# Chart Workbench

`BravenChartWorkbench` gives one mounted `BravenChartPlus` a native data view,
a responsive split view, and a safe extension point for host actions. It owns
the generic presentation and extraction lifecycle; your application still owns
the chart configuration, persistence, permissions, navigation, and action
policy.

Use the public package barrel:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Minimal workbench

Give the workbench a chart builder. Always attach the
`BravenChartController` supplied to that builder:

```dart
BravenChartWorkbench(
  initialDisplayMode: ChartDisplayMode.split,
  chartBuilder: (context, chartController) {
    return BravenChartPlus(
      bravenChartController: chartController,
      series: series,
    );
  },
)
```

The supplied controller is the connection between the mounted chart, the data
table, and artifact extraction. Do not create another controller inside the
builder.

The workbench keeps the chart subtree mounted in all three modes:

- `ChartDisplayMode.chart` shows the interactive chart;
- `ChartDisplayMode.data` shows a table derived from the chart's effective
  document while the chart remains mounted underneath; and
- `ChartDisplayMode.split` presents both surfaces when enough width is
  available.

The table is never reconstructed from pixels or widget inputs. It comes from
`BravenChartController.extractDocument()`, so controller changes, resolved
series state, annotations, and requested durable view state follow the same
artifact extraction boundary.

## Responsive Split behavior

`splitBreakpoint` controls when a horizontal Split presentation has enough
space. Below the breakpoint, the user's requested mode remains `split`, but the
effective presentation becomes one compact pane with a Chart pane / Data pane
switch. When width returns, Split resumes automatically.

This distinction is public:

```dart
final requested = workbenchController.requestedMode;
final visibleNow = workbenchController.effectiveMode;
```

Use `requestedMode` for user preference and `effectiveMode` for telemetry or UI
that describes the current layout. Do not overwrite a saved Split preference
just because the current viewport is compact.

For a vertical split, set `splitAxis: Axis.vertical`. `splitRatio` is the chart
share of the available content dimension and must be greater than zero and less
than one.

## Add host-defined actions

`actionsBuilder` receives a stable `ChartWorkbenchHandle`. The package manages
duplicate extraction state and structured failures; the host chooses the label,
artifact identity, metadata, and persistence destination.

```dart
BravenChartWorkbench(
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
  ),
  actionsBuilder: (context, handle) => [
    FilledButton.icon(
      onPressed: handle.isExtractingArtifact
          ? null
          : () async {
              final captured = await handle.extractArtifact(
                ChartArtifactExtractOptions(
                  artifactId: 'report-chart-42',
                  createdAt: DateTime.now().toUtc(),
                  includePreview: true,
                  provenance: ChartArtifactProvenance(
                    values: JsonObjectValue(const {
                      'destination': JsonStringValue('quarterly-report'),
                    }),
                  ),
                ),
              );

              switch (captured) {
                case ChartArtifactSuccess<ChartArtifact>():
                  final encoded = ChartArtifactJsonCodec.encode(
                    captured.value,
                  );
                  // Persist the successful encoded value in host storage.
                case ChartArtifactFailure<ChartArtifact>():
                  // Present captured.error.code and captured.error.message.
              }
            },
      icon: const Icon(Icons.bookmark_add_outlined),
      label: const Text('Add to report'),
    ),
  ],
)
```

An action can be save, attach, share, add to a report, or add to comparisons.
`braven_charts` deliberately does not import a database, file picker, Firebase,
or a domain repository.

Preview capture works from Chart, Data, or Split because the chart remains
mounted and paintable. The preview is a convenience for thumbnails and loading
states; the portable `ChartDocument` remains the source used for restoration.

## Control the workbench

Provide a `ChartWorkbenchController` when another part of your widget needs to
change modes, refresh the table, inspect status, or extract an artifact:

