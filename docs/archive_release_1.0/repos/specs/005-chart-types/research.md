# Phase 0: Research & Technical Decisions

**Feature**: Chart Types (Layer 4)  
**Date**: 2025-10-06  
**Status**: Complete

---

## Research Overview

This document consolidates technical research for implementing four core chart types (Line, Area, Bar, Scatter) as RenderLayers. All unknowns from the Technical Context have been resolved through research into chart rendering algorithms, interpolation methods, and animation patterns.

---

## 1. Chart Architecture Pattern

### Decision: Chart Types as RenderLayers

**Rationale**:
- **Composability**: Each chart type implements the RenderLayer interface from the Core Rendering Engine, enabling multiple chart types to coexist in a single RenderPipeline
- **Z-ordering**: Charts can layer on top of each other with proper depth sorting
- **Performance**: Shared optimizations (object pooling, viewport culling) apply to all chart types
- **Consistency**: All charts have the same lifecycle (prepare, render, dispose)

**Implementation**:
```dart
// Base class for all chart implementations
abstract class ChartLayer extends RenderLayer {
  final List<ChartSeries> series;
  final ChartTheme theme;
  
  @override
  void render(Canvas canvas, Size size, RenderContext context);
  
  @override
  bool shouldRender(RenderContext context) => series.isNotEmpty;
}

// Concrete implementations
class LineChartLayer extends ChartLayer { /* ... */ }
class AreaChartLayer extends ChartLayer { /* ... */ }
class BarChartLayer extends ChartLayer { /* ... */ }
class ScatterChartLayer extends ChartLayer { /* ... */ }
```

**Alternatives Considered**:
- **Option 1**: Separate widget hierarchy for each chart type
  - ❌ Rejected: More boilerplate, harder to compose, duplicates rendering infrastructure
- **Option 2**: Single Chart class with type parameter
  - ❌ Rejected: Violates Single Responsibility Principle, harder to test, complex implementation
  
---

## 2. Line Rendering Algorithms

### Decision: Three Line Styles with Bezier Interpolation

**Rationale**:
- **Straight lines**: Simple linear interpolation (Canvas.drawLine), fastest rendering
- **Smooth curves**: Catmull-Rom spline converted to cubic bezier curves for visually pleasing smoothness
- **Stepped lines**: Constant value interpolation (horizontal then vertical segments) for discrete data

**Smooth Line Implementation** (Catmull-Rom to Bezier):
```dart
// Catmull-Rom spline: passes through all points with smooth curves
// Convert to cubic bezier for Canvas.drawPath compatibility
Path createSmoothLinePath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  
  path.moveTo(points[0].dx, points[0].dy);
  
  for (int i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];
    
    // Catmull-Rom to Bezier control points
    final cp1 = Offset(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
    );
    final cp2 = Offset(
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
    );
    
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
  }
  
  return path;
}
```

**Performance Optimization**:
- Cache computed path when data doesn't change
- Use viewport culling to exclude off-screen segments
- Simplify bezier curves for zoomed-out views (Douglas-Peucker algorithm)

**Alternatives Considered**:
- **B-splines**: More control but don't pass through data points (user expectation violated)
- **Hermite splines**: Similar to Catmull-Rom but require tangent specification (more complex API)

---

## 3. Marker Shape Rendering

### Decision: Six Marker Shapes with Object Pooling

**Shapes**: Circle, Square, Triangle, Diamond, Cross, Plus

**Rationale**:
- **Distinctiveness**: 6 shapes provide clear visual differentiation for multi-series charts
- **Performance**: Pre-computed paths stored in ObjectPool, reused per marker type
- **Simplicity**: All shapes can be drawn with Canvas.drawPath or Canvas.drawCircle

**Implementation**:
```dart
enum MarkerShape { circle, square, triangle, diamond, cross, plus }

class MarkerRenderer {
  final ObjectPool<Path> _pathPool;
  
  void drawMarker(Canvas canvas, Offset position, MarkerShape shape, double size, Paint paint) {
    switch (shape) {
      case MarkerShape.circle:
        canvas.drawCircle(position, size / 2, paint);
        break;
      case MarkerShape.square:
        final rect = Rect.fromCenter(center: position, width: size, height: size);
        canvas.drawRect(rect, paint);
        break;
      case MarkerShape.triangle:
        final path = _getTrianglePath(position, size);
        canvas.drawPath(path, paint);
        _pathPool.release(path);
        break;
      // ... diamond, cross, plus
    }
  }
  
  Path _getTrianglePath(Offset center, double size) {
    final path = _pathPool.acquire() ?? Path();
    path.reset();
    final h = size * 0.866; // sqrt(3)/2 for equilateral triangle
    path.moveTo(center.dx, center.dy - h / 2);
    path.lineTo(center.dx - size / 2, center.dy + h / 2);
    path.lineTo(center.dx + size / 2, center.dy + h / 2);
    path.close();
    return path;
  }
}
```

