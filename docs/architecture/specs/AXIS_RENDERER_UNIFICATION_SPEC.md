# Axis Renderer Unification Specification

**Document Status**: DRAFT - Analysis & Discussion  
**Date**: 2025-12-10  
**Branch**: `refactor/axis-labels`  
**Author**: AI Assistant + forcegage-pvm

---

## Executive Summary

The current codebase has **two parallel Y-axis rendering paths** with inconsistent behavior:

1. **`AxisRenderer`** (legacy) - Used for single-axis mode via `BravenChartPlus.yAxis`
2. **`MultiAxisPainter`** - Used for multi-axis mode via `ChartSeries.yAxisConfig`

This spec proposes unifying these paths by:
- Standardizing `BravenChartPlus.yAxis` to accept `YAxisConfig` instead of `AxisConfig`
- Using `MultiAxisPainter` as the single Y-axis rendering path
- Adding a new `CrosshairLabelPosition` enum for crosshair label positioning

---

## 1. Technical Comparison: AxisRenderer vs MultiAxisPainter

### 1.1 Side-by-Side Code Analysis

| Aspect | `AxisRenderer` | `MultiAxisPainter` |
|--------|----------------|-------------------|
| **Config Input** | `Axis` object (contains `InternalAxisConfig`) | `YAxisConfig` directly |
| **Tick Generation** | Pre-computed `axis.ticks` (Tick objects) | Generates on-the-fly via `generateTicks()` |
| **Tick Caching** | `Tick.getTextPainter()` caches TextPainter | Creates new TextPainter each paint |
| **Color Resolution** | `theme?.axisStyle` → `config.axisColor` | `AxisColorResolver.resolveAxisColor()` |
| **Position Calculation** | Uses `axis.scale.dataToPixel()` | Uses `MultiAxisNormalizer.normalize()` |
| **Layout Computation** | None (hardcoded margins) | `MultiAxisLayoutDelegate` + `AxisLayoutManager` |
| **Unit/Label Display** | Not supported | `AxisLabelDisplay` enum |
| **Axis Orientation** | Both X and Y (horizontal/vertical) | Y-axis only |
| **Grid Rendering** | ✅ Yes | ❌ No (separate concern) |

### 1.2 Rendering Logic Comparison

#### Tick Mark Rendering

**AxisRenderer** (Y-axis):
```dart
final tickX1 = config.position == AxisPosition.left ? axisX - config.tickLength : axisX;
final tickX2 = config.position == AxisPosition.left ? axisX : axisX + config.tickLength;
canvas.drawLine(Offset(tickX1, y), Offset(tickX2, y), paint);
```

**MultiAxisPainter**:
```dart
if (isLeftSide) {
  tickStart = axisRect.right;
  tickEnd = axisRect.right - _tickLength;
} else {
  tickStart = axisRect.left;
  tickEnd = axisRect.left + _tickLength;
}
canvas.drawLine(Offset(tickStart, screenY), Offset(tickEnd, screenY), paint);
```

**Difference**: `AxisRenderer` uses plot area edge (`axisX`), `MultiAxisPainter` uses computed `axisRect`.

#### Tick Label Rendering

**AxisRenderer**:
```dart
final textPainter = tick.getTextPainter(config.tickLabelStyle);  // Cached!
final labelX = config.position == AxisPosition.left
    ? axisX - config.tickLength - config.labelPadding - textPainter.width
    : axisX + config.tickLength + config.labelPadding;
```

**MultiAxisPainter**:
```dart
final label = formatTickLabel(value, axis);  // Dynamic formatting with unit
final textPainter = TextPainter(...)..layout();  // NOT cached
labelX = axisRect.right - _tickLength - axis.tickLabelPadding - textPainter.width;
```

**Difference**: `AxisRenderer` has TextPainter caching via `Tick` objects; `MultiAxisPainter` has richer formatting.

