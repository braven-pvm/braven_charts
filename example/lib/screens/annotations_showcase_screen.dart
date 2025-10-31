import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Comprehensive showcase of all 5 annotation types
///
/// Demonstrates:
/// - TextAnnotation: Free-form text labels
/// - PointAnnotation: Highlight specific data points
/// - RangeAnnotation: Highlight ranges on x or y axis
/// - ThresholdAnnotation: Show target/limit lines
/// - TrendAnnotation: Display trend lines (linear, polynomial, exponential, moving average)
class AnnotationsShowcaseScreen extends StatefulWidget {
  const AnnotationsShowcaseScreen({super.key});

  @override
  State<AnnotationsShowcaseScreen> createState() => _AnnotationsShowcaseScreenState();
}

class _AnnotationsShowcaseScreenState extends State<AnnotationsShowcaseScreen> {
  // Sample data for demonstrations
  final _salesData = ChartSeries(
    id: 'sales',
    name: 'Monthly Sales',
    points: const [
      ChartDataPoint(x: 1, y: 12000),
      ChartDataPoint(x: 2, y: 15000),
      ChartDataPoint(x: 3, y: 13500),
      ChartDataPoint(x: 4, y: 18000),
      ChartDataPoint(x: 5, y: 16500),
      ChartDataPoint(x: 6, y: 22000),
      ChartDataPoint(x: 7, y: 20500),
      ChartDataPoint(x: 8, y: 24000),
    ],
  );

