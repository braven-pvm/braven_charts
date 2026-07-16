# Changelog

All notable changes to the braven_charts package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.3.1 - 2026-07-17

### Added
- First-class `PieChartSeries` rendering with deterministic radial geometry,
  inside or collision-managed outside labels, slice legends, tooltips,
  keyboard navigation, accessible slice semantics, and selectable explode
  state.
- Pie artifact capability (`series.pie`), canonical JSON hydration, preview
  capture, category/value/share table projection, native copy/CSV actions,
  and tool-schema support.
- Dedicated Pie Charts showcase and Pie option in the Chart Types comparison.

### Fixed
- Expand data-derived constant per-axis ranges to a stable non-zero span so
  single-point and constant-valued series render safely with per-series
  normalization.

## 0.3.0 - 2026-07-16

### Added
- Expand range and threshold annotation label placement from five positions to
  a complete 3x3 anchor model while retaining all legacy position names.
- Standardize native annotation editors on a shared sticky header, consistent
  actions, a compact spatial label-position selector, and the universal color
  palette for every annotation color field.

### Fixed
- Preserve the remaining normalized multi-axis series, visible-axis slots, and
  controller state when another series is hidden and the parent chart rebuilds
  or reorders.

## 0.2.0 - 2026-07-16

### Added
- `BravenChartWorkbench` with one mounted Chart/Data/Split runtime, responsive
  compact fallback, document freshness policies, and host-defined artifact
  actions.
- Revision-safe table-to-chart point focus and durable point selection through
  canonical `ChartPointRef` values, including wide-row multi-point linking and
  artifact/hydration round-trip.
- Pure multi-document comparison models with explicit semantic series mapping,
  exact-X, timestamp-tolerance, and independent alignment, safe unit
  conversion, missing-value state, deltas, and source-preserving CSV export.
- Release-packaged Workbench and Chart Document Comparison guides plus an
  interactive showcase covering capture, canonical JSON diagnostics,
  recoverable table states, bounded-stream snapshots, aligned values, and
  three independently hydrated charts.

### Fixed
- Initial workbench table failures remain observable until the user retries;
  layout rebuilds no longer trigger an uncontrolled automatic retry loop.

## 0.1.4 - 2026-07-16

### Changed
- Recompose the pub.dev introduction as two compact analytical stills followed by one full-width animated interaction example.
- Add deterministic, independently rendered media-capture surfaces for the light threshold and dark power-duration charts.

## 0.1.3 - 2026-07-15

### Fixed
- Pin the README hero to immutable `v0.1.2` media so pub.dev invalidates its external-image cache and serves the new dual-chart composition.

## 0.1.2 - 2026-07-15

### Changed
- Replace the package hero with a taller, side-by-side analytical showcase: a warm mixed-series threshold view and a dark power-duration baseline model.
- Add the two hero compositions to the live Gallery with contrasting themes, chart geometries, annotations, tracking, and scrollbar behavior.

### Fixed
- Retry incomplete Flutter web canvas captures when generating package showcase media.

## 0.1.1 - 2026-07-15

### Fixed
- Use absolute HTTPS sources for README showcase media so images and animated examples render correctly on pub.dev.

## 0.1.0 - 2026-07-15

### Added
- **Core chart types**: Line, area, bar, scatter, and mixed-series charts with markers, interpolation modes, segment styling, baseline fills, and configurable legends and labels.
- **Native Flutter rendering**: Custom `RenderBox` and `Canvas` pipeline with cached series layers, spatial hit testing, and no embedded JavaScript chart engine.
- **Interaction**: Pointer and touch zoom, pan, X/Y scrollbars, tracking tooltips, crosshairs, selection, and runtime controller APIs.
- **Multi-axis plotting**: Independent and shared Y axes, per-series normalization, fixed or derived bounds, axis-slot management, and original-unit tracking values.
- **Live data**: Frame-coalesced render updates, bounded buffers, follow-latest viewports, pause/resume, and buffered catch-up through `LiveStreamController`.
- **Chart and table display**: Exact-X data tables, sortable columns, native copy actions, and CSV export without discarding chart state.
- **Portable chart artifacts**: Canonical JSON documents, binary and inline payloads, migration, validation, preview capture, deduplication, storage resolvers, and interactive chart hydration.
- **Themes and state views**: Light, dark, custom, and accessibility-oriented themes plus configurable loading, empty, and error presentations.
- **Loading and empty states**: `BravenChartPlus.isLoading` now supports a responsive, chart-theme-aware animated skeleton, circular, linear, determinate, and custom loading presentations. Empty series render configurable guidance instead of a blank plot.
- **ChordAnnotation**: New annotation type that draws a straight line (chord/secant) between two data points on a series. Supports line color, width, dash pattern, and elevation/glow styling.
- **Perpendicular drop-line**: Optional `perpendicularIndex` on ChordAnnotation draws a line from the chord to a data point, projected perpendicularly onto the chord. Includes independent styling and label support. Used for lactate threshold (LT1) deflection distance visualization.
- **ChordAnnotationDialog**: Full Material Design 3 creation/edit dialog with series selection, start/end indices, perpendicular configuration, and complete label + line styling controls.
- **Lactate Threshold showcase page**: New example page demonstrating ChordAnnotation for LT1 detection with interactive controls for chord placement, LT1 point selection, and annotation visibility.

