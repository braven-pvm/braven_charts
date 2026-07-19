// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../models/candlestick_chart_style.dart';
import '../models/candlestick_data_point.dart';

/// The source-index range that can overlap the current X viewport.
class CandlestickVisibleRange {
  const CandlestickVisibleRange(this.start, this.endExclusive);

  final int start;
  final int endExclusive;

  int get length => endExclusive - start;
  bool get isEmpty => length == 0;
}

/// Immutable source index for ordered candlestick data.
///
/// Construction performs the only whole-series pass. Viewport queries use two
/// binary searches and therefore do not rescan large source lists while
/// panning or zooming.
class CandlestickViewportIndex {
  CandlestickViewportIndex(List<CandlestickDataPoint> points)
    : points = List<CandlestickDataPoint>.unmodifiable(points),
      nominalSpacingData = _medianPositiveSpacing(points) {
    double? previousX;
    for (var index = 0; index < points.length; index++) {
      final x = points[index].x;
      if (previousX != null && x <= previousX) {
        throw ArgumentError.value(
          x,
          'points[$index].x',
          'must be strictly greater than points[${index - 1}].x ($previousX)',
        );
      }
      previousX = x;
    }
  }

  final List<CandlestickDataPoint> points;

  /// Median positive interval between adjacent source candles.
  ///
  /// Returns null for fewer than two points.
  final double? nominalSpacingData;

  CandlestickVisibleRange visibleRange({
    required double xMin,
    required double xMax,
    double paddingData = 0,
  }) {
    if (points.isEmpty) return const CandlestickVisibleRange(0, 0);
    if (!xMin.isFinite || !xMax.isFinite || xMax < xMin) {
      throw ArgumentError('Viewport X bounds must be finite and ordered');
    }
    if (!paddingData.isFinite || paddingData < 0) {
      throw ArgumentError.value(
        paddingData,
        'paddingData',
        'must be finite and non-negative',
      );
    }
    final start = _lowerBound(xMin - paddingData);
    final end = _upperBound(xMax + paddingData);
    return CandlestickVisibleRange(start, end);
  }

