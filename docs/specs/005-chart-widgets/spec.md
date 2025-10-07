# Feature Specification: Chart Widgets

**Feature**: Chart Widgets (Layer 5)  
**Status**: Draft Specification  
**Created**: 2025-01-06  
**Dependencies**: Layer 0 (Foundation), Layer 1 (Core Rendering), Layer 2 (Coordinate System), Layer 3 (Theming), Layer 4 (Chart Types)

---

## 📋 Overview

### Purpose

Provide user-facing Flutter widgets that wrap chart layer implementations, enabling Flutter developers to easily integrate high-performance charts into their applications without complex boilerplate or manual resource management.

### Key Distinction: Multiple Charts vs Multiple Series

**Multiple Charts (Different Configurations):**
```dart
BravenChart(
  charts: [
    LineChart(series: [seriesA], config: LineChartConfig(lineStyle: LineStyle.smooth)),
    LineChart(series: [seriesB], config: LineChartConfig(lineStyle: LineStyle.dashed)),
  ],
)
```
- Each chart has **independent configuration**
- Different line styles, markers, widths, etc.
- Use when you need **mixed visual styles**

**Multiple Series (Shared Configuration):**
```dart
LineChart(
  series: [seriesA, seriesB],
  config: LineChartConfig(lineStyle: LineStyle.smooth), // Applies to BOTH
)
```
- All series share **ONE configuration**
- Uniform visual style
- Use when all data should look **the same**

### Problem Statement

**Current State (Layer 4):**
Layer 4 provides powerful chart implementations (LineChartLayer, AreaChartLayer, BarChartLayer, ScatterChartLayer), but these are low-level `RenderLayer` classes that require:

- Manual `RenderPipeline` setup and configuration
- Explicit `ObjectPool` creation and management
- Manual `Canvas` and `CustomPainter` integration
- Complex resource lifecycle management
- Deep understanding of rendering internals

**Example of current complexity:**
```dart
// 50+ lines just to display a line chart!
class MyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create pools
    final paintPool = ObjectPool<Paint>(factory: () => Paint(), reset: (p) {});
    final pathPool = ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset());
    // ... more pools
    
    // Create pipeline
    final pipeline = RenderPipeline(
      paintPool: paintPool,
      pathPool: pathPool,
      // ... 10+ more parameters
    );
    
    // Create layer
    final layer = LineChartLayer(
      series: [ChartSeries(id: 's1', points: myData)],
      config: LineChartConfig(),
      theme: ChartTheme.defaultLight,
      animationConfig: ChartAnimationConfig(),
      zIndex: 0,
    );
    
    // Create context
    final context = RenderContext(/* ... */);
    
    // Finally render
    layer.render(canvas, size, context);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Usage
CustomPaint(painter: MyChartPainter(), size: Size(400, 300))
```

**Desired State (Layer 5):**
Simple, idiomatic Flutter widgets that hide complexity:

```dart
// 5 lines - developer-friendly!
LineChart(
  data: myChartData,
  config: LineChartConfig(),
  theme: ChartTheme.defaultLight,
)
```

### Success Criteria

1. **Zero Boilerplate**: Developers can create charts with 5-10 lines of code
2. **Automatic Resource Management**: Widgets handle all pool/pipeline lifecycle
3. **Flutter Idioms**: Follows standard Flutter widget patterns (StatelessWidget/StatefulWidget)
4. **Hot Reload Support**: Full hot reload compatibility
5. **Memory Safety**: Zero memory leaks, proper dispose patterns
6. **Performance**: No performance degradation vs. manual layer usage
7. **Flexibility**: Advanced users can still customize pipeline/pools if needed
8. **Documentation**: Comprehensive examples and API docs

---

## 🎯 Functional Requirements

### FR-001: LineChart Widget (Internal - Not User-Facing)
**Priority**: Critical  
**User Story**: As a BravenChart developer (internal), I need a LineChart widget that wraps Layer 4's LineChartLayer for use within BravenChart.

**IMPORTANT**: This widget is **INTERNAL ONLY** - users access line charts via `BravenChart(chartType: ChartType.line)`, NOT by using `LineChart` directly.

**Requirements:**
- Widget accepts `List<ChartSeries>` (passed from BravenChart)
- Automatic RenderPipeline creation and management
- Supports all LineChartConfig options (straight/smooth/stepped, markers, etc.)
- Supports theme customization (inherited from BravenChart)
- Supports animation configuration
- Automatic sizing (respects parent constraints)
- Hot reload support
- Used internally by BravenChart when `chartType == ChartType.line`

**Internal Implementation (for reference only):**
```dart
// INTERNAL WIDGET - Users never see this directly
class LineChart extends StatefulWidget {
  final List<ChartSeries> series;
  final LineChartConfig? config;
  
  const LineChart({
    Key? key,
    required this.series,
    this.config,
  }) : super(key: key);
  
  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  late RenderPipeline _pipeline;
  late LineChartLayer _layer;
  
  @override
  void initState() {
    super.initState();
    _pipeline = RenderPipeline(/* ... */);
    _layer = LineChartLayer(/* ... */);
  }
  
  @override
  void dispose() {
    _pipeline.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartPainter(pipeline: _pipeline, layer: _layer),
    );
  }
}
```

---

### FR-002: AreaChart Widget
**Priority**: Critical  
**User Story**: As a Flutter developer, I want to display area charts with fills and gradients so that I can show trends and cumulative data.

**Requirements:**
- Widget accepts `List<ChartSeries>` or simplified data format
- Supports all AreaChartConfig options (solid/gradient fills, stacking, baseline)
- Automatic gradient shader caching
- Automatic stacking calculations
- Theme-aware fill colors
- Optional line overlay
- Callbacks for interactions

**Acceptance Criteria:**
```dart
// Stacked area chart
AreaChart(
  series: multiSeriesData,
  config: AreaChartConfig(
    fillStyle: AreaFillStyle.gradient,
    stacked: true,
    showLine: true,
  ),
)

// Single area with custom baseline
AreaChart(
  series: [ChartSeries(id: 's1', points: data)],
  config: AreaChartConfig(
    fillStyle: AreaFillStyle.solid,
    baseline: AreaBaseline.fixed(50.0),
    fillOpacity: 0.7,
  ),
)
```

---

### FR-003: BarChart Widget
**Priority**: Critical  
**User Story**: As a Flutter developer, I want to display bar charts (vertical/horizontal, grouped/stacked) so that I can compare categorical data.

**Requirements:**
- Widget accepts `List<ChartSeries>` or simplified data format
- Supports both vertical and horizontal orientations
- Supports grouped and stacked modes
- Automatic bar positioning calculations
- Rounded corners, borders, gradient fills
- Automatic category width calculation
- Handles negative values correctly

**Acceptance Criteria:**
```dart
// Grouped vertical bars
BarChart(
  series: salesByRegion,
  config: BarChartConfig(
    orientation: BarOrientation.vertical,
    groupingMode: BarGroupingMode.grouped,
    barWidth: 0.8,
    cornerRadius: 4.0,
  ),
)

// Stacked horizontal bars
BarChart(
  series: expenseCategories,
  config: BarChartConfig(
    orientation: BarOrientation.horizontal,
    groupingMode: BarGroupingMode.stacked,
    showBorder: true,
  ),
)
```

---

### FR-004: ScatterChart Widget
**Priority**: Critical  
**User Story**: As a Flutter developer, I want to display scatter plots with various marker shapes and sizes so that I can visualize correlations and distributions.

**Requirements:**
- Widget accepts `List<ChartSeries>` or simplified data format
- Supports 6 marker shapes (circle, square, triangle, diamond, cross, plus)
- Supports fixed and data-driven sizing modes
- Optional clustering for dense data
- Marker customization (filled, outlined, both)
- Supports large datasets (10,000+ points)

**Acceptance Criteria:**
```dart
// Basic scatter plot
ScatterChart(
  series: [ChartSeries(id: 's1', points: correlationData)],
  config: ScatterChartConfig(
    markerShape: MarkerShape.circle,
    markerSize: 6.0,
  ),
)

// Bubble chart (data-driven sizing)
ScatterChart(
  series: bubbleData,
  config: ScatterChartConfig(
    sizingMode: MarkerSizingMode.dataDriven,
    markerStyle: MarkerStyle.filled,
    enableClustering: true,
  ),
)
```

---

### FR-005: BravenChart Widget (ONLY User-Facing Widget)
**Priority**: Critical  
**User Story**: As a Flutter developer, I want a reusable chart container with title, legend, and controls so that I can create professional-looking charts quickly.

**CRITICAL ARCHITECTURAL DECISION:**
- **BravenChart is the ONLY user-facing widget** - users NEVER use `LineChart`, `AreaChart`, etc. directly
- Direct chart widget usage creates rendering nightmares (axis inconsistency, resource management, theme conflicts)
- All chart types are specified via `chartType` enum parameter, NOT separate widgets
- Axes are ALWAYS controlled by BravenChart (with full customization including hiding)

