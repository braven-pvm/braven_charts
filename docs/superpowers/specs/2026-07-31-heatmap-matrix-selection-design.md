# Heatmap matrix selection design

**Register:** BC-0043
**Slice:** B1 -- rectangular cell brushing and row/column expansion
**Status:** implementation in progress

## Purpose

Heatmaps need matrix-aware selection without introducing a second gesture
system. This slice reuses Braven Charts' existing durable Cartesian selection
brush, controller state, keyboard path, and touch arbitration. Only Heatmap
hit acquisition and semantic expansion are specialised.

## Public contract

`ChartSelectionConfig` gains a Heatmap-only expansion policy:

- `cell` keeps the acquired source cells.
- `row` expands every acquired Heatmap cell to all source cells with the same
  Y identity in that series.
- `column` expands every acquired Heatmap cell to all source cells with the
  same X identity in that series.

The default is `cell`, preserving existing selection behaviour. The policy is
applied when the generic selection scope targets marks. Existing generic
category, stack, and whole-series scopes retain their current meaning.

The setting must round-trip through JSON artifacts, generated Dart source,
fluent/generated surfaces, and the showcase workbench.

## Acquisition semantics

For `ChartSelectionAcquisitionMode.rectangle`, a Heatmap cell is acquired when
its rendered cell rectangle overlaps the brush rectangle. This deliberately
differs from point-series centre containment and makes partial cell brushing
predictable.

The query first uses `HeatmapViewportIndex` to bound source candidates, then
performs exact rendered-rectangle overlap checks. It must not scan the complete
matrix for a small brush.

Lasso remains centre-based in this slice. Row/column expansion still applies
to cells acquired by taps, keyboard navigation, or lasso.

## Identity and filtering

- Expansion is confined to the source Heatmap series. It never links separate
  charts or series merely because their coordinates match.
- Missing cells retain source identity and may be selected.
- Cells hidden by `HeatmapValueFilterMode.hide` are not acquired. A row or
  column expansion also excludes hidden cells so the selected document matches
  what the user can see.
- Dimmed cells remain selectable.

## Interaction ownership

The native `ChartSelectionBrushConfig` remains the only persistent selection
geometry. Existing drag activation, page-scroll arbitration, pan/zoom rules,
modifier operations, resize handles, and controller publication are reused.
No Heatmap-specific recognizer or parallel brush state is added.

## Performance boundary

Rectangle acquisition is viewport-indexed and exact only over candidate cells.
Row/column expansion is a source-series scan performed when selection commits,
not during paint. Dense-matrix storage, irregular cell geometry, hierarchical
selection, and multi-colour-axis coordination remain separate Phase 2 work.

## Review preset

The Heatmap showcase exposes a dedicated matrix-selection example with:

- cell, row, and column expansion controls;
- a persistent rectangular brush;
- visible selected-cell feedback and a selected-count summary;
- instructions for drag, resize, clear, and modifier operations.

The example is the physical verification surface for mouse and touch gesture
coexistence before PR promotion.
