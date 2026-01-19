# Quickstart Guide: Core Rendering Engine

**Feature**: 002-core-rendering  
**Audience**: Developers implementing or extending the rendering layer  
**Prerequisites**: Foundation Layer (001-foundation) complete  
**Estimated Time**: 15 minutes to understand, 2-4 weeks to implement

---

## Overview

This guide demonstrates how to use the Core Rendering Engine to create high-performance chart visualizations. You'll learn to:

1. Create a render pipeline with object pooling
2. Implement custom render layers
3. Monitor rendering performance
4. Optimize text rendering with caching

**Performance Targets**: <8ms avg frame time, >90% pool hit rate, >70% text cache hit rate

---

## Quick Start: Minimal Working Example

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/src/foundation/foundation.dart';
import 'package:braven_charts/src/rendering/render_pipeline.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:braven_charts/src/rendering/layers/grid_layer.dart';
import 'package:braven_charts/src/rendering/layers/data_series_layer.dart';
import 'package:braven_charts/src/rendering/layers/annotation_layer.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: CustomPaint(
        painter: ChartPainter(),
        size: Size(800, 600),
      ),
    ),
  ));
}

class ChartPainter extends CustomPainter {
  final RenderPipeline pipeline;

  ChartPainter() : pipeline = _createPipeline();

  static RenderPipeline _createPipeline() {
    // Step 1: Create object pools (from Foundation)
    final paintPool = ObjectPool<Paint>(
      factory: () => Paint(),
      reset: (paint) {
        paint.color = Colors.black;
        paint.strokeWidth = 1.0;
        paint.style = PaintingStyle.fill;
      },
    );

    final pathPool = ObjectPool<Path>(
      factory: () => Path(),
      reset: (path) => path.reset(),
    );

    final textPainterPool = ObjectPool<TextPainter>(
      factory: () => TextPainter(textDirection: TextDirection.ltr),
      reset: (painter) {},
    );

    // Step 2: Create viewport culler (from Foundation)
    final culler = const ViewportCuller();

    // Step 3: Create performance monitor and text cache
    final monitor = StopwatchPerformanceMonitor();
    final textCache = LinkedHashMapTextLayoutCache();

    // Step 4: Create render pipeline
    final pipeline = RenderPipeline(
      paintPool: paintPool,
      pathPool: pathPool,
      textPainterPool: textPainterPool,
      textCache: textCache,
      performanceMonitor: monitor,
      culler: culler,
      initialViewport: Rect.fromLTWH(0, 0, 800, 600),
    );

    // Step 5: Add layers (background to foreground)
    pipeline.addLayer(GridLayer(
      gridLineCount: 10,
      lineColor: const Color(0xFFE0E0E0),
      zIndex: -1,
    )); // Background
    
    pipeline.addLayer(DataSeriesLayer(
      dataPoints: _generateData(),
      dataBounds: Rect.fromLTRB(0, 0, 1000, 100),
      lineColor: Colors.blue,
      lineWidth: 2.0,
      zIndex: 0,
    )); // Primary
    
    pipeline.addLayer(AnnotationLayer(zIndex: 1)); // Foreground

    return pipeline;
  }

