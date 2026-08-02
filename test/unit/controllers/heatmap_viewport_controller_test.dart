import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapMatrixDomain', () {
    final domain = HeatmapMatrixDomain(columnCount: 100, rowCount: 50);

    test('exposes full cell extents for explicit chart axes', () {
      expect(
        domain.fullBounds,
        const HeatmapViewportBounds(
          minimumX: -0.5,
          maximumX: 99.5,
          minimumY: -0.5,
          maximumY: 49.5,
        ),
      );
      expect(domain.cellCount, 5000);
    });

    test('resolves deterministic row-major tiles with overscan', () {
      final keys = domain.tileKeysFor(
        const HeatmapViewportRequest(
          minimumX: 9.5,
          maximumX: 19.5,
          minimumY: 9.5,
          maximumY: 19.5,
        ),
        tileColumnCount: 10,
        tileRowCount: 10,
        overscanColumns: 1,
        overscanRows: 1,
      );

      expect(keys, const [
        HeatmapTileKey(column: 0, row: 0),
        HeatmapTileKey(column: 1, row: 0),
        HeatmapTileKey(column: 2, row: 0),
        HeatmapTileKey(column: 0, row: 1),
        HeatmapTileKey(column: 1, row: 1),
        HeatmapTileKey(column: 2, row: 1),
        HeatmapTileKey(column: 0, row: 2),
        HeatmapTileKey(column: 1, row: 2),
        HeatmapTileKey(column: 2, row: 2),
      ]);
    });

    test('clamps edge requests and rejects out-of-domain tiles', () {
      final keys = domain.tileKeysFor(
        const HeatmapViewportRequest(
          minimumX: -10,
          maximumX: 4.5,
          minimumY: 44.5,
          maximumY: 60,
        ),
        tileColumnCount: 10,
        tileRowCount: 10,
        overscanColumns: 4,
        overscanRows: 4,
      );

      expect(keys, const [HeatmapTileKey(column: 0, row: 4)]);
      expect(
        domain.tileKeysFor(
          const HeatmapViewportRequest(
            minimumX: 120,
            maximumX: 140,
            minimumY: 0,
            maximumY: 10,
          ),
          tileColumnCount: 10,
          tileRowCount: 10,
        ),
        isEmpty,
      );
      expect(
        () => domain.tileRequestFor(
          const HeatmapTileKey(column: 10, row: 0),
          tileColumnCount: 10,
          tileRowCount: 10,
        ),
        throwsArgumentError,
      );
    });

    test('creates clamped requests for partial edge tiles', () {
      final partial = HeatmapMatrixDomain(columnCount: 23, rowCount: 17)
          .tileRequestFor(
            const HeatmapTileKey(column: 2, row: 1),
            tileColumnCount: 10,
            tileRowCount: 10,
          );

      expect(partial.columnStart, 20);
      expect(partial.columnEndExclusive, 23);
      expect(partial.rowStart, 10);
      expect(partial.rowEndExclusive, 17);
      expect(partial.maximumCellCount, 21);
    });

    test('maps a regular cell to its stable tile', () {
      expect(
        domain.tileKeyForCell(29, 31, tileColumnCount: 10, tileRowCount: 8),
        const HeatmapTileKey(column: 2, row: 3),
      );
      expect(
        () =>
            domain.tileKeyForCell(100, 0, tileColumnCount: 10, tileRowCount: 8),
        throwsRangeError,
      );
    });
  });

  group('HeatmapViewportController', () {
    test(
      'publishes a bounded snapshot and materializes a normal series',
      () async {
        final source = _ProceduralTileSource();
        final controller = HeatmapViewportController(
          source: source,
          overscanColumns: 0,
          overscanRows: 0,
        );
        addTearDown(controller.dispose);

        await controller.loadViewport(_viewportForTile(1, 2));

        expect(controller.snapshot.isLoading, isFalse);
        expect(controller.snapshot.requestedTiles, const [
          HeatmapTileKey(column: 1, row: 2),
        ]);
        expect(controller.snapshot.cells, hasLength(100));
        expect(controller.snapshot.cells.first.pointKey, '20:10');
        expect(controller.snapshot.cells.last.pointKey, '29:19');
        final series = controller.snapshot.materializeSeries(
          HeatmapChartSeries(
            id: 'massive',
            points: const [],
            colorScale: HeatmapColorScale.sequential(
              colors: const [Colors.white, Colors.blue],
            ),
          ),
        );
        expect(series.cells, controller.snapshot.cells);
        expect(source.loadCounts.values.single, 1);
      },
    );

    test('uses deterministic LRU promotion and eviction', () async {
      final source = _ProceduralTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        maxCachedTiles: 2,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0, 0));
      await controller.loadViewport(_viewportForTile(1, 0));
      await controller.loadViewport(_viewportForTile(0, 0));
      await controller.loadViewport(_viewportForTile(2, 0));
      await controller.loadViewport(_viewportForTile(1, 0));

      expect(source.totalLoads, 4);
      expect(controller.diagnostics.cacheHits, 1);
      expect(controller.diagnostics.cacheMisses, 4);
      expect(controller.snapshot.cacheTileCount, 2);
    });

    test('publishes every resident cell for an all-cache viewport', () async {
      final source = _ProceduralTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
      );
      addTearDown(controller.dispose);

      const firstViewport = HeatmapViewportRequest(
        minimumX: -0.4,
        maximumX: 19.4,
        minimumY: -0.4,
        maximumY: 9.4,
      );
      const cachedViewport = HeatmapViewportRequest(
        minimumX: 1,
        maximumX: 18,
        minimumY: 1,
        maximumY: 8,
      );
      await controller.loadViewport(firstViewport);
      expect(controller.snapshot.cells, hasLength(200));

      await controller.loadViewport(cachedViewport);

      expect(controller.snapshot.requestedTiles, const [
        HeatmapTileKey(column: 0, row: 0),
        HeatmapTileKey(column: 1, row: 0),
      ]);
      expect(controller.snapshot.cells, hasLength(200));
      expect(source.totalLoads, 2);
      expect(controller.diagnostics.cacheHits, 2);
    });

    test(
      'deduplicates in-flight loads and rejects stale publication',
      () async {
        final source = _ControlledTileSource();
        final controller = HeatmapViewportController(
          source: source,
          overscanColumns: 0,
          overscanRows: 0,
        );
        addTearDown(controller.dispose);

        final first = controller.loadViewport(_viewportForTile(0, 0));
        final second = controller.loadViewport(
          const HeatmapViewportRequest(
            minimumX: 1,
            maximumX: 8,
            minimumY: 1,
            maximumY: 8,
          ),
        );
        expect(source.loadCount, 1);
        source.complete(const HeatmapTileKey(column: 0, row: 0));
        await Future.wait([first, second]);

        expect(controller.diagnostics.inFlightJoins, 1);
        expect(controller.diagnostics.stalePublicationsRejected, 1);
        expect(controller.snapshot.generation, 2);
        expect(controller.snapshot.cells, hasLength(100));
      },
    );

    test('a newer tile can publish before a superseded slower tile', () async {
      final source = _ControlledTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
      );
      addTearDown(controller.dispose);

      final first = controller.loadViewport(_viewportForTile(0, 0));
      final second = controller.loadViewport(_viewportForTile(1, 0));
      source.complete(const HeatmapTileKey(column: 1, row: 0));
      await second;
      expect(controller.snapshot.cells.first.pointKey, '0:10');

      source.complete(const HeatmapTileKey(column: 0, row: 0));
      await first;
      expect(controller.snapshot.cells.first.pointKey, '0:10');
      expect(controller.diagnostics.stalePublicationsRejected, 1);
    });

    test('current failures retain the previous complete cells', () async {
      final source = _ProceduralTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
      );
      addTearDown(controller.dispose);
      await controller.loadViewport(_viewportForTile(0, 0));
      final previous = controller.snapshot.cells;
      source.failureKey = const HeatmapTileKey(column: 1, row: 0);

      await controller.loadViewport(_viewportForTile(1, 0));

      expect(controller.snapshot.hasError, isTrue);
      expect(controller.snapshot.isLoading, isFalse);
      expect(controller.snapshot.cells, orderedEquals(previous));
    });

    test(
      'oversized viewports are rejected before starting tile loads',
      () async {
        final source = _ProceduralTileSource();
        final controller = HeatmapViewportController(
          source: source,
          overscanColumns: 0,
          overscanRows: 0,
          maxTilesPerViewport: 4,
        );
        addTearDown(controller.dispose);
        await controller.loadViewport(_viewportForTile(0, 0));
        final previous = controller.snapshot.cells;

        await controller.loadViewport(
          const HeatmapViewportRequest(
            minimumX: -0.5,
            maximumX: 99.5,
            minimumY: -0.5,
            maximumY: 99.5,
          ),
        );

        expect(controller.snapshot.hasError, isTrue);
        expect(controller.snapshot.error, isA<StateError>());
        expect(controller.snapshot.requestedTiles, isEmpty);
        expect(controller.snapshot.cells, orderedEquals(previous));
        expect(source.totalLoads, 1);
      },
    );

    test('duplicate settled viewport pulses do not reload tiles', () async {
      final source = _ProceduralTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        debounceDuration: Duration.zero,
      );
      addTearDown(controller.dispose);
      final viewport = _viewportForTile(0, 0);
      await controller.loadViewport(viewport);

      controller.requestViewport(viewport);
      await Future<void>.delayed(Duration.zero);

      expect(source.totalLoads, 1);
      expect(controller.snapshot.generation, 1);
    });

    test('scheduled viewport pulses coalesce to the latest request', () async {
      final source = _ProceduralTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        debounceDuration: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.requestViewport(_viewportForTile(0, 0));
      controller.requestViewport(_viewportForTile(1, 0));
      controller.requestViewport(_viewportForTile(2, 0));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(source.totalLoads, 1);
      expect(controller.snapshot.requestedTiles, const [
        HeatmapTileKey(column: 2, row: 0),
      ]);
    });

    test(
      'coalesces ordered cell mutations into one immutable publication',
      () async {
        final source = _MutableTileSource();
        final controller = HeatmapViewportController(
          source: source,
          overscanColumns: 0,
          overscanRows: 0,
          mutationPublishDuration: const Duration(milliseconds: 10),
        );
        addTearDown(controller.dispose);
        await controller.loadViewport(_viewportForTile(0, 0));
        var notifications = 0;
        controller.addListener(() => notifications++);

        final first = HeatmapDataPoint(x: 2, y: 3, value: 40, pointKey: '3:2');
        source.upsert(2, 3, first);
        expect(
          controller.applyMutationBatch(
            HeatmapMutationBatch(
              revision: 1,
              mutations: [HeatmapCellUpsert(column: 2, row: 3, cell: first)],
            ),
          ),
          isTrue,
        );
        final second = first.copyWith(value: 88);
        source.upsert(2, 3, second);
        controller.applyMutationBatch(
          HeatmapMutationBatch(
            revision: 2,
            mutations: [HeatmapCellUpsert(column: 2, row: 3, cell: second)],
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(notifications, 1);
        expect(_cellAt(controller.snapshot.cells, 2, 3).value, 88);
        expect(controller.diagnostics.lastMutationRevision, 2);
        expect(controller.diagnostics.mutationBatchesAccepted, 2);
        expect(controller.diagnostics.cellMutationsApplied, 2);
        expect(controller.diagnostics.mutationPublications, 1);
      },
    );

    test('ignores stale revisions and supports sparse cell removal', () async {
      final source = _MutableTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        mutationPublishDuration: Duration.zero,
      );
      addTearDown(controller.dispose);
      await controller.loadViewport(_viewportForTile(0, 0));

      source.remove(4, 5);
      expect(
        controller.applyMutationBatch(
          HeatmapMutationBatch(
            revision: 7,
            mutations: const [HeatmapCellRemoval(column: 4, row: 5)],
          ),
        ),
        isTrue,
      );
      expect(
        controller.applyMutationBatch(
          HeatmapMutationBatch(
            revision: 7,
            mutations: const [HeatmapCellRemoval(column: 1, row: 1)],
          ),
        ),
        isFalse,
      );

      expect(
        controller.snapshot.cells.where((cell) => cell.x == 4 && cell.y == 5),
        isEmpty,
      );
      expect(controller.diagnostics.staleMutationBatchesIgnored, 1);
    });

    test('overlays a mutation on a tile that was already loading', () async {
      final source = _ControlledTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        mutationPublishDuration: Duration.zero,
      );
      addTearDown(controller.dispose);

      final loading = controller.loadViewport(_viewportForTile(0, 0));
      final cell = HeatmapDataPoint(x: 2, y: 3, value: 777, pointKey: '3:2');
      controller.applyMutationBatch(
        HeatmapMutationBatch(
          revision: 1,
          mutations: [HeatmapCellUpsert(column: 2, row: 3, cell: cell)],
        ),
      );
      source.complete(const HeatmapTileKey(column: 0, row: 0));
      await loading;

      expect(_cellAt(controller.snapshot.cells, 2, 3).value, 777);
    });

    test('visible tile invalidation reloads current source truth', () async {
      final source = _MutableTileSource();
      final controller = HeatmapViewportController(
        source: source,
        overscanColumns: 0,
        overscanRows: 0,
        mutationPublishDuration: Duration.zero,
      );
      addTearDown(controller.dispose);
      await controller.loadViewport(_viewportForTile(0, 0));
      expect(_cellAt(controller.snapshot.cells, 2, 3).value, 5);
      source.upsert(
        2,
        3,
        HeatmapDataPoint(x: 2, y: 3, value: 99, pointKey: '3:2'),
      );

      controller.applyMutationBatch(
        HeatmapMutationBatch(
          revision: 1,
          mutations: const [
            HeatmapTileInvalidation(HeatmapTileKey(column: 0, row: 0)),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(source.totalLoads, 2);
      expect(_cellAt(controller.snapshot.cells, 2, 3).value, 99);
    });
  });
}

