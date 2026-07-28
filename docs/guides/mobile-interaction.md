# Mobile interaction

Braven Charts separates page browsing, chart navigation, and data inspection so
touch-first products can choose the gesture contract that fits each surface.

Use the Browse profile when a chart lives inside a scrolling page. One-finger
dragging remains available to the parent scrollable, while two fingers may
still pan and zoom the chart. Short taps can be disabled so an accidental tap
does not select a point or open tracking feedback; users then hold one finger
to inspect and scrub the chart.

## Scroll-first Browse configuration

```dart
BravenChartPlus(
  series: series,
  interactionConfig: const InteractionConfig(
    enablePan: true,
    enableZoom: true,
    touch: TouchInteractionConfig(
      profile: TouchInteractionProfile.browse,
      tapBehavior: TouchTapBehavior.disabled,
      enablePan: true,
      enablePinchZoom: true,
      enableLongPressTracking: true,
    ),
  ),
)
```

This configuration gives a mobile user the following contract:

| Gesture | Result |
|---|---|
| Short one-finger tap | No chart action |
| One-finger drag | Scroll the surrounding page |
| Hold one finger | Start transient tracking |
| Hold, then drag | Scrub the crosshair and tracking tooltip |
| Release after tracking | Clear transient tracking |
| Two-finger drag | Pan the chart |
| Two-finger pinch | Zoom the chart |

`TouchTapBehavior.disabled` only gates direct-touch short taps. It does not
disable mouse or pen clicks, keyboard navigation, accessibility actions,
long-press tracking, or touch viewport gestures.

## Explore configuration

Use Explore when the chart is the focused work surface and one-finger chart
navigation is more important than scrolling the page:

```dart
const InteractionConfig(
  touch: TouchInteractionConfig(
    profile: TouchInteractionProfile.explore,
    tapBehavior: TouchTapBehavior.inspectAndSelect,
  ),
)
```

Explore permits one-finger panning after drag slop. The default
`TouchTapBehavior.inspectAndSelect` preserves the package's existing
tap-to-inspect and tap-to-select behavior.

## Configure tap and hold independently

Short-tap activation and long-press tracking are separate policies:

```dart
const TouchInteractionConfig(
  tapBehavior: TouchTapBehavior.disabled,
  enableLongPressTracking: false,
)
```

The example above makes both short tap and hold inert while leaving the
configured viewport gestures available. Conversely, enabling long-press
tracking while disabling short taps creates the scroll-first inspection model
shown in the Browse example.

Top-level interaction gates still apply. For example,
`InteractionConfig.enablePan: false` prevents panning even when
`TouchInteractionConfig.enablePan` is true.

## Compatibility and persisted documents

The default remains `TouchTapBehavior.inspectAndSelect`, so existing
applications retain their current touch behavior. Chart documents written by
older package versions also decode to `inspectAndSelect` when the field is
absent.

The touch policy is included in portable interaction documents and generated
Dart source. It can therefore travel with a captured chart instead of being
reconstructed by each host.

## Current boundaries

- Long-press tracking currently uses the Cartesian tracking cursor. Radial
  chart families keep their existing direct-selection interaction.
- A host that also assigns long press to a context menu should choose which
  action owns the gesture instead of enabling both.
- Haptic feedback is best effort and is safely ignored on unsupported
  platforms.

Try the contract on a touch device in the
[Mobile Interaction showcase](https://braven-pvm.github.io/braven_charts/?page=mobile-interaction).