**Requirements:**
- Supports single chart mode via `series` parameter
- Supports multiple charts mode via `multiSeries` parameter - renders all in SAME coordinate space
- Chart type specified via `chartType` enum (line, area, bar, scatter)
- Optional title and subtitle
- Optional legend with full configurability
- Legend auto-aggregates series from all charts
- Optional toolbar (refresh, download, settings)
- Optional loading/error states
- **Highly customizable axes** (labels, grid, range, colors, fonts, visibility, etc.)
- **Axes can be completely hidden** for sparklines/embedded charts
- Charts naturally overlap (later series render on top)
- Responsive layout
- Customizable padding and decoration

**Acceptance Criteria:**
```dart
// Single chart (simple mode)
BravenChart(
  title: 'Monthly Sales',
  subtitle: 'Last 12 months',
  chartType: ChartType.line,
  series: salesData,  // Single series or list of series
  showLegend: true,
  legendPosition: LegendPosition.bottom,
  toolbar: ChartToolbar(
    showRefresh: true,
    showDownload: true,
    onRefresh: () => loadData(),
  ),
  xAxis: AxisConfig.defaults(),  // Default visible axes
  yAxis: AxisConfig.defaults(),
)

// Sparkline (no axes, no legend, no title - minimal)
BravenChart(
  chartType: ChartType.line,
  series: sparklineData,
  xAxis: AxisConfig.hidden(),  // Hide x-axis completely
  yAxis: AxisConfig.hidden(),  // Hide y-axis completely
  showLegend: false,
)

// Multiple series in SAME coordinate space
BravenChart(
  title: 'Stock Performance',
  subtitle: '5 Companies - Last 7 Days',
  chartType: ChartType.line,
  series: [blueSeries, greenSeries, orangeSeries, purpleSeries, yellowSeries],
  showLegend: true,
  legendPosition: LegendPosition.bottom,
  xAxis: AxisConfig(
    label: 'Date',
    showGridLines: true,
    gridLineStyle: GridLineStyle.dashed,
    labelRotation: 45.0,
  ),
  yAxis: AxisConfig(
    label: 'Value',
    showGridLines: true,
    range: AxisRange.auto(),
    labelFormatter: (value) => '\$${value.toStringAsFixed(2)}',
  ),
)

// Advanced: Fully customized axes
BravenChart(
  title: 'Temperature Monitoring',
  chartType: ChartType.line,
  series: temperatureData,
  xAxis: AxisConfig(
    visible: true,
    label: 'Time',
    labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
    showAxisLine: true,
    axisLineColor: Colors.grey.shade300,
    axisLineWidth: 2.0,
    showGridLines: true,
    gridLineColor: Colors.grey.shade200,
    gridLineWidth: 1.0,
    gridLineStyle: GridLineStyle.dotted,
    showTicks: true,
    tickLength: 8.0,
    tickColor: Colors.grey,
    tickInterval: TickInterval.auto(),
    labelFormatter: (value) => DateFormat('HH:mm').format(value),
    labelRotation: 0.0,
    position: AxisPosition.bottom,
  ),
  yAxis: AxisConfig(
    visible: true,
    label: 'Temperature (°C)',
    range: AxisRange.fixed(-10, 50),
    showGridLines: true,
    gridLineStyle: GridLineStyle.solid,
    labelFormatter: (value) => '${value.toInt()}°C',
    position: AxisPosition.left,
  ),
)

// Hidden axes for embedded/minimal display
BravenChart(
  chartType: ChartType.area,
  series: backgroundData,
  xAxis: AxisConfig.hidden(),
  yAxis: AxisConfig.hidden(),
  padding: EdgeInsets.zero,  // No padding for tight embedding
)
```

---

### FR-012: Real-Time Data Support
**Priority**: High  
**User Story**: As a Flutter developer, I want to display real-time data streams (live sensor readings, stock prices, monitoring dashboards) with automatic updates and smooth animations.

**Requirements:**
- Support Stream-based data binding for automatic updates
- Support manual updates via setState (traditional Flutter pattern)
- Support ChartController for incremental updates without full rebuild
- Throttle high-frequency updates to maintain 60 FPS
- Implement sliding window to limit displayed data points
- Preserve chart state (zoom/pan) during real-time updates
- Animate data additions/changes smoothly
- Handle backpressure when data arrives faster than render rate

**Acceptance Criteria:**
```dart
// ============================================================================
// PATTERN 1: Stream-based real-time (automatic updates)
// ============================================================================

// Full-featured real-time chart
BravenChart(
  title: 'CPU Usage',
  subtitle: 'Last 100 readings',
  chartType: ChartType.line,
  dataStream: cpuDataStream,  // Stream<List<ChartSeries>>
  realTimeConfig: RealTimeConfig(
    maxDataPoints: 100,           // Sliding window: keep last 100 points
    updateThrottle: Duration(milliseconds: 100),  // Max 10 updates/second
    animateUpdates: true,         // Smooth transitions
    slideWindow: true,            // Auto-remove old points
    preserveViewport: true,       // Keep user's zoom/pan
  ),
  showLegend: true,
  xAxis: AxisConfig(label: 'Time'),
  yAxis: AxisConfig(label: '%', range: AxisRange.fixed(0, 100)),
)

// Minimal sparkline (no axes/legend)
BravenChart(
  chartType: ChartType.line,
  dataStream: sensorDataStream,
  realTimeConfig: RealTimeConfig.monitoring(), // Preset: 100 points, 100ms throttle
  xAxis: AxisConfig.hidden(),
  yAxis: AxisConfig.hidden(),
)

// ============================================================================
// PATTERN 2: Controller-based real-time (fine-grained control)
// ============================================================================

final controller = ChartController(
  maxDataPoints: 100,
  updateThrottle: Duration(milliseconds: 100),
);

BravenChart(
  title: 'Live Stock Prices',
  chartType: ChartType.line,
  controller: controller,
  series: [
    ChartSeries(id: 'AAPL', name: 'Apple', points: appleData),
    ChartSeries(id: 'GOOGL', name: 'Google', points: googleData),
  ],
  showLegend: true,
  xAxis: AxisConfig.defaults(),
  yAxis: AxisConfig.defaults(),
)

// Incremental updates (no full rebuild)
controller.addPoint('AAPL', newPoint);  // Add single point to series
controller.removeOldestPoint('GOOGL');  // Remove oldest point
controller.clearSeries('AAPL');         // Clear all data

// ============================================================================
// PATTERN 3: Manual updates with setState (traditional Flutter)
// ============================================================================

class _MyChartState extends State<MyChart> {
  List<ChartDataPoint> _data = [];
  
  void _onNewData(ChartDataPoint point) {
    setState(() {
      _data.add(point);
      if (_data.length > 100) _data.removeAt(0);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      chartType: ChartType.line,
      series: [ChartSeries(id: 's1', points: _data)],
      config: ChartConfig(animateUpdates: true),
      xAxis: AxisConfig.hidden(),  // Sparkline style
      yAxis: AxisConfig.hidden(),
    );
  }
}

// ============================================================================
// PATTERN 4: Multi-series real-time (same chart)
// ============================================================================

final controller = ChartController(maxDataPoints: 100);

BravenChart(
  title: 'Multi-Sensor Dashboard',
  chartType: ChartType.line,
  controller: controller,
  series: [
    ChartSeries(id: 'temp', name: 'Temperature', points: tempData),
    ChartSeries(id: 'humid', name: 'Humidity', points: humidData),
    ChartSeries(id: 'pressure', name: 'Pressure', points: pressureData),
  ],
  showLegend: true,
  xAxis: AxisConfig(label: 'Time'),
  yAxis: AxisConfig(label: 'Value'),
)

// Update different series independently
controller.addPoint('temp', newTempPoint);
controller.addPoint('humid', newHumidPoint);
controller.addPoint('pressure', newPressurePoint);
```

**RealTimeConfig Properties:**
- `maxDataPoints`: Maximum points to keep (oldest removed automatically)
- `updateThrottle`: Minimum duration between renders (throttle high-frequency updates)
- `animateUpdates`: Enable/disable smooth transitions
- `slideWindow`: Auto-remove old points when max reached
- `preserveViewport`: Keep user's zoom/pan state during updates
- `onBufferOverflow`: Callback when data arrives faster than throttle allows

**Performance Requirements:**
- Stream updates throttled to maintain 60 FPS
- Dropped frames when data arrives >60 FPS (drop oldest queued updates)
- Sliding window removes old data in O(1) time
- Incremental updates via controller avoid full widget rebuild
- Animation overhead <2ms per update

---

### FR-006: Automatic Resource Management
**Priority**: Critical  
**User Story**: As a Flutter developer, I want widgets to automatically manage rendering resources so that I don't have memory leaks or performance issues.

**Requirements:**
- Widgets automatically create `RenderPipeline` on first build
- Widgets reuse pipeline across rebuilds (unless configuration changes)
- Widgets automatically create and configure `ObjectPool` instances
- Widgets properly dispose all resources in `dispose()`
- Widgets detect configuration changes and recreate only what's necessary
- Zero memory leaks under normal usage

