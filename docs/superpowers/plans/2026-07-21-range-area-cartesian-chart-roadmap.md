# Range Area Cartesian Chart — Delivery Roadmap

**Date:** 2026-07-21
**Branch:** `spec/ranged-area-chart`
**Status:** Range Area delivery and Financial consumption complete; final combined E2E gate passed
**Design:** `docs/superpowers/specs/2026-07-21-range-area-cartesian-chart-design.md`
**Base:** fast-forwarded to `origin/master` at `2a06a29e` after Financial PR #78

## Product outcome

Ship Range Area as a complete built-in Cartesian family and then consume it in
weather, confidence, forecast, and financial compositions.

The lane is successful only when `(x, low, high)` remains one atomic point
through renderer, bounds, interpolation, tracking, selection, animation,
artifacts, Data mode, source generation, Workbench, accessibility, and
performance verification.

The public implementation is not allowed to stop at a painter or showcase-only
prototype.

## Delivery principles

1. **One interval, one identity.** Do not model the band as two independent
   series.
2. **Exact geometry is shared.** Paint, reverse fill construction, tracking,
   and motion use the same interpolation descriptors.
3. **Composition stays composition.** Mean/median/forecast lines remain normal
   `LineChartSeries` overlays.
4. **Gaps are explicit.** They never become zero-valued intervals or portable
   NaN values.
5. **The showcase is first-class.** It is the renderer lab, property test
   interface, public guide, and Workbench validation surface.
6. **Vertical completion precedes release.** Artifacts, Data, Source,
   accessibility, performance, and docs are required family work.
7. **No PR between slices unless requested.** Keep one local review surface and
   preserve a focused diff until the user asks for a commit/PR.

## Sequence at a glance

| Slice | Outcome | Review checkpoint |
|---|---|---|
| 0 | Research, design, and implementation roadmap | Complete in this branch |
| 1 | Typed model, validation, bounds, and interpolation descriptors | Complete locally |
| 2 | Native paint, theme, hit testing, and first chart-type route | Complete; user pixel review approved |
| 3 | Tracking, labels, keyboard, semantics, and motion | Review surface ready; user interaction approved |
| 4 | Artifacts, hydration, Data/Split, Source, and agentic input | Complete locally |
| 5 | Full showcase lab and cross-family compositions | Complete; core showcase and Financial volatility composition approved |
| 6 | Performance, regression hardening, docs, and release readiness | Complete; final combined E2E and clean-archive gates pass |

## Dependency map

```text
RangeAreaDataPoint + validation
        |
        +--> low/high bounds
        |
        +--> interpolation segment descriptors
                 |
                 +--> fill + boundary geometry
                 +--> exact tracking
                 +--> update motion
        |
        +--> point artifact extension
                 |
                 +--> hydration
                 +--> Data/CSV
                 +--> generated Dart
                 +--> Workbench Source
```

The Financial Technical Indicators page is a downstream consumer. The core
family must remain independently buildable from the current master base. Its
financial integration is rebased only after that showcase lane has landed.

## Slice 0 — Research and architecture

**Status:** Complete in `spec/ranged-area-chart`

### Scope

- Compare official Highcharts, Syncfusion Flutter, Vega-Lite, and Matplotlib
  range-area contracts.
- Audit Braven model, renderer, interpolation, bounds, crosshair, motion,
  artifacts, table, source, Workbench, showcase, and performance seams.
- Decide public naming, typed point identity, canonical midpoint Y, explicit
  gaps, independent boundaries, centre-line composition, and v1 exclusions.
- Write the complete product design and this delivery roadmap.

### Result

- Public family is `RangeAreaDataPoint` + `RangeAreaChartSeries`.
- A point owns low/high atomically; the inherited canonical Y is midpoint.
- Gaps are explicit and portable.
- The fill is built from reusable forward/reverse interpolation descriptors.
- A mean/median/forecast line is an independent Line series.
- Core Range Area does not depend on the in-flight Financial showcase branch.

