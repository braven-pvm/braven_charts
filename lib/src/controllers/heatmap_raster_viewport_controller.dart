// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/heatmap_chart_series.dart';
import '../models/heatmap_data_point.dart';
import '../models/heatmap_raster_viewport_source.dart';
import '../models/heatmap_viewport_source.dart';

/// Diagnostics for the host-owned raster tile lifecycle.
@immutable
final class HeatmapRasterViewportDiagnostics {
  const HeatmapRasterViewportDiagnostics({
    required this.generation,
    required this.cachedTileCount,
    required this.decodedCacheBytes,
    required this.cacheHits,
    required this.cacheMisses,
    required this.loadsStarted,
    required this.evictions,
    required this.resourcesDisposed,
    required this.stalePublicationsRejected,
  });

  final int generation;
  final int cachedTileCount;
  final int decodedCacheBytes;
  final int cacheHits;
  final int cacheMisses;
  final int loadsStarted;
  final int evictions;
  final int resourcesDisposed;
  final int stalePublicationsRejected;
}

/// An immutable, atomically published raster viewport.
///
/// While a newer request is loading or has failed, [mountedTiles] and
/// [mountedViewport] continue to describe the last complete viewport.
@immutable
final class HeatmapRasterViewportSnapshot {
  HeatmapRasterViewportSnapshot({
    required this.generation,
    required this.requestedViewport,
    required this.mountedViewport,
    required Iterable<HeatmapTileKey> requestedTileKeys,
    required Iterable<HeatmapRasterTile> mountedTiles,
    required this.semanticDescriptor,
    required this.isLoading,
    required this.diagnostics,
    this.error,
    this.stackTrace,
  }) : requestedTileKeys = List<HeatmapTileKey>.unmodifiable(requestedTileKeys),
       mountedTiles = List<HeatmapRasterTile>.unmodifiable(mountedTiles);

  factory HeatmapRasterViewportSnapshot.initial() =>
      const _InitialHeatmapRasterViewportSnapshot().snapshot;

  final int generation;
  final HeatmapViewportRequest? requestedViewport;
  final HeatmapViewportRequest? mountedViewport;
  final List<HeatmapTileKey> requestedTileKeys;
  final List<HeatmapRasterTile> mountedTiles;
  final HeatmapRasterSemanticDescriptor? semanticDescriptor;
  final bool isLoading;
  final HeatmapRasterViewportDiagnostics diagnostics;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasMountedTiles => mountedTiles.isNotEmpty;

  /// Canonical cells supplied by the host for the complete mounted viewport.
  late final List<HeatmapDataPoint> semanticCells = List.unmodifiable([
    for (final tile in mountedTiles) ...tile.semanticCells,
  ]);

  /// Bounded canonical series used by interaction, accessibility, Data, and
  /// Source. Null keeps the mounted raster presentation-only.
  late final HeatmapChartSeries? semanticSeries = semanticDescriptor
      ?.buildSeries(semanticCells);

  bool get hasSemanticCompanion => semanticSeries?.cells.isNotEmpty ?? false;
}

final class _InitialHeatmapRasterViewportSnapshot {
  const _InitialHeatmapRasterViewportSnapshot();

  HeatmapRasterViewportSnapshot get snapshot => HeatmapRasterViewportSnapshot(
    generation: 0,
    requestedViewport: null,
    mountedViewport: null,
    requestedTileKeys: const [],
    mountedTiles: const [],
    semanticDescriptor: null,
    isLoading: false,
    diagnostics: const HeatmapRasterViewportDiagnostics(
      generation: 0,
      cachedTileCount: 0,
      decodedCacheBytes: 0,
      cacheHits: 0,
      cacheMisses: 0,
      loadsStarted: 0,
      evictions: 0,
      resourcesDisposed: 0,
      stalePublicationsRejected: 0,
    ),
  );
}