**Acceptance Criteria:**
- Memory profiler shows zero leaks after repeated widget builds
- Object pools are reused across rebuilds (same config)
- Pools are recreated only when pool config changes
- Pipeline is disposed when widget is disposed
- Hot reload works without memory accumulation

---

### FR-007: Simplified Data Binding
**Priority**: High  
**User Story**: As a Flutter developer, I want to provide data in simple formats (lists, maps) so that I don't need to create complex data structures.

**Requirements:**
- Widgets accept `List<ChartSeries>` (standard format)
- Widgets provide named constructors for simplified data:
  - `.fromValues(List<num>)` - single series from values
  - `.fromMap(Map<String, List<num>>)` - multi-series from map
  - `.fromJson(String)` - parse JSON data
- Automatic x-value generation if not provided
- Automatic series ID/name generation

**Acceptance Criteria:**
```dart
// From values (simplest)
LineChart.fromValues([10, 20, 15, 25, 30])

// From map (multi-series)
LineChart.fromMap({
  'Sales': [100, 120, 115, 130],
  'Target': [110, 110, 110, 110],
})

// From JSON
LineChart.fromJson('{"series": [{"name": "A", "data": [1,2,3]}]}')

// Standard format (full control)
LineChart(series: [
  ChartSeries(id: 's1', name: 'Sales', points: [
    ChartDataPoint(x: 0, y: 100),
    ChartDataPoint(x: 1, y: 120),
  ]),
])
```

---

### FR-008: Event Callbacks
**Priority**: High  
**User Story**: As a Flutter developer, I want to respond to user interactions (taps, hovers) so that I can build interactive dashboards.

**Requirements:**
- `onDataPointTap(ChartDataPoint, String seriesId)` - called when data point tapped
- `onDataPointHover(ChartDataPoint?, String? seriesId)` - called on hover (null when hover ends)
- `onChartTap(Offset)` - called when chart background tapped
- `onSeriesSelected(String seriesId)` - called when series selected (e.g., in legend)
- Callbacks receive enough context to identify what was interacted with

**Acceptance Criteria:**
```dart
LineChart(
  series: data,
  onDataPointTap: (point, seriesId) {
    showDialog(
      context: context,
      builder: (_) => Alert('Tapped ${point.y} in $seriesId'),
    );
  },
  onDataPointHover: (point, seriesId) {
    if (point != null) {
      setState(() => hoveredValue = point.y);
    }
  },
)
```

---

### FR-009: Theme Integration
**Priority**: High  
**User Story**: As a Flutter developer, I want charts to respect app themes and support dark mode so that my charts look consistent with my app.

**Requirements:**
- Widgets accept `ChartTheme` parameter
- Widgets provide `theme` property that defaults to `ChartTheme.defaultLight`
- Widgets can inherit theme from `ChartThemeProvider` (optional)
- Widgets respond to Flutter's `Theme` brightness for auto dark mode
- Theme changes trigger efficient repaints (no full rebuild)

**Acceptance Criteria:**
```dart
// Explicit theme
LineChart(
  series: data,
  theme: ChartTheme.defaultDark,
)

// Theme provider (optional)
ChartThemeProvider(
  theme: ChartTheme.corporate,
  child: Column(
    children: [
      LineChart(series: data1), // Uses corporate theme
      BarChart(series: data2),  // Uses corporate theme
    ],
  ),
)

// Auto dark mode
LineChart(
  series: data,
  adaptToTheme: true, // Uses ChartTheme.defaultDark if Theme.brightness is dark
)
```

---

### FR-010: Loading and Error States
**Priority**: Medium  
**User Story**: As a Flutter developer, I want to show loading/error states while data is fetching so that users have feedback.

**Requirements:**
- Widgets accept `isLoading` boolean parameter
- Widgets show loading indicator when `isLoading = true`
- Widgets accept `errorMessage` string parameter
- Widgets show error UI when `errorMessage` is not null
- Customizable loading/error widgets via builder parameters

**Acceptance Criteria:**
```dart
LineChart(
  series: data,
  isLoading: _isLoading,
  loadingBuilder: (context) => CircularProgressIndicator(),
)

LineChart(
  series: data,
  errorMessage: _errorMessage,
  errorBuilder: (context, message) => Text('Error: $message'),
)
```

---

### FR-013: Annotations and Markers
**Priority**: High  
**User Story**: As a Flutter developer, I want to add annotations and markers to my charts so that I can highlight important data points, ranges, and add context to visualizations.

**ARCHITECTURE NOTE**: This FR integrates the comprehensive Annotation System (defined in `ANNOTATION_SYSTEM_ARCHITECTURE.md`) into the BravenChart widget API. The annotation system itself is implemented in Layer 7, but BravenChart provides the widget API for managing annotations.

**Requirements:**
- BravenChart accepts `annotations` list parameter
- Support all 5 annotation types:
  - **Text Annotations**: Free-floating labels at arbitrary coordinates
  - **Point Annotations**: Mark specific data points
  - **Range Annotations**: Highlight rectangular areas (time/value ranges)
  - **Threshold Annotations**: Horizontal/vertical lines with labels
  - **Trend Annotations**: Regression lines, moving averages, etc.
- Annotations render ABOVE chart data (on top)
- Annotations participate in hit-testing for interaction
- Support programmatic annotation management via `ChartController`
- Annotations respect chart theme
- Annotations persist through hot reload
- Annotations work with real-time data updates
- Support data point markers (different from scatter chart markers)

**Acceptance Criteria:**
```dart
// ============================================================================
// SIMPLE ANNOTATIONS
// ============================================================================

// Highlight threshold line
BravenChart(
  chartType: ChartType.line,
  series: temperatureData,
  annotations: [
    ThresholdAnnotation(
      axis: Axis.horizontal,
      value: 32.0,
      label: 'Freezing Point',
      style: ThresholdStyle.danger(),  // Red dashed line
    ),
  ],
)

// Mark important data point
BravenChart(
  chartType: ChartType.line,
  series: stockPriceData,
  annotations: [
    PointAnnotation(
      seriesId: 'AAPL',
      dataPointIndex: 42,
      label: 'All-Time High',
      markerStyle: MarkerStyle.star(color: Colors.gold, size: 16.0),
      tooltipText: 'Peak: \$182.94 on March 15, 2024',
    ),
  ],
)

// ============================================================================
// RANGE ANNOTATIONS (Highlight periods)
// ============================================================================

// Highlight time range (e.g., recession period)
BravenChart(
  chartType: ChartType.line,
  series: economicData,
  annotations: [
    RangeAnnotation(
      axis: Axis.vertical,  // Vertical range = time period
      start: DateTime(2020, 3, 1),
      end: DateTime(2020, 12, 31),
      label: 'COVID-19 Recession',
      style: RangeStyle.subtle(
        fillColor: Colors.red.withOpacity(0.1),
        borderColor: Colors.red.withOpacity(0.3),
      ),
    ),
  ],
)

// Highlight value range (e.g., normal operating range)
BravenChart(
  chartType: ChartType.line,
  series: sensorReadings,
  annotations: [
    RangeAnnotation(
      axis: Axis.horizontal,  // Horizontal range = value range
      start: 18.0,
      end: 24.0,
      label: 'Normal Range',
      style: RangeStyle.success(opacity: 0.15),
      position: RangePosition.behind,  // Render behind chart data
    ),
  ],
)

// ============================================================================
// TEXT ANNOTATIONS (Free-floating labels)
// ============================================================================

// Add free-text label at specific coordinate
BravenChart(
  chartType: ChartType.line,
  series: salesData,
  annotations: [
    TextAnnotation(
      position: ChartPosition(x: DateTime(2024, 6, 1), y: 150000),
      text: 'Launch of Product X',
      markerStyle: MarkerStyle.pin(),  // Pin marker at position
      titleStyle: TitleStyle.callout(
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue,
      ),
      allowDragging: true,  // User can reposition
      allowEditing: true,   // User can edit text in-place
    ),
  ],
)

// ============================================================================
// TREND ANNOTATIONS (Statistical overlays)
// ============================================================================

// Add linear regression trend line
BravenChart(
  chartType: ChartType.scatter,
  series: correlationData,
  annotations: [
    TrendAnnotation.linearRegression(
      seriesId: 'dataset1',
      label: 'Best Fit Line',
      style: LineStyle.dashed(color: Colors.red, width: 2.0),
      showEquation: true,  // Display y = mx + b
      showRSquared: true,  // Display R² value
    ),
  ],
)

// Add moving average overlay
BravenChart(
  chartType: ChartType.line,
  series: stockPriceData,
  annotations: [
    TrendAnnotation.movingAverage(
      seriesId: 'AAPL',
      window: 50,  // 50-day moving average
      label: '50-day MA',
      style: LineStyle.smooth(color: Colors.orange, width: 2.0),
    ),
  ],
)

// ============================================================================
// MULTIPLE ANNOTATIONS
// ============================================================================

BravenChart(
  title: 'Stock Analysis with Annotations',
  chartType: ChartType.line,
  series: stockData,
  annotations: [
    // Background range for earnings season
    RangeAnnotation(
      axis: Axis.vertical,
      start: DateTime(2024, 4, 10),
      end: DateTime(2024, 4, 20),
      label: 'Earnings Week',
      style: RangeStyle.info(opacity: 0.1),
      position: RangePosition.behind,
    ),
    
    // Threshold line for target price
    ThresholdAnnotation(
      axis: Axis.horizontal,
      value: 180.0,
      label: 'Price Target',
      style: ThresholdStyle.custom(
        lineColor: Colors.green,
        lineStyle: LineStyle.dashed,
        labelPosition: ThresholdLabelPosition.start,
      ),
    ),
    
    // Mark specific event
    PointAnnotation(
      seriesId: 'AAPL',
      dataPointIndex: 25,
      label: 'Product Launch',
      markerStyle: MarkerStyle.flag(color: Colors.blue),
      tooltipText: 'iPhone 15 Released',
    ),
    
    // Moving average trend
    TrendAnnotation.movingAverage(
      seriesId: 'AAPL',
      window: 20,
      label: '20-day MA',
      style: LineStyle.smooth(color: Colors.orange.withOpacity(0.7)),
    ),
  ],
)

// ============================================================================
// PROGRAMMATIC ANNOTATION MANAGEMENT
// ============================================================================

final controller = ChartController();

BravenChart(
  chartType: ChartType.line,
  series: data,
  controller: controller,
)

// Add annotation dynamically
controller.addAnnotation(
  PointAnnotation(
    seriesId: 's1',
    dataPointIndex: 10,
    label: 'New Peak',
  ),
);

// Remove annotation
controller.removeAnnotation(annotationId);

// Update annotation
controller.updateAnnotation(
  annotationId,
  label: 'Updated Label',
  markerStyle: MarkerStyle.star(),
);

// Clear all annotations
controller.clearAnnotations();

// ============================================================================
// DATA POINT MARKERS (Different from scatter chart markers)
// ============================================================================

// Show markers on ALL data points
BravenChart(
  chartType: ChartType.line,
  series: salesData,
  config: ChartConfig(
    showDataPointMarkers: true,
    dataPointMarkerStyle: MarkerStyle.circle(size: 6.0),
  ),
)

// Show markers only on hover
BravenChart(
  chartType: ChartType.line,
  series: salesData,
  config: ChartConfig(
    showDataPointMarkers: false,
    showMarkersOnHover: true,
    hoverMarkerStyle: MarkerStyle.circle(size: 8.0, outlined: true),
  ),
)

// Custom markers per series
BravenChart(
  chartType: ChartType.line,
  series: [
    ChartSeries(
      id: 's1',
      points: data1,
      markerStyle: MarkerStyle.circle(size: 6.0),  // Per-series override
    ),
    ChartSeries(
      id: 's2',
      points: data2,
      markerStyle: MarkerStyle.square(size: 6.0),
    ),
  ],
)
```

