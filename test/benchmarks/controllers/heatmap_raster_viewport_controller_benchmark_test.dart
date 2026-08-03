// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../heatmap_benchmark_support.dart';

void main() {
  test(
    '512M-cell raster source keeps 100 moving viewport loads bounded',
    () async {
      final source = _BenchmarkRasterSource();
      final controller = HeatmapRasterViewportController(
        source: source,
        semanticDescriptor: _semanticDescriptor,
        maxCachedTiles: 48,
        maxDecodedBytes: 8 * 1024 * 1024,
        maxTilesPerViewport: 24,
      );
      addTearDown(controller.dispose);

      final stopwatch = Stopwatch()..start();
      final loadSamples = <int>[];
      for (var step = 0; step < 100; step++) {
        final firstColumn = step * 4096.0;
        final loadStopwatch = Stopwatch()..start();
        await controller.loadViewport(
          HeatmapViewportRequest(
            minimumX: firstColumn - 0.5,
            maximumX: firstColumn + 24575.5,
            minimumY: -0.5,
            maximumY: 511.5,
          ),
        );
        loadStopwatch.stop();
        loadSamples.add(loadStopwatch.elapsedMicroseconds);
        final snapshot = controller.snapshot;
        expect(snapshot.mountedTiles.length, lessThanOrEqualTo(16));
        expect(snapshot.requestedTileKeys.length, lessThanOrEqualTo(24));
        expect(snapshot.semanticCells.length, lessThanOrEqualTo(2048));
        expect(snapshot.diagnostics.cachedTileCount, lessThanOrEqualTo(48));
        expect(
          snapshot.diagnostics.decodedCacheBytes,
          lessThanOrEqualTo(8 * 1024 * 1024),
        );
      }
      stopwatch.stop();

      final diagnostics = controller.snapshot.diagnostics;
      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      final loadDistribution = HeatmapBenchmarkDistribution.fromMicroseconds(
        loadSamples,
      );
      // ignore: avoid_print
      print(
        'Heatmap raster viewport controller '
        '(512,000,000 conceptual cells / 100 moving windows): '
        '${elapsedMs.toStringAsFixed(3)}ms, '
        '${source.loadCount} tile loads, '
        '${diagnostics.cacheHits} cache hits, '
        '${diagnostics.evictions} evictions, '
        '${diagnostics.decodedCacheBytes} decoded bytes',
      );
      printHeatmapDistribution(
        'Heatmap raster moving-window load latency',
        loadDistribution,
      );
      expect(controller.snapshot.error, isNull);
      expect(source.loadCount, lessThan(240));
      expect(diagnostics.evictions, greaterThan(0));
      expect(diagnostics.resourcesDisposed, diagnostics.evictions);
      expect(source.disposedCount, diagnostics.resourcesDisposed);
      expect(elapsedMs, lessThan(10000));
    },
  );

  test('same raster residency reuses decoded tiles across 100 pans', () async {
    final source = _BenchmarkRasterSource();
    final controller = HeatmapRasterViewportController(
      source: source,
      semanticDescriptor: _semanticDescriptor,
      maxCachedTiles: 48,
      maxDecodedBytes: 8 * 1024 * 1024,
      maxTilesPerViewport: 24,
    );
    addTearDown(controller.dispose);

    await controller.loadViewport(
      const HeatmapViewportRequest(
        minimumX: 983039.5,
        maximumX: 999999.5,
        minimumY: -0.5,
        maximumY: 511.5,
      ),
    );
    final initialLoadCount = source.loadCount;
    final initialResources = controller.snapshot.mountedTiles
        .map((tile) => tile.resource)
        .toList(growable: false);

    final stopwatch = Stopwatch()..start();
    final panSamples = <int>[];
    for (var step = 0; step < 100; step++) {
      final offset = (step % 20) * 0.25;
      final panStopwatch = Stopwatch()..start();
      await controller.loadViewport(
        HeatmapViewportRequest(
          minimumX: 983039.5 + offset,
          maximumX: 999999.5,
          minimumY: -0.5,
          maximumY: 511.5,
        ),
      );
      panStopwatch.stop();
      panSamples.add(panStopwatch.elapsedMicroseconds);
      expect(controller.snapshot.semanticCells, hasLength(1536));
    }
    stopwatch.stop();

    final diagnostics = controller.snapshot.diagnostics;
    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    final panDistribution = HeatmapBenchmarkDistribution.fromMicroseconds(
      panSamples,
    );
    // ignore: avoid_print
    print(
      'Heatmap raster same-residency reuse (100 pans): '
      '${elapsedMs.toStringAsFixed(3)}ms, '
      '${diagnostics.cacheHits} cache hits',
    );
    printHeatmapDistribution(
      'Heatmap raster same-residency pan latency',
      panDistribution,
    );
    expect(source.loadCount, initialLoadCount);
    expect(diagnostics.cacheHits, 1200);
    expect(
      controller.snapshot.mountedTiles.map((tile) => tile.resource),
      orderedEquals(initialResources),
    );
    expect(diagnostics.resourcesDisposed, 0);
    expect(elapsedMs, lessThan(1000));
  });
}

