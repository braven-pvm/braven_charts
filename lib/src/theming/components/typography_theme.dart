// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

/// Defines typography settings for chart text elements.
///
/// This theme controls:
/// - Font family for all text
/// - Base font size
/// - Responsive scaling factors for different viewport sizes
/// - Multipliers for different text types (titles, labels)
///
/// Example:
/// ```dart
/// final theme = TypographyTheme(
///   fontFamily: 'Roboto',
///   baseFontSize: 12.0,
///   scaleFactorMobile: 0.9,
///   scaleFactorTablet: 1.0,
///   scaleFactorDesktop: 1.1,
///   titleMultiplier: 1.4,
///   labelMultiplier: 1.0,
/// );
/// ```
class TypographyTheme {
  // ========== Constructor ==========

  /// Creates a typography theme with the specified settings.
  ///
  /// Validates that:
  /// - [baseFontSize] > 0
  /// - [scaleFactorMobile] > 0
  /// - [scaleFactorTablet] > 0
  /// - [scaleFactorDesktop] > 0
  /// - [titleMultiplier] > 0
  /// - [labelMultiplier] > 0
  TypographyTheme({
    required this.fontFamily,
    required this.baseFontSize,
    required this.scaleFactorMobile,
    required this.scaleFactorTablet,
    required this.scaleFactorDesktop,
    required this.titleMultiplier,
    required this.labelMultiplier,
  })  : assert(baseFontSize > 0, 'baseFontSize must be > 0'),
        assert(scaleFactorMobile > 0, 'scaleFactorMobile must be > 0'),
        assert(scaleFactorTablet > 0, 'scaleFactorTablet must be > 0'),
        assert(scaleFactorDesktop > 0, 'scaleFactorDesktop must be > 0'),
        assert(titleMultiplier > 0, 'titleMultiplier must be > 0'),
        assert(labelMultiplier > 0, 'labelMultiplier must be > 0');

  /// Creates a theme from a JSON map.
  factory TypographyTheme.fromJson(Map<String, dynamic> json) {
    return TypographyTheme(
      fontFamily: json['fontFamily'] as String,
      baseFontSize: (json['baseFontSize'] as num).toDouble(),
      scaleFactorMobile: (json['scaleFactorMobile'] as num).toDouble(),
      scaleFactorTablet: (json['scaleFactorTablet'] as num).toDouble(),
      scaleFactorDesktop: (json['scaleFactorDesktop'] as num).toDouble(),
      titleMultiplier: (json['titleMultiplier'] as num).toDouble(),
      labelMultiplier: (json['labelMultiplier'] as num).toDouble(),
    );
  }
  // ========== Properties ==========

  /// Font family used for all text in charts.
  final String fontFamily;

  /// Base font size in logical pixels.
  /// Must be > 0. All other sizes are calculated from this base.
  final double baseFontSize;

  /// Scale factor applied for mobile viewports.
  /// Must be > 0. Typically 0.8-1.0 for smaller screens.
  final double scaleFactorMobile;

  /// Scale factor applied for tablet viewports.
  /// Must be > 0. Typically 0.9-1.1 for medium screens.
  final double scaleFactorTablet;

  /// Scale factor applied for desktop viewports.
  /// Must be > 0. Typically 1.0-1.2 for larger screens.
  final double scaleFactorDesktop;

  /// Multiplier for title text sizes.
  /// Must be > 0. Typically 1.2-1.6 to make titles larger than labels.
  final double titleMultiplier;

  /// Multiplier for label text sizes.
  /// Must be > 0. Typically 0.9-1.1 for axis labels and legends.
  final double labelMultiplier;

  // ========== Predefined Themes ==========

  static final TypographyTheme defaultLight = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    scaleFactorMobile: 0.9,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.1,
    titleMultiplier: 1.4,
    labelMultiplier: 1.0,
  );

  static final TypographyTheme defaultDark = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 13.0, // Slightly larger for better readability on dark backgrounds
    scaleFactorMobile: 0.9,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.1,
    titleMultiplier: 1.3,
    labelMultiplier: 1.0,
  );

  static final TypographyTheme corporateBlue = TypographyTheme(
    fontFamily: 'Arial',
    baseFontSize: 11.0,
    scaleFactorMobile: 0.9,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.1,
    titleMultiplier: 1.5,
    labelMultiplier: 1.0,
  );

  static final TypographyTheme vibrant = TypographyTheme(
    fontFamily: 'Helvetica',
    baseFontSize: 13.0,
    scaleFactorMobile: 0.85,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.15,
    titleMultiplier: 1.6,
    labelMultiplier: 1.0,
  );

  static final TypographyTheme minimal = TypographyTheme(
    fontFamily: 'Helvetica',
    baseFontSize: 11.0,
    scaleFactorMobile: 0.9,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.0,
    titleMultiplier: 1.2,
    labelMultiplier: 0.95,
  );

  static final TypographyTheme highContrast = TypographyTheme(
    fontFamily: 'Arial',
    baseFontSize: 14.0,
    scaleFactorMobile: 1.0,
    scaleFactorTablet: 1.1,
    scaleFactorDesktop: 1.2,
    titleMultiplier: 1.5,
    labelMultiplier: 1.1,
  );

  static final TypographyTheme colorblindFriendly = TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    scaleFactorMobile: 0.9,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.1,
    titleMultiplier: 1.4,
    labelMultiplier: 1.0,
  );

  // ========== Methods ==========

  /// Creates a copy of this theme with the given fields replaced.
  TypographyTheme copyWith({
    String? fontFamily,
    double? baseFontSize,
    double? scaleFactorMobile,
    double? scaleFactorTablet,
    double? scaleFactorDesktop,
    double? titleMultiplier,
    double? labelMultiplier,
  }) {
    return TypographyTheme(
      fontFamily: fontFamily ?? this.fontFamily,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      scaleFactorMobile: scaleFactorMobile ?? this.scaleFactorMobile,
      scaleFactorTablet: scaleFactorTablet ?? this.scaleFactorTablet,
      scaleFactorDesktop: scaleFactorDesktop ?? this.scaleFactorDesktop,
      titleMultiplier: titleMultiplier ?? this.titleMultiplier,
      labelMultiplier: labelMultiplier ?? this.labelMultiplier,
    );
  }

  /// Converts this theme to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'baseFontSize': baseFontSize,
      'scaleFactorMobile': scaleFactorMobile,
      'scaleFactorTablet': scaleFactorTablet,
      'scaleFactorDesktop': scaleFactorDesktop,
      'titleMultiplier': titleMultiplier,
      'labelMultiplier': labelMultiplier,
    };
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TypographyTheme) return false;

    return fontFamily == other.fontFamily &&
        baseFontSize == other.baseFontSize &&
        scaleFactorMobile == other.scaleFactorMobile &&
        scaleFactorTablet == other.scaleFactorTablet &&
        scaleFactorDesktop == other.scaleFactorDesktop &&
        titleMultiplier == other.titleMultiplier &&
        labelMultiplier == other.labelMultiplier;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontFamily,
      baseFontSize,
      scaleFactorMobile,
      scaleFactorTablet,
      scaleFactorDesktop,
      titleMultiplier,
      labelMultiplier,
    );
  }
}
