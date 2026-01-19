# Braven Charts Example App

A comprehensive showcase of all BravenChart widget features. This example app demonstrates every capability of the charting library through interactive, well-documented examples.

## 🚀 Getting Started

```bash
# Navigate to example directory
cd example

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 App Structure

The example app is organized into three main sections:

### 1. Feature Showcases

Comprehensive demonstrations of specific chart capabilities:

#### **Interaction System Showcase** 🆕

- **All Interaction Features** in one comprehensive demo
  - `Crosshair`: Vertical, horizontal, or both modes with snap-to-point
  - `Tooltip`: Default or custom builder with smart positioning
  - `Zoom`: CTRL+Scroll, pinch gestures, configurable limits
  - `Pan`: Middle-mouse drag, SHIFT+Scroll, touch gestures
  - `Keyboard Navigation`: Arrow keys, +/-, Home/End
- **10 Interaction Callbacks**: Real-time event logging
  - onDataPointTap, onDataPointHover, onDataPointLongPress
  - onZoomChanged, onPanChanged, onViewportChanged
  - onCrosshairChanged, onTooltipChanged, onSelectionChanged, onKeyboardAction
- **Live Configuration Panel**: Toggle features on/off
- **Factory Constructors**: Test `.all()`, `.none()`, and custom configs
- **Event Log**: See every interaction in real-time

#### **Interaction Examples** 🆕

- **9 Focused Examples** demonstrating specific interaction patterns
  1. Basic Crosshair (5-line setup)
  2. Custom Crosshair Style (color, width, dash pattern)
  3. Default Tooltip (hover/tap triggers)
  4. Custom Tooltip Builder (rich content, custom styling)
  5. Zoom & Pan Configuration (limits, bounds, step sizes)
  6. Gesture Callbacks (tap, long-press, hover)
  7. Keyboard Navigation (configurable key bindings)
  8. Multi-Series Crosshair (snap across multiple series)
  9. Complete Interaction (all features working together)

#### **Annotations Showcase**

- **All 5 Annotation Types** with live examples
  - `TextAnnotation`: Free-form labels with custom positioning
  - `PointAnnotation`: 7 marker shapes (circle, square, triangle, diamond, star, cross, plus)
  - `RangeAnnotation`: Highlight time periods or value zones
  - `ThresholdAnnotation`: Reference lines for targets and limits
  - `TrendAnnotation`: Linear, polynomial, exponential, and moving average trends
- **Interactive Controls**: Toggle annotation types on/off
- **Combined Demo**: All annotations working together
- **Code Snippets**: Ready-to-use examples for each type

#### **Advanced Features**

- **Real-Time Streaming**
  - Automatic 60 FPS throttling
  - Sensor data simulation (200ms intervals)
  - Multi-stream support (different update rates)
- **ChartController**
  - Add points dynamically
  - Remove oldest points
  - Clear series data
  - Add/remove annotations programmatically
  - Peak detection and auto-annotation
- **Interactive Buttons**: All controller operations
- **Complete Code Examples**: Stream setup and controller usage

#### **Axis & Theming**

- **4 Axis Presets**
  - `AxisConfig.defaults()`: Full axes with labels and grid
  - `AxisConfig.hidden()`: Sparkline style (no axes)
  - `AxisConfig.minimal()`: Axis lines only
  - `AxisConfig.gridOnly()`: Grid without axis lines
- **Custom Configurations**: Build from scratch or use `copyWith()`
- **Theming**
  - Light theme (optimized for light backgrounds)
  - Dark theme (optimized for dark backgrounds)
  - Side-by-side comparison
- **Interactive Theme Switcher**: Toggle between light/dark modes

### 2. Quickstart Guide

A single screen with all 6 quickstart scenarios:

1. **Basic Line Chart** - Get started in 2 minutes
2. **Add Annotations** - Highlight important data points
3. **fromValues Factory** - Simplified data input
4. **Customize Axes** - Hidden and grid-only styles
5. **Real-Time Data** - Streaming with throttling
6. **Programmatic Control** - Dynamic updates via ChartController

### 3. Chart Types

Individual screens for each chart type:

- **Line Charts**: Straight, smooth, and stepped interpolation
- **Area Charts**: Filled areas with gradients and stacking
- **Bar Charts**: Grouped and stacked bars (vertical & horizontal)
- **Scatter Plots**: Fixed-size, bubble charts, and clustering

## 🎯 Key Features Demonstrated

### Interaction System (Layer 7) 🆕

- ✅ **Crosshair**: Vertical, horizontal, both modes
- ✅ **Snap-to-Point**: Configurable snap radius (default: 30px)
- ✅ **Tooltip**: Default and custom builders
- ✅ **Smart Positioning**: Auto-flip tooltip when near edges
- ✅ **Zoom Controls**: CTRL+Scroll, pinch gestures
- ✅ **Pan Controls**: Middle-mouse drag (PRIMARY), SHIFT+Scroll, touch drag
- ✅ **Keyboard Navigation**: Arrow keys (pan), +/- (zoom), Home/End (jump)
- ✅ **Viewport Transformation**: Zoom/pan applied to rendering
- ✅ **Viewport Culling**: Optimized rendering for large datasets
- ✅ **10 Interaction Callbacks**: Full event system
- ✅ **Factory Constructors**: `.all()`, `.none()`, `.defaultConfig()`
- ✅ **GestureDetector Integration**: Tap, long-press, hover, pan, pinch
- ✅ **Focus Management**: Keyboard events with proper focus handling

### Annotations

- ✅ 5 annotation types (Text, Point, Range, Threshold, Trend)
- ✅ 7 marker shapes for point annotations
- ✅ Custom styling (colors, fonts, borders, backgrounds)
- ✅ z-index layering
- ✅ Multiple annotations on one chart

### Data Management

- ✅ Static series data
- ✅ Real-time streaming (Stream<ChartDataPoint>)
- ✅ Programmatic updates (ChartController)
- ✅ Multi-series support
- ✅ Dynamic add/remove operations

### Customization

- ✅ 4 axis presets + custom configurations
- ✅ Light and dark themes
- ✅ Custom dimensions (width × height)
- ✅ Titles and subtitles
- ✅ Legend control (show/hide)
- ✅ copyWith() for preset customization

### Performance

- ✅ Automatic 60 FPS throttling for streams
- ✅ RepaintBoundary for optimal rendering
- ✅ Efficient data updates
- ✅ Smooth animations

### Chart Types

- ✅ Line charts (4 supported)
- ✅ Area charts (4 supported)
- ✅ Bar charts (4 supported)
- ✅ Scatter plots (4 supported)

## 📂 File Structure

```
example/
├── lib/
│   ├── main.dart                              # App entry point
│   ├── screens/
│   │   ├── home_screen.dart                   # Main navigation
│   │   ├── quickstart_screen.dart             # All 6 quickstart scenarios
│   │   ├── interaction_showcase_screen.dart   # Full interaction demo 🆕
│   │   ├── interaction_examples_screen.dart   # 9 interaction examples 🆕
│   │   ├── interaction_examples/              # Individual example files 🆕
│   │   │   ├── basic_crosshair.dart
│   │   │   ├── custom_crosshair_style.dart
│   │   │   ├── default_tooltip.dart
│   │   │   ├── custom_tooltip_builder.dart
│   │   │   ├── zoom_pan_config.dart
│   │   │   ├── gesture_callbacks.dart
│   │   │   ├── keyboard_navigation.dart
│   │   │   ├── multi_series_crosshair.dart
│   │   │   └── complete_interaction.dart
│   │   ├── annotations_showcase_screen.dart   # 5 annotation types
│   │   ├── advanced_features_screen.dart      # Streaming & controller
│   │   ├── axis_theming_screen.dart           # Axis configs & themes
│   │   ├── line_chart_screen.dart             # Line chart demos
│   │   ├── area_chart_screen.dart             # Area chart demos
│   │   ├── bar_chart_screen.dart              # Bar chart demos
│   │   └── scatter_chart_screen.dart          # Scatter plot demos
│   ├── data/
│   │   └── chart_data_generator.dart          # Sample data utilities
│   └── widgets/
│       └── chart_container.dart               # Reusable chart wrapper
├── readme.md                                   # This file
└── interaction_features_test.md               # Manual testing guide 🆕
```

## 💡 Usage Examples

### Basic Line Chart

```dart
BravenChart(
  chartType: ChartType.line,
  series: [
    ChartSeries(
      id: 'sales',
      name: 'Monthly Sales',
      points: const [
        ChartDataPoint(x: 1, y: 10000),
        ChartDataPoint(x: 2, y: 15000),
        ChartDataPoint(x: 3, y: 13500),
      ],
    ),
  ],
  title: 'Sales Report',
  width: 400,
  height: 300,
)
```

### Real-Time Streaming

```dart
final streamController = StreamController<ChartDataPoint>();

