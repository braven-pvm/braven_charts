/// Universal coordinate transformation engine for BravenCharts.
///
/// Provides stateless, bidirectional transformations between all 8 coordinate
/// systems used in chart rendering. Optimized for performance with:
/// - Matrix caching per context
/// - SIMD batch transformations
/// - Zero allocations in steady-state
///
/// **Constitutional Compliance**:
/// - Pure Flutter (dart:math, dart:ui only)
/// - Performance: <1ms for 10K point batch transformation
/// - Testable: Stateless, deterministic, no side effects
///
/// **Usage Example**:
/// ```dart
/// final transformer = UniversalCoordinateTransformer();
///
/// // Single point transformation
/// final screenPoint = transformer.transform(
///   Point(50.0, 25.0),
///   from: CoordinateSystem.data,
///   to: CoordinateSystem.screen,
///   context: transformContext,
/// );
///
/// // Batch transformation (optimized)
/// final screenPoints = transformer.transformBatch(
///   dataPoints,
///   from: CoordinateSystem.data,
///   to: CoordinateSystem.screen,
///   context: transformContext,
/// );
/// ```
///
/// See also:
/// - [CoordinateSystem] - All 8 coordinate systems
/// - [TransformContext] - Context for transformations
/// - [TransformMatrix] - Internal matrix implementation
library;

import 'dart:math' show Point;
import 'dart:ui' show Rect;

import 'coordinate_system.dart';
import 'transform_context.dart';
import 'transform_matrix.dart';

/// Universal coordinate transformer implementing all 56 bidirectional paths.
///
/// This class provides transformations between any two of the 8 coordinate
/// systems: mouse, screen, chartArea, data, dataPoint, marker, viewport,
/// normalized.
///
/// **Transformation Paths**:
/// - **Direct paths** (7): Optimized single-matrix transformations
/// - **Transitive paths** (49): Composed from direct paths
///
/// **Performance Targets**:
/// - Single transform: O(1), <100ns per point
/// - Batch transform: <1ms for 10,000 points (constitutional requirement)
/// - Cache hit rate: >90% for transformation matrices
///
/// **Implementation Strategy**:
/// 1. Cache transformation matrices per context (hash-based lookup)
/// 2. Use SIMD for batch transformations (4 points in parallel)
/// 3. Compose complex paths from simpler ones (matrix multiplication)
///
/// See also:
/// - [transform] - Transform single point
/// - [transformBatch] - Transform point batch (optimized)
/// - [validate] - Validate point in coordinate system
/// - [getValidRange] - Get valid range for coordinate system
class UniversalCoordinateTransformer {
  /// Create a new universal coordinate transformer.
  ///
  /// The transformer is stateless - all context is passed via method parameters.
  /// Multiple transformers can be used concurrently (thread-safe).
  UniversalCoordinateTransformer();

  /// Internal matrix cache: context hash → transformation matrix.
  ///
  /// Cache key format: `(fromSystem.index << 16) | (toSystem.index << 8) | contextHash`
  ///
  /// This cache dramatically improves performance for repeated transformations
  /// with the same context (e.g., transforming 10K points in same frame).
  ///
  /// **Cache Management**:
  /// - Entries created on-demand during first transformation
  /// - No eviction policy (bounded by number of unique contexts)
  /// - Typical size: <100 entries (8 systems × ~10 unique contexts)
  final Map<int, TransformMatrix> _matrixCache = {};

