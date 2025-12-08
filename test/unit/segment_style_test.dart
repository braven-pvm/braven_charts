// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SegmentStyle', () {
    test('creates with color only', () {
      const style = SegmentStyle.color(Color(0xFFFF0000));
      expect(style.color, const Color(0xFFFF0000));
      expect(style.strokeWidth, isNull);
      expect(style.hasOverrides, isTrue);
    });

    test('creates with strokeWidth only', () {
      const style = SegmentStyle.strokeWidth(4.0);
      expect(style.color, isNull);
      expect(style.strokeWidth, 4.0);
      expect(style.hasOverrides, isTrue);
    });

    test('creates with both properties', () {
      const style = SegmentStyle(
        color: Color(0xFF00FF00),
        strokeWidth: 3.0,
      );
      expect(style.color, const Color(0xFF00FF00));
      expect(style.strokeWidth, 3.0);
      expect(style.hasOverrides, isTrue);
    });

    test('empty style has no overrides', () {
      const style = SegmentStyle();
      expect(style.hasOverrides, isFalse);
    });

    test('equality with same values', () {
      const s1 = SegmentStyle(color: Color(0xFFFF0000), strokeWidth: 2.0);
      const s2 = SegmentStyle(color: Color(0xFFFF0000), strokeWidth: 2.0);
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('inequality with different color', () {
      const s1 = SegmentStyle.color(Color(0xFFFF0000));
      const s2 = SegmentStyle.color(Color(0xFF00FF00));
      expect(s1, isNot(equals(s2)));
    });

    test('inequality with different strokeWidth', () {
      const s1 = SegmentStyle.strokeWidth(2.0);
      const s2 = SegmentStyle.strokeWidth(4.0);
      expect(s1, isNot(equals(s2)));
    });

    test('copyWith preserves values', () {
      const original = SegmentStyle(color: Color(0xFFFF0000), strokeWidth: 2.0);
      final copy = original.copyWith();
      expect(copy.color, original.color);
      expect(copy.strokeWidth, original.strokeWidth);
    });

    test('copyWith overrides values', () {
      const original = SegmentStyle(color: Color(0xFFFF0000), strokeWidth: 2.0);
      final copy = original.copyWith(color: const Color(0xFF00FF00));
      expect(copy.color, const Color(0xFF00FF00));
      expect(copy.strokeWidth, 2.0);
    });

    test('copyWith clears color', () {
      const original = SegmentStyle(color: Color(0xFFFF0000), strokeWidth: 2.0);
      final copy = original.copyWith(clearColor: true);
      expect(copy.color, isNull);
      expect(copy.strokeWidth, 2.0);
    });

    test('toString includes properties', () {
      const style = SegmentStyle(color: Color(0xFFFF0000), strokeWidth: 2.0);
      expect(style.toString(), contains('color'));
      expect(style.toString(), contains('strokeWidth'));
    });
  });

  group('ChartDataPoint with segmentStyle', () {
    test('creates point with segmentStyle', () {
      final point = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
      );
      expect(point.segmentStyle, isNotNull);
      expect(point.segmentStyle!.color, const Color(0xFFFF0000));
      expect(point.hasSegmentStyle, isTrue);
    });

    test('creates point without segmentStyle', () {
      const point = ChartDataPoint(x: 10.0, y: 20.0);
      expect(point.segmentStyle, isNull);
      expect(point.hasSegmentStyle, isFalse);
    });

    test('copyWith adds segmentStyle', () {
      const point = ChartDataPoint(x: 10.0, y: 20.0);
      final styled = point.copyWith(
        segmentStyle: const SegmentStyle.color(Color(0xFFFF0000)),
      );
      expect(styled.segmentStyle, isNotNull);
      expect(styled.x, point.x);
      expect(styled.y, point.y);
    });

    test('copyWith clears segmentStyle', () {
      final point = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
      );
      final cleared = point.copyWith(clearSegmentStyle: true);
      expect(cleared.segmentStyle, isNull);
    });

    test('equality includes segmentStyle', () {
      final p1 = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
      );
      final p2 = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
      );
      final p3 = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        segmentStyle: SegmentStyle.color(Color(0xFF00FF00)),
      );
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('LineChartSeries segment extensions', () {
    test('hasSegmentOverrides is false when no overrides', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 2, y: 2),
        ],
      );
      expect(series.hasSegmentOverrides, isFalse);
    });

    test('hasSegmentOverrides is true when override exists', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(
            x: 1,
            y: 1,
            segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(x: 2, y: 2),
        ],
      );
      expect(series.hasSegmentOverrides, isTrue);
    });

    test('withSegmentColors applies colors at indices', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 2, y: 2),
          ChartDataPoint(x: 3, y: 3),
        ],
      );

      final colored = series.withSegmentColors({
        1: const Color(0xFFFF0000),
      });

      expect(colored.points[0].segmentStyle, isNull);
      expect(colored.points[1].segmentStyle?.color, const Color(0xFFFF0000));
      expect(colored.points[2].segmentStyle, isNull);
      expect(colored.points[3].segmentStyle, isNull); // Last point
    });

    test('withSegmentColors ignores invalid indices', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
        ],
      );

      // Index 1 is last point - should be ignored (no segment after it)
      final colored = series.withSegmentColors({
        1: const Color(0xFFFF0000),
        5: const Color(0xFF00FF00), // Out of bounds
        -1: const Color(0xFF0000FF), // Negative
      });

      expect(colored.points[0].segmentStyle, isNull);
      expect(colored.points[1].segmentStyle, isNull);
    });

    test('withStyleInRange applies style to X range', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 5, y: 5),
          ChartDataPoint(x: 10, y: 10),
          ChartDataPoint(x: 15, y: 15),
          ChartDataPoint(x: 20, y: 20),
        ],
      );

      final styled = series.withStyleInRange(
        5.0,
        15.0,
        const SegmentStyle.color(Color(0xFFFF0000)),
      );

      expect(styled.points[0].segmentStyle, isNull); // x=0, outside
      expect(styled.points[1].segmentStyle?.color, const Color(0xFFFF0000)); // x=5
      expect(styled.points[2].segmentStyle?.color, const Color(0xFFFF0000)); // x=10
      expect(styled.points[3].segmentStyle, isNull); // x=15, excluded (half-open)
      expect(styled.points[4].segmentStyle, isNull); // x=20, outside
    });

    test('withColorWhere applies color based on condition', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 50),
          ChartDataPoint(x: 1, y: 150), // Above threshold
          ChartDataPoint(x: 2, y: 120), // Above threshold
          ChartDataPoint(x: 3, y: 80),
          ChartDataPoint(x: 4, y: 200), // Above threshold (last point)
        ],
      );

      final styled = series.withColorWhere(
        (point) => point.y > 100,
        const Color(0xFFFF0000),
      );

      expect(styled.points[0].segmentStyle, isNull);
      expect(styled.points[1].segmentStyle?.color, const Color(0xFFFF0000));
      expect(styled.points[2].segmentStyle?.color, const Color(0xFFFF0000));
      expect(styled.points[3].segmentStyle, isNull);
      expect(styled.points[4].segmentStyle, isNull); // Last point ignored
    });

    test('clearSegmentStyles removes all styles', () {
      final series = const LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(
            x: 1,
            y: 1,
            segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(
            x: 2,
            y: 2,
            segmentStyle: SegmentStyle.color(Color(0xFF00FF00)),
          ),
        ],
      );

      expect(series.hasSegmentOverrides, isTrue);

      final cleared = series.clearSegmentStyles();

      expect(cleared.hasSegmentOverrides, isFalse);
      expect(cleared.points[0].segmentStyle, isNull);
      expect(cleared.points[1].segmentStyle, isNull);
      expect(cleared.points[2].segmentStyle, isNull);
    });
  });

  group('PointStyle', () {
    test('creates with color only', () {
      const style = PointStyle.color(Color(0xFFFF0000));
      expect(style.color, const Color(0xFFFF0000));
      expect(style.size, isNull);
      expect(style.hasOverrides, isTrue);
    });

    test('creates with size only', () {
      const style = PointStyle.size(8.0);
      expect(style.color, isNull);
      expect(style.size, 8.0);
      expect(style.hasOverrides, isTrue);
    });

    test('creates with both properties', () {
      const style = PointStyle(
        color: Color(0xFF00FF00),
        size: 12.0,
      );
      expect(style.color, const Color(0xFF00FF00));
      expect(style.size, 12.0);
      expect(style.hasOverrides, isTrue);
    });

    test('empty style has no overrides', () {
      const style = PointStyle();
      expect(style.hasOverrides, isFalse);
    });

    test('equality with same values', () {
      const s1 = PointStyle(color: Color(0xFFFF0000), size: 8.0);
      const s2 = PointStyle(color: Color(0xFFFF0000), size: 8.0);
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('inequality with different color', () {
      const s1 = PointStyle.color(Color(0xFFFF0000));
      const s2 = PointStyle.color(Color(0xFF00FF00));
      expect(s1, isNot(equals(s2)));
    });

    test('inequality with different size', () {
      const s1 = PointStyle.size(8.0);
      const s2 = PointStyle.size(12.0);
      expect(s1, isNot(equals(s2)));
    });

    test('copyWith preserves values', () {
      const original = PointStyle(color: Color(0xFFFF0000), size: 8.0);
      final copy = original.copyWith();
      expect(copy.color, original.color);
      expect(copy.size, original.size);
    });

    test('copyWith overrides values', () {
      const original = PointStyle(color: Color(0xFFFF0000), size: 8.0);
      final copy = original.copyWith(color: const Color(0xFF00FF00));
      expect(copy.color, const Color(0xFF00FF00));
      expect(copy.size, 8.0);
    });

    test('copyWith clears color', () {
      const original = PointStyle(color: Color(0xFFFF0000), size: 8.0);
      final copy = original.copyWith(clearColor: true);
      expect(copy.color, isNull);
      expect(copy.size, 8.0);
    });

    test('toString includes properties', () {
      const style = PointStyle(color: Color(0xFFFF0000), size: 8.0);
      expect(style.toString(), contains('color'));
      expect(style.toString(), contains('size'));
    });
  });

  group('ChartDataPoint with pointStyle', () {
    test('creates point with pointStyle', () {
      final point = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        pointStyle: PointStyle.color(Color(0xFFFF0000)),
      );
      expect(point.pointStyle, isNotNull);
      expect(point.pointStyle!.color, const Color(0xFFFF0000));
      expect(point.hasPointStyle, isTrue);
    });

    test('creates point without pointStyle', () {
      const point = ChartDataPoint(x: 10.0, y: 20.0);
      expect(point.pointStyle, isNull);
      expect(point.hasPointStyle, isFalse);
    });

    test('copyWith adds pointStyle', () {
      const point = ChartDataPoint(x: 10.0, y: 20.0);
      final styled = point.copyWith(
        pointStyle: const PointStyle.color(Color(0xFFFF0000)),
      );
      expect(styled.pointStyle, isNotNull);
      expect(styled.x, point.x);
      expect(styled.y, point.y);
    });

    test('copyWith clears pointStyle', () {
      final point = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        pointStyle: PointStyle.color(Color(0xFFFF0000)),
      );
      final cleared = point.copyWith(clearPointStyle: true);
      expect(cleared.pointStyle, isNull);
    });

    test('equality includes pointStyle', () {
      final p1 = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        pointStyle: PointStyle.color(Color(0xFFFF0000)),
      );
      final p2 = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        pointStyle: PointStyle.color(Color(0xFFFF0000)),
      );
      final p3 = const ChartDataPoint(
        x: 10.0,
        y: 20.0,
        pointStyle: PointStyle.color(Color(0xFF00FF00)),
      );
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('ScatterChartSeries point extensions', () {
    test('hasPointOverrides is false when no overrides', () {
      final series = const ScatterChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 2, y: 2),
        ],
      );
      expect(series.hasPointOverrides, isFalse);
    });

    test('hasPointOverrides is true when override exists', () {
      final series = const ScatterChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(
            x: 1,
            y: 1,
            pointStyle: PointStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(x: 2, y: 2),
        ],
      );
      expect(series.hasPointOverrides, isTrue);
    });

    test('withPointColors applies colors at indices', () {
      final series = const ScatterChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 2, y: 2),
        ],
      );

      final colored = series.withPointColors({
        1: const Color(0xFFFF0000),
      });

      expect(colored.points[0].pointStyle, isNull);
      expect(colored.points[1].pointStyle?.color, const Color(0xFFFF0000));
      expect(colored.points[2].pointStyle, isNull);
    });

    test('withPointColorWhere applies color based on condition', () {
      final series = const ScatterChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 50),
          ChartDataPoint(x: 1, y: 150), // Above threshold
          ChartDataPoint(x: 2, y: 80),
        ],
      );

      final styled = series.withColorWhere(
        (point) => point.y > 100,
        const Color(0xFFFF0000),
      );

      expect(styled.points[0].pointStyle, isNull);
      expect(styled.points[1].pointStyle?.color, const Color(0xFFFF0000));
      expect(styled.points[2].pointStyle, isNull);
    });

    test('clearPointStyles removes all styles', () {
      final series = const ScatterChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(
            x: 0,
            y: 0,
            pointStyle: PointStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(
            x: 1,
            y: 1,
            pointStyle: PointStyle.color(Color(0xFF00FF00)),
          ),
        ],
      );

      expect(series.hasPointOverrides, isTrue);

      final cleared = series.clearPointStyles();

      expect(cleared.hasPointOverrides, isFalse);
      expect(cleared.points[0].pointStyle, isNull);
      expect(cleared.points[1].pointStyle, isNull);
    });
  });

  group('BarChartSeries point extensions', () {
    test('hasPointOverrides is false when no overrides', () {
      final series = const BarChartSeries(
        id: 'test',
        barWidthPercent: 0.8,
        points: [
          ChartDataPoint(x: 0, y: 10),
          ChartDataPoint(x: 1, y: 20),
        ],
      );
      expect(series.hasPointOverrides, isFalse);
    });

    test('hasPointOverrides is true when override exists', () {
      final series = const BarChartSeries(
        id: 'test',
        barWidthPercent: 0.8,
        points: [
          ChartDataPoint(
            x: 0,
            y: 10,
            pointStyle: PointStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(x: 1, y: 20),
        ],
      );
      expect(series.hasPointOverrides, isTrue);
    });

    test('withPointColors applies colors at indices', () {
      final series = const BarChartSeries(
        id: 'test',
        barWidthPercent: 0.8,
        points: [
          ChartDataPoint(x: 0, y: 10),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 2, y: 30),
        ],
      );

      final colored = series.withPointColors({
        0: const Color(0xFFFF0000),
        2: const Color(0xFF00FF00),
      });

      expect(colored.points[0].pointStyle?.color, const Color(0xFFFF0000));
      expect(colored.points[1].pointStyle, isNull);
      expect(colored.points[2].pointStyle?.color, const Color(0xFF00FF00));
    });

    test('clearPointStyles removes all styles', () {
      final series = const BarChartSeries(
        id: 'test',
        barWidthPercent: 0.8,
        points: [
          ChartDataPoint(
            x: 0,
            y: 10,
            pointStyle: PointStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(
            x: 1,
            y: 20,
            pointStyle: PointStyle.size(2.0),
          ),
        ],
      );

      final cleared = series.clearPointStyles();

      expect(cleared.hasPointOverrides, isFalse);
    });
  });

  group('AreaChartSeries segment extensions', () {
    test('hasSegmentOverrides is false when no overrides', () {
      final series = const AreaChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 2, y: 2),
        ],
      );
      expect(series.hasSegmentOverrides, isFalse);
    });

    test('hasSegmentOverrides is true when override exists', () {
      final series = const AreaChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(
            x: 1,
            y: 1,
            segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(x: 2, y: 2),
        ],
      );
      expect(series.hasSegmentOverrides, isTrue);
    });

    test('withSegmentColors applies colors at indices', () {
      final series = const AreaChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 1, y: 1),
          ChartDataPoint(x: 2, y: 2),
          ChartDataPoint(x: 3, y: 3),
        ],
      );

      final colored = series.withSegmentColors({
        1: const Color(0xFFFF0000),
      });

      expect(colored.points[0].segmentStyle, isNull);
      expect(colored.points[1].segmentStyle?.color, const Color(0xFFFF0000));
      expect(colored.points[2].segmentStyle, isNull);
      expect(colored.points[3].segmentStyle, isNull); // Last point
    });

    test('clearSegmentStyles removes all styles', () {
      final series = const AreaChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(
            x: 1,
            y: 1,
            segmentStyle: SegmentStyle.color(Color(0xFFFF0000)),
          ),
          ChartDataPoint(
            x: 2,
            y: 2,
            segmentStyle: SegmentStyle.color(Color(0xFF00FF00)),
          ),
        ],
      );

      final cleared = series.clearSegmentStyles();

      expect(cleared.hasSegmentOverrides, isFalse);
    });
  });
}