### Gate

- User reviews and approves the design direction before implementation begins.

## Slice 1 — Model, bounds, and geometry foundation

**Status:** Complete locally — 2026-07-21

### Scope

#### Public model

- Add `SeriesStyle.rangeArea`.
- Add `RangeAreaDataPoint`, `.atTime`, `.gap`, typed `copyWith`, equality,
  hash, midpoint/span, and shared validation.
- Add `RangeAreaChartSeries`, `RangeAreaBoundaryStyle`,
  `RangeAreaBorderMode`, `RangeAreaHitTestMode`, and typed label configuration.
- Enforce strict ordered unique X, finite intervals, explicit gaps, and
  `low <= high`.
- Add public barrel exports and API documentation.

Likely files:

- `lib/src/models/chart_series.dart`
- new `lib/src/models/range_area_data_point.dart`
- new `lib/src/models/range_area_chart_series.dart`
- new `lib/src/models/range_area_style.dart`
- `lib/braven_charts.dart`

#### Layout and bounds

- Register the concrete family in Cartesian layout validation.
- Allow Line, Area, Scatter, Candlestick, and multiple Range Area overlays
  under existing Cartesian restrictions.
- Extend `DataConverter.computeDataBounds()` to include every valid low/high
  and exclude gaps.
- Preserve explicit axis bounds and degenerate-range padding.

Likely files:

- `lib/src/layout/chart_layout_kind.dart`
- `lib/src/utils/data_converter.dart`

#### Shared interpolation descriptors

- Extract immutable linear, stepped, Bezier, and monotone segment descriptors
  from `InterpolationGeometry` without changing existing Line/Area output.
- Support exact forward append, reverse append with swapped cubic controls,
  and Y-at-X evaluation.
- Add `RangeAreaGeometry` for contiguous runs, gaps, upper/lower screen points,
  fill paths, boundaries, sides, and source-index mapping.
- Add ordered-X visible-window culling plus curve overscan.

Likely files:

- `lib/src/utils/interpolation_geometry.dart`
- new `lib/src/utils/range_area_geometry.dart`

### Tests first

- Point validation: valid, equal, inverted, non-finite, half-gap, full gap,
  empty, single, duplicate X, unordered X.
- Model: `copyWith`, equality, midpoint/span, gap identity, at-time mapping.
- Bounds: low/high extremes, gap exclusion, single zero-span, explicit axes,
  mixed Line/Range Area/Candlestick.
- Descriptor parity: every current Line/Area interpolation fixture remains
  byte/coordinate equivalent.
- Geometry: forward high + exact reverse low for all interpolations, irregular
  X, sides, gaps, connection, clipping, source indices, DPR.
- Complexity: 50,000-source / 1,000-visible lookup scales with visible window.

### Acceptance gates

- Generic midpoint-only bounds cannot pass.
- No invalid interval is swapped, clamped, sorted, or converted silently.
- Existing Line/Area golden and interpolation tests remain unchanged.
- No `Path.combine()` is used in the warm fill path.
- Geometry is pure and deterministic without widget or canvas state.
- Core package analysis and focused model/geometry suites are green.

### Review surface

An internal geometry lab may paint linear, monotone, stepped, gaps, gradient,
zero-span, and dense intervals. It is explicitly not yet advertised as
Workbench-complete.

### Local verification

- `RangeAreaDataPoint` preserves one low/high interval, midpoint compatibility
  Y, derived span, UTC time, typed copies, and explicit portable-ready gaps.
- `RangeAreaChartSeries` owns immutable typed points, strict ordered unique X,
  interpolation, fill/gradient, independent boundary styles, gaps, markers,
  labels, hit policy, and path motion configuration.
- `SeriesStyle.rangeArea`, public exports, Cartesian concrete-type validation,
  mixed Line composition, and low/high bounds are registered.
