// Copyright 2025 Braven Charts - Multi-Axis Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _MultiAxisPattern { dualUnits, normalized, hiddenScale, denseTelemetry }

/// A guided playground for the multi-axis API and its scaling behaviour.
class MultiAxisPage extends StatefulWidget {
  const MultiAxisPage({super.key});

  @override
  State<MultiAxisPage> createState() => _MultiAxisPageState();
}

class _MultiAxisPageState extends State<MultiAxisPage> {
  static const _powerColor = Color(0xFFFF6D2D);
  static const _heartColor = Color(0xFF3478F6);
  static const _cadenceColor = Color(0xFF08A88A);
  static const _lactateColor = Color(0xFFFF405D);
  static const _vo2Color = Color(0xFF7747E8);
  static const _temperatureColor = Color(0xFFE6A117);

  final ChartOptionsController _optionsController = ChartOptionsController();
  final BravenChartController _chartController = BravenChartController();

  _MultiAxisPattern _selectedPattern = _MultiAxisPattern.dualUnits;
  NormalizationMode _normalizationMode = NormalizationMode.perSeries;
  YAxisPosition _secondaryPosition = YAxisPosition.right;
  AxisLabelDisplay _labelDisplay = AxisLabelDisplay.labelWithUnit;
  AxisSwapMode _axisSwapMode = AxisSwapMode.sticky;
  int _maxAxesPerSide = 3;
  bool _useFixedBounds = true;
  bool _showCrosshairLabels = true;
  bool _matchAxisColors = true;
  bool _keepEfficiencyAxisHidden = true;
  final Set<String> _hiddenSeriesIds = {};
  String? _slotStatus;

  late final Map<String, List<ChartDataPoint>> _data;

  @override
  void initState() {
    super.initState();
    _optionsController.showDataMarkers = false;
    _data = _buildData();
    _chartController.addListener(_onControllerChanged);
  }

  Map<String, List<ChartDataPoint>> _buildData() {
    return {
      'power': _points((x) => 175 + x * 4.5 + math.sin(x * 0.72) * 35),
      'heart': _points((x) => 112 + x * 2.1 + math.sin(x * 0.46 + 0.8) * 8),
      'cadence': _points((x) => 82 + math.sin(x * 0.9) * 8 + x * 0.2),
      'lactate': _points(
        (x) => 0.8 + math.pow(x / 24, 2.7) * 5.1 + math.sin(x * 0.6) * 0.12,
      ),
      'vo2': _points((x) => 29 + x * 1.05 + math.sin(x * 0.38) * 3.5),
      'temperature': _points(
        (x) => 36.6 + x * 0.105 + math.sin(x * 0.33) * 0.22,
      ),
      'efficiency': _points(
        (x) => 0.78 + x * 0.013 + math.cos(x * 0.55) * 0.035,
      ),
    };
  }

  List<ChartDataPoint> _points(double Function(double x) value) {
    return List.generate(49, (index) {
      final x = index / 2;
      return ChartDataPoint(x: x, y: value(x));
    });
  }

  void _onControllerChanged() {
    if (!mounted || _selectedPattern != _MultiAxisPattern.denseTelemetry) {
      return;
    }
    final visible = _chartController.visibleAxisIds.length;
    final overflow = _chartController.overflowAxisIds.length;
    final selected = _chartController.selectedSeriesId;
    setState(() {
      _slotStatus = selected == null
          ? '$visible visible axes · $overflow in overflow'
          : '$selected selected · $visible visible · $overflow overflow';
    });
  }

  @override
  void dispose() {
    _chartController.removeListener(_onControllerChanged);
    _chartController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Multi-Axis',
      subtitle:
          'Bind every metric to its own scale, position, unit, and visible axis slot',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          'Choose a multi-axis pattern',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        );
        final guide = _MultiAxisGuide(
          key: const ValueKey('multi-axis-pattern-guide'),
          pattern: _selectedPattern,
          status: _slotStatus,
        );

