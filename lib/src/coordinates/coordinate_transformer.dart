/// Temporary stub for CoordinateTransformer until Layer 3 (Coordinate System) is fully implemented.
///
/// This provides the minimal interface needed for the Interaction System (Layer 7)
/// to transform coordinates between screen and data space.
library;

import 'dart:ui' show Rect, Offset;

/// Coordinate transformer for converting between screen and data coordinates.
///
/// This is a simplified version that will be replaced by the full
/// UniversalCoordinateTransformer implementation from Layer 3.
class CoordinateTransformer {
  /// Creates a coordinate transformer with the specified bounds.
  const CoordinateTransformer({
    required this.chartBounds,
    required this.dataBounds,
  });

  /// The bounds of the chart in screen coordinates.
  final Rect chartBounds;

  /// The bounds of the data in data coordinates.
  final Rect dataBounds;

  /// Converts a screen coordinate to a data coordinate.
  ///
  /// Maps from screen pixel space (chartBounds) to data value space (dataBounds).
  Offset screenToData(Offset screenPosition) {
    // Calculate normalized position within chart bounds (0.0 to 1.0)
    final normalizedX = (screenPosition.dx - chartBounds.left) / chartBounds.width;
    final normalizedY = (screenPosition.dy - chartBounds.top) / chartBounds.height;

    // Map to data bounds
    // Note: Y axis is inverted (screen Y increases downward, data Y increases upward)
    final dataX = dataBounds.left + (normalizedX * dataBounds.width);
    final dataY = dataBounds.top + ((1.0 - normalizedY) * dataBounds.height);

    return Offset(dataX, dataY);
  }

  /// Converts a data coordinate to a screen coordinate.
  ///
  /// Maps from data value space (dataBounds) to screen pixel space (chartBounds).
  Offset dataToScreen(Offset dataPosition) {
    // Calculate normalized position within data bounds (0.0 to 1.0)
    final normalizedX = (dataPosition.dx - dataBounds.left) / dataBounds.width;
    final normalizedY = (dataPosition.dy - dataBounds.top) / dataBounds.height;

    // Map to chart bounds
    // Note: Y axis is inverted (data Y increases upward, screen Y increases downward)
    final screenX = chartBounds.left + (normalizedX * chartBounds.width);
    final screenY = chartBounds.top + ((1.0 - normalizedY) * chartBounds.height);

    return Offset(screenX, screenY);
  }
}
