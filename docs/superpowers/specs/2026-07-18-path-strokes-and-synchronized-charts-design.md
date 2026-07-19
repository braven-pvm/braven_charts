# Path Stroke Patterns and Synchronized Cartesian Charts

**Status:** Sprint 11 promoted in PR #45; Sprint 12 local review approved
**Roadmap:** Sprints 11 and 12 of Line and Area Product Parity
**Sprint 11 lane:** `feature/line-stroke-forecast`
**Sprint 12 lane:** `feature/synchronized-cartesian-charts`
**Prerequisite:** PR #45 merged into `master`

## Goal

Add two related analytical presentation capabilities without turning one chart
into a multi-panel layout engine:

1. portable dotted, dashed, and dash-dot outlines for ordinary Line and Area
   series, proven by an observed-versus-forecast composition; and
2. native data-X interaction synchronization across independently mounted
   Cartesian charts, proven by stacked Speed, Elevation, and Heart rate plots.

The two capabilities ship separately. Stroke patterns are a series rendering
and document concern. Chart synchronization is transient interaction
coordination and must remain independent of Workbench presentation grouping.

## Sprint 11 — Path stroke patterns and Forecast

### Public model

`LineChartSeries` and `AreaChartSeries` gain:

```dart
dashPattern: const [2, 6],
```

An empty pattern is the solid default. Every configured entry must be finite
and greater than zero, and the list must contain an even number of alternating
draw and gap lengths. The pattern uses logical pixels in rendered path space.

The existing rounded stroke cap remains the default. `[2, 6]` therefore reads
as a dotted line, `[8, 4]` as dashed, and `[8, 4, 2, 4]` as dash-dot. No enum is
added because callers need precise analytical and brand-specific patterns.

`copyWith`, equality, hashing, and debugging output include the pattern.
Existing constructors and solid rendering remain source- and behavior-
compatible.

`SegmentStyle` also gains a nullable `dashPattern`. A null segment value
inherits the series pattern; an empty segment value explicitly restores a
solid stroke. Because a point's `SegmentStyle` already applies to the outgoing
segment, callers can change stroke identity at an exact data point without
splitting the series or recomputing interpolation endpoints.

### Rendering contract

- Generate interpolation geometry exactly once using the existing linear,
  stepped, Bezier, or monotone path builder.
- Apply the draw/gap pattern to that rendered path using path metrics. Do not
  resample the source data or approximate curved interpolation with straight
  data segments.
- Carry phase continuously through each path contour. A pattern restarts only
  at a genuinely separate contour or separately styled region.
- Apply the same pattern to the visible stroke and optional glow. Area fill
  remains continuous; only its outline is patterned.
- Per-segment color, width, and pattern overrides retain their current region
  boundaries. Every region is generated from the complete point array so
  Bezier and monotone tangents remain continuous across paint changes.
- Baseline Area fills keep their existing positive/negative clips and apply
  the pattern only to the shared outline.
- Hit testing, tracking, markers, labels, inline labels, focus, and selection
  continue to use canonical path and point geometry. Gaps are not interaction
  holes.
- Entrance reveal, compatible data updates, topology motion, interruption, and
  reduced motion operate on geometry before stroke patterning. Animation never
  changes canonical identity or dash configuration.

### Portable document contract

Series and outgoing-segment patterns:

- encode in the built-in Line/Area style document;
- advertise `series.path-dash.v1`;
- hydrate without a runtime extension;
- round-trip through extraction, JSON, migration-safe decoding, and generated
  Dart source; and
- render the same pattern in the package-owned legend swatch.

Malformed decoded patterns fail with a structured format error. A missing
segment pattern inherits its series; an explicit empty segment pattern remains
solid. Missing or empty series patterns decode to solid, preserving older
artifacts.

### Forecast composition

Add one `Forecast` preset to the Line chart-family page. It uses:

- one canonical Line series containing observed and forecast samples;
- a solid series default and dotted outgoing segment styles from the
  current-time point onward;
- one interpolation pass across the complete dataset, preserving positional
  and tangent continuity at the paint boundary;
- hollow sample markers;
- one vertical `ThresholdAnnotation(axis: AnnotationAxis.x)` labelled
  `Current time`; and
- the existing Workbench Chart/Data/Split/Source surface.

