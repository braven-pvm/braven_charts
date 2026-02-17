/// Zoom and pan state model for chart navigation.
///
/// Tracks the current zoom level, pan offset, and visible data bounds.
///
/// This model is immutable and uses copyWith for updates.
library;

import 'dart:ui' show Offset, Rect;

/// Represents the zoom and pan state of a chart.
///
/// This immutable model tracks the current zoom level and pan offset,
/// along with the visible and original data bounds.
///
/// Example:
/// ```dart
/// final dataBounds = Rect.fromLTWH(0, 0, 100, 100);
/// final state = ZoomPanState.initial(dataBounds);
/// final zoomed = state.copyWith(zoomLevelX: 2.0);
/// ```
class ZoomPanState {
  /// Creates a zoom/pan state from a JSON map.
  factory ZoomPanState.fromJson(Map<String, dynamic> json) {
    final originalBounds = json['originalDataBounds'] != null
        ? Rect.fromLTRB(
            (json['originalDataBounds']['left'] as num).toDouble(),
            (json['originalDataBounds']['top'] as num).toDouble(),
            (json['originalDataBounds']['right'] as num).toDouble(),
            (json['originalDataBounds']['bottom'] as num).toDouble(),
          )
        : Rect.zero;

    final visibleBounds = json['visibleDataBounds'] != null
        ? Rect.fromLTRB(
            (json['visibleDataBounds']['left'] as num).toDouble(),
            (json['visibleDataBounds']['top'] as num).toDouble(),
            (json['visibleDataBounds']['right'] as num).toDouble(),
            (json['visibleDataBounds']['bottom'] as num).toDouble(),
          )
        : originalBounds;

    return ZoomPanState(
      zoomLevelX: (json['zoomLevelX'] as num?)?.toDouble() ?? 1.0,
      zoomLevelY: (json['zoomLevelY'] as num?)?.toDouble() ?? 1.0,
      panOffset: json['panOffset'] != null
          ? Offset(
              (json['panOffset']['dx'] as num).toDouble(),
              (json['panOffset']['dy'] as num).toDouble(),
            )
          : Offset.zero,
      visibleDataBounds: visibleBounds,
      originalDataBounds: originalBounds,
      minZoomLevel: (json['minZoomLevel'] as num?)?.toDouble() ?? 0.5,
      maxZoomLevel: (json['maxZoomLevel'] as num?)?.toDouble() ?? 10.0,
      allowOverscroll: json['allowOverscroll'] as bool? ?? false,
      isAnimating: json['isAnimating'] as bool? ?? false,
      animationDuration: json['animationDuration'] != null
          ? Duration(milliseconds: json['animationDuration'] as int)
          : const Duration(milliseconds: 300),
    );
  }

