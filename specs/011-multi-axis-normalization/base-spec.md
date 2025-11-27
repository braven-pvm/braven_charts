# Feature Specification: Multi-Axis Normalization

**Spec ID**: 011-multi-axis-normalization  
**Date**: 2025-11-27  
**Status**: DRAFT - Awaiting SpecKit Process  
**Author**: Copilot + User Collaboration

---

## 1. Executive Summary

### Problem Statement

Scientific and athletic performance visualization frequently requires displaying multiple data series with vastly different Y-axis ranges on the same chart. For example:

| Series | Unit | Typical Range | Scale Factor |
|--------|------|---------------|--------------|
| Power | W (Watts) | 0-300 | 1x |
| Heart Rate | bpm | 60-200 | ~0.7x |
| Cadence | rpm | 60-120 | ~0.4x |
| Tidal Volume | L | 0.5-4.0 | ~0.01x |
| Respiratory Rate | bpm | 10-40 | ~0.13x |

When plotted on a single Y-axis, series with smaller ranges appear as flat lines, making the data unreadable.

### Proposed Solution

Implement **multi-axis normalization** where:
1. Each series is internally normalized to fit the full chart height
2. Multiple color-coded Y-axes display original values for each series
3. All user-facing displays (tooltips, crosshair, labels) show original values
4. Auto-detection triggers normalization when series ranges differ significantly

### Reference Implementation

See attached VO2master screenshot showing:
- 4 distinct Y-axes (2 left, 2 right)
- Color-coded axes matching series colors
- Original values displayed on each axis
- All series rendered in same plot area despite 100x+ scale differences

---

## 2. User Stories

### US-001: Multi-Scale Data Visualization
**As a** sports scientist  
**I want to** display power, heart rate, and respiratory metrics on one chart  
**So that** I can correlate physiological responses without switching views

**Acceptance Criteria**:
- [ ] All series visible and distinguishable regardless of Y-range differences
- [ ] Each series uses full vertical space (not squashed to bottom)
- [ ] Original Y values displayed on corresponding axis

### US-002: Automatic Normalization Detection
**As a** developer  
**I want** the chart to automatically detect when series need normalization  
**So that** I don't need to manually configure multi-axis mode

**Acceptance Criteria**:
- [ ] Auto-detection when series ranges differ by >10x
- [ ] Opt-out available via configuration
- [ ] Manual override to force single/multi axis mode

### US-003: Color-Coded Axis Identification
**As a** user viewing a multi-axis chart  
**I want** each Y-axis to match the color of its series  
**So that** I can easily identify which axis corresponds to which data

**Acceptance Criteria**:
- [ ] Axis labels/ticks use series color
- [ ] Clear visual association between axis and line
- [ ] Works in light and dark themes

### US-004: Crosshair with Original Values
**As a** user hovering over the chart  
**I want** the crosshair to show original Y values for each series  
**So that** I can read actual data values, not normalized percentages

**Acceptance Criteria**:
- [ ] Tooltip shows original Y value per series
- [ ] Value formatted with appropriate unit (W, bpm, L, etc.)
- [ ] Tracking mode displays all intersected series values

---

## 3. Functional Requirements

### FR-001: Y-Axis Binding
Each series MUST be bindable to a specific Y-axis configuration.

```dart
LineChartSeries(
  id: 'power',
  yAxisId: 'primary',  // NEW: Links to YAxisConfig
  ...
)
```

### FR-002: Multiple Y-Axis Configuration
The chart MUST support up to 4 Y-axes with configurable positions.

```dart
enum YAxisPosition {
  leftOuter,   // Leftmost axis
  left,        // Inner left axis (default primary)
  right,       // Inner right axis
  rightOuter,  // Rightmost axis
}
```

### FR-003: Per-Axis Data Bounds
Each Y-axis MUST maintain its own min/max bounds, either:
- Auto-computed from bound series data
- Explicitly configured by developer

