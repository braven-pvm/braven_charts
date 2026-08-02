// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('24M-cell source keeps 100 moving viewport loads bounded', () async {
    final source = _BenchmarkTileSource();
    final controller = HeatmapViewportController(
      source: source,
      overscanColumns: 32,
      overscanRows: 0,
      maxCachedTiles: 12,
      maxTilesPerViewport: 8,
      debounceDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    final stopwatch = Stopwatch()..start();
    for (var step = 0; step < 100; step++) {
      final minimumX = step * 97.0;
      await controller.loadViewport(
        HeatmapViewportRequest(
          minimumX: minimumX,
          maximumX: minimumX + 299,
          minimumY: -0.5,
          maximumY: 23.5,
        ),
      );
      expect(controller.snapshot.cells.length, lessThanOrEqualTo(12288));
      expect(controller.snapshot.requestedTiles.length, lessThanOrEqualTo(8));
      expect(controller.snapshot.cacheTileCount, lessThanOrEqualTo(12));
    }
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Heatmap viewport controller '
      '(24,000,000 conceptual cells / 100 moving windows): '
      '${elapsedMs.toStringAsFixed(3)}ms, '
      '${source.loadCount} tile loads',
    );
    expect(controller.snapshot.hasError, isFalse);
    expect(controller.snapshot.cells, isNotEmpty);
    expect(source.loadCount, lessThan(120));
    expect(elapsedMs, lessThan(10000));
  });

  test(
    '2400 streamed cell updates coalesce without growing residency',
    () async {
      final source = _BenchmarkTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        maxCachedTiles: 12,
        maxTilesPerViewport: 8,
        mutationPublishDuration: const Duration(milliseconds: 20),
      );
      addTearDown(controller.dispose);
      await controller.loadViewport(
        const HeatmapViewportRequest(
          minimumX: -0.4,
          maximumX: 299.4,
          minimumY: -0.4,
          maximumY: 23.4,
        ),
      );

      final stopwatch = Stopwatch()..start();
      for (var revision = 1; revision <= 100; revision++) {
        controller.applyMutationBatch(
          HeatmapMutationBatch(
            revision: revision,
            mutations: [
              for (var row = 0; row < 24; row++)
                HeatmapCellUpsert(
                  column: revision,
                  row: row,
                  cell: HeatmapDataPoint(
                    x: revision.toDouble(),
                    y: row.toDouble(),
                    value: ((revision + row) % 100).toDouble(),
                    pointKey: '$row:$revision',
                  ),
                ),
            ],
          ),
        );
      }
      stopwatch.stop();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      // ignore: avoid_print
      print(
        'Heatmap live controller (2400 updates): '
        '${elapsedMs.toStringAsFixed(3)}ms, '
        '${controller.diagnostics.mutationPublications} publication',
      );
      expect(controller.diagnostics.mutationBatchesAccepted, 100);
      expect(controller.diagnostics.cellMutationsApplied, 2400);
      expect(controller.diagnostics.mutationPublications, 1);
      expect(controller.snapshot.cacheTileCount, lessThanOrEqualTo(12));
      expect(controller.snapshot.cells.length, lessThanOrEqualTo(12288));
      expect(elapsedMs, lessThan(1000));
    },
  );
}

final class _BenchmarkTileSource implements HeatmapTileSource {
  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 1000000,
    rowCount: 24,
  );

  @override
  int get tileColumnCount => 128;

  @override
  int get tileRowCount => 24;

  int loadCount = 0;

  @override
  Future<HeatmapTile> loadTile(HeatmapTileRequest request) async {
    loadCount++;
    return HeatmapTile(
      key: request.key,
      cells: [
        for (var row = request.rowStart; row < request.rowEndExclusive; row++)
          for (
            var column = request.columnStart;
            column < request.columnEndExclusive;
            column++
          )
            HeatmapDataPoint(
              x: domain.xForColumn(column),
              y: domain.yForRow(row),
              value: ((column * 17 + row * 31) % 100).toDouble(),
              pointKey: '$row:$column',
            ),
      ],
    );
  }
}
