# Changelog

All notable changes to the braven_charts package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.17.1 - 2026-08-11

### Fixed

- Restored the declared Flutter 3.35 floor. `flex_color_picker` was constrained
  to `^3.8.0`, whose only release requires Flutter `>=3.38.0`, so version
  solving failed outright for every consumer on Flutter 3.35, 3.36, or 3.37 —
  the package could not be installed across part of the range it advertised.
  The constraint is now `^3.7.2`, which still resolves to the latest release on
  current Flutter and falls back to `3.7.2` on older toolchains.

### Changed

- Rewrote the package description to state what the package is and lead with the
  capabilities developers search for, rather than internal subsystem names.
  Package directories and pub.dev render this text verbatim.
- Replaced the ultra-wide README strip with a near-square thirteen-family hero
  that remains legible in package-directory and social-card layouts.

### Added

- A dedicated mobile-app showcase with six live phone-native compositions for
  endurance, recovery, live sport, training, habits, and urban mobility. The
  mobile experience is directly routable, discoverable from desktop and phone
  navigation, featured in the main Gallery, and included as the second pub.dev
  screenshot.
- Deterministic Line Race playback with a portable model and controller,
  play/pause, seek, step, speed and reduced-motion behavior, interpolated
  frontiers, collision-aware endpoint labels, artifact/source round-tripping,
  and a complete F1-style showcase preset.
- Bar label rotation, portable static or lazy hierarchical drill-down with
  breadcrumb navigation, and deterministic Bar Race playback with stable rank
  identity, one animation clock, configurable period/aggregate presentation,
  artifacts, generated source, accessibility, and showcase controls.
- A CI dependency-floor gate that proves every direct hosted dependency admits
  a version compatible with the Dart and Flutter floors declared by the
  package, including a non-vacuous regression for the fixed colour-picker
  constraint.

## 0.17.0 - 2026-08-03

### Added

- Per-series `showInTrackingTooltip` control. Set it to `false` to omit the
  complete series row from the crosshair tracking panel while preserving the
  rendered series, tracked snapshot, intersection markers, selection, and
  independently configured axis-side tracking labels.

- A measure unit on the Cartesian grammar marks: `unit:` on
  `BravenChart.geomLine()`, `geomArea()`, `geomBar()`, `geomPoint()` and
  `geomCandlestick()`, carried onto the lowered `ChartSeries.unit` and reversed
  back into generated Dart source. A config-authored Cartesian chart whose
  series declares a unit is no longer refused for it.
- `SeriesMark<T>`, a sealed intermediate between `Mark<T>` and the six mark
  families that lower to a series — the five Cartesian ones plus `RadialMark` —
  declaring `unit` once for all of them. `TrendMark`, `ThresholdMark`,
  `BandMark` and `PointMark` stay on `Mark<T>`: they lower to annotations,
  which have no unit, so they structurally cannot carry one. Existing code is
  unaffected; `unit` remains readable on every radial mark exactly as before.
- Per-point metadata on the four Cartesian geometry marks: `label:` and
  `pointKey:` on `BravenChart.geomLine()`, `geomArea()`, `geomBar()` and
  `geomPoint()`. Both are accessors (`String? Function(T)`) carried onto
  `ChartDataPoint.label` and `ChartDataPoint.pointKey`, and both are reversed
  back into generated Dart source. An empty string means "this point has none",
  which is what lets a partially labelled or partially keyed series round-trip.
- A `duplicatePointKey` Grammar diagnostic: a `pointKey` accessor that yields
  the same key for two rows of one mark is refused by name rather than lowering
  to a series whose selection identity is ambiguous. The Cartesian counterpart
  of `duplicateRadialCategory`.
- `isXOrdered:` on `BravenChart.geomLine()`, `geomArea()`, `geomBar()` and
  `geomPoint()`, carried onto `ChartSeries.isXOrdered` and reversed back into
  generated Dart source. It is a DECLARATION, never inferred from the data:
  a chart that does not declare it stays unordered even when its rows happen to
  arrive sorted, so nearest-point behaviour cannot change underneath an
  existing chart. `geomCandlestick()` does not take it —
  `CandlestickChartSeries` is ordered by its own contract.
- A named refusal for a per-point `segmentStyle`, in two sentences because it is
  two boundaries. A style setting `strokeWidth` or `dashPattern` is reported as
  one "no V1 … mark carries"; a COLOUR-ONLY style is reported as a per-point
  segment colour that a chain paints from `colorBy` + `colorEncoding`, which the
  reverser cannot recover from the baked colours. Either way it beats falling
  into the generic "does not reproduce exactly" sentence. The style is
  deliberately not carried yet: it needs a row-field kind the synthesised rows
  do not have, and it shares its slot with `LineMark.colorBy`, which already
  bakes `segmentStyle.color` per point.
- Generated Dart source now reverses the LEGACY SINGLE-AXIS chart: a
  `BravenChartPlus` built the ordinary way — a widget-level `yAxis` and no
  per-series binding — emits a `BravenChart` chain instead of being refused
  with the axis sentence. Only a chart that binds SOME series and not others
  still reaches that refusal — an all-unbound chart refused for some OTHER
  reason is no longer told to change a binding that was never the problem.
- A Range Area grammar geometry: `BravenChart.geomRangeArea(low:, high:)`,
  lowering to a real `RangeAreaChartSeries` and reversed back into generated
  Dart source. `low`/`high` are nullable accessors — returning null from both
  at a row expresses a gap (`RangeAreaDataPoint.gap`); returning null from
  exactly one raises `incompleteRangeAreaInterval`. The mark carries the
  range-area-native fields (interpolation, tension, fill opacity, border mode,
  both boundary styles, gap connection, boundary markers, marker radius, label
  configuration and hit-test mode); `fillGradient` and `pathAnimation` are not
  carried and a band using either is refused by name rather than emitted
  without it.
- Collision-aware Cartesian series callouts through `SeriesCalloutConfig` and
  per-series `SeriesCalloutSpec` overrides. Line and Area charts can place
  stable connector-backed labels in a shared bounded lane, choose
  follow-anchor or compact packing, prioritize dense labels, and configure
  label, connector, glow, and content-sized lane-panel presentation without
  changing legend, selection, or tracking participation. The complete portable
  configuration round-trips through artifacts, hydration, JSON, generated
  Config Dart, fluent APIs, and AI surface definitions; typed Chart Grammar
  reports its current callout limitation explicitly.

### Changed

