# Feature Specification: Universal Coordinate System

**Feature ID**: 002-coordinate-system  
**Layer**: 2 (depends on Layer 0: Foundation, Layer 1: Core Rendering)  
**Status**: Draft  
**Created**: 2025-10-05  
**Last Updated**: 2025-10-05

---

## Executive Summary

The Universal Coordinate System provides **type-safe, bidirectional transformations** between the 8 coordinate spaces used throughout BravenCharts. This prevents the coordinate-related bugs that plagued v1.0 and ensures consistency across all chart features (rendering, interactions, annotations).

**Critical Lesson from v1.0**: Ad-hoc coordinate transformations scattered throughout the codebase led to:
- Mismatched hit detection and visual positioning
- Tooltip positioning errors under zoom/pan
- Annotation placement inconsistencies
- Maintenance nightmare (changes required updates in 10+ files)

**Solution**: Centralized, stateless, validated coordinate transformation system with compile-time type safety.

---

## Problem Statement

### User Pain Points
- **Inaccurate interactions**: Clicking on a data point shows tooltip for different point (coordinate mismatch)
- **Annotation drift**: Annotations don't stay anchored to data under zoom/pan
- **Inconsistent behavior**: Same data coordinates render differently in different contexts

### Technical Challenges
- **8 coordinate systems** need bidirectional conversions (8×7 = 56 transformation paths)
- **Context-dependent transformations**: Same point has different meaning in different chart states
- **Performance**: Transform 10,000+ points per frame without allocations
- **Validation**: Detect invalid coordinates before rendering artifacts occur

### v1.0 Failures
- Coordinate logic duplicated in 12+ files (ChartPainter, AnnotationManager, TooltipController, etc.)
- No validation → negative pixel coordinates crashed Canvas API
- Zoom/pan broke because transformations didn't compose correctly
- Hit testing used different logic than rendering → clicks missed targets

---

## Goals & Non-Goals

### Goals ✅
1. **Single Source of Truth**: All coordinate transformations go through one system
2. **Type Safety**: Compile-time prevention of coordinate space errors
3. **Performance**: <1ms for batch transformation of 10K points
4. **Bidirectional**: Any system → any system transformation
5. **Validated**: Automatic bounds checking with actionable errors
6. **Composable**: Zoom/pan/animation transformations stack correctly
7. **Testable**: 100% test coverage with deterministic transforms

### Non-Goals ❌
- 3D transformations (2D charts only)
- Polar coordinate systems (deferred to chart-specific logic)
- Curved coordinate spaces (handled by chart renderers)
- Geographic projections (not a mapping library)

---

## User Scenarios

### Scenario 1: Mouse Click Hit Detection
**User Story**: As a chart user, when I click on a data point, I want the correct tooltip to appear, so I can see accurate data.

**Technical Flow**:
```dart
// 1. User clicks at mouse position (150px, 200px)
final mousePos = Point(150.0, 200.0);

// 2. Transform to data coordinates
final dataPos = transformer.transform(
  mousePos,
  from: CoordinateSystem.mouse,
  to: CoordinateSystem.data,
  context: chartContext,
);

// 3. Find nearest data point
final nearestPoint = findNearestDataPoint(dataPos, series);

// 4. Transform back to screen for tooltip positioning
final tooltipPos = transformer.transform(
  nearestPoint.position,
  from: CoordinateSystem.data,
  to: CoordinateSystem.screen,
  context: chartContext,
);

// 5. Show tooltip at correct position
showTooltip(tooltipPos, nearestPoint.data);
```

**Acceptance Criteria**:
- ✅ Tooltip appears at exact data point location
- ✅ Works correctly under zoom (2x, 10x, 0.1x)
- ✅ Works correctly under pan (any viewport position)
- ✅ Works on all 8 viewport sizes (mobile to ultrawide)

---

### Scenario 2: Annotation Positioning
**User Story**: As a financial analyst, when I add a "peak" annotation to a stock chart, I want it to stay anchored to the data point even when I zoom/pan.