The chart is the page's primary content. The threshold, solid/dotted pattern,
composition summary, and `Forecast` endpoint label provide redundant
non-colour meaning. No new options section, forecast engine, menu, or dense
legend is introduced.

At compact widths the existing preset selector scrolls horizontally. The
chart remains at its established minimum pane extent, while Workbench compact
Split behavior remains unchanged.

## Sprint 12 — Synchronized Cartesian charts

### Architecture decision

Use three independent `BravenChartPlus` instances with one shared X domain.
Do not add panes or subplots inside one renderer. Independent charts preserve
readable units, Y bounds, titles, latest values, and responsive height while
reusing the existing Cartesian renderer unchanged.

`ChartWorkbenchGroupController` continues to synchronize only Chart/Data/
Split/Source presentation. A new caller-owned
`ChartInteractionGroupController` coordinates transient chart interaction.

### Synchronization contract

Each participant registers its mounted chart and local data-X transform. The
group coordinates:

- a shared data-space X cursor;
- rendered-series intersection resolution per chart using each local Line or
  Area interpolation mode, even when sample counts differ;
- one vertical crosshair and local intersection markers in every participant;
- X-only viewport pan, zoom, reset, and reveal bounds;
- pointer exit, focus loss, and touch-scrub cleanup; and
- re-entrancy protection so broadcast viewport updates cannot loop.

Y bounds, Y axes, series visibility, annotations, local selection, and local
tooltips remain independent by default. Durable point selection synchronization
is deferred until a concrete product need defines cross-chart identity.

The group publishes data values, never widget pixel offsets. Every chart maps
the shared X through its own plot bounds, so different Y-axis widths and
responsive sizes still align semantically.

### Lifecycle and artifacts

- Group membership attaches and detaches with the chart lifecycle.
- The caller owns and disposes the controller.
- A participant can opt out of cursor or viewport synchronization.
- Removed or detached charts stop receiving events immediately.
- Shared cursor state is transient and is never captured in a chart artifact.
- Each chart's current viewport remains its own durable `ChartViewState`; a
  broadcast viewport event updates participants through their normal viewport
  path and revision accounting.

### Showcase composition

Add one dedicated synchronized-chart example containing:

- Speed as a Line series;
- Elevation as an Area series;
- Heart rate as an Area series;
- one aligned distance X domain; and
- local headings, units, and latest values above each plot.

Use proximity and alignment instead of three heavy cards. Desktop shows three
compact stacked plots. Compact screens retain the stack, reduce nonessential
axis repetition, and provide touch scrubbing with at least a 48 px interaction
target.

## Explicit exclusions

- Forecast calculation, confidence intervals, weather APIs, or time-series
  imputation.
- Marker-specific dash patterns, animated dash phase, gradient strokes, or
  patterned Bar/Pie/Donut outlines.
- Dash changes during an active transition; the target series style applies to
  the whole rendered frame.
- Multi-panel rendering, shared Y axes, or one artifact containing several
  independent charts.
- Synchronizing Workbench tables, Source freshness, local Y zoom, annotations,
  tooltips, or durable selections in Sprint 12.

## Acceptance gates

### Sprint 11

- Pure path tests prove solid, dotted, dashed, dash-dot, multi-contour, and
  malformed-pattern behavior.
- Pixel-backed Line and Area tests cover all interpolation modes, Area fill
  continuity, baseline fill, segment overrides, glow, and animation progress.
- Artifact, hydration, capability, generated source, equality/copy, and legend
  tests prove the public contract.
- Forecast page tests prove one canonical identity, the exact segment-style
  boundary, hollow markers, vertical current-time threshold, Workbench modes,
  and wide/compact layout.
- Complete package/showcase analyzers and suites, release builds, pub.dev dry
  run, direct-route browser checks, and local pixel review pass.

### Sprint 12

- Unit tests prove data-X broadcast, rendered-path intersections, lifecycle,
  opt-outs, re-entrancy protection, and X-only viewport synchronization.
- Real render-path tests prove aligned crosshairs across different plot sizes,
  sample counts, interpolation modes, and Y domains.
- Pointer, touch, keyboard, compact, and reduced-motion behavior pass.
- Complete publication and release gates plus wide/compact local pixel review
  pass before promotion.
