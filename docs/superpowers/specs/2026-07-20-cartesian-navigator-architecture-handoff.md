# Native Cartesian Navigator — Architecture, Feature, and Lane Handoff

**Date:** 2026-07-20
**Status:** Architecture ready; showcase composition proven locally; native package implementation not started
**Recommended lane:** `feature/cartesian-navigator`
**Dependency:** Branch from `master` only after the active Candlestick lane has landed
**Prototype:** `example/lib/showcase/pages/candlestick_charts_page.dart`
**Owning surface:** Shared Cartesian infrastructure, not the Candlestick family

## Executive decision

Promote the proven stock-composition navigator into a reusable native
`CartesianNavigator` widget.

The navigator is not a new chart family, a special series renderer, or an
enhanced scrollbar. It is a compact Cartesian overview and viewport-control
surface composed from existing Braven Charts primitives:

- an ordinary Line or Area series rendered across the full X domain;
- one selected X-only range window representing the shared visible viewport;
- `ChartInteractionGroupController` as the sole viewport authority; and
- the existing annotation drag pipeline for live pan and resize previews.

The native implementation must preserve the successful prototype's defining
property: the overview stays on the full domain while its window controls the
viewport of one or more independent Cartesian charts in real time.

This document is the authoritative handoff for that work. The Candlestick
showcase remains the behavioral and visual reference until the reusable widget
replaces its local composition without regression.

## Product outcome

An application developer can add a first-class overview navigator beneath any
compatible Cartesian composition and receive:

- a persistent visible-range window;
- drag-the-window panning;
- drag-either-edge zooming;
- live viewport updates during the pointer gesture, not only on release;
- external viewport reflection when a main chart pans, zooms, or changes range;
- themeable window, handles, overview series, and interaction states;
- mouse, touch, keyboard, and assistive-technology operation;
- cursor isolation from chart tracking; and
- bounded, measurable fanout across synchronized charts.

The first native release should support Line, Area, Bar, Scatter, and
Candlestick consumers through the common Cartesian viewport contract. The
navigator's own overview visual is intentionally limited to one Line or Area
series in v1.

## Why the prototype succeeded

Earlier navigator exploration was framed as a more elaborate scrollbar. The
archived scrollbar specification consequently deferred the essential pieces:
mini-chart rendering, dual handles, and custom handle presentation. That
boundary was reasonable for shipping the scrollbar, but it made a true
navigator awkward because a scrollbar owns normalized track geometry rather
than a chart's data-space overview.

The Candlestick composition solved the problem by changing the abstraction:

1. Render the overview with a normal `BravenChartPlus` Cartesian chart.
2. Keep that chart on the complete X domain.
3. Draw the visible viewport as an X-only `RangeAnnotation`.
4. Send transient annotation movement to the existing shared X viewport.
5. Keep the navigator out of shared cursor and viewport participation.

That separation avoids a second coordinate system, reuses the normal renderer,
and gives every controlled chart the same data-space viewport command.

## Scope boundaries

### In scope for native v1

- Reusable `CartesianNavigator` widget in the package.
- Caller-owned `ChartInteractionGroupController` integration.
- One Line or Area overview series with a matching X domain.
- Explicit full-domain and initial-viewport contracts.
- Persistent left and right handles for X-only range control.
- Window panning and edge resizing with live preview and committed callbacks.
- Clamp, snap, and minimum-span policies.
- External viewport synchronization without feedback loops.
- Public visual styles for selection, masks, handles, and states.
- Mouse cursors, touch hit targets, keyboard actions, focus, and semantics.
- Light, dark, compact, responsive, and RTL verification.
- Integration examples for Candlestick and Line/Area charts.
- Performance benchmarks and public documentation.

### Explicitly out of scope for native v1

- A new chart-series family or renderer.
- Embedding the navigator inside `ChartScrollbar`.
- Y-axis navigation or two-dimensional viewport selection.
- Financial data fetching, market calendars, or stock range buttons.
- Automatic financial indicators or OHLC-to-close business logic.
- Arbitrary multi-series aggregation chosen silently by the package.
- Portable multi-chart composition artifacts.
- Persisting transient cursor or viewport state in `ChartDocument`.
- Radial charts.
- Live-stream follow-latest behavior; it requires a separate viewport policy.
- General annotation editing inside the navigator.

