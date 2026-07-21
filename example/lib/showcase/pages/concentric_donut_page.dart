// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../data/radial_demo_data.dart';
import '../widgets/options_panel.dart';
import '../widgets/radial_option_order.dart';
import '../widgets/radial_legend_value_card.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

/// First public review surface for independent multi-ring Donut composition.
class ConcentricDonutPage extends StatefulWidget {
  const ConcentricDonutPage({super.key});

  @override
  State<ConcentricDonutPage> createState() => _ConcentricDonutPageState();
}

class _ConcentricDonutPageState extends State<ConcentricDonutPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final BravenChartController _restoredController = BravenChartController();
  final math.Random _random = math.Random();
  late final ShowcaseRandomizerController<int> _showcaseRandomizer;

  _ConcentricShowcasePreset _showcasePreset =
      _ConcentricShowcasePreset.comparison;
  _ConcentricShowcasePreset _authoredPreset =
      _ConcentricShowcasePreset.comparison;
  bool _playgroundActive = false;
  double _innerRadiusFactor = 0.28;
  double _outerRadiusFactor = 0.94;
  double _ringGap = 6;
  final Map<String, double> _ringWeights = {
    'current': 1.25,
    'previous': 1,
    'forecast': 1,
    'plan': 1,
    'baseline': 1,
    'target': 1,
  };
  double _sweepAngleDegrees = 360;
  double _startAngleDegrees = -90;
  double _sliceGap = 2;
  double _borderWidth = 1;
  _ConcentricBorderPreset _borderPreset = _ConcentricBorderPreset.darkerSlice;
  Color _fixedBorderColor = const Color(0xFF334155);
  double _cornerRadius = 5;
  double _selectionExplodeOffset = 5;
  RadialSelectionEffect _selectionEffect = RadialSelectionEffect.lift;
  double _selectionLiftScale = 1.1;
  double _selectionLiftOffset = 6;
  double _selectionBackdropBlur = 1.25;
  double _sliceOpacity = 1;
  _ConcentricGradientPreset _gradientPreset = _ConcentricGradientPreset.radial;
  bool _useFixedGradientColors = false;
  Color _gradientStartColor = const Color(0xFF67E8F9);
  Color _gradientEndColor = const Color(0xFF1D4ED8);
  double _gradientStartLightnessShift = 0.16;
  double _gradientEndLightnessShift = -0.12;
  double _gradientAngleDegrees = -45;
  bool _showShadow = false;
  bool _showSelectedGlow = true;
  _ConcentricGlowColor _selectedGlowColor = _ConcentricGlowColor.slice;
  double _selectedGlowBlur = 12;
  double _selectedGlowSpread = 2;
  double _selectedGlowOpacity = 0.48;
  double _selectedGlowOffsetY = 0;
  bool _clockwise = true;
  PieCornerTreatment _cornerTreatment = PieCornerTreatment.roundAll;
  PieAnimationMode _animationMode = PieAnimationMode.sweep;
  RadialDataTransitionMode _dataTransitionMode =
      RadialDataTransitionMode.automatic;
  ConcentricRingOrder _order = ConcentricRingOrder.outerToInner;
  ConcentricDonutLegendMode _legendMode =
      ConcentricDonutLegendMode.groupedByRing;
  bool _showLabels = true;
  _ConcentricLabelLayout _labelLayout = _ConcentricLabelLayout.hierarchy;
  PieDataLabelPosition _labelPosition = PieDataLabelPosition.inside;
  PieDataLabelContent _labelContent = PieDataLabelContent.percentage;
  PieDataLabelCollisionStrategy _labelCollisionStrategy =
      PieDataLabelCollisionStrategy.shiftAndHide;
  double _labelMinimumShare = 0.03;
  double _labelMinimumSweepDegrees = 8;
  double _labelPadding = 6;
  double _insideLabelOffset = 0;
  double _outsideLabelOffset = 0;
  double _connectorLength = 14;
  double _connectorWidth = 1;
  bool _useCustomConnectorColor = false;
  Color _connectorColor = const Color(0xFF475569);
  _ConcentricCalloutPreset _calloutPreset = _ConcentricCalloutPreset.surface;
  _ConcentricInsideShareStyle _insideShareStyle =
      _ConcentricInsideShareStyle.darkBadge;
  bool _showLegend = true;
  _ConcentricLegendPreset _legendPreset = _ConcentricLegendPreset.compact;
  _ConcentricLegendContent _legendContent = _ConcentricLegendContent.standard;
  LegendPosition _legendPosition = LegendPosition.bottomCenter;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.circle;
  double _legendMarkerSize = 10;
  double _legendFontSize = 10;
  double _legendOpacity = 1;
  bool _showTooltips = true;
  _ConcentricTooltipPreset _tooltipPreset = _ConcentricTooltipPreset.elevated;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowsCursor = false;
  double _tooltipOffset = 8;
  _ConcentricThemePreset _themePreset = _ConcentricThemePreset.light;
  _ConcentricPalette _palette = _ConcentricPalette.ocean;
  bool _showCenter = true;
  bool _useRuntimeCenter = true;
  DonutCenterValueMode _centerValueMode = DonutCenterValueMode.selectedOrTotal;
  String _centerLabel = '';
  String _centerCustomValue = '2 periods';
  double _centerLabelFontSize = 11;
  double _centerValueFontSize = 22;
  FontWeight _centerLabelFontWeight = FontWeight.w500;
  FontWeight _centerValueFontWeight = FontWeight.w700;
  bool _useChartThemeCenterColors = true;
  Color _centerLabelColor = const Color(0xFFCBD5E1);
  Color _centerValueColor = const Color(0xFFF8FAFC);
  _ConcentricCenterSurface _centerSurface =
      _ConcentricCenterSurface.transparent;
  bool _groupSmallCategories = true;
  double _groupingMinimumShare = 0.1;
  ChartDisplayMode _displayMode = ChartDisplayMode.split;
  String? _selectedSummary;
  ChartArtifact? _capturedArtifact;
  HydratedChartConfiguration? _restoredConfiguration;
  String? _capturedJson;
  String? _artifactMessage;
  bool _isCapturing = false;
  int _categoryCount = 5;
  int _ringCount = 2;

  static const _oceanSliceColors = <String, Color>{
    'Subscriptions': Color(0xFF2563EB),
    'Services': Color(0xFF0D9488),
    'Enterprise': Color(0xFFF59E0B),
    'Training': Color(0xFF7C3AED),
    'Support': Color(0xFF64748B),
  };

  static const _colorChoices = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
    Color(0xFFEF4444),
    Color(0xFF334155),
    Color(0xFFF8FAFC),
  ];

  static const _baseCurrentValues = <String, num>{
    'Subscriptions': 45,
    'Services': 30,
    'Enterprise': 15,
    'Training': 6,
    'Support': 4,
  };

  static const _basePreviousValues = <String, num>{
    'Subscriptions': 60,
    'Services': 70,
    'Enterprise': 50,
    'Training': 12,
    'Support': 8,
  };

  static const _baseForecastValues = <String, num>{
    'Subscriptions': 90,
    'Services': 80,
    'Enterprise': 70,
    'Training': 36,
    'Support': 24,
  };

  static const _ringDescriptors = <_ConcentricRingDescriptor>[
    _ConcentricRingDescriptor(
      id: 'current',
      name: 'Current period',
      generatedTotal: 100,
    ),
    _ConcentricRingDescriptor(
      id: 'previous',
      name: 'Previous period',
      generatedTotal: 200,
    ),
    _ConcentricRingDescriptor(
      id: 'forecast',
      name: 'Forecast period',
      generatedTotal: 300,
    ),
    _ConcentricRingDescriptor(
      id: 'plan',
      name: 'Plan period',
      generatedTotal: 400,
    ),
    _ConcentricRingDescriptor(
      id: 'baseline',
      name: 'Baseline period',
      generatedTotal: 500,
    ),
    _ConcentricRingDescriptor(
      id: 'target',
      name: 'Target period',
      generatedTotal: 600,
    ),
  ];

  static const _compactCurrentValues = <String, num>{
    'Subscriptions': 2.1003057687312516,
    'Services': 10.174866679789481,
    'Enterprise': 18.900722496403024,
    'Training': 29.04229774545904,
    'Support': 8.879737207130427,
    'Analytics': 3.7440403282201826,
    'Integrations': 27.158029774266595,
  };

  static const _compactPreviousValues = <String, num>{
    'Subscriptions': 35.38110724006537,
    'Services': 37.475410358254884,
    'Enterprise': 16.848117707993246,
    'Training': 24.053069677188876,
    'Support': 23.484604667790432,
    'Analytics': 46.304313668802855,
    'Integrations': 16.453376679904352,
  };

  static const _elevatedCurrentValues = <String, num>{
    'Subscriptions': 19.05387372764938,
    'Services': 2.1825014427349614,
    'Enterprise': 2.843202175093259,
    'Training': 12.522433120729959,
    'Support': 0.4391245911747618,
    'Analytics': 10.67415082878745,
    'Integrations': 14.125337101318364,
    'Consulting': 12.802344186918882,
    'Marketplace': 20.354578075178033,
    'Storage': 5.002454750414955,
  };

  static const _elevatedPreviousValues = <String, num>{
    'Subscriptions': 57.902067509084496,
    'Services': 26.803072722142396,
    'Enterprise': 7.010259915540149,
    'Training': 7.322416023511789,
    'Support': 7.335267283792226,
    'Analytics': 27.647908021492693,
    'Integrations': 29.2101962847596,
    'Consulting': 5.08061233727336,
    'Marketplace': 13.091333849004572,
    'Storage': 18.59686605339874,
  };

  static const _highContrastCurrentValues = <String, num>{
    'Subscriptions': 2.9299878623846847,
    'Services': 3.3231662201015584,
    'Enterprise': 11.516645869356609,
    'Training': 12.214459531127103,
    'Support': 20.885276994518527,
    'Analytics': 3.0963227197881693,
    'Integrations': 13.468165395321275,
    'Consulting': 15.109796979410444,
    'Marketplace': 0.9286434299171611,
    'Storage': 16.527534998074472,
  };

  static const _highContrastPreviousValues = <String, num>{
    'Subscriptions': 32.78483949737364,
    'Services': 21.81597367483022,
    'Enterprise': 27.987188696333433,
    'Training': 31.11579472021379,
    'Support': 21.16458186019966,
    'Analytics': 31.51415239808732,
    'Integrations': 7.460035810557016,
    'Consulting': 5.494188839139545,
    'Marketplace': 9.523272012296621,
    'Storage': 11.139972490968745,
  };

  static const _categoryLabels = <String>[
    'Subscriptions',
    'Services',
    'Enterprise',
    'Training',
    'Support',
    'Analytics',
    'Integrations',
    'Consulting',
    'Marketplace',
    'Storage',
    'Automation',
    'Security',
    'Data export',
    'Mobile',
    'API usage',
    'Onboarding',
    'Premium support',
    'Compliance',
    'Partners',
    'Other services',
  ];

  late Map<String, num> _currentValues;
  late Map<String, num> _previousValues;
  final Map<String, Map<String, num>> _additionalRingValues = {};

  @override
  void initState() {
    super.initState();
    _showcaseRandomizer = ShowcaseRandomizerController<int>(
      initialSeed: 503,
      generate: (seed) => seed,
      apply: _applyRandomSeed,
    );
    _currentValues = Map<String, num>.of(_baseCurrentValues);
    _previousValues = Map<String, num>.of(_basePreviousValues);
    final labels = radialDemoLabels(
      preferredLabels: _categoryLabels,
      count: _categoryCount,
    );
    for (final ring in _ringDescriptors.skip(2)) {
      _additionalRingValues[ring.id] = randomRadialDistribution(
        labels: labels,
        total: ring.generatedTotal,
        random: _random,
      );
    }
    _applyComparisonPresentation();
  }

  @override
  void dispose() {
    _showcaseRandomizer.dispose();
    _workbenchController.dispose();
    _restoredController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Concentric Donut',
      subtitle:
          'Compare several independent part-to-whole distributions in one shared radial pane',
      optionsChildren: _buildOptions(),
      playground: ChartPlaygroundConfig(
        active: _playgroundActive,
        optionsChildren: _buildPlaygroundOptions(),
        randomizer: _showcaseRandomizer,
      ),
      randomizerKeyPrefix: 'concentric-randomizer',
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return SingleChildScrollView(
          key: const ValueKey('concentric-donut-showcase-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresentationHeader(),
              const SizedBox(height: 8),
              _buildPresentationSelector(),
              const SizedBox(height: 12),
              _buildRingCountSelector(),
              const SizedBox(height: 16),
              _buildMeaningCard(compact: compact),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildChartHeader(compact: compact),
                      const SizedBox(height: 8),
                      _buildDisplayModeSelector(),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: compact ? 720 : 640,
                        child: _buildDataSurface(compact: compact),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildPortabilityCard(compact: compact),
              const SizedBox(height: 24),
              _buildApiCard(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresentationHeader() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a presentation',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Apply a complete multi-ring configuration, then refine every detail in Options.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPresentationSelector() {
    return ShowcaseExampleGrid(
      key: const ValueKey('concentric-presentation-selector'),
      children: [
        for (final preset in _ConcentricShowcasePreset.values)
          _presentationCard(preset),
        PlaygroundExampleCard(
          key: const ValueKey('concentric-playground'),
          selected: _playgroundActive,
          onTap: () => _setPlaygroundActive(true),
        ),
      ],
    );
  }

  Widget _presentationCard(_ConcentricShowcasePreset preset) {
    final selected = !_playgroundActive && preset == _showcasePreset;
    return ShowcaseExampleCard(
      key: ValueKey('concentric-preset-${preset.name}'),
      title: _presentationName(preset),
      description: _presentationDescription(preset),
      icon: _presentationIcon(preset),
      selected: selected,
      onTap: () => _applyShowcasePreset(preset),
      semanticsLabel:
          'Apply ${_presentationName(preset)} Concentric Donut presentation',
    );
  }

  Widget _buildRingCountSelector() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose active rings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Every ring keeps its own series identity, total, and table rows.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SegmentedButton<int>(
          key: const ValueKey('concentric-ring-count-selector'),
          segments: [
            for (var count = 2; count <= _ringDescriptors.length; count++)
              ButtonSegment(value: count, label: Text('$count')),
          ],
          selected: {_ringCount},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _setRingCount(selection.single),
        ),
      ],
    );
  }

  Widget _buildMeaningCard({required bool compact}) {
    final theme = Theme.of(context);
    final points = [
      (
        Icons.layers_outlined,
        'Independent totals',
        '$_ringCount active rings calculate shares against their own totals. Denominators never cross rings.',
      ),
      (
        Icons.track_changes_outlined,
        'Stable ring identity',
        'Tooltips, tables, selection, and grouped Other slices keep the ring name, series ID, and original source rows.',
      ),
      (
        Icons.tune_outlined,
        'One shared pane',
        'Order, gaps, opening, and relative thickness belong to the composition.',
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            for (final point in points)
              SizedBox(
                width: compact ? double.infinity : 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(point.$1, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.$2,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(point.$3, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader({required bool compact}) {
    final theme = Theme.of(context);
    final ringKey = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (index, ring) in _activeRingDescriptors.indexed)
          _RingPill(
            label:
                '${_ringPositionLabel(index)} · ${ring.name.replaceFirst(' period', '')}',
            total: '${_ringTotal(ring.id).toStringAsFixed(0)} USD',
          ),
      ],
    );
    final selection = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: Text(
        _selectedSummary ??
            'Hover or select a slice to inspect its exact ring identity',
        key: ValueKey(_selectedSummary),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ringKey, const SizedBox(height: 8), selection],
      );
    }
    return Row(
      children: [
        Expanded(child: ringKey),
        const SizedBox(width: 16),
        Flexible(child: selection),
      ],
    );
  }

  Widget _buildDisplayModeSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<ChartDisplayMode>(
        key: const ValueKey('concentric-donut-display-mode'),
        segments: const [
          ButtonSegment(
            value: ChartDisplayMode.chart,
            icon: Icon(Icons.donut_large_outlined, size: 18),
            label: Text('Chart'),
          ),
          ButtonSegment(
            value: ChartDisplayMode.data,
            icon: Icon(Icons.table_rows_outlined, size: 18),
            label: Text('Data'),
          ),
          ButtonSegment(
            value: ChartDisplayMode.split,
            icon: Icon(Icons.vertical_split_outlined, size: 18),
            label: Text('Split'),
          ),
          ButtonSegment(
            value: ChartDisplayMode.source,
            icon: Icon(Icons.code_outlined, size: 18),
            label: Text('Source'),
          ),
        ],
        selected: {_displayMode},
        onSelectionChanged: (selected) {
          final mode = selected.single;
          setState(() => _displayMode = mode);
          _workbenchController.setDisplayMode(mode);
        },
      ),
    );
  }

  Widget _buildDataSurface({required bool compact}) {
    return BravenChartWorkbench(
      chartController: _chartController,
      workbenchController: _workbenchController,
      initialDisplayMode: _displayMode,
      availableDisplayModes: const {
        ChartDisplayMode.chart,
        ChartDisplayMode.data,
        ChartDisplayMode.split,
        ChartDisplayMode.source,
      },
      sourceOptions: const ChartDartSourceOptions(
        variableName: 'concentricDonutChart',
      ),
      showModeSwitcher: false,
      splitBreakpoint: 1,
      splitAxis: compact ? Axis.vertical : Axis.horizontal,
      splitGap: 8,
      minimumChartPaneExtent: compact ? 280 : 360,
      minimumTablePaneExtent: compact ? 240 : 420,
      maximumAutoTablePaneExtent: 620,
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
      chartBuilder: (context, controller) => _buildLiveChart(controller),
    );
  }

  Widget _buildLiveChart(BravenChartController controller) {
    return BravenChartPlus(
      key: const ValueKey('concentric-donut-chart'),
      title: 'Revenue mix by period',
      subtitle: 'Each ring calculates share against its own total',
      bravenChartController: controller,
      concentricDonutConfig: ConcentricDonutConfig(
        innerRadiusFactor: _innerRadiusFactor,
        outerRadiusFactor: _outerRadiusFactor,
        ringGap: _ringGap,
        order: _order,
        legendMode: _legendMode,
        ringWeights: {
          for (final ring in _activeRingDescriptors)
            ring.id: _ringWeights[ring.id] ?? 1,
        },
        centerContent: _centerContent,
      ),
      donutCenterBuilder: _showCenter && _useRuntimeCenter
          ? _buildRuntimeCenter
          : null,
      showLegend: _showLegend,
      radialLegendItemBuilder:
          _showLegend && _legendContent == _ConcentricLegendContent.valueCards
          ? _buildValueCardLegendItem
          : null,
      theme: _buildChartTheme(),
      interactionConfig: InteractionConfig(
        crosshair: const CrosshairConfig(enabled: false),
        tooltip: TooltipConfig(
          enabled: _showTooltips,
          triggerMode: TooltipTriggerMode.both,
          preferredPosition: _tooltipPosition,
          followCursor: _tooltipFollowsCursor,
          offsetFromPoint: _tooltipOffset,
        ),
        enableZoom: false,
        enablePan: false,
        enableSelection: true,
        showFocusBorder: false,
      ),
      onPointTap: (point, seriesId) =>
          _showSelectionSummary(point: point, seriesId: seriesId),
      series: _buildSeries(),
    );
  }

  Widget _buildValueCardLegendItem(
    BuildContext context,
    RadialLegendItemData item,
  ) => RadialLegendValueCard(
    key: ValueKey(
      'concentric-custom-legend-${item.seriesId}-${item.visibleIndex}',
    ),
    item: item,
  );

  Widget _buildRuntimeCenter(BuildContext context, DonutCenterData center) {
    final selected = center.hasSelection;
    final explicitLabel = _centerLabel.trim();
    final primary = explicitLabel.isNotEmpty
        ? center.label ?? explicitLabel
        : selected
        ? center.selectedCategory ?? 'Selected slice'
        : (center.rings.isEmpty ? null : center.rings.first.seriesName) ??
              center.label ??
              'Total';
    final backgroundColor = switch (_centerSurface) {
      _ConcentricCenterSurface.transparent => Colors.transparent,
      _ConcentricCenterSurface.tonal =>
        (center.defaultValueStyle.color ??
                _baseChartTheme.axisStyle.labelStyle.color ??
                Colors.white)
            .withValues(alpha: 0.09),
      _ConcentricCenterSurface.outlined => Colors.transparent,
    };
    final borderColor = switch (_centerSurface) {
      _ConcentricCenterSurface.transparent => Colors.transparent,
      _ConcentricCenterSurface.tonal =>
        _baseChartTheme.axisStyle.lineColor.withValues(alpha: 0.24),
      _ConcentricCenterSurface.outlined => center.selectionColor.withValues(
        alpha: 0.7,
      ),
    };
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: center.availableDiameter * 0.72),
        padding: _centerSurface == _ConcentricCenterSurface.transparent
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            key: const ValueKey('concentric-runtime-center-content'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                primary,
                key: const ValueKey('concentric-runtime-center-label'),
                style: center.defaultLabelStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                center.valueLabel,
                key: const ValueKey('concentric-runtime-center-value'),
                style: center.defaultValueStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DonutCenterContent get _centerContent {
    if (!_showCenter) return DonutCenterContent.hidden;
    final label = _centerLabel.trim();
    final customValue = _centerCustomValue.trim();
    return DonutCenterContent(
      label: label.isEmpty ? null : label,
      valueMode: _centerValueMode,
      customValue: _centerValueMode == DonutCenterValueMode.custom
          ? (customValue.isEmpty ? '—' : customValue)
          : null,
      labelStyle: _centerLabelStyle,
      valueStyle: _centerValueStyle,
    );
  }

  LabelStyle get _centerLabelStyle => LabelStyle(
    textStyle: TextStyle(
      color: _useChartThemeCenterColors ? null : _centerLabelColor,
      fontSize: _centerLabelFontSize,
      fontWeight: _centerLabelFontWeight,
    ),
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: 0,
    padding: EdgeInsets.zero,
  );

  LabelStyle get _centerValueStyle => LabelStyle(
    textStyle: TextStyle(
      color: _useChartThemeCenterColors ? null : _centerValueColor,
      fontSize: _centerValueFontSize,
      fontWeight: _centerValueFontWeight,
    ),
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: 0,
    padding: EdgeInsets.zero,
  );

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
    final ref = points.first;
    final series = _buildSeries().firstWhere(
      (series) => series.id == ref.seriesId,
    );
    final slice = series.visibleSliceForSourcePointIndex(ref.pointIndex);
    if (slice == null) return;
    final sliceRefs = {
      for (final pointIndex in slice.sourcePointIndices)
        ChartPointRef(seriesId: series.id, pointIndex: pointIndex),
    };
    final alreadySelected =
        _chartController.selectedPointRefs.length == sliceRefs.length &&
        _chartController.selectedPointRefs.containsAll(sliceRefs);
    if (alreadySelected) {
      _chartController.clearPointSelection();
      setState(() => _selectedSummary = null);
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      _showVisibleSliceSummary(series: series, slice: slice);
    }
  }

  void _showSelectionSummary({
    required ChartDataPoint point,
    required String seriesId,
  }) {
    final series = _buildSeries().firstWhere((series) => series.id == seriesId);
    RadialCategorySlice? visibleSlice;
    for (final slice in series.visibleSlices) {
      if (slice.point.label == point.label && slice.point.y == point.y) {
        visibleSlice = slice;
        break;
      }
    }
    if (visibleSlice == null) return;
    _showVisibleSliceSummary(series: series, slice: visibleSlice);
  }

  void _showVisibleSliceSummary({
    required DonutChartSeries series,
    required RadialCategorySlice slice,
  }) {
    if (!mounted) return;
    setState(() {
      final sourceRows = slice.isGrouped
          ? ' · ${slice.sourcePointIndices.length} source rows'
          : '';
      _selectedSummary =
          '${series.name} · ${slice.point.label} · '
          '${slice.point.y.toStringAsFixed(0)} USD$sourceRows';
    });
  }

  List<_ConcentricRingDescriptor> get _activeRingDescriptors =>
      _ringDescriptors.take(_ringCount).toList(growable: false);

  Map<String, num> _valuesForRing(String ringId) => switch (ringId) {
    'current' => _currentValues,
    'previous' => _previousValues,
    _ => _additionalRingValues[ringId]!,
  };

  double _ringTotal(String ringId) => _valuesForRing(
    ringId,
  ).values.fold<double>(0, (sum, value) => sum + value.toDouble());

  String _ringPositionLabel(int seriesIndex) {
    final radialIndex = _order == ConcentricRingOrder.outerToInner
        ? seriesIndex
        : _ringCount - seriesIndex - 1;
    if (radialIndex == 0) return 'Outer';
    if (radialIndex == _ringCount - 1) return 'Inner';
    return 'Ring ${radialIndex + 1}';
  }

  bool _isOuterRing(int seriesIndex) =>
      _order == ConcentricRingOrder.outerToInner
      ? seriesIndex == 0
      : seriesIndex == _ringCount - 1;

  List<DonutChartSeries> _buildSeries() => [
    for (final (index, ring) in _activeRingDescriptors.indexed)
      DonutChartSeries.fromMap(
        id: ring.id,
        name: ring.name,
        unit: 'USD',
        values: _valuesForRing(ring.id),
        sliceColors: _activeSliceColors,
        sliceGroupingConfig: _groupSmallCategories
            ? RadialSliceGroupingConfig(
                minimumShare: _groupingMinimumShare,
                label: 'Other',
                color: const Color(0xFF7C3AED),
              )
            : null,
        dataLabels: _buildDataLabels(isOuterRing: _isOuterRing(index)),
        donutStyle: _buildDonutStyle(),
        selectionStyle: _buildSelectionStyle(),
      ),
  ];

  PieDataLabelConfig _buildDataLabels({required bool isOuterRing}) {
    final (position, content) = switch (_labelLayout) {
      _ConcentricLabelLayout.uniform => (_labelPosition, _labelContent),
      _ConcentricLabelLayout.hierarchy =>
        isOuterRing
            ? (
                PieDataLabelPosition.outside,
                PieDataLabelContent.categoryAndPercentage,
              )
            : (PieDataLabelPosition.inside, PieDataLabelContent.category),
      _ConcentricLabelLayout.split => (
        PieDataLabelPosition.outside,
        PieDataLabelContent.category,
      ),
    };
    final hasSplitLayer = _labelLayout == _ConcentricLabelLayout.split;
    return PieDataLabelConfig(
      isVisible: _showLabels,
      position: position,
      content: content,
      secondaryContent: hasSplitLayer ? PieDataLabelContent.percentage : null,
      secondaryPosition: PieDataLabelPosition.inside,
      secondaryCalloutStyle: hasSplitLayer ? _insidePercentageStyle : null,
      minimumShare: _labelMinimumShare,
      minimumSweepDegrees: _labelMinimumSweepDegrees,
      padding: _labelPadding,
      insideOffset: _insideLabelOffset,
      outsideOffset: _outsideLabelOffset,
      connectorLength: _connectorLength,
      connectorWidth: _connectorWidth,
      connectorColor: _useCustomConnectorColor ? _connectorColor : null,
      collisionStrategy: _labelCollisionStrategy,
      calloutStyle:
          _labelLayout == _ConcentricLabelLayout.hierarchy && !isOuterRing
          ? _insideRingLabelStyle
          : _calloutStyle(_baseChartTheme),
    );
  }

  RadialSelectionStyle _buildSelectionStyle() => RadialSelectionStyle(
    effect: _selectionEffect,
    liftScale: _selectionLiftScale,
    liftOffset: _selectionLiftOffset,
    backdropBlur: _selectionBackdropBlur,
  );

  ChartTheme get _baseChartTheme => switch (_themePreset) {
    _ConcentricThemePreset.light => ChartTheme.light,
    _ConcentricThemePreset.dark => ChartTheme.dark,
    _ConcentricThemePreset.highContrast => ChartTheme.highContrast,
    _ConcentricThemePreset.colorblind => ChartTheme.colorblindFriendly,
  };

  List<Color> get _paletteColors => switch (_palette) {
    _ConcentricPalette.theme => List<Color>.generate(
      5,
      _baseChartTheme.seriesTheme.colorAt,
    ),
    _ConcentricPalette.ocean => _oceanSliceColors.values.toList(),
    _ConcentricPalette.sunset => const [
      Color(0xFFE63946),
      Color(0xFFF77F00),
      Color(0xFFFCBF49),
      Color(0xFF9D4EDD),
      Color(0xFF5A189A),
    ],
    _ConcentricPalette.earth => const [
      Color(0xFF386641),
      Color(0xFF6A994E),
      Color(0xFFA7C957),
      Color(0xFFBC6C25),
      Color(0xFF606C38),
    ],
    _ConcentricPalette.monochrome => const [
      Color(0xFF1F2937),
      Color(0xFF374151),
      Color(0xFF4B5563),
      Color(0xFF6B7280),
      Color(0xFF9CA3AF),
    ],
  };

  Map<String, Color> get _activeSliceColors {
    final colors = _paletteColors;
    return {
      for (final (index, category) in _currentValues.keys.indexed)
        category: colors[index % colors.length],
    };
  }

  PieGradientStyle? get _gradientStyle => switch (_gradientPreset) {
    _ConcentricGradientPreset.solid => null,
    _ConcentricGradientPreset.linear => PieGradientStyle(
      type: PieGradientType.linear,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartLightnessShift,
      endLightnessShift: _gradientEndLightnessShift,
      angleDegrees: _gradientAngleDegrees,
    ),
    _ConcentricGradientPreset.radial => PieGradientStyle(
      type: PieGradientType.radial,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartLightnessShift,
      endLightnessShift: _gradientEndLightnessShift,
    ),
  };

  DonutChartStyle _buildDonutStyle() {
    final selectedGlowColor = switch (_selectedGlowColor) {
      _ConcentricGlowColor.slice => null,
      _ConcentricGlowColor.accent => _paletteColors.first,
      _ConcentricGlowColor.neutral =>
        _baseChartTheme.axisStyle.labelStyle.color,
    };
    final borderColor = switch (_borderPreset) {
      _ConcentricBorderPreset.fixed => _fixedBorderColor,
      _ => null,
    };
    final borderColorMode = switch (_borderPreset) {
      _ConcentricBorderPreset.chartTheme => PieBorderColorMode.chartTheme,
      _ConcentricBorderPreset.darkerSlice ||
      _ConcentricBorderPreset.shiftedHue => PieBorderColorMode.slice,
      _ConcentricBorderPreset.fixed => null,
    };
    final borderHueShift = switch (_borderPreset) {
      _ConcentricBorderPreset.shiftedHue => 28.0,
      _ => 0.0,
    };
    final borderLightnessShift = switch (_borderPreset) {
      _ConcentricBorderPreset.darkerSlice => -0.18,
      _ConcentricBorderPreset.shiftedHue => -0.08,
      _ => -0.12,
    };
    return DonutChartStyle(
      innerRadiusFactor: _innerRadiusFactor,
      sweepAngleDegrees: _sweepAngleDegrees,
      startAngleDegrees: _startAngleDegrees,
      clockwise: _clockwise,
      sliceGap: _sliceGap,
      borderWidth: _borderWidth,
      borderColor: borderColor,
      borderColorMode: borderColorMode,
      borderHueShiftDegrees: borderHueShift,
      borderLightnessShift: borderLightnessShift,
      gradient: _gradientStyle,
      selectionExplodeOffset: _selectionExplodeOffset,
      opacity: _sliceOpacity,
      cornerRadius: _cornerRadius,
      cornerTreatment: _cornerTreatment,
      shadow: _showShadow
          ? PieElevationStyle(
              color: _themePreset == _ConcentricThemePreset.dark
                  ? const Color(0xB3000000)
                  : const Color(0x4D0F172A),
              blurRadius: _themePreset == _ConcentricThemePreset.dark ? 12 : 8,
              offset: const Offset(0, 4),
              opacity: 0.7,
            )
          : const PieElevationStyle(),
      selectedElevation: _showSelectedGlow
          ? PieElevationStyle(
              color: selectedGlowColor,
              blurRadius: _selectedGlowBlur,
              spreadRadius: _selectedGlowSpread,
              offset: Offset(0, _selectedGlowOffsetY),
              opacity: _selectedGlowOpacity,
            )
          : const PieElevationStyle(),
      animationMode: _animationMode,
      dataTransitionMode: _dataTransitionMode,
    );
  }

  ChartTheme _buildChartTheme() {
    final base = _baseChartTheme;
    final legendBase = base.legendStyle.copyWith(
      position: _legendPosition,
      orientation: _legendOrientation,
      markerShape: _legendMarkerShape,
      markerSize: _legendMarkerSize,
      textStyle: base.legendStyle.textStyle.copyWith(fontSize: _legendFontSize),
      opacity: _legendOpacity,
    );
    final legendStyle = switch (_legendPreset) {
      _ConcentricLegendPreset.theme => legendBase,
      _ConcentricLegendPreset.compact => legendBase.copyWith(
        markerLabelSpacing: 5,
        itemSpacing: 3,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      _ConcentricLegendPreset.surface => legendBase.copyWith(
        textStyle: legendBase.textStyle.copyWith(fontWeight: FontWeight.w600),
        backgroundColor: base.backgroundColor.withValues(alpha: 0.94),
        borderColor: base.axisStyle.lineColor.withValues(alpha: 0.42),
        borderWidth: 1,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemSpacing: 8,
      ),
    };
    return base.copyWith(
      seriesTheme: base.seriesTheme.copyWith(colors: _paletteColors),
      legendStyle: legendStyle,
      interactionTheme: base.interactionTheme.copyWith(
        tooltipStyle: _tooltipStyle(base),
      ),
      pieChartTheme: base.pieChartTheme.copyWith(
        calloutStyle: _calloutStyle(base),
        clearCalloutStyle: _calloutPreset == _ConcentricCalloutPreset.plain,
        animationMode: _animationMode,
      ),
    );
  }

  LabelStyle? _calloutStyle(ChartTheme theme) => switch (_calloutPreset) {
    _ConcentricCalloutPreset.plain => null,
    _ConcentricCalloutPreset.surface => LabelStyle(
      textStyle: theme.axisStyle.labelStyle.copyWith(
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: theme.backgroundColor.withValues(alpha: 0.94),
      borderColor: theme.axisStyle.lineColor.withValues(alpha: 0.55),
      borderWidth: 1,
      borderRadius: 7,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      shadowColor: const Color(0x261A1A1A),
      shadowBlurRadius: 6,
    ),
    _ConcentricCalloutPreset.accent => LabelStyle(
      textStyle: theme.axisStyle.labelStyle.copyWith(
        color: _paletteColors.first,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: _paletteColors.first.withValues(alpha: 0.12),
      borderColor: _paletteColors.first.withValues(alpha: 0.72),
      borderWidth: 1,
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    ),
    _ConcentricCalloutPreset.highContrast => const LabelStyle(
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.black,
      borderColor: Colors.white,
      borderWidth: 2,
      borderRadius: 4,
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    ),
  };

  LabelStyle get _insideRingLabelStyle => const LabelStyle(
    textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: 0,
    padding: EdgeInsets.zero,
  );

  LabelStyle get _insidePercentageStyle => switch (_insideShareStyle) {
    _ConcentricInsideShareStyle.autoContrast => const LabelStyle(
      textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.all(2),
    ),
    _ConcentricInsideShareStyle.darkBadge => const LabelStyle(
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0xD91F2937),
      borderColor: Color(0x99FFFFFF),
      borderWidth: 1,
      borderRadius: 4,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      shadowColor: Color(0x26000000),
      shadowBlurRadius: 3,
    ),
    _ConcentricInsideShareStyle.lightBadge => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0xF2FFFFFF),
      borderColor: Color(0x661A1A1A),
      borderWidth: 1,
      borderRadius: 4,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      shadowColor: Color(0x26000000),
      shadowBlurRadius: 3,
    ),
  };

  LabelStyle _tooltipStyle(ChartTheme theme) => switch (_tooltipPreset) {
    _ConcentricTooltipPreset.theme => theme.interactionTheme.tooltipStyle,
    _ConcentricTooltipPreset.elevated =>
      theme.interactionTheme.tooltipStyle.copyWith(
        borderRadius: 9,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shadowColor: const Color(0x401A1A1A),
        shadowBlurRadius: 12,
      ),
    _ConcentricTooltipPreset.highContrast => const LabelStyle(
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.black,
      borderColor: Colors.white,
      borderWidth: 2,
      borderRadius: 6,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shadowColor: Color(0x66000000),
      shadowBlurRadius: 8,
    ),
  };

  Future<void> _capturePortableCopy() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _artifactMessage = 'Capturing document and PNG preview…';
    });
    final result = await _chartController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'concentric-donut-showcase',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: const ChartDocumentExtractOptions(
          documentId: 'period-comparison',
          includeViewState: true,
        ),
        previewOptions: const ChartPreviewOptions(pixelRatio: 1),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case ChartArtifactSuccess<ChartArtifact>():
        final encoded = ChartArtifactJsonCodec.encode(result.value);
        if (encoded case ChartArtifactSuccess<String>()) {
          setState(() {
            _capturedArtifact = result.value;
            _capturedJson = encoded.value;
            _restoredConfiguration = null;
            _artifactMessage =
                'Captured ${result.value.document.series.length} rings, current selection, and a revision-bound preview.';
            _isCapturing = false;
          });
        } else if (encoded case ChartArtifactFailure<String>()) {
          setState(() {
            _artifactMessage = encoded.error.message;
            _isCapturing = false;
          });
        }
      case ChartArtifactFailure<ChartArtifact>():
        setState(() {
          _artifactMessage = result.error.message;
          _isCapturing = false;
        });
    }
  }

  void _restorePortableCopy() {
    final json = _capturedJson;
    if (json == null) return;
    final result = ChartDocumentHydrator.hydrateJson(json);
    switch (result) {
      case ChartArtifactSuccess<HydratedChartConfiguration>():
        setState(() {
          _restoredConfiguration = result.value;
          _artifactMessage =
              'Restored a fresh chart runtime from the saved JSON document.';
        });
      case ChartArtifactFailure<HydratedChartConfiguration>():
        setState(() => _artifactMessage = result.error.message);
    }
  }

  Widget _buildPortabilityCard({required bool compact}) {
    final theme = Theme.of(context);
    final artifact = _capturedArtifact;
    final previewBytes = artifact?.preview?.bytes;
    final restored = _restoredConfiguration;
    return Card(
      key: const ValueKey('concentric-portability-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: compact ? double.infinity : 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture, transport, and restore',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Save every active ring document plus its chart-level composition, exact point selection, portable center, and PNG preview.',
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('capture-concentric-artifact'),
                      onPressed: _isCapturing ? null : _capturePortableCopy,
                      icon: _isCapturing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(_isCapturing ? 'Capturing' : 'Capture copy'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('restore-concentric-artifact'),
                      onPressed: artifact == null ? null : _restorePortableCopy,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore copy'),
                    ),
                  ],
                ),
              ],
            ),
            if (_artifactMessage != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_artifactMessage!),
                ),
              ),
            ],
            if (artifact != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: compact ? double.infinity : 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved preview',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: previewBytes == null
                                ? const Center(child: Text('No inline preview'))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(
                                      previewBytes,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_capturedJson?.length ?? 0} JSON bytes · ${artifact.preview?.byteLength ?? previewBytes?.length ?? 0} PNG bytes',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (restored != null)
                    SizedBox(
                      key: const ValueKey('restored-concentric-chart'),
                      width: compact ? double.infinity : 620,
                      height: 360,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: restored.build(
                          bravenChartController: _restoredController,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _regenerateValues() {
    _chartController.clearPointSelection();
    setState(() {
      final labels = radialDemoLabels(
        preferredLabels: _categoryLabels,
        count: _categoryCount,
      );
      for (final ring in _activeRingDescriptors) {
        _regenerateRing(ring, labels);
      }
      _selectedSummary = null;
      _capturedArtifact = null;
      _restoredConfiguration = null;
      _capturedJson = null;
      _artifactMessage = null;
    });
  }

  void _applyRandomSeed(int seed) {
    if (!mounted) return;
    final random = math.Random(seed);
    final categoryCount = radialDemoMinimumDataPoints + random.nextInt(8);
    final ringCount = 2 + random.nextInt(4);
    final labels = List<String>.generate(
      categoryCount,
      (index) => 'Category ${index + 1}',
      growable: false,
    );
    setState(() {
      _categoryCount = categoryCount;
      _ringCount = ringCount;
      _currentValues = randomRadialDistribution(
        labels: labels,
        total: 100,
        random: random,
      );
      _previousValues = randomRadialDistribution(
        labels: labels,
        total: 100,
        random: random,
      );
      _additionalRingValues.clear();
      for (final ring in _ringDescriptors.skip(2)) {
        _additionalRingValues[ring.id] = randomRadialDistribution(
          labels: labels,
          total: ring.generatedTotal,
          random: random,
        );
      }
      for (final ring in _ringDescriptors) {
        _ringWeights[ring.id] = 0.7 + random.nextDouble() * 1.2;
      }
      _innerRadiusFactor = 0.18 + random.nextDouble() * 0.34;
      _outerRadiusFactor = 0.78 + random.nextDouble() * 0.2;
      _ringGap = 1 + random.nextDouble() * 9;
      _sweepAngleDegrees = 220 + random.nextDouble() * 140;
      _startAngleDegrees = -180 + random.nextDouble() * 360;
      _sliceGap = random.nextDouble() * 6;
      _borderWidth = random.nextDouble() * 3;
      _cornerRadius = random.nextDouble() * 12;
      _sliceOpacity = 0.58 + random.nextDouble() * 0.42;
      _clockwise = random.nextBool();
      _cornerTreatment = PieCornerTreatment
          .values[random.nextInt(PieCornerTreatment.values.length)];
      _animationMode = PieAnimationMode
          .values[random.nextInt(PieAnimationMode.values.length)];
      _order = ConcentricRingOrder
          .values[random.nextInt(ConcentricRingOrder.values.length)];
      _legendMode = ConcentricDonutLegendMode
          .values[random.nextInt(ConcentricDonutLegendMode.values.length)];
      _showLabels = random.nextBool();
      _labelPosition = PieDataLabelPosition
          .values[random.nextInt(PieDataLabelPosition.values.length)];
      _labelContent = PieDataLabelContent
          .values[random.nextInt(PieDataLabelContent.values.length)];
      _labelCollisionStrategy = PieDataLabelCollisionStrategy
          .values[random.nextInt(PieDataLabelCollisionStrategy.values.length)];
      _showLegend = random.nextBool();
      _legendPosition =
          LegendPosition.values[random.nextInt(LegendPosition.values.length)];
      _legendMarkerShape = LegendMarkerShape
          .values[random.nextInt(LegendMarkerShape.values.length)];
      _showTooltips = random.nextBool();
      _tooltipPosition =
          TooltipPosition.values[random.nextInt(TooltipPosition.values.length)];
      _themePreset = _ConcentricThemePreset
          .values[random.nextInt(_ConcentricThemePreset.values.length)];
      _palette = _ConcentricPalette
          .values[random.nextInt(_ConcentricPalette.values.length)];
      _showCenter = random.nextBool();
      _centerValueMode = DonutCenterValueMode
          .values[random.nextInt(DonutCenterValueMode.values.length)];
      _groupSmallCategories = random.nextBool();
      _groupingMinimumShare = 0.04 + random.nextDouble() * 0.12;
      _selectionEffect = RadialSelectionEffect
          .values[random.nextInt(RadialSelectionEffect.values.length)];
      _selectionExplodeOffset = random.nextDouble() * 18;
      _selectionLiftScale = 1 + random.nextDouble() * 0.3;
      _selectionLiftOffset = random.nextDouble() * 14;
      _selectionBackdropBlur = random.nextDouble() * 3;
      _dataTransitionMode = RadialDataTransitionMode
          .values[random.nextInt(RadialDataTransitionMode.values.length)];
      _labelLayout = _ConcentricLabelLayout
          .values[random.nextInt(_ConcentricLabelLayout.values.length)];
      _labelMinimumShare = random.nextDouble() * 0.1;
      _labelMinimumSweepDegrees = random.nextDouble() * 16;
      _labelPadding = random.nextDouble() * 14;
      _insideLabelOffset = -8 + random.nextDouble() * 16;
      _outsideLabelOffset = random.nextDouble() * 14;
      _connectorLength = 6 + random.nextDouble() * 24;
      _connectorWidth = 0.5 + random.nextDouble() * 2.5;
      _useCustomConnectorColor = random.nextBool();
      _connectorColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _calloutPreset = _ConcentricCalloutPreset
          .values[random.nextInt(_ConcentricCalloutPreset.values.length)];
      _insideShareStyle = _ConcentricInsideShareStyle
          .values[random.nextInt(_ConcentricInsideShareStyle.values.length)];
      _borderPreset = _ConcentricBorderPreset
          .values[random.nextInt(_ConcentricBorderPreset.values.length)];
      _fixedBorderColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _gradientPreset = _ConcentricGradientPreset
          .values[random.nextInt(_ConcentricGradientPreset.values.length)];
      _useFixedGradientColors = random.nextBool();
      _gradientStartColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _gradientEndColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _gradientStartLightnessShift = -0.25 + random.nextDouble() * 0.5;
      _gradientEndLightnessShift = -0.25 + random.nextDouble() * 0.5;
      _gradientAngleDegrees = -180 + random.nextDouble() * 360;
      _showShadow = random.nextBool();
      _showSelectedGlow = random.nextBool();
      _selectedGlowColor = _ConcentricGlowColor
          .values[random.nextInt(_ConcentricGlowColor.values.length)];
      _selectedGlowBlur = random.nextDouble() * 24;
      _selectedGlowSpread = random.nextDouble() * 8;
      _selectedGlowOpacity = 0.15 + random.nextDouble() * 0.8;
      _selectedGlowOffsetY = -8 + random.nextDouble() * 16;
      _legendPreset = _ConcentricLegendPreset
          .values[random.nextInt(_ConcentricLegendPreset.values.length)];
      _legendContent = _ConcentricLegendContent
          .values[random.nextInt(_ConcentricLegendContent.values.length)];
      _legendOrientation = LegendOrientation
          .values[random.nextInt(LegendOrientation.values.length)];
      _legendMarkerSize = 6 + random.nextDouble() * 12;
      _legendFontSize = 8 + random.nextDouble() * 8;
      _legendOpacity = 0.35 + random.nextDouble() * 0.65;
      _tooltipPreset = _ConcentricTooltipPreset
          .values[random.nextInt(_ConcentricTooltipPreset.values.length)];
      _tooltipFollowsCursor = random.nextBool();
      _tooltipOffset = 2 + random.nextDouble() * 18;
      _useRuntimeCenter = random.nextBool();
      _centerLabel = random.nextBool() ? '' : 'Generated';
      _centerCustomValue = '${2 + random.nextInt(9)} rings';
      _centerLabelFontSize = 8 + random.nextDouble() * 10;
      _centerValueFontSize = 14 + random.nextDouble() * 20;
      _centerLabelFontWeight =
          FontWeight.values[random.nextInt(FontWeight.values.length)];
      _centerValueFontWeight =
          FontWeight.values[random.nextInt(FontWeight.values.length)];
      _useChartThemeCenterColors = random.nextBool();
      _centerLabelColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _centerValueColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _centerSurface = _ConcentricCenterSurface
          .values[random.nextInt(_ConcentricCenterSurface.values.length)];
      _selectedSummary = null;
    });
    _chartController.clearPointSelection();
  }

  void _setCategoryCount(int count) {
    if (_categoryCount == count) return;
    _chartController.clearPointSelection();
    setState(() {
      _categoryCount = count;
      final labels = radialDemoLabels(
        preferredLabels: _categoryLabels,
        count: count,
      );
      for (final ring in _activeRingDescriptors) {
        _regenerateRing(ring, labels);
      }
      _selectedSummary = null;
      _capturedArtifact = null;
      _restoredConfiguration = null;
      _capturedJson = null;
      _artifactMessage = null;
    });
  }

  void _setRingCount(int count) {
    if (_ringCount == count) return;
    _chartController.clearPointSelection();
    setState(() {
      final previousCount = _ringCount;
      _ringCount = count;
      if (count > previousCount) {
        final labels = radialDemoLabels(
          preferredLabels: _categoryLabels,
          count: _categoryCount,
        );
        for (final ring
            in _ringDescriptors
                .skip(previousCount)
                .take(count - previousCount)) {
          _regenerateRing(ring, labels);
        }
      }
      _selectedSummary = null;
      _capturedArtifact = null;
      _restoredConfiguration = null;
      _capturedJson = null;
      _artifactMessage = null;
    });
  }

  void _regenerateRing(_ConcentricRingDescriptor ring, List<String> labels) {
    final values = randomRadialDistribution(
      labels: labels,
      total: ring.generatedTotal,
      random: _random,
    );
    switch (ring.id) {
      case 'current':
        _currentValues = values;
        return;
      case 'previous':
        _previousValues = values;
        return;
      default:
        _additionalRingValues[ring.id] = values;
        return;
    }
  }

  String _dataLabelContentName(PieDataLabelContent value) => switch (value) {
    PieDataLabelContent.category => 'Category',
    PieDataLabelContent.value => 'Value',
    PieDataLabelContent.percentage => 'Percentage',
    PieDataLabelContent.categoryAndValue => 'Category + value',
    PieDataLabelContent.categoryAndPercentage => 'Category + percentage',
    PieDataLabelContent.valueAndPercentage => 'Value + percentage',
    PieDataLabelContent.categoryValueAndPercentage =>
      'Category + value + percentage',
  };

  String _fontWeightName(FontWeight value) => switch (value) {
    FontWeight.w400 => 'Regular · 400',
    FontWeight.w500 => 'Medium · 500',
    FontWeight.w600 => 'Semi-bold · 600',
    FontWeight.w700 => 'Bold · 700',
    FontWeight.w800 => 'Extra-bold · 800',
    _ => 'Weight ${value.value}',
  };

  void _applyShowcasePreset(
    _ConcentricShowcasePreset preset, {
    bool authoredSelection = true,
  }) {
    if (authoredSelection) {
      _showcaseRandomizer.pause();
      _showcaseRandomizer.clear();
    }
    _chartController.clearPointSelection();
    setState(() {
      if (authoredSelection) {
        _playgroundActive = false;
        _authoredPreset = preset;
      }
      _resetPresentationDefaults();
      _showcasePreset = preset;
      switch (preset) {
        case _ConcentricShowcasePreset.comparison:
          _applyComparisonPresentation();
        case _ConcentricShowcasePreset.compact:
          _categoryCount = 7;
          _currentValues = Map<String, num>.of(_compactCurrentValues);
          _previousValues = Map<String, num>.of(_compactPreviousValues);
          _themePreset = _ConcentricThemePreset.colorblind;
          _palette = _ConcentricPalette.theme;
          _innerRadiusFactor = 0.4;
          _outerRadiusFactor = 1;
          _ringGap = 0;
          _ringWeights['current'] = 1;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _clockwise = true;
          _sliceGap = 0;
          _borderWidth = 3;
          _borderPreset = _ConcentricBorderPreset.darkerSlice;
          _cornerRadius = 12;
          _cornerTreatment = PieCornerTreatment.outerOnly;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.explode;
          _selectionLiftScale = 1.1;
          _sliceOpacity = 1;
          _gradientPreset = _ConcentricGradientPreset.solid;
          _showShadow = true;
          _showSelectedGlow = true;
          _selectedGlowColor = _ConcentricGlowColor.slice;
          _selectedGlowBlur = 12;
          _selectedGlowSpread = 2.5;
          _selectedGlowOpacity = 0.48;
          _selectedGlowOffsetY = 0;
          _showLabels = true;
          _labelLayout = _ConcentricLabelLayout.hierarchy;
          _labelMinimumShare = 0.04;
          _labelMinimumSweepDegrees = 16;
          _labelPadding = 10;
          _insideLabelOffset = 0;
          _outsideLabelOffset = 6;
          _calloutPreset = _ConcentricCalloutPreset.plain;
          _insideShareStyle = _ConcentricInsideShareStyle.autoContrast;
          _showLegend = false;
          _legendPreset = _ConcentricLegendPreset.compact;
          _legendContent = _ConcentricLegendContent.standard;
          _legendMarkerSize = 11;
          _legendFontSize = 9;
          _showTooltips = true;
          _tooltipPreset = _ConcentricTooltipPreset.elevated;
          _showCenter = true;
          _useRuntimeCenter = false;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerLabel = '';
          _centerLabelFontSize = 11;
          _centerValueFontSize = 22;
          _centerLabelFontWeight = FontWeight.w500;
          _centerValueFontWeight = FontWeight.w700;
          _useChartThemeCenterColors = true;
          _centerSurface = _ConcentricCenterSurface.transparent;
          _groupSmallCategories = true;
          _groupingMinimumShare = 0.1;
          _animationMode = PieAnimationMode.fade;
          break;
        case _ConcentricShowcasePreset.partial:
          _ringCount = 3;
          _additionalRingValues['forecast'] = Map<String, num>.of(
            _baseForecastValues,
          );
          _innerRadiusFactor = 0.38;
          _outerRadiusFactor = 0.9;
          _ringGap = 8;
          _ringWeights['current'] = 1;
          _sweepAngleDegrees = 260;
          _startAngleDegrees = -140;
          _sliceGap = 3;
          _cornerRadius = 8;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.explode;
          _gradientPreset = _ConcentricGradientPreset.linear;
          _gradientAngleDegrees = -20;
          _palette = _ConcentricPalette.earth;
          _labelPosition = PieDataLabelPosition.outside;
          _labelContent = PieDataLabelContent.categoryAndPercentage;
          _labelMinimumShare = 0.04;
          _outsideLabelOffset = 8;
          _groupSmallCategories = false;
          _legendMode = ConcentricDonutLegendMode.flat;
          _legendPosition = LegendPosition.centerRight;
          _legendOrientation = LegendOrientation.vertical;
          _legendMarkerShape = LegendMarkerShape.line;
          _legendMarkerSize = 12;
          _legendFontSize = 11;
          break;
        case _ConcentricShowcasePreset.elevated:
          _categoryCount = 10;
          _currentValues = Map<String, num>.of(_elevatedCurrentValues);
          _previousValues = Map<String, num>.of(_elevatedPreviousValues);
          _themePreset = _ConcentricThemePreset.dark;
          _palette = _ConcentricPalette.sunset;
          _innerRadiusFactor = 0.38;
          _outerRadiusFactor = 0.94;
          _ringGap = 10;
          _ringWeights['current'] = 1.25;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -30;
          _clockwise = true;
          _sliceGap = 2;
          _borderWidth = 1;
          _borderPreset = _ConcentricBorderPreset.darkerSlice;
          _cornerRadius = 8;
          _cornerTreatment = PieCornerTreatment.roundAll;
          _selectionExplodeOffset = 14;
          _selectionEffect = RadialSelectionEffect.lift;
          _selectionLiftScale = 1.14;
          _selectionLiftOffset = 8;
          _selectionBackdropBlur = 2;
          _sliceOpacity = 1;
          _gradientPreset = _ConcentricGradientPreset.radial;
          _useFixedGradientColors = false;
          _gradientStartLightnessShift = 0.24;
          _gradientEndLightnessShift = -0.14;
          _showShadow = true;
          _showSelectedGlow = true;
          _selectedGlowColor = _ConcentricGlowColor.accent;
          _selectedGlowBlur = 20;
          _selectedGlowSpread = 4;
          _selectedGlowOpacity = 0.65;
          _selectedGlowOffsetY = 0;
          _showLabels = true;
          _labelLayout = _ConcentricLabelLayout.hierarchy;
          _labelMinimumShare = 0.04;
          _labelMinimumSweepDegrees = 6;
          _labelPadding = 6;
          _insideLabelOffset = 0;
          _outsideLabelOffset = 4;
          _calloutPreset = _ConcentricCalloutPreset.surface;
          _insideShareStyle = _ConcentricInsideShareStyle.autoContrast;
          _showLegend = false;
          _legendPreset = _ConcentricLegendPreset.compact;
          _legendContent = _ConcentricLegendContent.standard;
          _legendMarkerSize = 9;
          _legendFontSize = 10;
          _showTooltips = true;
          _tooltipPreset = _ConcentricTooltipPreset.elevated;
          _showCenter = true;
          _useRuntimeCenter = false;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerLabel = '';
          _centerLabelFontSize = 11;
          _centerValueFontSize = 22;
          _centerLabelFontWeight = FontWeight.w600;
          _centerValueFontWeight = FontWeight.w700;
          _useChartThemeCenterColors = true;
          _centerSurface = _ConcentricCenterSurface.transparent;
          _groupSmallCategories = false;
          _animationMode = PieAnimationMode.grow;
          break;
        case _ConcentricShowcasePreset.highContrast:
          _categoryCount = 10;
          _currentValues = Map<String, num>.of(_highContrastCurrentValues);
          _previousValues = Map<String, num>.of(_highContrastPreviousValues);
          _themePreset = _ConcentricThemePreset.highContrast;
          _palette = _ConcentricPalette.monochrome;
          _order = ConcentricRingOrder.innerToOuter;
          _innerRadiusFactor = 0.38;
          _outerRadiusFactor = 1;
          _ringGap = 9;
          _ringWeights['current'] = 1;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _clockwise = true;
          _sliceGap = 5;
          _gradientPreset = _ConcentricGradientPreset.solid;
          _borderWidth = 1.5;
          _borderPreset = _ConcentricBorderPreset.fixed;
          _fixedBorderColor = Colors.black;
          _cornerRadius = 0;
          _cornerTreatment = PieCornerTreatment.roundAll;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.explode;
          _selectionLiftScale = 1.1;
          _sliceOpacity = 1;
          _showShadow = false;
          _showSelectedGlow = true;
          _selectedGlowColor = _ConcentricGlowColor.neutral;
          _selectedGlowBlur = 4;
          _selectedGlowSpread = 3;
          _selectedGlowOpacity = 1;
          _selectedGlowOffsetY = 0;
          _animationMode = PieAnimationMode.sweep;
          _showLabels = true;
          _labelLayout = _ConcentricLabelLayout.split;
          _labelPosition = PieDataLabelPosition.outside;
          _labelContent = PieDataLabelContent.category;
          _labelMinimumShare = 0.05;
          _labelMinimumSweepDegrees = 4;
          _labelPadding = 2;
          _insideLabelOffset = 0;
          _outsideLabelOffset = 32;
          _connectorLength = 12;
          _connectorWidth = 1.5;
          _useCustomConnectorColor = true;
          _connectorColor = const Color(0xFFEF4444);
          _calloutPreset = _ConcentricCalloutPreset.highContrast;
          _insideShareStyle = _ConcentricInsideShareStyle.darkBadge;
          _groupSmallCategories = false;
          _showLegend = true;
          _legendMode = ConcentricDonutLegendMode.groupedByRing;
          _legendPreset = _ConcentricLegendPreset.compact;
          _legendContent = _ConcentricLegendContent.standard;
          _legendPosition = LegendPosition.bottomCenter;
          _legendOrientation = LegendOrientation.horizontal;
          _legendMarkerShape = LegendMarkerShape.circle;
          _legendMarkerSize = 10;
          _legendFontSize = 12;
          _legendOpacity = 1;
          _showTooltips = true;
          _tooltipPreset = _ConcentricTooltipPreset.highContrast;
          _tooltipPosition = TooltipPosition.auto;
          _tooltipFollowsCursor = false;
          _tooltipOffset = 8;
          _showCenter = true;
          _useRuntimeCenter = false;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerLabel = '';
          _centerLabelFontSize = 11;
          _centerValueFontSize = 22;
          _centerLabelFontWeight = FontWeight.w500;
          _centerValueFontWeight = FontWeight.w700;
          _useChartThemeCenterColors = true;
          _centerSurface = _ConcentricCenterSurface.transparent;
          break;
      }
      _selectedSummary = null;
      _capturedArtifact = null;
      _restoredConfiguration = null;
      _capturedJson = null;
      _artifactMessage = null;
    });
  }

  void _setPlaygroundActive(bool active) {
    if (active == _playgroundActive) return;
    if (active) {
      _authoredPreset = _showcasePreset;
      setState(() => _playgroundActive = true);
      _showcaseRandomizer.generateCurrent();
      return;
    }
    _showcaseRandomizer.pause();
    _showcaseRandomizer.clear();
    _applyShowcasePreset(_authoredPreset);
  }

  List<Widget> _buildPlaygroundOptions() => _buildOptions();

  void _resetPresentationDefaults() {
    _ringCount = 2;
    _categoryCount = 5;
    _currentValues = Map<String, num>.of(_baseCurrentValues);
    _previousValues = Map<String, num>.of(_basePreviousValues);
    _additionalRingValues['forecast'] = Map<String, num>.of(
      _baseForecastValues,
    );
    for (final ring in _ringDescriptors) {
      _ringWeights[ring.id] = 1;
    }
    _innerRadiusFactor = 0.28;
    _outerRadiusFactor = 0.94;
    _ringGap = 6;
    _ringWeights['current'] = 1.25;
    _sweepAngleDegrees = 360;
    _startAngleDegrees = -90;
    _sliceGap = 2;
    _borderWidth = 1;
    _borderPreset = _ConcentricBorderPreset.darkerSlice;
    _fixedBorderColor = const Color(0xFF334155);
    _cornerRadius = 5;
    _selectionExplodeOffset = 5;
    _selectionEffect = RadialSelectionEffect.lift;
    _selectionLiftScale = 1.1;
    _selectionLiftOffset = 6;
    _selectionBackdropBlur = 1.25;
    _sliceOpacity = 1;
    _gradientPreset = _ConcentricGradientPreset.radial;
    _useFixedGradientColors = false;
    _gradientStartColor = const Color(0xFF67E8F9);
    _gradientEndColor = const Color(0xFF1D4ED8);
    _gradientStartLightnessShift = 0.16;
    _gradientEndLightnessShift = -0.12;
    _gradientAngleDegrees = -45;
    _showShadow = false;
    _showSelectedGlow = true;
    _selectedGlowColor = _ConcentricGlowColor.slice;
    _selectedGlowBlur = 12;
    _selectedGlowSpread = 2;
    _selectedGlowOpacity = 0.48;
    _selectedGlowOffsetY = 0;
    _clockwise = true;
    _cornerTreatment = PieCornerTreatment.roundAll;
    _animationMode = PieAnimationMode.sweep;
    _dataTransitionMode = RadialDataTransitionMode.automatic;
    _order = ConcentricRingOrder.outerToInner;
    _legendMode = ConcentricDonutLegendMode.groupedByRing;
    _showLabels = true;
    _labelLayout = _ConcentricLabelLayout.uniform;
    _labelPosition = PieDataLabelPosition.inside;
    _labelContent = PieDataLabelContent.percentage;
    _labelCollisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide;
    _labelMinimumShare = 0.03;
    _labelMinimumSweepDegrees = 8;
    _labelPadding = 6;
    _insideLabelOffset = 0;
    _outsideLabelOffset = 0;
    _connectorLength = 14;
    _connectorWidth = 1;
    _useCustomConnectorColor = false;
    _connectorColor = const Color(0xFF475569);
    _calloutPreset = _ConcentricCalloutPreset.surface;
    _insideShareStyle = _ConcentricInsideShareStyle.darkBadge;
    _showLegend = true;
    _legendPreset = _ConcentricLegendPreset.compact;
    _legendContent = _ConcentricLegendContent.standard;
    _legendPosition = LegendPosition.bottomCenter;
    _legendOrientation = LegendOrientation.horizontal;
    _legendMarkerShape = LegendMarkerShape.circle;
    _legendMarkerSize = 10;
    _legendFontSize = 10;
    _legendOpacity = 1;
    _showTooltips = true;
    _tooltipPreset = _ConcentricTooltipPreset.elevated;
    _tooltipPosition = TooltipPosition.auto;
    _tooltipFollowsCursor = false;
    _tooltipOffset = 8;
    _themePreset = _ConcentricThemePreset.light;
    _palette = _ConcentricPalette.ocean;
    _showCenter = true;
    _useRuntimeCenter = true;
    _centerValueMode = DonutCenterValueMode.selectedOrTotal;
    _centerLabelFontSize = 11;
    _centerValueFontSize = 22;
    _centerLabelFontWeight = FontWeight.w500;
    _centerValueFontWeight = FontWeight.w700;
    _useChartThemeCenterColors = true;
    _centerSurface = _ConcentricCenterSurface.transparent;
    _groupSmallCategories = true;
    _groupingMinimumShare = 0.1;
  }

  void _applyComparisonPresentation() {
    _ringCount = 3;
    _additionalRingValues['forecast'] = Map<String, num>.of(
      _baseForecastValues,
    );
    _innerRadiusFactor = 0.36;
    _outerRadiusFactor = 0.88;
    _ringGap = 12;
    _ringWeights['current'] = 1;
    _ringWeights['forecast'] = 0.9;
    _sliceGap = 8;
    _cornerRadius = 6;
    _selectionEffect = RadialSelectionEffect.lift;
    _selectionLiftScale = 1.06;
    _selectionLiftOffset = 3;
    _selectionBackdropBlur = 3;
    _gradientPreset = _ConcentricGradientPreset.radial;
    _gradientStartLightnessShift = 0.4;
    _gradientEndLightnessShift = 0;
    _showShadow = true;
    _showLabels = true;
    _labelLayout = _ConcentricLabelLayout.hierarchy;
    _labelPosition = PieDataLabelPosition.inside;
    _labelContent = PieDataLabelContent.percentage;
    _labelMinimumShare = 0.02;
    _labelMinimumSweepDegrees = 0;
    _calloutPreset = _ConcentricCalloutPreset.plain;
    _showLegend = false;
  }

  String _presentationName(_ConcentricShowcasePreset preset) =>
      switch (preset) {
        _ConcentricShowcasePreset.comparison => 'Period comparison',
        _ConcentricShowcasePreset.compact => 'Compact dashboard',
        _ConcentricShowcasePreset.partial => 'Partial rings',
        _ConcentricShowcasePreset.elevated => 'Elevated gradients',
        _ConcentricShowcasePreset.highContrast => 'High contrast',
      };

  String _presentationDescription(
    _ConcentricShowcasePreset preset,
  ) => switch (preset) {
    _ConcentricShowcasePreset.comparison =>
      'Three full rings, grouped sources, high-contrast percentages, and lifted selection',
    _ConcentricShowcasePreset.compact =>
      'Two joined rings, colorblind palette, grouped sources, and compact labels',
    _ConcentricShowcasePreset.partial =>
      'Three partial rings, outside callouts, flat ring identity, and earth tones',
    _ConcentricShowcasePreset.elevated =>
      'Two ten-category rings, luminous gradients, lifted depth, and layered labels',
    _ConcentricShowcasePreset.highContrast =>
      'Two monochrome rings, strong borders, accessible callouts, and explicit labels',
  };

  IconData _presentationIcon(_ConcentricShowcasePreset preset) =>
      switch (preset) {
        _ConcentricShowcasePreset.comparison => Icons.compare_outlined,
        _ConcentricShowcasePreset.compact => Icons.dashboard_outlined,
        _ConcentricShowcasePreset.partial => Icons.speed_outlined,
        _ConcentricShowcasePreset.elevated => Icons.auto_awesome_outlined,
        _ConcentricShowcasePreset.highContrast => Icons.contrast_outlined,
      };

  List<Widget> _buildOptions() => orderRadialOptionSections([
    RadialOptionEntry(
      RadialOptionSectionKind.demoData,
      OptionSection(
        title: 'Demo data',
        icon: Icons.dataset_outlined,
        children: [
          IntSliderOption(
            key: const ValueKey('concentric-ring-count'),
            label: 'Active rings',
            value: _ringCount,
            min: 2,
            max: _ringDescriptors.length,
            suffix: 'rings',
            onChanged: _setRingCount,
          ),
          IntSliderOption(
            key: const ValueKey('concentric-data-point-count'),
            label: 'Data points per ring',
            value: _categoryCount,
            min: radialDemoMinimumDataPoints,
            max: radialDemoMaximumDataPoints,
            suffix: 'points',
            onChanged: _setCategoryCount,
          ),
          Text(
            '${_categoryCount * _ringCount} source points across $_ringCount independent rings. '
            'New rings receive fresh random distributions; point-count changes regenerate every active ring. '
            'Turn off Group small categories to render every row as a slice.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('regenerate-concentric-values'),
              onPressed: _regenerateValues,
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: const Text('Regenerate values'),
            ),
          ),
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.chartTheme,
      OptionSection(
        title: 'Chart theme',
        icon: Icons.contrast_outlined,
        children: [
          EnumOption<_ConcentricThemePreset>(
            key: const ValueKey('concentric-theme'),
            label: 'Theme',
            value: _themePreset,
            values: _ConcentricThemePreset.values,
            labelBuilder: (value) => switch (value) {
              _ConcentricThemePreset.light => 'Light',
              _ConcentricThemePreset.dark => 'Dark',
              _ConcentricThemePreset.highContrast => 'High contrast',
              _ConcentricThemePreset.colorblind => 'Colorblind friendly',
            },
            onChanged: (value) => setState(() => _themePreset = value),
          ),
          EnumOption<_ConcentricPalette>(
            key: const ValueKey('concentric-palette'),
            label: 'Color palette',
            value: _palette,
            values: _ConcentricPalette.values,
            labelBuilder: (value) => switch (value) {
              _ConcentricPalette.theme => 'Theme colors',
              _ConcentricPalette.ocean => 'Ocean',
              _ConcentricPalette.sunset => 'Sunset',
              _ConcentricPalette.earth => 'Earth',
              _ConcentricPalette.monochrome => 'Monochrome',
            },
            onChanged: (value) => setState(() => _palette = value),
          ),
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.geometry,
      OptionSection(
        title: 'Composition geometry',
        icon: Icons.donut_large_outlined,
        children: [
          SliderOption(
            key: const ValueKey('concentric-inner-radius'),
            label: 'Center opening',
            value: _innerRadiusFactor * 100,
            min: 12,
            max: 52,
            divisions: 20,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _innerRadiusFactor = value / 100),
          ),
          SliderOption(
            key: const ValueKey('concentric-outer-radius'),
            label: 'Outer radius',
            value: _outerRadiusFactor * 100,
            min: 60,
            max: 100,
            divisions: 20,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _outerRadiusFactor = value / 100),
          ),
          SliderOption(
            key: const ValueKey('concentric-ring-gap'),
            label: 'Ring gap',
            value: _ringGap,
            min: 0,
            max: 16,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _ringGap = value),
          ),
          for (final ring in _activeRingDescriptors)
            SliderOption(
              key: ValueKey(
                ring.id == 'current'
                    ? 'concentric-current-weight'
                    : 'concentric-ring-weight-${ring.id}',
              ),
              label: '${ring.name} weight',
              value: _ringWeights[ring.id] ?? 1,
              min: 0.5,
              max: 2,
              divisions: 6,
              suffix: '×',
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _ringWeights[ring.id] = value),
            ),
          EnumOption<ConcentricRingOrder>(
            key: const ValueKey('concentric-ring-order'),
            label: 'Series order',
            value: _order,
            values: ConcentricRingOrder.values,
            labelBuilder: (value) => switch (value) {
              ConcentricRingOrder.outerToInner => 'First series outside',
              ConcentricRingOrder.innerToOuter => 'First series inside',
            },
            onChanged: (value) => setState(() => _order = value),
          ),
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.geometry,
      OptionSection(
        title: 'Shared angular frame',
        icon: Icons.rotate_right_outlined,
        children: [
          SliderOption(
            key: const ValueKey('concentric-sweep-angle'),
            label: 'Sweep angle',
            value: _sweepAngleDegrees,
            min: 90,
            max: 360,
            divisions: 18,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _sweepAngleDegrees = value),
          ),
          SliderOption(
            key: const ValueKey('concentric-start-angle'),
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
            key: const ValueKey('concentric-clockwise'),
            label: 'Clockwise order',
            value: _clockwise,
            onChanged: (value) => setState(() => _clockwise = value),
          ),
          const InfoBox(
            message:
                'All rings intentionally share one start angle, sweep, and direction. Their category shares and totals remain independent.',
          ),
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.sliceAppearance,
      OptionSection(
        title: 'Slice appearance',
        icon: Icons.palette_outlined,
        children: [
          EnumOption<_ConcentricGradientPreset>(
            key: const ValueKey('concentric-gradient'),
            label: 'Slice fill',
            value: _gradientPreset,
            values: _ConcentricGradientPreset.values,
            labelBuilder: (value) => switch (value) {
              _ConcentricGradientPreset.solid => 'Solid color',
              _ConcentricGradientPreset.linear => 'Linear gradient',
              _ConcentricGradientPreset.radial => 'Radial gradient',
            },
            onChanged: (value) => setState(() => _gradientPreset = value),
          ),
          if (_playgroundActive ||
              _gradientPreset != _ConcentricGradientPreset.solid) ...[
            BoolOption(
              key: const ValueKey('concentric-fixed-gradient-colors'),
              label: 'Use fixed gradient colors',
              value: _useFixedGradientColors,
              onChanged: (value) =>
                  setState(() => _useFixedGradientColors = value),
              subtitle: 'Off derives both stops from each category color',
            ),
            if (_playgroundActive || _useFixedGradientColors) ...[
              ColorOption(
                key: const ValueKey('concentric-gradient-start-color'),
                label: 'Gradient start',
                value: _gradientStartColor,
                colors: _colorChoices,
                onChanged: (value) =>
                    setState(() => _gradientStartColor = value),
              ),
              ColorOption(
                key: const ValueKey('concentric-gradient-end-color'),
                label: 'Gradient end',
                value: _gradientEndColor,
                colors: _colorChoices,
                onChanged: (value) => setState(() => _gradientEndColor = value),
              ),
            ] else ...[
              SliderOption(
                key: const ValueKey('concentric-gradient-start-shift'),
                label: 'Start lightness',
                value: _gradientStartLightnessShift * 100,
                min: -40,
                max: 40,
                divisions: 16,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _gradientStartLightnessShift = value / 100),
              ),
              SliderOption(
                key: const ValueKey('concentric-gradient-end-shift'),
                label: 'End lightness',
                value: _gradientEndLightnessShift * 100,
                min: -40,
                max: 40,
                divisions: 16,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _gradientEndLightnessShift = value / 100),
              ),
            ],
            if (_playgroundActive ||
                _gradientPreset == _ConcentricGradientPreset.linear)
              SliderOption(
                key: const ValueKey('concentric-gradient-angle'),
                label: 'Gradient angle',
                value: _gradientAngleDegrees,
                min: -180,
                max: 180,
                divisions: 24,
                suffix: '°',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _gradientAngleDegrees = value),
              ),
          ],
          SliderOption(
            key: const ValueKey('concentric-opacity'),
            label: 'Transparency',
            value: _sliceOpacity * 100,
            min: 25,
            max: 100,
            divisions: 15,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _sliceOpacity = value / 100),
          ),
          SliderOption(
            key: const ValueKey('concentric-slice-gap'),
            label: 'Slice gap',
            value: _sliceGap,
            min: 0,
            max: 12,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _sliceGap = value),
          ),
          SliderOption(
            key: const ValueKey('concentric-border-width'),
            label: 'Border width',
            value: _borderWidth,
            min: 0,
            max: 4,
            divisions: 8,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _borderWidth = value),
          ),
          if (_playgroundActive || _borderWidth > 0) ...[
            EnumOption<_ConcentricBorderPreset>(
              key: const ValueKey('concentric-border-color'),
              label: 'Border color',
              value: _borderPreset,
              values: _ConcentricBorderPreset.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricBorderPreset.chartTheme => 'Chart theme outline',
                _ConcentricBorderPreset.darkerSlice => 'Darker slice shade',
                _ConcentricBorderPreset.shiftedHue => 'Shifted slice hue',
                _ConcentricBorderPreset.fixed => 'Fixed color',
              },
              onChanged: (value) => setState(() => _borderPreset = value),
            ),
            if (_playgroundActive ||
                _borderPreset == _ConcentricBorderPreset.fixed)
              ColorOption(
                key: const ValueKey('concentric-fixed-border-color'),
                label: 'Fixed border',
                value: _fixedBorderColor,
                colors: _colorChoices,
                onChanged: (value) => setState(() => _fixedBorderColor = value),
              ),
          ],
          SliderOption(
            key: const ValueKey('concentric-corner-radius'),
            label: 'Rounded corners',
            value: _cornerRadius,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _cornerRadius = value),
          ),
          if (_playgroundActive || _cornerRadius > 0)
            EnumOption<PieCornerTreatment>(
              key: const ValueKey('concentric-corner-treatment'),
              label: 'Corner treatment',
              value: _cornerTreatment,
              values: PieCornerTreatment.values,
              labelBuilder: (value) => switch (value) {
                PieCornerTreatment.roundAll => 'Round inner and outer',
                PieCornerTreatment.outerOnly => 'Outer corners only',
                PieCornerTreatment.circularCenter => 'Circular center cutout',
              },
              onChanged: (value) => setState(() => _cornerTreatment = value),
            ),
          BoolOption(
            key: const ValueKey('concentric-slice-shadow'),
            label: 'Slice shadow',
            value: _showShadow,
            onChanged: (value) => setState(() => _showShadow = value),
          ),
          BoolOption(
            key: const ValueKey('concentric-selected-glow'),
            label: 'Selected slice glow',
            value: _showSelectedGlow,
            onChanged: (value) => setState(() => _showSelectedGlow = value),
          ),
          if (_playgroundActive || _showSelectedGlow) ...[
            EnumOption<_ConcentricGlowColor>(
              key: const ValueKey('concentric-glow-color'),
              label: 'Glow color',
              value: _selectedGlowColor,
              values: _ConcentricGlowColor.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricGlowColor.slice => 'Selected slice',
                _ConcentricGlowColor.accent => 'Palette accent',
                _ConcentricGlowColor.neutral => 'Theme foreground',
              },
              onChanged: (value) => setState(() => _selectedGlowColor = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-glow-blur'),
              label: 'Glow blur',
              value: _selectedGlowBlur,
              min: 0,
              max: 24,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _selectedGlowBlur = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-glow-spread'),
              label: 'Glow spread',
              value: _selectedGlowSpread,
              min: 0,
              max: 6,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _selectedGlowSpread = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-glow-opacity'),
              label: 'Glow opacity',
              value: _selectedGlowOpacity * 100,
              min: 0,
              max: 100,
              divisions: 20,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _selectedGlowOpacity = value / 100),
            ),
            SliderOption(
              key: const ValueKey('concentric-glow-offset'),
              label: 'Depth offset',
              value: _selectedGlowOffsetY,
              min: -12,
              max: 12,
              divisions: 24,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _selectedGlowOffsetY = value),
            ),
          ],
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.selection,
      OptionSection(
        title: 'Selection',
        icon: Icons.layers_outlined,
        children: [
          EnumOption<RadialSelectionEffect>(
            key: const ValueKey('concentric-selection-effect'),
            label: 'Selection treatment',
            value: _selectionEffect,
            values: RadialSelectionEffect.values,
            labelBuilder: (value) => switch (value) {
              RadialSelectionEffect.explode => 'Pull outward',
              RadialSelectionEffect.lift => 'Lift towards viewer',
            },
            onChanged: (value) => setState(() => _selectionEffect = value),
          ),
          if (_playgroundActive ||
              _selectionEffect == RadialSelectionEffect.explode)
            SliderOption(
              key: const ValueKey('concentric-selection-offset'),
              label: 'Selected slice offset',
              value: _selectionExplodeOffset,
              min: 0,
              max: 24,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _selectionExplodeOffset = value),
            )
          else ...[
            SliderOption(
              key: const ValueKey('concentric-selection-lift-scale'),
              label: 'Lift scale',
              value: _selectionLiftScale * 100,
              min: 100,
              max: 125,
              divisions: 25,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _selectionLiftScale = value / 100),
            ),
            SliderOption(
              key: const ValueKey('concentric-selection-lift-offset'),
              label: 'Lift offset',
              value: _selectionLiftOffset,
              min: 0,
              max: 24,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _selectionLiftOffset = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-selection-backdrop-blur'),
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
          ],
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.motion,
      OptionSection(
        title: 'Motion',
        icon: Icons.animation_outlined,
        children: [
          EnumOption<PieAnimationMode>(
            key: const ValueKey('concentric-animation-mode'),
            label: 'Entrance',
            value: _animationMode,
            values: PieAnimationMode.values,
            labelBuilder: (value) => switch (value) {
              PieAnimationMode.none => 'No animation',
              PieAnimationMode.grow => 'Grow',
              PieAnimationMode.sweep => 'Sweep',
              PieAnimationMode.fade => 'Fade',
            },
            onChanged: (value) => setState(() => _animationMode = value),
            subtitle: 'Apply one coordinated entrance to every ring',
          ),
          EnumOption<RadialDataTransitionMode>(
            key: const ValueKey('concentric-data-transition-mode'),
            label: 'Data updates',
            value: _dataTransitionMode,
            values: RadialDataTransitionMode.values,
            labelBuilder: (value) => switch (value) {
              RadialDataTransitionMode.none => 'Instant',
              RadialDataTransitionMode.automatic => 'Identity-aware',
            },
            onChanged: (value) => setState(() => _dataTransitionMode = value),
            subtitle: 'Morph stable categories independently within each ring',
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('replay-concentric-entrance'),
              onPressed: _animationMode == PieAnimationMode.none
                  ? null
                  : _chartController.replayRadialEntrance,
              icon: const Icon(Icons.replay_outlined, size: 18),
              label: const Text('Replay entrance'),
            ),
          ),
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.dataLabels,
      OptionSection(
        title: 'Data labels',
        icon: Icons.label_outline,
        children: [
          BoolOption(
            key: const ValueKey('concentric-show-labels'),
            label: 'Show slice labels',
            value: _showLabels,
            onChanged: (value) => setState(() => _showLabels = value),
          ),
          if (_playgroundActive || _showLabels) ...[
            EnumOption<_ConcentricLabelLayout>(
              key: const ValueKey('concentric-label-layout'),
              label: 'Layout',
              value: _labelLayout,
              values: _ConcentricLabelLayout.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricLabelLayout.uniform => 'Same label on every ring',
                _ConcentricLabelLayout.hierarchy =>
                  'Outer callouts + inner categories',
                _ConcentricLabelLayout.split =>
                  'Category outside + share inside',
              },
              onChanged: (value) => setState(() => _labelLayout = value),
            ),
            if (_playgroundActive ||
                _labelLayout == _ConcentricLabelLayout.uniform) ...[
              EnumOption<PieDataLabelPosition>(
                key: const ValueKey('concentric-label-position'),
                label: 'Position',
                value: _labelPosition,
                values: PieDataLabelPosition.values,
                labelBuilder: (value) => switch (value) {
                  PieDataLabelPosition.inside => 'Inside slices',
                  PieDataLabelPosition.outside => 'Outside with connectors',
                },
                onChanged: (value) => setState(() => _labelPosition = value),
              ),
              EnumOption<PieDataLabelContent>(
                key: const ValueKey('concentric-label-content'),
                label: 'Content',
                value: _labelContent,
                values: PieDataLabelContent.values,
                labelBuilder: _dataLabelContentName,
                onChanged: (value) => setState(() => _labelContent = value),
              ),
            ],
            EnumOption<_ConcentricCalloutPreset>(
              key: const ValueKey('concentric-callout-style'),
              label: _labelLayout == _ConcentricLabelLayout.split
                  ? 'Outside callout style'
                  : 'Label style',
              value: _calloutPreset,
              values: _ConcentricCalloutPreset.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricCalloutPreset.plain => 'Plain text',
                _ConcentricCalloutPreset.surface => 'Raised surface',
                _ConcentricCalloutPreset.accent => 'Palette accent',
                _ConcentricCalloutPreset.highContrast => 'High contrast',
              },
              onChanged: (value) => setState(() => _calloutPreset = value),
            ),
            if (_playgroundActive ||
                _labelLayout == _ConcentricLabelLayout.split)
              EnumOption<_ConcentricInsideShareStyle>(
                key: const ValueKey('concentric-inside-share-style'),
                label: 'Inside share style',
                subtitle: 'Styled independently from the outside category',
                value: _insideShareStyle,
                values: _ConcentricInsideShareStyle.values,
                labelBuilder: (value) => switch (value) {
                  _ConcentricInsideShareStyle.autoContrast =>
                    'Auto-contrast text',
                  _ConcentricInsideShareStyle.darkBadge => 'Dark badge',
                  _ConcentricInsideShareStyle.lightBadge => 'Light badge',
                },
                onChanged: (value) => setState(() => _insideShareStyle = value),
              ),
            SliderOption(
              key: const ValueKey('concentric-label-minimum-share'),
              label: 'Minimum share',
              value: _labelMinimumShare * 100,
              min: 0,
              max: 15,
              divisions: 15,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _labelMinimumShare = value / 100),
            ),
            SliderOption(
              key: const ValueKey('concentric-label-minimum-sweep'),
              label: 'Minimum sweep',
              value: _labelMinimumSweepDegrees,
              min: 0,
              max: 24,
              divisions: 12,
              suffix: '°',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _labelMinimumSweepDegrees = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-label-padding'),
              label: 'Label padding',
              value: _labelPadding,
              min: 0,
              max: 16,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _labelPadding = value),
            ),
            if (_playgroundActive ||
                _labelLayout != _ConcentricLabelLayout.uniform ||
                _labelPosition == PieDataLabelPosition.inside)
              SliderOption(
                key: const ValueKey('concentric-label-inside-offset'),
                label: 'Inside radial offset',
                value: _insideLabelOffset,
                min: -32,
                max: 32,
                divisions: 32,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _insideLabelOffset = value),
              ),
            if (_playgroundActive ||
                _labelLayout != _ConcentricLabelLayout.uniform ||
                _labelPosition == PieDataLabelPosition.outside) ...[
              EnumOption<PieDataLabelCollisionStrategy>(
                key: const ValueKey('concentric-label-collision'),
                label: 'Collision handling',
                value: _labelCollisionStrategy,
                values: PieDataLabelCollisionStrategy.values,
                labelBuilder: (value) => switch (value) {
                  PieDataLabelCollisionStrategy.none => 'Allow overlap',
                  PieDataLabelCollisionStrategy.shift => 'Shift labels',
                  PieDataLabelCollisionStrategy.shiftAndHide =>
                    'Shift, then hide',
                },
                onChanged: (value) =>
                    setState(() => _labelCollisionStrategy = value),
              ),
              SliderOption(
                key: const ValueKey('concentric-label-outside-offset'),
                label: 'Outside offset',
                value: _outsideLabelOffset,
                min: 0,
                max: 32,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _outsideLabelOffset = value),
              ),
              SliderOption(
                key: const ValueKey('concentric-connector-length'),
                label: 'Connector length',
                value: _connectorLength,
                min: 0,
                max: 32,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _connectorLength = value),
              ),
              SliderOption(
                key: const ValueKey('concentric-connector-width'),
                label: 'Connector width',
                value: _connectorWidth,
                min: 0.5,
                max: 4,
                divisions: 7,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _connectorWidth = value),
              ),
              BoolOption(
                key: const ValueKey('concentric-custom-connector-color'),
                label: 'Custom connector color',
                value: _useCustomConnectorColor,
                onChanged: (value) =>
                    setState(() => _useCustomConnectorColor = value),
              ),
              if (_playgroundActive || _useCustomConnectorColor)
                ColorOption(
                  key: const ValueKey('concentric-connector-color'),
                  label: 'Connector color',
                  value: _connectorColor,
                  colors: _colorChoices,
                  onChanged: (value) => setState(() => _connectorColor = value),
                ),
            ],
          ],
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.centerContent,
      OptionSection(
        title: 'Center content',
        icon: Icons.center_focus_strong_outlined,
        initiallyExpanded: false,
        children: [
          BoolOption(
            key: const ValueKey('concentric-show-center'),
            label: 'Show composition center',
            value: _showCenter,
            onChanged: (value) => setState(() => _showCenter = value),
          ),
          if (_playgroundActive || _showCenter) ...[
            EnumOption<DonutCenterValueMode>(
              key: const ValueKey('concentric-center-value-mode'),
              label: 'Value source',
              value: _centerValueMode,
              values: DonutCenterValueMode.values,
              labelBuilder: (value) => switch (value) {
                DonutCenterValueMode.total => 'Current ring total',
                DonutCenterValueMode.selectedValue => 'Selected slice only',
                DonutCenterValueMode.selectedOrTotal => 'Selected or total',
                DonutCenterValueMode.custom => 'Custom text',
              },
              onChanged: (value) => setState(() => _centerValueMode = value),
            ),
            TextOption(
              key: const ValueKey('concentric-center-label'),
              label: 'Center label',
              value: _centerLabel,
              hint: 'Automatic ring or selected category',
              onChanged: (value) => setState(() => _centerLabel = value),
            ),
            if (_playgroundActive ||
                _centerValueMode == DonutCenterValueMode.custom)
              TextOption(
                key: const ValueKey('concentric-center-custom-value'),
                label: 'Custom value',
                value: _centerCustomValue,
                hint: 'For example: 2 periods',
                onChanged: (value) =>
                    setState(() => _centerCustomValue = value),
              ),
            SliderOption(
              key: const ValueKey('concentric-center-label-size'),
              label: 'Label size',
              value: _centerLabelFontSize,
              min: 8,
              max: 18,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _centerLabelFontSize = value),
            ),
            EnumOption<FontWeight>(
              key: const ValueKey('concentric-center-label-weight'),
              label: 'Label weight',
              value: _centerLabelFontWeight,
              values: const [
                FontWeight.w400,
                FontWeight.w500,
                FontWeight.w600,
                FontWeight.w700,
              ],
              labelBuilder: _fontWeightName,
              onChanged: (value) =>
                  setState(() => _centerLabelFontWeight = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-center-value-size'),
              label: 'Value size',
              value: _centerValueFontSize,
              min: 12,
              max: 32,
              divisions: 20,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _centerValueFontSize = value),
            ),
            EnumOption<FontWeight>(
              key: const ValueKey('concentric-center-value-weight'),
              label: 'Value weight',
              value: _centerValueFontWeight,
              values: const [
                FontWeight.w400,
                FontWeight.w500,
                FontWeight.w600,
                FontWeight.w700,
                FontWeight.w800,
              ],
              labelBuilder: _fontWeightName,
              onChanged: (value) =>
                  setState(() => _centerValueFontWeight = value),
            ),
            BoolOption(
              key: const ValueKey('concentric-center-theme-colors'),
              label: 'Use chart-theme colors',
              subtitle:
                  'Automatically follows light, dark, high-contrast, and custom chart themes.',
              value: _useChartThemeCenterColors,
              onChanged: (value) =>
                  setState(() => _useChartThemeCenterColors = value),
            ),
            if (_playgroundActive || !_useChartThemeCenterColors) ...[
              ColorOption(
                key: const ValueKey('concentric-center-label-color'),
                label: 'Label color',
                value: _centerLabelColor,
                colors: _colorChoices,
                onChanged: (value) => setState(() => _centerLabelColor = value),
              ),
              ColorOption(
                key: const ValueKey('concentric-center-value-color'),
                label: 'Value color',
                value: _centerValueColor,
                colors: _colorChoices,
                onChanged: (value) => setState(() => _centerValueColor = value),
              ),
            ],
            BoolOption(
              key: const ValueKey('concentric-runtime-center'),
              label: 'Use runtime center builder',
              subtitle:
                  'Return any Flutter widget while retaining the portable text fallback.',
              value: _useRuntimeCenter,
              onChanged: (value) => setState(() => _useRuntimeCenter = value),
            ),
            if (_playgroundActive || _useRuntimeCenter)
              EnumOption<_ConcentricCenterSurface>(
                key: const ValueKey('concentric-center-surface'),
                label: 'Runtime surface',
                value: _centerSurface,
                values: _ConcentricCenterSurface.values,
                labelBuilder: (value) => switch (value) {
                  _ConcentricCenterSurface.transparent => 'Transparent',
                  _ConcentricCenterSurface.tonal => 'Subtle tonal surface',
                  _ConcentricCenterSurface.outlined => 'Focus outline',
                },
                onChanged: (value) => setState(() => _centerSurface = value),
              ),
            const InfoBox(
              message:
                  'Portable label/value styles survive capture and restore. The runtime builder receives those effective chart-theme styles and may return a completely custom widget.',
            ),
          ],
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.smallCategories,
      OptionSection(
        title: 'Small categories',
        icon: Icons.call_merge_outlined,
        children: [
          BoolOption(
            key: const ValueKey('concentric-group-small-categories'),
            label: 'Group small categories',
            value: _groupSmallCategories,
            onChanged: (value) => setState(() {
              _groupSmallCategories = value;
              _selectedSummary = null;
              _chartController.clearPointSelection();
            }),
          ),
          if (_playgroundActive || _groupSmallCategories)
            SliderOption(
              key: const ValueKey('concentric-grouping-threshold'),
              label: 'Share threshold',
              value: _groupingMinimumShare * 100,
              min: 1,
              max: 20,
              divisions: 19,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) {
                _chartController.clearPointSelection();
                setState(() {
                  _groupingMinimumShare = value / 100;
                  _selectedSummary = null;
                });
              },
            ),
          const InfoBox(
            message:
                'Each ring projects Training and Support into its own Other slice. The native table and CSV still retain both original rows; selecting either row activates only that ring group.',
          ),
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.legend,
      OptionSection(
        title: 'Legend',
        icon: Icons.view_list_outlined,
        children: [
          BoolOption(
            key: const ValueKey('concentric-show-legend'),
            label: 'Show legend',
            value: _showLegend,
            onChanged: (value) => setState(() => _showLegend = value),
          ),
          if (_playgroundActive || _showLegend) ...[
            EnumOption<ConcentricDonutLegendMode>(
              key: const ValueKey('concentric-legend-mode'),
              label: 'Ring identity',
              value: _legendMode,
              values: ConcentricDonutLegendMode.values,
              labelBuilder: (value) => switch (value) {
                ConcentricDonutLegendMode.groupedByRing => 'Grouped by ring',
                ConcentricDonutLegendMode.flat => 'Flat, qualified items',
              },
              onChanged: (value) => setState(() => _legendMode = value),
            ),
            EnumOption<_ConcentricLegendPreset>(
              key: const ValueKey('concentric-legend-style'),
              label: 'Legend style',
              value: _legendPreset,
              values: _ConcentricLegendPreset.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricLegendPreset.theme => 'Chart theme',
                _ConcentricLegendPreset.compact => 'Compact',
                _ConcentricLegendPreset.surface => 'Raised surface',
              },
              onChanged: (value) => setState(() => _legendPreset = value),
            ),
            EnumOption<_ConcentricLegendContent>(
              key: const ValueKey('concentric-legend-content'),
              label: 'Item content',
              value: _legendContent,
              values: _ConcentricLegendContent.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricLegendContent.standard => 'Standard details',
                _ConcentricLegendContent.valueCards => 'Custom value cards',
              },
              onChanged: (value) => setState(() => _legendContent = value),
            ),
            EnumOption<LegendPosition>(
              key: const ValueKey('concentric-legend-position'),
              label: 'Position',
              value: _legendPosition,
              values: LegendPosition.values,
              labelBuilder: (value) => switch (value) {
                LegendPosition.topLeft => 'Top left',
                LegendPosition.topCenter => 'Top center',
                LegendPosition.topRight => 'Top right',
                LegendPosition.centerLeft => 'Center left',
                LegendPosition.center => 'Overlay center',
                LegendPosition.centerRight => 'Center right',
                LegendPosition.bottomLeft => 'Bottom left',
                LegendPosition.bottomCenter => 'Bottom center',
                LegendPosition.bottomRight => 'Bottom right',
              },
              onChanged: (value) => setState(() => _legendPosition = value),
            ),
            EnumOption<LegendOrientation>(
              key: const ValueKey('concentric-legend-orientation'),
              label: 'Orientation',
              value: _legendOrientation,
              values: LegendOrientation.values,
              labelBuilder: (value) => switch (value) {
                LegendOrientation.horizontal => 'Horizontal',
                LegendOrientation.vertical => 'Vertical',
              },
              onChanged: (value) => setState(() => _legendOrientation = value),
            ),
            EnumOption<LegendMarkerShape>(
              key: const ValueKey('concentric-legend-marker-shape'),
              label: 'Marker shape',
              value: _legendMarkerShape,
              values: LegendMarkerShape.values,
              labelBuilder: (value) => switch (value) {
                LegendMarkerShape.circle => 'Circle',
                LegendMarkerShape.square => 'Square',
                LegendMarkerShape.line => 'Line',
                LegendMarkerShape.diamond => 'Diamond',
              },
              onChanged: (value) => setState(() => _legendMarkerShape = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-legend-marker-size'),
              label: 'Marker size',
              value: _legendMarkerSize,
              min: 6,
              max: 20,
              divisions: 14,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _legendMarkerSize = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-legend-font-size'),
              label: 'Text size',
              value: _legendFontSize,
              min: 8,
              max: 16,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _legendFontSize = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-legend-opacity'),
              label: 'Legend opacity',
              value: _legendOpacity * 100,
              min: 25,
              max: 100,
              divisions: 15,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _legendOpacity = value / 100),
            ),
          ],
        ],
      ),
    ),
    RadialOptionEntry(
      RadialOptionSectionKind.interaction,
      OptionSection(
        title: 'Interaction',
        icon: Icons.touch_app_outlined,
        children: [
          BoolOption(
            key: const ValueKey('concentric-show-tooltips'),
            label: 'Show tooltips',
            value: _showTooltips,
            onChanged: (value) => setState(() => _showTooltips = value),
            subtitle:
                'Hover, tap, legend, and table selection share one tooltip',
          ),
          if (_playgroundActive || _showTooltips) ...[
            EnumOption<_ConcentricTooltipPreset>(
              key: const ValueKey('concentric-tooltip-style'),
              label: 'Tooltip style',
              value: _tooltipPreset,
              values: _ConcentricTooltipPreset.values,
              labelBuilder: (value) => switch (value) {
                _ConcentricTooltipPreset.theme => 'Chart theme',
                _ConcentricTooltipPreset.elevated => 'Elevated surface',
                _ConcentricTooltipPreset.highContrast => 'High contrast',
              },
              onChanged: (value) => setState(() => _tooltipPreset = value),
            ),
            EnumOption<TooltipPosition>(
              key: const ValueKey('concentric-tooltip-position'),
              label: 'Preferred position',
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
            BoolOption(
              key: const ValueKey('concentric-tooltip-follow-cursor'),
              label: 'Follow pointer',
              value: _tooltipFollowsCursor,
              onChanged: (value) =>
                  setState(() => _tooltipFollowsCursor = value),
            ),
            SliderOption(
              key: const ValueKey('concentric-tooltip-offset'),
              label: 'Point offset',
              value: _tooltipOffset,
              min: 0,
              max: 24,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _tooltipOffset = value),
            ),
          ],
        ],
      ),
    ),
    const RadialOptionEntry(
      RadialOptionSectionKind.guidance,
      InfoBox(
        message:
            'Legend items retain ring identity and select the exact source point. Keyboard traversal crosses rings without losing the series ID.',
      ),
    ),
  ]);

  Widget _buildApiCard() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compose real Donut series',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No new point type is required. Two or more DonutChartSeries values activate the shared allocator; this demo exposes up to six rings, while the public API has no fixed upper count.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SelectableText(
                "BravenChartPlus(\n"
                "  series: [currentDonut, previousDonut, forecastDonut],\n"
                "  concentricDonutConfig: ConcentricDonutConfig(\n"
                "    innerRadiusFactor: 0.28,\n"
                "    ringGap: 6,\n"
                "    ringWeights: {\n"
                "      'current': 1.25,\n"
                "      'previous': 1,\n"
                "      'forecast': 0.8,\n"
                "    },\n"
                "    legendMode: ConcentricDonutLegendMode.groupedByRing,\n"
                "    centerContent: DonutCenterContent(\n"
                "      valueMode: DonutCenterValueMode.selectedOrTotal,\n"
                "      labelStyle: centerLabelStyle,\n"
                "      valueStyle: centerValueStyle,\n"
                "    ),\n"
                "  ),\n"
                "  // Grouping is configured independently on each ring.\n"
                "  // sliceGroupingConfig: RadialSliceGroupingConfig(\n"
                "  //   minimumShare: 0.1,\n"
                "  // ),\n"
                "  donutCenterBuilder: (context, center) => MyCenter(\n"
                "    rings: center.rings,\n"
                "    labelStyle: center.defaultLabelStyle,\n"
                "    valueStyle: center.defaultValueStyle,\n"
                "  ),\n"
                ")",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcentricRingDescriptor {
  const _ConcentricRingDescriptor({
    required this.id,
    required this.name,
    required this.generatedTotal,
  });

  final String id;
  final String name;
  final double generatedTotal;
}

enum _ConcentricShowcasePreset {
  comparison,
  compact,
  partial,
  elevated,
  highContrast,
}

enum _ConcentricThemePreset { light, dark, highContrast, colorblind }

enum _ConcentricPalette { theme, ocean, sunset, earth, monochrome }

enum _ConcentricGradientPreset { solid, linear, radial }

enum _ConcentricBorderPreset { chartTheme, darkerSlice, shiftedHue, fixed }

enum _ConcentricGlowColor { slice, accent, neutral }

enum _ConcentricCalloutPreset { plain, surface, accent, highContrast }

enum _ConcentricInsideShareStyle { autoContrast, darkBadge, lightBadge }

enum _ConcentricLabelLayout { uniform, hierarchy, split }

enum _ConcentricLegendPreset { theme, compact, surface }

enum _ConcentricLegendContent { standard, valueCards }

enum _ConcentricTooltipPreset { theme, elevated, highContrast }

enum _ConcentricCenterSurface { transparent, tonal, outlined }

class _RingPill extends StatelessWidget {
  const _RingPill({required this.label, required this.total});

  final String label;
  final String total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('$label · $total', style: theme.textTheme.labelMedium),
      ),
    );
  }
}
