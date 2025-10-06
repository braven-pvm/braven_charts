// CONTRACT: SeriesTheme
// Feature: 004-theming-system
//
// Defines styling for chart series with cycling color/style lists.
// Supports unlimited series with automatic style cycling.

import 'package:flutter/material.dart';

/// Marker shape options for series data points.
enum MarkerShape {
  circle,
  square,
  triangle,
  diamond,
  cross,
  plus,
  star,
  none, // No marker
}

/// Styling for chart series (colors, line widths, markers).
///
/// All style lists cycle when seriesIndex >= list.length.
/// This allows defining a small palette that applies to unlimited series.
///
/// Example:
/// ```dart
/// final seriesTheme = SeriesTheme(
///   colors: [Colors.blue, Colors.orange, Colors.green],
///   lineWidths: [2.0],
///   dashPatterns: [null, [5.0, 5.0]], // Series 0 solid, 1 dashed, 2 solid, ...
///   markerShapes: [MarkerShape.circle, MarkerShape.square],
///   markerSizes: [8.0],
/// );
/// 
/// // Series 0: blue, 2.0px, solid, circle, 8.0px
/// // Series 1: orange, 2.0px, dashed, square, 8.0px
/// // Series 2: green, 2.0px, solid, circle, 8.0px (cycles back)
/// ```
class SeriesTheme {
  const SeriesTheme({
    required this.colors,
    required this.lineWidths,
    required this.dashPatterns,
    required this.markerShapes,
    required this.markerSizes,
  })  : assert(colors.length > 0, 'colors must have at least 1 element'),
        assert(lineWidths.length > 0, 'lineWidths must have at least 1 element'),
        assert(dashPatterns.length > 0, 'dashPatterns must have at least 1 element'),
        assert(markerShapes.length > 0, 'markerShapes must have at least 1 element'),
        assert(markerSizes.length > 0, 'markerSizes must have at least 1 element');

  /// Series colors. Cycles for series index >= colors.length.
  final List<Color> colors;

  /// Line widths in pixels. Cycles for series index >= lineWidths.length.
  final List<double> lineWidths;

  /// Dash patterns (null = solid). Cycles for series index >= dashPatterns.length.
  final List<List<double>?> dashPatterns;

  /// Marker shapes. Cycles for series index >= markerShapes.length.
  final List<MarkerShape> markerShapes;

  /// Marker sizes in pixels. Cycles for series index >= markerSizes.length.
  final List<double> markerSizes;

  // ========== Cycling Accessors ==========

  /// Gets color for given series index (with cycling).
  Color colorAt(int seriesIndex) => colors[seriesIndex % colors.length];

  /// Gets line width for given series index (with cycling).
  double lineWidthAt(int seriesIndex) => lineWidths[seriesIndex % lineWidths.length];

  /// Gets dash pattern for given series index (with cycling).
  List<double>? dashPatternAt(int seriesIndex) => dashPatterns[seriesIndex % dashPatterns.length];

  /// Gets marker shape for given series index (with cycling).
  MarkerShape markerShapeAt(int seriesIndex) => markerShapes[seriesIndex % markerShapes.length];

  /// Gets marker size for given series index (with cycling).
  double markerSizeAt(int seriesIndex) => markerSizes[seriesIndex % markerSizes.length];

  // ========== Predefined Themes ==========

  static const SeriesTheme defaultLight = SeriesTheme(
    colors: [
      Color(0xFF1976D2), // Blue
      Color(0xFFFF6F00), // Orange
      Color(0xFF388E3C), // Green
      Color(0xFFD32F2F), // Red
      Color(0xFF7B1FA2), // Purple
      Color(0xFFFBC02D), // Yellow
      Color(0xFF0097A7), // Cyan
    ],
    lineWidths: [2.0],
    dashPatterns: [null], // All solid
    markerShapes: [MarkerShape.circle],
    markerSizes: [8.0],
  );

  static const SeriesTheme defaultDark = SeriesTheme(
    colors: [
      Color(0xFF42A5F5), // Light Blue
      Color(0xFFFF9800), // Orange
      Color(0xFF66BB6A), // Light Green
      Color(0xFFEF5350), // Light Red
      Color(0xFFAB47BC), // Light Purple
      Color(0xFFFFEB3B), // Light Yellow
      Color(0xFF26C6DA), // Light Cyan
    ],
    lineWidths: [2.0],
    dashPatterns: [null],
    markerShapes: [MarkerShape.circle],
    markerSizes: [8.0],
  );

  static const SeriesTheme corporateBlue = SeriesTheme(
    colors: [
      Color(0xFF1976D2), // Primary Blue
      Color(0xFF1565C0), // Darker Blue
      Color(0xFF42A5F5), // Lighter Blue
      Color(0xFF0D47A1), // Deep Blue
      Color(0xFF64B5F6), // Sky Blue
    ],
    lineWidths: [2.0],
    dashPatterns: [null],
    markerShapes: [MarkerShape.circle],
    markerSizes: [8.0],
  );

