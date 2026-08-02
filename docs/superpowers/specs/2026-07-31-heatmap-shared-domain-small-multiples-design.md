# Heatmap shared-domain small multiples design

**Register:** BC-0043, slice S1
**Status:** Implementation
**Date:** 2026-07-31

## Problem

Independent Heatmaps auto-resolve their own minimum and maximum values. That is
correct for a single chart, but misleading in small multiples: the same colour
can represent different values in adjacent panels. A host needs one stable,
portable domain and usually one shared legend without merging the charts or
introducing a composition-specific renderer.

## Contract

`HeatmapSharedColorDomain` derives a finite minimum and maximum across one or
more `HeatmapChartSeries` values. Missing cells do not participate; finite zero
or other application-defined empty values do. The resolved domain and its
source-series provenance round-trip through JSON.

The domain can create a fixed-domain copy of a sequential or diverging
`HeatmapColorScale`. All other scale presentation is retained. A caller can
suppress legends on each panel and render one `HeatmapColorLegend` from a
representative series using the same fixed scale.

Threshold scales are intentionally excluded. They already share fixed semantic
boundaries when configured identically and do not own a continuous numeric
domain.

## Rendering boundary

Each panel remains a normal `BravenChartPlus` with its own axes, interaction,
selection, culling, and renderer lifecycle. The host owns only layout and the
shared domain/legend. This slice does not add multiple colour axes, legend
filtering, renderer-owned small multiples, or retained-renderer changes.

## Validation

- Reject non-finite or reversed domains.
- Reject an empty set of finite measured values.
- Reject negative or non-finite padding.
- Expand a constant-valued source by a deterministic minimal span.
- Require a diverging midpoint to fall inside the resolved shared domain.
- Prove JSON round-trip, immutable provenance, scale preservation, and
  artifact/source portability after applying the fixed domain.

## Showcase

The Heatmap Charts page gains a `Small multiples` preset with three compact
panels whose local ranges differ. A connected option toggles shared versus
independent domains and controls domain padding. Shared mode renders one legend
and makes equal colours comparable across panels; independent mode exposes why
per-panel auto domains answer a different question.
