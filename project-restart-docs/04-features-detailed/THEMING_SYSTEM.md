# Theming System - Comprehensive Specification

## 🎨 Overview

The Braven Charts theming system provides complete visual control through a comprehensive, layered approach. The system includes 7 professionally designed themes and full customization capabilities for creating unique chart appearances.

## 🏗️ Architecture

### Theme Hierarchy

```dart
// Top-level theme container
class ChartTheme {
  // Foundation Colors & Layout
  final Color backgroundColor;
  final Color canvasBorderColor;
  final double canvasBorderWidth;
  final double canvasBorderRadius;
  final List<BoxShadow>? canvasShadows;
  final EdgeInsets padding;
  final EdgeInsets margin;

  // Grid System
  final GridStyle gridStyle;
  
  // Axis System  
  final AxisStyle axisStyle;
  
  // Data Visualization
  final SeriesTheme seriesTheme;
  
  // Interactive Elements
  final InteractionTheme interactionTheme;
  
  // Typography
  final TypographyTheme typography;
  
  // Animation
  final AnimationTheme animation;
}
```

### Component-Specific Themes

```dart
class GridStyle {
  final Color color;                    // Grid line color
  final double width;                   // Line thickness
  final List<double>? dashPattern;      // Dash pattern
  final double opacity;                 // Transparency
  final bool showMajorGrid;             // Major grid lines
  final bool showMinorGrid;             // Minor grid lines
  final Color? minorGridColor;          // Minor grid color
}

class AxisStyle {
  final Color lineColor;                // Axis line color
  final double lineWidth;               // Line thickness
  final List<double>? dashPattern;      // Dash pattern
  final TextStyle labelTextStyle;       // Label styling
  final AxisTitleStyle titleStyle;      // Title styling
  final TickStyle tickStyle;            // Tick mark styling
}

class AxisTitleStyle {
  final TextStyle textStyle;            // Text appearance
  final Color? backgroundColor;         // Background color
  final EdgeInsets? padding;            // Text padding
  final double? borderRadius;           // Background corners
  final double opacity;                 // Background opacity
  final Offset offset;                  // Position offset
  final Border? border;                 // Border styling
}
```

## 🌈 Seven Professional Themes

### 1. Default Light Theme
**Purpose**: Clean, professional appearance for business applications

```dart
static ChartTheme get defaultLight => ChartTheme(
  backgroundColor: Colors.white,
  canvasBorderColor: Colors.grey[300]!,
  canvasBorderWidth: 1.0,
  
  gridStyle: GridStyle(
    color: Colors.grey[200]!,
    width: 0.5,
    opacity: 1.0,
  ),
  
  seriesTheme: SeriesTheme(
    colors: [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green  
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFFF44336), // Red
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
    ],
  ),
  
  typography: TypographyTheme(
    axisLabelStyle: TextStyle(
      fontSize: 12,
      color: Colors.grey[700],
      fontWeight: FontWeight.w400,
    ),
    axisTitleStyle: TextStyle(
      fontSize: 14,
      color: Colors.grey[800],
      fontWeight: FontWeight.w500,
    ),
  ),
);
```

### 2. Default Dark Theme  
**Purpose**: Modern dark theme for low-light environments

```dart
static ChartTheme get defaultDark => ChartTheme(
  backgroundColor: Color(0xFF121212),
  canvasBorderColor: Color(0xFF333333),
  
  gridStyle: GridStyle(
    color: Color(0xFF333333),
    width: 0.5,
    opacity: 0.6,
  ),
  
  seriesTheme: SeriesTheme(
    colors: [
      Color(0xFF64B5F6), // Light Blue
      Color(0xFF81C784), // Light Green
      Color(0xFFFFB74D), // Light Orange
      Color(0xFFBA68C8), // Light Purple
      Color(0xFFE57373), // Light Red
      Color(0xFF4DD0E1), // Light Cyan
      Color(0xFFFFF176), // Light Yellow
    ],
  ),
  
  typography: TypographyTheme(
    axisLabelStyle: TextStyle(
      fontSize: 12,
      color: Colors.grey[300],
      fontWeight: FontWeight.w400,
    ),
  ),
);
```

### 3. Corporate Blue Theme
**Purpose**: Professional corporate styling

```dart
static ChartTheme get corporateBlue => ChartTheme(
  backgroundColor: Color(0xFFF8F9FA),
  canvasBorderColor: Color(0xFF1565C0),
  canvasBorderWidth: 2.0,
  
  seriesTheme: SeriesTheme(
    colors: [
      Color(0xFF1565C0), // Primary Blue
      Color(0xFF0D47A1), // Dark Blue
      Color(0xFF42A5F5), // Light Blue
      Color(0xFF1976D2), // Medium Blue
      Color(0xFF2196F3), // Material Blue
    ],
  ),
  
  interactionTheme: InteractionTheme(
    crosshairStyle: CrosshairStyle(
      lineColor: Color(0xFF1565C0),
      lineWidth: 1.5,
    ),
    tooltipStyle: TooltipStyle(
      backgroundColor: Color(0xFF1565C0),
      textColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
```

