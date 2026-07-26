import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatting/multi_axis_value_formatter.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../layout/gauge_geometry.dart';
import '../layout/radial_pane_geometry.dart';
import '../models/chart_theme.dart';
import '../models/gauge_chart_config.dart';
import '../models/gauge_chart_series.dart';
import '../models/polar_chart_config.dart';
import '../utils/dashed_path.dart';

/// Paints and resolves interaction for one needle or solid Gauge measurement.
class GaugeSeriesElement implements DataHitElement {
  factory GaugeSeriesElement({
    required GaugeChartSeries series,
    required GaugeChartConfig config,
    required Size size,
    required ChartTheme theme,
    int seriesIndex = 0,
    Set<int> focusedPointIndices = const <int>{},
    double revealProgress = 1,
    double textScaleFactor = 1,
    TextDirection textDirection = TextDirection.ltr,
    bool isSelected = false,
    bool isHovered = false,
    bool paintCenterContent = true,
    bool highContrast = false,
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
      viewportInsets: EdgeInsets.all(14 * textScaleFactor),
      reservedLabelInsets: config.showTickLabels
          ? EdgeInsets.all(
              math.min(22 * textScaleFactor, size.shortestSide * 0.1),
            )
          : EdgeInsets.zero,
      innerRadiusFactor: paneConfig.innerRadiusFactor,
      outerRadiusFactor: paneConfig.outerRadiusFactor,
      startAngle: paneConfig.startAngleDegrees * math.pi / 180,
      sweepAngle: paneConfig.sweepAngleDegrees * math.pi / 180,
      clockwise: paneConfig.clockwise,
    );
    final animatedValue =
        series.minimum + (series.value - series.minimum) * revealProgress;
    final geometry = GaugeGeometryCalculator.calculate(
      pane: pane,
      minimum: series.minimum,
      maximum: series.maximum,
      value: animatedValue,
      style: series.indicatorStyle,
      zones: series.zones,
      target: series.target,
      thresholds: series.thresholds,
      tickCount: config.tickCount,
    );
    return GaugeSeriesElement._(
      series: series,
      config: config,
      size: size,
      theme: theme,
      seriesIndex: seriesIndex,
      focusedPointIndices: focusedPointIndices,
      revealProgress: revealProgress,
      textScaleFactor: textScaleFactor,
      textDirection: textDirection,
      pane: pane,
      geometry: geometry,
      isSelected: isSelected,
      isHovered: isHovered,
      paintCenterContent: paintCenterContent,
      highContrast: highContrast,
    );
  }

  const GaugeSeriesElement._({
    required this.series,
    required this.config,
    required this.size,
    required this.theme,
    required this.seriesIndex,
    required this.focusedPointIndices,
    required this.revealProgress,
    required this.textScaleFactor,
    required this.textDirection,
    required this.pane,
    required this.geometry,
    required this.isSelected,
    required this.isHovered,
    required this.paintCenterContent,
    required this.highContrast,
  });

  @override
  final GaugeChartSeries series;
  final GaugeChartConfig config;
  final Size size;
  final ChartTheme theme;
  @override
  final int seriesIndex;
  final Set<int> focusedPointIndices;
  final double revealProgress;
  final double textScaleFactor;
  final TextDirection textDirection;
  final RadialPaneGeometry pane;
  final GaugeGeometry geometry;

  @override
  final bool isSelected;
  @override
  final bool isHovered;
  final bool paintCenterContent;
  final bool highContrast;
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
  int get pointCount => 1;
  @override
  bool get isSelectable => false;
  @override
  bool get isDraggable => false;

  Color get resolvedIndicatorColor {
    if (config.colorIndicatorByActiveZone) {
      final active = series.activeZone?.color;
      if (active != null) return active;
    }
    return series.color ??
        theme.seriesTheme.colors[seriesIndex % theme.seriesTheme.colors.length];
  }

  @override
  bool hitTest(Offset position) => geometry.hitTest(position);

  @override
  ChartDataHit? dataHitAt(Offset position, {double maxDistance = 20}) =>
      geometry.hitTest(position) ||
          (position - geometry.tooltipAnchor).distance <= maxDistance
      ? _dataHit()
      : null;

  @override
  ChartDataHit? dataHitForPointIndex(int pointIndex) =>
      pointIndex == 0 ? _dataHit() : null;

