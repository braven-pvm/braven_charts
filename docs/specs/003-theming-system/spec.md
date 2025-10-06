# Feature Specification: Theming System

**Feature Branch**: `004-theming-system`  
**Layer**: 3 (Theming System)  
**Created**: 2025-10-06  
**Status**: Draft  
**Dependencies**: 001-foundation (Foundation Layer), 002-core-rendering (Rendering Engine), 003-coordinate-system (Coordinate Transformations)

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT the theming system must do and WHY
- ✅ Theming = Complete visual control through comprehensive styling
- ✅ Depends on Foundation, Rendering, and Coordinates (no chart types yet)
- ✅ Provides styling infrastructure for ALL visual elements

---

## Executive Summary

The Theming System provides comprehensive visual control over all chart components through a layered, cascading style architecture. It includes 7 professionally designed themes and full customization capabilities, ensuring consistent visual design across all chart elements while maintaining performance and accessibility standards.

**Why This Layer Exists**: Charts need consistent, professional visual design. The theming system provides centralized style management so that chart developers can apply cohesive styling without manually configuring every visual property. Users can switch between professional themes or create custom appearances that match their brand.

**What Makes It Special**:
- 7 professionally designed themes (Light, Dark, Corporate, Vibrant, Minimal, High Contrast, Colorblind Friendly)
- CSS-like cascading style resolution
- Theme switching without chart recreation (performance-neutral)
- WCAG 2.1 AA accessibility compliance
- Zero performance overhead (styles pre-computed and cached)

---

## User Scenarios & Testing

### Primary User Story

**As a chart developer**, I need comprehensive theming capabilities so that I can apply consistent, professional styling to all chart components with minimal configuration and maintain brand consistency across my application.

### Acceptance Scenarios

#### Scenario 1: Applying Predefined Theme
```dart
// Given: A chart instance with default theme
final chart = LineChart(
  data: myData,
  theme: ChartTheme.defaultLight, // Default
);

// When: User switches to dark theme
chart.updateTheme(ChartTheme.defaultDark);

// Then:
// - All chart elements immediately use dark theme colors
// - No chart recreation (state preserved)
// - Text remains readable (contrast checked)
// - Transition is smooth (no flicker)
// - Performance unchanged (<16ms frame time)
```

**Acceptance Criteria**:
- ✅ Theme switch completes in <100ms
- ✅ All visual elements update (grid, axes, series, tooltips, annotations)
- ✅ Chart state preserved (zoom level, selection, viewport)
- ✅ Text contrast meets WCAG 2.1 AA (4.5:1 for normal text)
- ✅ No memory leaks (old theme resources released)

#### Scenario 2: Custom Theme Creation
```dart
// Given: Need for brand-specific chart styling
final brandTheme = ChartThemeBuilder()
  .backgroundColor(Color(0xFFF5F5F5))
  .seriesColors([
    Color(0xFF1976D2), // Brand primary
    Color(0xFFFF6F00), // Brand accent
    Color(0xFF388E3C), // Brand success
  ])
  .gridStyle(GridStyle(
    color: Colors.grey[300]!,
    width: 0.5,
    dashPattern: [2.0, 2.0],
  ))
  .typography(TypographyTheme(
    fontFamily: 'Roboto',
    axisLabelStyle: TextStyle(fontSize: 12),
    axisTitleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  ))
  .build();

// When: Applying custom theme
final chart = LineChart(data: myData, theme: brandTheme);

// Then:
// - All specified properties applied correctly
// - Unspecified properties use sensible defaults
// - Theme validation passes (no invalid colors, sizes)
// - Visual consistency maintained across all elements
```

**Acceptance Criteria**:
- ✅ Builder API is fluent and discoverable
- ✅ Validation catches invalid configurations (e.g., negative widths)
- ✅ Defaults fill in unspecified properties
- ✅ Theme serializable to/from JSON for persistence
- ✅ Documentation includes complete example

#### Scenario 3: Accessibility-First Theming
```dart
// Given: User with protanopia (red-green color blindness)
final chart = LineChart(
  data: multiSeriesData,
  theme: ChartTheme.colorblindFriendly,
);

// When: Rendering 5 data series
chart.render();

// Then:
// - Each series has distinct, safe color
// - Line patterns used in addition to colors (solid, dashed, dotted)
// - Point markers have different shapes (circle, square, triangle)
// - Text contrast exceeds WCAG AAA (7:1)
// - Tooltip text includes series name (not just color)
```

**Acceptance Criteria**:
- ✅ All colorblind-safe palettes validated with simulation tools
- ✅ Redundant encoding (color + pattern + shape)
- ✅ Text contrast ratio ≥7:1 for all text elements
- ✅ Series distinguishable in grayscale
- ✅ High contrast theme available for low vision users

#### Scenario 4: Responsive Theme Adaptation
```dart
// Given: Chart rendered at different viewport sizes
final chart = BarChart(data: salesData, theme: ChartTheme.defaultLight);

// When: Viewport changes from desktop (1200px) to mobile (375px)
chart.resize(Size(375, 600));

// Then:
// - Font sizes scale appropriately (12px → 10px)
// - Padding reduces to fit content (16px → 8px)
// - Grid density decreases (fewer grid lines on mobile)
// - Touch targets remain ≥44×44 points (iOS HIG)
// - Text remains readable (no clipping or overlap)
```

**Acceptance Criteria**:
- ✅ Breakpoints defined for mobile (0-599px), tablet (600-1023px), desktop (1024px+)
- ✅ Typography scales smoothly (no sudden jumps)
- ✅ Touch targets meet platform guidelines (44×44 iOS, 48×48 Android)
- ✅ Layout adapts without content loss
- ✅ Responsive behavior configurable (can be disabled)

