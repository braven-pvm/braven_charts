import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final points = [
    for (var index = 0; index < 100000; index++)
      ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
  ];
  final series = ScatterChartSeries(
    id: 'dense-scatter',
    points: points,
    isXOrdered: true,
    markerRadius: 4,
  );

  test('cold-indexes 100,000 ordered Scatter points promptly', () {
    final stopwatch = Stopwatch()..start();
    final element = SeriesElement(
      series: series,
      transform: _transform(50000, 50010),
    );
    final visibleCount = element.visibleScatterGeometryCount;
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Cold Scatter index (100,000 points): '
      '${elapsedMs.toStringAsFixed(3)}ms; $visibleCount visible',
    );
    expect(visibleCount, lessThan(20));
    expect(elapsedMs, lessThan(100));
  });

  test('re-queries a 100,000-point Scatter viewport within one frame', () {
    final element = SeriesElement(series: series, transform: _transform(0, 10));
    element.visibleScatterGeometryCount;

    const iterations = 100;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final start = 1000.0 + iteration * 50;
      element.updateTransform(_transform(start, start + 10));
      element.visibleScatterGeometryCount;
    }
    stopwatch.stop();

    final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
    // ignore: avoid_print
    print(
      'Virtualized Scatter pan (100,000 points): '
      '${averageMs.toStringAsFixed(3)}ms average',
    );
    expect(averageMs, lessThan(16.67));
  });

  test('re-queries a jittered 100,000-point viewport within one frame', () {
    final element = SeriesElement(
      series: series.copyWith(
        jitter: const ScatterJitterConfig(
          xAmplitude: 20,
          yAmplitude: 14,
          seed: 37,
        ),
      ),
      transform: _transform(0, 10),
    );
    element.visibleScatterGeometryCount;

    const iterations = 100;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final start = 1000.0 + iteration * 50;
      element.updateTransform(_transform(start, start + 10));
      element.visibleScatterGeometryCount;
    }
    stopwatch.stop();

    final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
    // ignore: avoid_print
    print(
      'Virtualized jittered Scatter pan (100,000 points): '
      '${averageMs.toStringAsFixed(3)}ms average',
    );
    expect(averageMs, lessThan(16.67));
  });

  test('clusters 100,000 visible observations with bounded linear work', () {
    // Prime the lazy clustering path before timing it. The full package suite
    // can otherwise charge first-use JIT work to this benchmark on shared CI
    // runners, which measures VM warm-up rather than clustering throughput.
    final warmup = SeriesElement(
      series: series.copyWith(
        points: points.take(1000).toList(growable: false),
        renderMode: ScatterRenderMode.clusters,
        clusterConfig: const ScatterClusterConfig(cellSize: 32),
      ),
      transform: const ChartTransform(
        dataXMin: 0,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 1000,
        plotHeight: 600,
      ),
    );
    warmup.visibleScatterRenderedMarkerCount;

    final clustered = SeriesElement(
      series: series.copyWith(
        renderMode: ScatterRenderMode.clusters,
        clusterConfig: const ScatterClusterConfig(cellSize: 32),
      ),
      transform: const ChartTransform(
        dataXMin: 0,
        dataXMax: 100000,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 1000,
        plotHeight: 600,
      ),
    );

    final stopwatch = Stopwatch()..start();
    final rendered = clustered.visibleScatterRenderedMarkerCount;
    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Screen-space Scatter clustering (100,000 points): '
      '${elapsedMs.toStringAsFixed(3)}ms; $rendered markers',
    );
    expect(clustered.visibleScatterClusteredPointCount, 100000);
    expect(rendered, lessThan(700));
    expect(elapsedMs, lessThan(250));
  });

  test('mean-aggregates 500,000 observations with bounded linear work', () {
    final densePoints = [
      for (var index = 0; index < 500000; index++)
        ChartDataPoint(
          x: (index % 1000).toDouble(),
          y: ((index ~/ 1000) % 500).toDouble(),
        ),
    ];
    final binned = SeriesElement(
      series: ScatterChartSeries(
        id: 'dense-hexbin',
        points: densePoints,
        isXOrdered: false,
        renderMode: ScatterRenderMode.hexbin,
        binConfig: const ScatterBinConfig(
          cellSize: 24,
          aggregate: ScatterBinAggregate.mean,
          valueSource: ScatterBinValueSource.y,
        ),
      ),
      transform: const ChartTransform(
        dataXMin: 0,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 500,
        plotWidth: 1000,
        plotHeight: 600,
      ),
    );

    final stopwatch = Stopwatch()..start();
    final rendered = binned.visibleScatterRenderedMarkerCount;
    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Screen-space Scatter mean hexbin (500,000 points): '
      '${elapsedMs.toStringAsFixed(3)}ms; $rendered bins',
    );
    expect(binned.visibleScatterBinnedPointCount, 500000);
    expect(rendered, lessThan(3000));
    expect(elapsedMs, lessThan(1500));
  });

  test('contours 500,000 observations with bounded field work', () {
    final densePoints = [
      for (var index = 0; index < 500000; index++)
        ChartDataPoint(
          x: (index % 1000).toDouble(),
          y: ((index ~/ 1000) % 500).toDouble(),
        ),
    ];
    final density = SeriesElement(
      series: ScatterChartSeries(
        id: 'dense-contours',
        points: densePoints,
        isXOrdered: false,
        renderMode: ScatterRenderMode.density,
        densityConfig: const ScatterDensityConfig(
          gridCellSize: 8,
          bandwidth: 32,
          contourCount: 6,
        ),
      ),
      transform: const ChartTransform(
        dataXMin: 0,
        dataXMax: 1000,
        dataYMin: 0,
        dataYMax: 500,
        plotWidth: 1000,
        plotHeight: 600,
      ),
    );

    final stopwatch = Stopwatch()..start();
    final rendered = density.visibleScatterRenderedMarkerCount;
    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Screen-space Scatter density (500,000 points): '
      '${elapsedMs.toStringAsFixed(3)}ms; $rendered contours',
    );
    expect(rendered, inInclusiveRange(1, 6));
    expect(elapsedMs, lessThan(1500));
  });

  for (final pointCount in const [1000, 10000, 100000]) {
    test('batches $pointCount uniform markers with bounded paint cost', () {
      final denseElement = SeriesElement(
        series: ScatterChartSeries(
          id: 'paint-$pointCount',
          points: points.take(pointCount).toList(growable: false),
          isXOrdered: true,
          markerRadius: 4,
        ),
        transform: ChartTransform(
          dataXMin: 0,
          dataXMax: pointCount.toDouble(),
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 1000,
          plotHeight: 600,
        ),
      );
      denseElement.visibleScatterGeometryCount;
      final iterations = switch (pointCount) {
        1000 => 30,
        10000 => 15,
        _ => 5,
      };
      final stopwatch = Stopwatch()..start();
      for (var iteration = 0; iteration < iterations; iteration++) {
        final recorder = PictureRecorder();
        denseElement.paint(Canvas(recorder), const Size(1000, 600));
        recorder.endRecording().dispose();
      }
      stopwatch.stop();

      final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
      // ignore: avoid_print
      print(
        'Batched Scatter paint ($pointCount points): '
        '${averageMs.toStringAsFixed(3)}ms average',
      );
      expect(averageMs, lessThan(pointCount == 100000 ? 100 : 16.67));
    });
  }
}

ChartTransform _transform(double minX, double maxX) => ChartTransform(
  dataXMin: minX,
  dataXMax: maxX,
  dataYMin: 0,
  dataYMax: 100,
  plotWidth: 1000,
  plotHeight: 600,
);
