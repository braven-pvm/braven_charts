# Changelog

All notable changes to the braven_charts package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.7.0 - 2026-07-18

### Added
- Opt-in `ChartDisplayMode.source` for `BravenChartWorkbench`, backed by the
  public deterministic `ChartDartSourceGenerator`. Generated direct Dart
  covers Line, Area, Scatter, Bar, Pie, Donut, mixed and multi-axis charts,
  annotations, interactions, resolved themes, legends, and optional durable
  view state. `ChartDartSourceOptions` bounds inline data, while
  `ChartGeneratedSource` reports completeness, placeholders, and diagnostics
  for runtime-only behavior instead of silently omitting it.
- A package-owned Source viewport with Dart syntax highlighting, line numbers,
  selectable and wrappable text, exact clipboard copy, a dedicated dark code
  canvas in either host theme, independent loading/stale/failure state, retry,
  and manual, mode-entry, or document-revision refresh policies.
- Nestable `ChartWorkbenchScope` and caller-owned
  `ChartWorkbenchGroupController` for system-wide or chart-family-wide display
  mode and mode-selector visibility. Grouped Workbenches reconcile their common
  supported modes safely while retaining local split sizing, data/source
  snapshots, selection, focus, and interaction state.
- Opt-in Line and Area entrance reveals and compatible mounted data-update
  interpolation through `PathAnimationStyle`, `PathEntranceAnimationMode`, and
  `PathDataUpdateAnimationMode`. `PathAnimationTiming` adds independent
  per-series delay and duration for entrance and update phases, while
  `BravenChartController.replaySeriesEntrance()` replays the mounted entrance.
- Stable-identity Line and Area transition support for value changes, appends,
  boundary removals, and rolling-window snapshots. Area fill and outline share
  one timeline, artifacts persist the motion configuration, and reduced motion,
  zero-duration themes, interaction, and streaming paths retain their existing
  contracts.
- `CategoryAxisConfig`, `CategoryLabelDensity`, and
  `CategoryLabelOverflow` for stable categorical identity, automatic readable
  viewports, label thinning, wrapping or ellipsis, rotation, and transposed
  horizontal Bar axes without host label callbacks.
- `BarLayoutMode.divergingStacked`, `BarDivergingRole`, and
  `BarDivergingStyle` for centered normalized Likert-style compositions with a
  configurable center line and source-value preservation.
- `BarPatternStyle` and `BarFillPattern` for contrast-aware non-colour fills;
  `BarLollipopStyle` for stem-and-head categorical marks; and
  `BarBulletStyle`/`BarBulletRange` for qualitative ranges around an actual
  measure and target.
- `ParetoCategory`/`ParetoChartData` for stable ranked values and cumulative
  mixed-series data, plus `HistogramChartData`, `HistogramBin`, configurable
  binning methods, and count, percentage, or density output for continuous
  samples.
- `BarMotionStyle` and `BarAnimationOrder` for together, forward, reverse,
  center-out, or edges-in keyed Bar entrance/update/exit sequencing with
  baseline-collapse exits and reduced-motion support.
- Collision-aware Bar labels with reposition/hide policies, plot-edge
  containment, optional backgrounds and callouts, range endpoints, normalized
  percentages, waterfall values, and exposed positive/negative stack totals.
- `BravenChartPlus.transitionKey` for switching one mounted chart between
  semantically different configurations without interpolating incompatible
  geometry. A changed key clears prior Line, Area, Bar, Pie, and Donut motion
  history, replays only the destination entrance, and preserves Workbench and
  controller state.
- Runtime Donut center builders and actions through
  `BravenChartPlus.donutCenterBuilder`, `onDonutCenterTap`, and
  `DonutCenterData`, with package-owned circular hit testing and semantics,
  portable center-content fallback, and explicit rebinding after hydration.
- Shared Pie and Donut value, percentage, radius, and center formatting across
  labels, legends, tooltips, semantics, artifacts, restored charts, and source
  generation through `RadialValueFormatter` and portable formatter descriptors.
