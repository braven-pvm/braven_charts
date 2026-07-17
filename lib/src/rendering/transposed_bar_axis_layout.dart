// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';

/// Resolves horizontal value-axis strips for transposed bar charts.
///
/// Public [YAxisPosition.left] axes become bottom value axes and public
/// [YAxisPosition.right] axes become top value axes. Axes on the same side are
/// stacked from the plot outward in declaration order, matching the vertical
/// multi-axis slot model.
class TransposedBarAxisLayout {
  const TransposedBarAxisLayout({required this.axes, required this.labelStyle});

  final List<YAxisConfig> axes;
  final TextStyle labelStyle;

  static const tickLength = 6.0;

  List<YAxisConfig> get bottomAxes => axes
      .where((axis) => axis.visible && _isBottom(axis.position))
      .toList(growable: false);

  List<YAxisConfig> get topAxes => axes
      .where((axis) => axis.visible && _isTop(axis.position))
      .toList(growable: false);

  double get bottomExtent =>
      bottomAxes.fold(0, (total, axis) => total + extentFor(axis));

  double get topExtent =>
      topAxes.fold(0, (total, axis) => total + extentFor(axis));

  double extentFor(YAxisConfig axis) {
    if (!axis.visible || axis.position == YAxisPosition.hidden) return 0;

    var extent = axis.axisMargin;
    if (axis.showTicks) extent += tickLength;
    if (axis.shouldShowTickLabels) {
      extent += _textHeight(labelStyle) + axis.tickLabelPadding;
    }
    if (axis.shouldShowAxisLabel && (axis.label?.isNotEmpty ?? false)) {
      extent +=
          _textHeight(labelStyle.copyWith(fontWeight: FontWeight.bold)) +
          axis.axisLabelPadding;
    }
    return math.max(12, extent);
  }

  /// Returns the reserved strip for every visible value axis.
  Map<String, Rect> axisRects(Rect plotArea) {
    final result = <String, Rect>{};

    var bottom = plotArea.bottom;
    for (final axis in bottomAxes) {
      final extent = extentFor(axis);
      result[axis.id] = Rect.fromLTWH(
        plotArea.left,
        bottom,
        plotArea.width,
        extent,
      );
      bottom += extent;
    }

    var top = plotArea.top;
    for (final axis in topAxes) {
      final extent = extentFor(axis);
      result[axis.id] = Rect.fromLTWH(
        plotArea.left,
        top - extent,
        plotArea.width,
        extent,
      );
      top -= extent;
    }

    return result;
  }

  static bool isBottom(YAxisConfig axis) => _isBottom(axis.position);

  static bool _isBottom(YAxisPosition position) =>
      position == YAxisPosition.left ||
      // ignore: deprecated_member_use_from_same_package
      position == YAxisPosition.leftOuter;

  static bool _isTop(YAxisPosition position) =>
      position == YAxisPosition.right ||
      // ignore: deprecated_member_use_from_same_package
      position == YAxisPosition.rightOuter;

  static double _textHeight(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.height;
  }
}
