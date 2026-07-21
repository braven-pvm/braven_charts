import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeAreaChartSeries', () {
    test('is immutable, typed, ordered, and uses rangeArea style', () {
      final source = [_point(1), RangeAreaDataPoint.gap(x: 2), _point(3)];
      final series = RangeAreaChartSeries(id: 'range', points: source);
      source.add(_point(4));

      expect(series.length, 3);
      expect(series.intervals, hasLength(3));
      expect(series.style, SeriesStyle.rangeArea);
      expect(series.isXOrdered, isTrue);
      expect(() => series.points.add(_point(5)), throwsUnsupportedError);
    });

    test('accepts empty, single, and zero-span intervals', () {
      expect(
        RangeAreaChartSeries(id: 'empty', points: const []).isEmpty,
        isTrue,
      );
      expect(
        RangeAreaChartSeries(
          id: 'single',
          points: [RangeAreaDataPoint(x: 1, low: 4, high: 4)],
        ).length,
        1,
      );
    });

    test('rejects duplicate and descending X with indexed diagnostics', () {
      for (final points in [
        [_point(1), _point(1)],
        [_point(2), _point(1)],
      ]) {
        expect(
          () => RangeAreaChartSeries(id: 'invalid', points: points),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'points[1].x',
            ),
          ),
        );
      }
    });

    test('validates boundary and series presentation', () {
      expect(
        () => RangeAreaChartSeries(
          id: 'invalid-opacity',
          points: [_point(1)],
          fillOpacity: 1.2,
        ),
        throwsArgumentError,
      );
      expect(
        () => RangeAreaChartSeries(
          id: 'invalid-dash',
          points: [_point(1)],
          upperBoundaryStyle: const RangeAreaBoundaryStyle(
            dashPattern: [4, 2, 1],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('copyWith preserves typed invariants and styles', () {
      final source = RangeAreaChartSeries(
        id: 'range',
        points: [_point(1)],
        color: const Color(0xFF3366FF),
        borderMode: RangeAreaBorderMode.closed,
        labelConfig: const RangeAreaLabelConfig(
          value: RangeAreaLabelValue.both,
          labels: DataPointLabelConfig(show: true),
        ),
      );

      final copy = source.copyWith(id: 'copy', fillOpacity: 0.5);
      expect(copy, isA<RangeAreaChartSeries>());
      expect(copy.borderMode, RangeAreaBorderMode.closed);
      expect(copy.labelConfig.value, RangeAreaLabelValue.both);
      expect(copy.fillOpacity, 0.5);
      expect(
        () => source.copyWith(style: SeriesStyle.line),
        throwsArgumentError,
      );
      expect(() => source.copyWith(isXOrdered: false), throwsArgumentError);
      expect(
        () => source.copyWith(points: const [ChartDataPoint(x: 1, y: 2)]),
        throwsArgumentError,
      );
    });
  });
}

RangeAreaDataPoint _point(double x) =>
    RangeAreaDataPoint(x: x, low: 10 + x, high: 20 + x);
