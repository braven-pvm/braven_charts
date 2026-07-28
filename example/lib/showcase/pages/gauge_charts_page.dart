// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

enum _GaugePresentation {
  needle('Needle', Icons.speed_outlined),
  solid('Solid', Icons.donut_large_outlined),
  gradient('Gradient', Icons.gradient_outlined),
  zones('Zones', Icons.traffic_outlined),
  target('Target', Icons.flag_outlined),
  legend('Legend', Icons.view_list_outlined),
  popup('Popup', Icons.chat_bubble_outline),
  partial('Partial sweep', Icons.rotate_right_outlined),
  accessible('Accessible', Icons.accessibility_new_outlined),
  density('Density', Icons.density_medium_outlined);

  const _GaugePresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _GaugeGradientPreset { solid, sweep, radial }

enum _GaugeLegendPreset { theme, compact, surface }

enum _GaugeTooltipPreset { theme, elevated, contrast, custom }

enum _GaugeMotionCurve { linear, easeOut, easeOutCubic, easeInOutCubic }

@immutable
class _RandomGaugeState {
  const _RandomGaugeState({
    required this.solid,
    required this.value,
    required this.maximum,
    required this.startAngle,
    required this.sweepAngle,
    required this.clockwise,
    required this.innerRadius,
    required this.outerRadius,
    required this.tickCount,
    required this.tickWidth,
    required this.tickLength,
    required this.scaleLabelSize,
    required this.scaleLabelOffset,
    required this.showZones,
    required this.showTarget,
    required this.showReferenceLabels,
    required this.referenceLabelSize,
    required this.referenceLabelOffset,
    required this.showReferencePanel,
    required this.centerHorizontalOffset,
    required this.centerVerticalOffset,
    required this.centerLineSpacing,
    required this.cornerRadius,
    required this.indicatorOpacity,
    required this.theme,
    required this.gradient,
    required this.fixedGradientColors,
    required this.showLegend,
    required this.legendPosition,
    required this.legendOrientation,
    required this.legendMarkerShape,
    required this.showTooltip,
    required this.tooltipTrigger,
    required this.tooltipPosition,
    required this.tooltipFollowsCursor,
    required this.entranceEnabled,
    required this.entranceDurationMs,
    required this.motionCurve,
  });

  final bool solid;
  final double value;
  final double maximum;
  final double startAngle;
  final double sweepAngle;
  final bool clockwise;
  final double innerRadius;
  final double outerRadius;
  final int tickCount;
  final double tickWidth;
  final double tickLength;
  final double scaleLabelSize;
  final double scaleLabelOffset;
  final bool showZones;
  final bool showTarget;
  final bool showReferenceLabels;
  final double referenceLabelSize;
  final double referenceLabelOffset;
  final bool showReferencePanel;
  final double centerHorizontalOffset;
  final double centerVerticalOffset;
  final double centerLineSpacing;
  final double cornerRadius;
  final double indicatorOpacity;
  final ThemePreset theme;
  final _GaugeGradientPreset gradient;
  final bool fixedGradientColors;
  final bool showLegend;
  final LegendPosition legendPosition;
  final LegendOrientation legendOrientation;
  final LegendMarkerShape legendMarkerShape;
  final bool showTooltip;
  final TooltipTriggerMode tooltipTrigger;
  final TooltipPosition tooltipPosition;
  final bool tooltipFollowsCursor;
  final bool entranceEnabled;
  final int entranceDurationMs;
  final _GaugeMotionCurve motionCurve;
}

/// Public Gauge and Solid Gauge showcase with complete property inspection.
class GaugeChartsPage extends StatefulWidget {
  const GaugeChartsPage({super.key});

  @override
  State<GaugeChartsPage> createState() => _GaugeChartsPageState();
}

class _GaugeChartsPageState extends State<GaugeChartsPage> {
  late final ShowcaseRandomizerController<_RandomGaugeState> _randomizer;
  BravenChartController? _mountedChartController;

  _GaugePresentation _presentation = _GaugePresentation.needle;
  bool _playgroundActive = false;
  int _chartRevision = 0;

  bool _solid = false;
  String _metric = 'CPU utilization';
  String _unit = '%';
  double _minimum = 0;
  double _maximum = 100;
  double _value = 72;
  Color? _indicatorColor;
  ThemePreset _themePreset = ThemePreset.light;

  double _startAngle = -135;
  double _sweepAngle = 270;
  bool _clockwise = true;
  double _innerRadius = 0.56;
  double _outerRadius = 0.88;
  int _tickCount = 6;
  bool _showAxis = true;
  bool _showTicks = true;
  bool _showTickLabels = true;
  bool _showZones = true;
  bool _colorByZone = true;
  Color? _tickColor;
  double? _tickWidth;
  double? _tickLength;
  Color? _scaleLabelColor;
  double _scaleLabelSize = 9;
  bool _scaleLabelBold = false;
  double _scaleLabelOffset = 10;
  double _scaleLabelMaxWidth = 72;

  bool _showMetric = true;
  bool _showValue = true;
  bool _showTargetInCenter = false;
  bool _showStatus = true;
  double _metricFontSize = 13;
  double _valueFontSize = 28;
  double _targetFontSize = 12;
  double _statusFontSize = 12;
  bool _metricBold = false;
  bool _valueBold = true;
  bool _targetBold = false;
  bool _statusBold = true;
  Color? _metricTextColor;
  Color? _valueTextColor;
  Color? _targetTextColor;
  Color? _statusTextColor;
  double _centerHorizontalOffset = 0;
  double _centerVerticalOffset = 0;
  double _centerLineSpacing = 3;

  bool _zonesEnabled = true;
  double _healthyEnd = 60;
  double _elevatedEnd = 85;
  String _healthyStatus = 'Healthy';
  String _elevatedStatus = 'Elevated';
  String _criticalStatus = 'Critical';
  Color? _healthyColor = const Color(0xFF16A34A);
  Color? _elevatedColor = const Color(0xFFF59E0B);
  Color? _criticalColor = const Color(0xFFDC2626);

  bool _targetEnabled = true;
  double _targetValue = 70;
  String _targetLabel = 'SLO';
  Color? _targetColor;
  double _targetWidth = 3;

  bool _thresholdEnabled = true;
  double _thresholdValue = 90;
  String _thresholdLabel = 'Alert';
  Color? _thresholdColor;
  double _thresholdWidth = 1.5;
  bool _thresholdDashed = true;
  bool _showReferenceLabels = true;
  double _referenceInnerOffset = 4;
  double _referenceOuterOffset = 6;
  Color? _referenceLabelColor;
  double _referenceLabelSize = 10;
  bool _referenceLabelBold = true;
  double _referenceLabelOffset = 8;
  double _referenceLabelMaxWidth = 100;
  bool _showReferencePanel = false;
  Color? _referencePanelColor;
  Color? _referencePanelBorderColor;
  double _referencePanelBorderWidth = 1;
  double _referencePanelBorderRadius = 4;
  double _referencePanelPadding = 4;

  double _needleLength = 0.88;
  double _needleWidth = 3;
  Color? _needleColor;
  double _pivotRadius = 6;
  Color? _pivotColor;
  double _axisThickness = 12;
  Color? _axisColor;
  double _axisOpacity = 0.16;

  Color? _trackColor;
  double _trackOpacity = 0.14;
  double _cornerRadius = 8;
  Color? _borderColor;
  double _borderWidth = 0;
  double _solidOpacity = 1;
  _GaugeGradientPreset _gradientPreset = _GaugeGradientPreset.solid;
  bool _useFixedGradientColors = false;
  Color? _gradientStartColor = const Color(0xFF38BDF8);
  Color? _gradientEndColor = const Color(0xFF1D4ED8);
  double _gradientStartShift = 0.18;
  double _gradientEndShift = -0.08;

  bool _showLegend = false;
  _GaugeLegendPreset _legendPreset = _GaugeLegendPreset.theme;
  LegendPosition _legendPosition = LegendPosition.bottomCenter;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.line;
  double _legendMarkerSize = 14;
  double _legendTextSize = 11;
  double _legendOpacity = 1;
  Color? _legendBackgroundColor;
  Color? _legendBorderColor;
  double _legendBorderWidth = 0;
  double _legendBorderRadius = 8;

  bool _showTooltip = true;
  TooltipTriggerMode _tooltipTrigger = TooltipTriggerMode.both;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowsCursor = false;
  double _tooltipOffset = 8;
  int _tooltipShowDelayMs = 0;
  int _tooltipHideDelayMs = 200;
  _GaugeTooltipPreset _tooltipPreset = _GaugeTooltipPreset.theme;
  Color? _tooltipBackgroundColor;
  Color? _tooltipBorderColor;
  Color? _tooltipTextColor;
  Color? _tooltipShadowColor;
  double _tooltipBorderWidth = 1;
  double _tooltipBorderRadius = 6;
  double _tooltipPadding = 8;
  double _tooltipShadowBlur = 4;
  double _tooltipFontSize = 12;

  bool _entranceAnimationEnabled = true;
  int _entranceDurationMs = 400;
  _GaugeMotionCurve _entranceCurve = _GaugeMotionCurve.easeOutCubic;
  int _themeChangeDurationMs = 300;
  _GaugeMotionCurve _themeChangeCurve = _GaugeMotionCurve.easeOut;
  int _interactionDurationMs = 150;
  _GaugeMotionCurve _interactionCurve = _GaugeMotionCurve.easeOut;