## Current proven implementation

The current implementation is a showcase-level composition, supported by
reusable public primitives. It is not yet the intended high-level API.

| Concern | Current implementation | Status |
|---|---|---|
| Shared X viewport | `ChartInteractionGroupController`, `ChartXViewport`, `setViewport`, and `viewportListenable` | Reusable package primitive |
| Main and volume panes | Normal `BravenChartPlus` participants with shared cursor and viewport | Reusable package behavior |
| Full-domain overview | Area series derived from Candlestick close values | Showcase-specific derivation |
| Visible window | Draggable X-only `RangeAnnotation` | Reusable annotation primitive |
| Live preview | `BravenChartPlus.onAnnotationDragUpdate` | Reusable package primitive |
| Gesture commit | `BravenChartPlus.onAnnotationDragged` | Reusable package primitive |
| Persistent handles | `persistentRangeAnnotationHandles` forwarded to `RangeAnnotationElement` | Provisional widget-level policy |
| Pointer affordance | `grab`, `grabbing`, and horizontal-resize cursors | Proven package behavior |
| Domain snapping | `FinancialTimeDomain.nearestIndex` | Showcase-specific policy |
| Range presets | Showcase-owned commands calling `setViewport` | Product composition, not navigator API |
| Accessibility | Existing chart semantics only | Native navigator gap |
| Handle theming | Hard-coded 8 px handles and colors derived from annotation border | Native navigator gap |

### Proven data flow

```text
Range buttons ───────────────┐
Main chart pan / zoom ───────┼──> ChartInteractionGroupController.viewport
Navigator drag preview ──────┘                  │
                                                ├──> Price chart X viewport
                                                ├──> Volume chart X viewport
                                                └──> Navigator range-window mirror

Navigator overview chart:
  full X domain
  independent Y domain
  synchronizeCursor = false
  synchronizeViewport = false
```

The navigator is a control surface, not a synchronization participant. It may
hold a reference to the group controller and issue `setViewport`, but it must
not receive the controlled viewport as its own chart viewport. Otherwise the
overview collapses to the selected interval and ceases to be a navigator.

## Native target architecture

### Component boundary

Add a package widget named `CartesianNavigator`.

It should use `BravenChartPlus` internally rather than introduce a second
painting stack. Its private implementation may use an `AnnotationController`
and X-only `RangeAnnotation`, but callers should not need to assemble or keep
those objects synchronized.

Do not add a second public viewport controller. The caller-owned
`ChartInteractionGroupController` is already the authoritative state and
command surface. A navigator-specific controller would create competing state,
ambiguous initialization, and avoidable feedback-loop risk.

### Proposed public API

The exact names may be refined in the lane, but the responsibilities and state
ownership are contract requirements.

```dart
CartesianNavigator(
  interactionGroupController: group,
  fullDomain: const ChartXViewport(min: 0, max: 419),
  initialViewport: const ChartXViewport(min: 354, max: 419),
  overviewSeries: AreaChartSeries(
    id: 'close-overview',
    points: closePoints,
  ),
  height: 112,
  behavior: const CartesianNavigatorBehavior(
    allowPan: true,
    allowResize: true,
    livePreview: true,
    minimumSpan: CartesianNavigatorSpan.data(1),
  ),
  snapPolicy: CartesianNavigatorSnapPolicy.values(sessionXs),
  style: const CartesianNavigatorStyle(
    selectionFill: Color(0x243B82F6),
    selectionBorder: Color(0xCC3B82F6),
    outsideFill: Color(0x14000000),
  ),
  handleStyle: const CartesianNavigatorHandleStyle(
    width: 10,
    height: 22,
    hitTargetExtent: 44,
  ),
  onViewportPreview: (viewport) {},
  onViewportCommitted: (viewport) {},
)
```

Recommended value objects:

- `CartesianNavigatorBehavior`
  - `allowPan`
  - `allowResize`
  - `livePreview`
  - `minimumSpan`
  - boundary behavior, fixed to clamp in v1
