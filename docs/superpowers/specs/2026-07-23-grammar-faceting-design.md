# Grammar Faceting (small-multiples) — Design

**Date:** 2026-07-23
**Status:** Approved (brainstorming). Next: implementation plan (writing-plans).
**Programme:** Fluent/Grammar-of-Graphics, Theme A — Breadth. First Breadth item after Convergence + Depth completed.

## Goal

Add `.facet(by:)` to the `BravenChart` grammar so one chart specification renders as **N synchronized small-multiple panels** — one per distinct value of a categorical field — laid out in a grid. This is the first Breadth item: it makes the grammar express a composition the config surface cannot, without any new coordinate system or render-pipeline change.

## Scope (first cut)

- **facet-wrap only** (1-D: partition by ONE field). facet-grid (2-D matrix) is explicitly out of scope, addable later without rework.
- **Scales:** `fixed` (default, both axes shared) | `freeX` | `freeY` | `free`.
- **Interaction:** **synchronized** across panels (shared crosshair-x + viewport) via the existing `ChartInteractionGroupController`.

## Approach (chosen: B — same builder + `buildFaceted()`)

`.facet(...)` is a verb on the existing `BravenChart<T>` builder that records an immutable `FacetSpec<T>`. A distinct terminal `.buildFaceted()` returns a new `BravenFacetPlot<T>` widget. The footgun (calling `.facet()` then a plain `.build()`) is closed by guards: `.build()` throws a grammar diagnostic when a facet is present (directing to `.buildFaceted()`), and `.buildFaceted()` throws when no facet was set.

Rationale: the whole feature is *composition* over primitives that already exist —
- `PlotSpec.lower()` → `LoweredPlot` (a spec → `BravenChartPlus` config) already exists;
- `BravenPlot<T>` already accepts a `ChartInteractionGroupController? interactionGroupController` (`braven_plot.dart:72`), so synced interaction is a matter of handing every panel the *same* controller;
- `ChartInteractionGroupController` (`lib/src/controllers/chart_interaction_group_controller.dart`) already synchronizes crosshair-x + viewport across member charts.

So a faceted render = *partition the rows → build N per-facet `PlotSpec`s (with shared/free ranges injected) → render N `BravenPlot`s in a grid, all wired to one shared controller.* The only genuinely new logic is the global-range computation and the grid/strip layout widget.

(Approaches A "typed facet transition" and C "internal to BravenPlot" were considered and rejected — A adds a builder type, C makes `BravenPlot` dual-purpose.)

## API surface

```dart
/// How axes scale across facet panels.
enum FacetScales { fixed, freeX, freeY, free }  // default: fixed

// New verb on BravenChart<T>:
BravenChart<T> facet(
  FieldAccessor<T, Object?> by, {   // categorical field: one panel per distinct value
  int? columns,                      // null = auto (≈ ceil(sqrt(N)))
  FacetScales scales = FacetScales.fixed,
  String? label,                     // optional strip-label prefix, e.g. 'Athlete'
});

// New terminal:
BravenFacetPlot<T> buildFaceted({ /* same host-facing params build() exposes */ });
```
`FieldAccessor<T, V> = V Function(T row)` (`channel.dart:19`). `FacetSpec<T>` is a grammar value (NOT `@chartSurface` — it holds an accessor function, exactly as `Mark` does).

## Semantics

### Partition & ordering
- Distinct facet values are derived from the rows via `by`, in **first-seen (data) order** — stable and predictable; the author pre-sorts rows for any other order.
- Each panel gets the row subset where `by(row) == value` (value equality; works for String/enum/num/bool categoricals).
- A **null** facet value is a valid distinct value → its own panel.
- **Cap:** default max **50** panels. Exceeding it is a grammar diagnostic (a chart authoring error), not a silent 200-panel render.

### Scale sharing
- A **shared** axis (`fixed`; or the non-free axis under `freeX`/`freeY`): compute the *global* min/max across ALL rows from the marks' x/y channels, and inject it as an explicit axis range (`XAxisConfig(min:,max:)` / `YAxisConfig(min:,max:)`) into every panel's `PlotSpec` before lowering → directly comparable panels.
- A **free** axis: leave the panel to auto-scale its own subset (inject no range override).
- Global-range computation reuses the marks' channel accessors over the full dataset; everything downstream is unchanged `PlotSpec.lower()`.

