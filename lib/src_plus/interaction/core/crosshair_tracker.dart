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

import '../../models/chart_series.dart';
import '../../models/chart_data_point.dart';
import '../../models/interaction_config.dart';

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
      final interpolatedY = _linearInterpolate(
        leftPoint.x,
        leftPoint.y,
        rightPoint.x,
        rightPoint.y,
        targetX,
      );

      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: series.color ?? const Color(0xFF2196F3),
        x: targetX,
        y: interpolatedY,
        dataPointIndex: leftIndex, // Use left point as reference
        isInterpolated: true,
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
}