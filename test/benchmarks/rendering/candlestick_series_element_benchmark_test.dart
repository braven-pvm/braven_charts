import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/utils/candlestick_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

const _frameBudget = Duration(microseconds: 16667);

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

  test('warm-paints 5,000 visible candles within one frame at p95', () {
    final element = SeriesElement(
      series: _series(pointCount: 50000),
      transform: _transform(start: 20000, visibleCount: 5000),
    );

    final result = _measureFrames(() => _paint(element));

    expect(
      element.visibleCandlestickGeometryCount,
      inInclusiveRange(5000, 5002),
    );
    _expectWithinFrame('Warm Candlestick paint (5,000 visible)', result);
  });

  test('interpolates and paints 1,000 revised candles within one frame', () {
    final from = _series(pointCount: 1000);
    final to = _series(pointCount: 1000, revision: 1);
    final element = SeriesElement(
      series: from,
      transform: _transform(start: 0, visibleCount: 1000),
    );
    var frame = 0;

    final result = _measureFrames(() {
      final progress = ((frame++ % 59) + 1) / 60;
      element.updateSeries(
        CandlestickSeriesTransition.interpolate(
          from: from,
          to: to,
          progress: progress,
        ),
      );
      _paint(element);
    });

    expect(
      element.visibleCandlestickGeometryCount,
      inInclusiveRange(1000, 1002),
    );
    _expectWithinFrame('Animated Candlestick revision (1,000 visible)', result);
  });

  test('pans and zooms 5,000 visible candles within one frame at p95', () {
    final element = SeriesElement(
      series: _series(pointCount: 50000),
      transform: _transform(start: 0, visibleCount: 5000),
    );
    var frame = 0;

    final result = _measureFrames(() {
      final start = (frame++ * 700).toDouble();
      final base = _transform(start: start, visibleCount: 5000);
      final transform = frame.isEven
          ? base
          : base.zoom(1.2, const Offset(800, 450));
      element.updateTransform(transform);
      _paint(element);
    });

    expect(element.visibleCandlestickGeometryCount, lessThanOrEqualTo(5002));
    _expectWithinFrame('Candlestick pan/zoom (5,000 visible)', result);
  });
}

void _paint(SeriesElement element) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), const Size(1600, 900));
  recorder.endRecording().dispose();
}

_FrameResult _measureFrames(void Function() frame) {
  for (var warmup = 0; warmup < 5; warmup++) {
    frame();
  }
  final samples = <int>[];
  for (var iteration = 0; iteration < 30; iteration++) {
    final stopwatch = Stopwatch()..start();
    frame();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final p95Index = (samples.length * .95).ceil() - 1;
  return _FrameResult(
    median: Duration(microseconds: samples[samples.length ~/ 2]),
    p95: Duration(microseconds: samples[p95Index]),
  );
}

void _expectWithinFrame(String label, _FrameResult result) {
  // ignore: avoid_print
  print(
    '$label: median '
    '${(result.median.inMicroseconds / 1000).toStringAsFixed(3)}ms; p95 '
    '${(result.p95.inMicroseconds / 1000).toStringAsFixed(3)}ms',
  );
  expect(result.median, lessThan(_frameBudget));
  expect(result.p95, lessThan(_frameBudget));
}

CandlestickChartSeries _series({
  required int pointCount,
  double revision = 0,
}) => CandlestickChartSeries(
  id: 'benchmark-candles',
  points: [
    for (var index = 0; index < pointCount; index++)
      _point(index, revision: revision),
  ],
);

CandlestickDataPoint _point(int index, {required double revision}) {
  final open = 100 + (index % 8).toDouble() + revision;
  final close = open + (index.isEven ? 3 : -2) + revision * .5;
  return CandlestickDataPoint(
    x: index.toDouble(),
    open: open,
    high: math.max(open, close) + 4,
    low: math.min(open, close) - 4,
    close: close,
  );
}

ChartTransform _transform({required double start, required int visibleCount}) =>
    ChartTransform(
      dataXMin: start,
      dataXMax: start + visibleCount - 1,
      dataYMin: 85,
      dataYMax: 125,
      plotWidth: 1600,
      plotHeight: 900,
    );

class _FrameResult {
  const _FrameResult({required this.median, required this.p95});

  final Duration median;
  final Duration p95;
}
