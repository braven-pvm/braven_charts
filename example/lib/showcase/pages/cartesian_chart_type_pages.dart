// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../data/scatter_point_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _CartesianFamily { line, area, scatter }

enum _ScatterFillTone { indigo, teal, coral, amber }

enum _ScatterColorRamp { readiness, thermal, coolWarm }

enum _ScatterRiskPalette { safety, thermal, service }

enum _SynchronizedMetric { speed, elevation, heartRate }

enum _SynchronizedDatasetProfile { normal, dense, stress }

enum _ScatterCategoryPalette { mobility, accessible }

typedef _ScatterViewport = ({
  double xMin,
  double xMax,
  double yMin,
  double yMax,
});

class LineChartsPage extends StatelessWidget {
  const LineChartsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CartesianChartTypePage(family: _CartesianFamily.line);
}

class AreaChartsPage extends StatelessWidget {
  const AreaChartsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CartesianChartTypePage(family: _CartesianFamily.area);
}

class ScatterChartsPage extends StatelessWidget {
  const ScatterChartsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CartesianChartTypePage(family: _CartesianFamily.scatter);
}

class _CartesianChartTypePage extends StatefulWidget {
  const _CartesianChartTypePage({required this.family});

  final _CartesianFamily family;

  @override
  State<_CartesianChartTypePage> createState() =>
      _CartesianChartTypePageState();
}