**Technical Flow**:
```dart
// 1. User places annotation at data coordinates (Date('2024-01-15'), 150.50)
final annotation = PointAnnotation(
  dataPosition: Point(dateToTimestamp('2024-01-15'), 150.50),
  text: 'Peak price',
  markerOffset: Point(0, -50), // 50px above data point
);

// 2. During render, transform to marker coordinates
final markerPos = transformer.transform(
  annotation.dataPosition,
  from: CoordinateSystem.data,
  to: CoordinateSystem.marker,
  context: chartContext.withMarkerOffset(annotation.markerOffset),
);

// 3. Transform marker to screen coordinates (includes zoom/pan)
final screenPos = transformer.transform(
  markerPos,
  from: CoordinateSystem.marker,
  to: CoordinateSystem.screen,
  context: chartContext,
);

// 4. Render annotation at screen position
canvas.drawCircle(screenPos, 8.0, markerPaint);
canvas.drawText(annotation.text, screenPos + Point(10, -10));
```

**Acceptance Criteria**:
- ✅ Annotation stays anchored to data under zoom (visible/hidden appropriately)
- ✅ Annotation follows data under pan
- ✅ Marker offset (50px above) maintained in screen space
- ✅ No jitter or jumping during animations

---

### Scenario 3: Range Annotation Highlighting
**User Story**: As a business analyst, when I highlight a date range on a timeline chart, I want the shaded area to cover the exact date range regardless of zoom level.

**Technical Flow**:
```dart
// 1. User selects range: Jan 1 - Jan 31, 2024
final rangeAnnotation = RangeAnnotation(
  startData: Point(dateToTimestamp('2024-01-01'), double.negativeInfinity),
  endData: Point(dateToTimestamp('2024-01-31'), double.negativeInfinity),
  fillColor: Colors.blue.withOpacity(0.2),
);

// 2. Transform corners to screen coordinates
final topLeft = transformer.transform(
  Point(rangeAnnotation.startData.x, chartContext.yDataRange.max),
  from: CoordinateSystem.data,
  to: CoordinateSystem.screen,
  context: chartContext,
);

final bottomRight = transformer.transform(
  Point(rangeAnnotation.endData.x, chartContext.yDataRange.min),
  from: CoordinateSystem.data,
  to: CoordinateSystem.screen,
  context: chartContext,
);

// 3. Draw shaded rectangle
final rect = Rect.fromPoints(topLeft.toOffset(), bottomRight.toOffset());
canvas.drawRect(rect, rangeAnnotation.fillPaint);
```

**Acceptance Criteria**:
- ✅ Range covers exact data range (pixel-perfect boundaries)
- ✅ Expands/contracts correctly with zoom
- ✅ Clipped at chart area boundaries (no overflow)
- ✅ Partial range visible when panned outside viewport

---

### Scenario 4: Real-Time Data Streaming with Auto-Pan
**User Story**: As a monitoring dashboard user, when new data arrives, I want the chart to auto-pan to keep the latest data visible.

**Technical Flow**:
```dart
// 1. New data point arrives
final newPoint = ChartDataPoint(x: currentTimestamp, y: sensorValue);
series.add(newPoint);

// 2. Calculate new viewport to keep last 100 points visible
final viewportStartData = series[series.length - 100].x;
final viewportEndData = newPoint.x;

// 3. Update viewport range (triggers re-render)
chartContext = chartContext.withViewport(
  ViewportState(
    xRange: DataRange(min: viewportStartData, max: viewportEndData),
    yRange: chartContext.yDataRange, // Auto-scale
  ),
);

// 4. Rendering uses transformer automatically
// All existing data points transform correctly with new viewport
final screenPoints = transformer.transformBatch(
  series.dataPoints,
  from: CoordinateSystem.data,
  to: CoordinateSystem.screen,
  context: chartContext,
);
```

**Acceptance Criteria**:
- ✅ New data appears at right edge of chart
- ✅ Old data scrolls off left edge smoothly
- ✅ All annotations follow data correctly
- ✅ No coordinate "jumps" or discontinuities

---

## Functional Requirements

### FR-001: Coordinate System Definitions
**Priority**: P0 (Critical)

The system MUST support exactly 8 coordinate systems:

1. **Mouse**: Raw Flutter event coordinates
   - Origin: Top-left of Flutter widget
   - Range: (0, 0) to (widget.width, widget.height)
   - Units: Physical pixels
   - Use case: Event handling

