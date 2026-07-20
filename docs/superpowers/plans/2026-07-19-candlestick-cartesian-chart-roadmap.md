# Candlestick Cartesian Chart — Delivery Roadmap

**Date:** 2026-07-19  
**Branch:** `feature/candlestick-showcase-completeness`
**Status:** Core Candlestick clusters are merged; final showcase-completeness review is local
**Design:** `docs/superpowers/specs/2026-07-19-candlestick-cartesian-chart-design.md`
**Navigator handoff:** `docs/superpowers/specs/2026-07-20-cartesian-navigator-architecture-handoff.md`
**Value-summary handoff:** `docs/superpowers/specs/2026-07-20-cartesian-value-summary-architecture-handoff.md`

## Product outcome

Ship Candlestick as a complete built-in Cartesian family, then use normal
Braven Cartesian composition to deliver the stock-style range selector,
navigator, and optional volume pane shown in the reference.

The lane is successful only when OHLC semantics survive every layer: renderer,
tracking, accessibility, controller state, artifacts, native Data mode,
generated Source, agentic input, showcase, and performance verification.

## Sequence at a glance

| Slice | Outcome | Review checkpoint |
|---|---|---|
| 1 | Typed OHLC model, validation, bounds, and geometry lab | Complete locally |
| 2 | Native Candlestick paint, theme, hit testing, and core chart route | Complete locally; pixel review approved |
| 3 | Tracking, keyboard, semantics, temporal helpers, and motion | Complete locally |
| 4 | Artifacts, hydration, Data/Split, Source, AI schema, and Workbench | Complete locally |
| 5 | Range presets, navigator, ordinal sessions, and optional volume composition | Complete locally |
| 6 | Dense-data grouping, benchmarks, E2E, docs, and release readiness | Interactive review in progress |

No PR is opened between slices unless the user explicitly requests one. The
review surface remains local throughout the lane.

## Slice 1 — OHLC foundation and geometry lab

**Status:** Complete locally — 2026-07-19

### Scope

- Add `CandlestickDataPoint`, `CandlestickPointStyle`,
  `CandlestickChartStyle`, `CandlestickAnimationStyle`, and
  `CandlestickChartSeries`.
- Make close the inherited canonical Y value while exposing typed OHLC values.
- Enforce finite values, OHLC ordering, strict unique X ordering, and one
  Candlestick series per plot.
- Define allowed Line/Area/Scatter overlays and reject same-plot Bar in v1.
- Extend `SeriesStyle`, public exports, and Cartesian layout validation.
- Add pure `CandlestickGeometry` and viewport-aware geometry resolution.
- Extend data bounds to use low/high and candle-width X padding.
- Add deterministic tests for rising, falling, doji, flat, single-point,
  irregular-spacing, invalid, and off-viewport candles.
- Establish cold/warm geometry benchmarks before painter integration.

### Acceptance gates

- Direct Dart construction and validation have index-specific failures.
- No invalid OHLC input is silently reordered or clamped.
- The body, wick, paint, and semantic bounds are deterministic at multiple
  device-pixel ratios.
- One large X gap cannot inflate body width beyond the configured maximum.
- 50,000 ordered candles resolve only the visible range rather than scanning
  the complete source list on each viewport change.
- Existing Cartesian families remain green.

### Review surface

A small internal geometry lab paints rising, falling, doji, irregular-time, and
dense candles without yet claiming Workbench support.

### Local verification

- Public typed OHLC model, styles, animation settings, and series validation
  are implemented with `close` as canonical `y`.
- Cartesian composition accepts one Candlestick series plus Line, Area, and
  Scatter overlays; same-plot Bar and a second Candlestick series fail closed.
- Low/high bounds, flat single-point padding, robust lower-median X spacing,
  clamped candle widths, doji bodies, DPR alignment, and off-viewport culling
  have deterministic tests.
- The direct internal review surface at
  `/?capture=candlestick-geometry` paints irregular and dense geometry, exposes
  body width and corner controls, and remains explicitly outside
  `BravenChartPlus` until Slice 2.
