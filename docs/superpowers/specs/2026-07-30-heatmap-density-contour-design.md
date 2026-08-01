# Heatmap Density Contour Design

Date: 2026-07-30
Register: BC-0043
Status: implementation slice

## Outcome

Developers can extract deterministic, inspectable contour paths from a
`HeatmapDensityData` raster and compose those paths over the same native
Cartesian Heatmap without introducing a second density estimator or a
Heatmap-specific path renderer.

## Scope

This slice includes:

- validated contour levels over density or relative-density values;
- Marching Squares interpolation over the regular density grid;
- deterministic resolution of saddle cells;
- stable path and point identities;
- source-observation provenance retained on every extracted path;
- conversion of contour paths to ordinary `ChartDataPoint` values;
- one Heatmap plus line-only overlay composition;
- artifact, table, generated-source, benchmark, and showcase verification.

This slice does not include:

- filled contour bands;
- contour labels or collision management;
- irregular cell boundaries;
- clustering or dendrograms;
- rectangular brush semantics;
- multiple Heatmap colour axes;
- tiled, streamed, or image-backed matrices.

## Public contract

`HeatmapDensityContourData` accepts one immutable `HeatmapDensityData`, a
strictly increasing list of finite levels, and a
`HeatmapDensityValueMode`. Levels are expressed in the selected value mode.
Relative levels therefore normally use the inclusive `0..1` domain.

Each `HeatmapDensityContourPath` exposes:

- `id`: stable within one extraction for the same grid and levels;
- `level` and `levelIndex`;
- ordered `HeatmapDensityContourPoint` values in Heatmap cell-index space;
- exact, sorted source observation indices and point keys contributed by the
  grid cells crossed by the path.

`chartPointsFor(path)` maps one path to ordinary `ChartDataPoint` values with
stable point keys and JSON-safe contour metadata. Hosts remain in control of
line colour, width, dash, glow, labels, and interaction by constructing normal
`LineChartSeries` values.

## Geometry

The scalar sample at each density cell is located at the Heatmap cell centre,
whose chart coordinate is `(xIndex, yIndex)`. Marching Squares evaluates every
adjacent 2-by-2 group of samples.

Crossings use linear interpolation:

`t = (level - valueA) / (valueB - valueA)`

Equal endpoints fall back to the edge midpoint. Interpolation is clamped to the
edge so finite input cannot escape its source cell.

Cases 5 and 10 use the bilinear asymptotic determinant:

`q = (bottomLeft - level) * (topRight - level) -
     (bottomRight - level) * (topLeft - level)`

The sign of `q` selects one of the two deterministic saddle connections.
Extracted segments are then stitched by quantized endpoint identity into open
paths or closed loops. Path ordering is stable by level, first point, and
point sequence.

Marching Squares geometry remains piecewise linear and is the analytical
default. Hosts may opt into ordinary `LineChartSeries` Bézier interpolation
and tension as a presentation treatment. Monotone interpolation is not a
contour option because contour paths may reverse X direction or form loops.
Presentation smoothing does not alter the extracted points, path identity, or
source provenance.

Contours are clipped to the Cartesian plot. An open path that reaches the
sampled density-grid boundary remains open: extending or closing it would
require an assumption about density outside the declared domain. This slice
does not invent zero-valued ghost samples or extrapolate contours into axis
margins.

## Provenance

Every segment records the four density cells used by its Marching Squares
case. A completed path contains the sorted union of those cells'
`sourceIndices` and `sourcePointKeys`. The resulting chart-point metadata
contains:

- `densityContourLevel`;
- `densityContourLevelIndex`;
- `densityContourPathId`;
- `densityContourClosed`;
- `densityContourSourceIndices`;
- `densityContourSourcePointKeys`.

The transform never invents raw identities and never replaces the canonical
density cells.

## Composition

The existing Cartesian renderer already paints both Heatmap and Line series.
The v1 layout guard currently rejects their composition. This slice narrows
that guard to permit exactly one `HeatmapChartSeries` plus zero or more
`LineChartSeries` overlays. Bar, Area, Scatter, Candlestick, Range Area, and
additional Heatmap series remain rejected.

This is a composition contract, not a new renderer family. Artifact codecs,
tables, source generation, controllers, and interaction continue to see
ordinary series.

## Review preset

The Heatmap showcase adds a dedicated `Density contours` preset using the same
480 weighted customer observations as the accepted density raster. The preset
shows:

- the canonical relative-density raster;
- three independently styled contour levels;
- live Gaussian/Epanechnikov kernel and X/Y bandwidth controls;
- coarse/detailed contour level selection;
- exact or Bézier-smoothed line presentation with configurable tension;
- contour visibility and stroke-width controls;
- synchronized Chart, Data, Split, and Source modes.

## Verification

- unit tests for validation, edge interpolation, open paths, closed paths,
  saddle determinism, stable identity, value modes, and provenance;
- layout tests proving Heatmap-plus-Line acceptance and rejection of other
  mixed combinations;
- artifact/table/source round-trip and generated-source compilation;
- focused contour extraction benchmark;
- showcase widget tests for preset routing and live controls;
- `flutter analyze lib`;
- repository format checker;
- release web build and direct-route visual review.
