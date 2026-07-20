import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../axis/polar_category_scale.dart';
import '../axis/polar_numeric_scale.dart';
import '../formatting/multi_axis_value_formatter.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/element_types.dart';
import '../layout/polar_column_geometry.dart';
import '../layout/radial_pane_geometry.dart';
import '../models/chart_theme.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_selection_style.dart';

/// Axis, grid, mark, label, and interaction element for Polar Column V1.
class PolarColumnSeriesElement implements DataHitElement {
  factory PolarColumnSeriesElement({
    required PolarColumnChartSeries series,
    required PolarChartConfig config,
    required Size size,
    required ChartTheme theme,
    int seriesIndex = 0,
    int seriesCount = 1,
    Iterable<double>? numericScaleValues,
    bool paintGrid = true,
    bool paintAxisLabels = true,
    bool preferSeriesColor = false,
    Set<int> focusedPointIndices = const <int>{},
    Set<int> selectedPointIndices = const <int>{},
    double revealProgress = 1,
    double textScaleFactor = 1,
    bool isSelected = false,
    bool isHovered = false,
  }) {
    if (!textScaleFactor.isFinite || textScaleFactor <= 0) {
      throw ArgumentError.value(
        textScaleFactor,
        'textScaleFactor',
        'Value must be finite and positive',
      );
    }
    final layout = _resolveLayout(
      series: series,
      config: config,
      size: size,
      theme: theme,
      revealProgress: revealProgress,
      textScaleFactor: textScaleFactor,
      numericScaleValues: numericScaleValues,
      seriesIndex: seriesIndex,
      seriesCount: seriesCount,
    );
    return PolarColumnSeriesElement._(
      series: series,
      config: config,
      size: size,
      theme: theme,
      seriesIndex: seriesIndex,
      seriesCount: seriesCount,
      paintGrid: paintGrid,
      paintAxisLabels: paintAxisLabels,
      preferSeriesColor: preferSeriesColor,
      focusedPointIndices: focusedPointIndices,
      selectedPointIndices: selectedPointIndices,
      revealProgress: revealProgress,
      textScaleFactor: textScaleFactor,
      layout: layout,
      isSelected: isSelected,
      isHovered: isHovered,
    );
  }

  const PolarColumnSeriesElement._({
    required this.series,
    required this.config,
    required this.size,
    required this.theme,
    required this.seriesIndex,
    required this.seriesCount,
    required this.paintGrid,
    required this.paintAxisLabels,
    required this.preferSeriesColor,
    required this.focusedPointIndices,
    required this.selectedPointIndices,
    required this.revealProgress,
    required this.textScaleFactor,
    required _PolarColumnResolvedLayout layout,
    required this.isSelected,
    required this.isHovered,
  }) : _layout = layout;

  @override
  final PolarColumnChartSeries series;

  final PolarChartConfig config;
  final Size size;
  final ChartTheme theme;

  @override
  final int seriesIndex;

  /// Number of compatible series sharing this polar pane.
  final int seriesCount;

  /// Whether this element owns the composition-wide grid layer.
  final bool paintGrid;

  /// Whether this element owns the composition-wide axis-label layer.
  final bool paintAxisLabels;

  /// Uses a stable series palette color when no explicit color is supplied.
  ///
  /// Single-series Polar Column keeps its category palette. Layered
  /// compositions use one fallback color per series so the layers remain
  /// visually identifiable.
  final bool preferSeriesColor;

  final Set<int> focusedPointIndices;
  final Set<int> selectedPointIndices;
  final double revealProgress;
  final double textScaleFactor;
  final _PolarColumnResolvedLayout _layout;

  /// Immutable geometry shared by painting, tooltips, and hit testing.
  PolarColumnGeometry get geometry => _layout.geometry;

  /// Resolved pane, exposed for deterministic renderer tests.
  RadialPaneGeometry get pane => _layout.pane;

  /// Resolved numeric scale, exposed for axis and Rose assertions.
  PolarNumericScale get numericScale => _layout.numericScale;

  /// Angular labels that fit the resolved pane at the active text scale.
  ///
  /// The stable ordinal list is exposed for deterministic compact-layout and
  /// accessibility tests. Table and semantic data remain complete even when
  /// visual labels are thinned.
  List<int> get visibleAngularLabelIndices =>
      _layout.visibleAngularLabelIndices;

  /// Direct value labels with enough tangential and radial room to remain
  /// legible. Hidden values remain available through interaction and semantics.
  List<int> get visibleDataLabelIndices {
    final colors = resolvedMarkColors;
    return List<int>.unmodifiable([
      for (final mark in geometry.marks)
        if (_dataLabelFits(mark, color: colors[mark.index])) mark.index,
    ]);
  }

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

