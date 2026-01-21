# Data Model: Theming System

**Feature**: 004-theming-system  
**Layer**: 3 (depends on Foundation, Core Rendering)  
**Date**: 2025-10-06

---

## Overview

This document defines the complete data model for the Theming System, including all entities, their relationships, validation rules, state transitions, and serialization formats.

---

## Entity Relationship Diagram

```
ChartTheme (root)
    ├── backgroundColor: Color
    ├── borderColor: Color
    ├── borderWidth: double
    ├── padding: EdgeInsets
    ├── GridStyle
    │   ├── majorColor: Color
    │   ├── majorWidth: double
    │   ├── majorDashPattern: List<double>?
    │   ├── minorColor: Color?
    │   ├── minorWidth: double?
    │   ├── minorDashPattern: List<double>?
    │   └── showMinor: bool
    ├── AxisStyle
    │   ├── lineColor: Color
    │   ├── lineWidth: double
    │   ├── textStyle: TextStyle
    │   ├── titleStyle: TextStyle
    │   ├── tickLength: double
    │   ├── tickColor: Color
    │   └── tickWidth: double
    ├── SeriesTheme
    │   ├── colors: List<Color> (min 1)
    │   ├── lineWidths: List<double> (min 1)
    │   ├── dashPatterns: List<List<double>?> (min 1)
    │   ├── markerShapes: List<MarkerShape> (min 1)
    │   └── markerSizes: List<double> (min 1)
    ├── InteractionTheme
    │   ├── crosshairColor: Color
    │   ├── crosshairWidth: double
    │   ├── crosshairDashPattern: List<double>?
    │   ├── tooltipBackground: Color
    │   ├── tooltipTextStyle: TextStyle
    │   ├── tooltipBorderColor: Color
    │   ├── tooltipBorderWidth: double
    │   ├── selectionColor: Color
    │   └── selectionOpacity: double
    ├── TypographyTheme
    │   ├── fontFamily: String
    │   ├── baseFontSize: double
    │   ├── titleFontSize: double
    │   ├── labelFontSize: double
    │   ├── fontWeight: FontWeight
    │   └── scaleFactor: double (computed from viewport)
    └── AnimationTheme
        ├── dataUpdateDuration: Duration
        ├── dataUpdateCurve: Curve
        ├── themeSwitchDuration: Duration
        └── themeSwitchCurve: Curve
```

---

## Entity Specifications

### 1. ChartTheme (Root Entity)

**Purpose**: Top-level theme container, aggregates all component themes.

**Fields**:
```dart
class ChartTheme {
  const ChartTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.padding,
    required this.gridStyle,
    required this.axisStyle,
    required this.seriesTheme,
    required this.interactionTheme,
    required this.typographyTheme,
    required this.animationTheme,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final GridStyle gridStyle;
  final AxisStyle axisStyle;
  final SeriesTheme seriesTheme;
  final InteractionTheme interactionTheme;
  final TypographyTheme typographyTheme;
  final AnimationTheme animationTheme;
}
```

**Validation Rules**:
- `borderWidth >= 0.0` (0 = no border)
- All theme components must be non-null
- All colors must have alpha >= 0 (0 = transparent OK)

**Invariants**:
- Immutable after construction
- All fields are `final`
- Can only be modified via `copyWith()` (returns new instance)

**Default Values**:
```dart
static const ChartTheme defaultLight = ChartTheme(
  backgroundColor: Color(0xFFFFFFFF),
  borderColor: Color(0xFFE0E0E0),
  borderWidth: 1.0,
  padding: EdgeInsets.all(16.0),
  gridStyle: GridStyle.defaultLight,
  axisStyle: AxisStyle.defaultLight,
  seriesTheme: SeriesTheme.defaultLight,
  interactionTheme: InteractionTheme.defaultLight,
  typographyTheme: TypographyTheme.defaultLight,
  animationTheme: AnimationTheme.defaultLight,
);
```

**Serialization**:
```json
{
  "version": "1.0",
  "theme": {
    "backgroundColor": "#FFFFFFFF",
    "borderColor": "#FFE0E0E0",
    "borderWidth": 1.0,
    "padding": {"top": 16, "right": 16, "bottom": 16, "left": 16},
    "gridStyle": { /* nested object */ },
    "axisStyle": { /* nested object */ },
    "seriesTheme": { /* nested object */ },
    "interactionTheme": { /* nested object */ },
    "typographyTheme": { /* nested object */ },
    "animationTheme": { /* nested object */ }
  }
}
```

