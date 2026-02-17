// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'package:flutter/animation.dart';

/// Defines animation settings for chart transitions and interactions.
///
/// This theme controls:
/// - Data update animations when chart data changes
/// - Theme change animations when switching between themes
/// - Interaction animations for tooltips, selections, and highlighting
///
/// Example:
/// ```dart
/// final theme = AnimationTheme(
///   dataUpdateDuration: Duration(milliseconds: 400),
///   dataUpdateCurve: Curves.easeInOutCubic,
///   themeChangeDuration: Duration(milliseconds: 300),
///   themeChangeCurve: Curves.easeOut,
///   interactionDuration: Duration(milliseconds: 150),
///   interactionCurve: Curves.easeOut,
/// );
/// ```
class AnimationTheme {
  // ========== Constructor ==========

  /// Creates an animation theme with the specified settings.
  ///
  /// Validates that:
  /// - [dataUpdateDuration] >= Duration.zero
  /// - [themeChangeDuration] >= Duration.zero
  /// - [interactionDuration] >= Duration.zero
  AnimationTheme({
    required this.dataUpdateDuration,
    required this.dataUpdateCurve,
    required this.themeChangeDuration,
    required this.themeChangeCurve,
    required this.interactionDuration,
    required this.interactionCurve,
  }) : assert(
         dataUpdateDuration >= Duration.zero,
         'dataUpdateDuration must be >= Duration.zero',
       ),
       assert(
         themeChangeDuration >= Duration.zero,
         'themeChangeDuration must be >= Duration.zero',
       ),
       assert(
         interactionDuration >= Duration.zero,
         'interactionDuration must be >= Duration.zero',
       );

  /// Creates a theme from a JSON map.
  factory AnimationTheme.fromJson(Map<String, dynamic> json) {
    return AnimationTheme(
      dataUpdateDuration: Duration(
        milliseconds: json['dataUpdateDurationMs'] as int,
      ),
      dataUpdateCurve: _parseCurve(json['dataUpdateCurve'] as String),
      themeChangeDuration: Duration(
        milliseconds: json['themeChangeDurationMs'] as int,
      ),
      themeChangeCurve: _parseCurve(json['themeChangeCurve'] as String),
      interactionDuration: Duration(
        milliseconds: json['interactionDurationMs'] as int,
      ),
      interactionCurve: _parseCurve(json['interactionCurve'] as String),
    );
  }
  // ========== Properties ==========

  /// Duration for animating data updates.
  /// Must be >= Duration.zero. Zero means no animation.
  final Duration dataUpdateDuration;

  /// Curve for data update animations.
  final Curve dataUpdateCurve;

  /// Duration for animating theme changes.
  /// Must be >= Duration.zero. Zero means no animation.
  final Duration themeChangeDuration;

  /// Curve for theme change animations.
  final Curve themeChangeCurve;

  /// Duration for animating user interactions (hover, selection).
  /// Must be >= Duration.zero. Zero means no animation.
  final Duration interactionDuration;

  /// Curve for interaction animations.
  final Curve interactionCurve;

  // ========== Predefined Themes ==========

