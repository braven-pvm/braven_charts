# Heatmap portable provider runtime binding

**Register:** BC-0050 P1 and I1 gate 4  
**Status:** implemented for review

## Purpose

A viewport-backed Heatmap artifact must be able to describe how a host can
reconnect its resident snapshot to live, host-owned data after hydration. The
artifact cannot serialize a `HeatmapTileSource`, callbacks, credentials,
transport clients, caches, subscriptions, or mutation history.

## Portable contract

Each viewport-backed Heatmap series may opt in with one
`HeatmapViewportProviderDescriptor` containing:

- a stable `providerId` resolved by the host;
- the target Heatmap `seriesId`;
- JSON-safe provider arguments; and
- a finite initial viewport.

Descriptors are stored under
`ChartDocument.configuration.heatmapViewportProviders`. Documents containing
them declare `series.heatmap.viewport-provider.v1`.

The document still contains the current immutable resident cells. Data,
Split, Source, table export, preview capture, and accessibility therefore
remain truthful snapshots and never imply that the conceptual matrix was
embedded.

## Runtime contract

The host registers allowlisted factories in
`ChartRuntimeBindings.heatmapViewportProviders`. A factory receives the
portable descriptor and decoded resident Heatmap series template, then returns
a `HeatmapViewportProviderRuntime` containing a host-owned
`HeatmapViewportController` and an explicit controller-disposal policy.

Hydration validates all of the following before returning a chart:

1. every descriptor targets exactly one decoded Heatmap series;
2. no series has more than one provider descriptor;
3. the provider capability is declared; and
4. every provider ID has a registered host factory.

An absent factory fails with `runtime_binding_required`; it does not silently
render a chart that appears live.

The hydrated widget creates fresh provider runtimes per mounted chart, loads
the descriptor's initial viewport, listens to immutable controller snapshots,
and materializes replacement Heatmap series. Viewport changes are forwarded to
the provider controllers. Home and R restore the descriptor's bounded initial
viewport rather than fitting the complete conceptual axis domain. The provider
descriptor owns this viewport behavior, so extraction does not also require a
duplicate `onViewportChanged` callback binding.

## Lifecycle and trust boundary

- Factories run only after an application explicitly supplies a registry.
- Factories may use credentials or transports held by the host, but those
  values never enter the descriptor or artifact.
- A runtime may transfer controller disposal to the hydrated chart or retain
  ownership in a longer-lived host scope.
- Renderer code never fetches, caches, subscribes, or resolves providers.
- Provider errors stay in `HeatmapViewportSnapshot`; the last complete
  resident series remains renderable.

## Verification

- descriptor JSON round-trip and malformed-input tests;
- extraction capability/configuration tests;
- missing-provider and wrong-series hydration failures;
- fresh runtime lifecycle and viewport-forwarding widget tests;
- Workbench Data/Source assertions proving resident-snapshot semantics; and
- a focused Massive matrix showcase descriptor using the procedural host
  source.

## Deferred

Clustering/aggregation pushdown remains a separate BC-0050 decision gate. This
contract does not make provider acquisition renderer-owned.

## Image-backed provider specialization

Image-backed Heatmaps use the same host-registry rule but retain a distinct
descriptor because pixels are a presentation layer rather than canonical
series data. `HeatmapRasterViewportProviderDescriptor` records:

- one stable provider ID and presentation-layer ID;
- an optional canonical semantic-series ID;
- a finite initial viewport;
- JSON-safe provider arguments;
- opacity and filter quality; and
- either `cell` or `hardFailure` fallback.

The document declares `series.heatmap.raster-provider.v1` and stores the
descriptor under `configuration.heatmapRasterViewportProvider`. It never stores
encoded images, decoded handles, caches, transports, credentials, callbacks,
or mutation history.

`ChartRuntimeBindings.heatmapRasterViewportProviders` resolves the descriptor
to a fresh `HeatmapRasterViewportProviderRuntime` per mount. When a runtime is
available, its controller supplies both borrowed raster resources and the
current bounded semantic companion. The captured semantic template is removed
from the base chart series for that mount so the controller can publish the
same stable series identity without collision. When the provider is absent and
the descriptor declares `cell`, the captured canonical series remains as the
truthful non-raster fallback. `hardFailure` instead returns
`runtime_binding_required`.

The Deep signal spectrogram showcase exercises this contract over a conceptual
512-million-cell source. Its first window mounts 12 decoded image tiles and
1,536 host-aggregated canonical cells. Workbench Data and generated Dart expose
those aggregates; the portable document additionally retains the provider
identity and reconstruction arguments.