**RealTimeConfig Properties:**
- `maxDataPoints`: Maximum points to keep (oldest removed automatically)
- `updateThrottle`: Minimum duration between renders (throttle high-frequency updates)
- `animateUpdates`: Enable/disable smooth transitions
- `slideWindow`: Auto-remove old points when max reached
- `preserveViewport`: Keep user's zoom/pan state during updates
- `onBufferOverflow`: Callback when data arrives faster than throttle allows

**Annotation Types Summary:**

| Type | Purpose | Key Properties |
|------|---------|----------------|
| **TextAnnotation** | Free-floating labels | `position`, `text`, `allowDragging`, `allowEditing` |
| **PointAnnotation** | Mark data points | `seriesId`, `dataPointIndex`, `snapBehavior` |
| **RangeAnnotation** | Highlight areas | `axis`, `start`, `end`, `position` (behind/inFront) |
| **ThresholdAnnotation** | Reference lines | `axis`, `value`, `labelPosition` |
| **TrendAnnotation** | Statistical overlays | `type` (linear/moving average/polynomial), `seriesId` |

**Marker vs Annotation Distinction:**
- **Data Point Markers**: Visual indicators on data points (part of chart styling)
  - Configured via `ChartConfig.dataPointMarkerStyle`
  - Applied uniformly or per-series
  - Always tied to data points
  - Render AS PART of the chart layer
  
- **Annotations**: Semantic overlays with labels and context
  - Configured via `annotations` parameter
  - Can be at arbitrary positions
  - Have labels, tooltips, and rich styling
  - Render ABOVE the chart layer
  - Support user interaction (drag, edit, tap)

**Performance Requirements:**
- Viewport culling: Only render visible annotations
- Object pooling: Reuse annotation rendering resources
- Batch rendering: Group similar annotations
- Hit-test optimization: Spatial indexing for interaction
- Maximum 500 annotations before performance warning

**Integration with Annotation System:**
- BravenChart passes annotations to underlying `AnnotationLayer`
- AnnotationLayer (Layer 7) handles rendering and interaction
- Universal Marker System provides marker rendering
- ChartController provides annotation CRUD operations
- Annotations persist in chart state across rebuilds

---

## 🏗️ Technical Architecture

### Widget Class Hierarchy

```
StatefulWidget (Flutter)
├── LineChart                    # Single chart type
├── AreaChart                    # Single chart type
├── BarChart                     # Single chart type
├── ScatterChart                 # Single chart type
└── CompositeChart              # Multiple charts in same coordinate space

StatelessWidget (Flutter)
└── BravenChart                 # Main chart widget with title/legend/toolbar
    ├── child: (any single chart widget)
    └── charts: (creates CompositeChart internally)
```

### Component Structure

```
lib/src/widgets/
├── charts/
│   ├── line_chart.dart              # LineChart widget
│   ├── area_chart.dart              # AreaChart widget
│   ├── bar_chart.dart               # BarChart widget
│   ├── scatter_chart.dart           # ScatterChart widget
│   ├── composite_chart.dart         # CompositeChart widget (multi-chart composition)
│   └── base_chart_widget.dart       # Shared base logic (if needed)
├── containers/
│   ├── braven_chart.dart            # BravenChart widget (main user-facing widget)
│   ├── chart_legend.dart            # Legend component
│   └── chart_toolbar.dart           # Toolbar component
├── controllers/
│   ├── chart_controller.dart        # ChartController for real-time updates & annotations
│   └── real_time_config.dart        # RealTimeConfig configuration
├── annotations/
│   ├── text_annotation.dart         # TextAnnotation widget/model
│   ├── point_annotation.dart        # PointAnnotation widget/model
│   ├── range_annotation.dart        # RangeAnnotation widget/model
│   ├── threshold_annotation.dart    # ThresholdAnnotation widget/model
│   ├── trend_annotation.dart        # TrendAnnotation widget/model
│   ├── annotation_base.dart         # Base ChartAnnotation class
│   └── annotation_styles.dart       # MarkerStyle, TitleStyle, RangeStyle, etc.
├── painters/
│   ├── chart_painter.dart           # Base CustomPainter for single chart
│   ├── composite_chart_painter.dart # CustomPainter for multiple charts
│   └── chart_painter_config.dart    # Configuration for painter
├── theme/
│   └── chart_theme_provider.dart    # InheritedWidget for theme
└── widgets.dart                      # Barrel file
```

### Key Classes

#### 1. Chart Widget Base Pattern

```dart
class LineChart extends StatefulWidget {
  /// The data series to display
  final List<ChartSeries> series;
  
  /// Chart configuration
  final LineChartConfig config;
  
  /// Visual theme
  final ChartTheme? theme;
  
  /// Animation configuration
  final ChartAnimationConfig? animationConfig;
  
  /// Callback when data point is tapped
  final void Function(ChartDataPoint point, String seriesId)? onDataPointTap;
  
  /// Callback when data point is hovered
  final void Function(ChartDataPoint? point, String? seriesId)? onDataPointHover;
  
  /// Loading state
  final bool isLoading;
  
  /// Error message (if any)
  final String? errorMessage;
  
  /// Custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;
  
  /// Custom error widget builder
  final Widget Function(BuildContext, String)? errorBuilder;
  
  const LineChart({
    Key? key,
    required this.series,
    this.config = const LineChartConfig(),
    this.theme,
    this.animationConfig,
    this.onDataPointTap,
    this.onDataPointHover,
    this.isLoading = false,
    this.errorMessage,
    this.loadingBuilder,
    this.errorBuilder,
  }) : super(key: key);
  
  /// Create from simple value list
  factory LineChart.fromValues(
    List<num> values, {
    List<String>? labels,
    LineChartConfig? config,
    ChartTheme? theme,
  }) {
    final points = values.asMap().entries.map((e) => 
      ChartDataPoint(x: e.key.toDouble(), y: e.value.toDouble())
    ).toList();
    
    return LineChart(
      series: [ChartSeries(id: 'series_1', name: 'Data', points: points)],
      config: config ?? const LineChartConfig(),
      theme: theme,
    );
  }
  
  /// Create from map of series
  factory LineChart.fromMap(
    Map<String, List<num>> seriesMap, {
    LineChartConfig? config,
    ChartTheme? theme,
  }) {
    final series = seriesMap.entries.map((entry) {
      final points = entry.value.asMap().entries.map((e) =>
        ChartDataPoint(x: e.key.toDouble(), y: e.value.toDouble())
      ).toList();
      return ChartSeries(id: entry.key, name: entry.key, points: points);
    }).toList();
    
    return LineChart(
      series: series,
      config: config ?? const LineChartConfig(),
      theme: theme,
    );
  }
  
  @override
  State<LineChart> createState() => _LineChartState();
}
```

