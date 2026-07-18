# Line and Area Product Parity — Sprint Roadmap

**Original branch:** `feature/line-area-product-parity`
**Original PR:** #35 (merged)
**Topology continuation:** `feature/line-area-topology-motion`
**Continuation PR:** #37 (merged)
**Sprint 8 promotion:** PR #38 (merged)
**Sprint 9 lane:** Stable-identity interior topology motion (review approved)
**Next lane:** Path stroke patterns and Forecast (Sprint 11; in progress)

## Sprint 1 — Motion and workbench foundation

**Status:** Complete

- Public opt-in entrance and compatible data-update motion for Line and Area.
- Canonical artifact persistence and controller replay.
- Shared Chart/Data/Split workbench on both chart-family pages.
- Motion presets, responsive layouts, and controller lifecycle regression.
- Local pixel review, package/showcase verification, release build, and green
  PR CI.

## Sprint 2 — Flagship runtime hardening

**Status:** Complete

- Prove reveal behavior across linear, bezier, monotone, and stepped paths.
- Prove multi-axis transforms use stable target bounds throughout motion.
- Prove zero-duration themes render the final state synchronously.
- Prove controller-fed streaming tails retain their dedicated animation and do
  not also trigger path interpolation or reveal.
- Retain the radial data-transition runtime introduced on `master` while path
  transitions are active in the same package build.

## Sprint 3 — Public package and media parity

**Status:** Complete

- Add packaged Line/Area motion and workbench guidance under `doc/`.
- Update the API reference, feature matrix, root README, and example README.
- Refresh release screenshots and direct links so public claims show the new
  workbench and Motion compositions rather than legacy surfaces.
- Verify every public route and publication asset against a release build.

## Sprint 4 — Consolidated E2E and merge readiness

**Status:** Complete

- Run full package and showcase tests and analyzers from a clean tree.
- Build the release web app and validate the pub.dev archive.
- Exercise Line and Area Chart/Data/Split, resizing, preset switching,
  annotations, multi-axis normalization, entrance replay, data updates,
  reduced motion, compact fallback, and direct routes in the browser.
- Check browser console output, PR scope, generated docs, screenshots, and CI.
- Record residual risks and request final merge approval. Do not merge as part
  of the E2E run without that approval.

### E2E record

- `flutter analyze lib`: clean.
- Full package suite: 1,779 tests passed.
- Showcase analyzer: clean; full showcase suite: 133 tests passed.
- Browser release run: 21 checkpoints passed across Line and Area direct
  routes, Chart/Data/Split transitions, pointer resizing, preset switching,
  entrance replay, compatible updates, reduced motion, compact fallback, and
  severe-console/controller-error checks.
- `flutter build web --release --base-href /braven_charts/`: passed with the
  deployment base verified; the root-path release build was then restored for
  local review on port 8097.
- Dartdoc: 0 warnings and 0 errors. Pub.dev dry run: 0 warnings.
- The repository-wide formatter audit reports 132 pre-existing files that do
  not match the current Dart formatter. This PR does not mass-format unrelated
  code; every Dart file changed by this lane passes the formatter check.

PR #35 was approved and merged after its green E2E and CI gates.

## Sprint 5 — Path Motion 1.1 topology updates

**Status:** Complete

- Animate stable-identity append, boundary removal, and rolling-window
  snapshots for Line and Area.
- Collapse entering and exiting points at the nearest retained boundary while
  keeping all visual and interaction layers on the canonical animated series.
- Preserve target bounds, reduced-motion behavior, multi-axis correctness, and
  the dedicated controller streaming-tail path.
- Add focused Motion-preset actions and complete package, showcase, release,
  direct-route, and artifact verification before PR promotion.

The locked behavior and exclusions are recorded in
`../specs/2026-07-18-line-area-topology-motion-design.md`.

### Sprint 5 verification record

