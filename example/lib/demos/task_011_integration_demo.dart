import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Task 11 Demo: Multi-Axis Widget Integration
///
/// Demonstrates:
/// - yAxes parameter on BravenChartPlus
/// - axisBindings connecting series to axes
/// - Both axes rendering with derived colors
/// - Data properly normalized per-axis
void main() => runApp(const Task011IntegrationDemo());

class Task011IntegrationDemo extends StatelessWidget {
  const Task011IntegrationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task 11: Multi-Axis Integration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 11: Multi-Axis Widget Integration'),
          backgroundColor: const Color(0xFF2D2D2D),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMultiAxisChart(),
              const SizedBox(height: 24),
              _buildDescription(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Axis Integration Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This demo shows BravenChartPlus with multiple Y-axes:\n'
            '• Left axis (Blue): Power in Watts (0-400W)\n'
            '• Right axis (Red): Heart Rate in BPM (60-180)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiAxisChart() {
    // Power data: 100-400W range with some variation
    final powerData = List.generate(20, (i) {
      final base = 100 + (i * 15);
      final variation = (i % 3 == 0)
          ? 20
          : (i % 3 == 1)
              ? -15
              : 10;
      return ChartDataPoint(x: i.toDouble(), y: (base + variation).toDouble());
    });

    // Heart rate data: 60-180 bpm range (10x smaller scale)
    final hrData = List.generate(20, (i) {
      final base = 60 + (i * 6);
      final variation = (i % 4 == 0)
          ? 8
          : (i % 4 == 2)
              ? -5
              : 3;
      return ChartDataPoint(x: i.toDouble(), y: (base + variation).toDouble());
    });

    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D3D3D)),
      ),
      padding: const EdgeInsets.all(16),
      child: BravenChartPlus(
        chartType: ChartType.line,
        series: [
          LineChartSeries(
            id: 'power',
            name: 'Power (W)',
            points: powerData,
            color: Colors.blue,
            strokeWidth: 2.5,
          ),
          LineChartSeries(
            id: 'heartrate',
            name: 'Heart Rate (bpm)',
            points: hrData,
            color: Colors.red,
            strokeWidth: 2.5,
          ),
        ],
        // NEW: Multi-axis configuration via widget parameters
        yAxes: [
          YAxisConfig(
            id: 'power-axis',
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            // color: null - will derive from series (blue)
          ),
          YAxisConfig(
            id: 'hr-axis',
            position: YAxisPosition.right,
            label: 'Heart Rate',
            unit: 'bpm',
            // color: null - will derive from series (red)
          ),
        ],
        axisBindings: const [
          SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
          SeriesAxisBinding(seriesId: 'heartrate', yAxisId: 'hr-axis'),
        ],
        normalizationMode: NormalizationMode.perSeries,
        theme: ChartTheme.dark,
        showLegend: true,
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Implementation Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• BravenChartPlus now accepts yAxes: List<YAxisConfig>\n'
            '• Each axis can be positioned left/right with labels and units\n'
            '• SeriesAxisBinding connects series to their Y-axes\n'
            '• Axes inherit colors from bound series when not explicitly set\n'
            '• NormalizationMode.perSeries ensures each series uses full height\n'
            '• Multi-axis rendering via MultiAxisPainter in ChartRenderBox',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'SpecKit Tasks Completed:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '✅ T010: yAxes/normalizationMode parameters\n'
            '✅ T015: Widget test for multi-axis\n'
            '✅ T008: Widget test directory created\n'
            '✅ T018: SeriesAxisResolver for bindings\n'
            '✅ T026: Auto-detection widget test\n'
            '✅ T032: Color axes widget test',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
