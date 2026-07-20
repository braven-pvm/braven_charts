// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/options_panel.dart';
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
  PolarColumnCompositionMode _compositionMode =
      PolarColumnCompositionMode.layered;
  double _groupInnerPadding = 0.12;
  PolarRadialScaleMode _scaleMode = PolarRadialScaleMode.linear;
  int _tickCount = 5;
  bool _showAngularLabels = true;
  bool _showAngularGrid = true;
  bool _showRadialLabels = true;
  bool _showRadialGrid = true;
  bool _showValues = true;
  double _cornerRadius = 4;
  double _opacity = 0.94;
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
  String? _selectedCategory;
  String? _selectedSeries;

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

  static const _columnColors = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFE11D48),
    Color(0xFF9333EA),
    Color(0xFF4F46E5),
    Color(0xFF0284C7),
    Color(0xFF059669),
    Color(0xFFCA8A04),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF475569),
    Color(0xFFDB2777),
  ];

  @override
  void initState() {
    super.initState();
    _values = Map<String, num>.of(_standardValues);
    _comparisonValues = const {};
    _tertiaryValues = const {};
  }

  @override
  void dispose() {
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
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('polar-column-regenerate'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _regenerateValues,
          icon: const Icon(Icons.casino_outlined, size: 18),
          label: const Text('Regenerate values'),
        ),
      ],
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
              _buildPresentationSelector(constraints.maxWidth),
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

  Widget _buildPresentationSelector(double availableWidth) {
    final columns = availableWidth < 720
        ? 1
        : availableWidth < 900
        ? 2
        : 4;
    final cardWidth = (availableWidth - (columns - 1) * 8) / columns;
    return Semantics(
      container: true,
      label: 'Choose a Polar Column presentation',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final presentation in _PolarPresentation.values)
            SizedBox(
              width: cardWidth,
              child: _PresentationCard(
                presentation: presentation,
                selected: presentation == _presentation,
                onPressed: () => _applyPresentation(presentation),
              ),
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
    final isDark = theme.brightness == Brightness.dark;
    final chartTheme = isDark ? ChartTheme.dark : ChartTheme.light;
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
                        _presentation.chartTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _presentation.chartSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _MetricChip(label: '${_values.length} categories'),
                const SizedBox(width: 8),
                _MetricChip(
                  label: _scaleMode == PolarRadialScaleMode.areaCorrect
                      ? 'Area-correct'
                      : 'Linear radius',
                ),
                if (chartSeries.length > 1) ...[
                  const SizedBox(width: 8),
                  _MetricChip(
                    label:
                        '${chartSeries.length} ${switch (_compositionMode) {
                          PolarColumnCompositionMode.layered => 'layered',
                          PolarColumnCompositionMode.grouped => 'grouped',
                          PolarColumnCompositionMode.stacked => 'stacked',
                        }} series',
                  ),
                ],
                if (_presentation == _PolarPresentation.references) ...[
                  const SizedBox(width: 8),
                  const _MetricChip(label: 'Targets + threshold'),
                ],
                if (_presentation == _PolarPresentation.intervals) ...[
                  const SizedBox(width: 8),
                  _MetricChip(
                    label:
                        _intervalDisplay == PolarColumnIntervalDisplay.whisker
                        ? 'Uncertainty whiskers'
                        : 'Range bands',
                  ),
                ],
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
                  interactionConfig: const InteractionConfig(
                    tooltip: TooltipConfig(enabled: true),
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
    ),
    radialAxis: PolarNumericAxisConfig(
      scaleMode: _scaleMode,
      tickCount: _tickCount,
      showLabels: _showRadialLabels,
      showGridLines: _showRadialGrid,
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
              color: const Color(0xFFDC2626),
              width: 2,
              dashPattern: const <double>[7, 4],
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
    final colors = <String, Color>{};
    for (final (index, category) in _values.keys.indexed) {
      colors[category] = _columnColors[index % _columnColors.length];
    }
    final style = PolarColumnStyle(
      cornerRadius: _cornerRadius,
      opacity: _opacity,
      borderColor: const Color(0xFF334155),
      borderWidth: 0.75,
      showDataLabels: _showValues,
    );
    if (_presentation == _PolarPresentation.layered) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-capacity',
          name: 'Capacity',
          values: _comparisonValues,
          color: const Color(0xFF94A3B8),
          unit: 'orders',
          polarStyle: PolarColumnStyle(
            cornerRadius: _cornerRadius,
            opacity: math.min(_opacity, 0.32),
            borderColor: const Color(0xFF64748B),
            borderWidth: 0.75,
            showDataLabels: false,
          ),
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-observed',
          name: 'Observed',
          values: _values,
          color: const Color(0xFF2563EB),
          unit: 'orders',
          polarStyle: style,
        ),
      ];
    }
    if (_presentation == _PolarPresentation.grouped) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-north',
          name: 'North',
          values: _values,
          color: const Color(0xFF2563EB),
          unit: 'orders',
          polarStyle: style,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-south',
          name: 'South',
          values: _comparisonValues,
          color: const Color(0xFF0D9488),
          unit: 'orders',
          polarStyle: style,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-west',
          name: 'West',
          values: _tertiaryValues,
          color: const Color(0xFFF59E0B),
          unit: 'orders',
          polarStyle: style,
        ),
      ];
    }
    if (_presentation == _PolarPresentation.stacked) {
      return [
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-new',
          name: 'New accounts',
          values: _values,
          color: const Color(0xFF2563EB),
          unit: 'accounts',
          polarStyle: style,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-expansion',
          name: 'Expansion',
          values: _comparisonValues,
          color: const Color(0xFF0D9488),
          unit: 'accounts',
          polarStyle: style,
        ),
        PolarColumnChartSeries.fromMap(
          id: 'showcase-polar-churn',
          name: 'Churn',
          values: _tertiaryValues,
          color: const Color(0xFFE11D48),
          unit: 'accounts',
          polarStyle: style,
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
          targetMarkerStyle: PolarColumnTargetMarkerStyle(
            color: const Color(0xFFF59E0B),
            width: _targetMarkerWidth,
            lengthFactor: _targetMarkerLength,
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
          intervalStyle: PolarColumnIntervalStyle(
            display: _intervalDisplay,
            width: _intervalWidth,
            capLengthFactor: _intervalCapLength,
            bandLengthFactor: _intervalBandLength,
            opacity: 0.92,
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
            )
          : PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-column',
              name: 'Category volume',
              values: _values,
              columnColors: colors,
              unit: 'requests',
              polarStyle: style,
            ),
    ];
  }

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Data',
      icon: Icons.data_array_outlined,
      children: [
        IntSliderOption(
          label: 'Category count',
          value: _categoryCount,
          min: 3,
          max: 16,
          suffix: 'categories',
          onChanged: _setCategoryCount,
        ),
      ],
    ),
    if (_presentation == _PolarPresentation.layered ||
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
          if (_compositionMode == PolarColumnCompositionMode.grouped)
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
    if (_presentation == _PolarPresentation.references)
      OptionSection(
        title: 'Reference marks',
        icon: Icons.flag_outlined,
        children: [
          BoolOption(
            label: 'Show category targets',
            value: _showTargets,
            onChanged: (value) => setState(() => _showTargets = value),
          ),
          if (_showTargets) ...[
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
          ],
          BoolOption(
            label: 'Show capacity threshold',
            value: _showThreshold,
            onChanged: (value) => setState(() => _showThreshold = value),
          ),
          if (_showThreshold)
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
        ],
      ),
    if (_presentation == _PolarPresentation.intervals)
      OptionSection(
        title: 'Uncertainty & ranges',
        icon: Icons.vertical_align_center_outlined,
        children: [
          BoolOption(
            label: 'Show intervals',
            value: _showIntervals,
            onChanged: (value) => setState(() => _showIntervals = value),
          ),
          if (_showIntervals) ...[
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
            if (_intervalDisplay == PolarColumnIntervalDisplay.whisker)
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
          ],
        ],
      ),
    OptionSection(
      title: 'Polar pane',
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
      ],
    ),
    OptionSection(
      title: 'Angular categories',
      icon: Icons.rotate_right_outlined,
      children: [
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
        BoolOption(
          label: 'Show category labels',
          value: _showAngularLabels,
          onChanged: (value) => setState(() => _showAngularLabels = value),
        ),
        BoolOption(
          label: 'Show angular grid',
          value: _showAngularGrid,
          onChanged: (value) => setState(() => _showAngularGrid = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Radial values',
      icon: Icons.straighten_outlined,
      children: [
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
        BoolOption(
          label: 'Show radial labels',
          value: _showRadialLabels,
          onChanged: (value) => setState(() => _showRadialLabels = value),
        ),
        BoolOption(
          label: 'Show radial grid',
          value: _showRadialGrid,
          onChanged: (value) => setState(() => _showRadialGrid = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Columns',
      icon: Icons.view_column_outlined,
      children: [
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
        BoolOption(
          label: 'Show values inside columns',
          value: _showValues,
          onChanged: (value) => setState(() => _showValues = value),
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
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1
                ? 3.8
                : columns == 2
                ? 2.25
                : 1.55,
            children: [
              for (final item in items)
                _FeatureCard(icon: item.$1, title: item.$2, body: item.$3),
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
);

BravenChartPlus(
  series: [volume],
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(startAngleDegrees: -90),
    angularAxis: PolarCategoryAxisConfig(innerPadding: 0.12),
    radialAxis: PolarNumericAxisConfig(tickCount: 5),
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

  void _applyPresentation(_PolarPresentation presentation) {
    setState(() {
      _presentation = presentation;
      _selectedCategory = null;
      _selectedSeries = null;
      _comparisonValues = const {};
      _tertiaryValues = const {};
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.secondaryContainer
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('polar-presentation-${presentation.name}'),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  presentation.icon,
                  size: 22,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 18, color: scheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
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
