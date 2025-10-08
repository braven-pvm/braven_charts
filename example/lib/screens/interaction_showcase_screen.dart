// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Comprehensive Interaction System Showcase
///
/// This screen demonstrates all interaction features in one place:
/// - InteractionConfig.all() vs .none() factories
/// - Crosshair with custom styling
/// - Tooltip with custom builder
/// - Zoom and pan controls
/// - Gesture callbacks (tap, hover, long-press)
/// - Keyboard navigation
/// - All 8 callback types
///
/// Perfect for testing and demonstrating the full interaction system.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

class InteractionShowcaseScreen extends StatefulWidget {
  const InteractionShowcaseScreen({super.key});

  @override
  State<InteractionShowcaseScreen> createState() => _InteractionShowcaseScreenState();
}

class _InteractionShowcaseScreenState extends State<InteractionShowcaseScreen> {
  // State tracking
  bool interactionsEnabled = true;
  String lastEvent = 'No events yet';
  List<String> eventLog = [];
  double zoomLevelX = 1.0;
  double zoomLevelY = 1.0;
  Map<String, dynamic>? selectedPoint;
  Map<String, dynamic>? hoveredPoint;
  int eventCount = 0;

  // Configuration options
  bool useCrosshair = true;
  bool useTooltip = true;
  bool useZoom = true;
  bool usePan = true;
  bool useKeyboard = true;
  bool useAllFactory = false;
  bool useNoneFactory = false;

  void _logEvent(String event) {
    setState(() {
      lastEvent = event;
      eventCount++;
      eventLog.insert(0, '[$eventCount] $event');
      if (eventLog.length > 20) {
        eventLog.removeLast();
      }
    });
  }

