// Copyright (c) 2025 braven_charts. All rights reserved.
// Viewport Constraints - Extracted from ChartRenderBox

import '../../coordinates/chart_transform.dart';

/// Handles viewport constraint calculations for zoom and pan limits.
///
/// This class provides pure functions for clamping zoom levels and pan deltas
/// to enforce sensible viewport bounds. It prevents:
/// - Zooming too far in (losing context) or too far out (data becomes tiny)
/// - Panning beyond data bounds (excessive whitespace)
///
/// **Usage**:
/// ```dart
/// final constraints = ViewportConstraints();
/// final clampedTransform = constraints.clampZoomLevel(
///   transform: tentativeTransform,
///   baseTransform: originalTransform,
/// );
/// final (dx, dy) = constraints.clampPanDelta(
///   requestedPlotDx: plotDx,
///   requestedPlotDy: plotDy,
///   currentTransform: _transform,
///   constraintTransform: _originalTransform,
/// );
/// ```
///
/// **Pure Functions**: All methods are stateless calculations that take
/// transform objects as input and return constrained values. No side effects.
class ViewportConstraints {
  /// Creates a ViewportConstraints with optional custom limits.
  const ViewportConstraints({
    this.minZoomLevel = 0.8,
    this.maxZoomLevel = 10.0,
    this.maxWhitespaceFraction = 0.1,
  });

  /// Minimum allowed zoom level (0.8 = can zoom out 20% beyond fit-all).
  final double minZoomLevel;

  /// Maximum allowed zoom level (10.0 = can zoom in 10x).
  final double maxZoomLevel;

  /// Maximum whitespace allowed beyond data bounds (0.1 = 10% of viewport).
  final double maxWhitespaceFraction;

  /// Clamps zoom level to configured min/max bounds.
  ///
  /// **Algorithm**:
  /// 1. Calculate current zoom level: original_range / current_range
  /// 2. If zoom exceeds limits, scale ranges back to limit
  /// 3. Preserve center point of current viewport
  ///
  /// Returns the transform unchanged if within bounds, or a new clamped
  /// transform if zoom exceeded limits.
  ChartTransform clampZoomLevel({
    required ChartTransform transform,
    required ChartTransform baseTransform,
  }) {
    final originalXRange = baseTransform.dataXMax - baseTransform.dataXMin;
    final originalYRange = baseTransform.dataYMax - baseTransform.dataYMin;

    final currentXRange = transform.dataXMax - transform.dataXMin;
    final currentYRange = transform.dataYMax - transform.dataYMin;

    // Calculate current zoom levels
    final currentZoomX = originalXRange / currentXRange;
    final currentZoomY = originalYRange / currentYRange;

    // Check if clamping needed
    final bool needsClampX =
        currentZoomX < minZoomLevel || currentZoomX > maxZoomLevel;
    final bool needsClampY =
        currentZoomY < minZoomLevel || currentZoomY > maxZoomLevel;

    if (!needsClampX && !needsClampY) {
      return transform; // No clamping needed
    }

    // Clamp zoom levels
    final clampedZoomX = currentZoomX.clamp(minZoomLevel, maxZoomLevel);
    final clampedZoomY = currentZoomY.clamp(minZoomLevel, maxZoomLevel);

    // Calculate new ranges from clamped zoom
    final newXRange = originalXRange / clampedZoomX;
    final newYRange = originalYRange / clampedZoomY;

    // Preserve center of current viewport
    final centerX = (transform.dataXMin + transform.dataXMax) / 2;
    final centerY = (transform.dataYMin + transform.dataYMax) / 2;

    // Calculate new bounds centered on viewport center
    final newDataXMin = centerX - newXRange / 2;
    final newDataXMax = centerX + newXRange / 2;
    final newDataYMin = centerY - newYRange / 2;
    final newDataYMax = centerY + newYRange / 2;

    return ChartTransform(
      dataXMin: newDataXMin,
      dataXMax: newDataXMax,
      dataYMin: newDataYMin,
      dataYMax: newDataYMax,
      plotWidth: transform.plotWidth,
      plotHeight: transform.plotHeight,
      invertY: transform.invertY,
    );
  }