- `CartesianNavigatorSnapPolicy`
  - `none()`
  - `interval(double interval)`
  - `values(List<double> orderedValues)`
  - a custom callback may be considered only if it remains deterministic
- `CartesianNavigatorStyle`
  - background color
  - selection fill and border
  - outside-selection mask
  - border width and corner radius
  - axis/grid visibility or a normal chart configuration hook
- `CartesianNavigatorHandleStyle`
  - visual width, height, corner radius, fill, border, and grip
  - hover, pressed, and focused variants
  - independent hit-target extent
- `CartesianNavigatorSemantics`
  - optional label and X-value formatter
  - default labels for window, start handle, and end handle

The first implementation should accept exactly one `LineChartSeries` or
`AreaChartSeries`. This keeps derivation explicit and lets applications provide
raw, aggregated, enveloped, or downsampled overviews without the package
silently inventing domain semantics.

### Input invariants

- `fullDomain` must be finite and ordered.
- `overviewSeries` must have an X extent compatible with `fullDomain`.
- All emitted viewports must remain inside `fullDomain`.
- The selected span must never be smaller than the resolved minimum span.
- Snap values must be finite, strictly ordered, and inside or intentionally
  clampable to `fullDomain`.
- A caller-supplied `initialViewport` must be finite, ordered, and clampable.
- Empty and single-point overview data require explicit empty/disabled behavior;
  they must not fabricate an invalid viewport.

### Initialization precedence

Resolve the first window exactly once in this order:

1. An existing valid `interactionGroupController.viewport`.
2. A valid caller-supplied `initialViewport`.
3. The complete `fullDomain`.

The navigator then publishes the resolved viewport through `setViewport` so
late-attached charts receive the same state. Widget rebuilds must not reset a
user-selected viewport merely because `initialViewport` is unchanged.

### State ownership

| State | Owner | Persistence |
|---|---|---|
| Full overview domain | `CartesianNavigator` configuration | Immutable per configuration revision |
| Committed shared viewport | `ChartInteractionGroupController` | Runtime, caller-owned |
| Active drag preview | Navigator gesture state | Transient until commit/cancel |
| Range-window annotation | Navigator implementation | Derived mirror, never authoritative |
| Main-chart local Y domains | Each chart | Independent |
| Shared cursor | `ChartInteractionGroupController` | Transient; navigator opts out |
| Overview data | Caller | Normal application/series lifecycle |
| Window and handle style | Navigator configuration/theme | Declarative |

The range annotation must always be derived from the group viewport when idle.
During a gesture, a private preview guard prevents the annotation mirror from
replacing the in-flight geometry. On commit, clamp and snap once, call
`setViewport`, and explicitly mirror the final value even when the last preview
equals the committed value and the controller deduplicates notification.

### Gesture state machine

```text
idle
 ├─ hover window ───────────────> windowHover (grab)
 ├─ press window ───────────────> panning (grabbing)
 ├─ hover left/right handle ────> handleHover (resizeLeftRight)
 └─ press left/right handle ────> resizing

panning/resizing
 ├─ pointer move ───────────────> clamp + snap preview + setViewport
 ├─ pointer up ─────────────────> commit final viewport -> idle
 └─ pointer cancel / Escape ────> restore pre-gesture viewport -> idle
```

Body panning preserves the selected span, including when either domain boundary
is reached. Edge resizing changes only the corresponding boundary. Crossing
handles is not permitted in v1; the active edge stops at the minimum span.

Every preview must update the controlled charts before pointer-up. Range
manipulation must never publish or move the shared tracking cursor.

### External updates during interaction

When idle, any group viewport update immediately moves and resizes the window.

When a drag is active, the navigator owns the preview. External viewport writes
must not jump the active handle. The recommended v1 policy is:

- remember the external value;
- finish or cancel the active gesture;
- then reconcile to the most recent controller viewport.

This policy needs a direct test. If the lane chooses external-write-wins, that
must be an explicit public contract rather than incidental listener ordering.

## Data and coordinate model

### Matching X space, independent Y space

The navigator and controlled charts must use the same logical X coordinate
space. Their Y values and Y domains remain independent. A Candlestick chart may
therefore use close price for the overview, while a Line chart may use one
primary signal or a separately calculated envelope.

