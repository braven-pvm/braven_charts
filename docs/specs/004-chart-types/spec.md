# Feature Specification: Chart Types

**Feature Branch**: `005-chart-types`  
**Layer**: 4 (Chart Types)  
**Created**: 2025-10-06  
**Status**: Draft  
**Dependencies**: 
- 001-foundation (Foundation Layer) ✅
- 002-core-rendering (Rendering Engine) ✅
- 003-coordinate-system (Coordinate Transformations) ✅
- 004-theming-system (Theming & Styling) ✅

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT each chart type must do and WHY
- ✅ Chart Types = Visual representations of data using foundation layers
- ✅ Depends on all lower layers (foundation, rendering, coordinates, theming)
- ✅ Provides concrete chart implementations (Line, Area, Bar, Scatter)
- ✅ Each chart type is a composable RenderLayer with specialized rendering

---

## Executive Summary

The Chart Types layer provides four core chart implementations (Line, Area, Bar, Scatter) that leverage the foundation layers to render data efficiently and beautifully. Each chart type is implemented as a specialized RenderLayer, utilizing the coordinate system for transformations, the rendering engine for performance, and the theming system for visual consistency.

**Why This Layer Exists**: Users need concrete ways to visualize their data. While the foundation layers provide the infrastructure (data structures, rendering pipeline, coordinate transformations, theming), this layer provides the actual chart types that developers will use. Each chart type has unique visual characteristics and use cases.

**What Makes It Special**:
- 4 professionally implemented chart types covering 80% of use cases
- Unified architecture (all charts implement RenderLayer interface)
- Performance-optimized (viewport culling, object pooling, zero-allocation rendering)
- Multi-series support (multiple data series per chart)
- Real-time data updates (smooth animations, efficient diffing)
- Theme-aware rendering (automatic style application)

---

## Architectural Position

### Layer Dependencies
```
Layer 4: Chart Types (THIS LAYER)
├── Depends on Layer 3: Theming System (styling)
├── Depends on Layer 2: Coordinate System (transformations)
├── Depends on Layer 1: Rendering Engine (drawing)
└── Depends on Layer 0: Foundation (data structures, math, performance)
```

### What This Layer Provides
- **Concrete Chart Implementations**: LineChart, AreaChart, BarChart, ScatterChart
- **Render Layers**: LineChartLayer, AreaChartLayer, BarChartLayer, ScatterChartLayer
- **Chart Configuration**: Type-specific options and behaviors
- **Data Binding**: Efficient data-to-visual mapping
- **Animation Support**: Smooth transitions between data states

### What This Layer Does NOT Provide
- ❌ Interaction handling (Layer 5: Interaction System)
- ❌ Annotations (Layer 6: Annotation System)
- ❌ Advanced analytics (Layer 7+: Analytics features)
- ❌ Widget integration (separate package: braven_charts_flutter)

---

## User Scenarios & Testing

### Primary User Story

**As a chart developer**, I need a comprehensive set of chart types so that I can visualize different kinds of data appropriately, with consistent API patterns, high performance, and professional visual quality.

### Acceptance Scenarios

#### Scenario 1: Creating a Line Chart with Multiple Series
```dart
// Given: Time-series data with multiple metrics
final revenueSeries = ChartSeries(
  id: 'revenue',
  name: 'Revenue',
  points: [
    ChartDataPoint(x: 1.0, y: 100.0),
    ChartDataPoint(x: 2.0, y: 150.0),
    ChartDataPoint(x: 3.0, y: 120.0),
    ChartDataPoint(x: 4.0, y: 180.0),
  ],
  isXOrdered: true,
);

final costSeries = ChartSeries(
  id: 'cost',
  name: 'Cost',
  points: [
    ChartDataPoint(x: 1.0, y: 60.0),
    ChartDataPoint(x: 2.0, y: 80.0),
    ChartDataPoint(x: 3.0, y: 70.0),
    ChartDataPoint(x: 4.0, y: 90.0),
  ],
  isXOrdered: true,
);

// When: Creating a line chart with multiple series
final lineChartLayer = LineChartLayer(
  series: [revenueSeries, costSeries],
  config: LineChartConfig(
    lineStyle: LineStyle.smooth, // or LineStyle.stepped, LineStyle.straight
    showPoints: true,
    pointRadius: 4.0,
    lineWidth: 2.0,
  ),
);

// Add to rendering pipeline
final context = RenderContext(/* ... */);
final pipeline = RenderPipeline();
pipeline.addLayer(lineChartLayer, zIndex: 10);
pipeline.renderFrame(canvas, size, context);

// Then:
// - Both series rendered with distinct colors from theme
// - Smooth bezier curves between points
// - Data points marked with circles
// - Lines don't overlap (proper z-ordering)
// - Viewport culling active (only visible points rendered)
// - Renders in <8ms for 1000 points per series
```

**Acceptance Criteria**:
- ✅ Multiple series supported (minimum 10 series per chart)
- ✅ Each series gets distinct color from theme (cycling behavior)
- ✅ Smooth curves calculated using cubic bezier interpolation
- ✅ Point markers customizable (circle, square, triangle, diamond, none)
- ✅ Line styles: straight, smooth (bezier), stepped (constant)
- ✅ Viewport culling: only visible points rendered
- ✅ Performance: <8ms for 1000 points, <16ms for 10,000 points
- ✅ Theme integration: colors, line widths, point sizes from theme

