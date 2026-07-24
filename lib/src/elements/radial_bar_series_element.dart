import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatting/multi_axis_value_formatter.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../layout/radial_bar_geometry.dart';
import '../layout/radial_pane_geometry.dart';
import '../models/chart_theme.dart';
import '../models/radial_bar_chart_config.dart';
import '../models/radial_bar_chart_series.dart';
import '../models/radial_selection_style.dart';
import '../utils/dashed_path.dart';

/// Track, guide, label, and interaction element for Radial Bar V1.
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
    final pane = RadialPaneGeometry.resolve(
      viewportBounds: Offset.zero & size,
      viewportInsets: EdgeInsets.all(12 * textScaleFactor),
      reservedLabelInsets: config.showScaleLabels
          ? EdgeInsets.all(
              math.min(18 * textScaleFactor, size.shortestSide * 0.08),
            )
          : EdgeInsets.zero,
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

  const RadialBarSeriesElement._({
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
      geometry.marks.where((mark) => mark.isVisible).map(_dataHitForMark);

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
        _paintText(
          canvas,
          label,
          end + Offset.fromDirection(angle, 7 * textScaleFactor),
          theme.axisStyle.labelStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          center: true,
        );
      }
    }
  }

  void _paintMarks(Canvas canvas) {
    final style = series.radialBarStyle;
    final colors = resolvedMarkColors;
    for (final mark in geometry.marks) {
      final color = colors[mark.index];
      final path = _displayPath(mark);
      if (mark.isVisible) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..isAntiAlias = true
            ..color = color.withValues(alpha: color.a * style.opacity),
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

      if (config.showCategoryLabels) {
        _paintText(
          canvas,
          mark.category,
          _displayPoint(mark, mark.categoryLabelAnchor),
          theme.axisStyle.labelStyle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          center: true,
        );
      }
      if (style.showDataLabels && mark.isVisible) {
        final arcLength =
            mark.mark.sweepAngle.abs() *
            ((mark.innerRadius + mark.outerRadius) / 2);
        if (arcLength >= 30 * textScaleFactor) {
          _paintText(
            canvas,
            MultiAxisValueFormatter.format(
              value: series.points[mark.index].y,
              unit: series.unit,
            ),
            _displayPoint(mark, mark.valueLabelAnchor),
            theme.axisStyle.labelStyle.copyWith(
              color: _contrastingTextColor(color),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            center: true,
          );
        }
      }
    }
  }

  void _paintScaleLabels(Canvas canvas) {
    for (var tick = 0; tick < config.tickCount; tick++) {
      final fraction = tick / (config.tickCount - 1);
      final value =
          series.minimum + (series.maximum - series.minimum) * fraction;
      final angle = pane.angleAt(fraction);
      final anchor =
          pane.center + Offset.fromDirection(angle, pane.outerRadius + 10);
      _paintText(
        canvas,
        MultiAxisValueFormatter.format(value: value, unit: series.unit),
        anchor,
        theme.axisStyle.labelStyle.copyWith(fontSize: 9),
        center: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: TextScaler.linear(textScaleFactor),
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(36, size.width * 0.24));
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

  Color _contrastingTextColor(Color background) =>
      background.computeLuminance() > 0.45 ? Colors.black : Colors.white;

  ChartDataHit _dataHitForMark(RadialBarMarkGeometry mark) {
    final point = series.points[mark.index];
    final path = _displayPath(mark);
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: mark.index,
      plotPosition: _displayPoint(mark, mark.tooltipAnchor),
      semanticBounds: path.getBounds(),
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
    return transform == null
        ? mark.path
        : mark.path.transform(transform.storage);
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