#### Axis Label Rendering (Rotated)

**AxisRenderer**:
```dart
final labelX = (config.position == AxisPosition.left ? 12.0 : chartSize.width - 12).toDouble();
// No unit appending, fixed position
```

**MultiAxisPainter**:
```dart
if (axis.shouldAppendUnitToLabel && axis.unit != null) {
  labelText = '$labelText (${axis.unit})';  // Unit support!
}
final labelX = isLeftSide 
    ? axisRect.left + axis.axisMargin + (textPainter.height / 2)
    : axisRect.right - axis.axisMargin - (textPainter.height / 2);
```

**Difference**: `MultiAxisPainter` handles units, uses dynamic positioning via `axisRect`.

### 1.3 Key Architectural Differences

| Feature | `AxisRenderer` | `MultiAxisPainter` |
|---------|----------------|-------------------|
| **Scale/Transform** | `axis.scale.dataToPixel()` | `MultiAxisNormalizer.normalize()` |
| **Tick Objects** | `List<Tick>` with cached painters | `List<double>` values, painters created per-frame |
| **Axis Rect** | Implicit (uses plotArea edge) | Explicit `Rect` from `AxisLayoutManager` |
| **Multi-Axis Support** | No (single axis) | Yes (list of axes) |
| **Outer Positions** | No (`left`/`right` only) | Yes (`leftOuter`/`rightOuter`) |

---

## 2. Technical Decision: Unify or Extract?

### Option A: Unify into `MultiAxisPainter`

**Approach**: Make `MultiAxisPainter` handle single-axis case seamlessly.

**Pros**:
- Single code path for all Y-axis rendering
- Consistent behavior guaranteed
- Simpler maintenance

**Cons**:
- Loses `Tick` object caching (performance regression?)
- `MultiAxisPainter` becomes more complex
- May need to handle X-axis differently anyway

**Changes Required**:
1. Always create `YAxisConfig` even for default Y-axis
2. Compute axis bounds even for single axis
3. Remove Y-axis code from `AxisRenderer` (keep X-axis only)

### Option B: Extract Base Class + Specialize

**Approach**: Create `YAxisPainterBase` with shared logic, extend for both cases.

```
YAxisPainterBase (abstract)
├── generateTicks()
├── formatTickLabel()
├── _niceNum()
├── _roundToDecimals()
├── _paintTickMark()
├── _paintTickLabel()
└── _paintAxisLabel()
    │
    ├── SingleAxisPainter (extends)
    │   └── Uses Axis.scale for positioning
    │
    └── MultiAxisPainter (extends)
        └── Uses MultiAxisNormalizer for positioning
```

**Pros**:
- Single Responsibility preserved
- Can optimize each path independently
- Easier to reason about

**Cons**:
- More files/classes
- Risk of divergence over time
- Still need coordination for consistency

### Option C: Facade Pattern (Recommended)

**Approach**: Keep `MultiAxisPainter` as-is, but make it the **only** Y-axis renderer. Adapt inputs as needed.

```dart
/// Unified Y-axis rendering - handles both single and multi-axis cases.
class YAxisRenderer {
  /// Renders Y-axes using the multi-axis system.
  /// 
  /// For single-axis mode, pass a single-element list.
  /// For multi-axis mode, pass all configured axes.
  void paint(Canvas canvas, Rect chartArea, Rect plotArea, {
    required List<YAxisConfig> axes,
    required Map<String, DataRange> axisBounds,
    List<SeriesAxisBinding> bindings = const [],
    List<ChartSeries> series = const [],
  }) {
    final painter = MultiAxisPainter(
      axes: axes,
      axisBounds: axisBounds,
      bindings: bindings,
      series: series,
    );
    painter.paint(canvas, chartArea, plotArea);
  }
}
```

**Pros**:
- Minimal code changes
- Leverages existing battle-tested `MultiAxisPainter`
- Clear migration path

