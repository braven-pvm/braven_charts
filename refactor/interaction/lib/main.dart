// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Example Application

import 'dart:ui';

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
    // Create sample datapoints in a scatter pattern
    final datapoints = <SimulatedDatapoint>[];
    for (int i = 0; i < 20; i++) {
      datapoints.add(SimulatedDatapoint(
        id: 'point_$i',
        center: Offset(
          100 + (i % 5) * 120.0,
          100 + (i ~/ 5) * 100.0,
        ),
        radius: 8.0,
        color: Colors.blue,
      ));
    }

    // Create a series (line chart)
    final seriesPoints = <Offset>[];
    for (int i = 0; i < 10; i++) {
      seriesPoints.add(Offset(
        80 + i * 70.0,
        300 - i * 15.0 + (i % 2) * 30.0, // Zigzag pattern
      ));
    }

    final series = SimulatedSeries(
      id: 'series_1',
      points: seriesPoints,
      color: Colors.green,
      strokeWidth: 3.0,
    );

    // Create annotations
    final annotations = [
      SimulatedAnnotation(
        id: 'note_1',
        bounds: const Rect.fromLTWH(50, 450, 200, 80),
        text: 'Drag me!',
        backgroundColor: const Color(0xFFFFF9C4),
        borderColor: const Color(0xFFFBC02D),
      ),
      SimulatedAnnotation(
        id: 'note_2',
        bounds: const Rect.fromLTWH(550, 100, 180, 100),
        text: 'Resize handles when selected',
        backgroundColor: const Color(0xFFE1F5FE),
        borderColor: const Color(0xFF0288D1),
      ),
    ];

    return [
      series,
      ...datapoints,
      ...annotations,
    ];
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
                width: 800,
                height: 600,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.white,
                ),
                child: PrototypeChart(
                  elements: _elements,
                  chartBounds: const Rect.fromLTWH(0, 0, 800, 600),
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
