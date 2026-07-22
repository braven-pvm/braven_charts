# BravenChartPlus Public API

This document summarizes the public API surface exposed by the package entrypoint.

**Import**:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Core Widget

### `BravenChartPlus`

The primary chart widget. It renders a chart with optional annotations, interaction, and streaming.

**Constructor** (key parameters):

- `series` (required): `List<ChartSeries>`
- `xAxisConfig`: `XAxisConfig?`
- `yAxis`: `YAxisConfig?`
- `grid`: `GridConfig?`
- `theme`: `ChartTheme?`
- `interactionConfig`: `InteractionConfig?`
- `annotations`: `List<ChartAnnotation>`
- `controller`: `ChartController?`
- `annotationController`: `AnnotationController?`
- `streamingConfig`: `StreamingConfig?`
- `streamingController`: `StreamingController?`
- `liveStreamController`: `LiveStreamController?`
- `isLoading`: `bool`
- `loadingConfig`: `ChartLoadingConfig`
- `emptyStateConfig`: `ChartEmptyStateConfig`

**Factories**:

- `BravenChartPlus.fromValues(...)`
- `BravenChartPlus.fromMap(...)`
- `BravenChartPlus.fromJson(...)`

**Callbacks**:

- `onPointTap`, `onPointHover`, `onBackgroundTap`
- `onSeriesSelected`
- `onAnnotationTap`, `onAnnotationDragged`

## Data Models

### `ChartSeries`

Defines a series of data points with optional styling and axis configuration.

- `id`, `name`, `points`
- `color`, `style`, `isXOrdered`
- `yAxisId` (shared axis), `yAxisConfig` (inline axis)
- `unit` (value suffix)

Concrete series are `LineChartSeries`, `AreaChartSeries`, `BarChartSeries`,
`ScatterChartSeries`, `PieChartSeries`, and `DonutChartSeries`.

### `LineChartSeries` and `AreaChartSeries`

Path-based Cartesian series expose `pathAnimation: PathAnimationStyle`.
Entrance reveal and compatible data updates are opt-in. The
`entranceTiming` and `dataUpdateTiming` fields use `PathAnimationTiming` to set
an explicit non-negative delay and optional duration per stable series ID. A
null duration inherits `ChartTheme.animationTheme.dataUpdateDuration`.
Reduced motion and a zero-duration chart theme override every series timing;
an explicit zero series duration renders that series immediately.

### `BarChartSeries`

Represents grouped, overlaid, stacked, normalized, diverging/Likert,
floating-range, waterfall, vertical, or horizontal bars. `BarLabelStyle` controls value content and
placement plus chart-wide collision handling (`none`, `reposition`, or `hide`),
plot-edge awareness, optional background/border boxes, callout lines, and one
resolved total per stack. These label settings round-trip through portable
chart artifacts. `ChartConfigBuilder` and `ChartToolSchema` expose the same
model to serializable tool calls, including per-point range starts, targets,
uncertainty endpoints, waterfall totals, and native categorical axes.
`BarMotionStyle` adds together, forward, reverse, center-out, and edges-in
sequencing on one reduced-motion-aware entrance, keyed update, and exit
timeline. Removed points and complete series stay in canonical geometry while
collapsing to baseline, then leave the render tree at completion.
`BarPatternStyle` and `BarFillPattern` add clipped diagonal, crosshatch,
horizontal, or vertical line encodings. The same patterned swatch appears in
the chart legend so series remain distinguishable without colour alone.
`BarBulletStyle` and ordered `BarBulletRange` values add passive qualitative
backgrounds behind the actual bar; existing target values remain the distinct
comparison marker. Bullet ranges transpose, expand bounds, and round-trip
through artifacts and tool configuration without becoming synthetic series.
`BarLollipopStyle` replaces the filled body with a configurable stem and
circular endpoint marker while preserving canonical labels, motion,
interaction, horizontal transposition, and artifact/tool serialization.
`ParetoCategory` and `ParetoChartData` prepare stable descending values and
aligned cumulative percentages for a mixed `BarChartSeries` plus
`LineChartSeries` composition on independent value axes.
`HistogramChartData` prepares continuous samples with fixed-count,
Freedman–Diaconis, Sturges, or square-root binning and exposes count,
percentage, and density point sets for ordinary categorical bars.
`BarLayoutMode.divergingStacked` uses `BarDivergingRole` to place positive
magnitudes around one centered neutral segment. `BarDivergingStyle` controls
the shared midpoint line; normalized shares, centered bounds, raw values,
roles, and styling survive tool and artifact round-trips.
`AreaChartSeries.fillGradient` accepts an `AreaGradient` with colors, optional
stops, and plot-relative begin/end alignments. The solid fill remains the
default; `fillOpacity` composes with gradient alpha, while configured baseline
fills take precedence.

