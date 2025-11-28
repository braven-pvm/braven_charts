// Copyright (c) 2025 braven_charts. All rights reserved.
// Coordinate Space Architecture - Transform Layer

import 'dart:ui';

/// Handles bidirectional conversion between DATA space and PLOT space.
///
/// **Purpose**: Manages viewport (visible data range) and provides all
/// necessary coordinate transformations for chart rendering and interaction.
///
/// **Coordinate Spaces**:
/// - **Data Space**: Logical data values (timestamps, prices, etc.)
/// - **Plot Space**: Physical pixels within plot area (0,0 → plotWidth,plotHeight)
///
/// **Usage**:
/// ```dart
/// final transform = ChartTransform(
///   dataXMin: 1609459200.0,  // Jan 1, 2021 timestamp
///   dataXMax: 1640995200.0,  // Jan 1, 2022 timestamp
///   dataYMin: 100.0,         // Price $100
///   dataYMax: 200.0,         // Price $200
///   plotWidth: 730.0,        // Plot area width in pixels
///   plotHeight: 540.0,       // Plot area height in pixels
/// );
///
/// // Transform data point to plot coordinates
/// final plotPos = transform.dataToPlot(1625097600, 150.0);
///
/// // Reverse transform for hit testing
/// final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);
/// ```
///
/// **Immutability**: All transformation operations return new instances.
/// Use `copyWith()` for partial updates or `zoom()`/`pan()` for viewport changes.
///
/// See COORDINATE_SPACE_ARCHITECTURE.md for complete design documentation.
class ChartTransform {
  /// Creates a chart transform with specified data viewport and plot dimensions.
  ///
  /// **Parameters**:
  /// - `dataXMin`, `dataXMax`: Visible data range on X-axis
  /// - `dataYMin`, `dataYMax`: Visible data range on Y-axis
  /// - `plotWidth`, `plotHeight`: Plot area dimensions in pixels
  /// - `invertY`: If true, Y=0 is at bottom (standard chart convention)
  ///
  /// **Constraints**:
  /// - `dataXMax` must be > `dataXMin`
  /// - `dataYMax` must be > `dataYMin`
  /// - `plotWidth` and `plotHeight` must be > 0
  const ChartTransform({
    required this.dataXMin,
    required this.dataXMax,
    required this.dataYMin,
    required this.dataYMax,
    required this.plotWidth,
    required this.plotHeight,
    this.invertY = true,
  })  : assert(dataXMax > dataXMin, 'dataXMax must be greater than dataXMin'),
        assert(dataYMax > dataYMin, 'dataYMax must be greater than dataYMin'),
        assert(plotWidth > 0, 'plotWidth must be positive'),
        assert(plotHeight > 0, 'plotHeight must be positive');

  /// Minimum visible data value on X-axis (left edge of viewport).
  final double dataXMin;

  /// Maximum visible data value on X-axis (right edge of viewport).
  final double dataXMax;

  /// Minimum visible data value on Y-axis (bottom edge if invertY=true).
  final double dataYMin;

  /// Maximum visible data value on Y-axis (top edge if invertY=true).
  final double dataYMax;

  /// Width of plot area in pixels.
  final double plotWidth;

  /// Height of plot area in pixels.
  final double plotHeight;

  /// If true, Y-axis is inverted (Y=0 at bottom, standard chart convention).
  /// If false, Y-axis follows canvas convention (Y=0 at top).
  final bool invertY;

  // ============================================================================
  // Computed Properties
  // ============================================================================

  /// Width of visible data range on X-axis.
  double get dataXRange => dataXMax - dataXMin;

  /// Height of visible data range on Y-axis.
  double get dataYRange => dataYMax - dataYMin;

  /// Scale factor: data units per pixel on X-axis.
  double get dataPerPixelX => dataXRange / plotWidth;

  /// Scale factor: data units per pixel on Y-axis.
  double get dataPerPixelY => dataYRange / plotHeight;

  /// Scale factor: pixels per data unit on X-axis.
  double get pixelsPerDataX => plotWidth / dataXRange;

  /// Scale factor: pixels per data unit on Y-axis.
  double get pixelsPerDataY => plotHeight / dataYRange;

  /// Visible data bounds as a Rect (for viewport queries).
  Rect get visibleDataBounds => Rect.fromLTRB(
        dataXMin,
        dataYMin,
        dataXMax,
        dataYMax,
      );

  // ============================================================================
  // Core Transformations
  // ============================================================================

  /// Converts a data coordinate to plot coordinate.
  ///
  /// **Example**:
  /// ```dart
  /// // Data point: timestamp=1625097600, price=150.0
  /// final plotPos = transform.dataToPlot(1625097600, 150.0);
  /// // Result: Offset(365.0, 270.0) in plot space
  /// ```
  ///
  /// **Coordinate Spaces**:
  /// - Input: Data space (meaningful values)
  /// - Output: Plot space (0,0 → plotWidth,plotHeight)
  Offset dataToPlot(double dataX, double dataY) {
    // Calculate relative position in data range [0, 1]
    final relativeX = (dataX - dataXMin) / dataXRange;
    final relativeY = (dataY - dataYMin) / dataYRange;

    // Convert to plot pixels
    final plotX = relativeX * plotWidth;
    final plotY = invertY
        ? (1.0 - relativeY) * plotHeight // Invert: Y=0 at bottom
        : relativeY * plotHeight; // Standard: Y=0 at top

    return Offset(plotX, plotY);
  }

