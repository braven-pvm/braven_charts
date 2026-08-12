// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/options_panel.dart';
import '../widgets/persistent_resizable_chart_panel.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

enum _RadarPresentation {
  budget('Budget vs spending', Icons.account_balance_wallet_outlined),
  capability('Capability profile', Icons.hub_outlined),
  comparison('Product comparison', Icons.compare_arrows_outlined),
  scorecard('Normalized scorecard', Icons.fact_check_outlined),
  highContrast('High contrast', Icons.contrast_outlined),
  service('Service health', Icons.monitor_heart_outlined),
  compact('Compact KPI', Icons.phone_android_outlined),
  risk('Risk exposure', Icons.shield_outlined),
  longLabels('Long labels', Icons.text_fields_outlined),
  dense('Dense stress', Icons.blur_circular_outlined),
  playground('Playground', Icons.science_outlined);

  const _RadarPresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _RadarLinePattern {
  solid('Solid', <double>[]),
  dashed('Dashed', <double>[7, 4]),
  dotted('Dotted', <double>[2, 3]);

  const _RadarLinePattern(this.label, this.pattern);

  final String label;
  final List<double> pattern;
}

enum _RadarThemePreset {
  light('Light'),
  dark('Dark'),
  highContrast('High contrast'),
  colorblind('Color-blind friendly');

  const _RadarThemePreset(this.label);

  final String label;
}

class RadarChartsPage extends StatefulWidget {
  const RadarChartsPage({super.key});

  @override
  State<RadarChartsPage> createState() => _RadarChartsPageState();
}

class _RadarChartsPageState extends State<RadarChartsPage> {
  late final BravenChartController _chartController;
  late final ChartWorkbenchController _workbenchController;
  late final ShowcaseRandomizerController<int> _showcaseRandomizer;
  _RadarPresentation _presentation = _RadarPresentation.budget;
  RadarGridShape _gridShape = RadarGridShape.polygon;
  double _startAngleDegrees = -90;
  bool _clockwise = true;
  double _outerRadiusFactor = 0.78;
  int _tickCount = 5;
  bool _showRings = true;
  bool _showSpokes = true;
  Color? _ringColor;
  Color? _spokeColor;
  Color? _boundaryColor;
  double _ringWidth = 1;
  double _spokeWidth = 1;
  double _boundaryWidth = 1.5;
  _RadarLinePattern _ringPattern = _RadarLinePattern.solid;
  _RadarLinePattern _spokePattern = _RadarLinePattern.solid;
  _RadarLinePattern _boundaryPattern = _RadarLinePattern.solid;
  double _strokeWidth = 2.5;
  double _strokeOpacity = 1;
  _RadarLinePattern _strokePattern = _RadarLinePattern.solid;
  double _fillOpacity = 0.12;
  Color? _profileFillColor;
  bool _gradientEnabled = false;
  RadarGradientType _gradientType = RadarGradientType.radial;
  Color? _gradientStartColor;
  Color? _gradientEndColor;
  double _gradientStartLightnessShift = 0.2;
  double _gradientEndLightnessShift = -0.14;
  double _gradientAngle = 0;
  bool _shadowEnabled = false;
  Color? _shadowColor;
  double _shadowBlur = 10;
  double _shadowSpread = 1;
  double _shadowOffsetX = 0;
  double _shadowOffsetY = 3;
  double _shadowOpacity = 0.25;
  bool _showMarkers = true;
  SeriesMarkerShape _markerShape = SeriesMarkerShape.circle;
  double _markerRadius = 3.5;
  Color? _markerFillColor;
  Color? _markerBorderColor;
  double _markerBorderWidth = 0;
  bool _showDataLabels = false;
  int _maximumDataLabels = 24;
  double _dataLabelOffset = 8;
  Color? _dataLabelColor;
  double _dataLabelFontSize = 11;
  FontWeight _dataLabelWeight = FontWeight.w600;
  bool _showCategoryLabels = true;
  int _maximumCategoryLabels = 18;
  double _categoryLabelOffset = 10;
  Color? _categoryLabelColor;
  double _categoryLabelFontSize = 12;
  FontWeight _categoryLabelWeight = FontWeight.normal;
  bool _showRadialLabels = true;
  PolarRadialLabelPosition _radialLabelPosition =
      PolarRadialLabelPosition.start;
  double _radialLabelAngle = 0;
  double _radialLabelOffset = 4;
  Color? _radialLabelColor;
  double _radialLabelFontSize = 10;
  FontWeight _radialLabelWeight = FontWeight.normal;
  bool _showLegend = true;
  LegendPosition _legendPosition = LegendPosition.topRight;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.line;
  Color? _legendBackgroundColor;
  Color? _legendBorderColor;
  Color? _legendTextColor;
  double _legendBorderWidth = 0;
  double _legendOpacity = 1;
  bool _tooltipEnabled = true;
  TooltipTriggerMode _tooltipTriggerMode = TooltipTriggerMode.hover;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowCursor = false;
  double _tooltipOffset = 8;
  Color? _tooltipBackgroundColor;
  Color? _tooltipBorderColor;
  Color? _tooltipTextColor;
  double _tooltipBorderWidth = 1;
  double _tooltipBorderRadius = 6;
  Color? _tooltipShadowColor;
  double _tooltipShadowBlur = 4;
  double _tooltipPadding = 8;
  double _tooltipFontSize = 12;
  ChartSelectionScope _selectionScope = ChartSelectionScope.category;
  bool _clearSelectionOnBackgroundTap = true;
  double _selectionHitRadius = 20;
  double _selectionHoverScale = 1.5;
  double _selectionScale = 2.67;
  _RadarThemePreset _themePreset = _RadarThemePreset.light;
  RadarAnimationMode _animationMode = RadarAnimationMode.radial;
  bool _previewReducedMotion = false;
  double _previewTextScale = 1;
  int _valueRevision = 0;
  int _playgroundSeed = 47;
  int _playgroundCategoryCount = 12;
  int _playgroundProfileCount = 5;
  List<Color> _playgroundColors = const <Color>[
    Color(0xFF0EA5E9),
    Color(0xFFF97316),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _chartController = BravenChartController()..addListener(_handleChartState);
    _workbenchController = ChartWorkbenchController();
    _showcaseRandomizer = ShowcaseRandomizerController<int>(
      generate: (seed) => seed,
      apply: _applyRandomSeed,
      initialSeed: _playgroundSeed,
    );
  }

