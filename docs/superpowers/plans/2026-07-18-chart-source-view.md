# Chart Source View implementation plan

**Date:** 2026-07-18  
**Status:** Implemented locally; awaiting review  
**Branch:** `feature/chart-source-view`  
**Primary surface:** `BravenChartWorkbench`

## Objective

Give Flutter developers a consistent way to inspect and copy the Dart
configuration for the chart currently mounted in a `BravenChartWorkbench`.
The feature must be centrally reusable, opt-in, revision-aware, responsive,
and honest about data or runtime behaviour that cannot be represented as
portable source.

The source shown to a developer is generated from the chart's effective
document state. It is not a hand-maintained showcase snippet and is not
reconstructed from pixels or the chart's original widget arguments.

## Product contract

### Display mode

- Add `ChartDisplayMode.source` as a first-class Workbench presentation.
- Source remains hidden unless the host includes it in
  `availableDisplayModes`.
- When enabled, the existing mode selector reads
  `Chart | Data | Split | Source`.
- `Split` continues to mean Chart + Data in the first release. Source uses the
  full content viewport.
- On compact layouts, the mode selector may wrap but retains 48-pixel targets,
  keyboard operation, visible focus, and semantic labels.
- `showModeSwitcher` continues to control the selector as a whole. A separate
  `showSource` flag is intentionally not introduced.

### Meaning of "current chart"

The default source represents the current effective portable configuration at
a `ChartDocumentRevision`, including resolved series, axes, annotations,
theme, interaction configuration, legend, grid, layout, normalization, and
other portable chart settings.

Transient hover, crosshair, tooltip animation, focus painting, and pointer
state are excluded. Durable view state is optional and disabled by default so
the copied result is a reusable chart configuration rather than an incidental
viewport snapshot.

### Developer experience

The primary source format is direct Dart using public package APIs:

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

final chart = BravenChartPlus(
  title: 'Multi-axis',
  series: [
    LineChartSeries(
      id: 'power',
      name: 'Power',
      points: [
        ChartDataPoint(x: 0, y: 148),
        ChartDataPoint(x: 1, y: 162),
      ],
    ),
  ],
);
```

Artifact JSON or `ChartDocument.fromJson(...)` is not the default developer
view. The generated Dart should teach the public chart API and be directly
adaptable in a Flutter application.

The Source surface provides:

- selectable monospaced Dart;
- syntax highlighting and line numbers;
- vertical and horizontal scrolling;
- explicit line-wrap control;
- a primary **Copy code** action;
- revision, series, point, and completeness status;
- loading, stale, warning, failure, and retry states; and
- light/dark theme support without adding a visually unrelated panel system.

## Portability and safety

### Runtime-owned values

Closures, callbacks, custom widget builders, controllers, streams, formatter
implementations, and host services cannot be reconstructed faithfully.
Generated output must never silently discard them. It emits a compilable
placeholder where practical and an explicit diagnostic, for example:

```dart
// Runtime callback omitted: onDataPointTap.
// Provide this callback from your application.
```

Artifact extraction remains fail-closed when runtime values lack binding
descriptors. Source capture uses a source-specific adapter that can describe
runtime-owned values as placeholders without weakening artifact portability
or hydration rules.

### Data volume

The default inline-data ceiling is 250 points across the generated chart.
When the effective document exceeds that ceiling:

- source generation never silently samples or changes the data;
- named point-list placeholders keep the Dart structurally usable;
- the exact omitted point count is reported; and
- the result is marked `portableWithPlaceholders` rather than complete.

Hosts may request full inline data or configuration-only output. Continuously
streaming charts should normally use configuration-only or bounded data.

### Privacy

Source mode is opt-in because generated code can contain chart labels,
metadata, and data values. Copy is always an explicit user action. The package
does not log, persist, or transmit generated source.

## Public API shape

The names below are the intended contract. Exact constructor fields can be
adjusted during implementation when existing model constraints require it,
but the responsibilities must remain separate.

```dart
enum ChartDisplayMode { chart, data, split, source }

enum ChartSourceRefreshPolicy {
  manual,
  onModeEntry,
  onDocumentRevision,
}

enum ChartGeneratedSourceCompleteness {
  complete,
  portableWithPlaceholders,
}

class ChartDartSourceOptions {
  const ChartDartSourceOptions({
    this.includeImports = true,
    this.includeViewState = false,
    this.includeDefaultValues = false,
    this.maxInlinePoints = 250,
    this.variableName = 'chart',
  });
}

class ChartGeneratedSource {
  final String source;
  final ChartDocumentRevision revision;
  final ChartGeneratedSourceCompleteness completeness;
  final List<ChartSourceWarning> warnings;
  final int seriesCount;
  final int pointCount;
  final int omittedPointCount;
}

