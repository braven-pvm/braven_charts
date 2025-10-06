# Chart Types Specification Summary

**Layer**: 4 (Chart Types)  
**Status**: Specification Complete ✅  
**Created**: 2025-10-06  
**Dependencies**: Layers 0-3 (Foundation, Rendering, Coordinates, Theming)

---

## Overview

This specification defines four core chart types (Line, Area, Bar, Scatter) that provide concrete visualizations for user data. Each chart type is implemented as a composable `RenderLayer`, leveraging all foundation layers for performance, accuracy, and visual quality.

---

## Chart Types

### 1. Line Chart ✨
**Purpose**: Connect data points with lines to show trends over time

**Features**:
- 3 line styles: Straight, Smooth (bezier), Stepped
- Point markers (6 shapes: circle, square, triangle, diamond, cross, plus)
- Multi-series support (10+ series)
- Customizable line width, dash patterns, colors

**Performance**: <8ms for 10,000 points

### 2. Area Chart ✨
**Purpose**: Filled areas under lines to emphasize magnitude

**Features**:
- 3 fill styles: Solid, Gradient, Pattern
- Flexible baseline (fixed, dynamic, zero)
- Stacking support (series stack vertically)
- Optional line overlay

**Performance**: <10ms for 10,000 points

### 3. Bar Chart ✨
**Purpose**: Compare categories using rectangular bars

**Features**:
- 2 orientations: Vertical, Horizontal
- 2 grouping modes: Grouped (side-by-side), Stacked
- Rounded corners, borders, gradients
- Negative value support

**Performance**: <16ms for 1,000 bars

### 4. Scatter Chart ✨
**Purpose**: Plot individual points to show relationships

**Features**:
- 6 marker shapes (same as line chart)
- Dynamic sizing (based on data/metadata)
- 3 marker styles: Filled, Outlined, Both
- Optional clustering for dense data

**Performance**: <16ms for 10,000 points

---

## Key Design Decisions

### 1. Chart as RenderLayer
Each chart type implements `RenderLayer` from the rendering engine, enabling:
- Composable architecture (mix chart types in one pipeline)
- Consistent z-ordering (charts can layer)
- Shared rendering optimizations (pooling, culling)

### 2. Configuration Objects
Each chart has a dedicated config object:
- `LineChartConfig`, `AreaChartConfig`, `BarChartConfig`, `ScatterChartConfig`
- Immutable, validated configurations
- Clear separation of concerns (data vs presentation)

### 3. Theme Integration
Charts automatically use theming system:
- Series colors from `SeriesTheme.colors` (cycling)
- Line widths from `SeriesTheme.lineWidths`
- Animation settings from `AnimationTheme`
- No manual color management needed

### 4. Animation System
Data updates trigger smooth animations:
- Duration and curve from theme (overridable)
- Efficient data diffing (only changed points animate)
- 60 FPS maintained during transitions
- Can be disabled for real-time dashboards

---

## Technical Architecture

