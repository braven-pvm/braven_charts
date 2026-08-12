import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../axis/polar_numeric_scale.dart';
import '../axis/radar_category_scale.dart';
import '../formatting/multi_axis_value_formatter.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../layout/radar_chart_geometry.dart';
import '../layout/radial_pane_geometry.dart';
import '../models/chart_theme.dart';
import '../models/polar_chart_config.dart';
import '../models/radar_chart_config.dart';
import '../models/radar_chart_series.dart';
import '../rendering/scatter_marker_path.dart';
import '../theming/components/series_theme.dart' show SeriesMarkerShape;
import '../utils/dashed_path.dart';

/// Native Radar profile, web, label, and datum interaction element.
class RadarSeriesElement implements DataHitElement {
  factory RadarSeriesElement({
    required RadarChartSeries series,
    required RadarChartConfig config,
    required Size size,
    required ChartTheme theme,
    int seriesIndex = 0,
    int seriesCount = 1,
    Iterable<double>? numericScaleValues,
    bool paintGrid = true,
    bool paintAxisLabels = true,
    Set<int> focusedPointIndices = const <int>{},
    Set<int> selectedPointIndices = const <int>{},
    double textScaleFactor = 1,
    double revealProgress = 1,
    double fadeProgress = 1,
    bool isSelected = false,
    bool isHovered = false,
  }) {
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
    if (!textScaleFactor.isFinite || textScaleFactor <= 0) {
      throw ArgumentError.value(
        textScaleFactor,
        'textScaleFactor',
        'Value must be finite and positive',
      );
    }
    if (!revealProgress.isFinite || !fadeProgress.isFinite) {
      throw ArgumentError('Radar animation progress must be finite');
    }
    config.validate();
    series.radarStyle.validate();

    final shadow = series.radarStyle.shadow;
    final shadowInset = shadow.isVisible
        ? shadow.blurRadius +
              shadow.spreadRadius +
              math.max(shadow.offset.dx.abs(), shadow.offset.dy.abs())
        : 0.0;

    final reservedLabelInset = config.categoryAxis.showLabels
        ? math.min(
            44 * textScaleFactor + math.max(0, config.categoryAxis.labelOffset),
            size.shortestSide * 0.3,
          )
        : 0.0;
    // A highly elevated profile plus large category labels can request more
    // reserve than a compact host can provide. Preserve both reserves while
    // proportionally constraining them so responsive layouts never collapse
    // the pane into invalid bounds.
    final maximumCombinedInset = math.max(0.0, size.shortestSide / 2 - 1);
    final requestedViewportInset = 8 + shadowInset;
    final requestedCombinedInset = requestedViewportInset + reservedLabelInset;
    final insetScale = requestedCombinedInset > maximumCombinedInset
        ? maximumCombinedInset / requestedCombinedInset
        : 1.0;
    final effectiveViewportInset = requestedViewportInset * insetScale;
    final effectiveReservedLabelInset = reservedLabelInset * insetScale;
    final paneConfig = config.pane;
    final pane = RadialPaneGeometry.resolve(
      viewportBounds: Offset.zero & size,
      viewportInsets: EdgeInsets.all(effectiveViewportInset),
      reservedLabelInsets: EdgeInsets.all(effectiveReservedLabelInset),
      innerRadiusFactor: paneConfig.innerRadiusFactor,
      outerRadiusFactor: paneConfig.outerRadiusFactor,
      startAngle: paneConfig.startAngleDegrees * math.pi / 180,
      sweepAngle: paneConfig.sweepAngleDegrees * math.pi / 180,
      clockwise: paneConfig.clockwise,
    );
    final categoryScale = RadarCategoryScale(
      pane: pane,
      categories: series.categories,
    );
    final numericScale = PolarNumericScale.fromValues(
      pane: pane,
      values: numericScaleValues ?? series.points.map((point) => point.y),
      minimum: config.radialAxis.minimum,
      maximum: config.radialAxis.maximum,
    );
    final geometry = RadarChartGeometry(
      categoryScale: categoryScale,
      numericScale: numericScale,
    );
    final radialProgress = revealProgress.clamp(0.0, 1.0);
    final profile = geometry.profileFor([
      for (final point in series.points)
        numericScale.minimum +
            (point.y - numericScale.minimum) * radialProgress,
    ]);
    final ringPaths = <Path>[
      for (var tick = 0; tick < config.radialAxis.tickCount; tick++)
        _ringPath(
          geometry: geometry,
          shape: config.radialAxis.gridShape,
          fraction: tick / (config.radialAxis.tickCount - 1),
        ),
    ];
    final boundaryPath = _ringPath(
      geometry: geometry,
      shape: config.radialAxis.gridShape,
      fraction: 1,
    );
    return RadarSeriesElement._(
      series: series,
      config: config,
      size: size,
      theme: theme,
      seriesIndex: seriesIndex,
      seriesCount: seriesCount,
      paintGrid: paintGrid,
      paintAxisLabels: paintAxisLabels,
      focusedPointIndices: Set<int>.unmodifiable(focusedPointIndices),
      selectedPointIndices: Set<int>.unmodifiable(selectedPointIndices),
      textScaleFactor: textScaleFactor,
      revealProgress: radialProgress,
      fadeProgress: fadeProgress.clamp(0.0, 1.0),
      pane: pane,
      categoryScale: categoryScale,
      numericScale: numericScale,
      geometry: geometry,
      profile: profile,
      profilePath: _profilePath(profile),
      gridRingPaths: List<Path>.unmodifiable(ringPaths),
      boundaryPath: boundaryPath,
      visibleCategoryLabelIndices: List<int>.unmodifiable(
        _visibleCategoryLabels(
          count: series.points.length,
          maximum: config.categoryAxis.maximumVisibleLabels,
          pane: pane,
          textScaleFactor: textScaleFactor,
        ),
      ),
      isSelected: isSelected,
      isHovered: isHovered,
    );
  }

