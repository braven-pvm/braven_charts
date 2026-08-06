# Bar chart enhancements v2

**Register:** BC-0057  
**Status:** In progress  
**Branch:** `feature/BC-0057-bar-chart-enhancements-v2`

## Objective

Extend the existing Cartesian bar family with three related capabilities:

1. rotated value labels that remain collision-, contrast-, and container-aware;
2. hierarchical drill-down with visible breadcrumb navigation and portable data;
3. animated bar-race playback with stable category identity and deterministic controls.

The work must preserve the existing bar geometry, selection, tracking, axes,
artifacts, generated Dart, Fluent API, Typed Chart Grammar, Workbench, reduced
motion, and performance contracts. Existing configurations must render exactly
as before.

## Evidence and baseline

- Category-axis labels already support rotation through
  `XAxisConfig.tickLabelRotationDegrees` and
  `CategoryAxisConfig.labelRotationDegrees`; this plan adds rotation to labels
  attached to bars, not another axis-label implementation.
- `BarLabelStyle` already owns value content, placement, collision handling,
  backgrounds, borders, callouts, stack totals, and runtime formatting.
- Ordinary bar labels are currently measured and collided as horizontal
  rectangles. Range-end labels contain a separate narrow-bar 90-degree
  fallback; that special case must converge on the shared transformed-label
  geometry rather than remain a second implementation.
- Bar updates already interpolate canonical `BarChartSeries` geometry by stable
  series ID and X value. Race playback should extend that identity model rather
  than paint an unrelated animation layer.
- No portable Cartesian hierarchy or breadcrumb contract currently exists.
- The supplied reference race is a 12.6-second population ranking animation
  with play/pause/seek, smooth rank changes, live values, a period label, and a
  total.

## Non-goals

- A generic dashboard navigation framework.
- Arbitrary widgets painted inside `ChartRenderBox`.
- Silent serialization of callbacks or lazy loaders.
- Replacing axis category rotation.
- Rebuilding every chart element or spatial index on every race tick.
- Implicitly drilling on every ordinary selection tap.

## Cross-surface portability contract

Every serializable property introduced here must be represented in:

- public model constructors, `copyWith`, equality, hash code, and documentation;
- artifact encode/decode and round-trip tests;
- generated Fluent modifiers and smoke tests;
- AI surface definitions and config parsing;
- Typed Chart Grammar lowering or an explicit unsupported diagnostic;
- generated Config Dart/source capture;
- Workbench Data, Split, and Source modes;
- public guides and showcase examples.

Runtime callbacks such as lazy drill resolvers use explicit runtime binding
descriptors. Missing optional bindings disable the feature with a visible
diagnostic; required bindings fail hydration rather than silently changing the
chart.

## 1. Rotated bar value labels

### Public model

Add to `BarLabelStyle`:

```dart
enum BarLabelRotationMode {
  fixed,
  autoFit,
}

final BarLabelRotationMode rotationMode;
final double rotationDegrees;
```

Defaults are `fixed` and `0`, preserving all existing output. Positive degrees
rotate clockwise in screen coordinates. `rotationDegrees` is normalized for
layout but preserved as authored for round-trip fidelity.

`autoFit` chooses between the authored angle and a perpendicular alternative
when the preferred orientation cannot fit the bar/category slot. It does not
rotate merely because labels overlap; collision policy remains responsible for
overlap.

### Shared geometry

Introduce one internal transformed-label geometry result containing:

- the unrotated text/container size;
- the transformed axis-aligned bounds used by collision and viewport clipping;
- the pivot and paint transform;
- the text/container local rect;
- the resolved visual angle.

The same result drives fit checks, candidate placement, collision reservation,
callout attachment, background/border painting, contrast sampling, and text
painting. The background rotates with the label. Callouts remain in chart
coordinates and terminate at the transformed bounds.

Range endpoint labels consume this shared path. Horizontal bar labels and
stack totals follow the same rules. Auto contrast is based on the label
container when present and otherwise the underlying bar only when the
transformed label centre lies inside it.

### Workbench

The Labels section exposes:

- rotation mode: Fixed / Auto fit;
- angle slider plus numeric readout, `-180` to `180` degrees;
- quick actions: Horizontal, Vertical clockwise, Vertical counter-clockwise;
- concise on-demand help clarifying that category-axis rotation is separate.

The showcase includes dense vertical city labels, horizontal bars, outside
labels, inside labels with backgrounds, negative bars, stack totals, and an
auto-fit stress example.

