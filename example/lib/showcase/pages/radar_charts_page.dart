// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/persistent_resizable_chart_panel.dart';
import '../widgets/standard_options.dart';

enum _RadarPresentation {
  budget('Budget vs spending', Icons.account_balance_wallet_outlined),
  capability('Capability profile', Icons.hub_outlined),
  service('Service health', Icons.monitor_heart_outlined);

  const _RadarPresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}

class RadarChartsPage extends StatefulWidget {
  const RadarChartsPage({super.key});

  @override
  State<RadarChartsPage> createState() => _RadarChartsPageState();
}

class _RadarChartsPageState extends State<RadarChartsPage> {
  late final BravenChartController _chartController;
  late final ChartWorkbenchController _workbenchController;
  _RadarPresentation _presentation = _RadarPresentation.budget;
  RadarGridShape _gridShape = RadarGridShape.polygon;
  double _startAngleDegrees = -90;
  int _tickCount = 5;
  double _fillOpacity = 0.12;
  bool _showMarkers = true;
  bool _showDataLabels = false;
  bool _showCategoryLabels = true;
  bool _showRadialLabels = true;
  RadarAnimationMode _animationMode = RadarAnimationMode.radial;
  bool _previewReducedMotion = false;
  int _valueRevision = 0;

  @override
  void initState() {
    super.initState();
    _chartController = BravenChartController()..addListener(_handleChartState);
    _workbenchController = ChartWorkbenchController();
  }

  @override
  void dispose() {
    _chartController
      ..removeListener(_handleChartState)
      ..dispose();
    _workbenchController.dispose();
    super.dispose();
  }