- **`BravenPlot` mounts a single-axis chain as the legacy single-axis chart.**
  When a spec declares exactly one Y axis and no mark names it, the axis now
  reaches `BravenChartPlus` as a widget-level `yAxis` with the series left
  unbound, instead of as an inline `yAxisConfig` on every series. This is what
  makes a chain and the config chart it reverses to the SAME chart rather than
  merely similar ones.

  **Rendering asks two different questions here, and they have different
  answers.** Read both before upgrading.

  - **A chain reversed from a config chart renders identically: no change.**
    Both mounts tint the Y-axis tick and axis labels with the series colour —
    an axis takes its colour from the first series bound to it, and a
    widget-level axis has the chart's unbound series bound to it at render time
    — so the change is not visible. Verified in pixels rather than argued:
    eight chart shapes rendered at a fixed 600x400 host and compared as raw
    RGBA, each against the config chart it claims to be, all **0 of 240,000
    pixels differing** (`test/widgets/braven_plot_pixel_parity_test.dart`). The
    shapes are: no widget-level axis; a labelled axis; an axis declaring `min`
    and `max`; an axis the author named; a two-axis chart (the mount this must
    not touch); and the three authored-spec forms of the same. Earlier releases
    of this entry claimed the labels turned grey. That was wrong in both
    directions and is retracted: the tinting is what the legacy mount
    preserves, and the grey it described was a separate defect, now fixed (see
    below).
  - **An AUTHORED `PlotSpec` or `BravenChart` chain CHANGES appearance for six
    shapes.** The zeroes above compare two charts that both exist *after* this
    release; they say nothing about what an existing grammar chart drew
    *before* it. Where a spec declares one Y axis that no mark binds to, that
    chart is now the legacy chart — and the legacy chart honours axis settings
    the previous mount dropped. Measured by reverting
    `lib/src/grammar/braven_plot.dart` and
    `lib/src/rendering/modules/multi_axis_manager.dart` to the previous
    release, capturing every shape at the same 600x400 host, and differencing
    the frames:

    | authored single-axis shape | pixels changed (of 240,000) | in the plot area | filed under |
    |---|---|---|---|
    | axis declares `min` AND `max` | 25,885 | 20,770 | Fixed |
    | `min` only | 25,126 | 20,284 | Fixed |
    | `max` only | 23,196 | 17,854 | Fixed |
    | `scaleType: AxisScaleType.log` | 11,948 | 11,745 | Fixed |
    | `position: YAxisPosition.hidden` | 9,721 | 8,532 | Changed |
    | `visible: false` | 9,721 | 8,532 | Changed |
    | no axis declared | 0 | 0 | unchanged |
    | a plain labelled axis | 0 | 0 | unchanged |
    | an axis the author named | 0 | 0 | unchanged |

    "In the plot area" counts the differing pixels outside the 80-column
    Y-label gutter. Every row is asserted — both the parity zero and the size
    of the before/after change — by the mount divergence table in
    `test/widgets/braven_plot_pixel_parity_test.dart`, which reproduces the
    previous mount in process, so this list cannot go stale unnoticed. The four
    `Fixed` rows are described under **Fixed** below; the two hidden ones are
    the next bullet.
  - **A hidden or invisible single Y axis no longer draws horizontal grid
    lines.** `position: YAxisPosition.hidden` and `visible: false` hide the
    axis on either mount, and both mounts lay the plot area out identically;
    what changed is that the previous mount kept drawing the hidden axis'
    horizontal grid and the legacy chart does not. That accounts for the whole
    difference, measured by removing the thing at issue: with
    `GridConfig(horizontal: false)` the two mounts draw the byte-identical
    frame. Unlike the four rows above this is a behaviour change rather than a
    fix — neither mount was ignoring what the author asked for — so it is
    called out here rather than under **Fixed**.
  - **Extracted documents.** `BravenChartController.extractDocument()` on a
    single-axis chain no longer sets `series[*].axisId` or
    `series[*].inlineAxis`; the axis appears once, in `axes`. Hosts that
    persist or diff these documents will see the shape change. It is a fix, not
    a new capability: the document now matches the config chart's.

  Four shapes are DECLINED and keep the multi-axis mount verbatim: a chart with
  several declared axes; a one-axis chart whose mark names its axis (the author
  asked for the multi-axis path); a `BravenFacetPlot` panel, because faceting
  delivers the shared range `FacetScales.fixed` computes through an inline axis
  config and a widget-level axis applies `min`/`max` where an inline one does
  not, so re-mounting a panel would change what every faceted chart draws; and
  any chart carrying a series family that cannot express an unbound series
  (everything outside the five Cartesian families), which keeps the multi-axis
  mount for the whole plot rather than mounting half of it. A radial spec
  lowers to no Y axis at all and never reaches this shape.

  An axis carrying `min`/`max` is NOT declined, although the two mounts do
  disagree about it — only a widget-level axis applies the range to the Y
  domain. Declining it was measured and rejected: it changes no emitter
  refusal anywhere in the suite, and it makes the reversed chart differ from
  the chart it was reversed from by 25,885 of 240,000 pixels, 20,770 of them in
  the plot area. The reasoning is recorded in `_legacySingleAxisSeries`. That
  is the same 25,885 pixels an upgrading authored chart sees, disclosed as a
  fix below — this paragraph is about why an alternative mount was rejected,
  and is not where the user-facing change is published.

### Fixed

- **An authored single Y axis' `min`/`max` was silently ignored.** A
  `PlotSpec` or `BravenChart` chain whose one Y axis declares `min`, `max` or
  both, and whose marks do not bind to it, reached the chart only as an inline
  per-series `yAxisConfig` — and the inline path never applies a range to the
  Y domain. It was not a weaker range, it was no range: measured under the
  previous mount, an axis with `min: 100, max: 300` drew the byte-identical
  frame to the same axis carrying none, and so did `min`-only and `max`-only.
  The axis now reaches the chart as a widget-level `yAxis`, which applies it,
  and the authored chart draws exactly what the equivalent config chart draws.
  Charts relying on the old behaviour will see the plot area move: 25,885 of
  240,000 pixels for `min` and `max`, 25,126 for `min` only, 23,196 for `max`
  only, at a 600x400 host.
- **An authored single Y axis' `scaleType: AxisScaleType.log` drew log tick
  labels over a LINEAR plot.** `BravenChartPlus` takes the Y scale type from
  its widget-level axis — `widget.yAxis?.scaleType ?? AxisScaleType.linear` in
  `braven_chart_plus.dart` — and the previous mount never set one, so the data
  was mapped linearly while the axis renderer, reading the inline config,
  labelled the ticks logarithmically. The chart was not merely linear, it was
  mislabelled. Measured: under the previous mount a log axis' plot area is
  byte-identical to a plain linear chart's, and the only difference between
  them is 3,996 pixels of relabelled gutter. The data is now mapped on the
  scale that was asked for — 11,948 of 240,000 pixels against the old chart,
  11,745 of them in the plot area. Both halves are asserted in
  `test/widgets/braven_plot_pixel_parity_test.dart`.
- **A widget-level `yAxis` carrying an id of its own had nothing bound to it.**
  A series that declares neither `yAxisId` nor an inline `yAxisConfig` is bound
  to the chart's primary axis, but that binding named the auto-generated id
  `'primary_axis'` literally — and that id exists only when the widget-level
  axis carries none. Give the axis any id and every series pointed at an axis
  the chart did not have, leaving the chart's only axis unbound: axis bounds
  fell through to the `0..100` no-data fallback for a chart that plainly has
  data, and the tick and axis labels dropped from the series colour to the
  `#333333` default. Reachable three ways — a `BravenChartPlus` whose
  widget-level `yAxis` was built with `YAxisConfig.withId`; every hand-written
  `PlotSpec`, because lowering stamps `'axis-0'` on an axis that declares no id
  (including the axis it invents for a spec with no `yAxes` at all); and a
  generated chain, because extraction stamps `'y'`. The grammar shapes were
  measured at 4,658 and 5,378 of 240,000 pixels against the config chart they
  claim to be, all of it in the Y-label gutter; both are now 0. A chart whose
  series carries an inline `yAxisConfig` is deliberately unchanged: the
  widget-level axis is suppressed there, so an unbound series in that chart
  stays unbound rather than silently adopting another series' axis and scale.

- `showInLegend: false` now removes the complete series entry from every
  built-in legend path, including reusable `ChartLegend` widgets and explicit
  canvas `LegendAnnotation`s, rather than only affecting automatically
  generated legends.
- A live Range Area band with a label formatter produces generated source at
  all. `RangeAreaLabelConfig.formatter` and the nested
  `labelConfig.labels.formatter` are both refused by the document codec as
  runtime-owned, and the source capture adapter had no Range Area arm to strip
  them first — so extracting a chart carrying either failed outright with
  `runtime_binding_required` and the Source tab showed NOTHING. Both
  are now stripped to a placeholder with a `runtime_binding_required` capture
  warning naming `$.series.<id>.labelConfig.formatter` or
  `$.series.<id>.labelConfig.labels.formatter`, which is the treatment Line,
  Area, Scatter and Bar label formatters already had.

  The config emitter also gained a `// formatter:` placeholder and a
  `source_runtime_value_omitted` warning for `RangeAreaLabelConfig.formatter`.
  That branch is defensive parity with the identical branch on the data-point
  label config, and like that one it is unreachable through
  `ChartDartSourceGenerator` / `ChartGrammarSourceGenerator`: capture strips the
  formatter before the emitter ever sees it. It fires only for a caller driving
  `ChartConfigDartEmitter` directly. The user-visible fix is the capture arm
  above, not the placeholder.

### Heatmaps

- A complete native Cartesian Heatmap family. `HeatmapDataPoint` keeps X, Y,
  and the independently measured colour value in one typed cell, while
  `HeatmapDataPoint.missing` preserves explicit matrix positions without
  encoding absence as zero or NaN.
- `HeatmapColorScale` with validated sequential, diverging, and threshold
  mappings, automatic or explicit domains, semantic midpoint, palette
  reversal, clamping, missing-cell colour, formatter descriptors, and a
  reusable `HeatmapColorLegend`.
- Multiple Heatmap series in one native Cartesian chart, with independent
  units, colour domains, palettes, filters, keyboard identity, artifacts,
  generated Source, AI configuration, and lossless long-form Data projection.
  `HeatmapColorLegendGroup` presents and controls the visible colour axes in a
  compact horizontal or vertical surface.
- `HeatmapChartSeries` cell geometry, gaps, borders, corners, density-aware
  contrast labels, typed hit identity, hover/tap selection, keyboard
  row/column traversal, bounded dense-matrix semantics, Cartesian zoom/pan,
  X/Y scrollbars, and ordinary chart annotations.
- Native Heatmap rectangle selection based on rendered cell overlap, with
  portable `HeatmapSelectionExpansion` policies for touched cells, complete
  source rows, or complete source columns and a dedicated live review preset.
- Optional `HeatmapCellBounds` for unequal axis-aligned cells. Explicit
  rectangles now drive data extents, indexed viewport culling, painting, hit
  testing, semantics, selection, artifacts, generated Dart, AI configuration,
  and lossless Workbench Data fields without changing the regular-grid path.
- Reduced-motion-aware Heatmap entrance animation with fade or scale and
  simultaneous, row, column, or radial ordering. Compatible mounted updates
  interpolate measured values by stable cell identity.
