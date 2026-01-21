# Research: Universal Coordinate System

**Feature**: 003-coordinate-system  
**Date**: 2025-10-05  
**Status**: Complete

---

## Research Tasks

This research phase investigated the optimal approach for implementing a centralized coordinate transformation system that eliminates v1.0's scattered transformation logic.

---

## R1: Coordinate Transformation Strategies

### Decision
Use **affine transformation matrices (3x3)** for all coordinate transformations with per-context caching.

### Rationale
1. **Composability**: Zoom, pan, and scale transformations can be combined through matrix multiplication
2. **Performance**: Single matrix application vs multiple sequential calculations
3. **Correctness**: Well-established mathematical foundation prevents edge case bugs
4. **Reversibility**: Matrix inversion provides exact bidirectional transformations
5. **SIMD-friendly**: Matrix operations vectorize efficiently with Float32x4

### Alternatives Considered

**Option A: Direct Calculation Per Transformation**
```dart
// Data to Screen: Calculate directly
double dataToScreenX(double dataX) {
  final range = xMax - xMin;
  final normalized = (dataX - xMin) / range;
  return chartArea.left + normalized * chartArea.width;
}
```
- ❌ **Rejected**: Doesn't compose for zoom/pan; each transformation duplicates logic
- ❌ **Rejected**: Requires separate reverse transformation implementation
- ❌ **Rejected**: Harder to optimize batch operations

**Option B: Functional Composition Pipeline**
```dart
final dataToScreen = compose([
  dataToNormalized,
  normalizedToChartArea,
  chartAreaToScreen,
]);
```
- ✅ Composable and testable
- ❌ **Rejected**: Function call overhead for each transformation step
- ❌ **Rejected**: Harder to cache intermediate results

**Option C: Affine Transformation Matrices** ✅ **SELECTED**
```dart
class TransformMatrix {
  final Float32List _values; // 3x3 matrix in column-major order
  
  Point<double> transform(Point<double> point) {
    // Apply affine transformation: [x', y', 1] = M × [x, y, 1]
    final x = point.x * _values[0] + point.y * _values[3] + _values[6];
    final y = point.x * _values[1] + point.y * _values[4] + _values[7];
    return Point(x, y);
  }
  
  TransformMatrix operator *(TransformMatrix other) {
    // Matrix multiplication for composition
  }
  
  TransformMatrix inverse() {
    // Matrix inversion for bidirectional transforms
  }
}
```
- ✅ **Selected**: Composable via matrix multiplication
- ✅ **Selected**: Single operation for complex transformations
- ✅ **Selected**: Exact bidirectional transforms via inversion
- ✅ **Selected**: SIMD-optimizable with Float32x4

### Implementation Notes
- Use column-major order for Flutter/GLSL compatibility
- Cache matrices per TransformContext hash (viewport + data ranges + chart bounds)
- Invalidate cache on context changes (user zoom/pan)
- For batch transformations, compute matrix once, apply many times

---

## R2: Context Management Pattern

### Decision
Use **immutable TransformContext** passed explicitly to all transformation methods (no global state).

### Rationale
1. **Testability**: Pure functions easy to unit test without setup/teardown
2. **Concurrency**: No race conditions from shared mutable state
3. **Predictability**: Same input always produces same output
4. **Debuggability**: Full context visible in stack traces
5. **Matches Foundation Layer**: Follows established immutability patterns

### Alternatives Considered

**Option A: Global Singleton State**
```dart
class CoordinateTransformer {
  static ChartBounds? currentBounds;
  static DataRange? currentXRange;
  static DataRange? currentYRange;
  
  Point<double> transform(Point<double> point, ...) {
    // Use global state
  }
}
```
- ❌ **Rejected**: Hard to test (requires global setup/teardown)
- ❌ **Rejected**: Race conditions in multi-chart scenarios
- ❌ **Rejected**: Implicit dependencies hide data flow

**Option B: Mutable Context Object**
```dart
class TransformContext {
  ChartBounds bounds; // Mutable
  DataRange xRange;   // Mutable
  
  void updateBounds(ChartBounds newBounds) {
    bounds = newBounds;
    _invalidateCache();
  }
}
```
- ✅ Allows incremental updates
- ❌ **Rejected**: Mutable state complicates testing
- ❌ **Rejected**: Violates Foundation Layer immutability principle
- ❌ **Rejected**: Cache invalidation logic error-prone