- Explicit sum, mean, weighted-mean, minimum, and maximum
  `RadialSliceRadiusAggregation` policies when variable-radius Pie or Donut
  slices are grouped, without collapsing source rows carried by tables and
  artifacts.
- Identity-aware Pie and Donut data transitions that preserve category
  selection across keyed updates, fade structural changes safely, honor
  reduced motion, and support per-series opt-out.

### Changed
- Visible Workbench Source now follows effective chart-document changes by
  default. Regeneration is coalesced on a bounded cadence, hidden Source catches
  up on entry, and normal automatic refreshes no longer present manual
  `Chart changed` or `Refresh source` controls. `manual` and `onModeEntry`
  policies remain explicit opt-ins, independent from Data's snapshot policy.
- Line, Area, Bar, Scatter, Pie, and Donut showcase guides now use the same
  package-owned Chart/Data/Split/Source Workbench contract. Line and Area add
  resizable Split panes, motion presets, replay/update controls, responsive
  compact layouts, and direct review routes.
- Advanced Bar properties now round-trip through chart artifacts and hydration,
  project their resolved fields into native tables and CSV, and are available
  through `ChartConfigBuilder` and the public chart tool schema.
- Bar charts now inherit right-to-left canvas text direction and semantics,
  retain canonical interaction geometry across lollipop/bullet/pattern marks,
  and use keyed transitions for durable selection and focus across updates.
- Dense Bar charts now materialize only viewport-intersecting categories with
  visual overscan while retaining original point identity. Plot-cell hit-test
  indexing and a separate spatial index for collision-aware labels avoid
  full-series and previously accepted-label scans; maintained stress coverage
  spans 100,000 source points, 5,000 labels, and the public 12–10,000-category
  Bar Lab preset.
- Pie and Donut share the annular-sector layout foundation, formatter contract,
  grouped-radius semantics, and data-transition policy while preserving their
  distinct full-disc and center-opening constraints.

### Fixed
- Effective chart-document revisions no longer advance for layout-only parent
  rebuilds or responsive constraint changes. Fresh Data and Source snapshots
  therefore remain current after first layout and resize, while actual series,
  axes, annotations, themes, interactions, dimensions, and other portable
  configuration changes still mark them stale.
- Source capture now preserves Pie and Donut formatter descriptors without
  routing radial series through Cartesian annotation-copy paths or casting
  Donut series to Pie.

## 0.6.0 - 2026-07-18

### Added
- Native Bar projection in `BravenChartWorkbench` Chart, Data, and Split
  presentations. Tables preserve source values while exposing the resolved
  target, uncertainty, range, stack-bound, normalized-share, and waterfall
  running-total fields used by the renderer; row copy and CSV export include
  those fields without creating synthetic chart series.
- Bidirectional point linking between charts and virtualized data tables.
  Table hover and keyboard focus apply transient chart focus, while
  controller-driven chart focus and durable selection reveal and highlight
  the matching table row without stealing keyboard focus.
- Modifier-aware table selection matching desktop data tools: Ctrl/Command
  toggles rows additively, Shift selects a contiguous range in current sorted
  order, and Ctrl/Command+Shift adds that range to the existing selection.
  Shared-X rows select every populated point they represent.
- Complete keyboard table selection and navigation, including Enter row
  activation, Ctrl/Command+A select-all, Escape clear, Home/End boundary
  navigation, and viewport-sized Page Up/Page Down movement. Selection
  summaries report point counts and expose a compact Clear action.
- Host-built Pie and Donut legend items through
  `BravenChartPlus.radialLegendItemBuilder`, with resolved radial data,
  package-owned responsive layout and selection, stable accessibility
  semantics, and public Pie/Donut showcase examples.
- Angular `sweep` and geometry-preserving `fade` Pie/Donut entrance modes,
  retaining radial `grow` as the default and honoring reduced motion across
  initial mounts, data changes, and explicit controller replays.
- `BravenChartController.replayRadialEntrance()` plus public Donut showcase
  controls, artifact/theme round trips, AI input, and focused geometry,
  rendering, accessibility, and lifecycle coverage for radial motion.