2. **Screen**: Widget coordinate space
   - Origin: Top-left of Flutter widget
   - Range: (0, 0) to (widget.width, widget.height)
   - Units: Logical pixels (device-independent)
   - Use case: Canvas drawing

3. **ChartArea**: Plot area coordinates
   - Origin: Top-left of chart drawing area (excluding axes, title, legend)
   - Range: (0, 0) to (chartArea.width, chartArea.height)
   - Units: Logical pixels
   - Use case: Rendering within plot bounds

4. **Data**: Logical data space
   - Origin: Data-dependent (can be negative)
   - Range: (xAxis.min, yAxis.min) to (xAxis.max, yAxis.max)
   - Units: Data units (e.g., dollars, dates, temperatures)
   - Use case: Business logic, data storage

5. **DataPoint**: Series index coordinates
   - Origin: (0, 0) = first series, first point
   - Range: (0, 0) to (series.length-1, maxPoints-1)
   - Units: Integer indices
   - Use case: Direct array access for rendering optimization

6. **Marker**: Annotation positioning with offsets
   - Origin: Data position + marker-specific offset
   - Range: Same as ChartArea
   - Units: Logical pixels
   - Use case: Annotation markers, labels, indicators

7. **Viewport**: Zoom/pan adjusted coordinates
   - Origin: Viewport-dependent (moves with pan)
   - Range: Subset of Data range
   - Units: Data units scaled by zoom
   - Use case: User interaction transformations

8. **Normalized**: Relative coordinates (0.0-1.0)
   - Origin: (0, 0) = top-left of chart area
   - Range: (0.0, 0.0) to (1.0, 1.0)
   - Units: Percentage of chart area
   - Use case: Layout calculations, responsive sizing

**Validation**:
- Each system has well-defined origin, range, and units
- Transformations preserve geometric relationships (parallel lines stay parallel)
- Round-trip transformation preserves original point (within floating-point tolerance)

---

### FR-002: Bidirectional Transformations
**Priority**: P0 (Critical)

The system MUST support transformations between ANY two coordinate systems.

**API**:
```dart
Point<double> transform(
  Point<double> point,
  CoordinateSystem from,
  CoordinateSystem to,
  TransformContext context,
);
```

**All 56 transformation paths** (8 systems × 7 destinations):
- Mouse ↔ Screen, ChartArea, Data, DataPoint, Marker, Viewport, Normalized
- Screen ↔ ChartArea, Data, DataPoint, Marker, Viewport, Normalized
- ChartArea ↔ Data, DataPoint, Marker, Viewport, Normalized
- Data ↔ DataPoint, Marker, Viewport, Normalized
- DataPoint ↔ Marker, Viewport, Normalized
- Marker ↔ Viewport, Normalized
- Viewport ↔ Normalized

**Transformation Properties**:
1. **Deterministic**: Same input + context → same output
2. **Reversible**: `transform(transform(p, A, B, ctx), B, A, ctx) ≈ p`
3. **Transitive**: Direct A→C = composed A→B→C
4. **Context-aware**: Uses appropriate context fields for each transformation

**Validation**:
- All 56 paths have unit tests
- Round-trip tests verify reversibility
- Composition tests verify transitivity
- Edge case tests (infinity, NaN, extreme values)

---

### FR-003: Transform Context
**Priority**: P0 (Critical)

The system MUST accept immutable transformation context containing all necessary state.

**Context Structure**:
```dart
class TransformContext {
  // Widget dimensions
  final Size widgetSize;
  
  // Chart layout
  final Rect chartAreaBounds;  // Plot area excluding axes/legend
  
  // Data ranges
  final DataRange xDataRange;
  final DataRange yDataRange;
  
  // Viewport state (zoom/pan)
  final ViewportState viewport;
  
  // Series data (for DataPoint transformations)
  final List<ChartSeries> series;
  
  // Marker positioning
  final Point<double>? markerOffset;
  
  // Animation state
  final double animationProgress; // 0.0 to 1.0
  
  // Device metrics
  final double devicePixelRatio;
  
  // Immutable update methods
  TransformContext withViewport(ViewportState viewport);
  TransformContext withMarkerOffset(Point<double> offset);
  // ... other withX methods
}
```

