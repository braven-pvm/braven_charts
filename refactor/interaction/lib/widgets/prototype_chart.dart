// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../axis/axis.dart' as chart_axis;
import '../core/chart_element.dart';
import '../core/coordinator.dart';
import '../recognizers/priority_pan_recognizer.dart';
import '../recognizers/priority_tap_recognizer.dart';
import '../rendering/chart_render_box.dart';
import '../rendering/spatial_index.dart';

/// Prototype chart widget that demonstrates the interaction architecture.
///
/// **Purpose**: Validate the complete interaction system with:
/// - Custom RenderBox (ChartRenderBox) for chart rendering
/// - QuadTree spatial indexing for O(log n) hit testing
/// - ChartInteractionCoordinator for conflict-free state management
/// - Custom gesture recognizers for arena participation
///
/// **Usage**:
/// ```dart
/// PrototypeChart(
///   elements: [
///     SimulatedDatapoint(id: '1', center: Offset(100, 100)),
///     SimulatedAnnotation(id: 'note', bounds: Rect.fromLTWH(200, 200, 150, 100)),
///   ],
///   onElementSelected: (element) => print('Selected: ${element.id}'),
///   onPan: (delta) => print('Pan: $delta'),
/// )
/// ```
class PrototypeChart extends StatefulWidget {
  const PrototypeChart({
    super.key,
    this.elements,
    this.elementGenerator,
    required this.chartBounds,
    this.xAxis,
    this.yAxis,
    this.onElementSelected,
    this.onElementDeselected,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onZoom,
    this.backgroundColor = Colors.white,
    this.showDebugInfo = false,
  }) : assert(
          (elements != null) != (elementGenerator != null),
          'Must provide either elements or elementGenerator, not both',
        );

  /// Elements to display in the chart (static - no zoom/pan support).
  ///
  /// Use this for simple charts that don't need zoom/pan.
  /// For zoom/pan support, use [elementGenerator] instead.
  final List<ChartElement>? elements;

  /// Element generator callback (for zoom/pan support).
  ///
  /// Called with current transform to generate elements in plot space.
  /// Chart will call this on initial render and whenever zoom/pan occurs.
  ///
  /// **Example**:
  /// ```dart
  /// elementGenerator: (transform) {
  ///   // Define data in data space
  ///   final dataPoints = [(1000.0, 100.0), ...];
  ///
  ///   // Convert to plot space
  ///   final plotPoints = transform.dataPointsToPlot(dataPoints);
  ///
  ///   // Create elements
  ///   return [SeriesElement(points: plotPoints, ...)];
  /// }
  /// ```
  final ElementGenerator? elementGenerator;

  /// Chart coordinate bounds.
  final Rect chartBounds;

  /// Optional X-axis.
  final chart_axis.Axis? xAxis;

  /// Optional Y-axis.
  final chart_axis.Axis? yAxis;

  /// Called when an element is selected.
  final void Function(ChartElement element)? onElementSelected;

  /// Called when an element is deselected.
  final void Function(ChartElement element)? onElementDeselected;

  /// Called when pan gesture starts.
  final GestureDragStartCallback? onPanStart;

  /// Called when pan gesture updates.
  final GestureDragUpdateCallback? onPanUpdate;

  /// Called when pan gesture ends.
  final GestureDragEndCallback? onPanEnd;

  /// Called when zoom occurs (mouse wheel).
  final void Function(double zoomDelta)? onZoom;

  /// Background color.
  final Color backgroundColor;

  /// Show debug overlay with coordinator state.
  final bool showDebugInfo;

  @override
  State<PrototypeChart> createState() => _PrototypeChartState();
}

class _PrototypeChartState extends State<PrototypeChart> {
  late ChartInteractionCoordinator _coordinator;
  late QuadTree _spatialIndex;

  // Gesture recognizers
  late PriorityPanGestureRecognizer _panRecognizer;
  late PriorityTapGestureRecognizer _tapRecognizer;