## 2. Hierarchical drill-down

### Portable data

```dart
@chartSurface
class BarDrillNode {
  const BarDrillNode({
    required this.id,
    required this.label,
    required this.series,
    this.children = const [],
    this.metadata = const {},
  });
}

@chartSurface
class BarDrilldownConfig {
  const BarDrilldownConfig({
    required this.root,
    this.activation = BarDrillActivation.primaryAction,
    this.transition = BarDrillTransition.fadeThrough,
    this.showBreadcrumbs = true,
  });
}
```

Node IDs are unique within one hierarchy and remain stable across reorder.
Static child nodes are portable. A runtime-only lazy resolver may return child
nodes for a selected node; artifacts store only its binding descriptor.

The hierarchy changes the effective bar series/document. It does not mutate
source data or hide selection state in renderer-only fields.

### Controller and state

`BarDrilldownController` exposes current path and immutable state plus:

- `drillTo(nodeId)`;
- `up()`;
- `navigateToAncestor(nodeId)`;
- `root()`;
- `retry()` for a failed lazy load.

State distinguishes idle, loading, ready, empty, and error. Async resolver
responses carry a request generation so stale responses cannot replace a newer
navigation. Selection is cleared or remapped by stable identity according to
an explicit policy; drill activation must not masquerade as ordinary point
selection.

### Breadcrumb chrome

Breadcrumbs are Flutter widget chrome above the plot, not canvas-painted UI.
They:

- show a back affordance and the complete current path;
- collapse middle ancestors on narrow widths;
- expose semantic buttons, keyboard focus, Enter/Space activation, and at least
  48 logical-pixel touch targets;
- preserve title/subtitle alignment and existing chart theme tokens;
- show inline loading, empty, and retry states without replacing the entire
  page.

The chart announces the new level to assistive technologies after navigation.

### Workbench and showcase

A dedicated Drill-down preset includes a three-level nutrition example and a
business-region example. Options cover activation, breadcrumb visibility,
transition, selection policy, lazy-load simulation, delay, and failure. Data
and Source represent the current effective level while retaining a clear root
hierarchy summary.

## 3. Bar race

### Portable frame model

```dart
@chartSurface
class BarRaceFrame {
  const BarRaceFrame({
    required this.id,
    required this.label,
    required this.values,
    this.timestamp,
    this.total,
  });
}

@chartSurface
class BarRaceConfig {
  const BarRaceConfig({
    required this.frames,
    this.topCount = 10,
    this.durationPerFrame = const Duration(milliseconds: 800),
    this.axisRange = BarRaceAxisRange.dynamic,
    this.sort = BarRaceSort.descending,
    this.loop = false,
    this.showPeriod = true,
    this.showTotal = false,
    this.periodStyle = const BarRacePeriodStyle(),
    this.periodFormat = const BarRacePeriodFormat(),
    this.valueFormat = const BarRaceValueFormat(),
    this.totalFormat = const BarRaceValueFormat(),
  });
}
```

Frame value identity is category ID, never row index. Categories entering or
leaving the top set retain their identity through the transition. Frame IDs are
stable and unique.

### Playback controller

`BarRaceController` owns play state and exposes:

- play, pause, toggle;
- seek to frame or normalized progress;
- previous/next frame;
- playback speed and looping;
- current frame, progress, and effective values as listenable state.

The controller never depends on a `Timer.periodic` for visual interpolation.
Animation uses Flutter's frame clock and pauses when the widget is not active.
Reduced-motion mode resolves each requested frame immediately while controls
remain functional.

The frame label is the generic temporal fallback. Calendar frames may attach a
timestamp and use a portable token pattern for full/abbreviated month, year,
day, ISO-like, or mixed authored/date labels. A reusable
`BarRacePeriodIndicator` renders it prominently over the chart using portable
`BarRacePeriodStyle` placement, type, colour, opacity, and inset controls.
Portable value descriptors independently format the counting bar values and
aggregate total with patterns, notation, decimal precision, grouping,
trailing-zero policy, and scaling.

### Transition and layout

Race rendering uses horizontal bars by default. A race frame interpolates:

- value extent;
- category/rank position;
- opacity for top-N entry and exit;
- value label content/position;
- dynamic axis maximum where configured.

The data and dynamic-axis transitions consume the complete frame duration and
use linear progress. This prevents per-frame easing and idle tails from making
continuous source data appear to arrive in batches.