- Gaps contribute their X position but never a synthetic zero Y value.
- Shared interpolation descriptors reproduce existing Line/Area forward paths
  for linear, stepped, Bezier, and monotone modes. Cubic reverse traversal
  swaps endpoints and controls exactly.
- `RangeAreaGeometryEngine` creates separate upper/lower paths, one closed fill,
  optional side geometry, original source identities, split/connected gaps,
  and binary-searched viewport culling without widget or canvas state.
- 28 focused model, bounds, interpolation, geometry, and layout tests pass.
- The complete package suite passes 2,804 tests. The complete standalone
  showcase suite passes 329 tests.
- `flutter analyze --no-pub lib` and standalone showcase
  `flutter analyze --no-pub lib test` are clean.
- Focused benchmarking measured 2.289 ms to cold-index 50,000 intervals and
  0.790 ms average to resolve a 1,000-point visible monotone band from a
  50,000-point source.
- No public chart route is claimed yet: native `SeriesElement` painting begins
  in Slice 2 after this API/geometry checkpoint is approved.

## Slice 2 — Native renderer, styling, and first public route

### Scope

#### Renderer

- Add Range Area dispatch to the existing Cartesian `SeriesElement`.
- Paint fill, boundaries, sides, glows, markers, selection/focus, and labels in
  the specified order.
- Use uniform cached `Paint`/`Path` objects in the normal path.
- Isolate independent boundary dash/glow slow paths.
- Clip to plot bounds and preserve source point references through culling.
- Add band and nearest-boundary hit policies.

Likely files:

- `lib/src/elements/series_element.dart`
- targeted rendering helpers under `lib/src/rendering/` if the element would
  otherwise become materially harder to review.

#### Theme and legend

- Add `RangeAreaTheme` to light, dark, high-contrast, copy/equality, resolved
  theme documents, and source generation.
- Add a range-band legend glyph showing translucent fill and both boundaries.
- Resolve nullable boundary colours from series colour and theme.
- Reuse `AreaGradient` and the annotation-dialog optional-colour component.

Likely files:

- `lib/src/models/chart_theme.dart`
- legend renderer/model files
- source theme encoder/generator files

#### First chart-type route

- Add `range-area-charts` navigation and direct route.
- Add a controlled Temperature envelope preset: one Range Area and one
  independent observed Line.
- Mount it in `BravenChartWorkbench` only for Chart mode at this checkpoint;
  clearly mark Data/Source completion as a later slice if unavailable.
- Expose interpolation, fill, gradient, opacity, boundaries, border mode,
  markers, theme, grid, axes, zoom, and pan.

Likely files:

- new `example/lib/showcase/pages/range_area_charts_page.dart`
- showcase routing/navigation/catalogue files
- focused showcase widget tests

### Tests

- Painter/golden: light, dark, gradient, fill-only, closed, dashed boundaries,
  glow, markers, labels, gaps, single point, zero span, clipping.
- Hit: inside band, outside band, upper/lower proximity, overlap, culled source
  index, gap.
- Theme: defaults, overrides, clear colors, copy/equality, source/theme docs.
- Legend: glyph, hidden series, multiple bands, overlay ordering.
- Route: desktop/compact, reset, direct URL, no overflow/blank state.

### Acceptance gates

- Low/high extremes and both boundary paths match pure geometry.
- Hover does not invalidate geometry.
- Clear/select-again colour controls remove the override rather than applying
  a faint fallback colour.
- The mean Line can be hidden, styled, tracked, and listed independently.
- Route loads in release web at compact and desktop sizes.
- First pixel review is approved before broadening the sample catalogue.

### Local verification and review checkpoint

- Native Range Area painting now covers fill, stable plot-space gradient,
  independent upper/lower boundaries, optional closed sides, dash patterns,
  glow, paired markers, selection/focus, clipping, and reveal progress.
- Band and nearest-boundary hit policies preserve original source identity
  through visible-window culling; explicit gaps do not paint or hit-test.
