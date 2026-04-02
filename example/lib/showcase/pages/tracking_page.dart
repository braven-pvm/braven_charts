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

  late List<ChartSeries> _autoNormalizationSeries;
  late List<ChartSeries> _interpolationSeries;
  late List<ChartSeries> _tensionSeries;
  late List<ChartSeries> _stressSeries;
  late List<ChartSeries> _partialRangeSeries;

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
    _autoNormalizationSeries = [
      AreaChartSeries(
        id: 'fat_oxidation',
        name: 'Fat Oxidation (g/min)',
        points: const [
          ChartDataPoint(x: 155, y: 24.8),
          ChartDataPoint(x: 180, y: 25.1),
          ChartDataPoint(x: 205, y: 25.2),
          ChartDataPoint(x: 230, y: 25.1),
          ChartDataPoint(x: 255, y: 25.3),
          ChartDataPoint(x: 270, y: 25.4),
          ChartDataPoint(x: 280, y: 25.5),
          ChartDataPoint(x: 307, y: 34.6),
        ],
        color: const Color(0xFF10B981),
        interpolation: LineInterpolation.bezier,
        tension: 0.12,
        strokeWidth: 2.2,
        fillOpacity: 0.28,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Oxidation',
          unit: 'g/min',
          color: const Color(0xFF10B981),
          showCrosshairLabel: true,
        ).copyWith(id: 'fat-axis'),
      ),
      LineChartSeries(
        id: 'cho_oxidation',
        name: 'CHO Oxidation (g/min)',
        points: const [
          ChartDataPoint(x: 155, y: 24.5),
          ChartDataPoint(x: 180, y: 25.0),
          ChartDataPoint(x: 205, y: 25.3),
          ChartDataPoint(x: 230, y: 25.4),
          ChartDataPoint(x: 255, y: 25.6),
          ChartDataPoint(x: 268, y: 29.3),
          ChartDataPoint(x: 276, y: 30.1),
          ChartDataPoint(x: 281, y: 27.4),
          ChartDataPoint(x: 307, y: 0.4),
        ],
        color: const Color(0xFFF59E0B),
        interpolation: LineInterpolation.bezier,
        tension: 0.14,
        strokeWidth: 2.2,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Oxidation',
          unit: 'g/min',
          color: const Color(0xFFF59E0B),
          showCrosshairLabel: true,
        ).copyWith(id: 'cho-axis'),
      ),
    ];

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

    // Partial-range series: each series ends at a different x to test that the
    // crosshair stops tracking a series once the cursor moves past its last point.
    // Series end order: La_acc (x=18) → Lactate (x=22) → HR/VO₂ (x=30)
    _partialRangeSeries = [
      LineChartSeries(
        id: 'pr_vo2',
        name: 'VO₂ (mL/kg/min)',
        points: const [
          ChartDataPoint(x: 0, y: 20),
          ChartDataPoint(x: 3, y: 21),
          ChartDataPoint(x: 6, y: 23),
          ChartDataPoint(x: 9, y: 27),
          ChartDataPoint(x: 12, y: 32),
          ChartDataPoint(x: 15, y: 38),
          ChartDataPoint(x: 18, y: 44),
          ChartDataPoint(x: 21, y: 50),
          ChartDataPoint(x: 24, y: 55),
          ChartDataPoint(x: 27, y: 58),
          ChartDataPoint(x: 30, y: 60),
        ],
        color: const Color(0xFF1565C0),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.2,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'VO₂',
          unit: 'mL/kg/min',
          color: const Color(0xFF1565C0),
          showCrosshairLabel: true,
        ).copyWith(id: 'pr-vo2-axis'),
      ),
      LineChartSeries(
        id: 'pr_hr',
        name: 'HR (bpm)',
        points: const [
          ChartDataPoint(x: 0, y: 65),
          ChartDataPoint(x: 3, y: 72),
          ChartDataPoint(x: 6, y: 80),
          ChartDataPoint(x: 9, y: 90),
          ChartDataPoint(x: 12, y: 105),
          ChartDataPoint(x: 15, y: 120),
          ChartDataPoint(x: 18, y: 138),
          ChartDataPoint(x: 21, y: 152),
          ChartDataPoint(x: 24, y: 164),
          ChartDataPoint(x: 27, y: 172),
          ChartDataPoint(x: 30, y: 178),
        ],
        color: const Color(0xFFE53935),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.2,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'HR',
          unit: 'bpm',
          color: const Color(0xFFE53935),
          showCrosshairLabel: true,
        ).copyWith(id: 'pr-hr-axis'),
      ),
      // Lactate: ends at x=22 — crosshair should stop tracking it after that
      LineChartSeries(
        id: 'pr_lactate',
        name: 'Lactate (mmol/L)',
        points: const [
          ChartDataPoint(x: 0, y: 0.8),
          ChartDataPoint(x: 3, y: 0.9),
          ChartDataPoint(x: 6, y: 1.1),
          ChartDataPoint(x: 9, y: 1.4),
          ChartDataPoint(x: 12, y: 2.0),
          ChartDataPoint(x: 15, y: 3.2),
          ChartDataPoint(x: 18, y: 5.8),
          ChartDataPoint(x: 22, y: 9.4),
        ],
        color: const Color(0xFF2E7D32),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.4,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 5.0,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Lactate',
          unit: 'mmol/L',
          color: const Color(0xFF2E7D32),
          showCrosshairLabel: true,
        ).copyWith(id: 'pr-lac-axis'),
      ),
      // La_acc: ends at x=18 — the first series to disappear from the crosshair
      AreaChartSeries(
        id: 'pr_la_acc',
        name: 'La_acc (mmol/L/min)',
        points: const [
          ChartDataPoint(x: 0, y: 0.0),
          ChartDataPoint(x: 3, y: 0.1),
          ChartDataPoint(x: 6, y: 0.2),
          ChartDataPoint(x: 9, y: 0.4),
          ChartDataPoint(x: 12, y: 1.0),
          ChartDataPoint(x: 15, y: 2.8),
          ChartDataPoint(x: 18, y: 7.2),
        ],
        color: const Color(0xFF66BB6A),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.0,
        fillOpacity: 0.25,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 5.0,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'La_acc',
          unit: 'mmol/L/min',
          color: const Color(0xFF66BB6A),
          showCrosshairLabel: true,
        ).copyWith(id: 'pr-laacc-axis'),
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
                'Move horizontally across each chart and watch whether the tracking dots stay centered on the visible stroke. '
                'The first chart verifies the series end-boundary fix: La_acc (ends x=18) and Lactate (ends x=22) must vanish from the tooltip and lose their dot exactly at the marked boundary. '
                'The remaining charts cover auto-normalization, split-column layout, interpolation families, bezier tension, and sharp-reversal stress tests.',
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
              height: 360,
              child: ChartCard(
                title: 'Partial-Range Series — Crosshair End Boundary',
                subtitle:
                    'La_acc ends at x=18, Lactate ends at x=22, HR/VO₂ run to x=30. '
                    'Sweep right: each series must vanish from the tooltip and lose its dot exactly at its last point.',
                child: _buildChart(
                  series: _partialRangeSeries,
                  yAxisLabel: 'Value',
                  normalizationMode: NormalizationMode.perSeries,
                  xAxisConfig: const XAxisConfig(
                    label: 'Time',
                    unit: 'min',
                    min: 0,
                    max: 30,
                  ),
                  annotations: [
                    ThresholdAnnotation(
                      id: 'la_acc_end',
                      axis: AnnotationAxis.x,
                      value: 18,
                      label: 'La_acc ends',
                      labelPosition: AnnotationLabelPosition.topLeft,
                      lineColor: const Color(0xFF66BB6A),
                      lineWidth: 1.5,
                      dashPattern: [4, 4],
                      style: const AnnotationStyle(
                        textStyle: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ThresholdAnnotation(
                      id: 'lactate_end',
                      axis: AnnotationAxis.x,
                      value: 22,
                      label: 'Lactate ends',
                      labelPosition: AnnotationLabelPosition.topLeft,
                      lineColor: const Color(0xFF2E7D32),
                      lineWidth: 1.5,
                      dashPattern: [4, 4],
                      style: const AnnotationStyle(
                        textStyle: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ChartCard(
                title: 'Auto Normalization Repro',
                subtitle:
                    'Mixed area and line series with dual axes, forced tracking, and NormalizationMode.auto',
                child: _buildChart(
                  series: _autoNormalizationSeries,
                  yAxisLabel: 'Substrate Oxidation',
                  normalizationMode: NormalizationMode.auto,
                  xAxisConfig: const XAxisConfig(
                    label: 'Power',
                    unit: 'W',
                    min: 155,
                    max: 325,
                  ),
                  annotations: [
                    ThresholdAnnotation(
                      id: 'lt1',
                      axis: AnnotationAxis.x,
                      value: 155,
                      label: 'LT1',
                      lineColor: const Color(0xFFF59E0B),
                      lineWidth: 1.4,
                      dashPattern: [3, 3],
                    ),
                    ThresholdAnnotation(
                      id: 'lt2',
                      axis: AnnotationAxis.x,
                      value: 205,
                      label: 'LT2',
                      lineColor: const Color(0xFFF59E0B),
                      lineWidth: 1.4,
                      dashPattern: [3, 3],
                    ),
                    ThresholdAnnotation(
                      id: 'fatmax',
                      axis: AnnotationAxis.x,
                      value: 280,
                      label: 'FatMax',
                      lineColor: const Color(0xFF10B981),
                      lineWidth: 1.4,
                      dashPattern: [3, 3],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 380,
              child: ChartCard(
                title: 'Split Column 280px Repro',
                subtitle:
                    'Same mixed-series case, but constrained to a split-pane style viewport with the chart held near 280px tall',
                child: _buildSplitColumnRepro(),
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildSplitColumnRepro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitLayout = constraints.maxWidth >= 860;
        final chartPane = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SizedBox(
              height: 280,
              child: _buildChart(
                series: _autoNormalizationSeries,
                yAxisLabel: 'Substrate Oxidation',
                normalizationMode: NormalizationMode.auto,
                xAxisConfig: const XAxisConfig(
                  label: 'Power',
                  unit: 'W',
                  min: 155,
                  max: 325,
                ),
                annotations: [
                  ThresholdAnnotation(
                    id: 'split_lt1',
                    axis: AnnotationAxis.x,
                    value: 155,
                    label: 'LT1',
                    lineColor: const Color(0xFFF59E0B),
                    lineWidth: 1.4,
                    dashPattern: const [3, 3],
                  ),
                  ThresholdAnnotation(
                    id: 'split_lt2',
                    axis: AnnotationAxis.x,
                    value: 205,
                    label: 'LT2',
                    lineColor: const Color(0xFFF59E0B),
                    lineWidth: 1.4,
                    dashPattern: const [3, 3],
                  ),
                  ThresholdAnnotation(
                    id: 'split_fatmax',
                    axis: AnnotationAxis.x,
                    value: 280,
                    label: 'FatMax',
                    lineColor: const Color(0xFF10B981),
                    lineWidth: 1.4,
                    dashPattern: const [3, 3],
                  ),
                ],
              ),
            ),
          ),
        );

        final notesPane = DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewport Target',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'This mirrors the reported host layout: chart in a split pane, visibly narrower than full width, with the drawable chart region held around 280px tall.',
                ),
                SizedBox(height: 12),
                Text(
                  'What to check',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Initial render should match post-zoom behavior. Reset should return to the same tracked alignment rather than drifting back to an offset baseline.',
                ),
              ],
            ),
          ),
        );

        if (splitLayout) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: notesPane),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: chartPane),
            ],
          );
        }

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [notesPane, const SizedBox(height: 16), chartPane],
        );
      },
    );
  }

  Widget _buildChart({
    required List<ChartSeries> series,
    required String yAxisLabel,
    NormalizationMode normalizationMode = NormalizationMode.none,
    XAxisConfig? xAxisConfig,
    List<ChartAnnotation> annotations = const [],
  }) {
    return BravenChartPlus(
      series: series,
      annotations: annotations,
      theme: _optionsController.theme,
      showLegend: _optionsController.showLegend,
      showXScrollbar: _optionsController.showXScrollbar,
      showYScrollbar: _optionsController.showYScrollbar,
      scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
      xAxisConfig: (xAxisConfig ?? const XAxisConfig(label: 'Sample Index'))
          .copyWith(showAxisLine: _optionsController.showAxisLines),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: yAxisLabel,
        showAxisLine: _optionsController.showAxisLines,
      ),
      grid: GridConfig(
        horizontal: _optionsController.showGrid,
        vertical: _optionsController.showGrid,
      ),
      normalizationMode: normalizationMode,
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
        const StatusItem(label: 'Charts', value: '6'),
        const StatusItem(label: 'Series', value: '18'),
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
