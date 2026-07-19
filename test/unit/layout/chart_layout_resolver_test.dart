import 'package:braven_charts/src/layout/chart_layout_kind.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartLayoutResolver', () {
    test('uses Cartesian layout for empty and Cartesian compositions', () {
      expect(ChartLayoutResolver.resolve(const []), ChartLayoutKind.cartesian);
      expect(
        ChartLayoutResolver.resolve(const [
          LineChartSeries(id: 'line', points: []),
          ScatterChartSeries(id: 'scatter', points: []),
        ]),
        ChartLayoutKind.cartesian,
      );
    });

    test('uses partition-radial layout for exactly one PieChartSeries', () {
      final pie = PieChartSeries.fromMap(id: 'pie', values: const {'A': 1});

      expect(
        ChartLayoutResolver.resolve([pie]),
        ChartLayoutKind.partitionRadial,
      );
    });

    test('uses partition-radial layout for exactly one DonutChartSeries', () {
      final donut = DonutChartSeries.fromMap(
        id: 'donut',
        values: const {'A': 1},
      );

      expect(
        ChartLayoutResolver.resolve([donut]),
        ChartLayoutKind.partitionRadial,
      );
    });

    test('rejects mixed radial and Cartesian series', () {
      final pie = PieChartSeries.fromMap(id: 'pie', values: const {'A': 1});

      expect(
        () => ChartLayoutResolver.resolve([
          pie,
          const LineChartSeries(id: 'line', points: []),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('cannot be mixed'),
          ),
        ),
      );
    });

    test('rejects more than one pie series', () {
      final first = PieChartSeries.fromMap(id: 'first', values: const {'A': 1});
      final second = PieChartSeries.fromMap(
        id: 'second',
        values: const {'B': 2},
      );

      expect(
        () => ChartLayoutResolver.resolve([first, second]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('exactly one PieChartSeries'),
          ),
        ),
      );
    });

    test('uses partition-radial layout for multiple Donut series', () {
      final current = DonutChartSeries.fromMap(
        id: 'current',
        values: const {'A': 1},
      );
      final previous = DonutChartSeries.fromMap(
        id: 'previous',
        values: const {'A': 2},
      );

      expect(
        ChartLayoutResolver.resolve([current, previous]),
        ChartLayoutKind.partitionRadial,
      );
    });

    test('keeps mixed Pie and Donut composition unavailable', () {
      final pie = PieChartSeries.fromMap(id: 'pie', values: const {'A': 1});
      final donut = DonutChartSeries.fromMap(
        id: 'donut',
        values: const {'A': 1},
      );

      expect(
        () => ChartLayoutResolver.resolve([pie, donut]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Pie and Donut series cannot be mixed'),
          ),
        ),
      );
    });

    test('rejects generic series that only claim the pie style', () {
      const invalid = ChartSeries(
        id: 'fake-pie',
        points: [],
        style: SeriesStyle.pie,
      );

      expect(
        () => ChartLayoutResolver.resolve(const [invalid]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('requires a PieChartSeries'),
          ),
        ),
      );
    });

    test('rejects generic series that only claim the donut style', () {
      const invalid = ChartSeries(
        id: 'fake-donut',
        points: [],
        style: SeriesStyle.donut,
      );

      expect(
        () => ChartLayoutResolver.resolve(const [invalid]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('requires a DonutChartSeries'),
          ),
        ),
      );
    });

    testWidgets('BravenChartPlus applies composition validation at runtime', (
      tester,
    ) async {
      final pie = PieChartSeries.fromMap(id: 'pie', values: const {'A': 1});

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BravenChartPlus(
            series: [
              pie,
              const LineChartSeries(id: 'line', points: []),
            ],
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('cannot be mixed'),
        ),
      );
    });
  });
}
