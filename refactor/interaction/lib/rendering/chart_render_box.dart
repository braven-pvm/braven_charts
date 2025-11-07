// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../axis/axis.dart' as chart_axis;
import '../axis/axis_renderer.dart';
import '../core/chart_element.dart';
import '../core/coordinator.dart';
import '../core/element_types.dart';
import '../core/hit_test_strategy.dart';
import '../core/interaction_mode.dart';
import '../elements/resize_handle_element.dart';
import '../elements/simulated_annotation.dart';
import '../transforms/chart_transform.dart';
import 'spatial_index.dart';

/// Callback for generating chart elements based on current transform.
/// Used for zoom/pan to regenerate elements from original data coordinates.
typedef ElementGenerator = List<ChartElement> Function(ChartTransform transform);

/// Custom RenderBox for high-performance chart rendering and interaction.
///
/// **Purpose** (per INTERACTION_ARCHITECTURE_DESIGN.md):
/// - High-performance rendering with GPU batching
/// - Viewport culling via QuadTree spatial index
/// - Background interactions (pan, zoom, wheel events)
/// - Pixel-perfect hit testing
/// - Handles 100+ elements at 60fps
///
/// **Integration**: Used by ChartPrototypeWidget as the RenderObject layer.
///
/// **Interaction Flow**:
/// 1. PointerEvent arrives at handleEvent()
/// 2. Use QuadTree to find candidate elements at pointer position
/// 3. Check coordinator state to determine if interaction is allowed
/// 4. Route event to appropriate handler based on button/modifiers
/// 5. Update coordinator state if interaction mode changes
class ChartRenderBox extends RenderBox {
  ChartRenderBox({
    required this.coordinator,
    List<ChartElement>? elements,
    ElementGenerator? elementGenerator,
    this.onElementClick,
    this.onElementHover,
    this.onEmptyAreaClick,
    this.onCursorChange,
  })  : _elementGenerator = elementGenerator,
        assert((elements != null) != (elementGenerator != null), 'Must provide either elements or elementGenerator, but not both') {
    _elements = elements ?? [];
  }

  /// Spatial index for O(log n) hit testing.
  QuadTree? _spatialIndex;

  /// All chart elements to render and test.
  ///
  /// CRITICAL: This must be the same list reference that the coordinator
  /// mutates when calling element.onSelect()/onDeselect(), so that
  /// isSelected state changes are reflected during paint().
  List<ChartElement> _elements = [];

  /// Optional callback for generating elements from current transform.
  /// If provided, elements will be regenerated on zoom/pan operations.
  final ElementGenerator? _elementGenerator;

  /// Interaction coordinator for conflict resolution.
  final ChartInteractionCoordinator coordinator;

  /// Callback for element click events.
  final void Function(ChartElement element, PointerEvent event)? onElementClick;

  /// Callback for element hover events.
  final void Function(ChartElement? element)? onElementHover;

  /// Callback for empty area click (for box select start).
  final void Function(Offset position, PointerEvent event)? onEmptyAreaClick;

  /// Callback for cursor changes.
  final void Function(MouseCursor cursor)? onCursorChange;

  /// Current resize state (if resizing annotation).
  ResizeDirection? _activeResizeDirection;
  SimulatedAnnotation? _resizingAnnotation;
  Rect? _resizeStartBounds;

  /// Current cursor position (for crosshair rendering).
  Offset? _cursorPosition;

  /// Last pan position (for calculating delta during middle-button drag).
  Offset? _lastPanPosition;

  /// X-axis for the chart (optional).
  chart_axis.Axis? _xAxis;

  /// Y-axis for the chart (optional).
  chart_axis.Axis? _yAxis;

  /// Plot area where chart elements are rendered (excluding axis space).
  Rect _plotArea = Rect.zero;

  /// Coordinate transform for Data ↔ Plot conversion.
  ///
  /// Created during layout based on data ranges and plot area dimensions.
  /// Elements are stored in PLOT space, transform is used for viewport changes.
  ChartTransform? _transform;

  /// Original transform state (for reset functionality and constraint calculations).
  ///
  /// Captured during first performLayout() and preserved throughout chart lifetime.
  /// Used to:
  /// - Calculate current zoom level relative to original
  /// - Enforce pan bounds (keep data visible)
  /// - Reset view to original state
  ChartTransform? _originalTransform;

  // ==========================================================================
  // Zoom/Pan Constraints
  // ==========================================================================

  /// Minimum zoom level (relative to original data range).
  /// 1.0 = cannot zoom out beyond original view (no zoom out allowed).
  static const double minZoomLevel = 1.0;

  /// Maximum zoom level (relative to original data range).
  /// 10.0 = can zoom in to show 1/10th of original data range.
  static const double maxZoomLevel = 10.0;

  /// Maximum whitespace allowed beyond data boundaries when panning.
  /// 0.1 = can pan until original data edge is 10% into viewport
  /// (leaving maximum 90% of data visible, minimum 10% whitespace).
  /// This is viewport-based, so it's independent of zoom level.
  static const double maxWhitespaceFraction = 0.1;

  /// Public getter for plot width.
  double get plotWidth => _plotArea.width;

  /// Public getter for plot height.
  double get plotHeight => _plotArea.height;

  /// Updates the list of chart elements.
  ///
  /// Rebuilds the spatial index with new elements.
  void updateElements(List<ChartElement> elements) {
    if (elements == _elements) return;

    _elements = elements;
    _rebuildSpatialIndex();
    markNeedsPaint();
  }

