# Quickstart Guide: Interaction System

**Feature**: Layer 7 Interaction System  
**Branch**: 007-interaction-system  
**Date**: 2025-01-07  
**Audience**: Developers using Braven Charts

## Overview

This quickstart guide provides **8+ executable examples** demonstrating all interaction system features. Each example is self-contained and can be copied directly into your project.

**Success Criteria** (from spec):
- ✅ Setup Time: <5 lines of code to enable basic interactions
- ✅ Customization: All visual styles customizable via config objects
- ✅ Documentation: 100% API documentation coverage
- ✅ Examples: Minimum 8 executable examples covering all interaction types

---

## Example 1: Basic Crosshair Enablement

**Goal**: Enable crosshair with default settings (5 lines of code)

```dart
import 'package:braven_charts/braven_charts.dart';

class BasicCrosshairExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      series: [
        ChartSeries(
          id: 'sales',
          data: [
            ChartDataPoint(x: 1, y: 100),
            ChartDataPoint(x: 2, y: 150),
            ChartDataPoint(x: 3, y: 120),
          ],
        ),
      ],
      // Enable crosshair with one line
      interactionConfig: InteractionConfig(
        crosshair: CrosshairConfig.defaultConfig(),
      ),
    );
  }
}
```

**Expected Behavior**:
- ✅ Mouse hover shows crosshair following cursor
- ✅ Crosshair snaps to nearest data point within 20px
- ✅ Vertical + horizontal lines displayed
- ✅ Coordinate labels shown at intersection

---

## Example 2: Custom Crosshair Styling

