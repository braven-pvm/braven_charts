import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('warm-paints 1,000 visible candles within one frame on average', () {
    final element = SeriesElement(
      series: CandlestickChartSeries(
        id: 'benchmark-candles',
        points: [
          for (var index = 0; index < 50000; index++)
            CandlestickDataPoint(
              x: index.toDouble(),
              open: 100 + (index % 8),
              high: 112 + (index % 8),
              low: 94 + (index % 8),
              close: 105 + (index % 8),
            ),
        ],
      ),
      transform: const ChartTransform(
        dataXMin: 24000,
        dataXMax: 24999,
        dataYMin: 90,
        dataYMax: 125,
        plotWidth: 1600,
        plotHeight: 900,
      ),
    );

    for (var warmup = 0; warmup < 5; warmup++) {
      _paint(element);
    }
    const iterations = 50;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      _paint(element);
    }
    stopwatch.stop();

    final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
    // ignore: avoid_print
    print(
      'Warm Candlestick paint (50,000 source / 1,000 visible): '
      '${averageMs.toStringAsFixed(3)}ms average',
    );
    expect(
      element.visibleCandlestickGeometryCount,
      inInclusiveRange(1000, 1002),
    );
    expect(averageMs, lessThan(16.67));
  });
}

void _paint(SeriesElement element) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), const Size(1600, 900));
  recorder.endRecording().dispose();
}
