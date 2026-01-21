# Migration Guide & API Evolution

## Overview

This migration guide documents the evolution of Braven Charts APIs and provides guidance for upgrading between versions while maintaining backward compatibility.

## API Evolution Strategy

### Backward Compatibility Promise
- **No Breaking Changes**: Major versions maintain full backward compatibility
- **Deprecation Warnings**: Old APIs are deprecated with clear migration paths
- **Gradual Migration**: Developers can upgrade incrementally
- **Documentation**: Complete migration examples for all changes

### Version Strategy
```
v1.0.x - Foundation (Current restart target)
v1.1.x - Performance optimizations
v1.2.x - Additional chart types
v2.0.x - Major API improvements (with migration tools)
```

## API Design Principles

### 1. Progressive Disclosure
```dart
// Simple usage (sensible defaults)
BravenChart(data: myData)

// Advanced usage (full control)
BravenChart(
  data: myData,
  theme: customTheme,
  annotations: annotations,
  interactions: InteractionConfig(
    enableZoom: true,
    enablePan: true,
    crosshairMode: CrosshairMode.followPointer,
  ),
)
```

### 2. Type Safety
```dart
// Strongly typed APIs prevent runtime errors
sealed class ChartData {
  const ChartData();
}

class LineChartData extends ChartData {
  final List<DataPoint> points;
  final LineStyle style;
  
  const LineChartData({required this.points, this.style = LineStyle.default});
}
```

### 3. Composition Over Inheritance
```dart
// Prefer composition
class AnnotationStyle {
  final MarkerStyle? markerStyle;
  final TitleStyle? titleStyle;
  final TooltipStyle? tooltipStyle;
  
  const AnnotationStyle({
    this.markerStyle,
    this.titleStyle,
    this.tooltipStyle,
  });
}

// Avoid deep inheritance hierarchies
```

## Migration Patterns

### Pattern 1: Factory Constructor Migration
```dart
// Old way (deprecated but still works)
AnnotationStyle(
  markerSize: 8.0,
  markerColor: Colors.blue,
  textStyle: TextStyle(fontSize: 12),
)

// New way (recommended)
AnnotationStyle.point(
  markerStyle: MarkerStyle(size: 8.0, color: Colors.blue),
  titleStyle: TitleStyle(style: TextStyle(fontSize: 12)),
)
```

### Pattern 2: Configuration Object Migration
```dart
// Old way (many parameters)
BravenChart(
  data: data,
  enableZoom: true,
  enablePan: true,
  showCrosshair: true,
  crosshairColor: Colors.red,
  // ... 20 more parameters
)

// New way (configuration objects)
BravenChart(
  data: data,
  interactions: InteractionConfig(
    enableZoom: true,
    enablePan: true,
  ),
  crosshair: CrosshairConfig(
    enabled: true,
    color: Colors.red,
  ),
)
```

### Pattern 3: Builder Pattern for Complex Objects
```dart
// Complex annotation creation
final annotation = AnnotationBuilder()
  .id('trend-line-1')
  .type(AnnotationType.trendLine)
  .position(DataPosition(x: 10, y: 20))
  .style(AnnotationStyle.trendLine(
    lineStyle: LineStyle(color: Colors.blue, width: 2.0),
  ))
  .metadata({'equation': 'y = 2x + 1'})
  .build();
```

## Deprecated API Reference

### Deprecated in v0.3.0 (Remove in v1.0.0)
```dart
@Deprecated('Use AnnotationStyle.point() instead')
AnnotationStyle({
  double? markerSize,
  Color? markerColor,
  // ...
})

@Deprecated('Use InteractionConfig instead')
bool enableZoom;

@Deprecated('Use CrosshairConfig instead')
bool showCrosshair;
```

## Future API Considerations

### Planned Enhancements
1. **Streaming Data API**: Real-time data updates
2. **Export API**: PNG, SVG, PDF export capabilities
3. **Accessibility API**: Enhanced screen reader support
4. **Plugin System**: Third-party chart type extensions

### API Stability Guarantees
- **Core APIs**: Stable, no breaking changes
- **Extension APIs**: May evolve with deprecation warnings
- **Experimental APIs**: Clearly marked, may change

This migration strategy ensures smooth upgrades while allowing the API to evolve and improve over time.