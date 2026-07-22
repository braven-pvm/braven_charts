# Chart Selection Implementation Plan

**Status:** In progress

**Architecture:**
[`2026-07-21-chart-selection-architecture.md`](../specs/2026-07-21-chart-selection-architecture.md)

**Lane:** `feature/selection-architecture`

## Delivery slices

### Slice 0 - contract and regression freeze

**Status:** Complete

- Record the approved acquisition/scope/projection architecture.
- Capture the interaction ownership matrix and compatibility boundaries.
- Add regression tests for current Bar, Scatter, Candlestick, radial, table,
  multi-axis slot, and artifact view-state behavior before changing state.

### Slice 1 - independent series and Line/Area selection

**Status:** Complete; visually approved

- Separate promoted-axis series from durable selected series.
- Add immutable multi-series state to the widget, controller, and view state
  while preserving the legacy singular artifact field.
- Route modifier-aware series activation through one reducer.
- Allow Line and Area data points to participate in durable point selection.
- Render selected series and selected Line/Area points through normal geometry.
- Add controller, JSON, source-generation, widget, and interaction tests.
- Add focused Line/Area showcase presets only at the first visual checkpoint.

### Slice 2 - semantic mark resolution

**Status:** Complete; visually approved

- Introduce implemented public selection scopes: `mark`, `category`,
  `categoryStack`, `wholeSeries`, and `markOrWholeSeries`.
- Add one renderer-neutral resolver from `ChartDataHit` and chart document to
  source identities.
- Expand aggregate Scatter hits using `effectiveSourcePointIndices`.
- Reuse Workbench shared-X row identity for Cartesian category selection.
- Add opt-in Bar category/stack/series policies for vertical, horizontal,
  grouped, stacked, normalized, waterfall, and overlaid layouts.
- Make radial/polar operations modifier-aware and expand grouped marks.

Implemented semantics:

- mark scope expands every source identity represented by an aggregate hit;
- category scope uses exact native X identity for Cartesian series and native
  category labels for radial/polar series, so reordered concentric rings still
  resolve the same category;
- stack scope is limited to Bar series sharing orientation, layout, resolved
  value axis, baseline, and stack/group identity;
- stacked Polar Columns resolve contributors by category label and positive or
  negative stack side;
- grouped and waterfall Bars intentionally keep stack scope within the source
  series because they do not form a multi-series composition stack;
- radial canvas and legend activation now use the same replace/add/toggle/
  subtract reducer as Cartesian input;
- the Bar States showcase exposes category and stack scope for live review;
- artifacts hydrate the legacy `mode`, `stack`, and `series` names while new
  documents emit `acquisitionMode`, `categoryStack`, and `wholeSeries`.

### Slice 3 - domain and free-form acquisition

**Status:** Complete; verified across acquisition modes and interaction owners

- Generalize acquisition into point, X interval, Y interval, rectangle, and
  lasso without changing semantic scope.
- Add an explicit selection tool state and visible compact toolbar.
- Add interval handles, transient preview, atomic commit, Escape cancellation,
  and touch hit regions.
- Reconcile interaction-mode and element-hit priority into one tested winner.
- Add multi-axis, scrollbar, navigator, pan, zoom, annotation, and context-menu
  conflict tests.

Current checkpoint:

- `ChartSelectionAcquisitionMode.xInterval` and `.yInterval` span the complete
  orthogonal plot dimension and honor transposed Cartesian transforms;
- Rectangle and lasso candidate lookup is renderer-neutral across Cartesian
  series while Scatter retains its indexed lookup;
- Line and Area Selection examples expose a compact, visible tool selector and
  the exhaustive inspector mirrors the active tool;
- interval preview is overlay-only, uses bounded point rings plus boundary
  handles, commits once on pointer-up, and Escape cancels before any committed
  point state is cleared;
- complete-series Line and Area activation uses a configurable path corridor
  (22 logical pixels by default), resolves overlapping paths by nearest
  distance, and expands the hovered stroke with immediate enter/exit feedback;
  marker-only scope keeps feedback on the acquired marker, while the explicit
  dual-target scope selects either a marker or a complete series, with marker
  acquisition winning inside its radius and no mixed point/series state;
- marker and complete-series acquisition radii are independent public options
  (`dataPointHitRadius` and `completeSeriesHitRadius`) and are exposed in the
  showcase inspector; the series corridor remains disabled for interval,
  rectangle, and lasso acquisition;
- point hover, point selection, series hover, and series selection emphasis are
  independent public scale options, with scope-aware showcase controls;
- the Selection showcase can hide the floating tracking information panel
  without disabling crosshair lines, axis labels, or intersection feedback;
- the standard data-point hover popup has a separate inspector switch backed
  by `TooltipConfig.enabled`.
- the shared Cartesian Chart Options section now has one master crosshair and
  tracking switch which gates guide lines, axis values, intersection markers,
  and the floating tracking panel while leaving the ordinary point tooltip
  independent.