#### Scenario 2: Creating an Area Chart with Gradients
```dart
// Given: Data for filled area visualization
final dataSeries = ChartSeries(
  id: 'temperature',
  name: 'Temperature',
  points: generateSineWaveData(100), // 100 points
  isXOrdered: true,
);

// When: Creating area chart with gradient fill
final areaChartLayer = AreaChartLayer(
  series: [dataSeries],
  config: AreaChartConfig(
    fillStyle: AreaFillStyle.gradient,
    gradientStart: Color(0xFF2196F3).withOpacity(0.8),
    gradientEnd: Color(0xFF2196F3).withOpacity(0.1),
    lineStyle: LineStyle.smooth,
    showLine: true,
    lineWidth: 2.0,
    baselineY: 0.0, // Fill from this Y value
  ),
);

// Then:
// - Area filled from baseline to line
// - Gradient interpolated vertically (top to bottom)
// - Line rendered on top of fill
// - Fill doesn't obscure other elements (proper transparency)
// - Multiple series stack correctly (no overlap conflicts)
```

**Acceptance Criteria**:
- ✅ Area filled from baseline to data line
- ✅ Gradient support (vertical, horizontal, radial)
- ✅ Transparency support (0.0 to 1.0 opacity)
- ✅ Stacking support (series stack on top of each other)
- ✅ Baseline customizable (fixed Y value or dynamic)
- ✅ Line on/off toggle (area only vs area + line)
- ✅ Theme integration: gradient colors from theme palette
- ✅ Performance: Same as line chart (<8ms for 1000 points)

#### Scenario 3: Creating a Bar Chart with Grouping
```dart
// Given: Categorical data with multiple groups
final q1Sales = ChartSeries(
  id: 'q1-sales',
  name: 'Q1 Sales',
  points: [
    ChartDataPoint(x: 0.0, y: 100.0), // Product A
    ChartDataPoint(x: 1.0, y: 150.0), // Product B
    ChartDataPoint(x: 2.0, y: 120.0), // Product C
  ],
);

final q2Sales = ChartSeries(
  id: 'q2-sales',
  name: 'Q2 Sales',
  points: [
    ChartDataPoint(x: 0.0, y: 120.0),
    ChartDataPoint(x: 1.0, y: 160.0),
    ChartDataPoint(x: 2.0, y: 140.0),
  ],
);

// When: Creating grouped bar chart
final barChartLayer = BarChartLayer(
  series: [q1Sales, q2Sales],
  config: BarChartConfig(
    orientation: BarOrientation.vertical,
    grouping: BarGrouping.grouped, // or BarGrouping.stacked
    barWidth: 0.8, // Percentage of category width
    barSpacing: 0.2, // Space between bars in group
    cornerRadius: 4.0,
  ),
);

// Then:
// - Bars grouped at each X position
// - Each series has distinct color
// - Bars have rounded corners
// - Proper spacing between groups and bars
// - Bars scale correctly with viewport zoom
```

**Acceptance Criteria**:
- ✅ Grouped bars (bars side-by-side at each category)
- ✅ Stacked bars (bars stacked vertically/horizontally)
- ✅ Vertical and horizontal orientations
- ✅ Bar width customizable (percentage of category width)
- ✅ Corner radius support (rounded corners)
- ✅ Negative values supported (bars extend below baseline)
- ✅ Theme integration: bar colors, border styles from theme
- ✅ Performance: <16ms for 1000 bars

#### Scenario 4: Creating a Scatter Plot with Custom Markers
```dart
// Given: Point-based data with varying sizes
final dataPoints = ChartSeries(
  id: 'scatter-data',
  name: 'Measurements',
  points: [
    ChartDataPoint(x: 1.0, y: 2.0, metadata: {'size': 10.0}),
    ChartDataPoint(x: 2.0, y: 3.5, metadata: {'size': 15.0}),
    ChartDataPoint(x: 3.0, y: 1.8, metadata: {'size': 8.0}),
    // ... more points
  ],
);

// When: Creating scatter plot with size-based markers
final scatterLayer = ScatterChartLayer(
  series: [dataPoints],
  config: ScatterChartConfig(
    markerShape: MarkerShape.circle,
    markerSize: 8.0, // Base size
    sizeScale: (point) => point.metadata['size'] as double, // Dynamic sizing
    markerStyle: MarkerStyle.filled, // or MarkerStyle.outlined
    outlineWidth: 1.0,
  ),
);

// Then:
// - Each point rendered with custom size
// - Markers properly centered at coordinates
// - No marker overlap (visual clarity)
// - Colors assigned per series from theme
// - Fast rendering even with many points
```

**Acceptance Criteria**:
- ✅ Custom marker shapes (circle, square, triangle, diamond, cross, plus)
- ✅ Dynamic marker sizing based on data or metadata
- ✅ Filled and outlined marker styles
- ✅ Outline width customizable
- ✅ Point clustering for dense data (optional)
- ✅ Theme integration: marker colors from theme
- ✅ Performance: <16ms for 10,000 points with viewport culling

#### Scenario 5: Real-time Data Updates with Smooth Animations
```dart
// Given: A line chart with initial data
final series = ChartSeries(
  id: 'live-data',
  name: 'Live Metrics',
  points: initialData,
  isXOrdered: true,
);

final lineChart = LineChartLayer(series: [series]);

// When: New data arrives (e.g., every second)
series.updatePoints(newData); // Efficient update

// Then:
// - Chart smoothly animates from old to new data
// - Animation duration matches theme (e.g., 300ms)
// - Animation curve from theme (e.g., easeInOut)
// - No jarring transitions or flicker
// - Performance maintained during animation
// - Old data fades out gracefully
```

