import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../layout/pie_chart_geometry.dart';
import '../models/chart_data_point.dart';
import '../models/chart_theme.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../rendering/pie_slice_color_resolver.dart';

/// Radial chart element responsible for pie wedges and deterministic labels.
class PieSeriesElement implements DataHitElement {
  /// Creates a pie element for one resolved plot size.
  PieSeriesElement({
    required this.series,
    required this.size,
    required this.theme,
    this.seriesIndex = 0,
    this.textScaleFactor = 1,
    this.focusedPointIndices = const <int>{},
    this.selectedPointIndices = const <int>{},
    this.coordinator,
    this.isSelected = false,
    this.isHovered = false,
  }) : geometry = PieChartGeometryCalculator.calculate(
         series: series,
         size: size,
         padding: _geometryPadding(series, size, textScaleFactor),
         explodedPointIndices: selectedPointIndices,
       );

  @override
  final PieChartSeries series;

  /// Plot-local size used to resolve the radial geometry.
  final Size size;

  /// Effective chart theme.
  final ChartTheme theme;

  @override
  final int seriesIndex;

  /// Media text scale captured by the widget layer.
  final double textScaleFactor;

  /// Source-point indices receiving transient keyboard or linked focus.
  final Set<int> focusedPointIndices;

  /// Durable source-point indices shown with explode geometry.
  final Set<int> selectedPointIndices;

  /// Shared interaction state used for dynamic hover highlighting.
  final ChartInteractionCoordinator? coordinator;

  /// Immutable geometry shared by painting and hit testing.
  final PieChartGeometry geometry;

  @override
  final bool isSelected;

  @override
  final bool isHovered;

  @override
  int get pointCount => series.points.length;

  @override
  String get id => series.id;

  @override
  Rect get bounds => Offset.zero & size;

  @override
  ChartElementType get elementType => ChartElementType.series;

  @override
  int get priority => ElementPriority.series;

  @override
  int get renderOrder => RenderOrder.series;

  /// Slice colors after point overrides, series preference, and theme cycling.
  List<Color> get resolvedSliceColors => List<Color>.unmodifiable([
    for (final (visibleIndex, slice) in geometry.slices.indexed)
      _resolveSliceColor(slice.point, visibleIndex),
  ]);

  /// Returns the visible slice at [position], if any.
  PieSliceGeometry? sliceAt(Offset position) => geometry.sliceAt(position);

  @override
  ChartDataHit? dataHitAt(Offset position, {double maxDistance = 20}) {
    final slice = sliceAt(position);
    return slice == null ? null : _dataHitForSlice(slice);
  }

  @override
  ChartDataHit? dataHitForPointIndex(int pointIndex) {
    for (final slice in geometry.slices) {
      if (slice.pointIndex == pointIndex) return _dataHitForSlice(slice);
    }
    return null;
  }

  @override
  Iterable<ChartDataHit> get semanticDataHits =>
      geometry.slices.map(_dataHitForSlice);

  @override
  bool get isSelectable => false;

  @override
  bool get isDraggable => false;

  @override
  bool hitTest(Offset position) => sliceAt(position) != null;

  @override
  void paint(Canvas canvas, Size size) {
    final slices = geometry.slices;
    for (final (index, slice) in slices.indexed) {
      final fillColor = _resolveSliceColor(slice.point, index);
      canvas.drawPath(
        slice.path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor
          ..isAntiAlias = true,
      );
      if (series.pieStyle.borderWidth > 0) {
        canvas.drawPath(
          slice.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = series.pieStyle.borderWidth
            ..strokeJoin = StrokeJoin.round
            ..color = series.pieStyle.borderColor ?? theme.axisStyle.lineColor
            ..isAntiAlias = true,
        );
      }
      final hoveredMarker = coordinator?.hoveredMarker;
      final isHovered =
          hoveredMarker?.seriesId == series.id &&
          hoveredMarker?.markerIndex == slice.pointIndex;
      if (isHovered) {
        canvas.drawPath(
          slice.path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = theme.interactionTheme.selectionColor
            ..isAntiAlias = true,
        );
      }
      if (selectedPointIndices.contains(slice.pointIndex) ||
          focusedPointIndices.contains(slice.pointIndex)) {
        final isFocused = focusedPointIndices.contains(slice.pointIndex);
        canvas.drawPath(
          slice.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isFocused
                ? math.max(3, theme.focusBorderWidth)
                : math.max(2, series.pieStyle.borderWidth + 1)
            ..strokeJoin = StrokeJoin.round
            ..color = isFocused
                ? theme.focusBorderColor
                : theme.interactionTheme.selectionColor.withValues(alpha: 1)
            ..isAntiAlias = true,
        );
      }
    }

    if (!series.dataLabels.isVisible || slices.isEmpty) {
      return;
    }
    if (series.dataLabels.position == PieDataLabelPosition.inside) {
      _paintInsideLabels(canvas);
    } else {
      _paintOutsideLabels(canvas);
    }
  }