HeatmapDataPoint _cellAt(
  Iterable<HeatmapDataPoint> cells,
  double x,
  double y,
) => cells.singleWhere((cell) => cell.x == x && cell.y == y);

HeatmapViewportRequest _viewportForTile(int column, int row) =>
    HeatmapViewportRequest(
      minimumX: column * 10 - 0.4,
      maximumX: column * 10 + 9.4,
      minimumY: row * 10 - 0.4,
      maximumY: row * 10 + 9.4,
    );

class _ProceduralTileSource implements HeatmapTileSource {
  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 100,
    rowCount: 100,
  );

  @override
  int get tileColumnCount => 10;

  @override
  int get tileRowCount => 10;

  final Map<HeatmapTileKey, int> loadCounts = {};
  HeatmapTileKey? failureKey;
  int get totalLoads => loadCounts.values.fold(0, (sum, value) => sum + value);

  @override
  Future<HeatmapTile> loadTile(HeatmapTileRequest request) async {
    loadCounts.update(request.key, (count) => count + 1, ifAbsent: () => 1);
    if (request.key == failureKey) throw StateError('tile failed');
    return _tileFor(domain, request);
  }
}

class _MutableTileSource extends _ProceduralTileSource {
  final Map<(int, int), HeatmapDataPoint?> _changes = {};