- The complete package suite passes: 2,132 tests.
- `flutter analyze lib` and the standalone example `flutter analyze lib test`
  pass. Repository-wide analysis remains blocked by pre-existing optional
  dependencies in vendored `packages/fleather` and legacy golden/integration
  utilities; neither is touched by this lane.
- On the current machine, cold indexing 50,000 ordered candles measured
  7.499 ms during the full suite and resolving 1,000 visible candles averaged
  0.181 ms. Focused runs measured 4.345 ms and 0.122 ms respectively.
- Compact and desktop geometry-lab widget tests pass, the release web build
  succeeds, and browser capture confirms the desktop surface renders rather
  than returning a blank route.
- The complete standalone example suite passes: 208 tests.

## Slice 2 — Native renderer and first showcase route

**Status:** Complete locally — 2026-07-19

### Scope

- Add Candlestick dispatch to the existing Cartesian `SeriesElement`.
- Keep candle geometry and paint helpers isolated from Bar geometry.
- Implement batched uniform body fill, border, wick, and doji paths.
- Add the per-point override slow path only when needed.
- Add `CandlestickTheme` to light, dark, and custom `ChartTheme` handling.
- Implement plot clipping, crisp one-pixel strokes, legend symbol, preview
  capture, empty/loading behavior, and selected/focused presentation.
- Implement body-first and wick-tolerant hit testing with original source refs.
- Add a `candlestick-charts` route and one controlled reference preset.

### Acceptance gates

- Low/high extremes are never clipped and close-only bounds cannot pass tests.
- Rising/falling/doji remain distinguishable in light, dark, monochrome, and
  common colour-vision simulations.
- Uniform warm paint creates no per-candle `Paint`, `Path`, or text object.
- Zoom/pan regenerates only visible geometry.
- Direct route loads at compact and desktop sizes with no blank state,
  overflow, or severe browser console entry.

### Review surface

The local route exposes body mode, candle width, border, wick, corner, and theme
controls for the first pixel review.

### Local verification

- Candlestick is registered as the eighth showcase chart family, with a
  dedicated navigation destination, Chart Types catalogue preview, and direct
  `/?page=candlestick-charts` route.
- The route uses the native Cartesian `SeriesElement`, not Bar emulation, and
  composes a native Line close-average overlay on the same plot.
- Uniform candles batch rising, falling, and doji body, border, and wick paths;
  point-specific styles take an explicit slow path.
- Viewport queries materialize only visible candles and body-first hit testing
  retains original source indices and point references.
- `CandlestickTheme` participates in all built-in themes, resolved theme
  artifacts, generated Dart theme source, equality, and copy operations.
- Built-in and overlay legends render a candlestick-specific wick/body symbol;
  the showcase direction legend separately explains hollow rising, filled
  falling, doji, and the Line overlay without relying on colour alone.
- The page exposes live body mode, width, maximum width, corner radius, minimum
  doji height, border, wick, overlay, theme, grid, axes, scrollbars, zoom, and
  pan controls. Compact layout uses the shared options sheet and keeps header
  actions within the viewport.
- The complete package suite passes: 2,138 tests. The complete standalone
  showcase suite passes: 211 tests. `flutter analyze lib` and showcase
  `flutter analyze lib test` are clean.
- Release web build and direct-route HTTP check pass. The local review route is
  available at `http://127.0.0.1:8132/?page=candlestick-charts`.
- On the current machine, 50,000 source candles with 1,000 visible resolve in
  0.223 ms average and warm-paint in 0.018 ms average during the complete suite;
  the focused warm-paint run measured 0.009 ms average.

## Slice 3 — Tracking, temporal behavior, and motion

**Status:** Complete locally — 2026-07-19

### Scope

- Add nearest-X sample tracking for Candlestick with no interpolation.
- Extend `ChartDataHit`, crosshair rendering, and tooltip rendering with Open,
  High, Low, Close, direction, and open-to-close change.