```dart
final workbenchController = ChartWorkbenchController();

@override
void dispose() {
  workbenchController.dispose();
  super.dispose();
}

// Later, while the workbench is mounted:
final modeResult = workbenchController.setDisplayMode(ChartDisplayMode.data);
final tableResult = await workbenchController.refreshTable();
```

`setDisplayMode` returns `ChartArtifactFailure` with
`requested_display_mode_unavailable` when the host excluded that mode through
`availableDisplayModes`. It does not throw for a normal unavailable-mode
request.

The handle and controller expose:

| Member | Meaning |
| --- | --- |
| `chartController` | Controller attached to the currently mounted chart |
| `requestedMode` | User-selected Chart, Data, or Split preference |
| `effectiveMode` | Presentation actually visible at the current width |
| `tableSnapshot` | Immutable effective document used for the current table |
| `tableModel` | Current projected table, when ready |
| `tableIsStale` | Whether the chart revision moved past the table snapshot, including after a failed refresh |
| `tableState` | Table phase, model, warnings, and structured error |
| `artifactState` | Independent artifact-extraction phase, result, warnings, and error |
| `refreshTable()` | Coalesced document extraction and table projection |
| `extractArtifact()` | Atomic document and optional preview extraction |

Table extraction and artifact extraction have separate state. A table refresh
does not erase an artifact result, and an artifact failure does not replace a
usable table.

## Table refresh and freshness

The table is a snapshot of effective mounted state, not a live view into mutable
series lists.

`ChartTableRefreshPolicy.manual` captures on the first Data or Split use and
then only when `refreshTable()` is called. `ChartTableRefreshPolicy.onModeEntry`
also refreshes whenever Data or Split becomes effective.

`ChartTableRefreshPolicy.onDocumentRevision` listens to the mounted chart's
opaque effective revision, marks an older table stale immediately, and
coalesces refreshes onto a bounded 250 ms cadence while Data or Split is
visible. It is opt-in; `onModeEntry` remains the predictable default for large
or continuously streaming charts. The package does not show a stale-warning
banner during this normal automatic-refresh window; extraction progress and
real refresh failures remain visible, and `tableIsStale` is still observable.

When the host changes chart data while Data or Split is already visible, call
`refreshTable()` after the updated chart has built:

```dart
setState(() => series = nextSeries);
WidgetsBinding.instance.addPostFrameCallback((_) {
  workbenchController.refreshTable();
});
```

Concurrent calls to `refreshTable()` share the same in-flight future. During a
refresh, a previous usable table remains visible. If the refresh fails, the
previous table remains available, `tableIsStale` becomes true, and
`tableState.error` explains the failure.

If the first table extraction fails, the workbench shows **Retry table** and
keeps the failed state observable. A layout rebuild does not silently retry the
operation. The user can retry explicitly, or the host can call
`refreshTable()` after correcting the source or runtime binding.

Every `ChartDocumentSnapshot` carries a `ChartDocumentRevision`. The mounted
controller exposes the same equality-only value:

```dart
final chartRevision =
    workbenchController.chartController.effectiveDocumentRevision.value;
final tableRevision = workbenchController.tableSnapshot?.revision;
final isCurrent = chartRevision != null && chartRevision == tableRevision;
```

The signal changes for effective data, annotation, visibility, selection, and
durable viewport changes. Hover, crosshair motion, tooltip animation, and focus
painting do not change it. Direct live-stream data mutations are coalesced
before publication, and revision-driven table refresh is separately bounded.
The token is opaque: compare it only with another token emitted by the same
mounted runtime; do not infer ordering or reconstruct it.

For high-rate streams, prefer `manual` or `onModeEntry` and refresh at a cadence
appropriate to the product. Do not refresh a large table at paint or sample
frequency. The showcase's bounded-stream example makes this distinction
visible: the chart advances inside a fixed-size buffer while the table retains
its previous row count until **Refresh table** is chosen.

## Link table rows to chart points

