# Fluent API + Grammar-of-Graphics — programme roadmap

**Date:** 2026-07-22
**Status:** Active. V1 shipped in PR #81 (`feature/chart-grammar`); this doc governs V2+.
**Governs:** the fluent modifier surface, the typed grammar (`PlotSpec`/`Mark`/`BravenChart`),
the grammar-source emitter, and the convergence of the config surface's hand-maintained mirrors.
**Supersedes the V2 backlog list** in `2026-07-21-chart-grammar-design.md` (that list is now organised here).

## Where V1 landed (the baseline this builds on)

- `@chartSurface` surface model + `tool/surface_gen` engine, hard-mode enforcement (`missing=0`).
- 98 generated fluent extensions / ~1,160 verbs behind the opt-in barrel; 1,090+ executed every suite.
- Typed grammar: `PlotSpec<T>`, sealed `Mark<T>` (Line/Area/Bar/Scatter/Candlestick/Trend), channels,
  `PlotSpecLowering.lower()`, `BravenPlot<T>`, chained `BravenChart.of(...)` — parity-locked by
  config- and artifact-document equality.
- `ChartToolSchema.surfaceDefinitions` generated from the model + a bidirectional schema↔builder drift gate.
- Workbench Config/Grammar Source toggle, gated by a round-trip proof ("emitted == faithful").

## The three themes

Every backlog item falls into one of three tracks. **Emission coverage == grammar coverage**: any
Breadth item that lets the grammar express a chart also removes that chart's "not emitted" diagnostic
in the Source tab.

### Theme A — Breadth (make the grammar express more charts)
- **Non-trend annotation marks** — Range/Threshold/Point annotations get chain verbs. *(V2.0)*
- **Chart-level options on `PlotSpec`** — non-default grid, title/subtitle, legend/toolbar toggles. *(V2.0)*
- **Per-mark data-point markers + inline labels** on Line/Area/Bar. *(V2.0)*
- Faceting / small-multiples — `.facet(by:)` lowering to N synchronized widgets. *(V2.x, high cost)*
- Radial/polar marks — Pie/Donut/Polar authorable via the grammar. *(V2.x, high cost — new geometry family)*
- Scale-driven colour/size/opacity channels on non-scatter families. *(V2.x — needs render-pipeline work)*
- Log/time scale objects. *(V2.x)*

### Theme B — Convergence (one model drives every mirror; delete the mirror tax)
The original justification for the whole programme: ~12.5k lines of hand-maintained, drift-prone
mirrors of the config surface. V1 made the model drive the fluent layer + AI schema *definitions*.
- **AI schema builder-AST convergence** + fix the 2 live AI bugs (10 candlestick keys undiscoverable
  by an LLM; `line_interpolation` documented-but-hardcoded). *(self-contained, high payoff)*
- **Generate the Source config emitter** (89 hand-written `_emit*` methods today).
- **The 29 `copyWith`-less config classes** → add `copyWith` → they enter enforcement + fluent + schema.
- Artifact codec convergence (the deepest mirror). *(late)*

### Theme C — Depth (complete the fluent layer itself)
- **Nullable-clear gap** — 70% of nullable params have no clear verb (`copyWith` can't unset them);
  closing it is a model-driven sentinel-`copyWith` refactor across ~97 classes (also a Convergence enabler).
- `YAxisConfig.withId` → public API. *(trivial)*
- Emitter → Dart `augment` declarations when they ship (the emitter seam already exists).

## Sequence (owner-approved 2026-07-22)

1. **V2.0 — Close the emission gaps** *(active)*. The three low-cost Theme-A items above, in one lane.
   Together they turn most existing charts from "not emitted" into a real grammar chain — the most
   user-visible next win, and it directly closes what the owner saw in the Source tab. Plan:
   `docs/superpowers/plans/2026-07-22-grammar-v2.0-emission-gaps.md`.
2. **Strategic fork** (decided after V2.0):
   - **Convergence** (Theme B) — finish the single-source-of-truth story and start *deleting* mirrors. Highest long-term leverage.
   - **Breadth** (rest of Theme A) — radial marks + faceting make `BravenChart.of()` a universal authoring API. More visible, more expensive, some needs render-pipeline changes.

## Dependency / branch note

V2.0 (`feature/grammar-v2`) is **stacked on V1** (`feature/chart-grammar`, PR #81, not yet merged).
When #81 merges to master, rebase `feature/grammar-v2` onto master before its own PR. Its base is the
V1 tip `a0b7eb0b`; any V1 review changes shift that base.

## Tracking

- This doc is the programme's living index; update the Sequence section as slices land.
- Each numbered slice gets its own plan under `docs/superpowers/plans/` and its own PR.
- Invariants every slice preserves: enforcement `missing=0`; zero golden drift; the round-trip proof
  ("emitted == faithful"); config- and artifact-parity; the opt-in fluent barrel stays out of the core barrel.
