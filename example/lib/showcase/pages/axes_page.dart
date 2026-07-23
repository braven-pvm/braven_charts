// Copyright 2025 Braven Charts - Axes Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _AxisPattern { labelsBounds, minorTicks, renderWindows, axisSlots }

/// A focused axis playground covering the foundational and advanced axis API.
class AxesPage extends StatefulWidget {
  const AxesPage({super.key});

  @override
  State<AxesPage> createState() => _AxesPageState();
}

class _AxesPageState extends State<AxesPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final BravenChartController _chartController = BravenChartController();

  _AxisPattern _selectedPattern = _AxisPattern.labelsBounds;

  AxisLabelDisplay _labelDisplay = AxisLabelDisplay.labelWithUnit;
  XAxisPosition _xAxisPosition = XAxisPosition.bottom;
  double _xTickLabelRotation = 0;
  XAxisTickLabelCollisionPolicy _xTickLabelCollisionPolicy =
      XAxisTickLabelCollisionPolicy.auto;
  double _xTickLabelCollisionPadding = 4;
  YAxisPosition _yAxisPosition = YAxisPosition.left;
  int _xMajorTickCount = 6;
  int _yMajorTickCount = 6;
  bool _showXTicks = true;
  bool _showXTickLabels = true;
  bool _showYTicks = true;
  bool _showYTickLabels = true;
  bool _showCrosshairLabels = true;
  double _axisMargin = 8;

  bool _showMinorTicks = true;
  int _minorTickCount = 4;
  double _minorTickLength = 3;
  bool _horizontalGrid = true;
  bool _verticalGrid = true;
  double _gridWidth = 0.5;

  double _xRenderMin = 10;
  double _xRenderMax = 90;
  double _yRenderMin = 45;
  double _yRenderMax = 90;

  int _maxAxesPerSide = 3;
  AxisSwapMode _axisSwapMode = AxisSwapMode.sticky;
  final Set<String> _hiddenSeriesIds = {};
  String? _slotStatus;

  late final List<ChartDataPoint> _observed;
  late final List<ChartDataPoint> _forecast;
  late final List<ChartDataPoint> _capacity;
  late final List<LineChartSeries> _slotSeries;

  @override
  void initState() {
    super.initState();
    _optionsController.showDataMarkers = true;
    _buildData();
    _chartController.addListener(_onControllerChanged);
  }

  void _buildData() {
    _observed = List.generate(41, (index) {
      final x = index * 2.5;
      return ChartDataPoint(
        x: x,
        y: 52 + x * 0.28 + math.sin(index * 0.52) * 8,
      );
    });
    _forecast = List.generate(41, (index) {
      final x = index * 2.5;
      return ChartDataPoint(
        x: x,
        y: 58 + x * 0.24 + math.cos(index * 0.35) * 5,
      );
    });
    _capacity = List.generate(41, (index) {
      final x = index * 2.5;
      return ChartDataPoint(x: x, y: 72 + x * 0.16 + math.sin(index * 0.2) * 3);
    });

    _slotSeries = [
      _slotSeriesItem(
        id: 'lactate',
        name: 'Lactate',
        label: 'Lactate',
        unit: 'mmol/L',
        color: const Color(0xFFE53935),
        min: 0,
        max: 4,
        value: (index) => 0.6 + index * 0.07,
      ),
      _slotSeriesItem(
        id: 'vo2',
        name: 'VO₂ Avg',
        label: 'VO₂',
        unit: 'mL/min/kg',
        color: const Color(0xFF1E88E5),
        min: 15,
        max: 45,
        value: (index) => 20 + index * 0.8,
      ),
      _slotSeriesItem(
        id: 'rf',
        name: 'Respiratory rate',
        label: 'RF',
        unit: 'br/min',
        color: const Color(0xFF43A047),
        min: 10,
        max: 24,
        value: (index) => 12 + index * 0.3,
      ),
      _slotSeriesItem(
        id: 'heat',
        name: 'Heat strain',
        label: 'Heat strain',
        unit: 'HSI',
        color: const Color(0xFFFF9800),
        min: 0.5,
        max: 2,
        value: (index) => 0.8 + index * 0.04,
      ),
      _slotSeriesItem(
        id: 'tidal',
        name: 'Tidal volume',
        label: 'Tidal vol',
        unit: 'L',
        color: const Color(0xFF8E24AA),
        min: 0.2,
        max: 1,
        value: (index) => 0.3 + index * 0.02,
      ),
    ];
  }

  LineChartSeries _slotSeriesItem({
    required String id,
    required String name,
    required String label,
    required String unit,
    required Color color,
    required double min,
    required double max,
    required double Function(int index) value,
  }) {
    return LineChartSeries(
      id: id,
      name: name,
      color: color,
      points: List.generate(
        20,
        (index) => ChartDataPoint(
          x: index.toDouble(),
          y: value(index) + math.sin(index * 0.45) * (max - min) * 0.04,
        ),
      ),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.2,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.right,
        label: label,
        unit: unit,
        color: color,
        min: min,
        max: max,
        showCrosshairLabel: true,
      ),
    );
  }

  void _onControllerChanged() {
    if (!mounted || _selectedPattern != _AxisPattern.axisSlots) return;
    setState(() {
      final visible = _chartController.visibleAxisIds;
      final overflow = _chartController.overflowAxisIds;
      _slotStatus = '${visible.length} visible · ${overflow.length} overflow';
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
      title: 'Axes',
      subtitle:
          'Configure labels, bounds, ticks, render windows, and constrained axis allocation',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          'Choose an axis pattern',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        );
        final guide = _AxisPatternGuide(
          key: const ValueKey('axis-pattern-guide'),
          pattern: _selectedPattern,
          slotStatus: _slotStatus,
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
              SizedBox(height: 430, child: _buildMainStage()),
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
        const spacing = 12.0;
        final cardWidth = constraints.maxWidth >= 920
            ? (constraints.maxWidth - spacing * 3) / 4
            : 190.0;

        return SingleChildScrollView(
          key: const ValueKey('axis-pattern-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < _AxisPattern.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _AxisPatternCard(
                    key: ValueKey(
                      'axis-pattern-${_AxisPattern.values[index].name}',
                    ),
                    pattern: _AxisPattern.values[index],
                    selected: _selectedPattern == _AxisPattern.values[index],
                    onTap: () => _selectPattern(_AxisPattern.values[index]),
                    chart: _buildPatternPreview(_AxisPattern.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternPreview(_AxisPattern pattern) {
    final previewObserved = _observed
        .where((point) => point.x % 10 == 0)
        .toList(growable: false);
    final previewForecast = _forecast
        .where((point) => point.x % 10 == 0)
        .toList(growable: false);

    final xAxis = switch (pattern) {
      _AxisPattern.labelsBounds => const XAxisConfig(
        label: 'Time',
        min: -10,
        max: 110,
        renderMin: 0,
        renderMax: 100,
        tickCount: 3,
      ),
      _AxisPattern.minorTicks => const XAxisConfig(
        min: 0,
        max: 100,
        tickCount: 4,
        showMinorTicks: true,
        minorTickCount: 3,
        minorTickLength: 2,
      ),
      _AxisPattern.renderWindows => const XAxisConfig(
        min: 0,
        max: 100,
        renderMin: 20,
        renderMax: 80,
        tickCount: 6,
      ),
      _AxisPattern.axisSlots => const XAxisConfig(
        visible: false,
        minHeight: 0,
        maxHeight: 0,
      ),
    };

    final yAxis = switch (pattern) {
      _AxisPattern.labelsBounds => YAxisConfig(
        position: YAxisPosition.left,
        label: 'Value',
        min: 35,
        max: 95,
        tickCount: 4,
      ),
      _AxisPattern.minorTicks => YAxisConfig(
        position: YAxisPosition.left,
        min: 35,
        max: 95,
        tickCount: 4,
        showMinorTicks: true,
        minorTickCount: 3,
        minorTickLength: 2,
      ),
      _AxisPattern.renderWindows => YAxisConfig(
        position: YAxisPosition.left,
        min: 35,
        max: 95,
        renderMin: 50,
        renderMax: 85,
        tickCount: 5,
      ),
      _AxisPattern.axisSlots => YAxisConfig(
        position: YAxisPosition.hidden,
        minWidth: 0,
        maxWidth: 0,
      ),
    };

    final series = pattern == _AxisPattern.axisSlots
        ? _slotSeries.take(3).toList()
        : <ChartSeries>[
            LineChartSeries(
              id: 'preview-${pattern.name}-observed',
              points: previewObserved,
              color: const Color(0xFF3B82F6),
              interpolation: LineInterpolation.monotone,
              strokeWidth: 2,
            ),
            LineChartSeries(
              id: 'preview-${pattern.name}-forecast',
              points: previewForecast,
              color: const Color(0xFFF97316),
              interpolation: LineInterpolation.bezier,
              strokeWidth: 1.6,
            ),
          ];

    return RepaintBoundary(
      child: BravenChartPlus(
        series: series,
        xAxisConfig: xAxis,
        yAxis: yAxis,
        maxAxesPerSide: pattern == _AxisPattern.axisSlots ? 2 : 3,
        normalizationMode: pattern == _AxisPattern.axisSlots
            ? NormalizationMode.perSeries
            : NormalizationMode.none,
        grid: GridConfig(
          horizontal: pattern == _AxisPattern.minorTicks,
          vertical: pattern == _AxisPattern.minorTicks,
        ),
        showLegend: false,
        interactionConfig: InteractionConfig.none(),
      ),
    );
  }

  Widget _buildMainStage() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: _patternStageTitle(_selectedPattern),
          subtitle: _patternStageSubtitle(_selectedPattern),
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
          child: _selectedPattern == _AxisPattern.axisSlots
              ? _buildAxisSlotStage()
              : _buildStandardAxisChart(),
        );
      },
    );
  }

  Widget _buildStandardAxisChart() {
    return BravenChartPlus(
      key: const ValueKey('axes-main-chart'),
      series: [
        AreaChartSeries(
          id: 'capacity',
          name: 'Capacity',
          points: _capacity,
          color: const Color(0xFF60A5FA),
          interpolation: LineInterpolation.bezier,
          strokeWidth: 1.8,
          fillOpacity: 0.14,
        ),
        LineChartSeries(
          id: 'observed',
          name: 'Observed',
          points: _observed,
          color: const Color(0xFF2563EB),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.5,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: 3,
        ),
        LineChartSeries(
          id: 'forecast',
          name: 'Forecast',
          points: _forecast,
          color: const Color(0xFFF97316),
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: 2.5,
        ),
      ],
      annotations: _selectedPattern == _AxisPattern.renderWindows
          ? [
              RangeAnnotation(
                id: 'axis-render-window',
                startX: _xRenderMin,
                endX: _xRenderMax,
                label: 'Rendered ticks',
                fillColor: const Color(0x1A10B981),
                borderColor: const Color(0xFF10B981),
                allowDragging: false,
                allowEditing: false,
              ),
            ]
          : const [],
      theme: _optionsController.theme,
      xAxisConfig: _mainXAxis,
      yAxis: _mainYAxis,
      grid: GridConfig(
        horizontal: _optionsController.showGrid && _horizontalGrid,
        vertical: _optionsController.showGrid && _verticalGrid,
        horizontalStrokeWidth: _gridWidth,
        verticalStrokeWidth: _gridWidth,
      ),
      showLegend: _optionsController.showLegend,
      showXScrollbar: _optionsController.showXScrollbar,
      showYScrollbar: _optionsController.showYScrollbar,
      scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.enableZoom,
        enablePan: _optionsController.enablePan,
        crosshair: CrosshairConfig.tracking(interpolate: true),
        tooltip: const TooltipConfig(enabled: true),
      ),
    );
  }

  Widget _buildAxisSlotStage() {
    final visibleSeries = _slotSeries
        .where((series) => !_hiddenSeriesIds.contains(series.id))
        .toList();

    return Column(
      children: [
        Expanded(
          child: BravenChartPlus(
            key: const ValueKey('axes-main-chart'),
            series: visibleSeries,
            theme: _optionsController.theme,
            maxAxesPerSide: _maxAxesPerSide,
            axisSwapMode: _axisSwapMode,
            bravenChartController: _chartController,
            normalizationMode: NormalizationMode.perSeries,
            xAxisConfig: XAxisConfig(
              position: _xAxisPosition,
              label: 'Interval',
              min: 0,
              max: 19,
              showAxisLine: true,
              showTicks: _showXTicks,
              showTickLabels: _showXTickLabels,
              tickCount: _xMajorTickCount,
              tickLabelRotationDegrees: _xTickLabelRotation,
              tickLabelCollisionPolicy: _xTickLabelCollisionPolicy,
              tickLabelCollisionPadding: _xTickLabelCollisionPadding,
            ),
            grid: GridConfig(
              horizontal: _optionsController.showGrid,
              vertical: _optionsController.showGrid,
            ),
            showLegend: false,
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
                  setState(() {
                    _slotStatus =
                        'Promoted $promotedAxisId · demoted $demotedAxisId';
                  });
                },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _slotStatus ??
              'Tap a legend item to promote its axis into a visible slot',
          key: const ValueKey('axis-slot-status'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ChartLegend(
            series: _slotSeries,
            hiddenSeriesIds: _hiddenSeriesIds,
            onSeriesToggle: (id) {
              setState(() {
                if (!_hiddenSeriesIds.remove(id)) _hiddenSeriesIds.add(id);
              });
            },
            onSeriesTap: _chartController.selectSeries,
          ),
        ),
      ],
    );
  }

  XAxisConfig get _mainXAxis {
    return XAxisConfig(
      position: _xAxisPosition,
      label: 'Time',
      unit: 'h',
      min: _selectedPattern == _AxisPattern.labelsBounds ? -10 : 0,
      max: _selectedPattern == _AxisPattern.labelsBounds ? 110 : 100,
      renderMin: switch (_selectedPattern) {
        _AxisPattern.labelsBounds => 0,
        _AxisPattern.renderWindows => _xRenderMin,
        _ => null,
      },
      renderMax: switch (_selectedPattern) {
        _AxisPattern.labelsBounds => 100,
        _AxisPattern.renderWindows => _xRenderMax,
        _ => null,
      },
      showAxisLine: _optionsController.showAxisLines,
      showTicks: _showXTicks,
      showTickLabels: _showXTickLabels,
      showCrosshairLabel: _showCrosshairLabels,
      labelDisplay: _labelDisplay,
      tickCount: _xMajorTickCount,
      tickLabelRotationDegrees: _xTickLabelRotation,
      tickLabelCollisionPolicy: _xTickLabelCollisionPolicy,
      tickLabelCollisionPadding: _xTickLabelCollisionPadding,
      labelFormatter: _selectedPattern == _AxisPattern.labelsBounds
          ? _formatHourTick
          : null,
      showMinorTicks:
          _selectedPattern == _AxisPattern.minorTicks && _showMinorTicks,
      minorTickCount: _minorTickCount,
      minorTickLength: _minorTickLength,
      axisMargin: _axisMargin,
    );
  }

  String _formatHourTick(double value) {
    final totalMinutes = (value * 60).round();
    final sign = totalMinutes < 0 ? '-' : '';
    final absoluteMinutes = totalMinutes.abs();
    final hours = absoluteMinutes ~/ 60;
    final minutes = absoluteMinutes % 60;
    return '$sign${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  YAxisConfig get _mainYAxis {
    return YAxisConfig(
      position: _yAxisPosition,
      label: 'Utilization',
      unit: '%',
      min: 35,
      max: 95,
      renderMin: _selectedPattern == _AxisPattern.renderWindows
          ? _yRenderMin
          : null,
      renderMax: _selectedPattern == _AxisPattern.renderWindows
          ? _yRenderMax
          : null,
      showAxisLine: _optionsController.showAxisLines,
      showTicks: _showYTicks,
      showTickLabels: _showYTickLabels,
      showCrosshairLabel: _showCrosshairLabels,
      labelDisplay: _labelDisplay,
      tickCount: _yMajorTickCount,
      showMinorTicks:
          _selectedPattern == _AxisPattern.minorTicks && _showMinorTicks,
      minorTickCount: _minorTickCount,
      minorTickLength: _minorTickLength,
      axisMargin: _axisMargin,
    );
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Axis Pattern',
        icon: Icons.view_week_outlined,
        children: [
          EnumOption<_AxisPattern>(
            label: 'Example',
            value: _selectedPattern,
            values: _AxisPattern.values,
            labelBuilder: _patternLabel,
            onChanged: _selectPattern,
          ),
        ],
      ),
      OptionSection(
        title: 'X-axis ticks & labels',
        icon: Icons.text_rotate_up,
        children: [
          EnumOption<XAxisPosition>(
            label: 'Position',
            value: _xAxisPosition,
            values: XAxisPosition.values,
            labelBuilder: (value) => switch (value) {
              XAxisPosition.bottom => 'Bottom',
              XAxisPosition.top => 'Top',
              XAxisPosition.both => 'Both',
            },
            onChanged: (value) => setState(() => _xAxisPosition = value),
          ),
          IntSliderOption(
            label: 'Requested X-axis ticks',
            value: _xMajorTickCount,
            min: 2,
            max: 32,
            description:
                'Set the maximum major ticks requested from the numeric '
                'axis generator.',
            aliases: const ['tick count', 'major ticks', 'density'],
            onChanged: (value) => setState(() => _xMajorTickCount = value),
          ),
          BoolOption(
            label: 'Show tick marks',
            value: _showXTicks,
            onChanged: (value) => setState(() => _showXTicks = value),
          ),
          BoolOption(
            label: 'Show tick labels',
            value: _showXTickLabels,
            onChanged: (value) => setState(() => _showXTickLabels = value),
          ),
          SliderOption(
            label: 'Tick label angle',
            value: _xTickLabelRotation,
            min: -90,
            max: 90,
            divisions: 12,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _xTickLabelRotation = value),
          ),
          EnumOption<XAxisTickLabelCollisionPolicy>(
            label: 'Label density',
            value: _xTickLabelCollisionPolicy,
            values: XAxisTickLabelCollisionPolicy.values,
            labelBuilder: (value) => switch (value) {
              XAxisTickLabelCollisionPolicy.auto =>
                'Automatic — prevent overlap',
              XAxisTickLabelCollisionPolicy.showAll => 'Show every label',
            },
            subtitle:
                'Automatic density thins labels after measuring their '
                'rotated bounds.',
            description:
                'Choose whether the axis automatically removes overlapping '
                'labels or paints every requested label.',
            aliases: const ['collision', 'overlap', 'show all', 'thinning'],
            onChanged: (value) =>
                setState(() => _xTickLabelCollisionPolicy = value),
          ),
          SliderOption(
            label: 'Minimum label spacing',
            value: _xTickLabelCollisionPadding,
            min: 0,
            max: 24,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _xTickLabelCollisionPadding = value),
          ),
        ],
      ),
      ..._buildPatternOptions(),
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'What to try',
        icon: Icons.fact_check_outlined,
        children: [InfoBox(message: _patternInstruction(_selectedPattern))],
      ),
    ];
  }

  List<Widget> _buildPatternOptions() {
    return switch (_selectedPattern) {
      _AxisPattern.labelsBounds => [
        OptionSection(
          title: 'Labels & Bounds',
          icon: Icons.straighten,
          children: [
            EnumOption<AxisLabelDisplay>(
              label: 'Label Display',
              value: _labelDisplay,
              values: AxisLabelDisplay.values,
              labelBuilder: _labelDisplayName,
              onChanged: (value) => setState(() => _labelDisplay = value),
            ),
            EnumOption<YAxisPosition>(
              label: 'Y-Axis Position',
              value: _yAxisPosition,
              values: const [
                YAxisPosition.left,
                YAxisPosition.right,
                YAxisPosition.hidden,
              ],
              labelBuilder: (value) => switch (value) {
                YAxisPosition.left => 'Left',
                YAxisPosition.right => 'Right',
                _ => 'Hidden',
              },
              onChanged: (value) => setState(() => _yAxisPosition = value),
            ),
            IntSliderOption(
              label: 'Requested Y-axis ticks',
              value: _yMajorTickCount,
              min: 2,
              max: 32,
              description:
                  'Set the maximum major ticks requested from the Y-axis '
                  'generator independently of the X-axis.',
              aliases: const ['tick count', 'major ticks', 'density'],
              onChanged: (value) => setState(() => _yMajorTickCount = value),
            ),
            BoolOption(
              label: 'Show Y-axis tick marks',
              value: _showYTicks,
              onChanged: (value) => setState(() => _showYTicks = value),
            ),
            BoolOption(
              label: 'Show Y-axis tick labels',
              value: _showYTickLabels,
              onChanged: (value) => setState(() => _showYTickLabels = value),
            ),
            BoolOption(
              label: 'Crosshair Labels',
              value: _showCrosshairLabels,
              onChanged: (value) =>
                  setState(() => _showCrosshairLabels = value),
            ),
            SliderOption(
              label: 'Axis Margin',
              value: _axisMargin,
              min: 0,
              max: 24,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _axisMargin = value),
            ),
          ],
        ),
      ],
      _AxisPattern.minorTicks => [
        OptionSection(
          title: 'Ticks & Grid',
          icon: Icons.linear_scale,
          children: [
            BoolOption(
              label: 'Show Minor Ticks',
              value: _showMinorTicks,
              onChanged: (value) => setState(() => _showMinorTicks = value),
            ),
            IntSliderOption(
              label: 'Minor Tick Count',
              value: _minorTickCount,
              min: 1,
              max: 9,
              onChanged: (value) => setState(() => _minorTickCount = value),
            ),
            SliderOption(
              label: 'Minor Tick Length',
              value: _minorTickLength,
              min: 1,
              max: 6,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _minorTickLength = value),
            ),
            BoolOption(
              label: 'Horizontal Grid',
              value: _horizontalGrid,
              onChanged: (value) => setState(() => _horizontalGrid = value),
            ),
            BoolOption(
              label: 'Vertical Grid',
              value: _verticalGrid,
              onChanged: (value) => setState(() => _verticalGrid = value),
            ),
            SliderOption(
              label: 'Grid Stroke',
              value: _gridWidth,
              min: 0.25,
              max: 2,
              divisions: 7,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _gridWidth = value),
            ),
          ],
        ),
      ],
      _AxisPattern.renderWindows => [
        OptionSection(
          title: 'Render Windows',
          icon: Icons.crop_free,
          children: [
            SliderOption(
              label: 'X renderMin',
              value: _xRenderMin,
              min: 0,
              max: 35,
              divisions: 7,
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _xRenderMin = value),
            ),
            SliderOption(
              label: 'X renderMax',
              value: _xRenderMax,
              min: 65,
              max: 100,
              divisions: 7,
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _xRenderMax = value),
            ),
            SliderOption(
              label: 'Y renderMin',
              value: _yRenderMin,
              min: 35,
              max: 55,
              divisions: 10,
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _yRenderMin = value),
            ),
            SliderOption(
              label: 'Y renderMax',
              value: _yRenderMax,
              min: 75,
              max: 95,
              divisions: 10,
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _yRenderMax = value),
            ),
          ],
        ),
      ],
      _AxisPattern.axisSlots => [
        OptionSection(
          title: 'Axis Slot Allocation',
          icon: Icons.swap_vert,
          children: [
            IntSliderOption(
              label: 'Max Axes Per Side',
              value: _maxAxesPerSide,
              min: 1,
              max: 4,
              onChanged: (value) => setState(() => _maxAxesPerSide = value),
            ),
            EnumOption<AxisSwapMode>(
              label: 'Swap Mode',
              value: _axisSwapMode,
              values: AxisSwapMode.values,
              labelBuilder: (value) => switch (value) {
                AxisSwapMode.sticky => 'Sticky',
                AxisSwapMode.revert => 'Revert on deselect',
              },
              onChanged: (value) => setState(() => _axisSwapMode = value),
            ),
          ],
        ),
      ],
    };
  }

  void _selectPattern(_AxisPattern pattern) {
    if (_selectedPattern == pattern) return;
    setState(() {
      _selectedPattern = pattern;
      if (pattern != _AxisPattern.axisSlots) _slotStatus = null;
    });
  }

  static String _patternLabel(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds => 'Labels & bounds',
      _AxisPattern.minorTicks => 'Ticks & grid',
      _AxisPattern.renderWindows => 'Render windows',
      _AxisPattern.axisSlots => 'Axis slots',
    };
  }

  static String _patternDescription(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds => 'Titles, units, formatting, position',
      _AxisPattern.minorTicks => 'Major/minor subdivisions and grid',
      _AxisPattern.renderWindows => 'Hide ticks without rescaling data',
      _AxisPattern.axisSlots => 'Constrain and promote competing axes',
    };
  }

  static String _patternStageTitle(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds => 'Axis formatting playground',
      _AxisPattern.minorTicks => 'Tick and grid playground',
      _AxisPattern.renderWindows => 'Fixed scale with filtered ticks',
      _AxisPattern.axisSlots => '5 right axes competing for visible slots',
    };
  }

  static String _patternStageSubtitle(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds =>
        'Padded scale bounds · 0–100 tick window · custom time formatter · configurable units',
      _AxisPattern.minorTicks =>
        'Unlabelled minor marks subdivide each labelled major interval',
      _AxisPattern.renderWindows =>
        'The data scale remains 0–100 / 35–95 while tick visibility changes',
      _AxisPattern.axisSlots =>
        'Tap a legend item to promote its axis; toggle visibility independently',
    };
  }

  static String _patternInstruction(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds =>
        'Move the Y-axis, change unit placement, or hide ticks and labels independently. Hover the chart to verify crosshair labels use the configured axes.',
      _AxisPattern.minorTicks =>
        'Sweep the minor count from 1 to 9. Minor marks stay unlabelled, shorter than major ticks, and evenly divide each interval.',
      _AxisPattern.renderWindows =>
        'Move renderMin and renderMax. Ticks outside the window disappear, but series geometry and the fixed min/max coordinate space do not move.',
      _AxisPattern.axisSlots =>
        'Reduce the slot limit, then tap an overflow series in the legend. Sticky keeps the promoted axis visible; revert restores declaration order on deselect.',
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
}

