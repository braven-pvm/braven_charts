// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Example Application

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/elements/simulated_annotation.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';
import 'package:interaction_prototype/elements/simulated_series.dart';
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
  late List<ChartElement> _elements;
  String _statusMessage = 'Ready';

  @override
  void initState() {
    super.initState();
    _elements = _createDemoElements();
  }

  List<ChartElement> _createDemoElements() {
    final elements = <ChartElement>[];

    // Create multiple series with different patterns
    // Series 1: Sine wave across the chart
    final series1Points = <Offset>[];
    for (int i = 0; i < 30; i++) {
      final x = 50 + i * 40.0;
      final y = 400 + 80 * math.sin(i * 0.3);
      series1Points.add(Offset(x, y));
    }
    elements.add(SimulatedSeries(
      id: 'series_1',
      points: series1Points,
      color: Colors.blue.withOpacity(0.7),
      strokeWidth: 3.0,
    ));

    // Series 2: Diagonal line
    final series2Points = <Offset>[];
    for (int i = 0; i < 20; i++) {
      series2Points.add(Offset(80 + i * 60.0, 150 + i * 30.0));
    }
    elements.add(SimulatedSeries(
      id: 'series_2',
      points: series2Points,
      color: Colors.green.withOpacity(0.7),
      strokeWidth: 2.5,
    ));

    // Series 3: Stepped pattern
    final series3Points = <Offset>[];
    for (int i = 0; i < 25; i++) {
      final x = 100 + i * 45.0;
      final y = 250 + (i % 4) * 60.0;
      series3Points.add(Offset(x, y));
    }
    elements.add(SimulatedSeries(
      id: 'series_3',
      points: series3Points,
      color: Colors.purple.withOpacity(0.7),
      strokeWidth: 2.0,
    ));

    // Create dense clusters of datapoints
    // Cluster 1: Top-left area
    for (int i = 0; i < 15; i++) {
      elements.add(SimulatedDatapoint(
        id: 'cluster1_$i',
        center: Offset(
          100 + (i % 5) * 50.0 + (i % 3) * 10.0,
          100 + (i ~/ 5) * 50.0 + (i % 2) * 10.0,
        ),
        radius: 6.0,
        color: Colors.red,
      ));
    }

    // Cluster 2: Middle area (overlapping with series)
    for (int i = 0; i < 20; i++) {
      elements.add(SimulatedDatapoint(
        id: 'cluster2_$i',
        center: Offset(
          400 + (i % 5) * 60.0,
          250 + (i ~/ 5) * 60.0,
        ),
        radius: 7.0,
        color: Colors.orange,
      ));
    }

    // Cluster 3: Bottom-right scattered points
    for (int i = 0; i < 18; i++) {
      elements.add(SimulatedDatapoint(
        id: 'cluster3_$i',
        center: Offset(
          800 + (i % 6) * 55.0,
          550 + (i ~/ 6) * 55.0,
        ),
        radius: 5.5,
        color: Colors.teal,
      ));
    }

    // Additional scattered points across the entire chart
    for (int i = 0; i < 30; i++) {
      elements.add(SimulatedDatapoint(
        id: 'scatter_$i',
        center: Offset(
          150 + (i % 10) * 100.0 + (i % 7) * 20.0,
          120 + (i ~/ 5) * 90.0 + (i % 4) * 15.0,
        ),
        radius: 6.0,
        color: Colors.blue.shade300,
      ));
    }

    // Create overlapping annotations of various sizes
    elements.add(SimulatedAnnotation(
      id: 'note_1',
      bounds: const Rect.fromLTWH(80, 650, 250, 120),
      text: 'Bottom-left annotation',
      backgroundColor: const Color(0xFFFFF9C4),
      borderColor: const Color(0xFFFBC02D),
    ));

    elements.add(SimulatedAnnotation(
      id: 'note_2',
      bounds: const Rect.fromLTWH(900, 150, 220, 150),
      text: 'Top-right annotation',
      backgroundColor: const Color(0xFFE1F5FE),
      borderColor: const Color(0xFF0288D1),
    ));

    elements.add(SimulatedAnnotation(
      id: 'note_3',
      bounds: const Rect.fromLTWH(450, 100, 280, 180),
      text: 'Large center annotation - overlaps many elements',
      backgroundColor: const Color(0xFFF3E5F5),
      borderColor: const Color(0xFF8E24AA),
    ));

    elements.add(SimulatedAnnotation(
      id: 'note_4',
      bounds: const Rect.fromLTWH(200, 400, 200, 100),
      text: 'Overlaps series 1',
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF43A047),
    ));

    elements.add(SimulatedAnnotation(
      id: 'note_5',
      bounds: const Rect.fromLTWH(700, 500, 180, 140),
      text: 'Bottom-right zone',
      backgroundColor: const Color(0xFFFCE4EC),
      borderColor: const Color(0xFFE91E63),
    ));

    // Small annotation overlapping datapoint cluster
    elements.add(SimulatedAnnotation(
      id: 'note_6',
      bounds: const Rect.fromLTWH(380, 230, 150, 90),
      text: 'Cluster overlay',
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
      body: Column(
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
          Expanded(
            child: Center(
              child: Container(
                width: 1200,
                height: 800,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.white,
                ),
                child: PrototypeChart(
                  elements: _elements,
                  chartBounds: const Rect.fromLTWH(0, 0, 1200, 800),
                  onElementSelected: _handleElementSelected,
                  onElementDeselected: _handleElementDeselected,
                  onPanUpdate: _handlePanUpdate,
                  backgroundColor: Colors.white,
                  showDebugInfo: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