  @override
  void dispose() {
    _chartController
      ..removeListener(_handleChartState)
      ..dispose();
    _workbenchController.dispose();
    _showcaseRandomizer.dispose();
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
      playground: ChartPlaygroundConfig(
        active: _presentation == _RadarPresentation.playground,
        optionsChildren: _buildOptions(),
        randomizer: _showcaseRandomizer,
      ),
      randomizerKeyPrefix: 'radar-randomizer',
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
          // Radar needs more vertical runway than Cartesian plots because the
          // web, outside category labels, legend, and workbench chrome all
          // share the shortest dimension. Keep the initial desktop pane large
          // enough to demonstrate the chart rather than a thumbnail.
          minimumPanelHeight: compact ? 500 : 480,
          maximumPanelHeight: compact ? 1200 : 960,
          initialPanelHeight: 680,
          scrollViewKey: const ValueKey('radar-showcase-scroll'),
          leading: [_buildPresentationSelector(), const SizedBox(height: 16)],
          panel: _buildChartCard(),
          trailing: [const SizedBox(height: 24), _buildMobileExamples()],
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
        'shared 0–100 scale · '
        '${_presentation == _RadarPresentation.playground ? 'seed $_playgroundSeed · ' : ''}'
        'update $_valueRevision';
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

  Widget _buildMobileExamples() {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Mobile Radar chart examples',
      child: Column(
        key: const ValueKey('radar-mobile-examples'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Built for constrained and touch-first surfaces',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compact labels, generous vertex hit targets, and long-press detail keep the web useful without taking over the screen.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 720
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _RadarMobileExampleCard(
                      example: _RadarMobileExample.snapshot,
                      onOpen: () =>
                          _applyPresentation(_RadarPresentation.compact),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _RadarMobileExampleCard(
                      example: _RadarMobileExample.touchComparison,
                      onOpen: () =>
                          _applyPresentation(_RadarPresentation.service),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _RadarMobileExampleCard(
                      example: _RadarMobileExample.largeText,
                      onOpen: () =>
                          _applyPresentation(_RadarPresentation.longLabels),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    List<RadarChartSeries> series,
    BravenChartController controller,
  ) {
    final chart = BravenChartPlus(
      key: ValueKey('radar-chart-${_presentation.name}-${_gridShape.name}'),
      // The workbench card already provides the authored title and context.
      // Repeating them inside the finite chart pane disproportionately shrinks
      // axisless charts, particularly Radar webs with outside labels.
      bravenChartController: controller,
      series: series,
      radarChartConfig: RadarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: _startAngleDegrees,
          clockwise: _clockwise,
          outerRadiusFactor: _outerRadiusFactor,
        ),
        categoryAxis: RadarCategoryAxisConfig(
          showLabels: _showCategoryLabels,
          showSpokes: _showSpokes,
          maximumVisibleLabels: _maximumCategoryLabels,
          labelOffset: _categoryLabelOffset,
          labelStyle: PolarLabelStyle(
            color: _categoryLabelColor,
            fontSize: _categoryLabelFontSize,
            fontWeight: _categoryLabelWeight,
          ),
        ),
        radialAxis: RadarNumericAxisConfig(
          minimum: 0,
          maximum: 100,
          tickCount: _tickCount,
          showLabels: _showRadialLabels,
          showGridLines: _showRings,
          gridShape: _gridShape,
          labelPosition: _radialLabelPosition,
          labelAngleOffsetDegrees: _radialLabelAngle,
          labelOffset: _radialLabelOffset,
          labelStyle: PolarLabelStyle(
            color: _radialLabelColor,
            fontSize: _radialLabelFontSize,
            fontWeight: _radialLabelWeight,
          ),
        ),
        webStyle: RadarWebStyle(
          ringColor: _ringColor,
          ringWidth: _ringWidth,
          ringDashPattern: _ringPattern.pattern,
          spokeColor: _spokeColor,
          spokeWidth: _spokeWidth,
          spokeDashPattern: _spokePattern.pattern,
          boundaryColor: _boundaryColor,
          boundaryWidth: _boundaryWidth,
          boundaryDashPattern: _boundaryPattern.pattern,
        ),
      ),
      interactionConfig: InteractionConfig(
        selection: ChartSelectionConfig(
          scope: _selectionScope,
          clearOnBackgroundTap: _clearSelectionOnBackgroundTap,
          dataPointHitRadius: _selectionHitRadius,
          dataPointHoverScale: _selectionHoverScale,
          dataPointSelectionScale: _selectionScale,
        ),
        tooltip: TooltipConfig(
          enabled: _tooltipEnabled,
          triggerMode: _tooltipTriggerMode,
          preferredPosition: _tooltipPosition,
          followCursor: _tooltipFollowCursor,
          offsetFromPoint: _tooltipOffset,
          style: TooltipStyle(
            backgroundColor:
                _tooltipBackgroundColor ??
                _effectiveTheme.interactionTheme.tooltipStyle.backgroundColor,
            borderColor:
                _tooltipBorderColor ??
                _effectiveTheme.interactionTheme.tooltipStyle.borderColor,
            borderWidth: _tooltipBorderWidth,
            borderRadius: _tooltipBorderRadius,
            shadowColor:
                _tooltipShadowColor ??
                _effectiveTheme.interactionTheme.tooltipStyle.shadowColor ??
                Colors.transparent,
            shadowBlurRadius: _tooltipShadowBlur,
            padding: _tooltipPadding,
            textColor:
                _tooltipTextColor ??
                _effectiveTheme.interactionTheme.tooltipStyle.textStyle.color ??
                Colors.black,
            fontSize: _tooltipFontSize,
          ),
        ),
      ),
      showLegend: _showLegend,
      legendStyle: _effectiveTheme.legendStyle.copyWith(
        position: _legendPosition,
        orientation: _legendOrientation,
        markerShape: _legendMarkerShape,
        backgroundColor: _legendBackgroundColor,
        borderColor: _legendBorderColor,
        borderWidth: _legendBorderWidth,
        textStyle: _effectiveTheme.legendStyle.textStyle.copyWith(
          color: _legendTextColor,
        ),
        opacity: _legendOpacity,
      ),
      theme: _effectiveTheme,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: const XAxisConfig(visible: false),
    );
    Widget result = chart;
    if (_previewTextScale != 1) {
      result = MediaQuery(
        key: const ValueKey('radar-large-text-preview'),
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(_previewTextScale)),
        child: result,
      );
    }
    if (_previewReducedMotion) {
      result = MediaQuery(
        key: const ValueKey('radar-reduced-motion-preview'),
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: result,
      );
    }
    return result;
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
      _RadarPresentation.comparison => const <Map<String, double>>[
        {
          'Performance': 88,
          'Battery': 63,
          'Camera': 79,
          'Display': 92,
          'Durability': 58,
          'Value': 74,
        },
        {
          'Performance': 72,
          'Battery': 91,
          'Camera': 68,
          'Display': 77,
          'Durability': 84,
          'Value': 82,
        },
        {
          'Performance': 81,
          'Battery': 75,
          'Camera': 93,
          'Display': 70,
          'Durability': 76,
          'Value': 66,
        },
      ],
      _RadarPresentation.scorecard => const <Map<String, double>>[
        {
          'Strategy': 76,
          'Execution': 84,
          'Customers': 69,
          'People': 81,
          'Risk': 73,
          'Innovation': 65,
          'Sustainability': 78,
        },
        {
          'Strategy': 70,
          'Execution': 70,
          'Customers': 70,
          'People': 70,
          'Risk': 70,
          'Innovation': 70,
          'Sustainability': 70,
        },
      ],
      _RadarPresentation.highContrast => const <Map<String, double>>[
        {'Discover': 86, 'Plan': 64, 'Build': 91, 'Verify': 72, 'Release': 80},
        {'Discover': 61, 'Plan': 83, 'Build': 69, 'Verify': 88, 'Release': 70},
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
      _RadarPresentation.compact => const <Map<String, double>>[
        {'Focus': 86, 'Energy': 72, 'Recovery': 64, 'Load': 78, 'Sleep': 59},
      ],
      _RadarPresentation.risk => const <Map<String, double>>[
        {
          'Security': 78,
          'Availability': 52,
          'Compliance': 88,
          'Supplier': 44,
          'Financial': 63,
          'People': 71,
          'Delivery': 57,
        },
        {
          'Security': 58,
          'Availability': 77,
          'Compliance': 62,
          'Supplier': 81,
          'Financial': 48,
          'People': 66,
          'Delivery': 74,
        },
        {
          'Security': 42,
          'Availability': 42,
          'Compliance': 42,
          'Supplier': 42,
          'Financial': 42,
          'People': 42,
          'Delivery': 42,
        },
      ],
      _RadarPresentation.longLabels => const <Map<String, double>>[
        {
          'Customer satisfaction': 84,
          'Operational resilience': 72,
          'Information security': 91,
          'Employee engagement': 65,
          'Sustainable delivery': 76,
          'Financial stewardship': 69,
          'Product innovation': 82,
        },
        {
          'Customer satisfaction': 75,
          'Operational resilience': 80,
          'Information security': 78,
          'Employee engagement': 74,
          'Sustainable delivery': 70,
          'Financial stewardship': 77,
          'Product innovation': 71,
        },
      ],
      _RadarPresentation.dense => <Map<String, double>>[
        for (var profile = 0; profile < 4; profile++)
          {
            for (var category = 1; category <= 20; category++)
              'Metric $category':
                  28 +
                  58 *
                      (0.5 +
                          0.5 *
                              math.sin(
                                category * (0.41 + profile * 0.07) + profile,
                              )),
          },
      ],
      _RadarPresentation.playground => <Map<String, double>>[
        for (var profile = 0; profile < _playgroundProfileCount; profile++)
          {
            for (
              var category = 1;
              category <= _playgroundCategoryCount;
              category++
            )
              'Dimension $category':
                  12 +
                  ((_playgroundValue(profile, category) * 83).roundToDouble()),
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
      _RadarPresentation.comparison => const ['Atlas', 'Boreal', 'Cirrus'],
      _RadarPresentation.scorecard => const ['Current score', 'Target score'],
      _RadarPresentation.highContrast => const ['Programme A', 'Programme B'],
      _RadarPresentation.service => const ['Current window', 'Target profile'],
      _RadarPresentation.compact => const ['Today'],
      _RadarPresentation.risk => const [
        'Current exposure',
        'Previous quarter',
        'Risk appetite',
      ],
      _RadarPresentation.longLabels => const ['Current year', 'Previous year'],
      _RadarPresentation.dense => const ['North', 'South', 'East', 'West'],
      _RadarPresentation.playground => <String>[
        for (var index = 0; index < _playgroundProfileCount; index++)
          'Profile ${String.fromCharCode(65 + index)}',
      ],
    };
    final colors = switch (_presentation) {
      _RadarPresentation.budget => const [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
      _RadarPresentation.capability => const [
        Color(0xFF7C3AED),
        Color(0xFF0D9488),
        Color(0xFFF59E0B),
      ],
      _RadarPresentation.comparison => const [
        Color(0xFF2563EB),
        Color(0xFFEA580C),
        Color(0xFF7C3AED),
      ],
      _RadarPresentation.scorecard => const [
        Color(0xFF059669),
        Color(0xFF475569),
      ],
      _RadarPresentation.highContrast => const [
        Color(0xFFFFD400),
        Color(0xFF00E5FF),
      ],
      _RadarPresentation.service => const [
        Color(0xFF0891B2),
        Color(0xFFE11D48),
      ],
      _RadarPresentation.compact => const [Color(0xFF0F766E)],
      _RadarPresentation.risk => const [
        Color(0xFFE11D48),
        Color(0xFFF59E0B),
        Color(0xFF475569),
      ],
      _RadarPresentation.longLabels => const [
        Color(0xFF2563EB),
        Color(0xFF7C3AED),
      ],
      _RadarPresentation.dense => const [
        Color(0xFF2563EB),
        Color(0xFFDC2626),
        Color(0xFF059669),
        Color(0xFF9333EA),
      ],
      _RadarPresentation.playground => _playgroundColors,
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
            strokeWidth: index == 0 ? _strokeWidth : _strokeWidth * 0.86,
            strokeOpacity: _strokeOpacity,
            strokeDashPattern:
                index.isOdd && _presentation == _RadarPresentation.comparison
                ? _RadarLinePattern.dashed.pattern
                : _strokePattern.pattern,
            fillColor: _profileFillColor,
            fillOpacity: _fillOpacity,
            gradient: _gradientEnabled
                ? RadarGradientStyle(
                    type: _gradientType,
                    startColor: _gradientStartColor,
                    endColor: _gradientEndColor,
                    startLightnessShift: _gradientStartLightnessShift,
                    endLightnessShift: _gradientEndLightnessShift,
                    angleDegrees: _gradientAngle,
                  )
                : null,
            shadow: _shadowEnabled
                ? RadarShadowStyle(
                    color: _shadowColor,
                    blurRadius: _shadowBlur,
                    spreadRadius: _shadowSpread,
                    offset: Offset(_shadowOffsetX, _shadowOffsetY),
                    opacity: _shadowOpacity,
                  )
                : const RadarShadowStyle(),
            showMarkers: _showMarkers,
            markerShape: _markerShape,
            markerRadius: _markerRadius,
            markerFillColor: _markerFillColor,
            markerBorderColor: _markerBorderColor,
            markerBorderWidth: _markerBorderWidth,
            showDataLabels: _showDataLabels,
            maximumVisibleDataLabels: _maximumDataLabels,
            dataLabelOffset: _dataLabelOffset,
            dataLabelStyle: PolarLabelStyle(
              color: _dataLabelColor,
              fontSize: _dataLabelFontSize,
              fontWeight: _dataLabelWeight,
            ),
            animationMode: _animationMode,
          ),
        ),
    ];
  }

  double _playgroundValue(int profile, int category) {
    final seed =
        (_playgroundSeed + _valueRevision * 7919) * 7919 +
        profile * 104729 +
        category * 31;
    final mixed = math.sin(seed * 12.9898) * 43758.5453;
    return mixed - mixed.floorToDouble();
  }

  ChartTheme get _effectiveTheme => switch (_themePreset) {
    _RadarThemePreset.light => ChartTheme.light,
    _RadarThemePreset.dark => ChartTheme.dark,
    _RadarThemePreset.highContrast => ChartTheme.highContrast,
    _RadarThemePreset.colorblind => ChartTheme.colorblindFriendly,
  };

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
        BoolOption(
          label: 'Clockwise order',
          value: _clockwise,
          onChanged: (value) => setState(() => _clockwise = value),
        ),
        SliderOption(
          label: 'Chart radius',
          value: _outerRadiusFactor,
          min: 0.45,
          max: 0.92,
          divisions: 47,
          suffix: 'factor',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _outerRadiusFactor = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Category labels',
      icon: Icons.label_outline,
      description: 'Styles and density-bounds the labels around the web.',
      children: [
        BoolOption(
          label: 'Show category labels',
          value: _showCategoryLabels,
          onChanged: (value) => setState(() => _showCategoryLabels = value),
        ),
        IntSliderOption(
          label: 'Maximum visible labels',
          value: _maximumCategoryLabels,
          min: 3,
          max: 32,
          onChanged: (value) => setState(() => _maximumCategoryLabels = value),
        ),
        SliderOption(
          label: 'Category label offset',
          value: _categoryLabelOffset,
          min: -8,
          max: 40,
          divisions: 48,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _categoryLabelOffset = value),
        ),
        PaletteColorOption(
          label: 'Category label color',
          value: _categoryLabelColor,
          keyPrefix: 'radar-category-label-color',
          customColorFallback: _effectiveTheme.axisStyle.labelStyle.color,
          onChanged: (value) => setState(() => _categoryLabelColor = value),
        ),
        SliderOption(
          label: 'Category font size',
          value: _categoryLabelFontSize,
          min: 8,
          max: 24,
          divisions: 16,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _categoryLabelFontSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Category font weight',
          value: _categoryLabelWeight,
          values: const [FontWeight.w400, FontWeight.w600, FontWeight.w700],
          labelBuilder: _fontWeightLabel,
          onChanged: (value) => setState(() => _categoryLabelWeight = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Radial scale and labels',
      icon: Icons.straighten_outlined,
      description: 'Controls numeric rings and the single visible label ray.',
      children: [
        IntSliderOption(
          label: 'Radial ticks',
          value: _tickCount,
          min: 2,
          max: 12,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
        BoolOption(
          label: 'Show radial labels',
          value: _showRadialLabels,
          onChanged: (value) => setState(() => _showRadialLabels = value),
        ),
        EnumOption<PolarRadialLabelPosition>(
          label: 'Radial label position',
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
          label: 'Radial label angle',
          value: _radialLabelAngle,
          min: -180,
          max: 180,
          divisions: 36,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _radialLabelAngle = value),
        ),
        SliderOption(
          label: 'Radial label offset',
          value: _radialLabelOffset,
          min: -12,
          max: 24,
          divisions: 36,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _radialLabelOffset = value),
        ),
        PaletteColorOption(
          label: 'Radial label color',
          value: _radialLabelColor,
          keyPrefix: 'radar-radial-label-color',
          customColorFallback: _effectiveTheme.axisStyle.labelStyle.color,
          onChanged: (value) => setState(() => _radialLabelColor = value),
        ),
        SliderOption(
          label: 'Radial font size',
          value: _radialLabelFontSize,
          min: 8,
          max: 20,
          divisions: 12,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _radialLabelFontSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Radial font weight',
          value: _radialLabelWeight,
          values: const [FontWeight.w400, FontWeight.w600, FontWeight.w700],
          labelBuilder: _fontWeightLabel,
          onChanged: (value) => setState(() => _radialLabelWeight = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Web lines',
      icon: Icons.grid_4x4_outlined,
      description:
          'Styles rings, spokes, and the outer boundary independently.',
      children: [
        BoolOption(
          label: 'Show rings',
          value: _showRings,
          onChanged: (value) => setState(() => _showRings = value),
        ),
        PaletteColorOption(
          label: 'Ring color',
          value: _ringColor,
          keyPrefix: 'radar-ring-color',
          customColorFallback: _effectiveTheme.gridStyle.majorColor,
          onChanged: (value) => setState(() => _ringColor = value),
        ),
        SliderOption(
          label: 'Ring width',
          value: _ringWidth,
          min: 0.25,
          max: 5,
          divisions: 19,
          suffix: ' px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _ringWidth = value),
        ),
        EnumOption<_RadarLinePattern>(
          label: 'Ring pattern',
          value: _ringPattern,
          values: _RadarLinePattern.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _ringPattern = value),
        ),
        BoolOption(
          label: 'Show spokes',
          value: _showSpokes,
          onChanged: (value) => setState(() => _showSpokes = value),
        ),
        PaletteColorOption(
          label: 'Spoke color',
          value: _spokeColor,
          keyPrefix: 'radar-spoke-color',
          customColorFallback: _effectiveTheme.gridStyle.majorColor,
          onChanged: (value) => setState(() => _spokeColor = value),
        ),
        SliderOption(
          label: 'Spoke width',
          value: _spokeWidth,
          min: 0.25,
          max: 5,
          divisions: 19,
          suffix: ' px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _spokeWidth = value),
        ),
        EnumOption<_RadarLinePattern>(
          label: 'Spoke pattern',
          value: _spokePattern,
          values: _RadarLinePattern.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _spokePattern = value),
        ),
        PaletteColorOption(
          label: 'Boundary color',
          value: _boundaryColor,
          keyPrefix: 'radar-boundary-color',
          customColorFallback: _effectiveTheme.axisStyle.lineColor,
          onChanged: (value) => setState(() => _boundaryColor = value),
        ),
        SliderOption(
          label: 'Boundary width',
          value: _boundaryWidth,
          min: 0.25,
          max: 6,
          divisions: 23,
          suffix: ' px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _boundaryWidth = value),
        ),
        EnumOption<_RadarLinePattern>(
          label: 'Boundary pattern',
          value: _boundaryPattern,
          values: _RadarLinePattern.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _boundaryPattern = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Profile stroke and fill',
      icon: Icons.layers_outlined,
      description: 'Styles every profile while retaining its series identity.',
      children: [
        SliderOption(
          label: 'Stroke width',
          value: _strokeWidth,
          min: 0.5,
          max: 8,
          divisions: 30,
          suffix: ' px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _strokeWidth = value),
        ),
        SliderOption(
          label: 'Stroke opacity',
          value: _strokeOpacity,
          min: 0.1,
          max: 1,
          divisions: 18,
          suffix: 'opacity',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _strokeOpacity = value),
        ),
        EnumOption<_RadarLinePattern>(
          label: 'Stroke pattern',
          value: _strokePattern,
          values: _RadarLinePattern.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _strokePattern = value),
        ),
        PaletteColorOption(
          label: 'Shared fill color',
          subtitle: 'Clear to retain each series color.',
          value: _profileFillColor,
          keyPrefix: 'radar-profile-fill-color',
          customColorFallback: const Color(0xFF2563EB),
          onChanged: (value) => setState(() => _profileFillColor = value),
        ),
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
          label: 'Gradient fill',
          value: _gradientEnabled,
          onChanged: (value) => setState(() => _gradientEnabled = value),
        ),
        if (_gradientEnabled) ...[
          EnumOption<RadarGradientType>(
            label: 'Gradient type',
            value: _gradientType,
            values: RadarGradientType.values,
            labelBuilder: (value) => switch (value) {
              RadarGradientType.linear => 'Linear',
              RadarGradientType.radial => 'Radial',
            },
            onChanged: (value) => setState(() => _gradientType = value),
          ),
          PaletteColorOption(
            label: 'Gradient start color',
            subtitle: 'Clear to derive from each series color.',
            value: _gradientStartColor,
            keyPrefix: 'radar-gradient-start-color',
            customColorFallback: const Color(0xFF38BDF8),
            onChanged: (value) => setState(() => _gradientStartColor = value),
          ),
          PaletteColorOption(
            label: 'Gradient end color',
            subtitle: 'Clear to derive from each series color.',
            value: _gradientEndColor,
            keyPrefix: 'radar-gradient-end-color',
            customColorFallback: const Color(0xFF312E81),
            onChanged: (value) => setState(() => _gradientEndColor = value),
          ),
          SliderOption(
            label: 'Start lightness shift',
            value: _gradientStartLightnessShift,
            min: -1,
            max: 1,
            divisions: 40,
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _gradientStartLightnessShift = value),
          ),
          SliderOption(
            label: 'End lightness shift',
            value: _gradientEndLightnessShift,
            min: -1,
            max: 1,
            divisions: 40,
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _gradientEndLightnessShift = value),
          ),
          if (_gradientType == RadarGradientType.linear)
            SliderOption(
              label: 'Gradient angle',
              value: _gradientAngle,
              min: -180,
              max: 180,
              divisions: 36,
              suffix: '°',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _gradientAngle = value),
            ),
        ],
        BoolOption(
          label: 'Profile shadow',
          value: _shadowEnabled,
          onChanged: (value) => setState(() => _shadowEnabled = value),
        ),
        if (_shadowEnabled) ...[
          PaletteColorOption(
            label: 'Shadow color',
            subtitle: 'Clear to derive from each series color.',
            value: _shadowColor,
            keyPrefix: 'radar-shadow-color',
            customColorFallback: Colors.black,
            onChanged: (value) => setState(() => _shadowColor = value),
          ),
          SliderOption(
            label: 'Shadow blur',
            value: _shadowBlur,
            min: 0,
            max: 30,
            divisions: 30,
            suffix: ' px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _shadowBlur = value),
          ),
          SliderOption(
            label: 'Shadow spread',
            value: _shadowSpread,
            min: 0,
            max: 10,
            divisions: 20,
            suffix: ' px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _shadowSpread = value),
          ),
          SliderOption(
            label: 'Shadow X offset',
            value: _shadowOffsetX,
            min: -12,
            max: 12,
            divisions: 24,
            suffix: ' px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _shadowOffsetX = value),
          ),
          SliderOption(
            label: 'Shadow Y offset',
            value: _shadowOffsetY,
            min: -12,
            max: 12,
            divisions: 24,
            suffix: ' px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _shadowOffsetY = value),
          ),
          SliderOption(
            label: 'Shadow opacity',
            value: _shadowOpacity,
            min: 0,
            max: 0.8,
            divisions: 16,
            suffix: 'opacity',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _shadowOpacity = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Markers and profile values',
      icon: Icons.scatter_plot_outlined,
      description:
          'Styles vertices and direct values without changing profile geometry.',
      children: [
        BoolOption(
          label: 'Show markers',
          value: _showMarkers,
          onChanged: (value) => setState(() => _showMarkers = value),
        ),
        if (_showMarkers) ...[
          EnumOption<SeriesMarkerShape>(
            label: 'Marker shape',
            value: _markerShape,
            values: SeriesMarkerShape.values,
            onChanged: (value) => setState(() => _markerShape = value),
          ),
          SliderOption(
            label: 'Marker radius',
            value: _markerRadius,
            min: 0,
            max: 10,
            divisions: 20,
            suffix: ' px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _markerRadius = value),
          ),
          PaletteColorOption(
            label: 'Marker fill',
            subtitle: 'Clear to inherit each series color.',
            value: _markerFillColor,
            keyPrefix: 'radar-marker-fill-color',
            customColorFallback: const Color(0xFF38BDF8),
            onChanged: (value) => setState(() => _markerFillColor = value),
          ),
          PaletteColorOption(
            label: 'Marker border',
            subtitle: 'Clear to inherit each series color.',
            value: _markerBorderColor,
            keyPrefix: 'radar-marker-border-color',
            customColorFallback: const Color(0xFF0F172A),
            onChanged: (value) => setState(() => _markerBorderColor = value),
          ),
          SliderOption(
            label: 'Marker border width',
            value: _markerBorderWidth,
            min: 0,
            max: 6,
            divisions: 24,
            suffix: ' px',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _markerBorderWidth = value),
          ),
        ],
        BoolOption(
          label: 'Show profile values',
          value: _showDataLabels,
          onChanged: (value) => setState(() => _showDataLabels = value),
        ),
        if (_showDataLabels) ...[
          SliderOption(
            label: 'Maximum visible values',
            value: _maximumDataLabels.toDouble(),
            min: 1,
            max: 48,
            divisions: 47,
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _maximumDataLabels = value.round()),
          ),
          SliderOption(
            label: 'Value label offset',
            value: _dataLabelOffset,
            min: -20,
            max: 40,
            divisions: 60,
            suffix: ' px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _dataLabelOffset = value),
          ),
          PaletteColorOption(
            label: 'Value label color',
            subtitle: 'Clear to inherit each series color.',
            value: _dataLabelColor,
            keyPrefix: 'radar-data-label-color',
            customColorFallback: _effectiveTheme.axisStyle.labelStyle.color,
            onChanged: (value) => setState(() => _dataLabelColor = value),
          ),
          SliderOption(
            label: 'Value font size',
            value: _dataLabelFontSize,
            min: 8,
            max: 24,
            divisions: 16,
            suffix: ' px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _dataLabelFontSize = value),
          ),
          EnumOption<FontWeight>(
            label: 'Value font weight',
            value: _dataLabelWeight,
            values: const [FontWeight.w400, FontWeight.w600, FontWeight.w700],
            labelBuilder: _fontWeightLabel,
            onChanged: (value) => setState(() => _dataLabelWeight = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Legend',
      icon: Icons.view_list_outlined,
      description: 'Controls profile identity outside the Radar pane.',
      children: [
        BoolOption(
          label: 'Show legend',
          value: _showLegend,
          onChanged: (value) => setState(() => _showLegend = value),
        ),
        EnumOption<LegendPosition>(
          label: 'Legend position',
          value: _legendPosition,
          values: LegendPosition.values,
          onChanged: (value) => setState(() => _legendPosition = value),
        ),
        EnumOption<LegendOrientation>(
          label: 'Legend orientation',
          value: _legendOrientation,
          values: LegendOrientation.values,
          onChanged: (value) => setState(() => _legendOrientation = value),
        ),
        EnumOption<LegendMarkerShape>(
          label: 'Legend marker',
          value: _legendMarkerShape,
          values: LegendMarkerShape.values,
          onChanged: (value) => setState(() => _legendMarkerShape = value),
        ),
        PaletteColorOption(
          label: 'Legend background',
          value: _legendBackgroundColor,
          keyPrefix: 'radar-legend-background-color',
          customColorFallback: _effectiveTheme.backgroundColor,
          onChanged: (value) => setState(() => _legendBackgroundColor = value),
        ),
        PaletteColorOption(
          label: 'Legend border',
          value: _legendBorderColor,
          keyPrefix: 'radar-legend-border-color',
          customColorFallback: _effectiveTheme.axisStyle.lineColor,
          onChanged: (value) => setState(() => _legendBorderColor = value),
        ),
        PaletteColorOption(
          label: 'Legend text',
          value: _legendTextColor,
          keyPrefix: 'radar-legend-text-color',
          customColorFallback: _effectiveTheme.axisStyle.labelStyle.color,
          onChanged: (value) => setState(() => _legendTextColor = value),
        ),
        SliderOption(
          label: 'Legend border width',
          value: _legendBorderWidth,
          min: 0,
          max: 4,
          divisions: 16,
          suffix: ' px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _legendBorderWidth = value),
        ),
        SliderOption(
          label: 'Legend opacity',
          value: _legendOpacity,
          min: 0.2,
          max: 1,
          divisions: 16,
          suffix: 'opacity',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _legendOpacity = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Tooltip',
      icon: Icons.chat_bubble_outline,
      description:
          'Controls how one Radar vertex explains its category and profile value.',
      children: [
        BoolOption(
          label: 'Show tooltip',
          value: _tooltipEnabled,
          onChanged: (value) => setState(() => _tooltipEnabled = value),
        ),
        EnumOption<TooltipTriggerMode>(
          label: 'Tooltip trigger',
          value: _tooltipTriggerMode,
          values: TooltipTriggerMode.values,
          onChanged: (value) => setState(() => _tooltipTriggerMode = value),
        ),
        EnumOption<TooltipPosition>(
          label: 'Tooltip position',
          value: _tooltipPosition,
          values: TooltipPosition.values,
          onChanged: (value) => setState(() => _tooltipPosition = value),
        ),
        BoolOption(
          label: 'Follow pointer',
          value: _tooltipFollowCursor,
          onChanged: (value) => setState(() => _tooltipFollowCursor = value),
        ),
        SliderOption(
          label: 'Tooltip offset',
          value: _tooltipOffset,
          min: 0,
          max: 32,
          divisions: 32,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _tooltipOffset = value),
        ),
        PaletteColorOption(
          label: 'Tooltip background',
          value: _tooltipBackgroundColor,
          keyPrefix: 'radar-tooltip-background-color',
          customColorFallback:
              _effectiveTheme.interactionTheme.tooltipStyle.backgroundColor,
          onChanged: (value) => setState(() => _tooltipBackgroundColor = value),
        ),
        PaletteColorOption(
          label: 'Tooltip border',
          value: _tooltipBorderColor,
          keyPrefix: 'radar-tooltip-border-color',
          customColorFallback:
              _effectiveTheme.interactionTheme.tooltipStyle.borderColor,
          onChanged: (value) => setState(() => _tooltipBorderColor = value),
        ),
        PaletteColorOption(
          label: 'Tooltip text',
          value: _tooltipTextColor,
          keyPrefix: 'radar-tooltip-text-color',
          customColorFallback:
              _effectiveTheme.interactionTheme.tooltipStyle.textStyle.color ??
              Colors.black,
          onChanged: (value) => setState(() => _tooltipTextColor = value),
        ),
        PaletteColorOption(
          label: 'Tooltip shadow',
          value: _tooltipShadowColor,
          keyPrefix: 'radar-tooltip-shadow-color',
          customColorFallback: Colors.black,
          onChanged: (value) => setState(() => _tooltipShadowColor = value),
        ),
        SliderOption(
          label: 'Tooltip border width',
          value: _tooltipBorderWidth,
          min: 0,
          max: 4,
          divisions: 16,
          suffix: ' px',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _tooltipBorderWidth = value),
        ),
        SliderOption(
          label: 'Tooltip corner radius',
          value: _tooltipBorderRadius,
          min: 0,
          max: 20,
          divisions: 20,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _tooltipBorderRadius = value),
        ),
        SliderOption(
          label: 'Tooltip shadow blur',
          value: _tooltipShadowBlur,
          min: 0,
          max: 24,
          divisions: 24,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _tooltipShadowBlur = value),
        ),
        SliderOption(
          label: 'Tooltip padding',
          value: _tooltipPadding,
          min: 0,
          max: 24,
          divisions: 24,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _tooltipPadding = value),
        ),
        SliderOption(
          label: 'Tooltip font size',
          value: _tooltipFontSize,
          min: 9,
          max: 20,
          divisions: 22,
          suffix: ' px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _tooltipFontSize = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Selection',
      icon: Icons.touch_app_outlined,
      description:
          'Chooses whether a gesture links one vertex, a spoke, or a complete profile.',
      children: [
        EnumOption<ChartSelectionScope>(
          label: 'Selection scope',
          value: _selectionScope,
          values: const [
            ChartSelectionScope.mark,
            ChartSelectionScope.category,
            ChartSelectionScope.wholeSeries,
            ChartSelectionScope.markOrWholeSeries,
          ],
          labelBuilder: (scope) => switch (scope) {
            ChartSelectionScope.mark => 'One vertex',
            ChartSelectionScope.category => 'Shared category spoke',
            ChartSelectionScope.wholeSeries => 'Complete profile',
            ChartSelectionScope.markOrWholeSeries => 'Vertex or profile',
            ChartSelectionScope.categoryStack => 'Category stack',
          },
          onChanged: (value) {
            _chartController.clearPointSelection();
            setState(() => _selectionScope = value);
          },
        ),
        BoolOption(
          label: 'Clear on background tap',
          value: _clearSelectionOnBackgroundTap,
          onChanged: (value) =>
              setState(() => _clearSelectionOnBackgroundTap = value),
        ),
        SliderOption(
          label: 'Vertex hit radius',
          value: _selectionHitRadius,
          min: 4,
          max: 48,
          divisions: 44,
          suffix: ' px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _selectionHitRadius = value),
        ),
        SliderOption(
          label: 'Hover scale',
          value: _selectionHoverScale,
          min: 1,
          max: 3,
          divisions: 20,
          suffix: '×',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _selectionHoverScale = value),
        ),
        SliderOption(
          label: 'Selected scale',
          value: _selectionScale,
          min: 1,
          max: 4,
          divisions: 30,
          suffix: '×',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _selectionScale = value),
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
      title: 'Theme and accessibility',
      icon: Icons.contrast_outlined,
      description: 'Changes the complete chart palette without losing data.',
      children: [
        EnumOption<_RadarThemePreset>(
          label: 'Chart theme',
          value: _themePreset,
          values: _RadarThemePreset.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _themePreset = value),
        ),
      ],
    ),
  ];

  String _fontWeightLabel(FontWeight value) => switch (value) {
    FontWeight.w400 => 'Regular',
    FontWeight.w600 => 'Semi-bold',
    FontWeight.w700 => 'Bold',
    _ => value.toString(),
  };

  void _applyPresentation(_RadarPresentation presentation) {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _presentation = presentation;
      _restoreAppearanceDefaults();
      switch (presentation) {
        case _RadarPresentation.budget:
          break;
        case _RadarPresentation.capability:
          _gridShape = RadarGridShape.circle;
          _ringColor = const Color(0xFFCBD5E1);
          _spokeColor = const Color(0xFFE2E8F0);
          _boundaryColor = const Color(0xFF64748B);
          _ringWidth = 0.75;
          _spokeWidth = 0.5;
          _boundaryWidth = 2;
          _fillOpacity = 0.09;
          _markerShape = SeriesMarkerShape.diamond;
          _markerRadius = 4;
          _categoryLabelColor = const Color(0xFF334155);
          _radialLabelPosition = PolarRadialLabelPosition.middle;
        case _RadarPresentation.comparison:
          _gridShape = RadarGridShape.circle;
          _ringColor = const Color(0xFFBFDBFE);
          _spokeColor = const Color(0xFFFED7AA);
          _boundaryColor = const Color(0xFF1D4ED8);
          _ringPattern = _RadarLinePattern.dashed;
          _spokePattern = _RadarLinePattern.dotted;
          _ringWidth = 1.25;
          _boundaryWidth = 2.5;
          _fillOpacity = 0.06;
          _strokeWidth = 3;
          _categoryLabelColor = const Color(0xFF1E3A8A);
          _radialLabelColor = const Color(0xFF9A3412);
        case _RadarPresentation.scorecard:
          _ringColor = const Color(0xFF6EE7B7);
          _spokeColor = const Color(0xFF94A3B8);
          _boundaryColor = const Color(0xFF047857);
          _ringPattern = _RadarLinePattern.dashed;
          _spokePattern = _RadarLinePattern.dotted;
          _gradientEnabled = true;
          _fillOpacity = 0.22;
          _legendPosition = LegendPosition.bottomCenter;
          _tooltipPosition = TooltipPosition.right;
        case _RadarPresentation.highContrast:
          _themePreset = _RadarThemePreset.highContrast;
          _fillOpacity = 0.04;
          _strokeWidth = 4;
          _markerRadius = 5;
          _categoryLabelFontSize = 14;
          _categoryLabelWeight = FontWeight.w700;
          _radialLabelWeight = FontWeight.w700;
          _ringWidth = 1.5;
          _spokeWidth = 1.5;
          _boundaryWidth = 3;
          _tooltipBorderWidth = 2;
          _tooltipFontSize = 14;
        case _RadarPresentation.service:
          _ringColor = const Color(0xFFBAE6FD);
          _spokeColor = const Color(0xFFCFFAFE);
          _boundaryColor = const Color(0xFF0E7490);
          _categoryLabelColor = const Color(0xFF155E75);
          _dataLabelColor = const Color(0xFF9F1239);
          _showDataLabels = true;
          _maximumDataLabels = 12;
          _dataLabelOffset = 10;
          _fillOpacity = 0.08;
          _selectionScope = ChartSelectionScope.mark;
          _markerRadius = 5;
          _selectionHitRadius = 28;
          _tooltipTriggerMode = TooltipTriggerMode.hover;
        case _RadarPresentation.compact:
          _gridShape = RadarGridShape.circle;
          _tickCount = 4;
          _outerRadiusFactor = 0.72;
          _showLegend = false;
          _showRadialLabels = false;
          _showDataLabels = true;
          _maximumDataLabels = 5;
          _dataLabelOffset = -10;
          _markerRadius = 5;
          _fillOpacity = 0.18;
          _tooltipTriggerMode = TooltipTriggerMode.both;
          _selectionHitRadius = 28;
        case _RadarPresentation.risk:
          _gridShape = RadarGridShape.circle;
          _ringPattern = _RadarLinePattern.dashed;
          _spokePattern = _RadarLinePattern.dotted;
          _boundaryColor = const Color(0xFF9F1239);
          _boundaryWidth = 2.5;
          _gradientEnabled = true;
          _gradientType = RadarGradientType.radial;
          _shadowEnabled = true;
          _shadowBlur = 10;
          _fillOpacity = 0.13;
          _legendPosition = LegendPosition.bottomCenter;
        case _RadarPresentation.longLabels:
          _gridShape = RadarGridShape.polygon;
          _outerRadiusFactor = 0.67;
          _maximumCategoryLabels = 7;
          _categoryLabelOffset = 14;
          _categoryLabelFontSize = 13;
          _categoryLabelWeight = FontWeight.w600;
          _showRadialLabels = false;
          _showLegend = false;
          _fillOpacity = 0.08;
          _previewTextScale = 1.6;
        case _RadarPresentation.dense:
          _gridShape = RadarGridShape.circle;
          _ringColor = const Color(0xFFD8B4FE);
          _spokeColor = const Color(0xFFE9D5FF);
          _boundaryColor = const Color(0xFF7E22CE);
          _ringWidth = 0.5;
          _spokeWidth = 0.5;
          _maximumCategoryLabels = 12;
          _showMarkers = false;
          _fillOpacity = 0.04;
          _strokeWidth = 1.6;
          _categoryLabelFontSize = 10;
          _tooltipFollowCursor = true;
          _selectionScope = ChartSelectionScope.wholeSeries;
        case _RadarPresentation.playground:
          _gradientEnabled = true;
          _gradientType = RadarGradientType.linear;
          _gradientAngle = -35;
          _shadowEnabled = true;
          _shadowBlur = 12;
          _markerShape = SeriesMarkerShape.star;
          _markerBorderColor = Colors.white;
          _markerBorderWidth = 1.5;
          _shadowSpread = 1.5;
          _shadowOffsetY = 4;
          _fillOpacity = 0.18;
          _ringPattern = _RadarLinePattern.dotted;
          _boundaryWidth = 2.5;
          _tooltipTriggerMode = TooltipTriggerMode.both;
          _tooltipPosition = TooltipPosition.top;
          _selectionScope = ChartSelectionScope.markOrWholeSeries;
      }
      _valueRevision = 0;
    });
    if (presentation == _RadarPresentation.playground) {
      _showcaseRandomizer.generateCurrent();
    } else {
      _showcaseRandomizer.pause();
    }
  }

  void _applyRandomSeed(int seed) {
    final random = math.Random(seed);
    T pick<T>(List<T> values) => values[random.nextInt(values.length)];
    double between(double minimum, double maximum) =>
        minimum + random.nextDouble() * (maximum - minimum);
    double stepped(double minimum, double maximum, double step) =>
        (between(minimum, maximum) / step).round() * step;

    const vivid = <Color>[
      Color(0xFF2563EB),
      Color(0xFF0891B2),
      Color(0xFF0D9488),
      Color(0xFF16A34A),
      Color(0xFFF59E0B),
      Color(0xFFF97316),
      Color(0xFFDC2626),
      Color(0xFF9333EA),
      Color(0xFFDB2777),
    ];
    const lightLines = <Color>[
      Color(0xFFCBD5E1),
      Color(0xFF94A3B8),
      Color(0xFF60A5FA),
      Color(0xFF67E8F9),
      Color(0xFF6EE7B7),
      Color(0xFFFDE68A),
      Color(0xFFFCA5A5),
      Color(0xFFD8B4FE),
    ];
    const darkLines = <Color>[
      Color(0xFF334155),
      Color(0xFF475569),
      Color(0xFF1D4ED8),
      Color(0xFF0E7490),
      Color(0xFF047857),
      Color(0xFFB45309),
      Color(0xFFB91C1C),
      Color(0xFF7E22CE),
    ];
    Color? configuredColor(List<Color> values) =>
        random.nextInt(5) == 0 ? null : pick(values);

    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _restoreAppearanceDefaults();
      _presentation = _RadarPresentation.playground;
      _playgroundSeed = seed;
      _playgroundCategoryCount = 5 + random.nextInt(14);
      _playgroundProfileCount = 2 + random.nextInt(5);
      final shuffledColors = List<Color>.of(vivid)..shuffle(random);
      _playgroundColors = shuffledColors
          .take(_playgroundProfileCount)
          .toList(growable: false);

      _themePreset = pick(_RadarThemePreset.values);
      final darkCanvas = _themePreset == _RadarThemePreset.dark;
      final labelColors = darkCanvas ? lightLines : darkLines;
      _gridShape = pick(RadarGridShape.values);
      _startAngleDegrees = stepped(-180, 180, 15);
      _clockwise = random.nextBool();
      _outerRadiusFactor = stepped(0.58, 0.92, 0.02);
      _tickCount = 3 + random.nextInt(7);
      _showRings = random.nextInt(6) != 0;
      _showSpokes = random.nextInt(6) != 0;
      if (!_showRings && !_showSpokes) _showRings = true;
      _ringColor = configuredColor(lightLines);
      _spokeColor = configuredColor(lightLines);
      _boundaryColor = configuredColor(darkLines);
      _ringWidth = stepped(0.25, 3.5, 0.25);
      _spokeWidth = stepped(0.25, 3, 0.25);
      _boundaryWidth = stepped(0.5, 5, 0.25);
      _ringPattern = pick(_RadarLinePattern.values);
      _spokePattern = pick(_RadarLinePattern.values);
      _boundaryPattern = pick(_RadarLinePattern.values);

      _strokeWidth = stepped(1, 6, 0.25);
      _strokeOpacity = stepped(0.45, 1, 0.05);
      _strokePattern = pick(_RadarLinePattern.values);
      _fillOpacity = stepped(0.02, 0.34, 0.02);
      _profileFillColor = random.nextInt(4) == 0 ? pick(vivid) : null;
      _gradientEnabled = random.nextInt(4) != 0;
      _gradientType = pick(RadarGradientType.values);
      _gradientStartColor = configuredColor(vivid);
      _gradientEndColor = configuredColor(vivid);
      _gradientStartLightnessShift = stepped(-0.35, 0.6, 0.05);
      _gradientEndLightnessShift = stepped(-0.6, 0.35, 0.05);
      _gradientAngle = stepped(-180, 180, 15);
      _shadowEnabled = random.nextBool();
      _shadowColor = configuredColor(darkLines);
      _shadowBlur = stepped(0, 24, 1);
      _shadowSpread = stepped(0, 6, 0.5);
      _shadowOffsetX = stepped(-8, 8, 1);
      _shadowOffsetY = stepped(-8, 8, 1);
      _shadowOpacity = stepped(0.1, 0.65, 0.05);

      _showMarkers = random.nextInt(5) != 0;
      _markerShape = pick(SeriesMarkerShape.values);
      _markerRadius = stepped(1.5, 8, 0.5);
      _markerFillColor = configuredColor(vivid);
      _markerBorderColor = configuredColor(labelColors);
      _markerBorderWidth = stepped(0, 4, 0.5);
      _showDataLabels = random.nextBool();
      _maximumDataLabels = 6 + random.nextInt(37);
      _dataLabelOffset = stepped(-12, 28, 2);
      _dataLabelColor = configuredColor(labelColors);
      _dataLabelFontSize = stepped(8, 18, 1);
      _dataLabelWeight = pick(const <FontWeight>[
        FontWeight.w400,
        FontWeight.w600,
        FontWeight.w700,
      ]);

      _showCategoryLabels = random.nextInt(8) != 0;
      _maximumCategoryLabels = 5 + random.nextInt(24);
      _categoryLabelOffset = stepped(-4, 28, 2);
      _categoryLabelColor = configuredColor(labelColors);
      _categoryLabelFontSize = stepped(9, 18, 1);
      _categoryLabelWeight = pick(const <FontWeight>[
        FontWeight.w400,
        FontWeight.w600,
        FontWeight.w700,
      ]);
      _showRadialLabels = random.nextInt(6) != 0;
      _radialLabelPosition = pick(PolarRadialLabelPosition.values);
      _radialLabelAngle = stepped(-180, 180, 15);
      _radialLabelOffset = stepped(-8, 18, 2);
      _radialLabelColor = configuredColor(labelColors);
      _radialLabelFontSize = stepped(8, 16, 1);
      _radialLabelWeight = pick(const <FontWeight>[
        FontWeight.w400,
        FontWeight.w600,
        FontWeight.w700,
      ]);

      _showLegend = random.nextInt(6) != 0;
      _legendPosition = pick(LegendPosition.values);
      _legendOrientation = pick(LegendOrientation.values);
      _legendMarkerShape = pick(LegendMarkerShape.values);
      _legendBackgroundColor = configuredColor(
        darkCanvas ? darkLines : lightLines,
      );
      _legendBorderColor = configuredColor(labelColors);
      _legendTextColor = configuredColor(labelColors);
      _legendBorderWidth = stepped(0, 3, 0.5);
      _legendOpacity = stepped(0.45, 1, 0.05);

      _tooltipEnabled = random.nextInt(8) != 0;
      _tooltipTriggerMode = pick(TooltipTriggerMode.values);
      _tooltipPosition = pick(TooltipPosition.values);
      _tooltipFollowCursor = random.nextBool();
      _tooltipOffset = stepped(0, 24, 2);
      _tooltipBackgroundColor = pick(darkCanvas ? darkLines : lightLines);
      _tooltipBorderColor = pick(labelColors);
      _tooltipTextColor = pick(darkCanvas ? lightLines : darkLines);
      _tooltipBorderWidth = stepped(0, 3, 0.5);
      _tooltipBorderRadius = stepped(0, 18, 2);
      _tooltipShadowColor = configuredColor(darkLines);
      _tooltipShadowBlur = stepped(0, 20, 2);
      _tooltipPadding = stepped(2, 18, 2);
      _tooltipFontSize = stepped(9, 16, 1);

      _selectionScope = pick(ChartSelectionScope.values);
      _clearSelectionOnBackgroundTap = random.nextBool();
      _selectionHitRadius = stepped(8, 36, 2);
      _selectionHoverScale = stepped(1, 2.4, 0.1);
      _selectionScale = stepped(1, 3.5, 0.1);
      _animationMode = pick(RadarAnimationMode.values);
      _previewReducedMotion = false;
      _previewTextScale = 1;
      _valueRevision = 0;
    });
  }