- Source-preserving Pie/Donut small-slice grouping with a configurable share
  threshold, minimum source count, label, and color. One visible aggregate
  selects every original controller/table reference while artifacts, copy,
  CSV, selection callbacks, and hydration retain the uncollapsed source data.
- Content-aware, user-resizable Chart/Data Split panes in
  `BravenChartWorkbench`, including a focused divider with a 12-pixel pointer
  strip, keyboard resizing, Escape/double-click reset, and stable Pie/Donut
  legend footprints when selection changes.

### Changed
- Replaced repeated pub.dev contact sheets and oversized caption overlays with
  a three-column visual index of 42 individually linked chart captures. The
  index covers every curated Gallery composition alongside concise tracking,
  zoom/pan, Donut selection, and live-buffering animations generated from
  reusable showcase compositions.
- Added a dedicated thirteen-composition Bar Gallery covering target and
  uncertainty markers, capacity tracks, waterfall bridges, floating ranges,
  horizontal rankings, normalized and absolute stacks, overlaid plan/actual
  values, capsule rods, gradient groups, signed values, offset comparisons,
  and four-axis normalization. Twelve new native chart captures link directly
  to their corresponding Bar presets from the README and expand the pub.dev
  screenshot catalogue.

## 0.5.0 - 2026-07-17

### Added
- First-class `DonutChartSeries` for single-ring categorical charts, including
  validated inner and outer radii, full or partial sweeps, clockwise or
  counter-clockwise layout, slice gaps, gradients, borders, corner policies,
  elevation, animation, variable outer radii, and stable category order.
- Donut-native annular hit testing, hover and durable selection, keyboard
  navigation, focus semantics, tooltips, inside or collision-managed outside
  labels, positioned legends, and controller-linked slice identity.
- Portable `DonutCenterContent` with total, selected, selected-or-total, and
  custom value modes; independent label/value styling; accessible summary
  semantics; and selection-aware updates from slices, legends, and tables.
- Complete Donut artifact support: capability metadata, canonical JSON codecs,
  hydration, previews, Chart/Data/Split projection, native copy/CSV output,
  controller state, AI builder input, and tool-schema generation.
- Variable-radius Pie and Donut slices with labeled secondary metrics,
  perceptual-area or linear scaling, configurable minimum radius, tooltip and
  table/CSV exposure, artifact persistence, and AI input.
- Configurable radial corner treatments for all-corner rounding, outer-edge
  rounding, or a uniform circular center gap across variable-radius slices.
- Bar point interaction states through `BarInteractionStyle`, covering hover,
  press, keyboard focus, durable selection, selected emphasis, and dimming of
  non-selected bars without losing category identity.
- Persistent bar-point selection through pointer, keyboard, controller, view
  state, callbacks, semantics, tooltip anchoring, and artifact restoration.
- Keyed bar data-update animation for grouped, overlaid, stacked, normalized,
  range, horizontal, and waterfall layouts. Updates interpolate category
  values and geometry using the chart animation theme, honor reduced motion,
  grow inserted points from their baseline, and allow per-series opt-out with
  `BarAnimationMode.none`.
- Per-category bar benchmarks through `BarChartSeries.targetValues` and
  `BarTargetMarkerStyle`, including configurable line length, width, color,
  dash pattern, bounds participation, tooltips, semantics, animation, and
  canonical artifact round-tripping.
- Per-point Bar uncertainty intervals through `errorLowerValues` and
  `errorUpperValues`, with `BarErrorBarStyle` control over stem/cap color,
  width, opacity, and cap length. Error ranges participate in automatic axis
  bounds, keyed data-update animation, Cartesian and transposed geometry,
  tooltips, semantics, and canonical artifact round-tripping.
- Public Donut, Bar, and chart-family showcase coverage with dedicated deep
  routes, a six-family overview and Gallery sampler, Donut Chart/Data/Split
  workflows, Bar interaction/motion/target presets, and native pub.dev media.

### Changed
- Reorganized the public showcase around a concise Chart Types overview with
  nested Line, Area, Bar, Scatter, Pie, and Donut guides while retaining the
  cross-cutting interaction, annotation, theming, performance, axis,
  scientific, styling, baseline, loading, artifact, and workbench pages.
