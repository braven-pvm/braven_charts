# Line and Area Product Parity — Design Spec

**Status:** Sprints 1-7 complete; PRs #35 and #37 merged
**Original lane:** `feature/line-area-product-parity`
**Next review gate:** Sprint 8 per-series motion timing

See the [sprint roadmap](../plans/2026-07-18-line-area-product-parity-roadmap.md)
for the completed delivery record and next proposed slice.

## Goal

Bring the flagship Line and Area surfaces to the product standard established by Bar, Pie, and Donut without weakening their existing strengths: interpolation, multi-axis normalization, annotations, streaming, tracking, linked selection, and artifact extraction.

The first complete slice adds deliberate path motion and moves both showcase pages onto the shared resizable chart/data workbench. It must be useful as a public package example, not only as a demo.

## Product principles

- The chart remains the primary surface. Data and controls support inspection rather than competing with it.
- Motion explains continuity. It must never change the meaning of the data or hide an incompatible update behind an arbitrary morph.
- Paint, hit-testing, linked points, tooltips, and crosshairs use the same in-flight geometry.
- Extracted documents and workbench tables always expose canonical target data, never transient animation frames.
- Target axis bounds are established before motion begins and remain stable during the transition.
- Reduced-motion preferences and zero-duration themes render the final frame immediately.
- Existing Line and Area charts remain static unless motion is explicitly configured.

## Public API

Line and Area share one path-oriented animation contract:

```dart
enum PathEntranceAnimationMode { none, reveal }
enum PathDataUpdateAnimationMode { none, interpolate }

@immutable
class PathAnimationStyle {
  const PathAnimationStyle({
    this.entranceMode = PathEntranceAnimationMode.none,
    this.dataUpdateMode = PathDataUpdateAnimationMode.none,
  });

  final PathEntranceAnimationMode entranceMode;
  final PathDataUpdateAnimationMode dataUpdateMode;
}
```

`LineChartSeries` and `AreaChartSeries` gain `pathAnimation`, defaulting to `const PathAnimationStyle()`. The default is intentionally additive and backwards compatible because Line and Area are used for large and streaming datasets.

`BravenChartController.replaySeriesEntrance()` replays the configured entrance animation for Line, Area, Pie, or Donut. `replayRadialEntrance()` remains supported.

Animation timing comes from `ChartTheme.animationTheme.dataUpdateDuration` and `dataUpdateCurve`, matching Bar and radial charts.

## Motion semantics

### Entrance

- `reveal` clips each participating Line or Area series from the plot's leading edge to its trailing edge.
- Area fill, stroke, glow, markers, point labels, inline labels, and linked-point decoration reveal together.
- The clip is based on plot width, so every interpolation mode keeps its exact rendering geometry.
- Series with `none` render their final frame immediately beside animated series.
- Cartesian annotations remain visible and stable. They are explanatory context, not part of the series geometry.

### Compatible data updates

Updates interpolate canonical `ChartDataPoint.x` and `y` values when all of these are true:

- previous and next series have the same ID and runtime type;
- both are Line or both are Area;
- interpolation mode is unchanged;
- point count is unchanged;
- each point can be matched by timestamp, then `x + label`, with index fallback only for equal-length ordered data.

Presentation comes from the target series. Point metadata, labels, segment style, and point style switch to their target value while geometry interpolates.

### Incompatible updates

Stable-identity points may enter or leave at a series boundary, including a
rolling-window update. Interior topology edits, arbitrary reordering, series
type changes, and interpolation-mode changes do not morph. An incompatible
target uses its configured entrance reveal, or renders immediately when reveal
is disabled. Streaming single-tail updates retain the existing incoming-point
animation and do not double animate.

## Rendering architecture

1. Resolve canonical target series as today.
2. Build in-flight Line/Area series through a pure `PathSeriesTransition` utility.
3. Pass per-series reveal progress through `DataConverter` into `SeriesElement`.
4. Clip only the affected `SeriesElement` paint scope.
5. Restrict bounds, series hit-testing, point hits, and linked-point painting to the revealed portion.
6. Rebuild through the existing element-generator version so cached chart layers receive each frame.

This mirrors the Bar architecture: animation feeds the normal renderer rather than painting a detached visual overlay.

## Showcase surface

Line and Area keep their dedicated narratives but share the established workbench behavior:

- chart, data, and split modes;
- resizable split with keyboard, pointer, double-click reset, and compact fallback;
- chart remains mounted while modes change;
- responsive table sizing and linked row/chart focus;
- a focused Motion preset for each family with `Replay entrance` and `Update data` actions;
- controls grouped by purpose with 8-point spacing and 48-point action targets;
- direct routes `?page=line-charts` and `?page=area-charts` remain stable.

The workbench uses the package component and existing showcase tokens. It does not introduce a second selector or one-off resize implementation.

## Acceptance criteria

### Core

- Line and Area reveal correctly for linear, bezier, monotone, and stepped interpolation.
- Area fill and outline share one reveal edge.
- Compatible data updates interpolate through the normal render and hit-test path.
- Incompatible changes do not interpolate.
- Replay is available through `BravenChartController`.
- Reduced motion and zero duration render final state synchronously.
- Existing streaming-tail behavior does not double animate.
- Multi-axis target bounds stay stable throughout motion.
- Artifact extraction returns target series while an animation is active.

### Showcase/workbench

- Line and Area pages expose chart/data/split modes and a resizable split.
- Wide and compact layouts remain usable with no overlap or clipped actions.
- Motion examples can replay entrance and trigger a real data update.
- Resize handle and motion actions meet the existing 48-point interaction contract.
- Direct routes load in a release web build.

### Verification

- Model and transition unit tests.
- Real widget render-path tests at start, mid, and final frames.
- Reduced-motion and controller replay tests.
- Workbench page tests at wide and compact widths.
- `flutter analyze`, package tests, example tests, `git diff --check`.
- `flutter build web --release` and live browser review of both direct routes.

## Deliberate deferrals

- Axis-domain interpolation. Stable target bounds are less distracting and avoid normalization ambiguity.
- Scatter entrance/update motion.
- Per-series delay and duration move into proposed Sprint 8; automatic
  order-derived staggering and per-series curves remain deferred.
- Animation-progress persistence in chart artifacts.
- Morphing interior point insertion/removal, arbitrary reordering, or
  interpolation-mode changes.

