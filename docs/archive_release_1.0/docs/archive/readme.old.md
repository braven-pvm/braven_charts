# Braven Charts

<div align="center">

![Braven Charts Hero](screenshots/hero-image.png)

**A powerful and flexible charting library for Flutter**

[![Pub Version](https://img.shields.io/pub/v/braven_charts.svg)](https://pub.dev/packages/braven_charts)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MI## 📚 Documentation

- **[📖 Full Documentation](docs/readme.md)** - Complete documentation index
- **[🎨 Theming Guide](docs/features/theming.md)** - Complete theming documentation
- **[📈 Trendlines Guide](docs/features/trendlines.md)** - Comprehensive trendline analysis with 6 mathematical curve types
- **[📝 Annotations Guide](docs/features/annotations.md)** - Annotation persistence system
- **[📋 User Guides](docs/guides/)** - Screenshots and usage guides
- **[📊 Examples](example/)** - Full-featured demo app
- **[🔧 API Reference](https://pub.dev/documentation/braven_charts/)** - Complete API docs
- **[🛠️ Development](docs/development/)** - Development documentation and specifications

[Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

Beautiful, interactive charts with comprehensive theming and customization capabilities

[🚀 Quick Start](#-quick-start) • [🎨 Themes](#-themes) • [📊 Examples](#-chart-types) • [📖 Documentation](docs/readme.md)

</div>

---

## ✨ Key Features

<div align="center">

|   📊 **Chart Types**    |   🎨 **Theming**    |  🎯 **Interactions**   | ⚡ **Performance**  |
| :---------------------: | :-----------------: | :--------------------: | :-----------------: |
| Line, Area, Bar charts  | 7 predefined themes | Tooltips & crosshairs  | Optimized rendering |
|  Multiple data series   | Full customization  |  Zoom & pan gestures   |  Smooth animations  |
|    Bezier smoothing     | Axis title styling  |   Real-time updates    |  Responsive design  |
| **Advanced Trendlines** |   **Desktop UX**    | **Mouse Interactions** | **Event Handling**  |
|  6 mathematical curves  |  Professional feel  | Middle-button panning  |  Proper delegation  |
|  Statistical analysis   |   Native behavior   |  Isolated event zones  | Multi-touch support |
|   **Custom Builders**   | **Widget Markers**  |  **Custom Tooltips**   |  **Full Control**   |
|   No size constraints   | Any Flutter widget  |  Animated transitions  |  Complete styling   |
|   State-aware design    | Interactive widgets |   Builder callbacks    | Native performance  |

</div>

### 🎯 **NEW in v0.3.0**: Revolutionary Annotation System

<div align="center">

|           **📝 Composition Architecture**            |        **🎨 Rich Styling**         |     **⚡ Performance**      |   **🔄 Migration**   |
| :--------------------------------------------------: | :--------------------------------: | :-------------------------: | :------------------: |
| MarkerStyle + TitleStyle + TooltipStyle + RangeStyle | Factory constructors for all types | Automatic caching & pooling | Backward compatible  |
|             Clean separation of concerns             |    Type-specific optimizations     |      Viewport culling       | Deprecation warnings |
|               No property duplication                |         Theme integration          |      Memory efficient       | Gradual upgrade path |

</div>

```dart
// Revolutionary composition approach
AnnotationStyle.text(
  markerStyle: MarkerStyle(/* marker config */),
  titleStyle: TitleStyle(/* title config */),
  tooltipStyle: TooltipStyle(/* tooltip config */),
  // Clean, organized, type-safe!
)
```

### 🖱️ Professional Desktop Experience

![Scrollbar Demo](screenshots/scrollbar-demo.gif)

**Advanced Scrollbar System:**

- Native-style scrollbars that appear when zooming
- Professional desktop behavior with instant mouse tracking
- Positioned outside chart area to prevent interaction conflicts
- Real-time synchronization with manual panning

**Precision Mouse Controls:**

- **Left Button**: Crosshair movement and tooltip selection
- **Middle Button**: Dedicated chart panning functionality
- **Multi-touch**: Pinch-to-zoom and gesture navigation
- No more mouse button conflicts or unexpected behavior!

## 📊 Chart Types

### Interactive Line Charts with Advanced Controls

![Line Chart Example](screenshots/line-chart-interactive.png)

**Professional Features:**

- Smooth crosshair following with boundary clamping
- Real-time tooltips showing precise data values
- Zoom and pan with professional scrollbar controls
- Multiple series with customizable styling

![Zoom and Pan Demo](screenshots/zoom-pan-demo.gif)

```dart
BravenChart(
  theme: ChartTheme.material,
  series: [
    ChartSeriesData(
      name: 'Revenue',
      data: [
        ChartData(x: 'Jan', y: 100),
        ChartData(x: 'Feb', y: 150),
        ChartData(x: 'Mar', y: 120),
      ],
    ),
  ],
)
```

### Area Charts with Gradients

![Area Chart Example](screenshots/area-chart.png)

```dart
ChartSeriesData(
  name: 'Profit',
  data: data,
  enableArea: true,
  areaOpacity: 0.4,
  enableBezier: true,
)
```

### Multiple Series

![Multi Series Chart](screenshots/multi-series.png)

```dart
series: [
  ChartSeriesData(name: 'Revenue', data: revenueData, color: Colors.blue),
  ChartSeriesData(name: 'Profit', data: profitData, color: Colors.green),
]
```

## 🎨 Themes

Choose from **7 professionally designed themes** or create your own:

<div align="center">
  
| Light | Dark | Material | Cupertino |
|:---:|:---:|:---:|:---:|
| ![Light Theme](screenshots/theme-light.png) | ![Dark Theme](screenshots/theme-dark.png) | ![Material Theme](screenshots/theme-material.png) | ![Cupertino Theme](screenshots/theme-cupertino.png) |

|                     Business                      |                     Vibrant                     |                     Minimal                     |                    Custom                     |
| :-----------------------------------------------: | :---------------------------------------------: | :---------------------------------------------: | :-------------------------------------------: |
| ![Business Theme](screenshots/theme-business.png) | ![Vibrant Theme](screenshots/theme-vibrant.png) | ![Minimal Theme](screenshots/theme-minimal.png) | ![Custom Theme](screenshots/theme-custom.png) |

</div>

### Quick Theme Selection

```dart
// Use predefined themes
BravenChart(theme: ChartTheme.dark, ...)
BravenChart(theme: ChartTheme.vibrant, ...)
BravenChart(theme: ChartTheme.minimal, ...)
```

### Custom Theming

```dart
final customTheme = ChartTheme(
  backgroundColor: Colors.white,
  seriesColors: [Colors.blue, Colors.green],
  axisTitleStyle: AxisTitleStyle(
    textStyle: TextStyle(fontWeight: FontWeight.bold),
    backgroundColor: Colors.blue.withOpacity(0.1),
    padding: EdgeInsets.all(8),
  ),
);
```

## 🎯 Interactive Features

![Interactive Features Demo](screenshots/interactions.gif)

```dart
BravenChart(
  enableTooltips: true,    // Hover data points
  enableCrosshair: true,   // Crosshair tracking
  enableZoom: true,        // Pinch to zoom
  enablePan: true,         // Pan gestures
  // ... other properties
)
```

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  braven_charts: ^0.6.0
```

### Basic Usage

```dart
import 'package:braven_charts/braven_charts.dart';

BravenChart(
  theme: ChartTheme.material,
  series: [
    ChartSeriesData(
      name: 'Sales',
      data: [
        ChartData(x: 'Q1', y: 100),
        ChartData(x: 'Q2', y: 150),
        ChartData(x: 'Q3', y: 120),
        ChartData(x: 'Q4', y: 180),
      ],
    ),
  ],
  xAxis: ChartAxis(title: 'Quarter'),
  yAxis: ChartAxis(title: 'Revenue ($K)'),
  enableZoom: true,           // Enable zoom and scrollbars
  enableCrosshair: true,      // Interactive crosshair
  enableTooltip: true,        // Data tooltips
)
```

### **NEW in v0.3.0**: Quick Annotation Usage

```dart
BravenChart(
  // ... basic chart setup
  annotations: [
    // Highlight a peak performance point
    ChartAnnotation.point(
      position: ChartPosition(x: 'Q2', y: 150),
      style: AnnotationStyle.point(
        color: Colors.red,
        markerStyle: MarkerStyle(size: 10.0),
        titleStyle: TitleStyle(
          text: 'Peak Sales',
          position: TitlePosition.top,
        ),
      ),
    ),

    // Highlight a growth period
    ChartAnnotation.range(
      startPosition: ChartPosition(x: 'Q1', y: 0),
      endPosition: ChartPosition(x: 'Q2', y: 200),
      style: AnnotationStyle.range(
        backgroundColor: Colors.green.withOpacity(0.2),
        titleStyle: TitleStyle(text: 'Growth Period'),
      ),
    ),
  ],
)
```

## 🖱️ Professional Desktop Controls

![Mouse Interaction Demo](screenshots/mouse-interactions.gif)

### Scrollbar Configuration

```dart
BravenChart(
  theme: ChartTheme.material.copyWith(
    scrollbarStyle: ScrollbarStyle(
      enabled: true,
      thickness: 12.0,           // Scrollbar width/height
      minZoomThreshold: 1.1,     // When to show scrollbars
      activeOpacity: 0.9,        // Opacity when dragging
      idleOpacity: 0.6,          // Opacity when idle
      color: Colors.grey,        // Scrollbar color
    ),
  ),
  // ... rest of configuration
)
```

### Mouse Interaction Controls

- **Left Mouse Button**: Move crosshair, select data points
- **Middle Mouse Button**: Pan chart when zoomed (hold + drag)
- **Mouse Wheel**: Zoom in/out at cursor position
- **Scrollbar Dragging**: Precise navigation through zoomed content
- **Track Clicking**: Jump to any position by clicking scrollbar track

````

## � Advanced Annotation System

### 🎯 Comprehensive Annotation Styling

**New in v0.3.0**: Revolutionary annotation system with composition-based styling architecture. Create sophisticated annotations with precise control over every visual aspect.

![Annotations Demo](screenshots/annotations-demo.gif)

#### Core Annotation Types

The new annotation system supports multiple annotation types with specialized styling:

```dart
// Text annotations with rich styling
final textAnnotation = ChartAnnotation.text(
  position: ChartPosition(x: 'Q2', y: 150),
  style: AnnotationStyle.text(
    backgroundColor: Colors.blue.withOpacity(0.1),
    borderColor: Colors.blue,
    borderWidth: 1.0,
    borderRadius: BorderRadius.circular(8.0),
    markerStyle: MarkerStyle(
      visible: true,
      size: 8.0,
      color: Colors.red,
      borderColor: Colors.white,
      borderWidth: 2.0,
    ),
    titleStyle: TitleStyle(
      text: 'Peak Performance',
      position: TitlePosition.top,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      padding: EdgeInsets.all(8.0),
    ),
    tooltipStyle: TooltipStyle(
      backgroundColor: Colors.black87,
      borderRadius: BorderRadius.circular(6.0),
      padding: EdgeInsets.all(12.0),
    ),
  ),
);

// Point annotations for highlighting specific data
final pointAnnotation = ChartAnnotation.point(
  position: ChartPosition(x: 'Q3', y: 120),
  style: AnnotationStyle.point(
    color: Colors.orange,
    strokeWidth: 3.0,
    markerStyle: MarkerStyle(
      type: MarkerType.circle,
      size: 12.0,
      color: Colors.orange,
      borderColor: Colors.white,
      borderWidth: 2.0,
    ),
  ),
);

// Range annotations for highlighting periods
final rangeAnnotation = ChartAnnotation.range(
  startPosition: ChartPosition(x: 'Q1', y: 0),
  endPosition: ChartPosition(x: 'Q2', y: 200),
  style: AnnotationStyle.range(
    backgroundColor: Colors.yellow.withOpacity(0.2),
    borderColor: Colors.yellow.withOpacity(0.5),
    borderWidth: 1.0,
    borderRadius: BorderRadius.circular(4.0),
    rangeStyle: RangeStyle(
      minHeight: 40.0,
      paddingX: 8.0,
      paddingY: 4.0,
    ),
    titleStyle: TitleStyle(
      text: 'Growth Period',
      position: TitlePosition.center,
    ),
  ),
);
```

#### Composition Architecture

The annotation system uses a powerful composition pattern with four specialized style classes:

```dart
AnnotationStyle(
  // Basic visual properties
  color: Colors.blue,
  backgroundColor: Colors.white.withOpacity(0.9),
  borderColor: Colors.blue.withOpacity(0.5),
  borderWidth: 1.0,

  // Specialized composition styles
  markerStyle: MarkerStyle(
    type: MarkerType.circle,
    size: 10.0,
    color: Colors.red,
    borderColor: Colors.white,
    borderWidth: 2.0,
    visible: true,
  ),

  titleStyle: TitleStyle(
    text: 'Important Point',
    position: TitlePosition.top,
    style: TextStyle(fontWeight: FontWeight.bold),
    padding: EdgeInsets.all(8.0),
    backgroundColor: Colors.white.withOpacity(0.8),
  ),

  tooltipStyle: TooltipStyle(
    backgroundColor: Colors.black87,
    textColor: Colors.white,
    borderRadius: BorderRadius.circular(6.0),
    padding: EdgeInsets.all(12.0),
    showArrow: true,
  ),

  rangeStyle: RangeStyle(
    minHeight: 30.0,
    paddingX: 8.0,
    paddingY: 4.0,
    borderColor: Colors.blue,
    areaColor: Colors.blue.withOpacity(0.1),
  ),
);
```

#### Factory Constructors for Common Use Cases

```dart
// Quick text annotation
final quickText = AnnotationStyle.text(
  backgroundColor: Colors.blue.withOpacity(0.1),
  borderColor: Colors.blue,
);

// Quick point annotation
final quickPoint = AnnotationStyle.point(
  color: Colors.red,
  markerStyle: MarkerStyle(size: 8.0),
);

// Quick range annotation
final quickRange = AnnotationStyle.range(
  backgroundColor: Colors.yellow.withOpacity(0.2),
  borderColor: Colors.yellow,
);
```

#### Performance Optimizations

The annotation system includes built-in performance optimizations:

- **Style Caching**: Automatic caching of computed styles
- **Object Pooling**: Reuse of annotation objects to reduce garbage collection
- **Viewport Culling**: Only render annotations visible in current viewport
- **Efficient Hit Testing**: Optimized touch/click detection for interactive annotations

```dart
// Performance is automatically handled, but you can tune cache settings
BravenChart(
  annotations: annotations,
  // Chart automatically manages annotation performance
  performanceConfig: PerformanceConfig(
    enableAnnotationCaching: true,
    maxCachedStyles: 100,
    enableViewportCulling: true,
  ),
);
```

### 📊 Interactive Annotation Features

#### Dynamic Annotation Management

```dart
class _ChartPageState extends State<ChartPage> {
  final ChartController _controller = ChartController();
  List<ChartAnnotation> _annotations = [];

  void _addAnnotation(ChartPosition position) {
    setState(() {
      _annotations.add(
        ChartAnnotation.text(
          position: position,
          style: AnnotationStyle.text(
            backgroundColor: Colors.blue.withOpacity(0.1),
            titleStyle: TitleStyle(
              text: 'Note at ${position.x}',
              position: TitlePosition.top,
            ),
          ),
        ),
      );
    });
  }

  void _removeAnnotation(int index) {
    setState(() {
      _annotations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BravenChart(
      controller: _controller,
      annotations: _annotations,
      onChartTap: (position) => _addAnnotation(position),
      // Other chart properties...
    );
  }
}
```

#### Annotation Persistence

```dart
// Save annotations to storage
final annotationData = _annotations.map((a) => a.toJson()).toList();
await storage.save('chart_annotations', jsonEncode(annotationData));

// Load annotations from storage
final jsonData = await storage.load('chart_annotations');
final List<dynamic> annotationList = jsonDecode(jsonData);
_annotations = annotationList
    .map((data) => ChartAnnotation.fromJson(data))
    .toList();
```

## �📈 Advanced Features

### 🎨 Custom Markers & Tooltips

Create completely custom marker widgets and tooltip displays:

```dart
ChartSeriesData(
  name: 'Custom Series',
  data: data,
  markerStyle: MarkerStyle(
    type: MarkerType.custom,
    customMarkerBuilder: (context, dataPoint, seriesIndex, dataIndex, isHovered, isHighlighted) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isHovered ? Colors.red : Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: isHighlighted ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            dataPoint.y.toInt().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    },
    tooltipConfig: TooltipConfig(
      customTooltipBuilder: (context, dataPoint, seriesIndex, dataIndex, position) {
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Custom Tooltip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Value: ${dataPoint.y}',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    ),
  ),
)
```

**Custom Builder Features:**
- **No Size Constraints**: Custom markers can be any size or shape
- **Full Widget Support**: Use any Flutter widget for markers and tooltips
- **State-Aware**: Builders receive hover and selection state
- **Smooth Animations**: Custom tooltips animate in/out like default tooltips
- **Complete Control**: Replace default rendering entirely with your custom widgets

### Enhanced Axis Control

```dart
ChartAxis(
  title: 'Revenue',
  intervalCount: 5,         // Previously: labelCount
  interval: 100,           // Previously: labelInterval
  titleStyle: AxisTitleStyle(
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    backgroundColor: Colors.blue.withOpacity(0.1),
    borderRadius: 4.0,
  ),
  labelFormatter: (value) => '\$${value.toInt()}K',
)
````

### Responsive Design

```dart
Widget buildChart(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;

  return BravenChart(
    theme: isMobile ? ChartTheme.minimal : ChartTheme.business,
    // ... other properties
  );
}
```

## � Migration Guide

### 🔧 From v0.1.x to v0.2.0+

#### Property Name Changes

Version 0.2.0 introduces cleaner property names:

| Old (v0.1.x)         | New (v0.2.0+)      |
| -------------------- | ------------------ |
| `labelCount: 5`      | `intervalCount: 5` |
| `labelInterval: 100` | `interval: 100`    |

### 📝 From v0.2.x to v0.3.0 - New Annotation System

**Major Update**: Version 0.3.0 introduces a revolutionary composition-based annotation system.

#### Annotation Style Migration

```dart
// Old (v0.2.x) - Direct property approach
AnnotationStyle(
  markerSize: 8.0,
  markerColor: Colors.red,
  markerBorderColor: Colors.white,
  markerBorderWidth: 2.0,
  textStyle: TextStyle(fontWeight: FontWeight.bold),
  textPadding: EdgeInsets.all(8.0),
  backgroundColor: Colors.blue.withOpacity(0.1),
)

// New (v0.3.0+) - Composition approach
AnnotationStyle(
  backgroundColor: Colors.blue.withOpacity(0.1),
  markerStyle: MarkerStyle(
    size: 8.0,
    color: Colors.red,
    borderColor: Colors.white,
    borderWidth: 2.0,
  ),
  titleStyle: TitleStyle(
    style: TextStyle(fontWeight: FontWeight.bold),
    padding: EdgeInsets.all(8.0),
  ),
)
```

#### Factory Constructor Migration

```dart
// Old (v0.2.x)
final style = AnnotationStyle(
  markerSize: 10.0,
  markerColor: Colors.blue,
  backgroundColor: Colors.white,
);

// New (v0.3.0+) - Type-specific factories
final style = AnnotationStyle.point(
  markerStyle: MarkerStyle(
    size: 10.0,
    color: Colors.blue,
  ),
  backgroundColor: Colors.white,
);
```

#### Backward Compatibility

The new system maintains backward compatibility with deprecated parameter warnings:

```dart
// This still works but shows deprecation warnings
AnnotationStyle(
  markerSize: 8.0,        // ⚠️ Deprecated: Use markerStyle.size instead
  textStyle: textStyle,   // ⚠️ Deprecated: Use titleStyle.style instead
  textPadding: padding,   // ⚠️ Deprecated: Use titleStyle.padding instead
)
```

#### Migration Strategy

1. **Gradual Migration**: Update one annotation type at a time
2. **Use Factory Constructors**: Start with `AnnotationStyle.text()`, `.point()`, `.range()`
3. **Composition Benefits**: Leverage specialized style classes for better organization
4. **Performance Gains**: New system includes automatic caching and optimization

```dart
// Step 1: Replace direct properties with composition
// Step 2: Use type-specific factory constructors
// Step 3: Remove deprecated parameter usage
// Step 4: Leverage new features like RangeStyle, TooltipStyle
```

## 🎮 Try the Demo

```bash
git clone https://github.com/forcegage-pvm/braven_charts.git
cd braven_charts/example
flutter run -d web-server --web-port=8000
```

Then open http://localhost:8000 to see all themes and features in action!

![Demo App](screenshots/demo-app.png)

## 📚 Documentation

- **[🎨 Theming Guide](docs/features/theming.md)** - Complete theming documentation
- **[� Trendlines Guide](docs/features/trendlines.md)** - Comprehensive trendline analysis with 6 mathematical curve types
- **[�📊 Examples](example/)** - Full-featured demo app
- **[🔧 API Reference](https://pub.dev/documentation/braven_charts/)** - Complete API docs

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](contributing.md) for details.

## 📄 License

MIT License - see [license](license) file for details.

---

<div align="center">

**Made with ❤️ by the Braven Charts team**

[⭐ Star on GitHub](https://github.com/forcegage-pvm/braven_charts) • [🐛 Report Issues](https://github.com/forcegage-pvm/braven_charts/issues) • [💬 Discussions](https://github.com/forcegage-pvm/braven_charts/discussions)

</div>
  gridColor: Colors.grey[300]!,
  axisTitleStyle: AxisTitleStyle(
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blue[800],
    ),
    backgroundColor: Colors.blue.withOpacity(0.1),
    padding: EdgeInsets.all(8),
    borderRadius: 6.0,
  ),
  seriesColors: [
    Colors.blue,
    Colors.green,
    Colors.orange,
  ],
);
```

### Theme Customization

Modify existing themes to match your brand:

```dart
final brandTheme = ChartTheme.material.copyWith(
  backgroundColor: Color(0xFFF8F9FA),
  seriesColors: [Color(0xFF007BFF), Color(0xFF28A745)],
  axisTitleStyle: AxisTitleStyle(
    textStyle: TextStyle(
      fontFamily: 'YourBrandFont',
      fontWeight: FontWeight.w600,
    ),
    backgroundColor: Color(0xFF007BFF).withOpacity(0.1),
  ),
);
```

## 📈 Advanced Chart Configuration

### Enhanced Axis Control

The axis system provides rich customization with updated property names:

```dart
ChartAxis(
  title: 'Revenue',
  // Updated property names (v0.2.0+)
  intervalCount: 6,  // Previously: labelCount
  interval: 100,     // Previously: labelInterval

  // Enhanced title styling
  titleStyle: AxisTitleStyle(
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.indigo,
    ),
    backgroundColor: Colors.indigo.withOpacity(0.1),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    borderRadius: 4.0,
    offset: Offset(0, -2),
  ),

  // Formatting and display
  labelFormatter: (value) => '\$${value.toStringAsFixed(0)}K',
  showGridLines: true,
  showAxisLine: true,
)
```

### Multiple Series

Display multiple data series with different styling:

```dart
ChartData(
  series: [
    SeriesData(
      name: 'Revenue',
      data: revenueData,
      color: Colors.blue,
      markerStyle: MarkerStyle(
        shape: MarkerShape.circle,
        size: 6,
      ),
    ),
    SeriesData(
      name: 'Profit',
      data: profitData,
      color: Colors.green,
      markerStyle: MarkerStyle(
        shape: MarkerShape.square,
        size: 6,
      ),
    ),
  ],
)
```

### Interactive Features

Enable rich interactivity with tooltips and crosshairs:

```dart
BravenChart(
  // ... other properties
  enableTooltips: true,
  enableCrosshair: true,
  enableZoom: true,
  enablePan: true,

  tooltipBuilder: (context, data) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${data.seriesName}: ${data.y}',
        style: TextStyle(color: Colors.white),
      ),
    );
  },
)
```

## Responsive Design

Create charts that adapt to different screen sizes:

```dart
Widget buildResponsiveChart(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return BravenChart(
    theme: screenWidth < 600
        ? ChartTheme.minimal.copyWith(
            axisTitleStyle: AxisTitleStyle(
              textStyle: TextStyle(fontSize: 12),
              padding: EdgeInsets.all(4),
            ),
          )
        : ChartTheme.business,
    // ... other properties
  );
}
```

## 🎯 Performance Tips

1. **Use appropriate intervals**: Set reasonable `intervalCount` and `interval` values
2. **Optimize data size**: Limit the number of data points for smooth animations
3. **Choose efficient themes**: Minimal themes perform better than complex ones
4. **Cache theme objects**: Reuse theme instances across multiple charts

## 📚 Documentation

- [📖 Full Documentation](docs/readme.md) - Complete documentation index
- [🎨 Comprehensive Theming Guide](docs/features/theming.md) - Detailed theming documentation
- [📈 Advanced Trendlines Guide](docs/features/trendlines.md) - Mathematical curve fitting and statistical analysis
- [📝 **NEW** Annotations System Guide](docs/features/annotations.md) - **v0.3.0** Composition-based annotation styling
- [🔄 **NEW** Migration Guide](docs/guides/migration.md) - **v0.3.0** Upgrade from older annotation API
- [⚡ **NEW** Performance Guide](docs/guides/performance.md) - **v0.3.0** Optimization best practices
- [📋 User Guides](docs/guides/) - Screenshots and usage tutorials
- [📊 Examples](example/) - Sample implementations and use cases
- [🔧 API Reference](https://pub.dev/documentation/braven_charts/latest/) - Complete API documentation

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](contributing.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Pub.dev Package](https://pub.dev/packages/braven_charts)
- [GitHub Repository](https://github.com/your-repo/braven_charts)
- [Issue Tracker](https://github.com/your-repo/braven_charts/issues)
- [Documentation](https://github.com/your-repo/braven_charts/wiki)

---

Made with ❤️ by the Braven Charts team
