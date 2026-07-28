// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/radial_legend_value_card.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

enum _RadialBarPresentation {
  progress('Progress', Icons.track_changes_outlined),
  signed('Signed baseline', Icons.compare_arrows_outlined),
  partial('Partial target', Icons.donut_small_outlined),
  callouts('Callout labels', Icons.call_split_outlined),
  insideStyling('Inside styling', Icons.format_color_text_outlined),
  labelCards('Label cards', Icons.style_outlined),
  popupStudio('Popup studio', Icons.chat_bubble_outline),
  motion('Motion', Icons.animation_outlined),
  rotatedCategories('Rotated categories', Icons.rotate_right_outlined),
  calloutLanes('Callout lanes', Icons.alt_route_outlined),
  dense('Dense tracks', Icons.density_medium_outlined);

  const _RadialBarPresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _RadialBarLegendPreset { theme, compact, surface }

enum _RadialBarLegendContent { standard, valueCards }

enum _RadialBarGradientPreset { solid, sweep, radial }

enum _RadialBarTooltipPreset { theme, elevated, contrast }

enum _RadialBarMotionCurve { linear, easeOut, easeOutCubic, easeInOutCubic }

@immutable
class _RandomRadialBarState {
  const _RandomRadialBarState({
    required this.values,
    required this.minimum,
    required this.maximum,
    required this.baseline,
    required this.startAngle,
    required this.sweepAngle,
    required this.clockwise,
    required this.innerRadius,
    required this.outerRadius,
    required this.trackGap,
    required this.cornerRadius,
    required this.trackOpacity,
    required this.gradientPreset,
    required this.useFixedGradientColors,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.gradientStartLightnessShift,
    required this.gradientEndLightnessShift,
    required this.tickCount,
    required this.thresholdValue,
    required this.showThreshold,
    required this.labelPosition,
    required this.labelContent,
    required this.labelColorMode,
    required this.labelSize,
    required this.labelOffset,
    required this.showCalloutPanel,
    required this.calloutPanelPaddingX,
    required this.calloutPanelPaddingY,
    required this.calloutPanelShadowBlur,
    required this.categoryLabelPosition,
    required this.categoryLabelOrientation,
    required this.showCategoryPanel,
    required this.categoryPanelPaddingX,
    required this.categoryPanelPaddingY,
    required this.categoryPanelShadowBlur,
    required this.selectionEffect,
    required this.selectionLiftScale,
    required this.selectionLiftOffset,
    required this.selectionBackdropBlur,
    required this.showLegend,
    required this.legendPreset,
    required this.legendContent,
    required this.legendPosition,
    required this.legendOrientation,
    required this.legendMarkerShape,
    required this.tooltipPreset,
    required this.tooltipTriggerMode,
    required this.tooltipPosition,
    required this.tooltipFollowsPointer,
    required this.tooltipOffset,
    required this.tooltipShowDelayMs,
    required this.tooltipHideDelayMs,
    required this.tooltipBorderWidth,
    required this.tooltipBorderRadius,
    required this.tooltipPadding,
    required this.tooltipShadowBlur,
    required this.tooltipFontSize,
    required this.entranceAnimationEnabled,
    required this.animationDurationMs,
    required this.animationCurve,
    required this.interactionDurationMs,
    required this.interactionCurve,
  });

  final Map<String, num> values;
  final double minimum;
  final double maximum;
  final double baseline;
  final double startAngle;
  final double sweepAngle;
  final bool clockwise;
  final double innerRadius;
  final double outerRadius;
  final double trackGap;
  final double cornerRadius;
  final double trackOpacity;
  final _RadialBarGradientPreset gradientPreset;
  final bool useFixedGradientColors;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final double gradientStartLightnessShift;
  final double gradientEndLightnessShift;
  final int tickCount;
  final double thresholdValue;
  final bool showThreshold;
  final RadialBarDataLabelPosition labelPosition;
  final RadialBarDataLabelContent labelContent;
  final RadialBarDataLabelColorMode labelColorMode;
  final double labelSize;
  final double labelOffset;
  final bool showCalloutPanel;
  final double calloutPanelPaddingX;
  final double calloutPanelPaddingY;
  final double calloutPanelShadowBlur;
  final RadialBarCategoryLabelPosition categoryLabelPosition;
  final RadialBarCategoryLabelOrientation categoryLabelOrientation;
  final bool showCategoryPanel;
  final double categoryPanelPaddingX;
  final double categoryPanelPaddingY;
  final double categoryPanelShadowBlur;
  final RadialSelectionEffect selectionEffect;
  final double selectionLiftScale;
  final double selectionLiftOffset;
  final double selectionBackdropBlur;
  final bool showLegend;
  final _RadialBarLegendPreset legendPreset;
  final _RadialBarLegendContent legendContent;
  final LegendPosition legendPosition;
  final LegendOrientation legendOrientation;
  final LegendMarkerShape legendMarkerShape;
  final _RadialBarTooltipPreset tooltipPreset;
  final TooltipTriggerMode tooltipTriggerMode;
  final TooltipPosition tooltipPosition;
  final bool tooltipFollowsPointer;
  final double tooltipOffset;
  final int tooltipShowDelayMs;
  final int tooltipHideDelayMs;
  final double tooltipBorderWidth;
  final double tooltipBorderRadius;
  final double tooltipPadding;
  final double tooltipShadowBlur;
  final double tooltipFontSize;
  final bool entranceAnimationEnabled;
  final int animationDurationMs;
  final _RadialBarMotionCurve animationCurve;
  final int interactionDurationMs;
  final _RadialBarMotionCurve interactionCurve;
}

/// Public Radial Bar showcase and complete property workbench.
class RadialBarPage extends StatefulWidget {
  const RadialBarPage({super.key});

  @override
  State<RadialBarPage> createState() => _RadialBarPageState();
}

class _RadialBarPageState extends State<RadialBarPage> {
  static const _progressValues = <String, num>{
    'Activation': 92,
    'Retention': 78,
    'Adoption': 66,
    'Satisfaction': 84,
    'Expansion': 57,
  };

  static const _signedValues = <String, num>{
    'Acquisition': 64,
    'Support': -36,
    'Reliability': 82,
    'Churn': -52,
    'Advocacy': 48,
  };

  static const _partialValues = <String, num>{
    'Search': 88,
    'Social': 72,
    'Direct': 94,
    'Partner': 63,
    'Referral': 79,
  };

  static const _denseValues = <String, num>{
    'North': 82,
    'North-east': 64,
    'East': 91,
    'South-east': 58,
    'South': 76,
    'South-west': 49,
    'West': 86,
    'North-west': 69,
    'Central': 74,
    'Remote': 55,
    'Partner': 80,
    'Direct': 67,
  };

  static const _calloutValues = <String, num>{
    'Activation': 92,
    'Retention': 78,
    'Adoption': 12,
    'Satisfaction': 84,
    'Expansion': 7,
  };

  static const _insideStyleValues = <String, num>{
    'Discover': 96,
    'Evaluate': 84,
    'Adopt': 72,
    'Retain': 61,
    'Advocate': 49,
  };

  static const _rotatedCategoryValues = <String, num>{
    'Organic search': 91,
    'Paid social': 76,
    'Direct traffic': 68,
    'Channel partners': 83,
    'Customer referral': 57,
  };

  static const _calloutLaneValues = <String, num>{
    'North': 96,
    'North-east': 92,
    'East': 88,
    'South-east': 84,
    'South': 80,
    'South-west': 76,
    'West': 72,
    'North-west': 68,
  };