BravenChart(
  chartType: ChartType.line,
  series: [],
  dataStream: streamController.stream,
  title: 'Live Sensor Data',
)

// Add data to stream
streamController.add(ChartDataPoint(x: 1, y: 20));
// Automatically throttled to 60 FPS!
```

### Programmatic Control

```dart
final controller = ChartController();

BravenChart(
  chartType: ChartType.line,
  series: [],
  controller: controller,
)

// Add data dynamically
controller.addPoint('series_id', ChartDataPoint(x: 1, y: 20));

// Remove oldest point
controller.removeOldestPoint('series_id');

// Clear all data
controller.clearSeries('series_id');

// Add annotation
controller.addAnnotation(
  PointAnnotation(
    id: 'peak',
    label: 'Peak Value',
    seriesId: 'series_id',
    dataPointIndex: 5,
    markerShape: MarkerShape.star,
  ),
);
```

### Annotations

```dart
BravenChart(
  chartType: ChartType.line,
  series: [salesData],
  annotations: [
    // Highlight a data point
    PointAnnotation(
      id: 'record',
      label: 'Record High',
      seriesId: 'sales',
      dataPointIndex: 5,
      markerShape: MarkerShape.star,
    ),

    // Show target line
    ThresholdAnnotation(
      id: 'target',
      label: 'Sales Target',
      value: 20000,
      axis: AnnotationAxis.y,
      style: AnnotationStyle(
        borderColor: Colors.green,
        borderWidth: 2,
      ),
    ),

    // Highlight time range
    RangeAnnotation(
      id: 'q1',
      label: 'Q1',
      startX: 1,
      endX: 3,
      fillColor: Colors.blue.withOpacity(0.1),
    ),
  ],
)
```

### Axis Customization

```dart
// Use preset
BravenChart(
  chartType: ChartType.line,
  series: [data],
  xAxis: AxisConfig.hidden(),      // Sparkline
  yAxis: AxisConfig.gridOnly(),    // Grid only
)

