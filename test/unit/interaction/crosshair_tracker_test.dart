import 'dart:ui';

import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
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
  });
}