#### 2. Chart Widget State (Resource Management)

```dart
class _LineChartState extends State<LineChart> {
  // Rendering resources (created once, reused)
  late RenderPipeline _pipeline;
  late ObjectPool<Paint> _paintPool;
  late ObjectPool<Path> _pathPool;
  late ObjectPool<TextPainter> _textPainterPool;
  late TextLayoutCache _textCache;
  late PerformanceMonitor _perfMonitor;
  
  // Chart layer (recreated when data/config changes)
  late LineChartLayer _layer;
  
  // Resource initialization flag
  bool _resourcesInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeResources();
    _createLayer();
  }
  
  @override
  void didUpdateWidget(LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recreate layer if data or config changed
    if (oldWidget.series != widget.series ||
        oldWidget.config != widget.config ||
        oldWidget.theme != widget.theme) {
      _createLayer();
    }
  }
  
  void _initializeResources() {
    // Create object pools (reusable across rebuilds)
    _paintPool = ObjectPool<Paint>(
      factory: () => Paint(),
      reset: (paint) => paint
        ..color = Colors.black
        ..strokeWidth = 1.0
        ..style = PaintingStyle.fill,
      maxSize: 100,
    );
    
    _pathPool = ObjectPool<Path>(
      factory: () => Path(),
      reset: (path) => path.reset(),
      maxSize: 50,
    );
    
    _textPainterPool = ObjectPool<TextPainter>(
      factory: () => TextPainter(textDirection: TextDirection.ltr),
      reset: (tp) => tp.text = null,
      maxSize: 50,
    );
    
    _textCache = LinkedHashMapTextLayoutCache(maxSize: 1000);
    _perfMonitor = StopwatchPerformanceMonitor();
    
    // Create render pipeline
    _pipeline = RenderPipeline(
      paintPool: _paintPool,
      pathPool: _pathPool,
      textPainterPool: _textPainterPool,
      textCache: _textCache,
      performanceMonitor: _perfMonitor,
      culler: const ViewportCuller(),
      initialViewport: Rect.zero, // Will be updated in painter
    );
    
    _resourcesInitialized = true;
  }
  
  void _createLayer() {
    final theme = widget.theme ?? ChartTheme.defaultLight;
    final animConfig = widget.animationConfig ?? const ChartAnimationConfig();
    
    _layer = LineChartLayer(
      series: widget.series,
      config: widget.config,
      theme: theme,
      animationConfig: animConfig,
      zIndex: 0,
    );
  }
  
  @override
  void dispose() {
    // Clean up all resources
    _layer.dispose();
    _pipeline.dispose();
    _paintPool.dispose();
    _pathPool.dispose();
    _textPainterPool.dispose();
    _textCache.clear();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (widget.isLoading) {
      return widget.loadingBuilder?.call(context) ?? 
        const Center(child: CircularProgressIndicator());
    }
    
    // Handle error state
    if (widget.errorMessage != null) {
      return widget.errorBuilder?.call(context, widget.errorMessage!) ??
        Center(child: Text('Error: ${widget.errorMessage}'));
    }
    
    // Render chart
    return CustomPaint(
      painter: ChartPainter(
        pipeline: _pipeline,
        layer: _layer,
        onTap: widget.onDataPointTap,
        onHover: widget.onDataPointHover,
      ),
      size: Size.infinite, // Respects parent constraints
    );
  }
}
```

#### 3. ChartPainter (Rendering Bridge)

```dart
class ChartPainter extends CustomPainter {
  final RenderPipeline pipeline;
  final ChartLayer layer;
  final void Function(ChartDataPoint, String)? onTap;
  final void Function(ChartDataPoint?, String?)? onHover;
  
  ChartPainter({
    required this.pipeline,
    required this.layer,
    this.onTap,
    this.onHover,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Update pipeline viewport to match widget size
    pipeline.updateViewport(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create render context
    final context = RenderContext(
      canvas: canvas,
      size: size,
      viewport: Rect.fromLTWH(0, 0, size.width, size.height),
      culler: pipeline.culler,
      paintPool: pipeline.paintPool,
      pathPool: pipeline.pathPool,
      textPainterPool: pipeline.textPainterPool,
      textCache: pipeline.textCache,
      perfMonitor: pipeline.performanceMonitor,
    );
    
    // Render layer
    layer.render(canvas, size, context);
  }
  
  @override
  bool shouldRepaint(ChartPainter oldDelegate) {
    // Repaint if layer changed
    return oldDelegate.layer != layer;
  }
}
```

#### 4. CompositeChart Widget (Multi-Chart Composition)

```dart
class CompositeChart extends StatefulWidget {
  /// Multiple charts to render in SAME coordinate space
  final List<Widget> charts;
  
  /// Shared theme for all charts (can be overridden per chart)
  final ChartTheme? theme;
  
  /// X-axis configuration
  final AxisConfig? xAxis;
  
  /// Y-axis configuration
  final AxisConfig? yAxis;
  
  /// Secondary Y-axis (optional, for dual-axis charts)
  final AxisConfig? secondaryYAxis;
  
  const CompositeChart({
    Key? key,
    required this.charts,
    this.theme,
    this.xAxis,
    this.yAxis,
    this.secondaryYAxis,
  }) : super(key: key);
  
  @override
  State<CompositeChart> createState() => _CompositeChartState();
}

class _CompositeChartState extends State<CompositeChart> {
  // Shared rendering resources
  late RenderPipeline _pipeline;
  late ObjectPool<Paint> _paintPool;
  late ObjectPool<Path> _pathPool;
  late ObjectPool<TextPainter> _textPainterPool;
  late TextLayoutCache _textCache;
  late PerformanceMonitor _perfMonitor;
  
  // Extracted layers from child chart widgets
  List<ChartLayer> _layers = [];
  
  @override
  void initState() {
    super.initState();
    _initializeResources();
    _extractLayers();
  }
  
  @override
  void didUpdateWidget(CompositeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recreate layers if charts changed
    if (oldWidget.charts != widget.charts) {
      _extractLayers();
    }
  }
  
  void _initializeResources() {
    // Same resource initialization as single chart
    _paintPool = ObjectPool<Paint>(/* ... */);
    _pathPool = ObjectPool<Path>(/* ... */);
    _textPainterPool = ObjectPool<TextPainter>(/* ... */);
    _textCache = LinkedHashMapTextLayoutCache(maxSize: 1000);
    _perfMonitor = StopwatchPerformanceMonitor();
    
    _pipeline = RenderPipeline(
      paintPool: _paintPool,
      pathPool: _pathPool,
      textPainterPool: _textPainterPool,
      textCache: _textCache,
      performanceMonitor: _perfMonitor,
      culler: const ViewportCuller(),
      initialViewport: Rect.zero,
    );
  }
  
  void _extractLayers() {
    // Extract ChartLayer from each chart widget
    // This is done by calling a method on the widget (or accessing state)
    _layers = widget.charts
      .map((chartWidget) => _getLayerFromWidget(chartWidget))
      .whereType<ChartLayer>()
      .toList();
  }
  
  ChartLayer? _getLayerFromWidget(Widget widget) {
    // Extract the layer from chart widget
    // LineChart, AreaChart, etc. expose their internal layer
    if (widget is LineChart) {
      return widget.toLayer(); // Factory method to create layer
    } else if (widget is AreaChart) {
      return widget.toLayer();
    } else if (widget is BarChart) {
      return widget.toLayer();
    } else if (widget is ScatterChart) {
      return widget.toLayer();
    }
    return null;
  }
  
  @override
  void dispose() {
    // Clean up all layers
    for (final layer in _layers) {
      layer.dispose();
    }
    
    // Clean up shared resources
    _pipeline.dispose();
    _paintPool.dispose();
    _pathPool.dispose();
    _textPainterPool.dispose();
    _textCache.clear();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CompositeChartPainter(
        pipeline: _pipeline,
        layers: _layers,
      ),
      size: Size.infinite,
    );
  }
}

class CompositeChartPainter extends CustomPainter {
  final RenderPipeline pipeline;
  final List<ChartLayer> layers;
  
  CompositeChartPainter({
    required this.pipeline,
    required this.layers,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Update pipeline viewport
    pipeline.updateViewport(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create SHARED render context
    final context = RenderContext(
      canvas: canvas,
      size: size,
      viewport: Rect.fromLTWH(0, 0, size.width, size.height),
      culler: pipeline.culler,
      paintPool: pipeline.paintPool,
      pathPool: pipeline.pathPool,
      textPainterPool: pipeline.textPainterPool,
      textCache: pipeline.textCache,
      perfMonitor: pipeline.performanceMonitor,
    );
    
    // Render all layers in order (natural overlap)
    for (final layer in layers) {
      layer.render(canvas, size, context);
    }
  }
  
  @override
  bool shouldRepaint(CompositeChartPainter oldDelegate) {
    // Repaint if any layer changed
    return !_listsEqual(oldDelegate.layers, layers);
  }
  
  bool _listsEqual(List<ChartLayer> a, List<ChartLayer> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

#### 5. BravenChart with Composite Support

```dart
/// ONLY user-facing widget - users never use LineChart/AreaChart/etc. directly
class BravenChart extends StatefulWidget {
  // ==================== CONTENT ====================
  
