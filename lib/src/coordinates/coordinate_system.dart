/// CoordinateSystem Enum
///
/// Defines all 8 coordinate systems used in chart rendering, interaction,
/// and annotation positioning.
///
/// Constitutional compliance:
/// - Pure Flutter: No external dependencies
/// - Type-safe: Compile-time coordinate system validation
/// - Exhaustive: All transformations must handle all 8 systems
library;

/// Enumeration of all coordinate systems used in BravenCharts.
///
/// Each coordinate system has a specific origin, range, units, and primary
/// use case. The Universal Coordinate Transformer provides bidirectional
/// transformations between any two systems.
///
/// **Coordinate Systems:**
///
/// 1. **mouse** - Raw Flutter event coordinates (physical pixels)
///    - Origin: Top-left of Flutter widget
///    - Range: (0,0) to (widget.width, widget.height)
///    - Use: Touch/mouse event processing
///
/// 2. **screen** - Screen pixel coordinates (logical pixels)
///    - Origin: Top-left of widget
///    - Range: (0,0) to (widget.width, widget.height)
///    - Use: Canvas drawing, UI layout
///
/// 3. **chartArea** - Chart drawing area excluding axes/legend
///    - Origin: Top-left of plot area
///    - Range: (0,0) to (chartArea.width, chartArea.height)
///    - Use: Rendering within chart bounds
///
/// 4. **data** - Logical data space coordinates
///    - Origin: Data-dependent (may be negative)
///    - Range: (xAxis.min, yAxis.min) to (xAxis.max, yAxis.max)
///    - Use: Business logic, data queries
///
/// 5. **dataPoint** - Index-based series data point references
///    - Origin: (0, 0) = first series, first point
///    - Range: (0, 0) to (series.length-1, maxPoints-1)
///    - Use: Direct series data access
///
/// 6. **marker** - Annotation positioning with pixel offsets
///    - Origin: Data position + marker offset
///    - Range: Same as chartArea
///    - Use: Annotation anchoring
///
/// 7. **viewport** - Zoom/pan adjusted coordinates
///    - Origin: Viewport-dependent (moves with pan)
///    - Range: Subset of data range
///    - Use: Zoomed/panned visualization
///
/// 8. **normalized** - Normalized coordinates (0.0-1.0)
///    - Origin: (0, 0) = top-left of chart area
///    - Range: (0.0, 0.0) to (1.0, 1.0)
///    - Use: Percentage-based layout
///
/// **Transformation Paths:**
///
/// The transformer supports all 56 bidirectional transformation paths
/// (8 systems × 7 destinations). Common patterns:
///
/// ```dart
/// // Mouse click to data
/// final dataPoint = transformer.transform(
///   mousePoint,
///   from: CoordinateSystem.mouse,
///   to: CoordinateSystem.data,
///   context: context,
/// );
///
/// // Data to screen for rendering
/// final screenPoint = transformer.transform(
///   dataPoint,
///   from: CoordinateSystem.data,
///   to: CoordinateSystem.screen,
///   context: context,
/// );
/// ```
///
/// See also:
/// - [CoordinateTransformer] for transformation methods
/// - [TransformContext] for required transformation state
enum CoordinateSystem {
  /// Raw Flutter event coordinates (mouse, touch).
  ///
  /// **Origin:** Top-left of Flutter widget
  /// **Range:** (0,0) to (widget.width, widget.height)
  /// **Units:** Physical pixels
  /// **Primary Use:** Raw event coordinate capture
  mouse,

  /// Screen pixel coordinates within Flutter widget.
  ///
  /// **Origin:** Top-left of widget
  /// **Range:** (0,0) to (widget.width, widget.height)
  /// **Units:** Logical pixels
  /// **Primary Use:** Canvas drawing and UI layout
  screen,

  /// Coordinates within chart drawing area (excluding axes/legend).
  ///
  /// **Origin:** Top-left of plot area
  /// **Range:** (0,0) to (chartArea.width, chartArea.height)
  /// **Units:** Logical pixels
  /// **Primary Use:** Rendering within chart bounds
  chartArea,

  /// Logical data space coordinates.
  ///
  /// **Origin:** Data-dependent (may be negative)
  /// **Range:** (xAxis.min, yAxis.min) to (xAxis.max, yAxis.max)
  /// **Units:** Data units (dollars, dates, temperatures, etc.)
  /// **Primary Use:** Business logic and data queries
  data,

  /// Index-based references to series data points.
  ///
  /// **Origin:** (0, 0) = first series, first point
  /// **Range:** (0, 0) to (series.length-1, maxPoints-1)
  /// **Units:** Integer indices
  /// **Primary Use:** Direct array access to series data
  dataPoint,

  /// Annotation positioning with offsets.
  ///
  /// **Origin:** Data position + marker-specific offset
  /// **Range:** Same as chartArea
  /// **Units:** Logical pixels
  /// **Primary Use:** Annotation and marker anchoring
  marker,

  /// Zoom/pan adjusted coordinates.
  ///
  /// **Origin:** Viewport-dependent (moves with pan)
  /// **Range:** Subset of data range
  /// **Units:** Data units scaled by zoom
  /// **Primary Use:** Zoomed and panned visualization
  viewport,

  /// Normalized coordinates (0.0-1.0 relative to chart area).
  ///
  /// **Origin:** (0, 0) = top-left of chart area
  /// **Range:** (0.0, 0.0) to (1.0, 1.0)
  /// **Units:** Percentage of chart area dimensions
  /// **Primary Use:** Percentage-based layout calculations
  normalized,
}