- `RangeAreaTheme` is integrated into light, dark, high-contrast, theme
  documents, source generation, copy/equality, and the Range Area legend
  glyph.
- The public `range-area-charts` route provides Temperature, Confidence, and
  Volatility presets plus live controls for interpolation, band treatment,
  boundaries, palette overrides, hit policy, markers, and chart chrome.
- Optional colour controls use the shared showcase palette contract: clear and
  select-again both remove the override rather than leaving a faint colour.
- Focused renderer, theme-codec, source-generation, route, desktop, and compact
  showcase tests pass.
- Full package suite: 2,809 tests passed. Full showcase suite: 333 tests passed.
- Package and showcase analysis are clean; the release web build and direct
  route return successfully.
- A 1600 x 1000 release-build browser capture passed the internal layout pass;
  user first-pixel approval remains the gate before Slice 3.

## Slice 3 — Interaction, accessibility, labels, and motion

**Status:** Complete — interaction review approved — 2026-07-21

### Scope

#### Typed interaction

- Add `RangeAreaInteractionDetails` to hits, crosshair values, callbacks, and
  value summaries.
- Implement ordered nearest-X and exact interpolated low/high tracking from
  shared segment descriptors.
- Paint paired boundary intersection markers and paired Y-axis labels.
- Return no interpolated value inside a disconnected gap.
- Add floating tooltip, crosshair panel, point hover, pinned overlay card, and
  chart-annotation summary support through the shared value-summary model.

Likely files:

- new `lib/src/models/range_area_interaction_details.dart`
- crosshair tracker/renderer
- tooltip renderer
- Cartesian value-summary adapters/renderers
- hit/callback models

#### Labels, keyboard, and semantics

- Add low/high/both/midpoint/span label modes and typed formatter payload.
- Implement upper/lower placement, collision, and chart-edge behavior.
- Skip gaps during left/right traversal.
- Activate one interval identity and focus both boundaries.
- Announce time/X, low, high, span, position, and selection.

#### Motion

- Reuse X-ordered entrance reveal for fill, boundaries, markers, labels, glow,
  focus, and selection.
- Add a typed Range Area update transition, or safely generalize
  `PathSeriesTransition` without losing subclass data.
- Interpolate X/low/high atomically; recompute midpoint each frame.
- Handle compatible boundary and interior topology changes plus gap entry/exit.
- Preserve target bounds, formatter state, controller identity, and immutable
  source/target documents.
- Add replay controls and reduced-motion behavior to the route.

### Tests

- Tracking: nearest, interpolated, all interpolation modes, irregular X,
  multi-axis, synchronized panes, gaps, overlays, paired labels/markers.
- Tooltip/summary: default/custom formatter, unit, precision, pinned placement,
  background/border clear controls, overlay and annotation presentation.
- Keyboard/semantics: traversal, gap skip, selection, activation, exact copy.
- Motion: entrance directions, zero/reduced duration, equal/update/topology/gap
  frames, invariant at every sampled frame, exact target completion.
- Regressions: Line/Area/candlestick crosshair and path motion remain green.

### Acceptance gates

- Paint and tracking agree numerically at the same X.
- No tooltip or axis label reports midpoint as low or high.
- Horizontal crosshair visibility remains independently configurable.
- Static/pinned summaries can be styled and positioned using the shared
  Cartesian summary contract.
- Animation never creates `low > high` or changes target plot bounds.
- Cached tracking remains below 1 ms p95 on the reference harness.

### Review surface

The Range Area page adds Confidence interval and Gaps and steps presets, full
tracking controls, static summaries, keyboard focus, and entrance/update
replay.

### Local verification

- `RangeAreaInteractionDetails` carries low, high, midpoint, span, formatted
  values, and timestamp context through hits, tracking snapshots, tooltips,
  callbacks, semantics, and automatic Cartesian value summaries.
- Nearest and interpolated tracking use the same linear, stepped, Bezier, and
  monotone descriptors as paint. Disconnected gaps resolve to no interval;
  `connectGaps` resolves the same joined geometry the renderer paints.