---

### 2. GridStyle

**Purpose**: Configures major and minor grid lines.

**Fields**:
```dart
class GridStyle {
  const GridStyle({
    required this.majorColor,
    required this.majorWidth,
    this.majorDashPattern,
    this.minorColor,
    this.minorWidth,
    this.minorDashPattern,
    this.showMinor = false,
  });

  final Color majorColor;
  final double majorWidth;
  final List<double>? majorDashPattern; // null = solid line
  final Color? minorColor; // null = no minor grid
  final double? minorWidth;
  final List<double>? minorDashPattern;
  final bool showMinor;
}
```

**Validation Rules**:
- `majorWidth >= 0.0`
- `minorWidth == null || minorWidth >= 0.0`
- `dashPattern` elements must all be > 0.0 (if provided)
- `dashPattern.length` must be even (on-off pairs)
- If `showMinor == true`, then `minorColor != null && minorWidth != null`

**Dash Pattern Format**:
```dart
// Examples:
null                  // Solid line
[5.0, 5.0]           // 5px on, 5px off (simple dash)
[10.0, 5.0, 2.0, 5.0] // 10px on, 5px off, 2px on, 5px off (dash-dot)
```

**Default Values**:
```dart
static const GridStyle defaultLight = GridStyle(
  majorColor: Color(0xFFE0E0E0),
  majorWidth: 1.0,
  majorDashPattern: null, // Solid
  minorColor: null,        // No minor grid
  minorWidth: null,
  minorDashPattern: null,
  showMinor: false,
);

static const GridStyle defaultDark = GridStyle(
  majorColor: Color(0xFF424242),
  majorWidth: 1.0,
  majorDashPattern: null,
  minorColor: null,
  minorWidth: null,
  minorDashPattern: null,
  showMinor: false,
);
```

---

### 3. AxisStyle

**Purpose**: Configures axis lines, labels, titles, and ticks.

**Fields**:
```dart
class AxisStyle {
  const AxisStyle({
    required this.lineColor,
    required this.lineWidth,
    required this.textStyle,
    required this.titleStyle,
    required this.tickLength,
    required this.tickColor,
    required this.tickWidth,
  });

  final Color lineColor;
  final double lineWidth;
  final TextStyle textStyle;    // For axis labels (numbers)
  final TextStyle titleStyle;   // For axis titles
  final double tickLength;
  final Color tickColor;
  final double tickWidth;
}
```

**Validation Rules**:
- `lineWidth >= 0.0` (0 = no axis line)
- `tickLength >= 0.0` (0 = no ticks)
- `tickWidth >= 0.0`
- `textStyle.fontSize >= 8.0` (minimum readable)
- `titleStyle.fontSize >= 10.0` (minimum readable)

**TextStyle Requirements**:
- Must include `fontSize`, `fontFamily`, `color`
- `fontFamily` should be available on target platform
- Recommended: Use Flutter standard fonts (Roboto, SF Pro)

**Default Values**:
```dart
static const AxisStyle defaultLight = AxisStyle(
  lineColor: Color(0xFF000000),
  lineWidth: 1.0,
  textStyle: TextStyle(
    fontSize: 12.0,
    fontFamily: 'Roboto',
    color: Color(0xFF000000),
  ),
  titleStyle: TextStyle(
    fontSize: 14.0,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    color: Color(0xFF000000),
  ),
  tickLength: 6.0,
  tickColor: Color(0xFF000000),
  tickWidth: 1.0,
);
```

---

### 4. SeriesTheme

**Purpose**: Configures series styling with cycling lists (colors, line widths, markers).

**Fields**:
```dart
class SeriesTheme {
  const SeriesTheme({
    required this.colors,
    required this.lineWidths,
    required this.dashPatterns,
    required this.markerShapes,
    required this.markerSizes,
  });

  final List<Color> colors;               // Min 1
  final List<double> lineWidths;          // Min 1
  final List<List<double>?> dashPatterns; // Min 1
  final List<MarkerShape> markerShapes;   // Min 1
  final List<double> markerSizes;         // Min 1
}
```

