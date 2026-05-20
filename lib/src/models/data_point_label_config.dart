// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show FontWeight;

import 'chart_data_point.dart';

/// Position of a data-point label relative to its marker.
enum DataPointLabelPosition { above, below, left, right }

/// Configuration for optional text labels rendered next to data point markers.
///
/// Attach to [LineChartSeries.dataPointLabels] or [AreaChartSeries.dataPointLabels].
/// Labels are hidden by default — set [show] to true to enable.
class DataPointLabelConfig {
  const DataPointLabelConfig({
    this.show = false,
    this.position = DataPointLabelPosition.above,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.labelColor,
    this.fontSize = 10.0,
    this.fontWeight = FontWeight.w600,
    this.showUnit = false,
    this.formatter,
    this.background,
    this.backgroundOpacity = 0.85,
  });

  final bool show;
  final DataPointLabelPosition position;
  final double offsetX;
  final double offsetY;
  final Color? labelColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showUnit;
  final String Function(ChartDataPoint)? formatter;
  final Color? background;
  final double backgroundOpacity;

  /// Formats [y] using the spec rules:
  /// - Whole number → no decimal places
  /// - |y| < 1 → 2 decimal places
  /// - 1 ≤ |y| < 100 → 1 decimal place
  /// - |y| ≥ 100 → 0 decimal places (rounded)
  static String autoFormatLabelValue(double y, String? unit) {
    final String numStr;
    if (y == y.roundToDouble()) {
      numStr = y.toStringAsFixed(0);
    } else if (y.abs() < 1.0) {
      numStr = y.toStringAsFixed(2);
    } else if (y.abs() < 100.0) {
      numStr = y.toStringAsFixed(1);
    } else {
      numStr = y.toStringAsFixed(0);
    }
    if (unit != null && unit.isNotEmpty) return '$numStr $unit';
    return numStr;
  }

  DataPointLabelConfig copyWith({
    bool? show,
    DataPointLabelPosition? position,
    double? offsetX,
    double? offsetY,
    Color? labelColor,
    double? fontSize,
    FontWeight? fontWeight,
    bool? showUnit,
    String Function(ChartDataPoint)? formatter,
    Color? background,
    double? backgroundOpacity,
  }) {
    return DataPointLabelConfig(
      show: show ?? this.show,
      position: position ?? this.position,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      labelColor: labelColor ?? this.labelColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      showUnit: showUnit ?? this.showUnit,
      formatter: formatter ?? this.formatter,
      background: background ?? this.background,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataPointLabelConfig &&
        other.show == show &&
        other.position == position &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.labelColor == labelColor &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.showUnit == showUnit &&
        other.formatter == formatter &&
        other.background == background &&
        other.backgroundOpacity == backgroundOpacity;
  }

  @override
  int get hashCode => Object.hashAll([
        show,
        position,
        offsetX,
        offsetY,
        labelColor,
        fontSize,
        fontWeight,
        showUnit,
        formatter,
        background,
        backgroundOpacity,
      ]);

  @override
  String toString() =>
      'DataPointLabelConfig(show: $show, position: $position, '
      'fontSize: $fontSize, showUnit: $showUnit)';
}
