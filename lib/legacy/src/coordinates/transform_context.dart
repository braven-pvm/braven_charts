/// Coordinate transformation context.
///
/// Immutable snapshot of all state required for coordinate transformations.
/// Enables stateless transformation logic by explicitly passing all
/// dependencies (viewport, data ranges, chart bounds, etc.) rather than
/// maintaining internal state.
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/legacy/braven_charts.dart'
    show DataRange, ChartSeries;

import '../rendering/render_context.dart';
import 'viewport_state.dart';

/// Immutable snapshot of all state required for coordinate transformations.
///
/// This class enables stateless transformation logic by explicitly passing
/// all dependencies (viewport, data ranges, chart bounds, etc.) rather than
/// maintaining internal state. This design provides several benefits:
///
/// - **Testability**: Transformations are pure functions of context
/// - **Cacheability**: Context can serve as a cache key
/// - **Thread safety**: No shared mutable state
/// - **Composition**: Easy to chain transformations
///
/// The context captures:
/// - Widget dimensions and layout (widgetSize, chartAreaBounds)
/// - Data space boundaries (xDataRange, yDataRange)
/// - Viewport state for zoom/pan (viewport)
/// - Series data for point lookups (series)
/// - Optional marker positioning (markerOffset)
/// - Animation state (animationProgress)
/// - Display density (devicePixelRatio)
///
/// **Usage Example**:
/// ```dart
/// // Create context from current chart state
/// final context = TransformContext(
///   widgetSize: Size(800, 600),
///   chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540),
///   xDataRange: DataRange(min: 0, max: 100),
///   yDataRange: DataRange(min: -50, max: 50),
///   viewport: ViewportState.identity(),
///   series: [lineSeries, barSeries],
/// );
///
/// // Use in transformation
/// final screenPoint = transformer.transform(
///   dataPoint,
///   CoordinateSystem.data,
///   CoordinateSystem.screen,
///   context, // All state passed explicitly
/// );
/// ```
///
/// **Immutability**:
/// All fields are final. Use `withX()` methods to create modified copies:
/// ```dart
/// final zoomed = context.withViewport(
///   context.viewport.withZoom(2.0),
/// );
/// ```
///
/// **Validation**:
/// Constructor validates all inputs:
/// - widgetSize dimensions must be > 0
/// - chartAreaBounds must be within widget bounds
/// - Data ranges must be non-empty (min < max)
/// - animationProgress must be in [0.0, 1.0]
/// - devicePixelRatio must be > 0
///
/// See also:
/// - [ViewportState] - Zoom/pan state
/// - [CoordinateSystem] - Available coordinate systems
/// - [UniversalCoordinateTransformer] - Transformation engine
class TransformContext {
  /// Create immutable transformation context.
  ///
  /// **Validation**:
  /// - widgetSize dimensions > 0
  /// - chartAreaBounds within widget bounds
  /// - data ranges non-empty (min < max)
  /// - animationProgress in [0.0, 1.0]
  /// - devicePixelRatio > 0
  ///
  /// Throws [AssertionError] in debug mode if validation fails.
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
  })  : assert(animationProgress >= 0.0 && animationProgress <= 1.0,
            'animationProgress must be in [0.0, 1.0]'),
        assert(devicePixelRatio > 0.0, 'devicePixelRatio must be > 0');

  /// Create context from RenderContext (convenience factory).
  ///
  /// Extracts transformation state from Core Rendering Engine's RenderContext.
  /// Useful for integrating coordinate system with existing rendering pipeline.
  ///
  /// **Parameters**:
  /// - `renderContext`: Source rendering context (provides size, viewport)
  /// - `xDataRange`: X-axis data range (required)
  /// - `yDataRange`: Y-axis data range (required)
  /// - `series`: Series data for point lookups (required)
  /// - `viewport`: Optional zoom/pan state (defaults to identity)
  ///
  /// **Example**:
  /// ```dart
  /// final context = TransformContext.fromRenderContext(
  ///   renderContext,
  ///   xDataRange: DataRange(min: 0, max: 100),
  ///   yDataRange: DataRange(min: 0, max: 50),
  ///   series: chartSeries,
  /// );
  /// ```
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

  /// Flutter widget dimensions (width, height in logical pixels).
  ///
  /// Represents the total size of the chart widget. Used for:
  /// - Mouse/screen coordinate bounds
  /// - Layout calculations
  /// - Aspect ratio preservation
  ///
  /// **Coordinate System**: Screen (logical pixels)
  /// **Origin**: Top-left corner of widget
  /// **Range**: (0, 0) to (width, height)
  final Size widgetSize;

  /// Plot area bounds excluding axes, title, legend.
  ///
  /// Defines the rectangular region where data is rendered, excluding:
  /// - Axis labels and tick marks
  /// - Chart title and subtitle
  /// - Legend
  /// - Padding/margins
  ///
  /// **Coordinate System**: Screen (logical pixels)
  /// **Format**: LTWH (left, top, width, height)
  /// **Constraint**: Must be fully contained within widgetSize
  ///
  /// Example:
  /// ```dart
  /// // Widget is 800x600, chart area has 50px margins
  /// chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540)
  /// ```
  final Rect chartAreaBounds;

  /// X-axis data range (min to max in data units).
  ///
  /// Defines the extent of data along the X axis. Used to map between
  /// data coordinates and chart area pixels.
  ///
  /// **Coordinate System**: Data
  /// **Units**: Application-defined (time, distance, index, etc.)
  /// **Constraint**: Must be non-empty (min < max)
  ///
  /// Example:
  /// ```dart
  /// xDataRange: DataRange(min: 0.0, max: 100.0)  // 0-100 range
  /// ```
  final DataRange xDataRange;

  /// Y-axis data range (min to max in data units).
  ///
  /// Defines the extent of data along the Y axis. Used to map between
  /// data coordinates and chart area pixels.
  ///
  /// **Coordinate System**: Data
  /// **Units**: Application-defined (temperature, price, count, etc.)
  /// **Constraint**: Must be non-empty (min < max)
  ///
  /// Example:
  /// ```dart
  /// yDataRange: DataRange(min: -50.0, max: 50.0)  // -50 to +50 range
  /// ```
  final DataRange yDataRange;

  /// Current zoom/pan state.
  ///
  /// Controls the visible portion of data space. Affects transformations
  /// to/from viewport coordinates.
  ///
  /// - **No zoom/pan**: Use `ViewportState.identity()`
  /// - **Zoomed in**: zoomFactor > 1.0
  /// - **Panned**: panOffset != Point(0, 0)
  ///
  /// See [ViewportState] for zoom/pan behavior details.
  final ViewportState viewport;

  /// Series data for dataPoint → data transformations.
  ///
  /// Provides lookup capability for point-based coordinates. When transforming
  /// from `CoordinateSystem.dataPoint` (series index, point index) to
  /// `CoordinateSystem.data` (x, y values), this list is queried.
  ///
  /// **Format**: List of series in rendering order (front to back)
  /// **Usage**: `series[seriesIndex].points[pointIndex]`
  ///
  /// May be empty if dataPoint transformations are not needed.
  final List<ChartSeries> series;

  /// Optional marker offset for annotation positioning (in logical pixels).
  ///
  /// When transforming to `CoordinateSystem.marker`, this offset is applied
  /// after data-to-screen transformation. Useful for:
  /// - Callout annotations
  /// - Tooltip positioning
  /// - Label placement with fixed pixel offsets
  ///
  /// **Coordinate System**: Screen (logical pixels)
  /// **Default**: null (no offset)
  ///
  /// Example:
  /// ```dart
  /// // Position annotation 20px right, 10px up from data point
  /// markerOffset: Point(20.0, -10.0)
  /// ```
  final Point<double>? markerOffset;

  /// Animation progress (0.0 = start, 1.0 = end).
  ///
  /// Used for animated transitions between coordinate states. Typically
  /// interpolated linearly:
  ///
  /// ```dart
  /// final current = start + (end - start) * animationProgress;
  /// ```
  ///
  /// **Range**: [0.0, 1.0]
  /// **Default**: 1.0 (fully transitioned)
  final double animationProgress;

  /// Device pixel density ratio.
  ///
  /// Ratio of physical pixels to logical pixels. Used for:
  /// - Mouse → Screen transformations (raw event coords to logical pixels)
  /// - High-DPI display support
  /// - Precise pixel rendering
  ///
  /// **Typical values**:
  /// - 1.0: Standard display
  /// - 2.0: Retina/@2x display
  /// - 3.0: High-DPI mobile display
  ///
  /// **Default**: 1.0
  final double devicePixelRatio;

  /// Create copy with updated viewport (zoom/pan).
  ///
  /// Returns new context with modified viewport state. All other fields
  /// are copied unchanged.
  ///
  /// **Example**:
  /// ```dart
  /// // Zoom in 2x
  /// final zoomed = context.withViewport(
  ///   context.viewport.withZoom(2.0),
  /// );
  ///
  /// // Pan 10 units right
  /// final panned = context.withViewport(
  ///   context.viewport.withPan(Point(10.0, 0.0)),
  /// );
  /// ```
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
  ///
  /// Returns new context with modified marker offset. Use for dynamic
  /// annotation positioning.
  ///
  /// **Example**:
  /// ```dart
  /// // Position tooltip 20px above point
  /// final withTooltip = context.withMarkerOffset(Point(0.0, -20.0));
  /// ```
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
  ///
  /// Returns new context with modified animation progress. Use for animated
  /// transitions between states.
  ///
  /// **Progress values**:
  /// - 0.0: Animation start
  /// - 0.5: Halfway through
  /// - 1.0: Animation complete
  ///
  /// **Example**:
  /// ```dart
  /// // Update animation frame
  /// final frame = context.withAnimationProgress(0.5);
  /// ```
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
  ///
  /// Returns new context with modified X and Y data ranges. Use when
  /// axis bounds change (e.g., auto-scaling, user zoom).
  ///
  /// **Example**:
  /// ```dart
  /// // Update to new data ranges
  /// final rescaled = context.withDataRanges(
  ///   DataRange(min: 0, max: 200),
  ///   DataRange(min: -100, max: 100),
  /// );
  /// ```
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
  /// Combines all fields to create unique key for transformation matrix caching.
  /// Cache invalidates when any field changes.
  ///
  /// **Note**: series list is NOT hashed (would be expensive). If series
  /// content changes, consider creating new context instance.
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
  ///
  /// Two contexts are equal if all their fields are equal. Used for:
  /// - Cache key comparison
  /// - Detecting state changes
  /// - Avoiding redundant transformations
  ///
  /// **Note**: series list compared by reference (==), not deep equality.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TransformContext &&
            widgetSize == other.widgetSize &&
            chartAreaBounds == other.chartAreaBounds &&
            xDataRange == other.xDataRange &&
            yDataRange == other.yDataRange &&
            viewport == other.viewport &&
            series == other.series &&
            markerOffset == other.markerOffset &&
            animationProgress == other.animationProgress &&
            devicePixelRatio == other.devicePixelRatio);
  }

  /// String representation for debugging.
  ///
  /// Shows key context information in human-readable format.
  @override
  String toString() => 'TransformContext('
      'widgetSize: $widgetSize, '
      'chartAreaBounds: $chartAreaBounds, '
      'xDataRange: $xDataRange, '
      'yDataRange: $yDataRange, '
      'viewport: $viewport, '
      'series: ${series.length} series, '
      'markerOffset: $markerOffset, '
      'animationProgress: $animationProgress, '
      'devicePixelRatio: $devicePixelRatio)';
}
