import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/options_panel.dart';

class AnnotationsPage extends StatefulWidget {
  const AnnotationsPage({super.key});

  @override
  State<AnnotationsPage> createState() => _AnnotationsPageState();
}

class _AnnotationsPageState extends State<AnnotationsPage> {
  late final AnnotationController _annotationController;

  // Annotation visibility toggles
  bool _showPoint = true;
  bool _showRange = true;
  bool _showText = true;
  bool _showThreshold = true;
  bool _showTrend = true;

  // Annotation configuration
  bool _allowDragging = true;
  bool _allowEditing = true;

  // Annotation change tracking
  String _lastChangeMessage = 'No changes yet';
  int _changeCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize AnnotationController with initial annotations
    final initialAnnotations = <ChartAnnotation>[];

    if (_showPoint) {
      initialAnnotations.add(
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
      initialAnnotations.add(
        RangeAnnotation(
          id: 'range-1',
          startY: 85,
          endY: 120,
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
      initialAnnotations.add(
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
      initialAnnotations.addAll([
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
      initialAnnotations.add(
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

    _annotationController = AnnotationController(
      initialAnnotations: initialAnnotations,
    );

    // Listen to annotation changes to show persistence feedback
    _annotationController.addListener(_onAnnotationControllerChanged);
  }

  void _onAnnotationControllerChanged() {
    if (!mounted) return;

    setState(() {
      _changeCount++;

      // Get the most recently modified annotation (if any)
      final annotations = _annotationController.annotations;
      if (annotations.isNotEmpty) {
        final lastAnnotation = annotations.last;
        _lastChangeMessage = 'Updated: ${lastAnnotation.id} (${lastAnnotation.runtimeType})';
      }
    });
  }

  @override
  void dispose() {
    _annotationController.removeListener(_onAnnotationControllerChanged);
    _annotationController.dispose();
    super.dispose();
  }

  void _togglePointAnnotation(bool show) {
    setState(() {
      _showPoint = show;
      if (show) {
        _annotationController.addAnnotation(
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
      } else {
        _annotationController.removeAnnotation('point-1');
      }
    });
  }

  void _toggleRangeAnnotation(bool show) {
    setState(() {
      _showRange = show;
      if (show) {
        _annotationController.addAnnotation(
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
      } else {
        _annotationController.removeAnnotation('range-1');
      }
    });
  }

  void _toggleTextAnnotation(bool show) {
    setState(() {
      _showText = show;
      if (show) {
        _annotationController.addAnnotation(
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
      } else {
        _annotationController.removeAnnotation('text-1');
      }
    });
  }

  void _toggleThresholdAnnotations(bool show) {
    setState(() {
      _showThreshold = show;
      if (show) {
        _annotationController.addAnnotation(
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
        );
        _annotationController.addAnnotation(
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
        );
      } else {
        _annotationController.removeAnnotation('threshold-y');
        _annotationController.removeAnnotation('threshold-x');
      }
    });
  }

  void _toggleTrendAnnotation(bool show) {
    setState(() {
      _showTrend = show;
      if (show) {
        _annotationController.addAnnotation(
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
      } else {
        _annotationController.removeAnnotation('trend-1');
      }
    });
  }

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
        showDataPointMarkers: true,
      ),
    ];

    // Create axis configs
    final xAxis = const AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: true,
      showAxisLine: true,
    );

    final yAxis = const AxisConfig(
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
                      annotationController: _annotationController,
                      xAxis: xAxis,
                      yAxis: yAxis,
                      interactiveAnnotations: _allowDragging || _allowEditing,
                      showLegend: true,
                      backgroundColor: Colors.white,
                      interactionConfig: InteractionConfig.defaultConfig()),
                ),
                const SizedBox(height: 16),
                // Persistence Status Panel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Annotation Persistence Active',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Changes: $_changeCount',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        _lastChangeMessage,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💡 Try dragging annotations - they persist automatically!',
                        style: TextStyle(fontSize: 11, color: Colors.green[800]),
                      ),
                    ],
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
                    onChanged: _togglePointAnnotation,
                  ),
                  BoolOption(
                    label: 'Show Range Annotations',
                    value: _showRange,
                    onChanged: _toggleRangeAnnotation,
                  ),
                  BoolOption(
                    label: 'Show Text Annotations',
                    value: _showText,
                    onChanged: _toggleTextAnnotation,
                  ),
                  BoolOption(
                    label: 'Show Threshold Annotations',
                    value: _showThreshold,
                    onChanged: _toggleThresholdAnnotations,
                  ),
                  BoolOption(
                    label: 'Show Trend Annotations',
                    value: _showTrend,
                    onChanged: _toggleTrendAnnotation,
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
              OptionSection(
                title: 'Current Annotations',
                children: [
                  ..._annotationController.annotations.map((annotation) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _annotationController.selectedAnnotationId == annotation.id ? Colors.blue : Colors.grey[300]!,
                            width: _annotationController.selectedAnnotationId == annotation.id ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _annotationController.selectedAnnotationId == annotation.id ? Icons.check_box : Icons.check_box_outline_blank,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    annotation.id,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getAnnotationDetails(annotation),
                              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_annotationController.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No annotations active',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAnnotationDetails(ChartAnnotation annotation) {
    return switch (annotation) {
      PointAnnotation a => 'Point at index ${a.dataPointIndex}',
      RangeAnnotation a =>
        'Range: X[${a.startX?.toStringAsFixed(1) ?? '∞'}-${a.endX?.toStringAsFixed(1) ?? '∞'}] Y[${a.startY?.toStringAsFixed(1) ?? '∞'}-${a.endY?.toStringAsFixed(1) ?? '∞'}]',
      TextAnnotation a => 'Text at (${a.position.dx.toStringAsFixed(0)}, ${a.position.dy.toStringAsFixed(0)})',
      ThresholdAnnotation a => '${a.axis == AnnotationAxis.x ? 'X' : 'Y'} = ${a.value.toStringAsFixed(1)}',
      TrendAnnotation a => 'Trend: ${a.trendType.name}',
    };
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