- Complete portable Heatmap surfaces: inline and columnar artifacts,
  hydration, matrix and long Data projections, CSV, deterministic generated
  Dart, Chart Grammar, fluent modifiers, strict tool-driven configuration,
  and Chart/Data/Split/Source Workbench support.
- A dedicated Heatmap showcase and hosted guide with labelled activity,
  day/hour temperature, service thresholds, calendar missing cells, diverging
  correlation, and dense sparse viewport examples, plus Chart Types, Gallery,
  mobile, and native pub.dev capture integration.
- Permanent Heatmap rendering benchmarks and focused model, scale, geometry,
  interaction, accessibility, animation, artifact, table, source, Workbench,
  compact, desktop, and golden regression coverage.
- Viewport-backed Heatmap matrices through `HeatmapTileSource`,
  `HeatmapMatrixDomain`, and `HeatmapViewportController`. Hosts can load only
  the regular matrix tiles needed by the current viewport, use bounded
  overscan and deterministic LRU caching, reject stale asynchronous results,
  and publish an ordinary immutable Heatmap snapshot without adding source
  fetching to the render loop. Workbench Data, Split, Source, capture, and
  artifacts intentionally describe the current resident snapshot.
- Bounded live Heatmap mutation through typed upsert, remove, and tile
  invalidation batches. Host-owned controllers merge accepted generations into
  cached and resident tiles, protect in-flight loads, coalesce immutable
  publication, and keep the renderer, Workbench, artifacts, and generated
  source truthful to the current resident snapshot rather than serializing a
  live transport.
- Portable viewport-provider descriptors for regular and raster-backed Heatmap
  sources. Artifact hydration resolves an allowlisted host registry and creates
  a fresh host-owned runtime without serializing callbacks, credentials,
  clients, caches, decoded images, or mutation history.
- Image-backed Heatmap viewport tiles with bounded decoded-byte residency,
  stale-generation rejection, exact-once resource disposal, atomic retained
  loading/failure replacement, and optional canonical semantic companions for
  exact selection, accessibility, Workbench, artifacts, and generated source.
  The showcase includes a 512-million-cell conceptual spectrogram while the
  mounted raster and semantic snapshots remain bounded.

### Heatmap integration and performance

- Public catalog, generated README, hosted documentation, feature matrix, API
  overview, package description, and native chart-family media now describe
  thirteen built-in chart families.
- Heatmap dense geometry now caches visible quad chunks and batches regular
  borders. Repeated release audits keep 10K dense paint, resident viewport
  paint, selection overlays, live mutation, regular/raster viewport movement,
  and measured Chrome presentation within their recorded budgets without
  weakening the one-frame gates.

### Notes

- Heatmap compositions accept one or more Heatmap series and optional Line
  overlays, but do not mix with other Cartesian mark families. Remote
  clustering/aggregation pushdown, arbitrary cell polygons, and
  treemap/mosaic/vector/geographic families remain explicitly scoped to later
  work.

## 0.16.0 - 2026-07-29

### Added

- Per-series `showInLegend` and `showTrackingAxisLabel` controls. Authors can
  independently omit a rendered series from automatic legends or suppress its
  tracking-axis value labels without removing it from tracking snapshots,
  tooltips, selection, or the chart. Both flags default to `true` and
  round-trip through every concrete family, `copyWith`, JSON, artifacts,
  generated Dart source, fluent APIs, and AI surface definitions.
- Gauge scale and instrument styling with independent major/minor ticks,
  inside/centered/outside tick placement, inside/outside scale labels,
  segmented zone gaps, corners and borders, plus tapered needle and pivot
  controls.
- Persistent resize handles on standard showcase chart panels, including
  pointer, keyboard, reset, focus, and semantics support. Desktop and compact
  heights are stored separately in browser local storage.
- A per-slice colour channel on the radial marks: `PieMark.sliceColor` and
  `DonutMark.sliceColor`, with `sliceColor:` on `BravenChart.geomPie()` and
  `geomDonut()`, mirroring `PolarMark.columnColor`. A null return leaves that
  category on the series colour, and a concentric composition resolves the
  channel per ring bucket.
- Per-ring overrides on `DonutMark`: `dataLabelsByRing`, keyed by the bare ring
  key, with `dataLabels` as the base, and `ringIds`, giving each ring an
  explicit series id so a composition whose ids are decoupled from its ring
  names round-trips. Both are exposed on `BravenChart.geomDonut()`.
- Three Grammar diagnostics for the per-ring surface above: `unknownRingKey`,
  `partialRingIds`, and `perRingOverrideOnRinglessDonut`.

### Changed

- Generated Dart source now also reverses per-slice colours, per-ring data
  labels and non-conforming concentric ring ids, and carries a donut's captured
  `DonutCenterContent` verbatim — `labelStyle` and `valueStyle` included — so a
  styled centre emits rather than being refused, and a live `valueFormatter`
  emits as a `// valueFormatter:` placeholder with a runtime-value-omitted
  warning. Output is byte-identical for every shape that already emitted a
  chain: Cartesian, polar, and pie/donut/concentric charts with no per-slice
  colours, uniform ring labels, conforming ring ids and a default centre.

### Fixed

- Gauge center values remain readable in constrained and large-text layouts,
  accessibility pane reservation stays stable as live values change, and
  active needle and solid indicators receive a high-contrast outline.
- Generated Dart source that sets a non-default tooltip trigger mode now
  compiles. Both the Config and the Grammar form open with
  `import 'package:braven_charts/braven_charts.dart';` and
  `import 'package:flutter/material.dart';`, and `TooltipTriggerMode` is
  declared in both libraries, so `triggerMode: TooltipTriggerMode.<mode>` was
  `ambiguous_import` — the copied source parsed, read correctly and did not
  compile. The material import is now written as
  `import 'package:flutter/material.dart' hide TooltipTriggerMode;` whenever
  the emitted body uses that name. Charts that do not emit an ambiguous name
  are byte-identical; for those that do, the only change is that one import
  line.

### Breaking Changes

- `GrammarDiagnosticCode` gained three further enum values (listed under
  Added), on top of the six added in 0.15.0. They are declared beside the
  radial codes they belong with rather than appended, so the ordinals of the
  values after them shifted again. The breakage is confined to compile time: an
  exhaustive `switch` over `GrammarDiagnosticCode` with no default or wildcard
  case will stop compiling until the new codes are handled. Nothing serialises
  the enum, and chart artifacts and documents encode every enum by NAME rather
  than by ordinal, so persisted documents still load unchanged and the runtime
  behavior of existing code is unaffected.

### Notes

- Every radial Workbench Grammar pane now emits a chain — pie, donut,
  concentric donut and polar column. This supersedes the known limitation
  recorded under 0.15.0: per-slice colours and divergent per-ring data labels
  are no longer refused. What stays refused in the radial families is narrow: a
  radial-bar, gauge or range-area chart (no grammar geometry), a per-point
  `PointStyle` carrying more than a colour and a size, and a concentric
  composition that breaks one of the ring preconditions. A concentric
  composition emits only when every ring shares one `donutStyle`, one
  `selectionStyle`, one `unit`, one `sliceRadiusConfig` and one
  `sliceGroupingConfig`, carries no series `color` of its own, carries no
  centre of its own, and has a distinct, non-empty name — `DonutMark` holds one
  of each for the whole composition, and the ring lowering never carries a
  per-ring `color`. Sharing a NON-DEFAULT value is fine; it is divergence that
  is refused. Of these, the ring name and the ring centre are refused with a
  reason of their own; the five config divergences and the ring colour are
  refused by the round-trip proof's catch-all and are not yet named. The pie
  and donut showcase pages emit with `isComplete == false`, for live formatter
  callbacks that have no literal form — the pie with ONE runtime-value-omitted
  warning covering its two radial label formatters, the donut with TWO, one for
  its centre `valueFormatter` and one for its two radial label formatters. Full
  detail is in `doc/chart_grammar.md`.

## 0.15.0 - 2026-07-28

### Added

- Three production-shaped Radial Bar Gallery compositions covering target
  progress, signed values around a shared baseline, and dense collision-aware
  category tracks, linked to the complete Radial Bar workbench and public
  guide.
- Multi-series Chart Grammar polar columns. A plot may now carry several
  `geomPolar` marks sharing one angular and one radial axis, covering layered,
  grouped, and stacked compositions, and `PolarMark` gained the advanced
  channels `columnColor`, `target`, `targetMarkerStyle`, `intervalLow`,
  `intervalHigh`, `intervalStyle`, and `preset` (including the area-correct
  rose presentation). The chain verb `BravenChart.geomPolar()` exposes the same
  channels, with the preset as the `rose` flag.