- Tracking paints paired upper/lower intersection markers and paired Y-axis
  labels. The ordinary midpoint remains compatibility data and is never
  presented as either boundary.
- Low, high, both, midpoint, and span labels share the chart-wide collision
  coordinator, typed formatter payload, unit formatting, and edge-aware
  placement.
- Range Area keyboard traversal skips gaps, focuses both boundaries, supports
  selection, and announces X/time context, low, high, midpoint, span, ordinal,
  and selection state even when an ordinary Line is composed over the band.
- Entrance reveal and compatible data updates reuse the path animation
  controller. X, low, and high interpolate atomically; sampled gap entry/exit
  frames preserve `low <= high`, explicit gaps, immutable targets, and exact
  completion.
- The public review page exposes tracking, interpolation, paired markers,
  paired axis values, gap connection, label modes, collision, static overlay
  or draggable annotation summaries, summary appearance, keyboard navigation,
  reduced motion, entrance replay, and live update replay.
- The permanent 5,000-interval tracking benchmark measured 0.006 ms median and
  0.018 ms p95 during the complete package run, below the 1 ms acceptance gate.
- `flutter analyze --no-pub lib` and standalone showcase
  `flutter analyze --no-pub lib test` are clean.
- The complete package suite passes 2,821 tests; the standalone showcase suite
  passes 334 tests.
- `flutter build web --release` passes, the direct Range Area route returns
  HTTP 200, and the 1600 x 1000 release capture passed the internal layout
  review. User interaction and motion approval remains the Slice 3 gate.

## Slice 4 — Portable family and full Workbench contract

**Status:** Complete locally — 2026-07-21

The portable point/style codec, hydration capability negotiation, Data/CSV
projection, deterministic generated Dart, and Chart/Data/Split/Source showcase
surface are implemented. Strict typed agentic input and the remaining malformed
portable fixtures are now included.

### Scope

#### Artifacts and hydration

- Add series type `rangeArea`, capability negotiation, point extension
  `range-area.interval.v1`, style transport, and explicit gap bit.
- Validate canonical midpoint Y against low/high on decode.
- Preserve inline and columnar points, timestamps, metadata, labels, styles,
  axes, annotations, interaction, and motion.
- Add hydration and mounted-controller identity tests.

Likely files:

- `lib/src/artifacts/chart_series_document_codec.dart`
- capability/diagnostic files
- document extractor/hydrator
- source capture adapter

#### Native Data, Split, export

- Add low, high, and derived span auxiliary fields.
- Label the main Range Area value Midpoint rather than Value.
- Preserve gaps as empty cells and explicit state.
- Add long/wide Data mode, sorting, focus, selection, copy, and CSV.
- Verify exact-X alignment with ordinary overlays.

Likely files:

- `lib/src/table/chart_table_model.dart`
- `lib/src/table/chart_data_table.dart`
- `lib/src/table/chart_table_export.dart`

#### Source and agentic input

- Emit typed series, points/gaps, styles, labels, formatter descriptors,
  interaction, axes, annotations, and animation.
- Add deterministic parse/format/compile fixtures.
- Extend tool schema and `ChartConfigBuilder` with required low/high or gap.
- Reject generic `(x, y)` Range Area input.

Likely files:

- `lib/src/source/chart_dart_source_generator.dart`
- `lib/src/source/chart_source_capture_adapter.dart`
- `lib/src/ai/chart_config_builder.dart`
- tool schema files

#### Workbench

- Enable Chart/Data/Split/Source on every Range Area preset.
- Register first-party formatter descriptors so Source has no safe-fallback
  warning.
- Keep chart mounted while switching modes.
- Add source copy and data export tests.

### Tests

- Artifact: inline/columnar, gap, styled, multi-axis, annotated, mixed overlay,
  capability rejection, malformed/mismatched midpoint.
