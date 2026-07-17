// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/chart_series.dart';
import '../models/series_axis_binding.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'axis_color_resolver.dart';
import 'multi_axis_normalizer.dart';
import 'transposed_bar_axis_layout.dart';
import 'x_axis_painter.dart';

/// Paints semantic bar axes after horizontal orientation transposes the chart.
///
/// The public data contract remains X = category and Y = value. This painter
/// therefore moves the configured X axis to the left and maps Y axes to
/// horizontal strips: left-positioned value axes below the plot and
/// right-positioned value axes above it.
class TransposedBarAxesPainter {
  TransposedBarAxesPainter({
    required this.categoryConfig,
    required this.categoryBounds,
    required this.valueAxes,
    required this.valueBounds,
    required this.labelStyle,
    this.bindings = const [],
    this.series = const [],
    this.categoryTickValues,
  });

  final XAxisConfig categoryConfig;
  final DataRange categoryBounds;
  final List<YAxisConfig> valueAxes;
  final Map<String, DataRange> valueBounds;
  final TextStyle labelStyle;
  final List<SeriesAxisBinding> bindings;
  final List<ChartSeries> series;
  final List<double>? categoryTickValues;

  static const _tickLength = TransposedBarAxisLayout.tickLength;

  TransposedBarAxisLayout get layout =>
      TransposedBarAxisLayout(axes: valueAxes, labelStyle: labelStyle);

  double measureCategoryAxisWidth() {
    if (!categoryConfig.visible) return 10;
    final formatter = XAxisPainter(
      config: categoryConfig,
      axisBounds: categoryBounds,
      labelStyle: labelStyle,
      series: series,
      tickValues: categoryTickValues,
    );
    final ticks = categoryTickValues ?? formatter.generateTicks(categoryBounds);
    var widest = 0.0;
    if (categoryConfig.shouldShowTickLabels) {
      for (final value in ticks) {
        if (!_categoryTickVisible(value)) continue;
        final painter = _text(formatter.formatTickLabel(value));
        widest = math.max(widest, painter.width);
      }
    }
    final titleSpace =
        categoryConfig.shouldShowAxisLabel &&
            categoryConfig.label != null &&
            categoryConfig.label!.isNotEmpty
        ? (_text(_categoryTitle).height + categoryConfig.axisLabelPadding)
        : 0.0;
    return (widest +
            _tickLength +
            categoryConfig.tickLabelPadding +
            titleSpace +
            categoryConfig.axisMargin)
        .clamp(40.0, 180.0);
  }

  double measureBottomAxesHeight() => layout.bottomExtent;

  double measureTopAxesHeight() => layout.topExtent;

  /// Grid positions follow the innermost visible value axis.
  List<double> valueGridPositions(Rect plotArea) {
    final axes = [...layout.bottomAxes, ...layout.topAxes];
    if (axes.isEmpty) return const [];
    final axis = axes.first;
    final bounds = valueBounds[axis.id];
    if (bounds == null) return const [];
    final formatter = _valueFormatter(axis, bounds);
    final ticks = formatter.generateTicks(bounds);
    final renderMin = axis.renderMin ?? bounds.min;
    final renderMax = axis.renderMax ?? bounds.max;
    return [
      for (final tick in ticks)
        if (tick >= renderMin && tick <= renderMax)
          plotArea.left +
              MultiAxisNormalizer.normalize(tick, bounds.min, bounds.max) *
                  plotArea.width,
    ];
  }

  void paint(Canvas canvas, Rect chartArea, Rect plotArea) {
    _paintCategoryAxis(canvas, chartArea, plotArea);
    final axisRects = layout.axisRects(plotArea);
    for (final axis in valueAxes.where((axis) => axis.visible)) {
      final bounds = valueBounds[axis.id];
      final axisRect = axisRects[axis.id];
      if (bounds == null || axisRect == null) continue;
      _paintValueAxis(
        canvas: canvas,
        chartArea: chartArea,
        plotArea: plotArea,
        axis: axis,
        bounds: bounds,
        axisRect: axisRect,
      );
    }
  }

