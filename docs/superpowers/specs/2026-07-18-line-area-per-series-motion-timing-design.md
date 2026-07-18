# Line and Area Per-Series Motion Timing

**Status:** Review needed
**Roadmap:** Sprint 8 of Line and Area Product Parity
**Proposed implementation lane:** `feature/line-area-motion-orchestration`
**Prerequisite:** PR #37 merged

## Goal

Let package consumers sequence multi-series Line and Area motion without
changing the meaning of the chart or introducing a second rendering path.
Timing remains explicit, deterministic, opt-in, and local to each series.

Existing charts must behave exactly as they do today. A series with no timing
override starts immediately and inherits
`ChartTheme.animationTheme.dataUpdateDuration` and `dataUpdateCurve`.

## Product principles

- Timing explains series order or dependency; it is not decorative noise.
- Series identity, not list or paint order, owns timing configuration.
- A delayed series always has valid geometry and canonical target identity.
- One orchestration clock drives a phase. The runtime does not create a timer
  or animation controller per series.
- The chart theme remains the global motion authority. Reduced motion and a
  zero-duration theme always win over series overrides.
- Exported documents persist configuration and canonical target data, never an
  in-flight frame or elapsed animation progress.

## Public API proposal

Add one immutable timing value object and two timing fields to the existing
path animation style:

```dart
@immutable
class PathAnimationTiming {
  const PathAnimationTiming({
    this.delay = Duration.zero,
    this.duration,
  }) : assert(!delay.isNegative),
       assert(duration == null || !duration!.isNegative);

  final Duration delay;

  /// Null inherits `ChartTheme.animationTheme.dataUpdateDuration`.
  final Duration? duration;
}

@immutable
class PathAnimationStyle {
  const PathAnimationStyle({
    this.entranceMode = PathEntranceAnimationMode.none,
    this.dataUpdateMode = PathDataUpdateAnimationMode.none,
    this.entranceTiming = const PathAnimationTiming(),
    this.dataUpdateTiming = const PathAnimationTiming(),
  });

  final PathEntranceAnimationMode entranceMode;
  final PathDataUpdateAnimationMode dataUpdateMode;
  final PathAnimationTiming entranceTiming;
  final PathAnimationTiming dataUpdateTiming;
}
```

`copyWith`, equality, hash code, diagnostics, Line/Area series equality, and
public documentation include both timing values. No timing field is added to
Bar or radial styles in this sprint.

### Validation and defaults

- Delay must be non-negative.
- An explicit duration must be non-negative.
- `duration == null` inherits the theme data-update duration.
- Default timing has zero delay and inherited duration, reproducing current
  simultaneous motion.
- An explicit zero duration renders the series target immediately and ignores
  its delay.
- A zero theme data-update duration disables all path motion, including a
  non-zero series override. This preserves the existing theme-level kill
  switch.
- Reduced motion ignores all delays and durations and renders every target
  synchronously.

## Runtime model

Entrance reveal and compatible data updates retain their existing independent
animation controllers. Each active phase resolves a timing window per series:

```text
series start = delay
series end   = delay + resolved duration
phase end    = max(series end)
```

The phase controller runs linearly from zero to `phase end`. On each frame the
runtime converts controller progress to elapsed time, resolves local progress
for every participating series, clamps it to `0...1`, and applies the existing
theme data-update curve to that local value.

This replaces the current single shared progress value with a map keyed by
series ID. It does not replace `PathSeriesTransition`, `SeriesElement`, or the
normal Line/Area painter.

### Entrance semantics

- Before its window begins, a delayed reveal has progress zero and exposes no
  revealed hit region.
- During its window, fill, stroke, glow, markers, labels, linked decoration,
  and hit testing share the same local reveal edge.
- After its window, the series remains fully revealed while later series
  continue.
- `replaySeriesEntrance()` restarts the complete explicit sequence from zero.

### Data-update semantics

- Before its window begins, a delayed transition remains on its valid
  phase-start geometry while lookup, selection, callbacks, workbench rows, and
  artifacts retain canonical target identity and data.
- During its window, the existing compatible value/topology transition uses
  local series progress.