  /// Effective fill colors in stable category order.
  List<Color> get resolvedMarkColors => List<Color>.unmodifiable([
    for (final (index, point) in series.points.indexed)
      point.pointStyle?.color ??
          series.color ??
          theme.seriesTheme.colors[(preferSeriesColor ? seriesIndex : index) %
              theme.seriesTheme.colors.length],
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    if (paintGrid) _paintGrid(canvas);
    _paintMarks(canvas);
    if (paintAxisLabels) _paintAxisLabels(canvas);
  }

  void _paintGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridStyle.majorWidth
      ..color = theme.gridStyle.majorColor;
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.axisStyle.lineWidth
      ..color = theme.axisStyle.lineColor;

    if (config.radialAxis.showGridLines) {
      for (var tick = 0; tick < config.radialAxis.tickCount; tick++) {
        final fraction = tick / (config.radialAxis.tickCount - 1);
        final value = numericScale.minimum + numericScale.domainSpan * fraction;
        final radius = numericScale.valueToRadius(value);
        final rect = Rect.fromCircle(center: pane.center, radius: radius);
        final path = Path()
          ..addArc(rect, pane.startAngle, pane.signedSweepAngle);
        canvas.drawPath(
          path,
          tick == 0 || tick == config.radialAxis.tickCount - 1
              ? axisPaint
              : gridPaint,
        );
      }
    }

    if (config.angularAxis.showGridLines) {
      for (final band in _layout.categoryScale.bands) {
        final start =
            pane.center +
            Offset.fromDirection(band.startAngle, pane.innerRadius);
        final end =
            pane.center +
            Offset.fromDirection(band.startAngle, pane.outerRadius);
        canvas.drawLine(start, end, gridPaint);
      }
      if (pane.sweepAngle < math.pi * 2 - 1e-9) {
        final end = pane.endAngle;
        canvas.drawLine(
          pane.center + Offset.fromDirection(end, pane.innerRadius),
          pane.center + Offset.fromDirection(end, pane.outerRadius),
          gridPaint,
        );
      }
    }
  }