**Cycling Behavior**:
```dart
// Series 0: colors[0], lineWidths[0], dashPatterns[0], etc.
// Series 1: colors[1], lineWidths[1], dashPatterns[1], etc.
// Series 7: colors[7 % colors.length], etc. (cycles back to colors[0])

Color colorAt(int seriesIndex) => colors[seriesIndex % colors.length];
double lineWidthAt(int seriesIndex) => lineWidths[seriesIndex % lineWidths.length];
List<double>? dashPatternAt(int seriesIndex) => dashPatterns[seriesIndex % dashPatterns.length];
MarkerShape markerShapeAt(int seriesIndex) => markerShapes[seriesIndex % markerShapes.length];
double markerSizeAt(int seriesIndex) => markerSizes[seriesIndex % markerSizes.length];
```

**Validation Rules**:
- All lists must have length >= 1
- All `lineWidths` elements >= 0.0
- All `markerSizes` elements >= 0.0
- `dashPatterns` elements: null OR valid dash pattern (see GridStyle)
- `colors` must have good visual separation (recommended: ΔE > 40 in CIELAB)

**MarkerShape Enum**:
```dart
enum MarkerShape {
  circle,
  square,
  triangle,
  diamond,
  cross,
  plus,
  star,
  none, // No marker
}
```

**Default Values**:
```dart
static const SeriesTheme defaultLight = SeriesTheme(
  colors: [
    Color(0xFF1976D2), // Blue
    Color(0xFFFF6F00), // Orange
    Color(0xFF388E3C), // Green
    Color(0xFFD32F2F), // Red
    Color(0xFF7B1FA2), // Purple
    Color(0xFFFBC02D), // Yellow
    Color(0xFF0097A7), // Cyan
  ],
  lineWidths: [2.0],
  dashPatterns: [null], // All solid
  markerShapes: [MarkerShape.circle],
  markerSizes: [8.0],
);
```

**Accessibility Note**:
- Default colors tested for WCAG AA against white/dark backgrounds
- Colorblind Friendly theme uses Brettel-tested colors

---

### 5. InteractionTheme

**Purpose**: Configures interactive elements (crosshair, tooltips, selection).

**Fields**:
```dart
class InteractionTheme {
  const InteractionTheme({
    required this.crosshairColor,
    required this.crosshairWidth,
    this.crosshairDashPattern,
    required this.tooltipBackground,
    required this.tooltipTextStyle,
    required this.tooltipBorderColor,
    required this.tooltipBorderWidth,
    required this.selectionColor,
    required this.selectionOpacity,
  });

  final Color crosshairColor;
  final double crosshairWidth;
  final List<double>? crosshairDashPattern;
  final Color tooltipBackground;
  final TextStyle tooltipTextStyle;
  final Color tooltipBorderColor;
  final double tooltipBorderWidth;
  final Color selectionColor;
  final double selectionOpacity; // 0.0 - 1.0
}
```

**Validation Rules**:
- `crosshairWidth >= 0.0` (0 = no crosshair)
- `tooltipBorderWidth >= 0.0` (0 = no border)
- `selectionOpacity >= 0.0 && selectionOpacity <= 1.0`
- `tooltipTextStyle.fontSize >= 10.0` (minimum readable)
- `tooltipBackground` and `tooltipTextStyle.color` must have contrast >= 4.5:1 (WCAG AA)

**Default Values**:
```dart
static const InteractionTheme defaultLight = InteractionTheme(
  crosshairColor: Color(0xFF757575),
  crosshairWidth: 1.0,
  crosshairDashPattern: [5.0, 5.0],
  tooltipBackground: Color(0xFFFFFFFF),
  tooltipTextStyle: TextStyle(
    fontSize: 12.0,
    fontFamily: 'Roboto',
    color: Color(0xFF000000),
  ),
  tooltipBorderColor: Color(0xFF757575),
  tooltipBorderWidth: 1.0,
  selectionColor: Color(0xFF1976D2),
  selectionOpacity: 0.2,
);
```

---

### 6. TypographyTheme

**Purpose**: Configures fonts, sizes, and responsive scaling.