- Add keyboard traversal, activation, focus, selection, and complete semantic
  labels.
- Add UTC epoch-millisecond formatting and runtime locale binding guidance.
- Add `FinancialTimeDomain` for ordinal index ↔ timestamp mapping.
- Demonstrate elapsed-time gaps and equal-spaced ordinal sessions explicitly.
- Implement X-ordered entrance reveal and stable OHLC update interpolation.
- Extend streaming bounds to low/high and add a typed latest-candle upsert for
  revising the active interval without appending duplicates.
- Respect zero-duration themes and reduced motion.

### Acceptance gates

- Crosshair lookup is `O(log n)` and returns the original source candle.
- Tooltip and axis labels remain stable at doji and flat-value candles.
- Keyboard and assistive traversal announce all four OHLC values and state.
- Elapsed and ordinal examples label the same timestamps without confusing
  their different spacing semantics.
- Animation keeps target bounds fixed, preserves point identity, and never
  mutates the source document.
- Live upsert replaces equal-X final candles, appends increasing X, rejects
  older X, and keeps the circular-buffer size stable during revision.
- Existing synchronized Cartesian tracking remains green.

### Review surface

The local route adds tracking and motion presets plus toggles for elapsed versus
ordinal spacing.

### Local verification

- Candlestick crosshair tracking performs one ordered nearest-X lookup, keeps
  the original source index, and always reports a complete non-interpolated
  OHLC sample with direction and open-to-close change.
- `ChartDataHit`, tracking rows, marker tooltips, and semantics share the typed
  `CandlestickInteractionDetails` payload rather than rebuilding financial
  values in individual renderers.
- Left/right keyboard traversal, Enter/Space activation, focus, selection, and
  visible semantic nodes announce time/label, Open, High, Low, Close, change,
  direction, position, and selection state.
- `FinancialTimeDomain` maps strictly ordered UTC sessions to equal ordinal or
  elapsed epoch-millisecond X values with O(log n) nearest-session lookup and
  runtime-supplied locale formatting.
- The chart-type route exposes `Equal sessions` and `Elapsed UTC`, OHLC
  tracking/tooltip toggles, reduced-motion-aware entrance replay, update-motion
  control, and a `Revise latest` interaction on one stable candle identity.
- X-ordered entrance reveal reuses the Cartesian motion timeline. Compatible
  update frames interpolate valid OHLC tuples while source data and target
  bounds remain final and immutable; reduced motion resolves synchronously.
- `StreamingBuffer` derives Y bounds from candle low/high. The typed live
  upsert appends increasing X, revises equal X in O(1), rejects older X, and
  coalesces paused revisions without growing the buffer.
- Full package analysis is clean and the complete package suite passes 2,156
  tests. Standalone showcase analysis is clean and its complete suite passes
  212 tests. The release web build and direct-route HTTP 200 check pass.
- Full-suite performance measured 7.570 ms for 1,000 nearest-X queries over
  50,000 candles and 11.247 ms for 10,000 same-candle revisions. Focused
  renderer checks remain at 4.343 ms cold indexing, 0.122 ms virtualized
  geometry, and 0.010 ms warm paint for 50,000 source / 1,000 visible candles.
- The refreshed interaction review remains available at
  `http://127.0.0.1:8132/?page=candlestick-charts`.

## Slice 4 — Full family and Workbench contract

**Status:** Complete locally — 2026-07-19

### Scope

- Add built-in artifact type `candlestick`, capabilities, point OHLC extension,
  JSON round trip, validation, and hydration.
- Support inline point and columnar storage without losing OHLC or timestamp.
- Add `ChartTableProjectionKind.candlestick` with Time/X, Open, High, Low,
  Close, change, change percent, unit, copy, CSV, focus, and selection.