**Acceptance Criteria**:
- ✅ Data updates trigger smooth animations
- ✅ Animation duration configurable (default from theme)
- ✅ Animation curves customizable (default from theme)
- ✅ Efficient data diffing (only changed points animate)
- ✅ No performance degradation during animation
- ✅ Animation can be disabled for real-time dashboards
- ✅ Frame rate maintained (60 FPS) during transitions

---

## Functional Requirements

### FR-001: Line Chart Implementation

#### FR-001.1: Line Rendering Modes
**MUST support three line rendering modes:**

1. **Straight Lines** (`LineStyle.straight`)
   - Connect points with direct line segments
   - Simplest rendering (fastest performance)
   - Use case: Technical charts, engineering data

2. **Smooth Curves** (`LineStyle.smooth`)
   - Connect points with cubic bezier curves
   - Calculate control points using Catmull-Rom splines
   - Smooth, organic appearance
   - Use case: Trend visualization, natural phenomena

3. **Stepped Lines** (`LineStyle.stepped`)
   - Constant value between points (horizontal then vertical)
   - Clear value changes
   - Use case: Digital signals, state changes, categorical timelines

**Performance Requirements:**
- Straight lines: <5ms for 10,000 points
- Smooth curves: <8ms for 10,000 points (control point calculation cached)
- Stepped lines: <6ms for 10,000 points

#### FR-001.2: Point Markers
**MUST support customizable point markers:**

- **Shapes**: Circle, Square, Triangle, Diamond, Cross, Plus, None
- **Size**: Configurable radius (default from theme)
- **Style**: Filled, Outlined, or Both
- **Visibility**: Show all, show none, show on hover
- **Per-series customization**: Different markers for each series

**Visual Requirements:**
- Markers centered on data points
- Markers scale with zoom (remain visible)
- Markers don't overlap line (z-order correct)
- Markers use series color from theme

#### FR-001.3: Multi-Series Support
**MUST support multiple series per chart:**

- Minimum 10 series simultaneously
- Each series gets distinct color (cycling through theme palette)
- Series can be shown/hidden independently
- Series render in correct z-order (first series on bottom)
- Series legend automatically generated

**Performance Requirements:**
- <16ms frame time with 10 series × 1,000 points each
- <8ms per series rendering time

#### FR-001.4: Line Styling
**MUST provide comprehensive line styling:**

- **Line Width**: Customizable (default from theme)
- **Dash Patterns**: Solid, dashed, dotted, custom patterns
- **Opacity**: 0.0 to 1.0 transparency
- **Anti-aliasing**: Always enabled for smooth appearance
- **Join Style**: Miter, round, bevel (default: round)
- **Cap Style**: Butt, round, square (default: round)

---

### FR-002: Area Chart Implementation

#### FR-002.1: Fill Modes
**MUST support three fill modes:**

1. **Solid Fill** (`AreaFillStyle.solid`)
   - Single color fill from baseline to line
   - Customizable opacity
   - Use case: Simple area charts, sparklines

2. **Gradient Fill** (`AreaFillStyle.gradient`)
   - Linear gradient from top to bottom
   - Two-color gradient (start and end colors)
   - Opacity interpolated smoothly
   - Use case: Depth visualization, emphasis areas

3. **Pattern Fill** (`AreaFillStyle.pattern`)
   - Repeating pattern (hatching, dots, grid)
   - Use case: Print-friendly charts, pattern differentiation

**Performance Requirements:**
- Solid fill: Same as line chart rendering
- Gradient fill: +2ms overhead for shader setup
- Pattern fill: +3ms overhead for pattern tessellation

#### FR-002.2: Baseline Configuration
**MUST support flexible baseline definition:**

- **Fixed Baseline**: Constant Y value (e.g., 0.0)
- **Dynamic Baseline**: Minimum Y value in viewport
- **Series Baseline**: Fill between two series
- **Zero Baseline**: Always fill from zero (default)

**Visual Requirements:**
- Fill extends exactly to baseline (no gaps)
- Baseline respects coordinate transformations
- Negative areas filled correctly (below baseline)

#### FR-002.3: Stacking Support
**MUST support stacked area charts:**

- Series stack vertically on top of each other
- Each series area starts from previous series top
- Total height = sum of all series values
- Stack order configurable
- Percentage stacking (normalize to 100%)

**Performance Requirements:**
- Stacking calculation: <2ms overhead for 10 series
- Rendering: Same as non-stacked performance

#### FR-002.4: Line Overlay
**MUST support optional line overlay:**

- Line rendered on top of area fill
- Line style independent of fill style
- Line can be enabled/disabled
- Line uses same interpolation as area boundary

---

### FR-003: Bar Chart Implementation

#### FR-003.1: Orientations
**MUST support two orientations:**

1. **Vertical Bars** (`BarOrientation.vertical`)
   - Bars extend upward from baseline (Y-axis)
   - X-axis for categories
   - Use case: Standard bar charts, sales data

2. **Horizontal Bars** (`BarOrientation.horizontal`)
   - Bars extend rightward from baseline (X-axis)
   - Y-axis for categories
   - Use case: Ranking charts, long category names

**Visual Requirements:**
- Bars centered on category coordinates
- Bars scale correctly with zoom
- Axis labels oriented correctly for each orientation

#### FR-003.2: Grouping Modes
**MUST support two grouping modes:**

1. **Grouped Bars** (`BarGrouping.grouped`)
   - Bars placed side-by-side within each category
   - Each series visible independently
   - Bar width auto-calculated based on group size
   - Use case: Comparison across categories and series

