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

Annotation model for points, ranges, text, thresholds, and trends.

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
