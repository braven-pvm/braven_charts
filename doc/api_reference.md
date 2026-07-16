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

## Portable chart artifacts and data tables

- `BravenChartWorkbench`, `ChartWorkbenchController`, and
  `ChartWorkbenchHandle` — one mounted Chart/Data/Split product surface with
  responsive fallback, snapshot freshness, independent operation state, and
  host-defined artifact actions.
- `ChartDocumentRevision` and `ChartPointRef` — opaque snapshot freshness and
  canonical series/index identity for revision-safe table focus and durable
  point selection.
- `BravenChartController.focusPoint`, `focusPoints`, `selectPoint`, and
  `selectPoints` — linked-surface commands that reject stale or invalid refs;
  selected refs round-trip through `ChartViewState`.
- `BravenChartController.extractDocument` — captures a stable effective chart
  document and optional durable view state from a mounted chart.
- `BravenChartController.extractArtifact` — composes the document with
  metadata and an optional revision-bound preview.
- `ChartArtifact`, `ChartDocument`, `ChartViewState`, and `ChartPreview` — the
  portable envelope and its renderer-independent parts.
- `ChartArtifactJsonCodec` — canonical JSON encode/decode with schema,
  capability, and resource-limit validation.
- `ChartDocumentHydrator`, `HydratedChartConfiguration`, and
  `HydratedBravenChart` — validated restoration into fresh public chart models.
- `ChartDataScope` and `ChartDataStorage` — choose the effective data
  projection and inline point/column storage strategy.
- `ChartTableModel`, `ChartTableOptions`, and `ChartDataTable` — exact-X wide
  rows (one X value with one column per series), lossless long rows, sorting,
  virtualization, theming, bounded dataset/row clipboard copy, and raw-value
  CSV export with automatic web download or host delivery callbacks. Pass
  `selectedPointRefs` to mirror durable chart selection into rows.
- `ChartDataBlobCodec`, `ReferencedPayload`, and `ChartDataResolver` — host
  controlled external payload persistence and checksum-verified resolution.
- `ChartRuntimeBindings` and its formatter, callback, tooltip, and extension
  registries — explicit resolution of executable host behavior by stable IDs.
- `ChartArtifactValidationLimits`, `ChartArtifactMigration`, and
  `ChartArtifactDiagnosticCodes` — bounded decoding, adjacent schema upgrades,
  and machine-readable failure handling.
- `ChartComparisonInput`, `ChartSeriesMatch`, and `ChartComparisonOptions` —
  explicit multi-document identity, alignment, baseline, duplicate, and unit
  rules without name inference.
- `ChartComparisonBuilder`, `ChartComparisonModel`, and
  `ChartComparisonExporter` — source-preserving exact-X, timestamp-tolerance,
  or independent alignment with missing cells, safe deltas, and labelled
  derived CSV columns.

See [Portable chart artifacts](chart_artifacts.md) for the end-to-end guide and
copyable examples, [Chart Workbench](chart_workbench.md) for the reusable
single-chart surface, and [Chart Document Comparison](chart_comparison.md) for
multi-document alignment and export.

## Export policy

Only symbols exported by `package:braven_charts/braven_charts.dart` are part of
the supported public package surface. Files under `lib/src` are implementation
details unless re-exported by that entrypoint.