**Fields**:
```dart
class TypographyTheme {
  const TypographyTheme({
    required this.fontFamily,
    required this.baseFontSize,
    required this.titleFontSize,
    required this.labelFontSize,
    required this.fontWeight,
    this.scaleFactor = 1.0, // Computed from viewport
  });

  final String fontFamily;
  final double baseFontSize;   // Default text size
  final double titleFontSize;  // Chart title
  final double labelFontSize;  // Axis labels
  final FontWeight fontWeight;
  final double scaleFactor;    // Responsive multiplier
}
```

**Validation Rules**:
- `baseFontSize >= 8.0` (minimum readable)
- `titleFontSize >= 10.0`
- `labelFontSize >= 8.0`
- `scaleFactor >= 0.5 && scaleFactor <= 2.0` (reasonable range)
- `fontFamily` should be available on target platform (check with `FontLoader`)

**Responsive Scaling**:
```dart
// Applied font size = base * scaleFactor
double effectiveFontSize(double baseSize, double scaleFactor) {
  return max(baseSize * scaleFactor, 8.0); // Never below 8.0
}

// Scale factor computed from viewport:
static double computeScaleFactor(double viewportWidth) {
  if (viewportWidth < 600) return 0.9;   // Mobile
  if (viewportWidth < 1024) return 1.0;  // Tablet
  return 1.1;                             // Desktop
}
```

**Default Values**:
```dart
static const TypographyTheme defaultLight = TypographyTheme(
  fontFamily: 'Roboto',
  baseFontSize: 12.0,
  titleFontSize: 16.0,
  labelFontSize: 11.0,
  fontWeight: FontWeight.normal,
  scaleFactor: 1.0,
);
```

---

### 7. AnimationTheme

**Purpose**: Configures animation durations and curves.

**Fields**:
```dart
class AnimationTheme {
  const AnimationTheme({
    required this.dataUpdateDuration,
    required this.dataUpdateCurve,
    required this.themeSwitchDuration,
    required this.themeSwitchCurve,
  });

  final Duration dataUpdateDuration;
  final Curve dataUpdateCurve;
  final Duration themeSwitchDuration;
  final Curve themeSwitchCurve;
}
```

**Validation Rules**:
- `dataUpdateDuration >= Duration.zero` (0 = no animation)
- `themeSwitchDuration >= Duration.zero`
- Recommended max: `Duration(milliseconds: 500)` (longer feels sluggish)

**Default Values**:
```dart
static const AnimationTheme defaultLight = AnimationTheme(
  dataUpdateDuration: Duration(milliseconds: 300),
  dataUpdateCurve: Curves.easeInOut,
  themeSwitchDuration: Duration(milliseconds: 200),
  themeSwitchCurve: Curves.easeInOut,
);
```

**Curve Options**:
- `Curves.linear` - Constant speed
- `Curves.easeIn` - Slow start
- `Curves.easeOut` - Slow end
- `Curves.easeInOut` - Slow start + end (recommended for smooth feel)
- `Curves.fastOutSlowIn` - Material Design standard

---

### 8. ColorUtils (Utility Entity)

**Purpose**: Provides color accessibility and manipulation utilities.

**Static Methods**:
```dart
class ColorUtils {
  // WCAG 2.1 relative luminance
  static double relativeLuminance(Color color);
  
  // WCAG 2.1 contrast ratio (1.0 - 21.0)
  static double contrastRatio(Color c1, Color c2);
  
  // Auto-select text color (black or white) for best contrast
  static Color autoContrastText(Color background);
  
  // Colorblind simulation (Brettel algorithm)
  static Color simulateProtanopia(Color color);
  static Color simulateDeuteranopia(Color color);
  static Color simulateTritanopia(Color color);
  
  // Grayscale conversion
  static Color toGrayscale(Color color);
  
  // Color distance (ΔE in CIELAB)
  static double colorDistance(Color c1, Color c2);
}
```

**WCAG Compliance Checks**:
```dart
bool isWCAG_AA(Color text, Color background) {
  return contrastRatio(text, background) >= 4.5;
}

bool isWCAG_AAA(Color text, Color background) {
  return contrastRatio(text, background) >= 7.0;
}

bool isWCAG_AA_Large(Color text, Color background) {
  return contrastRatio(text, background) >= 3.0; // 18pt+ text
}
```

---

