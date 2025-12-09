// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

/// Element type classification for conflict resolution.
///
/// Defines all possible interactive element types in the chart system.
/// Used for type-safe element identification and priority resolution.
enum ChartElementType {
  /// Modal UI elements that block all interactions.
  modalOverlay,

  /// Context menu (right-click).
  contextMenu,

  /// Active drag operation in progress.
  draggingOperation,

  /// Annotation resize handle.
  resizeHandle,

  /// Data point marker.
  datapoint,

  /// Series line/area/bar.
  series,

  /// Annotation overlay (text, range, trend).
  annotation,

  /// Background pan/zoom interaction.
  backgroundInteraction,

  /// Passive crosshair display.
  crosshair,

  /// Passive tooltip display.
  tooltip,
}

/// Priority mapping for conflict resolution.
///
/// When multiple elements overlap at the same position, the element with
/// the highest priority value "wins" the interaction.
///
/// **Performance**: Uses const values and switch expression (optimized to
/// jump table by compiler). Zero runtime overhead compared to hardcoded values.
///
/// **Hierarchy**:
/// - CRITICAL (10): Modal overlays, context menus
/// - HIGH (7-9): Dragging operations (9), Datapoints (9), Series (8), Resize handles (7)
/// - MEDIUM (4-6): Annotations (6)
/// - LOW (1-3): Background pan/zoom (2)
/// - PASSIVE (0): Crosshair, tooltips
class ElementPriority {
  const ElementPriority._();

  // ============================================================================
  // CRITICAL (10) - Blocks all other interactions
  // ============================================================================

  /// Modal overlay priority (blocks everything).
  static const int modalOverlay = 10;

  /// Context menu priority (blocks everything).
  static const int contextMenu = 10;

  // ============================================================================
  // HIGH (7-9) - Interactive data elements and active operations
  // ============================================================================

  /// Active dragging operation (highest interactive priority).
  static const int draggingOperation = 9;

  /// Datapoint marker (the actual data - highest priority).
  static const int datapoint = 9;

  /// Series line/area (the actual data - very high priority).
  static const int series = 8;

  /// Resize handle (annotation edges).
  static const int resizeHandle = 7;

  // ============================================================================
  // MEDIUM (4-6) - Visual overlays
  // ============================================================================

  /// Annotation overlay (below actual data elements).
  static const int annotation = 6;

  // ============================================================================
  // LOW (1-3) - Background interactions
  // ============================================================================

  /// Background pan/zoom.
  static const int backgroundInteraction = 2;

  // ============================================================================
  // PASSIVE (0) - Display only, never blocks
  // ============================================================================

  /// Crosshair (passive display).
  static const int crosshair = 0;

  /// Tooltip (passive display).
  static const int tooltip = 0;

  // ============================================================================
  // Priority Resolution
  // ============================================================================

  /// Returns the priority for a given element type.
  ///
  /// **Performance**: Switch expression is optimized to jump table by Dart
  /// compiler. Zero overhead compared to hardcoded values.
  static int forType(ChartElementType type) {
    return switch (type) {
      ChartElementType.modalOverlay => modalOverlay,
      ChartElementType.contextMenu => contextMenu,
      ChartElementType.draggingOperation => draggingOperation,
      ChartElementType.resizeHandle => resizeHandle,
      ChartElementType.datapoint => datapoint,
      ChartElementType.series => series,
      ChartElementType.annotation => annotation,
      ChartElementType.backgroundInteraction => backgroundInteraction,
      ChartElementType.crosshair => crosshair,
      ChartElementType.tooltip => tooltip,
    };
  }

  /// Returns a human-readable description of the priority level.
  static String describe(int priority) {
    if (priority >= 10) return 'CRITICAL';
    if (priority >= 7) return 'HIGH';
    if (priority >= 4) return 'MEDIUM';
    if (priority >= 1) return 'LOW';
    return 'PASSIVE';
  }
}

/// Render order mapping for z-index/paint ordering.
///
/// **IMPORTANT**: This is SEPARATE from hit test priority!
/// - [ElementPriority] determines which element wins a click when overlapping
/// - [RenderOrder] determines which element is painted on top (higher = front)
///
/// Lower values paint FIRST (in back), higher values paint LAST (in front).
///
/// **Hierarchy**:
/// - BACKGROUND (0-1): Range annotations (shaded regions)
/// - DATA (2-3): Series lines, thresholds
/// - FOREGROUND (4-5): Point annotations, text annotations
/// - CONTROLS (6-7): Resize handles, selection indicators
class RenderOrder {
  const RenderOrder._();

  // ============================================================================
  // BACKGROUND (0-1) - Painted first, behind everything
  // ============================================================================

  /// Range annotations (shaded background regions).
  static const int rangeAnnotation = 0;

  // ============================================================================
  // DATA (2-3) - Chart data elements
  // ============================================================================

  /// Series lines/areas (main chart data).
  static const int series = 2;

  /// Threshold lines (horizontal/vertical reference lines).
  static const int thresholdAnnotation = 3;

  /// Trend lines.
  static const int trendAnnotation = 3;

  // ============================================================================
  // FOREGROUND (4-5) - Annotations that should be visible over data
  // ============================================================================

  /// Point annotations (markers on data points).
  static const int pointAnnotation = 4;

  /// Text annotations (labels, callouts).
  static const int textAnnotation = 1;

  /// Pin annotations (coordinate-based markers, render on top of text).
  static const int pinAnnotation = 5; // Same as text - both are foreground labels

  // ============================================================================
  // CONTROLS (6-7) - UI controls always on top
  // ============================================================================

  /// Resize handles (annotation edges).
  static const int resizeHandle = 6;

  /// Selection indicators, drag previews.
  static const int selectionIndicator = 7;

  // ============================================================================
  // OVERLAY (8+) - Always on top
  // ============================================================================

  /// Legend annotations (draggable legend boxes).
  static const int legend = 8;

  // ============================================================================
  // Default for unknown types
  // ============================================================================

  /// Default render order for unknown element types.
  static const int defaultOrder = 3;
}