final _semanticDescriptor = HeatmapRasterSemanticDescriptor(
  seriesId: 'benchmark-raster-semantic',
  colorScale: HeatmapColorScale.sequential(
    colors: const [Color(0xFF071D49), Color(0xFF22D3EE), Color(0xFFF97316)],
    minimumValue: 0,
    maximumValue: 100,
  ),
);

final class _BenchmarkRasterSource implements HeatmapRasterTileSource {
  static const int _semanticColumnsPerTile = 16;
  static const int _semanticRowsPerTile = 8;
  static const int _decodedBytesPerTile = 256 * 128 * 4;

  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 1000000,
    rowCount: 512,
  );

  @override
  int get tileColumnCount => 8192;

  @override
  int get tileRowCount => 128;

  int loadCount = 0;
  int disposedCount = 0;

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) async {
    loadCount++;
    return HeatmapRasterTile(
      key: request.key,
      bounds: HeatmapViewportBounds(
        minimumX: domain.xForColumn(request.columnStart) - 0.5,
        maximumX: domain.xForColumn(request.columnEndExclusive - 1) + 0.5,
        minimumY: domain.yForRow(request.rowStart) - 0.5,
        maximumY: domain.yForRow(request.rowEndExclusive - 1) + 0.5,
      ),
      resource: _BenchmarkRasterResource(
        decodedByteCount: _decodedBytesPerTile,
        onDispose: () => disposedCount++,
      ),
      semanticCells: _semanticCells(request),
    );
  }

  List<HeatmapDataPoint> _semanticCells(HeatmapTileRequest request) => [
    for (var row = 0; row < _semanticRowsPerTile; row++)
      for (var column = 0; column < _semanticColumnsPerTile; column++)
        _semanticCell(request, column: column, row: row),
  ];

  HeatmapDataPoint _semanticCell(
    HeatmapTileRequest request, {
    required int column,
    required int row,
  }) {
    final columnStart =
        request.columnStart +
        column * request.columnCount ~/ _semanticColumnsPerTile;
    final columnEnd =
        request.columnStart +
        (column + 1) * request.columnCount ~/ _semanticColumnsPerTile;
    final rowStart =
        request.rowStart + row * request.rowCount ~/ _semanticRowsPerTile;
    final rowEnd =
        request.rowStart + (row + 1) * request.rowCount ~/ _semanticRowsPerTile;
    final xMinimum = domain.xForColumn(columnStart) - 0.5;
    final xMaximum = domain.xForColumn(columnEnd - 1) + 0.5;
    final yMinimum = domain.yForRow(rowStart) - 0.5;
    final yMaximum = domain.yForRow(rowEnd - 1) + 0.5;
    return HeatmapDataPoint(
      x: (xMinimum + xMaximum) / 2,
      y: (yMinimum + yMaximum) / 2,
      value: ((columnStart * 17 + rowStart * 31) % 101).toDouble(),
      pointKey: '${request.key.column}:${request.key.row}:$column:$row',
      bounds: HeatmapCellBounds(
        xMinimum: xMinimum,
        xMaximum: xMaximum,
        yMinimum: yMinimum,
        yMaximum: yMaximum,
      ),
    );
  }
}

final class _BenchmarkRasterResource implements HeatmapRasterResource {
  _BenchmarkRasterResource({
    required this.decodedByteCount,
    required this.onDispose,
  });

  @override
  final int decodedByteCount;
  final void Function() onDispose;
  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    onDispose();
  }
}
