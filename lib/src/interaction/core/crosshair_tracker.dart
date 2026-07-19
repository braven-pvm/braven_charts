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

import '../../coordinates/chart_transform.dart';
import '../../models/chart_data_point.dart';
import '../../models/bar_chart_style.dart';
import '../../models/chart_series.dart';
import '../../models/interaction_config.dart';
import '../../utils/interpolation_geometry.dart';

/// Interpolation method for tracking values between data points.
enum TrackingInterpolation {
  /// Linear interpolation - straight line between points
  linear,

  /// Stepped interpolation - uses left point's Y value (step chart behavior)
  stepped,

  /// Bezier/smooth interpolation - follows the curve path
  bezier,

  /// Monotone cubic interpolation - preserves curve direction changes.
  monotone,

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
  /// Finds the Scatter point nearest to [plotPosition] in two-dimensional
  /// plot space.
  ///
  /// Unlike line tracking, Scatter samples are not required to be X-ordered
  /// and proximity depends on both coordinates. Ties preserve source order so
  /// repeated coordinates resolve deterministically.
  static CrosshairSeriesValue? calculateNearestScatterValue({
    required ScatterChartSeries series,
    required Offset plotPosition,
    required ChartTransform transform,
  }) {
    var nearestIndex = -1;
    var nearestDistanceSquared = double.infinity;
    for (var index = 0; index < series.points.length; index++) {
      final point = series.points[index];
      if (!point.isValid) continue;
      final candidate = transform.dataToPlot(point.x, point.y);
      if (!candidate.dx.isFinite || !candidate.dy.isFinite) continue;
      final dx = plotPosition.dx - candidate.dx;
      final dy = plotPosition.dy - candidate.dy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared < nearestDistanceSquared) {
        nearestDistanceSquared = distanceSquared;
        nearestIndex = index;
      }
    }
    if (nearestIndex < 0) return null;