For financial time, ordinal and elapsed mappings remain application/domain
decisions. When the mapping mode changes, rebuild both the controlled series and
overview series into the new X space, then map the existing viewport through
domain indices before publishing it again.

### Overview derivation policy

The package must not guess which of several series represents the overview.
Callers provide the overview series explicitly.

Acceptable inputs include:

- the primary Line/Area series unchanged;
- Candlestick close values;
- a precomputed moving average;
- a min/max envelope reduced to one visual series; or
- a caller-downsampled representation for very large sources.

Convenience factories such as `CartesianNavigator.fromCandlestickClose` may be
added later, but they must be explicit transformations with documented output.

The navigator should reuse normal visible-range and density optimizations. It
must not clone or regenerate a large overview point list on every pointer move.

## Styling and theming contract

The native feature must expose styling without leaking annotation internals.

### Required states

- default
- window hover
- window pressed
- handle hover
- handle pressed
- keyboard focus
- disabled

The left and right handles are persistent in the default configuration. Their
visual size may be compact, but their effective pointer/touch target must be at
least 44 logical pixels where layout permits. The hit target must not obscure
the complete window on narrow selections; define deterministic overlap
priority: active handle, nearest handle, then body.

Support both an inside-selection fill and an outside-selection mask. The
current prototype fills the selected area; stock-style consumers often shade
the area outside it. These are styling choices, not different interaction
models.

Default pointer cursors:

| Target/state | Cursor |
|---|---|
| Window hover | `SystemMouseCursors.grab` |
| Window pressed/dragging | `SystemMouseCursors.grabbing` |
| Left or right handle | `SystemMouseCursors.resizeLeftRight` |
| Disabled navigator | `SystemMouseCursors.basic` |

All colors must derive from the active chart theme unless explicitly
overridden. Light and dark defaults need WCAG-conscious contrast for handles,
focus indicators, and the overview line.

## Accessibility and keyboard contract

The current prototype does not yet provide dedicated range-control semantics.
Native implementation is incomplete until it does.

Expose three ordered semantic/focus targets:

1. Visible range start handle.
2. Visible range window.
3. Visible range end handle.

Each target reports a formatted X value or range. Recommended operations:

| Input | Start/end handle | Window |
|---|---|---|
| Left/Right | Move by one snap step | Pan by one snap step |
| Shift + Left/Right | Move by a larger step | Pan by a larger step |
| Home/End | Move edge to domain boundary | Move window to domain boundary |
| Page Up/Page Down | Resize by one coarse step | Pan by one window fraction |
| Escape | Restore pre-gesture value | Restore pre-gesture value |

Keyboard commands must use the same clamp, snap, minimum-span, preview, and
commit reducer as pointer input. Do not maintain a second keyboard algorithm.

RTL affects visual direction and focus traversal, but it must not silently
reverse the underlying ordered data domain. Document and test arrow behavior.

## Relationship to existing systems

### Cartesian synchronization

The feature builds directly on `ChartInteractionGroupController`. Controlled
charts attach normally. The internal overview chart uses:

```dart
const ChartInteractionGroupOptions(
  synchronizeCursor: false,
  synchronizeViewport: false,
)
```

The navigator observes `viewportListenable` and writes through `setViewport`.
No new fanout bus is required.

### Scrollbars

The navigator and scrollbar are separate controls that can technically coexist
because both write the same X viewport. Product guidance should normally use
the navigator instead of the X scrollbar to avoid duplicate controls. A Y
scrollbar remains independent and may coexist.

Do not subclass `ChartScrollbar`, put chart rendering inside its track, or add
navigator knowledge to `ScrollbarManager`.

### Annotations

`onAnnotationDragUpdate` is broadly useful and should remain a core primitive.
The `persistentRangeAnnotationHandles` property is provisional. The new lane
must make an explicit compatibility decision:

- retain it as a general annotation feature; or
- internalize the policy in `CartesianNavigator` and deprecate it only through
  the normal public API process after the Candlestick lane lands.

Do not remove a landed public property without a migration period.

### Workbench and artifacts

