# Crosshair Axis-Label Layout Cache

**Register:** `BC-0019`
**Status:** Approved architecture; written specification awaiting review
**Lane:** `perf/crosshair-label-cache`

## Goal

Avoid repeated `TextPainter.layout()` work for unchanged Cartesian crosshair
axis labels without allowing cached state to change label content, styling,
placement, accessibility, or device-dependent behavior.

This is a measurement-gated optimization. A cache is authorized only when a
focused benchmark shows that repeated unchanged-label frames improve by both:

- at least 20 percent at p95; and
- at least 0.10 ms at p95.

If either threshold is missed, the lane will not add production cache state.
It will retain the benchmark evidence, remove the four stale caching TODOs in
`ChartRenderBox`, document that caching is not currently justified, and close
`BC-0019`.

## Current architecture

`ChartRenderBox` owns each chart's mutable rendering lifecycle. It keeps one
shared, stateless `const CrosshairRenderer` and delegates crosshair painting to
it.

`CrosshairRenderer` currently performs label formatting, constructs a
`TextPainter`, calls `layout()`, calculates the current placement, paints the
background and border, and paints the text during the same frame. This occurs
across:

- standard X-axis labels;
- standard per-axis Y labels;
- tracking X- and Y-axis labels;
- transposed category and value labels; and
- top, bottom, mirrored, and multi-axis layouts.

Four TODO blocks in `ChartRenderBox` suggest retaining one X painter, one Y
painter, and the last label strings. That design is incomplete: it cannot
represent multiple Y axes, transposed labels, mirrored X axes, formatter or
theme changes, or inherited rendering environment changes.

## Ownership decision

Introduce an internal, per-chart `CrosshairAxisLabelLayoutCache`.

- `ChartRenderBox` owns the cache because it owns the chart lifecycle.
- `CrosshairRenderer` consumes the cache because it owns formatting and text
  layout decisions.
- `CrosshairRenderer` remains stateless and may remain `const`.
- No cache instance is shared across charts.
- `ChartRenderBox.dispose()` disposes the cache.

This separates lifecycle from layout logic without moving formatting into the
render box or introducing shared mutable renderer state.

## What is cached

Only the laid-out text paragraph and its measured size are cached.

The following remain live calculations on every paint:

- cursor-to-data conversion;
- formatter invocation and resolved display text;
- axis and plot rectangles;
- label X/Y placement and clamping;
- top, bottom, mirrored, inside-plot, and over-axis positioning;
- multi-axis strip selection;
- background, border, and text paint appearance;
- zoom, pan, synchronized-cursor, and transposed geometry; and
- semantic state.

Consequently, a cache hit cannot preserve an old screen position or old axis
geometry. It can only avoid recreating and laying out an equivalent text
paragraph.

## Compatibility key

A cached layout may be reused only when every input that can affect paragraph
measurement or glyph selection remains compatible. The internal key includes:

- fully resolved display text, after formatter and unit application;
- the effective `TextStyle`;
- resolved `TextDirection`, using the ambient chart direction as the fallback
  for neutral text;
- effective `Locale`;
- effective `TextScaler`;
- device-pixel ratio;
- the exact layout constraints passed to `TextPainter.layout()`; and
- any future axis-label input that changes paragraph construction.

Formatter identity itself is not a cache key. Formatters execute before lookup,
and their output is the resolved text key. A formatter replacement that
produces different text therefore misses automatically; a replacement that
produces identical text can safely reuse identical paragraph layout.

Axis placement, bounds, axis position, plot bounds, and cursor position are not
paragraph-layout inputs in the current unconstrained label implementation.
They are deliberately excluded from painter reuse and recalculated every
frame. If a future implementation introduces width-constrained, rotated, or
axis-dependent paragraph layout, those values become mandatory key fields.

## Rendering environment

The render-object bridge already supplies ambient text scale and text
direction. The bridge will additionally supply the effective locale and
device-pixel ratio needed by the compatibility contract.

Crosshair axis-label painters will use those effective values rather than
silently relying on `TextPainter` defaults. This closes the current gap where
crosshair text layout does not consume the chart's existing text-scale input.