**Goal**: Customize crosshair appearance (color, width, dash pattern)

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class CustomCrosshairStyleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      series: [_createSampleSeries()],
      interactionConfig: InteractionConfig(
        crosshair: CrosshairConfig(
          enabled: true,
          mode: CrosshairMode.both,  // Both vertical and horizontal
          snapToDataPoint: true,
          snapRadius: 30.0,  // Increased snap radius
          style: CrosshairStyle(
            lineColor: Colors.blue.withOpacity(0.8),
            lineWidth: 2.0,  // Thicker line
            dashPattern: [10, 5],  // Custom dash pattern
            strokeCap: StrokeCap.round,
          ),
          showCoordinateLabels: true,
          coordinateLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  ChartSeries _createSampleSeries() {
    return ChartSeries(
      id: 'revenue',
      data: List.generate(20, (i) => ChartDataPoint(
        x: i * 1.0,
        y: 100 + (i * 10) + (i % 3) * 20,
      )),
    );
  }
}
```

**Expected Behavior**:
- ✅ Blue crosshair with 2px width
- ✅ Custom dash pattern (10px dash, 5px gap)
- ✅ Larger snap radius (30px instead of default 20px)
- ✅ Bold blue coordinate labels

---

## Example 3: Tooltip with Default Content

**Goal**: Show tooltip on hover/tap with default formatting

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class DefaultTooltipExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      series: [
        ChartSeries(
          id: 'temperature',
          name: 'Temperature (°F)',
          data: [
            ChartDataPoint(x: 1, y: 72),
            ChartDataPoint(x: 2, y: 75),
            ChartDataPoint(x: 3, y: 78),
            ChartDataPoint(x: 4, y: 76),
          ],
        ),
      ],
      interactionConfig: InteractionConfig(
        crosshair: CrosshairConfig.defaultConfig(),
        tooltip: TooltipConfig(
          enabled: true,
          triggerMode: TooltipTriggerMode.both,  // Hover or tap
          showDelay: Duration(milliseconds: 300),
          hideDelay: Duration.zero,
          preferredPosition: TooltipPosition.auto,  // Smart positioning
          offsetFromPoint: 10.0,
          style: TooltipStyle(
            backgroundColor: Colors.white,
            borderColor: Colors.grey.shade300,
            borderWidth: 1.0,
            borderRadius: 4.0,
            padding: EdgeInsets.all(8),
            textStyle: TextStyle(fontSize: 14, color: Colors.black87),
            shadow: BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Expected Behavior**:
- ✅ Tooltip appears 300ms after hover/tap
- ✅ Shows series name, X value, Y value
- ✅ Positioned automatically to avoid clipping
- ✅ White background with subtle shadow

---

## Example 4: Tooltip with Custom Builder

**Goal**: Provide custom tooltip content with rich formatting

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class CustomTooltipBuilderExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      series: [_createSalesSeries()],
      interactionConfig: InteractionConfig(
        crosshair: CrosshairConfig.defaultConfig(),
        tooltip: TooltipConfig(
          enabled: true,
          triggerMode: TooltipTriggerMode.both,
          showDelay: Duration(milliseconds: 200),
          hideDelay: Duration.zero,
          preferredPosition: TooltipPosition.top,
          offsetFromPoint: 15.0,
          style: TooltipStyle(
            backgroundColor: Colors.blue.shade50,
            borderColor: Colors.blue,
            borderWidth: 2.0,
            borderRadius: 8.0,
            padding: EdgeInsets.all(12),
            textStyle: TextStyle(fontSize: 14, color: Colors.black),
          ),
          // Custom builder for rich content
          customBuilder: (context, point, seriesId) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Report',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Day ${point.x.toInt()}'),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      '\$${point.y.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: point.y > 150 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    point.y > 150 ? 'Above Target' : 'Below Target',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  ChartSeries _createSalesSeries() {
    return ChartSeries(
      id: 'sales',
      name: 'Daily Sales',
      data: [
        ChartDataPoint(x: 1, y: 120),
        ChartDataPoint(x: 2, y: 165),
        ChartDataPoint(x: 3, y: 145),
        ChartDataPoint(x: 4, y: 180),
        ChartDataPoint(x: 5, y: 130),
      ],
    );
  }
}
```

**Expected Behavior**:
- ✅ Rich tooltip with title, icons, and conditional styling
- ✅ Shows "Above Target" badge if sales > 150
- ✅ Blue-themed styling with custom border radius
- ✅ Positioned at top of data point

---

## Example 5: Zoom/Pan Configuration

**Goal**: Enable zoom/pan with mouse wheel, drag, and touch gestures

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class ZoomPanExample extends StatefulWidget {
  @override
  _ZoomPanExampleState createState() => _ZoomPanExampleState();
}

class _ZoomPanExampleState extends State<ZoomPanExample> {
  double currentZoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zoom level indicator
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Zoom Level: ${(currentZoomLevel * 100).toInt()}%',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: BravenChart(
            series: [_createLargeDataset()],
            interactionConfig: InteractionConfig(
              crosshair: CrosshairConfig.defaultConfig(),
              tooltip: TooltipConfig.defaultConfig(),
              zoomPan: ZoomPanConfig(
                enabled: true,
                zoomMode: ZoomMode.xOnly,  // Zoom X-axis only
                minZoomLevel: 1.0,  // 100% (no zoom out beyond default)
                maxZoomLevel: 10.0,  // 1000% (zoom in 10x)
                allowOverscroll: false,  // Pan stops at data boundaries
                mouseWheelZoomEnabled: true,
                dragPanEnabled: true,
                pinchZoomEnabled: true,
                doubleTapZoomEnabled: true,
                doubleTapZoomFactor: 2.0,  // Double-tap zooms 2x
                resetOnDoubleTap: false,  // Single function: zoom in
                animationDuration: Duration(milliseconds: 200),
              ),
              onZoomChange: (zoomLevel) {
                setState(() {
                  currentZoomLevel = zoomLevel;
                });
              },
            ),
          ),
        ),
        // Reset button
        Padding(
          padding: EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: () {
              // Reset zoom/pan programmatically
              // (BravenChart exposes resetZoomPan() method)
            },
            child: Text('Reset View'),
          ),
        ),
      ],
    );
  }

  ChartSeries _createLargeDataset() {
    return ChartSeries(
      id: 'data',
      name: 'Sample Data',
      data: List.generate(365, (i) => ChartDataPoint(
        x: i * 1.0,
        y: 100 + (i * 0.5) + (i % 10) * 10,
      )),
    );
  }
}
```

**Expected Behavior**:
- ✅ Mouse wheel zooms in/out at cursor position
- ✅ Click+drag pans the chart
- ✅ Pinch gesture zooms on mobile
- ✅ Double-tap zooms in 2x
- ✅ Pan constrained to data boundaries (no overscroll)
- ✅ Zoom level displayed and updated via callback

---

## Example 6: Gesture Handling with Callbacks

**Goal**: Handle interaction events with developer callbacks

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class GestureCallbacksExample extends StatefulWidget {
  @override
  _GestureCallbacksExampleState createState() => _GestureCallbacksExampleState();
}

class _GestureCallbacksExampleState extends State<GestureCallbacksExample> {
  String lastEvent = 'No events yet';
  ChartDataPoint? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Event log
        Container(
          padding: EdgeInsets.all(8),
          color: Colors.grey.shade200,
          child: Text(
            'Last Event: $lastEvent',
            style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
          ),
        ),
        // Selected point info
        if (selectedPoint != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: Text(
              'Selected: X=${selectedPoint!.x}, Y=${selectedPoint!.y}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: BravenChart(
            series: [_createSampleSeries()],
            interactionConfig: InteractionConfig(
              crosshair: CrosshairConfig.defaultConfig(),
              tooltip: TooltipConfig.defaultConfig(),
              zoomPan: ZoomPanConfig.defaultConfig(),
              // Interaction callbacks
              onDataPointTap: (point, seriesId) {
                setState(() {
                  lastEvent = 'Tap: ($seriesId) X=${point.x}, Y=${point.y}';
                  selectedPoint = point;
                });
              },
              onDataPointHover: (point, seriesId) {
                setState(() {
                  lastEvent = 'Hover: ($seriesId) X=${point.x}, Y=${point.y}';
                });
              },
              onDataPointLongPress: (point, seriesId) {
                setState(() {
                  lastEvent = 'Long Press: ($seriesId) X=${point.x}, Y=${point.y}';
                });
                // Show custom dialog on long press
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Data Point Details'),
                    content: Text('X: ${point.x}\nY: ${point.y}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              onSelectionChange: (points) {
                setState(() {
                  lastEvent = 'Selection: ${points.length} points';
                });
              },
              onZoomChange: (zoomLevel) {
                setState(() {
                  lastEvent = 'Zoom: ${(zoomLevel * 100).toInt()}%';
                });
              },
              onPanChange: (offset) {
                setState(() {
                  lastEvent = 'Pan: dx=${offset.dx.toStringAsFixed(1)}, dy=${offset.dy.toStringAsFixed(1)}';
                });
              },
              onViewportChange: (visibleBounds) {
                setState(() {
                  lastEvent = 'Viewport: X(${visibleBounds.left.toStringAsFixed(1)}, ${visibleBounds.right.toStringAsFixed(1)})';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  ChartSeries _createSampleSeries() {
    return ChartSeries(
      id: 'data',
      name: 'Sample',
      data: List.generate(20, (i) => ChartDataPoint(
        x: i * 1.0,
        y: 50 + (i * 5) + (i % 4) * 10,
      )),
    );
  }
}
```

