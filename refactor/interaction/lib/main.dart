// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Example Application
// Demonstrates proper coordinate space architecture with Data→Plot transformation

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:interaction_prototype/axis/axis.dart' as chart_axis;
import 'package:interaction_prototype/axis/axis_config.dart';
import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/elements/simulated_annotation.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';
import 'package:interaction_prototype/elements/simulated_series.dart';
import 'package:interaction_prototype/transforms/chart_transform.dart';
import 'package:interaction_prototype/widgets/prototype_chart.dart';

void main() {
  runApp(const PrototypeApp());
}

class PrototypeApp extends StatelessWidget {
  const PrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interaction Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PrototypeHomePage(),
    );
  }
}

class PrototypeHomePage extends StatefulWidget {
  const PrototypeHomePage({super.key});

  @override
  State<PrototypeHomePage> createState() => _PrototypeHomePageState();
}

class _PrototypeHomePageState extends State<PrototypeHomePage> {
  String _statusMessage = 'Ready (Shift+Scroll to zoom)';

  // Data ranges (constant - original data coordinates)
  static const dataXMin = 1000.0;
  static const dataXMax = 2000.0;
  static const dataYMin = 50.0;
  static const dataYMax = 150.0;

  // Generate elements based on current transform
  List<ChartElement> _generateElements(ChartTransform transform) {
    final elements = <ChartElement>[];

    // Create multiple series with different patterns (in DATA space)
    // Series 1: Sine wave across the chart
    final series1DataPoints = <Offset>[];
    for (int i = 0; i < 30; i++) {
      final dataX = dataXMin + (i / 29.0) * (dataXMax - dataXMin);
      final dataY = 100.0 + 20.0 * math.sin(i * 0.3); // Oscillate around price 100
      series1DataPoints.add(Offset(dataX, dataY));
    }
    // Convert to PLOT space for rendering
    final series1PlotPoints = transform.dataPointsToPlot(series1DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_1',
      points: series1PlotPoints,
      color: Colors.blue.withOpacity(0.7),
      strokeWidth: 3.0,
    ));

