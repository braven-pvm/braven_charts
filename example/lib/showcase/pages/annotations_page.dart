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

  // Annotation toggles
  bool _showThresholds = true;
  bool _showRanges = true;
  bool _showTextAnnotations = true;

  // Generated data
  late List<ChartDataPoint> _data;

  @override
  void initState() {
    super.initState();
    _regenerateData();
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
    super.dispose();
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

      // Annotation options
      OptionSection(
        title: 'Annotations',
        icon: Icons.edit_note,
        children: [
          BoolOption(
            label: 'Show Thresholds',
            value: _showThresholds,
            onChanged: (v) => setState(() => _showThresholds = v),
            subtitle: 'Horizontal limit lines',
          ),
          BoolOption(
            label: 'Show Range Highlights',
            value: _showRanges,
            onChanged: (v) => setState(() => _showRanges = v),
            subtitle: 'Highlighted regions',
          ),
          BoolOption(
            label: 'Show Text Labels',
            value: _showTextAnnotations,
            onChanged: (v) => setState(() => _showTextAnnotations = v),
            subtitle: 'Custom text overlays',
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

      // Info
      const InfoBox(
        message: 'Annotations help highlight important values, ranges, '
            'and trends in your data.',
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Annotated Chart',
          subtitle: 'Sine wave with annotations',
          child: BravenChartPlus(
            chartType: ChartType.line,
            lineStyle: LineStyle.smooth,
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
            annotations: _buildAnnotations(),
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
            interactiveAnnotations: true,
          ),
        );
      },
    );
  }

  List<ChartAnnotation> _buildAnnotations() {
    final annotations = <ChartAnnotation>[];

    if (_showThresholds) {
      // Upper threshold
      annotations.add(ThresholdAnnotation(
        axis: AnnotationAxis.y,
        value: 80,
        label: 'Upper Limit',
        labelPosition: AnnotationLabelPosition.topLeft,
        lineColor: Colors.red,
        lineWidth: 2.0,
        dashPattern: [5, 3],
      ));

      // Lower threshold
      annotations.add(ThresholdAnnotation(
        axis: AnnotationAxis.y,
        value: 20,
        label: 'Lower Limit',
        labelPosition: AnnotationLabelPosition.bottomLeft,
        lineColor: Colors.orange,
        lineWidth: 2.0,
        dashPattern: [5, 3],
      ));

      // Target line
      annotations.add(ThresholdAnnotation(
        axis: AnnotationAxis.y,
        value: 50,
        label: 'Target',
        labelPosition: AnnotationLabelPosition.topRight,
        lineColor: Colors.green,
        lineWidth: 1.5,
      ));
    }

    if (_showRanges) {
      // Optimal range
      annotations.add(RangeAnnotation(
        startX: 20,
        endX: 40,
        label: 'Optimal Zone',
        fillColor: Colors.green.withValues(alpha: 0.2),
        borderColor: Colors.green.withValues(alpha: 0.5),
      ));

      // Warning range
      annotations.add(RangeAnnotation(
        startX: 60,
        endX: 80,
        label: 'Caution Zone',
        fillColor: Colors.orange.withValues(alpha: 0.2),
        borderColor: Colors.orange.withValues(alpha: 0.5),
      ));
    }

    if (_showTextAnnotations) {
      // Text at peak
      annotations.add(TextAnnotation(
        text: 'Peak Value',
        position: const Offset(25, 90),
        style: const AnnotationStyle(
          textStyle: TextStyle(
            color: Colors.blue,
            fontSize: 12,
          ),
          backgroundColor: Colors.white,
        ),
      ));
    }

    return annotations;
  }

  Widget _buildStatusPanel() {
    int annotationCount = 0;
    if (_showThresholds) annotationCount += 3;
    if (_showRanges) annotationCount += 2;
    if (_showTextAnnotations) annotationCount += 1;

    return StatusPanel(
      items: [
        StatusItem(
          label: 'Data Points',
          value: '${_data.length}',
        ),
        StatusItem(
          label: 'Annotations',
          value: '$annotationCount',
        ),
        StatusItem(
          label: 'Thresholds',
          value: _showThresholds ? 'On' : 'Off',
        ),
        StatusItem(
          label: 'Ranges',
          value: _showRanges ? 'On' : 'Off',
        ),
      ],
    );
  }
}