        if (constraints.maxHeight < 820) {
          return ListView(
            children: [
              heading,
              const SizedBox(height: 8),
              SizedBox(height: 172, child: _buildPatternRibbon()),
              const SizedBox(height: 16),
              guide,
              const SizedBox(height: 16),
              SizedBox(height: 470, child: _buildMainStage()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 8),
            SizedBox(height: 172, child: _buildPatternRibbon()),
            const SizedBox(height: 16),
            guide,
            const SizedBox(height: 16),
            Expanded(child: _buildMainStage()),
          ],
        );
      },
    );
  }

  Widget _buildPatternRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth >= 920
            ? (constraints.maxWidth - gap * 3) / 4
            : 200.0;
        return SingleChildScrollView(
          key: const ValueKey('multi-axis-pattern-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < _MultiAxisPattern.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: _MultiAxisPatternCard(
                    key: ValueKey(
                      'multi-axis-pattern-${_MultiAxisPattern.values[index].name}',
                    ),
                    pattern: _MultiAxisPattern.values[index],
                    selected:
                        _selectedPattern == _MultiAxisPattern.values[index],
                    onTap: () =>
                        _selectPattern(_MultiAxisPattern.values[index]),
                    chart: _buildPatternPreview(
                      _MultiAxisPattern.values[index],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternPreview(_MultiAxisPattern pattern) {
    final previewData = <String, List<ChartDataPoint>>{
      for (final entry in _data.entries)
        entry.key: entry.value.where((point) => point.x % 3 == 0).toList(),
    };
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;
    final series = _seriesForPattern(
      pattern,
      data: previewData,
      axisColorFallback: neutral,
      preview: true,
    );

    return BravenChartPlus(
      key: ValueKey('multi-axis-preview-${pattern.name}'),
      series: series,
      normalizationMode: pattern == _MultiAxisPattern.dualUnits
          ? NormalizationMode.perSeries
          : NormalizationMode.perSeries,
      maxAxesPerSide: 3,
      xAxisConfig: const XAxisConfig(
        min: 0,
        max: 24,
        tickCount: 3,
        showTickLabels: false,
        showAxisLine: true,
        minHeight: 10,
        maxHeight: 10,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        showTickLabels: false,
        showTicks: false,
        maxWidth: 18,
      ),
      grid: const GridConfig(horizontal: true, vertical: false),
      showLegend: false,
      interactionConfig: const InteractionConfig(
        enableZoom: false,
        enablePan: false,
      ),
    );
  }

  Widget _buildMainStage() {
    final series = _stageSeries();
    return ChartCard(
      key: const ValueKey('multi-axis-main-stage'),
      title: _stageTitle(_selectedPattern),
      subtitle: _stageSubtitle(_selectedPattern),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _optionsController,
              builder: (context, _) {
                final chartSeries = _stageSeries()
                    .where((item) => !_hiddenSeriesIds.contains(item.id))
                    .toList();
                return BravenChartPlus(
                  key: ValueKey(
                    'multi-axis-main-chart-${_selectedPattern.name}',
                  ),
                  series: chartSeries,
                  theme: _optionsController.theme,
                  normalizationMode: _normalizationMode,
                  maxAxesPerSide: _maxAxesPerSide,
                  axisSwapMode: _axisSwapMode,
                  bravenChartController: _chartController,
                  xAxisConfig: XAxisConfig(
                    label: 'Elapsed time',
                    unit: 'h',
                    min: 0,
                    max: 24,
                    tickCount: 7,
                    showAxisLine: _optionsController.showAxisLines,
                    showCrosshairLabel: _showCrosshairLabels,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  grid: GridConfig(
                    horizontal: _optionsController.showGrid,
                    vertical: _optionsController.showGrid,
                  ),
                  showLegend: false,
                  showXScrollbar: _optionsController.showXScrollbar,
                  showYScrollbar: _optionsController.showYScrollbar,
                  scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
                    autoHide: false,
                  ),
                  interactionConfig: InteractionConfig(
                    enableZoom: _optionsController.enableZoom,
                    enablePan: _optionsController.enablePan,
                    crosshair: CrosshairConfig.tracking(interpolate: true),
                    tooltip: const TooltipConfig(enabled: true),
                  ),
                  onAxisSwapped:
                      ({
                        required String promotedAxisId,
                        required String demotedAxisId,
                      }) {
                        if (!mounted) return;
                        setState(() {
                          _slotStatus =
                              'Promoted $promotedAxisId · demoted $demotedAxisId';
                        });
                      },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          _buildAxisMap(series),
          if (_selectedPattern == _MultiAxisPattern.denseTelemetry) ...[
            const SizedBox(height: 5),
            Text(
              _slotStatus ??
                  'Tap a metric to select it; overflow axes are promoted into a visible slot',
              key: const ValueKey('multi-axis-slot-status'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<ChartSeries> _stageSeries() {
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;
    return _seriesForPattern(
      _selectedPattern,
      data: _data,
      axisColorFallback: neutral,
    );
  }

  List<ChartSeries> _seriesForPattern(
    _MultiAxisPattern pattern, {
    required Map<String, List<ChartDataPoint>> data,
    required Color axisColorFallback,
    bool preview = false,
  }) {
    final marker = !preview && _optionsController.showDataMarkers;
    final lineWidth = preview ? 1.45 : 2.25;
    final fixed = _useFixedBounds || preview;

    LineChartSeries metric({
      required String id,
      required String name,
      required String label,
      required String unit,
      required Color color,
      required YAxisPosition position,
      required double min,
      required double max,
    }) {
      return LineChartSeries(
        id: id,
        name: name,
        points: data[id]!,
        color: color,
        unit: unit,
        interpolation: LineInterpolation.monotone,
        strokeWidth: lineWidth,
        showDataPointMarkers: marker,
        dataPointMarkerRadius: 2.6,
        yAxisConfig: YAxisConfig(
          position: position,
          label: label,
          unit: unit,
          color: _matchAxisColors || preview ? color : axisColorFallback,
          min: fixed ? min : null,
          max: fixed ? max : null,
          tickCount: preview ? 3 : 6,
          showAxisLine: true,
          showCrosshairLabel: !preview && _showCrosshairLabels,
          labelDisplay: preview ? AxisLabelDisplay.tickOnly : _labelDisplay,
          axisMargin: preview ? 2 : 8,
          minWidth: 0,
          maxWidth: preview ? 26 : 76,
        ),
      );
    }

    final power = metric(
      id: 'power',
      name: 'Power',
      label: 'Power',
      unit: 'W',
      color: _powerColor,
      position: YAxisPosition.left,
      min: 100,
      max: 340,
    );
    final heart = metric(
      id: 'heart',
      name: 'Heart rate',
      label: 'Heart rate',
      unit: 'bpm',
      color: _heartColor,
      position: pattern == _MultiAxisPattern.dualUnits
          ? _secondaryPosition
          : YAxisPosition.left,
      min: 100,
      max: 175,
    );
    final cadence = metric(
      id: 'cadence',
      name: 'Cadence',
      label: 'Cadence',
      unit: 'rpm',
      color: _cadenceColor,
      position: YAxisPosition.left,
      min: 65,
      max: 105,
    );
    final lactate = metric(
      id: 'lactate',
      name: 'Lactate',
      label: 'Lactate',
      unit: 'mmol/L',
      color: _lactateColor,
      position: YAxisPosition.right,
      min: 0,
      max: 6.5,
    );
    final vo2 = metric(
      id: 'vo2',
      name: 'VO₂',
      label: 'VO₂',
      unit: 'mL/kg/min',
      color: _vo2Color,
      position: YAxisPosition.right,
      min: 25,
      max: 58,
    );
    final temperature = metric(
      id: 'temperature',
      name: 'Core temperature',
      label: 'Core temp',
      unit: '°C',
      color: _temperatureColor,
      position: YAxisPosition.right,
      min: 36,
      max: 40,
    );
    final efficiency = metric(
      id: 'efficiency',
      name: 'Efficiency index',
      label: 'Efficiency',
      unit: 'ratio',
      color: _cadenceColor,
      position: _keepEfficiencyAxisHidden || preview
          ? YAxisPosition.hidden
          : YAxisPosition.right,
      min: 0.7,
      max: 1.2,
    );

    return switch (pattern) {
      _MultiAxisPattern.dualUnits => [power, heart],
      _MultiAxisPattern.normalized => [power, heart, lactate],
      _MultiAxisPattern.hiddenScale => [power, heart, efficiency],
      _MultiAxisPattern.denseTelemetry => [
        power,
        heart,
        cadence,
        lactate,
        vo2,
        temperature,
      ],
    };
  }

  Widget _buildAxisMap(List<ChartSeries> series) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('multi-axis-map'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < series.length; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              _AxisMapChip(
                series: series[index],
                hidden: _hiddenSeriesIds.contains(series[index].id),
                onToggle: () => _toggleSeries(series[index].id),
                onSelect: () => _chartController.selectSeries(series[index].id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSeries(String id) {
    setState(() {
      if (!_hiddenSeriesIds.remove(id)) _hiddenSeriesIds.add(id);
    });
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Multi-Axis Pattern',
        icon: Icons.multiline_chart,
        children: [
          EnumOption<_MultiAxisPattern>(
            label: 'Example',
            value: _selectedPattern,
            values: _MultiAxisPattern.values,
            labelBuilder: _patternLabel,
            onChanged: _selectPattern,
          ),
        ],
      ),
      OptionSection(
        title: 'Scale Model',
        icon: Icons.compare_arrows,
        children: [
          EnumOption<NormalizationMode>(
            label: 'Normalization',
            value: _normalizationMode,
            values: NormalizationMode.values,
            labelBuilder: (value) => switch (value) {
              NormalizationMode.none => 'None · shared coordinates',
              NormalizationMode.auto => 'Auto · detect >10× ranges',
              NormalizationMode.perSeries => 'Per series · independent',
            },
            onChanged: (value) => setState(() => _normalizationMode = value),
          ),
          BoolOption(
            label: 'Use Fixed Bounds',
            value: _useFixedBounds,
            subtitle: 'Otherwise each axis derives min/max from its data',
            onChanged: (value) => setState(() => _useFixedBounds = value),
          ),
          EnumOption<AxisLabelDisplay>(
            label: 'Axis Label Display',
            value: _labelDisplay,
            values: AxisLabelDisplay.values,
            labelBuilder: _labelDisplayName,
            onChanged: (value) => setState(() => _labelDisplay = value),
          ),
          BoolOption(
            label: 'Match Axis Colors',
            value: _matchAxisColors,
            subtitle:
                'Pair each scale with its series without relying on order',
            onChanged: (value) => setState(() => _matchAxisColors = value),
          ),
          BoolOption(
            label: 'Crosshair Values Per Axis',
            value: _showCrosshairLabels,
            subtitle: 'Hover to compare original values in every unit',
            onChanged: (value) => setState(() => _showCrosshairLabels = value),
          ),
        ],
      ),
      ..._buildPatternOptions(),
      StandardChartOptions(
        controller: _optionsController,
        showLegendOption: false,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'What to Try',
        icon: Icons.fact_check_outlined,
        children: [InfoBox(message: _instruction(_selectedPattern))],
      ),
    ];
  }

  List<Widget> _buildPatternOptions() {
    return switch (_selectedPattern) {
      _MultiAxisPattern.dualUnits => [
        OptionSection(
          title: 'Axis Placement',
          icon: Icons.compare_arrows,
          children: [
            EnumOption<YAxisPosition>(
              label: 'Heart Rate Axis',
              value: _secondaryPosition,
              values: const [
                YAxisPosition.left,
                YAxisPosition.right,
                YAxisPosition.hidden,
              ],
              labelBuilder: _positionLabel,
              onChanged: (value) => setState(() => _secondaryPosition = value),
            ),
          ],
        ),
      ],
      _MultiAxisPattern.hiddenScale => [
        OptionSection(
          title: 'Hidden Axis',
          icon: Icons.visibility_off_outlined,
          children: [
            BoolOption(
              label: 'Keep Efficiency Axis Hidden',
              value: _keepEfficiencyAxisHidden,
              subtitle: 'The teal series still uses its own 0.7–1.2 scale',
              onChanged: (value) =>
                  setState(() => _keepEfficiencyAxisHidden = value),
            ),
          ],
        ),
      ],
      _MultiAxisPattern.denseTelemetry => [
        OptionSection(
          title: 'Visible Axis Slots',
          icon: Icons.swap_vert,
          children: [
            IntSliderOption(
              label: 'Max Axes Per Side',
              value: _maxAxesPerSide,
              min: 1,
              max: 3,
              onChanged: (value) => setState(() => _maxAxesPerSide = value),
            ),
            EnumOption<AxisSwapMode>(
              label: 'Selection Swap',
              value: _axisSwapMode,
              values: AxisSwapMode.values,
              labelBuilder: (value) => switch (value) {
                AxisSwapMode.sticky => 'Sticky promotion',
                AxisSwapMode.revert => 'Revert on deselect',
              },
              onChanged: (value) => setState(() => _axisSwapMode = value),
            ),
          ],
        ),
      ],
      _MultiAxisPattern.normalized => const [],
    };
  }

  void _selectPattern(_MultiAxisPattern pattern) {
    if (_selectedPattern == pattern) return;
    setState(() {
      _selectedPattern = pattern;
      _hiddenSeriesIds.clear();
      _slotStatus = null;
      _normalizationMode = NormalizationMode.perSeries;
    });
  }

  static String _patternLabel(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits => 'Dual units',
      _MultiAxisPattern.normalized => 'Independent scales',
      _MultiAxisPattern.hiddenScale => 'Hidden scale',
      _MultiAxisPattern.denseTelemetry => 'Dense telemetry',
    };
  }

  static String _patternDescription(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits => '2 metrics · opposite sides',
      _MultiAxisPattern.normalized => '3 ranges · equal visual weight',
      _MultiAxisPattern.hiddenScale => 'Normalize without axis chrome',
      _MultiAxisPattern.denseTelemetry => '6 units · stacked slots',
    };
  }

  static String _stageTitle(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits => 'Power and heart rate',
      _MultiAxisPattern.normalized => 'Independent physiological scales',
      _MultiAxisPattern.hiddenScale =>
        'Visible metrics with a hidden reference scale',
      _MultiAxisPattern.denseTelemetry => '6-axis performance telemetry',
    };
  }

  static String _stageSubtitle(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits =>
        'Power owns the left scale · heart rate owns the configurable secondary scale',
      _MultiAxisPattern.normalized =>
        'Watts, bpm, and mmol/L each occupy the full plot while preserving original values',
      _MultiAxisPattern.hiddenScale =>
        'The efficiency line remains independently normalized even when its axis is not painted',
      _MultiAxisPattern.denseTelemetry =>
        '3 left + 3 right axes · select any metric to promote an overflow scale',
    };
  }

  static String _instruction(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits =>
        'Move the heart-rate axis between left, right, and hidden. Then switch normalization to none to see why unrelated units usually need independent coordinates.',
      _MultiAxisPattern.normalized =>
        'Compare none, auto, and per-series normalization. Hover the chart: crosshair labels and tooltips report each metric in its original unit, not normalized values.',
      _MultiAxisPattern.hiddenScale =>
        'Hide the efficiency axis while keeping its line visible. A hidden YAxisConfig consumes no layout space but still controls normalization and interaction values.',
      _MultiAxisPattern.denseTelemetry =>
        'Reduce max axes per side, then select a metric chip whose scale overflowed. Sticky keeps the promoted axis; revert restores declaration order after deselection.',
    };
  }

  static String _labelDisplayName(AxisLabelDisplay value) {
    return switch (value) {
      AxisLabelDisplay.labelOnly => 'Label only',
      AxisLabelDisplay.labelWithUnit => 'Label with unit',
      AxisLabelDisplay.labelAndTickUnit => 'Label + tick units',
      AxisLabelDisplay.labelWithUnitAndTickUnit => 'Unit on label + ticks',
      AxisLabelDisplay.tickUnitOnly => 'Tick units only',
      AxisLabelDisplay.tickOnly => 'Ticks only',
      AxisLabelDisplay.none => 'No labels',
    };
  }

  static String _positionLabel(YAxisPosition value) {
    return switch (value) {
      YAxisPosition.left => 'Left',
      YAxisPosition.right => 'Right',
      YAxisPosition.hidden => 'Hidden',
      _ => value.name,
    };
  }
}

class _MultiAxisPatternCard extends StatelessWidget {
  const _MultiAxisPatternCard({
    super.key,
    required this.pattern,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _MultiAxisPattern pattern;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Select ${_MultiAxisPageState._patternLabel(pattern)} multi-axis pattern',
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _MultiAxisPageState._patternLabel(pattern),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-multi-axis-${pattern.name}'),
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _MultiAxisPageState._patternDescription(pattern),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(child: IgnorePointer(child: chart)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiAxisGuide extends StatelessWidget {
  const _MultiAxisGuide({
    super.key,
    required this.pattern,
    required this.status,
  });

  final _MultiAxisPattern pattern;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanation = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(pattern), size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _MultiAxisPageState._patternLabel(pattern),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _explanation(pattern, status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final api = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _api(pattern),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(child: explanation),
                const SizedBox(width: 16),
                SizedBox(width: 470, child: api),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [explanation, const SizedBox(height: 10), api],
          );
        },
      ),
    );
  }

  static IconData _icon(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits => Icons.compare_arrows,
      _MultiAxisPattern.normalized => Icons.compare_arrows,
      _MultiAxisPattern.hiddenScale => Icons.visibility_off_outlined,
      _MultiAxisPattern.denseTelemetry => Icons.stacked_line_chart,
    };
  }

  static String _explanation(_MultiAxisPattern pattern, String? status) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits =>
        'Inline YAxisConfig keeps each series, scale, unit, color, and physical position together.',
      _MultiAxisPattern.normalized =>
        'Per-series normalization maps unrelated numeric ranges into one plot while axes, tooltips, and crosshair labels retain source values.',
      _MultiAxisPattern.hiddenScale =>
        'YAxisPosition.hidden preserves an independent transform without consuming width or painting ticks and labels.',
      _MultiAxisPattern.denseTelemetry =>
        status ??
            'Axes stack outward in declaration order. A configurable per-side cap moves excess axes into selectable overflow.',
    };
  }

  static String _api(_MultiAxisPattern pattern) {
    return switch (pattern) {
      _MultiAxisPattern.dualUnits =>
        'series.yAxisConfig: YAxisConfig(position, label, unit, color)',
      _MultiAxisPattern.normalized =>
        'normalizationMode: none | auto | perSeries',
      _MultiAxisPattern.hiddenScale =>
        'YAxisConfig(position: YAxisPosition.hidden) · normalization retained',
      _MultiAxisPattern.denseTelemetry =>
        'maxAxesPerSide · axisSwapMode · BravenChartController.selectSeries()',
    };
  }
}

class _AxisMapChip extends StatelessWidget {
  const _AxisMapChip({
    required this.series,
    required this.hidden,
    required this.onToggle,
    required this.onSelect,
  });

  final ChartSeries series;
  final bool hidden;
  final VoidCallback onToggle;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axis = series.yAxisConfig;
    final color = series.color ?? theme.colorScheme.primary;
    final position = axis?.position == YAxisPosition.hidden
        ? 'hidden'
        : axis?.position.name ?? 'default';
    return Material(
      color: hidden
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
          : color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelect,
        onLongPress: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${series.displayName} → $position${axis?.unit == null ? '' : ' · ${axis!.unit}'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hidden
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  decoration: hidden ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(width: 4),
              InkResponse(
                onTap: onToggle,
                radius: 18,
                child: Icon(
                  hidden ? Icons.visibility_off : Icons.visibility,
                  size: 15,
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
