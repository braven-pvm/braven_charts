// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/material.dart';

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
    required this.elements,
    this.chartBounds = const Rect.fromLTWH(0, 0, 800, 600),
    this.onElementSelected,
    this.onElementDeselected,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onZoom,
    this.backgroundColor = Colors.white,
    this.showDebugInfo = false,
  });

  /// Elements to display in the chart.
  final List<ChartElement> elements;

  /// Chart coordinate bounds.
  final Rect chartBounds;

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
    for (final element in widget.elements) {
      _spatialIndex.insert(element);
    }
  }

  void _onCoordinatorChanged() {
    setState(() {
      // Rebuild when coordinator state changes
    });
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                coordinator: _coordinator,
                spatialIndex: _spatialIndex,
                elements: widget.elements,
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
    );
  }
}

/// Widget that wraps ChartRenderBox.
class _ChartRenderWidget extends LeafRenderObjectWidget {
  const _ChartRenderWidget({
    required this.coordinator,
    required this.spatialIndex,
    required this.elements,
    this.onCursorChange,
  });

  final ChartInteractionCoordinator coordinator;
  final QuadTree spatialIndex;
  final List<ChartElement> elements;
  final void Function(MouseCursor cursor)? onCursorChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(
      coordinator: coordinator,
      elements: elements,
      onCursorChange: onCursorChange,
    );
  }

  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    // Update elements reference to pick up selection state mutations
    renderObject.updateElements(elements);
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