#### Scenario 5: Theme Inheritance and Overrides
```dart
// Given: Base theme with specific series override
final baseTheme = ChartTheme.corporateBlue;

final customizedChart = LineChart(
  data: multiSeriesData,
  theme: baseTheme,
  seriesOverrides: {
    'revenue': SeriesStyle(
      color: Colors.green,
      lineWidth: 3.0,
      dashPattern: null, // Solid line
    ),
    'expenses': SeriesStyle(
      color: Colors.red,
      lineWidth: 2.0,
      dashPattern: [4.0, 2.0], // Dashed
    ),
  },
);

// When: Rendering with overrides
customizedChart.render();

// Then:
// - 'revenue' series uses green with 3px solid line
// - 'expenses' series uses red with 2px dashed line
// - All other series use baseTheme colors
// - Grid, axes, tooltips still use baseTheme styling
// - No theme duplication (efficient memory use)
```

**Acceptance Criteria**:
- ✅ Series-level overrides don't affect global theme
- ✅ Override cascade: series > chart > theme > defaults
- ✅ Partial overrides supported (only override specific properties)
- ✅ Type-safe override API (compile-time validation)
- ✅ Override changes trigger minimal redraws (only affected series)

### Edge Cases

- What happens when theme has invalid color values (null, negative opacity)?
- How does system handle missing font families (fallback fonts)?
- Are theme changes during active animations handled gracefully?
- How does theming work with zero-size charts (width or height = 0)?
- Can themes be hot-reloaded during development without state loss?
- What happens when serialized theme JSON has unknown properties?
- How are themes validated before application?
- Can themes be applied incrementally (partial theme updates)?

---

## Requirements

### Functional Requirements

#### Theme Structure (FR-001)

System MUST provide comprehensive theme definition:

- **FR-001.1**: ChartTheme MUST define all visual properties
  - Background color and border styling
  - Canvas padding, margin, shadows
  - Grid style (colors, widths, patterns)
  - Axis style (lines, labels, titles, ticks)
  - Series theme (colors, line styles, markers)
  - Interaction theme (crosshair, tooltip, selection)
  - Typography theme (fonts, sizes, weights)
  - Animation theme (durations, curves)
  - **Validation**: All properties have valid defaults, no nulls for required fields

- **FR-001.2**: Theme components MUST be immutable
  - All fields final
  - `copyWith()` methods for modifications
  - Deep equality comparison
  - Hash code implementation
  - **Validation**: Theme instances never mutate after creation

- **FR-001.3**: Theme MUST support serialization
  - JSON export: `theme.toJson()` → Map<String, dynamic>
  - JSON import: `ChartTheme.fromJson(json)` → ChartTheme
  - Versioned schema (forward/backward compatibility)
  - Missing properties use defaults
  - **Validation**: Round-trip serialization preserves all properties

#### Predefined Themes (FR-002)

System MUST provide 7 professionally designed themes:

- **FR-002.1**: Default Light Theme
  - Clean, professional appearance
  - High contrast for readability
  - Business-appropriate color palette
  - Suitable for presentations and reports
  - **Validation**: WCAG 2.1 AA compliance (4.5:1 contrast)

- **FR-002.2**: Default Dark Theme
  - Modern dark appearance
  - Reduced eye strain in low light
  - Material Design 3 dark theme guidelines
  - Lighter colors on dark background
  - **Validation**: WCAG 2.1 AA compliance for dark mode

- **FR-002.3**: Corporate Blue Theme
  - Professional corporate styling
  - Blue color palette (primary brand color)
  - Conservative, trustworthy appearance
  - Suitable for financial/business applications
  - **Validation**: All blues distinguishable (5+ shades)

- **FR-002.4**: Vibrant Theme
  - High-energy, bold colors
  - Suitable for dashboards and marketing
  - Bright, saturated palette
  - Eye-catching visual impact
  - **Validation**: Colors remain distinguishable when saturated

- **FR-002.5**: Minimal Theme
  - Clean, uncluttered design
  - Subtle grays and blacks
  - Focus on data, not decoration
  - Suitable for technical/scientific charts
  - **Validation**: Minimal visual noise while maintaining clarity

- **FR-002.6**: High Contrast Theme
  - Maximum readability
  - Black and white with limited accent colors
  - Suitable for accessibility and printing
  - Clear visual hierarchy
  - **Validation**: WCAG 2.1 AAA compliance (7:1 contrast)

- **FR-002.7**: Colorblind Friendly Theme
  - Safe for all colorblindness types (protanopia, deuteranopia, tritanopia)
  - Redundant encoding (color + pattern + shape)
  - Validated with colorblind simulation tools
  - Distinguishable in grayscale
  - **Validation**: All series distinguishable with deuteranopia simulation

#### Theme Customization (FR-003)

System MUST provide fluent builder API for custom themes:

- **FR-003.1**: ChartThemeBuilder MUST support incremental theme construction
  - Fluent API (method chaining)
  - Start from base theme (defaults or predefined)
  - Override specific properties only
  - Type-safe property setters
  - **Validation**: Builder validates constraints (e.g., positive widths)

- **FR-003.2**: Theme builder MUST support advanced customization
  - Callback-based customization (e.g., `customizeAxis((axis) => ...)`)
  - Conditional styling (e.g., different styles per series)
  - Computed properties (e.g., auto-contrast text color)
  - Preview mode (visualize before applying)
  - **Validation**: Custom themes validated before `build()`

- **FR-003.3**: Theme MUST support partial updates
  - Update single property without full theme replacement
  - Minimal re-rendering (only affected components)
  - Efficient diffing (compare old/new theme)
  - Transactional updates (all-or-nothing application)
  - **Validation**: Partial updates maintain theme consistency

#### Style Cascade (FR-004)

System MUST implement CSS-like cascading style resolution:

- **FR-004.1**: Style resolution order MUST be predictable
  - Element-specific override (highest priority)
  - Chart-level override
  - Theme-level default
  - System default (lowest priority)
  - **Validation**: Style precedence documented and tested

- **FR-004.2**: Style inheritance MUST propagate efficiently
  - Child elements inherit parent styles
  - Explicit overrides break inheritance
  - Inheritance cached (no repeated lookups)
  - Changes propagate to descendants
  - **Validation**: Inheritance tree traversal <1ms for 100 elements