- Pure and real render-path coverage passes for append, removal, forward and
  reverse rolling windows, reduced motion, target-bound multi-axis updates,
  canonical artifact extraction, and the streaming-tail exclusion.
- Full package and showcase suites pass; the showcase suite contains 134 tests.
- `flutter analyze lib`, the full showcase analyzer, and every touched-file
  analysis pass with zero issues.
- Deployment-base and root-path release web builds pass; Line and Area direct
  routes were inspected at 1600 x 1000 and accepted in local review.
- Dartdoc 9.0.8 reports zero warnings and zero errors. The package dry run
  reaches validation with only the expected dirty-worktree warning before the
  approved local slice is committed.

## Sprint 6 — Path identity continuity

**Status:** Complete

- Keep temporary exiting geometry visual-only while all interaction surfaces
  expose canonical target point indices.
- Remap retained Line/Area focus and selection by stable point identity when a
  topology snapshot changes; remove state whose identity exits.
- Preserve canonical hit, hover, tooltip, linked-marker, workbench, callback,
  and artifact behavior throughout append, removal, and rolling transitions.
- Prove rapid snapshot interruption starts from current geometry without
  leaking temporary render indices or migrating durable point state.

The locked interaction contract and exclusions are recorded in
`../specs/2026-07-18-line-area-motion-identity-continuity-design.md`.

### Sprint 6 verification record

- Pure transition and real render-path tests prove canonical mapping for
  forward/reverse rolling and removal, non-interactive exits, retained and
  removed point state, workbench-linked selection, and rapid interruption.
- Full package suite: 1,790 tests passed. Full showcase suite: 134 tests
  passed. Package and showcase analyzers report zero issues.
- The timing-sensitive workbench benchmark was isolated after a deliberately
  concurrent first run and passed; the complete package suite then passed
  serially.
- The root-path release web build passes, and the refreshed Line Motion direct
  route plus compiled application script respond successfully on port 8098.

## Sprint 7 — Continuation E2E and promotion readiness

**Status:** Complete

- Re-run every package, showcase, documentation, archive, and release-build
  gate after rebasing the topology and identity commits onto current master.
- Exercise Line and Area direct routes, Chart/Data/Split, resizing, linked
  selection, append/remove/rolling motion, rapid interruption, reduced motion,
  annotations, and multi-axis behavior against the final release bundle.
- Review the complete three-commit continuation diff for cross-family regression
  risk after the radial-family foundation merge.
- Record residual risks and leave a refreshed local review route available.
  Do not push, open a PR, or merge without explicit user approval.

### Sprint 7 E2E record

- Rebased the topology and identity work onto the radial-family foundation.
  The rebase exposed the foundation's `radial` to `partitionRadial` layout-kind
  rename in generic entrance replay; the dispatch was corrected and covered by
  the existing Donut controller test through the generic replay API.
- `flutter analyze lib` and the full showcase analyzer pass with zero issues.
  The full package suite passes with 1,796 tests; the full showcase suite passes
  with 134 tests.
- Dartdoc reports zero warnings and zero errors. The pub.dev dry run reports
  zero warnings; constrained dependency update notices remain informational.
- Deployment-base and root-path release web builds pass. The deployment build's
  `/braven_charts/` base href was verified before restoring the root build for
  local review.
- Chrome release-browser checks pass for refreshed Line and Area Motion direct
  routes, Chart/Data/Split composition, divider resizing, linked table
  selection, value updates, rapid rolling-window interruption, reduced motion,
  compact layouts, Line multi-axis and workhorse presets, and the Area baseline
  preset. Every checked route rendered nonblank with no severe console output,
  controller error, or visible overflow.
- Residual promotion gates are intentionally external to the local E2E slice:
  cross-browser coverage and hosted CI run during PR promotion. No push, PR,
  or merge had been performed when the E2E record was captured.
- Final local review was approved on 2026-07-18. PR #37 then passed hosted
  package-quality CI, received final approval, and merged into `master`.

## Sprint 8 — Per-series motion timing