  @override
  void initState() {
    super.initState();
    _randomizer = ShowcaseRandomizerController<_RandomGaugeState>(
      generate: _generateRandomState,
      apply: _applyRandomState,
    );
  }

  @override
  void dispose() {
    _randomizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Gauge Charts',
      subtitle:
          'Inspect one operational measurement against an explicit range, status zones, and target',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('gauge-reset-example'),
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
      randomizerKeyPrefix: 'gauge-randomizer',
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
          key: const ValueKey('gauge-showcase-scroll'),
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
      label: 'Choose a Gauge example',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Gauge example',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('gauge-presentation-selector'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final presentation in _GaugePresentation.values)
                    ShowcaseExampleChoiceChip(
                      key: ValueKey('gauge-presentation-${presentation.name}'),
                      label: presentation.label,
                      icon: presentation.icon,
                      selected:
                          !_playgroundActive && _presentation == presentation,
                      onSelected: () => _applyPresentation(presentation),
                    ),
                  PlaygroundChoiceChip(
                    key: const ValueKey('gauge-playground'),
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
    final chartTheme = _buildChartTheme();
    final subtitle =
        '${_solid ? 'Solid arc' : 'Needle'} · '
        '${_minimum.toStringAsFixed(0)}–${_maximum.toStringAsFixed(0)} domain · '
        '${_sweepAngle.toStringAsFixed(0)}° sweep · '
        '${series.status ?? 'No active status'}';
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
                  variableName: 'gaugeChart',
                ),
                splitBreakpoint: 1,
                splitGap: 8,
                minimumChartPaneExtent: 340,
                minimumTablePaneExtent: 420,
                maximumAutoTablePaneExtent: 560,
                autoFitTablePane: true,
                isSplitResizable: true,
                documentOptions: const ChartDocumentExtractOptions(
                  includeViewState: true,
                ),
                tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
                chartBuilder: (context, controller) {
                  _mountedChartController = controller;
                  return BravenChartPlus(
                    key: ValueKey('gauge-chart-$_chartRevision'),
                    series: [series],
                    gaugeChartConfig: config,
                    bravenChartController: controller,
                    theme: chartTheme,
                    showLegend: _showLegend,
                    interactionConfig: InteractionConfig(
                      tooltip: TooltipConfig(
                        enabled: _showTooltip,
                        triggerMode: _tooltipTrigger,
                        preferredPosition: _tooltipPosition,
                        showDelay: Duration(milliseconds: _tooltipShowDelayMs),
                        hideDelay: Duration(milliseconds: _tooltipHideDelayMs),
                        followCursor: _tooltipFollowsCursor,
                        offsetFromPoint: _tooltipOffset,
                        style: _resolvedTooltipStyle(chartTheme),
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

  GaugeChartSeries _buildSeries() {
    final healthyEnd = _resolvedHealthyEnd;
    final elevatedEnd = _resolvedElevatedEnd;
    final zones = _zonesEnabled
        ? <GaugeZone>[
            GaugeZone(
              from: _minimum,
              to: healthyEnd,
              status: _healthyStatus.trim().isEmpty
                  ? 'Healthy'
                  : _healthyStatus.trim(),
              color: _healthyColor,
            ),
            GaugeZone(
              from: healthyEnd,
              to: elevatedEnd,
              status: _elevatedStatus.trim().isEmpty
                  ? 'Elevated'
                  : _elevatedStatus.trim(),
              color: _elevatedColor,
            ),
            GaugeZone(
              from: elevatedEnd,
              to: _maximum,
              status: _criticalStatus.trim().isEmpty
                  ? 'Critical'
                  : _criticalStatus.trim(),
              color: _criticalColor,
            ),
          ]
        : const <GaugeZone>[];
    final target = _targetEnabled
        ? GaugeTarget(
            value: _targetValue.clamp(_minimum, _maximum),
            label: _targetLabel.trim().isEmpty ? null : _targetLabel.trim(),
            color: _targetColor,
            width: _targetWidth,
          )
        : null;
    final thresholds = _thresholdEnabled
        ? <GaugeThreshold>[
            GaugeThreshold(
              value: _thresholdValue.clamp(_minimum, _maximum),
              label: _thresholdLabel.trim().isEmpty
                  ? null
                  : _thresholdLabel.trim(),
              color: _thresholdColor,
              width: _thresholdWidth,
              dashPattern: _thresholdDashed ? const [6, 4] : const [],
            ),
          ]
        : const <GaugeThreshold>[];
    if (_solid) {
      return GaugeChartSeries.solid(
        id: 'gauge-showcase',
        name: _chartTitle,
        metric: _metric.trim().isEmpty ? 'Metric' : _metric.trim(),
        value: _value.clamp(_minimum, _maximum),
        minimum: _minimum,
        maximum: _maximum,
        unit: _unit.trim().isEmpty ? null : _unit.trim(),
        color: _indicatorColor,
        zones: zones,
        target: target,
        thresholds: thresholds,
        style: SolidGaugeStyle(
          trackColor: _trackColor,
          trackOpacity: _trackOpacity,
          cornerRadius: _cornerRadius,
          borderColor: _borderColor,
          borderWidth: _borderWidth,
          opacity: _solidOpacity,
          gradient: _gradientStyle,
        ),
      );
    }
    return GaugeChartSeries.needle(
      id: 'gauge-showcase',
      name: _chartTitle,
      metric: _metric.trim().isEmpty ? 'Metric' : _metric.trim(),
      value: _value.clamp(_minimum, _maximum),
      minimum: _minimum,
      maximum: _maximum,
      unit: _unit.trim().isEmpty ? null : _unit.trim(),
      color: _indicatorColor,
      zones: zones,
      target: target,
      thresholds: thresholds,
      style: NeedleGaugeStyle(
        needleLengthFactor: _needleLength,
        needleWidth: _needleWidth,
        needleColor: _needleColor,
        pivotRadius: _pivotRadius,
        pivotColor: _pivotColor,
        axisThickness: _axisThickness,
        axisColor: _axisColor,
        axisOpacity: _axisOpacity,
      ),
    );
  }

  GaugeChartConfig _buildConfig() => GaugeChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: _startAngle,
      sweepAngleDegrees: _sweepAngle,
      clockwise: _clockwise,
      innerRadiusFactor: _innerRadius,
      outerRadiusFactor: _outerRadius,
    ),
    tickCount: _tickCount,
    showAxis: _showAxis,
    showTicks: _showTicks,
    showTickLabels: _showTickLabels,
    showZones: _showZones,
    colorIndicatorByActiveZone: _colorByZone,
    scale: GaugeScaleStyle(
      tickColor: _tickColor,
      tickWidth: _tickWidth,
      tickLength: _tickLength,
      labelStyle: _labelStyle(
        _scaleLabelColor,
        _scaleLabelSize,
        _scaleLabelBold,
      ),
      labelOffset: _scaleLabelOffset,
      labelMaxWidth: _scaleLabelMaxWidth,
    ),
    references: GaugeReferenceStyle(
      showLabels: _showReferenceLabels,
      innerLineOffset: _referenceInnerOffset,
      outerLineOffset: _referenceOuterOffset,
      labelStyle: _labelStyle(
        _referenceLabelColor,
        _referenceLabelSize,
        _referenceLabelBold,
      ),
      labelOffset: _referenceLabelOffset,
      labelMaxWidth: _referenceLabelMaxWidth,
      showLabelPanel: _showReferencePanel,
      panelColor: _referencePanelColor,
      panelBorderColor: _referencePanelBorderColor,
      panelBorderWidth: _referencePanelBorderWidth,
      panelBorderRadius: _referencePanelBorderRadius,
      panelPadding: _referencePanelPadding,
    ),
    center: GaugeCenterConfig(
      showMetric: _showMetric,
      showValue: _showValue,
      showTarget: _showTargetInCenter,
      showStatus: _showStatus,
      metricStyle: _labelStyle(_metricTextColor, _metricFontSize, _metricBold),
      valueStyle: _labelStyle(_valueTextColor, _valueFontSize, _valueBold),
      targetStyle: _labelStyle(_targetTextColor, _targetFontSize, _targetBold),
      statusStyle: _labelStyle(_statusTextColor, _statusFontSize, _statusBold),
      horizontalOffset: _centerHorizontalOffset,
      verticalOffset: _centerVerticalOffset,
      lineSpacing: _centerLineSpacing,
    ),
  );

  PolarLabelStyle _labelStyle(Color? color, double size, bool bold) =>
      PolarLabelStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      );

  GaugeGradientStyle? get _gradientStyle => switch (_gradientPreset) {
    _GaugeGradientPreset.solid => null,
    _GaugeGradientPreset.sweep => GaugeGradientStyle(
      type: GaugeGradientType.sweep,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartShift,
      endLightnessShift: _gradientEndShift,
    ),
    _GaugeGradientPreset.radial => GaugeGradientStyle(
      type: GaugeGradientType.radial,
      startColor: _useFixedGradientColors ? _gradientStartColor : null,
      endColor: _useFixedGradientColors ? _gradientEndColor : null,
      startLightnessShift: _gradientStartShift,
      endLightnessShift: _gradientEndShift,
    ),
  };

  ChartTheme _buildChartTheme() {
    final base = _themePreset.theme;
    final legendBase = base.legendStyle.copyWith(
      position: _legendPosition,
      orientation: _legendOrientation,
      markerShape: _legendMarkerShape,
      markerSize: _legendMarkerSize,
      textStyle: base.legendStyle.textStyle.copyWith(fontSize: _legendTextSize),
      opacity: _legendOpacity,
      backgroundColor: _legendBackgroundColor,
      borderColor: _legendBorderColor,
      borderWidth: _legendBorderWidth,
      borderRadius: BorderRadius.circular(_legendBorderRadius),
    );
    final legend = switch (_legendPreset) {
      _GaugeLegendPreset.theme => legendBase,
      _GaugeLegendPreset.compact => legendBase.copyWith(
        markerLabelSpacing: 4,
        itemSpacing: 3,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      _GaugeLegendPreset.surface => legendBase.copyWith(
        backgroundColor:
            _legendBackgroundColor ??
            base.backgroundColor.withValues(alpha: 0.94),
        borderColor:
            _legendBorderColor ??
            base.axisStyle.lineColor.withValues(alpha: 0.42),
        borderWidth: math.max(1, _legendBorderWidth),
        textStyle: legendBase.textStyle.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    };
    return base.copyWith(
      legendStyle: legend,
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: _entranceAnimationEnabled
            ? Duration(milliseconds: _entranceDurationMs)
            : Duration.zero,
        dataUpdateCurve: _motionCurve(_entranceCurve),
        themeChangeDuration: Duration(milliseconds: _themeChangeDurationMs),
        themeChangeCurve: _motionCurve(_themeChangeCurve),
        interactionDuration: Duration(milliseconds: _interactionDurationMs),
        interactionCurve: _motionCurve(_interactionCurve),
      ),
    );
  }

  TooltipStyle _resolvedTooltipStyle(ChartTheme theme) {
    final themeStyle = theme.interactionTheme.tooltipStyle;
    final resolved = switch (_tooltipPreset) {
      _GaugeTooltipPreset.theme => TooltipStyle(
        backgroundColor: themeStyle.backgroundColor,
        borderColor: themeStyle.borderColor,
        borderWidth: themeStyle.borderWidth,
        borderRadius: themeStyle.borderRadius,
        shadowColor: themeStyle.shadowColor ?? const Color(0x00000000),
        shadowBlurRadius: themeStyle.shadowBlurRadius ?? 4,
        padding: themeStyle.padding.horizontal / 2,
        textColor:
            themeStyle.textStyle.color ??
            theme.axisStyle.labelStyle.color ??
            const Color(0xFF333333),
        fontSize: themeStyle.textStyle.fontSize ?? 12,
      ),
      _GaugeTooltipPreset.elevated => const TooltipStyle(
        backgroundColor: Color(0xF2FFFFFF),
        borderColor: Color(0x33718096),
        borderWidth: 1,
        borderRadius: 10,
        shadowColor: Color(0x401A1A1A),
        shadowBlurRadius: 12,
        padding: 10,
        textColor: Color(0xFF1F2937),
        fontSize: 12,
      ),
      _GaugeTooltipPreset.contrast => const TooltipStyle(
        backgroundColor: Color(0xFF111827),
        borderColor: Color(0xFFFFFFFF),
        borderWidth: 2,
        borderRadius: 5,
        shadowColor: Color(0x66000000),
        shadowBlurRadius: 8,
        padding: 10,
        textColor: Color(0xFFFFFFFF),
        fontSize: 13,
      ),
      _GaugeTooltipPreset.custom => const TooltipStyle(),
    };
    if (_tooltipPreset != _GaugeTooltipPreset.custom) return resolved;
    return TooltipStyle(
      backgroundColor:
          _tooltipBackgroundColor ?? const TooltipStyle().backgroundColor,
      borderColor: _tooltipBorderColor ?? const TooltipStyle().borderColor,
      borderWidth: _tooltipBorderWidth,
      borderRadius: _tooltipBorderRadius,
      shadowColor: _tooltipShadowColor ?? const TooltipStyle().shadowColor,
      shadowBlurRadius: _tooltipShadowBlur,
      padding: _tooltipPadding,
      textColor: _tooltipTextColor ?? const TooltipStyle().textColor,
      fontSize: _tooltipFontSize,
    );
  }

  Curve _motionCurve(_GaugeMotionCurve value) => switch (value) {
    _GaugeMotionCurve.linear => Curves.linear,
    _GaugeMotionCurve.easeOut => Curves.easeOut,
    _GaugeMotionCurve.easeOutCubic => Curves.easeOutCubic,
    _GaugeMotionCurve.easeInOutCubic => Curves.easeInOutCubic,
  };

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Measurement',
      icon: Icons.speed_outlined,
      description:
          'Defines the one source measurement and its explicit numeric domain.',
      children: [
        SegmentedOption<bool>(
          label: 'Indicator',
          value: _solid,
          options: const [false, true],
          labelBuilder: (value) => value ? 'Solid' : 'Needle',
          onChanged: (value) => setState(() => _solid = value),
        ),
        TextOption(
          label: 'Metric',
          value: _metric,
          onChanged: (value) => setState(() => _metric = value),
        ),
        TextOption(
          label: 'Unit',
          value: _unit,
          onChanged: (value) => setState(() => _unit = value),
        ),
        SliderOption(
          label: 'Value',
          value: _value.clamp(_minimum, _maximum),
          min: _minimum,
          max: _maximum,
          divisions: 100,
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _value = value),
        ),
        SliderOption(
          label: 'Minimum',
          value: _minimum,
          min: -100,
          max: _maximum - 0.1,
          divisions: 100,
          decimalPlaces: 1,
          onChanged: (value) => setState(() {
            _minimum = value;
            _value = _value.clamp(_minimum, _maximum);
            _healthyEnd = _minimum + (_maximum - _minimum) * 0.6;
            _elevatedEnd = _minimum + (_maximum - _minimum) * 0.85;
          }),
        ),
        SliderOption(
          label: 'Maximum',
          value: _maximum,
          min: _minimum + 0.1,
          max: 200,
          divisions: 100,
          decimalPlaces: 1,
          onChanged: (value) => setState(() {
            _maximum = value;
            _value = _value.clamp(_minimum, _maximum);
            _healthyEnd = _resolvedHealthyEnd;
            _elevatedEnd = _resolvedElevatedEnd;
          }),
        ),
        PaletteColorOption(
          label: 'Indicator color',
          subtitle: 'Clear to inherit the chart theme.',
          value: _indicatorColor,
          keyPrefix: 'gauge-indicator-color',
          customColorFallback: const Color(0xFF2563EB),
          onChanged: (value) => setState(() => _indicatorColor = value),
        ),
        EnumOption<ThemePreset>(
          label: 'Theme',
          value: _themePreset,
          values: ThemePreset.values,
          labelBuilder: (value) => value.displayName,
          onChanged: (value) => setState(() => _themePreset = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Pane and scale',
      icon: Icons.rotate_right_outlined,
      description:
          'Controls the polar pane, direction, ticks, axis, labels, and visible status zones.',
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
          min: 0.1,
          max: math.max(0.1, _outerRadius - 0.1),
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
        IntSliderOption(
          label: 'Tick count',
          value: _tickCount,
          min: 2,
          max: 12,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
        BoolOption(
          label: 'Axis',
          value: _showAxis,
          onChanged: (value) => setState(() => _showAxis = value),
        ),
        BoolOption(
          label: 'Ticks',
          value: _showTicks,
          onChanged: (value) => setState(() => _showTicks = value),
        ),
        BoolOption(
          label: 'Tick labels',
          value: _showTickLabels,
          onChanged: (value) => setState(() => _showTickLabels = value),
        ),
        BoolOption(
          label: 'Zone bands',
          value: _showZones,
          onChanged: (value) => setState(() => _showZones = value),
        ),
        BoolOption(
          label: 'Color indicator by active zone',
          value: _colorByZone,
          onChanged: (value) => setState(() => _colorByZone = value),
        ),
      ],
    ),
    _buildScaleOptions(),
    _solid ? _buildSolidStyleOptions() : _buildNeedleStyleOptions(),
    _buildZoneOptions(),
    _buildReferenceOptions(),
    _buildCenterOptions(),
    _buildLegendOptions(),
    _buildInteractionOptions(),
    _buildMotionOptions(),
  ];

  Widget _buildScaleOptions() => OptionSection(
    title: 'Scale ticks and labels',
    icon: Icons.straighten_outlined,
    description:
        'Styles numeric ticks and labels independently from the indicator and chart theme.',
    initiallyExpanded: false,
    children: [
      PaletteColorOption(
        label: 'Tick color',
        subtitle: 'Clear to inherit the chart axis theme.',
        value: _tickColor,
        keyPrefix: 'gauge-tick-color',
        customColorFallback: const Color(0xFF64748B),
        onChanged: (value) => setState(() => _tickColor = value),
      ),
      BoolOption(
        label: 'Override tick geometry',
        value: _tickWidth != null || _tickLength != null,
        onChanged: (value) {
          setState(() {
            _tickWidth = value ? (_tickWidth ?? 1) : null;
            _tickLength = value ? (_tickLength ?? 10) : null;
          });
        },
      ),
      if (_tickWidth != null || _tickLength != null) ...[
        SliderOption(
          label: 'Tick width',
          value: _tickWidth ?? 1,
          min: 0.5,
          max: 6,
          divisions: 11,
          suffix: 'px',
          onChanged: (value) => setState(() => _tickWidth = value),
        ),
        SliderOption(
          label: 'Tick length',
          value: _tickLength ?? 10,
          min: 0,
          max: 30,
          divisions: 30,
          suffix: 'px',
          onChanged: (value) => setState(() => _tickLength = value),
        ),
      ],
      SliderOption(
        label: 'Scale label size',
        value: _scaleLabelSize,
        min: 7,
        max: 20,
        divisions: 13,
        suffix: 'px',
        onChanged: (value) => setState(() => _scaleLabelSize = value),
      ),
      BoolOption(
        label: 'Scale labels bold',
        value: _scaleLabelBold,
        onChanged: (value) => setState(() => _scaleLabelBold = value),
      ),
      PaletteColorOption(
        label: 'Scale label color',
        subtitle: 'Clear to inherit the chart axis theme.',
        value: _scaleLabelColor,
        keyPrefix: 'gauge-scale-label-color',
        customColorFallback: const Color(0xFF334155),
        onChanged: (value) => setState(() => _scaleLabelColor = value),
      ),
      SliderOption(
        label: 'Scale label offset',
        description:
            'Edge gap from the tick end; 0 px touches without overlapping.',
        value: _scaleLabelOffset,
        min: 0,
        max: 30,
        divisions: 30,
        suffix: 'px',
        onChanged: (value) => setState(() => _scaleLabelOffset = value),
      ),
      SliderOption(
        label: 'Scale label width',
        value: _scaleLabelMaxWidth,
        min: 36,
        max: 160,
        divisions: 31,
        suffix: 'px',
        onChanged: (value) => setState(() => _scaleLabelMaxWidth = value),
      ),
    ],
  );

  Widget _buildNeedleStyleOptions() => OptionSection(
    title: 'Needle geometry',
    icon: Icons.navigation_outlined,
    description:
        'Controls the pointer, pivot, and passive axis behind the needle.',
    children: [
      SliderOption(
        label: 'Needle length',
        value: _needleLength,
        min: 0.2,
        max: 1,
        divisions: 16,
        decimalPlaces: 2,
        onChanged: (value) => setState(() => _needleLength = value),
      ),
      SliderOption(
        label: 'Needle width',
        value: _needleWidth,
        min: 1,
        max: 12,
        divisions: 22,
        suffix: 'px',
        onChanged: (value) => setState(() => _needleWidth = value),
      ),
      SliderOption(
        label: 'Pivot radius',
        value: _pivotRadius,
        min: 2,
        max: 18,
        divisions: 16,
        suffix: 'px',
        onChanged: (value) => setState(() => _pivotRadius = value),
      ),
      SliderOption(
        label: 'Axis thickness',
        value: _axisThickness,
        min: 2,
        max: 28,
        divisions: 26,
        suffix: 'px',
        onChanged: (value) => setState(() => _axisThickness = value),
      ),
      SliderOption(
        label: 'Axis opacity',
        value: _axisOpacity,
        min: 0,
        max: 1,
        divisions: 20,
        decimalPlaces: 2,
        onChanged: (value) => setState(() => _axisOpacity = value),
      ),
      PaletteColorOption(
        label: 'Needle color',
        value: _needleColor,
        keyPrefix: 'gauge-needle-color',
        customColorFallback: const Color(0xFF2563EB),
        onChanged: (value) => setState(() => _needleColor = value),
      ),
      PaletteColorOption(
        label: 'Pivot color',
        value: _pivotColor,
        keyPrefix: 'gauge-pivot-color',
        customColorFallback: const Color(0xFF0F172A),
        onChanged: (value) => setState(() => _pivotColor = value),
      ),
      PaletteColorOption(
        label: 'Axis color',
        value: _axisColor,
        keyPrefix: 'gauge-axis-color',
        customColorFallback: const Color(0xFF64748B),
        onChanged: (value) => setState(() => _axisColor = value),
      ),
    ],
  );

  Widget _buildSolidStyleOptions() => OptionSection(
    title: 'Solid arc geometry',
    icon: Icons.donut_large_outlined,
    description:
        'Controls the passive track, rounded progress arc, border, and opacity.',
    children: [
      SliderOption(
        label: 'Track opacity',
        value: _trackOpacity,
        min: 0,
        max: 1,
        divisions: 20,
        decimalPlaces: 2,
        onChanged: (value) => setState(() => _trackOpacity = value),
      ),
      SliderOption(
        label: 'Corner radius',
        value: _cornerRadius,
        min: 0,
        max: 24,
        divisions: 24,
        suffix: 'px',
        onChanged: (value) => setState(() => _cornerRadius = value),
      ),
      SliderOption(
        label: 'Border width',
        value: _borderWidth,
        min: 0,
        max: 6,
        divisions: 12,
        suffix: 'px',
        onChanged: (value) => setState(() => _borderWidth = value),
      ),
      SliderOption(
        label: 'Arc opacity',
        value: _solidOpacity,
        min: 0.1,
        max: 1,
        divisions: 18,
        decimalPlaces: 2,
        onChanged: (value) => setState(() => _solidOpacity = value),
      ),
      EnumOption<_GaugeGradientPreset>(
        key: const ValueKey('gauge-gradient-type'),
        label: 'Fill treatment',
        value: _gradientPreset,
        values: _GaugeGradientPreset.values,
        labelBuilder: (value) => switch (value) {
          _GaugeGradientPreset.solid => 'Solid color',
          _GaugeGradientPreset.sweep => 'Sweep gradient',
          _GaugeGradientPreset.radial => 'Radial gradient',
        },
        onChanged: (value) => setState(() => _gradientPreset = value),
      ),
      if (_playgroundActive ||
          _gradientPreset != _GaugeGradientPreset.solid) ...[
        BoolOption(
          key: const ValueKey('gauge-fixed-gradient-colors'),
          label: 'Fixed gradient colors',
          value: _useFixedGradientColors,
          subtitle: 'Off derives both stops from the indicator color.',
          onChanged: (value) => setState(() => _useFixedGradientColors = value),
        ),
        if (_playgroundActive || _useFixedGradientColors) ...[
          PaletteColorOption(
            label: 'Gradient start',
            value: _gradientStartColor,
            keyPrefix: 'gauge-gradient-start',
            customColorFallback: const Color(0xFF38BDF8),
            onChanged: (value) => setState(() => _gradientStartColor = value),
          ),
          PaletteColorOption(
            label: 'Gradient end',
            value: _gradientEndColor,
            keyPrefix: 'gauge-gradient-end',
            customColorFallback: const Color(0xFF1D4ED8),
            onChanged: (value) => setState(() => _gradientEndColor = value),
          ),
        ],
        SliderOption(
          label: 'Start lightness shift',
          value: _gradientStartShift,
          min: -0.5,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _gradientStartShift = value),
        ),
        SliderOption(
          label: 'End lightness shift',
          value: _gradientEndShift,
          min: -0.5,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _gradientEndShift = value),
        ),
      ],
      PaletteColorOption(
        label: 'Track color',
        value: _trackColor,
        keyPrefix: 'gauge-track-color',
        customColorFallback: const Color(0xFF94A3B8),
        onChanged: (value) => setState(() => _trackColor = value),
      ),
      PaletteColorOption(
        label: 'Border color',
        value: _borderColor,
        enabled: _borderWidth > 0,
        onEnabledChanged: (enabled) =>
            setState(() => _borderWidth = enabled ? 1 : 0),
        keyPrefix: 'gauge-border-color',
        customColorFallback: const Color(0xFF0F172A),
        onChanged: (value) => setState(() => _borderColor = value),
      ),
    ],
  );

  Widget _buildLegendOptions() => OptionSection(
    title: 'Legend',
    icon: Icons.view_list_outlined,
    description:
        'An optional informational summary for the single Gauge measurement. It shares the native radial legend layout and never pretends the reading is selectable.',
    initiallyExpanded: false,
    children: [
      BoolOption(
        key: const ValueKey('gauge-show-legend'),
        label: 'Show legend',
        value: _showLegend,
        onChanged: (value) => setState(() => _showLegend = value),
      ),
      if (_playgroundActive || _showLegend) ...[
        EnumOption<_GaugeLegendPreset>(
          key: const ValueKey('gauge-legend-style'),
          label: 'Legend style',
          value: _legendPreset,
          values: _GaugeLegendPreset.values,
          labelBuilder: (value) => switch (value) {
            _GaugeLegendPreset.theme => 'Chart theme',
            _GaugeLegendPreset.compact => 'Compact',
            _GaugeLegendPreset.surface => 'Raised surface',
          },
          onChanged: (value) => setState(() => _legendPreset = value),
        ),
        EnumOption<LegendPosition>(
          key: const ValueKey('gauge-legend-position'),
          label: 'Position',
          value: _legendPosition,
          values: LegendPosition.values,
          labelBuilder: _legendPositionName,
          onChanged: (value) => setState(() => _legendPosition = value),
        ),
        EnumOption<LegendOrientation>(
          key: const ValueKey('gauge-legend-orientation'),
          label: 'Orientation',
          value: _legendOrientation,
          values: LegendOrientation.values,
          labelBuilder: (value) =>
              value == LegendOrientation.horizontal ? 'Horizontal' : 'Vertical',
          onChanged: (value) => setState(() => _legendOrientation = value),
        ),
        EnumOption<LegendMarkerShape>(
          key: const ValueKey('gauge-legend-marker-shape'),
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
          label: 'Marker size',
          value: _legendMarkerSize,
          min: 6,
          max: 24,
          divisions: 18,
          suffix: 'px',
          onChanged: (value) => setState(() => _legendMarkerSize = value),
        ),
        SliderOption(
          label: 'Text size',
          value: _legendTextSize,
          min: 8,
          max: 18,
          divisions: 10,
          suffix: 'px',
          onChanged: (value) => setState(() => _legendTextSize = value),
        ),
        SliderOption(
          label: 'Legend opacity',
          value: _legendOpacity * 100,
          min: 20,
          max: 100,
          divisions: 16,
          suffix: '%',
          onChanged: (value) => setState(() => _legendOpacity = value / 100),
        ),
        SliderOption(
          label: 'Border width',
          value: _legendBorderWidth,
          min: 0,
          max: 4,
          divisions: 8,
          suffix: 'px',
          onChanged: (value) => setState(() => _legendBorderWidth = value),
        ),
        SliderOption(
          label: 'Corner radius',
          value: _legendBorderRadius,
          min: 0,
          max: 24,
          divisions: 24,
          suffix: 'px',
          onChanged: (value) => setState(() => _legendBorderRadius = value),
        ),
        PaletteColorOption(
          label: 'Panel color',
          subtitle: 'Clear to inherit the chart background.',
          value: _legendBackgroundColor,
          keyPrefix: 'gauge-legend-background',
          customColorFallback: const Color(0xFFFFFFFF),
          onChanged: (value) => setState(() => _legendBackgroundColor = value),
        ),
        PaletteColorOption(
          label: 'Border color',
          subtitle: 'Clear to inherit the axis color.',
          value: _legendBorderColor,
          keyPrefix: 'gauge-legend-border',
          customColorFallback: const Color(0xFF94A3B8),
          onChanged: (value) => setState(() => _legendBorderColor = value),
        ),
      ],
    ],
  );

  Widget _buildInteractionOptions() => OptionSection(
    title: 'Tracking and popup',
    icon: Icons.touch_app_outlined,
    description:
        'Controls the complete portable tooltip trigger, placement, timing, and presentation contract.',
    initiallyExpanded: false,
    children: [
      BoolOption(
        key: const ValueKey('gauge-show-tooltip'),
        label: 'Data point popup',
        value: _showTooltip,
        onChanged: (value) => setState(() => _showTooltip = value),
      ),
      if (_playgroundActive || _showTooltip) ...[
        EnumOption<TooltipTriggerMode>(
          key: const ValueKey('gauge-tooltip-trigger'),
          label: 'Trigger',
          value: _tooltipTrigger,
          values: TooltipTriggerMode.values,
          labelBuilder: (value) => switch (value) {
            TooltipTriggerMode.hover => 'Hover / hold',
            TooltipTriggerMode.tap => 'Tap / click',
            TooltipTriggerMode.both => 'Hover and tap',
          },
          onChanged: (value) => setState(() => _tooltipTrigger = value),
        ),
        EnumOption<TooltipPosition>(
          key: const ValueKey('gauge-tooltip-position'),
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
          label: 'Follow pointer',
          value: _tooltipFollowsCursor,
          onChanged: (value) => setState(() => _tooltipFollowsCursor = value),
        ),
        SliderOption(
          label: 'Point offset',
          value: _tooltipOffset,
          min: 0,
          max: 30,
          divisions: 15,
          suffix: 'px',
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
          max: 1500,
          suffix: 'ms',
          onChanged: (value) => setState(() => _tooltipHideDelayMs = value),
        ),
        EnumOption<_GaugeTooltipPreset>(
          key: const ValueKey('gauge-tooltip-style'),
          label: 'Popup style',
          value: _tooltipPreset,
          values: _GaugeTooltipPreset.values,
          labelBuilder: (value) => switch (value) {
            _GaugeTooltipPreset.theme => 'Chart theme',
            _GaugeTooltipPreset.elevated => 'Elevated surface',
            _GaugeTooltipPreset.contrast => 'High contrast',
            _GaugeTooltipPreset.custom => 'Custom',
          },
          onChanged: (value) => setState(() => _tooltipPreset = value),
        ),
        if (_playgroundActive ||
            _tooltipPreset == _GaugeTooltipPreset.custom) ...[
          PaletteColorOption(
            label: 'Popup background',
            value: _tooltipBackgroundColor,
            keyPrefix: 'gauge-tooltip-background',
            customColorFallback: const Color(0xFFFFFFFF),
            onChanged: (value) =>
                setState(() => _tooltipBackgroundColor = value),
          ),
          PaletteColorOption(
            label: 'Popup text',
            value: _tooltipTextColor,
            keyPrefix: 'gauge-tooltip-text',
            customColorFallback: const Color(0xFF1F2937),
            onChanged: (value) => setState(() => _tooltipTextColor = value),
          ),
          PaletteColorOption(
            label: 'Popup border',
            value: _tooltipBorderColor,
            keyPrefix: 'gauge-tooltip-border',
            customColorFallback: const Color(0xFF94A3B8),
            onChanged: (value) => setState(() => _tooltipBorderColor = value),
          ),
          SliderOption(
            label: 'Border width',
            value: _tooltipBorderWidth,
            min: 0,
            max: 4,
            divisions: 8,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipBorderWidth = value),
          ),
          SliderOption(
            label: 'Corner radius',
            value: _tooltipBorderRadius,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipBorderRadius = value),
          ),
          SliderOption(
            label: 'Padding',
            value: _tooltipPadding,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipPadding = value),
          ),
          SliderOption(
            label: 'Text size',
            value: _tooltipFontSize,
            min: 8,
            max: 20,
            divisions: 12,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipFontSize = value),
          ),
          PaletteColorOption(
            label: 'Popup shadow',
            subtitle: 'Clear to remove the shadow.',
            value: _tooltipShadowColor,
            keyPrefix: 'gauge-tooltip-shadow',
            customColorFallback: const Color(0x660F172A),
            onChanged: (value) => setState(() => _tooltipShadowColor = value),
          ),
          SliderOption(
            label: 'Shadow blur',
            value: _tooltipShadowBlur,
            min: 0,
            max: 24,
            divisions: 24,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipShadowBlur = value),
          ),
        ],
      ],
      const InfoBox(
        message:
            'Hover, tap, or focus the indicator to inspect its value, domain, status, and target. The current reading remains data state, not durable selection state.',
      ),
    ],
  );

  Widget _buildMotionOptions() => OptionSection(
    title: 'Motion',
    icon: Icons.animation_outlined,
    description:
        'Controls the Gauge entrance, theme transition, and shared hover response timing.',
    initiallyExpanded: false,
    children: [
      BoolOption(
        key: const ValueKey('gauge-entrance-enabled'),
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
      IntSliderOption(
        label: 'Entrance duration',
        value: _entranceDurationMs,
        min: 0,
        max: 2000,
        suffix: 'ms',
        onChanged: (value) => setState(() => _entranceDurationMs = value),
      ),
      EnumOption<_GaugeMotionCurve>(
        label: 'Entrance curve',
        value: _entranceCurve,
        values: _GaugeMotionCurve.values,
        labelBuilder: _motionCurveName,
        onChanged: (value) => setState(() => _entranceCurve = value),
      ),
      if (_entranceAnimationEnabled)
        ActionButton(
          key: const ValueKey('gauge-replay-entrance'),
          label: 'Replay entrance',
          icon: Icons.replay_outlined,
          onPressed: () => _mountedChartController?.replayRadialEntrance(),
        ),
      IntSliderOption(
        label: 'Theme duration',
        value: _themeChangeDurationMs,
        min: 0,
        max: 1200,
        suffix: 'ms',
        onChanged: (value) => setState(() => _themeChangeDurationMs = value),
      ),
      EnumOption<_GaugeMotionCurve>(
        label: 'Theme curve',
        value: _themeChangeCurve,
        values: _GaugeMotionCurve.values,
        labelBuilder: _motionCurveName,
        onChanged: (value) => setState(() => _themeChangeCurve = value),
      ),
      IntSliderOption(
        label: 'Interaction duration',
        value: _interactionDurationMs,
        min: 0,
        max: 600,
        suffix: 'ms',
        onChanged: (value) => setState(() => _interactionDurationMs = value),
      ),
      EnumOption<_GaugeMotionCurve>(
        label: 'Interaction curve',
        value: _interactionCurve,
        values: _GaugeMotionCurve.values,
        labelBuilder: _motionCurveName,
        onChanged: (value) => setState(() => _interactionCurve = value),
      ),
    ],
  );

  Widget _buildZoneOptions() => OptionSection(
    title: 'Operational zones',
    icon: Icons.traffic_outlined,
    description:
        'Defines ordered, non-overlapping status intervals. Status text preserves meaning when color is unavailable.',
    initiallyExpanded: false,
    children: [
      BoolOption(
        label: 'Configure zones',
        value: _zonesEnabled,
        onChanged: (value) => setState(() => _zonesEnabled = value),
      ),
      SliderOption(
        label: 'Healthy upper bound',
        value: _resolvedHealthyEnd,
        min: _minimum + _zoneStep,
        max: _resolvedElevatedEnd - _zoneStep,
        divisions: 40,
        onChanged: (value) => setState(() => _healthyEnd = value),
      ),
      SliderOption(
        label: 'Elevated upper bound',
        value: _resolvedElevatedEnd,
        min: _resolvedHealthyEnd + _zoneStep,
        max: _maximum - _zoneStep,
        divisions: 40,
        onChanged: (value) => setState(() => _elevatedEnd = value),
      ),
      TextOption(
        label: 'Healthy status',
        value: _healthyStatus,
        onChanged: (value) => setState(() => _healthyStatus = value),
      ),
      PaletteColorOption(
        label: 'Healthy color',
        value: _healthyColor,
        keyPrefix: 'gauge-zone-healthy',
        customColorFallback: const Color(0xFF16A34A),
        onChanged: (value) => setState(() => _healthyColor = value),
      ),
      TextOption(
        label: 'Elevated status',
        value: _elevatedStatus,
        onChanged: (value) => setState(() => _elevatedStatus = value),
      ),
      PaletteColorOption(
        label: 'Elevated color',
        value: _elevatedColor,
        keyPrefix: 'gauge-zone-elevated',
        customColorFallback: const Color(0xFFF59E0B),
        onChanged: (value) => setState(() => _elevatedColor = value),
      ),
      TextOption(
        label: 'Critical status',
        value: _criticalStatus,
        onChanged: (value) => setState(() => _criticalStatus = value),
      ),
      PaletteColorOption(
        label: 'Critical color',
        value: _criticalColor,
        keyPrefix: 'gauge-zone-critical',
        customColorFallback: const Color(0xFFDC2626),
        onChanged: (value) => setState(() => _criticalColor = value),
      ),
    ],
  );

  Widget _buildReferenceOptions() => OptionSection(
    title: 'Target and threshold',
    icon: Icons.flag_outlined,
    description:
        'Target is the preferred reading; threshold is an additional absolute reference. Neither changes status.',
    initiallyExpanded: false,
    children: [
      BoolOption(
        label: 'Target',
        value: _targetEnabled,
        onChanged: (value) => setState(() => _targetEnabled = value),
      ),
      TextOption(
        label: 'Target label',
        value: _targetLabel,
        onChanged: (value) => setState(() => _targetLabel = value),
      ),
      SliderOption(
        label: 'Target value',
        value: _targetValue.clamp(_minimum, _maximum),
        min: _minimum,
        max: _maximum,
        divisions: 100,
        onChanged: (value) => setState(() => _targetValue = value),
      ),
      SliderOption(
        label: 'Target width',
        value: _targetWidth,
        min: 0.5,
        max: 8,
        divisions: 15,
        suffix: 'px',
        onChanged: (value) => setState(() => _targetWidth = value),
      ),
      PaletteColorOption(
        label: 'Target color',
        value: _targetColor,
        keyPrefix: 'gauge-target-color',
        customColorFallback: const Color(0xFF0F172A),
        onChanged: (value) => setState(() => _targetColor = value),
      ),
      BoolOption(
        label: 'Threshold',
        value: _thresholdEnabled,
        onChanged: (value) => setState(() => _thresholdEnabled = value),
      ),
      TextOption(
        label: 'Threshold label',
        value: _thresholdLabel,
        onChanged: (value) => setState(() => _thresholdLabel = value),
      ),
      SliderOption(
        label: 'Threshold value',
        value: _thresholdValue.clamp(_minimum, _maximum),
        min: _minimum,
        max: _maximum,
        divisions: 100,
        onChanged: (value) => setState(() => _thresholdValue = value),
      ),
      SliderOption(
        label: 'Threshold width',
        value: _thresholdWidth,
        min: 0.5,
        max: 6,
        divisions: 11,
        suffix: 'px',
        onChanged: (value) => setState(() => _thresholdWidth = value),
      ),
      BoolOption(
        label: 'Dashed threshold',
        value: _thresholdDashed,
        onChanged: (value) => setState(() => _thresholdDashed = value),
      ),
      PaletteColorOption(
        label: 'Threshold color',
        value: _thresholdColor,
        keyPrefix: 'gauge-threshold-color',
        customColorFallback: const Color(0xFF7C3AED),
        onChanged: (value) => setState(() => _thresholdColor = value),
      ),
      const Divider(),
      BoolOption(
        label: 'Reference labels',
        value: _showReferenceLabels,
        onChanged: (value) => setState(() => _showReferenceLabels = value),
      ),
      SliderOption(
        label: 'Inner line reach',
        value: _referenceInnerOffset,
        min: 0,
        max: 30,
        divisions: 30,
        suffix: 'px',
        onChanged: (value) => setState(() => _referenceInnerOffset = value),
      ),
      SliderOption(
        label: 'Outer callout reach',
        value: _referenceOuterOffset,
        min: 0,
        max: 40,
        divisions: 40,
        suffix: 'px',
        onChanged: (value) => setState(() => _referenceOuterOffset = value),
      ),
      if (_showReferenceLabels) ...[
        SliderOption(
          label: 'Reference label size',
          value: _referenceLabelSize,
          min: 7,
          max: 20,
          divisions: 13,
          suffix: 'px',
          onChanged: (value) => setState(() => _referenceLabelSize = value),
        ),
        BoolOption(
          label: 'Reference labels bold',
          value: _referenceLabelBold,
          onChanged: (value) => setState(() => _referenceLabelBold = value),
        ),
        PaletteColorOption(
          label: 'Reference label color',
          subtitle: 'Clear to inherit each target or threshold color.',
          value: _referenceLabelColor,
          keyPrefix: 'gauge-reference-label-color',
          customColorFallback: const Color(0xFF334155),
          onChanged: (value) => setState(() => _referenceLabelColor = value),
        ),
        SliderOption(
          label: 'Reference label offset',
          description:
              'Edge gap from the callout end; 0 px touches without overlapping.',
          value: _referenceLabelOffset,
          min: 0,
          max: 40,
          divisions: 40,
          suffix: 'px',
          onChanged: (value) => setState(() => _referenceLabelOffset = value),
        ),
        SliderOption(
          label: 'Reference label width',
          value: _referenceLabelMaxWidth,
          min: 40,
          max: 180,
          divisions: 35,
          suffix: 'px',
          onChanged: (value) => setState(() => _referenceLabelMaxWidth = value),
        ),
        BoolOption(
          label: 'Label panels',
          value: _showReferencePanel,
          onChanged: (value) => setState(() => _showReferencePanel = value),
        ),
        if (_showReferencePanel) ...[
          PaletteColorOption(
            label: 'Panel color',
            subtitle: 'Clear to derive a readable chart-theme surface.',
            value: _referencePanelColor,
            keyPrefix: 'gauge-reference-panel-color',
            customColorFallback: const Color(0xFFFFFFFF),
            onChanged: (value) => setState(() => _referencePanelColor = value),
          ),
          PaletteColorOption(
            label: 'Panel border',
            subtitle: 'Clear to inherit the chart axis color.',
            value: _referencePanelBorderColor,
            keyPrefix: 'gauge-reference-panel-border',
            customColorFallback: const Color(0xFF94A3B8),
            onChanged: (value) =>
                setState(() => _referencePanelBorderColor = value),
          ),
          SliderOption(
            label: 'Panel border width',
            value: _referencePanelBorderWidth,
            min: 0,
            max: 4,
            divisions: 8,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _referencePanelBorderWidth = value),
          ),
          SliderOption(
            label: 'Panel corner radius',
            value: _referencePanelBorderRadius,
            min: 0,
            max: 16,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _referencePanelBorderRadius = value),
          ),
          SliderOption(
            label: 'Panel padding',
            value: _referencePanelPadding,
            min: 0,
            max: 12,
            divisions: 12,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _referencePanelPadding = value),
          ),
        ],
      ],
    ],
  );

  Widget _buildCenterOptions() => OptionSection(
    title: 'Center content',
    icon: Icons.text_fields_outlined,
    description:
        'Controls the portable metric, value, target, and status fallback used by artifacts and previews.',
    initiallyExpanded: false,
    children: [
      BoolOption(
        label: 'Metric label',
        value: _showMetric,
        onChanged: (value) => setState(() => _showMetric = value),
      ),
      BoolOption(
        label: 'Value label',
        value: _showValue,
        onChanged: (value) => setState(() => _showValue = value),
      ),
      BoolOption(
        label: 'Target label',
        value: _showTargetInCenter,
        onChanged: (value) => setState(() => _showTargetInCenter = value),
      ),
      BoolOption(
        label: 'Status label',
        value: _showStatus,
        onChanged: (value) => setState(() => _showStatus = value),
      ),
      SliderOption(
        label: 'Horizontal offset',
        value: _centerHorizontalOffset,
        min: -40,
        max: 40,
        divisions: 40,
        suffix: 'px',
        onChanged: (value) => setState(() => _centerHorizontalOffset = value),
      ),
      SliderOption(
        label: 'Vertical offset',
        value: _centerVerticalOffset,
        min: -40,
        max: 40,
        divisions: 40,
        suffix: 'px',
        onChanged: (value) => setState(() => _centerVerticalOffset = value),
      ),
      SliderOption(
        label: 'Line spacing',
        value: _centerLineSpacing,
        min: 0,
        max: 16,
        divisions: 16,
        suffix: 'px',
        onChanged: (value) => setState(() => _centerLineSpacing = value),
      ),
      ..._labelOptions(
        label: 'Metric',
        size: _metricFontSize,
        bold: _metricBold,
        color: _metricTextColor,
        keyPrefix: 'gauge-center-metric',
        onSize: (value) => setState(() => _metricFontSize = value),
        onBold: (value) => setState(() => _metricBold = value),
        onColor: (value) => setState(() => _metricTextColor = value),
      ),
      ..._labelOptions(
        label: 'Value',
        size: _valueFontSize,
        bold: _valueBold,
        color: _valueTextColor,
        keyPrefix: 'gauge-center-value',
        onSize: (value) => setState(() => _valueFontSize = value),
        onBold: (value) => setState(() => _valueBold = value),
        onColor: (value) => setState(() => _valueTextColor = value),
      ),
      ..._labelOptions(
        label: 'Target',
        size: _targetFontSize,
        bold: _targetBold,
        color: _targetTextColor,
        keyPrefix: 'gauge-center-target',
        onSize: (value) => setState(() => _targetFontSize = value),
        onBold: (value) => setState(() => _targetBold = value),
        onColor: (value) => setState(() => _targetTextColor = value),
      ),
      ..._labelOptions(
        label: 'Status',
        size: _statusFontSize,
        bold: _statusBold,
        color: _statusTextColor,
        keyPrefix: 'gauge-center-status',
        onSize: (value) => setState(() => _statusFontSize = value),
        onBold: (value) => setState(() => _statusBold = value),
        onColor: (value) => setState(() => _statusTextColor = value),
      ),
    ],
  );

  List<Widget> _labelOptions({
    required String label,
    required double size,
    required bool bold,
    required Color? color,
    required String keyPrefix,
    required ValueChanged<double> onSize,
    required ValueChanged<bool> onBold,
    required ValueChanged<Color?> onColor,
  }) => [
    SliderOption(
      label: '$label font size',
      value: size,
      min: 8,
      max: 40,
      divisions: 32,
      suffix: 'px',
      onChanged: onSize,
    ),
    BoolOption(label: '$label bold', value: bold, onChanged: onBold),
    PaletteColorOption(
      label: '$label text color',
      value: color,
      keyPrefix: keyPrefix,
      customColorFallback: const Color(0xFF1F2937),
      onChanged: onColor,
    ),
  ];

  void _applyPresentation(_GaugePresentation presentation) {
    _randomizer.pause();
    _randomizer.clear();
    setState(() {
      _playgroundActive = false;
      _presentation = presentation;
      _chartRevision++;
      _applyPresentationState(presentation);
    });
  }

  void _applyPresentationState(_GaugePresentation presentation) {
    _resetCommon();
    switch (presentation) {
      case _GaugePresentation.needle:
        _solid = false;
        _metric = 'CPU utilization';
        _value = 72;
        _startAngle = -135;
        _sweepAngle = 270;
      case _GaugePresentation.solid:
        _solid = true;
        _metric = 'Service availability';
        _minimum = 99;
        _maximum = 100;
        _value = 99.93;
        _healthyEnd = 99.7;
        _elevatedEnd = 99.9;
        _targetValue = 99.9;
        _thresholdValue = 99.75;
        _cornerRadius = 12;
        _startAngle = -150;
        _sweepAngle = 300;
      case _GaugePresentation.gradient:
        _solid = true;
        _metric = 'Release confidence';
        _value = 82;
        _indicatorColor = const Color(0xFF2563EB);
        _gradientPreset = _GaugeGradientPreset.sweep;
        _useFixedGradientColors = true;
        _gradientStartColor = const Color(0xFF22D3EE);
        _gradientEndColor = const Color(0xFF4F46E5);
        _showZones = false;
        _colorByZone = false;
        _trackOpacity = 0.08;
        _cornerRadius = 16;
        _startAngle = -120;
        _sweepAngle = 240;
      case _GaugePresentation.zones:
        _solid = true;
        _metric = 'Queue pressure';
        _value = 86;
        _colorByZone = true;
        _showTargetInCenter = false;
        _startAngle = -180;
        _sweepAngle = 360;
      case _GaugePresentation.target:
        _solid = false;
        _metric = 'Latency budget';
        _unit = 'ms';
        _maximum = 500;
        _value = 318;
        _healthyEnd = 250;
        _elevatedEnd = 400;
        _targetValue = 300;
        _thresholdValue = 450;
        _showTargetInCenter = true;
        _showReferencePanel = true;
        _referenceLabelOffset = 12;
        _referenceLabelSize = 11;
        _startAngle = -90;
        _sweepAngle = 180;
      case _GaugePresentation.legend:
        _solid = true;
        _metric = 'Energy reserve';
        _unit = 'kWh';
        _maximum = 80;
        _value = 54;
        _healthyEnd = 32;
        _elevatedEnd = 60;
        _targetValue = 64;
        _thresholdValue = 20;
        _showLegend = true;
        _legendPreset = _GaugeLegendPreset.surface;
        _legendPosition = LegendPosition.centerRight;
        _legendOrientation = LegendOrientation.vertical;
        _legendMarkerShape = LegendMarkerShape.diamond;
        _gradientPreset = _GaugeGradientPreset.radial;
        _startAngle = -160;
        _sweepAngle = 320;
      case _GaugePresentation.popup:
        _solid = false;
        _metric = 'Safety margin';
        _value = 46;
        _themePreset = ThemePreset.dark;
        _tooltipPreset = _GaugeTooltipPreset.contrast;
        _tooltipTrigger = TooltipTriggerMode.both;
        _tooltipPosition = TooltipPosition.right;
        _tooltipFollowsCursor = true;
        _needleWidth = 5;
        _pivotRadius = 9;
        _showLegend = false;
        _scaleLabelColor = const Color(0xFFE2E8F0);
        _tickColor = const Color(0xFF94A3B8);
        _referenceLabelColor = const Color(0xFFF8FAFC);
        _startAngle = -105;
        _sweepAngle = 210;
      case _GaugePresentation.partial:
        _solid = true;
        _metric = 'Capacity used';
        _value = 64;
        _startAngle = 15;
        _sweepAngle = 150;
        _innerRadius = 0.62;
        _outerRadius = 0.9;
        _scaleLabelOffset = 16;
        _referenceOuterOffset = 14;
      case _GaugePresentation.accessible:
        _solid = false;
        _metric = 'Recovery confidence';
        _value = 58;
        _needleWidth = 6;
        _targetWidth = 5;
        _thresholdWidth = 3;
        _metricFontSize = 16;
        _valueFontSize = 34;
        _statusFontSize = 15;
        _scaleLabelSize = 13;
        _scaleLabelBold = true;
        _tickWidth = 3;
        _tickLength = 16;
        _referenceLabelSize = 13;
        _showReferencePanel = true;
        _referencePanelBorderWidth = 2;
        _referencePanelPadding = 6;
        _showTargetInCenter = true;
        _themePreset = ThemePreset.highContrast;
        _startAngle = -140;
        _sweepAngle = 280;
      case _GaugePresentation.density:
        _solid = true;
        _metric = 'Infrastructure load';
        _value = 81;
        _tickCount = 12;
        _showTargetInCenter = true;
        _showTickLabels = true;
        _thresholdWidth = 2;
        _axisThickness = 18;
        _tickWidth = 0.75;
        _tickLength = 7;
        _scaleLabelSize = 8;
        _scaleLabelOffset = 5;
        _scaleLabelMaxWidth = 48;
        _referenceLabelSize = 9;
        _referenceLabelOffset = 5;
        _referenceLabelMaxWidth = 72;
        _centerVerticalOffset = 8;
        _centerLineSpacing = 1;
        _startAngle = -165;
        _sweepAngle = 330;
    }
  }

  void _resetCommon() {
    _solid = false;
    _metric = 'CPU utilization';
    _unit = '%';
    _minimum = 0;
    _maximum = 100;
    _value = 72;
    _indicatorColor = null;
    _themePreset = ThemePreset.light;
    _startAngle = -135;
    _sweepAngle = 270;
    _clockwise = true;
    _innerRadius = 0.56;
    _outerRadius = 0.88;
    _tickCount = 6;
    _showAxis = true;
    _showTicks = true;
    _showTickLabels = true;
    _showZones = true;
    _colorByZone = true;
    _tickColor = null;
    _tickWidth = null;
    _tickLength = null;
    _scaleLabelColor = null;
    _scaleLabelSize = 9;
    _scaleLabelBold = false;
    _scaleLabelOffset = 10;
    _scaleLabelMaxWidth = 72;
    _showMetric = true;
    _showValue = true;
    _showTargetInCenter = false;
    _showStatus = true;
    _centerHorizontalOffset = 0;
    _centerVerticalOffset = 0;
    _centerLineSpacing = 3;
    _zonesEnabled = true;
    _healthyEnd = 60;
    _elevatedEnd = 85;
    _targetEnabled = true;
    _targetValue = 70;
    _thresholdEnabled = true;
    _thresholdValue = 90;
    _showReferenceLabels = true;
    _referenceInnerOffset = 4;
    _referenceOuterOffset = 6;
    _referenceLabelColor = null;
    _referenceLabelSize = 10;
    _referenceLabelBold = true;
    _referenceLabelOffset = 8;
    _referenceLabelMaxWidth = 100;
    _showReferencePanel = false;
    _referencePanelColor = null;
    _referencePanelBorderColor = null;
    _referencePanelBorderWidth = 1;
    _referencePanelBorderRadius = 4;
    _referencePanelPadding = 4;
    _needleLength = 0.88;
    _needleWidth = 3;
    _pivotRadius = 6;
    _axisThickness = 12;
    _axisOpacity = 0.16;
    _trackOpacity = 0.14;
    _cornerRadius = 8;
    _borderWidth = 0;
    _solidOpacity = 1;
    _gradientPreset = _GaugeGradientPreset.solid;
    _useFixedGradientColors = false;
    _gradientStartColor = const Color(0xFF38BDF8);
    _gradientEndColor = const Color(0xFF1D4ED8);
    _gradientStartShift = 0.18;
    _gradientEndShift = -0.08;
    _showLegend = false;
    _legendPreset = _GaugeLegendPreset.theme;
    _legendPosition = LegendPosition.bottomCenter;
    _legendOrientation = LegendOrientation.horizontal;
    _legendMarkerShape = LegendMarkerShape.line;
    _legendMarkerSize = 14;
    _legendTextSize = 11;
    _legendOpacity = 1;
    _legendBackgroundColor = null;
    _legendBorderColor = null;
    _legendBorderWidth = 0;
    _legendBorderRadius = 8;
    _showTooltip = true;
    _tooltipTrigger = TooltipTriggerMode.both;
    _tooltipPosition = TooltipPosition.auto;
    _tooltipFollowsCursor = false;
    _tooltipOffset = 8;
    _tooltipShowDelayMs = 0;
    _tooltipHideDelayMs = 200;
    _tooltipPreset = _GaugeTooltipPreset.theme;
    _tooltipBackgroundColor = null;
    _tooltipBorderColor = null;
    _tooltipTextColor = null;
    _tooltipShadowColor = null;
    _tooltipBorderWidth = 1;
    _tooltipBorderRadius = 6;
    _tooltipPadding = 8;
    _tooltipShadowBlur = 4;
    _tooltipFontSize = 12;
    _entranceAnimationEnabled = true;
    _entranceDurationMs = 400;
    _entranceCurve = _GaugeMotionCurve.easeOutCubic;
    _themeChangeDurationMs = 300;
    _themeChangeCurve = _GaugeMotionCurve.easeOut;
    _interactionDurationMs = 150;
    _interactionCurve = _GaugeMotionCurve.easeOut;
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
      _chartRevision++;
      _applyPresentationState(_presentation);
    });
  }

  _RandomGaugeState _generateRandomState(int seed) {
    final random = math.Random(seed);
    final maximum = 50.0 + random.nextInt(151);
    return _RandomGaugeState(
      solid: random.nextBool(),
      value: maximum * (0.08 + random.nextDouble() * 0.88),
      maximum: maximum,
      startAngle: -180 + random.nextInt(181).toDouble(),
      sweepAngle: 150 + random.nextInt(211).toDouble(),
      clockwise: random.nextBool(),
      innerRadius: 0.38 + random.nextDouble() * 0.28,
      outerRadius: 0.78 + random.nextDouble() * 0.18,
      tickCount: 3 + random.nextInt(10),
      tickWidth: 0.5 + random.nextDouble() * 3.5,
      tickLength: 4 + random.nextDouble() * 18,
      scaleLabelSize: 8 + random.nextDouble() * 6,
      scaleLabelOffset: 4 + random.nextDouble() * 18,
      showZones: random.nextBool(),
      showTarget: random.nextBool(),
      showReferenceLabels: random.nextBool(),
      referenceLabelSize: 8 + random.nextDouble() * 6,
      referenceLabelOffset: 4 + random.nextDouble() * 20,
      showReferencePanel: random.nextBool(),
      centerHorizontalOffset: -12 + random.nextDouble() * 24,
      centerVerticalOffset: -12 + random.nextDouble() * 24,
      centerLineSpacing: random.nextDouble() * 8,
      cornerRadius: random.nextDouble() * 18,
      indicatorOpacity: 0.55 + random.nextDouble() * 0.45,
      theme: ThemePreset.values[random.nextInt(ThemePreset.values.length)],
      gradient: _GaugeGradientPreset
          .values[random.nextInt(_GaugeGradientPreset.values.length)],
      fixedGradientColors: random.nextBool(),
      showLegend: random.nextBool(),
      legendPosition:
          LegendPosition.values[random.nextInt(LegendPosition.values.length)],
      legendOrientation: LegendOrientation
          .values[random.nextInt(LegendOrientation.values.length)],
      legendMarkerShape: LegendMarkerShape
          .values[random.nextInt(LegendMarkerShape.values.length)],
      showTooltip: random.nextBool(),
      tooltipTrigger: TooltipTriggerMode
          .values[random.nextInt(TooltipTriggerMode.values.length)],
      tooltipPosition:
          TooltipPosition.values[random.nextInt(TooltipPosition.values.length)],
      tooltipFollowsCursor: random.nextBool(),
      entranceEnabled: random.nextBool(),
      entranceDurationMs: 150 + random.nextInt(1351),
      motionCurve: _GaugeMotionCurve
          .values[random.nextInt(_GaugeMotionCurve.values.length)],
    );
  }

  void _applyRandomState(_RandomGaugeState value) {
    setState(() {
      _playgroundActive = true;
      _chartRevision++;
      _solid = value.solid;
      _minimum = 0;
      _maximum = value.maximum;
      _value = value.value;
      _healthyEnd = _maximum * 0.6;
      _elevatedEnd = _maximum * 0.84;
      _targetValue = _maximum * 0.7;
      _thresholdValue = _maximum * 0.9;
      _startAngle = value.startAngle;
      _sweepAngle = value.sweepAngle;
      _clockwise = value.clockwise;
      _innerRadius = value.innerRadius;
      _outerRadius = math.max(value.outerRadius, value.innerRadius + 0.1);
      _tickCount = value.tickCount;
      _tickWidth = value.tickWidth;
      _tickLength = value.tickLength;
      _scaleLabelSize = value.scaleLabelSize;
      _scaleLabelOffset = value.scaleLabelOffset;
      _zonesEnabled = value.showZones;
      _showZones = value.showZones;
      _targetEnabled = value.showTarget;
      _showReferenceLabels = value.showReferenceLabels;
      _referenceLabelSize = value.referenceLabelSize;
      _referenceLabelOffset = value.referenceLabelOffset;
      _showReferencePanel =
          value.showReferenceLabels && value.showReferencePanel;
      _centerHorizontalOffset = value.centerHorizontalOffset;
      _centerVerticalOffset = value.centerVerticalOffset;
      _centerLineSpacing = value.centerLineSpacing;
      _cornerRadius = value.cornerRadius;
      _solidOpacity = value.indicatorOpacity;
      _axisOpacity = value.indicatorOpacity * 0.3;
      _themePreset = value.theme;
      _gradientPreset = value.solid
          ? value.gradient
          : _GaugeGradientPreset.solid;
      _useFixedGradientColors = value.fixedGradientColors;
      _showLegend = value.showLegend;
      _legendPosition = value.legendPosition;
      _legendOrientation = value.legendOrientation;
      _legendMarkerShape = value.legendMarkerShape;
      _showTooltip = value.showTooltip;
      _tooltipTrigger = value.tooltipTrigger;
      _tooltipPosition = value.tooltipPosition;
      _tooltipFollowsCursor = value.tooltipFollowsCursor;
      _entranceAnimationEnabled = value.entranceEnabled;
      _entranceDurationMs = value.entranceDurationMs;
      _entranceCurve = value.motionCurve;
      _interactionCurve = value.motionCurve;
    });
  }

  double get _zoneStep => (_maximum - _minimum) * 0.01;

  double get _resolvedHealthyEnd =>
      _healthyEnd.clamp(_minimum + _zoneStep, _maximum - (_zoneStep * 2));

  double get _resolvedElevatedEnd =>
      _elevatedEnd.clamp(_resolvedHealthyEnd + _zoneStep, _maximum - _zoneStep);

  String get _chartTitle => switch (_presentation) {
    _GaugePresentation.needle => 'Operational utilization',
    _GaugePresentation.solid => 'Availability objective',
    _GaugePresentation.gradient => 'Gradient release confidence',
    _GaugePresentation.zones => 'Status-aware pressure',
    _GaugePresentation.target => 'Latency against target',
    _GaugePresentation.legend => 'Dashboard reserve summary',
    _GaugePresentation.popup => 'Dark tracking presentation',
    _GaugePresentation.partial => 'Partial capacity dial',
    _GaugePresentation.accessible => 'Accessible operational status',
    _GaugePresentation.density => 'Dense scale and references',
  };

  String get _presentationDescription => switch (_presentation) {
    _GaugePresentation.needle =>
      'A pointer locates one live measurement on an explicit numeric scale.',
    _GaugePresentation.solid =>
      'A progress arc communicates the same measurement without changing its data contract.',
    _GaugePresentation.gradient =>
      'Sweep and radial gradients can derive from the indicator or use explicit portable stops.',
    _GaugePresentation.zones =>
      'Ordered status ranges derive operational meaning from the current value.',
    _GaugePresentation.target =>
      'The preferred target and additional threshold remain separate references.',
    _GaugePresentation.legend =>
      'An optional native legend summarizes the single reading without inventing selection behavior.',
    _GaugePresentation.popup =>
      'Trigger, placement, timing, surface, border, type, and shadow settings are all inspectable.',
    _GaugePresentation.partial =>
      'Pane start, sweep, direction, and radii support compact dashboard layouts.',
    _GaugePresentation.accessible =>
      'Status text, stronger geometry, large center type, and high contrast avoid color-only meaning.',
    _GaugePresentation.density =>
      'Maximum tick density, labels, target, and threshold exercise constrained layout.',
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

  String _motionCurveName(_GaugeMotionCurve value) => switch (value) {
    _GaugeMotionCurve.linear => 'Linear',
    _GaugeMotionCurve.easeOut => 'Ease out',
    _GaugeMotionCurve.easeOutCubic => 'Ease out cubic',
    _GaugeMotionCurve.easeInOutCubic => 'Ease in/out cubic',
  };
}
