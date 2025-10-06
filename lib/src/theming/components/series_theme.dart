// SeriesTheme Implementation
// Feature: 004-theming-system
// Phase 1: Core Data Structures (T011)

import 'package:flutter/material.dart';

/// Marker shapes for series data points.
enum MarkerShape {
  circle,
  square,
  triangle,
  diamond,
  cross,
  plus,
  star,
  none,
}

/// Theming for chart data series.
///
/// Provides color, line style, and marker configuration for multiple series.
/// Properties cycle when accessing indices beyond the list length.
///
/// Example:
/// ```dart
/// final theme = SeriesTheme(
///   colors: [Colors.blue, Colors.red, Colors.green],
///   lineWidths: [2.0],
///   markerSizes: [6.0],
///   markerShapes: [MarkerShape.circle],
/// );
/// print(theme.colorAt(0)); // Colors.blue
/// print(theme.colorAt(3)); // Colors.blue (cycles)
/// ```
class SeriesTheme {
  SeriesTheme({
    required this.colors,
    required this.lineWidths,
    required this.markerSizes,
    required this.markerShapes,
  })  : assert(colors.isNotEmpty, 'colors must have at least 1 element'),
        assert(lineWidths.isNotEmpty, 'lineWidths must have at least 1 element'),
        assert(markerSizes.isNotEmpty, 'markerSizes must have at least 1 element'),
        assert(markerShapes.isNotEmpty, 'markerShapes must have at least 1 element');

  /// Colors for series. Cycles when series count exceeds list length.
  final List<Color> colors;

  /// Line widths for series. Cycles when series count exceeds list length.
  final List<double> lineWidths;

  /// Marker sizes for series. Cycles when series count exceeds list length.
  final List<double> markerSizes;

  /// Marker shapes for series. Cycles when series count exceeds list length.
  final List<MarkerShape> markerShapes;

  // ========== Predefined Themes ==========

  static final SeriesTheme defaultLight = SeriesTheme(
    colors: const [
      Color(0xFF2196F3), // Blue
      Color(0xFFF44336), // Red
      Color(0xFF4CAF50), // Green
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
    ],
    lineWidths: const [2.0],
    markerSizes: const [6.0],
    markerShapes: const [MarkerShape.circle],
  );

  static final SeriesTheme defaultDark = SeriesTheme(
    colors: const [
      Color(0xFF64B5F6), // Light Blue
      Color(0xFFEF5350), // Light Red
      Color(0xFF66BB6A), // Light Green
      Color(0xFFFFB74D), // Light Orange
      Color(0xFFBA68C8), // Light Purple
    ],
    lineWidths: const [2.0],
    markerSizes: const [6.0],
    markerShapes: const [MarkerShape.circle],
  );

  static final SeriesTheme corporateBlue = SeriesTheme(
    colors: const [
      Color(0xFF1976D2), // Primary Blue
      Color(0xFF0288D1), // Light Blue
      Color(0xFF0097A7), // Cyan
      Color(0xFF00796B), // Teal
      Color(0xFF388E3C), // Green
    ],
    lineWidths: const [2.0],
    markerSizes: const [6.0],
    markerShapes: const [MarkerShape.square],
  );

  static final SeriesTheme vibrant = SeriesTheme(
    colors: const [
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFF3F51B5), // Indigo
      Color(0xFF00BCD4), // Cyan
      Color(0xFFCDDC39), // Lime
      Color(0xFFFF5722), // Deep Orange
    ],
    lineWidths: const [2.5],
    markerSizes: const [8.0],
    markerShapes: const [MarkerShape.circle, MarkerShape.square, MarkerShape.triangle],
  );

  static final SeriesTheme minimal = SeriesTheme(
    colors: const [
      Color(0xFF757575), // Gray
      Color(0xFF9E9E9E), // Light Gray
      Color(0xFF616161), // Dark Gray
    ],
    lineWidths: const [1.5],
    markerSizes: const [4.0],
    markerShapes: const [MarkerShape.circle],
  );

  static final SeriesTheme highContrast = SeriesTheme(
    colors: const [
      Color(0xFF000000), // Black
      Color(0xFFFFFFFF), // White
      Color(0xFFFF0000), // Red
      Color(0xFF0000FF), // Blue
    ],
    lineWidths: const [3.0],
    markerSizes: const [10.0],
    markerShapes: const [MarkerShape.square],
  );

  static final SeriesTheme colorblindFriendly = SeriesTheme(
    colors: const [
      Color(0xFF0173B2), // Blue
      Color(0xFFDE8F05), // Orange
      Color(0xFF029E73), // Teal
      Color(0xFFCC78BC), // Pink
      Color(0xFFECE133), // Yellow
      Color(0xFF56B4E9), // Light Blue
    ],
    lineWidths: const [2.0],
    markerSizes: const [7.0],
    markerShapes: const [
      MarkerShape.circle,
      MarkerShape.square,
      MarkerShape.triangle,
      MarkerShape.diamond,
    ],
  );

  // ========== Cycling Accessors ==========

  /// Get color at index with cycling.
  Color colorAt(int index) => colors[index % colors.length];

  /// Get line width at index with cycling.
  double lineWidthAt(int index) => lineWidths[index % lineWidths.length];

  /// Get marker size at index with cycling.
  double markerSizeAt(int index) => markerSizes[index % markerSizes.length];

  /// Get marker shape at index with cycling.
  MarkerShape markerShapeAt(int index) => markerShapes[index % markerShapes.length];

  // ========== Customization ==========

  SeriesTheme copyWith({
    List<Color>? colors,
    List<double>? lineWidths,
    List<double>? markerSizes,
    List<MarkerShape>? markerShapes,
  }) {
    return SeriesTheme(
      colors: colors ?? this.colors,
      lineWidths: lineWidths ?? this.lineWidths,
      markerSizes: markerSizes ?? this.markerSizes,
      markerShapes: markerShapes ?? this.markerShapes,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((c) => '#${c.value.toRadixString(16).padLeft(8, '0')}').toList(),
      'lineWidths': lineWidths,
      'markerSizes': markerSizes,
      'markerShapes': markerShapes.map((s) => s.name).toList(),
    };
  }

  static SeriesTheme fromJson(Map<String, dynamic> json) {
    return SeriesTheme(
      colors: (json['colors'] as List<dynamic>?)
              ?.map((c) => _parseColor(c))
              .whereType<Color>()
              .toList() ??
          defaultLight.colors,
      lineWidths: (json['lineWidths'] as List<dynamic>?)
              ?.map((w) => (w as num).toDouble())
              .toList() ??
          defaultLight.lineWidths,
      markerSizes: (json['markerSizes'] as List<dynamic>?)
              ?.map((s) => (s as num).toDouble())
              .toList() ??
          defaultLight.markerSizes,
      markerShapes: (json['markerShapes'] as List<dynamic>?)
              ?.map((s) => _parseMarkerShape(s))
              .whereType<MarkerShape>()
              .toList() ??
          defaultLight.markerShapes,
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
    try {
      return MarkerShape.values.firstWhere((s) => s.name == value);
    } catch (_) {
      return null;
    }
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesTheme &&
        _listEquals(other.colors, colors) &&
        _listEquals(other.lineWidths, lineWidths) &&
        _listEquals(other.markerSizes, markerSizes) &&
        _listEquals(other.markerShapes, markerShapes);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(colors),
        Object.hashAll(lineWidths),
        Object.hashAll(markerSizes),
        Object.hashAll(markerShapes),
      );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
