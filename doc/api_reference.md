# Public API overview

Import the supported package surface through one entrypoint:

```dart
import 'package:braven_charts/braven_charts.dart';
```

Pub.dev generates the complete member-level API reference from Dart
documentation comments. This page is a human-oriented map of the main exported
types and where to begin.

## Chart widget and series

- `BravenChartPlus` — primary chart widget, including `fromValues` and
  `fromMap` convenience factories.
- `ChartSeries` — common immutable series model.
- `LineChartSeries`, `AreaChartSeries`, `BarChartSeries`,
  `ScatterChartSeries` — concrete renderable series.
- `ChartDataPoint`, `DataRange`, `ChartType` — core data types.
- `LineInterpolation`, `SeriesStyle`, `SegmentStyle`,
  `DataPointLabelConfig`, `SeriesInlineLabelConfig` — series presentation.

## Axes, normalization, and layout

- `XAxisConfig` — X bounds, ticks, labels, render range, and presentation.
- `YAxisConfig`, `YAxisPosition` — independent Y-axis identity, units,
  position, bounds, and labels.
- `MultiAxisConfig`, `NormalizationMode` — multi-axis policy.
- `NormalizationDetector`, `RangeRatioCalculator`, `SeriesAxisResolver` —
  automatic multi-axis helpers.
- `AxisLayoutManager`, `MultiAxisLayout`, `MultiAxisNormalizer`,
  `MultiAxisPainter`, `AxisColorResolver` — advanced layout and rendering
  integration.
- `AxisSwapMode` and `BravenChartController` — visible-axis slot behavior and
  runtime series selection.

## Interaction

- `InteractionConfig` — interaction configuration root.
- `CrosshairConfig`, `CrosshairMode`, `CrosshairDisplayMode` — crosshair and
  tracking behavior.
- `TooltipConfig`, `TooltipStyle`, `TooltipTriggerMode` — marker and tracking
  tooltip behavior.
- `InteractionCallbacks` and chart callbacks — point, series, background, and
  annotation events.
- `ScrollbarConfig` — chart scrollbar presentation.

## Annotations

- `ChartAnnotation` — sealed annotation base type.
- `PointAnnotation`, `RangeAnnotation`, `TextAnnotation`,
  `ThresholdAnnotation`, `TrendAnnotation`, `ChordAnnotation`, `PinAnnotation`,
  and `LegendAnnotation` — supported overlays.
- `AnnotationStyle` and annotation theme types — common presentation.
- `AnnotationController` and `ChartController` — programmatic annotation
  creation, updates, lookup, and removal.

## Streaming and live data

- `StreamingConfig`, `AutoScrollConfig` — buffered viewport behavior.
- `StreamingController` — follow-latest, paused, and user-controlled viewport
  modes.
- `LiveStreamController` — direct, frame-coalesced point ingestion with bounded
  buffers and pause/resume.
- `StreamingBuffer` — bounded point storage and data bounds.

## Loading and empty states

- `ChartLoadingConfig` — chart skeleton, circular progress, linear progress, or
  a custom state builder.
- `ChartLoadingSkeletonStyle` — animation, trace colors, geometry, optional
  grid, and edge fading.
- `ChartEmptyStateConfig` — empty-state title, guidance, semantics, icon, or
  custom builder.

## Theming

- `ChartTheme` — complete chart theme and built-in presets.
- `GridStyle`, `AxisStyle`, `SeriesTheme`, `InteractionTheme`,
  `TypographyTheme`, `AnimationTheme`, `AnnotationTheme`, `LegendStyle`, and
  `LabelStyle` — component-level themes.
- `GridConfig` — per-chart grid visibility and style.

## Configuration and tool-driven charts

- `ChartConfigBuilder` — converts serializable configuration into chart input.
- `ChartAgentInterface` and chart tool schemas — contracts for tool-driven or
  agent-assisted chart construction.

## Export policy

Only symbols exported by `package:braven_charts/braven_charts.dart` are part of
the supported public package surface. Files under `lib/src` are implementation
details unless re-exported by that entrypoint.
