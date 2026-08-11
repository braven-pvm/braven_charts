# Line race chart implementation plan

Register: `BC-0059`

## Outcome

Add a first-class line-race timeline to the existing Cartesian line family.
Unlike a bar race, identities do not continuously reorder into ranked rows.
Each stable series progressively reveals observations along one fixed X domain,
while its current frontier marker and direct label travel with the latest
visible value.

The reference behavior is the supplied "F1 2012 Top Ten Drivers" recording:

- the complete round axis is visible from the first frame;
- play, pause, step, seek, speed, and loop all operate on one deterministic
  timeline;
- line values interpolate continuously between authored observations;
- every driver keeps a stable color and identity;
- endpoint labels follow the same interpolated frontier as the line;
- the ordinary chart legend remains available independently of direct labels.

## Architecture boundaries

### Reuse

- Reuse the deterministic playback contract proven by `BarRaceController` and
  `BarRaceTicker`: one controller clock, normalized seek, speed scaling,
  lifecycle pause, reduced-motion behavior, and no timer-owned UI state.
- Render ordinary `LineChartSeries` through `BravenChartPlus`; line race is a
  data/timeline capability, not a second line renderer.
- Use `SeriesCalloutConfig(anchor: SeriesCalloutAnchor.lastVisible)` for moving
  endpoint labels. This keeps collision resolution, connector styling, source
  extraction, artifacts, and generated Dart on the shared callout system.
- Keep the existing chart legend. Direct endpoint labels must not create a
  parallel legend implementation.

### Do not reuse

- Do not use bar-race rank interpolation, top-N membership, or dynamic category
  axes. A line race has no rank lane.
- Do not drive playback through `PathAnimationStyle.reveal`; that is a mounted
  entrance animation and would introduce a second clock.
- Do not mutate caller-owned source series or fabricate observations across
  gaps and late-entry boundaries.

## Public model

Introduce:

- `LineRaceSeries`: stable id, display name, and color used to build ordinary
  line series.
- `LineRaceFrame`: stable id/label, numeric X coordinate, and sparse values by
  series id. Missing values remain missing.
- `LineRaceConfig`: series, ordered frames, frame duration, and loop. Standard
  line-series and callout configuration owns interpolation, stroke, markers,
  labels, and other presentation concerns.
- `LineRaceSnapshot`: immutable controller output containing the completed
  points and one optional interpolated frontier per series.
- `LineRaceController`: deterministic play/pause/seek/step/speed state machine.
- `LineRaceTicker`: presentation-free Flutter ticker with lifecycle and reduced
  motion handling.
- `LineRaceConfigCodec`: versioned JSON-safe portable configuration.

Validation rejects duplicate ids, unknown frame keys, unordered/non-finite X
values, non-finite values, empty series/frames, and invalid durations. Sparse
series are valid; interpolation only occurs when both adjacent observations
exist, so gaps and late entrants never gain invented values.

## Controller semantics

The controller owns `frameIndex` and `frameTransitionProgress`.

- At a settled frame, each snapshot contains authored points up to that frame.
- During a transition, a series with finite values in both adjacent frames gets
  one frontier point whose X and Y are linearly interpolated on the same clock.
- A missing source or target value creates a hard boundary: the next authored
  point appears only when its frame settles.
- Seeking settles directly on the requested frame and pauses playback.
- Reaching the final frame pauses unless loop is enabled.
- Speed changes rescale the current frame duration without changing authored
  data.

## Showcase

Add `Race` as the final authored choice on the Line Charts page, immediately
before Playground. The example uses representative 2012 Formula 1 driver
points by round and provides:

- playback controls and a seek slider above the chart;
- stable series colors and a fixed full-round X axis;
- collision-aware endpoint labels that follow the live X frontier, ordinary
  legend, and configurable markers;
- Options groups for playback, line geometry, endpoint-aligned frontier
  labels, hide-or-pack collision policies, optional values and decoration,
  legend, and standard chart options;
- Data, Split, and Source views for the current render-ready snapshot, while
  `LineRaceConfigCodec` separately preserves the complete authored timeline;
- a fresh chart identity on preset changes so unrelated presets do not morph
  into or out of the race.

## Delivery slices

### Slice 1 - deterministic timeline

- Add the public model, controller, ticker, codec, exports, and focused tests.
- Cover validation, sparse data, interpolation, seek/step/speed/loop, reduced
  motion, and codec round trips.

### Slice 2 - line-family composition

- Compose controller snapshots into ordinary `LineChartSeries`.
- Wire last-visible series callouts, fixed X domain, legend, and playback UI.
- Add the F1 showcase preset and searchable Options controls.

### Slice 3 - portability and hardening

- Verify Data/Split/Source, generated Dart, fluent/AI surfaces, accessibility,
  keyboard operation, export, and fresh-chart preset transitions.
- Add performance coverage for long timelines and many series.
- Update line-family documentation and gallery/help references.

## Verification gates

- Focused model/controller/ticker/codec/widget/showcase tests.
- `dart format --output=none --set-exit-if-changed` on touched Dart files.
- `flutter analyze` for package and example.
- Relevant package and example test suites.
- Live web review on the line `Race` preset, including play, pause, seek, step,
  speed, loop, endpoint-label collision behavior, reduced motion, and switching
  to/from unrelated presets.
- Register `validate` and `refresh`, with residual debt recorded explicitly.
