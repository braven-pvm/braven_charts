# Persistent Cartesian Selection Brush

**Status:** Implemented, product reviewed, and physical mobile interaction reviewed
**Lane:** `feature/persistent-selection-brush`
**Scope:** Cartesian X/Y interval and rectangle selection

## Product intent

Turn the existing transient X/Y interval and rectangle acquisition geometry into an
optional, durable selection control. When enabled, the brush remains visible
after pointer-up, can be moved or resized, and continues to drive the same
semantic selection state and public selection callbacks as a fresh interval
gesture.

This is selection state, not an annotation:

- its bounds define the active selected data interval;
- moving or resizing it replaces that interval selection;
- hiding it does not erase the underlying selection;
- clearing it erases both the brush and its selection;
- annotations remain independent and keep their existing interaction priority.

The feature is opt-in. Existing charts preserve the current transient behavior.

## Public contract

### Configuration

Add a nested `ChartSelectionBrushConfig` to `ChartSelectionConfig`.

The brush config owns:

- `enabled`: retain and activate an interval or box brush after selection;
- `keyboardEnabled`: opt in to brush focus, movement, and bound resizing;
- `initialVisible`: show the configured interval on first mounted render;
- `initialRange`: optional ordered data-domain bounds and Y-axis reference
  series for interval modes;
- `initialBox`: ordered X/Y bounds for rectangle mode;
- visual style through `ChartSelectionBrushStyle`.

Initial range and box models require finite, ordered bounds. If
`initialVisible` is true but the active acquisition mode has no corresponding
initial geometry, the brush remains hidden; this keeps one reusable
configuration safe while applications switch selection tools dynamically.

The active acquisition mode determines the dimension:

- `xInterval`: minimum/maximum are X-domain values;
- `yInterval`: minimum/maximum are values on `referenceSeriesId`, or the first
  visible Cartesian series when no reference is supplied.
- `rectangle`: `initialBox` supplies independent X and Y bounds; its optional
  reference series chooses the Y transform on multi-axis charts.

Point and lasso acquisition do not create or activate a persistent brush.

### Style

`ChartSelectionBrushStyle` exposes:

- fill colour and opacity;
- border colour, width, and radius;
- optional keyboard-focus border colour;
- handle fill, border colour, border width, size, and hit-target size;
- hover and active opacity/scale treatments.
- optional visual grid direction, row/column cell counts, colour, weight, and
  solid/dashed/dotted pattern.

Null colours inherit the chart interaction selection colour and chart
background. Visible handles remain compact while their pointer hit target is at
least 44 logical pixels. Default, hover, active, and keyboard-focus states must
remain distinguishable without relying on colour alone.

### Runtime state and controller

Expose an immutable `ChartSelectionBrushState` containing:

- acquisition mode (`xInterval`, `yInterval`, or `rectangle`);
- ordered data-domain minimum/maximum;
- reference series ID when applicable;
- visibility.

`BravenChartController` mirrors the current brush state and provides:

- `setSelectionBrush(...)` to set data bounds and visibility;
- `setSelectionBrushBox(...)` to set X/Y bounds and visibility;
- `showSelectionBrush()`;
- `hideSelectionBrush()` (selection remains);
- `clearSelectionBrush()` (brush and semantic selection clear together).

Detached, stale, unsupported-mode, invalid-bound, and ambiguous-axis commands
return structured `ChartArtifactResult` failures. Reapplying equivalent state
is a no-op.

## Interaction contract

### Creation

An ordinary X/Y interval drag behaves exactly as today while the pointer is
down. On pointer-up:

1. the interval selection commits;
2. the brush becomes persistent when enabled;
3. the controller publishes the brush state;
4. existing selection callbacks publish the selected data.

### Move

Pointer-down inside the brush claims the brush before chart pan or a new empty
range selection. Dragging moves the complete interval and clamps it to the plot
domain without changing its span.

### Resize

- X interval: left and right edge handles resize.
- Y interval: top and bottom edge handles resize.
- Rectangle: four edge and four corner handles resize either or both axes.

Crossing handles is not allowed. A minimum visual span keeps the handles
operable. Values remain continuous; they do not snap to source observations.

### Live updates

Move and resize update the overlay on every pointer move. Semantic selection
and the normal public selection callback are coalesced to at most once per
frame. Pointer-up performs a final commit.

Escape during an active manipulation restores the pointer-down bounds. Escape
while idle clears the brush and selection, matching the Selection Lab clear
action.

### Priority

Interaction priority is:

1. modal/editor interactions;
2. annotation resize/move and navigator/scrollbar ownership;
3. persistent brush handles and body;
4. new interval selection;
5. viewport pan/zoom;
6. passive hover/tracking.

This prevents the brush from stealing annotation, navigator, or scrollbar
gestures.