/// Resolves and owns decoded raster tiles for one Heatmap viewport.
///
/// This controller is intentionally independent from `ChartRenderBox`. It
/// publishes only complete mounted snapshots, applies both tile-count and
/// decoded-byte LRU limits, and owns exact-once resource disposal.
final class HeatmapRasterViewportController extends ChangeNotifier {
  HeatmapRasterViewportController({
    required this.source,
    this.semanticDescriptor,
    this.maxCachedTiles = 64,
    this.maxDecodedBytes = 64 * 1024 * 1024,
    this.maxTilesPerViewport = 16,
    this.overscanColumns = 0,
    this.overscanRows = 0,
  }) {
    if (maxCachedTiles <= 0) {
      throw ArgumentError.value(maxCachedTiles, 'maxCachedTiles', 'positive');
    }
    if (maxDecodedBytes <= 0) {
      throw ArgumentError.value(maxDecodedBytes, 'maxDecodedBytes', 'positive');
    }
    if (maxTilesPerViewport <= 0) {
      throw ArgumentError.value(
        maxTilesPerViewport,
        'maxTilesPerViewport',
        'positive',
      );
    }
    if (maxTilesPerViewport > maxCachedTiles) {
      throw ArgumentError(
        'maxCachedTiles must accommodate maxTilesPerViewport',
      );
    }
    if (overscanColumns < 0 || overscanRows < 0) {
      throw ArgumentError('Heatmap raster overscan must be non-negative');
    }
    if (source.tileColumnCount <= 0 || source.tileRowCount <= 0) {
      throw ArgumentError('Heatmap raster tile dimensions must be positive');
    }
  }

  final HeatmapRasterTileSource source;

  /// Optional metadata that turns tile-provided semantic cells into one
  /// bounded canonical series. Without it raster tiles remain pixel-only.
  final HeatmapRasterSemanticDescriptor? semanticDescriptor;
  final int maxCachedTiles;
  final int maxDecodedBytes;
  final int maxTilesPerViewport;
  final int overscanColumns;
  final int overscanRows;

  final LinkedHashMap<HeatmapTileKey, HeatmapRasterTile> _cache =
      LinkedHashMap<HeatmapTileKey, HeatmapRasterTile>();
  final Map<HeatmapTileKey, Future<HeatmapRasterTile>> _inFlight = {};
  final Set<HeatmapRasterResource> _disposedResources = HashSet.identity();

  HeatmapRasterViewportSnapshot _snapshot =
      HeatmapRasterViewportSnapshot.initial();
  int _generation = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _loadsStarted = 0;
  int _evictions = 0;
  int _resourcesDisposed = 0;
  int _stalePublicationsRejected = 0;
  bool _disposed = false;

  HeatmapRasterViewportSnapshot get snapshot => _snapshot;

