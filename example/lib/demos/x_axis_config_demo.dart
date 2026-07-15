// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT
//
// X-Axis Configuration Demo
// Demonstrates XAxisConfig features through XAxisPainter.
//
// Note: This demo focuses on XAxisPainter functionality which uses XAxisConfig.
// BravenChartPlus now accepts XAxisConfig directly.
//
// This demo imports internal implementation files to directly test XAxisPainter.
// ignore_for_file: implementation_imports

import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/rendering/x_axis_painter.dart';
import 'package:flutter/material.dart';

/// Demo showcasing XAxisConfig features through XAxisPainter.
///
/// Features demonstrated:
/// 1. Label and unit display modes (7 different AxisLabelDisplay modes)
/// 2. Explicit min/max bounds override
/// 3. TickCount control
/// 4. Visibility toggles (visible, showAxisLine, showTicks, showCrosshairLabel)
/// 5. Custom label formatters
/// 6. Color customization
class XAxisConfigDemo extends StatefulWidget {
  const XAxisConfigDemo({super.key});

  @override
  State<XAxisConfigDemo> createState() => _XAxisConfigDemoState();
}

class _XAxisConfigDemoState extends State<XAxisConfigDemo> {
  String _selectedDemo = 'label-modes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XAxisConfig Demo'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedDemo,
            onSelected: (value) => setState(() => _selectedDemo = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'label-modes',
                child: Text('Label Display Modes'),
              ),
              const PopupMenuItem(
                value: 'bounds',
                child: Text('Min/Max Bounds Override'),
              ),
              const PopupMenuItem(
                value: 'tick-count',
                child: Text('Tick Count Control'),
              ),
              const PopupMenuItem(
                value: 'visibility',
                child: Text('Visibility Toggles'),
              ),
              const PopupMenuItem(
                value: 'custom-formatter',
                child: Text('Custom Label Formatter'),
              ),
              const PopupMenuItem(
                value: 'colors',
                child: Text('Color Customization'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDemoTitle(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _getDemoDescription(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CustomPaint(
                painter: _XAxisDemoPainter(_buildXAxisConfig()),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDemoTitle() {
    switch (_selectedDemo) {
      case 'label-modes':
        return 'Label Display Modes';
      case 'bounds':
        return 'Min/Max Bounds Override';
      case 'tick-count':
        return 'Tick Count Control';
      case 'visibility':
        return 'Visibility Toggles';
      case 'custom-formatter':
        return 'Custom Label Formatter';
      case 'colors':
        return 'Color Customization';
      default:
        return 'XAxisConfig Demo';
    }
  }

  String _getDemoDescription() {
    switch (_selectedDemo) {
      case 'label-modes':
        return 'Shows labelWithUnit mode: "Time (s)" label with plain tick numbers.';
      case 'bounds':
        return 'Explicit min/max override: Data range 0-100 but axis shows 20-80.';
      case 'tick-count':
        return 'tickCount property controls approximate number of tick marks (5 ticks).';
      case 'visibility':
        return 'Toggle flags: showAxisLine=true, showTicks=false (line but no ticks).';
      case 'custom-formatter':
        return 'labelFormatter callback formats ticks as time (e.g., "1m 30s").';
      case 'colors':
        return 'XAxisConfig.color customizes axis line, ticks, and labels (purple).';
      default:
        return '';
    }
  }

  XAxisConfig _buildXAxisConfig() {
    switch (_selectedDemo) {
      case 'label-modes':
        return const XAxisConfig(
          label: 'Time',
          unit: 's',
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
      case 'bounds':
        return const XAxisConfig(
          label: 'Time',
          unit: 's',
          min: 20.0,
          max: 80.0,
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
      case 'tick-count':
        return const XAxisConfig(
          label: 'Time',
          unit: 's',
          tickCount: 5,
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
      case 'visibility':
        return const XAxisConfig(
          label: 'Time',
          unit: 's',
          visible: true,
          showAxisLine: true,
          showTicks: false,
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
      case 'custom-formatter':
        return XAxisConfig(
          label: 'Time',
          labelFormatter: (value) {
            final minutes = (value / 60).floor();
            final seconds = (value % 60).floor();
            return '${minutes}m ${seconds}s';
          },
          labelDisplay: AxisLabelDisplay.labelOnly,
        );
      case 'colors':
        return const XAxisConfig(
          label: 'Time',
          unit: 's',
          color: Colors.deepPurple,
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
      default:
        return const XAxisConfig();
    }
  }
}

class _XAxisDemoPainter extends CustomPainter {
  _XAxisDemoPainter(this.config);
  final XAxisConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    // Create plot area leaving space for axis
    final plotArea = Rect.fromLTWH(40, 20, size.width - 80, size.height - 100);

    // Create axis painter
    final painter = XAxisPainter(
      config: config,
      axisBounds: const DataRange(min: 0.0, max: 100.0),
      labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
    );

    // Paint the axis
    painter.paint(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      plotArea,
    );
  }

  @override
  bool shouldRepaint(_XAxisDemoPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}

void main() => runApp(
  const MaterialApp(home: XAxisConfigDemo(), debugShowCheckedModeBanner: false),
);
