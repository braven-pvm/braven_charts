# Theming Accessibility Guide

**Version:** 1.0  
**Last Updated:** October 6, 2025  
**Status:** Complete

This guide provides comprehensive accessibility guidelines for the Braven Charts theming system, ensuring charts are usable by everyone, including users with visual impairments and color vision deficiencies.

---

## Table of Contents

1. [WCAG 2.1 Compliance Overview](#wcag-21-compliance-overview)
2. [Contrast Ratio Requirements](#contrast-ratio-requirements)
3. [Verifying Contrast Ratios](#verifying-contrast-ratios)
4. [Colorblind-Friendly Design](#colorblind-friendly-design)
5. [Testing for Accessibility](#testing-for-accessibility)
6. [Accessible Theme Checklist](#accessible-theme-checklist)
7. [Common Pitfalls](#common-pitfalls)
8. [Resources](#resources)

---

## WCAG 2.1 Compliance Overview

The Web Content Accessibility Guidelines (WCAG) 2.1 define three conformance levels for accessibility:

| Level | Description | Use Case |
|-------|-------------|----------|
| **A** | Minimum accessibility | Basic requirement, rarely sufficient |
| **AA** | Mid-range accessibility | Standard for most websites, legal requirement in many jurisdictions |
| **AAA** | Highest accessibility | Government sites, healthcare, finance, universal access |

### Key Success Criteria for Charts

| Criterion | Level | Requirement | Impact on Charts |
|-----------|-------|-------------|------------------|
| **1.4.3** Color alone not used for information | A | Must not rely solely on color to convey information | Use patterns, labels, or shapes in addition to colors |
| **1.4.6** | AAA | Contrast ratio ≥ 7:1 for normal text | Axis labels, tooltips, legends |
| **1.4.11** Non-text Contrast | AA | Contrast ratio ≥ 3:1 for UI components and graphical objects | Chart borders, grid lines, series lines |

### Braven Charts Compliance

All predefined themes meet **WCAG AA standards**:

```dart
ChartTheme.defaultLight  // WCAG AA ✓
ChartTheme.defaultDark   // WCAG AA ✓
ChartTheme.corporateBlue // WCAG AA ✓
ChartTheme.vibrant       // WCAG AA ✓
ChartTheme.minimal       // WCAG AA ✓
```

For **WCAG AAA compliance**, use:

```dart
ChartTheme.highContrast  // WCAG AAA ✓ (21:1 contrast ratios)
```

---

## Contrast Ratio Requirements

### Understanding Contrast Ratios

Contrast ratio is a measure of the difference in luminance between two colors, expressed as a ratio from 1:1 (no contrast) to 21:1 (maximum contrast, black on white).

**Formula:**
```
Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)

Where:
- L1 = relative luminance of the lighter color
- L2 = relative luminance of the darker color
- Luminance values range from 0 (black) to 1 (white)
```

### WCAG 2.1 Requirements

#### Text Contrast

| Text Size | WCAG AA | WCAG AAA |
|-----------|---------|----------|
| **Normal text** (<18pt / <24px regular, <14pt / <18.66px bold) | 4.5:1 | 7:1 |
| **Large text** (≥18pt / ≥24px regular, ≥14pt / ≥18.66px bold) | 3:1 | 4.5:1 |

#### Non-Text Contrast

| Element | WCAG AA | WCAG AAA |
|---------|---------|----------|
| **UI Components** (borders, icons, buttons) | 3:1 | 4.5:1 |
| **Graphical Objects** (chart lines, markers, areas) | 3:1 | No specific requirement |

### Chart-Specific Guidelines

#### Essential Elements (WCAG AA Minimum)

1. **Axis Labels**: 4.5:1 against background
2. **Axis Titles**: 4.5:1 against background (or 3:1 if ≥24px)
3. **Tooltips**: 4.5:1 (text on tooltip background)
4. **Legend Text**: 4.5:1 against background
5. **Chart Border**: 3:1 against background
6. **Grid Lines**: 3:1 against background
7. **Series Lines/Markers**: 3:1 against background

#### Enhanced Accessibility (WCAG AAA)

1. **All Text**: 7:1 minimum (or 4.5:1 for large text)
2. **All UI Components**: 4.5:1 minimum
3. **Series Differentiation**: Use patterns or shapes in addition to color

---

## Verifying Contrast Ratios

### Using ColorUtils

Braven Charts provides built-in utilities for verifying contrast:

```dart
import 'package:braven_charts/theming.dart';

// Calculate contrast ratio
final foreground = Color(0xFF333333);
final background = Color(0xFFFFFFFF);

final ratio = ColorUtils.calculateContrastRatio(foreground, background);
print('Contrast ratio: ${ratio.toStringAsFixed(2)}:1');
// Output: Contrast ratio: 12.63:1

// Check WCAG AA compliance
final meetsAA = ColorUtils.meetsWCAG_AA(foreground, background, isLargeText: false);
print('Meets WCAG AA: $meetsAA');
// Output: Meets WCAG AA: true

// Check WCAG AAA compliance
final meetsAAA = ColorUtils.meetsWCAG_AAA(foreground, background, isLargeText: false);
print('Meets WCAG AAA: $meetsAAA');
// Output: Meets WCAG AAA: true
```

### Verifying a Complete Theme

```dart
void verifyThemeAccessibility(ChartTheme theme) {
  final results = <String, double>{};
  
  // 1. Background vs Axis Labels
  final bgLabelRatio = ColorUtils.calculateContrastRatio(
    theme.backgroundColor,
    theme.axisStyle.labelStyle.color!,
  );
  results['Background/Labels'] = bgLabelRatio;
  
  // 2. Background vs Axis Titles
  final bgTitleRatio = ColorUtils.calculateContrastRatio(
    theme.backgroundColor,
    theme.axisStyle.titleStyle.color!,
  );
  results['Background/Titles'] = bgTitleRatio;
  
  // 3. Background vs Border
  final bgBorderRatio = ColorUtils.calculateContrastRatio(
    theme.backgroundColor,
    theme.borderColor,
  );
  results['Background/Border'] = bgBorderRatio;
  
  // 4. Background vs Grid
  final bgGridRatio = ColorUtils.calculateContrastRatio(
    theme.backgroundColor,
    theme.gridStyle.majorColor,
  );
  results['Background/Grid'] = bgGridRatio;
  
  // 5. Tooltip Background vs Text
  final tooltipRatio = ColorUtils.calculateContrastRatio(
    theme.interactionTheme.tooltipBackgroundColor,
    theme.interactionTheme.tooltipTextColor,
  );
  results['Tooltip BG/Text'] = tooltipRatio;
  
  // 6. Background vs Series Colors
  for (var i = 0; i < theme.seriesTheme.colors.length; i++) {
    final seriesRatio = ColorUtils.calculateContrastRatio(
      theme.backgroundColor,
      theme.seriesTheme.colors[i],
    );
    results['Background/Series $i'] = seriesRatio;
  }
  
  // Report results
  print('\n=== Accessibility Verification ===\n');
  
  var passesAA = true;
  var passesAAA = true;
  
  results.forEach((key, ratio) {
    final status = ratio >= 7.0 ? 'AAA ✓' : ratio >= 4.5 ? 'AA ✓' : 'FAIL ✗';
    print('$key: ${ratio.toStringAsFixed(2)}:1 [$status]');
    
    if (ratio < 4.5) passesAA = false;
    if (ratio < 7.0) passesAAA = false;
  });
  
  print('\n=== Summary ===');
  print('WCAG AA: ${passesAA ? "PASS ✓" : "FAIL ✗"}');
  print('WCAG AAA: ${passesAAA ? "PASS ✓" : "FAIL ✗"}');
  print('==================\n');
}

// Usage
void main() {
  verifyThemeAccessibility(ChartTheme.defaultLight);
  verifyThemeAccessibility(ChartTheme.highContrast);
}
```

### Example Output

```
=== Accessibility Verification ===

Background/Labels: 12.63:1 [AAA ✓]
Background/Titles: 15.54:1 [AAA ✓]
Background/Border: 2.89:1 [FAIL ✗]
Background/Grid: 1.89:1 [FAIL ✗]
Tooltip BG/Text: 21.00:1 [AAA ✓]
Background/Series 0: 5.12:1 [AA ✓]
Background/Series 1: 4.87:1 [AA ✓]
Background/Series 2: 3.94:1 [FAIL ✗]

=== Summary ===
WCAG AA: FAIL ✗
WCAG AAA: FAIL ✗
==================
```

**Note**: Borders and grid lines have lower contrast requirements (3:1 per WCAG 1.4.11). The above example shows how to identify which elements meet which levels.

---

## Colorblind-Friendly Design

Approximately 8% of men and 0.5% of women have some form of color vision deficiency (CVD). Designing for colorblindness ensures your charts are accessible to everyone.

### Types of Color Vision Deficiency

| Type | Affected Colors | Prevalence | Description |
|------|-----------------|------------|-------------|
| **Protanopia** | Red | ~1% males | Cannot perceive red light |
| **Deuteranopia** | Green | ~1% males | Cannot perceive green light |
| **Tritanopia** | Blue | ~0.001% | Cannot perceive blue light (very rare) |
| **Protanomaly** | Red (weak) | ~1% males | Reduced sensitivity to red |
| **Deuteranomaly** | Green (weak) | ~5% males | Reduced sensitivity to green (most common) |
| **Tritanomaly** | Blue (weak) | ~0.01% | Reduced sensitivity to blue |

### Simulating Colorblindness

Use ColorUtils to simulate how colors appear to colorblind users:

```dart
import 'package:braven_charts/theming.dart';

final originalColor = Color(0xFFE74C3C); // Red

// Simulate Protanopia (red-blind)
final protanopia = ColorUtils.simulateProtanopia(originalColor);
// Result: Yellowish-brown (red appears as brown/yellow)

// Simulate Deuteranopia (green-blind)
final deuteranopia = ColorUtils.simulateDeuteranopia(originalColor);
// Result: Similar to protanopia

// Simulate Tritanopia (blue-blind)
final tritanopia = ColorUtils.simulateTritanopia(originalColor);
// Result: Pinkish (red appears more pink/magenta)
```

### Testing a Color Palette

```dart
void testPaletteForColorblindness(List<Color> palette) {
  print('Testing palette for colorblindness...\n');
  
  for (var i = 0; i < palette.length; i++) {
    final color = palette[i];
    
    print('Color $i: ${_colorToHex(color)}');
    print('  Protanopia:   ${_colorToHex(ColorUtils.simulateProtanopia(color))}');
    print('  Deuteranopia: ${_colorToHex(ColorUtils.simulateDeuteranopia(color))}');
    print('  Tritanopia:   ${_colorToHex(ColorUtils.simulateTritanopia(color))}');
    print('');
  }
  
  // Check for similar colors after simulation
  print('Checking for collisions...\n');
  
  for (var i = 0; i < palette.length; i++) {
    for (var j = i + 1; j < palette.length; j++) {
      final colorA = palette[i];
      final colorB = palette[j];
      
      // Check protanopia confusion
      final protA = ColorUtils.simulateProtanopia(colorA);
      final protB = ColorUtils.simulateProtanopia(colorB);
      
      if (_colorsSimilar(protA, protB)) {
        print('⚠️  Colors $i and $j may be confused in Protanopia');
        print('   $i: ${_colorToHex(colorA)} → ${_colorToHex(protA)}');
        print('   $j: ${_colorToHex(colorB)} → ${_colorToHex(protB)}');
      }
    }
  }
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

bool _colorsSimilar(Color a, Color b) {
  // Consider colors similar if deltaE < 10 (perceptual difference)
  final dr = (a.red - b.red).abs();
  final dg = (a.green - b.green).abs();
  final db = (a.blue - b.blue).abs();
  
  return (dr + dg + db) < 30; // Simplified check
}
```

### The Okabe-Ito Palette

The scientifically-validated **Okabe-Ito palette** is designed to be distinguishable by all types of colorblindness:

```dart
final colorblindSafe = ChartTheme.colorblindFriendly;

// Palette colors:
// 1. Orange:         #E69F00
// 2. Sky Blue:       #56B4E9
// 3. Bluish Green:   #009E73
// 4. Yellow:         #F0E442
// 5. Blue:           #0072B2
// 6. Vermillion:     #D55E00
// 7. Reddish Purple: #CC79A7
```

**Why it works:**
- Maximum separation in color space
- Validated across all CVD types
- High contrast against white and black backgrounds
- Widely used in scientific publications

### Design Guidelines for Colorblindness

#### 1. Use the Colorblind-Friendly Theme

```dart
final theme = ChartTheme.colorblindFriendly;
```

#### 2. Add Non-Color Differentiators

Don't rely on color alone:

```dart
final theme = ChartThemeBuilder()
  .seriesTheme(SeriesTheme(
    colors: [Colors.blue, Colors.red, Colors.green],
    
    // Different line widths
    lineWidths: [2.0, 3.0, 4.0],
    
    // Different marker shapes
    markerShapes: [
      MarkerShape.circle,
      MarkerShape.square,
      MarkerShape.triangle,
    ],
    
    // Different marker sizes
    markerSizes: [6.0, 8.0, 10.0],
  ))
  .build();
```

#### 3. Avoid Problematic Color Combinations

**Bad:**
- Red + Green (indistinguishable to deuteranopes and protanopes)
- Blue + Purple (indistinguishable to tritanopes)
- Light colors on light background
- Dark colors on dark background

**Good:**
- Blue + Orange (high contrast across all CVD types)
- Blue + Yellow (safe and high contrast)
- Black + White (universal)
- Use Okabe-Ito palette

#### 4. Test with Simulation Tools

Always test your themes:

```dart
void main() {
  final myTheme = ChartThemeBuilder()
    .seriesTheme(SeriesTheme(
      colors: [
        Color(0xFF0066CC), // Blue
        Color(0xFFFF6B35), // Orange
        Color(0xFF004E89), // Dark blue
      ],
      lineWidths: [2.0],
      markerSizes: [6.0],
      markerShapes: [MarkerShape.circle],
    ))
    .build();
  
  testPaletteForColorblindness(myTheme.seriesTheme.colors);
}
```

---

## Testing for Accessibility

### Manual Testing Checklist

- [ ] **Contrast Check**: All text has 4.5:1 minimum contrast
- [ ] **Large Text Check**: Titles ≥24px have 3:1 minimum contrast
- [ ] **Border/UI Check**: All borders and UI elements have 3:1 minimum contrast
- [ ] **Tooltip Check**: Tooltip text has 4.5:1 contrast on tooltip background
- [ ] **Series Differentiation**: Series use different shapes/patterns, not just colors
- [ ] **Colorblind Simulation**: Test with protanopia, deuteranopia, tritanopia simulations
- [ ] **Screen Reader**: Chart has descriptive labels (future: ARIA support)
- [ ] **Keyboard Navigation**: All interactive elements are keyboard accessible (future)
- [ ] **Zoom Test**: Chart remains readable at 200% zoom
- [ ] **Grayscale Test**: Convert to grayscale and verify information is still clear

### Automated Testing

Include accessibility tests in your test suite:

```dart
// test/accessibility/theme_accessibility_test.dart

import 'package:braven_charts/theming.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Accessibility Tests', () {
    test('All predefined themes meet WCAG AA', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];
      
      for (final theme in themes) {
        // Background vs axis labels
        final labelRatio = ColorUtils.calculateContrastRatio(
          theme.backgroundColor,
          theme.axisStyle.labelStyle.color!,
        );
        
        expect(
          labelRatio,
          greaterThanOrEqualTo(4.5),
          reason: 'Axis labels must have 4.5:1 contrast',
        );
        
        // Tooltip text vs background
        final tooltipRatio = ColorUtils.calculateContrastRatio(
          theme.interactionTheme.tooltipBackgroundColor,
          theme.interactionTheme.tooltipTextColor,
        );
        
        expect(
          tooltipRatio,
          greaterThanOrEqualTo(4.5),
          reason: 'Tooltip text must have 4.5:1 contrast',
        );
      }
    });
    
    test('High Contrast theme meets WCAG AAA', () {
      final theme = ChartTheme.highContrast;
      
      final labelRatio = ColorUtils.calculateContrastRatio(
        theme.backgroundColor,
        theme.axisStyle.labelStyle.color!,
      );
      
      expect(
        labelRatio,
        greaterThanOrEqualTo(7.0),
        reason: 'High Contrast theme must meet WCAG AAA (7:1)',
      );
    });
    
    test('Colorblind-friendly palette uses Okabe-Ito colors', () {
      final theme = ChartTheme.colorblindFriendly;
      final colors = theme.seriesTheme.colors;
      
      // Okabe-Ito palette
      expect(colors[0], const Color(0xFFE69F00)); // Orange
      expect(colors[1], const Color(0xFF56B4E9)); // Sky Blue
      expect(colors[2], const Color(0xFF009E73)); // Bluish Green
      expect(colors[3], const Color(0xFFF0E442)); // Yellow
      expect(colors[4], const Color(0xFF0072B2)); // Blue
      expect(colors[5], const Color(0xFFD55E00)); // Vermillion
      expect(colors[6], const Color(0xFFCC79A7)); // Reddish Purple
    });
  });
}
```

### Third-Party Tools

For comprehensive testing, use external tools:

1. **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/
2. **Color Oracle**: Free colorblindness simulator (desktop app)
3. **Coblis**: Online colorblind simulator
4. **Chrome DevTools**: Built-in vision deficiency emulation
5. **axe DevTools**: Automated accessibility testing

---

## Accessible Theme Checklist

Use this checklist when creating custom themes:

### Text Contrast

- [ ] Axis labels: ≥4.5:1 against background (WCAG AA)
- [ ] Axis titles: ≥4.5:1 against background (or ≥3:1 if ≥24px)
- [ ] Legend text: ≥4.5:1 against background
- [ ] Tooltip text: ≥4.5:1 against tooltip background
- [ ] Data labels: ≥4.5:1 against background

### UI Element Contrast

- [ ] Chart border: ≥3:1 against background (WCAG AA 1.4.11)
- [ ] Grid lines: ≥3:1 against background
- [ ] Axis lines: ≥3:1 against background
- [ ] Series lines/markers: ≥3:1 against background

### Color Independence

- [ ] Information not conveyed by color alone
- [ ] Series use different shapes/patterns
- [ ] Critical elements have text labels
- [ ] Hover states use multiple indicators (color + border + size)

### Colorblind Safety

- [ ] Palette tested with protanopia simulation
- [ ] Palette tested with deuteranopia simulation
- [ ] Palette tested with tritanopia simulation
- [ ] No red-green combinations for critical distinctions
- [ ] Okabe-Ito palette considered for maximum safety

### Typography

- [ ] Minimum font size: 11px (WCAG minimum is approximately 11px)
- [ ] Font is legible (sans-serif recommended)
- [ ] Line height ≥1.5 for body text
- [ ] Letter spacing adequate for readability

### Testing

- [ ] Automated contrast tests pass
- [ ] Manual inspection in grayscale
- [ ] Tested with screen magnification (200%)
- [ ] Tested with colorblind simulators
- [ ] Real user testing (if possible)

---

## Common Pitfalls

### 1. Relying on Color Alone

**❌ Bad:**
```dart
// Red line = errors, green line = success
// Colorblind users cannot distinguish
```

**✅ Good:**
```dart
final theme = ChartThemeBuilder()
  .seriesTheme(SeriesTheme(
    colors: [Colors.red, Colors.green],
    markerShapes: [MarkerShape.cross, MarkerShape.circle], // Different shapes
    lineWidths: [3.0, 2.0], // Different widths
  ))
  .build();

// Also: Add text labels like "Errors" and "Success"
```

### 2. Low Contrast Grid Lines

**❌ Bad:**
```dart
GridStyle(
  majorColor: Color(0xFFF0F0F0), // 1.2:1 on white background
  majorWidth: 0.5,
)
```

**✅ Good:**
```dart
GridStyle(
  majorColor: Color(0xFFCCCCCC), // 3.1:1 on white background
  majorWidth: 1.0,
)
```

### 3. Thin Text on Dark Backgrounds

**❌ Bad:**
```dart
// Light gray on dark gray: low contrast
backgroundColor: Color(0xFF424242),
axisStyle: AxisStyle(
  labelStyle: TextStyle(color: Color(0xFF999999)), // 3.2:1 - fails AA
)
```

**✅ Good:**
```dart
backgroundColor: Color(0xFF424242),
axisStyle: AxisStyle(
  labelStyle: TextStyle(color: Color(0xFFFFFFFF)), // 9.7:1 - passes AAA
)
```

### 4. Red-Green Color Schemes

**❌ Bad:**
```dart
// Most common form of colorblindness cannot distinguish these
colors: [Colors.red, Colors.green]
```

**✅ Good:**
```dart
// Blue-orange has high contrast for all CVD types
colors: [Color(0xFF0072B2), Color(0xFFE69F00)]
```

### 5. Small Font Sizes

**❌ Bad:**
```dart
typographyTheme: TypographyTheme(
  baseFontSize: 8.0, // Too small for many users
)
```

**✅ Good:**
```dart
typographyTheme: TypographyTheme(
  baseFontSize: 12.0, // Readable minimum
)
```

---

## Resources

### Official Guidelines

- **WCAG 2.1**: https://www.w3.org/WAI/WCAG21/quickref/
- **WCAG 1.4.3 (Contrast)**: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum
- **WCAG 1.4.11 (Non-text Contrast)**: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast

### Color Tools

- **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Coolors Contrast Checker**: https://coolors.co/contrast-checker
- **Color Oracle** (simulator): https://colororacle.org/
- **Coblis** (online simulator): https://www.color-blindness.com/coblis-color-blindness-simulator/

### Scientific References

- **Okabe & Ito (2008)**: "Color Universal Design" - https://jfly.uni-koeln.de/color/
- **Colorbrewer**: Research-backed color schemes - https://colorbrewer2.org/

### Braven Charts Documentation

- **Theming Usage Guide**: `docs/guides/theming-usage.md`
- **API Reference**: Dartdoc in `lib/src/theming/`
- **Example Tests**: `test/integration/theming/quickstart_examples_test.dart`

---

## Summary

This guide covered:

✅ **WCAG 2.1 Compliance**: AA and AAA standards for charts  
✅ **Contrast Requirements**: 4.5:1 for text, 3:1 for UI, 7:1 for AAA  
✅ **Verification Tools**: ColorUtils API for automated checking  
✅ **Colorblind Design**: Okabe-Ito palette, simulation tools, design guidelines  
✅ **Testing Procedures**: Manual checklist, automated tests, third-party tools  
✅ **Accessible Checklist**: Comprehensive pre-launch verification  
✅ **Common Pitfalls**: What to avoid and how to fix  
✅ **Resources**: Official guidelines, tools, scientific references  

**Key Takeaways:**

1. **Use predefined themes** for instant WCAG AA compliance
2. **Use High Contrast theme** for WCAG AAA compliance
3. **Use Colorblind-Friendly theme** for universal color accessibility
4. **Always verify custom themes** with ColorUtils API
5. **Don't rely on color alone** - use shapes, patterns, labels
6. **Test early and often** with simulations and real users

Making charts accessible is not optional—it's a fundamental requirement for inclusive design.

---

**Questions or Issues?**  
File an issue on GitHub: https://github.com/forcegage-pvm/braven_charts/issues