**Option C: Immutable Context with `withX()` Methods** ✅ **SELECTED**
```dart
class TransformContext {
  final Size widgetSize;
  final Rect chartAreaBounds;
  final DataRange xDataRange;
  final DataRange yDataRange;
  final ViewportState viewport;
  // ... all fields final
  
  const TransformContext({...});
  
  TransformContext withViewport(ViewportState newViewport) {
    return TransformContext(
      widgetSize: widgetSize,
      chartAreaBounds: chartAreaBounds,
      // ... copy other fields
      viewport: newViewport, // Updated field
    );
  }
}
```
- ✅ **Selected**: Immutable, pure functions
- ✅ **Selected**: Easy to test (construct context, call transform)
- ✅ **Selected**: Matches Foundation Layer patterns
- ✅ **Selected**: Clear data flow (context passed explicitly)

### Implementation Notes
- Context hashing for cache keys: hash(chartAreaBounds, xDataRange, yDataRange, viewport, devicePixelRatio)
- Provide convenience constructors: `TransformContext.fromRenderContext(RenderContext)`
- Store in RenderContext for access during rendering pipeline

---

## R3: Performance Optimization Techniques

### Decision
Implement **multi-tier caching** with SIMD batch transformations and viewport culling integration.

### Rationale
1. **Matrix caching**: Avoid recomputing matrices per frame (90%+ cache hit rate expected)
2. **SIMD batch ops**: Process 4 points simultaneously with Float32x4
3. **Viewport culling**: Skip transformations for off-screen points
4. **Zero allocations**: Reuse Point objects from Foundation Layer ObjectPool

### Research Findings

**Benchmark Target**: <1ms for 10,000 point transformation

**Optimization 1: Matrix Caching**
```dart
class CachedCoordinateTransformer {
  final Map<int, TransformMatrix> _cache = {};
  
  Point<double> transform(Point<double> point, ..., TransformContext ctx) {
    final cacheKey = _hashContext(ctx, from, to);
    final matrix = _cache[cacheKey] ??= _buildMatrix(from, to, ctx);
    return matrix.transform(point);
  }
}
```
- **Expected hit rate**: >90% during typical usage (stable viewport, frame-to-frame)
- **Invalidation**: Clear cache on context hash change

**Optimization 2: SIMD Batch Transformations**
```dart
List<Point<double>> transformBatch(
  List<Point<double>> points,
  CoordinateSystem from,
  CoordinateSystem to,
  TransformContext context,
) {
  final matrix = _getOrBuildMatrix(from, to, context);
  
  // Process 4 points at a time with SIMD
  for (var i = 0; i < points.length; i += 4) {
    final x = Float32x4(
      points[i].x,
      points[i + 1].x,
      points[i + 2].x,
      points[i + 3].x,
    );
    final y = Float32x4(
      points[i].y,
      points[i + 1].y,
      points[i + 2].y,
      points[i + 3].y,
    );
    
    // Apply matrix transformation in parallel
    final xPrime = x * matrix.m00 + y * matrix.m01 + matrix.tx;
    final yPrime = x * matrix.m10 + y * matrix.m11 + matrix.ty;
    
    // Extract results
    results[i] = Point(xPrime.x, yPrime.x);
    results[i + 1] = Point(xPrime.y, yPrime.y);
    results[i + 2] = Point(xPrime.z, yPrime.z);
    results[i + 3] = Point(xPrime.w, yPrime.w);
  }
  
  // Handle remainder (< 4 points)
  // ...
}
```
- **Expected speedup**: 2-3x over sequential processing
- **Dart support**: Float32x4 available in dart:typed_data

**Optimization 3: Viewport Culling Integration**
```dart
List<Point<double>> transformVisiblePoints(
  List<Point<double>> dataPoints,
  TransformContext context,
) {
  // Pre-cull in data space (cheap)
  final visibleDataPoints = context.culler.cullPoints(
    dataPoints,
    context.viewport.dataRange,
  );
  
  // Transform only visible points (expensive)
  return transformBatch(
    visibleDataPoints,
    CoordinateSystem.data,
    CoordinateSystem.screen,
    context,
  );
}
```
- **Expected reduction**: 50-90% fewer transformations when zoomed

