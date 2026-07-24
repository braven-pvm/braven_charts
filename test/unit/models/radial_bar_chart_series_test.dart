import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadialBarChartSeries', () {
    test('preserves category identity and explicit numeric semantics', () {
      final series = RadialBarChartSeries.fromMap(
        id: 'progress',
        name: 'Delivery progress',
        values: const {'Discovery': 72, 'Build': 54, 'Launch': 31},
        barColors: const {'Build': Colors.orange},
        unit: '%',
        minimum: 0,
        maximum: 100,
        baseline: 0,
      );

      expect(series.style, SeriesStyle.radialBar);
      expect(series.isXOrdered, isTrue);
      expect(series.categories, ['Discovery', 'Build', 'Launch']);
      expect(series.points.map((point) => point.x), [0, 1, 2]);
      expect(series.points.map((point) => point.y), [72, 54, 31]);
      expect(series.points[1].pointStyle?.color, Colors.orange);
      expect(series.unit, '%');
      expect(series.minimum, 0);
      expect(series.maximum, 100);
      expect(series.baseline, 0);
    });

    test('supports signed values around an explicit baseline', () {
      final series = RadialBarChartSeries.fromMap(
        id: 'variance',
        values: const {'Ahead': 18, 'Behind': -12},
        minimum: -25,
        maximum: 25,
        baseline: 0,
      );

      expect(series.points.map((point) => point.y), [18, -12]);
      expect(series.copyWith(baseline: 5).baseline, 5);
    });

    test('copyWith clears nullable public state without losing subtype', () {
      final series = RadialBarChartSeries.fromMap(
        id: 'progress',
        name: 'Progress',
        values: const {'A': 20},
        color: Colors.blue,
        metadata: const {'source': 'test'},
        unit: '%',
      );

      final copied = series.copyWith(
        clearName: true,
        clearColor: true,
        clearMetadata: true,
        clearUnit: true,
      );

      expect(copied, isA<RadialBarChartSeries>());
      expect(copied.name, isNull);
      expect(copied.color, isNull);
      expect(copied.metadata, isNull);
      expect(copied.unit, isNull);
      expect(copied.points, same(series.points));
    });

    test('rejects implicit domains and invalid category identities', () {
      expect(
        () => RadialBarChartSeries.fromMap(
          id: 'outside',
          values: const {'A': 120},
        ),
        throwsArgumentError,
      );
      expect(
        () => RadialBarChartSeries.fromMap(
          id: 'baseline',
          values: const {'A': 40},
          baseline: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => RadialBarChartSeries(
          id: 'duplicate',
          points: const [
            ChartDataPoint(x: 0, y: 20, label: 'A'),
            ChartDataPoint(x: 1, y: 30, label: 'A'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => RadialBarChartSeries.fromMap(
          id: 'style',
          values: const {'A': 20},
          radialBarStyle: const RadialBarStyle(trackOpacity: 1.1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects Cartesian state and style mutations', () {
      final series = RadialBarChartSeries.fromMap(
        id: 'progress',
        values: const {'A': 20},
      );

      expect(
        () => series.copyWith(style: SeriesStyle.line),
        throwsArgumentError,
      );
      expect(() => series.copyWith(yAxisId: 'cartesian'), throwsArgumentError);
      expect(() => series.copyWith(isXOrdered: false), throwsArgumentError);
    });
  });

  group('RadialBarChartConfig', () {
    test('validates pane guides and thresholds', () {
      const config = RadialBarChartConfig(
        trackGap: 4,
        tickCount: 6,
        thresholds: [RadialBarThreshold(value: 75, label: 'Target')],
      );

      expect(config.validate, returnsNormally);
      expect(config.copyWith(showGridLines: false).showGridLines, isFalse);
    });

    test('rejects invalid guide configuration', () {
      expect(
        const RadialBarChartConfig(trackGap: -1).validate,
        throwsArgumentError,
      );
      expect(
        const RadialBarChartConfig(tickCount: 1).validate,
        throwsArgumentError,
      );
      expect(
        const RadialBarChartConfig(
          thresholds: [
            RadialBarThreshold(value: 50, dashPattern: [2]),
          ],
        ).validate,
        throwsArgumentError,
      );
    });
  });
}
