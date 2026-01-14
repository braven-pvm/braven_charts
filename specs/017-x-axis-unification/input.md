# X-Axis Architecture Unification - Speckit Input

**Feature Branch**: `016-x-axis-architecture-unification`
**Created**: 2026-01-14
**Status**: Input for Speckit processing
**Prerequisite**: `013-axis-renderer-unification` (COMPLETED)

---

## Problem Statement

Sprint 013 successfully unified Y-axis rendering through `MultiAxisPainter` with a rich configuration model (`YAxisConfig`). However, the X-axis remains on a legacy architecture with significant capability gaps. The current 014/015 specs only addressed superficial theming changes (font size, colors, padding) without addressing the fundamental architectural disparity.

### Current Architecture Comparison

| Component | Y-Axis (Modern) | X-Axis (Legacy) |
|-----------|-----------------|-----------------|
| **Config Model** | `YAxisConfig` (616 lines, 22 properties) | `AxisConfig` (476 lines, generic, shared) |
| **Renderer** | `MultiAxisPainter` (556 lines, dedicated) | `XAxisRenderer` (133 lines, minimal) |
| **Color Resolver** | `AxisColorResolver` (series-derived colors) | None (static colors only) |
| **Per-Series Binding** | `ChartSeries.yAxisConfig` property | Not available |
| **Multi-Axis Support** | 4 positions (left, leftOuter, right, rightOuter) | 2 positions (top, bottom) |

---

## Detailed Gap Analysis

### 1. Configuration Model Gap

**YAxisConfig properties (22):**
```dart
// Identity
- id: String (auto-generated from series)
- position: YAxisPosition (4 positions)

// Appearance
- color: Color? (null = derive from series)
- label: String?
- unit: String? (e.g., "W", "bpm")

// Bounds
- min: double?
- max: double?

// Visibility
- visible: bool (hide entire axis but keep normalization)
- showAxisLine: bool
- showTicks: bool
- showCrosshairLabel: bool
- crosshairLabelPosition: CrosshairLabelPosition

// Display Mode
- labelDisplay: AxisLabelDisplay (7 modes for unit/label combinations)

// Sizing
- minWidth: double
- maxWidth: double
- tickLabelPadding: double (4.0 default)
- axisLabelPadding: double (5.0 default)
- axisMargin: double (8.0 default)

// Formatting
- tickCount: int?
- labelFormatter: YAxisLabelFormatter?
```

**AxisConfig properties (used for X-axis, 30+ but different focus):**
```dart
// Visibility
- showAxis, showGrid, showTicks, showLabels

// Range
- range: AxisRange?
- allowZoom, allowPan

// Axis Line
- axisColor, axisWidth, axisPosition

// Grid Lines (not in YAxisConfig)
- gridColor, gridWidth, gridDashPattern
- showMinorGrid, minorGridColor

// Ticks
- tickLength, tickWidth, tickColor
- customTickPositions

// Labels
- label, labelFormatter, maxLabels
- labelRotation, labelOffset, labelStyle
- reservedSize

// Advanced
- highlightZeroLine, zeroLineColor, zeroLineWidth
- logarithmic, inverted
```

**Gap Summary:**
| Feature | YAxisConfig | AxisConfig (X-axis) | Gap Type |
|---------|-------------|---------------------|----------|
| Unit suffix support | ✅ `unit` field + `AxisLabelDisplay` | ❌ Not available | **MISSING** |
| Series color derivation | ✅ `color: null` → derive from series | ❌ Static colors only | **MISSING** |
| Label display modes | ✅ 7 modes via `AxisLabelDisplay` | ❌ Not available | **MISSING** |
| Crosshair label | ✅ `showCrosshairLabel`, `crosshairLabelPosition` | ❌ Not available | **MISSING** |
| Structured spacing | ✅ `tickLabelPadding`, `axisLabelPadding`, `axisMargin` | ⚠️ `labelPadding` only + hardcoded offsets | **PARTIAL** |
| Per-series config | ✅ `ChartSeries.yAxisConfig` | ❌ Global only | **MISSING** |
| Visibility control | ✅ `visible` (hide but keep normalization) | ⚠️ `showAxis` (simpler) | **PARTIAL** |
| Grid control | ⚠️ Delegated to GridRenderer | ✅ Inline grid properties | Different |
| Label rotation | ❌ Not available | ✅ `labelRotation` | X-axis has more |
| Logarithmic scale | ❌ Not available | ✅ `logarithmic` | X-axis has more |