Changes to text scale, text direction, locale, or device-pixel ratio mark the
chart for repaint and clear the label cache defensively. Equality in the cache
key remains the primary correctness boundary; explicit clearing prevents
obsolete entries from consuming memory.

## Capacity and lifecycle

The cache is a 16-entry least-recently-used set. This covers the current X
label and the supported visible Y-axis labels with headroom for mirrored and
transposed paths while preventing growth during continuous cursor movement. It
must not become an unbounded map of formatted cursor values.

On replacement or eviction, the old `TextPainter` is disposed. Clearing the
cache disposes every retained painter. `ChartRenderBox.dispose()` clears and
disposes the complete cache exactly once.

## Deterministic invalidation

Key equality prevents incompatible reuse. The cache is also cleared when a
structural change makes old entries predictably irrelevant:

- chart theme or crosshair label style changes;
- text scale, text direction, locale, or device-pixel ratio changes;
- X- or Y-axis configuration changes;
- effective axes or normalization mode changes; and
- the render box is disposed.

Data, formatter, unit, or bounds changes do not depend solely on explicit
clearing: the renderer still formats first, and changed resolved text misses
the cache. Zoom, pan, plot-size, synchronized-cursor, and axis-position changes
continue to recompute placement even when text layout is reusable.

## Benchmark design

Add a focused rendering benchmark with warm-up and multiple p95 trials. It
measures the label-layout portion used by real crosshair rendering, not a
synthetic string map.

The benchmark covers:

1. repeated frames with unchanged X and Y labels;
2. frames with changing X and Y labels, which expose cache lookup and eviction
   overhead;
3. one X and one Y axis;
4. one X and several independently formatted Y axes; and
5. environment-key changes such as text scale or direction.

The baseline and candidate run as five interleaved paired trials in the same
process after common warm-up. Every trial uses the same strings, styles,
constraints, and sample count. Each trial records median and p95 milliseconds
per simulated frame. The decision value is the median of the five trial p95
values, calculated identically for the uncached and cached paths.

The changing-label decision p95 must not regress by more than the greater of
10 percent or 0.05 ms. A cache that passes the unchanged-label gate but fails
this guard during normal cursor motion will not ship.

## Correctness tests

Focused tests must prove:

- identical compatible inputs reuse the same layout;
- changes to text, style, direction, locale, text scale, DPR, or constraints
  miss;
- formatter and unit changes cannot display stale content;
- background, border, and axis colors remain live even on a layout hit;
- X labels preserve bottom, top, and mirrored placement;
- Y labels preserve single-axis and multiple-axis placement;
- transposed labels remain correct;
- zoom, pan, resizing, and synchronized tracking never reuse old placement;
- high text scale and high-DPI changes invalidate safely;
- the bounded cache evicts and disposes old painters; and
- render-box disposal releases all retained painters.

Existing crosshair renderer suites remain regression gates. Golden coverage is
required only if the implementation changes observable output; the intended
result is pixel-identical rendering.

## Accessibility

The optimization does not cache semantics and does not suppress repaint or
semantic updates. Ambient direction and text scaling become explicit layout
inputs. Crosshair enablement, coordinate-label visibility, tracking behavior,
and assistive-technology behavior remain unchanged.

## Non-goals

This lane does not:

- cache tooltips, value-summary cards, series labels, or annotations;
- cache label screen positions or drawing commands;
- change public crosshair APIs or defaults;
- alter formatter contracts;
- change crosshair visual design;
- add a global text-layout cache; or
- optimize unrelated series or axis painting.

## Delivery sequence

1. Add the focused benchmark and record the uncached baseline.
2. Add the internal cache behind a benchmark/test seam, not a public API.
3. Record cached unchanged-label and changing-label results.
4. Apply the approved performance gate.
5. If the gate passes, integrate the cache with the renderer and render-box
   lifecycle and complete the correctness matrix.
6. If the gate fails, remove the prototype cache and stale TODOs while keeping
   the benchmark evidence and rationale.
7. Run focused crosshair tests, the benchmark, `flutter analyze --no-pub lib`,
   and the proportional package test suite.
8. Update `BC-0019` with evidence, accepted deferrals, and residual risk.

No production implementation begins until this written specification is
reviewed and approved.