**Expected Behavior**:
- ✅ All interaction events logged to UI
- ✅ Tap selects data point and shows info
- ✅ Long press shows dialog
- ✅ Hover updates event log continuously
- ✅ Zoom/pan events update viewport info

---

## Example 7: Keyboard Navigation Setup

**Goal**: Enable full keyboard navigation with accessibility

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardNavigationExample extends StatefulWidget {
  @override
  _KeyboardNavigationExampleState createState() => _KeyboardNavigationExampleState();
}

class _KeyboardNavigationExampleState extends State<KeyboardNavigationExample> {
  ChartDataPoint? focusedPoint;
  int focusedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Container(
          padding: EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keyboard Controls:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('← → : Navigate data points'),
              Text('Enter/Space : Show tooltip'),
              Text('+ - : Zoom in/out'),
              Text('↑ ↓ ← → (unfocused) : Pan chart'),
              Text('Home/End : Jump to first/last point'),
              Text('Esc : Close tooltip / Clear selection'),
            ],
          ),
        ),
        // Focused point info
        if (focusedPoint != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.green.shade50,
            child: Text(
              'Focused: Point ${focusedIndex + 1} - X=${focusedPoint!.x}, Y=${focusedPoint!.y}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: BravenChart(
            series: [_createSampleSeries()],
            interactionConfig: InteractionConfig(
              crosshair: CrosshairConfig.defaultConfig(),
              tooltip: TooltipConfig.defaultConfig(),
              zoomPan: ZoomPanConfig.defaultConfig(),
              keyboard: KeyboardConfig(
                enabled: true,
                navigationEnabled: true,  // Arrow keys navigate points
                zoomEnabled: true,  // +/- zoom
                panEnabled: true,  // Arrow keys pan when no focus
                focusIndicatorStyle: FocusIndicatorStyle(
                  color: Colors.blue,
                  strokeWidth: 3.0,
                  radius: 8.0,
                  contrastRatio: 3.0,  // WCAG 2.1 AA compliance
                ),
                customBindings: {
                  // Custom key: Z for zoom in
                  LogicalKeyboardKey.keyZ: (state) {
                    // Zoom in at center
                  },
                  // Custom key: X for zoom out
                  LogicalKeyboardKey.keyX: (state) {
                    // Zoom out at center
                  },
                },
              ),
              onDataPointFocus: (point, seriesId, index) {
                setState(() {
                  focusedPoint = point;
                  focusedIndex = index;
                });
              },
            ),
            // Enable accessibility
            semanticsLabel: 'Sales data chart with ${_createSampleSeries().data.length} points',
          ),
        ),
      ],
    );
  }

  ChartSeries _createSampleSeries() {
    return ChartSeries(
      id: 'sales',
      name: 'Sales',
      data: List.generate(15, (i) => ChartDataPoint(
        x: i * 1.0,
        y: 100 + (i * 10),
      )),
    );
  }
}
```

**Expected Behavior**:
- ✅ Tab focuses on chart
- ✅ Arrow keys navigate between data points
- ✅ Visual focus indicator with 3:1 contrast
- ✅ Enter/Space shows tooltip for focused point
- ✅ +/- keys zoom in/out
- ✅ Home/End jump to first/last point
- ✅ Screen reader announces focused point details
- ✅ Custom Z/X keys for zoom (developer-defined)

---

## Example 8: Complete Interaction Configuration

**Goal**: Show all interaction features working together

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class CompleteInteractionExample extends StatefulWidget {
  @override
  _CompleteInteractionExampleState createState() => _CompleteInteractionExampleState();
}

class _CompleteInteractionExampleState extends State<CompleteInteractionExample> {
  String statusMessage = 'Hover, tap, zoom, or use keyboard to interact';
  double zoomLevel = 1.0;
  ChartDataPoint? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Interaction System'),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $statusMessage'),
                Text('Zoom: ${(zoomLevel * 100).toInt()}%'),
                if (selectedPoint != null)
                  Text('Selected: X=${selectedPoint!.x}, Y=${selectedPoint!.y}'),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: BravenChart(
              series: [
                ChartSeries(
                  id: 'revenue',
                  name: 'Revenue',
                  data: List.generate(50, (i) => ChartDataPoint(
                    x: i * 1.0,
                    y: 200 + (i * 5) + (i % 7) * 20,
                  )),
                ),
                ChartSeries(
                  id: 'profit',
                  name: 'Profit',
                  data: List.generate(50, (i) => ChartDataPoint(
                    x: i * 1.0,
                    y: 150 + (i * 3) + (i % 5) * 15,
                  )),
                ),
              ],
              interactionConfig: InteractionConfig(
                // Crosshair
                crosshair: CrosshairConfig(
                  enabled: true,
                  mode: CrosshairMode.both,
                  snapToDataPoint: true,
                  snapRadius: 25.0,
                  style: CrosshairStyle(
                    lineColor: Colors.blue.withOpacity(0.7),
                    lineWidth: 1.5,
                    dashPattern: [5, 3],
                    strokeCap: StrokeCap.round,
                  ),
                  showCoordinateLabels: true,
                ),
                // Tooltip
                tooltip: TooltipConfig(
                  enabled: true,
                  triggerMode: TooltipTriggerMode.both,
                  showDelay: Duration(milliseconds: 250),
                  hideDelay: Duration.zero,
                  preferredPosition: TooltipPosition.auto,
                  offsetFromPoint: 12.0,
                  style: TooltipStyle(
                    backgroundColor: Colors.white,
                    borderColor: Colors.blue,
                    borderWidth: 1.5,
                    borderRadius: 6.0,
                    padding: EdgeInsets.all(10),
                    textStyle: TextStyle(fontSize: 13),
                  ),
                ),
                // Zoom/Pan
                zoomPan: ZoomPanConfig(
                  enabled: true,
                  zoomMode: ZoomMode.xy,
                  minZoomLevel: 1.0,
                  maxZoomLevel: 20.0,
                  allowOverscroll: false,
                  mouseWheelZoomEnabled: true,
                  dragPanEnabled: true,
                  pinchZoomEnabled: true,
                  doubleTapZoomEnabled: true,
                  doubleTapZoomFactor: 2.0,
                  animationDuration: Duration(milliseconds: 200),
                ),
                // Keyboard
                keyboard: KeyboardConfig(
                  enabled: true,
                  navigationEnabled: true,
                  zoomEnabled: true,
                  panEnabled: true,
                  focusIndicatorStyle: FocusIndicatorStyle(
                    color: Colors.blue,
                    strokeWidth: 2.5,
                    radius: 7.0,
                    contrastRatio: 3.0,
                  ),
                ),
                // Callbacks
                onDataPointTap: (point, seriesId) {
                  setState(() {
                    statusMessage = 'Tapped: $seriesId at X=${point.x}, Y=${point.y}';
                    selectedPoint = point;
                  });
                },
                onDataPointHover: (point, seriesId) {
                  setState(() {
                    statusMessage = 'Hovering: $seriesId at X=${point.x}, Y=${point.y}';
                  });
                },
                onZoomChange: (level) {
                  setState(() {
                    zoomLevel = level;
                  });
                },
                onViewportChange: (bounds) {
                  setState(() {
                    statusMessage = 'Viewport: X(${bounds.left.toStringAsFixed(0)} - ${bounds.right.toStringAsFixed(0)})';
                  });
                },
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Reset zoom/pan
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Reset View'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedPoint = null;
                      statusMessage = 'Selection cleared';
                    });
                  },
                  icon: Icon(Icons.clear),
                  label: Text('Clear Selection'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Expected Behavior**:
- ✅ All 7 interaction systems working together:
  1. Event handling (mouse, touch, keyboard)
  2. Crosshair (blue dashed lines, snap-to-point)
  3. Tooltip (auto-positioned, multi-series support)
  4. Zoom/pan (mouse wheel, drag, pinch, double-tap)
  5. Gestures (tap, long-press, pinch, pan)
  6. Keyboard (arrow navigation, +/- zoom, Enter for tooltip)
  7. Callbacks (status updates, selection tracking)
- ✅ Multi-series chart with both Revenue and Profit
- ✅ Status bar showing current interaction
- ✅ Zoom level indicator
- ✅ Selection tracking
- ✅ Reset and clear buttons

---

## Example 9: Multi-Series Interaction

**Goal**: Handle interactions across multiple series simultaneously

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class MultiSeriesInteractionExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      series: [
        ChartSeries(
          id: 'temperature',
          name: 'Temperature (°F)',
          data: _generateTemperatureData(),
          color: Colors.red,
        ),
        ChartSeries(
          id: 'humidity',
          name: 'Humidity (%)',
          data: _generateHumidityData(),
          color: Colors.blue,
        ),
        ChartSeries(
          id: 'pressure',
          name: 'Pressure (hPa)',
          data: _generatePressureData(),
          color: Colors.green,
        ),
      ],
      interactionConfig: InteractionConfig(
        crosshair: CrosshairConfig(
          enabled: true,
          mode: CrosshairMode.vertical,  // Only vertical line
          snapToDataPoint: true,
          snapRadius: 30.0,
          // Multi-series: Shows snap point for ALL series at X position
          multiSeriesSnap: true,
        ),
        tooltip: TooltipConfig(
          enabled: true,
          triggerMode: TooltipTriggerMode.hover,
          showDelay: Duration(milliseconds: 200),
          // Custom builder shows ALL series values at X position
          customBuilder: (context, point, seriesId) {
            // Note: In multi-series mode, point will be the nearest point
            // but tooltip should show all series at that X coordinate
            return _buildMultiSeriesTooltip(context, point.x);
          },
        ),
      ),
    );
  }

  List<ChartDataPoint> _generateTemperatureData() {
    return List.generate(24, (i) => ChartDataPoint(
      x: i * 1.0,
      y: 70 + (i * 0.5) + (i % 3) * 2,
    ));
  }

  List<ChartDataPoint> _generateHumidityData() {
    return List.generate(24, (i) => ChartDataPoint(
      x: i * 1.0,
      y: 60 - (i * 0.3) + (i % 4) * 3,
    ));
  }

  List<ChartDataPoint> _generatePressureData() {
    return List.generate(24, (i) => ChartDataPoint(
      x: i * 1.0,
      y: 1013 + (i * 0.2) - (i % 5) * 1,
    ));
  }

  Widget _buildMultiSeriesTooltip(BuildContext context, double xValue) {
    // In real implementation, BravenChart would provide all series points
    // at the given X coordinate
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hour ${xValue.toInt()}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Divider(),
          _buildSeriesRow('Temperature', 72.5, Colors.red),
          _buildSeriesRow('Humidity', 58.3, Colors.blue),
          _buildSeriesRow('Pressure', 1013.8, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSeriesRow(String name, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text('$name: ${value.toStringAsFixed(1)}'),
        ],
      ),
    );
  }
}
```

