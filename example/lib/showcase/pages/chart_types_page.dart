// Copyright 2025 Braven Charts - Chart Types Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates all available chart types with configurable options.
///
/// Chart types:
/// - Line charts (with various interpolation modes)
/// - Area charts (filled and stacked)
/// - Bar charts (grouped and stacked)
/// - Scatter charts (with markers)
class ChartTypesPage extends StatefulWidget {
  const ChartTypesPage({super.key});

  @override
  State<ChartTypesPage> createState() => _ChartTypesPageState();
}

class _ChartTypesPageState extends State<ChartTypesPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Chart-specific options
  ChartType _chartType = ChartType.line;
  LineInterpolation _interpolation = LineInterpolation.linear;
  double _strokeWidth = 2.0;
  double _fillOpacity = 0.3;
  double _barWidthPercent = 0.7;
  double _markerRadius = 4.0;
  bool _showSecondSeries = false;

  // Generated data
  late List<ChartDataPoint> _data1;
  late List<ChartDataPoint> _data2;

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      _data1 = DataGenerator.generateSineWave(
        count: 50,
        amplitude: 40,
        yOffset: 50,
        stepX: 0.5,
      );
      _data2 = DataGenerator.generateCosineWave(
        count: 50,
        amplitude: 30,
        yOffset: 60,
        stepX: 0.5,
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
      title: 'Chart Types',
      subtitle: 'Explore different visualization styles',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Chart type selector
      OptionSection(
        title: 'Chart Type',
        children: [
          EnumOption<ChartType>(
            label: 'Type',
            value: _chartType,
            values: ChartType.values,
            onChanged: (value) => setState(() => _chartType = value),
          ),
          BoolOption(
            label: 'Show second series',
            value: _showSecondSeries,
            onChanged: (value) => setState(() => _showSecondSeries = value),
          ),
        ],
      ),

      // Type-specific options
      if (_chartType == ChartType.line || _chartType == ChartType.area)
        OptionSection(
          title: 'Line Options',
          initiallyExpanded: false,
          children: [
            EnumOption<LineInterpolation>(
              label: 'Interpolation',
              value: _interpolation,
              values: LineInterpolation.values,
              onChanged: (value) => setState(() => _interpolation = value),
            ),
            SliderOption(
              label: 'Stroke Width',
              value: _strokeWidth,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
          ],
        ),

      if (_chartType == ChartType.area)
        OptionSection(
          title: 'Area Options',
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Fill Opacity',
              value: _fillOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) => setState(() => _fillOpacity = value),
            ),
          ],
        ),

      if (_chartType == ChartType.bar)
        OptionSection(
          title: 'Bar Options',
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Bar Width',
              value: _barWidthPercent,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) => setState(() => _barWidthPercent = value),
            ),
          ],
        ),

      if (_chartType == ChartType.scatter)
        OptionSection(
          title: 'Scatter Options',
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Marker Radius',
              value: _markerRadius,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (value) => setState(() => _markerRadius = value),
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
        return ChartCard(
          title: '${_chartType.name.toUpperCase()} Chart',
          subtitle: _getChartSubtitle(),
          child: BravenChartPlus(
            series: _buildSeries(),
            theme: _optionsController.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
            xAxis: AxisConfig(
              showGrid: _optionsController.showGrid,
              showAxis: _optionsController.showAxisLines,
            ),
            yAxis: AxisConfig(
              showGrid: _optionsController.showGrid,
              showAxis: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
            ),
          ),
        );
      },
    );
  }

  List<ChartSeries> _buildSeries() {
    final series = <ChartSeries>[];

    switch (_chartType) {
      case ChartType.line:
        series.add(LineChartSeries(
          id: 'series1',
          name: 'Series 1',
          points: _data1,
          color: Colors.blue,
          interpolation: _interpolation,
          strokeWidth: _strokeWidth,
          showDataPointMarkers: _optionsController.showDataMarkers,
        ));
        if (_showSecondSeries) {
          series.add(LineChartSeries(
            id: 'series2',
            name: 'Series 2',
            points: _data2,
            color: Colors.red,
            interpolation: _interpolation,
            strokeWidth: _strokeWidth,
            showDataPointMarkers: _optionsController.showDataMarkers,
          ));
        }

      case ChartType.area:
        series.add(AreaChartSeries(
          id: 'series1',
          name: 'Series 1',
          points: _data1,
          color: Colors.green,
          interpolation: _interpolation,
          strokeWidth: _strokeWidth,
          fillOpacity: _fillOpacity,
        ));
        if (_showSecondSeries) {
          series.add(AreaChartSeries(
            id: 'series2',
            name: 'Series 2',
            points: _data2,
            color: Colors.teal,
            interpolation: _interpolation,
            strokeWidth: _strokeWidth,
            fillOpacity: _fillOpacity,
          ));
        }

      case ChartType.bar:
        series.add(BarChartSeries(
          id: 'series1',
          name: 'Series 1',
          points: _data1,
          color: Colors.orange,
          barWidthPercent: _barWidthPercent,
        ));
        if (_showSecondSeries) {
          series.add(BarChartSeries(
            id: 'series2',
            name: 'Series 2',
            points: _data2,
            color: Colors.deepOrange,
            barWidthPercent: _barWidthPercent,
          ));
        }

      case ChartType.scatter:
        series.add(ScatterChartSeries(
          id: 'series1',
          name: 'Series 1',
          points: _data1,
          color: Colors.purple,
          markerRadius: _markerRadius,
        ));
        if (_showSecondSeries) {
          series.add(ScatterChartSeries(
            id: 'series2',
            name: 'Series 2',
            points: _data2,
            color: Colors.deepPurple,
            markerRadius: _markerRadius,
          ));
        }
    }

    return series;
  }

  String _getChartSubtitle() {
    switch (_chartType) {
      case ChartType.line:
        return 'Interpolation: ${_interpolation.name}';
      case ChartType.area:
        return 'Opacity: ${(_fillOpacity * 100).toInt()}%';
      case ChartType.bar:
        return 'Width: ${(_barWidthPercent * 100).toInt()}%';
      case ChartType.scatter:
        return 'Radius: ${_markerRadius.toStringAsFixed(1)}';
    }
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(
          label: 'Data Points',
          value: '${_data1.length}${_showSecondSeries ? ' × 2' : ''}',
        ),
        StatusItem(
          label: 'Chart Type',
          value: _chartType.name,
        ),
        StatusItem(
          label: 'Theme',
          value: _optionsController.theme?.toString().split('.').last ?? 'Default',
        ),
      ],
    );
  }
}