### 2. Renderer Architecture Gap

**MultiAxisPainter (Y-axis):**
```dart
class MultiAxisPainter {
  // Rich caching system
  final Map<String, Map<double, TextPainter>> _tickLabelCache = {};
  final Map<String, TextPainter> _axisLabelCache = {};
  
  // Automatic cache invalidation
  void _invalidateCachesIfNeeded() { ... }
  
  // Color resolution via AxisColorResolver
  final axisColor = AxisColorResolver.resolveAxisColor(axis, bindings, series);
  
  // Label formatting with unit support
  String formatTickLabel(double value, YAxisConfig axis) {
    if (axis.shouldShowTickUnit && axis.unit != null) {
      formatted = '$formatted ${axis.unit}';
    }
    return formatted;
  }
  
  // Nice numbers algorithm for readable ticks
  List<double> generateTicks(DataRange bounds, {int maxTicks = 10}) { ... }
  
  // Layout integration
  final _layoutDelegate = const MultiAxisLayoutDelegate();
  final _layoutManager = const AxisLayoutManager();
}
```

**XAxisRenderer (X-axis) - Current:**
```dart
class XAxisRenderer {
  // No caching beyond Tick.getTextPainter()
  
  // No color resolution - uses static config colors
  final axisStyle = theme?.axisStyle;
  ..color = axisStyle?.lineColor ?? config.axisColor
  
  // No unit support in labels
  final textPainter = tick.getTextPainter(config.tickLabelStyle);
  
  // Hardcoded spacing
  final labelY = axisY + config.tickLength + config.labelPadding + 20; // +20!
  
  // No layout integration
  // No nice numbers algorithm (relies on Axis.ticks)
}
```

**Gap Summary:**
| Feature | MultiAxisPainter | XAxisRenderer | Gap |
|---------|------------------|---------------|-----|
| TextPainter caching | ✅ Full cache + invalidation | ⚠️ Relies on Tick class | Partial |
| Color resolution | ✅ AxisColorResolver | ❌ Static colors | **MISSING** |
| Unit formatting | ✅ `formatTickLabel()` | ❌ No unit support | **MISSING** |
| Nice numbers | ✅ `generateTicks()` | ⚠️ Uses Axis.ticks | Different approach |
| Structured spacing | ✅ Uses config properties | ❌ Hardcoded offsets | **MISSING** |
| Layout integration | ✅ LayoutDelegate + LayoutManager | ❌ None | **MISSING** |
| Default constants | ✅ 11px font, 4px padding | ⚠️ 10px font, 8px padding | Config mismatch |

### 3. Per-Series Binding Gap

**Y-Axis (how it works):**
```dart
// Series can declare its own Y-axis inline
LineChartSeries(
  id: 'power',
  points: [...],
  yAxisConfig: YAxisConfig(
    position: YAxisPosition.left,
    label: 'Power',
    unit: 'W',
    color: Colors.blue,
  ),
)

// Or reference a shared axis by ID
LineChartSeries(
  id: 'hr',
  points: [...],
  yAxisId: 'heartrate',  // References YAxisConfig with this ID
)
```

**X-Axis (how it works):**
```dart
// Global X-axis config on the chart widget
BravenChartPlus(
  series: [...],
  xAxis: AxisConfig(
    label: 'Time',
    // No per-series customization possible
  ),
)
```

**Gap:** No `xAxisConfig` on `ChartSeries`, no `xAxisId` for shared X-axes.

### 4. Crosshair Label Gap

**Y-Axis:**
```dart
YAxisConfig(
  showCrosshairLabel: true,  // Shows denormalized value
  crosshairLabelPosition: CrosshairLabelPosition.overAxis,  // or insidePlot
)
```

**X-Axis:** No equivalent. No crosshair X-value label support.

### 5. Label Display Modes Gap

**Y-Axis has 7 modes:**
```dart
enum AxisLabelDisplay {
  labelOnly,                  // Label = "Power", Ticks = "250"
  labelWithUnit,              // Label = "Power (W)", Ticks = "250"  ← DEFAULT
  labelAndTickUnit,           // Label = "Power", Ticks = "250 W"
  labelWithUnitAndTickUnit,   // Label = "Power (W)", Ticks = "250 W"
  tickUnitOnly,               // Label = none, Ticks = "250 W"
  tickOnly,                   // Label = none, Ticks = "250"
  none,                       // Hidden
}

// Helper methods
bool get shouldShowAxisLabel { ... }
bool get shouldAppendUnitToLabel { ... }
bool get shouldShowTickUnit { ... }
bool get shouldShowTickLabels { ... }
```

