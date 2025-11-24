import 'package:braven_charts/src/interaction/models/interaction_config.dart';
import 'package:braven_charts/src/interaction/models/tooltip_config.dart';
import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/options_panel.dart';

class ChartTypesPage extends StatefulWidget {
  const ChartTypesPage({super.key});

  @override
  State<ChartTypesPage> createState() => _ChartTypesPageState();
}

class _ChartTypesPageState extends State<ChartTypesPage> {
  // Data
  late List<ChartDataPoint> _data;

  // Chart Type
  bool _isLineChart = true;

  // Common Options
  bool _showGrid = true;
  bool _showAxis = true;
  bool _showBorder = true;
  bool _showTooltip = true;

  // Line Options
  bool _fillArea = true;
  bool _curved = true;
  bool _showPoints = true;

  // Bar Options
  double _barWidth = 10.0;
  double _barSpacing = 5.0;

  @override
  void initState() {
    super.initState();
    _data = DataGenerator.generateSineWave();
  }

  void _regenerateData() {
    setState(() {
      _data = DataGenerator.generateRandom(count: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Chart Area
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildChart(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _regenerateData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate Data'),
                ),
              ],
            ),
          ),
        ),

        // Options Panel
        Expanded(
          flex: 1,
          child: OptionsPanel(
            title: 'Chart Options',
            children: [
              OptionSection(
                title: 'Type',
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Line'), icon: Icon(Icons.show_chart)),
                      ButtonSegment(value: false, label: Text('Bar'), icon: Icon(Icons.bar_chart)),
                    ],
                    selected: {_isLineChart},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isLineChart = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              OptionSection(
                title: 'Common',
                children: [
                  BoolOption(
                    label: 'Show Grid',
                    value: _showGrid,
                    onChanged: (v) => setState(() => _showGrid = v),
                  ),
                  BoolOption(
                    label: 'Show Axis',
                    value: _showAxis,
                    onChanged: (v) => setState(() => _showAxis = v),
                  ),
                  BoolOption(
                    label: 'Show Border',
                    value: _showBorder,
                    onChanged: (v) => setState(() => _showBorder = v),
                  ),
                  BoolOption(
                    label: 'Show Tooltip',
                    value: _showTooltip,
                    onChanged: (v) => setState(() => _showTooltip = v),
                  ),
                ],
              ),
              if (_isLineChart)
                OptionSection(
                  title: 'Line Settings',
                  children: [
                    BoolOption(
                      label: 'Fill Area',
                      value: _fillArea,
                      onChanged: (v) => setState(() => _fillArea = v),
                    ),
                    BoolOption(
                      label: 'Curved Line',
                      value: _curved,
                      onChanged: (v) => setState(() => _curved = v),
                    ),
                    BoolOption(
                      label: 'Show Points',
                      value: _showPoints,
                      onChanged: (v) => setState(() => _showPoints = v),
                    ),
                  ],
                )
              else
                OptionSection(
                  title: 'Bar Settings',
                  children: [
                    SliderOption(
                      label: 'Bar Width',
                      value: _barWidth,
                      min: 2,
                      max: 50,
                      onChanged: (v) => setState(() => _barWidth = v),
                    ),
                    SliderOption(
                      label: 'Bar Spacing',
                      value: _barSpacing,
                      min: 0,
                      max: 20,
                      onChanged: (v) => setState(() => _barSpacing = v),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    // Create series based on chart type
    final List<ChartSeries> series;
    if (_isLineChart) {
      // Use AreaChartSeries when fill is enabled, otherwise LineChartSeries
      if (_fillArea) {
        series = [
          AreaChartSeries(
            id: 'series_1',
            name: 'Data Series',
            points: _data,
            color: Colors.blue,
            interpolation: _curved ? LineInterpolation.bezier : LineInterpolation.linear,
            showDataPointMarkers: _showPoints,
            fillOpacity: 0.3,
          ),
        ];
      } else {
        series = [
          LineChartSeries(
            id: 'series_1',
            name: 'Data Series',
            points: _data,
            color: Colors.blue,
            interpolation: _curved ? LineInterpolation.bezier : LineInterpolation.linear,
            showDataPointMarkers: _showPoints,
          ),
        ];
      }
    } else {
      series = [
        BarChartSeries(
          id: 'series_1',
          name: 'Data Series',
          points: _data,
          color: Colors.blue,
          barWidthPixels: _barWidth,
        ),
      ];
    }

    final chart = BravenChartPlus(
      chartType: _isLineChart ? ChartType.line : ChartType.bar,
      series: series,
      xAxis: AxisConfig(
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
        showGrid: _showGrid,
        showAxisLine: _showAxis,
        showTickMarks: _showAxis,
      ),
      yAxis: AxisConfig(
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
        showGrid: _showGrid,
        showAxisLine: _showAxis,
        showTickMarks: _showAxis,
      ),
      interactionConfig: InteractionConfig(
        tooltip: TooltipConfig(enabled: _showTooltip),
        showFocusBorder: false, // Disable auto-select border on hover
      ),
    );

    if (_showBorder) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: chart,
      );
    }

    return chart;
  }
}
