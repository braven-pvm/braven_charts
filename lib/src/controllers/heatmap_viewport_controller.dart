// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/heatmap_chart_series.dart';
import '../models/heatmap_data_point.dart';
import '../models/heatmap_viewport_source.dart';

/// Immutable host diagnostics for a viewport-backed Heatmap source.
final class HeatmapViewportDiagnostics {
  const HeatmapViewportDiagnostics({
    required this.requestGeneration,
    required this.cacheHits,
    required this.cacheMisses,
    required this.inFlightJoins,
    required this.loadsStarted,
    required this.stalePublicationsRejected,
  });

  final int requestGeneration;
  final int cacheHits;
  final int cacheMisses;
  final int inFlightJoins;
  final int loadsStarted;
  final int stalePublicationsRejected;
}

/// One immutable resident Heatmap snapshot published by a tile controller.
final class HeatmapViewportSnapshot {
  HeatmapViewportSnapshot({
    required this.generation,
    required this.viewport,
    required List<HeatmapTileKey> requestedTiles,
    required List<HeatmapDataPoint> cells,
    required this.isLoading,
    required this.cacheTileCount,
    required this.diagnostics,
    this.error,
    this.stackTrace,
  }) : requestedTiles = List<HeatmapTileKey>.unmodifiable(requestedTiles),
       cells = List<HeatmapDataPoint>.unmodifiable(cells);

  factory HeatmapViewportSnapshot.empty() => HeatmapViewportSnapshot(
    generation: 0,
    viewport: null,
    requestedTiles: const [],
    cells: const [],
    isLoading: false,
    cacheTileCount: 0,
    diagnostics: const HeatmapViewportDiagnostics(
      requestGeneration: 0,
      cacheHits: 0,
      cacheMisses: 0,
      inFlightJoins: 0,
      loadsStarted: 0,
      stalePublicationsRejected: 0,
    ),
  );

  final int generation;
  final HeatmapViewportRequest? viewport;
  final List<HeatmapTileKey> requestedTiles;
  final List<HeatmapDataPoint> cells;
  final bool isLoading;
  final int cacheTileCount;
  final HeatmapViewportDiagnostics diagnostics;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasError => error != null;

  /// Replaces [template]'s points with this current resident snapshot.
  HeatmapChartSeries materializeSeries(HeatmapChartSeries template) =>
      template.copyWith(points: cells);
}

/// Loads and caches regular Heatmap tiles outside the rendering pipeline.
///
/// The controller retains the last complete snapshot while a newer viewport
/// loads. A superseded request may warm the bounded cache but can never publish
/// over a newer generation.
final class HeatmapViewportController extends ChangeNotifier {
  HeatmapViewportController({
    required this.source,
    this.overscanColumns = 1,
    this.overscanRows = 1,
    this.maxCachedTiles = 24,
    this.maxTilesPerViewport = 64,
    this.debounceDuration = const Duration(milliseconds: 40),
  }) {
    if (source.tileColumnCount <= 0 || source.tileRowCount <= 0) {
      throw ArgumentError('Heatmap source tile dimensions must be positive');
    }
    if (overscanColumns < 0 || overscanRows < 0) {
      throw ArgumentError('Heatmap overscan counts must be non-negative');
    }
    if (maxCachedTiles <= 0) {
      throw ArgumentError.value(
        maxCachedTiles,
        'maxCachedTiles',
        'must be positive',
      );
    }
    if (maxTilesPerViewport <= 0) {
      throw ArgumentError.value(
        maxTilesPerViewport,
        'maxTilesPerViewport',
        'must be positive',
      );
    }
    if (debounceDuration.isNegative) {
      throw ArgumentError.value(
        debounceDuration,
        'debounceDuration',
        'must not be negative',
      );
    }
  }

  final HeatmapTileSource source;
  final int overscanColumns;
  final int overscanRows;
  final int maxCachedTiles;
  final int maxTilesPerViewport;
  final Duration debounceDuration;

  final LinkedHashMap<HeatmapTileKey, HeatmapTile> _cache =
      LinkedHashMap<HeatmapTileKey, HeatmapTile>();
  final Map<HeatmapTileKey, Future<HeatmapTile>> _inFlight = {};

  HeatmapViewportSnapshot _snapshot = HeatmapViewportSnapshot.empty();
  HeatmapViewportSnapshot get snapshot => _snapshot;

  /// Current cumulative host diagnostics, including superseded requests that
  /// intentionally did not publish a new [snapshot].
  HeatmapViewportDiagnostics get diagnostics => _diagnostics;

  int _generation = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _inFlightJoins = 0;
  int _loadsStarted = 0;
  int _stalePublicationsRejected = 0;
  Timer? _debounceTimer;
  HeatmapViewportRequest? _scheduledViewport;
  bool _disposed = false;

  /// Coalesces interaction-heavy viewport pulses to the latest request.
  void requestViewport(HeatmapViewportRequest viewport) {
    _ensureActive();
    viewport.validate();
    if (_scheduledViewport == viewport) return;
    if (_snapshot.viewport == viewport &&
        !_snapshot.isLoading &&
        !_snapshot.hasError) {
      return;
    }
    _scheduledViewport = viewport;
    _debounceTimer?.cancel();
    if (debounceDuration == Duration.zero) {
      unawaited(loadViewport(viewport));
      return;
    }
    _debounceTimer = Timer(debounceDuration, () {
      final scheduled = _scheduledViewport;
      _scheduledViewport = null;
      if (scheduled != null && !_disposed) {
        unawaited(loadViewport(scheduled));
      }
    });
  }