- **FR-004.3**: Style caching MUST eliminate redundant computations
  - Resolved styles cached per element
  - Cache invalidated on theme change
  - Cache keyed by (theme, element type, overrides)
  - LRU eviction for memory management
  - **Validation**: Cache hit rate >95% during normal rendering

#### Typography System (FR-005)

System MUST provide comprehensive text styling:

- **FR-005.1**: TypographyTheme MUST define all text styles
  - Font family (with fallbacks)
  - Font size (responsive scaling)
  - Font weight (light, normal, medium, bold, etc.)
  - Font style (normal, italic)
  - Letter spacing and line height
  - Text color and opacity
  - **Validation**: All text elements have defined styles

- **FR-005.2**: Typography MUST support responsive scaling
  - Breakpoints: mobile, tablet, desktop
  - Scale factors per breakpoint (e.g., 0.9x mobile, 1.0x desktop)
  - Smooth interpolation between breakpoints
  - Minimum readable sizes enforced (≥10px)
  - **Validation**: Text readable at all viewport sizes

- **FR-005.3**: Font loading MUST be handled gracefully
  - Fallback fonts if custom font unavailable
  - No layout shift during font load (size reservation)
  - Web font loading optimization (font-display: swap)
  - Font load timeout (3 seconds, then fallback)
  - **Validation**: Charts render immediately with fallback fonts

#### Color System (FR-006)

System MUST provide sophisticated color management:

- **FR-006.1**: SeriesTheme MUST define color palettes
  - Minimum 7 distinct colors per theme
  - Automatic cycling for >7 series (modulo)
  - Color interpolation for gradients
  - Opacity support (alpha channel)
  - **Validation**: All palette colors distinguishable (ΔE >20)

- **FR-006.2**: Color utilities MUST provide accessibility helpers
  - Contrast ratio calculation (WCAG 2.1)
  - Auto-contrast text (white on dark, black on light)
  - Colorblind simulation (8 types)
  - Grayscale conversion
  - **Validation**: Contrast calculations match WCAG algorithms

- **FR-006.3**: Color MUST support multiple formats
  - Hex: #RRGGBB, #AARRGGBB
  - RGB: rgb(r, g, b), rgba(r, g, b, a)
  - HSL: hsl(h, s, l), hsla(h, s, l, a)
  - Named colors (Material Design palette)
  - **Validation**: All formats parse correctly and round-trip

#### Interaction Theming (FR-007)

System MUST style interactive elements:

- **FR-007.1**: CrosshairStyle MUST define crosshair appearance
  - Line color, width, dash pattern
  - Label background, text color, border
  - Snap behavior (to nearest point, grid line)
  - Visibility conditions (hover, tap, always)
  - **Validation**: Crosshair visible against all backgrounds

- **FR-007.2**: TooltipStyle MUST define tooltip appearance
  - Background color and opacity
  - Border color, width, radius
  - Text color, font, size
  - Arrow/pointer styling
  - Shadow and elevation
  - **Validation**: Tooltips readable with all themes

- **FR-007.3**: SelectionStyle MUST define selection appearance
  - Selected state color/opacity
  - Hover state color/opacity
  - Active/pressed state color/opacity
  - Focus indicator (keyboard navigation)
  - **Validation**: All states visually distinct

#### Grid and Axis Theming (FR-008)

System MUST style chart infrastructure:

- **FR-008.1**: GridStyle MUST define grid appearance
  - Major grid color, width, dash pattern
  - Minor grid color, width, dash pattern
  - Grid visibility toggles (major, minor, both, none)
  - Opacity control
  - **Validation**: Grid visible but not distracting (opacity <0.3)

- **FR-008.2**: AxisStyle MUST define axis appearance
  - Axis line color, width, dash pattern
  - Tick mark style (length, width, color)
  - Label style (font, color, rotation, offset)
  - Title style (font, color, background, padding)
  - **Validation**: Axis labels don't overlap (collision detection)

- **FR-008.3**: Axis MUST support flexible positioning
  - Left, right, top, bottom placement
  - Offset from chart area (margin)
  - Inside vs outside placement
  - Label alignment (start, center, end)
  - **Validation**: Axis rendering respects chart bounds

#### Animation Theming (FR-009)

System MUST provide animation configuration:

- **FR-009.1**: AnimationTheme MUST define animation behavior
  - Duration per animation type (enter, exit, update, theme change)
  - Easing curves (linear, ease-in, ease-out, ease-in-out, custom)
  - Stagger delays for multi-element animations
  - Enable/disable flag (accessibility preference)
  - **Validation**: Animations respect system motion preferences

- **FR-009.2**: Theme changes MUST support animation
  - Smooth color transitions (interpolate RGB)
  - Size/position transitions (spring physics)
  - Opacity fades (in/out)
  - Configurable duration (default 300ms)
  - **Validation**: Theme transitions smooth (no jarring changes)

- **FR-009.3**: Animation MUST be performance-neutral
  - 60 FPS maintained during animations
  - Animations cancelled if frame budget exceeded
  - No allocations during animation (pre-computed paths)
  - Requestable frame callback optimization
  - **Validation**: Frame time <16ms during all animations

### Non-Functional Requirements

#### Performance (NFR-001)

- **NFR-001.1**: Theme application MUST be performance-neutral
  - Theme switch <100ms for complex charts
  - No chart recreation required
  - Minimal re-rendering (diff-based updates)
  - **Measurement**: Benchmark theme switching on 10k point chart

- **NFR-001.2**: Style resolution MUST be efficient
  - Resolved styles cached per element
  - Cache hit rate >95%
  - Style lookup <0.1ms per element
  - **Measurement**: Profile style resolution in rendering pipeline

- **NFR-001.3**: Memory footprint MUST be minimal
  - Single theme instance per chart (shared, not copied)
  - Style cache bounded (LRU eviction)
  - No memory leaks on theme changes
  - **Measurement**: Memory profiler shows stable heap after 100 theme switches