  /// Clamps pan delta to enforce viewport bounds (limit whitespace).
  ///
  /// **Correct Viewport Position Constraint Algorithm**:
  ///
  /// **Core Concept**: Track WHERE THE VIEWPORT IS in data space, not where
  /// original boundaries appear in viewport. This makes constraints zoom-independent.
  ///
  /// **Algorithm**:
  /// 1. Convert requested plot delta to data delta
  /// 2. Calculate tentative new viewport position (dataXMin, dataYMin)
  /// 3. Calculate max allowed whitespace in data space (zoom-aware)
  /// 4. Calculate allowed bounds for viewport position
  /// 5. Clamp tentative position to allowed bounds
  /// 6. Calculate actual movement and convert back to plot delta
  ///
  /// **Constraint**: Viewport can show up to 10% whitespace beyond original data.
  /// - Example at 1x zoom (800px plot, 1000 data range):
  ///   maxWhitespace = 800 * 0.1 * (1000/800) = 100 data units
  /// - Example at 2x zoom (800px plot, 500 data range):
  ///   maxWhitespace = 800 * 0.1 * (500/800) = 50 data units
  ///
  /// **Result**: Consistent 10% whitespace at ALL zoom levels. Zoom-independent!
  ({double dx, double dy}) clampPanDelta({
    required double requestedPlotDx,
    required double requestedPlotDy,
    required ChartTransform currentTransform,
    required ChartTransform constraintTransform,
  }) {
    // 1. Convert requested plot delta to data space
    // CRITICAL: Match the inversion logic in ChartTransform.pan()!
    final dataPerPixelX = currentTransform.dataPerPixelX;
    final dataPerPixelY = currentTransform.dataPerPixelY;
    final requestedDataDx = requestedPlotDx * dataPerPixelX;
    final requestedDataDy = currentTransform.invertY
        ? -requestedPlotDy *
              dataPerPixelY // Invert Y movement (match pan() logic)
        : requestedPlotDy * dataPerPixelY;

    // 2. Calculate tentative new viewport position in data space
    final tentativeDataXMin = currentTransform.dataXMin + requestedDataDx;
    final tentativeDataYMin = currentTransform.dataYMin + requestedDataDy;

    // 3. Calculate maximum allowed whitespace in data space (zoom-aware!)
    // At 1x zoom: maxWhitespace = plotWidth * 0.1 * (originalRange / plotWidth) = originalRange * 0.1
    // At 2x zoom: maxWhitespace = plotWidth * 0.1 * (originalRange/2 / plotWidth) = originalRange * 0.05
    // This ensures 10% whitespace in VIEWPORT, which scales correctly with zoom
    final maxWhitespaceDataX =
        currentTransform.plotWidth * maxWhitespaceFraction * dataPerPixelX;
    final maxWhitespaceDataY =
        currentTransform.plotHeight * maxWhitespaceFraction * dataPerPixelY;

    // 4. Calculate allowed bounds for viewport position using constraint transform
    // Viewport left edge (dataXMin) can range from:
    //   - Minimum: constraintDataXMin - maxWhitespace (show whitespace on left)
    //   - Maximum: constraintDataXMax - currentViewportWidth + maxWhitespace (show whitespace on right)
    final minAllowedDataXMin =
        constraintTransform.dataXMin - maxWhitespaceDataX;
    final maxAllowedDataXMin =
        constraintTransform.dataXMax -
        currentTransform.dataXRange +
        maxWhitespaceDataX;

    final minAllowedDataYMin =
        constraintTransform.dataYMin - maxWhitespaceDataY;
    final maxAllowedDataYMin =
        constraintTransform.dataYMax -
        currentTransform.dataYRange +
        maxWhitespaceDataY;

    // 5. Clamp tentative viewport position to allowed bounds
    // Defensive: If min > max (viewport larger than constraint range), allow full movement
    final clampedDataXMin = minAllowedDataXMin <= maxAllowedDataXMin
        ? tentativeDataXMin.clamp(minAllowedDataXMin, maxAllowedDataXMin)
        : tentativeDataXMin;
    final clampedDataYMin = minAllowedDataYMin <= maxAllowedDataYMin
        ? tentativeDataYMin.clamp(minAllowedDataYMin, maxAllowedDataYMin)
        : tentativeDataYMin;

    // 6. Calculate actual movement allowed and convert back to plot space
    // CRITICAL: Reverse the inversion applied in step 1!
    final actualDataDx = clampedDataXMin - currentTransform.dataXMin;
    final actualDataDy = clampedDataYMin - currentTransform.dataYMin;

    final actualPlotDx = actualDataDx / dataPerPixelX;
    final actualPlotDy = currentTransform.invertY
        ? -actualDataDy /
              dataPerPixelY // Reverse Y inversion
        : actualDataDy / dataPerPixelY;

    return (dx: actualPlotDx, dy: actualPlotDy);
  }
}
