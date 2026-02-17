// Copyright 2025 Braven Charts - Annotations Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates chart annotation features:
/// - Threshold annotations (horizontal/vertical lines)
/// - Range annotations (highlighted regions)
/// - Point annotations (markers on specific points)
/// - Text annotations (custom text overlays)
/// - Trend annotations (trend lines)
class AnnotationsPage extends StatefulWidget {
  const AnnotationsPage({super.key});

  @override
  State<AnnotationsPage> createState() => _AnnotationsPageState();
}

class _AnnotationsPageState extends State<AnnotationsPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Annotation controller for reactive, editable annotations
  final AnnotationController _annotationController = AnnotationController();

  // Annotation visibility toggles
  bool _showThresholds = true;
  bool _showRanges = true;
  bool _showTextAnnotations = true;

  // Annotation interaction settings
  bool _interactiveAnnotations = true;
  bool _allowDragging = true;
  bool _allowEditing = true;
  bool _snapToValue = false;

  // Generated data
  late List<ChartDataPoint> _data;

  @override
  void initState() {
    super.initState();
    _regenerateData();
    _rebuildAnnotations();
  }

  void _regenerateData() {
    setState(() {
      _data = DataGenerator.generateSineWave(
        count: 100,
        amplitude: 40,
        yOffset: 50,
        frequency: 0.1,
      );
    });
  }

  @override
  void dispose() {
    _optionsController.dispose();
    _annotationController.dispose();
    super.dispose();
  }

  /// Rebuilds annotations based on current toggle states and settings.
  void _rebuildAnnotations() {
    _annotationController.clearAnnotations();

    if (_showThresholds) {
      // Upper threshold
      _annotationController.addAnnotation(
        ThresholdAnnotation(
          id: 'upper_limit',
          axis: AnnotationAxis.y,
          value: 80,
          label: 'Upper Limit',
          labelPosition: AnnotationLabelPosition.topLeft,
          lineColor: Colors.red,
          lineWidth: 2.0,
          dashPattern: [5, 3],
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );

      // Lower threshold
      _annotationController.addAnnotation(
        ThresholdAnnotation(
          id: 'lower_limit',
          axis: AnnotationAxis.y,
          value: 20,
          label: 'Lower Limit',
          labelPosition: AnnotationLabelPosition.bottomLeft,
          lineColor: Colors.orange,
          lineWidth: 2.0,
          dashPattern: [5, 3],
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );

      // Target line
      _annotationController.addAnnotation(
        ThresholdAnnotation(
          id: 'target',
          axis: AnnotationAxis.y,
          value: 50,
          label: 'Target',
          labelPosition: AnnotationLabelPosition.topRight,
          lineColor: Colors.green,
          lineWidth: 1.5,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );

      // vertical line
      _annotationController.addAnnotation(
        ThresholdAnnotation(
          id: 'lt1',
          axis: AnnotationAxis.x,
          value: 95,
          label: 'LT1',
          labelPosition: AnnotationLabelPosition.topRight,
          lineColor: Colors.deepOrange,
          lineWidth: 3,
          style: const AnnotationStyle(padding: EdgeInsets.all(0)),
          dashPattern: [4, 4],
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );
    }

    if (_showRanges) {
      // Optimal range
      _annotationController.addAnnotation(
        RangeAnnotation(
          id: 'optimal_zone',
          startX: 20,
          endX: 40,
          label: 'Optimal Zone',
          fillColor: Colors.green.withValues(alpha: 0.2),
          borderColor: Colors.green.withValues(alpha: 0.5),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          snapToValue: _snapToValue,
        ),
      );

      // Warning range
      _annotationController.addAnnotation(
        RangeAnnotation(
          id: 'caution_zone',
          startX: 60,
          endX: 80,
          label: 'Caution Zone',
          fillColor: Colors.orange.withValues(alpha: 0.2),
          borderColor: Colors.orange.withValues(alpha: 0.5),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          snapToValue: _snapToValue,
        ),
      );
    }

    if (_showTextAnnotations) {
      // Text at peak (plain text)
      _annotationController.addAnnotation(
        TextAnnotation(
          id: 'peak_text',
          text: 'Peak Value',
          position: const Offset(25, 90),
          style: AnnotationStyle(
            textStyle: const TextStyle(color: Colors.blue, fontSize: 12),
            backgroundColor: Colors.grey.shade100.withValues(alpha: 0.8),
            borderColor: Colors.grey.shade400,
            borderWidth: 0.5,
            padding: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(5),
          ),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );

      // Rich text annotation with formatting
      // Note: Uses Fleather's standard attributes (b, i, u, s)
      _annotationController.addAnnotation(
        TextAnnotation.rich(
          id: 'rich_text_note',
          richTextDelta: [
            {
              'insert': 'Important: ',
              'attributes': {'b': true},
            },
            {'insert': 'This zone shows '},
            {
              'insert': 'critical',
              'attributes': {'i': true, 'u': true},
            },
            {'insert': ' data!\n'},
          ],
          position: const Offset(70, 30),
          style: AnnotationStyle(
            textStyle: const TextStyle(color: Colors.black87, fontSize: 12),
            backgroundColor: Colors.amber.shade50,
            borderColor: Colors.amber.shade700,
            borderWidth: 1.0,
            padding: const EdgeInsets.all(10),
            borderRadius: BorderRadius.circular(6),
          ),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Annotations',
      subtitle: 'Add visual markers and highlights to charts',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Annotation visibility options
      OptionSection(
        title: 'Annotation Types',
        icon: Icons.layers,
        children: [
          BoolOption(
            label: 'Show Thresholds',
            value: _showThresholds,
            onChanged: (v) {
              setState(() => _showThresholds = v);
              _rebuildAnnotations();
            },
            subtitle: 'Horizontal limit lines',
          ),
          BoolOption(
            label: 'Show Range Highlights',
            value: _showRanges,
            onChanged: (v) {
              setState(() => _showRanges = v);
              _rebuildAnnotations();
            },
            subtitle: 'Highlighted regions',
          ),
          BoolOption(
            label: 'Show Text Labels',
            value: _showTextAnnotations,
            onChanged: (v) {
              setState(() => _showTextAnnotations = v);
              _rebuildAnnotations();
            },
            subtitle: 'Custom text overlays',
          ),
        ],
      ),

      // Annotation interaction settings
      OptionSection(
        title: 'Annotation Behavior',
        icon: Icons.touch_app,
        children: [
          BoolOption(
            label: 'Interactive Annotations',
            value: _interactiveAnnotations,
            onChanged: (v) => setState(() => _interactiveAnnotations = v),
            subtitle: 'Enable all annotation interactions',
          ),
          BoolOption(
            label: 'Allow Dragging',
            value: _allowDragging,
            onChanged: (v) {
              setState(() => _allowDragging = v);
              _rebuildAnnotations();
            },
            subtitle: 'Drag to reposition annotations',
          ),
          BoolOption(
            label: 'Allow Editing',
            value: _allowEditing,
            onChanged: (v) {
              setState(() => _allowEditing = v);
              _rebuildAnnotations();
            },
            subtitle: 'Double-click to edit properties',
          ),
          BoolOption(
            label: 'Snap to Value',
            value: _snapToValue,
            onChanged: (v) {
              setState(() => _snapToValue = v);
              _rebuildAnnotations();
            },
            subtitle: 'Ranges snap to data values',
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
          ActionButton(
            label: 'Clear All Annotations',
            icon: Icons.clear_all,
            onPressed: () {
              _annotationController.clearAnnotations();
              setState(() {
                _showThresholds = false;
                _showRanges = false;
                _showTextAnnotations = false;
              });
            },
          ),
          ActionButton(
            label: 'Reset Annotations',
            icon: Icons.restore,
            onPressed: () {
              setState(() {
                _showThresholds = true;
                _showRanges = true;
                _showTextAnnotations = true;
              });
              _rebuildAnnotations();
            },
          ),
        ],
      ),

      // Info
      const InfoBox(
        message:
            'Annotations help highlight important values, ranges, '
            'and trends in your data. Enable dragging and editing to '
            'interactively modify annotations.',
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Annotated Chart',
          subtitle: 'Sine wave with interactive annotations',
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'sine',
                name: 'Sine Wave',
                points: _data,
                color: Colors.blue,
                interpolation: LineInterpolation.bezier,
                strokeWidth: 2.0,
                showDataPointMarkers: _optionsController.showDataMarkers,
              ),
            ],
            annotationController: _annotationController,
            theme: _optionsController.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
              autoHide: false,
            ),
            xAxisConfig: XAxisConfig(
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              showAxisLine: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
            ),
            interactiveAnnotations: _interactiveAnnotations,
            onAnnotationTap: (annotation) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped: ${annotation.label ?? annotation.id}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            onAnnotationDragged: (annotation, newPosition) {
              // The controller automatically updates the annotation
              // This callback is for additional handling if needed
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    return ListenableBuilder(
      listenable: _annotationController,
      builder: (context, _) {
        return StatusPanel(
          items: [
            StatusItem(label: 'Data Points', value: '${_data.length}'),
            StatusItem(
              label: 'Annotations',
              value: '${_annotationController.length}',
            ),
            StatusItem(
              label: 'Interactive',
              value: _interactiveAnnotations ? 'On' : 'Off',
              color: _interactiveAnnotations ? Colors.green : Colors.grey,
            ),
            StatusItem(
              label: 'Draggable',
              value: _allowDragging ? 'On' : 'Off',
              color: _allowDragging ? Colors.blue : Colors.grey,
            ),
            StatusItem(
              label: 'Editable',
              value: _allowEditing ? 'On' : 'Off',
              color: _allowEditing ? Colors.orange : Colors.grey,
            ),
          ],
        );
      },
    );
  }
}