abstract final class ChartDartSourceGenerator {
  static ChartArtifactResult<ChartGeneratedSource> generate(
    ChartDocumentSnapshot snapshot, {
    ChartDartSourceOptions options = const ChartDartSourceOptions(),
  });
}
```

`ChartWorkbenchController` and `ChartWorkbenchHandle` gain source state,
`refreshSource()`. `ChartWorkbenchStatus` reports
source state independently from table and artifact state.

## Implementation progress

- [x] Document the product contract, API boundary, delivery slices, and gates.
- [x] Add deterministic source models, writer, and the public generator.
- [x] Cover all six chart-family constructors and direct analytical annotation
  constructors, with explicit warnings for fields not emitted yet.
- [x] Add opt-in Workbench Source state without coupling it to table state.
- [x] Add the first read-only Source viewport and exact clipboard copy.
- [x] Enable the central Chart Workbench showcase for local review.
- [x] Roll the shared Source mode through the Line, Area, Bar, Scatter, Pie,
  and Donut detail pages without page-owned source panels.
- [x] Complete portable built-in source emission for advanced bar, radial,
  annotation, interaction, resolved custom-theme, canvas legend, label, and
  durable view-state options; retain explicit diagnostics for runtime-owned
  callbacks and host-owned theme references.
- [x] Complete the first advanced emission tranche: Bar analytical and style
  models, radial gradients/elevation/radius/grouping, annotation styles,
  line/area labels, detailed interaction configuration, and legend styling.
- [x] Add the source-specific runtime placeholder adapter described below,
  while keeping portable artifact extraction fail-closed.
- [x] Add parser/compile fixtures and the remaining freshness/failure/a11y
  matrix before promoting the feature for release.

## Internal architecture

```text
Mounted effective chart
        |
        v
Source capture adapter
        |
        +-- portable ChartDocumentSnapshot
        +-- runtime placeholder descriptors
        +-- source warnings
        |
        v
ChartDartSourceGenerator
        |
        v
ChartGeneratedSource
        |
        v