**Cons**:
- Doesn't address TextPainter caching loss
- `AxisRenderer` still needed for X-axis

---

## 3. Recommendation

### Chosen Approach: **Option C (Facade) + Performance Optimization**

**Rationale**:
1. `MultiAxisPainter` already handles single-axis correctly (just pass 1 axis)
2. The tick caching concern can be addressed by adding caching to `MultiAxisPainter`
3. Keep `AxisRenderer` but **rename to `XAxisRenderer`** for clarity
4. Less risk than major refactor

### 3.1 Grid Rendering Concern

**Current State**: `AxisRenderer` renders grid lines inline with tick rendering:
- X-axis draws **vertical** grid lines (at each X tick)
- Y-axis draws **horizontal** grid lines (at each Y tick)

**Problem**: If we remove Y-axis rendering from `AxisRenderer`, who draws horizontal grid lines?

**Options**:

#### Option 3.1.A: Keep Grid in XAxisRenderer (NOT recommended)
Have XAxisRenderer draw BOTH vertical (X) and horizontal (Y) grid lines.
- ❌ Breaks separation of concerns
- ❌ XAxisRenderer needs Y-axis tick positions
- ❌ Complex coupling

#### Option 3.1.B: Add Grid to MultiAxisPainter (NOT recommended)  
Have MultiAxisPainter draw horizontal grid lines.
- ❌ MultiAxisPainter is for axis painting, not grid
- ❌ Would duplicate grid logic across renderers

#### Option 3.1.C: Create Dedicated `GridRenderer` (RECOMMENDED)
Extract grid rendering into its own single-purpose class.

```dart
/// Renders chart grid lines independent of axis rendering.
/// 
/// Grid lines are painted BEFORE data series (behind them).
class GridRenderer {
  const GridRenderer({this.theme});
  final ChartTheme? theme;
  
  /// Paints horizontal grid lines at the specified Y positions.
  void paintHorizontalGrid(
    Canvas canvas,
    Rect plotArea,
    List<double> yPositions, {
    Color? color,
    double strokeWidth = 0.5,
  }) {
    final paint = Paint()
      ..color = color ?? theme?.gridStyle?.majorColor ?? const Color(0xFFE0E0E0)
      ..strokeWidth = strokeWidth;
    
    for (final y in yPositions) {
      if (y >= plotArea.top && y <= plotArea.bottom) {
        canvas.drawLine(
          Offset(plotArea.left, y),
          Offset(plotArea.right, y),
          paint,
        );
      }
    }
  }
  
  /// Paints vertical grid lines at the specified X positions.
  void paintVerticalGrid(
    Canvas canvas,
    Rect plotArea,
    List<double> xPositions, {
    Color? color,
    double strokeWidth = 0.5,
  }) {
    final paint = Paint()
      ..color = color ?? theme?.gridStyle?.majorColor ?? const Color(0xFFE0E0E0)
      ..strokeWidth = strokeWidth;
    
    for (final x in xPositions) {
      if (x >= plotArea.left && x <= plotArea.right) {
        canvas.drawLine(
          Offset(x, plotArea.top),
          Offset(x, plotArea.bottom),
          paint,
        );
      }
    }
  }
}
```

**Benefits of Option 3.1.C**:
- ✅ Single Responsibility: Grid rendering is its own concern
- ✅ Consistent styling: One place for grid styling logic
- ✅ Paint order control: Grid can be painted at correct z-order
- ✅ Axis independence: Neither X nor Y axis renderer handles grid
- ✅ Future-proof: Easy to add minor grid, different patterns, etc.

**Revised Architecture**:
```
Paint Order (back to front):
1. Background
2. GridRenderer.paintHorizontalGrid() ← NEW
3. GridRenderer.paintVerticalGrid()   ← NEW  
4. MultiAxisPainter (Y-axes)          ← All Y-axis rendering
5. XAxisRenderer (X-axis only)        ← Renamed from AxisRenderer
6. Data series
7. Crosshair / tooltips
8. Annotations
```