- Add exact-X overlay columns for permitted Line/Area/Scatter indicators.
- Emit `CandlestickChartSeries` and `CandlestickDataPoint` from generated Dart.
- Extend source capture and runtime formatter diagnostics.
- Extend agentic schema/builder with required OHLC fields and shared validation.
- Mount every preset in `BravenChartWorkbench` with Chart, Data, Split, and
  Source.
- Add codec, migration, hydration, table, CSV, source-determinism, syntax, and
  compile-fixture tests.

### Acceptance gates

- Portable round trip preserves every OHLC value, timestamp, point style,
  series style, axis, annotation, animation, and source reference.
- Older runtimes fail closed on Candlestick capabilities rather than rendering
  close-only data.
- Data and CSV are lossless; derived change fields are labelled as derived.
- Generated source compiles and reconstructs equivalent chart state.
- AI input cannot create a Candlestick series from generic `(x, y)` data.
- Chart/Data/Split/Source fail independently and do not remount the chart.

### Review surface

The main Candlestick page becomes the complete chart-type detail page and every
preset exposes Source.

### Local verification

- Portable artifacts register Candlestick as a built-in family with explicit
  OHLC and motion capabilities; inline-point and inline-column storage both
  preserve timestamp, point style, series style, animation, and canonical
  close-as-Y validation through hydration.
- Native Data and CSV projection expose Time/X, Open, High, Low, Close,
  derived change and change percent, unit, labels, source references, and
  exact-X Line/Area/Scatter overlay values.
- Generated Dart emits typed `CandlestickChartSeries` and
  `CandlestickDataPoint` construction, passes deterministic source checks, and
  compiles in the generated-source fixture.
- Agentic schema and builder require typed OHLC input, reject generic `(x, y)`
  candle data, and share the package's strict OHLC validation.
- The chart-type surface now mounts the native family in
  `BravenChartWorkbench` with Chart, Data, resizable Split, and Source modes.
- Package analysis and the complete package suite pass. Standalone showcase
  analysis and all 213 showcase tests pass, including the Workbench mode
  matrix and generated-source compile fixture.
- Full-suite performance showed no regression: 1,000 nearest-X queries over
  50,000 candles measured 6.061 ms, 10,000 active-candle revisions measured
  11.287 ms, and 1,000 visible candles from a 50,000-source series measured
  0.216 ms geometry and 0.016 ms warm paint averages.

## Slice 5 — Stock composition

**Status:** Complete locally — 2026-07-19

### Scope

- Add a stock-composition showcase built from ordinary Braven charts.
- Add 1m, 3m, 6m, YTD, 1y, and All preset controls plus explicit date bounds.
- Add a compact Area/Line navigator derived from close values.
- Add a draggable navigator window with persistent pointer handles and live
  viewport preview; hand native keyboard and semantics work to the dedicated
  Cartesian navigator lane.
- Add a public viewport command that range controls and navigator can share.
- Synchronize main candle, optional volume Bar pane, and navigator X viewport.
- Keep each pane's Y scale independent.
- Add ordinal-session and elapsed-time modes using one `FinancialTimeDomain`.
- Provide copyable composition code beneath the Workbench when the wrapper
  itself is outside the single-chart Workbench boundary.

### Acceptance gates

- Main pan/zoom updates the navigator window and navigator drag updates the main
  visible range without feedback loops.
- Range presets resolve correctly across year boundaries and missing sessions.
- Adding/removing the volume pane does not reset the main viewport.
- Compact layout wraps controls and keeps the navigator window operable.
- The composition is explicitly documented as reusable coordination, not a
  second Candlestick renderer.
- Session performance measurements display main, volume, and navigator cost.

### Review surface

The local route matches the reference's information architecture while
retaining Braven styling and Workbench behavior.

### Local verification

- The chart-type page now switches between the single-chart Workbench and a
  stock composition built from native Candlestick, Line, Bar, and Area
  participants; it does not introduce a second financial renderer.
- `ChartInteractionGroupController.setViewport` and `viewportListenable` give
  range controls and the navigator a public host-owned viewport contract with
  participant opt-out and feedback-loop protection.
