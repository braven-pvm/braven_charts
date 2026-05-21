// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

enum SeriesLabelPosition { left, center, right }

class SeriesLabelBackground {
  const SeriesLabelBackground({
    required this.color,
    this.cornerRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    this.borderColor,
    this.borderWidth = 1.0,
  });

  final Color color;
  /// Null = auto-pill (half the pill height). Set to 0 for a rectangle.
  final double? cornerRadius;
  final EdgeInsets padding;
  final Color? borderColor;
  final double borderWidth;

  SeriesLabelBackground copyWith({
    Color? color,
    Object? cornerRadius = _sentinel,
    EdgeInsets? padding,
    Object? borderColor = _sentinel,
    double? borderWidth,
  }) =>
      SeriesLabelBackground(
        color: color ?? this.color,
        cornerRadius: cornerRadius == _sentinel
            ? this.cornerRadius
            : cornerRadius as double?,
        padding: padding ?? this.padding,
        borderColor: borderColor == _sentinel
            ? this.borderColor
            : borderColor as Color?,
        borderWidth: borderWidth ?? this.borderWidth,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SeriesLabelBackground) return false;
    return other.color == color &&
        other.cornerRadius == cornerRadius &&
        other.padding == padding &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth;
  }

  @override
  int get hashCode =>
      Object.hashAll([color, cornerRadius, padding, borderColor, borderWidth]);

  @override
  String toString() =>
      'SeriesLabelBackground(color: $color, cornerRadius: $cornerRadius, '
      'padding: $padding, borderColor: $borderColor, borderWidth: $borderWidth)';
}

// Sentinel for nullable copyWith params so callers can explicitly pass null.
const Object _sentinel = Object();

class SeriesInlineLabelConfig {
  const SeriesInlineLabelConfig({
    required this.text,
    this.position = SeriesLabelPosition.right,
    this.offsetY = 0.0,
    this.color,
    this.fontSize = 11.0,
    this.fontWeight = FontWeight.w500,
    this.background,
  });

  final String text;
  final SeriesLabelPosition position;
  final double offsetY;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final SeriesLabelBackground? background;

  SeriesInlineLabelConfig copyWith({
    String? text,
    SeriesLabelPosition? position,
    double? offsetY,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    SeriesLabelBackground? background,
  }) =>
      SeriesInlineLabelConfig(
        text: text ?? this.text,
        position: position ?? this.position,
        offsetY: offsetY ?? this.offsetY,
        color: color ?? this.color,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        background: background ?? this.background,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SeriesInlineLabelConfig) return false;
    return other.text == text &&
        other.position == position &&
        other.offsetY == offsetY &&
        other.color == color &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.background == background;
  }

  @override
  int get hashCode =>
      Object.hashAll([text, position, offsetY, color, fontSize, fontWeight, background]);

  @override
  String toString() =>
      'SeriesInlineLabelConfig(text: $text, position: $position)';
}