**Requirements**:
- MUST be immutable (all fields final)
- MUST provide `withX()` methods for updates
- MUST validate all fields in constructor (no invalid ranges)
- MUST cache derived values (e.g., transformation matrices)

**Validation**:
- Constructor throws on invalid ranges (min > max)
- Constructor throws on negative dimensions
- withX() methods preserve immutability (return new instance)
- Context equality based on structural equality

---

### FR-004: Batch Transformations
**Priority**: P0 (Critical - Performance)

The system MUST support efficient batch transformation of large point sets.

**API**:
```dart
List<Point<double>> transformBatch(
  List<Point<double>> points,
  CoordinateSystem from,
  CoordinateSystem to,
  TransformContext context,
);
```

**Performance Requirements**:
- MUST transform 10,000 points in <1ms (on reference hardware)
- MUST use zero allocations for intermediate calculations
- MUST leverage SIMD operations where available
- MUST cache transformation matrices across batch

**Optimization Strategies**:
1. **Matrix pre-computation**: Calculate once, apply many times
2. **SIMD operations**: Use Float32x4 for parallel arithmetic
3. **Object pooling**: Reuse Point instances from Foundation layer
4. **Viewport culling**: Skip points outside viewport before transformation

**Validation**:
- Benchmark tests verify <1ms target
- Memory profiler confirms zero allocations
- Batch results identical to individual transforms
- Large dataset tests (100K+ points)

---

### FR-005: Coordinate Validation
**Priority**: P1 (High)

The system MUST validate coordinates before transformation and provide actionable errors.

**Validation Checks**:
1. **Range Validation**: Point within valid range for coordinate system
2. **Finite Check**: No NaN or infinity values
3. **Context Validation**: Context contains required fields for transformation
4. **Transformation Support**: from→to path is implemented

**API**:
```dart
ValidationResult validate(
  Point<double> point,
  CoordinateSystem system,
  TransformContext context,
);

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationErrorType? errorType;
  
  // Factory constructors
  factory ValidationResult.valid();
  factory ValidationResult.invalid(String message, ValidationErrorType type);
}

enum ValidationErrorType {
  outOfRange,      // Point outside valid range
  invalidValue,    // NaN or infinity
  missingContext,  // Required context field null
  unsupportedPath, // Transformation not implemented
}
```

**Error Messages** (must be actionable):
- ❌ "Point (150.5, -10.3) out of range"
- ✅ "Point (150.5, -10.3) outside valid range for ChartArea. Valid range: Rect(0, 0, 800, 600). Check if point is in Data coordinates instead?"

**Validation**:
- All validation error types have unit tests
- Error messages include suggested fixes
- Validation can be disabled for performance (opt-in)

---

### FR-006: Transformation Caching
**Priority**: P1 (High - Performance)

The system MUST cache transformation matrices to avoid repeated calculations.

**Cache Strategy**:
```dart
class CachedCoordinateTransformer implements CoordinateTransformer {
  final Map<String, TransformMatrix> _matrixCache;
  
  @override
  Point<double> transform(Point<double> point, ...) {
    final cacheKey = _buildCacheKey(from, to, context);
    final matrix = _matrixCache[cacheKey] ??= _buildMatrix(from, to, context);
    return matrix.transform(point);
  }
  
  void invalidateCache() {
    _matrixCache.clear();
  }
}
```

**Cache Key Components**:
- from and to coordinate systems
- chartAreaBounds hash
- xDataRange and yDataRange hash
- viewport state hash
- devicePixelRatio

**Cache Invalidation**:
- MUST invalidate on context changes (viewport, data range, chart size)
- MUST NOT cache across different contexts
- MUST provide manual invalidation for testing

**Validation**:
- Cache hit rate >90% during typical usage
- Cache size bounded (LRU eviction if needed)
- Cache invalidation tests verify correctness

---

## Non-Functional Requirements

### NFR-001: Performance
**Target**: <1ms for batch transformation of 10,000 points

**Measurement**:
```dart
final stopwatch = Stopwatch()..start();
final screenPoints = transformer.transformBatch(
  tenThousandDataPoints,
  CoordinateSystem.data,
  CoordinateSystem.screen,
  context,
);
stopwatch.stop();
assert(stopwatch.elapsedMicroseconds < 1000); // <1ms
```