The current effective geometry remains the source of hit testing, tracking,
selection, semantics, and labels. Hover/selection follow category identity
during reorder. The dynamic axis advances through cached monotonic
human-readable ceilings so small leader changes do not rescale every bar on
every frame. Ceiling changes interpolate on the race frame clock; fixed mode
uses the global ceiling precomputed across all frames. A separate continuous
policy retains the initial readable ceiling until the leader consumes 90% of
it, then follows the running leader monotonically on that same clock. This
matches fill-responsive race references without reintroducing contraction or
one-frame ceiling jumps.

Category-slot thickness is resolved from an explicit stable data-space slot
spacing during a keyed reorder. It must never be inferred from the temporary
minimum gap between interpolating ranks: two categories necessarily share the
same fractional position at the midpoint of an overtake, and treating that
crossing as the slot width collapses the entire race to one-pixel rows.

The showcase race uses a multi-decade monthly population timeline with regular
top-N entries and overtakes. Monthly values interpolate annual source anchors,
and the period indicator advances through labels such as `January 1965` and
`February 1965`. Category identity remains visually attached to its bar through
the crossing; the example is not considered representative if the ranking
barely changes during normal playback.

Prominent totals interpolate between adjacent frame totals. The month/year
label remains the discrete temporal landmark while the bars, numeric labels,
aggregate, ranks, and continuous axis all move throughout the frame.

Race updates use a bounded keyed frame cache and a specialized interpolation
path. They must not regenerate unrelated elements, annotations, or indexes on
every tick.

### Playback chrome and Workbench

Controls are widget chrome below or above the chart:

- Play/Pause, Previous, Next;
- accessible seek slider with current period;
- speed selector and loop toggle;
- large optional period and total overlays that never intercept chart input.

Mobile controls use 48-pixel targets and collapse secondary actions into a
menu. The Race preset offers country population, product adoption, and compact
mobile examples plus controls for top-N, cadence, axis policy, sort order,
labels, period and value patterns, notation, precision, grouping, scaling,
total, loop, colors, and transition timing.

## Delivery slices

### Slice A — transformed labels

1. Add failing model, codec, source, and renderer tests.
2. Add rotation model and generated surfaces.
3. Replace ordinary/range label placement with shared transformed geometry.
4. Wire Workbench options and examples.
5. Update guide and performance coverage.

### Slice B — portable hierarchy

1. Add hierarchy/config/controller models and validation.
2. Add static artifact/source/grammar support and runtime binding diagnostics.
3. Add breadcrumb/loading/error/empty chrome.
4. Connect activation, selection, keyboard, touch, and effective documents.
5. Add drill-down presets and integration tests.

### Slice C — race timeline

1. Add frame/config/controller models and validation.
2. Add pure identity/rank/value interpolation tests.
3. Integrate a bounded race transition into canonical bar geometry.
4. Add playback chrome, reduced motion, lifecycle handling, and semantics.
5. Add race presets, artifact/source coverage, benchmarks, and docs.

### Slice D — adversarial release pass

Test combinations across grouped, stacked, normalized, diverging, range,
waterfall, horizontal, negative, multi-axis, dense, selection, tracking,
annotations, zoom/pan, light/dark/high-contrast, RTL, keyboard, touch, and
reduced-motion configurations. Reconcile every accepted deferral in BC-0057.

## Verification gates

- `dart run build_runner build`
- `dart format --output=none --set-exit-if-changed lib test example`
- `flutter analyze lib`
- focused package model/codec/source/renderer/widget tests
- focused Workbench widget tests
- complete package tests and example tests
- release web build of the showcase
- direct-route manual review at desktop, tablet, and phone widths
- semantics/keyboard review and reduced-motion review
- bar geometry and race benchmarks in isolation and in the full suite

Performance targets remain the repository defaults: layout under 5 ms, full
paint under 17 ms, interaction paint under 1 ms, and no continuous allocation
or element regeneration in the race hot path.

## Acceptance mapping

- Rotated labels are configurable, portable, collision-correct, and visually
  testable without changing axis rotation behavior.
- Drill-down supports multiple levels, back/breadcrumb navigation, static and
  lazy data, loading/error/empty states, touch, keyboard, and source fidelity.
- Bar race supports stable smooth reordering, play/pause/seek/step/speed/loop,
  top-N and axis policies, period/total presentation, reduced motion, and
  performant canonical interaction.
- All controls are discoverable in the Bar showcase with searchable help and
  representative examples.
- Existing bar behavior and artifacts remain backward compatible.
