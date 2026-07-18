# Chart family integration

This document defines what a future chart family must provide before it can
participate fully in `BravenChartPlus`, `BravenChartWorkbench`, portable
artifacts, native data views, generated Dart source, and the public showcase.

## Two different integration tasks

Adding an already-supported chart to a Workbench is intentionally small. The
host supplies the Workbench controller to the mounted chart and opts into the
presentations it wants:

```dart
BravenChartWorkbench(
  availableDisplayModes: const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: [supportedSeries],
  ),
)
```

The Workbench is family-neutral at this layer. It keeps the chart mounted and
asks its controller for the effective document used by Data, Source, and
artifact operations.

Adding an entirely new chart family is a larger package-level task. Extending
`ChartSeries` alone does not install a renderer, schema codec, table meaning,
or Dart source emitter. The family must complete the vertical contract below
before the Workbench can represent it honestly.

## Required vertical contract

### 1. Public model and validation

- Define the immutable public series and style configuration.
- Establish data invariants, empty-data behavior, mixing rules, and whether
  the family is Cartesian, radial, or another layout category.
- Give point identity stable semantics so controller focus and selection can
  survive document extraction and restoration.
- Export the supported API from `package:braven_charts/braven_charts.dart`.

### 2. Rendering and interaction

- Add deterministic geometry, painting, layout, bounds, and animation.
- Define pointer, touch, keyboard, focus, selection, tooltip, and semantics
  behavior.
- Integrate theme defaults, reduced motion, loading/empty states, and preview
  capture.
- Add performance coverage appropriate to the expected dataset size.

### 3. Portable document and artifacts

- Encode and decode every portable property in the canonical chart document.
- Allocate stable type and capability IDs and update hydration validation.
- Preserve all source data and point metadata without reconstructing state
  from rendered pixels.
- Describe runtime-owned callbacks, builders, and formatters explicitly;
  portable extraction must continue to fail closed when a required binding is
  missing.

`ChartSeriesExtensionCodec` supports allowlisted artifact extensions. It does
not, by itself, install a new renderer or teach the Workbench how to project or
generate source for that family.

### 4. Native data projection

- Confirm whether the existing exact-X Cartesian long/wide projection is
  semantically correct.
- Add a dedicated projection when the visual encoding has different source
  semantics, as Pie and Donut do for category, value, radius, and share.
- Define sorting, copy, CSV, focus, selection, and derived-field behavior.
- Keep the table source-preserving even when the renderer groups or derives
  visible marks.

### 5. Generated Dart source

- Add the public constructor and all portable options to
  `ChartDartSourceGenerator`.
- Extend source capture for runtime formatter or callback descriptors.
- Emit explicit placeholders and diagnostics for values that cannot be
  reconstructed as Dart.
- Add deterministic-output, syntax, formatter, and compile-fixture tests.

### 6. Workbench and showcase proof

- Mount the chart with the controller supplied by `BravenChartWorkbench`.
- Exercise Chart, Data, Split, and Source using the effective mounted state.
- Add a complete chart-type detail page and route rather than a static code
  sample.
- Verify compact and desktop layouts, direct-route loading, release web build,
  documentation, and pub.dev readiness.

## Current implementation seams

Built-in chart families currently have explicit integrations in these areas:

- `lib/src/braven_chart_plus.dart` for validation, layout, rendering, and
  interaction dispatch;
- `lib/src/artifacts/chart_series_document_codec.dart` for document encoding,
  capabilities, and hydration input;
- `lib/src/table/chart_table_model.dart` and its builders for native data
  projection;
- `lib/src/source/chart_source_capture_adapter.dart` for runtime-value
  descriptors; and
- `lib/src/source/chart_dart_source_generator.dart` for direct Dart emission.

Consequently, the current rule is:

> Workbench adoption is plug-and-play after a chart family satisfies the full
> rendering, document, table, and source contract. A new family does not become
> complete merely by subclassing `ChartSeries` or registering an artifact
> extension codec.

## Future adapter direction

A future internal `ChartFamilyAdapter` could consolidate the non-rendering
integration points behind one compile-time registration:

```text
ChartFamilyAdapter
  |-- stable type and capability IDs
  |-- document encoder and decoder
  |-- native table projector
  |-- Dart source emitter
  |-- runtime-value descriptor adapter
  `-- family validation rules
```

This is a design direction, not an implemented public API. It should begin as
an internal registry so built-in families share one auditable contract without
promising arbitrary third-party renderer installation. Rendering remains an
explicit integration until its geometry, hit-testing, animation, and semantics
contract is stable enough to expose safely.

## Completion checklist

A chart family is ready for Workbench and public showcase use only when:

- its public configuration renders and interacts correctly;
- its effective document round-trips without losing portable state;
- its Data projection preserves the source model;
- its generated Dart compiles or reports explicit runtime placeholders;
- Chart/Data/Split/Source remain independent on failure;
- controller identity, focus, and selection remain revision-safe;
- focused tests cover its specialized semantics;
- package and example analysis/tests pass;
- the direct showcase route and release web build pass; and
- its public docs, feature matrix, and changelog are updated.

