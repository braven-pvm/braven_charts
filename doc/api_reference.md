# Public API overview

Import the supported package surface through one entrypoint:

```dart
import 'package:braven_charts/braven_charts.dart';
```

Pub.dev generates the complete member-level API reference from Dart
documentation comments. This page is a human-oriented map of the main exported
types and where to begin.

## Chart widget and series

- `BravenChartPlus` — primary chart widget, including `fromValues` and
  `fromMap` convenience factories.
- `ChartSeries` — common immutable series model.
- `LineChartSeries`, `AreaChartSeries`, `BarChartSeries`,
  `ScatterChartSeries`, `PieChartSeries`, and `DonutChartSeries` — concrete
  renderable series.
- `ChartDataPoint`, `DataRange`, `ChartType` — core data types.
- `LineInterpolation`, `SeriesStyle`, `SegmentStyle`,
  `DataPointLabelConfig`, `SeriesInlineLabelConfig` — series presentation.

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
- `PieChartTheme`, `PieElevationStyle`, and `PieAnimationMode` provide
  theme-level radial styling, independently configurable shadows/glows,
  callouts, and motion defaults.
- `RadialDataTransitionMode` separates identity-aware mounted data changes
  from first-mount/replay entrance motion.
- `PieDataLabelConfig`, `PieDataLabelPosition`, `PieDataLabelContent`, and
  `PieDataLabelCollisionStrategy` control label eligibility, placement, and
  optional shared-`LabelStyle` callouts.
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

Donut is single-series, has no Cartesian axes/pan/zoom/crosshair, and shares
the Pie category table, CSV, tooltip, legend, selection, controller, artifact,
and accessibility contracts. Pie and Donut also accept the runtime-only
`BravenChartPlus.radialLegendItemBuilder`, whose `RadialLegendItemData` gives
host widgets resolved category, value, share, color, selected state, and
grouped source points while the package retains layout, activation, and
semantics. Runtime legend and center builders/actions must be rebound after
artifact hydration; portable legend style and `DonutCenterContent` remain the
preview/restoration fallback. See [Donut charts](donut_charts.md).

## Axes, normalization, and layout

- `XAxisConfig`, `CategoryAxisConfig` — numeric bounds plus native categorical
  labels, density, wrapping/ellipsis, rotation, and automatic scrollable
  viewports.
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

## Interaction

- `InteractionConfig` — interaction configuration root.
- `CrosshairConfig`, `CrosshairMode`, `CrosshairDisplayMode` — crosshair and
  tracking behavior.
- `TooltipConfig`, `TooltipStyle`, `TooltipTriggerMode` — marker and tracking
  tooltip behavior.
- `InteractionCallbacks` and chart callbacks — point, series, background, and
  annotation events.
- `ScrollbarConfig` — chart scrollbar presentation.
- `ChartInteractionGroupController`, `ChartInteractionGroupOptions`, and
  `ChartXViewport` — caller-owned data-X cursor and X-only viewport
  synchronization across independent Cartesian charts.

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
  buffers and pause/resume.
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
