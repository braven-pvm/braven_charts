import 'package:braven_charts/src/layout/polar_column_stack_layout.dart';
import 'package:braven_charts/src/models/polar_column_chart_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarColumnStackLayout', () {
    test('accumulates positive values in declaration order', () {
      final layout = PolarColumnStackLayout.resolve([
        PolarColumnChartSeries.fromMap(
          id: 'first',
          values: const {'A': 10, 'B': 20},
        ),
        PolarColumnChartSeries.fromMap(
          id: 'second',
          values: const {'A': 5, 'B': 7},
        ),
      ]);

      expect(layout.forSeries('first').starts, [0, 0]);
      expect(layout.forSeries('first').ends, [10, 20]);
      expect(layout.forSeries('second').starts, [10, 20]);
      expect(layout.forSeries('second').ends, [15, 27]);
      expect(layout.minimum, 0);
      expect(layout.maximum, 27);
    });

    test('keeps positive and negative accumulators independent', () {
      final layout = PolarColumnStackLayout.resolve([
        PolarColumnChartSeries.fromMap(
          id: 'first',
          values: const {'A': 10, 'B': -4},
        ),
        PolarColumnChartSeries.fromMap(
          id: 'second',
          values: const {'A': -3, 'B': -6},
        ),
        PolarColumnChartSeries.fromMap(
          id: 'third',
          values: const {'A': 5, 'B': 2},
        ),
      ]);

      expect(layout.forSeries('first').starts, [0, 0]);
      expect(layout.forSeries('first').ends, [10, -4]);
      expect(layout.forSeries('second').starts, [0, -4]);
      expect(layout.forSeries('second').ends, [-3, -10]);
      expect(layout.forSeries('third').starts, [10, 0]);
      expect(layout.forSeries('third').ends, [15, 2]);
      expect(layout.minimum, -10);
      expect(layout.maximum, 15);
    });

    test('requires at least two source series', () {
      expect(
        () => PolarColumnStackLayout.resolve([
          PolarColumnChartSeries.fromMap(id: 'only', values: const {'A': 10}),
        ]),
        throwsArgumentError,
      );
    });
  });
}
