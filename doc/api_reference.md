# Public API overview

Import the supported package surface through one entrypoint:

```dart
import 'package:braven_charts/braven_charts.dart';
```

Pub.dev generates the complete member-level API reference from Dart
documentation comments. This page is a human-oriented map of the main exported
types and where to begin.

## Authoring surfaces

- `BravenChartPlus` is the direct, immutable chart configuration surface.
- `BravenChart.of<T>(rows)` starts the typed Chart Grammar facade. Its
  `x`/`y`, geometry, encoding, axis, reference, title, legend, theme, and
  interaction verbs build a `PlotSpec<T>` and lower through
  `PlotSpecLowering` to the ordinary package configuration and renderer.
- `BravenPlot<T>` mounts a `PlotSpec<T>` directly. `Mark<T>`, `Channel<T>`,
  `CategoryChannel<T>`, and `GrammarDiagnosticCode` expose the typed grammar
  model and fail-fast validation contract.
- `BravenChartWorkbench` keeps one chart mounted across Chart, Data, Split,
  and Source modes. `initialSourceForm` and `grammarSourceOptions` configure
  the Config/Grammar source forms; `ChartGrammarSourceGenerator` emits a
  Grammar chain only after lowering it and proving structural fidelity to the
  captured chart document.
- `package:braven_charts/braven_charts_fluent.dart` is an opt-in barrel that
  re-exports the core API and adds generated immutable modifier extensions to
  public configuration classes. Applications that do not import it keep the
  original core namespace.

The Grammar, direct configuration, fluent modifiers, Workbench, artifact
codecs, data tables, and generated source are authoring and portability
surfaces over the same renderer. See
[Chart Grammar and fluent configuration](chart_grammar.md) for supported marks,
round-trip boundaries, diagnostics, and integration guidance.

## Chart widget and series

- `BravenChartPlus` — primary chart widget, including `fromValues` and
  `fromMap` convenience factories.
- `ChartSeries` — common immutable series model.
- `LineChartSeries`, `AreaChartSeries`, `RangeAreaChartSeries`, `BarChartSeries`,
  `ScatterChartSeries`, `CandlestickChartSeries`, `HeatmapChartSeries`,
  `PieChartSeries`,
  `DonutChartSeries`, and `PolarColumnChartSeries` — concrete renderable
  series.
- `ChartDataPoint`, `DataRange`, `ChartType` — core data types.
- `LineInterpolation`, `SeriesStyle`, `SegmentStyle`,
  `DataPointLabelConfig`, `SeriesInlineLabelConfig` — series presentation.

### Scatter charts

- `ScatterMarkerStyle` controls fill, outline, opacity, independent width and
  height, and rotation; `SeriesMarkerShape` provides circle, square, triangle,
  inverted-triangle, diamond, cross, plus, star, and hidden markers.
- `ScatterSizeEncoding` maps `ChartDataPoint.magnitude` to perceptually correct
  marker area with optional fixed bounds and a quantitative size legend.
- `ScatterColorEncoding` maps `ChartDataPoint.colorValue` through continuous
  interpolation or explicit `ScatterColorScaleType.piecewise` thresholds with
  native gradient or segmented legends.
- `ScatterOpacityEncoding` maps `ChartDataPoint.opacityValue` independently of
  position, size, and colour.
- `ScatterInteractionStyle` controls geometry-and-outline hover, press,
  selection, focus, and dimmed states. The renderer uses resolved marker paths
  for point-accurate two-dimensional hits, including unsorted data.