### FR-004: Internal Normalization
When multiple Y-axes are active, the rendering engine MUST:
1. Normalize each series Y-values to [0, 1] range using its axis bounds
2. Render all series in the same plot area
3. Maintain original Y values for all display purposes

### FR-005: Axis Label Rendering
Each Y-axis MUST render tick labels using:
- Original data values (not normalized)
- Appropriate number formatting
- Optional unit suffix (W, bpm, L/min, etc.)

### FR-006: Color-Coded Axes
When a Y-axis is bound to a single series, the axis MUST:
- Use the series color for tick labels and axis line
- Support explicit color override

### FR-007: Auto-Detection Mode
The chart MUST support automatic multi-axis activation when:
- Multiple series present
- Series Y-ranges differ by more than configurable threshold (default: 10x)

### FR-008: Grid Lines Behavior
When multi-axis normalization is active:
- Grid lines MUST be disabled (avoids confusion with multiple scales)
- Option to show grid for primary axis only (future consideration)

### FR-009: Shared Axis Support
Multiple series MAY share the same Y-axis if they:
- Have the same or similar units
- Have comparable ranges
- Are explicitly bound to same axis ID

### FR-010: Threshold Annotation Handling
When threshold annotations are used with normalized series:
- Threshold MUST specify which Y-axis it applies to
- OR threshold displays values for all series at that screen position

---

## 4. Success Criteria

### SC-001: Rendering Performance
- 60 FPS maintained with 4 series, 1000+ points each, 4 Y-axes
- Normalization calculation adds <1ms per frame
- No increased memory per data point

### SC-002: Visual Clarity
- Each series fully visible using complete vertical plot space
- Axis-to-series association immediately clear via color coding
- No overlapping axis labels (automatic spacing)

### SC-003: Value Accuracy
- All displayed Y-values match original data values exactly
- No rounding errors from normalization visible to user
- Crosshair/tooltip values consistent with axis labels

### SC-004: Backward Compatibility
- Single Y-axis mode (current behavior) unchanged when:
  - Only one series present
  - Auto-detection disabled and no explicit multi-axis config
  - All series have similar Y-ranges

---

## 5. Non-Functional Requirements

### NFR-001: Performance Budget
- Normalization computation: O(1) per point (pre-computed bounds)
- Axis rendering: <2ms per axis
- Total multi-axis overhead: <5ms per frame

### NFR-002: Memory Constraints
- No additional memory per data point
- Per-axis metadata: O(A) where A = number of axes (max 4)
- Per-series metadata: O(S) where S = number of series

### NFR-003: API Ergonomics
- Simple cases (2 series, auto-detect) require zero configuration
- Complex cases (4 axes, custom colors) remain declarative
- Progressive disclosure of complexity

---

## 6. Technical Constraints

### TC-001: Coordinate Space
Must integrate with existing `ChartTransform` without breaking:
- Pan/zoom functionality
- Hit testing
- Crosshair tracking
- Viewport culling

### TC-002: Existing Axis System
Must extend, not replace, current `AxisConfig`:
- Backward compatible API
- Reuse axis rendering logic where possible
- Support existing axis features (grid, labels, ticks)

### TC-003: Series Types
Must work with all series types:
- LineChartSeries
- AreaChartSeries
- ScatterChartSeries
- BarChartSeries (may need special handling)

---

## 7. Out of Scope (Phase 1)

- Logarithmic Y-axis scale
- Secondary X-axes
- Axis break/discontinuity
- Interactive axis dragging to reorder
- Per-axis zoom (all axes zoom together)

---

## 8. Open Questions

### OQ-001: Series-to-Axis Binding Syntax
**Options**:
A) `yAxisId` on series, separate `yAxes` list on chart
B) Inline `YAxisConfig` on each series
C) Grouped series configuration

**Current Preference**: Option A (cleaner separation)

### OQ-002: Default Axis Assignment
When no `yAxisId` specified:
A) Use primary axis (left)
B) Auto-assign to next available axis
C) Error if multi-axis mode is forced

