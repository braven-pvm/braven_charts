# Line and Area Motion Identity Continuity

**Status:** Complete
**Branch:** `feature/line-area-topology-motion`
**Parent delivery:** Path Motion 1.1 topology updates, commit `451320b7`

## Problem

A topology frame may contain more rendered points than the canonical target.
For example, a forward rolling window renders `[exiting A, retained B,
retained C, entering D]` while the accepted data snapshot is `[B, C, D]`.
Raw render indices therefore cannot be exposed as point identities: render
index 1 is canonical B at target index 0, while exiting A has no target index.

## Contract

- Every topology frame carries an internal render-index to canonical
  target-index map.
- Retained and entering geometry maps to its target point index.
- Exiting geometry has no canonical point index and is never hoverable,
  hittable, selectable, focusable, or exposed through callbacks/artifacts.
- Point lookup by canonical index resolves the current rendered geometry, so
  tooltips, crosshairs, linked markers, and accessibility stay attached to the
  accepted datum while it moves.
- Existing Line/Area focus and durable selection remap by timestamp first,
  then `x + label`, across a compatible canonical snapshot change. State is
  removed when its identity exits. Equal-length ordered value updates retain
  index identity as before.
- A rapid compatible snapshot interrupts from current rendered geometry and
  rebinds all interaction identity to the newest canonical target.
- At completion the renderer returns the exact target series and an identity
  point map.

## Boundaries

- The mapping is private runtime state. No public model, artifact schema, or
  `ChartDataPoint.metadata` field is added.
- Controller-fed streaming tails keep their existing dedicated path.
- Temporary exiting points may continue to paint their path, marker, and label
  while collapsing; only interaction is suppressed.
- Persisting state for an identity that has left the target, or keyboard
  traversal of temporary exit geometry, is out of scope.

## Verification

- Pure transition tests prove forward/reverse rolling maps, completed identity
  maps, and source-to-target stable identity remapping.
- Renderer tests prove canonical point lookup, non-interactive exiting
  geometry, hover/linked-state alignment, and selection/focus continuity.
- A rapid-update test proves interruption continuity and final canonical state.
- Existing topology, streaming, artifact, package, showcase, analyzer, docs,
  release-build, and direct-route gates remain green before review.