### `PieChartSeries`

Represents one insertion-ordered set of category contributions. A pie chart
accepts exactly one pie series and cannot mix with Cartesian series.

- `PieChartSeries.fromMap`: category/value convenience constructor
- `radiusValues` plus `sliceRadiusConfig`: optional complete second-metric map,
  `PieSliceRadiusScale` mapping, minimum factor, label, and unit
- `sliceGroupingConfig`: optional `RadialSliceGroupingConfig` that projects
  small positive sources into one visible slice without collapsing source data
- `pieStyle`: `PieChartStyle` geometry, physical separation, border, solid or
  `PieGradientStyle` fill, explode, opacity, `PieCornerTreatment`, elevation,
  and animation overrides
- `selectionStyle`: shared `RadialSelectionStyle` for Pie, Donut, and
  Concentric Donut, choosing the compatibility
  `RadialSelectionEffect.explode` treatment or a centroid-scaled
  `RadialSelectionEffect.lift`, plus lift scale, radial offset, and
  unselected-slice blur
- `dataLabels`: `PieDataLabelConfig` primary and optional opposite-placement
  secondary content, independent callout styles, eligibility, compact
  outside-lane offset, signed inside radial offset, connector, and collision
  policy
- `ChartTheme.pieChartTheme`: shared `PieChartTheme` defaults, including
  `PieGradientStyle` fills, `PieCornerTreatment`, `PieElevationStyle`
  shadows/glows, and `PieAnimationMode.none`, `grow`, `sweep`, or `fade`
- `total`, `visiblePointIndices`, and `hasVariableSliceRadius`: validated
  contribution and radius helpers

Values must be finite and non-negative, and categories must be non-empty. Zero
values remain in transport and tables but do not paint a slice.

### `DonutChartSeries`

Represents one ordered category whole around a shared circular opening. Donut
is single-series and cannot mix with Pie or Cartesian series.

- `DonutChartSeries.fromMap`: category/value constructor with optional complete
  `radiusValues`
- `donutStyle`: `DonutChartStyle` adds `innerRadiusFactor` and
  `sweepAngleDegrees` to the shared radial geometry and appearance contract
- `centerContent`: `DonutCenterContent` controls portable label/value text,
  `DonutCenterValueMode`, and series-level `LabelStyle` overrides
- `ChartTheme.pieChartTheme.centerLabelStyle` and `centerValueStyle`: shared
  theme defaults for measured center text
- `sliceRadiusConfig`: optional second-metric label, unit, minimum factor, and
  area or linear scaling
- `sliceGroupingConfig`: share threshold, minimum source count, aggregate label,
  and optional color; grouped selection expands to the original point refs
- `BravenChartController.replayRadialEntrance()`: replay the effective Pie,
  Donut, or Polar Column entrance while still honoring reduced motion, `none`,
  and zero-duration themes

The center can show total, selected value, selected-or-total fallback, or
custom text. It follows the same `ChartPointRef` selection used by slices,
legends, tables, keyboard navigation, controllers, and restored runtimes.
See the [Donut guide](../doc/donut_charts.md).

### `ChartDataPoint`

Represents a single data point.

### Selection API

`ChartSelectionConfig` combines an acquisition geometry with a semantic scope:

- `ChartSelectionAcquisitionMode`: direct point, X interval, Y interval,
  rectangle, or lasso;
- `ChartSelectionScope`: mark, category, compatible category stack, whole
  series, or exclusive mark-or-whole-series targeting;
- `ChartSelectionOperation`: replace, add, subtract, or toggle, with optional
  Shift, Alt, and Ctrl/Command modifier overrides;
- configurable mark/path hit radii, hover and selected marker scales, complete
  path stroke scales, background clearing, and tracking-popup visibility.

`BravenChartController` exposes `selectedPointRefs`, `selectedSeriesIds`,
`selectionExpression`, `selectionResult`, and the lazy revision-bound
`selectionSnapshot`. Commands include point/series/expression selection,
inversion, clearing, selection zoom, and document extraction. Use
`ChartDocumentExtractOptions(dataScope: ChartDataScope.selection)` to create a
portable chart from the selected data; `ChartSelectionProjectionOptions`
controls series completion, annotation clipping, and continuous Line/Area
boundary interpolation.

### `ChartAnnotation`

Annotation model for points, ranges, text, thresholds, trends, and chords.

