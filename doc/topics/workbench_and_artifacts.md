# Workbench and artifacts

These features share one effective chart document, but solve different product
problems:

- **Workbench** is the in-app presentation surface. It keeps one chart mounted
  while users move between Chart, Data, Split, and Source, link rows to points,
  and trigger host-owned actions.
- **Artifacts** are the portable boundary. They capture the chart's resolved
  data, configuration, durable view state, provenance, and optional preview for
  storage, transport, inspection, or fresh hydration.

Start with the Workbench when the user needs to explore a chart. Capture an
artifact when that chart needs to cross a screen, session, service, or person.
The package performs extraction and validation; the host still owns storage,
authorization, retention, and business workflow.

- [Workbench showcase](https://braven-pvm.github.io/braven_charts/#/braven_charts/?page=chart-workbench)
- [Artifact showcase](https://braven-pvm.github.io/braven_charts/#/braven_charts/?page=artifact-showcase)
- [Workbench guide](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_workbench.md)
- [Artifact contract](https://github.com/braven-pvm/braven_charts/blob/master/doc/chart_artifact.md)