### 4. Vibrant Theme
**Purpose**: High-energy theme with bold colors

```dart
static ChartTheme get vibrant => ChartTheme(
  backgroundColor: Colors.white,
  canvasBorderColor: Color(0xFFE91E63),
  canvasBorderWidth: 2.0,
  canvasBorderRadius: 8.0,
  
  seriesTheme: SeriesTheme(
    colors: [
      Color(0xFFE91E63), // Pink
      Color(0xFF673AB7), // Deep Purple
      Color(0xFF3F51B5), // Indigo
      Color(0xFF009688), // Teal
      Color(0xFF8BC34A), // Light Green
      Color(0xFFFFEB3B), // Yellow
      Color(0xFFFF5722), // Deep Orange
    ],
  ),
  
  gridStyle: GridStyle(
    color: Color(0xFFE91E63),
    width: 0.8,
    opacity: 0.3,
  ),
);
```

### 5. Minimal Theme
**Purpose**: Clean, minimal design with maximum focus on data

```dart
static ChartTheme get minimal => ChartTheme(
  backgroundColor: Colors.white,
  canvasBorderColor: Colors.transparent,
  canvasBorderWidth: 0.0,
  
  gridStyle: GridStyle(
    color: Colors.grey[100]!,
    width: 0.5,
    opacity: 1.0,
    showMinorGrid: false,
  ),
  
  axisStyle: AxisStyle(
    lineColor: Colors.grey[400]!,
    lineWidth: 1.0,
    labelTextStyle: TextStyle(
      fontSize: 11,
      color: Colors.grey[600],
      fontWeight: FontWeight.w300,
    ),
  ),
  
  seriesTheme: SeriesTheme(
    colors: [
      Color(0xFF37474F), // Blue Grey
      Color(0xFF546E7A), // Blue Grey 600
      Color(0xFF78909C), // Blue Grey 400
      Color(0xFF90A4AE), // Blue Grey 300
    ],
  ),
);
```

### 6. High Contrast Theme
**Purpose**: Accessibility-focused theme for users with visual impairments

```dart
static ChartTheme get highContrast => ChartTheme(
  backgroundColor: Colors.white,
  canvasBorderColor: Colors.black,
  canvasBorderWidth: 3.0,
  
  gridStyle: GridStyle(
    color: Colors.black,
    width: 1.0,
    opacity: 0.8,
  ),
  
  axisStyle: AxisStyle(
    lineColor: Colors.black,
    lineWidth: 2.0,
    labelTextStyle: TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
  ),
  
  seriesTheme: SeriesTheme(
    colors: [
      Colors.black,
      Color(0xFF1976D2),     // High contrast blue
      Color(0xFFD32F2F),     // High contrast red
      Color(0xFF388E3C),     // High contrast green
      Color(0xFFF57C00),     // High contrast orange
    ],
  ),
  
  interactionTheme: InteractionTheme(
    crosshairStyle: CrosshairStyle(
      lineColor: Colors.black,
      lineWidth: 2.0,
    ),
    selectionStyle: SelectionStyle(
      highlightColor: Colors.yellow,
      highlightOpacity: 0.5,
    ),
  ),
);
```

### 7. Colorblind Friendly Theme
**Purpose**: Optimized for users with color vision deficiencies

```dart
static ChartTheme get colorblindFriendly => ChartTheme(
  backgroundColor: Colors.white,
  canvasBorderColor: Color(0xFF555555),
  
  seriesTheme: SeriesTheme(
    colors: [
      Color(0xFF0173B2), // Blue (safe for all types)
      Color(0xFFDE8F05), // Orange (deuteranopia safe)
      Color(0xFF029E73), // Green (protanopia safe)
      Color(0xFFCC78BC), // Pink (tritanopia safe)
      Color(0xFF949494), // Grey (neutral)
      Color(0xFF56B4E9), // Sky Blue
      Color(0xFFE69F00), // Amber
    ],
    linePatterns: [
      [], // Solid
      [4.0, 2.0], // Dashed
      [2.0, 2.0], // Dotted
      [8.0, 2.0, 2.0, 2.0], // Dash-dot
    ],
  ),
  
  // Use patterns in addition to colors
  accessibility: AccessibilityTheme(
    usePatterns: true,
    useShapes: true,
    highContrast: false,
  ),
);
```

## 🎨 Custom Theme Creation

### Theme Builder Pattern