**X-Axis:** No equivalent. Just `showLabels: bool`.

---

## Proposed Solution

### Phase 1: Create XAxisConfig Model

Create a dedicated `XAxisConfig` class parallel to `YAxisConfig`:

```dart
// New file: lib/src/models/x_axis_config.dart

/// Position of X-axis relative to plot area.
enum XAxisPosition {
  bottom,      // Standard position below plot
  top,         // Above plot
  // Future: bottomOuter, topOuter for multi-X-axis
}

/// Configuration for X-axis in charts.
class XAxisConfig {
  const XAxisConfig({
    required this.position,
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showCrosshairLabel = false,
    this.crosshairLabelPosition = CrosshairLabelPosition.overAxis,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minHeight = 0.0,
    this.maxHeight = 60.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.labelFormatter,
    this.labelRotation = 0.0,
    // Grid properties (if we keep grid on X-axis config)
    this.showGrid = true,
    this.gridColor,
  });

  // ... properties parallel to YAxisConfig
}
```

### Phase 2: Create XAxisPainter

Create a dedicated painter parallel to `MultiAxisPainter`:

```dart
// New file: lib/src/rendering/x_axis_painter.dart

class XAxisPainter {
  // Same architecture as MultiAxisPainter:
  // - TextPainter caching with invalidation
  // - Color resolution via AxisColorResolver (extended for X-axis)
  // - Unit formatting support
  // - Nice numbers algorithm
  // - Structured spacing using config properties
  // - Layout integration
  
  void paint(Canvas canvas, Rect chartArea, Rect plotArea) { ... }
  
  List<double> generateTicks(DataRange bounds, {int maxTicks = 10}) { ... }
  
  String formatTickLabel(double value, XAxisConfig axis) { ... }
}
```

### Phase 3: Extend AxisColorResolver

Add X-axis support to `AxisColorResolver`:

```dart
// Update: lib/src/rendering/axis_color_resolver.dart

static Color resolveAxisColor(
  Object axis,  // YAxisConfig or XAxisConfig
  List<SeriesAxisBinding> bindings,
  List<ChartSeries> series, {
  Color defaultColor = defaultAxisColor,
}) {
  if (axis is YAxisConfig) {
    return _resolveYAxisColor(axis, bindings, series, defaultColor);
  } else if (axis is XAxisConfig) {
    return _resolveXAxisColor(axis, bindings, series, defaultColor);
  }
  return defaultColor;
}
```

### Phase 4: Add Per-Series X-Axis Binding

Extend `ChartSeries` to support X-axis configuration:

```dart
// Update: lib/src/models/chart_series.dart

abstract class ChartSeries {
  // Existing Y-axis binding
  final YAxisConfig? yAxisConfig;
  final String? yAxisId;
  
  // NEW: X-axis binding (optional)
  final XAxisConfig? xAxisConfig;
  final String? xAxisId;
}
```

### Phase 5: Update BravenChartPlus Widget

Update the widget to use the new X-axis system:

```dart
// Update: lib/src/braven_chart_plus.dart

class BravenChartPlus extends StatefulWidget {
  // DEPRECATED (keep for backward compat):
  final AxisConfig? xAxis;
  
  // NEW: Modern X-axis configuration
  final XAxisConfig? xAxisConfig;
}
```

### Phase 6: Visual Alignment (from original 015 spec)

Apply consistent defaults:
- Default font size: 11px (matching Y-axis)
- Default color: `Color(0xFF666666)` (matching Y-axis)
- Default spacing: 4px tick padding (matching Y-axis)
- Theme integration: Full `theme.axisStyle` support

---

## Scope Decisions

### In Scope

1. **XAxisConfig model** with parity to YAxisConfig
2. **XAxisPainter** with parity to MultiAxisPainter
3. **AxisColorResolver extension** for X-axis color derivation
4. **Per-series X-axis binding** (xAxisConfig property)
5. **Crosshair X-value label** support
6. **AxisLabelDisplay** support for X-axis
7. **Unit suffix** support for X-axis
8. **Structured spacing** (remove hardcoded offsets)
9. **Visual defaults alignment** (font, color, padding)
10. **Backward compatibility** with existing AxisConfig API

