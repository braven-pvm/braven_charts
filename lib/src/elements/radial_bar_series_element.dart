import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../formatting/multi_axis_value_formatter.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../layout/annular_sector_geometry.dart';
import '../layout/radial_bar_geometry.dart';
import '../layout/radial_pane_geometry.dart';
import '../models/chart_theme.dart';
import '../models/radial_bar_chart_config.dart';
import '../models/radial_bar_chart_series.dart';
import '../models/radial_selection_style.dart';
import '../theming/styles/label_style.dart';
import '../utils/dashed_path.dart';

/// Track, guide, label, and interaction element for Radial Bar v0.1.
class RadialBarSeriesElement implements DataHitElement {
  factory RadialBarSeriesElement({
    required RadialBarChartSeries series,
    required RadialBarChartConfig config,
    required Size size,
    required ChartTheme theme,
    int seriesIndex = 0,
    Set<int> focusedPointIndices = const <int>{},
    Set<int> selectedPointIndices = const <int>{},
    double revealProgress = 1,
    double textScaleFactor = 1,
    TextDirection textDirection = TextDirection.ltr,
    bool isSelected = false,
    bool isHovered = false,
  }) {
    config.validate();
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(
        size,
        'size',
        'Size must be finite and positive',
      );
    }
    if (!revealProgress.isFinite || revealProgress < 0 || revealProgress > 1) {
      throw ArgumentError.value(
        revealProgress,
        'revealProgress',
        'Value must be finite and in [0, 1]',
      );
    }
    if (!textScaleFactor.isFinite || textScaleFactor <= 0) {
      throw ArgumentError.value(
        textScaleFactor,
        'textScaleFactor',
        'Value must be finite and positive',
      );
    }
    final paneConfig = config.pane;
    final dataLabels = series.radialBarStyle.dataLabels;
    final outsideLabels =
        series.radialBarStyle.showDataLabels &&
        dataLabels.position == RadialBarDataLabelPosition.outsideCallout;
    final categoryLabels = config.categoryLabels;
    final outsideCategoryLabels =
        config.showCategoryLabels &&
        categoryLabels.position != RadialBarCategoryLabelPosition.legacyOnTrack;
    final scaleReserve = config.showScaleLabels
        ? math.min(18 * textScaleFactor, size.shortestSide * 0.08)
        : 0.0;
    final horizontalCalloutReserve = outsideLabels
        ? math.min(96 * textScaleFactor, size.width * 0.2)
        : scaleReserve;
    final categoryHorizontalReserve = outsideCategoryLabels
        ? math.min(72 * textScaleFactor, size.width * 0.16)
        : scaleReserve;
    final categoryVerticalReserve = outsideCategoryLabels
        ? math.min(36 * textScaleFactor, size.height * 0.1)
        : scaleReserve;
    final pane = RadialPaneGeometry.resolve(
      viewportBounds: Offset.zero & size,
      viewportInsets: EdgeInsets.all(12 * textScaleFactor),
      reservedLabelInsets: EdgeInsets.fromLTRB(
        math.max(horizontalCalloutReserve, categoryHorizontalReserve),
        categoryVerticalReserve,
        math.max(horizontalCalloutReserve, categoryHorizontalReserve),
        categoryVerticalReserve,
      ),
      innerRadiusFactor: paneConfig.innerRadiusFactor,
      outerRadiusFactor: paneConfig.outerRadiusFactor,
      startAngle: paneConfig.startAngleDegrees * math.pi / 180,
      sweepAngle: paneConfig.sweepAngleDegrees * math.pi / 180,
      clockwise: paneConfig.clockwise,
    );
    final animatedValues = <double>[
      for (final point in series.points)
        series.baseline + (point.y - series.baseline) * revealProgress,
    ];
    final geometry = RadialBarGeometryCalculator.calculate(
      pane: pane,
      categories: series.categories,
      values: animatedValues,
      minimum: series.minimum,
      maximum: series.maximum,
      baseline: series.baseline,
      trackGap: config.trackGap,
      trackOrder: config.trackOrder,
      cornerRadius: series.radialBarStyle.cornerRadius * revealProgress,
    );
    return RadialBarSeriesElement._(
      series: series,
      config: config,
      size: size,
      theme: theme,
      seriesIndex: seriesIndex,
      focusedPointIndices: focusedPointIndices,
      selectedPointIndices: selectedPointIndices,
      revealProgress: revealProgress,
      textScaleFactor: textScaleFactor,
      textDirection: textDirection,
      pane: pane,
      geometry: geometry,
      isSelected: isSelected,
      isHovered: isHovered,
    );
  }

  RadialBarSeriesElement._({
    required this.series,
    required this.config,
    required this.size,
    required this.theme,
    required this.seriesIndex,
    required this.focusedPointIndices,
    required this.selectedPointIndices,
    required this.revealProgress,
    required this.textScaleFactor,
    required this.textDirection,
    required this.pane,
    required this.geometry,
    required this.isSelected,
    required this.isHovered,
  });

  @override
  final RadialBarChartSeries series;
  final RadialBarChartConfig config;
  final Size size;
  final ChartTheme theme;
  @override
  final int seriesIndex;
  final Set<int> focusedPointIndices;
  final Set<int> selectedPointIndices;
  final double revealProgress;
  final double textScaleFactor;
  final TextDirection textDirection;
  final RadialPaneGeometry pane;
  final RadialBarGeometry geometry;
  final List<Rect> _debugOutsideDataLabelRects = <Rect>[];
  final List<Offset> _debugOutsideConnectorOrigins = <Offset>[];
  final List<List<Offset>> _debugOutsideConnectorRoutes = <List<Offset>>[];
  final List<Rect> _debugInsideDataLabelRects = <Rect>[];
  final List<Rect> _debugCategoryLabelRects = <Rect>[];
  final List<Offset> _debugCategoryConnectorOrigins = <Offset>[];
  final List<List<Offset>> _debugCategoryConnectorRoutes = <List<Offset>>[];
  final List<double> _debugCategoryLabelRotations = <double>[];
  final List<Offset> _debugCategoryLabelTrackAnchors = <Offset>[];
  final List<Offset> _debugCategoryLabelAttachmentAnchors = <Offset>[];
  final List<Rect> _debugScaleLabelRects = <Rect>[];
  final List<Rect> _debugThresholdLabelRects = <Rect>[];

  @override
  final bool isSelected;
  @override
  final bool isHovered;
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
  @override
  int get pointCount => series.points.length;
  @override
  bool get isSelectable => false;
  @override
  bool get isDraggable => false;

  List<Color> get resolvedMarkColors => List<Color>.unmodifiable([
    for (final (index, point) in series.points.indexed)
      point.pointStyle?.color ??
          series.color ??
          theme.seriesTheme.colors[index % theme.seriesTheme.colors.length],
  ]);

  @override
  bool hitTest(Offset position) => _markAt(position) != null;

  @override
  ChartDataHit? dataHitAt(Offset position, {double maxDistance = 20}) {
    final mark = _markAt(position);
    return mark == null ? null : _dataHitForMark(mark);
  }

  @override
  ChartDataHit? dataHitForPointIndex(int pointIndex) {
    if (pointIndex < 0 || pointIndex >= geometry.marks.length) return null;
    return _dataHitForMark(geometry.marks[pointIndex]);
  }

  @override
  Iterable<ChartDataHit> get semanticDataHits =>
      geometry.marks.map(_dataHitForMark);

  @override
  void paint(Canvas canvas, Size size) {
    _paintTracks(canvas);
    if (config.showGridLines) _paintGrid(canvas);
    _paintThresholds(canvas);
    _paintMarks(canvas);
    if (config.showScaleLabels) _paintScaleLabels(canvas);
  }

  void _paintTracks(Canvas canvas) {
    final style = series.radialBarStyle;
    final fallback = theme.gridStyle.majorColor;
    final trackColor = style.trackColor ?? fallback;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = trackColor.withValues(alpha: trackColor.a * style.trackOpacity);
    for (final mark in geometry.marks) {
      canvas.drawPath(mark.trackPath, paint);
    }
  }

  void _paintGrid(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridStyle.majorWidth
      ..color = theme.gridStyle.majorColor;
    for (var tick = 0; tick < config.tickCount; tick++) {
      final fraction = tick / (config.tickCount - 1);
      final angle = pane.angleAt(fraction);
      final start = pane.center + Offset.fromDirection(angle, pane.innerRadius);
      final end = pane.center + Offset.fromDirection(angle, pane.outerRadius);
      canvas.drawLine(start, end, paint);
    }
  }

  void _paintThresholds(Canvas canvas) {
    _debugThresholdLabelRects.clear();
    for (final threshold in config.thresholds) {
      if (threshold.value < series.minimum ||
          threshold.value > series.maximum) {
        continue;
      }
      final fraction =
          (threshold.value - series.minimum) /
          (series.maximum - series.minimum);
      final angle = pane.angleAt(fraction);
      final color = threshold.color ?? theme.focusBorderColor;
      final start = pane.center + Offset.fromDirection(angle, pane.innerRadius);
      final end = pane.center + Offset.fromDirection(angle, pane.outerRadius);
      final source = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(
        threshold.dashPattern.isEmpty
            ? source
            : createDashedPath(source, threshold.dashPattern),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = threshold.width
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      if (threshold.label case final label?) {
        final painter = _createTextPainter(
          label,
          theme.axisStyle.labelStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        );
        final rect = _centeredTextRect(
          painter,
          end + Offset.fromDirection(angle, 7 * textScaleFactor),
        );
        _debugThresholdLabelRects.add(rect);
        painter.paint(canvas, rect.topLeft);
      }
    }
  }

  void _paintMarks(Canvas canvas) {
    final style = series.radialBarStyle;
    final colors = resolvedMarkColors;
    final startGapLabels =
        config.showCategoryLabels &&
            config.categoryLabels.position ==
                RadialBarCategoryLabelPosition.startGap
        ? _startGapCategoryLabels()
        : null;
    _debugInsideDataLabelRects.clear();
    final insideLabelBlockedRects = <Rect>[
      ...?startGapLabels
          ?.where((candidate) => candidate.isVisible)
          .map((candidate) => candidate.labelRect),
      ..._debugThresholdLabelRects,
    ];
    final hasLiftedSelection =
        selectedPointIndices.isNotEmpty &&
        series.selectionStyle.effect == RadialSelectionEffect.lift;
    if (hasLiftedSelection && series.selectionStyle.backdropBlur > 0) {
      canvas.saveLayer(
        bounds,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: series.selectionStyle.backdropBlur,
            sigmaY: series.selectionStyle.backdropBlur,
          ),
      );
      for (final mark in geometry.marks) {
        if (!selectedPointIndices.contains(mark.index)) {
          _paintMark(canvas, mark, colors[mark.index], insideLabelBlockedRects);
        }
      }
      canvas.restore();
      for (final mark in geometry.marks) {
        if (selectedPointIndices.contains(mark.index)) {
          _paintMark(canvas, mark, colors[mark.index], insideLabelBlockedRects);
        }
      }
    } else {
      for (final mark in geometry.marks) {
        _paintMark(canvas, mark, colors[mark.index], insideLabelBlockedRects);
      }
    }
    if (style.showDataLabels &&
        style.dataLabels.position ==
            RadialBarDataLabelPosition.outsideCallout) {
      _paintOutsideDataLabels(canvas, colors);
    } else {
      _debugOutsideDataLabelRects.clear();
      _debugOutsideConnectorOrigins.clear();
      _debugOutsideConnectorRoutes.clear();
    }
    if (config.showCategoryLabels) {
      if (startGapLabels != null) {
        _paintStartGapCategoryLabels(canvas, startGapLabels);
      } else if (config.categoryLabels.position !=
          RadialBarCategoryLabelPosition.legacyOnTrack) {
        _paintOutsideCategoryLabels(canvas, colors);
      } else {
        _debugCategoryLabelRects.clear();
        _debugCategoryConnectorOrigins.clear();
        _debugCategoryConnectorRoutes.clear();
        _debugCategoryLabelRotations.clear();
        _debugCategoryLabelTrackAnchors.clear();
        _debugCategoryLabelAttachmentAnchors.clear();
      }
    } else {
      _debugCategoryLabelRects.clear();
      _debugCategoryConnectorOrigins.clear();
      _debugCategoryConnectorRoutes.clear();
      _debugCategoryLabelRotations.clear();
      _debugCategoryLabelTrackAnchors.clear();
      _debugCategoryLabelAttachmentAnchors.clear();
    }
  }

  void _paintMark(
    Canvas canvas,
    RadialBarMarkGeometry mark,
    Color color,
    List<Rect> insideLabelBlockedRects,
  ) {
    final style = series.radialBarStyle;
    final path = _displayPath(mark);
    if (mark.isVisible) {
      final fill = color.withValues(alpha: color.a * style.opacity);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = true
          ..color = fill
          ..shader = _markGradient(mark, color),
      );
    }
    final selected = selectedPointIndices.contains(mark.index);
    final focused = focusedPointIndices.contains(mark.index);
    if (mark.isVisible && (style.borderWidth > 0 || selected || focused)) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true
          ..strokeWidth = selected || focused
              ? math.max(2, style.borderWidth)
              : style.borderWidth
          ..color = selected || focused
              ? theme.focusBorderColor
              : (style.borderColor ?? theme.axisStyle.lineColor),
      );
    }

    if (config.showCategoryLabels &&
        config.categoryLabels.position ==
            RadialBarCategoryLabelPosition.legacyOnTrack) {
      _paintText(
        canvas,
        mark.category,
        _displayPoint(mark, mark.categoryLabelAnchor),
        _categoryLabelTextStyle(),
        center: true,
      );
    }
    if (style.showDataLabels &&
        style.dataLabels.position == RadialBarDataLabelPosition.insideEnd &&
        mark.isVisible) {
      final layout = _valueLabelLayout(
        mark,
        color,
        blockedRects: insideLabelBlockedRects,
      );
      if (layout != null) {
        final anchor = _displayPoint(mark, layout.anchor);
        final rect = Rect.fromCenter(
          center: anchor,
          width: layout.painter.width,
          height: layout.painter.height,
        );
        _debugInsideDataLabelRects.add(rect);
        insideLabelBlockedRects.add(rect);
        _paintTextPainter(canvas, layout.painter, anchor, center: true);
      }
    }
  }

  List<_RadialBarCategoryLabelCandidate>? _startGapCategoryLabels() {
    final config = this.config.categoryLabels;
    final tangent = Offset.fromDirection(
      pane.startAngle - pane.signedSweepAngle.sign * math.pi / 2,
    );
    final rotation =
        config.orientation == RadialBarCategoryLabelOrientation.followStartAngle
        ? _readableCategoryLabelRotation(pane.startAngle + math.pi / 2)
        : 0.0;
    final candidates = <_RadialBarCategoryLabelCandidate>[];
    for (final mark in geometry.marks) {
      final painter = _createTextPainter(
        mark.category,
        _categoryLabelTextStyle(),
      );
      final boxSize = _categoryLabelBoxSize(painter);
      final boundsSize = _rotatedBoundsSize(boxSize, rotation);
      final trackAnchor = _displayPoint(mark, mark.categoryLabelAnchor);
      final attachmentAnchor =
          trackAnchor + tangent * (config.offset + 2 * textScaleFactor);
      final attachment = _categoryLabelAttachment(
        boxSize,
        rotation: rotation,
        direction: tangent,
      );
      final center =
          attachmentAnchor + attachment.normal * attachment.halfExtent;
      final rect = Rect.fromCenter(
        center: center,
        width: boundsSize.width,
        height: boundsSize.height,
      );
      candidates.add(
        _RadialBarCategoryLabelCandidate(
          mark: mark,
          painter: painter,
          edge: _RadialBarLabelEdge.startGap,
          preferredCoordinate: 0,
          rotation: rotation,
          trackAnchor: trackAnchor,
          attachmentAnchor: attachmentAnchor,
        )..labelRect = rect,
      );
    }
    _thinStartGuideLabelCollisions(candidates);
    return candidates;
  }

  void _thinStartGuideLabelCollisions(
    List<_RadialBarCategoryLabelCandidate> candidates,
  ) {
    final viewport = (Offset.zero & size).deflate(2);
    final ordered = candidates.toList()
      ..sort((a, b) => b.mark.outerRadius.compareTo(a.mark.outerRadius));
    final placed = <_RadialBarCategoryLabelCandidate>[];
    for (final candidate in ordered) {
      final rect = candidate.labelRect;
      final insideViewport =
          viewport.contains(rect.topLeft) &&
          viewport.contains(rect.bottomRight);
      final overlapsLabel = placed.any(
        (other) => rect.overlaps(other.labelRect),
      );
      candidate.isVisible = insideViewport && !overlapsLabel;
      if (candidate.isVisible) placed.add(candidate);
    }
  }

  ({Offset normal, double halfExtent}) _categoryLabelAttachment(
    Size boxSize, {
    required double rotation,
    required Offset direction,
  }) {
    final horizontal = Offset.fromDirection(rotation);
    final vertical = Offset.fromDirection(rotation + math.pi / 2);
    final horizontalDot =
        direction.dx * horizontal.dx + direction.dy * horizontal.dy;
    final verticalDot = direction.dx * vertical.dx + direction.dy * vertical.dy;
    if (horizontalDot.abs() >= verticalDot.abs()) {
      return (
        normal: horizontal * (horizontalDot.isNegative ? -1.0 : 1.0),
        halfExtent: boxSize.width / 2,
      );
    }
    return (
      normal: vertical * (verticalDot.isNegative ? -1.0 : 1.0),
      halfExtent: boxSize.height / 2,
    );
  }

  void _paintStartGapCategoryLabels(
    Canvas canvas,
    List<_RadialBarCategoryLabelCandidate> candidates,
  ) {
    _debugCategoryConnectorOrigins.clear();
    _debugCategoryConnectorRoutes.clear();
    _debugCategoryLabelRotations
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.rotation),
      );
    _debugCategoryLabelTrackAnchors
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.trackAnchor),
      );
    _debugCategoryLabelAttachmentAnchors
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.attachmentAnchor),
      );
    _debugCategoryLabelRects
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.labelRect),
      );
    for (final candidate in candidates) {
      if (!candidate.isVisible) continue;
      _paintCategoryLabelBox(canvas, candidate);
    }
  }

  void _paintOutsideCategoryLabels(Canvas canvas, List<Color> colors) {
    final categoryConfig = config.categoryLabels;
    final edge = _categoryOriginLabelEdge();
    final candidates = <_RadialBarCategoryLabelCandidate>[];
    for (final mark in geometry.marks) {
      final painter = _createTextPainter(
        mark.category,
        _categoryLabelTextStyle(),
      );
      final categoryAnchor = _displayPoint(mark, mark.categoryLabelAnchor);
      final origin = _projectCategoryAnchorToPaneEdge(categoryAnchor, edge);
      candidates.add(
        _RadialBarCategoryLabelCandidate(
          mark: mark,
          painter: painter,
          edge: edge,
          preferredCoordinate: edge.isHorizontalLane ? origin.dy : origin.dx,
          trackAnchor: categoryAnchor,
          attachmentAnchor: origin,
        ),
      );
    }
    _resolveCategoryLabelLane(candidates);
    _debugCategoryLabelRects
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.labelRect),
      );
    _debugCategoryConnectorOrigins.clear();
    _debugCategoryConnectorRoutes.clear();
    _debugCategoryLabelTrackAnchors.clear();
    _debugCategoryLabelAttachmentAnchors.clear();
    _debugCategoryLabelRotations
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.rotation),
      );

    for (final candidate in candidates) {
      if (!candidate.isVisible) continue;
      final rect = candidate.labelRect;
      final categoryAnchor = _displayPoint(
        candidate.mark,
        candidate.mark.categoryLabelAnchor,
      );
      _debugCategoryConnectorOrigins.add(categoryAnchor);
      _debugCategoryLabelTrackAnchors.add(categoryAnchor);
      final labelEdge = switch (candidate.edge) {
        _RadialBarLabelEdge.left => Offset(rect.right, rect.center.dy),
        _RadialBarLabelEdge.right => Offset(rect.left, rect.center.dy),
        _RadialBarLabelEdge.top => Offset(rect.center.dx, rect.bottom),
        _RadialBarLabelEdge.bottom => Offset(rect.center.dx, rect.top),
        _RadialBarLabelEdge.startGap => rect.center,
      };
      _debugCategoryLabelAttachmentAnchors.add(labelEdge);
      if (categoryConfig.connectorWidth > 0) {
        // Category ownership begins at the owning track's shared angular
        // start. A single direct segment keeps that ownership visible instead
        // of stopping early at the generic outer-pane boundary.
        final route = <Offset>[categoryAnchor, labelEdge];
        _debugCategoryConnectorRoutes.add(List<Offset>.unmodifiable(route));
        final path = Path()
          ..moveTo(categoryAnchor.dx, categoryAnchor.dy)
          ..lineTo(labelEdge.dx, labelEdge.dy);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true
            ..strokeWidth = categoryConfig.connectorWidth + 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = theme.backgroundColor,
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true
            ..strokeWidth = categoryConfig.connectorWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color =
                categoryConfig.connectorColor ?? colors[candidate.mark.index],
        );
      }
      _paintCategoryLabelBox(canvas, candidate);
    }
  }

  _RadialBarLabelEdge _categoryOriginLabelEdge() {
    final sweepDirection = pane.signedSweepAngle.sign == 0
        ? 1.0
        : pane.signedSweepAngle.sign;
    final gapDirection = Offset.fromDirection(
      pane.startAngle - sweepDirection * math.pi / 2,
    );
    // Category names read as one ordered legend-like lane. Keeping that lane
    // vertical avoids the cramped sentence produced by top/bottom callouts.
    // Prefer the side immediately before the shared start angle; exactly
    // vertical gap directions use the start ray itself as the tie-breaker.
    final horizontalDirection = gapDirection.dx.abs() > 0.001
        ? gapDirection.dx
        : Offset.fromDirection(pane.startAngle).dx;
    return horizontalDirection < 0
        ? _RadialBarLabelEdge.left
        : _RadialBarLabelEdge.right;
  }

  Offset _projectCategoryAnchorToPaneEdge(
    Offset anchor,
    _RadialBarLabelEdge edge,
  ) {
    final relative = anchor - pane.center;
    final radiusSquared = pane.outerRadius * pane.outerRadius;
    switch (edge) {
      case _RadialBarLabelEdge.left:
      case _RadialBarLabelEdge.right:
        final y = relative.dy.clamp(-pane.outerRadius, pane.outerRadius);
        final x = math.sqrt(math.max(0, radiusSquared - y * y));
        return pane.center +
            Offset(edge == _RadialBarLabelEdge.left ? -x : x, y);
      case _RadialBarLabelEdge.top:
      case _RadialBarLabelEdge.bottom:
        final x = relative.dx.clamp(-pane.outerRadius, pane.outerRadius);
        final y = math.sqrt(math.max(0, radiusSquared - x * x));
        return pane.center +
            Offset(x, edge == _RadialBarLabelEdge.top ? -y : y);
      case _RadialBarLabelEdge.startGap:
        return anchor;
    }
  }

  void _resolveCategoryLabelLane(
    List<_RadialBarCategoryLabelCandidate> candidates, {
    double? connectorLength,
  }) {
    if (candidates.isEmpty) return;
    candidates.sort((a, b) {
      final coordinate = a.preferredCoordinate.compareTo(b.preferredCoordinate);
      return coordinate != 0
          ? coordinate
          : a.mark.index.compareTo(b.mark.index);
    });
    const edgePadding = 4.0;
    final gap = 4 * textScaleFactor;
    final edge = candidates.first.edge;
    final categoryConfig = config.categoryLabels;
    final leaderLength = connectorLength ?? categoryConfig.connectorLength;
    final scaleLabelClearance = config.showScaleLabels
        ? 8 * textScaleFactor
        : 0.0;
    var cursor = edgePadding;
    for (final candidate in candidates) {
      final boxSize = _categoryLabelBoxSize(candidate.painter);
      if (edge.isHorizontalLane) {
        final desiredTop = candidate.preferredCoordinate - boxSize.height / 2;
        final top = math.max(cursor, desiredTop);
        final requestedX = edge == _RadialBarLabelEdge.left
            ? pane.markBounds.left -
                  leaderLength -
                  categoryConfig.offset -
                  scaleLabelClearance -
                  boxSize.width
            : pane.markBounds.right +
                  leaderLength +
                  categoryConfig.offset +
                  scaleLabelClearance;
        candidate.labelRect = Rect.fromLTWH(
          requestedX
              .clamp(edgePadding, size.width - edgePadding - boxSize.width)
              .toDouble(),
          top,
          boxSize.width,
          boxSize.height,
        );
        cursor = top + boxSize.height + gap;
      } else {
        final desiredLeft = candidate.preferredCoordinate - boxSize.width / 2;
        final left = math.max(cursor, desiredLeft);
        final requestedY = edge == _RadialBarLabelEdge.top
            ? pane.markBounds.top -
                  leaderLength -
                  categoryConfig.offset -
                  scaleLabelClearance -
                  boxSize.height
            : pane.markBounds.bottom +
                  leaderLength +
                  categoryConfig.offset +
                  scaleLabelClearance;
        candidate.labelRect = Rect.fromLTWH(
          left,
          requestedY
              .clamp(edgePadding, size.height - edgePadding - boxSize.height)
              .toDouble(),
          boxSize.width,
          boxSize.height,
        );
        cursor = left + boxSize.width + gap;
      }
    }
    final last = candidates.last.labelRect;
    final overflow = edge.isHorizontalLane
        ? last.bottom - (size.height - edgePadding)
        : last.right - (size.width - edgePadding);
    if (overflow > 0) {
      final shift = edge.isHorizontalLane
          ? Offset(0, -overflow)
          : Offset(-overflow, 0);
      for (final candidate in candidates) {
        candidate.labelRect = candidate.labelRect.shift(shift);
      }
    }
    final viewport = (Offset.zero & size).deflate(edgePadding);
    for (final candidate in candidates) {
      candidate.isVisible =
          candidate.labelRect.left >= viewport.left &&
          candidate.labelRect.top >= viewport.top &&
          candidate.labelRect.right <= viewport.right &&
          candidate.labelRect.bottom <= viewport.bottom;
    }
  }

  TextStyle _categoryLabelTextStyle() {
    final fallback = theme.axisStyle.labelStyle.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final explicit = config.categoryLabels.textStyle;
    return fallback.copyWith(
      color: explicit.color ?? fallback.color,
      fontSize: explicit.fontSize ?? fallback.fontSize,
      fontWeight: explicit.fontWeight ?? fallback.fontWeight,
    );
  }

  Size _categoryLabelBoxSize(TextPainter painter) {
    if (!config.categoryLabels.showPanel) return painter.size;
    final padding =
        config.categoryLabels.panelStyle?.padding ??
        const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    return Size(
      painter.width + padding.horizontal,
      painter.height + padding.vertical,
    );
  }

  Size _rotatedBoundsSize(Size boxSize, double rotation) {
    final cosine = math.cos(rotation).abs();
    final sine = math.sin(rotation).abs();
    return Size(
      boxSize.width * cosine + boxSize.height * sine,
      boxSize.width * sine + boxSize.height * cosine,
    );
  }

  double _readableCategoryLabelRotation(double rotation) {
    var normalized = rotation % (2 * math.pi);
    if (normalized > math.pi) normalized -= 2 * math.pi;
    if (normalized <= -math.pi) normalized += 2 * math.pi;
    if (normalized > math.pi / 2) normalized -= math.pi;
    if (normalized < -math.pi / 2) normalized += math.pi;
    if (normalized.abs() < math.pi / 4) return 0;
    return normalized.isNegative ? -math.pi / 2 : math.pi / 2;
  }

  void _paintCategoryLabelBox(
    Canvas canvas,
    _RadialBarCategoryLabelCandidate candidate,
  ) {
    if (candidate.rotation == 0) {
      _paintCategoryLabelBoxAt(canvas, candidate, candidate.labelRect);
      return;
    }
    final boxSize = _categoryLabelBoxSize(candidate.painter);
    final localRect = Rect.fromCenter(
      center: Offset.zero,
      width: boxSize.width,
      height: boxSize.height,
    );
    canvas
      ..save()
      ..translate(candidate.labelRect.center.dx, candidate.labelRect.center.dy)
      ..rotate(candidate.rotation);
    _paintCategoryLabelBoxAt(canvas, candidate, localRect);
    canvas.restore();
  }

  void _paintCategoryLabelBoxAt(
    Canvas canvas,
    _RadialBarCategoryLabelCandidate candidate,
    Rect rect,
  ) {
    final categoryConfig = config.categoryLabels;
    var textOffset = rect.topLeft;
    if (categoryConfig.showPanel) {
      final style =
          categoryConfig.panelStyle ??
          LabelStyle(
            textStyle: _categoryLabelTextStyle(),
            backgroundColor: theme.backgroundColor.withValues(alpha: 0.94),
            borderColor: theme.gridStyle.majorColor,
            borderWidth: 1,
            borderRadius: 4,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(style.borderRadius),
      );
      if (style.shadowColor != null && (style.shadowBlurRadius ?? 0) > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = style.shadowColor!
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              style.shadowBlurRadius!,
            ),
        );
      }
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = style.backgroundColor,
      );
      if (style.borderWidth > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.borderWidth
            ..color = style.borderColor,
        );
      }
      textOffset += Offset(style.padding.left, style.padding.top);
    }
    candidate.painter.paint(canvas, textOffset);
  }

  ({Offset anchor, TextPainter painter})? _valueLabelLayout(
    RadialBarMarkGeometry mark,
    Color markColor, {
    List<Rect> blockedRects = const <Rect>[],
  }) {
    final config = series.radialBarStyle.dataLabels;
    final painter = _createTextPainter(
      _dataLabelText(mark),
      _dataLabelTextStyle(
        background: _effectiveMarkFill(_labelGradientColor(mark, markColor)),
        outside: false,
      ),
    );
    final middleRadius = (mark.innerRadius + mark.outerRadius) / 2;
    final trackThickness = mark.outerRadius - mark.innerRadius;
    final sweep = mark.mark.sweepAngle;
    final arcLength = sweep.abs() * middleRadius;
    final padding = textScaleFactor;
    final halfWidth = painter.width / 2;
    final halfHeight = painter.height / 2;
    final endAngle = mark.mark.startAngle + sweep;
    final direction = sweep.sign;
    final endClearance = mark.mark.cornerRadius + padding;

    double tangentExtent(double angle) =>
        math.sin(angle).abs() * halfWidth + math.cos(angle).abs() * halfHeight;
    double radialExtent(double angle) =>
        math.cos(angle).abs() * halfWidth + math.sin(angle).abs() * halfHeight;

    var inset = tangentExtent(endAngle) + endClearance + config.offset;
    if (arcLength < inset * 2) return null;
    var anchorAngle = endAngle - direction * inset / middleRadius;

    // Re-resolve against the final text orientation. Text remains horizontal,
    // so its tangent and radial extents vary around the ring.
    inset = tangentExtent(anchorAngle) + endClearance + config.offset;
    if (arcLength < inset * 2 ||
        trackThickness < (radialExtent(anchorAngle) + padding) * 2) {
      return null;
    }
    anchorAngle = endAngle - direction * inset / middleRadius;
    final availableRetreat = math.max(0, arcLength - inset * 2);
    final retreatStep = math.max(3, painter.height * 0.35);
    for (
      var retreat = 0.0;
      retreat <= availableRetreat + 0.001;
      retreat += retreatStep
    ) {
      final candidateAngle =
          endAngle - direction * (inset + retreat) / middleRadius;
      final anchor =
          pane.center + Offset.fromDirection(candidateAngle, middleRadius);
      final rect = Rect.fromCenter(
        center: anchor,
        width: painter.width,
        height: painter.height,
      );
      if (!blockedRects.any((blocked) => rect.inflate(3).overlaps(blocked))) {
        return (anchor: anchor, painter: painter);
      }
    }
    return null;
  }

  void _paintOutsideDataLabels(Canvas canvas, List<Color> colors) {
    final labelConfig = series.radialBarStyle.dataLabels;
    final panelStyle = _outsideDataLabelPanelStyle();
    final labelBackground = labelConfig.showPanel
        ? Color.alphaBlend(panelStyle.backgroundColor, theme.backgroundColor)
        : theme.backgroundColor;
    final candidates = <_RadialBarLabelCandidate>[];
    for (final mark in geometry.marks) {
      if (!mark.isVisible) continue;
      final endAngle = mark.mark.startAngle + mark.mark.sweepAngle;
      final painter = _createTextPainter(
        _dataLabelText(mark),
        _dataLabelTextStyle(background: labelBackground, outside: true),
      );
      candidates.add(
        _RadialBarLabelCandidate(
          mark: mark,
          painter: painter,
          color: colors[mark.index],
          isLeft: math.cos(endAngle) < 0,
          preferredY:
              pane.center.dy +
              math.sin(endAngle) *
                  (pane.outerRadius + labelConfig.connectorLength),
        ),
      );
    }

    final left = candidates.where((candidate) => candidate.isLeft).toList();
    final right = candidates.where((candidate) => !candidate.isLeft).toList();
    _resolveOutsideLabelLane(left);
    _resolveOutsideLabelLane(right);
    _debugOutsideDataLabelRects
      ..clear()
      ..addAll(
        candidates
            .where((candidate) => candidate.isVisible)
            .map((candidate) => candidate.labelRect),
      );
    _debugOutsideConnectorOrigins.clear();
    _debugOutsideConnectorRoutes.clear();

    for (final candidate in candidates) {
      if (!candidate.isVisible) continue;
      final rect = candidate.labelRect;
      final labelEdge = candidate.isLeft
          ? Offset(rect.right, rect.center.dy)
          : Offset(rect.left, rect.center.dy);
      final endAngle =
          candidate.mark.mark.startAngle + candidate.mark.mark.sweepAngle;
      // A callout must visibly belong to its own concentric track. Start at the
      // actual rounded mark endpoint, follow its value angle beyond the pane,
      // then adjust vertically only when collision resolution moved the label.
      // The label-facing segment is always horizontal. This retains track
      // ownership without the visually unstable diagonal lane segment.
      final origin = _displayPoint(
        candidate.mark,
        candidate.mark.valueLabelAnchor,
      );
      _debugOutsideConnectorOrigins.add(origin);
      final paneExit =
          pane.center +
          Offset.fromDirection(
            endAngle,
            pane.outerRadius + labelConfig.connectorLength,
          );
      final laneElbow = Offset(paneExit.dx, labelEdge.dy);
      final route = <Offset>[origin, paneExit, laneElbow, labelEdge];
      _debugOutsideConnectorRoutes.add(List<Offset>.unmodifiable(route));
      if (labelConfig.connectorWidth > 0) {
        final connectorPath = Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(paneExit.dx, paneExit.dy)
          ..lineTo(laneElbow.dx, laneElbow.dy)
          ..lineTo(labelEdge.dx, labelEdge.dy);
        canvas.drawPath(
          connectorPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true
            ..strokeWidth = labelConfig.connectorWidth + 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = theme.backgroundColor,
        );
        final connectorPaint = Paint()
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true
          ..strokeWidth = labelConfig.connectorWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = labelConfig.connectorColor ?? candidate.color;
        canvas.drawPath(connectorPath, connectorPaint);
        final anchorRadius = math.max(
          1.75 * textScaleFactor,
          labelConfig.connectorWidth + 0.75 * textScaleFactor,
        );
        canvas
          ..drawCircle(
            origin,
            anchorRadius + 1.5 * textScaleFactor,
            Paint()
              ..isAntiAlias = true
              ..color = theme.backgroundColor,
          )
          ..drawCircle(
            origin,
            anchorRadius,
            Paint()
              ..isAntiAlias = true
              ..color = labelConfig.connectorColor ?? candidate.color,
          );
      }
      _paintOutsideDataLabelBox(canvas, candidate, panelStyle);
    }
  }

  LabelStyle _outsideDataLabelPanelStyle() {
    final explicit = series.radialBarStyle.dataLabels.panelStyle;
    return explicit ??
        LabelStyle(
          textStyle: _dataLabelTextStyle(
            background: theme.backgroundColor,
            outside: true,
          ),
          backgroundColor: theme.backgroundColor.withValues(alpha: 0.96),
          borderColor: theme.gridStyle.majorColor,
          borderWidth: 1,
          borderRadius: 4,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        );
  }

  Size _outsideDataLabelBoxSize(TextPainter painter) {
    final labelConfig = series.radialBarStyle.dataLabels;
    if (!labelConfig.showPanel) return painter.size;
    final padding = _outsideDataLabelPanelStyle().padding;
    return Size(
      painter.width + padding.horizontal,
      painter.height + padding.vertical,
    );
  }

  void _paintOutsideDataLabelBox(
    Canvas canvas,
    _RadialBarLabelCandidate candidate,
    LabelStyle panelStyle,
  ) {
    final labelConfig = series.radialBarStyle.dataLabels;
    final rect = candidate.labelRect;
    var textOffset = Offset(
      rect.left,
      rect.center.dy - candidate.painter.height / 2,
    );
    if (labelConfig.showPanel) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(panelStyle.borderRadius),
      );
      if (panelStyle.shadowColor != null &&
          (panelStyle.shadowBlurRadius ?? 0) > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = panelStyle.shadowColor!
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              panelStyle.shadowBlurRadius!,
            ),
        );
      }
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = panelStyle.backgroundColor,
      );
      if (panelStyle.borderWidth > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = panelStyle.borderWidth
            ..color = panelStyle.borderColor,
        );
      }
      textOffset = Offset(
        rect.left + panelStyle.padding.left,
        rect.top + panelStyle.padding.top,
      );
    }
    candidate.painter.paint(canvas, textOffset);
  }

  void _resolveOutsideLabelLane(List<_RadialBarLabelCandidate> lane) {
    if (lane.isEmpty) return;
    lane.sort((a, b) {
      final vertical = a.preferredY.compareTo(b.preferredY);
      return vertical != 0 ? vertical : a.mark.index.compareTo(b.mark.index);
    });

    const edgePadding = 4.0;
    final minimumGap = 4 * textScaleFactor;
    final labelConfig = series.radialBarStyle.dataLabels;
    final isLeft = lane.first.isLeft;
    final availableHeight = math.max(0, size.height - edgePadding * 2);
    final boxSizes = <Size>[
      for (final candidate in lane) _outsideDataLabelBoxSize(candidate.painter),
    ];
    final requiredHeight =
        boxSizes.fold<double>(0, (total, box) => total + box.height) +
        minimumGap * math.max(0, lane.length - 1);
    if (requiredHeight > availableHeight) {
      final maximumBoxHeight = boxSizes.fold<double>(
        0,
        (maximum, box) => math.max(maximum, box.height),
      );
      final maximumVisible = math.max(
        1,
        ((availableHeight + minimumGap) / (maximumBoxHeight + minimumGap))
            .floor(),
      );
      final visibleIndices = <int>{};
      if (maximumVisible == 1) {
        visibleIndices.add((lane.length - 1) ~/ 2);
      } else {
        for (var index = 0; index < maximumVisible; index++) {
          visibleIndices.add(
            (index * (lane.length - 1) / (maximumVisible - 1)).round(),
          );
        }
      }
      for (final (index, candidate) in lane.indexed) {
        candidate.isVisible = visibleIndices.contains(index);
      }
    }
    final visibleLane = lane
        .where((candidate) => candidate.isVisible)
        .toList(growable: false);
    if (visibleLane.isEmpty) return;
    var nextTop = edgePadding;
    for (final candidate in visibleLane) {
      final boxSize = _outsideDataLabelBoxSize(candidate.painter);
      final desiredTop = candidate.preferredY - boxSize.height / 2;
      final top = math.max(desiredTop, nextTop);
      final requestedX = isLeft
          ? pane.markBounds.left -
                labelConfig.connectorLength -
                labelConfig.offset -
                boxSize.width
          : pane.markBounds.right +
                labelConfig.connectorLength +
                labelConfig.offset;
      final maximumX = math.max(
        edgePadding,
        size.width - edgePadding - boxSize.width,
      );
      final x = requestedX.clamp(edgePadding, maximumX).toDouble();
      candidate.labelRect = Rect.fromLTWH(
        x,
        top,
        boxSize.width,
        boxSize.height,
      );
      nextTop = top + boxSize.height + minimumGap;
    }

    final overflow =
        visibleLane.last.labelRect.bottom - (size.height - edgePadding);
    if (overflow > 0) {
      for (final candidate in visibleLane) {
        candidate.labelRect = candidate.labelRect.shift(Offset(0, -overflow));
      }
    }
    final topOverflow = edgePadding - visibleLane.first.labelRect.top;
    if (topOverflow > 0) {
      for (final candidate in visibleLane) {
        candidate.labelRect = candidate.labelRect.shift(Offset(0, topOverflow));
      }
    }
  }

  String _dataLabelText(RadialBarMarkGeometry mark) {
    final formattedValue = MultiAxisValueFormatter.format(
      value: series.points[mark.index].y,
      unit: series.unit,
    );
    return switch (series.radialBarStyle.dataLabels.content) {
      RadialBarDataLabelContent.value => formattedValue,
      RadialBarDataLabelContent.category => mark.category,
      RadialBarDataLabelContent.categoryAndValue =>
        '${mark.category} · $formattedValue',
    };
  }

  TextStyle _dataLabelTextStyle({
    required Color background,
    required bool outside,
  }) {
    final config = series.radialBarStyle.dataLabels;
    final explicit = config.textStyle;
    final fallback = theme.axisStyle.labelStyle;
    final resolvedColor =
        config.colorMode == RadialBarDataLabelColorMode.autoContrast
        ? _readableTextColor(background)
        : (explicit.color ?? fallback.color ?? const Color(0xFF374151));
    return fallback.copyWith(
      color: resolvedColor,
      fontSize: explicit.fontSize ?? fallback.fontSize ?? 10,
      fontWeight:
          explicit.fontWeight ??
          fallback.fontWeight ??
          (outside ? FontWeight.w500 : FontWeight.w700),
    );
  }

  void _paintScaleLabels(Canvas canvas) {
    _debugScaleLabelRects.clear();
    final blockedRects = <Rect>[
      ..._debugCategoryLabelRects,
      ..._debugThresholdLabelRects,
      ..._debugInsideDataLabelRects,
    ];
    final viewport = Offset.zero & size;
    for (var tick = 0; tick < config.tickCount; tick++) {
      final fraction = tick / (config.tickCount - 1);
      final value =
          series.minimum + (series.maximum - series.minimum) * fraction;
      final angle = pane.angleAt(fraction);
      final direction = Offset.fromDirection(angle);
      final painter = _createTextPainter(
        MultiAxisValueFormatter.format(value: value, unit: series.unit),
        theme.axisStyle.labelStyle.copyWith(fontSize: 9),
      );
      Rect? resolved;
      Rect? fallback;
      for (var attempt = 0; attempt <= 24; attempt++) {
        final anchor =
            pane.center +
            direction * (pane.outerRadius + 10 + attempt * 3 * textScaleFactor);
        final raw = Rect.fromCenter(
          center: anchor,
          width: painter.width,
          height: painter.height,
        );
        if (!viewport.contains(raw.topLeft) ||
            !viewport.contains(raw.bottomRight)) {
          break;
        }
        fallback ??= raw;
        if (!blockedRects.any(
          (blocked) => raw.inflate(5 * textScaleFactor).overlaps(blocked),
        )) {
          resolved = raw;
          break;
        }
      }
      final rect =
          resolved ??
          fallback ??
          _centeredTextRect(
            painter,
            pane.center + direction * (pane.outerRadius + 10),
          );
      _debugScaleLabelRects.add(rect);
      blockedRects.add(rect);
      painter.paint(canvas, rect.topLeft);
    }
  }

  Rect _centeredTextRect(TextPainter painter, Offset anchor) {
    final raw = anchor - Offset(painter.width / 2, painter.height / 2);
    return Rect.fromLTWH(
      raw.dx.clamp(0, math.max(0, size.width - painter.width)),
      raw.dy.clamp(0, math.max(0, size.height - painter.height)),
      painter.width,
      painter.height,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool center = false,
  }) {
    _paintTextPainter(
      canvas,
      _createTextPainter(text, style),
      anchor,
      center: center,
    );
  }

  TextPainter _createTextPainter(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: TextScaler.linear(textScaleFactor),
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: math.max(36, size.width * 0.24));

  void _paintTextPainter(
    Canvas canvas,
    TextPainter painter,
    Offset anchor, {
    bool center = false,
  }) {
    final raw = center
        ? anchor - Offset(painter.width / 2, painter.height / 2)
        : anchor;
    painter.paint(
      canvas,
      Offset(
        raw.dx.clamp(0, math.max(0, size.width - painter.width)),
        raw.dy.clamp(0, math.max(0, size.height - painter.height)),
      ),
    );
  }

  Color _effectiveMarkFill(Color markColor) => Color.alphaBlend(
    markColor.withValues(alpha: markColor.a * series.radialBarStyle.opacity),
    theme.backgroundColor,
  );

  ui.Shader? _markGradient(RadialBarMarkGeometry mark, Color color) {
    final gradient = series.radialBarStyle.gradient;
    if (gradient == null || !gradient.enabled) return null;
    var startColor = _gradientColor(
      color,
      gradient.startColor,
      gradient.startLightnessShift,
    );
    var endColor = _gradientColor(
      color,
      gradient.endColor,
      gradient.endLightnessShift,
    );
    final opacity = series.radialBarStyle.opacity;
    startColor = startColor.withValues(alpha: startColor.a * opacity);
    endColor = endColor.withValues(alpha: endColor.a * opacity);

    return switch (gradient.type) {
      RadialBarGradientType.sweep => _sweepMarkGradient(
        mark,
        startColor,
        endColor,
      ),
      RadialBarGradientType.radial => ui.Gradient.radial(
        pane.center,
        mark.outerRadius,
        <Color>[startColor, endColor],
        <double>[(mark.innerRadius / mark.outerRadius).clamp(0, 1), 1],
      ),
    };
  }

  ui.Shader _sweepMarkGradient(
    RadialBarMarkGeometry mark,
    Color startColor,
    Color endColor,
  ) {
    var startAngle = mark.mark.startAngle;
    var endAngle = startAngle + mark.mark.sweepAngle;
    if (endAngle < startAngle) {
      final swapAngle = startAngle;
      startAngle = endAngle;
      endAngle = swapAngle;
      final swapColor = startColor;
      startColor = endColor;
      endColor = swapColor;
    }
    while (startAngle < 0) {
      startAngle += math.pi * 2;
      endAngle += math.pi * 2;
    }
    return ui.Gradient.sweep(
      pane.center,
      <Color>[startColor, endColor],
      null,
      TileMode.clamp,
      startAngle,
      endAngle,
    );
  }

  Color _labelGradientColor(RadialBarMarkGeometry mark, Color color) {
    final gradient = series.radialBarStyle.gradient;
    if (gradient == null || !gradient.enabled) return color;
    return switch (gradient.type) {
      RadialBarGradientType.sweep => _gradientColor(
        color,
        gradient.endColor,
        gradient.endLightnessShift,
      ),
      RadialBarGradientType.radial => Color.lerp(
        _gradientColor(
          color,
          gradient.startColor,
          gradient.startLightnessShift,
        ),
        _gradientColor(color, gradient.endColor, gradient.endLightnessShift),
        0.5,
      )!,
    };
  }

  Color _gradientColor(Color base, Color? fixed, double lightnessShift) =>
      fixed ?? _shiftLightness(base, lightnessShift);

  Color _readableTextColor(Color background) {
    final preferred = theme.axisStyle.labelStyle.color;
    if (preferred != null && _contrastRatio(preferred, background) >= 4.5) {
      return preferred;
    }
    final blackRatio = _contrastRatio(Colors.black, background);
    final whiteRatio = _contrastRatio(Colors.white, background);
    return blackRatio >= whiteRatio ? Colors.black : Colors.white;
  }

  double _contrastRatio(Color foreground, Color background) {
    final composited = Color.alphaBlend(foreground, background);
    final foregroundLuminance = composited.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = math.max(foregroundLuminance, backgroundLuminance);
    final darker = math.min(foregroundLuminance, backgroundLuminance);
    return (lighter + 0.05) / (darker + 0.05);
  }

  @visibleForTesting
  ({Offset anchor, Size textSize, Color color})? debugValueLabelLayoutForPoint(
    int pointIndex,
  ) {
    if (pointIndex < 0 || pointIndex >= geometry.marks.length) return null;
    final mark = geometry.marks[pointIndex];
    final layout = _valueLabelLayout(mark, resolvedMarkColors[pointIndex]);
    if (layout == null) return null;
    return (
      anchor: layout.anchor,
      textSize: layout.painter.size,
      color: layout.painter.text?.style?.color ?? Colors.transparent,
    );
  }

  @visibleForTesting
  List<Rect> get debugOutsideDataLabelRects =>
      List<Rect>.unmodifiable(_debugOutsideDataLabelRects);

  @visibleForTesting
  List<Rect> get debugInsideDataLabelRects =>
      List<Rect>.unmodifiable(_debugInsideDataLabelRects);

  @visibleForTesting
  List<Offset> get debugOutsideConnectorOrigins =>
      List<Offset>.unmodifiable(_debugOutsideConnectorOrigins);

  @visibleForTesting
  List<List<Offset>> get debugOutsideConnectorRoutes =>
      List<List<Offset>>.unmodifiable(_debugOutsideConnectorRoutes);

  @visibleForTesting
  List<Rect> get debugCategoryLabelRects =>
      List<Rect>.unmodifiable(_debugCategoryLabelRects);

  @visibleForTesting
  List<Offset> get debugCategoryConnectorOrigins =>
      List<Offset>.unmodifiable(_debugCategoryConnectorOrigins);

  @visibleForTesting
  List<List<Offset>> get debugCategoryConnectorRoutes =>
      List<List<Offset>>.unmodifiable(_debugCategoryConnectorRoutes);

  @visibleForTesting
  List<double> get debugCategoryLabelRotations =>
      List<double>.unmodifiable(_debugCategoryLabelRotations);

  @visibleForTesting
  List<Offset> get debugCategoryLabelTrackAnchors =>
      List<Offset>.unmodifiable(_debugCategoryLabelTrackAnchors);

  @visibleForTesting
  List<Offset> get debugCategoryLabelAttachmentAnchors =>
      List<Offset>.unmodifiable(_debugCategoryLabelAttachmentAnchors);

  @visibleForTesting
  List<Rect> get debugScaleLabelRects =>
      List<Rect>.unmodifiable(_debugScaleLabelRects);

  @visibleForTesting
  List<Rect> get debugThresholdLabelRects =>
      List<Rect>.unmodifiable(_debugThresholdLabelRects);

  @visibleForTesting
  Color? get debugCategoryLabelTextColor => _categoryLabelTextStyle().color;

  ChartDataHit _dataHitForMark(RadialBarMarkGeometry mark) {
    final point = series.points[mark.index];
    final path = _displayPath(mark);
    final semanticBounds = path.getBounds();
    final semanticAnchor = _displayPoint(mark, mark.tooltipAnchor);
    final minimumSemanticRadius = math.max(
      6 * textScaleFactor,
      (mark.outerRadius - mark.innerRadius) / 2,
    );
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: mark.index,
      plotPosition: semanticAnchor,
      // A value equal to the configured baseline has no painted sweep, but it
      // is still a real category in the table, artifact, and traversal order.
      // Give that datum a stable assistive focus region at the shared baseline
      // instead of silently dropping it from the semantics tree.
      semanticBounds: semanticBounds.isEmpty
          ? Rect.fromCircle(
              center: semanticAnchor,
              radius: minimumSemanticRadius,
            )
          : semanticBounds,
      point: point,
      category: mark.category,
      formattedValue: MultiAxisValueFormatter.format(
        value: point.y,
        unit: series.unit,
      ),
      ordinal: mark.index + 1,
      count: geometry.marks.length,
      isSelected: selectedPointIndices.contains(mark.index),
      isFocused: focusedPointIndices.contains(mark.index),
    );
  }

  RadialBarMarkGeometry? _markAt(Offset position) {
    for (final mark in geometry.marks.reversed) {
      if (mark.isVisible && _displayPath(mark).contains(position)) return mark;
    }
    return null;
  }

  Matrix4? _selectionTransform(RadialBarMarkGeometry mark) {
    if (!selectedPointIndices.contains(mark.index)) return null;
    final style = series.selectionStyle;
    final angle = mark.mark.startAngle + mark.mark.sweepAngle / 2;
    final offset = Offset.fromDirection(angle, style.liftOffset);
    final scale = style.effect == RadialSelectionEffect.lift
        ? style.liftScale
        : 1.0;
    final pivot = mark.tooltipAnchor;
    return Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0, 1)
      ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
  }

  Path _displayPath(RadialBarMarkGeometry mark) {
    final transform = _selectionTransform(mark);
    final displayPath = transform == null
        ? mark.path
        : mark.path.transform(transform.storage);
    if (!config.pane.clipMarks || transform == null) return displayPath;

    // Selection lift is allowed to transform the mark beyond the resolved
    // pane. Honour the shared PolarPaneConfig contract in the same geometry
    // used by painting, hit testing, and semantics so those surfaces cannot
    // disagree about the visible selected shape.
    final panePath = AnnularSectorGeometry(
      center: pane.center,
      innerRadius: pane.innerRadius,
      outerRadius: pane.outerRadius,
      startAngle: pane.startAngle,
      sweepAngle: pane.signedSweepAngle,
    ).path;
    return Path.combine(PathOperation.intersect, displayPath, panePath);
  }

  Offset _displayPoint(RadialBarMarkGeometry mark, Offset point) {
    final transform = _selectionTransform(mark);
    if (transform == null) return point;
    final values = transform.storage;
    return Offset(
      values[0] * point.dx + values[4] * point.dy + values[12],
      values[1] * point.dx + values[5] * point.dy + values[13],
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
  RadialBarSeriesElement copyWith({bool? isHovered, bool? isSelected}) =>
      RadialBarSeriesElement(
        series: series,
        config: config,
        size: size,
        theme: theme,
        seriesIndex: seriesIndex,
        focusedPointIndices: focusedPointIndices,
        selectedPointIndices: selectedPointIndices,
        revealProgress: revealProgress,
        textScaleFactor: textScaleFactor,
        textDirection: textDirection,
        isHovered: isHovered ?? this.isHovered,
        isSelected: isSelected ?? this.isSelected,
      );
}

Color _shiftLightness(Color color, double shift) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + shift).clamp(0.0, 1.0))
      .toColor()
      .withValues(alpha: color.a);
}

class _RadialBarLabelCandidate {
  _RadialBarLabelCandidate({
    required this.mark,
    required this.painter,
    required this.color,
    required this.isLeft,
    required this.preferredY,
  });

  final RadialBarMarkGeometry mark;
  final TextPainter painter;
  final Color color;
  final bool isLeft;
  final double preferredY;
  late Rect labelRect;
  bool isVisible = true;
}

enum _RadialBarLabelEdge {
  left,
  right,
  top,
  bottom,
  startGap;

  bool get isHorizontalLane => this == left || this == right;
}

class _RadialBarCategoryLabelCandidate {
  _RadialBarCategoryLabelCandidate({
    required this.mark,
    required this.painter,
    required this.edge,
    required this.preferredCoordinate,
    required this.trackAnchor,
    required this.attachmentAnchor,
    this.rotation = 0,
  });

  final RadialBarMarkGeometry mark;
  final TextPainter painter;
  final _RadialBarLabelEdge edge;
  final double preferredCoordinate;
  final Offset trackAnchor;
  final Offset attachmentAnchor;
  final double rotation;
  late Rect labelRect;
  bool isVisible = true;
}
