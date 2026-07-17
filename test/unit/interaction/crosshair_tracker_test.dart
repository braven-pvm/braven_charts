import 'dart:ui';

import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
import 'package:braven_charts/src/models/bar_chart_style.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
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
}