  /// Immediately resolves [viewport] and publishes it if still current.
  Future<void> loadViewport(HeatmapViewportRequest viewport) async {
    _ensureActive();
    viewport.validate();
    final generation = ++_generation;
    late final List<HeatmapTileKey> tileKeys;
    try {
      tileKeys = source.domain.tileKeysFor(
        viewport,
        tileColumnCount: source.tileColumnCount,
        tileRowCount: source.tileRowCount,
        overscanColumns: overscanColumns,
        overscanRows: overscanRows,
        maximumTileCount: maxTilesPerViewport,
      );
    } catch (error, stackTrace) {
      _snapshot = HeatmapViewportSnapshot(
        generation: generation,
        viewport: viewport,
        requestedTiles: const [],
        cells: _snapshot.cells,
        isLoading: false,
        cacheTileCount: _cache.length,
        diagnostics: _diagnostics,
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
      return;
    }
    _snapshot = HeatmapViewportSnapshot(
      generation: generation,
      viewport: viewport,
      requestedTiles: tileKeys,
      cells: _snapshot.cells,
      isLoading: true,
      cacheTileCount: _cache.length,
      diagnostics: _diagnostics,
    );
    notifyListeners();

    try {
      final tiles = await Future.wait([
        for (final key in tileKeys) _resolveTile(key),
      ]);
      if (_disposed) return;
      if (generation != _generation) {
        _stalePublicationsRejected++;
        return;
      }
      final cells = _materializeCells(tiles);
      _snapshot = HeatmapViewportSnapshot(
        generation: generation,
        viewport: viewport,
        requestedTiles: tileKeys,
        cells: cells,
        isLoading: false,
        cacheTileCount: _cache.length,
        diagnostics: _diagnostics,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      if (_disposed || generation != _generation) return;
      _snapshot = HeatmapViewportSnapshot(
        generation: generation,
        viewport: viewport,
        requestedTiles: tileKeys,
        cells: _snapshot.cells,
        isLoading: false,
        cacheTileCount: _cache.length,
        diagnostics: _diagnostics,
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  /// Removes all reusable tiles without changing the visible snapshot.
  void clearCache() {
    _ensureActive();
    _cache.clear();
    _snapshot = HeatmapViewportSnapshot(
      generation: _snapshot.generation,
      viewport: _snapshot.viewport,
      requestedTiles: _snapshot.requestedTiles,
      cells: _snapshot.cells,
      isLoading: _snapshot.isLoading,
      cacheTileCount: 0,
      diagnostics: _diagnostics,
      error: _snapshot.error,
      stackTrace: _snapshot.stackTrace,
    );
    notifyListeners();
  }

  Future<HeatmapTile> _resolveTile(HeatmapTileKey key) {
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      _cacheHits++;
      // Future.wait installs each completion handler before advancing its
      // internal result index. A SynchronousFuture can complete inside that
      // installation and leave an all-cache request with an empty result.
      // Keep cache hits asynchronous so multi-tile snapshots retain every
      // resident tile deterministically.
      return Future<HeatmapTile>.value(cached);
    }
    _cacheMisses++;
    final active = _inFlight[key];
    if (active != null) {
      _inFlightJoins++;
      return active;
    }
    final request = source.domain.tileRequestFor(
      key,
      tileColumnCount: source.tileColumnCount,
      tileRowCount: source.tileRowCount,
    );
    _loadsStarted++;
    late final Future<HeatmapTile> future;
    future = _loadAndCache(request).whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  Future<HeatmapTile> _loadAndCache(HeatmapTileRequest request) async {
    final tile = await source.loadTile(request);
    _validateTile(tile, request);
    _cache.remove(tile.key);
    _cache[tile.key] = tile;
    while (_cache.length > maxCachedTiles) {
      _cache.remove(_cache.keys.first);
    }
    return tile;
  }

  void _validateTile(HeatmapTile tile, HeatmapTileRequest request) {
    if (tile.key != request.key) {
      throw StateError(
        'Heatmap source returned ${tile.key} for requested ${request.key}',
      );
    }
    final identities = <HeatmapCellIdentity>{};
    for (final cell in tile.cells) {
      if (!source.domain.containsPointInTile(cell, request)) {
        throw StateError(
          'Heatmap source returned ${cell.identity} outside ${request.key}',
        );
      }
      if (!identities.add(cell.identity)) {
        throw StateError(
          'Heatmap source returned duplicate cell ${cell.identity}',
        );
      }
    }
  }

  List<HeatmapDataPoint> _materializeCells(List<HeatmapTile> tiles) {
    final identities = <HeatmapCellIdentity>{};
    final cells = <HeatmapDataPoint>[];
    for (final tile in tiles) {
      for (final cell in tile.cells) {
        if (!identities.add(cell.identity)) {
          throw StateError(
            'Heatmap tiles returned duplicate cell ${cell.identity}',
          );
        }
        cells.add(cell);
      }
    }
    cells.sort((left, right) {
      final yOrder = left.y.compareTo(right.y);
      if (yOrder != 0) return yOrder;
      final xOrder = left.x.compareTo(right.x);
      if (xOrder != 0) return xOrder;
      return (left.pointKey ?? '').compareTo(right.pointKey ?? '');
    });
    return List<HeatmapDataPoint>.unmodifiable(cells);
  }

  HeatmapViewportDiagnostics get _diagnostics => HeatmapViewportDiagnostics(
    requestGeneration: _generation,
    cacheHits: _cacheHits,
    cacheMisses: _cacheMisses,
    inFlightJoins: _inFlightJoins,
    loadsStarted: _loadsStarted,
    stalePublicationsRejected: _stalePublicationsRejected,
  );

  void _ensureActive() {
    if (_disposed) {
      throw StateError('HeatmapViewportController has been disposed');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _scheduledViewport = null;
    super.dispose();
  }
}
