import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BravenChartPlus Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChartShowcasePage(),
    );
  }
}

class ChartShowcasePage extends StatefulWidget {
  const ChartShowcasePage({super.key});

  @override
  State<ChartShowcasePage> createState() => _ChartShowcasePageState();
}

class _ChartShowcasePageState extends State<ChartShowcasePage> {
  int _selectedChartIndex = 0;

  // Sample data for different chart types
  final List<ChartDataPoint> _sampleData = List.generate(
    20,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 50 + 30 * (i % 3 == 0 ? 1.5 : 1.0) + (i % 2 == 0 ? 10 : -10),
    ),
  );

  final List<ChartDataPoint> _sampleData2 = List.generate(
    20,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 70 + 20 * (i % 4 == 0 ? 1.2 : 0.8) + (i % 3 == 0 ? 15 : -5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('BravenChartPlus Showcase'),
      ),
      body: Column(
        children: [
          // Chart Type Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Line')),
                ButtonSegment(value: 1, label: Text('Area')),
                ButtonSegment(value: 2, label: Text('Bar')),
                ButtonSegment(value: 3, label: Text('Scatter')),
                ButtonSegment(value: 4, label: Text('Multiple Series')),
              ],
              selected: {_selectedChartIndex},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedChartIndex = newSelection.first;
                });
              },
            ),
          ),

          // Chart Display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSelectedChart(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedChartIndex) {
      case 0:
        return _buildLineChart();
      case 1:
        return _buildAreaChart();
      case 2:
        return _buildBarChart();
      case 3:
        return _buildScatterChart();
      case 4:
        return _buildMultiSeriesChart();
      default:
        return _buildLineChart();
    }
  }

  Widget _buildLineChart() {
    return BravenChartPlus(
      chartType: ChartType.line,
      lineStyle: LineStyle.smooth,
      series: [
        LineChartSeries(
          id: 'series1',
          name: 'Sample Data',
          points: _sampleData,
          color: Colors.blue,
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2.0,
          showDataPointMarkers: true,
        ),
      ],
      title: 'Line Chart Example',
      subtitle: 'Smooth bezier interpolation',
      showLegend: true,
    );
  }

  Widget _buildAreaChart() {
    return BravenChartPlus(
      chartType: ChartType.area,
      lineStyle: LineStyle.smooth,
      series: [
        AreaChartSeries(
          id: 'series1',
          name: 'Sample Data',
          points: _sampleData,
          color: Colors.green,
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2.0,
          fillOpacity: 0.3,
        ),
      ],
      title: 'Area Chart Example',
      subtitle: 'Filled area under curve',
      showLegend: true,
    );
  }

  Widget _buildBarChart() {
    return BravenChartPlus(
      chartType: ChartType.bar,
      series: [
        BarChartSeries(
          id: 'series1',
          name: 'Sample Data',
          points: _sampleData,
          color: Colors.orange,
          barWidthPercent: 0.7,
        ),
      ],
      title: 'Bar Chart Example',
      subtitle: 'Vertical bars',
      showLegend: true,
    );
  }

  Widget _buildScatterChart() {
    return BravenChartPlus(
      chartType: ChartType.scatter,
      series: [
        ScatterChartSeries(
          id: 'series1',
          name: 'Sample Data',
          points: _sampleData,
          color: Colors.purple,
          markerRadius: 4.0,
        ),
      ],
      title: 'Scatter Plot Example',
      subtitle: 'Individual data points',
      showLegend: true,
    );
  }

  Widget _buildMultiSeriesChart() {
    return BravenChartPlus(
      chartType: ChartType.line,
      lineStyle: LineStyle.smooth,
      series: [
        LineChartSeries(
          id: 'series1',
          name: 'Series 1',
          points: _sampleData,
          color: Colors.blue,
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2.0,
          showDataPointMarkers: true,
        ),
        LineChartSeries(
          id: 'series2',
          name: 'Series 2',
          points: _sampleData2,
          color: Colors.red,
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2.0,
          showDataPointMarkers: true,
        ),
      ],
      title: 'Multiple Series Example',
      subtitle: 'Two series on the same chart',
      showLegend: true,
    );
  }
}
