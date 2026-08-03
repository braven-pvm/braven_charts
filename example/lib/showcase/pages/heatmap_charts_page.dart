// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _HeatmapPreset {
  activity,
  selection,
  irregular,
  temperature,
  threshold,
  calendar,
  contributions,
  correlation,
  histogram,
  density,
  contours,
  clustered,
  colourAxes,
  smallMultiples,
  dense,
  viewportSource,
  rasterTiles,
}

enum _HeatmapPalette { ocean, forest, sunset, viridis, graphite }

enum _HeatmapMotion { fade, scale, none }

enum _ContourDetail { coarse, detailed }

enum _ContourGeometry { exact, smooth }

enum _ClusterFocus { full, primary, secondary }

enum _RasterReviewState { idle, loading, ready, retainedFallback, failed }

_HeatmapPreset? _heatmapPresetFromSlug(String? value) {
  final normalized = value?.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );
  if (normalized == null || normalized.isEmpty) return null;

  for (final preset in _HeatmapPreset.values) {
    if (preset.name.toLowerCase() == normalized) return preset;
  }

  return switch (normalized) {
    'activitymatrix' => _HeatmapPreset.activity,
    'matrixselection' => _HeatmapPreset.selection,
    'irregularcells' => _HeatmapPreset.irregular,
    'servicehealth' => _HeatmapPreset.threshold,
    'calendarmonth' => _HeatmapPreset.calendar,
    'contributioncalendar' => _HeatmapPreset.contributions,
    '2dhistogram' => _HeatmapPreset.histogram,
    'densityraster' => _HeatmapPreset.density,
    'densitycontours' => _HeatmapPreset.contours,
    'clusteredmatrix' => _HeatmapPreset.clustered,
    'colouraxes' || 'coloraxes' => _HeatmapPreset.colourAxes,
    'smallmultiples' => _HeatmapPreset.smallMultiples,
    'denseviewport' => _HeatmapPreset.dense,
    'massivematrix' => _HeatmapPreset.viewportSource,
    'rastertiles' => _HeatmapPreset.rasterTiles,
    _ => null,
  };
}

class HeatmapChartsPage extends StatefulWidget {
  const HeatmapChartsPage({super.key, this.initialPreset});

  /// Optional direct-route/test preset. Hosted links otherwise read `preset`
  /// from [Uri.base] and accept both enum names and the labels' URL slugs.
  final String? initialPreset;

  @override
  State<HeatmapChartsPage> createState() => _HeatmapChartsPageState();
}

class _HeatmapChartsPageState extends State<HeatmapChartsPage> {
  static const EdgeInsets _clusterPlotInsets = EdgeInsets.all(10);
  static const double _clusterRowLabelWidth = 84;
  static const double _clusterColumnLabelHeight = 28;
  static const double _clusterXAxisTitleHeight = 22;

  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();

  _ProceduralMassiveHeatmapSource? _viewportSource;
  HeatmapViewportController? _viewportController;
  ChartInteractionGroupController? _viewportGroupController;
  _ProceduralRasterHeatmapSource? _rasterSource;
  HeatmapRasterViewportController? _rasterController;
  ChartInteractionGroupController? _rasterGroupController;
  Timer? _rasterViewportTimer;
  Timer? _viewportMutationTimer;
  bool _streamViewportMutations = false;
  int _viewportMutationRevision = 0;
  int _viewportMutationTick = 0;

  _HeatmapPreset _preset = _HeatmapPreset.activity;
  HeatmapSelectionExpansion _heatmapSelectionExpansion =
      HeatmapSelectionExpansion.cell;
  _HeatmapPalette _palette = _HeatmapPalette.ocean;
  bool _showValues = true;
  bool _showColorLegend = true;
  bool _useSharedDomain = true;
  double _sharedDomainPaddingFraction = 0.05;
  HeatmapValueFilter? _smallMultipleValueFilter;
  HeatmapValueFilter? _latencyValueFilter;
  HeatmapValueFilter? _errorRateValueFilter;
  bool _showLatencyColorAxis = true;
  bool _showErrorRateColorAxis = true;
  HeatmapValueFilterMode _smallMultipleFilterMode = HeatmapValueFilterMode.dim;
  double _smallMultipleExcludedOpacity = 0.14;
  bool _reverseScale = false;
  bool _clampScale = true;
  double _gapFraction = 0.06;
  double _cornerRadius = 3;
  double _domainPadding = 0;
  double _midpointOffset = 0;
  Color _missingColor = const Color(0xFFE2E8F0);
  bool _styleEmptyValues = true;
  Color _emptyValueColor = const Color(0xFFE5E7EB);
  Color _emptyValueBorderColor = const Color(0xFFD1D5DB);
  double _emptyValueBorderWidth = 0.8;
  bool _showEmptyValueLabels = false;
  bool _showEmptyValueLegend = true;
  _HeatmapMotion _motion = _HeatmapMotion.scale;
  HeatmapEntranceOrder _entranceOrder = HeatmapEntranceOrder.row;
  bool _animateUpdates = true;
  HeatmapDensityKernel _densityKernel = HeatmapDensityKernel.gaussian;
  double _densityBandwidthX = 0.72;
  double _densityBandwidthY = 8;
  _ContourDetail _contourDetail = _ContourDetail.coarse;
  _ContourGeometry _contourGeometry = _ContourGeometry.exact;
  bool _showContours = true;
  double _contourStrokeWidth = 2;
  double _contourTension = 0.25;
  HeatmapClusterAxisMode _clusterAxisMode = HeatmapClusterAxisMode.both;
  HeatmapClusterDistance _clusterDistance = HeatmapClusterDistance.correlation;
  HeatmapClusterLinkage _clusterLinkage = HeatmapClusterLinkage.average;
  HeatmapClusterMissingValueMode _clusterMissingValueMode =
      HeatmapClusterMissingValueMode.pairwiseIgnore;
  bool _applyClusterOrder = true;
  _ClusterFocus _clusterFocus = _ClusterFocus.full;
  bool _showRowDendrogram = true;
  bool _showColumnDendrogram = true;
  bool _enableDendrogramInteraction = true;
  HeatmapDendrogramInteractionState _rowDendrogramInteraction =
      const HeatmapDendrogramInteractionState();
  HeatmapDendrogramInteractionState _columnDendrogramInteraction =
      const HeatmapDendrogramInteractionState();
  HeatmapHierarchyCollapseState _rowHierarchyCollapse =
      const HeatmapHierarchyCollapseState.empty();
  HeatmapHierarchyCollapseState _columnHierarchyCollapse =
      const HeatmapHierarchyCollapseState.empty();
  HeatmapHierarchyReducer _hierarchyReducer = HeatmapHierarchyReducer.mean;
  HeatmapDendrogramDistanceScale _dendrogramDistanceScale =
      HeatmapDendrogramDistanceScale.structural;
  double _dendrogramExtent = 88;
  double _dendrogramStrokeWidth = 1.5;
  Color _dendrogramBranchColor = const Color(0xFF5B5AA6);
  StrokeCap _dendrogramBranchCap = StrokeCap.round;
  StrokeJoin _dendrogramBranchJoin = StrokeJoin.round;
  Color _dendrogramBaselineColor = const Color(0xFFB8B7D9);
  double _dendrogramBaselineWidth = 1;
  bool _showDendrogramBaseline = true;
  Color _dendrogramTickColor = const Color(0xFF7473A8);
  double _dendrogramTickWidth = 1;
  double _dendrogramTickLength = 5;
  bool _showDendrogramTicks = true;
  double _dendrogramElbowRadius = 6;
  bool _showDendrogramLeafMarkers = true;
  Color _dendrogramLeafMarkerColor = const Color(0xFF3B82F6);
  double _dendrogramLeafMarkerRadius = 3;
  HeatmapDendrogramMarkerShape _dendrogramLeafMarkerShape =
      HeatmapDendrogramMarkerShape.circle;
  HeatmapDendrogramMarkerFill _dendrogramLeafMarkerFill =
      HeatmapDendrogramMarkerFill.hollow;
  Color _dendrogramLeafMarkerBorderColor = const Color(0xFF3B82F6);
  double _dendrogramLeafMarkerBorderWidth = 1.5;
  bool _showDendrogramMergeMarkers = true;
  Color _dendrogramMergeMarkerColor = const Color(0xFFF97316);
  double _dendrogramMergeMarkerRadius = 3.5;
  HeatmapDendrogramMarkerShape _dendrogramMergeMarkerShape =
      HeatmapDendrogramMarkerShape.diamond;
  HeatmapDendrogramMarkerFill _dendrogramMergeMarkerFill =
      HeatmapDendrogramMarkerFill.solid;
  Color _dendrogramMergeMarkerBorderColor = const Color(0xFF9A3412);
  double _dendrogramMergeMarkerBorderWidth = 1;
  bool _showDendrogramLeafLabels = false;
  bool _showDendrogramMergeLabels = true;
  Color _dendrogramLabelColor = const Color(0xFF2E2D4F);
  Color _dendrogramLabelBackgroundColor = const Color(0xFFF4F3FF);
  double _dendrogramLabelFontSize = 9;
  HeatmapDendrogramLabelDensity _dendrogramLabelDensity =
      HeatmapDendrogramLabelDensity.balanced;
  HeatmapDendrogramLabelPlacement _dendrogramLabelPlacement =
      HeatmapDendrogramLabelPlacement.before;
  double _dendrogramMaxLabelCharacters = 12;
  double _dendrogramMergeLabelDecimals = 2;
  bool _automaticDendrogramLevelOfDetail = true;
  double _dendrogramMinimumBranchLength = 0.75;
  double _dendrogramMinimumLeafGuideSpacing = 3;
  double _dendrogramMinimumLeafMarkerSpacing = 8;
  double _dendrogramMinimumMergeMarkerSpacing = 6;
  double _dendrogramMinimumLabelSpacing = 24;
  int _dataRevision = 0;

  static final HeatmapHistogramAxis _histogramXAxis = HeatmapHistogramAxis(
    boundaries: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    labels: const [
      '1–2',
      '2–3',
      '3–4',
      '4–5',
      '5–6',
      '6–7',
      '7–8',
      '8–9',
      '9–10',
    ],
  );
  static final HeatmapHistogramAxis _histogramYAxis = HeatmapHistogramAxis(
    boundaries: const [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
    labels: const [
      '0–10',
      '10–20',
      '20–30',
      '30–40',
      '40–50',
      '50–60',
      '60–70',
      '70–80',
      '80–90',
      '90–100',
    ],
  );
  static final HeatmapHistogramData _histogramData = HeatmapHistogramData(
    xAxis: _histogramXAxis,
    yAxis: _histogramYAxis,
    observations: [
      for (var index = 0; index < 800; index++)
        () {
          final x = 1.05 + ((index * 37) % 890) / 100;
          final noise = (((index * 53) % 220) - 110) / 5;
          final outlierShift = index % 29 == 0
              ? (index.isEven ? 24.0 : -24.0)
              : 0.0;
          final y = (x * 10.4 + noise + outlierShift)
              .clamp(0.0, 100.0)
              .toDouble();
          return HeatmapHistogramObservation(
            x: x,
            y: y,
            pointKey: 'review-$index',
            metadata: {'source': 'review', 'row': index},
          );
        }(),
    ],
  );
  static final HeatmapDensityAxis _densityXAxis = HeatmapDensityAxis(
    minimum: 0,
    maximum: 10,
    cellCount: 16,
    labels: const [
      '0.3',
      '0.9',
      '1.6',
      '2.2',
      '2.8',
      '3.4',
      '4.1',
      '4.7',
      '5.3',
      '5.9',
      '6.6',
      '7.2',
      '7.8',
      '8.4',
      '9.1',
      '9.7',
    ],
  );
  static final HeatmapDensityAxis _densityYAxis = HeatmapDensityAxis(
    minimum: 0,
    maximum: 100,
    cellCount: 14,
    labels: const [
      '4',
      '11',
      '18',
      '25',
      '32',
      '39',
      '46',
      '54',
      '61',
      '68',
      '75',
      '82',
      '89',
      '96',
    ],
  );
  static final List<HeatmapDensityObservation> _densityObservations =
      List.unmodifiable([
        for (var index = 0; index < 480; index++)
          () {
            final cluster = index % 3;
            final baseX = switch (cluster) {
              0 => 2.1,
              1 => 5.4,
              _ => 8.0,
            };
            final baseY = switch (cluster) {
              0 => 27.0,
              1 => 72.0,
              _ => 46.0,
            };
            final xNoise = (((index * 37) % 101) - 50) / 34;
            final yNoise = (((index * 53) % 103) - 51) / 2.15;
            final drift = ((index * 19) % 29 - 14) / 30;
            return HeatmapDensityObservation(
              x: (baseX + xNoise + drift).clamp(0.05, 9.95).toDouble(),
              y: (baseY + yNoise + drift * 8).clamp(0.5, 99.5).toDouble(),
              weight: 0.75 + (index % 7) * 0.08,
              pointKey: 'customer-$index',
              metadata: {'segment': cluster, 'sourceRow': index},
            );
          }(),
      ]);
  static const List<String> _clusterSourceRowLabels = [
    'Activation',
    'Errors',
    'Retention',
    'Latency',
    'Revenue',
    'Support load',
    'Conversion',
    'Engagement',
  ];
  static const List<String> _clusterSourceColumnLabels = [
    'Revenue',
    'Error rate',
    'Retention',
    'Conversion',
    'Latency',
    'Activation',
    'Support load',
    'Engagement',
  ];
  static const List<List<double?>> _clusterSourceValues = [
    [0.76, -0.68, 0.71, 0.91, -0.62, 1, null, 0.78],
    [-0.66, 1, -0.58, -0.61, 0.87, -0.68, 0.92, -0.55],
    [0.82, -0.52, 1, 0.73, -0.48, 0.71, -0.44, 0.92],
    [-0.58, 0.87, -0.48, -0.55, 1, -0.62, 0.83, -0.45],
    [1, -0.66, 0.82, 0.88, -0.58, 0.76, -0.57, 0.79],
    [-0.57, 0.92, -0.44, -0.52, 0.83, -0.54, 1, -0.4],
    [0.88, -0.61, 0.73, 1, -0.55, 0.91, -0.52, 0.76],
    [0.79, -0.55, 0.92, 0.76, -0.45, 0.78, -0.4, 1],
  ];

  @override
  void initState() {
    super.initState();
    final requestedPreset = _heatmapPresetFromSlug(
      widget.initialPreset ?? Uri.base.queryParameters['preset'],
    );
    if (requestedPreset != null) {
      _preset = requestedPreset;
      if (requestedPreset == _HeatmapPreset.contributions) {
        _palette = _HeatmapPalette.forest;
        _showValues = false;
      }
    }
    if (_preset == _HeatmapPreset.viewportSource) {
      _ensureViewportSource();
    } else if (_preset == _HeatmapPreset.rasterTiles) {
      _ensureRasterSource();
    }
  }

  @override
  void dispose() {
    _viewportMutationTimer?.cancel();
    _rasterViewportTimer?.cancel();
    _viewportController?.dispose();
    _viewportGroupController?.dispose();
    _rasterController?.dispose();
    _rasterGroupController?.dispose();
    _chartController.dispose();
    _workbenchController.dispose();
    super.dispose();
  }

  void _ensureViewportSource() {
    if (_viewportController != null) return;
    final source = _ProceduralMassiveHeatmapSource();
    final controller = HeatmapViewportController(
      source: source,
      overscanColumns: 32,
      overscanRows: 0,
      maxCachedTiles: 12,
      maxTilesPerViewport: 8,
      debounceDuration: const Duration(milliseconds: 45),
    );
    final groupController = ChartInteractionGroupController();
    _viewportSource = source;
    _viewportController = controller;
    _viewportGroupController = groupController;
    controller.addListener(_handleViewportSnapshotChanged);
    _resetMassiveViewport(loadImmediately: true);
  }

  void _ensureRasterSource() {
    if (_rasterController != null) return;
    final source = _ProceduralRasterHeatmapSource();
    final controller = HeatmapRasterViewportController(
      source: source,
      semanticDescriptor: HeatmapRasterSemanticDescriptor(
        seriesId: 'raster-spectrogram-resident',
        name: 'Visible spectrogram aggregates',
        unit: '%',
        metadata: const {
          'aggregation': 'sampled-mean',
          'semanticColumnsPerTile': 16,
          'semanticRowsPerTile': 8,
        },
        colorScale: source.semanticColorScale,
      ),
      maxCachedTiles: 48,
      maxDecodedBytes: 8 * 1024 * 1024,
      maxTilesPerViewport: 24,
    );
    final groupController = ChartInteractionGroupController();
    _rasterSource = source;
    _rasterController = controller;
    _rasterGroupController = groupController;
    controller.addListener(_handleRasterSnapshotChanged);
    final viewport = _initialRasterViewport(source);
    groupController.setViewport(
      ChartXViewport(min: viewport.minimumX, max: viewport.maximumX),
    );
    unawaited(controller.loadViewport(viewport));
  }

  HeatmapViewportRequest _initialRasterViewport(
    _ProceduralRasterHeatmapSource source,
  ) {
    final finalTileColumn =
        (source.domain.columnCount - 1) ~/ source.tileColumnCount;
    final firstTileColumn = math.max(0, finalTileColumn - 2);
    final firstColumn = firstTileColumn * source.tileColumnCount;
    return HeatmapViewportRequest(
      minimumX:
          source.domain.xForColumn(firstColumn) - source.domain.cellWidth / 2,
      maximumX: source.domain.fullBounds.maximumX,
      minimumY: source.domain.fullBounds.minimumY,
      maximumY: source.domain.fullBounds.maximumY,
    );
  }

  HeatmapViewportRequest _rasterReviewViewport(
    _ProceduralRasterHeatmapSource source, {
    required int tileWindowsBeforeLatest,
  }) {
    final finalTileColumn =
        (source.domain.columnCount - 1) ~/ source.tileColumnCount;
    final finalWindowStart = math.max(0, finalTileColumn - 2);
    final firstTileColumn = math.max(
      0,
      finalWindowStart - tileWindowsBeforeLatest * 3,
    );
    final firstColumn = firstTileColumn * source.tileColumnCount;
    final finalColumnExclusive = math.min(
      source.domain.columnCount,
      (firstTileColumn + 3) * source.tileColumnCount,
    );
    return HeatmapViewportRequest(
      minimumX:
          source.domain.xForColumn(firstColumn) - source.domain.cellWidth / 2,
      maximumX:
          source.domain.xForColumn(finalColumnExclusive - 1) +
          source.domain.cellWidth / 2,
      minimumY: source.domain.fullBounds.minimumY,
      maximumY: source.domain.fullBounds.maximumY,
    );
  }

  Future<void> _reviewRasterLoading() async {
    final source = _rasterSource;
    final controller = _rasterController;
    if (source == null || controller == null) return;
    source.delayNextBatch(const Duration(milliseconds: 650));
    final viewport = _rasterReviewViewport(source, tileWindowsBeforeLatest: 1);
    await _loadRasterViewportAndAdopt(viewport);
  }

  Future<void> _reviewRasterRetainedFailure() async {
    final source = _rasterSource;
    final controller = _rasterController;
    if (source == null || controller == null) return;
    source
      ..delayNextBatch(const Duration(milliseconds: 320))
      ..failNextLoad();
    final viewport = _rasterReviewViewport(source, tileWindowsBeforeLatest: 2);
    await _loadRasterViewportAndAdopt(viewport);
  }

  Future<void> _retryRasterViewport() async {
    final controller = _rasterController;
    final viewport = controller?.snapshot.requestedViewport;
    if (controller == null || viewport == null) return;
    await _loadRasterViewportAndAdopt(viewport);
  }

  Future<void> _returnRasterToLatest() async {
    final source = _rasterSource;
    if (source == null) return;
    final viewport = _initialRasterViewport(source);
    await _loadRasterViewportAndAdopt(viewport);
  }

  Future<void> _loadRasterViewportAndAdopt(
    HeatmapViewportRequest viewport,
  ) async {
    final controller = _rasterController;
    final groupController = _rasterGroupController;
    if (controller == null || groupController == null) return;
    await controller.loadViewport(viewport);
    if (!mounted) return;
    final snapshot = controller.snapshot;
    if (snapshot.error != null || snapshot.mountedViewport != viewport) return;
    groupController.setViewport(
      ChartXViewport(min: viewport.minimumX, max: viewport.maximumX),
    );
  }

  ChartBoundsDocument? get _rasterResetViewportBounds {
    final source = _rasterSource;
    if (source == null) return null;
    final viewport = _initialRasterViewport(source);
    return ChartBoundsDocument(
      xMin: viewport.minimumX,
      xMax: viewport.maximumX,
      yMin: viewport.minimumY,
      yMax: viewport.maximumY,
    );
  }

  HeatmapRasterViewportProviderDescriptor?
  get _rasterViewportProviderDescriptor {
    final source = _rasterSource;
    if (source == null) return null;
    return HeatmapRasterViewportProviderDescriptor(
      providerId: 'showcase.deep-signal-spectrogram.v1',
      layerId: 'deep-signal-spectrogram',
      semanticSeriesId: 'raster-spectrogram-resident',
      initialViewport: _initialRasterViewport(source),
      fallback: HeatmapRasterProviderFallback.cell,
      filterQuality: HeatmapRasterProviderFilterQuality.low,
      arguments: {
        'matrixColumns': JsonNumberValue(source.domain.columnCount),
        'matrixRows': JsonNumberValue(source.domain.rowCount),
        'tileColumns': JsonNumberValue(source.tileColumnCount),
        'tileRows': JsonNumberValue(source.tileRowCount),
        'semanticColumnsPerTile': JsonNumberValue(
          source.semanticColumnsPerTile,
        ),
        'semanticRowsPerTile': JsonNumberValue(source.semanticRowsPerTile),
      },
    );
  }

  void _handleRasterViewportChanged(Map<String, double> visibleBounds) {
    final controller = _rasterController;
    if (controller == null) return;
    final viewport = HeatmapViewportRequest.fromVisibleBounds(visibleBounds);
    final snapshot = controller.snapshot;
    if (!snapshot.isLoading && snapshot.mountedViewport == viewport) return;
    _rasterViewportTimer?.cancel();
    _rasterViewportTimer = Timer(
      const Duration(milliseconds: 55),
      () => unawaited(controller.loadViewport(viewport)),
    );
  }

  void _handleRasterSnapshotChanged() {
    if (!mounted || _preset != _HeatmapPreset.rasterTiles) return;
    setState(() {});
  }

  void _handleViewportSnapshotChanged() {
    if (!mounted || _preset != _HeatmapPreset.viewportSource) return;
    setState(() {});
  }

  void _resetMassiveViewport({bool loadImmediately = false}) {
    final source = _viewportSource;
    final controller = _viewportController;
    final groupController = _viewportGroupController;
    if (source == null || controller == null || groupController == null) return;
    final viewport = _initialMassiveViewport(source);
    groupController.setViewport(
      ChartXViewport(min: viewport.minimumX, max: viewport.maximumX),
    );
    if (loadImmediately) {
      unawaited(controller.loadViewport(viewport));
    } else {
      controller.requestViewport(viewport);
    }
  }

  HeatmapViewportRequest _initialMassiveViewport(
    _ProceduralMassiveHeatmapSource source,
  ) {
    final maximumX = source.domain.fullBounds.maximumX;
    return HeatmapViewportRequest(
      minimumX: maximumX - 300,
      maximumX: maximumX,
      minimumY: source.domain.fullBounds.minimumY,
      maximumY: source.domain.fullBounds.maximumY,
    );
  }

  HeatmapViewportProviderDescriptor? get _massiveViewportProviderDescriptor {
    final source = _viewportSource;
    if (source == null) return null;
    return HeatmapViewportProviderDescriptor(
      providerId: 'showcase.heatmap.procedural-matrix.v1',
      seriesId: 'heatmap-viewport-source',
      initialViewport: _initialMassiveViewport(source),
      arguments: {
        'model': const JsonStringValue('procedural-signal-v1'),
        'columnCount': JsonNumberValue(source.domain.columnCount),
        'rowCount': JsonNumberValue(source.domain.rowCount),
        'tileColumnCount': JsonNumberValue(source.tileColumnCount),
        'tileRowCount': JsonNumberValue(source.tileRowCount),
      },
    );
  }

  ChartBoundsDocument? get _massiveResetViewportBounds {
    final source = _viewportSource;
    if (source == null) return null;
    final viewport = _initialMassiveViewport(source);
    return ChartBoundsDocument(
      xMin: viewport.minimumX,
      xMax: viewport.maximumX,
      yMin: viewport.minimumY,
      yMax: viewport.maximumY,
    );
  }

  void _handleMassiveViewportChanged(Map<String, double> visibleBounds) {
    _viewportController?.requestViewport(
      HeatmapViewportRequest.fromVisibleBounds(visibleBounds),
    );
  }

  void _reloadMassiveViewport() {
    final controller = _viewportController;
    final viewport = controller?.snapshot.viewport;
    if (controller == null || viewport == null) return;
    controller.clearCache();
    unawaited(controller.loadViewport(viewport));
  }

  void _toggleViewportMutationStream() {
    if (_streamViewportMutations) {
      _stopViewportMutationStream();
      setState(() {});
      return;
    }
    setState(() => _streamViewportMutations = true);
    _viewportMutationTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _publishViewportMutationFrame(),
    );
    _publishViewportMutationFrame();
  }

