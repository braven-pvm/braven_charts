// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ui';

import 'package:braven_charts/src/controllers/heatmap_raster_viewport_controller.dart';
import 'package:braven_charts/src/models/heatmap_color_scale.dart';
import 'package:braven_charts/src/models/heatmap_data_point.dart';
import 'package:braven_charts/src/models/heatmap_raster_viewport_source.dart';
import 'package:braven_charts/src/models/heatmap_viewport_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapRasterViewportController', () {
    test('publishes a complete viewport atomically', () async {
      final source = _ControlledRasterSource(columnCount: 4);
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 4,
        maxDecodedBytes: 64,
        maxTilesPerViewport: 2,
      );
      addTearDown(controller.dispose);

      final firstLoad = controller.loadViewport(_viewportForTile(0));
      final firstResource = source.complete(
        const HeatmapTileKey(column: 0, row: 0),
      );
      await firstLoad;
      expect(controller.snapshot.mountedTiles.single.resource, firstResource);

      final nextLoad = controller.loadViewport(
        const HeatmapViewportRequest(
          minimumX: 0.5,
          maximumX: 2.5,
          minimumY: -0.5,
          maximumY: 0.5,
        ),
      );
      expect(controller.snapshot.isLoading, isTrue);
      expect(controller.snapshot.mountedTiles.single.resource, firstResource);

      source.complete(const HeatmapTileKey(column: 1, row: 0));
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.snapshot.mountedTiles.single.resource,
        firstResource,
        reason: 'one completed tile must not partially replace the viewport',
      );
      source.complete(const HeatmapTileKey(column: 2, row: 0));
      await nextLoad;

      expect(controller.snapshot.isLoading, isFalse);
      expect(controller.snapshot.mountedTiles.map((tile) => tile.key), const [
        HeatmapTileKey(column: 1, row: 0),
        HeatmapTileKey(column: 2, row: 0),
      ]);
      expect(controller.snapshot.error, isNull);
    });

    test(
      'publishes every tile when a viewport is fully cache-backed',
      () async {
        final source = _ImmediateRasterSource(columnCount: 2, bytesPerTile: 4);
        final controller = HeatmapRasterViewportController(
          source: source,
          maxCachedTiles: 2,
          maxDecodedBytes: 16,
          maxTilesPerViewport: 2,
        );
        addTearDown(controller.dispose);
        const viewport = HeatmapViewportRequest(
          minimumX: -0.5,
          maximumX: 1.5,
          minimumY: -0.5,
          maximumY: 0.5,
        );

        await controller.loadViewport(viewport);
        expect(controller.snapshot.mountedTiles, hasLength(2));
        final sourceLoadCount = source.resources.length;

        await controller.loadViewport(viewport);

        expect(controller.snapshot.mountedTiles, hasLength(2));
        expect(controller.snapshot.requestedTileKeys, hasLength(2));
        expect(source.resources, hasLength(sourceLoadCount));
        expect(controller.snapshot.diagnostics.cacheHits, 2);
        expect(controller.snapshot.error, isNull);
      },
    );

    test(
      'rejects a stale generation without replacing the latest view',
      () async {
        final source = _ControlledRasterSource(columnCount: 3);
        final controller = HeatmapRasterViewportController(
          source: source,
          maxCachedTiles: 1,
          maxDecodedBytes: 8,
          maxTilesPerViewport: 1,
        );
        addTearDown(controller.dispose);

        final stale = controller.loadViewport(_viewportForTile(0));
        final latest = controller.loadViewport(_viewportForTile(1));
        final latestResource = source.complete(
          const HeatmapTileKey(column: 1, row: 0),
        );
        await latest;
        final staleResource = source.complete(
          const HeatmapTileKey(column: 0, row: 0),
        );
        await stale;

        expect(
          controller.snapshot.mountedTiles.single.resource,
          latestResource,
        );
        expect(controller.snapshot.mountedViewport, _viewportForTile(1));
        expect(controller.snapshot.diagnostics.stalePublicationsRejected, 1);
        expect(staleResource.disposeCount, 1);
        expect(latestResource.disposeCount, 0);
      },
    );

    test('enforces decoded-byte and tile-count LRU budgets', () async {
      final source = _ImmediateRasterSource(columnCount: 4, bytesPerTile: 8);
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 2,
        maxDecodedBytes: 16,
        maxTilesPerViewport: 1,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0));
      final first = source.resources.single;
      await controller.loadViewport(_viewportForTile(1));
      await controller.loadViewport(_viewportForTile(2));

      expect(controller.snapshot.diagnostics.cachedTileCount, 2);
      expect(controller.snapshot.diagnostics.decodedCacheBytes, 16);
      expect(controller.snapshot.diagnostics.evictions, 1);
      expect(first.disposeCount, 1);
      expect(
        controller.snapshot.mountedTiles.single.key,
        const HeatmapTileKey(column: 2, row: 0),
      );
    });

    test(
      'retains the last complete view when a tile exceeds the budget',
      () async {
        final source = _ImmediateRasterSource(columnCount: 2, bytesPerTile: 4);
        final controller = HeatmapRasterViewportController(
          source: source,
          maxCachedTiles: 2,
          maxDecodedBytes: 8,
          maxTilesPerViewport: 1,
        );
        addTearDown(controller.dispose);

        await controller.loadViewport(_viewportForTile(0));
        final retained = controller.snapshot.mountedTiles.single.resource;
        source.bytesPerTile = 12;
        await controller.loadViewport(_viewportForTile(1));

        expect(controller.snapshot.mountedTiles.single.resource, retained);
        expect(controller.snapshot.mountedViewport, _viewportForTile(0));
        expect(controller.snapshot.error, isA<StateError>());
        expect(source.resources.last.disposeCount, 1);
        expect((retained as _FakeRasterResource).disposeCount, 0);
      },
    );

    test(
      'rejects an aggregate viewport that exceeds the byte budget',
      () async {
        final source = _ControlledRasterSource(columnCount: 2);
        final controller = HeatmapRasterViewportController(
          source: source,
          maxCachedTiles: 2,
          maxDecodedBytes: 10,
          maxTilesPerViewport: 2,
        );
        addTearDown(controller.dispose);

        final load = controller.loadViewport(
          const HeatmapViewportRequest(
            minimumX: -0.5,
            maximumX: 1.5,
            minimumY: -0.5,
            maximumY: 0.5,
          ),
        );
        final first = source.complete(
          const HeatmapTileKey(column: 0, row: 0),
          bytes: 6,
        );
        final second = source.complete(
          const HeatmapTileKey(column: 1, row: 0),
          bytes: 6,
        );
        await load;

        expect(controller.snapshot.mountedTiles, isEmpty);
        expect(controller.snapshot.error, isA<StateError>());
        expect(
          controller.snapshot.diagnostics.decodedCacheBytes,
          lessThanOrEqualTo(10),
        );
        expect(first.disposeCount + second.disposeCount, 1);
      },
    );

    test('retains mounted fallback when a later load fails', () async {
      final source = _ImmediateRasterSource(columnCount: 2, bytesPerTile: 4);
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 2,
        maxDecodedBytes: 16,
        maxTilesPerViewport: 1,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0));
      final retained = controller.snapshot.mountedTiles.single.resource;
      source.failure = StateError('decode failed');
      await controller.loadViewport(_viewportForTile(1));

      expect(controller.snapshot.isLoading, isFalse);
      expect(controller.snapshot.mountedTiles.single.resource, retained);
      expect(controller.snapshot.error, isA<StateError>());
    });

    test('disposes cached and late resources exactly once', () async {
      final source = _ControlledRasterSource(columnCount: 2);
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 2,
        maxDecodedBytes: 16,
        maxTilesPerViewport: 1,
      );

      final firstLoad = controller.loadViewport(_viewportForTile(0));
      final first = source.complete(const HeatmapTileKey(column: 0, row: 0));
      await firstLoad;
      final lateLoad = controller.loadViewport(_viewportForTile(1));
      controller.dispose();
      final late = source.complete(const HeatmapTileKey(column: 1, row: 0));
      await lateLoad;

      expect(first.disposeCount, 1);
      expect(late.disposeCount, 1);
      controller.dispose();
      expect(first.disposeCount, 1);
      expect(late.disposeCount, 1);
    });

    test('rejects incorrect source bounds and disposes the resource', () async {
      final source = _ImmediateRasterSource(
        columnCount: 1,
        bytesPerTile: 4,
        offsetBounds: true,
      );
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 1,
        maxDecodedBytes: 8,
        maxTilesPerViewport: 1,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0));

      expect(controller.snapshot.mountedTiles, isEmpty);
      expect(controller.snapshot.error, isA<StateError>());
      expect(source.resources.single.disposeCount, 1);
    });

    test('publishes a bounded canonical semantic companion', () async {
      final source = _SemanticRasterSource(
        columnCount: 1,
        cellsFor: (_) => [
          HeatmapDataPoint(
            x: 0,
            y: 0,
            value: 73,
            pointKey: 'aggregate-0',
            label: 'Visible aggregate',
            bounds: HeatmapCellBounds(
              xMinimum: -0.5,
              xMaximum: 0.5,
              yMinimum: -0.5,
              yMaximum: 0.5,
            ),
          ),
        ],
      );
      final controller = HeatmapRasterViewportController(
        source: source,
        semanticDescriptor: _semanticDescriptor,
        maxCachedTiles: 1,
        maxDecodedBytes: 8,
        maxTilesPerViewport: 1,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0));

      expect(controller.snapshot.hasSemanticCompanion, isTrue);
      expect(controller.snapshot.semanticCells, hasLength(1));
      expect(controller.snapshot.semanticSeries!.id, 'visible-aggregates');
      expect(controller.snapshot.semanticSeries!.cells.single.value, 73);
      expect(controller.snapshot.semanticSeries!.metadata, {
        'aggregation': 'mean',
      });
      expect(controller.snapshot.semanticCells, isA<List<HeatmapDataPoint>>());
      expect(
        () => controller.snapshot.semanticCells.add(
          HeatmapDataPoint(x: 0, y: 0, value: 1),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects semantic cells when no descriptor is configured', () async {
      final source = _SemanticRasterSource(
        columnCount: 1,
        cellsFor: (_) => [HeatmapDataPoint(x: 0, y: 0, value: 1)],
      );
      final controller = HeatmapRasterViewportController(
        source: source,
        maxCachedTiles: 1,
        maxDecodedBytes: 8,
        maxTilesPerViewport: 1,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0));

      expect(controller.snapshot.mountedTiles, isEmpty);
      expect(controller.snapshot.error, isA<StateError>());
      expect(source.resources.single.disposeCount, 1);
    });

    test('rejects semantic bounds that escape their raster tile', () async {
      final source = _SemanticRasterSource(
        columnCount: 1,
        cellsFor: (_) => [
          HeatmapDataPoint(
            x: 0,
            y: 0,
            value: 1,
            bounds: HeatmapCellBounds(
              xMinimum: -0.6,
              xMaximum: 0.4,
              yMinimum: -0.5,
              yMaximum: 0.5,
            ),
          ),
        ],
      );
      final controller = HeatmapRasterViewportController(
        source: source,
        semanticDescriptor: _semanticDescriptor,
        maxCachedTiles: 1,
        maxDecodedBytes: 8,
        maxTilesPerViewport: 1,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(_viewportForTile(0));

      expect(controller.snapshot.mountedTiles, isEmpty);
      expect(controller.snapshot.error, isA<StateError>());
      expect(source.resources.single.disposeCount, 1);
    });

    test('rejects duplicate semantic identity across mounted tiles', () async {
      final source = _SemanticRasterSource(
        columnCount: 2,
        cellsFor: (request) => [
          HeatmapDataPoint(
            x: request.columnStart.toDouble(),
            y: 0,
            value: 1,
            pointKey: 'duplicate',
          ),
        ],
      );
      final controller = HeatmapRasterViewportController(
        source: source,
        semanticDescriptor: _semanticDescriptor,
        maxCachedTiles: 2,
        maxDecodedBytes: 16,
        maxTilesPerViewport: 2,
      );
      addTearDown(controller.dispose);

      await controller.loadViewport(
        const HeatmapViewportRequest(
          minimumX: -0.5,
          maximumX: 1.5,
          minimumY: -0.5,
          maximumY: 0.5,
        ),
      );

      expect(controller.snapshot.mountedTiles, isEmpty);
      expect(controller.snapshot.error, isA<StateError>());
    });
  });
}