  // Mouse cursor state
  MouseCursor _currentCursor = SystemMouseCursors.basic;

  // Key for accessing ChartRenderBox
  final GlobalKey _renderBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize coordinator
    _coordinator = ChartInteractionCoordinator();
    _coordinator.addListener(_onCoordinatorChanged);

    // Initialize spatial index
    _spatialIndex = QuadTree(
      bounds: widget.chartBounds,
      maxElementsPerNode: 4,
    );

    // Initialize gesture recognizers
    _panRecognizer = PriorityPanGestureRecognizer(
      coordinator: _coordinator,
      onPanStart: widget.onPanStart,
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
    );

    _tapRecognizer = PriorityTapGestureRecognizer(
      coordinator: _coordinator,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
    );

    _rebuildSpatialIndex();
  }

  @override
  void didUpdateWidget(PrototypeChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.elements != oldWidget.elements) {
      _rebuildSpatialIndex();
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

  void _rebuildSpatialIndex() {
    _spatialIndex.clear();
    // Only rebuild from widget.elements if provided
    // If elementGenerator is used, RenderBox will handle spatial index
    if (widget.elements != null) {
      for (final element in widget.elements!) {
        _spatialIndex.insert(element);
      }
    }
  }

  void _onCoordinatorChanged() {
    // CRITICAL FIX: Only call setState() if debug overlay is visible!
    // Crosshair rendering happens in RenderBox.paint() via markNeedsPaint(),
    // so we don't need setState() for cursor movement.
    // setState() triggers expensive widget tree rebuilds.
    if (widget.showDebugInfo) {
      setState(() {});
    }
  }

  void _handleTapDown(TapDownDetails details) {
    // NOTE: Selection logic has been moved to ChartRenderBox._handlePointerDown
    // to ensure correct coordinate space usage. RenderBox uses event.localPosition
    // which is in the correct coordinate space, whereas TapDownDetails.localPosition
    // is in widget coordinate space and may differ due to transforms/padding.
    //
    // The RenderBox handler already performs hit-testing and selection with proper
    // coordinates, so this handler should remain empty to avoid duplicate/conflicting
    // selection logic.
  }

  void _handleTapUp(TapUpDetails details) {
    // Tap completed - selection already handled in tapDown
  }

  void _handleCursorChange(MouseCursor cursor) {
    if (_currentCursor != cursor) {
      setState(() {
        _currentCursor = cursor;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Handle reset view (Home key or R key)
      if (event.logicalKey == LogicalKeyboardKey.home || event.logicalKey == LogicalKeyboardKey.keyR) {
        final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
        if (renderBox != null) {
          renderBox.resetView();
          debugPrint('⌨️ View reset to original');
        }
      }
      // Handle zoom keys (+, -, numpad +, numpad -)
      else if (event.logicalKey == LogicalKeyboardKey.equal || // = key (+ requires shift, but we accept both)
          event.logicalKey == LogicalKeyboardKey.add || // Numpad + (alternative name)
          event.logicalKey == LogicalKeyboardKey.numpadAdd || // Numpad + (primary name)
          event.logicalKey == LogicalKeyboardKey.minus || // - key
          event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        // Numpad -
        final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
        if (renderBox != null) {
          const double zoomStep = 1.2; // 20% zoom per key press
          final bool isZoomIn = event.logicalKey == LogicalKeyboardKey.equal ||
              event.logicalKey == LogicalKeyboardKey.add ||
              event.logicalKey == LogicalKeyboardKey.numpadAdd;
          final double zoomFactor = isZoomIn ? zoomStep : 1.0 / zoomStep;

          // Apply zoom directly (no animation - keeps it responsive for repeated presses)
          renderBox.zoomChart(zoomFactor);
          debugPrint('⌨️ Keyboard zoom: ${zoomFactor > 1 ? "IN" : "OUT"}');
        }
      }
      // Handle arrow key panning
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
        if (renderBox != null) {
          // Pan by 10% of plot area per key press
          final plotWidth = renderBox.plotWidth;
          final plotHeight = renderBox.plotHeight;

          if (plotWidth > 0 && plotHeight > 0) {
            final panStepX = plotWidth * 0.1;
            final panStepY = plotHeight * 0.1;

            double dx = 0.0;
            double dy = 0.0;

            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              dx = -panStepX; // Pan view left (show more data on left)
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              dx = panStepX; // Pan view right (show more data on right)
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              dy = -panStepY; // Pan view up (show more data above)
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              dy = panStepY; // Pan view down (show more data below)
            }

            renderBox.panChart(dx, dy);
            debugPrint('⌨️ Arrow key pan: ${event.logicalKey.keyLabel}');
          }
        }
      }
      // Track modifier keys
      else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _coordinator.addModifierKey(LogicalKeyboardKey.shift);
        debugPrint('✓ Shift pressed - zoom enabled');
      } else if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
        _coordinator.addModifierKey(LogicalKeyboardKey.control);
      } else if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight) {
        _coordinator.addModifierKey(LogicalKeyboardKey.alt);
      } else if (event.logicalKey == LogicalKeyboardKey.metaLeft || event.logicalKey == LogicalKeyboardKey.metaRight) {
        _coordinator.addModifierKey(LogicalKeyboardKey.meta);
      }
    } else if (event is KeyUpEvent) {
      // Release modifier keys
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _coordinator.removeModifierKey(LogicalKeyboardKey.shift);
        debugPrint('✗ Shift released - zoom disabled');
      } else if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
        _coordinator.removeModifierKey(LogicalKeyboardKey.control);
      } else if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight) {
        _coordinator.removeModifierKey(LogicalKeyboardKey.alt);
      } else if (event.logicalKey == LogicalKeyboardKey.metaLeft || event.logicalKey == LogicalKeyboardKey.metaRight) {
        _coordinator.removeModifierKey(LogicalKeyboardKey.meta);
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
      child: Container(
        color: widget.backgroundColor,
        child: Stack(
          children: [
            // Main chart render area wrapped in MouseRegion for cursor control
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
                  elements: widget.elements,
                  elementGenerator: widget.elementGenerator,
                  xAxis: widget.xAxis,
                  yAxis: widget.yAxis,
                  onCursorChange: _handleCursorChange,
                ),
              ),
            ),

            // Debug overlay (if enabled)
            if (widget.showDebugInfo)
              Positioned(
                top: 8,
                left: 8,
                child: _DebugOverlay(coordinator: _coordinator),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget that wraps ChartRenderBox.
class _ChartRenderWidget extends LeafRenderObjectWidget {
  const _ChartRenderWidget({
    super.key,
    required this.coordinator,
    required this.spatialIndex,
    this.elements,
    this.elementGenerator,
    this.xAxis,
    this.yAxis,
    this.onCursorChange,
  }) : assert((elements != null) != (elementGenerator != null), 'Must provide either elements or elementGenerator, but not both');

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement>? elements;
  final ElementGenerator? elementGenerator;
  final chart_axis.Axis? xAxis;
  final chart_axis.Axis? yAxis;
  final void Function(MouseCursor cursor)? onCursorChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(
      coordinator: coordinator,
      elements: elements,
      elementGenerator: elementGenerator,
      onCursorChange: onCursorChange,
    )
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    // Update elements reference to pick up selection state mutations
    if (elements != null) {
      renderObject.updateElements(elements!);
    }
    // Update axes
    renderObject
      ..setXAxis(xAxis)
      ..setYAxis(yAxis);
  }
}

/// Debug overlay showing coordinator state.
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
            Text(
              'Modifiers: '
              '${coordinator.isCtrlPressed ? "Ctrl " : ""}'
              '${coordinator.isShiftPressed ? "Shift " : ""}'
              '${coordinator.isAltPressed ? "Alt " : ""}',
            ),
            if (coordinator.activeElement != null) Text('Active: ${coordinator.activeElement!.id}'),
          ],
        ),
      ),
    );
  }
}
