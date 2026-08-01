# Heatmap irregular cell rectangles

## Purpose

Add an opt-in geometry contract for Heatmap cells whose X and Y spans are not
uniform. This supports interval grids, unequal time windows, and other native
Cartesian matrices without turning Heatmap into a polygon, mosaic, or treemap
renderer.

## Public contract

`HeatmapCellBounds` stores finite `xMinimum`, `xMaximum`, `yMinimum`, and
`yMaximum` values. Both ranges must have positive extent. A
`HeatmapDataPoint` may carry one optional bounds object; its existing `x` and
`y` values remain the stable representative coordinate used by identity,
tracking, source data, and sorting, and must lie inside the rectangle.

Cells without explicit bounds continue to use the series-level `cellWidth` and
`cellHeight`. `gapFraction` is applied inside either resolved data rectangle
after projection, so gaps, rounded corners, selection, and hit testing retain
the same visual semantics.

## Runtime geometry

The existing row-based `HeatmapViewportIndex` remains the complete fast path
for regular cells. Explicit rectangles are excluded from those rows and added
to a secondary immutable interval tree that is created only when required.
Viewport and point queries merge source indices from both paths and retain
source paint order.

The interval tree is indexed on X bounds, stores the maximum X extent for each
subtree, and filters exact Y overlap at query time. It avoids a complete scan
without coupling data cells to the renderer's heavyweight `ChartElement`
quadtree. Exact projected rectangles remain authoritative for visual gaps and
topmost hit order.

Data bounds, culling, painting, semantic bounds, tracking, persistent
selection, and rectangle/lasso selection all resolve the same cell rectangle.
The renderer does not add a second geometry representation.

## Portable surfaces

The optional rectangle is encoded additively in the existing
`heatmap.cell.v1` point extension and round-trips through artifacts. Generated
Dart source emits `HeatmapCellBounds`. Workbench data exposes the representative
coordinate and the four optional boundaries when irregular geometry is
present.

## Showcase and verification

A focused irregular-cells preset demonstrates unequal X and Y spans, gaps,
tracking, and selection. Verification covers model validation, regular-path
diagnostics, mixed viewport and point queries, data bounds, rendering and hit
testing, artifact/source/table fidelity, and a release web build.

## Exclusions

- arbitrary polygons and mosaic/Marimekko layout;
- multiple colour axes;
- tiled or out-of-core storage;
- cross-chart linked selection;
- changes to the regular-grid query algorithm.