**Implementation Plan (Revised)**:

1. **Add TextPainter caching to `MultiAxisPainter`**:
   ```dart
   /// Cached text painters per axis per tick value
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

2. **Create `GridRenderer`** (new file):
   - `lib/src/rendering/grid_renderer.dart`
   - Handles both horizontal and vertical grid lines
   - Receives tick positions from axis systems

3. **Rename `AxisRenderer` → `XAxisRenderer`**:
   - Remove `_paintVerticalAxis()` method
   - Remove grid rendering from `_paintHorizontalAxis()`
   - Keep only X-axis line, ticks, labels

4. **Update `chart_render_box.dart`**:
   - Add `GridRenderer` instance
   - Paint grid before axes
   - Get Y tick positions from `MultiAxisPainter.generateTicks()`
   - Get X tick positions from `XAxisRenderer` or scale

---

## 4. Original Architecture Details

### 4.1 The Two Rendering Paths

#### Path A: Legacy `AxisRenderer` (Single-Axis Mode)

**Location**: `lib/src/axis/axis_renderer.dart`

**Triggered when**:
- `BravenChartPlus.yAxis` is set (or defaults)
- No series has `yAxisConfig` or `yAxisId`

**Config type**: `AxisConfig` (legacy) → converted to `InternalAxisConfig`

**Flow**:
```
BravenChartPlus.yAxis (AxisConfig)
    ↓
toAxisConfig() → AxisConfig
    ↓
InternalAxisConfig.fromPublicConfig()
    ↓
AxisRenderer.paint()
```

**Limitations**:
- Position always assumed `left` (hardcoded `leftMargin = 60`)
- No support for `YAxisPosition.right`, `leftOuter`, `rightOuter`
- No axis color resolution from series
- No unit/label display modes (`AxisLabelDisplay`)
- No crosshair label integration

---

#### Path B: `MultiAxisPainter` (Multi-Axis Mode)

**Location**: `lib/src/rendering/multi_axis_painter.dart`

**Triggered when**:
- Any series has `yAxisConfig != null` OR `yAxisId != null`

**Config type**: `YAxisConfig` (native)

**Flow**:
```
ChartSeries.yAxisConfig (YAxisConfig)
    ↓
MultiAxisManager.getEffectiveYAxes()
    ↓
MultiAxisPainter.paint()
```

**Features**:
- Full position support (`left`, `right`, `leftOuter`, `rightOuter`)
- Automatic axis color resolution from series
- Unit/label display modes (`AxisLabelDisplay`)
- Nice number tick generation
- Proper layout width computation
- Crosshair label integration

---

### 4.2 Configuration Model Comparison

| Property | `AxisConfig` (Legacy) | `YAxisConfig` (Modern) |
|----------|----------------------|------------------------|
| Position | `AxisPosition` (4 values, includes top/bottom) | `YAxisPosition` (4 values, Y-axis specific) |
| Color | `axisColor`, `tickColor` | `color` (unified) |
| Unit | ❌ Not supported | ✅ `unit` |
| Label Display | ❌ Not supported | ✅ `AxisLabelDisplay` enum |
| Visibility | `showAxis`, `showTicks`, `showLabels` | `visible`, `showTicks`, `showAxisLine` |
| Grid | `showGrid`, `gridColor`, `gridWidth` | `showGrid` |
| Range | `AxisRange` | `min`, `max` (separate) |
| Crosshair | ❌ Not supported | ✅ `showCrosshairLabel` |
| Width Constraints | ❌ Not supported | ✅ `minWidth`, `maxWidth` |
| Tick Formatting | `labelFormatter` | `labelFormatter`, `decimalPlaces` |

---

### 4.3 Code Path Decision Logic

```dart
// In chart_render_box.dart performLayout():
final effectiveYAxes = _multiAxisManager.getEffectiveYAxes();

