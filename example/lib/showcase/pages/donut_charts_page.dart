// Copyright 2026 Braven Charts - Donut Charts Showcase
// SPDX-License-Identifier: MIT

import 'dart:typed_data';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../data/radial_demo_data.dart';
import '../widgets/options_panel.dart';
import '../widgets/radial_option_order.dart';
import '../widgets/radial_legend_value_card.dart';
import '../widgets/standard_options.dart';

/// Public showcase for first-class Donut geometry and portable center content.
class DonutChartsPage extends StatefulWidget {
  const DonutChartsPage({super.key});

  @override
  State<DonutChartsPage> createState() => _DonutChartsPageState();
}

class _DonutChartsPageState extends State<DonutChartsPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final math.Random _random = math.Random();

  _DonutStory _story = _DonutStory.contribution;
  late Map<String, num> _values;
  late Map<String, num> _radiusValues;
  late int _categoryCount;
  double _innerRadiusFactor = 0.58;
  double _sweepAngleDegrees = 360;
  double _startAngleDegrees = -90;
  double _radiusFactor = 0.86;
  double _sliceGap = 3;
  double _cornerRadius = 8;
  double _selectionExplodeOffset = 10;
  RadialSelectionEffect _selectionEffect = RadialSelectionEffect.lift;
  double _selectionLiftScale = 1.1;
  double _selectionLiftOffset = 6;
  double _selectionBackdropBlur = 1.25;
  PieAnimationMode _animationMode = PieAnimationMode.grow;
  RadialDataTransitionMode _dataTransitionMode =
      RadialDataTransitionMode.automatic;
  bool _clockwise = true;
  bool _showLabels = true;
  _DonutLabelLayout _labelLayout = _DonutLabelLayout.split;
  PieDataLabelPosition _labelPosition = PieDataLabelPosition.outside;
  PieDataLabelContent _labelContent = PieDataLabelContent.categoryAndPercentage;
  PieDataLabelCollisionStrategy _labelCollisionStrategy =
      PieDataLabelCollisionStrategy.shiftAndHide;
  double _labelMinimumShare = 0.04;
  double _labelMinimumSweepDegrees = 0;
  double _labelPadding = 6;
  double _insideLabelOffset = 0;
  double _outsideLabelOffset = 4;
  double _connectorLength = 12;
  double _connectorWidth = 1;
  bool _useCustomConnectorColor = false;
  Color _connectorColor = const Color(0xFF475569);
  _DonutCalloutPreset _calloutPreset = _DonutCalloutPreset.plain;
  _DonutInsideShareStyle _insideShareStyle = _DonutInsideShareStyle.darkBadge;
  _DonutThemePreset _themePreset = _DonutThemePreset.light;
  _DonutPalette _palette = _DonutPalette.theme;
  _DonutGradientPreset _gradientPreset = _DonutGradientPreset.radial;
  bool _useFixedGradientColors = false;
  Color _gradientStartColor = const Color(0xFF67E8F9);
  Color _gradientEndColor = const Color(0xFF1D4ED8);
  double _gradientStartLightnessShift = 0.14;
  double _gradientEndLightnessShift = -0.08;
  double _gradientAngleDegrees = -45;
  double _sliceOpacity = 1;
  double _borderWidth = 1;
  _DonutBorderPreset _borderPreset = _DonutBorderPreset.darkerSlice;
  Color _fixedBorderColor = const Color(0xFF334155);
  PieCornerTreatment _cornerTreatment = PieCornerTreatment.roundAll;
  bool _showShadow = false;
  bool _showSelectedGlow = true;
  _DonutGlowColor _selectedGlowColor = _DonutGlowColor.slice;
  double _selectedGlowBlur = 12;
  double _selectedGlowSpread = 2;
  double _selectedGlowOpacity = 0.48;
  double _selectedGlowOffsetY = 0;
  bool _showLegend = true;
  _DonutLegendPreset _legendPreset = _DonutLegendPreset.theme;
  _DonutLegendContent _legendContent = _DonutLegendContent.standard;
  LegendPosition _legendPosition = LegendPosition.bottomCenter;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.circle;
  double _legendMarkerSize = 10;
  double _legendFontSize = 10;
  double _legendOpacity = 1;
  bool _showTooltips = true;
  _DonutTooltipPreset _tooltipPreset = _DonutTooltipPreset.theme;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowsCursor = false;
  double _tooltipOffset = 8;
  bool _showCenterContent = true;
  bool _groupSmallSlices = false;
  double _groupingMinimumShare = 0.07;
  RadialSliceRadiusAggregation _radiusAggregation =
      RadialSliceRadiusAggregation.weightedMean;
  DonutCenterValueMode _centerValueMode = DonutCenterValueMode.selectedOrTotal;
  _DonutCenterStyle _centerStyle = _DonutCenterStyle.theme;
  ChartArtifact? _capturedArtifact;
  HydratedChartConfiguration? _restoredConfiguration;
  String? _portableJson;
  String? _captureError;
  String? _selectedCategory;
  bool _isCapturing = false;
  bool _showRestoredCopy = false;
  int _centerActionCount = 0;

  static const _colorChoices = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
    Color(0xFFEF4444),
    Color(0xFF334155),
    Color(0xFFF8FAFC),
  ];

  @override
  void initState() {
    super.initState();
    _values = Map<String, num>.of(_story.values);
    _radiusValues = Map<String, num>.of(_story.radiusValues);
    _categoryCount = _values.length;
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
      title: 'Donut Charts',
      subtitle:
          'Compare category contributions around a configurable center opening',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return SingleChildScrollView(
          key: const ValueKey('donut-showcase-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStorySelector(compact: compact),
              const SizedBox(height: 16),
              _buildSliceNotice(),
              const SizedBox(height: 16),
              SizedBox(
                height: compact ? 760 : 680,
                child: _buildChartCard(compact: compact),
              ),
              const SizedBox(height: 32),
              _buildPortableWorkflow(compact: compact),
              const SizedBox(height: 32),
              _buildFeatureGuide(compact: compact),
              const SizedBox(height: 32),
              _buildCodeRecipe(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorySelector({required bool compact}) {
    final theme = Theme.of(context);
    final availableWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = compact ? availableWidth : 220.0;
    return Semantics(
      container: true,
      label: 'Choose a Donut geometry story',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final story in _DonutStory.values)
            SizedBox(
              width: cardWidth,
              child: Material(
                color: story == _story
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: story == _story
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('donut-story-${story.name}'),
                  onTap: () => _selectStory(story),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 76),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(story.icon, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  story.description,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (story == _story)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                        ],
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

  Widget _buildSliceNotice() {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.donut_large_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(_sliceNoticeText)),
          ],
        ),
      ),
    );
  }

  String get _sliceNoticeText {
    if (_selectedCategory == null) {
      return _groupSmallSlices
          ? 'Small categories render as one Other slice, while the data table keeps every original row. Select Other or any grouped row to see the shared selection.'
          : 'Select a slice, legend item, or table row. The center follows the same durable selection, then returns to the total when selection clears.';
    }
    if (_groupSmallSlices && _selectedCategory == 'Other') {
      RadialCategorySlice? grouped;
      for (final slice in _buildSeries().visibleSlices) {
        if (slice.isGrouped) {
          grouped = slice;
          break;
        }
      }
      if (grouped != null) {
        return 'Selected: Other. One visible slice now selects all ${grouped.sourcePointIndices.length} original source rows through the controller.';
      }
    }
    return 'Selected: $_selectedCategory. The chart, table, controller, and center now share this category identity.';
  }

  Widget _buildChartCard({required bool compact}) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('donut-showcase-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartHeading(theme),
                  const SizedBox(height: 8),
                  _buildChartMetrics(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildChartHeading(theme)),
                  const SizedBox(width: 16),
                  Flexible(child: _buildChartMetrics()),
                ],
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildDataSurface(compact: compact)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeading(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _story.chartTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        _story.chartDescription,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildChartMetrics() => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: [
      _MetricPill(label: '${(_innerRadiusFactor * 100).round()}% center'),
      _MetricPill(label: '${_sweepAngleDegrees.round()}° sweep'),
      _MetricPill(label: _centerModeName(_centerValueMode)),
      _MetricPill(label: '${_animationModeName(_animationMode)} in'),
      _MetricPill(label: _selectionEffectName(_selectionEffect)),
      if (_groupSmallSlices) const _MetricPill(label: 'Grouped sources'),
    ],
  );

  Widget _buildDataSurface({required bool compact}) {
    return BravenChartWorkbench(
      chartController: _chartController,
      workbenchController: _workbenchController,
      initialDisplayMode: ChartDisplayMode.split,
      availableDisplayModes: const {
        ChartDisplayMode.chart,
        ChartDisplayMode.data,
        ChartDisplayMode.split,
        ChartDisplayMode.source,
      },
      sourceOptions: const ChartDartSourceOptions(variableName: 'donutChart'),
      splitBreakpoint: 1,
      splitAxis: compact ? Axis.vertical : Axis.horizontal,
      splitGap: 8,
      minimumChartPaneExtent: compact ? 240 : 360,
      minimumTablePaneExtent: compact ? 240 : 420,
      maximumAutoTablePaneExtent: 620,
      autoFitTablePane: true,
      isSplitResizable: true,
      documentOptions: ChartDocumentExtractOptions(
        includeViewState: true,
        radialFormatterDescriptors: {
          'donut-${_story.name}': _radialFormatterDescriptors(
            includeRadius: _radiusValues.isNotEmpty,
          ),
        },
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
    final theme = _buildChartTheme();
    return BravenChartPlus(
      key: const ValueKey('donut-showcase-chart'),
      title: _story.chartTitle,
      subtitle: _story.chartDescription,
      bravenChartController: controller,
      showLegend: _showLegend,
      radialLegendItemBuilder: _legendContent == _DonutLegendContent.valueCards
          ? _buildValueCardLegendItem
          : null,
      donutCenterBuilder: _centerStyle == _DonutCenterStyle.customWidget
          ? _buildRuntimeCenter
          : null,
      onDonutCenterTap: _centerStyle == _DonutCenterStyle.customWidget
          ? _handleCenterAction
          : null,
      theme: theme,
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
      onPointTap: _handlePointActivation,
      series: [_buildSeries()],
    );
  }

  Widget _buildValueCardLegendItem(
    BuildContext context,
    RadialLegendItemData item,
  ) => RadialLegendValueCard(
    key: ValueKey('donut-custom-legend-item-${item.visibleIndex}'),
    item: item,
  );

  Widget _buildRuntimeCenter(BuildContext context, DonutCenterData data) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.hasSelection
                ? Icons.check_circle_outline
                : Icons.touch_app_outlined,
            size: math.max(16, data.availableDiameter * .14),
            color: colors.primary,
          ),
          const SizedBox(height: 3),
          Text(
            data.label ?? 'Interactive center',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: data.defaultLabelStyle,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(data.valueLabel, style: data.defaultValueStyle),
          ),
          Text(
            'Center actions: $_centerActionCount',
            maxLines: 1,
            style: data.defaultLabelStyle.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: math.max(8, data.defaultLabelStyle.fontSize! * .78),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCenterAction(DonutCenterData data) {
    setState(() => _centerActionCount++);
  }

  DonutChartSeries _buildSeries() {
    return DonutChartSeries.fromMap(
      id: 'donut-${_story.name}',
      name: _story.seriesName,
      unit: _story.unit,
      values: _values,
      sliceColors: _activeSliceColors,
      radiusValues: _radiusValues,
      sliceRadiusConfig: _radiusValues.isEmpty
          ? null
          : RadialSliceRadiusConfig(
              minimumFactor: 0.42,
              scale: PieSliceRadiusScale.area,
              label: 'Audience reach',
              unit: 'k users',
              formatter: (value) => '${value.toStringAsFixed(0)} k users',
            ),
      sliceGroupingConfig: _groupSmallSlices
          ? RadialSliceGroupingConfig(
              minimumShare: _groupingMinimumShare,
              label: 'Other',
              radiusAggregation: _radiusValues.isEmpty
                  ? null
                  : _radiusAggregation,
            )
          : null,
      donutStyle: DonutChartStyle(
        innerRadiusFactor: _innerRadiusFactor,
        sweepAngleDegrees: _sweepAngleDegrees,
        startAngleDegrees: _startAngleDegrees,
        clockwise: _clockwise,
        radiusFactor: _radiusFactor,
        sliceGap: _sliceGap,
        borderWidth: _borderWidth,
        borderColor: _borderPreset == _DonutBorderPreset.fixed
            ? _fixedBorderColor
            : null,
        borderColorMode: switch (_borderPreset) {
          _DonutBorderPreset.chartTheme => PieBorderColorMode.chartTheme,
          _DonutBorderPreset.darkerSlice ||
          _DonutBorderPreset.shiftedHue => PieBorderColorMode.slice,
          _DonutBorderPreset.fixed => null,
        },
        borderHueShiftDegrees: _borderPreset == _DonutBorderPreset.shiftedHue
            ? 28
            : 0,
        borderLightnessShift: _borderPreset == _DonutBorderPreset.darkerSlice
            ? -0.18
            : -0.08,
        selectionExplodeOffset: _selectionExplodeOffset,
        opacity: _sliceOpacity,
        cornerRadius: _cornerRadius,
        cornerTreatment: _cornerTreatment,
        shadow: _showShadow
            ? const PieElevationStyle(
                color: Color(0x4D0F172A),
                blurRadius: 8,
                offset: Offset(0, 4),
                opacity: 0.7,
              )
            : const PieElevationStyle(),
        selectedElevation: _showSelectedGlow
            ? PieElevationStyle(
                color: _selectedGlowColor == _DonutGlowColor.slice
                    ? null
                    : _selectedGlowColor == _DonutGlowColor.accent
                    ? _paletteColors.first
                    : (_baseChartTheme.axisStyle.labelStyle.color ??
                          const Color(0xFF1A1A1A)),
                blurRadius: _selectedGlowBlur,
                spreadRadius: _selectedGlowSpread,
                offset: Offset(0, _selectedGlowOffsetY),
                opacity: _selectedGlowOpacity,
              )
            : const PieElevationStyle(),
        animationMode: _animationMode,
        dataTransitionMode: _dataTransitionMode,
        gradient: _gradientStyle,
      ),
      selectionStyle: RadialSelectionStyle(
        effect: _selectionEffect,
        liftScale: _selectionLiftScale,
        liftOffset: _selectionLiftOffset,
        backdropBlur: _selectionBackdropBlur,
      ),
      centerContent: DonutCenterContent(
        isVisible: _showCenterContent,
        label: switch (_centerValueMode) {
          DonutCenterValueMode.total => 'Total',
          DonutCenterValueMode.custom => 'Status',
          DonutCenterValueMode.selectedValue ||
          DonutCenterValueMode.selectedOrTotal => null,
        },
        valueMode: _centerValueMode,
        customValue: _centerValueMode == DonutCenterValueMode.custom
            ? 'On track'
            : null,
        labelStyle: _centerLabelStyle,
        valueStyle: _centerValueStyle,
        valueFormatter: (value) => '${value.toStringAsFixed(0)} ${_story.unit}',
      ),
      dataLabels: PieDataLabelConfig(
        isVisible: _showLabels,
        position: _labelLayout == _DonutLabelLayout.split
            ? PieDataLabelPosition.outside
            : _labelPosition,
        content: _labelLayout == _DonutLabelLayout.split
            ? PieDataLabelContent.category
            : _labelContent,
        secondaryContent: _labelLayout == _DonutLabelLayout.split
            ? PieDataLabelContent.percentage
            : null,
        secondaryPosition: PieDataLabelPosition.inside,
        secondaryCalloutStyle: _labelLayout == _DonutLabelLayout.split
            ? _insidePercentageStyle
            : null,
        minimumShare: _labelMinimumShare,
        minimumSweepDegrees: _labelMinimumSweepDegrees,
        padding: _labelPadding,
        insideOffset: _insideLabelOffset,
        outsideOffset: _outsideLabelOffset,
        connectorLength: _connectorLength,
        connectorWidth: _connectorWidth,
        connectorColor: _useCustomConnectorColor ? _connectorColor : null,
        collisionStrategy: _labelCollisionStrategy,
        calloutStyle: _calloutStyle(_baseChartTheme),
        valueFormatter: (value) => '${value.toStringAsFixed(1)} ${_story.unit}',
        percentageFormatter: (share) => '${(share * 100).toStringAsFixed(0)}%',
      ),
    );
  }

  ChartTheme get _baseChartTheme => switch (_themePreset) {
    _DonutThemePreset.light => ChartTheme.light,
    _DonutThemePreset.dark => ChartTheme.dark,
    _DonutThemePreset.highContrast => ChartTheme.highContrast,
    _DonutThemePreset.colorblind => ChartTheme.colorblindFriendly,
  };

  List<Color> get _paletteColors => switch (_palette) {
    _DonutPalette.theme => List<Color>.generate(
      math.max(5, _values.length),
      _baseChartTheme.seriesTheme.colorAt,
    ),
    _DonutPalette.ocean => const [
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFF06B6D4),
      Color(0xFF7C3AED),
      Color(0xFF64748B),
    ],
    _DonutPalette.sunset => const [
      Color(0xFFE63946),
      Color(0xFFF77F00),
      Color(0xFFFCBF49),
      Color(0xFF9D4EDD),
      Color(0xFF5A189A),
    ],
    _DonutPalette.earth => const [
      Color(0xFF386641),
      Color(0xFF6A994E),
      Color(0xFFA7C957),
      Color(0xFFBC6C25),
      Color(0xFFDDA15E),
    ],
    _DonutPalette.monochrome => const [
      Color(0xFF1F2937),
      Color(0xFF374151),
      Color(0xFF4B5563),
      Color(0xFF6B7280),
      Color(0xFF9CA3AF),
    ],
  };

  Map<String, Color> get _activeSliceColors {
    final palette = _paletteColors;
    return {
      for (final (index, category) in _values.keys.indexed)
        category: palette[index % palette.length],
    };
  }

  PieGradientStyle? get _gradientStyle => switch (_gradientPreset) {
    _DonutGradientPreset.solid => null,
    _DonutGradientPreset.linear => PieGradientStyle(
      type: PieGradientType.linear,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartLightnessShift,
      endLightnessShift: _gradientEndLightnessShift,
      angleDegrees: _gradientAngleDegrees,
    ),
    _DonutGradientPreset.radial => PieGradientStyle(
      type: PieGradientType.radial,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartLightnessShift,
      endLightnessShift: _gradientEndLightnessShift,
    ),
  };

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
      _DonutLegendPreset.theme => legendBase,
      _DonutLegendPreset.compact => legendBase.copyWith(
        markerLabelSpacing: 5,
        itemSpacing: 3,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      _DonutLegendPreset.surface => legendBase.copyWith(
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
        clearCalloutStyle: _calloutPreset == _DonutCalloutPreset.plain,
        animationMode: _animationMode,
      ),
    );
  }

  LabelStyle? _calloutStyle(ChartTheme theme) => switch (_calloutPreset) {
    _DonutCalloutPreset.plain => null,
    _DonutCalloutPreset.surface => LabelStyle(
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
    _DonutCalloutPreset.accent => LabelStyle(
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
    _DonutCalloutPreset.highContrast => const LabelStyle(
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
    _DonutCalloutPreset.simpleValues => LabelStyle(
      textStyle: TextStyle(
        color:
            (_labelLayout == _DonutLabelLayout.split ||
                _labelPosition == PieDataLabelPosition.outside)
            ? (theme.axisStyle.labelStyle.color ?? const Color(0xFF374151))
            : const Color(0xFFFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0x00000000),
      borderColor: const Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: const EdgeInsets.all(2),
    ),
  };

  LabelStyle get _insidePercentageStyle => switch (_insideShareStyle) {
    _DonutInsideShareStyle.autoContrast => const LabelStyle(
      textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.all(2),
    ),
    _DonutInsideShareStyle.darkBadge => const LabelStyle(
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
    _DonutInsideShareStyle.lightBadge => const LabelStyle(
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
    _DonutTooltipPreset.theme => theme.interactionTheme.tooltipStyle,
    _DonutTooltipPreset.elevated =>
      theme.interactionTheme.tooltipStyle.copyWith(
        borderRadius: 9,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shadowColor: const Color(0x401A1A1A),
        shadowBlurRadius: 12,
      ),
    _DonutTooltipPreset.highContrast => const LabelStyle(
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.black,
      borderColor: Colors.white,
      borderWidth: 2,
      borderRadius: 6,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    ),
  };

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
    if (revision == null) return;
    final selectedPoints = _chartController.selectedPointRefs;
    final targetPoints = _expandedVisibleSliceRefs(points);
    if (targetPoints.isNotEmpty &&
        selectedPoints.length == targetPoints.length &&
        selectedPoints.containsAll(targetPoints)) {
      _chartController.clearPointSelection();
      setState(() => _selectedCategory = null);
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      final selected = points.firstOrNull;
      final category = selected == null
          ? null
          : _buildSeries()
                .visibleSliceForSourcePointIndex(selected.pointIndex)
                ?.point
                .label;
      setState(() => _selectedCategory = category);
    }
  }

  Set<ChartPointRef> _expandedVisibleSliceRefs(List<ChartPointRef> points) {
    final series = _buildSeries();
    final expanded = <ChartPointRef>{};
    for (final ref in points) {
      final slice = series.visibleSliceForSourcePointIndex(ref.pointIndex);
      if (slice == null) {
        expanded.add(ref);
        continue;
      }
      expanded.addAll([
        for (final pointIndex in slice.sourcePointIndices)
          ChartPointRef(seriesId: ref.seriesId, pointIndex: pointIndex),
      ]);
    }
    return expanded;
  }

  void _setGroupingEnabled(bool value) {
    _chartController.clearPointSelection();
    setState(() {
      _groupSmallSlices = value;
      _selectedCategory = null;
      _clearPortableState();
    });
  }

  void _handlePointActivation(ChartDataPoint point, String seriesId) {
    final reference = ChartPointRef(
      seriesId: seriesId,
      pointIndex: point.x.round(),
    );
    final isSelected = _chartController.selectedPointRefs.contains(reference);
    setState(() => _selectedCategory = isSelected ? point.label : null);
  }

  void _clearPortableState() {
    _capturedArtifact = null;
    _restoredConfiguration = null;
    _portableJson = null;
    _captureError = null;
    _showRestoredCopy = false;
  }

  Future<void> _capturePortableCopy() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });
    final captured = await _chartController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'donut-showcase-${DateTime.now().microsecondsSinceEpoch}',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'donut-${_story.name}',
          radialFormatterDescriptors: {
            'donut-${_story.name}': _radialFormatterDescriptors(
              includeRadius: _radiusValues.isNotEmpty,
            ),
          },
        ),
        previewOptions: const ChartPreviewOptions(pixelRatio: 0.75),
      ),
    );
    if (!mounted) return;
    if (captured case ChartArtifactFailure<ChartArtifact>()) {
      setState(() {
        _isCapturing = false;
        _captureError =
            '${captured.error.message} Try again after the chart finishes rendering.';
      });
      return;
    }
    final artifact = (captured as ChartArtifactSuccess<ChartArtifact>).value;
    final encoded = ChartArtifactJsonCodec.encode(artifact);
    if (encoded case ChartArtifactFailure<String>()) {
      setState(() {
        _isCapturing = false;
        _captureError = encoded.error.message;
      });
      return;
    }
    final json = (encoded as ChartArtifactSuccess<String>).value;
    final hydrated = ChartDocumentHydrator.hydrateJson(json);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _isCapturing = false;
        _captureError = hydrated.error.message;
      });
      return;
    }
    setState(() {
      _isCapturing = false;
      _capturedArtifact = artifact;
      _portableJson = json;
      _restoredConfiguration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
    });
  }

  List<Widget> _buildOptions() {
    return orderRadialOptionSections([
      RadialOptionEntry(
        RadialOptionSectionKind.chartTheme,
        OptionSection(
          title: 'Chart theme',
          icon: Icons.contrast_outlined,
          children: [
            EnumOption<_DonutThemePreset>(
              key: const ValueKey('donut-theme'),
              label: 'Theme',
              value: _themePreset,
              values: _DonutThemePreset.values,
              labelBuilder: _themePresetName,
              onChanged: (value) => setState(() => _themePreset = value),
            ),
            EnumOption<_DonutPalette>(
              key: const ValueKey('donut-palette'),
              label: 'Color palette',
              value: _palette,
              values: _DonutPalette.values,
              labelBuilder: _paletteName,
              onChanged: (value) => setState(() => _palette = value),
            ),
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.demoData,
        OptionSection(
          title: 'Demo data',
          icon: Icons.dataset_outlined,
          children: [
            IntSliderOption(
              key: const ValueKey('donut-data-point-count'),
              label: 'Data points',
              value: _categoryCount,
              min: radialDemoMinimumDataPoints,
              max: radialDemoMaximumDataPoints,
              suffix: 'points',
              onChanged: _setCategoryCount,
            ),
            Text(
              'Changing the count creates a new random distribution while '
              'preserving the ${_story.unit} total.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('regenerate-donut-values'),
                onPressed: _regenerateValues,
                icon: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('Regenerate values'),
              ),
            ),
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.geometry,
        OptionSection(
          title: 'Donut geometry',
          icon: Icons.donut_large_outlined,
          children: [
            SliderOption(
              label: 'Inner radius',
              value: _innerRadiusFactor * 100,
              min: 20,
              max: 82,
              divisions: 31,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _innerRadiusFactor = value / 100),
            ),
            SliderOption(
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
              label: 'Outer radius',
              value: _radiusFactor * 100,
              min: 55,
              max: 100,
              divisions: 9,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _radiusFactor = value / 100),
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
            EnumOption<_DonutGradientPreset>(
              key: const ValueKey('donut-gradient'),
              label: 'Slice fill',
              value: _gradientPreset,
              values: _DonutGradientPreset.values,
              labelBuilder: _gradientPresetName,
              onChanged: (value) => setState(() => _gradientPreset = value),
            ),
            if (_gradientPreset != _DonutGradientPreset.solid) ...[
              BoolOption(
                key: const ValueKey('donut-fixed-gradient-colors'),
                label: 'Use fixed gradient colors',
                value: _useFixedGradientColors,
                onChanged: (value) =>
                    setState(() => _useFixedGradientColors = value),
                subtitle: 'Off derives both stops from each category color',
              ),
              if (_useFixedGradientColors) ...[
                ColorOption(
                  key: const ValueKey('donut-gradient-start-color'),
                  label: 'Gradient start',
                  value: _gradientStartColor,
                  colors: _colorChoices,
                  onChanged: (value) =>
                      setState(() => _gradientStartColor = value),
                ),
                ColorOption(
                  key: const ValueKey('donut-gradient-end-color'),
                  label: 'Gradient end',
                  value: _gradientEndColor,
                  colors: _colorChoices,
                  onChanged: (value) =>
                      setState(() => _gradientEndColor = value),
                ),
              ] else ...[
                SliderOption(
                  key: const ValueKey('donut-gradient-start-shift'),
                  label: 'Start lightness',
                  value: _gradientStartLightnessShift * 100,
                  min: -40,
                  max: 40,
                  divisions: 16,
                  suffix: '%',
                  decimalPlaces: 0,
                  onChanged: (value) => setState(
                    () => _gradientStartLightnessShift = value / 100,
                  ),
                ),
                SliderOption(
                  key: const ValueKey('donut-gradient-end-shift'),
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
              if (_gradientPreset == _DonutGradientPreset.linear)
                SliderOption(
                  key: const ValueKey('donut-gradient-angle'),
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
              key: const ValueKey('donut-opacity'),
              label: 'Transparency',
              value: _sliceOpacity * 100,
              min: 20,
              max: 100,
              divisions: 16,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _sliceOpacity = value / 100),
            ),
            SliderOption(
              key: const ValueKey('donut-slice-gap'),
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
              key: const ValueKey('donut-border-width'),
              label: 'Border width',
              value: _borderWidth,
              min: 0,
              max: 4,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _borderWidth = value),
            ),
            if (_borderWidth > 0) ...[
              EnumOption<_DonutBorderPreset>(
                key: const ValueKey('donut-border-color'),
                label: 'Border color',
                value: _borderPreset,
                values: _DonutBorderPreset.values,
                labelBuilder: _borderPresetName,
                onChanged: (value) => setState(() => _borderPreset = value),
              ),
              if (_borderPreset == _DonutBorderPreset.fixed)
                ColorOption(
                  key: const ValueKey('donut-fixed-border-color'),
                  label: 'Fixed border',
                  value: _fixedBorderColor,
                  colors: _colorChoices,
                  onChanged: (value) =>
                      setState(() => _fixedBorderColor = value),
                ),
            ],
            SliderOption(
              key: const ValueKey('donut-corner-radius'),
              label: 'Rounded corners',
              value: _cornerRadius,
              min: 0,
              max: 20,
              divisions: 20,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _cornerRadius = value),
            ),
            if (_cornerRadius > 0)
              EnumOption<PieCornerTreatment>(
                key: const ValueKey('donut-corner-treatment'),
                label: 'Corner treatment',
                value: _cornerTreatment,
                values: PieCornerTreatment.values,
                labelBuilder: _cornerTreatmentName,
                onChanged: (value) => setState(() => _cornerTreatment = value),
              ),
            BoolOption(
              key: const ValueKey('donut-slice-shadow'),
              label: 'Slice shadow',
              value: _showShadow,
              onChanged: (value) => setState(() => _showShadow = value),
            ),
            BoolOption(
              key: const ValueKey('donut-selected-glow'),
              label: 'Selected slice glow',
              value: _showSelectedGlow,
              onChanged: (value) => setState(() => _showSelectedGlow = value),
            ),
            if (_showSelectedGlow) ...[
              EnumOption<_DonutGlowColor>(
                key: const ValueKey('donut-glow-color'),
                label: 'Glow color',
                value: _selectedGlowColor,
                values: _DonutGlowColor.values,
                labelBuilder: _glowColorName,
                onChanged: (value) =>
                    setState(() => _selectedGlowColor = value),
              ),
              SliderOption(
                key: const ValueKey('donut-glow-blur'),
                label: 'Glow blur',
                value: _selectedGlowBlur,
                min: 0,
                max: 32,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _selectedGlowBlur = value),
              ),
              SliderOption(
                key: const ValueKey('donut-glow-spread'),
                label: 'Glow spread',
                value: _selectedGlowSpread,
                min: 0,
                max: 8,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) =>
                    setState(() => _selectedGlowSpread = value),
              ),
              SliderOption(
                key: const ValueKey('donut-glow-opacity'),
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
                key: const ValueKey('donut-glow-offset'),
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
        RadialOptionSectionKind.motion,
        OptionSection(
          title: 'Motion',
          icon: Icons.animation_outlined,
          children: [
            EnumOption<PieAnimationMode>(
              key: const ValueKey('donut-animation-mode'),
              label: 'Entrance',
              value: _animationMode,
              values: PieAnimationMode.values,
              labelBuilder: _animationModeName,
              onChanged: _setAnimationMode,
              subtitle:
                  'Grow, reveal around the ring, fade, or render instantly',
            ),
            EnumOption<RadialDataTransitionMode>(
              key: const ValueKey('donut-data-transition-mode'),
              label: 'Data updates',
              value: _dataTransitionMode,
              values: RadialDataTransitionMode.values,
              labelBuilder: (value) => switch (value) {
                RadialDataTransitionMode.none => 'Instant',
                RadialDataTransitionMode.automatic => 'Identity-aware',
              },
              onChanged: (value) => setState(() => _dataTransitionMode = value),
              subtitle: 'Morph stable categories; fade structural changes',
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('replay-donut-entrance'),
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
        RadialOptionSectionKind.centerContent,
        OptionSection(
          title: 'Center content',
          icon: Icons.center_focus_strong_outlined,
          children: [
            BoolOption(
              label: 'Show center content',
              value: _showCenterContent,
              onChanged: (value) => setState(() => _showCenterContent = value),
              subtitle: 'Portable text included in previews and artifacts',
            ),
            if (_showCenterContent) ...[
              EnumOption<DonutCenterValueMode>(
                label: 'Value source',
                value: _centerValueMode,
                values: DonutCenterValueMode.values,
                labelBuilder: _centerModeName,
                onChanged: (value) => setState(() => _centerValueMode = value),
              ),
              EnumOption<_DonutCenterStyle>(
                key: const ValueKey('donut-center-style'),
                label: 'Center style',
                value: _centerStyle,
                values: _DonutCenterStyle.values,
                labelBuilder: (value) => switch (value) {
                  _DonutCenterStyle.theme => 'Theme default',
                  _DonutCenterStyle.compact => 'Compact',
                  _DonutCenterStyle.accent => 'Accent',
                  _DonutCenterStyle.customWidget => 'Custom widget + action',
                },
                onChanged: (value) => setState(() => _centerStyle = value),
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
              key: const ValueKey('donut-selection-effect'),
              label: 'Selection treatment',
              value: _selectionEffect,
              values: RadialSelectionEffect.values,
              labelBuilder: _selectionEffectName,
              subtitle: 'Pull a slice outward or raise it towards the viewer',
              onChanged: (value) => setState(() => _selectionEffect = value),
            ),
            if (_selectionEffect == RadialSelectionEffect.explode)
              SliderOption(
                key: const ValueKey('donut-selection-explode-offset'),
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
                key: const ValueKey('donut-selection-lift-scale'),
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
                key: const ValueKey('donut-selection-lift-offset'),
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
                key: const ValueKey('donut-selection-backdrop-blur'),
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
        RadialOptionSectionKind.smallCategories,
        OptionSection(
          title: 'Small categories',
          icon: Icons.call_merge_outlined,
          children: [
            BoolOption(
              key: const ValueKey('donut-group-small-slices'),
              label: 'Group small slices',
              value: _groupSmallSlices,
              onChanged: _setGroupingEnabled,
              subtitle: _radiusValues.isNotEmpty
                  ? 'Group angle and aggregate radius by the policy below'
                  : 'Render one Other slice while preserving every source row',
            ),
            if (_groupSmallSlices) ...[
              SliderOption(
                key: const ValueKey('donut-grouping-threshold'),
                label: 'Share threshold',
                value: _groupingMinimumShare * 100,
                min: 1,
                max: 15,
                divisions: 14,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) {
                  _chartController.clearPointSelection();
                  setState(() {
                    _groupingMinimumShare = value / 100;
                    _selectedCategory = null;
                    _clearPortableState();
                  });
                },
              ),
              if (_radiusValues.isNotEmpty)
                EnumOption<RadialSliceRadiusAggregation>(
                  key: const ValueKey('donut-radius-aggregation'),
                  label: 'Radius aggregation',
                  value: _radiusAggregation,
                  values: RadialSliceRadiusAggregation.values,
                  labelBuilder: _radiusAggregationName,
                  onChanged: (value) => setState(() {
                    _radiusAggregation = value;
                    _clearPortableState();
                  }),
                  subtitle: 'Explicit policy for the grouped second metric',
                ),
            ],
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
              key: const ValueKey('donut-show-labels'),
              label: 'Show slice labels',
              value: _showLabels,
              onChanged: (value) => setState(() => _showLabels = value),
            ),
            if (_showLabels) ...[
              EnumOption<_DonutLabelLayout>(
                key: const ValueKey('donut-label-layout'),
                label: 'Layout',
                value: _labelLayout,
                values: _DonutLabelLayout.values,
                labelBuilder: (value) => switch (value) {
                  _DonutLabelLayout.single => 'One label per slice',
                  _DonutLabelLayout.split => 'Category outside + share inside',
                },
                onChanged: (value) => setState(() => _labelLayout = value),
              ),
              if (_labelLayout == _DonutLabelLayout.single) ...[
                EnumOption<PieDataLabelPosition>(
                  key: const ValueKey('donut-label-position'),
                  label: 'Position',
                  value: _labelPosition,
                  values: PieDataLabelPosition.values,
                  labelBuilder: _labelPositionName,
                  onChanged: (value) => setState(() => _labelPosition = value),
                ),
                EnumOption<PieDataLabelContent>(
                  key: const ValueKey('donut-label-content'),
                  label: 'Content',
                  value: _labelContent,
                  values: PieDataLabelContent.values,
                  labelBuilder: _dataLabelContentName,
                  onChanged: (value) => setState(() => _labelContent = value),
                ),
              ],
              EnumOption<_DonutCalloutPreset>(
                key: const ValueKey('donut-primary-label-style'),
                label: _labelLayout == _DonutLabelLayout.split
                    ? 'Outside callout style'
                    : 'Label style',
                value: _calloutPreset,
                values: _DonutCalloutPreset.values,
                labelBuilder: _calloutPresetName,
                onChanged: (value) => setState(() => _calloutPreset = value),
              ),
              if (_labelLayout == _DonutLabelLayout.split)
                EnumOption<_DonutInsideShareStyle>(
                  key: const ValueKey('donut-inside-share-style'),
                  label: 'Inside share style',
                  subtitle: 'Styled independently from the outside category',
                  value: _insideShareStyle,
                  values: _DonutInsideShareStyle.values,
                  labelBuilder: _insideShareStyleName,
                  onChanged: (value) =>
                      setState(() => _insideShareStyle = value),
                ),
              SliderOption(
                key: const ValueKey('donut-label-minimum-share'),
                label: 'Minimum share',
                value: _labelMinimumShare * 100,
                min: 0,
                max: 20,
                divisions: 20,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _labelMinimumShare = value / 100),
              ),
              SliderOption(
                key: const ValueKey('donut-label-minimum-sweep'),
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
                key: const ValueKey('donut-label-padding'),
                label: 'Label padding',
                value: _labelPadding,
                min: 0,
                max: 16,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _labelPadding = value),
              ),
              if (_labelLayout == _DonutLabelLayout.split ||
                  _labelPosition == PieDataLabelPosition.inside)
                SliderOption(
                  key: const ValueKey('donut-label-inside-offset'),
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
              if (_labelLayout == _DonutLabelLayout.split ||
                  _labelPosition == PieDataLabelPosition.outside) ...[
                EnumOption<PieDataLabelCollisionStrategy>(
                  key: const ValueKey('donut-label-collision'),
                  label: 'Collision handling',
                  value: _labelCollisionStrategy,
                  values: PieDataLabelCollisionStrategy.values,
                  labelBuilder: _collisionStrategyName,
                  onChanged: (value) =>
                      setState(() => _labelCollisionStrategy = value),
                ),
                SliderOption(
                  key: const ValueKey('donut-label-outside-offset'),
                  label: 'Outside offset',
                  value: _outsideLabelOffset,
                  min: 0,
                  max: 64,
                  divisions: 16,
                  suffix: 'px',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _outsideLabelOffset = value),
                ),
                SliderOption(
                  key: const ValueKey('donut-connector-length'),
                  label: 'Connector length',
                  value: _connectorLength,
                  min: 0,
                  max: 32,
                  divisions: 16,
                  suffix: 'px',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _connectorLength = value),
                ),
                SliderOption(
                  key: const ValueKey('donut-connector-width'),
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
                  key: const ValueKey('donut-custom-connector-color'),
                  label: 'Custom connector color',
                  value: _useCustomConnectorColor,
                  onChanged: (value) =>
                      setState(() => _useCustomConnectorColor = value),
                ),
                if (_useCustomConnectorColor)
                  ColorOption(
                    key: const ValueKey('donut-connector-color'),
                    label: 'Connector color',
                    value: _connectorColor,
                    colors: _colorChoices,
                    onChanged: (value) =>
                        setState(() => _connectorColor = value),
                  ),
              ],
            ],
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
              key: const ValueKey('donut-show-legend'),
              label: 'Show legend',
              value: _showLegend,
              onChanged: (value) => setState(() => _showLegend = value),
            ),
            if (_showLegend) ...[
              EnumOption<_DonutLegendPreset>(
                key: const ValueKey('donut-legend-style'),
                label: 'Legend style',
                value: _legendPreset,
                values: _DonutLegendPreset.values,
                labelBuilder: _legendPresetName,
                onChanged: (value) => setState(() => _legendPreset = value),
              ),
              EnumOption<_DonutLegendContent>(
                key: const ValueKey('donut-legend-content'),
                label: 'Item content',
                value: _legendContent,
                values: _DonutLegendContent.values,
                labelBuilder: _legendContentName,
                onChanged: (value) => setState(() => _legendContent = value),
              ),
              EnumOption<LegendPosition>(
                key: const ValueKey('donut-legend-position'),
                label: 'Position',
                value: _legendPosition,
                values: LegendPosition.values,
                labelBuilder: _legendPositionName,
                onChanged: (value) => setState(() => _legendPosition = value),
              ),
              EnumOption<LegendOrientation>(
                key: const ValueKey('donut-legend-orientation'),
                label: 'Orientation',
                value: _legendOrientation,
                values: LegendOrientation.values,
                labelBuilder: _legendOrientationName,
                onChanged: (value) =>
                    setState(() => _legendOrientation = value),
              ),
              EnumOption<LegendMarkerShape>(
                key: const ValueKey('donut-legend-marker-shape'),
                label: 'Marker shape',
                value: _legendMarkerShape,
                values: LegendMarkerShape.values,
                labelBuilder: _legendMarkerShapeName,
                onChanged: (value) =>
                    setState(() => _legendMarkerShape = value),
              ),
              SliderOption(
                key: const ValueKey('donut-legend-marker-size'),
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
                key: const ValueKey('donut-legend-font-size'),
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
                key: const ValueKey('donut-legend-opacity'),
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
              key: const ValueKey('donut-show-tooltips'),
              label: 'Show tooltips',
              value: _showTooltips,
              onChanged: (value) => setState(() => _showTooltips = value),
              subtitle:
                  'Hover, tap, legend, and table selection share one tooltip',
            ),
            if (_showTooltips) ...[
              EnumOption<_DonutTooltipPreset>(
                key: const ValueKey('donut-tooltip-style'),
                label: 'Tooltip style',
                value: _tooltipPreset,
                values: _DonutTooltipPreset.values,
                labelBuilder: _tooltipPresetName,
                onChanged: (value) => setState(() => _tooltipPreset = value),
              ),
              EnumOption<TooltipPosition>(
                key: const ValueKey('donut-tooltip-position'),
                label: 'Preferred position',
                value: _tooltipPosition,
                values: TooltipPosition.values,
                labelBuilder: _tooltipPositionName,
                onChanged: (value) => setState(() => _tooltipPosition = value),
              ),
              BoolOption(
                key: const ValueKey('donut-tooltip-follow-cursor'),
                label: 'Follow pointer',
                value: _tooltipFollowsCursor,
                onChanged: (value) =>
                    setState(() => _tooltipFollowsCursor = value),
              ),
              SliderOption(
                key: const ValueKey('donut-tooltip-offset'),
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
    ]);
  }

  Widget _buildPortableWorkflow({required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final artifact = _capturedArtifact;
    final previewBytes = artifact?.preview?.bytes;
    final captureButton = ElevatedButton.icon(
      key: const ValueKey('capture-donut-artifact'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: _isCapturing ? null : _capturePortableCopy,
      icon: _isCapturing
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt_outlined, size: 18),
      label: Text(_isCapturing ? 'Capturing copy…' : 'Capture portable copy'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPortableHeading(),
                const SizedBox(height: 16),
                captureButton,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPortableHeading()),
                const SizedBox(width: 24),
                captureButton,
              ],
            ),
          if (_captureError != null) ...[
            const SizedBox(height: 16),
            _buildCaptureMessage(
              icon: Icons.error_outline,
              message: _captureError!,
              color: colors.errorContainer,
              foreground: colors.onErrorContainer,
            ),
          ],
          if (artifact == null && _captureError == null) ...[
            const SizedBox(height: 16),
            _buildCaptureMessage(
              icon: Icons.info_outline,
              message:
                  'Capture stores Donut geometry, center content, data, selection state, and a revision-bound PNG preview.',
              color: colors.primaryContainer.withValues(alpha: 0.36),
              foreground: colors.onPrimaryContainer,
            ),
          ],
          if (artifact != null) ...[
            const SizedBox(height: 24),
            _buildCapturedArtifactBody(
              artifact: artifact,
              previewBytes: previewBytes,
              compact: compact,
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: const ValueKey('inspect-donut-artifact-json'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.data_object_outlined),
                title: const Text('Inspect canonical JSON'),
                subtitle: Text('${_portableJson?.length ?? 0} characters'),
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _portableJson ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_showRestoredCopy && _restoredConfiguration != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.restore, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restored from canonical JSON into a fresh chart runtime',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              key: const ValueKey('restored-donut-artifact'),
              height: compact ? 440 : 420,
              child: _restoredConfiguration!.build(
                key: ValueKey('restored-${artifact?.artifactId}'),
                donutCenterBuilder:
                    _centerStyle == _DonutCenterStyle.customWidget
                    ? _buildRuntimeCenter
                    : null,
                onDonutCenterTap: _centerStyle == _DonutCenterStyle.customWidget
                    ? _handleCenterAction
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortableHeading() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capture, transport, and restore',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Save the real Donut as schema-v1 JSON with a PNG preview, then hydrate an independent chart from that portable document.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedArtifactBody({
    required ChartArtifact artifact,
    required Uint8List? previewBytes,
    required bool compact,
  }) {
    final colors = Theme.of(context).colorScheme;
    final preview = AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: previewBytes == null
            ? const Center(child: Text('Preview was not available'))
            : Image.memory(
                previewBytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: 'Captured donut chart preview',
              ),
      ),
    );
    final details = _buildPortableDetails(artifact);
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [preview, const SizedBox(height: 16), details],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: preview),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: details),
      ],
    );
  }

  Widget _buildPortableDetails(ChartArtifact artifact) {
    final colors = Theme.of(context).colorScheme;
    final preview = artifact.preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Schema ${artifact.schemaVersion}')),
            const Chip(label: Text('series.donut')),
            const Chip(label: Text('series.donut.style.v1')),
            if (artifact.document.requiredCapabilities.contains(
              'series.donut.center-content.v1',
            ))
              const Chip(label: Text('series.donut.center-content.v1')),
            if (artifact.document.requiredCapabilities.contains(
              'series.donut.variable-radius.v1',
            ))
              const Chip(label: Text('series.donut.variable-radius.v1')),
            Chip(
              label: Text(
                preview == null
                    ? 'No PNG preview'
                    : '${preview.widthPixels.toInt()} × ${preview.heightPixels.toInt()} PNG',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${artifact.document.series.single.data.pointCount} transported categories · '
          '${artifact.document.requiredCapabilities.length} capabilities · '
          '${_portableJson?.length ?? 0} JSON characters',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('restore-donut-artifact'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => setState(() => _showRestoredCopy = true),
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Restore captured chart'),
        ),
      ],
    );
  }

  Widget _buildCaptureMessage({
    required IconData icon,
    required String message,
    required Color color,
    required Color foreground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGuide({required bool compact}) {
    final features = const [
      _DonutFeature(
        icon: Icons.vertical_split_outlined,
        title: 'Chart, data, or split',
        description:
            'One document drives the Donut and its native category, value, radius, and share table.',
      ),
      _DonutFeature(
        icon: Icons.center_focus_strong_outlined,
        title: 'A meaningful center',
        description:
            'Show totals, selected values, fallback totals, or portable custom text without a widget builder.',
      ),
      _DonutFeature(
        icon: Icons.hub_outlined,
        title: 'One selection identity',
        description:
            'Slices, legends, tables, controllers, and restored charts resolve the same ChartPointRef.',
      ),
      _DonutFeature(
        icon: Icons.view_list_outlined,
        title: 'Host-built legend items',
        description:
            'Replace every visible legend item with a Flutter widget while the package retains responsive layout, selection, and semantics.',
      ),
      _DonutFeature(
        icon: Icons.call_merge_outlined,
        title: 'Group without losing detail',
        description:
            'Small sources can render as Other while tables, exports, selection callbacks, and controller state retain every original point.',
      ),
      _DonutFeature(
        icon: Icons.inventory_2_outlined,
        title: 'Ready to travel',
        description:
            'Canonical JSON carries geometry, styling, center content, data, and a revision-bound PNG preview.',
      ),
    ];
    final columns = compact ? 1 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built for product workflows',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Donut keeps the category contract of Pie while adding a measured center and annular geometry.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 128,
          children: [for (final feature in features) _FeatureTile(feature)],
        ),
      ],
    );
  }

  Widget _buildCodeRecipe() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with one portable series',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'The same public model works in direct Dart configuration, AI tool input, tables, and artifacts.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SelectableText('''DonutChartSeries.fromMap(
  id: 'revenue-share',
  unit: 'USD',
  values: {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 20,
    'Training': 4,
    'Support': 3,
  },
  sliceGroupingConfig: RadialSliceGroupingConfig(
    minimumShare: 0.05,
    label: 'Other',
  ),
  donutStyle: DonutChartStyle(innerRadiusFactor: 0.58),
  selectionStyle: RadialSelectionStyle(
    effect: RadialSelectionEffect.lift,
    liftScale: 1.1,
    liftOffset: 6,
  ),
  centerContent: DonutCenterContent(
    label: 'Revenue',
    valueMode: DonutCenterValueMode.selectedOrTotal,
  ),
)''', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _selectStory(_DonutStory story) {
    _chartController.clearPointSelection();
    setState(() {
      _story = story;
      _values = Map<String, num>.of(story.values);
      _radiusValues = Map<String, num>.of(story.radiusValues);
      _categoryCount = _values.length;
      _selectedCategory = null;
      _centerActionCount = 0;
      _clearPortableState();
      switch (story) {
        case _DonutStory.contribution:
          _innerRadiusFactor = 0.58;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _radiusFactor = 0.86;
          _sliceGap = 3;
          _cornerRadius = 8;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.lift;
          _selectionLiftScale = 1.1;
          _selectionLiftOffset = 6;
          _selectionBackdropBlur = 1.25;
          _animationMode = PieAnimationMode.grow;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerStyle = _DonutCenterStyle.theme;
          _legendContent = _DonutLegendContent.standard;
          _groupSmallSlices = false;
        case _DonutStory.progress:
          _innerRadiusFactor = 0.68;
          _sweepAngleDegrees = 280;
          _startAngleDegrees = 130;
          _radiusFactor = 0.9;
          _sliceGap = 2;
          _cornerRadius = 12;
          _selectionExplodeOffset = 8;
          _selectionEffect = RadialSelectionEffect.lift;
          _selectionLiftScale = 1.12;
          _selectionLiftOffset = 8;
          _selectionBackdropBlur = 1.5;
          _animationMode = PieAnimationMode.sweep;
          _centerValueMode = DonutCenterValueMode.custom;
          _centerStyle = _DonutCenterStyle.accent;
          _legendContent = _DonutLegendContent.valueCards;
          _groupSmallSlices = false;
        case _DonutStory.reach:
          _innerRadiusFactor = 0.3;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _radiusFactor = 0.88;
          _sliceGap = 4;
          _cornerRadius = 10;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.lift;
          _selectionLiftScale = 1.1;
          _selectionLiftOffset = 6;
          _selectionBackdropBlur = 1;
          _animationMode = PieAnimationMode.fade;
          _centerValueMode = DonutCenterValueMode.total;
          _centerStyle = _DonutCenterStyle.compact;
          _legendContent = _DonutLegendContent.standard;
          _groupSmallSlices = false;
        case _DonutStory.grouping:
          _innerRadiusFactor = 0.58;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _radiusFactor = 0.88;
          _sliceGap = 3;
          _cornerRadius = 8;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.explode;
          _selectionLiftScale = 1.08;
          _selectionLiftOffset = 6;
          _selectionBackdropBlur = 1.25;
          _animationMode = PieAnimationMode.sweep;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerStyle = _DonutCenterStyle.theme;
          _legendContent = _DonutLegendContent.standard;
          _groupSmallSlices = true;
          _groupingMinimumShare = 0.07;
      }
    });
  }

  String _themePresetName(_DonutThemePreset value) => switch (value) {
    _DonutThemePreset.light => 'Light',
    _DonutThemePreset.dark => 'Dark',
    _DonutThemePreset.highContrast => 'High contrast',
    _DonutThemePreset.colorblind => 'Colorblind friendly',
  };

  String _paletteName(_DonutPalette value) => switch (value) {
    _DonutPalette.theme => 'Theme colors',
    _DonutPalette.ocean => 'Ocean',
    _DonutPalette.sunset => 'Sunset',
    _DonutPalette.earth => 'Earth',
    _DonutPalette.monochrome => 'Monochrome',
  };

  String _gradientPresetName(_DonutGradientPreset value) => switch (value) {
    _DonutGradientPreset.solid => 'Solid color',
    _DonutGradientPreset.linear => 'Linear gradient',
    _DonutGradientPreset.radial => 'Radial gradient',
  };

  String _borderPresetName(_DonutBorderPreset value) => switch (value) {
    _DonutBorderPreset.chartTheme => 'Chart theme outline',
    _DonutBorderPreset.darkerSlice => 'Darker slice shade',
    _DonutBorderPreset.shiftedHue => 'Shifted slice hue',
    _DonutBorderPreset.fixed => 'Fixed color',
  };

  String _cornerTreatmentName(PieCornerTreatment value) => switch (value) {
    PieCornerTreatment.roundAll => 'Round inner and outer',
    PieCornerTreatment.outerOnly => 'Round outside only',
    PieCornerTreatment.circularCenter => 'Force circular center',
  };

  String _glowColorName(_DonutGlowColor value) => switch (value) {
    _DonutGlowColor.slice => 'Selected slice color',
    _DonutGlowColor.accent => 'Palette accent',
    _DonutGlowColor.neutral => 'Theme foreground',
  };

  String _labelPositionName(PieDataLabelPosition value) => switch (value) {
    PieDataLabelPosition.inside => 'Inside slices',
    PieDataLabelPosition.outside => 'Outside with connectors',
  };

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

  String _calloutPresetName(_DonutCalloutPreset value) => switch (value) {
    _DonutCalloutPreset.plain => 'Plain text',
    _DonutCalloutPreset.surface => 'Raised surface',
    _DonutCalloutPreset.accent => 'Palette accent',
    _DonutCalloutPreset.highContrast => 'High contrast',
    _DonutCalloutPreset.simpleValues => 'Simple values',
  };

  String _insideShareStyleName(_DonutInsideShareStyle value) => switch (value) {
    _DonutInsideShareStyle.autoContrast => 'Auto-contrast text',
    _DonutInsideShareStyle.darkBadge => 'Dark badge',
    _DonutInsideShareStyle.lightBadge => 'Light badge',
  };

  String _collisionStrategyName(PieDataLabelCollisionStrategy value) =>
      switch (value) {
        PieDataLabelCollisionStrategy.none => 'Allow overlap',
        PieDataLabelCollisionStrategy.shift => 'Shift labels',
        PieDataLabelCollisionStrategy.shiftAndHide => 'Shift, then hide',
      };

  String _legendPresetName(_DonutLegendPreset value) => switch (value) {
    _DonutLegendPreset.theme => 'Chart theme',
    _DonutLegendPreset.compact => 'Compact',
    _DonutLegendPreset.surface => 'Raised surface',
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

  String _tooltipPresetName(_DonutTooltipPreset value) => switch (value) {
    _DonutTooltipPreset.theme => 'Chart theme',
    _DonutTooltipPreset.elevated => 'Elevated surface',
    _DonutTooltipPreset.highContrast => 'High contrast',
  };

  String _tooltipPositionName(TooltipPosition value) => switch (value) {
    TooltipPosition.auto => 'Automatic',
    TooltipPosition.top => 'Above',
    TooltipPosition.bottom => 'Below',
    TooltipPosition.left => 'Left',
    TooltipPosition.right => 'Right',
  };

  String _centerModeName(DonutCenterValueMode mode) => switch (mode) {
    DonutCenterValueMode.total => 'Total',
    DonutCenterValueMode.selectedValue => 'Selected value',
    DonutCenterValueMode.selectedOrTotal => 'Selected or total',
    DonutCenterValueMode.custom => 'Custom text',
  };

  String _animationModeName(PieAnimationMode mode) => switch (mode) {
    PieAnimationMode.none => 'No animation',
    PieAnimationMode.grow => 'Grow',
    PieAnimationMode.sweep => 'Sweep',
    PieAnimationMode.fade => 'Fade',
  };

  String _selectionEffectName(RadialSelectionEffect effect) => switch (effect) {
    RadialSelectionEffect.explode => 'Pull outward',
    RadialSelectionEffect.lift => 'Lift towards viewer',
  };

  String _legendContentName(_DonutLegendContent value) => switch (value) {
    _DonutLegendContent.standard => 'Standard details',
    _DonutLegendContent.valueCards => 'Custom value cards',
  };

  String _radiusAggregationName(RadialSliceRadiusAggregation value) =>
      switch (value) {
        RadialSliceRadiusAggregation.sum => 'Sum',
        RadialSliceRadiusAggregation.mean => 'Mean',
        RadialSliceRadiusAggregation.weightedMean => 'Weighted mean',
        RadialSliceRadiusAggregation.minimum => 'Minimum',
        RadialSliceRadiusAggregation.maximum => 'Maximum',
      };

  RadialFormatterDocumentDescriptors _radialFormatterDescriptors({
    required bool includeRadius,
  }) => RadialFormatterDocumentDescriptors(
    value: ChartFormatterDescriptor(
      id: 'braven.number.fixed',
      arguments: {
        'decimals': JsonNumberValue(1),
        'suffix': JsonStringValue(' ${_story.unit}'),
      },
    ).toDocument(),
    percentage: ChartFormatterDescriptor(
      id: 'braven.number.percent',
      arguments: {'decimals': JsonNumberValue(0)},
    ).toDocument(),
    radius: includeRadius
        ? ChartFormatterDescriptor(
            id: 'braven.number.fixed',
            arguments: {
              'decimals': JsonNumberValue(0),
              'suffix': const JsonStringValue(' k users'),
            },
          ).toDocument()
        : null,
    center: ChartFormatterDescriptor(
      id: 'braven.number.fixed',
      arguments: {
        'decimals': JsonNumberValue(0),
        'suffix': JsonStringValue(' ${_story.unit}'),
      },
    ).toDocument(),
  );

  void _regenerateValues() {
    _chartController.clearPointSelection();
    setState(() {
      _selectedCategory = null;
      _randomizeDataset();
      _clearPortableState();
    });
  }

  void _setCategoryCount(int count) {
    if (_categoryCount == count) return;
    _chartController.clearPointSelection();
    setState(() {
      _categoryCount = count;
      _selectedCategory = null;
      _randomizeDataset();
      _clearPortableState();
    });
  }

  void _randomizeDataset() {
    final labels = radialDemoLabels(
      preferredLabels: _story.values.keys,
      count: _categoryCount,
    );
    final total = _story.values.values.fold<double>(
      0,
      (sum, value) => sum + value.toDouble(),
    );
    _values = randomRadialDistribution(
      labels: labels,
      total: total,
      random: _random,
    );

    final authoredRadiusValues = _story.radiusValues;
    if (authoredRadiusValues.isEmpty) {
      _radiusValues = const <String, num>{};
      return;
    }
    final radiusRange = authoredRadiusValues.values
        .map((value) => value.toDouble())
        .toList(growable: false);
    _radiusValues = randomRadialMetric(
      labels: labels,
      minimum: radiusRange.reduce((a, b) => a < b ? a : b),
      maximum: radiusRange.reduce((a, b) => a > b ? a : b),
      random: _random,
    );
  }

  void _setAnimationMode(PieAnimationMode mode) {
    setState(() => _animationMode = mode);
  }

  LabelStyle? get _centerLabelStyle => switch (_centerStyle) {
    _DonutCenterStyle.theme => null,
    _DonutCenterStyle.customWidget => null,
    _DonutCenterStyle.compact => const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF64748B), fontSize: 10),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.zero,
    ),
    _DonutCenterStyle.accent => const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF5B55A5), fontSize: 11),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.zero,
    ),
  };

  LabelStyle? get _centerValueStyle => switch (_centerStyle) {
    _DonutCenterStyle.theme => null,
    _DonutCenterStyle.customWidget => null,
    _DonutCenterStyle.compact => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.zero,
    ),
    _DonutCenterStyle.accent => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF4F46E5),
        fontSize: 23,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0x0F4F46E5),
      borderColor: Color(0x334F46E5),
      borderWidth: 1,
      borderRadius: 10,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  };
}