  void _handleChartState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Radar and Spider Charts',
      subtitle:
          'Compare several quantitative dimensions on one shared category web',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('radar-update-values'),
          onPressed: _updateValues,
          icon: const Icon(Icons.auto_graph_outlined, size: 18),
          label: const Text('Update values'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('radar-replay-entrance'),
          onPressed: _chartController.replaySeriesEntrance,
          icon: const Icon(Icons.play_arrow_outlined, size: 18),
          label: const Text('Replay entrance'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('radar-reset-example'),
          onPressed: _resetExample,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return PersistentResizableChartPanelWorkspace(
          preferenceKey: showcaseChartPanelHeightKey(compact: compact),
          minimumPanelHeight: compact ? 500 : 360,
          maximumPanelHeight: compact ? 1200 : 960,
          initialPanelHeight: compact ? 680 : 560,
          scrollViewKey: const ValueKey('radar-showcase-scroll'),
          leading: [_buildPresentationSelector(), const SizedBox(height: 16)],
          panel: _buildChartCard(),
        );
      },
    );
  }

  Widget _buildPresentationSelector() {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Choose a Radar chart example',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Radar chart example',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('radar-presentation-selector'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final presentation in _RadarPresentation.values)
                    ShowcaseExampleChoiceChip(
                      key: ValueKey('radar-presentation-${presentation.name}'),
                      label: presentation.label,
                      icon: presentation.icon,
                      selected: _presentation == presentation,
                      onSelected: () => _applyPresentation(presentation),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _presentationDescription,
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

  Widget _buildChartCard() {
    final series = _buildSeries();
    final theme = Theme.of(context);
    final subtitle =
        '${series.first.categories.length} categories · '
        '${series.length} profiles · ${_gridShape.name} web · '
        'shared 0–100 scale · update $_valueRevision';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _chartTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildInteractionStatus(series),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartWorkbench(
                key: const ValueKey('radar-workbench'),
                chartController: _chartController,
                workbenchController: _workbenchController,
                initialDisplayMode: ChartDisplayMode.chart,
                availableDisplayModes: const {
                  ChartDisplayMode.chart,
                  ChartDisplayMode.data,
                  ChartDisplayMode.split,
                  ChartDisplayMode.source,
                },
                documentOptions: const ChartDocumentExtractOptions(
                  includeViewState: true,
                ),
                tableOptions: const ChartTableOptions(
                  rowLayout: ChartTableRowLayout.wide,
                ),
                tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
                sourceOptions: const ChartDartSourceOptions(
                  variableName: 'radarChart',
                ),
                grammarSourceOptions: const ChartGrammarSourceOptions(
                  variableName: 'radarChart',
                  rowClassName: 'RadarProfileRow',
                  rowsVariableName: 'radarRows',
                ),
                initialSourceForm: ChartSourceForm.grammar,
                splitBreakpoint: 760,
                splitRatio: 0.58,
                autoFitTablePane: true,
                minimumChartPaneExtent: 340,
                minimumTablePaneExtent: 360,
                maximumAutoTablePaneExtent: 560,
                splitGap: 10,
                chartBuilder: (context, controller) =>
                    _buildChart(series, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    List<RadarChartSeries> series,
    BravenChartController controller,
  ) {
    final chart = BravenChartPlus(
      key: ValueKey('radar-chart-${_presentation.name}-${_gridShape.name}'),
      title: _chartTitle,
      subtitle: _chartSubtitle,
      bravenChartController: controller,
      series: series,
      radarChartConfig: RadarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: _startAngleDegrees,
          outerRadiusFactor: 0.78,
        ),
        categoryAxis: RadarCategoryAxisConfig(
          showLabels: _showCategoryLabels,
          maximumVisibleLabels: 18,
          labelOffset: 10,
        ),
        radialAxis: RadarNumericAxisConfig(
          minimum: 0,
          maximum: 100,
          tickCount: _tickCount,
          showLabels: _showRadialLabels,
          gridShape: _gridShape,
        ),
      ),
      interactionConfig: const InteractionConfig(
        selection: ChartSelectionConfig(scope: ChartSelectionScope.category),
        tooltip: TooltipConfig(followCursor: false),
      ),
      showLegend: true,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: const XAxisConfig(visible: false),
    );
    if (!_previewReducedMotion) return chart;
    return MediaQuery(
      key: const ValueKey('radar-reduced-motion-preview'),
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: chart,
    );
  }

  Widget _buildInteractionStatus(List<RadarChartSeries> series) {
    final theme = Theme.of(context);
    final selected = _chartController.selectedPointRefs;
    final focused = _chartController.focusedPointRefs;
    final active = selected.isNotEmpty ? selected : focused;
    final category = _categoryForRefs(series, active);
    return Container(
      key: const ValueKey('radar-linked-status'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category == null
                  ? 'Hover a vertex or choose a row: every profile on that spoke tracks together.'
                  : '${selected.isNotEmpty ? 'Selected' : 'Focused'}: '
                        '$category · ${active.length} linked profile values',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (selected.isNotEmpty)
            TextButton.icon(
              key: const ValueKey('radar-clear-selection'),
              onPressed: _chartController.clearPointSelection,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  String? _categoryForRefs(
    List<RadarChartSeries> series,
    Set<ChartPointRef> refs,
  ) {
    final ref = refs.firstOrNull;
    if (ref == null) return null;
    final profile = series.where((item) => item.id == ref.seriesId).firstOrNull;
    if (profile == null || ref.pointIndex >= profile.points.length) return null;
    return profile.points[ref.pointIndex].label;
  }

  List<RadarChartSeries> _buildSeries() {
    final data = switch (_presentation) {
      _RadarPresentation.budget => const <Map<String, double>>[
        {
          'Sales': 43,
          'Marketing': 19,
          'Development': 60,
          'Customer Support': 35,
          'Information Technology': 17,
          'Administration': 10,
        },
        {
          'Sales': 50,
          'Marketing': 39,
          'Development': 42,
          'Customer Support': 31,
          'Information Technology': 26,
          'Administration': 14,
        },
      ],
      _RadarPresentation.capability => const <Map<String, double>>[
        {
          'Discovery': 82,
          'Delivery': 64,
          'Quality': 74,
          'Operations': 58,
          'Leadership': 76,
          'Learning': 68,
        },
        {
          'Discovery': 61,
          'Delivery': 78,
          'Quality': 67,
          'Operations': 84,
          'Leadership': 57,
          'Learning': 72,
        },
        {
          'Discovery': 70,
          'Delivery': 69,
          'Quality': 88,
          'Operations': 66,
          'Leadership': 81,
          'Learning': 76,
        },
      ],
      _RadarPresentation.service => const <Map<String, double>>[
        {
          'Availability': 96,
          'Latency': 72,
          'Errors': 81,
          'Capacity': 65,
          'Recovery': 88,
          'Security': 91,
          'Cost': 62,
          'Change': 77,
        },
        {
          'Availability': 90,
          'Latency': 84,
          'Errors': 75,
          'Capacity': 82,
          'Recovery': 71,
          'Security': 86,
          'Cost': 79,
          'Change': 69,
        },
      ],
    };
    final names = switch (_presentation) {
      _RadarPresentation.budget => const [
        'Allocated budget',
        'Actual spending',
      ],
      _RadarPresentation.capability => const [
        'Product team',
        'Platform team',
        'Quality team',
      ],
      _RadarPresentation.service => const ['Current window', 'Target profile'],
    };
    final colors = switch (_presentation) {
      _RadarPresentation.budget => const [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
      _RadarPresentation.capability => const [
        Color(0xFF7C3AED),
        Color(0xFF0D9488),
        Color(0xFFF59E0B),
      ],
      _RadarPresentation.service => const [
        Color(0xFF0891B2),
        Color(0xFFE11D48),
      ],
    };
    return [
      for (final (index, values) in data.indexed)
        RadarChartSeries.fromMap(
          id: '${_presentation.name}-$index',
          name: names[index],
          values: {
            for (final (categoryIndex, entry) in values.entries.indexed)
              entry.key: _updatedValue(
                entry.value,
                profileIndex: index,
                categoryIndex: categoryIndex,
              ),
          },
          color: colors[index],
          unit: '%',
          radarStyle: RadarSeriesStyle(
            strokeWidth: index == 0 ? 2.5 : 2,
            fillOpacity: _fillOpacity,
            showMarkers: _showMarkers,
            markerRadius: 3.5,
            showDataLabels: _showDataLabels,
            animationMode: _animationMode,
          ),
        ),
    ];
  }

  double _updatedValue(
    double value, {
    required int profileIndex,
    required int categoryIndex,
  }) {
    if (_valueRevision == 0) return value;
    final wave = math.sin(
      (_valueRevision + 1) * (profileIndex + 2) * (categoryIndex + 1) * 0.71,
    );
    return (value + wave * 12).clamp(5, 98).toDouble();
  }

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Radar geometry',
      icon: Icons.radar_outlined,
      description: 'Controls the shared category web and numeric radial scale.',
      children: [
        EnumOption<RadarGridShape>(
          label: 'Web shape',
          value: _gridShape,
          values: RadarGridShape.values,
          labelBuilder: (shape) => switch (shape) {
            RadarGridShape.polygon => 'Polygon web',
            RadarGridShape.circle => 'Circular web',
          },
          onChanged: (value) => setState(() => _gridShape = value),
        ),
        SliderOption(
          label: 'Start angle',
          value: _startAngleDegrees,
          min: -180,
          max: 180,
          divisions: 24,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _startAngleDegrees = value),
        ),
        IntSliderOption(
          label: 'Radial ticks',
          value: _tickCount,
          min: 2,
          max: 8,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Profile appearance',
      icon: Icons.layers_outlined,
      description:
          'Styles every authored profile while preserving its own series color.',
      children: [
        SliderOption(
          label: 'Fill opacity',
          value: _fillOpacity,
          min: 0,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _fillOpacity = value),
        ),
        BoolOption(
          label: 'Show markers',
          value: _showMarkers,
          onChanged: (value) => setState(() => _showMarkers = value),
        ),
        BoolOption(
          label: 'Show profile values',
          value: _showDataLabels,
          onChanged: (value) => setState(() => _showDataLabels = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Motion',
      icon: Icons.animation_outlined,
      description:
          'Replay entrance, interpolate stable categories, or preview reduced motion.',
      children: [
        EnumOption<RadarAnimationMode>(
          label: 'Profile animation',
          value: _animationMode,
          values: RadarAnimationMode.values,
          labelBuilder: (mode) => switch (mode) {
            RadarAnimationMode.radial => 'Grow from radial baseline',
            RadarAnimationMode.fade => 'Fade at final geometry',
            RadarAnimationMode.none => 'None',
          },
          onChanged: (value) => setState(() => _animationMode = value),
        ),
        BoolOption(
          label: 'Preview reduced motion',
          description: 'Renders the final frame immediately.',
          value: _previewReducedMotion,
          onChanged: (value) => setState(() => _previewReducedMotion = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Labels',
      icon: Icons.label_outline,
      description:
          'Separates category identity from numeric radial scale labels.',
      children: [
        BoolOption(
          label: 'Show category labels',
          value: _showCategoryLabels,
          onChanged: (value) => setState(() => _showCategoryLabels = value),
        ),
        BoolOption(
          label: 'Show radial labels',
          value: _showRadialLabels,
          onChanged: (value) => setState(() => _showRadialLabels = value),
        ),
      ],
    ),
  ];

  void _applyPresentation(_RadarPresentation presentation) {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _presentation = presentation;
      _gridShape = presentation == _RadarPresentation.capability
          ? RadarGridShape.circle
          : RadarGridShape.polygon;
      _showDataLabels = presentation == _RadarPresentation.service;
      _valueRevision = 0;
    });
  }

  void _resetExample() {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _presentation = _RadarPresentation.budget;
      _gridShape = RadarGridShape.polygon;
      _startAngleDegrees = -90;
      _tickCount = 5;
      _fillOpacity = 0.12;
      _showMarkers = true;
      _showDataLabels = false;
      _showCategoryLabels = true;
      _showRadialLabels = true;
      _animationMode = RadarAnimationMode.radial;
      _previewReducedMotion = false;
      _valueRevision = 0;
    });
  }

  void _updateValues() {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() => _valueRevision++);
  }

  String get _chartTitle => switch (_presentation) {
    _RadarPresentation.budget => 'Budget vs spending',
    _RadarPresentation.capability => 'Team capability profile',
    _RadarPresentation.service => 'Service health profile',
  };

  String get _chartSubtitle => switch (_presentation) {
    _RadarPresentation.budget =>
      'Allocated budget and actual spending across six departments',
    _RadarPresentation.capability =>
      'Three teams compared across one common capability model',
    _RadarPresentation.service =>
      'Current operations compared with the target service profile',
  };

  String get _presentationDescription => switch (_presentation) {
    _RadarPresentation.budget =>
      'Compare two related profiles across the same six departmental dimensions.',
    _RadarPresentation.capability =>
      'A circular web compares three teams without implying a part-to-whole total.',
    _RadarPresentation.service =>
      'Eight operational dimensions exercise denser labels and optional point values.',
  };
}
