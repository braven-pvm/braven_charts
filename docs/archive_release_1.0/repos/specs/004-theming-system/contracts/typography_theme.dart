// CONTRACT: TypographyTheme
// Feature: 004-theming-system
//
// Defines font family, sizes, and responsive scaling for chart text.

import 'package:flutter/material.dart';

/// Styling for chart typography (fonts, sizes, responsive scaling).
///
/// Supports responsive scaling based on viewport width using breakpoints.
///
/// Example:
/// ```dart
/// final typography = TypographyTheme(
///   fontFamily: 'Roboto',
///   baseFontSize: 12.0,
///   titleFontSize: 16.0,
///   labelFontSize: 11.0,
///   fontWeight: FontWeight.normal,
/// );
///
/// // With responsive scaling:
/// final scaledTypography = typography.withScaleFactor(1.1); // Desktop
/// ```
class TypographyTheme {
  const TypographyTheme({
    required this.fontFamily,
    required this.baseFontSize,
    required this.titleFontSize,
    required this.labelFontSize,
    required this.fontWeight,
    this.scaleFactor = 1.0,
  }) : assert(
         baseFontSize >= 8.0,
         'baseFontSize must be >= 8.0 (minimum readable)',
       ),
       assert(titleFontSize >= 10.0, 'titleFontSize must be >= 10.0'),
       assert(labelFontSize >= 8.0, 'labelFontSize must be >= 8.0'),
       assert(
         scaleFactor >= 0.5 && scaleFactor <= 2.0,
         'scaleFactor must be 0.5-2.0',
       );

  /// Font family name. Should be available on target platform.
  final String fontFamily;

  /// Base font size in pixels (default text).
  final double baseFontSize;

  /// Chart title font size in pixels.
  final double titleFontSize;

  /// Axis label font size in pixels.
  final double labelFontSize;

  /// Font weight for text.
  final FontWeight fontWeight;

  /// Responsive scale factor (computed from viewport width).
  /// Applied to all font sizes: effectiveSize = baseSize * scaleFactor.
  final double scaleFactor;

  // ========== Responsive Scaling ==========

  /// Material Design 3 breakpoints (mobile, tablet, desktop).
  static const double mobileBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  /// Computes scale factor for given viewport width.
  /// - Mobile (<600px): 0.9x
  /// - Tablet (600-1023px): 1.0x
  /// - Desktop (>=1024px): 1.1x
  static double computeScaleFactor(double viewportWidth) {
    if (viewportWidth < mobileBreakpoint) return 0.9;
    if (viewportWidth < desktopBreakpoint) return 1.0;
    return 1.1;
  }

  /// Returns a new TypographyTheme with the given scale factor.
  TypographyTheme withScaleFactor(double scaleFactor) {
    return TypographyTheme(
      fontFamily: fontFamily,
      baseFontSize: baseFontSize,
      titleFontSize: titleFontSize,
      labelFontSize: labelFontSize,
      fontWeight: fontWeight,
      scaleFactor: scaleFactor,
    );
  }

  /// Gets effective base font size (with scale factor applied).
  /// Minimum 8.0px enforced.
  double get effectiveBaseFontSize =>
      (baseFontSize * scaleFactor).clamp(8.0, double.infinity);

  /// Gets effective title font size (with scale factor applied).
  /// Minimum 10.0px enforced.
  double get effectiveTitleFontSize =>
      (titleFontSize * scaleFactor).clamp(10.0, double.infinity);

  /// Gets effective label font size (with scale factor applied).
  /// Minimum 8.0px enforced.
  double get effectiveLabelFontSize =>
      (labelFontSize * scaleFactor).clamp(8.0, double.infinity);

  // ========== Predefined Themes ==========

