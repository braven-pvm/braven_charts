# Research: Axis Renderer Unification

**Feature**: 013-axis-renderer-unification  
**Date**: 2025-12-11  
**Status**: Complete (pre-resolved in technical spec)

---

## Overview

All major technical decisions were pre-resolved during the specification phase. This document consolidates those decisions and documents the research findings that informed them.

**Reference**: `docs/architecture/specs/axis_renderer_unification_spec.md`

---

## Research Findings

### 1. Rendering Path Unification Strategy

**Decision**: Use Facade Pattern (Option C) - route all Y-axis rendering through `MultiAxisPainter`

**Rationale**:
- `MultiAxisPainter` already handles single-axis case correctly (just pass 1 axis)
- Minimal code changes compared to base class extraction
- Leverages existing battle-tested code
- Clear migration path with low risk

**Alternatives Considered**:
- **Option A (Unify into MultiAxisPainter)**: Would lose Tick object caching, add complexity
- **Option B (Extract Base Class)**: More files/classes, risk of divergence over time

**Source**: Technical spec Section 2 & 3

---

### 2. Grid Rendering Extraction

**Decision**: Create dedicated `GridRenderer` class (Option 3.1.C)

**Rationale**:
- Single Responsibility: Grid rendering is its own concern
- Consistent styling: One place for grid styling logic
- Paint order control: Grid can be painted at correct z-order (behind axes)
- Axis independence: Neither X nor Y axis renderer handles grid
- Future-proof: Easy to add minor grid, different patterns

**Alternatives Considered**:
- **Option 3.1.A (Keep Grid in XAxisRenderer)**: Breaks separation of concerns, complex coupling
- **Option 3.1.B (Add Grid to MultiAxisPainter)**: Duplicates grid logic, wrong responsibility

**Source**: Technical spec Section 3.1

---

### 3. TextPainter Caching Strategy

**Decision**: Add per-axis per-tick-value caching to `MultiAxisPainter`

**Rationale**:
- Legacy `AxisRenderer` has caching via `Tick.getTextPainter()`
- Without caching, creating new TextPainters each paint() causes performance regression
- Map structure: `Map<String, Map<double, TextPainter>>` (axis ID → tick value → painter)
- Critical for 60fps target during crosshair interaction

**Implementation Pattern**:
```dart
Map<String, Map<double, TextPainter>>? _tickLabelCache;

TextPainter _getTickLabelPainter(YAxisConfig axis, double value) {
  _tickLabelCache ??= {};
  _tickLabelCache![axis.id] ??= {};
  return _tickLabelCache![axis.id]!.putIfAbsent(value, () {
    final label = formatTickLabel(value, axis);
    return TextPainter(...)..layout();
  });
}
```

**Source**: Technical spec Section 3 Implementation Plan

---

### 4. Breaking Change Strategy

**Decision**: Clean break (no deprecation period)

**Rationale**:
- Simplifies implementation significantly
- Matches major version bump expectations
- Migration guide provided in spec Section 7.1
- `AxisConfig` Y-axis usage was already inconsistent

**Alternatives Considered**:
- **Deprecation with automatic conversion**: Added complexity, extended maintenance burden
- **Parallel APIs**: Confusing for users, maintenance nightmare

**Source**: Technical spec Section 9 (Resolved Question 1)

---

### 5. Default Y-Axis Behavior

**Decision**: Auto-create default Y-axis when none provided

**Rationale**:
- Maintains backward compatibility
- Simple charts "just work" without explicit axis configuration
- Default: `YAxisConfig(position: YAxisPosition.left)`

**Source**: Technical spec Section 9 (Resolved Question 6)

---

### 6. Property Naming Consistency

**Decision**: Use unified property names across `YAxisConfig` and `XAxisConfig`

**Key Property Mappings (AxisConfig → YAxisConfig/XAxisConfig)**:
| Legacy (AxisConfig) | Unified (Y/XAxisConfig) |
|---------------------|-------------------------|
| `axisColor`       | `color`               |
| `tickColor`       | `color` (unified)     |
| `showAxis`        | `visible` + `showAxisLine` |
| `axisPosition`    | `position`            |
| `range`           | `min`, `max`        |

**Source**: Technical spec Section 7.2

---

### 7. Paint Order

**Decision**: Grid → Y-axes → X-axis → Series → Crosshair → Annotations

**Paint Order (back to front)**:
1. Background
2. `GridRenderer.paintHorizontalGrid()`
3. `GridRenderer.paintVerticalGrid()`
4. `MultiAxisPainter` (Y-axes)
5. `XAxisRenderer` (X-axis only)
6. Data series
7. Crosshair / tooltips
8. Annotations

**Source**: Technical spec Section 3.1

---

## Unresolved Items

None - all NEEDS CLARIFICATION items were resolved during specification phase.

---

## Dependencies & Best Practices

### Flutter CustomPainter Performance

- Use `shouldRepaint()` wisely - return false when possible
- Cache TextPainters between frames
- Avoid creating new objects in `paint()` method
- Use RepaintBoundary to isolate expensive repaints

### Breaking Change Communication

- Document in changelog.md with migration examples
- Update readme.md with new API examples
- Provide before/after code snippets
- Consider major version bump (v2.0.0)

---

## Conclusion

All technical decisions have been pre-resolved. Implementation can proceed directly to Phase 1 design and task generation.
