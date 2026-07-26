// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

enum _GaugePresentation {
  needle('Needle', Icons.speed_outlined),
  solid('Solid', Icons.donut_large_outlined),
  zones('Zones', Icons.traffic_outlined),
  target('Target', Icons.flag_outlined),
  partial('Partial sweep', Icons.rotate_right_outlined),
  accessible('Accessible', Icons.accessibility_new_outlined),
  density('Density', Icons.density_medium_outlined);

  const _GaugePresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}

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
    required this.showZones,
    required this.showTarget,
    required this.cornerRadius,
    required this.indicatorOpacity,
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
  final bool showZones;
  final bool showTarget;
  final double cornerRadius;
  final double indicatorOpacity;
}

/// Public Gauge and Solid Gauge showcase with complete property inspection.
class GaugeChartsPage extends StatefulWidget {
  const GaugeChartsPage({super.key});

  @override
  State<GaugeChartsPage> createState() => _GaugeChartsPageState();
}

class _GaugeChartsPageState extends State<GaugeChartsPage> {
  late final ShowcaseRandomizerController<_RandomGaugeState> _randomizer;

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
  bool _showTooltip = true;

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
                chartBuilder: (context, controller) => BravenChartPlus(
                  key: ValueKey('gauge-chart-$_chartRevision'),
                  series: [series],
                  gaugeChartConfig: config,
                  bravenChartController: controller,
                  theme: _themePreset.theme,
                  showLegend: false,
                  interactionConfig: InteractionConfig(
                    tooltip: TooltipConfig(enabled: _showTooltip),
                  ),
                ),
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
    center: GaugeCenterConfig(
      showMetric: _showMetric,
      showValue: _showValue,
      showTarget: _showTargetInCenter,
      showStatus: _showStatus,
      metricStyle: _labelStyle(_metricTextColor, _metricFontSize, _metricBold),
      valueStyle: _labelStyle(_valueTextColor, _valueFontSize, _valueBold),
      targetStyle: _labelStyle(_targetTextColor, _targetFontSize, _targetBold),
      statusStyle: _labelStyle(_statusTextColor, _statusFontSize, _statusBold),
    ),
  );

  PolarLabelStyle _labelStyle(Color? color, double size, bool bold) =>
      PolarLabelStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      );

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
    _solid ? _buildSolidStyleOptions() : _buildNeedleStyleOptions(),
    _buildZoneOptions(),
    _buildReferenceOptions(),
    _buildCenterOptions(),
    OptionSection(
      title: 'Interaction',
      icon: Icons.touch_app_outlined,
      description:
          'Gauge supports tracking and one accessible focus stop without inventing durable selection state.',
      initiallyExpanded: false,
      children: [
        BoolOption(
          label: 'Data point popup',
          value: _showTooltip,
          onChanged: (value) => setState(() => _showTooltip = value),
        ),
        const InfoBox(
          message:
              'Hover, tap, or focus the indicator to inspect its value, range, status, and target. The current reading remains data state, not selection state.',
        ),
      ],
    ),
  ];

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
      case _GaugePresentation.zones:
        _solid = true;
        _metric = 'Queue pressure';
        _value = 86;
        _colorByZone = true;
        _showTargetInCenter = false;
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
      case _GaugePresentation.partial:
        _solid = true;
        _metric = 'Capacity used';
        _value = 64;
        _startAngle = -115;
        _sweepAngle = 230;
        _innerRadius = 0.62;
        _outerRadius = 0.9;
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
        _showTargetInCenter = true;
        _themePreset = ThemePreset.highContrast;
      case _GaugePresentation.density:
        _solid = true;
        _metric = 'Infrastructure load';
        _value = 81;
        _tickCount = 12;
        _showTargetInCenter = true;
        _showTickLabels = true;
        _thresholdWidth = 2;
        _axisThickness = 18;
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
    _showMetric = true;
    _showValue = true;
    _showTargetInCenter = false;
    _showStatus = true;
    _zonesEnabled = true;
    _healthyEnd = 60;
    _elevatedEnd = 85;
    _targetEnabled = true;
    _targetValue = 70;
    _thresholdEnabled = true;
    _thresholdValue = 90;
    _needleLength = 0.88;
    _needleWidth = 3;
    _pivotRadius = 6;
    _axisThickness = 12;
    _axisOpacity = 0.16;
    _trackOpacity = 0.14;
    _cornerRadius = 8;
    _borderWidth = 0;
    _solidOpacity = 1;
    _showTooltip = true;
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
      showZones: random.nextBool(),
      showTarget: random.nextBool(),
      cornerRadius: random.nextDouble() * 18,
      indicatorOpacity: 0.55 + random.nextDouble() * 0.45,
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
      _zonesEnabled = value.showZones;
      _showZones = value.showZones;
      _targetEnabled = value.showTarget;
      _cornerRadius = value.cornerRadius;
      _solidOpacity = value.indicatorOpacity;
      _axisOpacity = value.indicatorOpacity * 0.3;
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
    _GaugePresentation.zones => 'Status-aware pressure',
    _GaugePresentation.target => 'Latency against target',
    _GaugePresentation.partial => 'Partial capacity dial',
    _GaugePresentation.accessible => 'Accessible operational status',
    _GaugePresentation.density => 'Dense scale and references',
  };

  String get _presentationDescription => switch (_presentation) {
    _GaugePresentation.needle =>
      'A pointer locates one live measurement on an explicit numeric scale.',
    _GaugePresentation.solid =>
      'A progress arc communicates the same measurement without changing its data contract.',
    _GaugePresentation.zones =>
      'Ordered status ranges derive operational meaning from the current value.',
    _GaugePresentation.target =>
      'The preferred target and additional threshold remain separate references.',
    _GaugePresentation.partial =>
      'Pane start, sweep, direction, and radii support compact dashboard layouts.',
    _GaugePresentation.accessible =>
      'Status text, stronger geometry, large center type, and high contrast avoid color-only meaning.',
    _GaugePresentation.density =>
      'Maximum tick density, labels, target, and threshold exercise constrained layout.',
  };
}