final _semanticDescriptor = HeatmapRasterSemanticDescriptor(
  seriesId: 'visible-aggregates',
  name: 'Visible aggregates',
  metadata: const {'aggregation': 'mean'},
  colorScale: HeatmapColorScale.sequential(
    colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
    minimumValue: 0,
    maximumValue: 100,
  ),
);

HeatmapViewportRequest _viewportForTile(int column) => HeatmapViewportRequest(
  minimumX: column - 0.49,
  maximumX: column + 0.49,
  minimumY: -0.49,
  maximumY: 0.49,
);

class _FakeRasterResource implements HeatmapRasterResource {
  _FakeRasterResource(this.decodedByteCount);

  @override
  final int decodedByteCount;
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount++;
  }
}

class _ImmediateRasterSource implements HeatmapRasterTileSource {
  _ImmediateRasterSource({
    required int columnCount,
    required this.bytesPerTile,
    this.offsetBounds = false,
  }) : domain = HeatmapMatrixDomain(columnCount: columnCount, rowCount: 1);

  @override
  final HeatmapMatrixDomain domain;
  int bytesPerTile;
  final bool offsetBounds;
  Object? failure;
  final List<_FakeRasterResource> resources = [];

  @override
  int get tileColumnCount => 1;

  @override
  int get tileRowCount => 1;

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) async {
    final error = failure;
    if (error != null) throw error;
    final resource = _FakeRasterResource(bytesPerTile);
    resources.add(resource);
    return HeatmapRasterTile(
      key: request.key,
      bounds: _boundsFor(domain, request, offset: offsetBounds ? 1 : 0),
      resource: resource,
    );
  }
}