**Strategies**:
- Pre-compute transformation matrices
- Use SIMD operations (Float32x4)
- Leverage ObjectPool from Foundation layer
- Avoid allocations in hot path

---

### NFR-002: Memory Efficiency
**Target**: Zero allocations during steady-state transformations

**Measurement**:
- Use Flutter DevTools memory profiler
- Run transformation loop 1000x
- Verify heap size unchanged

**Strategies**:
- Reuse Point objects via ObjectPool
- Cache transformation matrices
- Use primitive arrays instead of objects where possible

---

### NFR-003: Type Safety
**Target**: 100% compile-time coordinate space checking

**Mechanism**:
```dart
// ❌ This should NOT compile (Point<double> is ambiguous)
Point<double> ambiguous = getMousePosition();
canvas.drawCircle(ambiguous, 5.0, paint);

// ✅ This SHOULD compile (types enforce coordinate space)
MousePoint mouse = getMousePosition();
ScreenPoint screen = transformer.transform(mouse, context);
canvas.drawCircle(screen, 5.0, paint);
```

**Strategy**:
- Define typed point classes: `MousePoint`, `ScreenPoint`, `DataPoint`, etc.
- Overload `transform()` for each typed pair
- Use sealed classes to prevent external subclassing

**Validation**:
- Negative tests verify compilation failures
- Type system tests in contract tests
- API examples demonstrate usage

---

## Key Entities

### CoordinateSystem (Enum)
```dart
enum CoordinateSystem {
  mouse,
  screen,
  chartArea,
  data,
  dataPoint,
  marker,
  viewport,
  normalized,
}
```

**Properties**:
- 8 well-defined coordinate spaces
- Used as parameters in transformation API
- Human-readable for debugging

---

### TransformContext (Immutable Data Class)
```dart
class TransformContext {
  final Size widgetSize;
  final Rect chartAreaBounds;
  final DataRange xDataRange;
  final DataRange yDataRange;
  final ViewportState viewport;
  final List<ChartSeries> series;
  final Point<double>? markerOffset;
  final double animationProgress;
  final double devicePixelRatio;
  
  const TransformContext({...});
  
  TransformContext withViewport(ViewportState viewport);
  TransformContext withMarkerOffset(Point<double> offset);
  // ... other with methods
}
```

**Dependencies**:
- `DataRange` from Foundation layer
- `ChartSeries` from Foundation layer
- `ViewportState` (defined in this layer)

---

### CoordinateTransformer (Interface)
```dart
abstract class CoordinateTransformer {
  Point<double> transform(
    Point<double> point,
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );
  
  List<Point<double>> transformBatch(
    List<Point<double>> points,
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );
  
  ValidationResult validate(
    Point<double> point,
    CoordinateSystem system,
    TransformContext context,
  );
  
  Rect getValidRange(
    CoordinateSystem system,
    TransformContext context,
  );
}
```

**Implementations**:
- `UniversalCoordinateTransformer` - Standard implementation
- `CachedCoordinateTransformer` - With matrix caching
- `ValidatedCoordinateTransformer` - With automatic validation

---

### ViewportState (Immutable Data Class)
```dart
class ViewportState {
  final DataRange xRange;
  final DataRange yRange;
  final double zoomFactor;
  final Point<double> panOffset;
  
  const ViewportState({
    required this.xRange,
    required this.yRange,
    this.zoomFactor = 1.0,
    this.panOffset = Point.zero,
  });
  
  ViewportState withZoom(double factor);
  ViewportState withPan(Point<double> offset);
  
  bool containsPoint(Point<double> dataPoint);
}
```

**Properties**:
- Represents current zoom/pan state
- Immutable for safe sharing
- Provides convenience methods for common operations

---

### TransformMatrix (Internal Utility)
```dart
class TransformMatrix {
  final Float32List _values; // 3x3 affine matrix
  
  TransformMatrix.identity();
  TransformMatrix.translation(double dx, double dy);
  TransformMatrix.scale(double sx, double sy);
  TransformMatrix.combined(List<TransformMatrix> matrices);
  
  Point<double> transform(Point<double> point);
  TransformMatrix inverse();
}
```

**Properties**:
- Efficient 3x3 affine transformation
- Composable (multiply matrices)
- Invertible for bidirectional transforms

---

## Dependencies