- Table/CSV: all fields, two decimals only where configured, gaps, units,
  timestamps, focus, selection, exact-X overlays.
- Source: deterministic output, parse, formatter registry, compile fixture,
  equivalent reconstructed document.
- Agentic input: valid, missing field, inverted, gap, unknown options.
- Workbench: Chart/Data/Split/Source independently, error boundaries,
  controller persistence.

### Acceptance gates

- Portable round trip loses no low/high or gap state.
- An older runtime cannot render a midpoint-only fallback.
- Data and CSV expose source values and label span as derived.
- Generated source compiles and reconstructs an equivalent chart.
- Every built-in preset has a clean Source surface.

### Local verification

- `ChartConfigBuilder` accepts typed `rangeArea` series with finite low/high
  intervals or explicit gaps and rejects generic `(x, y)`, half intervals,
  malformed gaps, inverted bounds, unordered X, and unknown explicit types.
- The tool schema advertises Range Area type, low, high, and gap input without
  weakening direct-model validation.
- Inline and columnar artifacts preserve low/high, canonical midpoint, gaps,
  styling, and motion. Malformed gap bounds or non-canonical gap Y values fail
  decode, and older runtimes reject midpoint-only fallback.
- Native Data/Split/Source surfaces expose low, high, midpoint, span, and gaps;
  representative generated Dart formats, analyzes, and compiles.
- The complete package suite passes 2,834 tests and the standalone showcase
  suite passes 336 tests. Package/showcase scoped analysis and the release web
  build are green.

## Slice 5 — First-class showcase and compositions

**Status:** Complete — expanded product/property review approved — 2026-07-21

### Scope

#### Presets

- Temperature envelope.
- Seasonal variation.
- Confidence interval.
- Nested forecast fan.
- Volatility band with price or Candlestick composition.
- Gaps and steps.

Each preset demonstrates a materially different part of the contract; avoid
duplicating the same chart with cosmetic-only changes.

#### Options and data variation

- Complete fill/gradient/opacity and upper/lower style controls.
- Border, marker, label, hit-test, tracking, summary, animation, and replay
  controls.
- Point count, density, interval breadth, categories/time, gaps, and overlays.
- Chart theme, grid, axes, legend, navigator/scrollbars, zoom, and pan.
- Useful reset semantics and URL-persisted preset selection.
- Performance measurements visible for stress presets.

#### Financial integration

After the Financial Technical Indicators lane lands:

- rebase this lane on current `origin/master`;
- use Range Area for a volatility band or cloud in the Financial section;
- keep indicator calculation in showcase/application preparation;
- synchronize the existing Cartesian panes and navigator normally;
- add global plot-bound alignment tests if the new band is used in a
  synchronized composition.

PR #78 landed on `origin/master` and this branch was fast-forwarded to that
baseline without a merge commit. The Technical Indicators price pane now uses
one native 20-session, 2σ `RangeAreaChartSeries` behind Candlestick and Line
series. It includes a focused Volatility band preset, show/hide control, fill
opacity control, warm-up gaps, typed tracking, and the existing synchronized
viewport/cursor/navigator behavior. Indicator calculation remains showcase
data preparation rather than renderer logic.

### Tests

- Compact/desktop layout and option scrolling.
- Every selector, toggle, slider, colour clear/reselect, reset, replay, and
  preset URL.
- Direct route, catalogue/navigation, Workbench modes, source registration.
- Light, dark, gradient, high contrast, reduced motion.
- Navigator and synchronization alignment where used.
- User-visible frame metrics update without contaminating hot-path geometry.

### Acceptance gates

- The page is useful as a test lab without becoming visually overwhelming.
- Samples prove range-only, range+Line, nested ranges, financial composition,
  gaps, and motion.
- Every public visual/style property is either wired to a control or exercised
  by a clearly labelled preset.
- No showcase-only API or renderer fork is introduced.

### Current local checkpoint

- The selector now exposes six materially different samples: Temperature,
  Seasonal, Confidence, Forecast fan, Volatility, and Gaps & steps.