**Optimization 4: Zero-Allocation Transformations**
```dart
void transformInPlace(
  List<Point<double>> points, // Mutable list from ObjectPool
  CoordinateSystem from,
  CoordinateSystem to,
  TransformContext context,
) {
  final matrix = _getOrBuildMatrix(from, to, context);
  
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final x = p.x * matrix.m00 + p.y * matrix.m01 + matrix.tx;
    final y = p.x * matrix.m10 + p.y * matrix.m11 + matrix.ty;
    points[i] = Point(x, y); // Reuse Point from pool
  }
}
```
- **Expected allocations**: Zero in steady-state rendering

### Implementation Notes
- Profile with Flutter DevTools to verify <1ms batch transformation
- Use PerformanceMonitor from Core Rendering to track transformation time
- Benchmark cache hit rate during typical user interactions (pan, zoom, hover)
- Memory profiler to verify zero allocations in rendering loop

---

## R4: Validation Strategy

### Decision
Implement **progressive validation** with three levels: compile-time (type system), runtime (bounds checking), and debug-mode (assertions).

### Rationale
1. **Type safety**: Prevent coordinate system mismatches at compile time
2. **Runtime safety**: Catch invalid values (NaN, infinity) before rendering
3. **Actionable errors**: Help developers fix issues quickly
4. **Performance**: Validation overhead only in debug mode for hot paths

### Validation Levels

**Level 1: Compile-Time Type Safety**
```dart
// Future enhancement: Typed coordinate classes
class DataPoint { final double x, y; }
class ScreenPoint { final double x, y; }

Point<ScreenPoint> transform(
  Point<DataPoint> point,
  TransformContext context,
); // Type mismatch caught by compiler
```
- **Current implementation**: Use enums + runtime checks (simpler for v1)
- **Future enhancement**: Typed wrappers for compile-time safety

**Level 2: Runtime Validation**
```dart
ValidationResult validate(
  Point<double> point,
  CoordinateSystem system,
  TransformContext context,
) {
  // Check for NaN/infinity
  if (point.x.isNaN || point.x.isInfinite || 
      point.y.isNaN || point.y.isInfinite) {
    return ValidationResult.invalid(
      'Point ($point.x, $point.y) contains NaN or infinity. '
      'Check data source for invalid calculations.',
      ValidationErrorType.invalidValue,
    );
  }
  
  // Check bounds for specific coordinate system
  final validRange = _getValidRange(system, context);
  if (!validRange.contains(point)) {
    return ValidationResult.invalid(
      'Point ($point.x, $point.y) outside valid range for $system. '
      'Valid range: $validRange. '
      'Hint: Did you mean to use ${_suggestSystem(point)}?',
      ValidationErrorType.outOfRange,
    );
  }
  
  return ValidationResult.valid();
}
```
- **Error messages include**:
  - Actual values (not just "invalid")
  - Expected range
  - Suggested fix (e.g., "Did you mean CoordinateSystem.data?")

**Level 3: Debug Mode Assertions**
```dart
Point<double> transform(...) {
  assert(() {
    final result = validate(point, from, context);
    if (!result.isValid) {
      throw ArgumentError(result.errorMessage);
    }
    return true;
  }());
  
  // Transformation logic (no validation overhead in release mode)
  return _transformUnchecked(point, from, to, context);
}
```
- **Debug mode**: Full validation with stack traces
- **Release mode**: Validation overhead removed by Dart compiler

### Implementation Notes
- Provide `transformer.validateAndTransform()` for explicit validation in user code
- Provide `transformer.transformUnchecked()` for performance-critical paths (after validation)
- Document validation behavior in API docs
- Add validation tests for all error types

---

## R5: Integration with Core Rendering Engine

### Decision
Extend **RenderContext** to include TransformContext and provide convenience transformation methods.

### Rationale
1. **Unified context**: Rendering layers access both canvas and transformations
2. **Consistency**: All rendering uses same transformation logic
3. **Convenience**: Shorthand methods reduce boilerplate
4. **Backward compatibility**: Non-breaking addition to RenderContext