  static const SeriesTheme vibrant = SeriesTheme(
    colors: [
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFF2196F3), // Blue
      Color(0xFF00BCD4), // Cyan
      Color(0xFF4CAF50), // Green
      Color(0xFFFFEB3B), // Yellow
      Color(0xFFFF5722), // Deep Orange
    ],
    lineWidths: [3.0],
    dashPatterns: [null],
    markerShapes: [MarkerShape.circle, MarkerShape.square, MarkerShape.diamond],
    markerSizes: [10.0],
  );

  static const SeriesTheme minimal = SeriesTheme(
    colors: [
      Color(0xFF616161), // Dark Gray
      Color(0xFF9E9E9E), // Medium Gray
      Color(0xFF757575), // Gray
      Color(0xFFBDBDBD), // Light Gray
    ],
    lineWidths: [1.5],
    dashPatterns: [null, [5.0, 5.0], [10.0, 5.0, 2.0, 5.0]], // Varied patterns
    markerShapes: [MarkerShape.none],
    markerSizes: [6.0],
  );

  static const SeriesTheme highContrast = SeriesTheme(
    colors: [
      Color(0xFF000000), // Black
      Color(0xFFFF0000), // Red
      Color(0xFF0000FF), // Blue
      Color(0xFF00FF00), // Green
    ],
    lineWidths: [3.0],
    dashPatterns: [null],
    markerShapes: [MarkerShape.circle, MarkerShape.square, MarkerShape.triangle, MarkerShape.diamond],
    markerSizes: [12.0],
  );

  static const SeriesTheme colorblindFriendly = SeriesTheme(
    colors: [
      Color(0xFF0173B2), // Blue (safe for all types)
      Color(0xFFDE8F05), // Orange (safe for all types)
      Color(0xFF029E73), // Teal (safe for all types)
      Color(0xFFCC78BC), // Pink (safe for all types)
      Color(0xFFCA9161), // Tan (safe for all types)
      Color(0xFF949494), // Gray (safe for all types)
      Color(0xFFECE133), // Yellow (safe for all types)
    ],
    lineWidths: [2.5],
    dashPatterns: [null, [8.0, 4.0], [2.0, 2.0]], // Varied for redundant encoding
    markerShapes: [
      MarkerShape.circle,
      MarkerShape.square,
      MarkerShape.triangle,
      MarkerShape.diamond,
      MarkerShape.cross,
      MarkerShape.plus,
      MarkerShape.star,
    ], // Redundant shape encoding
    markerSizes: [9.0],
  );

  // ========== Customization ==========

  SeriesTheme copyWith({
    List<Color>? colors,
    List<double>? lineWidths,
    List<List<double>?>? dashPatterns,
    List<MarkerShape>? markerShapes,
    List<double>? markerSizes,
  }) {
    return SeriesTheme(
      colors: colors ?? this.colors,
      lineWidths: lineWidths ?? this.lineWidths,
      dashPatterns: dashPatterns ?? this.dashPatterns,
      markerShapes: markerShapes ?? this.markerShapes,
      markerSizes: markerSizes ?? this.markerSizes,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((c) => '#${c.value.toRadixString(16).padLeft(8, '0')}').toList(),
      'lineWidths': lineWidths,
      'dashPatterns': dashPatterns,
      'markerShapes': markerShapes.map((s) => s.name).toList(),
      'markerSizes': markerSizes,
    };
  }

  static SeriesTheme fromJson(Map<String, dynamic> json) {
    return SeriesTheme(
      colors: (json['colors'] as List<dynamic>?)
          ?.map((c) => _parseColor(c))
          .whereType<Color>()
          .toList() ?? defaultLight.colors,
      lineWidths: (json['lineWidths'] as List<dynamic>?)
          ?.map((w) => (w as num).toDouble())
          .toList() ?? defaultLight.lineWidths,
      dashPatterns: (json['dashPatterns'] as List<dynamic>?)
          ?.map((p) => p == null ? null : (p as List<dynamic>).map((e) => (e as num).toDouble()).toList())
          .toList() ?? defaultLight.dashPatterns,
      markerShapes: (json['markerShapes'] as List<dynamic>?)
          ?.map((s) => _parseMarkerShape(s))
          .whereType<MarkerShape>()
          .toList() ?? defaultLight.markerShapes,
      markerSizes: (json['markerSizes'] as List<dynamic>?)
          ?.map((s) => (s as num).toDouble())
          .toList() ?? defaultLight.markerSizes,
    );
  }

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;
    final hex = value.substring(1);
    if (hex.length != 8) return null;
    return Color(int.parse(hex, radix: 16));
  }

  static MarkerShape? _parseMarkerShape(dynamic value) {
    if (value is! String) return null;
    return MarkerShape.values.firstWhere((s) => s.name == value, orElse: () => MarkerShape.circle);
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesTheme &&
        _listEquals(other.colors, colors) &&
        _listEquals(other.lineWidths, lineWidths) &&
        _listOfListEquals(other.dashPatterns, dashPatterns) &&
        _listEquals(other.markerShapes, markerShapes) &&
        _listEquals(other.markerSizes, markerSizes);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(colors),
    Object.hashAll(lineWidths),
    Object.hashAll(dashPatterns.map((p) => p == null ? 0 : Object.hashAll(p))),
    Object.hashAll(markerShapes),
    Object.hashAll(markerSizes),
  );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _listOfListEquals(List<List<double>?> a, List<List<double>?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] == null && b[i] == null) continue;
      if (a[i] == null || b[i] == null) return false;
      if (!_listEquals(a[i]!, b[i]!)) return false;
    }
    return true;
  }
}
