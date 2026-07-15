# Portable Chart Artifacts

Chart artifacts preserve a chart as validated, versioned data that can be
saved, restored, compared, displayed as a native table, or rendered again in a
fresh runtime. The artifact model captures effective chart state; it is not a
screenshot and does not serialize controllers, callbacks, open files, network
clients, or other executable objects.

Use the public package barrel throughout:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## What an artifact contains

`ChartArtifact` is the portable envelope. Its main fields are:

- `schemaVersion`: artifact wire-schema version;
- `renderer`: package and renderer version that produced it;
- `artifactId` and `createdAt`: host identity and capture time;
- `document`: series, data, axes, annotations, theme, and interaction config;
- `viewState`: optional durable visibility, selection, legend, and viewport state;
- `preview`: optional raster representation bound to a document hash;
- `provenance`: JSON-safe host metadata;
- `integrity`: optional host-defined integrity metadata;
- `extensions`: namespaced portable extension values.

Runtime callbacks and services are rebound separately through
`ChartRuntimeBindings`. A restored chart receives fresh controllers and must
not share mutable runtime state with the chart that produced the artifact.

## Save a mounted chart

Attach a `BravenChartController` to the chart, then extract after the widget is
mounted:

```dart
final chartController = BravenChartController();

BravenChartPlus(
  bravenChartController: chartController,
  series: series,
);

final extracted = await chartController.extractArtifact(
  ChartArtifactExtractOptions(
    artifactId: 'workout-42-power',
    documentOptions: const ChartDocumentExtractOptions(
      documentId: 'workout-42-power-document',
      includeViewState: true,
    ),
    provenance: ChartArtifactProvenance(
      values: JsonObjectValue(const {
        'source': JsonStringValue('workout-review'),
      }),
    ),
  ),
);

switch (extracted) {
  case ChartArtifactSuccess<ChartArtifact>():
    final encoded = ChartArtifactJsonCodec.encode(extracted.value);
    // Persist encoded.value when the encode result is successful.
  case ChartArtifactFailure<ChartArtifact>():
    // Display or log extracted.error and extracted.warnings.
}
```

Extraction reads the chart's resolved source state. It includes declarative
widget series, `ChartController` changes, committed direct
`LiveStreamController` points, controller-managed annotations, and durable view
state. It does not reconstruct data from paint elements or pixels.

`ChartArtifactJsonCodec.encode` emits deterministic canonical JSON. Map keys,
number representation, and omitted default fields therefore remain stable for
hashing and repeatable persistence.

## Restore into a fresh runtime

Decode and hydrate untrusted or persisted JSON through the package boundary:

```dart
final restored = ChartDocumentHydrator.hydrateJson(
  savedJson,
  runtimeBindings: ChartRuntimeBindings(
    onSeriesSelected: (seriesId) {
      // Host behavior is rebound here; it was not serialized.
    },
  ),
);

switch (restored) {
  case ChartArtifactSuccess<HydratedChartConfiguration>():
    final controller = BravenChartController();
    final chart = restored.value.build(
      bravenChartController: controller,
    );
  case ChartArtifactFailure<HydratedChartConfiguration>():
    // Treat restored.error.code, message, and path as structured diagnostics.
}
```

Call `hydrateJson` for each independent chart tile. Each call creates a fresh
configuration; give every built chart its own `BravenChartController`.

If an artifact uses external payloads, use
`ChartDocumentHydrator.hydrateJsonWithDataResolver` instead. It validates the
envelope, asks the host resolver for authorized bytes, verifies length and
SHA-256, decodes within resource limits, and only then hydrates the chart.

## Host-controlled external data

Large series can be moved out of the JSON envelope without giving the package
file or network access:

```dart
final encodedBlob = ChartDataBinaryCodec.encode(inlinePayload);

if (encodedBlob case ChartArtifactSuccess<ChartDataBlob>()) {
  await hostStorage.put(encodedBlob.value.checksum, encodedBlob.value.bytes);

  final reference = encodedBlob.value.reference(
    resolverKey: encodedBlob.value.checksum,
  );
  // Put `reference` in the series document before encoding the artifact.
}
```

Implement the resolver at the host boundary:

```dart
class AppChartDataResolver implements ChartDataResolver {
  AppChartDataResolver(this.storage);

  final AuthorizedBlobStorage storage;

  @override
  Future<ChartArtifactResult<List<int>>> resolve(
    ReferencedPayload reference,
  ) async {
    final bytes = await storage.readAuthorized(reference.resolverKey!);
    return ChartArtifactSuccess(value: bytes);
  }
}
```