  Future<void> loadViewport(HeatmapViewportRequest viewport) async {
    _ensureActive();
    viewport.validate();
    final generation = ++_generation;
    final requestedKeys = source.domain.tileKeysFor(
      viewport,
      tileColumnCount: source.tileColumnCount,
      tileRowCount: source.tileRowCount,
      overscanColumns: overscanColumns,
      overscanRows: overscanRows,
      maximumTileCount: maxTilesPerViewport,
    );

    _publish(
      generation: generation,
      requestedViewport: viewport,
      mountedViewport: _snapshot.mountedViewport,
      requestedTileKeys: requestedKeys,
      mountedTiles: _snapshot.mountedTiles,
      isLoading: true,
    );

    try {
      final tiles = await Future.wait(requestedKeys.map(_resolveTile));
      if (_disposed) return;
      if (generation != _generation) {
        _stalePublicationsRejected++;
        _trimCache(protectedKeys: _mountedKeys);
        _refreshDiagnostics();
        return;
      }

      final mountedBytes = tiles.fold<int>(
        0,
        (sum, tile) => sum + tile.resource.decodedByteCount,
      );
      if (mountedBytes > maxDecodedBytes) {
        throw StateError(
          'Heatmap raster viewport requires $mountedBytes decoded bytes, '
          'exceeding the configured limit of $maxDecodedBytes',
        );
      }
      _validateMountedSemantics(tiles);

      final protectedKeys = requestedKeys.toSet();
      // Make the complete replacement current before old mounted resources
      // become eviction candidates. No listener observes this intermediate
      // assignment; the post-trim snapshot below is the atomic publication.
      _snapshot = HeatmapRasterViewportSnapshot(
        generation: generation,
        requestedViewport: viewport,
        mountedViewport: viewport,
        requestedTileKeys: requestedKeys,
        mountedTiles: tiles,
        semanticDescriptor: semanticDescriptor,
        isLoading: false,
        diagnostics: _diagnostics,
      );
      _trimCache(protectedKeys: protectedKeys);
      _refreshDiagnostics();
    } catch (error, stackTrace) {
      if (_disposed) return;
      if (generation != _generation) {
        _stalePublicationsRejected++;
        _trimCache(protectedKeys: _mountedKeys);
        _refreshDiagnostics();
        return;
      }
      _trimCache(protectedKeys: _mountedKeys);
      _publish(
        generation: generation,
        requestedViewport: viewport,
        mountedViewport: _snapshot.mountedViewport,
        requestedTileKeys: requestedKeys,
        mountedTiles: _snapshot.mountedTiles,
        isLoading: false,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<HeatmapRasterTile> _resolveTile(HeatmapTileKey key) {
    final cached = _cache.remove(key);
    if (cached != null) {
      _cacheHits++;
      _cache[key] = cached;
      // Future.wait registers each callback while iterating the input. A
      // SynchronousFuture may invoke that callback before Future.wait has
      // finished accounting for the batch, producing an incomplete result
      // when an entire viewport is served from cache.
      return Future<HeatmapRasterTile>.value(cached);
    }
    _cacheMisses++;
    return _inFlight[key] ??= _loadAndCache(key);
  }

  Future<HeatmapRasterTile> _loadAndCache(HeatmapTileKey key) async {
    _loadsStarted++;
    try {
      final request = source.domain.tileRequestFor(
        key,
        tileColumnCount: source.tileColumnCount,
        tileRowCount: source.tileRowCount,
      );
      final tile = await source.loadTile(request);
      if (_disposed) {
        _disposeResource(tile.resource);
        throw StateError('HeatmapRasterViewportController has been disposed');
      }
      _validateTile(tile, request);
      final existing = _cache.remove(key);
      if (existing != null && !identical(existing.resource, tile.resource)) {
        _disposeResource(tile.resource);
        _cache[key] = existing;
        return existing;
      }
      _cache[key] = tile;
      return tile;
    } catch (error) {
      rethrow;
    } finally {
      _inFlight.remove(key);
    }
  }

  void _validateTile(HeatmapRasterTile tile, HeatmapTileRequest request) {
    try {
      if (tile.key != request.key) {
        throw StateError(
          'Heatmap raster source returned ${tile.key} for ${request.key}',
        );
      }
      tile.bounds.validate(parameterName: 'tile.bounds');
      final expected = _boundsFor(request);
      if (!_sameBounds(tile.bounds, expected)) {
        throw StateError(
          'Heatmap raster tile ${tile.key} returned bounds ${tile.bounds}; '
          'expected $expected',
        );
      }
      if (tile.revision < 0) {
        throw StateError('Heatmap raster tile revisions must be non-negative');
      }
      if (tile.resource.decodedByteCount <= 0) {
        throw StateError('Heatmap raster resources must report positive bytes');
      }
      if (tile.resource.decodedByteCount > maxDecodedBytes) {
        throw StateError(
          'Heatmap raster tile ${tile.key} requires '
          '${tile.resource.decodedByteCount} decoded bytes, exceeding the '
          'configured limit of $maxDecodedBytes',
        );
      }
      if (semanticDescriptor == null && tile.semanticCells.isNotEmpty) {
        throw StateError(
          'Heatmap raster tile ${tile.key} supplied semantic cells without '
          'a semanticDescriptor on the viewport controller',
        );
      }
      final identities = <Object>{};
      for (final cell in tile.semanticCells) {
        final cellBounds = cell.bounds;
        final insideTile = cellBounds == null
            ? cell.x >= tile.bounds.minimumX &&
                  cell.x <= tile.bounds.maximumX &&
                  cell.y >= tile.bounds.minimumY &&
                  cell.y <= tile.bounds.maximumY
            : cellBounds.xMinimum >= tile.bounds.minimumX &&
                  cellBounds.xMaximum <= tile.bounds.maximumX &&
                  cellBounds.yMinimum >= tile.bounds.minimumY &&
                  cellBounds.yMaximum <= tile.bounds.maximumY;
        if (!insideTile) {
          throw StateError(
            'Heatmap raster semantic cell ${cell.identity} falls outside '
            'tile ${tile.key} bounds ${tile.bounds}',
          );
        }
        if (!identities.add(cell.identity)) {
          throw StateError(
            'Heatmap raster tile ${tile.key} contains duplicate semantic '
            'cell identity ${cell.identity}',
          );
        }
      }
    } catch (_) {
      _disposeResource(tile.resource);
      rethrow;
    }
  }

  void _validateMountedSemantics(Iterable<HeatmapRasterTile> tiles) {
    final identities = <Object>{};
    for (final tile in tiles) {
      for (final cell in tile.semanticCells) {
        if (!identities.add(cell.identity)) {
          throw StateError(
            'Heatmap raster mounted viewport contains duplicate semantic '
            'cell identity ${cell.identity}',
          );
        }
      }
    }
  }

  HeatmapViewportBounds _boundsFor(HeatmapTileRequest request) =>
      HeatmapViewportBounds(
        minimumX:
            source.domain.xForColumn(request.columnStart) -
            source.domain.cellWidth / 2,
        maximumX:
            source.domain.xForColumn(request.columnEndExclusive - 1) +
            source.domain.cellWidth / 2,
        minimumY:
            source.domain.yForRow(request.rowStart) -
            source.domain.cellHeight / 2,
        maximumY:
            source.domain.yForRow(request.rowEndExclusive - 1) +
            source.domain.cellHeight / 2,
      );

  bool _sameBounds(HeatmapViewportBounds left, HeatmapViewportBounds right) {
    const epsilon = 0.000000001;
    return (left.minimumX - right.minimumX).abs() <= epsilon &&
        (left.maximumX - right.maximumX).abs() <= epsilon &&
        (left.minimumY - right.minimumY).abs() <= epsilon &&
        (left.maximumY - right.maximumY).abs() <= epsilon;
  }

  Set<HeatmapTileKey> get _mountedKeys =>
      _snapshot.mountedTiles.map((tile) => tile.key).toSet();

  int get _decodedCacheBytes => _cache.values.fold<int>(
    0,
    (sum, tile) => sum + tile.resource.decodedByteCount,
  );

  void _trimCache({required Set<HeatmapTileKey> protectedKeys}) {
    while (_cache.length > maxCachedTiles ||
        _decodedCacheBytes > maxDecodedBytes) {
      HeatmapTileKey? evictionKey;
      for (final key in _cache.keys) {
        if (!protectedKeys.contains(key)) {
          evictionKey = key;
          break;
        }
      }
      if (evictionKey == null) return;
      final evicted = _cache.remove(evictionKey)!;
      _evictions++;
      _disposeResource(evicted.resource);
    }
  }

  void _disposeResource(HeatmapRasterResource resource) {
    if (!_disposedResources.add(resource)) return;
    resource.dispose();
    _resourcesDisposed++;
  }

  HeatmapRasterViewportDiagnostics get _diagnostics =>
      HeatmapRasterViewportDiagnostics(
        generation: _generation,
        cachedTileCount: _cache.length,
        decodedCacheBytes: _decodedCacheBytes,
        cacheHits: _cacheHits,
        cacheMisses: _cacheMisses,
        loadsStarted: _loadsStarted,
        evictions: _evictions,
        resourcesDisposed: _resourcesDisposed,
        stalePublicationsRejected: _stalePublicationsRejected,
      );

  void _publish({
    required int generation,
    required HeatmapViewportRequest? requestedViewport,
    required HeatmapViewportRequest? mountedViewport,
    required Iterable<HeatmapTileKey> requestedTileKeys,
    required Iterable<HeatmapRasterTile> mountedTiles,
    required bool isLoading,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _snapshot = HeatmapRasterViewportSnapshot(
      generation: generation,
      requestedViewport: requestedViewport,
      mountedViewport: mountedViewport,
      requestedTileKeys: requestedTileKeys,
      mountedTiles: mountedTiles,
      semanticDescriptor: semanticDescriptor,
      isLoading: isLoading,
      diagnostics: _diagnostics,
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
  }

  void _refreshDiagnostics() {
    final current = _snapshot;
    _snapshot = HeatmapRasterViewportSnapshot(
      generation: current.generation,
      requestedViewport: current.requestedViewport,
      mountedViewport: current.mountedViewport,
      requestedTileKeys: current.requestedTileKeys,
      mountedTiles: current.mountedTiles,
      semanticDescriptor: semanticDescriptor,
      isLoading: current.isLoading,
      diagnostics: _diagnostics,
      error: current.error,
      stackTrace: current.stackTrace,
    );
    notifyListeners();
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('HeatmapRasterViewportController has been disposed');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final tile in _cache.values) {
      _disposeResource(tile.resource);
    }
    _cache.clear();
    super.dispose();
  }
}