  const RadarSeriesElement._({
    required this.series,
    required this.config,
    required this.size,
    required this.theme,
    required this.seriesIndex,
    required this.seriesCount,
    required this.paintGrid,
    required this.paintAxisLabels,
    required this.focusedPointIndices,
    required this.selectedPointIndices,
    required this.textScaleFactor,
    required this.revealProgress,
    required this.fadeProgress,
    required this.pane,
    required this.categoryScale,
    required this.numericScale,
    required this.geometry,
    required this.profile,
    required this.profilePath,
    required this.gridRingPaths,
    required this.boundaryPath,
    required this.visibleCategoryLabelIndices,
    required this.isSelected,
    required this.isHovered,
  });

  @override
  final RadarChartSeries series;
  final RadarChartConfig config;
  final Size size;
  final ChartTheme theme;
  @override
  final int seriesIndex;
  final int seriesCount;
  final bool paintGrid;
  final bool paintAxisLabels;
  final Set<int> focusedPointIndices;
  final Set<int> selectedPointIndices;
  final double textScaleFactor;
  final double revealProgress;
  final double fadeProgress;
  final RadialPaneGeometry pane;
  final RadarCategoryScale categoryScale;
  final PolarNumericScale numericScale;
  final RadarChartGeometry geometry;
  final RadarProfileGeometry profile;
  final Path profilePath;
  final List<Path> gridRingPaths;
  final Path boundaryPath;
  final List<int> visibleCategoryLabelIndices;

  @override
  final bool isSelected;
  @override
  final bool isHovered;

  Color get resolvedSeriesColor =>
      series.color ??
      theme.seriesTheme.colors[seriesIndex % theme.seriesTheme.colors.length];

  @override
  String get id => series.id;

  @override
  Rect get bounds => Offset.zero & size;

  @override
  ChartElementType get elementType => ChartElementType.series;

  @override
  int get priority =>
      ElementPriority.series + (selectedPointIndices.isEmpty ? 0 : 1);

  @override
  int get renderOrder => RenderOrder.series;

  @override
  int get pointCount => series.points.length;

  @override
  bool get isSelectable => false;

  @override
  bool get isDraggable => false;

  @override
  bool hitTest(Offset position) => dataHitAt(position) != null;

  @override
  ChartDataHit? dataHitAt(Offset position, {double maxDistance = 20}) {
    var bestIndex = -1;
    var bestDistance = double.infinity;
    for (final (index, vertex) in profile.vertices.indexed) {
      final distance = (position - vertex).distance;
      if (distance < bestDistance) {
        bestIndex = index;
        bestDistance = distance;
      }
    }
    if (bestIndex < 0 || bestDistance > maxDistance) return null;
    return _dataHit(bestIndex);
  }

  @override
  ChartDataHit? dataHitForPointIndex(int pointIndex) {
    if (pointIndex < 0 || pointIndex >= profile.vertices.length) return null;
    return _dataHit(pointIndex);
  }

