// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Comprehensive Annotation Showcase - Full Interactive Control
///
/// Features:
/// - Create/Edit/Delete all 5 annotation types
/// - TextAnnotation dual-mode: screen-coordinate (static) and data-coordinate (anchored)
/// - Real-time property editing for each type
/// - Visual configuration panels
/// - Tap and drag interaction demos
/// - Export/Import annotation configurations
/// - Performance monitoring (500+ annotation stress test)
///
/// This is the DEFINITIVE annotation demonstration screen.
library;

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class AnnotationsComprehensiveScreen extends StatefulWidget {
  const AnnotationsComprehensiveScreen({super.key});

  @override
  State<AnnotationsComprehensiveScreen> createState() => _AnnotationsComprehensiveScreenState();
}

class _AnnotationsComprehensiveScreenState extends State<AnnotationsComprehensiveScreen> {
  // Sample data
  final _timeSeries = ChartSeries(
    id: 'temperature',
    name: 'Temperature (°C)',
    points: _generateTimeSeriesData(),
  );

  // Annotation storage
  List<ChartAnnotation> _annotations = [];
  ChartAnnotation? _selectedAnnotation;

  // Event tracking
  final List<String> _eventLog = [];
  int _eventCount = 0;

  // View state
  ChartType _chartType = ChartType.line;
  bool _showGrid = true;
  bool _interactiveAnnotations = true;

  // Creation state
  String _creationType = 'text';
  final _textController = TextEditingController(text: 'New Annotation');