- Samples prove range-only rendering, Range Area plus Line, nested Range Area
  bands plus a centre Line, a widening forecast horizon, and stepped explicit
  gaps without introducing a showcase-only renderer.
- Interval count and interval breadth controls vary real typed source data;
  existing fill, boundary, marker, label, tracking, summary, animation, colour,
  theme, axes, legend, zoom, and pan controls remain live across every preset.
- Preset selection is persisted in the direct-route query string. The release
  review route is available at `?page=range-area-charts&preset=forecastFan`.
- Focused wide/compact widget coverage, full package/showcase suites, scoped
  analysis, and the release web build pass at this checkpoint.

## Slice 6 — Performance, regression hardening, docs, and readiness

**Status:** Complete — final combined local E2E and clean-tree archive gates
passed — 2026-07-21

### Scope

#### Performance

- Add the complete benchmark matrix from the design document.
- Compare Range Area to native Area on the same data and machine.
- Profile uniform, gradient, dashed/glow, gaps, multiple bands, tracking, and
  motion.
- Confirm visible-window culling and cache invalidation behavior.
- Record build mode, device, source/visible points, style, and p50/p95.

#### Regression hardening

- Full package suite and scoped analysis.
- Full showcase suite and analysis.
- Existing Line/Area interpolation and motion.
- Candlestick compositions and value summaries.
- Synchronized plot alignment and navigator behavior.
- Workbench artifact/data/source contracts.
- Golden review in light/dark and compact/desktop.

#### Documentation and release

- Public API docs and code examples.
- Chart type guide, composition guide, performance note, and accessibility
  behavior.
- README feature matrix and changelog.
- `doc/chart_family_integration.md` completed-family evidence if appropriate.
- Release web build and direct-route browser smoke.
- Pub.dev dry run and package/example cleanliness.

### Acceptance gates

- Cached hover <1 ms p95.
- Warm full-frame paint <16.7 ms p95 on the reference harness.
- Uniform Range Area median <=1.8× corresponding Area median.
- No off-screen linear scan or per-point warm allocation regression.
- All required suites, release web, direct route, generated-source compile,
  and pub.dev dry run pass.
- Golden changes receive explicit visual review.

### Current local checkpoint

- Permanent benchmarks cover cold 5K and 50K indexing, 50K source / 1K
  visible geometry and paint, uniform and gradient fill, independent
  dashed/glowing boundaries, gap-heavy data, nested 2 x 5K bands, cached 50K
  tracking, 5K atomic update frames, and dense portable output.
- On the Windows Flutter test harness, all frame gates pass. Representative
  p95 values are 1.529 ms for dashed/glowing 5K paint, 6.071 ms for 5K atomic
  updates, and 0.010 ms for cached 50K tracking. Uniform warm Range Area paint
  remains below the 1.8x Area median ratio gate.
- Light nested-fan, dark stepped-gap, and compact high-contrast golden
  baselines were generated and explicitly inspected for boundary, gap, fill,
  and contrast behavior.
- The public Range Area guide, chart-type guide, API reference, feature matrix,
  chart-family integration evidence, package metadata, README, example README,
  and changelog now describe the shipped vertical contract.
- Package analysis is clean and all 2,845 package tests pass, including
  generated-source compilation, synchronized cursor, and navigator fanout
  regressions.
- Standalone showcase analysis is clean and all 345 tests pass, including the
  direct Range Area route, every Workbench mode, and the Financial volatility
  composition.
- `flutter build web --release --base-href /braven_charts/` passes, including
  its WebAssembly dry run; the live direct route returns HTTP 200.
- Global dartdoc 9.0.8 generates the public API with 0 warnings and 0 errors.
- `dart pub publish --dry-run` validates the complete clean-tree archive with
  0 warnings.
- User performs the final E2E/pixel review before merge.

### Post-Slice 6 Financial consumption checkpoint