class _ControlledRasterSource implements HeatmapRasterTileSource {
  _ControlledRasterSource({required int columnCount})
    : domain = HeatmapMatrixDomain(columnCount: columnCount, rowCount: 1);

  @override
  final HeatmapMatrixDomain domain;
  final Map<HeatmapTileKey, Completer<HeatmapRasterTile>> completers = {};
  final Map<HeatmapTileKey, HeatmapTileRequest> requests = {};

  @override
  int get tileColumnCount => 1;

  @override
  int get tileRowCount => 1;

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) {
    requests[request.key] = request;
    return (completers[request.key] ??= Completer<HeatmapRasterTile>()).future;
  }

  _FakeRasterResource complete(HeatmapTileKey key, {int bytes = 4}) {
    final request = requests[key]!;
    final resource = _FakeRasterResource(bytes);
    completers[key]!.complete(
      HeatmapRasterTile(
        key: key,
        bounds: _boundsFor(domain, request),
        resource: resource,
      ),
    );
    return resource;
  }
}

class _SemanticRasterSource implements HeatmapRasterTileSource {
  _SemanticRasterSource({required int columnCount, required this.cellsFor})
    : domain = HeatmapMatrixDomain(columnCount: columnCount, rowCount: 1);

  @override
  final HeatmapMatrixDomain domain;
  final List<HeatmapDataPoint> Function(HeatmapTileRequest request) cellsFor;
  final List<_FakeRasterResource> resources = [];

  @override
  int get tileColumnCount => 1;

  @override
  int get tileRowCount => 1;

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) async {
    final resource = _FakeRasterResource(4);
    resources.add(resource);
    return HeatmapRasterTile(
      key: request.key,
      bounds: _boundsFor(domain, request),
      resource: resource,
      semanticCells: cellsFor(request),
    );
  }
}

HeatmapViewportBounds _boundsFor(
  HeatmapMatrixDomain domain,
  HeatmapTileRequest request, {
  double offset = 0,
}) => HeatmapViewportBounds(
  minimumX:
      domain.xForColumn(request.columnStart) - domain.cellWidth / 2 + offset,
  maximumX:
      domain.xForColumn(request.columnEndExclusive - 1) +
      domain.cellWidth / 2 +
      offset,
  minimumY: domain.yForRow(request.rowStart) - domain.cellHeight / 2,
  maximumY: domain.yForRow(request.rowEndExclusive - 1) + domain.cellHeight / 2,
);