**Status:** Complete

### Product outcome

Multi-series Line and Area charts can sequence entrance and compatible data
updates deliberately. Each series may inherit the chart theme's duration or
declare an explicit delay and duration for entrance and update motion. Existing
charts retain their current simultaneous, theme-timed behavior by default.

The detailed proposal is recorded in
`../specs/2026-07-18-line-area-per-series-motion-timing-design.md`.

### Scope

- Add immutable, non-negative entrance and data-update timing values to
  `PathAnimationStyle` through a reusable `PathAnimationTiming` value object.
- Resolve every participating series onto one elapsed-time orchestration
  timeline per phase; do not add one controller or timer per series.
- Apply the existing theme curve to each series' local progress window while
  preserving theme timing as the default and theme zero-duration as a global
  synchronous-motion override.
- Preserve canonical target bounds, identity mapping, interaction state,
  annotations, artifacts, rapid interruption, and the streaming-tail
  exclusion throughout delayed and active windows.
- Persist non-default timing configuration additively in chart documents while
  keeping animation progress itself transient.
- Upgrade the Line and Area Motion examples with restrained, explicit timing
  sequences and controls that remain usable in wide and compact workbenches.

### Explicit exclusions

- Automatic staggering derived from list position or paint order.
- Per-series easing curves, spring physics, or path-shape morphing.
- Axis-domain interpolation or animated normalization bounds.
- Interior insertion/removal, arbitrary reordering, or interpolation-mode
  morphing.
- Scatter, Bar, Pie, Donut, or polar-family timing changes.
- Persistence or restoration of in-flight animation progress.

### Acceptance gates

- Defaults remain bit-for-bit simultaneous and theme-timed; motion stays
  opt-in and backwards compatible.
- Delayed series remain on their valid phase-start geometry and canonical
  target identity until their local window begins; completed series resolve to
  the exact target while later series continue.
- Reduced motion, a zero-duration theme, and a zero-duration series override
  render the final state immediately without honoring delay.
- A rapid compatible snapshot restarts from each series' currently rendered
  geometry and uses the newest target timing configuration.
- Pure timing-window tests and real Line/Area render-path tests cover before,
  during, between, and after per-series windows, including replay, updates,
  topology changes, multi-axis bounds, interaction mapping, and artifacts.
- Artifact round trips preserve timing; documents without timing decode to the
  current inherited defaults; a dedicated timing capability marks documents
  that require the new semantics.
- Wide and compact showcase tests, package/showcase analyzers and suites,
  Dartdoc, pub.dev dry run, deployment-base and root release builds, direct
  browser routes, console checks, and local product review pass before PR
  promotion.

### Sprint 8 local verification record

- Added immutable per-series entrance and update timing, one shared elapsed-time
  timeline per phase, artifact persistence, and the dedicated
  `series.path-motion-timing.v1` capability without changing default motion.
- Real Line and Area render-path coverage passes for staggered entrance,
  independent compatible updates, topology changes, interruption, replay,
  canonical bounds and identity, reduced motion, zero theme/series durations,
  and controller-fed streaming exclusion.
- The Line Motion preset now uses explicit `0/80/160 ms` timing across three
  stable series. Area uses two translucent layers at `0/120 ms`. Their compact
  control changes explicit sample timing without implying automatic ordering.
- `flutter analyze lib`, the full showcase analyzer, the complete package test
  suite, and the complete showcase test suite pass. Dartdoc reports zero
  warnings and zero errors; the committed pub.dev dry run reports zero
  warnings.
- Deployment-base and root-path release web builds pass. Chrome release
  captures for both direct Motion Split routes are nonblank; filtered console
  checks and the local asset log show no severe output, controller error, or
  404 response. Compact widget coverage asserts the header actions and
  workbench remain inside a 390 px viewport.
- The root release build is available for joint review on port 8097. No push,
  PR, or merge had been performed when the local record was captured.
