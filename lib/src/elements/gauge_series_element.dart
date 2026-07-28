import 'dart:math' as math;
import 'dart:ui' as ui;

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

class _GaugeTextLayout {
  const _GaugeTextLayout({
    required this.index,
    required this.painter,
    required this.rect,
  });

  final int index;
  final TextPainter painter;
  final Rect rect;
}

class _GaugeReferencePaintEntry {
  const _GaugeReferencePaintEntry({
    required this.geometry,
    required this.color,
    required this.width,
    required this.dashPattern,
  });

  final GaugeReferenceGeometry geometry;
  final Color color;
  final double width;
  final List<double> dashPattern;
}

class _GaugeReferenceLabelLayout {
  const _GaugeReferenceLabelLayout({
    required this.painter,
    required this.rect,
    required this.style,
  });

  final TextPainter painter;
  final Rect rect;
  final GaugeReferenceStyle style;
}

enum _GaugeCenterLineKind { metric, value, target, status }

const double _minimumReadableCenterScale = 0.8;

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
    final signedSweepAngle =
        paneConfig.sweepAngleDegrees *
        math.pi /
        180 *
        (paneConfig.clockwise ? 1 : -1);
    final startAngle = paneConfig.startAngleDegrees * math.pi / 180;
    double radialTextExtent(
      String text,
      TextStyle style,
      double maxWidth,
      double angle, {
      double padding = 0,
    }) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        textScaler: TextScaler.linear(textScaleFactor),
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(36, maxWidth));
      final width = painter.width + padding * 2;
      final height = painter.height + padding * 2;
      return math.cos(angle).abs() * width / 2 +
          math.sin(angle).abs() * height / 2;
    }

    final scaleTextStyle = theme.axisStyle.labelStyle.copyWith(
      color: config.scale.labelStyle.color,
      fontSize: config.scale.labelStyle.fontSize,
      fontWeight: config.scale.labelStyle.fontWeight,
    );
    var maximumScaleLabelExtent = 0.0;
    if (config.showTickLabels) {
      for (var index = 0; index < config.tickCount; index++) {
        final fraction = index / (config.tickCount - 1);
        maximumScaleLabelExtent = math.max(
          maximumScaleLabelExtent,
          radialTextExtent(
            MultiAxisValueFormatter.format(
              value:
                  series.minimum + (series.maximum - series.minimum) * fraction,
              unit: series.unit,
            ),
            scaleTextStyle,
            config.scale.labelMaxWidth,
            startAngle + signedSweepAngle * fraction,
          ),
        );
      }
    }
    final majorTickLength =
        config.scale.tickLength ?? theme.axisStyle.tickLength;
    final outwardTickExtent = switch (config.scale.tickPosition) {
      GaugeTickPosition.inside => 0.0,
      GaugeTickPosition.centered => majorTickLength * 0.4,
      GaugeTickPosition.outside => majorTickLength,
    };
    final scaleLabelReserve = config.showTickLabels
        ? config.scale.labelPosition == GaugeScaleLabelPosition.outside
              ? outwardTickExtent +
                    config.scale.labelOffset * textScaleFactor +
                    maximumScaleLabelExtent
              : outwardTickExtent
        : 0.0;
    final hasReferenceLabels =
        config.references.showLabels &&
        ((series.target?.label?.isNotEmpty ?? false) ||
            series.thresholds.any(
              (threshold) => threshold.label?.isNotEmpty ?? false,
            ));
    final referenceTextStyle = theme.axisStyle.labelStyle.copyWith(
      fontSize: config.references.labelStyle.fontSize,
      fontWeight: config.references.labelStyle.fontWeight,
    );
    var maximumReferenceLabelExtent = 0.0;
    if (hasReferenceLabels) {
      final references = <(double, String)>[
        if (series.target case final target?)
          if (target.label case final label?)
            if (label.isNotEmpty) (target.value, label),
        for (final threshold in series.thresholds)
          if (threshold.label case final label?)
            if (label.isNotEmpty) (threshold.value, label),
      ];
      for (final (value, label) in references) {
        final fraction =
            (value - series.minimum) / (series.maximum - series.minimum);
        maximumReferenceLabelExtent = math.max(
          maximumReferenceLabelExtent,
          radialTextExtent(
            label,
            referenceTextStyle,
            config.references.labelMaxWidth,
            startAngle + signedSweepAngle * fraction,
            padding: config.references.showLabelPanel
                ? config.references.panelPadding * textScaleFactor
                : 0,
          ),
        );
      }
    }
    final referenceLabelReserve = hasReferenceLabels
        ? config.references.outerLineOffset +
              config.references.labelOffset * textScaleFactor +
              maximumReferenceLabelExtent
        : 0.0;
    final reservedLabelExtent = math.max(
      config.showTickLabels ? 22.0 * textScaleFactor : 0.0,
      math.max(scaleLabelReserve, referenceLabelReserve),
    );
    final resolvedLabelReserve = reservedLabelExtent > 0
        ? math.min(reservedLabelExtent, size.shortestSide * 0.24)
        : 0.0;
    var effectiveInnerRadiusFactor = paneConfig.innerRadiusFactor;
    var effectiveOuterRadiusFactor = paneConfig.outerRadiusFactor;

    // Preserve a readable value before optional center lines are shed. For a
    // Solid Gauge the opening may grow inward; for a Needle Gauge the outer
    // axis may use more of the already label-safe pane. The authored radius
    // factors remain minimums unless accessibility text needs more room.
    if (paintCenterContent && config.center.showValue) {
      final valueStyle = theme.axisStyle.labelStyle.copyWith(
        color: config.center.valueStyle.color,
        fontSize: config.center.valueStyle.fontSize,
        fontWeight: config.center.valueStyle.fontWeight ?? FontWeight.w800,
      );
      final valuePainters = <TextPainter>[
        for (final value in {series.minimum, series.value, series.maximum})
          TextPainter(
            text: TextSpan(
              text: MultiAxisValueFormatter.format(
                value: value,
                unit: series.unit,
              ),
              style: valueStyle,
            ),
            textDirection: textDirection,
            textScaler: TextScaler.linear(textScaleFactor),
            maxLines: 1,
          )..layout(),
      ];
      final maximumValueWidth = valuePainters.fold<double>(
        0,
        (width, painter) => math.max(width, painter.width),
      );
      final maximumValueHeight = valuePainters.fold<double>(
        0,
        (height, painter) => math.max(height, painter.height),
      );
      final centerOffset =
          Offset(config.center.horizontalOffset, config.center.verticalOffset) *
          textScaleFactor;
      final requiredCenterRadius = Offset(
        centerOffset.dx.abs() +
            maximumValueWidth * _minimumReadableCenterScale / 2,
        centerOffset.dy.abs() +
            maximumValueHeight * _minimumReadableCenterScale / 2,
      ).distance;
      final availableOuterRadius =
          (size.shortestSide -
              2 * (14 * textScaleFactor + resolvedLabelReserve)) /
          2;
      if (availableOuterRadius > 0) {
        switch (series.indicatorStyle) {
          case final NeedleGaugeStyle style:
            effectiveOuterRadiusFactor = math.min(
              1,
              math.max(
                effectiveOuterRadiusFactor,
                (requiredCenterRadius + style.axisThickness + 8) /
                    availableOuterRadius,
              ),
            );
          case SolidGaugeStyle():
            final minimumTrackFactor = 8 / availableOuterRadius;
            final maximumInnerRadiusFactor = math.max(
              effectiveInnerRadiusFactor,
              effectiveOuterRadiusFactor - minimumTrackFactor,
            );
            effectiveInnerRadiusFactor = math.min(
              maximumInnerRadiusFactor,
              math.max(
                effectiveInnerRadiusFactor,
                (requiredCenterRadius + 8) / availableOuterRadius,
              ),
            );
        }
      }
    }
    final pane = RadialPaneGeometry.resolve(
      viewportBounds: Offset.zero & size,
      viewportInsets: EdgeInsets.all(14 * textScaleFactor),
      reservedLabelInsets: resolvedLabelReserve > 0
          ? EdgeInsets.all(resolvedLabelReserve)
          : EdgeInsets.zero,
      innerRadiusFactor: effectiveInnerRadiusFactor,
      outerRadiusFactor: effectiveOuterRadiusFactor,
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
      tickLength: config.scale.tickLength ?? theme.axisStyle.tickLength,
      minorTicksPerInterval: config.minorTicksPerInterval,
      minorTickLength: config.scale.minorTickLength,
      tickPosition: config.scale.tickPosition,
      labelPosition: config.scale.labelPosition,
      tickLabelOffset: config.scale.labelOffset * textScaleFactor,
      zoneGap: config.zones.gap,
      zoneCornerRadius: config.zones.cornerRadius,
      referenceInnerOffset: config.references.innerLineOffset,
      referenceOuterOffset: config.references.outerLineOffset,
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
    if (config.showTicks || config.showTickLabels) _paintTicks(canvas);
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
      final alpha =
          config.zones.opacity ??
          (series.indicatorStyle is NeedleGaugeStyle ? 0.58 : 0.34);
      canvas.drawPath(
        zoneGeometry.sector.path,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = source.withValues(alpha: source.a * alpha),
      );
      final borderWidth = highContrast
          ? math.max(
              math.max(config.zones.borderWidth, 1.5),
              theme.axisStyle.lineWidth,
            )
          : config.zones.borderWidth;
      if (borderWidth > 0) {
        canvas.drawPath(
          zoneGeometry.sector.path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth
            ..color =
                config.zones.borderColor ??
                (highContrast ? theme.axisStyle.lineColor : source),
        );
      }
    }
  }

  void _paintTicks(Canvas canvas) {
    final scale = config.scale;
    final majorTickPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scale.tickWidth ?? theme.axisStyle.tickWidth
      ..color = scale.tickColor ?? theme.axisStyle.tickColor;
    final minorTickPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scale.minorTickWidth
      ..color =
          scale.minorTickColor ??
          (scale.tickColor ?? theme.axisStyle.tickColor).withValues(
            alpha: 0.55,
          );
    final paintedTickPoints = <Offset>[];
    for (final tick in geometry.ticks) {
      final coincidesWithPaintedTick = paintedTickPoints.any(
        (point) => (tick.outerPoint - point).distance < 0.5,
      );
      if (config.showTicks && !coincidesWithPaintedTick) {
        canvas.drawLine(
          tick.innerPoint,
          tick.outerPoint,
          tick.isMajor ? majorTickPaint : minorTickPaint,
        );
        paintedTickPoints.add(tick.outerPoint);
      }
    }
    if (config.showTickLabels) {
      final referenceLabels = _resolvedReferenceLabels();
      for (final label in _resolvedTickLabels(
        blockers: referenceLabels.map((label) => label.rect),
      )) {
        label.painter.paint(canvas, label.rect.topLeft);
      }
    }
  }

  void _paintReferences(Canvas canvas) {
    for (final entry in _referenceEntries()) {
      _paintReferenceLine(canvas, entry);
    }
    for (final label in _resolvedReferenceLabels()) {
      if (label.style.showLabelPanel) {
        _paintResolvedReferencePanel(canvas, label);
      } else {
        label.painter.paint(canvas, label.rect.topLeft);
      }
    }
  }

  void _paintReferenceLine(Canvas canvas, _GaugeReferencePaintEntry entry) {
    final reference = entry.geometry;
    final source = Path()
      ..moveTo(reference.innerPoint.dx, reference.innerPoint.dy)
      ..lineTo(reference.outerPoint.dx, reference.outerPoint.dy);
    canvas.drawPath(
      entry.dashPattern.isEmpty
          ? source
          : createDashedPath(source, entry.dashPattern),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = entry.width
        ..color = entry.color,
    );
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
        if (style.pivotBorderWidth > 0) {
          canvas.drawCircle(
            pane.center,
            style.pivotRadius,
            Paint()
              ..isAntiAlias = true
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.pivotBorderWidth
              ..color = style.pivotBorderColor ?? theme.axisStyle.lineColor,
          );
        }
        if (highContrast) {
          final outline = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.5, theme.axisStyle.lineWidth)
            ..color = theme.axisStyle.lineColor;
          canvas
            ..drawPath(needle.visualPath, outline)
            ..drawCircle(pane.center, style.pivotRadius, outline);
        }
      case SolidGaugeStyle():
        final solid = geometry.solid!;
        final style = series.indicatorStyle as SolidGaugeStyle;
        final gradient = _solidGradient(style, color);
        canvas.drawPath(
          solid.progress.path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = gradient == null
                ? color.withValues(alpha: color.a * style.opacity)
                : Colors.white
            ..shader = gradient,
        );
        final borderWidth = highContrast
            ? math.max(
                1.5,
                math.max(style.borderWidth, theme.axisStyle.lineWidth),
              )
            : style.borderWidth;
        if (borderWidth > 0) {
          canvas.drawPath(
            solid.progress.path,
            Paint()
              ..isAntiAlias = true
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderWidth
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

  ui.Shader? _solidGradient(SolidGaugeStyle style, Color color) {
    final gradient = style.gradient;
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
    startColor = startColor.withValues(alpha: startColor.a * style.opacity);
    endColor = endColor.withValues(alpha: endColor.a * style.opacity);
    final progress = geometry.solid!.progress;
    return switch (gradient.type) {
      GaugeGradientType.sweep => _sweepGradient(
        progress.startAngle,
        progress.sweepAngle,
        startColor,
        endColor,
      ),
      GaugeGradientType.radial => ui.Gradient.radial(
        pane.center,
        progress.outerRadius,
        <Color>[startColor, endColor],
        <double>[(progress.innerRadius / progress.outerRadius).clamp(0, 1), 1],
      ),
    };
  }

  ui.Shader _sweepGradient(
    double rawStartAngle,
    double rawSweepAngle,
    Color startColor,
    Color endColor,
  ) {
    var startAngle = rawStartAngle;
    var endAngle = startAngle + rawSweepAngle;
    if (endAngle < startAngle) {
      final angle = startAngle;
      startAngle = endAngle;
      endAngle = angle;
      final color = startColor;
      startColor = endColor;
      endColor = color;
    }
    while (startAngle < 0) {
      startAngle += math.pi * 2;
      endAngle += math.pi * 2;
    }
    // Entrance animation begins at an exact zero-length sweep. Flutter's
    // native sweep shader requires a strictly increasing angular interval even
    // though the arc itself paints no visible pixels at that frame.
    if (endAngle - startAngle < 1e-9) {
      endAngle = startAngle + 1e-9;
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

  Color _gradientColor(Color base, Color? fixed, double lightnessShift) =>
      fixed ?? _shiftLightness(base, lightnessShift);

  Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  ({
    List<TextPainter> painters,
    List<_GaugeCenterLineKind> kinds,
    double height,
    double scale,
    Offset centerOffset,
    double spacing,
  })?
  _resolveCenterContentLayout() {
    final lines =
        <(String, PolarLabelStyle, FontWeight, _GaugeCenterLineKind)>[];
    if (config.center.showMetric) {
      lines.add((
        series.metric,
        config.center.metricStyle,
        FontWeight.w600,
        _GaugeCenterLineKind.metric,
      ));
    }
    if (config.center.showValue) {
      lines.add((
        MultiAxisValueFormatter.format(
          value: geometry.value,
          unit: series.unit,
        ),
        config.center.valueStyle,
        FontWeight.w800,
        _GaugeCenterLineKind.value,
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
        _GaugeCenterLineKind.target,
      ));
    }
    final status = series.status;
    if (config.center.showStatus && status != null) {
      lines.add((
        status,
        config.center.statusStyle,
        FontWeight.w600,
        _GaugeCenterLineKind.status,
      ));
    }
    if (lines.isEmpty) return null;
    final availableDiameter = geometry.centerBounds.width;
    List<TextPainter> buildPainters() => <TextPainter>[
      for (final (text, style, fallbackWeight, _) in lines)
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
        )..layout(),
    ];
    var painters = buildPainters();
    final configuredSpacing = config.center.lineSpacing * textScaleFactor;
    double measuredTextHeight() =>
        painters.fold<double>(0, (sum, painter) => sum + painter.height) +
        configuredSpacing * math.max(0, painters.length - 1);
    final centerOffset =
        Offset(config.center.horizontalOffset, config.center.verticalOffset) *
        textScaleFactor;
    double resolveContentScale() {
      final radius = availableDiameter / 2;
      if (radius <= 0 || centerOffset.distance >= radius) return 0;

      bool fits(double scale) {
        var y = -measuredTextHeight() / 2;
        for (final painter in painters) {
          final left = centerOffset.dx - painter.width * scale / 2;
          final right = centerOffset.dx + painter.width * scale / 2;
          final top = centerOffset.dy + y * scale;
          final bottom = centerOffset.dy + (y + painter.height) * scale;
          for (final point in <Offset>[
            Offset(left, top),
            Offset(right, top),
            Offset(left, bottom),
            Offset(right, bottom),
          ]) {
            if (point.distance > radius + 1e-6) return false;
          }
          y += painter.height + configuredSpacing;
        }
        return true;
      }

      var lower = 0.0;
      var upper = 1.0;
      for (var iteration = 0; iteration < 28; iteration += 1) {
        final candidate = (lower + upper) / 2;
        if (fits(candidate)) {
          lower = candidate;
        } else {
          upper = candidate;
        }
      }
      return lower;
    }

    var contentScale = resolveContentScale();

    // Large-text and compact layouts must not turn the center summary into
    // unreadably small copy. Retain the value, then shed duplicate/supporting
    // lines in deterministic priority order until the remaining content is
    // readable. The complete metric, range, target, and status remain present
    // in the single semantic node and tooltip.
    for (final kind in const [
      _GaugeCenterLineKind.target,
      _GaugeCenterLineKind.status,
      _GaugeCenterLineKind.metric,
    ]) {
      if (contentScale >= _minimumReadableCenterScale || lines.length <= 1) {
        break;
      }
      if (!lines.any((line) => line.$4 == kind)) continue;
      lines.removeWhere((line) => line.$4 == kind);
      painters = buildPainters();
      contentScale = resolveContentScale();
    }
    final height = measuredTextHeight();
    return (
      painters: painters,
      kinds: lines.map((line) => line.$4).toList(growable: false),
      height: height,
      scale: contentScale,
      centerOffset: centerOffset,
      spacing: configuredSpacing,
    );
  }

  void _paintCenterContent(Canvas canvas) {
    final layout = _resolveCenterContentLayout();
    if (layout == null) return;
    final center = pane.center + layout.centerOffset;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(layout.scale);
    var y = -layout.height / 2;
    for (final painter in layout.painters) {
      painter.paint(canvas, Offset(-painter.width / 2, y));
      y += painter.height + layout.spacing;
    }
    canvas.restore();
  }

  List<_GaugeReferencePaintEntry> _referenceEntries() => [
    if (geometry.target case final target?)
      _GaugeReferencePaintEntry(
        geometry: target,
        color: series.target!.color ?? theme.focusBorderColor,
        width: series.target!.width,
        dashPattern: const [],
      ),
    for (final (index, threshold) in geometry.thresholds.indexed)
      _GaugeReferencePaintEntry(
        geometry: threshold,
        color: series.thresholds[index].color ?? theme.axisStyle.lineColor,
        width: series.thresholds[index].width,
        dashPattern: series.thresholds[index].dashPattern,
      ),
  ];

  List<_GaugeReferenceLabelLayout> _resolvedReferenceLabels() {
    final style = config.references;
    if (!style.showLabels) return const [];
    final candidates = <_GaugeReferenceLabelLayout>[];
    for (final entry in _referenceEntries()) {
      final label = entry.geometry.label;
      if (label == null || label.isEmpty) continue;
      final painter = _createTextPainter(
        label,
        theme.axisStyle.labelStyle.copyWith(
          color: style.labelStyle.color ?? entry.color,
          fontSize: style.labelStyle.fontSize,
          fontWeight: style.labelStyle.fontWeight,
        ),
        maxWidth: style.labelMaxWidth,
      );
      final padding = style.showLabelPanel
          ? style.panelPadding * textScaleFactor
          : 0.0;
      final labelSize = Size(
        painter.width + padding * 2,
        painter.height + padding * 2,
      );
      final boundaryAnchor =
          entry.geometry.outerPoint +
          Offset.fromDirection(
            entry.geometry.angle,
            style.labelOffset * textScaleFactor,
          );
      final center = _radialTextCenter(
        boundaryAnchor,
        entry.geometry.angle,
        labelSize,
      );
      candidates.add(
        _GaugeReferenceLabelLayout(
          painter: painter,
          rect: _clampTextRect(
            Rect.fromCenter(
              center: center,
              width: labelSize.width,
              height: labelSize.height,
            ),
          ),
          style: style,
        ),
      );
    }
    final accepted = <_GaugeReferenceLabelLayout>[];
    for (final candidate in candidates) {
      if (accepted.any(
        (label) => label.rect.inflate(2).overlaps(candidate.rect.inflate(2)),
      )) {
        continue;
      }
      accepted.add(candidate);
    }
    return accepted;
  }

  void _paintResolvedReferencePanel(
    Canvas canvas,
    _GaugeReferenceLabelLayout label,
  ) {
    final style = label.style;
    final rect = label.rect;
    final painter = label.painter;
    final rounded = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.panelBorderRadius * textScaleFactor),
    );
    final panelColor =
        style.panelColor ??
        theme.backgroundColor.withValues(
          alpha: math.max(theme.backgroundColor.a, 0.94),
        );
    canvas.drawRRect(
      rounded,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = panelColor,
    );
    if (style.panelBorderWidth > 0) {
      canvas.drawRRect(
        rounded,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.panelBorderWidth
          ..color = style.panelBorderColor ?? theme.axisStyle.lineColor,
      );
    }
    painter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - painter.width) / 2,
        rect.top + (rect.height - painter.height) / 2,
      ),
    );
  }

  List<_GaugeTextLayout> _resolvedTickLabels({
    Iterable<Rect> blockers = const [],
  }) {
    final scale = config.scale;
    final textStyle = theme.axisStyle.labelStyle.copyWith(
      color: scale.labelStyle.color,
      fontSize: scale.labelStyle.fontSize,
      fontWeight: scale.labelStyle.fontWeight,
    );
    final candidates = <_GaugeTextLayout>[
      for (final tick in geometry.ticks)
        if (tick.isMajor)
          (() {
            final painter = _createTextPainter(
              MultiAxisValueFormatter.format(
                value: tick.value,
                unit: series.unit,
              ),
              textStyle,
              maxWidth: scale.labelMaxWidth,
            );
            final center = _radialTextCenter(
              tick.labelAnchor,
              tick.angle,
              painter.size,
              direction: scale.labelPosition == GaugeScaleLabelPosition.outside
                  ? 1
                  : -1,
            );
            return _GaugeTextLayout(
              index: tick.index,
              painter: painter,
              rect: _clampTextRect(
                Rect.fromCenter(
                  center: center,
                  width: painter.width,
                  height: painter.height,
                ),
              ),
            );
          })(),
    ];
    if (candidates.length < 2) return candidates;

    // Endpoints communicate the scale domain most strongly. Resolve them
    // before interior labels, then accept only non-overlapping candidates.
    final priority = <int>[
      0,
      candidates.length - 1,
      for (var index = 1; index < candidates.length - 1; index++) index,
    ];
    final accepted = <_GaugeTextLayout>[];
    for (final index in priority) {
      final candidate = candidates[index];
      final collisionBounds = candidate.rect.inflate(2);
      if (blockers.any(
            (blocker) => blocker.inflate(2).overlaps(collisionBounds),
          ) ||
          accepted.any(
            (label) => label.rect.inflate(2).overlaps(collisionBounds),
          )) {
        continue;
      }
      accepted.add(candidate);
    }
    accepted.sort((left, right) => left.index.compareTo(right.index));
    return accepted;
  }

  TextPainter _createTextPainter(
    String text,
    TextStyle style, {
    required double maxWidth,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: TextScaler.linear(textScaleFactor),
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: math.max(36, maxWidth));

  Offset _radialTextCenter(
    Offset boundaryAnchor,
    double angle,
    Size textSize, {
    double direction = 1,
  }) {
    final radialExtent =
        math.cos(angle).abs() * textSize.width / 2 +
        math.sin(angle).abs() * textSize.height / 2;
    return boundaryAnchor +
        Offset.fromDirection(angle, radialExtent * direction);
  }

  Rect _clampTextRect(Rect desired) => desired.shift(
    Offset(
      desired.left < 0
          ? -desired.left
          : desired.right > size.width
          ? size.width - desired.right
          : 0,
      desired.top < 0
          ? -desired.top
          : desired.bottom > size.height
          ? size.height - desired.bottom
          : 0,
    ),
  );

  @visibleForTesting
  List<Rect> get resolvedTickLabelBounds {
    final references = _resolvedReferenceLabels();
    return _resolvedTickLabels(
      blockers: references.map((label) => label.rect),
    ).map((label) => label.rect).toList(growable: false);
  }

  @visibleForTesting
  List<Rect> get resolvedReferenceLabelBounds => _resolvedReferenceLabels()
      .map((label) => label.rect)
      .toList(growable: false);

  @visibleForTesting
  double get resolvedCenterContentScale =>
      _resolveCenterContentLayout()?.scale ?? 1;

  @visibleForTesting
  List<String> get resolvedCenterLineKinds =>
      _resolveCenterContentLayout()?.kinds
          .map((kind) => kind.name)
          .toList(growable: false) ??
      const <String>[];

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
