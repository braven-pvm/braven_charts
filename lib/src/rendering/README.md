# Core Rendering Engine

High-performance, layer-based rendering system for Braven Charts with object pooling, viewport culling, and text caching.

## Overview

The Core Rendering Engine (002-core-rendering) provides a complete rendering pipeline for creating performant chart visualizations with:

- **Layer-based architecture**: Compose visualizations from independent layers (grid, data, annotations)
- **Object pooling**: Reuse Paint, Path, and TextPainter objects to eliminate allocations
- **Viewport culling**: Render only visible data points for large datasets
- **Text caching**: Cache pre-laid-out text to avoid redundant measurement
- **Performance monitoring**: Real-time frame timing and jank detection

**Performance Targets**: <8ms avg frame time, <16ms p99, >90% pool hit rate, >70% text cache hit rate

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/src/foundation/foundation.dart';
import 'package:braven_charts/src/rendering/rendering.dart';

class ChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartPainter(),
      size: Size(800, 600),
    );
  }
}

class ChartPainter extends CustomPainter {
  final RenderPipeline pipeline = _createPipeline();

  static RenderPipeline _createPipeline() {
    // Create infrastructure
    final paintPool = ObjectPool<Paint>(
      factory: () => Paint(),
      reset: (p) => p.color = Colors.black,
    );

    final pathPool = ObjectPool<Path>(
      factory: () => Path(),
      reset: (p) => p.reset(),
    );

    final textPainterPool = ObjectPool<TextPainter>(
      factory: () => TextPainter(),
      reset: (tp) {},
    );

    // Create pipeline
    final pipeline = RenderPipeline(
      paintPool: paintPool,
      pathPool: pathPool,
      textPainterPool: textPainterPool,
      textCache: LinkedHashMapTextLayoutCache(),
      performanceMonitor: StopwatchPerformanceMonitor(),
      culler: const ViewportCuller(),
      initialViewport: Rect.fromLTWH(0, 0, 800, 600),
    );

    // Add layers (background to foreground)
    pipeline.addLayer(GridLayer(zIndex: -1));
    pipeline.addLayer(DataSeriesLayer(
      dataPoints: _generateData(),
      dataBounds: Rect.fromLTRB(0, 0, 100, 100),
      lineColor: Colors.blue,
      lineWidth: 2.0,
      zIndex: 0,
    ));
    pipeline.addLayer(AnnotationLayer(zIndex: 1));

    return pipeline;
  }

