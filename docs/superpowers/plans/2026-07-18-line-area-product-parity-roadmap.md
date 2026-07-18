# Line and Area Product Parity — Sprint Roadmap

**Original branch:** `feature/line-area-product-parity`
**Original PR:** #35 (merged)
**Topology continuation:** `feature/line-area-topology-motion`
**Continuation PR:** #37 (merged)
**Next lane:** Per-series motion timing (Sprint 8; review needed)

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

**Status:** Review needed

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