if (effectiveYAxes.isNotEmpty) {
  // Multi-axis path - uses MultiAxisPainter
  // Properly handles left/right positioning
} else if (_yAxis != null && _yAxis!.config.showAxisLine) {
  // Legacy path - uses AxisRenderer
  // Always assumes left position (leftMargin = 60)
}
```

**Problem**: When using `BravenChartPlus.yAxis` alone (no series with `yAxisConfig`), the legacy path is taken, losing all modern features.

---

## 5. Identified Issues

### 5.1 Property Type Mismatch

**Current**: `BravenChartPlus.yAxis: AxisConfig?`  
**Expected**: `BravenChartPlus.yAxis: YAxisConfig?`

The `AxisConfig` type lacks essential properties:
- `unit` for tick label formatting
- `AxisLabelDisplay` for label/unit display control  
- `showCrosshairLabel` for crosshair integration
- `crosshairLabelPosition` (proposed) for label positioning

### 5.2 Hardcoded Left Margin

In `chart_render_box.dart`:
```dart
} else if (_yAxis != null && _yAxis!.config.showAxisLine) {
  leftMargin = 60; // HARDCODED - ignores position!
}
```

This breaks `YAxisPosition.right` for single-axis mode.

### 5.3 Dual Conversion Chain

When `BravenChartPlus.yAxis` is provided:
```dart
// Step 1: User provides YAxisConfig (proposed)
// Step 2: Convert to AxisConfig via toAxisConfig()
// Step 3: Merge with theme
// Step 4: Convert to InternalAxisConfig
// Step 5: Create Axis object
// Step 6: Render via AxisRenderer
```

This is overly complex. With `YAxisConfig`, we can go directly to `MultiAxisPainter`.

### 5.4 Missing Crosshair Label Position Control

Currently, crosshair labels are always rendered at a fixed position. We need:

```dart
enum CrosshairLabelPosition {
  /// Label is positioned over the axis area (outside the plot area).
  /// This is the default behavior.
  overAxis,

  /// Label is positioned inside the plot area, near the axis edge.
  /// Similar to the default "Y: value" crosshair label behavior.
  insidePlot,
}
```

---

## 6. Implementation Phases

### 6.1 Phase 1: Add `CrosshairLabelPosition` Enum

**File**: `lib/src/models/y_axis_config.dart`

```dart
/// Controls where the crosshair Y-value label is positioned.
enum CrosshairLabelPosition {
  /// Label is positioned over the axis area (outside the plot area).
  /// This is the default behavior for multi-axis mode.
  overAxis,

  /// Label is positioned inside the plot area, near the axis edge.
  /// Similar to the default "Y: value" crosshair label behavior.
  insidePlot,
}
```

**Add to `YAxisConfig`**:
```dart
/// Where to position the crosshair label when [showCrosshairLabel] is true.
///
/// - [CrosshairLabelPosition.overAxis]: Label appears in the axis strip area
/// - [CrosshairLabelPosition.insidePlot]: Label appears inside the plot area
///
/// Defaults to [CrosshairLabelPosition.overAxis].
final CrosshairLabelPosition crosshairLabelPosition;
```

---

### 6.2 Phase 2: Change `BravenChartPlus.yAxis` Type

**Current**:
```dart
final AxisConfig? yAxis;
```

**Proposed**:
```dart
final YAxisConfig? yAxis;
```

**Migration**:
- This is a **breaking change** for users who currently use `AxisConfig`
- Provide migration guide in CHANGELOG
- Consider deprecation period with automatic conversion

---

### 6.3 Phase 3: Create `GridRenderer` and Unify Rendering Path

**Goal**: 
- Extract grid rendering to dedicated class
- Use `MultiAxisPainter` for all Y-axis rendering

**New File**: `lib/src/rendering/grid_renderer.dart`

```dart
/// Renders chart grid lines independent of axis rendering.
class GridRenderer {
  const GridRenderer({this.theme});
  final ChartTheme? theme;
  