  void _paintMarks(Canvas canvas) {
    final colors = resolvedMarkColors;
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
          _paintMark(canvas, mark, colors[mark.index]);
        }
      }
      canvas.restore();
      for (final mark in geometry.marks) {
        if (selectedPointIndices.contains(mark.index)) {
          _paintMark(canvas, mark, colors[mark.index]);
        }
      }
      return;
    }

    for (final mark in geometry.marks) {
      _paintMark(canvas, mark, colors[mark.index]);
    }
  }

  void _paintMark(Canvas canvas, PolarColumnMarkGeometry mark, Color color) {
    if (!mark.isVisible) return;
    final selected = selectedPointIndices.contains(mark.index);
    final focused = focusedPointIndices.contains(mark.index);
    final path = _displayPath(mark);

    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.36)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = color.withValues(alpha: color.a * series.polarStyle.opacity),
    );
    if (series.polarStyle.borderWidth > 0 || selected || focused) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true
          ..strokeWidth = selected || focused
              ? math.max(2, series.polarStyle.borderWidth)
              : series.polarStyle.borderWidth
          ..color = selected || focused
              ? theme.focusBorderColor
              : (series.polarStyle.borderColor ?? theme.axisStyle.lineColor),
      );
    }

    if (series.polarStyle.showDataLabels &&
        _dataLabelFits(mark, color: color)) {
      _paintText(
        canvas,
        _dataLabelText(mark),
        _displayPoint(mark, mark.labelAnchor),
        _dataLabelStyle(color),
        center: true,
      );
    }
  }

  bool _dataLabelFits(PolarColumnMarkGeometry mark, {required Color color}) {
    if (!series.polarStyle.showDataLabels || !mark.isVisible) return false;
    final textSize = _measureText(
      _dataLabelText(mark),
      _dataLabelStyle(color),
      textScaleFactor,
      maxWidth: size.width,
    );
    final radialDepth = mark.valueRadius - mark.baselineRadius;
    final labelRadius = mark.baselineRadius + radialDepth * 0.5;
    final tangentialWidth = mark.band.sweepAngle.abs() * labelRadius;
    return radialDepth >= textSize.height + 4 * textScaleFactor &&
        tangentialWidth >= textSize.width + 6 * textScaleFactor;
  }

  String _dataLabelText(PolarColumnMarkGeometry mark) =>
      MultiAxisValueFormatter.format(value: mark.value);

  TextStyle _dataLabelStyle(Color color) => theme.axisStyle.labelStyle.copyWith(
    color: _contrastingTextColor(color),
    fontWeight: FontWeight.w600,
  );

  void _paintAxisLabels(Canvas canvas) {
    if (config.angularAxis.showLabels) {
      for (final index in visibleAngularLabelIndices) {
        final band = _layout.categoryScale.bands[index];
        final anchor =
            pane.center +
            Offset.fromDirection(
              band.centerAngle,
              pane.outerRadius + _angularLabelOffset(size, textScaleFactor),
            );
        _paintText(
          canvas,
          band.category,
          anchor,
          theme.axisStyle.labelStyle,
          center: true,
        );
      }
    }

    if (config.radialAxis.showLabels) {
      for (var tick = 0; tick < config.radialAxis.tickCount; tick++) {
        final fraction = tick / (config.radialAxis.tickCount - 1);
        final value = numericScale.minimum + numericScale.domainSpan * fraction;
        final radius = numericScale.valueToRadius(value);
        final anchor =
            pane.center + Offset.fromDirection(pane.startAngle, radius);
        _paintText(
          canvas,
          MultiAxisValueFormatter.format(value: value),
          anchor + Offset(4 * textScaleFactor, 2 * textScaleFactor),
          theme.axisStyle.labelStyle.copyWith(fontSize: 10),
        );
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool center = false,
  }) {
    final painter =
        TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(textScaleFactor),
          maxLines: 1,
          ellipsis: '…',
        )..layout(
          maxWidth: math.min(
            size.width,
            math.max(24 * textScaleFactor, size.width * 0.22),
          ),
        );
    final rawOffset = center
        ? anchor - Offset(painter.width / 2, painter.height / 2)
        : anchor;
    final offset = Offset(
      rawOffset.dx.clamp(0, math.max(0, size.width - painter.width)),
      rawOffset.dy.clamp(0, math.max(0, size.height - painter.height)),
    );
    painter.paint(canvas, offset);
  }

  ChartDataHit _dataHitForMark(PolarColumnMarkGeometry mark) {
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

  PolarColumnMarkGeometry? _markAt(Offset position) {
    for (final mark in geometry.marks.reversed) {
      if (mark.isVisible && _displayPath(mark).contains(position)) return mark;
    }
    return null;
  }

  Path _displayPath(PolarColumnMarkGeometry mark) {
    final transform = _selectionTransform(mark);
    return transform == null
        ? mark.path
        : mark.path.transform(transform.storage);
  }

  Offset _displayPoint(PolarColumnMarkGeometry mark, Offset point) {
    final transform = _selectionTransform(mark);
    if (transform == null) return point;
    final values = transform.storage;
    return Offset(
      values[0] * point.dx + values[4] * point.dy + values[12],
      values[1] * point.dx + values[5] * point.dy + values[13],
    );
  }

  Matrix4? _selectionTransform(PolarColumnMarkGeometry mark) {
    if (!selectedPointIndices.contains(mark.index)) return null;
    final style = series.selectionStyle;
    final offset = Offset.fromDirection(
      mark.band.centerAngle,
      style.liftOffset,
    );
    final scale = style.effect == RadialSelectionEffect.lift
        ? style.liftScale
        : 1.0;
    final pivot = mark.labelAnchor;
    return Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0, 1)
      ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
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
  PolarColumnSeriesElement copyWith({bool? isHovered, bool? isSelected}) =>
      PolarColumnSeriesElement(
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
        preferSeriesColor: preferSeriesColor,
        focusedPointIndices: focusedPointIndices,
        selectedPointIndices: selectedPointIndices,
        revealProgress: revealProgress,
        textScaleFactor: textScaleFactor,
        isHovered: isHovered ?? this.isHovered,
        isSelected: isSelected ?? this.isSelected,
      );
}

@immutable
class _PolarColumnResolvedLayout {
  const _PolarColumnResolvedLayout({
    required this.pane,
    required this.categoryScale,
    required this.numericScale,
    required this.geometry,
    required this.visibleAngularLabelIndices,
  });

  final RadialPaneGeometry pane;
  final PolarCategoryScale categoryScale;
  final PolarNumericScale numericScale;
  final PolarColumnGeometry geometry;
  final List<int> visibleAngularLabelIndices;
}