  bool _showTextAnnotations = true;
  bool _showPointAnnotations = true;
  bool _showRangeAnnotations = true;
  bool _showThresholdAnnotations = true;
  bool _showTrendAnnotations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotations Showcase'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildControls(),
          const SizedBox(height: 24),
          _buildAllAnnotationsChart(),
          const SizedBox(height: 32),
          _buildTextAnnotationDemo(),
          const SizedBox(height: 24),
          _buildDualModeTextAnnotationDemo(),
          const SizedBox(height: 24),
          _buildPointAnnotationDemo(),
          const SizedBox(height: 24),
          _buildRangeAnnotationDemo(),
          const SizedBox(height: 24),
          _buildThresholdAnnotationDemo(),
          const SizedBox(height: 24),
          _buildTrendAnnotationDemo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.label, color: Colors.purple.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annotation Types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BravenChart supports 5 annotation types to highlight, '
                    'explain, and analyze your data.',
                    style: TextStyle(color: Colors.purple.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toggle Annotations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Text'),
                  selected: _showTextAnnotations,
                  onSelected: (value) => setState(() => _showTextAnnotations = value),
                ),
                FilterChip(
                  label: const Text('Point'),
                  selected: _showPointAnnotations,
                  onSelected: (value) => setState(() => _showPointAnnotations = value),
                ),
                FilterChip(
                  label: const Text('Range'),
                  selected: _showRangeAnnotations,
                  onSelected: (value) => setState(() => _showRangeAnnotations = value),
                ),
                FilterChip(
                  label: const Text('Threshold'),
                  selected: _showThresholdAnnotations,
                  onSelected: (value) => setState(() => _showThresholdAnnotations = value),
                ),
                FilterChip(
                  label: const Text('Trend'),
                  selected: _showTrendAnnotations,
                  onSelected: (value) => setState(() => _showTrendAnnotations = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAnnotationsChart() {
    final chartAnnotations = <TextAnnotation>[];
    final seriesAnnotations = <ChartAnnotation>[];

    if (_showTextAnnotations) {
      chartAnnotations.add(
        TextAnnotation(
          id: 'peak_label',
          text: 'Peak Sales!',
          position: const Offset(320, 80),
          style: const AnnotationStyle(
            textStyle: TextStyle(fontSize: 14, color: Colors.red),
            backgroundColor: Colors.white,
            borderColor: Colors.red,
            borderWidth: 2,
          ),
        ),
      );
    }

    if (_showPointAnnotations) {
      seriesAnnotations.add(
        PointAnnotation(
          id: 'highlight_peak',
          label: 'Record',
          seriesId: 'sales',
          dataPointIndex: 7, // August - highest point
          markerShape: MarkerShape.star,
          markerSize: 16,
          style: const AnnotationStyle(
            textStyle: TextStyle(color: Colors.orange),
            borderColor: Colors.orange,
          ),
        ),
      );
    }

    if (_showRangeAnnotations) {
      seriesAnnotations.add(
        RangeAnnotation(
          id: 'summer_range',
          label: 'Summer Sales',
          startX: 6,
          endX: 8,
          fillColor: Colors.yellow.withValues(alpha: 0.2),
          borderColor: Colors.orange,
        ),
      );
    }

    if (_showThresholdAnnotations) {
      seriesAnnotations.addAll([
        ThresholdAnnotation(
          id: 'target',
          label: 'Target',
          value: 20000,
          axis: AnnotationAxis.y,
          style: const AnnotationStyle(
            textStyle: TextStyle(color: Colors.green),
            borderColor: Colors.green,
            borderWidth: 2,
          ),
        ),
        ThresholdAnnotation(
          id: 'warning',
          label: 'Low',
          value: 14000,
          axis: AnnotationAxis.y,
          style: AnnotationStyle(
            textStyle: TextStyle(color: Colors.red.shade300),
            borderColor: Colors.red.shade300,
            borderWidth: 2,
          ),
        ),
      ]);
    }

    if (_showTrendAnnotations) {
      seriesAnnotations.add(
        TrendAnnotation(
          id: 'growth_trend',
          label: 'Growth Trend',
          seriesId: 'sales',
          trendType: TrendType.linear,
          style: AnnotationStyle(
            borderColor: Colors.blue.shade700,
            borderWidth: 2,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Annotations Combined',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toggle annotation types above to see them in action',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [_salesData.copyWith(annotations: seriesAnnotations)],
              annotations: chartAnnotations,
              title: '2025 Monthly Sales',
              width: 400,
              height: 350,
              theme: ChartTheme.defaultLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAnnotationDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'TextAnnotation - Screen Coordinates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Add free-form text labels at fixed screen positions. '
              'Text stays in place regardless of zoom/pan.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.area,
              series: [_salesData],
              annotations: [
                TextAnnotation(
                  id: 'start',
                  text: 'Year Start',
                  position: const Offset(50, 250),
                  style: const AnnotationStyle(
                    textStyle: TextStyle(fontSize: 12, color: Colors.blue),
                    backgroundColor: Colors.white,
                  ),
                ),
                TextAnnotation(
                  id: 'mid',
                  text: 'Mid-Year\nReview',
                  position: const Offset(200, 150),
                  style: AnnotationStyle(
                    textStyle: TextStyle(fontSize: 14, color: Colors.orange.shade700),
                    backgroundColor: Colors.orange.shade50,
                    borderColor: Colors.orange,
                    borderWidth: 2,
                  ),
                ),
                TextAnnotation(
                  id: 'end',
                  text: 'Strong Finish 🎉',
                  position: const Offset(320, 80),
                  style: const AnnotationStyle(
                    textStyle: TextStyle(fontSize: 14, color: Colors.green),
                    backgroundColor: Colors.white,
                    borderColor: Colors.green,
                    borderWidth: 2,
                  ),
                ),
              ],
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 8),
            _buildCodeSnippet('''
TextAnnotation(
  id: 'note',
  text: 'Important Note',
  position: Offset(200, 100), // Fixed screen position
  style: AnnotationStyle(
    textStyle: TextStyle(fontSize: 14),
    textStyle: TextStyle(color: Colors.blue),
  ),
)'''),
          ],
        ),
      ),
    );
  }

  Widget _buildDualModeTextAnnotationDemo() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.anchor, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'TextAnnotation - Data Coordinates (NEW!)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Anchor text to specific data points. Text moves with zoom/pan. '
              'Try zooming/panning to see the difference!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'demo-data',
                  name: 'Demo Series',
                  points: [
                    const ChartDataPoint(x: 0, y: 5),
                    const ChartDataPoint(x: 1, y: 7),
                    const ChartDataPoint(x: 2, y: 3), // Valley
                    const ChartDataPoint(x: 3, y: 8),
                    const ChartDataPoint(x: 4, y: 6),
                    const ChartDataPoint(x: 5, y: 9), // Peak
                  ],
                ),
              ],
              annotations: [
                // Data-coordinate mode: Anchored to peak point
                TextAnnotation(
                  id: 'peak',
                  text: 'Peak\n(5, 9)',
                  dataX: 5.0,
                  dataY: 9.0,
                  seriesId: 'demo-data',
                  backgroundColor: Colors.red.withOpacity(0.9),
                  borderColor: Colors.red,
                  style: const AnnotationStyle(
                    textStyle: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                // Data-coordinate mode: Anchored to valley point
                TextAnnotation(
                  id: 'valley',
                  text: 'Valley\n(2, 3)',
                  dataX: 2.0,
                  dataY: 3.0,
                  seriesId: 'demo-data',
                  backgroundColor: Colors.blue.withOpacity(0.9),
                  borderColor: Colors.blue,
                  style: const AnnotationStyle(
                    textStyle: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
              interactionConfig: const InteractionConfig(
                enableZoom: true,
                enablePan: true,
                crosshair: CrosshairConfig(enabled: true),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Zoom/pan to see data-anchored text move with the data points!',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildCodeSnippet('''
// Data-coordinate mode: Anchored to data point
TextAnnotation(
  id: 'peak',
  text: 'Peak (5, 9)',
  dataX: 5.0,          // Data X coordinate
  dataY: 9.0,          // Data Y coordinate
  seriesId: 'my-series', // Series ID
  backgroundColor: Colors.red,
  style: AnnotationStyle(
    textStyle: TextStyle(fontSize: 12),
    textStyle: TextStyle(color: Colors.white),
  ),
)'''),
          ],
        ),
      ),
    );
  }

  Widget _buildPointAnnotationDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'PointAnnotation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Highlight specific data points with custom markers. '
              'Choose from 7 marker shapes.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                _salesData.copyWith(
                  annotations: [
                    PointAnnotation(
                      id: 'min',
                      label: 'Lowest',
                      seriesId: 'sales',
                      dataPointIndex: 0,
                      markerShape: MarkerShape.triangle,
                      markerSize: 14,
                      style: const AnnotationStyle(
                        textStyle: TextStyle(color: Colors.red),
                        borderColor: Colors.red,
                      ),
                    ),
                    PointAnnotation(
                      id: 'max',
                      label: 'Highest',
                      seriesId: 'sales',
                      dataPointIndex: 7,
                      markerShape: MarkerShape.star,
                      markerSize: 16,
                      style: const AnnotationStyle(
                        textStyle: TextStyle(color: Colors.green),
                        borderColor: Colors.green,
                      ),
                    ),
                    PointAnnotation(
                      id: 'mid',
                      label: 'Notable',
                      seriesId: 'sales',
                      dataPointIndex: 3,
                      markerShape: MarkerShape.diamond,
                      markerSize: 12,
                      style: const AnnotationStyle(
                        textStyle: TextStyle(color: Colors.orange),
                        borderColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 8),
            _buildCodeSnippet('''
PointAnnotation(
  id: 'peak',
  label: 'Record High',
  seriesId: 'sales',
  dataPointIndex: 7,
  markerShape: MarkerShape.star,
  markerSize: 16,
  style: AnnotationStyle(
    textStyle: TextStyle(color: Colors.green),
    borderColor: Colors.green,
  ),
)

// 7 shapes: circle, square, triangle,
// diamond, star, cross, plus'''),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeAnnotationDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.highlight, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'RangeAnnotation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Highlight ranges on X or Y axis. Great for showing '
              'time periods, value ranges, or zones.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.area,
              series: [
                _salesData.copyWith(
                  annotations: [
                    RangeAnnotation(
                      id: 'q1',
                      label: 'Q1',
                      startX: 1,
                      endX: 3,
                      fillColor: Colors.blue.withValues(alpha: 0.1),
                      borderColor: Colors.blue,
                      style: AnnotationStyle(
                        textStyle: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                    RangeAnnotation(
                      id: 'q2',
                      label: 'Q2',
                      startX: 4,
                      endX: 6,
                      fillColor: Colors.green.withValues(alpha: 0.1),
                      borderColor: Colors.green,
                      style: AnnotationStyle(
                        textStyle: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    RangeAnnotation(
                      id: 'q3',
                      label: 'Q3',
                      startX: 7,
                      endX: 8,
                      fillColor: Colors.orange.withValues(alpha: 0.1),
                      borderColor: Colors.orange,
                      style: AnnotationStyle(
                        textStyle: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                    RangeAnnotation(
                      id: 'target_zone',
                      label: 'Target Zone',
                      startY: 18000,
                      endY: 25000,
                      fillColor: Colors.green.withValues(alpha: 0.05),
                      borderColor: Colors.green.shade300,
                    ),
                  ],
                ),
              ],
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 8),
            _buildCodeSnippet('''
RangeAnnotation(
  id: 'q1',
  label: 'Q1 2025',
  startX: 1,
  endX: 3,
  fillColor: Colors.blue.withOpacity(0.1),
  borderColor: Colors.blue,
  style: AnnotationStyle(
    textStyle: TextStyle(color: Colors.blue),
  ),
)'''),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdAnnotationDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.horizontal_rule, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'ThresholdAnnotation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Display horizontal or vertical reference lines. '
              'Perfect for targets, limits, and benchmarks.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.line,
              series: [
                _salesData.copyWith(
                  annotations: [
                    ThresholdAnnotation(
                      id: 'target',
                      label: 'Sales Target',
                      value: 20000,
                      axis: AnnotationAxis.y,
                      style: const AnnotationStyle(
                        textStyle: TextStyle(color: Colors.green, fontSize: 12),
                        borderColor: Colors.green,
                        borderWidth: 3,
                      ),
                    ),
                    ThresholdAnnotation(
                      id: 'stretch',
                      label: 'Stretch Goal',
                      value: 23000,
                      axis: AnnotationAxis.y,
                      style: AnnotationStyle(
                        textStyle: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                        borderColor: Colors.blue.shade700,
                        borderWidth: 2,
                      ),
                    ),
                    ThresholdAnnotation(
                      id: 'minimum',
                      label: 'Minimum',
                      value: 14000,
                      axis: AnnotationAxis.y,
                      style: const AnnotationStyle(
                        textStyle: TextStyle(color: Colors.red, fontSize: 11),
                        borderColor: Colors.red,
                        borderWidth: 2,
                      ),
                    ),
                    ThresholdAnnotation(
                      id: 'mid_year',
                      label: 'Mid Year',
                      value: 4.5,
                      axis: AnnotationAxis.x,
                      style: AnnotationStyle(
                        borderColor: Colors.purple.shade400,
                        borderWidth: 2,
                        textStyle: TextStyle(color: Colors.purple.shade700),
                      ),
                    ),
                  ],
                ),
              ],
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 8),
            _buildCodeSnippet('''
// Horizontal threshold
ThresholdAnnotation(
  id: 'target',
  label: 'Target',
  value: 20000,
  axis: AnnotationAxis.y,
  style: AnnotationStyle(
    borderColor: Colors.green,
    borderWidth: 2,
  ),
)

// Vertical threshold
ThresholdAnnotation(
  id: 'cutoff',
  value: 6,
  axis: AnnotationAxis.x,
  style: AnnotationStyle(
    borderColor: Colors.red,
  ),
)'''),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnnotationDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                const Text(
                  'TrendAnnotation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Visualize trends with 4 algorithms: linear, polynomial, '
              'exponential, and moving average.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            BravenChart(
              chartType: ChartType.scatter,
              series: [
                _salesData.copyWith(
                  annotations: [
                    TrendAnnotation(
                      id: 'linear',
                      label: 'Linear Trend',
                      seriesId: 'sales',
                      trendType: TrendType.linear,
                      style: AnnotationStyle(
                        borderColor: Colors.blue.shade700,
                        borderWidth: 3,
                        textStyle: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                    TrendAnnotation(
                      id: 'moving_avg',
                      label: 'Moving Avg',
                      seriesId: 'sales',
                      trendType: TrendType.movingAverage,
                      windowSize: 5, // Required for moving average
                      style: const AnnotationStyle(
                        borderColor: Colors.orange,
                        borderWidth: 2,
                        textStyle: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
              width: 400,
              height: 300,
              theme: ChartTheme.defaultLight,
            ),
            const SizedBox(height: 8),
            _buildCodeSnippet('''
// Linear regression
TrendAnnotation(
  id: 'trend',
  label: 'Growth Trend',
  seriesId: 'sales',
  trendType: TrendType.linear,
  style: AnnotationStyle(
    borderColor: Colors.blue,
    borderWidth: 2,
  ),
)

// Types: linear, polynomial,
// exponential, movingAverage'''),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}
