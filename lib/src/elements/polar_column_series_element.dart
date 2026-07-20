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
import '../utils/dashed_path.dart';

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
    List<double>? stackStarts,
    List<double>? stackEnds,
    List<bool>? stackExteriorEnds,
    bool paintGrid = true,
    bool paintAxisLabels = true,
    bool paintDataLabels = true,
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
      stackStarts: stackStarts,
      stackEnds: stackEnds,
      stackExteriorEnds: stackExteriorEnds,
      seriesIndex: seriesIndex,
      seriesCount: seriesCount,
    );
    final visibleDataLabelIndices = _resolveVisibleDataLabelIndices(
      series: series,
      geometry: layout.geometry,
      size: size,
      theme: theme,
      textScaleFactor: textScaleFactor,
    );
    return PolarColumnSeriesElement._(
      series: series,
      config: config,
      size: size,
      theme: theme,
      seriesIndex: seriesIndex,
      seriesCount: seriesCount,
      stackStarts: stackStarts,
      stackEnds: stackEnds,
      stackExteriorEnds: stackExteriorEnds,
      paintGrid: paintGrid,
      paintAxisLabels: paintAxisLabels,
      paintDataLabels: paintDataLabels,
      preferSeriesColor: preferSeriesColor,
      focusedPointIndices: focusedPointIndices,
      selectedPointIndices: selectedPointIndices,
      revealProgress: revealProgress,
      textScaleFactor: textScaleFactor,
      layout: layout,
      visibleDataLabelIndices: visibleDataLabelIndices,
      isSelected: isSelected,
      isHovered: isHovered,
    );
  }

  PolarColumnSeriesElement._({
    required this.series,
    required this.config,
    required this.size,
    required this.theme,
    required this.seriesIndex,
    required this.seriesCount,
    required this.stackStarts,
    required this.stackEnds,
    required this.stackExteriorEnds,
    required this.paintGrid,
    required this.paintAxisLabels,
    required this.paintDataLabels,
    required this.preferSeriesColor,
    required this.focusedPointIndices,
    required this.selectedPointIndices,
    required this.revealProgress,
    required this.textScaleFactor,
    required _PolarColumnResolvedLayout layout,
    required List<int> visibleDataLabelIndices,
    required this.isSelected,
    required this.isHovered,
  }) : _layout = layout,
       _visibleDataLabelIndices = List<int>.unmodifiable(
         visibleDataLabelIndices,
       ),
       _visibleDataLabelIndexSet = Set<int>.unmodifiable(
         visibleDataLabelIndices,
       );

  @override
  final PolarColumnChartSeries series;

  final PolarChartConfig config;
  final Size size;
  final ChartTheme theme;

  @override
  final int seriesIndex;

  /// Number of compatible series sharing this polar pane.
  final int seriesCount;

  /// Cumulative numeric stack starts in stable category order.
  final List<double>? stackStarts;

  /// Cumulative numeric stack ends in stable category order.
  final List<double>? stackEnds;

  /// Exposed signed-stack endpoints in stable category order.
  final List<bool>? stackExteriorEnds;

  /// Whether this element owns the composition-wide grid layer.
  final bool paintGrid;

  /// Whether this element owns the composition-wide axis-label layer.
  final bool paintAxisLabels;

  /// Whether this element paints its direct value labels.
  ///
  /// Multi-series compositions defer these labels to one shared foreground
  /// pass so grid lines remain visible without crossing the label text.
  final bool paintDataLabels;

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

  /// Numeric origin shared by ordinary and diverging stacked marks.
  double get baseline => _layout.baseline;

  /// Angular labels that fit the resolved pane at the active text scale.
  ///
  /// The stable ordinal list is exposed for deterministic compact-layout and
  /// accessibility tests. Table and semantic data remain complete even when
  /// visual labels are thinned.
  List<int> get visibleAngularLabelIndices =>
      _layout.visibleAngularLabelIndices;

  /// Angular grid spokes retained after deterministic density thinning.
  List<int> get visibleAngularGridIndices => _layout.visibleAngularGridIndices;

  /// Direct value labels with enough tangential and radial room to remain
  /// legible. Hidden values remain available through interaction and semantics.
  List<int> get visibleDataLabelIndices => _visibleDataLabelIndices;

  final List<int> _visibleDataLabelIndices;
  final Set<int> _visibleDataLabelIndexSet;

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
    if (paintGrid) {
      paintCompositionGrid(canvas);
    }
    _paintMarks(canvas);
    if (paintDataLabels) paintCompositionDataLabels(canvas);
    if (paintAxisLabels) paintCompositionAxisLabels(canvas);
  }

  /// Paints the pane grid and thresholds for one complete composition.
  ///
  /// This is public within the package so [PolarColumnCompositionOverlayElement]
  /// can place shared structure above every opaque series mark.
  void paintCompositionGrid(Canvas canvas) {
    _paintGrid(canvas);
    _paintThresholds(canvas);
  }

  /// Repaints shared structure above opaque marks without overpowering them.
  void paintCompositionGridOverlay(Canvas canvas) {
    _paintGrid(
      canvas,
      gridOpacity: 0.28,
      axisOpacity: 0.62,
      includeAngularGrid: false,
    );
    _paintThresholds(canvas);
  }

  /// Paints direct labels after composition-wide grid structure.
  void paintCompositionDataLabels(Canvas canvas) {
    final colors = resolvedMarkColors;
    for (final mark in geometry.marks) {
      if (!mark.isVisible ||
          !series.polarStyle.showDataLabels ||
          !_visibleDataLabelIndexSet.contains(mark.index)) {
        continue;
      }
      _paintText(
        canvas,
        _dataLabelText(mark),
        _displayPoint(mark, mark.labelAnchor),
        _dataLabelStyle(colors[mark.index]),
        center: true,
      );
    }
  }

  /// Paints angular and radial labels above the full composition.
  void paintCompositionAxisLabels(Canvas canvas) => _paintAxisLabels(canvas);

  void _paintThresholds(Canvas canvas) {
    for (final threshold in config.thresholds) {
      if (threshold.value < numericScale.minimum ||
          threshold.value > numericScale.maximum) {
        continue;
      }
      final color = threshold.color ?? theme.focusBorderColor;
      final radius = numericScale.valueToRadius(threshold.value);
      final source = _radialArcPath(radius);
      canvas.drawPath(
        threshold.dashPattern.isEmpty
            ? source
            : createDashedPath(source, threshold.dashPattern),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = threshold.width
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = color,
      );
      if (threshold.label case final label?) {
        final labelAngle = pane.startAngle + pane.signedSweepAngle * 0.115;
        final anchor =
            pane.center +
            Offset.fromDirection(labelAngle, radius) +
            Offset.fromDirection(labelAngle, 6 * textScaleFactor);
        _paintText(
          canvas,
          label,
          anchor,
          theme.axisStyle.labelStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          center: true,
        );
      }
    }
  }

  void _paintGrid(
    Canvas canvas, {
    double gridOpacity = 1,
    double axisOpacity = 1,
    bool includeAngularGrid = true,
  }) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridStyle.majorWidth
      ..color = theme.gridStyle.majorColor.withValues(
        alpha: theme.gridStyle.majorColor.a * gridOpacity,
      );
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.axisStyle.lineWidth
      ..color = theme.axisStyle.lineColor.withValues(
        alpha: theme.axisStyle.lineColor.a * axisOpacity,
      );

    if (config.radialAxis.showGridLines) {
      for (var tick = 0; tick < config.radialAxis.tickCount; tick++) {
        final fraction = tick / (config.radialAxis.tickCount - 1);
        final value = numericScale.minimum + numericScale.domainSpan * fraction;
        final radius = numericScale.valueToRadius(value);
        canvas.drawPath(
          _radialArcPath(radius),
          tick == 0 || tick == config.radialAxis.tickCount - 1
              ? axisPaint
              : gridPaint,
        );
      }
    }

    if (_layout.baseline > numericScale.minimum &&
        _layout.baseline < numericScale.maximum) {
      final radius = numericScale.valueToRadius(_layout.baseline);
      final rect = Rect.fromCircle(center: pane.center, radius: radius);
      final baselinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, theme.axisStyle.lineWidth)
        ..color = theme.axisStyle.lineColor;
      if (_isFullSweep) {
        canvas.drawCircle(pane.center, radius, baselinePaint);
      } else {
        canvas.drawArc(
          rect,
          pane.startAngle,
          pane.signedSweepAngle,
          false,
          baselinePaint,
        );
      }
    }

    if (includeAngularGrid && config.angularAxis.showGridLines) {
      for (final index in visibleAngularGridIndices) {
        final band = _layout.categoryScale.bands[index];
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

  bool get _isFullSweep => pane.sweepAngle >= math.pi * 2 - 1e-9;

  Path _radialArcPath(double radius) {
    final rect = Rect.fromCircle(center: pane.center, radius: radius);
    return _isFullSweep
        ? (Path()..addOval(rect))
        : (Path()..addArc(rect, pane.startAngle, pane.signedSweepAngle));
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
    if (!mark.isVisible &&
        mark.targetPath == null &&
        mark.intervalWhiskerPath == null &&
        mark.intervalBandPath == null) {
      return;
    }
    final selected = selectedPointIndices.contains(mark.index);
    final focused = focusedPointIndices.contains(mark.index);
    final path = _displayPath(mark);

    if (selected && mark.isVisible) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.36)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }
    if (mark.isVisible) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = true
          ..color = color.withValues(
            alpha: color.a * series.polarStyle.opacity,
          ),
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
    }

    _paintInterval(canvas, mark);

    if (mark.targetPath case final targetPath?) {
      final style = series.targetMarkerStyle;
      final targetColor = style.color ?? theme.focusBorderColor;
      canvas.drawPath(
        targetPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.width
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = targetColor.withValues(
            alpha: targetColor.a * style.opacity,
          ),
      );
    }
  }

  void _paintInterval(Canvas canvas, PolarColumnMarkGeometry mark) {
    final style = series.intervalStyle;
    final color = style.color ?? theme.axisStyle.lineColor;
    switch (style.display) {
      case PolarColumnIntervalDisplay.whisker:
        final path = mark.intervalWhiskerPath;
        if (path == null) return;
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.width + 2.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true
            ..color = theme.backgroundColor.withValues(alpha: 0.82),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true
            ..color = color.withValues(alpha: color.a * style.opacity),
        );
        break;
      case PolarColumnIntervalDisplay.band:
        final path = mark.intervalBandPath;
        if (path == null) {
          final pointPath = mark.intervalWhiskerPath;
          if (pointPath == null) return;
          canvas.drawPath(
            pointPath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.width
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..isAntiAlias = true
              ..color = color.withValues(alpha: color.a * style.opacity),
          );
          return;
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..isAntiAlias = true
            ..color = color.withValues(alpha: color.a * style.opacity * 0.22),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.width
            ..isAntiAlias = true
            ..color = color.withValues(alpha: color.a * style.opacity),
        );
        break;
    }
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
    final value = MultiAxisValueFormatter.format(
      value: point.y,
      unit: series.unit,
    );
    final target = mark.targetValue == null
        ? ''
        : ' · target ${MultiAxisValueFormatter.format(value: mark.targetValue!, unit: series.unit)}';
    final interval =
        mark.intervalLowerValue == null || mark.intervalUpperValue == null
        ? ''
        : ' · interval ${MultiAxisValueFormatter.format(value: mark.intervalLowerValue!, unit: series.unit)} to ${MultiAxisValueFormatter.format(value: mark.intervalUpperValue!, unit: series.unit)}';
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: mark.index,
      plotPosition: _displayPoint(mark, mark.tooltipAnchor),
      semanticBounds: path.getBounds(),
      point: point,
      category: mark.category,
      formattedValue: '$value$target$interval',
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
        stackStarts: stackStarts,
        stackEnds: stackEnds,
        stackExteriorEnds: stackExteriorEnds,
        numericScaleValues: <double>[
          numericScale.minimum,
          numericScale.maximum,
        ],
        paintGrid: paintGrid,
        paintAxisLabels: paintAxisLabels,
        paintDataLabels: paintDataLabels,
        preferSeriesColor: preferSeriesColor,
        focusedPointIndices: focusedPointIndices,
        selectedPointIndices: selectedPointIndices,
        revealProgress: revealProgress,
        textScaleFactor: textScaleFactor,
        isHovered: isHovered ?? this.isHovered,
        isSelected: isSelected ?? this.isSelected,
      );
}