- primary-button annotation manipulation now resolves before overlapping data
  marks, scrollbar mode outranks the competing tap recognizer, and focused
  conflict coverage proves draggable annotations, scrollbars, external
  navigators, middle-button pan, wheel zoom, secondary-click menus, and
  multi-axis intervals preserve durable selection while the owning interaction
  proceeds.

### Slice 4 - selection expression and performance

**Status:** Complete; benchmarked at 100k and 1m observations

- Add compact series, point-span, interval, and explicit-reference clauses.
- Resolve revision-bound `ChartSelectionSnapshot` statistics lazily.
- Add optional stable point keys and topology-change remapping.
- Add sorted-domain binary search and indexed dense-geometry acquisition.
- Benchmark 100k and 1m observation selection and callback materialization.

Current checkpoint:

- `ChartSelectionExpression` stores clearly named whole-series,
  point-index-span, X-interval, Y-interval, and explicit-point-reference
  clauses;
- resolved point identities compress deterministically while point references
  already covered by a whole-series clause are omitted;
- `ChartSelectionSnapshot` binds an expression to one opaque effective
  document revision and materializes references, extents, and statistics only
  when requested;
- ordered-X interval resolution uses binary search plus output size, with a
  counted 100k-point regression proving it does not linearly scan the source;
- the mounted controller exposes both compact intent and the current lazy
  revision-bound snapshot without changing the legacy eager callback result.
- `ChartDataPoint.pointKey` and `ChartPointKeyRef` now provide optional stable
  identity across source reorder, insertion, and bounded-stream eviction;
- keyed selections compress into `ChartSelectionPointKeysClause`, resolve
  lazily through a duplicate-rejecting per-series index, and remap consistently
  for Cartesian and radial families while unkeyed data preserves prior rules;
- generic, Range Area, and Candlestick points retain keys through artifact
  JSON, inline/binary columnar payloads, AI input, legacy JSON, generated Dart,
  copy operations, and Range Area transitions;
- regressions cover expression resolution after reorder, duplicate-key
  rejection, Cartesian and Pie selection remapping, and portable representation
  round trips.
- selection statistics and extents stay lazy and use a streaming summary for
  whole-series, large contiguous-span, Y-interval, unordered-X, and large
  ordered-X selections, avoiding one `ChartPointRef` and result allocation per
  observation when callers only need aggregates;
- narrow ordered-X selections retain binary-search plus output-size behavior;
- dedicated benchmarks cover 100k and 1m whole-series summaries plus a narrow
  interval inside a 1m-point ordered series.

### Slice 5 - selection-scoped extraction

**Status:** Complete; verified against Workbench and artifact surfaces

- Add `ChartDataScope.selection` and projection options to the existing
  document/artifact extraction lifecycle.
- Project participating series, data, axes, annotations, legends, and theme.
- Interpolate Line/Area boundaries through the canonical path interpolation.
- Preserve complete OHLC and range tuples; recalculate radial shares.
- Rebase point-index annotations/chords and return structured warnings.
- Add artifact JSON, hydration, generated Dart, and round-trip tests.

Current checkpoint:

- `ChartDataScope.selection` now enters the existing synchronous document and
  artifact extraction path rather than introducing a parallel chart builder;
- `ChartSelectionProjectionOptions.seriesProjection` explicitly chooses exact
  selected points or complete participating series;
- complete-series selections remain complete in either projection, empty
  selections fail with `selection_empty`, and stale point references produce
  structured warnings;
- selection-scoped documents start fitted with durable selection cleared while
  retaining compatible axis-slot and legend placement state;
- unrelated Y axes and axis-slot view state are pruned from the detached chart;
- `ChartSelectionAnnotationProjection` provides explicit omit, contained, and
  clip-to-selection policies, with clipping as the default;
- point annotations, chord endpoints, perpendiculars, and error bars rebase to
  projected indices; incompatible or partial components emit structured
  warnings instead of retaining stale references;
- ranges clip to selected data-space bounds, thresholds resolve against their
  referenced series axis, and pins outside the selected extent are omitted;
- derived trend annotations remain only when their complete source series is
  retained; partial derived annotations are omitted with a structured warning;
- focused widget coverage proves exact-point, participating-series,
  complete-series, empty-selection, annotation, multi-axis, hydration, and JSON
  round-trip behavior.
- exact drag bounds now survive as revision-bound X/Y interval clauses instead
  of being collapsed to the source markers that happened to fall inside them;
- `BravenChartController.selectExpression` provides a first-class,
  revision-safe programmatic entry point for compact selection intent;
- selected Line and Area intervals synthesize exact boundary observations via
  the same linear, stepped, Bezier, or monotone interpolation geometry used by
  rendering, including sparse intervals containing no source marker;
- callers can explicitly request source-points-only interval projection when
  synthetic continuous boundaries are undesirable;
- Candlestick OHLC and Range Area low/high tuples remain atomic, while Pie,
  Donut, and concentric-ring projections retain raw values and therefore
  recompute contribution shares against each retained series total;
- selection snapshots pass through the source-capture adapter, and the normal
  Workbench Chart/Data/Split/Source freshness and round-trip contracts remain
  green.

### Slice 6 - visible actions and linked composition

**Status:** Complete; verified across Workbench presentations and interaction groups