  int _lowerBound(double value) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (points[middle].x < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int _upperBound(double value) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (points[middle].x <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  static double? _medianPositiveSpacing(List<CandlestickDataPoint> points) {
    if (points.length < 2) return null;
    final spacings = List<double>.generate(
      points.length - 1,
      (index) => points[index + 1].x - points[index].x,
      growable: false,
    )..sort();
    // Use the lower median for an even sample count. It is deliberately
    // resistant to one large market-closure interval in a short series.
    return spacings[(spacings.length - 1) >> 1];
  }
}

/// Pure plot-space geometry for one visible source candle.
class CandlestickGeometry {
  const CandlestickGeometry({
    required this.pointIndex,
    required this.point,
    required this.direction,
    required this.centerX,
    required this.bodyWidth,
    required this.bodyRect,
    required this.bodyRRect,
    required this.upperWickStart,
    required this.upperWickEnd,
    required this.lowerWickStart,
    required this.lowerWickEnd,
    required this.paintBounds,
    required this.hitBounds,
  });

  final int pointIndex;
  final CandlestickDataPoint point;
  final CandlestickDirection direction;
  final double centerX;
  final double bodyWidth;
  final Rect bodyRect;
  final RRect bodyRRect;
  final Offset upperWickStart;
  final Offset upperWickEnd;
  final Offset lowerWickStart;
  final Offset lowerWickEnd;
  final Rect paintBounds;
  final Rect hitBounds;
}

/// Resolves visible candlestick geometry without painting or allocating style
/// objects per candle.
class CandlestickGeometryEngine {
  const CandlestickGeometryEngine._();

  static List<CandlestickGeometry> resolve({
    required CandlestickViewportIndex index,
    required ChartTransform transform,
    required CandlestickChartStyle style,
    double devicePixelRatio = 1,
    double minimumHitTargetSize = 8,
  }) {
    style.validate();
    if (transform.transposed) {
      throw ArgumentError(
        'Candlestick geometry does not support transposition',
      );
    }
    if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
      throw ArgumentError.value(
        devicePixelRatio,
        'devicePixelRatio',
        'must be finite and greater than 0',
      );
    }
    if (!minimumHitTargetSize.isFinite || minimumHitTargetSize < 0) {
      throw ArgumentError.value(
        minimumHitTargetSize,
        'minimumHitTargetSize',
        'must be finite and non-negative',
      );
    }

    final spacingPixels = index.nominalSpacingData == null
        ? style.maxBodyWidth / style.bodyWidthFactor
        : index.nominalSpacingData! * transform.pixelsPerDataX;
    final bodyWidth = (spacingPixels * style.bodyWidthFactor).clamp(
      style.minBodyWidth,
      style.maxBodyWidth,
    );
    final paddingData = (bodyWidth / 2) * transform.dataPerPixelX;
    final visible = index.visibleRange(
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      paddingData: paddingData,
    );
    if (visible.isEmpty) return const [];

    return List<CandlestickGeometry>.generate(visible.length, (offset) {
      final pointIndex = visible.start + offset;
      return _resolveOne(
        pointIndex: pointIndex,
        point: index.points[pointIndex],
        transform: transform,
        style: style,
        bodyWidth: bodyWidth,
        devicePixelRatio: devicePixelRatio,
        minimumHitTargetSize: minimumHitTargetSize,
      );
    }, growable: false);
  }

  static CandlestickGeometry _resolveOne({
    required int pointIndex,
    required CandlestickDataPoint point,
    required ChartTransform transform,
    required CandlestickChartStyle style,
    required double bodyWidth,
    required double devicePixelRatio,
    required double minimumHitTargetSize,
  }) {
    final centerX = _align(
      transform.dataToPlot(point.x, point.close).dx,
      devicePixelRatio,
    );
    final highY = transform.dataToPlot(point.x, point.high).dy;
    final lowY = transform.dataToPlot(point.x, point.low).dy;
    final openY = transform.dataToPlot(point.x, point.open).dy;
    final closeY = transform.dataToPlot(point.x, point.close).dy;
    final rawTop = math.min(openY, closeY);
    final rawBottom = math.max(openY, closeY);
    final rawHeight = rawBottom - rawTop;
    final bodyHeight = math.max(rawHeight, style.minimumBodyHeight);
    final bodyCenterY = (rawTop + rawBottom) / 2;
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, bodyCenterY),
      width: bodyWidth,
      height: bodyHeight,
    );
    final cornerRadius = math.min(
      style.bodyCornerRadius,
      math.min(bodyRect.width, bodyRect.height) / 2,
    );
    final upperWickStart = Offset(centerX, highY);
    final upperWickEnd = Offset(
      centerX,
      highY <= bodyCenterY ? bodyRect.top : bodyRect.bottom,
    );
    final lowerWickStart = Offset(
      centerX,
      lowY <= bodyCenterY ? bodyRect.top : bodyRect.bottom,
    );
    final lowerWickEnd = Offset(centerX, lowY);
    final wickBounds = Rect.fromLTRB(
      centerX,
      math.min(math.min(highY, lowY), bodyRect.top),
      centerX,
      math.max(math.max(highY, lowY), bodyRect.bottom),
    );
    final strokeInflation =
        math.max(style.bodyBorderWidth, style.wickWidth) / 2;
    final paintBounds = bodyRect
        .expandToInclude(wickBounds)
        .inflate(strokeInflation);
    final hitWidth = math.max(paintBounds.width, minimumHitTargetSize);
    final hitHeight = math.max(paintBounds.height, minimumHitTargetSize);
    final hitBounds = Rect.fromCenter(
      center: paintBounds.center,
      width: hitWidth,
      height: hitHeight,
    );

    return CandlestickGeometry(
      pointIndex: pointIndex,
      point: point,
      direction: point.direction,
      centerX: centerX,
      bodyWidth: bodyWidth,
      bodyRect: bodyRect,
      bodyRRect: RRect.fromRectAndRadius(
        bodyRect,
        Radius.circular(cornerRadius),
      ),
      upperWickStart: upperWickStart,
      upperWickEnd: upperWickEnd,
      lowerWickStart: lowerWickStart,
      lowerWickEnd: lowerWickEnd,
      paintBounds: paintBounds,
      hitBounds: hitBounds,
    );
  }

  static double _align(double value, double devicePixelRatio) =>
      (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
}
