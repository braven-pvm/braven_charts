// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../models/candlestick_chart_style.dart';
import '../models/candlestick_data_point.dart';
import '../models/candlestick_density_grouping.dart';

/// The source-index range that can overlap the current X viewport.
class CandlestickVisibleRange {
  const CandlestickVisibleRange(this.start, this.endExclusive);

  final int start;
  final int endExclusive;

  int get length => endExclusive - start;
  bool get isEmpty => length == 0;
}

/// One render-time OHLC projection and its complete raw source identity.
class CandlestickProjection {
  const CandlestickProjection({
    required this.point,
    required this.sourceStartIndex,
    required this.sourceEndIndexExclusive,
  }) : assert(sourceStartIndex >= 0),
       assert(sourceEndIndexExclusive > sourceStartIndex);

  final CandlestickDataPoint point;
  final int sourceStartIndex;
  final int sourceEndIndexExclusive;

  int get sourceCount => sourceEndIndexExclusive - sourceStartIndex;
  bool get isGrouped => sourceCount > 1;

  /// Stable identity for this grouping resolution.
  String get groupKey => '$sourceStartIndex:$sourceEndIndexExclusive';

  /// Every raw point represented by this projection, in source order.
  List<int> get sourcePointIndices => List<int>.unmodifiable(
    List<int>.generate(
      sourceCount,
      (offset) => sourceStartIndex + offset,
      growable: false,
    ),
  );
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

/// Builds density-aware OHLC projections without changing source data.
abstract final class CandlestickDensityProjector {
  static List<CandlestickProjection> project({
    required CandlestickViewportIndex index,
    required double xMin,
    required double xMax,
    required double plotWidth,
    required CandlestickDensityGrouping grouping,
    double paddingData = 0,
  }) {
    grouping.validate();
    final visible = index.visibleRange(
      xMin: xMin,
      xMax: xMax,
      paddingData: paddingData,
    );
    if (visible.isEmpty) return const [];

    final maximumGroupCount = plotWidth.isFinite && plotWidth > 0
        ? math.max(1, (plotWidth / grouping.targetGroupWidth).floor())
        : visible.length;
    final proposedGroupSize = (visible.length / maximumGroupCount).ceil();
    if (!grouping.enabled ||
        proposedGroupSize < grouping.minimumPointsPerGroup) {
      return List<CandlestickProjection>.generate(visible.length, (offset) {
        final sourceIndex = visible.start + offset;
        return CandlestickProjection(
          point: index.points[sourceIndex],
          sourceStartIndex: sourceIndex,
          sourceEndIndexExclusive: sourceIndex + 1,
        );
      }, growable: false);
    }

    final groupSize = math.max(
      grouping.minimumPointsPerGroup,
      proposedGroupSize,
    );
    final firstGroupStart = (visible.start ~/ groupSize) * groupSize;
    final projections = <CandlestickProjection>[];
    for (
      var groupStart = firstGroupStart;
      groupStart < visible.endExclusive;
      groupStart += groupSize
    ) {
      final groupEnd = math.min(index.points.length, groupStart + groupSize);
      if (groupEnd <= visible.start || groupStart >= visible.endExclusive) {
        continue;
      }
      projections.add(_aggregate(index.points, groupStart, groupEnd));
    }
    return List<CandlestickProjection>.unmodifiable(projections);
  }

