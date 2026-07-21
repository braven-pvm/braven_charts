# Showcase property platform

## Status

In progress on `feature/showcase-property-platform`, refreshed from `master` at
`a071a7b6`. The first review exposed a product-boundary mismatch: shared
inspector mechanics were correct, but randomization was attached to authored
examples instead of dedicated playgrounds. The implementation is being
realigned before commit and pull request.

Reusable foundation delivered in the first slice:

- one searchable, metadata-aware inspector on desktop and compact layouts;
- on-demand property help without permanently expanding the options panel;
- shared typed editors, including the canonical colour palette behavior;
- one deterministic randomizer controller with seed, generate, play, pause,
  interval, and timer lifecycle management;
- real-state randomizer adapters ready to be hosted by the 9 chart-family
  playgrounds;
- responsive header actions that remain usable on action-heavy pages; and
- regression coverage for search, help, compact parity, deterministic
  generation, playback, disposal, and chart-family adoption.

## Why this is a platform change

The showcase is simultaneously a development workbench, regression surface,
interactive API reference, and public product demonstration. Its property
editors therefore need the same consistency and completeness as the chart
renderers they exercise.

The current implementation has a strong shared shell (`ChartPageLayout`,
`OptionsPanel`, and the option control widgets), but the shell receives opaque
widgets. It cannot identify a property, search it, explain it, validate editor
choice, or drive it from a generated configuration. The Polar Column page has
proved the value of deterministic randomization, but its seed, timer, playback,
and presentation UI are page-local.

Current inventory:

- 9 chart-family routes: Line, Area, Bar, Scatter, Candlestick, Pie, Donut,
  Concentric Donut, and Polar Column.
- 25 showcase pages use `ChartPageLayout` with an options surface.
- 169 option sections and 624 shared option controls are declared across the
  showcase.
- The 21 legacy colour call sites now inherit the shared
  `ChartColorPalette` clear, reselect, custom-colour, and toggle semantics
  through the common option control.

## Corrected product contract

### Authored examples are fixtures

Existing examples are curated regression and teaching fixtures. Their data,
configuration, selector identity, and example-specific option lists remain
stable. Reopening or resetting an authored example must reproduce its authored
state. Random generation and timed playback are never shown or run while an
authored example is active.

### Every chart family has one Playground sample

Line, Area, Bar, Scatter, Candlestick, Pie, Donut, Concentric Donut, and Polar
Column each gain a clearly separate `Playground` sample, listed after the
curated examples so it reads as the advanced testing destination. The
Playground owns:

- the exhaustive property inspector for that chart family;
- generated data controls;
- seeded property and data randomization;
- timed playback and pause-for-inspection; and
- reset-to-playground-default behavior.

The Playground inspector is not assembled from whichever authored example
happens to be active. It is backed by an explicit family property inventory
covering every public property applicable to the mounted chart and series.
Properties that are temporarily inapplicable remain discoverable and explain
their prerequisite instead of disappearing from search.

### Searchable inspector

Every options surface uses one inspector implementation on wide screens and in
the compact bottom sheet. Search matches section names, property labels,
descriptions, and aliases. Matching sections open automatically and show only
matching properties; clearing search restores the user's expansion state.

Search has an accessible label, a clear action, an empty state, and a visible
match count. It is sticky with the panel header so it remains available while
scrolling.

Every inspector, authored and Playground, also exposes `Expand all sections`
and `Collapse all sections` from the sticky header. Search temporarily expands
matching sections; clearing search returns to the current authored expansion
state.

### Property metadata and help

Every shared editor exposes:

- a stable label used as its default search identity;
- a concise label;
- an on-demand description;
- search aliases for API terminology and common synonyms;
- the editor type and current value through the existing typed widget.

Descriptions remain out of the normal reading path. A small help affordance
opens a focused explanation and retains a tooltip for pointer users. Existing
inline subtitles remain supported only when they communicate state or a
constraint that must always be visible.

### Editor taxonomy

- immediate boolean: switch;
- short mutually exclusive choice: segmented control when it fits;
- longer or variable choice: dropdown;
- bounded numeric value: slider with a formatted value;
- short integer: integer slider or stepper according to range;
- colour: `ChartColorPalette`, including inherit/clear, reselect-to-clear,
  custom colour, and an optional enable toggle;
