# Heatmap Matrix Clustering and Reordering Design

Date: 2026-07-30
Register: BC-0043
Status: implementation slice

## Outcome

Developers can cluster the rows and columns of a rectangular Heatmap,
inspect the deterministic hierarchy and leaf order, and render the reordered
result as ordinary Heatmap cells without changing the native renderer.

## Scope

This slice includes:

- validated rectangular matrix input with explicit row and column labels;
- optional independent row and column clustering;
- Euclidean and correlation distances;
- average, complete, and single linkage;
- explicit missing-value comparison semantics;
- stable hierarchy nodes and deterministic tie resolution;
- source-coordinate and source-cell identity retained after reordering;
- JSON-safe hierarchy and ordering metadata;
- a focused clustered-matrix showcase with live controls.

This slice does not include:

- a dedicated dendrogram painter or dendrogram interaction;
- optimal-leaf-ordering optimization;
- rectangular brush or row/column selection;
- irregular cells or multiple colour axes;
- tiled, streamed, or image-backed matrix sources.

## Public contract

`HeatmapMatrixClusterData` accepts canonical `HeatmapDataPoint` values plus
explicit row and column labels. Input coordinates must be integer category
centres inside the declared rectangle, and every coordinate must occur exactly
once. Explicitly missing cells are valid matrix members.

`HeatmapClusterConfig` controls:

- whether rows, columns, or both are clustered;
- Euclidean or Pearson-correlation distance;
- average, complete, or single linkage;
- whether missing pairs are ignored or treated as zero.

The result exposes:

- `rowOrder` and `columnOrder` as original category indices;
- reordered row and column labels;
- optional row and column `HeatmapClusterNode` roots;
- reordered canonical cells;
- JSON-safe hierarchy and ordering metadata.

Each output cell keeps its original `pointKey`, value, missing state, label,
styling, and host metadata. Added metadata records the original row/column
indices and labels plus the reordered indices. Reordering therefore changes
only spatial category coordinates, not logical cell identity.

## Distance and missing values

Rows are compared across columns and columns across rows.

Euclidean distance is the square root of the sum of squared differences,
scaled by `dimensionCount / comparableCount` when pairwise missing values are
ignored. Pearson distance is `1 - correlation`, clamped to `0..2`.
Constant equal vectors have zero correlation distance; other constant-vector
comparisons use distance one.

With pairwise-ignore semantics, two vectors with no comparable values have
infinite distance. They remain deterministic because cluster-pair ties and
infinite distances resolve by the smallest source leaf identity. With
missing-as-zero semantics, missing cells participate as zero.

## Hierarchy and deterministic ordering

Agglomerative clustering starts with one stable leaf per source category.
At each step the closest cluster pair is merged using the configured linkage.
Equal distances resolve lexicographically by the two clusters' smallest source
leaf indices.

Children are oriented by their minimum source leaf. `leafOrder` is the
left-to-right traversal of that stable hierarchy. Node identifiers are derived
from axis identity and sorted member indices, so repeated transforms of the
same input and configuration produce the same tree and order.

The hierarchy is serializable independently of Flutter rendering. A later
dendrogram composition can consume the accepted node contract without rerunning
clustering or inventing renderer-owned topology.

## Composition

The transform emits normal `HeatmapDataPoint` values at reordered category
coordinates. Hosts use the reordered labels in `CategoryAxisConfig`. Rendering,
interaction, tables, artifacts, generated Dart source, animation, and
accessibility therefore continue through the existing Heatmap paths.

## Review preset

The Heatmap showcase adds a `Clustered matrix` preset containing product
behavior signals whose related rows and columns begin deliberately separated.
Controls allow:

- row, column, or two-axis clustering;
- Euclidean or correlation distance;
- average, complete, or single linkage;
- pairwise-ignore or missing-as-zero semantics;
- toggling between source and clustered order.

The chart subtitle and Source metadata expose the effective configuration and
stable row/column permutations.

## Verification

- validation for rectangular coordinates, labels, duplicates, and empties;
- exact distance and missing-value semantics;
- deterministic linkage, ties, hierarchy identity, and leaf order;
- row-only, column-only, both-axis, and disabled transformations;
- stable point identity and original-coordinate provenance;
- hierarchy JSON round-trip;
- artifact, table, generated-source, and generated-Dart compilation proof;
- focused transform benchmark;
- showcase widget tests for routing and every live control;
- `flutter analyze lib`, repository format checker, release web build, and
  direct-route visual review.
