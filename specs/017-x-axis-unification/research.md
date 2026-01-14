# Research: X-Axis Architecture Unification

**Feature**: 017-x-axis-unification  
**Date**: 2025-01-14  
**Status**: Complete

---

## Research Questions

### RQ-1: What patterns from MultiAxisPainter should XAxisPainter adopt?

**Decision**: XAxisPainter will adopt the same architecture as MultiAxisPainter

**Rationale**: 
- MultiAxisPainter (545 lines) provides proven patterns for:
  - TextPainter caching (`_tickLabelCache`, `_axisLabelCache`)
  - Color resolution via AxisColorResolver
  - Nice numbers algorithm for readable tick values
  - Configuration-driven rendering (no hardcoded values)
- Consistency between X and Y axis renderers reduces maintenance burden
- Performance patterns (caching, RepaintBoundary) already validated

**Alternatives Considered**:
- Refactoring XAxisRenderer in place: Rejected because legacy renderer lacks caching infrastructure and would require more changes than new class
- Creating shared AxisPainter base class: Rejected as over-engineering; X and Y axes have different layout concerns (horizontal vs vertical)

---

### RQ-2: How should XAxisConfig relate to existing YAxisConfig and AxisConfig?

**Decision**: XAxisConfig as parallel class to YAxisConfig, with reused enums

**Rationale**:
- `AxisLabelDisplay` enum (7 modes) and `CrosshairLabelPosition` enum are axis-agnostic
- These enums are already defined in `y_axis_config.dart` - can be reused directly
- XAxisConfig will have X-specific properties (XAxisPosition.top/bottom vs YAxisPosition.left/right)
- Backward compatibility: existing `AxisConfig` parameter remains functional

**Alternatives Considered**:
- Single AxisConfig class for both X and Y: Rejected because X and Y have different position enums and layout semantics
- Inheritance hierarchy: Rejected as over-engineering for 2 axis types

**Implementation Note**: Consider moving `AxisLabelDisplay` and `CrosshairLabelPosition` to shared file (`axis_enums.dart`) during refactor, but not required for MVP.

---

### RQ-3: How should AxisColorResolver be extended for XAxisConfig?

**Decision**: Add overloaded/generic method to AxisColorResolver for X-axis

**Rationale**:
- Current `resolveAxisColor(YAxisConfig, ...)` only handles Y-axis
- Need parallel method `resolveXAxisColor(XAxisConfig, ...)`
- Color resolution logic is identical: explicit color → first bound series → default
- Series binding model needs extension: `SeriesAxisBinding` currently only has `yAxisId`

**Implementation Approach**:
```dart
// Option A: Add new method (chosen - minimal change)
static Color resolveXAxisColor(
  XAxisConfig axis,
  List<SeriesAxisBinding> bindings,
  List<ChartSeries> series,
)

// Option B: Generic method (future consideration)
static Color resolveAxisColor<T extends AxisConfig>(
  T axis,
  List<SeriesAxisBinding> bindings,
  List<ChartSeries> series,
)
```

**Alternatives Considered**:
- Generic method: Deferred - requires interface extraction and more refactoring
- Separate resolver class: Rejected as duplication

---

### RQ-4: What is the per-series binding model for X-axis?

**Decision**: Extend SeriesAxisBinding with optional `xAxisId` field

**Rationale**:
- Current model: `SeriesAxisBinding(seriesId, yAxisId)`
- Extended model: `SeriesAxisBinding(seriesId, yAxisId, xAxisId?)`
- Most charts use single shared X-axis, so `xAxisId` is optional
- Default behavior: all series share the chart-level X-axis

**Alternatives Considered**:
- Separate XSeriesAxisBinding class: Rejected as duplication
- Series.xAxisConfig inline only: Rejected because binding model allows shared axis references

---

### RQ-5: How should backward compatibility be maintained?

**Decision**: Deprecate-then-migrate pattern with widget parameter coexistence

**Rationale**:
- `BravenChartPlus(xAxis: AxisConfig(...))` must continue working
- Add `BravenChartPlus(xAxisConfig: XAxisConfig(...))` as new parameter
- When both provided, `xAxisConfig` takes precedence
- Internal logic converts `AxisConfig` to `XAxisConfig` for unified rendering

**Migration Path**:
1. Sprint 017: Both parameters work, `xAxis` not deprecated yet
2. Future sprint: `@Deprecated` annotation on `xAxis` parameter
3. Major version: Remove `xAxis` parameter

---

### RQ-6: What visual defaults should XAxisConfig use?

**Decision**: Match YAxisConfig defaults exactly

**Rationale**:
| Property | Y-Axis Default | X-Axis Default (NEW) | Current X-Axis |
|----------|----------------|----------------------|----------------|
| Font size | 11px | 11px | 12px |
| Color | 0xFF666666 | 0xFF666666 | varies |
| Tick padding | 4px | 4px | 8px |
| Axis margin | 8px | 8px | 4px |
| Tick length | 6px | 6px | 6px |

**Source**: MultiAxisPainter defaults at lines 73-76, YAxisConfig defaults.

---

## Dependencies & Patterns

### Existing Patterns to Follow

| Pattern | Source File | Lines | Application |
|---------|-------------|-------|-------------|
| TextPainter caching | multi_axis_painter.dart | 89-97 | XAxisPainter tick label cache |
| Color resolution | axis_color_resolver.dart | 95-118 | XAxisConfig color lookup |
| Nice numbers algorithm | multi_axis_painter.dart | 200-250 | X-axis tick value calculation |
| Configuration model | y_axis_config.dart | 1-616 | XAxisConfig property structure |

### Test Patterns to Follow

| Pattern | Source File | Application |
|---------|-------------|-------------|
| Unit tests for config | test/unit/models/ | XAxisConfig property tests |
| Rendering tests | test/unit/rendering/ | XAxisPainter paint() tests |
| Widget tests | test/widgets/ | Chart integration tests |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing tests | Medium | High | Run full test suite after each change |
| Performance regression | Low | High | Benchmark before/after, maintain caching |
| API confusion (2 params) | Low | Medium | Clear documentation, deprecation warnings |
| Enum import conflicts | Low | Low | Careful export organization in barrel file |

---

## Conclusion

No NEEDS CLARIFICATION items remain. All technical decisions are well-defined based on existing patterns in the codebase. Implementation can proceed with Phase 1 design artifacts.