/// One cached foreground pass shared by every Polar Column series in a pane.
///
/// Opaque stacked marks must all paint before the grid, thresholds, direct
/// labels, and axes. Keeping this as a data-layer element preserves picture
/// caching while preventing later series from erasing composition structure.
class PolarColumnCompositionOverlayElement implements DataSeriesElement {
  PolarColumnCompositionOverlayElement({
    required List<PolarColumnSeriesElement> seriesElements,
  }) : assert(seriesElements.isNotEmpty),
       seriesElements = List<PolarColumnSeriesElement>.unmodifiable(
         seriesElements,
       );

  /// Series elements in stable declaration order.
  final List<PolarColumnSeriesElement> seriesElements;

  PolarColumnSeriesElement get _gridOwner => seriesElements.first;
  PolarColumnSeriesElement get _axisOwner => seriesElements.last;

  @override
  PolarColumnChartSeries get series => _axisOwner.series;

  @override
  int get seriesIndex => seriesElements.length;

  @override
  int get pointCount => 0;

  @override
  String get id => '${series.id}-polar-composition-overlay';

  @override
  Rect get bounds => _gridOwner.bounds;

  @override
  ChartElementType get elementType => ChartElementType.series;

  @override
  int get priority => ElementPriority.series + 2;

  @override
  int get renderOrder => RenderOrder.series;