**Expected Behavior**:
- ✅ Vertical crosshair shows snap points on ALL three series
- ✅ Tooltip displays all series values at same X coordinate
- ✅ Each series has distinct color indicator in tooltip
- ✅ Smooth interaction across multiple datasets

---

## Performance Tips

### 1. Large Datasets (10,000+ points)
```dart
interactionConfig: InteractionConfig(
  crosshair: CrosshairConfig(
    snapToDataPoint: true,
    snapRadius: 15.0,  // Smaller radius for faster snap calculation
    // Internal: Uses spatial indexing (quadtree) for O(log n) performance
  ),
  zoomPan: ZoomPanConfig(
    enabled: true,
    // Viewport culling automatically enabled
    // Only visible points rendered during zoom/pan
  ),
),
```

### 2. Memory Optimization
```dart
interactionConfig: InteractionConfig(
  tooltip: TooltipConfig(
    enabled: true,
    customBuilder: (context, point, seriesId) {
      // Avoid creating new widgets on every hover
      // Use const widgets when possible
      return const TooltipContent(); // If content doesn't change
    },
  ),
),
```

### 3. Disable Unused Features
```dart
interactionConfig: InteractionConfig(
  crosshair: CrosshairConfig(enabled: false),  // Disable if not needed
  tooltip: TooltipConfig(enabled: true),  // Only enable what's needed
  zoomPan: ZoomPanConfig(enabled: false),  // Disable for static charts
  keyboard: KeyboardConfig(enabled: false),  // Disable if accessibility not required
),
```