Sealed class with subtypes: `PointAnnotation`, `RangeAnnotation`, `TextAnnotation`,
`ThresholdAnnotation`, `TrendAnnotation`, `ChordAnnotation`, `PinAnnotation`, `LegendAnnotation`.

### `ChordAnnotation`

Draws a straight line (chord/secant) between two data points on a series, with an optional perpendicular drop-line to a third data point.

- `seriesId`, `startIndex`, `endIndex` (required)
- `lineColor`, `lineWidth`, `dashPattern`, `elevation`
- `perpendicularIndex` — optional data point index for perpendicular drop-line
- `perpendicularLabel`, `perpendicularLabelStyle` — label on the perpendicular line
- `perpendicularLineColor`, `perpendicularLineWidth`, `perpendicularDashPattern`, `perpendicularElevation` — optional overrides (default: inherit chord styling)

## Axis Configuration

### `XAxisConfig`

Controls X-axis layout, labeling, and tick generation.

- `label`, `unit`, `color`
- `min`, `max`, `tickCount`
- `labelDisplay`, `tickLabelPadding`, `axisLabelPadding`, `axisMargin`
- `showAxisLine`, `showTicks`, `showCrosshairLabel`
- `categoryAxis` — optional `CategoryAxisConfig` for integer-indexed category
  names, automatic readable viewports, density control, wrapping/ellipsis, and
  label rotation. Category metadata is portable in chart artifacts and is used
  by axis ticks, crosshair labels, and native data tables without a formatter
  callback.

```dart
xAxisConfig: const XAxisConfig(
  label: 'Market segment',
  maxHeight: 88,
  categoryAxis: CategoryAxisConfig(
    categories: ['Enterprise', 'Mid-market', 'Small business'],
    minimumCategoryExtent: 72,
    labelOverflow: CategoryLabelOverflow.wrap,
  ),
),
```

When all categories cannot fit, `autoViewport` opens the first readable window.
Enable `showXScrollbar` or pan/zoom to navigate the full category domain.

### `YAxisConfig`

Controls Y-axis placement and styling.

- `position` (`YAxisPosition.left`, `right`, `leftOuter`, `rightOuter`)
- `label`, `unit`, `color`, `tickCount`
- `labelDisplay`, `crosshairLabelPosition`

## Grid and Layout

### `GridConfig`

Controls gridline visibility and style.

## Interaction

### `InteractionConfig`

Controls crosshair, tooltip, zoom, and pan behavior.

### `CrosshairConfig`

Controls crosshair mode, labels, and tracking behavior.

## Streaming

### `StreamingConfig`

Controls auto-scroll and buffering behavior for live data.

### `StreamingController` / `LiveStreamController`

Programmatic control over streaming mode transitions.

## Loading and Empty States

### `ChartLoadingConfig`

Controls the viewport presentation while `BravenChartPlus.isLoading` is true.
Use `ChartLoadingConfig.skeleton()`, `.circular()`, or `.linear()`. Circular and
linear configurations accept optional determinate `progress` from 0 to 1.

The animated skeleton is responsive and inherits its series and grid colors
from `BravenChartPlus.theme`, then the Material theme. Its
`ChartLoadingSkeletonStyle` can override primary and secondary trace colors,
grid color, animation duration, maximum width, viewport width factor, aspect
ratio, motion intensity, optional grid visibility, secondary-trace visibility,
and horizontal edge fade. The polished default omits grid lines.

`loadingWidget` takes precedence over the configured built-in indicator. For a
context-aware replacement, use `ChartLoadingConfig.customBuilder`.

### `ChartEmptyStateConfig`

Controls the title, guidance, icon, semantics, or custom builder displayed when
loading has finished and all effective chart series are empty. A chart using a
`LiveStreamController` keeps its render box mounted while waiting for its first
direct streaming point.

## Portable Chart Artifacts

### Chart workbench

- `BravenChartWorkbench` composes one mounted chart with Chart, Data, and
  responsive Split presentations. Horizontal Split can auto-fit the native
  table footprint and exposes an accessible draggable/keyboard divider with
  minimum pane extents and an explicit fixed-layout opt-out.
- `ChartDataTable.preferredWidthFor(...)` exposes the same projection-width
  estimate used by Split auto-fit for custom host compositions.
- `ChartWorkbenchController` is the caller-owned imperative controller and
  stable `ChartWorkbenchHandle` supplied to host actions.
- `ChartWorkbenchStatus`, `ChartWorkbenchTableState`, and
  `ChartWorkbenchArtifactState` expose operation-scoped phases, warnings, and
  structured errors.
- `ChartTableRefreshPolicy` selects first-use/manual, mode-entry, or bounded
  effective-document revision refresh.