  @override
  Iterable<ChartDataHit> get semanticDataHits sync* {
    for (var index = 0; index < profile.vertices.length; index++) {
      yield _dataHit(index);
    }
  }

  ChartDataHit _dataHit(int index) {
    final point = series.points[index];
    final vertex = profile.vertices[index];
    final formattedValue = MultiAxisValueFormatter.format(
      value: point.y,
      unit: series.unit,
    );
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: index,
      plotPosition: vertex,
      semanticBounds: Rect.fromCircle(
        center: vertex,
        radius: math.max(8, series.radarStyle.markerRadius + 5),
      ),
      point: point,
      formattedValue: formattedValue,
      ordinal: index + 1,
      count: series.points.length,
      category: series.categories[index],
      markerColor: resolvedSeriesColor,
      isSelected: selectedPointIndices.contains(index),
      isFocused: focusedPointIndices.contains(index),
      semanticLabelOverride:
          '${series.name ?? series.id}, ${series.categories[index]}, '
          '$formattedValue',
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (paintGrid) _paintGrid(canvas);
    _paintProfile(canvas);
    if (paintAxisLabels) _paintAxisLabels(canvas);
  }

  void _paintGrid(Canvas canvas) {
    final webStyle = config.webStyle;
    final ringPattern =
        webStyle.ringDashPattern ?? theme.gridStyle.majorDashPattern;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = webStyle.ringWidth ?? theme.gridStyle.majorWidth
      ..isAntiAlias = true
      ..color = webStyle.ringColor ?? theme.gridStyle.majorColor;
    if (config.radialAxis.showGridLines) {
      for (final path in gridRingPaths) {
        canvas.drawPath(
          ringPattern.isEmpty ? path : createDashedPath(path, ringPattern),
          gridPaint,
        );
      }
    }
    if (config.categoryAxis.showSpokes) {
      final spokePattern =
          webStyle.spokeDashPattern ?? theme.gridStyle.majorDashPattern;
      final spokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = webStyle.spokeWidth ?? theme.gridStyle.majorWidth
        ..isAntiAlias = true
        ..color = webStyle.spokeColor ?? theme.gridStyle.majorColor;
      for (var index = 0; index < series.points.length; index++) {
        final path = Path()
          ..moveTo(pane.center.dx, pane.center.dy)
          ..lineTo(
            pane.center.dx +
                math.cos(categoryScale.angleAt(index)) * pane.outerRadius,
            pane.center.dy +
                math.sin(categoryScale.angleAt(index)) * pane.outerRadius,
          );
        canvas.drawPath(
          spokePattern.isEmpty ? path : createDashedPath(path, spokePattern),
          spokePaint,
        );
      }
    }
    final boundaryPattern = webStyle.boundaryDashPattern ?? const <double>[];
    canvas.drawPath(
      boundaryPattern.isEmpty
          ? boundaryPath
          : createDashedPath(boundaryPath, boundaryPattern),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = webStyle.boundaryWidth ?? theme.axisStyle.lineWidth
        ..isAntiAlias = true
        ..color = webStyle.boundaryColor ?? theme.axisStyle.lineColor,
    );
  }