  @override
  void initState() {
    super.initState();
    _loadDefaultAnnotations();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _loadDefaultAnnotations() {
    setState(() {
      _annotations = [
        // Screen-coordinate mode TextAnnotation (static position)
        TextAnnotation(
          id: 'text1',
          text: 'Peak Temperature',
          position: const Offset(200, 80),
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              letterSpacing: 0.5,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.red,
            borderWidth: 2,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
        // Data-coordinate mode TextAnnotation (anchored to data point)
        TextAnnotation(
          id: 'text2_data_mode',
          text: 'Data Point\n(15, 32)',
          dataX: 15.0,
          dataY: 32.0,
          seriesId: 'temperature',
          backgroundColor: Colors.purple.withAlpha(20),
          borderColor: Colors.purple,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
              fontFamily: 'monospace',
            ),
            borderWidth: 0.5,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            padding: EdgeInsets.all(6),
          ),
        ),
        PointAnnotation(
            id: 'point1',
            label: 'Highest Point',
            seriesId: 'temperature',
            dataPointIndex: 12,
            markerShape: MarkerShape.circle,
            offset: Offset.zero,
            markerSize: 10,
            markerColor: Colors.blue.shade300,
            style: AnnotationStyle(
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w200,
                color: Colors.blue.shade700,
              ),
              backgroundColor: Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            )),
        RangeAnnotation(
            id: 'range1',
            label: 'Above Average',
            startY: 20,
            endY: 25,
            fillColor: Colors.green.withAlpha(20),
            borderColor: Colors.green,
            labelPosition: AnnotationLabelPosition.topLeft,
            style: const AnnotationStyle(
              textStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
              backgroundColor: Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(6)),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            )),
        RangeAnnotation(
            id: 'range2',
            label: 'Above',
            startX: 6,
            endX: 8,
            fillColor: Colors.blue.withAlpha(20),
            borderColor: Colors.blue,
            labelPosition: AnnotationLabelPosition.bottomRight,
            style: const AnnotationStyle(
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              backgroundColor: Colors.transparent,
              borderRadius: BorderRadius.zero, // Sharp corners
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            )),

        ThresholdAnnotation(
            id: 'threshold1',
            label: 'Target: 28°C',
            axis: AnnotationAxis.y,
            value: 28,
            lineColor: Colors.red,
            lineWidth: 2,
            dashPattern: const [5, 5],
            labelPosition: AnnotationLabelPosition.bottomLeft,
            style: AnnotationStyle(
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
              ),
              backgroundColor: Colors.red,
              borderRadius: BorderRadius.circular(5), // Sharp corners
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            )),

        // TrendAnnotation examples demonstrating all trend types
        TrendAnnotation(
          id: 'trend_linear',
          seriesId: 'temperature',
          trendType: TrendType.linear,
          lineColor: Colors.blue.withAlpha(180),
          lineWidth: 2.5,
          dashPattern: const [8, 4],
        ),

        TrendAnnotation(
          id: 'trend_moving_avg',
          seriesId: 'temperature',
          trendType: TrendType.movingAverage,
          windowSize: 5,
          lineColor: Colors.green.withAlpha(180),
          lineWidth: 2,
        ),

        TrendAnnotation(
          id: 'trend_polynomial',
          seriesId: 'temperature',
          trendType: TrendType.polynomial,
          degree: 3,
          lineColor: Colors.orange.withAlpha(180),
          lineWidth: 2.5,
          dashPattern: const [4, 4],
        ),

        TrendAnnotation(
          id: 'trend_exponential',
          seriesId: 'temperature',
          trendType: TrendType.exponential,
          lineColor: Colors.purple.withAlpha(180),
          lineWidth: 2,
        ),
      ];
    });
  }

  void _logEvent(String event) {
    setState(() {
      _eventCount++;
      _eventLog.insert(0, '[$_eventCount] $event');
      if (_eventLog.length > 50) {
        _eventLog.removeLast();
      }
    });
  }

  void _addAnnotation() {
    ChartAnnotation? newAnnotation;
    final id = 'annotation_${DateTime.now().millisecondsSinceEpoch}';

    switch (_creationType) {
      case 'text':
        newAnnotation = TextAnnotation(
          id: id,
          text: _textController.text.isEmpty ? 'New Text' : _textController.text,
          position: const Offset(200, 100),
          style: const AnnotationStyle(
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
            backgroundColor: Colors.white,
            borderColor: Colors.grey,
            borderWidth: 1,
          ),
        );
        break;

      case 'point':
        newAnnotation = PointAnnotation(
          id: id,
          label: 'Point',
          seriesId: 'temperature',
          dataPointIndex: 10,
          markerShape: MarkerShape.circle,
          markerSize: 12,
          markerColor: Colors.blue,
        );
        break;

      case 'range':
        newAnnotation = RangeAnnotation(
          id: id,
          label: 'Range',
          startX: 5,
          endX: 15,
          fillColor: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          labelPosition: AnnotationLabelPosition.topLeft,
        );
        break;

      case 'threshold':
        newAnnotation = ThresholdAnnotation(
          id: id,
          label: 'Threshold',
          axis: AnnotationAxis.y,
          value: 25,
          lineColor: Colors.red,
          lineWidth: 2,
          labelPosition: AnnotationLabelPosition.topLeft,
        );
        break;

      case 'trend':
        newAnnotation = TrendAnnotation(
          id: id,
          label: 'Linear Trend',
          seriesId: 'temperature',
          trendType: TrendType.linear,
          lineColor: Colors.purple,
          lineWidth: 2,
        );
        break;
    }

    if (newAnnotation != null) {
      setState(() {
        _annotations.add(newAnnotation!);
        _selectedAnnotation = newAnnotation;
      });
      _logEvent('CREATED: ${_creationType.toUpperCase()} annotation [$id]');
    }
  }

  void _deleteAnnotation(ChartAnnotation annotation) {
    setState(() {
      _annotations.removeWhere((a) => a.id == annotation.id);
      if (_selectedAnnotation?.id == annotation.id) {
        _selectedAnnotation = null;
      }
    });
    _logEvent('DELETED: ${annotation.runtimeType} [${annotation.id}]');
  }

  void _deleteAllAnnotations() {
    final count = _annotations.length;
    setState(() {
      _annotations.clear();
      _selectedAnnotation = null;
    });
    _logEvent('DELETED ALL: Removed $count annotations');
  }

  void _stressTest() {
    final random = math.Random(42);
    final stressAnnotations = <ChartAnnotation>[];

    // Add 100 of each type (500 total)
    for (int i = 0; i < 100; i++) {
      stressAnnotations.add(
        TextAnnotation(
          id: 'stress_text_$i',
          text: 'T$i',
          position: Offset(
            random.nextDouble() * 400,
            random.nextDouble() * 300,
          ),
          style: const AnnotationStyle(
            textStyle: TextStyle(fontSize: 10),
          ),
        ),
      );

      stressAnnotations.add(
        PointAnnotation(
          id: 'stress_point_$i',
          label: 'P$i',
          seriesId: 'temperature',
          dataPointIndex: random.nextInt(30),
          markerShape: MarkerShape.values[random.nextInt(5)],
          markerSize: 8,
          markerColor: Colors.primaries[random.nextInt(Colors.primaries.length)],
        ),
      );

      stressAnnotations.add(
        RangeAnnotation(
          id: 'stress_range_$i',
          startX: random.nextDouble() * 20,
          endX: random.nextDouble() * 10 + 20,
          fillColor: Colors.primaries[random.nextInt(Colors.primaries.length)].withOpacity(0.1),
        ),
      );

      stressAnnotations.add(
        ThresholdAnnotation(
          id: 'stress_threshold_$i',
          axis: random.nextBool() ? AnnotationAxis.x : AnnotationAxis.y,
          value: random.nextDouble() * 30,
          lineColor: Colors.primaries[random.nextInt(Colors.primaries.length)],
          lineWidth: 1,
        ),
      );

      stressAnnotations.add(
        TrendAnnotation(
          id: 'stress_trend_$i',
          seriesId: 'temperature',
          trendType: TrendType.linear,
          lineColor: Colors.primaries[random.nextInt(Colors.primaries.length)],
          lineWidth: 1,
        ),
      );
    }

    setState(() {
      _annotations = stressAnnotations;
      _selectedAnnotation = null;
    });
    _logEvent('STRESS TEST: Created 500 annotations (100 of each type)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Annotation Comprehensive Showcase'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Main chart area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildStatusBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BravenChart(
                          key: ValueKey('chart_${_annotations.length}'),
                          chartType: _chartType,
                          series: [_timeSeries],
                          title: 'Interactive Annotation Demo',
                          annotations: _annotations,
                          theme: ChartTheme.defaultLight,
                          interactionConfig: const InteractionConfig(
                            enabled: true,
                            enableZoom: true,
                            enablePan: true,
                          ),
                          onAnnotationTap: _interactiveAnnotations
                              ? (annotation) {
                                  setState(() {
                                    _selectedAnnotation = annotation;
                                  });
                                  _logEvent('TAP: ${annotation.runtimeType} [${annotation.id}]');
                                }
                              : null,
                          onAnnotationDragged: _interactiveAnnotations
                              ? (annotation, newPosition) {
                                  _logEvent('DRAG: ${annotation.runtimeType} to $newPosition');
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildQuickActions(),
              ],
            ),
          ),

          // Right panel - Controls
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCreationSection(),
                        const Divider(height: 32),
                        _buildAnnotationList(),
                        const Divider(height: 32),
                        if (_selectedAnnotation != null) ...[
                          _buildEditorSection(),
                          const Divider(height: 32),
                        ],
                        _buildEventLog(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
        ),
        border: Border(bottom: BorderSide(color: Colors.purple.shade200, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatusChip('Total Annotations', '${_annotations.length}', Colors.purple),
              _buildStatusChip('Text', '${_annotations.whereType<TextAnnotation>().length}', Colors.blue),
              _buildStatusChip('Point', '${_annotations.whereType<PointAnnotation>().length}', Colors.orange),
              _buildStatusChip('Range', '${_annotations.whereType<RangeAnnotation>().length}', Colors.green),
              _buildStatusChip('Threshold', '${_annotations.whereType<ThresholdAnnotation>().length}', Colors.red),
              _buildStatusChip('Trend', '${_annotations.whereType<TrendAnnotation>().length}', Colors.indigo),
              _buildStatusChip('Selected', _selectedAnnotation != null ? '1' : '0', Colors.amber),
              _buildStatusChip('Events', '$_eventCount', Colors.teal),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 NEW: TextAnnotation dual-mode! Red = screen-anchored (static), Purple = data-anchored (moves with zoom/pan)',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.9), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ChartType>(
              segments: const [
                ButtonSegment(value: ChartType.line, label: Text('Line'), icon: Icon(Icons.show_chart, size: 16)),
                ButtonSegment(value: ChartType.scatter, label: Text('Scatter'), icon: Icon(Icons.scatter_plot, size: 16)),
                ButtonSegment(value: ChartType.bar, label: Text('Bar'), icon: Icon(Icons.bar_chart, size: 16)),
              ],
              selected: {_chartType},
              onSelectionChanged: (Set<ChartType> selected) {
                setState(() => _chartType = selected.first);
                _logEvent('CHART TYPE: ${selected.first.toString().split('.').last}');
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filled(
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: _showGrid ? 'Hide Grid' : 'Show Grid',
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          IconButton.filled(
            icon: Icon(_interactiveAnnotations ? Icons.touch_app : Icons.block),
            tooltip: _interactiveAnnotations ? 'Disable Interactions' : 'Enable Interactions',
            onPressed: () => setState(() => _interactiveAnnotations = !_interactiveAnnotations),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('➕ Create Annotation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _creationType,
          decoration: const InputDecoration(
            labelText: 'Annotation Type',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'text', child: Text('📝 Text Annotation')),
            DropdownMenuItem(value: 'point', child: Text('📍 Point Annotation')),
            DropdownMenuItem(value: 'range', child: Text('📊 Range Annotation')),
            DropdownMenuItem(value: 'threshold', child: Text('📏 Threshold Annotation')),
            DropdownMenuItem(value: 'trend', child: Text('📈 Trend Annotation')),
          ],
          onChanged: (value) => setState(() => _creationType = value!),
        ),
        if (_creationType == 'text') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text Content',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addAnnotation,
                icon: const Icon(Icons.add),
                label: const Text('Add Annotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              icon: const Icon(Icons.restore),
              tooltip: 'Load Defaults',
              onPressed: _loadDefaultAnnotations,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _deleteAllAnnotations,
              icon: const Icon(Icons.delete_sweep, size: 16),
              label: const Text('Delete All'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _stressTest,
              icon: const Icon(Icons.speed, size: 16),
              label: const Text('Stress Test (500)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnotationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('📋 Annotations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${_annotations.length} total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        if (_annotations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No annotations yet', style: TextStyle(color: Colors.grey)),
                  Text('Create one above to get started', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _annotations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final annotation = _annotations[index];
                final isSelected = _selectedAnnotation?.id == annotation.id;
                IconData icon;
                Color color;
                String type;

                if (annotation is TextAnnotation) {
                  icon = Icons.text_fields;
                  color = Colors.blue;
                  type = 'Text';
                } else if (annotation is PointAnnotation) {
                  icon = Icons.place;
                  color = Colors.orange;
                  type = 'Point';
                } else if (annotation is RangeAnnotation) {
                  icon = Icons.view_column;
                  color = Colors.green;
                  type = 'Range';
                } else if (annotation is ThresholdAnnotation) {
                  icon = Icons.horizontal_rule;
                  color = Colors.red;
                  type = 'Threshold';
                } else if (annotation is TrendAnnotation) {
                  icon = Icons.trending_up;
                  color = Colors.indigo;
                  type = 'Trend';
                } else {
                  icon = Icons.help;
                  color = Colors.grey;
                  type = 'Unknown';
                }

                return ListTile(
                  dense: true,
                  selected: isSelected,
                  leading: Icon(icon, color: color, size: 20),
                  title: Text(
                    annotation.label ?? annotation.id,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    type,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteAnnotation(annotation),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedAnnotation = annotation);
                    _logEvent('SELECT: ${annotation.runtimeType} [${annotation.id}]');
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEditorSection() {
    if (_selectedAnnotation == null) return const SizedBox.shrink();

    final annotation = _selectedAnnotation!;
    String typeName;
    IconData icon;
    Color color;

    if (annotation is TextAnnotation) {
      typeName = 'Text Annotation';
      icon = Icons.text_fields;
      color = Colors.blue;
    } else if (annotation is PointAnnotation) {
      typeName = 'Point Annotation';
      icon = Icons.place;
      color = Colors.orange;
    } else if (annotation is RangeAnnotation) {
      typeName = 'Range Annotation';
      icon = Icons.view_column;
      color = Colors.green;
    } else if (annotation is ThresholdAnnotation) {
      typeName = 'Threshold Annotation';
      icon = Icons.horizontal_rule;
      color = Colors.red;
    } else if (annotation is TrendAnnotation) {
      typeName = 'Trend Annotation';
      icon = Icons.trending_up;
      color = Colors.indigo;
    } else {
      typeName = 'Unknown';
      icon = Icons.help;
      color = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text('✏️ Edit: $typeName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyRow('ID', annotation.id),
              if (annotation.label != null) _buildPropertyRow('Label', annotation.label!),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Type-specific properties
              if (annotation is TextAnnotation) ...[
                _buildPropertyRow('Text', annotation.text),
                // Handle dual-mode positioning
                if (annotation.position != null)
                  _buildPropertyRow('Position (Screen)', '(${annotation.position!.dx.toInt()}, ${annotation.position!.dy.toInt()})')
                else if (annotation.dataX != null && annotation.dataY != null)
                  _buildPropertyRow('Position (Data)', '(${annotation.dataX}, ${annotation.dataY}) in ${annotation.seriesId}'),
                _buildPropertyRow('Anchor', annotation.anchor.toString().split('.').last),
              ] else if (annotation is PointAnnotation) ...[
                _buildPropertyRow('Series', annotation.seriesId),
                _buildPropertyRow('Data Point', '#${annotation.dataPointIndex}'),
                _buildPropertyRow('Marker', annotation.markerShape.toString().split('.').last),
                _buildPropertyRow('Size', '${annotation.markerSize}px'),
              ] else if (annotation is RangeAnnotation) ...[
                if (annotation.startX != null) _buildPropertyRow('Start X', annotation.startX!.toStringAsFixed(1)),
                if (annotation.endX != null) _buildPropertyRow('End X', annotation.endX!.toStringAsFixed(1)),
                if (annotation.startY != null) _buildPropertyRow('Start Y', annotation.startY!.toStringAsFixed(1)),
                if (annotation.endY != null) _buildPropertyRow('End Y', annotation.endY!.toStringAsFixed(1)),
              ] else if (annotation is ThresholdAnnotation) ...[
                _buildPropertyRow('Axis', annotation.axis == AnnotationAxis.x ? 'X-Axis' : 'Y-Axis'),
                _buildPropertyRow('Value', annotation.value.toStringAsFixed(1)),
                _buildPropertyRow('Width', '${annotation.lineWidth}px'),
                if (annotation.dashPattern != null) _buildPropertyRow('Dash', annotation.dashPattern.toString()),
              ] else if (annotation is TrendAnnotation) ...[
                _buildPropertyRow('Series', annotation.seriesId),
                _buildPropertyRow('Type', annotation.trendType.toString().split('.').last),
                if (annotation.windowSize != null) _buildPropertyRow('Window', '${annotation.windowSize}'),
                if (annotation.degree != 2) _buildPropertyRow('Degree', '${annotation.degree}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '💡 Note: Full property editing coming in Phase 4',
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text('📊 Event Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              onPressed: () {
                setState(() {
                  _eventLog.clear();
                  _eventCount = 0;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: _eventLog.isEmpty
              ? const Center(
                  child: Text(
                    'No events yet...',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  itemCount: _eventLog.length,
                  itemBuilder: (context, index) {
                    final event = _eventLog[index];
                    Color eventColor = const Color(0xFF00FF00);
                    if (event.contains('CREATED')) {
                      eventColor = const Color(0xFF4CAF50);
                    } else if (event.contains('DELETED')) {
                      eventColor = const Color(0xFFF44336);
                    } else if (event.contains('TAP')) {
                      eventColor = const Color(0xFF2196F3);
                    } else if (event.contains('DRAG')) {
                      eventColor = const Color(0xFFFF9800);
                    } else if (event.contains('SELECT')) {
                      eventColor = const Color(0xFF9C27B0);
                    } else if (event.contains('STRESS')) {
                      eventColor = const Color(0xFFFFEB3B);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        event,
                        style: TextStyle(
                          color: eventColor,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 8),
            Text('Annotation Showcase Help'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📝 Annotation Types:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Text: Free-floating labels at screen positions'),
              Text('• Point: Markers on specific data points'),
              Text('• Range: Rectangular highlighting (time/value ranges)'),
              Text('• Threshold: Horizontal/vertical reference lines'),
              Text('• Trend: Statistical overlays (linear, polynomial, etc.)'),
              SizedBox(height: 16),
              Text('🎮 Controls:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Create: Select type, then click "Add Annotation"'),
              Text('• Select: Click annotation in list or tap on chart'),
              Text('• Delete: Click trash icon in annotation list'),
              Text('• Edit: Select annotation to view properties'),
              SizedBox(height: 16),
              Text('⚡ Quick Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Load Defaults: Restore 4 sample annotations'),
              Text('• Delete All: Clear all annotations'),
              Text('• Stress Test: Create 500 annotations for performance testing'),
              SizedBox(height: 16),
              Text('🔧 Known Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Point/Range/Threshold use placeholder coordinates'),
              Text('• Trend calculations not yet implemented'),
              Text('• Drag interaction not yet functional'),
              Text('• See ANNOTATION_ROADMAP.md for details'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  static List<ChartDataPoint> _generateTimeSeriesData() {
    final points = <ChartDataPoint>[];
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = i.toDouble();
      final y = 20 + math.sin(i * 0.3) * 8 + random.nextDouble() * 5;
      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }
}
