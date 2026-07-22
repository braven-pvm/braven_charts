// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../meta/chart_surface.dart';

/// Theme defaults for native Candlestick rendering.
///
/// Series and point styles may override these colors. Direction is also
/// communicated by the series' hollow/filled body treatment, so the defaults
/// never rely on hue alone.
@immutable
@chartSurface
class CandlestickTheme {
  const CandlestickTheme({
    required this.risingBodyFillColor,
    required this.fallingBodyFillColor,
    required this.dojiBodyFillColor,
    required this.risingBorderColor,
    required this.fallingBorderColor,
    required this.dojiBorderColor,
    required this.risingWickColor,
    required this.fallingWickColor,
    required this.dojiWickColor,
    required this.selectionColor,
    required this.focusColor,
  });

  final Color risingBodyFillColor;
  final Color fallingBodyFillColor;
  final Color dojiBodyFillColor;
  final Color risingBorderColor;
  final Color fallingBorderColor;
  final Color dojiBorderColor;
  final Color risingWickColor;
  final Color fallingWickColor;
  final Color dojiWickColor;
  final Color selectionColor;
  final Color focusColor;

  static const light = CandlestickTheme(
    risingBodyFillColor: Color(0xFFCCFBF1),
    fallingBodyFillColor: Color(0xFFEF4444),
    dojiBodyFillColor: Color(0xFF64748B),
    risingBorderColor: Color(0xFF0F766E),
    fallingBorderColor: Color(0xFFB91C1C),
    dojiBorderColor: Color(0xFF475569),
    risingWickColor: Color(0xFF0F766E),
    fallingWickColor: Color(0xFFB91C1C),
    dojiWickColor: Color(0xFF475569),
    selectionColor: Color(0xFF2563EB),
    focusColor: Color(0xFF334155),
  );

  static const dark = CandlestickTheme(
    risingBodyFillColor: Color(0xFF064E3B),
    fallingBodyFillColor: Color(0xFFFB7185),
    dojiBodyFillColor: Color(0xFFCBD5E1),
    risingBorderColor: Color(0xFF34D399),
    fallingBorderColor: Color(0xFFFDA4AF),
    dojiBorderColor: Color(0xFFE2E8F0),
    risingWickColor: Color(0xFF34D399),
    fallingWickColor: Color(0xFFFDA4AF),
    dojiWickColor: Color(0xFFE2E8F0),
    selectionColor: Color(0xFF60A5FA),
    focusColor: Color(0xFFF8FAFC),
  );

  static const highContrast = CandlestickTheme(
    risingBodyFillColor: Colors.white,
    fallingBodyFillColor: Colors.black,
    dojiBodyFillColor: Colors.black,
    risingBorderColor: Colors.black,
    fallingBorderColor: Colors.black,
    dojiBorderColor: Colors.black,
    risingWickColor: Colors.black,
    fallingWickColor: Colors.black,
    dojiWickColor: Colors.black,
    selectionColor: Color(0xFF0000FF),
    focusColor: Colors.black,
  );

  static const colorblindFriendly = CandlestickTheme(
    risingBodyFillColor: Color(0xFFBAE6FD),
    fallingBodyFillColor: Color(0xFFFDBA74),
    dojiBodyFillColor: Color(0xFF6B7280),
    risingBorderColor: Color(0xFF0369A1),
    fallingBorderColor: Color(0xFFC2410C),
    dojiBorderColor: Color(0xFF374151),
    risingWickColor: Color(0xFF0369A1),
    fallingWickColor: Color(0xFFC2410C),
    dojiWickColor: Color(0xFF374151),
    selectionColor: Color(0xFF7C3AED),
    focusColor: Color(0xFF111827),
  );

  CandlestickTheme copyWith({
    Color? risingBodyFillColor,
    Color? fallingBodyFillColor,
    Color? dojiBodyFillColor,
    Color? risingBorderColor,
    Color? fallingBorderColor,
    Color? dojiBorderColor,
    Color? risingWickColor,
    Color? fallingWickColor,
    Color? dojiWickColor,
    Color? selectionColor,
    Color? focusColor,
  }) => CandlestickTheme(
    risingBodyFillColor: risingBodyFillColor ?? this.risingBodyFillColor,
    fallingBodyFillColor: fallingBodyFillColor ?? this.fallingBodyFillColor,
    dojiBodyFillColor: dojiBodyFillColor ?? this.dojiBodyFillColor,
    risingBorderColor: risingBorderColor ?? this.risingBorderColor,
    fallingBorderColor: fallingBorderColor ?? this.fallingBorderColor,
    dojiBorderColor: dojiBorderColor ?? this.dojiBorderColor,
    risingWickColor: risingWickColor ?? this.risingWickColor,
    fallingWickColor: fallingWickColor ?? this.fallingWickColor,
    dojiWickColor: dojiWickColor ?? this.dojiWickColor,
    selectionColor: selectionColor ?? this.selectionColor,
    focusColor: focusColor ?? this.focusColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickTheme &&
          other.risingBodyFillColor == risingBodyFillColor &&
          other.fallingBodyFillColor == fallingBodyFillColor &&
          other.dojiBodyFillColor == dojiBodyFillColor &&
          other.risingBorderColor == risingBorderColor &&
          other.fallingBorderColor == fallingBorderColor &&
          other.dojiBorderColor == dojiBorderColor &&
          other.risingWickColor == risingWickColor &&
          other.fallingWickColor == fallingWickColor &&
          other.dojiWickColor == dojiWickColor &&
          other.selectionColor == selectionColor &&
          other.focusColor == focusColor;

  @override
  int get hashCode => Object.hashAll([
    risingBodyFillColor,
    fallingBodyFillColor,
    dojiBodyFillColor,
    risingBorderColor,
    fallingBorderColor,
    dojiBorderColor,
    risingWickColor,
    fallingWickColor,
    dojiWickColor,
    selectionColor,
    focusColor,
  ]);
}
