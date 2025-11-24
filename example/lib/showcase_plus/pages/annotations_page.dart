import 'package:flutter/material.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/chart_annotation.dart';
import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import '../data/data_generator.dart';
import '../widgets/options_panel.dart';

class AnnotationsPage extends StatefulWidget {
  const AnnotationsPage({super.key});

  @override
  State<AnnotationsPage> createState() => _AnnotationsPageState();
}

class _AnnotationsPageState extends State<AnnotationsPage> {
  // Annotation visibility toggles
  bool _showPoint = true;
  bool _showRange = true;
  bool _showText = true;
  bool _showThreshold = true;
  bool _showTrend = true;

  // Annotation configuration
  bool _allowDragging = true;
  bool _allowEditing = true;

  @override
  Widget build(BuildContext context) {
    // Generate sample data
    final data = DataGenerator.generateSineWave(
      count: 50,
      amplitude: 40,
      frequency: 0.3,
      yOffset: 100,
    );

    // Create series
    final series = [
      LineChartSeries(
        id: 'data-series',
        name: 'Sample Data',
        points: data,
        color: Colors.blue,
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: false,
      ),
    ];

    // Create annotations list
    final annotations = <ChartAnnotation>[];

    if (_showPoint) {
      annotations.add(
        PointAnnotation(
          id: 'point-1',
          seriesId: 'data-series',
          dataPointIndex: 12,
          markerShape: MarkerShape.star,
          markerSize: 16.0,
          markerColor: Colors.red,
          label: 'Peak Point',
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );
    }

    if (_showRange) {
      annotations.add(
        RangeAnnotation(
          id: 'range-1',
          startX: 15.0,
          endX: 35.0,
          fillColor: Colors.orange.withOpacity(0.2),
          borderColor: Colors.orange,
          label: 'Important Range',
          labelPosition: AnnotationLabelPosition.topLeft,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          snapToValue: true,
        ),
      );
    }

    if (_showText) {
      annotations.add(
        TextAnnotation(
          id: 'text-1',
          text: 'Chart Title',
          position: const Offset(20, 20),
          anchor: AnnotationAnchor.topLeft,
          backgroundColor: Colors.white.withOpacity(0.8),
          borderColor: Colors.grey,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );
    }

    if (_showThreshold) {
      annotations.addAll([
        ThresholdAnnotation(
          id: 'threshold-y',
          axis: AnnotationAxis.y,
          value: 120.0,
          lineColor: Colors.green,
          lineWidth: 2.0,
          dashPattern: const [5, 5],
          label: 'Target',
          labelPosition: AnnotationLabelPosition.topRight,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
        ThresholdAnnotation(
          id: 'threshold-x',
          axis: AnnotationAxis.x,
          value: 25.0,
          lineColor: Colors.purple,
          lineWidth: 2.0,
          dashPattern: const [10, 5],
          label: 'Milestone',
          labelPosition: AnnotationLabelPosition.bottomRight,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      ]);
    }

    if (_showTrend) {
      annotations.add(
        TrendAnnotation(
          id: 'trend-1',
          seriesId: 'data-series',
          trendType: TrendType.linear,
          lineColor: Colors.red.withOpacity(0.7),
          lineWidth: 2.0,
          dashPattern: const [8, 4],
          label: 'Linear Trend',
          allowDragging: false,
          allowEditing: _allowEditing,
        ),
      );
    }

    // Create axis configs
    final xAxis = AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: true,
      showAxisLine: true,
    );

    final yAxis = AxisConfig(
      orientation: AxisOrientation.vertical,
      position: AxisPosition.left,
      showGrid: true,
      showAxisLine: true,
    );

    return Row(
      children: [
        // Chart
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chart Annotations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'All 5 annotation types: Point, Range, Text, Threshold, and Trend',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    series: series,
                    annotations: annotations,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    interactiveAnnotations: _allowDragging || _allowEditing,
                    showLegend: true,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annotation Types',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.red, '★ Point', 'Marks specific data points'),
                      _buildLegendItem(Colors.orange, '▬ Range', 'Highlights regions'),
                      _buildLegendItem(Colors.grey, '✎ Text', 'Free-form text labels'),
                      _buildLegendItem(Colors.green, '─ Threshold', 'Reference lines'),
                      _buildLegendItem(Colors.red.withOpacity(0.7), '╱ Trend', 'Statistical trends'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Options Panel
        SizedBox(
          width: 320,
          child: OptionsPanel(
            title: 'Annotation Options',
            children: [
              OptionSection(
                title: 'Visibility',
                children: [
                  BoolOption(
                    label: 'Show Point Annotations',
                    value: _showPoint,
                    onChanged: (value) => setState(() => _showPoint = value),
                  ),
                  BoolOption(
                    label: 'Show Range Annotations',
                    value: _showRange,
                    onChanged: (value) => setState(() => _showRange = value),
                  ),
                  BoolOption(
                    label: 'Show Text Annotations',
                    value: _showText,
                    onChanged: (value) => setState(() => _showText = value),
                  ),
                  BoolOption(
                    label: 'Show Threshold Annotations',
                    value: _showThreshold,
                    onChanged: (value) => setState(() => _showThreshold = value),
                  ),
                  BoolOption(
                    label: 'Show Trend Annotations',
                    value: _showTrend,
                    onChanged: (value) => setState(() => _showTrend = value),
                  ),
                ],
              ),
              OptionSection(
                title: 'Interactivity',
                children: [
                  BoolOption(
                    label: 'Allow Dragging',
                    value: _allowDragging,
                    onChanged: (value) => setState(() => _allowDragging = value),
                  ),
                  BoolOption(
                    label: 'Allow Editing',
                    value: _allowEditing,
                    onChanged: (value) => setState(() => _allowEditing = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String symbol, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