- Plot-level polar configuration through `PlotSpec.polar` and the
  `BravenChart.polarConfig()` verb, forwarding a `PolarChartConfig` to every
  polar mark in the plot. A misplaced `.polarConfig(...)` is diagnosed rather
  than silently discarded. Like `grid`, `title`, `subtitle` and the legend
  toggle, the config is a SPEC-level option, so `BravenPlot` also forwards it
  on the empty-data path: a polar chain built over an empty dataset renders
  its empty state inside the authored pane rather than a default one. Cartesian
  charts are unaffected — a non-polar spec carrying a config is refused by
  `polarConfigOnNonPolarSpec`, which runs above the empty-data guard, so it
  still falls through to the const default.
- Complete concentric-donut configuration passthrough through
  `DonutMark.concentric` and `BravenChart.geomDonut(concentric: ...)`, carrying
  ring gap, radial order, ring weights, legend mode, pane radii, and the shared
  center into the Grammar, with the ring-series keying rules stated on the API.
- Six Grammar diagnostics for the compositions the new surface makes
  expressible: `polarConfigOnNonPolarSpec`, `invalidPolarComposition`,
  `incompletePolarInterval`, `conflictingConcentricCenter`,
  `concentricConfigOnRinglessDonut`, and `invalidConcentricComposition`.

### Changed

- Generated Dart source now reverses multi-series polar compositions, the
  polar advanced channels and presets, `.polarConfig(...)`, and non-default
  `ConcentricDonutConfig` ring geometry into Grammar chains instead of
  refusing them. Output is unchanged for Cartesian, pie, donut, concentric
  donut with default ring geometry, and single-series polar with a default
  `PolarChartConfig` and no advanced channels — the shapes that already
  emitted a chain.
- `multipleRadialGeoms` is now raised only when the several radial geoms are
  not all `geomPolar`, and its message names polar columns as the one
  exception to "at most one radial geom". Two pies, or a pie alongside a donut
  or a polar column, are still rejected exactly as before.

### Breaking Changes

- `GrammarDiagnosticCode` gained six enum values (listed under Added). They are
  declared beside the radial codes they belong with rather than appended, so
  the ordinals of the values after them shifted. The breakage is confined to
  compile time: an exhaustive `switch` over `GrammarDiagnosticCode` with no
  default or wildcard case will stop compiling until the new codes are
  handled. Nothing serialises the enum, and chart artifacts and documents
  encode every enum by NAME rather than by ordinal, so persisted documents
  still load unchanged and the runtime behavior of existing code is
  unaffected.

### Notes

- The Grammar of Graphics and fluent authoring APIs (`BravenChart`,
  `PlotSpec`, marks/channels, and `braven_charts_fluent.dart`) remain Beta /
  experimental and may change before a stable release. Pin a version if you
  depend on them.
- Known limitation, so the concentric-donut passthrough above is not read wider
  than it is: a pie or donut series carrying **per-slice colours**
  (`sliceColors`) is still refused by the Grammar source emitter, because
  `PieMark` and `DonutMark` have no per-point colour channel — only `PolarMark`
  does, through `columnColor`. A concentric composition whose rings carry
  *different* `dataLabels` is refused for the same class of reason: one
  `DonutMark` holds one `dataLabels` for every ring it splits into. Both are
  named diagnostics, never a silently different chart. Full detail, including
  which showcase pages this leaves blocked, is under *Known gap* in
  `doc/chart_grammar.md`.

## 0.14.0 - 2026-07-27

### Added

- First-class Gauge and Solid Gauge charts with needle and solid modes,
  operational zones, targets, reference markers, configurable polar panes,
  center content, tracking, selection, semantics, artifacts, generated source,
  fluent modifiers, AI metadata, and dedicated showcase surfaces.
- First-class Radial Bar charts with independent progress tracks, signed
  domains, thresholds, labels, selection, tracking, artifacts, generated
  source, fluent modifiers, AI metadata, and dedicated showcase surfaces.
- Native logarithmic and calendar-time Cartesian axes, including log-space
  transforms, zoom and pan, decade ticks and grid lines, calendar-aware ticks
  and labels, artifacts, generated source, Grammar verbs, diagnostics, and
  deterministic visual coverage.
- Native rectangle selection expressions with exact portable geometry and
  package-wide selection integration.
- Explicit accessible chart actions for keyboard and assistive-technology
  users.
- Searchable, statically hosted public guides under `/guides/`, with stable
  deep links, generated navigation, responsive tables of contents, source and
  runnable-example links, and release-artifact validation.
- Configurable short-tap activation for mobile chart interaction, independent
  of long-press tracking.
- Opt-in crosshair focus bands with independently configurable translucent
  fill, width, center-line color, width, dash pattern, and stroke cap. Bands
  remain plot-clipped and paint-only across standard and synchronized tracking.
- Opt-in persistent tracking guides through
  `CrosshairConfig.persistOnPointerExit`, retaining the last resolved cursor
  across pointer exit, focus loss, and synchronized middle-button viewport
  panning for inspection-oriented chart stacks. Ordinary host-page wheel
  scrolling no longer claims a false chart-zoom lifecycle or clears the guide.
- The Technical Indicators showcase now exposes the complete guide-band
  appearance and accessible seam-overlay drag handles that redistribute height
  locally between the price, volume, MACD, momentum, and navigator panes
  without inserting layout gaps or rebuilding the complete page.

### Changed

- Radial Grammar charts now emit generated Dart source for Pie, Donut,
  Concentric Donut, Polar Column, and Radial Bar configurations instead of
  falling back to configuration-only output.
- Public package and showcase surfaces now describe all twelve chart families,
  link the hosted guides and generated API reference consistently, and enforce
  responsive visual regression checks across phone, tablet, desktop, and dark
  README rendering.
- Refined Range Area interaction feedback so transient interval and whole-band
  hover, keyboard focus, durable point selection, and selected-band emphasis
  remain visually distinct in nested and overlapping compositions across
  light, dark, and high-contrast themes.

### Fixed

- Long guide tables of contents remain independently keyboard-scrollable on
  short desktop viewports without constraining the article.
- Persistent X, Y, and box-brush popups now preserve independent ownership and
  dismissal across pointer, keyboard, controller, and outside-chart paths;
  first-frame tooltip motion is scheduled reliably with reduced-motion support.
- Persistent brush manipulation, host-page scrolling, and viewport pinch
  gestures no longer compete on touch surfaces, with a dedicated multi-axis
  Y-brush review composition in the showcase.

## 0.13.5 - 2026-07-24

### Added

- Opt-in, velocity-aware touch-pan inertia with bounded decay and cancellation
  when a new interaction starts, carried through artifacts, generated source,
  fluent modifiers, and AI metadata. The phone showcase now exposes Browse and
  Explore gesture ownership, independent tap responses, long-press tracking,
  haptics, momentum, and chart-chrome controls across every chart family.
- Scale-driven colour channels on bar, line, and area geometries and a width
  channel on bars in the Chart Grammar, reusing the scatter colour/size
  encodings, baked at lowering into per-element styles with a colour-ramp
  legend, plus a Scale-driven channels showcase with hand-built parity.
- Persistent Cartesian box brushes with exact initial geometry, move and
  edge/corner resize behavior, configurable grid subdivisions, keyboard focus
  styling, controller commands, and complete artifact, generated source,
  fluent, and AI support. Selection geometry and Workbench table projection
  remain exact after live edits on pointer and touch surfaces.
- Direct pub.dev package and GitHub repository links in the persistent showcase
  navigation.

### Notes

- The Grammar of Graphics and fluent authoring APIs (`BravenChart`, `PlotSpec`,
  marks/channels, and `braven_charts_fluent.dart`) are Beta / experimental and
  may change before a stable release. Pin a version if you depend on them.

## 0.13.4 - 2026-07-23

### Added

- Checked Chart Grammar authoring for Pie, Donut, Concentric Donut, and Polar
  Column charts, with radial diagnostics, configuration forwarding, generated
  source parity, single-value ring handling, and a public radial Grammar
  showcase.
- Selectable top, bottom, or mirrored Cartesian X-axis placement and configurable
  numeric or categorical tick-label rotation, plus exact rotation-aware
  collision thinning with configurable spacing and a show-all override.
  Preferred X-axis tick counts now generate uniform readable intervals across
  the visible domain independently of Y-axis density.
  Placement and label behavior are covered by portable artifacts, generated
  source, AI configuration, crosshair alignment, and live Axes controls.
- Opt-in persistent Cartesian X/Y interval brushes with configurable initial
  bounds and visibility, native move/resize handles, styling, controller
  commands, selection callbacks, view-state/artifact/source portability,
  keyboard and semantics support, and touch coexistence with viewport
  gestures. Selection Lab provides the complete review and configuration
  surface.

## 0.13.3 - 2026-07-23

### Added

- Browse and Explore touch profiles for phone and tablet charts, including
  touch pan, focal-point pinch zoom, selection arbitration, controller
  viewport actions, and long-press tracking scrub with optional haptics.
- A responsive Mobile Interaction showcase covering the new touch profiles,
  gesture controls, selection, tracking, and viewport behavior.

### Changed

