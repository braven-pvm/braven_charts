/// Interaction state model for chart user interactions.
///
/// Tracks the current state of all user interactions with the chart including:
/// - Crosshair position and visibility
/// - Tooltip position, visibility, and data
/// - Hovered and focused data points
/// - Selection state
/// - Zoom/pan state
///
/// This model is immutable and uses copyWith for updates.
library;

import 'dart:ui' show Offset;

import 'gesture_details.dart';
import 'zoom_pan_state.dart';

/// Represents the complete interaction state of a chart.
///
/// This immutable model tracks all aspects of user interaction including
/// crosshair, tooltip, hover, focus, selection, and zoom/pan state.
///
/// Example:
/// ```dart
/// final state = InteractionState.initial();
/// final updated = state.copyWith(
///   crosshairPosition: Offset(100, 200),
///   isCrosshairVisible: true,
/// );
/// ```
class InteractionState {
  /// Creates an interaction state from a JSON map.
  factory InteractionState.fromJson(Map<String, dynamic> json) {
    return InteractionState(
      hoveredPoint: json['hoveredPoint'] as Map<String, dynamic>?,
      hoveredSeriesId: json['hoveredSeriesId'] as String?,
      focusedPoint: json['focusedPoint'] as Map<String, dynamic>?,
      focusedPointIndex: json['focusedPointIndex'] as int? ?? -1,
      selectedPoints: (json['selectedPoints'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? const [],
      crosshairPosition: json['crosshairPosition'] != null
          ? Offset(
              (json['crosshairPosition']['dx'] as num).toDouble(),
              (json['crosshairPosition']['dy'] as num).toDouble(),
            )
          : null,
      snapPoints: (json['snapPoints'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? const [],
      isCrosshairVisible: json['isCrosshairVisible'] as bool? ?? false,
      isTooltipVisible: json['isTooltipVisible'] as bool? ?? false,
      tooltipPosition: json['tooltipPosition'] != null
          ? Offset(
              (json['tooltipPosition']['dx'] as num).toDouble(),
              (json['tooltipPosition']['dy'] as num).toDouble(),
            )
          : null,
      tooltipDataPoint: json['tooltipDataPoint'] as Map<String, dynamic>?,
      zoomPanState: json['zoomPanState'] != null ? ZoomPanState.fromJson(json['zoomPanState'] as Map<String, dynamic>) : const ZoomPanState.initial(),
      activeGesture: json['activeGesture'] != null ? GestureDetails.fromJson(json['activeGesture'] as Map<String, dynamic>) : null,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
    );
  }

  /// Creates an interaction state with the specified properties.
  InteractionState({
    this.hoveredPoint,
    this.hoveredSeriesId,
    this.focusedPoint,
    this.focusedPointIndex = -1,
    this.selectedPoints = const [],
    this.crosshairPosition,
    this.snapPoints = const [],
    this.isCrosshairVisible = false,
    this.isTooltipVisible = false,
    this.tooltipPosition,
    this.tooltipDataPoint,
    this.zoomPanState = const ZoomPanState.initial(),
    this.activeGesture,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Creates an initial interaction state with default values.
  ///
  /// All interactive features are disabled and no data points are selected.
  InteractionState.initial()
      : hoveredPoint = null,
        hoveredSeriesId = null,
        focusedPoint = null,
        focusedPointIndex = -1,
        selectedPoints = const [],
        crosshairPosition = null,
        snapPoints = const [],
        isCrosshairVisible = false,
        isTooltipVisible = false,
        tooltipPosition = null,
        tooltipDataPoint = null,
        zoomPanState = const ZoomPanState.initial(),
        activeGesture = null,
        lastUpdated = DateTime.now();

  // Hover state (desktop mouse)
  /// The data point currently being hovered by the mouse/touch.
  ///
  /// Null if no data point is hovered.
  final Map<String, dynamic>? hoveredPoint;

  /// The series ID of the currently hovered point.
  ///
  /// Null if no point is hovered.
  final String? hoveredSeriesId;

  // Focus state (keyboard navigation)
  /// The data point currently focused via keyboard navigation.
  ///
  /// Null if no data point is focused.
  final Map<String, dynamic>? focusedPoint;

  /// The index of the focused point in its data series.
  ///
  /// -1 if no point is focused.
  final int focusedPointIndex;

  // Selection state (multi-select support)
  /// List of currently selected data points.
  ///
  /// Empty list if no points are selected.
  final List<Map<String, dynamic>> selectedPoints;

  // Crosshair state
  /// The position of the crosshair in chart coordinates.
  ///
  /// Null if crosshair is not active. Required when [isCrosshairVisible] is true.
  final Offset? crosshairPosition;

  /// Points at the crosshair position (snap points).
  ///
  /// Empty list if no points are near crosshair.
  final List<Map<String, dynamic>> snapPoints;

  /// Whether the crosshair should be visible.
  ///
  /// When true, [crosshairPosition] must not be null.
  final bool isCrosshairVisible;

  // Tooltip state
  /// Whether the tooltip should be visible.
  ///
  /// When true, both [tooltipPosition] and [tooltipDataPoint] must not be null.
  final bool isTooltipVisible;

  /// The position where the tooltip should be displayed.
  ///
  /// Null if tooltip is not active. Required when [isTooltipVisible] is true.
  final Offset? tooltipPosition;

  /// The data point that the tooltip is displaying.
  ///
  /// Null if no data point is being shown. Required when [isTooltipVisible] is true.
  final Map<String, dynamic>? tooltipDataPoint;

  // Viewport state
  /// The current zoom and pan state.
  ///
  /// Defaults to initial state (1.0 zoom, no pan).
  final ZoomPanState zoomPanState;

  // Active gesture
  /// The currently active gesture, if any.
  ///
  /// Null if no gesture is active.
  final GestureDetails? activeGesture;

  // Timestamp for debugging
  /// Timestamp when this state was last updated.
  ///
  /// Used for debugging and analytics.
  final DateTime lastUpdated;

  /// Whether there is a hovered data point.
  bool get hasHoveredPoint => hoveredPoint != null;

  /// Whether there is a focused data point.
  bool get hasFocusedPoint => focusedPoint != null;

  /// Whether any data points are selected.
  bool get hasSelection => selectedPoints.isNotEmpty;

  /// Validates the state for consistency.
  ///
  /// Throws [StateError] if validation fails:
  /// - Crosshair visible requires crosshair position
  /// - Tooltip visible requires tooltip position and data point
  void validate() {
    if (isCrosshairVisible && crosshairPosition == null) {
      throw StateError(
        'Crosshair cannot be visible without a position',
      );
    }

    if (isTooltipVisible) {
      if (tooltipPosition == null) {
        throw StateError(
          'Tooltip cannot be visible without a position',
        );
      }
      if (tooltipDataPoint == null) {
        throw StateError(
          'Tooltip cannot be visible without a data point',
        );
      }
    }
  }

  /// Creates a copy of this state with the specified properties updated.
  ///
  /// All properties are optional. Omitted properties retain their current values.
  InteractionState copyWith({
    Map<String, dynamic>? hoveredPoint,
    String? hoveredSeriesId,
    Map<String, dynamic>? focusedPoint,
    int? focusedPointIndex,
    List<Map<String, dynamic>>? selectedPoints,
    Offset? crosshairPosition,
    List<Map<String, dynamic>>? snapPoints,
    bool? isCrosshairVisible,
    bool? isTooltipVisible,
    Offset? tooltipPosition,
    Map<String, dynamic>? tooltipDataPoint,
    ZoomPanState? zoomPanState,
    GestureDetails? activeGesture,
    DateTime? lastUpdated,
  }) {
    return InteractionState(
      hoveredPoint: hoveredPoint ?? this.hoveredPoint,
      hoveredSeriesId: hoveredSeriesId ?? this.hoveredSeriesId,
      focusedPoint: focusedPoint ?? this.focusedPoint,
      focusedPointIndex: focusedPointIndex ?? this.focusedPointIndex,
      selectedPoints: selectedPoints ?? this.selectedPoints,
      crosshairPosition: crosshairPosition ?? this.crosshairPosition,
      snapPoints: snapPoints ?? this.snapPoints,
      isCrosshairVisible: isCrosshairVisible ?? this.isCrosshairVisible,
      isTooltipVisible: isTooltipVisible ?? this.isTooltipVisible,
      tooltipPosition: tooltipPosition ?? this.tooltipPosition,
      tooltipDataPoint: tooltipDataPoint ?? this.tooltipDataPoint,
      zoomPanState: zoomPanState ?? this.zoomPanState,
      activeGesture: activeGesture ?? this.activeGesture,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Converts this state to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'hoveredPoint': hoveredPoint,
      'hoveredSeriesId': hoveredSeriesId,
      'focusedPoint': focusedPoint,
      'focusedPointIndex': focusedPointIndex,
      'selectedPoints': selectedPoints,
      'crosshairPosition': crosshairPosition != null
          ? {
              'dx': crosshairPosition!.dx,
              'dy': crosshairPosition!.dy,
            }
          : null,
      'snapPoints': snapPoints,
      'isCrosshairVisible': isCrosshairVisible,
      'isTooltipVisible': isTooltipVisible,
      'tooltipPosition': tooltipPosition != null
          ? {
              'dx': tooltipPosition!.dx,
              'dy': tooltipPosition!.dy,
            }
          : null,
      'tooltipDataPoint': tooltipDataPoint,
      'zoomPanState': zoomPanState.toJson(),
      'activeGesture': activeGesture?.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InteractionState &&
        other.hoveredPoint == hoveredPoint &&
        other.hoveredSeriesId == hoveredSeriesId &&
        other.focusedPoint == focusedPoint &&
        other.focusedPointIndex == focusedPointIndex &&
        _listEquals(other.selectedPoints, selectedPoints) &&
        other.crosshairPosition == crosshairPosition &&
        _listEquals(other.snapPoints, snapPoints) &&
        other.isCrosshairVisible == isCrosshairVisible &&
        other.isTooltipVisible == isTooltipVisible &&
        other.tooltipPosition == tooltipPosition &&
        other.tooltipDataPoint == tooltipDataPoint &&
        other.zoomPanState == zoomPanState &&
        other.activeGesture == activeGesture &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(
      hoveredPoint,
      hoveredSeriesId,
      focusedPoint,
      focusedPointIndex,
      Object.hashAll(selectedPoints),
      crosshairPosition,
      Object.hashAll(snapPoints),
      isCrosshairVisible,
      isTooltipVisible,
      tooltipPosition,
      tooltipDataPoint,
      zoomPanState,
      activeGesture,
      lastUpdated,
    );
  }

  /// Helper to compare lists for equality.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