  InteractionConfig _buildConfig() {
    // Demonstrate factory constructors
    if (useAllFactory) {
      return InteractionConfig.all();
    }
    if (useNoneFactory) {
      return InteractionConfig.none();
    }

    // Custom configuration
    return InteractionConfig(
      enabled: interactionsEnabled,
      // Crosshair with custom styling
      crosshair: CrosshairConfig(
        enabled: useCrosshair,
        mode: CrosshairMode.both,
        snapToDataPoint: true,
        snapRadius: 30.0,
        style: const CrosshairStyle(
          lineColor: Color(0xFF2196F3),
          lineWidth: 2.0,
          dashPattern: [10, 5],
        ),
        showCoordinateLabels: true,
      ),
      // Tooltip with custom builder
      tooltip: TooltipConfig(
        enabled: useTooltip,
        triggerMode: TooltipTriggerMode.both,
        showDelay: const Duration(milliseconds: 200),
        preferredPosition: TooltipPosition.top,
        style: const TooltipStyle(
          backgroundColor: Color(0xFFE3F2FD),
          borderColor: Color(0xFF2196F3),
          borderWidth: 2.0,
          borderRadius: 8.0,
          padding: 12.0,
          textColor: Color(0xFF000000),
          fontSize: 14.0,
        ),
        customBuilder: (context, dataPoint) {
          final x = dataPoint['x'] as num;
          final y = dataPoint['y'] as num;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Data Point',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, size: 16, color: Color(0xFF757575)),
                  const SizedBox(width: 4),
                  Text('X: ${x.toStringAsFixed(1)}'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics, size: 16, color: Color(0xFF757575)),
                  const SizedBox(width: 4),
                  Text('Y: ${y.toStringAsFixed(1)}'),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: y > 200 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  y > 200 ? '✓ Above Average' : '! Below Average',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Gesture configuration
      gesture: const GestureConfig(
        tapTimeout: Duration(milliseconds: 200),
        longPressTimeout: Duration(milliseconds: 500),
        panThreshold: 10.0,
        pinchThreshold: 0.1,
      ),
      // Keyboard navigation
      keyboard: KeyboardConfig(
        enabled: useKeyboard,
        panStep: 15.0,
        zoomStep: 0.15,
        enableArrowKeys: true,
        enablePlusMinusKeys: true,
        enableHomeEndKeys: true,
      ),
      // Zoom/Pan flags
      enableZoom: useZoom,
      enablePan: usePan,
      enableSelection: true,
      // All 8 callback types demonstrated
      onDataPointTap: (point, position) {
        _logEvent('TAP: X=${point.x.toStringAsFixed(1)}, Y=${point.y.toStringAsFixed(1)}');
        setState(() {
          selectedPoint = {'x': point.x, 'y': point.y};
        });
      },
      onDataPointHover: (point, position) {
        if (point != null) {
          _logEvent('HOVER: X=${point.x.toStringAsFixed(1)}, Y=${point.y.toStringAsFixed(1)}');
          setState(() {
            hoveredPoint = {'x': point.x, 'y': point.y};
          });
        } else {
          setState(() {
            hoveredPoint = null;
          });
        }
      },
      onDataPointLongPress: (point, position) {
        _logEvent('LONG-PRESS: X=${point.x.toStringAsFixed(1)}, Y=${point.y.toStringAsFixed(1)}');
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('📌 Data Point Details'),
            content: Text(
              'X: ${point.x.toStringAsFixed(2)}\n'
              'Y: ${point.y.toStringAsFixed(2)}\n\n'
              'Position: (${position.dx.toInt()}, ${position.dy.toInt()})',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      onSelectionChanged: (points) {
        _logEvent('SELECTION: ${points.length} points selected');
      },
      onZoomChanged: (zoomX, zoomY) {
        _logEvent('ZOOM: ${(zoomX * 100).toInt()}% x ${(zoomY * 100).toInt()}%');
        setState(() {
          zoomLevelX = zoomX;
          zoomLevelY = zoomY;
        });
      },
      onPanChanged: (offset) {
        _logEvent('PAN: dx=${offset.dx.toStringAsFixed(1)}, dy=${offset.dy.toStringAsFixed(1)}');
      },
      onViewportChanged: (dataBounds) {
        final minX = dataBounds['minX'] ?? 0.0;
        final maxX = dataBounds['maxX'] ?? 0.0;
        _logEvent('VIEWPORT: X=${minX.toStringAsFixed(1)} to ${maxX.toStringAsFixed(1)}');
      },
      onCrosshairChanged: (position, snapPoints) {
        if (snapPoints.isNotEmpty) {
          _logEvent('CROSSHAIR: Snapped to ${snapPoints.length} points');
        }
      },
      onTooltipChanged: (visible, data) {
        if (visible && data != null) {
          _logEvent('TOOLTIP: Shown at (${data.x}, ${data.y})');
        } else {
          _logEvent('TOOLTIP: Hidden');
        }
      },
      onKeyboardAction: (action, targetPoint) {
        if (targetPoint != null) {
          _logEvent('KEYBOARD: $action -> (${targetPoint.x}, ${targetPoint.y})');
        } else {
          _logEvent('KEYBOARD: $action');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction System Showcase'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(interactionsEnabled ? Icons.touch_app : Icons.block),
            onPressed: () {
              setState(() {
                interactionsEnabled = !interactionsEnabled;
              });
            },
            tooltip: interactionsEnabled ? 'Disable All' : 'Enable All',
          ),
        ],
      ),
      body: Row(
        children: [
          // Chart area
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Status bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Status: ${interactionsEnabled ? "ENABLED" : "DISABLED"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Zoom: ${(zoomLevelX * 100).toInt()}% | Events: $eventCount'),
                      if (selectedPoint != null)
                        Text('Selected: X=${selectedPoint!['x']}, Y=${selectedPoint!['y']}'),
                      if (hoveredPoint != null)
                        Text('Hovered: X=${hoveredPoint!['x']}, Y=${hoveredPoint!['y']}'),
                    ],
                  ),
                ),
                // Chart
                Expanded(
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: [
                      ChartSeries(
                        id: 'revenue',
                        name: 'Revenue',
                        points: List.generate(
                          50,
                          (i) => ChartDataPoint(
                            x: i * 1.0,
                            y: 150 + (i * 4) + (i % 7) * 25,
                          ),
                        ),
                      ),
                      ChartSeries(
                        id: 'profit',
                        name: 'Profit',
                        points: List.generate(
                          50,
                          (i) => ChartDataPoint(
                            x: i * 1.0,
                            y: 120 + (i * 3) + (i % 5) * 20,
                          ),
                        ),
                      ),
                    ],
                    interactionConfig: _buildConfig(),
                  ),
                ),
                // Instructions
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    '💡 Try: Hover • Tap • Long-press • Zoom (wheel/pinch) • Pan (drag) • Keyboard (arrows, +/-, home/end)',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Control panel
          Container(
            width: 320,
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  // Factory constructors
                  const Text('Factory Constructors:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Custom Config'),
                    value: 'custom',
                    groupValue: useAllFactory ? 'all' : (useNoneFactory ? 'none' : 'custom'),
                    dense: true,
                    onChanged: (value) {
                      setState(() {
                        useAllFactory = false;
                        useNoneFactory = false;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('InteractionConfig.all()'),
                    value: 'all',
                    groupValue: useAllFactory ? 'all' : (useNoneFactory ? 'none' : 'custom'),
                    dense: true,
                    onChanged: (value) {
                      setState(() {
                        useAllFactory = true;
                        useNoneFactory = false;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('InteractionConfig.none()'),
                    value: 'none',
                    groupValue: useAllFactory ? 'all' : (useNoneFactory ? 'none' : 'custom'),
                    dense: true,
                    onChanged: (value) {
                      setState(() {
                        useAllFactory = false;
                        useNoneFactory = true;
                      });
                    },
                  ),
                  const Divider(),
                  // Feature toggles (only active when custom config)
                  Opacity(
                    opacity: (!useAllFactory && !useNoneFactory) ? 1.0 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SwitchListTile(
                          title: const Text('Crosshair'),
                          value: useCrosshair,
                          dense: true,
                          onChanged: (!useAllFactory && !useNoneFactory)
                              ? (value) => setState(() => useCrosshair = value)
                              : null,
                        ),
                        SwitchListTile(
                          title: const Text('Tooltip'),
                          value: useTooltip,
                          dense: true,
                          onChanged: (!useAllFactory && !useNoneFactory)
                              ? (value) => setState(() => useTooltip = value)
                              : null,
                        ),
                        SwitchListTile(
                          title: const Text('Zoom'),
                          value: useZoom,
                          dense: true,
                          onChanged: (!useAllFactory && !useNoneFactory)
                              ? (value) => setState(() => useZoom = value)
                              : null,
                        ),
                        SwitchListTile(
                          title: const Text('Pan'),
                          value: usePan,
                          dense: true,
                          onChanged: (!useAllFactory && !useNoneFactory)
                              ? (value) => setState(() => usePan = value)
                              : null,
                        ),
                        SwitchListTile(
                          title: const Text('Keyboard'),
                          value: useKeyboard,
                          dense: true,
                          onChanged: (!useAllFactory && !useNoneFactory)
                              ? (value) => setState(() => useKeyboard = value)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Event log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📋 Event Log:', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            eventLog.clear();
                            eventCount = 0;
                            lastEvent = 'Log cleared';
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: eventLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          eventLog[index],
                          style: const TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