- Exposed touch interaction configuration through artifacts, generated source,
  fluent modifiers, and AI surfaces.
- Hardened cross-family gesture ownership, tracking cleanup, callbacks,
  semantics, context-menu precedence, and rebuild behavior.

## 0.13.2 - 2026-07-23

### Fixed

- Unified Range Area selection around the visible low-to-high interval for
  pointer, lasso, expression, table, statistics, zoom, artifact, keyboard, and
  screen-reader behavior, including nested bands with a centre line.
- Preserved exact sparse X/Y interval intent and modifier operations without
  eagerly expanding large selections; dense Cartesian acquisition now uses
  family-appropriate indexes and mounted 100K/1M regressions.
- Persisted typed compact selection expressions through artifact JSON,
  hydration, and generated Dart while retaining legacy artifact fields.
- Normalized stale expressions to an empty live selection, disabled invalid
  Workbench actions, and removed full-widget offscreen compositing from
  lightweight selection/hover painting while retaining it for tooltip shadows
  and translucent surfaces.
- Selection-scoped chart creation now retains the canonical selected source
  observations by default, so Line and Area X-range selections create the same
  rows shown in the Workbench data table. Exact interpolated continuous
  boundaries remain available as an explicit projection policy.
- Selection zoom now fits atomic interval geometry instead of only inherited
  scalar Y values: Range Area selections include every retained low/high bound,
  and Candlestick selections include complete wick extents.
- Completed selection accessibility hardening: Bar and Candlestick expose
  tappable live semantics that activate the same durable selection path as
  keyboard and pointer input. The Selection Lab now exposes replace, add,
  subtract, and toggle as visible touch controls and preserves an operable
  chart viewport at 200% text scaling through an adaptive scroll layout.

## 0.13.1 - 2026-07-23

### Added
- A task-oriented Documentation home in the public showcase, with generated
  catalog data for evergreen capabilities, chart families, guide groups, and
  tested starter snippets.
- A generated Dart API reference deployed under `/api/` in the same GitHub
  Pages artifact as the runnable showcase.

### Changed
- Restructured the pub.dev README as a concise product entry point: visual
  synopsis, six evergreen highlights, ten curated chart families, two tested
  starter examples, grouped documentation routes, and a final visual gallery.
- Added a package-neutral public documentation catalog, schema, generator, and
  CI drift gate so README, showcase, routes, media, snippets, and versions stay
  aligned.

## 0.13.0 - 2026-07-22

### Added
- A dedicated phone-width showcase selected automatically below 600 logical
  pixels. It replaces the compressed desktop rail, workbench chrome, and
  property panels with a focused mobile header, horizontally scrollable chart
  family selector, touch-sized presentation controls, and vertically stacked
  examples while leaving the desktop and tablet showcase unchanged.
- Three production-shaped but intentionally compact examples for every
  built-in family: Line, Area, Range Area, Bar, Scatter, Candlestick, Pie,
  Donut, Concentric Donut, and Polar Column/Rose. The mobile compositions cover
  forecast boundaries, comparison lines, baseline fills, nested forecast
  bands, diverging and overlaid bars, bubbles and generated cohorts, technical
  OHLC overlays, dense radial categories, partial and variable-radius rings,
  independent concentric totals, and layered radial values without importing
  desktop-only multi-axis analysis.
- Vivid, Midnight, and Calm mobile presentation presets. Theme changes retain
  the selected family, update every visible chart consistently, and preserve
  the chart family configurations rather than replacing examples with generic
  colour swaps.
- Entrance and update motion throughout the mobile tour, with reduced-motion
  handling inherited from the package's animation policies. Lazy vertical
  mounting limits initial work while keeping the page naturally scrollable.
- Direct mobile routing for every existing chart-family URL, so links from
  pub.dev and the README open the matching family whether the visitor arrives
  on a phone or desktop viewport.
- Repeatable `mobile-0.13` package-media capture support in
  `tool/capture_showcase_media.py`, including a deterministic narrow viewport
  and a settled post-animation frame for `mobile_showcase.png`.

### Changed
- The package README and pub.dev screenshot manifest now document the
  responsive showcase as a first-class public surface. The mobile capture
  replaces the second, redundant Grammar screenshot in the ten-slot pub.dev
  gallery; the full Workbench Grammar image remains in the README beside its
  technical explanation.
- The showcase documentation now distinguishes the focused phone tour from the
  full desktop workbench and describes the automatic breakpoint, mobile chart
  coverage, themes, motion, and touch interaction contract.

## 0.12.0 - 2026-07-22

### Added
- Renderer-neutral durable selection across all built-in families: point,
  X/Y interval, rectangle, and lasso acquisition; point, category,
  composition-stack, complete-series, and exclusive point-or-series scopes;
  Shift/Ctrl-or-Command/Alt set operations; configurable path hit corridors
  and focus/selection feedback; scope-aware keyboard and screen-reader
  traversal for every built-in family, ordered Shift+Space extension, and
  bounded Ctrl/Command+A; compact expression snapshots with extents and
  statistics; linked
  brushing by stable point key; selection-scoped chart extraction with exact
  continuous Line/Area boundaries and annotation projection; and Workbench
  Create chart, Zoom, Copy, CSV, Invert, and Clear actions. The dedicated
  Selection Lab compares the same policies across every chart family.
- Opt-in fluent modifier surface behind a new barrel,
  `package:braven_charts/braven_charts_fluent.dart`: 98 generated extensions
  carrying ~1160 chained verbs over the existing config classes, with a
  vocabulary that keeps the two kinds of "unset" apart — `withX(v)` replaces,
  `withoutX()` suppresses a tri-state `ChartStyleValue` field, `inheritX()`
  defers it to the theme, `clearX()` unsets a nullable parameter back to its
  default, and `updateX(fn)` edits a nested config in place. The barrel
  re-exports the core barrel, so one import is enough; the core barrel is
  untouched, so consumers who never import it never see the verbs. Assert
  coupled parameters are only reachable through combined setters
  (`withOhlc(open:, high:, low:, close:)`, `withRange(min, max)`), and
  cross-object join keys (`id`), OR-coupled bar widths and `RangeAnnotation`
  bounds are deliberately construction-only.
- `@chartSurface` surface model and the `tool/surface_gen` build_runner engine
  that reads it: an analyzer-based, dev-only generator emitting checked-in
  fluent extensions plus an executing smoke suite, with enforcement that fails
  when a barrel-reachable, `copyWith`-carrying config class is unannotated
  (`missing = 0`) and a CI regeneration gate that fails on any diff. Consumers
  never run `build_runner`. The 0.11.0 Range Area family is covered by the
  same gate: `RangeAreaChartSeries`, `RangeAreaDataPoint`,
  `RangeAreaBoundaryStyle`, `RangeAreaLabelConfig` and `RangeAreaTheme` are
  modelled, with `withInterval(low, high)` keeping the `high >= low`
  invariant and `id`/`points` construction-only.
- `ChartToolSchema.surfaceDefinitions`: structural surface definitions
  generated from the same annotated model that drives the fluent layer, so the
  AI tool schema and the config builder are derived from one source, guarded
  by a bidirectional drift gate in both directions.
- Grammar-chain source generation, and a Config / Grammar toggle in the
  Workbench Source pane. `ChartGrammarSourceGenerator` reads a captured chart
  document and writes the `BravenChart.of(rows).x(...).geomLine(...).build()`
  chain that rebuilds it, over a SYNTHESISED row class — one field for the
  shared x, one per measure, named after each series, with candlesticks
  contributing open/high/low/close and scatter channels their own fields.
  Fidelity is proven rather than asserted: before emitting anything the
  generator lowers the spec it is about to write and compares the resulting
  series, annotations, Y-axes AND the X axis, theme and interaction to the
  ones the document hydrated to, so a
  chain that would render a different chart is refused with a named diagnostic
  and no code — one that identifies the specific series, annotation or axis
  option a V1 mark cannot carry (a lost series field, or the single-axis
  binding a config-authored chart leaves implicit) rather than only reporting
  that the chart "does not reproduce exactly". Non-Cartesian families,
  misaligned x domains, partially
  populated scatter channels, partial candlestick timestamps, mixed bar
  orientations, annotations other than
  `TrendAnnotation` and chart-level options `BravenPlot` does not forward are
  each diagnosed by name; runtime bindings and over-budget data are warned
  about and emitted, exactly as the config form does. Both forms read the same
  captured document, so switching never re-extracts the chart, and the config
  form's output, keys and tests are byte-for-byte unchanged.
  `BravenChartWorkbench` gains `grammarSourceOptions` and `initialSourceForm`.