- 1m, 3m, 6m, YTD, 1y, and All presets use one 420-session
  `FinancialTimeDomain`; the same selection survives ordinal-session and
  elapsed-UTC switching across weekends and year boundaries.
- Price and optional volume share only X cursor/viewport state and retain
  independent USD and volume Y domains. Removing and restoring volume leaves
  the active viewport unchanged.
- The full-domain Area navigator visualizes the active range through one
  draggable X-only range window. Its own cursor and viewport synchronization
  are disabled so it never tracks during manipulation or collapses to the
  selected window. Dedicated keyboard, semantics, and touch-target contracts
  remain explicit scope for the native Cartesian navigator handoff.
- The composition includes copyable coordination source and isolated passive
  frame instrumentation for active charts, source/visible sessions, samples,
  p95 build/raster, and frames over 16.7 ms. Diagnostics refresh no more than
  twice per second without rebuilding any chart participant.
- Desktop tests retain more than 250 logical pixels for the main price chart;
  compact tests cover wrapped controls and prevent a zero-sized plot.
- Package analysis is clean and all 2,166 package tests pass. Showcase
  analysis is clean and all 216 showcase tests pass. The release web build,
  including its Wasm dry run, succeeds.
- Full-suite measurements remained below one frame: 12-chart synchronized
  cursor fanout measured 3.51 ms p95 for 1,000 moves; Candlestick nearest-X
  measured 7.451 ms per 1,000 queries; 10,000 latest-candle revisions measured
  11.921 ms; and 50,000-source / 1,000-visible geometry and warm paint averaged
  0.237 ms and 0.015 ms respectively.

## Slice 6 — Grouping, performance, and promotion readiness

**Status:** Final showcase-completeness review in progress; dartdoc tooling qualification recorded

### Scope

- Add opt-in density-aware OHLC grouping outside paint.
- Aggregate first open, maximum high, minimum low, and last close.
- Retain every represented source index and keep Data/CSV raw by default.
- Add grouped tracking and explicit grouped tooltip/semantic copy.
- Run 50,000-source, 5,000-visible, 1,000-animated, crosshair, pan/zoom, and
  three-pane fanout benchmarks.
- Add goldens for light, dark, doji, irregular gaps, ordinal sessions, compact
  stock composition, and grouped density.
- Complete public guide, API docs, feature matrix, changelog, and gallery/chart
  type navigation.
- Run analyzers, complete package/example suites, release builds for both base
  paths, direct-route/refresh checks, browser console checks, dartdoc, and
  pub.dev dry run.

### Acceptance gates

- Every benchmark remains below the established 16.67 ms p95 frame budget or a
  measured device/build-mode qualification is documented before promotion.
- Grouping never changes raw artifacts, native Data rows, or default CSV.
- No visible aliasing, clipped wick, unstable body width, crosshair mismatch,
  remount, overflow, blank state, or severe console error survives E2E.
- Public docs distinguish native Candlestick, stock composition, and excluded
  financial analytics.
- The final local release route remains available for user review.
- Commit/PR occurs only after explicit user approval.

### Landed in the first Slice 6 cluster

- Added an opt-in `CandlestickDensityGrouping` public contract with
  pixel-width and minimum-group-size thresholds.
- Added a pure, globally aligned OHLC projection outside paint using first
  open, maximum high, minimum low, and last close.
- Carried complete raw source spans through geometry, hit testing, selection,
  focus, crosshair tracking, tooltip values, and semantic copy.
- Kept the immutable series points and Workbench table/export inputs raw; the
  showcase verifies 2,000 source rows while rendering grouped candles.
- Added portable artifact, hydration, AI-builder, and generated-Dart support
  plus the `series.candlestick.density-grouping.v1` capability.
- Added a focused showcase density section and a deterministic 2,000-candle
  stress data set.
- Added permanent 50,000-source grouping and grouped-crosshair benchmarks. On
  the first local run, geometry averaged 0.242 ms and 1,000 grouped crosshair
  queries completed in 8.969 ms.
