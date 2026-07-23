# Mobile Interaction Phase 2: Long-press tracking scrub

## Status — release candidate

Implemented and release-hardened on 2026-07-23. Long-press tracking reuses the
existing renderer-owned Cartesian tracking pipeline, clears on lift, respects
the public touch and haptic gates, and yields to a configured context menu.
The viewport hardening pass verifies that a claimed pan/pinch suppresses scrub,
tap selection, and crosshair publication for the remainder of that touch
sequence.

## Outcome

Add a phone-friendly way to inspect dense Cartesian data without introducing a
second tooltip or cursor system.

Users can press and hold inside a Cartesian plot, drag while holding to scrub
the existing tracking crosshair, and lift to clear the transient inspection.

## Interaction contract

- A normal touch tap keeps its existing selection and tap-tooltip behavior.
- Movement before the long-press timeout remains owned by page scrolling in
  `browse` and viewport panning in `explore`.
- Holding for `GestureConfig.longPressTimeout` enters tracking scrub.
- Dragging while held updates the existing renderer-owned tracking cursor.
- Lifting or cancelling clears the transient crosshair, marker feedback, and
  tracking tooltip.
- Two-finger viewport gestures retain priority over tracking scrub.
- When `ChartContextMenuConfig.enableLongPress` is enabled, the context menu
  owns long press and tracking scrub is not registered.
- Phase 2 applies to Cartesian charts. Radial chart families retain their
  existing selection and context-menu behavior.

## Public configuration

Extend `TouchInteractionConfig` with:

- `enableLongPressTracking` — enables the long-press scrub recognizer.
- `enableHapticFeedback` — requests a selection haptic on activation and when
  the scrub crosses to a different snapped X observation.

Both remain subordinate to `TouchInteractionConfig.enabled` and
`InteractionConfig.enabled`.

## Architecture

- Gesture recognition lives in `BravenChartPlus`.
- Gesture ownership is represented by a dedicated coordinator mode.
- Raw pointer candidates are cancelled when scrub wins the gesture arena.
- `ChartRenderBox` exposes a narrow touch-tracking entry point that delegates
  marker resolution to `EventHandlerManager` and publishes through the existing
  crosshair callbacks.
- No new overlay, tooltip, hit-test index, or cursor model is introduced.

## Showcase

The mobile interaction page must:

- enable scrub by default;
- provide a visible toggle for scrub and haptics;
- explain the hold-drag-lift gesture;
- show the currently snapped day so activation and movement can be verified;
- remain usable at phone width with 48 logical-pixel controls.

## Verification

- Model equality, copy, artifact codec, and source-generation coverage.
- Widget tests for activation, movement, clearing, disabling, viewport
  arbitration, and context-menu precedence.
- Existing touch tap, browse scroll, explore pan, and pinch regressions.
- Scoped analysis, showcase tests, and release web build.
- Physical-phone review through the LAN web server.

All listed verification items are complete. Physical phone review confirmed
hold-drag-lift tracking alongside Browse and Explore navigation. Automated
coverage also verifies context-menu precedence and that crosshair callbacks are
explicitly cleared when viewport navigation takes ownership.
