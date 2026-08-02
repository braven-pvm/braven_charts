# Heatmap Density Raster — Phase 2 Slice Contract

**Date:** 2026-07-30
**Register:** `BC-0043`
**Branch:** `feature/BC-0043-heatmap-histogram`
**Depends on:** the accepted 2D-histogram slice and `BC-0037`

## Outcome

Developers can transform raw numeric X/Y observations into a deterministic
kernel-density raster and render that raster as ordinary Heatmap cells while
retaining the local source identities required for inspection.

## Product boundary

Density estimation remains a typed data transform. It does not add a second
Heatmap painter or hide aggregation inside Scatter rendering. The transform
owns explicit domains, regular sample grids, kernel choice, bandwidth,
finite-support evaluation, and source provenance. Its output uses the existing
Heatmap renderer, interaction, table, artifact, Source, Workbench, animation,
and accessibility paths.

Contour geometry is deliberately not inferred from the raster in this slice.
Contours need their own typed topology, hit testing, artifact shape, and
composition decision.

## Public contract

- `HeatmapDensityObservation` owns finite X/Y coordinates, a non-negative
  weight, an optional durable key, and optional host metadata.
- `HeatmapDensityAxis` owns an explicit finite domain and a positive number of
  regular cells. Cell centers and display labels are deterministic.
- `HeatmapDensityKernel` supports Gaussian and Epanechnikov kernels.
- Gaussian evaluation is explicitly truncated at a configurable positive
  radius measured in bandwidths. Epanechnikov has its natural unit support.
- X and Y bandwidths are finite and strictly positive.
- Density is the weighted product-kernel estimate divided by total source
  weight and the X/Y bandwidth product.
- Every density cell retains the input indices and durable keys of the exact
  non-zero contributors under the selected finite support.
- Relative-density output is normalized by the maximum cell density and
  remains zero for an all-zero source.
- Output cells have stable row/column identities and carry JSON-safe domain,
  kernel, bandwidth, absolute density, relative density, and contributor
  metadata.

## Deferred from this slice

- contour extraction and contour labels;
- adaptive or data-selected bandwidths;
- FFT or separable-convolution acceleration;
- irregular grids;
- rectangular brushing;
- tiled, streamed, or image-backed density sources;
- raw-observation artifact codecs that rerun the estimator after hydration.

These remain explicit `BC-0043` work and must not be claimed from a raster
showcase.

## Verification

- validation, support, and stable-grid tests;
- weighted Gaussian and Epanechnikov evaluation;
- bandwidth behavior and relative normalization;
- contributor identity and outside-domain source behavior;
- artifact, table, generated-source, and generated-Dart compilation proof;
- one production-shaped density Heatmap with live bandwidth controls;
- focused transform benchmark before promotion.
