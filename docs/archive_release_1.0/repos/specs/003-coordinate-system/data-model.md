# Data Model: Universal Coordinate System

**Feature**: 003-coordinate-system  
**Date**: 2025-10-05  
**Status**: Design Complete

---

## Entity Overview

The Universal Coordinate System introduces 4 primary entities for type-safe, performant coordinate transformations:

1. **CoordinateSystem** - Enum defining 8 coordinate spaces
2. **TransformContext** - Immutable state container for transformations
3. **ViewportState** - Immutable zoom/pan state
4. **TransformMatrix** - Internal affine transformation matrix (3x3)

All entities follow Foundation Layer patterns: immutability, const constructors, value semantics. Integrates with Core Rendering Engine's RenderContext for unified rendering context.

---

## Entity 1: CoordinateSystem (Enum)

### Purpose
Type-safe enumeration of all coordinate spaces used in chart rendering, interaction, and annotation. Prevents coordinate system mismatches at compile time.

### Values

| Value | Origin | Range | Units | Primary Use Case |
|-------|--------|-------|-------|------------------|
| `mouse` | Top-left of Flutter widget | (0,0) to (widget.width, widget.height) | Physical pixels | Raw event coordinates |
| `screen` | Top-left of Flutter widget | (0,0) to (widget.width, widget.height) | Logical pixels | Canvas drawing |
| `chartArea` | Top-left of plot area | (0,0) to (chartArea.width, chartArea.height) | Logical pixels | Rendering within bounds |
| `data` | Data-dependent | (xAxis.min, yAxis.min) to (xAxis.max, yAxis.max) | Data units | Business logic |
| `dataPoint` | First series, first point | (0, 0) to (series.length-1, maxPoints-1) | Integer indices | Array access |
| `marker` | Data position + offset | Same as chartArea | Logical pixels | Annotation positioning |
| `viewport` | Viewport-dependent | Subset of data range | Data units (scaled) | Zoom/pan transforms |
| `normalized` | Top-left of chart area | (0.0, 0.0) to (1.0, 1.0) | Percentage | Layout calculations |

### Validation Rules
- Enum is sealed (no custom values allowed)
- All 8 values must be handled in transformation logic (exhaustive switch)

### Lifecycle
- **Creation**: Defined at compile time (enum)
- **Usage**: Passed to `transform()` methods as `from` and `to` parameters
- **Immutability**: Enum values are compile-time constants

### Relationships
- **Used by**: CoordinateTransformer (as parameters to `transform()`)
- **Defines**: Valid source/destination coordinate spaces for transformations

### Example
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

// Usage
final screenPoint = transformer.transform(
  dataPoint,
  from: CoordinateSystem.data,
  to: CoordinateSystem.screen,
  context: transformContext,
);
```

---

## Entity 2: TransformContext

### Purpose
Immutable snapshot of all state required for coordinate transformations. Provides dependency injection for stateless transformation logic, ensuring pure functions with no side effects.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `widgetSize` | Size | non-null | Flutter widget dimensions (width, height) |
| `chartAreaBounds` | Rect | non-null | Plot area excluding axes/legend (LTWH) |
| `xDataRange` | DataRange | non-null | Data axis range for X (min, max) |
| `yDataRange` | DataRange | non-null | Data axis range for Y (min, max) |
| `viewport` | ViewportState | non-null | Current zoom/pan state |
| `series` | List<ChartSeries> | non-null | Series data for dataPoint transforms |
| `markerOffset` | Point<double>? | nullable | Annotation marker offset (optional) |
| `animationProgress` | double | non-null (default: 1.0) | Animation state (0.0 to 1.0) |
| `devicePixelRatio` | double | non-null (default: 1.0) | Device pixel density |

### Validation Rules
- `widgetSize.width` and `widgetSize.height` must be > 0
- `chartAreaBounds` must be within widget bounds: `chartAreaBounds.left >= 0`, `chartAreaBounds.top >= 0`, `chartAreaBounds.right <= widgetSize.width`, `chartAreaBounds.bottom <= widgetSize.height`
- `xDataRange.min` must be < `xDataRange.max` (non-empty range)
- `yDataRange.min` must be < `yDataRange.max` (non-empty range)
- `animationProgress` must be in range [0.0, 1.0]
- `devicePixelRatio` must be > 0

### Lifecycle
- **Creation**: Constructed per frame by RenderPipeline or from RenderContext
- **Usage**: Passed to `transform()` and `transformBatch()` methods
- **Destruction**: Discarded at end of frame (immutable, no cleanup)
- **Immutability**: Never mutated; use `withX()` methods to create updated copies

### Relationships
- **Depends on**: DataRange (Foundation), ChartSeries (Foundation), ViewportState (this layer)
- **Used by**: CoordinateTransformer (as parameter to `transform()`)
- **Created from**: RenderContext (convenience factory constructor)
- **Integrated with**: RenderContext (stored as field in v0.3.0+)

### Immutable Update Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `withViewport(ViewportState)` | TransformContext | Update zoom/pan state |
| `withMarkerOffset(Point<double>)` | TransformContext | Set annotation offset |
| `withAnimationProgress(double)` | TransformContext | Update animation state |
| `withDataRanges(DataRange x, DataRange y)` | TransformContext | Update axis ranges |

### Hash Code & Equality
- **Hash code**: Combines all fields for cache key generation
- **Equality**: Structural equality (all fields must match)
- **Cache invalidation**: New hash when any field changes

### Example
```dart
const context = TransformContext(
  widgetSize: Size(800, 600),
  chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540), // Excluding axes
  xDataRange: DataRange(min: 0.0, max: 100.0),
  yDataRange: DataRange(min: -50.0, max: 50.0),
  viewport: ViewportState.identity(), // No zoom/pan
  series: [series1, series2],
  devicePixelRatio: 2.0, // Retina display
);