## Geometry and multi-axis rules

The durable source of truth is data-domain state. Plot geometry is derived each
frame from the current transform, so the brush stays aligned through resize,
zoom, pan, transpose, axis placement, and RTL layout.

For a Y brush on independent axes:

- `referenceSeriesId` maps the public data bounds to one visual band;
- that visual band is resolved through every participating series transform;
- the durable selection expression retains one targeted Y interval clause per
  series, preserving the existing multi-axis selection semantics.

If the reference series is removed or hidden, the brush becomes unavailable
without mutating the existing semantic selection. The controller reports the
state and the next valid programmatic update can restore it.

For a rectangle brush, resolved point identities remain the durable semantic
selection while the box is stationary. The current selection-expression model
combines clauses as a union and cannot faithfully encode the required
`X interval AND Y interval` conjunction; synthesizing two clauses would
reselect points outside the box. Moving or resizing the brush performs a fresh
two-axis hit test and atomically replaces those identities. A future native
two-axis expression clause can remove this representation boundary without
changing the public brush contract.

## Persistence

`ChartViewState` records brush mode, bounds, reference series, and visibility.
Artifact hydration restores the brush only when its chart selection
configuration enables persistent brushes. Older view-state documents remain
valid.

The configuration belongs to the chart document/source surface; current brush
position and visibility belong to view state.

## Performance budget

- pointer move: overlay-only repaint;
- no element regeneration or spatial-index rebuild;
- no series-cache invalidation;
- one range hit-resolution/callback publication per rendered frame at most;
- idle persistent brush adds a fill, stroke, optional clipped grid, and two or
  eight compact handles;
- target: under 1 ms median brush hit/paint work on the existing 5,000-point
  selection benchmark.

## Accessibility

- visual handles have at least 44x44 logical-pixel hit targets;
- keyboard focus is visible and not confused with the chart-wide focus border;
- arrow keys move the focused brush by a stable domain step;
- Shift+arrow resizes the focused edge;
- semantics announce dimension, bounds, and available move/resize actions;
- styling must meet the chart theme's contrast behavior in light, dark, and
  high-contrast modes.

Keyboard adjustment is a readiness requirement, but it follows pointer-complete
behavior so the first visual review checkpoint can validate the geometry and
API before semantics copy is frozen.

## Delivery slices

### Slice 1 — Contract and state

**Complete.**

- public config, style, and runtime state;
- controller read/command API;
- default-off and validation tests;
- plan and public API documentation.

### Slice 2 — Native persistence

**Complete.**

- retain X/Y interval geometry after commit;
- render configured fill, border, and handles;
- derive geometry from current transforms;
- initial visibility and programmatic bounds.

### Slice 3 — Move and resize

**Complete.**

- brush hit testing and interaction priority;
- live overlay movement/resizing;
- continuous bounds and plot clamping;
- replace-selection semantics and public callbacks;
- cancel/final-commit behavior.

### Slice 4 — State portability

**Complete.**

- controller mirroring;
- hide/show/clear lifecycle;
- `ChartViewState` JSON and generated Dart source;
- artifact extraction/hydration compatibility.

### Slice 5 — Selection Lab

**Complete.**

- persistent-brush toggle;
- show/hide/reset actions;
- initial/current bound controls;
- shared palette-based appearance controls;
- X and Y range review presets, including multi-axis Y.

### Slice 6 — Hardening

**Complete.**

- keyboard move, Shift-resize, focus-target cycling, and semantic actions;
- transpose, RTL, zoom, hidden reference series, and resize coverage;
- 5,000-point brush hit-resolution plus overlay-paint benchmark;
- full package, showcase, analyzer, and release-web gates.

### Slice 7 — Mobile-touch coexistence

**Complete.**

- replay the completed brush implementation onto the v0.13.3 interaction
  stack without dropping viewport zoom/pan, long-press tracking, or touch tap
  behavior;
- keep one-finger touch ownership on a visible brush body or handle so the
  brush remains movable and resizable on tablets;
- let an explicit two-finger viewport gesture take over cleanly, including
  when its first pointer landed inside the brush, without committing a partial
  brush move;
- preserve brush data-domain bounds while touch zoom/pan reprojects its
  geometry;
- cover touch ownership, cancellation, callback publication, and the existing
  mobile release-hardening suite before refreshing the review build.

### Slice 8 — Public adoption and release readiness

**Complete.**

- document the opt-in configuration, initial state, styling, runtime state,
  and controller lifecycle in the public API guide;
- add a compile-checked public example that mounts an initially visible brush
  and exercises programmatic move, hide, show, and clear commands;
- make the Selection Lab's persistent-brush coverage discoverable from the
  package and showcase documentation;
- validate the public documentation catalog, generated API reference, and
  publish archive;