- Local review was approved on 2026-07-18. PR #38 was opened against `master`
  with the hosted package-quality gate in progress.

## Sprint 9 — Stable-identity interior topology motion

**Status:** Local review approved

### Product outcome

Line and Area snapshot updates can animate ordered points inserted into or
removed from the interior of a path. This covers late-arriving and corrected
samples without replaying the whole series, while retaining the existing
canonical target-data and interaction contracts.

The detailed contract is recorded in
`../specs/2026-07-18-line-area-interior-topology-motion-design.md`.

### Scope

- Extend the private `PathSeriesTransition` plan; add no new public model or
  animation controller.
- Support insertion-only or removal-only interior edits with at least two
  ordered retained stable identities bracketing every interior edit.
- Start inserted points on the phase-start path at their target X and collapse
  removed points onto the target path at their source X, using the configured
  interpolation geometry.
- Preserve render-to-target point maps, target bounds, focus and selection,
  linked workbench identity, artifacts, interruption continuity, reduced
  motion, streaming exclusion, and Sprint 8 per-series timing windows.
- Add one compact backfill action to the existing Line and Area Motion presets
  while retaining 48 px targets, 8 px action spacing, and chart-first layout.

### Explicit exclusions

- A single snapshot that both inserts and removes interior identities.
- Arbitrary retained-identity reordering or duplicate/ambiguous identities.
- Interpolation-mode morphing, axis-domain animation, or path-shape tween APIs.
- Scatter, Bar, Pie, Donut, polar families, or controller-fed streaming tails.
- New artifact schema: artifacts continue to persist canonical target data.

### Acceptance gates

- Pure frames prove exact start anchors, intermediate geometry, exact targets,
  canonical maps, and fallback for mixed/reordered edits across Line and Area.
- Real render-path tests prove interpolation-aware interior insertion/removal,
  delayed series timing, interruption continuity, non-interactive exits,
  retained focus/selection, target bounds, reduced motion, and artifacts.
- Motion showcase actions exercise actual backfill insertion and removal in
  wide and compact Chart/Data/Split compositions.
- Package/showcase analyzers and complete suites, Dartdoc, pub.dev dry run,
  deployment-base and root release builds, and direct browser review pass
  before promotion.

### Sprint 9 verification record

- Pure transition coverage passes for linear, stepped, Bezier, and monotone
  insertion sampling, multiple interior entries, removal collapse, canonical
  maps, exact targets, and explicit mixed/reordered/invalid fallbacks.
- Real Line and Area render-path coverage passes for independent timing,
  visual-only exits, canonical artifacts, cleared exiting state, and in-flight
  interruption from the exact rendered geometry.
- Package analyzer: clean; complete package suite: 1,813 tests passed.
  Showcase analyzer: clean; complete showcase suite: 135 tests passed.
- Dartdoc 9.0.8 generated the public library with zero warnings and errors.
  The Flutter-bundled Dartdoc 9.0.4 has a reproducible internal `RangeError`
  on the unchanged Sprint 8 branch, so the newer installed patch was used.
- The pub.dev dry run reports zero warnings. Deployment-base and root release
  builds pass with `/braven_charts/` and `/` verified respectively.
- Wide release captures render both direct Motion/Split routes nonblank. Widget
  coverage runs the backfill action for Line and Area in both wide and 390 px
  compact option surfaces, with 48 px actions kept inside the viewport.
- The root release build is available on port 8097 for joint review. This lane
  remains local and stacked on Sprint 8 / PR #38; it has not been pushed or
  opened as a PR.

## Sprint 10 — Showcase polish and Area gradients

**Status:** Local review ready

### Product outcome

The Line and Area family pages expose a broader set of immediately useful
compositions, while Area charts gain a first-class portable linear fill
gradient. The page remains a chart-first guide rather than a configuration
catalogue.

### Scope

- Add two concise Line presets and two concise Area presets, including mixed
  Line/Area compositions that reuse the existing Workbench and controller.