  final String? title;
  final String? subtitle;
  
  /// Chart type (line, area, bar, scatter)
  final ChartType chartType;
  
  /// Single series or list of series (all rendered in same coordinate space)
  final List<ChartSeries> series;
  
  /// Chart configuration (styling, behavior)
  final ChartConfig? config;
  
  // ==================== REAL-TIME ====================
  
  /// Stream for automatic real-time updates
  final Stream<List<ChartSeries>>? dataStream;
  
  /// Controller for manual incremental updates
  final ChartController? controller;
  
  /// Real-time configuration (throttling, sliding window, etc.)
  final RealTimeConfig? realTimeConfig;
  
  // ==================== LAYOUT ====================
  
  /// Show legend (aggregates all series)
  final bool showLegend;
  final LegendPosition legendPosition;
  final LegendConfig? legendConfig;
  
  /// Toolbar (refresh, download, settings)
  final ChartToolbar? toolbar;
  
  /// Padding around chart
  final EdgeInsets padding;
  
  // ==================== AXES ====================
  
  /// X-axis configuration (can be completely hidden)
  final AxisConfig xAxis;
  
  /// Y-axis configuration (can be completely hidden)
  final AxisConfig yAxis;
  
  /// Secondary Y-axis (optional, for dual-axis charts)
  final AxisConfig? secondaryYAxis;
  
  // ==================== ANNOTATIONS ====================
  
  /// List of annotations to display on chart
  /// Supports: Text, Point, Range, Threshold, and Trend annotations
  final List<ChartAnnotation> annotations;
  
  /// Whether annotations should be interactive (draggable, editable)
  final bool interactiveAnnotations;
  
  // ==================== INTERACTION ====================
  
  /// Callbacks
  final void Function(ChartDataPoint point, String seriesId)? onDataPointTap;
  final void Function(ChartDataPoint? point, String? seriesId)? onDataPointHover;
  final void Function(Offset position)? onChartTap;
  final void Function(String seriesId)? onSeriesSelected;
  final void Function(ChartAnnotation annotation)? onAnnotationTap;
  final void Function(ChartAnnotation annotation, Offset newPosition)? onAnnotationDragged;
  
  const BravenChart({
    Key? key,
    this.title,
    this.subtitle,
    required this.chartType,
    required this.series,
    this.config,
    // Real-time
    this.dataStream,
    this.controller,
    this.realTimeConfig,
    // Layout
    this.showLegend = false,
    this.legendPosition = LegendPosition.bottom,
    this.legendConfig,
    this.toolbar,
    this.padding = const EdgeInsets.all(16.0),
    // Axes
    this.xAxis = const AxisConfig(),  // Default visible
    this.yAxis = const AxisConfig(),  // Default visible
    this.secondaryYAxis,
    // Annotations
    this.annotations = const [],
    this.interactiveAnnotations = true,
    // Interaction
    this.onDataPointTap,
    this.onDataPointHover,
    this.onChartTap,
    this.onSeriesSelected,
    this.onAnnotationTap,
    this.onAnnotationDragged,
  }) : super(key: key);
  
  @override
  State<BravenChart> createState() => _BravenChartState();
}

class _BravenChartState extends State<BravenChart> {
  late RenderPipeline _pipeline;
  late List<ChartSeries> _currentSeries;
  StreamSubscription? _streamSubscription;
  
  @override
  void initState() {
    super.initState();
    _currentSeries = widget.series;
    _initializePipeline();
    _subscribeToStream();
    _attachController();
  }
  
  void _initializePipeline() {
    // Create appropriate chart layer based on chartType
    // Create RenderPipeline
    // Initialize resources
  }
  
  void _subscribeToStream() {
    if (widget.dataStream != null) {
      // Subscribe to stream with throttling from realTimeConfig
    }
  }
  
  void _attachController() {
    if (widget.controller != null) {
      widget.controller!.addListener(_onControllerUpdate);
    }
  }
  
  void _onControllerUpdate() {
    setState(() {
      _currentSeries = widget.controller!.getAllSeries();
    });
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    widget.controller?.removeListener(_onControllerUpdate);
    _pipeline.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) _buildTitle(context),
        if (widget.subtitle != null) _buildSubtitle(context),
        if (widget.toolbar != null) widget.toolbar!,
        Expanded(child: _buildChart()),
        if (widget.showLegend) _buildLegend(context),
      ],
    );
  }
  
  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(widget.title!, style: Theme.of(context).textTheme.titleLarge),
    );
  }
  
  Widget _buildSubtitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(widget.subtitle!, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
  
  Widget _buildChart() {
    return Padding(
      padding: widget.padding,
      child: CustomPaint(
        painter: ChartPainter(
          pipeline: _pipeline,
          series: _currentSeries,
          xAxis: widget.xAxis,
          yAxis: widget.yAxis,
          secondaryYAxis: widget.secondaryYAxis,
        ),
      ),
    );
  }
  
  Widget _buildLegend(BuildContext context) {
    return ChartLegend(
      series: _currentSeries,
      config: widget.legendConfig,
      onSeriesSelected: widget.onSeriesSelected,
    );
  }
}

enum ChartType { line, area, bar, scatter }
```

#### 6. ChartController (Real-Time Updates)

```dart
class ChartController {
  /// Maximum data points to keep per series
  final int? maxDataPoints;
  
  /// Throttle duration for updates
  final Duration? updateThrottle;
  
  /// Internal state
  final Map<String, List<ChartDataPoint>> _seriesData = {};
  final Map<String, ChartAnnotation> _annotations = {};  // Annotation management
  DateTime _lastUpdateTime = DateTime.now();
  final List<VoidCallback> _listeners = [];
  int _nextAnnotationId = 0;  // Auto-incrementing ID
  
  ChartController({
    this.maxDataPoints,
    this.updateThrottle,
  });
  
  // ==================== DATA POINT MANAGEMENT ====================
  
  /// Add a single point to a series
  void addPoint(String seriesId, ChartDataPoint point) {
    // Throttle check
    if (updateThrottle != null) {
      final now = DateTime.now();
      if (now.difference(_lastUpdateTime) < updateThrottle!) {
        return; // Drop update (too frequent)
      }
      _lastUpdateTime = now;
    }
    
    // Add point
    _seriesData.putIfAbsent(seriesId, () => []);
    _seriesData[seriesId]!.add(point);
    
    // Sliding window
    if (maxDataPoints != null && _seriesData[seriesId]!.length > maxDataPoints!) {
      _seriesData[seriesId]!.removeAt(0);
    }
    
    // Notify listeners
    _notifyListeners();
  }
  
  /// Add multiple points at once
  void addPoints(String seriesId, List<ChartDataPoint> points) {
    for (final point in points) {
      addPoint(seriesId, point);
    }
  }
  
  /// Remove oldest point from series
  void removeOldestPoint(String seriesId) {
    if (_seriesData[seriesId]?.isNotEmpty ?? false) {
      _seriesData[seriesId]!.removeAt(0);
      _notifyListeners();
    }
  }
  
  /// Clear all data from series
  void clearSeries(String seriesId) {
    _seriesData[seriesId]?.clear();
    _notifyListeners();
  }
  
  /// Get current data for series
  List<ChartDataPoint> getSeriesData(String seriesId) {
    return _seriesData[seriesId] ?? [];
  }
  
  /// Get all series as ChartSeries list
  List<ChartSeries> getAllSeries() {
    return _seriesData.entries.map((e) => 
      ChartSeries(id: e.key, points: e.value)
    ).toList();
  }
  
  // ==================== ANNOTATION MANAGEMENT ====================
  
  /// Add annotation to chart
  /// Returns annotation ID for later reference
  String addAnnotation(ChartAnnotation annotation) {
    final id = 'annotation_${_nextAnnotationId++}';
    _annotations[id] = annotation.copyWith(id: id);
    _notifyListeners();
    return id;
  }
  
  /// Remove annotation by ID
  void removeAnnotation(String annotationId) {
    if (_annotations.remove(annotationId) != null) {
      _notifyListeners();
    }
  }
  
  /// Update annotation by ID
  void updateAnnotation(String annotationId, ChartAnnotation updatedAnnotation) {
    if (_annotations.containsKey(annotationId)) {
      _annotations[annotationId] = updatedAnnotation.copyWith(id: annotationId);
      _notifyListeners();
    }
  }
  
