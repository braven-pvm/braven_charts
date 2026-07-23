# Mobile interaction phase 1

## Status — release candidate

Implemented and release-hardened on 2026-07-23 against `master` 0.13.2.
Physical browser testing on a phone over the LAN verified Browse scrolling,
two-finger zoom/pan, Explore one-finger pan, and the transition from an active
one-finger pan into a two-finger pinch.

The release-hardening pass also verified Line, Area, Range Area, horizontal
Bar, Scatter, and Candlestick charts. It fixed:

- off-centre pinch drift by composing incremental zoom around the previous
  focal point before applying the inverse centroid translation;
- Explore mode claiming stationary one-finger taps before drag slop;
- viewport gestures leaving stale crosshair callback state;
- offscreen Cartesian semantics nodes after viewport changes;
- touch drag-selection losing to Browse/Explore viewport arbitration; and
- pending empty-area drag selection being ignored while the coordinator was
  still in its passive pre-claim state.

## Outcome

Make Cartesian charts usable inside phone and tablet layouts without stealing
the surrounding page's primary scroll gesture.

This phase establishes the shared gesture contract and viewport plumbing. It
does not attempt to reproduce every desktop editing interaction on a phone.

## Interaction contract

### Browse profile (default)

| Input | Chart behavior |
| --- | --- |
| One-finger drag | Remains available to the parent scrollable |
| Tap | Inspect or select using the existing chart interaction policy |
| Two-finger pinch | Zoom around the gesture focal point |
| Two-finger translation | Pan the visible viewport |
| Reset / fit | Restore the complete data viewport |

The recognizer must not win the gesture arena for a single touch pointer. A
second pointer is the explicit signal that the chart owns the gesture.

### Explore profile

| Input | Chart behavior |
| --- | --- |
| One-finger drag | Pan after configured drag slop |
| Tap | Inspect or select when drag slop is not crossed |
| Two-finger pinch | Zoom around the gesture focal point |
| Two-finger translation | Pan the visible viewport |
| Reset / fit | Restore the complete data viewport |

Explore is an explicit product choice for a chart-focused surface. It is not
the embedded-chart default.

### Tablet

Tablet behavior is selected by input capability and product context, not width
alone. Touch input follows the selected touch profile. Mouse, trackpad, and
keyboard input retain the existing desktop interaction contract.

## Architecture

- Add touch policy to `InteractionConfig`; do not infer it from platform.
- Participate in Flutter's gesture arena through the chart's existing
  `RawGestureDetector`.
- Claim one coordinator mode for a continuous viewport transform.
- Suppress hover, tooltip, selection, and cursor publication while that mode is
  active.
- Apply zoom and pan as paint-only updates while fingers move.
- Rebuild chart elements, spatial indexes, and caches once when the gesture
  finishes.
- Expose reset/fit through `BravenChartController` so applications can provide
  accessible touch-sized controls outside the rendering surface.

No second viewport state, chart canvas, or mobile-only renderer is introduced.

## Public surface

`TouchInteractionConfig`:

- `enabled`
- `profile`: `browse` or `explore`
- `enablePinchZoom`
- `enablePan`

Global `InteractionConfig.enableZoom` and `enablePan` remain the final feature
gates. Touch policy only determines how touch input may request those actions.

## Acceptance criteria

1. A one-finger vertical drag over a browse-profile chart scrolls its parent.
2. A two-finger gesture zooms and pans a Cartesian chart.
3. Explore mode pans with one finger without converting a tap into a pan.
4. The focal data position remains visually stable during pinch zoom.
5. Tooltip/crosshair/selection state does not fire during a viewport transform.
6. Geometry and spatial indexes rebuild once at gesture completion, not once
   per pointer update.
7. Reset/fit restores the original data bounds.
8. Mouse, keyboard, annotation, selection, and synchronized viewport tests
   remain green.
9. A focused showcase demonstrates browse versus explore behavior and provides
   48 px minimum touch targets for mode and viewport actions.

All nine criteria are complete. Automated evidence is concentrated in
`test/widgets/mobile_touch_interaction_test.dart` and
`test/widgets/mobile_touch_release_hardening_test.dart`; the existing Scatter
selection matrix verifies rectangle/lasso priority over viewport navigation.

## Release verification

- Combined mobile suites: 20 tests passed.
- Cross-family release-hardening matrix: 13 tests passed.
- Core interaction regression suite: 42 tests passed.
- Full showcase suite: 407 tests passed.
- Package library analysis: no issues found.
- Showcase analysis: no issues found.
- Release web build: passed, including Flutter's WASM dry run.
- Full package suite: 3,553 tests passed with 6 intentional skips.

The checked-in example Android project is not accepted by the current Flutter
Gradle toolchain (`unsupported Gradle project`), so native APK compilation is a
separate packaging migration rather than a phase-1 interaction gate. iOS
packaging is not available on the Windows host. Browser-on-phone verification
is complete.

## Deferred follow-up

- Velocity-aware fling behavior.
- Mobile annotation creation/editing and touch-sized edit handles.
- Explicit accessibility actions for viewport and selection controls.
- Native Android Gradle migration plus Android/iOS device-lab coverage.
- Touch handles for resize and range selection.
- Velocity/fling panning.
- Platform accessibility actions beyond the existing semantic/keyboard layer.
- Android Gradle project migration, native Android/iOS packaging gates, and
  device-lab coverage.
