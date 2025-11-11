// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../axis/axis.dart' as chart_axis;
import '../axis/axis_renderer.dart';
import '../coordinates/chart_transform.dart';
import '../elements/resize_handle_element.dart';
import '../elements/simulated_annotation.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/hit_test_strategy.dart';
import '../interaction/core/interaction_mode.dart';
import '../models/chart_theme.dart';
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
    ChartTheme? theme,
    this.onElementClick,
    this.onElementHover,
    this.onEmptyAreaClick,
    this.onCursorChange,
  })  : _elementGenerator = elementGenerator,
        _theme = theme,
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
  ElementGenerator? _elementGenerator;

  /// Current theme for the chart (colors, styles, etc.)
  ChartTheme? _theme;

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
  /// If transform exists (zoomed/panned state), syncs new axis with current viewport.
  void setXAxis(chart_axis.Axis? axis) {
    if (_xAxis == axis) {
      debugPrint('🔄 setXAxis: Same axis reference, skipping');
      return;
    }

    debugPrint('🔄 setXAxis: Setting new axis, hasTransform=${_transform != null}, hasOriginalTransform=${_originalTransform != null}');
    if (axis != null) {
      debugPrint('   New axis dataRange: [${axis.dataMin}, ${axis.dataMax}]');
    }
    if (_transform != null) {
      debugPrint('   Current transform: dataX=[${_transform!.dataXMin}, ${_transform!.dataXMax}]');
    }

    _xAxis = axis;

    // If we have an existing transform (zoomed/panned state), sync the new axis to match viewport
    if (_transform != null && axis != null) {
      axis.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
      debugPrint('✅ setXAxis: Synced new axis to current viewport X=[${_transform!.dataXMin}, ${_transform!.dataXMax}]');
    }

    markNeedsLayout();
  }

  /// Sets the Y-axis for the chart.
  ///
  /// Triggers layout and paint when axis is changed.
  /// If transform exists (zoomed/panned state), syncs new axis with current viewport.
  void setYAxis(chart_axis.Axis? axis) {
    if (_yAxis == axis) {
      debugPrint('🔄 setYAxis: Same axis reference, skipping');
      return;
    }

    debugPrint('🔄 setYAxis: Setting new axis, hasTransform=${_transform != null}, hasOriginalTransform=${_originalTransform != null}');
    if (axis != null) {
      debugPrint('   New axis dataRange: [${axis.dataMin}, ${axis.dataMax}]');
    }
    if (_transform != null) {
      debugPrint('   Current transform: dataY=[${_transform!.dataYMin}, ${_transform!.dataYMax}]');
    }

    _yAxis = axis;

    // If we have an existing transform (zoomed/panned state), sync the new axis to match viewport
    if (_transform != null && axis != null) {
      axis.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
      debugPrint('✅ setYAxis: Synced new axis to current viewport Y=[${_transform!.dataYMin}, ${_transform!.dataYMax}]');
    }

    markNeedsLayout();
  }

  /// Sets the theme for the chart.
  ///
  /// Updates colors for background, grid, axes, etc.
  void setTheme(ChartTheme? theme) {
    if (_theme == theme) return;
    _theme = theme;
    markNeedsPaint();
  }

  /// Updates the element generator function.
  ///
  /// Regenerates elements using the new generator if transform is available.
  void setElementGenerator(ElementGenerator? generator) {
    debugPrint('🔄 setElementGenerator called: hasTransform=${_transform != null}');
    // NOTE: Don't check if generator == _elementGenerator!
    // Closures are never equal even if functionally identical,
    // so we must always update and regenerate when called.
    _elementGenerator = generator;

    // Regenerate elements with new generator if we have a transform
    if (_transform != null && _elementGenerator != null) {
      debugPrint('🎨 Regenerating elements due to generator change (likely theme change)');
      _rebuildElementsWithTransform();
    }
  }

  /// Programmatically zoom the chart.
  ///
  /// **Parameters**:
  /// - `factor`: Zoom factor (> 1.0 = zoom in, < 1.0 = zoom out)
  /// - `plotCenter`: Center point in plot space (if null, uses plot center)
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void zoomChart(double factor, {Offset? plotCenter}) {
    debugPrint(
        '🔍 zoomChart called: factor=$factor, hasTransform=${_transform != null}, hasGenerator=${_elementGenerator != null}, hasOriginal=${_originalTransform != null}');

    if (_transform == null || _elementGenerator == null || _originalTransform == null) {
      debugPrint(
          '❌ Cannot zoom: transform=${_transform != null}, elementGenerator=${_elementGenerator != null}, originalTransform=${_originalTransform != null}');
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

    // Update axes to reflect new viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    debugPrint('✅ Keyboard zoom: factor=$factor, center=$center');
  }

  /// Programmatically pan the chart.
  ///
  /// **Parameters**:
  /// - `plotDx`, `plotDy`: Pan delta in plot pixels
  ///
  /// Only works when using elementGenerator (for element regeneration).
  void panChart(double plotDx, double plotDy) {
    debugPrint(
        '🔄 panChart called: dx=$plotDx, dy=$plotDy, hasTransform=${_transform != null}, hasGenerator=${_elementGenerator != null}, hasOriginal=${_originalTransform != null}');

    if (_transform == null || _elementGenerator == null || _originalTransform == null) {
      debugPrint(
          '❌ Cannot pan: transform=${_transform != null}, elementGenerator=${_elementGenerator != null}, originalTransform=${_originalTransform != null}');
      return;
    }

    // Clamp pan delta BEFORE applying (prevents overshoot/snap-back)
    final (clampedDx, clampedDy) = _clampPanDelta(plotDx, plotDy);

    // Apply constrained pan (won't violate boundaries)
    _transform = _transform!.pan(clampedDx, clampedDy);

    // Update axes to reflect new viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    if (clampedDx != plotDx || clampedDy != plotDy) {
      debugPrint(' Pan constrained: requested=($plotDx, $plotDy) to allowed=($clampedDx, $clampedDy)');
    } else {
      debugPrint('✅ Pan applied: dx=$plotDx, dy=$plotDy');
    }
  }

  /// Reset view to original zoom/pan state.
  void resetView() {
    if (_originalTransform == null || _elementGenerator == null) {
      debugPrint(' Cannot reset: originalTransform or elementGenerator not available');
      return;
    }

    // Restore original data ranges, preserve current plot dimensions
    _transform = _originalTransform!.copyWith(plotWidth: _plotArea.width, plotHeight: _plotArea.height);

    // Update axes to reflect reset viewport
    _updateAxesFromTransform();

    // Regenerate elements
    _rebuildElementsWithTransform();

    debugPrint(' View reset to original');
  }

  /// Updates axes to reflect the current transform's data ranges.
  ///
  /// Called after zoom/pan operations to keep axis labels synchronized
  /// with the visible viewport. The reference implementation does this
  /// dynamically during paint, but our prototype uses a separate Axis
  /// class that needs explicit updates.
  void _updateAxesFromTransform() {
    if (_transform == null) return;

    // Update X-axis with current viewport's X range
    _xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);

    // Update Y-axis with current viewport's Y range
    _yAxis?.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);

    debugPrint(' Axes updated: X=[${_transform!.dataXMin}, ${_transform!.dataXMax}], Y=[${_transform!.dataYMin}, ${_transform!.dataYMax}]');
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
    final bool needsClampX = currentZoomX < minZoomLevel || currentZoomX > maxZoomLevel;
    final bool needsClampY = currentZoomY < minZoomLevel || currentZoomY > maxZoomLevel;

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

    debugPrint(' Zoom clamped: X=$currentZoomX to $clampedZoomX, Y=$currentZoomY to $clampedZoomY');

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

  /// Clamps pan delta to enforce viewport bounds (limit whitespace).
  ///
  /// **Correct Viewport Position Constraint Algorithm**:
  ///
  /// **Core Concept**: Track WHERE THE VIEWPORT IS in data space, not where
  /// original boundaries appear in viewport. This makes constraints zoom-independent.
  ///
  /// **Algorithm**:
  /// 1. Convert requested plot delta to data delta
  /// 2. Calculate tentative new viewport position (dataXMin, dataYMin)
  /// 3. Calculate max allowed whitespace in data space (zoom-aware)
  /// 4. Calculate allowed bounds for viewport position
  /// 5. Clamp tentative position to allowed bounds
  /// 6. Calculate actual movement and convert back to plot delta
  ///
  /// **Constraint**: Viewport can show up to 10% whitespace beyond original data.
  /// - Example at 1x zoom (800px plot, 1000 data range):
  ///   maxWhitespace = 800 * 0.1 * (1000/800) = 100 data units
  /// - Example at 2x zoom (800px plot, 500 data range):
  ///   maxWhitespace = 800 * 0.1 * (500/800) = 50 data units
  ///
  /// **Result**: Consistent 10% whitespace at ALL zoom levels. Zoom-independent!
  (double, double) _clampPanDelta(double requestedPlotDx, double requestedPlotDy) {
    if (_originalTransform == null || _transform == null) {
      return (requestedPlotDx, requestedPlotDy);
    }

    // 1. Convert requested plot delta to data space
    // CRITICAL: Match the inversion logic in ChartTransform.pan()!
    final dataPerPixelX = _transform!.dataPerPixelX;
    final dataPerPixelY = _transform!.dataPerPixelY;
    final requestedDataDx = requestedPlotDx * dataPerPixelX;
    final requestedDataDy = _transform!.invertY
        ? -requestedPlotDy * dataPerPixelY // Invert Y movement (match pan() logic)
        : requestedPlotDy * dataPerPixelY;

    // 2. Calculate tentative new viewport position in data space
    final tentativeDataXMin = _transform!.dataXMin + requestedDataDx;
    final tentativeDataYMin = _transform!.dataYMin + requestedDataDy;

    // 3. Calculate maximum allowed whitespace in data space (zoom-aware!)
    // At 1x zoom: maxWhitespace = plotWidth * 0.1 * (originalRange / plotWidth) = originalRange * 0.1
    // At 2x zoom: maxWhitespace = plotWidth * 0.1 * (originalRange/2 / plotWidth) = originalRange * 0.05
    // This ensures 10% whitespace in VIEWPORT, which scales correctly with zoom
    final maxWhitespaceDataX = _transform!.plotWidth * maxWhitespaceFraction * dataPerPixelX;
    final maxWhitespaceDataY = _transform!.plotHeight * maxWhitespaceFraction * dataPerPixelY;

    // 4. Calculate allowed bounds for viewport position
    // Viewport left edge (dataXMin) can range from:
    //   - Minimum: originalDataXMin - maxWhitespace (show whitespace on left)
    //   - Maximum: originalDataXMax - currentViewportWidth + maxWhitespace (show whitespace on right)
    final minAllowedDataXMin = _originalTransform!.dataXMin - maxWhitespaceDataX;
    final maxAllowedDataXMin = _originalTransform!.dataXMax - _transform!.dataXRange + maxWhitespaceDataX;

    final minAllowedDataYMin = _originalTransform!.dataYMin - maxWhitespaceDataY;
    final maxAllowedDataYMin = _originalTransform!.dataYMax - _transform!.dataYRange + maxWhitespaceDataY;

    // 5. Clamp tentative viewport position to allowed bounds
    final clampedDataXMin = tentativeDataXMin.clamp(minAllowedDataXMin, maxAllowedDataXMin);
    final clampedDataYMin = tentativeDataYMin.clamp(minAllowedDataYMin, maxAllowedDataYMin);

    // 6. Calculate actual movement allowed and convert back to plot space
    // CRITICAL: Reverse the inversion applied in step 1!
    final actualDataDx = clampedDataXMin - _transform!.dataXMin;
    final actualDataDy = clampedDataYMin - _transform!.dataYMin;

    final actualPlotDx = actualDataDx / dataPerPixelX;
    final actualPlotDy = _transform!.invertY
        ? -actualDataDy / dataPerPixelY // Reverse Y inversion
        : actualDataDy / dataPerPixelY;

    // Debug output (optional - can be removed in production)
    if (actualPlotDx != requestedPlotDx || actualPlotDy != requestedPlotDy) {
      debugPrint(' PAN CONSTRAINED: requested=($requestedPlotDx, $requestedPlotDy) to allowed=($actualPlotDx, $actualPlotDy)');
    }

    return (actualPlotDx, actualPlotDy);
  }

  // ============================================================================
  // Coordinate Space Conversion (Widget ↔ Plot)
  // ============================================================================

  /// Converts widget coordinates to plot coordinates.
  ///
  /// Widget coordinates include axis areas, plot coordinates are relative
  /// to the plot area (0,0 at top-left of plot area).
  Offset widgetToPlot(Offset widgetPosition) {
    return Offset(widgetPosition.dx - _plotArea.left, widgetPosition.dy - _plotArea.top);
  }

  /// Converts plot coordinates to widget coordinates.
  ///
  /// Inverse of widgetToPlot().
  Offset plotToWidget(Offset plotPosition) {
    return Offset(plotPosition.dx + _plotArea.left, plotPosition.dy + _plotArea.top);
  }

  /// Rebuilds the QuadTree spatial index from current elements.
  ///
  /// QuadTree operates in PLOT space (0,0 → plotWidth,plotHeight).
  void _rebuildSpatialIndex() {
    if (!hasSize || _plotArea.isEmpty) return;

    // QuadTree bounds = plot area (in plot space, not widget space)
    _spatialIndex = QuadTree(bounds: Offset.zero & _plotArea.size, maxElementsPerNode: 4, maxDepth: 8);

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
    final generator = _elementGenerator;
    final transform = _transform;
    if (generator == null || transform == null) {
      debugPrint(' REBUILD ELEMENTS SKIPPED: generator=${generator != null}, transform=${transform != null}');
      return;
    }

    // Generate new elements using current transform
    _elements = generator(transform);
    debugPrint(
      ' ELEMENTS REGENERATED: count=${_elements.length}, dataX=${transform.dataXMin.toStringAsFixed(2)}..${transform.dataXMax.toStringAsFixed(2)}',
    );

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
          : Size(constraints.hasBoundedWidth ? constraints.maxWidth : 800, constraints.hasBoundedHeight ? constraints.maxHeight : 600),
    );

    // Calculate plot area (reserve space for axes)
    // Default margins if no axes
    double leftMargin = 10;
    const double rightMargin = 10;
    const double topMargin = 10;
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
    _plotArea = Rect.fromLTRB(leftMargin, topMargin, size.width - rightMargin, size.height - bottomMargin);

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
        debugPrint(' Original transform captured: dataX=${_xAxis!.dataMin}..${_xAxis!.dataMax}, dataY=${_yAxis!.dataMin}..${_yAxis!.dataMax}');
      } else {
        // Subsequent layouts: preserve current data ranges (zoom/pan state),
        // only update plot dimensions if they changed
        if (_transform!.plotWidth != _plotArea.width || _transform!.plotHeight != _plotArea.height) {
          _transform = _transform!.copyWith(plotWidth: _plotArea.width, plotHeight: _plotArea.height);
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
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
        break;
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy, oldBounds.right + delta.dx, oldBounds.bottom);
        break;
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top, oldBounds.right, oldBounds.bottom + delta.dy);
        break;
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right + delta.dx, oldBounds.bottom + delta.dy);
        break;
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
        break;
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right + delta.dx, oldBounds.bottom);
        break;
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top, oldBounds.right, oldBounds.bottom + delta.dy);
        break;
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top, oldBounds.right, oldBounds.bottom);
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

    debugPrint(' PointerDown: buttons=${event.buttons} (middle=$kMiddleMouseButton, primary=$kPrimaryMouseButton)');
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
      debugPrint(' Middle button DOWN detected at $position');
      coordinator.claimMode(InteractionMode.panning);
      // Store initial pan position in widget space
      _lastPanPosition = position;
      debugPrint(' Pan mode claimed, _lastPanPosition set to $position');
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
        ' Middle button MOVE: buttons=${event.buttons}, mode=${coordinator.currentMode}, lastPos=$_lastPanPosition, transform=${_transform != null}',
      );
      if (_lastPanPosition != null && _transform != null && _originalTransform != null) {
        // Calculate delta in widget space
        final widgetDelta = position - _lastPanPosition!;

        // Convert widget delta to plot space (widget space -> plot space is just offset removal)
        final plotDelta = widgetToPlot(position) - widgetToPlot(_lastPanPosition!);

        debugPrint(' BEFORE CLAMP: position=$position, lastPos=$_lastPanPosition, plotDelta=$plotDelta');

        // Clamp pan delta BEFORE applying (prevents overshoot/snap-back)
        final (clampedDx, clampedDy) = _clampPanDelta(-plotDelta.dx, -plotDelta.dy);

        // Apply constrained pan (won't violate boundaries)
        _transform = _transform!.pan(clampedDx, clampedDy);

        // Update axes to match new transform
        _updateAxesFromTransform();

        // Regenerate elements with new transform for live visual feedback
        if (_elementGenerator != null) {
          _rebuildElementsWithTransform();
        }

        // Update last position for next move event
        _lastPanPosition = position;

        // Repaint with updated elements
        markNeedsPaint();

        if (clampedDx != -plotDelta.dx || clampedDy != -plotDelta.dy) {
          debugPrint(' Pan constrained: requested=${Offset(-plotDelta.dx, -plotDelta.dy)} to allowed=${Offset(clampedDx, clampedDy)}');
        } else {
          debugPrint(' Middle-button pan: widgetDelta=$widgetDelta, plotDelta=$plotDelta');
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
      // Update axes after panning completes
      _updateAxesFromTransform();

      _rebuildElementsWithTransform();
      debugPrint(' Pan ended - regenerated elements with final transform');
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

      // Update axes to reflect new viewport
      _updateAxesFromTransform();

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
        ' Scroll without zoom: shift=${coordinator.isShiftPressed}, transform=${_transform != null}, generator=${_elementGenerator != null}',
      );

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

    // Paint background using theme color
    final backgroundColor = _theme?.backgroundColor ?? const Color(0xFFFFFFFF);
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    // Update axes to match current viewport JUST-IN-TIME before painting
    // This ensures axes always reflect the latest transform state during every paint
    if (_transform != null) {
      _xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
      _yAxis?.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
    }

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
      canvas.drawLine(Offset(0, cursorPos.dy), Offset(size.width, cursorPos.dy), crosshairPaint);

      // Vertical line across entire widget
      canvas.drawLine(Offset(cursorPos.dx, 0), Offset(cursorPos.dx, size.height), crosshairPaint);

      // Draw coordinate labels (showing both screen and data coordinates)
      _drawCrosshairLabels(canvas, size, cursorPos);
    }

    canvas.restore(); // Final restore (removes initial offset translation)
  }

  /// Draws coordinate labels for the crosshair showing screen and data coordinates.
  ///
  /// Displays:
  /// - X label at bottom of plot area showing data coordinate
  /// - Y label at left of plot area showing data coordinate
  void _drawCrosshairLabels(Canvas canvas, Size size, Offset cursorPos) {
    if (_transform == null) return;

    // Convert cursor position (widget space) to plot space for data coordinate calculation
    final plotPos = widgetToPlot(cursorPos);

    // Convert plot coordinates to data coordinates
    final dataPos = _transform!.plotToData(plotPos.dx, plotPos.dy);
    final dataX = dataPos.dx;
    final dataY = dataPos.dy;

    const textStyle = TextStyle(
      color: Color(0xFF000000),
      fontSize: 10,
      backgroundColor: Color(0xF0FFFFFF), // Almost opaque white
    );

    const labelPadding = 4.0;
    final labelBackgroundPaint = Paint()..color = const Color(0xF0FFFFFF);

    // X coordinate label (positioned at bottom of chart area)
    final xDisplayValue = _formatDataValue(dataX);
    final xTextPainter = TextPainter(
      text: TextSpan(text: 'X: $xDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label inside chart area (just above bottom edge)
    var xLabelX = cursorPos.dx - xTextPainter.width / 2;
    final xLabelY = _plotArea.bottom - xTextPainter.height - 8;

    // Clamp X position to keep label within plot bounds
    xLabelX = xLabelX.clamp(_plotArea.left + labelPadding, _plotArea.right - xTextPainter.width - labelPadding);

    // Draw background
    final xBgRect = Rect.fromLTWH(
      xLabelX - labelPadding,
      xLabelY - labelPadding,
      xTextPainter.width + labelPadding * 2,
      xTextPainter.height + labelPadding * 2,
    );
    canvas.drawRect(xBgRect, labelBackgroundPaint);

    // Draw text
    xTextPainter.paint(canvas, Offset(xLabelX, xLabelY));

    // Y coordinate label (positioned at left of chart area)
    final yDisplayValue = _formatDataValue(dataY);
    final yTextPainter = TextPainter(
      text: TextSpan(text: 'Y: $yDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label inside chart area (just right of left edge)
    final yLabelX = _plotArea.left + 8;
    var yLabelY = cursorPos.dy - yTextPainter.height / 2;

    // Clamp Y position to keep label within plot bounds
    yLabelY = yLabelY.clamp(_plotArea.top + labelPadding, _plotArea.bottom - yTextPainter.height - labelPadding);

    // Draw background
    final yBgRect = Rect.fromLTWH(
      yLabelX - labelPadding,
      yLabelY - labelPadding,
      yTextPainter.width + labelPadding * 2,
      yTextPainter.height + labelPadding * 2,
    );
    canvas.drawRect(yBgRect, labelBackgroundPaint);

    // Draw text
    yTextPainter.paint(canvas, Offset(yLabelX, yLabelY));
  }

  /// Formats data values for display (same logic as axis labels).
  String _formatDataValue(double value) {
    // If the value is very close to an integer, show it as an integer
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    // Otherwise, show with appropriate decimal places
    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
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
