# Persistent Cartesian Selection Brush

**Status:** Implemented and automated/release verified — physical mobile review pending
**Lane:** `feature/persistent-selection-brush`
**Scope:** Cartesian X/Y interval selection only

## Product intent

Turn the existing transient X/Y interval acquisition rectangle into an
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

- `enabled`: retain and activate an interval brush after selection;
- `initialVisible`: show the configured interval on first mounted render;
- `initialMinimum` / `initialMaximum`: initial data-domain bounds;
- `referenceSeriesId`: optional Y-axis reference series for multi-axis charts;
- visual style through `ChartSelectionBrushStyle`.

The initial bounds are valid only as a pair. They must be finite and ordered by
the implementation. `initialVisible` without a complete valid range is a
configuration error in debug builds and remains hidden in release builds.

The active acquisition mode determines the dimension:

- `xInterval`: minimum/maximum are X-domain values;
- `yInterval`: minimum/maximum are values on `referenceSeriesId`, or the first
  visible Cartesian series when no reference is supplied.

Other acquisition modes do not create or activate a persistent brush.

### Style

`ChartSelectionBrushStyle` exposes:

- fill colour and opacity;
- border colour, width, and radius;
- handle fill, border colour, border width, size, and hit-target size;
- hover and active opacity/scale treatments.

Null colours inherit the chart interaction selection colour and chart
background. Visible handles remain compact while their pointer hit target is at
least 44 logical pixels. Default, hover, active, and keyboard-focus states must
remain distinguishable without relying on colour alone.

### Runtime state and controller

Expose an immutable `ChartSelectionBrushState` containing:

- acquisition mode (`xInterval` or `yInterval`);
- ordered data-domain minimum/maximum;
- reference series ID when applicable;
- visibility.

`BravenChartController` mirrors the current brush state and provides:

- `setSelectionBrush(...)` to set data bounds and visibility;
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
- idle persistent brush adds only simple fill, stroke, and two handles;
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

**Complete, with the physical-device review checkpoint intentionally pending.**

- document the opt-in configuration, initial state, styling, runtime state,
  and controller lifecycle in the public API guide;
- add a compile-checked public example that mounts an initially visible brush
  and exercises programmatic move, hide, show, and clear commands;
- make the Selection Lab's persistent-brush coverage discoverable from the
  package and showcase documentation;
- validate the public documentation catalog, generated API reference, and
  publish archive;
- retain physical phone/tablet interaction review as an explicit release
  checkpoint rather than treating browser pointer emulation as equivalent.

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
- physical phone/tablet validation remains pending by product direction and is
  not represented as complete by the automated touch suites.

## Review checkpoint

Pause for product review after Slices 1–3 when the Selection Lab demonstrates:

- default transient behavior unchanged;
- opt-in X and Y brushes remain visible;
- handles are persistent and clearly interactive;
- moving and resizing update the chart and selection callbacks live;
- programmatic initial bounds render in the requested location;
- style overrides are visibly applied;
- no selection, axis, annotation, navigator, or pan regression is present.
