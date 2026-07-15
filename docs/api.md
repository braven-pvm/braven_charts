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

### `ChartDataPoint`

Represents a single data point.

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
  accessible long or exact-X wide table from the portable document. The widget
  natively provides bounded dataset clipboard copy, per-row copy, and raw CSV
  export; web downloads directly and non-web hosts can override delivery.
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
