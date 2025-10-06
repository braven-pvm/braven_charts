# Research & Design Decisions: Theming System

**Feature**: 004-theming-system  
**Date**: 2025-10-06  
**Status**: Complete

---

## Overview

This document captures all research findings and design decisions made during the planning phase of the Theming System. Each decision includes the rationale, alternatives considered, and implementation implications.

---

## 1. Theme Architecture Pattern

### Decision
Implement **immutable theme data structures** with `copyWith()` semantics, following Flutter's `ThemeData` pattern.

### Rationale
- **Consistency**: Matches Flutter conventions, familiar to Flutter developers
- **Safety**: Prevents accidental mutations that could cause rendering inconsistencies
- **Performance**: Enables efficient theme diffing (object identity checks)
- **Testability**: Immutable objects easier to test (no state mutations to track)
- **Debugging**: No hidden side effects from mutations

### Alternatives Considered
1. **Mutable themes with setters**
   - Rejected: Risk of race conditions in rendering pipeline
   - Rejected: Harder to test (need to track state changes)
   - Rejected: Theme diffing requires deep equality checks (expensive)

2. **Builder-only pattern (no direct construction)**
   - Rejected: Too restrictive for simple theme creation
   - Rejected: Forces builder overhead even for const themes

### Implementation Implications
- All theme classes: `final` fields, `const` constructors where possible
- `copyWith()` method for each theme component (7 components)
- Deep `==` operator and `hashCode` implementation
- Theme diffing via object identity first, then deep equality if needed

### Code Pattern
```dart
class ChartTheme {
  const ChartTheme({
    required this.backgroundColor,
    required this.gridStyle,
    // ... all fields final
  });

  final Color backgroundColor;
  final GridStyle gridStyle;
  // ... more fields

  ChartTheme copyWith({
    Color? backgroundColor,
    GridStyle? gridStyle,
    // ... all fields
  }) {
    return ChartTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridStyle: gridStyle ?? this.gridStyle,
      // ...
    );
  }

  @override
  bool operator ==(Object other) { /* deep equality */ }
  
  @override
  int get hashCode => Object.hash(backgroundColor, gridStyle, ...);
}
```

---

## 2. Style Cascade Resolution

### Decision
Implement **CSS-like cascading** with precedence: element override > chart override > theme > system default.

### Rationale
- **Familiarity**: Web developers already understand CSS cascade
- **Flexibility**: Allows granular overrides without full theme duplication
- **Predictability**: Clear, documented precedence order
- **Performance**: Can cache resolved styles efficiently
- **Maintainability**: Centralized resolution logic, not scattered

### Alternatives Considered
1. **Single-level override (no cascade)**
   - Rejected: Not flexible enough for complex charts
   - Example failure: Can't override single series color without defining all series colors

2. **Deep merging (JSON-style)**
   - Rejected: Expensive performance cost (recursive merging)
   - Rejected: Unclear semantics for null vs. undefined vs. missing
   - Rejected: Hard to reason about final resolved value

3. **React-style context propagation**
   - Rejected: Doesn't fit Flutter's widget tree model well
   - Rejected: Requires context threading through all rendering code

### Implementation Implications
- Style resolution function: `resolveStyle(element, chart, theme, default)`
- Caching: Key = `(theme.hashCode, elementType, overrides.hashCode)`
- Cache invalidation: Full clear on theme change (simple, correct)
- LRU eviction: 1000-entry limit to prevent memory bloat

### Precedence Rules
```dart
// Precedence order (highest to lowest):
1. Element-specific override (e.g., series[0].color = red)
2. Chart-level override (e.g., chart.axisStyle = customStyle)
3. Theme-level default (e.g., theme.axisStyle)
4. System default (e.g., AxisStyle.defaultLight)

// Resolution example:
Color resolveAxisColor(Element element, Chart chart, ChartTheme theme) {
  return element.axisColor          // 1. Element override
      ?? chart.axisStyle?.color     // 2. Chart override
      ?? theme.axisStyle.color      // 3. Theme default
      ?? AxisStyle.defaultColor;    // 4. System default
}
```

---

## 3. Color Accessibility Standards