**Performance**: Object pooling reduces allocations from O(markers) to O(marker_types) = 6 paths

---

## 4. Area Chart Fill Rendering

### Decision: Gradient Shaders with Caching

**Fill Styles**: Solid color, Linear gradient (vertical/horizontal), Custom pattern

**Rationale**:
- **Solid fills**: Simplest, use Paint with solid color
- **Gradients**: Visually appealing, use Paint with Gradient shader
- **Patterns**: Future extension point (not in initial implementation)

**Gradient Implementation**:
```dart
class AreaFillRenderer {
  final Map<String, Shader> _shaderCache = {};
  
  Paint createFillPaint(AreaFillStyle style, Rect bounds, ChartTheme theme) {
    final paint = Paint();
    
    switch (style) {
      case AreaFillStyle.solid:
        paint.color = theme.series.colors[0].withOpacity(style.opacity);
        break;
        
      case AreaFillStyle.gradient:
        final cacheKey = '${style.gradientStart}_${style.gradientEnd}_${bounds.hashCode}';
        final shader = _shaderCache.putIfAbsent(cacheKey, () {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [style.gradientStart, style.gradientEnd],
          ).createShader(bounds);
        });
        paint.shader = shader;
        break;
    }
    
    return paint;
  }
}
```

**Performance**: Shader caching prevents recreation on every frame (expensive operation)

---

## 5. Bar Chart Positioning

### Decision: Two Grouping Modes with Configurable Spacing

**Modes**: Grouped (side-by-side), Stacked (cumulative)

**Rationale**:
- **Grouped**: Compare same category across series (e.g., sales by region per quarter)
- **Stacked**: Show total and composition (e.g., total sales with breakdown by product)

**Grouped Bar Algorithm**:
```dart
class BarPositioner {
  List<Rect> calculateGroupedBars({
    required List<ChartSeries> series,
    required int categoryIndex,
    required double categoryWidth,
    required double barWidth,
    required double spacing,
    required double baseline,
  }) {
    final bars = <Rect>[];
    final numSeries = series.length;
    final totalBarWidth = barWidth * numSeries + spacing * (numSeries - 1);
    final startX = categoryWidth * categoryIndex + (categoryWidth - totalBarWidth) / 2;
    
    for (int i = 0; i < numSeries; i++) {
      final x = startX + i * (barWidth + spacing);
      final value = series[i].points[categoryIndex].y;
      final y = value >= 0 ? baseline - value : baseline;
      final height = value.abs();
      
      bars.add(Rect.fromLTWH(x, y, barWidth, height));
    }
    
    return bars;
  }
}
```

**Stacked Bar Algorithm**:
```dart
List<Rect> calculateStackedBars({
  required List<ChartSeries> series,
  required int categoryIndex,
  required double categoryWidth,
  required double barWidth,
  required double baseline,
}) {
  final bars = <Rect>[];
  double cumulativeTop = baseline;
  double cumulativeBottom = baseline;
  
  for (final s in series) {
    final value = s.points[categoryIndex].y;
    if (value >= 0) {
      final y = cumulativeTop - value;
      bars.add(Rect.fromLTWH(x, y, barWidth, value));
      cumulativeTop = y;
    } else {
      bars.add(Rect.fromLTWH(x, cumulativeBottom, barWidth, value.abs()));
      cumulativeBottom += value.abs();
    }
  }
  
  return bars;
}
```

---

## 6. Animation System for Data Updates

### Decision: Diff-Based Lerp Animation

**Rationale**:
- **Smoothness**: Linear interpolation (lerp) between old and new values
- **Efficiency**: Only animate changed data points (diff algorithm)
- **Performance**: Maintain 60 FPS during transitions

**Implementation**:
```dart
class ChartAnimationController {
  List<ChartDataPoint> _oldData = [];
  List<ChartDataPoint> _newData = [];
  double _animationProgress = 0.0;
  
  void updateData(List<ChartDataPoint> newData, {Duration duration = const Duration(milliseconds: 300)}) {
    _oldData = _currentData;
    _newData = newData;
    _animationProgress = 0.0;
    
    // Animate from 0.0 to 1.0 over duration
    AnimationController(vsync: this, duration: duration)
      ..addListener(() {
        _animationProgress = animation.value;
        markNeedsRender();
      })
      ..forward();
  }
  
  List<ChartDataPoint> get _currentData {
    if (_animationProgress >= 1.0) return _newData;
    
    // Lerp between old and new data
    return List.generate(_newData.length, (i) {
      final oldPoint = i < _oldData.length ? _oldData[i] : _newData[i];
      final newPoint = _newData[i];
      
      return ChartDataPoint(
        x: lerpDouble(oldPoint.x, newPoint.x, _animationProgress)!,
        y: lerpDouble(oldPoint.y, newPoint.y, _animationProgress)!,
      );
    });
  }
}
```