  /// Converts a plot coordinate to data coordinate.
  ///
  /// **Example**:
  /// ```dart
  /// // Hit test at plot position (365.0, 270.0)
  /// final dataPos = transform.plotToData(365.0, 270.0);
  /// // Result: Offset(1625097600, 150.0) in data space
  /// ```
  ///
  /// **Coordinate Spaces**:
  /// - Input: Plot space (0,0 → plotWidth,plotHeight)
  /// - Output: Data space (meaningful values)
  ///
  /// **Use Case**: Hit testing, converting pointer position to data values.
  Offset plotToData(double plotX, double plotY) {
    // Calculate relative position in plot range [0, 1]
    final relativeX = plotX / plotWidth;
    final relativeY = invertY
        ? 1.0 - (plotY / plotHeight) // Invert: Y=0 at bottom
        : plotY / plotHeight; // Standard: Y=0 at top

    // Convert to data values
    final dataX = dataXMin + (relativeX * dataXRange);
    final dataY = dataYMin + (relativeY * dataYRange);

    return Offset(dataX, dataY);
  }

  // ============================================================================
  // Bulk Transformations (Optimized for Series)
  // ============================================================================

  /// Converts multiple data points to plot coordinates in one call.
  ///
  /// **Performance**: Optimized for series rendering with many points.
  ///
  /// **Example**:
  /// ```dart
  /// final dataPoints = [
  ///   Offset(1609459200, 150.0),
  ///   Offset(1612137600, 175.0),
  ///   Offset(1614556800, 160.0),
  /// ];
  /// final plotPoints = transform.dataPointsToPlot(dataPoints);
  /// ```
  List<Offset> dataPointsToPlot(List<Offset> dataPoints) {
    return dataPoints.map((p) => dataToPlot(p.dx, p.dy)).toList();
  }

  /// Converts multiple plot points to data coordinates in one call.
  ///
  /// **Use Case**: Batch conversion for analytics or export.
  List<Offset> plotPointsToData(List<Offset> plotPoints) {
    return plotPoints.map((p) => plotToData(p.dx, p.dy)).toList();
  }