- Keep seven choices per family in the existing segmented selector. Wide layouts
  fit the choices in one group; compact layouts retain horizontal scrolling.
- Add a serializable `AreaGradient` model with colors, optional stops, and
  begin/end alignment, applied across the stable plot bounds.
- Preserve the solid-fill default and baseline-fill precedence. Gradient
  opacity composes with the existing `fillOpacity`.
- Round-trip non-default gradients through chart artifacts and advertise a
  dedicated capability.

### Explicit exclusions

- Radial gradients, per-point gradients, animated gradient stops, or a general
  cross-family gradient abstraction.
- Gradient baseline-above/below pairs or gradient interpolation during motion.
- A new options panel, preset editor, gallery page, or chart family.

### Acceptance gates

- Pixel-backed render tests prove vertical and directional gradient fills,
  opacity composition, solid fallback, and unchanged baseline behavior.
- Artifact tests prove exact gradient round-trip and capability hydration.
- Showcase tests prove all new presets, mixed family compositions, interactive
  gradient toggling, and bounded wide/390 px selectors and option surfaces.
- Complete analyzers/suites, Dartdoc, pub.dev dry run, deployment/root release
  builds, and direct Line/Area route review pass before promotion.

### Delivered local slice

- Added `Comparison` and mixed `Envelope` Line presets plus `Gradient` and
  mixed `Composition` Area presets. The existing segmented selector remains a
  single group on wide layouts and horizontally scrollable at 390 px.
- Added public `AreaGradient` colors, stops, and begin/end alignment with a
  stable plot-bound shader, `fillOpacity` composition, solid fallback, and
  baseline-fill precedence.
- Added `series.area.gradient.v1` artifact encoding, decoding, capability
  advertisement, and built-in hydration support.
- Pixel-backed renderer tests cover solid fallback, vertical/directional
  blends, alpha composition, and baseline precedence. Artifact, hydration,
  wide, compact, mixed-series, controller, and toggle coverage is green.
- `flutter analyze lib` and the showcase analyzer are clean. Complete package
  and 137-test showcase suites pass, as does the release web build. Direct
  Envelope, Gradient, and Composition routes return HTTP 200 and were reviewed
  at 1600 px and 390 px.
- The clean-tree pub.dev dry run passes with zero warnings. Dartdoc 9.0.4
  currently crashes inside
  `DocumentationComment._stripDocImports` with an internal range error before
  emitting diagnostics; this publication gate remains recorded for the final
  promotion pass.
- The current release build is served on port 8097 from the dedicated Sprint
  10 worktree. This slice remains local and has no PR.

### Review amendment

- Add exactly one restrained hero preset per family: a dark Line spotlight
  combining a luminous focus line, gradient context area, inline identity, and
  one threshold; and an Area pulse combining a gradient magnitude, target
  window, reference line, inline identity, and highlighted peak.
- Reuse existing public series, annotation, theme, Workbench, and artifact
  surfaces. Do not add another option panel, new chart API, or dense multi-axis
  composition.
- Delivered `Spotlight` for Line with a fixed dark chart surface, luminous focus
  line, soft gradient context, inline identity, and one styled threshold.
- Delivered `Pulse` for Area with a gradient magnitude, stepped target, target
  window, inline identities, and one peak marker. Its legend is intentionally
  suppressed to keep the peak and right-edge labels clear.
- The focused 13-test page suite and complete 139-test showcase suite pass;
  the showcase analyzer is clean and the root-path release web build succeeds.
  Both direct routes were inspected at 1600 x 1000 and 430 x 900 from the
  release bundle served on port 8097.

### Promotion verification

- Rebased the six approved Sprint 9 and Sprint 10 commits onto the current
  `origin/master` 0.7.0 release tip. The generated-source showcase coverage and
  expanded Bar API documentation added on `master` are both retained.
