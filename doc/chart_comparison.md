# Chart Document Comparison

`ChartComparisonBuilder` is a pure, opt-in model for aligning raw values from
two or more portable `ChartDocument` instances. It calculates optional deltas
without owning persistence, routes, selection state, chart layout, or a global
comparison screen.

Use the public barrel:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Declare identity explicitly

Every document needs a host identity and label. Every comparable series needs
an explicit semantic mapping:

```dart
final result = ChartComparisonBuilder.compare(
  inputs: [
    ChartComparisonInput(
      inputId: 'baseline',
      label: 'Baseline',
      document: baselineDocument,
      viewState: baselineViewState,
    ),
    ChartComparisonInput(
      inputId: 'candidate',
      label: 'Candidate',
      document: candidateDocument,
      viewState: candidateViewState,
    ),
  ],
  seriesMatches: [
    ChartSeriesMatch(
      semanticKey: 'power',
      seriesIdByInputId: {
        'baseline': 'recorded-power',
        'candidate': 'planned-watts',
      },
    ),
  ],
  options: const ChartComparisonOptions(
    baselineInputId: 'baseline',
  ),
);
```

The builder never infers semantic identity from a display name. One source
series cannot map to two semantic keys, input IDs and semantic keys must be
unique, and missing series IDs fail with a stable diagnostic.

The input document is the source of truth. A PNG preview is not comparison
data. Referenced payloads must be resolved through the host's existing
`ChartDataResolver` workflow before calling the synchronous builder.

## Choose an alignment policy

`ChartComparisonAlignmentPolicy.exactX` is the default. It groups equal raw X
values, or equal explicitly converted X values. It does not interpolate,
resample, bucket, or choose a nearby value.

Duplicate X values require an explicit policy:

- `reject` fails closed;
- `byOccurrence` pairs first with first, second with second, and retains every
  source point;
- `keepFirst` aligns the first and emits later duplicates as independent rows;
  and
- `keepLast` aligns the last and emits earlier duplicates as independent rows.

`ChartComparisonAlignmentPolicy.timestampTolerance` performs deterministic,
one-to-one timestamp matching. `timestampTolerance` is required and positive.
The anchor is the mapped baseline input when present, otherwise the first
mapped input. The nearest unused timestamp wins; equal-distance ties choose
the earlier timestamp and then the lower source point index. Ambiguous ties
produce a warning. Points without timestamps and unmatched points remain
independent rows.

`ChartComparisonAlignmentPolicy.none` preserves each source point as its own
long row. It is the safe choice when alignment is not meaningful.

Every row contains a value or an explicit missing cell for every input.
`isAligned` is true only when at least two source points were actually grouped.

## Keep units and domains safe

Equal labels do not prove equal units. When source Y units differ, deltas are
unavailable unless the host supplies a common unit and conversion:

```dart
ChartSeriesMatch(
  semanticKey: 'power',
  comparisonUnit: 'W',
  seriesIdByInputId: const {
    'baseline': 'power-watts',
    'candidate': 'power-kilowatts',
  },
  unitConversionsByInputId: const {
    'candidate': ChartComparisonUnitConversion(
      sourceUnit: 'kW',
      targetUnit: 'W',
      scale: 1000,
    ),
  },
)
```

The affine conversion is `source * scale + offset`. `rawY`, its display value,
and its source unit remain in `ChartComparisonValue`; the converted
`comparisonValue` is additional and marked derived.

Exact-X alignment applies the same rule to incompatible X units:

```dart
const ChartComparisonOptions(
  comparisonXUnit: 's',
  xUnitConversionsByInputId: {
    'candidate': ChartComparisonUnitConversion(
      sourceUnit: 'ms',
      targetUnit: 's',
      scale: 0.001,
    ),
  },
)
```

Different axis domain types remain incompatible; a unit scale does not turn a
numeric sample axis into a datetime axis. Without a safe domain/conversion,
the builder warns and preserves independent rows rather than aligning values
that happen to share the same number.

Comparison always uses raw document data. Normalized render-space coordinates
are never inputs.

## Read values and deltas

`ChartComparisonModel.rows` is deterministic in mapping and alignment order.
Each `ChartComparisonRow` exposes:

- `semanticKey` and a deterministic `rowId`;
- optional `alignmentX` or `alignmentTimestamp`;
- `valuesByInputId`, including raw X/Y, formatted display values, unit,
  timestamp, point reference, validity, hidden-source state, comparison value,
  and missing state; and
- `deltasByInputId` when `baselineInputId` is explicit.

Absolute delta is `candidate - baseline`. Percentage delta is
`absolute / baseline * 100`. A zero baseline keeps the absolute delta but
returns a null percentage with `ChartComparisonDeltaStatus.baselineZero`; it
never produces infinity. Missing, invalid, or unit-incompatible values retain
their source cells and return an explanatory delta status.

No baseline is inferred. When `baselineInputId` is null, the model contains no
delta map.

## Export without losing provenance

```dart
if (result case ChartArtifactSuccess<ChartComparisonModel>()) {
  final export = ChartComparisonExporter.export(result.value);
  final csv = export.csv;
  final derivedColumns = export.columns.where((column) => column.isDerived);
  // Deliver csv using the host's file, share-sheet, or storage policy.
}
```

The rectangular export keeps raw source X/Y, display values, source units, and
missing flags. Comparison values, converted alignment X, deltas, percentages,
and delta statuses use columns whose labels include `[derived]` and whose
`isDerived` flag is true. Delivery remains a host concern.

## Diagnostics

Expected failures use `ChartArtifactFailure<ChartComparisonModel>`:

- `comparison_invalid_input` — invalid count, IDs, baseline, tolerance, or
  conversion configuration;
- `comparison_ambiguous_mapping` — duplicate semantic identity or one source
  series mapped twice;
- `comparison_series_not_found` — a declared source series does not exist;
- `comparison_payload_unsupported` — referenced data was not resolved first;
  and
- `comparison_duplicate_key` — duplicate exact X encountered under `reject`.

Successful models can carry warnings:

- `comparison_unit_mismatch` — no safe common Y unit;
- `comparison_incompatible_domain` — incompatible X domain or unit;
- `comparison_duplicate_key` — an explicit keep policy retained unaligned
  duplicates;
- `comparison_missing_timestamp` — timestamp alignment received untimestamped
  points; and
- `comparison_ambiguous_timestamp` — deterministic tie-breaking was required.

Use diagnostic codes and paths for logs. Localize product-facing recovery copy
in the host.

## Rendering comparison workspaces

The package comparison model does not replace native charts. Hydrate each
document independently with `ChartDocumentHydrator`, give each chart its own
`BravenChartController`, and lay out the resulting charts in the host's route.
This keeps zoom, selection, visibility, annotations, and theme behavior
independent per tile.

The showcase makes that runtime boundary observable by naming the toggled
series and verifying that hiding it changes only the chosen chart's effective
projection.

Use `BravenChartWorkbench.actionsBuilder` for host actions such as **Add to
comparisons**. Store the canonical artifact JSON as the native source and the
PNG preview as a derived thumbnail. Repository, permissions, metadata indexes,
selection limits, and global comparison navigation remain outside
`braven_charts`.

For capture and restoration contracts, read
[Portable Chart Artifacts](chart_artifacts.md). For the single-chart product
surface, read [Chart Workbench](chart_workbench.md).