- Completed the remaining permanent performance matrix on the established
  local benchmark environment. The authoritative combined run measured:
  - 5,000-visible warm paint at 0.008 ms median / 0.009 ms p95;
  - 1,000-candle animated revision and paint at 1.904 ms median / 2.995 ms p95;
  - 5,000-visible pan/zoom regeneration at 3.822 ms median / 5.194 ms p95;
  - three-pane cursor fanout for 1,000 moves at 2.767 ms median / 10.733 ms p95;
  - synchronized price/volume viewport fanout at 1.666 ms median / 2.474 ms
    p95 while the navigator remained local; and
  - 50,000-source grouped geometry at 0.280 ms average and 1,000 grouped
    crosshair queries in 11.442 ms.
- Corrected the benchmark percentile helper to use the nearest-rank p95 rather
  than treating the maximum sample as p95 for a 20-sample run.
- Hardened the three-pane cursor microbenchmark against shared-runner
  preemption after CI twice reported an 18 ms p95 beside a stable 4.4 ms
  median, while an intervening identical run passed. The gate still publishes
  1,000 synchronized cursor moves per sample and keeps the 16.667 ms budget;
  it now measures three independent p95 trials, requires every trial median to
  remain within budget, and uses the best uncontended p95 to distinguish
  sustained fanout work from an operating-system scheduling stall. Five
  consecutive local invocations and the complete two-test benchmark file pass.
- Added and visually reviewed deterministic golden coverage for light and dark
  themes, doji bodies, proportional irregular gaps, ordinal trading sessions,
  the compact price/volume/navigator stock composition, and grouped density.
- Added the public Candlestick guide, chart-type overview, feature-matrix row,
  README support statement, and unreleased changelog. The documentation
  distinguishes native OHLC rendering, synchronized stock composition, and
  application-owned calendars, data feeds, indicators, and analytics.
- Release browser testing exposed and fixed a direct-route lifecycle defect in
  which a caller-owned `ChartWorkbenchController` could be attached to a
  transient second Workbench mount. The Candlestick page now uses one
  Workbench-owned controller per mounted surface, with an initial-route
  regression test.
- Package `lib` analysis and showcase analysis are clean. The complete 247-test
  showcase suite passes after the lifecycle, interactive configuration, and
  post-Scatter rebase work.
- Release web builds pass for `/` and `/braven_charts/`, including Wasm dry
  runs. The final root release route returns HTTP 200 for both the shell and
  compiled script at
  `http://127.0.0.1:8197/?page=candlestick-charts`.
- Logged headless Chrome direct-load and same-profile refresh checks render the
  complete reduced-motion Candlestick surface without an application
  exception. Their 1600 x 1000 captures are byte-identical, confirming stable
  refresh layout and final-frame rendering.
- `dart pub publish --dry-run` reports only the expected dirty-worktree warning
  and no package-content warning.
- Flutter-bundled dartdoc 9.0.4 remains blocked before package diagnostics by
  its existing internal `DocumentationComment._stripDocImports` `RangeError`.
  The failure is tool-internal and unchanged from the prior Candlestick lane;
  maintained analyzers remain clean.

### Landed in the interactive configuration review cluster

- Replaced the two-state surface switch with wrapping, directly selectable
  examples for balanced price action, trend, volatility, gaps and doji,
  accessible direction cues, density, and synchronized stock composition.
- Added deterministic normal-data controls for 12–120 visible sessions, price
  range, trend bias, and opening-gap frequency while retaining the existing
  2,000-source density path and raw Workbench rows.
- Added chart-theme and candle-palette selection, entrance and revision motion,
  complete candle geometry and stroke controls, and palette-aware direction
  keys.
- Added configurable moving-average visibility, window, stroke width, and
  colour plus built-in series-legend visibility, position, and dragging.
- Applied shared theme, grid, axis, zoom, pan, tracking, scrollbar, palette,
  overlay, and legend controls to the stock-composition price and volume panes
  where the property is meaningful.
