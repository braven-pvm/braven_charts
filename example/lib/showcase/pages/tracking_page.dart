// Copyright 2025 Braven Charts - Tracking Lab Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Dedicated page for visually verifying crosshair tracking alignment.
class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  bool _showTrackingTooltip = true;
  bool _showIntersectionMarkers = true;

  late List<ChartSeries> _interpolationSeries;
  late List<ChartSeries> _tensionSeries;
  late List<ChartSeries> _stressSeries;

  @override
  void initState() {
    super.initState();
    _optionsController.enableZoom = true;
    _optionsController.enablePan = true;
    _optionsController.showLegend = true;
    _optionsController.showAxisLines = true;
    _optionsController.showGrid = true;
    _buildDemoSeries();
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  void _buildDemoSeries() {
    _interpolationSeries = [
      _lineSeries(
        id: 'linear_reference',
        name: 'Linear reference',
        color: const Color(0xFF1F4E79),
        interpolation: LineInterpolation.linear,
        points: _offsetSeries(_baseInterpolationPoints, 90),
      ),
      _lineSeries(
        id: 'bezier_soft',
        name: 'Bezier 0.15',
        color: const Color(0xFF2F855A),
        interpolation: LineInterpolation.bezier,
        tension: 0.15,
        points: _offsetSeries(_baseInterpolationPoints, 60),
      ),
      _lineSeries(
        id: 'bezier_tight',
        name: 'Bezier 0.55',
        color: const Color(0xFFB7791F),
        interpolation: LineInterpolation.bezier,
        tension: 0.55,
        points: _offsetSeries(_baseInterpolationPoints, 30),
      ),
      _lineSeries(
        id: 'monotone_curve',
        name: 'Monotone cubic',
        color: const Color(0xFF8B2C2C),
        interpolation: LineInterpolation.monotone,
        points: _offsetSeries(_baseInterpolationPoints, 0),
      ),
      _lineSeries(
        id: 'stepped_control',
        name: 'Stepped control',
        color: const Color(0xFF6B46C1),
        interpolation: LineInterpolation.stepped,
        points: _offsetSeries(_baseInterpolationPoints, -30),
      ),
    ];

    _tensionSeries = [
      _lineSeries(
        id: 'tension_low',
        name: 'Tension 0.10',
        color: const Color(0xFF1565C0),
        interpolation: LineInterpolation.bezier,
        tension: 0.10,
        points: _offsetSeries(_baseTensionPoints, 40),
      ),
      _lineSeries(
        id: 'tension_medium',
        name: 'Tension 0.30',
        color: const Color(0xFF00897B),
        interpolation: LineInterpolation.bezier,
        tension: 0.30,
        points: _offsetSeries(_baseTensionPoints, 0),
      ),
      _lineSeries(
        id: 'tension_high',
        name: 'Tension 0.70',
        color: const Color(0xFFEF6C00),
        interpolation: LineInterpolation.bezier,
        tension: 0.70,
        points: _offsetSeries(_baseTensionPoints, -40),
      ),
    ];

    _stressSeries = [
      _lineSeries(
        id: 'stress_bezier',
        name: 'Bezier stress',
        color: const Color(0xFF3949AB),
        interpolation: LineInterpolation.bezier,
        tension: 0.45,
        points: _baseStressPoints,
      ),
      _lineSeries(
        id: 'stress_monotone',
        name: 'Monotone stress',
        color: const Color(0xFFD81B60),
        interpolation: LineInterpolation.monotone,
        points: _offsetSeries(_baseStressPoints, -18),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Tracking Lab',
      subtitle:
          'Purpose-built crosshair tracking verification for interpolation and tension alignment',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChartList(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Tracking Overlay',
        icon: Icons.track_changes,
        children: [
          BoolOption(
            label: 'Show tracking tooltip',
            value: _showTrackingTooltip,
            onChanged: (value) => setState(() => _showTrackingTooltip = value),
          ),
          BoolOption(
            label: 'Show intersection markers',
            value: _showIntersectionMarkers,
            onChanged: (value) =>
                setState(() => _showIntersectionMarkers = value),
          ),
        ],
      ),
      const OptionSection(
        title: 'Test Notes',
        icon: Icons.fact_check_outlined,
        children: [
          InfoBox(
            message:
                'Move horizontally across each chart and watch whether the tracking dots stay centered on the visible stroke. The first chart compares interpolation families, the second isolates bezier tension, and the third stresses sharp reversals.',
          ),
        ],
      ),
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Rebuild Demo Series',
            icon: Icons.refresh,
            onPressed: () => setState(_buildDemoSeries),
          ),
        ],
      ),
    ];
  }

  Widget _buildChartList() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ListView(
          children: [
            SizedBox(
              height: 320,
              child: ChartCard(
                title: 'Interpolation Comparison',
                subtitle:
                    'Linear, stepped, monotone, and two bezier curves with the same underlying anchors',
                child: _buildChart(
                  series: _interpolationSeries,
                  yAxisLabel: 'Offset lane',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ChartCard(
                title: 'Bezier Tension Sweep',
                subtitle:
                    'Same anchors, different tension values to expose drift on stronger curvature',
                child: _buildChart(
                  series: _tensionSeries,
                  yAxisLabel: 'Tension lane',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ChartCard(
                title: 'Stress Test',
                subtitle:
                    'Sharp direction changes and plateaus designed to make tracking errors obvious',
                child: _buildChart(
                  series: _stressSeries,
                  yAxisLabel: 'Stress path',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart({
    required List<ChartSeries> series,
    required String yAxisLabel,
  }) {
    return BravenChartPlus(
      series: series,
      theme: _optionsController.theme,
      showLegend: _optionsController.showLegend,
      showXScrollbar: _optionsController.showXScrollbar,
      showYScrollbar: _optionsController.showYScrollbar,
      scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
      xAxisConfig: XAxisConfig(
        label: 'Sample Index',
        showAxisLine: _optionsController.showAxisLines,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: yAxisLabel,
        showAxisLine: _optionsController.showAxisLines,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.enableZoom,
        enablePan: _optionsController.enablePan,
        crosshair: CrosshairConfig.tracking(
          interpolate: true,
          showTooltip: _showTrackingTooltip,
          showMarkers: _showIntersectionMarkers,
        ),
        tooltip: const TooltipConfig(enabled: false),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        const StatusItem(label: 'Charts', value: '3'),
        const StatusItem(label: 'Series', value: '10'),
        StatusItem(
          label: 'Tracking',
          value: 'Forced',
          color: Colors.green.shade700,
        ),
        StatusItem(
          label: 'Tooltip',
          value: _showTrackingTooltip ? 'On' : 'Off',
          color: Colors.blue.shade700,
        ),
      ],
      highlighted: true,
      color: Colors.green.shade50,
    );
  }

  LineChartSeries _lineSeries({
    required String id,
    required String name,
    required Color color,
    required LineInterpolation interpolation,
    required List<ChartDataPoint> points,
    double tension = 0.25,
  }) {
    return LineChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      interpolation: interpolation,
      tension: tension,
      strokeWidth: 2.6,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointMarkerRadius: 3.5,
    );
  }

  List<ChartDataPoint> _offsetSeries(
    List<ChartDataPoint> source,
    double offset,
  ) {
    return source
        .map((point) => ChartDataPoint(x: point.x, y: point.y + offset))
        .toList(growable: false);
  }

  static const List<ChartDataPoint> _baseInterpolationPoints = [
    ChartDataPoint(x: 0, y: 12),
    ChartDataPoint(x: 1, y: 28),
    ChartDataPoint(x: 2, y: 6),
    ChartDataPoint(x: 3, y: 34),
    ChartDataPoint(x: 4, y: 14),
    ChartDataPoint(x: 5, y: 40),
    ChartDataPoint(x: 6, y: 18),
    ChartDataPoint(x: 7, y: 46),
    ChartDataPoint(x: 8, y: 24),
    ChartDataPoint(x: 9, y: 54),
    ChartDataPoint(x: 10, y: 30),
  ];

  static const List<ChartDataPoint> _baseTensionPoints = [
    ChartDataPoint(x: 0, y: 24),
    ChartDataPoint(x: 1, y: 42),
    ChartDataPoint(x: 2, y: 12),
    ChartDataPoint(x: 3, y: 66),
    ChartDataPoint(x: 4, y: 18),
    ChartDataPoint(x: 5, y: 76),
    ChartDataPoint(x: 6, y: 28),
    ChartDataPoint(x: 7, y: 58),
    ChartDataPoint(x: 8, y: 22),
    ChartDataPoint(x: 9, y: 70),
    ChartDataPoint(x: 10, y: 34),
  ];

  static const List<ChartDataPoint> _baseStressPoints = [
    ChartDataPoint(x: 0, y: 82),
    ChartDataPoint(x: 1, y: 88),
    ChartDataPoint(x: 2, y: 54),
    ChartDataPoint(x: 3, y: 58),
    ChartDataPoint(x: 4, y: 22),
    ChartDataPoint(x: 5, y: 72),
    ChartDataPoint(x: 6, y: 20),
    ChartDataPoint(x: 7, y: 74),
    ChartDataPoint(x: 8, y: 44),
    ChartDataPoint(x: 9, y: 48),
    ChartDataPoint(x: 10, y: 16),
    ChartDataPoint(x: 11, y: 84),
  ];
}
