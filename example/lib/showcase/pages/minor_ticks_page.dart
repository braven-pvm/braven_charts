// Copyright 2025 Braven Charts - Minor Ticks Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Dedicated page for visually verifying minor (sub) tick marks on axes.
///
/// Shows three charts:
///  1. X-axis minor ticks — horizontal axis subdivisions
///  2. Y-axis minor ticks — multi-axis with both left and right minor ticks
///  3. Both axes — combined control
class MinorTicksPage extends StatefulWidget {
  const MinorTicksPage({super.key});

  @override
  State<MinorTicksPage> createState() => _MinorTicksPageState();
}

class _MinorTicksPageState extends State<MinorTicksPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Minor tick controls
  bool _showMinorTicks = true;
  int _minorTickCount = 4;
  double _minorTickLength = 3.0;

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

  /// Linear ramp 0–100 over 11 steps — major ticks should land on 0,20,40,…
  static const List<ChartDataPoint> _linearPoints = [
    ChartDataPoint(x: 0, y: 0),
    ChartDataPoint(x: 10, y: 10),
    ChartDataPoint(x: 20, y: 20),
    ChartDataPoint(x: 30, y: 30),
    ChartDataPoint(x: 40, y: 40),
    ChartDataPoint(x: 50, y: 50),
    ChartDataPoint(x: 60, y: 60),
    ChartDataPoint(x: 70, y: 70),
    ChartDataPoint(x: 80, y: 80),
    ChartDataPoint(x: 90, y: 90),
    ChartDataPoint(x: 100, y: 100),
  ];

  /// Sine wave sampled at integer x=0..100 — shows minor ticks on curved data
  static final List<ChartDataPoint> _sinePoints = List.generate(
    101,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 50 + 45 * math.sin(i * math.pi / 25),
    ),
  );

  /// Secondary series: cosine offset, scaled 0–200 for a right Y-axis
  static final List<ChartDataPoint> _cosinePoints = List.generate(
    101,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 100 + 80 * math.cos(i * math.pi / 25),
    ),
  );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Ticks & Grid',
      subtitle: 'Configure minor tick subdivisions across X and Y axes',
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
        title: 'Minor Ticks',
        icon: Icons.linear_scale,
        children: [
          BoolOption(
            label: 'Show minor ticks',
            value: _showMinorTicks,
            onChanged: (v) => setState(() => _showMinorTicks = v),
          ),
          SliderOption(
            label: 'Minor tick count',
            value: _minorTickCount.toDouble(),
            min: 1,
            max: 9,
            divisions: 8,
            suffix: '',
            decimalPlaces: 0,
            onChanged: (v) => setState(() => _minorTickCount = v.round()),
          ),
          SliderOption(
            label: 'Minor tick length',
            value: _minorTickLength,
            min: 1,
            max: 6,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (v) => setState(() => _minorTickLength = v),
          ),
        ],
      ),
      const OptionSection(
        title: 'What to check',
        icon: Icons.fact_check_outlined,
        children: [
          InfoBox(
            message:
                'Chart 1: Minor ticks on the X-axis only. '
                'Chart 2: Minor ticks on both left and right Y-axes. '
                'Chart 3: Both axes at once. '
                'Sweep the count from 1 (midpoint only) to 9 (10 subdivisions) '
                'and confirm marks are evenly spaced between labelled major ticks. '
                'Minor ticks must be shorter than major ticks and carry no labels.',
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
            // ── Chart 1: X-axis minor ticks ─────────────────────────────────
            SizedBox(
              height: 300,
              child: ChartCard(
                title: 'X-Axis Minor Ticks',
                subtitle:
                    'Linear ramp 0–100. Major ticks every 20 units; '
                    'minor ticks subdivide each interval.',
                child: BravenChartPlus(
                  series: const [
                    LineChartSeries(
                      id: 'linear',
                      name: 'Linear',
                      points: _linearPoints,
                      color: Color(0xFF1565C0),
                      interpolation: LineInterpolation.linear,
                      strokeWidth: 2.4,
                      showDataPointMarkers: true,
                      dataPointMarkerRadius: 4,
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    label: 'X',
                    unit: 'u',
                    min: 0,
                    max: 100,
                    showAxisLine: _optionsController.showAxisLines,
                    showMinorTicks: _showMinorTicks,
                    minorTickCount: _minorTickCount,
                    minorTickLength: _minorTickLength,
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

            // ── Chart 2: Y-axis minor ticks (dual axis) ─────────────────────
            SizedBox(
              height: 300,
              child: ChartCard(
                title: 'Y-Axis Minor Ticks — Dual Axis',
                subtitle:
                    'Sine (left, 0–100) and cosine (right, 0–200). '
                    'Both axes show minor ticks independently.',
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'sine',
                      name: 'Sine',
                      points: _sinePoints,
                      color: const Color(0xFF2E7D32),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.2,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Sine',
                        unit: 'u',
                        color: const Color(0xFF2E7D32),
                        min: 0,
                        max: 100,
                        showAxisLine: _optionsController.showAxisLines,
                        showCrosshairLabel: true,
                        showMinorTicks: _showMinorTicks,
                        minorTickCount: _minorTickCount,
                        minorTickLength: _minorTickLength,
                      ).copyWith(id: 'sine-axis'),
                    ),
                    LineChartSeries(
                      id: 'cosine',
                      name: 'Cosine',
                      points: _cosinePoints,
                      color: const Color(0xFFE53935),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.2,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Cosine',
                        unit: 'u',
                        color: const Color(0xFFE53935),
                        min: 0,
                        max: 200,
                        showAxisLine: _optionsController.showAxisLines,
                        showCrosshairLabel: true,
                        showMinorTicks: _showMinorTicks,
                        minorTickCount: _minorTickCount,
                        minorTickLength: _minorTickLength,
                      ).copyWith(id: 'cosine-axis'),
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    label: 'X',
                    unit: 'u',
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

            // ── Chart 3: Both axes ──────────────────────────────────────────
            SizedBox(
              height: 300,
              child: ChartCard(
                title: 'Both Axes — Minor Ticks',
                subtitle:
                    'X-axis and Y-axis both carry minor ticks at the same '
                    'count and length settings.',
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'sine_both',
                      name: 'Sine',
                      points: _sinePoints,
                      color: const Color(0xFF6A1B9A),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 2.4,
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    label: 'X',
                    unit: 'u',
                    min: 0,
                    max: 100,
                    showAxisLine: _optionsController.showAxisLines,
                    showMinorTicks: _showMinorTicks,
                    minorTickCount: _minorTickCount,
                    minorTickLength: _minorTickLength,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Y',
                    unit: 'u',
                    min: 0,
                    max: 100,
                    showAxisLine: _optionsController.showAxisLines,
                    showMinorTicks: _showMinorTicks,
                    minorTickCount: _minorTickCount,
                    minorTickLength: _minorTickLength,
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
          label: 'Minor ticks',
          value: _showMinorTicks ? 'On' : 'Off',
          color: _showMinorTicks ? Colors.green.shade700 : Colors.grey,
        ),
        StatusItem(
          label: 'Count',
          value: '$_minorTickCount',
          color: Colors.blue.shade700,
        ),
        StatusItem(
          label: 'Length',
          value: '${_minorTickLength.toStringAsFixed(1)}px',
          color: Colors.orange.shade700,
        ),
      ],
      highlighted: true,
      color: Colors.purple.shade50,
    );
  }
}
