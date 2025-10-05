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
    // TODO: Implement transformation logic in T025-T026
    throw UnimplementedError(
      'transform() will be implemented in T025 (direct paths) and T026 (transitive paths)',
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