2. **Stacked Bars** (`BarGrouping.stacked`)
   - Bars stacked vertically (or horizontally)
   - Total height = sum of all series values
   - Each segment colored by series
   - Use case: Part-to-whole visualization, totals

**Performance Requirements:**
- Grouped: <16ms for 100 categories × 5 series
- Stacked: <18ms for 100 categories × 5 series

#### FR-003.3: Bar Styling
**MUST provide comprehensive bar styling:**

- **Corner Radius**: Rounded corners (0.0 to full circle)
- **Border**: Optional border with width and color
- **Gradient Fill**: Vertical gradient within bar
- **Shadow**: Optional drop shadow for depth
- **Spacing**: Configurable gap between bars and groups

**Visual Requirements:**
- Corners rounded consistently (top/bottom/all)
- Borders don't affect bar size (drawn inside)
- Shadows don't overlap other bars

#### FR-003.4: Negative Values
**MUST handle negative values correctly:**

- Negative bars extend in opposite direction from baseline
- Baseline at Y=0 (vertical) or X=0 (horizontal)
- Negative bars use same styling as positive bars
- Color can differ for negative values (optional)

---

### FR-004: Scatter Chart Implementation

#### FR-004.1: Marker Shapes
**MUST support six marker shapes:**

1. **Circle**: Perfect circles (default)
2. **Square**: Filled or outlined squares
3. **Triangle**: Upward-pointing triangles
4. **Diamond**: 45-degree rotated squares
5. **Cross**: × shape (two diagonal lines)
6. **Plus**: + shape (two perpendicular lines)

**Visual Requirements:**
- All shapes centered on data point
- All shapes scale uniformly
- Outlined shapes have configurable line width

#### FR-004.2: Dynamic Sizing
**MUST support data-driven marker sizing:**

- **Fixed Size**: All markers same size (default)
- **Metadata Sizing**: Size based on point metadata
- **Value Sizing**: Size based on Y value
- **Custom Function**: User-provided sizing function

**Size Constraints:**
- Minimum size: 2.0 pixels (visibility threshold)
- Maximum size: Configurable (default: 50.0 pixels)
- Size scaling: Linear or logarithmic

**Performance Requirements:**
- Size calculation: <0.1ms per 1000 points
- Rendering: <16ms for 10,000 points (with viewport culling)

#### FR-004.3: Marker Styles
**MUST support three marker styles:**

1. **Filled** (`MarkerStyle.filled`)
   - Solid color fill
   - No outline
   - Use case: Dense scatter plots

2. **Outlined** (`MarkerStyle.outlined`)
   - Transparent fill
   - Colored outline
   - Use case: Overlapping points, clarity

3. **Both** (`MarkerStyle.filledWithOutline`)
   - Filled with contrasting outline
   - Use case: Maximum visibility

#### FR-004.4: Point Clustering (Optional)
**MAY support clustering for dense data:**

- Automatically cluster nearby points at low zoom
- Show cluster count as label
- Expand to individual points on zoom
- Use case: Geographic data, very large datasets

**Performance Requirements:**
- Clustering algorithm: <50ms for 100,000 points
- Re-clustering on zoom: <20ms

---

### FR-005: Common Chart Features

#### FR-005.1: Data Series Management
**MUST provide efficient data management:**

- **Add Series**: Add new series to existing chart
- **Remove Series**: Remove series without re-rendering others
- **Update Series**: Update series data with efficient diffing
- **Reorder Series**: Change z-order of series
- **Show/Hide Series**: Toggle series visibility

**Performance Requirements:**
- Add/remove: <5ms (no full re-render)
- Update: <10ms for 1,000 changed points
- Reorder: <2ms (z-index change only)

#### FR-005.2: Viewport Culling Integration
**MUST integrate with viewport culling system:**

- Use `ViewportCuller` from foundation layer
- Only render visible data points
- Cull points outside viewport bounds
- Include small buffer for smooth pan (viewport + 10%)

**Performance Requirements:**
- Culling calculation: <1ms for 10,000 points
- Memory savings: >80% for off-screen points

#### FR-005.3: Coordinate System Integration
**MUST use coordinate transformation system:**

- Data coordinates → Screen coordinates via `UniversalCoordinateTransformer`
- Support all 8 coordinate spaces
- Handle zoom/pan transformations automatically
- Validate coordinate bounds

**Correctness Requirements:**
- Sub-pixel accuracy (<0.5px error)
- Round-trip accuracy (data → screen → data within 0.001)
- Handle edge cases (infinity, NaN, out-of-bounds)

#### FR-005.4: Theme Integration
**MUST apply theming automatically:**

- Use theme colors for series (cycling through palette)
- Use theme line widths, point sizes
- Use theme animation settings
- Support theme changes without recreation

**Theme Properties Used:**
- `SeriesTheme.colors` - Series color palette
- `SeriesTheme.lineWidths` - Line width cycling
- `SeriesTheme.markerSizes` - Point size defaults
- `AnimationTheme.duration` - Update animation duration
- `AnimationTheme.curve` - Update animation curve

#### FR-005.5: Rendering Layer Implementation
**MUST implement `RenderLayer` interface:**

```dart
abstract class ChartRenderLayer implements RenderLayer {
  @override
  void render(Canvas canvas, Size size, RenderContext context);
  
  @override
  Rect getBounds();
  
  @override
  bool hitTest(Offset position);
  
  @override
  int get zIndex;
}
```