### 9. StyleCache (Performance Entity)

**Purpose**: LRU cache for resolved styles, prevents redundant cascade resolution.

**Structure**:
```dart
class StyleCache {
  StyleCache({this.maxSize = 1000});
  
  final int maxSize;
  final _cache = LinkedHashMap<StyleCacheKey, dynamic>();
  int _hits = 0;
  int _misses = 0;
  
  T? get<T>(StyleCacheKey key);
  void put<T>(StyleCacheKey key, T value);
  void clear();
  
  double get hitRate => _hits / (_hits + _misses);
  int get size => _cache.length;
}

class StyleCacheKey {
  const StyleCacheKey(this.themeHash, this.elementType, [this.overridesHash]);
  
  final int themeHash;
  final String elementType; // 'grid', 'axis', 'series', etc.
  final int? overridesHash;
  
  @override
  int get hashCode => Object.hash(themeHash, elementType, overridesHash);
  
  @override
  bool operator ==(Object other) => /* ... */;
}
```

**Cache Metrics**:
- Hit rate target: >95% during normal rendering
- Max size: 1000 entries (~100KB memory)
- Eviction policy: LRU (Least Recently Used)
- Invalidation: Full clear on theme change

---

## State Transitions

### Theme Lifecycle

```
[Unthemed]
    ↓ applyTheme(theme)
[Themed]
    ↓ updateTheme(newTheme)
[Theme Switching]
    ↓ diffComplete + cacheCleared
[Themed] (with new theme)
    ↓ removeTheme()
[Unthemed]
```

**State Descriptions**:
1. **Unthemed**: No theme applied, uses system defaults
2. **Themed**: Active theme, styles resolved via cascade
3. **Theme Switching**: Diff in progress, cache being invalidated
4. **Themed** (new): New theme active, cache warming up

**Invariants**:
- Cache always empty in Unthemed state
- Cache always cleared during Theme Switching
- Only one theme active at a time (no multi-theme support)

---

## Data Validation

### Construction-Time Validation
```dart
// All themes validate on construction
ChartTheme({required Color backgroundColor, ...}) {
  ArgumentError.checkNotNull(backgroundColor, 'backgroundColor');
  // ... validate all fields
}

// Builder validates on build()
ChartThemeBuilder.build() {
  _validate();
  return ChartTheme(...);
}

void _validate() {
  if (_borderWidth != null && _borderWidth! < 0) {
    throw ArgumentError('borderWidth must be >= 0');
  }
  // ... all validations
}
```

### Runtime Validation
```dart
// Style cascade validates resolved styles
Color resolveColor(/* ... */) {
  final color = /* cascade resolution */;
  assert(color != null, 'Resolved color cannot be null');
  assert(color.alpha >= 0, 'Resolved color must have valid alpha');
  return color;
}
```

---

## Serialization Format