### Breaking Changes
None. All deprecated APIs remain functional with backward compatibility.

### Deprecations & Migration Guide

This release introduces a unified theming and axis configuration system. Several legacy APIs are now deprecated but remain functional. Please migrate to the new APIs at your convenience.

#### ChartTheme Field Deprecations

The following `ChartTheme` constructor parameters and getters are deprecated in favor of the new component-based theming system:

**Deprecated Fields:**
- `gridColor` → Use `gridStyle.majorColor` instead
- `axisColor` → Use `axisStyle.lineColor` instead
- `textColor` → Use `typographyTheme` or `axisStyle.labelStyle.color` instead
- `seriesColors` → Use `seriesTheme.colors` instead

**Migration Example:**

```dart
// OLD (deprecated but still works)
final theme = ChartTheme(
  backgroundColor: Colors.white,
  gridColor: Colors.grey.shade300,
  axisColor: Colors.black,
  textColor: Colors.black87,
  seriesColors: [Colors.blue, Colors.red, Colors.green],
  // ... other required fields
);

// NEW (recommended)
final theme = ChartTheme(
  backgroundColor: Colors.white,
  gridStyle: GridStyle(
    majorColor: Colors.grey.shade300,
    majorWidth: 1.0,
  ),
  axisStyle: AxisStyle(
    lineColor: Colors.black,
    labelStyle: TextStyle(color: Colors.black87),
  ),
  seriesTheme: SeriesTheme(
    colors: [Colors.blue, Colors.red, Colors.green],
  ),
  typographyTheme: TypographyTheme.defaultLight,
  interactionTheme: InteractionTheme.defaultLight,
  animationTheme: AnimationTheme.defaultLight,
  annotationTheme: AnnotationTheme.defaultLight,
  scrollbarConfig: ScrollbarConfig.defaultLight,
  legendStyle: LegendStyle.light,
);

// Or use predefined themes:
final theme = ChartTheme.light; // or .dark, .corporateBlue, .vibrant, etc.
```

#### AxisConfig vs YAxisConfig

**For Y-Axis Configuration:**
- Use `YAxisConfig` when configuring Y-axes in multi-axis charts
- Use `ChartSeries.yAxisConfig` to define Y-axis inline on a series
- `AxisConfig` remains available for general axis configuration and X-axis use

**Migration Example:**

```dart
// Preferred approach for Y-axis configuration
LineChartSeries(
  id: 'temperature',
  points: tempData,
  yAxisConfig: YAxisConfig(
    position: YAxisPosition.left,
    label: 'Temperature',
    unit: '°C',
    color: Colors.red,
  ),
)

// AxisConfig is still valid for X-axis and general configuration
BravenChartPlus(
  series: [series1, series2],
  xAxisConfig: AxisConfig(
    label: 'Time',
    showGrid: true,
  ),
)
```

#### SeriesElement & DataConverter Parameter Deprecations

**SeriesElement Constructor:**
- `strokeWidth` parameter → Use `seriesTheme` instead
- `themeColor` parameter → Use `seriesTheme` instead

**DataConverter.seriesToElements:**
- `strokeWidth` parameter → Use `theme.seriesTheme` instead

**Migration Example:**

```dart
// OLD (deprecated)
final elements = DataConverter.seriesToElements(
  series: chartData,
  transform: transform,
  strokeWidth: 2.5,
);

// NEW (recommended)
final theme = ChartTheme(
  // ... other theme properties
  seriesTheme: SeriesTheme(
    lineWidth: 2.5,
    colors: [Colors.blue, Colors.red],
  ),
);

final elements = DataConverter.seriesToElements(
  series: chartData,
  transform: transform,
  theme: theme,
);
```

#### LineStyle Enum Deprecation

The widget-level `LineStyle` enum has been deprecated. Use `LineInterpolation` directly on individual `ChartSeries` instead for fine-grained control.

**Migration Example:**

```dart
// OLD (no longer available at widget level)
// BravenChartPlus(lineStyle: LineStyle.smooth)

// NEW (set on each series)
LineChartSeries(
  id: 'series1',
  points: data,
  interpolation: LineInterpolation.bezier, // smooth curves
)

LineChartSeries(
  id: 'series2',
  points: data,
  interpolation: LineInterpolation.linear, // straight lines
)
```

### Benefits of Migration

- **Component-Based Theming**: More flexible and modular styling
- **Type Safety**: Better IDE autocomplete and compile-time checks
- **Consistency**: Unified theming across all chart elements
- **Performance**: Optimized rendering with the new theme system
- **Flexibility**: Per-series interpolation and styling control

### Backward Compatibility

All deprecated APIs remain functional with full backward compatibility. Existing code will continue to work with deprecation warnings. You can migrate incrementally at your own pace.

## [Previous Versions]

(Version history to be added as releases are published)