  @override
  Iterable<ChartDataHit> get semanticDataHits sync* {
    yield _dataHit();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (config.showAxis) _paintAxis(canvas);
    if (config.showZones) _paintZones(canvas);
    if (config.showTicks) _paintTicks(canvas);
    _paintReferences(canvas);
    _paintIndicator(canvas);
    if (paintCenterContent) _paintCenterContent(canvas);
  }

  void _paintAxis(Canvas canvas) {
    final color = switch (series.indicatorStyle) {
      NeedleGaugeStyle(:final axisColor, :final axisOpacity) =>
        (axisColor ?? theme.gridStyle.majorColor).withValues(
          alpha: (axisColor ?? theme.gridStyle.majorColor).a * axisOpacity,
        ),
      SolidGaugeStyle(:final trackColor, :final trackOpacity) =>
        (trackColor ?? theme.gridStyle.majorColor).withValues(
          alpha: (trackColor ?? theme.gridStyle.majorColor).a * trackOpacity,
        ),
    };
    canvas.drawPath(
      geometry.axis.path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  void _paintZones(Canvas canvas) {
    for (final (index, zoneGeometry) in geometry.zones.indexed) {
      final fallback =
          theme.seriesTheme.colors[index % theme.seriesTheme.colors.length];
      final source = zoneGeometry.zone.color ?? fallback;
      final alpha = series.indicatorStyle is NeedleGaugeStyle ? 0.58 : 0.34;
      canvas.drawPath(
        zoneGeometry.sector.path,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = source.withValues(alpha: source.a * alpha),
      );
      if (highContrast) {
        canvas.drawPath(
          zoneGeometry.sector.path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.5, theme.axisStyle.lineWidth)
            ..color = theme.axisStyle.lineColor,
        );
      }
    }
  }

  void _paintTicks(Canvas canvas) {
    final tickPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, theme.axisStyle.lineWidth)
      ..color = theme.axisStyle.lineColor;
    for (final tick in geometry.ticks) {
      canvas.drawLine(tick.innerPoint, tick.outerPoint, tickPaint);
      if (config.showTickLabels) {
        _paintText(
          canvas,
          MultiAxisValueFormatter.format(value: tick.value, unit: series.unit),
          tick.labelAnchor,
          theme.axisStyle.labelStyle.copyWith(fontSize: 9),
          center: true,
          maxWidth: 72,
        );
      }
    }
  }

  void _paintReferences(Canvas canvas) {
    if (geometry.target case final target?) {
      final source = series.target!;
      final color = source.color ?? theme.focusBorderColor;
      _paintReference(canvas, target, color: color, width: source.width);
    }
    for (final (index, threshold) in geometry.thresholds.indexed) {
      final source = series.thresholds[index];
      final color = source.color ?? theme.axisStyle.lineColor;
      _paintReference(
        canvas,
        threshold,
        color: color,
        width: source.width,
        dashPattern: source.dashPattern,
      );
    }
  }

  void _paintReference(
    Canvas canvas,
    GaugeReferenceGeometry reference, {
    required Color color,
    required double width,
    List<double> dashPattern = const <double>[],
  }) {
    final source = Path()
      ..moveTo(reference.innerPoint.dx, reference.innerPoint.dy)
      ..lineTo(reference.outerPoint.dx, reference.outerPoint.dy);
    canvas.drawPath(
      dashPattern.isEmpty ? source : createDashedPath(source, dashPattern),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color,
    );
    if (reference.label case final label?) {
      _paintText(
        canvas,
        label,
        reference.outerPoint +
            Offset.fromDirection(reference.angle, 8 * textScaleFactor),
        theme.axisStyle.labelStyle.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        center: true,
        maxWidth: 100,
      );
    }
  }