**Requirements:**
- Each chart type is a separate RenderLayer
- Can be composed in RenderPipeline
- Supports z-ordering (charts can layer over each other)
- Hit testing for interaction (preparation for Layer 5)

---

### FR-006: Animation System

#### FR-006.1: Data Update Animations
**MUST animate data changes smoothly:**

- Interpolate from old to new data points
- Use theme animation duration (default: 300ms)
- Use theme animation curve (default: easeInOut)
- Support disabling animation (real-time dashboards)

**Animation Types:**
- **Point Movement**: Points slide to new positions
- **Value Change**: Lines/bars morph to new values
- **Add/Remove**: Points fade in/out
- **Series Add/Remove**: Series fade in/out

**Performance Requirements:**
- Animation frame rate: 60 FPS (16.67ms per frame)
- No jank during animation
- Smooth interpolation (no stuttering)

#### FR-006.2: Animation Customization
**MUST provide animation control:**

- **Duration**: Per-chart override of theme duration
- **Curve**: Per-chart override of theme curve
- **Delay**: Staggered animation start
- **Enable/Disable**: Per-chart animation toggle

**Supported Curves:**
- Linear, easeIn, easeOut, easeInOut
- EaseInCubic, easeOutCubic, easeInOutCubic
- ElasticIn, elasticOut (for playful animations)

---

### FR-007: Configuration Objects

#### FR-007.1: LineChartConfig
```dart
class LineChartConfig {
  final LineStyle lineStyle;        // straight | smooth | stepped
  final bool showPoints;            // Show point markers
  final double pointRadius;         // Marker size
  final MarkerShape pointShape;     // Marker shape
  final double lineWidth;           // Line thickness
  final List<double>? dashPattern;  // Dash pattern (null = solid)
  final bool enableAnimation;       // Animation on/off
  final Duration? animationDuration; // Override theme duration
  final Curve? animationCurve;      // Override theme curve
}
```

#### FR-007.2: AreaChartConfig
```dart
class AreaChartConfig {
  final AreaFillStyle fillStyle;    // solid | gradient | pattern
  final Color? fillColor;           // Solid fill color
  final Color? gradientStart;       // Gradient top color
  final Color? gradientEnd;         // Gradient bottom color
  final double fillOpacity;         // Fill transparency (0.0-1.0)
  final double baselineY;           // Baseline Y coordinate
  final bool showLine;              // Show line on top of area
  final LineStyle lineStyle;        // Line rendering mode
  final double lineWidth;           // Line thickness
}
```

#### FR-007.3: BarChartConfig
```dart
class BarChartConfig {
  final BarOrientation orientation; // vertical | horizontal
  final BarGrouping grouping;       // grouped | stacked
  final double barWidth;            // Percentage of category width
  final double barSpacing;          // Space between bars
  final double cornerRadius;        // Corner rounding
  final bool showBorder;            // Show bar borders
  final double borderWidth;         // Border thickness
  final Color? borderColor;         // Border color
}
```

#### FR-007.4: ScatterChartConfig
```dart
class ScatterChartConfig {
  final MarkerShape markerShape;    // circle | square | triangle | etc
  final double markerSize;          // Base marker size
  final MarkerSizeFunction? sizeScale; // Dynamic sizing function
  final MarkerStyle markerStyle;    // filled | outlined | both
  final double outlineWidth;        // Outline thickness
  final bool enableClustering;      // Auto-cluster dense points
  final int clusterThreshold;       // Points per cluster
}

typedef MarkerSizeFunction = double Function(ChartDataPoint point);
```

---

## Technical Architecture

### Component Structure

```
lib/src/charts/
├── base/
│   ├── chart_layer.dart              // Base class for all chart layers
│   ├── chart_config.dart             // Base configuration interface
│   └── chart_renderer.dart           // Common rendering utilities
├── line/
│   ├── line_chart_layer.dart         // LineChartLayer implementation
│   ├── line_chart_config.dart        // LineChartConfig
│   ├── line_renderer.dart            // Line rendering logic
│   └── line_interpolator.dart        // Smooth curve calculations
├── area/
│   ├── area_chart_layer.dart         // AreaChartLayer implementation
│   ├── area_chart_config.dart        // AreaChartConfig
│   ├── area_renderer.dart            // Area fill rendering
│   └── area_gradient.dart            // Gradient calculations
├── bar/
│   ├── bar_chart_layer.dart          // BarChartLayer implementation
│   ├── bar_chart_config.dart         // BarChartConfig
│   ├── bar_renderer.dart             // Bar drawing logic
│   └── bar_layout.dart               // Grouping/stacking layout
├── scatter/
│   ├── scatter_chart_layer.dart      // ScatterChartLayer implementation
│   ├── scatter_chart_config.dart     // ScatterChartConfig
│   ├── scatter_renderer.dart         // Marker rendering
│   ├── marker_shapes.dart            // Marker shape definitions
│   └── clustering.dart               // Point clustering (optional)
└── charts.dart                        // Barrel file
```

### Class Hierarchy

```
RenderLayer (from rendering engine)
└── ChartLayer (base class)
    ├── LineChartLayer
    ├── AreaChartLayer
    ├── BarChartLayer
    └── ScatterChartLayer
```

### Key Abstractions