```dart
class ChartThemeBuilder {
  ChartTheme _theme = ChartTheme.defaultLight;
  
  // Fluent API for theme building
  ChartThemeBuilder backgroundColor(Color color) {
    _theme = _theme.copyWith(backgroundColor: color);
    return this;
  }
  
  ChartThemeBuilder seriesColors(List<Color> colors) {
    _theme = _theme.copyWith(
      seriesTheme: _theme.seriesTheme.copyWith(colors: colors),
    );
    return this;
  }
  
  ChartThemeBuilder gridStyle(GridStyle style) {
    _theme = _theme.copyWith(gridStyle: style);
    return this;
  }
  
  ChartThemeBuilder typography(TypographyTheme typography) {
    _theme = _theme.copyWith(typography: typography);
    return this;
  }
  
  // Advanced customization
  ChartThemeBuilder customizeAxis(AxisCustomizer customizer) {
    _theme = _theme.copyWith(
      axisStyle: customizer(_theme.axisStyle),
    );
    return this;
  }
  
  ChartTheme build() => _theme;
}

// Usage example
final customTheme = ChartThemeBuilder()
  .backgroundColor(Color(0xFFF5F5F5))
  .seriesColors([Colors.purple, Colors.teal, Colors.amber])
  .gridStyle(GridStyle(
    color: Colors.grey[300]!,
    width: 0.5,
    dashPattern: [2.0, 2.0],
  ))
  .customizeAxis((axis) => axis.copyWith(
    titleStyle: axis.titleStyle.copyWith(
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      backgroundColor: Colors.purple.withOpacity(0.1),
      padding: EdgeInsets.all(8),
      borderRadius: 4.0,
    ),
  ))
  .build();
```

### Theme Inheritance System

```dart
class ThemeInheritance {
  // Merge themes with priority system
  static ChartTheme merge(ChartTheme base, ChartTheme override) {
    return ChartTheme(
      backgroundColor: override.backgroundColor ?? base.backgroundColor,
      gridStyle: GridStyle.merge(base.gridStyle, override.gridStyle),
      seriesTheme: SeriesTheme.merge(base.seriesTheme, override.seriesTheme),
      // ... other properties
    );
  }
  
  // Create theme variants
  static ChartTheme createVariant(
    ChartTheme base,
    ThemeVariantConfig config,
  ) {
    return base.copyWith(
      seriesTheme: base.seriesTheme.copyWith(
        colors: config.adjustColors(base.seriesTheme.colors),
      ),
      gridStyle: base.gridStyle.copyWith(
        opacity: base.gridStyle.opacity * config.opacityMultiplier,
      ),
    );
  }
}
```

## 🎯 Interactive Element Theming

### Comprehensive Interaction Styling

```dart
class InteractionTheme {
  // Crosshair System
  final CrosshairStyle crosshairStyle;
  
  // Tooltip System
  final TooltipStyle tooltipStyle;
  
  // Selection System
  final SelectionStyle selectionStyle;
  
  // Scrollbar System (Professional Desktop)
  final ScrollbarStyle scrollbarStyle;
  
  // Hover Effects
  final HoverStyle hoverStyle;
  
  // Animation System
  final InteractionAnimationStyle animationStyle;
}

class CrosshairStyle {
  final Color lineColor;                // Crosshair line color
  final double lineWidth;               // Line thickness
  final List<double>? dashPattern;      // Dash pattern
  final double opacity;                 // Line transparency
  final bool showHorizontal;            // Show horizontal line
  final bool showVertical;              // Show vertical line
  final CrosshairBehavior behavior;     // Interaction behavior
}

class TooltipStyle {
  final Color backgroundColor;          // Background color
  final Color borderColor;              // Border color
  final double borderWidth;             // Border thickness
  final BorderRadius borderRadius;      // Rounded corners
  final TextStyle textStyle;            // Text styling
  final EdgeInsets padding;             // Internal padding
  final List<BoxShadow>? shadows;       // Drop shadows
  final Duration showDelay;             // Hover delay
  final Duration hideDelay;             // Hide delay
  final TooltipAnimation animation;     // Show/hide animation
}

class ScrollbarStyle {
  final Color trackColor;               // Scrollbar track
  final Color thumbColor;               // Scrollbar thumb
  final Color hoverColor;               // Hover state color
  final double thickness;               // Scrollbar thickness
  final double borderRadius;            // Rounded corners
  final bool showAlways;                // Always visible vs on-demand
  final Duration fadeDelay;             // Auto-hide delay
  final ScrollbarPosition position;     // Placement on chart
}
```

### State-Based Styling

