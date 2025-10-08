/// Tooltip provider implementation for chart interactions.
///
/// Provides context-aware tooltips that display data point details on hover or tap.
/// Implements smart positioning to avoid clipping and supports custom content builders.
library;

import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/material.dart';

import '../foundation/data_models/chart_data_point.dart';
import 'models/tooltip_config.dart';

/// Abstract interface for tooltip rendering.
///
/// Implementations must display tooltips with <5ms render time and maintain
/// 60 FPS during fade animations.
abstract class ITooltipProvider {
  /// Shows tooltip for a data point.
  ///
  /// Parameters:
  /// - [context]: BuildContext for widget tree
  /// - [point]: Data point to show tooltip for
  /// - [seriesId]: ID of the series containing the point
  /// - [screenPosition]: Position in screen coordinates
  /// - [config]: Tooltip configuration (style, builder, positioning)
  ///
  /// Returns: Tooltip widget to be rendered
  ///
  /// Performance: Must complete in <5ms
  Widget showTooltip(
    BuildContext context,
    ChartDataPoint point,
    String seriesId,
    Offset screenPosition,
    TooltipConfig config,
  );

  /// Hides the currently visible tooltip.
  ///
  /// Applies fade-out animation if configured.
  void hideTooltip();

  /// Calculates optimal tooltip position to avoid clipping.
  ///
  /// Smart positioning algorithm:
  /// 1. Try preferred position (top/bottom/left/right)
  /// 2. If clipped, try opposite side
  /// 3. If still clipped, try other two sides
  /// 4. If all clipped, position at edge with arrow pointing to point
  ///
  /// Parameters:
  /// - [tooltipSize]: Size of tooltip widget
  /// - [pointPosition]: Position of data point in screen coordinates
  /// - [chartBounds]: Visible bounds of chart area
  /// - [preferredPosition]: Developer's preferred position
  /// - [offset]: Distance from point in pixels
  ///
  /// Returns: Optimal position for tooltip
  Offset calculatePosition(
    Size tooltipSize,
    Offset pointPosition,
    Rect chartBounds,
    TooltipPosition preferredPosition,
    double offset,
  );

  /// Renders default tooltip content (series name, X/Y values).
  ///
  /// Used when no custom builder is provided.
  ///
  /// Parameters:
  /// - [context]: BuildContext
  /// - [point]: Data point
  /// - [seriesId]: Series ID
  /// - [style]: Tooltip style configuration
  ///
  /// Returns: Default tooltip widget
  Widget buildDefaultTooltip(
    BuildContext context,
    ChartDataPoint point,
    String seriesId,
    TooltipStyle style,
  );

  /// Renders tooltip for multiple series at same X coordinate.
  ///
  /// Shows all series values stacked vertically in tooltip.
  ///
  /// Parameters:
  /// - [context]: BuildContext
  /// - [points]: List of data points (one per series)
  /// - [seriesIds]: List of series IDs corresponding to points
  /// - [style]: Tooltip style configuration
  ///
  /// Returns: Multi-series tooltip widget
  Widget buildMultiSeriesTooltip(
    BuildContext context,
    List<ChartDataPoint> points,
    List<String> seriesIds,
    TooltipStyle style,
  );

  /// Determines if tooltip should update.
  ///
  /// Used to avoid unnecessary rebuilds.
  ///
  /// Parameters:
  /// - [oldPoint]: Previously displayed data point
  /// - [newPoint]: New data point to display
  ///
  /// Returns: true if tooltip content changed
  bool shouldUpdate(
    ChartDataPoint? oldPoint,
    ChartDataPoint? newPoint,
  );
}

/// Tooltip provider implementation.
///
/// Renders context-aware tooltips with smart positioning and customizable content.
///
/// Example:
/// ```dart
/// final provider = TooltipProvider();
/// final tooltip = provider.showTooltip(
///   context,
///   dataPoint,
///   'series1',
///   Offset(400, 300),
///   config,
/// );
/// ```
class TooltipProvider implements ITooltipProvider {
  /// Creates a tooltip provider.
  TooltipProvider();

