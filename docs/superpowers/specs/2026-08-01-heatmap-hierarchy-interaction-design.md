# Heatmap hierarchy interaction design

Status: review candidate
Register: BC-0049
Depends on: BC-0043

## Purpose

Add deterministic hierarchy inspection and explicit collapse/expand to the
standalone Heatmap dendrogram without moving hierarchy composition,
clustering, aggregation, or viewport ownership into the retained Heatmap
renderer.

## Architecture boundaries

- `HeatmapDendrogramData` remains the immutable source of visible hierarchy
  identity and geometry.
- One projected screen-space layout drives both painting and hit testing.
- Hover is ephemeral, keyboard focus is navigational, durable selection is
  inspectable state, and collapse is an explicit matrix projection. These
  states are independent even when they refer to the same node.
- The host owns hierarchy projection and aggregation. It passes ordinary,
  immutable Heatmap points and labels to the existing renderer.
- The core retained renderer, viewport source, tile cache, and clustering
  implementation are unchanged.

## Interaction geometry

`HeatmapDendrogramLayout` projects normalized hierarchy coordinates to screen
space and exposes only the segments accepted by the active LOD policy.
`HeatmapDendrogramHitTestMap` snapshots node anchors and those accepted branch
segments. Hit testing is pure and deterministic:

1. find node anchors within the node radius;
2. choose the closest, then stable node ID;
3. otherwise find accepted branch segments within the branch radius;
4. choose the closest, then stable segment ID;
5. otherwise return no hit.

The map is rebuilt only when accepted data, canvas size, or
interaction-relevant style changes. Pointer motion therefore performs bounded
distance checks over an immutable snapshot and never reclusters data.

Pointer hover/tap, short touch activation, physical keyboard traversal,
selection, and semantics share the same public target identity. Touch drags
remain available to the enclosing page. Suppressed LOD branches are neither
painted nor interactive.

Transient hover and keyboard focus follow the exact node or line segment under
inspection. Durable branch selection instead paints the complete visible
three-segment merge glyph for the selected hierarchy node. A low-opacity outer
stroke and crisp theme-colour inner stroke communicate cluster membership
without adding a rectangular hit-box treatment or relying on colour alone.
Normal and selected branches use the same elbow-radius, cap, join, and
quadratic merge-path construction, so the selection follows the exact visible
branch shape. This bounded foreground paint does not change dendrogram
geometry, hit testing, hierarchy projection, or the core Heatmap renderer.

## Collapse and projection

`HeatmapHierarchyCollapseState` stores immutable collapsed node IDs separately
for row and column hierarchies. Collapse is explicit: selecting a node only
inspects it; a host action collapses or expands the selected branch.

`HeatmapHierarchyProjection` walks the accepted source hierarchy and produces
visible terminal groups. A collapsed branch becomes one terminal group with
its original source indices and labels; descendants remain in the collapse
state so nested choices survive a parent collapse/expand cycle. IDs that do
not belong to the accepted hierarchy are reported as ignored rather than
silently changing source identity.

`HeatmapHierarchyMatrixProjection` combines the row and column projections and
reduces each visible cell with an explicit `mean`, `sum`, `minimum`, or
`maximum` reducer. Missing-only groups remain explicit missing cells.
Aggregated cells retain provenance for:

- row and column hierarchy node IDs;
- original row and column source indices and labels;
- contributing source point keys;
- reducer and measured/source cell counts.

One-to-one visible cells retain the original cell metadata. The resulting
labels, points, hierarchy geometry, and matrix dimensions all derive from the
same immutable projection.

## Portability and compatibility

Collapse state, visible groups, terminal-node identity, reducer choice, and
cell provenance are JSON-serializable and appear in generated Workbench Dart
source. Older dendrogram documents that omit `isTerminal`, `visibleGroups`, or
`collapseState` hydrate with their original leaf behavior.

## Showcase review contract

The clustered-matrix preset exposes hierarchy interaction, reducer selection,
explicit collapse/expand actions, and Workbench Chart/Data/Split/Source modes.
Selecting a row target clears the column target and vice versa, keeping the
action target unambiguous. The showcase can collapse the full column root from
64 cells to 8 and restore all 64 cells without losing source provenance.

## Verification

- 37 focused model, layout, painter, interaction, keyboard, touch,
  accessibility, serialization, compatibility, and projection tests pass.
- 14 Heatmap showcase tests pass, including collapse/expand and generated
  source provenance.
- `flutter analyze lib` passes.
- `dart run tool/check_dart_format.dart` passes for 232 files.
- `flutter build web --release` passes, including the Wasm dry run.
- Release review route:
  `http://127.0.0.1:8196/?page=heatmap-charts&preset=clustered`.
