# Portable chart artifacts

Portable chart artifacts let an application capture the effective state of a
mounted `BravenChartPlus`, store it as deterministic JSON, render an exact data
table, attach an optional preview image, and restore a fresh interactive chart
later.

The artifact boundary is deliberately separate from the widget constructor.
It captures the state that was actually resolved for rendering, including
controller and live-stream data, visibility, annotations, theme, axes,
interaction settings, and durable view state. It does not serialize Dart
objects, closures, widget instances, or arbitrary executable code.

## The supported flow

```text
mounted chart
    │
    ├─ BravenChartController.extractArtifact()
    │      effective document + optional view state + optional preview
    │
    ├─ ChartArtifactJsonCodec.encode()
    │      canonical, deterministic JSON for storage or transport
    │
    ├─ ChartTableModel.fromDocument()
    │      exact-X wide rows for a compact table, or lossless long rows
    │
    └─ ChartDocumentHydrator.hydrateJson()
           validated models → HydratedChartConfiguration → fresh chart
```

Use the controller only after the chart is mounted. An unattached controller
returns a `ChartArtifactFailure` with the `chart_not_attached` diagnostic.

## Capture a chart

Create and retain a `BravenChartController` with the chart. Dispose it with
the owning widget.

```dart
class ChartScreenState extends State<ChartScreen> {
  final chartController = BravenChartController();

  @override
  void dispose() {
    chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BravenChartPlus(
      bravenChartController: chartController,
      series: widget.series,
      title: 'Training response',
    );
  }
}
```

Capture an artifact after the chart has completed its first layout. The
default is a complete effective snapshot with inline point objects and no
preview. A preview is optional and is hash-matched to the document that is
returned.

```dart
final result = await chartController.extractArtifact(
  const ChartArtifactExtractOptions(
    artifactId: 'workout-2026-07-15',
    includePreview: true,
    documentOptions: ChartDocumentExtractOptions(
      dataScope: ChartDataScope.effectiveFull,
      dataStorage: ChartDataStorage.inlineColumns,
      includeViewState: true,
    ),
  ),
);

switch (result) {
  case ChartArtifactSuccess<ChartArtifact>():
    final artifact = result.value;
    final warnings = result.warnings;
    // Persist or transmit `artifact`; surface warnings to diagnostics.
  case ChartArtifactFailure<ChartArtifact>():
    throw StateError(result.error.message);
}
```

`effectiveFull` includes hidden series and points committed through a runtime
or live-stream controller. Use `visibleSeries` when hidden series should be
excluded, `visibleViewport` for a bounded slice (with one adjacent point on
each side for continuous line/area rendering), `declaredSource` for only the
widget-declared series, or `configurationOnly` when data must not be copied.

## Encode and store JSON

`ChartArtifactJsonCodec` validates the schema, resource limits, required
capabilities, and semantic invariants before returning canonical JSON. A
successful encode is deterministic: equivalent documents produce the same
ordering and number representation.

```dart
final encoded = ChartArtifactJsonCodec.encode(artifact);
if (encoded case ChartArtifactSuccess<String>()) {
  await repository.saveChartArtifact(
    artifact.artifactId,
    encoded.value,
  );
} else if (encoded case ChartArtifactFailure<String>()) {
  logArtifactError(encoded.error, encoded.warnings);
}
```

The envelope has `artifactType: "braven.chartArtifact"` and currently uses
schema version `1`. Store the JSON string as UTF-8; do not depend on the
private files under `lib/src` or on the order of Dart object fields.

## Hydrate a fresh chart

Hydration validates and decodes JSON before constructing public chart models.
It never runs code named by the artifact. The result can build a new
`HydratedBravenChart`, or its models can be used by a host-owned widget.

```dart
final restored = ChartDocumentHydrator.hydrateJson(savedJson);

Widget restoredChart() {
  return switch (restored) {
    ChartArtifactSuccess<HydratedChartConfiguration>() =>
      restored.value.build(),
    ChartArtifactFailure<HydratedChartConfiguration>() =>
      Text('Unable to restore chart: ${restored.error.message}'),
  };
}
```

`ChartHydrationOptions.restoreViewState` defaults to `true`. Set it to `false`
when the destination should use a fresh viewport and selection. Use
`ChartThemeHydrationMode.adaptToHost` to keep the chart's structure while
applying a host theme, or `hostOverride` when the host must supply the entire
theme.

## Data tables: wide rows and long rows

Build a table from the same `ChartDocument` used for the chart. The default
layout is `wide`, which transposes the series into columns and aligns rows by
the exact shared X value:

```text
# │ X value │ Power (W) │ Heart rate (bpm)
1 │ 7.0     │ 241.44    │ 133.75
```