### Decision
Comply with **WCAG 2.1 AA (4.5:1)** for all themes, **WCAG 2.1 AAA (7:1)** for High Contrast theme.

### Rationale
- **Legal compliance**: Required by many jurisdictions (ADA, Section 508, AODA)
- **Inclusivity**: 1 in 12 men (8%) have color vision deficiency
- **Best practice**: Industry standard for accessible design
- **Measurable**: Objective, testable criteria (contrast ratio calculation)
- **Future-proof**: WCAG 2.1 widely adopted, stable standard

### Algorithms Implemented

#### WCAG 2.1 Relative Luminance
```dart
// Per WCAG 2.1 spec (https://www.w3.org/TR/WCAG21/#dfn-relative-luminance)
double relativeLuminance(Color color) {
  final r = _sRGBtoLinear(color.red / 255.0);
  final g = _sRGBtoLinear(color.green / 255.0);
  final b = _sRGBtoLinear(color.blue / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _sRGBtoLinear(double channel) {
  if (channel <= 0.03928) {
    return channel / 12.92;
  } else {
    return pow((channel + 0.055) / 1.055, 2.4);
  }
}
```

#### Contrast Ratio Calculation
```dart
// Per WCAG 2.1 spec (https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio)
double contrastRatio(Color c1, Color c2) {
  final l1 = relativeLuminance(c1);
  final l2 = relativeLuminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

// Usage:
// AA (normal text): ratio >= 4.5
// AA (large text 18pt+): ratio >= 3.0
// AAA (normal text): ratio >= 7.0
// AAA (large text 18pt+): ratio >= 4.5
```

#### Brettel Colorblind Simulation
```dart
// Brettel et al. algorithm for protanopia/deuteranopia/tritanopia
// Reference: Brettel, H., Viénot, F., & Mollon, J. D. (1997)
// "Computerized simulation of color appearance for dichromats"
Color simulateColorblind(Color color, ColorblindType type) {
  // Convert RGB → LMS (cone response)
  final lms = rgbToLms(color);
  
  // Apply dichromatic transformation matrix
  final Matrix3 transform = switch (type) {
    ColorblindType.protanopia => protanopiaMatrix,    // L-cone deficiency
    ColorblindType.deuteranopia => deuteranopiaMatrix, // M-cone deficiency
    ColorblindType.tritanopia => tritanopiaMatrix,    // S-cone deficiency
  };
  
  final simulatedLms = transform * lms;
  
  // Convert LMS → RGB
  return lmsToRgb(simulatedLms);
}
```

### Validation Strategy
- Unit tests: Verify all theme text/background pairs meet AA minimum
- High Contrast theme: Verify AAA compliance (7:1)
- Colorblind tests: Run simulation, verify all series distinguishable
- Grayscale test: Convert to grayscale, verify series separable

### Alternatives Considered
1. **WCAG 1.0 (obsolete)**
   - Rejected: Superseded by WCAG 2.0 (2008), then 2.1 (2018)

2. **Apple Human Interface Guidelines only**
   - Rejected: Not sufficient for web accessibility (our primary target)

3. **No formal accessibility requirements**
   - Rejected: Violates our commitment to inclusivity and legal compliance

---

## 4. Serialization Strategy

### Decision
Use **JSON with versioned schema**, missing properties use defaults, unknown properties ignored.

### Rationale
- **Human-readable**: JSON is debuggable, can be hand-edited if needed
- **Ubiquitous**: Every platform/language has JSON support
- **Forward compatible**: Versioning allows schema evolution
- **Backward compatible**: Missing properties filled with defaults
- **Dart native**: `dart:convert` built-in, no dependencies

### Schema Versioning
```json
{
  "version": "1.0",
  "theme": {
    "backgroundColor": "#FFFFFF",
    "gridStyle": {
      "majorColor": "#E0E0E0",
      "majorWidth": 1.0
    }
  }
}
```

Version handling:
- **Current version**: 1.0
- **Unknown version**: Parse best-effort, warn if >2.0
- **Missing version**: Assume 1.0
- **Future versions**: 1.x (minor) = backward compatible, 2.0 (major) = breaking changes