// Custom configuration
BravenChart(
  chartType: ChartType.line,
  series: [data],
  xAxis: AxisConfig(
    label: 'Time (seconds)',
    showAxis: true,
    showLabels: true,
    showGrid: true,
  ),
  yAxis: AxisConfig.defaults().copyWith(
    label: 'Temperature (°C)',
  ),
)
```

### Theming

```dart
// Light theme
BravenChart(
  chartType: ChartType.line,
  series: [data],
  theme: ChartTheme.defaultLight,
)

// Dark theme
BravenChart(
  chartType: ChartType.line,
  series: [data],
  theme: ChartTheme.defaultDark,
)
```

### Interaction System 🆕

#### Basic Crosshair

```dart
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig(
    crosshair: CrosshairConfig(
      enabled: true,
      mode: CrosshairMode.both,      // Vertical + horizontal lines
      snapToDataPoint: true,          // Snap to nearest point
      snapRadius: 30.0,               // Within 30 pixels
    ),
  ),
)
```

#### Custom Tooltip

```dart
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig(
    tooltip: TooltipConfig(
      enabled: true,
      triggerMode: TooltipTriggerMode.both,  // Hover + tap
      customBuilder: (context, dataPoint) {
        return Column(
          children: [
            Text('X: ${dataPoint['x']}'),
            Text('Y: ${dataPoint['y']}'),
            Text('Custom content here!'),
          ],
        );
      },
    ),
  ),
)
```

#### Zoom & Pan

```dart
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig(
    enableZoom: true,   // CTRL+Scroll, pinch gestures
    enablePan: true,    // Middle-mouse drag, SHIFT+Scroll
    onZoomChanged: (zoomX, zoomY) {
      print('Zoom: ${zoomX * 100}% x ${zoomY * 100}%');
    },
    onPanChanged: (offset) {
      print('Pan: dx=${offset.dx}, dy=${offset.dy}');
    },
  ),
)
```

#### Keyboard Navigation

```dart
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig(
    keyboard: KeyboardConfig(
      enabled: true,
      panStep: 15.0,          // Pixels per arrow key press
      zoomStep: 0.15,         // 15% zoom per +/- key
      enableArrowKeys: true,   // Up/Down/Left/Right
      enablePlusMinusKeys: true,  // +/- for zoom
      enableHomeEndKeys: true,    // Jump to start/end
    ),
  ),
)
```

#### All Interaction Callbacks

```dart
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig(
    // Visual features
    crosshair: CrosshairConfig(enabled: true),
    tooltip: TooltipConfig(enabled: true),
    enableZoom: true,
    enablePan: true,

    // All 10 callbacks
    onDataPointTap: (point, position) {
      print('Tapped: X=${point.x}, Y=${point.y}');
    },
    onDataPointHover: (point, position) {
      if (point != null) {
        print('Hovering: X=${point.x}, Y=${point.y}');
      }
    },
    onDataPointLongPress: (point, position) {
      print('Long-pressed: X=${point.x}, Y=${point.y}');
    },
    onSelectionChanged: (points) {
      print('Selected ${points.length} points');
    },
    onZoomChanged: (zoomX, zoomY) {
      print('Zoom: ${zoomX * 100}%');
    },
    onPanChanged: (offset) {
      print('Pan: ${offset.dx}, ${offset.dy}');
    },
    onViewportChanged: (bounds) {
      print('Viewport: ${bounds['minX']} to ${bounds['maxX']}');
    },
    onCrosshairChanged: (position, snapPoints) {
      print('Crosshair at: $position, snapped to ${snapPoints.length} points');
    },
    onTooltipChanged: (visible, data) {
      print('Tooltip ${visible ? "shown" : "hidden"}');
    },
    onKeyboardAction: (action, targetPoint) {
      print('Keyboard action: $action');
    },
  ),
)
```

#### Factory Constructors

```dart
// All features enabled
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig.all(),
)