The package never opens `ReferencedPayload.uri`. Resolver implementations own
authorization, allowed URI schemes, credentials, retries, storage access, and
network policy. Returning bytes does not bypass package validation.

Available payload encodings are:

- `ChartDataBlobCodec`: deterministic canonical JSON blob;
- `ChartDataBinaryCodec`: compact columnar binary-v1 with exact chart-number
  recovery and `xor-significant-bytes-v1` compression.

The reference records content type, byte length, point count, and checksum. A
declared checksum becomes trusted only after resolution verifies the bytes.

## Resource limits and failures

Decoding applies `ChartArtifactValidationLimits` before model construction and
again after migrations or external payload resolution. Defaults bound encoded
bytes, nesting depth, collection entries, string length, series, total points,
individual payload bytes, and aggregate payload bytes.

Hosts can apply stricter limits:

```dart
const limits = ChartArtifactValidationLimits(
  maxEncodedBytes: 2 * 1024 * 1024,
  maxSeries: 40,
  maxPoints: 200000,
  maxDataPayloadBytes: 8 * 1024 * 1024,
  maxTotalDataPayloadBytes: 24 * 1024 * 1024,
);

final decoded = ChartArtifactJsonCodec.decode(savedJson, limits: limits);
```

All artifact operations return `ChartArtifactResult<T>`:

- `ChartArtifactSuccess<T>` has `value` and optional warnings;
- `ChartArtifactFailure<T>` has a structured `error` and optional warnings.

Do not infer success from a missing exception. Branch on the result type and
surface the diagnostic `code`, `message`, and optional JSON `path`.

## Canonical hashes and deduplication

```dart
final documentHash = ChartArtifactCanonicalizer.documentHash(
  artifact.document,
);
final viewHash = ChartArtifactCanonicalizer.viewHash(
  artifact.document,
  artifact.viewState,
);
final payloadHash = ChartArtifactCanonicalizer.dataPayloadHash(
  artifact.document.series.first.data,
);

final groups = ChartArtifactDeduplicator.group(
  artifacts,
  scope: ChartArtifactDeduplicationScope.view,
);
```

Document scope ignores envelope metadata and view state. View scope combines
the complete document with durable view state. Deduplication preserves caller
order, retains the first matching artifact as the primary, and returns
immutable groups. The host still decides whether to cache, retain, or delete
anything.

SHA-256 supports content identity and integrity checks. It does not prove who
created an artifact. Signing, encryption, key management, and trust policy
belong to the host or transport layer.

## Native data table

Build the table from the same `ChartDocument`, not from rendered pixels:

```dart
final model = ChartTableModel.fromDocument(
  artifact.document,
  viewState: artifact.viewState,
  options: const ChartTableOptions(
    rowLayout: ChartTableRowLayout.wide,
    alignmentPolicy: ChartTableAlignmentPolicy.exactX,
  ),
);

final table = ChartDataTable(model: model);
```

Wide layout produces one row per exact shared X value and one value column per
series. Sparse series remain sparse; the table does not invent interpolation.
Long layout is the canonical lossless row representation. Table options also
support all, visible, selected, or explicitly named series and optional
viewport filtering.

## Preview capture

Set `includePreview: true` in `ChartArtifactExtractOptions` to request a PNG.
The preview records dimensions, pixel ratio, media type, and the exact
document hash it represents. Extraction retries if state changes between
document and preview capture.

Preview failure is independent from native document export: an artifact may
return successfully without a preview and include a warning. Hosts should keep
the portable document usable and treat the raster as a derived convenience.

## Schema evolution

Future schemas fail closed. Older schemas are accepted only when the caller
explicitly supplies a trusted adjacent-version migration chain. See
[chart-artifact-migrations.md](chart-artifact-migrations.md).

## Showcase checkpoints

Run the example app and open these surfaces from navigation or with the `page`
query parameter:

- `artifact-lab`: canonical JSON and future-schema failure;
- `extraction-lab`: effective widget/controller/live-stream capture;
- `hydration-lab`: independent restored runtime and callback binding;
- `data-table-lab`: chart/data/split modes and exact-X wide table;
- `preview-lab` and `export-lab`: revision-bound raster behavior;
- `resolver-lab` and `binary-payload-lab`: external blob validation;
- `migration-lab`: explicit trusted migration path;
- `identity-lab`: document/view/payload hashes and deduplication;
- `save-restore-lab`: canonical persistence and comparison gallery.
