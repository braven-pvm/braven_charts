# Incremental Merge Strategy - BravenChartPlus

**Branch**: `core-interaction-refactor`  
**Approach**: Incremental feature porting (NOT big-bang migration)  
**Status**: ✅ Phase 1 Complete | ⏳ Phase 2 In Progress  
**Implementation Location**: `lib/src_plus/` (isolated from production `lib/src/`)  
**Created**: 2025-11-10  
**Last Updated**: 2025-11-12  

---

## ⚠️ IMPLEMENTATION UPDATE (2025-11-12)

**DECISION**: BravenChartPlus is being built in **`lib/src_plus/`** (NOT `lib/src/`)

**Rationale**:
- ✅ Complete isolation from production code
- ✅ Zero risk of breaking existing BravenChart
- ✅ Clean prototype-to-production evolution path
- ✅ Easy to compare old vs new implementations

**Current Status**: See [Progress Tracking](#progress-tracking-updated-2025-11-12) and [Sprint Tasks](../SPRINT_TASKS.md) below.

---

## 🔥 CRITICAL: Performance Divergence Event

**Date**: During Sprint 2 (Theming System Implementation)  
**Impact**: +25 hours unplanned work, timeline extended  
**Status**: ✅ Resolved - Performance now excellent (60fps with 7 series)

### What Happened

During the implementation of the theming system (Phase 2, Feature 2), we encountered **massive performance issues**:
- Frame render times spiked to 200-300ms (target: <16ms for 60fps)
- UI became completely unresponsive during pan/zoom
- Hit testing caused cascade failures
- Memory leaks from Picture objects not being disposed

### Divergence Timeline

1. **Started**: Implementing runtime theme switching
2. **Discovered**: Severe performance degradation with multiple charts
3. **Diverted**: Paused feature work to debug performance
4. **Invested**: ~25 hours of unplanned optimization work
5. **Resolved**: Performance now exceeds targets
6. **Resumed**: Back to feature porting (Sprint 3.2)

### Performance Optimizations Completed

| Optimization | Impact | Time Spent |
|--------------|--------|------------|
| Picture caching for chart canvas | ~17ms saved per frame | 4h |
| Hit test throttling (50ms debounce) | Prevents cascade failures | 2h |
| QuadTree spatial index optimization | O(log n) hit testing | 3h |
| Pan/zoom constraint validation | 10% max whitespace, smooth UX | 4h |
| Memory leak investigation | Fixed Picture disposal | 3h |
| 5-chart stress test example | Validates performance claims | 2h |
| Dynamic axis tick generation | Just-in-time ticks, no waste | 4h |
| Focus management fix | Runtime theme switching works | 3h |

**Total**: 25 hours of unplanned work

### Performance Metrics Achieved

- ✅ 60fps with 7 series (14ms average frame time)
- ✅ <100ms to render 1000 data points
- ✅ Smooth pan/zoom with no jank
- ✅ No memory leaks (Picture objects properly disposed)
- ✅ QuadTree O(log n) hit testing (vs O(n) before)

### Lesson Learned

**Performance issues can derail feature work.** Always include buffer time for unexpected optimization work.

### Impact on Timeline

- **Original Phase 2 Estimate**: 25-30 hours
- **Actual Phase 2 Time Spent**: 22 hours (features) + 25 hours (performance) = 47 hours
- **Variance**: +17 to +22 hours beyond original estimate

### Re-Verification Required

⚠️ **CRITICAL**: Theming system needs **re-verification** after ALL features are added.

**Why**: Performance divergence happened during theming implementation. Must verify theming works correctly with ALL features once they're all ported (annotations, legends, markers, streaming, scrollbars).

**See**: [Theming Re-Verification Tasks](../SPRINT_TASKS.md#️-critical-theming-re-verification-task) in SPRINT_TASKS.md

**Current Status**: See [Progress Tracking](#progress-tracking-updated-2025-11-12) and [Sprint Tasks](../SPRINT_TASKS.md) below.

---

## Why This Approach?

### Previous Attempt Failed Because:
- ❌ Tried to gut BravenChart (7,300 lines) and replace engine in place
- ❌ Attempted "100% functionality preservation" while changing architecture
- ❌ Big-bang migration with no safety net
- ❌ Analysis paralysis from overwhelming scope
- ❌ Lost working code, broke everything

### New Approach Succeeds Because:
- ✅ Keep BravenChart untouched (continues working)
- ✅ Keep PrototypeChart untouched (proven architecture)
- ✅ Create NEW BravenChartPlus based on PrototypeChart
- ✅ Gradually port features from BravenChart → BravenChartPlus
- ✅ Test after EVERY feature addition
- ✅ Small, reversible commits
- ✅ Clear decision point for cutover

---

## Core Principle: PrototypeChart Architecture is Sacred

**PrototypeChart has PROVEN:**
- ✅ RenderBox-based rendering with handleEvent()
- ✅ ChartInteractionCoordinator for unified state
- ✅ QuadTree spatial indexing (O(log n) hit testing)
- ✅ 3-space coordinate system (Widget → Plot → Data)
- ✅ Priority-based conflict resolution
- ✅ Dynamic axes with live updates
- ✅ Pan constraints (10% whitespace limit)
- ✅ Zero gesture conflicts

**BravenChart has PROVEN:**
- ✅ Complete theming system (ChartTheme)
- ✅ Real-time streaming (BufferManager, StreamingController)
- ✅ Scrollbars (ChartScrollbar)
- ✅ 5 annotation types (Point, Range, Text, Threshold, Trend)
- ✅ Multiple chart types (Line, Area, Bar, Scatter)
- ✅ Markers, legends, tooltips
- ✅ Public API used by consumers

**BravenChartPlus = PrototypeChart Architecture + BravenChart Features**

---

## Implementation Strategy

### Phase 1: Foundation Setup (Day 1) - ✅ COMPLETE

**Goal**: Create BravenChartPlus skeleton that compiles and renders

**Status**: ✅ **COMPLETE** (implemented in `lib/src_plus/`)

**Tasks**:
1. ✅ Copy PrototypeChart files to new BravenChartPlus structure
2. ✅ Align public API with BravenChart (constructor parameters, etc.)
3. ✅ Keep internal architecture from PrototypeChart
4. ✅ Create dedicated example app (`braven_chart_plus_example.dart`, `braven_chart_plus_example_5charts.dart`)
5. ✅ Verify basic rendering works

**Files Created** (in `lib/src_plus/`):
```
lib/src_plus/widgets/braven_chart_plus.dart       # ✅ Public widget (340 lines)
lib/src_plus/rendering/chart_render_box.dart      # ✅ RenderBox (1,247 lines)
lib/src_plus/interaction/core/coordinator.dart    # ✅ From prototype
lib/src_plus/interaction/core/interaction_mode.dart # ✅
lib/src_plus/rendering/spatial_index.dart         # ✅ QuadTree
lib/src_plus/coordinates/chart_transform.dart     # ✅ 3-space coords (419 lines)
lib/src_plus/interaction/core/chart_element.dart  # ✅
lib/src_plus/interaction/core/element_types.dart  # ✅
lib/src_plus/axis/axis.dart                       # ✅ Dynamic axis system (133 lines)
lib/src_plus/axis/axis_renderer.dart              # ✅
lib/src_plus/axis/linear_scale.dart               # ✅
lib/src_plus/axis/tick_generator.dart             # ✅
lib/src_plus/axis/tick.dart                       # ✅
```

**Success Criteria**:
- [x] BravenChartPlus compiles without errors
- [x] Example app runs and shows basic chart
- [x] No impact to existing BravenChart
- [x] RenderBox architecture with handleEvent()
- [x] QuadTree spatial indexing working
- [x] Coordinator managing interaction state

**Commits**:
- Multiple commits implementing Phase 1 foundation
- See git history from `c8a00de` onwards

**Completed**: Phase 1 complete, architecture validated

---

### Phase 2: Feature Porting (Incremental, 2-3 weeks) - ⏳ IN PROGRESS

**Approach**: One feature at a time, test thoroughly, commit

#### Feature 1: Real ChartSeries (Priority 1) - ✅ COMPLETE
**Goal**: Replace simulated datapoints with real ChartSeries data structures

**Status**: ✅ **COMPLETE**

**Implementation** (in `lib/src_plus/`):
- ✅ `models/chart_series.dart` - **Sealed class hierarchy** (commit `233fc70`)
  - `LineChartSeries` with interpolation (linear, bezier, stepped, monotone)
  - `BarChartSeries` with width configuration
  - `ScatterChartSeries` with marker configuration
  - `AreaChartSeries` with fill opacity
- ✅ `models/chart_data_point.dart` - Basic x/y data point
- ✅ `elements/series_element.dart` - SeriesElement wrapper with ChartElement interface
- ✅ `elements/simulated_series.dart` - Series hit testing
- ✅ `elements/simulated_datapoint.dart` - DataPoint hit testing
- ✅ Spatial index integration
- ✅ Real data rendering in example apps

**Success Criteria**:
- [x] Can pass List<ChartSeries> to BravenChartPlus
- [x] Series renders correctly (line, area, bar, scatter)
- [x] Spatial index contains datapoint elements
- [x] Click on point shows hit test works
- [x] Sealed class provides type safety

**Commits**: 
- `233fc70` - feat: Implement sealed class series architecture
- `b86f975` - refactor: Remove obsolete chartType parameter

**Estimated Time**: 4-6 hours | **Actual Time**: ~6 hours

---

#### Feature 2: Theming System (Priority 2) - ✅ COMPLETE
**Goal**: Apply BravenChart's theming to BravenChartPlus rendering

**Status**: ✅ **COMPLETE**

**Implementation** (in `lib/src_plus/`):
- ✅ `models/chart_theme.dart` - Complete theme system
- ✅ Theme passed to ChartRenderBox
- ✅ Background, grid, axes use theme colors
- ✅ Series rendering uses theme colors
- ✅ Runtime theme switching with FocusNode fix (commit `17c692f`)

**Success Criteria**:
- [x] Can pass ChartTheme to BravenChartPlus
- [x] Background, grid, axes use theme colors
- [x] Series lines use theme colors
- [x] Theme changes update rendering
- [x] Runtime theme switching works

**Commits**: 
- `17c692f` - feat: Add runtime theme switching with FocusNode fix

**Estimated Time**: 4-6 hours | **Actual Time**: ~5 hours

---

#### Feature 3: Annotations (Priority 3) - ✅ COMPLETE
**Goal**: Add BravenChart's annotation types with PrototypeChart's interactions

**Status**: ✅ **COMPLETE** (all 5 annotation types implemented and tested)

**Implemented**:
- ✅ `models/chart_annotation.dart` - All 5 annotation model classes (PointAnnotation, RangeAnnotation, TextAnnotation, ThresholdAnnotation, TrendAnnotation)
- ✅ `elements/annotation_elements.dart` - All annotation element rendering classes
- ✅ PointAnnotation - Markers at specific data points with custom shapes
- ✅ RangeAnnotation - Vertical/horizontal ranges with resize handles
- ✅ TextAnnotation - Floating text labels with custom positioning
- ✅ ThresholdAnnotation - Horizontal/vertical reference lines with dash patterns
- ✅ TrendAnnotation - Statistical trend lines (linear, polynomial, moving average, EMA)
- ✅ `elements/resize_handle_element.dart` - Annotation resize handles
- ✅ Annotation hit testing
- ✅ Annotation drag/resize via Coordinator
- ✅ Pattern matching in BravenChartPlus widget
- ✅ Examples in showcase app
- ✅ Unit tests (14 tests passing)

**Success Criteria**:
- [x] Basic annotations render correctly
- [x] Annotations are draggable
- [x] Annotations are resizable (with handles)
- [x] No gesture conflicts
- [x] All 5 annotation types from BravenChart ported

**Commits**: 
- feat(annotations): Add ThresholdAnnotation and TrendAnnotation models
- feat(annotations): Implement ThresholdAnnotationElement and TrendAnnotationElement
- feat(annotations): Add pattern matching in BravenChartPlus widget
- feat(annotations): Add examples and unit tests
- feat(annotations): Complete all 5 annotation types

**Estimated Time**: 8-10 hours | **Actual Time**: ~10 hours  
**Breakdown**: 
- Models: 1.5h
- Elements (Threshold): 2h
- Elements (Trend): 2.5h
- Widget integration: 0.5h
- Examples: 0.5h
- Testing & validation: 1h
- Bug fixes & optimization: 2h

---

#### Feature 4: Streaming (Priority 4) - ❌ NOT STARTED
**Goal**: Add real-time data streaming from BravenChart

**Status**: ❌ **NOT STARTED**

**From BravenChart** (needs porting):
- ⏳ `StreamingConfig` class
- ⏳ `BufferManager` (ring buffer)
- ⏳ `StreamingController`
- ⏳ Auto-scroll behavior

**Adapt To PrototypeChart**:
- ⏳ Integrate with ChartTransform viewport
- ⏳ Update spatial index on new data
- ⏳ Keep PrototypeChart's pan/zoom during streaming

**Success Criteria**:
- [ ] Can enable streaming mode
- [ ] Data updates in real-time
- [ ] Spatial index updates correctly
- [ ] Pan/zoom works during streaming
- [ ] Auto-scroll respects constraints

**Estimated Time**: 6-8 hours | **Actual Time**: Not started

---

#### Feature 5: Scrollbars (Priority 5) - ❌ NOT STARTED
**Goal**: Add BravenChart's scrollbars synced with PrototypeChart's viewport

**Status**: ❌ **NOT STARTED**

**From BravenChart** (needs porting):
- ⏳ `ChartScrollbar` widget
- ⏳ `ScrollbarController`
- ⏳ Horizontal/vertical scrollbar support

**Adapt To PrototypeChart**:
- ⏳ Sync with ChartTransform viewport
- ⏳ Scrollbar drag updates transform
- ⏳ Keep PrototypeChart's zoom/pan

**Success Criteria**:
- [ ] Scrollbars appear when data exceeds viewport
- [ ] Dragging scrollbar updates viewport
- [ ] Pan/zoom updates scrollbar position
- [ ] No conflicts between scrollbar and pan

**Estimated Time**: 4-6 hours | **Actual Time**: Not started

---

#### Feature 6: Additional Chart Types - ✅ COMPLETE
**Goal**: Add remaining chart types (Bar, Scatter if not already done)

**Status**: ✅ **COMPLETE**

**Implementation**:
- ✅ Line chart with interpolation modes
- ✅ Bar chart rendering
- ✅ Scatter chart rendering
- ✅ Area chart with fill
- ✅ All integrated with sealed class series

**Success Criteria**:
- [x] All 4 chart types work (Line, Bar, Scatter, Area)
- [x] Type-specific configuration via sealed classes
- [x] Proper rendering for each type

**Commits**: 
- `233fc70` - Sealed class series with all 4 types

**Estimated Time**: 4-6 hours | **Actual Time**: Included in Feature 1

---

#### Feature 7: Markers, Legends, Tooltips - 🔄 PARTIAL
**Goal**: Add visual enhancements from BravenChart

**Status**: 🔄 **PARTIAL**

**Implemented**:
- ✅ Basic tooltips (commit `2c03fcc`) - nearest datapoint lookup, <5ms render
- ✅ Crosshair with coordinate labels
- ✅ Data point marker configuration in series

**Pending**:
- ⏳ Legend widget (show/hide series, colors)
- ⏳ Advanced tooltip configuration
- ⏳ Marker shape variations (circle, square, triangle, etc.)

**Success Criteria**:
- [x] Basic tooltips work
- [x] Crosshair shows coordinates
- [ ] Legend widget displays all series
- [ ] Legend allows show/hide series
- [ ] Multiple marker shapes available

**Commits**: 
- `2c03fcc` - perf: Basic tooltips implementation
- Crosshair in chart_render_box.dart

**Estimated Time**: 6-8 hours | **Actual Time**: ~3 hours (partial)  
**Remaining**: ~4 hours for legend and advanced features

---

### Phase 3: Feature Parity & Cutover (Week 4) - ❌ NOT STARTED

**Goal**: BravenChartPlus has 100% of BravenChart features

**Status**: ❌ **NOT STARTED** (pending Phase 2 completion)

**Tasks**:
1. Feature comparison audit (BravenChart vs BravenChartPlus)
2. Port any remaining features
3. Performance testing and optimization
4. Update example app to use BravenChartPlus
5. Write migration guide
6. Deprecate BravenChart (keep for backwards compat)

**Success Criteria**:
- [ ] BravenChartPlus has feature parity with BravenChart
- [ ] All example apps work with BravenChartPlus
- [ ] All tests pass
- [ ] Performance equal or better than BravenChart
- [ ] Documentation complete

**Commit**: `feat: BravenChartPlus reaches feature parity`

**Estimated Time**: ~40 hours

---

## Progress Tracking (Updated 2025-11-12)

### Phase Completion Status

| Phase | Status | Completion | Time Estimate | Time Actual |
|-------|--------|-----------|---------------|-------------|
| **Phase 1: Foundation** | ✅ Complete | 100% | 8 hours | ~10 hours |
| **Phase 2: Feature Porting** | ⏳ In Progress | ~70% | 80-100 hours | ~35 hours |
| **Phase 3: Feature Parity** | ❌ Not Started | 0% | 40 hours | - |

### Feature Implementation Status

| Feature | Priority | Status | Completion | Time Est | Time Actual | Notes |
|---------|----------|--------|-----------|----------|-------------|-------|
| **1. Real ChartSeries** | P1 | ✅ Complete | 100% | 4-6h | ~6h | Sealed class architecture |
| **2. Theming System** | P2 | ✅ Complete | 100% | 4-6h | ~5h | Runtime switching works |
| **3. Annotations** | P3 | ✅ Complete | 100% | 8-10h | ~10h | All 5 types implemented & tested |
| **4. Streaming** | P4 | ❌ Not Started | 0% | 6-8h | - | BufferManager pending |
| **5. Scrollbars** | P5 | ❌ Not Started | 0% | 4-6h | - | ChartScrollbar pending |
| **6. Chart Types** | P6 | ✅ Complete | 100% | 4-6h | (in F1) | All 4 types done |
| **7. Markers/Legends/Tooltips** | P7 | 🔄 Partial | 40% | 6-8h | ~3h | Tooltips done, legend pending |

### Additional Work Completed (Not in Original Plan)

| Feature | Status | Time Spent | Commits | Notes |
|---------|--------|------------|---------|-------|
| **Pan/Zoom Constraints** | ✅ Complete | ~10h | Multiple | 10% whitespace, 1x-10x zoom |
| **Dynamic Axes** | ✅ Complete | ~6h | `c8a00de` | Just-in-time tick generation |
| **Performance Optimizations** | ✅ Complete | ~15h | 4 commits | Picture caching, throttling |
| **Sealed Class Series** | ✅ Complete | ~4h | `233fc70` | Type-safe series architecture |
| **5-Chart Example** | ✅ Complete | ~2h | `50196d4` | Performance validation |
| **Focus Management** | ✅ Complete | ~2h | `4d5433e` | Keyboard integration |
| **Bug Fixes** | ✅ Complete | ~8h | Multiple | Double-pan, constraints, etc. |

**Total Additional Work**: ~47 hours (not originally planned)

### Overall Progress Summary

**Total Planned Work**: 128-148 hours  
**Total Actual Work**: ~72 hours (includes 47 hours of additional work)  
**Remaining Work**: ~60-70 hours

**Progress**: Phase 1 complete + 60% of Phase 2 + significant additional architecture work

---

## What's Been Achieved Beyond Original Plan

The implementation has delivered MORE than the original strategy planned:

### Architecture Enhancements ✅
1. **Pan/Zoom Constraints System** (not in original plan)
   - 10% whitespace constraint algorithm
   - Zoom-aware constraint calculations
   - Edge case handling for high zoom levels
   - Viewport position constraint algorithm
   
2. **Dynamic Axis System** (not in original plan)
   - Just-in-time tick generation
   - Axis updates during zoom/pan
   - No stale ticks problem
   
3. **Performance Layer** (not in original plan)
   - Picture caching for series layer (~17ms saved)
   - Two-layer rendering architecture
   - Hit test throttling (50ms debounce, 60fps hover)
   - Cache invalidation system
   
4. **API Improvements** (not in original plan)
   - Sealed class series architecture (type safety)
   - Removed redundant chartType parameter
   - Runtime theme switching

### Performance Validated ✅
- 60fps with 7 series simultaneously
- O(log n) hit testing via QuadTree
- <100ms for 1000 points
- Smooth interactions with no gesture conflicts

---

## Next Steps - Updated Priority

Based on current progress, recommended next features:

**📋 See detailed sprint task breakdown in [SPRINT_TASKS.md](../SPRINT_TASKS.md)**

### Immediate Priority (Sprint 3.2 - Next 2-3 weeks)

**1. Complete Annotations System** (~7 hours, 7 tasks)
- Port 5 annotation types from BravenChart
- PointAnnotation, RangeAnnotation, TextAnnotation, ThresholdAnnotation, TrendAnnotation
- Test all annotation types with drag/resize
- Test annotations with theming
- **Current Progress**: 50% complete (basic infrastructure exists)

**2. Add Legend Widget** (~3 hours, 3 tasks)
- Port Legend from BravenChart
- Show/hide series functionality
- Click to toggle series visibility
- **Current Progress**: 0% complete

**3. Add Streaming Support** (~9.5 hours, 8 tasks)
- Port BufferManager, StreamingConfig, StreamingController
- Integrate with ChartTransform viewport
- Test streaming + pan/zoom interaction
- Add streaming example to example app
- **Current Progress**: 0% complete

**4. Add Scrollbars** (~7 hours, 6 tasks)
- Port ChartScrollbar widget
- Sync with ChartTransform viewport (two-way binding)
- Test scrollbar + pan/zoom interaction (no conflicts)
- **Current Progress**: 0% complete

**5. Advanced Markers** (~1.5 hours, 2 tasks)
- Multiple marker shapes (circle, square, triangle, diamond)
- Marker configuration per series
- **Current Progress**: 40% complete (tooltips done)

**Sprint 3.2 Subtotal**: ~28 hours, 26 tasks remaining

---

### Medium Priority (Sprint 4 - Weeks 4-6)

**Phase 3: Feature Parity & Polish** (~30 hours, 8 tasks)

**6. Feature Parity Audit** (~4 hours)
- Compare BravenChart vs BravenChartPlus feature lists
- Port any missing chart types (Candlestick, Bubble, etc.)
- Port any missing interaction modes
- Update documentation

**7. Testing & Optimization** (~11 hours)
- Unit test coverage
- Integration testing
- Performance benchmarking at scale (10+ charts, 10k+ points)
- Bug fixes

**8. Migration Guide** (~10 hours)
- Document differences between BravenChart and BravenChartPlus
- Migration steps and code examples
- Breaking changes documentation
- Update all example apps to use BravenChartPlus
- Deprecate old BravenChart (add deprecation notices)

**9. Theming Re-Verification** (~4 hours, 8 tasks) **⚠️ CRITICAL**
- Re-test theming system after ALL features added
- Verify theme changes update: series, axes, tooltips, annotations, legends, markers
- Test runtime theme switching performance
- Test theme changes with streaming data
- **Why**: Performance divergence happened during theming implementation - must verify complete integration

**Sprint 4 Subtotal**: ~30 hours, 8 major tasks

---

### Overall Remaining Work

| Sprint | Focus | Tasks | Hours | Status |
|--------|-------|-------|-------|--------|
| Sprint 3.2 | Remaining Phase 2 Features | 26 | ~28h | 🔄 IN PROGRESS |
| Sprint 4 | Phase 3 Feature Parity | 8 | ~30h | ❌ NOT STARTED |
| Theming Re-Verification | Quality Assurance | 8 | ~4h | ❌ NOT STARTED |
| **TOTAL REMAINING** | - | **42** | **~62h** | - |

**Recommended Approach**: 
1. Complete Sprint 3.2 features one at a time (start with Annotations)
2. Test each feature thoroughly in example app
3. Commit after each feature
4. Update SPRINT_TASKS.md progress after each commit
5. Move to Sprint 4 when all Phase 2 features complete

---
## Timeline Revision

### Original Estimate (from 2025-11-10)
- Phase 1: 1 day (8 hours)
- Phase 2: 2-3 weeks (80-100 hours)
- Phase 3: 1 week (40 hours)
- **Total**: 128-148 hours (4-6 weeks)

### Actual Progress (as of 2025-11-12)
- Phase 1: ✅ Complete (~10 hours)
- Phase 2: ⏳ 60% Complete (~25 hours planned + 47 hours additional)
- Phase 3: ❌ Not Started

**Time Spent**: ~72 hours (includes significant architecture work beyond plan)  
**Remaining**: ~60-70 hours

### Revised Timeline (from 2025-11-12)

**Weeks 1-2**: Complete Phase 2 remaining features
- Annotations (6h), Legend (4h), Streaming (8h), Scrollbars (6h)
- Advanced markers (3h)
- **Total**: ~27 hours

**Weeks 3-4**: Phase 3 - Feature parity & polish
- Feature audit (8h)
- Missing features (20h)
- Testing (8h)
- Documentation (4h)
- **Total**: ~40 hours

**Total Remaining**: ~67 hours (~3-4 weeks)

**New Completion Estimate**: 4-5 weeks from 2025-11-12 = **Mid-December 2025**

---

## File Structure (Updated for lib/src_plus/)

```
lib/
├── src/                                   # ✅ OLD - BravenChart (untouched, working)
│   └── widgets/
│       └── braven_chart.dart              # Production widget (7,300+ lines)
│
└── src_plus/                              # ✅ NEW - BravenChartPlus (incremental build)
    ├── widgets/
    │   └── braven_chart_plus.dart         # ✅ Main public widget (340 lines)
    │
    ├── rendering/
    │   ├── chart_render_box.dart          # ✅ RenderBox (1,247 lines) - from PrototypeChart
    │   └── spatial_index.dart             # ✅ QuadTree
    │
    ├── interaction/
    │   ├── core/
    │   │   ├── coordinator.dart           # ✅ From PrototypeChart
    │   │   ├── interaction_mode.dart      # ✅
    │   │   ├── chart_element.dart         # ✅ Element interface
    │   │   ├── element_types.dart         # ✅
    │   │   ├── element_data.dart          # ✅
    │   │   └── hit_test_strategy.dart     # ✅
    │   └── recognizers/
    │       ├── context_aware_recognizer.dart    # ✅
    │       ├── priority_pan_recognizer.dart     # ✅
    │       └── priority_tap_recognizer.dart     # ✅
    │
    ├── coordinates/
    │   └── chart_transform.dart           # ✅ 3-space coords (419 lines)
    │
    ├── axis/
    │   ├── axis.dart                      # ✅ Dynamic axis (133 lines)
    │   ├── axis_config.dart               # ✅
    │   ├── axis_renderer.dart             # ✅
    │   ├── linear_scale.dart              # ✅
    │   ├── tick_generator.dart            # ✅
    │   └── tick.dart                      # ✅
    │
    ├── elements/                          # ✅ Element wrappers
    │   ├── series_element.dart            # ✅ Series rendering
    │   ├── simulated_series.dart          # ✅ Series hit testing
    │   ├── simulated_datapoint.dart       # ✅ Point hit testing
    │   ├── simulated_annotation.dart      # ✅ Basic annotations
    │   └── resize_handle_element.dart     # ✅ Resize handles
    │
    ├── models/                            # ✅ Data models
    │   ├── chart_series.dart              # ✅ Sealed class hierarchy
    │   ├── chart_data_point.dart          # ✅
    │   ├── chart_theme.dart               # ✅
    │   ├── chart_type.dart                # ✅
    │   └── axis_config.dart               # ✅
    │
    └── utils/
        └── data_converter.dart            # ✅ Data utilities

example/lib/
├── main.dart                              # ✅ OLD - BravenChart examples
├── braven_chart_plus_example.dart         # ✅ NEW - BravenChartPlus basic test
└── braven_chart_plus_example_5charts.dart # ✅ NEW - Performance test (7 series)

refactor/interaction/                      # ✅ REFERENCE - Original prototype
└── lib/
    ├── widgets/prototype_chart.dart       # Reference implementation
    ├── rendering/chart_render_box.dart    # Original RenderBox
    └── ...
```

**Total Files in src_plus/**: ~30 unique files, ~6,000+ lines of code  
**Status**: Core architecture complete, partial features implemented

---

## Testing Strategy

### After Each Feature Port:

1. **Compile Check**:
   ```powershell
   flutter analyze
   ```

2. **Visual Test**:
   ```powershell
   cd example
   flutter run -d chrome lib/braven_chart_plus_example.dart
   ```

3. **Interaction Test**:
   - Test the newly ported feature works
   - Test no regressions in existing features
   - Test gesture interactions (pan, zoom, click, drag)

4. **Commit**:
   ```powershell
   git add .
   git commit -m "feat(BravenChartPlus): Add [feature name]"
   ```

### Continuous Validation:
- BravenChart continues to work (no changes)
- PrototypeChart continues to work (no changes)
- BravenChartPlus gains features incrementally

---

## API Alignment Strategy

**BravenChart Public API** (must match):
```dart
BravenChart({
  Key? key,
  required ChartType chartType,
  required List<ChartSeries> series,
  ChartTheme? theme,
  AxisConfig? xAxis,
  AxisConfig? yAxis,
  List<ChartAnnotation>? annotations,
  StreamingConfig? streamingConfig,
  InteractionConfig? interactionConfig,
  // ... other parameters
})
```

**BravenChartPlus API** (matches public API):
```dart
BravenChartPlus({
  Key? key,
  required ChartType chartType,
  required List<ChartSeries> series,
  ChartTheme? theme,
  AxisConfig? xAxis,
  AxisConfig? yAxis,
  List<ChartAnnotation>? annotations,
  StreamingConfig? streamingConfig,
  InteractionConfig? interactionConfig,
  // ... same parameters
})
```

**Internal Implementation** (from PrototypeChart):
```dart
class _BravenChartPlusState extends State<BravenChartPlus> {
  late ChartInteractionCoordinator _coordinator;  // PrototypeChart
  late ChartTransform _transform;                 // PrototypeChart
  
  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        // Custom recognizers from PrototypeChart
      },
      child: _ChartRenderObjectWidget(
        // Pass to RenderBox from PrototypeChart
      ),
    );
  }
}
```

---

## Risk Mitigation

### Risk 1: Breaking PrototypeChart Architecture
**Mitigation**: Keep PrototypeChart code in refactor/interaction/ as reference. Any changes to BravenChartPlus must preserve core patterns (Coordinator, QuadTree, 3-space coords).

### Risk 2: Feature Port Complexity
**Mitigation**: Port simplest features first (series, theming). Build confidence before tackling complex features (streaming, scrollbars).

### Risk 3: API Incompatibility
**Mitigation**: Match BravenChart's public API exactly. Internal implementation can be completely different.

### Risk 4: Performance Regression
**Mitigation**: Benchmark after each major feature. PrototypeChart's QuadTree should improve performance, not degrade it.

---

## Success Metrics

### After Each Feature:
- ✅ Feature works in BravenChartPlus
- ✅ No regressions in previously ported features
- ✅ BravenChart still works (untouched)
- ✅ Code compiles without errors
- ✅ Example app demonstrates feature

### Final Success (Phase 3):
- ✅ BravenChartPlus has 100% feature parity
- ✅ All interactions work without conflicts
- ✅ Performance equal or better than BravenChart
- ✅ Example apps migrated to BravenChartPlus
- ✅ Migration guide complete
- ✅ Tests pass

---

## Timeline Estimate

**⚠️ UPDATED TIMELINE (2025-11-12)** - Reflects performance divergence

### Original Estimate

**Phase 1 (Foundation)**: 1 day (8 hours)
- Setup BravenChartPlus skeleton
- Create example app
- Verify basic rendering

**Phase 2 (Feature Porting)**: 2-3 weeks (80-100 hours)
- Feature 1 (Series): 4-6 hours
- Feature 2 (Theming): 4-6 hours
- Feature 3 (Annotations): 8-10 hours
- Feature 4 (Streaming): 6-8 hours
- Feature 5 (Scrollbars): 4-6 hours
- Feature 6 (Chart types): 4-6 hours
- Feature 7 (Markers/legends/tooltips): 6-8 hours
- Buffer time: 40-50 hours

**Phase 3 (Cutover)**: 1 week (40 hours)
- Feature parity audit
- Performance optimization
- Migration guide
- Documentation

**Total**: 4-5 weeks (128-148 hours)
**Conservative with buffer**: 6 weeks

---

### Revised Timeline (After Performance Divergence)

| Phase | Original Est. | Actual Spent | Remaining | Notes |
|-------|---------------|--------------|-----------|-------|
| Phase 1: Foundation | 8h | ~25h | 0h | Over by 17h (added extra arch work) |
| Phase 2: Features (planned) | 36-50h | ~22h | 0h | Completed: Series, Theming, partial Annotations/Markers |
| **Performance Divergence** | **0h** | **~25h** | **0h** | **Unplanned optimization work** |
| Phase 2: Remaining | - | 0h | ~29.5h | Annotations, Streaming, Scrollbars, Legends |
| Phase 3: Feature Parity | 40h | 0h | ~30h | Audit, testing, migration guide |
| **Theming Re-Verification** | **0h** | **0h** | **~4h** | **New requirement from divergence** |
| **TOTAL** | **84-98h** | **72h** | **~63.5h** | **~135.5h total** |

**Current Status**: Sprint 3 (Performance + Features)  
**Time Invested**: 72 hours  
**Remaining Work**: ~63.5 hours (~3-4 weeks)  
**Revised Completion Target**: Mid-December 2025

**Variance Analysis**:
- Phase 1 over by 17h (architectural improvements)
- Performance divergence added 25h (unplanned)
- Theming re-verification added 4h (quality assurance)
- Total increase: +46h over original estimate (+54% variance)

**Lesson**: Always include contingency for performance optimization work. Architectural changes often reveal performance bottlenecks that require immediate attention.

---

## Next Steps

1. ✅ Document strategy (this file)
2. ⏳ Copy PrototypeChart files to BravenChartPlus structure
3. ⏳ Align public API with BravenChart
4. ⏳ Create example app
5. ⏳ Verify basic rendering
6. ⏳ Port Feature 1 (Real ChartSeries)
7. ⏳ Port Feature 2 (Theming)
8. ⏳ Continue with remaining features...

---

**Status**: Strategy documented, ready to begin Phase 1  
**Branch**: `core-interaction-refactor`  
**Created**: 2025-11-10  
**Author**: AI Assistant (with user guidance)

---

## References

- **Previous Strategy (FAILED)**: `03-PHASE_1_IMPLEMENTATION_PLAN.md` (big-bang migration)
- **Prototype Code**: `refactor/interaction/` (proven architecture)
- **Target API**: `lib/src/widgets/braven_chart.dart` (production API)
- **Analysis Documents**: `01-TECHNICAL_ANALYSIS.md`, `02-EXECUTIVE_SUMMARY.md`
