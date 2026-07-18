# Feature coverage matrix

This matrix connects Braven Charts' defining features to a public API and a
runnable showcase surface. A release-facing claim should appear here before it
is added to package marketing.

| Defining feature | Public API | Showcase evidence |
| --- | --- | --- |
| Zoom and pan | `InteractionConfig`, chart toolbar, gesture and keyboard handlers | Interaction |
| X/Y viewport scrolling | `showXScrollbar`, `showYScrollbar`, `ScrollbarConfig` | Interaction, Render Range |
| Tooltips | `TooltipConfig`, `TooltipStyle`, callbacks | Gallery, Interaction, Tracking Lab |
| Crosshair tracking | `CrosshairConfig`, `CrosshairMode`, `CrosshairDisplayMode` | Tracking Lab, Gallery |
| Annotations | `ChartAnnotation` subtypes, `AnnotationController`, editing dialogs | Annotations, Lactate Threshold, Gallery |
| Line charts | `LineChartSeries`, `LineInterpolation`, `PathAnimationStyle`, entrance replay and compatible data-update interpolation | Line Charts, Chart Types, Gallery |
| Area charts and baselines | `AreaChartSeries`, baseline and above/below fill properties, `PathAnimationStyle`, entrance replay and compatible data-update interpolation | Area Charts, Baseline Fill, Gallery |
| Bar charts | `BarChartSeries`, `BarOrientation`, horizontal multi-axis mapping, `rangeStartValues`, `BarLayoutMode`, `BarChartStyle`, `BarTrackStyle`, `BarLabelStyle`, `BarGroupInfo` | Bar Lab, Chart Types, Gallery |
| Scatter plots | `ScatterChartSeries` | Chart Types, Gallery |
| Pie charts | `PieChartSeries`, `PieChartStyle`, `PieChartTheme`, `PieElevationStyle`, `PieDataLabelConfig` | Pie Charts, Chart Types |
| Conditional series styling | `SegmentStyle`, series style helpers | Segment Styling, Series Styling, Gallery |
| Multiple Y axes | `YAxisConfig`, `yAxisId`, `maxAxesPerSide`, `BravenChartController` | Multi-Axis, Axis Slots |
| Normalization | `NormalizationMode`, `MultiAxisNormalizer`, automatic detection | Multi-Axis, Tracking Lab, Gallery |
| Configurable X axis | `XAxisConfig` | Minor Ticks, Render Range, all chart pages |
| Streaming data | `StreamingConfig`, `StreamingController` | Streaming |
| Direct live ingestion | `LiveStreamController`, `StreamingBuffer` | Gallery, Live Stream |
| Theming | `ChartTheme` and component theme types, including radial defaults | Theming, Pie Charts, Gallery |
| Loading and empty UX | `isLoading`, `ChartLoadingConfig`, `ChartEmptyStateConfig` | Loading States |
| Runtime control | `BravenChartController`, `ChartController`, callbacks | Axis Slots, Annotations, Live Stream |
| Native chart data | `ChartTableModel`, `ChartDataTable`, copy and CSV export | Chart Artifacts, Chart Workbench, Pie Charts |
| Portable chart artifacts | `ChartArtifact`, canonical JSON, preview capture, hydration | Chart Artifacts, Pie Charts |
| Reusable chart workbench | `BravenChartWorkbench`, resizable Split view, revision-safe linked point identity | Line Charts, Area Charts, Pie Charts, Donut Charts, Chart Workbench |
| Document comparison | `ChartComparisonBuilder`, explicit mapping and source-preserving CSV | Chart Workbench |
| Serializable/tool-driven charts | `ChartConfigBuilder`, chart agent interfaces and schemas, including the `pie` contract | Pie Charts, API documentation |
| Dense-data performance | bounded buffers, viewport culling, render caches | Performance, Live Stream |

## Current boundary

Cartesian charts support one configurable X axis and multiple independent Y
axes. Multiple simultaneous X axes are not part of the public contract. A pie
chart accepts exactly one `PieChartSeries`, has no Cartesian axes, and cannot
be mixed with line, area, bar, or scatter series.
