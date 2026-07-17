import 'dart:math' as math;
import 'dart:ui' as ui;

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
import '../theming/styles/label_style.dart';

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
    this.animationProgress = 1,
    bool? isEntranceAnimationComplete,
    this.selectionProgress = 1,
    this.isSelected = false,
    this.isHovered = false,
  }) : isEntranceAnimationComplete =
           isEntranceAnimationComplete ?? animationProgress >= 0.999,
       geometry = PieChartGeometryCalculator.calculate(
         series: series,
         size: size,
         padding: _geometryPadding(series, size, theme, textScaleFactor),
         explodedPointIndices: selectedPointIndices,
         cornerRadius:
             series.pieStyle.cornerRadius ?? theme.pieChartTheme.cornerRadius,
         animationProgress: animationProgress,
         selectionProgress: selectionProgress,
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

  /// Radial entrance progress in the inclusive range 0–1.
  final double animationProgress;

  /// Whether the entrance animation lifecycle has reached completion.
  ///
  /// This is intentionally separate from [animationProgress]. Curves such as
  /// `elasticOut` can reach the final geometry more than once before the
  /// animation controller itself completes.
  final bool isEntranceAnimationComplete;

  /// Selected explode/elevation progress in the inclusive range 0–1.
  final double selectionProgress;

  /// Immutable geometry shared by painting and hit testing.
  final PieChartGeometry geometry;

  @override
  final bool isSelected;

  @override
  final bool isHovered;

  @override
  int get pointCount => series.points.length;

  /// Whether data labels are eligible to paint in the current frame.
  bool get shouldPaintDataLabels =>
      series.dataLabels.isVisible &&
      geometry.slices.isNotEmpty &&
      isEntranceAnimationComplete;

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

  /// Border colors after fixed, series, and theme policies are resolved.
  List<Color> get resolvedBorderColors => List<Color>.unmodifiable([
    for (final color in resolvedSliceColors) _resolveBorderColor(color),
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
    final opacity = series.pieStyle.opacity ?? theme.pieChartTheme.opacity;
    final shadow = series.pieStyle.shadow ?? theme.pieChartTheme.shadow;
    final combinedShadow = shadow.isVisible && shadow.color != null;
    if (combinedShadow && slices.isNotEmpty) {
      final combinedPath = Path();
      for (final slice in slices) {
        combinedPath.addPath(slice.path, Offset.zero);
      }
      _paintElevation(
        canvas,
        combinedPath,
        shadow.color!,
        shadow,
        opacity: opacity,
      );
    }
    for (final (index, slice) in slices.indexed) {
      final fillColor = _resolveSliceColor(slice.point, index);
      final selected = selectedPointIndices.contains(slice.pointIndex);
      final selectedElevation =
          series.pieStyle.selectedElevation ??
          theme.pieChartTheme.selectedElevation;
      if (!combinedShadow) {
        _paintElevation(
          canvas,
          slice.path,
          fillColor,
          shadow,
          opacity: opacity,
        );
      }
      if (selected) {
        _paintElevation(
          canvas,
          slice.path,
          fillColor,
          selectedElevation,
          opacity: opacity * selectionProgress,
        );
      }
      canvas.drawPath(slice.path, _sliceFillPaint(fillColor, opacity));
      if (series.pieStyle.borderWidth > 0) {
        canvas.drawPath(
          slice.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = series.pieStyle.borderWidth
            ..strokeJoin = StrokeJoin.round
            ..color = _resolveBorderColor(fillColor)
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
      if (focusedPointIndices.contains(slice.pointIndex)) {
        canvas.drawPath(
          slice.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(3, theme.focusBorderWidth)
            ..strokeJoin = StrokeJoin.round
            ..color = theme.focusBorderColor
            ..isAntiAlias = true,
        );
      }
    }

    if (!shouldPaintDataLabels) {
      return;
    }
    if (series.dataLabels.position == PieDataLabelPosition.inside) {
      _paintInsideLabels(canvas);
    } else {
      _paintOutsideLabels(canvas);
    }
  }

  void _paintElevation(
    Canvas canvas,
    Path path,
    Color sliceColor,
    PieElevationStyle style, {
    required double opacity,
  }) {
    if (!style.isVisible || opacity <= 0) return;
    final source = style.color ?? sliceColor;
    final color = source.withValues(
      alpha: (source.a * style.opacity * opacity).clamp(0, 1),
    );
    canvas.save();
    canvas.translate(style.offset.dx, style.offset.dy);
    _paintSoftPathShadow(
      canvas,
      path,
      color: color,
      blurRadius: style.blurRadius,
      spreadRadius: style.spreadRadius,
    );
    canvas.restore();
  }

  void _paintSoftPathShadow(
    Canvas canvas,
    Path path, {
    required Color color,
    required double blurRadius,
    required double spreadRadius,
  }) {
    const layers = 4;
    for (var layer = layers; layer >= 1; layer--) {
      final fraction = layer / layers;
      final extent = spreadRadius + blurRadius * fraction * 0.65;
      if (extent <= 0) continue;
      final layerAlpha = color.a * (0.08 + (1 - fraction) * 0.16);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = extent * 2
          ..strokeJoin = StrokeJoin.round
          ..color = color.withValues(alpha: layerAlpha.clamp(0, 1))
          ..isAntiAlias = true,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: (color.a * 0.45).clamp(0, 1))
        ..isAntiAlias = true,
    );
  }

  void _paintInsideLabels(Canvas canvas) {
    final calloutStyle = _effectiveCalloutStyle;
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
      final labelSize = _labelSize(painter, calloutStyle);
      final radialThickness = slice.outerRadius - slice.innerRadius;
      if (labelSize.width > radialThickness * 0.95 ||
          labelSize.height > radialThickness * 0.55) {
        continue;
      }
      final rect = Rect.fromCenter(
        center: slice.insideLabelAnchor,
        width: labelSize.width,
        height: labelSize.height,
      );
      _paintLabel(canvas, painter, rect, calloutStyle);
    }
  }

  void _paintOutsideLabels(Canvas canvas) {
    final calloutStyle = _effectiveCalloutStyle;
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
          size: _labelSize(painter, calloutStyle),
        ),
      );
    }

    final left = candidates.where((candidate) => candidate.isLeft).toList();
    final right = candidates.where((candidate) => !candidate.isLeft).toList();
    _resolveLabelLane(left);
    _resolveLabelLane(right);
    final visibleCandidates = [...left, ...right];
    _paintCalloutShadows(canvas, visibleCandidates, calloutStyle);

    for (final candidate in visibleCandidates) {
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
      _paintLabel(
        canvas,
        candidate.painter,
        rect,
        calloutStyle,
        paintShadow: false,
      );
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
    final isLeft = lane.first.isLeft;
    final pieBounds = geometry.slices
        .map((slice) => slice.bounds)
        .reduce((bounds, sliceBounds) => bounds.expandToInclude(sliceBounds));
    final laneEdge = isLeft ? pieBounds.left : pieBounds.right;
    var nextTop = edgePadding;
    for (final candidate in lane) {
      final desiredTop =
          candidate.slice.outsideLabelAnchor.dy - candidate.size.height / 2;
      final top = allowShift ? math.max(desiredTop, nextTop) : desiredTop;
      final maximumX = math.max(
        edgePadding,
        size.width - edgePadding - candidate.size.width,
      );
      final requestedX = isLeft
          ? laneEdge - series.dataLabels.outsideOffset - candidate.size.width
          : laneEdge + series.dataLabels.outsideOffset;
      final x = requestedX.clamp(edgePadding, maximumX).toDouble();
      candidate.labelRect = Rect.fromLTWH(
        x,
        top,
        candidate.size.width,
        candidate.size.height,
      );
      nextTop = top + candidate.size.height + minimumGap;
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
    final calloutTextStyle = _effectiveCalloutStyle?.textStyle;
    final resolvedFontSize =
        (calloutTextStyle?.fontSize ??
            typography.baseFontSize * typography.labelMultiplier) *
        textScaleFactor;
    return TextPainter(
      text: TextSpan(
        text: _labelText(slice),
        style: TextStyle(
          color: color,
          fontFamily: typography.fontFamily,
          fontWeight: fontWeight,
          height: 1.1,
        ).merge(calloutTextStyle).copyWith(fontSize: resolvedFontSize),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(32, size.width * 0.32));
  }

  LabelStyle? get _effectiveCalloutStyle =>
      series.dataLabels.calloutStyle ?? theme.pieChartTheme.calloutStyle;

  Size _labelSize(TextPainter painter, LabelStyle? style) {
    final padding = style?.padding ?? EdgeInsets.zero;
    return Size(
      painter.width + padding.horizontal,
      painter.height + padding.vertical,
    );
  }

  void _paintLabel(
    Canvas canvas,
    TextPainter painter,
    Rect rect,
    LabelStyle? style, {
    bool paintShadow = true,
  }) {
    if (style == null) {
      painter.paint(canvas, rect.topLeft);
      return;
    }
    final rounded = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.borderRadius),
    );
    if (paintShadow &&
        style.shadowColor != null &&
        (style.shadowBlurRadius ?? 0) > 0) {
      _paintSoftPathShadow(
        canvas,
        Path()..addRRect(rounded),
        color: style.shadowColor!,
        blurRadius: style.shadowBlurRadius!,
        spreadRadius: 0,
      );
    }
    if (style.backgroundColor.a > 0) {
      canvas.drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.fill
          ..color = style.backgroundColor,
      );
    }
    if (style.borderWidth > 0 && style.borderColor.a > 0) {
      canvas.drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.borderWidth
          ..color = style.borderColor,
      );
    }
    painter.paint(canvas, rect.topLeft + style.padding.topLeft);
  }

  void _paintCalloutShadows(
    Canvas canvas,
    List<_PieLabelCandidate> candidates,
    LabelStyle? style,
  ) {
    if (style?.shadowColor == null || (style?.shadowBlurRadius ?? 0) <= 0) {
      return;
    }
    final path = Path();
    for (final candidate in candidates) {
      final rect = candidate.labelRect;
      if (rect == null) continue;
      path.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(style!.borderRadius)),
      );
    }
    _paintSoftPathShadow(
      canvas,
      path,
      color: style!.shadowColor!,
      blurRadius: style.shadowBlurRadius!,
      spreadRadius: 0,
    );
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

  Paint _sliceFillPaint(Color sliceColor, double opacity) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final gradient = series.pieStyle.gradient ?? theme.pieChartTheme.gradient;
    if (gradient == null || !gradient.enabled) {
      return paint
        ..color = sliceColor.withValues(alpha: sliceColor.a * opacity);
    }

    final colors = <Color>[
      _gradientStopColor(
        gradient.startColor,
        sliceColor,
        gradient.startLightnessShift,
        opacity,
      ),
      _gradientStopColor(
        gradient.endColor,
        sliceColor,
        gradient.endLightnessShift,
        opacity,
      ),
    ];
    final center = geometry.center;
    final radius = geometry.outerRadius;
    paint.shader = switch (gradient.type) {
      PieGradientType.radial => ui.Gradient.radial(center, radius, colors),
      PieGradientType.linear => () {
        final radians = gradient.angleDegrees * math.pi / 180;
        final direction = Offset(math.cos(radians), math.sin(radians));
        return ui.Gradient.linear(
          center - direction * radius,
          center + direction * radius,
          colors,
        );
      }(),
    };
    return paint;
  }

  Color _gradientStopColor(
    Color? fixedColor,
    Color sliceColor,
    double lightnessShift,
    double opacity,
  ) {
    final hsl = HSLColor.fromColor(sliceColor);
    final color =
        fixedColor ??
        hsl
            .withLightness((hsl.lightness + lightnessShift).clamp(0.0, 1.0))
            .toColor();
    return color.withValues(alpha: color.a * opacity);
  }

  Color _resolveBorderColor(Color sliceColor) {
    final style = series.pieStyle;
    if (style.borderColor case final fixedColor?) return fixedColor;

    final pieTheme = theme.pieChartTheme;
    final mode = style.borderColorMode ?? pieTheme.borderColorMode;
    if (mode == PieBorderColorMode.chartTheme) {
      return theme.axisStyle.lineColor;
    }

    final hueShift =
        style.borderHueShiftDegrees ?? pieTheme.borderHueShiftDegrees;
    final saturationShift =
        style.borderSaturationShift ?? pieTheme.borderSaturationShift;
    final lightnessShift =
        style.borderLightnessShift ?? pieTheme.borderLightnessShift;
    final hsl = HSLColor.fromColor(sliceColor);
    final shiftedHue = (hsl.hue + hueShift) % 360;
    return hsl
        .withHue(shiftedHue < 0 ? shiftedHue + 360 : shiftedHue)
        .withSaturation(
          (hsl.saturation + saturationShift).clamp(0.0, 1.0).toDouble(),
        )
        .withLightness(
          (hsl.lightness + lightnessShift).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
  }

  ChartDataHit _dataHitForSlice(PieSliceGeometry slice) {
    final visibleIndex = geometry.slices.indexOf(slice);
    final unit = series.unit == null || series.unit!.isEmpty
        ? ''
        : ' ${series.unit}';
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: slice.pointIndex,
      plotPosition: slice.tooltipAnchor,
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
      animationProgress: animationProgress,
      isEntranceAnimationComplete: isEntranceAnimationComplete,
      selectionProgress: selectionProgress,
      isHovered: isHovered ?? this.isHovered,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  static EdgeInsets _geometryPadding(
    PieChartSeries series,
    Size size,
    ChartTheme theme,
    double textScaleFactor,
  ) {
    final EdgeInsets labelPadding;
    if (!series.dataLabels.isVisible ||
        series.dataLabels.position == PieDataLabelPosition.inside) {
      labelPadding = const EdgeInsets.all(12);
    } else {
      final horizontal = math.min(
        math.max(36.0, size.width * 0.22 * textScaleFactor),
        size.width * 0.34,
      );
      final vertical = math.min(28 * textScaleFactor, size.height * 0.18);
      labelPadding = EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      );
    }

    final strokeOverflow = math.max(
      series.pieStyle.borderWidth / 2,
      math.max(3, theme.focusBorderWidth) / 2,
    );
    final shadow = series.pieStyle.shadow ?? theme.pieChartTheme.shadow;
    final selectedElevation =
        series.pieStyle.selectedElevation ??
        theme.pieChartTheme.selectedElevation;
    final shadowOverflow = _paintOverflowInsets(
      shadow,
      radialOffset: strokeOverflow,
    );
    final selectedOverflow = _paintOverflowInsets(
      selectedElevation,
      radialOffset: strokeOverflow + series.pieStyle.selectionExplodeOffset,
    );

    return EdgeInsets.fromLTRB(
      math.max(
        labelPadding.left,
        math.max(shadowOverflow.left, selectedOverflow.left),
      ),
      math.max(
        labelPadding.top,
        math.max(shadowOverflow.top, selectedOverflow.top),
      ),
      math.max(
        labelPadding.right,
        math.max(shadowOverflow.right, selectedOverflow.right),
      ),
      math.max(
        labelPadding.bottom,
        math.max(shadowOverflow.bottom, selectedOverflow.bottom),
      ),
    );
  }

  static EdgeInsets _paintOverflowInsets(
    PieElevationStyle style, {
    required double radialOffset,
  }) {
    final elevationExtent = style.isVisible
        ? style.spreadRadius + style.blurRadius * 0.65
        : 0.0;
    return EdgeInsets.fromLTRB(
      radialOffset + elevationExtent + math.max(0, -style.offset.dx),
      radialOffset + elevationExtent + math.max(0, -style.offset.dy),
      radialOffset + elevationExtent + math.max(0, style.offset.dx),
      radialOffset + elevationExtent + math.max(0, style.offset.dy),
    );
  }
}

class _PieLabelCandidate {
  _PieLabelCandidate({
    required this.slice,
    required this.painter,
    required this.color,
    required this.isLeft,
    required this.size,
  });

  final PieSliceGeometry slice;
  final TextPainter painter;
  final Color color;
  final bool isLeft;
  final Size size;
  Rect? labelRect;
}