    final point = series.points[nearestIndex];
    final magnitude =
        series.sizeEncoding != null &&
            point.magnitude != null &&
            point.magnitude!.isFinite &&
            point.magnitude! >= 0
        ? point.magnitude
        : null;
    final colorValue =
        series.colorEncoding != null &&
            point.colorValue != null &&
            point.colorValue!.isFinite
        ? point.colorValue
        : null;
    final opacityValue =
        series.opacityEncoding != null &&
            point.opacityValue != null &&
            point.opacityValue!.isFinite
        ? point.opacityValue
        : null;
    return CrosshairSeriesValue(
      seriesId: series.id,
      seriesName: series.displayName,
      seriesColor: _trackedPointColor(series, nearestIndex),
      x: point.x,
      y: _trackedPointY(series, nearestIndex),
      dataPointIndex: nearestIndex,
      isInterpolated: false,
      pointLabel: point.label,
      magnitudeValue: magnitude,
      formattedMagnitudeValue: magnitude == null
          ? null
          : series.sizeEncoding!.format(magnitude),
      magnitudeLabel: magnitude == null ? null : series.sizeEncoding!.label,
      colorValue: colorValue,
      formattedColorValue: colorValue == null
          ? null
          : series.colorEncoding!.formatForInteraction(colorValue),
      colorLabel: colorValue == null ? null : series.colorEncoding!.label,
      opacityValue: opacityValue,
      formattedOpacityValue: opacityValue == null
          ? null
          : series.opacityEncoding!.format(opacityValue),
      opacityLabel: opacityValue == null ? null : series.opacityEncoding!.label,
    );
  }

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
  /// [includeScatterXFallback] Whether unordered Scatter series should use a
  /// nearest-X fallback. The renderer disables this after installing its
  /// indexed two-dimensional values.
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
    bool includeScatterXFallback = true,
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
    var hasDeferredScatterData = false;

    for (final series in seriesList) {
      final points = series.points;
      if (points.isEmpty) continue;
      if (series is ScatterChartSeries && !includeScatterXFallback) {
        hasDeferredScatterData = true;
        continue;
      }

      final value = _calculateSeriesValue(
        series: series,
        targetX: dataX,
        interpolate: interpolate,
      );

      if (value != null) {
        seriesValues.add(value);
      }
    }

    if (seriesValues.isEmpty && !hasDeferredScatterData) return null;

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

    // Scatter samples are not required to be X-ordered. Use a stable linear
    // nearest-X lookup until the plot-space two-dimensional tracker supplies
    // indexed candidates directly.
    if (series is ScatterChartSeries) {
      return _calculateScatterSeriesValue(series, targetX);
    }

    // Bars represent discrete observations. Their crosshair values must snap
    // to an actual mark rather than inventing values between categories.
    if (series is BarChartSeries) {
      interpolate = false;
    }

    // Handle edge cases: target is outside data range
    if (targetX == points.first.x) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: _trackedPointColor(series, 0),
        x: points.first.x,
        y: _trackedPointY(series, 0),
        dataPointIndex: 0,
        isInterpolated: false,
      );
    }

    if (targetX == points.last.x) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: _trackedPointColor(series, points.length - 1),
        x: points.last.x,
        y: _trackedPointY(series, points.length - 1),
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
        seriesColor: _trackedPointColor(series, leftIndex),
        x: leftPoint.x,
        y: _trackedPointY(series, leftIndex),
        dataPointIndex: leftIndex,
        isInterpolated: false,
      );
    }

    if ((targetX - rightPoint.x).abs() < 1e-10) {
      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: _trackedPointColor(series, rightIndex),
        x: rightPoint.x,
        y: _trackedPointY(series, rightIndex),
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
          targetX: targetX,
          interpolation: LineInterpolation.bezier,
          tension: _getSeriesTension(series),
        ),
        TrackingInterpolation.monotone => _bezierInterpolate(
          points: points,
          leftIndex: leftIndex,
          targetX: targetX,
          interpolation: LineInterpolation.monotone,
          tension: _getSeriesTension(series),
        ),
        TrackingInterpolation.none => leftPoint.y, // Fallback to left point
      };

      return CrosshairSeriesValue(
        seriesId: series.id,
        seriesName: series.displayName,
        seriesColor: _trackedPointColor(series, leftIndex),
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
          seriesColor: _trackedPointColor(series, leftIndex),
          x: leftPoint.x,
          y: _trackedPointY(series, leftIndex),
          dataPointIndex: leftIndex,
          isInterpolated: false,
        );
      } else {
        return CrosshairSeriesValue(
          seriesId: series.id,
          seriesName: series.displayName,
          seriesColor: _trackedPointColor(series, rightIndex),
          x: rightPoint.x,
          y: _trackedPointY(series, rightIndex),
          dataPointIndex: rightIndex,
          isInterpolated: false,
        );
      }
    }
  }

  static CrosshairSeriesValue? _calculateScatterSeriesValue(
    ScatterChartSeries series,
    double targetX,
  ) {
    var nearestIndex = -1;
    var nearestDistance = double.infinity;
    for (var index = 0; index < series.points.length; index++) {
      final point = series.points[index];
      if (!point.isValid) continue;
      final distance = (targetX - point.x).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }
    if (nearestIndex < 0) return null;

    final point = series.points[nearestIndex];
    return CrosshairSeriesValue(
      seriesId: series.id,
      seriesName: series.displayName,
      seriesColor: _trackedPointColor(series, nearestIndex),
      x: point.x,
      y: _trackedPointY(series, nearestIndex),
      dataPointIndex: nearestIndex,
      isInterpolated: false,
    );
  }

  static double _trackedPointY(ChartSeries series, int pointIndex) {
    if (series case final BarChartSeries barSeries
        when barSeries.layoutMode == BarLayoutMode.waterfall) {
      return barSeries.waterfallDisplayValueFor(pointIndex);
    }
    return series.points[pointIndex].y;
  }

  static Color _trackedPointColor(ChartSeries series, int pointIndex) {
    final markerColor =
        series.points[pointIndex].pointStyle?.scatterMarkerStyle?.fillColor;
    if (markerColor != null) return markerColor;
    final pointColor = series.points[pointIndex].pointStyle?.color;
    if (pointColor != null) return pointColor;
    if (series case final ScatterChartSeries scatter
        when scatter.colorEncoding != null) {
      final values = [
        for (final point in scatter.points)
          if (point.colorValue case final value? when value.isFinite) value,
      ];
      if (values.isNotEmpty) {
        final encoding = scatter.colorEncoding!;
        var minimum = encoding.minimumValue ?? values.first;
        var maximum = encoding.maximumValue ?? values.first;
        if (encoding.minimumValue == null || encoding.maximumValue == null) {
          for (final value in values.skip(1)) {
            if (encoding.minimumValue == null && value < minimum) {
              minimum = value;
            }
            if (encoding.maximumValue == null && value > maximum) {
              maximum = value;
            }
          }
        }
        final encoded = encoding.colorFor(
          scatter.points[pointIndex].colorValue,
          resolvedMinimumValue: minimum,
          resolvedMaximumValue: maximum,
        );
        if (encoded != null) return encoded;
      }
    }
    if (series case final BarChartSeries barSeries
        when barSeries.layoutMode == BarLayoutMode.waterfall) {
      final waterfallColor = barSeries.isWaterfallTotal(pointIndex)
          ? barSeries.waterfallStyle.totalColor
          : barSeries.points[pointIndex].y >= 0
          ? barSeries.waterfallStyle.increaseColor
          : barSeries.waterfallStyle.decreaseColor;
      if (waterfallColor != null) return waterfallColor;
    }
    return series.color ?? const Color(0xFF2196F3);
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
        LineInterpolation.monotone => TrackingInterpolation.monotone,
      };
    } else if (series is AreaChartSeries) {
      return switch (series.interpolation) {
        LineInterpolation.stepped => TrackingInterpolation.stepped,
        LineInterpolation.linear => TrackingInterpolation.linear,
        LineInterpolation.bezier => TrackingInterpolation.bezier,
        LineInterpolation.monotone => TrackingInterpolation.monotone,
      };
    }
    return TrackingInterpolation.none;
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
  /// Uses the same shared cubic geometry as rendering, solving x(t)=targetX
  /// before evaluating y(t) so the tracker follows the rendered curve exactly.
  static double _bezierInterpolate({
    required List<ChartDataPoint> points,
    required int leftIndex,
    required double targetX,
    required LineInterpolation interpolation,
    required double tension,
  }) {
    return InterpolationGeometry.interpolateYForX<ChartDataPoint>(
      points: points,
      startIndex: leftIndex,
      targetX: targetX,
      interpolation: interpolation,
      getX: (point) => point.x,
      getY: (point) => point.y,
      tension: tension,
    );
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