The navigator is not a chart family, so it does not require a new
`ChartSeriesExtensionCodec`, Data-mode table, or Source generator.

The overview series remains an ordinary Line/Area series. Runtime group state,
cursor position, and current viewport are not added to `ChartDocument`.
Portable multi-chart layouts would be a separate artifact/product project.

Workbench examples may show the code needed to compose a navigator, but v1 does
not teach a single-chart Workbench to serialize an entire synchronized layout.

## Performance architecture

### Hot-path rules

- Pointer movement updates transient range geometry and one shared viewport.
- Do not replace the controller-owned annotation on every pointer event.
- Do not rebuild or copy overview data during pan or resize.
- Do not scan the complete source list to resolve every visible range.
- Reuse the controller's equality and reentrancy guards.
- Keep cursor fanout disabled for the navigator.
- Prefer repaint/transform updates over rebuilding all synchronized widgets.

### Required benchmark matrix

Measure preview and committed viewport fanout for:

| Dimension | Required cases |
|---|---|
| Controlled charts | 1, 2, 3, 6, and 12 |
| Source size | 420, 5,000, and 50,000 X values |
| Overview input | raw, pre-downsampled, and dense rendered input |
| Gesture | window pan, left resize, right resize |
| Build | debug benchmark plus release/profile browser smoke |

The default gate is p95 below one 16.67 ms frame for the representative stock
composition, with no sustained missed-frame growth over a continuous drag.
Record median, p95, callback count, rebuild count, and visible geometry count.

Performance tests are sensitive to concurrent test load. A failure in the full
suite must be rerun in isolation and reported with both results; do not simply
raise the budget.

## Failure and lifecycle behavior

- Disposing the navigator detaches listeners without disposing the caller-owned
  group controller.
- Disposing the group first must not cause late navigator callbacks to throw.
- Switching group controllers detaches the old listener before attaching the
  new one.
- Invalid external viewports fail fast at the public controller boundary.
- Pointer cancel and Escape restore the last committed viewport.
- Layout resize preserves data-space viewport values.
- Changing `fullDomain` clamps the committed viewport and emits one reconciled
  update if needed.
- Removing or adding synchronized panes never resets the shared viewport.
- Empty overview data renders a documented disabled/empty state.

## Implementation slices

### Slice 0 — Dependency landing and contract freeze

**Work**

- Land the Candlestick lane containing `setViewport`, `viewportListenable`, live
  annotation preview, persistent handles, X-only handle behavior, and cursor
  affordances.
- Branch the navigator lane from the resulting `master`.
- Add failing contract tests for initialization precedence, cursor isolation,
  live preview, commit, and cancel.
- Freeze public names only after one API review.

**Acceptance**

- The new lane contains no copied showcase implementation.
- Every dependency is on `master`; no cross-worktree path or unmerged commit is
  assumed.

### Slice 1 — Pure viewport reducer and policy models

**Work**

- Implement pure pan, resize, clamp, snap, and minimum-span calculations.
- Add behavior, snap, and span value objects.
- Define initialization and external-update precedence.

**Acceptance**

- Unit tests cover both boundaries, reversed pointer movement, one-value spans,
  irregular snap values, floating-point edges, and domain replacement.
- Pointer and keyboard integrations can call the same reducer.

### Slice 2 — Native widget composition

**Work**

- Add `CartesianNavigator` using the existing Cartesian renderer.
- Keep its overview at `fullDomain` and mirror the group viewport internally.
- Support one Line/Area overview series and documented empty/disabled states.
- Establish responsive height and axis-label defaults.

**Acceptance**

- External main-chart pan/zoom moves the navigator window without changing the
  overview domain.
- Rebuilding the widget does not reset the viewport.
- Navigator tracking and tooltips remain disabled by default.

### Slice 3 — Interaction lifecycle

**Work**

- Wire body pan and both edge-resize gestures.
- Publish live preview before pointer-up.
- Commit, cancel, and reconcile external writes explicitly.
- Add correct hover/pressed cursors and touch hit targets.

**Acceptance**