enum _DonutStory { contribution, progress, reach, grouping }

enum _DonutLabelLayout { single, split }

enum _DonutThemePreset { light, dark, highContrast, colorblind }

enum _DonutPalette { theme, ocean, sunset, earth, monochrome }

enum _DonutGradientPreset { solid, linear, radial }

enum _DonutBorderPreset { chartTheme, darkerSlice, shiftedHue, fixed }

enum _DonutGlowColor { slice, accent, neutral }

enum _DonutCalloutPreset { plain, surface, accent, highContrast, simpleValues }

enum _DonutInsideShareStyle { autoContrast, darkBadge, lightBadge }

enum _DonutLegendPreset { theme, compact, surface }

enum _DonutTooltipPreset { theme, elevated, highContrast }

enum _DonutCenterStyle { theme, compact, accent, customWidget }

enum _DonutLegendContent { standard, valueCards }

extension on _DonutStory {
  String get label => switch (this) {
    _DonutStory.contribution => 'Contribution ring',
    _DonutStory.progress => 'Partial sweep',
    _DonutStory.reach => 'Variable radius',
    _DonutStory.grouping => 'Grouped sources',
  };

  String get description => switch (this) {
    _DonutStory.contribution => 'A complete ring for category shares',
    _DonutStory.progress => 'A controlled angular span and opening',
    _DonutStory.reach => 'A second metric controls outer radius',
    _DonutStory.grouping => 'Small sources combine without losing rows',
  };