// Create updated context after zoom
final zoomedContext = context.withViewport(
  ViewportState(
    xRange: DataRange(min: 25.0, max: 75.0), // Zoomed to middle 50%
    yRange: context.yDataRange,
  ),
);

// Factory from RenderContext
final contextFromRender = TransformContext.fromRenderContext(
  renderContext,
  xDataRange: DataRange(min: 0.0, max: 100.0),
  yDataRange: DataRange(min: 0.0, max: 50.0),
  series: chartSeries,
);
```

---

## Entity 3: ViewportState

### Purpose
Immutable representation of current zoom and pan state. Enables users to interactively explore subsets of data while maintaining coordinate transformation consistency.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `xRange` | DataRange | non-null | Visible data range for X axis |
| `yRange` | DataRange | non-null | Visible data range for Y axis |
| `zoomFactor` | double | non-null (default: 1.0) | Zoom level (1.0 = no zoom) |
| `panOffset` | Point<double> | non-null (default: Point.zero) | Pan offset in data units |

### Validation Rules
- `xRange.min` must be < `xRange.max`
- `yRange.min` must be < `yRange.max`
- `zoomFactor` must be > 0 (typical range: 0.1 to 100.0)
- Viewport ranges must be subset of full data ranges (validated in TransformContext)

### Lifecycle
- **Creation**: Initial state = `ViewportState.identity()` (full data range visible)
- **Updates**: User interactions (zoom, pan) create new ViewportState instances
- **Persistence**: Optionally saved to restore user's viewport on app restart

### Relationships
- **Used by**: TransformContext (as field)
- **Created by**: User interaction handlers (zoom/pan gestures)
- **Consumed by**: Data ↔ Viewport transformations

### Immutable Update Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `withZoom(double factor)` | ViewportState | Apply zoom factor |
| `withPan(Point<double> offset)` | ViewportState | Apply pan offset |
| `withRange(DataRange x, DataRange y)` | ViewportState | Set visible ranges directly |

### Convenience Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `containsPoint(Point<double> dataPoint)` | bool | Check if point visible in viewport |
| `isIdentity()` | bool | Check if viewport = full data range (no zoom/pan) |

### Example
```dart
// Initial viewport (full data range)
const initialViewport = ViewportState.identity();

// User zooms in 2x
final zoomedViewport = initialViewport.withZoom(2.0);

// User pans right by 10 data units
final pannedViewport = zoomedViewport.withPan(Point(10.0, 0.0));

// Check if data point is visible
if (pannedViewport.containsPoint(dataPoint)) {
  // Render point
}

// Explicit range (e.g., auto-pan to show last 100 data points)
final autoPanViewport = ViewportState(
  xRange: DataRange(min: lastPoint.x - 100, max: lastPoint.x),
  yRange: fullDataRange.y,
);
```

---

## Entity 4: TransformMatrix

### Purpose
Internal utility for efficient affine transformations using 3x3 matrices. Provides composability (matrix multiplication) and reversibility (matrix inversion) for complex coordinate transformations.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `_values` | Float32List (length 9) | non-null | Column-major 3x3 matrix storage |

**Matrix Layout** (column-major for GLSL/Flutter compatibility):
```
[m00 m10 m20]   [scaleX  shearY  0]
[m01 m11 m21] = [shearX  scaleY  0]
[m02 m12 m22]   [transX  transY  1]