  void _paintIndicator(Canvas canvas) {
    final color = resolvedIndicatorColor;
    switch (series.indicatorStyle) {
      case final NeedleGaugeStyle style:
        final needle = geometry.needle!;
        canvas.drawPath(
          needle.visualPath,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = style.needleColor ?? color,
        );
        final pivotColor = style.pivotColor ?? color;
        canvas.drawCircle(
          pane.center,
          style.pivotRadius,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = pivotColor,
        );
      case SolidGaugeStyle():
        final solid = geometry.solid!;
        final style = series.indicatorStyle as SolidGaugeStyle;
        canvas.drawPath(
          solid.progress.path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = color.withValues(alpha: color.a * style.opacity),
        );
        if (style.borderWidth > 0) {
          canvas.drawPath(
            solid.progress.path,
            Paint()
              ..isAntiAlias = true
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.borderWidth
              ..color = style.borderColor ?? theme.axisStyle.lineColor,
          );
        }
    }
    if (isHovered || focusedPointIndices.contains(0)) {
      final focusPath =
          geometry.needle?.hitPath ?? geometry.solid!.progress.path;
      canvas.drawPath(
        focusPath,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = theme.focusBorderColor,
      );
    }
  }

  void _paintCenterContent(Canvas canvas) {
    final lines = <(String, PolarLabelStyle, FontWeight)>[];
    if (config.center.showMetric) {
      lines.add((series.metric, config.center.metricStyle, FontWeight.w600));
    }
    if (config.center.showValue) {
      lines.add((
        MultiAxisValueFormatter.format(
          value: geometry.value,
          unit: series.unit,
        ),
        config.center.valueStyle,
        FontWeight.w800,
      ));
    }
    final target = series.target;
    if (config.center.showTarget && target != null) {
      final formatted = MultiAxisValueFormatter.format(
        value: target.value,
        unit: series.unit,
      );
      lines.add((
        target.label == null
            ? 'Target $formatted'
            : '${target.label} $formatted',
        config.center.targetStyle,
        FontWeight.w600,
      ));
    }
    final status = series.status;
    if (config.center.showStatus && status != null) {
      lines.add((status, config.center.statusStyle, FontWeight.w600));
    }
    if (lines.isEmpty) return;
    final painters = <TextPainter>[
      for (final (text, style, fallbackWeight) in lines)
        TextPainter(
          text: TextSpan(
            text: text,
            style: theme.axisStyle.labelStyle.copyWith(
              color: style.color,
              fontSize: style.fontSize,
              fontWeight: style.fontWeight ?? fallbackWeight,
            ),
          ),
          textDirection: textDirection,
          textScaler: TextScaler.linear(textScaleFactor),
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: math.max(64, geometry.centerBounds.width)),
    ];
    final spacing = 3 * textScaleFactor;
    final height =
        painters.fold<double>(0, (sum, painter) => sum + painter.height) +
        spacing * math.max(0, painters.length - 1);
    var y = pane.center.dy - height / 2;
    for (final painter in painters) {
      painter.paint(canvas, Offset(pane.center.dx - painter.width / 2, y));
      y += painter.height + spacing;
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool center = false,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: TextScaler.linear(textScaleFactor),
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(36, maxWidth));
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

  ChartDataHit _dataHit() {
    final semanticBounds =
        geometry.needle?.hitPath.getBounds() ?? geometry.solid!.progress.bounds;
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: 0,
      plotPosition: geometry.tooltipAnchor,
      semanticBounds: semanticBounds,
      point: series.points.single,
      category: series.metric,
      formattedValue: MultiAxisValueFormatter.format(
        value: series.value,
        unit: series.unit,
      ),
      semanticLabelOverride: _semanticLabel,
      isActivatable: false,
      ordinal: 1,
      count: 1,
      isFocused: focusedPointIndices.contains(0),
    );
  }

  String get _semanticLabel {
    String format(double value) =>
        MultiAxisValueFormatter.format(value: value, unit: series.unit);
    final parts = <String>[
      series.metric,
      format(series.value),
      'range ${format(series.minimum)} to ${format(series.maximum)}',
      ?series.status,
      if (series.target case final target?)
        '${target.label ?? 'target'} ${format(target.value)}',
    ];
    return parts.join(', ');
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
  GaugeSeriesElement copyWith({bool? isHovered, bool? isSelected}) =>
      GaugeSeriesElement(
        series: series,
        config: config,
        size: size,
        theme: theme,
        seriesIndex: seriesIndex,
        focusedPointIndices: focusedPointIndices,
        revealProgress: revealProgress,
        textScaleFactor: textScaleFactor,
        textDirection: textDirection,
        isHovered: isHovered ?? this.isHovered,
        isSelected: isSelected ?? this.isSelected,
        paintCenterContent: paintCenterContent,
        highContrast: highContrast,
      );
}
