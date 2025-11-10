// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Integration of Prototype Interaction System
// NO REFERENCES TO lib/src - COMPLETELY ISOLATED

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../axis/axis.dart' as chart_axis;
import '../axis/axis_config.dart';
import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/recognizers/priority_pan_recognizer.dart';
import '../interaction/recognizers/priority_tap_recognizer.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/chart_type.dart';
import '../rendering/chart_render_box.dart';
import '../rendering/spatial_index.dart';
import '../utils/data_converter.dart';

/// Next-generation BravenChart with prototype interaction system.
///
/// **⚠️ COMPLETELY ISOLATED** - No references to lib/src!
///
/// **Architecture** (from PrototypeChart):
/// - RenderBox with handleEvent() for direct pointer events
/// - ChartInteractionCoordinator for unified state management
/// - QuadTree spatial indexing for O(log n) hit testing
///
/// **Current Phase**: Foundation - Widget skeleton created
/// Next: Create example app to test empty widget
class BravenChartPlus extends StatefulWidget {
  const BravenChartPlus({
    super.key,
    required this.chartType,
    required this.series,
    this.theme,
    this.xAxis,
    this.yAxis,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.showDebugInfo = false,
  });

  final ChartType chartType;
  final List<ChartSeries> series;
  final ChartTheme? theme;
  final AxisConfig? xAxis;
  final AxisConfig? yAxis;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final bool showDebugInfo;

  @override
  State<BravenChartPlus> createState() => _BravenChartPlusState();
}

class _BravenChartPlusState extends State<BravenChartPlus> {
  late ChartInteractionCoordinator _coordinator;
  late QuadTree _spatialIndex;
  late PriorityPanGestureRecognizer _panRecognizer;
  late PriorityTapGestureRecognizer _tapRecognizer;

  MouseCursor _currentCursor = SystemMouseCursors.basic;
  final GlobalKey _renderBoxKey = GlobalKey();

  // Element generator function for pan/zoom regeneration
  List<ChartElement> Function(ChartTransform)? _elementGenerator;

  chart_axis.Axis? _xAxis;
  chart_axis.Axis? _yAxis;

  @override
  void initState() {
    super.initState();

    _coordinator = ChartInteractionCoordinator();
    _coordinator.addListener(_onCoordinatorChanged);

    _spatialIndex = QuadTree(
      bounds: const Rect.fromLTWH(0, 0, 800, 600),
      maxElementsPerNode: 4,
    );

    _panRecognizer = PriorityPanGestureRecognizer(
      coordinator: _coordinator,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
    );

    _tapRecognizer = PriorityTapGestureRecognizer(
      coordinator: _coordinator,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
    );

    _rebuildElements();
  }

  @override
  void didUpdateWidget(BravenChartPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series != oldWidget.series) {
      _rebuildElements();
    }
  }

  @override
  void dispose() {
    _coordinator.removeListener(_onCoordinatorChanged);
    _coordinator.dispose();
    _panRecognizer.dispose();
    _tapRecognizer.dispose();
    super.dispose();
  }

  void _rebuildElements() {
    _spatialIndex.clear();

    // Compute data bounds from all series
    final dataBounds = DataConverter.computeDataBounds(widget.series);

    // Create axes from data bounds
    _xAxis = chart_axis.Axis(
      config: AxisConfig(
        label: widget.xAxis?.label ?? 'X',
        orientation: AxisOrientation.horizontal,
        position: AxisPosition.bottom,
      ),
      dataMin: dataBounds.xMin,
      dataMax: dataBounds.xMax,
    );

    _yAxis = chart_axis.Axis(
      config: AxisConfig(
        label: widget.yAxis?.label ?? 'Y',
        orientation: AxisOrientation.vertical,
        position: AxisPosition.left,
      ),
      dataMin: dataBounds.yMin,
      dataMax: dataBounds.yMax,
    );

    // Create element generator function
    // This will be called by ChartRenderBox during zoom/pan to regenerate elements
    _elementGenerator = (ChartTransform transform) {
      return DataConverter.seriesToElements(
        series: widget.series,
        transform: transform,
        strokeWidth: 2.0,
      );
    };
  }

  void _onCoordinatorChanged() => setState(() {});

  void _handlePanStart(DragStartDetails details) {}

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.panChart(details.delta.dx, details.delta.dy);
  }

  void _handlePanEnd(DragEndDetails details) {}
  void _handleTapDown(TapDownDetails details) {}
  void _handleTapUp(TapUpDetails details) {}

  void _handleCursorChange(MouseCursor cursor) {
    if (_currentCursor != cursor) {
      setState(() => _currentCursor = cursor);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
      if (renderBox == null) return;

      // Reset view
      if (event.logicalKey == LogicalKeyboardKey.home || event.logicalKey == LogicalKeyboardKey.keyR) {
        renderBox.resetView();
      }
      // Shift modifier for zoom
      else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _coordinator.addModifierKey(LogicalKeyboardKey.shift);
      }
      // Arrow keys for panning
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        renderBox.panChart(-20.0, 0.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        renderBox.panChart(20.0, 0.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        renderBox.panChart(0.0, -20.0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        renderBox.panChart(0.0, 20.0);
      }
      // Zoom in with + or = or numpad +
      else if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.add ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        renderBox.zoomChart(1.1);
      }
      // Zoom out with - or numpad -
      else if (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        renderBox.zoomChart(0.9);
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _coordinator.removeModifierKey(LogicalKeyboardKey.shift);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: hasFocus ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Stack(
              children: [
                MouseRegion(
                  cursor: _currentCursor,
                  child: RawGestureDetector(
                    gestures: {
                      PriorityPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PriorityPanGestureRecognizer>(
                        () => _panRecognizer,
                        (recognizer) {},
                      ),
                      PriorityTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<PriorityTapGestureRecognizer>(
                        () => _tapRecognizer,
                        (recognizer) {},
                      ),
                    },
                    child: _ChartRenderWidget(
                      key: _renderBoxKey,
                      coordinator: _coordinator,
                      spatialIndex: _spatialIndex,
                      elementGenerator: _elementGenerator,
                      xAxis: _xAxis,
                      yAxis: _yAxis,
                      onCursorChange: _handleCursorChange,
                    ),
                  ),
                ),
                if (widget.showDebugInfo)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _DebugOverlay(coordinator: _coordinator),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartRenderWidget extends LeafRenderObjectWidget {
  const _ChartRenderWidget({
    super.key,
    required this.coordinator,
    required this.spatialIndex,
    this.elementGenerator,
    this.xAxis,
    this.yAxis,
    this.onCursorChange,
  });

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement> Function(ChartTransform)? elementGenerator;
  final chart_axis.Axis? xAxis;
  final chart_axis.Axis? yAxis;
  final void Function(MouseCursor cursor)? onCursorChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(
      coordinator: coordinator,
      elementGenerator: elementGenerator,
      onCursorChange: onCursorChange,
    )
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    renderObject
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }
}

class _DebugOverlay extends StatelessWidget {
  const _DebugOverlay({required this.coordinator});

  final ChartInteractionCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mode: ${coordinator.currentMode.name}'),
            Text('Selected: ${coordinator.selectedElements.length}'),
            if (coordinator.activeElement != null) Text('Active: ${coordinator.activeElement!.id}'),
          ],
        ),
      ),
    );
  }
}