ChartSourceView / Copy code
```

The generator is independent of Flutter widget state. It uses a deterministic
internal Dart writer with stable field ordering, correct Dart string escaping,
finite-number validation, enum names, public constructors, and `const` where
the emitted expression is valid.

No reflection and no runtime source-formatting dependency are introduced.
Generated fixtures are parsed in tests, and representative fixtures are
compiled to prevent plausible-looking but invalid source.

## Workbench state changes

The current implementation treats every non-chart display mode as table-backed.
Before adding Source, replace that assumption with explicit predicates:

```dart
bool _modeShowsChart(ChartDisplayMode mode);
bool _modeShowsTable(ChartDisplayMode mode);
bool _modeShowsSource(ChartDisplayMode mode);
```

Source owns independent phase, snapshot, generated result, warning, error, and
stale state. A source failure must not erase a usable table or artifact result.

The default refresh policy is `onModeEntry`. A document revision change marks
visible source stale and offers **Refresh source**. The optional
`onDocumentRevision` policy refreshes only while Source is visible and uses a
bounded debounce; it is not recommended for high-frequency live data.

Concurrent refresh requests share one in-flight future. A failed refresh keeps
the previous source visible, marks it stale, and exposes a structured recovery
action.

## Delivery slices

### Slice 1 — Generator foundation

1. Add source options, result, warning, and completeness models.
2. Add a deterministic internal Dart source writer.
3. Generate direct Dart for document-level chart configuration.
4. Generate Cartesian series, radial series, axes, points, annotations,
   interaction, theme, layout, legend, grid, and normalization expressions.
5. Add bounded-data placeholders and runtime-owned warnings.
6. Export the public generator API.
7. Add parser, golden, and semantic coverage tests.

**Checkpoint:** A `ChartDocumentSnapshot` can produce stable, valid Dart for
representative line, bar, pie, donut, multi-axis, and annotated charts without
any Workbench UI dependency.

### Slice 2 — Workbench source state

1. Move `ChartDisplayMode` to a neutral display/workbench module while
   preserving its existing export path.
2. Add Source mode and explicit surface predicates.
3. Add source state to the controller, handle, and status model.
4. Add source capture, refresh, revision, stale, and structured failure logic.
5. Keep table, source, and artifact operations isolated.

**Checkpoint:** Programmatic mode selection and source refresh work with Source
enabled or disabled, and regression tests prove existing Chart/Data/Split
behaviour is unchanged.

### Slice 3 — Source surface

1. Add the Source segment and icon.
2. Build `ChartSourceView` with selection, scrolling, line numbers, wrapping,
   copy, and theme-aware highlighting.
3. Add loading, stale, warning, first-failure, refresh-failure, and retry states.
4. Verify keyboard focus, semantics, 48-pixel targets, contrast, compact
   wrapping, long lines, and large output.

**Checkpoint:** Source is visually and behaviourally consistent with the
existing Workbench on desktop and compact viewports.

### Slice 4 — Showcase and documentation

1. Enable Source centrally in the Chart Workbench showcase.
2. Enable it selectively on chart-type detail pages that use the shared
   Workbench rather than adding one-off code samples.
3. Add a direct public route that can be browser-verified.
4. Update Workbench, public API, feature matrix, README, and changelog docs.
5. Explain data limits, effective configuration, refresh policy, and runtime
   placeholders.

**Checkpoint:** A developer can open a hosted chart, select Source, copy the
generated Dart, and understand any omitted runtime or data dependencies.

### Slice 5 — Shared Workbench presentation scope

1. Add a caller-owned `ChartWorkbenchGroupController` that stores the shared
   requested display mode and selector visibility.
2. Add a nestable `ChartWorkbenchScope`; the nearest scope coordinates its
   descendant workbenches, while an explicit Workbench group controller takes
   precedence over the inherited scope.
3. Register mounted Workbenches with their available modes and expose only the
   intersection. If a newly attached Workbench cannot support the current
   shared mode, reconcile the whole group to Chart when available, otherwise
   to the first common mode.
4. Route both UI and programmatic `ChartWorkbenchController.setDisplayMode`
   requests through the group while attached. Applying a group notification
   locally must not rebroadcast it.
5. Treat `showModeSwitcher` as the Workbench's local capability gate. The
   switcher is visible only when both the local flag and group preference are
   true; host actions remain available when the selector is hidden.
6. Keep compact Split pane choice, split ratio, table/source freshness, and
   chart interaction state local to each Workbench.
7. Wrap the showcase in one application-wide scope and enable the complete
   Chart/Data/Split/Source set on every scoped Workbench.
8. Add group lifecycle, availability, nesting, visibility, synchronized-mode,
   programmatic-control, and cross-page showcase tests.

**Checkpoint:** Selecting a mode in any scoped chart updates every mounted
chart and becomes the initial mode when navigating to another chart page.
Hiding or showing the selector through the group affects all scoped charts
without hiding unrelated host actions.

## Test matrix

### Generator tests

- line, area, scatter, and every supported bar variant;
- pie and donut configuration, labels, sweeps, radii, and centre content;
- multi-axis and per-series normalization;
- all annotation document variants;
- light, dark, and resolved custom themes;
- grids, legends, layout, labels, markers, interpolation, glow, and baseline
  fills;
- Dart escaping for quotes, newlines, dollar signs, backslashes, and Unicode;
- integer/double formatting and rejection of non-finite values;
- zero, boundary, and over-limit data volumes;
- runtime callbacks, builders, formatters, controllers, and extensions;
- deterministic ordering and repeatable output; and
- parser plus representative compile-fixture validation.

### Workbench tests

- Source is hidden by default;
- Source appears only when included in `availableDisplayModes`;
- unavailable controller selection returns the existing structured error;
- requested/effective Source behaviour at wide and compact widths;
- entering Source generates the current effective revision;
- document changes mark Source stale;
- manual, mode-entry, and revision refresh policies;
- in-flight request coalescing and previous-result retention;
- source failure does not alter table or artifact state;
- chart remains mounted and paintable while Source is visible;
- Copy code returns the exact visible source;
- keyboard, semantics, focus, wrap, scrolling, light/dark, and narrow-layout
  behaviour; and
- Chart/Data/Split regression coverage remains green.

## Release gates

Before review or PR:

```text
dart format --set-exit-if-changed lib test example
flutter analyze lib
flutter test
cd example && flutter analyze
cd example && flutter test
cd example && flutter build web --release
dart pub publish --dry-run
git diff --check
```

Browser verification must cover the direct Workbench route and at least one
Cartesian, bar, pie, and donut example with Source enabled, with no console
errors or layout overflow.

## Acceptance criteria

- One public generator API works without the Workbench.
- Source is a host-configurable Workbench mode and is hidden by default.
- The visible result is direct `BravenChartPlus` Dart, not artifact JSON.
- Output is bound to the effective document revision.
- Portable configuration is represented without silently dropping fields.
- Runtime-only values and data omissions are explicit.
- Large data is never silently sampled.
- Copy returns the exact visible source.
- Generated fixtures parse, and representative fixtures compile.
- Source errors do not affect Chart, Data, Split, table, or artifact state.
- The interface works in light/dark themes, compact layouts, keyboard
  navigation, and screen-reader semantics.

## Explicitly deferred

- A Chart + Source split mode.
- Multiple output languages or framework wrappers.
- An editable source playground or round-trip source parser.
- Automatic execution of generated source.
- Persisting or sharing generated source from the package itself.
- Replacing the portable artifact format with Dart source.

These can be considered after the read-only Dart Source mode has proved useful
without weakening the Workbench's current chart/table/artifact boundaries.
