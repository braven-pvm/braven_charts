# Sprint 11 Implementation Plan — Path Strokes and Forecast

**Status:** Ready for local review
**Branch:** `feature/line-stroke-forecast`
**Base:** merged PR #43 / current `origin/master`
**Design:** `../specs/2026-07-18-path-strokes-and-synchronized-charts-design.md`

## Outcome

Ship portable dash patterns for Line and Area outlines and prove them in a
restrained observed-versus-forecast composition on the Line chart-family page.

## Slice 1 — Lock the public model

1. Add failing constructor, validation, copy, equality, and hash tests for
   `dashPattern` on `LineChartSeries` and `AreaChartSeries`.
2. Add the solid default and validated non-empty pattern to both models.
3. Keep existing constructors source-compatible and touched files formatted.
4. Extend `SegmentStyle` with a nullable pattern: null inherits the series and
   an empty list explicitly restores a solid outgoing segment.

## Slice 2 — Render path patterns

1. Add a reusable path-metric utility that converts one interpolated `Path`
   into alternating draw/gap geometry.
2. Test solid fallback, exact intervals, multiple contours, and invalid input.
3. Apply the utility to Line single-style and multi-style rendering.
4. Apply it to Area standard, gradient, multi-style, and baseline outlines
   without changing fill geometry.
5. Apply the pattern consistently to optional glow.
6. Add pixel/render-path coverage for linear, stepped, Bezier, monotone,
   markers, segment overrides, fill, glow, reveal, and data-update motion.

## Slice 3 — Complete the portable vertical

1. Encode/decode non-empty patterns in `ChartSeriesDocumentCodec`.
2. Advertise and hydrate `series.path-dash.v1`.
3. Emit non-default patterns in readable Dart source.
4. Teach the package legend to draw patterned Line/Area swatches.
5. Add artifact round-trip, capability, hydration, source, and legend tests.

## Slice 4 — Build the Forecast preset

1. Add `Forecast` to the Line preset selector.
2. Compose one canonical series with solid observed segments and dotted
   outgoing segment styles from the current-time point, hollow markers, an
   inline identity, and one vertical `Current time` threshold.
3. Reuse the existing Workbench and options surface; do not add a new panel.
4. Add wide and 390 px tests for preset selection, series contract,
   annotation, Chart/Data/Split/Source, and bounded controls.
5. Review the release route at desktop and compact widths.

## Slice 5 — Promotion gates

1. Run touched-file formatting and `git diff --check`.
2. Run package and showcase analyzers and complete suites.
3. Generate root and deployment-base release web builds.
4. Run pub.dev dry run and Dartdoc, recording any tool-only failure precisely.
5. Serve the root release bundle locally for joint review.
6. Commit locally. Do not push or open a PR until review approval.

## Deferred to Sprint 12

- `ChartInteractionGroupController`.
- Shared data-X cursor and crosshair rendering.
- X viewport pan/zoom synchronization.
- The stacked Speed/Elevation/Heart rate showcase.

## Delivered local slice

- Added empty-by-default `dashPattern` support to Line and Area models,
  including copy, equality, hashing, debugging output, path-metric validation,
  and solid fallback.
- Patterned every Line and Area outline path after interpolation, including
  per-segment regions, glow, baseline fills, and all four interpolation modes.
  Area interiors remain continuous and interaction geometry is unchanged.
- Added `series.path-dash.v1` encoding, decoding, validation, built-in
  hydration, generated Dart source, and patterned Line/Area legend swatches.
- Added the Line `Forecast` preset and then replaced its initial two-series
  composition after pixel review exposed a monotone endpoint-tangent break.
  The corrected design uses one canonical series and changes only outgoing
  segment patterns at `Current time`, preserving the complete interpolation.
- The complete package suite passes with 1,972 tests and the complete showcase
  suite passes with 160 tests. Package `lib`, showcase `lib/test`, and the
  changed-file analysis set are clean.
- Both the GitHub Pages `/braven_charts/` and root-base release web builds
  succeed. The refreshed root build is served on port 8099.
- The clean-tree pub.dev dry run passes with zero warnings. Dartdoc 9.0.4
  reproduces the recorded internal `DocumentationComment._stripDocImports`
  range error.
- Direct browser capture confirms one smooth monotone path through the
  current-time boundary, with only the outgoing stroke pattern changing.
- A post-review performance audit preserves the original single-path fast path
  for unstyled baseline Area charts and adds a permanent 5,000-point render
  benchmark. Feature medians remain within measurement noise of `origin/master`
  for solid and baseline Area, while the continuous Forecast remains under
  2 ms median and 2.2 ms p95 on the verification host.
- The release bundle is served from this worktree on port 8099 for joint pixel
  review. The slice is committed locally and rebased onto current
  `origin/master`; no push or PR has been made.