### Integration Pattern

**Extended RenderContext**
```dart
class RenderContext {
  // Existing fields (v0.2.0-rendering)
  final Canvas canvas;
  final Size size;
  final Rect viewport;
  final ViewportCuller culler;
  final ObjectPool<Paint> paintPool;
  final ObjectPool<Path> pathPool;
  final ObjectPool<TextPainter> textPainterPool;
  final TextLayoutCache textCache;
  final PerformanceMonitor performanceMonitor;
  
  // NEW: Coordinate transformation support (v0.3.0)
  final TransformContext transformContext;
  final CoordinateTransformer transformer;
  
  const RenderContext({
    // ... existing parameters
    required this.transformContext,
    required this.transformer,
  });
  
  // NEW: Convenience methods for common transformations
  Point<double> dataToScreen(Point<double> dataPoint) {
    return transformer.transform(
      dataPoint,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: transformContext,
    );
  }
  
  Point<double> screenToData(Point<double> screenPoint) {
    return transformer.transform(
      screenPoint,
      from: CoordinateSystem.screen,
      to: CoordinateSystem.data,
      context: transformContext,
    );
  }
  
  List<Point<double>> dataToScreenBatch(List<Point<double>> dataPoints) {
    return transformer.transformBatch(
      dataPoints,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: transformContext,
    );
  }
}
```

**Usage in RenderLayer**
```dart
class DataSeriesLayer extends RenderLayer {
  final ChartSeries series;
  
  @override
  void render(RenderContext context) {
    // Transform all data points to screen coordinates
    final screenPoints = context.dataToScreenBatch(series.dataPoints);
    
    // Draw line through points
    final path = context.pathPool.obtain();
    path.moveTo(screenPoints[0].x, screenPoints[0].y);
    for (var i = 1; i < screenPoints.length; i++) {
      path.lineTo(screenPoints[i].x, screenPoints[i].y);
    }
    
    final paint = context.paintPool.obtain();
    context.canvas.drawPath(path, paint);
    
    context.pathPool.release(path);
    context.paintPool.release(paint);
  }
}
```

### Migration Strategy
1. **Phase 1**: Add transformContext and transformer as optional parameters to RenderContext
2. **Phase 2**: Update RenderPipeline to construct TransformContext from chart state
3. **Phase 3**: Migrate existing layers to use RenderContext.dataToScreen() instead of manual calculations
4. **Phase 4**: Make transformContext and transformer required (breaking change for v1.0.0)

### Implementation Notes
- RenderContext.transformContext constructed from:
  - widgetSize = RenderContext.size
  - chartAreaBounds = Calculated from size - axes/legend space
  - xDataRange, yDataRange = From chart axes configuration
  - viewport = RenderContext.viewport (already supports zoom/pan)
  - devicePixelRatio = MediaQuery.of(context).devicePixelRatio
- CoordinateTransformer instance shared across all RenderContexts (stateless)
- Cache invalidation: New RenderContext per frame with updated TransformContext

---

## Summary of Research Decisions

| Research Area | Decision | Rationale |
|---------------|----------|-----------|
| **Transformation Strategy** | Affine transformation matrices (3x3) | Composability, performance, correctness |
| **Context Management** | Immutable TransformContext with explicit passing | Testability, predictability, matches Foundation patterns |
| **Performance Optimization** | Multi-tier caching + SIMD + viewport culling | <1ms batch transformation target |
| **Validation Strategy** | Progressive validation (compile-time + runtime + debug) | Safety without performance overhead |
| **Core Rendering Integration** | Extend RenderContext with transformContext + convenience methods | Unified context, backward compatible |

All decisions align with constitutional requirements:
- ✅ Pure Flutter (dart:ui, dart:math, dart:typed_data only)
- ✅ Performance first (<1ms, zero allocations)
- ✅ Testable (pure functions, explicit context)
- ✅ API consistency (matches Foundation + Core Rendering patterns)
- ✅ Well-documented (research rationale captured)

---

**Research Status**: ✅ Complete - Ready for Phase 1 (Design & Contracts)