class _AxisPatternCard extends StatelessWidget {
  const _AxisPatternCard({
    super.key,
    required this.pattern,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _AxisPattern pattern;
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
      label: 'Select ${_AxesPageState._patternLabel(pattern)} axis pattern',
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
                        _AxesPageState._patternLabel(pattern),
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
                        key: ValueKey('selected-axis-${pattern.name}'),
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _AxesPageState._patternDescription(pattern),
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

class _AxisPatternGuide extends StatelessWidget {
  const _AxisPatternGuide({
    super.key,
    required this.pattern,
    required this.slotStatus,
  });

  final _AxisPattern pattern;
  final String? slotStatus;

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
                      _AxesPageState._patternLabel(pattern),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _explanation(pattern, slotStatus),
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
                    _apiSummary(pattern),
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

  static IconData _icon(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds => Icons.straighten,
      _AxisPattern.minorTicks => Icons.linear_scale,
      _AxisPattern.renderWindows => Icons.crop_free,
      _AxisPattern.axisSlots => Icons.swap_vert,
    };
  }

  static String _explanation(_AxisPattern pattern, String? slotStatus) {
    return switch (pattern) {
      _AxisPattern.labelsBounds =>
        'Separate coordinate bounds, physical placement, title/unit display, formatter, tick marks, labels, and crosshair labels.',
      _AxisPattern.minorTicks =>
        'Major ticks carry values. Minor ticks subdivide intervals without labels, while horizontal and vertical grids remain independently configurable.',
      _AxisPattern.renderWindows =>
        'min/max define the coordinate system. renderMin/renderMax only filter which ticks and labels are painted.',
      _AxisPattern.axisSlots =>
        slotStatus ??
            'Five right-side axes compete for a configurable number of slots; series selection promotes an overflow axis.',
    };
  }

  static String _apiSummary(_AxisPattern pattern) {
    return switch (pattern) {
      _AxisPattern.labelsBounds =>
        'XAxisConfig(label, unit, min, max, tickCount, labelFormatter) · YAxisConfig(position, labelDisplay)',
      _AxisPattern.minorTicks =>
        'showMinorTicks · minorTickCount · minorTickLength · GridConfig(horizontal, vertical)',
      _AxisPattern.renderWindows =>
        'min/max = scale · renderMin/renderMax = painted tick window',
      _AxisPattern.axisSlots =>
        'maxAxesPerSide · axisSwapMode · BravenChartController.selectSeries()',
    };
  }
}