  void _paintInsideLabels(Canvas canvas) {
    for (final (index, slice) in geometry.slices.indexed) {
      if (!_isLabelEligible(slice)) {
        continue;
      }
      final color = _resolveSliceColor(slice.point, index);
      final painter = _labelPainter(
        slice,
        color: color.computeLuminance() > 0.46
            ? const Color(0xFF111827)
            : const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w600,
      );
      final radialThickness = slice.outerRadius - slice.innerRadius;
      if (painter.width > radialThickness * 0.95 ||
          painter.height > radialThickness * 0.55) {
        continue;
      }
      painter.paint(
        canvas,
        slice.insideLabelAnchor - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _paintOutsideLabels(Canvas canvas) {
    final candidates = <_PieLabelCandidate>[];
    for (final (index, slice) in geometry.slices.indexed) {
      if (!_isLabelEligible(slice)) {
        continue;
      }
      final painter = _labelPainter(
        slice,
        color: theme.axisStyle.labelStyle.color ?? const Color(0xFF374151),
        fontWeight: FontWeight.w500,
      );
      candidates.add(
        _PieLabelCandidate(
          slice: slice,
          painter: painter,
          color: _resolveSliceColor(slice.point, index),
          isLeft: math.cos(slice.midAngle) < 0,
        ),
      );
    }

    final left = candidates.where((candidate) => candidate.isLeft).toList();
    final right = candidates.where((candidate) => !candidate.isLeft).toList();
    _resolveLabelLane(left);
    _resolveLabelLane(right);

    for (final candidate in [...left, ...right]) {
      final rect = candidate.labelRect;
      if (rect == null) {
        continue;
      }
      final labelEdge = candidate.isLeft
          ? Offset(rect.right, rect.center.dy)
          : Offset(rect.left, rect.center.dy);
      final elbowX = candidate.isLeft
          ? math.min(
              candidate.slice.connectorOrigin.dx,
              labelEdge.dx + series.dataLabels.padding,
            )
          : math.max(
              candidate.slice.connectorOrigin.dx,
              labelEdge.dx - series.dataLabels.padding,
            );
      final elbow = Offset(elbowX, rect.center.dy);
      final connectorPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = series.dataLabels.connectorWidth
        ..strokeCap = StrokeCap.round
        ..color = series.dataLabels.connectorColor ?? candidate.color;
      canvas.drawLine(candidate.slice.connectorOrigin, elbow, connectorPaint);
      canvas.drawLine(elbow, labelEdge, connectorPaint);
      candidate.painter.paint(canvas, rect.topLeft);
    }
  }

  void _resolveLabelLane(List<_PieLabelCandidate> lane) {
    if (lane.isEmpty) {
      return;
    }
    lane.sort((a, b) {
      final vertical = a.slice.outsideLabelAnchor.dy.compareTo(
        b.slice.outsideLabelAnchor.dy,
      );
      return vertical != 0
          ? vertical
          : a.slice.pointIndex.compareTo(b.slice.pointIndex);
    });

    final collisionStrategy = series.dataLabels.collisionStrategy;
    final visible = [...lane];
    while (visible.isNotEmpty) {
      final fits = _positionLabelLane(
        visible,
        allowShift: collisionStrategy != PieDataLabelCollisionStrategy.none,
      );
      if (fits ||
          collisionStrategy != PieDataLabelCollisionStrategy.shiftAndHide) {
        break;
      }
      final lowestPriority = visible.reduce((a, b) {
        final share = a.slice.share.compareTo(b.slice.share);
        if (share != 0) {
          return share < 0 ? a : b;
        }
        return a.slice.pointIndex > b.slice.pointIndex ? a : b;
      });
      lowestPriority.labelRect = null;
      visible.remove(lowestPriority);
    }
  }

  bool _positionLabelLane(
    List<_PieLabelCandidate> lane, {
    required bool allowShift,
  }) {
    const edgePadding = 4.0;
    final minimumGap = 4 * textScaleFactor;
    var nextTop = edgePadding;
    for (final candidate in lane) {
      final desiredTop =
          candidate.slice.outsideLabelAnchor.dy - candidate.painter.height / 2;
      final top = allowShift ? math.max(desiredTop, nextTop) : desiredTop;
      final x = candidate.isLeft
          ? edgePadding
          : size.width - edgePadding - candidate.painter.width;
      candidate.labelRect = Rect.fromLTWH(
        x,
        top,
        candidate.painter.width,
        candidate.painter.height,
      );
      nextTop = top + candidate.painter.height + minimumGap;
    }

    final overflow =
        (lane.last.labelRect?.bottom ?? 0) - (size.height - edgePadding);
    if (allowShift && overflow > 0) {
      for (final candidate in lane) {
        final rect = candidate.labelRect;
        if (rect != null) {
          candidate.labelRect = rect.shift(Offset(0, -overflow));
        }
      }
    }

    var previousBottom = edgePadding - minimumGap;
    var fits = true;
    for (final candidate in lane) {
      final rect = candidate.labelRect;
      if (rect == null) {
        continue;
      }
      if (rect.top < edgePadding || rect.top < previousBottom + minimumGap) {
        fits = false;
      }
      previousBottom = rect.bottom;
    }
    return fits && previousBottom <= size.height - edgePadding;
  }

  bool _isLabelEligible(PieSliceGeometry slice) {
    final minimumSweep = series.dataLabels.minimumSweepDegrees * math.pi / 180;
    return slice.share >= series.dataLabels.minimumShare &&
        slice.sweepAngle.abs() >= minimumSweep;
  }

  TextPainter _labelPainter(
    PieSliceGeometry slice, {
    required Color color,
    required FontWeight fontWeight,
  }) {
    final typography = theme.typographyTheme;
    final fontSize =
        typography.baseFontSize * typography.labelMultiplier * textScaleFactor;
    return TextPainter(
      text: TextSpan(
        text: _labelText(slice),
        style: TextStyle(
          color: color,
          fontFamily: typography.fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(32, size.width * 0.32));
  }

  String _labelText(PieSliceGeometry slice) {
    final category = slice.point.label!.trim();
    final value =
        '${slice.point.y.toStringAsFixed(2)}'
        '${series.unit == null || series.unit!.isEmpty ? '' : ' ${series.unit}'}';
    final percentage = '${(slice.share * 100).toStringAsFixed(1)}%';
    return switch (series.dataLabels.content) {
      PieDataLabelContent.category => category,
      PieDataLabelContent.value => value,
      PieDataLabelContent.percentage => percentage,
      PieDataLabelContent.categoryAndValue => '$category • $value',
      PieDataLabelContent.categoryAndPercentage => '$category • $percentage',
      PieDataLabelContent.valueAndPercentage => '$value • $percentage',
      PieDataLabelContent.categoryValueAndPercentage =>
        '$category • $value • $percentage',
    };
  }

  Color _resolveSliceColor(ChartDataPoint point, int visibleIndex) {
    return PieSliceColorResolver.resolve(
      series: series,
      theme: theme,
      point: point,
      visibleIndex: visibleIndex,
    );
  }

  ChartDataHit _dataHitForSlice(PieSliceGeometry slice) {
    final visibleIndex = geometry.slices.indexOf(slice);
    final unit = series.unit == null || series.unit!.isEmpty
        ? ''
        : ' ${series.unit}';
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: slice.pointIndex,
      plotPosition: slice.insideLabelAnchor,
      semanticBounds: slice.path.getBounds(),
      point: slice.point,
      category: slice.point.label!.trim(),
      total: geometry.total,
      share: slice.share,
      formattedValue: '${slice.point.y.toStringAsFixed(2)}$unit',
      ordinal: visibleIndex + 1,
      count: geometry.slices.length,
      isSelected: selectedPointIndices.contains(slice.pointIndex),
      isFocused: focusedPointIndices.contains(slice.pointIndex),
    );
  }

  @override
  void onSelect() {}

  @override
  void onDeselect() {}

  @override
  void onHoverEnter() {}

  @override
  void onHoverExit() {}

  @override
  PieSeriesElement copyWith({bool? isHovered, bool? isSelected}) {
    return PieSeriesElement(
      series: series,
      size: size,
      theme: theme,
      seriesIndex: seriesIndex,
      textScaleFactor: textScaleFactor,
      focusedPointIndices: focusedPointIndices,
      selectedPointIndices: selectedPointIndices,
      coordinator: coordinator,
      isHovered: isHovered ?? this.isHovered,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  static EdgeInsets _geometryPadding(
    PieChartSeries series,
    Size size,
    double textScaleFactor,
  ) {
    if (!series.dataLabels.isVisible ||
        series.dataLabels.position == PieDataLabelPosition.inside) {
      return const EdgeInsets.all(12);
    }
    final horizontal = math.min(
      math.max(36.0, size.width * 0.22 * textScaleFactor),
      size.width * 0.34,
    );
    final vertical = math.min(28 * textScaleFactor, size.height * 0.18);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}

class _PieLabelCandidate {
  _PieLabelCandidate({
    required this.slice,
    required this.painter,
    required this.color,
    required this.isLeft,
  });

  final PieSliceGeometry slice;
  final TextPainter painter;
  final Color color;
  final bool isLeft;
  Rect? labelRect;
}
