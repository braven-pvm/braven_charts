// GridStyle Implementation
// Feature: 004-theming-system
// Phase 1: Core Data Structures (T009)

import 'package:flutter/material.dart';

/// Styling for chart grid lines (major and optional minor).
///
/// Grid lines can be solid or dashed. Dash patterns follow Canvas API format.
///
/// Example:
/// ```dart
/// final grid = GridStyle(
///   majorColor: Colors.grey[300]!,
///   majorWidth: 1.0,
///   majorDashPattern: [5.0, 5.0], // 5px on, 5px off
///   showMinor: true,
///   minorColor: Colors.grey[200]!,
///   minorWidth: 0.5,
/// );
/// ```
class GridStyle {
  const GridStyle({
    required this.majorColor,
    required this.majorWidth,
    this.majorDashPattern = const [],
    this.minorColor,
    this.minorWidth,
    this.minorDashPattern = const [],
    this.showMinor = false,
  })  : assert(majorWidth >= 0.0, 'majorWidth must be >= 0'),
        assert(minorWidth == null || minorWidth >= 0.0, 'minorWidth must be >= 0'),
        assert(!showMinor || (minorColor != null && minorWidth != null), 'If showMinor is true, minorColor and minorWidth must be provided');

  /// Color of major grid lines.
  final Color majorColor;

  /// Width of major grid lines in pixels. Use 0.0 for no major grid.
  final double majorWidth;

  /// Dash pattern for major grid lines. Empty list = solid line.
  /// Pattern format: [onLength, offLength, onLength, offLength, ...]
  /// Example: [5.0, 5.0] = 5px on, 5px off
  final List<double> majorDashPattern;

  /// Color of minor grid lines (if [showMinor] is true).
  final Color? minorColor;

  /// Width of minor grid lines in pixels.
  final double? minorWidth;

  /// Dash pattern for minor grid lines. Empty list = solid line.
  final List<double> minorDashPattern;

  /// Whether to show minor grid lines.
  final bool showMinor;

  // ========== Predefined Styles ==========

  static const GridStyle defaultLight = GridStyle(
    majorColor: Color(0xFFE0E0E0),
    majorWidth: 1.0,
    majorDashPattern: [],
    showMinor: false,
  );

  static const GridStyle defaultDark = GridStyle(
    majorColor: Color(0xFF424242),
    majorWidth: 1.0,
    majorDashPattern: [],
    showMinor: false,
  );

  static const GridStyle corporateBlue = GridStyle(
    majorColor: Color(0xFFCFD8DC),
    majorWidth: 1.0,
    majorDashPattern: [],
    showMinor: false,
  );

  static const GridStyle vibrant = GridStyle(
    majorColor: Color(0xFFE0E0E0),
    majorWidth: 1.5,
    majorDashPattern: [],
    showMinor: false,
  );

  static const GridStyle minimal = GridStyle(
    majorColor: Color(0xFFF5F5F5),
    majorWidth: 0.5,
    majorDashPattern: [],
    showMinor: false,
  );

  static const GridStyle highContrast = GridStyle(
    majorColor: Color(0xFF000000),
    majorWidth: 1.0,
    majorDashPattern: [],
    showMinor: false,
  );

  static const GridStyle colorblindFriendly = GridStyle(
    majorColor: Color(0xFFBDBDBD),
    majorWidth: 1.0,
    majorDashPattern: [5.0, 5.0], // Dashed to aid visual separation
    showMinor: false,
  );

  // ========== Customization ==========

  GridStyle copyWith({
    Color? majorColor,
    double? majorWidth,
    List<double>? majorDashPattern,
    Color? minorColor,
    double? minorWidth,
    List<double>? minorDashPattern,
    bool? showMinor,
  }) {
    return GridStyle(
      majorColor: majorColor ?? this.majorColor,
      majorWidth: majorWidth ?? this.majorWidth,
      majorDashPattern: majorDashPattern ?? this.majorDashPattern,
      minorColor: minorColor ?? this.minorColor,
      minorWidth: minorWidth ?? this.minorWidth,
      minorDashPattern: minorDashPattern ?? this.minorDashPattern,
      showMinor: showMinor ?? this.showMinor,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'majorColor': '#${majorColor.value.toRadixString(16).padLeft(8, '0')}',
      'majorWidth': majorWidth,
      'majorDashPattern': majorDashPattern,
      'minorColor': minorColor != null ? '#${minorColor!.value.toRadixString(16).padLeft(8, '0')}' : null,
      'minorWidth': minorWidth,
      'minorDashPattern': minorDashPattern,
      'showMinor': showMinor,
    };
  }

  static GridStyle fromJson(Map<String, dynamic> json) {
    return GridStyle(
      majorColor: _parseColor(json['majorColor']) ?? defaultLight.majorColor,
      majorWidth: (json['majorWidth'] as num?)?.toDouble() ?? defaultLight.majorWidth,
      majorDashPattern: (json['majorDashPattern'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      minorColor: _parseColor(json['minorColor']),
      minorWidth: (json['minorWidth'] as num?)?.toDouble(),
      minorDashPattern: (json['minorDashPattern'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      showMinor: json['showMinor'] as bool? ?? false,
    );
  }

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;
    final hex = value.substring(1);
    if (hex.length != 8) return null;
    return Color(int.parse(hex, radix: 16));
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridStyle &&
        other.majorColor == majorColor &&
        other.majorWidth == majorWidth &&
        _listEquals(other.majorDashPattern, majorDashPattern) &&
        other.minorColor == minorColor &&
        other.minorWidth == minorWidth &&
        _listEquals(other.minorDashPattern, minorDashPattern) &&
        other.showMinor == showMinor;
  }

  @override
  int get hashCode => Object.hash(
        majorColor,
        majorWidth,
        Object.hashAll(majorDashPattern),
        minorColor,
        minorWidth,
        Object.hashAll(minorDashPattern),
        showMinor,
      );

  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