- Fast-forwarded the Range Area branch to Financial PR #78 at `2a06a29e`.
- Preserved both direct routes and the Financial global plot-alignment tests.
- Added a real rolling volatility calculation with 19 explicit warm-up gaps
  followed by atomic low/high intervals; no financial statistic was moved into
  the chart renderer.
- The Full stack preset proves Range Area + Candlestick + two Line overlays;
  Volatility band isolates Range Area + Candlestick + one Line above the
  synchronized volume pane.
- Focused route, alignment, preset, toggle, Workbench, and Range Area tests pass
  (20 tests), and the Financial volatility composition received user
  pixel/product approval.
- The final combined gate is complete: package analysis is clean and all 2,845
  package tests pass; standalone showcase analysis is clean and all 345 tests
  pass; both root and `/braven_charts/` release web builds pass their WebAssembly
  dry runs; the Range Area and Financial direct routes return HTTP 200; and
  dartdoc reports 0 warnings and 0 errors.
- `dart pub publish --dry-run` validates the 11 MB clean-tree archive with
  0 warnings.
- The publication pass promotes Range Area across the shared ten-family Chart
  Types catalog, its native preview, the selection guide, nested navigation,
  and a dedicated three-card Gallery section for weather, forecast, and
  financial interval compositions. The rendered Gallery and Chart Types routes
  were inspected at 1600 x 1000 before promotion.

## Risk register

| Risk | Why it matters | Mitigation |
|---|---|---|
| Reversing curved lower geometry incorrectly | Fill can kink or diverge from tracking | Shared segment descriptors with exact reverse-control tests |
| Midpoint leaks into bounds/tooltips | Silently misrepresents the interval | Typed details and low/high-specific tests at every vertical seam |
| Gaps become zero/NaN artifacts | Corrupts bounds and portability | Explicit gap state plus codec and table tests |
| Cubic boundaries cross between ordered samples | Produces self-intersecting fills | Test and document Bezier overshoot; defer constrained curves deliberately |
| Generic path transition erases typed data | Broken update animation and identity | Typed Range Area transition or safe generalized adapter |
| Multiple overlays make tracking ambiguous | Duplicated cards/markers | One typed interval row and separate overlay identities |
| Showcase lands before portable family | Public surface cannot show real Data/Source | Explicit slice checkpoint and no release claim before Slice 4 |
| Financial branch drift | Conflicts with in-flight showcase work | Resolved by fast-forwarding to landed PR #78 before adding the volatility composition |
| Interpolation refactor regresses Line/Area | Core workhorse risk | Behavior-preserving descriptor extraction and complete regression suite |
| Dense bands exceed frame budget | Two paths plus fill cost more than Area | Visible culling, cached uniform paths, benchmark ratio gate |

## Decisions that do not need reopening during implementation

- Public name is Range Area.
- The interval is one typed point and one series.
- Canonical inherited Y is midpoint for valid points.
- Low/high drive bounds, tracking, rendering, tables, and semantics.
- Gaps are explicit and portable.
- Low must be less than or equal to high.
- Centre lines are independent Line series.
- Both boundaries share interpolation but may have independent styles.
- Default border mode excludes vertical sides.
- Stacking, crossing fills, horizontal range axes, and derived statistics are
  not v1 scope.

## User review checkpoints

1. **Now:** research/design/roadmap approval.
2. **After Slice 1:** API names, gap model, geometry lab, and interpolation
   parity.
3. **After Slice 2:** first pixel and control review on the live route.
4. **After Slice 3:** tracking, static summary, keyboard, and animation review.
5. **After Slice 4:** Chart/Data/Split/Source and generated-source review.
6. **After Slice 5:** sample breadth, financial composition, and stress controls.
7. **After Slice 6:** complete E2E/performance/release review, then commit/PR
   only when requested.

## Immediate next action after approval

Keep the approved Range Area and Financial review routes available, push the
approved commit, open the PR to `master`, and confirm the remote CI result.
