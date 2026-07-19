import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

const _pointCount = 5000;
const _frameBudget = Duration(microseconds: 16670);
const _size = Size(1000, 400);
const _transform = ChartTransform(
  dataXMin: 0,
  dataXMax: _pointCount - 1,
  dataYMin: 0,
  dataYMax: 100,
  plotWidth: 1000,
  plotHeight: 400,
);

void main() {
  final points = List.generate(
    _pointCount,
    (index) => ChartDataPoint(
      x: index.toDouble(),
      y: 50 + math.sin(index / 80) * 24 + math.cos(index / 31) * 8,
    ),
    growable: false,
  );

  group('Path SeriesElement rendering benchmarks', () {
    test('solid 5K-point Line stays within one frame', () {
      final series = LineChartSeries(
        id: 'solid-line',
        points: points,
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2,
      );
      final result = _benchmark(series);

      _expectWithinFrame('Solid Line', result);

      final coldResult = _benchmarkCold(series);
      _expectWithinFrame('Cold Solid Line', coldResult);
    });

    test('solid 5K-point Area stays within one frame', () {
      final result = _benchmark(
        AreaChartSeries(
          id: 'solid-area',
          points: points,
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2,
          fillOpacity: 0.25,
        ),
      );

      _expectWithinFrame('Solid Area', result);
    });

    test('baseline 5K-point Area keeps its single-path fast path', () {
      final result = _benchmark(
        AreaChartSeries(
          id: 'baseline-area',
          points: points,
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2,
          fillOpacity: 0.25,
          baselineValue: 50,
        ),
      );

      _expectWithinFrame('Baseline Area', result);
    });

    test(
      '5K-point Forecast with one style boundary stays within one frame',
      () {
        final forecastPoints = [
          for (var index = 0; index < points.length; index++)
            index < points.length ~/ 2 || index == points.length - 1
                ? points[index]
                : points[index].copyWith(
                    segmentStyle: const SegmentStyle(dashPattern: [2, 6]),
                  ),
        ];
        final result = _benchmark(
          LineChartSeries(
            id: 'continuous-forecast',
            points: forecastPoints,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2,
          ),
        );

        _expectWithinFrame('Continuous Forecast', result);
      },
    );
  });
}

_BenchmarkResult _benchmark(ChartSeries series) {
  final element = SeriesElement(series: series, transform: _transform);
  for (var iteration = 0; iteration < 5; iteration++) {
    _paint(element);
  }

  final samples = <int>[];
  for (var iteration = 0; iteration < 30; iteration++) {
    final stopwatch = Stopwatch()..start();
    _paint(element);
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  return _BenchmarkResult(
    median: Duration(microseconds: samples[samples.length ~/ 2]),
    p95: Duration(microseconds: samples[(samples.length * 0.95).floor()]),
  );
}

_BenchmarkResult _benchmarkCold(ChartSeries series) {
  for (var iteration = 0; iteration < 5; iteration++) {
    _paint(SeriesElement(series: series, transform: _transform));
  }

  final samples = <int>[];
  for (var iteration = 0; iteration < 30; iteration++) {
    final stopwatch = Stopwatch()..start();
    _paint(SeriesElement(series: series, transform: _transform));
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  return _BenchmarkResult(
    median: Duration(microseconds: samples[samples.length ~/ 2]),
    p95: Duration(microseconds: samples[(samples.length * 0.95).floor()]),
  );
}

void _paint(SeriesElement element) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), _size);
  recorder.endRecording().dispose();
}

void _expectWithinFrame(String label, _BenchmarkResult result) {
  // ignore: avoid_print
  print(
    '$label (5K points): median ${result.median.inMicroseconds / 1000}ms; '
    'p95 ${result.p95.inMicroseconds / 1000}ms',
  );
  expect(result.median, lessThan(_frameBudget));
  expect(result.p95, lessThan(_frameBudget));
}

class _BenchmarkResult {
  const _BenchmarkResult({required this.median, required this.p95});

  final Duration median;
  final Duration p95;
}
