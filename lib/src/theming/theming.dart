// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

/// The Braven Charts theming system.
///
/// This library provides a comprehensive theming system for customizing the
/// appearance and behavior of charts. It includes:
///
/// - **ChartTheme**: The root theme class that aggregates all styling components
/// - **Component themes**: GridStyle, AxisStyle, SeriesTheme, InteractionTheme,
///   TypographyTheme, AnimationTheme
/// - **Utilities**: ColorUtils for accessibility and colorblind support
///
/// ## Quick Start
///
/// Use one of the predefined themes:
/// ```dart
/// final theme = ChartTheme.defaultLight;
/// final darkTheme = ChartTheme.defaultDark;
/// ```
///
/// Or create a custom theme:
/// ```dart
/// final customTheme = ChartTheme.defaultLight.copyWith(
///   backgroundColor: Colors.blue,
///   seriesTheme: SeriesTheme.vibrant,
/// );
/// ```
///
/// ## Predefined Themes
///
/// Seven built-in themes are available:
/// - `defaultLight`: Clean light theme for general use
/// - `defaultDark`: Material-inspired dark theme
/// - `corporateBlue`: Professional blue color scheme
/// - `vibrant`: Bold and colorful
/// - `minimal`: Understated and clean
/// - `highContrast`: Maximum accessibility
/// - `colorblindFriendly`: Optimized for colorblind users (Okabe-Ito palette)
///
/// ## Accessibility
///
/// Use `ColorUtils` for WCAG compliance:
/// ```dart
/// final ratio = ColorUtils.calculateContrastRatio(foreground, background);
/// final meetsAA = ColorUtils.meetsWCAG_AA(foreground, background, isLargeText: false);
/// ```
///
/// Simulate colorblindness:
/// ```dart
/// final protanopia = ColorUtils.simulateProtanopia(color);
/// final deuteranopia = ColorUtils.simulateDeuteranopia(color);
/// ```
library theming;

// Root theme
export 'chart_theme.dart';

// Component themes
export 'components/grid_style.dart';
export 'components/axis_style.dart';
export 'components/series_theme.dart';
export 'components/interaction_theme.dart';
export 'components/typography_theme.dart';
export 'components/animation_theme.dart';

// Utilities
export 'utilities/color_utils.dart';
