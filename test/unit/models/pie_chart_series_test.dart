import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieChartSeries', () {
    test('fromMap preserves category order, ordinals, values, and colors', () {
      final series = PieChartSeries.fromMap(
        id: 'revenue',
        unit: 'USD',
        values: const {'Subscriptions': 42, 'Services': 0, 'Hardware': 27.5},
        sliceColors: const {'Hardware': Color(0xFF00AA88)},
      );

      expect(series.style, SeriesStyle.pie);
      expect(series.isXOrdered, isTrue);
      expect(series.points.map((point) => point.label), [
        'Subscriptions',
        'Services',
        'Hardware',
      ]);
      expect(series.points.map((point) => point.x), [0, 1, 2]);
      expect(series.points.map((point) => point.y), [42, 0, 27.5]);
      expect(series.points.last.pointStyle?.color, const Color(0xFF00AA88));
      expect(series.visiblePointIndices, [0, 2]);
      expect(series.total, 69.5);
      expect(series.unit, 'USD');
    });

    test('explicit points allow duplicate labels and retain zero values', () {
      final series = PieChartSeries(
        id: 'segments',
        points: const [
          ChartDataPoint(x: 10, y: 3, label: 'Other'),
          ChartDataPoint(x: 20, y: 0, label: 'Other'),
        ],
      );

      expect(series.points, hasLength(2));
      expect(series.visiblePointIndices, [0]);
      expect(series.isAllZero, isFalse);
    });

    test(
      'all-zero data remains transportable and reports empty geometry data',
      () {
        final series = PieChartSeries.fromMap(
          id: 'empty',
          values: const {'A': 0, 'B': 0},
        );

        expect(series.isAllZero, isTrue);
        expect(series.total, 0);
        expect(series.visiblePointIndices, isEmpty);
      },
    );

    for (final invalidValue in <double>[-1, double.nan, double.infinity]) {
      test('rejects invalid contribution $invalidValue', () {
        expect(
          () => PieChartSeries(
            id: 'invalid',
            points: [ChartDataPoint(x: 0, y: invalidValue, label: 'Invalid')],
          ),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'points[0].y')
                .having(
                  (error) => error.message,
                  'message',
                  contains('finite and non-negative'),
                ),
          ),
        );
      });
    }

    test('rejects a non-finite ordinal', () {
      expect(
        () => PieChartSeries(
          id: 'invalid-x',
          points: const [ChartDataPoint(x: double.nan, y: 1, label: 'Invalid')],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'points[0].x',
          ),
        ),
      );
    });

    test('rejects finite contributions whose combined total overflows', () {
      expect(
        () => PieChartSeries(
          id: 'overflow',
          points: const [
            ChartDataPoint(x: 0, y: double.maxFinite, label: 'A'),
            ChartDataPoint(x: 1, y: double.maxFinite, label: 'B'),
          ],
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'points')
              .having(
                (error) => error.message,
                'message',
                contains('finite total'),
              ),
        ),
      );
    });

    for (final label in <String?>[null, '', '   ']) {
      test('rejects empty category label ${label ?? 'null'}', () {
        expect(
          () => PieChartSeries(
            id: 'invalid-label',
            points: [ChartDataPoint(x: 0, y: 1, label: label)],
          ),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'points[0].label')
                .having(
                  (error) => error.message,
                  'message',
                  contains('non-empty category'),
                ),
          ),
        );
      });
    }

    test('validates geometry and data-label configuration in release code', () {
      PieChartSeries build({
        PieChartStyle style = const PieChartStyle(),
        PieDataLabelConfig labels = const PieDataLabelConfig(),
      }) => PieChartSeries.fromMap(
        id: 'config',
        values: const {'A': 1},
        pieStyle: style,
        dataLabels: labels,
      );

      expect(
        () => build(style: const PieChartStyle(radiusFactor: 0)),
        throwsArgumentError,
      );
      expect(
        () => build(style: const PieChartStyle(sliceGap: -1)),
        throwsArgumentError,
      );
      expect(
        () => build(style: const PieChartStyle(borderWidth: double.nan)),
        throwsArgumentError,
      );
      expect(
        () => build(labels: const PieDataLabelConfig(minimumShare: 1.01)),
        throwsArgumentError,
      );
      expect(
        () => build(labels: const PieDataLabelConfig(connectorWidth: -0.1)),
        throwsArgumentError,
      );
    });

    test('copies style and labels without weakening pie invariants', () {
      final original = PieChartSeries.fromMap(
        id: 'copy',
        values: const {'A': 2, 'B': 1},
      );
      final copied = original.copyWith(
        pieStyle: original.pieStyle.copyWith(clockwise: false),
        dataLabels: original.dataLabels.copyWith(
          content: PieDataLabelContent.categoryValueAndPercentage,
        ),
      );

      expect(copied.pieStyle.clockwise, isFalse);
      expect(
        copied.dataLabels.content,
        PieDataLabelContent.categoryValueAndPercentage,
      );
      expect(copied.points, original.points);
      expect(copied.style, SeriesStyle.pie);
      expect(
        () => original.copyWith(style: SeriesStyle.line),
        throwsArgumentError,
      );
      expect(() => original.copyWith(isXOrdered: false), throwsArgumentError);
    });

    test('equality and hashCode include pie configuration', () {
      final first = PieChartSeries.fromMap(
        id: 'same',
        values: const {'A': 2, 'B': 1},
      );
      final same = PieChartSeries.fromMap(
        id: 'same',
        values: const {'A': 2, 'B': 1},
      );
      final different = PieChartSeries.fromMap(
        id: 'same',
        values: const {'A': 2, 'B': 1},
        pieStyle: const PieChartStyle(clockwise: false),
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    test('defensively freezes the supplied point list', () {
      final points = <ChartDataPoint>[
        const ChartDataPoint(x: 0, y: 1, label: 'A'),
      ];
      final series = PieChartSeries(id: 'frozen', points: points);
      points.add(const ChartDataPoint(x: 1, y: 2, label: 'B'));

      expect(series.points, hasLength(1));
      expect(
        () => series.points.add(const ChartDataPoint(x: 1, y: 2, label: 'B')),
        throwsUnsupportedError,
      );
    });
  });

  group('BravenChartPlus pie factories', () {
    test('fromValues now honors every Cartesian chart type', () {
      final expectedTypes = <ChartType, Type>{
        ChartType.line: LineChartSeries,
        ChartType.area: AreaChartSeries,
        ChartType.bar: BarChartSeries,
        ChartType.scatter: ScatterChartSeries,
      };

      for (final entry in expectedTypes.entries) {
        final chart = BravenChartPlus.fromValues(
          chartType: entry.key,
          seriesId: entry.key.name,
          yValues: const [1, 2],
        );
        expect(chart.series.single.runtimeType, entry.value);
      }
    });

    test('fromMap treats keys as insertion-ordered pie categories', () {
      final chart = BravenChartPlus.fromMap(
        chartType: ChartType.pie,
        seriesId: 'factory-pie',
        data: const {'North': 3, 'South': 2},
      );

      final series = chart.series.single as PieChartSeries;
      expect(series.points.map((point) => point.label), ['North', 'South']);
      expect(series.points.map((point) => point.x), [0, 1]);
    });

    test('fromJson creates a validated pie series', () {
      final chart = BravenChartPlus.fromJson(
        chartType: ChartType.pie,
        seriesId: 'json-pie',
        json: '[{"x":0,"y":4,"label":"A"}]',
      );

      expect(chart.series.single, isA<PieChartSeries>());
    });

    test('fromValues rejects pie because categories cannot be inferred', () {
      expect(
        () => BravenChartPlus.fromValues(
          chartType: ChartType.pie,
          seriesId: 'invalid-factory',
          yValues: const [1, 2],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('cannot infer pie category labels'),
          ),
        ),
      );
    });
  });
}