Point identity is explicit and revision-bound. `ChartPointRef` contains a
stable `seriesId` and zero-based `pointIndex`, implements value equality, and
round-trips through artifact JSON. `ChartTablePointReference` remains as a
deprecated type alias for source compatibility; new code should use
`ChartPointRef`.

A long-form table row represents one point. An exact-X wide row represents a
collection: one reference for every populated series cell at that X value.
`ChartDataTable.onRowFocused` and `onRowActivated` therefore receive
`List<ChartPointRef>` rather than an arbitrary first cell. `onRowFocusCleared`
fires when keyboard focus leaves the row, and `onRowHoverChanged` reports a
row collection or null independently for standalone table experiences.

The workbench enables safe row linking by default:

- pointer hover temporarily applies the row's chart focus ring;
- keyboard focus applies a transient chart focus ring;
- pointer exit restores keyboard-driven focus when present;
- focus loss clears the ring when no row remains hovered;
- click or Enter replaces the durable point selection;
- selected chart points are mirrored into the table with a themed row fill,
  persistent leading indicator, and selected semantics; and
- chart-controller point focus is mirrored into the table with the focused-row
  treatment and reveals the matching row without taking keyboard focus;
- a newly selected chart point is scrolled into the table viewport once,
  without taking keyboard focus or overriding later manual scrolling; and
- a wide row focuses or selects every point it represents.

Because durable selection is captured document state, it advances the mounted
document revision. After a successful package-owned row activation, the
workbench immediately refreshes its snapshot so another row remains safe to
select even when `ChartTableRefreshPolicy.manual` is configured. This targeted
refresh does not make independent data, annotation, visibility, or viewport
changes live; those changes continue to follow the configured refresh policy.

Transient focus is not captured in `ChartViewState`. Durable selection is
stored in `ChartViewState.selectedPointRefs`, survives JSON transport and
hydration, and remains independent in each hydrated runtime.

Standalone tables can render the same durable state by passing a set of
`ChartPointRef` values to `ChartDataTable.selectedPointRefs`. A long row is
selected when its point is present. A shared-X row is selected only when every
populated series point represented by that row is present. Override the fill
with `ChartDataTableTheme.selectedRowColor`; the leading indicator and
accessibility semantics remain package-owned.

Pass `ChartDataTable.focusedPointRefs` to mirror transient chart focus in a
standalone table. A long row matches its point; a shared-X row matches when any
represented point is focused. This uses the focused-row visual treatment but
does not claim keyboard or accessibility focus for the table row.

`ChartDataTable.autoRevealFocusedPoints` defaults to true and scrolls only when
the focused point or projected model changes. Set it to false when the host
owns vertical navigation or maps high-frequency chart hover into controller
focus. Package-owned table hover remains stable because its row is already in
the visible viewport.

`ChartDataTable.autoRevealSelectedPoints` defaults to true. Set it to false
when the host owns vertical table navigation. In a wide table, a partial
series selection still reveals its shared-X row, but the row receives complete
selection styling only when all populated points in that row are selected.

Hosts can drive the same behavior directly, but must supply the revision that
issued the references:

```dart
final snapshot = workbenchController.tableSnapshot;
if (snapshot != null) {
  final result = workbenchController.chartController.selectPoints(
    const [
      ChartPointRef(seriesId: 'power', pointIndex: 7),
      ChartPointRef(seriesId: 'heart-rate', pointIndex: 7),
    ],
    revision: snapshot.revision,
    additive: false,
    reveal: true,
  );

  if (result case ChartArtifactFailure<void>()) {
    // Refresh for stale_point_reference; fix the source for
    // invalid_point_reference.
  }
}
```

`focusPoint` / `focusPoints` and `selectPoint` / `selectPoints` reject a stale
revision or an unknown series/index before changing state. `reveal` defaults to
false; when true, the chart pans or expands its X viewport only when needed.
`additive` is available for selection and defaults to replacement. Use
`clearPointFocus()` and `clearPointSelection()` for explicit cleanup.