- Reworked the Gallery landing sequence to lead with six simple native chart
  previews, followed by a readable multi-axis training profile, the advanced
  analytical flagship, and focused Pie and Donut composition collections.
- Carry dark radial themes through the complete Gallery card surface, reduce
  compact Donut label typography, and replace the initial Donut samples with
  distinct subscription, release-readiness, and channel-efficiency analyses.
- Expanded the Bar guide and API documentation to cover grouped, overlaid,
  stacked, normalized, horizontal, floating/range, waterfall, capacity-track,
  target-marker, uncertainty, interaction-state, and animated-update behavior.
- Updated package metadata, README feature coverage, API references, release
  checklist, and screenshot descriptions to enumerate every public chart
  family and the new radial and Bar capabilities.

### Fixed
- Keep Cartesian axes out of Pie and Donut layout and capture paths so radial
  charts retain the full intended viewport.
- Preserve Bar tooltip, crosshair, semantics, bounds, labels, selection, and
  target-marker identity across transposed, stacked, overlaid, range, and
  animated geometry.

## 0.4.0 - 2026-07-17

### Added
- First-class `PieChartSeries` rendering with deterministic radial geometry,
  inside or collision-managed outside labels, slice legends, tooltips,
  keyboard navigation, accessible slice semantics, and selectable explode
  state.
- Pie artifact capability (`series.pie`), canonical JSON hydration, preview
  capture, category/value/share table projection, native copy/CSV actions,
  and tool-schema support.
- Dedicated Pie Charts showcase and Pie option in the Chart Types comparison.
- Theme-level Pie palettes, opacity, rounded corners, shadows, selected glow,
  styled label callouts, tooltip presets, positioned/oriented slice legends,
  and reduced-motion-aware radial animations.
- Public Gallery Pie compositions, basic Pie controls in Chart Types, complete
  presentation presets in the Pie showcase, and deterministic pub.dev media.
- A simple dark Pie presentation with dominant inside values and no legend,
  available both as a focused preset and a reusable Gallery composition.
- Fixed or HSL slice-derived Pie border policies, detailed selected-glow
  controls, and showcase presets for legend, label callout, and tooltip themes.
- Linear and radial Pie slice gradients with per-slice derived or fixed color
  stops, theme/series precedence, artifact hydration, AI schema support, and a
  live showcase selector.
### Fixed
- Refine Pie selection so pointer and legend activation use slice-derived
  offset/elevation without an intrusive global accent outline, while retaining
  the themed keyboard and assistive focus ring.
- The high-contrast Pie showcase preset now uses collision-managed outside
  labels with opaque white callouts, near-black text, and a 2 px outline so
  labels remain readable across every monochrome slice.
- The Pie showcase no longer draws a chart-wide focus box during hover or
  pointer interaction; keyboard focus remains visible on the active slice.
- Pie legends now measure compactly at their requested edge instead of
  reserving a fixed 40% band or rail, leaving the bulk of the viewport to the
  chart while bounded overflow remains scrollable.
- Pie slice gaps now preserve category angles and separate complete wedges like
  physical padding, while per-slice radius compensation keeps uneven wedges on
  one outer ring instead of shrinking the largest slice inward.
- Pie tooltips now inherit the interaction theme when no explicit non-default
  style is supplied, follow durable selection from slices, legends, and linked
  tables, clear on deselection, and re-anchor after geometry or size changes.
- Pie layout now reserves the configured explode, border/focus stroke, shadow,
  and selected elevation extents so edge-facing selections remain inside the
  plot instead of being clipped by the viewport.
- Outside Pie labels now use compact lanes beside the painted chart by default,
  with a configurable non-negative offset for deliberate extra spacing.
- Pie entrance labels now follow the animation lifecycle instead of curved
  radius thresholds, preventing elastic animations from flashing callouts on
  and off before the chart settles.
- Native PNG previews now paint the chart theme background across the complete
  capture boundary, including positioned Pie legend space.
- Canvas-rendered multi-axis titles, series labels, point labels, and tracking
  tooltips now preserve the chart typography theme's font family.

## 0.3.1 - 2026-07-17

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
