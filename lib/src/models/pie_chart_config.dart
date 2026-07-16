import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// Content rendered for an eligible pie-slice data label.
enum PieDataLabelContent {
  /// Category only.
  category,

  /// Formatted numeric value only.
  value,

  /// Percentage share only.
  percentage,

  /// Category followed by the formatted value.
  categoryAndValue,

  /// Category followed by its percentage share.
  categoryAndPercentage,

  /// Formatted value followed by its percentage share.
  valueAndPercentage,

  /// Category, formatted value, and percentage share.
  categoryValueAndPercentage,
}

/// Placement of pie-slice data labels.
enum PieDataLabelPosition {
  /// Place labels inside eligible slices.
  inside,

  /// Place labels in collision-managed lanes outside the pie.
  outside,
}

/// Policy used when outside pie labels would overlap.
enum PieDataLabelCollisionStrategy {
  /// Keep the requested anchors even if labels overlap.
  none,

  /// Shift labels within their side lane while space remains.
  shift,

  /// Shift labels, then hide the lowest-priority labels if space is exhausted.
  shiftAndHide,
}

/// Immutable visual configuration for pie geometry.
@immutable
class PieChartStyle {
  /// Creates pie geometry styling.
  const PieChartStyle({
    this.startAngleDegrees = -90,
    this.clockwise = true,
    this.radiusFactor = 0.9,
    this.sliceGap = 2,
    this.borderWidth = 1,
    this.borderColor,
    this.selectionExplodeOffset = 8,
  });

  /// Angle in degrees at which the first slice begins.
  final double startAngleDegrees;

  /// Whether slices advance clockwise in screen coordinates.
  final bool clockwise;

  /// Fraction of the available half-size used as the outer radius.
  final double radiusFactor;

  /// Logical-pixel gap measured along the outer circumference.
  final double sliceGap;

  /// Logical-pixel slice-border width.
  final double borderWidth;

  /// Optional shared slice-border color.
  final Color? borderColor;

  /// Logical-pixel offset applied to a selected, exploded slice.
  final double selectionExplodeOffset;

  /// Returns a copy with selected fields replaced.
  PieChartStyle copyWith({
    double? startAngleDegrees,
    bool? clockwise,
    double? radiusFactor,
    double? sliceGap,
    double? borderWidth,
    Color? borderColor,
    bool clearBorderColor = false,
    double? selectionExplodeOffset,
  }) {
    return PieChartStyle(
      startAngleDegrees: startAngleDegrees ?? this.startAngleDegrees,
      clockwise: clockwise ?? this.clockwise,
      radiusFactor: radiusFactor ?? this.radiusFactor,
      sliceGap: sliceGap ?? this.sliceGap,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
      selectionExplodeOffset:
          selectionExplodeOffset ?? this.selectionExplodeOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartStyle &&
          startAngleDegrees == other.startAngleDegrees &&
          clockwise == other.clockwise &&
          radiusFactor == other.radiusFactor &&
          sliceGap == other.sliceGap &&
          borderWidth == other.borderWidth &&
          borderColor == other.borderColor &&
          selectionExplodeOffset == other.selectionExplodeOffset;

  @override
  int get hashCode => Object.hash(
    startAngleDegrees,
    clockwise,
    radiusFactor,
    sliceGap,
    borderWidth,
    borderColor,
    selectionExplodeOffset,
  );
}

/// Immutable eligibility, placement, and connector policy for pie labels.
@immutable
class PieDataLabelConfig {
  /// Creates pie data-label configuration.
  const PieDataLabelConfig({
    this.isVisible = true,
    this.position = PieDataLabelPosition.outside,
    this.content = PieDataLabelContent.categoryAndPercentage,
    this.minimumShare = 0.03,
    this.minimumSweepDegrees = 8,
    this.padding = 6,
    this.connectorLength = 14,
    this.connectorWidth = 1,
    this.connectorColor,
    this.collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide,
  });

  /// Whether data labels are rendered.
  final bool isVisible;

  /// Requested inside or outside placement.
  final PieDataLabelPosition position;

  /// Category/value/share content shown by each label.
  final PieDataLabelContent content;

  /// Minimum share in the inclusive range 0–1 required for a label.
  final double minimumShare;

  /// Minimum absolute slice sweep in degrees required for a label.
  final double minimumSweepDegrees;

  /// Logical-pixel padding between a label and its anchor or lane.
  final double padding;

  /// Logical-pixel radial connector length for outside labels.
  final double connectorLength;

  /// Logical-pixel connector stroke width.
  final double connectorWidth;

  /// Optional connector color; the renderer otherwise derives one from theme.
  final Color? connectorColor;

  /// Collision policy for outside labels.
  final PieDataLabelCollisionStrategy collisionStrategy;

  /// Returns a copy with selected fields replaced.
  PieDataLabelConfig copyWith({
    bool? isVisible,
    PieDataLabelPosition? position,
    PieDataLabelContent? content,
    double? minimumShare,
    double? minimumSweepDegrees,
    double? padding,
    double? connectorLength,
    double? connectorWidth,
    Color? connectorColor,
    bool clearConnectorColor = false,
    PieDataLabelCollisionStrategy? collisionStrategy,
  }) {
    return PieDataLabelConfig(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      content: content ?? this.content,
      minimumShare: minimumShare ?? this.minimumShare,
      minimumSweepDegrees: minimumSweepDegrees ?? this.minimumSweepDegrees,
      padding: padding ?? this.padding,
      connectorLength: connectorLength ?? this.connectorLength,
      connectorWidth: connectorWidth ?? this.connectorWidth,
      connectorColor: clearConnectorColor
          ? null
          : (connectorColor ?? this.connectorColor),
      collisionStrategy: collisionStrategy ?? this.collisionStrategy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieDataLabelConfig &&
          isVisible == other.isVisible &&
          position == other.position &&
          content == other.content &&
          minimumShare == other.minimumShare &&
          minimumSweepDegrees == other.minimumSweepDegrees &&
          padding == other.padding &&
          connectorLength == other.connectorLength &&
          connectorWidth == other.connectorWidth &&
          connectorColor == other.connectorColor &&
          collisionStrategy == other.collisionStrategy;

  @override
  int get hashCode => Object.hash(
    isVisible,
    position,
    content,
    minimumShare,
    minimumSweepDegrees,
    padding,
    connectorLength,
    connectorWidth,
    connectorColor,
    collisionStrategy,
  );
}
