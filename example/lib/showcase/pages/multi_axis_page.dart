// Copyright 2025 Braven Charts - Multi-Axis Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates multi-axis features:
/// - Dual Y-axis charts
/// - Different scales on each axis
/// - Series-to-axis binding
/// - Normalization modes
class MultiAxisPage extends StatefulWidget {
  const MultiAxisPage({super.key});

  @override
  State<MultiAxisPage> createState() => _MultiAxisPageState();
}

class _MultiAxisPageState extends State<MultiAxisPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Multi-axis demo selection
  int _selectedDemo = 0;

  // Generated data for different demos
  late List<ChartDataPoint> _powerData;
  late List<ChartDataPoint> _heartRateData;
  late List<ChartDataPoint> _cadenceData;
  late List<ChartDataPoint> _temperatureData;
  late List<ChartDataPoint> _pressureData;

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      // Athletic data - Power, HR, Cadence
      _powerData = DataGenerator.generatePowerData(count: 200);
      _heartRateData = DataGenerator.generateHeartRateData(count: 200);
      _cadenceData = DataGenerator.generateCadenceData(count: 200);

      // Scientific data - Temperature, Pressure
      _temperatureData = DataGenerator.generateTemperatureData(count: 100);
      _pressureData = DataGenerator.generateLinear(
        count: 100,
        slope: 0.5,
        intercept: 1013,
        noise: 5,
      );
    });
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Multi-Axis',
      subtitle: 'Display multiple scales in one chart',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Demo selection
      OptionSection(
        title: 'Demo Selection',
        icon: Icons.category,
        children: [
          SegmentedOption<int>(
            value: _selectedDemo,
            options: const [0, 1],
            labelBuilder: (v) => v == 0 ? 'Athletic' : 'Scientific',
            onChanged: (v) => setState(() => _selectedDemo = v),
          ),
          const SizedBox(height: 8),
          InfoBox(
            message: _selectedDemo == 0 ? 'Power, Heart Rate, and Cadence on different scales' : 'Temperature and Pressure with different units',
          ),
        ],
      ),

      // Actions
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Regenerate Data',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
        ],
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        if (_selectedDemo == 0) {
          return _buildAthleticChart();
        } else {
          return _buildScientificChart();
        }
      },
    );
  }

  Widget _buildAthleticChart() {
    return ChartCard(
      title: 'Athletic Performance',
      subtitle: 'Power (W), Heart Rate (bpm), Cadence (rpm)',
      child: BravenChartPlus(
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        series: [
          LineChartSeries(
            id: 'power',
            name: 'Power (W)',
            points: _powerData,
            color: Colors.blue,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'power_axis',
            unit: 'W',
          ),
          LineChartSeries(
            id: 'heart_rate',
            name: 'Heart Rate (bpm)',
            points: _heartRateData,
            color: Colors.red,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'hr_axis',
            unit: 'bpm',
          ),
          LineChartSeries(
            id: 'cadence',
            name: 'Cadence (rpm)',
            points: _cadenceData,
            color: Colors.green,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'cadence_axis',
            unit: 'rpm',
          ),
        ],
        theme: _optionsController.theme,
        showLegend: _optionsController.showLegend,
        showXScrollbar: _optionsController.showXScrollbar,
        showYScrollbar: _optionsController.showYScrollbar,
        xAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
        ),
        yAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
        ),
        yAxes: [
          YAxisConfig(
            id: 'power_axis',
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            showAxisLine: true,
          ),
          YAxisConfig(
            id: 'hr_axis',
            position: YAxisPosition.right,
            label: 'Heart Rate',
            unit: 'bpm',
            showAxisLine: true,
          ),
        ],
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          crosshair: const CrosshairConfig(enabled: true),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _buildScientificChart() {
    return ChartCard(
      title: 'Environmental Monitoring',
      subtitle: 'Temperature (°C) and Pressure (hPa)',
      child: BravenChartPlus(
        chartType: ChartType.line,
        lineStyle: LineStyle.smooth,
        series: [
          LineChartSeries(
            id: 'temperature',
            name: 'Temperature (°C)',
            points: _temperatureData,
            color: Colors.orange,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2.0,
            yAxisId: 'temp_axis',
            unit: '°C',
          ),
          LineChartSeries(
            id: 'pressure',
            name: 'Pressure (hPa)',
            points: _pressureData,
            color: Colors.purple,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.0,
            yAxisId: 'pressure_axis',
            unit: 'hPa',
          ),
        ],
        theme: _optionsController.theme,
        showLegend: _optionsController.showLegend,
        showXScrollbar: _optionsController.showXScrollbar,
        showYScrollbar: _optionsController.showYScrollbar,
        xAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
        ),
        yAxis: AxisConfig(
          showGrid: _optionsController.showGrid,
          showAxis: _optionsController.showAxisLines,
        ),
        yAxes: [
          YAxisConfig(
            id: 'temp_axis',
            position: YAxisPosition.left,
            label: 'Temperature',
            unit: '°C',
            showAxisLine: true,
          ),
          YAxisConfig(
            id: 'pressure_axis',
            position: YAxisPosition.right,
            label: 'Pressure',
            unit: 'hPa',
            showAxisLine: true,
          ),
        ],
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          crosshair: const CrosshairConfig(enabled: true),
          tooltip: const TooltipConfig(enabled: true),
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    if (_selectedDemo == 0) {
      return StatusPanel(
        items: [
          StatusItem(label: 'Power Pts', value: '${_powerData.length}'),
          StatusItem(label: 'HR Pts', value: '${_heartRateData.length}'),
          StatusItem(label: 'Cadence Pts', value: '${_cadenceData.length}'),
          const StatusItem(label: 'Axes', value: '3', color: Colors.blue),
        ],
      );
    } else {
      return StatusPanel(
        items: [
          StatusItem(label: 'Temp Pts', value: '${_temperatureData.length}'),
          StatusItem(label: 'Pressure Pts', value: '${_pressureData.length}'),
          const StatusItem(label: 'Axes', value: '2', color: Colors.blue),
        ],
      );
    }
  }
}
