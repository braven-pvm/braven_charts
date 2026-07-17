// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../models/bar_chart_style.dart';
import '../models/bar_group_info.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Canonical plot-space geometry for one rendered bar.
///
/// Painting, hit testing, focus, labels, and bounds all consume this object so
/// those systems cannot silently calculate different bar rectangles.
class BarGeometry {
  const BarGeometry({
    required this.pointIndex,
    required this.point,
    required this.rect,
    required this.rrect,
    required this.orientation,
    required this.baselinePosition,
    required this.valueEndPosition,
    required this.isNegative,
    required this.startValue,
    required this.endValue,
    this.percentage,
    this.trackRect,
    this.trackRRect,
  });

  final int pointIndex;
  final ChartDataPoint point;
  final Rect rect;
  final RRect rrect;
  final BarOrientation orientation;

  /// Screen coordinate along the value axis at the segment start.
  final double baselinePosition;

  /// Screen coordinate along the value axis at the segment end.
  final double valueEndPosition;

  double get baselineY => orientation == BarOrientation.vertical
      ? baselinePosition
      : rect.center.dy;

  double get valueEndY => orientation == BarOrientation.vertical
      ? valueEndPosition
      : rect.center.dy;

  double get baselineX => orientation == BarOrientation.horizontal
      ? baselinePosition
      : rect.center.dx;

  double get valueEndX => orientation == BarOrientation.horizontal
      ? valueEndPosition
      : rect.center.dx;

  Offset get valueEndPoint => Offset(valueEndX, valueEndY);
  final bool isNegative;
  final double startValue;
  final double endValue;
  final double? percentage;
  final Rect? trackRect;
  final RRect? trackRRect;

  /// The bar body plus its optional background track.
  Rect get paintBounds =>
      trackRect == null ? rect : rect.expandToInclude(trackRect!);

  /// A forgiving hit target for very thin rod-style bars.
  Rect get hitBounds {
    const minimumHitThickness = 8.0;
    if (orientation == BarOrientation.horizontal) {
      if (rect.height >= minimumHitThickness) return rect;
      final padding = (minimumHitThickness - rect.height) / 2;
      return Rect.fromLTRB(
        rect.left,
        rect.top - padding,
        rect.right,
        rect.bottom + padding,
      );
    }
    if (rect.width >= minimumHitThickness) return rect;
    final padding = (minimumHitThickness - rect.width) / 2;
    return Rect.fromLTRB(
      rect.left - padding,
      rect.top,
      rect.right + padding,
      rect.bottom,
    );
  }
}

/// Resolves [BarChartSeries] data into reusable plot-space geometry.
abstract final class BarGeometryEngine {
  static List<BarGeometry> layout({
    required BarChartSeries series,
    required ChartTransform transform,
    BarGroupInfo? groupInfo,
  }) {
    series.validateRangeConfiguration();
    if (series.points.isEmpty) return const [];
    final effectiveTransform = transform.copyWith(
      transposed: series.orientation == BarOrientation.horizontal,
    );

    var groupWidth = _resolveGroupWidth(series, effectiveTransform);
    final groupCount = groupInfo?.count ?? 1;
    final totalGap = (groupInfo?.gap ?? 0) * (groupCount - 1);
    groupWidth = math.max(groupWidth, totalGap + groupCount * 4.0);
    final slotWidth = math.max(4.0, (groupWidth - totalGap) / groupCount);
    final barWidth = groupInfo?.isOverlaid == true
        ? math.max(1.0, slotWidth * series.overlayWidthFactor)
        : slotWidth;
    final compositionOffset = groupInfo?.calculateOffset(slotWidth) ?? 0.0;
    final overlayOffset = groupInfo?.isOverlaid == true
        ? slotWidth * series.overlayOffsetFactor
        : 0.0;
    final categoryOffset = compositionOffset + overlayOffset;

    return [
      for (var index = 0; index < series.points.length; index++)
        _layoutPoint(
          series: series,
          point: series.points[index],
          pointIndex: index,
          transform: effectiveTransform,
          groupInfo: groupInfo,
          defaultBarWidth: barWidth,
          categoryOffset: categoryOffset,
        ),
    ];
  }