  void _resetExample() {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _presentation = _RadarPresentation.budget;
      _restoreAppearanceDefaults();
      _valueRevision = 0;
    });
    _showcaseRandomizer
      ..pause()
      ..clear();
  }

  void _restoreAppearanceDefaults() {
    _gridShape = RadarGridShape.polygon;
    _startAngleDegrees = -90;
    _clockwise = true;
    _outerRadiusFactor = 0.78;
    _tickCount = 5;
    _showRings = true;
    _showSpokes = true;
    _ringColor = null;
    _spokeColor = null;
    _boundaryColor = null;
    _ringWidth = 1;
    _spokeWidth = 1;
    _boundaryWidth = 1.5;
    _ringPattern = _RadarLinePattern.solid;
    _spokePattern = _RadarLinePattern.solid;
    _boundaryPattern = _RadarLinePattern.solid;
    _strokeWidth = 2.5;
    _strokeOpacity = 1;
    _strokePattern = _RadarLinePattern.solid;
    _fillOpacity = 0.12;
    _profileFillColor = null;
    _gradientEnabled = false;
    _gradientType = RadarGradientType.radial;
    _gradientStartColor = null;
    _gradientEndColor = null;
    _gradientStartLightnessShift = 0.2;
    _gradientEndLightnessShift = -0.14;
    _gradientAngle = 0;
    _shadowEnabled = false;
    _shadowColor = null;
    _shadowBlur = 10;
    _shadowSpread = 1;
    _shadowOffsetX = 0;
    _shadowOffsetY = 3;
    _shadowOpacity = 0.25;
    _showMarkers = true;
    _markerShape = SeriesMarkerShape.circle;
    _markerRadius = 3.5;
    _markerFillColor = null;
    _markerBorderColor = null;
    _markerBorderWidth = 0;
    _showDataLabels = false;
    _maximumDataLabels = 24;
    _dataLabelOffset = 8;
    _dataLabelColor = null;
    _dataLabelFontSize = 11;
    _dataLabelWeight = FontWeight.w600;
    _showCategoryLabels = true;
    _maximumCategoryLabels = 18;
    _categoryLabelOffset = 10;
    _categoryLabelColor = null;
    _categoryLabelFontSize = 12;
    _categoryLabelWeight = FontWeight.normal;
    _showRadialLabels = true;
    _radialLabelPosition = PolarRadialLabelPosition.start;
    _radialLabelAngle = 0;
    _radialLabelOffset = 4;
    _radialLabelColor = null;
    _radialLabelFontSize = 10;
    _radialLabelWeight = FontWeight.normal;
    _showLegend = true;
    _legendPosition = LegendPosition.topRight;
    _legendOrientation = LegendOrientation.horizontal;
    _legendMarkerShape = LegendMarkerShape.line;
    _legendBackgroundColor = null;
    _legendBorderColor = null;
    _legendTextColor = null;
    _legendBorderWidth = 0;
    _legendOpacity = 1;
    _tooltipEnabled = true;
    _tooltipTriggerMode = TooltipTriggerMode.hover;
    _tooltipPosition = TooltipPosition.auto;
    _tooltipFollowCursor = false;
    _tooltipOffset = 8;
    _tooltipBackgroundColor = null;
    _tooltipBorderColor = null;
    _tooltipTextColor = null;
    _tooltipBorderWidth = 1;
    _tooltipBorderRadius = 6;
    _tooltipShadowColor = null;
    _tooltipShadowBlur = 4;
    _tooltipPadding = 8;
    _tooltipFontSize = 12;
    _selectionScope = ChartSelectionScope.category;
    _clearSelectionOnBackgroundTap = true;
    _selectionHitRadius = 20;
    _selectionHoverScale = 1.5;
    _selectionScale = 2.67;
    _themePreset = _RadarThemePreset.light;
    _animationMode = RadarAnimationMode.radial;
    _previewReducedMotion = false;
    _previewTextScale = 1;
  }

  void _updateValues() {
    if (_presentation == _RadarPresentation.playground) {
      _showcaseRandomizer.generateNext();
      return;
    }
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() => _valueRevision++);
  }

  String get _chartTitle => switch (_presentation) {
    _RadarPresentation.budget => 'Budget vs spending',
    _RadarPresentation.capability => 'Team capability profile',
    _RadarPresentation.comparison => 'Product comparison',
    _RadarPresentation.scorecard => 'Normalized operating scorecard',
    _RadarPresentation.highContrast => 'High-contrast delivery profile',
    _RadarPresentation.service => 'Service health profile',
    _RadarPresentation.compact => 'Daily readiness snapshot',
    _RadarPresentation.risk => 'Enterprise risk exposure',
    _RadarPresentation.longLabels => 'Long-label governance review',
    _RadarPresentation.dense => 'Dense metric stress test',
    _RadarPresentation.playground => 'Generated Radar playground',
  };

  String get _presentationDescription => switch (_presentation) {
    _RadarPresentation.budget =>
      'Compare two related profiles across the same six departmental dimensions.',
    _RadarPresentation.capability =>
      'A circular web compares three teams without implying a part-to-whole total.',
    _RadarPresentation.comparison =>
      'Compare competing products while dashed profiles preserve identity without color alone.',
    _RadarPresentation.scorecard =>
      'Discloses normalization and keeps an exact target baseline visible in Data view.',
    _RadarPresentation.highContrast =>
      'Tests large text, stronger boundaries, marker emphasis, and minimal translucent fill.',
    _RadarPresentation.service =>
      'Eight operational dimensions exercise denser labels and optional point values.',
    _RadarPresentation.compact =>
      'A five-axis, single-profile snapshot removes secondary chrome and enlarges touch affordances.',
    _RadarPresentation.risk =>
      'Gradients, shadows, patterns, and a reference profile prove styling does not change the shared scale.',
    _RadarPresentation.longLabels =>
      'Long category names verify bounded labels, pane reservation, and Data-view preservation.',
    _RadarPresentation.dense =>
      'Twenty categories prove deterministic label thinning while Data retains every value.',
    _RadarPresentation.playground =>
      'Update values advances one deterministic seed while every appearance property stays editable.',
  };
}

enum _RadarMobileExample { snapshot, touchComparison, largeText }

class _RadarMobileExampleCard extends StatelessWidget {
  const _RadarMobileExampleCard({required this.example, required this.onOpen});

  final _RadarMobileExample example;
  final VoidCallback onOpen;

  String get _title => switch (example) {
    _RadarMobileExample.snapshot => 'One-glance readiness',
    _RadarMobileExample.touchComparison => 'Long-press comparison',
    _RadarMobileExample.largeText => 'Large-text fallback',
  };

  String get _summary => switch (example) {
    _RadarMobileExample.snapshot =>
      'One profile, five dimensions, and no legend compete for attention.',
    _RadarMobileExample.touchComparison =>
      'Large markers and long-press details preserve normal page scrolling.',
    _RadarMobileExample.largeText =>
      'Label thinning protects the pane while every category remains in Data.',
  };

  IconData get _icon => switch (example) {
    _RadarMobileExample.snapshot => Icons.phone_android_outlined,
    _RadarMobileExample.touchComparison => Icons.touch_app_outlined,
    _RadarMobileExample.largeText => Icons.text_increase_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('radar-mobile-example-${example.name}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: Text(
                _summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: ValueKey('radar-mobile-open-${example.name}'),
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in workbench'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
