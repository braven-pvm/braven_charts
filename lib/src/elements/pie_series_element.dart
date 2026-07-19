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
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_config.dart';
import '../models/radial_category_series.dart';
import '../models/radial_selection_style.dart';
import '../formatting/radial_value_formatter.dart';
import '../formatting/multi_axis_value_formatter.dart';
import '../rendering/pie_slice_color_resolver.dart';
import '../theming/styles/label_style.dart';

/// Radial chart element responsible for category sectors and deterministic
/// labels.
class PieSeriesElement implements DataHitElement, ChartSemanticSummaryProvider {
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
    this.geometryCenter,
    this.geometryInnerRadius,
    this.geometryOuterRadius,
    this.insideLabelRadiusFactor = 0.58,
    this.groupLabel,
    this.groupName,
    this.groupOrdinal,
    this.groupCount,
    this.centerContentOverride,
    this.centerTotalOverride,
    this.centerUnitOverride,
    this.centerSelectionUsesOverride = false,
    this.centerSelectedPointOverride,
    this.centerSelectedPointIndexOverride,
    this.paintCenterContent = true,
    this.includeCenterSemantics = true,
    this.coordinateOutsideLabels = false,
    this.compositionBackdropBlur = 0,
    this.isSelected = false,
    this.isHovered = false,
  }) : isEntranceAnimationComplete =
           isEntranceAnimationComplete ?? animationProgress >= 0.999,
       geometry = PieChartGeometryCalculator.calculate(
         series: series,
         size: size,
         padding: geometryPaddingFor(series, size, theme, textScaleFactor),
         centerOverride: geometryCenter,
         innerRadiusOverride: geometryInnerRadius,
         outerRadiusOverride: geometryOuterRadius,
         insideLabelRadiusFactor: insideLabelRadiusFactor,
         explodedPointIndices: selectedPointIndices,
         cornerRadius:
             series.radialStyle.cornerRadius ??
             theme.pieChartTheme.cornerRadius,
         cornerTreatment:
             series.radialStyle.cornerTreatment ??
             theme.pieChartTheme.cornerTreatment,
         animationMode:
             series.radialStyle.animationMode ??
             theme.pieChartTheme.animationMode,
         animationProgress: animationProgress,
         selectionProgress: selectionProgress,
         selectionEffect: series.selectionStyle.effect,
         selectionLiftScale: series.selectionStyle.liftScale,
         selectionLiftOffset: series.selectionStyle.liftOffset,
       );

  @override
  final RadialCategorySeries series;

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

  /// Durable source-point indices shown with the configured selection geometry.
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

  /// Shared plot center supplied by a multi-ring composition allocator.
  final Offset? geometryCenter;

  /// Allocated inner band edge supplied by a multi-ring composition.
  final double? geometryInnerRadius;

  /// Allocated outer band edge supplied by a multi-ring composition.
  final double? geometryOuterRadius;

  /// Radial position of inside labels within the allocated slice band.
  ///
  /// Pie and single-ring Donut retain the established 58% anchor. Concentric
  /// Donut supplies 50% so a zero offset is the exact midpoint of every ring.
  final double insideLabelRadiusFactor;

  /// Physical ring label supplied by a multi-ring composition.
  final String? groupLabel;

  /// User-facing ring name supplied by a multi-ring composition.
  final String? groupName;

  /// One-based traversal position supplied by a multi-ring composition.
  final int? groupOrdinal;

  /// Number of rings participating in the composition.
  final int? groupCount;

  /// Plot-owned center content used by a multi-ring composition.
  ///
  /// Single Donut leaves this null and retains its series-owned center model.
  final DonutCenterContent? centerContentOverride;

  /// Plot-owned numeric total used by [centerContentOverride].
  final double? centerTotalOverride;

  /// Unit used when formatting [centerTotalOverride] or an overridden point.
  final String? centerUnitOverride;

  /// Whether center selection comes from the explicit override fields.
  final bool centerSelectionUsesOverride;

  /// Selected visible point from any ring sharing a composition center.
  final ChartDataPoint? centerSelectedPointOverride;

  /// Source point index represented by [centerSelectedPointOverride].
  final int? centerSelectedPointIndexOverride;

  /// Whether the portable Donut center text is painted on the Canvas.
  ///
  /// Runtime center widgets disable this while retaining the same portable
  /// [DonutCenterContent] as an artifact and preview fallback.
  final bool paintCenterContent;

  /// Whether the render element contributes the Donut center summary node.
  ///
  /// Runtime center widgets and actions provide their own widget semantics and
  /// disable this to avoid duplicate assistive nodes.
  final bool includeCenterSemantics;

  /// Whether outside labels are deferred to the composition-level resolver.
  ///
  /// Concentric Donut enables this for every ring so labels from separate
  /// independent series cannot overlap. Single Pie and Donut elements keep
  /// their established local label path.
  final bool coordinateOutsideLabels;

  /// Backdrop blur requested by another lifted ring in the same composition.
  ///
  /// Concentric Donut keeps every ring as an independent series element. This
  /// composition-level value lets the selected ring soften all surrounding
  /// rings without changing their geometry or durable selection state.
  final double compositionBackdropBlur;

  /// Immutable geometry shared by painting and hit testing.
  final PieChartGeometry geometry;

  final List<Rect> _debugResolvedOutsideLabelRects = <Rect>[];
  final List<Rect> _debugResolvedInsideLabelRects = <Rect>[];

  /// Most recently painted outside-label rectangles for deterministic tests.
  List<Rect> get debugResolvedOutsideLabelRects =>
      List<Rect>.unmodifiable(_debugResolvedOutsideLabelRects);

  /// Most recently painted inside-label rectangles for deterministic tests.
  List<Rect> get debugResolvedInsideLabelRects =>
      List<Rect>.unmodifiable(_debugResolvedInsideLabelRects);

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
  int get priority => ElementPriority.series + (usesLiftSelection ? 1 : 0);

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

  /// Whether this ring owns at least one selected slice using the lift effect.
  ///
  /// The render pipeline also uses this signal as the composition z-order and
  /// hit-test priority so an elevated inner-ring slice can sit above adjacent
  /// rings without reallocating any radial bands.
  bool get usesLiftSelection =>
      series.selectionStyle.effect == RadialSelectionEffect.lift &&
      geometry.slices.any(_isSliceSelected);

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
      if (slice.sourcePointIndices.contains(pointIndex)) {
        return _dataHitForSlice(slice);
      }
    }
    return null;
  }

  @override
  Iterable<ChartDataHit> get semanticDataHits =>
      geometry.slices.map(_dataHitForSlice);

  /// Visible selected slice represented by the Donut center, if any.
  PieSliceGeometry? get selectedCenterSlice {
    for (final slice in geometry.slices) {
      if (slice.sourcePointIndices.any(selectedPointIndices.contains)) {
        return slice;
      }
    }
    return null;
  }

  /// Resolved text shown in the Donut opening for the current selection.
  DonutCenterPresentation? get centerPresentation {
    final donut = series;
    if (donut is! DonutChartSeries) {
      return null;
    }
    final config = centerContentOverride ?? donut.centerContent;
    if (!config.isVisible) return null;
    final selectedSlice = centerSelectionUsesOverride
        ? null
        : selectedCenterSlice;
    final selectedIndex = centerSelectionUsesOverride
        ? centerSelectedPointIndexOverride
        : selectedSlice?.pointIndex;
    final selectedPoint = centerSelectionUsesOverride
        ? centerSelectedPointOverride
        : selectedSlice?.point;
    final total = centerTotalOverride ?? donut.total;
    final usesSelectedValue = switch (config.valueMode) {
      DonutCenterValueMode.selectedValue => true,
      DonutCenterValueMode.selectedOrTotal => selectedPoint != null,
      DonutCenterValueMode.total || DonutCenterValueMode.custom => false,
    };
    final String? value = switch (config.valueMode) {
      DonutCenterValueMode.total => _formatCenterNumber(total, config),
      DonutCenterValueMode.selectedValue =>
        selectedPoint == null
            ? null
            : _formatCenterNumber(selectedPoint.y, config),
      DonutCenterValueMode.selectedOrTotal => _formatCenterNumber(
        selectedPoint?.y ?? total,
        config,
      ),
      DonutCenterValueMode.custom => config.customValue!.trim(),
    };
    if (value == null) return null;

    final explicitLabel = config.label?.trim();
    final dynamicSelectedLabel = usesSelectedValue
        ? selectedPoint?.label?.trim()
        : null;
    final label = explicitLabel ?? dynamicSelectedLabel;
    final semanticParts = <String>[
      'Donut center',
      if (label != null && label.isNotEmpty) label,
      value,
      if (usesSelectedValue && selectedPoint?.label != null)
        'selected slice ${selectedPoint!.label!.trim()}',
      if (config.valueMode == DonutCenterValueMode.selectedOrTotal &&
          selectedPoint == null)
        'total fallback',
    ];
    return DonutCenterPresentation(
      label: label,
      value: value,
      semanticLabel: semanticParts.join(', '),
      selectedPointIndex: usesSelectedValue ? selectedIndex : null,
    );
  }

  /// Safe rectangular region inscribed within the circular center opening.
  Rect? get centerContentBounds {
    if (centerPresentation == null || geometry.innerRadius <= 0) return null;
    final diameter = geometry.innerRadius * 2;
    if (diameter < 16) return null;
    return Rect.fromCenter(
      center: geometry.center,
      width: diameter * 0.78,
      height: diameter * 0.62,
    );
  }

  @override
  Iterable<ChartSemanticSummary> get semanticSummaries sync* {
    if (!includeCenterSemantics) return;
    final presentation = centerPresentation;
    final contentBounds = centerContentBounds;
    if (presentation == null || contentBounds == null) return;
    yield ChartSemanticSummary(
      id: '${series.id}:center',
      label: presentation.semanticLabel,
      bounds: contentBounds,
    );
  }

  @override
  bool get isSelectable => false;

  @override
  bool get isDraggable => false;

  @override
  bool hitTest(Offset position) => sliceAt(position) != null;

  @override
  void paint(Canvas canvas, Size size) {
    final animationMode =
        series.radialStyle.animationMode ?? theme.pieChartTheme.animationMode;
    final fadeProgress = animationMode == PieAnimationMode.fade
        ? animationProgress
        : 1.0;
    if (fadeProgress <= 0) return;
    final usesFadeLayer = fadeProgress < 1;
    if (usesFadeLayer) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: fadeProgress),
      );
    }
    final slices = geometry.slices;
    final opacity = series.radialStyle.opacity ?? theme.pieChartTheme.opacity;
    final shadow = series.radialStyle.shadow ?? theme.pieChartTheme.shadow;
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
    final selectionStyle = series.selectionStyle;
    final backgroundSlices = usesLiftSelection
        ? slices.where((slice) => !_isSliceSelected(slice))
        : slices;
    final foregroundSlices = usesLiftSelection
        ? slices.where(_isSliceSelected)
        : const <PieSliceGeometry>[];
    final localBackdropBlur = usesLiftSelection
        ? selectionStyle.backdropBlur * selectionProgress
        : 0.0;
    final backdropBlur = math.max(localBackdropBlur, compositionBackdropBlur);
    if (backdropBlur > 0.01) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: backdropBlur,
            sigmaY: backdropBlur,
          ),
      );
    }
    for (final slice in backgroundSlices) {
      _paintSlice(
        canvas,
        slice,
        index: slices.indexOf(slice),
        opacity: opacity,
        shadow: shadow,
        combinedShadow: combinedShadow,
      );
    }
    if (backdropBlur > 0.01) canvas.restore();
    for (final slice in foregroundSlices) {
      _paintSlice(
        canvas,
        slice,
        index: slices.indexOf(slice),
        opacity: opacity,
        shadow: shadow,
        combinedShadow: combinedShadow,
      );
    }

    if (shouldPaintDataLabels) {
      if (series.dataLabels.hasLabelAt(PieDataLabelPosition.inside)) {
        _paintInsideLabels(canvas);
      }
      if (series.dataLabels.hasLabelAt(PieDataLabelPosition.outside) &&
          !coordinateOutsideLabels) {
        _paintOutsideLabels(canvas);
      }
    }
    if (paintCenterContent) _paintCenterContent(canvas);
    if (usesFadeLayer) canvas.restore();
  }

  void _paintSlice(
    Canvas canvas,
    PieSliceGeometry slice, {
    required int index,
    required double opacity,
    required PieElevationStyle shadow,
    required bool combinedShadow,
  }) {
    final fillColor = _resolveSliceColor(slice.point, index);
    final selected = _isSliceSelected(slice);
    final selectedElevation =
        series.radialStyle.selectedElevation ??
        theme.pieChartTheme.selectedElevation;
    if (!combinedShadow) {
      _paintElevation(canvas, slice.path, fillColor, shadow, opacity: opacity);
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
    if (series.radialStyle.borderWidth > 0) {
      canvas.drawPath(
        slice.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = series.radialStyle.borderWidth
          ..strokeJoin = StrokeJoin.round
          ..color = _resolveBorderColor(fillColor)
          ..isAntiAlias = true,
      );
    }
    final hoveredMarker = coordinator?.hoveredMarker;
    final hovered =
        hoveredMarker?.seriesId == series.id &&
        hoveredMarker?.markerIndex == slice.pointIndex;
    if (hovered) {
      canvas.drawPath(
        slice.path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = theme.interactionTheme.selectionColor
          ..isAntiAlias = true,
      );
    }
    if (_isSliceFocused(slice)) {
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

  void _paintCenterContent(Canvas canvas) {
    final donut = series;
    if (donut is! DonutChartSeries) return;
    final presentation = centerPresentation;
    final contentBounds = centerContentBounds;
    if (presentation == null || contentBounds == null) return;

    final config = centerContentOverride ?? donut.centerContent;
    final labelStyle =
        config.labelStyle ?? theme.pieChartTheme.centerLabelStyle;
    final valueStyle =
        config.valueStyle ?? theme.pieChartTheme.centerValueStyle;
    final hasLabel = presentation.label?.isNotEmpty ?? false;
    final gap = hasLabel
        ? math.min(4 * textScaleFactor, contentBounds.height * 0.1)
        : 0.0;

    var labelPainter = hasLabel
        ? _centerTextPainter(
            presentation.label!,
            style: labelStyle,
            defaultFontSize: 12,
            defaultWeight: FontWeight.w500,
            scale: 1,
            maxWidth: contentBounds.width,
          )
        : null;
    var valuePainter = _centerTextPainter(
      presentation.value,
      style: valueStyle,
      defaultFontSize: 22,
      defaultWeight: FontWeight.w700,
      scale: 1,
      maxWidth: contentBounds.width,
    );
    final initialHeight =
        (labelPainter == null
            ? 0
            : _labelSize(labelPainter, labelStyle).height) +
        gap +
        _labelSize(valuePainter, valueStyle).height;
    final fitScale = initialHeight <= 0
        ? 1.0
        : math.min(1.0, contentBounds.height / initialHeight);
    if (fitScale < 1) {
      labelPainter = hasLabel
          ? _centerTextPainter(
              presentation.label!,
              style: labelStyle,
              defaultFontSize: 12,
              defaultWeight: FontWeight.w500,
              scale: fitScale,
              maxWidth: contentBounds.width,
            )
          : null;
      valuePainter = _centerTextPainter(
        presentation.value,
        style: valueStyle,
        defaultFontSize: 22,
        defaultWeight: FontWeight.w700,
        scale: fitScale,
        maxWidth: contentBounds.width,
      );
    }

    final labelSize = labelPainter == null
        ? Size.zero
        : _labelSize(labelPainter, labelStyle);
    final valueSize = _labelSize(valuePainter, valueStyle);
    final effectiveGap = labelPainter == null ? 0.0 : gap * fitScale;
    final totalHeight = labelSize.height + effectiveGap + valueSize.height;
    var top = contentBounds.center.dy - totalHeight / 2;
    if (labelPainter != null) {
      final labelRect = Rect.fromLTWH(
        contentBounds.center.dx - labelSize.width / 2,
        top,
        labelSize.width,
        labelSize.height,
      );
      _paintLabel(canvas, labelPainter, labelRect, labelStyle);
      top = labelRect.bottom + effectiveGap;
    }
    final valueRect = Rect.fromLTWH(
      contentBounds.center.dx - valueSize.width / 2,
      top,
      valueSize.width,
      valueSize.height,
    );
    _paintLabel(canvas, valuePainter, valueRect, valueStyle);
  }

  TextPainter _centerTextPainter(
    String text, {
    required LabelStyle? style,
    required double defaultFontSize,
    required FontWeight defaultWeight,
    required double scale,
    required double maxWidth,
  }) {
    final typography = theme.typographyTheme;
    final sourceStyle = style?.textStyle;
    final fontSize =
        (sourceStyle?.fontSize ?? defaultFontSize) * textScaleFactor * scale;
    final color =
        sourceStyle?.color ??
        theme.axisStyle.labelStyle.color ??
        const Color(0xFF1F2937);
    final horizontalPadding = style?.padding.horizontal ?? 0;
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontFamily: typography.fontFamily,
          fontSize: fontSize,
          fontWeight: defaultWeight,
          height: 1.1,
        ).merge(sourceStyle).copyWith(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(8, maxWidth - horizontalPadding));
  }

  String _formatCenterNumber(double value, DonutCenterContent content) {
    final custom = content.valueFormatter;
    if (custom != null) return custom(value);
    if (centerContentOverride == null) {
      return RadialValueFormatters.center(series, value);
    }
    return MultiAxisValueFormatter.format(
      value: value,
      unit: centerUnitOverride,
    );
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
    final content = _labelContentFor(PieDataLabelPosition.inside);
    final calloutStyle = _effectiveCalloutStyleFor(PieDataLabelPosition.inside);
    _debugResolvedInsideLabelRects.clear();
    for (final (index, slice) in geometry.slices.indexed) {
      if (!_isLabelEligible(slice)) {
        continue;
      }
      final color = _resolveSliceColor(slice.point, index);
      final painter = _labelPainter(
        slice,
        content: content,
        calloutStyle: calloutStyle,
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
      _debugResolvedInsideLabelRects.add(rect);
    }
  }

  void _paintOutsideLabels(Canvas canvas) {
    final content = _labelContentFor(PieDataLabelPosition.outside);
    final calloutStyle = _effectiveCalloutStyleFor(
      PieDataLabelPosition.outside,
    );
    final candidates = <_PieLabelCandidate>[];
    for (final (index, slice) in geometry.slices.indexed) {
      if (!_isLabelEligible(slice)) {
        continue;
      }
      final painter = _labelPainter(
        slice,
        content: content,
        calloutStyle: calloutStyle,
        color: theme.axisStyle.labelStyle.color ?? const Color(0xFF374151),
        fontWeight: FontWeight.w500,
      );
      candidates.add(
        _PieLabelCandidate(
          owner: this,
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
    _debugResolvedOutsideLabelRects
      ..clear()
      ..addAll(
        visibleCandidates
            .map((candidate) => candidate.labelRect)
            .whereType<Rect>(),
      );
    for (final candidate in visibleCandidates) {
      _paintOutsideLabelCandidate(canvas, candidate);
    }
  }

  void _paintOutsideLabelCandidate(
    Canvas canvas,
    _PieLabelCandidate candidate,
  ) {
    final rect = candidate.labelRect;
    if (rect == null) return;
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
      _effectiveCalloutStyleFor(PieDataLabelPosition.outside),
      paintShadow: false,
    );
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

  /// Paints one collision-managed outside-label layer for several rings.
  ///
  /// Every element must share the same plot size and center. The method keeps
  /// each ring's own formatter and label/callout configuration while using the
  /// outermost painted sector as the common lane edge.
  static void paintCoordinatedOutsideLabels(
    Canvas canvas,
    List<PieSeriesElement> elements,
  ) {
    final candidates = <_PieLabelCandidate>[];
    for (final element in elements) {
      element._debugResolvedOutsideLabelRects.clear();
      if (!element.coordinateOutsideLabels ||
          !element.shouldPaintDataLabels ||
          !element.series.dataLabels.hasLabelAt(PieDataLabelPosition.outside)) {
        continue;
      }
      final content = element._labelContentFor(PieDataLabelPosition.outside);
      final calloutStyle = element._effectiveCalloutStyleFor(
        PieDataLabelPosition.outside,
      );
      for (final (index, slice) in element.geometry.slices.indexed) {
        if (!element._isLabelEligible(slice)) continue;
        final painter = element._labelPainter(
          slice,
          content: content,
          calloutStyle: calloutStyle,
          color:
              element.theme.axisStyle.labelStyle.color ??
              const Color(0xFF374151),
          fontWeight: FontWeight.w500,
        );
        candidates.add(
          _PieLabelCandidate(
            owner: element,
            slice: slice,
            painter: painter,
            color: element._resolveSliceColor(slice.point, index),
            isLeft: math.cos(slice.midAngle) < 0,
            size: element._labelSize(painter, calloutStyle),
          ),
        );
      }
    }
    if (candidates.isEmpty) return;

    final commonPieBounds = candidates
        .map((candidate) => candidate.slice.bounds)
        .reduce((bounds, sliceBounds) => bounds.expandToInclude(sliceBounds));
    final left = candidates.where((candidate) => candidate.isLeft).toList();
    final right = candidates.where((candidate) => !candidate.isLeft).toList();
    _resolveCoordinatedLabelLane(left, commonPieBounds);
    _resolveCoordinatedLabelLane(right, commonPieBounds);

    for (final element in elements) {
      final owned = candidates
          .where((candidate) => identical(candidate.owner, element))
          .toList(growable: false);
      element._paintCalloutShadows(
        canvas,
        owned,
        element._effectiveCalloutStyleFor(PieDataLabelPosition.outside),
      );
      element._debugResolvedOutsideLabelRects.addAll(
        owned.map((candidate) => candidate.labelRect).whereType<Rect>(),
      );
    }
    for (final candidate in candidates) {
      candidate.owner._paintOutsideLabelCandidate(canvas, candidate);
    }
  }

  static void _resolveCoordinatedLabelLane(
    List<_PieLabelCandidate> lane,
    Rect commonPieBounds,
  ) {
    if (lane.isEmpty) return;
    lane.sort((a, b) {
      final vertical = a.slice.outsideLabelAnchor.dy.compareTo(
        b.slice.outsideLabelAnchor.dy,
      );
      if (vertical != 0) return vertical;
      final ring = a.owner.seriesIndex.compareTo(b.owner.seriesIndex);
      return ring != 0
          ? ring
          : a.slice.pointIndex.compareTo(b.slice.pointIndex);
    });

    final collisionStrategy = lane
        .map((candidate) => candidate.owner.series.dataLabels.collisionStrategy)
        .reduce((a, b) => a.index >= b.index ? a : b);
    final visible = [...lane];
    while (visible.isNotEmpty) {
      final fits = _positionCoordinatedLabelLane(
        visible,
        commonPieBounds: commonPieBounds,
        allowShift: collisionStrategy != PieDataLabelCollisionStrategy.none,
      );
      if (fits ||
          collisionStrategy != PieDataLabelCollisionStrategy.shiftAndHide) {
        break;
      }
      final lowestPriority = visible.reduce((a, b) {
        final share = a.slice.share.compareTo(b.slice.share);
        if (share != 0) return share < 0 ? a : b;
        final ring = a.owner.seriesIndex.compareTo(b.owner.seriesIndex);
        if (ring != 0) return ring > 0 ? a : b;
        return a.slice.pointIndex > b.slice.pointIndex ? a : b;
      });
      lowestPriority.labelRect = null;
      visible.remove(lowestPriority);
    }
  }

  static bool _positionCoordinatedLabelLane(
    List<_PieLabelCandidate> lane, {
    required Rect commonPieBounds,
    required bool allowShift,
  }) {
    const edgePadding = 4.0;
    final minimumGap = lane
        .map((candidate) => 4 * candidate.owner.textScaleFactor)
        .reduce(math.max);
    final isLeft = lane.first.isLeft;
    final laneEdge = isLeft ? commonPieBounds.left : commonPieBounds.right;
    final size = lane.first.owner.size;
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
          ? laneEdge -
                candidate.owner.series.dataLabels.outsideOffset -
                candidate.size.width
          : laneEdge + candidate.owner.series.dataLabels.outsideOffset;
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
      if (rect == null) continue;
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
    required PieDataLabelContent content,
    required LabelStyle? calloutStyle,
    required Color color,
    required FontWeight fontWeight,
  }) {
    final typography = theme.typographyTheme;
    final calloutTextStyle = calloutStyle?.textStyle;
    final resolvedFontSize =
        (calloutTextStyle?.fontSize ??
            typography.baseFontSize * typography.labelMultiplier) *
        textScaleFactor;
    return TextPainter(
      text: TextSpan(
        text: _labelText(slice, content),
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

  PieDataLabelContent _labelContentFor(PieDataLabelPosition placement) {
    if (series.dataLabels.position == placement) {
      return series.dataLabels.content;
    }
    assert(
      series.dataLabels.secondaryContent != null &&
          series.dataLabels.secondaryPosition == placement,
    );
    return series.dataLabels.secondaryContent!;
  }

  LabelStyle? _effectiveCalloutStyleFor(PieDataLabelPosition placement) {
    final configured = series.dataLabels.position == placement
        ? series.dataLabels.calloutStyle
        : series.dataLabels.secondaryCalloutStyle;
    return configured ?? theme.pieChartTheme.calloutStyle;
  }

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

  String _labelText(PieSliceGeometry slice, PieDataLabelContent content) {
    final category = slice.point.label!.trim();
    final value = RadialValueFormatters.value(series, slice.point.y);
    final percentage = RadialValueFormatters.share(series, slice.share);
    return switch (content) {
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
    final gradient =
        series.radialStyle.gradient ?? theme.pieChartTheme.gradient;
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
    final style = series.radialStyle;
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
    final radiusConfig = series.sliceRadiusConfig;
    final radiusValue = radiusConfig == null
        ? null
        : slice.point.pointStyle!.size;
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: slice.pointIndex,
      sourcePointIndices: slice.sourcePointIndices,
      plotPosition: slice.tooltipAnchor,
      semanticBounds: slice.path.getBounds(),
      point: slice.point,
      category: slice.point.label!.trim(),
      total: geometry.total,
      share: slice.share,
      formattedShare: RadialValueFormatters.share(series, slice.share),
      radiusValue: radiusValue,
      formattedRadiusValue: radiusValue == null
          ? null
          : RadialValueFormatters.radius(series, radiusValue),
      radiusLabel: radiusConfig?.label,
      groupLabel: groupLabel,
      groupName: groupName,
      groupOrdinal: groupOrdinal,
      groupCount: groupCount,
      formattedValue: RadialValueFormatters.value(series, slice.point.y),
      ordinal: visibleIndex + 1,
      count: geometry.slices.length,
      isSelected: _isSliceSelected(slice),
      isFocused: _isSliceFocused(slice),
    );
  }

  bool _isSliceSelected(PieSliceGeometry slice) =>
      slice.sourcePointIndices.every(selectedPointIndices.contains);

  bool _isSliceFocused(PieSliceGeometry slice) =>
      slice.sourcePointIndices.any(focusedPointIndices.contains);

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
      geometryCenter: geometryCenter,
      geometryInnerRadius: geometryInnerRadius,
      geometryOuterRadius: geometryOuterRadius,
      insideLabelRadiusFactor: insideLabelRadiusFactor,
      groupLabel: groupLabel,
      groupName: groupName,
      groupOrdinal: groupOrdinal,
      groupCount: groupCount,
      centerContentOverride: centerContentOverride,
      centerTotalOverride: centerTotalOverride,
      centerUnitOverride: centerUnitOverride,
      centerSelectionUsesOverride: centerSelectionUsesOverride,
      centerSelectedPointOverride: centerSelectedPointOverride,
      centerSelectedPointIndexOverride: centerSelectedPointIndexOverride,
      paintCenterContent: paintCenterContent,
      includeCenterSemantics: includeCenterSemantics,
      coordinateOutsideLabels: coordinateOutsideLabels,
      compositionBackdropBlur: compositionBackdropBlur,
      isHovered: isHovered ?? this.isHovered,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Resolves the exact padding shared by radial Canvas and widget overlays.
  static EdgeInsets geometryPaddingFor(
    RadialCategorySeries series,
    Size size,
    ChartTheme theme,
    double textScaleFactor,
  ) {
    final EdgeInsets labelPadding;
    if (!series.dataLabels.isVisible ||
        !series.dataLabels.hasLabelAt(PieDataLabelPosition.outside)) {
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
      series.radialStyle.borderWidth / 2,
      math.max(3, theme.focusBorderWidth) / 2,
    );
    final shadow = series.radialStyle.shadow ?? theme.pieChartTheme.shadow;
    final selectedElevation =
        series.radialStyle.selectedElevation ??
        theme.pieChartTheme.selectedElevation;
    final selectionStyle = series.selectionStyle;
    final usesLiftSelection =
        selectionStyle.effect == RadialSelectionEffect.lift;
    final maximumRadius =
        math.min(size.width, size.height) / 2 * series.radialStyle.radiusFactor;
    final selectionGeometryOverflow = usesLiftSelection
        ? maximumRadius * (selectionStyle.liftScale - 1) +
              selectionStyle.liftOffset +
              selectionStyle.backdropBlur * 2
        : series.radialStyle.selectionExplodeOffset;
    final shadowOverflow = _paintOverflowInsets(
      shadow,
      radialOffset: strokeOverflow,
    );
    final selectedOverflow = _paintOverflowInsets(
      selectedElevation,
      radialOffset: strokeOverflow + selectionGeometryOverflow,
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

/// Deterministic center text resolved from one Donut and its durable
/// selection state.
class DonutCenterPresentation {
  const DonutCenterPresentation({
    required this.label,
    required this.value,
    required this.semanticLabel,
    required this.selectedPointIndex,
  });

  final String? label;
  final String value;
  final String semanticLabel;
  final int? selectedPointIndex;
}

class _PieLabelCandidate {
  _PieLabelCandidate({
    required this.owner,
    required this.slice,
    required this.painter,
    required this.color,
    required this.isLeft,
    required this.size,
  });

  final PieSeriesElement owner;
  final PieSliceGeometry slice;
  final TextPainter painter;
  final Color color;
  final bool isLeft;
  final Size size;
  Rect? labelRect;
}