Scatter channels, legends, tracking values, tables, CSV, artifacts, hydration,
and generated Dart share the same portable configuration. See
[Chart types: Scatter](../docs/guides/chart-types.md#scatter-charts).

### Candlestick charts

- `CandlestickDataPoint` carries typed open, high, low, and close values while
  retaining the shared Cartesian X identity.
- `CandlestickChartStyle`, `CandlestickPointStyle`, and `CandlestickTheme`
  resolve rising, falling, doji, wick, body, width, and spacing presentation.
- `CandlestickAnimationStyle` controls entrance and compatible OHLC update
  motion; `LiveStreamController.upsertLatestCandlestick` revises or appends the
  active candle without rebuilding the chart widget tree per sample.
- `CandlestickDensityGrouping` produces viewport-aware OHLC aggregates while
  raw tables, CSV, artifacts, and generated Source retain source values.

One Candlestick series can share a plot with Line, Area, and Scatter overlays.
The family uses the common axes, annotations, navigator, interaction group,
Workbench, data table, artifact, and generated-source contracts. See
[Candlestick charts](candlestick_charts.md).

### Heatmap charts

- `HeatmapDataPoint` keeps X position, Y position, and the independently
  measured colour value in one typed cell. `HeatmapDataPoint.missing` retains
  an explicit matrix position without inventing a numeric value.
- `HeatmapCellBounds` optionally gives one cell an unequal axis-aligned
  rectangle. The same bounds drive data extents, culling, painting, hit
  testing, semantics, selection, artifacts, Data mode, and generated Source.
- `HeatmapColorScale` provides validated sequential, diverging, and threshold
  scales with fixed or automatic domains, palette reversal, clamping, a
  semantic midpoint, missing-cell colour, and portable formatter descriptors.
- `HeatmapSharedColorDomain` derives one JSON-safe continuous domain across
  independent series and applies it without merging panels or renderers.
- `HeatmapChartSeries` controls cell dimensions, gaps, borders, corners,
  contrast-aware labels, `HeatmapValueFilter`, and `HeatmapAnimationStyle`.
- `HeatmapValueFilter` retains one inclusive measured-value window and either
  dims or hides excluded finite cells without changing the source matrix,
  colour domain, table, generated Source, or artifact.
- `HeatmapColorLegend` renders the same continuous ramp or discrete threshold
  bands used by the chart. Continuous legends can opt into an accessible range
  control through `onValueFilterChanged`.
- `HeatmapColorLegendGroup` presents the visible colour axes for multiple
  Heatmap series in one compact horizontal or vertical surface and routes
  independent filter changes by series ID.
- `HeatmapSelectionExpansion` extends native rectangle mark selection from the
  cells touched by the brush to their complete source rows or columns while
  preserving series identity and hide-filter exclusions.
- `HeatmapMatrixDomain`, `HeatmapViewportRequest`, `HeatmapTileKey`,
  `HeatmapTileRequest`, and `HeatmapTile` define a finite regular matrix and
  deterministic viewport-to-tile contract without entering the renderer.
- `HeatmapTileSource` is the host transport boundary for asynchronously loaded
  cells. `HeatmapViewportController` coalesces viewport requests, deduplicates
  in-flight loads, rejects stale publication, maintains a bounded LRU cache,
  and materializes the current resident cells as an ordinary immutable
  `HeatmapChartSeries`.

Heatmap is a native Cartesian family and uses the ordinary numeric or
categorical X/Y axes, annotations, zoom, pan, scrollbars, tracking, tooltip,
selection, keyboard, and Workbench contracts. Multiple Heatmap series may
share one matrix while retaining independent units, colour scales, filters,
portable identity, and generated Source. Heatmap compositions may otherwise
only add Line overlays such as prepared density contours.

The renderer indexes the complete matrix while materializing and painting only
the visible window. Interactive semantics are capped for dense matrices while
the focused and selected cells remain prioritized and fully announced.
Entrance motion supports fade or scale with row, column, radial, or
simultaneous order; compatible value updates interpolate by stable cell
identity and reduced motion resolves immediately.

For a conceptual matrix that should not remain fully resident, the host keeps
explicit X/Y axis bounds from `HeatmapMatrixDomain`, forwards visible bounds
to `HeatmapViewportController`, and renders its current snapshot. Source
futures never run in the render object. Workbench and portable output preserve
the resident snapshot rather than serializing the provider or claiming that
the complete conceptual matrix is present.

Artifacts preserve inline or columnar cells, explicit missing state and cell
bounds,
categorical axes, colour scale, styling, and animation. Native Data mode offers
matrix and long projections; explicit rectangles automatically select lossless
long form with X/Y minimum and maximum fields. Generated Dart, Grammar, fluent
modifiers, and tool configuration reconstruct the same family. See
[Heatmap charts](heatmap_charts.md).

### Line and Area charts

- `PathAnimationStyle` opts a Line or Area series into leading-edge entrance
  reveal and compatible mounted data-update interpolation, including
  stable-identity append, boundary removal, and rolling-window snapshots. Both
  behaviors are disabled by default.
- `PathEntranceAnimationMode` and `PathDataUpdateAnimationMode` select the two
  independent motion phases; timing and easing come from
  `ChartTheme.animationTheme`.
- `BravenChartController.replaySeriesEntrance()` replays the entrance phase for
  mounted Line and Area series without changing their data.
- Path motion uses the final chart bounds and standard renderer throughout,
  keeps Area fill and outline synchronized, and yields immediately to reduced
  motion or zero-duration themes.

Line and Area work with `BravenChartWorkbench` for package-owned
Chart/Data/Split presentation, including a pointer- and keyboard-resizable
wide Split divider. Tables and artifacts always expose target data rather than
transient animation frames. Controller-fed streaming tails retain their
dedicated animation and do not also run path interpolation. See
[Line and Area charts](line_area_charts.md).

### Range Area charts

- `RangeAreaDataPoint` owns finite low/high values at one ordered X position;
  `.gap()` represents a missing interval explicitly.
- `RangeAreaChartSeries` controls interpolation, fill/gradient, independent
  boundary styles, side closure, markers, typed labels, hit testing, gaps, and
  path motion.
- `RangeAreaInteractionDetails` carries low, high, midpoint, and span through
  tracking, hits, summaries, callbacks, keyboard navigation, and semantics.
- `RangeAreaTheme` provides light, dark, high-contrast, and custom defaults.

Range Area composes with ordinary Cartesian Line, Area, Scatter,
Candlestick, and additional Range Area series. Data/Split/Source, CSV,
artifacts, hydration, generated Dart, and typed agent input preserve the
atomic interval. See [Range Area charts](range_area_charts.md).

### Bar charts

- `BarChartStyle`, `BarPatternStyle`, `BarFillPattern`, `BarTrackStyle`, `BarLollipopStyle`, `BarBulletStyle`, `BarBulletRange`, `BarDivergingStyle`, `BarDivergingRole`, `BarTargetMarkerStyle`, and
  `BarErrorBarStyle` control mark styling and analytical references.
- Pattern fills are clipped to canonical rounded bar geometry, choose an
  automatic contrast colour when none is supplied, and are repeated by the
  legend swatch as a non-colour series cue.
- Bullet ranges provide ordered qualitative context behind one dominant actual
  measure and reuse `targetValues` for the benchmark marker.
- `BarLollipopStyle` replaces the filled body with a stem and circular value
  marker while preserving canonical labels, animation, interaction, and
  horizontal transposition.
- `ParetoCategory` and `ParetoChartData` validate and stably rank categorical
  values, expose aligned raw and cumulative point sets, and locate cumulative
  thresholds for mixed bar-and-line Pareto compositions.
- `HistogramChartData`, `HistogramBin`, `HistogramBinningMethod`, and
  `HistogramValueMode` transform continuous samples into equal-width count,
  percentage, or density bars while preserving interval boundaries.
- `BarLayoutMode.divergingStacked` normalizes positive response magnitudes,
  centers one neutral series, stacks negative and positive roles outward, and
  preserves raw values for tooltips and tables.
- `BarMotionStyle` and `BarAnimationOrder` sequence keyed entrances, updates,
  and baseline-collapse exits together, forward, reverse, center-out, or
  edges-in while honoring the chart animation theme and reduced-motion
  preference.
- `BarLabelStyle` controls content, placement, chart-wide collision handling,
  backgrounds, callouts, and stack totals.

### Pie charts

- `PieChartSeries.fromMap` converts insertion-ordered category/value pairs into
  stable slices; the explicit constructor preserves source point metadata and
  optional per-point colors.
- `radiusValues`, `PieSliceRadiusConfig`, and `PieSliceRadiusScale` optionally
  encode one complete labeled second metric as slice radius. The default area
  scale is perceptual; linear radius mapping is opt-in.
- `PieChartStyle` controls start angle, direction, radius, physical slice
  separation, fixed or `PieBorderColorMode` slice-derived borders, selection
  explode offset, and optional per-series opacity, `PieCornerTreatment`,
  elevation, and animation overrides.
- `RadialSelectionStyle` keeps selection identity unchanged while choosing
  `RadialSelectionEffect.explode` or a centroid-scaled foreground
  `RadialSelectionEffect.lift` with configurable scale, radial offset, and
  backdrop blur.
- `PieChartTheme`, `PieElevationStyle`, and `PieAnimationMode` provide
  theme-level radial styling, independently configurable shadows/glows,
  callouts, and motion defaults.
- `RadialDataTransitionMode` separates identity-aware mounted data changes
  from first-mount/replay entrance motion.
- `PieDataLabelConfig`, `PieDataLabelPosition`, `PieDataLabelContent`, and
  `PieDataLabelCollisionStrategy` control label eligibility, placement, and
  optional shared-`LabelStyle` callouts. `secondaryContent`,
  `secondaryPosition`, and `secondaryCalloutStyle` add one independently
  styled label at the opposite placement. Signed `insideOffset` moves inside
  labels radially within their slice, while `outsideOffset` controls the
  compact outside-label lanes.
- `RadialValueFormatter` supplies complete value/share/radius text reused by
  labels, legends, tooltips, center content, and accessibility as applicable.
- `RadialSliceGroupingConfig` keeps source rows while projecting small slices;
  `RadialSliceRadiusAggregation` makes grouped second-metric semantics
  explicit when variable radius is also enabled.

A chart accepts exactly one pie series and cannot mix radial and Cartesian
series. Pie charts do not use axes, crosshairs, scrollbars, pan, zoom, or
Cartesian annotations. Contributions must be finite and non-negative; zero
values remain portable but do not paint a slice.

Pie label callouts use `LabelStyle`; legends use the shared `LegendStyle`; and
tooltips use either an explicit non-default `TooltipConfig.style` or
`ChartTheme.interactionTheme.tooltipStyle`. Slice, legend, and linked table
selection resolve the same durable tooltip, which clears with selection and
re-anchors after geometry or responsive layout changes.

### Donut charts

- `DonutChartSeries.fromMap` creates one insertion-ordered category whole with
  a required non-zero center opening.
- `DonutChartStyle` adds validated `innerRadiusFactor` and
  `sweepAngleDegrees` values to the shared radial style used for start angle,
  direction, outer radius, gaps, borders, gradients, corners, elevation,
  selection, and animation.
- `DonutCenterContent` supplies optional portable label and value text through
  `DonutCenterValueMode.total`, `selectedValue`, `selectedOrTotal`, or
  `custom`, with series-level `LabelStyle` overrides.
- `PieChartTheme.centerLabelStyle` and `centerValueStyle` provide theme
  defaults for measured center text.
- `BravenChartPlus.donutCenterBuilder`, `onDonutCenterTap`, and
  `DonutCenterData` provide runtime Flutter composition and an accessible
  center action inside the package-owned circular interaction shell.
- Optional radius values use `RadialSliceRadiusConfig` and never cross the
  shared circular opening.

Standalone Donut is single-series, has no Cartesian axes/pan/zoom/crosshair, and shares
the Pie category table, CSV, tooltip, legend, selection, controller, artifact,
and accessibility contracts. Pie and Donut also accept the runtime-only
`BravenChartPlus.radialLegendItemBuilder`, whose `RadialLegendItemData` gives
host widgets resolved category, value, share, color, selected state, and
grouped source points while the package retains layout, activation, and
semantics. Runtime legend and center builders/actions must be rebound after
artifact hydration; portable legend style and `DonutCenterContent` remain the
preview/restoration fallback. See [Donut charts](donut_charts.md).

### Concentric Donut charts

- Two or more `DonutChartSeries` values form one Concentric Donut composition;
  every series keeps its independent total, formatter, grouping, source rows,
  and durable `(seriesId, pointIndex)` identity.
- `ConcentricDonutConfig` controls plot-level inner/outer radius factors, ring
  gap, source-to-radial order, optional thickness weights keyed by series ID,
  legend grouping, and one portable center fallback.
- `ConcentricRingOrder` chooses whether the first source series is outside or
  inside. `ConcentricDonutLegendMode` provides grouped ring sections or a flat
  sequence whose items retain ring identity.
- `DonutCenterData.rings` exposes one `DonutCenterRingSummary` per series;
  selected ring, series, and point identity remain available to runtime center
  builders.
- `RadialLegendItemData` adds ring index, ring count, physical position, and
  ring total for custom Concentric legend content.
- Every ring accepts the shared `RadialSelectionStyle`. A lifted selection
  scales and offsets the selected slice above the complete composition while
  backdrop blur is coordinated across all rings without reallocating bands.

The native table adds Ring identity and CSV adds the stable Series ID. Shares
are calculated within each ring. Outside labels use one cross-ring collision
layout. Chart/Data/Split/Source workbenches generate the exact
`ConcentricDonutConfig`, including deterministic ring weights. Artifacts
declare `series.donut.concentric.v1` and preserve the chart-level composition,
every ordinary Donut series document, selection, portable center, and preview.
See
[Concentric Donut charts](concentric_donut_charts.md).

### Polar Column and Rose charts

- `PolarColumnChartSeries.fromMap` creates stable equal-angle categories whose
  numeric values grow outward against a radial scale.
- `PolarColumnChartSeries.rose` selects the named Nightingale/Rose preset. It
  keeps equal angular bandwidth and defaults to area-correct radial scaling.
- `PolarColumnStyle` controls corner radius, opacity, border treatment,
  baseline-to-value `PolarColumnGradientStyle`, `PolarColumnShadowStyle`,
  direct value-label placement/style, and `PolarColumnAnimationMode` entrance
  treatment. Per-category colors may be supplied through
  `columnColors` or point styles. `maximumVisibleDataLabels` places a
  deterministic upper bound on painted value labels without removing values
  from interaction, semantics, tables, or portable documents.
- `PolarColumnChartSeries.targetValues` and
  `PolarColumnTargetMarkerStyle` provide optional absolute per-category target
  ticks. `PolarChartConfig.thresholds` accepts pane-wide `PolarThreshold`
  reference arcs with optional labels and dash patterns.
- `PolarColumnInterval` stores absolute lower/upper endpoints for one category.
  `PolarColumnIntervalStyle` renders them as a radial whisker with tangential
  caps or as a compact annular range band. Intervals are supported by
  ordinary, layered, and grouped compositions; stacked contributors reject
  them because cumulative placement would make the interval ambiguous.
- `PolarChartConfig` groups the dedicated `PolarPaneConfig`,
  `PolarCategoryAxisConfig`, `PolarNumericAxisConfig`, and
  `PolarColumnCompositionConfig` contracts. The angular axis exposes
  `maximumVisibleLabels`, `maximumVisibleGridLines`, outward `labelOffset`, and
  independent `PolarLabelStyle`. The radial axis can place styled labels on
  the start, middle, or end sweep ray, rotate that ray, and offset labels along
  it. Spatial fit may show fewer labels, while every category retains its exact
  angular band.
- `PolarColumnCompositionMode.layered` reuses the full category band for every
  series. `grouped` divides it into stable declaration-order sub-bands;
  `groupInnerPadding` controls the fractional gap inside each series slot.
- `PolarColumnCompositionMode.stacked` accumulates raw contributors in
  declaration order. Positive and negative values use separate accumulators
  from zero, so opposite signs never cancel in the rendered geometry.
- `PolarRadialScaleMode.linear` maps equal value differences to equal radial
  distances; `areaCorrect` maps equal value proportions to equal annular-sector
  areas.
- `RadialSelectionStyle` provides the same durable explode or lift selection
  vocabulary used by the partition-radial families without converting values
  into shares.

Polar Column accepts one or more compatible, non-empty series with finite,
signed values. Multiple series layer in declaration order, divide each
category into grouped angular sub-bands, or form a diverging stack. They must
share the same category labels/order, preset, and unit so they can use one
angular axis and one numeric radial scale. Stacked explicit bounds must contain
zero. Polar Column cannot mix with Cartesian or partition-radial series. Its
native table is
`# | Category | Series | Value (unit)`, and Chart/Data/Split/Source views,
controller selection, deterministic artifacts, hydration, and generated Dart
all preserve that value-only meaning. Artifacts declare
`series.polar.column.v1`; multi-series documents additionally declare
`chart.polar.multiple-series.v1`, while grouped documents also declare
`chart.polar.grouped-series.v1` and stacked documents declare
`chart.polar.stacked-series.v1`. Documents with targets, thresholds, or
intervals also declare `series.polar.column.targets.v1`,
`chart.polar.thresholds.v1`, or `series.polar.column.intervals.v1`. The native
appearance and axis-label additions negotiate
`series.polar.column.appearance.v1` and `chart.polar.labels.v1`. The native
table conditionally appends `Target (unit)` and `Lower (unit) | Upper (unit)`
only when the corresponding data exists. See
[Polar Column and Rose charts](polar_column_charts.md).

## Axes, normalization, and layout

- `XAxisConfig`, `XAxisPosition`, `CategoryAxisConfig` — top, bottom, or
  mirrored placement, numeric bounds, general tick-label rotation,
  visible-domain uniform tick budgets, rotation-aware collision thinning,
  native categorical labels, density, wrapping/ellipsis, compatibility
  rotation, and automatic scrollable viewports.
- `YAxisConfig`, `YAxisPosition` — independent Y-axis identity, units,
  position, bounds, and labels.
- `MultiAxisConfig`, `NormalizationMode` — multi-axis policy.
- `NormalizationDetector`, `RangeRatioCalculator`, `SeriesAxisResolver` —
  automatic multi-axis helpers.
- `AxisLayoutManager`, `MultiAxisLayout`, `MultiAxisNormalizer`,
  `MultiAxisPainter`, `AxisColorResolver` — advanced layout and rendering
  integration.
- `AxisSwapMode` and `BravenChartController` — visible-axis slot behavior and
  runtime series selection.
- `PolarPaneConfig`, `PolarCategoryAxisConfig`, and `PolarNumericAxisConfig` —
  independent angular-category and radial-value axes for Polar Column/Rose.

## Interaction

- `InteractionConfig` — interaction configuration root.
- `CrosshairConfig`, `CrosshairMode`, `CrosshairDisplayMode` — crosshair and
  tracking behavior, including opt-in retention of the last guide after
  pointer exit or focus loss.
- `CrosshairStyle` — chart-specific center-line color, width, dash pattern,
  stroke cap, plot-clipped focus-band color and width, and coordinate-label
  appearance.
- `InteractionTheme` — theme-level crosshair line and focus-band defaults,
  tooltip, selection, hover, and zoom appearance.
- `TooltipConfig`, `TooltipStyle`, `TooltipTriggerMode` — marker and tracking
  tooltip behavior.
- `InteractionCallbacks` and chart callbacks — point, series, background, and
  annotation events.
- `ScrollbarConfig` — chart scrollbar presentation.
- `ChartInteractionGroupController`, `ChartInteractionGroupOptions`, and
  `ChartXViewport` — caller-owned data-X cursor and X-only viewport
  synchronization across independent Cartesian charts.
- `CartesianNavigator` — full-domain Line or Area overview with a draggable
  and resizable X selection shared by synchronized Line, Area, Bar, Scatter,
  and Candlestick charts.
- `CartesianNavigatorBehavior` — pan, resize, live-preview, and minimum-span
  policy.
- `CartesianNavigatorSnapPolicy` and `CartesianNavigatorSnapMode` — exact,
  fixed-interval, or ordered-value edge snapping.
- `CartesianNavigatorStyle` — theme-aware selection, mask, handle, interaction,
  focus, disabled, and touch-target styling.
- `CartesianValueSummaryConfig` — persistent, policy-resolved Cartesian datum
  display for Line, Area, Bar, Scatter, Candlestick, mixed, and multi-axis
  charts.
- `CartesianValueSummaryPresentation`, `CartesianValueSummaryValuePolicy`,
  `CartesianValueSummaryContent`, `CartesianValueSummaryStyle`, and
  `CartesianValueSummaryController` — fixed or draggable presentation,
  deterministic value precedence, automatic or custom rows, tri-state styling,
  pinning, placement, and accessibility behavior.
- `ChartContextMenuConfig`, `ChartContextAction`, and `ChartOverlayAction` —
  typed host actions exposed through context menus or an opt-in compact in-chart
  button; Workbench builders receive the same stable mounted-chart handle.

## Annotations

- `ChartAnnotation` — sealed annotation base type.
- `PointAnnotation`, `RangeAnnotation`, `TextAnnotation`,
  `ThresholdAnnotation`, `TrendAnnotation`, `ChordAnnotation`, `PinAnnotation`,
  and `LegendAnnotation` — supported overlays.
- `AnnotationStyle` and annotation theme types — common presentation.
- `AnnotationController` and `ChartController` — programmatic annotation
  creation, updates, lookup, and removal.

## Streaming and live data

- `StreamingConfig`, `AutoScrollConfig` — buffered viewport behavior.
- `StreamingController` — follow-latest, paused, and user-controlled viewport
  modes.
- `LiveStreamController` — direct, frame-coalesced point ingestion with bounded
  buffers, pause/resume, and optional external X-viewport ownership through
  `manageViewport: false`; `dataRevision` plus O(1) retained endpoints support
  display-frame-coalesced follow-latest hosts.
- `StreamingBuffer` — bounded point storage and data bounds.

## Loading and empty states

- `ChartLoadingConfig` — chart skeleton, circular progress, linear progress, or
  a custom state builder.
- `ChartLoadingSkeletonStyle` — animation, trace colors, geometry, optional
  grid, and edge fading.
- `ChartEmptyStateConfig` — empty-state title, guidance, semantics, icon, or
  custom builder.

## Theming

- `ChartTheme` — complete chart theme and built-in presets.
- `GridStyle`, `AxisStyle`, `SeriesTheme`, `InteractionTheme`,
  `TypographyTheme`, `AnimationTheme`, `AnnotationTheme`, `LegendStyle`, and
  `LabelStyle` — component-level themes.
- `GridConfig` — per-chart grid visibility and style.

## Configuration and tool-driven charts

- `ChartConfigBuilder` — converts serializable configuration into chart input,
  including advanced bar composition, analytical references, label layout,
  native categories, and radial chart contracts.
- `ChartAgentInterface` and chart tool schemas — contracts for tool-driven or
  agent-assisted chart construction.

## Portable chart artifacts and data tables

- `BravenChartWorkbench`, `ChartWorkbenchController`, and
  `ChartWorkbenchHandle` — one mounted Chart/Data/Split/Source product surface
  with responsive fallback, content-aware/resizable Split panes, snapshot
  freshness, independent table/source/artifact operation state, and
  host-defined actions. Source is opt-in through `availableDisplayModes`.
- `ChartContextAction`, `ChartContextInvocation`, `ChartContextHit`, and
  `ChartContextMenuConfig` — typed, renderer-neutral host commands for native
  chart context menus reached by secondary click, keyboard, or opt-in touch
  long press. `BravenChartWorkbench.contextActionsBuilder` supplies the same
  stable handle as its visible `actionsBuilder`.
- `ChartOverlayAction`, `ChartOverlayActionBuilder`, and
  `ChartOverlayActionButtonConfig` — an independently opt-in compact chart
  button with host-owned callback, enabled state, semantics, placement, target
  size, icon size, and Material style. Its default is a translucent,
  zero-elevation treatment derived from the inherited `ColorScheme`. A
  Workbench builder receives its stable handle; a direct `BravenChartPlus`
  builder works without Workbench state.
- `ChartWorkbenchGroupController` and `ChartWorkbenchScope` — nestable,
  caller-owned system or chart-family coordination for shared display mode,
  selector visibility, and safe common-mode reconciliation across mounted
  Workbenches.
- `ChartDartSourceGenerator`, `ChartDartSourceOptions`, and
  `ChartGeneratedSource` — deterministic direct Dart for an effective chart
  document, with bounded inline data, completeness metadata, runtime-placeholder
  warnings, and optional durable view-state restoration.
- `ChartSourceRefreshPolicy` and `ChartWorkbenchSourceState` — manual,
  mode-entry, or revision-aware source refresh with stale-result retention and
  structured recovery.
- `ChartDataTable.preferredWidthFor` — projection-aware native column width for
  host-owned Split sizing.
- `ChartDocumentRevision` and `ChartPointRef` — opaque snapshot freshness and
  canonical series/index identity for revision-safe table focus and durable
  point selection.
- `BravenChartController.focusPoint`, `focusPoints`, `selectPoint`, and
  `selectPoints` — linked-surface commands that reject stale or invalid refs;
  selected refs round-trip through `ChartViewState`.
- `BravenChartController.extractDocument` — captures a stable effective chart
  document and optional durable view state from a mounted chart.
- `BravenChartController.extractArtifact` — composes the document with
  metadata and an optional revision-bound preview.
- `ChartArtifact`, `ChartDocument`, `ChartViewState`, and `ChartPreview` — the
  portable envelope and its renderer-independent parts.
- `ChartArtifactJsonCodec` — canonical JSON encode/decode with schema,
  capability, and resource-limit validation.
- `ChartDocumentHydrator`, `HydratedChartConfiguration`, and
  `HydratedBravenChart` — validated restoration into fresh public chart models.
- `ChartDataScope` and `ChartDataStorage` — choose the effective data
  projection and inline point/column storage strategy.
- `RadialFormatterDocumentDescriptors` — series-keyed portable descriptions
  for Pie/Donut value, share, radius, and center callbacks. Extraction fails
  closed when a runtime radial formatter has no descriptor.
- `ChartTableModel`, `ChartTableOptions`, and `ChartDataTable` — exact-X wide
  rows (one X value with one column per series), lossless long rows, or native
  radial `Category | Value | Radius? | Share` rows; plus sorting,
  virtualization, theming,
  bounded dataset/row clipboard copy, and raw-value CSV export with automatic
  web download or host delivery callbacks. Pass `selectedPointRefs` to mirror
  durable chart or slice selection into rows.
- `ChartDataBlobCodec`, `ReferencedPayload`, and `ChartDataResolver` — host
  controlled external payload persistence and checksum-verified resolution.
- `ChartRuntimeBindings` and its formatter, callback, tooltip, and extension
  registries — explicit resolution of executable host behavior by stable IDs.
- `ChartArtifactValidationLimits`, `ChartArtifactMigration`, and
  `ChartArtifactDiagnosticCodes` — bounded decoding, adjacent schema upgrades,
  and machine-readable failure handling.
- `ChartComparisonInput`, `ChartSeriesMatch`, and `ChartComparisonOptions` —
  explicit multi-document identity, alignment, baseline, duplicate, and unit
  rules without name inference.
- `ChartComparisonBuilder`, `ChartComparisonModel`, and
  `ChartComparisonExporter` — source-preserving exact-X, timestamp-tolerance,
  or independent alignment with missing cells, safe deltas, and labelled
  derived CSV columns.

See [Portable chart artifacts](chart_artifacts.md) for the end-to-end guide and
copyable examples, [Chart Workbench](chart_workbench.md) for the reusable
single-chart surface, [Chart family integration](chart_family_integration.md)
for new built-in family requirements, and
[Chart Document Comparison](chart_comparison.md) for multi-document alignment
and export.

See [Pie charts](pie_charts.md) for the radial data contract, labels,
interaction, table projection, artifacts, and accessibility behavior.

## Export policy

Only symbols exported by `package:braven_charts/braven_charts.dart` are part of
the supported public package surface. Files under `lib/src` are implementation
details unless re-exported by that entrypoint.