  /// Transform a single point from one coordinate system to another.
  ///
  /// This is the primary transformation method. It handles all 56 possible
  /// transformation paths between the 8 coordinate systems.
  ///
  /// **Parameters**:
  /// - [point]: Point in source coordinate system
  /// - [from]: Source coordinate system
  /// - [to]: Destination coordinate system
  /// - [context]: Transformation context (viewport, data ranges, etc.)
  ///
  /// **Returns**: Point in destination coordinate system
  ///
  /// **Throws**: [ArgumentError] if transformation is invalid
  ///
  /// **Performance**: O(1) - constant time after first matrix computation
  ///
  /// **Accuracy**: Round-trip within 0.01 pixels
  ///
  /// **Example**:
  /// ```dart
  /// // Transform data coordinate to screen pixels
  /// final dataPoint = Point(50.0, 25.0);
  /// final screenPoint = transformer.transform(
  ///   dataPoint,
  ///   from: CoordinateSystem.data,
  ///   to: CoordinateSystem.screen,
  ///   context: transformContext,
  /// );
  /// ```
  Point<double> transform(
    Point<double> point, {
    required CoordinateSystem from,
    required CoordinateSystem to,
    required TransformContext context,
  }) {
    // Identity transformation (same system)
    if (from == to) return point;

    // Direct transformation paths (7 core paths)
    // These are the fundamental transformations that all others build upon
    
    // Path 1: mouse ↔ screen (identity when devicePixelRatio = 1.0)
    if (from == CoordinateSystem.mouse && to == CoordinateSystem.screen) {
      return _mouseToScreen(point, context);
    }
    if (from == CoordinateSystem.screen && to == CoordinateSystem.mouse) {
      return _screenToMouse(point, context);
    }

    // Path 2: screen ↔ chartArea (translation by chartAreaBounds offset)
    if (from == CoordinateSystem.screen && to == CoordinateSystem.chartArea) {
      return _screenToChartArea(point, context);
    }
    if (from == CoordinateSystem.chartArea && to == CoordinateSystem.screen) {
      return _chartAreaToScreen(point, context);
    }

    // Path 3: chartArea ↔ data (scale + translate + Y-flip)
    if (from == CoordinateSystem.chartArea && to == CoordinateSystem.data) {
      return _chartAreaToData(point, context);
    }
    if (from == CoordinateSystem.data && to == CoordinateSystem.chartArea) {
      return _dataToChartArea(point, context);
    }

    // Path 4: data ↔ viewport (scale by zoom + translate by pan)
    if (from == CoordinateSystem.data && to == CoordinateSystem.viewport) {
      return _dataToViewport(point, context);
    }
    if (from == CoordinateSystem.viewport && to == CoordinateSystem.data) {
      return _viewportToData(point, context);
    }

    // Path 5: data ↔ dataPoint (index lookup in series)
    if (from == CoordinateSystem.data && to == CoordinateSystem.dataPoint) {
      return _dataToDataPoint(point, context);
    }
    if (from == CoordinateSystem.dataPoint && to == CoordinateSystem.data) {
      return _dataPointToData(point, context);
    }

    // Path 6: data ↔ marker (apply markerOffset)
    if (from == CoordinateSystem.data && to == CoordinateSystem.marker) {
      return _dataToMarker(point, context);
    }
    if (from == CoordinateSystem.marker && to == CoordinateSystem.data) {
      return _markerToData(point, context);
    }

    // Path 7: chartArea ↔ normalized (scale to/from 0.0-1.0)
    if (from == CoordinateSystem.chartArea && to == CoordinateSystem.normalized) {
      return _chartAreaToNormalized(point, context);
    }
    if (from == CoordinateSystem.normalized && to == CoordinateSystem.chartArea) {
      return _normalizedToChartArea(point, context);
    }

    // Transitive paths: compose from direct paths
    // This will be implemented in T026
    throw UnimplementedError(
      'Transitive path from $from to $to not yet implemented. '
      'Will be added in T026 via path composition.',
    );
  }