  void paintHorizontalGrid(Canvas canvas, Rect plotArea, List<double> yPositions, {...});
  void paintVerticalGrid(Canvas canvas, Rect plotArea, List<double> xPositions, {...});
}
```

**Changes**:

1. **Create `GridRenderer`** (new file)
   - Handles horizontal and vertical grid lines
   - Uses `ChartTheme.gridStyle` for styling
   - Receives computed tick positions

2. **Rename `AxisRenderer` → `XAxisRenderer`**
   - Remove `_paintVerticalAxis()` method
   - Remove grid rendering from `_paintHorizontalAxis()`
   - Keep only: axis line, tick marks, tick labels, axis label

3. **Always populate `effectiveYAxes` from primary Y-axis**
   ```dart
   List<YAxisConfig> getEffectiveYAxes() {
     final effectiveAxes = <YAxisConfig>[];
     
     // Always include primary Y-axis if provided
     if (_primaryYAxisConfig != null) {
       effectiveAxes.add(_primaryYAxisConfig!.copyWith(
         id: _primaryYAxisConfig!.id.isEmpty ? '_primary' : null,
       ));
     }
     
     // Add series-defined axes...
     for (final series in _series) {
       if (series.yAxisConfig != null) {
         effectiveAxes.add(series.yAxisConfig!);
       }
     }
     
     return effectiveAxes;
   }
   ```

4. **Update `chart_render_box.dart` paint order**:
   ```dart
   void paint(PaintingContext context, Offset offset) {
     final canvas = context.canvas;
     
     // 1. Background
     _paintBackground(canvas);
     
     // 2. Grid (NEW - before axes)
     if (_showGrid) {
       final yTickPositions = _computeYTickPositions();
       final xTickPositions = _computeXTickPositions();
       _gridRenderer.paintHorizontalGrid(canvas, _plotArea, yTickPositions);
       _gridRenderer.paintVerticalGrid(canvas, _plotArea, xTickPositions);
     }
     
     // 3. Y-axes (always via MultiAxisPainter)
     if (effectiveYAxes.isNotEmpty) {
       _multiAxisManager.paintMultipleYAxes(canvas, ...);
     }
     
     // 4. X-axis (via XAxisRenderer, no grid)
     if (_xAxis != null) {
       XAxisRenderer(_xAxis!, theme: _theme).paint(canvas, size, _plotArea);
     }
     
     // 5. Data series
     _paintSeries(canvas);
     
     // 6. Crosshair, tooltips, annotations...
   }
   ```

---

### 6.4 Phase 4: Update Crosshair Renderer

**File**: `lib/src/rendering/modules/crosshair_renderer.dart`

Update `_paintPerAxisCrosshairLabels()` to respect `crosshairLabelPosition`:

```dart
void _paintPerAxisCrosshairLabels(...) {
  for (final axis in effectiveAxes) {
    if (!axis.showCrosshairLabel || !axis.visible) continue;
    
    // Determine label X position based on crosshairLabelPosition
    double labelX;
    final isLeftSide = axis.position == YAxisPosition.left || 
                       axis.position == YAxisPosition.leftOuter;
    
    if (axis.crosshairLabelPosition == CrosshairLabelPosition.overAxis) {
      // Position over the axis strip (outside plot area)
      labelX = _computeAxisStripLabelX(axis, axisWidths, plotArea, isLeftSide);
    } else {
      // Position inside the plot area
      labelX = isLeftSide 
          ? plotArea.left + labelPadding * 2
          : plotArea.right - textPainter.width - labelPadding * 2;
    }
    
    // Paint label at computed position...
  }
}
```

---

## 7. Migration Guide

### 7.1 For Users of `BravenChartPlus.yAxis`

**Before**:
```dart
BravenChartPlus(
  yAxis: AxisConfig(
    label: 'Power',
    axisColor: Colors.blue,
    showGrid: true,
  ),
  // ...
)
```

**After (minimal)**:
```dart
// Simplest case - just use series, Y-axis auto-created
BravenChartPlus(
  series: [...],  // Y-axis auto-created on left with defaults
)
```

**After (with customization)**:
```dart
BravenChartPlus(
  yAxis: YAxisConfig(               // position defaults to left
    label: 'Power',
    color: Colors.blue,
    unit: 'W',                      // New: unit support
    labelDisplay: AxisLabelDisplay.labelWithUnit,  // New: display control
    showCrosshairLabel: true,       // New: crosshair integration
  ),
  grid: GridConfig(horizontal: true, vertical: true),  // Grid moved to chart level
  // ...
)
```

**After (explicit position)**:
```dart
BravenChartPlus(
  yAxis: YAxisConfig(
    position: YAxisPosition.right,  // Explicit non-default position
    label: 'Heart Rate',
    unit: 'bpm',
  ),
  // ...
)
```

### 7.2 Property Mapping

| `AxisConfig` | `YAxisConfig` |
|--------------|---------------|
| `label` | `label` |
| `axisColor` | `color` |
| `tickColor` | `color` (unified) |
| `gridColor` | (use theme) |
| `showAxis` | `visible` + `showAxisLine` |
| `showGrid` | `showGrid` |
| `showTicks` | `showTicks` |
| `showLabels` | (controlled by `labelDisplay`) |
| `axisPosition` | `position` (`YAxisPosition`) |
| `range` | `min`, `max` |
| `labelFormatter` | `labelFormatter` |

---

## 8. Implementation Checklist

### Phase 1: CrosshairLabelPosition
- [ ] Add `CrosshairLabelPosition` enum to `y_axis_config.dart`
- [ ] Add `crosshairLabelPosition` property to `YAxisConfig`
- [ ] Update `copyWith`, `==`, `hashCode`, `toString`
- [ ] Update crosshair renderer to respect the property
- [ ] Add unit tests

### Phase 2: Type Change
- [ ] Change `BravenChartPlus.yAxis` type from `AxisConfig?` to `YAxisConfig?`
- [ ] Update all internal references
- [ ] Update `_rebuildElements()` to handle `YAxisConfig` directly
- [ ] Remove `toAxisConfig()` conversion for Y-axis
- [ ] Update example apps
- [ ] Add deprecation notice in CHANGELOG

### Phase 3: Grid Extraction & Rendering Unification
- [ ] Create `lib/src/rendering/grid_renderer.dart`
- [ ] Implement `paintHorizontalGrid()` and `paintVerticalGrid()`
- [ ] Rename `AxisRenderer` → `XAxisRenderer`
- [ ] Remove `_paintVerticalAxis()` from `XAxisRenderer`
- [ ] Remove grid rendering from `XAxisRenderer._paintHorizontalAxis()`
- [ ] Update `getEffectiveYAxes()` to always include primary Y-axis
- [ ] Update `performLayout()` to use multi-axis layout for all cases
- [ ] Update `paint()` order: Grid → Y-axes → X-axis → Series
- [ ] Add unit tests for `GridRenderer`
- [ ] Add integration tests

### Phase 4: Cleanup & Performance
- [ ] Add TextPainter caching to `MultiAxisPainter`
- [ ] Remove unused `InternalAxisConfig` Y-axis handling
- [ ] Update documentation
- [ ] Update README examples
- [ ] Final testing pass

---

## 9. Open Questions for Discussion

### RESOLVED

1. **Breaking Change Strategy**: Should we provide a deprecation period with automatic `AxisConfig` → `YAxisConfig` conversion, or make a clean break?
   
   **Decision**: ✅ **Clean break**. Change `BravenChartPlus.yAxis` type directly to `YAxisConfig`. No deprecation period.

2. **Default ID**: When `BravenChartPlus.yAxis` is provided without an explicit `id`, should we use `'_primary'`, `'default'`, or require an ID?
   
   **Decision**: ✅ **Remove `id` from public API entirely**. The `id` is auto-generated internally by `MultiAxisManager` as `${series.id}_axis`. Public constructor sets `id: ''` (empty string). Added `@visibleForTesting` `withId` factory for tests that need explicit IDs.

3. **Default Position**: Should we require `position` or default to `YAxisPosition.left`?
   
   **Decision**: ✅ **Default to `YAxisPosition.left`**. Most charts have a single left Y-axis; this is the common case and matches most charting library conventions.

4. **Grid Ownership**: Currently `showGrid` on `YAxisConfig` controls Y-grid lines. Should this remain, or should grid be a separate concern?
   
   **Decision**: ✅ **Separate `GridConfig` object (Option C)**. Remove `showGrid` from `YAxisConfig` entirely. Multi-axis mode already disables Y-grid because horizontal grid lines don't make sense when axes have different scales. Grid becomes a chart-level concern via `BravenChartPlus.grid: GridConfig(...)`.

5. **X-Axis Unification**: Should we also create `XAxisConfig` for consistency, or keep `AxisConfig` for X-axis only?
   
   **Decision**: ✅ **Create `XAxisConfig` for consistency (Option B)**. Provides consistent API with same property names (`color` not `axisColor`), both support `unit`, and type-safe positions (`XAxisPosition.top`/`bottom` vs `YAxisPosition.left`/`right`). Breaking change accepted as part of the overall API cleanup.

6. **Default Y-Axis Behavior**: When `BravenChartPlus.yAxis` is `null` AND no series has `yAxisConfig`, should a default Y-axis be auto-created?
   
   **Decision**: ✅ **Auto-create a default Y-axis (Option A)**. When no Y-axis configuration is provided anywhere, the system auto-creates a minimal default: `YAxisConfig(position: YAxisPosition.left)`. This maintains backwards compatibility and allows simple charts to "just work" without explicit axis configuration.

---

## 10. Appendix: File References

### Core Files to Modify

| File | Purpose |
|------|---------|
| `lib/src/models/y_axis_config.dart` | Add enum + property |
| `lib/src/braven_chart_plus.dart` | Change `yAxis` type |
| `lib/src/rendering/chart_render_box.dart` | Unify rendering path, add GridRenderer |
| `lib/src/rendering/modules/multi_axis_manager.dart` | Always include primary |
| `lib/src/rendering/modules/crosshair_renderer.dart` | Label positioning |
| `lib/src/axis/axis_renderer.dart` | Rename to `x_axis_renderer.dart`, remove Y-axis + grid |

### New Files to Create

| File | Purpose |
|------|---------|
| `lib/src/rendering/grid_renderer.dart` | Dedicated grid line rendering |
| `lib/src/axis/x_axis_renderer.dart` | X-axis only (renamed from axis_renderer.dart) |

### Test Files to Update

| File | Purpose |
|------|---------|
| `test/unit/multi_axis/y_axis_config_test.dart` | New enum tests |
| `test/unit/rendering/modules/crosshair_renderer_test.dart` | Label position tests |
| `test/unit/rendering/grid_renderer_test.dart` | New: grid rendering tests |
| `test/widget/braven_chart_plus_test.dart` | Type change tests |

---

## 11. Next Steps

1. ~~**Review**: Discuss open questions and finalize approach~~ ✅ **COMPLETE** - All 5 questions resolved
2. **Approve**: Get sign-off on breaking change strategy
3. **Implement**: Phase-by-phase implementation
4. **Test**: Comprehensive testing at each phase
5. **Document**: Update all documentation
6. **Release**: Version bump with CHANGELOG entry