  /// Converts a rectangle from data space to plot space.
  ///
  /// **Use Case**: Transform annotation bounds from data coordinates to plot coordinates.
  ///
  /// **Example**:
  /// ```dart
  /// final dataRect = Rect.fromLTWH(startTime, minPrice, timeRange, priceRange);
  /// final plotRect = transform.dataRectToPlot(dataRect);
  /// // Use plotRect for rendering annotation bounds
  /// ```
  Rect dataRectToPlot(Rect dataRect) {
    final topLeft = dataToPlot(dataRect.left, dataRect.top);
    final bottomRight = dataToPlot(dataRect.right, dataRect.bottom);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Converts a rectangle from plot space to data space.
  ///
  /// **Use Case**: Convert selection box from plot coordinates to data coordinates.
  ///
  /// **Example**:
  /// ```dart
  /// final plotRect = Rect.fromLTWH(plotX, plotY, plotWidth, plotHeight);
  /// final dataRect = transform.plotRectToData(plotRect);
  /// // Use dataRect to query visible data range
  /// ```
  Rect plotRectToData(Rect plotRect) {
    final topLeft = plotToData(plotRect.left, plotRect.top);
    final bottomRight = plotToData(plotRect.right, plotRect.bottom);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Checks if a data point is within the visible viewport.
  ///
  /// **Use Case**: Viewport culling before creating elements.
  ///
  /// **Example**:
  /// ```dart
  /// if (transform.isDataPointVisible(timestamp, price)) {
  ///   // Create element for this point
  /// }
  /// ```
  bool isDataPointVisible(double dataX, double dataY) {
    return dataX >= dataXMin && dataX <= dataXMax && dataY >= dataYMin && dataY <= dataYMax;
  }

  /// Checks if a data rect intersects the visible viewport.
  ///
  /// **Use Case**: Culling annotations or large elements.
  bool isDataRectVisible(Rect dataRect) {
    return dataRect.left <= dataXMax && dataRect.right >= dataXMin && dataRect.top <= dataYMax && dataRect.bottom >= dataYMin;
  }

  // ============================================================================
  // Viewport Manipulation
  // ============================================================================

  /// Creates a new transform with viewport zoomed around a plot-space center point.
  ///
  /// **Parameters**:
  /// - `factor`: Zoom factor (>1 = zoom in, <1 = zoom out)
  /// - `plotCenter`: Center point in plot space (where to zoom)
  ///
  /// **Example**:
  /// ```dart
  /// // Zoom in 2x around center of plot
  /// final zoomed = transform.zoom(2.0, Offset(plotWidth/2, plotHeight/2));
  /// ```
  ///
  /// **Behavior**:
  /// - Data range shrinks/grows by factor
  /// - Center point remains at same screen position
  /// - Viewport stays within valid data bounds (if constraints applied)
  ChartTransform zoom(double factor, Offset plotCenter) {
    // Convert plot center to data space
    final dataCenterOffset = plotToData(plotCenter.dx, plotCenter.dy);
    final dataCenterX = dataCenterOffset.dx;
    final dataCenterY = dataCenterOffset.dy;

    // Calculate new data ranges (centered on data center point)
    final newDataXRange = dataXRange / factor;
    final newDataYRange = dataYRange / factor;

    // Calculate proportion of center point in current range
    final centerProportionX = (dataCenterX - dataXMin) / dataXRange;
    final centerProportionY = (dataCenterY - dataYMin) / dataYRange;

    // Calculate new bounds preserving center proportion
    final newDataXMin = dataCenterX - (newDataXRange * centerProportionX);
    final newDataXMax = dataCenterX + (newDataXRange * (1.0 - centerProportionX));
    final newDataYMin = dataCenterY - (newDataYRange * centerProportionY);
    final newDataYMax = dataCenterY + (newDataYRange * (1.0 - centerProportionY));

    return ChartTransform(
      dataXMin: newDataXMin,
      dataXMax: newDataXMax,
      dataYMin: newDataYMin,
      dataYMax: newDataYMax,
      plotWidth: plotWidth,
      plotHeight: plotHeight,
      invertY: invertY,
    );
  }

  /// Creates a new transform with viewport panned by plot-space delta.
  ///
  /// **Parameters**:
  /// - `plotDx`, `plotDy`: Pan delta in plot pixels
  ///
  /// **Example**:
  /// ```dart
  /// // Pan right by 50 pixels
  /// final panned = transform.pan(50.0, 0.0);
  /// ```
  ///
  /// **Behavior**:
  /// - Viewport shifts in data space
  /// - Data range size stays constant
  /// - Positive plotDx pans viewport right (data shifts left)
  /// - Positive plotDy pans viewport down (data shifts up)
  ChartTransform pan(double plotDx, double plotDy) {
    // Convert plot delta to data delta
    final dataDx = plotDx * dataPerPixelX;
    final dataDy = invertY
        ? -plotDy * dataPerPixelY // Invert Y movement
        : plotDy * dataPerPixelY;

    // Shift data bounds
    final newDataXMin = dataXMin + dataDx;
    final newDataXMax = dataXMax + dataDx;
    final newDataYMin = dataYMin + dataDy;
    final newDataYMax = dataYMax + dataDy;

    return ChartTransform(
      dataXMin: newDataXMin,
      dataXMax: newDataXMax,
      dataYMin: newDataYMin,
      dataYMax: newDataYMax,
      plotWidth: plotWidth,
      plotHeight: plotHeight,
      invertY: invertY,
    );
  }

  // ============================================================================
  // Immutable Updates
  // ============================================================================

  /// Creates a copy with optional parameter updates.
  ///
  /// **Example**:
  /// ```dart
  /// // Update only plot dimensions (e.g., after layout change)
  /// final resized = transform.copyWith(
  ///   plotWidth: newWidth,
  ///   plotHeight: newHeight,
  /// );
  /// ```
  ChartTransform copyWith({
    double? dataXMin,
    double? dataXMax,
    double? dataYMin,
    double? dataYMax,
    double? plotWidth,
    double? plotHeight,
    bool? invertY,
  }) {
    return ChartTransform(
      dataXMin: dataXMin ?? this.dataXMin,
      dataXMax: dataXMax ?? this.dataXMax,
      dataYMin: dataYMin ?? this.dataYMin,
      dataYMax: dataYMax ?? this.dataYMax,
      plotWidth: plotWidth ?? this.plotWidth,
      plotHeight: plotHeight ?? this.plotHeight,
      invertY: invertY ?? this.invertY,
    );
  }

  // ============================================================================
  // Equality & Debug
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChartTransform &&
        other.dataXMin == dataXMin &&
        other.dataXMax == dataXMax &&
        other.dataYMin == dataYMin &&
        other.dataYMax == dataYMax &&
        other.plotWidth == plotWidth &&
        other.plotHeight == plotHeight &&
        other.invertY == invertY;
  }

  @override
  int get hashCode {
    return Object.hash(
      dataXMin,
      dataXMax,
      dataYMin,
      dataYMax,
      plotWidth,
      plotHeight,
      invertY,
    );
  }

  @override
  String toString() {
    return 'ChartTransform('
        'dataX: [$dataXMin, $dataXMax], '
        'dataY: [$dataYMin, $dataYMax], '
        'plot: $plotWidth×$plotHeight, '
        'invertY: $invertY)';
  }
}
