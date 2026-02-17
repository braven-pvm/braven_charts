// CONTRACT: AnimationTheme
// Feature: 004-theming-system
//
// Defines animation durations and curves for chart transitions.

import 'package:flutter/material.dart';

/// Styling for chart animations (data updates, theme switching).
///
/// Example:
/// ```dart
/// final animationTheme = AnimationTheme(
///   dataUpdateDuration: Duration(milliseconds: 300),
///   dataUpdateCurve: Curves.easeInOut,
///   themeSwitchDuration: Duration(milliseconds: 200),
///   themeSwitchCurve: Curves.easeInOut,
/// );
/// ```
class AnimationTheme {
  const AnimationTheme({
    required this.dataUpdateDuration,
    required this.dataUpdateCurve,
    required this.themeSwitchDuration,
    required this.themeSwitchCurve,
  });

  /// Duration for animating data changes (adding/removing/updating points).
  final Duration dataUpdateDuration;

  /// Curve for data update animations.
  final Curve dataUpdateCurve;

  /// Duration for animating theme switches.
  final Duration themeSwitchDuration;

  /// Curve for theme switch animations.
  final Curve themeSwitchCurve;

  // ========== Predefined Themes ==========

  static const AnimationTheme defaultLight = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 300),
    dataUpdateCurve: Curves.easeInOut,
    themeSwitchDuration: Duration(milliseconds: 200),
    themeSwitchCurve: Curves.easeInOut,
  );

  static const AnimationTheme defaultDark = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 300),
    dataUpdateCurve: Curves.easeInOut,
    themeSwitchDuration: Duration(milliseconds: 200),
    themeSwitchCurve: Curves.easeInOut,
  );

  static const AnimationTheme corporateBlue = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 250),
    dataUpdateCurve: Curves.easeInOut,
    themeSwitchDuration: Duration(milliseconds: 150),
    themeSwitchCurve: Curves.easeInOut,
  );

  static const AnimationTheme vibrant = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 400),
    dataUpdateCurve: Curves.elasticOut,
    themeSwitchDuration: Duration(milliseconds: 250),
    themeSwitchCurve: Curves.easeInOut,
  );

  static const AnimationTheme minimal = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 200),
    dataUpdateCurve: Curves.linear,
    themeSwitchDuration: Duration(milliseconds: 100),
    themeSwitchCurve: Curves.linear,
  );

  static const AnimationTheme highContrast = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 200),
    dataUpdateCurve: Curves.easeInOut,
    themeSwitchDuration: Duration(milliseconds: 100),
    themeSwitchCurve: Curves.easeInOut,
  );

  static const AnimationTheme colorblindFriendly = AnimationTheme(
    dataUpdateDuration: Duration(milliseconds: 300),
    dataUpdateCurve: Curves.easeInOut,
    themeSwitchDuration: Duration(milliseconds: 200),
    themeSwitchCurve: Curves.easeInOut,
  );

  // ========== Customization ==========

  AnimationTheme copyWith({
    Duration? dataUpdateDuration,
    Curve? dataUpdateCurve,
    Duration? themeSwitchDuration,
    Curve? themeSwitchCurve,
  }) {
    return AnimationTheme(
      dataUpdateDuration: dataUpdateDuration ?? this.dataUpdateDuration,
      dataUpdateCurve: dataUpdateCurve ?? this.dataUpdateCurve,
      themeSwitchDuration: themeSwitchDuration ?? this.themeSwitchDuration,
      themeSwitchCurve: themeSwitchCurve ?? this.themeSwitchCurve,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'dataUpdateDuration': dataUpdateDuration.inMilliseconds,
      'dataUpdateCurve': _curveName(dataUpdateCurve),
      'themeSwitchDuration': themeSwitchDuration.inMilliseconds,
      'themeSwitchCurve': _curveName(themeSwitchCurve),
    };
  }

  static AnimationTheme fromJson(Map<String, dynamic> json) {
    return AnimationTheme(
      dataUpdateDuration: Duration(
        milliseconds: json['dataUpdateDuration'] as int? ?? 300,
      ),
      dataUpdateCurve: _parseCurve(json['dataUpdateCurve']) ?? Curves.easeInOut,
      themeSwitchDuration: Duration(
        milliseconds: json['themeSwitchDuration'] as int? ?? 200,
      ),
      themeSwitchCurve:
          _parseCurve(json['themeSwitchCurve']) ?? Curves.easeInOut,
    );
  }

  static String _curveName(Curve curve) {
    if (curve == Curves.linear) return 'linear';
    if (curve == Curves.easeIn) return 'easeIn';
    if (curve == Curves.easeOut) return 'easeOut';
    if (curve == Curves.easeInOut) return 'easeInOut';
    if (curve == Curves.fastOutSlowIn) return 'fastOutSlowIn';
    if (curve == Curves.elasticOut) return 'elasticOut';
    return 'easeInOut'; // Default fallback
  }

  static Curve _parseCurve(dynamic value) {
    if (value is! String) return Curves.easeInOut;
    switch (value) {
      case 'linear':
        return Curves.linear;
      case 'easeIn':
        return Curves.easeIn;
      case 'easeOut':
        return Curves.easeOut;
      case 'easeInOut':
        return Curves.easeInOut;
      case 'fastOutSlowIn':
        return Curves.fastOutSlowIn;
      case 'elasticOut':
        return Curves.elasticOut;
      default:
        return Curves.easeInOut;
    }
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimationTheme &&
        other.dataUpdateDuration == dataUpdateDuration &&
        other.dataUpdateCurve == dataUpdateCurve &&
        other.themeSwitchDuration == themeSwitchDuration &&
        other.themeSwitchCurve == themeSwitchCurve;
  }

  @override
  int get hashCode => Object.hash(
    dataUpdateDuration,
    dataUpdateCurve,
    themeSwitchDuration,
    themeSwitchCurve,
  );
}