  /// Current tooltip visibility state.
  bool _isVisible = false;

  /// Whether the tooltip is currently visible.
  bool get isVisible => _isVisible;

  @override
  Widget showTooltip(
    BuildContext context,
    ChartDataPoint point,
    String seriesId,
    Offset screenPosition,
    TooltipConfig config,
  ) {
    _isVisible = true;

    // Use custom builder if provided
    if (config.customBuilder != null) {
      final dataMap = {
        'x': point.x,
        'y': point.y,
        'label': point.label,
        'seriesId': seriesId,
      };
      return config.customBuilder!(context, dataMap);
    }

    // Otherwise use default tooltip
    return buildDefaultTooltip(context, point, seriesId, config.style);
  }

  @override
  void hideTooltip() {
    _isVisible = false;
  }

  @override
  Offset calculatePosition(
    Size tooltipSize,
    Offset pointPosition,
    Rect chartBounds,
    TooltipPosition preferredPosition,
    double offset,
  ) {
    // Helper to check if position is within bounds
    bool isWithinBounds(Offset pos) {
      return pos.dx >= chartBounds.left &&
          pos.dy >= chartBounds.top &&
          pos.dx + tooltipSize.width <= chartBounds.right &&
          pos.dy + tooltipSize.height <= chartBounds.bottom;
    }

    // Helper to calculate position for a given side
    Offset positionFor(TooltipPosition position) {
      switch (position) {
        case TooltipPosition.top:
          return Offset(
            pointPosition.dx - tooltipSize.width / 2,
            pointPosition.dy - tooltipSize.height - offset,
          );
        case TooltipPosition.bottom:
          return Offset(
            pointPosition.dx - tooltipSize.width / 2,
            pointPosition.dy + offset,
          );
        case TooltipPosition.left:
          return Offset(
            pointPosition.dx - tooltipSize.width - offset,
            pointPosition.dy - tooltipSize.height / 2,
          );
        case TooltipPosition.right:
          return Offset(
            pointPosition.dx + offset,
            pointPosition.dy - tooltipSize.height / 2,
          );
        case TooltipPosition.auto:
          // Default to top if auto
          return positionFor(TooltipPosition.top);
      }
    }

    // If auto positioning, try all positions in order
    if (preferredPosition == TooltipPosition.auto) {
      final positions = [
        TooltipPosition.top,
        TooltipPosition.bottom,
        TooltipPosition.right,
        TooltipPosition.left,
      ];

      for (final position in positions) {
        final pos = positionFor(position);
        if (isWithinBounds(pos)) {
          return pos;
        }
      }

      // If none fit, position at edge with clamping
      return _clampToChart(pointPosition, tooltipSize, chartBounds, offset);
    }

    // Try preferred position first
    final preferredPos = positionFor(preferredPosition);
    if (isWithinBounds(preferredPos)) {
      return preferredPos;
    }

    // Try opposite side
    final opposite = _oppositePosition(preferredPosition);
    final oppositePos = positionFor(opposite);
    if (isWithinBounds(oppositePos)) {
      return oppositePos;
    }

    // Try other two sides
    final otherPositions = _otherPositions(preferredPosition);
    for (final position in otherPositions) {
      final pos = positionFor(position);
      if (isWithinBounds(pos)) {
        return pos;
      }
    }

    // If nothing fits, clamp to edges
    return _clampToChart(pointPosition, tooltipSize, chartBounds, offset);
  }