  static double _resolveGroupWidth(
    BarChartSeries series,
    ChartTransform transform,
  ) {
    if (series.barWidthPixels case final pixels?) {
      return pixels.clamp(series.minWidth, series.maxWidth);
    }

    final spacing = _calculateCategorySpacing(series.points, transform);
    return (spacing * series.barWidthPercent!).clamp(
      series.minWidth,
      series.maxWidth,
    );
  }

  static double _calculateCategorySpacing(
    List<ChartDataPoint> points,
    ChartTransform transform,
  ) {
    if (points.length == 1) {
      return (transform.transposed
              ? transform.plotHeight
              : transform.plotWidth) *
          0.6;
    }

    var minimumDataSpacing = double.infinity;
    final ordered = [...points]
      ..sort((left, right) => left.x.compareTo(right.x));
    for (var index = 0; index < ordered.length - 1; index++) {
      final spacing = (ordered[index + 1].x - ordered[index].x).abs();
      if (spacing > 0 && spacing < minimumDataSpacing) {
        minimumDataSpacing = spacing;
      }
    }
    if (minimumDataSpacing.isFinite) {
      return minimumDataSpacing * transform.pixelsPerDataX;
    }
    return 40.0;
  }

  static BarGeometry _layoutPoint({
    required BarChartSeries series,
    required ChartDataPoint point,
    required int pointIndex,
    required ChartTransform transform,
    required BarGroupInfo? groupInfo,
    required double defaultBarWidth,
    required double categoryOffset,
  }) {
    final widthMultiplier = point.pointStyle?.size ?? 1.0;
    final width = math.max(1.0, defaultBarWidth * widthMultiplier);
    final pointPosition = transform.dataToPlot(point.x, point.y);
    final rangeStartValue = series.rangeStartValueFor(pointIndex);
    final startValue =
        groupInfo?.startValueFor(pointIndex, rangeStartValue) ??
        rangeStartValue;
    final endValue = groupInfo?.endValueFor(pointIndex, point.y) ?? point.y;
    final isNegative = endValue < startValue;

    if (series.orientation == BarOrientation.horizontal) {
      final centerY = pointPosition.dy + categoryOffset;
      final baselineX = transform.dataToPlot(point.x, startValue).dx;
      var valueEndX = transform.dataToPlot(point.x, endValue).dx;

      if ((valueEndX - baselineX).abs() < series.minBarLength) {
        final screenDirection = valueEndX == baselineX
            ? (isNegative ? -1.0 : 1.0)
            : (valueEndX - baselineX).sign;
        valueEndX = baselineX + screenDirection * series.minBarLength;
      }

      final rect = Rect.fromLTRB(
        math.min(valueEndX, baselineX),
        centerY - width / 2,
        math.max(valueEndX, baselineX),
        centerY + width / 2,
      );
      return _buildGeometry(
        series: series,
        point: point,
        pointIndex: pointIndex,
        transform: transform,
        groupInfo: groupInfo,
        rect: rect,
        baselinePosition: baselineX,
        valueEndPosition: valueEndX,
        startValue: startValue,
        endValue: endValue,
        isNegative: isNegative,
      );
    }

    final centerX = pointPosition.dx + categoryOffset;
    final baselineY = transform.dataToPlot(point.x, startValue).dy;
    var valueEndY = transform.dataToPlot(point.x, endValue).dy;

    if ((valueEndY - baselineY).abs() < series.minBarLength) {
      final screenDirection = valueEndY == baselineY
          ? (transform.invertY ? -1.0 : 1.0)
          : (valueEndY - baselineY).sign;
      valueEndY = baselineY + screenDirection * series.minBarLength;
    }

    final rect = Rect.fromLTRB(
      centerX - width / 2,
      math.min(valueEndY, baselineY),
      centerX + width / 2,
      math.max(valueEndY, baselineY),
    );
    return _buildGeometry(
      series: series,
      point: point,
      pointIndex: pointIndex,
      transform: transform,
      groupInfo: groupInfo,
      rect: rect,
      baselinePosition: baselineY,
      valueEndPosition: valueEndY,
      startValue: startValue,
      endValue: endValue,
      isNegative: isNegative,
    );
  }

