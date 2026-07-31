# Chart Workbench

`BravenChartWorkbench` keeps one `BravenChartPlus` mounted while exposing
Chart, Data, Split, and generated Dart Source views of the same effective
document. Host actions can extract a portable artifact without transferring
storage, permissions, or workflow policy into the package.

Use `BravenChartPlus` directly when a screen only needs an interactive chart.
Add `BravenChartWorkbench` when the same user also needs to inspect exact
values, compare chart and data side by side, copy effective Dart, or send the
current chart into a host-owned workflow such as **Add to report**.

## Choose the right layer

| Need | Use |
| --- | --- |
| One interactive chart | `BravenChartPlus` |
| Chart, Data, Split, Source, or host actions around that chart | `BravenChartWorkbench` |
| A chart that can cross a screen, session, service, or person | `ChartArtifact` |
| Explicit alignment and deltas across saved documents | `ChartComparisonBuilder` |

The Workbench is a presentation wrapper around one mounted chart. It is not a
chart type, storage layer, report builder, upload service, or permission
system:

```text
BravenChartPlus
      ↓
Workbench: Chart · Data · Split · Source
      ↓ extractArtifact()
your application: save · attach · share · compare · discard
```

Nothing is persisted until the application handles the successful artifact
result.

## Read the showcase as four proofs

Use the [live Workbench showcase](https://braven-pvm.github.io/braven_charts/#/braven_charts/?page=chart-workbench)
as a guided product journey:

1. **Linked views:** switch views without remounting the chart; table rows and
   chart points share durable identities.
2. **Host action:** **Add to report** returns a portable artifact with JSON,
   diagnostics, and an optional PNG preview. The demo displays it; the host
   chooses where it goes.
3. **Independent copies:** current, plan +5%, and plan -8% are separate
   portable documents hydrated with separate controllers. The comparison API
   aligns their source data without coupling their runtimes.
4. **Freshness:** the live chart can advance while the Data view remains a
   deliberate snapshot until refresh.

The comparison is an example built from artifacts, not hidden Workbench
storage or automatic version history.

The page uses deterministic generated stories across Cartesian, range, and
radial chart families. Regenerating changes the chart family, data, theme, and
series shape while preserving the Workbench contract.

The complete package guide, API examples, responsive Split behavior, and host
action contract live in
[doc/chart_workbench.md](../../doc/chart_workbench.md).
