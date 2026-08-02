# Heatmap dendrogram composition design

## Status

Implementation checkpoint for `BC-0043`.

## Outcome

Developers can render optional row and column dendrograms around a clustered
Heatmap without asking the renderer to cluster data or infer hierarchy.

The dendrogram consumes the portable `HeatmapClusterNode` hierarchy produced by
`HeatmapMatrixClusterData`. The accepted cluster order remains the single source
of truth for matrix categories, table rows, generated source, artifacts, and
branch layout.

## Contract

`HeatmapDendrogramData` converts one cluster root into stable, normalized branch
segments:

- category position runs from `0` to `1` in accepted leaf order;
- distance runs from `0` at leaves to `1` at the root;
- proportional distance preserves the clustering algorithm's merge distances;
- structural distance spaces merge levels evenly for a more legible hierarchy
  without changing membership or leaf order;
- source leaf indices and category labels remain attached to the layout;
- every branch segment has a deterministic identity derived from its cluster
  node;
- a zero-distance hierarchy falls back to structural depth so the topology
  remains visible;
- JSON output contains only portable scalar, list, and map values.

`HeatmapDendrogram` paints that geometry in either column or row orientation:

- column leaves align left-to-right and branches grow upward;
- row leaves align bottom-to-top and branches grow leftward, matching the
  native Heatmap category direction;
- presentation is theme-aware and subordinate to the matrix;
- a quiet leaf baseline and one tick per accepted category make the tree-to-
  matrix relationship visible without adding another labelled axis;
- semantics summarize the axis and category count;
- the widget owns no clustering, selection, or viewport state.

## Showcase composition

The clustered-matrix preset exposes independent row and column dendrogram
switches. A compact top band and left rail surround the existing chart only
when the corresponding hierarchy exists. Branch extent, stroke width, and
distance spacing are live options. Readable structural spacing is the showcase
default because correlation distance can compress the lower hierarchy into a
few pixels; proportional spacing remains available for analytical inspection.

While either hierarchy is visible, the showcase uses a fixed full-matrix
composition. Both native axes are hidden and their row labels, column labels,
and X-axis title are rendered by the host from the same category order. The
matrix, labels, and dendrograms all retain the chart's explicit 10 logical
pixel axisless plot inset, so every tree leaf shares an exact layout division
with its matrix category instead of relying on estimated axis gutters.

Zoom, pan, and the X scrollbar are intentionally disabled in this composed
hierarchy view. The public chart controller synchronizes X viewports but does
not expose a live plot rectangle or Y viewport, so moving an external row tree
with the renderer would require a new two-axis layout and viewport contract.
That expansion is excluded from this slice to avoid adding host-composition
work to the core render loop. Hiding both dendrograms removes the composition
and restores the ordinary visible axes, zoom, pan, and scrollbar.

## Initial hierarchy focus

A fixed initial focus is the accepted follow-up to the locked full-matrix
composition. It is a data-domain window, not a post-layout renderer zoom:

- the host chooses contiguous accepted row and column leaf ranges, or a complete
  hierarchy subtree, before building the composition;
- the matrix cells, host labels, and both displayed hierarchies are derived
  from the same focused leaf identities;
- hidden branches are pruned without re-clustering, changing source identity,
  or inventing a different leaf order;
- the focused composition remains locked while either hierarchy is visible;
- returning to the full hierarchy is deterministic and does not mutate the
  underlying clustered result.

The existing category-axis automatic viewport is not used for this purpose. It
is applied by the renderer after plot layout and currently initializes only the
native category viewport; external row labels, column labels, and dendrograms
cannot observe the resulting two-axis plot transform.

`HeatmapMatrixClusterFocusData` implements this contract as a reusable public
transform over an accepted `HeatmapMatrixClusterData`. Callers may select a row
and/or column subtree by its stable hierarchy node ID. The transform:

- resolves each node against the already accepted hierarchy;
- retains the selected subtree's accepted leaf order;
- emits a locally reindexed matrix carrying its original source and clustered
  coordinates plus focused coordinates in metadata;
- exposes focused row and column labels and portable focus metadata;
- rejects node IDs outside the accepted hierarchy.

The showcase exposes Full hierarchy, Primary cluster, and Secondary cluster as
fixed initial-focus choices. Each choice derives the matrix, host labels, row
tree, column tree, table projection, and generated source from the same focused
data object. Turning clustered order off returns to the full authored matrix.

## Branch presentation

`HeatmapDendrogramStyle` is the immutable presentation contract for the
standalone painter. It configures branch, leaf-baseline, and leaf-tick colours
and widths; branch caps and joins; guide visibility and tick length; and an
optional presentation-only elbow radius. Theme-derived colours remain the
default.