Indices in _values:
[0 3 6]
[1 4 7]
[2 5 8]
```

### Validation Rules
- `_values.length` must be exactly 9
- Bottom row must be [0, 0, 1] for affine transformations
- Matrix must be invertible for bidirectional transforms (determinant ≠ 0)

### Lifecycle
- **Creation**: Constructed from transformation parameters or composed from other matrices
- **Usage**: Apply to Point<double> via `transform()` method
- **Caching**: Stored in transformation cache keyed by context hash
- **Immutability**: Never mutated; matrix operations return new instances

### Relationships
- **Used by**: CoordinateTransformer internally (not exposed in public API)
- **Cached by**: CachedCoordinateTransformer
- **Composed from**: Multiple TransformMatrix instances via multiplication

### Factory Constructors

| Constructor | Purpose | Matrix |
|-------------|---------|--------|
| `TransformMatrix.identity()` | No transformation | `[1 0 0; 0 1 0; 0 0 1]` |
| `TransformMatrix.translation(dx, dy)` | Shift by offset | `[1 0 0; 0 1 0; dx dy 1]` |
| `TransformMatrix.scale(sx, sy)` | Scale about origin | `[sx 0 0; 0 sy 0; 0 0 1]` |
| `TransformMatrix.combined(List<TransformMatrix>)` | Compose transformations | M1 × M2 × ... × Mn |

### Methods

| Method | Signature | Purpose |
|--------|-----------|---------|
| `transform` | `Point<double> transform(Point<double> point)` | Apply transformation |
| `inverse` | `TransformMatrix inverse()` | Compute inverse matrix |
| `multiply` | `TransformMatrix operator *(TransformMatrix other)` | Matrix multiplication |

### Transformation Logic

```dart
Point<double> transform(Point<double> point) {
  // Affine transformation: [x', y', 1] = M × [x, y, 1]
  final x = point.x * _values[0] + point.y * _values[3] + _values[6];
  final y = point.x * _values[1] + point.y * _values[4] + _values[7];
  return Point(x, y);
}
```

### SIMD Optimization

For batch transformations, process 4 points simultaneously:
```dart
// Load 4 x-coordinates and 4 y-coordinates
final xVec = Float32x4(p1.x, p2.x, p3.x, p4.x);
final yVec = Float32x4(p1.y, p2.y, p3.y, p4.y);

// Apply matrix in parallel
final xPrime = xVec * m00 + yVec * m01 + tx;
final yPrime = xVec * m10 + yVec * m11 + ty;

// Extract results: (xPrime.x, yPrime.x), (xPrime.y, yPrime.y), ...
```

### Example
```dart
// Translation matrix: Move right 50px, down 30px
final translation = TransformMatrix.translation(50.0, 30.0);
final p1 = translation.transform(Point(0, 0)); // → Point(50, 30)

// Scale matrix: Double size
final scale = TransformMatrix.scale(2.0, 2.0);
final p2 = scale.transform(Point(10, 20)); // → Point(20, 40)

// Combined transformation: Scale THEN translate
final combined = TransformMatrix.combined([scale, translation]);
final p3 = combined.transform(Point(10, 20)); 
// → scale: (10, 20) → (20, 40)
// → translate: (20, 40) → (70, 70)

// Inverse transformation (reverse direction)
final inverse = combined.inverse();
final p4 = inverse.transform(p3); // → Point(10, 20) (original)
```

---

## Coordinate Transformation Paths

### All 56 Bidirectional Paths

| From → To | Transformation Logic |
|-----------|----------------------|
| **mouse ↔ screen** | Identity (same coordinate space) |
| **screen ↔ chartArea** | Translate by chartArea offset |
| **chartArea ↔ data** | Scale by data range, translate to data origin |
| **data ↔ viewport** | Crop to viewport range, scale by zoom |
| **data ↔ dataPoint** | Lookup series[x].data[y] for index ↔ value |
| **data ↔ marker** | Translate by marker offset |
| **chartArea ↔ normalized** | Scale by chartArea dimensions (0.0-1.0) |

**Transitive Transformations** (via intermediate systems):
- Mouse → Data: mouse → screen → chartArea → data
- DataPoint → Screen: dataPoint → data → chartArea → screen
- Viewport → Marker: viewport → data → marker

### Matrix Composition Example

**Data to Screen** (multi-step transformation):
```dart
// Step 1: Data → ChartArea
final dataToChartArea = TransformMatrix.combined([
  TransformMatrix.translation(-xDataRange.min, -yDataRange.min), // Origin to 0,0
  TransformMatrix.scale(
    chartArea.width / xDataRange.span,
    chartArea.height / yDataRange.span,
  ), // Scale to chart dimensions
  TransformMatrix.scale(1.0, -1.0), // Flip Y (data Y increases up, screen Y increases down)
  TransformMatrix.translation(0, chartArea.height), // Move to bottom-left
]);

// Step 2: ChartArea → Screen
final chartAreaToScreen = TransformMatrix.translation(
  chartArea.left,
  chartArea.top,
);