  /// Get annotation by ID
  ChartAnnotation? getAnnotation(String annotationId) {
    return _annotations[annotationId];
  }
  
  /// Get all annotations
  List<ChartAnnotation> getAllAnnotations() {
    return _annotations.values.toList();
  }
  
  /// Clear all annotations
  void clearAnnotations() {
    _annotations.clear();
    _notifyListeners();
  }
  
  /// Find annotations at position (for hit-testing)
  List<ChartAnnotation> findAnnotationsAt(Offset position, {double tolerance = 10.0}) {
    // Implementation would use spatial indexing for performance
    return _annotations.values.where((annotation) {
      return annotation.containsPoint(position, tolerance);
    }).toList();
  }
  
  // ==================== LISTENER MANAGEMENT ====================
  
  /// Register listener for updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  /// Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  /// Clean up
  void dispose() {
    _seriesData.clear();
    _listeners.clear();
  }
}
```

#### 7. RealTimeConfig

```dart
class RealTimeConfig {
  /// Maximum data points to keep (oldest removed automatically)
  final int? maxDataPoints;
  
  /// Minimum duration between renders (throttle high-frequency updates)
  final Duration? updateThrottle;
  
  /// Enable smooth transitions for updates
  final bool animateUpdates;
  
  /// Auto-remove old points when max reached
  final bool slideWindow;
  
  /// Preserve user's zoom/pan state during updates
  final bool preserveViewport;
  
  /// Callback when data arrives faster than throttle allows
  final void Function(int droppedUpdates)? onBufferOverflow;
  
  const RealTimeConfig({
    this.maxDataPoints,
    this.updateThrottle,
    this.animateUpdates = true,
    this.slideWindow = true,
    this.preserveViewport = true,
    this.onBufferOverflow,
  });
  
  /// Default config for real-time monitoring (100 points, 100ms throttle)
  static const RealTimeConfig monitoring = RealTimeConfig(
    maxDataPoints: 100,
    updateThrottle: Duration(milliseconds: 100),
    animateUpdates: true,
    slideWindow: true,
  );
  
  /// Config for high-frequency data (no animation, aggressive throttling)
  static const RealTimeConfig highFrequency = RealTimeConfig(
    maxDataPoints: 50,
    updateThrottle: Duration(milliseconds: 50),
    animateUpdates: false,
    slideWindow: true,
  );
  
  /// Config for smooth visualization (slower updates, animated)
  static const RealTimeConfig smooth = RealTimeConfig(
    maxDataPoints: 200,
    updateThrottle: Duration(milliseconds: 200),
    animateUpdates: true,
    slideWindow: true,
  );
}
```

#### 8. LineChart with Stream Support

```dart
class LineChart extends StatefulWidget {
  // ... existing properties ...
  
  /// Stream of data for real-time updates
  final Stream<List<ChartDataPoint>>? dataStream;
  
  /// Real-time configuration
  final RealTimeConfig? realTimeConfig;
  
  /// Controller for manual updates
  final ChartController? controller;
  
  const LineChart({
    Key? key,
    required this.series,
    this.dataStream,
    this.realTimeConfig,
    this.controller,
    // ... other properties
  }) : super(key: key);
  
  /// Create from stream for real-time updates
  factory LineChart.fromStream({
    required Stream<List<ChartDataPoint>> stream,
    required String seriesId,
    String? seriesName,
    RealTimeConfig? realTimeConfig,
    LineChartConfig? config,
    ChartTheme? theme,
  }) {
    return LineChart(
      series: [], // Initial empty, populated from stream
      dataStream: stream,
      realTimeConfig: realTimeConfig ?? RealTimeConfig.monitoring,
      config: config ?? const LineChartConfig(),
      theme: theme,
    );
  }
  
  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  // ... existing resource management ...
  
  StreamSubscription<List<ChartDataPoint>>? _streamSubscription;
  List<ChartDataPoint> _streamData = [];
  DateTime _lastUpdateTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _initializeResources();
    _createLayer();
    
    // Listen to stream if provided
    if (widget.dataStream != null) {
      _subscribeToStream();
    }
    
    // Listen to controller if provided
    if (widget.controller != null) {
      widget.controller!.addListener(_onControllerUpdate);
    }
  }
  
  void _subscribeToStream() {
    _streamSubscription = widget.dataStream!.listen((points) {
      // Throttle updates
      final config = widget.realTimeConfig ?? RealTimeConfig.monitoring;
      if (config.updateThrottle != null) {
        final now = DateTime.now();
        if (now.difference(_lastUpdateTime) < config.updateThrottle!) {
          return; // Drop update
        }
        _lastUpdateTime = now;
      }
      
      setState(() {
        _streamData = points;
        
        // Sliding window
        if (config.maxDataPoints != null && _streamData.length > config.maxDataPoints!) {
          _streamData = _streamData.sublist(_streamData.length - config.maxDataPoints!);
        }
      });
    });
  }
  
  void _onControllerUpdate() {
    setState(() {
      // Controller updated, trigger rebuild
    });
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    widget.controller?.removeListener(_onControllerUpdate);
    // ... existing dispose logic
    super.dispose();
  }
  
  // ... rest of implementation
}
```

---

## 🧪 Testing Requirements

### Unit Tests

1. **Widget Creation Tests** (per chart type)
   - Widget can be created with minimal parameters
   - Widget accepts all optional parameters
   - Named constructors work correctly (.fromValues, .fromMap)

2. **Resource Management Tests**
   - Resources created on initState
   - Resources reused across rebuilds (same config)
   - Resources recreated when config changes
   - Resources disposed on widget dispose
   - No memory leaks after 100 rebuild cycles

3. **Data Binding Tests**
   - `.fromValues()` creates correct ChartSeries
   - `.fromMap()` handles multi-series correctly
   - Automatic x-value generation works
   - Automatic series ID generation is unique

4. **Real-Time Update Tests**
   - ChartController.addPoint updates chart correctly
   - Stream updates trigger rebuilds
   - Throttling drops updates correctly (respects updateThrottle)
   - Sliding window removes old data when maxDataPoints exceeded
   - State preserved during updates (zoom/pan)
   - Stream subscription cleaned up on dispose

5. **Callback Tests**
   - onDataPointTap called with correct data
   - onDataPointHover called on hover
   - onChartTap called on background tap
   - Callbacks receive correct context (point, seriesId)

### Widget Tests

1. **Rendering Tests**
   - Widget renders without errors
   - Widget respects parent size constraints
   - Loading state shows loading indicator
   - Error state shows error message
   - Custom builders are used when provided

2. **Hot Reload Tests**
   - Widget survives hot reload
   - Data updates reflect after hot reload
   - Theme updates reflect after hot reload
   - No resource leaks after multiple hot reloads

3. **Interaction Tests**
   - Tap gesture detected
   - Hover gesture detected (web/desktop)
   - Callbacks fired on interactions

### Golden Tests

✅ **UNBLOCKS DEFERRED TASKS FROM LAYER 4**

1. **LineChart Golden Tests** (T062)
   - Straight line with markers
   - Smooth line without markers
   - Stepped line
   - Multi-series

2. **AreaChart Golden Tests** (T063)
   - Solid fill
   - Gradient fill
   - Stacked areas

3. **BarChart Golden Tests** (T064)
   - Vertical grouped bars
   - Vertical stacked bars
   - Horizontal bars

4. **ScatterChart Golden Tests** (T065)
   - Fixed-size markers
   - Data-driven sizing
   - Multiple marker shapes

### Integration Tests

1. **BravenChart Integration**
   - BravenChart with single LineChart
   - BravenChart with multiple charts (composite)
   - BravenChart with legend
   - BravenChart with toolbar
   - BravenChart with title/subtitle

2. **Theme Integration**
   - Widget uses provided theme
   - Widget inherits from ChartThemeProvider
   - Dark mode adaptation works

---

## 📊 Performance Requirements

### Rendering Performance

- **60 FPS**: Maintain 60 FPS with animated data updates
- **Frame Budget**: Stay within 16ms frame time (same as Layer 4)
- **Memory**: Widget overhead <100KB per chart instance
- **Pool Efficiency**: Maintain >90% object pool reuse rate

### Resource Management

- **Initialization**: Widget ready to paint within 1 frame
- **Updates**: Data updates processed within 1 frame
- **Disposal**: All resources released within 100ms of dispose
- **Memory Leaks**: Zero leaks after 1000 build/dispose cycles

---

## 🎨 Design Patterns

### 1. Widget Pattern

All chart widgets follow Flutter's standard widget pattern:
- Immutable configuration (all fields final)
- StatefulWidget for resource management
- State class handles mutable resources
- didUpdateWidget detects changes
- dispose() cleans up resources

### 2. Factory Constructors

Provide convenience constructors for common use cases:
- Default constructor: full control
- `.fromValues()`: simplest usage
- `.fromMap()`: multi-series from map
- `.fromJson()`: parse JSON data

### 3. Builder Pattern

Use builders for customization:
- `loadingBuilder`: custom loading widget
- `errorBuilder`: custom error widget
- Optional: `legendBuilder`, `tooltipBuilder`

### 4. Inherited Widget (Optional)

ChartThemeProvider for theme inheritance:
```dart
class ChartThemeProvider extends InheritedWidget {
  final ChartTheme theme;
  