- Collapsed the stock navigator's disconnected annotation and `RangeSlider`
  into one selected range window: dragging its body pans the shared viewport,
  dragging either edge zooms it, and range presets plus main-chart pan/zoom
  update that same window through the host-owned viewport controller.
- Navigator body and edge gestures now publish transient viewport previews on
  every pointer move, so the price and volume panes pan or zoom while the
  gesture remains active. The navigator opts out of cursor synchronization,
  preventing viewport manipulation from moving the charts' tracking cursor.
- The navigator's left and right resize grips remain visible and hit-testable
  independently of annotation selection, while its body uses `grab` on hover
  and `grabbing` on press to distinguish panning from edge resizing.
- Made range-annotation resize affordances dimension-aware: the X-only stock
  navigator now renders and hit-tests only its two side grips, while two-axis
  ranges retain their complete eight-handle editing surface.
- Added focused showcase tests for every example preset and the data, palette,
  overlay, and legend wiring. The Candlestick showcase suite now has 13 passing
  tests, including compact coverage and pointer-level navigator pan/resize
  verification against the synchronized viewport.
- Added dedicated interaction-detail controls for point and tracking tooltips,
  axis-value labels, intersection markers and radius, crosshair width and dash
  pattern, selection, keyboard navigation, and focus-border behavior.
- Added axis-side, X-tick-density, axis-label visibility, and minimum-body-width
  controls, all wired directly to the mounted chart rather than display-only
  showcase state.
- Added an accessibility-focused preset combining blue/orange hues, hollow
  rising bodies, stronger borders and wicks, visible doji, a close average, and
  a direction key so financial direction never relies on colour alone.
- Added five coherent styling recipes for balanced analytical, trading-terminal,
  accessible blue/orange, print-friendly monochrome, and latest-event emphasis
  treatments. Recipes are starting points; every underlying geometry and colour
  control remains independently adjustable.
- Added opt-in per-direction body, border, and wick colour overrides plus a
  point-level latest-candle body/border/wick highlight. The same resolved
  colours feed the Workbench chart, direction key, and stock-composition panes.
- Replaced binary motion switches with explicit entrance and OHLC-update modes,
  entrance stagger, 100–1,200 ms duration, curve selection, revision magnitude,
  and in-rail replay/revise actions wired to the mounted controller and native
  Candlestick transition contract.
- Added a progressive tracking-theme section covering crosshair, coordinate
  label, and tooltip colours; tooltip border width, corner radius, and font
  size; point-tooltip position; and cursor-follow behavior. One `TooltipStyle`
  now themes both point and multi-value OHLC tracking tooltips.
- Replaced every Candlestick-specific colour grid with the same exported
  `AnnotationColorPalette` used by native annotation editors. Direction,
  point-highlight, moving-average, crosshair, coordinate-label, and tooltip
  overrides now share the leading clear action, selected-swatch toggle,
  canonical presets, custom colour dialog, opacity support, and recent colours.
  Each cleared value restores the active chart or interaction theme instead of
  retaining a hidden showcase-only colour.
- Disabled hover-acquired keyboard focus on the Workbench Candlestick chart,
  removing the misleading blue hover outline. The whole-chart focus outline is
  now also off by default, while remaining available as an explicit showcase
  accessibility toggle; candle focus and selection styling remain independent.
- Increased compact composition height to preserve a valid plot after the
  expanded wrapping preset catalogue and options surface; focused compact and
  full Candlestick showcase tests pass. The Candlestick suite now has 15 tests,
  including renderer-contract assertions for custom element colours, point
  highlighting, native animation configuration, replay, crosshair styling,
  tooltip styling, and shared palette clear/toggle behavior.

### Landed in the final showcase-completeness cluster

- Added an eighth `Events & levels` preset that combines native Candlestick
  marks with a Cartesian session range, price threshold, and candle-linked
  point annotation. The preset remains available in Chart, Data, Split, and
  generated Source modes rather than using a one-off demo renderer.