#### Accessibility (NFR-002)

- **NFR-002.1**: All themes MUST meet WCAG 2.1 AA standards
  - Text contrast ratio ≥4.5:1 (normal text)
  - Text contrast ratio ≥3:1 (large text >18pt)
  - Interactive elements ≥44×44 points (touch targets)
  - **Measurement**: Automated contrast checking in theme builder

- **NFR-002.2**: High Contrast theme MUST meet WCAG 2.1 AAA
  - Text contrast ratio ≥7:1 (all text)
  - No color-only information (redundant encoding)
  - Clear visual hierarchy (size, weight, spacing)
  - **Measurement**: AAA validation with automated tools

- **NFR-002.3**: Colorblind Friendly theme MUST be validated
  - Protanopia simulation (red-blind)
  - Deuteranopia simulation (green-blind)
  - Tritanopia simulation (blue-blind)
  - Grayscale distinguishability
  - **Measurement**: Simulation tools + user testing

#### Developer Experience (NFR-003)

- **NFR-003.1**: Theme API MUST be intuitive and discoverable
  - Fluent builder pattern (method chaining)
  - Auto-complete friendly (well-named properties)
  - Comprehensive dartdoc with examples
  - Type-safe (no stringly-typed properties)
  - **Measurement**: Developer survey (time to first custom theme)

- **NFR-003.2**: Theme debugging MUST be simple
  - Theme inspector widget (shows applied styles)
  - Validation errors include fix suggestions
  - Hot reload support (no chart recreation)
  - Visual diff tool (compare two themes)
  - **Measurement**: Debugging task completion time

- **NFR-003.3**: Documentation MUST be comprehensive
  - All 7 predefined themes documented with screenshots
  - Custom theme tutorial with step-by-step guide
  - Accessibility best practices guide
  - Migration guide from other chart libraries
  - **Measurement**: Documentation completeness checklist

#### Compatibility (NFR-004)

- **NFR-004.1**: Themes MUST be platform-agnostic
  - Work identically on Web, iOS, Android, desktop
  - No platform-specific code in theme layer
  - Platform conventions respected (e.g., touch targets)
  - **Measurement**: Visual regression tests across platforms

- **NFR-004.2**: Theme serialization MUST be forward-compatible
  - Unknown JSON properties ignored (no errors)
  - Schema versioning (v1, v2, etc.)
  - Automatic migration from older schemas
  - **Measurement**: Load themes from 3 schema versions back

- **NFR-004.3**: Font rendering MUST be consistent
  - Same font metrics across platforms
  - Fallback fonts specified per platform
  - No layout shift between platforms
  - **Measurement**: Screenshot diff <1% across platforms

---

## Dependencies

### Layer 0: Foundation (001-foundation)
**Required Components**:
- DataRange (for responsive scaling thresholds)
- ValidationResult (for theme validation)
- ChartError (for theme errors)

**Why**: Theming uses foundation validation for checking theme consistency and reporting errors.

### Layer 1: Core Rendering (002-core-rendering)
**Required Components**:
- Paint/Path object pools (themed colors applied to pooled objects)
- TextLayoutCache (themed text styles cached)
- RenderLayer (themes applied per layer)

**Why**: Theming applies visual properties to rendering primitives. Must not break object pooling performance.

### Layer 2: Coordinate System (003-coordinate-system)
**Required Components**:
- ViewportState (responsive theming based on viewport size)
- TransformContext (theme-aware layout calculations)

**Why**: Responsive theming adapts to viewport dimensions. Grid density and font sizes scale with zoom level.

**No Dependencies On**:
- Chart types (theming is independent of line/bar/scatter)
- Interaction system (interaction theme is defined, but no interactive code yet)
- Annotations (annotation styles defined in theme, but no annotation rendering)

---

## Technical Design

### Theme Architecture

```dart
/// Top-level theme container
@immutable
class ChartTheme {
  const ChartTheme({
    required this.backgroundColor,
    required this.canvasBorderColor,
    this.canvasBorderWidth = 1.0,
    this.canvasBorderRadius = 0.0,
    this.canvasShadows,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    required this.gridStyle,
    required this.axisStyle,
    required this.seriesTheme,
    required this.interactionTheme,
    required this.typography,
    required this.animation,
  });

  // Canvas properties
  final Color backgroundColor;
  final Color canvasBorderColor;
  final double canvasBorderWidth;
  final double canvasBorderRadius;
  final List<BoxShadow>? canvasShadows;
  final EdgeInsets padding;
  final EdgeInsets margin;

  // Component themes
  final GridStyle gridStyle;
  final AxisStyle axisStyle;
  final SeriesTheme seriesTheme;
  final InteractionTheme interactionTheme;
  final TypographyTheme typography;
  final AnimationTheme animation;

  // Predefined themes
  static ChartTheme get defaultLight => _defaultLight;
  static ChartTheme get defaultDark => _defaultDark;
  static ChartTheme get corporateBlue => _corporateBlue;
  static ChartTheme get vibrant => _vibrant;
  static ChartTheme get minimal => _minimal;
  static ChartTheme get highContrast => _highContrast;
  static ChartTheme get colorblindFriendly => _colorblindFriendly;

  // Serialization
  Map<String, dynamic> toJson();
  factory ChartTheme.fromJson(Map<String, dynamic> json);

  // Immutable updates
  ChartTheme copyWith({...});
  
  // Validation
  ValidationResult validate();
}
```

### Component Themes