  /// Sets the X-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  void setXAxis(chart_axis.Axis? axis) {
    if (_xAxis == axis) return;
    _xAxis = axis;
    markNeedsLayout();
  }

  /// Sets the Y-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  void setYAxis(chart_axis.Axis? axis) {
    if (_yAxis == axis) return;
    _yAxis = axis;
    markNeedsLayout();
  }

  /// Programmatically zoom the chart.
  ///
  /// **Parameters**:
  /// - `factor`: Zoom factor (> 1.0 = zoom in, < 1.0 = zoom out)
  /// - `plotCenter`: Center point in plot space (if null, uses plot center)
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void zoomChart(double factor, {Offset? plotCenter}) {
    if (_transform == null || _elementGenerator == null || _originalTransform == null) {
      debugPrint('⚠️ Cannot zoom: transform, elementGenerator, or originalTransform not available');
      return;
    }

    // Use plot center if not specified
    final center = plotCenter ?? Offset(_plotArea.width / 2, _plotArea.height / 2);

    // Apply zoom tentatively
    final tentativeTransform = _transform!.zoom(factor, center);

    // Clamp zoom to min/max levels
    final clampedTransform = _clampZoomLevel(tentativeTransform);

    // Apply clamped zoom
    _transform = clampedTransform;

    // Regenerate elements
    _rebuildElementsWithTransform();

    debugPrint('🔍 Keyboard zoom: factor=$factor, center=$center');
  }

  /// Programmatically pan the chart.
  ///
  /// **Parameters**:
  /// - `plotDx`, `plotDy`: Pan delta in plot pixels
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void panChart(double plotDx, double plotDy) {
    if (_transform == null || _elementGenerator == null || _originalTransform == null) {
      debugPrint('⚠️ Cannot pan: transform, elementGenerator, or originalTransform not available');
      return;
    }

    // Clamp pan delta BEFORE applying (prevents overshoot/snap-back)
    final (clampedDx, clampedDy) = _clampPanDelta(plotDx, plotDy);

    // Apply constrained pan (won't violate boundaries)
    _transform = _transform!.pan(clampedDx, clampedDy);

    // Regenerate elements
    _rebuildElementsWithTransform();

    if (clampedDx != plotDx || clampedDy != plotDy) {
      debugPrint('� Pan constrained: requested=($plotDx, $plotDy) → allowed=($clampedDx, $clampedDy)');
    } else {
      debugPrint('🔄 Pan applied: dx=$plotDx, dy=$plotDy');
    }
  }

  /// Reset view to original zoom/pan state.
  void resetView() {
    if (_originalTransform == null || _elementGenerator == null) {
      debugPrint('⚠️ Cannot reset: originalTransform or elementGenerator not available');
      return;
    }

    // Restore original data ranges, preserve current plot dimensions
    _transform = _originalTransform!.copyWith(
      plotWidth: _plotArea.width,
      plotHeight: _plotArea.height,
    );

    // Regenerate elements
    _rebuildElementsWithTransform();

    debugPrint('🔄 View reset to original');
  }

  // ============================================================================
  // Zoom/Pan Constraint Helpers
  // ============================================================================

  /// Clamps a transform to enforce min/max zoom levels.
  ///
  /// **Constraints**:
  /// - Min zoom: 0.1x (can zoom out to show 10x original data)
  /// - Max zoom: 10.0x (can zoom in to show 1/10th original data)
  ///
  /// **Algorithm**:
  /// 1. Calculate current zoom level: original_range / current_range
  /// 2. If zoom exceeds limits, scale ranges back to limit
  /// 3. Preserve center point of current viewport
  ChartTransform _clampZoomLevel(ChartTransform transform) {
    if (_originalTransform == null) return transform;

    final originalXRange = _originalTransform!.dataXMax - _originalTransform!.dataXMin;
    final originalYRange = _originalTransform!.dataYMax - _originalTransform!.dataYMin;

    final currentXRange = transform.dataXMax - transform.dataXMin;
    final currentYRange = transform.dataYMax - transform.dataYMin;

    // Calculate current zoom levels
    final currentZoomX = originalXRange / currentXRange;
    final currentZoomY = originalYRange / currentYRange;

    // Check if clamping needed
    bool needsClampX = currentZoomX < minZoomLevel || currentZoomX > maxZoomLevel;
    bool needsClampY = currentZoomY < minZoomLevel || currentZoomY > maxZoomLevel;

    if (!needsClampX && !needsClampY) {
      return transform; // No clamping needed
    }

    // Clamp zoom levels
    final clampedZoomX = currentZoomX.clamp(minZoomLevel, maxZoomLevel);
    final clampedZoomY = currentZoomY.clamp(minZoomLevel, maxZoomLevel);

    // Calculate new ranges from clamped zoom
    final newXRange = originalXRange / clampedZoomX;
    final newYRange = originalYRange / clampedZoomY;

    // Preserve center of current viewport
    final centerX = (transform.dataXMin + transform.dataXMax) / 2;
    final centerY = (transform.dataYMin + transform.dataYMax) / 2;

    // Calculate new bounds centered on viewport center
    final newDataXMin = centerX - newXRange / 2;
    final newDataXMax = centerX + newXRange / 2;
    final newDataYMin = centerY - newYRange / 2;
    final newDataYMax = centerY + newYRange / 2;

    debugPrint('🔒 Zoom clamped: X=$currentZoomX→$clampedZoomX, Y=$currentZoomY→$clampedZoomY');

    return ChartTransform(
      dataXMin: newDataXMin,
      dataXMax: newDataXMax,
      dataYMin: newDataYMin,
      dataYMax: newDataYMax,
      plotWidth: transform.plotWidth,
      plotHeight: transform.plotHeight,
      invertY: transform.invertY,
    );
  }

  /// Clamps a transform to enforce pan bounds (limit whitespace).
  ///
  /// **Constraints**:
  /// - Original data boundaries can move OFF-SCREEN by up to 10% of viewport
  /// - This ensures at least 90% of original data remains visible when fully panned
  /// - Constraint is viewport-based (independent of zoom level)
  ///
  /// **Algorithm**:
  /// 1. Convert original data boundaries to current plot coordinates
  /// 2. Check if they've moved too far off-screen
  /// 3. Clamp so they stay within allowed off-screen range
  ///
  /// **Example**: If viewport is 800px wide:
  /// - Left edge can move to -80px (10% off-screen to left)
  /// - Right edge can move to 880px (10% off-screen to right)
  /// This ensures 90% of data stays visible.

  /// Clamp pan delta to prevent violating boundaries.
  ///
  /// **Strategy**: Calculate maximum allowed delta in each direction,
  /// then clamp requested delta to stay within those limits.
  /// This prevents overshoot, making pan feel like hitting a wall.
  ///
  /// **Zoom-Aware Constraints**:
  /// - Low zoom (1x-2x): Track original data boundaries to keep them visible
  /// - High zoom (>2x): Track current viewport to prevent excessive whitespace
  (double, double) _clampPanDelta(double requestedDx, double requestedDy) {
    if (_originalTransform == null || _transform == null) {
      return (requestedDx, requestedDy);
    }

    final plotWidth = _transform!.plotWidth;
    final plotHeight = _transform!.plotHeight;

    // Calculate current zoom level
    final originalXRange = _originalTransform!.dataXMax - _originalTransform!.dataXMin;
    final originalYRange = _originalTransform!.dataYMax - _originalTransform!.dataYMin;
    final currentXRange = _transform!.dataXMax - _transform!.dataXMin;
    final currentYRange = _transform!.dataYMax - _transform!.dataYMin;
    final currentZoomX = originalXRange / currentXRange;
    final currentZoomY = originalYRange / currentYRange;

    // At high zoom (>2x), use current viewport boundaries instead of original data boundaries
    // This prevents infinite panning while allowing reasonable exploration
    final useCurrentViewport = currentZoomX > 2.0 || currentZoomY > 2.0;

    double originalLeft, originalRight, originalTop, originalBottom;
    
    if (useCurrentViewport) {
      // High zoom: track current viewport edges (left edge = 0, right edge = plotWidth)
      // We want to prevent panning when we already have substantial whitespace
      originalLeft = 0.0;
      originalRight = plotWidth;
      originalTop = 0.0;
      originalBottom = plotHeight;
    } else {
      // Low zoom: track original data boundaries to keep them visible
      originalLeft = _transform!.dataToPlot(_originalTransform!.dataXMin, 0.0).dx;
      originalRight = _transform!.dataToPlot(_originalTransform!.dataXMax, 0.0).dx;
      originalTop = _transform!.dataToPlot(0.0, _originalTransform!.dataYMax).dy;
      originalBottom = _transform!.dataToPlot(0.0, _originalTransform!.dataYMin).dy;
    }

    // Allowed bounds for data edges (with whitespace)
    final minLeftEdge = -plotWidth * maxWhitespaceFraction;
    final maxRightEdge = plotWidth * (1.0 + maxWhitespaceFraction);
    final minTopEdge = -plotHeight * maxWhitespaceFraction;
    final maxBottomEdge = plotHeight * (1.0 + maxWhitespaceFraction);

    double clampedDx = requestedDx;
    double clampedDy = requestedDy;

    // ========== X-AXIS CONSTRAINTS ==========
    // Calculate how far from limit each edge is
    // Positive = edge is inside allowed zone (has room to move further out)
    // Negative = edge is past limit (needs to move back in)
    final leftMargin = originalLeft - minLeftEdge;
    final rightMargin = maxRightEdge - originalRight;

    debugPrint('🔍 CLAMP: requested=($requestedDx, $requestedDy), zoom=${currentZoomX.toStringAsFixed(1)}x, mode=${useCurrentViewport ? "viewport" : "original"}');
    debugPrint('🔍 EDGES: L=$originalLeft/$minLeftEdge, R=$originalRight/$maxRightEdge');
    debugPrint('🔍 MARGINS: left=$leftMargin, right=$rightMargin');

    // Check if both X edges are past their limits (over-zoomed case)
    final bothXEdgesPastLimits = (leftMargin < 0) && (rightMargin < 0);

    if (bothXEdgesPastLimits) {
      // At extreme zoom, both edges are outside bounds
      // ONLY allow panning that brings edges back toward center (recovery)
      // Block panning that pushes edges further from center

      // When both edges are past limits:
      // - leftMargin < 0 means left edge is LEFT of allowed zone (too far left)
      // - rightMargin < 0 means right edge is RIGHT of allowed zone (too far right)
      // - To recover, need to move viewport TOWARD CENTER
      // - Positive dx = pan right in plot = data moves LEFT = edges move toward center ✓
      // - Negative dx = pan left in plot = data moves RIGHT = edges move away from center ✗

      if (requestedDx > 0) {
        // Panning right: data moves left, both edges move toward center (RECOVERY)
        // Allow this, but clamp to avoid overcorrection
        final maxRecoveryLeft = -leftMargin; // How far left edge needs to move right to reach limit
        final maxRecoveryRight = -rightMargin; // How far right edge needs to move left to reach limit
        // Use the smaller recovery distance to avoid overshooting
        final maxRecovery = maxRecoveryLeft < maxRecoveryRight ? maxRecoveryLeft : maxRecoveryRight;
        clampedDx = requestedDx.clamp(0, maxRecovery);
      } else if (requestedDx < 0) {
        // Panning left: data moves right, both edges move AWAY from center (WORSE)
        // Block this completely
        clampedDx = 0;
      }
    } else {
      // Normal case: at least one edge is within bounds
      // Apply standard directional constraints

      // CRITICAL UNDERSTANDING:
      // - Pan RIGHT (+dx) → data moves RIGHT → originalLeft/Right plot positions move LEFT
      // - Pan LEFT (-dx) → data moves LEFT → originalLeft/Right plot positions move RIGHT

      if (requestedDx > 0) {
        // Panning right: data moves right, so LEFT edge moves LEFT (toward left limit)
        // Check if left edge would hit/exceed its limit
        if (leftMargin < 0) {
          // Left edge already past limit, panning right makes it worse - block
          clampedDx = 0;
        } else if (leftMargin == 0) {
          // Left edge exactly at limit, block panning right
          clampedDx = 0;
        } else {
          // Left edge has room, clamp to not exceed limit
          clampedDx = requestedDx.clamp(0, leftMargin);
        }
      } else if (requestedDx < 0) {
        // Panning left: data moves left, so RIGHT edge moves RIGHT (toward right limit)
        // Check if right edge would hit/exceed its limit
        if (rightMargin < 0) {
          // Right edge already past limit, panning left makes it worse - block
          clampedDx = 0;
        } else if (rightMargin == 0) {
          // Right edge exactly at limit, block panning left
          clampedDx = 0;
        } else {
          // Right edge has room, clamp to not exceed limit
          // Negative requestedDx, so clamp to -rightMargin (max left pan)
          clampedDx = requestedDx.clamp(-rightMargin, 0);
        }
      }
    }

    // ========== Y-AXIS CONSTRAINTS ==========
    final topMargin = originalTop - minTopEdge;
    final bottomMargin = maxBottomEdge - originalBottom;

    final bothYEdgesPastLimits = (topMargin < 0) && (bottomMargin < 0);

    if (bothYEdgesPastLimits) {
      // At extreme zoom, both edges are outside bounds
      // Same logic as X-axis: allow recovery toward center only

      // When both edges are past limits:
      // - topMargin < 0 means top edge is ABOVE allowed zone (too far up)
      // - bottomMargin < 0 means bottom edge is BELOW allowed zone (too far down)
      // - To recover, need to move viewport TOWARD CENTER
      // - Positive dy = pan down in plot = data moves UP = edges move toward center ✓
      // - Negative dy = pan up in plot = data moves DOWN = edges move away from center ✗

      if (requestedDy > 0) {
        // Panning down: data moves up, both edges move toward center (RECOVERY)
        // Allow this, but clamp to avoid overcorrection
        final maxRecoveryTop = -topMargin; // How far top edge needs to move down to reach limit
        final maxRecoveryBottom = -bottomMargin; // How far bottom edge needs to move up to reach limit
        // Use the smaller recovery distance
        final maxRecovery = maxRecoveryTop < maxRecoveryBottom ? maxRecoveryTop : maxRecoveryBottom;
        clampedDy = requestedDy.clamp(0, maxRecovery);
      } else if (requestedDy < 0) {
        // Panning up: data moves down, both edges move AWAY from center (WORSE)
        // Block this completely
        clampedDy = 0;
      }
    } else {
      // Normal case: at least one edge is within bounds

      // CRITICAL UNDERSTANDING (Y-AXIS):
      // - Pan DOWN (+dy) → data moves DOWN → originalTop/Bottom plot positions move UP
      // - Pan UP (-dy) → data moves UP → originalTop/Bottom plot positions move DOWN

      if (requestedDy > 0) {
        // Panning down: data moves down, so TOP edge moves UP (toward top limit)
        // Check if top edge would hit/exceed its limit
        if (topMargin < 0) {
          // Top edge already past limit, panning down makes it worse - block
          clampedDy = 0;
        } else if (topMargin == 0) {
          // Top edge exactly at limit, block panning down
          clampedDy = 0;
        } else {
          // Top edge has room, clamp to not exceed limit
          clampedDy = requestedDy.clamp(0, topMargin);
        }
      } else if (requestedDy < 0) {
        // Panning up: data moves up, so BOTTOM edge moves DOWN (toward bottom limit)
        // Check if bottom edge would hit/exceed its limit
        if (bottomMargin < 0) {
          // Bottom edge already past limit, panning up makes it worse - block
          clampedDy = 0;
        } else if (bottomMargin == 0) {
          // Bottom edge exactly at limit, block panning up
          clampedDy = 0;
        } else {
          // Bottom edge has room, clamp to not exceed limit
          clampedDy = requestedDy.clamp(-bottomMargin, 0);
        }
      }
    }

    return (clampedDx, clampedDy);
  }

  // ============================================================================
  // Coordinate Space Conversion (Widget ↔ Plot)
  // ============================================================================

  /// Converts widget coordinates to plot coordinates.
  ///
  /// Widget coordinates include axis areas, plot coordinates are relative
  /// to the plot area (0,0 at top-left of plot area).
  Offset widgetToPlot(Offset widgetPosition) {
    return Offset(
      widgetPosition.dx - _plotArea.left,
      widgetPosition.dy - _plotArea.top,
    );
  }

  /// Converts plot coordinates to widget coordinates.
  ///
  /// Inverse of widgetToPlot().
  Offset plotToWidget(Offset plotPosition) {
    return Offset(
      plotPosition.dx + _plotArea.left,
      plotPosition.dy + _plotArea.top,
    );
  }

  /// Rebuilds the QuadTree spatial index from current elements.
  ///
  /// QuadTree operates in PLOT space (0,0 → plotWidth,plotHeight).
  void _rebuildSpatialIndex() {
    if (!hasSize || _plotArea.isEmpty) return;

    // QuadTree bounds = plot area (in plot space, not widget space)
    _spatialIndex = QuadTree(
      bounds: Offset.zero & _plotArea.size,
      maxElementsPerNode: 4,
      maxDepth: 8,
    );

    // Insert all chart elements
    for (final element in _elements) {
      _spatialIndex!.insert(element);

      // For annotations, also insert their resize handle elements
      if (element is SimulatedAnnotation) {
        final handleElements = element.createResizeHandleElements();
        for (final handle in handleElements) {
          _spatialIndex!.insert(handle);
        }
      }
    }
  }

  /// Rebuilds elements using the element generator with current transform.
  ///
  /// Called after zoom/pan operations to regenerate elements from original
  /// data coordinates using the updated transform.
  void _rebuildElementsWithTransform() {
    if (_elementGenerator == null || _transform == null) return;

    // Generate new elements using current transform
    _elements = _elementGenerator!(_transform!);

    // Rebuild spatial index with new elements
    _rebuildSpatialIndex();

    // Mark for repaint to show updated elements
    markNeedsPaint();
  }

  // ============================================================================
  // Layout
  // ============================================================================

  @override
  void performLayout() {
    // Chart respects parent constraints
    // Use constrain() to handle both bounded and unbounded constraints
    size = constraints.constrain(
      constraints.isTight
          ? constraints.smallest
          : Size(
              constraints.hasBoundedWidth ? constraints.maxWidth : 800,
              constraints.hasBoundedHeight ? constraints.maxHeight : 600,
            ),
    );

    // Calculate plot area (reserve space for axes)
    // Default margins if no axes
    double leftMargin = 10;
    double rightMargin = 10;
    double topMargin = 10;
    double bottomMargin = 10;

    // Reserve space for Y-axis (left side)
    if (_yAxis != null) {
      leftMargin = 60; // Space for Y-axis labels + axis label + padding
    }

    // Reserve space for X-axis (bottom)
    if (_xAxis != null) {
      bottomMargin = 50; // Space for X-axis labels + axis label + padding
    }

    // Calculate plot area
    _plotArea = Rect.fromLTRB(
      leftMargin,
      topMargin,
      size.width - rightMargin,
      size.height - bottomMargin,
    );

    // Update axis pixel ranges to match plot area
    _xAxis?.updatePixelRange(_plotArea.left, _plotArea.right);
    _yAxis?.updatePixelRange(_plotArea.top, _plotArea.bottom);

    // Create/update coordinate transform
    // Transform handles Data ↔ Plot conversion based on axis data ranges
    if (_xAxis != null && _yAxis != null) {
      // Only create initial transform if none exists, otherwise preserve zoom/pan state
      if (_transform == null) {
        // First time: create transform from axis data ranges
        _transform = ChartTransform(
          dataXMin: _xAxis!.dataMin,
          dataXMax: _xAxis!.dataMax,
          dataYMin: _yAxis!.dataMin,
          dataYMax: _yAxis!.dataMax,
          plotWidth: _plotArea.width,
          plotHeight: _plotArea.height,
          invertY: true, // Standard chart convention (Y=0 at bottom)
        );

        // Capture original transform for reset and constraint calculations
        _originalTransform = _transform;
        debugPrint('📸 Original transform captured: dataX=${_xAxis!.dataMin}..${_xAxis!.dataMax}, dataY=${_yAxis!.dataMin}..${_yAxis!.dataMax}');
      } else {
        // Subsequent layouts: preserve current data ranges (zoom/pan state),
        // only update plot dimensions if they changed
        if (_transform!.plotWidth != _plotArea.width || _transform!.plotHeight != _plotArea.height) {
          _transform = _transform!.copyWith(
            plotWidth: _plotArea.width,
            plotHeight: _plotArea.height,
          );
        }
      }

      // If using element generator, regenerate elements with new transform
      if (_elementGenerator != null) {
        _rebuildElementsWithTransform();
        return; // _rebuildElementsWithTransform already rebuilds spatial index
      }
    }

    // Rebuild spatial index when size changes (for static elements)
    _rebuildSpatialIndex();
  }

  // ============================================================================
  // Hit Testing
  // ============================================================================

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Always claim hit test (chart consumes all pointer events in its bounds)
    if (!size.contains(position)) {
      return false;
    }

    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  /// Finds the top-priority element at the given position.
  ///
  /// Uses QuadTree for O(log n) spatial query, then performs precise hit
  /// testing and priority-based conflict resolution.
  ///
  /// **Coordinate Conversion**: Position is in widget space, converted to
  /// plot space before querying QuadTree (which operates in plot space).
  ///
  /// Returns the element with highest priority that passes hitTest(), or null.
  ///
  /// **Conflict Resolution** (per CONFLICT_RESOLUTION_TABLE.md):
  /// - Query QuadTree for candidate elements at position
  /// - Filter to elements that pass precise hitTest()
  /// - Return highest priority element
  ChartElement? hitTestElements(Offset widgetPosition) {
    if (_spatialIndex == null) return null;

    // Convert widget coordinates to plot coordinates
    final plotPosition = widgetToPlot(widgetPosition);

    // Query spatial index for candidate elements (in plot space)
    // Use 18px radius to account for edge zones that extend 8px outside bounds
    // (10px base tolerance + 8px max edge width = 18px total)
    // NOTE: QuadTree now inserts elements into ALL overlapping quadrants,
    // so this smaller radius is sufficient (previously needed 50px due to center-only insertion bug)
    final candidates = _spatialIndex!.query(plotPosition, radius: 18);

    if (candidates.isEmpty) return null;

    // Filter to elements that pass precise hit test
    // Elements use plot coordinates, so pass plot position
    final hits = candidates.where((e) => e.hitTest(plotPosition)).toList();

    if (hits.isEmpty) return null;

    // Return highest priority element
    hits.sort((a, b) => b.priority.compareTo(a.priority));
    return hits.first;
  }

  /// Finds all elements within a rectangular region (for box select).
  ///
  /// **Coordinate Conversion**: Rect is in widget space, converted to plot
  /// space before querying QuadTree.
  ///
  /// Per conflict resolution scenario 14: Box select only captures datapoints.
  List<ChartElement> hitTestRect(Rect widgetRect) {
    if (_spatialIndex == null) return [];

    // Convert widget rect to plot rect
    final plotTopLeft = widgetToPlot(widgetRect.topLeft);
    final plotBottomRight = widgetToPlot(widgetRect.bottomRight);
    final plotRect = Rect.fromPoints(plotTopLeft, plotBottomRight);

    final candidates = _spatialIndex!.queryRect(plotRect);

    // Filter to datapoints only (per conflict resolution)
    // and elements whose center is inside rect (in plot space)
    return candidates.where((e) => e.elementType == ChartElementType.datapoint && plotRect.contains(e.bounds.center)).toList();
  }

  /// Hit tests for resize handles on annotations.
  ///
  /// Returns annotation and direction if a handle is hit, null otherwise.
  ///
  /// Performs resize operation during drag.
  void _performResize(Offset currentPosition, Offset startPosition) {
    if (_resizingAnnotation == null || _activeResizeDirection == null || _resizeStartBounds == null) {
      return;
    }

    final delta = currentPosition - startPosition;
    final oldBounds = _resizeStartBounds!;
    Rect newBounds;

    // Calculate new bounds based on resize direction
    switch (_activeResizeDirection!) {
      case ResizeDirection.topLeft:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top + delta.dy,
          oldBounds.right,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top + delta.dy,
          oldBounds.right + delta.dx,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom + delta.dy,
        );
        break;
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right + delta.dx,
          oldBounds.bottom + delta.dy,
        );
        break;
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top + delta.dy,
          oldBounds.right,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right + delta.dx,
          oldBounds.bottom,
        );
        break;
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(
          oldBounds.left,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom + delta.dy,
        );
        break;
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(
          oldBounds.left + delta.dx,
          oldBounds.top,
          oldBounds.right,
          oldBounds.bottom,
        );
        break;
    }

    // Apply minimum size constraints (40x40 minimum)
    const minSize = 40.0;
    if (newBounds.width < minSize || newBounds.height < minSize) {
      // Don't allow resize below minimum
      return;
    }

    // Update annotation bounds
    // Note: Spatial index will be rebuilt on pointer up for performance
    _resizingAnnotation!.updateBounds(newBounds);
  } // ============================================================================
  // Event Handling
  // ============================================================================

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    // Modal states block all events except themselves
    if (coordinator.isModal) {
      return;
    }

    // CRITICAL: Use event.localPosition, NOT entry.localPosition!
    // entry.localPosition is captured at hit test time (pointer down) and never updates.
    // event.localPosition gives us the current position for move events.
    final localPosition = event.localPosition;

    if (event is PointerDownEvent) {
      _handlePointerDown(event, localPosition);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event, localPosition);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event, localPosition);
    } else if (event is PointerHoverEvent) {
      _handlePointerHover(event, localPosition);
    } else if (event is PointerScrollEvent) {
      _handlePointerScroll(event, localPosition);
    }
  }

  void _handlePointerDown(PointerDownEvent event, Offset position) {
    // Use unified hit testing with priority-based conflict resolution
    final hitElement = hitTestElements(position);

    debugPrint('🖱️ PointerDown: buttons=${event.buttons} (middle=$kMiddleMouseButton, primary=$kPrimaryMouseButton)');
    coordinator.startInteraction(position, element: hitElement);

    // Check if we hit a resize handle (priority 7)
    if (event.buttons == kPrimaryMouseButton && hitElement is ResizeHandleElement) {
      // Clicked on resize handle - extract parent annotation and direction
      final annotation = hitElement.parentAnnotation;
      final direction = hitElement.direction;

      // Select the annotation first if not already selected
      if (!annotation.isSelected) {
        coordinator.selectElement(annotation);
      }

      _activeResizeDirection = direction;
      _resizingAnnotation = annotation;
      _resizeStartBounds = annotation.bounds;
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);
      markNeedsPaint();
      return;
    }

    // Per conflict resolution: Different buttons have different behaviors
    if (event.buttons == kMiddleMouseButton) {
      // Middle-click: EXCLUSIVELY pan (per scenario 6)
      debugPrint('🖱️ Middle button DOWN detected at $position');
      coordinator.claimMode(InteractionMode.panning);
      // Store initial pan position in widget space
      _lastPanPosition = position;
      debugPrint('🖱️ Pan mode claimed, _lastPanPosition set to $position');
    } else if (event.buttons == kSecondaryMouseButton) {
      // Right-click: EXCLUSIVELY context menu (per scenario 8)
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: hitElement);
    } else if (event.buttons == kPrimaryMouseButton) {
      // Left-click: Select, or start drag/box-select (determined on move)
      if (hitElement != null) {
        // Clicked on element - select it (or toggle if Ctrl)
        if (coordinator.isCtrlPressed) {
          coordinator.toggleElementSelection(hitElement);
        } else {
          coordinator.selectElement(hitElement);
        }
        coordinator.claimMode(InteractionMode.selecting, element: hitElement);
        onElementClick?.call(hitElement, event);
      } else {
        // Clicked on empty area - clear selection and prepare for box select
        coordinator.clearSelection();
        onEmptyAreaClick?.call(position, event);
        markNeedsPaint();
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event, Offset position) {
    if (!coordinator.isInteracting) return;

    final startPos = coordinator.interactionStartPosition;
    if (startPos == null) return;

    // Handle resize dragging
    if (coordinator.currentMode == InteractionMode.resizingAnnotation &&
        _resizingAnnotation != null &&
        _activeResizeDirection != null &&
        _resizeStartBounds != null) {
      _performResize(position, startPos);
      markNeedsPaint();
      return;
    }

    // Middle-button drag = pan (per conflict resolution scenario 6)
    if (event.buttons == kMiddleMouseButton && coordinator.currentMode == InteractionMode.panning) {
      debugPrint(
          '🖱️ Middle button MOVE: buttons=${event.buttons}, mode=${coordinator.currentMode}, lastPos=$_lastPanPosition, transform=${_transform != null}');
      if (_lastPanPosition != null && _transform != null && _originalTransform != null) {
        // Calculate delta in widget space
        final widgetDelta = position - _lastPanPosition!;

        // Convert widget delta to plot space (widget space -> plot space is just offset removal)
        final plotDelta = widgetToPlot(position) - widgetToPlot(_lastPanPosition!);

        // Clamp pan delta BEFORE applying (prevents overshoot/snap-back)
        final (clampedDx, clampedDy) = _clampPanDelta(-plotDelta.dx, -plotDelta.dy);

        // Apply constrained pan (won't violate boundaries)
        // PERFORMANCE: Only update transform during drag, defer element regeneration until pointer up
        _transform = _transform!.pan(clampedDx, clampedDy);

        // Update last position for next move event
        _lastPanPosition = position;

        // Just repaint (no element regeneration during drag for performance)
        markNeedsPaint();

        if (clampedDx != -plotDelta.dx || clampedDy != -plotDelta.dy) {
          debugPrint('🔒 Pan constrained: requested=${Offset(-plotDelta.dx, -plotDelta.dy)} → allowed=${Offset(clampedDx, clampedDy)}');
        } else {
          debugPrint('🖱️ Middle-button pan: widgetDelta=$widgetDelta, plotDelta=$plotDelta (deferred regen)');
        }
      }
      return;
    }

    // Left-button drag: datapoint drag, annotation drag, or box select
    if (event.buttons == kPrimaryMouseButton) {
      final startElement = coordinator.interactionStartElement;

      // Update box selection rectangle if already in box select mode
      if (coordinator.currentMode == InteractionMode.boxSelecting) {
        coordinator.updateBoxSelection(startPos, position);
        final newRect = coordinator.boxSelectionRect;

        // Track cursor position for crosshair rendering
        _cursorPosition = position;

        // Update preview selection with elements currently in box
        if (newRect != null) {
          final previewElements = hitTestRect(newRect);
          coordinator.updatePreviewSelection(previewElements.toSet());
        }

        markNeedsPaint();
        return;
      }

      if (startElement != null && startElement.isDraggable) {
        // Dragging an element (per scenarios 5, 10, 13)
        if (startElement.elementType == ChartElementType.datapoint) {
          coordinator.claimMode(InteractionMode.draggingDataPoint, element: startElement);
        } else if (startElement.elementType == ChartElementType.annotation) {
          coordinator.claimMode(InteractionMode.draggingAnnotation, element: startElement);
        }
      } else if (coordinator.shouldStartBoxSelect(position)) {
        // Box selection (per scenario 5: >5px drag on empty area)
        coordinator.claimMode(InteractionMode.boxSelecting);
        coordinator.updateBoxSelection(startPos, position);
        markNeedsPaint(); // Repaint to show box selection rectangle
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event, Offset position) {
    // Complete box selection if active
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        final selectedElements = hitTestRect(boxRect);

        // Clear preview before committing actual selection
        coordinator.clearPreviewSelection();
        coordinator.addToSelection(selectedElements.toSet());
      }
    }

    // Rebuild spatial index if we just finished resizing
    // (Updates resize handle positions to match new annotation bounds)
    if (coordinator.currentMode == InteractionMode.resizingAnnotation) {
      _rebuildSpatialIndex();
    }

    // Clear resize state (annotation will revert to original size on next rebuild)
    _activeResizeDirection = null;
    _resizingAnnotation = null;
    _resizeStartBounds = null;

    // Clear pan state and regenerate elements if we were panning
    // (Elements were not regenerated during drag for performance)
    final wasPanning = coordinator.currentMode == InteractionMode.panning;
    _lastPanPosition = null;
    if (wasPanning && _elementGenerator != null) {
      _rebuildElementsWithTransform();
      debugPrint('🔄 Pan ended - regenerated elements with final transform');
    }

    // Clear cursor position
    _cursorPosition = null;

    // Release interaction
    coordinator.endInteraction();
    coordinator.releaseMode();
    markNeedsPaint();
  }

  void _handlePointerHover(PointerHoverEvent event, Offset position) {
    // Track cursor position for crosshair rendering
    _cursorPosition = position;

    // Per conflict resolution scenario 7: Hover is passive
    // Per scenario 12: Hover/tooltips suspended during panning
    if (coordinator.isPanning) {
      coordinator.setHoveredElement(null);
      onCursorChange?.call(SystemMouseCursors.basic);
      return;
    }

    // Use unified hit testing with priority-based conflict resolution
    final hitElement = hitTestElements(position);

    // Check if we hit a resize handle (priority 7)
    if (hitElement is ResizeHandleElement) {
      // Hovering over resize handle - show resize cursor
      final cursor = _getCursorForResizeDirection(hitElement.direction);
      onCursorChange?.call(cursor);
      coordinator.setHoveredElement(hitElement.parentAnnotation);
      onElementHover?.call(hitElement.parentAnnotation);
      markNeedsPaint();
      return;
    }

    // For any other element (datapoint=9, series=8, annotation=6, etc.)
    // Priority system ensures the highest-priority element wins
    onCursorChange?.call(SystemMouseCursors.basic);
    coordinator.setHoveredElement(hitElement);
    onElementHover?.call(hitElement);
    markNeedsPaint();
  }

  /// Gets the appropriate cursor for a resize direction.
  MouseCursor _getCursorForResizeDirection(ResizeDirection direction) {
    switch (direction) {
      case ResizeDirection.topLeft:
      case ResizeDirection.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case ResizeDirection.topRight:
      case ResizeDirection.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case ResizeDirection.top:
      case ResizeDirection.bottom:
        return SystemMouseCursors.resizeUpDown;
      case ResizeDirection.left:
      case ResizeDirection.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  void _handlePointerScroll(PointerScrollEvent event, Offset position) {
    // Check for Shift modifier to trigger zoom
    if (coordinator.isShiftPressed && _transform != null && _elementGenerator != null && _originalTransform != null) {
      // Claim zooming mode
      coordinator.claimMode(InteractionMode.zooming);

      // Calculate zoom factor from scroll delta
      // Positive scrollDelta.dy = scroll down = zoom out
      // Negative scrollDelta.dy = scroll up = zoom in
      final double scrollAmount = event.scrollDelta.dy;
      const double zoomSensitivity = 0.001; // Adjust for comfortable zoom speed
      final double zoomFactor = 1.0 - (scrollAmount * zoomSensitivity);

      debugPrint('🔍 ZOOM: factor=$zoomFactor, scrollDelta=${event.scrollDelta.dy}');

      // Convert cursor position (widget space) to plot space
      final Offset plotPosition = widgetToPlot(position);

      // Apply zoom centered on cursor position with constraints
      final tentativeTransform = _transform!.zoom(zoomFactor, plotPosition);
      _transform = _clampZoomLevel(tentativeTransform);

      // Regenerate elements with new transform
      _rebuildElementsWithTransform();

      debugPrint('🔍 Transform updated: dataX=${_transform!.dataXMin}..${_transform!.dataXMax}');

      // Release zoom mode after short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (coordinator.currentMode == InteractionMode.zooming) {
          coordinator.releaseMode();
        }
      });
    } else {
      debugPrint(
          '⚠️ Scroll without zoom: shift=${coordinator.isShiftPressed}, transform=${_transform != null}, generator=${_elementGenerator != null}');

      // Without Shift, just claim mode for compatibility
      coordinator.claimMode(InteractionMode.zooming);

      // Release zoom mode after short delay (zoom is instant, not continuous)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (coordinator.currentMode == InteractionMode.zooming) {
          coordinator.releaseMode();
        }
      });
    }
  }

  // ============================================================================
  // Painting
  // ============================================================================

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // Paint background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Paint axes (behind all chart elements)
    if (_xAxis != null) {
      AxisRenderer(_xAxis!).paint(canvas, size, _plotArea);
    }
    if (_yAxis != null) {
      AxisRenderer(_yAxis!).paint(canvas, size, _plotArea);
    }

    // Clip canvas to plot area to prevent elements from rendering over axes
    // Elements are positioned in plot space, but painting happens in widget space
    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Offset.zero & _plotArea.size);

    // Paint all elements (in order: lowest to highest priority)
    // Elements are in plot space, so no coordinate conversion needed during paint
    final sortedElements = _elements.toList()..sort((a, b) => a.priority.compareTo(b.priority));

    for (final element in sortedElements) {
      element.paint(canvas, _plotArea.size);
    }

    canvas.restore(); // Restore canvas state (removes clipping and translation from plot area)

    // Paint overlays in widget space (crosshair, selection box, preview indicators)
    // These are painted AFTER plot elements but BEFORE final canvas.restore()
    // so they appear in widget coordinates with the initial offset applied

    // Paint preview selection indicators (during box drag)
    // Draw with different visual style than actual selection (dashed outline)
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final previewElements = coordinator.previewSelectedElements;
      for (final element in previewElements) {
        // Only draw preview for elements that aren't already selected
        if (!element.isSelected && element.elementType == ChartElementType.datapoint) {
          // Convert plot bounds to widget bounds for preview rendering
          final plotBounds = element.bounds;
          final widgetCenter = plotToWidget(plotBounds.center);
          final radius = plotBounds.width / 2;

          // Draw dashed preview ring (different from solid selection ring)
          final previewPaint = Paint()
            ..color = const Color(0x8000AAFF) // Semi-transparent blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(widgetCenter, radius + 3, previewPaint);
        }
      }
    }

    // Paint box selection rectangle if active (in widget space)
    if (coordinator.currentMode == InteractionMode.boxSelecting) {
      final boxRect = coordinator.boxSelectionRect;
      if (boxRect != null) {
        // boxRect is already in widget space, draw it directly
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = const Color(0x4000AAFF)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = const Color(0xFF0088FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Draw crosshair at cursor position (in widget space)
    final cursorPos = _cursorPosition;
    if (cursorPos != null) {
      final crosshairPaint = Paint()
        ..color = const Color(0x80666666) // Semi-transparent gray
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Horizontal line across entire widget
      canvas.drawLine(
        Offset(0, cursorPos.dy),
        Offset(size.width, cursorPos.dy),
        crosshairPaint,
      );

      // Vertical line across entire widget
      canvas.drawLine(
        Offset(cursorPos.dx, 0),
        Offset(cursorPos.dx, size.height),
        crosshairPaint,
      );
    }

    canvas.restore(); // Final restore (removes initial offset translation)
  }

  // ============================================================================
  // Debug
  // ============================================================================

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('elementCount', _elements.length));
    properties.add(DiagnosticsProperty<QuadTreeStats>('spatialIndexStats', _spatialIndex?.stats));
    properties.add(StringProperty('coordinatorState', coordinator.debugState()));
  }
}
