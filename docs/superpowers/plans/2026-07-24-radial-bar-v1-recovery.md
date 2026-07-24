# Radial Bar V1 recovery plan

## Purpose

Recover the useful Radial Bar discovery work without transplanting its stale
runtime assumptions into the current chart architecture.

Radial Bar is an axis-based radial family:

- category identity maps to concentric tracks;
- an explicit numeric domain maps values to angular sweep;
- an explicit baseline determines where each mark starts;
- values remain absolute values and are never converted into Pie/Donut shares.

## Preserved discovery

The original dirty discovery worktree is preserved outside Git under:

`F:\Repositories\_braven_charts_register\evidence\BC-0012`

That evidence includes the ahead commits, tracked patch, path-preserving
untracked archive, inventory, and checksums. Recovery work happens only in the
fresh `feature/radial-bar-v1-recovery` lane.

## Contract decisions

### Retain

- `RadialBarChartSeries` as the public first-class series name.
- Stable zero-based category ordinals with visible unique labels.
- Explicit `minimum`, `maximum`, and `baseline`.
- Signed values that sweep in opposite directions around an interior baseline.
- Full and partial radial panes.
- Background tracks, configurable track gaps/order, rounded ends, thresholds,
  selection treatment, and deterministic geometry.
- One series in V1. Grouped and stacked Radial Bar remain separately reviewed
  follow-on work.

### Rebuild against current architecture

- Generated fluent/property surfaces via `@ChartSurface`.
- Runtime layout resolution and animation/reduced-motion behavior.
- Shared hit acquisition, durable selection, keyboard navigation, semantics,
  and controller point references.
- Chart configuration artifacts, hydration, preview, source capture/emission,
  Workbench, tables, copy, and CSV.
- Showcase pages, property inspector, randomizer, source view, direct routing,
  and developer documentation.

### Reject

- Pie-style share derivation or reuse of partition-radial semantics.
- Silent fallback to Cartesian rendering.
- Hard-coded text direction, theme colors, labels, or viewport assumptions.
- Shipping the stale prototype element without current interaction and artifact
  contracts.

## Delivery slices

1. **Domain and geometry**
   - Add validated public config, style, threshold, and series models.
   - Add deterministic concentric-track/angular-sweep geometry.
   - Cover explicit domains, signed baselines, partial sweeps, ordering, dense
     tracks, validation, equality, and copy behavior.
2. **Rendering and interaction**
   - Resolve Radial Bar as an axis-based radial layout.
   - Paint tracks, thresholds, guides, labels, and marks.
   - Add motion/reduced-motion, exact hit testing, hover, durable selection,
     keyboard traversal, tooltips, and semantics.
3. **Documents and tools**
   - Add artifact codec/capabilities/hydration/preview.
   - Add table, copy, CSV, controller, source capture/emission, and Workbench.
4. **Showcase and release gates**
   - Add distinct Radial Bar examples, property inspector, randomizer, source,
     route, documentation, accessibility checks, goldens, performance tests,
     analyzer, web build, and publish dry run.

## Slice gates

Every slice must:

- preserve stable category and point identity;
- remain deterministic for equal inputs;
- reject invalid public state in all build modes;
- introduce no hidden Pie/Donut normalization;
- pass targeted tests before broader verification;
- update BC-0012 with evidence and the next executable action.