  static const _categoryPalette = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFE11D48),
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
    Color(0xFFDB2777),
    Color(0xFF0284C7),
    Color(0xFF65A30D),
  ];

  late final ShowcaseRandomizerController<_RandomRadialBarState> _randomizer;

  _RadialBarPresentation _presentation = _RadialBarPresentation.progress;
  bool _playgroundActive = false;
  int _chartRevision = 0;
  Map<String, num> _values = Map.of(_progressValues);

  double _minimum = 0;
  double _maximum = 100;
  double _baseline = 0;
  double _startAngle = -90;
  double _sweepAngle = 360;
  bool _clockwise = true;
  double _innerRadius = 0.22;
  double _outerRadius = 0.82;
  double _trackGap = 6;
  RadialBarTrackOrder _trackOrder = RadialBarTrackOrder.outerToInner;

  double _cornerRadius = 8;
  double _markOpacity = 1;
  double _borderWidth = 0;
  Color? _borderColor;
  Color? _barColor;
  Color? _trackColor;
  double _trackOpacity = 0.12;
  _RadialBarGradientPreset _gradientPreset = _RadialBarGradientPreset.solid;
  bool _useFixedGradientColors = false;
  Color _gradientStartColor = const Color(0xFF67E8F9);
  Color _gradientEndColor = const Color(0xFF1D4ED8);
  double _gradientStartLightnessShift = 0.18;
  double _gradientEndLightnessShift = -0.12;
  bool _showDataLabels = true;
  RadialBarDataLabelPosition _labelPosition =
      RadialBarDataLabelPosition.insideEnd;
  RadialBarDataLabelContent _labelContent = RadialBarDataLabelContent.value;
  RadialBarDataLabelColorMode _labelColorMode =
      RadialBarDataLabelColorMode.autoContrast;
  Color? _labelColor;
  double _labelSize = 10;
  FontWeight _labelWeight = FontWeight.w700;
  double _labelOffset = 0;
  bool _showCalloutPanel = false;
  Color? _calloutPanelColor;
  Color? _calloutPanelBorderColor;
  double _calloutPanelBorderWidth = 1;
  double _calloutPanelRadius = 4;
  double _calloutPanelPaddingX = 6;
  double _calloutPanelPaddingY = 3;
  Color? _calloutPanelShadowColor;
  double _calloutPanelShadowBlur = 0;
  double _connectorLength = 14;
  double _connectorWidth = 1;
  Color? _connectorColor;

  bool _showCategoryLabels = true;
  RadialBarCategoryLabelPosition _categoryLabelPosition =
      RadialBarCategoryLabelPosition.startGap;
  RadialBarCategoryLabelOrientation _categoryLabelOrientation =
      RadialBarCategoryLabelOrientation.followStartAngle;
  Color? _categoryLabelColor;
  double _categoryLabelSize = 10;
  FontWeight _categoryLabelWeight = FontWeight.w600;
  double _categoryLabelOffset = 8;
  bool _showCategoryPanel = false;
  Color? _categoryPanelColor;
  Color? _categoryPanelBorderColor;
  double _categoryPanelBorderWidth = 1;
  double _categoryPanelRadius = 4;
  double _categoryPanelPaddingX = 6;
  double _categoryPanelPaddingY = 3;
  Color? _categoryPanelShadowColor;
  double _categoryPanelShadowBlur = 0;
  double _categoryConnectorLength = 14;
  double _categoryConnectorWidth = 0;
  Color? _categoryConnectorColor;
  RadialSelectionEffect _selectionEffect = RadialSelectionEffect.explode;
  double _selectionLiftScale = 1.08;
  double _selectionLiftOffset = 6;
  double _selectionBackdropBlur = 1.25;
  bool _showScaleLabels = true;
  bool _showGridLines = true;
  int _tickCount = 5;
  bool _showThreshold = true;
  double _thresholdValue = 75;
  Color? _thresholdColor;
  double _thresholdWidth = 1.5;
  bool _dashedThreshold = true;

  bool _showTooltip = true;
  _RadialBarTooltipPreset _tooltipPreset = _RadialBarTooltipPreset.theme;
  TooltipTriggerMode _tooltipTriggerMode = TooltipTriggerMode.both;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowsPointer = false;
  double _tooltipOffset = 8;
  int _tooltipShowDelayMs = 0;
  int _tooltipHideDelayMs = 200;
  Color? _tooltipBackgroundColor;
  Color? _tooltipTextColor;
  Color? _tooltipBorderColor;
  double _tooltipBorderWidth = 1;
  double _tooltipBorderRadius = 4;
  double _tooltipPadding = 8;
  Color? _tooltipShadowColor;
  double _tooltipShadowBlur = 4;
  double _tooltipFontSize = 12;
  bool _entranceAnimationEnabled = true;
  int _animationDurationMs = 400;
  _RadialBarMotionCurve _animationCurve = _RadialBarMotionCurve.easeInOutCubic;
  int _interactionDurationMs = 150;
  _RadialBarMotionCurve _interactionCurve = _RadialBarMotionCurve.easeOut;
  BravenChartController? _mountedChartController;
  bool _showLegend = true;
  _RadialBarLegendPreset _legendPreset = _RadialBarLegendPreset.theme;
  _RadialBarLegendContent _legendContent = _RadialBarLegendContent.standard;
  LegendPosition _legendPosition = LegendPosition.bottomCenter;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.circle;
  double _legendMarkerSize = 10;
  double _legendFontSize = 10;
  double _legendOpacity = 1;
  Color? _legendPanelColor;
  Color? _legendBorderColor;
  ThemePreset _themePreset = ThemePreset.light;

  @override
  void initState() {
    super.initState();
    _randomizer = ShowcaseRandomizerController<_RandomRadialBarState>(
      generate: _generateRandomState,
      apply: _applyRandomState,
    );
    _applyPresentationState(_presentation);
  }

  @override
  void dispose() {
    _randomizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Radial Bar Charts',
      subtitle:
          'Compare independent category values on concentric tracks and one explicit angular scale',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('radial-bar-reset-example'),
          onPressed: _resetExample,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      playground: ChartPlaygroundConfig(
        active: _playgroundActive,
        optionsChildren: _buildOptions(),
        randomizer: _randomizer,
      ),
      randomizerKeyPrefix: 'radial-bar-randomizer',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final contentHeight = math.max(
          constraints.maxHeight,
          compact ? 980.0 : 800.0,
        );
        final content = SizedBox(
          height: contentHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresentationSelector(),
              const SizedBox(height: 16),
              Expanded(child: _buildChartCard()),
            ],
          ),
        );
        if (contentHeight <= constraints.maxHeight) return content;
        return SingleChildScrollView(
          key: const ValueKey('radial-bar-showcase-scroll'),
          primary: false,
          child: content,
        );
      },
    );
  }

  Widget _buildPresentationSelector() {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Choose a Radial Bar example',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Radial Bar example',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('radial-bar-presentation-selector'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final presentation in _RadialBarPresentation.values)
                    ShowcaseExampleChoiceChip(
                      key: ValueKey(
                        'radial-bar-presentation-${presentation.name}',
                      ),
                      label: presentation.label,
                      icon: presentation.icon,
                      selected:
                          !_playgroundActive && _presentation == presentation,
                      onSelected: () => _applyPresentation(presentation),
                    ),
                  PlaygroundChoiceChip(
                    key: const ValueKey('radial-bar-playground'),
                    selected: _playgroundActive,
                    onSelected: () => _setPlaygroundActive(true),
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
    final config = _buildConfig();
    final theme = _buildTheme();
    final subtitle =
        '${_values.length} independent tracks · '
        '${_minimum.toStringAsFixed(0)}–${_maximum.toStringAsFixed(0)} domain · '
        '${_sweepAngle.toStringAsFixed(0)}° sweep';

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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BravenChartWorkbench(
                initialDisplayMode: ChartDisplayMode.chart,
                availableDisplayModes: const {
                  ChartDisplayMode.chart,
                  ChartDisplayMode.data,
                  ChartDisplayMode.split,
                  ChartDisplayMode.source,
                },
                sourceOptions: const ChartDartSourceOptions(
                  variableName: 'radialBarChart',
                ),
                splitBreakpoint: 1,
                splitGap: 8,
                minimumChartPaneExtent: 340,
                minimumTablePaneExtent: 380,
                maximumAutoTablePaneExtent: 520,
                autoFitTablePane: true,
                isSplitResizable: true,
                documentOptions: const ChartDocumentExtractOptions(
                  includeViewState: true,
                ),
                tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
                chartBuilder: (context, controller) {
                  _mountedChartController = controller;
                  return BravenChartPlus(
                    key: ValueKey('radial-bar-chart-$_chartRevision'),
                    series: [series],
                    radialBarChartConfig: config,
                    bravenChartController: controller,
                    theme: theme,
                    showLegend: _showLegend,
                    radialLegendItemBuilder:
                        _legendContent == _RadialBarLegendContent.valueCards
                        ? _buildValueCardLegendItem
                        : null,
                    interactionConfig: InteractionConfig(
                      tooltip: TooltipConfig(
                        enabled: _showTooltip,
                        triggerMode: _tooltipTriggerMode,
                        preferredPosition: _tooltipPosition,
                        showDelay: Duration(milliseconds: _tooltipShowDelayMs),
                        hideDelay: Duration(milliseconds: _tooltipHideDelayMs),
                        followCursor: _tooltipFollowsPointer,
                        offsetFromPoint: _tooltipOffset,
                        style: _resolvedTooltipStyle(theme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCardLegendItem(
    BuildContext context,
    RadialLegendItemData item,
  ) => RadialLegendValueCard(
    key: ValueKey('radial-bar-custom-legend-item-${item.visibleIndex}'),
    item: item,
    showShare: false,
  );

  RadialBarChartSeries _buildSeries() {
    final palette = _themePreset.theme.seriesTheme.colors;
    final colors = <String, Color>{
      for (final (index, category) in _values.keys.indexed)
        category: _barColor ?? palette[index % palette.length],
    };
    return RadialBarChartSeries.fromMap(
      id: 'radial-bar-showcase',
      name: _chartTitle,
      values: _values,
      barColors: colors,
      minimum: _minimum,
      maximum: _maximum,
      baseline: _baseline,
      unit: _minimum < 0 ? 'pts' : '%',
      radialBarStyle: RadialBarStyle(
        cornerRadius: _cornerRadius,
        opacity: _markOpacity,
        borderColor: _borderColor,
        borderWidth: _borderWidth,
        trackColor: _trackColor,
        trackOpacity: _trackOpacity,
        gradient: _radialBarGradient,
        showDataLabels: _showDataLabels,
        dataLabels: RadialBarDataLabelConfig(
          position: _labelPosition,
          content: _labelContent,
          colorMode: _labelColorMode,
          textStyle: PolarLabelStyle(
            color: _labelColor,
            fontSize: _labelSize,
            fontWeight: _labelWeight,
          ),
          offset: _labelOffset,
          showPanel: _showCalloutPanel,
          panelStyle: _showCalloutPanel
              ? LabelStyle(
                  textStyle: const TextStyle(),
                  backgroundColor:
                      _calloutPanelColor ??
                      _themePreset.theme.backgroundColor.withValues(
                        alpha: 0.96,
                      ),
                  borderColor:
                      _calloutPanelBorderColor ??
                      _themePreset.theme.gridStyle.majorColor,
                  borderWidth: _calloutPanelBorderWidth,
                  borderRadius: _calloutPanelRadius,
                  padding: EdgeInsets.symmetric(
                    horizontal: _calloutPanelPaddingX,
                    vertical: _calloutPanelPaddingY,
                  ),
                  shadowColor: _calloutPanelShadowColor,
                  shadowBlurRadius: _calloutPanelShadowColor == null
                      ? null
                      : _calloutPanelShadowBlur,
                )
              : null,
          connectorLength: _connectorLength,
          connectorWidth: _connectorWidth,
          connectorColor: _connectorColor,
        ),
      ),
      selectionStyle: RadialSelectionStyle(
        effect: _selectionEffect,
        liftScale: _selectionLiftScale,
        liftOffset: _selectionLiftOffset,
        backdropBlur: _selectionBackdropBlur,
      ),
    );
  }

  RadialBarGradientStyle? get _radialBarGradient => switch (_gradientPreset) {
    _RadialBarGradientPreset.solid => null,
    _RadialBarGradientPreset.sweep => RadialBarGradientStyle(
      type: RadialBarGradientType.sweep,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartLightnessShift,
      endLightnessShift: _gradientEndLightnessShift,
    ),
    _RadialBarGradientPreset.radial => RadialBarGradientStyle(
      type: RadialBarGradientType.radial,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartLightnessShift,
      endLightnessShift: _gradientEndLightnessShift,
    ),
  };

  ChartTheme _buildTheme() {
    final base = _themePreset.theme;
    final legendBase = base.legendStyle.copyWith(
      position: _legendPosition,
      orientation: _legendOrientation,
      markerShape: _legendMarkerShape,
      markerSize: _legendMarkerSize,
      textStyle: base.legendStyle.textStyle.copyWith(fontSize: _legendFontSize),
      opacity: _legendOpacity,
      markerLabelSpacing: 8,
    );
    final legendStyle = switch (_legendPreset) {
      _RadialBarLegendPreset.theme => legendBase,
      _RadialBarLegendPreset.compact => legendBase.copyWith(
        markerLabelSpacing: 5,
        itemSpacing: 3,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      _RadialBarLegendPreset.surface => legendBase.copyWith(
        textStyle: legendBase.textStyle.copyWith(fontWeight: FontWeight.w600),
        backgroundColor:
            _legendPanelColor ?? base.backgroundColor.withValues(alpha: 0.94),
        borderColor:
            _legendBorderColor ??
            base.axisStyle.lineColor.withValues(alpha: 0.42),
        borderWidth: 1,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemSpacing: 8,
      ),
    };
    return base.copyWith(
      legendStyle: legendStyle,
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: _entranceAnimationEnabled
            ? Duration(milliseconds: _animationDurationMs)
            : Duration.zero,
        dataUpdateCurve: _motionCurve(_animationCurve),
        interactionDuration: Duration(milliseconds: _interactionDurationMs),
        interactionCurve: _motionCurve(_interactionCurve),
      ),
    );
  }

  LabelStyle _tooltipPresetStyle(ChartTheme theme) => switch (_tooltipPreset) {
    _RadialBarTooltipPreset.theme => theme.interactionTheme.tooltipStyle,
    _RadialBarTooltipPreset.elevated =>
      theme.interactionTheme.tooltipStyle.copyWith(
        borderRadius: 10,
        borderWidth: 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shadowColor: const Color(0x401A1A1A),
        shadowBlurRadius: 12,
      ),
    _RadialBarTooltipPreset.contrast => LabelStyle(
      textStyle: TextStyle(
        color: theme.backgroundColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor:
          theme.axisStyle.labelStyle.color ?? const Color(0xFF1A1A1A),
      borderColor: theme.backgroundColor.withValues(alpha: 0.72),
      borderWidth: 1,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shadowColor: const Color(0x4D1A1A1A),
      shadowBlurRadius: 8,
    ),
  };

  TooltipStyle _resolvedTooltipStyle(ChartTheme theme) {
    final preset = _tooltipPresetStyle(theme);
    return TooltipStyle(
      backgroundColor: _tooltipBackgroundColor ?? preset.backgroundColor,
      borderColor: _tooltipBorderColor ?? preset.borderColor,
      borderWidth: _tooltipBorderWidth,
      borderRadius: _tooltipBorderRadius,
      shadowColor:
          _tooltipShadowColor ?? preset.shadowColor ?? const Color(0x00000000),
      shadowBlurRadius: _tooltipShadowBlur,
      padding: _tooltipPadding,
      textColor:
          _tooltipTextColor ??
          preset.textStyle.color ??
          const Color(0xFF333333),
      fontSize: _tooltipFontSize,
    );
  }

  Curve _motionCurve(_RadialBarMotionCurve value) => switch (value) {
    _RadialBarMotionCurve.linear => Curves.linear,
    _RadialBarMotionCurve.easeOut => Curves.easeOut,
    _RadialBarMotionCurve.easeOutCubic => Curves.easeOutCubic,
    _RadialBarMotionCurve.easeInOutCubic => Curves.easeInOutCubic,
  };

  RadialBarChartConfig _buildConfig() {
    final chartTheme = _themePreset.theme;
    return RadialBarChartConfig(
      pane: PolarPaneConfig(
        startAngleDegrees: _startAngle,
        sweepAngleDegrees: _sweepAngle,
        clockwise: _clockwise,
        innerRadiusFactor: _innerRadius,
        outerRadiusFactor: _outerRadius,
      ),
      trackGap: _trackGap,
      trackOrder: _trackOrder,
      showCategoryLabels: _showCategoryLabels,
      categoryLabels: RadialBarCategoryLabelConfig(
        position: _categoryLabelPosition,
        orientation: _categoryLabelOrientation,
        offset: _categoryLabelOffset,
        textStyle: PolarLabelStyle(
          color: _categoryLabelColor,
          fontSize: _categoryLabelSize,
          fontWeight: _categoryLabelWeight,
        ),
        showPanel: _showCategoryPanel,
        panelStyle: _showCategoryPanel
            ? LabelStyle(
                textStyle: const TextStyle(),
                backgroundColor:
                    _categoryPanelColor ??
                    chartTheme.backgroundColor.withValues(alpha: 0.94),
                borderColor:
                    _categoryPanelBorderColor ??
                    chartTheme.gridStyle.majorColor,
                borderWidth: _categoryPanelBorderWidth,
                borderRadius: _categoryPanelRadius,
                padding: EdgeInsets.symmetric(
                  horizontal: _categoryPanelPaddingX,
                  vertical: _categoryPanelPaddingY,
                ),
                shadowColor: _categoryPanelShadowColor,
                shadowBlurRadius: _categoryPanelShadowColor == null
                    ? null
                    : _categoryPanelShadowBlur,
              )
            : null,
        connectorLength: _categoryConnectorLength,
        connectorWidth: _categoryConnectorWidth,
        connectorColor: _categoryConnectorColor,
      ),
      showScaleLabels: _showScaleLabels,
      showGridLines: _showGridLines,
      tickCount: _tickCount,
      thresholds: _showThreshold
          ? [
              RadialBarThreshold(
                value: _thresholdValue.clamp(_minimum, _maximum),
                label: 'Target ${_thresholdValue.toStringAsFixed(0)}',
                color: _thresholdColor,
                width: _thresholdWidth,
                dashPattern: _dashedThreshold ? const [6, 4] : const [],
              ),
            ]
          : const [],
    );
  }

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Chart appearance',
      icon: Icons.palette_outlined,
      description:
          'Select the chart theme and optionally override the category marks, tracks, and borders.',
      children: [
        EnumOption<ThemePreset>(
          label: 'Theme',
          value: _themePreset,
          values: ThemePreset.values,
          labelBuilder: (value) => value.displayName,
          onChanged: (value) => setState(() => _themePreset = value),
        ),
        PaletteColorOption(
          label: 'Bar color override',
          subtitle: 'Clear to use a distinct color for every category.',
          value: _barColor,
          keyPrefix: 'radial-bar-mark-color',
          customColorFallback: const Color(0xFF2563EB),
          onChanged: (value) => setState(() => _barColor = value),
        ),
        PaletteColorOption(
          label: 'Track color',
          subtitle: 'Clear to derive the track from each mark color.',
          value: _trackColor,
          keyPrefix: 'radial-bar-track-color',
          customColorFallback: const Color(0xFF94A3B8),
          onChanged: (value) => setState(() => _trackColor = value),
        ),
        PaletteColorOption(
          label: 'Border color',
          value: _borderColor,
          enabled: _borderWidth > 0,
          onEnabledChanged: (enabled) => setState(() {
            _borderWidth = enabled ? math.max(_borderWidth, 1) : 0;
          }),
          keyPrefix: 'radial-bar-border-color',
          customColorFallback: const Color(0xFF0F172A),
          onChanged: (value) => setState(() => _borderColor = value),
        ),
        EnumOption<_RadialBarGradientPreset>(
          key: const ValueKey('radial-bar-gradient'),
          label: 'Mark fill',
          value: _gradientPreset,
          values: _RadialBarGradientPreset.values,
          labelBuilder: _gradientPresetName,
          onChanged: (value) => setState(() => _gradientPreset = value),
        ),
        if (_gradientPreset != _RadialBarGradientPreset.solid) ...[
          BoolOption(
            key: const ValueKey('radial-bar-fixed-gradient-colors'),
            label: 'Use fixed gradient colors',
            value: _useFixedGradientColors,
            onChanged: (value) =>
                setState(() => _useFixedGradientColors = value),
          ),
          if (_useFixedGradientColors) ...[
            PaletteColorOption(
              key: const ValueKey('radial-bar-gradient-start-color'),
              label: 'Gradient start',
              value: _gradientStartColor,
              keyPrefix: 'radial-bar-gradient-start',
              customColorFallback: const Color(0xFF67E8F9),
              onChanged: (value) => setState(
                () => _gradientStartColor = value ?? const Color(0xFF67E8F9),
              ),
            ),
            PaletteColorOption(
              key: const ValueKey('radial-bar-gradient-end-color'),
              label: 'Gradient end',
              value: _gradientEndColor,
              keyPrefix: 'radial-bar-gradient-end',
              customColorFallback: const Color(0xFF1D4ED8),
              onChanged: (value) => setState(
                () => _gradientEndColor = value ?? const Color(0xFF1D4ED8),
              ),
            ),
          ] else ...[
            SliderOption(
              key: const ValueKey('radial-bar-gradient-start-shift'),
              label: 'Start lightness',
              value: _gradientStartLightnessShift * 100,
              min: -50,
              max: 50,
              divisions: 20,
              suffix: '%',
              onChanged: (value) =>
                  setState(() => _gradientStartLightnessShift = value / 100),
            ),
            SliderOption(
              key: const ValueKey('radial-bar-gradient-end-shift'),
              label: 'End lightness',
              value: _gradientEndLightnessShift * 100,
              min: -50,
              max: 50,
              divisions: 20,
              suffix: '%',
              onChanged: (value) =>
                  setState(() => _gradientEndLightnessShift = value / 100),
            ),
          ],
        ],
      ],
    ),
    OptionSection(
      title: 'Polar geometry',
      icon: Icons.donut_small_outlined,
      description:
          'Controls the angular pane and the annular space available to category tracks.',
      children: [
        SliderOption(
          label: 'Start angle',
          value: _startAngle,
          min: -180,
          max: 180,
          divisions: 36,
          suffix: '°',
          onChanged: (value) => setState(() => _startAngle = value),
        ),
        SliderOption(
          label: 'Sweep angle',
          value: _sweepAngle,
          min: 90,
          max: 360,
          divisions: 27,
          suffix: '°',
          onChanged: (value) => setState(() => _sweepAngle = value),
        ),
        BoolOption(
          label: 'Clockwise',
          value: _clockwise,
          onChanged: (value) => setState(() => _clockwise = value),
        ),
        SliderOption(
          label: 'Inner radius',
          value: _innerRadius,
          min: 0,
          max: math.max(0, _outerRadius - 0.1),
          divisions: 16,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _innerRadius = value),
        ),
        SliderOption(
          label: 'Outer radius',
          value: _outerRadius,
          min: math.min(1, _innerRadius + 0.1),
          max: 1,
          divisions: 16,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _outerRadius = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Tracks and marks',
      icon: Icons.view_stream_outlined,
      description:
          'Adjust track order, physical separation, rounded ends, opacity, and mark borders.',
      children: [
        EnumOption<RadialBarTrackOrder>(
          label: 'Track order',
          value: _trackOrder,
          values: RadialBarTrackOrder.values,
          labelBuilder: (value) => switch (value) {
            RadialBarTrackOrder.outerToInner => 'First category outside',
            RadialBarTrackOrder.innerToOuter => 'First category inside',
          },
          onChanged: (value) => setState(() => _trackOrder = value),
        ),
        SliderOption(
          label: 'Track gap',
          value: _trackGap,
          min: 0,
          max: 18,
          divisions: 18,
          suffix: 'px',
          onChanged: (value) => setState(() => _trackGap = value),
        ),
        SliderOption(
          label: 'Corner radius',
          value: _cornerRadius,
          min: 0,
          max: 20,
          divisions: 20,
          suffix: 'px',
          onChanged: (value) => setState(() => _cornerRadius = value),
        ),
        SliderOption(
          label: 'Mark opacity',
          value: _markOpacity,
          min: 0.1,
          max: 1,
          divisions: 18,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _markOpacity = value),
        ),
        SliderOption(
          label: 'Track opacity',
          value: _trackOpacity,
          min: 0,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _trackOpacity = value),
        ),
        SliderOption(
          label: 'Border width',
          value: _borderWidth,
          min: 0,
          max: 4,
          divisions: 8,
          suffix: 'px',
          onChanged: (value) => setState(() => _borderWidth = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Value labels',
      icon: Icons.label_outline,
      description:
          'Choose measured inside labels or collision-managed outside callouts, then style their content and typography.',
      children: [
        BoolOption(
          label: 'Show value labels',
          value: _showDataLabels,
          onChanged: (value) => setState(() => _showDataLabels = value),
        ),
        EnumOption<RadialBarDataLabelPosition>(
          label: 'Label position',
          value: _labelPosition,
          values: RadialBarDataLabelPosition.values,
          labelBuilder: (value) => switch (value) {
            RadialBarDataLabelPosition.insideEnd => 'Inside end',
            RadialBarDataLabelPosition.outsideCallout => 'Outside callout',
          },
          onChanged: (value) => setState(() => _labelPosition = value),
        ),
        EnumOption<RadialBarDataLabelContent>(
          label: 'Label content',
          value: _labelContent,
          values: RadialBarDataLabelContent.values,
          labelBuilder: (value) => switch (value) {
            RadialBarDataLabelContent.value => 'Value',
            RadialBarDataLabelContent.category => 'Category',
            RadialBarDataLabelContent.categoryAndValue => 'Category + value',
          },
          onChanged: (value) => setState(() => _labelContent = value),
        ),
        EnumOption<RadialBarDataLabelColorMode>(
          label: 'Label color mode',
          description:
              'Auto selects accessible black or white text independently for each rendered mark or callout background.',
          value: _labelColorMode,
          values: RadialBarDataLabelColorMode.values,
          labelBuilder: (value) => switch (value) {
            RadialBarDataLabelColorMode.autoContrast =>
              'Auto contrast (mark/background)',
            RadialBarDataLabelColorMode.fixed => 'Fixed color',
          },
          onChanged: (value) => setState(() {
            _labelColorMode = value;
            if (value == RadialBarDataLabelColorMode.autoContrast) {
              _labelColor = null;
            } else {
              _labelColor ??= const Color(0xFF0F172A);
            }
          }),
        ),
        PaletteColorOption(
          label: 'Label color',
          subtitle: _labelColorMode == RadialBarDataLabelColorMode.autoContrast
              ? 'Choose a swatch to switch to a fixed color.'
              : 'Clear the color to restore automatic contrast.',
          value: _labelColor,
          keyPrefix: 'radial-bar-label-color',
          customColorFallback: const Color(0xFF0F172A),
          onChanged: (value) => setState(() {
            _labelColor = value;
            _labelColorMode = value == null
                ? RadialBarDataLabelColorMode.autoContrast
                : RadialBarDataLabelColorMode.fixed;
          }),
        ),
        SliderOption(
          label: 'Label size',
          value: _labelSize,
          min: 8,
          max: 24,
          divisions: 16,
          suffix: 'px',
          onChanged: (value) => setState(() => _labelSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Label weight',
          value: _labelWeight,
          values: const [
            FontWeight.w400,
            FontWeight.w500,
            FontWeight.w600,
            FontWeight.w700,
            FontWeight.w800,
          ],
          labelBuilder: (value) => switch (value) {
            FontWeight.w400 => 'Regular',
            FontWeight.w500 => 'Medium',
            FontWeight.w600 => 'Semi-bold',
            FontWeight.w700 => 'Bold',
            FontWeight.w800 => 'Extra-bold',
            _ => value.toString(),
          },
          onChanged: (value) => setState(() => _labelWeight = value),
        ),
        SliderOption(
          label: _labelPosition == RadialBarDataLabelPosition.insideEnd
              ? 'End inset'
              : 'Callout offset',
          value: _labelOffset,
          min: 0,
          max: 40,
          divisions: 40,
          suffix: 'px',
          onChanged: (value) => setState(() => _labelOffset = value),
        ),
        if (_labelPosition == RadialBarDataLabelPosition.outsideCallout) ...[
          BoolOption(
            label: 'Label panel',
            description:
                'Place each callout on a background panel while preserving its connector and collision-managed lane.',
            value: _showCalloutPanel,
            onChanged: (value) => setState(() => _showCalloutPanel = value),
          ),
          if (_showCalloutPanel) ...[
            PaletteColorOption(
              label: 'Panel fill',
              subtitle: 'Clear to derive the panel from the chart theme.',
              value: _calloutPanelColor,
              keyPrefix: 'radial-bar-callout-panel-fill',
              customColorFallback: const Color(0xFFF8FAFC),
              onChanged: (value) => setState(() => _calloutPanelColor = value),
            ),
            PaletteColorOption(
              label: 'Panel border',
              subtitle: 'Clear to derive the border from the chart theme.',
              value: _calloutPanelBorderColor,
              keyPrefix: 'radial-bar-callout-panel-border',
              customColorFallback: const Color(0xFFCBD5E1),
              onChanged: (value) =>
                  setState(() => _calloutPanelBorderColor = value),
            ),
            SliderOption(
              label: 'Panel border width',
              value: _calloutPanelBorderWidth,
              min: 0,
              max: 4,
              divisions: 16,
              suffix: 'px',
              onChanged: (value) =>
                  setState(() => _calloutPanelBorderWidth = value),
            ),
            SliderOption(
              label: 'Panel radius',
              value: _calloutPanelRadius,
              min: 0,
              max: 16,
              divisions: 16,
              suffix: 'px',
              onChanged: (value) => setState(() => _calloutPanelRadius = value),
            ),
            SliderOption(
              label: 'Panel horizontal padding',
              value: _calloutPanelPaddingX,
              min: 0,
              max: 20,
              divisions: 20,
              suffix: 'px',
              onChanged: (value) =>
                  setState(() => _calloutPanelPaddingX = value),
            ),
            SliderOption(
              label: 'Panel vertical padding',
              value: _calloutPanelPaddingY,
              min: 0,
              max: 16,
              divisions: 16,
              suffix: 'px',
              onChanged: (value) =>
                  setState(() => _calloutPanelPaddingY = value),
            ),
            PaletteColorOption(
              label: 'Panel shadow',
              subtitle: 'Clear to remove the callout shadow.',
              value: _calloutPanelShadowColor,
              keyPrefix: 'radial-bar-callout-panel-shadow',
              customColorFallback: const Color(0x660F172A),
              onChanged: (value) =>
                  setState(() => _calloutPanelShadowColor = value),
            ),
            if (_calloutPanelShadowColor != null)
              SliderOption(
                label: 'Panel shadow blur',
                value: _calloutPanelShadowBlur,
                min: 0,
                max: 24,
                divisions: 24,
                suffix: 'px',
                onChanged: (value) =>
                    setState(() => _calloutPanelShadowBlur = value),
              ),
          ],
          SliderOption(
            label: 'Connector length',
            value: _connectorLength,
            min: 0,
            max: 40,
            divisions: 40,
            suffix: 'px',
            onChanged: (value) => setState(() => _connectorLength = value),
          ),
          SliderOption(
            label: 'Connector width',
            value: _connectorWidth,
            min: 0,
            max: 4,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) => setState(() => _connectorWidth = value),
          ),
          PaletteColorOption(
            label: 'Connector color',
            subtitle: 'Clear to match each category mark.',
            value: _connectorColor,
            keyPrefix: 'radial-bar-label-connector-color',
            customColorFallback: const Color(0xFF64748B),
            onChanged: (value) => setState(() => _connectorColor = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Category labels',
      icon: Icons.account_tree_outlined,
      description:
          'Keeps every category visibly attached to its owning track start, with optional panels and explicit outside callouts.',
      children: [
        BoolOption(
          label: 'Show category labels',
          value: _showCategoryLabels,
          onChanged: (value) => setState(() => _showCategoryLabels = value),
        ),
        EnumOption<RadialBarCategoryLabelPosition>(
          label: 'Category position',
          description:
              'Track start keeps category ownership at every angle. Outside callouts are an explicit alternative.',
          value: _categoryLabelPosition,
          values: RadialBarCategoryLabelPosition.values,
          labelBuilder: (value) => switch (value) {
            RadialBarCategoryLabelPosition.outsideCallout => 'Outside labels',
            RadialBarCategoryLabelPosition.startGap => 'At track start',
            RadialBarCategoryLabelPosition.legacyOnTrack => 'Legacy on track',
          },
          onChanged: (value) => setState(() {
            _categoryLabelPosition = value;
            if (value == RadialBarCategoryLabelPosition.outsideCallout &&
                _categoryConnectorWidth == 0) {
              _categoryConnectorWidth = 1;
            }
          }),
        ),
        if (_categoryLabelPosition == RadialBarCategoryLabelPosition.startGap)
          EnumOption<RadialBarCategoryLabelOrientation>(
            label: 'Category orientation',
            description:
                'Adaptive orientation keeps labels attached to their track starts and snaps them horizontal or vertical for readability.',
            value: _categoryLabelOrientation,
            values: RadialBarCategoryLabelOrientation.values,
            labelBuilder: (value) => switch (value) {
              RadialBarCategoryLabelOrientation.followStartAngle =>
                'Adaptive orientation',
              RadialBarCategoryLabelOrientation.horizontal => 'Horizontal',
            },
            onChanged: (value) =>
                setState(() => _categoryLabelOrientation = value),
          ),
        PaletteColorOption(
          label: 'Category text color',
          subtitle: 'Clear to inherit the active chart theme.',
          value: _categoryLabelColor,
          keyPrefix: 'radial-bar-category-label-color',
          customColorFallback: const Color(0xFF0F172A),
          onChanged: (value) => setState(() => _categoryLabelColor = value),
        ),
        SliderOption(
          label: 'Category text size',
          value: _categoryLabelSize,
          min: 8,
          max: 24,
          divisions: 16,
          suffix: 'px',
          onChanged: (value) => setState(() => _categoryLabelSize = value),
        ),
        EnumOption<FontWeight>(
          label: 'Category text weight',
          value: _categoryLabelWeight,
          values: const [
            FontWeight.w400,
            FontWeight.w500,
            FontWeight.w600,
            FontWeight.w700,
            FontWeight.w800,
          ],
          labelBuilder: (value) => switch (value) {
            FontWeight.w400 => 'Regular',
            FontWeight.w500 => 'Medium',
            FontWeight.w600 => 'Semi-bold',
            FontWeight.w700 => 'Bold',
            FontWeight.w800 => 'Extra-bold',
            _ => value.toString(),
          },
          onChanged: (value) => setState(() => _categoryLabelWeight = value),
        ),
        SliderOption(
          label: 'Category label offset',
          value: _categoryLabelOffset,
          min: 0,
          max: 40,
          divisions: 40,
          suffix: 'px',
          onChanged: (value) => setState(() => _categoryLabelOffset = value),
        ),
        BoolOption(
          label: 'Label background panel',
          value: _showCategoryPanel,
          onChanged: (value) => setState(() => _showCategoryPanel = value),
        ),
        if (_showCategoryPanel) ...[
          PaletteColorOption(
            label: 'Panel fill color',
            subtitle: 'Clear to derive the surface from the active theme.',
            value: _categoryPanelColor,
            keyPrefix: 'radial-bar-category-panel-fill',
            customColorFallback: Colors.white,
            onChanged: (value) => setState(() => _categoryPanelColor = value),
          ),
          PaletteColorOption(
            label: 'Panel border color',
            subtitle: 'Clear to derive the border from the active theme.',
            value: _categoryPanelBorderColor,
            keyPrefix: 'radial-bar-category-panel-border',
            customColorFallback: const Color(0xFFCBD5E1),
            onChanged: (value) =>
                setState(() => _categoryPanelBorderColor = value),
          ),
          SliderOption(
            label: 'Panel border width',
            value: _categoryPanelBorderWidth,
            min: 0,
            max: 4,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _categoryPanelBorderWidth = value),
          ),
          SliderOption(
            label: 'Panel corner radius',
            value: _categoryPanelRadius,
            min: 0,
            max: 16,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) => setState(() => _categoryPanelRadius = value),
          ),
          SliderOption(
            label: 'Panel horizontal padding',
            value: _categoryPanelPaddingX,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _categoryPanelPaddingX = value),
          ),
          SliderOption(
            label: 'Panel vertical padding',
            value: _categoryPanelPaddingY,
            min: 0,
            max: 16,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _categoryPanelPaddingY = value),
          ),
          PaletteColorOption(
            label: 'Panel shadow',
            subtitle: 'Clear to remove the category-label shadow.',
            value: _categoryPanelShadowColor,
            keyPrefix: 'radial-bar-category-panel-shadow',
            customColorFallback: const Color(0x660F172A),
            onChanged: (value) =>
                setState(() => _categoryPanelShadowColor = value),
          ),
          if (_categoryPanelShadowColor != null)
            SliderOption(
              label: 'Panel shadow blur',
              value: _categoryPanelShadowBlur,
              min: 0,
              max: 24,
              divisions: 24,
              suffix: 'px',
              onChanged: (value) =>
                  setState(() => _categoryPanelShadowBlur = value),
            ),
        ],
        if (_categoryLabelPosition ==
            RadialBarCategoryLabelPosition.outsideCallout) ...[
          BoolOption(
            label: 'Callout leaders',
            subtitle:
                'Optional category-coloured leaders; off avoids crossing unrelated concentric tracks.',
            value: _categoryConnectorWidth > 0,
            onChanged: (value) =>
                setState(() => _categoryConnectorWidth = value ? 1 : 0),
          ),
          if (_categoryConnectorWidth > 0) ...[
            SliderOption(
              label: 'Category connector length',
              value: _categoryConnectorLength,
              min: 0,
              max: 40,
              divisions: 40,
              suffix: 'px',
              onChanged: (value) =>
                  setState(() => _categoryConnectorLength = value),
            ),
            SliderOption(
              label: 'Category connector width',
              value: _categoryConnectorWidth,
              min: 0.25,
              max: 4,
              divisions: 15,
              suffix: 'px',
              onChanged: (value) =>
                  setState(() => _categoryConnectorWidth = value),
            ),
            PaletteColorOption(
              label: 'Category connector color',
              subtitle: 'Clear to match each category mark.',
              value: _categoryConnectorColor,
              keyPrefix: 'radial-bar-category-connector-color',
              customColorFallback: const Color(0xFF64748B),
              onChanged: (value) =>
                  setState(() => _categoryConnectorColor = value),
            ),
          ],
        ],
      ],
    ),
    OptionSection(
      title: 'Scale and target',
      icon: Icons.straighten_outlined,
      description:
          'Configures the shared numeric angular scale, scale labels, grid rings, and absolute target guide.',
      children: [
        BoolOption(
          label: 'Scale labels',
          value: _showScaleLabels,
          onChanged: (value) => setState(() => _showScaleLabels = value),
        ),
        BoolOption(
          label: 'Grid lines',
          value: _showGridLines,
          onChanged: (value) => setState(() => _showGridLines = value),
        ),
        IntSliderOption(
          label: 'Tick count',
          value: _tickCount,
          min: 2,
          max: 12,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
        BoolOption(
          label: 'Target guide',
          value: _showThreshold,
          onChanged: (value) => setState(() => _showThreshold = value),
        ),
        if (_showThreshold) ...[
          SliderOption(
            label: 'Target value',
            value: _thresholdValue.clamp(_minimum, _maximum),
            min: _minimum,
            max: _maximum,
            divisions: 40,
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _thresholdValue = value),
          ),
          SliderOption(
            label: 'Target width',
            value: _thresholdWidth,
            min: 0.5,
            max: 5,
            divisions: 9,
            suffix: 'px',
            onChanged: (value) => setState(() => _thresholdWidth = value),
          ),
          BoolOption(
            label: 'Dashed target',
            value: _dashedThreshold,
            onChanged: (value) => setState(() => _dashedThreshold = value),
          ),
          PaletteColorOption(
            label: 'Target color',
            value: _thresholdColor,
            keyPrefix: 'radial-bar-threshold-color',
            customColorFallback: const Color(0xFFDC2626),
            onChanged: (value) => setState(() => _thresholdColor = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Selection',
      icon: Icons.touch_app_outlined,
      description:
          'Choose how a durably selected category track separates from the remaining radial composition.',
      initiallyExpanded: false,
      children: [
        EnumOption<RadialSelectionEffect>(
          label: 'Selected track',
          value: _selectionEffect,
          values: RadialSelectionEffect.values,
          labelBuilder: (value) => switch (value) {
            RadialSelectionEffect.explode => 'Pull outward',
            RadialSelectionEffect.lift => 'Lift towards viewer',
          },
          onChanged: (value) => setState(() => _selectionEffect = value),
        ),
        SliderOption(
          label: 'Lift offset',
          value: _selectionLiftOffset,
          min: 0,
          max: 24,
          divisions: 24,
          suffix: 'px',
          onChanged: (value) => setState(() => _selectionLiftOffset = value),
        ),
        if (_selectionEffect == RadialSelectionEffect.lift) ...[
          SliderOption(
            label: 'Lift scale',
            value: _selectionLiftScale * 100,
            min: 100,
            max: 125,
            divisions: 25,
            suffix: '%',
            onChanged: (value) =>
                setState(() => _selectionLiftScale = value / 100),
          ),
          SliderOption(
            label: 'Backdrop blur',
            value: _selectionBackdropBlur,
            min: 0,
            max: 8,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _selectionBackdropBlur = value),
          ),
        ],
        const InfoBox(
          message:
              'Select a track on the chart, in the data table, or from the legend to inspect the shared treatment.',
        ),
      ],
    ),
    OptionSection(
      title: 'Interaction',
      icon: Icons.touch_app_outlined,
      description:
          'Radial Bar uses the shared chart hit testing, focus, selection, keyboard, and tooltip contracts.',
      initiallyExpanded: false,
      children: [
        BoolOption(
          label: 'Data point popup',
          value: _showTooltip,
          onChanged: (value) => setState(() => _showTooltip = value),
        ),
        if (_showTooltip) ...[
          EnumOption<_RadialBarTooltipPreset>(
            key: const ValueKey('radial-bar-tooltip-style'),
            label: 'Popup style',
            value: _tooltipPreset,
            values: _RadialBarTooltipPreset.values,
            labelBuilder: _tooltipPresetName,
            onChanged: _setTooltipPreset,
          ),
          EnumOption<TooltipTriggerMode>(
            key: const ValueKey('radial-bar-tooltip-trigger'),
            label: 'Popup trigger',
            value: _tooltipTriggerMode,
            values: TooltipTriggerMode.values,
            labelBuilder: (value) => switch (value) {
              TooltipTriggerMode.hover => 'Hover / touch hold',
              TooltipTriggerMode.tap => 'Tap / click',
              TooltipTriggerMode.both => 'Hover and tap',
            },
            onChanged: (value) => setState(() => _tooltipTriggerMode = value),
          ),
          EnumOption<TooltipPosition>(
            key: const ValueKey('radial-bar-tooltip-position'),
            label: 'Preferred position',
            value: _tooltipPosition,
            values: TooltipPosition.values,
            labelBuilder: _tooltipPositionName,
            onChanged: (value) => setState(() => _tooltipPosition = value),
          ),
          BoolOption(
            key: const ValueKey('radial-bar-tooltip-follow-pointer'),
            label: 'Follow pointer',
            value: _tooltipFollowsPointer,
            onChanged: (value) =>
                setState(() => _tooltipFollowsPointer = value),
          ),
          SliderOption(
            key: const ValueKey('radial-bar-tooltip-offset'),
            label: 'Point offset',
            value: _tooltipOffset,
            min: 0,
            max: 24,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _tooltipOffset = value),
          ),
          IntSliderOption(
            label: 'Show delay',
            value: _tooltipShowDelayMs,
            min: 0,
            max: 1000,
            suffix: 'ms',
            onChanged: (value) => setState(() => _tooltipShowDelayMs = value),
          ),
          IntSliderOption(
            label: 'Hide delay',
            value: _tooltipHideDelayMs,
            min: 0,
            max: 1000,
            suffix: 'ms',
            onChanged: (value) => setState(() => _tooltipHideDelayMs = value),
          ),
          PaletteColorOption(
            label: 'Popup background',
            subtitle: 'Clear to derive the surface from the selected preset.',
            value: _tooltipBackgroundColor,
            keyPrefix: 'radial-bar-tooltip-background',
            customColorFallback: const Color(0xFFF8FAFC),
            onChanged: (value) =>
                setState(() => _tooltipBackgroundColor = value),
          ),
          PaletteColorOption(
            label: 'Popup text color',
            subtitle: 'Clear to derive text contrast from the selected preset.',
            value: _tooltipTextColor,
            keyPrefix: 'radial-bar-tooltip-text',
            customColorFallback: const Color(0xFF0F172A),
            onChanged: (value) => setState(() => _tooltipTextColor = value),
          ),
          SliderOption(
            label: 'Popup text size',
            value: _tooltipFontSize,
            min: 8,
            max: 24,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipFontSize = value),
          ),
          PaletteColorOption(
            label: 'Popup border',
            subtitle: 'Clear to derive the border from the selected preset.',
            value: _tooltipBorderColor,
            keyPrefix: 'radial-bar-tooltip-border',
            customColorFallback: const Color(0xFF64748B),
            onChanged: (value) => setState(() => _tooltipBorderColor = value),
          ),
          SliderOption(
            label: 'Popup border width',
            value: _tooltipBorderWidth,
            min: 0,
            max: 4,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipBorderWidth = value),
          ),
          SliderOption(
            label: 'Popup corner radius',
            value: _tooltipBorderRadius,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipBorderRadius = value),
          ),
          SliderOption(
            label: 'Popup padding',
            value: _tooltipPadding,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipPadding = value),
          ),
          PaletteColorOption(
            label: 'Popup shadow',
            subtitle: 'Clear to remove the popup shadow.',
            value: _tooltipShadowColor,
            keyPrefix: 'radial-bar-tooltip-shadow',
            customColorFallback: const Color(0x660F172A),
            onChanged: (value) => setState(() => _tooltipShadowColor = value),
          ),
          SliderOption(
            label: 'Popup shadow blur',
            value: _tooltipShadowBlur,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipShadowBlur = value),
          ),
        ],
        const InfoBox(
          message:
              'Hover or tap a track to inspect it. Every portable TooltipConfig and TooltipStyle property is editable here; customBuilder remains application-owned runtime code.',
        ),
      ],
    ),
    OptionSection(
      title: 'Motion',
      icon: Icons.animation_outlined,
      description:
          'Controls the real baseline-growth entrance and the shared hover and selection response timing.',
      initiallyExpanded: false,
      children: [
        BoolOption(
          key: const ValueKey('radial-bar-entrance-enabled'),
          label: 'Entrance animation',
          value: _entranceAnimationEnabled,
          onChanged: (value) {
            setState(() => _entranceAnimationEnabled = value);
            if (value) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _mountedChartController?.replayRadialEntrance(),
              );
            }
          },
        ),
        if (_entranceAnimationEnabled) ...[
          IntSliderOption(
            key: const ValueKey('radial-bar-animation-duration'),
            label: 'Entrance duration',
            value: _animationDurationMs,
            min: 100,
            max: 2000,
            suffix: 'ms',
            onChanged: (value) => setState(() => _animationDurationMs = value),
          ),
          EnumOption<_RadialBarMotionCurve>(
            key: const ValueKey('radial-bar-animation-curve'),
            label: 'Entrance curve',
            value: _animationCurve,
            values: _RadialBarMotionCurve.values,
            labelBuilder: _motionCurveName,
            onChanged: (value) => setState(() => _animationCurve = value),
          ),
          ActionButton(
            key: const ValueKey('radial-bar-replay-entrance'),
            label: 'Replay entrance',
            icon: Icons.replay_outlined,
            onPressed: () => _mountedChartController?.replayRadialEntrance(),
          ),
        ],
        IntSliderOption(
          label: 'Interaction duration',
          value: _interactionDurationMs,
          min: 0,
          max: 600,
          suffix: 'ms',
          onChanged: (value) => setState(() => _interactionDurationMs = value),
        ),
        EnumOption<_RadialBarMotionCurve>(
          label: 'Interaction curve',
          value: _interactionCurve,
          values: _RadialBarMotionCurve.values,
          labelBuilder: _motionCurveName,
          onChanged: (value) => setState(() => _interactionCurve = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Legend',
      icon: Icons.view_list_outlined,
      description:
          'Each native legend item represents one category track and shares its durable point selection.',
      initiallyExpanded: false,
      children: [
        BoolOption(
          key: const ValueKey('radial-bar-show-legend'),
          label: 'Show legend',
          value: _showLegend,
          onChanged: (value) => setState(() => _showLegend = value),
        ),
        if (_showLegend) ...[
          EnumOption<_RadialBarLegendPreset>(
            key: const ValueKey('radial-bar-legend-style'),
            label: 'Legend style',
            value: _legendPreset,
            values: _RadialBarLegendPreset.values,
            labelBuilder: _legendPresetName,
            onChanged: (value) => setState(() => _legendPreset = value),
          ),
          EnumOption<_RadialBarLegendContent>(
            key: const ValueKey('radial-bar-legend-content'),
            label: 'Item content',
            value: _legendContent,
            values: _RadialBarLegendContent.values,
            labelBuilder: _legendContentName,
            onChanged: (value) => setState(() => _legendContent = value),
          ),
          EnumOption<LegendPosition>(
            key: const ValueKey('radial-bar-legend-position'),
            label: 'Position',
            value: _legendPosition,
            values: LegendPosition.values,
            labelBuilder: _legendPositionName,
            onChanged: _setLegendPosition,
          ),
          EnumOption<LegendOrientation>(
            key: const ValueKey('radial-bar-legend-orientation'),
            label: 'Orientation',
            value: _legendOrientation,
            values: LegendOrientation.values,
            labelBuilder: _legendOrientationName,
            onChanged: (value) => setState(() => _legendOrientation = value),
          ),
          EnumOption<LegendMarkerShape>(
            key: const ValueKey('radial-bar-legend-marker-shape'),
            label: 'Marker shape',
            value: _legendMarkerShape,
            values: LegendMarkerShape.values,
            labelBuilder: _legendMarkerShapeName,
            onChanged: (value) => setState(() => _legendMarkerShape = value),
          ),
          SliderOption(
            key: const ValueKey('radial-bar-legend-marker-size'),
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
            key: const ValueKey('radial-bar-legend-font-size'),
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
            key: const ValueKey('radial-bar-legend-opacity'),
            label: 'Legend opacity',
            value: _legendOpacity * 100,
            min: 25,
            max: 100,
            divisions: 15,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _legendOpacity = value / 100),
          ),
          if (_legendPreset == _RadialBarLegendPreset.surface) ...[
            PaletteColorOption(
              label: 'Panel fill',
              subtitle: 'Clear to derive the surface from the chart theme.',
              value: _legendPanelColor,
              keyPrefix: 'radial-bar-legend-panel-fill',
              customColorFallback: Colors.white,
              onChanged: (value) => setState(() => _legendPanelColor = value),
            ),
            PaletteColorOption(
              label: 'Panel border',
              subtitle: 'Clear to derive the border from the chart theme.',
              value: _legendBorderColor,
              keyPrefix: 'radial-bar-legend-panel-border',
              customColorFallback: const Color(0xFFCBD5E1),
              onChanged: (value) => setState(() => _legendBorderColor = value),
            ),
          ],
        ],
        const InfoBox(
          message:
              'Activate a legend item to select the same category track on the chart and in the data table.',
        ),
      ],
    ),
  ];

  void _applyPresentation(_RadialBarPresentation presentation) {
    _randomizer.pause();
    _randomizer.clear();
    setState(() {
      _playgroundActive = false;
      _presentation = presentation;
      _chartRevision++;
      _applyPresentationState(presentation);
    });
  }

  void _applyPresentationState(_RadialBarPresentation presentation) {
    _trackOrder = RadialBarTrackOrder.outerToInner;
    _markOpacity = 1;
    _borderWidth = 0;
    _borderColor = null;
    _barColor = null;
    _trackColor = null;
    _gradientPreset = _RadialBarGradientPreset.solid;
    _useFixedGradientColors = false;
    _gradientStartColor = const Color(0xFF67E8F9);
    _gradientEndColor = const Color(0xFF1D4ED8);
    _gradientStartLightnessShift = 0.18;
    _gradientEndLightnessShift = -0.12;
    _showCategoryLabels = true;
    _categoryLabelPosition = RadialBarCategoryLabelPosition.startGap;
    _categoryLabelOrientation =
        RadialBarCategoryLabelOrientation.followStartAngle;
    _categoryLabelColor = null;
    _categoryLabelSize = 10;
    _categoryLabelWeight = FontWeight.w600;
    _categoryLabelOffset = 8;
    _showCategoryPanel = false;
    _categoryPanelColor = null;
    _categoryPanelBorderColor = null;
    _categoryPanelBorderWidth = 1;
    _categoryPanelRadius = 4;
    _categoryPanelPaddingX = 6;
    _categoryPanelPaddingY = 3;
    _categoryPanelShadowColor = null;
    _categoryPanelShadowBlur = 0;
    _categoryConnectorLength = 14;
    _categoryConnectorWidth = 0;
    _categoryConnectorColor = null;
    _selectionEffect = RadialSelectionEffect.explode;
    _selectionLiftScale = 1.08;
    _selectionLiftOffset = 6;
    _selectionBackdropBlur = 1.25;
    _showScaleLabels = true;
    _showGridLines = true;
    _showDataLabels = true;
    _labelPosition = RadialBarDataLabelPosition.insideEnd;
    _labelContent = RadialBarDataLabelContent.value;
    _labelColorMode = RadialBarDataLabelColorMode.autoContrast;
    _labelColor = null;
    _labelSize = 10;
    _labelWeight = FontWeight.w700;
    _labelOffset = 0;
    _showCalloutPanel = false;
    _calloutPanelColor = null;
    _calloutPanelBorderColor = null;
    _calloutPanelBorderWidth = 1;
    _calloutPanelRadius = 4;
    _calloutPanelPaddingX = 6;
    _calloutPanelPaddingY = 3;
    _calloutPanelShadowColor = null;
    _calloutPanelShadowBlur = 0;
    _connectorLength = 14;
    _connectorWidth = 1;
    _connectorColor = null;
    _selectionEffect = RadialSelectionEffect.explode;
    _selectionLiftScale = 1.08;
    _selectionLiftOffset = 6;
    _selectionBackdropBlur = 1.25;
    _showTooltip = true;
    _tooltipPreset = _RadialBarTooltipPreset.theme;
    _tooltipTriggerMode = TooltipTriggerMode.both;
    _tooltipPosition = TooltipPosition.auto;
    _tooltipFollowsPointer = false;
    _tooltipOffset = 8;
    _tooltipShowDelayMs = 0;
    _tooltipHideDelayMs = 200;
    _tooltipBackgroundColor = null;
    _tooltipTextColor = null;
    _tooltipBorderColor = null;
    _tooltipBorderWidth = 1;
    _tooltipBorderRadius = 4;
    _tooltipPadding = 8;
    _tooltipShadowColor = null;
    _tooltipShadowBlur = 4;
    _tooltipFontSize = 12;
    _entranceAnimationEnabled = true;
    _animationDurationMs = 400;
    _animationCurve = _RadialBarMotionCurve.easeInOutCubic;
    _interactionDurationMs = 150;
    _interactionCurve = _RadialBarMotionCurve.easeOut;
    _showLegend = true;
    _legendPreset = _RadialBarLegendPreset.theme;
    _legendContent = _RadialBarLegendContent.standard;
    _legendPosition = LegendPosition.bottomCenter;
    _legendOrientation = LegendOrientation.horizontal;
    _legendMarkerShape = LegendMarkerShape.circle;
    _legendMarkerSize = 10;
    _legendFontSize = 10;
    _legendOpacity = 1;
    _legendPanelColor = null;
    _legendBorderColor = null;
    _clockwise = true;
    _tickCount = 5;
    _thresholdWidth = 1.5;
    _thresholdColor = null;
    _dashedThreshold = true;
    _themePreset = ThemePreset.light;

    switch (presentation) {
      case _RadialBarPresentation.progress:
        _values = Map.of(_progressValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.22;
        _outerRadius = 0.82;
        _trackGap = 6;
        _cornerRadius = 8;
        _trackOpacity = 0.12;
        _showThreshold = true;
        _thresholdValue = 75;
        _gradientPreset = _RadialBarGradientPreset.sweep;
        _showLegend = false;
      case _RadialBarPresentation.signed:
        _values = Map.of(_signedValues);
        _minimum = -100;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.2;
        _outerRadius = 0.84;
        _trackGap = 7;
        _cornerRadius = 7;
        _trackOpacity = 0.1;
        _showThreshold = true;
        _thresholdValue = 50;
        _themePreset = ThemePreset.colorblindFriendly;
        _gradientPreset = _RadialBarGradientPreset.radial;
        _legendPreset = _RadialBarLegendPreset.compact;
        _configureTooltipPreset(_RadialBarTooltipPreset.contrast);
        _selectionEffect = RadialSelectionEffect.lift;
      case _RadialBarPresentation.partial:
        _values = Map.of(_partialValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -135;
        _sweepAngle = 270;
        _innerRadius = 0.24;
        _outerRadius = 0.84;
        _trackGap = 8;
        _cornerRadius = 10;
        _trackOpacity = 0.14;
        _showThreshold = true;
        _thresholdValue = 80;
        _categoryLabelPosition = RadialBarCategoryLabelPosition.startGap;
        _themePreset = ThemePreset.corporateBlue;
        _gradientPreset = _RadialBarGradientPreset.sweep;
        _legendPreset = _RadialBarLegendPreset.surface;
        _legendContent = _RadialBarLegendContent.valueCards;
        _legendPosition = LegendPosition.centerRight;
        _legendOrientation = LegendOrientation.vertical;
        _legendMarkerShape = LegendMarkerShape.diamond;
        _configureTooltipPreset(_RadialBarTooltipPreset.elevated);
        _tooltipPosition = TooltipPosition.right;
      case _RadialBarPresentation.callouts:
        _values = Map.of(_calloutValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.22;
        _outerRadius = 0.78;
        _trackGap = 7;
        _cornerRadius = 8;
        _trackOpacity = 0.12;
        _showThreshold = false;
        _thresholdValue = 75;
        _showCategoryLabels = false;
        _labelPosition = RadialBarDataLabelPosition.outsideCallout;
        _labelContent = RadialBarDataLabelContent.categoryAndValue;
        _showCalloutPanel = true;
        _connectorLength = 16;
        _labelOffset = 4;
        _themePreset = ThemePreset.minimal;
        _gradientPreset = _RadialBarGradientPreset.solid;
        _showLegend = false;
        _legendPosition = LegendPosition.topCenter;
        _legendOrientation = LegendOrientation.horizontal;
        _legendMarkerShape = LegendMarkerShape.line;
        _tooltipPosition = TooltipPosition.bottom;
      case _RadialBarPresentation.insideStyling:
        _values = Map.of(_insideStyleValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.2;
        _outerRadius = 0.82;
        _trackGap = 8;
        _cornerRadius = 12;
        _trackOpacity = 0.18;
        _showThreshold = false;
        _thresholdValue = 75;
        _themePreset = ThemePreset.dark;
        _labelColorMode = RadialBarDataLabelColorMode.fixed;
        _labelColor = Colors.white;
        _labelSize = 12;
        _labelOffset = 4;
        _categoryLabelOrientation =
            RadialBarCategoryLabelOrientation.horizontal;
        _categoryLabelColor = Colors.white;
        _categoryLabelSize = 11;
        _categoryLabelOffset = 12;
        _showCategoryPanel = true;
        _categoryPanelColor = const Color(0xFF1E293B);
        _categoryPanelBorderColor = const Color(0xFF64748B);
        _categoryPanelRadius = 6;
        _gradientPreset = _RadialBarGradientPreset.radial;
        _legendPreset = _RadialBarLegendPreset.surface;
        _legendContent = _RadialBarLegendContent.valueCards;
        _legendPosition = LegendPosition.bottomCenter;
        _legendOrientation = LegendOrientation.horizontal;
        _legendMarkerShape = LegendMarkerShape.square;
        _configureTooltipPreset(_RadialBarTooltipPreset.contrast);
        _selectionEffect = RadialSelectionEffect.lift;
        _selectionLiftScale = 1.12;
        _selectionBackdropBlur = 3;
      case _RadialBarPresentation.labelCards:
        _values = Map.of(_partialValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -110;
        _sweepAngle = 320;
        _innerRadius = 0.2;
        _outerRadius = 0.74;
        _trackGap = 8;
        _cornerRadius = 10;
        _trackOpacity = 0.1;
        _showThreshold = false;
        _showCategoryLabels = false;
        _labelPosition = RadialBarDataLabelPosition.outsideCallout;
        _labelContent = RadialBarDataLabelContent.categoryAndValue;
        _labelColorMode = RadialBarDataLabelColorMode.fixed;
        _labelColor = const Color(0xFF172554);
        _labelSize = 11;
        _labelWeight = FontWeight.w700;
        _labelOffset = 10;
        _showCalloutPanel = true;
        _calloutPanelColor = const Color(0xFFEFF6FF);
        _calloutPanelBorderColor = const Color(0xFF93C5FD);
        _calloutPanelBorderWidth = 1;
        _calloutPanelRadius = 10;
        _calloutPanelPaddingX = 10;
        _calloutPanelPaddingY = 6;
        _calloutPanelShadowColor = const Color(0x330F172A);
        _calloutPanelShadowBlur = 10;
        _connectorLength = 20;
        _connectorWidth = 1.5;
        _gradientPreset = _RadialBarGradientPreset.radial;
        _themePreset = ThemePreset.corporateBlue;
        _showLegend = false;
        _configureTooltipPreset(_RadialBarTooltipPreset.elevated);
      case _RadialBarPresentation.popupStudio:
        _values = Map.of(_insideStyleValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 300;
        _innerRadius = 0.2;
        _outerRadius = 0.8;
        _trackGap = 8;
        _cornerRadius = 9;
        _trackOpacity = 0.14;
        _showThreshold = false;
        _labelContent = RadialBarDataLabelContent.category;
        _labelSize = 9;
        _categoryLabelPosition = RadialBarCategoryLabelPosition.outsideCallout;
        _categoryConnectorWidth = 1;
        _categoryConnectorLength = 18;
        _showLegend = true;
        _legendPreset = _RadialBarLegendPreset.compact;
        _legendPosition = LegendPosition.bottomCenter;
        _configureTooltipPreset(_RadialBarTooltipPreset.contrast);
        _tooltipTriggerMode = TooltipTriggerMode.both;
        _tooltipPosition = TooltipPosition.right;
        _tooltipFollowsPointer = true;
        _tooltipOffset = 14;
        _tooltipShowDelayMs = 100;
        _tooltipHideDelayMs = 450;
        _tooltipBackgroundColor = const Color(0xFF172554);
        _tooltipTextColor = const Color(0xFFEFF6FF);
        _tooltipBorderColor = const Color(0xFF38BDF8);
        _tooltipBorderWidth = 1.5;
        _tooltipBorderRadius = 12;
        _tooltipPadding = 12;
        _tooltipShadowColor = const Color(0x660F172A);
        _tooltipShadowBlur = 16;
        _tooltipFontSize = 13;
        _themePreset = ThemePreset.minimal;
      case _RadialBarPresentation.motion:
        _values = Map.of(_progressValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -135;
        _sweepAngle = 270;
        _innerRadius = 0.18;
        _outerRadius = 0.82;
        _trackGap = 7;
        _cornerRadius = 12;
        _trackOpacity = 0.16;
        _showThreshold = true;
        _thresholdValue = 85;
        _labelContent = RadialBarDataLabelContent.categoryAndValue;
        _labelSize = 11;
        _showCategoryLabels = false;
        _showLegend = true;
        _legendPreset = _RadialBarLegendPreset.surface;
        _legendPosition = LegendPosition.centerRight;
        _legendOrientation = LegendOrientation.vertical;
        _gradientPreset = _RadialBarGradientPreset.sweep;
        _animationDurationMs = 1200;
        _animationCurve = _RadialBarMotionCurve.easeOutCubic;
        _interactionDurationMs = 280;
        _interactionCurve = _RadialBarMotionCurve.easeInOutCubic;
        _configureTooltipPreset(_RadialBarTooltipPreset.elevated);
        _tooltipPosition = TooltipPosition.left;
      case _RadialBarPresentation.rotatedCategories:
        _values = Map.of(_rotatedCategoryValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = 25;
        _sweepAngle = 285;
        _innerRadius = 0.24;
        _outerRadius = 0.8;
        _trackGap = 8;
        _cornerRadius = 9;
        _trackOpacity = 0.1;
        _showThreshold = true;
        _thresholdValue = 70;
        _categoryLabelColor = const Color(0xFF312E81);
        _categoryLabelSize = 11;
        _categoryLabelWeight = FontWeight.w700;
        _categoryLabelOffset = 12;
        _showCategoryPanel = true;
        _categoryPanelColor = const Color(0xFFF5F3FF);
        _categoryPanelBorderColor = const Color(0xFF8B5CF6);
        _categoryPanelBorderWidth = 1.5;
        _categoryPanelRadius = 6;
        _themePreset = ThemePreset.vibrant;
        _gradientPreset = _RadialBarGradientPreset.sweep;
        _showLegend = false;
        _legendPreset = _RadialBarLegendPreset.compact;
        _legendPosition = LegendPosition.bottomRight;
        _legendOrientation = LegendOrientation.horizontal;
        _legendMarkerShape = LegendMarkerShape.diamond;
        _tooltipFollowsPointer = true;
      case _RadialBarPresentation.calloutLanes:
        _values = Map.of(_calloutLaneValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -105;
        _sweepAngle = 360;
        _innerRadius = 0.14;
        _outerRadius = 0.72;
        _trackGap = 5;
        _cornerRadius = 7;
        _trackOpacity = 0.1;
        _showThreshold = false;
        _thresholdValue = 75;
        _showCategoryLabels = false;
        _labelPosition = RadialBarDataLabelPosition.outsideCallout;
        _labelContent = RadialBarDataLabelContent.categoryAndValue;
        _labelColorMode = RadialBarDataLabelColorMode.fixed;
        _labelColor = const Color(0xFF111827);
        _labelSize = 11;
        _labelOffset = 8;
        _showCalloutPanel = false;
        _connectorLength = 22;
        _connectorWidth = 2;
        _connectorColor = const Color(0xFF7C3AED);
        _themePreset = ThemePreset.highContrast;
        _gradientPreset = _RadialBarGradientPreset.sweep;
        _useFixedGradientColors = true;
        _gradientStartColor = const Color(0xFF22D3EE);
        _gradientEndColor = const Color(0xFF4F46E5);
        _legendPreset = _RadialBarLegendPreset.surface;
        _legendPosition = LegendPosition.centerLeft;
        _legendOrientation = LegendOrientation.vertical;
        _legendMarkerShape = LegendMarkerShape.circle;
        _configureTooltipPreset(_RadialBarTooltipPreset.elevated);
      case _RadialBarPresentation.dense:
        _values = Map.of(_denseValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.12;
        _outerRadius = 0.9;
        _trackGap = 3;
        _cornerRadius = 4;
        _trackOpacity = 0.1;
        _showThreshold = false;
        _thresholdValue = 75;
        _themePreset = ThemePreset.colorblindFriendly;
        _gradientPreset = _RadialBarGradientPreset.radial;
        _showLegend = false;
        _legendPreset = _RadialBarLegendPreset.compact;
        _legendPosition = LegendPosition.centerRight;
        _legendOrientation = LegendOrientation.vertical;
        _legendMarkerSize = 8;
        _legendFontSize = 9;
        _configureTooltipPreset(_RadialBarTooltipPreset.contrast);
    }
  }

  void _setPlaygroundActive(bool active) {
    setState(() => _playgroundActive = active);
    if (active && !_randomizer.hasGeneratedValue) {
      _randomizer.generateCurrent();
    }
  }

  void _resetExample() {
    _randomizer.pause();
    _randomizer.clear();
    setState(() {
      _playgroundActive = false;
      _presentation = _RadialBarPresentation.progress;
      _chartRevision++;
      _applyPresentationState(_presentation);
    });
  }

  _RandomRadialBarState _generateRandomState(int seed) {
    final random = math.Random(seed);
    final signed = random.nextBool();
    final minimum = signed ? -100.0 : 0.0;
    const maximum = 100.0;
    final baseline = signed ? 0.0 : minimum;
    final categoryCount = 4 + random.nextInt(9);
    final values = <String, num>{
      for (var index = 0; index < categoryCount; index++)
        'Category ${index + 1}':
            minimum + random.nextDouble() * (maximum - minimum),
    };
    final sweep = 180.0 + random.nextInt(19) * 10.0;
    final threshold = minimum + random.nextDouble() * (maximum - minimum);
    final legendPosition =
        LegendPosition.values[random.nextInt(LegendPosition.values.length)];
    return _RandomRadialBarState(
      values: values,
      minimum: minimum,
      maximum: maximum,
      baseline: baseline,
      startAngle: -180 + random.nextInt(37) * 10.0,
      sweepAngle: sweep,
      clockwise: random.nextBool(),
      innerRadius: 0.08 + random.nextDouble() * 0.28,
      outerRadius: 0.75 + random.nextDouble() * 0.2,
      trackGap: random.nextDouble() * 12,
      cornerRadius: random.nextDouble() * 16,
      trackOpacity: 0.06 + random.nextDouble() * 0.22,
      gradientPreset: _RadialBarGradientPreset
          .values[random.nextInt(_RadialBarGradientPreset.values.length)],
      useFixedGradientColors: random.nextBool(),
      gradientStartColor:
          _categoryPalette[random.nextInt(_categoryPalette.length)],
      gradientEndColor:
          _categoryPalette[random.nextInt(_categoryPalette.length)],
      gradientStartLightnessShift: -0.3 + random.nextDouble() * 0.6,
      gradientEndLightnessShift: -0.3 + random.nextDouble() * 0.6,
      tickCount: 3 + random.nextInt(8),
      thresholdValue: threshold,
      showThreshold: random.nextBool(),
      labelPosition: RadialBarDataLabelPosition
          .values[random.nextInt(RadialBarDataLabelPosition.values.length)],
      labelContent: RadialBarDataLabelContent
          .values[random.nextInt(RadialBarDataLabelContent.values.length)],
      labelColorMode: RadialBarDataLabelColorMode
          .values[random.nextInt(RadialBarDataLabelColorMode.values.length)],
      labelSize: 9 + random.nextDouble() * 7,
      labelOffset: random.nextDouble() * 18,
      showCalloutPanel: random.nextBool(),
      calloutPanelPaddingX: random.nextDouble() * 14,
      calloutPanelPaddingY: random.nextDouble() * 10,
      calloutPanelShadowBlur: random.nextDouble() * 18,
      categoryLabelPosition: RadialBarCategoryLabelPosition
          .values[random.nextInt(RadialBarCategoryLabelPosition.values.length)],
      categoryLabelOrientation:
          RadialBarCategoryLabelOrientation.values[random.nextInt(
            RadialBarCategoryLabelOrientation.values.length,
          )],
      showCategoryPanel: random.nextBool(),
      categoryPanelPaddingX: random.nextDouble() * 14,
      categoryPanelPaddingY: random.nextDouble() * 10,
      categoryPanelShadowBlur: random.nextDouble() * 18,
      selectionEffect: RadialSelectionEffect
          .values[random.nextInt(RadialSelectionEffect.values.length)],
      selectionLiftScale: 1.02 + random.nextDouble() * 0.18,
      selectionLiftOffset: random.nextDouble() * 14,
      selectionBackdropBlur: random.nextDouble() * 5,
      showLegend: random.nextBool(),
      legendPreset: _RadialBarLegendPreset
          .values[random.nextInt(_RadialBarLegendPreset.values.length)],
      legendContent: _RadialBarLegendContent
          .values[random.nextInt(_RadialBarLegendContent.values.length)],
      legendPosition: legendPosition,
      legendOrientation: _legendOrientationForPosition(legendPosition),
      legendMarkerShape: LegendMarkerShape
          .values[random.nextInt(LegendMarkerShape.values.length)],
      tooltipPreset: _RadialBarTooltipPreset
          .values[random.nextInt(_RadialBarTooltipPreset.values.length)],
      tooltipTriggerMode: TooltipTriggerMode
          .values[random.nextInt(TooltipTriggerMode.values.length)],
      tooltipPosition:
          TooltipPosition.values[random.nextInt(TooltipPosition.values.length)],
      tooltipFollowsPointer: random.nextBool(),
      tooltipOffset: random.nextDouble() * 24,
      tooltipShowDelayMs: random.nextInt(401),
      tooltipHideDelayMs: random.nextInt(801),
      tooltipBorderWidth: random.nextDouble() * 3,
      tooltipBorderRadius: random.nextDouble() * 16,
      tooltipPadding: 4 + random.nextDouble() * 12,
      tooltipShadowBlur: random.nextDouble() * 20,
      tooltipFontSize: 9 + random.nextDouble() * 7,
      entranceAnimationEnabled: random.nextDouble() > 0.15,
      animationDurationMs: 200 + random.nextInt(1401),
      animationCurve: _RadialBarMotionCurve
          .values[random.nextInt(_RadialBarMotionCurve.values.length)],
      interactionDurationMs: random.nextInt(401),
      interactionCurve: _RadialBarMotionCurve
          .values[random.nextInt(_RadialBarMotionCurve.values.length)],
    );
  }

  void _applyRandomState(_RandomRadialBarState value) {
    if (!mounted) return;
    setState(() {
      _playgroundActive = true;
      _chartRevision++;
      _values = Map.of(value.values);
      _minimum = value.minimum;
      _maximum = value.maximum;
      _baseline = value.baseline;
      _startAngle = value.startAngle;
      _sweepAngle = value.sweepAngle;
      _clockwise = value.clockwise;
      _innerRadius = value.innerRadius;
      _outerRadius = value.outerRadius;
      _trackGap = value.trackGap;
      _cornerRadius = value.cornerRadius;
      _trackOpacity = value.trackOpacity;
      _gradientPreset = value.gradientPreset;
      _useFixedGradientColors = value.useFixedGradientColors;
      _gradientStartColor = value.gradientStartColor;
      _gradientEndColor = value.gradientEndColor;
      _gradientStartLightnessShift = value.gradientStartLightnessShift;
      _gradientEndLightnessShift = value.gradientEndLightnessShift;
      _tickCount = value.tickCount;
      _thresholdValue = value.thresholdValue;
      _showThreshold = value.showThreshold;
      _labelPosition = value.labelPosition;
      _labelContent = value.labelContent;
      _labelColorMode = value.labelColorMode;
      _labelSize = value.labelSize;
      _labelOffset = value.labelOffset;
      _showCalloutPanel = value.showCalloutPanel;
      _calloutPanelPaddingX = value.calloutPanelPaddingX;
      _calloutPanelPaddingY = value.calloutPanelPaddingY;
      _calloutPanelShadowBlur = value.calloutPanelShadowBlur;
      _calloutPanelShadowColor = value.calloutPanelShadowBlur > 1
          ? const Color(0x330F172A)
          : null;
      _categoryLabelPosition = value.categoryLabelPosition;
      _categoryLabelOrientation = value.categoryLabelOrientation;
      _showCategoryPanel = value.showCategoryPanel;
      _categoryPanelPaddingX = value.categoryPanelPaddingX;
      _categoryPanelPaddingY = value.categoryPanelPaddingY;
      _categoryPanelShadowBlur = value.categoryPanelShadowBlur;
      _categoryPanelShadowColor = value.categoryPanelShadowBlur > 1
          ? const Color(0x330F172A)
          : null;
      _selectionEffect = value.selectionEffect;
      _selectionLiftScale = value.selectionLiftScale;
      _selectionLiftOffset = value.selectionLiftOffset;
      _selectionBackdropBlur = value.selectionBackdropBlur;
      _showLegend = value.showLegend;
      _legendPreset = value.legendPreset;
      _legendContent = value.legendContent;
      _legendPosition = value.legendPosition;
      _legendOrientation = value.legendOrientation;
      _legendMarkerShape = value.legendMarkerShape;
      _tooltipPreset = value.tooltipPreset;
      _tooltipBackgroundColor = null;
      _tooltipTextColor = null;
      _tooltipBorderColor = null;
      _tooltipTriggerMode = value.tooltipTriggerMode;
      _tooltipPosition = value.tooltipPosition;
      _tooltipFollowsPointer = value.tooltipFollowsPointer;
      _tooltipOffset = value.tooltipOffset;
      _tooltipShowDelayMs = value.tooltipShowDelayMs;
      _tooltipHideDelayMs = value.tooltipHideDelayMs;
      _tooltipBorderWidth = value.tooltipBorderWidth;
      _tooltipBorderRadius = value.tooltipBorderRadius;
      _tooltipPadding = value.tooltipPadding;
      _tooltipShadowBlur = value.tooltipShadowBlur;
      _tooltipFontSize = value.tooltipFontSize;
      _tooltipShadowColor = value.tooltipShadowBlur > 1
          ? const Color(0x4D0F172A)
          : null;
      _entranceAnimationEnabled = value.entranceAnimationEnabled;
      _animationDurationMs = value.animationDurationMs;
      _animationCurve = value.animationCurve;
      _interactionDurationMs = value.interactionDurationMs;
      _interactionCurve = value.interactionCurve;
      _labelColor = value.labelColorMode == RadialBarDataLabelColorMode.fixed
          ? _categoryPalette[value.values.length % _categoryPalette.length]
          : null;
      _barColor = null;
    });
  }

  void _setLegendPosition(LegendPosition value) {
    setState(() {
      _legendPosition = value;
      _legendOrientation = _legendOrientationForPosition(value);
    });
  }

  static LegendOrientation _legendOrientationForPosition(
    LegendPosition value,
  ) => switch (value) {
    LegendPosition.centerLeft ||
    LegendPosition.centerRight => LegendOrientation.vertical,
    _ => LegendOrientation.horizontal,
  };

  String _legendPresetName(_RadialBarLegendPreset value) => switch (value) {
    _RadialBarLegendPreset.theme => 'Chart theme',
    _RadialBarLegendPreset.compact => 'Compact',
    _RadialBarLegendPreset.surface => 'Raised surface',
  };

  String _legendContentName(_RadialBarLegendContent value) => switch (value) {
    _RadialBarLegendContent.standard => 'Standard details',
    _RadialBarLegendContent.valueCards => 'Custom value cards',
  };

  String _legendPositionName(LegendPosition value) => switch (value) {
    LegendPosition.topLeft => 'Top left',
    LegendPosition.topCenter => 'Top center',
    LegendPosition.topRight => 'Top right',
    LegendPosition.centerLeft => 'Center left',
    LegendPosition.center => 'Overlay center',
    LegendPosition.centerRight => 'Center right',
    LegendPosition.bottomLeft => 'Bottom left',
    LegendPosition.bottomCenter => 'Bottom center',
    LegendPosition.bottomRight => 'Bottom right',
  };

  String _legendOrientationName(LegendOrientation value) => switch (value) {
    LegendOrientation.horizontal => 'Horizontal',
    LegendOrientation.vertical => 'Vertical',
  };

  String _legendMarkerShapeName(LegendMarkerShape value) => switch (value) {
    LegendMarkerShape.circle => 'Circle',
    LegendMarkerShape.square => 'Square',
    LegendMarkerShape.line => 'Line',
    LegendMarkerShape.diamond => 'Diamond',
  };

  String _gradientPresetName(_RadialBarGradientPreset value) => switch (value) {
    _RadialBarGradientPreset.solid => 'Solid color',
    _RadialBarGradientPreset.sweep => 'Along value arc',
    _RadialBarGradientPreset.radial => 'Across track',
  };

  String _tooltipPresetName(_RadialBarTooltipPreset value) => switch (value) {
    _RadialBarTooltipPreset.theme => 'Chart theme',
    _RadialBarTooltipPreset.elevated => 'Elevated surface',
    _RadialBarTooltipPreset.contrast => 'High contrast',
  };

  String _tooltipPositionName(TooltipPosition value) => switch (value) {
    TooltipPosition.auto => 'Automatic',
    TooltipPosition.top => 'Above',
    TooltipPosition.bottom => 'Below',
    TooltipPosition.left => 'Left',
    TooltipPosition.right => 'Right',
  };

  String _motionCurveName(_RadialBarMotionCurve value) => switch (value) {
    _RadialBarMotionCurve.linear => 'Linear',
    _RadialBarMotionCurve.easeOut => 'Ease out',
    _RadialBarMotionCurve.easeOutCubic => 'Ease out cubic',
    _RadialBarMotionCurve.easeInOutCubic => 'Ease in/out cubic',
  };

  void _configureTooltipPreset(_RadialBarTooltipPreset value) {
    _tooltipPreset = value;
    _tooltipBackgroundColor = null;
    _tooltipTextColor = null;
    _tooltipBorderColor = null;
    _tooltipShadowColor = null;
    switch (value) {
      case _RadialBarTooltipPreset.theme:
        _tooltipBorderWidth = 1;
        _tooltipBorderRadius = 4;
        _tooltipPadding = 8;
        _tooltipShadowBlur = 4;
        _tooltipFontSize = 12;
      case _RadialBarTooltipPreset.elevated:
        _tooltipBorderWidth = 1;
        _tooltipBorderRadius = 10;
        _tooltipPadding = 12;
        _tooltipShadowColor = const Color(0x401A1A1A);
        _tooltipShadowBlur = 12;
        _tooltipFontSize = 12;
      case _RadialBarTooltipPreset.contrast:
        _tooltipBorderWidth = 1;
        _tooltipBorderRadius = 6;
        _tooltipPadding = 10;
        _tooltipShadowColor = const Color(0x4D1A1A1A);
        _tooltipShadowBlur = 8;
        _tooltipFontSize = 12;
    }
  }

  void _setTooltipPreset(_RadialBarTooltipPreset value) {
    setState(() => _configureTooltipPreset(value));
  }

  String get _chartTitle => _playgroundActive
      ? 'Generated category tracks'
      : switch (_presentation) {
          _RadialBarPresentation.progress => 'Customer journey progress',
          _RadialBarPresentation.signed => 'Net contribution by driver',
          _RadialBarPresentation.partial => 'Channel target attainment',
          _RadialBarPresentation.callouts => 'Outcome labels beyond the pane',
          _RadialBarPresentation.insideStyling =>
            'High-contrast labels and category panels',
          _RadialBarPresentation.labelCards => 'Panelled value-label callouts',
          _RadialBarPresentation.popupStudio => 'Styled data-point popup',
          _RadialBarPresentation.motion => 'Replayable track motion',
          _RadialBarPresentation.rotatedCategories =>
            'Rotated category-label treatment',
          _RadialBarPresentation.calloutLanes =>
            'Collision-managed callout lanes',
          _RadialBarPresentation.dense => 'Regional operating profile',
        };

  String get _presentationDescription => switch (_presentation) {
    _RadialBarPresentation.progress =>
      'Each labeled track stands alone on one explicit 0–100 scale, without a duplicate legend.',
    _RadialBarPresentation.signed =>
      'Marks grow in either direction from an explicit zero baseline.',
    _RadialBarPresentation.partial =>
      'A partial pane preserves absolute values and one shared target guide.',
    _RadialBarPresentation.callouts =>
      'Outside callouts identify every short arc directly, so no separate legend is needed.',
    _RadialBarPresentation.insideStyling =>
      'Fixed light value labels and compact category panels exercise a dark chart theme.',
    _RadialBarPresentation.labelCards =>
      'Spacious label panels exercise custom fill, border, padding, radius, shadow, and connector styling.',
    _RadialBarPresentation.popupStudio =>
      'Hover or tap a track to inspect a deliberately styled, pointer-following data-point popup.',
    _RadialBarPresentation.motion =>
      'A slower elastic baseline-growth entrance makes duration, easing, replay, and interaction timing easy to inspect.',
    _RadialBarPresentation.rotatedCategories =>
      'Adaptive category labels identify a non-cardinal partial pane without a duplicate legend.',
    _RadialBarPresentation.calloutLanes =>
      'Crowded values exercise horizontal lane exits, custom connector colour, width, and offset.',
    _RadialBarPresentation.dense =>
      'Compact geometry keeps every category hit-testable and reserves the viewport for the chart.',
  };
}