  static final AnimationTheme defaultLight = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 400),
    dataUpdateCurve: Curves.easeInOutCubic,
    themeChangeDuration: const Duration(milliseconds: 300),
    themeChangeCurve: Curves.easeOut,
    interactionDuration: const Duration(milliseconds: 150),
    interactionCurve: Curves.easeOut,
  );

  static final AnimationTheme defaultDark = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 350),
    dataUpdateCurve: Curves.easeInOutCubic,
    themeChangeDuration: const Duration(milliseconds: 250),
    themeChangeCurve: Curves.easeOut,
    interactionDuration: const Duration(milliseconds: 120),
    interactionCurve: Curves.easeOut,
  );

  static final AnimationTheme corporateBlue = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 500),
    dataUpdateCurve: Curves.easeInOut,
    themeChangeDuration: const Duration(milliseconds: 300),
    themeChangeCurve: Curves.easeInOut,
    interactionDuration: const Duration(milliseconds: 200),
    interactionCurve: Curves.easeOut,
  );

  static final AnimationTheme vibrant = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 600),
    dataUpdateCurve: Curves.elasticOut,
    themeChangeDuration: const Duration(milliseconds: 400),
    themeChangeCurve: Curves.fastOutSlowIn,
    interactionDuration: const Duration(milliseconds: 200),
    interactionCurve: Curves.easeOutBack,
  );

  static final AnimationTheme minimal = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 250),
    dataUpdateCurve: Curves.linear,
    themeChangeDuration: const Duration(milliseconds: 200),
    themeChangeCurve: Curves.linear,
    interactionDuration: const Duration(milliseconds: 100),
    interactionCurve: Curves.linear,
  );

  static final AnimationTheme highContrast = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 300),
    dataUpdateCurve: Curves.easeInOut,
    themeChangeDuration: const Duration(milliseconds: 250),
    themeChangeCurve: Curves.easeInOut,
    interactionDuration: const Duration(milliseconds: 150),
    interactionCurve: Curves.easeOut,
  );

  static final AnimationTheme colorblindFriendly = AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 400),
    dataUpdateCurve: Curves.easeInOutCubic,
    themeChangeDuration: const Duration(milliseconds: 300),
    themeChangeCurve: Curves.easeOut,
    interactionDuration: const Duration(milliseconds: 150),
    interactionCurve: Curves.easeOut,
  );

  // ========== Methods ==========

  /// Creates a copy of this theme with the given fields replaced.
  AnimationTheme copyWith({
    Duration? dataUpdateDuration,
    Curve? dataUpdateCurve,
    Duration? themeChangeDuration,
    Curve? themeChangeCurve,
    Duration? interactionDuration,
    Curve? interactionCurve,
  }) {
    return AnimationTheme(
      dataUpdateDuration: dataUpdateDuration ?? this.dataUpdateDuration,
      dataUpdateCurve: dataUpdateCurve ?? this.dataUpdateCurve,
      themeChangeDuration: themeChangeDuration ?? this.themeChangeDuration,
      themeChangeCurve: themeChangeCurve ?? this.themeChangeCurve,
      interactionDuration: interactionDuration ?? this.interactionDuration,
      interactionCurve: interactionCurve ?? this.interactionCurve,
    );
  }

  /// Converts this theme to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'dataUpdateDurationMs': dataUpdateDuration.inMilliseconds,
      'dataUpdateCurve': _curveName(dataUpdateCurve),
      'themeChangeDurationMs': themeChangeDuration.inMilliseconds,
      'themeChangeCurve': _curveName(themeChangeCurve),
      'interactionDurationMs': interactionDuration.inMilliseconds,
      'interactionCurve': _curveName(interactionCurve),
    };
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnimationTheme) return false;

    return dataUpdateDuration == other.dataUpdateDuration &&
        dataUpdateCurve == other.dataUpdateCurve &&
        themeChangeDuration == other.themeChangeDuration &&
        themeChangeCurve == other.themeChangeCurve &&
        interactionDuration == other.interactionDuration &&
        interactionCurve == other.interactionCurve;
  }

  @override
  int get hashCode {
    return Object.hash(
      dataUpdateDuration,
      dataUpdateCurve,
      themeChangeDuration,
      themeChangeCurve,
      interactionDuration,
      interactionCurve,
    );
  }

  // ========== Helper Methods ==========

  /// Gets a string name for common Flutter curves.
  static String _curveName(Curve curve) {
    if (curve == Curves.linear) return 'linear';
    if (curve == Curves.easeIn) return 'easeIn';
    if (curve == Curves.easeOut) return 'easeOut';
    if (curve == Curves.easeInOut) return 'easeInOut';
    if (curve == Curves.easeInCubic) return 'easeInCubic';
    if (curve == Curves.easeOutCubic) return 'easeOutCubic';
    if (curve == Curves.easeInOutCubic) return 'easeInOutCubic';
    if (curve == Curves.fastOutSlowIn) return 'fastOutSlowIn';
    if (curve == Curves.bounceIn) return 'bounceIn';
    if (curve == Curves.bounceOut) return 'bounceOut';
    if (curve == Curves.bounceInOut) return 'bounceInOut';
    if (curve == Curves.elasticIn) return 'elasticIn';
    if (curve == Curves.elasticOut) return 'elasticOut';
    if (curve == Curves.elasticInOut) return 'elasticInOut';
    if (curve == Curves.easeOutBack) return 'easeOutBack';
    return 'linear'; // Default fallback
  }

  /// Parses a curve from its string name.
  static Curve _parseCurve(String name) {
    switch (name) {
      case 'linear':
        return Curves.linear;
      case 'easeIn':
        return Curves.easeIn;
      case 'easeOut':
        return Curves.easeOut;
      case 'easeInOut':
        return Curves.easeInOut;
      case 'easeInCubic':
        return Curves.easeInCubic;
      case 'easeOutCubic':
        return Curves.easeOutCubic;
      case 'easeInOutCubic':
        return Curves.easeInOutCubic;
      case 'fastOutSlowIn':
        return Curves.fastOutSlowIn;
      case 'bounceIn':
        return Curves.bounceIn;
      case 'bounceOut':
        return Curves.bounceOut;
      case 'bounceInOut':
        return Curves.bounceInOut;
      case 'elasticIn':
        return Curves.elasticIn;
      case 'elasticOut':
        return Curves.elasticOut;
      case 'elasticInOut':
        return Curves.elasticInOut;
      case 'easeOutBack':
        return Curves.easeOutBack;
      default:
        return Curves.linear; // Default fallback
    }
  }
}
