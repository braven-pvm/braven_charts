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

    test('uses polar-axis layout for one PolarColumnChartSeries', () {
      final polar = PolarColumnChartSeries.fromMap(
        id: 'polar',
        values: const {'A': 1, 'B': 2},
      );

      expect(ChartLayoutResolver.resolve([polar]), ChartLayoutKind.polarAxis);
    });

    test('rejects mixed and multi-series Polar Column compositions in V1', () {
      final first = PolarColumnChartSeries.fromMap(
        id: 'first',
        values: const {'A': 1},
      );
      final second = PolarColumnChartSeries.fromMap(
        id: 'second',
        values: const {'A': 2},
      );

      expect(
        () => ChartLayoutResolver.resolve([
          first,
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
      expect(
        () => ChartLayoutResolver.resolve([first, second]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('exactly one PolarColumnChartSeries'),
          ),
        ),
      );
    });

    test(
      'rejects a generic series that only claims the polar-column style',
      () {
        const invalid = ChartSeries(
          id: 'fake-polar',
          points: [],
          style: SeriesStyle.polarColumn,
        );

        expect(
          () => ChartLayoutResolver.resolve(const [invalid]),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('requires a PolarColumnChartSeries'),
            ),
          ),
        );
      },
    );

    test(
      'accepts one Candlestick series with Line, Area, and Scatter overlays',
      () {
        final candle = CandlestickChartSeries(
          id: 'price',
          points: [
            CandlestickDataPoint(x: 1, open: 10, high: 12, low: 9, close: 11),
          ],
        );

        expect(
          ChartLayoutResolver.resolve([
            candle,
            const LineChartSeries(id: 'line', points: []),
            const AreaChartSeries(id: 'area', points: []),
            const ScatterChartSeries(id: 'scatter', points: []),
          ]),
          ChartLayoutKind.cartesian,
        );
      },
    );

    test('rejects more than one Candlestick series', () {
      CandlestickChartSeries series(String id) => CandlestickChartSeries(
        id: id,
        points: [
          CandlestickDataPoint(x: 1, open: 10, high: 12, low: 9, close: 11),
        ],
      );

      expect(
        () => ChartLayoutResolver.resolve([series('one'), series('two')]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('at most one CandlestickChartSeries'),
          ),
        ),
      );
    });

    test('rejects same-plot Candlestick and Bar series', () {
      final candle = CandlestickChartSeries(
        id: 'price',
        points: [
          CandlestickDataPoint(x: 1, open: 10, high: 12, low: 9, close: 11),
        ],
      );

      expect(
        () => ChartLayoutResolver.resolve([
          candle,
          const BarChartSeries(id: 'volume', points: [], barWidthPercent: 0.7),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('cannot share one plot'),
          ),
        ),
      );
    });

    test('rejects a generic series that only claims candlestick style', () {
      const invalid = ChartSeries(
        id: 'fake-candle',
        points: [],
        style: SeriesStyle.candlestick,
      );

      expect(
        () => ChartLayoutResolver.resolve(const [invalid]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('requires a CandlestickChartSeries'),
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
