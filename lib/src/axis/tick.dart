// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection;

/// Represents a tick mark on an axis.
///
/// Each tick has a data value and a formatted label for display.
/// Optionally caches a laid-out TextPainter for high-performance rendering.
class Tick {
  Tick({required this.value, required this.label, this.isMajor = true});

  /// The data value at this tick position.
  final double value;

  /// The formatted label to display for this tick.
  final String label;

  /// Whether this is a major tick (larger mark, always labeled).
  ///
  /// Minor ticks can be used for finer graduations without labels.
  final bool isMajor;

  /// Cached TextPainter for this tick's label.
  /// Created lazily and cached to avoid repeated layout() calls during paint.
  TextPainter? _cachedTextPainter;

  /// The style used for the cached TextPainter (for cache invalidation).
  TextStyle? _cachedStyle;

  /// Gets a laid-out TextPainter for this tick's label.
  ///
  /// Caches the TextPainter to avoid expensive layout() calls on every paint.
  /// The cache is invalidated if the style changes.
  TextPainter getTextPainter(TextStyle style) {
    if (_cachedTextPainter != null && _cachedStyle == style) {
      return _cachedTextPainter!;
    }

    _cachedTextPainter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    _cachedStyle = style;

    return _cachedTextPainter!;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tick &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label &&
          isMajor == other.isMajor;

  @override
  int get hashCode => Object.hash(value, label, isMajor);

  @override
  String toString() => 'Tick(value: $value, label: "$label", major: $isMajor)';
}