### Implementation Pattern
```dart
Map<String, dynamic> toJson() {
  return {
    'version': '1.0',
    'theme': {
      'backgroundColor': '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
      'gridStyle': gridStyle.toJson(),
      // ... all components
    },
  };
}

static ChartTheme fromJson(Map<String, dynamic> json) {
  final version = json['version'] as String? ?? '1.0';
  if (version != '1.0') {
    print('Warning: Theme schema version $version, expected 1.0');
  }
  
  final themeData = json['theme'] as Map<String, dynamic>;
  return ChartTheme(
    backgroundColor: _parseColor(themeData['backgroundColor']) ?? Colors.white,
    gridStyle: GridStyle.fromJson(themeData['gridStyle'] ?? {}),
    // ... all components with ?? defaults
  );
}
```

### Alternatives Considered
1. **Binary serialization (Protocol Buffers, MessagePack)**
   - Rejected: Not human-readable, harder to debug
   - Rejected: Adds external dependency
   - Pro: More compact, faster parsing (not critical for themes)

2. **YAML**
   - Rejected: No native Dart support (requires external package)
   - Pro: More human-friendly syntax (but themes rarely hand-edited)

3. **Dart code generation (built_value, json_serializable)**
   - Rejected: Overkill for simple DTOs
   - Rejected: Build step adds complexity
   - Pro: Type-safe, no runtime errors (but tests catch these)

---

## 5. Performance Optimization Strategy

### Decision
Use **LRU (Least Recently Used) cache** for resolved styles, keyed by `(theme hash, element type, overrides hash)`.

### Rationale
- **Bounded memory**: LRU eviction prevents unbounded growth
- **High hit rate**: Rendering loops access same styles repeatedly
- **Fast lookups**: O(1) hash table lookup
- **Simple invalidation**: Full cache clear on theme change (correct, minimal code)
- **Measurable**: Can track hit rate, cache size

### Cache Sizing
```dart
class StyleCache {
  static const int maxSize = 1000;  // Sufficient for most charts
  
  // Typical chart:
  // - 10 chart elements (grid, axes, title, legend, etc.)
  // - 5-10 series (each with overrides)
  // - 10 style variations per element
  // = ~100-200 entries used, 1000 provides headroom
}
```

### Cache Key Design
```dart
class StyleCacheKey {
  final int themeHash;
  final String elementType;  // 'axis', 'grid', 'series', etc.
  final int? overridesHash;  // null if no overrides
  
  @override
  int get hashCode => Object.hash(themeHash, elementType, overridesHash);
  
  @override
  bool operator ==(Object other) => /* ... */;
}
```

### LRU Implementation
```dart
import 'dart:collection';

class StyleCache {
  final _cache = LinkedHashMap<StyleCacheKey, dynamic>(
    // LinkedHashMap maintains insertion order
  );
  
  T? get<T>(StyleCacheKey key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end (most recently used)
    }
    return value as T?;
  }
  
  void put<T>(StyleCacheKey key, T value) {
    _cache.remove(key); // Remove if exists
    _cache[key] = value; // Insert at end
    
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first); // Evict oldest
    }
  }
  
  void clear() => _cache.clear();
  
  double get hitRate => _hits / (_hits + _misses);
}
```

### Performance Targets
- **Cache hit rate**: >95% during normal rendering
- **Lookup time**: <0.1ms per style resolution
- **Memory usage**: <100KB for cache (1000 entries × ~100 bytes/entry)
- **Theme switching**: <100ms (includes cache clear + re-resolve visible styles)

### Alternatives Considered
1. **No caching (compute every frame)**
   - Rejected: Wastes CPU (same styles computed repeatedly)
   - Rejected: Violates <16ms frame budget for complex charts

2. **Infinite cache (no eviction)**
   - Rejected: Memory leak risk (unbounded growth)
   - Rejected: Poor cache locality (old entries never used)

3. **Time-based expiration (TTL)**
   - Rejected: More complex than needed
   - Rejected: Theme changes are explicit events, not time-based

4. **LFU (Least Frequently Used)**
   - Rejected: More complex to implement
   - Rejected: LRU sufficient for our access patterns