    // Series 2: Diagonal trend line
    final series2DataPoints = <Offset>[];
    for (int i = 0; i < 20; i++) {
      final dataX = dataXMin + (i / 19.0) * (dataXMax - dataXMin);
      final dataY = 60.0 + (i / 19.0) * 60.0; // Linear trend from 60 to 120
      series2DataPoints.add(Offset(dataX, dataY));
    }
    final series2PlotPoints = transform.dataPointsToPlot(series2DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_2',
      points: series2PlotPoints,
      color: Colors.green.withOpacity(0.7),
      strokeWidth: 2.5,
    ));

    // Series 3: Stepped pattern
    final series3DataPoints = <Offset>[];
    for (int i = 0; i < 25; i++) {
      final dataX = dataXMin + 100.0 + (i / 24.0) * 700.0;
      final dataY = 80.0 + (i % 4) * 15.0; // Steps between 80-125
      series3DataPoints.add(Offset(dataX, dataY));
    }
    final series3PlotPoints = transform.dataPointsToPlot(series3DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_3',
      points: series3PlotPoints,
      color: Colors.purple.withOpacity(0.7),
      strokeWidth: 2.0,
    ));

    // Series 4: Bezier curve (to test interpolation performance)
    final series4DataPoints = <Offset>[];
    for (int i = 0; i < 30; i++) {
      final dataX = dataXMin + (i / 29.0) * (dataXMax - dataXMin);
      final dataY = 90.0 + 25.0 * math.cos(i * 0.4); // Cosine wave
      series4DataPoints.add(Offset(dataX, dataY));
    }
    final series4PlotPoints = transform.dataPointsToPlot(series4DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_4_bezier',
      points: series4PlotPoints,
      color: Colors.orange.withOpacity(0.7),
      strokeWidth: 2.5,
      useBezier: true,
      tension: 0.4,
    ));

    // *** ADDED SERIES 5-10 TO TEST PERFORMANCE THRESHOLD ***

    // Series 5: Another sine wave (offset)
    final series5DataPoints = <Offset>[];
    for (int i = 0; i < 28; i++) {
      final dataX = dataXMin + (i / 27.0) * (dataXMax - dataXMin);
      final dataY = 110.0 + 18.0 * math.sin(i * 0.35 + 1.0);
      series5DataPoints.add(Offset(dataX, dataY));
    }
    final series5PlotPoints = transform.dataPointsToPlot(series5DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_5',
      points: series5PlotPoints,
      color: Colors.red.withOpacity(0.7),
      strokeWidth: 2.5,
    ));

    // Series 6: Inverted trend
    final series6DataPoints = <Offset>[];
    for (int i = 0; i < 22; i++) {
      final dataX = dataXMin + (i / 21.0) * (dataXMax - dataXMin);
      final dataY = 130.0 - (i / 21.0) * 50.0; // Downward trend
      series6DataPoints.add(Offset(dataX, dataY));
    }
    final series6PlotPoints = transform.dataPointsToPlot(series6DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_6',
      points: series6PlotPoints,
      color: Colors.teal.withOpacity(0.7),
      strokeWidth: 2.0,
    ));

    // Series 7: Zigzag pattern
    final series7DataPoints = <Offset>[];
    for (int i = 0; i < 26; i++) {
      final dataX = dataXMin + (i / 25.0) * (dataXMax - dataXMin);
      final dataY = 95.0 + (i % 2 == 0 ? 15.0 : -15.0);
      series7DataPoints.add(Offset(dataX, dataY));
    }
    final series7PlotPoints = transform.dataPointsToPlot(series7DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_7',
      points: series7PlotPoints,
      color: Colors.pink.withOpacity(0.7),
      strokeWidth: 2.5,
    ));

    // Series 8: Bezier curve 2
    final series8DataPoints = <Offset>[];
    for (int i = 0; i < 30; i++) {
      final dataX = dataXMin + (i / 29.0) * (dataXMax - dataXMin);
      final dataY = 70.0 + 30.0 * math.sin(i * 0.25);
      series8DataPoints.add(Offset(dataX, dataY));
    }
    final series8PlotPoints = transform.dataPointsToPlot(series8DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_8_bezier',
      points: series8PlotPoints,
      color: Colors.cyan.withOpacity(0.7),
      strokeWidth: 2.0,
      useBezier: true,
      tension: 0.5,
    ));

    // Series 9: Double frequency wave
    final series9DataPoints = <Offset>[];
    for (int i = 0; i < 32; i++) {
      final dataX = dataXMin + (i / 31.0) * (dataXMax - dataXMin);
      final dataY = 105.0 + 12.0 * math.sin(i * 0.6);
      series9DataPoints.add(Offset(dataX, dataY));
    }
    final series9PlotPoints = transform.dataPointsToPlot(series9DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_9',
      points: series9PlotPoints,
      color: Colors.amber.withOpacity(0.7),
      strokeWidth: 2.5,
    ));

    // Series 10: Flat line at top
    final series10DataPoints = <Offset>[];
    for (int i = 0; i < 20; i++) {
      final dataX = dataXMin + (i / 19.0) * (dataXMax - dataXMin);
      final dataY = 135.0 + (i % 5) * 2.0;
      series10DataPoints.add(Offset(dataX, dataY));
    }
    final series10PlotPoints = transform.dataPointsToPlot(series10DataPoints);
    elements.add(SimulatedSeries(
      id: 'series_10',
      points: series10PlotPoints,
      color: Colors.lime.withOpacity(0.7),
      strokeWidth: 2.0,
    ));

    // Create dense clusters of datapoints (in DATA space)
    // Cluster 1: Top-left area (low time, high price)
    for (int i = 0; i < 15; i++) {
      final dataX = 1050.0 + (i % 5) * 30.0 + (i % 3) * 8.0;
      final dataY = 120.0 + (i ~/ 5) * 8.0 + (i % 2) * 3.0;
      final plotCenter = transform.dataToPlot(dataX, dataY);
      elements.add(SimulatedDatapoint(
        id: 'cluster1_$i',
        center: plotCenter,
        radius: 6.0,
        color: Colors.red,
      ));
    }

    // Cluster 2: Middle area (overlapping with series)
    for (int i = 0; i < 20; i++) {
      final dataX = 1400.0 + (i % 5) * 35.0;
      final dataY = 85.0 + (i ~/ 5) * 12.0;
      final plotCenter = transform.dataToPlot(dataX, dataY);
      elements.add(SimulatedDatapoint(
        id: 'cluster2_$i',
        center: plotCenter,
        radius: 7.0,
        color: Colors.orange,
      ));
    }

    // Cluster 3: Bottom-right scattered points (high time, low price)
    for (int i = 0; i < 18; i++) {
      final dataX = 1700.0 + (i % 6) * 40.0;
      final dataY = 65.0 + (i ~/ 6) * 10.0;
      final plotCenter = transform.dataToPlot(dataX, dataY);
      elements.add(SimulatedDatapoint(
        id: 'cluster3_$i',
        center: plotCenter,
        radius: 5.5,
        color: Colors.teal,
      ));
    }

    // Additional scattered points across the entire chart
    for (int i = 0; i < 30; i++) {
      final dataX = 1100.0 + (i % 10) * 80.0 + (i % 7) * 15.0;
      final dataY = 70.0 + (i ~/ 5) * 15.0 + (i % 4) * 5.0;
      final plotCenter = transform.dataToPlot(dataX, dataY);
      elements.add(SimulatedDatapoint(
        id: 'scatter_$i',
        center: plotCenter,
        radius: 6.0,
        color: Colors.blue.shade300,
      ));
    }

    // Create overlapping annotations of various sizes (in DATA space)
    // Annotation 1: Bottom-left (low time, low price)
    final note1DataRect = const Rect.fromLTWH(1050, 55, 180, 15);
    final note1PlotRect = transform.dataRectToPlot(note1DataRect);
    elements.add(SimulatedAnnotation(
      id: 'note_1',
      bounds: note1PlotRect,
      text: 'Low price zone',
      backgroundColor: const Color(0xFFFFF9C4),
      borderColor: const Color(0xFFFBC02D),
    ));

    // Annotation 2: Top-right (high time, high price)
    final note2DataRect = const Rect.fromLTWH(1800, 125, 150, 20);
    final note2PlotRect = transform.dataRectToPlot(note2DataRect);
    elements.add(SimulatedAnnotation(
      id: 'note_2',
      bounds: note2PlotRect,
      text: 'High price zone',
      backgroundColor: const Color(0xFFE1F5FE),
      borderColor: const Color(0xFF0288D1),
    ));

    // Annotation 3: Large center annotation
    final note3DataRect = const Rect.fromLTWH(1400, 110, 200, 30);
    final note3PlotRect = transform.dataRectToPlot(note3DataRect);
    elements.add(SimulatedAnnotation(
      id: 'note_3',
      bounds: note3PlotRect,
      text: 'Major price resistance - overlaps multiple series',
      backgroundColor: const Color(0xFFF3E5F5),
      borderColor: const Color(0xFF8E24AA),
    ));

    // Annotation 4: Overlaps series 1
    final note4DataRect = const Rect.fromLTWH(1200, 95, 140, 15);
    final note4PlotRect = transform.dataRectToPlot(note4DataRect);
    elements.add(SimulatedAnnotation(
      id: 'note_4',
      bounds: note4PlotRect,
      text: 'Trend intersection',
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF43A047),
    ));

    // Annotation 5: Bottom-right zone
    final note5DataRect = const Rect.fromLTWH(1650, 60, 130, 18);
    final note5PlotRect = transform.dataRectToPlot(note5DataRect);
    elements.add(SimulatedAnnotation(
      id: 'note_5',
      bounds: note5PlotRect,
      text: 'Support level',
      backgroundColor: const Color(0xFFFCE4EC),
      borderColor: const Color(0xFFE91E63),
    ));

    // Small annotation overlapping datapoint cluster
    final note6DataRect = const Rect.fromLTWH(1380, 95, 110, 12);
    final note6PlotRect = transform.dataRectToPlot(note6DataRect);
    elements.add(SimulatedAnnotation(
      id: 'note_6',
      bounds: note6PlotRect,
      text: 'Cluster highlight',
      backgroundColor: const Color(0xFFFFF3E0),
      borderColor: const Color(0xFFFB8C00),
    ));

    return elements;
  }

  void _handleElementSelected(ChartElement element) {
    setState(() {
      _statusMessage = 'Selected: ${element.elementType} "${element.id}"';
    });
  }

  void _handleElementDeselected(ChartElement element) {
    setState(() {
      _statusMessage = 'Deselected: ${element.elementType} "${element.id}"';
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _statusMessage = 'Panning: delta=(${details.delta.dx.toStringAsFixed(1)}, ${details.delta.dy.toStringAsFixed(1)})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 0 Interaction Prototype'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Instructions panel
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interaction Controls:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Left-click: Select element'),
                  const Text('• Ctrl+Left-click: Multi-select'),
                  const Text('• Shift+drag empty area: Box select datapoints'),
                  const Text('• Shift+scroll wheel: Zoom (cursor-centered)'),
                  const Text('• +/- keys: Zoom in/out (plot-centered)'),
                  const Text('• Drag annotation: Move annotation'),
                  const Text('• Drag resize handle: Resize annotation (when selected)'),
                  const Text('• Middle-click: Pan (exclusive - blocks other interactions)'),
                  const Text('• Hover: Highlight elements'),
                  const SizedBox(height: 8),
                  Text(
                    'Status: $_statusMessage',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // Chart area
            Container(
              width: 800,
              height: 600,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.white,
              ),
              child: PrototypeChart(
                elementGenerator: _generateElements,
                chartBounds: const Rect.fromLTWH(0, 0, 800, 600),
                xAxis: chart_axis.Axis(
                  config: AxisConfig(
                    orientation: AxisOrientation.horizontal,
                    position: AxisPosition.bottom,
                    label: 'Time Series Index (Shift+Scroll to Zoom)',
                    showGrid: true,
                  ),
                  dataMin: dataXMin,
                  dataMax: dataXMax,
                ),
                yAxis: chart_axis.Axis(
                  config: AxisConfig(
                    orientation: AxisOrientation.vertical,
                    position: AxisPosition.left,
                    label: 'Price Value',
                    showGrid: true,
                  ),
                  dataMin: dataYMin,
                  dataMax: dataYMax,
                ),
                onElementSelected: _handleElementSelected,
                onElementDeselected: _handleElementDeselected,
                onPanUpdate: _handlePanUpdate,
                backgroundColor: Colors.white,
                showDebugInfo: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