// All features disabled (static chart)
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig.none(),
)

// Default settings
BravenChart(
  chartType: ChartType.line,
  series: [data],
  interactionConfig: InteractionConfig.defaultConfig(),
)
```

## 🧪 Testing

The example app serves as both a showcase and a testing platform. Each screen can be used to:

- **Visual Testing**: Verify chart rendering across different configurations
- **Interaction Testing**: Test dynamic updates, streaming, and controller operations
- **Theme Testing**: Validate appearance in light and dark modes
- **Performance Testing**: Monitor 60 FPS throttling and rendering efficiency

## 📖 Learn More

- **Quickstart Guide**: Start with `quickstart_screen.dart` for the fastest learning path
- **API Documentation**: Explore each showcase screen for detailed feature explanations
- **Code Snippets**: Every screen includes copy-ready code examples
- **Interactive Examples**: Use toggle buttons and controls to see features in action

## 🎨 Customization Guide

The example app demonstrates these customization patterns:

1. **Axis Presets**: Start with `defaults()`, `hidden()`, `minimal()`, or `gridOnly()`
2. **Modify Presets**: Use `copyWith()` to change specific properties
3. **Custom Axes**: Build from scratch with `AxisConfig(...)`
4. **Themes**: Choose `defaultLight` or `defaultDark` based on your UI
5. **Annotations**: Mix and match all 5 types for rich data visualization
6. **Data Updates**: Use static series, streaming, or controller based on your needs

## 🚦 Navigation Flow

```
Home Screen
├── Feature Showcases
│   ├── Interaction Showcase   → interaction_showcase_screen.dart 🆕
│   ├── Interaction Examples   → interaction_examples_screen.dart 🆕
│   ├── Annotations            → annotations_showcase_screen.dart
│   ├── Advanced Features      → advanced_features_screen.dart
│   └── Axis & Theming         → axis_theming_screen.dart
└── Chart Types
    ├── Quickstart Guide       → quickstart_screen.dart
    ├── Line Charts            → line_chart_screen.dart
    ├── Area Charts            → area_chart_screen.dart
    ├── Bar Charts             → bar_chart_screen.dart
    └── Scatter Plots          → scatter_chart_screen.dart
```

## 📝 Notes

- All screens compile without errors
- Real-time streaming automatically throttles to 60 FPS
- Controllers must be disposed to prevent memory leaks
- Stream controllers must be closed when no longer needed
- Each annotation type has unique parameters - see individual demos
- Axis presets can be mixed (e.g., `hidden()` for X, `defaults()` for Y)

## 🎯 Best Practices

1. **Dispose Resources**: Always dispose controllers and close streams
2. **Use Presets First**: Start with axis presets before custom configs
3. **Test Themes**: Check both light and dark themes for accessibility
4. **Leverage Streaming**: Use `dataStream` for real-time data (auto-throttled)
5. **Controller Pattern**: Use `ChartController` for dynamic, user-driven updates
6. **Annotation Layering**: Use `zIndex` to control annotation stacking order
7. **Interaction Factories**: Start with `InteractionConfig.all()` then customize 🆕
8. **Keyboard Focus**: Charts need focus for keyboard navigation (click to focus) 🆕
9. **Middle-Mouse Pan**: Primary pan method for desktop (SHIFT+Scroll as fallback) 🆕
10. **Viewport Optimization**: Enable zoom/pan for large datasets (viewport culling) 🆕

## 🧪 Testing & Verification

### Automated Testing

```bash
# Run all tests
flutter test

# Interaction widget tests (12 tests)
flutter test test/interaction/widgets/interaction_widget_test.dart
```

### Manual Testing

See **[interaction_features_test.md](interaction_features_test.md)** for comprehensive manual testing guide covering:

- All 15 core interaction features
- All 10 interaction callbacks
- Factory constructors (.all(), .none(), .defaultConfig())
- Platform-specific behaviors
- Performance verification

The guide includes step-by-step test procedures for every interaction feature.

---

**Built with** ❤️ **using BravenCharts**
