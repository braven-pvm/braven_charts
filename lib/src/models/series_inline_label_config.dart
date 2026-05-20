// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

enum SeriesLabelPosition { left, center, right }

class SeriesLabelBackground {
  const SeriesLabelBackground({
    required this.color,
    this.opacity = 0.85,
  });

  final Color color;
  final double opacity;

  SeriesLabelBackground copyWith({Color? color, double? opacity}) =>
      SeriesLabelBackground(
        color: color ?? this.color,
        opacity: opacity ?? this.opacity,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SeriesLabelBackground) return false;
    return other.color == color && other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(color, opacity);

  @override
  String toString() =>
      'SeriesLabelBackground(color: $color, opacity: $opacity)';
}

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
