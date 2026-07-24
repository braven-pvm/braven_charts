# Mobile Interaction Phase 3: Bounded pan inertia

## Status — complete

Phase 3 shipped in
[PR #103](https://github.com/braven-pvm/braven_charts/pull/103) at merge commit
`fee0d936`. Package-quality CI passed and the release-mode LAN build was
accepted on a physical phone. The implementation adds opt-in, velocity-aware
touch pan inertia without creating a second viewport or animation system.

## Outcome

Users may release a moving touch pan and allow the existing Cartesian viewport
to coast briefly before settling. A new touch, a disabled interaction gate, or
the configured stop threshold cancels the motion deterministically.

## Interaction contract

- Pan inertia is opt-in and disabled by default.
- It remains subordinate to the chart, pan, and touch interaction gates.
- Both Browse two-finger pans and Explore one-finger pans may supply release
  velocity.
- Release velocity is capped before it reaches the viewport.
- Velocity decays exponentially and stops below a package-owned threshold or
  after two seconds.
- A new touch stops inertia immediately and finalizes the current viewport.
- Geometry and hit indexes rebuild once when the inertial interaction settles.
- Streaming remains paused until inertia settles or is cancelled.
- Pinch and selection arbitration retain their phase-1 behavior.

## Public configuration

`TouchInteractionConfig` adds:

- `enablePanInertia`
- `panInertiaDeceleration`
- `maximumPanInertiaVelocity`

The configuration is carried by artifacts, generated Dart source, fluent
modifiers, and the AI surface schema.

## Showcase

The mobile interaction page enables inertia for testing and exposes:

- an on/off toggle;
- a deceleration slider;
- the existing Browse/Explore profile selector and viewport counters.

## Verification

- Recognizer release-velocity coverage.
- Widget coverage for coasting, deterministic cancellation, settling, and
  parent-scroll isolation.
- Artifact, source-generation, fluent, model, and schema coverage.
- Existing mobile interaction, selection, and cross-family regression suites.
- Scoped analysis, showcase tests, and release web build.
- Physical-phone review through the release-mode LAN server.

## Later phase candidates

These remain intentionally deferred and are owned outside this completed
phase:

- Mobile annotation editing and touch-sized resize handles: shared-register
  item `BC-0002`.
- Explicit accessibility actions for viewport and selection controls:
  shared-register item `BC-0001`.
- Android/iOS native packaging and device-lab verification: shared-register
  item `BC-0003`.