class _CartesianChartTypePageState extends State<_CartesianChartTypePage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final ChartInteractionGroupController _interactionGroupController =
      ChartInteractionGroupController();
  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showDataMarkers: true),
  );
  final ScrollController _presetScrollController = ScrollController();
  final Map<int, GlobalKey> _presetLabelKeys = {};

  int _presetIndex = 0;
  LineInterpolation _interpolation = LineInterpolation.monotone;
  double _strokeWidth = 2.5;
  double _lineGlow = 0;
  double _fillOpacity = 0.24;
  double _markerRadius = 5;
  double _lineMarkerRadius = 3;
  DataPointMarkerStyle _lineMarkerStyle = DataPointMarkerStyle.filled;
  SeriesMarkerShape _scatterMarkerShape = SeriesMarkerShape.circle;
  _ScatterFillTone _scatterFillTone = _ScatterFillTone.indigo;
  double _scatterMarkerWidth = 18;
  double _scatterMarkerHeight = 10;
  double _scatterMarkerStrokeWidth = 2;
  double _scatterMarkerOpacity = 0.82;
  double _scatterMarkerRotation = 24;
  double _scatterSelectionScale = 1.45;
  double _scatterSelectionStrokeWidth = 3;
  double _scatterDimmedOpacity = 0.22;
  double _scatterFocusGap = 5;
  double _scatterBubbleMinimumRadius = 4;
  double _scatterBubbleMaximumRadius = 24;
  _ScatterColorRamp _scatterColorRamp = _ScatterColorRamp.readiness;
  _ScatterRiskPalette _scatterRiskPalette = _ScatterRiskPalette.safety;
  _ScatterCategoryPalette _scatterCategoryPalette =
      _ScatterCategoryPalette.mobility;
  double _scatterMinimumOpacity = 0.18;
  double _scatterJitterX = 44;
  double _scatterJitterY = 32;
  int _scatterJitterSeed = 17;
  double _scatterLoessSpan = 0.45;
  int _scatterLoessRobustnessIterations = 2;
  int _scatterLoessSampleCount = 120;
  bool _scatterShowEquation = true;
  bool _scatterShowRSquared = true;
  bool _scatterShowSampleCount = true;
  bool _scatterShowPearsonCorrelation = true;
  bool _scatterShowSpearmanCorrelation = true;
  bool _scatterShowConfidenceBand = true;
  bool _scatterShowPredictionBand = true;
  double _scatterConfidenceLevel = 0.95;
  bool _scatterShowXErrorBars = true;
  bool _scatterShowYErrorBars = true;
  bool _scatterAsymmetricErrorBars = true;
  double _scatterErrorScale = 1;
  DataPointLabelPosition _scatterLabelPosition = DataPointLabelPosition.right;
  DataPointLabelCollisionPolicy _scatterLabelCollisionPolicy =
      DataPointLabelCollisionPolicy.reposition;
  double _scatterLabelOffsetX = 0;
  double _scatterLabelOffsetY = 0;
  ChartSelectionOperation _scatterSelectionOperation =
      ChartSelectionOperation.toggle;
  bool _scatterClearSelectionOnBackgroundTap = true;
  ChartSelectionResult _scatterSelectionResult =
      const ChartSelectionResult.empty();
  int _scatterPointCount = 10000;
  int _scatterSeriesCount = 3;
  int _scatterGeneratorSeriesCount = 3;
  ScatterPointGeneratorConfig _scatterGeneratorConfig =
      const ScatterPointGeneratorConfig();
  int _scatterClusterPointCount = 25000;
  double _scatterClusterCellSize = 44;
  int _scatterClusterMinimumPoints = 2;
  double _scatterClusterMinimumRadius = 8;
  double _scatterClusterMaximumRadius = 26;
  bool _scatterClusterShowLabels = true;
  bool _scatterClusterShowZones = true;
  double _scatterClusterZoneOpacity = 0.08;
  bool _scatterClusterDrillOnTap = true;
  double _scatterClusterDrillPadding = 0.18;
  final Map<int, List<ChartDataPoint>> _scatterClusterPointCache = {};
  int _scatterBinPointCount = 50000;
  double _scatterBinCellSize = 36;
  double _scatterBinGap = 1;
  int _scatterBinMinimumPoints = 1;
  double _scatterBinMinimumOpacity = 0.18;
  double _scatterBinMaximumOpacity = 0.95;
  ScatterBinAggregate _scatterBinAggregate = ScatterBinAggregate.count;
  ScatterBinValueSource _scatterBinValueSource = ScatterBinValueSource.y;
  bool _scatterBinShowLabels = false;
  int _scatterBinLabelMinimumPoints = 25;
  int _scatterDensityPointCount = 50000;
  double _scatterDensityGridCellSize = 8;
  double _scatterDensityBandwidth = 32;
  int _scatterDensityContourCount = 6;
  double _scatterDensityMinimum = 0.08;
  double _scatterDensityMinimumOpacity = 0.28;
  double _scatterDensityMaximumOpacity = 0.9;
  double _scatterDensityLineWidth = 1.5;
  bool _scatterDensityShowPoints = false;
  int _scatterMarginalBinCount = 12;
  ScatterMarginalMode _scatterMarginalMode =
      ScatterMarginalMode.histogramAndDensity;
  HistogramValueMode _scatterMarginalValueMode = HistogramValueMode.percentage;
  double _scatterMarginalBandwidth = 1;
  double _scatterMarginalXExtent = 128;
  double _scatterMarginalYExtent = 144;
  final List<Color?> _scatterSeriesColorOverrides = List<Color?>.filled(
    6,
    null,
  );
  bool _scatterFillOverrideEnabled = false;
  Color? _scatterFillColorOverride;
  bool _scatterOutlineOverrideEnabled = false;
  Color? _scatterOutlineColorOverride;
  double _scatterOutlineWidthOverride = 2;
  bool _scatterOpacityOverrideEnabled = false;
  double _scatterOpacityOverride = 0.82;
  Color? _scatterBackgroundColorOverride;
  Color? _scatterGridColorOverride;
  Color? _scatterAxisColorOverride;
  Color? _scatterCrosshairColorOverride;
  bool _scatterInteractionColorOverrideEnabled = false;
  Color? _scatterHoverColorOverride;
  Color? _scatterSelectionColorOverride;
  Color? _scatterFocusColorOverride;
  bool _showSecondSeries = true;
  bool _showPointLabels = false;
  bool _showBaselineFill = true;
  bool _useAreaGradient = true;
  bool _animatePaths = true;
  bool _synchronizeCursor = true;
  bool _synchronizeViewport = true;
  bool _showSynchronizedIntersections = true;
  bool _synchronizedTracking = true;
  bool _synchronizedInterpolateValues = true;
  bool _showSynchronizedTrackingTooltip = true;
  bool _showSynchronizedHorizontalGuide = true;
  bool _showSynchronizedAxisValues = true;
  double _synchronizedIntersectionRadius = 4;
  bool _animateSynchronizedUpdates = true;
  bool _synchronizedLiveRevision = false;
  double _synchronizedUpdateDurationMs = 650;
  _SynchronizedDatasetProfile _synchronizedDatasetProfile =
      _SynchronizedDatasetProfile.normal;
  final Map<
    _SynchronizedDatasetProfile,
    Map<_SynchronizedMetric, List<ChartDataPoint>>
  >
  _synchronizedPointCache = {};
  final Map<
    _SynchronizedDatasetProfile,
    Map<_SynchronizedMetric, List<ChartDataPoint>>
  >
  _synchronizedUpdateCache = {};
  final Set<_SynchronizedMetric> _visibleSynchronizedMetrics = {
    ..._SynchronizedMetric.values,
  };
  final Map<_SynchronizedMetric, double> _synchronizedChartHeights = {
    _SynchronizedMetric.speed: 216,
    _SynchronizedMetric.elevation: 216,
    _SynchronizedMetric.heartRate: 232,
  };
  double _motionDurationMs = 650;
  late double _motionSeriesDelayMs;
  int _motionValueRevision = 0;
  late List<ChartDataPoint> _motionPrimaryPoints;
  late List<ChartDataPoint> _motionSecondaryPoints;
  ChartDisplayMode _initialDisplayMode = ChartDisplayMode.chart;

  @override
  void initState() {
    super.initState();
    _motionSeriesDelayMs = _defaultMotionSeriesDelayMs;
    _resetMotionData();
    _chartController.addListener(_handleChartControllerChanged);
    final requestedPreset = Uri.base.queryParameters['preset']?.toLowerCase();
    if (requestedPreset != null) {
      final index = _presets.indexWhere(
        (preset) => preset.label.toLowerCase() == requestedPreset,
      );
      if (index >= 0) _presetIndex = index;
    }
    final requestedView = Uri.base.queryParameters['view'];
    for (final mode in ChartDisplayMode.values) {
      if (mode.name == requestedView) {
        _initialDisplayMode = mode;
        break;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealActivePreset(animate: false);
    });
  }

  @override
  void dispose() {
    _chartController.removeListener(_handleChartControllerChanged);
    _chartController.dispose();
    _workbenchController.dispose();
    _interactionGroupController.dispose();
    _optionsController.dispose();
    _presetScrollController.dispose();
    super.dispose();
  }

  void _handleChartControllerChanged() {
    if (mounted && _isScatterSelectionPreset) setState(() {});
  }

  void _revealActivePreset({required bool animate}) {
    if (widget.family == _CartesianFamily.scatter) return;
    final renderObject = _presetLabelKeys[_presetIndex]?.currentContext
        ?.findRenderObject();
    if (!_presetScrollController.hasClients || renderObject == null) return;
    _presetScrollController.position.ensureVisible(
      renderObject,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  void _selectPreset(int index) {
    if (index == _presetIndex) return;
    _interactionGroupController.reset();
    _chartController.clearPointFocus();
    _chartController.clearPointSelection();
    setState(() {
      _presetIndex = index;
      _scatterSelectionResult = const ChartSelectionResult.empty();
      _resetMotionData();
    });
    if (widget.family != _CartesianFamily.scatter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _revealActivePreset(animate: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: _pageTitle,
      subtitle: _pageSubtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final preferredHeight = switch ((widget.family, compact)) {
            (_CartesianFamily.line, true) =>
              _isLineSynchronized ? 1660.0 : 820.0,
            (_CartesianFamily.line, false) =>
              _isLineSynchronized ? 1504.0 : 960.0,
            (_CartesianFamily.scatter, true) => 1500.0,
            _ => constraints.maxHeight,
          };
          final contentHeight = math.max(
            constraints.maxHeight,
            preferredHeight,
          );
          final content = SizedBox(
            height: contentHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPresetPicker(compact: compact),
                SizedBox(height: compact ? 8 : 16),
                Expanded(child: _buildChartCard()),
                if (!compact) ...[
                  const SizedBox(height: 16),
                  _FeatureCoverage(family: widget.family),
                ],
              ],
            ),
          );
          if (contentHeight <= constraints.maxHeight) return content;
          return SingleChildScrollView(
            key: const ValueKey('line-showcase-scroll'),
            primary: false,
            child: content,
          );
        },
      ),
    );
  }

  String get _pageTitle => switch (widget.family) {
    _CartesianFamily.line => 'Line Charts',
    _CartesianFamily.area => 'Area Charts',
    _CartesianFamily.scatter => 'Scatter Charts',
  };

  String get _presetPickerTitle => switch (widget.family) {
    _CartesianFamily.line => 'Choose a line chart example',
    _CartesianFamily.area => 'Choose an area chart example',
    _CartesianFamily.scatter => 'Choose a scatter chart example',
  };

  String get _pageSubtitle => switch (widget.family) {
    _CartesianFamily.line =>
      'The analytical workhorse: trends, interpolation, axes, tracking, and annotations',
    _CartesianFamily.area =>
      'Show magnitude, layering, and positive or negative deviation from a baseline',
    _CartesianFamily.scatter =>
      'Compare observation sets, reveal relationships, and inspect outliers',
  };

  List<_ChartTypePreset> get _presets => switch (widget.family) {
    _CartesianFamily.line => const [
      _ChartTypePreset(
        label: 'Workhorse',
        icon: Icons.monitor_heart_outlined,
        description: 'Two tracked signals with stages, a threshold, and peak.',
      ),
      _ChartTypePreset(
        label: 'Interpolation',
        icon: Icons.gesture,
        description: 'Linear, bezier, monotone, and stepped geometry together.',
      ),
      _ChartTypePreset(
        label: 'Multi-axis',
        icon: Icons.align_vertical_bottom_outlined,
        description: 'Independent units remain readable in one plot.',
      ),
      _ChartTypePreset(
        label: 'Motion',
        icon: Icons.animation,
        description: 'Reveal paths, then interpolate real value updates.',
      ),
      _ChartTypePreset(
        label: 'Comparison',
        icon: Icons.multiline_chart,
        description: 'Current, previous, and target trends share one scale.',
      ),
      _ChartTypePreset(
        label: 'Envelope',
        icon: Icons.area_chart_outlined,
        description: 'A gradient capacity envelope supports the observed line.',
      ),
      _ChartTypePreset(
        label: 'Spotlight',
        icon: Icons.blur_on,
        description: 'A luminous focus line stands over soft gradient context.',
      ),
      _ChartTypePreset(
        label: 'Forecast',
        icon: Icons.more_horiz,
        description: 'Solid observations hand off to a dotted prognosis.',
      ),
      _ChartTypePreset(
        label: 'Synchronized',
        icon: Icons.stacked_line_chart,
        description:
            'Three local scales share one distance cursor and viewport.',
      ),
    ],
    _CartesianFamily.area => const [
      _ChartTypePreset(
        label: 'Layered',
        icon: Icons.layers_outlined,
        description: 'Related volumes share a plot with restrained opacity.',
      ),
      _ChartTypePreset(
        label: 'Baseline',
        icon: Icons.compare_arrows,
        description: 'Positive and negative deviation use distinct fills.',
      ),
      _ChartTypePreset(
        label: 'Forecast',
        icon: Icons.cloud_outlined,
        description: 'A contextual range sits behind the observed line.',
      ),
      _ChartTypePreset(
        label: 'Motion',
        icon: Icons.animation,
        description: 'Fill and stroke reveal and update as one geometry.',
      ),
      _ChartTypePreset(
        label: 'Gradient',
        icon: Icons.gradient,
        description: 'A plot-bound gradient adds depth without obscuring data.',
      ),
      _ChartTypePreset(
        label: 'Composition',
        icon: Icons.stacked_line_chart,
        description: 'Two area layers combine with a crisp reference line.',
      ),
      _ChartTypePreset(
        label: 'Pulse',
        icon: Icons.auto_graph,
        description:
            'Gradient magnitude meets a target window and marked peak.',
      ),
    ],
    _CartesianFamily.scatter => const [
      _ChartTypePreset(
        label: 'Cohorts',
        icon: Icons.groups_outlined,
        description:
            'Olympic athlete height and body mass reveal sport-specific profiles.',
      ),
      _ChartTypePreset(
        label: 'Correlation',
        icon: Icons.trending_up,
        description:
            'Weekly training load and 20-minute power show a measurable relationship.',
      ),
      _ChartTypePreset(
        label: 'Outliers',
        icon: Icons.crisis_alert_outlined,
        description:
            'Glucose sensor agreement makes exception readings immediately visible.',
      ),
      _ChartTypePreset(
        label: 'Shapes',
        icon: Icons.category_outlined,
        description:
            'Marker silhouettes separate cohorts without relying on colour.',
      ),
      _ChartTypePreset(
        label: 'Styling',
        icon: Icons.palette_outlined,
        description:
            'Fill, outline, dimensions, opacity, and rotation form one marker style.',
      ),
      _ChartTypePreset(
        label: 'Stress',
        icon: Icons.speed,
        description:
            'Large ordered cohorts exercise viewport culling and indexed hits.',
      ),
      _ChartTypePreset(
        label: 'Unsorted',
        icon: Icons.shuffle,
        description:
            'Source order is deliberately shuffled without changing point identity.',
      ),
      _ChartTypePreset(
        label: 'States',
        icon: Icons.ads_click_outlined,
        description:
            'Hover, press, focus, and durable selection remain visually distinct.',
      ),
      _ChartTypePreset(
        label: 'Bubble',
        icon: Icons.bubble_chart_outlined,
        description:
            'Growth and retention position each market while active accounts control marker area.',
      ),
      _ChartTypePreset(
        label: 'Color scale',
        icon: Icons.gradient_outlined,
        description:
            'Training load and power locate each athlete while recovery readiness drives a continuous color scale.',
      ),
      _ChartTypePreset(
        label: 'Bands',
        icon: Icons.view_column_outlined,
        description:
            'Vibration and bearing temperature locate each asset while a piecewise risk score assigns explicit operating bands.',
      ),
      _ChartTypePreset(
        label: 'Opacity',
        icon: Icons.opacity_outlined,
        description:
            'Forecast horizon and demand locate each estimate while model confidence controls marker opacity.',
      ),
      _ChartTypePreset(
        label: 'Categories',
        icon: Icons.category_outlined,
        description:
            'One vehicle series maps powertrain categories to both color and shape.',
      ),
      _ChartTypePreset(
        label: 'Jitter',
        icon: Icons.blur_on_outlined,
        description:
            'Stable plot-space jitter reveals overlapping responses without changing raw scores.',
      ),
      _ChartTypePreset(
        label: 'Labels',
        icon: Icons.label_outline,
        description:
            'Marker-aware offsets and chart-wide collision policies keep account labels legible.',
      ),
      _ChartTypePreset(
        label: 'Selection',
        icon: Icons.select_all_outlined,
        description:
            'Tap markers or use arrow keys to focus and Enter to select. Empty primary drags stay neutral; middle-drag pans and Shift+wheel zooms.',
      ),
      _ChartTypePreset(
        label: 'Brush',
        icon: Icons.crop_free,
        description:
            'Drag a rectangle across account markers to select every enclosed point. Middle-drag still pans the viewport.',
      ),
      _ChartTypePreset(
        label: 'Lasso',
        icon: Icons.gesture,
        description:
            'Draw a free-form boundary around irregular account clusters. The live preview shows which points will be selected.',
      ),
      _ChartTypePreset(
        label: 'Regression',
        icon: Icons.show_chart,
        description:
            'A robust LOESS curve reveals the nonlinear campaign response while resisting anomalous cohorts.',
      ),
      _ChartTypePreset(
        label: 'Uncertainty',
        icon: Icons.straighten_outlined,
        description:
            'OLS confidence and prediction envelopes combine with symmetric or asymmetric X/Y measurement error.',
      ),
      _ChartTypePreset(
        label: 'Generator',
        icon: Icons.tune,
        description:
            'Generate deterministic test cohorts while controlling count, spread, correlation, outliers, and seed.',
      ),
      _ChartTypePreset(
        label: 'Clusters',
        icon: Icons.hub_outlined,
        description:
            'Dense raw observations collapse into deterministic screen-space clusters and separate again as you zoom.',
      ),
      _ChartTypePreset(
        label: 'Grid bins',
        icon: Icons.grid_view_outlined,
        description:
            'Rectangular screen cells summarize observation count with a stable opacity scale.',
      ),
      _ChartTypePreset(
        label: 'Hexbin',
        icon: Icons.hexagon_outlined,
        description:
            'Hexagonal cells reduce directional bias while preserving every raw observation for inspection.',
      ),
      _ChartTypePreset(
        label: 'Density',
        icon: Icons.layers_outlined,
        description:
            'Gaussian contours reveal concentration without replacing or mutating the source observations.',
      ),
      _ChartTypePreset(
        label: 'Marginals',
        icon: Icons.space_dashboard_outlined,
        description:
            'Viewport-linked histograms, density curves, and rug marks reveal both marginal distributions.',
      ),
    ],
  };

  bool get _isScatterSelectionPreset =>
      widget.family == _CartesianFamily.scatter &&
      _presetIndex >= 15 &&
      _presetIndex <= 17;

  bool get _isScatterRegressionPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 18;

  bool get _isScatterGeneratorPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 20;

  bool get _isScatterUncertaintyPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 19;

  bool get _isScatterClusterPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 21;

  bool get _isScatterGridBinPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 22;

  bool get _isScatterHexbinPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 23;

  bool get _isScatterBinPreset =>
      _isScatterGridBinPreset || _isScatterHexbinPreset;

  bool get _isScatterDensityPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 24;

  bool get _isScatterMarginalPreset =>
      widget.family == _CartesianFamily.scatter && _presetIndex == 25;

  ChartSelectionMode get _scatterSelectionMode => switch (_presetIndex) {
    16 => ChartSelectionMode.rectangle,
    17 => ChartSelectionMode.lasso,
    _ => ChartSelectionMode.point,
  };

  Widget _buildPresetPicker({required bool compact}) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _presetPickerTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            if (widget.family == _CartesianFamily.scatter)
              Wrap(
                key: ValueKey('${widget.family.name}-preset-picker'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var index = 0; index < _presets.length; index++)
                    ChoiceChip(
                      key: ValueKey('scatter-preset-${_presets[index].label}'),
                      showCheckmark: false,
                      selected: index == _presetIndex,
                      onSelected: (_) => _selectPreset(index),
                      avatar: Icon(
                        _presets[index].icon,
                        size: 17,
                        color: index == _presetIndex
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(_presets[index].label),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: index == _presetIndex
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: index == _presetIndex
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      selectedColor: theme.colorScheme.secondaryContainer,
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              )
            else
              SingleChildScrollView(
                controller: _presetScrollController,
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  key: ValueKey('${widget.family.name}-preset-picker'),
                  showSelectedIcon: false,
                  segments: [
                    for (var index = 0; index < _presets.length; index++)
                      ButtonSegment(
                        value: index,
                        icon: Icon(_presets[index].icon, size: 18),
                        label: Text(
                          _presets[index].label,
                          key: _presetLabelKeys.putIfAbsent(
                            index,
                            GlobalKey.new,
                          ),
                        ),
                      ),
                  ],
                  selected: {_presetIndex},
                  onSelectionChanged: (selection) {
                    _selectPreset(selection.single);
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _presets[_presetIndex].description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        final options = _optionsController.options;
        if (_isLineSynchronized) {
          final visibleMetrics = _SynchronizedMetric.values
              .where(_visibleSynchronizedMetrics.contains)
              .toList(growable: false);
          final pointsByMetric = {
            for (final metric in visibleMetrics)
              metric: _synchronizedPoints(metric),
          };
          final pointCount = visibleMetrics.fold<int>(
            0,
            (total, metric) => total + pointsByMetric[metric]!.length,
          );
          final configuredStackHeight = visibleMetrics.fold<double>(
            0,
            (total, metric) => total + (_synchronizedChartHeights[metric] ?? 0),
          );
          final chartCardHeight = (configuredStackHeight + 72)
              .clamp(360.0, 800.0)
              .toDouble();
          return Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: chartCardHeight,
                  child: ChartCard(
                    title: _presets[_presetIndex].label,
                    subtitle:
                        '${visibleMetrics.length} independent ${visibleMetrics.length == 1 ? 'chart' : 'charts'} · ${_synchronizedLiveRevision ? 'live update' : 'baseline'} · shared distance cursor + X viewport',
                    padding: const EdgeInsets.all(8),
                    child: _SynchronizedCartesianExample(
                      groupController: _interactionGroupController,
                      options: options,
                      interpolation: _interpolation,
                      strokeWidth: _strokeWidth,
                      lineGlow: _lineGlow,
                      markerRadius: _lineMarkerRadius,
                      markerStyle: _lineMarkerStyle,
                      synchronizeCursor: _synchronizeCursor,
                      synchronizeViewport: _synchronizeViewport,
                      showIntersectionMarkers: _showSynchronizedIntersections,
                      trackingEnabled: _synchronizedTracking,
                      interpolateValues: _synchronizedInterpolateValues,
                      showTrackingTooltip: _showSynchronizedTrackingTooltip,
                      showHorizontalGuide: _showSynchronizedHorizontalGuide,
                      showAxisValues: _showSynchronizedAxisValues,
                      intersectionMarkerRadius: _synchronizedIntersectionRadius,
                      visibleMetrics: visibleMetrics,
                      chartHeights: _synchronizedChartHeights,
                      pointsByMetric: pointsByMetric,
                      pathAnimation: _synchronizedPathAnimation,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SynchronizedPerformancePanel(
                  activeChartCount: visibleMetrics.length,
                  visiblePointCount: pointCount,
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  height: 304,
                  child: _SynchronizedCodeReference(),
                ),
              ],
            ),
          );
        }
        return ChartCard(
          title: _chartTitle,
          subtitle: _chartSummary,
          padding: const EdgeInsets.all(8),
          child: BravenChartWorkbench(
            key: ValueKey('${widget.family.name}-workbench'),
            chartController: _chartController,
            workbenchController: _workbenchController,
            initialDisplayMode: _initialDisplayMode,
            availableDisplayModes: const {
              ChartDisplayMode.chart,
              ChartDisplayMode.data,
              ChartDisplayMode.split,
              ChartDisplayMode.source,
            },
            documentOptions: _workbenchDocumentOptions,
            sourceOptions: ChartDartSourceOptions(
              variableName: '${widget.family.name}Chart',
            ),
            tableOptions: widget.family == _CartesianFamily.scatter
                ? const ChartTableOptions(rowLayout: ChartTableRowLayout.long)
                : const ChartTableOptions(),
            tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
            splitBreakpoint: 760,
            autoFitTablePane: true,
            minimumChartPaneExtent: 360,
            minimumTablePaneExtent: 360,
            maximumAutoTablePaneExtent: 520,
            chartBuilder: (context, controller) =>
                _buildChart(options, controller),
          ),
        );
      },
    );
  }

  ChartDocumentExtractOptions get _workbenchDocumentOptions =>
      ChartDocumentExtractOptions(
        documentId: '${widget.family.name}-showcase',
        includeViewState: true,
        interactionBindingDescriptors: _isScatterMarginalPreset
            ? {
                ChartInteractionDocumentCodec.viewportChangedBinding:
                    JsonObjectValue(const {
                      'id': JsonStringValue(
                        'showcase.scatter.marginals.viewportChanged',
                      ),
                    }),
              }
            : const {},
      );

  Widget _buildChart(ChartOptions options, BravenChartController controller) {
    final baseTheme = options.theme ?? ChartTheme.light;
    final presetTheme = _isLineSpotlight ? ChartTheme.dark : baseTheme;
    final effectiveTheme = _applyScatterThemeOverrides(presetTheme);
    if (_isScatterMarginalPreset) {
      return _ScatterMarginalExample(
        key: ValueKey(
          'scatter-marginals-$_scatterMarginalBinCount-${_scatterMarginalMode.name}-${_scatterMarginalValueMode.name}',
        ),
        controller: controller,
        series: _buildScatterSeries().cast<ScatterChartSeries>(),
        theme: effectiveTheme,
        options: options,
        binCount: _scatterMarginalBinCount,
        marginalMode: _scatterMarginalMode,
        valueMode: _scatterMarginalValueMode,
        bandwidthMultiplier: _scatterMarginalBandwidth,
        xMarginalExtent: _scatterMarginalXExtent,
        yMarginalExtent: _scatterMarginalYExtent,
        xMarginalColor:
            _scatterSeriesColorOverrides[0] ?? const Color(0xFF0EA5E9),
        yMarginalColor:
            _scatterSeriesColorOverrides[2] ?? const Color(0xFF10B981),
      );
    }
    return BravenChartPlus(
      key: ValueKey('${widget.family.name}-chart'),
      bravenChartController: controller,
      series: _buildSeries(),
      annotations: _buildAnnotations(),
      theme: effectiveTheme.copyWith(
        animationTheme: effectiveTheme.animationTheme.copyWith(
          dataUpdateDuration: Duration(milliseconds: _motionDurationMs.round()),
          dataUpdateCurve: Curves.easeInOutCubic,
        ),
      ),
      showLegend: (_isLineSpotlight || _isLineForecast || _isAreaPulse)
          ? false
          : options.showLegend,
      legendStyle: _isScatterUncertaintyPreset
          ? const LegendStyle(position: LegendPosition.topLeft)
          : null,
      showXScrollbar: options.showXScrollbar,
      showYScrollbar: options.showYScrollbar,
      grid: GridConfig(
        horizontal: options.showGrid,
        vertical: options.showGrid,
      ),
      xAxisConfig: XAxisConfig(
        label: _xAxisLabel,
        min: widget.family == _CartesianFamily.scatter
            ? switch (_presetIndex) {
                13 => 2.75,
                14 || 15 || 16 || 17 => 0,
                _ => null,
              }
            : null,
        max: widget.family == _CartesianFamily.scatter
            ? switch (_presetIndex) {
                13 => 5.25,
                14 || 15 || 16 || 17 => 10,
                _ => null,
              }
            : null,
        showAxisLine: options.showAxisLines,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: _yAxisLabel,
        min: widget.family == _CartesianFamily.scatter
            ? switch (_presetIndex) {
                13 => 2.75,
                14 || 15 || 16 || 17 => 0,
                _ => null,
              }
            : null,
        max: widget.family == _CartesianFamily.scatter
            ? switch (_presetIndex) {
                13 => 5.25,
                14 || 15 || 16 || 17 => 10,
                _ => null,
              }
            : null,
        showAxisLine: options.showAxisLines,
      ),
      normalizationMode:
          _presetIndex == 2 && widget.family == _CartesianFamily.line
          ? NormalizationMode.perSeries
          : NormalizationMode.none,
      interactionConfig: InteractionConfig(
        enableZoom: options.enableZoom,
        enablePan: options.enablePan,
        showXScrollbar: options.showXScrollbar,
        showYScrollbar: options.showYScrollbar,
        crosshair: CrosshairConfig(
          enabled: true,
          mode: _isScatterUncertaintyPreset
              ? CrosshairMode.vertical
              : CrosshairMode.both,
          snapToDataPoint: true,
          displayMode: CrosshairDisplayMode.tracking,
        ),
        tooltip: const TooltipConfig(enabled: true),
        selection: _isScatterSelectionPreset
            ? ChartSelectionConfig(
                mode: _scatterSelectionMode,
                operation: _scatterSelectionOperation,
                clearOnBackgroundTap: _scatterClearSelectionOnBackgroundTap,
              )
            : const ChartSelectionConfig(),
        onSelectionResultChanged: _isScatterSelectionPreset
            ? _handleScatterSelectionResult
            : null,
      ),
    );
  }

  ChartTheme _applyScatterThemeOverrides(ChartTheme theme) {
    if (widget.family != _CartesianFamily.scatter) return theme;
    final axisColor = _scatterAxisColorOverride;
    return theme.copyWith(
      backgroundColor: _scatterBackgroundColorOverride,
      gridStyle: _scatterGridColorOverride == null
          ? null
          : theme.gridStyle.copyWith(
              majorColor: _scatterGridColorOverride,
              minorColor: theme.gridStyle.minorColor == null
                  ? null
                  : _scatterGridColorOverride!.withValues(alpha: 0.55),
            ),
      axisStyle: axisColor == null
          ? null
          : theme.axisStyle.copyWith(
              lineColor: axisColor,
              tickColor: axisColor,
              labelStyle: theme.axisStyle.labelStyle.copyWith(color: axisColor),
              titleStyle: theme.axisStyle.titleStyle.copyWith(color: axisColor),
            ),
      interactionTheme: _scatterCrosshairColorOverride == null
          ? null
          : theme.interactionTheme.copyWith(
              crosshairColor: _scatterCrosshairColorOverride,
            ),
    );
  }

  String get _chartSummary => switch (widget.family) {
    _CartesianFamily.line =>
      _isLineForecast
          ? 'Observed + prognosis · dotted forecast · current-time boundary'
          : '${_buildSeries().length} series · ${_interpolation.name} · tracking enabled',
    _CartesianFamily.area =>
      '${_buildSeries().length} series · ${(_fillOpacity * 100).round()}% fill${_presetIndex >= 4 && _useAreaGradient ? ' · gradient' : ''} · ${_interpolation.name}',
    _CartesianFamily.scatter =>
      _presetIndex == 8
          ? 'X: revenue growth · Y: customer retention · Bubble area: active accounts · Shape: market type'
          : _presetIndex == 9
          ? 'X: weekly load · Y: 20-minute power · Marker color: recovery readiness · Shape: training block'
          : _presetIndex == 10
          ? 'X: vibration · Y: bearing temperature · Marker color: discrete risk band · Threshold equality enters the higher band'
          : _presetIndex == 11
          ? 'X: forecast horizon · Y: expected demand · Marker opacity: model confidence · Shape: forecast model'
          : _presetIndex == 12
          ? '1 series · X: daily distance · Y: operating cost · Category: powertrain · Color + shape encoding'
          : _presetIndex == 13
          ? '1 series · ${_scatterSurveyResponses.length} integer responses · ${_scatterJitterX.toStringAsFixed(0)}×${_scatterJitterY.toStringAsFixed(0)}px stable jitter · seed $_scatterJitterSeed'
          : _presetIndex == 14
          ? '2 cohorts · ${_scatterPriorityAccounts.length + _scatterMonitorAccounts.length} named accounts · ${_formatDataPointLabelPosition(_scatterLabelPosition).toLowerCase()} labels · ${_formatDataPointLabelCollisionPolicy(_scatterLabelCollisionPolicy).toLowerCase()} collisions'
          : _isScatterSelectionPreset
          ? '2 cohorts · ${_scatterPriorityAccounts.length + _scatterMonitorAccounts.length} accounts · ${_scatterSelectionMode.name} acquisition · ${_formatChartSelectionOperation(_scatterSelectionOperation).toLowerCase()} operation · ${_scatterSelectionResult.statistics.pointCount} selected'
          : _isScatterRegressionPreset
          ? '1 cohort · ${_scatterCampaignResponse.length} observations · robust LOESS · ${(_scatterLoessSpan * 100).round()}% neighborhood · $_scatterLoessRobustnessIterations robust passes'
          : _isScatterUncertaintyPreset
          ? '${_scatterAssayCalibration.length} measurements · grey bars: ${_scatterAsymmetricErrorBars ? 'asymmetric' : 'symmetric'} ${_scatterShowXErrorBars && _scatterShowYErrorBars
                ? 'X/Y error'
                : _scatterShowXErrorBars
                ? 'X error'
                : _scatterShowYErrorBars
                ? 'Y error'
                : 'hidden error'} · inner teal: ${(_scatterConfidenceLevel * 100).round()}% mean confidence · outer violet: future prediction'
          : _isScatterGeneratorPreset
          ? '$_scatterGeneratorSeriesCount generated cohorts · ${_scatterGeneratorSeriesCount * _scatterGeneratorConfig.pointCount} observations · ${_scatterGeneratorConfig.distribution.name} distribution · ${_scatterGeneratorConfig.correlation.toStringAsFixed(2)} correlation · ${(_scatterGeneratorConfig.outlierFraction * 100).round()}% outliers · seed ${_scatterGeneratorConfig.seed}'
          : _isScatterClusterPreset
          ? '$_scatterClusterPointCount raw observations · ${_scatterClusterCellSize.toStringAsFixed(0)}px screen cells · count-scaled markers · ${_scatterClusterShowZones ? 'cluster zones · ' : ''}${_scatterClusterDrillOnTap ? 'tap a cluster to drill in' : 'zoom reveals detail'}'
          : _isScatterBinPreset
          ? '$_scatterBinPointCount raw observations · ${_scatterBinCellSize.toStringAsFixed(0)}px ${_isScatterHexbinPreset ? 'hexagonal' : 'rectangular'} cells · ${_formatScatterBinAggregate(_scatterBinAggregate).toLowerCase()} aggregation${_scatterBinAggregate == ScatterBinAggregate.count || _scatterBinAggregate == ScatterBinAggregate.proportion ? '' : ' of ${_formatScatterBinValueSource(_scatterBinValueSource).toLowerCase()}'} · opacity shows magnitude · raw identities retained'
          : _isScatterDensityPreset
          ? '$_scatterDensityPointCount raw observations · $_scatterDensityContourCount Gaussian contours · ${_scatterDensityBandwidth.toStringAsFixed(0)}px bandwidth · relative-density interaction · raw identities retained'
          : _isScatterMarginalPreset
          ? '${_scatterMarginalPoints.length} athlete observations · ${_formatScatterMarginalMode(_scatterMarginalMode).toLowerCase()} · ${_scatterMarginalMode.showsHistogram ? '$_scatterMarginalBinCount bins per axis · ' : ''}${_scatterMarginalMode.showsDensity ? '${_scatterMarginalBandwidth.toStringAsFixed(2)}× automatic bandwidth · ' : ''}viewport-linked X/Y marginals'
          : '$_scatterEffectiveSeriesCount series · $_scatterRawPointCount observations · ${_presetIndex == 4 ? '${_scatterMarkerWidth.toStringAsFixed(0)}×${_scatterMarkerHeight.toStringAsFixed(0)}px styled markers' : '${_markerRadius.toStringAsFixed(0)}px markers'} · ${_presetIndex == 0 || _presetIndex == 3 || _presetIndex == 4 || _presetIndex == 7 ? 'mixed shapes' : _formatMarkerShape(_scatterMarkerShape).toLowerCase()} · ${_presetIndex == 7 ? 'selection-aware states' : 'indexed 2D tracking'}',
  };

  String get _chartTitle {
    if (widget.family != _CartesianFamily.scatter) {
      return _presets[_presetIndex].label;
    }
    return switch (_presetIndex) {
      0 => 'Olympic athlete profiles',
      1 => 'Training load and 20-minute power',
      2 => 'Glucose sensor agreement',
      3 => 'Marker shape catalogue',
      4 => 'Product channel performance',
      5 => 'Dense cohort stress test',
      6 => 'Unsorted source order',
      7 => 'Interactive point states',
      8 => 'Market opportunity map',
      9 => 'Athlete readiness map',
      10 => 'Equipment risk map',
      11 => 'Demand forecast confidence',
      12 => 'Fleet operating profile',
      13 => 'Support survey responses',
      14 => 'Customer expansion candidates',
      15 => 'Account portfolio selection',
      16 => 'Account portfolio brush',
      17 => 'Account portfolio lasso',
      18 => 'Campaign frequency response',
      19 => 'Assay calibration uncertainty',
      20 => 'Generated relationship lab',
      21 => 'Dense customer activity clusters',
      22 => 'Support demand grid',
      23 => 'Urban pickup density',
      24 => 'Urban service concentration',
      25 => 'Athlete profile with marginals',
      _ => _presets[_presetIndex].label,
    };
  }

  int get _scatterEffectiveSeriesCount => _presetIndex == 0
      ? (_showSecondSeries ? 3 : 1)
      : _presetIndex == 3
      ? _visibleScatterShapeCount
      : _presetIndex == 4
      ? 3
      : _presetIndex == 7
      ? 2
      : _presetIndex == 8
      ? 2
      : _presetIndex == 9
      ? 2
      : _presetIndex == 10
      ? 1
      : _presetIndex == 11
      ? 2
      : _presetIndex == 12
      ? 1
      : _presetIndex == 13
      ? 1
      : _presetIndex == 14
      ? 2
      : _presetIndex == 15 || _presetIndex == 16 || _presetIndex == 17
      ? 2
      : _presetIndex == 18
      ? 1
      : _presetIndex == 19
      ? 1
      : _presetIndex == 20
      ? _scatterGeneratorSeriesCount
      : _presetIndex == 21
      ? 1
      : _presetIndex == 22 || _presetIndex == 23
      ? 1
      : _presetIndex == 24
      ? 1
      : _presetIndex == 25
      ? 3
      : _presetIndex == 5 || _presetIndex == 6
      ? _scatterSeriesCount
      : (_showSecondSeries ? 2 : 1);

  int get _scatterRawPointCount {
    if (_presetIndex == 0) {
      return _scatterTriathlon.length +
          (_showSecondSeries
              ? _scatterVolleyball.length + _scatterBasketball.length
              : 0);
    }
    if (_presetIndex == 1) {
      return _scatterTrainingBase.length +
          (_showSecondSeries ? _scatterTrainingBuild.length : 0);
    }
    if (_presetIndex == 2) {
      return _scatterSensorExpected.length +
          (_showSecondSeries ? _scatterSensorReview.length : 0);
    }
    if (_presetIndex == 3) return _visibleScatterShapeCount * 12;
    if (_presetIndex == 4) return 3 * 12;
    if (_presetIndex == 5 || _presetIndex == 6) {
      return _scatterSeriesCount * _scatterPointCount;
    }
    if (_presetIndex == 7) return 24;
    if (_presetIndex == 8) {
      return _scatterEnterpriseMarkets.length + _scatterGrowthMarkets.length;
    }
    if (_presetIndex == 9) {
      return _scatterReadyAthletes.length + _scatterFatiguedAthletes.length;
    }
    if (_presetIndex == 10) return _scatterEquipmentRisk.length;
    if (_presetIndex == 11) {
      return _scatterBaselineForecast.length + _scatterAdaptiveForecast.length;
    }
    if (_presetIndex == 12) return _scatterFleetVehicles.length;
    if (_presetIndex == 13) return _scatterSurveyResponses.length;
    if (_presetIndex == 14) {
      return _scatterPriorityAccounts.length + _scatterMonitorAccounts.length;
    }
    if (_isScatterSelectionPreset) {
      return _scatterPriorityAccounts.length + _scatterMonitorAccounts.length;
    }
    if (_isScatterRegressionPreset) return _scatterCampaignResponse.length;
    if (_isScatterUncertaintyPreset) return _scatterAssayCalibration.length;
    if (_isScatterGeneratorPreset) {
      return _scatterGeneratorSeriesCount * _scatterGeneratorConfig.pointCount;
    }
    if (_isScatterClusterPreset) return _scatterClusterPointCount;
    if (_isScatterBinPreset) return _scatterBinPointCount;
    if (_isScatterDensityPreset) return _scatterDensityPointCount;
    if (_isScatterMarginalPreset) return _scatterMarginalPoints.length;
    return 0;
  }

  int get _visibleScatterShapeCount => SeriesMarkerShape.values
      .where((shape) => shape != SeriesMarkerShape.none)
      .length;

  String get _xAxisLabel => switch (widget.family) {
    _CartesianFamily.line => _isLineForecast ? 'Hour' : 'Elapsed interval',
    _CartesianFamily.area => 'Period',
    _CartesianFamily.scatter => switch (_presetIndex) {
      0 => 'Height (cm)',
      1 => 'Weekly training load (TSS)',
      2 => 'Reference glucose (mmol/L)',
      3 => 'Observation',
      4 => 'Conversion rate (%)',
      7 => 'Release week',
      8 => 'Revenue growth (%)',
      9 => 'Weekly training load (TSS)',
      10 => 'Vibration (mm/s)',
      11 => 'Forecast horizon (days)',
      12 => 'Average daily distance (km)',
      13 => 'Satisfaction score',
      14 || 15 || 16 || 17 => 'Product adoption (%)',
      18 => 'Messages per week',
      19 => 'Reference concentration (mg/L)',
      20 => 'Generated input',
      21 => 'Feature adoption (%)',
      22 || 23 => 'East–west position',
      24 => 'East–west position',
      25 => 'Height (cm)',
      _ => 'Input',
    },
  };

  String get _yAxisLabel => switch (widget.family) {
    _CartesianFamily.line => _isLineForecast ? 'Temperature (°C)' : 'Value',
    _CartesianFamily.area => 'Magnitude',
    _CartesianFamily.scatter => switch (_presetIndex) {
      0 => 'Body mass (kg)',
      1 => '20-minute power (W)',
      2 => 'Sensor reading (mmol/L)',
      3 => 'Cohort band',
      4 => 'Average order value (USD)',
      7 => 'Activation rate (%)',
      8 => 'Customer retention (%)',
      9 => '20-minute power (W)',
      10 => 'Bearing temperature (°C)',
      11 => 'Expected demand (k units)',
      12 => 'Operating cost per 100 km (USD)',
      13 => 'Ease score',
      14 || 15 || 16 || 17 => 'Revenue growth (%)',
      18 => 'Conversion lift (%)',
      19 => 'Measured response (AU)',
      20 => 'Generated outcome',
      21 => 'Account expansion (%)',
      22 || 23 => 'North–south position',
      24 => 'North–south position',
      25 => 'Body mass (kg)',
      _ => 'Outcome',
    },
  };

  List<Widget> _buildOptions() {
    final typeOptions = <Widget>[
      if (widget.family != _CartesianFamily.scatter &&
          !_isLineSpotlight &&
          !_isAreaPulse)
        EnumOption<LineInterpolation>(
          label: 'Interpolation',
          value: _interpolation,
          values: LineInterpolation.values,
          onChanged: (value) => setState(() => _interpolation = value),
        ),
      if (widget.family != _CartesianFamily.scatter &&
          !_isLineSpotlight &&
          !_isAreaPulse)
        SliderOption(
          label: 'Stroke width',
          value: _strokeWidth,
          min: 1,
          max: 5,
          divisions: 8,
          suffix: 'px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _strokeWidth = value),
        ),
      if (widget.family != _CartesianFamily.scatter &&
          !_isLineSpotlight &&
          !_isAreaPulse)
        SliderOption(
          label: 'Line glow',
          value: _lineGlow,
          min: 0,
          max: 10,
          divisions: 10,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _lineGlow = value),
        ),
      if (widget.family == _CartesianFamily.area)
        SliderOption(
          label: 'Fill opacity',
          value: _fillOpacity,
          min: 0.05,
          max: 0.8,
          divisions: 15,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _fillOpacity = value),
        ),
      if (widget.family == _CartesianFamily.scatter &&
          _presetIndex != 4 &&
          _presetIndex != 8 &&
          !_isScatterBinPreset &&
          !_isScatterDensityPreset)
        SliderOption(
          label: 'Marker radius',
          value: _markerRadius,
          min: 2,
          max: 10,
          divisions: 8,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _markerRadius = value),
        ),
      if (widget.family == _CartesianFamily.line && !_isLineForecast)
        EnumOption<DataPointMarkerStyle>(
          key: const ValueKey('line-marker-style'),
          label: 'Marker style',
          value: _lineMarkerStyle,
          values: DataPointMarkerStyle.values,
          labelBuilder: (value) => switch (value) {
            DataPointMarkerStyle.filled => 'Filled',
            DataPointMarkerStyle.hollow => 'Hollow',
          },
          onChanged: (value) => setState(() => _lineMarkerStyle = value),
        ),
      if (widget.family == _CartesianFamily.line)
        SliderOption(
          key: const ValueKey('line-marker-radius'),
          label: 'Marker radius',
          value: _lineMarkerRadius,
          min: 2,
          max: 7,
          divisions: 10,
          suffix: 'px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _lineMarkerRadius = value),
        ),
      if (widget.family == _CartesianFamily.scatter &&
          _presetIndex != 0 &&
          _presetIndex != 3 &&
          _presetIndex != 4 &&
          _presetIndex != 7 &&
          _presetIndex != 8 &&
          _presetIndex != 9 &&
          _presetIndex != 10 &&
          _presetIndex != 11 &&
          _presetIndex != 12 &&
          _presetIndex != 13 &&
          _presetIndex != 14 &&
          !_isScatterBinPreset)
        EnumOption<SeriesMarkerShape>(
          label: 'Marker shape',
          value: _scatterMarkerShape,
          values: SeriesMarkerShape.values
              .where((shape) => shape != SeriesMarkerShape.none)
              .toList(),
          labelBuilder: _formatMarkerShape,
          onChanged: (value) => setState(() => _scatterMarkerShape = value),
        ),
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 4) ...[
        EnumOption<_ScatterFillTone>(
          label: 'Fill tone',
          value: _scatterFillTone,
          values: _ScatterFillTone.values,
          labelBuilder: _formatScatterFillTone,
          onChanged: (value) => setState(() => _scatterFillTone = value),
        ),
        SliderOption(
          label: 'Marker width',
          value: _scatterMarkerWidth,
          min: 4,
          max: 28,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterMarkerWidth = value),
        ),
        SliderOption(
          label: 'Marker height',
          value: _scatterMarkerHeight,
          min: 4,
          max: 28,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterMarkerHeight = value),
        ),
        SliderOption(
          label: 'Outline width',
          value: _scatterMarkerStrokeWidth,
          min: 0,
          max: 6,
          divisions: 6,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) =>
              setState(() => _scatterMarkerStrokeWidth = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-styling-opacity'),
          label: 'Opacity',
          value: _scatterMarkerOpacity,
          min: 0.2,
          max: 1,
          divisions: 8,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _scatterMarkerOpacity = value),
        ),
        SliderOption(
          label: 'Rotation',
          value: _scatterMarkerRotation,
          min: 0,
          max: 180,
          divisions: 12,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterMarkerRotation = value),
        ),
      ],
      if (widget.family == _CartesianFamily.scatter &&
          (_presetIndex == 5 || _presetIndex == 6))
        EnumOption<int>(
          label: 'Points per series',
          value: _scatterPointCount,
          values: const [100, 1000, 10000, 50000, 100000],
          labelBuilder: _formatPointCount,
          onChanged: (value) => setState(() => _scatterPointCount = value),
        ),
      if (widget.family == _CartesianFamily.scatter &&
          (_presetIndex == 5 || _presetIndex == 6))
        IntSliderOption(
          label: 'Series count',
          value: _scatterSeriesCount,
          min: 1,
          max: 6,
          onChanged: (value) => setState(() => _scatterSeriesCount = value),
        ),
      if (!_isLineForecast &&
          !_isLineSynchronized &&
          (widget.family != _CartesianFamily.scatter || _presetIndex < 3))
        BoolOption(
          label: widget.family == _CartesianFamily.scatter
              ? switch (_presetIndex) {
                  0 => 'Show comparison sports',
                  1 => 'Show build block',
                  2 => 'Show review readings',
                  _ => 'Show second cohort',
                }
              : 'Show second series',
          value: _showSecondSeries,
          onChanged: (value) => setState(() => _showSecondSeries = value),
        ),
      if (widget.family != _CartesianFamily.scatter && !_isLineSynchronized)
        BoolOption(
          label: 'Show point labels',
          value: _showPointLabels,
          onChanged: (value) => setState(() => _showPointLabels = value),
        ),
      if (widget.family == _CartesianFamily.area && _presetIndex == 1)
        BoolOption(
          label: 'Use baseline fills',
          value: _showBaselineFill,
          onChanged: (value) => setState(() => _showBaselineFill = value),
          subtitle: 'Apply positive and negative fills in the baseline preset',
        ),
      if (widget.family == _CartesianFamily.area && _presetIndex >= 4)
        BoolOption(
          key: const ValueKey('area-gradient-fill'),
          label: 'Gradient fill',
          value: _useAreaGradient,
          onChanged: (value) => setState(() => _useAreaGradient = value),
          subtitle: 'Blend configured colors across the plot',
        ),
      if (widget.family == _CartesianFamily.scatter &&
          (_presetIndex == 7 || _isScatterSelectionPreset)) ...[
        SliderOption(
          key: const ValueKey('scatter-selection-scale'),
          label: 'Selection scale',
          value: _scatterSelectionScale,
          min: 1,
          max: 2,
          divisions: 10,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _scatterSelectionScale = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-selection-stroke-width'),
          label: 'Selection ring',
          value: _scatterSelectionStrokeWidth,
          min: 1,
          max: 6,
          divisions: 10,
          suffix: 'px',
          decimalPlaces: 1,
          onChanged: (value) =>
              setState(() => _scatterSelectionStrokeWidth = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-unselected-opacity'),
          label: 'Unselected opacity',
          value: _scatterDimmedOpacity,
          min: 0.1,
          max: 1,
          divisions: 9,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _scatterDimmedOpacity = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-focus-ring-gap'),
          label: 'Focus ring gap',
          value: _scatterFocusGap,
          min: 1,
          max: 10,
          divisions: 9,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterFocusGap = value),
        ),
      ],
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 8) ...[
        SliderOption(
          key: const ValueKey('scatter-bubble-minimum-radius'),
          label: 'Small bubble',
          value: _scatterBubbleMinimumRadius,
          min: 2,
          max: 10,
          divisions: 8,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) =>
              setState(() => _scatterBubbleMinimumRadius = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-bubble-maximum-radius'),
          label: 'Large bubble',
          value: _scatterBubbleMaximumRadius,
          min: 12,
          max: 36,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) =>
              setState(() => _scatterBubbleMaximumRadius = value),
        ),
      ],
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 9)
        EnumOption<_ScatterColorRamp>(
          key: const ValueKey('scatter-color-ramp'),
          label: 'Color ramp',
          value: _scatterColorRamp,
          values: _ScatterColorRamp.values,
          labelBuilder: (value) => switch (value) {
            _ScatterColorRamp.readiness => 'Readiness',
            _ScatterColorRamp.thermal => 'Thermal',
            _ScatterColorRamp.coolWarm => 'Cool–warm',
          },
          onChanged: (value) => setState(() => _scatterColorRamp = value),
        ),
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 10)
        EnumOption<_ScatterRiskPalette>(
          key: const ValueKey('scatter-risk-palette'),
          label: 'Band palette',
          value: _scatterRiskPalette,
          values: _ScatterRiskPalette.values,
          labelBuilder: (value) => switch (value) {
            _ScatterRiskPalette.safety => 'Safety',
            _ScatterRiskPalette.thermal => 'Thermal',
            _ScatterRiskPalette.service => 'Service',
          },
          onChanged: (value) => setState(() => _scatterRiskPalette = value),
        ),
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 11)
        SliderOption(
          key: const ValueKey('scatter-minimum-opacity'),
          label: 'Low-confidence opacity',
          value: _scatterMinimumOpacity,
          min: 0.05,
          max: 0.6,
          divisions: 11,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _scatterMinimumOpacity = value),
        ),
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 12)
        EnumOption<_ScatterCategoryPalette>(
          key: const ValueKey('scatter-category-palette'),
          label: 'Category palette',
          value: _scatterCategoryPalette,
          values: _ScatterCategoryPalette.values,
          labelBuilder: (value) => switch (value) {
            _ScatterCategoryPalette.mobility => 'Mobility',
            _ScatterCategoryPalette.accessible => 'Accessible',
          },
          onChanged: (value) => setState(() => _scatterCategoryPalette = value),
        ),
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 13) ...[
        SliderOption(
          key: const ValueKey('scatter-jitter-x'),
          label: 'Horizontal spread',
          value: _scatterJitterX,
          min: 0,
          max: 64,
          divisions: 32,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterJitterX = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-jitter-y'),
          label: 'Vertical spread',
          value: _scatterJitterY,
          min: 0,
          max: 64,
          divisions: 32,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterJitterY = value),
        ),
        IntSliderOption(
          key: const ValueKey('scatter-jitter-seed'),
          label: 'Layout seed',
          value: _scatterJitterSeed,
          min: 0,
          max: 24,
          onChanged: (value) => setState(() => _scatterJitterSeed = value),
        ),
      ],
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 14) ...[
        EnumOption<DataPointLabelPosition>(
          key: const ValueKey('scatter-label-position'),
          label: 'Label anchor',
          value: _scatterLabelPosition,
          values: DataPointLabelPosition.values,
          labelBuilder: _formatDataPointLabelPosition,
          onChanged: (value) => setState(() => _scatterLabelPosition = value),
        ),
        EnumOption<DataPointLabelCollisionPolicy>(
          key: const ValueKey('scatter-label-collision'),
          label: 'Overlapping labels',
          value: _scatterLabelCollisionPolicy,
          values: DataPointLabelCollisionPolicy.values,
          labelBuilder: _formatDataPointLabelCollisionPolicy,
          onChanged: (value) =>
              setState(() => _scatterLabelCollisionPolicy = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-label-offset-x'),
          label: 'Horizontal offset',
          value: _scatterLabelOffsetX,
          min: -16,
          max: 16,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterLabelOffsetX = value),
        ),
        SliderOption(
          key: const ValueKey('scatter-label-offset-y'),
          label: 'Vertical offset',
          value: _scatterLabelOffsetY,
          min: -16,
          max: 16,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _scatterLabelOffsetY = value),
        ),
      ],
      if (_isScatterRegressionPreset) ...[
        SliderOption(
          key: const ValueKey('scatter-loess-span'),
          label: 'Neighborhood',
          value: _scatterLoessSpan,
          min: 0.2,
          max: 1,
          divisions: 16,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _scatterLoessSpan = value),
        ),
        IntSliderOption(
          key: const ValueKey('scatter-loess-robustness'),
          label: 'Robust passes',
          value: _scatterLoessRobustnessIterations,
          min: 0,
          max: 4,
          onChanged: (value) =>
              setState(() => _scatterLoessRobustnessIterations = value),
        ),
        EnumOption<int>(
          key: const ValueKey('scatter-loess-samples'),
          label: 'Curve detail',
          value: _scatterLoessSampleCount,
          values: const [40, 80, 120, 160, 200],
          labelBuilder: (value) => '$value points',
          onChanged: (value) =>
              setState(() => _scatterLoessSampleCount = value),
        ),
      ],
      if (_isScatterUncertaintyPreset) ...[
        SliderOption(
          key: const ValueKey('scatter-uncertainty-error-scale'),
          label: 'Error magnitude',
          value: _scatterErrorScale,
          min: 0.25,
          max: 2,
          divisions: 7,
          suffix: '×',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _scatterErrorScale = value),
        ),
      ],
      if (_isScatterSelectionPreset) ...[
        EnumOption<ChartSelectionOperation>(
          key: const ValueKey('scatter-selection-operation'),
          label: 'Selection operation',
          value: _scatterSelectionOperation,
          values: ChartSelectionOperation.values,
          labelBuilder: _formatChartSelectionOperation,
          onChanged: (value) =>
              setState(() => _scatterSelectionOperation = value),
        ),
        BoolOption(
          key: const ValueKey('scatter-selection-background-clear'),
          label: 'Clear on background tap',
          value: _scatterClearSelectionOnBackgroundTap,
          subtitle: 'Keep the current selection when this is off',
          onChanged: (value) =>
              setState(() => _scatterClearSelectionOnBackgroundTap = value),
        ),
      ],
    ];

    return [
      OptionSection(
        title: '${_pageTitle.replaceAll(' Charts', '')} options',
        icon: switch (widget.family) {
          _CartesianFamily.line => Icons.show_chart,
          _CartesianFamily.area => Icons.area_chart_outlined,
          _CartesianFamily.scatter => Icons.scatter_plot_outlined,
        },
        children: typeOptions,
      ),
      if (_isScatterClusterPreset)
        OptionSection(
          title: 'Cluster layout',
          icon: Icons.hub_outlined,
          children: [
            EnumOption<int>(
              key: const ValueKey('scatter-cluster-point-count'),
              label: 'Raw observations',
              value: _scatterClusterPointCount,
              values: const [1000, 5000, 10000, 25000, 50000, 100000],
              labelBuilder: _formatPointCount,
              onChanged: (value) =>
                  setState(() => _scatterClusterPointCount = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-cluster-cell-size'),
              label: 'Aggregation cell',
              value: _scatterClusterCellSize,
              min: 20,
              max: 80,
              divisions: 15,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _scatterClusterCellSize = value),
            ),
            IntSliderOption(
              key: const ValueKey('scatter-cluster-minimum-points'),
              label: 'Minimum cluster size',
              value: _scatterClusterMinimumPoints,
              min: 2,
              max: 12,
              onChanged: (value) =>
                  setState(() => _scatterClusterMinimumPoints = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-cluster-minimum-radius'),
              label: 'Small cluster',
              value: _scatterClusterMinimumRadius,
              min: 4,
              max: 16,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _scatterClusterMinimumRadius = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-cluster-maximum-radius'),
              label: 'Large cluster',
              value: _scatterClusterMaximumRadius,
              min: 18,
              max: 42,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _scatterClusterMaximumRadius = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-cluster-count-labels'),
              label: 'Count labels',
              subtitle: 'Show raw observation counts inside cluster markers',
              value: _scatterClusterShowLabels,
              onChanged: (value) =>
                  setState(() => _scatterClusterShowLabels = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-cluster-zones'),
              label: 'Cluster zones',
              subtitle: 'Reveal the source-marker extent behind each cluster',
              value: _scatterClusterShowZones,
              onChanged: (value) =>
                  setState(() => _scatterClusterShowZones = value),
            ),
            if (_scatterClusterShowZones)
              SliderOption(
                key: const ValueKey('scatter-cluster-zone-opacity'),
                label: 'Zone opacity',
                value: _scatterClusterZoneOpacity,
                min: 0.04,
                max: 0.24,
                divisions: 10,
                decimalPlaces: 2,
                onChanged: (value) =>
                    setState(() => _scatterClusterZoneOpacity = value),
              ),
            BoolOption(
              key: const ValueKey('scatter-cluster-drill-on-tap'),
              label: 'Tap to drill',
              subtitle: 'Zoom to the raw observations represented by a cluster',
              value: _scatterClusterDrillOnTap,
              onChanged: (value) =>
                  setState(() => _scatterClusterDrillOnTap = value),
            ),
            if (_scatterClusterDrillOnTap)
              SliderOption(
                key: const ValueKey('scatter-cluster-drill-padding'),
                label: 'Drill padding',
                value: _scatterClusterDrillPadding,
                min: 0,
                max: 0.5,
                divisions: 10,
                suffix: '×',
                decimalPlaces: 2,
                onChanged: (value) =>
                    setState(() => _scatterClusterDrillPadding = value),
              ),
          ],
        ),
      if (_isScatterBinPreset)
        OptionSection(
          title: '2D bin layout',
          icon: _isScatterHexbinPreset
              ? Icons.hexagon_outlined
              : Icons.grid_view_outlined,
          children: [
            EnumOption<ScatterBinAggregate>(
              key: const ValueKey('scatter-bin-aggregate'),
              label: 'Aggregate',
              value: _scatterBinAggregate,
              values: ScatterBinAggregate.values,
              labelBuilder: _formatScatterBinAggregate,
              onChanged: (value) => setState(() {
                _scatterBinAggregate = value;
                if (value == ScatterBinAggregate.count ||
                    value == ScatterBinAggregate.proportion) {
                  _scatterBinValueSource = ScatterBinValueSource.y;
                }
              }),
            ),
            if (_scatterBinAggregate != ScatterBinAggregate.count &&
                _scatterBinAggregate != ScatterBinAggregate.proportion)
              EnumOption<ScatterBinValueSource>(
                key: const ValueKey('scatter-bin-value-source'),
                label: 'Value',
                value: _scatterBinValueSource,
                values: const [
                  ScatterBinValueSource.x,
                  ScatterBinValueSource.y,
                ],
                labelBuilder: _formatScatterBinValueSource,
                onChanged: (value) =>
                    setState(() => _scatterBinValueSource = value),
              ),
            EnumOption<int>(
              key: const ValueKey('scatter-bin-point-count'),
              label: 'Raw observations',
              value: _scatterBinPointCount,
              values: const [1000, 5000, 10000, 25000, 50000, 100000],
              labelBuilder: _formatPointCount,
              onChanged: (value) =>
                  setState(() => _scatterBinPointCount = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-bin-cell-size'),
              label: 'Cell size',
              value: _scatterBinCellSize,
              min: 16,
              max: 80,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _scatterBinCellSize = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-bin-gap'),
              label: 'Cell gap',
              value: _scatterBinGap,
              min: 0,
              max: 6,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _scatterBinGap = value),
            ),
            IntSliderOption(
              key: const ValueKey('scatter-bin-minimum-points'),
              label: 'Minimum bin count',
              value: _scatterBinMinimumPoints,
              min: 1,
              max: 20,
              onChanged: (value) =>
                  setState(() => _scatterBinMinimumPoints = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-bin-minimum-opacity'),
              label: _scatterBinAggregate == ScatterBinAggregate.count
                  ? 'Low-count opacity'
                  : 'Low-value opacity',
              value: _scatterBinMinimumOpacity,
              min: 0.05,
              max: 0.55,
              divisions: 10,
              decimalPlaces: 2,
              onChanged: (value) => setState(() {
                _scatterBinMinimumOpacity = math.min(
                  value,
                  _scatterBinMaximumOpacity,
                );
              }),
            ),
            SliderOption(
              key: const ValueKey('scatter-bin-maximum-opacity'),
              label: _scatterBinAggregate == ScatterBinAggregate.count
                  ? 'High-count opacity'
                  : 'High-value opacity',
              value: _scatterBinMaximumOpacity,
              min: 0.55,
              max: 1,
              divisions: 9,
              decimalPlaces: 2,
              onChanged: (value) => setState(() {
                _scatterBinMaximumOpacity = math.max(
                  value,
                  _scatterBinMinimumOpacity,
                );
              }),
            ),
            BoolOption(
              key: const ValueKey('scatter-bin-count-labels'),
              label: 'Bin labels',
              subtitle:
                  'Show aggregate values only in bins meeting the threshold',
              value: _scatterBinShowLabels,
              onChanged: (value) =>
                  setState(() => _scatterBinShowLabels = value),
            ),
            if (_scatterBinShowLabels)
              IntSliderOption(
                key: const ValueKey('scatter-bin-label-minimum-points'),
                label: 'Label threshold',
                value: _scatterBinLabelMinimumPoints,
                min: 2,
                max: 100,
                onChanged: (value) =>
                    setState(() => _scatterBinLabelMinimumPoints = value),
              ),
          ],
        ),
      if (_isScatterDensityPreset)
        OptionSection(
          title: 'Density contours',
          icon: Icons.layers_outlined,
          children: [
            EnumOption<int>(
              key: const ValueKey('scatter-density-point-count'),
              label: 'Raw observations',
              value: _scatterDensityPointCount,
              values: const [1000, 5000, 10000, 25000, 50000, 100000],
              labelBuilder: _formatPointCount,
              onChanged: (value) =>
                  setState(() => _scatterDensityPointCount = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-density-bandwidth'),
              label: 'Smoothing radius',
              value: _scatterDensityBandwidth,
              min: 8,
              max: 96,
              divisions: 22,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _scatterDensityBandwidth = value),
            ),
            IntSliderOption(
              key: const ValueKey('scatter-density-contour-count'),
              label: 'Contour levels',
              value: _scatterDensityContourCount,
              min: 2,
              max: 12,
              onChanged: (value) =>
                  setState(() => _scatterDensityContourCount = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-density-minimum'),
              label: 'Outer threshold',
              value: _scatterDensityMinimum,
              min: 0.02,
              max: 0.4,
              divisions: 19,
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _scatterDensityMinimum = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-density-line-width'),
              label: 'Contour width',
              value: _scatterDensityLineWidth,
              min: 0.5,
              max: 4,
              divisions: 14,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) =>
                  setState(() => _scatterDensityLineWidth = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-density-show-points'),
              label: 'Show raw points',
              subtitle: 'Overlay source markers above the contour family',
              value: _scatterDensityShowPoints,
              onChanged: (value) =>
                  setState(() => _scatterDensityShowPoints = value),
            ),
            if (_scatterDensityShowPoints)
              SliderOption(
                key: const ValueKey('scatter-density-marker-radius'),
                label: 'Point radius',
                value: _markerRadius,
                min: 1,
                max: 6,
                divisions: 10,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _markerRadius = value),
              ),
          ],
        ),
      if (_isScatterMarginalPreset)
        OptionSection(
          title: 'Marginal distributions',
          icon: Icons.space_dashboard_outlined,
          children: [
            EnumOption<ScatterMarginalMode>(
              key: const ValueKey('scatter-marginal-mode'),
              label: 'Display',
              value: _scatterMarginalMode,
              values: ScatterMarginalMode.values,
              labelBuilder: _formatScatterMarginalMode,
              onChanged: (value) =>
                  setState(() => _scatterMarginalMode = value),
            ),
            if (_scatterMarginalMode.showsHistogram)
              IntSliderOption(
                key: const ValueKey('scatter-marginal-bin-count'),
                label: 'Bins per axis',
                value: _scatterMarginalBinCount,
                min: 4,
                max: 24,
                onChanged: (value) =>
                    setState(() => _scatterMarginalBinCount = value),
              ),
            if (_scatterMarginalMode == ScatterMarginalMode.histogram)
              EnumOption<HistogramValueMode>(
                key: const ValueKey('scatter-marginal-value-mode'),
                label: 'Bar value',
                value: _scatterMarginalValueMode,
                values: HistogramValueMode.values,
                labelBuilder: _formatHistogramValueMode,
                onChanged: (value) =>
                    setState(() => _scatterMarginalValueMode = value),
              ),
            if (_scatterMarginalMode.showsDensity)
              SliderOption(
                key: const ValueKey('scatter-marginal-bandwidth'),
                label: 'Density smoothing',
                value: _scatterMarginalBandwidth,
                min: 0.5,
                max: 2,
                divisions: 12,
                suffix: '×',
                decimalPlaces: 2,
                onChanged: (value) =>
                    setState(() => _scatterMarginalBandwidth = value),
              ),
            SliderOption(
              key: const ValueKey('scatter-marginal-x-extent'),
              label: 'Top panel height',
              value: _scatterMarginalXExtent,
              min: 128,
              max: 192,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _scatterMarginalXExtent = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-marginal-y-extent'),
              label: 'Side panel width',
              value: _scatterMarginalYExtent,
              min: 96,
              max: 220,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _scatterMarginalYExtent = value),
            ),
          ],
        ),
      if (_isScatterGeneratorPreset)
        OptionSection(
          title: 'Point generator',
          icon: Icons.tune,
          children: [
            EnumOption<ScatterPointDistribution>(
              key: const ValueKey('scatter-generator-distribution'),
              label: 'Distribution',
              value: _scatterGeneratorConfig.distribution,
              values: ScatterPointDistribution.values,
              labelBuilder: (value) => switch (value) {
                ScatterPointDistribution.uniform => 'Uniform',
                ScatterPointDistribution.normal => 'Normal',
                ScatterPointDistribution.clustered => 'Two clusters',
              },
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  distribution: value,
                );
              }),
            ),
            EnumOption<int>(
              key: const ValueKey('scatter-generator-point-count'),
              label: 'Points per cohort',
              value: _scatterGeneratorConfig.pointCount,
              values: const [25, 50, 100, 250, 500, 1000, 5000, 10000],
              labelBuilder: _formatPointCount,
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  pointCount: value,
                );
              }),
            ),
            IntSliderOption(
              key: const ValueKey('scatter-generator-series-count'),
              label: 'Cohort count',
              value: _scatterGeneratorSeriesCount,
              min: 1,
              max: 6,
              onChanged: (value) =>
                  setState(() => _scatterGeneratorSeriesCount = value),
            ),
            SliderOption(
              key: const ValueKey('scatter-generator-x-spread'),
              label: 'Horizontal spread',
              value: _scatterGeneratorConfig.xSpread,
              min: 10,
              max: 120,
              divisions: 22,
              decimalPlaces: 0,
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  xSpread: value,
                );
              }),
            ),
            SliderOption(
              key: const ValueKey('scatter-generator-y-spread'),
              label: 'Vertical spread',
              value: _scatterGeneratorConfig.ySpread,
              min: 10,
              max: 120,
              divisions: 22,
              decimalPlaces: 0,
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  ySpread: value,
                );
              }),
            ),
            SliderOption(
              key: const ValueKey('scatter-generator-correlation'),
              label: 'Correlation',
              value: _scatterGeneratorConfig.correlation,
              min: -1,
              max: 1,
              divisions: 20,
              decimalPlaces: 2,
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  correlation: value,
                );
              }),
            ),
            SliderOption(
              key: const ValueKey('scatter-generator-outliers'),
              label: 'Outlier rate',
              value: _scatterGeneratorConfig.outlierFraction * 100,
              min: 0,
              max: 20,
              divisions: 20,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  outlierFraction: value / 100,
                );
              }),
            ),
            IntSliderOption(
              key: const ValueKey('scatter-generator-seed'),
              label: 'Seed',
              value: _scatterGeneratorConfig.seed,
              min: 0,
              max: 99,
              onChanged: (value) => setState(() {
                _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                  seed: value,
                );
              }),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('scatter-generator-regenerate'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => setState(() {
                  _scatterGeneratorConfig = _scatterGeneratorConfig.copyWith(
                    seed: (_scatterGeneratorConfig.seed + 1) % 100,
                  );
                }),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerate points'),
              ),
            ),
          ],
        ),
      if (_isScatterRegressionPreset)
        OptionSection(
          title: 'Regression diagnostics',
          icon: Icons.functions,
          children: [
            BoolOption(
              key: const ValueKey('scatter-regression-show-equation'),
              label: 'Equation',
              value: _scatterShowEquation,
              onChanged: (value) =>
                  setState(() => _scatterShowEquation = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-regression-show-r-squared'),
              label: 'R²',
              value: _scatterShowRSquared,
              onChanged: (value) =>
                  setState(() => _scatterShowRSquared = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-regression-show-sample-count'),
              label: 'Sample count',
              value: _scatterShowSampleCount,
              onChanged: (value) =>
                  setState(() => _scatterShowSampleCount = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-regression-show-pearson'),
              label: 'Pearson r',
              value: _scatterShowPearsonCorrelation,
              onChanged: (value) =>
                  setState(() => _scatterShowPearsonCorrelation = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-regression-show-spearman'),
              label: 'Spearman ρ',
              value: _scatterShowSpearmanCorrelation,
              onChanged: (value) =>
                  setState(() => _scatterShowSpearmanCorrelation = value),
            ),
          ],
        ),
      if (_isScatterUncertaintyPreset)
        OptionSection(
          title: 'Uncertainty model',
          icon: Icons.straighten_outlined,
          children: [
            BoolOption(
              key: const ValueKey('scatter-uncertainty-confidence-band'),
              label: 'Mean confidence band',
              subtitle: 'Interval for the fitted mean response',
              value: _scatterShowConfidenceBand,
              onChanged: (value) =>
                  setState(() => _scatterShowConfidenceBand = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-uncertainty-prediction-band'),
              label: 'Future prediction band',
              subtitle: 'Interval for one future observation',
              value: _scatterShowPredictionBand,
              onChanged: (value) =>
                  setState(() => _scatterShowPredictionBand = value),
            ),
            EnumOption<double>(
              key: const ValueKey('scatter-uncertainty-confidence-level'),
              label: 'Interval coverage',
              value: _scatterConfidenceLevel,
              values: const [0.90, 0.95, 0.99],
              labelBuilder: (value) => '${(value * 100).round()}%',
              onChanged: (value) =>
                  setState(() => _scatterConfidenceLevel = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-uncertainty-x-errors'),
              label: 'Horizontal error bars',
              subtitle: 'Reference concentration uncertainty',
              value: _scatterShowXErrorBars,
              onChanged: (value) =>
                  setState(() => _scatterShowXErrorBars = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-uncertainty-y-errors'),
              label: 'Vertical error bars',
              subtitle: 'Measured response uncertainty',
              value: _scatterShowYErrorBars,
              onChanged: (value) =>
                  setState(() => _scatterShowYErrorBars = value),
            ),
            BoolOption(
              key: const ValueKey('scatter-uncertainty-asymmetric'),
              label: 'Asymmetric sides',
              subtitle: 'Use independent negative and positive magnitudes',
              value: _scatterAsymmetricErrorBars,
              onChanged: (value) =>
                  setState(() => _scatterAsymmetricErrorBars = value),
            ),
          ],
        ),
      if (_isLineSynchronized)
        StandardChartOptions(
          controller: _optionsController,
          showLegendOption: false,
          showYScrollbarOption: false,
          showLineStyleOption: false,
        ),
      if (_isLineSynchronized)
        OptionSection(
          title: 'Chart composition',
          icon: Icons.view_stream_outlined,
          initiallyExpanded: false,
          children: [
            EnumOption<_SynchronizedDatasetProfile>(
              key: const ValueKey('synchronized-dataset-profile'),
              label: 'Dataset profile',
              value: _synchronizedDatasetProfile,
              values: _SynchronizedDatasetProfile.values,
              labelBuilder: _synchronizedProfileLabel,
              subtitle: _synchronizedProfileSummary(
                _synchronizedDatasetProfile,
              ),
              onChanged: (profile) {
                _ensureSynchronizedProfileCached(profile);
                if (_synchronizedLiveRevision) {
                  _ensureSynchronizedUpdateCached(profile);
                }
                _interactionGroupController.reset();
                setState(() => _synchronizedDatasetProfile = profile);
              },
            ),
            for (final metric in _SynchronizedMetric.values) ...[
              BoolOption(
                key: ValueKey('synchronized-${metric.name}-visible'),
                label: '${_synchronizedMetricLabel(metric)} chart',
                value: _visibleSynchronizedMetrics.contains(metric),
                subtitle: _visibleSynchronizedMetrics.contains(metric)
                    ? '${_synchronizedPoints(metric).length} points · mounted in the shared group'
                    : 'Removed from the shared group',
                onChanged: (value) {
                  _interactionGroupController.reset();
                  setState(() {
                    if (value) {
                      _visibleSynchronizedMetrics.add(metric);
                    } else {
                      _visibleSynchronizedMetrics.remove(metric);
                    }
                  });
                },
              ),
              if (_visibleSynchronizedMetrics.contains(metric))
                SliderOption(
                  key: ValueKey('synchronized-${metric.name}-height'),
                  label: '${_synchronizedMetricLabel(metric)} height',
                  value: _synchronizedChartHeights[metric]!,
                  min: 176,
                  max: 400,
                  divisions: 14,
                  suffix: 'px',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _synchronizedChartHeights[metric] = value),
                ),
            ],
          ],
        ),
      if (_isLineSynchronized)
        OptionSection(
          title: 'Data updates',
          icon: Icons.update_outlined,
          initiallyExpanded: false,
          children: [
            Text(
              _synchronizedLiveRevision
                  ? 'Current state · Live revision'
                  : 'Current state · Baseline',
              key: const ValueKey('synchronized-data-state'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                key: const ValueKey('synchronized-update-data'),
                onPressed: _toggleSynchronizedDataRevision,
                icon: Icon(
                  _synchronizedLiveRevision
                      ? Icons.undo_outlined
                      : Icons.auto_graph_outlined,
                  size: 18,
                ),
                label: Text(
                  _synchronizedLiveRevision
                      ? 'Restore baseline'
                      : 'Apply live update',
                ),
              ),
            ),
            const SizedBox(height: 16),
            BoolOption(
              key: const ValueKey('animate-synchronized-updates'),
              label: 'Animate data updates',
              value: _animateSynchronizedUpdates,
              subtitle: 'Use native Line and Area geometry interpolation',
              onChanged: (value) =>
                  setState(() => _animateSynchronizedUpdates = value),
            ),
            if (_animateSynchronizedUpdates)
              SliderOption(
                key: const ValueKey('synchronized-update-duration'),
                label: 'Update duration',
                value: _synchronizedUpdateDurationMs,
                min: 200,
                max: 1500,
                divisions: 13,
                suffix: 'ms',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _synchronizedUpdateDurationMs = value),
              ),
          ],
        ),
      if (_isLineSynchronized)
        OptionSection(
          title: 'Synchronization',
          icon: Icons.sync_alt,
          children: [
            BoolOption(
              key: const ValueKey('synchronized-tracking'),
              label: 'Crosshair tracking',
              value: _synchronizedTracking,
              subtitle: 'Show X/Y guides, axis values, and the value tooltip',
              onChanged: (value) {
                _interactionGroupController.reset();
                setState(() => _synchronizedTracking = value);
              },
            ),
            BoolOption(
              key: const ValueKey('synchronize-cursor'),
              label: 'Synchronize cursor',
              value: _synchronizeCursor,
              subtitle: 'Share the active data-X position across all plots',
              onChanged: (value) {
                _interactionGroupController.reset();
                setState(() => _synchronizeCursor = value);
              },
            ),
            BoolOption(
              key: const ValueKey('synchronize-viewport'),
              label: 'Synchronize viewport',
              value: _synchronizeViewport,
              subtitle: 'Share horizontal pan, zoom, and reset bounds',
              onChanged: (value) {
                _interactionGroupController.reset();
                setState(() => _synchronizeViewport = value);
              },
            ),
            BoolOption(
              key: const ValueKey('synchronized-intersections'),
              label: 'Show intersections',
              value: _showSynchronizedIntersections,
              subtitle: 'Mark each local curve at the shared X position',
              onChanged: (value) =>
                  setState(() => _showSynchronizedIntersections = value),
            ),
          ],
        ),
      if (_isLineSynchronized)
        OptionSection(
          title: 'Tracking detail',
          icon: Icons.center_focus_strong_outlined,
          initiallyExpanded: false,
          children: [
            BoolOption(
              key: const ValueKey('synchronized-interpolate-values'),
              label: 'Interpolate values',
              value: _synchronizedInterpolateValues,
              subtitle: _synchronizedInterpolateValues
                  ? 'Resolve each local curve at the shared X position'
                  : 'Use the nearest real sample in each chart',
              onChanged: (value) =>
                  setState(() => _synchronizedInterpolateValues = value),
            ),
            BoolOption(
              key: const ValueKey('synchronized-tracking-tooltip'),
              label: 'Show tracking tooltip',
              value: _showSynchronizedTrackingTooltip,
              subtitle: 'Show the floating series-value summary',
              onChanged: (value) =>
                  setState(() => _showSynchronizedTrackingTooltip = value),
            ),
            BoolOption(
              key: const ValueKey('synchronized-horizontal-guide'),
              label: 'Show horizontal guide',
              value: _showSynchronizedHorizontalGuide,
              subtitle: 'Draw each chart\'s local Y crosshair line',
              onChanged: (value) =>
                  setState(() => _showSynchronizedHorizontalGuide = value),
            ),
            BoolOption(
              key: const ValueKey('synchronized-axis-values'),
              label: 'Show axis values',
              value: _showSynchronizedAxisValues,
              subtitle: 'Label the active X and local Y coordinates',
              onChanged: (value) =>
                  setState(() => _showSynchronizedAxisValues = value),
            ),
            SliderOption(
              key: const ValueKey('synchronized-intersection-radius'),
              label: 'Intersection radius',
              value: _synchronizedIntersectionRadius,
              min: 2,
              max: 10,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _synchronizedIntersectionRadius = value),
            ),
          ],
        ),
      if (widget.family == _CartesianFamily.scatter && _presetIndex == 7)
        OptionSection(
          title: 'Point state',
          icon: Icons.ads_click_outlined,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('scatter-select-sample'),
                  onPressed: _selectScatterSample,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Select sample'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('scatter-focus-sample'),
                  onPressed: _focusScatterSample,
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                  label: const Text('Focus sample'),
                ),
                TextButton.icon(
                  key: const ValueKey('scatter-clear-states'),
                  onPressed: _clearScatterStates,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
            Text(
              'Move over or press a point in the chart to compare transient states.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      if (_isScatterSelectionPreset)
        OptionSection(
          title: 'Selection result',
          icon: Icons.select_all_outlined,
          children: [
            Text(
              '${_scatterSelectionResult.statistics.pointCount} selected',
              key: const ValueKey('scatter-selection-count'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (_scatterSelectionResult.isNotEmpty)
              Text(
                _formatScatterSelectionSummary(_scatterSelectionResult),
                key: const ValueKey('scatter-selection-summary'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            Text(
              switch (_scatterSelectionMode) {
                ChartSelectionMode.point =>
                  'Click a marker to apply the chosen operation. Ctrl/Command toggles, Shift adds, and Alt/Option subtracts.',
                ChartSelectionMode.rectangle =>
                  'Drag a rectangle on empty chart space. Ctrl/Command toggles and Alt/Option subtracts; middle-drag pans.',
                ChartSelectionMode.lasso =>
                  'Draw around a cluster on empty chart space. Ctrl/Command toggles and Alt/Option subtracts; middle-drag pans.',
              },
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('scatter-clear-selection'),
                onPressed: _chartController.clearPointSelection,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear selection'),
              ),
            ),
          ],
        ),
      if (widget.family != _CartesianFamily.scatter && _presetIndex == 3)
        OptionSection(
          title: 'Motion',
          icon: Icons.animation,
          children: [
            SliderOption(
              label: 'Duration',
              value: _motionDurationMs,
              min: 150,
              max: 1200,
              divisions: 21,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _motionDurationMs = value),
            ),
            SliderOption(
              key: ValueKey('${widget.family.name}-series-delay'),
              label: 'Series delay',
              value: _motionSeriesDelayMs,
              min: 0,
              max: 240,
              divisions: 12,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _motionSeriesDelayMs = value),
            ),
            BoolOption(
              label: 'Animate paths',
              value: _animatePaths,
              subtitle: 'Reduced-motion settings always take priority',
              onChanged: (value) => setState(() => _animatePaths = value),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-replay-entrance'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _chartController.replaySeriesEntrance,
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay entrance'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-update-values'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _updateMotionValues,
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Update values'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-backfill-point'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _toggleMotionBackfill,
                  icon: Icon(
                    _hasMotionBackfill
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    _hasMotionBackfill ? 'Remove backfill' : 'Add backfill',
                  ),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-add-point'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _addMotionPoint,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add point'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-remove-point'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _motionPrimaryPoints.length > 2
                      ? _removeMotionPoint
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                  label: const Text('Remove point'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-roll-window'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _motionPrimaryPoints.length > 1
                      ? _rollMotionWindow
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Roll window'),
                ),
              ],
            ),
            Text(
              _animatePaths
                  ? '${_motionPrimaryPoints.length} points · ${_motionSeriesDelayMs.round()} ms explicit series delay'
                  : 'Path animation is off · updates apply immediately',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      if (widget.family == _CartesianFamily.scatter)
        ..._buildScatterStyleSections(),
      if (!_isLineSynchronized)
        StandardChartOptions(
          controller: _optionsController,
          showThemeOption: !_isLineSpotlight,
          showLegendOption:
              !_isLineSpotlight && !_isLineForecast && !_isAreaPulse,
          showLineStyleOption: false,
        ),
    ];
  }

  List<Widget> _buildScatterStyleSections() {
    final theme = _optionsController.theme ?? ChartTheme.light;
    final visibleColorSlots = math.min(_scatterEffectiveSeriesCount, 6);
    return [
      OptionSection(
        title: 'Marker appearance',
        icon: Icons.palette_outlined,
        initiallyExpanded: false,
        children: [
          for (var index = 0; index < visibleColorSlots; index++)
            PaletteColorOption(
              key: ValueKey('scatter-series-color-${index + 1}'),
              keyPrefix: 'scatter-series-color-${index + 1}',
              label: visibleColorSlots == 1
                  ? 'Series color'
                  : 'Series ${index + 1} color',
              subtitle: 'Clear to restore the preset color',
              value: _scatterSeriesColorOverrides[index],
              customColorFallback: theme.seriesTheme.colorAt(index),
              onChanged: (value) =>
                  setState(() => _scatterSeriesColorOverrides[index] = value),
            ),
          PaletteColorOption(
            key: const ValueKey('scatter-marker-fill-override'),
            keyPrefix: 'scatter-marker-fill',
            label: 'Override marker fill',
            subtitle: 'Clear to inherit each series color',
            enabled: _scatterFillOverrideEnabled,
            onEnabledChanged: (value) =>
                setState(() => _scatterFillOverrideEnabled = value),
            value: _scatterFillColorOverride,
            customColorFallback:
                _scatterSeriesColorOverrides.first ??
                theme.seriesTheme.colorAt(0),
            onChanged: (value) =>
                setState(() => _scatterFillColorOverride = value),
          ),
          PaletteColorOption(
            key: const ValueKey('scatter-marker-outline-override'),
            keyPrefix: 'scatter-marker-outline',
            label: 'Override marker outline',
            subtitle: 'Clear to use each marker’s inherited outline color',
            enabled: _scatterOutlineOverrideEnabled,
            onEnabledChanged: (value) =>
                setState(() => _scatterOutlineOverrideEnabled = value),
            value: _scatterOutlineColorOverride,
            customColorFallback: theme.axisStyle.lineColor,
            onChanged: (value) =>
                setState(() => _scatterOutlineColorOverride = value),
          ),
          if (_scatterOutlineOverrideEnabled)
            SliderOption(
              key: const ValueKey('scatter-marker-outline-width'),
              label: 'Outline width',
              value: _scatterOutlineWidthOverride,
              min: 0,
              max: 6,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) =>
                  setState(() => _scatterOutlineWidthOverride = value),
            ),
          BoolOption(
            key: const ValueKey('scatter-marker-opacity-toggle'),
            label: 'Override marker opacity',
            subtitle: 'Apply one opacity across the active preset',
            value: _scatterOpacityOverrideEnabled,
            onChanged: (value) =>
                setState(() => _scatterOpacityOverrideEnabled = value),
          ),
          if (_scatterOpacityOverrideEnabled)
            SliderOption(
              key: const ValueKey('scatter-marker-opacity-override'),
              label: 'Marker opacity',
              value: _scatterOpacityOverride,
              min: 0.05,
              max: 1,
              divisions: 19,
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _scatterOpacityOverride = value),
            ),
        ],
      ),
      OptionSection(
        title: 'Canvas colors',
        icon: Icons.format_paint_outlined,
        initiallyExpanded: false,
        children: [
          PaletteColorOption(
            key: const ValueKey('scatter-background-color-option'),
            keyPrefix: 'scatter-background-color',
            label: 'Chart background',
            subtitle: 'Clear to use the selected theme',
            value: _scatterBackgroundColorOverride,
            customColorFallback: theme.backgroundColor,
            onChanged: (value) =>
                setState(() => _scatterBackgroundColorOverride = value),
          ),
          PaletteColorOption(
            key: const ValueKey('scatter-grid-color-option'),
            keyPrefix: 'scatter-grid-color',
            label: 'Grid lines',
            subtitle: 'Clear to use the selected theme',
            value: _scatterGridColorOverride,
            customColorFallback: theme.gridStyle.majorColor,
            onChanged: (value) =>
                setState(() => _scatterGridColorOverride = value),
          ),
          PaletteColorOption(
            key: const ValueKey('scatter-axis-color-option'),
            keyPrefix: 'scatter-axis-color',
            label: 'Axes and labels',
            subtitle: 'Applies to lines, ticks, labels, and titles',
            value: _scatterAxisColorOverride,
            customColorFallback: theme.axisStyle.lineColor,
            onChanged: (value) =>
                setState(() => _scatterAxisColorOverride = value),
          ),
          PaletteColorOption(
            key: const ValueKey('scatter-crosshair-color-option'),
            keyPrefix: 'scatter-crosshair-color',
            label: 'Crosshair',
            subtitle: 'Clear to use the selected theme',
            value: _scatterCrosshairColorOverride,
            customColorFallback: theme.interactionTheme.crosshairColor,
            onChanged: (value) =>
                setState(() => _scatterCrosshairColorOverride = value),
          ),
        ],
      ),
      OptionSection(
        title: 'Interaction colors',
        icon: Icons.ads_click_outlined,
        initiallyExpanded: false,
        children: [
          BoolOption(
            key: const ValueKey('scatter-interaction-color-toggle'),
            label: 'Override interaction colors',
            subtitle: 'Customize hover, selection, and keyboard focus',
            value: _scatterInteractionColorOverrideEnabled,
            onChanged: (value) =>
                setState(() => _scatterInteractionColorOverrideEnabled = value),
          ),
          if (_scatterInteractionColorOverrideEnabled) ...[
            PaletteColorOption(
              key: const ValueKey('scatter-hover-color-option'),
              keyPrefix: 'scatter-hover-color',
              label: 'Hover outline',
              subtitle: 'Clear to inherit the point color',
              value: _scatterHoverColorOverride,
              customColorFallback: theme.interactionTheme.crosshairColor,
              onChanged: (value) =>
                  setState(() => _scatterHoverColorOverride = value),
            ),
            PaletteColorOption(
              key: const ValueKey('scatter-selection-color-option'),
              keyPrefix: 'scatter-selection-color',
              label: 'Selection ring',
              subtitle: 'Clear to use the preset interaction style',
              value: _scatterSelectionColorOverride,
              customColorFallback: theme.interactionTheme.selectionColor,
              onChanged: (value) =>
                  setState(() => _scatterSelectionColorOverride = value),
            ),
            PaletteColorOption(
              key: const ValueKey('scatter-focus-color-option'),
              keyPrefix: 'scatter-focus-color',
              label: 'Keyboard focus ring',
              subtitle: 'Clear to inherit the point color',
              value: _scatterFocusColorOverride,
              customColorFallback: theme.focusBorderColor,
              onChanged: (value) =>
                  setState(() => _scatterFocusColorOverride = value),
            ),
          ],
        ],
      ),
    ];
  }

  List<ChartSeries> _buildSeries() => switch (widget.family) {
    _CartesianFamily.line => _buildLineSeries(),
    _CartesianFamily.area => _buildAreaSeries(),
    _CartesianFamily.scatter => _buildScatterSeries(),
  };

  List<ChartSeries> _buildLineSeries() {
    if (_isLineForecast) {
      const forecastColor = Color(0xFF4F8CFF);
      return [
        LineChartSeries(
          id: 'forecast-continuous',
          name: 'Observed + forecast',
          unit: '°C',
          points: _forecastContinuousPoints,
          color: forecastColor,
          interpolation: _interpolation,
          strokeWidth: _strokeWidth,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: _lineMarkerRadius,
          dataPointMarkerStyle: DataPointMarkerStyle.hollow,
          dataPointMarkerBackground: const Color(0xFFF8FAFC),
          lineGlow: _lineGlow,
          inlineLabel: const SeriesInlineLabelConfig(
            text: 'Forecast',
            position: SeriesLabelPosition.right,
            offsetY: -10,
            color: forecastColor,
            fontWeight: FontWeight.w700,
          ),
          pathAnimation: _pathAnimationFor(0),
        ),
      ];
    }
    if (_presetIndex == 3) {
      return [
        _line(
          id: 'motion-observed',
          name: 'Observed',
          unit: 'W',
          points: _motionPrimaryPoints,
          color: const Color(0xFF2563EB),
          motionSequence: 0,
        ),
        if (_showSecondSeries)
          _line(
            id: 'motion-plan',
            name: 'Plan',
            unit: 'W',
            points: _motionSecondaryPoints,
            color: const Color(0xFFF97316),
            motionSequence: 1,
          ),
        if (_showSecondSeries)
          _line(
            id: 'motion-capacity',
            name: 'Capacity',
            unit: 'W',
            points: _motionCapacityPoints,
            color: const Color(0xFF0F9F8F),
            motionSequence: 2,
          ),
      ];
    }
    if (_presetIndex == 1) {
      final modes = LineInterpolation.values;
      const colors = [
        Color(0xFF2563EB),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
      ];
      return [
        for (var index = 0; index < modes.length; index++)
          LineChartSeries(
            id: 'interpolation-${modes[index].name}',
            name: modes[index].name,
            points: _offsetPoints(_primaryPoints, index * 7.0),
            color: colors[index],
            interpolation: modes[index],
            strokeWidth: _strokeWidth,
            showDataPointMarkers: _optionsController.showDataMarkers,
            dataPointMarkerRadius: _lineMarkerRadius,
            dataPointMarkerStyle: _lineMarkerStyle,
            lineGlow: _lineGlow,
          ),
      ];
    }
    if (_presetIndex == 2) {
      return [
        _line(
          id: 'power',
          name: 'Power',
          unit: 'W',
          points: _powerPoints,
          color: const Color(0xFFF97316),
          axis: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            color: const Color(0xFFF97316),
          ),
        ),
        _line(
          id: 'heart-rate',
          name: 'Heart rate',
          unit: 'bpm',
          points: _heartRatePoints,
          color: const Color(0xFF3B82F6),
          axis: YAxisConfig(
            position: YAxisPosition.right,
            label: 'Heart rate',
            unit: 'bpm',
            color: const Color(0xFF3B82F6),
          ),
        ),
        if (_showSecondSeries)
          _line(
            id: 'lactate',
            name: 'Lactate',
            unit: 'mmol/L',
            points: _lactatePoints,
            color: const Color(0xFFE11D48),
            axis: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Lactate',
              unit: 'mmol/L',
              color: const Color(0xFFE11D48),
            ),
          ),
      ];
    }
    if (_presetIndex == 4) {
      return [
        _line(
          id: 'comparison-current',
          name: 'Current',
          unit: 'W',
          points: _primaryPoints,
          color: const Color(0xFF2563EB),
        ),
        if (_showSecondSeries)
          _line(
            id: 'comparison-previous',
            name: 'Previous',
            unit: 'W',
            points: _offsetPoints(_primaryPoints, -6),
            color: const Color(0xFF8B5CF6),
          ),
        if (_showSecondSeries)
          _line(
            id: 'comparison-target',
            name: 'Target',
            unit: 'W',
            points: _secondaryPoints,
            color: const Color(0xFFF97316),
          ),
      ];
    }
    if (_presetIndex == 5) {
      return [
        _area(
          id: 'capacity-envelope',
          name: 'Capacity envelope',
          points: _offsetPoints(_secondaryPoints, 10),
          color: const Color(0xFF818CF8),
          fillOpacity: 0.32,
          fillGradient: const AreaGradient(
            colors: [Color(0xFF6366F1), Color(0x196366F1)],
          ),
        ),
        _line(
          id: 'envelope-observed',
          name: 'Observed',
          unit: 'W',
          points: _primaryPoints,
          color: const Color(0xFF0F9F8F),
        ),
      ];
    }
    if (_presetIndex == 6) {
      return [
        if (_showSecondSeries)
          const AreaChartSeries(
            id: 'spotlight-context',
            name: 'Expected range',
            points: _spotlightContextPoints,
            color: Color(0xFF22D3EE),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.2,
            fillOpacity: 0.16,
            fillGradient: AreaGradient(
              colors: [Color(0xFF22D3EE), Color(0x3322D3EE)],
            ),
          ),
        LineChartSeries(
          id: 'spotlight-signal',
          name: 'Live signal',
          points: _spotlightSignalPoints,
          color: const Color(0xFFA78BFA),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 3,
          lineGlow: 8,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: _lineMarkerRadius,
          dataPointMarkerStyle: _lineMarkerStyle,
          dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
          inlineLabel: const SeriesInlineLabelConfig(
            text: 'Live signal',
            position: SeriesLabelPosition.right,
            offsetY: -10,
            color: Color(0xFFC4B5FD),
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
    }
    return [
      _line(
        id: 'observed',
        name: 'Observed',
        unit: 'W',
        points: _primaryPoints,
        color: const Color(0xFF2563EB),
      ),
      if (_showSecondSeries)
        _line(
          id: 'target',
          name: 'Target',
          unit: 'W',
          points: _secondaryPoints,
          color: const Color(0xFFF97316),
        ),
    ];
  }

  LineChartSeries _line({
    required String id,
    required String name,
    required String unit,
    required List<ChartDataPoint> points,
    required Color color,
    YAxisConfig? axis,
    int motionSequence = 0,
  }) {
    return LineChartSeries(
      id: id,
      name: name,
      unit: unit,
      points: points,
      color: color,
      interpolation: _interpolation,
      strokeWidth: _strokeWidth,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointMarkerRadius: _lineMarkerRadius,
      dataPointMarkerStyle: _lineMarkerStyle,
      lineGlow: _lineGlow,
      dataPointLabels: DataPointLabelConfig(
        show: _showPointLabels,
        showUnit: true,
      ),
      yAxisConfig: axis,
      pathAnimation: _pathAnimationFor(motionSequence),
    );
  }

  List<ChartSeries> _buildAreaSeries() {
    if (_presetIndex == 3) {
      return [
        _area(
          id: 'motion-volume',
          name: 'Volume',
          points: _motionPrimaryPoints,
          color: const Color(0xFF4F46E5),
          fillOpacity: _fillOpacity,
          motionSequence: 0,
        ),
        if (_showSecondSeries)
          _area(
            id: 'motion-plan',
            name: 'Plan',
            points: _motionSecondaryPoints,
            color: const Color(0xFF0891B2),
            fillOpacity: (_fillOpacity * 0.55).clamp(0.06, 0.22),
            motionSequence: 1,
          ),
      ];
    }
    if (_presetIndex == 1) {
      return [
        AreaChartSeries(
          id: 'baseline-delta',
          name: 'Delta from target',
          unit: '%',
          points: _baselinePoints,
          color: const Color(0xFF8B5CF6),
          interpolation: _interpolation,
          strokeWidth: _strokeWidth,
          fillOpacity: _fillOpacity,
          lineGlow: _lineGlow,
          baselineValue: _showBaselineFill ? 0 : null,
          aboveBaselineFillColor: _showBaselineFill
              ? const Color(0x4434D399)
              : null,
          belowBaselineFillColor: _showBaselineFill
              ? const Color(0x44FB7185)
              : null,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
        ),
      ];
    }
    if (_presetIndex == 2) {
      return [
        AreaChartSeries(
          id: 'forecast-range',
          name: 'Forecast range',
          points: _secondaryPoints,
          color: const Color(0xFF60A5FA),
          interpolation: _interpolation,
          strokeWidth: 1,
          fillOpacity: _fillOpacity,
        ),
        _line(
          id: 'forecast-observed',
          name: 'Observed',
          unit: 'k',
          points: _primaryPoints,
          color: const Color(0xFF0F9F8F),
        ),
      ];
    }
    if (_presetIndex == 4) {
      return [
        _area(
          id: 'gradient-throughput',
          name: 'Throughput',
          points: _primaryPoints,
          color: const Color(0xFF4F46E5),
          fillOpacity: _fillOpacity,
          fillGradient: _useAreaGradient
              ? const AreaGradient(
                  colors: [Color(0xFF4F46E5), Color(0x1A06B6D4)],
                  stops: [0, 1],
                )
              : null,
        ),
      ];
    }
    if (_presetIndex == 5) {
      return [
        _area(
          id: 'composition-total',
          name: 'Total demand',
          points: _offsetPoints(_secondaryPoints, 18),
          color: const Color(0xFF6366F1),
          fillOpacity: (_fillOpacity * 0.72).clamp(0.08, 0.48),
          fillGradient: _useAreaGradient
              ? const AreaGradient(
                  colors: [Color(0xFF6366F1), Color(0x146366F1)],
                )
              : null,
        ),
        if (_showSecondSeries)
          _area(
            id: 'composition-active',
            name: 'Active demand',
            points: _primaryPoints,
            color: const Color(0xFF06B6D4),
            fillOpacity: _fillOpacity,
            fillGradient: _useAreaGradient
                ? const AreaGradient(
                    colors: [Color(0xFF06B6D4), Color(0x1406B6D4)],
                  )
                : null,
          ),
        _line(
          id: 'composition-plan',
          name: 'Plan',
          unit: 'k',
          points: _secondaryPoints,
          color: const Color(0xFFF97316),
        ),
      ];
    }
    if (_presetIndex == 6) {
      return [
        AreaChartSeries(
          id: 'pulse-live-load',
          name: 'Live load',
          unit: 'k',
          points: _pulseLivePoints,
          color: const Color(0xFF6366F1),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.5,
          fillOpacity: _fillOpacity,
          fillGradient: _useAreaGradient
              ? const AreaGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                  stops: [0, 1],
                )
              : null,
          lineGlow: 3,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: 3,
          dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
          inlineLabel: const SeriesInlineLabelConfig(
            text: 'Live load',
            position: SeriesLabelPosition.right,
            offsetY: -10,
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            background: SeriesLabelBackground(
              color: Color(0xEFFFFFFF),
              borderColor: Color(0x556366F1),
            ),
          ),
        ),
        if (_showSecondSeries)
          const LineChartSeries(
            id: 'pulse-target',
            name: 'Target',
            unit: 'k',
            points: _pulseTargetPoints,
            color: Color(0xFFF97316),
            interpolation: LineInterpolation.stepped,
            strokeWidth: 2,
            inlineLabel: SeriesInlineLabelConfig(
              text: 'Target',
              position: SeriesLabelPosition.center,
              offsetY: 10,
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w700,
            ),
          ),
      ];
    }
    return [
      _area(
        id: 'sessions',
        name: 'Sessions',
        points: _offsetPoints(_secondaryPoints, 18),
        color: const Color(0xFF6366F1),
      ),
      if (_showSecondSeries)
        _area(
          id: 'active-users',
          name: 'Active users',
          points: _primaryPoints,
          color: const Color(0xFF06B6D4),
        ),
    ];
  }

  AreaChartSeries _area({
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color color,
    double? fillOpacity,
    AreaGradient? fillGradient,
    int motionSequence = 0,
  }) {
    return AreaChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      interpolation: _interpolation,
      strokeWidth: _strokeWidth,
      fillOpacity: fillOpacity ?? _fillOpacity,
      fillGradient: fillGradient,
      lineGlow: _lineGlow,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
      pathAnimation: _pathAnimationFor(motionSequence),
    );
  }

  PathAnimationStyle _pathAnimationFor(int motionSequence) =>
      _animatePaths && _presetIndex == 3
      ? PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
          entranceTiming: PathAnimationTiming(
            delay: Duration(
              milliseconds: _motionSeriesDelayMs.round() * motionSequence,
            ),
          ),
          dataUpdateTiming: PathAnimationTiming(
            delay: Duration(
              milliseconds: _motionSeriesDelayMs.round() * motionSequence,
            ),
          ),
        )
      : const PathAnimationStyle();

  double get _defaultMotionSeriesDelayMs =>
      widget.family == _CartesianFamily.area ? 120 : 80;

  List<ChartDataPoint> get _motionCapacityPoints => [
    for (var index = 0; index < _motionPrimaryPoints.length; index++)
      _motionPrimaryPoints[index].copyWith(
        y:
            ((_motionPrimaryPoints[index].y + _motionSecondaryPoints[index].y) /
                2) +
            12,
      ),
  ];

  List<ChartSeries> _buildScatterSeries() {
    final series = _buildScatterPresetSeries();
    return [
      for (var index = 0; index < series.length; index++)
        _applyScatterStyleOverrides(series[index], index),
    ];
  }

  ChartSeries _applyScatterStyleOverrides(ChartSeries source, int index) {
    if (source is! ScatterChartSeries) return source;
    final colorOverride = index < _scatterSeriesColorOverrides.length
        ? _scatterSeriesColorOverrides[index]
        : null;
    var markerStyle = source.markerStyle;
    if (_scatterFillOverrideEnabled ||
        _scatterOutlineOverrideEnabled ||
        _scatterOpacityOverrideEnabled) {
      markerStyle ??= const ScatterMarkerStyle();
      if (_scatterFillOverrideEnabled) {
        markerStyle = markerStyle.copyWith(
          fillColor: _scatterFillColorOverride,
          clearFillColor: _scatterFillColorOverride == null,
        );
      }
      if (_scatterOutlineOverrideEnabled) {
        markerStyle = markerStyle.copyWith(
          strokeColor: _scatterOutlineColorOverride,
          strokeWidth: _scatterOutlineWidthOverride,
          clearStrokeColor: _scatterOutlineColorOverride == null,
        );
      }
      if (_scatterOpacityOverrideEnabled) {
        markerStyle = markerStyle.copyWith(opacity: _scatterOpacityOverride);
      }
    }

    var interactionStyle = source.interactionStyle;
    if (_scatterInteractionColorOverrideEnabled) {
      interactionStyle = interactionStyle.copyWith(
        hoverColor: _scatterHoverColorOverride,
        clearHoverColor: _scatterHoverColorOverride == null,
        selectionColor: _scatterSelectionColorOverride,
        clearSelectionColor: _scatterSelectionColorOverride == null,
        focusColor: _scatterFocusColorOverride,
        clearFocusColor: _scatterFocusColorOverride == null,
      );
    }

    return source.copyWith(
      color: colorOverride,
      markerStyle: markerStyle,
      interactionStyle: interactionStyle,
    );
  }

  List<ChartSeries> _buildScatterPresetSeries() {
    if (_presetIndex == 3) return _buildScatterShapeSeries();
    if (_presetIndex == 4) return _buildScatterStylingSeries();
    if (_presetIndex == 7) return _buildScatterStateSeries();
    if (_presetIndex == 8) return _buildScatterBubbleSeries();
    if (_presetIndex == 9) return _buildScatterColorSeries();
    if (_presetIndex == 10) return _buildScatterRiskSeries();
    if (_presetIndex == 11) return _buildScatterOpacitySeries();
    if (_presetIndex == 12) return _buildScatterCategorySeries();
    if (_presetIndex == 13) return _buildScatterJitterSeries();
    if (_presetIndex == 14) return _buildScatterLabelSeries();
    if (_isScatterSelectionPreset) return _buildScatterSelectionSeries();
    if (_isScatterRegressionPreset) {
      return [
        ScatterChartSeries(
          id: 'campaign-response',
          name: 'Observed cohorts',
          points: _scatterCampaignResponse,
          color: const Color(0xFF0F8CA8),
          markerRadius: _markerRadius,
          markerShape: _scatterMarkerShape,
          isXOrdered: true,
        ),
      ];
    }
    if (_isScatterUncertaintyPreset) {
      return [
        ScatterChartSeries(
          id: 'assay-calibration',
          name: 'Observed assay',
          points: _scatterAssayCalibration,
          color: const Color(0xFF0F8CA8),
          markerRadius: _markerRadius + 1,
          markerShape: SeriesMarkerShape.circle,
          markerStyle: const ScatterMarkerStyle(
            fillColor: Color(0xFFF8FAFC),
            strokeColor: Color(0xFF0F8CA8),
            strokeWidth: 2,
          ),
          isXOrdered: true,
        ),
      ];
    }
    if (_isScatterClusterPreset) {
      return [
        ScatterChartSeries(
          id: 'dense-customer-activity',
          name: 'Customer accounts',
          points: _scatterClusterPoints,
          color: const Color(0xFF0F8CA8),
          markerRadius: _markerRadius,
          markerShape: _scatterMarkerShape,
          isXOrdered: true,
          renderMode: ScatterRenderMode.clusters,
          clusterConfig: ScatterClusterConfig(
            cellSize: _scatterClusterCellSize,
            minimumPointCount: _scatterClusterMinimumPoints,
            minimumRadius: _scatterClusterMinimumRadius,
            maximumRadius: _scatterClusterMaximumRadius,
            showCountLabels: _scatterClusterShowLabels,
            labelMinimumPointCount: math.max(2, _scatterClusterMinimumPoints),
            showZones: _scatterClusterShowZones,
            zoneOpacity: _scatterClusterZoneOpacity,
            drillOnTap: _scatterClusterDrillOnTap,
            drillPadding: _scatterClusterDrillPadding,
          ),
        ),
      ];
    }
    if (_isScatterBinPreset) {
      return [
        ScatterChartSeries(
          id: _isScatterHexbinPreset
              ? 'urban-pickup-density'
              : 'support-demand-grid',
          name: _isScatterHexbinPreset ? 'Pickup requests' : 'Support cases',
          points: _scatterBinPoints,
          color: const Color(0xFF0F8CA8),
          markerRadius: _markerRadius,
          markerShape: SeriesMarkerShape.circle,
          isXOrdered: true,
          renderMode: _isScatterHexbinPreset
              ? ScatterRenderMode.hexbin
              : ScatterRenderMode.rectangularBins,
          binConfig: ScatterBinConfig(
            cellSize: _scatterBinCellSize,
            gap: _scatterBinGap,
            minimumPointCount: _scatterBinMinimumPoints,
            minimumOpacity: _scatterBinMinimumOpacity,
            maximumOpacity: _scatterBinMaximumOpacity,
            aggregate: _scatterBinAggregate,
            valueSource: _scatterBinValueSource,
            showLabels: _scatterBinShowLabels,
            labelMinimumPointCount: _scatterBinLabelMinimumPoints,
          ),
        ),
      ];
    }
    if (_isScatterDensityPreset) {
      return [
        ScatterChartSeries(
          id: 'urban-service-concentration',
          name: 'Service requests',
          points: _scatterDensityPoints,
          color: const Color(0xFF0F8CA8),
          markerRadius: _markerRadius,
          markerShape: SeriesMarkerShape.circle,
          isXOrdered: true,
          renderMode: ScatterRenderMode.density,
          densityConfig: ScatterDensityConfig(
            gridCellSize: _scatterDensityGridCellSize,
            bandwidth: _scatterDensityBandwidth,
            contourCount: _scatterDensityContourCount,
            minimumDensity: _scatterDensityMinimum,
            minimumOpacity: _scatterDensityMinimumOpacity,
            maximumOpacity: _scatterDensityMaximumOpacity,
            lineWidth: _scatterDensityLineWidth,
            showPoints: _scatterDensityShowPoints,
          ),
        ),
      ];
    }
    if (_isScatterMarginalPreset) {
      return [
        ScatterChartSeries(
          id: 'marginal-triathlon',
          name: 'Triathlon',
          points: _scatterTriathlon,
          color: const Color(0xFF0EA5E9),
          markerRadius: _markerRadius,
          markerShape: SeriesMarkerShape.triangle,
          isXOrdered: true,
        ),
        ScatterChartSeries(
          id: 'marginal-volleyball',
          name: 'Volleyball',
          points: _scatterVolleyball,
          color: const Color(0xFF6366F1),
          markerRadius: _markerRadius,
          markerShape: SeriesMarkerShape.square,
          isXOrdered: true,
        ),
        ScatterChartSeries(
          id: 'marginal-basketball',
          name: 'Basketball',
          points: _scatterBasketball,
          color: const Color(0xFF10B981),
          markerRadius: _markerRadius,
          markerShape: SeriesMarkerShape.circle,
          isXOrdered: true,
        ),
      ];
    }
    if (_isScatterGeneratorPreset) {
      const colors = [
        Color(0xFF2563EB),
        Color(0xFFF97316),
        Color(0xFF0F9F8F),
        Color(0xFF8B5CF6),
        Color(0xFFE11D48),
        Color(0xFFD69E00),
      ];
      return [
        for (
          var seriesIndex = 0;
          seriesIndex < _scatterGeneratorSeriesCount;
          seriesIndex++
        )
          ScatterChartSeries(
            id: 'generated-cohort-$seriesIndex',
            name: 'Generated cohort ${seriesIndex + 1}',
            points: ScatterPointGenerator.generate(
              _scatterGeneratorConfig,
              seriesIndex: seriesIndex,
            ),
            color: colors[seriesIndex % colors.length],
            markerRadius: _markerRadius,
            markerShape: _scatterMarkerShape,
            isXOrdered: true,
          ),
      ];
    }
    if (_presetIndex == 5 || _presetIndex == 6) {
      const colors = [
        Color(0xFF2563EB),
        Color(0xFFF97316),
        Color(0xFF0F9F8F),
        Color(0xFF8B5CF6),
        Color(0xFFE11D48),
        Color(0xFFD69E00),
      ];
      final unordered = _presetIndex == 6;
      return [
        for (
          var seriesIndex = 0;
          seriesIndex < _scatterSeriesCount;
          seriesIndex++
        )
          ScatterChartSeries(
            id: 'scatter-${unordered ? 'unsorted' : 'stress'}-$seriesIndex',
            name: 'Cohort ${seriesIndex + 1}',
            points: _generatedScatterPoints(
              seriesIndex: seriesIndex,
              pointCount: _scatterPointCount,
              unordered: unordered,
            ),
            color: colors[seriesIndex % colors.length],
            markerRadius: _markerRadius,
            markerShape: _scatterMarkerShape,
            isXOrdered: !unordered,
          ),
      ];
    }
    if (_presetIndex == 0) {
      return [
        ScatterChartSeries(
          id: 'athletes-triathlon',
          name: 'Triathlon',
          points: _scatterTriathlon,
          color: const Color(0xFF0EA5E9),
          markerRadius: _markerRadius,
          markerShape: SeriesMarkerShape.triangle,
          isXOrdered: true,
        ),
        if (_showSecondSeries) ...[
          ScatterChartSeries(
            id: 'athletes-volleyball',
            name: 'Volleyball',
            points: _scatterVolleyball,
            color: const Color(0xFF6366F1),
            markerRadius: _markerRadius,
            markerShape: SeriesMarkerShape.square,
            isXOrdered: true,
          ),
          ScatterChartSeries(
            id: 'athletes-basketball',
            name: 'Basketball',
            points: _scatterBasketball,
            color: const Color(0xFF10B981),
            markerRadius: _markerRadius,
            markerShape: SeriesMarkerShape.circle,
            isXOrdered: true,
          ),
        ],
      ];
    }
    if (_presetIndex == 1) {
      return [
        ScatterChartSeries(
          id: 'training-base',
          name: 'Base block',
          points: _scatterTrainingBase,
          color: const Color(0xFF2563EB),
          markerRadius: _markerRadius,
          markerShape: _scatterMarkerShape,
          isXOrdered: true,
        ),
        if (_showSecondSeries)
          ScatterChartSeries(
            id: 'training-build',
            name: 'Build block',
            points: _scatterTrainingBuild,
            color: const Color(0xFFF97316),
            markerRadius: _markerRadius - 1,
            markerShape: _scatterMarkerShape,
            isXOrdered: true,
          ),
      ];
    }
    return [
      ScatterChartSeries(
        id: 'sensor-expected',
        name: 'Within tolerance',
        points: _scatterSensorExpected,
        color: const Color(0xFF0F9F8F),
        markerRadius: _markerRadius,
        markerShape: _scatterMarkerShape,
        isXOrdered: true,
      ),
      if (_showSecondSeries)
        ScatterChartSeries(
          id: 'sensor-review',
          name: 'Review',
          points: _scatterSensorReview,
          color: const Color(0xFFE11D48),
          markerRadius: _markerRadius + 2,
          markerShape: SeriesMarkerShape.diamond,
          isXOrdered: true,
        ),
    ];
  }

  List<ChartDataPoint> get _scatterClusterPoints =>
      _scatterClusterPointCache.putIfAbsent(
        _scatterClusterPointCount,
        () => ScatterPointGenerator.generate(
          ScatterPointGeneratorConfig(
            pointCount: _scatterClusterPointCount,
            xCenter: 50,
            yCenter: 52,
            xSpread: 92,
            ySpread: 74,
            correlation: 0.38,
            outlierFraction: 0.025,
            seed: 73,
            distribution: ScatterPointDistribution.clustered,
          ),
        ),
      );

  List<ChartDataPoint> get _scatterBinPoints =>
      _scatterClusterPointCache.putIfAbsent(
        -(_scatterBinPointCount * 10 + _presetIndex),
        () => ScatterPointGenerator.generate(
          ScatterPointGeneratorConfig(
            pointCount: _scatterBinPointCount,
            xCenter: 50,
            yCenter: 52,
            xSpread: 92,
            ySpread: 74,
            correlation: _isScatterHexbinPreset ? 0.18 : 0.52,
            outlierFraction: 0.018,
            seed: _isScatterHexbinPreset ? 97 : 89,
            distribution: ScatterPointDistribution.clustered,
          ),
        ),
      );

  List<ChartDataPoint> get _scatterDensityPoints =>
      _scatterClusterPointCache.putIfAbsent(
        -2000000 - _scatterDensityPointCount,
        () => ScatterPointGenerator.generate(
          ScatterPointGeneratorConfig(
            pointCount: _scatterDensityPointCount,
            xCenter: 50,
            yCenter: 52,
            xSpread: 92,
            ySpread: 74,
            correlation: 0.26,
            outlierFraction: 0.012,
            seed: 107,
            distribution: ScatterPointDistribution.clustered,
          ),
        ),
      );

  List<ChartDataPoint> get _scatterMarginalPoints => [
    ..._scatterTriathlon,
    ..._scatterVolleyball,
    ..._scatterBasketball,
  ];

  List<ChartSeries> _buildScatterShapeSeries() {
    const shapes = [
      SeriesMarkerShape.circle,
      SeriesMarkerShape.square,
      SeriesMarkerShape.triangle,
      SeriesMarkerShape.invertedTriangle,
      SeriesMarkerShape.diamond,
      SeriesMarkerShape.star,
      SeriesMarkerShape.cross,
      SeriesMarkerShape.plus,
    ];
    const colors = [
      Color(0xFF2563EB),
      Color(0xFFF97316),
      Color(0xFF0F9F8F),
      Color(0xFF0891B2),
      Color(0xFF8B5CF6),
      Color(0xFFE11D48),
      Color(0xFFD69E00),
      Color(0xFF475569),
    ];
    return [
      for (var seriesIndex = 0; seriesIndex < shapes.length; seriesIndex++)
        ScatterChartSeries(
          id: 'scatter-shape-${shapes[seriesIndex].name}',
          name: _formatMarkerShape(shapes[seriesIndex]),
          color: colors[seriesIndex],
          markerRadius: _markerRadius,
          markerShape: shapes[seriesIndex],
          isXOrdered: true,
          points: [
            for (var pointIndex = 0; pointIndex < 12; pointIndex++)
              ChartDataPoint(
                x: pointIndex.toDouble(),
                y:
                    18 +
                    seriesIndex * 9 +
                    math.sin(pointIndex * 0.8 + seriesIndex) * 2.4,
              ),
          ],
        ),
    ];
  }

  List<ChartSeries> _buildScatterStylingSeries() {
    final fill = switch (_scatterFillTone) {
      _ScatterFillTone.indigo => const Color(0xFF6366F1),
      _ScatterFillTone.teal => const Color(0xFF0F9F8F),
      _ScatterFillTone.coral => const Color(0xFFF97360),
      _ScatterFillTone.amber => const Color(0xFFD69E00),
    };
    const strokes = [Color(0xFF1E293B), Color(0xFF0F766E), Color(0xFF9F1239)];
    const shapes = [
      SeriesMarkerShape.square,
      SeriesMarkerShape.diamond,
      SeriesMarkerShape.triangle,
    ];
    const channelNames = ['Web', 'Retail', 'Partner'];
    const channelPoints = [
      _scatterWebChannel,
      _scatterRetailChannel,
      _scatterPartnerChannel,
    ];
    return [
      for (var seriesIndex = 0; seriesIndex < 3; seriesIndex++)
        ScatterChartSeries(
          id: 'scatter-styling-$seriesIndex',
          name: channelNames[seriesIndex],
          color: strokes[seriesIndex],
          markerRadius: _markerRadius,
          markerShape: shapes[seriesIndex],
          markerStyle: ScatterMarkerStyle(
            fillColor: fill.withValues(alpha: 0.82 + seriesIndex * 0.06),
            strokeColor: strokes[seriesIndex],
            strokeWidth: _scatterMarkerStrokeWidth,
            opacity: _scatterMarkerOpacity,
            width: _scatterMarkerWidth,
            height: _scatterMarkerHeight,
            rotationDegrees: _scatterMarkerRotation + seriesIndex * 18,
          ),
          isXOrdered: true,
          points: [
            for (
              var pointIndex = 0;
              pointIndex < channelPoints[seriesIndex].length;
              pointIndex++
            )
              channelPoints[seriesIndex][pointIndex].copyWith(
                pointStyle: pointIndex == 6
                    ? PointStyle(
                        scatterMarkerShape: SeriesMarkerShape.star,
                        scatterMarkerStyle: ScatterMarkerStyle(
                          fillColor: const Color(0xFFFFFFFF),
                          strokeColor: strokes[seriesIndex],
                          strokeWidth: _scatterMarkerStrokeWidth + 1,
                          width: _scatterMarkerWidth + 6,
                          height: _scatterMarkerHeight + 6,
                          rotationDegrees:
                              _scatterMarkerRotation + seriesIndex * 18,
                        ),
                      )
                    : null,
              ),
          ],
        ),
    ];
  }

  List<ChartSeries> _buildScatterStateSeries() {
    final interactionStyle = ScatterInteractionStyle(
      hoverColor: const Color(0xFF0F172A),
      hoverScale: 1.55,
      hoverStrokeWidth: 2.5,
      pressedColor: const Color(0xFF0F172A),
      pressedScale: 1.18,
      selectionColor: const Color(0xFF4F46E5),
      selectionScale: _scatterSelectionScale,
      selectionStrokeWidth: _scatterSelectionStrokeWidth,
      focusColor: const Color(0xFF0F172A),
      focusGap: _scatterFocusGap,
      focusStrokeWidth: 2.5,
      dimmedOpacity: _scatterDimmedOpacity,
    );
    return [
      ScatterChartSeries(
        id: 'scatter-state-current',
        name: 'Current release',
        points: _scatterStateCurrent,
        color: const Color(0xFF0F9F8F),
        markerRadius: _markerRadius,
        markerShape: SeriesMarkerShape.circle,
        interactionStyle: interactionStyle,
        isXOrdered: true,
      ),
      ScatterChartSeries(
        id: 'scatter-state-previous',
        name: 'Previous release',
        points: _scatterStatePrevious,
        color: const Color(0xFFF97360),
        markerRadius: _markerRadius,
        markerShape: SeriesMarkerShape.diamond,
        interactionStyle: interactionStyle,
        isXOrdered: true,
      ),
    ];
  }

  List<ChartSeries> _buildScatterBubbleSeries() {
    final encoding = ScatterSizeEncoding(
      minimumRadius: _scatterBubbleMinimumRadius,
      maximumRadius: _scatterBubbleMaximumRadius,
      minimumValue: 95,
      maximumValue: 600,
      label: 'Active accounts',
    );
    return [
      ScatterChartSeries(
        id: 'bubble-enterprise',
        name: 'Enterprise',
        points: _scatterEnterpriseMarkets,
        color: const Color(0xFF0F9F8F),
        markerShape: SeriesMarkerShape.circle,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFF0F766E),
          strokeWidth: 1.5,
          opacity: 0.72,
        ),
        sizeEncoding: encoding,
        isXOrdered: true,
      ),
      ScatterChartSeries(
        id: 'bubble-growth',
        name: 'Growth market',
        points: _scatterGrowthMarkets,
        color: const Color(0xFFF97360),
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFBE4937),
          strokeWidth: 1.5,
          opacity: 0.72,
        ),
        sizeEncoding: encoding,
        isXOrdered: true,
      ),
    ];
  }

  List<ChartSeries> _buildScatterColorSeries() {
    final colors = switch (_scatterColorRamp) {
      _ScatterColorRamp.readiness => const [
        Color(0xFFDC2626),
        Color(0xFFF59E0B),
        Color(0xFF16A34A),
      ],
      _ScatterColorRamp.thermal => const [
        Color(0xFF312E81),
        Color(0xFF2563EB),
        Color(0xFFFACC15),
        Color(0xFFDC2626),
      ],
      _ScatterColorRamp.coolWarm => const [
        Color(0xFF2563EB),
        Color(0xFFF8FAFC),
        Color(0xFFE11D48),
      ],
    };
    final encoding = ScatterColorEncoding(
      colors: colors,
      minimumValue: 45,
      maximumValue: 95,
      label: 'Recovery readiness',
      unit: '%',
    );
    return [
      ScatterChartSeries(
        id: 'readiness-base',
        name: 'Base block',
        points: _scatterReadyAthletes,
        markerRadius: _markerRadius,
        markerShape: SeriesMarkerShape.circle,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.25,
          opacity: 0.9,
        ),
        colorEncoding: encoding,
        isXOrdered: true,
      ),
      ScatterChartSeries(
        id: 'readiness-build',
        name: 'Build block',
        points: _scatterFatiguedAthletes,
        markerRadius: _markerRadius,
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.25,
          opacity: 0.9,
        ),
        colorEncoding: encoding,
        isXOrdered: true,
      ),
    ];
  }

  List<ChartSeries> _buildScatterRiskSeries() {
    final colors = switch (_scatterRiskPalette) {
      _ScatterRiskPalette.safety => const [
        Color(0xFF16A34A),
        Color(0xFFEAB308),
        Color(0xFFF97316),
        Color(0xFFDC2626),
      ],
      _ScatterRiskPalette.thermal => const [
        Color(0xFF0284C7),
        Color(0xFF14B8A6),
        Color(0xFFF59E0B),
        Color(0xFFB91C1C),
      ],
      _ScatterRiskPalette.service => const [
        Color(0xFF2563EB),
        Color(0xFF8B5CF6),
        Color(0xFFE11D48),
        Color(0xFF7F1D1D),
      ],
    };
    return [
      ScatterChartSeries(
        id: 'equipment-risk',
        name: 'Monitored assets',
        points: _scatterEquipmentRisk,
        color: const Color(0xFF64748B),
        markerRadius: _markerRadius + 1,
        markerShape: SeriesMarkerShape.circle,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.5,
          opacity: 0.94,
        ),
        colorEncoding: ScatterColorEncoding(
          colors: colors,
          scaleType: ScatterColorScaleType.piecewise,
          thresholds: const [35, 60, 80],
          bandLabels: const ['Normal', 'Monitor', 'Warning', 'Critical'],
          minimumValue: 0,
          maximumValue: 100,
          label: 'Equipment risk',
          unit: '%',
        ),
        isXOrdered: true,
      ),
    ];
  }

  List<ChartSeries> _buildScatterOpacitySeries() {
    final encoding = ScatterOpacityEncoding(
      minimumOpacity: _scatterMinimumOpacity,
      maximumOpacity: 1,
      minimumValue: 45,
      maximumValue: 98,
      label: 'Model confidence',
      unit: '%',
    );
    return [
      ScatterChartSeries(
        id: 'forecast-baseline',
        name: 'Seasonal baseline',
        points: _scatterBaselineForecast,
        color: const Color(0xFF2563EB),
        markerRadius: _markerRadius + 1,
        markerShape: SeriesMarkerShape.circle,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFF1D4ED8),
          strokeWidth: 1.25,
        ),
        opacityEncoding: encoding,
        isXOrdered: true,
      ),
      ScatterChartSeries(
        id: 'forecast-adaptive',
        name: 'Adaptive model',
        points: _scatterAdaptiveForecast,
        color: const Color(0xFFF97316),
        markerRadius: _markerRadius + 1,
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFC2410C),
          strokeWidth: 1.25,
        ),
        opacityEncoding: encoding,
        isXOrdered: true,
      ),
    ];
  }

  List<ChartSeries> _buildScatterCategorySeries() {
    final colors = switch (_scatterCategoryPalette) {
      _ScatterCategoryPalette.mobility => const [
        Color(0xFF0F9F8F),
        Color(0xFF6366F1),
        Color(0xFFF97316),
      ],
      _ScatterCategoryPalette.accessible => const [
        Color(0xFF0072B2),
        Color(0xFFCC79A7),
        Color(0xFFD55E00),
      ],
    };
    return [
      ScatterChartSeries(
        id: 'fleet-vehicles',
        name: 'Fleet vehicles',
        points: _scatterFleetVehicles,
        color: const Color(0xFF64748B),
        markerRadius: _markerRadius + 1,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.5,
          opacity: 0.94,
        ),
        categoryEncoding: ScatterCategoryEncoding(
          label: 'Powertrain',
          categories: [
            ScatterCategoryStyle(
              key: 'electric',
              label: 'Battery electric',
              color: colors[0],
              shape: SeriesMarkerShape.circle,
            ),
            ScatterCategoryStyle(
              key: 'hybrid',
              label: 'Plug-in hybrid',
              color: colors[1],
              shape: SeriesMarkerShape.diamond,
            ),
            ScatterCategoryStyle(
              key: 'combustion',
              label: 'Combustion',
              color: colors[2],
              shape: SeriesMarkerShape.triangle,
            ),
          ],
        ),
        isXOrdered: false,
      ),
    ];
  }

  List<ChartSeries> _buildScatterJitterSeries() => [
    ScatterChartSeries(
      id: 'survey-responses',
      name: 'Survey responses',
      points: _scatterSurveyResponses,
      color: const Color(0xFF64748B),
      markerRadius: _markerRadius,
      markerStyle: const ScatterMarkerStyle(
        strokeColor: Color(0xFFFFFFFF),
        strokeWidth: 1.25,
        opacity: 0.9,
      ),
      categoryEncoding: const ScatterCategoryEncoding(
        label: 'Account tier',
        categories: [
          ScatterCategoryStyle(
            key: 'standard',
            label: 'Standard',
            color: Color(0xFF0072B2),
            shape: SeriesMarkerShape.circle,
          ),
          ScatterCategoryStyle(
            key: 'professional',
            label: 'Professional',
            color: Color(0xFFCC79A7),
            shape: SeriesMarkerShape.diamond,
          ),
          ScatterCategoryStyle(
            key: 'enterprise',
            label: 'Enterprise',
            color: Color(0xFFD55E00),
            shape: SeriesMarkerShape.triangle,
          ),
        ],
      ),
      jitter: ScatterJitterConfig(
        xAmplitude: _scatterJitterX,
        yAmplitude: _scatterJitterY,
        seed: _scatterJitterSeed,
      ),
    ),
  ];

  List<ChartSeries> _buildScatterLabelSeries() {
    DataPointLabelConfig labels(Color background) => DataPointLabelConfig(
      show: true,
      position: _scatterLabelPosition,
      content: DataPointLabelContent.pointLabel,
      offsetX: _scatterLabelOffsetX,
      offsetY: _scatterLabelOffsetY,
      markerGap: 6,
      collisionPolicy: _scatterLabelCollisionPolicy,
      collisionPadding: 3,
      labelColor: const Color(0xFF334155),
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      background: background,
      backgroundOpacity: 0.94,
    );

    return [
      ScatterChartSeries(
        id: 'priority-accounts',
        name: 'Priority',
        points: _scatterPriorityAccounts,
        color: const Color(0xFF007C91),
        markerRadius: _markerRadius + 1,
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.5,
          opacity: 0.94,
        ),
        dataPointLabels: labels(const Color(0xFFE6F5F7)),
      ),
      ScatterChartSeries(
        id: 'monitor-accounts',
        name: 'Monitor',
        points: _scatterMonitorAccounts,
        color: const Color(0xFFD55E00),
        markerRadius: _markerRadius,
        markerShape: SeriesMarkerShape.circle,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.5,
          opacity: 0.9,
        ),
        dataPointLabels: labels(const Color(0xFFFFF0E8)),
      ),
    ];
  }

  List<ChartSeries> _buildScatterSelectionSeries() {
    final interactionStyle = ScatterInteractionStyle(
      hoverColor: const Color(0xFF0F172A),
      hoverScale: 1.35,
      hoverStrokeWidth: 2,
      pressedColor: const Color(0xFF0F172A),
      pressedScale: 1.12,
      selectionColor: const Color(0xFF4F46E5),
      selectionScale: _scatterSelectionScale,
      selectionStrokeWidth: _scatterSelectionStrokeWidth,
      focusColor: const Color(0xFF0F172A),
      focusGap: _scatterFocusGap,
      focusStrokeWidth: 2,
      dimmedOpacity: _scatterDimmedOpacity,
    );
    return [
      ScatterChartSeries(
        id: 'selection-priority',
        name: 'Priority',
        points: _scatterPriorityAccounts,
        color: const Color(0xFF007C91),
        markerRadius: _markerRadius + 1,
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.5,
          opacity: 0.94,
        ),
        interactionStyle: interactionStyle,
      ),
      ScatterChartSeries(
        id: 'selection-monitor',
        name: 'Monitor',
        points: _scatterMonitorAccounts,
        color: const Color(0xFFD55E00),
        markerRadius: _markerRadius,
        markerShape: SeriesMarkerShape.circle,
        markerStyle: const ScatterMarkerStyle(
          strokeColor: Color(0xFFFFFFFF),
          strokeWidth: 1.5,
          opacity: 0.9,
        ),
        interactionStyle: interactionStyle,
      ),
    ];
  }

  void _selectScatterSample() {
    final revision = _chartController.effectiveDocumentRevision.value;
    if (revision == null) return;
    _chartController.selectPoint(
      const ChartPointRef(seriesId: 'scatter-state-current', pointIndex: 6),
      revision: revision,
    );
  }

  void _focusScatterSample() {
    final revision = _chartController.effectiveDocumentRevision.value;
    if (revision == null) return;
    _chartController.focusPoint(
      const ChartPointRef(seriesId: 'scatter-state-previous', pointIndex: 8),
      revision: revision,
    );
  }

  void _clearScatterStates() {
    _chartController.clearPointFocus();
    _chartController.clearPointSelection();
  }

  void _handleScatterSelectionResult(ChartSelectionResult result) {
    if (!mounted) return;
    setState(() => _scatterSelectionResult = result);
  }

  String _formatScatterSelectionSummary(ChartSelectionResult result) {
    final statistics = result.statistics;
    final x = statistics.x!;
    final y = statistics.y!;
    final seriesLabel = statistics.seriesCount == 1
        ? '1 series'
        : '${statistics.seriesCount} series';
    return '$seriesLabel · X ${_compactNumber(x.minimum)}–${_compactNumber(x.maximum)}, mean ${_compactNumber(x.mean)} · Y ${_compactNumber(y.minimum)}–${_compactNumber(y.maximum)}, mean ${_compactNumber(y.mean)}';
  }

  String _compactNumber(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  String _formatMarkerShape(SeriesMarkerShape shape) => switch (shape) {
    SeriesMarkerShape.circle => 'Circle',
    SeriesMarkerShape.square => 'Square',
    SeriesMarkerShape.triangle => 'Triangle',
    SeriesMarkerShape.invertedTriangle => 'Inverted triangle',
    SeriesMarkerShape.diamond => 'Diamond',
    SeriesMarkerShape.star => 'Star',
    SeriesMarkerShape.cross => 'Cross',
    SeriesMarkerShape.plus => 'Plus',
    SeriesMarkerShape.none => 'None',
  };

  String _formatChartSelectionOperation(ChartSelectionOperation operation) =>
      switch (operation) {
        ChartSelectionOperation.replace => 'Replace',
        ChartSelectionOperation.add => 'Add',
        ChartSelectionOperation.subtract => 'Subtract',
        ChartSelectionOperation.toggle => 'Toggle',
      };

  String _formatScatterBinAggregate(ScatterBinAggregate aggregate) =>
      switch (aggregate) {
        ScatterBinAggregate.count => 'Count',
        ScatterBinAggregate.sum => 'Sum',
        ScatterBinAggregate.mean => 'Mean',
        ScatterBinAggregate.minimum => 'Minimum',
        ScatterBinAggregate.maximum => 'Maximum',
        ScatterBinAggregate.proportion => 'Proportion',
      };

  String _formatScatterBinValueSource(ScatterBinValueSource source) =>
      switch (source) {
        ScatterBinValueSource.x => 'East–west position',
        ScatterBinValueSource.y => 'North–south position',
        ScatterBinValueSource.magnitude => 'Magnitude',
        ScatterBinValueSource.colorValue => 'Color value',
        ScatterBinValueSource.opacityValue => 'Opacity value',
      };

  String _formatHistogramValueMode(HistogramValueMode mode) => switch (mode) {
    HistogramValueMode.count => 'Count',
    HistogramValueMode.percentage => 'Percentage',
    HistogramValueMode.density => 'Density',
  };

  String _formatScatterMarginalMode(ScatterMarginalMode mode) =>
      _scatterMarginalModeLabel(mode);

  String get _scatterBinLegendLabel => switch (_scatterBinAggregate) {
    ScatterBinAggregate.count => 'Observations per bin',
    ScatterBinAggregate.proportion => 'Share of observations',
    ScatterBinAggregate.sum =>
      'Sum of ${_formatScatterBinValueSource(_scatterBinValueSource)}',
    ScatterBinAggregate.mean =>
      'Mean ${_formatScatterBinValueSource(_scatterBinValueSource)}',
    ScatterBinAggregate.minimum =>
      'Minimum ${_formatScatterBinValueSource(_scatterBinValueSource)}',
    ScatterBinAggregate.maximum =>
      'Maximum ${_formatScatterBinValueSource(_scatterBinValueSource)}',
  };

  String _formatScatterFillTone(_ScatterFillTone tone) => switch (tone) {
    _ScatterFillTone.indigo => 'Indigo',
    _ScatterFillTone.teal => 'Teal',
    _ScatterFillTone.coral => 'Coral',
    _ScatterFillTone.amber => 'Amber',
  };

  String _formatDataPointLabelPosition(DataPointLabelPosition position) =>
      switch (position) {
        DataPointLabelPosition.above => 'Above',
        DataPointLabelPosition.below => 'Below',
        DataPointLabelPosition.left => 'Left',
        DataPointLabelPosition.right => 'Right',
      };

  String _formatDataPointLabelCollisionPolicy(
    DataPointLabelCollisionPolicy policy,
  ) => switch (policy) {
    DataPointLabelCollisionPolicy.none => 'Allow overlap',
    DataPointLabelCollisionPolicy.hide => 'Hide collisions',
    DataPointLabelCollisionPolicy.reposition => 'Reposition',
  };

  List<ChartDataPoint> _generatedScatterPoints({
    required int seriesIndex,
    required int pointCount,
    required bool unordered,
  }) {
    final points = [
      for (var index = 0; index < pointCount; index++)
        ChartDataPoint(
          x: pointCount == 1 ? 0 : index * 100 / (pointCount - 1),
          y:
              50 +
              seriesIndex * 5 +
              math.sin(index * 0.071 + seriesIndex) * 18 +
              math.cos(index * 0.017 + seriesIndex * 0.8) * 7,
        ),
    ];
    if (!unordered || points.length < 2) return points;

    // Interleave the high and low ends. This is deterministic, keeps every
    // source point exactly once, and makes X-order assumptions fail visibly.
    return [
      for (var index = 0; index < points.length; index++)
        points[index.isEven ? index ~/ 2 : points.length - 1 - index ~/ 2],
    ];
  }

  String _formatPointCount(int value) => value >= 1000
      ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
      : '$value';

  List<ChartAnnotation> _buildAnnotations() {
    if (widget.family == _CartesianFamily.line && _presetIndex == 0) {
      return [
        RangeAnnotation(
          id: 'work-stage',
          startX: 2.5,
          endX: 5.5,
          label: 'Work block',
          fillColor: const Color(0x123B82F6),
          borderColor: const Color(0x443B82F6),
          allowDragging: false,
          allowEditing: false,
        ),
        ThresholdAnnotation(
          id: 'target-threshold',
          axis: AnnotationAxis.y,
          value: 50,
          label: 'Target · 50 W',
          lineColor: const Color(0xFFF59E0B),
          dashPattern: const [6, 4],
          allowDragging: false,
          allowEditing: false,
        ),
        PointAnnotation(
          id: 'peak',
          seriesId: 'observed',
          dataPointIndex: 6,
          label: 'Peak',
          markerShape: MarkerShape.star,
          markerColor: const Color(0xFF2563EB),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isLineForecast) {
      return [
        ThresholdAnnotation(
          id: 'forecast-current-time',
          axis: AnnotationAxis.x,
          value: 4,
          label: 'Current time',
          lineColor: const Color(0xFF6366F1),
          lineWidth: 1.5,
          dashPattern: const [6, 4],
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isLineSpotlight) {
      return [
        ThresholdAnnotation(
          id: 'spotlight-threshold',
          axis: AnnotationAxis.y,
          value: 60,
          label: 'Upper threshold',
          lineColor: const Color(0xFFFBBF24),
          lineWidth: 1.5,
          dashPattern: const [5, 4],
          elevation: 5,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Color(0xCC111827),
            borderColor: Color(0x66FBBF24),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          ),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isAreaPulse) {
      return [
        RangeAnnotation(
          id: 'pulse-target-window',
          startX: 2.5,
          endX: 5.5,
          startY: 42,
          endY: 58,
          label: 'Target window',
          fillColor: const Color(0x1422D3EE),
          borderColor: const Color(0x5522D3EE),
          allowDragging: false,
          allowEditing: false,
        ),
        PointAnnotation(
          id: 'pulse-peak',
          seriesId: 'pulse-live-load',
          dataPointIndex: 6,
          label: 'Peak',
          markerShape: MarkerShape.star,
          markerColor: const Color(0xFF6366F1),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (widget.family == _CartesianFamily.scatter && _presetIndex == 1) {
      return [
        TrendAnnotation(
          id: 'scatter-trend',
          seriesId: 'training-base',
          trendType: TrendType.linear,
          label: 'Base-block trend',
          lineColor: const Color(0xFF2563EB),
          dashPattern: const [6, 4],
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isScatterRegressionPreset) {
      return [
        TrendAnnotation(
          id: 'campaign-response-loess',
          seriesId: 'campaign-response',
          trendType: TrendType.loess,
          loessSpan: _scatterLoessSpan,
          loessRobustnessIterations: _scatterLoessRobustnessIterations,
          loessSampleCount: _scatterLoessSampleCount,
          label: 'Robust LOESS',
          lineColor: const Color(0xFFF97316),
          lineWidth: 3,
          allowDragging: false,
          allowEditing: false,
        ),
        TrendAnnotation(
          id: 'campaign-response-linear',
          seriesId: 'campaign-response',
          trendType: TrendType.linear,
          label: 'Linear diagnostics',
          showEquation: _scatterShowEquation,
          showRSquared: _scatterShowRSquared,
          showSampleCount: _scatterShowSampleCount,
          showPearsonCorrelation: _scatterShowPearsonCorrelation,
          showSpearmanCorrelation: _scatterShowSpearmanCorrelation,
          lineColor: const Color(0xFF64748B),
          lineWidth: 1.5,
          dashPattern: const [6, 4],
          style: const AnnotationStyle(
            textStyle: TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
            backgroundColor: Color(0xF7FFFFFF),
            borderColor: Color(0x5964748B),
            borderRadius: BorderRadius.all(Radius.circular(6)),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isScatterUncertaintyPreset) {
      return [
        TrendAnnotation(
          id: 'assay-ols-fit',
          seriesId: 'assay-calibration',
          trendType: TrendType.linear,
          label: 'OLS fit',
          showConfidenceBand: _scatterShowConfidenceBand,
          showPredictionBand: _scatterShowPredictionBand,
          confidenceLevel: _scatterConfidenceLevel,
          confidenceBandColor: const Color(0xFF0F8CA8),
          predictionBandColor: const Color(0xFF6366F1),
          confidenceBandOpacity: 0.22,
          predictionBandOpacity: 0.10,
          lineColor: const Color(0xFF0F766E),
          lineWidth: 2.5,
          style: const AnnotationStyle(
            textStyle: TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
            backgroundColor: Color(0xF7FFFFFF),
            borderColor: Color(0x590F766E),
            borderRadius: BorderRadius.all(Radius.circular(6)),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          allowDragging: false,
          allowEditing: false,
        ),
        if (_scatterShowXErrorBars || _scatterShowYErrorBars)
          ErrorBarAnnotation(
            id: 'assay-measurement-error',
            label: _scatterShowXErrorBars && _scatterShowYErrorBars
                ? 'X/Y measurement error'
                : _scatterShowXErrorBars
                ? 'X measurement error'
                : 'Y measurement error',
            seriesId: 'assay-calibration',
            values: [
              for (
                var index = 0;
                index < _scatterAssayCalibration.length;
                index++
              )
                _scatterErrorDatum(index),
            ],
            lineColor: const Color(0xFF64748B),
            lineWidth: 1.35,
            capSize: 8,
          ),
      ];
    }
    if (_isScatterBinPreset) {
      return [
        LegendAnnotation(
          id: 'scatter-bin-count-key',
          opacityScale: LegendOpacityScale(
            label: _scatterBinLegendLabel,
            color: const Color(0xFF0F8CA8),
            minimumOpacity: _scatterBinMinimumOpacity,
            maximumOpacity: _scatterBinMaximumOpacity,
            minimumLabel: _scatterBinAggregate == ScatterBinAggregate.count
                ? 'Fewer'
                : 'Lower',
            maximumLabel: _scatterBinAggregate == ScatterBinAggregate.count
                ? 'More'
                : 'Higher',
          ),
          legendStyle: const LegendStyle(
            position: LegendPosition.bottomRight,
            allowDragging: false,
          ),
        ),
      ];
    }
    if (_isScatterDensityPreset) {
      return [
        LegendAnnotation(
          id: 'scatter-density-key',
          opacityScale: LegendOpacityScale(
            label: 'Relative density',
            color: const Color(0xFF0F8CA8),
            minimumOpacity: _scatterDensityMinimumOpacity,
            maximumOpacity: _scatterDensityMaximumOpacity,
            minimumLabel: 'Lower',
            maximumLabel: 'Higher',
          ),
          legendStyle: const LegendStyle(
            position: LegendPosition.bottomRight,
            allowDragging: false,
          ),
        ),
      ];
    }
    return const [];
  }

  ErrorBarDatum _scatterErrorDatum(int index) {
    const xNegative = [
      0.35,
      0.45,
      0.40,
      0.55,
      0.50,
      0.65,
      0.70,
      0.75,
      0.85,
      0.90,
    ];
    const xPositive = [
      0.45,
      0.40,
      0.55,
      0.50,
      0.70,
      0.60,
      0.80,
      0.70,
      0.95,
      1.10,
    ];
    const yNegative = [2.5, 3.0, 3.4, 3.1, 4.0, 4.4, 4.1, 5.0, 5.4, 6.0];
    const yPositive = [3.2, 3.5, 3.0, 4.2, 4.6, 4.1, 5.2, 5.6, 6.2, 6.8];
    final symmetricX = (xNegative[index] + xPositive[index]) / 2;
    final symmetricY = (yNegative[index] + yPositive[index]) / 2;
    return ErrorBarDatum(
      pointIndex: index,
      xNegative: _scatterShowXErrorBars
          ? (_scatterAsymmetricErrorBars ? xNegative[index] : symmetricX) *
                _scatterErrorScale
          : 0,
      xPositive: _scatterShowXErrorBars
          ? (_scatterAsymmetricErrorBars ? xPositive[index] : symmetricX) *
                _scatterErrorScale
          : 0,
      yNegative: _scatterShowYErrorBars
          ? (_scatterAsymmetricErrorBars ? yNegative[index] : symmetricY) *
                _scatterErrorScale
          : 0,
      yPositive: _scatterShowYErrorBars
          ? (_scatterAsymmetricErrorBars ? yPositive[index] : symmetricY) *
                _scatterErrorScale
          : 0,
    );
  }

  bool get _isLineSpotlight =>
      widget.family == _CartesianFamily.line && _presetIndex == 6;

  bool get _isLineForecast =>
      widget.family == _CartesianFamily.line && _presetIndex == 7;

  bool get _isLineSynchronized =>
      widget.family == _CartesianFamily.line && _presetIndex == 8;

  bool get _isAreaPulse =>
      widget.family == _CartesianFamily.area && _presetIndex == 6;

  void _reset() {
    _interactionGroupController.reset();
    _clearScatterStates();
    setState(() {
      _presetIndex = 0;
      _interpolation = LineInterpolation.monotone;
      _strokeWidth = 2.5;
      _lineGlow = 0;
      _fillOpacity = 0.24;
      _markerRadius = 5;
      _lineMarkerRadius = 3;
      _lineMarkerStyle = DataPointMarkerStyle.filled;
      _scatterMarkerShape = SeriesMarkerShape.circle;
      _scatterFillTone = _ScatterFillTone.indigo;
      _scatterMarkerWidth = 18;
      _scatterMarkerHeight = 10;
      _scatterMarkerStrokeWidth = 2;
      _scatterMarkerOpacity = 0.82;
      _scatterMarkerRotation = 24;
      _scatterSelectionScale = 1.45;
      _scatterSelectionStrokeWidth = 3;
      _scatterDimmedOpacity = 0.22;
      _scatterFocusGap = 5;
      _scatterBubbleMinimumRadius = 4;
      _scatterBubbleMaximumRadius = 24;
      _scatterColorRamp = _ScatterColorRamp.readiness;
      _scatterRiskPalette = _ScatterRiskPalette.safety;
      _scatterCategoryPalette = _ScatterCategoryPalette.mobility;
      _scatterMinimumOpacity = 0.18;
      _scatterJitterX = 44;
      _scatterJitterY = 32;
      _scatterJitterSeed = 17;
      _scatterLoessSpan = 0.45;
      _scatterLoessRobustnessIterations = 2;
      _scatterLoessSampleCount = 120;
      _scatterShowEquation = true;
      _scatterShowRSquared = true;
      _scatterShowSampleCount = true;
      _scatterShowPearsonCorrelation = true;
      _scatterShowSpearmanCorrelation = true;
      _scatterShowConfidenceBand = true;
      _scatterShowPredictionBand = true;
      _scatterConfidenceLevel = 0.95;
      _scatterShowXErrorBars = true;
      _scatterShowYErrorBars = true;
      _scatterAsymmetricErrorBars = true;
      _scatterErrorScale = 1;
      _scatterLabelPosition = DataPointLabelPosition.right;
      _scatterLabelCollisionPolicy = DataPointLabelCollisionPolicy.reposition;
      _scatterLabelOffsetX = 0;
      _scatterLabelOffsetY = 0;
      _scatterSelectionOperation = ChartSelectionOperation.toggle;
      _scatterClearSelectionOnBackgroundTap = true;
      _scatterSelectionResult = const ChartSelectionResult.empty();
      _scatterPointCount = 10000;
      _scatterSeriesCount = 3;
      _scatterGeneratorSeriesCount = 3;
      _scatterGeneratorConfig = const ScatterPointGeneratorConfig();
      _scatterClusterPointCount = 25000;
      _scatterClusterCellSize = 44;
      _scatterClusterMinimumPoints = 2;
      _scatterClusterMinimumRadius = 8;
      _scatterClusterMaximumRadius = 26;
      _scatterClusterShowLabels = true;
      _scatterClusterShowZones = true;
      _scatterClusterZoneOpacity = 0.08;
      _scatterClusterDrillOnTap = true;
      _scatterClusterDrillPadding = 0.18;
      _scatterClusterPointCache.clear();
      _scatterBinPointCount = 50000;
      _scatterBinCellSize = 36;
      _scatterBinGap = 1;
      _scatterBinMinimumPoints = 1;
      _scatterBinMinimumOpacity = 0.18;
      _scatterBinMaximumOpacity = 0.95;
      _scatterBinAggregate = ScatterBinAggregate.count;
      _scatterBinValueSource = ScatterBinValueSource.y;
      _scatterBinShowLabels = false;
      _scatterBinLabelMinimumPoints = 25;
      _scatterDensityPointCount = 50000;
      _scatterDensityGridCellSize = 8;
      _scatterDensityBandwidth = 32;
      _scatterDensityContourCount = 6;
      _scatterDensityMinimum = 0.08;
      _scatterDensityMinimumOpacity = 0.28;
      _scatterDensityMaximumOpacity = 0.9;
      _scatterDensityLineWidth = 1.5;
      _scatterDensityShowPoints = false;
      _scatterMarginalBinCount = 12;
      _scatterMarginalMode = ScatterMarginalMode.histogramAndDensity;
      _scatterMarginalValueMode = HistogramValueMode.percentage;
      _scatterMarginalBandwidth = 1;
      _scatterMarginalXExtent = 128;
      _scatterMarginalYExtent = 144;
      _scatterSeriesColorOverrides.fillRange(
        0,
        _scatterSeriesColorOverrides.length,
        null,
      );
      _scatterFillOverrideEnabled = false;
      _scatterFillColorOverride = null;
      _scatterOutlineOverrideEnabled = false;
      _scatterOutlineColorOverride = null;
      _scatterOutlineWidthOverride = 2;
      _scatterOpacityOverrideEnabled = false;
      _scatterOpacityOverride = 0.82;
      _scatterBackgroundColorOverride = null;
      _scatterGridColorOverride = null;
      _scatterAxisColorOverride = null;
      _scatterCrosshairColorOverride = null;
      _scatterInteractionColorOverrideEnabled = false;
      _scatterHoverColorOverride = null;
      _scatterSelectionColorOverride = null;
      _scatterFocusColorOverride = null;
      _showSecondSeries = true;
      _showPointLabels = false;
      _showBaselineFill = true;
      _useAreaGradient = true;
      _animatePaths = true;
      _synchronizeCursor = true;
      _synchronizeViewport = true;
      _showSynchronizedIntersections = true;
      _synchronizedTracking = true;
      _synchronizedInterpolateValues = true;
      _showSynchronizedTrackingTooltip = true;
      _showSynchronizedHorizontalGuide = true;
      _showSynchronizedAxisValues = true;
      _synchronizedIntersectionRadius = 4;
      _animateSynchronizedUpdates = true;
      _synchronizedLiveRevision = false;
      _synchronizedUpdateDurationMs = 650;
      _synchronizedDatasetProfile = _SynchronizedDatasetProfile.normal;
      _visibleSynchronizedMetrics
        ..clear()
        ..addAll(_SynchronizedMetric.values);
      _synchronizedChartHeights
        ..clear()
        ..addAll({
          _SynchronizedMetric.speed: 216,
          _SynchronizedMetric.elevation: 216,
          _SynchronizedMetric.heartRate: 232,
        });
      _motionDurationMs = 650;
      _motionSeriesDelayMs = _defaultMotionSeriesDelayMs;
      _resetMotionData();
    });
    _optionsController.update(const ChartOptions(showDataMarkers: true));
  }

  String _synchronizedMetricLabel(_SynchronizedMetric metric) =>
      switch (metric) {
        _SynchronizedMetric.speed => 'Speed',
        _SynchronizedMetric.elevation => 'Elevation',
        _SynchronizedMetric.heartRate => 'Heart rate',
      };

  String _synchronizedProfileLabel(_SynchronizedDatasetProfile profile) =>
      switch (profile) {
        _SynchronizedDatasetProfile.normal => 'Normal · 52 total',
        _SynchronizedDatasetProfile.dense => 'Dense · 1,500 total',
        _SynchronizedDatasetProfile.stress => 'Stress · 15,000 total',
      };

  int _synchronizedProfilePointCount(_SynchronizedDatasetProfile profile) =>
      switch (profile) {
        _SynchronizedDatasetProfile.normal => 0,
        _SynchronizedDatasetProfile.dense => 500,
        _SynchronizedDatasetProfile.stress => 5000,
      };

  String _synchronizedProfileSummary(_SynchronizedDatasetProfile profile) =>
      switch (profile) {
        _SynchronizedDatasetProfile.normal =>
          '52 original samples across all charts',
        _SynchronizedDatasetProfile.dense =>
          '500 points per chart · generated once and cached',
        _SynchronizedDatasetProfile.stress =>
          '5,000 points per chart · generated once and cached',
      };

  List<ChartDataPoint> _synchronizedSourcePoints(_SynchronizedMetric metric) =>
      switch (metric) {
        _SynchronizedMetric.speed => _synchronizedSpeedPoints,
        _SynchronizedMetric.elevation => _synchronizedElevationPoints,
        _SynchronizedMetric.heartRate => _synchronizedHeartRatePoints,
      };

  List<ChartDataPoint> _synchronizedPoints(_SynchronizedMetric metric) {
    if (_synchronizedLiveRevision) {
      final cachedUpdate =
          _synchronizedUpdateCache[_synchronizedDatasetProfile];
      assert(
        cachedUpdate != null,
        'Synchronized updates must be prepared before setState.',
      );
      return cachedUpdate![metric]!;
    }
    return _synchronizedBaselinePoints(_synchronizedDatasetProfile, metric);
  }

  List<ChartDataPoint> _synchronizedBaselinePoints(
    _SynchronizedDatasetProfile profile,
    _SynchronizedMetric metric,
  ) {
    if (profile == _SynchronizedDatasetProfile.normal) {
      return _synchronizedSourcePoints(metric);
    }
    final cachedProfile = _synchronizedPointCache[profile];
    assert(
      cachedProfile != null,
      'Expanded synchronized profiles must be prepared before setState.',
    );
    return cachedProfile![metric]!;
  }

  void _ensureSynchronizedProfileCached(_SynchronizedDatasetProfile profile) {
    if (profile == _SynchronizedDatasetProfile.normal ||
        _synchronizedPointCache.containsKey(profile)) {
      return;
    }
    final targetCount = _synchronizedProfilePointCount(profile);
    _synchronizedPointCache[profile] = {
      for (final metric in _SynchronizedMetric.values)
        metric: _resampleSynchronizedPoints(
          _synchronizedSourcePoints(metric),
          targetCount,
        ),
    };
  }

  void _ensureSynchronizedUpdateCached(_SynchronizedDatasetProfile profile) {
    if (_synchronizedUpdateCache.containsKey(profile)) return;
    _ensureSynchronizedProfileCached(profile);
    _synchronizedUpdateCache[profile] = {
      for (final metric in _SynchronizedMetric.values)
        metric: _buildSynchronizedUpdate(
          metric,
          _synchronizedBaselinePoints(profile, metric),
        ),
    };
  }

  List<ChartDataPoint> _buildSynchronizedUpdate(
    _SynchronizedMetric metric,
    List<ChartDataPoint> baseline,
  ) {
    final (bias, amplitude, cycles, phase) = switch (metric) {
      _SynchronizedMetric.speed => (0.45, 0.9, 2.0, 0.0),
      _SynchronizedMetric.elevation => (14.0, 24.0, 1.0, math.pi / 3),
      _SynchronizedMetric.heartRate => (2.5, 5.0, 2.0, math.pi / 2),
    };
    final lastIndex = baseline.length - 1;
    return List<ChartDataPoint>.unmodifiable([
      for (var index = 0; index < baseline.length; index++)
        baseline[index].copyWith(
          y:
              baseline[index].y +
              bias +
              (math.sin(phase + (index / lastIndex * math.pi * 2 * cycles)) *
                  amplitude),
        ),
    ]);
  }

  void _toggleSynchronizedDataRevision() {
    if (!_synchronizedLiveRevision) {
      _ensureSynchronizedUpdateCached(_synchronizedDatasetProfile);
    }
    setState(() => _synchronizedLiveRevision = !_synchronizedLiveRevision);
  }

  PathAnimationStyle get _synchronizedPathAnimation =>
      _animateSynchronizedUpdates
      ? PathAnimationStyle(
          dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
          dataUpdateTiming: PathAnimationTiming(
            duration: Duration(
              milliseconds: _synchronizedUpdateDurationMs.round(),
            ),
          ),
        )
      : const PathAnimationStyle();

  void _resetMotionData() {
    _motionPrimaryPoints = List<ChartDataPoint>.of(_primaryPoints);
    _motionSecondaryPoints = List<ChartDataPoint>.of(_secondaryPoints);
    _motionValueRevision = 0;
  }

  void _updateMotionValues() {
    const primaryDelta = <double>[6, 6, 6, 8, 7, 8, -5, 10];
    const secondaryDelta = <double>[-3, 4, 6, 4, 5, 5, 6, 5];
    final direction = _motionValueRevision.isEven ? 1.0 : -1.0;
    setState(() {
      _motionPrimaryPoints = _motionPrimaryPoints
          .asMap()
          .entries
          .map(
            (entry) => entry.value.copyWith(
              y:
                  entry.value.y +
                  (primaryDelta[entry.key % primaryDelta.length] * direction),
            ),
          )
          .toList(growable: false);
      _motionSecondaryPoints = _motionSecondaryPoints
          .asMap()
          .entries
          .map(
            (entry) => entry.value.copyWith(
              y:
                  entry.value.y +
                  (secondaryDelta[entry.key % secondaryDelta.length] *
                      direction),
            ),
          )
          .toList(growable: false);
      _motionValueRevision++;
    });
  }

  bool get _hasMotionBackfill =>
      _motionPrimaryPoints.any((point) => point.label == 'Backfill');

  void _toggleMotionBackfill() {
    setState(() {
      if (_hasMotionBackfill) {
        _motionPrimaryPoints = _motionPrimaryPoints
            .where((point) => point.label != 'Backfill')
            .toList(growable: false);
        _motionSecondaryPoints = _motionSecondaryPoints
            .where((point) => point.label != 'Backfill')
            .toList(growable: false);
        return;
      }

      final insertionIndex = _motionPrimaryPoints.length ~/ 2;
      final primaryBefore = _motionPrimaryPoints[insertionIndex - 1];
      final primaryAfter = _motionPrimaryPoints[insertionIndex];
      final secondaryBefore = _motionSecondaryPoints[insertionIndex - 1];
      final secondaryAfter = _motionSecondaryPoints[insertionIndex];
      final x = (primaryBefore.x + primaryAfter.x) / 2;
      _motionPrimaryPoints = [
        ..._motionPrimaryPoints.take(insertionIndex),
        ChartDataPoint(
          x: x,
          y: ((primaryBefore.y + primaryAfter.y) / 2) + 8,
          label: 'Backfill',
        ),
        ..._motionPrimaryPoints.skip(insertionIndex),
      ];
      _motionSecondaryPoints = [
        ..._motionSecondaryPoints.take(insertionIndex),
        ChartDataPoint(
          x: x,
          y: ((secondaryBefore.y + secondaryAfter.y) / 2) - 6,
          label: 'Backfill',
        ),
        ..._motionSecondaryPoints.skip(insertionIndex),
      ];
    });
  }

  void _addMotionPoint() {
    setState(() {
      final nextX = _motionPrimaryPoints.last.x + 1;
      _motionPrimaryPoints = [
        ..._motionPrimaryPoints,
        ChartDataPoint(
          x: nextX,
          y: _motionPrimaryPoints.last.y + 7,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
      _motionSecondaryPoints = [
        ..._motionSecondaryPoints,
        ChartDataPoint(
          x: nextX,
          y: _motionSecondaryPoints.last.y + 5,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
    });
  }

  void _removeMotionPoint() {
    if (_motionPrimaryPoints.length <= 2) return;
    setState(() {
      _motionPrimaryPoints = _motionPrimaryPoints.sublist(
        0,
        _motionPrimaryPoints.length - 1,
      );
      _motionSecondaryPoints = _motionSecondaryPoints.sublist(
        0,
        _motionSecondaryPoints.length - 1,
      );
    });
  }

  void _rollMotionWindow() {
    if (_motionPrimaryPoints.length <= 1) return;
    setState(() {
      final nextX = _motionPrimaryPoints.last.x + 1;
      _motionPrimaryPoints = [
        ..._motionPrimaryPoints.skip(1),
        ChartDataPoint(
          x: nextX,
          y: _motionPrimaryPoints.last.y + 7,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
      _motionSecondaryPoints = [
        ..._motionSecondaryPoints.skip(1),
        ChartDataPoint(
          x: nextX,
          y: _motionSecondaryPoints.last.y + 5,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
    });
  }
}

class _SynchronizedCartesianExample extends StatelessWidget {
  const _SynchronizedCartesianExample({
    required this.groupController,
    required this.options,
    required this.interpolation,
    required this.strokeWidth,
    required this.lineGlow,
    required this.markerRadius,
    required this.markerStyle,
    required this.synchronizeCursor,
    required this.synchronizeViewport,
    required this.showIntersectionMarkers,
    required this.trackingEnabled,
    required this.interpolateValues,
    required this.showTrackingTooltip,
    required this.showHorizontalGuide,
    required this.showAxisValues,
    required this.intersectionMarkerRadius,
    required this.visibleMetrics,
    required this.chartHeights,
    required this.pointsByMetric,
    required this.pathAnimation,
  });

  final ChartInteractionGroupController groupController;
  final ChartOptions options;
  final LineInterpolation interpolation;
  final double strokeWidth;
  final double lineGlow;
  final double markerRadius;
  final DataPointMarkerStyle markerStyle;
  final bool synchronizeCursor;
  final bool synchronizeViewport;
  final bool showIntersectionMarkers;
  final bool trackingEnabled;
  final bool interpolateValues;
  final bool showTrackingTooltip;
  final bool showHorizontalGuide;
  final bool showAxisValues;
  final double intersectionMarkerRadius;
  final List<_SynchronizedMetric> visibleMetrics;
  final Map<_SynchronizedMetric, double> chartHeights;
  final Map<_SynchronizedMetric, List<ChartDataPoint>> pointsByMetric;
  final PathAnimationStyle pathAnimation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        if (visibleMetrics.isEmpty) {
          return const _SynchronizedEmptyState();
        }
        final stack = Column(
          key: const ValueKey('synchronized-cartesian-stack'),
          children: [
            for (var index = 0; index < visibleMetrics.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              SizedBox(
                key: ValueKey(
                  'synchronized-${visibleMetrics[index].name}-slot',
                ),
                height: chartHeights[visibleMetrics[index]],
                child: _buildMetricPlot(
                  visibleMetrics[index],
                  compact: compact,
                  showDistanceAxis: index == visibleMetrics.length - 1,
                ),
              ),
            ],
          ],
        );
        return Semantics(
          container: true,
          label:
              'Synchronized distance charts. Touch and drag any plot to inspect ${visibleMetrics.length == 1 ? 'it' : 'all ${visibleMetrics.length}'}.',
          child: SingleChildScrollView(
            key: const ValueKey('synchronized-cartesian-scroll'),
            primary: false,
            child: stack,
          ),
        );
      },
    );
  }

  Widget _buildMetricPlot(
    _SynchronizedMetric metric, {
    required bool compact,
    required bool showDistanceAxis,
  }) {
    final points = pointsByMetric[metric]!;
    return switch (metric) {
      _SynchronizedMetric.speed => _SynchronizedMetricPlot(
        title: 'Speed',
        latestValue: '${points.last.y.toStringAsFixed(1)} km/h',
        accessibilityValue:
            '${points.last.y.toStringAsFixed(1)} kilometres per hour',
        color: const Color(0xFF2196F3),
        groupController: groupController,
        options: options,
        compact: compact,
        showDistanceAxis: showDistanceAxis,
        showXScrollbar: showDistanceAxis && options.showXScrollbar,
        series: LineChartSeries(
          id: 'synchronized-speed',
          name: 'Speed',
          unit: 'km/h',
          points: points,
          color: const Color(0xFF2196F3),
          interpolation: interpolation,
          strokeWidth: strokeWidth,
          lineGlow: lineGlow,
          showDataPointMarkers: options.showDataMarkers,
          dataPointMarkerRadius: markerRadius,
          dataPointMarkerStyle: markerStyle,
          pathAnimation: pathAnimation,
        ),
        synchronizeCursor: synchronizeCursor,
        synchronizeViewport: synchronizeViewport,
        showIntersectionMarkers: showIntersectionMarkers,
        trackingEnabled: trackingEnabled,
        interpolateValues: interpolateValues,
        showTrackingTooltip: showTrackingTooltip,
        showHorizontalGuide: showHorizontalGuide,
        showAxisValues: showAxisValues,
        intersectionMarkerRadius: intersectionMarkerRadius,
      ),
      _SynchronizedMetric.elevation => _SynchronizedMetricPlot(
        title: 'Elevation',
        latestValue: '${points.last.y.round()} m',
        accessibilityValue: '${points.last.y.round()} metres',
        color: const Color(0xFF5B56D6),
        groupController: groupController,
        options: options,
        compact: compact,
        showDistanceAxis: showDistanceAxis,
        showXScrollbar: showDistanceAxis && options.showXScrollbar,
        series: AreaChartSeries(
          id: 'synchronized-elevation',
          name: 'Elevation',
          unit: 'm',
          points: points,
          color: const Color(0xFF5B56D6),
          interpolation: interpolation,
          strokeWidth: strokeWidth,
          lineGlow: lineGlow,
          fillOpacity: 0.28,
          fillGradient: const AreaGradient(
            colors: [Color(0x665B56D6), Color(0x125B56D6)],
          ),
          showDataPointMarkers: options.showDataMarkers,
          dataPointMarkerRadius: markerRadius,
          dataPointMarkerStyle: markerStyle,
          pathAnimation: pathAnimation,
        ),
        synchronizeCursor: synchronizeCursor,
        synchronizeViewport: synchronizeViewport,
        showIntersectionMarkers: showIntersectionMarkers,
        trackingEnabled: trackingEnabled,
        interpolateValues: interpolateValues,
        showTrackingTooltip: showTrackingTooltip,
        showHorizontalGuide: showHorizontalGuide,
        showAxisValues: showAxisValues,
        intersectionMarkerRadius: intersectionMarkerRadius,
      ),
      _SynchronizedMetric.heartRate => _SynchronizedMetricPlot(
        title: 'Heart rate',
        latestValue: '${points.last.y.round()} bpm',
        accessibilityValue: '${points.last.y.round()} beats per minute',
        color: const Color(0xFF00B86B),
        groupController: groupController,
        options: options,
        compact: compact,
        showDistanceAxis: showDistanceAxis,
        showXScrollbar: showDistanceAxis && options.showXScrollbar,
        series: AreaChartSeries(
          id: 'synchronized-heart-rate',
          name: 'Heart rate',
          unit: 'bpm',
          points: points,
          color: const Color(0xFF00B86B),
          interpolation: interpolation,
          strokeWidth: strokeWidth,
          lineGlow: lineGlow,
          fillOpacity: 0.24,
          fillGradient: const AreaGradient(
            colors: [Color(0x6600B86B), Color(0x1000B86B)],
          ),
          showDataPointMarkers: options.showDataMarkers,
          dataPointMarkerRadius: markerRadius,
          dataPointMarkerStyle: markerStyle,
          pathAnimation: pathAnimation,
        ),
        synchronizeCursor: synchronizeCursor,
        synchronizeViewport: synchronizeViewport,
        showIntersectionMarkers: showIntersectionMarkers,
        trackingEnabled: trackingEnabled,
        interpolateValues: interpolateValues,
        showTrackingTooltip: showTrackingTooltip,
        showHorizontalGuide: showHorizontalGuide,
        showAxisValues: showAxisValues,
        intersectionMarkerRadius: intersectionMarkerRadius,
      ),
    };
  }
}

class _SynchronizedEmptyState extends StatelessWidget {
  const _SynchronizedEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('synchronized-empty-state'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.view_stream_outlined,
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text('No charts mounted', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Add Speed, Elevation, or Heart rate from Chart composition.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SynchronizedMetricPlot extends StatelessWidget {
  const _SynchronizedMetricPlot({
    required this.title,
    required this.latestValue,
    required this.accessibilityValue,
    required this.color,
    required this.groupController,
    required this.options,
    required this.compact,
    required this.showDistanceAxis,
    required this.showXScrollbar,
    required this.series,
    required this.synchronizeCursor,
    required this.synchronizeViewport,
    required this.showIntersectionMarkers,
    required this.trackingEnabled,
    required this.interpolateValues,
    required this.showTrackingTooltip,
    required this.showHorizontalGuide,
    required this.showAxisValues,
    required this.intersectionMarkerRadius,
  });

  final String title;
  final String latestValue;
  final String accessibilityValue;
  final Color color;
  final ChartInteractionGroupController groupController;
  final ChartOptions options;
  final bool compact;
  final bool showDistanceAxis;
  final bool showXScrollbar;
  final ChartSeries series;
  final bool synchronizeCursor;
  final bool synchronizeViewport;
  final bool showIntersectionMarkers;
  final bool trackingEnabled;
  final bool interpolateValues;
  final bool showTrackingTooltip;
  final bool showHorizontalGuide;
  final bool showAxisValues;
  final double intersectionMarkerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartTheme = options.theme ?? ChartTheme.light;
    final yAxisGutterWidth = compact ? 48.0 : 56.0;
    return Semantics(
      container: true,
      label: '$title, latest $accessibilityValue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    latestValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BravenChartPlus(
              key: ValueKey(series.id),
              interactionGroupController: groupController,
              interactionGroupOptions: ChartInteractionGroupOptions(
                synchronizeCursor: synchronizeCursor,
                synchronizeViewport: synchronizeViewport,
              ),
              series: [series],
              theme: chartTheme,
              showLegend: false,
              showXScrollbar: showXScrollbar,
              showYScrollbar: false,
              grid: GridConfig(
                horizontal: options.showGrid,
                vertical: options.showGrid,
              ),
              xAxisConfig: XAxisConfig(
                label: showDistanceAxis ? 'Distance' : null,
                unit: 'km',
                visible: !compact || showDistanceAxis,
                showAxisLine: options.showAxisLines,
                showTicks: !compact || showDistanceAxis,
                showTickLabels: !compact || showDistanceAxis,
                showCrosshairLabel: trackingEnabled && showAxisValues,
                labelDisplay: AxisLabelDisplay.labelWithUnit,
                tickCount: compact ? 4 : 6,
                maxHeight: showDistanceAxis ? 52 : 36,
              ),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                color: color,
                unit: series.unit,
                showAxisLine: options.showAxisLines,
                showCrosshairLabel: trackingEnabled && showAxisValues,
                labelDisplay: AxisLabelDisplay.tickOnly,
                tickCount: compact ? 3 : 4,
                minWidth: yAxisGutterWidth,
                maxWidth: yAxisGutterWidth,
              ),
              interactionConfig: InteractionConfig(
                enableZoom: options.enableZoom,
                enablePan: options.enablePan,
                crosshair: CrosshairConfig(
                  enabled: trackingEnabled,
                  mode: showHorizontalGuide
                      ? CrosshairMode.both
                      : CrosshairMode.vertical,
                  displayMode: CrosshairDisplayMode.tracking,
                  interpolateValues: interpolateValues,
                  showTrackingTooltip: trackingEnabled && showTrackingTooltip,
                  showIntersectionMarkers: showIntersectionMarkers,
                  intersectionMarkerRadius: intersectionMarkerRadius,
                  showCoordinateLabels: trackingEnabled && showAxisValues,
                ),
                tooltip: const TooltipConfig(enabled: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Passive page-frame instrumentation for the synchronized composition.
///
/// This widget owns its own state so the twice-per-second metrics refresh does
/// not rebuild any chart participant. Values describe this browser/device and
/// build mode only; they are comparison signals, not portable benchmarks.
class _SynchronizedPerformancePanel extends StatefulWidget {
  const _SynchronizedPerformancePanel({
    required this.activeChartCount,
    required this.visiblePointCount,
  });

  final int activeChartCount;
  final int visiblePointCount;

  @override
  State<_SynchronizedPerformancePanel> createState() =>
      _SynchronizedPerformancePanelState();
}

class _SynchronizedPerformancePanelState
    extends State<_SynchronizedPerformancePanel> {
  static const _slowFrameThreshold = Duration(microseconds: 16667);
  static const _maxFrameSamples = 180;

  final List<FrameTiming> _frameTimings = [];
  DateTime _lastMetricsRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;
    _frameTimings.addAll(timings);
    if (_frameTimings.length > _maxFrameSamples) {
      _frameTimings.removeRange(0, _frameTimings.length - _maxFrameSamples);
    }

    // Throttle the diagnostics subtree so measurement never creates a
    // per-frame chart rebuild feedback loop.
    final now = DateTime.now();
    if (now.difference(_lastMetricsRefresh) >=
        const Duration(milliseconds: 500)) {
      _lastMetricsRefresh = now;
      setState(() {});
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slowFrames = _frameTimings
        .where((timing) => timing.totalSpan > _slowFrameThreshold)
        .length;
    final p95Build = _percentileMs(
      _frameTimings.map((timing) => timing.buildDuration),
      0.95,
    );
    final p95Raster = _percentileMs(
      _frameTimings.map((timing) => timing.rasterDuration),
      0.95,
    );

    return Card(
      key: const ValueKey('synchronized-performance-panel'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session performance',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Rolling UI frame timings for this device, browser, and build mode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('reset-synchronized-performance'),
                  tooltip: 'Reset frame samples',
                  onPressed: () => setState(() {
                    _frameTimings.clear();
                    _lastMetricsRefresh = DateTime.now();
                  }),
                  icon: const Icon(Icons.restart_alt, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatusPanel(
              items: [
                StatusItem(
                  label: 'Active charts',
                  value: '${widget.activeChartCount}',
                ),
                StatusItem(
                  label: 'Visible points',
                  value: '${widget.visiblePointCount}',
                ),
                StatusItem(
                  label: 'Frame samples',
                  value: '${_frameTimings.length}',
                ),
                StatusItem(
                  label: 'p95 build',
                  value: _formatMilliseconds(p95Build),
                ),
                StatusItem(
                  label: 'p95 raster',
                  value: _formatMilliseconds(p95Raster),
                ),
                StatusItem(
                  label: 'Over 16.7ms',
                  value: '$slowFrames / ${_frameTimings.length}',
                  color: slowFrames == 0
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double? _percentileMs(Iterable<Duration> durations, double percentile) {
    final values = durations.map((duration) => duration.inMicroseconds).toList()
      ..sort();
    if (values.isEmpty) return null;
    final index = ((values.length - 1) * percentile).ceil();
    return values[index] / 1000;
  }

  String _formatMilliseconds(double? value) {
    if (value == null) return '—';
    if (value < 0.1) return '<0.1ms';
    return '${value.toStringAsFixed(1)}ms';
  }
}

class _SynchronizedCodeReference extends StatefulWidget {
  const _SynchronizedCodeReference();

  @override
  State<_SynchronizedCodeReference> createState() =>
      _SynchronizedCodeReferenceState();
}

class _SynchronizedCodeReferenceState
    extends State<_SynchronizedCodeReference> {
  var _selectedSnippet = 0;

  String get _source => _selectedSnippet == 0
      ? _synchronizedControllerSnippet
      : _synchronizedParticipantsSnippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<int>(
          key: const ValueKey('synchronized-code-selector'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Shared controller')),
            ButtonSegment(value: 1, label: Text('Chart participants')),
          ],
          selected: {_selectedSnippet},
          onSelectionChanged: (selection) =>
              setState(() => _selectedSnippet = selection.single),
        ),
        OutlinedButton.icon(
          key: const ValueKey('copy-synchronized-code'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _source));
            if (!context.mounted) return;
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Synchronized chart code copied')),
            );
          },
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: const Text('Copy code'),
        ),
      ],
    );
    return Card(
      key: const ValueKey('synchronized-code-reference'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build synchronized charts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reuse one interaction controller; each chart keeps its own series and Y axis.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 12), controls],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 16),
                    controls,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF0F172A),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectionArea(
                    child: Text(
                      _source,
                      key: ValueKey(
                        'synchronized-code-${_selectedSnippet == 0 ? 'controller' : 'participants'}',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _synchronizedControllerSnippet = '''
final interactions = ChartInteractionGroupController();

@override
void dispose() {
  interactions.dispose();
  super.dispose();
}
''';

const _synchronizedParticipantsSnippet = '''
final visibleMetrics = metrics.where((metric) => metric.visible);
const updateMotion = PathAnimationStyle(
  dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
  dataUpdateTiming: PathAnimationTiming(
    duration: Duration(milliseconds: 650),
  ),
);
final crosshairMode = showHorizontalGuide
    ? CrosshairMode.both
    : CrosshairMode.vertical;

Column(
  children: [
    for (final metric in visibleMetrics)
      SizedBox(
        height: metric.height,
        child: BravenChartPlus(
          interactionGroupController: interactions,
          interactionGroupOptions: const ChartInteractionGroupOptions(
            synchronizeCursor: true,
            synchronizeViewport: true,
          ),
          // Keep the series ID and X coordinates stable when points change.
          series: [metric.buildSeries(pathAnimation: updateMotion)],
          yAxis: const YAxisConfig(
            minWidth: 56,
            maxWidth: 56,
            showCrosshairLabel: true,
          ),
          interactionConfig: InteractionConfig(
            crosshair: CrosshairConfig(
              enabled: true,
              mode: crosshairMode,
              displayMode: CrosshairDisplayMode.tracking,
              interpolateValues: true,
              showTrackingTooltip: true,
              showCoordinateLabels: true,
              showIntersectionMarkers: true,
              intersectionMarkerRadius: 4,
            ),
          ),
        ),
      ),
  ],
);
''';

List<ChartDataPoint> _resampleSynchronizedPoints(
  List<ChartDataPoint> source,
  int targetCount,
) {
  assert(source.length >= 2);
  assert(targetCount >= 2);
  if (targetCount == source.length) return source;

  final first = source.first;
  final last = source.last;
  final span = last.x - first.x;
  var sourceIndex = 0;
  final points = List<ChartDataPoint>.generate(targetCount, (index) {
    if (index == 0) return first;
    if (index == targetCount - 1) return last;

    final x = first.x + (span * index / (targetCount - 1));
    while (sourceIndex < source.length - 2 && source[sourceIndex + 1].x < x) {
      sourceIndex++;
    }
    final lower = source[sourceIndex];
    final upper = source[sourceIndex + 1];
    final segmentSpan = upper.x - lower.x;
    final progress = segmentSpan == 0 ? 0.0 : (x - lower.x) / segmentSpan;
    return ChartDataPoint(x: x, y: lower.y + ((upper.y - lower.y) * progress));
  }, growable: false);
  return List<ChartDataPoint>.unmodifiable(points);
}

const _synchronizedSpeedPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 13.5),
  ChartDataPoint(x: 0.4, y: 4.8),
  ChartDataPoint(x: 0.8, y: 3.5),
  ChartDataPoint(x: 1.2, y: 4.9),
  ChartDataPoint(x: 1.6, y: 5.1),
  ChartDataPoint(x: 2, y: 5),
  ChartDataPoint(x: 2.4, y: 10.8),
  ChartDataPoint(x: 2.8, y: 6.6),
  ChartDataPoint(x: 3.2, y: 6),
  ChartDataPoint(x: 3.6, y: 8.2),
  ChartDataPoint(x: 4, y: 6.4),
  ChartDataPoint(x: 4.4, y: 8.7),
  ChartDataPoint(x: 4.8, y: 12.1),
  ChartDataPoint(x: 5.2, y: 9.8),
  ChartDataPoint(x: 5.6, y: 11.2),
  ChartDataPoint(x: 6, y: 10.8),
  ChartDataPoint(x: 6.4, y: 9.3),
];

const _synchronizedElevationPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 20),
  ChartDataPoint(x: 0.5, y: 80),
  ChartDataPoint(x: 1, y: 280),
  ChartDataPoint(x: 1.5, y: 430),
  ChartDataPoint(x: 2, y: 420),
  ChartDataPoint(x: 2.5, y: 380),
  ChartDataPoint(x: 3, y: 329),
  ChartDataPoint(x: 3.5, y: 290),
  ChartDataPoint(x: 4, y: 220),
  ChartDataPoint(x: 4.5, y: 110),
  ChartDataPoint(x: 5, y: 90),
  ChartDataPoint(x: 5.5, y: 100),
  ChartDataPoint(x: 6, y: 210),
  ChartDataPoint(x: 6.4, y: 329),
];

const _synchronizedHeartRatePoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 96),
  ChartDataPoint(x: 0.32, y: 122),
  ChartDataPoint(x: 0.64, y: 132),
  ChartDataPoint(x: 0.96, y: 139),
  ChartDataPoint(x: 1.28, y: 141),
  ChartDataPoint(x: 1.6, y: 118),
  ChartDataPoint(x: 1.92, y: 117),
  ChartDataPoint(x: 2.24, y: 134),
  ChartDataPoint(x: 2.56, y: 121),
  ChartDataPoint(x: 2.88, y: 116),
  ChartDataPoint(x: 3.2, y: 124),
  ChartDataPoint(x: 3.52, y: 128),
  ChartDataPoint(x: 3.84, y: 126),
  ChartDataPoint(x: 4.16, y: 127),
  ChartDataPoint(x: 4.48, y: 125),
  ChartDataPoint(x: 4.8, y: 129),
  ChartDataPoint(x: 5.12, y: 130),
  ChartDataPoint(x: 5.44, y: 135),
  ChartDataPoint(x: 5.76, y: 143),
  ChartDataPoint(x: 6.08, y: 145),
  ChartDataPoint(x: 6.4, y: 138),
];

class _ScatterMarginalExample extends StatefulWidget {
  const _ScatterMarginalExample({
    super.key,
    required this.controller,
    required this.series,
    required this.theme,
    required this.options,
    required this.binCount,
    required this.marginalMode,
    required this.valueMode,
    required this.bandwidthMultiplier,
    required this.xMarginalExtent,
    required this.yMarginalExtent,
    required this.xMarginalColor,
    required this.yMarginalColor,
  });

  final BravenChartController controller;
  final List<ScatterChartSeries> series;
  final ChartTheme theme;
  final ChartOptions options;
  final int binCount;
  final ScatterMarginalMode marginalMode;
  final HistogramValueMode valueMode;
  final double bandwidthMultiplier;
  final double xMarginalExtent;
  final double yMarginalExtent;
  final Color xMarginalColor;
  final Color yMarginalColor;

  @override
  State<_ScatterMarginalExample> createState() =>
      _ScatterMarginalExampleState();
}

class _ScatterMarginalExampleState extends State<_ScatterMarginalExample> {
  _ScatterViewport? _visibleViewport;

  List<ChartDataPoint> get _points => [
    for (final series in widget.series) ...series.points,
  ];

  _ScatterViewport get _fullViewport {
    final finite = _points.where((point) => point.isValid).toList();
    if (finite.isEmpty) {
      return (xMin: 0, xMax: 1, yMin: 0, yMax: 1);
    }
    final xMin = finite.map((point) => point.x).reduce(math.min);
    final xMax = finite.map((point) => point.x).reduce(math.max);
    final yMin = finite.map((point) => point.y).reduce(math.min);
    final yMax = finite.map((point) => point.y).reduce(math.max);
    final xPadding = math.max((xMax - xMin) * 0.04, 0.5);
    final yPadding = math.max((yMax - yMin) * 0.06, 0.5);
    return (
      xMin: xMin - xPadding,
      xMax: xMax + xPadding,
      yMin: yMin - yPadding,
      yMax: yMax + yPadding,
    );
  }

  _ScatterViewport get _viewport => _visibleViewport ?? _fullViewport;

  void _handleViewportChanged(Map<String, double> bounds) {
    final next = (
      xMin: bounds['minX']!,
      xMax: bounds['maxX']!,
      yMin: bounds['minY']!,
      yMax: bounds['maxY']!,
    );
    if (_visibleViewport == next || !mounted) return;
    setState(() => _visibleViewport = next);
  }

  @override
  Widget build(BuildContext context) {
    final viewport = _viewport;
    final marginalData = ScatterMarginalData(
      points: _points,
      method: HistogramBinningMethod.fixedCount,
      requestedBinCount: widget.binCount,
      xMinimum: viewport.xMin,
      xMaximum: viewport.xMax,
      yMinimum: viewport.yMin,
      yMaximum: viewport.yMax,
    );
    final histogramValueMode =
        widget.marginalMode == ScatterMarginalMode.histogram
        ? widget.valueMode
        : HistogramValueMode.density;
    final xHistogram = marginalData.xPointsFor(histogramValueMode);
    final yHistogram = marginalData
        .yPointsFor(histogramValueMode, invertDomain: true)
        .reversed
        .toList();
    final xDensity = marginalData.xDensityPoints(
      bandwidthMultiplier: widget.bandwidthMultiplier,
    );
    final yDensity = marginalData.yDensityPoints(
      bandwidthMultiplier: widget.bandwidthMultiplier,
      invertDomain: true,
    );
    final xRug = marginalData.xRugPoints();
    final yRug = marginalData.yRugPoints(invertDomain: true);

    return ScatterMarginalComposition(
      xMarginalExtent: widget.xMarginalExtent,
      yMarginalExtent: widget.yMarginalExtent,
      gap: 6,
      xMarginal: _MarginalPanel(
        label: 'Height distribution',
        child: Padding(
          padding: const EdgeInsets.only(left: 48),
          child: _marginalChart(
            id: 'height-marginal',
            histogramPoints: xHistogram,
            densityPoints: xDensity,
            rugPoints: xRug,
            color: widget.xMarginalColor,
            xMinimum: viewport.xMin,
            xMaximum: viewport.xMax,
          ),
        ),
      ),
      yMarginal: _MarginalPanel(
        label: 'Mass distribution',
        child: RotatedBox(
          quarterTurns: 1,
          child: _marginalChart(
            id: 'mass-marginal',
            histogramPoints: yHistogram,
            densityPoints: yDensity,
            rugPoints: yRug,
            color: widget.yMarginalColor,
            xMinimum: -viewport.yMax,
            xMaximum: -viewport.yMin,
          ),
        ),
      ),
      corner: _MarginalSummary(
        visiblePointCount: marginalData.visiblePointCount,
        sourcePointCount: marginalData.sourcePointCount,
        marginalMode: widget.marginalMode,
        histogramValueMode: histogramValueMode,
      ),
      scatter: BravenChartPlus(
        key: const ValueKey('scatter-marginal-source-chart'),
        bravenChartController: widget.controller,
        series: widget.series,
        theme: widget.theme,
        showLegend: widget.options.showLegend,
        showXScrollbar: widget.options.showXScrollbar,
        showYScrollbar: widget.options.showYScrollbar,
        grid: GridConfig(
          horizontal: widget.options.showGrid,
          vertical: widget.options.showGrid,
        ),
        xAxisConfig: XAxisConfig(
          label: 'Height (cm)',
          min: _fullViewport.xMin,
          max: _fullViewport.xMax,
          showAxisLine: widget.options.showAxisLines,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Body mass (kg)',
          min: _fullViewport.yMin,
          max: _fullViewport.yMax,
          showAxisLine: widget.options.showAxisLines,
        ),
        interactionConfig: InteractionConfig(
          enableZoom: widget.options.enableZoom,
          enablePan: widget.options.enablePan,
          showXScrollbar: widget.options.showXScrollbar,
          showYScrollbar: widget.options.showYScrollbar,
          onViewportChanged: _handleViewportChanged,
          crosshair: const CrosshairConfig(
            enabled: true,
            mode: CrosshairMode.both,
            snapToDataPoint: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _marginalChart({
    required String id,
    required List<ChartDataPoint> histogramPoints,
    required List<ChartDataPoint> densityPoints,
    required List<ChartDataPoint> rugPoints,
    required Color color,
    required double xMinimum,
    required double xMaximum,
  }) {
    final plottedValues = <ChartDataPoint>[
      if (widget.marginalMode.showsHistogram) ...histogramPoints,
      if (widget.marginalMode.showsDensity) ...densityPoints,
    ];
    final maximum = plottedValues.fold<double>(
      0,
      (current, point) => math.max(current, point.y),
    );
    final resolvedMaximum = maximum <= 0 ? 1.0 : maximum;
    final positionedRugPoints = [
      for (final point in rugPoints)
        ChartDataPoint(
          x: point.x,
          y: resolvedMaximum * 0.045,
          metadata: point.metadata,
        ),
    ];
    return BravenChartPlus(
      key: ValueKey(id),
      series: [
        if (widget.marginalMode.showsHistogram)
          BarChartSeries(
            id: '$id-histogram',
            name: _histogramValueLabel(
              widget.marginalMode == ScatterMarginalMode.histogram
                  ? widget.valueMode
                  : HistogramValueMode.density,
            ),
            points: histogramPoints,
            color: color,
            barWidthPercent: 0.94,
            minWidth: 1,
            barGap: 0,
            barStyle: BarChartStyle(
              cornerRadius: 2,
              cornerRadiusPolicy: BarCornerRadiusPolicy.valueEnd,
              opacity: widget.marginalMode.showsDensity ? 0.28 : 0.78,
            ),
          ),
        if (widget.marginalMode.showsDensity)
          LineChartSeries(
            id: '$id-density',
            name: 'Density estimate',
            points: densityPoints,
            color: color,
            isXOrdered: true,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.25,
          ),
        if (widget.marginalMode.showsRug)
          ScatterChartSeries(
            id: '$id-rug',
            name: 'Visible observations',
            points: positionedRugPoints,
            color: color,
            markerRadius: 2,
            markerShape: SeriesMarkerShape.square,
            markerStyle: const ScatterMarkerStyle(
              width: 1,
              height: 8,
              opacity: 0.62,
            ),
          ),
      ],
      theme: widget.theme,
      showLegend: false,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: XAxisConfig(visible: false, min: xMinimum, max: xMaximum),
      yAxis: YAxisConfig(
        position: YAxisPosition.hidden,
        min: 0,
        max: resolvedMaximum * 1.08,
      ),
      interactionConfig: const InteractionConfig(
        enableZoom: false,
        enablePan: false,
        crosshair: CrosshairConfig(enabled: false),
        tooltip: TooltipConfig(enabled: true),
      ),
    );
  }
}

class _MarginalPanel extends StatelessWidget {
  const _MarginalPanel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _MarginalSummary extends StatelessWidget {
  const _MarginalSummary({
    required this.visiblePointCount,
    required this.sourcePointCount,
    required this.marginalMode,
    required this.histogramValueMode,
  });

  final int visiblePointCount;
  final int sourcePointCount;
  final ScatterMarginalMode marginalMode;
  final HistogramValueMode histogramValueMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleShare = sourcePointCount == 0
        ? 0
        : (visiblePointCount / sourcePointCount * 100).round();
    final modeLabel = _marginalSummaryLabel(
      marginalMode,
      histogramValueMode,
      compact: true,
    );
    return Semantics(
      label:
          '$visiblePointCount of $sourcePointCount source points visible. $modeLabel.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Visible sample',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$visiblePointCount / $sourcePointCount',
                key: const ValueKey('scatter-marginal-visible-count'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '$visibleShare% in view',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          modeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _histogramValueLabel(HistogramValueMode mode) => switch (mode) {
  HistogramValueMode.count => 'Count',
  HistogramValueMode.percentage => 'Share of visible points',
  HistogramValueMode.density => 'Probability density',
};

String _scatterMarginalModeLabel(ScatterMarginalMode mode) => switch (mode) {
  ScatterMarginalMode.histogram => 'Histogram',
  ScatterMarginalMode.density => 'Density',
  ScatterMarginalMode.rug => 'Rug marks',
  ScatterMarginalMode.histogramAndDensity => 'Histogram + density',
  ScatterMarginalMode.densityAndRug => 'Density + rug',
};

String _marginalSummaryLabel(
  ScatterMarginalMode mode,
  HistogramValueMode histogramValueMode, {
  bool compact = false,
}) {
  if (compact) {
    return switch (mode) {
      ScatterMarginalMode.histogram =>
        'Bars · ${_formatMarginalValue(histogramValueMode)}',
      ScatterMarginalMode.density => 'KDE curve',
      ScatterMarginalMode.rug => 'Rug marks',
      ScatterMarginalMode.histogramAndDensity => 'Bars + KDE',
      ScatterMarginalMode.densityAndRug => 'KDE + rug',
    };
  }
  return mode == ScatterMarginalMode.histogram
      ? '${_scatterMarginalModeLabel(mode)} · ${_formatMarginalValue(histogramValueMode)}'
      : _scatterMarginalModeLabel(mode);
}

String _formatMarginalValue(HistogramValueMode mode) => switch (mode) {
  HistogramValueMode.count => 'Count',
  HistogramValueMode.percentage => 'Percentage',
  HistogramValueMode.density => 'Density',
};

class _ChartTypePreset {
  const _ChartTypePreset({
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String description;
}

class _FeatureCoverage extends StatelessWidget {
  const _FeatureCoverage({required this.family});

  final _CartesianFamily family;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final groups = switch (family) {
      _CartesianFamily.line => const [
        _FeatureGroup(
          id: 'geometry',
          label: 'Geometry',
          icon: Icons.show_chart,
          features: ['Linear', 'Bezier', 'Monotone', 'Stepped'],
        ),
        _FeatureGroup(
          id: 'presentation',
          label: 'Presentation',
          icon: Icons.auto_awesome_outlined,
          features: ['Markers', 'Point labels', 'Glow', 'Multi-axis'],
        ),
        _FeatureGroup(
          id: 'workflow',
          label: 'Motion & workflow',
          icon: Icons.motion_photos_on_outlined,
          features: [
            'Entrance reveal',
            'Data-update motion',
            'Synchronized charts',
            'Chart/data workbench',
          ],
        ),
      ],
      _CartesianFamily.area => const [
        _FeatureGroup(
          id: 'fill',
          label: 'Fill',
          icon: Icons.area_chart_outlined,
          features: [
            'Layering',
            'Fill opacity',
            'Gradient fill',
            'Positive/negative baseline',
          ],
        ),
        _FeatureGroup(
          id: 'geometry',
          label: 'Geometry',
          icon: Icons.timeline_outlined,
          features: ['Interpolation', 'Markers', 'Glow'],
        ),
        _FeatureGroup(
          id: 'workflow',
          label: 'Motion & workflow',
          icon: Icons.motion_photos_on_outlined,
          features: [
            'Entrance reveal',
            'Data-update motion',
            'Chart/data workbench',
          ],
        ),
      ],
      _CartesianFamily.scatter => const [
        _FeatureGroup(
          id: 'marks',
          label: 'Marks',
          icon: Icons.category_outlined,
          features: [
            'Multiple cohorts',
            'Marker sizing',
            'Marker shapes',
            'Point styling',
            'Point labels',
            'Deterministic jitter',
          ],
        ),
        _FeatureGroup(
          id: 'encodings',
          label: 'Encodings',
          icon: Icons.palette_outlined,
          features: [
            'Bubble size',
            'Continuous color',
            'Risk bands',
            'Quantitative opacity',
            'Categories',
          ],
        ),
        _FeatureGroup(
          id: 'analysis',
          label: 'Analysis',
          icon: Icons.query_stats_outlined,
          features: [
            'Trend annotations',
            'Robust LOESS',
            'Confidence bands',
            'Prediction bands',
            'X/Y error bars',
          ],
        ),
        _FeatureGroup(
          id: 'interaction',
          label: 'Interaction',
          icon: Icons.ads_click_outlined,
          features: [
            'Tracking tooltips',
            'Touch selection',
            'Keyboard selection',
            'Rectangle brush',
            'Free-form lasso',
          ],
        ),
        _FeatureGroup(
          id: 'density',
          label: 'Density',
          icon: Icons.blur_on_outlined,
          features: [
            'Aggregate semantics',
            'Screen-space clusters',
            'Rectangular 2D bins',
            'Hexagonal 2D bins',
            'Density contours',
          ],
        ),
        _FeatureGroup(
          id: 'composition',
          label: 'Composition',
          icon: Icons.space_dashboard_outlined,
          features: ['X/Y marginal distributions'],
        ),
      ],
    };
    final featureCount = groups.fold<int>(
      0,
      (count, group) => count + group.features.length,
    );
    return DecoratedBox(
      key: const ValueKey('feature-coverage-card'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_familyLabel(family)} capabilities',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '$featureCount features',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = constraints.maxWidth >= 1160
                    ? groups.length
                    : constraints.maxWidth >= 820
                    ? math.min(3, groups.length)
                    : constraints.maxWidth >= 520
                    ? math.min(2, groups.length)
                    : 1;
                const spacing = 8.0;
                final width =
                    (constraints.maxWidth - spacing * (columnCount - 1)) /
                    columnCount;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final group in groups)
                      SizedBox(
                        width: width,
                        child: _FeatureGroupCard(group: group),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _familyLabel(_CartesianFamily family) => switch (family) {
    _CartesianFamily.line => 'Line',
    _CartesianFamily.area => 'Area',
    _CartesianFamily.scatter => 'Scatter',
  };
}

class _FeatureGroup {
  const _FeatureGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.features,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<String> features;
}

class _FeatureGroupCard extends StatelessWidget {
  const _FeatureGroupCard({required this.group});

  final _FeatureGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: group.features.join('\n'),
      child: Semantics(
        label: '${group.label}: ${group.features.join(', ')}',
        child: SizedBox(
          height: 40,
          child: DecoratedBox(
            key: ValueKey('feature-group-${group.id}'),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(group.icon, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      child: Text(
                        '${group.features.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<ChartDataPoint> _offsetPoints(
  List<ChartDataPoint> points,
  double offset,
) => points
    .map((point) => ChartDataPoint(x: point.x, y: point.y + offset))
    .toList(growable: false);

const _primaryPoints = [
  ChartDataPoint(x: 0, y: 30),
  ChartDataPoint(x: 1, y: 38),
  ChartDataPoint(x: 2, y: 35),
  ChartDataPoint(x: 3, y: 48),
  ChartDataPoint(x: 4, y: 44),
  ChartDataPoint(x: 5, y: 55),
  ChartDataPoint(x: 6, y: 63),
  ChartDataPoint(x: 7, y: 58),
];

const _secondaryPoints = [
  ChartDataPoint(x: 0, y: 34),
  ChartDataPoint(x: 1, y: 36),
  ChartDataPoint(x: 2, y: 39),
  ChartDataPoint(x: 3, y: 43),
  ChartDataPoint(x: 4, y: 47),
  ChartDataPoint(x: 5, y: 51),
  ChartDataPoint(x: 6, y: 55),
  ChartDataPoint(x: 7, y: 59),
];

const _powerPoints = [
  ChartDataPoint(x: 0, y: 148),
  ChartDataPoint(x: 1, y: 162),
  ChartDataPoint(x: 2, y: 177),
  ChartDataPoint(x: 3, y: 196),
  ChartDataPoint(x: 4, y: 212),
  ChartDataPoint(x: 5, y: 201),
  ChartDataPoint(x: 6, y: 226),
  ChartDataPoint(x: 7, y: 218),
];

const _heartRatePoints = [
  ChartDataPoint(x: 0, y: 108),
  ChartDataPoint(x: 1, y: 116),
  ChartDataPoint(x: 2, y: 124),
  ChartDataPoint(x: 3, y: 137),
  ChartDataPoint(x: 4, y: 149),
  ChartDataPoint(x: 5, y: 156),
  ChartDataPoint(x: 6, y: 164),
  ChartDataPoint(x: 7, y: 168),
];

const _lactatePoints = [
  ChartDataPoint(x: 0, y: 0.9),
  ChartDataPoint(x: 1, y: 1.0),
  ChartDataPoint(x: 2, y: 1.2),
  ChartDataPoint(x: 3, y: 1.5),
  ChartDataPoint(x: 4, y: 1.9),
  ChartDataPoint(x: 5, y: 2.3),
  ChartDataPoint(x: 6, y: 2.8),
  ChartDataPoint(x: 7, y: 3.4),
];

const _baselinePoints = [
  ChartDataPoint(x: 0, y: 14),
  ChartDataPoint(x: 1, y: 9),
  ChartDataPoint(x: 2, y: 5),
  ChartDataPoint(x: 3, y: -3),
  ChartDataPoint(x: 4, y: -9),
  ChartDataPoint(x: 5, y: -16),
  ChartDataPoint(x: 6, y: -8),
  ChartDataPoint(x: 7, y: 4),
];

const _spotlightSignalPoints = [
  ChartDataPoint(x: 0, y: 52),
  ChartDataPoint(x: 1, y: 66),
  ChartDataPoint(x: 2, y: 59),
  ChartDataPoint(x: 3, y: 43),
  ChartDataPoint(x: 4, y: 34),
  ChartDataPoint(x: 5, y: 38),
  ChartDataPoint(x: 6, y: 51),
  ChartDataPoint(x: 7, y: 56),
  ChartDataPoint(x: 8, y: 48),
  ChartDataPoint(x: 9, y: 31),
  ChartDataPoint(x: 10, y: 25),
  ChartDataPoint(x: 11, y: 40),
  ChartDataPoint(x: 12, y: 54),
];

const _spotlightContextPoints = [
  ChartDataPoint(x: 0, y: 48),
  ChartDataPoint(x: 1, y: 52),
  ChartDataPoint(x: 2, y: 54),
  ChartDataPoint(x: 3, y: 55),
  ChartDataPoint(x: 4, y: 53),
  ChartDataPoint(x: 5, y: 49),
  ChartDataPoint(x: 6, y: 45),
  ChartDataPoint(x: 7, y: 42),
  ChartDataPoint(x: 8, y: 43),
  ChartDataPoint(x: 9, y: 47),
  ChartDataPoint(x: 10, y: 51),
  ChartDataPoint(x: 11, y: 54),
  ChartDataPoint(x: 12, y: 52),
];

const _forecastContinuousPoints = [
  ChartDataPoint(x: 0, y: 12.1),
  ChartDataPoint(x: 1, y: 11.9),
  ChartDataPoint(x: 2, y: 11.8),
  ChartDataPoint(x: 3, y: 11.7),
  ChartDataPoint(
    x: 4,
    y: 11.8,
    segmentStyle: SegmentStyle(dashPattern: [2, 6]),
  ),
  ChartDataPoint(
    x: 5,
    y: 11.4,
    segmentStyle: SegmentStyle(dashPattern: [2, 6]),
  ),
  ChartDataPoint(
    x: 6,
    y: 11.4,
    segmentStyle: SegmentStyle(dashPattern: [2, 6]),
  ),
  ChartDataPoint(
    x: 7,
    y: 11.1,
    segmentStyle: SegmentStyle(dashPattern: [2, 6]),
  ),
  ChartDataPoint(
    x: 8,
    y: 10.4,
    segmentStyle: SegmentStyle(dashPattern: [2, 6]),
  ),
  ChartDataPoint(x: 9, y: 9.9, segmentStyle: SegmentStyle(dashPattern: [2, 6])),
  ChartDataPoint(x: 10, y: 9.8),
];

const _pulseLivePoints = [
  ChartDataPoint(x: 0, y: 28),
  ChartDataPoint(x: 1, y: 34),
  ChartDataPoint(x: 2, y: 39),
  ChartDataPoint(x: 3, y: 48),
  ChartDataPoint(x: 4, y: 44),
  ChartDataPoint(x: 5, y: 56),
  ChartDataPoint(x: 6, y: 64),
  ChartDataPoint(x: 7, y: 58),
];

const _pulseTargetPoints = [
  ChartDataPoint(x: 0, y: 32),
  ChartDataPoint(x: 1, y: 36),
  ChartDataPoint(x: 2, y: 40),
  ChartDataPoint(x: 3, y: 44),
  ChartDataPoint(x: 4, y: 48),
  ChartDataPoint(x: 5, y: 52),
  ChartDataPoint(x: 6, y: 56),
  ChartDataPoint(x: 7, y: 60),
];

const _scatterTriathlon = [
  ChartDataPoint(x: 158, y: 50, label: 'TRI-01'),
  ChartDataPoint(x: 161, y: 53, label: 'TRI-02'),
  ChartDataPoint(x: 164, y: 55, label: 'TRI-03'),
  ChartDataPoint(x: 166, y: 58, label: 'TRI-04'),
  ChartDataPoint(x: 168, y: 56, label: 'TRI-05'),
  ChartDataPoint(x: 170, y: 61, label: 'TRI-06'),
  ChartDataPoint(x: 172, y: 60, label: 'TRI-07'),
  ChartDataPoint(x: 174, y: 64, label: 'TRI-08'),
  ChartDataPoint(x: 176, y: 66, label: 'TRI-09'),
  ChartDataPoint(x: 178, y: 65, label: 'TRI-10'),
  ChartDataPoint(x: 180, y: 70, label: 'TRI-11'),
  ChartDataPoint(x: 182, y: 72, label: 'TRI-12'),
  ChartDataPoint(x: 184, y: 74, label: 'TRI-13'),
];

const _scatterVolleyball = [
  ChartDataPoint(x: 172, y: 63, label: 'VOL-01'),
  ChartDataPoint(x: 175, y: 68, label: 'VOL-02'),
  ChartDataPoint(x: 178, y: 70, label: 'VOL-03'),
  ChartDataPoint(x: 181, y: 72, label: 'VOL-04'),
  ChartDataPoint(x: 184, y: 75, label: 'VOL-05'),
  ChartDataPoint(x: 186, y: 73, label: 'VOL-06'),
  ChartDataPoint(x: 188, y: 78, label: 'VOL-07'),
  ChartDataPoint(x: 190, y: 81, label: 'VOL-08'),
  ChartDataPoint(x: 192, y: 79, label: 'VOL-09'),
  ChartDataPoint(x: 194, y: 84, label: 'VOL-10'),
  ChartDataPoint(x: 196, y: 87, label: 'VOL-11'),
  ChartDataPoint(x: 198, y: 85, label: 'VOL-12'),
  ChartDataPoint(x: 200, y: 91, label: 'VOL-13'),
  ChartDataPoint(x: 202, y: 94, label: 'VOL-14'),
  ChartDataPoint(x: 205, y: 98, label: 'VOL-15'),
];

const _scatterBasketball = [
  ChartDataPoint(x: 181, y: 76, label: 'BAS-01'),
  ChartDataPoint(x: 184, y: 78, label: 'BAS-02'),
  ChartDataPoint(x: 187, y: 82, label: 'BAS-03'),
  ChartDataPoint(x: 190, y: 84, label: 'BAS-04'),
  ChartDataPoint(x: 193, y: 88, label: 'BAS-05'),
  ChartDataPoint(x: 196, y: 86, label: 'BAS-06'),
  ChartDataPoint(x: 198, y: 92, label: 'BAS-07'),
  ChartDataPoint(x: 200, y: 95, label: 'BAS-08'),
  ChartDataPoint(x: 202, y: 93, label: 'BAS-09'),
  ChartDataPoint(x: 204, y: 99, label: 'BAS-10'),
  ChartDataPoint(x: 206, y: 101, label: 'BAS-11'),
  ChartDataPoint(x: 208, y: 105, label: 'BAS-12'),
  ChartDataPoint(x: 210, y: 103, label: 'BAS-13'),
  ChartDataPoint(x: 212, y: 110, label: 'BAS-14'),
  ChartDataPoint(x: 214, y: 113, label: 'BAS-15'),
  ChartDataPoint(x: 216, y: 116, label: 'BAS-16'),
];

const _scatterTrainingBase = [
  ChartDataPoint(x: 260, y: 232, label: 'Week 1'),
  ChartDataPoint(x: 285, y: 241, label: 'Week 2'),
  ChartDataPoint(x: 310, y: 248, label: 'Week 3'),
  ChartDataPoint(x: 335, y: 246, label: 'Week 4'),
  ChartDataPoint(x: 360, y: 258, label: 'Week 5'),
  ChartDataPoint(x: 385, y: 266, label: 'Week 6'),
  ChartDataPoint(x: 410, y: 271, label: 'Week 7'),
  ChartDataPoint(x: 435, y: 278, label: 'Week 8'),
  ChartDataPoint(x: 460, y: 283, label: 'Week 9'),
  ChartDataPoint(x: 490, y: 291, label: 'Week 10'),
  ChartDataPoint(x: 520, y: 297, label: 'Week 11'),
  ChartDataPoint(x: 550, y: 304, label: 'Week 12'),
  ChartDataPoint(x: 585, y: 312, label: 'Week 13'),
  ChartDataPoint(x: 620, y: 319, label: 'Week 14'),
];

const _scatterTrainingBuild = [
  ChartDataPoint(x: 420, y: 286, label: 'Build 1'),
  ChartDataPoint(x: 455, y: 294, label: 'Build 2'),
  ChartDataPoint(x: 490, y: 301, label: 'Build 3'),
  ChartDataPoint(x: 525, y: 308, label: 'Build 4'),
  ChartDataPoint(x: 560, y: 314, label: 'Build 5'),
  ChartDataPoint(x: 600, y: 326, label: 'Build 6'),
  ChartDataPoint(x: 640, y: 331, label: 'Build 7'),
  ChartDataPoint(x: 680, y: 343, label: 'Build 8'),
  ChartDataPoint(x: 720, y: 349, label: 'Build 9'),
  ChartDataPoint(x: 760, y: 361, label: 'Build 10'),
];

const _scatterSensorExpected = [
  ChartDataPoint(x: 3.8, y: 3.9, label: 'Pair 01'),
  ChartDataPoint(x: 4.2, y: 4.1, label: 'Pair 02'),
  ChartDataPoint(x: 4.7, y: 4.8, label: 'Pair 03'),
  ChartDataPoint(x: 5.1, y: 5.0, label: 'Pair 04'),
  ChartDataPoint(x: 5.6, y: 5.8, label: 'Pair 05'),
  ChartDataPoint(x: 6.0, y: 5.9, label: 'Pair 06'),
  ChartDataPoint(x: 6.5, y: 6.6, label: 'Pair 07'),
  ChartDataPoint(x: 7.0, y: 6.8, label: 'Pair 08'),
  ChartDataPoint(x: 7.4, y: 7.5, label: 'Pair 09'),
  ChartDataPoint(x: 7.9, y: 8.1, label: 'Pair 10'),
  ChartDataPoint(x: 8.4, y: 8.3, label: 'Pair 11'),
  ChartDataPoint(x: 8.9, y: 9.0, label: 'Pair 12'),
  ChartDataPoint(x: 9.5, y: 9.3, label: 'Pair 13'),
  ChartDataPoint(x: 10.1, y: 10.2, label: 'Pair 14'),
  ChartDataPoint(x: 10.8, y: 10.6, label: 'Pair 15'),
  ChartDataPoint(x: 11.5, y: 11.7, label: 'Pair 16'),
  ChartDataPoint(x: 12.2, y: 12.0, label: 'Pair 17'),
];

const _scatterSensorReview = [
  ChartDataPoint(x: 4.5, y: 6.2, label: 'Review A'),
  ChartDataPoint(x: 6.8, y: 4.9, label: 'Review B'),
  ChartDataPoint(x: 8.6, y: 11.1, label: 'Review C'),
  ChartDataPoint(x: 10.4, y: 7.8, label: 'Review D'),
  ChartDataPoint(x: 11.8, y: 14.0, label: 'Review E'),
];

const _scatterWebChannel = [
  ChartDataPoint(x: 2.8, y: 68, label: 'Jan'),
  ChartDataPoint(x: 3.1, y: 72, label: 'Feb'),
  ChartDataPoint(x: 3.4, y: 76, label: 'Mar'),
  ChartDataPoint(x: 3.7, y: 74, label: 'Apr'),
  ChartDataPoint(x: 4.0, y: 81, label: 'May'),
  ChartDataPoint(x: 4.3, y: 84, label: 'Jun'),
  ChartDataPoint(x: 4.6, y: 88, label: 'Jul'),
  ChartDataPoint(x: 4.9, y: 91, label: 'Aug'),
  ChartDataPoint(x: 5.2, y: 89, label: 'Sep'),
  ChartDataPoint(x: 5.5, y: 97, label: 'Oct'),
  ChartDataPoint(x: 5.8, y: 101, label: 'Nov'),
  ChartDataPoint(x: 6.2, y: 105, label: 'Dec'),
];

const _scatterRetailChannel = [
  ChartDataPoint(x: 1.2, y: 96, label: 'Jan'),
  ChartDataPoint(x: 1.4, y: 102, label: 'Feb'),
  ChartDataPoint(x: 1.6, y: 99, label: 'Mar'),
  ChartDataPoint(x: 1.8, y: 108, label: 'Apr'),
  ChartDataPoint(x: 2.0, y: 112, label: 'May'),
  ChartDataPoint(x: 2.2, y: 118, label: 'Jun'),
  ChartDataPoint(x: 2.4, y: 115, label: 'Jul'),
  ChartDataPoint(x: 2.6, y: 123, label: 'Aug'),
  ChartDataPoint(x: 2.8, y: 129, label: 'Sep'),
  ChartDataPoint(x: 3.0, y: 134, label: 'Oct'),
  ChartDataPoint(x: 3.2, y: 139, label: 'Nov'),
  ChartDataPoint(x: 3.4, y: 145, label: 'Dec'),
];

const _scatterPartnerChannel = [
  ChartDataPoint(x: 0.8, y: 132, label: 'Jan'),
  ChartDataPoint(x: 1.0, y: 138, label: 'Feb'),
  ChartDataPoint(x: 1.2, y: 145, label: 'Mar'),
  ChartDataPoint(x: 1.3, y: 149, label: 'Apr'),
  ChartDataPoint(x: 1.5, y: 153, label: 'May'),
  ChartDataPoint(x: 1.6, y: 158, label: 'Jun'),
  ChartDataPoint(x: 1.8, y: 162, label: 'Jul'),
  ChartDataPoint(x: 1.9, y: 168, label: 'Aug'),
  ChartDataPoint(x: 2.1, y: 171, label: 'Sep'),
  ChartDataPoint(x: 2.2, y: 176, label: 'Oct'),
  ChartDataPoint(x: 2.4, y: 181, label: 'Nov'),
  ChartDataPoint(x: 2.6, y: 186, label: 'Dec'),
];

const _scatterStateCurrent = [
  ChartDataPoint(x: 1.0, y: 54, label: 'Week 1 · 54%'),
  ChartDataPoint(x: 1.4, y: 61, label: 'Week 1.4 · 61%'),
  ChartDataPoint(x: 1.8, y: 58, label: 'Week 1.8 · 58%'),
  ChartDataPoint(x: 2.1, y: 67, label: 'Week 2.1 · 67%'),
  ChartDataPoint(x: 2.5, y: 64, label: 'Week 2.5 · 64%'),
  ChartDataPoint(x: 2.8, y: 72, label: 'Week 2.8 · 72%'),
  ChartDataPoint(x: 3.2, y: 69, label: 'Week 3.2 · 69%'),
  ChartDataPoint(x: 3.6, y: 78, label: 'Week 3.6 · 78%'),
  ChartDataPoint(x: 4.0, y: 76, label: 'Week 4 · 76%'),
  ChartDataPoint(x: 4.4, y: 84, label: 'Week 4.4 · 84%'),
  ChartDataPoint(x: 4.8, y: 82, label: 'Week 4.8 · 82%'),
  ChartDataPoint(x: 5.2, y: 89, label: 'Week 5.2 · 89%'),
];

const _scatterEnterpriseMarkets = [
  ChartDataPoint(x: 4.2, y: 93, magnitude: 520, label: 'North America'),
  ChartDataPoint(x: 6.8, y: 89, magnitude: 410, label: 'Western Europe'),
  ChartDataPoint(x: 9.5, y: 86, magnitude: 285, label: 'Nordics'),
  ChartDataPoint(x: 12.4, y: 82, magnitude: 190, label: 'Australia'),
  ChartDataPoint(x: 15.8, y: 79, magnitude: 120, label: 'Japan'),
];

const _scatterGrowthMarkets = [
  ChartDataPoint(x: 8.2, y: 75, magnitude: 560, label: 'Brazil'),
  ChartDataPoint(x: 11.6, y: 84, magnitude: 330, label: 'UAE'),
  ChartDataPoint(x: 14.1, y: 72, magnitude: 450, label: 'India'),
  ChartDataPoint(x: 17.5, y: 77, magnitude: 230, label: 'Mexico'),
  ChartDataPoint(x: 20.3, y: 68, magnitude: 95, label: 'South Africa'),
];

const _scatterReadyAthletes = [
  ChartDataPoint(x: 310, y: 286, colorValue: 92, label: 'A. Mokoena'),
  ChartDataPoint(x: 345, y: 301, colorValue: 88, label: 'L. Jacobs'),
  ChartDataPoint(x: 375, y: 318, colorValue: 83, label: 'T. Naidoo'),
  ChartDataPoint(x: 410, y: 329, colorValue: 79, label: 'S. Williams'),
  ChartDataPoint(x: 455, y: 344, colorValue: 75, label: 'K. Dlamini'),
  ChartDataPoint(x: 500, y: 351, colorValue: 71, label: 'R. Botha'),
  ChartDataPoint(x: 540, y: 365, colorValue: 68, label: 'N. Smith'),
  ChartDataPoint(x: 585, y: 372, colorValue: 64, label: 'P. Nkosi'),
];

const _scatterFatiguedAthletes = [
  ChartDataPoint(x: 330, y: 274, colorValue: 78, label: 'C. Meyer'),
  ChartDataPoint(x: 390, y: 295, colorValue: 72, label: 'B. Khumalo'),
  ChartDataPoint(x: 430, y: 308, colorValue: 66, label: 'J. van Wyk'),
  ChartDataPoint(x: 475, y: 321, colorValue: 61, label: 'M. Daniels'),
  ChartDataPoint(x: 520, y: 327, colorValue: 56, label: 'Z. Cele'),
  ChartDataPoint(x: 565, y: 339, colorValue: 52, label: 'E. Petersen'),
  ChartDataPoint(x: 610, y: 346, colorValue: 48, label: 'D. Ncube'),
];

const _scatterEquipmentRisk = [
  ChartDataPoint(x: 1.8, y: 52, colorValue: 18, label: 'Cooling pump A'),
  ChartDataPoint(x: 2.4, y: 58, colorValue: 28, label: 'Conveyor motor 3'),
  ChartDataPoint(x: 3.1, y: 61, colorValue: 35, label: 'Compressor B'),
  ChartDataPoint(x: 3.8, y: 67, colorValue: 44, label: 'Feed pump 2'),
  ChartDataPoint(x: 4.6, y: 64, colorValue: 53, label: 'Blower fan 1'),
  ChartDataPoint(x: 5.2, y: 74, colorValue: 60, label: 'Hydraulic pack'),
  ChartDataPoint(x: 6.0, y: 71, colorValue: 68, label: 'Transfer pump'),
  ChartDataPoint(x: 6.7, y: 82, colorValue: 76, label: 'Crusher bearing'),
  ChartDataPoint(x: 7.4, y: 86, colorValue: 80, label: 'Kiln fan gearbox'),
  ChartDataPoint(x: 8.1, y: 91, colorValue: 88, label: 'Main compressor'),
  ChartDataPoint(x: 8.8, y: 79, colorValue: 72, label: 'Extraction fan'),
  ChartDataPoint(x: 9.4, y: 96, colorValue: 96, label: 'Turbine bearing'),
];

const _scatterBaselineForecast = [
  ChartDataPoint(
    x: 1,
    y: 84,
    opacityValue: 96,
    label: 'Day 1 · 96% confidence',
  ),
  ChartDataPoint(
    x: 3,
    y: 88,
    opacityValue: 91,
    label: 'Day 3 · 91% confidence',
  ),
  ChartDataPoint(
    x: 5,
    y: 92,
    opacityValue: 84,
    label: 'Day 5 · 84% confidence',
  ),
  ChartDataPoint(
    x: 7,
    y: 86,
    opacityValue: 78,
    label: 'Day 7 · 78% confidence',
  ),
  ChartDataPoint(
    x: 10,
    y: 97,
    opacityValue: 69,
    label: 'Day 10 · 69% confidence',
  ),
  ChartDataPoint(
    x: 14,
    y: 103,
    opacityValue: 58,
    label: 'Day 14 · 58% confidence',
  ),
  ChartDataPoint(
    x: 21,
    y: 95,
    opacityValue: 47,
    label: 'Day 21 · 47% confidence',
  ),
];

const _scatterAdaptiveForecast = [
  ChartDataPoint(
    x: 1,
    y: 81,
    opacityValue: 98,
    label: 'Day 1 · 98% confidence',
  ),
  ChartDataPoint(
    x: 3,
    y: 86,
    opacityValue: 95,
    label: 'Day 3 · 95% confidence',
  ),
  ChartDataPoint(
    x: 5,
    y: 90,
    opacityValue: 92,
    label: 'Day 5 · 92% confidence',
  ),
  ChartDataPoint(
    x: 7,
    y: 89,
    opacityValue: 88,
    label: 'Day 7 · 88% confidence',
  ),
  ChartDataPoint(
    x: 10,
    y: 94,
    opacityValue: 82,
    label: 'Day 10 · 82% confidence',
  ),
  ChartDataPoint(
    x: 14,
    y: 99,
    opacityValue: 74,
    label: 'Day 14 · 74% confidence',
  ),
  ChartDataPoint(
    x: 21,
    y: 101,
    opacityValue: 63,
    label: 'Day 21 · 63% confidence',
  ),
];

const _scatterFleetVehicles = [
  ChartDataPoint(x: 62, y: 4.8, categoryValue: 'electric', label: 'City EV 01'),
  ChartDataPoint(x: 88, y: 5.1, categoryValue: 'electric', label: 'City EV 02'),
  ChartDataPoint(
    x: 118,
    y: 5.5,
    categoryValue: 'electric',
    label: 'Regional EV 01',
  ),
  ChartDataPoint(
    x: 146,
    y: 5.9,
    categoryValue: 'electric',
    label: 'Regional EV 02',
  ),
  ChartDataPoint(
    x: 176,
    y: 6.4,
    categoryValue: 'electric',
    label: 'Long-range EV 01',
  ),
  ChartDataPoint(
    x: 205,
    y: 6.8,
    categoryValue: 'electric',
    label: 'Long-range EV 02',
  ),
  ChartDataPoint(x: 58, y: 6.3, categoryValue: 'hybrid', label: 'City PHEV 01'),
  ChartDataPoint(x: 82, y: 6.7, categoryValue: 'hybrid', label: 'City PHEV 02'),
  ChartDataPoint(
    x: 108,
    y: 7.0,
    categoryValue: 'hybrid',
    label: 'Regional PHEV 01',
  ),
  ChartDataPoint(
    x: 134,
    y: 7.5,
    categoryValue: 'hybrid',
    label: 'Regional PHEV 02',
  ),
  ChartDataPoint(
    x: 162,
    y: 7.8,
    categoryValue: 'hybrid',
    label: 'Touring PHEV 01',
  ),
  ChartDataPoint(
    x: 194,
    y: 8.2,
    categoryValue: 'hybrid',
    label: 'Touring PHEV 02',
  ),
  ChartDataPoint(
    x: 54,
    y: 8.1,
    categoryValue: 'combustion',
    label: 'City ICE 01',
  ),
  ChartDataPoint(
    x: 76,
    y: 8.6,
    categoryValue: 'combustion',
    label: 'City ICE 02',
  ),
  ChartDataPoint(
    x: 102,
    y: 9.2,
    categoryValue: 'combustion',
    label: 'Regional ICE 01',
  ),
  ChartDataPoint(
    x: 128,
    y: 9.6,
    categoryValue: 'combustion',
    label: 'Regional ICE 02',
  ),
  ChartDataPoint(
    x: 158,
    y: 10.1,
    categoryValue: 'combustion',
    label: 'Touring ICE 01',
  ),
  ChartDataPoint(
    x: 188,
    y: 10.7,
    categoryValue: 'combustion',
    label: 'Touring ICE 02',
  ),
];

const _scatterSurveyResponseValues = <({double x, double y, String category})>[
  (x: 3, y: 3, category: 'standard'),
  (x: 3, y: 3, category: 'standard'),
  (x: 3, y: 3, category: 'standard'),
  (x: 4, y: 4, category: 'standard'),
  (x: 4, y: 4, category: 'standard'),
  (x: 4, y: 4, category: 'standard'),
  (x: 4, y: 4, category: 'standard'),
  (x: 4, y: 5, category: 'standard'),
  (x: 4, y: 5, category: 'standard'),
  (x: 5, y: 4, category: 'standard'),
  (x: 5, y: 4, category: 'standard'),
  (x: 5, y: 4, category: 'standard'),
  (x: 3, y: 4, category: 'professional'),
  (x: 3, y: 4, category: 'professional'),
  (x: 4, y: 4, category: 'professional'),
  (x: 4, y: 4, category: 'professional'),
  (x: 4, y: 4, category: 'professional'),
  (x: 4, y: 5, category: 'professional'),
  (x: 4, y: 5, category: 'professional'),
  (x: 4, y: 5, category: 'professional'),
  (x: 4, y: 5, category: 'professional'),
  (x: 5, y: 5, category: 'professional'),
  (x: 5, y: 5, category: 'professional'),
  (x: 5, y: 5, category: 'professional'),
  (x: 3, y: 3, category: 'enterprise'),
  (x: 3, y: 4, category: 'enterprise'),
  (x: 3, y: 4, category: 'enterprise'),
  (x: 4, y: 4, category: 'enterprise'),
  (x: 4, y: 4, category: 'enterprise'),
  (x: 4, y: 5, category: 'enterprise'),
  (x: 4, y: 5, category: 'enterprise'),
  (x: 4, y: 5, category: 'enterprise'),
  (x: 5, y: 4, category: 'enterprise'),
  (x: 5, y: 4, category: 'enterprise'),
  (x: 5, y: 5, category: 'enterprise'),
  (x: 5, y: 5, category: 'enterprise'),
];

final List<ChartDataPoint> _scatterSurveyResponses = [
  for (var index = 0; index < _scatterSurveyResponseValues.length; index++)
    ChartDataPoint(
      x: _scatterSurveyResponseValues[index].x,
      y: _scatterSurveyResponseValues[index].y,
      categoryValue: _scatterSurveyResponseValues[index].category,
      label: 'Response ${(index + 1).toString().padLeft(2, '0')}',
    ),
];

const _scatterCampaignResponse = [
  ChartDataPoint(x: 1, y: 1.2, label: 'Cohort 01'),
  ChartDataPoint(x: 1, y: 1.8, label: 'Cohort 02'),
  ChartDataPoint(x: 2, y: 2.4, label: 'Cohort 03'),
  ChartDataPoint(x: 2, y: 3.1, label: 'Cohort 04'),
  ChartDataPoint(x: 2, y: 2.7, label: 'Cohort 05'),
  ChartDataPoint(x: 3, y: 4.2, label: 'Cohort 06'),
  ChartDataPoint(x: 3, y: 4.8, label: 'Cohort 07'),
  ChartDataPoint(x: 4, y: 6.1, label: 'Cohort 08'),
  ChartDataPoint(x: 4, y: 6.7, label: 'Cohort 09'),
  ChartDataPoint(x: 4, y: 5.8, label: 'Cohort 10'),
  ChartDataPoint(x: 5, y: 7.6, label: 'Cohort 11'),
  ChartDataPoint(x: 5, y: 8.1, label: 'Cohort 12'),
  ChartDataPoint(x: 6, y: 8.8, label: 'Cohort 13'),
  ChartDataPoint(x: 6, y: 9.2, label: 'Cohort 14'),
  ChartDataPoint(x: 6, y: 2.1, label: 'Anomalous cohort A'),
  ChartDataPoint(x: 7, y: 9.4, label: 'Cohort 15'),
  ChartDataPoint(x: 7, y: 9.8, label: 'Cohort 16'),
  ChartDataPoint(x: 8, y: 9.2, label: 'Cohort 17'),
  ChartDataPoint(x: 8, y: 8.8, label: 'Cohort 18'),
  ChartDataPoint(x: 9, y: 7.8, label: 'Cohort 19'),
  ChartDataPoint(x: 9, y: 8.2, label: 'Cohort 20'),
  ChartDataPoint(x: 10, y: 6.4, label: 'Cohort 21'),
  ChartDataPoint(x: 10, y: 6.9, label: 'Cohort 22'),
  ChartDataPoint(x: 10, y: 15, label: 'Anomalous cohort B'),
  ChartDataPoint(x: 11, y: 5.2, label: 'Cohort 23'),
  ChartDataPoint(x: 11, y: 5.8, label: 'Cohort 24'),
  ChartDataPoint(x: 12, y: 4.1, label: 'Cohort 25'),
  ChartDataPoint(x: 12, y: 4.5, label: 'Cohort 26'),
];

const _scatterAssayCalibration = [
  ChartDataPoint(x: 2.0, y: 13.5, label: 'Run 01'),
  ChartDataPoint(x: 4.0, y: 23.8, label: 'Run 02'),
  ChartDataPoint(x: 6.0, y: 30.4, label: 'Run 03'),
  ChartDataPoint(x: 8.0, y: 41.7, label: 'Run 04'),
  ChartDataPoint(x: 10.0, y: 48.6, label: 'Run 05'),
  ChartDataPoint(x: 12.0, y: 59.9, label: 'Run 06'),
  ChartDataPoint(x: 14.0, y: 64.2, label: 'Run 07'),
  ChartDataPoint(x: 16.0, y: 76.8, label: 'Run 08'),
  ChartDataPoint(x: 18.0, y: 83.1, label: 'Run 09'),
  ChartDataPoint(x: 20.0, y: 92.4, label: 'Run 10'),
];

const _scatterPriorityAccounts = [
  ChartDataPoint(x: 2.0, y: 7.8, label: 'Aster Labs'),
  ChartDataPoint(x: 3.1, y: 6.9, label: 'Northstar'),
  ChartDataPoint(x: 4.2, y: 7.4, label: 'Beacon Health'),
  ChartDataPoint(x: 4.8, y: 6.6, label: 'Koru Systems'),
  ChartDataPoint(x: 5.4, y: 7.1, label: 'Lumen Works'),
  ChartDataPoint(x: 6.6, y: 8.2, label: 'Summit Co'),
  ChartDataPoint(x: 7.3, y: 6.8, label: 'Mosaic'),
  ChartDataPoint(x: 8.1, y: 7.6, label: 'Atlas Group'),
  ChartDataPoint(x: 8.7, y: 8.6, label: 'Copper Cloud'),
];

const _scatterMonitorAccounts = [
  ChartDataPoint(x: 1.4, y: 3.0, label: 'Bluebird'),
  ChartDataPoint(x: 2.8, y: 4.4, label: 'Cedar Inc'),
  ChartDataPoint(x: 4.0, y: 5.5, label: 'Delta Foods'),
  ChartDataPoint(x: 4.5, y: 6.3, label: 'Harbour'),
  ChartDataPoint(x: 5.1, y: 6.8, label: 'Juniper'),
  ChartDataPoint(x: 5.7, y: 7.0, label: 'Meridian'),
  ChartDataPoint(x: 6.9, y: 5.7, label: 'Redwood'),
  ChartDataPoint(x: 7.8, y: 4.9, label: 'Solace'),
  ChartDataPoint(x: 8.5, y: 3.8, label: 'Vertex'),
];

const _scatterStatePrevious = [
  ChartDataPoint(x: 1.1, y: 49, label: 'Week 1.1 · 49%'),
  ChartDataPoint(x: 1.5, y: 56, label: 'Week 1.5 · 56%'),
  ChartDataPoint(x: 1.9, y: 53, label: 'Week 1.9 · 53%'),
  ChartDataPoint(x: 2.2, y: 62, label: 'Week 2.2 · 62%'),
  ChartDataPoint(x: 2.6, y: 59, label: 'Week 2.6 · 59%'),
  ChartDataPoint(x: 3.0, y: 67, label: 'Week 3 · 67%'),
  ChartDataPoint(x: 3.4, y: 65, label: 'Week 3.4 · 65%'),
  ChartDataPoint(x: 3.8, y: 72, label: 'Week 3.8 · 72%'),
  ChartDataPoint(x: 4.2, y: 70, label: 'Week 4.2 · 70%'),
  ChartDataPoint(x: 4.6, y: 77, label: 'Week 4.6 · 77%'),
  ChartDataPoint(x: 5.0, y: 75, label: 'Week 5 · 75%'),
  ChartDataPoint(x: 5.4, y: 83, label: 'Week 5.4 · 83%'),
];