### Layer 0: Foundation (000-foundation)
**Required**:
- `DataRange` - For data axis ranges
- `ChartSeries` - For DataPoint coordinate transformations
- `ChartDataPoint` - Point data structure
- `ObjectPool<Point>` - For zero-allocation transformations

**Why**: Coordinate system is built on top of data structures and performance primitives.

---

### Layer 1: Core Rendering (001-core-rendering)
**Required**:
- `RenderContext` - Contains chart layout (chartAreaBounds)
- Performance monitoring infrastructure

**Why**: Coordinate transformations used during rendering pipeline.

**Integration**:
```dart
class RenderContext {
  final TransformContext transformContext;
  final CoordinateTransformer transformer;
  
  // Convenience methods
  Point<double> toScreen(Point<double> dataPoint) {
    return transformer.transform(
      dataPoint,
      CoordinateSystem.data,
      CoordinateSystem.screen,
      transformContext,
    );
  }
}
```

---

## Success Metrics

### Correctness Metrics
- ✅ 100% test coverage (all 56 transformation paths)
- ✅ Zero coordinate-related bugs in production (vs 23 in v1.0)
- ✅ All round-trip transformations within 0.01 pixel tolerance

### Performance Metrics
- ✅ <1ms for 10K point batch transformation
- ✅ >90% cache hit rate during typical usage
- ✅ Zero allocations in steady-state rendering

### Integration Metrics
- ✅ All chart types use coordinate system (100% adoption)
- ✅ All annotation types use coordinate system
- ✅ All interaction handlers use coordinate system

### Developer Experience
- ✅ <10 lines of code for typical transformation use case
- ✅ Actionable error messages (includes suggested fix)
- ✅ API examples in documentation for all 8 coordinate systems

---

## Testing Strategy

### Unit Tests (100% Coverage Target)
```dart
// Test individual transformations
test('Data to Screen transformation', () {
  final context = TransformContext(
    widgetSize: Size(800, 600),
    chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540),
    xDataRange: DataRange(min: 0, max: 100),
    yDataRange: DataRange(min: 0, max: 50),
    viewport: ViewportState.identity(),
  );
  
  final transformer = UniversalCoordinateTransformer();
  final dataPoint = Point(50.0, 25.0); // Middle of data range
  
  final screenPoint = transformer.transform(
    dataPoint,
    CoordinateSystem.data,
    CoordinateSystem.screen,
    context,
  );
  
  // Should be middle of chart area
  expect(screenPoint.x, closeTo(400, 0.1)); // 50 + 700/2
  expect(screenPoint.y, closeTo(300, 0.1)); // 30 + 540/2
});

// Test round-trip transformations
test('Round-trip transformation preserves point', () {
  final original = Point(42.5, 17.3);
  
  final intermediate = transformer.transform(
    original,
    CoordinateSystem.data,
    CoordinateSystem.screen,
    context,
  );
  
  final roundTrip = transformer.transform(
    intermediate,
    CoordinateSystem.screen,
    CoordinateSystem.data,
    context,
  );
  
  expect(roundTrip.x, closeTo(original.x, 0.01));
  expect(roundTrip.y, closeTo(original.y, 0.01));
});
```

### Contract Tests
```dart
// Verify all transformation paths exist
test('All 56 transformation paths implemented', () {
  final systems = CoordinateSystem.values;
  
  for (final from in systems) {
    for (final to in systems) {
      if (from == to) continue;
      
      expect(
        () => transformer.transform(testPoint, from, to, context),
        returnsNormally,
        reason: 'Transformation $from → $to not implemented',
      );
    }
  }
});
```

### Integration Tests
```dart
// Test with real chart rendering
test('Coordinate system integrates with rendering pipeline', () {
  final chart = LineChart(
    data: testSeries,
    transformer: UniversalCoordinateTransformer(),
  );
  
  final renderContext = buildRenderContext(chart);
  
  // Verify all data points transform correctly
  for (final point in testSeries.points) {
    final screenPos = renderContext.transformer.transform(
      point.position,
      CoordinateSystem.data,
      CoordinateSystem.screen,
      renderContext.transformContext,
    );
    
    expect(screenPos.x, inInclusiveRange(0, renderContext.size.width));
    expect(screenPos.y, inInclusiveRange(0, renderContext.size.height));
  }
});
```