- text: labelled text field;
- action: verb-led button with one primary action per group.

### Deterministic property randomizer

The shared controller owns seed progression, interval, play/pause, timer
lifecycle, and reproducibility. Each chart page owns only a typed generator and
an apply adapter. Applying a generated example updates the page's real state,
so the inspector always displays the values being rendered.

Each Playground generator must vary:

- representative data shape and values;
- geometry/layout properties;
- labels, axes, legends, and interaction settings where supported;
- theme and colour overrides;
- family-specific properties.

Generated combinations must satisfy API invariants. A seed reproduces the same
complete result. Playback advances one seed per tick, can be paused without
changing the current chart, and disposes its timer with the page.

## Architecture

### `ShowcasePropertyMetadata`

An explicit metadata value shared by controls and sections. Inspector matching
never scrapes rendered text. A small built-in help catalogue supplies useful
descriptions for common chart properties; family-specific controls can provide
more precise copy at the call site.

### `OptionsPanel`

Becomes stateful and provides the active search query through an inherited
scope. It filters top-level searchable widgets, shows result/empty states, and
keeps the same child list API for source compatibility.

### Shared option widgets

`OptionSection`, `BoolOption`, `EnumOption`, numeric options, colour options,
text options, and actions implement the searchable metadata contract and use a
shared label/help component. Unknown custom widgets remain visible when their
section title matches and can opt in through a searchable wrapper.

### `ShowcaseRandomizerController<T>`

A reusable `ChangeNotifier` with a typed `generate(seed)` callback and
`apply(value)` callback. It exposes seed, applied seed, interval, playing state,
and the current generated value. It contains no chart-family logic.

### `PropertyRandomizerSection`

The standard inspector section for seed, interval, generate, and play/pause.
The same controller can also drive a compact page-level action/card without
duplicating timer behavior.

## Rollout

1. Add metadata-aware search, help, and expand/collapse-all behavior without
   changing authored example definitions.
2. Add a shared authored/Playground boundary and ensure the randomizer is
   unavailable outside Playground mode.
3. Inventory the public chart, series, axis, legend, annotation, interaction,
   motion, styling, and data properties for each family.
4. Build the 9 exhaustive Playground inspectors from those inventories, with
   correct control types and visible prerequisite states.
5. Connect typed generators and adapters to Playground state only.
6. Move remaining legacy colour editors to `ChartColorPalette` semantics.
7. Add coverage tests proving every inventory item has an editor, help text,
   search metadata, current-value binding, and randomizer policy.
8. Verify authored fixture stability, desktop and compact inspectors,
   deterministic generation, timer disposal, direct routes, and a release web
   build.

## Verification record

- `flutter analyze` in `example`: clean.
- `flutter test` in `example`: 303 tests passed after refreshing from the
  latest Polar Column polish merge.
- Randomizer adoption matrix: all 9 chart families rendered seeds 0, 1, 2, 7,
  31, 127, 511, and 997 without framework exceptions.
- `flutter analyze lib` in the package root: clean.
- `flutter test` in the package root: 2,485
  tests passed.
- `flutter build web --release` in `example`: passed, including the WebAssembly
  compatibility dry run.
- `git diff --check`: clean.

The repository-wide analyzer continues to traverse vendored Fleather examples
and optional golden/integration harnesses whose development dependencies are
not installed by the root package. Those pre-existing environment errors are
outside this showcase-only change; the supported package-library and example
quality gates above are clean.

## Acceptance gates

- Search finds a property by label, description, and alias on desktop and in
  the compact options sheet.
- Search results expand automatically; clearing search restores authored
  section expansion.
- Help is available on demand and usable by pointer, keyboard, and semantics.
- All chart-family routes expose one dedicated Playground sample.
- Playground is the final choice after every curated chart-family example.
- Authored examples do not expose or respond to the randomizer.
- Authored data, configuration, and example-specific option lists are stable
  before and after a Playground session.
- Every public property in a family inventory has a typed Playground editor.
- Every inspector exposes search plus expand/collapse-all behavior.
- Identical seeds reproduce identical chart data and configuration.
- Every generated value is reflected by its property editor.
- Playback can pause/resume without losing the current result or leaking a
  timer.
- All colour properties use the shared palette contract.
- Targeted widget/unit tests, `flutter analyze`, `git diff --check`, and
  `flutter build web --release` pass before review.