### JSON Schema v1.0
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "theme"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$"
    },
    "theme": {
      "type": "object",
      "required": [
        "backgroundColor",
        "borderColor",
        "borderWidth",
        "padding",
        "gridStyle",
        "axisStyle",
        "seriesTheme",
        "interactionTheme",
        "typographyTheme",
        "animationTheme"
      ],
      "properties": {
        "backgroundColor": {"type": "string", "pattern": "^#[0-9A-F]{8}$"},
        "borderColor": {"type": "string", "pattern": "^#[0-9A-F]{8}$"},
        "borderWidth": {"type": "number", "minimum": 0},
        "padding": {
          "type": "object",
          "required": ["top", "right", "bottom", "left"],
          "properties": {
            "top": {"type": "number"},
            "right": {"type": "number"},
            "bottom": {"type": "number"},
            "left": {"type": "number"}
          }
        },
        "gridStyle": { /* nested schema */ },
        "axisStyle": { /* nested schema */ },
        "seriesTheme": { /* nested schema */ },
        "interactionTheme": { /* nested schema */ },
        "typographyTheme": { /* nested schema */ },
        "animationTheme": { /* nested schema */ }
      }
    }
  }
}
```

### Example Serialized Theme
```json
{
  "version": "1.0",
  "theme": {
    "backgroundColor": "#FFFFFFFF",
    "borderColor": "#FFE0E0E0",
    "borderWidth": 1.0,
    "padding": {"top": 16, "right": 16, "bottom": 16, "left": 16},
    "gridStyle": {
      "majorColor": "#FFE0E0E0",
      "majorWidth": 1.0,
      "majorDashPattern": null,
      "minorColor": null,
      "minorWidth": null,
      "minorDashPattern": null,
      "showMinor": false
    },
    "axisStyle": {
      "lineColor": "#FF000000",
      "lineWidth": 1.0,
      "textStyle": {
        "fontSize": 12.0,
        "fontFamily": "Roboto",
        "color": "#FF000000"
      },
      "titleStyle": {
        "fontSize": 14.0,
        "fontFamily": "Roboto",
        "fontWeight": "w500",
        "color": "#FF000000"
      },
      "tickLength": 6.0,
      "tickColor": "#FF000000",
      "tickWidth": 1.0
    },
    "seriesTheme": {
      "colors": [
        "#FF1976D2",
        "#FFFF6F00",
        "#FF388E3C",
        "#FFD32F2F",
        "#FF7B1FA2",
        "#FFFBC02D",
        "#FF0097A7"
      ],
      "lineWidths": [2.0],
      "dashPatterns": [null],
      "markerShapes": ["circle"],
      "markerSizes": [8.0]
    },
    "interactionTheme": {
      "crosshairColor": "#FF757575",
      "crosshairWidth": 1.0,
      "crosshairDashPattern": [5.0, 5.0],
      "tooltipBackground": "#FFFFFFFF",
      "tooltipTextStyle": {
        "fontSize": 12.0,
        "fontFamily": "Roboto",
        "color": "#FF000000"
      },
      "tooltipBorderColor": "#FF757575",
      "tooltipBorderWidth": 1.0,
      "selectionColor": "#FF1976D2",
      "selectionOpacity": 0.2
    },
    "typographyTheme": {
      "fontFamily": "Roboto",
      "baseFontSize": 12.0,
      "titleFontSize": 16.0,
      "labelFontSize": 11.0,
      "fontWeight": "normal",
      "scaleFactor": 1.0
    },
    "animationTheme": {
      "dataUpdateDuration": 300,
      "dataUpdateCurve": "easeInOut",
      "themeSwitchDuration": 200,
      "themeSwitchCurve": "easeInOut"
    }
  }
}
```

---

## Performance Considerations

### Memory Footprint
- **ChartTheme instance**: ~2KB (all fields)
- **StyleCache (1000 entries)**: ~100KB
- **7 predefined themes**: ~14KB (loaded lazily)
- **Total typical usage**: <120KB

### Allocation Strategy
- Theme objects: Immutable, can be const (zero allocation)
- Cache entries: Allocated on-demand, LRU eviction
- Serialization: Uses `dart:convert` (pooled buffers)

### Performance Targets
- Theme construction: <1ms
- copyWith(): <0.5ms
- JSON serialization: <10ms
- JSON deserialization: <20ms
- Style cascade resolution (cached): <0.1ms
- Style cascade resolution (uncached): <1ms
- Cache hit rate: >95%

---

## Testing Strategy

### Unit Tests (Per Entity)
- Construction with valid values
- Construction with invalid values (should throw)
- `copyWith()` preserves unchanged fields
- `==` operator and `hashCode` correctness
- JSON serialization round-trip
- Default values satisfy validation rules

### Integration Tests
- Theme application to chart
- Theme switching preserves state (zoom, pan)
- Style cascade resolution correctness
- Cache hit rate meets target (>95%)
- Responsive typography scaling

### Accessibility Tests
- All theme text/background pairs meet WCAG AA
- High Contrast theme meets WCAG AAA
- Colorblind simulation: series distinguishable
- Grayscale conversion: series separable

### Performance Tests
- Theme switching < 100ms
- Style resolution < 1ms (uncached)
- Cache hit rate > 95% during rendering
- Memory usage < 120KB

---

## Open Questions

- [ ] Should we support theme interpolation (crossfade between themes)?
- [ ] Should we support per-series theme overrides (not just chart-level)?
- [ ] Should we add theme validation mode (strict vs. permissive)?
- [ ] Should we support custom marker shapes (user-provided path)?

---

**Data Model Complete**: 2025-10-06  
**Next Steps**: Create contracts/ directory with 8 interface files
