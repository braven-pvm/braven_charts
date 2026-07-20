import 'dart:ui';

import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/bar_chart_style.dart';
import 'package:braven_charts/src/models/candlestick_chart_series.dart';
import 'package:braven_charts/src/models/candlestick_data_point.dart';
import 'package:braven_charts/src/models/candlestick_density_grouping.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/scatter_marker_style.dart';
import 'package:braven_charts/src/utils/interpolation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosshairTracker interpolation', () {
    test('tracking state follows bezier interpolation geometry', () {
      const series = LineChartSeries(
        id: 'bezier',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 4, y: 9),
          ChartDataPoint(x: 6, y: 2),
        ],
        interpolation: LineInterpolation.bezier,
        tension: 0.25,
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 100,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 6,
        seriesList: [series],
      );

      expect(state, isNotNull);
      final expectedY = InterpolationGeometry.interpolateYForX<ChartDataPoint>(
        points: series.points,
        startIndex: 1,
        targetX: 2.0,
        interpolation: LineInterpolation.bezier,
        getX: (point) => point.x,
        getY: (point) => point.y,
        tension: series.tension,
      );

      expect(state!.dataX, closeTo(2.0, 1e-9));
      expect(state.seriesValues.single.y, closeTo(expectedY, 1e-9));
      expect(state.seriesValues.single.isInterpolated, isTrue);
    });

    test('tracking state follows monotone interpolation geometry', () {
      const series = LineChartSeries(
        id: 'monotone',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 2),
          ChartDataPoint(x: 2, y: 3),
          ChartDataPoint(x: 3, y: 5),
        ],
        interpolation: LineInterpolation.monotone,
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 150,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 3,
        seriesList: [series],
      );

      expect(state, isNotNull);
      final expectedY = InterpolationGeometry.interpolateYForX<ChartDataPoint>(
        points: series.points,
        startIndex: 1,
        targetX: 1.5,
        interpolation: LineInterpolation.monotone,
        getX: (point) => point.x,
        getY: (point) => point.y,
      );

      expect(state!.dataX, closeTo(1.5, 1e-9));
      expect(state.seriesValues.single.y, closeTo(expectedY, 1e-9));
      expect(state.seriesValues.single.isInterpolated, isTrue);
    });

    test(
      'bar tracking snaps to the nearest category without interpolation',
      () {
        const series = BarChartSeries(
          id: 'bars',
          points: [ChartDataPoint(x: 0, y: 10), ChartDataPoint(x: 1, y: 80)],
          barWidthPercent: 0.7,
        );

        final state = CrosshairTracker.calculateTrackingState(
          screenX: 120,
          chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
          xMin: 0,
          xMax: 1,
          seriesList: [series],
        );

        expect(state, isNotNull);
        expect(state!.seriesValues.single.x, 0);
        expect(state.seriesValues.single.y, 10);
        expect(state.seriesValues.single.dataPointIndex, 0);
        expect(state.seriesValues.single.isInterpolated, isFalse);
      },
    );

    test('candlestick tracking snaps to one complete OHLC sample', () {
      final timestamp = DateTime.utc(2026, 7, 17);
      final series = CandlestickChartSeries(
        id: 'price',
        name: 'Price',
        unit: 'USD',
        points: [
          CandlestickDataPoint(
            x: 0,
            open: 100,
            high: 112,
            low: 98,
            close: 110,
            timestamp: timestamp,
          ),
          CandlestickDataPoint(
            x: 3,
            open: 110,
            high: 114,
            low: 103,
            close: 105,
          ),
        ],
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 160,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 3,
        seriesList: [series],
        interpolate: true,
      );

      final value = state!.seriesValues.single;
      expect(value.dataPointIndex, 1);
      expect(value.x, 3);
      expect(value.y, 105);
      expect(value.isInterpolated, isFalse);
      expect(value.candlestick, isNotNull);
      expect(value.candlestick!.open, 110);
      expect(value.candlestick!.high, 114);
      expect(value.candlestick!.low, 103);
      expect(value.candlestick!.close, 105);
      expect(value.candlestick!.formattedChange, '-5.00 USD (-4.55%)');
    });

    test(
      'candlestick tracking breaks nearest-X ties toward the earlier sample',
      () {
        final series = CandlestickChartSeries(
          id: 'price',
          points: [
            CandlestickDataPoint(x: 0, open: 1, high: 2, low: 0, close: 2),
            CandlestickDataPoint(x: 10, open: 2, high: 3, low: 1, close: 1),
          ],
        );

        final state = CrosshairTracker.calculateTrackingState(
          screenX: 150,
          chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
          xMin: 0,
          xMax: 10,
          seriesList: [series],
        );

        expect(state!.seriesValues.single.dataPointIndex, 0);
      },
    );

    test('candlestick tracking resolves the painted density group', () {
      final series = CandlestickChartSeries(
        id: 'price',
        unit: 'USD',
        densityGrouping: const CandlestickDensityGrouping(enabled: true),
        points: [
          CandlestickDataPoint(x: 0, open: 10, high: 12, low: 8, close: 11),
          CandlestickDataPoint(x: 1, open: 11, high: 15, low: 9, close: 14),
          CandlestickDataPoint(x: 2, open: 14, high: 16, low: 7, close: 8),
          CandlestickDataPoint(x: 3, open: 8, high: 13, low: 6, close: 12),
          CandlestickDataPoint(x: 4, open: 12, high: 17, low: 10, close: 16),
          CandlestickDataPoint(x: 5, open: 16, high: 18, low: 11, close: 13),
        ],
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 2,
        chartBounds: const Rect.fromLTWH(0, 0, 10, 100),
        xMin: 0,
        xMax: 5,
        seriesList: [series],
      );

      final value = state!.seriesValues.single;
      expect(value.dataPointIndex, 0);
      expect(value.sourcePointIndices, [0, 1, 2]);
      expect(value.candlestick!.open, 10);
      expect(value.candlestick!.high, 16);
      expect(value.candlestick!.low, 7);
      expect(value.candlestick!.close, 8);
      expect(value.candlestick!.semanticLabel, contains('3 grouped candles'));
    });

    test('scatter tracking supports unordered X values', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 100),
          ChartDataPoint(x: 2, y: 20),
          ChartDataPoint(x: 7, y: 70),
        ],
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 270,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 10,
        seriesList: const [series],
      );

      expect(state, isNotNull);
      expect(state!.seriesValues.single.x, 10);
      expect(state.seriesValues.single.y, 100);
      expect(state.seriesValues.single.dataPointIndex, 1);
      expect(state.seriesValues.single.isInterpolated, isFalse);
    });

    test('scatter tracking skips invalid points with stable tie breaking', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: double.nan, y: 100),
          ChartDataPoint(x: 10, y: 100),
        ],
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 120,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 10,
        seriesList: const [series],
      );

      expect(state, isNotNull);
      expect(state!.seriesValues.single.x, 0);
      expect(state.seriesValues.single.y, 0);
      expect(state.seriesValues.single.dataPointIndex, 0);
    });

    test('renderer can defer Scatter values to its two-dimensional index', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [ChartDataPoint(x: 4, y: 40)],
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 150,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 10,
        seriesList: const [series],
        includeScatterXFallback: false,
      );

      expect(state, isNotNull);
      expect(state!.seriesValues, isEmpty);
    });

    test('waterfall totals expose their resolved cumulative value', () {
      const series = BarChartSeries(
        id: 'waterfall',
        points: [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: -30),
          ChartDataPoint(x: 2, y: 999),
        ],
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {2},
        waterfallStyle: BarWaterfallStyle(totalColor: Color(0xFF5149C6)),
      );

      final state = CrosshairTracker.calculateTrackingState(
        screenX: 300,
        chartBounds: const Rect.fromLTWH(0, 0, 300, 200),
        xMin: 0,
        xMax: 2,
        seriesList: const [series],
      );

      expect(state, isNotNull);
      expect(state!.seriesValues.single.dataPointIndex, 2);
      expect(state.seriesValues.single.y, 70);
      expect(state.seriesValues.single.seriesColor, const Color(0xFF5149C6));
      expect(state.seriesValues.single.isInterpolated, isFalse);
    });
  });

  group('CrosshairTracker two-dimensional Scatter lookup', () {
    const transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 10,
      dataYMin: 0,
      dataYMax: 10,
      plotWidth: 100,
      plotHeight: 100,
    );

    test('uses both plot coordinates instead of X distance alone', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [ChartDataPoint(x: 5, y: 1), ChartDataPoint(x: 5.2, y: 9)],
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(50, 12),
        transform: transform,
      );

      expect(nearest?.dataPointIndex, 1);
      expect(nearest?.x, 5.2);
      expect(nearest?.y, 9);
    });

    test('preserves source order for coincident points', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [ChartDataPoint(x: 4, y: 4), ChartDataPoint(x: 4, y: 4)],
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(40, 60),
        transform: transform,
      );

      expect(nearest?.dataPointIndex, 0);
    });

    test('exposes the tracked point identity and bubble magnitude', () {
      const series = ScatterChartSeries(
        id: 'bubble',
        name: 'Enterprise',
        points: [
          ChartDataPoint(
            x: 4.2,
            y: 9.3,
            magnitude: 520,
            label: 'North America',
          ),
        ],
        sizeEncoding: ScatterSizeEncoding(
          minimumValue: 95,
          maximumValue: 600,
          label: 'Active accounts',
        ),
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(42, 7),
        transform: transform,
      );

      expect(nearest?.pointLabel, 'North America');
      expect(nearest?.magnitudeValue, 520);
      expect(nearest?.formattedMagnitudeValue, '520');
      expect(nearest?.magnitudeLabel, 'Active accounts');
    });

    test('does not expose an invalid bubble magnitude', () {
      const series = ScatterChartSeries(
        id: 'bubble',
        points: [ChartDataPoint(x: 4, y: 4, magnitude: -1)],
        sizeEncoding: ScatterSizeEncoding(maximumValue: 100),
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(40, 60),
        transform: transform,
      );

      expect(nearest?.magnitudeValue, isNull);
      expect(nearest?.formattedMagnitudeValue, isNull);
      expect(nearest?.magnitudeLabel, isNull);
    });

    test('exposes the tracked color metric and effective encoded color', () {
      const series = ScatterChartSeries(
        id: 'readiness',
        points: [
          ChartDataPoint(x: 4, y: 4, colorValue: 50, label: 'Athlete 1'),
        ],
        colorEncoding: ScatterColorEncoding(
          colors: [Color(0xFF0000FF), Color(0xFFFF0000)],
          minimumValue: 0,
          maximumValue: 100,
          label: 'Readiness',
          unit: '%',
        ),
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(40, 60),
        transform: transform,
      );

      expect(nearest?.colorValue, 50);
      expect(nearest?.formattedColorValue, '50 %');
      expect(nearest?.colorLabel, 'Readiness');
      expect(
        nearest?.seriesColor,
        Color.lerp(const Color(0xFF0000FF), const Color(0xFFFF0000), 0.5),
      );
    });

    test('exposes the tracked opacity metric', () {
      const series = ScatterChartSeries(
        id: 'confidence',
        points: [ChartDataPoint(x: 4, y: 4, opacityValue: 82, label: 'Day 7')],
        opacityEncoding: ScatterOpacityEncoding(
          minimumValue: 40,
          maximumValue: 100,
          label: 'Confidence',
          unit: '%',
        ),
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(40, 60),
        transform: transform,
      );

      expect(nearest?.opacityValue, 82);
      expect(nearest?.formattedOpacityValue, '82 %');
      expect(nearest?.opacityLabel, 'Confidence');
    });

    test('respects transposed transforms and skips invalid points', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [
          ChartDataPoint(x: double.nan, y: 5),
          ChartDataPoint(x: 2, y: 8),
          ChartDataPoint(x: 8, y: 2),
        ],
      );
      const transposed = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 10,
        plotWidth: 100,
        plotHeight: 100,
        transposed: true,
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(82, 18),
        transform: transposed,
      );

      expect(nearest?.dataPointIndex, 1);
    });

    test('uses the active zoomed viewport transform', () {
      const series = ScatterChartSeries(
        id: 'zoomed-scatter',
        points: [ChartDataPoint(x: 2, y: 2), ChartDataPoint(x: 8, y: 8)],
      );
      const zoomed = ChartTransform(
        dataXMin: 6,
        dataXMax: 10,
        dataYMin: 6,
        dataYMax: 10,
        plotWidth: 100,
        plotHeight: 100,
      );

      final nearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(50, 50),
        transform: zoomed,
      );

      expect(nearest?.dataPointIndex, 1);
    });

    test('resolves identical plot input through each series Y-axis bounds', () {
      const series = ScatterChartSeries(
        id: 'multi-axis-scatter',
        points: [ChartDataPoint(x: 5, y: 30), ChartDataPoint(x: 5, y: 80)],
      );
      const fullAxis = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
      );
      const upperAxis = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 50,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
      );

      final fullAxisNearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(50, 80),
        transform: fullAxis,
      );
      final upperAxisNearest = CrosshairTracker.calculateNearestScatterValue(
        series: series,
        plotPosition: const Offset(50, 80),
        transform: upperAxis,
      );

      expect(fullAxisNearest?.dataPointIndex, 0);
      expect(upperAxisNearest?.dataPointIndex, 1);
    });
  });
}