#### 1. ChartLayer Base Class
```dart
abstract class ChartLayer implements RenderLayer {
  List<ChartSeries> series;
  ChartTheme theme;
  
  @override
  void render(Canvas canvas, Size size, RenderContext context) {
    // 1. Get visible series from viewport culler
    final visibleSeries = cullSeries(context.viewport);
    
    // 2. Transform data coordinates to screen coordinates
    final screenPoints = transformPoints(visibleSeries, context.transformer);
    
    // 3. Render chart-specific visuals
    renderChart(canvas, screenPoints, context);
  }
  
  // Chart-specific rendering (implemented by subclasses)
  void renderChart(Canvas canvas, List<ScreenPoint> points, RenderContext context);
  
  // Viewport culling (shared)
  List<ChartSeries> cullSeries(ViewportState viewport);
  
  // Coordinate transformation (shared)
  List<ScreenPoint> transformPoints(List<ChartSeries> series, CoordinateTransformer transformer);
}
```

#### 2. Rendering Utilities
```dart
class ChartRenderer {
  // Shared rendering utilities for all chart types
  
  static void drawLine(Canvas canvas, List<Offset> points, Paint paint, LineStyle style) {
    switch (style) {
      case LineStyle.straight:
        _drawStraightLine(canvas, points, paint);
        break;
      case LineStyle.smooth:
        _drawSmoothLine(canvas, points, paint);
        break;
      case LineStyle.stepped:
        _drawSteppedLine(canvas, points, paint);
        break;
    }
  }
  
  static void drawMarker(Canvas canvas, Offset center, MarkerShape shape, double size, Paint paint) {
    // Draw various marker shapes
  }
  
  static void drawBar(Canvas canvas, Rect bounds, BarStyle style, Paint paint) {
    // Draw rounded-corner bars
  }
}
```

---

## Performance Requirements

### Rendering Performance

#### PR-001: Frame Time Budget
**MUST render within frame budget:**
- Target: <8ms (120 FPS capable)
- Maximum: <16ms (60 FPS minimum)
- Measurement: Average of 100 frames

**Per Chart Type:**
- Line Chart: <8ms for 10,000 points
- Area Chart: <10ms for 10,000 points (fill overhead)
- Bar Chart: <16ms for 1,000 bars
- Scatter Chart: <16ms for 10,000 points

#### PR-002: Viewport Culling
**MUST use efficient viewport culling:**
- Culling overhead: <1ms for 10,000 points
- Only visible points rendered
- Buffer zone: 10% outside viewport
- Culling accuracy: >95% (false positives OK)

#### PR-003: Object Pooling
**MUST use object pooling from rendering engine:**
- Paint objects: >90% pool hit rate
- Path objects: >90% pool hit rate
- Zero allocations in steady-state rendering
- Memory stable over time (no leaks)

#### PR-004: Animation Performance
**MUST maintain 60 FPS during animations:**
- Interpolation: <2ms per frame
- No frame drops during transitions
- Smooth easing curves
- Cancelable animations (no lingering tasks)

---

## Data Model

### Chart-Specific Data Structures

#### LineChartPoint
```dart
class LineChartPoint {
  final ChartDataPoint dataPoint;
  final Offset screenPosition;
  final Offset? controlPoint1;  // For smooth curves
  final Offset? controlPoint2;  // For smooth curves
  
  bool get isVisible;  // After viewport culling
}
```

#### BarChartBar
```dart
class BarChartBar {
  final ChartDataPoint dataPoint;
  final Rect bounds;           // Screen-space rectangle
  final Color color;
  final double cornerRadius;
  
  bool get isVisible;
}
```

#### ScatterChartMarker
```dart
class ScatterChartMarker {
  final ChartDataPoint dataPoint;
  final Offset screenPosition;
  final double size;
  final MarkerShape shape;
  final Color color;
  
  bool get isVisible;
}
```

---

## Testing Strategy

### Unit Tests

#### Test Coverage Requirements
- Minimum 90% code coverage per chart type
- 100% coverage of configuration objects
- All rendering modes tested

#### Per Chart Type Tests
1. **Configuration Tests**
   - Valid configurations accepted
   - Invalid configurations rejected
   - Default values correct

2. **Rendering Tests**
   - All rendering modes produce correct paths
   - Viewport culling works correctly
   - Coordinate transformations accurate

3. **Performance Tests**
   - Frame time within budget
   - Object pooling hit rates
   - Memory stable over time

### Integration Tests

#### Multi-Series Tests
- Multiple series render correctly
- Series colors distinct and consistent
- Z-ordering correct
- Legend generation accurate

#### Animation Tests
- Data updates animate smoothly
- Animation duration correct
- Animation curves applied
- Animations cancelable

#### Theme Integration Tests
- Theme changes apply correctly
- All theme properties used
- No chart recreation on theme change
- Performance unchanged with themes

### Benchmark Tests

#### Performance Benchmarks
Each chart type must have benchmarks for:
- 1,000 points: <5ms
- 10,000 points: <16ms
- 100,000 points: <100ms (with culling)

#### Memory Benchmarks
- Memory usage grows linearly with data size
- No memory leaks over 1000 render cycles
- Object pool efficiency >90%

---

## Non-Functional Requirements

### NFR-001: Cross-Platform Consistency
- Visual output identical on Web, iOS, Android, Desktop
- Performance proportional to device capability
- No platform-specific workarounds

### NFR-002: Backward Compatibility
- Configuration objects versioned
- Deprecated features supported for 2 major versions
- Migration guides provided

### NFR-003: Extensibility
- Custom chart types can extend ChartLayer
- Custom markers can be registered
- Custom interpolation functions supported

### NFR-004: Documentation
- Every public API has dartdoc
- Code examples for common use cases
- Performance best practices documented
- Migration guides for breaking changes

---

## Dependencies

### Required Foundation Layers

