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
    required this.lastMutationRevision,
    required this.mutationBatchesAccepted,
    required this.staleMutationBatchesIgnored,
    required this.cellMutationsApplied,
    required this.mutationPublications,
  });

  final int requestGeneration;
  final int cacheHits;
  final int cacheMisses;
  final int inFlightJoins;
  final int loadsStarted;
  final int stalePublicationsRejected;
  final int lastMutationRevision;
  final int mutationBatchesAccepted;
  final int staleMutationBatchesIgnored;
  final int cellMutationsApplied;
  final int mutationPublications;
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
      lastMutationRevision: -1,
      mutationBatchesAccepted: 0,
      staleMutationBatchesIgnored: 0,
      cellMutationsApplied: 0,
      mutationPublications: 0,
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
    this.mutationPublishDuration = const Duration(milliseconds: 16),
    this.maxMutationsPerBatch = 4096,
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
    if (mutationPublishDuration.isNegative) {
      throw ArgumentError.value(
        mutationPublishDuration,
        'mutationPublishDuration',
        'must not be negative',
      );
    }
    if (maxMutationsPerBatch <= 0) {
      throw ArgumentError.value(
        maxMutationsPerBatch,
        'maxMutationsPerBatch',
        'must be positive',
      );
    }
  }

  final HeatmapTileSource source;
  final int overscanColumns;
  final int overscanRows;
  final int maxCachedTiles;
  final int maxTilesPerViewport;
  final Duration debounceDuration;
  final Duration mutationPublishDuration;
  final int maxMutationsPerBatch;

  final LinkedHashMap<HeatmapTileKey, HeatmapTile> _cache =
      LinkedHashMap<HeatmapTileKey, HeatmapTile>();
  final Map<HeatmapTileKey, Future<HeatmapTile>> _inFlight = {};
  final Map<HeatmapTileKey, int> _tileEpochs = {};
  final Map<HeatmapTileKey, Map<_HeatmapCellAddress, _HeatmapCellPatch>>
  _inFlightPatches = {};
  final Map<_HeatmapCellAddress, _HeatmapCellPatch> _pendingSnapshotPatches =
      {};
  final Set<HeatmapTileKey> _pendingVisibleInvalidations = {};

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
  int _lastMutationRevision = -1;
  int _mutationBatchesAccepted = 0;
  int _staleMutationBatchesIgnored = 0;
  int _cellMutationsApplied = 0;
  int _mutationPublications = 0;
  Timer? _debounceTimer;
  Timer? _mutationPublishTimer;
  HeatmapViewportRequest? _scheduledViewport;
  bool _disposed = false;

  /// Applies one authoritative host mutation batch.
  ///
  /// The host must update [source] before calling this method. Returns `false`
  /// when [batch] is a repeated or older revision.
  bool applyMutationBatch(HeatmapMutationBatch batch) {
    _ensureActive();
    if (batch.revision <= _lastMutationRevision) {
      _staleMutationBatchesIgnored++;
      return false;
    }
    if (batch.mutations.length > maxMutationsPerBatch) {
      throw ArgumentError.value(
        batch.mutations.length,
        'batch.mutations',
        'must not exceed $maxMutationsPerBatch operations',
      );
    }

    final resolved = <_ResolvedHeatmapMutation>[];
    for (final mutation in batch.mutations) {
      resolved.add(_resolveMutation(mutation));
    }

    final incomingAddresses = resolved
        .where((entry) => entry.patch != null)
        .map((entry) => entry.patch!.address)
        .toSet();
    final pendingAddressCount = {
      ..._pendingSnapshotPatches.keys,
      ...incomingAddresses,
    }.length;
    if (pendingAddressCount > maxMutationsPerBatch &&
        _pendingSnapshotPatches.isNotEmpty) {
      _flushPendingMutations();
    }

    _lastMutationRevision = batch.revision;
    _mutationBatchesAccepted++;
    final patchesByTile = <HeatmapTileKey, List<_HeatmapCellPatch>>{};
    for (final entry in resolved) {
      final patch = entry.patch;
      if (patch != null) {
        (patchesByTile[entry.tileKey] ??= []).add(patch);
        _pendingSnapshotPatches[patch.address] = patch;
        _cellMutationsApplied++;
      } else {
        _cache.remove(entry.tileKey);
        _tileEpochs.update(
          entry.tileKey,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        if (_snapshot.requestedTiles.contains(entry.tileKey)) {
          _pendingVisibleInvalidations.add(entry.tileKey);
        }
      }
    }
    for (final entry in patchesByTile.entries) {
      _applyPatchesToCachedTile(entry.key, entry.value);
      if (_inFlight.containsKey(entry.key)) {
        final inFlight = _inFlightPatches[entry.key] ??= {};
        for (final patch in entry.value) {
          inFlight[patch.address] = patch;
        }
      }
    }
    _scheduleMutationPublication();
    return true;
  }

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

  _ResolvedHeatmapMutation _resolveMutation(HeatmapMutation mutation) {
    switch (mutation) {
      case HeatmapCellUpsert(:final column, :final row, :final cell):
        final key = source.domain.tileKeyForCell(
          column,
          row,
          tileColumnCount: source.tileColumnCount,
          tileRowCount: source.tileRowCount,
        );
        final expectedX = source.domain.xForColumn(column);
        final expectedY = source.domain.yForRow(row);
        if ((cell.x - expectedX).abs() > 0.000001 ||
            (cell.y - expectedY).abs() > 0.000001) {
          throw ArgumentError.value(
            cell,
            'mutation.cell',
            'must represent matrix cell ($column, $row)',
          );
        }
        return _ResolvedHeatmapMutation(
          tileKey: key,
          patch: _HeatmapCellPatch(
            address: _HeatmapCellAddress(x: expectedX, y: expectedY),
            cell: cell,
          ),
        );
      case HeatmapCellRemoval(:final column, :final row):
        final key = source.domain.tileKeyForCell(
          column,
          row,
          tileColumnCount: source.tileColumnCount,
          tileRowCount: source.tileRowCount,
        );
        return _ResolvedHeatmapMutation(
          tileKey: key,
          patch: _HeatmapCellPatch(
            address: _HeatmapCellAddress(
              x: source.domain.xForColumn(column),
              y: source.domain.yForRow(row),
            ),
          ),
        );
      case HeatmapTileInvalidation(:final key):
        source.domain.tileRequestFor(
          key,
          tileColumnCount: source.tileColumnCount,
          tileRowCount: source.tileRowCount,
        );
        return _ResolvedHeatmapMutation(tileKey: key);
    }
  }

  void _applyPatchesToCachedTile(
    HeatmapTileKey key,
    Iterable<_HeatmapCellPatch> patches,
  ) {
    final cached = _cache.remove(key);
    if (cached == null) return;
    _cache[key] = _patchTile(cached, patches);
  }

  void _scheduleMutationPublication() {
    if (_mutationPublishTimer != null) return;
    if (mutationPublishDuration == Duration.zero) {
      _flushPendingMutations();
      return;
    }
    _mutationPublishTimer = Timer(
      mutationPublishDuration,
      _flushPendingMutations,
    );
  }

  void _flushPendingMutations() {
    _mutationPublishTimer?.cancel();
    _mutationPublishTimer = null;
    if (_disposed) return;
    final patches = List<_HeatmapCellPatch>.of(_pendingSnapshotPatches.values);
    _pendingSnapshotPatches.clear();
    final shouldReload = _pendingVisibleInvalidations.isNotEmpty;
    _pendingVisibleInvalidations.clear();

    var cells = _snapshot.cells;
    if (patches.isNotEmpty && _snapshot.requestedTiles.isNotEmpty) {
      final visibleKeys = _snapshot.requestedTiles.toSet();
      final visiblePatches = patches.where((patch) {
        final column =
            ((patch.address.x - source.domain.xOrigin) /
                    source.domain.cellWidth)
                .round();
        final row =
            ((patch.address.y - source.domain.yOrigin) /
                    source.domain.cellHeight)
                .round();
        return visibleKeys.contains(
          source.domain.tileKeyForCell(
            column,
            row,
            tileColumnCount: source.tileColumnCount,
            tileRowCount: source.tileRowCount,
          ),
        );
      });
      cells = _patchCells(cells, visiblePatches);
    }
    _mutationPublications++;
    _snapshot = HeatmapViewportSnapshot(
      generation: _snapshot.generation,
      viewport: _snapshot.viewport,
      requestedTiles: _snapshot.requestedTiles,
      cells: cells,
      isLoading: _snapshot.isLoading,
      cacheTileCount: _cache.length,
      diagnostics: _diagnostics,
      error: _snapshot.error,
      stackTrace: _snapshot.stackTrace,
    );
    notifyListeners();

    final viewport = _snapshot.viewport;
    if (shouldReload && viewport != null) {
      unawaited(loadViewport(viewport));
    }
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
    late final Future<HeatmapTile> future;
    future = _loadAndCache(request).whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  Future<HeatmapTile> _loadAndCache(HeatmapTileRequest request) async {
    late HeatmapTile tile;
    while (true) {
      final epoch = _tileEpochs[request.key] ?? 0;
      _loadsStarted++;
      tile = await source.loadTile(request);
      _validateTile(tile, request);
      if (epoch == (_tileEpochs[request.key] ?? 0)) break;
    }
    final patches = _inFlightPatches.remove(request.key)?.values;
    if (patches != null && patches.isNotEmpty) {
      tile = _patchTile(tile, patches);
    }
    _cache.remove(tile.key);
    _cache[tile.key] = tile;
    while (_cache.length > maxCachedTiles) {
      _cache.remove(_cache.keys.first);
    }
    return tile;
  }

  HeatmapTile _patchTile(
    HeatmapTile tile,
    Iterable<_HeatmapCellPatch> patches,
  ) => HeatmapTile(key: tile.key, cells: _patchCells(tile.cells, patches));

  List<HeatmapDataPoint> _patchCells(
    Iterable<HeatmapDataPoint> cells,
    Iterable<_HeatmapCellPatch> patches,
  ) {
    final byAddress = <_HeatmapCellAddress, HeatmapDataPoint>{
      for (final cell in cells) _HeatmapCellAddress(x: cell.x, y: cell.y): cell,
    };
    for (final patch in patches) {
      final cell = patch.cell;
      if (cell == null) {
        byAddress.remove(patch.address);
      } else {
        byAddress[patch.address] = cell;
      }
    }
    return _sortCells(byAddress.values);
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
    return _sortCells(cells);
  }

  List<HeatmapDataPoint> _sortCells(Iterable<HeatmapDataPoint> sourceCells) {
    final cells = sourceCells.toList()
      ..sort((left, right) {
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
    lastMutationRevision: _lastMutationRevision,
    mutationBatchesAccepted: _mutationBatchesAccepted,
    staleMutationBatchesIgnored: _staleMutationBatchesIgnored,
    cellMutationsApplied: _cellMutationsApplied,
    mutationPublications: _mutationPublications,
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
    _mutationPublishTimer?.cancel();
    _scheduledViewport = null;
    _pendingSnapshotPatches.clear();
    _pendingVisibleInvalidations.clear();
    _inFlightPatches.clear();
    super.dispose();
  }
}

final class _HeatmapCellAddress {
  const _HeatmapCellAddress({required this.x, required this.y});

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is _HeatmapCellAddress && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class _HeatmapCellPatch {
  const _HeatmapCellPatch({required this.address, this.cell});

  final _HeatmapCellAddress address;
  final HeatmapDataPoint? cell;
}

final class _ResolvedHeatmapMutation {
  const _ResolvedHeatmapMutation({required this.tileKey, this.patch});

  final HeatmapTileKey tileKey;
  final _HeatmapCellPatch? patch;
}