  static List<ChartDataPoint> _generateData() {
    return List.generate(
      1000,
      (i) => ChartDataPoint(i.toDouble(), (i * 2.5) % 100),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Render frame through pipeline
    pipeline.renderFrame(canvas, size);

    // Check performance (optional)
    final metrics = pipeline.getMetrics();
    if (metrics.frameTimeMs > 8.0) {
      debugPrint('Performance issue: ${metrics.frameTimeMs.toStringAsFixed(1)}ms');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

## Step-by-Step Tutorial

### Step 1: Implement a Custom Render Layer

```dart
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/foundation/data_models.dart';
import 'package:flutter/material.dart';

/// Custom layer: Renders data points as circles.
class DataSeriesLayer extends RenderLayer {
  final List<ChartDataPoint> dataPoints;
  final Color color;
  final double radius;

  const DataSeriesLayer({
    required this.dataPoints,
    required super.zIndex,
    this.color = Colors.blue,
    this.radius = 3.0,
    super.isVisible,
  });

  @override
  void render(RenderContext context) {
    // Short-circuit if no data
    if (isEmpty) return;

    // Step 1: Cull to visible points (viewport optimization)
    final visiblePoints = context.culler.cullPoints(
      dataPoints,
      context.viewport,
    );

    // Step 2: Acquire pooled Paint object
    final paint = context.paintPool.acquire();
    
    try {
      // Step 3: Configure paint
      paint.color = color;
      paint.style = PaintingStyle.fill;

      // Step 4: Draw visible points only
      for (final point in visiblePoints) {
        context.canvas.drawCircle(
          Offset(point.x, point.y),
          radius,
          paint,
        );
      }
    } finally {
      // Step 5: Release pooled object (critical!)
      context.paintPool.release(paint);
    }
  }

  @override
  bool get isEmpty => dataPoints.isEmpty;
}
```

**Key Points**:
- ✅ **Always acquire from pools**: `context.paintPool.acquire()`
- ✅ **Always release in finally**: `context.paintPool.release(paint)`
- ✅ **Use viewport culling**: `context.culler.cullPoints()`
- ✅ **Short-circuit when empty**: `if (isEmpty) return;`

---

### Step 2: Add Text Rendering with Caching

```dart
class LabelLayer extends RenderLayer {
  final List<String> labels;
  final List<Offset> positions;
  final TextStyle textStyle;

  const LabelLayer({
    required this.labels,
    required this.positions,
    required this.textStyle,
    required super.zIndex,
    super.isVisible,
  });

  @override
  void render(RenderContext context) {
    if (isEmpty) return;

    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final position = positions[i];

      // Step 1: Check cache (fast path)
      var painter = context.textCache.get(label, textStyle);

      // Step 2: Cache miss - compute layout
      if (painter == null) {
        painter = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        painter.layout();
        
        // Step 3: Store in cache for next frame
        context.textCache.put(label, textStyle, painter);
      }

      // Step 4: Paint using cached or fresh painter
      painter.paint(context.canvas, position);
    }

    // Monitor cache effectiveness
    if (context.textCache.hitRate < 0.7) {
      debugPrint('Low text cache hit rate: ${context.textCache.hitRate}');
    }
  }

  @override
  bool get isEmpty => labels.isEmpty;
}
```

**Key Points**:
- ✅ **Check cache first**: `context.textCache.get()`
- ✅ **Cache miss workflow**: layout() → put() → paint()
- ✅ **Monitor hit rate**: Aim for >70%

---

### Step 3: Manage Viewport for Pan/Zoom

```dart
class InteractiveChart extends StatefulWidget {
  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  late RenderPipeline pipeline;
  Offset panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    pipeline = _createPipeline(); // See Quick Start
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      panOffset += details.delta;
      
      // Update viewport (triggers re-culling)
      final newViewport = Rect.fromLTWH(
        -panOffset.dx,
        -panOffset.dy,
        800,
        600,
      );
      pipeline.updateViewport(newViewport);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      child: CustomPaint(
        painter: ChartPainter(pipeline),
        size: Size(800, 600),
      ),
    );
  }
}
```

**Key Points**:
- ✅ **Update viewport on pan/zoom**: `pipeline.updateViewport()`
- ✅ **Viewport changes trigger re-culling**: Only visible elements render
- ✅ **Smooth interaction**: <16ms frame time maintained

---

### Step 4: Monitor and Debug Performance

```dart
class PerformanceDebugLayer extends RenderLayer {
  const PerformanceDebugLayer({super.zIndex = 999}); // Render on top

  @override
  void render(RenderContext context) {
    final metrics = context.performanceMonitor.currentMetrics;

    // Render performance overlay
    final textStyle = TextStyle(
      fontSize: 12,
      color: metrics.meetsTargets ? Colors.green : Colors.red,
      fontWeight: FontWeight.bold,
    );

    final text = '''
Frame: ${metrics.averageFrameTimeMs.toStringAsFixed(2)}ms
P99: ${metrics.p99FrameTimeMs.toStringAsFixed(2)}ms
Jank: ${metrics.jankCount}
Pool Hit: ${(metrics.poolHitRate * 100).toStringAsFixed(1)}%
''';

    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(context.canvas, Offset(10, 10));
  }
}

// Add to pipeline:
pipeline.addLayer(PerformanceDebugLayer());
```

**Key Metrics**:
- ✅ **Average frame time**: Target <8ms
- ✅ **P99 frame time**: Target <16ms
- ✅ **Jank count**: Minimize frames >16ms
- ✅ **Pool hit rate**: Target >90%

---

## Common Patterns

### Pattern 1: Multi-Layer Chart (Grid + Data + Annotations)

```dart
// Background: Grid (z-index -10)
pipeline.addLayer(GridLayer(
  gridLineCount: 10,
  color: Colors.grey.withOpacity(0.3),
  zIndex: -10,
));

// Primary: Data series (z-index 0)
pipeline.addLayer(DataSeriesLayer(
  dataPoints: stockPrices,
  color: Colors.blue,
  zIndex: 0,
));

// Overlay: Trend line (z-index 5)
pipeline.addLayer(TrendLineLayer(
  dataPoints: stockPrices,
  color: Colors.red,
  zIndex: 5,
));

// Foreground: Annotations (z-index 10)
pipeline.addLayer(AnnotationLayer(
  labels: ['Peak', 'Dip'],
  positions: [Offset(400, 100), Offset(600, 500)],
  zIndex: 10,
));
```

**Rendering Order**: Grid → Data → Trend → Annotations (lowest to highest z-index)

---

### Pattern 2: Dynamic Layer Visibility (Legend Toggle)

```dart
// Toggle data series visibility via legend
void toggleSeriesVisibility(DataSeriesLayer layer, bool visible) {
  layer.isVisible = visible; // Mutable field
  // Next frame: pipeline skips invisible layers
}

// Example: Legend checkbox
Checkbox(
  value: layer.isVisible,
  onChanged: (value) => toggleSeriesVisibility(layer, value ?? false),
);
```

---

### Pattern 3: Performance Benchmarking

```dart
void benchmarkRendering() {
  final monitor = pipeline.performanceMonitor;
  monitor.reset(); // Clear history

  // Render 100 frames
  for (int i = 0; i < 100; i++) {
    pipeline.renderFrame(canvas, size);
  }

  // Validate performance
  final metrics = monitor.currentMetrics;
  assert(metrics.averageFrameTime.inMicroseconds < 8000, 'Avg frame time >8ms');
  assert(metrics.p99FrameTime.inMicroseconds < 16000, 'P99 frame time >16ms');
  assert(metrics.poolHitRate > 0.90, 'Pool hit rate <90%');

  print('Benchmark passed: ${metrics.averageFrameTimeMs}ms avg');
}
```

---

## Troubleshooting

### Problem: Frame time exceeds 16ms (jank)

**Symptoms**: Choppy animation, jank counter increasing  
**Diagnosis**:
```dart
final metrics = pipeline.performanceMonitor.currentMetrics;
if (metrics.averageFrameTime.inMicroseconds > 16000) {
  print('Jank detected: ${metrics.averageFrameTimeMs}ms');
}
```

**Solutions**:
1. ✅ **Check pool hit rate**: Low hit rate (<90%) → increase pool sizes
2. ✅ **Profile viewport culling**: Ensure visible elements < 10% of total
3. ✅ **Reduce layer count**: Combine similar layers (e.g., multiple grids → one)
4. ✅ **Optimize isEmpty check**: Fast path for empty layers

---

### Problem: Low text cache hit rate (<70%)

**Symptoms**: Slow text rendering, repeated layout computation  
**Diagnosis**:
```dart
if (pipeline.textCache.hitRate < 0.7) {
  print('Cache hit rate: ${pipeline.textCache.hitRate}');
  print('Cache size: ${pipeline.textCache.length}/${pipeline.textCache.maxSize}');
}
```

**Solutions**:
1. ✅ **Increase cache size**: 500 → 1000 entries
2. ✅ **Check label diversity**: Too many unique labels overwhelm cache
3. ✅ **Precompute common labels**: Axis ticks, legend items (put before render)

---

### Problem: Pool exhaustion (allocation during render)

**Symptoms**: GC pressure, pool statistics show allocations  
**Diagnosis**:
```dart
final stats = pipeline.paintPool.statistics;
if (stats.allocationCount > 0) {
  print('Pool exhausted: ${stats.allocationCount} allocations');
}
```

**Solutions**:
1. ✅ **Increase pool size**: `maxSize: 100 → 200`
2. ✅ **Verify release**: All acquire() calls paired with release()
3. ✅ **Check layer count**: 10+ layers × 10 paints each = 100 pool size minimum

---

## Performance Validation Checklist

Before merging rendering code:

- [ ] **All tests pass**: `flutter test` (expect 100% pass - 62 tests)
- [ ] **Average frame time <8ms**: Run benchmarks, check metrics (500-5000 points)
- [ ] **P99 frame time <16ms**: Verify no outliers or jank
- [ ] **Pool hit rate >90%**: Check paintPool, pathPool, textPainterPool statistics
- [ ] **Text cache hit rate >70%**: If text-heavy chart, verify cache effectiveness
- [ ] **Zero jank in interaction**: Pan/zoom 100px, monitor for frame drops
- [ ] **All acquired objects released**: No pool leaks (acquire count = release count)
- [ ] **Viewport culling effective**: >80% reduction (10K→<2K points rendered)
- [ ] **Imports verified**: All paths correct (`lib/src/rendering/*`, `lib/src/foundation/*`)
- [ ] **Examples compile**: No syntax errors in quickstart code

**Validation Commands**:
```bash
# Run all tests
flutter test

# Run benchmarks
flutter test test/benchmarks/rendering/

# Check specific performance
flutter test test/benchmarks/rendering/render_pipeline_benchmark.dart
flutter test test/benchmarks/rendering/object_pool_benchmark.dart
flutter test test/benchmarks/rendering/text_cache_benchmark.dart
```

---

## Troubleshooting

### Common Issue #1: Import Errors

**Symptom**: `'RenderPipeline' isn't defined` or similar

**Solution**: Verify import paths match implementation:
```dart
// Correct imports (as of 002-core-rendering completion)
import 'package:braven_charts/src/foundation/foundation.dart';  // Foundation exports
import 'package:braven_charts/src/rendering/render_pipeline.dart';
import 'package:braven_charts/src/rendering/render_layer.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:braven_charts/src/rendering/layers/grid_layer.dart';
import 'package:braven_charts/src/rendering/layers/data_series_layer.dart';
import 'package:braven_charts/src/rendering/layers/annotation_layer.dart';
```

### Common Issue #2: Performance Below Target

**Symptom**: Frame time >8ms consistently

**Diagnosis**:
```dart
final metrics = pipeline.getMetrics();
print('Frame time: ${metrics.frameTimeMs}ms');
print('Layers rendered: ${metrics.layersRendered}');
print('Points culled: ${metrics.pointsCulled}');

final paintStats = paintPool.statistics;
print('Paint pool hit rate: ${(paintStats.hitRate * 100).toStringAsFixed(1)}%');
```

**Solutions**:
1. **Low pool hit rate (<90%)**: Increase pool size or reduce concurrent layer count
2. **Low cull rate (<80%)**: Verify viewport culler enabled and viewport set correctly
3. **Too many layers**: Combine layers or use isEmpty optimization
4. **Large text count**: Increase text cache size or reduce unique text/style combinations

### Common Issue #3: Visual Artifacts

**Symptom**: Flickering, z-fighting, or incorrect layer order

**Solution**:
- Ensure unique z-indices for each visual priority
- Verify layer sort is stable (don't mutate zIndex after adding)
- Check viewport intersects canvas bounds
- Verify Paint objects properly reset between uses

### Common Issue #4: Memory Leaks

**Symptom**: Heap grows unbounded, eventual OOM

**Diagnosis**:
```dart
final paintStats = paintPool.statistics;
if (paintStats.acquireCount != paintStats.releaseCount) {
  print('LEAK: ${paintStats.acquireCount - paintStats.releaseCount} Paint objects not released');
}
```

**Solution**:
- Wrap all acquire/release in try-finally blocks
- Verify cache bounded by maxSize (check textCache.length)
- Don't store RenderContext beyond frame scope

---

## Next Steps

1. **Read contracts**: Review `contracts/render_layer.dart` for layer requirements
2. **Study Foundation**: ObjectPool and ViewportCuller in `001-foundation/`
3. **Implement tests**: TDD - write failing tests before implementation
4. **Follow tasks.md**: Sequential task execution (generated by /tasks command)

**Estimated Implementation**: 2-4 weeks following TDD workflow (tests first, then code)

---

## Reference

- **Spec**: `specs/002-core-rendering/spec.md` (FR-001 to FR-005, NFR-001 to NFR-003)
- **Data Model**: `specs/002-core-rendering/data-model.md` (6 entities)
- **Research**: `specs/002-core-rendering/research.md` (6 decisions, 4 ADRs)
- **Foundation**: `specs/001-foundation/` (ObjectPool, ViewportCuller)
- **Constitution**: `.specify/memory/constitution.md` (TDD, Performance First, KISS)
