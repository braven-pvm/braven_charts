// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../data/polar_showcase_randomizer.dart';
import '../widgets/options_panel.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

/// Public, renderer-backed guide for axis-based Polar Column charts.
class PolarColumnPage extends StatefulWidget {
  const PolarColumnPage({super.key});

  @override
  State<PolarColumnPage> createState() => _PolarColumnPageState();
}

class _PolarColumnPageState extends State<PolarColumnPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final math.Random _random = math.Random(47);

  late final ShowcaseRandomizerController<PolarShowcaseRandomization>
  _showcaseRandomizer;
  bool _randomizedShowcaseSelected = false;
  _PolarPresentation _authoredPresentation = _PolarPresentation.standard;
  _PolarPresentation _presentation = _PolarPresentation.standard;
  late Map<String, num> _values;
  late Map<String, num> _comparisonValues;
  late Map<String, num> _tertiaryValues;
  int _categoryCount = 8;
  double _startAngle = -90;
  double _sweepAngle = 360;
  bool _clockwise = true;
  double _innerRadius = 0;
  double _outerRadius = 0.84;
  double _innerPadding = 0.12;
  double _outerPadding = 0.04;

  int? get _appliedRandomizerSeed => _showcaseRandomizer.appliedSeed;
  PolarColumnCompositionMode _compositionMode =
      PolarColumnCompositionMode.layered;
  double _groupInnerPadding = 0.12;
  PolarRadialScaleMode _scaleMode = PolarRadialScaleMode.linear;
  int _tickCount = 5;
  bool _showAngularLabels = true;
  bool _showAngularGrid = true;
  int _maximumAngularLabels = 24;
  int _maximumAngularGridLines = 72;
  bool _showRadialLabels = true;
  bool _showRadialGrid = true;
  bool _showValues = true;
  int _maximumDataLabels = 24;
  double _categoryLabelOffset = 0;
  Color? _categoryLabelColor;
  double _categoryLabelSize = 12;
  FontWeight _categoryLabelWeight = FontWeight.w400;
  double _valueLabelRadialPosition = 0.5;
  Color? _valueLabelColor;
  double _valueLabelSize = 11;
  FontWeight _valueLabelWeight = FontWeight.w600;
  PolarRadialLabelPosition _radialLabelPosition =
      PolarRadialLabelPosition.start;
  double _radialLabelAngleOffset = 0;
  double _radialLabelOffset = 4;
  Color? _radialLabelColor;
  double _radialLabelSize = 10;
  FontWeight _radialLabelWeight = FontWeight.w500;
  double _cornerRadius = 4;
  PolarColumnCornerRadiusMode _cornerRadiusMode =
      PolarColumnCornerRadiusMode.outerEnd;
  double _opacity = 0.94;
  bool _showGradient = false;
  Color? _gradientStartColor;
  Color? _gradientEndColor;
  double _gradientStartLightness = 0.16;
  double _gradientEndLightness = -0.12;
  bool _showColumnShadow = false;
  Color? _columnShadowColor;
  double _columnShadowBlur = 8;
  double _columnShadowSpread = 0;
  double _columnShadowOffsetX = 0;
  double _columnShadowOffsetY = 4;
  double _columnShadowOpacity = 0.28;
  PolarColumnAnimationMode _animationMode = PolarColumnAnimationMode.sweep;
  bool _showTargets = true;
  bool _showThreshold = true;
  double _thresholdValue = 80;
  double _targetMarkerWidth = 3;
  double _targetMarkerLength = 0.68;
  bool _showIntervals = true;
  PolarColumnIntervalDisplay _intervalDisplay =
      PolarColumnIntervalDisplay.whisker;
  double _intervalWidth = 2;
  double _intervalCapLength = 0.62;
  double _intervalBandLength = 0.58;
  double _intervalOpacity = 0.92;
  _PolarThemePreset _themePreset = _PolarThemePreset.light;
  _PolarPalette _palette = _PolarPalette.theme;
  Color? _canvasColor;
  Color? _axisLineColor;
  Color? _axisLabelColor;
  double _axisLineWidth = 1;
  double _axisLabelSize = 12;
  Color? _gridLineColor;
  double _gridLineWidth = 1;
  _PolarLinePattern _gridLinePattern = _PolarLinePattern.solid;
  Color? _columnBorderColor;
  double _columnBorderWidth = 0.75;
  Color? _targetColor;
  double _targetOpacity = 1;
  Color? _thresholdColor;
  double _thresholdWidth = 2;
  _PolarLinePattern _thresholdPattern = _PolarLinePattern.dashed;
  Color? _intervalColor;
  bool _showTooltip = true;
  TooltipTriggerMode _tooltipTrigger = TooltipTriggerMode.hover;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  double _tooltipOffset = 8;
  Color? _tooltipBackgroundColor;
  Color? _tooltipTextColor;
  Color? _tooltipBorderColor;
  double _tooltipBorderWidth = 1;
  double _tooltipCornerRadius = 6;
  RadialSelectionEffect _selectionEffect = RadialSelectionEffect.explode;
  double _selectionScale = 1.08;
  double _selectionOffset = 6;
  double _selectionBackdropBlur = 1.25;
  Color? _selectionColor;
  String? _selectedCategory;
  String? _selectedSeries;

  static const _labelWeights = <FontWeight>[
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

  static const _standardValues = <String, num>{
    'Search': 86,
    'Social': 58,
    'Partners': 72,
    'Email': 44,
    'Events': 65,
    'Direct': 92,
    'Referral': 54,
    'Other': 36,
  };

  static const _roseValues = <String, num>{
    'Jan': 42,
    'Feb': 58,
    'Mar': 76,
    'Apr': 63,
    'May': 88,
    'Jun': 54,
    'Jul': 97,
    'Aug': 82,
    'Sep': 69,
    'Oct': 74,
    'Nov': 49,
    'Dec': 61,
  };

  static const _partialValues = <String, num>{
    'Discover': 84,
    'Evaluate': 62,
    'Trial': 73,
    'Adopt': 91,
    'Expand': 66,
    'Renew': 79,
  };

  static const _layeredObservedValues = <String, num>{
    'Search': 72,
    'Social': 48,
    'Partners': 68,
    'Email': 39,
    'Events': 61,
    'Direct': 83,
  };

  static const _layeredCapacityValues = <String, num>{
    'Search': 92,
    'Social': 70,
    'Partners': 84,
    'Email': 62,
    'Events': 78,
    'Direct': 96,
  };

  static const _groupedNorthValues = <String, num>{
    'Search': 78,
    'Social': 46,
    'Partners': 64,
    'Email': 52,
    'Events': 70,
    'Direct': 58,
  };

  static const _groupedSouthValues = <String, num>{
    'Search': 62,
    'Social': 69,
    'Partners': 51,
    'Email': 73,
    'Events': 55,
    'Direct': 82,
  };

  static const _groupedWestValues = <String, num>{
    'Search': 54,
    'Social': 57,
    'Partners': 76,
    'Email': 61,
    'Events': 84,
    'Direct': 67,
  };

  static const _stackedNewValues = <String, num>{
    'Search': 34,
    'Social': 26,
    'Partners': 31,
    'Email': 19,
    'Events': 28,
    'Direct': 37,
  };

  static const _stackedExpansionValues = <String, num>{
    'Search': 16,
    'Social': 12,
    'Partners': 18,
    'Email': 11,
    'Events': 15,
    'Direct': 20,
  };

  static const _stackedChurnValues = <String, num>{
    'Search': -13,
    'Social': -21,
    'Partners': -12,
    'Email': -17,
    'Events': -10,
    'Direct': -15,
  };

  static const _referenceActualValues = <String, num>{
    'Search': 74,
    'Social': 56,
    'Partners': 83,
    'Email': 48,
    'Events': 69,
    'Direct': 91,
  };

  static const _referenceTargetValues = <String, num>{
    'Search': 78,
    'Social': 62,
    'Partners': 80,
    'Email': 55,
    'Events': 72,
    'Direct': 88,
  };

  static const _uncertaintyValues = <String, num>{
    'Search': 72,
    'Social': 58,
    'Partners': 81,
    'Email': 46,
    'Events': 67,
    'Direct': 88,
  };

  static const _uncertaintyLowerValues = <String, num>{
    'Search': 63,
    'Social': 49,
    'Partners': 70,
    'Email': 38,
    'Events': 57,
    'Direct': 76,
  };

  static const _uncertaintyUpperValues = <String, num>{
    'Search': 84,
    'Social': 69,
    'Partners': 94,
    'Email': 56,
    'Events': 79,
    'Direct': 103,
  };

  static const _colorChoices = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
    Color(0xFFE2E8F0),
    Color(0xFF94A3B8),
    Color(0xFF334155),
    Color(0xFF0F172A),
    Color(0xFF111827),
    Color(0xFF000000),
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFDC2626),
    Color(0xFF9333EA),
  ];

  @override
  void initState() {
    super.initState();
    _showcaseRandomizer =
        ShowcaseRandomizerController<PolarShowcaseRandomization>(
          generate: PolarShowcaseRandomizer.generate,
          apply: _applyGeneratedRandomization,
        );
    _values = Map<String, num>.of(_standardValues);
    _comparisonValues = const {};
    _tertiaryValues = const {};
  }

  @override
  void dispose() {
    _showcaseRandomizer.dispose();
    _workbenchController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Polar Column',
      subtitle:
          'Compare category magnitudes on angular categories and a numeric radial axis',
      actions: _randomizedShowcaseSelected
          ? [
              OutlinedButton.icon(
                key: const ValueKey('polar-column-regenerate'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: _regenerateValues,
                icon: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('Regenerate values'),
              ),
            ]
          : null,
      playground: ChartPlaygroundConfig(
        active: _randomizedShowcaseSelected,
        optionsChildren: _buildPlaygroundOptions(),
        randomizer: _showcaseRandomizer,
      ),
      randomizerKeyPrefix: 'polar-randomizer',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const ValueKey('polar-column-showcase-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresentationSelector(),
              const SizedBox(height: 16),
              _buildInteractionNotice(),
              const SizedBox(height: 16),
              _buildChartCard(),
              const SizedBox(height: 32),
              _buildFeatureGuide(),
              const SizedBox(height: 32),
              _buildCodeRecipe(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresentationSelector() {
    return Semantics(
      container: true,
      label: 'Choose a Polar Column example',
      child: ShowcaseExampleGrid(
        key: const ValueKey('polar-presentation-selector'),
        children: [
          for (final presentation in _PolarPresentation.values)
            _PresentationCard(
              presentation: presentation,
              selected:
                  !_randomizedShowcaseSelected && presentation == _presentation,
              onPressed: () => _applyPresentation(presentation),
            ),
          PlaygroundExampleCard(
            key: const ValueKey('polar-playground'),
            selected: _randomizedShowcaseSelected,
            onTap: () => _setPlaygroundActive(true),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionNotice() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selection = _selectedCategory == null
        ? 'Select a column to inspect its exact category and value.'
        : 'Selected: ${_selectedSeries == null ? '' : '$_selectedSeries · '}$_selectedCategory. '
              'Select it again or press Escape to clear.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.ads_click_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Angle finds the category; radius compares the value',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selection Use arrow keys to move between columns and Enter to select.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final theme = Theme.of(context);
    final chartTheme = _buildChartTheme();
    final config = _buildPolarConfig();
    final chartSeries = _buildSeriesList();

    return Card(
      key: const ValueKey('polar-column-chart-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _randomizedShowcaseSelected
                            ? 'Polar Column playground'
                            : _presentation.chartTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _randomizedShowcaseSelected
                            ? 'Generated data and every compatible Polar Column property.'
                            : _presentation.chartSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_appliedRandomizerSeed case final seed?)
                        _MetricChip(label: 'Generated seed $seed'),
                      _MetricChip(label: '${_values.length} categories'),
                      _MetricChip(
                        label: _scaleMode == PolarRadialScaleMode.areaCorrect
                            ? 'Area-correct'
                            : 'Linear radius',
                      ),
                      if (chartSeries.length > 1)
                        _MetricChip(
                          label:
                              '${chartSeries.length} ${switch (_compositionMode) {
                                PolarColumnCompositionMode.layered => 'layered',
                                PolarColumnCompositionMode.grouped => 'grouped',
                                PolarColumnCompositionMode.stacked => 'stacked',
                              }} series',
                        ),
                      if (_presentation == _PolarPresentation.references)
                        _MetricChip(
                          label: switch ((_showTargets, _showThreshold)) {
                            (true, true) => 'Targets + threshold',
                            (true, false) => 'Category targets',
                            (false, true) => 'Capacity threshold',
                            (false, false) => 'References hidden',
                          },
                        ),
                      if (_presentation == _PolarPresentation.intervals)
                        _MetricChip(
                          label: !_showIntervals
                              ? 'Intervals hidden'
                              : _intervalDisplay ==
                                    PolarColumnIntervalDisplay.whisker
                              ? 'Uncertainty whiskers'
                              : 'Range bands',
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (chartSeries.length > 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final (index, series) in chartSeries.indexed)
                    _SeriesKey(
                      color:
                          series.color ??
                          chartTheme.seriesTheme.colors[index %
                              chartTheme.seriesTheme.colors.length],
                      label: _seriesKeyLabel(series, index),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              key: const ValueKey('polar-column-live-chart'),
              height: 620,
              child: BravenChartWorkbench(
                chartController: _chartController,
                workbenchController: _workbenchController,
                initialDisplayMode: ChartDisplayMode.chart,
                availableDisplayModes: const {
                  ChartDisplayMode.chart,
                  ChartDisplayMode.data,
                  ChartDisplayMode.split,
                  ChartDisplayMode.source,
                },
                sourceOptions: const ChartDartSourceOptions(
                  variableName: 'polarColumnChart',
                ),
                splitBreakpoint: 1,
                splitGap: 8,
                minimumChartPaneExtent: 360,
                minimumTablePaneExtent: 420,
                maximumAutoTablePaneExtent: 560,
                autoFitTablePane: true,
                isSplitResizable: true,
                documentOptions: const ChartDocumentExtractOptions(
                  includeViewState: true,
                ),
                tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
                onTableRowFocused: _focusTablePoints,
                onTableRowFocusCleared: _chartController.clearPointFocus,
                onTableRowHoverChanged: (points) => points == null
                    ? _chartController.clearPointFocus()
                    : _focusTablePoints(points),
                onTableRowActivated: _selectTablePoints,
                chartBuilder: (context, controller) => BravenChartPlus(
                  key: const ValueKey('polar-column-chart'),
                  series: chartSeries,
                  polarChartConfig: config,
                  bravenChartController: controller,
                  theme: chartTheme,
                  showLegend: false,
                  interactionConfig: InteractionConfig(
                    tooltip: TooltipConfig(
                      enabled: _showTooltip,
                      triggerMode: _tooltipTrigger,
                      preferredPosition: _tooltipPosition,
                      offsetFromPoint: _tooltipOffset,
                      style: TooltipStyle(
                        backgroundColor: _effectiveTooltipBackgroundColor,
                        borderColor: _effectiveTooltipBorderColor,
                        borderWidth: _tooltipBorderWidth,
                        borderRadius: _tooltipCornerRadius,
                        textColor: _effectiveTooltipTextColor,
                      ),
                    ),
                  ),
                  onPointTap: _handlePointActivation,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PolarChartConfig _buildPolarConfig() => PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: _startAngle,
      sweepAngleDegrees: _sweepAngle,
      clockwise: _clockwise,
      innerRadiusFactor: _innerRadius,
      outerRadiusFactor: _outerRadius,
    ),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: _innerPadding,
      outerPadding: _outerPadding,
      showLabels: _showAngularLabels,
      showGridLines: _showAngularGrid,
      maximumVisibleLabels: _maximumAngularLabels,
      maximumVisibleGridLines: _maximumAngularGridLines,
      labelOffset: _categoryLabelOffset,
      labelStyle: PolarLabelStyle(
        color: _categoryLabelColor,
        fontSize: _categoryLabelSize,
        fontWeight: _categoryLabelWeight,
      ),
    ),
    radialAxis: PolarNumericAxisConfig(
      scaleMode: _scaleMode,
      tickCount: _tickCount,
      showLabels: _showRadialLabels,
      showGridLines: _showRadialGrid,
      labelPosition: _radialLabelPosition,
      labelAngleOffsetDegrees: _radialLabelAngleOffset,
      labelOffset: _radialLabelOffset,
      labelStyle: PolarLabelStyle(
        color: _radialLabelColor,
        fontSize: _radialLabelSize,
        fontWeight: _radialLabelWeight,
      ),
    ),
    composition: PolarColumnCompositionConfig(
      mode: _compositionMode,
      groupInnerPadding: _groupInnerPadding,
    ),
    thresholds: _presentation == _PolarPresentation.references && _showThreshold
        ? <PolarThreshold>[
            PolarThreshold(
              value: _thresholdValue,
              label: 'Capacity',
              color: _effectiveThresholdColor,
              width: _thresholdWidth,
              dashPattern: _thresholdPattern.pattern,
            ),
          ]
        : const <PolarThreshold>[],
  );

  String _seriesKeyLabel(PolarColumnChartSeries series, int index) {
    if (_presentation == _PolarPresentation.layered) {
      return index == 0
          ? '${series.name ?? series.id} · reference layer'
          : '${series.name ?? series.id} · foreground layer';
    }
    return series.name ?? series.id;
  }

  void _focusTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ??
        _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    _chartController.focusPoints(points, revision: revision);
  }

  void _selectTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ??
        _workbenchController.tableSnapshot?.revision;
    if (revision == null || points.isEmpty) return;
    final target = points.first;
    if (_chartController.selectedPointRefs.contains(target)) {
      _chartController.clearPointSelection();
      setState(() {
        _selectedCategory = null;
        _selectedSeries = null;
      });
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      final series = _seriesForId(target.seriesId);
      final point = target.pointIndex < series.points.length
          ? series.points[target.pointIndex]
          : null;
      setState(() {
        _selectedCategory = point?.label;
        _selectedSeries = series.name ?? series.id;
      });
    }
  }

  void _handlePointActivation(ChartDataPoint point, String seriesId) {
    final pointIndex = point.x.round();
    final isSelected = _chartController.selectedPointRefs.contains(
      ChartPointRef(seriesId: seriesId, pointIndex: pointIndex),
    );
    final series = _seriesForId(seriesId);
    setState(() {
      _selectedCategory = isSelected ? point.label : null;
      _selectedSeries = isSelected ? (series.name ?? series.id) : null;
    });
  }

  PolarColumnChartSeries _seriesForId(String seriesId) =>
      _buildSeriesList().firstWhere((series) => series.id == seriesId);

  List<PolarColumnChartSeries> _buildSeriesList() {
    final palette = _categoryColors;
    final colors = <String, Color>{};
    for (final (index, category) in _values.keys.indexed) {
      colors[category] = palette[index % palette.length];
    }
    final style = PolarColumnStyle(
      cornerRadius: _cornerRadius,
      cornerRadiusMode: _cornerRadiusMode,
      opacity: _opacity,
      borderColor: _effectiveColumnBorderColor,
      borderWidth: _columnBorderWidth,
      showDataLabels: _showValues,
      maximumVisibleDataLabels: _maximumDataLabels,
      dataLabelRadialPosition: _valueLabelRadialPosition,
      dataLabelStyle: PolarLabelStyle(
        color: _valueLabelColor,
        fontSize: _valueLabelSize,
        fontWeight: _valueLabelWeight,
      ),
      gradient: _showGradient
          ? PolarColumnGradientStyle(
              startColor: _gradientStartColor,
              endColor: _gradientEndColor,
              startLightnessShift: _gradientStartLightness,
              endLightnessShift: _gradientEndLightness,
            )
          : null,
      shadow: _showColumnShadow
          ? PolarColumnShadowStyle(
              color: _columnShadowColor,
              blurRadius: _columnShadowBlur,
              spreadRadius: _columnShadowSpread,
              offset: Offset(_columnShadowOffsetX, _columnShadowOffsetY),
              opacity: _columnShadowOpacity,
            )
          : const PolarColumnShadowStyle(),
      animationMode: _animationMode,
    );
    final selectionStyle = RadialSelectionStyle(
      effect: _selectionEffect,
      liftScale: _selectionScale,
      liftOffset: _selectionOffset,
      backdropBlur: _selectionBackdropBlur,
    );
    if (_presentation == _PolarPresentation.layered) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-capacity',
          name: 'Capacity',
          values: _comparisonValues,
          color: palette[1 % palette.length],
          unit: 'orders',
          polarStyle: style.copyWith(
            opacity: math.min(_opacity, 0.32),
            showDataLabels: false,
          ),
          selectionStyle: selectionStyle,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-observed',
          name: 'Observed',
          values: _values,
          color: palette.first,
          unit: 'orders',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
      ];
    }
    if (_presentation == _PolarPresentation.grouped) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-north',
          name: 'North',
          values: _values,
          color: palette[0],
          unit: 'orders',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-south',
          name: 'South',
          values: _comparisonValues,
          color: palette[1 % palette.length],
          unit: 'orders',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-west',
          name: 'West',
          values: _tertiaryValues,
          color: palette[2 % palette.length],
          unit: 'orders',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
      ];
    }
    if (_presentation == _PolarPresentation.stacked) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-new',
          name: 'New accounts',
          values: _values,
          color: palette[0],
          unit: 'accounts',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-expansion',
          name: 'Expansion',
          values: _comparisonValues,
          color: palette[1 % palette.length],
          unit: 'accounts',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-churn',
          name: 'Churn',
          values: _tertiaryValues,
          color: palette[2 % palette.length],
          unit: 'accounts',
          polarStyle: style,
          selectionStyle: selectionStyle,
        ),
      ];
    }
    if (_presentation == _PolarPresentation.references) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-actual-targets',
          name: 'Actual versus plan',
          values: _values,
          targets: _showTargets ? _comparisonValues : const <String, num>{},
          columnColors: colors,
          unit: 'orders',
          polarStyle: style,
          selectionStyle: selectionStyle,
          targetMarkerStyle: PolarColumnTargetMarkerStyle(
            color: _effectiveTargetColor,
            width: _targetMarkerWidth,
            lengthFactor: _targetMarkerLength,
            opacity: _targetOpacity,
          ),
        ),
      ];
    }
    if (_presentation == _PolarPresentation.intervals) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-forecast-intervals',
          name: 'Forecast',
          values: _values,
          intervals: _showIntervals
              ? {
                  for (final category in _values.keys)
                    if (_comparisonValues[category] case final lower?)
                      if (_tertiaryValues[category] case final upper?)
                        category: PolarColumnInterval(
                          lower: lower.toDouble(),
                          upper: upper.toDouble(),
                        ),
                }
              : const <String, PolarColumnInterval>{},
          columnColors: colors,
          unit: 'orders',
          polarStyle: style,
          selectionStyle: selectionStyle,
          intervalStyle: PolarColumnIntervalStyle(
            display: _intervalDisplay,
            color: _effectiveIntervalColor,
            width: _intervalWidth,
            capLengthFactor: _intervalCapLength,
            bandLengthFactor: _intervalBandLength,
            opacity: _intervalOpacity,
          ),
        ),
      ];
    }
    return [
      _presentation == _PolarPresentation.rose
          ? PolarColumnChartSeries.rose(
              id: 'showcase-polar-column',
              name: 'Monthly volume',
              values: _values,
              columnColors: colors,
              unit: 'requests',
              polarStyle: style,
              selectionStyle: selectionStyle,
            )
          : PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-column',
              name: 'Category volume',
              values: _values,
              columnColors: colors,
              unit: 'requests',
              polarStyle: style,
              selectionStyle: selectionStyle,
            ),
    ];
  }

  ChartTheme _buildChartTheme() {
    final base = _baseChartTheme;
    return base.copyWith(
      backgroundColor: _effectiveCanvasColor,
      gridStyle: base.gridStyle.copyWith(
        majorColor: _effectiveGridLineColor,
        majorWidth: _gridLineWidth,
        majorDashPattern: _gridLinePattern.pattern,
      ),
      axisStyle: base.axisStyle.copyWith(
        lineColor: _effectiveAxisLineColor,
        lineWidth: _axisLineWidth,
        tickColor: _effectiveAxisLineColor,
        labelStyle: base.axisStyle.labelStyle.copyWith(
          color: _effectiveAxisLabelColor,
          fontSize: _axisLabelSize,
        ),
      ),
      seriesTheme: base.seriesTheme.copyWith(colors: _categoryColors),
      interactionTheme: base.interactionTheme.copyWith(
        selectionColor: _effectiveSelectionColor.withValues(alpha: 0.3),
        tooltipStyle: base.interactionTheme.tooltipStyle.copyWith(
          textStyle: base.interactionTheme.tooltipStyle.textStyle.copyWith(
            color: _effectiveTooltipTextColor,
          ),
          backgroundColor: _effectiveTooltipBackgroundColor,
          borderColor: _effectiveTooltipBorderColor,
          borderWidth: _tooltipBorderWidth,
          borderRadius: _tooltipCornerRadius,
        ),
      ),
      focusBorderColor: _effectiveSelectionColor,
    );
  }

  ChartTheme get _baseChartTheme => _chartThemeForPreset(_themePreset);

  Color get _effectiveCanvasColor =>
      _canvasColor ?? _baseChartTheme.backgroundColor;
  Color get _effectiveAxisLineColor =>
      _axisLineColor ?? _baseChartTheme.axisStyle.lineColor;
  Color get _effectiveAxisLabelColor =>
      _axisLabelColor ??
      _baseChartTheme.axisStyle.labelStyle.color ??
      const Color(0xFF334155);
  Color get _effectiveGridLineColor =>
      _gridLineColor ?? _baseChartTheme.gridStyle.majorColor;
  Color get _effectiveColumnBorderColor =>
      _columnBorderColor ?? _baseChartTheme.axisStyle.lineColor;
  Color get _effectiveTargetColor => _targetColor ?? const Color(0xFFF59E0B);
  Color get _effectiveThresholdColor =>
      _thresholdColor ?? const Color(0xFFDC2626);
  Color get _effectiveIntervalColor =>
      _intervalColor ?? const Color(0xFF475569);
  Color get _effectiveTooltipBackgroundColor =>
      _tooltipBackgroundColor ??
      _baseChartTheme.interactionTheme.tooltipStyle.backgroundColor;
  Color get _effectiveTooltipTextColor =>
      _tooltipTextColor ??
      _baseChartTheme.interactionTheme.tooltipStyle.textStyle.color ??
      const Color(0xFF1E293B);
  Color get _effectiveTooltipBorderColor =>
      _tooltipBorderColor ??
      _baseChartTheme.interactionTheme.tooltipStyle.borderColor;
  Color get _effectiveSelectionColor =>
      _selectionColor ?? _baseChartTheme.focusBorderColor;

  ChartTheme _chartThemeForPreset(_PolarThemePreset preset) => switch (preset) {
    _PolarThemePreset.light => ChartTheme.light,
    _PolarThemePreset.dark => ChartTheme.dark,
    _PolarThemePreset.corporate => ChartTheme.corporateBlue,
    _PolarThemePreset.vibrant => ChartTheme.vibrant,
    _PolarThemePreset.minimal => ChartTheme.minimal,
    _PolarThemePreset.highContrast => ChartTheme.highContrast,
    _PolarThemePreset.colorblind => ChartTheme.colorblindFriendly,
  };

  List<Color> get _categoryColors => switch (_palette) {
    _PolarPalette.theme => List<Color>.generate(
      math.max(8, _values.length),
      _baseChartTheme.seriesTheme.colorAt,
    ),
    _PolarPalette.ocean => const [
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFF06B6D4),
      Color(0xFF7C3AED),
      Color(0xFF64748B),
    ],
    _PolarPalette.sunset => const [
      Color(0xFFE63946),
      Color(0xFFF77F00),
      Color(0xFFFCBF49),
      Color(0xFF9D4EDD),
      Color(0xFF5A189A),
    ],
    _PolarPalette.earth => const [
      Color(0xFF386641),
      Color(0xFF6A994E),
      Color(0xFFA7C957),
      Color(0xFFBC6C25),
      Color(0xFFDDA15E),
    ],
    _PolarPalette.monochrome => const [
      Color(0xFF1F2937),
      Color(0xFF374151),
      Color(0xFF4B5563),
      Color(0xFF6B7280),
      Color(0xFF9CA3AF),
    ],
  };

  void _applyThemePreset(_PolarThemePreset preset) {
    final base = _chartThemeForPreset(preset);
    setState(() {
      _themePreset = preset;
      _canvasColor = null;
      _axisLineColor = null;
      _axisLineWidth = base.axisStyle.lineWidth;
      _axisLabelColor = null;
      _axisLabelSize = base.axisStyle.labelStyle.fontSize ?? _axisLabelSize;
      _gridLineColor = null;
      _gridLineWidth = base.gridStyle.majorWidth;
      _gridLinePattern = base.gridStyle.majorDashPattern.isEmpty
          ? _PolarLinePattern.solid
          : _PolarLinePattern.dashed;
      _tooltipBackgroundColor = null;
      _tooltipTextColor = null;
      _tooltipBorderColor = null;
      _tooltipBorderWidth = base.interactionTheme.tooltipStyle.borderWidth;
      _tooltipCornerRadius = base.interactionTheme.tooltipStyle.borderRadius;
      _selectionColor = null;
    });
  }

  void _applyGeneratedRandomization(PolarShowcaseRandomization generated) {
    if (!mounted) return;
    _chartController.clearPointFocus();
    _chartController.clearPointSelection();
    setState(() {
      _randomizedShowcaseSelected = true;
      _presentation = _presentationFor(generated.presentation);
      _themePreset = _themePresetFor(generated.theme);
      _palette = _paletteFor(generated.palette);
      _values = Map<String, num>.of(generated.primaryValues);
      _comparisonValues = Map<String, num>.of(generated.secondaryValues);
      _tertiaryValues = Map<String, num>.of(generated.tertiaryValues);
      _categoryCount = generated.categoryCount;
      _startAngle = generated.startAngle;
      _sweepAngle = generated.sweepAngle;
      _clockwise = generated.clockwise;
      _innerRadius = generated.innerRadius;
      _outerRadius = generated.outerRadius;
      _innerPadding = generated.innerPadding;
      _outerPadding = generated.outerPadding;
      _compositionMode = generated.compositionMode;
      _groupInnerPadding = generated.groupInnerPadding;
      _scaleMode = generated.scaleMode;
      _tickCount = generated.tickCount;
      _showAngularLabels = generated.showAngularLabels;
      _showAngularGrid = generated.showAngularGrid;
      _maximumAngularLabels = generated.maximumAngularLabels;
      _maximumAngularGridLines = generated.maximumAngularGridLines;
      _showRadialLabels = generated.showRadialLabels;
      _showRadialGrid = generated.showRadialGrid;
      _showValues = generated.showValues;
      _maximumDataLabels = generated.maximumDataLabels;
      _categoryLabelOffset = generated.categoryLabelOffset;
      _categoryLabelColor = generated.categoryLabelColor;
      _categoryLabelSize = generated.categoryLabelSize;
      _categoryLabelWeight = generated.categoryLabelWeight;
      _valueLabelRadialPosition = generated.dataLabelRadialPosition;
      _valueLabelColor = generated.dataLabelColor;
      _valueLabelSize = generated.dataLabelSize;
      _valueLabelWeight = generated.dataLabelWeight;
      _radialLabelPosition = generated.radialLabelPosition;
      _radialLabelAngleOffset = generated.radialLabelAngleOffset;
      _radialLabelOffset = generated.radialLabelOffset;
      _radialLabelColor = generated.radialLabelColor;
      _radialLabelSize = generated.radialLabelSize;
      _radialLabelWeight = generated.radialLabelWeight;
      _cornerRadius = generated.cornerRadius;
      _cornerRadiusMode = generated.cornerRadiusMode;
      _opacity = generated.opacity;
      _showGradient = generated.showGradient;
      _gradientStartColor = generated.gradientStartColor;
      _gradientEndColor = generated.gradientEndColor;
      _gradientStartLightness = generated.gradientStartLightness;
      _gradientEndLightness = generated.gradientEndLightness;
      _showColumnShadow = generated.showColumnShadow;
      _columnShadowColor = generated.columnShadowColor;
      _columnShadowBlur = generated.columnShadowBlur;
      _columnShadowSpread = generated.columnShadowSpread;
      _columnShadowOffsetX = generated.columnShadowOffsetX;
      _columnShadowOffsetY = generated.columnShadowOffsetY;
      _columnShadowOpacity = generated.columnShadowOpacity;
      _animationMode = generated.animationMode;
      _showTargets = generated.showTargets;
      _showThreshold = generated.showThreshold;
      _thresholdValue = generated.thresholdValue;
      _targetMarkerWidth = generated.targetMarkerWidth;
      _targetMarkerLength = generated.targetMarkerLength;
      _targetOpacity = generated.targetOpacity;
      _showIntervals = generated.showIntervals;
      _intervalDisplay = generated.intervalDisplay;
      _intervalWidth = generated.intervalWidth;
      _intervalCapLength = generated.intervalCapLength;
      _intervalBandLength = generated.intervalBandLength;
      _intervalOpacity = generated.intervalOpacity;
      _canvasColor = generated.canvasColor;
      _axisLineColor = generated.axisLineColor;
      _axisLabelColor = generated.axisLabelColor;
      _axisLineWidth = generated.axisLineWidth;
      _axisLabelSize = generated.axisLabelSize;
      _gridLineColor = generated.gridLineColor;
      _gridLineWidth = generated.gridLineWidth;
      _gridLinePattern = _linePatternFor(generated.gridLinePattern);
      _columnBorderColor = generated.columnBorderColor;
      _columnBorderWidth = generated.columnBorderWidth;
      _targetColor = generated.targetColor;
      _thresholdColor = generated.thresholdColor;
      _thresholdWidth = generated.thresholdWidth;
      _thresholdPattern = _linePatternFor(generated.thresholdPattern);
      _intervalColor = generated.intervalColor;
      _showTooltip = generated.showTooltip;
      _tooltipTrigger = generated.tooltipTrigger;
      _tooltipPosition = generated.tooltipPosition;
      _tooltipOffset = generated.tooltipOffset;
      _tooltipBackgroundColor = generated.tooltipBackgroundColor;
      _tooltipTextColor = generated.tooltipTextColor;
      _tooltipBorderColor = generated.tooltipBorderColor;
      _tooltipBorderWidth = generated.tooltipBorderWidth;
      _tooltipCornerRadius = generated.tooltipCornerRadius;
      _selectionEffect = generated.selectionEffect;
      _selectionScale = generated.selectionScale;
      _selectionOffset = generated.selectionOffset;
      _selectionBackdropBlur = generated.selectionBackdropBlur;
      _selectionColor = generated.selectionColor;
      _selectedCategory = null;
      _selectedSeries = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chartController.replayRadialEntrance();
    });
  }

  _PolarPresentation _presentationFor(
    PolarShowcasePresentationKind presentation,
  ) => switch (presentation) {
    PolarShowcasePresentationKind.standard => _PolarPresentation.standard,
    PolarShowcasePresentationKind.rose => _PolarPresentation.rose,
    PolarShowcasePresentationKind.partial => _PolarPresentation.partial,
    PolarShowcasePresentationKind.layered => _PolarPresentation.layered,
    PolarShowcasePresentationKind.grouped => _PolarPresentation.grouped,
    PolarShowcasePresentationKind.stacked => _PolarPresentation.stacked,
    PolarShowcasePresentationKind.references => _PolarPresentation.references,
    PolarShowcasePresentationKind.intervals => _PolarPresentation.intervals,
  };

  _PolarThemePreset _themePresetFor(PolarShowcaseThemeKind theme) =>
      switch (theme) {
        PolarShowcaseThemeKind.light => _PolarThemePreset.light,
        PolarShowcaseThemeKind.dark => _PolarThemePreset.dark,
        PolarShowcaseThemeKind.corporate => _PolarThemePreset.corporate,
        PolarShowcaseThemeKind.vibrant => _PolarThemePreset.vibrant,
        PolarShowcaseThemeKind.minimal => _PolarThemePreset.minimal,
        PolarShowcaseThemeKind.highContrast => _PolarThemePreset.highContrast,
        PolarShowcaseThemeKind.colorblind => _PolarThemePreset.colorblind,
      };

  _PolarPalette _paletteFor(PolarShowcasePaletteKind palette) =>
      switch (palette) {
        PolarShowcasePaletteKind.theme => _PolarPalette.theme,
        PolarShowcasePaletteKind.ocean => _PolarPalette.ocean,
        PolarShowcasePaletteKind.sunset => _PolarPalette.sunset,
        PolarShowcasePaletteKind.earth => _PolarPalette.earth,
        PolarShowcasePaletteKind.monochrome => _PolarPalette.monochrome,
      };

  _PolarLinePattern _linePatternFor(PolarShowcaseLinePatternKind pattern) =>
      switch (pattern) {
        PolarShowcaseLinePatternKind.solid => _PolarLinePattern.solid,
        PolarShowcaseLinePatternKind.dashed => _PolarLinePattern.dashed,
        PolarShowcaseLinePatternKind.dotted => _PolarLinePattern.dotted,
      };

  String _fontWeightLabel(FontWeight weight) => switch (weight) {
    FontWeight.w400 => 'Regular',
    FontWeight.w500 => 'Medium',
    FontWeight.w600 => 'Semi-bold',
    FontWeight.w700 => 'Bold',
    _ => 'Weight ${weight.value}',
  };

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Chart appearance',
      icon: Icons.palette_outlined,
      children: [
        EnumOption<_PolarThemePreset>(
          label: 'Theme preset',
          value: _themePreset,
          values: _PolarThemePreset.values,
          labelBuilder: (value) => value.label,
          onChanged: _applyThemePreset,
        ),
        _PolarColorOption(
          label: 'Canvas color',
          value: _canvasColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _canvasColor = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Categories',
      icon: Icons.category_outlined,
      children: [
        IntSliderOption(
          label: 'Category count',
          value: _categoryCount,
          min: 3,
          max: 96,
          suffix: 'categories',
          onChanged: _setCategoryCount,
        ),
        EnumOption<_PolarPalette>(
          label: 'Category colors',
          value: _palette,
          values: _PolarPalette.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _palette = value),
        ),
        SliderOption(
          label: 'Column gap',
          value: _innerPadding,
          min: 0,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _innerPadding = value),
        ),
        SliderOption(
          label: 'Outer padding',
          value: _outerPadding,
          min: 0,
          max: 0.35,
          divisions: 14,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _outerPadding = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Category labels',
      icon: Icons.label_outline,
      children: [
        BoolOption(
          label: 'Show category labels',
          value: _showAngularLabels,
          onChanged: (value) => setState(() => _showAngularLabels = value),
        ),
        _PolarColorOption(
          label: 'Text color',
          value: _categoryLabelColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _categoryLabelColor = value),
        ),
        SliderOption(
          label: 'Text size',
          value: _categoryLabelSize,
          min: 8,
          max: 20,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _categoryLabelSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Text weight',
          value: _categoryLabelWeight,
          values: _labelWeights,
          labelBuilder: _fontWeightLabel,
          onChanged: (value) => setState(() => _categoryLabelWeight = value),
        ),
        SliderOption(
          label: 'Outer offset',
          value: _categoryLabelOffset,
          min: -12,
          max: 48,
          divisions: 30,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _categoryLabelOffset = value),
        ),
        if (_randomizedShowcaseSelected || _showAngularLabels)
          IntSliderOption(
            label: 'Maximum category labels',
            value: _maximumAngularLabels,
            min: 4,
            max: 48,
            suffix: 'labels',
            onChanged: (value) => setState(() => _maximumAngularLabels = value),
          ),
      ],
    ),
    OptionSection(
      title: 'Inside value labels',
      icon: Icons.pin_outlined,
      children: [
        BoolOption(
          label: 'Show values',
          value: _showValues,
          onChanged: (value) => setState(() => _showValues = value),
        ),
        _PolarColorOption(
          label: 'Text color (auto contrast)',
          value: _valueLabelColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _valueLabelColor = value),
        ),
        SliderOption(
          label: 'Text size',
          value: _valueLabelSize,
          min: 8,
          max: 20,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _valueLabelSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Text weight',
          value: _valueLabelWeight,
          values: _labelWeights,
          labelBuilder: _fontWeightLabel,
          onChanged: (value) => setState(() => _valueLabelWeight = value),
        ),
        SliderOption(
          label: 'Radial position',
          value: _valueLabelRadialPosition * 100,
          min: 10,
          max: 90,
          divisions: 16,
          suffix: '% through column',
          decimalPlaces: 0,
          onChanged: (value) =>
              setState(() => _valueLabelRadialPosition = value / 100),
        ),
        if (_randomizedShowcaseSelected || _showValues)
          IntSliderOption(
            label: 'Maximum value labels',
            value: _maximumDataLabels,
            min: 4,
            max: 48,
            suffix: 'labels',
            onChanged: (value) => setState(() => _maximumDataLabels = value),
          ),
      ],
    ),
    OptionSection(
      title: 'Radial axis labels',
      icon: Icons.track_changes_outlined,
      children: [
        BoolOption(
          label: 'Show radial labels',
          value: _showRadialLabels,
          onChanged: (value) => setState(() => _showRadialLabels = value),
        ),
        _PolarColorOption(
          label: 'Text color',
          value: _radialLabelColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _radialLabelColor = value),
        ),
        SliderOption(
          label: 'Text size',
          value: _radialLabelSize,
          min: 8,
          max: 20,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _radialLabelSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Text weight',
          value: _radialLabelWeight,
          values: _labelWeights,
          labelBuilder: _fontWeightLabel,
          onChanged: (value) => setState(() => _radialLabelWeight = value),
        ),
        EnumOption<PolarRadialLabelPosition>(
          label: 'Sweep anchor',
          value: _radialLabelPosition,
          values: PolarRadialLabelPosition.values,
          labelBuilder: (value) => switch (value) {
            PolarRadialLabelPosition.start => 'Start ray',
            PolarRadialLabelPosition.middle => 'Middle ray',
            PolarRadialLabelPosition.end => 'End ray',
          },
          onChanged: (value) => setState(() => _radialLabelPosition = value),
        ),
        SliderOption(
          label: 'Angular adjustment',
          value: _radialLabelAngleOffset,
          min: -45,
          max: 45,
          divisions: 18,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _radialLabelAngleOffset = value),
        ),
        SliderOption(
          label: 'Ray offset',
          value: _radialLabelOffset,
          min: -16,
          max: 24,
          divisions: 20,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _radialLabelOffset = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Grid & axes',
      icon: Icons.grid_4x4_outlined,
      children: [
        _PolarColorOption(
          label: 'Axis line color',
          value: _axisLineColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _axisLineColor = value),
        ),
        SliderOption(
          label: 'Axis line width',
          value: _axisLineWidth,
          min: 0,
          max: 4,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _axisLineWidth = value),
        ),
        BoolOption(
          label: 'Show angular grid',
          value: _showAngularGrid,
          onChanged: (value) => setState(() => _showAngularGrid = value),
        ),
        if (_randomizedShowcaseSelected || _showAngularGrid)
          IntSliderOption(
            label: 'Maximum grid spokes',
            value: _maximumAngularGridLines,
            min: 8,
            max: 96,
            suffix: 'spokes',
            onChanged: (value) =>
                setState(() => _maximumAngularGridLines = value),
          ),
        BoolOption(
          label: 'Show radial grid',
          value: _showRadialGrid,
          onChanged: (value) => setState(() => _showRadialGrid = value),
        ),
        _PolarColorOption(
          label: 'Grid line color',
          value: _gridLineColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _gridLineColor = value),
        ),
        SliderOption(
          label: 'Grid line width',
          value: _gridLineWidth,
          min: 0,
          max: 4,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _gridLineWidth = value),
        ),
        EnumOption<_PolarLinePattern>(
          key: const ValueKey('polar-grid-line-pattern'),
          label: 'Grid line pattern',
          value: _gridLinePattern,
          values: _PolarLinePattern.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _gridLinePattern = value),
        ),
      ],
    ),
    if (_randomizedShowcaseSelected ||
        _presentation == _PolarPresentation.layered ||
        _presentation == _PolarPresentation.grouped ||
        _presentation == _PolarPresentation.stacked)
      OptionSection(
        title: 'Series composition',
        icon: Icons.view_week_outlined,
        children: [
          EnumOption<PolarColumnCompositionMode>(
            label: 'Arrangement',
            value: _compositionMode,
            values: PolarColumnCompositionMode.values,
            labelBuilder: (value) => switch (value) {
              PolarColumnCompositionMode.layered => 'Layered',
              PolarColumnCompositionMode.grouped => 'Grouped',
              PolarColumnCompositionMode.stacked => 'Stacked',
            },
            onChanged: (value) => setState(() => _compositionMode = value),
          ),
          if (_randomizedShowcaseSelected ||
              _compositionMode == PolarColumnCompositionMode.grouped)
            SliderOption(
              label: 'Gap between series',
              value: _groupInnerPadding,
              min: 0,
              max: 0.5,
              divisions: 20,
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _groupInnerPadding = value),
            ),
        ],
      ),
    if (_randomizedShowcaseSelected ||
        _presentation == _PolarPresentation.references)
      OptionSection(
        title: 'Reference marks',
        icon: Icons.flag_outlined,
        children: [
          BoolOption(
            label: 'Show category targets',
            value: _showTargets,
            onChanged: (value) => setState(() => _showTargets = value),
          ),
          if (_randomizedShowcaseSelected || _showTargets) ...[
            _PolarColorOption(
              label: 'Target color',
              value: _targetColor,
              colors: _colorChoices,
              onChanged: (value) => setState(() => _targetColor = value),
            ),
            SliderOption(
              label: 'Target marker width',
              value: _targetMarkerWidth,
              min: 1,
              max: 6,
              divisions: 20,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _targetMarkerWidth = value),
            ),
            SliderOption(
              label: 'Target marker length',
              value: _targetMarkerLength * 100,
              min: 30,
              max: 100,
              divisions: 14,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _targetMarkerLength = value / 100),
            ),
            SliderOption(
              label: 'Target opacity',
              value: _targetOpacity * 100,
              min: 20,
              max: 100,
              divisions: 16,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _targetOpacity = value / 100),
            ),
          ],
          BoolOption(
            label: 'Show capacity threshold',
            value: _showThreshold,
            onChanged: (value) => setState(() => _showThreshold = value),
          ),
          if (_randomizedShowcaseSelected || _showThreshold) ...[
            _PolarColorOption(
              label: 'Threshold color',
              value: _thresholdColor,
              colors: _colorChoices,
              onChanged: (value) => setState(() => _thresholdColor = value),
            ),
            SliderOption(
              label: 'Capacity threshold',
              value: _thresholdValue,
              min: 40,
              max: 110,
              divisions: 28,
              suffix: 'orders',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _thresholdValue = value),
            ),
            SliderOption(
              label: 'Threshold width',
              value: _thresholdWidth,
              min: 0.5,
              max: 6,
              divisions: 22,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _thresholdWidth = value),
            ),
            EnumOption<_PolarLinePattern>(
              label: 'Threshold pattern',
              value: _thresholdPattern,
              values: _PolarLinePattern.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) => setState(() => _thresholdPattern = value),
            ),
          ],
        ],
      ),
    if (_randomizedShowcaseSelected ||
        _presentation == _PolarPresentation.intervals)
      OptionSection(
        title: 'Uncertainty & ranges',
        icon: Icons.vertical_align_center_outlined,
        children: [
          BoolOption(
            label: 'Show intervals',
            value: _showIntervals,
            onChanged: (value) => setState(() => _showIntervals = value),
          ),
          if (_randomizedShowcaseSelected || _showIntervals) ...[
            EnumOption<PolarColumnIntervalDisplay>(
              label: 'Presentation',
              value: _intervalDisplay,
              values: PolarColumnIntervalDisplay.values,
              labelBuilder: (value) => switch (value) {
                PolarColumnIntervalDisplay.whisker => 'Whisker + caps',
                PolarColumnIntervalDisplay.band => 'Annular range band',
              },
              onChanged: (value) => setState(() => _intervalDisplay = value),
            ),
            _PolarColorOption(
              label: 'Interval color',
              value: _intervalColor,
              colors: _colorChoices,
              onChanged: (value) => setState(() => _intervalColor = value),
            ),
            SliderOption(
              label: 'Line width',
              value: _intervalWidth,
              min: 1,
              max: 5,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _intervalWidth = value),
            ),
            if (_randomizedShowcaseSelected ||
                _intervalDisplay == PolarColumnIntervalDisplay.whisker)
              SliderOption(
                label: 'Cap length',
                value: _intervalCapLength * 100,
                min: 30,
                max: 100,
                divisions: 14,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _intervalCapLength = value / 100),
              )
            else
              SliderOption(
                label: 'Band width',
                value: _intervalBandLength * 100,
                min: 30,
                max: 100,
                divisions: 14,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _intervalBandLength = value / 100),
              ),
            SliderOption(
              label: 'Interval opacity',
              value: _intervalOpacity * 100,
              min: 20,
              max: 100,
              divisions: 16,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _intervalOpacity = value / 100),
            ),
          ],
        ],
      ),
    OptionSection(
      title: 'Selection',
      icon: Icons.touch_app_outlined,
      children: [
        EnumOption<RadialSelectionEffect>(
          label: 'Selected column effect',
          value: _selectionEffect,
          values: RadialSelectionEffect.values,
          labelBuilder: (value) => switch (value) {
            RadialSelectionEffect.explode => 'Move outward',
            RadialSelectionEffect.lift => 'Lift towards viewer',
          },
          onChanged: (value) => setState(() => _selectionEffect = value),
        ),
        _PolarColorOption(
          label: 'Selection accent',
          value: _selectionColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _selectionColor = value),
        ),
        if (_randomizedShowcaseSelected ||
            _selectionEffect == RadialSelectionEffect.lift) ...[
          SliderOption(
            label: 'Lift scale',
            value: _selectionScale * 100,
            min: 100,
            max: 125,
            divisions: 25,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _selectionScale = value / 100),
          ),
          SliderOption(
            label: 'Lift offset',
            value: _selectionOffset,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _selectionOffset = value),
          ),
          SliderOption(
            label: 'Backdrop blur',
            value: _selectionBackdropBlur,
            min: 0,
            max: 8,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) =>
                setState(() => _selectionBackdropBlur = value),
          ),
        ] else
          SliderOption(
            label: 'Selection offset',
            value: _selectionOffset,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _selectionOffset = value),
          ),
      ],
    ),
    OptionSection(
      title: 'Tooltips',
      icon: Icons.chat_bubble_outline,
      children: [
        BoolOption(
          label: 'Show tooltips',
          value: _showTooltip,
          onChanged: (value) => setState(() => _showTooltip = value),
        ),
        if (_randomizedShowcaseSelected || _showTooltip) ...[
          EnumOption<TooltipTriggerMode>(
            label: 'Trigger',
            value: _tooltipTrigger,
            values: TooltipTriggerMode.values,
            labelBuilder: (value) => switch (value) {
              TooltipTriggerMode.hover => 'Hover',
              TooltipTriggerMode.tap => 'Tap',
              TooltipTriggerMode.both => 'Hover + tap',
            },
            onChanged: (value) => setState(() => _tooltipTrigger = value),
          ),
          EnumOption<TooltipPosition>(
            label: 'Position',
            value: _tooltipPosition,
            values: TooltipPosition.values,
            labelBuilder: (value) => switch (value) {
              TooltipPosition.auto => 'Automatic',
              TooltipPosition.top => 'Above',
              TooltipPosition.bottom => 'Below',
              TooltipPosition.left => 'Left',
              TooltipPosition.right => 'Right',
            },
            onChanged: (value) => setState(() => _tooltipPosition = value),
          ),
          SliderOption(
            label: 'Point offset',
            value: _tooltipOffset,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _tooltipOffset = value),
          ),
          _PolarColorOption(
            label: 'Background color',
            value: _tooltipBackgroundColor,
            colors: _colorChoices,
            onChanged: (value) =>
                setState(() => _tooltipBackgroundColor = value),
          ),
          _PolarColorOption(
            label: 'Text color',
            value: _tooltipTextColor,
            colors: _colorChoices,
            onChanged: (value) => setState(() => _tooltipTextColor = value),
          ),
          _PolarColorOption(
            label: 'Border color',
            value: _tooltipBorderColor,
            colors: _colorChoices,
            onChanged: (value) => setState(() => _tooltipBorderColor = value),
          ),
          SliderOption(
            label: 'Border width',
            value: _tooltipBorderWidth,
            min: 0,
            max: 4,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _tooltipBorderWidth = value),
          ),
          SliderOption(
            label: 'Corner radius',
            value: _tooltipCornerRadius,
            min: 0,
            max: 18,
            divisions: 18,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _tooltipCornerRadius = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Polar geometry & scale',
      icon: Icons.radar_outlined,
      children: [
        SliderOption(
          label: 'Start angle',
          value: _startAngle,
          min: -180,
          max: 180,
          divisions: 36,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _startAngle = value),
        ),
        SliderOption(
          label: 'Sweep angle',
          value: _sweepAngle,
          min: 90,
          max: 360,
          divisions: 27,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _sweepAngle = value),
        ),
        BoolOption(
          label: 'Clockwise order',
          value: _clockwise,
          onChanged: (value) => setState(() => _clockwise = value),
        ),
        SliderOption(
          label: 'Inner radius',
          value: _innerRadius * 100,
          min: 0,
          max: 55,
          divisions: 11,
          suffix: '%',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _innerRadius = value / 100),
        ),
        SliderOption(
          label: 'Outer radius',
          value: _outerRadius * 100,
          min: 60,
          max: 94,
          divisions: 17,
          suffix: '%',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _outerRadius = value / 100),
        ),
        EnumOption<PolarRadialScaleMode>(
          label: 'Scale mode',
          value: _scaleMode,
          values: PolarRadialScaleMode.values,
          labelBuilder: (value) => switch (value) {
            PolarRadialScaleMode.linear => 'Linear radius',
            PolarRadialScaleMode.areaCorrect => 'Area-correct',
          },
          onChanged: (value) => setState(() => _scaleMode = value),
        ),
        IntSliderOption(
          label: 'Tick count',
          value: _tickCount,
          min: 2,
          max: 8,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Column fill & elevation',
      icon: Icons.gradient_outlined,
      children: [
        BoolOption(
          label: 'Gradient fill',
          value: _showGradient,
          onChanged: (value) => setState(() => _showGradient = value),
        ),
        if (_showGradient) ...[
          _PolarColorOption(
            label: 'Gradient start (derived)',
            value: _gradientStartColor,
            colors: _colorChoices,
            onChanged: (value) => setState(() => _gradientStartColor = value),
          ),
          _PolarColorOption(
            label: 'Gradient end (derived)',
            value: _gradientEndColor,
            colors: _colorChoices,
            onChanged: (value) => setState(() => _gradientEndColor = value),
          ),
          SliderOption(
            label: 'Derived start lightness',
            value: _gradientStartLightness * 100,
            min: -40,
            max: 40,
            divisions: 16,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _gradientStartLightness = value / 100),
          ),
          SliderOption(
            label: 'Derived end lightness',
            value: _gradientEndLightness * 100,
            min: -40,
            max: 40,
            divisions: 16,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _gradientEndLightness = value / 100),
          ),
        ],
        BoolOption(
          label: 'Column shadow',
          value: _showColumnShadow,
          onChanged: (value) => setState(() => _showColumnShadow = value),
        ),
        if (_showColumnShadow) ...[
          _PolarColorOption(
            label: 'Shadow color (derived)',
            value: _columnShadowColor,
            colors: _colorChoices,
            onChanged: (value) => setState(() => _columnShadowColor = value),
          ),
          SliderOption(
            label: 'Shadow blur',
            value: _columnShadowBlur,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _columnShadowBlur = value),
          ),
          SliderOption(
            label: 'Shadow spread',
            value: _columnShadowSpread,
            min: 0,
            max: 8,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _columnShadowSpread = value),
          ),
          SliderOption(
            label: 'Horizontal offset',
            value: _columnShadowOffsetX,
            min: -16,
            max: 16,
            divisions: 32,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _columnShadowOffsetX = value),
          ),
          SliderOption(
            label: 'Vertical offset',
            value: _columnShadowOffsetY,
            min: -16,
            max: 16,
            divisions: 32,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _columnShadowOffsetY = value),
          ),
          SliderOption(
            label: 'Shadow opacity',
            value: _columnShadowOpacity * 100,
            min: 0,
            max: 80,
            divisions: 16,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _columnShadowOpacity = value / 100),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Motion',
      icon: Icons.animation_outlined,
      children: [
        EnumOption<PolarColumnAnimationMode>(
          label: 'Entrance',
          value: _animationMode,
          values: PolarColumnAnimationMode.values,
          labelBuilder: (value) => switch (value) {
            PolarColumnAnimationMode.none => 'None',
            PolarColumnAnimationMode.grow => 'Grow from baseline',
            PolarColumnAnimationMode.fade => 'Fade in',
            PolarColumnAnimationMode.sweep => 'Sweep around pane',
          },
          onChanged: (value) {
            setState(() => _animationMode = value);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _chartController.replayRadialEntrance(),
            );
          },
        ),
        ActionButton(
          key: const ValueKey('polar-replay-entrance'),
          label: 'Replay entrance',
          icon: Icons.replay_outlined,
          onPressed: _chartController.replayRadialEntrance,
        ),
      ],
    ),
    OptionSection(
      title: 'Columns',
      icon: Icons.view_column_outlined,
      children: [
        EnumOption<PolarColumnCornerRadiusMode>(
          label: 'Corner placement',
          value: _cornerRadiusMode,
          values: PolarColumnCornerRadiusMode.values,
          labelBuilder: (value) => switch (value) {
            PolarColumnCornerRadiusMode.bothEnds => 'Both ends',
            PolarColumnCornerRadiusMode.outerEnd => 'Outer end',
            PolarColumnCornerRadiusMode.stackExterior => 'Stack exterior only',
          },
          onChanged: (value) => setState(() => _cornerRadiusMode = value),
        ),
        SliderOption(
          label: 'Corner radius',
          value: _cornerRadius,
          min: 0,
          max: 18,
          divisions: 18,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _cornerRadius = value),
        ),
        SliderOption(
          label: 'Opacity',
          value: _opacity * 100,
          min: 35,
          max: 100,
          divisions: 13,
          suffix: '%',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _opacity = value / 100),
        ),
        _PolarColorOption(
          label: 'Column border color',
          value: _columnBorderColor,
          colors: _colorChoices,
          onChanged: (value) => setState(() => _columnBorderColor = value),
        ),
        SliderOption(
          label: 'Column border width',
          value: _columnBorderWidth,
          min: 0,
          max: 4,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _columnBorderWidth = value),
        ),
      ],
    ),
  ];

  Widget _buildFeatureGuide() {
    final items = const [
      (
        Icons.rotate_right_outlined,
        'Category owns angle',
        'Every category receives a stable angular band. Value never changes its width.',
      ),
      (
        Icons.straighten_outlined,
        'Value owns radius',
        'A numeric radial scale makes magnitudes comparable instead of converting them into shares.',
      ),
      (
        Icons.nightlight_round,
        'Rose is area-correct',
        'The Nightingale preset maps values to annular-sector area by default.',
      ),
      (
        Icons.layers_outlined,
        'Layers share one scale',
        'Compatible series can compare observed and reference values in the same category bands.',
      ),
      (
        Icons.view_week_outlined,
        'Groups divide the band',
        'Each series receives a stable angular sub-band while the category and radial scale stay shared.',
      ),
      (
        Icons.stacked_bar_chart_outlined,
        'Stacks diverge from zero',
        'Positive and negative contributors accumulate independently without cancelling each other.',
      ),
      (
        Icons.flag_outlined,
        'Targets stay category-bound',
        'Per-category target ticks keep their identity through selection, transport, tables, and source generation.',
      ),
      (
        Icons.radar_outlined,
        'Thresholds span the pane',
        'A threshold ring communicates one absolute reference value across every angular category.',
      ),
      (
        Icons.vertical_align_center_outlined,
        'Intervals stay scale-bound',
        'Absolute lower and upper values render as radial whiskers or compact annular range bands.',
      ),
    ];
    return _Section(
      eyebrow: 'FEATURE GUIDE',
      title: 'An axis-based radial chart—not a Pie chart',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 720
              ? 1
              : constraints.maxWidth < 900
              ? 2
              : 3;
          const gap = 12.0;
          final cardWidth =
              (constraints.maxWidth - (columns - 1) * gap) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (index, item) in items.indexed)
                SizedBox(
                  key: ValueKey('polar-feature-card-$index'),
                  width: cardWidth,
                  child: _FeatureCard(
                    icon: item.$1,
                    title: item.$2,
                    body: item.$3,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCodeRecipe() => const _Section(
    eyebrow: 'HOW TO USE IT',
    title: 'Attach targets, thresholds, and absolute uncertainty intervals',
    child: _CodeBlock(
      code: '''final volume = PolarColumnChartSeries.fromMap(
  id: 'volume',
  values: const {'Search': 74, 'Social': 56, 'Partners': 83},
  targets: const {'Search': 78, 'Social': 62, 'Partners': 80},
  intervals: const {
    'Search': PolarColumnInterval(lower: 66, upper: 84),
    'Social': PolarColumnInterval(lower: 48, upper: 67),
  },
  unit: 'orders',
  targetMarkerStyle: const PolarColumnTargetMarkerStyle(
    color: Color(0xFFF59E0B),
    width: 3,
    lengthFactor: 0.68,
  ),
  intervalStyle: const PolarColumnIntervalStyle(
    display: PolarColumnIntervalDisplay.whisker,
    width: 2,
  ),
  polarStyle: const PolarColumnStyle(
    dataLabelRadialPosition: 0.65,
    gradient: PolarColumnGradientStyle(),
    shadow: PolarColumnShadowStyle(
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    animationMode: PolarColumnAnimationMode.sweep,
  ),
);

BravenChartPlus(
  series: [volume],
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(startAngleDegrees: -90),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: 0.12,
      labelOffset: 8,
      labelStyle: PolarLabelStyle(fontSize: 12),
    ),
    radialAxis: PolarNumericAxisConfig(
      tickCount: 5,
      labelPosition: PolarRadialLabelPosition.end,
      labelOffset: 6,
    ),
    thresholds: [
      PolarThreshold(
        value: 80,
        label: 'Capacity',
        color: Color(0xFFDC2626),
      ),
    ],
  ),
);''',
    ),
  );

  void _applyPresentation(
    _PolarPresentation presentation, {
    bool authoredSelection = true,
  }) {
    if (authoredSelection) {
      _showcaseRandomizer.pause();
      _showcaseRandomizer.clear();
    }
    setState(() {
      if (authoredSelection) {
        _randomizedShowcaseSelected = false;
        _authoredPresentation = presentation;
      }
      _presentation = presentation;
      _selectedCategory = null;
      _selectedSeries = null;
      _comparisonValues = const {};
      _tertiaryValues = const {};
      _cornerRadiusMode = presentation == _PolarPresentation.stacked
          ? PolarColumnCornerRadiusMode.stackExterior
          : PolarColumnCornerRadiusMode.outerEnd;
      switch (presentation) {
        case _PolarPresentation.standard:
          _values = Map<String, num>.of(_standardValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0;
          _outerRadius = 0.84;
          _innerPadding = 0.12;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 4;
          _compositionMode = PolarColumnCompositionMode.layered;
          _groupInnerPadding = 0.12;
        case _PolarPresentation.rose:
          _values = Map<String, num>.of(_roseValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.08;
          _outerRadius = 0.86;
          _innerPadding = 0.08;
          _outerPadding = 0;
          _scaleMode = PolarRadialScaleMode.areaCorrect;
          _cornerRadius = 6;
          _compositionMode = PolarColumnCompositionMode.layered;
          _groupInnerPadding = 0.12;
        case _PolarPresentation.partial:
          _values = Map<String, num>.of(_partialValues);
          _categoryCount = _values.length;
          _startAngle = 150;
          _sweepAngle = 240;
          _clockwise = true;
          _innerRadius = 0.28;
          _outerRadius = 0.9;
          _innerPadding = 0.14;
          _outerPadding = 0.08;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 8;
          _compositionMode = PolarColumnCompositionMode.layered;
          _groupInnerPadding = 0.12;
        case _PolarPresentation.layered:
          _values = Map<String, num>.of(_layeredObservedValues);
          _comparisonValues = Map<String, num>.of(_layeredCapacityValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.12;
          _outerRadius = 0.86;
          _innerPadding = 0.16;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 5;
          _compositionMode = PolarColumnCompositionMode.layered;
          _groupInnerPadding = 0.12;
        case _PolarPresentation.grouped:
          _values = Map<String, num>.of(_groupedNorthValues);
          _comparisonValues = Map<String, num>.of(_groupedSouthValues);
          _tertiaryValues = Map<String, num>.of(_groupedWestValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.1;
          _outerRadius = 0.88;
          _innerPadding = 0.12;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 4;
          _compositionMode = PolarColumnCompositionMode.grouped;
          _groupInnerPadding = 0.12;
        case _PolarPresentation.stacked:
          _values = Map<String, num>.of(_stackedNewValues);
          _comparisonValues = Map<String, num>.of(_stackedExpansionValues);
          _tertiaryValues = Map<String, num>.of(_stackedChurnValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.14;
          _outerRadius = 0.9;
          _innerPadding = 0.12;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 4;
          _compositionMode = PolarColumnCompositionMode.stacked;
          _groupInnerPadding = 0.12;
        case _PolarPresentation.references:
          _values = Map<String, num>.of(_referenceActualValues);
          _comparisonValues = Map<String, num>.of(_referenceTargetValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.12;
          _outerRadius = 0.88;
          _innerPadding = 0.14;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 5;
          _compositionMode = PolarColumnCompositionMode.layered;
          _groupInnerPadding = 0.12;
          _showTargets = true;
          _showThreshold = true;
          _thresholdValue = 80;
          _targetMarkerWidth = 3;
          _targetMarkerLength = 0.68;
        case _PolarPresentation.intervals:
          _values = Map<String, num>.of(_uncertaintyValues);
          _comparisonValues = Map<String, num>.of(_uncertaintyLowerValues);
          _tertiaryValues = Map<String, num>.of(_uncertaintyUpperValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.12;
          _outerRadius = 0.88;
          _innerPadding = 0.16;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 5;
          _compositionMode = PolarColumnCompositionMode.layered;
          _groupInnerPadding = 0.12;
          _showIntervals = true;
          _intervalDisplay = PolarColumnIntervalDisplay.whisker;
          _intervalWidth = 2;
          _intervalCapLength = 0.62;
          _intervalBandLength = 0.58;
      }
    });
  }

  void _setPlaygroundActive(bool active) {
    if (active == _randomizedShowcaseSelected) return;
    if (active) {
      _authoredPresentation = _presentation;
      setState(() => _randomizedShowcaseSelected = true);
      _showcaseRandomizer.generateCurrent();
      return;
    }
    _showcaseRandomizer.pause();
    _showcaseRandomizer.clear();
    _applyPresentation(_authoredPresentation);
  }

  List<Widget> _buildPlaygroundOptions() => _buildOptions();

  void _setCategoryCount(int count) {
    setState(() {
      _categoryCount = count;
      _selectedCategory = null;
      _selectedSeries = null;
      if (_presentation == _PolarPresentation.layered) {
        final generated = _randomLayeredValues(count);
        _values = generated.$1;
        _comparisonValues = generated.$2;
      } else if (_presentation == _PolarPresentation.grouped) {
        final generated = _randomGroupedValues(count);
        _values = generated.$1;
        _comparisonValues = generated.$2;
        _tertiaryValues = generated.$3;
      } else if (_presentation == _PolarPresentation.stacked) {
        final generated = _randomStackedValues(count);
        _values = generated.$1;
        _comparisonValues = generated.$2;
        _tertiaryValues = generated.$3;
      } else if (_presentation == _PolarPresentation.references) {
        final generated = _randomReferenceValues(count);
        _values = generated.$1;
        _comparisonValues = generated.$2;
      } else if (_presentation == _PolarPresentation.intervals) {
        final generated = _randomIntervalValues(count);
        _values = generated.$1;
        _comparisonValues = generated.$2;
        _tertiaryValues = generated.$3;
      } else {
        _values = _randomValues(count);
      }
    });
  }

  void _regenerateValues() {
    setState(() {
      _selectedCategory = null;
      _selectedSeries = null;
      if (_presentation == _PolarPresentation.layered) {
        final generated = _randomLayeredValues(_categoryCount);
        _values = generated.$1;
        _comparisonValues = generated.$2;
      } else if (_presentation == _PolarPresentation.grouped) {
        final generated = _randomGroupedValues(_categoryCount);
        _values = generated.$1;
        _comparisonValues = generated.$2;
        _tertiaryValues = generated.$3;
      } else if (_presentation == _PolarPresentation.stacked) {
        final generated = _randomStackedValues(_categoryCount);
        _values = generated.$1;
        _comparisonValues = generated.$2;
        _tertiaryValues = generated.$3;
      } else if (_presentation == _PolarPresentation.references) {
        final generated = _randomReferenceValues(_categoryCount);
        _values = generated.$1;
        _comparisonValues = generated.$2;
      } else if (_presentation == _PolarPresentation.intervals) {
        final generated = _randomIntervalValues(_categoryCount);
        _values = generated.$1;
        _comparisonValues = generated.$2;
        _tertiaryValues = generated.$3;
      } else {
        _values = _randomValues(_categoryCount);
      }
    });
  }

  Map<String, num> _randomValues(int count) => {
    for (var index = 0; index < count; index++)
      'Category ${index + 1}': 24 + _random.nextInt(77),
  };

  (Map<String, num>, Map<String, num>) _randomLayeredValues(int count) {
    final observed = _randomValues(count);
    return (
      observed,
      {
        for (final entry in observed.entries)
          entry.key: entry.value + 8 + _random.nextInt(17),
      },
    );
  }

  (Map<String, num>, Map<String, num>, Map<String, num>) _randomGroupedValues(
    int count,
  ) => (_randomValues(count), _randomValues(count), _randomValues(count));

  (Map<String, num>, Map<String, num>, Map<String, num>) _randomStackedValues(
    int count,
  ) => (
    {
      for (var index = 0; index < count; index++)
        'Channel ${index + 1}': 20 + _random.nextInt(26),
    },
    {
      for (var index = 0; index < count; index++)
        'Channel ${index + 1}': 8 + _random.nextInt(15),
    },
    {
      for (var index = 0; index < count; index++)
        'Channel ${index + 1}': -(8 + _random.nextInt(18)),
    },
  );

  (Map<String, num>, Map<String, num>) _randomReferenceValues(int count) {
    final actual = _randomValues(count);
    return (
      actual,
      {
        for (final entry in actual.entries)
          entry.key: math.max(20, entry.value + _random.nextInt(19) - 9),
      },
    );
  }

  (Map<String, num>, Map<String, num>, Map<String, num>) _randomIntervalValues(
    int count,
  ) {
    final values = _randomValues(count);
    return (
      values,
      {
        for (final entry in values.entries)
          entry.key: math.max(0, entry.value - (7 + _random.nextInt(8))),
      },
      {
        for (final entry in values.entries)
          entry.key: entry.value + 7 + _random.nextInt(10),
      },
    );
  }
}

enum _PolarThemePreset {
  light('Light'),
  dark('Dark'),
  corporate('Corporate blue'),
  vibrant('Vibrant'),
  minimal('Minimal'),
  highContrast('High contrast'),
  colorblind('Colorblind friendly');

  const _PolarThemePreset(this.label);

  final String label;
}

enum _PolarPalette {
  theme('Theme colors'),
  ocean('Ocean'),
  sunset('Sunset'),
  earth('Earth'),
  monochrome('Monochrome');

  const _PolarPalette(this.label);

  final String label;
}

enum _PolarLinePattern {
  solid('Solid', <double>[]),
  dashed('Dashed', <double>[7, 4]),
  dotted('Dotted', <double>[2, 3]);

  const _PolarLinePattern(this.label, this.pattern);

  final String label;
  final List<double> pattern;
}

enum _PolarPresentation {
  standard(
    'Standard columns',
    'Linear radius for direct category comparison',
    Icons.view_column_outlined,
    'Channel volume',
    'Equal angular bands compare one numeric measure across categories',
  ),
  rose(
    'Nightingale rose',
    'Area-correct sectors for cyclical profiles',
    Icons.nightlight_round,
    'Monthly request profile',
    'Equal angles with area-correct radial scaling across a complete cycle',
  ),
  partial(
    'Partial sweep',
    'A controlled angular span with an open center',
    Icons.speed_outlined,
    'Lifecycle conversion',
    'A 240° pane demonstrates start angle, sweep, and annular baselines',
  ),
  layered(
    'Layered comparison',
    'Observed values over a compatible reference layer',
    Icons.layers_outlined,
    'Observed demand against capacity',
    'Two compatible series share category bands and one numeric radial scale',
  ),
  grouped(
    'Grouped comparison',
    'Series sit side by side inside every category band',
    Icons.view_week_outlined,
    'Regional orders by channel',
    'Three regions divide each category band and share one numeric radial scale',
  ),
  stacked(
    'Stacked comparison',
    'Signed contributors accumulate independently from zero',
    Icons.stacked_bar_chart_outlined,
    'Net account movement by channel',
    'Growth stacks outward while churn accumulates inward from zero',
  ),
  references(
    'Targets & thresholds',
    'Category targets plus one pane-wide reference ring',
    Icons.flag_outlined,
    'Order volume against plan',
    'Amber ticks mark category targets; the dashed ring marks shared capacity',
  ),
  intervals(
    'Ranges & uncertainty',
    'Absolute lower and upper values on the shared radial scale',
    Icons.vertical_align_center_outlined,
    'Forecast range by channel',
    'Whiskers and annular bands show uncertainty without changing column values',
  );

  const _PolarPresentation(
    this.label,
    this.description,
    this.icon,
    this.chartTitle,
    this.chartSubtitle,
  );

  final String label;
  final String description;
  final IconData icon;
  final String chartTitle;
  final String chartSubtitle;
}

class _PresentationCard extends StatelessWidget {
  const _PresentationCard({
    required this.presentation,
    required this.selected,
    required this.onPressed,
  });

  final _PolarPresentation presentation;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ShowcaseExampleCard(
      key: ValueKey('polar-presentation-${presentation.name}'),
      title: presentation.label,
      description: presentation.description,
      icon: presentation.icon,
      selected: selected,
      onTap: onPressed,
      semanticsLabel: 'Apply ${presentation.label} Polar Column example',
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _SeriesKey extends StatelessWidget {
  const _SeriesKey({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _PolarColorOption extends StatelessWidget {
  const _PolarColorOption({
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final Color? value;
  final List<Color> colors;
  final ValueChanged<Color?> onChanged;

  @override
  Widget build(BuildContext context) {
    final keyName = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 8),
        ChartColorPalette(
          value: value,
          keyPrefix: 'polar-$keyName',
          customColorFallback: value ?? colors.first,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 29),
            child: Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