- Typed grammar-of-graphics authoring layer in the core barrel: `PlotSpec<T>`,
  the sealed `Mark<T>` hierarchy (`LineMark`, `AreaMark`, `BarMark`,
  `ScatterMark`, `CandlestickMark`, `TrendMark`), `Channel<T>` and
  `CategoryChannel<T>` encodings, the `PlotSpecLowering.lower()` extension, the
  `BravenPlot<T>` widget, and the chained `BravenChart.of(rows)` facade with
  `x`/`y`/`geomLine`/`geomArea`/`geomBar`/`geomPoint`/`geomCandlestick`/
  `trend`/`transposed`/`theme`/`interaction`/`xAxis`/`yAxis`/`build`. A spec
  lowers onto ordinary `ChartSeries`, `ChartAnnotation` and axis configs, so
  the render pipeline, artifact codecs, generated Source and the Workbench are
  untouched — parity is locked by config-equality and artifact-document
  equality suites. Failures are fail-fast and carry a machine-readable
  `GrammarDiagnosticCode`, and nothing is dropped silently — a channel without
  its encoding AND an encoding with no channel to drive it both raise. Every
  data-independent structural check (mark/axis ids, axis binding, channel
  pairing, trend source, transposition) runs BEFORE the empty-data check, so
  an authoring error surfaces even against a momentarily-empty dataset; empty
  data alone is treated as a runtime state and renders the standard empty
  state instead of throwing from `build`.
- Grammar V2.0 — the three most common charts V1 could only diagnose now
  round-trip. **Reference annotation marks:** `.threshold(value:)`,
  `.band(start:, end:)` and `.pointAt(seriesId:, dataPointIndex:)` (new
  `ThresholdMark` / `BandMark` / `PointMark`) lower to `ThresholdAnnotation`,
  a 1-D `RangeAnnotation` and `PointAnnotation`. **Chart-level options:**
  `PlotSpec` carries a `grid`, `title`/`subtitle` and `showLegend`, forwarded
  by `BravenPlot`, with `.grid(...)` / `.title(...)` / `.legend(...)` verbs; a
  null grid or legend reproduces the chart default. **Per-mark data-point
  markers and inline labels:** `showDataPointMarkers` and `dataPointLabels` on
  `geomLine`/`geomArea`, and `labelStyle` on `geomBar`. The grammar-source
  emitter emits every one of these — the reference verbs, `.grid`/`.title`/
  `.legend`, and the marker/label fields — so charts that previously drew a
  "not emitted" diagnostic in the Workbench Grammar form now emit a chain,
  proven by the round-trip fidelity guarantee. Marks stay `copyWith`-free.

## 0.11.0 - 2026-07-21

### Added
- First-class Range Area charts through `RangeAreaDataPoint` and
  `RangeAreaChartSeries`, including atomic low/high bounds, explicit gaps,
  linear/Bezier/monotone/stepped interpolation, solid or gradient fills,
  independently styled boundaries, markers, labels, hit policies, typed
  low/high/midpoint/span tracking, paired axis values and intersections,
  keyboard selection and semantics, invariant-preserving entrance/update
  motion, nested bands and ordinary Line composition, viewport culling,
  artifacts, hydration, native tables/CSV, generated Dart, Workbench modes,
  and strict tool-driven configuration.
- A complete Range Area publication surface across the ten-family Chart Types
  catalog and Gallery, including a native interval preview, weather envelope,
  nested forecast fan, financial volatility composition, dedicated route, and
  property-testing Workbench.
- Native pub.dev captures for the temperature envelope, nested forecast fan,
  and volatility envelope, plus a regenerated ten-family chart-type strip.

## 0.10.0 - 2026-07-21

### Added
- First-class typed OHLC charts through `CandlestickDataPoint`,
  `CandlestickChartSeries`, and `CandlestickChartStyle`, including
  rising/falling/doji presentation, elapsed and ordinal time spacing,
  viewport culling, indexed hit testing, pointer and keyboard selection,
  tracking, entrance and compatible data-update animation, live latest-candle
  upsert, density grouping, mixed Line/Area/Scatter overlays, native tables,
  CSV, artifacts, hydration, generated Dart, and Workbench integration.
- A reusable, family-neutral `CartesianNavigator` for Line, Area, Bar,
  Scatter, and Candlestick charts. It renders a full-domain Line or Area
  overview and controls caller-owned synchronized viewports through pointer,
  touch, keyboard, and semantic panning/resizing, interval or ordered-value
  snapping, accessible controls, external-domain growth, and live retained-
  history inspection.
- Polar Column and Nightingale Rose charts with a numeric radial scale,
  standard or area-correct radii, partial panes, layered/grouped/diverging
  stacked composition, category target ticks, pane thresholds, absolute
  uncertainty intervals, independent label and radial-axis placement,
  deterministic density limits, gradients, elevation, corner-radius modes,
  entrance animation, selection/tracking, portable artifacts, native data,
  and generated Source.
- Typed, host-extensible chart commands through `ChartContextAction`,
  `ChartContextInvocation`, and renderer-neutral `ChartContextHit`, plus
  `BravenChartWorkbench.contextActionsBuilder` and independently configurable
  `ChartOverlayAction` buttons. Secondary-click, keyboard, and opt-in touch or
  stylus long-press entry paths share accessible, theme-aware command styling.
- Label-driven release automation: a merged PR carrying the `release` label
  tags the package version, publishes to pub.dev with OIDC trusted publishing,
  and deploys the release showcase to GitHub Pages.
- Native Cartesian value summary for every Cartesian family through
  `InteractionConfig.valueSummary` and `CartesianValueSummaryConfig`: a
  persistent in-plot panel showing the current policy-resolved datum, fed by
  the chart's shared immutable tracking snapshot with one resolution per
  interaction frame.
- Two presentations sharing content, style, semantics, and formatting:
  `CartesianValueSummaryPresentation.overlay` (fixed, pointer-transparent,
  anchored via `ChartOverlayPlacement`) and
  `CartesianValueSummaryPresentation.annotation` (optionally draggable and
  keyboard-movable with plot clamping, continuous drag preview, and exactly
  one committed placement per gesture through `onPlacementChanged`).
- Deterministic `CartesianValueSummaryValuePolicy` precedence chains over
  tracking, selection, pinning, and latest/first visible fallbacks, with
  automatic invalid-pin clearing.
- `CartesianValueSummaryConfig.valueMode`
  (`interpolated` default / `dataPoints`): tracked summary rows can snap to
  the nearest actual data point instead of following the interpolated curve,
  independent of the crosshair's own interpolation setting. The summary
  keeps reusing the shared per-frame tracking resolution in every compatible
  combination; only crosshair interpolation and summary `dataPoints`
  simultaneously active add one extra memoized resolution per frame.
  Serialized in artifacts and generated Source when non-default, with a
  'Value mode' toggle on the showcase page.
- Family-aware `CartesianValueSummaryContent.automatic()` rows (Line/Area/Bar
  values with grouped context, Scatter encodings, Candlestick OHLC/change/
  direction, per-series sections for mixed charts, optional trend rows) and
  portable `CartesianValueSummaryContent.builder()` rows over the published
  snapshot.
- Tri-state `CartesianValueSummaryStyle` (`inherit`/`value`/`none` per field,
  with genuinely transparent clears) resolved against the new
  `CartesianValueSummaryTheme` component, including `light`, `dark`,
  `highContrast`, and `colorblindFriendly` presets.
- Packed row layout through `CartesianValueSummaryStyle.labelValueGap` (and
  the matching nullable `CartesianValueSummaryTheme.labelValueGap` default):
  an explicit gap left-aligns values in a shared column right after the
  widest row label and tightens the panel's intrinsic width — clamped by
  `minWidth`/`maxWidth`, long values still ellipsizing — while inherited or
  cleared keeps the spread layout with right-aligned values.
- `CartesianValueSummaryController` /
  `DefaultCartesianValueSummaryController` for programmatic pinning by stable
  `ChartPointRef` identity and placement reset.
- Accessibility: one grouped semantic region per visible summary with title,
  context, and unit-carrying rows in source order; opt-in `announceChanges`
  screen-reader announcements debounced by resolved datum identity;
  focusability and `Move`/`Reset position` custom actions for the draggable
  panel; `Pin value`/`Clear pin` actions when a controller and pin policy are
  active.
- Full portability: value summary configuration in chart artifacts and
  hydration, deterministic generated Dart Source, runtime-binding
  diagnostics for unregistered builder content, and Workbench integration.
- A first-class Tracking & Value Display showcase page with presets for
  single-series fallback, multi-series, multi-axis units, Candlestick OHLC,
  synchronized charts, and the draggable panel, plus independent toggles for
  every tracking feedback layer (crosshair lines, tracking panel, point
  tooltip, axis value labels, intersection markers, data point markers, and
  the value summary) alongside appearance, policy, and pin controls.
- A permanent value summary benchmark matrix (50k-point overlay updates,
  candlestick zero-invalidation tracking, dense Scatter single-scan proof,
  synchronized fanout, drag commit cadence) and a `doc/value_summary.md`
  feature guide.

### Changed
- Cartesian composition now accepts one Candlestick series with Line, Area,
  and Scatter overlays while retaining explicit validation for unsupported
  second-Candlestick and same-plot Bar combinations.