  static ChartTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChartThemeProvider>()?.theme;
  }
  
  // ...
}
```

---

## 🔗 Dependencies

### Internal Dependencies

- **Layer 0 (Foundation)**: ChartDataPoint, ChartSeries, ObjectPool
- **Layer 1 (Core Rendering)**: RenderPipeline, RenderContext, PerformanceMonitor
- **Layer 2 (Coordinate System)**: ViewportState (future integration)
- **Layer 3 (Theming)**: ChartTheme
- **Layer 4 (Chart Types)**: LineChartLayer, AreaChartLayer, BarChartLayer, ScatterChartLayer

### External Dependencies

- `flutter/material.dart` - Widget framework
- `flutter/widgets.dart` - Core widgets
- `dart:ui` - Canvas, Paint, Path (via layers)

### No New Dependencies

This layer uses only existing dependencies from previous layers. No new pub.dev packages required.

---

## 📝 Documentation Requirements

### API Documentation

- DartDoc for all public classes and methods
- Usage examples in class-level documentation
- Parameter descriptions for all properties
- Code samples showing common patterns

### User Guide

Create `docs/guides/chart-widgets.md` covering:
1. Quick Start (5-minute tutorial)
2. Basic Usage (all 4 chart types)
3. Data Binding (fromValues, fromMap, standard)
4. Customization (themes, configs)
5. Interactivity (callbacks)
6. Advanced (custom builders, performance tuning)
7. Migration from Layer 4 (for advanced users)

### Examples

Create example app demonstrating:
- Simple usage (fromValues)
- Multi-series charts (single chart, multiple series)
- Multi-chart composition (multiple charts, different configs)
- Themes and styling
- Interactive charts (callbacks)
- Loading/error states
- BravenChart usage (single + composite modes)

---

## 🚀 Implementation Phases

### Phase 1: Core Widgets (Week 1)
1. LineChart widget + state
2. AreaChart widget + state
3. BarChart widget + state
4. ScatterChart widget + state
5. ChartPainter base class
6. CompositeChart widget + CompositeChartPainter
7. Unit tests for resource management

### Phase 2: Data Binding & Real-Time (Week 1.5)
1. `.fromValues()` constructors
2. `.fromMap()` constructors
3. `.fromJson()` constructors
4. Data conversion utilities
5. ChartController implementation
6. RealTimeConfig class
7. `.fromStream()` constructors
8. Stream subscription management
9. Update throttling logic
10. Unit tests for data binding and real-time updates

### Phase 3: Features (Week 1.5)
1. Event callbacks (onTap, onHover)
2. Loading/error states
3. Theme integration
4. ChartThemeProvider (optional)
5. Widget tests

### Phase 4: Container & Polish (Week 1.5)
1. BravenChart widget (main user-facing container)
2. Legend component with aggregation
3. Toolbar component
4. Golden tests (all 4 chart types)
5. Integration tests (BravenChart + composite)
6. Performance validation

### Phase 5: Documentation (Week 0.5)
1. API documentation (DartDoc)
2. Usage guide
3. Example app
4. Migration guide (Layer 4 → Layer 5)

**Total Estimated Time**: 5-6 weeks (Weeks 9-10 on roadmap, +1-2 buffer)

---

## ✅ Acceptance Criteria

1. ✅ All 4 chart widgets implemented (Line, Area, Bar, Scatter)
2. ✅ CompositeChart widget implemented (multi-chart composition)
3. ✅ Real-time data support (Stream, Controller, manual updates)
4. ✅ Zero boilerplate - simple 5-line API works
5. ✅ Automatic resource management (no memory leaks)
6. ✅ Hot reload support confirmed (single and composite charts)
7. ✅ All callbacks functional (onTap, onHover)
8. ✅ Loading/error states working
9. ✅ Theme integration complete
10. ✅ BravenChart supports both single chart and multiple charts modes
11. ✅ BravenChart with legend aggregation working
12. ✅ BravenChart with toolbar working
13. ✅ Multiple charts render in same coordinate space correctly
14. ✅ Shared axes auto-calculated from all chart data
15. ✅ Per-chart legend control functional (showInLegend, legendLabel)
16. ✅ Chart transparency/opacity works for layering visibility
17. ✅ Stream-based updates work with throttling
18. ✅ ChartController incremental updates work
19. ✅ Sliding window removes old data correctly
20. ✅ 100% unit test coverage on widgets
21. ✅ Golden tests pass (unblocks T062-T065)
22. ✅ Performance benchmarks meet Layer 4 targets (composite + real-time)
23. ✅ Documentation complete (API + guide + examples + real-time)
24. ✅ Example app demonstrates all features including real-time data
25. ✅ No linter warnings or errors
26. ✅ Code review approved

---

## 🎯 Success Metrics

### Developer Experience
- **Time to First Chart**: <5 minutes from package import to working chart
- **Lines of Code**: <10 lines for basic chart
- **Learning Curve**: Developers can use widgets without reading Layer 4 docs

### Performance
- **Rendering**: Same performance as Layer 4 (no widget overhead)
- **Memory**: <100KB overhead per widget instance
- **Hot Reload**: <100ms to apply changes

### Quality
- **Test Coverage**: >95% line coverage
- **Bug Reports**: <5 critical bugs in first month
- **User Satisfaction**: Positive feedback on ease of use

---

## 📋 Design Decisions (Resolved)

### Q-001: StatefulWidget vs StatelessWidget?
**Decision**: ✅ **StatefulWidget** - Better resource lifecycle control, proper resource disposal, follows Flutter best practices for widgets with heavy resources.

---

### Q-002: Composite Chart API?
**Decision**: ✅ **User-friendly chart composition** - Users work with `LineChart`, `AreaChart`, etc. (not "layers"). ChartContainer accepts `charts: [...]` and automatically creates CompositeChart internally.

**Rationale**: Users don't know or care about internal layer implementation. API should be intuitive using familiar chart type names.

---

### Q-003: Legend Handling for Multiple Charts?
**Decision**: ✅ **Auto-aggregate with per-chart control** - ChartContainer automatically combines legends from all charts, but each chart can configure `showInLegend` and `legendLabel` independently.

**Rationale**: Smart defaults (show all) with full configurability for advanced use cases.

---

### Q-004: Axis Management?
**Decision**: ✅ **Auto-calculate with full configurability** - Automatically calculate shared domain/range from all chart data, but allow complete override via `AxisConfig` properties (range, labels, grid, etc.).

**Rationale**: Zero-config for simple cases, powerful customization when needed.

---

### Q-005: Chart Overlap and Z-Ordering?
**Decision**: ✅ **Natural list order with transparency** - Charts render in list order (later = on top). Area charts should use opacity (e.g., 0.15-0.3) to remain visible while showing charts behind/in-front.

**Rationale**: Implicit, predictable ordering. Transparency is visual design choice, not framework constraint.

---

### Q-006: BravenChart Responsibilities?
**Decision**: ✅ **Full orchestration** - BravenChart aggregates series, builds unified legend, manages shared axes, handles layout, and marshals all components needed for proper display.

**Rationale**: This is the user-facing component, so it must provide complete, cohesive functionality.

---

## 🔄 Future Enhancements (Post-Layer 5)

These features are explicitly OUT OF SCOPE for Layer 5 but may be added in future layers:

1. **Gestures** (Layer 6 - Interaction System)
   - Pinch-to-zoom
   - Pan
   - Tap-to-select with visual feedback

2. **Tooltips** (Layer 6)
   - Automatic tooltip on hover
   - Customizable tooltip content
   - Crosshair system

3. **Annotations** (Layer 7)
   - Add/edit annotations via widget API
   - Programmatic annotation management

4. **Advanced Data Binding** (Future)
   - Stream-based data updates
   - Data transformation utilities
   - Aggregation helpers

5. **Accessibility** (Future)
   - Screen reader support
   - Keyboard navigation
   - Semantic labels

---

## 📚 References

### Internal Documents
- [Layer 4 Specification](../004-chart-types/spec.md)
- [Layer 4 Implementation Status](../../specs/005-chart-types/IMPLEMENTATION_STATUS.md)
- [Technical Debt Document](../../TECHNICAL_DEBT.md) - TD-006 (Golden Tests)
- [Constitution](../../.specify/memory/constitution.md)

### Flutter Documentation
- [StatefulWidget](https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html)
- [CustomPaint](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)
- [InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html)

### Best Practices
- Flutter Widget Design Patterns
- Flutter Performance Best Practices
- Flutter Testing Guidelines

---

**Status**: Draft - Ready for Review  
**Next Steps**: Review specification, iterate based on feedback, create plan.md and tasks.md