---

## Accessibility Checklist

✅ **Keyboard Navigation**:
- Enable `keyboard: KeyboardConfig(enabled: true)`
- Ensure all features accessible via keyboard
- Test with Tab, Arrow keys, Enter, Space, Escape

✅ **Screen Reader Support**:
- Provide `semanticsLabel` on BravenChart
- Focused points automatically announced
- Use Flutter's Semantics widget

✅ **Focus Indicators**:
- Ensure `FocusIndicatorStyle` has 3:1 contrast ratio
- Visible ring around focused data points
- Customizable color and thickness

✅ **WCAG 2.1 AA Compliance**:
- All interactive features keyboard-accessible
- Focus indicators meet contrast requirements
- No time-based interactions (can disable auto-hide tooltips)

---

## Testing Your Implementation

### Unit Test Example
```dart
test('Crosshair snaps to nearest point within radius', () {
  final crosshairRenderer = CrosshairRenderer();
  final points = [
    ChartDataPoint(x: 0, y: 0),
    ChartDataPoint(x: 10, y: 10),
    ChartDataPoint(x: 20, y: 20),
  ];
  
  final snapPoints = crosshairRenderer.calculateSnapPoints(
    Offset(11, 11),  // Position near second point
    points,
    20.0,  // Snap radius
  );
  
  expect(snapPoints.length, 1);
  expect(snapPoints.first.x, 10);
  expect(snapPoints.first.y, 10);
});
```

### Widget Test Example
```dart
testWidgets('Tooltip appears on hover', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: BasicCrosshairExample(),
  ));
  
  // Find chart widget
  final chartFinder = find.byType(BravenChart);
  expect(chartFinder, findsOneWidget);
  
  // Hover over chart
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset(100, 100));
  await tester.pump();
  
  // Wait for tooltip delay (300ms default)
  await tester.pump(Duration(milliseconds: 400));
  
  // Verify tooltip is visible
  expect(find.text('X: '), findsOneWidget);
});
```

---

## Next Steps

1. **Explore API Documentation**: See generated dartdoc comments for all classes
2. **Run Examples**: Copy examples to your project and experiment
3. **Customize**: Adjust configs to match your design requirements
4. **Test**: Write unit and widget tests for your interaction logic
5. **Performance**: Profile with Flutter DevTools if handling large datasets

**Questions or Issues?**  
See `specs/007-interaction-system/spec.md` for detailed requirements or `plan.md` for technical architecture.

---

**Status**: ✅ Quickstart Complete (2025-01-07)  
**Examples**: 9 executable examples covering all interaction types  
**Setup Time**: <5 lines for basic interactions ✓  
**Customization**: All configs demonstrated ✓
