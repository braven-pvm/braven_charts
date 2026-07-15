# Braven Charts showcase

This Flutter application is the runnable product tour for Braven Charts. It is
also the source for pub.dev screenshots and the public web demo.

## Run locally

From the repository root:

```bash
cd example
flutter pub get
flutter run -d chrome
```

For a release build:

```bash
flutter build web --release
```

## Feature map

| Showcase page | What to try |
| --- | --- |
| Gallery | Flagship multi-axis analysis, baseline fills, glow, live streaming, small multiples, chart types, annotations, tracking, and real-world compositions |
| Chart Types | Switch among line, area, bar, and scatter series and tune their visual parameters |
| Interaction | Zoom and pan with pointer, touch, toolbar, and keyboard input; reset the viewport |
| Tracking Lab | Crosshair modes, snap-to-point behavior, tracking panels, and styled tooltips |
| Annotations | Point, range, text, threshold, trend, pin, legend, and editing workflows |
| Segment Styling | Conditional colors, per-segment styles, gradients, and alert thresholds |
| Streaming / Live Stream | Follow-latest viewports, frame-coalesced ingestion, pause/resume, buffering, and catch-up |
| Theming | Light, dark, accessible, and custom chart themes |
| Multi-Axis / Axis Slots | Independent Y units, shared axes, normalization, visible slots, overflow, and runtime series selection |
| Scientific | Dense measurement data and scientific formatting |
| Baseline Fill | Positive/negative and above/below-target area fills |
| Loading States | Animated chart skeleton, circular/linear progress, empty results, and custom state content |
| Performance | Large data sets and rendering diagnostics |

Additional focused pages cover minor ticks, explicit render ranges, point
labels, series styling, power/lactate analysis, and lactate-threshold chord
annotations.

## Interaction shortcuts

- Hover a series or marker for its tooltip.
- Move across a tracking chart to inspect synchronized series values.
- Drag or wheel over interactive charts to pan and zoom.
- Use scrollbars where enabled to inspect a constrained viewport.
- Select a legend entry or series in multi-axis demos to exercise axis slots.
- Pause live streams, allow points to buffer, then resume.
- Open annotation controls to create, edit, drag, or remove overlays.

## Responsive navigation

Desktop and tablet layouts use a scrollable feature rail. Narrow layouts use a
drawer so every demo remains reachable without an oversized bottom navigation
bar.

## Screenshot routes

The Gallery is designed as the primary pub.dev image. Focused screenshots can
also be captured from Multi-Axis, Live Stream, Annotations, and Loading States
to show the interaction engine and application states in more detail.

See the repository [release checklist](../doc/release_checklist.md) for capture
sizes and the public deployment workflow.
