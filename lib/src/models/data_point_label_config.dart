// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show FontWeight;

import 'chart_data_point.dart';

/// Position of a data-point label relative to its marker.
enum DataPointLabelPosition { above, below, left, right }

/// Portable text source used by a data-point label.
enum DataPointLabelContent { value, pointLabel }

/// How labels behave when their painted bounds overlap.
enum DataPointLabelCollisionPolicy {
  /// Preserve every preferred placement, even when labels overlap.
  none,

  /// Hide a label when its preferred placement is occupied.
  hide,

  /// Try the remaining marker sides before hiding the label.
  reposition,
}

/// Configuration for optional text labels rendered next to data point markers.
///
/// Attach to line, area, or Scatter series through their `dataPointLabels`
/// property.
/// Labels are hidden by default — set [show] to true to enable.
class DataPointLabelConfig {
  const DataPointLabelConfig({
    this.show = false,
    this.position = DataPointLabelPosition.above,
    this.content = DataPointLabelContent.value,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.markerGap = 4.0,
    this.collisionPolicy = DataPointLabelCollisionPolicy.none,
    this.collisionPadding = 2.0,
    this.plotEdgeAware = true,
    this.labelColor,
    this.fontSize = 10.0,
    this.fontWeight = FontWeight.w600,
    this.showUnit = false,
    this.formatter,
    this.background,
    this.backgroundOpacity = 0.85,
  }) : assert(
         offsetX > double.negativeInfinity && offsetX < double.infinity,
         'offsetX must be finite',
       ),
       assert(
         offsetY > double.negativeInfinity && offsetY < double.infinity,
         'offsetY must be finite',
       ),
       assert(
         markerGap >= 0 && markerGap < double.infinity,
         'markerGap must be finite and non-negative',
       ),
       assert(
         collisionPadding >= 0 && collisionPadding < double.infinity,
         'collisionPadding must be finite and non-negative',
       );

  final bool show;
  final DataPointLabelPosition position;
  final DataPointLabelContent content;
  final double offsetX;
  final double offsetY;
  final double markerGap;
  final DataPointLabelCollisionPolicy collisionPolicy;
  final double collisionPadding;
  final bool plotEdgeAware;
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
    DataPointLabelContent? content,
    double? offsetX,
    double? offsetY,
    double? markerGap,
    DataPointLabelCollisionPolicy? collisionPolicy,
    double? collisionPadding,
    bool? plotEdgeAware,
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
      content: content ?? this.content,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      markerGap: markerGap ?? this.markerGap,
      collisionPolicy: collisionPolicy ?? this.collisionPolicy,
      collisionPadding: collisionPadding ?? this.collisionPadding,
      plotEdgeAware: plotEdgeAware ?? this.plotEdgeAware,
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
        other.content == content &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.markerGap == markerGap &&
        other.collisionPolicy == collisionPolicy &&
        other.collisionPadding == collisionPadding &&
        other.plotEdgeAware == plotEdgeAware &&
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
    content,
    offsetX,
    offsetY,
    markerGap,
    collisionPolicy,
    collisionPadding,
    plotEdgeAware,
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
      'content: $content, collisionPolicy: $collisionPolicy, '
      'fontSize: $fontSize, showUnit: $showUnit)';
}
