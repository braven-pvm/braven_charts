// Copyright 2025 Braven Charts - Axis Render Range Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Showcase for renderMin / renderMax — tick-window filtering on X and Y axes.
///
/// The coordinate space (min/max) sets the full data range used for scaling.
/// renderMin/renderMax restrict which tick marks and labels are actually drawn,
/// without moving or clipping any data.
///
/// Three charts:
///  1. Y-axis render range — negative-dipping data, padded coordinate space
///  2. X-axis render range — suppress early/late ticks on a time axis
///  3. Both axes — combined render window on a dual-axis chart
class AxisRenderRangePage extends StatefulWidget {
  const AxisRenderRangePage({super.key});

  @override
  State<AxisRenderRangePage> createState() => _AxisRenderRangePageState();
}

class _AxisRenderRangePageState extends State<AxisRenderRangePage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Y-axis render window (chart 1 & 3)
  double _yRenderMin = 0;
  double _yRenderMax = 12;

  // X-axis render window (chart 2 & 3)
  double _xRenderMin = 10;
  double _xRenderMax = 90;

  @override
  void initState() {
    super.initState();
    _optionsController.showGrid = true;
    _optionsController.showAxisLines = true;
    _optionsController.showLegend = true;
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  /// Lactate-like curve: starts at −3, rises steeply to ~14.
  /// The negative portion represents "resting debt" padding in coordinate space.
  static final List<ChartDataPoint> _lactatePoints = List.generate(
    21,
    (i) {
      final x = i * 5.0;
      // Sigmoid-like rise from -3 to 14
      final y = -3 + 17 / (1 + math.exp(-0.15 * (x - 60)));
      return ChartDataPoint(x: x, y: double.parse(y.toStringAsFixed(2)));
    },
  );

  /// Heart-rate curve: starts ~100, rises to ~185.
  static final List<ChartDataPoint> _hrPoints = List.generate(
    21,
    (i) {
      final x = i * 5.0;
      final y = 100 + 85 * (1 - math.exp(-x / 55));
      return ChartDataPoint(x: x, y: double.parse(y.toStringAsFixed(1)));
    },
  );

  /// Smooth sine-based series for the X-axis render range demo.
  static final List<ChartDataPoint> _sinePoints = List.generate(
    101,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 50 + 40 * math.sin(i * math.pi / 30),
    ),
  );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Axis Render Range',
      subtitle: 'renderMin / renderMax — filter ticks without affecting data scaling',
      optionsChildren: _buildOptions(),
      chart: _buildCharts(),
      bottomPanel: _buildStatus(),
    );
  }

  // ── Options panel ─────────────────────────────────────────────────────────

  List<Widget> _buildOptions() {
    return [
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Y-Axis Render Window',
        icon: Icons.align_vertical_center,
        children: [
          SliderOption(
            label: 'Y renderMin',
            value: _yRenderMin,
            min: -4,
            max: 4,
            divisions: 8,
            suffix: '',
            decimalPlaces: 0,
            onChanged: (v) => setState(() => _yRenderMin = v.roundToDouble()),
          ),
          SliderOption(
            label: 'Y renderMax',
            value: _yRenderMax,
            min: 8,
            max: 15,
            divisions: 7,
            suffix: '',
            decimalPlaces: 0,
            onChanged: (v) => setState(() => _yRenderMax = v.roundToDouble()),
          ),
        ],
      ),
      OptionSection(
        title: 'X-Axis Render Window',
        icon: Icons.align_horizontal_center,
        children: [
          SliderOption(
            label: 'X renderMin',
            value: _xRenderMin,
            min: 0,
            max: 30,
            divisions: 6,
            suffix: '',
            decimalPlaces: 0,
            onChanged: (v) => setState(() => _xRenderMin = v.roundToDouble()),
          ),
          SliderOption(
            label: 'X renderMax',
            value: _xRenderMax,
            min: 70,
            max: 100,
            divisions: 6,
            suffix: '',
            decimalPlaces: 0,
            onChanged: (v) => setState(() => _xRenderMax = v.roundToDouble()),
          ),
        ],
      ),
      const OptionSection(
        title: 'What to check',
        icon: Icons.fact_check_outlined,
        children: [
          InfoBox(
            message:
                'Ticks outside the render window disappear while data stays '
                'in place. Chart 1: Y-axis min=−4 but only ticks within '
                '[renderMin, renderMax] are drawn — drag Y sliders to confirm '
                'data does not move. Chart 2: X ticks clipped at both ends. '
                'Chart 3: both axes clipped simultaneously.',
          ),
        ],
      ),
    ];
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  Widget _buildCharts() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ListView(
          children: [
            // ── Chart 1: Y-axis render range ────────────────────────────────
            SizedBox(
              height: 320,
              child: ChartCard(
                title: 'Y-Axis Render Range',
                subtitle:
                    'Coordinate space: Y ∈ [−4, 15]. '
                    'Render window: [renderMin, renderMax] from sliders. '
                    'Data position is unchanged — only visible ticks change.',
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'lactate',
                      name: 'Lactate',
                      points: _lactatePoints,
                      color: const Color(0xFF1565C0),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.4,
                      showDataPointMarkers: true,
                      dataPointMarkerRadius: 3.5,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Lactate',
                        unit: 'mmol/L',
                        color: const Color(0xFF1565C0),
                        min: -4,
                        max: 15,
                        renderMin: _yRenderMin,
                        renderMax: _yRenderMax,
                        showAxisLine: _optionsController.showAxisLines,
                        showCrosshairLabel: true,
                        showMinorTicks: true,
                        minorTickCount: 1,
                      ).copyWith(id: 'lactate-axis'),
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    label: 'Time',
                    unit: 'min',
                    min: 0,
                    max: 100,
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  normalizationMode: NormalizationMode.perSeries,
                  grid: GridConfig(
                    horizontal: _optionsController.showGrid,
                    vertical: _optionsController.showGrid,
                  ),
                  showLegend: _optionsController.showLegend,
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.tracking(interpolate: true),
                    tooltip: const TooltipConfig(enabled: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Chart 2: X-axis render range ────────────────────────────────
            SizedBox(
              height: 300,
              child: ChartCard(
                title: 'X-Axis Render Range',
                subtitle:
                    'Coordinate space: X ∈ [0, 100]. '
                    'Ticks outside [xRenderMin, xRenderMax] are suppressed. '
                    'Useful to hide warm-up or cool-down intervals.',
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'sine',
                      name: 'Signal',
                      points: _sinePoints,
                      color: const Color(0xFF2E7D32),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.2,
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    label: 'Time',
                    unit: 's',
                    min: 0,
                    max: 100,
                    renderMin: _xRenderMin,
                    renderMax: _xRenderMax,
                    showAxisLine: _optionsController.showAxisLines,
                    showMinorTicks: true,
                    minorTickCount: 1,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Y',
                    unit: 'u',
                    min: 0,
                    max: 100,
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  grid: GridConfig(
                    horizontal: _optionsController.showGrid,
                    vertical: _optionsController.showGrid,
                  ),
                  showLegend: _optionsController.showLegend,
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.tracking(interpolate: true),
                    tooltip: const TooltipConfig(enabled: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Chart 3: Both axes + dual Y ─────────────────────────────────
            SizedBox(
              height: 320,
              child: ChartCard(
                title: 'Both Axes — Dual Y',
                subtitle:
                    'Lactate (left, Y ∈ [−4,15]) + HR (right, Y ∈ [80,200]). '
                    'X and Y render windows applied simultaneously.',
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'lac2',
                      name: 'Lactate',
                      points: _lactatePoints,
                      color: const Color(0xFF1565C0),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.2,
                      showDataPointMarkers: true,
                      dataPointMarkerRadius: 3,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Lactate',
                        unit: 'mmol/L',
                        color: const Color(0xFF1565C0),
                        min: -4,
                        max: 15,
                        renderMin: _yRenderMin,
                        renderMax: _yRenderMax,
                        showAxisLine: _optionsController.showAxisLines,
                        showCrosshairLabel: true,
                      ).copyWith(id: 'lac2-axis'),
                    ),
                    LineChartSeries(
                      id: 'hr2',
                      name: 'HR',
                      points: _hrPoints,
                      color: const Color(0xFFE53935),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.2,
                      showDataPointMarkers: true,
                      dataPointMarkerRadius: 3,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'HR',
                        unit: 'bpm',
                        color: const Color(0xFFE53935),
                        min: 80,
                        max: 200,
                        showAxisLine: _optionsController.showAxisLines,
                        showCrosshairLabel: true,
                      ).copyWith(id: 'hr2-axis'),
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    label: 'Time',
                    unit: 'min',
                    min: 0,
                    max: 100,
                    renderMin: _xRenderMin,
                    renderMax: _xRenderMax,
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  normalizationMode: NormalizationMode.perSeries,
                  grid: GridConfig(
                    horizontal: _optionsController.showGrid,
                    vertical: _optionsController.showGrid,
                  ),
                  showLegend: _optionsController.showLegend,
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.tracking(interpolate: true),
                    tooltip: const TooltipConfig(enabled: false),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Status bar ────────────────────────────────────────────────────────────

  Widget _buildStatus() {
    return StatusPanel(
      items: [
        const StatusItem(label: 'Charts', value: '3'),
        StatusItem(
          label: 'Y window',
          value: '${_yRenderMin.toInt()} → ${_yRenderMax.toInt()}',
          color: Colors.blue.shade700,
        ),
        StatusItem(
          label: 'X window',
          value: '${_xRenderMin.toInt()} → ${_xRenderMax.toInt()}',
          color: Colors.green.shade700,
        ),
      ],
      highlighted: true,
      color: Colors.teal.shade50,
    );
  }
}