  void _paintCategoryAxis(Canvas canvas, Rect chartArea, Rect plotArea) {
    if (!categoryConfig.visible) return;
    final formatter = XAxisPainter(
      config: categoryConfig,
      axisBounds: categoryBounds,
      labelStyle: labelStyle,
      series: series,
      tickValues: categoryTickValues,
    );
    final color = formatter.resolveAxisColor();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    if (categoryConfig.showAxisLine) {
      canvas.drawLine(plotArea.topLeft, plotArea.bottomLeft, paint);
    }

    final ticks = categoryTickValues ?? formatter.generateTicks(categoryBounds);
    for (final value in ticks) {
      if (!_categoryTickVisible(value)) continue;
      final ratio = categoryBounds.span == 0
          ? 0.0
          : (value - categoryBounds.min) / categoryBounds.span;
      final y = plotArea.top + ratio * plotArea.height;
      if (y < plotArea.top || y > plotArea.bottom) continue;
      if (categoryConfig.showTicks) {
        canvas.drawLine(
          Offset(plotArea.left - _tickLength, y),
          Offset(plotArea.left, y),
          paint,
        );
      }
      if (categoryConfig.shouldShowTickLabels) {
        final label = _text(formatter.formatTickLabel(value), color: color);
        label.paint(
          canvas,
          Offset(
            plotArea.left -
                _tickLength -
                categoryConfig.tickLabelPadding -
                label.width,
            y - label.height / 2,
          ),
        );
      }
    }

    if (categoryConfig.shouldShowAxisLabel &&
        categoryConfig.label != null &&
        categoryConfig.label!.isNotEmpty) {
      final title = _text(
        _categoryTitle,
        color: color,
        fontWeight: FontWeight.bold,
      );
      canvas.save();
      final x = math.max(8.0, chartArea.left + categoryConfig.axisMargin);
      final y = plotArea.center.dy + title.width / 2;
      canvas.translate(x, y);
      canvas.rotate(-math.pi / 2);
      title.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  void _paintValueAxis({
    required Canvas canvas,
    required Rect chartArea,
    required Rect plotArea,
    required YAxisConfig axis,
    required DataRange bounds,
    required Rect axisRect,
  }) {
    final isBottom = TransposedBarAxisLayout.isBottom(axis);
    final lineY = isBottom ? axisRect.top : axisRect.bottom;
    final outward = isBottom ? 1.0 : -1.0;
    final color = AxisColorResolver.resolveAxisColor(axis, bindings, series);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (axis.showAxisLine) {
      canvas.drawLine(
        Offset(plotArea.left, lineY),
        Offset(plotArea.right, lineY),
        paint,
      );
    }

    final formatter = _valueFormatter(axis, bounds);
    final ticks = formatter.generateTicks(bounds);
    final renderMin = axis.renderMin ?? bounds.min;
    final renderMax = axis.renderMax ?? bounds.max;
    final tickLabelPainters = <TextPainter>[];

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        plotArea.left,
        chartArea.top,
        plotArea.right,
        chartArea.bottom,
      ),
    );
    for (final tick in ticks) {
      if (tick < renderMin || tick > renderMax) continue;
      final x =
          plotArea.left +
          MultiAxisNormalizer.normalize(tick, bounds.min, bounds.max) *
              plotArea.width;
      if (axis.showTicks) {
        canvas.drawLine(
          Offset(x, lineY),
          Offset(x, lineY + outward * _tickLength),
          paint,
        );
      }
      if (axis.shouldShowTickLabels) {
        final label = _text(formatter.formatTickLabel(tick), color: color);
        tickLabelPainters.add(label);
        final y = isBottom
            ? lineY + _tickLength + axis.tickLabelPadding
            : lineY - _tickLength - axis.tickLabelPadding - label.height;
        label.paint(canvas, Offset(x - label.width / 2, y));
      }
    }

    if (axis.showMinorTicks && axis.minorTickCount > 0 && ticks.length >= 2) {
      for (var i = 0; i < ticks.length - 1; i++) {
        for (var minor = 1; minor <= axis.minorTickCount; minor++) {
          final value =
              ticks[i] +
              (ticks[i + 1] - ticks[i]) * minor / (axis.minorTickCount + 1);
          if (value < renderMin || value > renderMax) continue;
          final x =
              plotArea.left +
              MultiAxisNormalizer.normalize(value, bounds.min, bounds.max) *
                  plotArea.width;
          canvas.drawLine(
            Offset(x, lineY),
            Offset(x, lineY + outward * axis.minorTickLength),
            paint,
          );
        }
      }
    }
    canvas.restore();

    if (axis.shouldShowAxisLabel && (axis.label?.isNotEmpty ?? false)) {
      final title = _text(
        axis.shouldAppendUnitToLabel && (axis.unit?.isNotEmpty ?? false)
            ? '${axis.label} (${axis.unit})'
            : axis.label!,
        color: color,
        fontWeight: FontWeight.bold,
      );
      final tickHeight = tickLabelPainters.isEmpty
          ? _text('0').height
          : tickLabelPainters.first.height;
      final tickSpace = axis.shouldShowTickLabels
          ? _tickLength + axis.tickLabelPadding + tickHeight
          : (axis.showTicks ? _tickLength : 0.0);
      final y = isBottom
          ? lineY + tickSpace + axis.axisLabelPadding
          : lineY - tickSpace - axis.axisLabelPadding - title.height;
      title.paint(canvas, Offset(plotArea.center.dx - title.width / 2, y));
    }
  }

  XAxisPainter _valueFormatter(YAxisConfig axis, DataRange bounds) =>
      XAxisPainter(
        config: XAxisConfig(
          color: axis.color,
          label: axis.label,
          unit: axis.unit,
          min: axis.min,
          max: axis.max,
          renderMin: axis.renderMin,
          renderMax: axis.renderMax,
          visible: axis.visible,
          showAxisLine: axis.showAxisLine,
          showTicks: axis.showTicks,
          showTickLabels: axis.showTickLabels,
          showCrosshairLabel: axis.showCrosshairLabel,
          crosshairLabelPosition: axis.crosshairLabelPosition,
          labelDisplay: axis.labelDisplay,
          tickLabelPadding: axis.tickLabelPadding,
          axisLabelPadding: axis.axisLabelPadding,
          axisMargin: axis.axisMargin,
          tickCount: axis.tickCount,
          labelFormatter: axis.labelFormatter,
          showMinorTicks: axis.showMinorTicks,
          minorTickCount: axis.minorTickCount,
          minorTickLength: axis.minorTickLength,
        ),
        axisBounds: bounds,
        labelStyle: labelStyle,
      );

  bool _categoryTickVisible(double value) {
    final min = categoryConfig.renderMin ?? categoryBounds.min;
    final max = categoryConfig.renderMax ?? categoryBounds.max;
    return value >= min && value <= max;
  }

  String get _categoryTitle =>
      categoryConfig.shouldAppendUnitToLabel && categoryConfig.unit != null
      ? '${categoryConfig.label} (${categoryConfig.unit})'
      : categoryConfig.label!;

  TextPainter _text(String value, {Color? color, FontWeight? fontWeight}) =>
      TextPainter(
        text: TextSpan(
          text: value,
          style: labelStyle.copyWith(color: color, fontWeight: fontWeight),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
}