```dart
/// Grid styling
@immutable
class GridStyle {
  const GridStyle({
    required this.color,
    this.width = 0.5,
    this.dashPattern,
    this.opacity = 1.0,
    this.showMajorGrid = true,
    this.showMinorGrid = false,
    this.minorGridColor,
    this.minorGridWidth = 0.25,
  });

  final Color color;              // Major grid color
  final double width;             // Major grid line width
  final List<double>? dashPattern; // Dash pattern (null = solid)
  final double opacity;           // Grid transparency
  final bool showMajorGrid;       // Show major grid lines
  final bool showMinorGrid;       // Show minor grid lines
  final Color? minorGridColor;    // Minor grid color (defaults to color)
  final double minorGridWidth;    // Minor grid line width

  GridStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory GridStyle.fromJson(Map<String, dynamic> json);
}

/// Axis styling
@immutable
class AxisStyle {
  const AxisStyle({
    required this.lineColor,
    this.lineWidth = 1.0,
    this.dashPattern,
    required this.labelTextStyle,
    required this.titleStyle,
    required this.tickStyle,
  });

  final Color lineColor;
  final double lineWidth;
  final List<double>? dashPattern;
  final TextStyle labelTextStyle;
  final AxisTitleStyle titleStyle;
  final TickStyle tickStyle;

  AxisStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory AxisStyle.fromJson(Map<String, dynamic> json);
}

/// Axis title styling
@immutable
class AxisTitleStyle {
  const AxisTitleStyle({
    required this.textStyle,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 0.0,
    this.opacity = 1.0,
    this.offset = Offset.zero,
    this.border,
  });

  final TextStyle textStyle;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double borderRadius;
  final double opacity;
  final Offset offset;
  final Border? border;

  AxisTitleStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory AxisTitleStyle.fromJson(Map<String, dynamic> json);
}

/// Tick mark styling
@immutable
class TickStyle {
  const TickStyle({
    required this.color,
    this.length = 6.0,
    this.width = 1.0,
    this.showMajorTicks = true,
    this.showMinorTicks = false,
    this.minorTickLength = 3.0,
  });

  final Color color;
  final double length;           // Major tick length
  final double width;            // Tick width
  final bool showMajorTicks;     // Show major ticks
  final bool showMinorTicks;     // Show minor ticks
  final double minorTickLength;  // Minor tick length

  TickStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory TickStyle.fromJson(Map<String, dynamic> json);
}

/// Series styling
@immutable
class SeriesTheme {
  const SeriesTheme({
    required this.colors,
    this.lineWidth = 2.0,
    this.linePatterns,
    this.pointSize = 4.0,
    this.pointShapes,
    this.areaOpacity = 0.3,
  });

  final List<Color> colors;                  // Palette (cycles if >7 series)
  final double lineWidth;                    // Default line width
  final List<List<double>>? linePatterns;    // Dash patterns per series
  final double pointSize;                    // Default point size
  final List<MarkerShape>? pointShapes;      // Point shapes per series
  final double areaOpacity;                  // Area chart fill opacity

  /// Get color for series at index (cycles through palette)
  Color colorForSeries(int index) => colors[index % colors.length];

  /// Get line pattern for series (if defined)
  List<double>? linePatternForSeries(int index) {
    if (linePatterns == null) return null;
    return linePatterns![index % linePatterns!.length];
  }

  /// Get marker shape for series (if defined)
  MarkerShape? shapeForSeries(int index) {
    if (pointShapes == null) return null;
    return pointShapes![index % pointShapes!.length];
  }

  SeriesTheme copyWith({...});
  Map<String, dynamic> toJson();
  factory SeriesTheme.fromJson(Map<String, dynamic> json);
}

/// Marker shapes for series points
enum MarkerShape {
  circle,
  square,
  triangle,
  diamond,
  cross,
  plus,
  star,
}

/// Interaction element styling
@immutable
class InteractionTheme {
  const InteractionTheme({
    required this.crosshairStyle,
    required this.tooltipStyle,
    required this.selectionStyle,
  });

  final CrosshairStyle crosshairStyle;
  final TooltipStyle tooltipStyle;
  final SelectionStyle selectionStyle;

  InteractionTheme copyWith({...});
  Map<String, dynamic> toJson();
  factory InteractionTheme.fromJson(Map<String, dynamic> json);
}

/// Crosshair styling
@immutable
class CrosshairStyle {
  const CrosshairStyle({
    required this.lineColor,
    this.lineWidth = 1.0,
    this.dashPattern,
    this.opacity = 0.8,
    this.labelBackgroundColor,
    this.labelTextColor,
    this.labelBorderRadius = 4.0,
  });

  final Color lineColor;
  final double lineWidth;
  final List<double>? dashPattern;
  final double opacity;
  final Color? labelBackgroundColor;
  final Color? labelTextColor;
  final double labelBorderRadius;

  CrosshairStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory CrosshairStyle.fromJson(Map<String, dynamic> json);
}

/// Tooltip styling
@immutable
class TooltipStyle {
  const TooltipStyle({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.padding = const EdgeInsets.all(8),
    this.shadow,
    this.textStyle,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final BoxShadow? shadow;
  final TextStyle? textStyle;

  TooltipStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory TooltipStyle.fromJson(Map<String, dynamic> json);
}

/// Selection state styling
@immutable
class SelectionStyle {
  const SelectionStyle({
    required this.selectedColor,
    required this.hoverColor,
    this.activeColor,
    this.focusColor,
    this.selectedOpacity = 1.0,
    this.hoverOpacity = 0.8,
    this.activeOpacity = 0.6,
    this.focusOpacity = 0.4,
  });

  final Color selectedColor;
  final Color hoverColor;
  final Color? activeColor;
  final Color? focusColor;
  final double selectedOpacity;
  final double hoverOpacity;
  final double activeOpacity;
  final double focusOpacity;

  SelectionStyle copyWith({...});
  Map<String, dynamic> toJson();
  factory SelectionStyle.fromJson(Map<String, dynamic> json);
}

/// Typography styling
@immutable
class TypographyTheme {
  const TypographyTheme({
    this.fontFamily = 'Roboto',
    this.fallbackFonts = const ['Arial', 'sans-serif'],
    required this.axisLabelStyle,
    required this.axisTitleStyle,
    required this.tooltipTextStyle,
    required this.legendTextStyle,
    this.scaleFactorMobile = 0.9,
    this.scaleFactorTablet = 1.0,
    this.scaleFactorDesktop = 1.0,
  });

  final String fontFamily;
  final List<String> fallbackFonts;
  final TextStyle axisLabelStyle;
  final TextStyle axisTitleStyle;
  final TextStyle tooltipTextStyle;
  final TextStyle legendTextStyle;
  final double scaleFactorMobile;    // 0-599px
  final double scaleFactorTablet;    // 600-1023px
  final double scaleFactorDesktop;   // 1024px+

  /// Get scaled text style for viewport width
  TextStyle getScaledStyle(TextStyle base, double viewportWidth) {
    final scaleFactor = viewportWidth < 600
        ? scaleFactorMobile
        : viewportWidth < 1024
            ? scaleFactorTablet
            : scaleFactorDesktop;

    return base.copyWith(
      fontSize: (base.fontSize ?? 14) * scaleFactor,
    );
  }

  TypographyTheme copyWith({...});
  Map<String, dynamic> toJson();
  factory TypographyTheme.fromJson(Map<String, dynamic> json);
}

/// Animation configuration
@immutable
class AnimationTheme {
  const AnimationTheme({
    this.enabled = true,
    this.enterDuration = const Duration(milliseconds: 600),
    this.exitDuration = const Duration(milliseconds: 300),
    this.updateDuration = const Duration(milliseconds: 400),
    this.themeChangeDuration = const Duration(milliseconds: 300),
    this.enterCurve = Curves.easeOut,
    this.exitCurve = Curves.easeIn,
    this.updateCurve = Curves.easeInOut,
    this.themeChangeCurve = Curves.easeInOut,
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  final bool enabled;                    // Master enable/disable
  final Duration enterDuration;          // Data enter animation
  final Duration exitDuration;           // Data exit animation
  final Duration updateDuration;         // Data update animation
  final Duration themeChangeDuration;    // Theme switch animation
  final Curve enterCurve;                // Enter easing
  final Curve exitCurve;                 // Exit easing
  final Curve updateCurve;               // Update easing
  final Curve themeChangeCurve;          // Theme change easing
  final Duration staggerDelay;           // Delay between multi-element animations

  AnimationTheme copyWith({...});
  Map<String, dynamic> toJson();
  factory AnimationTheme.fromJson(Map<String, dynamic> json);
}
```

