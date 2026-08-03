// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

const _frameBudgetMicros = 16670;
const _overlayBudgetMicros = 1000;
const _size = Size(1400, 800);

void main() {
  group('Heatmap SeriesElement performance', () {
    test('1K labelled cells stay within one frame', () {
      final element = _element(columns: 40, rows: 25, showLabels: true);

      final result = _measure(() => _paint(element));

      _printResult('Labelled Heatmap (1,000 visible)', result);
      expect(element.visibleHeatmapPointIndices, hasLength(1000));
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('10K dense cells stay within one frame', () {
      final element = _element(columns: 100, rows: 100);

      final result = _measure(() => _paint(element));

      _printResult('Dense Heatmap (10,000 visible)', result);
      expect(element.visibleHeatmapPointIndices, hasLength(10000));
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('viewport-backed matrix resident snapshot stays within one frame', () {
      final element = _element(
        columns: 512,
        rows: 24,
        transform: _transform(xMin: 211.5, xMax: 511.5, yMin: -0.5, yMax: 23.5),
        gapFraction: 0.06,
        cornerRadius: 3,
      );

      final result = _measure(() => _paint(element));

      _printResult(
        'Viewport-backed Heatmap (12,288 resident / 300 x 24 viewport)',
        result,
        detail: '${element.visibleHeatmapPointIndices.length} paint candidates',
      );
      expect(element.visibleHeatmapPointIndices, hasLength(7248));
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('10K cells with a durable hide filter stay within one frame', () {
      final element = _element(
        columns: 100,
        rows: 100,
        valueFilter: const HeatmapValueFilter(
          minimumValue: 45,
          maximumValue: 55,
          mode: HeatmapValueFilterMode.hide,
        ),
      );

      final result = _measure(() => _paint(element));

      _printResult('Filtered Heatmap (10,000 source)', result);
      expect(element.visibleHeatmapPointIndices, hasLength(10000));
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('250K source cells cull to the small viewport before paint', () {
      final element = _element(
        columns: 500,
        rows: 500,
        transform: _transform(xMin: 210, xMax: 249, yMin: 300, yMax: 324),
      );

      final result = _measure(() => _paint(element));

      _printResult(
        'Virtualized Heatmap (250,000 source / small viewport)',
        result,
        detail:
            '${element.visibleHeatmapPointIndices.length} materialized; '
            '${element.heatmapVisitedCellCount} visited',
      );
      expect(
        element.visibleHeatmapPointIndices.length,
        inInclusiveRange(1000, 1150),
      );
      expect(element.heatmapVisitedCellCount, lessThanOrEqualTo(1150));
      expect(result.p95Micros, lessThan(_frameBudgetMicros));
    });

    test('cached indexed hit lookup stays below one millisecond', () {
      final element = _element(columns: 500, rows: 500);
      final target = element.currentTransform.dataToPlot(245, 245);
      expect(element.dataHitAt(target), isNotNull);

      final result = _measure(
        () => expect(element.dataHitAt(target)?.pointIndex, 122745),
      );

      _printResult('Heatmap cached hit (250,000 source)', result);
      expect(result.p95Micros, lessThan(_overlayBudgetMicros));
    });

    test('hover overlay stays below one millisecond', () {
      final element = _element(columns: 100, rows: 100);
      _paint(element);

      final result = _measure(
        () => _paintOverlay(element, hoveredPointIndex: 5050),
      );

      _printResult('Heatmap hover overlay (10,000 visible)', result);
      expect(result.p95Micros, lessThan(_overlayBudgetMicros));
    });
  });
}

SeriesElement _element({
  required int columns,
  required int rows,
  bool showLabels = false,
  HeatmapValueFilter? valueFilter,
  ChartTransform? transform,
  double gapFraction = 0.04,
  double cornerRadius = 1.5,
}) {
  final cells = [
    for (var row = 0; row < rows; row++)
      for (var column = 0; column < columns; column++)
        HeatmapDataPoint(
          x: column.toDouble(),
          y: row.toDouble(),
          value: 50 + math.sin(column / 7) * 20 + math.cos(row / 5) * 15,
        ),
  ];
  return SeriesElement(
    series: HeatmapChartSeries(
      id: 'heatmap-benchmark',
      points: cells,
      colorScale: HeatmapColorScale.sequential(
        colors: const [Color(0xFFE0F2FE), Color(0xFF0369A1)],
      ),
      showCellLabels: showLabels,
      valueFilter: valueFilter,
      borderWidth: 0.5,
      gapFraction: gapFraction,
      cornerRadius: cornerRadius,
    ),
    transform:
        transform ??
        _transform(
          xMin: -0.5,
          xMax: columns - 0.5,
          yMin: -0.5,
          yMax: rows - 0.5,
        ),
  );
}

ChartTransform _transform({
  required double xMin,
  required double xMax,
  required double yMin,
  required double yMax,
}) => ChartTransform(
  dataXMin: xMin,
  dataXMax: xMax,
  dataYMin: yMin,
  dataYMax: yMax,
  plotWidth: _size.width,
  plotHeight: _size.height,
);

void _paint(SeriesElement element) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), _size);
  recorder.endRecording().dispose();
}

void _paintOverlay(SeriesElement element, {required int hoveredPointIndex}) {
  final recorder = PictureRecorder();
  element.paintHeatmapInteractionOverlay(
    Canvas(recorder),
    hoveredPointIndex: hoveredPointIndex,
  );
  recorder.endRecording().dispose();
}

_BenchmarkResult _measure(void Function() operation) {
  for (var warmup = 0; warmup < 8; warmup++) {
    operation();
  }
  final samples = <int>[];
  for (var iteration = 0; iteration < 40; iteration++) {
    final stopwatch = Stopwatch()..start();
    operation();
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
