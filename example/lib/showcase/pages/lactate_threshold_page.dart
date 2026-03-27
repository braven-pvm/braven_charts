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
/// - Chord annotation (secant line between two points on the curve)
/// - Threshold marker (vertical line at the deflection point)
/// - Point annotation at the deflection point
class LactateThresholdPage extends StatefulWidget {
  const LactateThresholdPage({super.key});

  @override
  State<LactateThresholdPage> createState() => _LactateThresholdPageState();
}

class _LactateThresholdPageState extends State<LactateThresholdPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final AnnotationController _annotationController = AnnotationController();

  // Chord endpoints (user-adjustable)
  int _chordStartIndex = 1;
  int _chordEndIndex = 14;

  // LT1 detection point
  int _lt1Index = 8;

  // Annotation visibility
  bool _showChord = true;
  bool _showLT1Marker = true;
  bool _showLT1Line = true;
  bool _showDeflectionPoint = true;

  // Styling
  double _chordLineWidth = 2.0;
  double _chordElevation = 0.0;
  bool _chordDashed = true;

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

  /// Generates a realistic lactate curve.
  ///
  /// Lactate stays relatively flat at low intensities then rises
  /// exponentially as exercise intensity increases — the classic
  /// "hockey stick" shape used in threshold testing.
  void _generateLactateData() {
    _lactateData = [];
    // 16 sample points representing increasing exercise intensity stages
    // Each stage is ~3 min, x-axis represents stage number (time)
    final baseLactate = 0.8; // resting lactate mmol/L
    for (int i = 0; i < 16; i++) {
      final t = i.toDouble();
      // Piecewise model: slow linear rise then exponential
      double lactate;
      if (i <= 6) {
        // Aerobic zone: slow, nearly flat rise
        lactate = baseLactate + 0.08 * t + 0.005 * t * t;
      } else if (i <= 10) {
        // Transition zone: moderate rise (LT1 region)
        final offset = t - 6;
        lactate = baseLactate + 0.08 * 6 + 0.005 * 36 + 0.25 * offset + 0.06 * offset * offset;
      } else {
        // Above threshold: steep exponential rise
        final transEnd = baseLactate + 0.08 * 6 + 0.005 * 36 + 0.25 * 4 + 0.06 * 16;
        final offset = t - 10;
        lactate = transEnd + 0.6 * offset + 0.15 * offset * offset;
      }
      _lactateData.add(ChartDataPoint(x: t, y: lactate));
    }
  }

  void _rebuildAnnotations() {
    _annotationController.clearAnnotations();

    if (_showChord) {
      _annotationController.addAnnotation(ChordAnnotation(
        id: 'chord',
        seriesId: 'lactate',
        startIndex: _chordStartIndex,
        endIndex: _chordEndIndex,
        lineColor: const Color(0xFF9E9E9E),
        lineWidth: _chordLineWidth,
        dashPattern: _chordDashed ? [6, 4] : null,
        elevation: _chordElevation,
        perpendicularIndex: _showDeflectionPoint ? _lt1Index : null,
        perpendicularLabel: 'chord',
        perpendicularDashPattern: _chordDashed ? [4, 3] : null,
        perpendicularLineColor: const Color(0xFF9E9E9E),
      ));
    }

    if (_showLT1Line) {
      final lt1X = _lactateData[_lt1Index].x;
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
    }

    if (_showLT1Marker) {
      // Pin at the bottom of the chart at the LT1 x-position
      final lt1X = _lactateData[_lt1Index].x;
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
        title: 'Chord Annotation',
        icon: Icons.trending_up,
        children: [
          BoolOption(
            label: 'Show Chord',
            value: _showChord,
            onChanged: (v) {
              setState(() => _showChord = v);
              _rebuildAnnotations();
            },
            subtitle: 'Secant line between two points',
          ),
          SliderOption(
            label: 'Start Index',
            value: _chordStartIndex.toDouble(),
            min: 0,
            max: maxIndex.toDouble(),
            divisions: maxIndex,
            decimalPlaces: 0,
            onChanged: (v) {
              final idx = v.round();
              if (idx != _chordEndIndex) {
                setState(() => _chordStartIndex = idx);
                _rebuildAnnotations();
              }
            },
          ),
          SliderOption(
            label: 'End Index',
            value: _chordEndIndex.toDouble(),
            min: 0,
            max: maxIndex.toDouble(),
            divisions: maxIndex,
            decimalPlaces: 0,
            onChanged: (v) {
              final idx = v.round();
              if (idx != _chordStartIndex) {
                setState(() => _chordEndIndex = idx);
                _rebuildAnnotations();
              }
            },
          ),
          BoolOption(
            label: 'Dashed',
            value: _chordDashed,
            onChanged: (v) {
              setState(() => _chordDashed = v);
              _rebuildAnnotations();
            },
          ),
          SliderOption(
            label: 'Line Width',
            value: _chordLineWidth,
            min: 0.5,
            max: 6.0,
            divisions: 11,
            suffix: 'px',
            onChanged: (v) {
              setState(() => _chordLineWidth = v);
              _rebuildAnnotations();
            },
          ),
          SliderOption(
            label: 'Glow',
            value: _chordElevation,
            min: 0,
            max: 8.0,
            divisions: 16,
            onChanged: (v) {
              setState(() => _chordElevation = v);
              _rebuildAnnotations();
            },
          ),
        ],
      ),

      OptionSection(
        title: 'LT1 Detection',
        icon: Icons.flag,
        children: [
          SliderOption(
            label: 'LT1 Point',
            value: _lt1Index.toDouble(),
            min: 1,
            max: (maxIndex - 1).toDouble(),
            divisions: maxIndex - 2,
            decimalPlaces: 0,
            onChanged: (v) {
              setState(() => _lt1Index = v.round());
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
            subtitle: 'Green marker at threshold',
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
            label: 'LT1 Pin Marker',
            value: _showLT1Marker,
            onChanged: (v) {
              setState(() => _showLT1Marker = v);
              _rebuildAnnotations();
            },
          ),
        ],
      ),

      const InfoBox(
        message: 'The chord annotation draws a straight line between two '
            'data points on the lactate curve. The deflection point (D) '
            'marks where the curve departs from the chord — indicating '
            'the first lactate threshold (LT1). '
            'Adjust the sliders to explore different chord placements.',
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
          label: 'Chord',
          value: '$_chordStartIndex → $_chordEndIndex',
          color: _showChord ? const Color(0xFF9E9E9E) : Colors.grey,
        ),
        StatusItem(
          label: 'Annotations',
          value: '${_annotationController.length}',
        ),
      ],
    );
  }
}
