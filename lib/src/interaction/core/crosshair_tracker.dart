// Copyright 2025 Braven Charts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui';

import '../../models/chart_data_point.dart';
import '../../models/chart_series.dart';
import '../../models/interaction_config.dart';

/// Interpolation method for tracking values between data points.
enum TrackingInterpolation {
  /// Linear interpolation - straight line between points
  linear,

  /// Stepped interpolation - uses left point's Y value (step chart behavior)
  stepped,

  /// Bezier/smooth interpolation - follows the curve path
  bezier,

  /// No interpolation - snaps to nearest actual data point
  none,
}

/// Utility class for crosshair tracking mode calculations.
///
/// This class provides high-performance utilities for calculating
/// series values at any X position, using binary search and linear
/// interpolation. Designed for 60fps performance with 1000+ data points.
///
/// Performance characteristics:
/// - Binary search: O(log n) per series
/// - Total calculation: O(S * log N) where S = series count, N = points per series
/// - Memory: O(S) for result storage
abstract final class CrosshairTracker {
  /// Calculates the tracking state for a given screen X position.
  ///
  /// This is the main entry point for tracking mode. It converts the
  /// screen position to data coordinates and calculates the Y value
  /// for each series at that X position.
  ///
  /// [screenX] The X position in screen coordinates (pixels)
  /// [chartBounds] The bounds of the chart area in screen coordinates
  /// [xMin] The minimum X value in data coordinates
  /// [xMax] The maximum X value in data coordinates
  /// [seriesList] List of all series to evaluate
  /// [interpolate] Whether to interpolate between points (default: true)
  ///
  /// Returns null if the position is outside the chart bounds or if
  /// there are no series with data.
  static CrosshairTrackingState? calculateTrackingState({
    required double screenX,
    required Rect chartBounds,
    required double xMin,
    required double xMax,
    required List<ChartSeries> seriesList,
    bool interpolate = true,
  }) {
    // Early exit if outside chart bounds
    if (screenX < chartBounds.left || screenX > chartBounds.right) {
      return null;
    }

    // Convert screen X to data X
    final chartWidth = chartBounds.width;
    if (chartWidth <= 0) return null;

    final normalizedX = (screenX - chartBounds.left) / chartWidth;
    final dataX = xMin + normalizedX * (xMax - xMin);

    // Calculate value for each series
    final seriesValues = <CrosshairSeriesValue>[];

    for (final series in seriesList) {
      final points = series.points;
      if (points.isEmpty) continue;

      final value = _calculateSeriesValue(
        series: series,
        targetX: dataX,
        interpolate: interpolate,
      );

      if (value != null) {
        seriesValues.add(value);
      }
    }

    if (seriesValues.isEmpty) return null;

    return CrosshairTrackingState(
      dataX: dataX,
      screenX: screenX,
      seriesValues: seriesValues,
    );
  }