  /// Transform a batch of points from one coordinate system to another.
  ///
  /// This method is optimized for large point sets using:
  /// - Matrix caching (compute once, apply many times)
  /// - SIMD operations (process 4 points in parallel)
  /// - Minimal allocations (reuse intermediate results)
  ///
  /// **Parameters**:
  /// - [points]: List of points in source coordinate system
  /// - [from]: Source coordinate system
  /// - [to]: Destination coordinate system
  /// - [context]: Transformation context
  ///
  /// **Returns**: List of points in destination coordinate system
  ///
  /// **Performance**: Must achieve <1ms for 10,000 points
  ///
  /// **Example**:
  /// ```dart
  /// final dataPoints = List.generate(
  ///   10000,
  ///   (i) => Point(i / 100.0, sin(i / 100.0)),
  /// );
  ///
  /// final stopwatch = Stopwatch()..start();
  /// final screenPoints = transformer.transformBatch(
  ///   dataPoints,
  ///   from: CoordinateSystem.data,
  ///   to: CoordinateSystem.screen,
  ///   context: transformContext,
  /// );
  /// stopwatch.stop();
  ///
  /// print('Transformed ${dataPoints.length} points in ${stopwatch.elapsedMicroseconds}μs');
  /// // Expected: <1000μs (1ms)
  /// ```
  List<Point<double>> transformBatch(
    List<Point<double>> points, {
    required CoordinateSystem from,
    required CoordinateSystem to,
    required TransformContext context,
  }) {
    // TODO: Implement batch transformation in T025-T026 with SIMD optimization
    throw UnimplementedError(
      'transformBatch() will be implemented in T025 (direct paths) and T026 (transitive paths) with SIMD',
    );
  }

  /// Validate a point in a specific coordinate system.
  ///
  /// Performs comprehensive validation:
  /// - No NaN or infinity values
  /// - Point within valid range for coordinate system
  /// - Required context fields are present
  ///
  /// **Parameters**:
  /// - [point]: Point to validate
  /// - [system]: Coordinate system for validation
  /// - [context]: Transformation context
  ///
  /// **Returns**: [ValidationResult] with detailed error if invalid
  ///
  /// **Example**:
  /// ```dart
  /// final result = transformer.validate(
  ///   Point(150.5, -10.3),
  ///   CoordinateSystem.normalized,
  ///   context,
  /// );
  ///
  /// if (!result.isValid) {
  ///   print(result.errorMessage);
  ///   // "Point (150.5, -10.3) outside valid range for normalized.
  ///   //  Valid range: [0.0, 0.0] to [1.0, 1.0].
  ///   //  Normalized coordinates must be in [0.0, 1.0] range."
  /// }
  /// ```
  ValidationResult validate(
    Point<double> point,
    CoordinateSystem system,
    TransformContext context,
  ) {
    // TODO: Implement validation in T027-T029
    throw UnimplementedError(
      'validate() will be implemented in T027 (validation logic)',
    );
  }

  /// Get the valid range for a coordinate system given current context.
  ///
  /// Returns the bounding rectangle defining valid (min, min) to (max, max)
  /// bounds for points in the specified coordinate system.
  ///
  /// **Parameters**:
  /// - [system]: Coordinate system to get range for
  /// - [context]: Transformation context
  ///
  /// **Returns**: Rectangle defining valid bounds
  ///
  /// **Example**:
  /// ```dart
  /// final dataRange = transformer.getValidRange(
  ///   CoordinateSystem.data,
  ///   context,
  /// );
  /// // Returns: Rect.fromLTRB(0, -50, 100, 50) based on context.xDataRange, yDataRange
  ///
  /// final screenRange = transformer.getValidRange(
  ///   CoordinateSystem.screen,
  ///   context,
  /// );
  /// // Returns: Rect.fromLTWH(0, 0, 800, 600) based on context.widgetSize
  ///
  /// final normalizedRange = transformer.getValidRange(
  ///   CoordinateSystem.normalized,
  ///   context,
  /// );
  /// // Returns: Rect.fromLTWH(0, 0, 1, 1) (always [0, 1])
  /// ```
  Rect getValidRange(
    CoordinateSystem system,
    TransformContext context,
  ) {
    // TODO: Implement in T028
    throw UnimplementedError(
      'getValidRange() will be implemented in T028 (validation ranges)',
    );
  }

  // ========================================================================
  // Direct Transformation Path Implementations
  // ========================================================================
  // These 14 methods (7 bidirectional paths) form the foundation of all
  // coordinate transformations. All other paths are composed from these.

  /// Transform from mouse to screen coordinates.
  /// 
  /// **Transformation**: Multiply by devicePixelRatio (usually identity)
  Point<double> _mouseToScreen(Point<double> point, TransformContext context) {
    final ratio = context.devicePixelRatio;
    return Point(point.x / ratio, point.y / ratio);
  }

