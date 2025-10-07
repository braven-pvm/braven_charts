# Layer 5: Architecture Decision - BravenChart as Single Entry Point

**Date**: October 6, 2025  
**Status**: APPROVED  
**Decision ID**: ARCH-005-001

---

## Context

Initially, the Layer 5 specification had individual chart widgets (`LineChart`, `AreaChart`, `BarChart`, `ScatterChart`) as user-facing APIs. Users would directly instantiate these widgets, optionally wrapping them in a `BravenChart` container for titles, legends, and axes.

**The Problem**:
- Users bypassing `BravenChart` creates **rendering nightmares**:
  - Axis inconsistency (different charts using different axis calculations)
  - Resource management issues (who manages RenderPipeline lifecycle?)
  - Theme conflicts (charts inheriting different themes)
  - Legend aggregation becomes impossible
  - No centralized control over chart behavior

---

## Decision

**BravenChart is the ONLY user-facing widget in Layer 5.**

### Key Changes:

1. **Single Entry Point**:
   - Users **NEVER** use `LineChart`, `AreaChart`, `BarChart`, or `ScatterChart` directly
   - All charts are created via `BravenChart(chartType: ChartType.line)` etc.
   - Chart type is specified via `chartType` enum parameter

2. **Internal Widgets**:
   - `LineChart`, `AreaChart`, `BarChart`, `ScatterChart` become **internal implementation details**
   - These widgets are used by `BravenChart` internally based on `chartType`
   - Developers working ON the library see these, developers working WITH the library do not

3. **Axis Ownership**:
   - **BravenChart ALWAYS controls axes** (no exceptions)
   - Axes are highly customizable via `AxisConfig` class
   - Axes can be completely hidden for sparklines/embedded charts via `AxisConfig.hidden()`

4. **No CompositeChart Widget**:
   - Removed `FR-011: CompositeChart` - no longer needed
   - Multiple series rendered in same coordinate space via single `BravenChart` with list of series
   - Simpler mental model: one widget does everything

---

## Consequences

### Positive:

✅ **Simplified API**: One widget to learn (`BravenChart`)  
✅ **Consistent Rendering**: All charts use same axis calculation, theme, resource management  
✅ **No User Errors**: Users can't bypass container and create broken charts  
✅ **Better Resource Management**: Single point of control for RenderPipeline lifecycle  
✅ **Easier Documentation**: Document one widget instead of five  
✅ **Flexible Customization**: `AxisConfig` provides full control (including hiding axes)  

### Negative:

❌ **Internal Complexity**: `BravenChart` must handle switching between chart types  
❌ **Less Granular**: Advanced users can't mix-and-match widgets as easily  
❌ **Factory Pattern**: Need to ensure efficient chart type switching  

### Mitigated:

- Internal complexity is acceptable - it's hidden from users
- Advanced customization still available via `config` parameter
- Chart type switching is straightforward with good architecture

---

## API Examples

### Before (OLD - Mixed API):

```dart
// Users could do this (BAD - inconsistent axes)
LineChart(series: data1);  // Creates own axes
AreaChart(series: data2);  // Creates different axes

// OR this (GOOD - but users don't know which to use)
BravenChart(
  child: LineChart(series: data),
);
```

### After (NEW - Single Entry Point):

```dart
// Simple chart
BravenChart(
  chartType: ChartType.line,
  series: salesData,
  title: 'Sales Over Time',
)

// Sparkline (hidden axes)
BravenChart(
  chartType: ChartType.line,
  series: sparklineData,
  xAxis: AxisConfig.hidden(),
  yAxis: AxisConfig.hidden(),
)

// Fully customized axes
BravenChart(
  chartType: ChartType.line,
  series: temperatureData,
  xAxis: AxisConfig(
    label: 'Time',
    showGridLines: true,
    gridLineStyle: GridLineStyle.dashed,
    labelFormatter: (value) => DateFormat('HH:mm').format(value),
  ),
  yAxis: AxisConfig(
    label: 'Temperature (°C)',
    range: AxisRange.fixed(-10, 50),
    showGridLines: true,
    labelFormatter: (value) => '${value.toInt()}°C',
  ),
)

// Multiple series (all in same coordinate space)
BravenChart(
  chartType: ChartType.line,
  series: [blueSeries, greenSeries, orangeSeries, purpleSeries, yellowSeries],
  showLegend: true,
)
```

---

## AxisConfig Capabilities

The `AxisConfig` class provides **complete axis customization**:

### Visibility Control:
- `AxisConfig.defaults()` - Standard visible axes
- `AxisConfig.hidden()` - Completely hidden (for sparklines)
- `AxisConfig.minimal()` - Line only, no grid/ticks
- `AxisConfig.gridOnly()` - Grid only, no axis line/ticks

### Fine-Grained Control:
- **Axis Line**: color, width, style (solid/dashed/dotted)
- **Grid Lines**: color, width, style, minor grid lines
- **Ticks**: length, color, interval (auto/fixed/count)
- **Labels**: formatter, rotation, padding, decimal places
- **Range**: auto, fixed, min-only, max-only with padding
- **Position**: top/bottom (X-axis), left/right (Y-axis)
- **Advanced**: Zero line highlighting, custom tick positions

---

## Implementation Plan

### Phase 1: Update spec.md
- [x] Update FR-005 to emphasize BravenChart as ONLY user-facing widget
- [x] Remove FR-011 (CompositeChart)
- [x] Add comprehensive AxisConfig class definition
- [x] Update FR-001 to clarify LineChart is internal
- [ ] Update FR-002, FR-003, FR-004 to clarify internal status
- [ ] Update all remaining examples to use BravenChart
- [ ] Update testing section
- [ ] Update component structure

### Phase 2: Update Related Documents
- [ ] Update plan.md
- [ ] Update tasks.md
- [ ] Update acceptance criteria count
- [ ] Update widget hierarchy diagram

### Phase 3: Code Implementation
- [ ] Implement comprehensive AxisConfig class
- [ ] Implement BravenChart with chartType switching
- [ ] Implement internal chart widgets (Line/Area/Bar/Scatter)
- [ ] Write tests for new architecture

---

## Alternatives Considered

### Alternative 1: Keep Mixed API (Rejected)
- Allow both direct widget usage AND BravenChart
- **Rejected**: Leads to confusion, inconsistent usage patterns

### Alternative 2: Use Factories Instead of Enum (Rejected)
```dart
BravenChart.line(series: data)
BravenChart.area(series: data)
```
- **Rejected**: Less flexible for programmatic chart type selection

### Alternative 3: Separate Packages (Rejected)
- Create separate packages for each chart type
- **Rejected**: Overkill, creates dependency hell

---

## Decision Owners

- **Proposed by**: Development Team
- **Approved by**: Project Lead
- **Reviewed by**: Architecture Team

---

## References

- Layer 5 Specification: `docs/specs/005-chart-widgets/spec.md`
- Layer 4 Architecture: `docs/specs/004-chart-types/spec.md`
- Original Issue: User request on October 6, 2025

---

## Changelog

- **2025-10-06**: Initial decision document created
- **2025-10-06**: Updated FR-001, FR-005, FR-012 in spec.md
- **2025-10-06**: Added comprehensive AxisConfig class
- **2025-10-06**: Removed FR-011 (CompositeChart)