- retain physical phone/tablet interaction review as an explicit release
  checkpoint rather than treating browser pointer emulation as equivalent;
- physical mobile pointer interaction was subsequently reviewed and accepted
  after direct-route access and touch ownership fixes.

### Slice 9 — Rectangle persistence and visual subdivisions

**Complete and product reviewed.**

- persist completed rectangle acquisition as two-axis data-domain state;
- expose programmatic initial bounds and `setSelectionBrushBox(...)`;
- move the complete box and resize it from four edges or four corners;
- continue publishing the ordinary selection callbacks during live changes;
- add optional horizontal, vertical, or combined visual grid subdivisions;
- configure grid cell counts, colour, weight, and solid/dashed/dotted pattern;
- preserve grid and box state through artifacts, hydration, generated Dart
  source, fluent surfaces, and AI schema;
- expose all controls in the Selection Lab without changing default visuals.
- keep box selections exact after move and resize by retaining the resolved
  point identities rather than approximating an X/Y conjunction as additive
  expression clauses;
- keep Workbench data-table geometry stable during selection-driven refresh by
  using a fixed toolbar spinner slot instead of inserting a progress row.

## Physical mobile review checkpoint

Run this checkpoint on a real phone or tablet before delivery:

1. open Selection Lab and choose Line plus X range;
2. enable Persistent brush and confirm the configured initial bounds render;
3. drag the body with one finger and resize both handles independently;
4. begin a one-finger brush move, add a second finger, and confirm viewport
   pinch/pan takes ownership without committing the partial brush move;
5. lift both fingers and confirm the brush remains aligned to its data-domain
   bounds with no crosshair flash or stale tooltip;
6. repeat with Y range and the multi-axis preset;
7. verify Hide preserves selection, Show restores the same bounds, and Clear
   removes both brush and selection;
8. repeat once with 200% text scaling and a screen reader enabled.

## Verification

Completed on 2026-07-23:

- `flutter analyze --no-pub lib`: no issues;
- root `flutter test --no-pub`: 3,582 tests passed, 6 skipped;
- showcase `flutter test --no-pub`: 408 tests passed;
- showcase `flutter build web --release --no-pub`: passed, including Wasm dry
  run;
- 5,000-point brush benchmark: 0.407 ms median and 0.647 ms p95 in the
  v0.13.3 full-suite run (1 ms median budget);
- one-finger touch move/resize and two-finger viewport takeover both pass
  alongside the complete mobile-touch release-hardening suites.

Slice 8 verification on 2026-07-23:

- public snippet analysis: no issues;
- public snippet widget suite: 3 tests passed, including initial render and
  controller move/hide/show/clear commands;
- `dart run tool/public_docs.dart --check`: catalog and generated outputs
  current;
- `dartdoc --validate-links`: 2 public libraries documented with 0 warnings
  and 0 errors;
- public catalog API-symbol validation against generated dartdoc: current;
- `dart pub publish --dry-run --ignore-warnings`: archive validation passed at
  14 MB; the ordinary dry run reports only the expected dirty-worktree warning
  while this uncommitted review lane remains open;
- physical phone/tablet validation was completed in the subsequent product
  review; direct mobile routing, brush manipulation, and touch ownership were
  accepted.

Post-review hardening on 2026-07-24:

- `flutter analyze lib`: no issues;
- root `flutter test`: 3,664 tests passed, 6 generated-smoke
  construction skips;
- showcase `flutter analyze`: no issues;
- showcase `flutter test`: 414 tests passed;
- showcase release web build passed, including the Wasm dry run;
- 5,000-point brush benchmark: 0.373 ms median and 0.525 ms p95;
- rectangle move and corner resize keep controller selection and exported
  selection snapshots equal to the final two-axis hit test;
- box persistence survives unrelated style/grid changes and Workbench
  selection tables rebase automatically to the current chart revision;
- background table refresh keeps first-row geometry fixed while a reserved
  toolbar spinner appears and disappears;
- initial interval and rectangle geometry now share an independent visibility
  flag in generated schema/fluent surfaces while preserving the existing
  `withInitialState(range, visible)` convenience API;
- public documentation generation/check and the pub.dev dry run passed;
- `dart doc --validate-links` remains blocked before package diagnostics by
  the Flutter-bundled dartdoc 9.0.4
  `DocumentationComment._stripDocImports` `RangeError`.

## Review checkpoint

Pause for product review after Slices 1–3 when the Selection Lab demonstrates:

- default transient behavior unchanged;
- opt-in X and Y brushes remain visible;
- handles are persistent and clearly interactive;
- moving and resizing update the chart and selection callbacks live;
- programmatic initial bounds render in the requested location;
- style overrides are visibly applied;
- no selection, axis, annotation, navigator, or pan regression is present.
