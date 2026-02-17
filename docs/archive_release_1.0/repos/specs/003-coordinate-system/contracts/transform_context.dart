/// Contract: TransformContext
///
/// Immutable state container for coordinate transformations. Provides all
/// context needed for stateless transformation functions.
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

/// Immutable snapshot of all state required for coordinate transformations.
///
/// This class enables stateless transformation logic by explicitly passing
/// all dependencies (viewport, data ranges, chart bounds, etc.) rather than
/// maintaining internal state.
///
/// Example usage:
/// ```dart
/// const context = TransformContext(
///   widgetSize: Size(800, 600),
///   chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540),
///   xDataRange: DataRange(min: 0, max: 100),
///   yDataRange: DataRange(min: -50, max: 50),
///   viewport: ViewportState.identity(),
///   series: [series1, series2],
/// );
///
/// final screenPoint = transformer.transform(
///   dataPoint,
///   CoordinateSystem.data,
///   CoordinateSystem.screen,
///   context, // All state passed explicitly
/// );
/// ```
class TransformContext {
  /// Flutter widget dimensions (width, height in logical pixels).
  final Size widgetSize;

  /// Plot area bounds excluding axes, title, legend (LTWH in logical pixels).
  final Rect chartAreaBounds;

  /// X-axis data range (min to max in data units).
  final DataRange xDataRange;

  /// Y-axis data range (min to max in data units).
  final DataRange yDataRange;

  /// Current zoom/pan state.
  final ViewportState viewport;

  /// Series data for dataPoint → data transformations.
  final List<ChartSeries> series;

  /// Optional marker offset for annotation positioning (in logical pixels).
  final Point<double>? markerOffset;

  /// Animation progress (0.0 = start, 1.0 = end).
  final double animationProgress;

  /// Device pixel density ratio.
  final double devicePixelRatio;

  /// Create immutable transformation context.
  ///
  /// Validates:
  /// - widgetSize dimensions > 0
  /// - chartAreaBounds within widget bounds
  /// - data ranges non-empty (min < max)
  /// - animationProgress in [0.0, 1.0]
  /// - devicePixelRatio > 0
  const TransformContext({
    required this.widgetSize,
    required this.chartAreaBounds,
    required this.xDataRange,
    required this.yDataRange,
    required this.viewport,
    required this.series,
    this.markerOffset,
    this.animationProgress = 1.0,
    this.devicePixelRatio = 1.0,
  });

  /// Create context from RenderContext (convenience factory).
  ///
  /// Extracts transformation state from Core Rendering Engine's RenderContext.
  factory TransformContext.fromRenderContext(
    RenderContext renderContext, {
    required DataRange xDataRange,
    required DataRange yDataRange,
    required List<ChartSeries> series,
    ViewportState? viewport,
  }) {
    return TransformContext(
      widgetSize: renderContext.size,
      chartAreaBounds: renderContext.viewport,
      xDataRange: xDataRange,
      yDataRange: yDataRange,
      viewport: viewport ?? ViewportState.identity(),
      series: series,
      devicePixelRatio: 1.0,
    );
  }

  /// Create copy with updated viewport (zoom/pan).
  TransformContext withViewport(ViewportState newViewport) {
    return TransformContext(
      widgetSize: widgetSize,
      chartAreaBounds: chartAreaBounds,
      xDataRange: xDataRange,
      yDataRange: yDataRange,
      viewport: newViewport,
      series: series,
      markerOffset: markerOffset,
      animationProgress: animationProgress,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Create copy with updated marker offset (annotation positioning).
  TransformContext withMarkerOffset(Point<double> offset) {
    return TransformContext(
      widgetSize: widgetSize,
      chartAreaBounds: chartAreaBounds,
      xDataRange: xDataRange,
      yDataRange: yDataRange,
      viewport: viewport,
      series: series,
      markerOffset: offset,
      animationProgress: animationProgress,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Create copy with updated animation progress.
  TransformContext withAnimationProgress(double progress) {
    return TransformContext(
      widgetSize: widgetSize,
      chartAreaBounds: chartAreaBounds,
      xDataRange: xDataRange,
      yDataRange: yDataRange,
      viewport: viewport,
      series: series,
      markerOffset: markerOffset,
      animationProgress: progress,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Create copy with updated data ranges (axis scaling).
  TransformContext withDataRanges(DataRange x, DataRange y) {
    return TransformContext(
      widgetSize: widgetSize,
      chartAreaBounds: chartAreaBounds,
      xDataRange: x,
      yDataRange: y,
      viewport: viewport,
      series: series,
      markerOffset: markerOffset,
      animationProgress: animationProgress,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Hash code for cache key generation.
  ///
  /// Combines all fields to create unique key for matrix caching.
  /// Cache invalidates when any field changes.
  @override
  int get hashCode => Object.hash(
    widgetSize,
    chartAreaBounds,
    xDataRange,
    yDataRange,
    viewport,
    markerOffset,
    animationProgress,
    devicePixelRatio,
  );

  /// Structural equality (all fields must match).
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TransformContext &&
            widgetSize == other.widgetSize &&
            chartAreaBounds == other.chartAreaBounds &&
            xDataRange == other.xDataRange &&
            yDataRange == other.yDataRange &&
            viewport == other.viewport &&
            markerOffset == other.markerOffset &&
            animationProgress == other.animationProgress &&
            devicePixelRatio == other.devicePixelRatio);
  }
}

// Forward declarations (defined in Foundation Layer)
abstract class DataRange {}

abstract class ChartSeries {}

abstract class ViewportState {}

abstract class RenderContext {}