```dart
class StateAwareStyle<T> {
  final T normal;                       // Default state
  final T? hovered;                     // Mouse hover
  final T? pressed;                     // Mouse down
  final T? focused;                     // Keyboard focus
  final T? disabled;                    // Disabled state
  final T? selected;                    // Selected state
  
  T getStyleForState(ElementState state) {
    switch (state) {
      case ElementState.hovered:
        return hovered ?? normal;
      case ElementState.pressed:
        return pressed ?? hovered ?? normal;
      case ElementState.focused:
        return focused ?? normal;
      case ElementState.disabled:
        return disabled ?? normal;
      case ElementState.selected:
        return selected ?? normal;
      default:
        return normal;
    }
  }
}

// Usage in component styling
class MarkerStyle {
  final StateAwareStyle<Color> fillColor;
  final StateAwareStyle<double> size;
  final StateAwareStyle<double> borderWidth;
  
  Color getFillColor(ElementState state) => fillColor.getStyleForState(state);
  double getSize(ElementState state) => size.getStyleForState(state);
}
```

## 🌐 Responsive Theming

### Adaptive Theme System

```dart
class ResponsiveTheme {
  final ChartTheme mobile;              // Small screens (<600px)
  final ChartTheme tablet;              // Medium screens (600-1200px)
  final ChartTheme desktop;             // Large screens (>1200px)
  
  ChartTheme getThemeForSize(Size screenSize) {
    if (screenSize.width < 600) return mobile;
    if (screenSize.width < 1200) return tablet;
    return desktop;
  }
  
  // Interpolate between themes based on screen size
  ChartTheme getInterpolatedTheme(Size screenSize) {
    final factor = (screenSize.width - 600) / 600; // 0.0 to 1.0
    return ChartTheme.lerp(mobile, desktop, factor.clamp(0.0, 1.0));
  }
}

// Responsive adjustments
class ResponsiveAdjustments {
  static double getResponsiveFontSize(double baseFontSize, Size screenSize) {
    final scaleFactor = (screenSize.width / 400).clamp(0.8, 1.5);
    return baseFontSize * scaleFactor;
  }
  
  static double getResponsiveSpacing(double baseSpacing, Size screenSize) {
    final scaleFactor = (screenSize.width / 400).clamp(0.5, 2.0);
    return baseSpacing * scaleFactor;
  }
}
```

## 🎨 Theme Animation System

### Smooth Theme Transitions

```dart
class ThemeTransitionController {
  late final AnimationController _controller;
  late final Animation<ChartTheme> _themeAnimation;
  
  void transitionToTheme(
    ChartTheme newTheme,
    Duration duration,
  ) {
    _themeAnimation = ChartThemeTween(
      begin: currentTheme,
      end: newTheme,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.duration = duration;
    _controller.forward();
  }
}

class ChartThemeTween extends Tween<ChartTheme> {
  ChartThemeTween({required ChartTheme begin, required ChartTheme end})
      : super(begin: begin, end: end);
  
  @override
  ChartTheme lerp(double t) {
    return ChartTheme.lerp(begin!, end!, t);
  }
}

// Theme interpolation
class ChartTheme {
  static ChartTheme lerp(ChartTheme a, ChartTheme b, double t) {
    return ChartTheme(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      gridStyle: GridStyle.lerp(a.gridStyle, b.gridStyle, t),
      seriesTheme: SeriesTheme.lerp(a.seriesTheme, b.seriesTheme, t),
      // ... other interpolated properties
    );
  }
}
```

## 🧪 Theme Validation & Testing

### Theme Validation System

```dart
class ThemeValidator {
  static List<ThemeValidationIssue> validate(ChartTheme theme) {
    final issues = <ThemeValidationIssue>[];
    
    // Color contrast validation
    final contrastRatio = _calculateContrastRatio(
      theme.backgroundColor,
      theme.typography.axisLabelStyle.color!,
    );
    
    if (contrastRatio < 4.5) {
      issues.add(ThemeValidationIssue.warning(
        'Low contrast ratio between background and text',
        suggestion: 'Increase contrast for better accessibility',
      ));
    }
    
    // Color blindness validation
    if (!_isColorblindFriendly(theme.seriesTheme.colors)) {
      issues.add(ThemeValidationIssue.info(
        'Color palette may not be colorblind friendly',
        suggestion: 'Consider using patterns or high contrast colors',
      ));
    }
    
    return issues;
  }
}

class ThemeValidationIssue {
  final String message;
  final String suggestion;
  final IssueSeverity severity;
  
  ThemeValidationIssue.warning(this.message, {required this.suggestion})
      : severity = IssueSeverity.warning;
}
```

---

**Feature Status**: ✅ Comprehensive and User-Validated  
**Implementation Priority**: High - Core Visual Foundation  
**User Feedback**: Excellent - Professional appearance highly valued  
**Accessibility**: ✅ WCAG 2.1 AA Compliant themes included  
**Last Updated**: October 2025