  static BarGeometry _buildGeometry({
    required BarChartSeries series,
    required ChartDataPoint point,
    required int pointIndex,
    required ChartTransform transform,
    required BarGroupInfo? groupInfo,
    required Rect rect,
    required double baselinePosition,
    required double valueEndPosition,
    required double startValue,
    required double endValue,
    required bool isNegative,
  }) {
    final isOuterPoint = groupInfo?.isOuterPoint(pointIndex) ?? true;
    final isStacked = groupInfo?.isStacked ?? false;
    final roundsEveryCorner =
        series.barStyle.cornerRadiusPolicy == BarCornerRadiusPolicy.all;
    final shouldRound = !isStacked || roundsEveryCorner || isOuterPoint;
    final radius = shouldRound
        ? _clampRadius(series.barStyle.cornerRadius, rect)
        : 0.0;
    final rrect = _barRRect(
      rect,
      radius,
      series.barStyle.cornerRadiusPolicy,
      isNegative,
      transform.invertY,
      series.orientation,
    );

    final track = series.trackStyle;
    Rect? trackRect;
    RRect? trackRRect;
    if (track != null && (groupInfo?.drawTrack ?? true)) {
      final trackValue =
          track.value ?? (isNegative ? transform.dataYMin : transform.dataYMax);
      final trackEnd = transform.dataToPlot(point.x, trackValue);
      final trackBaseline =
          groupInfo?.stackBaseline ?? series.rangeStartValueFor(pointIndex);
      final trackStart = transform.dataToPlot(point.x, trackBaseline);
      trackRect = series.orientation == BarOrientation.horizontal
          ? Rect.fromLTRB(
              math.min(trackEnd.dx, trackStart.dx),
              rect.top,
              math.max(trackEnd.dx, trackStart.dx),
              rect.bottom,
            )
          : Rect.fromLTRB(
              rect.left,
              math.min(trackEnd.dy, trackStart.dy),
              rect.right,
              math.max(trackEnd.dy, trackStart.dy),
            );
      final trackRadius = _clampRadius(
        track.cornerRadius ?? series.barStyle.cornerRadius,
        trackRect,
      );
      trackRRect = RRect.fromRectAndRadius(
        trackRect,
        Radius.circular(trackRadius),
      );
    }

    return BarGeometry(
      pointIndex: pointIndex,
      point: point,
      rect: rect,
      rrect: rrect,
      orientation: series.orientation,
      baselinePosition: baselinePosition,
      valueEndPosition: valueEndPosition,
      isNegative: isNegative,
      startValue: startValue,
      endValue: endValue,
      percentage: groupInfo?.percentageFor(pointIndex),
      trackRect: trackRect,
      trackRRect: trackRRect,
    );
  }

  static double _clampRadius(double radius, Rect rect) =>
      math.min(radius, math.min(rect.width, rect.height) / 2);

  static RRect _barRRect(
    Rect rect,
    double radius,
    BarCornerRadiusPolicy policy,
    bool isNegative,
    bool invertY,
    BarOrientation orientation,
  ) {
    if (radius <= 0) return RRect.fromRectAndRadius(rect, Radius.zero);
    if (policy == BarCornerRadiusPolicy.all) {
      return RRect.fromRectAndRadius(rect, Radius.circular(radius));
    }

    final rounded = Radius.circular(radius);
    if (orientation == BarOrientation.horizontal) {
      return RRect.fromRectAndCorners(
        rect,
        topLeft: isNegative ? rounded : Radius.zero,
        bottomLeft: isNegative ? rounded : Radius.zero,
        topRight: isNegative ? Radius.zero : rounded,
        bottomRight: isNegative ? Radius.zero : rounded,
      );
    }
    final roundedEndIsTop = invertY ? !isNegative : isNegative;
    return RRect.fromRectAndCorners(
      rect,
      topLeft: roundedEndIsTop ? rounded : Radius.zero,
      topRight: roundedEndIsTop ? rounded : Radius.zero,
      bottomLeft: roundedEndIsTop ? Radius.zero : rounded,
      bottomRight: roundedEndIsTop ? Radius.zero : rounded,
    );
  }
}
