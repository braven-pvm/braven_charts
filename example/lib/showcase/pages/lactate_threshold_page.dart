// Copyright 2025 Braven Charts - Lactate Threshold Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates a lactate threshold detection chart using ChordAnnotation.
///
/// Reproduces the classic LT1 detection pattern:
/// - Lactate curve (exponential rise over time)
/// - "Section" chord (solid line from baseline to LT1 point)
/// - "Ramp" chord (thick dashed line from LT1 to peak)
/// - Linear trend line across the full dataset
/// - Horizontal threshold at the LT1 lactate value
/// - Vertical LT1 marker with deflection point
class LactateThresholdPage extends StatefulWidget {
  const LactateThresholdPage({super.key});

  @override
  State<LactateThresholdPage> createState() => _LactateThresholdPageState();
}

class _LactateThresholdPageState extends State<LactateThresholdPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final AnnotationController _annotationController = AnnotationController();

  // LT1 detection point
  int _lt1Index = 8;

  // Annotation visibility
  bool _showSectionChord = true;
  bool _showRampChord = true;
  bool _showTrendLine = true;
  bool _showHorizontalThreshold = true;
  bool _showBaselineMarker = true;
  bool _showLT1Line = true;
  bool _showDeflectionPoint = true;

  late List<ChartDataPoint> _lactateData;

  @override
  void initState() {
    super.initState();
    _optionsController.showLegend = false;
    _optionsController.showAxisLines = true;
    _optionsController.showGrid = true;
    _generateLactateData();
    _rebuildAnnotations();
  }

  @override
  void dispose() {
    _optionsController.dispose();
    _annotationController.dispose();
    super.dispose();
  }

  /// Generates a realistic lactate curve (hockey stick shape).
  void _generateLactateData() {
    _lactateData = [];
    final baseLactate = 0.8;
    for (int i = 0; i < 16; i++) {
      final t = i.toDouble();
      double lactate;
      if (i <= 6) {
        lactate = baseLactate + 0.08 * t + 0.005 * t * t;
      } else if (i <= 10) {
        final offset = t - 6;
        lactate = baseLactate +
            0.08 * 6 +
            0.005 * 36 +
            0.25 * offset +
            0.06 * offset * offset;
      } else {
        final transEnd =
            baseLactate + 0.08 * 6 + 0.005 * 36 + 0.25 * 4 + 0.06 * 16;
        final offset = t - 10;
        lactate = transEnd + 0.6 * offset + 0.15 * offset * offset;
      }
      _lactateData.add(ChartDataPoint(x: t, y: lactate));
    }
  }

  void _rebuildAnnotations() {
    _annotationController.clearAnnotations();

    final lt1Value = _lactateData[_lt1Index].y;
    final lt1X = _lactateData[_lt1Index].x;

    // --- "Section" chord: baseline to LT1 (solid red/orange) ---
    if (_showSectionChord) {
      _annotationController.addAnnotation(ChordAnnotation(
        id: 'section_chord',
        seriesId: 'lactate',
        startIndex: 1,
        endIndex: _lt1Index,
        label: 'Section',
        style: const AnnotationStyle(
          textStyle: TextStyle(
            color: Color(0xFFE64A19),
            fontSize: 11,
          ),
        ),
        lineColor: const Color(0xFFE64A19),
        lineWidth: 2.5,
        perpendicularIndex: _showDeflectionPoint ? _lt1Index : null,
        perpendicularLabel: 'D',
        perpendicularLabelStyle: const AnnotationStyle(
          textStyle: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        perpendicularLineColor: const Color(0xFFE64A19),
        perpendicularDashPattern: [4, 3],
      ));
    }

    // --- "Ramp" chord: LT1 to peak (thick teal dashed) ---
    if (_showRampChord) {
      _annotationController.addAnnotation(ChordAnnotation(
        id: 'ramp_chord',
        seriesId: 'lactate',
        startIndex: _lt1Index,
        endIndex: 14,
        label: 'Ramp',
        style: const AnnotationStyle(
          textStyle: TextStyle(
            color: Color(0xFF00897B),
            fontSize: 11,
          ),
        ),
        lineColor: const Color(0xFF00897B),
        lineWidth: 4.0,
        dashPattern: [8, 6],
      ));
    }

    // --- Linear trend line across full dataset (cyan dashed) ---
    if (_showTrendLine) {
      _annotationController.addAnnotation(TrendAnnotation(
        id: 'linear_trend',
        seriesId: 'lactate',
        trendType: TrendType.linear,
        label: '',
        lineColor: const Color(0xFF00BCD4),
        lineWidth: 1.5,
        dashPattern: [6, 4],
      ));
    }

    // --- Horizontal threshold at LT1 lactate value ---
    if (_showHorizontalThreshold) {
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'lt1_horizontal',
        axis: AnnotationAxis.y,
        value: lt1Value,
        label: lt1Value.toStringAsFixed(2),
        labelPosition: AnnotationLabelPosition.topLeft,
        lineColor: Colors.grey.shade500,
        lineWidth: 1.0,
      ));
    }

    // --- Baseline vertical marker (dark line at x≈1.4) ---
    if (_showBaselineMarker) {
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'baseline_marker',
        axis: AnnotationAxis.x,
        value: 1.4,
        lineColor: const Color(0xFF333333),
        lineWidth: 1.5,
      ));
    }

    // --- LT1 vertical line (green dashed) ---
    if (_showLT1Line) {
      _annotationController.addAnnotation(ThresholdAnnotation(
        id: 'lt1_line',
        axis: AnnotationAxis.x,
        value: lt1X,
        label: 'LT1',
        labelPosition: AnnotationLabelPosition.bottomRight,
        lineColor: const Color(0xFF4CAF50),
        lineWidth: 2.0,
        dashPattern: [4, 4],
        style: const AnnotationStyle(
          textStyle: TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ));
    }

    // --- Deflection point "D" marker (green circle) ---
    if (_showDeflectionPoint) {
      _annotationController.addAnnotation(PointAnnotation(
        id: 'deflection_point',
        seriesId: 'lactate',
        dataPointIndex: _lt1Index,
        label: 'D',
        markerShape: MarkerShape.circle,
        markerSize: 10.0,
        markerColor: const Color(0xFF4CAF50),
        labelMargin: 8.0,
        style: const AnnotationStyle(
          textStyle: TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ));

      // Green pin at the bottom
      _annotationController.addAnnotation(PinAnnotation(
        id: 'lt1_pin',
        x: lt1X,
        y: _lactateData.first.y - 0.1,
        markerShape: MarkerShape.triangle,
        markerSize: 8.0,
        markerColor: const Color(0xFF4CAF50),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Lactate Threshold',
      subtitle: 'LT1 detection using chord annotation',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    final maxIndex = _lactateData.length - 1;
    return [
      StandardChartOptions(controller: _optionsController),

      OptionSection(
        title: 'LT1 Detection',
        icon: Icons.flag,
        children: [
          SliderOption(
            label: 'LT1 Point',
            value: _lt1Index.toDouble(),
            min: 2,
            max: (maxIndex - 1).toDouble(),
            divisions: maxIndex - 3,
            decimalPlaces: 0,
            onChanged: (v) {
              setState(() => _lt1Index = v.round());
              _rebuildAnnotations();
            },
          ),
        ],
      ),

      OptionSection(
        title: 'Annotations',
        icon: Icons.layers,
        children: [
          BoolOption(
            label: 'Section Chord',
            value: _showSectionChord,
            onChanged: (v) {
              setState(() => _showSectionChord = v);
              _rebuildAnnotations();
            },
            subtitle: 'Baseline to LT1 (solid)',
          ),
          BoolOption(
            label: 'Ramp Chord',
            value: _showRampChord,
            onChanged: (v) {
              setState(() => _showRampChord = v);
              _rebuildAnnotations();
            },
            subtitle: 'LT1 to peak (dashed)',
          ),
          BoolOption(
            label: 'Linear Trend',
            value: _showTrendLine,
            onChanged: (v) {
              setState(() => _showTrendLine = v);
              _rebuildAnnotations();
            },
            subtitle: 'Full dataset regression',
          ),
          BoolOption(
            label: 'LT1 Threshold',
            value: _showHorizontalThreshold,
            onChanged: (v) {
              setState(() => _showHorizontalThreshold = v);
              _rebuildAnnotations();
            },
            subtitle: 'Horizontal line at LT1 value',
          ),
          BoolOption(
            label: 'Baseline Marker',
            value: _showBaselineMarker,
            onChanged: (v) {
              setState(() => _showBaselineMarker = v);
              _rebuildAnnotations();
            },
            subtitle: 'Vertical line at resting sample',
          ),
          BoolOption(
            label: 'LT1 Vertical Line',
            value: _showLT1Line,
            onChanged: (v) {
              setState(() => _showLT1Line = v);
              _rebuildAnnotations();
            },
          ),
          BoolOption(
            label: 'Deflection Point (D)',
            value: _showDeflectionPoint,
            onChanged: (v) {
              setState(() => _showDeflectionPoint = v);
              _rebuildAnnotations();
            },
            subtitle: 'Green marker + perpendicular line',
          ),
        ],
      ),

      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Reset All',
            icon: Icons.restore,
            onPressed: () {
              setState(() {
                _lt1Index = 8;
                _showSectionChord = true;
                _showRampChord = true;
                _showTrendLine = true;
                _showHorizontalThreshold = true;
                _showBaselineMarker = true;
                _showLT1Line = true;
                _showDeflectionPoint = true;
              });
              _rebuildAnnotations();
            },
          ),
        ],
      ),

      const InfoBox(
        message: 'Classic lactate threshold detection chart. '
            'The "Section" chord spans the aerobic baseline. '
            'The "Ramp" chord spans the exponential rise. '
            'Point D marks the maximum deflection from the section '
            'chord — the first lactate threshold (LT1). '
            'The linear trend line shows the overall trajectory.',
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Lactate Threshold Detection',
          subtitle: 'Chord method for LT1 identification',
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'lactate',
                name: 'Lactate',
                points: _lactateData,
                color: const Color(0xFF3F51B5),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2.5,
                showDataPointMarkers: true,
                dataPointMarkerRadius: 3.5,
              ),
            ],
            annotationController: _annotationController,
            theme: _optionsController.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            xAxisConfig: XAxisConfig(
              label: 'Time',
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Lactate',
              unit: 'mmol/L',
              showAxisLine: _optionsController.showAxisLines,
              labelDisplay: AxisLabelDisplay.labelWithUnit,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
            ),
            interactiveAnnotations: true,
            onAnnotationTap: (annotation) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Tapped: ${annotation.label ?? annotation.id}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    final lt1Point = _lactateData[_lt1Index];
    return StatusPanel(
      items: [
        StatusItem(
          label: 'Data Points',
          value: '${_lactateData.length}',
        ),
        StatusItem(
          label: 'LT1 Index',
          value: '$_lt1Index',
          color: const Color(0xFF4CAF50),
        ),
        StatusItem(
          label: 'LT1 Lactate',
          value: '${lt1Point.y.toStringAsFixed(2)} mmol/L',
          color: const Color(0xFF4CAF50),
        ),
        StatusItem(
          label: 'Annotations',
          value: '${_annotationController.length}',
        ),
      ],
    );
  }
}