  @override
  void paint(Canvas canvas, Size size) {
    pipeline.renderFrame(canvas, size);

    // Optional: Check performance
    final metrics = pipeline.getMetrics();
    print('Frame time: ${metrics.frameTimeMs.toStringAsFixed(1)}ms');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

## Architecture

### Layer System

Layers render in z-order (lowest to highest). Common pattern:

1. **Background layers** (zIndex < 0): Grid, axes
2. **Primary layers** (zIndex = 0): Data series, bars, scatter points
3. **Overlay layers** (zIndex > 0): Annotations, tooltips, legends

### RenderContext

Dependency injection container providing layers with:

- Canvas and viewport for drawing
- Object pools (Paint, Path, TextPainter)
- Text layout cache
- Viewport culler
- Performance monitor

### Performance Optimization

#### Object Pooling

```dart
// Acquire from pool, use, release
final paint = context.paintPool.acquire();
try {
  paint.color = Colors.blue;
  context.canvas.drawRect(rect, paint);
} finally {
  context.paintPool.release(paint);
}
```

#### Viewport Culling

```dart
// Filter visible points before rendering
final visiblePoints = context.culler.filterVisiblePoints(
  allPoints,
  context.viewport,
  dataBounds,
);

for (final point in visiblePoints) {
  // Render only visible points
}
```

#### Text Caching

```dart
// Check cache before layout
var painter = context.textCache.get(text, style);
if (painter == null) {
  painter = context.textPainterPool.acquire();
  painter.text = TextSpan(text: text, style: style);
  painter.textDirection = TextDirection.ltr;
  painter.layout();
  context.textCache.put(text, style, painter);
}
painter.paint(context.canvas, offset);
```

## Implementation Guide

### Creating a Custom Layer

```dart
class MyCustomLayer implements RenderLayer {
  @override
  final int zIndex;

  @override
  bool isVisible = true;

  MyCustomLayer({required this.zIndex});

  @override
  bool get isEmpty => false;  // Return true to skip rendering

  @override
  void render(RenderContext context) {
    // Use object pools for zero allocations
    final paint = context.paintPool.acquire();
    final path = context.pathPool.acquire();

    try {
      // Draw your visualization
      paint.color = Colors.red;
      path.moveTo(0, 0);
      path.lineTo(100, 100);
      context.canvas.drawPath(path, paint);
    } finally {
      // Always release back to pool
      context.paintPool.release(paint);
      context.pathPool.release(path);
    }
  }
}
```

### Performance Monitoring

```dart
// Get frame metrics
final metrics = pipeline.getMetrics();

print('Frame time: ${metrics.frameTimeMs}ms');
print('Layers rendered: ${metrics.layersRendered}');
print('Points culled: ${metrics.pointsCulled}');
print('Jank frames: ${metrics.jankFrameCount}');

// Check statistics
final paintStats = paintPool.statistics;
print('Paint pool hit rate: ${(paintStats.hitRate * 100).toStringAsFixed(1)}%');

final cacheStats = textCache.hitRate;
print('Text cache hit rate: ${(cacheStats * 100).toStringAsFixed(1)}%');
```

### Viewport Management

```dart
// Pan viewport
pipeline.updateViewport(Rect.fromLTWH(100, 50, 800, 600));

// Zoom viewport
pipeline.updateViewport(Rect.fromLTWH(0, 0, 400, 300));  // 2x zoom

// Reset to initial viewport
pipeline.updateViewport(Rect.fromLTWH(0, 0, 800, 600));
```

## Validation

Run tests to verify implementation:

```bash
# Contract tests
flutter test test/contract/rendering/

# Unit tests
flutter test test/unit/rendering/

# Integration tests
flutter test test/integration/rendering/

# Performance benchmarks
flutter test test/benchmarks/rendering/

# Edge cases
flutter test test/unit/rendering/edge_cases/
```

Expected results:
- All contract tests pass (API compliance)
- All unit tests pass (component behavior)
- All integration tests pass (end-to-end scenarios)
- Benchmarks meet performance targets (<8ms avg, <16ms p99)
- Edge cases handled gracefully (no crashes)

## Related Documentation

- **Contracts**: [specs/002-core-rendering/contracts/](../../specs/002-core-rendering/contracts/)
- **Data Model**: [specs/002-core-rendering/data_model.md](../../specs/002-core-rendering/data_model.md)
- **Spec**: [specs/002-core-rendering/spec.md](../../specs/002-core-rendering/spec.md)
- **Quickstart**: [specs/002-core-rendering/quickstart.md](../../specs/002-core-rendering/quickstart.md)
- **Foundation Layer**: [lib/src/foundation/](../foundation/)

## Performance Targets (NFRs)

| Metric | Target | Validation |
|--------|--------|------------|
| Avg frame time | <8ms | test/benchmarks/rendering/render_pipeline_benchmark.dart |
| P99 frame time | <16ms | test/benchmarks/rendering/render_pipeline_benchmark.dart |
| Paint pool hit rate | >90% | test/benchmarks/rendering/object_pool_benchmark.dart |
| Text cache hit rate | >70% | test/benchmarks/rendering/text_cache_benchmark.dart |
| Viewport culling | <3ms for 10K points | test/benchmarks/rendering/viewport_culling_benchmark.dart |
| Layer sorting overhead | <0.1ms per layer | test/benchmarks/rendering/layer_sorting_benchmark.dart |
| isEmpty optimization | >1.5x speedup | test/benchmarks/rendering/empty_layer_benchmark.dart |

## Constitutional Compliance

✅ **Zero External Dependencies**: Only Dart stdlib and Flutter SDK  
✅ **TDD**: Comprehensive test coverage (contracts, unit, integration, benchmarks, edge cases)  
✅ **Performance**: All NFRs validated via benchmarks  
✅ **Immutability**: RenderContext recreated per frame  
✅ **Resource Management**: Object pools prevent allocations  

## Example Layers

Three example layer implementations demonstrate patterns:

- **GridLayer** (`lib/src/rendering/layers/grid_layer.dart`): Background grid, always renders
- **DataSeriesLayer** (`lib/src/rendering/layers/data_series_layer.dart`): Line chart with viewport culling
- **AnnotationLayer** (`lib/src/rendering/layers/annotation_layer.dart`): Text labels with caching

Use these as templates for custom layers.

---

**Next Steps**: Explore contracts for detailed API requirements, or see quickstart.md for more examples.
