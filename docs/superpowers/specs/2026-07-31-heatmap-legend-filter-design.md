# Heatmap durable legend filtering design

**Register:** BC-0043, slice S2
**Status:** Implementation
**Date:** 2026-07-31

## Problem

A shared colour domain makes values comparable across independent Heatmaps,
but developers still need a durable way to focus the same numeric interval in
every panel. Rebuilding each panel from a reduced point list loses the original
matrix contract, makes tables and generated source misleading, and can
incorrectly turn filtered values into missing observations.

## Public contract

`HeatmapValueFilter` is an immutable, JSON-safe inclusive numeric window. Its
minimum and maximum are finite and ordered. `HeatmapValueFilterMode.dim` keeps
excluded cells visible at a configurable opacity; `hide` removes excluded
cells from painting and hit testing while retaining their source values in the
series, tables, artifacts, and generated Dart.

The optional filter belongs to `HeatmapChartSeries`. A null filter means that
all finite values participate normally. Missing cells remain governed solely
by `HeatmapColorScale.missingColor`, and application-defined empty values remain
governed by `HeatmapEmptyValueStyle`. Filtering does not change the resolved
colour domain.

## Legend contract

`HeatmapColorLegend` may receive a filter-change callback. For continuous
sequential and diverging scales it then presents an accessible inclusive range
control derived from the same resolved colour domain. Changing or clearing the
window returns a new `HeatmapValueFilter`; the host decides whether to apply it
to one chart or several independent charts.

Threshold-band filtering is deliberately deferred. Discrete band toggling has
different selection and empty-state semantics and should not be inferred from
a continuous range control.

## Rendering and interaction boundary

The existing Heatmap element performs one value-window check while resolving a
finite cell. Dim mode multiplies only that cell's resolved alpha. Hide mode
skips the cell in paint and exact hit testing. No points are removed, reordered,
or rewritten as missing, and viewport indexing is unchanged.

The filter is presentation state, not a data transform. Data tables therefore
retain every original row. Artifacts and generated source carry the filter so a
restored chart presents the same view.

## Showcase

The accepted `Small multiples` preset applies one filter to Checkout, Search,
and Reporting. One shared interactive legend edits the window; connected
options select dim or hide treatment, tune dim opacity, and clear the filter.
Each panel remains a normal independent `BravenChartPlus` without linked
selection, zoom, data, Source, or Workbench state.

## Validation

- Reject non-finite or reversed filter bounds.
- Require dim opacity to be finite and within zero and one.
- Preserve inclusive endpoints and finite zero.
- Keep missing and application-defined empty semantics independent.
- Prove series equality/copy, JSON/artifact round-trip, table preservation,
  generated Dart, widget interaction, hidden hit testing, and shared-showcase
  behavior.
- Re-run the existing large Heatmap renderer benchmark with filtering enabled
  to guard the retained paint path.

## Deferred

- Threshold-band toggling.
- Multiple colour axes or legends in one renderer.
- Renderer-owned small-multiple layout or linked chart interaction.
- Data deletion, aggregation, or query-provider pushdown.