  /// Transform from screen to mouse coordinates.
  /// 
  /// **Transformation**: Divide by devicePixelRatio (usually identity)
  Point<double> _screenToMouse(Point<double> point, TransformContext context) {
    final ratio = context.devicePixelRatio;
    return Point(point.x * ratio, point.y * ratio);
  }

  /// Transform from screen to chartArea coordinates.
  /// 
  /// **Transformation**: Translate by chartAreaBounds offset
  /// ```
  /// chartArea.x = screen.x - chartAreaBounds.left
  /// chartArea.y = screen.y - chartAreaBounds.top
  /// ```
  Point<double> _screenToChartArea(Point<double> point, TransformContext context) {
    final bounds = context.chartAreaBounds;
    return Point(
      point.x - bounds.left,
      point.y - bounds.top,
    );
  }

  /// Transform from chartArea to screen coordinates.
  /// 
  /// **Transformation**: Translate by chartAreaBounds offset
  /// ```
  /// screen.x = chartArea.x + chartAreaBounds.left
  /// screen.y = chartArea.y + chartAreaBounds.top
  /// ```
  Point<double> _chartAreaToScreen(Point<double> point, TransformContext context) {
    final bounds = context.chartAreaBounds;
    return Point(
      point.x + bounds.left,
      point.y + bounds.top,
    );
  }

  /// Transform from chartArea to data coordinates.
  /// 
  /// **Transformation**: Scale + Y-flip
  /// ```
  /// data.x = xMin + (chartArea.x / chartArea.width) * (xMax - xMin)
  /// data.y = yMax - (chartArea.y / chartArea.height) * (yMax - yMin)
  /// ```
  /// 
  /// Note: Y-axis is flipped because screen Y increases downward,
  /// but data Y typically increases upward.
  Point<double> _chartAreaToData(Point<double> point, TransformContext context) {
    final bounds = context.chartAreaBounds;
    final xRange = context.xDataRange;
    final yRange = context.yDataRange;

    final xScale = (xRange.max - xRange.min) / bounds.width;
    final yScale = (yRange.max - yRange.min) / bounds.height;

    return Point(
      xRange.min + point.x * xScale,
      yRange.max - point.y * yScale, // Y-flip
    );
  }

  /// Transform from data to chartArea coordinates.
  /// 
  /// **Transformation**: Scale + Y-flip
  /// ```
  /// chartArea.x = (data.x - xMin) / (xMax - xMin) * chartArea.width
  /// chartArea.y = (yMax - data.y) / (yMax - yMin) * chartArea.height
  /// ```
  Point<double> _dataToChartArea(Point<double> point, TransformContext context) {
    final bounds = context.chartAreaBounds;
    final xRange = context.xDataRange;
    final yRange = context.yDataRange;

    final xScale = bounds.width / (xRange.max - xRange.min);
    final yScale = bounds.height / (yRange.max - yRange.min);

    return Point(
      (point.x - xRange.min) * xScale,
      (yRange.max - point.y) * yScale, // Y-flip
    );
  }

  /// Transform from data to viewport coordinates.
  /// 
  /// **Transformation**: Apply viewport pan offset
  /// ```
  /// viewport.x = data.x - panOffset.x
  /// viewport.y = data.y - panOffset.y
  /// ```
  /// 
  /// Note: Viewport represents the visible data range after zoom/pan.
  /// The pan offset shifts the data coordinate system.
  Point<double> _dataToViewport(Point<double> point, TransformContext context) {
    final panOffset = context.viewport.panOffset;
    return Point(
      point.x - panOffset.x,
      point.y - panOffset.y,
    );
  }

  /// Transform from viewport to data coordinates.
  /// 
  /// **Transformation**: Apply inverse of pan offset
  /// ```
  /// data.x = viewport.x + panOffset.x
  /// data.y = viewport.y + panOffset.y
  /// ```
  Point<double> _viewportToData(Point<double> point, TransformContext context) {
    final panOffset = context.viewport.panOffset;
    return Point(
      point.x + panOffset.x,
      point.y + panOffset.y,
    );
  }