  @override
  Widget buildDefaultTooltip(
    BuildContext context,
    ChartDataPoint point,
    String seriesId,
    TooltipStyle style,
  ) {
    return Container(
      padding: EdgeInsets.all(style.padding),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
        borderRadius: BorderRadius.circular(style.borderRadius),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor,
            blurRadius: style.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Series name
          Text(
            seriesId,
            style: TextStyle(
              color: style.textColor,
              fontSize: style.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // X value
          Text(
            'X: ${point.x.toStringAsFixed(2)}',
            style: TextStyle(
              color: style.textColor,
              fontSize: style.fontSize,
            ),
          ),
          // Y value
          Text(
            'Y: ${point.y.toStringAsFixed(2)}',
            style: TextStyle(
              color: style.textColor,
              fontSize: style.fontSize,
            ),
          ),
          // Label if available
          if (point.label != null && point.label!.isNotEmpty)
            Text(
              point.label!,
              style: TextStyle(
                color: style.textColor,
                fontSize: style.fontSize - 1,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget buildMultiSeriesTooltip(
    BuildContext context,
    List<ChartDataPoint> points,
    List<String> seriesIds,
    TooltipStyle style,
  ) {
    return Container(
      padding: EdgeInsets.all(style.padding),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
        borderRadius: BorderRadius.circular(style.borderRadius),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor,
            blurRadius: style.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // X coordinate (common for all points)
          if (points.isNotEmpty)
            Text(
              'X: ${points.first.x.toStringAsFixed(2)}',
              style: TextStyle(
                color: style.textColor,
                fontSize: style.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          // Each series
          for (var i = 0; i < points.length; i++) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Series name
                Text(
                  '${seriesIds[i]}: ',
                  style: TextStyle(
                    color: style.textColor,
                    fontSize: style.fontSize,
                  ),
                ),
                // Y value
                Text(
                  points[i].y.toStringAsFixed(2),
                  style: TextStyle(
                    color: style.textColor,
                    fontSize: style.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (i < points.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldUpdate(
    ChartDataPoint? oldPoint,
    ChartDataPoint? newPoint,
  ) {
    // Update if visibility changed
    if (oldPoint == null && newPoint != null) return true;
    if (oldPoint != null && newPoint == null) return true;

    // Update if point changed
    if (oldPoint != null && newPoint != null) {
      return oldPoint.x != newPoint.x ||
          oldPoint.y != newPoint.y ||
          oldPoint.label != newPoint.label;
    }

    return false;
  }

  // Helper: Get opposite position
  TooltipPosition _oppositePosition(TooltipPosition position) {
    switch (position) {
      case TooltipPosition.top:
        return TooltipPosition.bottom;
      case TooltipPosition.bottom:
        return TooltipPosition.top;
      case TooltipPosition.left:
        return TooltipPosition.right;
      case TooltipPosition.right:
        return TooltipPosition.left;
      case TooltipPosition.auto:
        return TooltipPosition.auto;
    }
  }

  // Helper: Get other two positions (perpendicular)
  List<TooltipPosition> _otherPositions(TooltipPosition position) {
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        return [TooltipPosition.left, TooltipPosition.right];
      case TooltipPosition.left:
      case TooltipPosition.right:
        return [TooltipPosition.top, TooltipPosition.bottom];
      case TooltipPosition.auto:
        return [];
    }
  }

  // Helper: Clamp tooltip to chart bounds
  Offset _clampToChart(
    Offset pointPosition,
    Size tooltipSize,
    Rect chartBounds,
    double offset,
  ) {
    // Start with top position
    var x = pointPosition.dx - tooltipSize.width / 2;
    var y = pointPosition.dy - tooltipSize.height - offset;

    // Clamp X
    if (x < chartBounds.left) {
      x = chartBounds.left;
    } else if (x + tooltipSize.width > chartBounds.right) {
      x = chartBounds.right - tooltipSize.width;
    }

    // Clamp Y
    if (y < chartBounds.top) {
      y = chartBounds.top;
    } else if (y + tooltipSize.height > chartBounds.bottom) {
      y = chartBounds.bottom - tooltipSize.height;
    }

    return Offset(x, y);
  }
}