  static CandlestickProjection _aggregate(
    List<CandlestickDataPoint> points,
    int start,
    int endExclusive,
  ) {
    final first = points[start];
    final last = points[endExclusive - 1];
    var high = first.high;
    var low = first.low;
    for (
      var sourceIndex = start + 1;
      sourceIndex < endExclusive;
      sourceIndex++
    ) {
      final point = points[sourceIndex];
      if (point.high > high) high = point.high;
      if (point.low < low) low = point.low;
    }
    return CandlestickProjection(
      point: CandlestickDataPoint(
        x: first.x,
        open: first.open,
        high: high,
        low: low,
        close: last.close,
        timestamp: first.timestamp,
      ),
      sourceStartIndex: start,
      sourceEndIndexExclusive: endExclusive,
    );
  }
}

/// Pure plot-space geometry for one visible source candle.
class CandlestickGeometry {
  const CandlestickGeometry({
    required this.projectionIndex,
    required this.pointIndex,
    required this.sourceStartIndex,
    required this.sourceEndIndexExclusive,
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

  /// Zero-based position within the current render projection.
  final int projectionIndex;

  /// First raw source index represented by this candle.
  final int pointIndex;
  final int sourceStartIndex;
  final int sourceEndIndexExclusive;
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

  int get sourceCount => sourceEndIndexExclusive - sourceStartIndex;
  bool get isGrouped => sourceCount > 1;
  String get groupKey => '$sourceStartIndex:$sourceEndIndexExclusive';
  List<int> get sourcePointIndices => List<int>.unmodifiable(
    List<int>.generate(
      sourceCount,
      (offset) => sourceStartIndex + offset,
      growable: false,
    ),
  );

  bool representsSourcePoint(int sourcePointIndex) =>
      sourcePointIndex >= sourceStartIndex &&
      sourcePointIndex < sourceEndIndexExclusive;
}

/// Resolves visible candlestick geometry without painting or allocating style
/// objects per candle.
class CandlestickGeometryEngine {
  const CandlestickGeometryEngine._();

  static List<CandlestickGeometry> resolve({
    required CandlestickViewportIndex index,
    required ChartTransform transform,
    required CandlestickChartStyle style,
    CandlestickDensityGrouping grouping = const CandlestickDensityGrouping(),
    double devicePixelRatio = 1,
    double minimumHitTargetSize = 8,
  }) {
    style.validate();
    grouping.validate();
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
    var projections = CandlestickDensityProjector.project(
      index: index,
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      plotWidth: transform.plotWidth,
      grouping: grouping,
      // Group sizing uses the exact viewport, matching crosshair tracking.
      // A full aligned bucket already carries the source candle immediately
      // before an interior viewport edge when that bucket overlaps the view.
      paddingData: grouping.enabled ? 0 : paddingData,
    );
    if (grouping.enabled && projections.every((item) => !item.isGrouped)) {
      // When opt-in grouping does not activate at this density, preserve the
      // legacy raw edge-body padding exactly.
      projections = CandlestickDensityProjector.project(
        index: index,
        xMin: transform.dataXMin,
        xMax: transform.dataXMax,
        plotWidth: transform.plotWidth,
        grouping: grouping.copyWith(enabled: false),
        paddingData: paddingData,
      );
    }
    if (projections.isEmpty) return const [];

    final projectedSpacingData = _medianPositiveProjectionSpacing(projections);
    final projectedSpacingPixels = projectedSpacingData == null
        ? style.maxBodyWidth / style.bodyWidthFactor
        : projectedSpacingData * transform.pixelsPerDataX;
    final projectedBodyWidth = (projectedSpacingPixels * style.bodyWidthFactor)
        .clamp(style.minBodyWidth, style.maxBodyWidth);

    return List<CandlestickGeometry>.generate(projections.length, (offset) {
      final projection = projections[offset];
      return _resolveOne(
        projectionIndex: offset,
        pointIndex: projection.sourceStartIndex,
        sourceStartIndex: projection.sourceStartIndex,
        sourceEndIndexExclusive: projection.sourceEndIndexExclusive,
        point: projection.point,
        transform: transform,
        style: style,
        bodyWidth: projectedBodyWidth,
        devicePixelRatio: devicePixelRatio,
        minimumHitTargetSize: minimumHitTargetSize,
      );
    }, growable: false);
  }

  static CandlestickGeometry _resolveOne({
    required int projectionIndex,
    required int pointIndex,
    required int sourceStartIndex,
    required int sourceEndIndexExclusive,
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
      projectionIndex: projectionIndex,
      pointIndex: pointIndex,
      sourceStartIndex: sourceStartIndex,
      sourceEndIndexExclusive: sourceEndIndexExclusive,
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

  static double? _medianPositiveProjectionSpacing(
    List<CandlestickProjection> projections,
  ) {
    if (projections.length < 2) return null;
    final spacings = <double>[];
    for (var index = 1; index < projections.length; index++) {
      final spacing =
          projections[index].point.x - projections[index - 1].point.x;
      if (spacing > 0 && spacing.isFinite) spacings.add(spacing);
    }
    if (spacings.isEmpty) return null;
    spacings.sort();
    return spacings[(spacings.length - 1) >> 1];
  }
}
