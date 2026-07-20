# Chart Workbench

`BravenChartWorkbench` gives one mounted `BravenChartPlus` native Chart, Data,
Split, and generated Dart Source presentations plus a safe extension point for
host actions. It owns the generic presentation and extraction lifecycle; your
application still owns the chart configuration, persistence, permissions,
navigation, and action policy.

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

The workbench keeps the chart subtree mounted in every mode:

- `ChartDisplayMode.chart` shows the interactive chart;
- `ChartDisplayMode.data` shows a table derived from the chart's effective
  document while the chart remains mounted underneath; and
- `ChartDisplayMode.split` presents both surfaces when enough width is
  available; and
- `ChartDisplayMode.source` shows deterministic Dart generated from the same
  effective document used by Data and portable artifacts.

Source is opt-in so adding the current package version does not change an
existing Workbench control:

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
    series: series,
  ),
)
```

The table is never reconstructed from pixels or widget inputs. It comes from
`BravenChartController.extractDocument()`, so controller changes, resolved
series state, annotations, and requested durable view state follow the same
artifact extraction boundary.

## Shared presentation scope

Use `ChartWorkbenchGroupController` when multiple Workbenches should present
one consistent Chart, Data, Split, or Source preference. `ChartWorkbenchScope`
applies that controller to every Workbench in its subtree:

```dart
class AnalysisScreenState extends State<AnalysisScreen> {
  final presentation = ChartWorkbenchGroupController(
    initialDisplayMode: ChartDisplayMode.chart,
  );