  IconData get icon => switch (this) {
    _DonutStory.contribution => Icons.donut_large_outlined,
    _DonutStory.progress => Icons.speed_outlined,
    _DonutStory.reach => Icons.radar_outlined,
    _DonutStory.grouping => Icons.call_merge_outlined,
  };

  String get chartTitle => switch (this) {
    _DonutStory.contribution => 'Revenue by product',
    _DonutStory.progress => 'Delivery mix',
    _DonutStory.reach => 'Campaign contribution and reach',
    _DonutStory.grouping => 'Support requests by channel',
  };

  String get chartDescription => switch (this) {
    _DonutStory.contribution =>
      'Five products contribute to total recurring revenue',
    _DonutStory.progress =>
      'The same category contract rendered across a 280° sweep',
    _DonutStory.reach =>
      'Angle shows contribution; outer radius shows audience reach',
    _DonutStory.grouping =>
      'Small channels render as Other while source data stays intact',
  };

  String get seriesName => switch (this) {
    _DonutStory.contribution => 'Revenue',
    _DonutStory.progress => 'Delivery',
    _DonutStory.reach => 'Campaigns',
    _DonutStory.grouping => 'Requests',
  };

  String get unit => switch (this) {
    _DonutStory.contribution => 'USD',
    _DonutStory.progress => 'hours',
    _DonutStory.reach => 'leads',
    _DonutStory.grouping => 'tickets',
  };

  Map<String, num> get values => switch (this) {
    _DonutStory.contribution => const {
      'Subscriptions': 42,
      'Services': 28,
      'Hardware': 16,
      'Training': 9,
      'Other': 5,
    },
    _DonutStory.progress => const {
      'Build': 46,
      'Discovery': 18,
      'Design': 14,
      'Testing': 12,
      'Launch': 7,
      'Support': 3,
    },
    _DonutStory.reach => const {
      'Search': 31,
      'Social': 24,
      'Partners': 19,
      'Events': 15,
      'Email': 11,
    },
    _DonutStory.grouping => const {
      'Portal': 64,
      'Phone': 12,
      'Partners': 9,
      'Email': 6,
      'Chat': 4,
      'Events': 3,
      'Other source': 2,
    },
  };

  Map<String, num> get radiusValues => switch (this) {
    _DonutStory.contribution ||
    _DonutStory.progress ||
    _DonutStory.grouping => const {},
    _DonutStory.reach => const {
      'Search': 82,
      'Social': 54,
      'Partners': 68,
      'Events': 37,
      'Email': 46,
    },
  };
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: theme.textTheme.labelMedium),
      ),
    );
  }
}

class _DonutFeature {
  const _DonutFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile(this.feature);

  final _DonutFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