- Added progressive annotation controls for visibility, threshold/window/event
  colours, stroke width, and threshold dash treatment. Every control changes
  the mounted annotation collection and uses the shared annotation palette.
- Added selected-candle and focused-candle colour controls alongside the
  existing crosshair, coordinate-label, and tooltip theme controls. The
  effective interaction theme now drives the renderer's real selection and
  focus paint paths.
- Audited the stock composition for display-only controls. Its price and
  volume panes now honor selection, keyboard, focus-border, axis-line, and
  Y-label controls; the price pane and navigator honor X-label/tick density;
  the price pane honors price-axis position; and its series legend honors
  position and dragging. The workbench-only direction key is hidden in stock
  mode instead of presenting a control with no mounted target.
- Added regression coverage for the eighth preset, annotation style wiring,
  selection/focus colours, stock-pane axis and interaction wiring, and compact
  selector scrolling. The focused Candlestick showcase suite now has 16
  passing tests.
- Standardized financial display precision at two decimals across price axes,
  pinned summaries, metric pills, tooltips, and native Workbench OHLC/change
  cells by attaching the portable `braven.number.fixed` formatter to the
  extracted price axis.
- Added an opt-in pinned OHLC summary that remains fixed in the plot's top-left
  corner, follows the active candle without following the pointer, and falls
  back to the latest candle. It is implemented as a showcase composition layer,
  leaving the native Cartesian renderer and artifact contract unchanged.
- Reorganized the options rail into explicit crosshair, candle-hover, pinned
  summary, and selection groups. Crosshair panel, axis values, intersection dot,
  candle hover card, and pinned summary are independently configurable; the
  hover card now defaults off so first load never presents duplicate OHLC cards.
- Added focused regression coverage for two-decimal artifact formatting,
  focus-outline defaults, and independent crosshair/hover/pinned-detail state.
  The focused Candlestick showcase suite now has 17 passing tests.
- Promoted the pinned summary from one fixed composition into two explicit
  presentations. The overlay can occupy any plot corner; the embedded mode is
  a native draggable `TextAnnotation.rich` included in annotation rendering,
  portable artifacts, and generated Source. Both modes share background,
  opacity, border, text, accent, radius, padding, and type-size controls backed
  by the standard annotation colour palette. The focused suite now has 19
  passing tests covering style wiring, live candle updates, annotation drag,
  and overlay positioning.
- Corrected optional summary-colour semantics so the palette clear action and
  selected-swatch toggle remove background and border paint instead of
  restoring a faint theme fallback. A cleared background also removes the
  overlay shadow. Tightened the default overlay to a 168-pixel width, 8-pixel
  padding, 11-pixel detail type, smaller identity mark, and denser row rhythm.
- Fixed the Candlestick Source hydration warning by adding an explicit
  formatter registry to `ChartDartSourceOptions` and sharing the page's session
  formatter registry between Data and Source. Generated Source can now hydrate
  custom portable formatter descriptors without misreporting them as
  unregistered; genuine non-portable callback omissions remain visible as
  source-generation notes.
- Re-ran the complete promotion matrix after the completeness work: package
  analysis and showcase analysis are clean; all 2,372 package tests and all
  251 showcase tests pass; the release web build and Wasm dry run pass; and the
  direct Candlestick route plus compiled script return HTTP 200 on port 8197.
  The established Candlestick paint, revision, grouping, nearest-X, and
  synchronized-pane performance gates also pass in the complete package run.

### Still required before promotion

- User visual and interaction review of the expanded selector and control
  surface on the live release route.
- Re-run dartdoc when the Flutter-bundled dartdoc defect is resolved or a
  qualified replacement toolchain is adopted before publication.

## Recommended next move

Keep the release route available for the deferred full visual and interaction
review. Address any review findings, re-run the affected gates, then wait for
explicit commit/PR approval; do not start another chart-family lane from this
worktree.
