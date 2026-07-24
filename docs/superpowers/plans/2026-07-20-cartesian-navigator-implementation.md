# Cartesian Navigator Implementation Plan

**Status:** Complete; merged in
[PR #69](https://github.com/braven-pvm/braven_charts/pull/69)

**Authoritative handoff:** `2026-07-20-cartesian-navigator-architecture-handoff.md`  
**Target:** one reusable, family-neutral X-range navigator for every Cartesian
`BravenChartPlus` composition.

## Delivery evidence

All seven slices shipped at merge commit `01a56f4b`. The package exports the
public widget and its behavior, snap-policy, and style models; focused reducer
and widget tests cover the viewport and interaction lifecycle; integration and
benchmark suites cover family-neutral synchronization and fan-out behavior.
The public [`doc/cartesian_navigator.md`](../../../doc/cartesian_navigator.md)
guide documents the contract and runnable showcase compositions exercise Line,
Area, Bar, Scatter, Candlestick, Interaction, Live Stream, and Gallery hosts.
Package quality passed on PR #69. Later Candlestick pane-alignment and
technical indicator adoption landed separately in PRs #71 and #78.

## Product contract

`CartesianNavigator` is a range-control composition, not a chart family and not
an enhanced scrollbar. It renders one caller-supplied Line or Area overview
series across the complete X domain and controls any synchronized Cartesian
charts through the caller-owned `ChartInteractionGroupController`.

The interaction group remains the only public viewport authority. The
navigator observes `viewportListenable`, publishes changes through
`setViewport`, and opts its internal overview chart out of cursor and viewport
synchronization. This prevents the overview from adopting the selected window
or participating in tracking.

## Public API shape

```dart
CartesianNavigator(
  interactionGroupController: groupController,
  overviewSeries: overviewAreaSeries,
  fullDomain: const ChartXViewport(min: 0, max: 100),
  initialViewport: const ChartXViewport(min: 60, max: 100),
  behavior: const CartesianNavigatorBehavior(
    minimumSpan: 4,
  ),
  snapPolicy: CartesianNavigatorSnapPolicy.interval(1),
)
```

The public surface consists of:

- `CartesianNavigator`
- `CartesianNavigatorBehavior`
- `CartesianNavigatorSnapPolicy`
- `CartesianNavigatorStyle`
- optional viewport preview/commit callbacks

Annotation controllers, internal range annotations, and reducer mechanics are
implementation details.

## Invariants

1. The overview chart always displays `fullDomain` and computes its own Y
   domain.
2. Existing valid controller state wins over `initialViewport`; a valid initial
   viewport wins over the full domain.
3. Initialization publishes the resolved viewport through `setViewport`.
4. Rebuilds preserve the active viewport unless the full domain no longer
   contains it.
5. Window panning preserves its data-space span at both domain boundaries.
6. Edge resizing moves only the active edge and never crosses the other edge.
7. Pointer movement previews live; pointer-up commits the latest preview.
8. During a local gesture, external viewport writes are remembered and
   reconciled after the gesture rather than interrupting the drag.
9. Pointer and keyboard interactions use the same pure viewport reducer.
10. The navigator never publishes or clears a shared tracking cursor.

## Delivery slices

### Slice 0 - dependency and contract freeze

- Verify the synchronized-controller, annotation-drag, and Candlestick oracle
  tests are green.
- Freeze public names and initialization precedence in this plan.
- Preserve the Candlestick local navigator until native parity is proven.

### Slice 1 - pure viewport policy

- Add behavior and snap-policy value types with release-mode validation.
- Add a pure reducer for initialization, clamping, panning, resizing, snapping,
  minimum span, and domain replacement.
- Cover boundaries, reverse movement, irregular snap values, single-value snap
  sets, floating-point precision, and precedence.

### Slice 2 - native widget composition

- Compose the caller's Line/Area series into an internal `BravenChartPlus`.
- Keep the internal chart full-domain and opt it out of group cursor/viewport
  synchronization.
- Paint the selected window, outside mask, and handles without exposing
  annotation APIs.

### Slice 3 - interaction lifecycle

- Add body pan and edge resize with live preview.
- Add pointer cancel/lost-capture handling.
- Reconcile deferred external writes after local gestures.
- Verify no cursor pollution and no data regeneration in the move path.

### Slice 4 - styling and accessibility

- Add theme-derived default style plus explicit fill, border, mask, handle,
  hover, pressed, focus, and disabled overrides.
- Provide 48 logical-pixel interaction targets where layout permits while
  keeping visual handles compact.
- Expose ordered start-edge, window, and end-edge semantics/focus targets.
- Route keyboard movement and resizing through the reducer.

### Slice 5 - integration proof

- Migrate the Candlestick showcase only after parity tests pass.
- Add Line and Area proof compositions controlling synchronized Cartesian
  charts.
- Verify Bar, Scatter, and Candlestick controlled charts require no family
  adapters.

### Slice 6 - release proof

- Add fan-out performance coverage and ensure pointer-move work is constant
  with respect to overview data size.
- Run package tests, example tests, analysis, and release web build.
- Update the public API overview, showcase docs, changelog, and release notes.

## Explicitly out of scope

- Y-axis navigation
- live-stream follow-latest policy
- radial charts
- financial data aggregation or presets
- artifact multi-layout encoding
- replacement or merger of the existing scrollbar