---

## 6. Responsive Typography

### Decision
**Breakpoint-based scaling** with smooth interpolation: mobile (0-599px, 0.9x), tablet (600-1023px, 1.0x), desktop (1024px+, 1.1x).

### Rationale
- **Material Design aligned**: Matches Material Design 3 breakpoints
- **Web-first**: Common web responsive design practice
- **Predictable**: Developers know standard breakpoints
- **Testable**: Discrete breakpoints easier to test than continuous scaling
- **Flutter support**: MediaQuery provides viewport width

### Breakpoints
```dart
class TypographyBreakpoints {
  static const double mobile = 600.0;   // < 600px
  static const double tablet = 1024.0;  // 600-1023px
  static const double desktop = 1024.0; // >= 1024px
  
  static double getScaleFactor(double viewportWidth) {
    if (viewportWidth < mobile) return 0.9;   // Mobile: smaller text
    if (viewportWidth < desktop) return 1.0;  // Tablet: base size
    return 1.1;                                // Desktop: larger text
  }
}
```

### Smooth Interpolation (Optional)
```dart
// For smooth scaling between breakpoints (not jumping)
static double getScaleFactorSmooth(double viewportWidth) {
  if (viewportWidth < mobile) {
    // 0-599px: interpolate 0.85 → 0.9
    final t = viewportWidth / mobile;
    return 0.85 + (0.9 - 0.85) * t;
  } else if (viewportWidth < desktop) {
    // 600-1023px: interpolate 0.9 → 1.0
    final t = (viewportWidth - mobile) / (desktop - mobile);
    return 0.9 + (1.0 - 0.9) * t;
  } else {
    // 1024px+: interpolate 1.0 → 1.1 (cap at 1200px)
    final t = min((viewportWidth - desktop) / 200.0, 1.0);
    return 1.0 + (1.1 - 1.0) * t;
  }
}
```

### Minimum Readable Size
```dart
static const double minFontSize = 10.0; // Enforced minimum

TextStyle applyScaleFactor(TextStyle base, double factor) {
  final scaledSize = base.fontSize! * factor;
  return base.copyWith(
    fontSize: max(scaledSize, minFontSize),
  );
}
```

### Alternatives Considered
1. **Fixed sizes (no responsive scaling)**
   - Rejected: Text too small on mobile, too large on ultrawide
   - Rejected: Poor user experience across device spectrum

2. **Continuous scaling (viewport width / 100)**
   - Rejected: Unpredictable sizing, hard to reason about
   - Rejected: Can produce sizes between font rasterization hints

3. **CSS-style clamp() (min, preferred, max)**
   - Considered: More flexible, but more complex
   - Deferred: Can add later if breakpoints insufficient

4. **Device pixel ratio scaling**
   - Rejected: Orthogonal concern (handled by Flutter)
   - Rejected: We want logical size scaling, not physical

---

## 7. Builder API Design

### Decision
**Fluent API** with method chaining, starting from base theme or defaults, validation before `build()`.

### Rationale
- **Discoverability**: IDE autocomplete shows all available methods
- **Readability**: Method chaining reads like natural language
- **Familiar pattern**: Used throughout Dart/Flutter ecosystem
- **Type-safe**: Compile-time checks for valid values
- **Validation**: Centralized validation in `build()`, fails fast with clear errors

### API Pattern
```dart
class ChartThemeBuilder {
  // Start from defaults
  ChartThemeBuilder();
  
  // Start from existing theme (copy)
  ChartThemeBuilder.from(ChartTheme base);
  
  // Fluent setters
  ChartThemeBuilder backgroundColor(Color color) {
    _backgroundColor = color;
    return this;
  }
  
  ChartThemeBuilder seriesColors(List<Color> colors) {
    _seriesColors = colors;
    return this;
  }
  
  ChartThemeBuilder gridStyle(GridStyle style) {
    _gridStyle = style;
    return this;
  }
  
  // ... more fluent setters
  
  // Validation and build
  ChartTheme build() {
    _validate();
    return ChartTheme(
      backgroundColor: _backgroundColor ?? _defaults.backgroundColor,
      seriesTheme: SeriesTheme(
        colors: _seriesColors ?? _defaults.seriesTheme.colors,
        // ...
      ),
      gridStyle: _gridStyle ?? _defaults.gridStyle,
      // ...
    );
  }
  
  void _validate() {
    if (_seriesColors != null && _seriesColors!.isEmpty) {
      throw ArgumentError('seriesColors cannot be empty');
    }
    if (_gridStyle?.majorWidth != null && _gridStyle!.majorWidth < 0) {
      throw ArgumentError('gridStyle.majorWidth must be >= 0');
    }
    // ... more validations
  }
}
```