  /// Calculates the Y value for a single series at the target X position.
  ///
  /// Uses binary search to find the surrounding points, then optionally
  /// interpolates between them.
  static CrosshairSeriesValue? _calculateSeriesValue({
    required ChartSeries series,
    required double targetX,
    required bool interpolate,
  }) {
    final points = series.points;
    if (points.isEmpty) return null;

    // Handle edge cases: target is outside data range
    if (targetX <= points.first.x) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: series.color ?? const Color(0xFF2196F3),
        x: points.first.x,
        y: points.first.y,
        dataPointIndex: 0,
        isInterpolated: false,
      );
    }

    if (targetX >= points.last.x) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: series.color ?? const Color(0xFF2196F3),
        x: points.last.x,
        y: points.last.y,
        dataPointIndex: points.length - 1,
        isInterpolated: false,
      );
    }

    // Binary search to find the insertion point
    final insertionPoint = _findInsertionPoint(points, targetX);

    // Get the surrounding points
    final rightIndex = insertionPoint;
    final leftIndex = insertionPoint - 1;

    if (leftIndex < 0 || rightIndex >= points.length) {
      return null;
    }

    final leftPoint = points[leftIndex];
    final rightPoint = points[rightIndex];

    // Check if we are exactly on a point
    if ((targetX - leftPoint.x).abs() < 1e-10) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: series.color ?? const Color(0xFF2196F3),
        x: leftPoint.x,
        y: leftPoint.y,
        dataPointIndex: leftIndex,
        isInterpolated: false,
      );
    }

    if ((targetX - rightPoint.x).abs() < 1e-10) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: series.color ?? const Color(0xFF2196F3),
        x: rightPoint.x,
        y: rightPoint.y,
        dataPointIndex: rightIndex,
        isInterpolated: false,
      );
    }

    // Interpolate between points
    if (interpolate) {
      // Determine interpolation type based on series type
      final interpolationType = _getSeriesInterpolationType(series);

      final interpolatedY = switch (interpolationType) {
        TrackingInterpolation.stepped =>
          leftPoint.y, // Step: use left point's Y
        TrackingInterpolation.linear => _linearInterpolate(
            leftPoint.x,
            leftPoint.y,
            rightPoint.x,
            rightPoint.y,
            targetX,
          ),
        TrackingInterpolation.bezier => _bezierInterpolate(
            points: points,
            leftIndex: leftIndex,
            rightIndex: rightIndex,
            targetX: targetX,
            tension: _getSeriesTension(series),
          ),
        TrackingInterpolation.none => leftPoint.y, // Fallback to left point
      };

      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: series.color ?? const Color(0xFF2196F3),
        x: targetX,
        y: interpolatedY,
        dataPointIndex: leftIndex, // Use left point as reference
        isInterpolated: interpolationType != TrackingInterpolation.stepped,
      );
    } else {
      // Return the nearest point
      final distToLeft = (targetX - leftPoint.x).abs();
      final distToRight = (targetX - rightPoint.x).abs();

      if (distToLeft <= distToRight) {
        return CrosshairSeriesValue(
          seriesId: series.id,
          seriesName: series.displayName,
          seriesColor: series.color ?? const Color(0xFF2196F3),
          x: leftPoint.x,
          y: leftPoint.y,
          dataPointIndex: leftIndex,
          isInterpolated: false,
        );
      } else {
        return CrosshairSeriesValue(
          seriesId: series.id,
          seriesName: series.displayName,
          seriesColor: series.color ?? const Color(0xFF2196F3),
          x: rightPoint.x,
          y: rightPoint.y,
          dataPointIndex: rightIndex,
          isInterpolated: false,
        );
      }
    }
  }

  /// Binary search to find the insertion point for targetX.
  ///
  /// Returns the index of the first element greater than or equal to targetX.
  /// If all elements are less than targetX, returns points.length.
  ///
  /// Performance: O(log n)
  static int _findInsertionPoint(List<ChartDataPoint> points, double targetX) {
    int low = 0;
    int high = points.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (points[mid].x < targetX) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  /// Determines the tracking interpolation type based on series type.
  ///
  /// For LineChartSeries and AreaChartSeries, uses their interpolation setting.
  /// For other series types, defaults to linear interpolation.
  static TrackingInterpolation _getSeriesInterpolationType(ChartSeries series) {
    if (series is LineChartSeries) {
      return switch (series.interpolation) {
        LineInterpolation.stepped => TrackingInterpolation.stepped,
        LineInterpolation.linear => TrackingInterpolation.linear,
        LineInterpolation.bezier => TrackingInterpolation.bezier,
        LineInterpolation.monotone =>
          TrackingInterpolation.bezier, // Monotone uses same curve tracking
      };
    } else if (series is AreaChartSeries) {
      return switch (series.interpolation) {
        LineInterpolation.stepped => TrackingInterpolation.stepped,
        LineInterpolation.linear => TrackingInterpolation.linear,
        LineInterpolation.bezier => TrackingInterpolation.bezier,
        LineInterpolation.monotone =>
          TrackingInterpolation.bezier, // Monotone uses same curve tracking
      };
    }
    // Default to linear for other series types (e.g., BarChartSeries)
    return TrackingInterpolation.linear;
  }

  /// Gets the tension value for a series (used for bezier curves).
  static double _getSeriesTension(ChartSeries series) {
    if (series is LineChartSeries) {
      return series.tension;
    } else if (series is AreaChartSeries) {
      return series.tension;
    }
    return 0.5; // Default tension
  }

  /// Bezier/Catmull-Rom interpolation between points.
  ///
  /// Uses the EXACT same Catmull-Rom spline algorithm as the renderer (_addBezierToPath)
  /// to calculate the Y value at targetX along the smooth curve.
  ///
  /// The renderer draws segments from point[i-1] to point[i] using:
  /// - p0 = point[i > 1 ? i - 2 : 0]  (point before the segment start)
  /// - p1 = point[i - 1]              (segment start)
  /// - p2 = point[i]                  (segment end)
  /// - p3 = point[i + 1] or last      (point after segment end)
  ///
  /// For tracking, leftIndex corresponds to (i-1) and rightIndex to (i).
  static double _bezierInterpolate({
    required List<ChartDataPoint> points,
    required int leftIndex,
    required int rightIndex,
    required double targetX,
    required double tension,
  }) {
    final length = points.length;

    // Match the EXACT same point selection as renderer's _addBezierToPath
    // In renderer: i is the index we're drawing TO, so i-1 is leftIndex, i is rightIndex
    // p0 = points[i > 1 ? i - 2 : 0] => points[rightIndex > 1 ? rightIndex - 2 : 0]
    //    which equals points[leftIndex > 0 ? leftIndex - 1 : 0]
    final p0 = points[leftIndex > 0 ? leftIndex - 1 : 0];
    final p1 = points[leftIndex];
    final p2 = points[rightIndex];
    final p3 = points[rightIndex < length - 1 ? rightIndex + 1 : length - 1];

    // Calculate t parameter (0 to 1) based on X position within this segment
    final xRange = p2.x - p1.x;
    if (xRange.abs() < 1e-10) return p1.y;

    final t = (targetX - p1.x) / xRange;

    // Catmull-Rom to cubic bezier control points (EXACT same formula as renderer)
    // cp1 = p1 + (p2 - p0) * alpha / 6
    // cp2 = p2 - (p3 - p1) * alpha / 6
    final alpha = tension;
    final cp1y = p1.y + (p2.y - p0.y) * alpha / 6;
    final cp2y = p2.y - (p3.y - p1.y) * alpha / 6;

    // Evaluate cubic bezier at t
    // B(t) = (1-t)³·P1 + 3(1-t)²t·CP1 + 3(1-t)t²·CP2 + t³·P2
    final oneMinusT = 1.0 - t;
    final oneMinusT2 = oneMinusT * oneMinusT;
    final oneMinusT3 = oneMinusT2 * oneMinusT;
    final t2 = t * t;
    final t3 = t2 * t;

    return oneMinusT3 * p1.y +
        3 * oneMinusT2 * t * cp1y +
        3 * oneMinusT * t2 * cp2y +
        t3 * p2.y;
  }

  /// Linear interpolation between two points.
  ///
  /// Calculates the Y value at targetX given two reference points.
  /// Handles the edge case where x1 == x2 by returning y1.
  static double _linearInterpolate(
    double x1,
    double y1,
    double x2,
    double y2,
    double targetX,
  ) {
    // Handle vertical line case
    if ((x2 - x1).abs() < 1e-10) {
      return y1;
    }

    final t = (targetX - x1) / (x2 - x1);
    return y1 + (y2 - y1) * t;
  }

  /// Calculates the total number of data points across all series.
  ///
  /// Used to determine if tracking mode should be auto-enabled.
  static int getTotalPointCount(List<ChartSeries> seriesList) {
    int total = 0;
    for (final series in seriesList) {
      total += series.points.length;
    }
    return total;
  }

  /// Converts a data X coordinate to screen X coordinate.
  static double dataToScreenX({
    required double dataX,
    required Rect chartBounds,
    required double xMin,
    required double xMax,
  }) {
    final xRange = xMax - xMin;
    if (xRange <= 0) return chartBounds.left;

    final normalizedX = (dataX - xMin) / xRange;
    return chartBounds.left + normalizedX * chartBounds.width;
  }

  /// Converts a data Y coordinate to screen Y coordinate.
  static double dataToScreenY({
    required double dataY,
    required Rect chartBounds,
    required double yMin,
    required double yMax,
  }) {
    final yRange = yMax - yMin;
    if (yRange <= 0) return chartBounds.bottom;

    final normalizedY = (dataY - yMin) / yRange;
    // Y is inverted in screen coordinates
    return chartBounds.bottom - normalizedY * chartBounds.height;
  }

  /// Converts a data Y coordinate to screen Y coordinate for a SPECIFIC axis.
  ///
  /// This method is used for multi-axis charts where each series may have
  /// different Y-axis bounds. Unlike [dataToScreenY] which uses global bounds,
  /// this method uses per-axis bounds for accurate positioning.
  ///
  /// [dataY] The Y value in data coordinates
  /// [chartBounds] The bounds of the chart area in screen coordinates
  /// [axisMin] The minimum Y value for this specific axis
  /// [axisMax] The maximum Y value for this specific axis
  ///
  /// Returns the screen Y coordinate for the given data Y value.
  /// Screen Y is inverted (higher values are lower on screen).
  static double dataToScreenYForAxis({
    required double dataY,
    required Rect chartBounds,
    required double axisMin,
    required double axisMax,
  }) {
    final yRange = axisMax - axisMin;
    if (yRange <= 0) return chartBounds.bottom;

    final normalizedY = (dataY - axisMin) / yRange;
    // Y is inverted in screen coordinates
    return chartBounds.bottom - normalizedY * chartBounds.height;
  }
}