  void upsert(int column, int row, HeatmapDataPoint cell) {
    _changes[(column, row)] = cell;
  }

  void remove(int column, int row) {
    _changes[(column, row)] = null;
  }

  @override
  Future<HeatmapTile> loadTile(HeatmapTileRequest request) async {
    final base = await super.loadTile(request);
    final cells = <(int, int), HeatmapDataPoint>{
      for (final cell in base.cells) (cell.x.round(), cell.y.round()): cell,
    };
    for (final entry in _changes.entries) {
      final (column, row) = entry.key;
      if (column < request.columnStart ||
          column >= request.columnEndExclusive ||
          row < request.rowStart ||
          row >= request.rowEndExclusive) {
        continue;
      }
      final cell = entry.value;
      if (cell == null) {
        cells.remove(entry.key);
      } else {
        cells[entry.key] = cell;
      }
    }
    return HeatmapTile(key: request.key, cells: cells.values.toList());
  }
}

class _ControlledTileSource implements HeatmapTileSource {
  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 100,
    rowCount: 100,
  );

  @override
  int get tileColumnCount => 10;

  @override
  int get tileRowCount => 10;

  final Map<HeatmapTileKey, Completer<HeatmapTile>> completers = {};
  final Map<HeatmapTileKey, HeatmapTileRequest> requests = {};
  int loadCount = 0;

  @override
  Future<HeatmapTile> loadTile(HeatmapTileRequest request) {
    loadCount++;
    requests[request.key] = request;
    return (completers[request.key] ??= Completer<HeatmapTile>()).future;
  }

  void complete(HeatmapTileKey key) {
    completers[key]!.complete(_tileFor(domain, requests[key]!));
  }
}

HeatmapTile _tileFor(HeatmapMatrixDomain domain, HeatmapTileRequest request) =>
    HeatmapTile(
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
              value: (row + column).toDouble(),
              pointKey: '$row:$column',
            ),
      ],
    );