- `ChartDocumentRevision` is the opaque equality token shared by
  `ChartDocumentSnapshot.revision` and
  `BravenChartController.effectiveDocumentRevision`.
- `ChartPointRef` is the canonical value identity for linked chart/table
  points. Controller focus and selection commands require the issuing document
  revision; transient focus is runtime-only, while selection is captured in
  `ChartViewState.selectedPointRefs`.
- Default workbench row activation refreshes the snapshot after a successful
  durable selection, keeping later row references valid without changing the
  configured policy for independent chart or data revisions.

The workbench owns no persistence. `actionsBuilder` lets the host attach save,
share, report, or comparison actions and use `extractArtifact()` without
duplicating the chart/table lifecycle. See [Chart Workbench](guides/chart-workbench.md)
for responsive behavior, freshness rules, controller ownership, and examples.

### Document comparison

- `ChartComparisonInput` gives each portable document a host identity and label.
- `ChartSeriesMatch` declares semantic series identity explicitly; names are
  never inferred.
- `ChartComparisonOptions` selects exact-X, timestamp-tolerance, or independent
  long-row behavior, plus explicit baseline, duplicate, and unit rules.
- `ChartComparisonBuilder` returns a pure `ChartComparisonModel` with raw source
  values, missing cells, converted comparison values, and optional deltas.
- `ChartComparisonExporter` creates a rectangular CSV projection whose source
  and derived columns remain machine-readable.

The package does not own a comparison repository or global screen. See
[Chart Document Comparison](guides/chart-comparison.md) for deterministic
alignment, unit/domain safety, diagnostics, and independent hydration.

### Extraction and transport

- `BravenChartController.extractDocument(...)` captures one immutable
  `ChartDocumentSnapshot` from effective mounted state.
- `BravenChartController.extractArtifact(...)` composes a `ChartArtifact` and
  optional hash-bound `ChartPreview`.
- `ChartArtifactJsonCodec` validates and canonically encodes/decodes the
  versioned JSON envelope.
- `ChartArtifactValidationLimits` bounds untrusted JSON and resolved payloads.

### Hydration and runtime bindings

- `ChartDocumentHydrator` restores documents, artifacts, JSON, and
  resolver-backed JSON into `HydratedChartConfiguration`.
- `HydratedChartConfiguration.build(...)` creates a fresh interactive
  `HydratedBravenChart` runtime.
- `ChartRuntimeBindings` reattaches host callbacks, formatters, tooltips,
  codecs, and extension capabilities without serializing executable behavior.

### Data payloads

- `InlinePointPayload` and `InlineColumnarPayload` store self-contained data.
- `ReferencedPayload` describes host-owned bytes by content type, length,
  point count, locator, and SHA-256.
- `ChartDataResolver` is the host authorization and byte-retrieval boundary.
- `ChartDataBlobCodec` and `ChartDataBinaryCodec` encode deterministic external
  payload blobs.

### Tables, identity, and migration

- `ChartTableModel`, `ChartTableOptions`, and `ChartDataTable` derive an
  accessible long, exact-X wide, or radial `Category | Value | Radius? | Share` table from
  the portable document. The widget
  natively provides bounded dataset clipboard copy, per-row copy, and raw CSV
  export; web downloads directly and non-web hosts can override delivery. Row
  callbacks report one point ref for long rows and every populated point ref
  for wide rows.
- `ChartArtifactCanonicalizer` creates document, document-plus-view, and
  per-payload SHA-256 identities.
- `ChartArtifactDeduplicator` returns immutable, input-ordered duplicate groups.
- `ChartArtifactMigration` and `ChartArtifactMigrationRegistry` define trusted
  adjacent-version JSON migrations supplied explicitly by the caller.

See [Portable Chart Artifacts](guides/chart-artifacts.md) and
[Chart Artifact Migrations](guides/chart-artifact-migrations.md) for complete
workflows and security boundaries.

## Theming

### `ChartTheme`

Defines visual styling for chart components.

## Controllers

### `ChartController`

Imperative control over chart state and view.

### `AnnotationController`

Manage interactive annotations and external tooling.

## Example

```dart
final series = ChartSeries(
  id: 's1',
  points: const [
    ChartDataPoint(x: 0, y: 10),
    ChartDataPoint(x: 1, y: 15),
  ],
  color: Colors.blue,
);

BravenChartPlus(
  series: [series],
  xAxisConfig: const XAxisConfig(label: 'Time'),
  yAxis: const YAxisConfig(label: 'Value'),
  interactionConfig: const InteractionConfig(
    crosshair: CrosshairConfig(enabled: true),
  ),
);
```
