# Theming System Usage Guide

**Version:** 1.0  
**Last Updated:** October 6, 2025  
**Status:** Complete

This guide covers the complete usage of the Braven Charts theming system, from quick start to advanced customization.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Predefined Themes](#predefined-themes)
3. [Custom Theme Creation](#custom-theme-creation)
4. [Theme Switching](#theme-switching)
5. [Responsive Typography](#responsive-typography)
6. [Accessibility Guidelines](#accessibility-guidelines)
7. [Performance Tips](#performance-tips)
8. [JSON Serialization](#json-serialization)
9. [Advanced Patterns](#advanced-patterns)

---

## Quick Start

### Using a Predefined Theme

The fastest way to start is using one of the 7 built-in themes:

```dart
import 'package:braven_charts/theming.dart';

// Apply a predefined theme
final theme = ChartTheme.defaultLight;

// Use in a chart (when chart widgets are implemented)
// final chart = LineChart(
//   data: myData,
//   theme: theme,
// );
```

### Available Predefined Themes

| Theme | Best For | Key Features |
|-------|----------|--------------|
| `defaultLight` | General purpose, light mode | Clean, professional, 5-color palette |
| `defaultDark` | General purpose, dark mode | Material Design inspired, high contrast |
| `corporateBlue` | Business presentations | Professional blue scheme, subtle |
| `vibrant` | Dashboards, marketing | Bold colors, eye-catching |
| `minimal` | Minimalist designs | Grayscale, understated |
| `highContrast` | Accessibility-first | WCAG AAA compliant, 21:1 contrast |
| `colorblindFriendly` | Universal accessibility | Okabe-Ito palette, safe for all |

---

## Predefined Themes

### Default Light Theme

Perfect for most use cases in light-mode applications.

```dart
final theme = ChartTheme.defaultLight;

// Key properties:
// - Background: White (#FFFFFF)
// - Border: Light Gray (#E0E0E0, 1px)
// - Series: Blue, Red, Green, Orange, Purple
// - Grid: Light gray with subtle minor grid
// - Font: Roboto, 12px base
// - Animation: 400ms smooth transitions
```

**When to use:**
- Standard light-mode applications
- Print-friendly charts
- Clean, professional presentations

### Default Dark Theme

Modern dark theme following Material Design principles.

```dart
final theme = ChartTheme.defaultDark;

// Key properties:
// - Background: Dark Gray (#121212)
// - Border: Medium Gray (#424242, 1px)
// - Series: Light Blue, Light Red, Light Green, Light Orange, Light Purple
// - Grid: Medium gray, visible on dark background
// - Font: Roboto, 12px base
// - Animation: 350ms (slightly faster for perceived responsiveness)
```

**When to use:**
- Dark-mode applications
- Dashboards viewed in low-light environments
// OLED-friendly displays

### Corporate Blue Theme

Professional theme for business environments.

```dart
final theme = ChartTheme.corporateBlue;

// Key properties:
// - Background: Very Light Gray (#FAFAFA)
// - Border: Blue (#1976D2, 2px)
// - Series: Professional blues and teals
// - Grid: Subtle, non-distracting
// - Font: Roboto, 13px base (slightly larger for readability)
// - Animation: 500ms (deliberate, professional feel)
```

**When to use:**
- Corporate presentations
- Financial reports
- Executive dashboards

### Vibrant Theme

Bold and colorful for engaging visualizations.

```dart
final theme = ChartTheme.vibrant;

// Key properties:
// - Background: White (#FFFFFF)
// - Border: Bright Blue (#2196F3, 2px)
// - Series: Bright Blue, Pink, Amber, Teal, Deep Orange
// - Grid: Light, doesn't compete with data
// - Font: Roboto, 12px base
// - Animation: 600ms (attention-grabbing transitions)
```

**When to use:**
- Marketing dashboards
- Public-facing analytics
- Colorful data stories

### Minimal Theme

Clean, understated design for focus on data.

```dart
final theme = ChartTheme.minimal;

// Key properties:
// - Background: Off-White (#F5F5F5)
// - Border: None (0px)
// - Series: Grayscale palette (Dark, Medium, Light grays)
// - Grid: Minimal, subtle
// - Font: Roboto, 11px base (compact)
// - Animation: 250ms (fast, unobtrusive)
```

**When to use:**
- Minimalist designs
- Print publications
- When data should speak for itself

### High Contrast Theme

Maximum accessibility with WCAG AAA compliance.

```dart
final theme = ChartTheme.highContrast;

// Key properties:
// - Background: Black (#000000)
// - Border: White (#FFFFFF, 2px)
// - Series: Bright Yellow, Cyan, Magenta, Lime, Orange
// - Grid: High contrast white lines
// - Font: Roboto, 14px base (larger for accessibility)
// - Animation: 300ms
// - Contrast ratios: All 21:1 (WCAG AAA)
```

**When to use:**
- Accessibility requirements
- Low-vision users
- High ambient light environments
- Legal compliance needs

### Colorblind-Friendly Theme

Uses the Okabe-Ito palette, safe for all types of colorblindness.

```dart
final theme = ChartTheme.colorblindFriendly;

// Key properties:
// - Background: White (#FFFFFF)
// - Border: Dark Gray (#424242, 1px)
// - Series: Okabe-Ito palette
//   * Orange (#E69F00)
//   * Sky Blue (#56B4E9)
//   * Bluish Green (#009E73)
//   * Yellow (#F0E442)
//   * Blue (#0072B2)
//   * Vermillion (#D55E00)
//   * Reddish Purple (#CC79A7)
// - Animation: 400ms
```

**When to use:**
- Universal accessibility
- Public dashboards
- International audiences
- When colorblind users are expected

---

## Custom Theme Creation

### Method 1: Modify Existing Theme

Use `copyWith()` to customize a predefined theme:

```dart
final customTheme = ChartTheme.defaultLight.copyWith(
  backgroundColor: const Color(0xFFF8F9FA), // Light blue-gray
  borderWidth: 2.0,
  padding: const EdgeInsets.all(24.0),
  seriesTheme: SeriesTheme.vibrant, // Mix components from different themes
);
```

**Advantages:**
- Quick and simple
- Maintains theme consistency
- Type-safe

**When to use:**
- Small customizations
- Brand color adjustments
- Tweaking existing themes

### Method 2: ChartThemeBuilder

For complex customizations, use the fluent builder:

```dart
import 'package:braven_charts/theming.dart';

final brandTheme = ChartThemeBuilder()
  // Chart-level properties
  .backgroundColor(const Color(0xFFFAFAFA))
  .borderColor(const Color(0xFF1976D2))
  .borderWidth(3.0)
  .padding(const EdgeInsets.all(24.0))
  
  // Component themes
  .gridStyle(GridStyle(
    majorColor: const Color(0xFFE0E0E0),
    majorWidth: 1.0,
    majorDashPattern: const [],
    showMinor: true,
    minorColor: const Color(0xFFF5F5F5),
    minorWidth: 0.5,
    minorDashPattern: const [2, 2],
  ))
  
  .axisStyle(AxisStyle(
    lineColor: const Color(0xFF424242),
    lineWidth: 2.0,
    tickLength: 6.0,
    tickWidth: 1.5,
    labelStyle: const TextStyle(
      fontSize: 11.0,
      color: Color(0xFF666666),
      fontFamily: 'Roboto',
    ),
    titleStyle: const TextStyle(
      fontSize: 14.0,
      color: Color(0xFF333333),
      fontWeight: FontWeight.bold,
      fontFamily: 'Roboto',
    ),
  ))
  
  .seriesTheme(SeriesTheme(
    colors: const [
      Color(0xFF0066CC), // Brand blue
      Color(0xFFFF6B35), // Brand orange
      Color(0xFF004E89), // Dark blue
      Color(0xFFF77F00), // Bright orange
      Color(0xFF1A759F), // Teal
    ],
    lineWidths: const [2.5],
    markerSizes: const [6.0],
    markerShapes: const [MarkerShape.circle],
  ))
  
  .interactionTheme(InteractionTheme(
    hoverColor: const Color(0x330066CC), // 20% blue
    selectionColor: const Color(0x660066CC), // 40% blue
    tooltipBackgroundColor: const Color(0xFF0066CC),
    tooltipTextColor: const Color(0xFFFFFFFF),
    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    tooltipBorderRadius: 4.0,
  ))
  
  .typographyTheme(TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 13.0,
    scaleFactorMobile: 0.9,
    scaleFactorTablet: 1.0,
    scaleFactorDesktop: 1.1,
    titleMultiplier: 1.4,
    labelMultiplier: 1.0,
  ))
  
  .animationTheme(AnimationTheme(
    dataUpdateDuration: const Duration(milliseconds: 450),
    hoverDuration: const Duration(milliseconds: 150),
    selectionDuration: const Duration(milliseconds: 200),
    enterDuration: const Duration(milliseconds: 600),
    exitDuration: const Duration(milliseconds: 300),
  ))
  
  .build();
```

**Advantages:**
- Complete control over every property
- Fluent, readable API
- Easy to version control
- Self-documenting code

**When to use:**
- Brand-specific themes
- Complete custom designs
- Corporate style guides
- Unique requirements

### Method 3: Start from Existing with Builder

Combine both approaches:

```dart
final customVibrant = ChartThemeBuilder.from(ChartTheme.vibrant)
  .backgroundColor(const Color(0xFFF0F4F8)) // Customize just a few properties
  .padding(const EdgeInsets.all(32.0))
  .build();
```

---

## Theme Switching

### Static Theme Switching

Simply replace the theme:

```dart
ChartTheme currentTheme = ChartTheme.defaultLight;

// Later, switch to dark mode
currentTheme = ChartTheme.defaultDark;
```

### With RenderContext (Advanced)

When using the rendering system, use the extension methods:

```dart
import 'package:braven_charts/rendering.dart';
import 'package:braven_charts/theming.dart';

final context = RenderContext(/* ... */);

// Apply initial theme
context.applyTheme(ChartTheme.defaultLight);

// Get current theme
final current = context.currentTheme;

// Update theme with automatic diffing and cache invalidation
context.updateTheme(ChartTheme.defaultDark);
```

**Performance benefits:**
- Automatic change detection
- Selective cache invalidation
- Partial re-rendering (only changed components)
- Preserves chart state (zoom, pan, selection)

### Theme Switching Performance

The theming system is optimized for fast switching:

```dart
// Benchmark results from test/benchmarks/theming/theme_switching_benchmark.dart
// - Initial theme application: <100ms
// - Identical theme switch: <10ms (no-op optimization)
// - Light-to-dark switch: <100ms (full diff)
// - Rapid switching (5000 iterations): <50ms average
```

**Best practices:**
1. Use `context.updateTheme()` instead of `context.applyTheme()` when switching
2. Avoid rapid theme changes (< 100ms apart)
3. Batch theme updates if modifying multiple properties

---

## Responsive Typography

The theming system includes built-in responsive typography that scales based on viewport size.

### Viewport Breakpoints

```dart
// Defined in TypographyTheme
Mobile:  width < 600px   → scaleFactorMobile (default: 0.9)
Tablet:  600px ≤ width < 1200px → scaleFactorTablet (default: 1.0)
Desktop: width ≥ 1200px  → scaleFactorDesktop (default: 1.1)
```

### Customizing Responsive Scaling

```dart
final responsiveTheme = ChartThemeBuilder()
  .typographyTheme(TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12.0,
    
    // Customize scale factors for different viewports
    scaleFactorMobile: 0.85,   // 15% smaller on mobile
    scaleFactorTablet: 1.0,    // Baseline
    scaleFactorDesktop: 1.15,  // 15% larger on desktop
    
    // Text type multipliers
    titleMultiplier: 1.5,      // Titles are 1.5x base size
    labelMultiplier: 0.95,     // Labels slightly smaller than base
  ))
  .build();
```

### Calculating Effective Font Sizes

```dart
// Mobile (viewport width = 400px)
// Title: 12.0 × 0.85 × 1.5 = 15.3px
// Label: 12.0 × 0.85 × 0.95 = 9.69px

// Tablet (viewport width = 800px)
// Title: 12.0 × 1.0 × 1.5 = 18.0px
// Label: 12.0 × 1.0 × 0.95 = 11.4px

// Desktop (viewport width = 1600px)
// Title: 12.0 × 1.15 × 1.5 = 20.7px
// Label: 12.0 × 1.15 × 0.95 = 13.11px
```

### Best Practices

1. **Keep scale factors subtle**: 0.8-1.2 range works well
2. **Test on real devices**: Emulators may not reflect actual readability
3. **Consider accessibility**: Minimum 11px for body text (WCAG)
4. **Progressive scaling**: mobile < tablet < desktop

---

## Accessibility Guidelines

### WCAG Contrast Requirements

```dart
import 'package:braven_charts/theming.dart';

// Check contrast ratios
final foreground = Color(0xFF333333);
final background = Color(0xFFFFFFFF);

final ratio = ColorUtils.calculateContrastRatio(foreground, background);
// ratio ≈ 12.63:1

// WCAG AA: 4.5:1 for normal text, 3:1 for large text
final meetsAA = ColorUtils.meetsWCAG_AA(foreground, background, isLargeText: false);
// true (12.63 > 4.5)

// WCAG AAA: 7:1 for normal text, 4.5:1 for large text
final meetsAAA = ColorUtils.meetsWCAG_AAA(foreground, background, isLargeText: false);
// true (12.63 > 7.0)
```

### Contrast Ratio Guidelines

| Level | Normal Text | Large Text | When to Use |
|-------|-------------|------------|-------------|
| **AA** | 4.5:1 | 3:1 | Minimum standard, most websites |
| **AAA** | 7:1 | 4.5:1 | Enhanced accessibility, government sites |

**Large text** is defined as:
- 18pt (24px) regular weight
- 14pt (18.66px) bold weight

### Colorblind Considerations

```dart
// Simulate how colors appear to colorblind users
final originalColor = Color(0xFFE74C3C); // Red

// Protanopia (red-blind)
final protanopia = ColorUtils.simulateProtanopia(originalColor);

// Deuteranopia (green-blind)
final deuteranopia = ColorUtils.simulateDeuteranopia(originalColor);

// Tritanopia (blue-blind)
final tritanopia = ColorUtils.simulateTritanopia(originalColor);
```

### Creating Accessible Themes

**1. Use the High Contrast theme for WCAG AAA:**

```dart
final accessible = ChartTheme.highContrast;
// All colors meet 21:1 contrast (maximum possible)
```

**2. Use the Colorblind-Friendly theme:**

```dart
final colorblindSafe = ChartTheme.colorblindFriendly;
// Uses Okabe-Ito palette (scientifically validated)
```

**3. Verify custom themes:**

```dart
void verifyThemeAccessibility(ChartTheme theme) {
  // Check background/text contrast
  final bgTextRatio = ColorUtils.calculateContrastRatio(
    theme.backgroundColor,
    theme.axisStyle.labelStyle.color!,
  );
  
  assert(bgTextRatio >= 4.5, 'Text contrast must meet WCAG AA (4.5:1)');
  
  // Check tooltip contrast
  final tooltipRatio = ColorUtils.calculateContrastRatio(
    theme.interactionTheme.tooltipBackgroundColor,
    theme.interactionTheme.tooltipTextColor,
  );
  
  assert(tooltipRatio >= 4.5, 'Tooltip contrast must meet WCAG AA (4.5:1)');
  
  print('✅ Theme passes accessibility checks');
  print('   - Background/Text: ${bgTextRatio.toStringAsFixed(2)}:1');
  print('   - Tooltip: ${tooltipRatio.toStringAsFixed(2)}:1');
}
```

---

## Performance Tips

### 1. Use Predefined Themes When Possible

Predefined themes are pre-validated and cached:

```dart
// GOOD: Fast, cached
final theme = ChartTheme.defaultLight;

// SLOWER: Creates new instance every time
final theme = ChartThemeBuilder().build();
```

### 2. Cache Custom Themes

If you create custom themes, cache them:

```dart
// BAD: Recreates theme on every build
Widget build(BuildContext context) {
  final theme = ChartThemeBuilder()
    .backgroundColor(Colors.white)
    .build();
  
  return MyChart(theme: theme);
}

// GOOD: Cache in state or constant
class MyChartWidget extends StatelessWidget {
  static final _customTheme = ChartThemeBuilder()
    .backgroundColor(Colors.white)
    .build();
  
  @override
  Widget build(BuildContext context) {
    return MyChart(theme: _customTheme);
  }
}
```

### 3. Use Theme Switching Efficiently

```dart
// GOOD: Automatic diffing, selective invalidation
context.updateTheme(newTheme);

// LESS EFFICIENT: Clears entire cache
context.applyTheme(newTheme);
```

### 4. Avoid Frequent Theme Changes

```dart
// BAD: 60 FPS = 60 theme changes/second
animationController.addListener(() {
  context.updateTheme(/* interpolated theme */);
});

// GOOD: Change theme only when animation completes
animationController.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    context.updateTheme(targetTheme);
  }
});
```

### 5. StyleCache Performance

The theming system includes an LRU cache for resolved styles:

```dart
// Benchmark results from test/benchmarks/theming/style_cache_benchmark.dart
// - Cache hit: <0.1ms lookup time
// - Cache miss: <1ms (includes style resolution)
// - Hit rate: >95% in typical usage
// - Capacity: 1000 entries (LRU eviction)
```

**The cache is automatic** - no manual management needed.

---

## JSON Serialization

### Serialize to JSON

```dart
final theme = ChartTheme.defaultLight;

// Convert to JSON map
final json = theme.toJson();

// Convert to JSON string
import 'dart:convert';
final jsonString = jsonEncode(json);

// Example output:
// {
//   "backgroundColor": "#ffffffff",
//   "borderColor": "#ffe0e0e0",
//   "borderWidth": 1.0,
//   ...
// }
```

### Deserialize from JSON

```dart
import 'dart:convert';

// From JSON string
final jsonString = '{"backgroundColor":"#ffffffff", ...}';
final json = jsonDecode(jsonString);

// From JSON map
final theme = ChartTheme.fromJson(json);
```

### Save/Load Themes

```dart
// Save theme to file
Future<void> saveTheme(ChartTheme theme, String path) async {
  final json = theme.toJson();
  final jsonString = jsonEncode(json);
  await File(path).writeAsString(jsonString);
}

// Load theme from file
Future<ChartTheme> loadTheme(String path) async {
  final jsonString = await File(path).readAsString();
  final json = jsonDecode(jsonString);
  return ChartTheme.fromJson(json);
}
```

### Theme Versioning

```dart
import 'package:braven_charts/theming.dart';

// Current version
const version = currentVersion; // ThemeVersion(1, 0, 0)

// Check compatibility
final savedVersion = ThemeVersion.parse('1.2.0');
final compatible = currentVersion.isCompatible(savedVersion);
// true (same major version)

// Version from JSON
final version = ThemeVersion.parse(json['version']);
```

---

## Advanced Patterns

### 1. Theme Inheritance

Create a base theme and derive variants:

```dart
// Base corporate theme
final baseCorporate = ChartThemeBuilder()
  .backgroundColor(const Color(0xFFFAFAFA))
  .borderColor(const Color(0xFF1976D2))
  .borderWidth(2.0)
  .padding(const EdgeInsets.all(20.0))
  .build();

// Light variant
final corporateLight = baseCorporate.copyWith(
  backgroundColor: const Color(0xFFFFFFFF),
);

// Dark variant
final corporateDark = baseCorporate.copyWith(
  backgroundColor: const Color(0xFF121212),
  borderColor: const Color(0xFF64B5F6),
);

// Compact variant (for dashboards)
final corporateCompact = baseCorporate.copyWith(
  padding: const EdgeInsets.all(12.0),
  typographyTheme: baseCorporate.typographyTheme.copyWith(
    baseFontSize: 10.0,
  ),
);
```

### 2. Conditional Theming

Apply themes based on conditions:

```dart
ChartTheme getTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isAccessible = MediaQuery.of(context).accessibleNavigation;
  
  if (isAccessible) {
    return ChartTheme.highContrast;
  } else if (isDark) {
    return ChartTheme.defaultDark;
  } else {
    return ChartTheme.defaultLight;
  }
}
```

### 3. Dynamic Theme Generation

Generate themes programmatically:

```dart
ChartTheme generateBrandTheme(Color primaryColor) {
  // Generate complementary colors
  final secondaryColor = _shiftHue(primaryColor, 180);
  final tertiaryColor = _shiftHue(primaryColor, 120);
  
  return ChartThemeBuilder()
    .backgroundColor(Colors.white)
    .borderColor(primaryColor)
    .borderWidth(2.0)
    .seriesTheme(SeriesTheme(
      colors: [
        primaryColor,
        secondaryColor,
        tertiaryColor,
        _lighten(primaryColor, 0.3),
        _darken(primaryColor, 0.3),
      ],
      lineWidths: const [2.0],
      markerSizes: const [6.0],
      markerShapes: const [MarkerShape.circle],
    ))
    .build();
}

Color _shiftHue(Color color, double degrees) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}

Color _lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color color, double amount) {
  return _lighten(color, -amount);
}
```

### 4. Theme Interpolation (for animations)

Smoothly transition between themes:

```dart
ChartTheme lerpTheme(ChartTheme a, ChartTheme b, double t) {
  return ChartTheme(
    backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
    borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
    borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t)!,
    padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
    gridStyle: _lerpGridStyle(a.gridStyle, b.gridStyle, t),
    axisStyle: _lerpAxisStyle(a.axisStyle, b.axisStyle, t),
    seriesTheme: _lerpSeriesTheme(a.seriesTheme, b.seriesTheme, t),
    interactionTheme: _lerpInteractionTheme(a.interactionTheme, b.interactionTheme, t),
    typographyTheme: _lerpTypographyTheme(a.typographyTheme, b.typographyTheme, t),
    animationTheme: _lerpAnimationTheme(a.animationTheme, b.animationTheme, t),
  );
}

// Use with AnimationController
final animation = AnimationController(
  vsync: this,
  duration: Duration(milliseconds: 500),
);

final themeAnimation = animation.drive(
  Tween<ChartTheme>(
    begin: ChartTheme.defaultLight,
    end: ChartTheme.defaultDark,
  ).chain(CurveTween(curve: Curves.easeInOut)),
);
```

---

## Summary

This guide covered:

✅ **Quick Start**: Using predefined themes  
✅ **Predefined Themes**: All 7 built-in themes in detail  
✅ **Custom Creation**: copyWith(), ChartThemeBuilder, hybrid approaches  
✅ **Theme Switching**: Static and RenderContext-based switching  
✅ **Responsive Typography**: Viewport-based scaling  
✅ **Accessibility**: WCAG compliance, colorblind support  
✅ **Performance**: Caching, optimization tips  
✅ **JSON Serialization**: Save/load themes  
✅ **Advanced Patterns**: Inheritance, conditional themes, interpolation  

For more information:
- **API Reference**: See Dartdoc in `lib/src/theming/`
- **Accessibility Guide**: `docs/guides/theming-accessibility.md`
- **Examples**: `test/integration/theming/quickstart_examples_test.dart`
- **Benchmarks**: `test/benchmarks/theming/`

---

**Questions or Issues?**  
File an issue on GitHub: https://github.com/forcegage-pvm/braven_charts/issues