  /// Transform from data to dataPoint (index) coordinates.
  /// 
  /// **Transformation**: Find nearest point in series
  /// ```
  /// dataPoint.x = series index (0 to series.length-1)
  /// dataPoint.y = point index (0 to series[x].points.length-1)
  /// ```
  /// 
  /// This is a reverse lookup - find which series/point is closest to
  /// the given data coordinate.
  Point<double> _dataToDataPoint(Point<double> point, TransformContext context) {
    if (context.series.isEmpty) {
      throw ArgumentError('Cannot transform to dataPoint: no series in context');
    }

    double minDistance = double.infinity;
    int bestSeriesIndex = 0;
    int bestPointIndex = 0;

    // Search all series for nearest point
    for (var seriesIdx = 0; seriesIdx < context.series.length; seriesIdx++) {
      final series = context.series[seriesIdx];
      for (var pointIdx = 0; pointIdx < series.points.length; pointIdx++) {
        final dataPoint = series.points[pointIdx];
        final dx = dataPoint.x - point.x;
        final dy = dataPoint.y - point.y;
        final distance = dx * dx + dy * dy; // Squared distance (faster)

        if (distance < minDistance) {
          minDistance = distance;
          bestSeriesIndex = seriesIdx;
          bestPointIndex = pointIdx;
        }
      }
    }

    return Point(bestSeriesIndex.toDouble(), bestPointIndex.toDouble());
  }

  /// Transform from dataPoint (index) to data coordinates.
  /// 
  /// **Transformation**: Lookup point value in series
  /// ```
  /// data.x = series[dataPoint.x].points[dataPoint.y].x
  /// data.y = series[dataPoint.x].points[dataPoint.y].y
  /// ```
  Point<double> _dataPointToData(Point<double> point, TransformContext context) {
    final seriesIdx = point.x.round();
    final pointIdx = point.y.round();

    if (seriesIdx < 0 || seriesIdx >= context.series.length) {
      throw RangeError.index(
        seriesIdx,
        context.series,
        'seriesIndex',
        'Series index out of range',
        context.series.length,
      );
    }

    final series = context.series[seriesIdx];
    if (pointIdx < 0 || pointIdx >= series.points.length) {
      throw RangeError.index(
        pointIdx,
        series.points,
        'pointIndex',
        'Point index out of range for series $seriesIdx',
        series.points.length,
      );
    }

    final dataPoint = series.points[pointIdx];
    return Point(dataPoint.x, dataPoint.y);
  }

  /// Transform from data to marker coordinates.
  /// 
  /// **Transformation**: data → chartArea → apply marker offset
  /// ```
  /// marker = chartArea + markerOffset
  /// ```
  /// 
  /// Marker offset is applied in screen pixels (chartArea space).
  Point<double> _dataToMarker(Point<double> point, TransformContext context) {
    // First transform to chartArea
    final chartAreaPoint = _dataToChartArea(point, context);

    // Apply marker offset (if any)
    final offset = context.markerOffset;
    if (offset == null) {
      return chartAreaPoint; // No offset = marker coords = chartArea coords
    }

    return Point(
      chartAreaPoint.x + offset.x,
      chartAreaPoint.y + offset.y,
    );
  }

  /// Transform from marker to data coordinates.
  /// 
  /// **Transformation**: Remove marker offset → chartArea → data
  Point<double> _markerToData(Point<double> point, TransformContext context) {
    // Remove marker offset
    final offset = context.markerOffset;
    final chartAreaPoint = offset == null
        ? point
        : Point(point.x - offset.x, point.y - offset.y);

    // Transform to data coordinates
    return _chartAreaToData(chartAreaPoint, context);
  }

  /// Transform from chartArea to normalized coordinates.
  /// 
  /// **Transformation**: Scale to [0.0, 1.0] range
  /// ```
  /// normalized.x = chartArea.x / chartArea.width
  /// normalized.y = chartArea.y / chartArea.height
  /// ```
  Point<double> _chartAreaToNormalized(Point<double> point, TransformContext context) {
    final bounds = context.chartAreaBounds;
    return Point(
      point.x / bounds.width,
      point.y / bounds.height,
    );
  }