  static const TypographyTheme defaultLight = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    titleFontSize: 16.0,
    labelFontSize: 11.0,
    fontWeight: FontWeight.normal,
    scaleFactor: 1.0,
  );

  static const TypographyTheme defaultDark = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    titleFontSize: 16.0,
    labelFontSize: 11.0,
    fontWeight: FontWeight.normal,
    scaleFactor: 1.0,
  );

  static const TypographyTheme corporateBlue = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    titleFontSize: 16.0,
    labelFontSize: 11.0,
    fontWeight: FontWeight.w500,
    scaleFactor: 1.0,
  );

  static const TypographyTheme vibrant = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 13.0,
    titleFontSize: 18.0,
    labelFontSize: 12.0,
    fontWeight: FontWeight.w500,
    scaleFactor: 1.0,
  );

  static const TypographyTheme minimal = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 11.0,
    titleFontSize: 14.0,
    labelFontSize: 10.0,
    fontWeight: FontWeight.normal,
    scaleFactor: 1.0,
  );

  static const TypographyTheme highContrast = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 14.0,
    titleFontSize: 18.0,
    labelFontSize: 13.0,
    fontWeight: FontWeight.w600,
    scaleFactor: 1.0,
  );

  static const TypographyTheme colorblindFriendly = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    titleFontSize: 16.0,
    labelFontSize: 11.0,
    fontWeight: FontWeight.w500,
    scaleFactor: 1.0,
  );

  // ========== Customization ==========

  TypographyTheme copyWith({
    String? fontFamily,
    double? baseFontSize,
    double? titleFontSize,
    double? labelFontSize,
    FontWeight? fontWeight,
    double? scaleFactor,
  }) {
    return TypographyTheme(
      fontFamily: fontFamily ?? this.fontFamily,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'baseFontSize': baseFontSize,
      'titleFontSize': titleFontSize,
      'labelFontSize': labelFontSize,
      'fontWeight': fontWeight.toString(),
      'scaleFactor': scaleFactor,
    };
  }

  static TypographyTheme fromJson(Map<String, dynamic> json) {
    return TypographyTheme(
      fontFamily: json['fontFamily'] as String? ?? defaultLight.fontFamily,
      baseFontSize:
          (json['baseFontSize'] as num?)?.toDouble() ??
          defaultLight.baseFontSize,
      titleFontSize:
          (json['titleFontSize'] as num?)?.toDouble() ??
          defaultLight.titleFontSize,
      labelFontSize:
          (json['labelFontSize'] as num?)?.toDouble() ??
          defaultLight.labelFontSize,
      fontWeight:
          _parseFontWeight(json['fontWeight']) ?? defaultLight.fontWeight,
      scaleFactor:
          (json['scaleFactor'] as num?)?.toDouble() ?? defaultLight.scaleFactor,
    );
  }

  static FontWeight? _parseFontWeight(dynamic value) {
    if (value is! String) return null;
    if (value == 'FontWeight.w100') return FontWeight.w100;
    if (value == 'FontWeight.w200') return FontWeight.w200;
    if (value == 'FontWeight.w300') return FontWeight.w300;
    if (value == 'FontWeight.w400') return FontWeight.w400;
    if (value == 'FontWeight.w500') return FontWeight.w500;
    if (value == 'FontWeight.w600') return FontWeight.w600;
    if (value == 'FontWeight.w700') return FontWeight.w700;
    if (value == 'FontWeight.w800') return FontWeight.w800;
    if (value == 'FontWeight.w900') return FontWeight.w900;
    return null;
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypographyTheme &&
        other.fontFamily == fontFamily &&
        other.baseFontSize == baseFontSize &&
        other.titleFontSize == titleFontSize &&
        other.labelFontSize == labelFontSize &&
        other.fontWeight == fontWeight &&
        other.scaleFactor == scaleFactor;
  }

  @override
  int get hashCode => Object.hash(
    fontFamily,
    baseFontSize,
    titleFontSize,
    labelFontSize,
    fontWeight,
    scaleFactor,
  );
}
