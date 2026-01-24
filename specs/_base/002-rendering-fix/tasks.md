# 002-rendering-fix: Task List

## Status Legend

- ⬜ Not Started
- 🔄 In Progress
- ✅ Complete
- ⛔ Blocked

---

## Phase 1: Grouped Bar Charts

### Task 1.1: BarGroupInfo Class ⬜

**Priority**: P0  
**Estimate**: 0.5 hours  
**Dependencies**: None

**Deliverables**:

- [ ] Create `lib/src/models/bar_group_info.dart`
- [ ] Implement `BarGroupInfo` immutable class
- [ ] Add `calculateOffset()` method
- [ ] Add `calculateBarWidth()` method
- [ ] Export from `braven_charts.dart`

**Test Cases**:

- [ ] Single bar (count=1) returns zero offset
- [ ] Two bars: index=0 left of center, index=1 right of center
- [ ] Three bars: index=1 centered
- [ ] Gap pixels reduce individual bar width

---

### Task 1.2: SeriesElement Integration ⬜

**Priority**: P0  
**Estimate**: 0.5 hours  
**Dependencies**: Task 1.1

**Deliverables**:

- [ ] Add `BarGroupInfo? barGroupInfo` parameter to `SeriesElement` constructor
- [ ] Store in instance field `_barGroupInfo`
- [ ] Update `copyWith()` if present
- [ ] Pass to `_paintBarSeries()` call

**Files Modified**:

- `lib/src/elements/series_element.dart`

---

### Task 1.3: Paint Offset Calculation ⬜

**Priority**: P0  
**Estimate**: 2.0 hours  
**Dependencies**: Task 1.2

**Deliverables**:

- [ ] Modify `_paintBarSeries()` to accept/use `BarGroupInfo`
- [ ] Calculate effective bar width from group info
- [ ] Calculate X offset from group info
- [ ] Apply offset to bar rect construction
- [ ] Handle styled path (per-bar coloring) case

**Test Cases**:

- [ ] Two bar series don't overlap
- [ ] Bars are centered as a group on X value
- [ ] Individual bar colors still work
- [ ] Bar hover detection still works

---

### Task 1.4: Element Generator Update ⬜

**Priority**: P0  
**Estimate**: 1.0 hours  
**Dependencies**: Task 1.2

**Deliverables**:

- [ ] Locate element generation code (ChartRenderBox or generator)
- [ ] Count bar series in input list
- [ ] Track bar series index during iteration
- [ ] Create BarGroupInfo for each bar series
- [ ] Pass to SeriesElement constructor

**Files Modified**:

- `lib/src/rendering/chart_render_box.dart` (or element generator)
- `lib/src/utils/data_converter.dart` (if element creation is there)

---

### Task 1.5: Unit Tests ⬜

**Priority**: P1  
**Estimate**: 1.0 hours  
**Dependencies**: Task 1.3, Task 1.4

**Deliverables**:

- [ ] Create `test/unit/bar_group_info_test.dart`
- [ ] Test offset calculations
- [ ] Test width calculations
- [ ] Test edge cases (count=0, count=1)

---

### Task 1.6: Demo Verification ⬜

**Priority**: P1  
**Estimate**: 0.5 hours  
**Dependencies**: Task 1.4

**Deliverables**:

- [ ] Modify FitDistributionPage to use two BarChartSeries
- [ ] Verify bars render adjacent
- [ ] Take screenshot for verification
- [ ] Revert demo if needed (or keep as example)

---

## Phase 2: perSeries Y-Zoom Fix

### Task 2.1: computeAxisBounds forPainting Parameter ⬜

**Priority**: P0  
**Estimate**: 1.0 hours  
**Dependencies**: None

**Deliverables**:

- [ ] Add `forPainting` parameter to `computeAxisBounds()` signature
- [ ] Default to `false` for backward compatibility
- [ ] Update all existing call sites to explicitly pass `false`
- [ ] Document parameter behavior

**Files Modified**:

- `lib/src/rendering/modules/multi_axis_manager.dart`
- All callers of `computeAxisBounds()`

---

### Task 2.2: Viewport-Aware Bounds Logic ⬜

**Priority**: P0  
**Estimate**: 3.0 hours  
**Dependencies**: Task 2.1

**Deliverables**:

- [ ] Implement zoom-aware bounds when `forPainting=true`
- [ ] Calculate zoom ratio from normalized transform
- [ ] Calculate pan offset from normalized transform
- [ ] Apply to each axis's full bounds
- [ ] Handle edge cases (no zoom, partial zoom)

**Test Cases**:

- [ ] No zoom: forPainting bounds = display bounds
- [ ] 2x zoom: forPainting bounds = half the range
- [ ] Pan + zoom: bounds correctly offset and scaled

---

### Task 2.3: Paint Series Update ⬜

**Priority**: P0  
**Estimate**: 1.5 hours  
**Dependencies**: Task 2.2

**Deliverables**:

- [ ] Update `_paintSeries()` to call `computeAxisBounds(forPainting: true)`
- [ ] Verify per-series transforms use zoomed bounds
- [ ] Test series rendering clips to viewport correctly

**Files Modified**:

- `lib/src/rendering/chart_render_box.dart`

---

### Task 2.4: Crosshair/Tooltip Bounds ⬜

**Priority**: P0  
**Estimate**: 1.5 hours  
**Dependencies**: Task 2.2

**Deliverables**:

- [ ] Audit crosshair renderer for bounds usage
- [ ] Ensure value labels use display bounds (not painting)
- [ ] Audit tooltip renderer similarly
- [ ] Verify data values display correctly after zoom

**Files Modified**:

- `lib/src/rendering/modules/crosshair_renderer.dart`
- `lib/src/rendering/modules/tooltip_renderer.dart`

---

### Task 2.5: Integration Tests ⬜

**Priority**: P1  
**Estimate**: 2.0 hours  
**Dependencies**: Task 2.3, Task 2.4

**Deliverables**:

- [ ] Create test for Y-zoom with perSeries mode
- [ ] Create test for combined X+Y zoom
- [ ] Create test for zoom then pan
- [ ] Verify axis label updates

---

### Task 2.6: Demo Verification ⬜

**Priority**: P1  
**Estimate**: 0.5 hours  
**Dependencies**: Task 2.3

**Deliverables**:

- [ ] Test FitDistributionPage with Y-zoom
- [ ] Verify Shift+scroll zooms both axes
- [ ] Verify scrollbar edge drag works
- [ ] Take screenshot for verification

---

## Phase 3: Integration & Polish

### Task 3.1: Regression Testing ⬜

**Priority**: P0  
**Estimate**: 1.5 hours  
**Dependencies**: Phase 1, Phase 2

**Deliverables**:

- [ ] Run full test suite
- [ ] Fix any failing tests
- [ ] Run `flutter analyze`
- [ ] Fix all analyzer issues

---

### Task 3.2: Performance Benchmarks ⬜

**Priority**: P1  
**Estimate**: 1.0 hours  
**Dependencies**: Task 3.1

**Deliverables**:

- [ ] Run existing performance benchmarks
- [ ] Compare with baseline
- [ ] Document any changes
- [ ] Optimize if >10% regression

---

### Task 3.3: Documentation ⬜

**Priority**: P2  
**Estimate**: 1.0 hours  
**Dependencies**: Task 3.1

**Deliverables**:

- [ ] Update API docs for BarGroupInfo
- [ ] Update multi-axis documentation
- [ ] Add grouped bar example to docs
- [ ] Update changelog

---

## Summary

| Phase     | Tasks        | Hours    | Status |
| --------- | ------------ | -------- | ------ |
| Phase 1   | 1.1 - 1.6    | 5.5      | ⬜     |
| Phase 2   | 2.1 - 2.6    | 9.5      | ⬜     |
| Phase 3   | 3.1 - 3.3    | 3.5      | ⬜     |
| **Total** | **15 tasks** | **18.5** |        |
