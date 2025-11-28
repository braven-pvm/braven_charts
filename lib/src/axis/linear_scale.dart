// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'dart:ui';

/// Maps between data space values and pixel space positions.
///
/// **Purpose**: Bidirectional conversion for axis coordinate systems.
///
/// **Example**:
/// ```dart
/// final scale = LinearScale(
///   dataMin: 0,
///   dataMax: 100,
///   pixelMin: 60,   // Left edge (after Y-axis)
///   pixelMax: 760,  // Right edge (before padding)
/// );
///
/// final screenX = scale.dataToPixel(50);  // → 410
/// final dataX = scale.pixelToData(410);   // → 50
/// ```
class LinearScale {
  final double dataMin;
  final double dataMax;
  final double pixelMin;
  final double pixelMax;

  /// Whether to invert the mapping (for Y-axis where high values are at top).
  ///
  /// Canvas Y coordinates increase downward, but chart Y values should increase upward.
  /// Set to true for Y-axis.
  final bool invertY;

  LinearScale({
    required this.dataMin,
    required this.dataMax,
    required this.pixelMin,
    required this.pixelMax,
    this.invertY = false,
  })  : assert(dataMax > dataMin, 'dataMax must be greater than dataMin'),
        assert(pixelMax > pixelMin, 'pixelMax must be greater than pixelMin');

  /// Range of data values.
  double get dataRange => dataMax - dataMin;

  /// Range of pixel positions.
  double get pixelRange => pixelMax - pixelMin;

  /// Scale factor: pixels per data unit.
  double get scale => pixelRange / dataRange;

  /// Converts a data value to a pixel position.
  ///
  /// If [invertY] is true, inverts the mapping so higher data values
  /// map to lower pixel positions (top of screen).
  double dataToPixel(double dataValue) {
    final normalizedValue = (dataValue - dataMin) / dataRange;
    final pixel = pixelMin + normalizedValue * pixelRange;

    if (invertY) {
      // Invert: pixelMin (top) should map to dataMax (high values)
      return pixelMax - (pixel - pixelMin);
    }

    return pixel;
  }

  /// Converts a pixel position to a data value.
  ///
  /// If [invertY] is true, inverts the mapping so lower pixel positions
  /// (top of screen) map to higher data values.
  double pixelToData(double pixelValue) {
    final adjustedPixel = invertY ? pixelMax - (pixelValue - pixelMin) : pixelValue;

    final normalizedPixel = (adjustedPixel - pixelMin) / pixelRange;
    return dataMin + normalizedPixel * dataRange;
  }

  /// Converts a data rectangle to a pixel rectangle.
  Rect dataRectToPixel(Rect dataRect) {
    final left = dataToPixel(dataRect.left);
    final right = dataToPixel(dataRect.right);
    final top = dataToPixel(dataRect.top);
    final bottom = dataToPixel(dataRect.bottom);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Converts a pixel rectangle to a data rectangle.
  Rect pixelRectToData(Rect pixelRect) {
    final left = pixelToData(pixelRect.left);
    final right = pixelToData(pixelRect.right);
    final top = pixelToData(pixelRect.top);
    final bottom = pixelToData(pixelRect.bottom);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Creates a copy with updated parameters.
  LinearScale copyWith({
    double? dataMin,
    double? dataMax,
    double? pixelMin,
    double? pixelMax,
    bool? invertY,
  }) {
    return LinearScale(
      dataMin: dataMin ?? this.dataMin,
      dataMax: dataMax ?? this.dataMax,
      pixelMin: pixelMin ?? this.pixelMin,
      pixelMax: pixelMax ?? this.pixelMax,
      invertY: invertY ?? this.invertY,
    );
  }

  @override
  String toString() => 'LinearScale(data: [$dataMin, $dataMax], '
      'pixels: [$pixelMin, $pixelMax], invertY: $invertY)';
}
