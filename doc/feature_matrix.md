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
| Synchronized Cartesian interaction | `ChartInteractionGroupController`, `ChartInteractionGroupOptions`, `ChartXViewport` | Line Charts — Synchronized |
| Annotations | `ChartAnnotation` subtypes, `AnnotationController`, editing dialogs | Annotations, Lactate Threshold, Gallery |
| Line charts | `LineChartSeries`, `LineInterpolation`, `PathAnimationStyle`, explicit per-series entrance/update timing, entrance replay, value interpolation, and stable boundary-topology motion | Line Charts, Chart Types, Gallery |
| Area charts and baselines | `AreaChartSeries`, baseline and above/below fill properties, `PathAnimationStyle`, explicit per-layer timing, and synchronized value and stable boundary-topology motion | Area Charts, Baseline Fill, Gallery |
| Bar charts | `BarChartSeries`, `BarOrientation`, horizontal multi-axis mapping, inherited RTL canvas text and semantics, `rangeStartValues`, `BarLayoutMode`, first-class diverging/Likert roles and center line, `BarChartStyle`, non-colour `BarPatternStyle`, `BarTrackStyle`, `BarLollipopStyle`, first-class `BarBulletStyle`, `ParetoChartData` mixed bar-line compositions, `HistogramChartData` continuous-sample binning, keyed entrance/update/exit `BarMotionStyle`, viewport-virtualized geometry and indexed hit testing, spatially indexed chart-wide collision-aware `BarLabelStyle`, stack totals, `BarGroupInfo` | Bar Lab Stress, Bar Lab RTL, Bar Lab Histogram, Bar Lab Pareto, Bar Lab Lollipop, Bar Lab Likert, Bar Lab Bullet, Bar Lab Patterns, Bar Lab, Chart Types, Gallery |
| Scatter plots | `ScatterChartSeries`, `ScatterMarkerStyle`, `ScatterInteractionStyle`, area-correct `ScatterSizeEncoding`, continuous or piecewise `ScatterColorEncoding`, `ScatterOpacityEncoding`, independent point channels, quantitative legends, unsorted-data culling, and point-accurate 2D interaction | Scatter Charts, Chart Types, Gallery |
| Pie charts | `PieChartSeries`, `PieChartStyle`, `PieChartTheme`, `PieElevationStyle`, dual inside/outside `PieDataLabelConfig`, shared explode/lift `RadialSelectionStyle` | Pie Charts, Chart Types |
| Donut charts | `DonutChartSeries`, `DonutChartStyle`, `DonutCenterContent`, runtime center builders, partial sweeps, variable radii, and shared explode/lift `RadialSelectionStyle` | Donut Charts, Chart Types, Gallery |
| Concentric Donut charts | two or more `DonutChartSeries`, `ConcentricDonutConfig`, composition-wide lift selection, ring-aware legends, native tables, exact generated Source, artifacts | Concentric Donut, Chart Types, Gallery |
| Polar Column and Rose charts | `PolarColumnChartSeries`, `PolarColumnPreset`, `PolarColumnStyle`, `PolarChartConfig`, angular category axis, numeric radial axis, linear or area-correct scaling, shared explode/lift `RadialSelectionStyle` | Polar Column, Chart Types, Gallery |
| Conditional series styling | `SegmentStyle`, series style helpers | Segment Styling, Series Styling, Gallery |
| Multiple Y axes | `YAxisConfig`, `yAxisId`, `maxAxesPerSide`, `BravenChartController` | Multi-Axis, Axis Slots |
| Normalization | `NormalizationMode`, `MultiAxisNormalizer`, automatic detection | Multi-Axis, Tracking Lab, Gallery |
| Configurable X axis | `XAxisConfig`, `CategoryAxisConfig`, `CategoryLabelDensity`, `CategoryLabelOverflow` | Bar Lab Categories, Minor Ticks, Render Range |
| Streaming data | `StreamingConfig`, `StreamingController` | Streaming |
| Direct live ingestion | `LiveStreamController`, `StreamingBuffer` | Gallery, Live Stream |
| Theming | `ChartTheme` and component theme types, including radial defaults | Theming, Pie Charts, Gallery |
| Loading and empty UX | `isLoading`, `ChartLoadingConfig`, `ChartEmptyStateConfig` | Loading States |
| Runtime control | `BravenChartController`, `ChartController`, callbacks | Axis Slots, Annotations, Live Stream |
| Native chart data | `ChartTableModel`, `ChartDataTable`, copy and CSV export | Chart Artifacts, Chart Workbench, Pie Charts, Polar Column |
| Portable chart artifacts | `ChartArtifact`, canonical JSON, preview capture, hydration | Chart Artifacts, Pie Charts, Polar Column |
| Reusable chart workbench | `BravenChartWorkbench`, resizable Split view, revision-safe linked point identity, nestable shared mode and selector scope | Chart Workbench; all chart-family guides |
| Generated Dart source | `ChartDartSourceGenerator`, `ChartDartSourceOptions`, `ChartDisplayMode.source`, `ChartWorkbenchSourceState` | Chart Workbench; Line, Area, Bar, Scatter, Pie, Donut, Concentric Donut, and Polar Column guides |
| Document comparison | `ChartComparisonBuilder`, explicit mapping and source-preserving CSV | Chart Workbench |
| Serializable/tool-driven charts | `ChartConfigBuilder`, chart agent interfaces and schemas, including complete advanced `bar`, `pie`, and `donut` contracts | Bar Lab, Pie Charts, API documentation |
| Dense-data performance | bounded buffers, viewport culling, render caches, Scatter spatial indexing and geometry-aware hit testing | Performance, Scatter Charts, Live Stream |

## Current boundary

Cartesian charts support one configurable X axis and multiple independent Y
axes. Multiple simultaneous X axes are not part of the public contract. A Pie
accepts exactly one `PieChartSeries`; a standalone Donut accepts one
`DonutChartSeries`; and two or more Donut series form one Concentric Donut
composition. Partition-radial charts have no Cartesian axes and cannot mix
with line, area, bar, or scatter series. Polar Column accepts one
`PolarColumnChartSeries` in V1, uses its own angular-category and radial-numeric
axes, and cannot mix with either Cartesian or partition-radial series.