### Usage Examples
```dart
// Minimal customization
final theme1 = ChartThemeBuilder()
  .backgroundColor(Colors.white)
  .build();

// Start from predefined theme
final theme2 = ChartThemeBuilder.from(ChartTheme.defaultDark)
  .seriesColors([Colors.red, Colors.blue])
  .build();

// Complex customization
final theme3 = ChartThemeBuilder()
  .backgroundColor(Color(0xFFF5F5F5))
  .seriesColors([Color(0xFF1976D2), Color(0xFFFF6F00)])
  .gridStyle(GridStyle(
    majorColor: Colors.grey[300]!,
    majorWidth: 0.5,
    showMinor: false,
  ))
  .typography(TypographyTheme(
    fontFamily: 'Roboto',
    baseFontSize: 12,
  ))
  .build();
```

### Alternatives Considered
1. **Constructor-only (no builder)**
   - Rejected: 20+ parameters unwieldy (ChartTheme has many fields)
   - Rejected: No validation until theme used (late errors)

2. **Cascading operator (..) instead of fluent**
   - Rejected: Requires void setters (can't return this)
   - Rejected: Less discoverable (requires knowing all methods up front)

3. **Separate builder for each component**
   - Considered: More fine-grained, but more boilerplate
   - Deferred: Can add if builder becomes too complex

4. **Mutable builder (modify in place)**
   - Rejected: Harder to test (mutations)
   - Rejected: Can't reuse builder instance safely

---

## 8. Theme Switching Performance

### Decision
**Theme diffing** to identify changed components, only re-render affected visual elements. No chart recreation.

### Rationale
- **Performance**: Avoid full chart rebuild (expensive)
- **State preservation**: Maintains zoom level, selection, viewport
- **User experience**: Smooth transition, no flicker
- **Testable**: Can measure switching time, verify state preservation

### Diffing Strategy
```dart
class ThemeChangeSet {
  final bool backgroundChanged;
  final bool gridStyleChanged;
  final bool axisStyleChanged;
  final bool seriesThemeChanged;
  final bool interactionThemeChanged;
  final bool typographyChanged;
  final bool animationChanged;
  
  factory ThemeChangeSet.compute(ChartTheme oldTheme, ChartTheme newTheme) {
    return ThemeChangeSet(
      backgroundChanged: oldTheme.backgroundColor != newTheme.backgroundColor,
      gridStyleChanged: oldTheme.gridStyle != newTheme.gridStyle,
      axisStyleChanged: oldTheme.axisStyle != newTheme.axisStyle,
      // ... compare each component (uses deep equality)
    );
  }
  
  bool get anyChanged => backgroundChanged || gridStyleChanged || /* ... */;
}
```

### Theme Application
```dart
void updateTheme(ChartTheme newTheme) {
  final changeSet = ThemeChangeSet.compute(_currentTheme, newTheme);
  
  if (!changeSet.anyChanged) {
    return; // No-op if themes equal
  }
  
  _currentTheme = newTheme;
  _styleCache.clear(); // Invalidate cached resolved styles
  
  // Trigger partial re-render (only changed components)
  if (changeSet.backgroundChanged) {
    _repaintBackground();
  }
  if (changeSet.gridStyleChanged) {
    _repaintGrid();
  }
  if (changeSet.seriesThemeChanged) {
    _repaintSeries();
  }
  // ... selective re-render
}
```

### Performance Target
- **<100ms total**: Theme switch completes within 100ms
  - Diff computation: <5ms
  - Cache clear: <1ms
  - Re-render affected: <94ms (depends on what changed)
- **No state loss**: Zoom, pan, selection all preserved
- **No flicker**: Smooth transition (can optionally animate)

### Alternatives Considered
1. **Full chart recreation**
   - Rejected: Too slow (>500ms for complex charts)
   - Rejected: Loses zoom/pan/selection state

2. **Copy-on-write theme internals**
   - Rejected: More complexity for marginal benefit
   - Rejected: Diffing with deep equality is fast enough

3. **Reactive streams (theme as stream)**
   - Rejected: Overkill for infrequent theme changes
   - Rejected: Adds dependency (RxDart or similar)

---

## 9. Platform Font Strategy

### Decision
**Platform-specific font detection** with fallback chain: Roboto (Android/Web), SF Pro (iOS), Segoe UI (Windows).

### Rationale
- **Native feel**: Each platform uses its system font for familiarity
- **Performance**: System fonts already loaded, no network fetch
- **Consistency**: Font metrics stable across same platform
- **Reliability**: Fallback chain ensures text always renders
- **Compliance**: Matches platform UI guidelines (Material Design, HIG)

### Implementation Pattern
```dart
class TypographyTheme {
  static String getPlatformFont() {
    if (Platform.isIOS || Platform.isMacOS) {
      return 'SF Pro Display';
    } else if (Platform.isAndroid) {
      return 'Roboto';
    } else if (Platform.isWindows) {
      return 'Segoe UI';
    } else if (Platform.isLinux) {
      return 'Ubuntu';
    } else {
      // Web or unknown platform
      return 'Roboto'; // Web default
    }
  }
  
  static const List<String> fallbackFonts = [
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
  
  const TypographyTheme({
    String? fontFamily,
    // ... other fields
  }) : fontFamily = fontFamily ?? getPlatformFont();
}
```

### Font Loading
- **System fonts**: Immediately available (no load time)
- **Custom fonts**: Use `FontLoader` with 3-second timeout
- **Fallback**: If font unavailable, use next in chain
- **No layout shift**: Reserve space with fallback metrics

### Alternatives Considered
1. **Single universal font (Roboto everywhere)**
   - Rejected: Doesn't match iOS/macOS native feel
   - Rejected: Users expect SF Pro on Apple devices

2. **Web fonts only (no platform detection)**
   - Rejected: Slower initial load (network fetch)
   - Rejected: Increases bundle size

3. **User-configurable font (no defaults)**
   - Rejected: Requires all users to make font decision
   - Rejected: More complex API for common use case

---

## Summary of Key Decisions

| Area | Decision | Why |
|------|----------|-----|
| Architecture | Immutable with copyWith() | Flutter conventions, safety, testability |
| Style Cascade | CSS-like precedence | Familiar, flexible, cacheable |
| Accessibility | WCAG 2.1 AA/AAA | Legal, inclusive, measurable |
| Serialization | Versioned JSON | Human-readable, forward-compatible |
| Performance | LRU style cache | Bounded memory, high hit rate |
| Typography | Breakpoint scaling | Material Design aligned, predictable |
| Platform Fonts | Platform detection + fallbacks | Native feel, performance, reliability |
| Builder API | Fluent with validation | Discoverable, type-safe, readable |
| Theme Switching | Diff + partial render | Fast, state-preserving, smooth |

---

## Implementation Checklist

- [x] Research theme architecture patterns
- [x] Research style cascade approaches
- [x] Research WCAG accessibility standards
- [x] Research serialization formats
- [x] Research cache eviction strategies
- [x] Research responsive typography patterns
- [x] Research builder API patterns
- [x] Research theme switching performance
- [ ] Implement core theme structure (Phase 1)
- [ ] Implement predefined themes (Phase 2)
- [ ] Implement builder API (Phase 3)
- [ ] Implement utilities (ColorUtils, StyleCache) (Phase 4)
- [ ] Implement integration with rendering (Phase 5)
- [ ] Performance benchmarks (Phase 6)

---

**Research Phase Complete**: 2025-10-06  
**Next Phase**: Create data-model.md, contracts/, quickstart.md