**Current Preference**: Option A (backward compatible)

### OQ-003: Axis Spacing
How much horizontal space per axis?
- Fixed width (e.g., 60px)
- Dynamic based on label width
- Configurable

**Current Preference**: Dynamic with configurable min/max

### OQ-004: Legend Enhancement
Should legend show per-series Y-range info?
- Just color + name (current)
- Color + name + range (e.g., "Power (60-240W)")
- Color + name + current value

**Current Preference**: Color + name (keep simple for now)

---

## 9. Clarifications Received

| Question | Answer | Date |
|----------|--------|------|
| Max number of Y-axes | 4 (leftOuter, left, right, rightOuter) | 2025-11-27 |
| Can multiple series share axis? | Yes, if apparent to user | 2025-11-27 |
| Threshold annotation handling | Same color as series, OR show all values | 2025-11-27 |
| Grid lines in multi-axis mode | Disable (avoid confusion) | 2025-11-27 |
| Display values | ALWAYS original Y-values everywhere | 2025-11-27 |
| Auto-detection | Yes, when ranges differ significantly | 2025-11-27 |

---

## 10. Reference Materials

### VO2master Screenshot Analysis
![VO2master Multi-Axis Chart](../../docs/design/vo2master-reference.png)

Key observations:
1. Left side: "Ventilation" (0-40) in gray, "Tv" (0-4) in orange
2. Right side: Multiple scales (0-300, 0-120) for different metrics
3. Top header: Per-series stats (Min/Max/Avg) with units
4. Legend: Color-coded series identification
5. All lines use full vertical space despite 100x+ range differences

### Similar Implementations
- TradingView: Dual Y-axis for price + volume
- Excel: Secondary axis for combo charts
- Matplotlib: `twinx()` for secondary Y-axis
- Highcharts: Multiple Y-axes with series binding

---

## 11. Appendix: Proposed Data Model (Draft)

```dart
/// Y-axis configuration for multi-axis charts
class YAxisConfig {
  /// Unique identifier for axis binding
  final String id;
  
  /// Position of axis relative to plot area
  final YAxisPosition position;
  
  /// Axis color (defaults to first bound series color)
  final Color? color;
  
  /// Axis label (e.g., "Power", "Heart Rate")
  final String? label;
  
  /// Unit suffix for tick labels (e.g., "W", "bpm")
  final String? unit;
  
  /// Explicit min value (null = auto from data)
  final double? min;
  
  /// Explicit max value (null = auto from data)
  final double? max;
  
  /// Whether to show tick marks
  final bool showTicks;
  
  /// Whether to show axis line
  final bool showAxisLine;
}

/// Updated series with axis binding
class LineChartSeries extends ChartSeries {
  /// ID of Y-axis to use (null = primary/default axis)
  final String? yAxisId;
  
  /// Unit for this series (displayed in tooltips)
  final String? unit;
  
  // ... existing fields
}

/// Widget configuration update
class BravenChartPlus {
  /// Multiple Y-axis configurations (null = single axis mode)
  final List<YAxisConfig>? yAxes;
  
  /// Normalization behavior
  final NormalizationMode normalizationMode;
  
  // ... existing fields
}

/// Normalization mode options
enum NormalizationMode {
  /// No normalization, use global Y bounds (current behavior)
  none,
  
  /// Auto-detect when series ranges differ significantly
  auto,
  
  /// Always normalize each series to its own range
  perSeries,
}
```

---

## Next Steps

1. **Run SpecKit Process**: `/speckit.plan` to generate research and design phases
2. **Technical Research**: Investigate integration points with ChartTransform
3. **Prototype**: Create minimal multi-axis rendering proof-of-concept
4. **Design Review**: Validate axis layout and spacing algorithms
5. **Implementation**: Phase-by-phase development with TDD

---

*Document Version: 1.0 DRAFT*
*Last Updated: 2025-11-27*
