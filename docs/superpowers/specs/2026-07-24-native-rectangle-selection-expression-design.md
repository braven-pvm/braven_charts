# Native Rectangle Selection Expression

**Register:** `BC-0008`
**Status:** Contract approved for implementation by the active lane
**Lane:** `feature/native-rectangle-selection-expression`

## Goal

Represent Cartesian rectangle selection as compact, portable two-axis intent
instead of materializing every selected point identity.

The public contract must preserve the existing selection expression rule:
top-level clauses are additive unions. A rectangle clause is the one
well-defined exception inside a clause: its X and Y predicates are
conjunctive.

```text
expression = clause OR clause OR clause
rectangle clause = X interval AND Y interval
```

This deliberately does not introduce arbitrary boolean expression groups.
Subtraction, negation, nested groups, precedence, and general-purpose boolean
algebra remain outside the public API.

## Public clause

Add `ChartSelectionRectangleClause` with:

- finite inclusive `minimumXInclusive` and `maximumXInclusive`;
- finite inclusive `minimumYInclusive` and `maximumYInclusive`;
- optional `seriesIds` targeting with the existing interval semantics:
  - `null` targets every resolved series;
  - an empty set targets no series;
  - a non-empty set targets only those series.

A point matches only when:

1. its finite X value is inside the closed X interval; and
2. its complete semantic Y span intersects the closed Y interval.

The Y rule reuses `chartSelectionPointIntersectsYInterval()`. Range Area
low/high pairs and Candlestick wicks therefore remain atomic marks rather than
being reduced to midpoint or close values.

## Multi-axis contract

Rectangle bounds are expressed in the native data space of every targeted
series. A clause targeting several series applies the same numeric Y interval
to each of them.

One visual rectangle on independent Y axes does not represent the same native
Y values for every series. Acquisition must therefore resolve the plot-space
rectangle through each participating series transform and emit one rectangle
clause per series:

```text
rectangle(x: 10-20, y: 40-60, seriesIds: {power})
OR
rectangle(x: 10-20, y: 120-150, seriesIds: {heartRate})
```

This is compact in series count and keeps top-level union semantics correct.
Transpose and axis placement do not alter the expression; the renderer-owned
transform seam remains responsible for plot-to-data conversion.

## Selection operations

- `replace`: store the acquired rectangle clauses.
- `add`: union the previous compact expression with the new rectangle clauses.
- `subtract` and `toggle`: retain the exact already-resolved identities when a
  general compact set difference cannot be represented.

Persistent Box movement and resizing always use `replace`, so the primary
product path remains compact.

## Portable document

Add `rectangle` to `ChartSelectionClauseDocumentKind`.

The rectangle document fields are:

- `minimumXInclusive`;
- `maximumXInclusive`;
- `minimumYInclusive`;
- `maximumYInclusive`;
- optional `seriesIds`.

Existing document kinds and JSON remain unchanged. Older documents hydrate
without migration. A reader that predates the new kind will continue to reject
unknown kinds explicitly rather than silently changing meaning.

Generated Dart source must emit
`ChartSelectionClauseDocument.rectangle(...)`.

## Runtime and revision behavior

Rendering, snapshots, Workbench tables, selection projection, and linked
consumers resolve the clause against the current effective series.

- Missing targeted series resolve no points for that target.
- Empty `seriesIds` resolve no points.
- Invalid or gap points never match.
- Compatible reorder/insertion/removal re-resolves from geometry.
- Replacement data does not gain broader compatibility guarantees beyond the
  current expression and point-key contracts.

Structured artifact/controller surfaces must retain their existing diagnostic
boundary. The low-level immutable clause follows the existing interval-clause
constructor invariants.

## Performance

- Ordered-X series use binary search to restrict the candidate span before
  applying the Y predicate.
- Unordered-X series scan only targeted series.
- Lazy summary paths stream matching points without materializing point refs.
- Memory stays proportional to clause count, not selected-point count.

Focused benchmarks cover 5,000, 100,000, and 1,000,000 observations before the
item is complete.

## Delivery checkpoints

1. Public clause, JSON document, resolver, rendering predicate, lazy summary,
   and generated-source round trip.
2. Rectangle gesture and persistent Box integration with per-series native Y
   bounds.
3. Controller, artifacts, Workbench, extraction, diagnostics, and revision
   tests.
4. Dense benchmarks and complete release gates.

The first review checkpoint follows Checkpoint 2, when the Selection Lab's Box
tool visibly retains compact intent while preserving the approved interaction.