  @override
  bool get isSelected => false;

  @override
  bool get isHovered => false;

  @override
  bool get isSelectable => false;

  @override
  bool get isDraggable => false;

  @override
  bool hitTest(Offset position) => false;

  @override
  void paint(Canvas canvas, Size size) {
    _gridOwner.paintCompositionGridOverlay(canvas);
    for (final element in seriesElements) {
      element.paintCompositionDataLabels(canvas);
    }
    _axisOwner.paintCompositionAxisLabels(canvas);
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
  PolarColumnCompositionOverlayElement copyWith({
    bool? isHovered,
    bool? isSelected,
  }) => this;
}

@immutable
class _PolarColumnResolvedLayout {
  const _PolarColumnResolvedLayout({
    required this.pane,
    required this.categoryScale,
    required this.numericScale,
    required this.geometry,
    required this.visibleAngularLabelIndices,
    required this.visibleAngularGridIndices,
    required this.baseline,
  });

  final RadialPaneGeometry pane;
  final PolarCategoryScale categoryScale;
  final PolarNumericScale numericScale;
  final PolarColumnGeometry geometry;
  final List<int> visibleAngularLabelIndices;
  final List<int> visibleAngularGridIndices;
  final double baseline;
}

_PolarColumnResolvedLayout _resolveLayout({
  required PolarColumnChartSeries series,
  required PolarChartConfig config,
  required Size size,
  required ChartTheme theme,
  required double revealProgress,
  required double textScaleFactor,
  Iterable<double>? numericScaleValues,
  List<double>? stackStarts,
  List<double>? stackEnds,
  List<bool>? stackExteriorEnds,
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
  final baseline = _resolveBaseline(numericScale);
  final animatedStarts = stackStarts == null
      ? List<double>.filled(series.points.length, baseline)
      : [for (final value in stackStarts) value * revealProgress];
  final animatedEnds = stackEnds == null
      ? [
          for (final point in series.points)
            baseline + (point.y - baseline) * revealProgress,
        ]
      : [for (final value in stackEnds) value * revealProgress];
  final geometry = PolarColumnGeometryCalculator.calculate(
    categoryScale: categoryScale,
    numericScale: numericScale,
    values: [for (final point in series.points) point.y],
    baseline: baseline,
    radialStarts: animatedStarts,
    radialEnds: animatedEnds,
    stackExteriorEnds: stackExteriorEnds,
    targetValues: series.targetValues,
    targetLengthFactor: series.targetMarkerStyle.lengthFactor,
    intervalLowerValues: series.intervalLowerValues,
    intervalUpperValues: series.intervalUpperValues,
    intervalCapLengthFactor: series.intervalStyle.capLengthFactor,
    intervalBandLengthFactor: series.intervalStyle.bandLengthFactor,
    cornerRadius: series.polarStyle.cornerRadius * revealProgress,
    cornerRadiusMode: series.polarStyle.cornerRadiusMode,
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
          maximumVisible: config.angularAxis.maximumVisibleLabels,
        )
      : const <int>[];
  final visibleAngularGridIndices = config.angularAxis.showGridLines
      ? _resolveVisibleAngularGridIndices(
          categoryScale: categoryScale,
          pane: pane,
          textScaleFactor: textScaleFactor,
          maximumVisible: config.angularAxis.maximumVisibleGridLines,
        )
      : const <int>[];
  return _PolarColumnResolvedLayout(
    pane: pane,
    categoryScale: categoryScale,
    numericScale: numericScale,
    geometry: geometry,
    baseline: baseline,
    visibleAngularLabelIndices: List<int>.unmodifiable(
      visibleAngularLabelIndices,
    ),
    visibleAngularGridIndices: List<int>.unmodifiable(
      visibleAngularGridIndices,
    ),
  );
}

double _resolveBaseline(PolarNumericScale scale) {
  if (scale.minimum <= 0 && scale.maximum >= 0) return 0;
  return scale.minimum > 0 ? scale.minimum : scale.maximum;
}

List<int> _resolveVisibleAngularLabelIndices({
  required PolarCategoryScale categoryScale,
  required RadialPaneGeometry pane,
  required Size size,
  required TextStyle style,
  required double textScaleFactor,
  required int maximumVisible,
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
  final resolvedMaximumVisible = math.max(
    1,
    math.min(
      maximumVisible,
      math.min(bands.length, (availableArcLength / minimumSpacing).floor()),
    ),
  );
  return _thinOrdinalIndices(<int>[
    for (var index = 0; index < bands.length; index++) index,
  ], resolvedMaximumVisible);
}

List<int> _resolveVisibleAngularGridIndices({
  required PolarCategoryScale categoryScale,
  required RadialPaneGeometry pane,
  required double textScaleFactor,
  required int maximumVisible,
}) {
  final count = categoryScale.bands.length;
  if (count == 0) return const <int>[];
  final availableArcLength = pane.sweepAngle.abs() * pane.outerRadius;
  final spatialMaximum = math.max(
    1,
    (availableArcLength / math.max(4, 4 * textScaleFactor)).floor(),
  );
  return _thinOrdinalIndices(<int>[
    for (var index = 0; index < count; index++) index,
  ], math.min(maximumVisible, spatialMaximum));
}

List<int> _resolveVisibleDataLabelIndices({
  required PolarColumnChartSeries series,
  required PolarColumnGeometry geometry,
  required Size size,
  required ChartTheme theme,
  required double textScaleFactor,
}) {
  if (!series.polarStyle.showDataLabels) return const <int>[];
  final style = theme.axisStyle.labelStyle.copyWith(
    fontWeight: FontWeight.w600,
  );
  final candidates = <int>[];
  for (final mark in geometry.marks) {
    if (!mark.isVisible) continue;
    final radialDepth = (mark.valueRadius - mark.baselineRadius).abs();
    final labelRadius = (mark.baselineRadius + mark.valueRadius) * 0.5;
    final tangentialWidth = mark.band.sweepAngle.abs() * labelRadius;
    if (radialDepth < 10 * textScaleFactor ||
        tangentialWidth < 12 * textScaleFactor) {
      continue;
    }
    final textSize = _measureText(
      MultiAxisValueFormatter.format(value: mark.value),
      style,
      textScaleFactor,
      maxWidth: size.width,
    );
    if (radialDepth >= textSize.height + 4 * textScaleFactor &&
        tangentialWidth >= textSize.width + 6 * textScaleFactor) {
      candidates.add(mark.index);
    }
  }
  return _thinOrdinalIndices(
    candidates,
    series.polarStyle.maximumVisibleDataLabels,
  );
}

List<int> _thinOrdinalIndices(List<int> indices, int maximumVisible) {
  if (indices.length <= maximumVisible) return indices;
  final stride = (indices.length / maximumVisible).ceil();
  return <int>[
    for (var position = 0; position < indices.length; position += stride)
      indices[position],
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