### Out of Scope (Future Work)

1. **Multi-X-axis support** (topOuter, bottomOuter positions) - complex layout implications
2. **X-axis normalization** - not needed currently (Y-axis normalization for overlays)
3. **X-axis scrollbar unification** - separate concern
4. **Logarithmic/inverted X-axis** - keep existing AxisConfig support

---

## Files to Create/Modify

### New Files
| File | Purpose |
|------|---------|
| `lib/src/models/x_axis_config.dart` | XAxisConfig model |
| `lib/src/models/x_axis_position.dart` | XAxisPosition enum |
| `lib/src/rendering/x_axis_painter.dart` | XAxisPainter class |
| `test/unit/axis/x_axis_config_test.dart` | Config model tests |
| `test/unit/rendering/x_axis_painter_test.dart` | Painter tests |

### Modified Files
| File | Changes |
|------|---------|
| `lib/src/rendering/axis_color_resolver.dart` | Add X-axis support |
| `lib/src/models/chart_series.dart` | Add xAxisConfig property |
| `lib/src/braven_chart_plus.dart` | Integrate XAxisPainter |
| `lib/braven_charts.dart` | Export new classes |
| `lib/src/axis/x_axis_renderer.dart` | Deprecate or delegate to XAxisPainter |

### Deprecated (Keep for Compatibility)
| File | Status |
|------|--------|
| `lib/src/axis/x_axis_renderer.dart` | Delegate to XAxisPainter |
| `BravenChartPlus.xAxis` parameter | Keep, prefer xAxisConfig |

---

## Success Criteria

| ID | Criterion | Verification |
|----|-----------|--------------|
| SC-1 | XAxisConfig has feature parity with YAxisConfig | Property comparison |
| SC-2 | XAxisPainter matches MultiAxisPainter architecture | Code review |
| SC-3 | X-axis supports unit suffixes | Unit test |
| SC-4 | X-axis derives color from series when not explicit | Unit test |
| SC-5 | Per-series xAxisConfig works | Widget test |
| SC-6 | Crosshair X-value label displays correctly | Widget test |
| SC-7 | AxisLabelDisplay modes work on X-axis | Unit tests |
| SC-8 | Visual defaults match Y-axis (11px, gray, 4px) | Visual inspection |
| SC-9 | All existing tests pass | CI/test suite |
| SC-10 | Backward compatibility with AxisConfig | Migration test |

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing AxisConfig users | High | Keep AxisConfig as fallback, auto-convert to XAxisConfig |
| Performance regression | Medium | Use same caching strategy as MultiAxisPainter |
| Complexity increase | Medium | Follow established patterns exactly |
| Scope creep into multi-X-axis | Low | Explicitly defer to future sprint |

---

## Estimated Effort

| Phase | Tasks | Estimate |
|-------|-------|----------|
| Phase 1: XAxisConfig model | 3-4 | 1 day |
| Phase 2: XAxisPainter | 5-6 | 2 days |
| Phase 3: AxisColorResolver | 1-2 | 0.5 day |
| Phase 4: Per-series binding | 2-3 | 0.5 day |
| Phase 5: Widget integration | 3-4 | 1 day |
| Phase 6: Visual alignment | 2-3 | 0.5 day |
| Testing & Polish | 4-5 | 1.5 days |
| **Total** | ~20-25 | **7 days** |

---

## References

### Source Files (for Speckit context)
- `lib/src/models/y_axis_config.dart` - Reference model (616 lines)
- `lib/src/rendering/multi_axis_painter.dart` - Reference renderer (556 lines)
- `lib/src/rendering/axis_color_resolver.dart` - Color resolution (124 lines)
- `lib/src/axis/x_axis_renderer.dart` - Current X-axis (133 lines)
- `lib/src/models/axis_config.dart` - Current X-axis config (476 lines)
- `lib/src/models/chart_series.dart` - Series model with yAxisConfig

### Previous Specs
- `specs/013-axis-renderer-unification/` - Y-axis unification (completed)
- `specs/014-x-axis-visual-unification/` - Superficial theming (superseded)
- `specs/015-x-axis-visual-unification/` - Superficial theming (superseded)