- After its window, the renderer returns the exact target series even while
  another series remains in flight.
- A series with no compatible transition renders its normal reveal or immediate
  fallback independently; it does not extend the update phase timeline.

### Interruption and configuration changes

- A new compatible snapshot interrupts from each series' currently rendered
  geometry, including progress zero for a still-delayed series.
- The new target's timing configuration defines the restarted phase.
- Timing-only widget changes do not replay entrance or fabricate a data update.
- Disabling animations while a phase is active clears orchestration state and
  publishes exact targets synchronously.
- Controller-fed streaming tails retain their dedicated incoming-point path and
  do not participate in snapshot timing orchestration.

## Bounds, interaction, and artifacts

- All Cartesian and multi-axis bounds are calculated from canonical target data
  before the phase starts and remain fixed until it completes.
- Temporary exiting topology geometry stays visual-only and non-interactive.
- Durable focus and selection continue to remap by stable identity.
- Annotations remain static context and are not staggered.
- Chart documents store target series and the two timing configurations.
- Existing documents without timing fields decode to `PathAnimationTiming()`.
- A document with non-default timing declares
  `series.path-motion-timing.v1` in addition to the existing path-motion
  capability. Animation progress and wall-clock state remain excluded.

## Showcase contract

The existing Line and Area Motion presets remain the only showcase surfaces for
this feature.

- Line uses a restrained three-series sequence with explicit stable IDs and
  delays of `0 ms`, `80 ms`, and `160 ms`.
- Area uses two readable layers with delays of `0 ms` and `120 ms`; opacity and
  ordering must keep both shapes legible.
- The Motion control group exposes a compact series-stagger control that updates
  explicit timing values in the sample. It does not imply automatic library
  ordering.
- Replay entrance, update values, add/remove point, and roll window continue to
  exercise the real chart/controller path.
- The chart remains the dominant surface in Chart and Split modes. Compact mode
  keeps actions reachable with no clipped labels or horizontal page overflow.

## Verification

### Model and resolver

- Default, explicit, zero, invalid, copy, equality, and diagnostic behavior.
- Timing-window resolution for simultaneous, staggered, mixed-duration, and
  zero-duration series.
- Local progress before, within, between, and after windows with the theme curve
  applied once per series.

### Real render path

- Line and Area entrance frames prove delayed, active, and completed series use
  the standard painter and exact local progress.
- Compatible value updates and boundary topology updates prove independent
  series windows and exact final targets.
- Rapid interruption proves continuity from current geometry and adoption of
  the newest timing configuration.
- Reduced motion, zero theme duration, and zero series duration prove immediate
  targets with no delayed callback.
- Multi-axis target bounds, annotations, point maps, hit testing, focus,
  selection, linked markers, callbacks, and artifact extraction remain stable.
- Controller entrance replay follows the full sequence; streaming tails remain
  excluded.

### Artifact and public surface

- Old path-motion documents decode to inherited timing defaults.
- Non-default timing round trips for Line and Area and emits the timing
  capability.
- Public API reference, Line/Area guide, feature matrix, and examples describe
  inherited versus explicit timing and reduced-motion precedence.

### Product and release gate

- Wide and compact widget coverage for both Motion presets.
- Package and showcase analyzers and complete test suites.
- Touched-file format and `git diff --check`.
- Dartdoc with zero warnings/errors and pub.dev dry run with zero warnings.
- Deployment-base and root-path release web builds.
- Direct-route browser review of Line and Area sequencing, updates, topology
  actions, resizing, linked selection, reduced motion, and console output.
- Keep the branch local for joint review; open a PR only after user approval.

## Explicit exclusions

- Automatic delay calculation from series index, legend order, z-order, or data
  volume.
- Per-series curves, spring configuration, repeat, reverse, autoplay loops, or
  chained event callbacks.
- Axis-domain interpolation or animated normalization bounds.
- Interior point insertion/removal, arbitrary identity reordering, or
  interpolation-mode morphing.
- Scatter, Bar, Pie, Donut, or polar-family timing changes.
- Persistence or restoration of in-flight progress.