**Optimization**: Skip animation if disabled (real-time dashboards) or duration is zero

---

## 7. Viewport Culling Integration

### Decision: Reuse Foundation's ViewportCuller

**Rationale**:
- Foundation Layer already provides ViewportCuller for performance
- No need to reimplement - just call `culler.cullPoints(points, viewport)`
- <1ms overhead for 10K points (constitutional requirement)

**Integration**:
```dart
class LineChartLayer extends ChartLayer {
  final ViewportCuller _culler = ViewportCuller();
  
  @override
  void render(Canvas canvas, Size size, RenderContext context) {
    for (final series in this.series) {
      // Transform data to screen coordinates
      final screenPoints = series.points.map((p) => 
        context.transformer.dataToScreen(p)
      ).toList();
      
      // Cull off-screen points
      final visiblePoints = _culler.cullPoints(screenPoints, context.viewport);
      
      // Render only visible points
      _renderLine(canvas, visiblePoints, series.style);
    }
  }
}
```

**Performance**: Viewport culling reduces rendering from O(total_points) to O(visible_points)

---

## 8. Theme Integration

### Decision: Automatic Theme Application from SeriesTheme

**Rationale**:
- Theming System (Layer 3) already provides SeriesTheme with colors, line widths, marker sizes
- Charts automatically apply theme styling unless overridden
- No manual color management needed

**Implementation**:
```dart
class LineChartLayer extends ChartLayer {
  @override
  void render(Canvas canvas, Size size, RenderContext context) {
    for (int i = 0; i < series.length; i++) {
      final s = series[i];
      final seriesTheme = context.theme.series;
      
      // Cycle through theme colors if more series than colors
      final color = s.style?.color ?? seriesTheme.colors[i % seriesTheme.colors.length];
      final lineWidth = s.style?.lineWidth ?? seriesTheme.lineWidths[i % seriesTheme.lineWidths.length];
      
      final paint = Paint()
        ..color = color
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke;
        
      _renderLine(canvas, s.points, paint);
    }
  }
}
```

---

## 9. Performance Benchmarking Strategy

### Decision: Automated Frame Time Measurements

**Benchmark Tests**:
- Line Chart: 10,000 points, 3 styles (straight, smooth, stepped)
- Area Chart: 10,000 points, 3 fill styles (solid, gradient, pattern)
- Bar Chart: 1,000 bars, 2 modes (grouped, stacked)
- Scatter Chart: 10,000 points, 6 marker shapes

**Implementation**:
```dart
testPerformance('Line chart renders 10K points in <16ms', () {
  final series = ChartSeries(
    id: 'test',
    points: List.generate(10000, (i) => ChartDataPoint(x: i.toDouble(), y: sin(i / 100))),
  );
  
  final layer = LineChartLayer(series: [series]);
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final context = RenderContext(/* ... */);
  
  final stopwatch = Stopwatch()..start();
  layer.render(canvas, Size(1920, 1080), context);
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(16), 
    reason: '60 FPS requires <16ms frame time');
});
```

---

## 10. Testing Strategy

### Test Coverage Plan:

**Contract Tests** (enforce interface compliance):
- All chart layers implement RenderLayer correctly
- All configs validate properly (throw on invalid values)
- All chart types integrate with RenderPipeline

**Unit Tests** (algorithm correctness):
- Bezier interpolation produces smooth curves
- Bar positioning algorithm calculates correct rectangles
- Stacking algorithm handles negative values
- Marker rendering draws correct shapes
- Viewport culling identifies visible points

**Integration Tests** (layer interaction):
- Multi-series rendering with distinct colors from theme
- Coordinate transformations applied correctly
- Animations maintain 60 FPS
- Theme changes apply without recreation

**Performance Benchmarks** (constitutional compliance):
- Line/Area: <16ms for 10K points
- Bar: <16ms for 1K bars  
- Scatter: <16ms for 10K points
- Viewport culling: <1ms overhead
- Object pooling: >90% hit rate

**Visual Regression Tests** (UI consistency):
- Golden tests for all chart types
- All line styles, fill styles, marker shapes
- Grouped vs stacked bars
- Edge cases (empty data, single point, negative values)

---

## Summary

All technical unknowns resolved. Implementation approach:

1. **Architecture**: Chart types as RenderLayers for composability
2. **Line Rendering**: Catmull-Rom to Bezier for smooth curves, straight/stepped for other styles
3. **Markers**: 6 shapes with object pooling
4. **Area Fills**: Gradient shaders with caching
5. **Bar Positioning**: Grouped/stacked algorithms with configurable spacing
6. **Animation**: Diff-based lerp for smooth data updates
7. **Performance**: Viewport culling, object pooling, shader caching
8. **Theme Integration**: Automatic from SeriesTheme
9. **Testing**: Contract, unit, integration, performance, visual regression

Ready for Phase 1: Design & Contracts.