  @override
  void dispose() {
    presentation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartWorkbenchScope(
      controller: presentation,
      child: const AnalysisCharts(),
    );
  }
}
```

Selecting a mode in any attached Workbench—or calling
`setDisplayMode()` on one of its `ChartWorkbenchController`s—updates every
Workbench in the scope. The shared controller also owns selector visibility:

```dart
presentation.setDisplayMode(ChartDisplayMode.split);
presentation.setShowModeSwitcher(false);
```

`showModeSwitcher: false` on an individual Workbench remains a local capability
gate: a group may hide or reveal eligible selectors, but cannot force a locally
disabled selector to appear. Host actions remain visible when the selector is
hidden.

The group's `availableDisplayModes` is the intersection supported by every
mounted member. If a newly mounted chart cannot support the current preference,
the group reconciles all members to Chart when available, otherwise to their
first common mode. Requests outside the intersection return a structured
failure without changing the group.

Scopes are nestable. Put one controller above the application shell for a
system-wide preference, or insert a nearer scope around a Line, Bar, or radial
chart subtree for a chart-family preference. An explicit `groupController` on
`BravenChartWorkbench` takes precedence over the nearest inherited scope.
Split ratio, compact Split pane, table/source freshness, focus, and chart
interaction state remain local to each Workbench.

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

Horizontal Split mode can auto-fit the table to its native column footprint,
capped by `maximumAutoTablePaneExtent`. The chart retains
`minimumChartPaneExtent`; the table retains `minimumTablePaneExtent` and uses
its native horizontal scrollbar if all columns cannot fit.

The divider is resizable by default. Users can drag its 12-pixel pointer strip,
focus its 48-pixel semantic lane and use arrow keys, or press Escape/double-
click to return to the configured automatic sizing. Configure this behavior
with:

```dart
BravenChartWorkbench(
  autoFitTablePane: true,
  isSplitResizable: true,
  minimumChartPaneExtent: 320,
  minimumTablePaneExtent: 360,
  maximumAutoTablePaneExtent: 640,
  splitGap: 16,
  onSplitRatioChanged: (chartShare) {
    // Optionally retain the user's effective chart/table preference.
  },
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
  ),
)
```

Set `autoFitTablePane: true` to enable content-aware sizing; otherwise
`splitRatio` defines the initial layout. Set `isSplitResizable: false` for a
deliberately fixed product surface.

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

### Put the same host action on the chart

Host actions can be exposed independently in three places: the Workbench action
row, the chart's native context menu, and a compact button over the chart. The
context menu and chart button are hidden unless their builders are supplied.
On a Workbench every builder receives the same stable
`ChartWorkbenchHandle`:

```dart
BravenChartWorkbench(
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
    contextMenuConfig: const ChartContextMenuConfig(
      enableLongPress: true,
    ),
  ),
  contextActionsBuilder: (context, handle, invocation) => [
    ChartContextAction(
      id: 'host.addToReport',
      label: 'Add to report',
      icon: Icons.bookmark_add_outlined,
      enabled: !handle.isExtractingArtifact,
      onSelected: () async {
        final result = await handle.extractArtifact(
          const ChartArtifactExtractOptions(
            artifactId: 'report-chart-42',
            includePreview: true,
          ),
        );
        // The host decides how to present or persist result.
      },
    ),
  ],
  chartActionButtonBuilder: (context, handle) => ChartOverlayAction(
    id: 'host.addToReport',
    tooltip: 'Add chart to report',
    semanticLabel: 'Add the current chart to the report',
    icon: Icons.bookmark_add_outlined,
    enabled: !handle.isExtractingArtifact,
    onPressed: () async {
      await handle.extractArtifact(
        const ChartArtifactExtractOptions(
          artifactId: 'report-chart-42',
          includePreview: true,
        ),
      );
    },
  ),
  chartActionButtonConfig: const ChartOverlayActionButtonConfig(
    alignment: Alignment.topLeft,
    margin: EdgeInsets.all(8),
    iconSize: 18,
  ),
)
```

`chartActionButtonBuilder` returning `null` hides the button for the current
state. `ChartOverlayActionButtonConfig` controls alignment, margin, target size,
icon size, and optional `ButtonStyle`. The default uses the inherited
`ColorScheme` with a translucent, zero-elevation surface that becomes clearer
on hover, focus, and press. Its 48 logical-pixel target is deliberately larger
than the icon for touch and keyboard accessibility. This is a host action
surface, not portable chart configuration, so callbacks are not serialized
into a `ChartDocument` or generated Dart source.

Override only the Material properties your product owns:

```dart
chartActionButtonConfig: ChartOverlayActionButtonConfig(
  style: IconButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
    backgroundColor: Theme.of(context)
        .colorScheme
        .primaryContainer
        .withValues(alpha: 0.72),
  ),
),
```

Developers can also render a completely external button through
`actionsBuilder` or their own application layout when an overlay does not suit
the product.

The builder works whether or not the chart has an `AnnotationController`.
Package annotation commands and host commands are composed in deterministic
groups: target editing, host commands, annotation creation, then destructive
commands. Duplicate action IDs keep the first registered action.

`ChartContextInvocation` contains only stable public information:

- `source` distinguishes secondary click, keyboard, and long press;
- `localPosition` and `globalPosition` locate the invocation;
- `hit` identifies a background, series, data point, or annotation without
  exposing private render elements; and
- `capabilities` describes whether annotations and a resolved data hit are
  available.

Mouse and trackpad secondary click are always supported. The Context Menu key
and Shift+F10 open the same menu at the focused or selected datum, falling back
to the plot center. Touch/stylus long press is deliberately opt-in through
`ChartContextMenuConfig.enableLongPress` so existing pan and zoom gestures do
not change silently. Menu rows provide 48 logical-pixel targets, keyboard
navigation, visible focus, theme-derived colours, assistive semantics, and
viewport clamping.

For a chart outside a Workbench, set
`BravenChartPlus.contextActionsBuilder` and/or
`BravenChartPlus.chartActionButtonBuilder` directly. Use these lower-level
forms when the action does not need artifact or Workbench state:

```dart
BravenChartPlus(
  series: series,
  contextActionsBuilder: (context, invocation) => [
    ChartContextAction(
      id: 'host.inspectPoint',
      label: 'Inspect point',
      enabled: invocation.hit.kind == ChartContextHitKind.point,
      onSelected: () => inspect(invocation.hit),
    ),
  ],
  chartActionButtonBuilder: (context) => ChartOverlayAction(
    id: 'host.saveChart',
    tooltip: 'Save chart',
    icon: Icons.save_outlined,
    onPressed: saveCurrentChart,
  ),
)
```

The chart releases its interaction coordinator before awaiting a selected
action, reports builder/callback failures through Flutter's error pipeline, and
restores chart focus when the menu closes. Actions should still perform their
own permission and lifecycle checks because the host owns action policy.

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
final sourceResult = await workbenchController.refreshSource();
```

`setDisplayMode` returns `ChartArtifactFailure` with
`requested_display_mode_unavailable` when the host excluded that mode through
`availableDisplayModes`. It does not throw for a normal unavailable-mode
request.

The handle and controller expose:

| Member | Meaning |
| --- | --- |
| `chartController` | Controller attached to the currently mounted chart |
| `requestedMode` | User-selected Chart, Data, Split, or Source preference |
| `effectiveMode` | Presentation actually visible at the current width |
| `tableSnapshot` | Immutable effective document used for the current table |
| `tableModel` | Current projected table, when ready |
| `tableIsStale` | Whether the chart revision moved past the table snapshot, including after a failed refresh |
| `tableState` | Table phase, model, warnings, and structured error |
| `artifactState` | Independent artifact-extraction phase, result, warnings, and error |
| `sourceState` | Independent source phase, snapshot, generated Dart, warnings, and error |
| `generatedSource` | Most recent usable `ChartGeneratedSource`, when ready |
| `sourceIsStale` | Whether the chart revision moved past the generated source |
| `refreshTable()` | Coalesced document extraction and table projection |
| `refreshSource()` | Coalesced effective-document extraction and Dart generation |
| `extractArtifact()` | Atomic document and optional preview extraction |

Table extraction and artifact extraction have separate state. A table refresh
does not erase an artifact result, and an artifact failure does not replace a
usable table.

## Generated Dart Source

Source is generated from the chart's effective mounted document—not from
pixels and not by replaying the host widget builder. It therefore reflects
resolved series, axes, annotations, built-in or resolved custom themes,
interaction options, and other portable configuration captured at that
revision. Canvas legends retain their series, labelled trends, style, hidden
state, and custom position.

```dart
BravenChartWorkbench(
  availableDisplayModes: const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
  sourceOptions: const ChartDartSourceOptions(
    includeImports: true,
    includeViewState: false,
    maxInlinePoints: 250,
    variableName: 'chart',
  ),
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: series,
  ),
)
```

The built-in Source surface provides selectable highlighted Dart, line
numbers, line wrapping, exact clipboard copy, freshness state, and explicit
warnings. It never silently samples a large dataset. When the configured
`maxInlinePoints` ceiling is exceeded, all point lists are replaced by clear
application-data placeholders and the result reports the omitted count.

Portable document and artifact extraction remains fail-closed when a runtime
callback or formatter has no host descriptor. Source uses a separate capture
adapter: it preserves host descriptors, creates stable source-only placeholders
for missing runtime values, and reports them in the Source diagnostics. The
generated Dart includes the portable configuration and marks the application
callbacks that still need to be supplied; Source never weakens artifact
portability rules.

Source is a live developer projection by default. While Source is visible,
`ChartSourceRefreshPolicy.onDocumentRevision` coalesces effective chart changes
onto a bounded 250 ms cadence and regenerates the Dart without exposing normal
revision movement as a manual stale state. Changes made while Source is hidden
are generated when Source next becomes visible. A failed regeneration retains
the previous usable source and exposes an explicit retry.

`ChartSourceRefreshPolicy.manual` and `onModeEntry` remain available for hosts
that intentionally want retained source snapshots or only want regeneration
when entering Source. Source and table policies remain independent: Data keeps
its snapshot-oriented `onModeEntry` default.

Set `includeViewState: true` when the copied result should also retain the
current viewport, hidden series, durable point selection, axis slots, selected
annotation, and canvas-legend position. The generated Dart then declares a
`BravenChartController`, attaches it to the chart, and includes a named restore
function with a clear call-after-mount instruction. View state stays off by
default so the usual copied result remains reusable across sessions.

Resolved custom themes are emitted as complete public `ChartTheme`
configuration. Series-theme markers use `SeriesMarkerShape` in copied Dart so
they remain distinct from point-annotation `MarkerShape`.

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
- Ctrl/Command-click or Ctrl/Command-Enter additively selects an unselected
  row and removes every point represented by an already selected row;
- Shift-click or Shift-Enter replaces selection with the contiguous row range
  from the last unmodified activation, following the current table sort;
- Ctrl/Command+Shift activation additively selects that sorted row range;
- Ctrl/Command+A selects every point in the current sorted table projection,
  while Escape clears durable selection and keeps row focus in place;
- Home and End move focus to the first or last displayed row, while Page Up
  and Page Down move by the current virtualized viewport height;
- selected chart points are mirrored into the table with a themed row fill,
  persistent leading indicator, and selected semantics; and
- the table summary reports the selected point count and exposes a compact
  Clear selection action that keeps subsequent row references current;
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

Supply `ChartDataTable.onClearSelection` to expose the summary toolbar's Clear
selection action for standalone tables. The table reports point count rather
than row count because a shared-X row can represent several selected points.

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
`onTableRowActivation` to replace individual defaults with product-specific
behavior. `onTableRowActivation` receives modifier-aware
`ChartTableRowActivationDetails`; Shift ranges arrive as the complete ordered
point collection and take precedence over the legacy
`onTableRowActivated` callback when both are supplied. Override
`onTableSelectAllPoints` or `onTableSelectionCleared` when the host owns those
keyboard selection commands. Use
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

For the complete contract a future chart family must satisfy before Data,
Source, artifacts, and the Workbench can support it, see
[Chart family integration](chart_family_integration.md).
