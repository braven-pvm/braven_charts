// Copyright (c) 2025 braven_charts. All rights reserved.
// Legend Style Configuration for BravenChartPlus

import 'package:flutter/material.dart';

/// Position where the legend can be anchored within the chart area.
enum LegendPosition {
  /// Top-left corner of the chart area.
  topLeft,

  /// Top-center of the chart area.
  topCenter,

  /// Top-right corner of the chart area.
  topRight,

  /// Center-left of the chart area.
  centerLeft,

  /// Center of the chart area.
  center,

  /// Center-right of the chart area.
  centerRight,

  /// Bottom-left corner of the chart area.
  bottomLeft,

  /// Bottom-center of the chart area.
  bottomCenter,

  /// Bottom-right corner of the chart area.
  bottomRight,
}

/// Layout orientation for legend items.
enum LegendOrientation {
  /// Items arranged horizontally (side by side).
  horizontal,

  /// Items arranged vertically (stacked).
  vertical,
}

/// Shape of the color indicator in legend items.
enum LegendMarkerShape {
  /// Circular marker (default).
  circle,

  /// Square marker.
  square,

  /// Short horizontal line.
  line,

  /// Diamond shape.
  diamond,
}

/// Immutable legend style configuration.
///
/// Defines the visual styling for chart legends including position,
/// colors, borders, fonts, and layout options.
///
/// Example:
/// ```dart
/// LegendStyle(
///   position: LegendPosition.topRight,
///   backgroundColor: Colors.white.withOpacity(0.9),
///   borderColor: Colors.grey,
///   textStyle: TextStyle(fontSize: 11, color: Colors.black87),
///   markerShape: LegendMarkerShape.line,
///   padding: EdgeInsets.all(8),
/// )
/// ```
@immutable
class LegendStyle {
  /// Creates a legend style.
  const LegendStyle({
    this.position = LegendPosition.topRight,
    this.orientation = LegendOrientation.horizontal,
    this.textStyle = const TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
    ),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius,
    this.padding,
    this.itemSpacing = 6.0,
    this.markerSize = 16.0,
    this.markerShape = LegendMarkerShape.line,
    this.markerLineWidth = 4.0,
    this.markerLabelSpacing = 6.0,
    this.allowDragging = true,
    this.opacity = 1.0,
    this.offset = Offset.zero,
  });

  /// Position where the legend is anchored.
  ///
  /// Default: `LegendPosition.topRight`
  final LegendPosition position;

  /// Layout orientation for legend items.
  ///
  /// Default: `LegendOrientation.vertical`
  final LegendOrientation orientation;

  /// Text style for legend item labels.
  ///
  /// Default: `TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.black87)`
  final TextStyle textStyle;

  /// Background color for the legend container (optional).
  ///
  /// If null, the legend will have a semi-transparent white background.
  final Color? backgroundColor;

  /// Border color for the legend outline (optional).
  ///
  /// If null, a subtle grey border will be used.
  final Color? borderColor;

  /// Border width in logical pixels.
  ///
  /// Default: 1.0
  final double borderWidth;

  /// Border radius for rounded corners.
  ///
  /// If null, defaults to `BorderRadius.circular(4)`.
  final BorderRadius? borderRadius;

  /// Padding inside the legend container.
  ///
  /// If null, defaults to `EdgeInsets.symmetric(horizontal: 8, vertical: 6)`.
  final EdgeInsets? padding;

  /// Spacing between legend items.
  ///
  /// Default: 4.0
  final double itemSpacing;

  /// Size of the color marker/indicator.
  ///
  /// Default: 12.0
  final double markerSize;

  /// Shape of the color marker/indicator.
  ///
  /// Default: `LegendMarkerShape.line`
  final LegendMarkerShape markerShape;

  /// Width of the line marker (when markerShape is line).
  ///
  /// Default: 3.0
  final double markerLineWidth;

  /// Spacing between marker and label text.
  ///
  /// Default: 6.0
  final double markerLabelSpacing;

  /// Whether the legend can be dragged to reposition.
  ///
  /// Default: true
  final bool allowDragging;

  /// Overall opacity of the legend.
  ///
  /// Default: 1.0 (fully opaque)
  final double opacity;

  /// Offset from the anchored position.
  ///
  /// Use this to fine-tune legend position relative to its anchor.
  /// Default: `Offset.zero`
  final Offset offset;

  /// Effective background color with default fallback.
  /// Default is semi-transparent white (85% opacity) - no border by default.
  Color get effectiveBackgroundColor => backgroundColor ?? const Color.fromARGB(117, 255, 255, 255);

  /// Effective border color with default fallback.
  Color get effectiveBorderColor => borderColor ?? const Color.fromARGB(0, 255, 255, 255);

  /// Effective border radius with default fallback.
  BorderRadius get effectiveBorderRadius => borderRadius ?? BorderRadius.circular(7);

  /// Effective padding with default fallback.
  EdgeInsets get effectivePadding => padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 4);

  /// Creates a copy with modified properties.
  LegendStyle copyWith({
    LegendPosition? position,
    LegendOrientation? orientation,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    double? itemSpacing,
    double? markerSize,
    LegendMarkerShape? markerShape,
    double? markerLineWidth,
    double? markerLabelSpacing,
    bool? allowDragging,
    double? opacity,
    Offset? offset,
  }) {
    return LegendStyle(
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      markerSize: markerSize ?? this.markerSize,
      markerShape: markerShape ?? this.markerShape,
      markerLineWidth: markerLineWidth ?? this.markerLineWidth,
      markerLabelSpacing: markerLabelSpacing ?? this.markerLabelSpacing,
      allowDragging: allowDragging ?? this.allowDragging,
      opacity: opacity ?? this.opacity,
      offset: offset ?? this.offset,
    );
  }

  /// Default light theme legend style.
  static const LegendStyle light = LegendStyle(
    backgroundColor: Color(0xCCFFFFFF), // Semi-transparent white
    borderWidth: 0.0, // No border by default
    textStyle: TextStyle(fontSize: 11, color: Colors.black87),
  );

  /// Default dark theme legend style.
  static const LegendStyle dark = LegendStyle(
    backgroundColor: Color(0xCC303030), // Semi-transparent dark
    borderWidth: 0.0, // No border by default
    textStyle: TextStyle(fontSize: 11, color: Colors.white70),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LegendStyle &&
        other.position == position &&
        other.orientation == orientation &&
        other.textStyle == textStyle &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.itemSpacing == itemSpacing &&
        other.markerSize == markerSize &&
        other.markerShape == markerShape &&
        other.markerLineWidth == markerLineWidth &&
        other.markerLabelSpacing == markerLabelSpacing &&
        other.allowDragging == allowDragging &&
        other.opacity == opacity &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return Object.hash(
      position,
      orientation,
      textStyle,
      backgroundColor,
      borderColor,
      borderWidth,
      borderRadius,
      padding,
      itemSpacing,
      markerSize,
      markerShape,
      markerLineWidth,
      markerLabelSpacing,
      allowDragging,
      opacity,
      offset,
    );
  }
}