### Performance Benchmarks
```dart
benchmark('Batch transformation of 10K points', () {
  final points = List.generate(10000, (i) => Point(i.toDouble(), i * 2.0));
  
  final stopwatch = Stopwatch()..start();
  final screenPoints = transformer.transformBatch(
    points,
    CoordinateSystem.data,
    CoordinateSystem.screen,
    context,
  );
  stopwatch.stop();
  
  expect(stopwatch.elapsedMicroseconds, lessThan(1000)); // <1ms
  expect(screenPoints.length, 10000);
});
```

---

## Implementation Phases

### Phase 1: Core Transformation Engine (Week 1)
- Define 8 coordinate systems
- Implement TransformContext
- Implement basic transformations (Data ↔ Screen, ChartArea ↔ Screen)
- Unit tests for core transformations

### Phase 2: Complete Transformation Matrix (Week 1-2)
- Implement all 56 transformation paths
- Implement TransformMatrix for efficient operations
- Round-trip tests for all paths
- Edge case handling (infinity, NaN, zero dimensions)

### Phase 3: Validation & Error Handling (Week 2)
- Implement coordinate validation
- Add actionable error messages
- Validation tests
- Performance validation (no overhead when disabled)

### Phase 4: Performance Optimization (Week 2)
- Implement matrix caching
- Implement batch transformations
- SIMD optimizations
- ObjectPool integration
- Performance benchmarks

### Phase 5: Integration & Documentation (Week 3)
- Integrate with RenderContext
- Create usage examples for all 8 coordinate systems
- API documentation
- Migration guide from ad-hoc transformations

---

## Migration from v1.0

### v1.0 Pattern (Ad-hoc)
```dart
// ❌ Old way: Manual calculation scattered everywhere
double dataToScreenX(double dataX) {
  final range = xMax - xMin;
  final normalized = (dataX - xMin) / range;
  return chartArea.left + normalized * chartArea.width;
}

// Different logic in annotation manager
double annotationToScreenX(Annotation ann) {
  // Slightly different calculation → bugs!
  return (ann.x - xMin) / (xMax - xMin) * chartWidth + padding;
}
```

### v2.0 Pattern (Centralized)
```dart
// ✅ New way: Single source of truth
final screenPoint = transformer.transform(
  dataPoint,
  from: CoordinateSystem.data,
  to: CoordinateSystem.screen,
  context: renderContext.transformContext,
);
```

### Migration Steps
1. Identify all manual coordinate calculations (grep for calculations)
2. Replace with `transformer.transform()` calls
3. Verify equivalent behavior with integration tests
4. Remove old calculation methods

---

## Open Questions

1. **Polar Coordinates**: Do we need polar→cartesian transformations for pie charts?
   - **Decision**: Defer to chart-specific logic (not universal)
   
2. **3D Transformations**: Future-proof for 3D charts?
   - **Decision**: No, 2D only. 3D would be separate system.

3. **Animation Interpolation**: How to handle coordinate interpolation during animations?
   - **Decision**: Use `animationProgress` field in context, interpolate in data space

4. **Coordinate Space Type Safety**: Enforce at compile-time vs runtime?
   - **Decision**: Both - typed classes for API, runtime validation for safety

---

## References

### Internal Documents
- [Universal Coordinate Transformer Architecture](../../architecture/specs/UNIVERSAL_COORDINATE_TRANSFORMER.md)
- [v1.0 Lessons Learned](../../architecture/lessons-learned/CRITICAL_IMPLEMENTATION_FAILURES.md)
- [Foundation Layer Specification](../001-foundation/spec.md)
- [Core Rendering Engine Specification](../002-core-rendering/spec.md)

### External Resources
- Flutter Canvas API: https://api.flutter.dev/flutter/dart-ui/Canvas-class.html
- Affine Transformations: https://en.wikipedia.org/wiki/Affine_transformation
- SIMD in Dart: https://api.flutter.dev/flutter/dart-typed_data/Float32x4-class.html

---

**Specification Status**: ✅ Ready for Implementation Planning  
**Next Step**: Create `plan.md` with implementation strategy  
**Estimated Effort**: 3 weeks (1 developer)  
**Risk Level**: Medium (complex but well-defined)