  /// Creates a zoom/pan state with the specified properties.
  const ZoomPanState({
    this.zoomLevelX = 1.0,
    this.zoomLevelY = 1.0,
    this.panOffset = Offset.zero,
    required this.visibleDataBounds,
    required this.originalDataBounds,
    this.minZoomLevel = 0.5,
    this.maxZoomLevel = 10.0,
    this.allowOverscroll = false,
    this.isAnimating = false,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : assert(minZoomLevel > 0, 'minZoomLevel must be greater than 0'),
       assert(
         maxZoomLevel > minZoomLevel,
         'maxZoomLevel must be greater than minZoomLevel',
       );

  /// Creates an initial zoom/pan state with default values.
  ///
  /// Sets zoom to 1.0, no pan offset, and standard zoom limits.
  /// Requires the original data bounds to initialize visible bounds.
  /// If [dataBounds] is not provided, defaults to Rect.zero.
  const ZoomPanState.initial([Rect dataBounds = Rect.zero])
    : zoomLevelX = 1.0,
      zoomLevelY = 1.0,
      panOffset = Offset.zero,
      visibleDataBounds = dataBounds,
      originalDataBounds = dataBounds,
      minZoomLevel = 0.5,
      maxZoomLevel = 10.0,
      allowOverscroll = false,
      isAnimating = false,
      animationDuration = const Duration(milliseconds: 300);

  /// The current horizontal zoom level.
  ///
  /// 1.0 is the default zoom (100%). Values > 1.0 zoom in, values < 1.0 zoom out.
  /// Must be between [minZoomLevel] and [maxZoomLevel].
  final double zoomLevelX;

  /// The current vertical zoom level.
  ///
  /// 1.0 is the default zoom (100%). Values > 1.0 zoom in, values < 1.0 zoom out.
  /// Must be between [minZoomLevel] and [maxZoomLevel].
  final double zoomLevelY;

  /// The current pan offset in data space.
  ///
  /// Represents how much the chart has been panned from its original position.
  final Offset panOffset;

  /// The visible data bounds after zoom/pan (calculated).
  ///
  /// This represents the portion of the data that is currently visible.
  final Rect visibleDataBounds;

  /// The original data bounds (before zoom/pan).
  ///
  /// This represents the full extent of the data.
  final Rect originalDataBounds;

  /// The minimum allowed zoom level.
  ///
  /// Must be greater than 0.
  final double minZoomLevel;

  /// The maximum allowed zoom level.
  ///
  /// Must be greater than [minZoomLevel].
  final double maxZoomLevel;

  /// Whether to allow overscrolling (panning beyond data bounds).
  ///
  /// When false, panning is constrained to keep data visible.
  final bool allowOverscroll;

  /// Whether a zoom/pan animation is currently in progress.
  final bool isAnimating;

  /// The duration of zoom/pan animations.
  final Duration animationDuration;

  /// Creates a copy of this state with the specified properties updated.
  ///
  /// All properties are optional. Omitted properties retain their current values.
  ZoomPanState copyWith({
    double? zoomLevelX,
    double? zoomLevelY,
    Offset? panOffset,
    Rect? visibleDataBounds,
    Rect? originalDataBounds,
    double? minZoomLevel,
    double? maxZoomLevel,
    bool? allowOverscroll,
    bool? isAnimating,
    Duration? animationDuration,
  }) {
    return ZoomPanState(
      zoomLevelX: zoomLevelX ?? this.zoomLevelX,
      zoomLevelY: zoomLevelY ?? this.zoomLevelY,
      panOffset: panOffset ?? this.panOffset,
      visibleDataBounds: visibleDataBounds ?? this.visibleDataBounds,
      originalDataBounds: originalDataBounds ?? this.originalDataBounds,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      allowOverscroll: allowOverscroll ?? this.allowOverscroll,
      isAnimating: isAnimating ?? this.isAnimating,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  /// Converts this state to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'zoomLevelX': zoomLevelX,
      'zoomLevelY': zoomLevelY,
      'panOffset': {'dx': panOffset.dx, 'dy': panOffset.dy},
      'visibleDataBounds': {
        'left': visibleDataBounds.left,
        'top': visibleDataBounds.top,
        'right': visibleDataBounds.right,
        'bottom': visibleDataBounds.bottom,
      },
      'originalDataBounds': {
        'left': originalDataBounds.left,
        'top': originalDataBounds.top,
        'right': originalDataBounds.right,
        'bottom': originalDataBounds.bottom,
      },
      'minZoomLevel': minZoomLevel,
      'maxZoomLevel': maxZoomLevel,
      'allowOverscroll': allowOverscroll,
      'isAnimating': isAnimating,
      'animationDuration': animationDuration.inMilliseconds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ZoomPanState &&
        other.zoomLevelX == zoomLevelX &&
        other.zoomLevelY == zoomLevelY &&
        other.panOffset == panOffset &&
        other.visibleDataBounds == visibleDataBounds &&
        other.originalDataBounds == originalDataBounds &&
        other.minZoomLevel == minZoomLevel &&
        other.maxZoomLevel == maxZoomLevel &&
        other.allowOverscroll == allowOverscroll &&
        other.isAnimating == isAnimating &&
        other.animationDuration == animationDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      zoomLevelX,
      zoomLevelY,
      panOffset,
      visibleDataBounds,
      originalDataBounds,
      minZoomLevel,
      maxZoomLevel,
      allowOverscroll,
      isAnimating,
      animationDuration,
    );
  }
}