A valid reference to a hidden series is retained deterministically, including
in captured view state, but cannot paint a ring until that series is visible.
If chart data changes, refresh the table and use references from the new
snapshot instead of retrying an old reference against a new revision.

Set `linkTableRowsToChart: false` to disable the workbench defaults. Supply
`onTableRowFocused`, `onTableRowFocusCleared`, `onTableRowHoverChanged`, or
`onTableRowActivated` to replace individual defaults with product-specific
behavior. Use
`onPointLinkError` to observe the same structured error shown by the workbench.

## Configure the data table

Pass `ChartTableOptions` directly to the workbench:

```dart
BravenChartWorkbench(
  tableOptions: const ChartTableOptions(
    rowLayout: ChartTableRowLayout.wide,
    dataScope: ChartTableDataScope.visibleSeries,
    viewportOnly: true,
  ),
  documentOptions: ChartDocumentExtractOptions(
    includeViewState: true,
    yAxisFormatterDescriptors: {
      'y': ChartFormatterDescriptor(
        id: 'braven.number.fixed',
        arguments: {'decimals': JsonNumberValue(2)},
      ).toDocument(),
    },
  ),
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
  ),
)
```

Wide layout produces one shared X column plus a value column for each series.
Long layout produces one row per point. `ChartDataTable` retains its native
sorting, bounded whole-dataset clipboard copy, per-row copy, and raw CSV export
inside the workbench. Sorting changes presentation order only; point references
continue to address the original effective document indices.

Changing `tableOptions` affects the next projection. Call `refreshTable()` if a
table is already visible and must immediately use the new options.

## Status and failures

Use `onStatusChanged` when status must leave the workbench subtree:

```dart
BravenChartWorkbench(
  onStatusChanged: (status) {
    analytics.record(
      requestedMode: status.requestedMode,
      effectiveMode: status.effectiveMode,
      tablePhase: status.table.phase,
      artifactPhase: status.artifact.phase,
    );
  },
  // ...
)
```

Expected operational failures use `ChartArtifactResult`,
`ChartArtifactError`, and `ChartArtifactWarning`. Important workbench codes are:

- `chart_not_attached`: the operation ran without a mounted chart;
- `capture_in_progress`: a second artifact request arrived while one was active;
- `requested_display_mode_unavailable`: the requested mode is host-disabled;
- `table_projection_failed`: extraction succeeded but the table could not be
  projected;
- `stale_point_reference`: the supplied ref came from a different effective
  document revision; and
- `invalid_point_reference`: the series ID or point index does not exist in the
  current effective document.

Display the code and message where useful for support, but write user-facing
recovery copy for your product. Programming errors such as attaching one
`ChartWorkbenchController` to two simultaneous workbenches still throw
`StateError`.

The package-owned failure presentation always pairs the error with a recovery
action: **Retry table** when no usable table exists, or **Retry refresh** while
the previous table remains available. Warning, failure, table, and artifact
states remain independently observable through `ChartWorkbenchStatus`.

## Controller ownership

The workbench disposes only controllers it creates. If you supply any of these,
you retain ownership and must dispose them:

- `chartController`;
- `workbenchController`; and
- `tableController`.

One workbench controller can be attached to only one mounted workbench at a
time. A caller-owned controller can be detached and reused after the previous
workbench unmounts.

## Scope boundary

The workbench composes one chart and its data. It does not persist artifacts or
align multiple documents. A comparison library can use host actions to capture
artifacts now, then hydrate each saved document into an independent workbench.
Cross-document series mapping, X alignment, and deltas require an explicit
comparison model rather than name-based guessing.

For the transport, validation, hydration, preview, and external-payload
contracts behind workbench extraction, continue with
[Portable Chart Artifacts](chart_artifacts.md).