#### Layer 0: Foundation
- `ChartSeries` - Data series abstraction
- `ChartDataPoint` - Individual data points
- `ViewportCuller` - Efficient viewport culling
- `ObjectPool` - Paint/Path pooling
- `Interpolation` - Smooth curve calculations

#### Layer 1: Rendering Engine
- `RenderLayer` - Base rendering interface
- `RenderPipeline` - Layer composition
- `RenderContext` - Rendering state
- Paint/Path pooling infrastructure

#### Layer 2: Coordinate System
- `UniversalCoordinateTransformer` - Coordinate transformations
- `TransformContext` - Transformation state
- `ViewportState` - Viewport configuration
- All 8 coordinate spaces

#### Layer 3: Theming System
- `ChartTheme` - Theme definitions
- `SeriesTheme` - Series styling
- `AnimationTheme` - Animation settings
- Color palettes, line widths, marker sizes

---

## Implementation Phases

### Phase 1: Base Infrastructure (Week 1)
**Goal**: Establish common chart layer architecture

**Tasks**:
1. Create `ChartLayer` base class
2. Implement `ChartRenderer` utilities
3. Create configuration base classes
4. Set up test infrastructure

**Deliverables**:
- `chart_layer.dart` - Base class
- `chart_renderer.dart` - Shared utilities
- Unit tests for base classes

### Phase 2: Line Chart (Week 2)
**Goal**: Complete line chart implementation

**Tasks**:
1. Implement `LineChartLayer`
2. Implement straight line rendering
3. Implement smooth curve interpolation
4. Implement stepped line rendering
5. Add point markers
6. Integration with viewport culling
7. Theme integration
8. Animation support

**Deliverables**:
- Fully functional line chart
- 90% test coverage
- Performance benchmarks passing
- Documentation complete

### Phase 3: Area Chart (Week 3)
**Goal**: Complete area chart implementation

**Tasks**:
1. Implement `AreaChartLayer`
2. Implement solid fill rendering
3. Implement gradient fill rendering
4. Implement stacking support
5. Add line overlay option
6. Theme integration
7. Animation support

**Deliverables**:
- Fully functional area chart
- 90% test coverage
- Performance benchmarks passing
- Documentation complete

### Phase 4: Bar Chart (Week 4)
**Goal**: Complete bar chart implementation

**Tasks**:
1. Implement `BarChartLayer`
2. Implement vertical bars
3. Implement horizontal bars
4. Implement grouped layout
5. Implement stacked layout
6. Add corner radius support
7. Theme integration
8. Animation support

**Deliverables**:
- Fully functional bar chart
- 90% test coverage
- Performance benchmarks passing
- Documentation complete

### Phase 5: Scatter Chart (Week 5)
**Goal**: Complete scatter chart implementation

**Tasks**:
1. Implement `ScatterChartLayer`
2. Implement all marker shapes
3. Implement dynamic sizing
4. Add clustering support (optional)
5. Theme integration
6. Animation support

**Deliverables**:
- Fully functional scatter chart
- 90% test coverage
- Performance benchmarks passing
- Documentation complete

### Phase 6: Integration & Polish (Week 6)
**Goal**: Comprehensive testing and optimization

**Tasks**:
1. Multi-chart integration tests
2. Performance optimization
3. Documentation polish
4. Example gallery creation
5. User acceptance testing

**Deliverables**:
- All integration tests passing
- Performance targets met
- Complete documentation
- Example showcase

---

## Success Criteria

### Technical Success
- ✅ All 4 chart types implemented and tested
- ✅ Performance targets met (<16ms frame time)
- ✅ 90%+ test coverage
- ✅ Zero memory leaks
- ✅ Object pooling >90% hit rate

### User Success
- ✅ Intuitive API for all chart types
- ✅ Consistent behavior across chart types
- ✅ Beautiful default appearance
- ✅ Professional themes applied automatically
- ✅ Smooth animations delight users

### Documentation Success
- ✅ Every public API documented
- ✅ Code examples for common scenarios
- ✅ Performance best practices guide
- ✅ Migration guide for v1.0 users

---

## Risk Assessment

### High Risks

#### R-001: Performance with Large Datasets
**Risk**: Charts may not meet <16ms target with 10,000+ points  
**Mitigation**: 
- Aggressive viewport culling
- Object pooling for all rendering objects
- Progressive rendering for initial load
- Benchmark early and often

#### R-002: Smooth Curve Calculations
**Risk**: Bezier curve calculations may be too slow  
**Mitigation**:
- Cache control points when data unchanged
- Use efficient Catmull-Rom algorithm
- Pre-calculate curves during data update
- Fall back to straight lines if too slow

#### R-003: Animation Smoothness
**Risk**: Animations may stutter with many series  
**Mitigation**:
- Limit concurrent animations (max 10 series)
- Use efficient interpolation algorithms
- Allow disabling animations
- Profile animation performance early

### Medium Risks

#### R-004: Theme Integration Complexity
**Risk**: Theme changes may require chart recreation  
**Mitigation**:
- Design for theme hot-swapping from start
- Cache theme-derived values
- Test theme changes early
- Document theme change performance

#### R-005: Multi-Series Layout
**Risk**: Many series may overlap and become unreadable  
**Mitigation**:
- Provide legend with show/hide toggles
- Support series filtering
- Use distinct colors and patterns
- Document best practices for multi-series

---

## Open Questions

### Q-001: Marker Collision Detection
**Question**: Should scatter plot markers automatically avoid overlap?  
**Options**:
1. No collision detection (simple, fast)
2. Automatic jittering for overlapping markers
3. Clustering for dense areas

