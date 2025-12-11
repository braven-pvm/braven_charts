import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Task 12 Demo: Tooltip Value Formatting with Units
///
/// Demonstrates:
/// - MultiAxisValueFormatter for clean value display
/// - Tooltip shows Y-values with units (e.g., "250 W", "145 bpm")
/// - No over-precision in displayed values
/// - Works with multi-axis configuration
void main() => runApp(const Task012TooltipDemo());

class Task012TooltipDemo extends StatelessWidget {
  const Task012TooltipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task 12: Tooltip Value Formatting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 12: Tooltip with Units'),
          backgroundColor: const Color(0xFF2D2D2D),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMultiAxisChartWithTooltips(),
              const SizedBox(height: 24),
              _buildValueFormatterExamples(),
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
            'Tooltip Value Formatting Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hover over data points to see formatted values with units:\n'
            '• Power values show "W" unit (e.g., "250 W")\n'
            '• Heart Rate values show "bpm" unit (e.g., "145 bpm")\n'
            '• Values are formatted with appropriate precision (no over-precision)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiAxisChartWithTooltips() {
    // Power data: 100-400W range
    final powerData = List.generate(15, (i) {
      final base = 150 + (i * 16);
      final variation = (i % 3 == 0)
          ? 25.5
          : (i % 3 == 1)
              ? -18.3
              : 12.7;
      return ChartDataPoint(x: i.toDouble(), y: base + variation);
    });

    // Heart rate data: 80-170 bpm range
    final hrData = List.generate(15, (i) {
      final base = 85 + (i * 5.5);
      final variation = (i % 4 == 0)
          ? 10.25
          : (i % 4 == 2)
              ? -6.8
              : 4.3;
      return ChartDataPoint(x: i.toDouble(), y: base + variation);
    });

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D3D3D)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Hover over data points to see formatted tooltips',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BravenChartPlus(
              series: [
                LineChartSeries(
                  id: 'power',
                  name: 'Power',
                  points: powerData,
                  color: Colors.blue,
                  strokeWidth: 2.5,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 5.0,
                  // Multi-axis with inline config
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Power',
                    unit: 'W', // Unit shown in tooltip
                  ),
                ),
                LineChartSeries(
                  id: 'heartrate',
                  name: 'Heart Rate',
                  points: hrData,
                  color: Colors.red,
                  strokeWidth: 2.5,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 5.0,
                  // Multi-axis with inline config
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.right,
                    label: 'Heart Rate',
                    unit: 'bpm', // Unit shown in tooltip
                  ),
                ),
              ],
              normalizationMode: NormalizationMode.perSeries,
              theme: ChartTheme.dark,
              showLegend: true,
              interactionConfig: const InteractionConfig(
                enabled: true,
                enableSelection: true,
                tooltip: TooltipConfig(
                  enabled: true,
                  // Note: Using package TooltipTriggerMode to avoid Flutter material conflict
                  preferredPosition: TooltipPosition.auto,
                  showDelay: Duration(milliseconds: 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueFormatterExamples() {
    // Demonstrate the MultiAxisValueFormatter directly
    final examples = [
      ('250.0', 'W', MultiAxisValueFormatter.format(value: 250.0, unit: 'W')),
      (
        '145.678',
        'bpm',
        MultiAxisValueFormatter.format(value: 145.678, unit: 'bpm')
      ),
      (
        '0.00456',
        'L',
        MultiAxisValueFormatter.format(value: 0.00456, unit: 'L')
      ),
      ('-50.5', 'W', MultiAxisValueFormatter.format(value: -50.5, unit: 'W')),
      ('1234.5', null, MultiAxisValueFormatter.format(value: 1234.5)),
      (
        '0.5 (denorm)',
        '100-300 → W',
        MultiAxisValueFormatter.formatWithDenormalization(
          normalizedValue: 0.5,
          min: 100,
          max: 300,
          unit: 'W',
        )
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MultiAxisValueFormatter Examples',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: const Color(0xFF3D3D3D)),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFF3D3D3D)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Input Value',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Unit',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Output',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ...examples.map((e) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(e.$1,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(e.$2 ?? '(none)',
                            style: const TextStyle(color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          e.$3,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ],
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
            '• MultiAxisValueFormatter provides clean value formatting\n'
            '• optimalPrecision() determines decimal places by magnitude\n'
            '• formatWithDenormalization() converts 0-1 values back to original\n'
            '• Tooltip uses axis unit from YAxisConfig for each series\n'
            '• No over-precision: "250.00000001" becomes "250"',
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
            '✅ T023: Tooltip displays original Y-values with units\n'
            '✅ T042: MultiAxisValueFormatter created\n'
            '✅ T045: Decimal values formatted appropriately\n'
            '✅ T040: Unit tests for value formatting',
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