  void _paintProfile(Canvas canvas) {
    final color = resolvedSeriesColor;
    final style = series.radarStyle;
    if (style.shadow.isVisible) {
      _paintShadow(canvas, profilePath, color, style.shadow);
    }
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (style.gradient case final gradient? when gradient.enabled) {
      fillPaint.shader = _profileGradient(color, gradient);
    } else {
      final source = style.fillColor ?? color;
      fillPaint.color = source.withValues(
        alpha: source.a * style.fillOpacity * fadeProgress,
      );
    }
    canvas.drawPath(profilePath, fillPaint);
    final strokePath = style.strokeDashPattern.isEmpty
        ? profilePath
        : createDashedPath(profilePath, style.strokeDashPattern);
    canvas.drawPath(
      strokePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = color.withValues(
          alpha: color.a * style.strokeOpacity * fadeProgress,
        ),
    );
    for (final (index, vertex) in profile.vertices.indexed) {
      final selected = selectedPointIndices.contains(index);
      final focused = focusedPointIndices.contains(index);
      if (style.showMarkers && style.markerShape != SeriesMarkerShape.none) {
        final radius = style.markerRadius + (selected || focused ? 2 : 0);
        final markerPath = Path();
        addScatterMarkerPath(
          markerPath,
          center: vertex,
          radius: radius,
          shape: style.markerShape,
        );
        final fillColor = selected || focused
            ? theme.focusBorderColor
            : (style.markerFillColor ?? color);
        canvas.drawPath(
          markerPath,
          Paint()
            ..style = PaintingStyle.fill
            ..isAntiAlias = true
            ..color = fillColor.withValues(alpha: fillColor.a * fadeProgress),
        );
        if (style.markerBorderWidth > 0) {
          final borderColor = selected || focused
              ? theme.focusBorderColor
              : (style.markerBorderColor ?? color);
          canvas.drawPath(
            markerPath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.markerBorderWidth
              ..isAntiAlias = true
              ..color = borderColor.withValues(
                alpha: borderColor.a * fadeProgress,
              ),
          );
        }
      }
      if (style.showDataLabels &&
          _isVisibleDataLabel(index, profile.vertices.length)) {
        final labelStyle = style.dataLabelStyle;
        final labelColor = labelStyle.color ?? color;
        _paintText(
          canvas,
          MultiAxisValueFormatter.format(value: series.points[index].y),
          vertex +
              Offset.fromDirection(
                categoryScale.angleAt(index),
                style.dataLabelOffset,
              ),
          theme.axisStyle.labelStyle.copyWith(
            color: labelColor.withValues(alpha: labelColor.a * fadeProgress),
            fontSize: labelStyle.fontSize,
            fontWeight: labelStyle.fontWeight ?? FontWeight.w600,
          ),
          centered: true,
        );
      }
    }
  }

  bool _isVisibleDataLabel(int index, int count) {
    final maximum = series.radarStyle.maximumVisibleDataLabels;
    if (count <= maximum) return true;
    final stride = (count / maximum).ceil();
    return index % stride == 0;
  }

  ui.Shader _profileGradient(Color color, RadarGradientStyle gradient) {
    final source = series.radarStyle.fillColor ?? color;
    final start =
        (gradient.startColor ??
                _shiftLightness(source, gradient.startLightnessShift))
            .withValues(
              alpha:
                  (gradient.startColor ?? source).a *
                  series.radarStyle.fillOpacity *
                  fadeProgress,
            );
    final end =
        (gradient.endColor ??
                _shiftLightness(source, gradient.endLightnessShift))
            .withValues(
              alpha:
                  (gradient.endColor ?? source).a *
                  series.radarStyle.fillOpacity *
                  fadeProgress,
            );
    if (gradient.type == RadarGradientType.radial) {
      return ui.Gradient.radial(
        pane.center,
        math.max(1, pane.outerRadius),
        <Color>[start, end],
      );
    }
    final angle = gradient.angleDegrees * math.pi / 180;
    final halfExtent = Offset.fromDirection(angle, pane.outerRadius);
    return ui.Gradient.linear(
      pane.center - halfExtent,
      pane.center + halfExtent,
      <Color>[start, end],
    );
  }