  /// Transform from normalized to chartArea coordinates.
  /// 
  /// **Transformation**: Scale from [0.0, 1.0] range
  /// ```
  /// chartArea.x = normalized.x * chartArea.width
  /// chartArea.y = normalized.y * chartArea.height
  /// ```
  Point<double> _normalizedToChartArea(Point<double> point, TransformContext context) {
    final bounds = context.chartAreaBounds;
    return Point(
      point.x * bounds.width,
      point.y * bounds.height,
    );
  }

  /// Compute cache key for transformation matrix.
  ///
  /// Cache key format combines:
  /// - Source system (bits 16-23)
  /// - Destination system (bits 8-15)
  /// - Context hash (bits 0-7, truncated)
  ///
  /// This allows efficient lookup while keeping different contexts separate.
  ///
  /// **Internal method** - not part of public API.
  int _getCacheKey(
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  ) {
    return (from.index << 16) | (to.index << 8) | (context.hashCode & 0xFF);
  }
}

/// Validation result for coordinate transformations.
///
/// Provides actionable error messages when validation fails, helping developers
/// quickly identify and fix coordinate-related issues.
///
/// See also:
/// - [ValidationErrorType] - Types of validation errors
/// - [UniversalCoordinateTransformer.validate] - Validate points
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });

  /// Factory for successful validation.
  ///
  /// **Example**:
  /// ```dart
  /// return ValidationResult.valid();
  /// ```
  factory ValidationResult.valid() {
    return const ValidationResult._(isValid: true);
  }

  /// Factory for failed validation with error details.
  ///
  /// **Parameters**:
  /// - [message]: Human-readable error message
  /// - [type]: Type of validation error
  ///
  /// **Example**:
  /// ```dart
  /// return ValidationResult.invalid(
  ///   'Point (${point.x}, ${point.y}) contains NaN or infinity',
  ///   ValidationErrorType.invalidValue,
  /// );
  /// ```
  factory ValidationResult.invalid(
    String message,
    ValidationErrorType type,
  ) {
    return ValidationResult._(
      isValid: false,
      errorMessage: message,
      errorType: type,
    );
  }

  /// Whether the validation passed.
  final bool isValid;

  /// Human-readable error message (null if valid).
  ///
  /// Error messages include:
  /// - Actual coordinate values
  /// - Expected range/constraints
  /// - Suggested fix (e.g., "Did you mean CoordinateSystem.data?")
  final String? errorMessage;

  /// Type of validation error (null if valid).
  final ValidationErrorType? errorType;

  @override
  String toString() {
    if (isValid) return 'ValidationResult.valid()';
    return 'ValidationResult.invalid(type: $errorType, message: "$errorMessage")';
  }
}

/// Types of validation errors for coordinate transformations.
///
/// Each error type corresponds to a specific validation failure:
/// - **outOfRange**: Point outside valid bounds for coordinate system
/// - **invalidValue**: Point contains NaN or infinity
/// - **missingContext**: Required context field is null
/// - **unsupportedPath**: Transformation path not implemented
///
/// See also:
/// - [ValidationResult] - Validation result container
/// - [UniversalCoordinateTransformer.validate] - Validation method
enum ValidationErrorType {
  /// Point outside valid range for coordinate system.
  ///
  /// **Example**:
  /// ```dart
  /// // Normalized coordinates must be [0.0, 1.0]
  /// ValidationErrorType.outOfRange for Point(1.5, -0.3)
  /// ```
  outOfRange,

  /// Point contains NaN or infinity.
  ///
  /// **Example**:
  /// ```dart
  /// ValidationErrorType.invalidValue for Point(double.nan, 10.0)
  /// ValidationErrorType.invalidValue for Point(50.0, double.infinity)
  /// ```
  invalidValue,

  /// Required context field is null.
  ///
  /// **Example**:
  /// ```dart
  /// // Marker transformation requires markerOffset
  /// ValidationErrorType.missingContext when context.markerOffset == null
  /// ```
  missingContext,

  /// Transformation path not implemented.
  ///
  /// **Example**:
  /// ```dart
  /// // All paths should be implemented; this is a fallback
  /// ValidationErrorType.unsupportedPath for unimplemented transformation
  /// ```
  unsupportedPath,
}