_PolarColumnResolvedLayout _resolveLayout({
  required PolarColumnChartSeries series,
  required PolarChartConfig config,
  required Size size,
  required ChartTheme theme,
  required double revealProgress,
  required double textScaleFactor,
  Iterable<double>? numericScaleValues,
  required int seriesIndex,
  required int seriesCount,
}) {
  config.validate();
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.width <= 0 ||
      size.height <= 0) {
    throw ArgumentError.value(size, 'size', 'Size must be finite and positive');
  }
  if (!revealProgress.isFinite || revealProgress < 0 || revealProgress > 1) {
    throw ArgumentError.value(
      revealProgress,
      'revealProgress',
      'Value must be finite and in [0, 1]',
    );
  }

  final paneConfig = config.pane;
  final reservedLabelInset = math.min(
    34 * textScaleFactor,
    size.shortestSide * 0.28,
  );
  final pane = RadialPaneGeometry.resolve(
    viewportBounds: Offset.zero & size,
    viewportInsets: const EdgeInsets.all(8),
    reservedLabelInsets: config.angularAxis.showLabels
        ? EdgeInsets.all(reservedLabelInset)
        : EdgeInsets.zero,
    innerRadiusFactor: paneConfig.innerRadiusFactor,
    outerRadiusFactor: paneConfig.outerRadiusFactor,
    startAngle: paneConfig.startAngleDegrees * math.pi / 180,
    sweepAngle: paneConfig.sweepAngleDegrees * math.pi / 180,
    clockwise: paneConfig.clockwise,
  );
  final categoryScale = PolarCategoryScale(
    pane: pane,
    categories: series.categories,
    innerPadding: config.angularAxis.innerPadding,
    outerPadding: config.angularAxis.outerPadding,
  );
  final scaleMode =
      config.radialAxis.scaleMode ??
      (series.preset == PolarColumnPreset.rose
          ? PolarRadialScaleMode.areaCorrect
          : PolarRadialScaleMode.linear);
  final numericScale = PolarNumericScale.fromValues(
    pane: pane,
    values: numericScaleValues ?? series.points.map((point) => point.y),
    minimum: config.radialAxis.minimum,
    maximum: config.radialAxis.maximum,
    mode: switch (scaleMode) {
      PolarRadialScaleMode.linear => PolarNumericScaleMode.linear,
      PolarRadialScaleMode.areaCorrect => PolarNumericScaleMode.areaCorrect,
    },
  );
  final baseline = numericScale.minimum;
  final animatedValues = <double>[
    for (final point in series.points)
      baseline + (point.y - baseline) * revealProgress,
  ];
  final geometry = PolarColumnGeometryCalculator.calculate(
    categoryScale: categoryScale,
    numericScale: numericScale,
    values: animatedValues,
    baseline: baseline,
    cornerRadius: series.polarStyle.cornerRadius * revealProgress,
    groupIndex: config.composition.mode == PolarColumnCompositionMode.grouped
        ? seriesIndex
        : 0,
    groupCount: config.composition.mode == PolarColumnCompositionMode.grouped
        ? seriesCount
        : 1,
    groupInnerPadding: config.composition.groupInnerPadding,
  );
  final visibleAngularLabelIndices = config.angularAxis.showLabels
      ? _resolveVisibleAngularLabelIndices(
          categoryScale: categoryScale,
          pane: pane,
          size: size,
          style: theme.axisStyle.labelStyle,
          textScaleFactor: textScaleFactor,
        )
      : const <int>[];
  return _PolarColumnResolvedLayout(
    pane: pane,
    categoryScale: categoryScale,
    numericScale: numericScale,
    geometry: geometry,
    visibleAngularLabelIndices: List<int>.unmodifiable(
      visibleAngularLabelIndices,
    ),
  );
}

List<int> _resolveVisibleAngularLabelIndices({
  required PolarCategoryScale categoryScale,
  required RadialPaneGeometry pane,
  required Size size,
  required TextStyle style,
  required double textScaleFactor,
}) {
  final bands = categoryScale.bands;
  if (bands.isEmpty) return const <int>[];

  final maximumLabelWidth = bands.fold<double>(0, (maximum, band) {
    final measured = _measureText(
      band.category,
      style,
      textScaleFactor,
      maxWidth: math.max(24, size.width * 0.22),
    );
    return math.max(maximum, measured.width);
  });
  final labelRadius =
      pane.outerRadius + _angularLabelOffset(size, textScaleFactor);
  final availableArcLength = pane.sweepAngle.abs() * labelRadius;
  final minimumSpacing = math.max(
    24 * textScaleFactor,
    math.min(
      88 * textScaleFactor,
      maximumLabelWidth * 0.55 + 8 * textScaleFactor,
    ),
  );
  final maximumVisible = math.max(
    1,
    math.min(bands.length, (availableArcLength / minimumSpacing).floor()),
  );
  final stride = (bands.length / maximumVisible).ceil();
  return <int>[
    for (var index = 0; index < bands.length; index += stride) index,
  ];
}

double _angularLabelOffset(Size size, double textScaleFactor) =>
    math.min(14 * textScaleFactor, size.shortestSide * 0.08);

Size _measureText(
  String text,
  TextStyle style,
  double textScaleFactor, {
  required double maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(textScaleFactor),
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  return painter.size;
}

Color _contrastingTextColor(Color background) =>
    background.computeLuminance() > 0.46 ? Colors.black : Colors.white;