  void _stopViewportMutationStream() {
    _viewportMutationTimer?.cancel();
    _viewportMutationTimer = null;
    _streamViewportMutations = false;
  }

  void _publishViewportMutationFrame() {
    final source = _viewportSource;
    final controller = _viewportController;
    final viewport = controller?.snapshot.viewport;
    if (!mounted ||
        !_streamViewportMutations ||
        source == null ||
        controller == null ||
        viewport == null) {
      return;
    }
    final minimumColumn = viewport.minimumX.ceil().clamp(
      0,
      source.domain.columnCount - 1,
    );
    final maximumColumn = viewport.maximumX.floor().clamp(
      minimumColumn,
      source.domain.columnCount - 1,
    );
    final visibleColumnCount = maximumColumn - minimumColumn + 1;
    final column = minimumColumn + _viewportMutationTick % visibleColumnCount;
    final mutations = <HeatmapMutation>[];
    for (var row = 0; row < source.domain.rowCount; row++) {
      final cell = source.liveCell(column, row, _viewportMutationTick);
      source.upsert(column, row, cell);
      mutations.add(HeatmapCellUpsert(column: column, row: row, cell: cell));
    }
    _viewportMutationTick++;
    _viewportMutationRevision++;
    controller.applyMutationBatch(
      HeatmapMutationBatch(
        revision: _viewportMutationRevision,
        mutations: mutations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Heatmap Charts',
      subtitle:
          'Encode an independent measured value across a native Cartesian matrix',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('heatmap-replay-entrance'),
          onPressed: _motion == _HeatmapMotion.none
              ? null
              : _chartController.replaySeriesEntrance,
          icon: const Icon(Icons.play_arrow_outlined, size: 18),
          label: const Text('Replay entrance'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('heatmap-animate-update'),
          onPressed: _animateUpdates
              ? () => setState(() => _dataRevision++)
              : null,
          icon: const Icon(Icons.autorenew, size: 18),
          label: const Text('Animate update'),
        ),
      ],
      chart: ListView(
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_preset == _HeatmapPreset.viewportSource) ...[
                    const SizedBox(height: 12),
                    _buildViewportSourceStatus(),
                  ],
                  if (_preset == _HeatmapPreset.rasterTiles) ...[
                    const SizedBox(height: 12),
                    _buildRasterSourceStatus(),
                  ],
                  if (_preset == _HeatmapPreset.selection) ...[
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _chartController,
                      builder: (context, _) {
                        final selectedCount =
                            _chartController.selectedPointRefs.length;
                        return Container(
                          key: const ValueKey('heatmap-selection-status'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.select_all_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedCount == 0
                                      ? 'Drag across cells, then move or resize the persistent brush.'
                                      : '$selectedCount cells selected · ${_selectionExpansionLabel(_heatmapSelectionExpansion)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 620,
                    child: _preset == _HeatmapPreset.smallMultiples
                        ? _buildSharedDomainComposition()
                        : BravenChartWorkbench(
                            key: const ValueKey('heatmap-workbench'),
                            chartController: _chartController,
                            workbenchController: _workbenchController,
                            availableDisplayModes: const {
                              ChartDisplayMode.chart,
                              ChartDisplayMode.data,
                              ChartDisplayMode.split,
                              ChartDisplayMode.source,
                            },
                            documentOptions: ChartDocumentExtractOptions(
                              documentId: 'heatmap-${_preset.name}-showcase',
                              includeViewState: true,
                              dataStorage: ChartDataStorage.inlineColumns,
                              interactionBindingDescriptors: switch (_preset) {
                                _HeatmapPreset.viewportSource => {
                                  ChartInteractionDocumentCodec
                                      .viewportChangedBinding: JsonObjectValue(
                                    const {
                                      'id': JsonStringValue(
                                        'showcase.heatmap.viewport-source.viewportChanged',
                                      ),
                                    },
                                  ),
                                },
                                _ => const {},
                              },
                              heatmapViewportProviderDescriptors:
                                  _preset == _HeatmapPreset.viewportSource &&
                                      _massiveViewportProviderDescriptor != null
                                  ? {
                                      'heatmap-viewport-source':
                                          _massiveViewportProviderDescriptor!,
                                    }
                                  : const {},
                              heatmapRasterViewportProviderDescriptor:
                                  _preset == _HeatmapPreset.rasterTiles
                                  ? _rasterViewportProviderDescriptor
                                  : null,
                            ),
                            tableOptions: const ChartTableOptions(
                              includeMetadata: true,
                            ),
                            tableRefreshPolicy:
                                ChartTableRefreshPolicy.onDocumentRevision,
                            sourceOptions: const ChartDartSourceOptions(
                              variableName: 'heatmapChart',
                            ),
                            splitBreakpoint: 760,
                            splitAxis: Axis.horizontal,
                            splitGap: 8,
                            splitRatio: 0.56,
                            minimumChartPaneExtent: 320,
                            minimumTablePaneExtent: 360,
                            maximumAutoTablePaneExtent: 640,
                            autoFitTablePane: true,
                            chartBuilder: (context, controller) =>
                                _buildChart(controller),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _HeatmapCoverageStrip(),
        ],
      ),
      optionsChildren: [
        if (_preset == _HeatmapPreset.viewportSource)
          OptionSection(
            key: const ValueKey('heatmap-viewport-source-options'),
            title: 'Viewport source',
            icon: Icons.dataset_outlined,
            children: [
              ActionButton(
                key: const ValueKey('heatmap-reset-massive-viewport'),
                label: 'Return to latest window',
                icon: Icons.last_page_outlined,
                onPressed: _resetMassiveViewport,
              ),
              ActionButton(
                key: const ValueKey('heatmap-reload-resident-tiles'),
                label: 'Clear cache and reload',
                icon: Icons.cached_outlined,
                onPressed: _reloadMassiveViewport,
              ),
              ActionButton(
                key: const ValueKey('heatmap-toggle-live-mutations'),
                label: _streamViewportMutations
                    ? 'Stop live cell stream'
                    : 'Start live cell stream',
                icon: _streamViewportMutations
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                onPressed: _toggleViewportMutationStream,
              ),
            ],
          ),
        if (_preset == _HeatmapPreset.rasterTiles)
          OptionSection(
            key: const ValueKey('heatmap-raster-review-options'),
            title: 'Raster lifecycle',
            icon: Icons.image_outlined,
            children: [
              ActionButton(
                key: const ValueKey('heatmap-raster-review-loading'),
                label: 'Review retained loading',
                icon: Icons.hourglass_top_outlined,
                onPressed: () => unawaited(_reviewRasterLoading()),
              ),
              ActionButton(
                key: const ValueKey('heatmap-raster-review-failure'),
                label: 'Review retained failure',
                icon: Icons.cloud_off_outlined,
                onPressed: () => unawaited(_reviewRasterRetainedFailure()),
              ),
              ActionButton(
                key: const ValueKey('heatmap-raster-retry'),
                label: 'Retry requested window',
                icon: Icons.refresh_outlined,
                onPressed: () => unawaited(_retryRasterViewport()),
              ),
              ActionButton(
                key: const ValueKey('heatmap-raster-return-latest'),
                label: 'Return to latest window',
                icon: Icons.last_page_outlined,
                onPressed: () => unawaited(_returnRasterToLatest()),
              ),
            ],
          ),
        if (_preset == _HeatmapPreset.selection)
          OptionSection(
            key: const ValueKey('heatmap-selection-options'),
            title: 'Matrix selection',
            icon: Icons.select_all_outlined,
            children: [
              EnumOption<HeatmapSelectionExpansion>(
                key: const ValueKey('heatmap-selection-expansion'),
                label: 'Expand selection',
                value: _heatmapSelectionExpansion,
                values: HeatmapSelectionExpansion.values,
                labelBuilder: _selectionExpansionLabel,
                onChanged: (value) =>
                    setState(() => _heatmapSelectionExpansion = value),
              ),
              ActionButton(
                key: const ValueKey('heatmap-clear-matrix-selection'),
                label: 'Clear selection',
                icon: Icons.clear_all_outlined,
                onPressed: _clearMatrixSelection,
              ),
            ],
          ),
        if (_preset == _HeatmapPreset.smallMultiples)
          OptionSection(
            title: 'Small multiples',
            icon: Icons.view_column_outlined,
            children: [
              BoolOption(
                key: const ValueKey('heatmap-shared-domain-toggle'),
                label: 'Share colour domain',
                value: _useSharedDomain,
                onChanged: (value) => setState(() => _useSharedDomain = value),
              ),
              if (_useSharedDomain)
                _slider(
                  key: const ValueKey('heatmap-shared-domain-padding'),
                  label: 'Shared padding',
                  value: _sharedDomainPaddingFraction,
                  minimum: 0,
                  maximum: 0.25,
                  divisions: 25,
                  onChanged: (value) =>
                      setState(() => _sharedDomainPaddingFraction = value),
                ),
              EnumOption<HeatmapValueFilterMode>(
                label: 'Filtered cells',
                value: _smallMultipleFilterMode,
                values: HeatmapValueFilterMode.values,
                labelBuilder: (value) => switch (value) {
                  HeatmapValueFilterMode.dim => 'Dim',
                  HeatmapValueFilterMode.hide => 'Hide',
                },
                onChanged: (value) => setState(() {
                  _smallMultipleFilterMode = value;
                  final filter = _smallMultipleValueFilter;
                  if (filter != null) {
                    _smallMultipleValueFilter = filter.copyWith(mode: value);
                  }
                }),
              ),
              if (_smallMultipleFilterMode == HeatmapValueFilterMode.dim)
                _slider(
                  key: const ValueKey('heatmap-filter-opacity'),
                  label: 'Excluded opacity',
                  value: _smallMultipleExcludedOpacity,
                  minimum: 0,
                  maximum: 0.5,
                  divisions: 25,
                  onChanged: (value) => setState(() {
                    _smallMultipleExcludedOpacity = value;
                    final filter = _smallMultipleValueFilter;
                    if (filter != null) {
                      _smallMultipleValueFilter = filter.copyWith(
                        excludedOpacity: value,
                      );
                    }
                  }),
                ),
              if (_smallMultipleValueFilter != null)
                OutlinedButton.icon(
                  key: const ValueKey('heatmap-clear-value-filter'),
                  onPressed: () =>
                      setState(() => _smallMultipleValueFilter = null),
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Clear value filter'),
                ),
            ],
          ),
        if (_preset == _HeatmapPreset.clustered) _buildClusterOptions(),
        if (_preset == _HeatmapPreset.contours) _buildContourOptions(),
        if (_preset == _HeatmapPreset.density ||
            _preset == _HeatmapPreset.contours)
          _buildDensityOptions(),
        if (_preset == _HeatmapPreset.colourAxes)
          OptionSection(
            key: const ValueKey('heatmap-colour-axes-options'),
            title: 'Colour axes',
            icon: Icons.gradient_outlined,
            children: [
              BoolOption(
                key: const ValueKey('heatmap-latency-axis-toggle'),
                label: 'Latency colour axis',
                value: _showLatencyColorAxis,
                onChanged: (value) =>
                    setState(() => _showLatencyColorAxis = value),
              ),
              BoolOption(
                key: const ValueKey('heatmap-error-axis-toggle'),
                label: 'Error-rate colour axis',
                value: _showErrorRateColorAxis,
                onChanged: (value) =>
                    setState(() => _showErrorRateColorAxis = value),
              ),
              if (_latencyValueFilter != null || _errorRateValueFilter != null)
                ActionButton(
                  key: const ValueKey('heatmap-clear-colour-axis-filters'),
                  label: 'Clear axis filters',
                  icon: Icons.filter_alt_off_outlined,
                  onPressed: () => setState(() {
                    _latencyValueFilter = null;
                    _errorRateValueFilter = null;
                  }),
                ),
            ],
          ),
        if (_preset != _HeatmapPreset.colourAxes)
          OptionSection(
            title: 'Colour scale',
            icon: Icons.gradient_outlined,
            children: [
              EnumOption<_HeatmapPalette>(
                label: 'Palette',
                value: _palette,
                values: _HeatmapPalette.values,
                labelBuilder: (value) => switch (value) {
                  _HeatmapPalette.ocean => 'Ocean',
                  _HeatmapPalette.forest => 'Forest',
                  _HeatmapPalette.sunset => 'Sunset',
                  _HeatmapPalette.viridis => 'Viridis',
                  _HeatmapPalette.graphite => 'Graphite',
                },
                onChanged: (value) => setState(() => _palette = value),
              ),
              BoolOption(
                label: 'Reverse palette',
                value: _reverseScale,
                onChanged: (value) => setState(() => _reverseScale = value),
              ),
              if (_preset != _HeatmapPreset.threshold)
                BoolOption(
                  label: 'Clamp to domain',
                  value: _clampScale,
                  onChanged: (value) => setState(() => _clampScale = value),
                ),
              if (_preset != _HeatmapPreset.threshold &&
                  _preset != _HeatmapPreset.smallMultiples)
                _slider(
                  label: 'Domain padding',
                  value: _domainPadding,
                  minimum: 0,
                  maximum: _domainPaddingMaximum,
                  onChanged: (value) => setState(() => _domainPadding = value),
                ),
              if (_usesMidpoint)
                _slider(
                  label: 'Midpoint offset',
                  value: _midpointOffset,
                  minimum: -_midpointOffsetMaximum,
                  maximum: _midpointOffsetMaximum,
                  onChanged: (value) => setState(() => _midpointOffset = value),
                ),
              ColorOption(
                label: 'Missing cell',
                value: _missingColor,
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                  Color(0xFFFEF3C7),
                  Color(0xFFFCE7F3),
                ],
                keyPrefix: 'heatmap-missing-color',
                onChanged: (value) => setState(() => _missingColor = value),
              ),
              BoolOption(
                label: 'Show colour legend',
                value: _showColorLegend,
                onChanged: (value) => setState(() => _showColorLegend = value),
              ),
            ],
          ),
        if (_preset == _HeatmapPreset.contributions)
          OptionSection(
            title: 'Empty values',
            icon: Icons.check_box_outline_blank,
            children: [
              BoolOption(
                label: 'Style zero activity',
                value: _styleEmptyValues,
                onChanged: (value) => setState(() => _styleEmptyValues = value),
              ),
              ColorOption(
                label: 'Zero activity fill',
                value: _emptyValueColor,
                colors: const [
                  Color(0xFFE5E7EB),
                  Color(0xFFF1F5F9),
                  Color(0xFFECFDF5),
                  Color(0xFFFFF7ED),
                ],
                keyPrefix: 'heatmap-empty-value-fill',
                onChanged: (value) => setState(() => _emptyValueColor = value),
              ),
              ColorOption(
                label: 'Zero activity border',
                value: _emptyValueBorderColor,
                colors: const [
                  Color(0xFFD1D5DB),
                  Color(0xFFCBD5E1),
                  Color(0xFFA7F3D0),
                  Color(0xFFFED7AA),
                ],
                keyPrefix: 'heatmap-empty-value-border',
                onChanged: (value) =>
                    setState(() => _emptyValueBorderColor = value),
              ),
              _slider(
                label: 'Zero border width',
                value: _emptyValueBorderWidth,
                minimum: 0,
                maximum: 3,
                onChanged: (value) =>
                    setState(() => _emptyValueBorderWidth = value),
              ),
              BoolOption(
                label: 'Show zero labels',
                value: _showEmptyValueLabels,
                onChanged: (value) =>
                    setState(() => _showEmptyValueLabels = value),
              ),
              BoolOption(
                label: 'Show in legend',
                value: _showEmptyValueLegend,
                onChanged: (value) =>
                    setState(() => _showEmptyValueLegend = value),
              ),
            ],
          ),
        OptionSection(
          title: 'Cell presentation',
          icon: Icons.grid_view_outlined,
          children: [
            BoolOption(
              label: 'Show cell values',
              value: _showValues,
              onChanged: (value) => setState(() => _showValues = value),
            ),
            _slider(
              label: 'Cell gap',
              value: _gapFraction,
              minimum: 0,
              maximum: 0.3,
              onChanged: (value) => setState(() => _gapFraction = value),
            ),
            _slider(
              label: 'Corner radius',
              value: _cornerRadius,
              minimum: 0,
              maximum: 14,
              onChanged: (value) => setState(() => _cornerRadius = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Motion',
          icon: Icons.animation_outlined,
          children: [
            EnumOption<_HeatmapMotion>(
              label: 'Entrance',
              value: _motion,
              values: _HeatmapMotion.values,
              labelBuilder: (value) => switch (value) {
                _HeatmapMotion.fade => 'Fade',
                _HeatmapMotion.scale => 'Fade + scale',
                _HeatmapMotion.none => 'None',
              },
              onChanged: (value) => setState(() => _motion = value),
            ),
            if (_motion != _HeatmapMotion.none)
              EnumOption<HeatmapEntranceOrder>(
                label: 'Reveal order',
                value: _entranceOrder,
                values: HeatmapEntranceOrder.values,
                labelBuilder: (value) => switch (value) {
                  HeatmapEntranceOrder.simultaneous => 'Simultaneous',
                  HeatmapEntranceOrder.row => 'By row',
                  HeatmapEntranceOrder.column => 'By column',
                  HeatmapEntranceOrder.radial => 'From centre',
                },
                onChanged: (value) => setState(() => _entranceOrder = value),
              ),
            BoolOption(
              label: 'Animate data updates',
              value: _animateUpdates,
              onChanged: (value) => setState(() => _animateUpdates = value),
            ),
            if (_motion != _HeatmapMotion.none)
              ActionButton(
                key: const ValueKey('heatmap-options-replay'),
                label: 'Replay entrance',
                icon: Icons.replay_outlined,
                onPressed: _chartController.replaySeriesEntrance,
              ),
            if (_animateUpdates)
              ActionButton(
                key: const ValueKey('heatmap-options-update'),
                label: 'Update stable values',
                icon: Icons.autorenew,
                onPressed: () => setState(() => _dataRevision++),
              ),
          ],
        ),
        OptionSection(
          key: const ValueKey('heatmap-performance-audit-options'),
          title: 'Performance audit',
          icon: Icons.monitor_heart_outlined,
          children: [
            _HeatmapPerformanceProbe(
              key: ValueKey('heatmap-performance-${_preset.name}'),
              scenarioLabel: _title,
            ),
          ],
        ),
      ],
    );
  }

  OptionSection _buildContourOptions() {
    return OptionSection(
      key: const ValueKey('heatmap-contour-options'),
      title: 'Contour overlay',
      icon: Icons.multiline_chart_outlined,
      children: [
        BoolOption(
          label: 'Show contours',
          value: _showContours,
          onChanged: (value) => setState(() => _showContours = value),
        ),
        EnumOption<_ContourDetail>(
          label: 'Contour levels',
          value: _contourDetail,
          values: _ContourDetail.values,
          labelBuilder: (value) => switch (value) {
            _ContourDetail.coarse => 'Coarse · 3 levels',
            _ContourDetail.detailed => 'Detailed · 5 levels',
          },
          onChanged: (value) => setState(() => _contourDetail = value),
        ),
        EnumOption<_ContourGeometry>(
          label: 'Line geometry',
          value: _contourGeometry,
          values: _ContourGeometry.values,
          labelBuilder: (value) => switch (value) {
            _ContourGeometry.exact => 'Exact · linear',
            _ContourGeometry.smooth => 'Smooth · Bézier',
          },
          onChanged: (value) => setState(() => _contourGeometry = value),
        ),
        if (_contourGeometry == _ContourGeometry.smooth)
          _slider(
            key: const ValueKey('heatmap-contour-tension'),
            label: 'Curve tension',
            value: _contourTension,
            minimum: 0.05,
            maximum: 0.5,
            onChanged: (value) => setState(() => _contourTension = value),
          ),
        _slider(
          key: const ValueKey('heatmap-contour-stroke-width'),
          label: 'Stroke width',
          value: _contourStrokeWidth,
          minimum: 1,
          maximum: 5,
          onChanged: (value) => setState(() => _contourStrokeWidth = value),
        ),
      ],
    );
  }

  String _markerShapeLabel(HeatmapDendrogramMarkerShape value) =>
      switch (value) {
        HeatmapDendrogramMarkerShape.circle => 'Circle',
        HeatmapDendrogramMarkerShape.square => 'Square',
        HeatmapDendrogramMarkerShape.diamond => 'Diamond',
        HeatmapDendrogramMarkerShape.triangle => 'Triangle',
      };

  String _markerFillLabel(HeatmapDendrogramMarkerFill value) => switch (value) {
    HeatmapDendrogramMarkerFill.solid => 'Solid',
    HeatmapDendrogramMarkerFill.hollow => 'Hollow',
  };

  OptionSection _buildClusterOptions() {
    return OptionSection(
      key: const ValueKey('heatmap-cluster-options'),
      title: 'Matrix clustering',
      icon: Icons.account_tree_outlined,
      children: [
        BoolOption(
          key: const ValueKey('heatmap-cluster-apply-order'),
          label: 'Apply clustered order',
          subtitle: 'Turn off to compare the authored source order.',
          value: _applyClusterOrder,
          onChanged: (value) => setState(() {
            _applyClusterOrder = value;
            if (!value) _clusterFocus = _ClusterFocus.full;
            _clearClusterProjection();
          }),
        ),
        EnumOption<_ClusterFocus>(
          key: const ValueKey('heatmap-cluster-focus'),
          label: 'Initial focus',
          value: _clusterFocus,
          values: _ClusterFocus.values,
          labelBuilder: (value) => switch (value) {
            _ClusterFocus.full => 'Full hierarchy',
            _ClusterFocus.primary => 'Primary cluster',
            _ClusterFocus.secondary => 'Secondary cluster',
          },
          onChanged: (value) => setState(() {
            _applyClusterOrder = true;
            _clusterFocus = value;
            _clearClusterProjection();
          }),
        ),
        EnumOption<HeatmapClusterAxisMode>(
          key: const ValueKey('heatmap-cluster-axis-mode'),
          label: 'Cluster axes',
          value: _clusterAxisMode,
          values: const [
            HeatmapClusterAxisMode.rows,
            HeatmapClusterAxisMode.columns,
            HeatmapClusterAxisMode.both,
          ],
          labelBuilder: (value) => switch (value) {
            HeatmapClusterAxisMode.none => 'None',
            HeatmapClusterAxisMode.rows => 'Rows',
            HeatmapClusterAxisMode.columns => 'Columns',
            HeatmapClusterAxisMode.both => 'Rows + columns',
          },
          onChanged: (value) => setState(() {
            _clusterAxisMode = value;
            _clearClusterProjection();
          }),
        ),
        EnumOption<HeatmapClusterDistance>(
          key: const ValueKey('heatmap-cluster-distance'),
          label: 'Distance',
          value: _clusterDistance,
          values: HeatmapClusterDistance.values,
          labelBuilder: (value) => switch (value) {
            HeatmapClusterDistance.euclidean => 'Euclidean',
            HeatmapClusterDistance.correlation => 'Correlation',
          },
          onChanged: (value) => setState(() {
            _clusterDistance = value;
            _clearClusterProjection();
          }),
        ),
        EnumOption<HeatmapClusterLinkage>(
          key: const ValueKey('heatmap-cluster-linkage'),
          label: 'Linkage',
          value: _clusterLinkage,
          values: HeatmapClusterLinkage.values,
          labelBuilder: (value) => switch (value) {
            HeatmapClusterLinkage.average => 'Average',
            HeatmapClusterLinkage.complete => 'Complete',
            HeatmapClusterLinkage.single => 'Single',
          },
          onChanged: (value) => setState(() {
            _clusterLinkage = value;
            _clearClusterProjection();
          }),
        ),
        EnumOption<HeatmapClusterMissingValueMode>(
          key: const ValueKey('heatmap-cluster-missing-values'),
          label: 'Missing values',
          value: _clusterMissingValueMode,
          values: HeatmapClusterMissingValueMode.values,
          labelBuilder: (value) => switch (value) {
            HeatmapClusterMissingValueMode.pairwiseIgnore =>
              'Ignore unmatched dimensions',
            HeatmapClusterMissingValueMode.zero => 'Substitute zero',
          },
          onChanged: (value) => setState(() {
            _clusterMissingValueMode = value;
            _clearClusterProjection();
          }),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-show-row-dendrogram'),
          label: 'Show row dendrogram',
          subtitle: 'Compose the accepted row hierarchy beside the matrix.',
          value: _showRowDendrogram,
          onChanged: (value) => setState(() => _showRowDendrogram = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-show-column-dendrogram'),
          label: 'Show column dendrogram',
          subtitle: 'Compose the accepted column hierarchy above the matrix.',
          value: _showColumnDendrogram,
          onChanged: (value) => setState(() => _showColumnDendrogram = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-interaction'),
          label: 'Hierarchy interaction',
          subtitle: 'Hover or tap visible nodes and branches.',
          value: _enableDendrogramInteraction,
          onChanged: (value) => setState(() {
            _enableDendrogramInteraction = value;
            if (!value) _clearDendrogramInteraction();
          }),
        ),
        if (_rowDendrogramInteraction.selectedTarget != null ||
            _columnDendrogramInteraction.selectedTarget != null)
          ActionButton(
            key: const ValueKey('heatmap-clear-dendrogram-selection'),
            label: 'Clear hierarchy selection',
            icon: Icons.deselect_outlined,
            onPressed: () => setState(_clearDendrogramInteraction),
          ),
        if (_selectedCollapsibleHierarchyTarget case final target?)
          ActionButton(
            key: const ValueKey('heatmap-collapse-selected-hierarchy'),
            label: 'Collapse selected branch',
            icon: Icons.unfold_less_outlined,
            isPrimary: true,
            onPressed: () => setState(() => _collapseHierarchyTarget(target)),
          ),
        if (_selectedCollapsedHierarchyTarget case final target?)
          ActionButton(
            key: const ValueKey('heatmap-expand-selected-hierarchy'),
            label: 'Expand selected group',
            icon: Icons.unfold_more_outlined,
            isPrimary: true,
            onPressed: () => setState(() => _expandHierarchyTarget(target)),
          ),
        if (_hasCollapsedHierarchyGroups)
          ActionButton(
            key: const ValueKey('heatmap-expand-all-hierarchy'),
            label: 'Expand all groups',
            icon: Icons.open_in_full_outlined,
            onPressed: () => setState(_clearClusterProjection),
          ),
        EnumOption<HeatmapHierarchyReducer>(
          key: const ValueKey('heatmap-cluster-hierarchy-reducer'),
          label: 'Collapsed-cell reducer',
          subtitle: 'How a collapsed row or column group combines values.',
          value: _hierarchyReducer,
          values: HeatmapHierarchyReducer.values,
          labelBuilder: (value) => switch (value) {
            HeatmapHierarchyReducer.mean => 'Mean',
            HeatmapHierarchyReducer.sum => 'Sum',
            HeatmapHierarchyReducer.minimum => 'Minimum',
            HeatmapHierarchyReducer.maximum => 'Maximum',
          },
          onChanged: (value) => setState(() => _hierarchyReducer = value),
        ),
        if (_clusterHierarchyIsVisible)
          InfoBox(
            message:
                'Hierarchy view keeps the ${_clusterFocusLabel.toLowerCase()} '
                'fixed so the matrix, labels, and both trees remain aligned. '
                'Hover or tap an enabled hierarchy to inspect its stable '
                'node or branch identity. Tab into a hierarchy, use the arrow '
                'keys to move between visible nodes, Enter or Space to '
                'select, and Escape to clear. Selection only inspects; use '
                'the explicit collapse or expand action to change the visible '
                'matrix. Collapsed cells use the selected reducer and retain '
                'all original row, column, and point identities. '
                'Initial focus prunes accepted subtrees before layout; it does '
                'not recluster values. Hide both '
                'dendrograms to restore zoom, pan, and the X scrollbar.',
          ),
        EnumOption<HeatmapDendrogramDistanceScale>(
          key: const ValueKey('heatmap-cluster-dendrogram-distance-scale'),
          label: 'Branch spacing',
          value: _dendrogramDistanceScale,
          values: HeatmapDendrogramDistanceScale.values,
          labelBuilder: (value) => switch (value) {
            HeatmapDendrogramDistanceScale.structural => 'Readable hierarchy',
            HeatmapDendrogramDistanceScale.proportional =>
              'Proportional distance',
          },
          onChanged: (value) =>
              setState(() => _dendrogramDistanceScale = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-extent'),
          label: 'Branch extent',
          value: _dendrogramExtent,
          minimum: 48,
          maximum: 120,
          onChanged: (value) => setState(() => _dendrogramExtent = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-stroke'),
          label: 'Branch stroke',
          value: _dendrogramStrokeWidth,
          minimum: 1,
          maximum: 4,
          onChanged: (value) => setState(() => _dendrogramStrokeWidth = value),
        ),
        ColorOption(
          label: 'Branch colour',
          value: _dendrogramBranchColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-branch-color',
          onChanged: (value) => setState(() => _dendrogramBranchColor = value),
        ),
        EnumOption<StrokeCap>(
          key: const ValueKey('heatmap-cluster-dendrogram-cap'),
          label: 'Branch caps',
          value: _dendrogramBranchCap,
          values: StrokeCap.values,
          labelBuilder: (value) => switch (value) {
            StrokeCap.butt => 'Flat',
            StrokeCap.round => 'Round',
            StrokeCap.square => 'Square',
          },
          onChanged: (value) => setState(() => _dendrogramBranchCap = value),
        ),
        EnumOption<StrokeJoin>(
          key: const ValueKey('heatmap-cluster-dendrogram-join'),
          label: 'Branch joins',
          value: _dendrogramBranchJoin,
          values: StrokeJoin.values,
          labelBuilder: (value) => switch (value) {
            StrokeJoin.miter => 'Miter',
            StrokeJoin.round => 'Round',
            StrokeJoin.bevel => 'Bevel',
          },
          onChanged: (value) => setState(() => _dendrogramBranchJoin = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-elbow-radius'),
          label: 'Elbow radius',
          value: _dendrogramElbowRadius,
          minimum: 0,
          maximum: 16,
          onChanged: (value) => setState(() => _dendrogramElbowRadius = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-baseline'),
          label: 'Show leaf baseline',
          value: _showDendrogramBaseline,
          onChanged: (value) => setState(() => _showDendrogramBaseline = value),
        ),
        ColorOption(
          label: 'Baseline colour',
          value: _dendrogramBaselineColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-baseline-color',
          onChanged: (value) =>
              setState(() => _dendrogramBaselineColor = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-baseline-width'),
          label: 'Baseline stroke',
          value: _dendrogramBaselineWidth,
          minimum: 0.5,
          maximum: 3,
          onChanged: (value) =>
              setState(() => _dendrogramBaselineWidth = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-ticks'),
          label: 'Show leaf ticks',
          value: _showDendrogramTicks,
          onChanged: (value) => setState(() => _showDendrogramTicks = value),
        ),
        ColorOption(
          label: 'Tick colour',
          value: _dendrogramTickColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-tick-color',
          onChanged: (value) => setState(() => _dendrogramTickColor = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-tick-width'),
          label: 'Tick stroke',
          value: _dendrogramTickWidth,
          minimum: 0.5,
          maximum: 3,
          onChanged: (value) => setState(() => _dendrogramTickWidth = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-tick-length'),
          label: 'Tick length',
          value: _dendrogramTickLength,
          minimum: 0,
          maximum: 12,
          onChanged: (value) => setState(() => _dendrogramTickLength = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-leaf-markers'),
          label: 'Show leaf markers',
          value: _showDendrogramLeafMarkers,
          onChanged: (value) =>
              setState(() => _showDendrogramLeafMarkers = value),
        ),
        ColorOption(
          label: 'Leaf fill colour',
          value: _dendrogramLeafMarkerColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-leaf-marker-color',
          onChanged: (value) =>
              setState(() => _dendrogramLeafMarkerColor = value),
        ),
        EnumOption<HeatmapDendrogramMarkerShape>(
          key: const ValueKey('heatmap-cluster-dendrogram-leaf-shape'),
          label: 'Leaf marker shape',
          value: _dendrogramLeafMarkerShape,
          values: HeatmapDendrogramMarkerShape.values,
          labelBuilder: _markerShapeLabel,
          onChanged: (value) =>
              setState(() => _dendrogramLeafMarkerShape = value),
        ),
        EnumOption<HeatmapDendrogramMarkerFill>(
          key: const ValueKey('heatmap-cluster-dendrogram-leaf-fill'),
          label: 'Leaf marker fill',
          value: _dendrogramLeafMarkerFill,
          values: HeatmapDendrogramMarkerFill.values,
          labelBuilder: _markerFillLabel,
          onChanged: (value) =>
              setState(() => _dendrogramLeafMarkerFill = value),
        ),
        ColorOption(
          label: 'Leaf border colour',
          value: _dendrogramLeafMarkerBorderColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-leaf-marker-border-color',
          onChanged: (value) =>
              setState(() => _dendrogramLeafMarkerBorderColor = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-leaf-border-width'),
          label: 'Leaf border stroke',
          value: _dendrogramLeafMarkerBorderWidth,
          minimum: 0,
          maximum: 4,
          onChanged: (value) =>
              setState(() => _dendrogramLeafMarkerBorderWidth = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-leaf-radius'),
          label: 'Leaf marker radius',
          value: _dendrogramLeafMarkerRadius,
          minimum: 1,
          maximum: 8,
          onChanged: (value) =>
              setState(() => _dendrogramLeafMarkerRadius = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-merge-markers'),
          label: 'Show merge markers',
          value: _showDendrogramMergeMarkers,
          onChanged: (value) =>
              setState(() => _showDendrogramMergeMarkers = value),
        ),
        ColorOption(
          label: 'Merge fill colour',
          value: _dendrogramMergeMarkerColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-merge-marker-color',
          onChanged: (value) =>
              setState(() => _dendrogramMergeMarkerColor = value),
        ),
        EnumOption<HeatmapDendrogramMarkerShape>(
          key: const ValueKey('heatmap-cluster-dendrogram-merge-shape'),
          label: 'Merge marker shape',
          value: _dendrogramMergeMarkerShape,
          values: HeatmapDendrogramMarkerShape.values,
          labelBuilder: _markerShapeLabel,
          onChanged: (value) =>
              setState(() => _dendrogramMergeMarkerShape = value),
        ),
        EnumOption<HeatmapDendrogramMarkerFill>(
          key: const ValueKey('heatmap-cluster-dendrogram-merge-fill'),
          label: 'Merge marker fill',
          value: _dendrogramMergeMarkerFill,
          values: HeatmapDendrogramMarkerFill.values,
          labelBuilder: _markerFillLabel,
          onChanged: (value) =>
              setState(() => _dendrogramMergeMarkerFill = value),
        ),
        ColorOption(
          label: 'Merge border colour',
          value: _dendrogramMergeMarkerBorderColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-merge-marker-border-color',
          onChanged: (value) =>
              setState(() => _dendrogramMergeMarkerBorderColor = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-merge-border-width'),
          label: 'Merge border stroke',
          value: _dendrogramMergeMarkerBorderWidth,
          minimum: 0,
          maximum: 4,
          onChanged: (value) =>
              setState(() => _dendrogramMergeMarkerBorderWidth = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-merge-radius'),
          label: 'Merge marker radius',
          value: _dendrogramMergeMarkerRadius,
          minimum: 1,
          maximum: 8,
          onChanged: (value) =>
              setState(() => _dendrogramMergeMarkerRadius = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-leaf-labels'),
          label: 'Show leaf labels',
          value: _showDendrogramLeafLabels,
          onChanged: (value) =>
              setState(() => _showDendrogramLeafLabels = value),
        ),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-merge-labels'),
          label: 'Show merge distances',
          subtitle: 'Original cluster distance, including in readable spacing.',
          value: _showDendrogramMergeLabels,
          onChanged: (value) =>
              setState(() => _showDendrogramMergeLabels = value),
        ),
        EnumOption<HeatmapDendrogramLabelDensity>(
          key: const ValueKey('heatmap-cluster-dendrogram-label-density'),
          label: 'Label density',
          value: _dendrogramLabelDensity,
          values: HeatmapDendrogramLabelDensity.values,
          labelBuilder: (value) => switch (value) {
            HeatmapDendrogramLabelDensity.all => 'All',
            HeatmapDendrogramLabelDensity.balanced => 'Balanced',
            HeatmapDendrogramLabelDensity.sparse => 'Sparse',
          },
          onChanged: (value) => setState(() => _dendrogramLabelDensity = value),
        ),
        EnumOption<HeatmapDendrogramLabelPlacement>(
          key: const ValueKey('heatmap-cluster-dendrogram-label-placement'),
          label: 'Label placement',
          value: _dendrogramLabelPlacement,
          values: HeatmapDendrogramLabelPlacement.values,
          labelBuilder: (value) => switch (value) {
            HeatmapDendrogramLabelPlacement.before => 'Before node',
            HeatmapDendrogramLabelPlacement.after => 'After node',
          },
          onChanged: (value) =>
              setState(() => _dendrogramLabelPlacement = value),
        ),
        ColorOption(
          label: 'Label text colour',
          value: _dendrogramLabelColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-label-color',
          onChanged: (value) => setState(() => _dendrogramLabelColor = value),
        ),
        ColorOption(
          label: 'Label background',
          value: _dendrogramLabelBackgroundColor,
          colors: _sequentialColors,
          keyPrefix: 'heatmap-dendrogram-label-background',
          onChanged: (value) =>
              setState(() => _dendrogramLabelBackgroundColor = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-label-font-size'),
          label: 'Label font size',
          value: _dendrogramLabelFontSize,
          minimum: 8,
          maximum: 16,
          onChanged: (value) =>
              setState(() => _dendrogramLabelFontSize = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-label-characters'),
          label: 'Label characters',
          value: _dendrogramMaxLabelCharacters,
          minimum: 4,
          maximum: 24,
          divisions: 20,
          onChanged: (value) =>
              setState(() => _dendrogramMaxLabelCharacters = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-label-decimals'),
          label: 'Distance decimals',
          value: _dendrogramMergeLabelDecimals,
          minimum: 0,
          maximum: 4,
          divisions: 4,
          onChanged: (value) =>
              setState(() => _dendrogramMergeLabelDecimals = value),
        ),
        const Divider(),
        BoolOption(
          key: const ValueKey('heatmap-cluster-dendrogram-lod'),
          label: 'Automatic level of detail',
          subtitle:
              'Suppress sub-pixel branches and crowded decoration at the current size.',
          value: _automaticDendrogramLevelOfDetail,
          onChanged: (value) =>
              setState(() => _automaticDendrogramLevelOfDetail = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-min-branch'),
          label: 'Minimum branch length',
          value: _dendrogramMinimumBranchLength,
          minimum: 0,
          maximum: 4,
          divisions: 16,
          onChanged: (value) =>
              setState(() => _dendrogramMinimumBranchLength = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-min-guides'),
          label: 'Leaf guide spacing',
          value: _dendrogramMinimumLeafGuideSpacing,
          minimum: 0,
          maximum: 12,
          divisions: 24,
          onChanged: (value) =>
              setState(() => _dendrogramMinimumLeafGuideSpacing = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-min-leaf-markers'),
          label: 'Leaf marker spacing',
          value: _dendrogramMinimumLeafMarkerSpacing,
          minimum: 0,
          maximum: 24,
          divisions: 24,
          onChanged: (value) =>
              setState(() => _dendrogramMinimumLeafMarkerSpacing = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-min-merge-markers'),
          label: 'Merge marker spacing',
          value: _dendrogramMinimumMergeMarkerSpacing,
          minimum: 0,
          maximum: 24,
          divisions: 24,
          onChanged: (value) =>
              setState(() => _dendrogramMinimumMergeMarkerSpacing = value),
        ),
        _slider(
          key: const ValueKey('heatmap-cluster-dendrogram-min-labels'),
          label: 'Label spacing',
          value: _dendrogramMinimumLabelSpacing,
          minimum: 0,
          maximum: 64,
          divisions: 32,
          onChanged: (value) =>
              setState(() => _dendrogramMinimumLabelSpacing = value),
        ),
      ],
    );
  }

  OptionSection _buildDensityOptions() {
    return OptionSection(
      key: const ValueKey('heatmap-density-options'),
      title: 'Density estimation',
      icon: Icons.blur_circular_outlined,
      children: [
        EnumOption<HeatmapDensityKernel>(
          label: 'Kernel',
          value: _densityKernel,
          values: HeatmapDensityKernel.values,
          labelBuilder: (value) => switch (value) {
            HeatmapDensityKernel.gaussian => 'Gaussian',
            HeatmapDensityKernel.epanechnikov => 'Epanechnikov',
          },
          onChanged: (value) => setState(() => _densityKernel = value),
        ),
        _slider(
          label: 'Engagement bandwidth',
          value: _densityBandwidthX,
          minimum: 0.25,
          maximum: 1.6,
          onChanged: (value) => setState(() => _densityBandwidthX = value),
        ),
        _slider(
          label: 'Value bandwidth',
          value: _densityBandwidthY,
          minimum: 3,
          maximum: 20,
          onChanged: (value) => setState(() => _densityBandwidthY = value),
        ),
        ActionButton(
          key: const ValueKey('heatmap-density-reset'),
          label: 'Reset density',
          icon: Icons.restart_alt_outlined,
          onPressed: () => setState(() {
            _densityKernel = HeatmapDensityKernel.gaussian;
            _densityBandwidthX = 0.72;
            _densityBandwidthY = 8;
          }),
        ),
      ],
    );
  }

  Widget _buildChart(BravenChartController controller) {
    final heatmapSeries = _chartSeries.whereType<HeatmapChartSeries>().toList(
      growable: false,
    );
    final showsClusterHierarchy = _clusterHierarchyIsVisible;
    final chart = BravenChartPlus(
      key: ValueKey('heatmap-chart-${_preset.name}'),
      bravenChartController: controller,
      series: _chartSeries,
      heatmapRasterViewportController: _preset == _HeatmapPreset.rasterTiles
          ? _rasterController
          : null,
      heatmapRasterFilterQuality: ui.FilterQuality.low,
      interactionGroupController: switch (_preset) {
        _HeatmapPreset.viewportSource => _viewportGroupController,
        _HeatmapPreset.rasterTiles => _rasterGroupController,
        _ => null,
      },
      interactionGroupOptions: const ChartInteractionGroupOptions(
        synchronizeCursor: false,
        synchronizeViewport: true,
        synchronizeSelection: false,
      ),
      resetViewportBounds: switch (_preset) {
        _HeatmapPreset.viewportSource => _massiveResetViewportBounds,
        _HeatmapPreset.rasterTiles => _rasterResetViewportBounds,
        _ => null,
      },
      showLegend: false,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: _preset == _HeatmapPreset.rasterTiles
          ? XAxisConfig(
              label: 'Acquisition sample',
              min: _rasterSource?.domain.fullBounds.minimumX ?? -0.5,
              max: _rasterSource?.domain.fullBounds.maximumX ?? 999999.5,
              tickCount: 7,
            )
          : _preset == _HeatmapPreset.viewportSource
          ? XAxisConfig(
              label: 'Source column',
              min: _viewportSource?.domain.fullBounds.minimumX ?? -0.5,
              max: _viewportSource?.domain.fullBounds.maximumX ?? 999999.5,
              tickCount: 7,
            )
          : _preset == _HeatmapPreset.irregular
          ? const XAxisConfig(
              label: 'Elapsed hour',
              min: 0,
              max: 12,
              tickCount: 7,
            )
          : _preset == _HeatmapPreset.dense
          ? const XAxisConfig(label: 'Sample', min: 80, max: 120, tickCount: 9)
          : showsClusterHierarchy
          ? XAxisConfig(
              label: _xAxisLabel,
              visible: false,
              minHeight: 0,
              maxHeight: 0,
              categoryAxis: CategoryAxisConfig(
                categories: _columnLabels,
                minimumCategoryExtent: 42,
              ),
            )
          : XAxisConfig(
              label: _xAxisLabel,
              categoryAxis: CategoryAxisConfig(
                categories: _columnLabels,
                minimumCategoryExtent: 42,
              ),
            ),
      yAxis: _preset == _HeatmapPreset.rasterTiles
          ? YAxisConfig(
              position: YAxisPosition.left,
              label: 'Frequency bin',
              min: _rasterSource?.domain.fullBounds.minimumY ?? -0.5,
              max: _rasterSource?.domain.fullBounds.maximumY ?? 511.5,
              tickCount: 7,
            )
          : _preset == _HeatmapPreset.viewportSource
          ? YAxisConfig(
              position: YAxisPosition.left,
              label: 'Signal row',
              min: _viewportSource?.domain.fullBounds.minimumY ?? -0.5,
              max: _viewportSource?.domain.fullBounds.maximumY ?? 23.5,
              tickCount: 7,
            )
          : _preset == _HeatmapPreset.dense
          ? YAxisConfig(
              position: YAxisPosition.left,
              label: 'Channel',
              min: 30,
              max: 60,
              tickCount: 7,
            )
          : showsClusterHierarchy
          ? YAxisConfig(
              position: YAxisPosition.hidden,
              label: _yAxisLabel,
              minWidth: 0,
              maxWidth: 0,
              categoryAxis: CategoryAxisConfig(
                categories: _rowLabels,
                minimumCategoryExtent: 34,
                maximumLabelExtent: _clusterRowLabelWidth,
              ),
            )
          : YAxisConfig(
              position: YAxisPosition.left,
              label: _preset == _HeatmapPreset.clustered ? null : _yAxisLabel,
              categoryAxis: CategoryAxisConfig(
                categories: _rowLabels,
                minimumCategoryExtent: 34,
                maximumLabelExtent: 78,
              ),
            ),
      axislessPlotInsets: _clusterPlotInsets,
      interactionConfig: InteractionConfig(
        tooltip: const TooltipConfig(enabled: true),
        keyboard: const KeyboardConfig(enabled: true),
        enableZoom:
            !showsClusterHierarchy && _preset != _HeatmapPreset.selection,
        enablePan:
            !showsClusterHierarchy && _preset != _HeatmapPreset.selection,
        enableSelection: _preset == _HeatmapPreset.selection,
        onViewportChanged: switch (_preset) {
          _HeatmapPreset.viewportSource => _handleMassiveViewportChanged,
          _HeatmapPreset.rasterTiles => _handleRasterViewportChanged,
          _ => null,
        },
        selection: _preset == _HeatmapPreset.selection
            ? ChartSelectionConfig(
                acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
                scope: ChartSelectionScope.mark,
                heatmapExpansion: _heatmapSelectionExpansion,
                clearOnBackgroundTap: false,
                brush: const ChartSelectionBrushConfig(
                  enabled: true,
                  keyboardEnabled: true,
                  initialVisible: true,
                  initialBox: ChartSelectionBrushBox(
                    minimumX: 1.25,
                    maximumX: 3.75,
                    minimumY: 1.25,
                    maximumY: 3.75,
                  ),
                  style: ChartSelectionBrushStyle(
                    fillOpacity: 0.13,
                    borderWidth: 2,
                    borderRadius: 4,
                    handleSize: 11,
                    handleHitSize: 44,
                  ),
                ),
              )
            : const ChartSelectionConfig(),
      ),
      annotations: _annotations,
      showXScrollbar:
          !showsClusterHierarchy && _preset != _HeatmapPreset.selection,
      showYScrollbar: _preset == _HeatmapPreset.dense,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: showsClusterHierarchy
              ? _buildClusteredComposition(chart)
              : chart,
        ),
        const SizedBox(height: 8),
        if (_preset == _HeatmapPreset.colourAxes)
          HeatmapColorLegendGroup(
            key: const ValueKey('heatmap-colour-axis-group'),
            series: heatmapSeries,
            rampExtent: 210,
            onValueFilterChanged: _updateColourAxisFilter,
          )
        else if (heatmapSeries.isNotEmpty)
          HeatmapColorLegend(series: heatmapSeries.single),
      ],
    );
  }

  Widget _buildViewportSourceStatus() {
    final source = _viewportSource;
    final controller = _viewportController;
    if (source == null || controller == null) return const SizedBox.shrink();
    final snapshot = controller.snapshot;
    final diagnostics = controller.diagnostics;
    final theme = Theme.of(context);
    final error = snapshot.error;
    return Container(
      key: const ValueKey('heatmap-viewport-source-status'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error == null
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ViewportMetric(
                label: 'Conceptual matrix',
                value: '${source.domain.cellCount ~/ 1000000}M cells',
              ),
              _ViewportMetric(
                label: 'Resident snapshot',
                value: '${snapshot.cells.length} cells',
              ),
              _ViewportMetric(
                label: 'Requested tiles',
                value: '${snapshot.requestedTiles.length}',
              ),
              _ViewportMetric(
                label: 'Cache',
                value:
                    '${snapshot.cacheTileCount}/${controller.maxCachedTiles}',
              ),
              _ViewportMetric(
                label: 'Loads / hits',
                value: '${diagnostics.loadsStarted} / ${diagnostics.cacheHits}',
              ),
              _ViewportMetric(
                label: 'Resident reuses',
                value: '${diagnostics.residentSnapshotReuses}',
              ),
              _ViewportMetric(
                label: 'Generation',
                value:
                    '${snapshot.generation}${snapshot.isLoading ? ' · loading' : ''}',
              ),
              const _ViewportMetric(
                label: 'Portable provider',
                value: 'procedural-matrix.v1',
              ),
              _ViewportMetric(
                label: 'Live revision',
                value: diagnostics.lastMutationRevision < 0
                    ? 'Not started'
                    : '${diagnostics.lastMutationRevision}',
              ),
              _ViewportMetric(
                label: 'Live publish',
                value:
                    '${diagnostics.cellMutationsApplied} cells / ${diagnostics.mutationPublications} frames',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error == null
                ? 'Pan or zoom to request bounded tiles, or start the live stream to patch resident cells through ordered mutation batches. The artifact carries a portable provider descriptor; Data and Source still expose only the current immutable resident snapshot.'
                : '$error · Narrow the viewport or return to the latest window.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: error == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onErrorContainer,
              fontWeight: error == null ? null : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRasterSourceStatus() {
    final source = _rasterSource;
    final controller = _rasterController;
    if (source == null || controller == null) return const SizedBox.shrink();
    final snapshot = controller.snapshot;
    final diagnostics = snapshot.diagnostics;
    final theme = Theme.of(context);
    final error = snapshot.error;
    final reviewState = switch ((
      snapshot.isLoading,
      snapshot.hasMountedTiles,
      error != null,
    )) {
      (true, _, _) => _RasterReviewState.loading,
      (false, true, true) => _RasterReviewState.retainedFallback,
      (false, false, true) => _RasterReviewState.failed,
      (false, true, false) => _RasterReviewState.ready,
      _ => _RasterReviewState.idle,
    };
    final reviewLabel = switch (reviewState) {
      _RasterReviewState.idle => 'Idle',
      _RasterReviewState.loading =>
        snapshot.hasMountedTiles
            ? 'Loading · previous viewport retained'
            : 'Loading',
      _RasterReviewState.ready => 'Ready',
      _RasterReviewState.retainedFallback => 'Retained fallback',
      _RasterReviewState.failed => 'Failed · no mounted viewport',
    };
    return Container(
      key: const ValueKey('heatmap-raster-source-status'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error == null
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ViewportMetric(label: 'State', value: reviewLabel),
              _ViewportMetric(
                label: 'Logical signal',
                value: '${source.logicalCellCount ~/ 1000000}M samples',
              ),
              _ViewportMetric(
                label: 'Mounted tiles',
                value:
                    '${snapshot.mountedTiles.length}/${snapshot.requestedTileKeys.length}',
              ),
              _ViewportMetric(
                label: 'Decoded cache',
                value:
                    '${(diagnostics.decodedCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MiB',
              ),
              _ViewportMetric(
                label: 'Semantic cells',
                value: '${snapshot.semanticCells.length}',
              ),
              _ViewportMetric(
                label: 'Loads / hits',
                value: '${diagnostics.loadsStarted} / ${diagnostics.cacheHits}',
              ),
              _ViewportMetric(
                label: 'Generation',
                value:
                    '${snapshot.generation}${snapshot.isLoading ? ' · loading' : ''}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.isLoading && snapshot.hasMountedTiles
                ? 'The requested viewport is loading while the last complete raster and semantic companion remain mounted. Publication is atomic; the chart never shows a partial tile batch.'
                : error == null
                ? 'A 512-channel, one-million-sample spectrogram is decoded only for the visible time window. Each tile also carries bounded, honest aggregate cells for tooltips, selection, accessibility, Data, and Source; no semantic value is inferred from pixels.'
                : snapshot.hasMountedTiles
                ? '$error · The previous complete viewport remains interactive. Retry the requested window or return to latest.'
                : '$error · No complete viewport has mounted; the artifact-defined cell fallback remains available to a hydrated host.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: error == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onErrorContainer,
              fontWeight: error == null ? null : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _updateColourAxisFilter(String seriesId, HeatmapValueFilter? filter) {
    setState(() {
      if (seriesId == 'latency-axis') _latencyValueFilter = filter;
      if (seriesId == 'error-rate-axis') _errorRateValueFilter = filter;
    });
  }

  Widget _buildSharedDomainComposition() {
    final sourceSeries = _smallMultipleSourceSeries;
    final sharedDomain = HeatmapSharedColorDomain.fromSeries(
      sourceSeries,
      paddingFraction: _sharedDomainPaddingFraction,
    );
    final displayedSeries = [
      for (final series in sourceSeries)
        series.copyWith(
          colorScale: _useSharedDomain
              ? sharedDomain.scaleFor(series.colorScale)
              : series.colorScale,
          valueFilter: _smallMultipleValueFilter,
          clearValueFilter: _smallMultipleValueFilter == null,
        ),
    ];
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('heatmap-small-multiples-composition'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: Icon(
                _useSharedDomain
                    ? Icons.link_outlined
                    : Icons.link_off_outlined,
                size: 16,
              ),
              label: Text(
                _useSharedDomain
                    ? 'Shared ${sharedDomain.minimumValue.toStringAsFixed(1)}–${sharedDomain.maximumValue.toStringAsFixed(1)} ms'
                    : 'Independent panel domains',
              ),
            ),
            Text(
              _useSharedDomain
                  ? 'Equal colours now mean equal latency in every panel.'
                  : 'Each panel stretches its own local range.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_smallMultipleValueFilter case final filter?)
              Chip(
                avatar: const Icon(Icons.filter_alt_outlined, size: 16),
                label: Text(
                  '${filter.minimumValue.toStringAsFixed(1)}–'
                  '${filter.maximumValue.toStringAsFixed(1)} ms · '
                  '${filter.mode.name}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panels = [
                for (var index = 0; index < displayedSeries.length; index++)
                  _buildSmallMultiplePanel(
                    displayedSeries[index],
                    _smallMultipleDescriptions[index],
                    showLocalLegend: !_useSharedDomain,
                  ),
              ];
              if (constraints.maxWidth >= 860) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < panels.length; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(child: panels[index]),
                    ],
                  ],
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: panels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => SizedBox(
                  width: constraints.maxWidth.clamp(280, 360),
                  child: panels[index],
                ),
              );
            },
          ),
        ),
        if (_useSharedDomain && _showColorLegend) ...[
          const SizedBox(height: 10),
          HeatmapColorLegend(
            key: const ValueKey('heatmap-shared-domain-legend'),
            series: displayedSeries.first,
            rampExtent: 280,
            onValueFilterChanged: _updateSmallMultipleValueFilter,
          ),
        ],
      ],
    );
  }

  Widget _buildSmallMultiplePanel(
    HeatmapChartSeries series,
    String description, {
    required bool showLocalLegend,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.name ?? series.id,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildSmallMultipleChart(series)),
            if (showLocalLegend && _showColorLegend) ...[
              const SizedBox(height: 5),
              HeatmapColorLegend(
                series: series,
                rampExtent: 130,
                rampThickness: 8,
                showTitle: false,
                textStyle: theme.textTheme.labelSmall,
                onValueFilterChanged: _updateSmallMultipleValueFilter,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateSmallMultipleValueFilter(HeatmapValueFilter? filter) {
    setState(() {
      _smallMultipleValueFilter = filter?.copyWith(
        mode: _smallMultipleFilterMode,
        excludedOpacity: _smallMultipleExcludedOpacity,
      );
    });
  }

  Widget _buildSmallMultipleChart(HeatmapChartSeries series) {
    return BravenChartPlus(
      key: ValueKey('heatmap-small-multiple-${series.id}'),
      series: [series],
      showLegend: false,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: const XAxisConfig(
        categoryAxis: CategoryAxisConfig(
          categories: ['00', '06', '12', '18', '24'],
          minimumCategoryExtent: 34,
        ),
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        categoryAxis: const CategoryAxisConfig(
          categories: ['Mon', 'Tue', 'Wed', 'Thu'],
          minimumCategoryExtent: 28,
          maximumLabelExtent: 34,
        ),
      ),
      interactionConfig: const InteractionConfig(
        tooltip: TooltipConfig(enabled: true),
        enableZoom: false,
        enablePan: false,
      ),
    );
  }

  List<HeatmapChartSeries> get _smallMultipleSourceSeries {
    const panelValues = <List<List<double>>>[
      [
        [12, 18, 31, 38, 24],
        [10, 16, 34, 42, 29],
        [14, 21, 36, 45, 30],
        [11, 19, 32, 40, 26],
      ],
      [
        [28, 35, 48, 62, 44],
        [31, 39, 54, 68, 49],
        [26, 37, 51, 64, 46],
        [33, 42, 57, 66, 52],
      ],
      [
        [52, 61, 76, 89, 70],
        [57, 65, 82, 96, 78],
        [49, 59, 74, 91, 72],
        [55, 67, 80, 94, 75],
      ],
    ];
    const names = ['Checkout', 'Search', 'Reporting'];
    return [
      for (var panel = 0; panel < panelValues.length; panel++)
        HeatmapChartSeries(
          id: 'latency-${names[panel].toLowerCase()}',
          name: names[panel],
          unit: 'ms',
          points: [
            for (var row = 0; row < panelValues[panel].length; row++)
              for (
                var column = 0;
                column < panelValues[panel][row].length;
                column++
              )
                HeatmapDataPoint(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  value: panelValues[panel][row][column],
                  pointKey: 'latency-$panel-$row-$column',
                  label:
                      '${names[panel]} · ${panelValues[panel][row][column]} ms',
                ),
          ],
          colorScale: HeatmapColorScale.sequential(
            colors: _sequentialColors,
            reverse: _reverseScale,
            clamp: _clampScale,
            missingColor: _missingColor,
            label: 'Response latency',
            unit: 'ms',
            showLegend: _showColorLegend,
          ),
          showCellLabels: _showValues,
          cellLabelFontSize: 9.5,
          gapFraction: _gapFraction,
          cornerRadius: _cornerRadius,
          borderColor: const Color(0x33FFFFFF),
          borderWidth: 0.7,
          animation: const HeatmapAnimationStyle(
            entranceMode: HeatmapEntranceMode.scale,
            entranceOrder: HeatmapEntranceOrder.row,
          ),
        ),
    ];
  }

  static const _smallMultipleDescriptions = [
    'Fast local range',
    'Typical service range',
    'High-latency service',
  ];

  Widget _buildClusteredComposition(Widget chart) {
    final rowData = _rowDendrogramData;
    final columnData = _columnDendrogramData;
    final theme = Theme.of(context);
    final dendrogramStyle = _dendrogramStyle;
    final showsRows = _showRowDendrogram && rowData != null;
    final showsColumns = _showColumnDendrogram && columnData != null;
    final leadingWidth =
        (showsRows ? _dendrogramExtent : 0.0) + _clusterRowLabelWidth;

    return Column(
      key: const ValueKey('heatmap-clustered-composition'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showsColumns)
          SizedBox(
            key: const ValueKey('heatmap-column-dendrogram'),
            height: _dendrogramExtent + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: leadingWidth),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: _clusterPlotInsets.left,
                      right: _clusterPlotInsets.right,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Row(
                            children: [
                              Text(
                                'Column hierarchy',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dendrogramDistanceScale ==
                                          HeatmapDendrogramDistanceScale
                                              .structural
                                      ? 'Readable spacing · similar near matrix'
                                      : 'Proportional distance · similar near matrix',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: HeatmapDendrogram(
                            data: columnData,
                            style: dendrogramStyle,
                            padding: const EdgeInsets.only(top: 4),
                            interactionState: _columnDendrogramInteraction,
                            onInteractionStateChanged:
                                _enableDendrogramInteraction
                                ? (value) => setState(() {
                                    _columnDendrogramInteraction = value;
                                    if (value.selectedTarget != null) {
                                      _rowDendrogramInteraction =
                                          _rowDendrogramInteraction
                                              .withSelectedTarget(null);
                                    }
                                  })
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showsRows)
                SizedBox(
                  key: const ValueKey('heatmap-row-dendrogram'),
                  width: _dendrogramExtent,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: _clusterPlotInsets.top,
                      bottom: _clusterPlotInsets.bottom,
                    ),
                    child: HeatmapDendrogram(
                      data: rowData,
                      style: dendrogramStyle,
                      interactionState: _rowDendrogramInteraction,
                      onInteractionStateChanged: _enableDendrogramInteraction
                          ? (value) => setState(() {
                              _rowDendrogramInteraction = value;
                              if (value.selectedTarget != null) {
                                _columnDendrogramInteraction =
                                    _columnDendrogramInteraction
                                        .withSelectedTarget(null);
                              }
                            })
                          : null,
                    ),
                  ),
                ),
              SizedBox(
                key: const ValueKey('heatmap-cluster-row-labels'),
                width: _clusterRowLabelWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _clusterPlotInsets.top,
                    bottom: _clusterPlotInsets.bottom,
                  ),
                  child: _ClusterRowLabels(
                    labels: _rowLabels,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(child: chart),
            ],
          ),
        ),
        SizedBox(
          key: const ValueKey('heatmap-cluster-column-labels'),
          height: _clusterColumnLabelHeight,
          child: Row(
            children: [
              SizedBox(width: leadingWidth),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: _clusterPlotInsets.left,
                    right: _clusterPlotInsets.right,
                  ),
                  child: _ClusterColumnLabels(
                    labels: _columnLabels,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _clusterXAxisTitleHeight,
          child: Padding(
            padding: EdgeInsets.only(left: leadingWidth),
            child: Text(
              _xAxisLabel,
              key: const ValueKey('heatmap-cluster-x-axis-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _clusterHierarchyIsVisible {
    if (_preset != _HeatmapPreset.clustered) return false;
    return (_showRowDendrogram && _rowDendrogramData != null) ||
        (_showColumnDendrogram && _columnDendrogramData != null);
  }

  void _clearDendrogramInteraction() {
    _rowDendrogramInteraction = const HeatmapDendrogramInteractionState();
    _columnDendrogramInteraction = const HeatmapDendrogramInteractionState();
  }

  void _clearClusterProjection() {
    _rowHierarchyCollapse = const HeatmapHierarchyCollapseState.empty();
    _columnHierarchyCollapse = const HeatmapHierarchyCollapseState.empty();
    _clearDendrogramInteraction();
  }

  bool get _hasCollapsedHierarchyGroups =>
      _rowHierarchyCollapse.collapsedNodeIds.isNotEmpty ||
      _columnHierarchyCollapse.collapsedNodeIds.isNotEmpty;

  HeatmapDendrogramTargetIdentity? get _selectedHierarchyTarget =>
      _rowDendrogramInteraction.selectedTarget ??
      _columnDendrogramInteraction.selectedTarget;

  HeatmapDendrogramTargetIdentity? get _selectedCollapsibleHierarchyTarget {
    final target = _selectedHierarchyTarget;
    if (target == null ||
        _collapseStateFor(target.axis).isCollapsed(target.nodeId)) {
      return null;
    }
    final node = _hierarchyNodeFor(target.axis, target.nodeId);
    return node == null || node.isLeaf ? null : target;
  }

  HeatmapDendrogramTargetIdentity? get _selectedCollapsedHierarchyTarget {
    final target = _selectedHierarchyTarget;
    return target != null &&
            _collapseStateFor(target.axis).isCollapsed(target.nodeId)
        ? target
        : null;
  }

  HeatmapHierarchyCollapseState _collapseStateFor(HeatmapDendrogramAxis axis) =>
      axis == HeatmapDendrogramAxis.rows
      ? _rowHierarchyCollapse
      : _columnHierarchyCollapse;

  HeatmapClusterNode? _hierarchyNodeFor(
    HeatmapDendrogramAxis axis,
    String nodeId,
  ) {
    final focused = _focusedClusterData;
    final root = axis == HeatmapDendrogramAxis.rows
        ? focused.rowRoot
        : focused.columnRoot;
    return _findHierarchyNode(root, nodeId);
  }

  HeatmapClusterNode? _findHierarchyNode(
    HeatmapClusterNode? node,
    String nodeId,
  ) {
    if (node == null) return null;
    if (node.id == nodeId) return node;
    return _findHierarchyNode(node.left, nodeId) ??
        _findHierarchyNode(node.right, nodeId);
  }

  void _collapseHierarchyTarget(HeatmapDendrogramTargetIdentity target) {
    if (target.axis == HeatmapDendrogramAxis.rows) {
      _rowHierarchyCollapse = _rowHierarchyCollapse.collapse(target.nodeId);
    } else {
      _columnHierarchyCollapse = _columnHierarchyCollapse.collapse(
        target.nodeId,
      );
    }
    _clearDendrogramInteraction();
  }

  void _expandHierarchyTarget(HeatmapDendrogramTargetIdentity target) {
    if (target.axis == HeatmapDendrogramAxis.rows) {
      _rowHierarchyCollapse = _rowHierarchyCollapse.expand(target.nodeId);
    } else {
      _columnHierarchyCollapse = _columnHierarchyCollapse.expand(target.nodeId);
    }
    _clearDendrogramInteraction();
  }

  Widget _buildPresetPicker() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a heatmap example',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice(
                  _HeatmapPreset.activity,
                  'Activity matrix',
                  Icons.calendar_view_week_outlined,
                ),
                _choice(
                  _HeatmapPreset.selection,
                  'Matrix selection',
                  Icons.select_all_outlined,
                ),
                _choice(
                  _HeatmapPreset.irregular,
                  'Irregular cells',
                  Icons.view_timeline_outlined,
                ),
                _choice(
                  _HeatmapPreset.temperature,
                  'Temperature',
                  Icons.thermostat_outlined,
                ),
                _choice(
                  _HeatmapPreset.threshold,
                  'Service health',
                  Icons.monitor_heart_outlined,
                ),
                _choice(
                  _HeatmapPreset.calendar,
                  'Calendar month',
                  Icons.calendar_month_outlined,
                ),
                _choice(
                  _HeatmapPreset.contributions,
                  'Contribution calendar',
                  Icons.grid_view_outlined,
                ),
                _choice(
                  _HeatmapPreset.correlation,
                  'Correlation',
                  Icons.hub_outlined,
                ),
                _choice(
                  _HeatmapPreset.histogram,
                  '2D histogram',
                  Icons.scatter_plot_outlined,
                ),
                _choice(
                  _HeatmapPreset.density,
                  'Density raster',
                  Icons.blur_circular_outlined,
                ),
                _choice(
                  _HeatmapPreset.contours,
                  'Density contours',
                  Icons.multiline_chart_outlined,
                ),
                _choice(
                  _HeatmapPreset.clustered,
                  'Clustered matrix',
                  Icons.account_tree_outlined,
                ),
                _choice(
                  _HeatmapPreset.colourAxes,
                  'Colour axes',
                  Icons.gradient_outlined,
                ),
                _choice(
                  _HeatmapPreset.smallMultiples,
                  'Small multiples',
                  Icons.view_column_outlined,
                ),
                _choice(
                  _HeatmapPreset.dense,
                  'Dense viewport',
                  Icons.blur_on_outlined,
                ),
                _choice(
                  _HeatmapPreset.viewportSource,
                  'Massive matrix',
                  Icons.dataset_outlined,
                ),
                _choice(
                  _HeatmapPreset.rasterTiles,
                  'Raster tiles',
                  Icons.image_outlined,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              switch (_preset) {
                _HeatmapPreset.activity =>
                  'A sequential scale reveals the busiest weekday and hour combinations.',
                _HeatmapPreset.selection =>
                  'One persistent rectangle can select touched cells or expand them to complete source rows and columns.',
                _HeatmapPreset.irregular =>
                  'Explicit X and Y bounds preserve unequal interval duration and lane height without changing the regular-grid fast path.',
                _HeatmapPreset.temperature =>
                  'A diverging scale keeps the comfort midpoint semantically stable.',
                _HeatmapPreset.threshold =>
                  'Discrete thresholds turn operational values into named status bands.',
                _HeatmapPreset.calendar =>
                  'Explicit missing cells preserve the shape of an incomplete calendar month.',
                _HeatmapPreset.contributions =>
                  'Zero-contribution days remain real, selectable cells with an independent empty-value style.',
                _HeatmapPreset.correlation =>
                  'A square diverging matrix exposes positive and negative relationships around zero.',
                _HeatmapPreset.histogram =>
                  'Typed binning turns raw paired observations into a canonical, inspectable Heatmap.',
                _HeatmapPreset.density =>
                  'A typed kernel transform turns raw weighted observations into a smooth, provenance-aware raster.',
                _HeatmapPreset.contours =>
                  'Marching Squares converts the same density grid into portable, provenance-aware line overlays.',
                _HeatmapPreset.clustered =>
                  'Deterministic row and column clustering reveals related product signals while preserving source identity.',
                _HeatmapPreset.colourAxes =>
                  'Two Heatmap series retain independent units, domains, palettes, filters, and Workbench identity in one Cartesian chart.',
                _HeatmapPreset.smallMultiples =>
                  'Independent panels can share one portable colour domain and one honest legend.',
                _HeatmapPreset.dense =>
                  'A 30,000-cell sparse field paints and hits only the visible viewport.',
                _HeatmapPreset.viewportSource =>
                  'A host-owned async tile source keeps a 24-million-cell matrix bounded to the current resident viewport.',
                _HeatmapPreset.rasterTiles =>
                  'A massive spectrogram stays bounded to decoded image tiles for the current Cartesian viewport.',
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(_HeatmapPreset preset, String label, IconData icon) {
    return ChoiceChip(
      key: ValueKey<String>('heatmap-preset-${preset.name}'),
      selected: _preset == preset,
      onSelected: (_) {
        _clearMatrixSelection();
        if (preset != _HeatmapPreset.viewportSource) {
          _stopViewportMutationStream();
        }
        if (preset == _HeatmapPreset.viewportSource) {
          _ensureViewportSource();
        } else if (preset == _HeatmapPreset.rasterTiles) {
          _ensureRasterSource();
        }
        setState(() {
          _preset = preset;
          _domainPadding = 0;
          _midpointOffset = 0;
          _dataRevision = 0;
          _showValues =
              preset != _HeatmapPreset.density &&
              preset != _HeatmapPreset.contours &&
              preset != _HeatmapPreset.dense &&
              preset != _HeatmapPreset.viewportSource &&
              preset != _HeatmapPreset.rasterTiles &&
              preset != _HeatmapPreset.contributions;
          if (preset == _HeatmapPreset.contributions) {
            _palette = _HeatmapPalette.forest;
          }
        });
      },
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  String _selectionExpansionLabel(HeatmapSelectionExpansion value) =>
      switch (value) {
        HeatmapSelectionExpansion.cell => 'Touched cells',
        HeatmapSelectionExpansion.row => 'Whole source rows',
        HeatmapSelectionExpansion.column => 'Whole source columns',
      };

  void _clearMatrixSelection() {
    _chartController
      ..clearSelection()
      ..clearSelectionBrush();
  }

  Widget _slider({
    Key? key,
    required String label,
    required double value,
    required double minimum,
    required double maximum,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value.toStringAsFixed(value < 1 ? 2 : 0)),
            ],
          ),
        ),
        Slider(
          value: value,
          min: minimum,
          max: maximum,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  HeatmapChartSeries get _series {
    if (_preset == _HeatmapPreset.viewportSource) {
      final template = HeatmapChartSeries(
        id: 'heatmap-viewport-source',
        name: 'Massive signal matrix',
        points: const [],
        colorScale: _scale,
        unit: '%',
        showCellLabels: false,
        gapFraction: _gapFraction,
        cornerRadius: _cornerRadius,
        // The configured gap already separates the thousands of resident
        // cells. Avoid adding an equivalent stroked RRect path to the dense
        // viewport's retained GPU picture.
        borderColor: Colors.transparent,
        borderWidth: 0,
        metadata: const {
          'sourceMode': 'viewport-backed',
          'snapshotSemantics': 'resident-cells-only',
          'conceptualCellCount': 24000000,
        },
        animation: const HeatmapAnimationStyle(
          entranceMode: HeatmapEntranceMode.none,
          animateDataUpdates: false,
        ),
      );
      return _viewportController?.snapshot.materializeSeries(template) ??
          template;
    }
    return HeatmapChartSeries(
      id: 'heatmap-${_preset.name}',
      name: _title,
      points: _points,
      colorScale: _scale,
      unit: _unit,
      showCellLabels:
          _showValues &&
          _preset != _HeatmapPreset.contours &&
          _preset != _HeatmapPreset.dense,
      cellLabelFontSize: 10.5,
      gapFraction: _gapFraction,
      cornerRadius: _cornerRadius,
      borderColor: const Color(0x33FFFFFF),
      borderWidth: 0.7,
      emptyValueStyle:
          _preset == _HeatmapPreset.contributions && _styleEmptyValues
          ? HeatmapEmptyValueStyle(
              fillColor: _emptyValueColor,
              borderColor: _emptyValueBorderColor,
              borderWidth: _emptyValueBorderWidth,
              showLabel: _showEmptyValueLabels,
              showInLegend: _showEmptyValueLegend,
              legendLabel: 'No contributions',
            )
          : null,
      metadata: _preset == _HeatmapPreset.clustered
          ? {
              ..._clusterData.metadata,
              ..._focusedClusterData.metadata,
              ..._clusterHierarchyProjection.metadata,
              ...?_rowDendrogramData?.metadata,
              ...?_columnDendrogramData?.metadata,
              ..._dendrogramStyleMetadata,
            }
          : null,
      animation: HeatmapAnimationStyle(
        entranceMode: switch (_motion) {
          _HeatmapMotion.fade => HeatmapEntranceMode.fade,
          _HeatmapMotion.scale => HeatmapEntranceMode.scale,
          _HeatmapMotion.none => HeatmapEntranceMode.none,
        },
        entranceOrder: _entranceOrder,
        animateDataUpdates: _animateUpdates,
      ),
    );
  }

  List<HeatmapChartSeries> get _colourAxisSeries {
    const latencyValues = [42.0, 58, 91, 74, 63, 47];
    const errorRateValues = [0.4, 0.9, 2.8, 1.7, 1.2, 0.6];
    final animation = HeatmapAnimationStyle(
      entranceMode: switch (_motion) {
        _HeatmapMotion.fade => HeatmapEntranceMode.fade,
        _HeatmapMotion.scale => HeatmapEntranceMode.scale,
        _HeatmapMotion.none => HeatmapEntranceMode.none,
      },
      entranceOrder: _entranceOrder,
      animateDataUpdates: _animateUpdates,
    );
    return [
      HeatmapChartSeries(
        id: 'latency-axis',
        name: 'Latency',
        unit: 'ms',
        points: [
          for (var column = 0; column < latencyValues.length; column++)
            HeatmapDataPoint(
              x: column.toDouble(),
              y: 1,
              value: latencyValues[column] + _dataRevision * (column + 1),
              pointKey: 'latency-$column',
              label: '${_columnLabels[column]} latency',
            ),
        ],
        colorScale: HeatmapColorScale.sequential(
          colors: const [
            Color(0xFFE0F2FE),
            Color(0xFF38BDF8),
            Color(0xFF0369A1),
          ],
          minimumValue: 35,
          maximumValue: 100,
          label: 'Response latency',
          unit: 'ms',
          showLegend: _showColorLegend && _showLatencyColorAxis,
        ),
        valueFilter: _latencyValueFilter,
        showCellLabels: _showValues,
        cellLabelFontSize: 10.5,
        gapFraction: _gapFraction,
        cornerRadius: _cornerRadius,
        borderColor: const Color(0x55FFFFFF),
        borderWidth: 0.8,
        animation: animation,
      ),
      HeatmapChartSeries(
        id: 'error-rate-axis',
        name: 'Error rate',
        unit: '%',
        points: [
          for (var column = 0; column < errorRateValues.length; column++)
            HeatmapDataPoint(
              x: column.toDouble(),
              y: 0,
              value:
                  errorRateValues[column] + _dataRevision * 0.05 * (column + 1),
              pointKey: 'error-rate-$column',
              label: '${_columnLabels[column]} error rate',
            ),
        ],
        colorScale: HeatmapColorScale.sequential(
          colors: const [
            Color(0xFFFFF7ED),
            Color(0xFFFB923C),
            Color(0xFFC2410C),
          ],
          minimumValue: 0,
          maximumValue: 3,
          label: 'Error rate',
          unit: '%',
          showLegend: _showColorLegend && _showErrorRateColorAxis,
        ),
        valueFilter: _errorRateValueFilter,
        showCellLabels: _showValues,
        cellLabelFontSize: 10.5,
        gapFraction: _gapFraction,
        cornerRadius: _cornerRadius,
        borderColor: const Color(0x55FFFFFF),
        borderWidth: 0.8,
        animation: animation,
      ),
    ];
  }

  List<ChartSeries> get _chartSeries => _preset == _HeatmapPreset.rasterTiles
      ? const []
      : _preset == _HeatmapPreset.colourAxes
      ? _colourAxisSeries
      : [
          _series,
          if (_preset == _HeatmapPreset.contours && _showContours)
            ..._contourSeries,
        ];

  List<LineChartSeries> get _contourSeries {
    final contourData = HeatmapContourData.fromDensity(
      _densityData,
      levels: _contourLevels,
    );
    const colors = [
      Color(0xFF0F172A),
      Color(0xFF7C3AED),
      Color(0xFFF97316),
      Color(0xFFE11D48),
      Color(0xFFF8FAFC),
    ];
    return [
      for (final path in contourData.paths)
        LineChartSeries(
          id: 'density-${path.id}',
          name: '${(path.level * 100).round()}% density',
          points: contourData.chartPointsFor(path),
          color:
              colors[path.levelIndex *
                  (colors.length - 1) ~/
                  (_contourLevels.length - 1)],
          interpolation: switch (_contourGeometry) {
            _ContourGeometry.exact => LineInterpolation.linear,
            _ContourGeometry.smooth => LineInterpolation.bezier,
          },
          tension: _contourTension,
          strokeWidth: _contourStrokeWidth,
          showDataPointMarkers: false,
          showInLegend: false,
          showTrackingAxisLabel: false,
          metadata: {
            'densityContourLevel': path.level,
            'densityContourPathId': path.id,
            'densityContourClosed': path.isClosed,
            'densityContourPresentation': _contourGeometry.name,
            'densityContourTension': _contourTension,
            'densityContourSourcePointKeys': path.sourcePointKeys,
          },
        ),
    ];
  }

  List<double> get _contourLevels => switch (_contourDetail) {
    _ContourDetail.coarse => const [0.25, 0.5, 0.75],
    _ContourDetail.detailed => const [0.15, 0.3, 0.45, 0.6, 0.75],
  };

  List<HeatmapDataPoint> get _points => [
    for (final cell in _basePoints)
      if (cell.isMissing)
        cell
      else if (_preset == _HeatmapPreset.contributions && cell.value == 0)
        cell
      else
        cell.copyWith(
          value:
              cell.value! +
              _dataRevision *
                  (1 + ((cell.x * 3 + cell.y * 5).round().abs() % 5)) *
                  _updateStep,
        ),
  ];

  HeatmapDensityData get _densityData => HeatmapDensityData(
    observations: _densityObservations,
    xAxis: _densityXAxis,
    yAxis: _densityYAxis,
    bandwidthX: _densityBandwidthX,
    bandwidthY: _densityBandwidthY,
    kernel: _densityKernel,
  );

  HeatmapClusterAxisMode get _effectiveClusterAxisMode =>
      _applyClusterOrder ? _clusterAxisMode : HeatmapClusterAxisMode.none;

  HeatmapMatrixClusterData get _clusterData => HeatmapMatrixClusterData(
    rowLabels: _clusterSourceRowLabels,
    columnLabels: _clusterSourceColumnLabels,
    cells: [
      for (var row = 0; row < _clusterSourceValues.length; row++)
        for (
          var column = 0;
          column < _clusterSourceValues[row].length;
          column++
        )
          if (_clusterSourceValues[row][column] == null)
            HeatmapDataPoint.missing(
              x: column.toDouble(),
              y: row.toDouble(),
              pointKey: 'clustered-$row-$column',
              label:
                  '${_clusterSourceRowLabels[row]} · '
                  '${_clusterSourceColumnLabels[column]} · not measured',
              metadata: const {'source': 'product-signal-audit'},
            )
          else
            HeatmapDataPoint(
              x: column.toDouble(),
              y: row.toDouble(),
              value: _clusterSourceValues[row][column]!,
              pointKey: 'clustered-$row-$column',
              label:
                  '${_clusterSourceRowLabels[row]} · '
                  '${_clusterSourceColumnLabels[column]}',
              metadata: const {'source': 'product-signal-audit'},
            ),
    ],
    config: HeatmapClusterConfig(
      axisMode: _effectiveClusterAxisMode,
      distance: _clusterDistance,
      linkage: _clusterLinkage,
      missingValueMode: _clusterMissingValueMode,
    ),
  );

  HeatmapMatrixClusterFocusData get _focusedClusterData {
    final source = _clusterData;
    if (!_applyClusterOrder || _clusterFocus == _ClusterFocus.full) {
      return HeatmapMatrixClusterFocusData(source: source);
    }
    return HeatmapMatrixClusterFocusData(
      source: source,
      rowRootId: _focusedRootId(source.rowRoot),
      columnRootId: _focusedRootId(source.columnRoot),
    );
  }

  String? _focusedRootId(HeatmapClusterNode? root) {
    if (root == null) return null;
    return switch (_clusterFocus) {
      _ClusterFocus.full => null,
      _ClusterFocus.primary => (root.left ?? root).id,
      _ClusterFocus.secondary => (root.right ?? root).id,
    };
  }

  HeatmapDendrogramData? get _rowDendrogramData {
    final focused = _focusedClusterData;
    final root = focused.rowRoot;
    if (root == null) return null;
    return HeatmapDendrogramData(
      root: root,
      sourceLabels: focused.source.sourceRowLabels,
      axis: HeatmapDendrogramAxis.rows,
      distanceScale: _dendrogramDistanceScale,
      collapseState: _rowHierarchyCollapse,
    );
  }

  HeatmapDendrogramData? get _columnDendrogramData {
    final focused = _focusedClusterData;
    final root = focused.columnRoot;
    if (root == null) return null;
    return HeatmapDendrogramData(
      root: root,
      sourceLabels: focused.source.sourceColumnLabels,
      axis: HeatmapDendrogramAxis.columns,
      distanceScale: _dendrogramDistanceScale,
      collapseState: _columnHierarchyCollapse,
    );
  }

  HeatmapHierarchyMatrixProjection get _clusterHierarchyProjection =>
      HeatmapHierarchyMatrixProjection(
        source: _focusedClusterData,
        rowCollapseState: _rowHierarchyCollapse,
        columnCollapseState: _columnHierarchyCollapse,
        reducer: _hierarchyReducer,
      );

  HeatmapDendrogramStyle get _dendrogramStyle => HeatmapDendrogramStyle(
    branchColor: _dendrogramBranchColor,
    branchWidth: _dendrogramStrokeWidth,
    branchCap: _dendrogramBranchCap,
    branchJoin: _dendrogramBranchJoin,
    baselineColor: _dendrogramBaselineColor,
    baselineWidth: _dendrogramBaselineWidth,
    showLeafBaseline: _showDendrogramBaseline,
    tickColor: _dendrogramTickColor,
    tickWidth: _dendrogramTickWidth,
    tickLength: _dendrogramTickLength,
    showLeafTicks: _showDendrogramTicks,
    elbowRadius: _dendrogramElbowRadius,
    showLeafMarkers: _showDendrogramLeafMarkers,
    leafMarkerColor: _dendrogramLeafMarkerColor,
    leafMarkerRadius: _dendrogramLeafMarkerRadius,
    leafMarkerShape: _dendrogramLeafMarkerShape,
    leafMarkerFill: _dendrogramLeafMarkerFill,
    leafMarkerBorderColor: _dendrogramLeafMarkerBorderColor,
    leafMarkerBorderWidth: _dendrogramLeafMarkerBorderWidth,
    showMergeMarkers: _showDendrogramMergeMarkers,
    mergeMarkerColor: _dendrogramMergeMarkerColor,
    mergeMarkerRadius: _dendrogramMergeMarkerRadius,
    mergeMarkerShape: _dendrogramMergeMarkerShape,
    mergeMarkerFill: _dendrogramMergeMarkerFill,
    mergeMarkerBorderColor: _dendrogramMergeMarkerBorderColor,
    mergeMarkerBorderWidth: _dendrogramMergeMarkerBorderWidth,
    showLeafLabels: _showDendrogramLeafLabels,
    showMergeDistanceLabels: _showDendrogramMergeLabels,
    labelColor: _dendrogramLabelColor,
    labelBackgroundColor: _dendrogramLabelBackgroundColor,
    labelFontSize: _dendrogramLabelFontSize,
    labelDensity: _dendrogramLabelDensity,
    labelPlacement: _dendrogramLabelPlacement,
    maxLabelCharacters: _dendrogramMaxLabelCharacters.round(),
    mergeDistanceFractionDigits: _dendrogramMergeLabelDecimals.round(),
    levelOfDetailMode: _automaticDendrogramLevelOfDetail
        ? HeatmapDendrogramLevelOfDetailMode.automatic
        : HeatmapDendrogramLevelOfDetailMode.disabled,
    minimumBranchLength: _dendrogramMinimumBranchLength,
    minimumLeafGuideSpacing: _dendrogramMinimumLeafGuideSpacing,
    minimumLeafMarkerSpacing: _dendrogramMinimumLeafMarkerSpacing,
    minimumMergeMarkerSpacing: _dendrogramMinimumMergeMarkerSpacing,
    minimumLabelSpacing: _dendrogramMinimumLabelSpacing,
  );

  Map<String, dynamic> get _dendrogramStyleMetadata => {
    if (_rowDendrogramData != null)
      ..._dendrogramStyle.metadataFor(HeatmapDendrogramAxis.rows),
    if (_columnDendrogramData != null)
      ..._dendrogramStyle.metadataFor(HeatmapDendrogramAxis.columns),
  };

  List<HeatmapDataPoint> get _basePoints {
    if (_preset == _HeatmapPreset.histogram) {
      return _histogramData.cellsFor(
        emptyBinMode: HeatmapHistogramEmptyBinMode.zero,
      );
    }
    if (_preset == _HeatmapPreset.density ||
        _preset == _HeatmapPreset.contours) {
      return _densityData.cellsFor();
    }
    if (_preset == _HeatmapPreset.dense) {
      return [
        for (var row = 0; row < 120; row++)
          for (var column = 0; column < 250; column++)
            if ((row * 17 + column * 31) % 29 != 0)
              HeatmapDataPoint(
                x: column.toDouble(),
                y: row.toDouble(),
                value:
                    50 +
                    34 *
                        (0.58 * _wave(column / 13) +
                            0.42 * _wave((row + column) / 19)),
                pointKey: 'dense-$row-$column',
                label: 'Channel $row · sample $column',
              ),
      ];
    }
    if (_preset == _HeatmapPreset.clustered) {
      return _clusterHierarchyProjection.cells;
    }
    if (_preset == _HeatmapPreset.irregular) {
      const intervals =
          <
            ({
              String lane,
              double y,
              double yMinimum,
              double yMaximum,
              double xMinimum,
              double xMaximum,
              double value,
            })
          >[
            (
              lane: 'Ingest',
              y: 0,
              yMinimum: -0.38,
              yMaximum: 0.38,
              xMinimum: 0,
              xMaximum: 2.4,
              value: 36,
            ),
            (
              lane: 'Ingest',
              y: 0,
              yMinimum: -0.38,
              yMaximum: 0.38,
              xMinimum: 2.65,
              xMaximum: 6.1,
              value: 74,
            ),
            (
              lane: 'Ingest',
              y: 0,
              yMinimum: -0.38,
              yMaximum: 0.38,
              xMinimum: 6.35,
              xMaximum: 11.6,
              value: 58,
            ),
            (
              lane: 'Transform',
              y: 1,
              yMinimum: 0.52,
              yMaximum: 1.48,
              xMinimum: 0.4,
              xMaximum: 3.2,
              value: 48,
            ),
            (
              lane: 'Transform',
              y: 1,
              yMinimum: 0.52,
              yMaximum: 1.48,
              xMinimum: 3.45,
              xMaximum: 8.4,
              value: 92,
            ),
            (
              lane: 'Transform',
              y: 1,
              yMinimum: 0.52,
              yMaximum: 1.48,
              xMinimum: 8.65,
              xMaximum: 11.2,
              value: 66,
            ),
            (
              lane: 'Score',
              y: 2,
              yMinimum: 1.68,
              yMaximum: 2.32,
              xMinimum: 1.1,
              xMaximum: 4.8,
              value: 42,
            ),
            (
              lane: 'Score',
              y: 2,
              yMinimum: 1.68,
              yMaximum: 2.32,
              xMinimum: 5.05,
              xMaximum: 7.15,
              value: 81,
            ),
            (
              lane: 'Score',
              y: 2,
              yMinimum: 1.68,
              yMaximum: 2.32,
              xMinimum: 7.4,
              xMaximum: 11.8,
              value: 63,
            ),
            (
              lane: 'Publish',
              y: 3,
              yMinimum: 2.58,
              yMaximum: 3.42,
              xMinimum: 0.2,
              xMaximum: 1.55,
              value: 28,
            ),
            (
              lane: 'Publish',
              y: 3,
              yMinimum: 2.58,
              yMaximum: 3.42,
              xMinimum: 1.8,
              xMaximum: 6.8,
              value: 69,
            ),
            (
              lane: 'Publish',
              y: 3,
              yMinimum: 2.58,
              yMaximum: 3.42,
              xMinimum: 7.1,
              xMaximum: 11.9,
              value: 97,
            ),
          ];
      return [
        for (final (index, interval) in intervals.indexed)
          HeatmapDataPoint(
            x: (interval.xMinimum + interval.xMaximum) / 2,
            y: interval.y,
            value: interval.value,
            pointKey: 'irregular-${interval.lane.toLowerCase()}-$index',
            label:
                '${interval.lane} · ${interval.xMinimum.toStringAsFixed(1)}–${interval.xMaximum.toStringAsFixed(1)} h',
            bounds: HeatmapCellBounds(
              xMinimum: interval.xMinimum,
              xMaximum: interval.xMaximum,
              yMinimum: interval.yMinimum,
              yMaximum: interval.yMaximum,
            ),
          ),
      ];
    }
    if (_preset == _HeatmapPreset.calendar) {
      const values = <double?>[
        null,
        null,
        18,
        19,
        21,
        23,
        24,
        22,
        20,
        18,
        17,
        19,
        22,
        25,
        27,
        28,
        24,
        21,
        20,
        18,
        17,
        16,
        18,
        21,
        23,
        22,
        20,
        19,
        17,
        16,
        15,
        null,
        null,
        null,
        null,
      ];
      return [
        for (var index = 0; index < values.length; index++)
          if (values[index] == null)
            HeatmapDataPoint.missing(
              x: (index % 7).toDouble(),
              y: (index ~/ 7).toDouble(),
              pointKey: 'calendar-$index',
              label: 'Outside July',
            )
          else
            HeatmapDataPoint(
              x: (index % 7).toDouble(),
              y: (index ~/ 7).toDouble(),
              value: values[index]!,
              pointKey: 'calendar-$index',
              label: 'July ${index - 1} · ${values[index]!.toInt()} °C',
            ),
      ];
    }
    if (_preset == _HeatmapPreset.contributions) {
      return [
        for (var week = 0; week < 24; week++)
          for (var day = 0; day < 7; day++)
            HeatmapDataPoint(
              x: week.toDouble(),
              y: day.toDouble(),
              value: _contributionValue(week, day),
              pointKey: 'contribution-$week-$day',
              label:
                  'Week ${week + 1} · ${_rowLabels[day]} · '
                  '${_contributionValue(week, day).toInt()} contributions',
            ),
      ];
    }
    if (_preset == _HeatmapPreset.correlation) {
      const values = [
        [1.0, 0.82, 0.44, -0.28, -0.61, 0.18],
        [0.82, 1.0, 0.56, -0.12, -0.48, 0.34],
        [0.44, 0.56, 1.0, 0.26, -0.22, 0.71],
        [-0.28, -0.12, 0.26, 1.0, 0.63, 0.39],
        [-0.61, -0.48, -0.22, 0.63, 1.0, 0.11],
        [0.18, 0.34, 0.71, 0.39, 0.11, 1.0],
      ];
      return [
        for (var row = 0; row < values.length; row++)
          for (var column = 0; column < values[row].length; column++)
            HeatmapDataPoint(
              x: column.toDouble(),
              y: row.toDouble(),
              value: values[row][column],
              pointKey: 'correlation-$row-$column',
              label: '${_rowLabels[row]} × ${_columnLabels[column]}',
            ),
      ];
    }
    final values = switch (_preset) {
      _HeatmapPreset.activity || _HeatmapPreset.selection => const [
        [18.0, 22, 35, 48, 72, 54, 31, 26, 20, 14, 9, 6],
        [16.0, 27, 42, 61, 84, 69, 50, 44, 33, 19, 12, 8],
        [12.0, 21, 38, 57, 76, 91, 67, 53, 37, 24, 15, 10],
        [14.0, 25, 46, 73, 96, 88, 71, 59, 41, 29, 18, 11],
        [20.0, 31, 51, 79, 100, 94, 78, 62, 45, 32, 22, 15],
        [28.0, 36, 49, 63, 82, 76, 66, 58, 47, 38, 30, 24],
        [24.0, 29, 37, 45, 58, 55, 49, 43, 36, 30, 26, 21],
      ],
      _HeatmapPreset.temperature => const [
        [12.0, 11, 10, 11, 13, 16, 19, 22, 24, 23, 19, 15],
        [11.0, 10, 9, 10, 12, 15, 18, 21, 23, 22, 18, 14],
        [9.0, 8, 8, 9, 11, 14, 18, 22, 26, 25, 20, 15],
        [10.0, 9, 9, 10, 13, 17, 21, 25, 28, 27, 22, 17],
        [13.0, 12, 11, 12, 14, 18, 22, 26, 29, 28, 23, 18],
        [14.0, 13, 12, 13, 15, 19, 23, 27, 30, 29, 24, 19],
        [12.0, 11, 10, 11, 14, 18, 22, 25, 27, 26, 22, 17],
      ],
      _HeatmapPreset.threshold => const [
        [99.9, 99.8, 99.7, 99.4, 99.2, 99.8, 99.9, 100, 99.7, 99.8, 99.9, 100],
        [
          99.8,
          99.5,
          98.8,
          97.9,
          96.7,
          98.4,
          99.3,
          99.7,
          99.8,
          99.9,
          99.7,
          99.8,
        ],
        [
          99.9,
          99.7,
          99.6,
          99.1,
          98.9,
          99.2,
          99.5,
          99.8,
          99.9,
          99.7,
          99.8,
          99.9,
        ],
        [
          100.0,
          99.9,
          99.8,
          99.7,
          99.5,
          99.6,
          99.8,
          99.9,
          100,
          99.9,
          99.8,
          99.9,
        ],
      ],
      _HeatmapPreset.calendar ||
      _HeatmapPreset.contributions ||
      _HeatmapPreset.correlation ||
      _HeatmapPreset.irregular => const <List<double>>[],
      _HeatmapPreset.histogram => const <List<double>>[],
      _HeatmapPreset.density => const <List<double>>[],
      _HeatmapPreset.contours => const <List<double>>[],
      _HeatmapPreset.clustered => const <List<double>>[],
      _HeatmapPreset.colourAxes => const <List<double>>[],
      _HeatmapPreset.smallMultiples => const <List<double>>[],
      _HeatmapPreset.dense => const <List<double>>[],
      _HeatmapPreset.viewportSource => const <List<double>>[],
      _HeatmapPreset.rasterTiles => const <List<double>>[],
    };
    return [
      for (var row = 0; row < values.length; row++)
        for (var column = 0; column < values[row].length; column++)
          HeatmapDataPoint(
            x: column.toDouble(),
            y: row.toDouble(),
            value: values[row][column].toDouble(),
            pointKey: '${_preset.name}-$row-$column',
            label: '${_rowLabels[row]} · ${_columnLabels[column]}',
          ),
    ];
  }

  List<ChartAnnotation> get _annotations => switch (_preset) {
    _HeatmapPreset.activity => [
      RangeAnnotation(
        id: 'working-hours',
        startX: 3.5,
        endX: 8.5,
        startY: -0.45,
        endY: 6.45,
        label: 'Working hours',
        fillColor: const Color(0x0F2563EB),
        borderColor: const Color(0x662563EB),
      ),
    ],
    _HeatmapPreset.threshold => [
      RangeAnnotation(
        id: 'incident-window',
        startX: 2.5,
        endX: 5.5,
        startY: -0.45,
        endY: 3.45,
        label: 'Incident window',
        fillColor: const Color(0x12DC2626),
        borderColor: const Color(0x66DC2626),
      ),
    ],
    _ => const <ChartAnnotation>[],
  };

  double get _updateStep => switch (_preset) {
    _HeatmapPreset.histogram ||
    _HeatmapPreset.density ||
    _HeatmapPreset.contours => 0,
    _HeatmapPreset.clustered => 0,
    _HeatmapPreset.correlation => 0.015,
    _HeatmapPreset.threshold => 0.02,
    _HeatmapPreset.temperature || _HeatmapPreset.calendar => 0.25,
    _HeatmapPreset.irregular => 1,
    _HeatmapPreset.contributions => 1,
    _ => 0.8,
  };

  HeatmapColorScale get _scale => switch (_preset) {
    _HeatmapPreset.activity ||
    _HeatmapPreset.selection => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0 - _domainPadding,
      maximumValue: 100 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Activity',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.irregular => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 20 - _domainPadding,
      maximumValue: 100 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Utilisation',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.temperature => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: 20 + _midpointOffset,
      minimumValue: 8 - _domainPadding,
      maximumValue: 30 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Temperature',
      unit: '°C',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.threshold => HeatmapColorScale.threshold(
      thresholds: const [98, 99.5],
      colors: _thresholdColors,
      bandLabels: const ['Degraded', 'Watch', 'Healthy'],
      reverse: _reverseScale,
      missingColor: _missingColor,
      label: 'Availability',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.calendar => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 15 - _domainPadding,
      maximumValue: 28 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Daily maximum',
      unit: '°C',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.contributions => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0,
      maximumValue: 12 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Contributions',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.correlation => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: _midpointOffset,
      minimumValue: -1 - _domainPadding,
      maximumValue: 1 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Correlation',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.histogram => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0,
      maximumValue:
          _histogramData.bins
              .map((bin) => bin.count)
              .reduce((first, second) => first > second ? first : second)
              .toDouble() +
          _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Observation count',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.density ||
    _HeatmapPreset.contours => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0,
      maximumValue: 1 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Relative density',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.clustered => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: _midpointOffset,
      minimumValue: -1 - _domainPadding,
      maximumValue: 1 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Relationship',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.colourAxes => HeatmapColorScale.sequential(
      colors: const [Color(0xFFE0F2FE), Color(0xFF0369A1)],
      minimumValue: 0,
      maximumValue: 100,
      label: 'Fallback scale',
      showLegend: false,
    ),
    _HeatmapPreset.dense => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: 50 + _midpointOffset,
      minimumValue: 16 - _domainPadding,
      maximumValue: 84 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Signal',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.smallMultiples => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 10,
      maximumValue: 100,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Response latency',
      unit: 'ms',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.viewportSource => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0,
      maximumValue: 100,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Signal intensity',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.rasterTiles => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0,
      maximumValue: 100,
      label: 'Raster intensity',
      unit: '%',
      showLegend: false,
    ),
  };

  String get _title => switch (_preset) {
    _HeatmapPreset.activity => 'Product activity by day and hour',
    _HeatmapPreset.selection => 'Matrix selection',
    _HeatmapPreset.irregular => 'Pipeline intervals',
    _HeatmapPreset.temperature => 'Weekly temperature profile',
    _HeatmapPreset.threshold => 'Service availability matrix',
    _HeatmapPreset.calendar => 'Daily temperature in July',
    _HeatmapPreset.contributions => 'Contribution activity',
    _HeatmapPreset.correlation => 'Product metric correlation',
    _HeatmapPreset.histogram => 'Review score density',
    _HeatmapPreset.density => 'Customer behaviour density',
    _HeatmapPreset.contours => 'Customer density contours',
    _HeatmapPreset.clustered => 'Clustered product signals',
    _HeatmapPreset.colourAxes => 'Independent operational colour axes',
    _HeatmapPreset.smallMultiples => 'Service latency by time window',
    _HeatmapPreset.dense => 'Dense signal viewport',
    _HeatmapPreset.viewportSource => 'Viewport-backed massive matrix',
    _HeatmapPreset.rasterTiles => 'Deep signal spectrogram',
  };

  String get _subtitle => switch (_preset) {
    _HeatmapPreset.activity => '7 days · 12 time slots · sequential scale',
    _HeatmapPreset.selection =>
      '7 × 12 matrix · persistent rectangle brush · row/column expansion',
    _HeatmapPreset.irregular =>
      '12 unequal intervals · explicit rectangular bounds · lossless Workbench projection',
    _HeatmapPreset.temperature => '7 days · diverging around 20 °C',
    _HeatmapPreset.threshold => '4 services · discrete operational bands',
    _HeatmapPreset.calendar =>
      '5 calendar weeks · explicit missing cells · sequential scale',
    _HeatmapPreset.contributions =>
      '24 weeks · zero is a real styled value · missing remains independent',
    _HeatmapPreset.correlation =>
      '6 metrics · square matrix · diverging around zero',
    _HeatmapPreset.histogram =>
      '800 raw reviews · explicit 9 × 10 bins · count aggregation',
    _HeatmapPreset.density =>
      '480 weighted observations · ${_densityKernel.name} kernel · live bandwidth',
    _HeatmapPreset.contours =>
      '480 weighted observations · ${_contourLevels.length} contour levels · ${_densityKernel.name} kernel',
    _HeatmapPreset.clustered =>
      '${_clusterHierarchyProjection.rowGroups.length} × ${_clusterHierarchyProjection.columnGroups.length} matrix · '
          '${_clusterFocusLabel.toLowerCase()} · '
          '${_effectiveClusterAxisMode.name} order · '
          '${_clusterDistance.name} · ${_clusterLinkage.name} linkage · '
          '${_hierarchyReducer.name} collapse reducer',
    _HeatmapPreset.colourAxes =>
      '2 Heatmap series · independent ms and % domains · independently filterable legends',
    _HeatmapPreset.smallMultiples =>
      '3 independent panels · ${_useSharedDomain ? 'one shared domain' : 'local domains'} · normal Heatmap renderers',
    _HeatmapPreset.dense =>
      '30,000 source positions · sparse gaps · viewport-indexed rendering',
    _HeatmapPreset.viewportSource =>
      '24,000,000 conceptual cells · async tiles · bounded resident snapshot',
    _HeatmapPreset.rasterTiles =>
      '512,000,000 logical samples · image-backed viewport tiles · Cartesian pan and zoom',
  };

  List<String> get _rowLabels => switch (_preset) {
    _HeatmapPreset.activity ||
    _HeatmapPreset.selection ||
    _HeatmapPreset.temperature ||
    _HeatmapPreset.contributions => const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ],
    _HeatmapPreset.irregular => const [
      'Ingest',
      'Transform',
      'Score',
      'Publish',
    ],
    _HeatmapPreset.threshold => const ['API', 'Web', 'Jobs', 'Storage'],
    _HeatmapPreset.calendar => const [
      'Week 1',
      'Week 2',
      'Week 3',
      'Week 4',
      'Week 5',
    ],
    _HeatmapPreset.correlation => const [
      'Revenue',
      'Orders',
      'Sessions',
      'Latency',
      'Errors',
      'Retention',
    ],
    _HeatmapPreset.histogram => _histogramYAxis.labels,
    _HeatmapPreset.density => _densityYAxis.labels,
    _HeatmapPreset.contours => _densityYAxis.labels,
    _HeatmapPreset.clustered => _clusterHierarchyProjection.rowLabels,
    _HeatmapPreset.colourAxes => const ['Error rate', 'Latency'],
    _HeatmapPreset.smallMultiples => const ['Mon', 'Tue', 'Wed', 'Thu'],
    _HeatmapPreset.dense => const [],
    _HeatmapPreset.viewportSource => const [],
    _HeatmapPreset.rasterTiles => const [],
  };

  List<String> get _columnLabels => switch (_preset) {
    _HeatmapPreset.calendar => const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ],
    _HeatmapPreset.contributions => const [
      'Aug 1',
      'Aug 2',
      'Aug 3',
      'Aug 4',
      'Sep 1',
      'Sep 2',
      'Sep 3',
      'Sep 4',
      'Oct 1',
      'Oct 2',
      'Oct 3',
      'Oct 4',
      'Nov 1',
      'Nov 2',
      'Nov 3',
      'Nov 4',
      'Dec 1',
      'Dec 2',
      'Dec 3',
      'Dec 4',
      'Jan 1',
      'Jan 2',
      'Jan 3',
      'Jan 4',
    ],
    _HeatmapPreset.correlation => _rowLabels,
    _HeatmapPreset.histogram => _histogramXAxis.labels,
    _HeatmapPreset.density => _densityXAxis.labels,
    _HeatmapPreset.contours => _densityXAxis.labels,
    _HeatmapPreset.clustered => _clusterHierarchyProjection.columnLabels,
    _HeatmapPreset.colourAxes => const ['00', '04', '08', '12', '16', '20'],
    _HeatmapPreset.smallMultiples => const ['00', '06', '12', '18', '24'],
    _HeatmapPreset.irregular => const [],
    _ => const [
      '00',
      '02',
      '04',
      '06',
      '08',
      '10',
      '12',
      '14',
      '16',
      '18',
      '20',
      '22',
    ],
  };

  String get _clusterFocusLabel => switch (_clusterFocus) {
    _ClusterFocus.full => 'Full hierarchy',
    _ClusterFocus.primary => 'Primary cluster',
    _ClusterFocus.secondary => 'Secondary cluster',
  };

  String? get _unit => switch (_preset) {
    _HeatmapPreset.temperature || _HeatmapPreset.calendar => '°C',
    _HeatmapPreset.contributions => 'contributions',
    _HeatmapPreset.correlation => null,
    _HeatmapPreset.histogram => 'observations',
    _HeatmapPreset.density => null,
    _HeatmapPreset.contours => null,
    _HeatmapPreset.clustered => null,
    _HeatmapPreset.colourAxes => null,
    _HeatmapPreset.smallMultiples => 'ms',
    _HeatmapPreset.irregular => '%',
    _ => '%',
  };
  String get _xAxisLabel => switch (_preset) {
    _HeatmapPreset.calendar => 'Day of week',
    _HeatmapPreset.contributions => 'Week',
    _HeatmapPreset.correlation => 'Metric',
    _HeatmapPreset.histogram => 'IMDb rating (binned)',
    _HeatmapPreset.density => 'Engagement score',
    _HeatmapPreset.contours => 'Engagement score',
    _HeatmapPreset.clustered => 'Observed metric',
    _HeatmapPreset.colourAxes => 'Time window',
    _HeatmapPreset.smallMultiples => 'Time window',
    _HeatmapPreset.irregular => 'Elapsed hour',
    _ => 'Hour',
  };
  String get _yAxisLabel => switch (_preset) {
    _HeatmapPreset.threshold => 'Service',
    _HeatmapPreset.calendar => 'Week',
    _HeatmapPreset.contributions => 'Day',
    _HeatmapPreset.correlation => 'Metric',
    _HeatmapPreset.histogram => 'Rotten Tomatoes (binned)',
    _HeatmapPreset.density => 'Customer value',
    _HeatmapPreset.contours => 'Customer value',
    _HeatmapPreset.clustered => 'Product signal',
    _HeatmapPreset.colourAxes => 'Operational metric',
    _HeatmapPreset.smallMultiples => 'Day',
    _HeatmapPreset.irregular => 'Pipeline lane',
    _ => 'Day',
  };

  bool get _usesMidpoint =>
      _preset == _HeatmapPreset.temperature ||
      _preset == _HeatmapPreset.correlation ||
      _preset == _HeatmapPreset.clustered ||
      _preset == _HeatmapPreset.dense;

  double get _domainPaddingMaximum => switch (_preset) {
    _HeatmapPreset.correlation => 0.5,
    _HeatmapPreset.temperature || _HeatmapPreset.calendar => 10,
    _HeatmapPreset.contributions => 12,
    _HeatmapPreset.histogram => 40,
    _HeatmapPreset.density => 0.5,
    _HeatmapPreset.contours => 0.5,
    _HeatmapPreset.clustered => 0.5,
    _HeatmapPreset.smallMultiples => 25,
    _ => 25,
  };

  double get _midpointOffsetMaximum => switch (_preset) {
    _HeatmapPreset.correlation => 0.5,
    _HeatmapPreset.clustered => 0.5,
    _HeatmapPreset.temperature => 6,
    _ => 20,
  };

  List<Color> get _sequentialColors => switch (_palette) {
    _HeatmapPalette.ocean => const [
      Color(0xFFE0F2FE),
      Color(0xFF67E8F9),
      Color(0xFF0891B2),
      Color(0xFF164E63),
    ],
    _HeatmapPalette.forest => const [
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ],
    _HeatmapPalette.sunset => const [
      Color(0xFFFFF7ED),
      Color(0xFFFDBA74),
      Color(0xFFEA580C),
      Color(0xFF7C2D12),
    ],
    _HeatmapPalette.viridis => const [
      Color(0xFF440154),
      Color(0xFF31688E),
      Color(0xFF35B779),
      Color(0xFFFDE725),
    ],
    _HeatmapPalette.graphite => const [
      Color(0xFFF8FAFC),
      Color(0xFFCBD5E1),
      Color(0xFF64748B),
      Color(0xFF0F172A),
    ],
  };

  List<Color> get _divergingColors => switch (_palette) {
    _HeatmapPalette.ocean => const [
      Color(0xFF2563EB),
      Color(0xFFF8FAFC),
      Color(0xFFEA580C),
    ],
    _HeatmapPalette.forest => const [
      Color(0xFF166534),
      Color(0xFFF8FAFC),
      Color(0xFFA3E635),
    ],
    _HeatmapPalette.sunset => const [
      Color(0xFF7C3AED),
      Color(0xFFFFFBEB),
      Color(0xFFE11D48),
    ],
    _HeatmapPalette.viridis => const [
      Color(0xFF440154),
      Color(0xFFF8FAFC),
      Color(0xFFFDE725),
    ],
    _HeatmapPalette.graphite => const [
      Color(0xFF334155),
      Color(0xFFF8FAFC),
      Color(0xFF0F172A),
    ],
  };

  List<Color> get _thresholdColors => switch (_palette) {
    _HeatmapPalette.ocean => const [
      Color(0xFFDC2626),
      Color(0xFFF59E0B),
      Color(0xFF16A34A),
    ],
    _HeatmapPalette.forest => const [
      Color(0xFFDC2626),
      Color(0xFFFACC15),
      Color(0xFF16A34A),
    ],
    _HeatmapPalette.sunset => const [
      Color(0xFF7C3AED),
      Color(0xFFF97316),
      Color(0xFFFDE047),
    ],
    _HeatmapPalette.viridis => const [
      Color(0xFF440154),
      Color(0xFF21918C),
      Color(0xFFFDE725),
    ],
    _HeatmapPalette.graphite => const [
      Color(0xFF334155),
      Color(0xFF94A3B8),
      Color(0xFFE2E8F0),
    ],
  };

  static double _contributionValue(int week, int day) {
    final activity = (week * 11 + day * 7 + week ~/ 4) % 19;
    if (activity < 9 || (week + day * 3) % 17 == 0) return 0;
    return (1 + (week * 5 + day * 3 + activity) % 12).toDouble();
  }

  static double _wave(num radians) {
    final value = radians.toDouble();
    // A compact deterministic approximation is sufficient for showcase data
    // and avoids making the example depend on a random seed.
    final wrapped = value % 6.283185307179586;
    if (wrapped < 1.5707963267948966) return wrapped / 1.5707963267948966;
    if (wrapped < 4.71238898038469) {
      return 2 - wrapped / 1.5707963267948966;
    }
    return wrapped / 1.5707963267948966 - 4;
  }
}

/// Passive browser/device timings for the currently selected Heatmap preset.
///
/// This widget owns its sampling state so the twice-per-second diagnostics
/// refresh never rebuilds the chart, its workbench, or the enclosing page.
class _HeatmapPerformanceProbe extends StatefulWidget {
  const _HeatmapPerformanceProbe({super.key, required this.scenarioLabel});

  final String scenarioLabel;

  @override
  State<_HeatmapPerformanceProbe> createState() =>
      _HeatmapPerformanceProbeState();
}

class _HeatmapPerformanceProbeState extends State<_HeatmapPerformanceProbe>
    with SingleTickerProviderStateMixin {
  static const _frameBudget = Duration(microseconds: 16667);
  static const _maxSamples = 180;
  static const _metricsRefreshInterval = Duration(milliseconds: 500);
  static const _samplingDuration = Duration(seconds: 4);

  final List<FrameTiming> _frameTimings = [];
  DateTime _lastMetricsRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  late final AnimationController _samplingController;
  bool _isSampling = false;

  @override
  void initState() {
    super.initState();
    _samplingController = AnimationController(
      vsync: this,
      duration: _samplingDuration,
    )..addStatusListener(_handleSamplingStatus);
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
  }

  void _recordTimings(List<FrameTiming> timings) {
    if (!mounted || !_isSampling || timings.isEmpty) return;
    _frameTimings.addAll(timings);
    if (_frameTimings.length > _maxSamples) {
      _frameTimings.removeRange(0, _frameTimings.length - _maxSamples);
    }
    final now = DateTime.now();
    if (now.difference(_lastMetricsRefresh) < _metricsRefreshInterval) return;
    _lastMetricsRefresh = now;
    setState(() {});
  }

  void _startSample() {
    _samplingController.stop();
    setState(() {
      _frameTimings.clear();
      _lastMetricsRefresh = DateTime.now();
      _isSampling = true;
    });
    // The controller deliberately has no visual listener. Its ticker requests
    // a continuous frame cadence while the user exercises the chart, without
    // rebuilding either this diagnostics widget or the chart subtree.
    _samplingController.forward(from: 0);
  }

  void _handleSamplingStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) return;
    setState(() => _isSampling = false);
  }

  void _reset() {
    _samplingController.stop();
    setState(() {
      _frameTimings.clear();
      _lastMetricsRefresh = DateTime.now();
      _isSampling = false;
    });
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _samplingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final frameP95 = _percentileMs(
      _frameTimings.map((timing) => timing.totalSpan),
    );
    final buildP95 = _percentileMs(
      _frameTimings.map((timing) => timing.buildDuration),
    );
    final rasterP95 = _percentileMs(
      _frameTimings.map((timing) => timing.rasterDuration),
    );
    final gapP95 = _percentileMs(_frameGaps());
    final slowFrames = _frameTimings
        .where((timing) => timing.totalSpan > _frameBudget)
        .length;
    final jankPercent = _frameTimings.isEmpty
        ? null
        : slowFrames / _frameTimings.length * 100;
    final presentedFps = gapP95 == null || gapP95 <= 0 ? null : 1000 / gapP95;

    return Semantics(
      container: true,
      label: 'Heatmap rolling performance diagnostics',
      child: Column(
        key: const ValueKey('heatmap-performance-probe'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.scenarioLabel} · ${_isSampling
                ? 'sampling'
                : _frameTimings.isEmpty
                ? 'ready'
                : 'sample complete'} · ${_frameTimings.length}/$_maxSamples rendered frames',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('run-heatmap-performance'),
                  onPressed: _isSampling ? null : _startSample,
                  icon: Icon(
                    _isSampling ? Icons.timelapse : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(_isSampling ? 'Sampling…' : 'Run 4 s sample'),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const ValueKey('reset-heatmap-performance'),
                tooltip: 'Clear Heatmap performance sample',
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = math.max(
                96.0,
                (constraints.maxWidth - 8) / 2,
              );
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeatmapDiagnosticMetric(
                    width: metricWidth,
                    label: 'Frame p95',
                    value: _formatMilliseconds(frameP95),
                    color: _timingColor(colors, frameP95, 16.67),
                  ),
                  _HeatmapDiagnosticMetric(
                    width: metricWidth,
                    label: 'Frame gap p95',
                    value: _formatMilliseconds(gapP95),
                    color: _timingColor(colors, gapP95, 20),
                  ),
                  _HeatmapDiagnosticMetric(
                    width: metricWidth,
                    label: 'Presented FPS',
                    value: presentedFps == null
                        ? '—'
                        : presentedFps.toStringAsFixed(1),
                    color: presentedFps == null
                        ? colors.onSurface
                        : presentedFps >= 55
                        ? Colors.green.shade700
                        : presentedFps >= 45
                        ? Colors.orange.shade800
                        : colors.error,
                  ),
                  _HeatmapDiagnosticMetric(
                    width: metricWidth,
                    label: 'Jank >16.7ms',
                    value: jankPercent == null
                        ? '—'
                        : '${jankPercent.toStringAsFixed(0)}%',
                    color: jankPercent == null
                        ? colors.onSurface
                        : jankPercent <= 1
                        ? Colors.green.shade700
                        : jankPercent <= 5
                        ? Colors.orange.shade800
                        : colors.error,
                  ),
                  _HeatmapDiagnosticMetric(
                    width: metricWidth,
                    label: 'Build p95',
                    value: _formatMilliseconds(buildP95),
                  ),
                  _HeatmapDiagnosticMetric(
                    width: metricWidth,
                    label: 'Raster p95',
                    value: _formatMilliseconds(rasterP95),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Start the controlled sample, then replay an update or pan/zoom '
            'the chart while it runs. Idle time is excluded. These are '
            'device-, browser-, and build-specific measurements, not portable '
            'package claims.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  double? _percentileMs(Iterable<Duration> durations) {
    final values = durations.map((duration) => duration.inMicroseconds).toList()
      ..sort();
    if (values.isEmpty) return null;
    final index = ((values.length - 1) * 0.95).ceil();
    return values[index] / 1000;
  }

  List<Duration> _frameGaps() {
    if (_frameTimings.length < 2) return const [];
    final gaps = <Duration>[];
    for (var index = 1; index < _frameTimings.length; index++) {
      final previous = _frameTimings[index - 1].timestampInMicroseconds(
        ui.FramePhase.vsyncStart,
      );
      final current = _frameTimings[index].timestampInMicroseconds(
        ui.FramePhase.vsyncStart,
      );
      final gap = current - previous;
      if (gap > 0) gaps.add(Duration(microseconds: gap));
    }
    return gaps;
  }

  String _formatMilliseconds(double? value) {
    if (value == null) return '—';
    if (value < 0.1) return '<0.1ms';
    return '${value.toStringAsFixed(1)}ms';
  }

  Color _timingColor(ColorScheme colors, double? value, double budget) {
    if (value == null) return colors.onSurface;
    if (value <= budget) return Colors.green.shade700;
    if (value <= budget * 1.5) return Colors.orange.shade800;
    return colors.error;
  }
}

class _HeatmapDiagnosticMetric extends StatelessWidget {
  const _HeatmapDiagnosticMetric({
    required this.width,
    required this.label,
    required this.value,
    this.color,
  });

  final double width;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 1),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterRowLabels extends StatelessWidget {
  const _ClusterRowLabels({required this.labels, required this.textStyle});

  final List<String> labels;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final label in labels.reversed)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textStyle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ClusterColumnLabels extends StatelessWidget {
  const _ClusterColumnLabels({required this.labels, required this.textStyle});

  final List<String> labels;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
          ),
      ],
    );
  }
}

class _ViewportMetric extends StatelessWidget {
  const _ViewportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 120),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _ProceduralMassiveHeatmapSource implements HeatmapTileSource {
  static const int _maximumLiveCellOverrides = 12288;

  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 1000000,
    rowCount: 24,
  );

  @override
  int get tileColumnCount => 128;

  @override
  int get tileRowCount => 24;

  final Map<(int, int), HeatmapDataPoint> _liveCells = {};

  void upsert(int column, int row, HeatmapDataPoint cell) {
    final key = (column, row);
    if (!_liveCells.containsKey(key) &&
        _liveCells.length >= _maximumLiveCellOverrides) {
      _liveCells.remove(_liveCells.keys.first);
    }
    _liveCells[key] = cell;
  }

  HeatmapDataPoint liveCell(int column, int row, int tick) {
    final pulse = math.sin(tick * 0.28 + row * 0.52) * 28;
    final value = (_valueAt(column, row) + pulse).clamp(0, 100).toDouble();
    return HeatmapDataPoint(
      x: domain.xForColumn(column),
      y: domain.yForRow(row),
      value: value,
      pointKey: 'massive-$row-$column',
      label: 'Live signal ${row + 1} · source column $column',
      metadata: {'sourceColumn': column, 'sourceRow': row, 'liveTick': tick},
    );
  }

  @override
  Future<HeatmapTile> loadTile(HeatmapTileRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 24));
    return HeatmapTile(
      key: request.key,
      cells: [
        for (var row = request.rowStart; row < request.rowEndExclusive; row++)
          for (
            var column = request.columnStart;
            column < request.columnEndExclusive;
            column++
          )
            _liveCells[(column, row)] ??
                HeatmapDataPoint(
                  x: domain.xForColumn(column),
                  y: domain.yForRow(row),
                  value: _valueAt(column, row),
                  pointKey: 'massive-$row-$column',
                  label: 'Signal ${row + 1} · source column $column',
                  metadata: {'sourceColumn': column, 'sourceRow': row},
                ),
      ],
    );
  }

  double _valueAt(int column, int row) {
    final primary = math.sin(column * 0.037 + row * 0.43);
    final secondary = math.cos(column * 0.011 - row * 0.29);
    final pulse = math.sin((column + row * 17) * 0.0037);
    return (50 + primary * 25 + secondary * 16 + pulse * 9)
        .clamp(0, 100)
        .toDouble();
  }
}

class _ProceduralRasterHeatmapSource implements HeatmapRasterTileSource {
  static const int _imageWidth = 256;
  static const int _imageHeight = 128;
  static const int _semanticColumnsPerTile = 16;
  static const int _semanticRowsPerTile = 8;
  static const List<Color> _colors = [
    Color(0xFF071D49),
    Color(0xFF0E7490),
    Color(0xFF22D3EE),
    Color(0xFFFDE68A),
    Color(0xFFF97316),
  ];

  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 1000000,
    rowCount: 512,
  );

  int get logicalCellCount => domain.columnCount * domain.rowCount;

  int get semanticColumnsPerTile => _semanticColumnsPerTile;

  int get semanticRowsPerTile => _semanticRowsPerTile;

  int _delayedLoadsRemaining = 0;
  Duration _nextBatchDelay = Duration.zero;
  bool _failNextLoad = false;

  void delayNextBatch(Duration delay) {
    _nextBatchDelay = delay;
    _delayedLoadsRemaining = 24;
  }

  void failNextLoad() => _failNextLoad = true;

  HeatmapColorScale get semanticColorScale => HeatmapColorScale.sequential(
    colors: _colors,
    minimumValue: 0,
    maximumValue: 100,
    label: 'Signal intensity',
    unit: '%',
    showLegend: false,
  );

  @override
  int get tileColumnCount => 8192;

  @override
  int get tileRowCount => 128;

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) async {
    final delayed = _delayedLoadsRemaining > 0;
    if (delayed) _delayedLoadsRemaining--;
    await Future<void>.delayed(
      delayed ? _nextBatchDelay : const Duration(milliseconds: 18),
    );
    if (_failNextLoad) {
      _failNextLoad = false;
      throw StateError(
        'Review failure: the upstream spectrogram tile was unavailable',
      );
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    for (var imageRow = 0; imageRow < _imageHeight; imageRow++) {
      final row =
          request.rowStart +
          ((imageRow + 0.5) * request.rowCount / _imageHeight).floor();
      for (var imageColumn = 0; imageColumn < _imageWidth; imageColumn++) {
        final column =
            request.columnStart +
            ((imageColumn + 0.5) * request.columnCount / _imageWidth).floor();
        final value = _valueAt(column, row);
        paint.color = _colorAt(value);
        canvas.drawRect(
          ui.Rect.fromLTWH(
            imageColumn.toDouble(),
            (_imageHeight - imageRow - 1).toDouble(),
            1,
            1,
          ),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(_imageWidth, _imageHeight);
    picture.dispose();
    return HeatmapRasterTile(
      key: request.key,
      bounds: HeatmapViewportBounds(
        minimumX: domain.xForColumn(request.columnStart) - domain.cellWidth / 2,
        maximumX:
            domain.xForColumn(request.columnEndExclusive - 1) +
            domain.cellWidth / 2,
        minimumY: domain.yForRow(request.rowStart) - domain.cellHeight / 2,
        maximumY:
            domain.yForRow(request.rowEndExclusive - 1) + domain.cellHeight / 2,
      ),
      resource: HeatmapRasterImageResource(image: image),
      semanticCells: _semanticCellsFor(request),
    );
  }

  List<HeatmapDataPoint> _semanticCellsFor(HeatmapTileRequest request) {
    final cells = <HeatmapDataPoint>[];
    for (
      var semanticRow = 0;
      semanticRow < _semanticRowsPerTile;
      semanticRow++
    ) {
      final rowStart =
          request.rowStart +
          semanticRow * request.rowCount ~/ _semanticRowsPerTile;
      final rowEndExclusive =
          request.rowStart +
          (semanticRow + 1) * request.rowCount ~/ _semanticRowsPerTile;
      if (rowStart >= rowEndExclusive) continue;
      for (
        var semanticColumn = 0;
        semanticColumn < _semanticColumnsPerTile;
        semanticColumn++
      ) {
        final columnStart =
            request.columnStart +
            semanticColumn * request.columnCount ~/ _semanticColumnsPerTile;
        final columnEndExclusive =
            request.columnStart +
            (semanticColumn + 1) *
                request.columnCount ~/
                _semanticColumnsPerTile;
        if (columnStart >= columnEndExclusive) continue;
        final xMinimum = domain.xForColumn(columnStart) - domain.cellWidth / 2;
        final xMaximum =
            domain.xForColumn(columnEndExclusive - 1) + domain.cellWidth / 2;
        final yMinimum = domain.yForRow(rowStart) - domain.cellHeight / 2;
        final yMaximum =
            domain.yForRow(rowEndExclusive - 1) + domain.cellHeight / 2;
        final value = _aggregateValue(
          columnStart: columnStart,
          columnEndExclusive: columnEndExclusive,
          rowStart: rowStart,
          rowEndExclusive: rowEndExclusive,
        );
        cells.add(
          HeatmapDataPoint(
            x: (xMinimum + xMaximum) / 2,
            y: (yMinimum + yMaximum) / 2,
            value: value * 100,
            bounds: HeatmapCellBounds(
              xMinimum: xMinimum,
              xMaximum: xMaximum,
              yMinimum: yMinimum,
              yMaximum: yMaximum,
            ),
            pointKey:
                'spectrogram-${request.key.column}-${request.key.row}-$semanticColumn-$semanticRow',
            label:
                'Samples $columnStart–${columnEndExclusive - 1} · bins $rowStart–${rowEndExclusive - 1}',
            metadata: {
              'aggregation': 'sampled-mean',
              'sourceColumnStart': columnStart,
              'sourceColumnEndExclusive': columnEndExclusive,
              'sourceRowStart': rowStart,
              'sourceRowEndExclusive': rowEndExclusive,
              'rasterTileColumn': request.key.column,
              'rasterTileRow': request.key.row,
            },
          ),
        );
      }
    }
    return List.unmodifiable(cells);
  }

  double _aggregateValue({
    required int columnStart,
    required int columnEndExclusive,
    required int rowStart,
    required int rowEndExclusive,
  }) {
    var total = 0.0;
    var sampleCount = 0;
    for (var rowSample = 0; rowSample < 3; rowSample++) {
      final row = math.min(
        rowEndExclusive - 1,
        rowStart +
            ((rowSample + 0.5) * (rowEndExclusive - rowStart) / 3).floor(),
      );
      for (var columnSample = 0; columnSample < 3; columnSample++) {
        final column = math.min(
          columnEndExclusive - 1,
          columnStart +
              ((columnSample + 0.5) * (columnEndExclusive - columnStart) / 3)
                  .floor(),
        );
        total += _valueAt(column, row);
        sampleCount++;
      }
    }
    return total / sampleCount;
  }

  double _valueAt(int column, int row) {
    final y = row / (domain.rowCount - 1);
    final time = column / 9500;
    final primaryFrequency =
        0.25 + math.sin(time * 0.83) * 0.10 + math.sin(time * 0.17) * 0.08;
    final secondaryFrequency = 0.62 + math.sin(time * 1.31 + 0.8) * 0.09;
    final primary = math.exp(-math.pow(y - primaryFrequency, 2) / 0.0018);
    final harmonic = math.exp(-math.pow(y - secondaryFrequency, 2) / 0.0032);
    final transientEnvelope = math.pow(
      math.max(0.0, math.sin(time * 2.4 + 0.6)),
      8,
    );
    final transient =
        transientEnvelope *
        math.exp(
          -math.pow(y - (0.42 + math.sin(time * 0.47) * 0.18), 2) / 0.024,
        );
    final lowFrequencyBed = math.exp(-math.pow(y - 0.08, 2) / 0.012);
    final texture =
        (math.sin(column * 0.013 + row * 0.19) +
            math.cos(column * 0.0047 - row * 0.11)) *
        0.025;
    return (0.035 +
            primary * 0.62 +
            harmonic * 0.38 +
            transient * 0.55 +
            lowFrequencyBed * 0.15 +
            texture)
        .clamp(0, 1)
        .toDouble();
  }

  Color _colorAt(double value) {
    final scaled = value * (_colors.length - 1);
    final lower = scaled.floor().clamp(0, _colors.length - 1);
    final upper = (lower + 1).clamp(0, _colors.length - 1);
    return Color.lerp(_colors[lower], _colors[upper], scaled - lower)!;
  }
}

class _HeatmapCoverageStrip extends StatelessWidget {
  const _HeatmapCoverageStrip();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _CoverageItem(label: 'Native Cartesian cells'),
            _CoverageItem(label: 'Sequential scale'),
            _CoverageItem(label: 'Diverging midpoint'),
            _CoverageItem(label: 'Threshold bands'),
            _CoverageItem(label: 'Tooltips + selection'),
            _CoverageItem(label: 'Sparse/missing identity'),
            _CoverageItem(label: 'Typed 2D aggregation'),
            _CoverageItem(label: 'Kernel density raster'),
            _CoverageItem(label: 'Marching Squares contours'),
            _CoverageItem(label: 'Deterministic matrix clustering'),
            _CoverageItem(label: 'Viewport culling + indexed hit'),
            _CoverageItem(label: 'Async viewport-backed matrix'),
            _CoverageItem(label: 'Ordered live cell mutation'),
          ],
        ),
      ),
    );
  }
}

class _CoverageItem extends StatelessWidget {
  const _CoverageItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.check_circle_outline,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 5),
      Text(label),
    ],
  );
}