// Combined: Data → Screen
final dataToScreen = chartAreaToScreen * dataToChartArea;

// Apply to point
final screenPoint = dataToScreen.transform(dataPoint);

// Reverse transformation
final dataPointReverse = dataToScreen.inverse().transform(screenPoint);
```

---

## Integration with Core Rendering Engine

### RenderContext Extension (v0.3.0)

```dart
class RenderContext {
  // Existing fields (v0.2.0)
  final Canvas canvas;
  final Size size;
  final Rect viewport;
  // ... other fields

  // NEW: Coordinate transformation support
  final TransformContext transformContext;
  final CoordinateTransformer transformer;

  const RenderContext({
    // ... existing parameters
    required this.transformContext,
    required this.transformer,
  });

  // Convenience methods
  Point<double> dataToScreen(Point<double> dataPoint) {
    return transformer.transform(
      dataPoint,
      from: CoordinateSystem.data,
      to: CoordinateSystem.screen,
      context: transformContext,
    );
  }
}
```

### TransformContext Construction from RenderContext

```dart
factory TransformContext.fromRenderContext(
  RenderContext renderContext, {
  required DataRange xDataRange,
  required DataRange yDataRange,
  required List<ChartSeries> series,
  ViewportState? viewport,
}) {
  return TransformContext(
    widgetSize: renderContext.size,
    chartAreaBounds: renderContext.viewport, // Reuse viewport as chartArea
    xDataRange: xDataRange,
    yDataRange: yDataRange,
    viewport: viewport ?? ViewportState.identity(),
    series: series,
    devicePixelRatio: 1.0, // TODO: Get from MediaQuery
  );
}
```

---

## Entity Relationships Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ RenderContext (Core Rendering Engine - Layer 1)            │
│ ┌──────────────────────────────────────┐                    │
│ │ TransformContext                     │                    │
│ │  - widgetSize: Size                  │                    │
│ │  - chartAreaBounds: Rect             │                    │
│ │  - xDataRange: DataRange ───────┐    │                    │
│ │  - yDataRange: DataRange        │    │                    │
│ │  - viewport: ViewportState ─┐   │    │                    │
│ │  - series: List<ChartSeries>│   │    │                    │
│ │  - markerOffset: Point?     │   │    │                    │
│ │  - animationProgress: double│   │    │                    │
│ │  - devicePixelRatio: double │   │    │                    │
│ └─────────────────────────────┼───┼────┘                    │
│                                │   │                         │
│ ┌──────────────────────────────▼───┼────┐                   │
│ │ ViewportState                    │    │                   │
│ │  - xRange: DataRange ────────────┘    │                   │
│ │  - yRange: DataRange                  │                   │
│ │  - zoomFactor: double                 │                   │
│ │  - panOffset: Point                   │                   │
│ └───────────────────────────────────────┘                   │
│                                                              │
│ CoordinateTransformer transformer                           │
│  ├─ transform(point, from, to, context)                     │
│  └─ transformBatch(points, from, to, context)               │
│      │                                                       │
│      └─> Uses: TransformMatrix (internal)                   │
│           ├─ identity()                                     │
│           ├─ translation(dx, dy)                            │
│           ├─ scale(sx, sy)                                  │
│           ├─ combined([matrices])                           │
│           └─ inverse()                                      │
└─────────────────────────────────────────────────────────────┘

Legend:
  ─────> Composition (has-a)
  ····> Dependency (uses)
```

---

## Summary

**4 Entities Defined**:
1. **CoordinateSystem** - Enum with 8 coordinate spaces (compile-time type safety)
2. **TransformContext** - Immutable state container (9 fields, all validated)
3. **ViewportState** - Immutable zoom/pan state (4 fields)
4. **TransformMatrix** - 3x3 affine matrix (internal utility, cached for performance)

**56 Transformation Paths**:
- 8 coordinate systems × 7 destinations = 56 bidirectional transformations
- Direct transformations: mouse↔screen, screen↔chartArea, chartArea↔data, data↔viewport, data↔dataPoint, data↔marker, chartArea↔normalized
- Transitive transformations: All other paths via intermediate systems

**Integration**:
- Extends RenderContext with transformContext and transformer fields
- Factory constructor: `TransformContext.fromRenderContext()`
- Convenience methods: `RenderContext.dataToScreen()`, `RenderContext.screenToData()`

**Constitutional Compliance**:
- ✅ Immutable entities (const constructors, final fields)
- ✅ Value semantics (structural equality, hash codes)
- ✅ Foundation patterns (DataRange, ChartSeries dependencies)
- ✅ Performance-optimized (matrix caching, SIMD batch transforms)

---

**Data Model Status**: ✅ Complete - Ready for Phase 1 (Contracts)
