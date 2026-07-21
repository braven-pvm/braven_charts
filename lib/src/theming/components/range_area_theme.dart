// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Theme defaults for native Range Area rendering.
///
/// Explicit series and boundary values remain authoritative. These values
/// provide accessible fallback treatment for the fill, paired boundaries,
/// markers, and linked interaction states.
@immutable
class RangeAreaTheme {
  const RangeAreaTheme({
    required this.fillOpacity,
    required this.boundaryOpacity,
    required this.boundaryWidth,
    required this.markerFillColor,
    required this.markerStrokeColor,
    required this.markerStrokeWidth,
    required this.selectionColor,
    required this.focusColor,
  });

  final double fillOpacity;
  final double boundaryOpacity;
  final double boundaryWidth;
  final Color markerFillColor;
  final Color markerStrokeColor;
  final double markerStrokeWidth;
  final Color selectionColor;
  final Color focusColor;

  static const light = RangeAreaTheme(
    fillOpacity: 0.26,
    boundaryOpacity: 0.92,
    boundaryWidth: 1.5,
    markerFillColor: Colors.white,
    markerStrokeColor: Color(0xFF2563EB),
    markerStrokeWidth: 1.5,
    selectionColor: Color(0xFF2563EB),
    focusColor: Color(0xFF334155),
  );

  static const dark = RangeAreaTheme(
    fillOpacity: 0.32,
    boundaryOpacity: 0.96,
    boundaryWidth: 1.5,
    markerFillColor: Color(0xFF0F172A),
    markerStrokeColor: Color(0xFF60A5FA),
    markerStrokeWidth: 1.5,
    selectionColor: Color(0xFF60A5FA),
    focusColor: Color(0xFFF8FAFC),
  );

  static const highContrast = RangeAreaTheme(
    fillOpacity: 0.18,
    boundaryOpacity: 1,
    boundaryWidth: 2,
    markerFillColor: Colors.white,
    markerStrokeColor: Colors.black,
    markerStrokeWidth: 2,
    selectionColor: Color(0xFF0000FF),
    focusColor: Colors.black,
  );

  RangeAreaTheme copyWith({
    double? fillOpacity,
    double? boundaryOpacity,
    double? boundaryWidth,
    Color? markerFillColor,
    Color? markerStrokeColor,
    double? markerStrokeWidth,
    Color? selectionColor,
    Color? focusColor,
  }) => RangeAreaTheme(
    fillOpacity: fillOpacity ?? this.fillOpacity,
    boundaryOpacity: boundaryOpacity ?? this.boundaryOpacity,
    boundaryWidth: boundaryWidth ?? this.boundaryWidth,
    markerFillColor: markerFillColor ?? this.markerFillColor,
    markerStrokeColor: markerStrokeColor ?? this.markerStrokeColor,
    markerStrokeWidth: markerStrokeWidth ?? this.markerStrokeWidth,
    selectionColor: selectionColor ?? this.selectionColor,
    focusColor: focusColor ?? this.focusColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAreaTheme &&
          other.fillOpacity == fillOpacity &&
          other.boundaryOpacity == boundaryOpacity &&
          other.boundaryWidth == boundaryWidth &&
          other.markerFillColor == markerFillColor &&
          other.markerStrokeColor == markerStrokeColor &&
          other.markerStrokeWidth == markerStrokeWidth &&
          other.selectionColor == selectionColor &&
          other.focusColor == focusColor;

  @override
  int get hashCode => Object.hash(
    fillOpacity,
    boundaryOpacity,
    boundaryWidth,
    markerFillColor,
    markerStrokeColor,
    markerStrokeWidth,
    selectionColor,
    focusColor,
  );
}