- Real pointer tests prove controlled charts update during the drag.
- The shared cursor remains unchanged throughout navigator interaction.
- Boundary panning preserves window width and resizing respects minimum span.
- Pointer cancel restores the pre-gesture viewport.

### Slice 4 — Styling, theme, keyboard, and semantics

**Work**

- Add public navigator/window/handle styles and themed defaults.
- Add persistent handles with hover, pressed, focus, and disabled states.
- Add the three semantic targets and shared keyboard actions.
- Verify compact, light, dark, high-contrast, touch, and RTL behavior.

**Acceptance**

- No hard-coded prototype handle colors or sizes remain in the high-level
  widget.
- Semantics tests can read and change both boundaries and pan the window.
- Focus is visible at 200% text scale and does not clip.

### Slice 5 — Product integrations and migration

**Work**

- Replace only the Candlestick showcase's local navigator builder and helper
  synchronization with the native widget.
- Preserve current stock-composition visuals, range presets, ordinal/elapsed
  mapping, volume toggling, and code example.
- Add a Line/Area synchronized example proving the feature is family-neutral.
- Document coexistence guidance for X/Y scrollbars.

**Acceptance**

- The existing Candlestick composition remains pixel- and behavior-equivalent.
- The same widget controls at least one Line/Area composition without
  Candlestick imports or finance-specific helpers.
- Workbench and artifact tests remain unchanged unless documentation links are
  intentionally added.

### Slice 6 — Performance, E2E, docs, and release readiness

**Work**

- Add the benchmark matrix and rebuild instrumentation.
- Add goldens and direct-route browser checks.
- Publish API docs, composition guidance, and migration notes.
- Run package and example release gates.

**Acceptance**

- Representative p95 preview fanout remains below one frame.
- Package analyze/tests, example analyze/tests, release web build, direct route,
  and pub.dev dry run pass.
- No known keyboard, semantics, lifecycle, or pointer-cancel gaps remain.

## Verification matrix

### Unit tests

- Initialization precedence and no rebuild reset.
- Pan preserves width at both boundaries.
- Left/right resize and minimum-span enforcement.
- None, interval, and irregular-value snapping.
- Commit, cancel, and external-update reconciliation.
- Domain replacement and invalid input failures.

### Widget and interaction tests

- Window and handles persist without annotation selection.
- Viewport changes before pointer-up for all three gestures.
- `grab`, `grabbing`, and `resizeLeftRight` cursors.
- Touch input and overlapping handle/body hit-test priority.
- Main chart, volume pane, and navigator maintain independent Y scales.
- Navigator does not publish or receive cursor tracking.
- Adding/removing panes preserves the viewport.
- Layout resize and theme changes preserve state.

### Accessibility tests

- Three focusable semantic targets in deterministic order.
- Formatted values and ranges announced correctly.
- Increment/decrement and keyboard commands change the viewport.
- Disabled and empty states are announced.
- RTL and large text remain operable.

### Visual tests

- Light and dark defaults.
- Inside fill and outside mask modes.
- Hover, pressed, focused, and disabled handles.
- Compact and desktop sizes.
- Minimum-width window without handle clipping.

### Performance and release tests

- Controller fanout benchmarks at the required chart/data matrix.
- Continuous pointer-drag frame sampling.
- Rebuild and visible-geometry counts.
- `flutter analyze lib`.
- Complete package test suite.
- Example `flutter analyze lib test`.
- Complete example test suite.
- `flutter build web --release` from the example.
- Direct navigator showcase route and compiled asset HTTP 200.
- `dart pub publish --dry-run` with zero package warnings.

## Migration plan from the prototype

Keep the current Candlestick composition intact as the oracle while Slices 1–4
are developed. Do not refactor it incrementally into half-native state.

Once the native widget meets its focused tests:

1. Replace `_buildStockNavigator` with `CartesianNavigator`.
2. Move generic clamp/snap/minimum-span logic into the native reducer.
3. Keep financial ordinal/elapsed mapping and preset definitions in the
   showcase because they are domain-specific.
4. Remove the showcase's annotation controller and preview guard only after
   behavior parity is proven.
5. Compare light/dark desktop and compact captures.
6. Run the full Candlestick and package verification gates.

