# Line and Area Topology Motion 1.1

**Status:** Complete
**Branch:** `feature/line-area-topology-motion`
**Parent delivery:** Line and Area Product Parity, PR #35 (merged)

## Goal

Extend the existing opt-in Line and Area data-update motion to common snapshot
changes where points enter or leave at a series boundary. The chart must keep
stroke, fill, markers, labels, tracking, and hit testing on one animated
geometry while preserving stable target bounds.

## Supported topology changes

- Append one or more points at either boundary.
- Remove one or more points from either boundary.
- Roll a window by removing points from one boundary and appending points at
  the other in the same snapshot.
- Continue to interpolate equal-length value updates.

Retained points match by timestamp first, then by the existing `x + label`
identity. Equal-length ordered updates may continue to use index identity when
no stable identity is available. Topology changes require at least one stable
retained point and preserve the order of all retained identities.

Interior insertion/removal, arbitrary reordering, series-type changes, and
interpolation-mode morphing remain incompatible and use the existing reveal or
immediate fallback.

## Geometry contract

The normal Line/Area renderer remains the only rendering path.

- Retained points interpolate from their matched source coordinates to their
  target coordinates.
- Entering boundary points begin collapsed at the nearest retained boundary
  and grow toward their target coordinates.
- Exiting boundary points remain in the temporary in-flight series and collapse
  into the nearest retained boundary.
- At completion, exiting points are coincident with the retained boundary and
  are then removed by returning the exact target series.

A rolling window therefore temporarily contains the shrinking old boundary,
all retained target points, and the emerging new boundary. Since every visual
and interaction layer consumes this same series, there is no detached marker,
label, fill, tracking, or hit-test animation.

## Runtime boundaries

- Bounds are calculated from the target data before the transition begins and
  stay fixed for its duration.
- Reduced motion and zero-duration themes render the target immediately.
- Controller-fed streaming tails keep their dedicated incoming-point animation;
  snapshot topology motion is only detected from widget series updates.
- A new snapshot interrupts from the currently rendered geometry, matching the
  existing data-update behavior.

## Showcase

The Line and Area Motion presets add a compact action group:

- **Update values** — existing equal-length interpolation.
- **Add point** — append a stable new point.
- **Remove point** — remove the current tail.
- **Roll window** — remove the head and append a new tail in one update.

Controls use the showcase's existing spacing, button treatment, and 48 px
minimum target. Actions are disabled when their operation is unavailable.

## Verification

- Pure transition tests for append, removal, rolling, identity order, and
  incompatible interior/reordered changes.
- Widget render-path tests for Line and Area mid-frame geometry and final
  targets, plus stable multi-axis bounds and reduced motion.
- Regression proof that controller-fed tails do not double animate.
- Showcase interaction and compact-viewport tests.
- Package/showcase analyze and test gates, release web build, direct-route
  browser review, and artifact/publication checks before PR promotion.