### Theme Builder

```dart
/// Fluent API for building custom themes
class ChartThemeBuilder {
  ChartTheme _theme;

  /// Start from base theme (default: defaultLight)
  ChartThemeBuilder([ChartTheme? baseTheme])
      : _theme = baseTheme ?? ChartTheme.defaultLight;

  // Canvas properties
  ChartThemeBuilder backgroundColor(Color color) {
    _theme = _theme.copyWith(backgroundColor: color);
    return this;
  }

  ChartThemeBuilder canvasBorder({
    Color? color,
    double? width,
    double? radius,
  }) {
    _theme = _theme.copyWith(
      canvasBorderColor: color,
      canvasBorderWidth: width,
      canvasBorderRadius: radius,
    );
    return this;
  }

  ChartThemeBuilder padding(EdgeInsets padding) {
    _theme = _theme.copyWith(padding: padding);
    return this;
  }

  // Component themes
  ChartThemeBuilder gridStyle(GridStyle style) {
    _theme = _theme.copyWith(gridStyle: style);
    return this;
  }

  ChartThemeBuilder axisStyle(AxisStyle style) {
    _theme = _theme.copyWith(axisStyle: style);
    return this;
  }

  ChartThemeBuilder seriesColors(List<Color> colors) {
    _theme = _theme.copyWith(
      seriesTheme: _theme.seriesTheme.copyWith(colors: colors),
    );
    return this;
  }

  ChartThemeBuilder typography(TypographyTheme typography) {
    _theme = _theme.copyWith(typography: typography);
    return this;
  }

  // Advanced customization with callbacks
  ChartThemeBuilder customizeAxis(AxisStyle Function(AxisStyle) customizer) {
    _theme = _theme.copyWith(axisStyle: customizer(_theme.axisStyle));
    return this;
  }

  ChartThemeBuilder customizeSeries(
    SeriesTheme Function(SeriesTheme) customizer,
  ) {
    _theme = _theme.copyWith(seriesTheme: customizer(_theme.seriesTheme));
    return this;
  }

  // Validation and build
  ChartTheme build() {
    final validation = _theme.validate();
    if (!validation.isValid) {
      throw ChartError(
        type: ChartErrorType.validation,
        message: 'Invalid theme: ${validation.errorMessage}',
      );
    }
    return _theme;
  }

  /// Build without validation (for advanced users)
  ChartTheme buildUnsafe() => _theme;
}
```

### Color Utilities

```dart
/// Accessibility and color utilities
class ColorUtils {
  /// Calculate WCAG 2.1 contrast ratio
  static double contrastRatio(Color color1, Color color2) {
    final l1 = _relativeLuminance(color1);
    final l2 = _relativeLuminance(color2);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast meets WCAG AA (4.5:1)
  static bool meetsAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast meets WCAG AAA (7:1)
  static bool meetsAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Get auto-contrast text color (white or black)
  static Color autoContrastText(Color background) {
    final whiteContrast = contrastRatio(Colors.white, background);
    final blackContrast = contrastRatio(Colors.black, background);
    return whiteContrast > blackContrast ? Colors.white : Colors.black;
  }

  /// Simulate colorblindness
  static Color simulateProtanopia(Color color) { /* implementation */ }
  static Color simulateDeuteranopia(Color color) { /* implementation */ }
  static Color simulateTritanopia(Color color) { /* implementation */ }

  /// Convert to grayscale
  static Color toGrayscale(Color color) {
    final gray = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue).round();
    return Color.fromARGB(color.alpha, gray, gray, gray);
  }

  /// Calculate relative luminance (WCAG formula)
  static double _relativeLuminance(Color color) {
    final r = _sRGBToLinear(color.red / 255.0);
    final g = _sRGBToLinear(color.green / 255.0);
    final b = _sRGBToLinear(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _sRGBToLinear(double c) {
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }
}
```