Rounded elbows are applied only while converting the accepted orthogonal
segments into a paint path. The radius is clamped to the adjacent segment
lengths and does not change hierarchy identity, merge distance, leaf order, or
portable geometry. One style serializes to JSON-safe row/column metadata so
artifacts and generated Source retain the effective host presentation.

## Markers and labels

`HeatmapDendrogramData` also retains one portable node anchor per hierarchy
node. A node anchor contains stable node identity, normalized category and
distance coordinates, the original clustering merge distance, member count,
and optional source-leaf identity. Branch segments remain the accepted
geometry contract; node anchors only expose positions already derived during
that same layout pass.

`HeatmapDendrogramStyle` keeps marker and label presentation opt-in:

- leaf and merge-node markers have independent visibility, radius, shape
  (`circle`, `square`, `diamond`, or `triangle`), and solid/hollow fill;
- marker fill, border colour, and border width are independently configurable
  for leaf and merge nodes, with branch colour as the border fallback;
- leaf markers terminate explicitly at the matrix-facing baseline: column
  markers retain their hierarchy-side upper half and row markers retain their
  hierarchy-side left half, avoiding host-layout-dependent overflow;
- leaf labels and merge-distance labels have independent visibility;
- merge labels display the original clustering distance even when structural
  branch spacing is selected;
- label density is deterministic (`all`, `balanced`, or `sparse`) and applies
  independently to leaf and merge candidates;
- labels use a configurable maximum character count and ellipsis;
- before/after placement is orientation-aware, and every painted label is
  shifted back inside the dendrogram canvas;
- marker painting and label layout do not mutate hierarchy geometry or add
  renderer-owned layout.

Marker configuration is JSON-safe and travels with the same effective host
style metadata used by artifacts and generated Source. Markers in this slice
are presentation-only. They do not install pointer hit targets or semantics
actions; branch/node hover, selection, and collapse remain the dedicated D4
interaction contract.

## Scale and level of detail

D5 keeps scale policy in the standalone dendrogram presentation layer. The
JSON-safe `HeatmapDendrogramStyle` exposes an automatic/disabled mode and
independent screen-space thresholds for branch length, leaf-guide spacing,
leaf-marker spacing, merge-marker spacing, and label spacing. Automatic mode
only suppresses presentation that was already enabled; it never turns hidden
guides, markers, or labels back on.

The painter caches its generated branch path while the same painter and canvas
size remain mounted. It suppresses a branch group only when every projected
segment is shorter than the configured threshold, retains the matrix-facing
baseline, samples labels deterministically, and uses screen-space collision
checks for merge markers. Leaf-guide and leaf-marker visibility derives from
the actual category spacing. Disabling level of detail restores every
explicitly enabled presentation element.

The regression envelope includes deterministic clustering of a 96 x 64
(6,144-cell) matrix, layout of a 512-leaf portable hierarchy, and 120 repeated
paints of that hierarchy. This establishes a representative performance guard;
it does not claim arbitrary massive-matrix storage or synchronous clustering.

## Remaining presentation and scale slices

Further dendrogram work remains deliberately independent:

- optional depth-level colours;
- branch or node hover/selection only after a dedicated hit-testing contract;
- broader clustering algorithms and storage strategies for genuinely massive
  matrices.

Clustering remains a data preparation step outside paint. Dendrogram painting
is linear in its generated branch-segment count, but readable labels and the
current agglomerative clustering implementation become the practical scale
limits well before the painter itself.

The chart series metadata includes dendrogram geometry alongside the existing
cluster configuration and hierarchy. This keeps Workbench Data, Split, Source,
and portable chart documents useful even though host layout remains an
application-level composition.

## Verification

- deterministic geometry and source-leaf identity;
- zero-distance structural fallback;
- JSON-safe geometry and presentation metadata;
- row and column painter orientation;
- theme resolution, painter invalidation, semantics, empty-size safety, and
  single-leaf alignment guides;
- showcase controls, hierarchy availability, source metadata, and mounted
  chart behavior;
- fixed hierarchy mode, exact shared plot insets, and restoration of normal
  Cartesian navigation when both hierarchies are hidden;
- focused-subtree identity, local matrix reindexing, portable focus metadata,
  and synchronized Full / Primary / Secondary showcase composition;
- focused package analysis and release web build before visual review.

## Explicit exclusions

- branch selection or collapse interaction;
- renderer-owned dendrogram layout;
- automatic plot-inset discovery;
- post-layout chart-controller zoom while external hierarchy is visible;
- alternative clustering algorithms;
- changing the accepted matrix order independently of its hierarchy.