- Representative Line, Area, Bar, Scatter, and Candlestick guides use the
  public navigator contract instead of family-specific overview controls.
- `LiveStreamController.manageViewport` can opt out of internal X-viewport
  movement so a caller-owned interaction group and navigator remain the sole
  viewport authority during ingest; `dataRevision` and O(1) `oldestPoint`
  support efficient external synchronization.
- Live Navigator snapshots and detail following are independently display-
  frame-coalesced and revision-gated. The detail chart remains mounted while
  telemetry, controls, and the retained-history overview update separately.
  Diagnostics now report device-local frame/build/raster/jank/FPS metrics and
  navigator synchronization cadence, gap, snapshot cost, and domain lag.
- Browser context-menu suppression is reference-counted across mounted charts
  and restores the previous application setting only after the final chart is
  disposed.
- The public showcase, chart-family catalog, Gallery, API guide, feature
  matrix, README media, and release screenshots now cover all nine built-in
  families plus the Cartesian navigator and value-summary surfaces.

### Fixed
- Candlestick price, volume, and navigator panes now use identical global plot
  bounds, keeping synchronized X values pixel-aligned despite independent Y
  axes and side-slot widths.
- Live Navigator historical inspection now starts only from explicit chart or
  navigator gestures. Programmatic follow-latest writes no longer freeze the
  detail view, reverse visual motion, or fight a second viewport owner.
- `CartesianNavigatorBehavior.allowExternalDomainGrowth` preserves an
  authoritative live viewport while a bounded overview snapshot catches up,
  eliminating stale-domain clamp feedback and left/right oscillation.
- Navigator panning and edge resizing publish synchronized viewports
  continuously during pointer movement while remaining isolated from tracking
  and cursor fanout.
- Full-circle Polar Column grid, baseline, and threshold rings now use closed
  geometry and remain visible at every start angle.
- Annotation hosts can consume transient move and resize previews without
  replacing controller-owned annotations during an active gesture; committed
  callbacks remain pointer-up only.
- `CrosshairConfig.showCoordinateLabels` is now honored by the crosshair
  renderer: clearing it removes the axis value labels in both standard and
  tracking display modes (previously the flag was serialized but never read
  during painting). The labels are their own feedback layer — with
  `CrosshairMode.none` they can now paint without any crosshair lines,
  matching the layer-independence contract of the tracking feedback stack.

## 0.10.0-dev.1

Prerelease validating the new automated release pipeline; content below is
release-candidate material for 0.10.0.

### Added
- Label-driven release automation: merging a PR carrying the `release` label
  tags the version, publishes to pub.dev via OIDC trusted publishing, and
  deploys the showcase to GitHub Pages (see `docs/releasing.md`).
- A native, family-neutral `CartesianNavigator` that renders one full-domain
  Line or Area overview and controls synchronized Line, Area, Bar, Scatter, and
  Candlestick viewports through a caller-owned
  `ChartInteractionGroupController`.
- Shared pointer, keyboard, and semantic viewport reduction; independent start
  and end resizing; span-preserving panning; configurable minimum span and live
  preview; fixed-interval and ordered-value snapping; and reconciliation of
  external controller writes during active gestures.
- Theme-aware `CartesianNavigatorStyle` states with compact visual handles,
  48-pixel default pointer/touch targets, focus treatment, disabled rendering,
  and three explicit accessible controls.
- A focused Interaction-page Navigator laboratory with deterministic point
  count and signal controls, draggable overview selection, live viewport
  feedback, and host buttons that exercise the same public
  `ChartInteractionGroupController` as direct chart gestures.
- A dedicated Live Stream Navigator strategy that keeps frame-coalesced ingest
  active while users inspect retained history, reports incoming samples without
  moving the historical viewport, and provides an explicit Return to live path.
- `LiveStreamController.dataRevision` plus the O(1) `oldestPoint` endpoint so
  external viewport owners can follow live data without copying snapshots.
- First-class typed OHLC charts through `CandlestickDataPoint`,
  `CandlestickChartSeries`, `CandlestickChartStyle`, theme-resolved rising,
  falling, and doji presentation, viewport-aware wick/body geometry, indexed
  hit testing, pointer and keyboard selection, and sample-based tracking.
- Candlestick entrance reveal and compatible OHLC data-update interpolation,
  plus bounded `LiveStreamController.upsertLatestCandlestick` revision and
  append behavior.
- Portable Candlestick artifacts, strict built-in hydration, lossless native
  OHLC tables, copy and CSV, deterministic generated Dart, explicit AI-builder
  input, and Chart/Data/Split/Source Workbench integration.
- Opt-in `CandlestickDensityGrouping` using first open, maximum high, minimum
  low, and last close while retaining all represented source indices and
  keeping raw tables and artifacts unchanged.
- A complete Candlestick showcase with elapsed and ordinal time spacing,
  configurable geometry and tracking, live revisions, a dense-data laboratory,
  and synchronized price, volume, and navigator panes.
- Permanent Candlestick performance and visual regression matrices covering
  50,000 source candles, 5,000 visible marks, 1,000 animated revisions,
  grouped tracking, pan/zoom, three-pane fanout, light/dark/doji/time-spacing,
  compact composition, and grouped-density rendering.
- Typed, host-extensible native chart context actions through
  `ChartContextAction`, `ChartContextInvocation`, renderer-neutral
  `ChartContextHit`, and `ChartContextMenuConfig`.
- `BravenChartWorkbench.contextActionsBuilder`, which supplies the same stable
  `ChartWorkbenchHandle` as visible actions so a host command can safely
  extract the current artifact from either surface.
- An independently opt-in compact in-chart host action through
  `ChartOverlayAction` and `ChartOverlayActionButtonConfig`, with configurable
  placement, sizing, semantics, enabled state, Material styling, a translucent
  theme-derived default, and direct-chart or Workbench builders using the same
  host callback model.
- Secondary-click, Context Menu key, Shift+F10, and opt-in touch/stylus
  long-press entry paths with deterministic command grouping, accessible
  keyboard navigation, 48-pixel rows, theme-derived styling, viewport
  clamping, focus restoration, and safe async callback cleanup.
- Polar Column baseline-to-value gradients, configurable mark elevation, and
  grow/sweep/fade/instant entrance modes with controller replay and reduced-motion
  compliance.
- Independent category-label outward offset/style, direct value-label radial
  position/style, and radial-axis label ray/angle/offset/style controls. The
  appearance additions round-trip through artifacts, hydration, and generated
  Dart with explicit capability negotiation.
- Polar radial rings and angular spokes honor the chart theme's solid, dashed,
  or dotted grid pattern. The seeded showcase now varies contrast-safe label
  and axis colors together with grid colors, stroke widths, and patterns.

### Changed
- The Live Navigator showcase now revision-gates retained-history snapshots and
  rebuilds only its telemetry, controls, and overview subtree, keeping the main
  live chart mounted during high-frequency ingest and navigator interaction.
- Every Live Stream strategy now exposes rolling device-local frame, build,
  raster, jank, presented-FPS, and frame-gap diagnostics; Live Navigator also
  reports its retained-history synchronization cost, navigator update rate,
  navigator gap p95, and live-domain lag separately.
- Live Navigator detail following is now display-frame-coalesced independently
  with its bounded retained-history overview snapshot, removing the former
  200 ms overview presentation gap.
- Live Navigator now enters historical inspection only from explicit chart or
  navigator gestures (or its switch), preventing programmatic follow-latest
  viewport commands from freezing the detail view or reversing visual motion.
- `CartesianNavigatorBehavior.allowExternalDomainGrowth` keeps a live external
  viewport authoritative while a throttled overview snapshot catches up,
  preventing stale-domain clamp feedback and left/right viewport oscillation.
- `LiveStreamController.manageViewport` can now opt out of built-in X-viewport
  movement so a caller-owned `ChartInteractionGroupController` and
  `CartesianNavigator` remain the single viewport authority during live ingest.
- The Candlestick stock showcase now uses the public Cartesian navigator rather
  than a local draggable `RangeAnnotation`; the Gallery proves the same control
  against a non-financial synchronized Line/Area composition.
- Representative Cartesian guides now expose the same reusable navigator in
  Line Synchronized, Area Forecast, Bar Categories, and Scatter Correlation,
  demonstrating one viewport contract across continuous, categorical, and
  unsorted data without turning navigation into global chart chrome.
- Cartesian composition accepts one Candlestick series with Line, Area, and
  Scatter overlays. A second Candlestick or same-plot Bar series fails closed;
  volume remains a separate synchronized chart with its own scale.
- The Chart Types catalog, navigation, public guide, feature matrix, and
  package overview include Candlestick as a built-in chart family.
- Browser context-menu suppression is reference-counted across mounted charts
  and restores the previous application state only after the final chart is
  disposed.