### Theme Validation

```dart
/// Theme validation logic
extension ChartThemeValidation on ChartTheme {
  ValidationResult validate() {
    final errors = <String>[];

    // Validate canvas properties
    if (canvasBorderWidth < 0) {
      errors.add('canvasBorderWidth must be >= 0 (got $canvasBorderWidth)');
    }
    if (canvasBorderRadius < 0) {
      errors.add('canvasBorderRadius must be >= 0 (got $canvasBorderRadius)');
    }

    // Validate grid
    if (gridStyle.width < 0) {
      errors.add('gridStyle.width must be >= 0 (got ${gridStyle.width})');
    }
    if (gridStyle.opacity < 0 || gridStyle.opacity > 1) {
      errors.add('gridStyle.opacity must be 0-1 (got ${gridStyle.opacity})');
    }

    // Validate series colors
    if (seriesTheme.colors.isEmpty) {
      errors.add('seriesTheme.colors must have at least 1 color');
    }
    if (seriesTheme.lineWidth < 0) {
      errors.add('seriesTheme.lineWidth must be >= 0 (got ${seriesTheme.lineWidth})');
    }

    // Validate accessibility
    final bgColor = backgroundColor;
    final textColor = typography.axisLabelStyle.color ?? Colors.black;
    if (!ColorUtils.meetsAA(textColor, bgColor)) {
      errors.add(
        'Text contrast fails WCAG AA (${ColorUtils.contrastRatio(textColor, bgColor).toStringAsFixed(2)}:1, need 4.5:1)',
      );
    }

    // Validate animation durations
    if (animation.enterDuration.inMilliseconds < 0) {
      errors.add('animation.enterDuration must be >= 0');
    }

    if (errors.isEmpty) {
      return ValidationResult.success();
    } else {
      return ValidationResult.failure(
        ChartError(
          type: ChartErrorType.validation,
          message: 'Theme validation failed:\n${errors.join('\n')}',
        ),
      );
    }
  }
}
```

### Predefined Theme Definitions

```dart
/// Predefined themes (excerpt - full definitions in implementation)
const _defaultLight = ChartTheme(
  backgroundColor: Color(0xFFFFFFFF),
  canvasBorderColor: Color(0xFFE0E0E0),
  canvasBorderWidth: 1.0,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.zero,
  
  gridStyle: GridStyle(
    color: Color(0xFFEEEEEE),
    width: 0.5,
    opacity: 1.0,
    showMajorGrid: true,
    showMinorGrid: false,
  ),
  
  axisStyle: AxisStyle(
    lineColor: Color(0xFF757575),
    lineWidth: 1.0,
    labelTextStyle: TextStyle(
      fontSize: 12,
      color: Color(0xFF616161),
      fontWeight: FontWeight.w400,
    ),
    titleStyle: AxisTitleStyle(
      textStyle: TextStyle(
        fontSize: 14,
        color: Color(0xFF424242),
        fontWeight: FontWeight.w500,
      ),
    ),
    tickStyle: TickStyle(
      color: Color(0xFF757575),
      length: 6.0,
      width: 1.0,
    ),
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
    lineWidth: 2.0,
    pointSize: 4.0,
    areaOpacity: 0.3,
  ),
  
  interactionTheme: InteractionTheme(
    crosshairStyle: CrosshairStyle(
      lineColor: Color(0xFF757575),
      lineWidth: 1.0,
      opacity: 0.8,
      dashPattern: [4.0, 2.0],
    ),
    tooltipStyle: TooltipStyle(
      backgroundColor: Color(0xFF212121),
      textColor: Color(0xFFFFFFFF),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      padding: EdgeInsets.all(8),
    ),
    selectionStyle: SelectionStyle(
      selectedColor: Color(0xFF2196F3),
      hoverColor: Color(0xFF64B5F6),
      selectedOpacity: 1.0,
      hoverOpacity: 0.8,
    ),
  ),
  
  typography: TypographyTheme(
    fontFamily: 'Roboto',
    fallbackFonts: ['Arial', 'sans-serif'],
    axisLabelStyle: TextStyle(
      fontSize: 12,
      color: Color(0xFF616161),
      fontWeight: FontWeight.w400,
    ),
    axisTitleStyle: TextStyle(
      fontSize: 14,
      color: Color(0xFF424242),
      fontWeight: FontWeight.w500,
    ),
    tooltipTextStyle: TextStyle(
      fontSize: 12,
      color: Color(0xFFFFFFFF),
      fontWeight: FontWeight.w400,
    ),
    legendTextStyle: TextStyle(
      fontSize: 12,
      color: Color(0xFF616161),
      fontWeight: FontWeight.w400,
    ),
  ),
  
  animation: AnimationTheme(
    enabled: true,
    enterDuration: Duration(milliseconds: 600),
    exitDuration: Duration(milliseconds: 300),
    updateDuration: Duration(milliseconds: 400),
    themeChangeDuration: Duration(milliseconds: 300),
    enterCurve: Curves.easeOut,
    exitCurve: Curves.easeIn,
    updateCurve: Curves.easeInOut,
    themeChangeCurve: Curves.easeInOut,
  ),
);

// Other themes: defaultDark, corporateBlue, vibrant, minimal,
// highContrast, colorblindFriendly defined similarly
```

---

## Implementation Strategy

### Phase 1: Core Theme Structure (Week 1)
1. Define all theme data classes (ChartTheme, GridStyle, AxisStyle, etc.)
2. Implement immutability (`copyWith()`, equality, hash code)
3. Add JSON serialization/deserialization
4. Implement theme validation
5. Unit tests for all data classes

### Phase 2: Predefined Themes (Week 1-2)
1. Implement all 7 predefined themes
2. Validate accessibility (WCAG 2.1 AA/AAA)
3. Test colorblind-friendly theme with simulation tools
4. Document each theme with screenshots
5. Integration tests for theme application