  void _paintShadow(
    Canvas canvas,
    Path path,
    Color color,
    RadarShadowStyle style,
  ) {
    final source = style.color ?? _shiftLightness(color, -0.32);
    final shadowColor = source.withValues(
      alpha: source.a * style.opacity * fadeProgress,
    );
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = shadowColor
      ..maskFilter = style.blurRadius <= 0
          ? null
          : ui.MaskFilter.blur(ui.BlurStyle.normal, style.blurRadius);
    canvas.save();
    canvas.translate(style.offset.dx, style.offset.dy);
    canvas.drawPath(path, paint);
    if (style.spreadRadius > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.spreadRadius * 2
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true
          ..color = shadowColor
          ..maskFilter = paint.maskFilter,
      );
    }
    canvas.restore();
  }

  void _paintAxisLabels(Canvas canvas) {
    if (config.categoryAxis.showLabels) {
      final style = _labelStyle(
        config.categoryAxis.labelStyle,
        theme.axisStyle.labelStyle,
      );
      for (final index in visibleCategoryLabelIndices) {
        final angle = categoryScale.angleAt(index);
        final anchor =
            pane.center +
            Offset.fromDirection(
              angle,
              pane.outerRadius + config.categoryAxis.labelOffset + 8,
            );
        _paintText(
          canvas,
          series.categories[index],
          anchor,
          style,
          centered: true,
        );
      }
    }
    if (config.radialAxis.showLabels) {
      final style = _labelStyle(
        config.radialAxis.labelStyle,
        theme.axisStyle.labelStyle,
      );
      final angle = _radialLabelAngle();
      for (var tick = 0; tick < config.radialAxis.tickCount; tick++) {
        final fraction = tick / (config.radialAxis.tickCount - 1);
        final value = numericScale.minimum + numericScale.domainSpan * fraction;
        final anchor =
            pane.center +
            Offset.fromDirection(
              angle,
              numericScale.valueToRadius(value) + config.radialAxis.labelOffset,
            );
        _paintText(
          canvas,
          MultiAxisValueFormatter.format(value: value),
          anchor,
          style,
          centered: true,
        );
      }
    }
  }

  double _radialLabelAngle() {
    final base = switch (config.radialAxis.labelPosition) {
      PolarRadialLabelPosition.start => pane.startAngle,
      PolarRadialLabelPosition.middle =>
        pane.startAngle + pane.signedSweepAngle * 0.5,
      PolarRadialLabelPosition.end => pane.endAngle,
    };
    return base + config.radialAxis.labelAngleOffsetDegrees * math.pi / 180;
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    required bool centered,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(textScaleFactor),
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(36, size.width * 0.28));
    var offset = centered
        ? anchor - Offset(painter.width / 2, painter.height / 2)
        : anchor;
    offset = Offset(
      offset.dx.clamp(0, math.max(0, size.width - painter.width)),
      offset.dy.clamp(0, math.max(0, size.height - painter.height)),
    );
    painter.paint(canvas, offset);
  }

  TextStyle _labelStyle(PolarLabelStyle style, TextStyle fallback) =>
      fallback.copyWith(
        color: style.color ?? fallback.color,
        fontSize: style.fontSize ?? fallback.fontSize,
        fontWeight: style.fontWeight ?? fallback.fontWeight,
      );

  @override
  void onSelect() {}

  @override
  void onDeselect() {}

  @override
  void onHoverEnter() {}

  @override
  void onHoverExit() {}

  @override
  RadarSeriesElement copyWith({bool? isHovered, bool? isSelected}) =>
      RadarSeriesElement(
        series: series,
        config: config,
        size: size,
        theme: theme,
        seriesIndex: seriesIndex,
        seriesCount: seriesCount,
        numericScaleValues: <double>[
          numericScale.minimum,
          numericScale.maximum,
        ],
        paintGrid: paintGrid,
        paintAxisLabels: paintAxisLabels,
        focusedPointIndices: focusedPointIndices,
        selectedPointIndices: selectedPointIndices,
        textScaleFactor: textScaleFactor,
        revealProgress: revealProgress,
        fadeProgress: fadeProgress,
        isSelected: isSelected ?? this.isSelected,
        isHovered: isHovered ?? this.isHovered,
      );
}

Path _profilePath(RadarProfileGeometry profile) {
  final path = Path();
  if (profile.vertices.isEmpty) return path;
  path.moveTo(profile.vertices.first.dx, profile.vertices.first.dy);
  for (final vertex in profile.vertices.skip(1)) {
    path.lineTo(vertex.dx, vertex.dy);
  }
  return path..close();
}

Path _ringPath({
  required RadarChartGeometry geometry,
  required RadarGridShape shape,
  required double fraction,
}) {
  final ring = geometry.ringAt(fraction);
  if (shape == RadarGridShape.circle) {
    return Path()..addOval(
      Rect.fromCircle(
        center: geometry.categoryScale.pane.center,
        radius: ring.radius,
      ),
    );
  }
  final path = Path();
  if (ring.polygonVertices.isEmpty) return path;
  path.moveTo(ring.polygonVertices.first.dx, ring.polygonVertices.first.dy);
  for (final vertex in ring.polygonVertices.skip(1)) {
    path.lineTo(vertex.dx, vertex.dy);
  }
  return path..close();
}

List<int> _visibleCategoryLabels({
  required int count,
  required int maximum,
  required RadialPaneGeometry pane,
  required double textScaleFactor,
}) {
  if (count == 0) return const <int>[];
  final circumference = math.max(1, math.pi * 2 * pane.outerRadius);
  final spatialMaximum = math.max(
    1,
    (circumference / (48 * textScaleFactor)).floor(),
  );
  final visible = math.min(count, math.min(maximum, spatialMaximum));
  if (visible >= count) {
    return <int>[for (var index = 0; index < count; index++) index];
  }
  final stride = (count / visible).ceil();
  return <int>[
    for (var index = 0; index < count; index += stride) index,
  ].take(visible).toList(growable: false);
}

Color _shiftLightness(Color color, double shift) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + shift).clamp(0.0, 1.0)).toColor();
}