**Recommendation**: Start with option 1, add option 3 as optional feature

### Q-002: Animation Interruption
**Question**: What happens if new data arrives during animation?  
**Options**:
1. Cancel current animation, start new one
2. Queue animations
3. Blend animations

**Recommendation**: Option 1 for simplicity

### Q-003: Custom Chart Types
**Question**: Should we support custom chart types in this layer?  
**Options**:
1. Yes, provide extensibility from start
2. No, add in Layer 8 (Custom Charts)

**Recommendation**: Option 1 - ChartLayer is designed for extension

---

## Appendix A: Performance Benchmarks

### Line Chart Benchmarks
```dart
// 1,000 points (straight lines)
benchmark('Line chart - 1K points - straight', () {
  lineChart.render(canvas, size, context);
  // Target: <5ms
});

// 10,000 points (smooth curves)
benchmark('Line chart - 10K points - smooth', () {
  lineChart.render(canvas, size, context);
  // Target: <8ms
});

// 10 series × 1,000 points each
benchmark('Line chart - 10 series × 1K points', () {
  multiSeriesLineChart.render(canvas, size, context);
  // Target: <16ms
});
```

### Area Chart Benchmarks
```dart
// 1,000 points (gradient fill)
benchmark('Area chart - 1K points - gradient', () {
  areaChart.render(canvas, size, context);
  // Target: <6ms
});

// 5 series stacked
benchmark('Area chart - 5 stacked series', () {
  stackedAreaChart.render(canvas, size, context);
  // Target: <16ms
});
```

### Bar Chart Benchmarks
```dart
// 100 bars (grouped)
benchmark('Bar chart - 100 bars - grouped', () {
  barChart.render(canvas, size, context);
  // Target: <8ms
});

// 1,000 bars (stacked)
benchmark('Bar chart - 1K bars - stacked', () {
  stackedBarChart.render(canvas, size, context);
  // Target: <16ms
});
```

### Scatter Chart Benchmarks
```dart
// 10,000 points (no clustering)
benchmark('Scatter chart - 10K points', () {
  scatterChart.render(canvas, size, context);
  // Target: <16ms
});

// 100,000 points (with clustering)
benchmark('Scatter chart - 100K points - clustered', () {
  clusteredScatterChart.render(canvas, size, context);
  // Target: <50ms
});
```

---

## Appendix B: Visual Examples

### Line Chart Examples
```dart
// Example 1: Simple line chart
final simpleLineChart = LineChartLayer(
  series: [revenueSeries],
  config: LineChartConfig(
    lineStyle: LineStyle.smooth,
    showPoints: true,
  ),
);

// Example 2: Multi-series comparison
final comparisonChart = LineChartLayer(
  series: [actualSeries, forecastSeries, targetSeries],
  config: LineChartConfig(
    lineStyle: LineStyle.straight,
    showPoints: false,
    lineWidth: 2.0,
  ),
);

// Example 3: Stepped timeline
final timelineChart = LineChartLayer(
  series: [stateSeries],
  config: LineChartConfig(
    lineStyle: LineStyle.stepped,
    showPoints: true,
    pointShape: MarkerShape.square,
  ),
);
```

### Area Chart Examples
```dart
// Example 1: Gradient area chart
final gradientAreaChart = AreaChartLayer(
  series: [temperatureSeries],
  config: AreaChartConfig(
    fillStyle: AreaFillStyle.gradient,
    gradientStart: Colors.red.withOpacity(0.8),
    gradientEnd: Colors.red.withOpacity(0.1),
    showLine: true,
  ),
);

// Example 2: Stacked areas
final stackedAreaChart = AreaChartLayer(
  series: [desktopSeries, mobileSeries, tabletSeries],
  config: AreaChartConfig(
    fillStyle: AreaFillStyle.solid,
    fillOpacity: 0.7,
    grouping: AreaGrouping.stacked,
  ),
);
```

### Bar Chart Examples
```dart
// Example 1: Grouped bar chart
final groupedBarChart = BarChartLayer(
  series: [q1Sales, q2Sales, q3Sales, q4Sales],
  config: BarChartConfig(
    orientation: BarOrientation.vertical,
    grouping: BarGrouping.grouped,
    barWidth: 0.8,
    cornerRadius: 4.0,
  ),
);

// Example 2: Horizontal stacked bars
final stackedBarChart = BarChartLayer(
  series: [completedTasks, inProgressTasks, pendingTasks],
  config: BarChartConfig(
    orientation: BarOrientation.horizontal,
    grouping: BarGrouping.stacked,
    cornerRadius: 8.0,
  ),
);
```

### Scatter Chart Examples
```dart
// Example 1: Basic scatter plot
final scatterPlot = ScatterChartLayer(
  series: [measurementSeries],
  config: ScatterChartConfig(
    markerShape: MarkerShape.circle,
    markerSize: 6.0,
    markerStyle: MarkerStyle.filled,
  ),
);

// Example 2: Bubble chart (size-varying)
final bubbleChart = ScatterChartLayer(
  series: [citySeries],
  config: ScatterChartConfig(
    markerShape: MarkerShape.circle,
    sizeScale: (point) => sqrt(point.metadata['population']),
    markerStyle: MarkerStyle.filledWithOutline,
    outlineWidth: 2.0,
  ),
);
```

---

**Document Status**: ✅ Draft Complete  
**Ready for Review**: Yes  
**Next Steps**: Create plan.md, tasks.md, data-model.md, contracts/  
**Target Implementation**: 6 weeks  
**Last Updated**: October 6, 2025