### Component Structure
```
lib/src/charts/
├── base/                 # Shared base classes
│   ├── chart_layer.dart
│   └── chart_renderer.dart
├── line/                 # Line chart
├── area/                 # Area chart
├── bar/                  # Bar chart
├── scatter/              # Scatter chart
└── charts.dart           # Barrel file
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

---

## Performance Requirements

### Frame Time Targets
| Chart Type | Data Size | Target | Maximum |
|------------|-----------|--------|---------|
| Line Chart | 10,000 pts | <8ms | <16ms |
| Area Chart | 10,000 pts | <10ms | <16ms |
| Bar Chart | 1,000 bars | <8ms | <16ms |
| Scatter Chart | 10,000 pts | <16ms | <32ms |

### Optimization Strategies
1. **Viewport Culling**: Only render visible points (<1ms overhead)
2. **Object Pooling**: Reuse Paint/Path objects (>90% hit rate)
3. **Coordinate Caching**: Cache transformed coordinates
4. **Animation Efficiency**: Diff-based updates (not full re-render)

---

## Functional Requirements Summary

### FR-001: Line Chart
- 3 line styles (straight, smooth, stepped)
- 6 marker shapes with customization
- Multi-series support (10+ series)
- Performance: <8ms for 10,000 points

### FR-002: Area Chart
- 3 fill modes (solid, gradient, pattern)
- Flexible baseline configuration
- Stacking support
- Performance: <10ms for 10,000 points

### FR-003: Bar Chart
- 2 orientations (vertical, horizontal)
- 2 grouping modes (grouped, stacked)
- Rounded corners, borders, shadows
- Performance: <16ms for 1,000 bars

### FR-004: Scatter Chart
- 6 marker shapes
- Dynamic sizing (data-driven)
- 3 marker styles (filled, outlined, both)
- Performance: <16ms for 10,000 points

### FR-005: Common Features
- Efficient data series management
- Viewport culling integration
- Coordinate transformation integration
- Automatic theme application

### FR-006: Animation System
- Smooth data update transitions
- Customizable duration and curves
- 60 FPS performance
- Diff-based efficient updates

### FR-007: Configuration
- Immutable config objects per chart type
- Validation on construction
- Sensible defaults from theme

---

## Testing Strategy

### Unit Tests (90% coverage)
- Configuration validation
- Rendering logic
- Coordinate transformations
- Viewport culling
- Performance benchmarks

### Integration Tests
- Multi-series rendering
- Theme application
- Animation smoothness
- Cross-chart composition

### Benchmark Tests
- Frame time measurements
- Memory usage tracking
- Object pool efficiency
- Animation performance

---

## Implementation Phases (6 weeks)

### Week 1: Base Infrastructure
- Create `ChartLayer` base class
- Implement shared utilities
- Set up test infrastructure

### Week 2: Line Chart
- Complete line chart implementation
- All 3 line styles
- Point markers
- 90% test coverage

### Week 3: Area Chart
- Complete area chart implementation
- All 3 fill modes
- Stacking support
- 90% test coverage

### Week 4: Bar Chart
- Complete bar chart implementation
- Both orientations
- Both grouping modes
- 90% test coverage

### Week 5: Scatter Chart
- Complete scatter chart implementation
- All marker shapes
- Dynamic sizing
- 90% test coverage

### Week 6: Integration & Polish
- Multi-chart tests
- Performance optimization
- Documentation
- Example gallery

---

## Dependencies on Lower Layers

### Layer 0: Foundation
- `ChartSeries`, `ChartDataPoint` - Data structures
- `ViewportCuller` - Efficient culling
- `ObjectPool` - Paint/Path pooling
- `Interpolation` - Smooth curves

### Layer 1: Rendering Engine
- `RenderLayer` - Base interface
- `RenderPipeline` - Composition
- `RenderContext` - State management
- Paint/Path pooling infrastructure

### Layer 2: Coordinate System
- `UniversalCoordinateTransformer` - Transformations
- `ViewportState` - Viewport config
- All 8 coordinate spaces

### Layer 3: Theming System
- `ChartTheme` - Theme definitions
- `SeriesTheme` - Series colors, widths
- `AnimationTheme` - Animation settings

---

## Success Criteria

### Technical ✅
- All 4 chart types implemented
- Performance targets met
- 90%+ test coverage
- Zero memory leaks
- >90% object pool hit rate

### User Experience ✅
- Intuitive API
- Beautiful default appearance
- Smooth animations
- Professional themes applied automatically

### Documentation ✅
- Every public API documented
- Code examples for common scenarios
- Performance best practices
- Migration guide for v1.0 users

---

## Next Steps

1. ✅ **Review Specification** - Team review and approval
2. ⏳ **Create plan.md** - Implementation strategy and tech stack
3. ⏳ **Create tasks.md** - Detailed task breakdown (TDD approach)
4. ⏳ **Create data-model.md** - Detailed data structures
5. ⏳ **Create contracts/** - Interface definitions for TDD
6. ⏳ **Begin Implementation** - Week 1: Base infrastructure

---

**Document Status**: ✅ Complete  
**Ready for Implementation**: Yes (pending lower layer completion)  
**Estimated Duration**: 6 weeks  
**Team Size**: 2-3 developers  
**Last Updated**: October 6, 2025
