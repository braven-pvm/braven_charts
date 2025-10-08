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
  /// Creates an interaction state with the specified properties.
  const InteractionState({
    this.crosshairPosition,
    this.isCrosshairVisible = false,
    this.tooltipPosition,
    this.tooltipDataPoint,
    this.isTooltipVisible = false,
    this.hoveredDataPoint,
    this.focusedDataPoint,
    this.selectedDataPoints = const [],
    this.zoomPanState = const ZoomPanState.initial(),
  });

  /// Creates an initial interaction state with default values.
  ///
  /// All interactive features are disabled and no data points are selected.
  const InteractionState.initial()
      : crosshairPosition = null,
        isCrosshairVisible = false,
        tooltipPosition = null,
        tooltipDataPoint = null,
        isTooltipVisible = false,
        hoveredDataPoint = null,
        focusedDataPoint = null,
        selectedDataPoints = const [],
        zoomPanState = const ZoomPanState.initial();

  /// The position of the crosshair in chart coordinates.
  ///
  /// Null if crosshair is not active. Required when [isCrosshairVisible] is true.
  final Offset? crosshairPosition;

  /// Whether the crosshair should be visible.
  ///
  /// When true, [crosshairPosition] must not be null.
  final bool isCrosshairVisible;

  /// The position where the tooltip should be displayed.
  ///
  /// Null if tooltip is not active. Required when [isTooltipVisible] is true.
  final Offset? tooltipPosition;

  /// The data point that the tooltip is displaying.
  ///
  /// Null if no data point is being shown. Required when [isTooltipVisible] is true.
  final Map<String, dynamic>? tooltipDataPoint;

  /// Whether the tooltip should be visible.
  ///
  /// When true, both [tooltipPosition] and [tooltipDataPoint] must not be null.
  final bool isTooltipVisible;

  /// The data point currently being hovered by the mouse/touch.
  ///
  /// Null if no data point is hovered.
  final Map<String, dynamic>? hoveredDataPoint;

  /// The data point currently focused via keyboard navigation.
  ///
  /// Null if no data point is focused.
  final Map<String, dynamic>? focusedDataPoint;

  /// List of currently selected data points.
  ///
  /// Empty list if no points are selected.
  final List<Map<String, dynamic>> selectedDataPoints;

  /// The current zoom and pan state.
  ///
  /// Defaults to initial state (1.0 zoom, no pan).
  final ZoomPanState zoomPanState;

  /// Whether there is a hovered data point.
  bool get hasHoveredPoint => hoveredDataPoint != null;

  /// Whether there is a focused data point.
  bool get hasFocusedPoint => focusedDataPoint != null;

  /// Whether any data points are selected.
  bool get hasSelection => selectedDataPoints.isNotEmpty;

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
    Offset? crosshairPosition,
    bool? isCrosshairVisible,
    Offset? tooltipPosition,
    Map<String, dynamic>? tooltipDataPoint,
    bool? isTooltipVisible,
    Map<String, dynamic>? hoveredDataPoint,
    Map<String, dynamic>? focusedDataPoint,
    List<Map<String, dynamic>>? selectedDataPoints,
    ZoomPanState? zoomPanState,
  }) {
    return InteractionState(
      crosshairPosition: crosshairPosition ?? this.crosshairPosition,
      isCrosshairVisible: isCrosshairVisible ?? this.isCrosshairVisible,
      tooltipPosition: tooltipPosition ?? this.tooltipPosition,
      tooltipDataPoint: tooltipDataPoint ?? this.tooltipDataPoint,
      isTooltipVisible: isTooltipVisible ?? this.isTooltipVisible,
      hoveredDataPoint: hoveredDataPoint ?? this.hoveredDataPoint,
      focusedDataPoint: focusedDataPoint ?? this.focusedDataPoint,
      selectedDataPoints: selectedDataPoints ?? this.selectedDataPoints,
      zoomPanState: zoomPanState ?? this.zoomPanState,
    );
  }

  /// Converts this state to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'crosshairPosition': crosshairPosition != null
          ? {
              'dx': crosshairPosition!.dx,
              'dy': crosshairPosition!.dy,
            }
          : null,
      'isCrosshairVisible': isCrosshairVisible,
      'tooltipPosition': tooltipPosition != null
          ? {
              'dx': tooltipPosition!.dx,
              'dy': tooltipPosition!.dy,
            }
          : null,
      'tooltipDataPoint': tooltipDataPoint,
      'isTooltipVisible': isTooltipVisible,
      'hoveredDataPoint': hoveredDataPoint,
      'focusedDataPoint': focusedDataPoint,
      'selectedDataPoints': selectedDataPoints,
      'zoomPanState': zoomPanState.toJson(),
    };
  }

  /// Creates an interaction state from a JSON map.
  factory InteractionState.fromJson(Map<String, dynamic> json) {
    return InteractionState(
      crosshairPosition: json['crosshairPosition'] != null
          ? Offset(
              (json['crosshairPosition']['dx'] as num).toDouble(),
              (json['crosshairPosition']['dy'] as num).toDouble(),
            )
          : null,
      isCrosshairVisible: json['isCrosshairVisible'] as bool? ?? false,
      tooltipPosition: json['tooltipPosition'] != null
          ? Offset(
              (json['tooltipPosition']['dx'] as num).toDouble(),
              (json['tooltipPosition']['dy'] as num).toDouble(),
            )
          : null,
      tooltipDataPoint: json['tooltipDataPoint'] as Map<String, dynamic>?,
      isTooltipVisible: json['isTooltipVisible'] as bool? ?? false,
      hoveredDataPoint: json['hoveredDataPoint'] as Map<String, dynamic>?,
      focusedDataPoint: json['focusedDataPoint'] as Map<String, dynamic>?,
      selectedDataPoints: (json['selectedDataPoints'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      zoomPanState: json['zoomPanState'] != null
          ? ZoomPanState.fromJson(json['zoomPanState'] as Map<String, dynamic>)
          : const ZoomPanState.initial(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InteractionState &&
        other.crosshairPosition == crosshairPosition &&
        other.isCrosshairVisible == isCrosshairVisible &&
        other.tooltipPosition == tooltipPosition &&
        other.tooltipDataPoint == tooltipDataPoint &&
        other.isTooltipVisible == isTooltipVisible &&
        other.hoveredDataPoint == hoveredDataPoint &&
        other.focusedDataPoint == focusedDataPoint &&
        _listEquals(other.selectedDataPoints, selectedDataPoints) &&
        other.zoomPanState == zoomPanState;
  }

  @override
  int get hashCode {
    return Object.hash(
      crosshairPosition,
      isCrosshairVisible,
      tooltipPosition,
      tooltipDataPoint,
      isTooltipVisible,
      hoveredDataPoint,
      focusedDataPoint,
      Object.hashAll(selectedDataPoints),
      zoomPanState,
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
