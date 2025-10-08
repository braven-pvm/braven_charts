/// Zoom and pan state model for chart navigation.
///
/// Tracks the current zoom level, pan offset, and provides methods for
/// calculating visible data bounds and constraining zoom/pan operations.
///
/// This model is immutable and uses copyWith for updates.
library;

import 'dart:ui' show Offset, Rect;

/// Represents the zoom and pan state of a chart.
///
/// This immutable model tracks the current zoom level and pan offset,
/// and provides methods for calculating visible data bounds and
/// constraining zoom/pan operations within specified limits.
///
/// Example:
/// ```dart
/// final state = ZoomPanState.initial();
/// final zoomed = state.copyWith(zoomLevel: 2.0);
/// final bounds = zoomed.visibleDataBounds(fullBounds);
/// ```
class ZoomPanState {
  /// Creates a zoom/pan state with the specified properties.
  const ZoomPanState({
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.minZoom = 0.5,
    this.maxZoom = 10.0,
    this.enableOverscroll = false,
  }) : assert(minZoom > 0, 'minZoom must be greater than 0'),
       assert(maxZoom > minZoom, 'maxZoom must be greater than minZoom');

  /// Creates an initial zoom/pan state with default values.
  ///
  /// Sets zoom to 1.0, no pan offset, and standard zoom limits.
  const ZoomPanState.initial()
      : zoomLevel = 1.0,
        panOffset = Offset.zero,
        minZoom = 0.5,
        maxZoom = 10.0,
        enableOverscroll = false;

  /// The current zoom level.
  ///
  /// 1.0 is the default zoom (100%). Values > 1.0 zoom in, values < 1.0 zoom out.
  /// Must be between [minZoom] and [maxZoom].
  final double zoomLevel;

  /// The current pan offset in chart coordinates.
  ///
  /// Represents how much the chart has been panned from its original position.
  final Offset panOffset;

  /// The minimum allowed zoom level.
  ///
  /// Must be greater than 0.
  final double minZoom;

  /// The maximum allowed zoom level.
  ///
  /// Must be greater than [minZoom].
  final double maxZoom;

  /// Whether to allow overscrolling (panning beyond data bounds).
  ///
  /// When false, panning is constrained to keep data visible.
  final bool enableOverscroll;

  /// Calculates the visible data bounds after applying zoom and pan.
  ///
  /// Takes the [fullDataBounds] and applies the current zoom level and pan offset
  /// to determine what portion of the data is currently visible.
  ///
  /// Returns a [Rect] representing the visible portion of the data space.
  Rect visibleDataBounds(Rect fullDataBounds) {
    // Calculate the size of the visible area (inversely proportional to zoom)
    final visibleWidth = fullDataBounds.width / zoomLevel;
    final visibleHeight = fullDataBounds.height / zoomLevel;

    // Calculate the top-left corner of the visible area
    // Pan offset is subtracted because panning right means viewing the left part
    final left = fullDataBounds.left - panOffset.dx;
    final top = fullDataBounds.top - panOffset.dy;

    return Rect.fromLTWH(left, top, visibleWidth, visibleHeight);
  }

  /// Constrains a zoom level to the allowed range.
  ///
  /// Returns a zoom level clamped between [minZoom] and [maxZoom].
  double constrainZoom(double zoom) {
    return zoom.clamp(minZoom, maxZoom);
  }

  /// Constrains a pan offset to prevent overscrolling (if disabled).
  ///
  /// If [enableOverscroll] is true, returns the offset unchanged.
  /// Otherwise, constrains the offset to keep data visible within [chartSize].
  ///
  /// [offset] is the desired pan offset.
  /// [fullDataBounds] is the full extent of the data.
  /// [chartSize] is the size of the visible chart area.
  Offset constrainPan(
    Offset offset,
    Rect fullDataBounds,
    Rect chartSize,
  ) {
    if (enableOverscroll) {
      return offset;
    }

    // Calculate the visible data size at current zoom
    final visibleWidth = fullDataBounds.width / zoomLevel;
    final visibleHeight = fullDataBounds.height / zoomLevel;

    // Calculate maximum pan offsets that keep data visible
    final maxPanX = fullDataBounds.width - visibleWidth;
    final maxPanY = fullDataBounds.height - visibleHeight;

    // Constrain the offset
    final constrainedDx = offset.dx.clamp(0.0, maxPanX);
    final constrainedDy = offset.dy.clamp(0.0, maxPanY);

    return Offset(constrainedDx, constrainedDy);
  }

  /// Interpolates between this state and [end] by the given [t] value.
  ///
  /// Used for smooth zoom/pan animations. When [t] is 0.0, returns this state.
  /// When [t] is 1.0, returns [end]. Values between 0 and 1 return interpolated states.
  ZoomPanState lerpTo(ZoomPanState end, double t) {
    return ZoomPanState(
      zoomLevel: zoomLevel + (end.zoomLevel - zoomLevel) * t,
      panOffset: Offset.lerp(panOffset, end.panOffset, t)!,
      minZoom: minZoom,
      maxZoom: maxZoom,
      enableOverscroll: enableOverscroll,
    );
  }

  /// Creates a copy of this state with the specified properties updated.
  ///
  /// All properties are optional. Omitted properties retain their current values.
  ZoomPanState copyWith({
    double? zoomLevel,
    Offset? panOffset,
    double? minZoom,
    double? maxZoom,
    bool? enableOverscroll,
  }) {
    return ZoomPanState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      enableOverscroll: enableOverscroll ?? this.enableOverscroll,
    );
  }

  /// Converts this state to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'zoomLevel': zoomLevel,
      'panOffset': {
        'dx': panOffset.dx,
        'dy': panOffset.dy,
      },
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'enableOverscroll': enableOverscroll,
    };
  }

  /// Creates a zoom/pan state from a JSON map.
  factory ZoomPanState.fromJson(Map<String, dynamic> json) {
    return ZoomPanState(
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      panOffset: json['panOffset'] != null
          ? Offset(
              (json['panOffset']['dx'] as num).toDouble(),
              (json['panOffset']['dy'] as num).toDouble(),
            )
          : Offset.zero,
      minZoom: (json['minZoom'] as num?)?.toDouble() ?? 0.5,
      maxZoom: (json['maxZoom'] as num?)?.toDouble() ?? 10.0,
      enableOverscroll: json['enableOverscroll'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ZoomPanState &&
        other.zoomLevel == zoomLevel &&
        other.panOffset == panOffset &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        other.enableOverscroll == enableOverscroll;
  }

  @override
  int get hashCode {
    return Object.hash(
      zoomLevel,
      panOffset,
      minZoom,
      maxZoom,
      enableOverscroll,
    );
  }
}