### Phase 3: Theme Builder (Week 2)
1. Implement ChartThemeBuilder with fluent API
2. Add callback-based customization
3. Implement theme preview capability
4. Add builder validation
5. Unit tests for builder patterns

### Phase 4: Color Utilities (Week 2)
1. Implement contrast ratio calculation (WCAG algorithms)
2. Add colorblind simulation functions
3. Implement auto-contrast text color
4. Add color format parsing (hex, RGB, HSL)
5. Unit tests for all color utilities

### Phase 5: Theme Application (Week 3)
1. Integrate themes with rendering engine (Paint/TextStyle from theme)
2. Implement theme caching and diffing
3. Add theme change animations
4. Optimize style resolution (caching, inheritance)
5. Performance benchmarks (<100ms theme switching)

### Phase 6: Responsive Theming (Week 3)
1. Implement breakpoint detection (mobile/tablet/desktop)
2. Add responsive font scaling
3. Implement responsive grid density
4. Add responsive touch target sizing
5. Integration tests across viewport sizes

### Phase 7: Documentation & Polish (Week 4)
1. Complete dartdoc for all public APIs
2. Write comprehensive usage guide
3. Create migration guide from other libraries
4. Add accessibility best practices guide
5. Final validation and testing

---

## Testing Strategy

### Unit Tests
- All theme data classes (equality, copyWith, serialization)
- Theme validation logic (all error conditions)
- Color utilities (contrast, colorblind simulation, grayscale)
- Theme builder (fluent API, validation, preview)
- Style resolution and caching

### Integration Tests
- Theme application to rendering pipeline
- Theme switching without chart recreation
- Responsive theming across viewport sizes
- Accessibility compliance (WCAG 2.1 AA/AAA)
- Performance (theme switching <100ms)

### Visual Regression Tests
- All 7 predefined themes rendered correctly
- Theme changes produce expected visual output
- Colorblind simulations match expected results
- Cross-platform consistency (Web, mobile, desktop)

### Accessibility Tests
- Automated contrast checking (all themes)
- Colorblind simulation validation
- Screen reader compatibility
- Keyboard navigation (focus indicators)

### Performance Benchmarks
- Theme switching time (<100ms for 10k point chart)
- Style resolution time (<0.1ms per element)
- Memory footprint (stable after 100 theme switches)
- Cache hit rate (>95% during rendering)

---

## Success Criteria

### Functional Completeness
- ✅ All 7 predefined themes implemented and documented
- ✅ Custom theme builder with fluent API
- ✅ Theme serialization (JSON import/export)
- ✅ Color utilities (contrast, simulation, auto-contrast)
- ✅ Responsive theming (mobile/tablet/desktop breakpoints)

### Performance
- ✅ Theme switching <100ms for complex charts
- ✅ Style resolution <0.1ms per element
- ✅ Cache hit rate >95%
- ✅ No memory leaks on theme changes
- ✅ Zero performance overhead vs. no theming

### Accessibility
- ✅ All themes meet WCAG 2.1 AA (4.5:1 contrast)
- ✅ High Contrast theme meets WCAG 2.1 AAA (7:1 contrast)
- ✅ Colorblind Friendly theme validated with simulation
- ✅ All themes distinguishable in grayscale
- ✅ Touch targets ≥44×44 points (all themes)

### Developer Experience
- ✅ Comprehensive dartdoc with examples
- ✅ Intuitive, discoverable API
- ✅ Theme debugging tools (inspector, validation)
- ✅ Hot reload support (no chart recreation)
- ✅ Migration guide from other libraries

### Documentation
- ✅ All 7 themes documented with screenshots
- ✅ Custom theme tutorial (step-by-step)
- ✅ Accessibility best practices guide
- ✅ API reference (all classes, methods)
- ✅ Usage guide with common patterns

---

## Open Questions

1. **Animation Performance**: Should theme change animations be skipped if frame budget exceeded?
   - **Recommendation**: Yes, use adaptive quality (skip animation if >16ms)

2. **Theme Versioning**: How should we handle breaking changes to theme schema?
   - **Recommendation**: Semantic versioning + automatic migration from older schemas

3. **Platform Fonts**: Should we have platform-specific font defaults (Roboto on Android, SF Pro on iOS)?
   - **Recommendation**: Yes, detect platform and use appropriate system font

4. **Theme Inheritance**: Should child charts inherit parent chart themes?
   - **Recommendation**: Yes, but allow explicit override per chart

5. **Dynamic Theming**: Should themes support dynamic values (e.g., theme-aware dark mode)?
   - **Recommendation**: Future enhancement, not in initial implementation

---

## Constitutional Compliance

### Pure Flutter ✅
- All theming code uses Flutter SDK only (dart:ui, dart:math)
- No external theming packages (no theme_provider, no styled_widget)
- Platform-agnostic implementation

### Performance ✅
- Theme switching <100ms (constitutional requirement for UI responsiveness)
- Style resolution cached (>95% hit rate)
- Zero allocations during theme application
- Performance-neutral vs. no theming

### Testability ✅
- All theme components immutable (pure data classes)
- Theme validation is pure function (no side effects)
- Color utilities are pure functions
- 100% unit test coverage target

### Accessibility ✅
- WCAG 2.1 AA minimum (4.5:1 contrast)
- WCAG 2.1 AAA for High Contrast theme (7:1 contrast)
- Colorblind-friendly theme validated
- Touch targets ≥44×44 points

---

## References

- **WCAG 2.1 Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **Material Design 3 Theming**: https://m3.material.io/styles/color/overview
- **Flutter Theming Best Practices**: https://docs.flutter.dev/cookbook/design/themes
- **Colorblind Simulation**: Coblis Color Blindness Simulator
- **iOS Human Interface Guidelines**: Touch Targets (44×44 points minimum)
- **Android Material Design**: Touch Targets (48×48 dp minimum)

---

**Status**: Ready for implementation planning (plan.md, tasks.md generation)
