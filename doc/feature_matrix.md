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
| Cartesian value summary | `CartesianValueSummaryConfig`, fixed overlay and draggable annotation `CartesianValueSummaryPresentation`, deterministic `CartesianValueSummaryValuePolicy` chains, family-aware automatic and builder `CartesianValueSummaryContent`, tri-state `CartesianValueSummaryStyle` clears, `CartesianValueSummaryTheme` presets, anchor-relative `ChartOverlayPlacement`, `CartesianValueSummaryController` pinning, grouped semantics with debounced `announceChanges`, portable artifacts and generated Source | Value Summary |
| Synchronized Cartesian interaction | `ChartInteractionGroupController`, `ChartInteractionGroupOptions`, `ChartXViewport` | Line Charts — Synchronized |
| Full-domain Cartesian navigation | `CartesianNavigator`, `CartesianNavigatorBehavior`, `CartesianNavigatorSnapPolicy`, `CartesianNavigatorStyle` | Interaction — Navigator; Live Stream — Live Navigator; Gallery — Synchronized Cartesian; Line — Synchronized; Area — Forecast; Bar — Categories; Scatter — Correlation; Candlestick — Stock |
| Annotations | `ChartAnnotation` subtypes, `AnnotationController`, editing dialogs | Annotations, Lactate Threshold, Gallery |
| Line charts | `LineChartSeries`, `LineInterpolation`, `PathAnimationStyle`, explicit per-series entrance/update timing, entrance replay, value interpolation, and stable boundary-topology motion | Line Charts, Chart Types, Gallery |
| Area charts and baselines | `AreaChartSeries`, baseline and above/below fill properties, `PathAnimationStyle`, explicit per-layer timing, and synchronized value and stable boundary-topology motion | Area Charts, Baseline Fill, Gallery |
| Range Area charts | `RangeAreaDataPoint`, `RangeAreaChartSeries`, `RangeAreaBoundaryStyle`, `RangeAreaLabelConfig`, `RangeAreaInteractionDetails`, typed low/high tracking, explicit gaps, nested-band and Line composition, atomic motion, artifacts, Data, and Source | Range Area Charts |
| Bar charts | `BarChartSeries`, `BarOrientation`, horizontal multi-axis mapping, inherited RTL canvas text and semantics, `rangeStartValues`, `BarLayoutMode`, first-class diverging/Likert roles and center line, `BarChartStyle`, non-colour `BarPatternStyle`, `BarTrackStyle`, `BarLollipopStyle`, first-class `BarBulletStyle`, `ParetoChartData` mixed bar-line compositions, `HistogramChartData` continuous-sample binning, keyed entrance/update/exit `BarMotionStyle`, viewport-virtualized geometry and indexed hit testing, spatially indexed chart-wide collision-aware `BarLabelStyle`, stack totals, `BarGroupInfo` | Bar Lab Stress, Bar Lab RTL, Bar Lab Histogram, Bar Lab Pareto, Bar Lab Lollipop, Bar Lab Likert, Bar Lab Bullet, Bar Lab Patterns, Bar Lab, Chart Types, Gallery |
| Candlestick charts | `CandlestickDataPoint`, `CandlestickChartSeries`, `CandlestickChartStyle`, `CandlestickAnimationStyle`, `CandlestickDensityGrouping`, typed OHLC tracking, ordered viewport culling, live latest-candle upsert, lossless artifacts, and Line/Area/Scatter overlays | Candlestick Charts, Chart Types |
| Scatter plots | `ScatterChartSeries`, `ScatterMarkerStyle`, `ScatterInteractionStyle`, area-correct `ScatterSizeEncoding`, continuous or piecewise `ScatterColorEncoding`, `ScatterOpacityEncoding`, independent point channels, quantitative legends, unsorted-data culling, and point-accurate 2D interaction | Scatter Charts, Chart Types, Gallery |
| Pie charts | `PieChartSeries`, `PieChartStyle`, `PieChartTheme`, `PieElevationStyle`, dual inside/outside `PieDataLabelConfig`, shared explode/lift `RadialSelectionStyle` | Pie Charts, Chart Types |
| Donut charts | `DonutChartSeries`, `DonutChartStyle`, `DonutCenterContent`, runtime center builders, partial sweeps, variable radii, and shared explode/lift `RadialSelectionStyle` | Donut Charts, Chart Types, Gallery |
| Concentric Donut charts | two or more `DonutChartSeries`, `ConcentricDonutConfig`, composition-wide lift selection, ring-aware legends, native tables, exact generated Source, artifacts | Concentric Donut, Chart Types, Gallery |
| Polar Column and Rose charts | one or more compatible signed `PolarColumnChartSeries` values, layered, grouped, or diverging stacked `PolarColumnCompositionConfig`, per-category `targetValues` and `PolarColumnTargetMarkerStyle`, pane-wide `PolarThreshold` references, absolute `PolarColumnInterval` endpoints with whisker or annular-band `PolarColumnIntervalStyle`, `PolarColumnPreset`, gradient/elevation/motion-aware `PolarColumnStyle`, independently positioned and styled category/value/radial labels, angular category axis, shared numeric radial axis, linear or area-correct scaling, bounded visual label/spoke density, shared explode/lift `RadialSelectionStyle` | Polar Column, Chart Types, Gallery |
| Conditional series styling | `SegmentStyle`, series style helpers | Segment Styling, Series Styling, Gallery |
| Multiple Y axes | `YAxisConfig`, `yAxisId`, `maxAxesPerSide`, `BravenChartController` | Multi-Axis, Axis Slots |
| Normalization | `NormalizationMode`, `MultiAxisNormalizer`, automatic detection | Multi-Axis, Tracking Lab, Gallery |
| Configurable X axis | `XAxisConfig`, `CategoryAxisConfig`, `CategoryLabelDensity`, `CategoryLabelOverflow` | Bar Lab Categories, Minor Ticks, Render Range |
| Streaming data | `StreamingConfig`, `StreamingController` | Streaming |
| Direct live ingestion | `LiveStreamController`, `StreamingBuffer`, external viewport ownership through `manageViewport: false`, frame-coalesced host following through `dataRevision` | Gallery, Live Stream — Live Navigator |
| Theming | `ChartTheme` and component theme types, including radial defaults | Theming, Pie Charts, Gallery |
| Loading and empty UX | `isLoading`, `ChartLoadingConfig`, `ChartEmptyStateConfig` | Loading States |
| Runtime control | `BravenChartController`, `ChartController`, callbacks | Axis Slots, Annotations, Live Stream |
| Host chart actions | Visible Workbench actions, `ChartContextAction` native menus, and configurable `ChartOverlayAction` buttons sharing one stable handle | Chart Workbench |
| Native chart data | `ChartTableModel`, `ChartDataTable`, copy and CSV export | Chart Artifacts, Chart Workbench, Pie Charts, Polar Column |
| Portable chart artifacts | `ChartArtifact`, canonical JSON, preview capture, hydration | Chart Artifacts, Pie Charts, Polar Column |
| Reusable chart workbench | `BravenChartWorkbench`, resizable Split view, revision-safe linked point identity, nestable shared mode and selector scope | Chart Workbench; all chart-family guides |
| Generated Dart source | `ChartDartSourceGenerator`, `ChartDartSourceOptions`, `ChartDisplayMode.source`, `ChartWorkbenchSourceState` | Chart Workbench; Line, Area, Bar, Scatter, Pie, Donut, Concentric Donut, and Polar Column guides |
| Document comparison | `ChartComparisonBuilder`, explicit mapping and source-preserving CSV | Chart Workbench |
| Chart grammar and fluent surface | sealed `Mark` hierarchy (`LineMark`, `AreaMark`, `BarMark`, `ScatterMark`, `CandlestickMark`, `TrendMark`), typed `Channel`/`CategoryChannel` encodings, `PlotSpec`, `PlotSpecLowering.lower()`, the `BravenPlot` widget, the chained `BravenChart` facade, coded `GrammarDiagnosticCode` failures, and the opt-in `package:braven_charts/braven_charts_fluent.dart` barrel of generated `withX`/`withoutX`/`inheritX`/`clearX`/`updateX` modifiers | Chart Grammar |
| Serializable/tool-driven charts | `ChartConfigBuilder`, chart agent interfaces and schemas, including complete advanced `bar`, `pie`, and `donut` contracts | Bar Lab, Pie Charts, API documentation |
| Dense-data performance | bounded buffers, viewport culling, render caches, Scatter spatial indexing and geometry-aware hit testing, Polar Column cached label eligibility and deterministic visual-density caps | Performance, Scatter Charts, Polar Column, Live Stream |

## Current boundary

Cartesian charts support one configurable X axis and multiple independent Y
axes. Multiple simultaneous X axes are not part of the public contract. One
Candlestick series may share a plot with Line, Area, and Scatter overlays; a
second Candlestick or same-plot Bar series is rejected in V1. A Pie
accepts exactly one `PieChartSeries`; a standalone Donut accepts one
`DonutChartSeries`; and two or more Donut series form one Concentric Donut
composition. Partition-radial charts have no Cartesian axes and cannot mix
with line, area, bar, or scatter series. Polar Column accepts one or more
compatible series, layered in declaration order, grouped into angular
sub-bands, or stacked with independent positive/negative accumulators, on
shared angular-category and radial-numeric axes. Category order, preset, and
unit must match. Targets, thresholds, and lower/upper intervals are absolute
references on that shared numeric scale. Intervals are available for ordinary,
layered, and grouped columns but not cumulative stacks. Polar Column cannot mix with either Cartesian or
partition-radial series.
