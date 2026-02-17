/// Contract: CoordinateTransformer Interface
///
/// Stateless interface for transforming points between any of the 8 coordinate
/// systems used in BravenCharts. All transformations are pure functions that
/// depend only on input parameters (no internal state).
///
/// Constitutional Compliance:
/// - Pure Flutter: Uses only dart:math (Point)
/// - Performance: <1ms batch transformation of 10K points
/// - Testable: Stateless, deterministic transformations
library;

import 'dart:math' show Point;

/// Enum defining all coordinate systems used in chart rendering.
///
/// Each coordinate system has a specific origin, range, and use case. The
/// transformer provides bidirectional transformations between any two systems.
enum CoordinateSystem {
  /// Raw Flutter event coordinates (mouse, touch).
  /// Origin: Top-left of Flutter widget
  /// Range: (0,0) to (widget.width, widget.height)
  /// Units: Physical pixels
  mouse,

  /// Screen pixel coordinates within Flutter widget.
  /// Origin: Top-left of widget
  /// Range: (0,0) to (widget.width, widget.height)
  /// Units: Logical pixels
  screen,

  /// Coordinates within chart drawing area (excluding axes/legend).
  /// Origin: Top-left of plot area
  /// Range: (0,0) to (chartArea.width, chartArea.height)
  /// Units: Logical pixels
  chartArea,

  /// Logical data space coordinates.
  /// Origin: Data-dependent (may be negative)
  /// Range: (xAxis.min, yAxis.min) to (xAxis.max, yAxis.max)
  /// Units: Data units (e.g., dollars, dates, temperatures)
  data,

  /// Index-based references to series data points.
  /// Origin: (0, 0) = first series, first point
  /// Range: (0, 0) to (series.length-1, maxPoints-1)
  /// Units: Integer indices
  dataPoint,

  /// Annotation positioning with offsets.
  /// Origin: Data position + marker-specific offset
  /// Range: Same as chartArea
  /// Units: Logical pixels
  marker,

  /// Zoom/pan adjusted coordinates.
  /// Origin: Viewport-dependent (moves with pan)
  /// Range: Subset of data range
  /// Units: Data units scaled by zoom
  viewport,

  /// Normalized coordinates (0.0-1.0 relative to chart area).
  /// Origin: (0, 0) = top-left of chart area
  /// Range: (0.0, 0.0) to (1.0, 1.0)
  /// Units: Percentage of chart area
  normalized,
}

/// Validation result for coordinate transformations.
///
/// Provides actionable error messages when validation fails, helping developers
/// quickly identify and fix coordinate-related issues.
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
  factory ValidationResult.valid() {
    return const ValidationResult._(isValid: true);
  }

  /// Factory for failed validation with error details.
  factory ValidationResult.invalid(String message, ValidationErrorType type) {
    return ValidationResult._(
      isValid: false,
      errorMessage: message,
      errorType: type,
    );
  }
}

/// Types of validation errors for coordinate transformations.
enum ValidationErrorType {
  /// Point outside valid range for coordinate system.
  outOfRange,

  /// Point contains NaN or infinity.
  invalidValue,

  /// Required context field is null.
  missingContext,

  /// Transformation path not implemented.
  unsupportedPath,
}

/// Abstract interface for coordinate transformations.
///
/// Implementations must:
/// 1. Be stateless (all context passed via parameters)
/// 2. Support all 56 bidirectional transformations (8 systems × 7 destinations)
/// 3. Provide validation with actionable error messages
/// 4. Meet performance targets (<1ms for 10K point batch)
///
/// Example usage:
/// ```dart
/// final transformer = UniversalCoordinateTransformer();
///
/// // Transform single point
/// final screenPoint = transformer.transform(
///   dataPoint,
///   from: CoordinateSystem.data,
///   to: CoordinateSystem.screen,
///   context: transformContext,
/// );
///
/// // Transform batch (optimized)
/// final screenPoints = transformer.transformBatch(
///   dataPoints,
///   from: CoordinateSystem.data,
///   to: CoordinateSystem.screen,
///   context: transformContext,
/// );
/// ```
abstract class CoordinateTransformer {
  /// Transform a single point from one coordinate system to another.
  ///
  /// Parameters:
  /// - [point]: Point in source coordinate system
  /// - [from]: Source coordinate system
  /// - [to]: Destination coordinate system
  /// - [context]: Transformation context (viewport, data ranges, etc.)
  ///
  /// Returns:
  ///   Point in destination coordinate system
  ///
  /// Throws:
  ///   ArgumentError if transformation is invalid (in debug mode)
  ///
  /// Performance:
  ///   O(1) - constant time transformation (matrix cached per context)
  ///
  /// Accuracy:
  ///   Round-trip accuracy within 0.01 pixels:
  ///   `transform(transform(p, A, B, ctx), B, A, ctx) ≈ p`
  Point<double> transform(
    Point<double> point,
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );

  /// Transform a batch of points from one coordinate system to another.
  ///
  /// This method is optimized for large point sets (10K+ points) using:
  /// - Matrix caching (compute once, apply many times)
  /// - SIMD operations (process 4 points in parallel)
  /// - Zero allocations (reuse Point objects from pool)
  ///
  /// Parameters:
  /// - [points]: List of points in source coordinate system
  /// - [from]: Source coordinate system
  /// - [to]: Destination coordinate system
  /// - [context]: Transformation context
  ///
  /// Returns:
  ///   List of points in destination coordinate system
  ///
  /// Performance:
  ///   Must achieve <1ms for 10,000 points (constitutional requirement)
  ///
  /// Example:
  /// ```dart
  /// final dataPoints = series.dataPoints; // 10K points
  /// final screenPoints = transformer.transformBatch(
  ///   dataPoints,
  ///   CoordinateSystem.data,
  ///   CoordinateSystem.screen,
  ///   context,
  /// ); // <1ms execution time
  /// ```
  List<Point<double>> transformBatch(
    List<Point<double>> points,
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );

  /// Validate a point in a specific coordinate system.
  ///
  /// Checks:
  /// - No NaN or infinity values
  /// - Point within valid range for coordinate system
  /// - Required context fields are present
  ///
  /// Parameters:
  /// - [point]: Point to validate
  /// - [system]: Coordinate system for validation
  /// - [context]: Transformation context
  ///
  /// Returns:
  ///   ValidationResult with detailed error message if invalid
  ///
  /// Example:
  /// ```dart
  /// final result = transformer.validate(
  ///   Point(150.5, -10.3),
  ///   CoordinateSystem.chartArea,
  ///   context,
  /// );
  ///
  /// if (!result.isValid) {
  ///   print(result.errorMessage);
  ///   // "Point (150.5, -10.3) outside valid range for chartArea.
  ///   //  Valid range: Rect(0, 0, 800, 600).
  ///   //  Check if point is in Data coordinates instead?"
  /// }
  /// ```
  ValidationResult validate(
    Point<double> point,
    CoordinateSystem system,
    TransformContext context,
  );

  /// Get the valid range for a coordinate system given current context.
  ///
  /// Parameters:
  /// - [system]: Coordinate system to get range for
  /// - [context]: Transformation context
  ///
  /// Returns:
  ///   Rectangle defining valid (min, min) to (max, max) bounds
  ///
  /// Example:
  /// ```dart
  /// final dataRange = transformer.getValidRange(
  ///   CoordinateSystem.data,
  ///   context,
  /// );
  /// // Returns: Rect.fromLTRB(xMin, yMin, xMax, yMax)
  ///
  /// final screenRange = transformer.getValidRange(
  ///   CoordinateSystem.screen,
  ///   context,
  /// );
  /// // Returns: Rect.fromLTWH(0, 0, widgetWidth, widgetHeight)
  /// ```
  Rect getValidRange(CoordinateSystem system, TransformContext context);
}

/// Placeholder for TransformContext (defined in separate contract file).
///
/// This is a forward declaration to avoid circular dependencies in contracts.
/// See transform_context.dart for full definition.
abstract class TransformContext {}

/// Placeholder for Rect (from dart:ui).
///
/// In actual implementation, import from dart:ui or define minimal Rect class.
abstract class Rect {}