### Fixed
- Stock navigator window panning and edge resizing now update synchronized
  viewports continuously during pointer movement, while the navigator remains
  isolated from chart tracking and cursor fanout.
- Annotation hosts can consume transient move and resize previews through
  `onAnnotationDragUpdate` without replacing controller-owned annotations
  during an active gesture; `onAnnotationDragged` remains the committed
  pointer-up callback.
- Range-based control surfaces can keep resize grips persistently visible and
  interactive, and draggable range bodies now expose platform `grab` and
  `grabbing` cursors instead of looking like passive chart content.
- Compatible multi-series Polar Column compositions. Series with matching
  categories/order, preset, and unit can either layer in declaration order or
  divide each category into grouped angular sub-bands on one shared radial
  scale, with series-aware pointer, keyboard, controller, table, CSV, artifact,
  hydration, and generated-source identity.
- `chart.polar.multiple-series.v1` capability negotiation for portable layered
  Polar Column documents and `chart.polar.grouped-series.v1` for grouped
  geometry, plus production-shaped layered and grouped comparison presets in
  the public showcase.
- Diverging stacked Polar Column composition through
  `PolarColumnCompositionMode.stacked`. Signed source values accumulate on
  independent positive and negative sides of an explicit zero baseline while
  tables, CSV, controllers, artifacts, hydration, and generated Dart retain
  the original values and series identity. Stacked documents negotiate
  `chart.polar.stacked-series.v1`.
- Per-category Polar Column target ticks through `targetValues` and
  `PolarColumnTargetMarkerStyle`, plus pane-wide `PolarThreshold` reference
  arcs. Automatic radial domains include both reference types; explicit
  domains retain the source data while omitting out-of-range paint. Targets
  and thresholds round-trip through tables, CSV, artifacts, hydration, and
  generated Dart using explicit capability negotiation.
- Absolute Polar Column uncertainty/range intervals through
  `PolarColumnInterval` and `PolarColumnIntervalStyle`. Intervals render as
  radial whiskers with tangential caps or compact annular bands, participate
  in automatic radial domains, clip against explicit domains while retaining
  exact source endpoints, and round-trip through native tables, CSV,
  artifacts, hydration, and generated Dart. Stacked contributors reject
  intervals because cumulative placement would make their meaning ambiguous.
- Deterministic Polar Column density controls through
  `PolarCategoryAxisConfig.maximumVisibleLabels`,
  `PolarCategoryAxisConfig.maximumVisibleGridLines`, and
  `PolarColumnStyle.maximumVisibleDataLabels`. Dense panes thin only painted
  labels and spokes; every mark remains available to hit testing, semantics,
  native tables, CSV, artifacts, hydration, and generated Dart source. A
  512-category warm-paint benchmark now guards the renderer's frame budget.
- `PolarColumnCornerRadiusMode` for rounding both radial ends, retaining the
  original outer-radius-only treatment, or rounding only the exposed positive
  and negative boundaries of a complete stack. Non-default modes negotiate
  `series.polar.column.corner-radius-mode.v1` through artifacts and generated
  source.

### Fixed
- Full-circle Polar Column grid, baseline, and threshold rings now use closed
  circle geometry, so rotating a 360-degree pane cannot make its radial lines
  disappear at particular start angles.

## 0.9.0 - 2026-07-19

### Added
- Quantitative Scatter encodings through `ScatterSizeEncoding`,
  `ScatterColorEncoding`, and `ScatterOpacityEncoding`. Independent
  `ChartDataPoint.magnitude`, `colorValue`, and `opacityValue` channels can be
  combined without replacing the point's X/Y coordinates or explicit style.
- Continuous and threshold-based Scatter colour scales, fixed or data-derived
  domains, native gradient and segmented legends, named piecewise bands, and
  consistent values in tracking tooltips, tables, artifacts, hydration, and
  generated Dart source.
- Area-correct bubble sizing with configurable radius bounds and quantitative
  size legends. Invalid size values are omitted deliberately, while finite
  values clamp safely to the configured domain.
- `ScatterMarkerStyle` for independent fill, outline, opacity, width, height,
  and rotation; circle, square, triangle, inverted-triangle, diamond, cross,
  plus, star, and hidden marker shapes; and per-point style/shape overrides.
- `ScatterInteractionStyle` for geometry-and-outline hover, press, durable
  selection, keyboard/linked focus, and non-selected dimming states that do not
  rely on colour alone.
- Point-accurate Scatter hit testing and tracking based on the resolved marker
  geometry, including unsorted X data, overlapping points, viewport culling,
  spatial indexing, and finite-value filtering.
- A complete Scatter chart-family guide with fixed, styled, stress, unsorted,
  interaction-state, bubble, continuous-colour, piecewise-band, and opacity
  examples in the shared Chart/Data/Split/Source Workbench.
- Three production-shaped Scatter Gallery compositions and native release
  captures covering bubble area and shape, continuous readiness colour, and a
  dark piecewise equipment-risk scale.
- A synchronized route-profile Gallery composition showing three independent
  charts with local Y scales and one shared data-X interaction controller.

### Changed
- Scatter data now round-trips its quantitative channels, resolved marker
  presentation, and encoding metadata through binary/JSON artifacts, chart
  hydration, generated Dart, chart tables, copy, and CSV export.
- Crosshair tracking and tooltips now resolve Scatter hits in both dimensions
  and expose encoded size, colour, opacity, and piecewise-band values alongside
  normal series and point metadata.
- The Chart Types catalog and Gallery now lead to the expanded Scatter guide
  and synchronized Cartesian example, and the pub.dev media set uses focused
  native captures of those capabilities.
- Pie and Concentric Donut catalog previews use more representative configured
  examples while preserving the existing radial rendering contracts.

### Fixed
- Removed an accidentally tracked, ignored local worktree gitlink from the
  package archive so `dart pub publish --dry-run` remains warning-free.
- Scatter virtualization and interaction no longer assume points are ordered by
  X, and marker bounds account for non-circular dimensions, rotation, outlines,
  and encoded radius.
- Annotation and series artifact codecs retain the complete Scatter
  configuration rather than silently dropping newly encoded fields.

## 0.8.0 - 2026-07-19

### Added
- Portable `dashPattern` outlines for ordinary Line and Area series, including
  interpolation-aware rendering, continuous Area fills, glow, native outgoing-
  segment pattern changes, artifacts, built-in hydration, generated Dart
  source, legend identity, and a continuous observed-versus-forecast showcase.
- Caller-owned `ChartInteractionGroupController` synchronization for
  data-space X cursors, local nearest-point tracking, and loop-safe X-only
  viewports across independent Cartesian charts, plus a responsive
  Speed/Elevation/Heart-rate showcase.
- Donut and Concentric Donut slice gaps now form constant-width physical
  channels with parallel sides from the center opening to the outer arc,
  including rounded sectors and independently allocated rings.
- Signed inside-label radial offsets for Pie, Donut, and Concentric Donut
  charts. Positive values move labels toward the outer edge, negative values
  move them toward the center, and resolved anchors remain inside each slice.
  A zero offset centers Concentric labels within each allocated ring band.
- Optional dual radial data-label layers, including independently styled
  outside category callouts and inside value/share badges for Pie, Donut, and
  per-ring Concentric Donut presentations. The model, generated Source, AI
  schema, artifacts, collision layout, and public showcases share one contract.
- Concentric Donut compositions built from two or more independent
  `DonutChartSeries` rings, with automatic or weighted band allocation,
  configurable ordering and gaps, one shared center, grouped or flat legends,
  coordinated labels, ring-aware tables/tooltips/semantics, exact generated
  Source, canonical artifacts, preview capture, and hydration.
- Shared `RadialSelectionStyle` presentation across Pie, Donut, and Concentric
  Donut charts. Selection can retain the established explode treatment or lift
  a scaled, radially offset foreground slice with configurable composition
  backdrop blur while preserving durable point identity and ring allocation.
- A dedicated Concentric Donut Gallery section with period comparison,
  partial-sweep service health, and dark weighted-portfolio compositions, plus
  native chart-export captures for the README and pub.dev listing.

### Fixed
- Invalid or non-finite Bar points no longer poison stacked, normalized,
  diverging, Waterfall, bounds, viewport, or hit-test geometry.
- Oversized per-point bars remain visible when their bodies intersect the
  viewport, while extreme widths are clipped before spatial indexing.
- Bar transition matching and exit placement now scale linearly, and dense
  charts bypass full-list entrance interpolation beyond the maintained
  10,000-mark animation budget.
- Changing `transitionKey` during an active radial morph now clears the stale
  transition before the destination chart enters.
- The Bar Lab maximum stress configuration no longer rebuilds its 10,000-item
  category list once per data point.
- Source capture preserves chart-level `ConcentricDonutConfig`, including
  deterministic ring weights, order, legend mode, and portable center content.
- Lifted Concentric selections paint and hit-test above the complete radial
  composition, with backdrop blur coordinated across rings and stable layout.

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