```dart
final snapshot = chartController.extractDocument(
  const ChartDocumentExtractOptions(
    dataScope: ChartDataScope.effectiveFull,
    dataStorage: ChartDataStorage.inlineColumns,
  ),
);

if (snapshot case ChartArtifactSuccess<ChartDocumentSnapshot>()) {
  final table = ChartTableModel.fromDocument(
    snapshot.value.document,
    viewState: snapshot.value.viewState,
    options: const ChartTableOptions(
      rowLayout: ChartTableRowLayout.wide,
      alignmentPolicy: ChartTableAlignmentPolicy.exactX,
    ),
  );

  return ChartDataTable(model: table);
}
```

`wideRows` contains one row per exact X value and a cell keyed by series ID.
If a series has no point at that X, the cell remains absent; values are never
silently interpolated. `longRows` remains available as the canonical one-point
per-row representation. `ChartDataTable` virtualizes rows, keeps raw values
for export, and derives its colors and typography from `ChartDataTableTheme`
and `ThemeData` unless overridden.

### Built-in copy and export actions

`ChartDataTable` shows three actions by default:

- **Copy data** copies the current scope and sort order as display-formatted
  TSV with headers, ready to paste into a spreadsheet.
- **Export CSV** exports raw values in the current scope and sort order. Web
  builds download the file directly.
- **Copy row** copies one display-formatted TSV row from its trailing row
  action.

Whole-dataset clipboard copies are bounded to 1,000 rows and 1,000,000
characters by default. When either limit is exceeded, the table leaves the
clipboard unchanged and tells the user to use CSV export. Row copy remains
available. Raw document values are never rounded or replaced by display text.

```dart
ChartDataTable(
  model: table,
  csvFileName: 'workout-2026-07-15.csv',
  clipboardRowLimit: 500,
  clipboardCharacterLimit: 500000,
  // Supply this on platforms where the host owns file/save-sheet delivery.
  onExportCsv: (export) => fileRepository.save(
    'workout-2026-07-15.csv',
    export.csv,
  ),
)
```

`onCopyDataset` and `onCopyRow` replace the default clipboard delivery when a
host needs its own permission, audit, or messaging flow. `onExportCsv` replaces
the automatic web download and is the delivery boundary for non-web targets.
Set `showCopyDatasetAction`, `showCopyRowAction`, or `showExportCsvAction` to
`false` only when the host intentionally removes that capability.

## Large or external data

Use `ChartDataStorage.inlineColumns` for compact self-contained payloads. For
larger data, `ChartDataBlobCodec.encode` produces bytes and a SHA-256 checksum;
the host persists those bytes and replaces the inline payload with a
`ReferencedPayload` manifest.

```dart
final blob = ChartDataBlobCodec.encode(payload);
if (blob case ChartArtifactSuccess<ChartDataBlob>()) {
  await repository.put(blob.value.bytes);
  final reference = blob.value.reference(resolverKey: 'workout-data-42');
}
```

The package never fetches a URI or opens a file. Implement
`ChartDataResolver.resolve`, authorize the request in the host, verify the
declared byte length and checksum, and pass the resolver to
`ChartDocumentHydrator.hydrateJsonWithDataResolver`.

## Formatters, callbacks, and extensions

Artifacts contain descriptors and stable IDs, not closures. Register the
matching implementation explicitly through `ChartRuntimeBindings`:

- `ChartFormatterRegistry` resolves built-in `braven.number.fixed` and
  `braven.number.percent` formatters plus host-provided formatters.
- `ChartCallbackRegistry` resolves typed callback IDs.
- `ChartTooltipRegistry` resolves tooltip builders.
- `ChartExtensionRegistry` resolves explicitly registered series, annotation,
  and other extension codecs.

An unregistered formatter falls back to its safe fallback pattern and returns a
warning. An extension or callback that is required but not registered fails
closed with a diagnostic; it is never imported by class name from JSON.

## Errors, warnings, limits, and migrations

All artifact operations return `ChartArtifactResult<T>`:

- `ChartArtifactSuccess<T>` contains the value and any non-fatal warnings.
- `ChartArtifactFailure<T>` contains a machine-readable
  `ChartArtifactError` and any warnings collected before failure.

Check `error.code` in application logic and log `error.path` when present. Do
not treat a warning as a failed capture: preview capture can fail while the
native artifact remains usable.

`ChartArtifactValidationLimits` protects memory and CPU during JSON and payload
decoding. Keep the defaults for untrusted input; raise them only for a trusted
transport after measuring the intended data size.

Older schema versions are accepted only when the host supplies an explicit
adjacent-step `ChartArtifactMigration` registry. Migrations are deterministic
data transforms; they cannot execute code from the artifact. A newer schema is
rejected until the package supports it.

## Identity and trust

`ChartArtifactCanonicalizer.documentHash` identifies canonical document
content and is also used to bind a preview to the document it depicts.
`ChartArtifactDeduplicator` can group equivalent content for caching. A hash
does not prove who created or transported an artifact. Hosts that need
authenticity must add their own signing, authorization, and storage policy.

## Public entrypoint

Import the supported API from one library:

```dart
import 'package:braven_charts/braven_charts.dart';
```

Only symbols re-exported by that entrypoint are part of the supported package
surface. The generated pub.dev API reference is built from the `///` comments
on those exported symbols.