### Synchronized interaction
- `BravenFacetPlot` constructs **one** `ChartInteractionGroupController` and passes it to every panel's `BravenPlot`.
- **Caveat (explicit, documented):** a shared crosshair-x is only meaningful when x is shared. Sync is active for `fixed` and `freeY`. Under `freeX`/`free`, panels revert to independent interaction (each `BravenPlot` gets no shared controller) — documented, not silently broken.

### Layout & strips
- Auto grid: `columns` if given, else ≈ `ceil(sqrt(N))`; rows flow; equal-size cells fill the host's constraints.
- Each cell = a **strip label** (the facet value; prefixed by `label` if provided) above one `BravenPlot`. The strip reuses the active `ChartTheme`'s existing title/label text style — **no new theme component in v1**.

## Architecture / file structure

- **Create** `lib/src/grammar/facet_spec.dart` — `FacetScales` enum + immutable `FacetSpec<T>` (by, columns, scales, label). One clear job: hold facet configuration.
- **Modify** `lib/src/grammar/chart_builder.dart` — add `.facet(...)` (records `FacetSpec`), the `.build()` guard, and `.buildFaceted()`.
- **Create** `lib/src/grammar/braven_facet_plot.dart` — `BravenFacetPlot<T>` StatelessWidget: partition → per-facet `PlotSpec` (range injection) → grid of `BravenPlot`s + strips → one shared controller. One clear job: render a faceted spec.
- **Create** `lib/src/grammar/facet_partition.dart` — pure functions: `distinctFacetValues(rows, by)`, `globalRange(spec, rows, axis)`, `autoColumns(n)`. Pure + unit-testable in isolation, kept out of the widget.
- **Modify** `lib/src/grammar/grammar_diagnostics.dart` — facet diagnostics (no marks, zero facet values, panel-cap exceeded, `.build()` on a faceted chart).
- **Modify** the core barrel (`lib/braven_charts.dart`) — export `FacetSpec`/`FacetScales`/`BravenFacetPlot` (the grammar lives in the core barrel).
- **Showcase (deliverable):** a faceting example on the Chart Grammar showcase page (per the "test surfaces become first-class showcase examples" convention) — e.g. one metric faceted across a categorical field, demonstrating `fixed` vs `free` scales and synced crosshair.

`FacetSpec` and `BravenFacetPlot` carry accessor functions, so — like `Mark`/`PlotSpec` — they are grammar types with **no `copyWith` and no `@chartSurface`** (they never enter the config drift gates).

## Testing

- **Unit** (`facet_partition` pure functions): first-seen distinct values incl. null; correct subset per value; global-range across all rows; each `FacetScales` mode injects/omits the right axis ranges; `autoColumns`.
- **Widget:** N panels render for N facet values; strip labels correct (incl. `label` prefix); `columns` override respected; the panel cap triggers a diagnostic.
- **Synced-interaction:** all panels share one controller under `fixed`/`freeY`; a driven crosshair-x reflects across panels; under `freeX`/`free` panels are independent.
- **Parity (the "emitted == faithful" discipline):** each panel's lowered `BravenChartPlus` config equals the config of the equivalent standalone `PlotSpec` (same marks + injected range) — proving faceting is pure composition with no semantic drift.
- **Diagnostics:** `.build()` on a faceted chart throws; `.buildFaceted()` without `.facet()` throws; zero facet values / cap-exceeded emit the right diagnostics.
- **Golden:** one representative faceted chart (e.g. 4 panels, fixed scales, strips).

## Invariants preserved
- The grammar's opt-in/core-barrel placement is unchanged; faceting adds no config-surface classes and touches no drift gate.
- Non-faceted authoring is completely unaffected (`.facet()` is additive; `.build()` unchanged except the guard when a facet is present).
- Reuses `PlotSpec.lower()`, `BravenPlot`, and `ChartInteractionGroupController` — no new coordinate system, no render-pipeline change.

## Out of scope (future)
- facet-grid (2-D, row-field × column-field).
- Per-facet independent marks / free faceting layouts (ragged grids).
- Faceting-aware legends (shared legend across panels) — v1 uses per-panel legends.