The old implementation should be removed in the same slice that proves native
parity; do not leave two production paths selectable by an undocumented flag.

## Known gaps the new lane inherits

- Pointer cancel does not yet have an explicit navigator restoration contract.
- Dedicated handle/window semantics and keyboard operations are absent.
- Handle visuals and hit targets are not fully public styles.
- `persistentRangeAnnotationHandles` is a provisional broad widget property.
- Clamp/snap logic is coupled to `FinancialTimeDomain` in the showcase.
- There is no generic minimum-span policy.
- Overview derivation and downsampling are caller/manual concerns.
- There is no high-level navigator widget or native empty/disabled state.
- External viewport writes during an active gesture are not formally resolved.
- Portable multi-chart composition is intentionally unsupported.

These are lane scope, not reasons to redesign the shared viewport controller.

## Handoff decisions requiring confirmation

The recommended answers are included so the lane can proceed unless product
review explicitly changes them.

| Question | Recommendation |
|---|---|
| Public widget name | `CartesianNavigator` |
| State authority | Existing `ChartInteractionGroupController` only |
| Overview input | Exactly one caller-supplied Line or Area series in v1 |
| Artifact portability | Runtime-only composition in v1 |
| Initial state precedence | Existing group viewport, then initial viewport, then full domain |
| Boundary behavior | Clamp; never wrap or overscroll in v1 |
| Window presentation | Support selected-area fill and outside mask |
| Handle visibility | Persistent by default |
| During-drag external writes | Defer and reconcile after gesture |
| Provisional annotation flag | Retain until native migration proves whether it remains generally useful |

## Required reading for the receiving lane

- `lib/src/controllers/chart_interaction_group_controller.dart`
- `lib/src/braven_chart_plus.dart`
- `lib/src/elements/annotation_elements.dart`
- `lib/src/rendering/modules/event_handler_manager.dart`
- `example/lib/showcase/pages/candlestick_charts_page.dart`
- `example/test/showcase/candlestick_charts_page_test.dart`
- `test/unit/rendering/modules/annotation_drag_handler_test.dart`
- `test/benchmarks/controllers/candlestick_three_pane_fanout_benchmark_test.dart`
- `docs/superpowers/plans/2026-07-19-synchronized-cartesian-charts.md`
- `docs/superpowers/specs/2026-07-18-path-strokes-and-synchronized-charts-design.md`
- `docs/superpowers/specs/2026-07-19-candlestick-cartesian-chart-design.md`
- `doc/chart_family_integration.md`
- `docs/archive_release_1.0/repos/specs/010-dual-purpose-scrollbars/spec.md`
- `docs/archive_release_1.0/docs/refactor/prototype/architecture/03-zoom_pan.md`

## Do-not-break rules

- Do not make the navigator's overview adopt the controlled viewport.
- Do not create a competing public viewport controller.
- Do not update tracking cursor state while manipulating the navigator.
- Do not calculate the visible chart only on pointer release.
- Do not regenerate overview data on pointer movement.
- Do not put finance-specific range presets or close-price derivation in the
  generic widget.
- Do not turn the navigator into a new series family or Workbench codec.
- Do not merge it into the X scrollbar implementation.
- Do not remove the reviewed showcase oracle before native parity is proven.
- Do not open a PR before the lane's local review checkpoint is approved.

## Definition of done

The architecture enhancement is complete only when:

1. `CartesianNavigator` is a documented public package widget.
2. It controls arbitrary Cartesian chart groups through the existing shared X
   viewport contract.
3. Window pan and edge resize update all controlled charts continuously.
4. Main-chart pan/zoom updates the navigator without shrinking its full-domain
   overview.
5. Navigator gestures never disturb tracking cursors.
6. Styling covers the window, masks, persistent handles, and all interaction
   states.
7. Pointer, touch, keyboard, semantics, cancel, lifecycle, and RTL behavior are
   deterministic and tested.
8. Candlestick and Line/Area showcase compositions both use the native widget.
9. Representative p95 fanout remains below one frame with recorded evidence.
10. Package, example, release-web, direct-route, and publish-readiness gates are
    green.

At that point the feature is native Cartesian infrastructure rather than an
excellent but page-local stock composition.
