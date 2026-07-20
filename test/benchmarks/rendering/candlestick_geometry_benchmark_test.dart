import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final index = CandlestickViewportIndex([
    for (var pointIndex = 0; pointIndex < 50000; pointIndex++)
      CandlestickDataPoint(
        x: pointIndex.toDouble(),
        open: 100 + (pointIndex % 8).toDouble(),
        high: 112 + (pointIndex % 8).toDouble(),
        low: 94 + (pointIndex % 8).toDouble(),
        close: 105 + (pointIndex % 8).toDouble(),
      ),
  ]);

  test('cold-indexes 50,000 ordered candles promptly', () {
    final points = index.points;
    final stopwatch = Stopwatch()..start();
    final coldIndex = CandlestickViewportIndex(points);
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print('Cold Candlestick index (50,000): ${elapsedMs.toStringAsFixed(3)}ms');
    expect(coldIndex.nominalSpacingData, 1);
    expect(elapsedMs, lessThan(100));
  });

  test('resolves 1,000 visible candles within one frame on average', () {
    for (var warmup = 0; warmup < 5; warmup++) {
      _resolve(index, warmup * 1000.0);
    }

    const iterations = 50;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final geometry = _resolve(index, iteration * 500.0);
      expect(geometry.length, inInclusiveRange(1000, 1002));
    }
    stopwatch.stop();

    final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
    // ignore: avoid_print
    print(
      'Virtualized Candlestick geometry (50,000 source / 1,000 visible): '
      '${averageMs.toStringAsFixed(3)}ms average',
    );
    expect(averageMs, lessThan(16.67));
  });

  test('groups 50,000 visible candles outside paint within one frame', () {
    const transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 49999,
      dataYMin: 90,
      dataYMax: 125,
      plotWidth: 1600,
      plotHeight: 900,
    );
    const grouping = CandlestickDensityGrouping(enabled: true);
    for (var warmup = 0; warmup < 5; warmup++) {
      CandlestickGeometryEngine.resolve(
        index: index,
        transform: transform,
        style: const CandlestickChartStyle(),
        grouping: grouping,
      );
    }

    const iterations = 50;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final geometry = CandlestickGeometryEngine.resolve(
        index: index,
        transform: transform,
        style: const CandlestickChartStyle(),
        grouping: grouping,
      );
      expect(geometry.length, inInclusiveRange(300, 322));
      expect(geometry.first.sourceStartIndex, 0);
      expect(geometry.last.sourceEndIndexExclusive, 50000);
    }
    stopwatch.stop();

    final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
    // ignore: avoid_print
    print(
      'Grouped Candlestick geometry (50,000 source): '
      '${averageMs.toStringAsFixed(3)}ms average',
    );
    expect(averageMs, lessThan(16.67));
  });
}

List<CandlestickGeometry> _resolve(
  CandlestickViewportIndex index,
  double start,
) => CandlestickGeometryEngine.resolve(
  index: index,
  transform: ChartTransform(
    dataXMin: start,
    dataXMax: start + 999,
    dataYMin: 90,
    dataYMax: 125,
    plotWidth: 1600,
    plotHeight: 900,
  ),
  style: const CandlestickChartStyle(),
);