- Add the selection summary/action strip to Workbench compositions.
- Wire Create chart, Zoom, Copy, CSV, Invert, and Clear.
- Add opt-in linked brushing through stable semantic keys and the existing
  interaction-group architecture.
- Verify focus, selection, table rows, source view, and host actions agree.

Current checkpoint:

- every Workbench presentation exposes one compact, semantic selection strip
  without remounting the chart or reducing short table layouts to an unusable
  height;
- Create chart, Zoom, Copy, CSV, Invert, and Clear all operate through the
  mounted controller and the existing artifact/table export paths;
- Create chart, Copy, and CSV use `ChartDataScope.selection`, so host callbacks
  and built-in actions receive the same selection-only projection;
- zoom is Cartesian-only, validates padding, and returns structured controller
  failures rather than silently changing an unsupported layout;
- linked brushing is explicitly opt-in through
  `ChartInteractionGroupOptions.synchronizeSelection` and transports only
  stable `seriesId` plus `pointKey` identities;
- linked selection resolves correctly when peer charts reorder the same source
  observations, suppresses feedback loops, and fails closed rather than
  broadcasting a partial selection when any selected point lacks a key;
- controller, widget, chart/table/split/source, copy/export, and compact-layout
  regressions cover the delivered contract.

Focused verification surface:

- the showcase now includes a dedicated `selection` route with one persistent
  Workbench and a wrapped family picker for Line, Area, Range Area, Bar,
  Scatter, Candlestick, Pie, Donut, Concentric Donut, and Polar Column;
- every case names the acquisition geometry and semantic scope it exercises,
  while shared operation, modifier, background-clear, and path-hit controls
  make cross-family differences directly comparable;
- only the active family is mounted, keeping dense and radial test cases
  isolated while preserving Chart/Data/Split/Source inspection and the shared
  selection action strip;
- route and family-matrix widget coverage asserts all ten configurations mount
  with their intended acquisition and scope contracts.

### Slice 7 - release hardening

**Status:** In progress; path accessibility and hostile showcase layouts verified

- Complete keyboard and screen-reader semantics for every chart family.
- Verify touch, compact layouts, RTL, reduced motion, themes, and long labels.
- Run package/example analysis and tests, performance suites, release web build,
  publish dry-run, direct-route browser review, and `git diff --check`.
- Update API reference, family guides, showcase capability matrices, changelog,
  and migration notes.

Current checkpoint:

- Line and Area now expose family-aware keyboard focus and live semantics;
  Left/Right traverses valid observations, Up/Down moves between series, gaps
  are skipped, and Enter/Space commits through the configured selection scope;
- Bar, Scatter, Candlestick, Range Area, Pie, Donut, Concentric Donut, and
  Polar Column keyboard activation now uses the same semantic resolver and
  replace/add/toggle/subtract policy as pointer input, including category,
  category-stack, and complete-series scopes;
- Shift+Space extends ordered Cartesian and radial selections from a stable
  keyboard anchor, Ctrl/Command+A selects bounded marks or every complete
  series, dense Scatter charts refuse eager select-all, and Escape clears both
  point and complete-series selection;
- semantic activation distinguishes point selection from complete-series
  selection and reports the series, observation, value, ordinal, and durable
  selection state without creating a parallel accessibility-only model;
- the focused Selection Lab remains stable at compact width under RTL, 1.25x
  text scaling, dark application chrome, and reduced-motion preferences;
- the public chart-types guide and unreleased changelog now describe semantic
  scopes, modifier operations, keyboard behavior, and selection extraction.

## First checkpoint acceptance criteria

- The branch remains based on current `origin/master` with no unrelated files.
- A Line or Area point tap can create durable point selection.
- A Line/Area stroke or fill can select a series; modifiers can retain more
  than one selected series.
- Series selection styling is visible and is not confused with point focus.
- Axis overflow promotion still behaves exactly as before.
- Controller and view-state snapshots expose both legacy promoted-axis state
  and durable multi-series selection.
- Existing Bar, Scatter, Candlestick, radial, table, and artifact tests remain
  green.
- The first interactive checkpoint has a focused showcase route and local dev
  server before PR creation.

## Verification matrix

| Layer | Required proof |
| --- | --- |
| Models | equality, copy, JSON defaults, legacy hydration |
| Controller | replace/add/toggle/subtract, detach, stale revision |
| Rendering | series and point visuals for Line and Area |
| Gestures | click, Shift, Ctrl/Command, Alt, background clear |
| Conflicts | annotations, navigator, scrollbars, pan, zoom, menus |
| Families | Line, Area, Bar, Scatter, Candlestick, Pie/Donut, Polar |
| Artifacts | capture, hydrate, generate source, compatibility |
| Performance | overlay preview and committed selection budgets |
| Showcase | wide/compact layout, keyboard, touch, direct route |

## Scope control

- Do not implement a second artifact or legend system.
- Do not fold unrelated showcase-property work into this lane.
- Do not expose a public scope or acquisition value before its resolver works.
- Do not store every point for whole-series or large contiguous selections.
- Do not change legacy defaults without a compatibility test and migration note.
