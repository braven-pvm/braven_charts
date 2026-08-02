# Heatmap multiple colour axes

## Purpose

Allow several Heatmap series in one native Cartesian chart to encode different
measured quantities without pretending that equal colours mean equal values.
Each series keeps its own value domain, colour ramp, title, unit, filtering,
and portable identity.

## Public contract

`HeatmapChartSeries.colorScale` remains the authoritative colour-axis contract.
No parallel chart-level scale registry is introduced. A chart may contain
several Heatmap series, and every renderer element continues to resolve colour
from the scale carried by its source series.

`HeatmapColorLegendGroup` presents the visible per-series scales together. It
accepts the source series in chart order, omits scales whose `showLegend` is
false, retains each series name beside its scale, supports horizontal wrapping
or vertical stacking, and can route filter updates by series ID. The existing
single-series `HeatmapColorLegend` remains unchanged and reusable.

## Runtime and interaction

This slice does not add work to the retained Heatmap paint loop: independent
per-series colour resolution already occurs inside each ordinary
`SeriesElement`. The new legend group is host/widget composition.

Keyboard navigation treats an all-Heatmap chart as one ordered collection of
series. Left/right and up/down continue to move through cells in the current
matrix; the existing series-navigation convention moves between Heatmap
series while preserving the closest cell position. Semantics identify the
focused series and report the total series and cell counts.

## Portable surfaces

Artifacts, generated Dart, AI configuration, fluent mutation, and Workbench
data already retain every Heatmap series and its own `colorScale`. Verification
must prove that two unlike scales round-trip together and that Workbench Data
and Source remain series-specific. No combined scale is synthesized.

## Showcase and verification

A focused `Colour axes` preset renders two non-overlapping Heatmap series in
one Cartesian chart: latency and error rate share time categories but use
different Y bands, domains, units, ramps, and legend entries. The preset
exposes independent legend filtering so one series can be dimmed without
changing the other.

Verification covers legend ordering/visibility/filter routing, multi-series
render colours and hit identity, keyboard/semantic traversal, artifact and
source fidelity, Workbench projection, AI construction, the direct showcase
route, and release web build.

## Exclusions

- a renderer-wide colour-axis manager or plot-side axis layout;
- shared colour domains (already covered by S1);
- cross-chart selection or viewport linkage;
- arbitrary polygon/mosaic cells;
- tiled or out-of-core storage.