- `flutter analyze lib` and the showcase analyzer pass. The complete package
  suite passes with 1,932 tests and the complete showcase suite passes with 159
  tests. The root-path release web build succeeds.
- The clean-tree pub.dev dry run reports zero warnings. Dartdoc 9.0.4 still
  reproduces its previously recorded internal
  `DocumentationComment._stripDocImports` range error before diagnostics.
- The refreshed Line Spotlight and Area Pulse routes and compiled application
  script return HTTP 200 from the release bundle on port 8097.

## Sprint 11 — Path stroke patterns and Forecast

**Status:** Ready for local review

### Product outcome

Ordinary Line and Area series support portable dotted, dashed, and dash-dot
outlines. A new Line Forecast preset demonstrates a solid observed path,
dotted forecast path, hollow forecast markers, and a vertical current-time
threshold without introducing a forecast engine or new options panel.

### Scope

- Add an empty-by-default `dashPattern` to Line and Area series.
- Pattern the interpolated rendered path while preserving fill, hit testing,
  tracking, markers, labels, glow, and path motion.
- Round-trip patterns through artifacts, hydration, capabilities, and readable
  Dart source, and represent them in the package legend.
- Add the Forecast composition to the existing Line Workbench page with wide
  and compact coverage.

### Acceptance gates

- Pure and pixel-backed pattern coverage across every interpolation and Area
  fill mode.
- Model, artifact, hydration, capability, source, legend, animation, and
  interaction regression coverage.
- Forecast wide/compact and Workbench coverage.
- Complete analyzers/suites, release builds, publication checks, direct-route
  browser review, and local pixel approval before PR promotion.

The locked contract and executable work slices are recorded in
`../specs/2026-07-18-path-strokes-and-synchronized-charts-design.md` and
`2026-07-18-line-stroke-forecast.md`.

### Delivered local slice

- Line and Area now accept portable path-space dash patterns; solid rendering
  remains the empty default and Area fill geometry stays continuous.
- Renderer coverage proves all interpolation modes, segment styling, glow,
  ordinary and baseline Area fill, plus animated geometry style retention.
- Artifacts, built-in hydration, capabilities, generated source, legends, and
  malformed-document handling preserve the new series identity.
- The new Line Forecast composition uses one canonical series with a native
  outgoing-segment pattern transition. This replaces the reviewed two-series
  draft whose independent monotone endpoint tangents produced a visible
  handoff break.
- Full package (1,972) and showcase (160) suites are green; package and
  showcase analysis is clean, both production base-href builds pass, and the
  refreshed root build is served locally on port 8099. Promotion remains
  gated on pixel approval.
- A follow-up performance audit restores the baseline Area single-path fast
  path when no segment override exists and locks 5,000-point solid Line, Area,
  baseline Area, and continuous-Forecast frame-budget benchmarks into the
  package suite. Legacy Area medians match `origin/master` within noise.

## Sprint 12 — Synchronized Cartesian charts

**Status:** Planned after Sprint 11 promotion

### Product outcome

Independent Cartesian charts can share a data-X cursor, aligned crosshairs,
nearest-point focus, and X-only viewport changes while retaining their own
units, Y domains, titles, and artifacts.

### Scope

- Add a caller-owned `ChartInteractionGroupController`; do not extend the
  presentation-only `ChartWorkbenchGroupController`.
- Coordinate data-space X, local nearest points, pointer/touch cleanup, and
  loop-safe X viewport changes.
- Add a stacked Speed, Elevation, and Heart rate showcase at wide and compact
  sizes.
- Keep Y interaction, annotations, tooltips, durable selection, and artifacts
  local to each chart.

### Acceptance gates

- Controller lifecycle, data-X mapping, nearest-point, viewport, opt-out, and
  loop-prevention unit coverage.
- Real render-path crosshair coverage across different sizes, sample counts,
  interpolation modes, and Y domains.
- Pointer, touch, keyboard, compact, release, publication, and pixel-review
  gates before promotion.
