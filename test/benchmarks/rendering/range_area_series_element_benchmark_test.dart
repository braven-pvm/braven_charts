// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/utils/range_area_series_transition.dart';
import 'package:flutter/widgets.dart' show Alignment;
import 'package:flutter_test/flutter_test.dart';

const _frameBudgetMicros = 16670;
const _size = Size(1600, 900);

void main() {
  group('Range Area SeriesElement performance', () {
    test('uniform 5K paint stays within one frame and 1.8x Area', () {
      final intervals = _intervals(5000);
      final rangeElement = _rangeElement(intervals);
      final areaElement = _areaElement(intervals);

      final area = _measure(() => _paint(areaElement));
      final range = _measure(() => _paint(rangeElement));
      final ratio = range.medianMicros / math.max(1, area.medianMicros);

      _printResult(
        'Uniform Range Area vs Area (5,000 visible)',
        range,
        detail:
            'Area median ${_ms(area.medianMicros)}ms; '
            'ratio ${ratio.toStringAsFixed(2)}x',
      );
      expect(range.p95Micros, lessThan(_frameBudgetMicros));
      expect(
        ratio,
        lessThanOrEqualTo(1.8),
        reason: 'uniform Range Area median must stay within 1.8x native Area',
      );
    });

    test('gradient and independent boundary slow paths stay interactive', () {
      final intervals = _intervals(5000);
      final gradient = _rangeElement(
        intervals,
        gradient: const AreaGradient(
          colors: [Color(0x332563EB), Color(0x992563EB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
      final styled = _rangeElement(
        intervals,
        upper: const RangeAreaBoundaryStyle(strokeWidth: 2.5, glowRadius: 3),
        lower: const RangeAreaBoundaryStyle(
          strokeWidth: 2.5,
          dashPattern: [6, 4],
          glowRadius: 3,
        ),
      );

      final gradientResult = _measure(() => _paint(gradient));
      final styledResult = _measure(() => _paint(styled));
      _printResult('Gradient Range Area (5,000 visible)', gradientResult);
      _printResult('Dashed/glowing Range Area (5,000 visible)', styledResult);

      expect(gradientResult.p95Micros, lessThan(_frameBudgetMicros));
      expect(styledResult.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('gap-heavy and two-band compositions stay within one frame', () {
      final gapHeavy = _rangeElement(_intervals(5000, gapEvery: 11));
      final outer = _rangeElement(_intervals(5000, breadth: 18));
      final inner = _rangeElement(
        _intervals(5000, breadth: 8),
        color: const Color(0xFF7C3AED),
      );

      final gaps = _measure(() => _paint(gapHeavy));
      final nested = _measure(() => _paintAll([outer, inner]));
      _printResult('Gap-heavy Range Area (5,000 source)', gaps);
      _printResult('Nested Range Area bands (2 x 5,000)', nested);

      expect(gaps.p95Micros, lessThan(_frameBudgetMicros));
      expect(nested.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('50K source culls to 1K visible intervals before paint', () {
      final element = _rangeElement(
        _intervals(50000),
        transform: _transform(start: 24000, visibleCount: 1000),
      );
      final result = _measure(() => _paint(element));

      _printResult(
        'Virtualized Range Area (50,000 source / 1,000 visible)',
        result,
      );
      expect(
        element.visibleRangeAreaPointIndices.length,
        inInclusiveRange(1000, 1002),
      );
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('compatible 5K updates preserve the frame budget', () {
      final from = _series(_intervals(5000), id: 'animated-range');
      final to = _series(_intervals(5000, revision: 1), id: 'animated-range');
      final element = SeriesElement(
        series: from,
        transform: _transform(start: 0, visibleCount: 5000),
      );
      var frame = 0;

      final result = _measure(() {
        final progress = ((frame++ % 59) + 1) / 60;
        element.updateSeries(
          RangeAreaSeriesTransition.interpolate(
            from: from,
            to: to,
            progress: progress,
          ),
        );
        _paint(element);
      });

      _printResult('Animated Range Area revision (5,000 visible)', result);
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('5K interval hover overlay stays below one millisecond', () {
      final element = _rangeElement(_intervals(5000));
      // Resolve and cache the visible geometry before measuring the dynamic
      // overlay path used on every pointer move.
      _paint(element);

      final result = _measure(
        () => _paintRangeAreaHover(element, pointIndex: 2500),
      );

      _printResult('Range Area hover overlay (5,000 visible)', result);
      expect(
        result.p95Micros,
        lessThan(1000),
        reason:
            'Range Area hover feedback must stay far below the frame budget.',
      );
    });
  });
}

SeriesElement _rangeElement(
  List<RangeAreaDataPoint> intervals, {
  ChartTransform? transform,
  Color color = const Color(0xFF2563EB),
  AreaGradient? gradient,
  RangeAreaBoundaryStyle upper = const RangeAreaBoundaryStyle(),
  RangeAreaBoundaryStyle lower = const RangeAreaBoundaryStyle(),
}) => SeriesElement(
  series: _series(
    intervals,
    color: color,
    gradient: gradient,
    upper: upper,
    lower: lower,
  ),
  transform: transform ?? _transform(start: 0, visibleCount: intervals.length),
);

RangeAreaChartSeries _series(
  List<RangeAreaDataPoint> intervals, {
  String id = 'range-benchmark',
  Color color = const Color(0xFF2563EB),
  AreaGradient? gradient,
  RangeAreaBoundaryStyle upper = const RangeAreaBoundaryStyle(),
  RangeAreaBoundaryStyle lower = const RangeAreaBoundaryStyle(),
}) => RangeAreaChartSeries(
  id: id,
  points: intervals,
  color: color,
  interpolation: LineInterpolation.monotone,
  fillOpacity: 0.28,
  fillGradient: gradient,
  upperBoundaryStyle: upper,
  lowerBoundaryStyle: lower,
);

SeriesElement _areaElement(List<RangeAreaDataPoint> intervals) => SeriesElement(
  series: AreaChartSeries(
    id: 'area-benchmark',
    points: [
      for (final interval in intervals)
        ChartDataPoint(x: interval.x, y: interval.midpoint!),
    ],
    interpolation: LineInterpolation.monotone,
    fillOpacity: 0.28,
  ),
  transform: _transform(start: 0, visibleCount: intervals.length),
);

List<RangeAreaDataPoint> _intervals(
  int count, {
  int? gapEvery,
  double breadth = 16,
  double revision = 0,
}) => [
  for (var index = 0; index < count; index++)
    if (gapEvery != null && index > 0 && index % gapEvery == 0)
      RangeAreaDataPoint.gap(x: index.toDouble())
    else
      RangeAreaDataPoint(
        x: index.toDouble(),
        low: 50 + math.sin(index / 80) * 12 - breadth / 2 + revision,
        high:
            50 +
            math.sin(index / 80) * 12 +
            breadth / 2 +
            math.cos(index / 37) * 2 +
            revision,
      ),
];

ChartTransform _transform({required double start, required int visibleCount}) =>
    ChartTransform(
      dataXMin: start,
      dataXMax: start + visibleCount - 1,
      dataYMin: 20,
      dataYMax: 80,
      plotWidth: _size.width,
      plotHeight: _size.height,
    );

void _paint(SeriesElement element) => _paintAll([element]);

void _paintAll(List<SeriesElement> elements) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  for (final element in elements) {
    element.paint(canvas, _size);
  }
  recorder.endRecording().dispose();
}

void _paintRangeAreaHover(SeriesElement element, {required int pointIndex}) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  element.paintRangeAreaInteractionOverlay(
    canvas,
    hoveredPointIndex: pointIndex,
  );
  recorder.endRecording().dispose();
}

_BenchmarkResult _measure(void Function() frame) {
  for (var warmup = 0; warmup < 8; warmup++) {
    frame();
  }
  final samples = <int>[];
  for (var iteration = 0; iteration < 40; iteration++) {
    final stopwatch = Stopwatch()..start();
    frame();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  return _BenchmarkResult(
    medianMicros: samples[samples.length ~/ 2],
    p95Micros: samples[(samples.length * 0.95).ceil() - 1],
  );
}

void _printResult(String label, _BenchmarkResult result, {String? detail}) {
  // ignore: avoid_print
  print(
    '$label: median ${_ms(result.medianMicros)}ms; '
    'p95 ${_ms(result.p95Micros)}ms${detail == null ? '' : '; $detail'}',
  );
}

String _ms(int microseconds) => (microseconds / 1000).toStringAsFixed(3);

class _BenchmarkResult {
  const _BenchmarkResult({required this.medianMicros, required this.p95Micros});

  final int medianMicros;
  final int p95Micros;
}
