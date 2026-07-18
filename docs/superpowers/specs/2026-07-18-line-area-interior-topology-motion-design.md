# Line and Area Interior Topology Motion

**Status:** In progress
**Roadmap:** Sprint 9 of Line and Area Product Parity
**Implementation lane:** `feature/line-area-interior-topology`
**Prerequisite:** Sprint 8 / PR #38

## Goal

Animate common analytical snapshot corrections where stable points enter or
leave inside an existing Line or Area path. The standard renderer, canonical
target identity, and one-controller-per-phase timing model remain unchanged.

Typical examples are a late sample inserted between two accepted readings or
a bad interior reading removed after validation.

## Compatibility contract

An interior topology snapshot is compatible when all of these are true:

- source and target retain the same series ID, runtime type, and interpolation;
- retained points match by timestamp, then `x + label`, in the same order;
- at least one stable identity remains, and every interior edit is bracketed
  by retained identities on both sides;
- the snapshot contains interior insertions or interior removals, not both;
- each interior point's X lies within its retained bracketing segment.

Existing equal-length, boundary, and rolling-window compatibility remains
unchanged. Mixed interior replacement, retained-identity reordering,
ambiguous identity, and interpolation-mode changes use the existing reveal or
immediate fallback.

## Geometry contract

`PathSeriesTransition` continues to produce the only rendered series.

### Interior insertion

For every entering target point, sample the phase-start path at the entering
point's target X using the series' configured linear, stepped, Bezier, or
monotone interpolation. The entering point starts at that sampled coordinate
and interpolates to its target coordinate. Retained points interpolate normally.

The temporary frame follows target order. Every entering and retained point
maps to its canonical target index.

### Interior removal

For every exiting source point, sample the target path at the exiting point's
source X. The exiting point interpolates to that sampled coordinate and remains
visual-only until completion. Retained points interpolate normally.

The temporary frame follows source order. Exiting points map to null; retained
points map to their canonical target indices. At progress one, the exact target
series and identity map replace the temporary frame.

### Interpolation and interruption

Sampling uses the same `InterpolationGeometry` math as rendering and tracking.
When an active transition is interrupted, the currently rendered geometry is
the next phase's source. Compatibility is re-evaluated against the newest
canonical target, and the newest Sprint 8 timing configuration owns the new
window.

## Runtime and identity

- Bounds always come from canonical target series before motion starts.
- Workbench rows, callbacks, controller lookup, and artifacts expose target
  indices and data throughout the transition.
- Exiting interior geometry paints but cannot hover, hit, focus, select, or
  appear in callbacks.
- Retained durable focus and selection remap by stable identity; removed state
  is cleared.
- Reduced motion, zero theme duration, or zero series duration renders the
  target synchronously and ignores delay.
- Controller-fed streaming tails retain their dedicated animation and do not
  enter snapshot topology planning.

## Showcase

The existing Line and Area Motion presets gain one outlined 48 px action:

- **Add backfill** inserts one stable sample between retained interior points.
- The same action becomes **Remove backfill** while that sample exists.

This toggle keeps the already dense action group bounded. It uses the existing
8 px wrap spacing and does not add a new panel, color, or primary action. Data,
Split, copied rows, and exported CSV continue to show canonical target data.

## Verification

### Pure transition

- Linear, stepped, Bezier, and monotone path sampling.
- Single and multiple insertion-only and removal-only gaps.
- Start, midpoint, completion, render-to-target map, and source-to-target map.
- Boundary behavior remains unchanged.
- Mixed interior replacement, unbracketed edits, invalid X order, reordering,
  type changes, and interpolation changes remain incompatible.

### Real render path

- Line insertion and Area removal through `SeriesElement`.
- Markers, labels, fill, stroke, tracking, and hit testing share one geometry.
- Exits are visual-only; retained and entering canonical lookup stays aligned.
- Focus, selection, workbench linkage, target bounds, artifact extraction,
  interruption, reduced motion, and per-series delay remain correct.

### Product and release

- Wide and compact Motion preset coverage for Add/Remove backfill.
- Package and showcase analyzers and complete test suites.
- Touched-file formatting and `git diff --check`.
- Dartdoc and pub.dev dry run with zero warnings/errors.
- Deployment-base and root release builds plus direct Line/Area browser review.
- Keep the dependent branch local until Sprint 8 merges and local review passes.

## Explicit exclusions

- Mixed interior insert-and-remove snapshots or arbitrary identity reorder.
- Cross-fading two independent series or adding a detached painter.
- Per-point delays, per-series curves, spring motion, or event callbacks.
- Axis interpolation, interpolation-mode morphing, or persistence of progress.
- Other chart families and streaming-tail changes.
