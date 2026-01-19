# BravenChartPlus Sprint Task List

**Purpose**: Trackable, updateable task list for incremental merge into `lib/src_plus/`  
**Last Updated**: 2025-11-14  
**Current Sprint**: Sprint 3 (Performance + Remaining Features)  
**Branch**: `core-interaction-refactor`

---

## 📊 Sprint Overview

| Sprint | Focus Area | Status | Hours Spent | Hours Remaining |
|--------|-----------|--------|-------------|-----------------|
| Sprint 1 | Phase 1 Foundation | ✅ COMPLETE | ~25h | 0h |
| Sprint 2 | Phase 2 Features (Partial) | ✅ COMPLETE | ~22h | 0h |
| **Sprint 3** | **Performance + Features** | **🔄 IN PROGRESS** | **~34.5h** | **~18.5h** |
| Sprint 4 | Phase 3 Feature Parity | ❌ NOT STARTED | 0h | ~20-30h |

**Total Progress**: 81.5 hours spent, ~48.5-58.5 hours remaining (61% complete)

---

## ⚠️ CRITICAL CONTEXT: Performance Divergence

**What Happened**:
- During Sprint 2 (theming system implementation), encountered **massive performance issues**
- Diverged from incremental merge plan to debug and fix performance
- Spent ~25 hours on performance optimization (unplanned)
- Performance work included:
  * Picture caching (~17ms saved per frame)
  * Hit test throttling (50ms debounce)
  * QuadTree spatial index optimization
  * Pan/zoom constraint validation
  * Memory leak fixes
  * 5-chart stress testing

**Impact**:
- ✅ **Good**: Now have 60fps with 7 series, <100ms for 1000 points
- ⚠️ **Theming**: Theming system needs RE-VERIFICATION after all features added
  * Theme changes must update ALL chart elements correctly
  * Must test: series colors, axis labels, tooltips, annotations, legends, markers
  * Test with runtime theme switching

**Lesson Learned**: Performance issues can derail feature work - need buffer time

---

## 🎯 Sprint 3: Current Tasks (Performance + Features)

### Sprint 3.1: Performance Work (COMPLETED ✅)

| Task | Status | Hours | Priority | Notes |
|------|--------|-------|----------|-------|
| Picture caching for chart canvas | ✅ DONE | 4h | CRITICAL | Saves ~17ms per frame |
| Hit test throttling (50ms debounce) | ✅ DONE | 2h | CRITICAL | Prevents cascade failures |
| QuadTree spatial index optimization | ✅ DONE | 3h | CRITICAL | O(log n) hit testing |
| Pan/zoom constraint validation | ✅ DONE | 4h | HIGH | 10% max whitespace, 1x-10x zoom |
| Memory leak investigation | ✅ DONE | 3h | HIGH | Fixed Picture disposal |
| 5-chart stress test example | ✅ DONE | 2h | MEDIUM | Validates performance claims |
| Dynamic axis tick generation | ✅ DONE | 4h | MEDIUM | Just-in-time ticks |
| Focus management fix | ✅ DONE | 3h | MEDIUM | Runtime theme switching |

**Sprint 3.1 Total**: ✅ 25 hours completed

---

### Sprint 3.2: Remaining Phase 2 Features (IN PROGRESS 🔄)

#### Feature 3: Annotations (100% complete - IMPLEMENTED ✅)

**What EXISTS**: Full production annotation system in `lib/src_plus/`:
- `models/chart_annotation.dart` - Base sealed class with PointAnnotation, RangeAnnotation, TextAnnotation
- `models/annotation_style.dart` - Visual styling (colors, borders, fonts)
- `elements/annotation_elements.dart` - PointAnnotationElement, RangeAnnotationElement, TextAnnotationElement (600 lines)
- `widgets/braven_chart_plus.dart` - Annotations parameter integrated with _rebuildElements()

**Implementation Details**:
- 3 annotation types fully implemented (Point, Range, Text)
- All implement ChartElement interface with copyWith() for immutable updates
- PointAnnotation: 7 marker shapes (circle, square, triangle, diamond, star, cross, plus)
- RangeAnnotation: Rectangular regions with 5 label positions
- TextAnnotation: Screen-positioned with 9 anchor points
- Integrated with rendering pipeline (ChartRenderBox)
- Supports selection, hover, and dragging interactions
- Example 8 in feature showcase demonstrates all types

| Task | Status | Hours Est. | Hours Actual | Priority | Notes |
|------|--------|-----------|--------------|----------|-------|
| Create base ChartAnnotation + AnnotationStyle classes | ✅ DONE | 1.5h | 1.5h | HIGH | Sealed class with 3 concrete types |
| Create PointAnnotation model | ✅ DONE | 1h | 0.5h | HIGH | Marks specific data points |
| Create RangeAnnotation model | ✅ DONE | 1.5h | 0.5h | HIGH | Rectangular regions |
| Create TextAnnotation model | ✅ DONE | 1h | 0.5h | HIGH | Screen-positioned text |
| Create annotation element classes | ✅ DONE | 2h | 1.5h | HIGH | 600 lines, all ChartElement implementations |
| Integrate annotations with _rebuildElements | ✅ DONE | 1h | 1h | HIGH | Convert models to elements |
| Create Example 8 - Annotations showcase | ✅ DONE | 1h | 0.5h | HIGH | Demonstrates all 3 types |
| Test annotations with pan/zoom | ✅ DONE | 0.5h | 0.5h | HIGH | Transforms correctly verified |
| Test annotations with theming | ✅ DONE | 0.5h | 0.5h | MEDIUM | Colors update on theme change |

**Feature 3 Subtotal**: 9 tasks, 9h estimated, 7h actual (22% time savings)

---

#### Feature 4: Streaming Data (0% complete)

| Task | Status | Hours Est. | Priority | Assignee | Notes |
|------|--------|-----------|----------|----------|-------|
| Port StreamingConfig class | ❌ TODO | 1h | HIGH | - | Configuration for buffer size, update rate |
| Port BufferManager (ring buffer) | ❌ TODO | 2h | HIGH | - | Circular buffer for efficient data management |
| Port StreamingController | ❌ TODO | 2h | HIGH | - | Manages real-time data updates |
| Integrate with ChartTransform viewport | ❌ TODO | 1.5h | HIGH | - | Auto-scroll with new data |
| Update QuadTree on new data | ❌ TODO | 0.5h | MEDIUM | - | Rebuild spatial index efficiently |
| Test streaming + pan/zoom interaction | ❌ TODO | 1h | HIGH | - | User can pan while streaming |
| Verify auto-scroll respects pan constraints | ❌ TODO | 0.5h | MEDIUM | - | No more than 10% whitespace |
| Add streaming example to example app | ❌ TODO | 1h | LOW | - | Real-time sine wave demo |

**Feature 4 Subtotal**: 8 tasks, ~9.5 hours remaining

---

#### Feature 5: Scrollbars (0% complete)

| Task | Status | Hours Est. | Priority | Assignee | Notes |
|------|--------|-----------|----------|----------|-------|
| Port ChartScrollbar widget | ❌ TODO | 2h | HIGH | - | From BravenChart lib/src/widgets/ |
| Sync scrollbar position with ChartTransform | ❌ TODO | 1.5h | HIGH | - | Two-way binding |
| Scrollbar drag updates transform | ❌ TODO | 1h | MEDIUM | - | Pan viewport on scrollbar interaction |
| Pan/zoom updates scrollbar position | ❌ TODO | 1h | MEDIUM | - | Scrollbar reflects current viewport |
| Test no conflicts between scrollbar and pan | ❌ TODO | 1h | HIGH | - | Both gesture systems coexist |
| Add scrollbar to 5-chart example | ❌ TODO | 0.5h | LOW | - | Visual validation |

**Feature 5 Subtotal**: 6 tasks, ~7 hours remaining

---

#### Feature 7: Markers, Legends, Tooltips (80% complete)

| Task | Status | Hours Est. | Priority | Assignee | Notes |
|------|--------|-----------|----------|----------|-------|
| Port Legend widget from BravenChart | ✅ DONE | 1.5h | HIGH | - | ChartLegend widget created, sealed class API |
| Connect Legend to BravenChartPlus | ✅ DONE | 0.5h | HIGH | - | Example 7 in feature showcase |
| Update chart when series hidden/shown | ✅ DONE | 0.5h | MEDIUM | - | State management via Set<String> hiddenSeriesIds |
| Port advanced Marker shapes | ❌ TODO | 1.5h | MEDIUM | - | Circle, square, triangle, diamond |
| Test markers with different chart types | ❌ TODO | 0.5h | LOW | - | Line, bar, scatter, area |
| Tooltips already implemented | ✅ DONE | - | - | - | Completed in Sprint 2 |

**Feature 7 Subtotal**: 5 tasks, ~2 hours remaining (Legend complete: 2.5h actual vs 4h estimated)

---

### Sprint 3.2 Summary

| Feature | Tasks | Tasks Done | Tasks Remaining | Hours Estimated | Hours Actual | Hours Remaining |
|---------|-------|------------|-----------------|-----------------|--------------|-----------------|
| Feature 3: Annotations | 9 | 9 | 0 | ~9h | ~7h | 0h |
| Feature 4: Streaming | 8 | 0 | 8 | ~9.5h | 0h | ~9.5h |
| Feature 5: Scrollbars | 6 | 0 | 6 | ~7h | 0h | ~7h |
| Feature 7: Markers/Legends | 5 | 4 | 1 | ~4h | ~2.5h | ~2h |
| **TOTAL** | **28** | **13** | **15** | **~29.5h** | **~9.5h** | **~18.5h** |

**Sprint 3 Total Remaining**: ~18.5 hours (Phase 2 features only, reduced from 27.5h)

**Progress**: Sprint 3.2 is 46% complete (13/28 tasks done)

---

## 🎯 Sprint 4: Phase 3 Feature Parity (NOT STARTED)

### Goal: Ensure 100% feature parity with BravenChart

| Task | Status | Hours Est. | Priority | Assignee | Notes |
|------|--------|-----------|----------|----------|-------|
| Audit BravenChart for missing features | ❌ TODO | 4h | HIGH | - | Compare lib/src/ vs lib/src_plus/ |
| Port any missing chart types | ❌ TODO | 4h | MEDIUM | - | Candlestick, Bubble, etc. |
| Port any missing interaction modes | ❌ TODO | 3h | MEDIUM | - | Crosshair, data selection |
| Port any missing configurations | ❌ TODO | 3h | LOW | - | Edge cases, advanced options |
| Performance testing at scale | ❌ TODO | 4h | HIGH | - | 10+ charts, 10k+ points |
| Write migration guide | ❌ TODO | 4h | HIGH | - | BravenChart → BravenChartPlus |
| Update all example apps | ❌ TODO | 6h | MEDIUM | - | Use BravenChartPlus |
| Deprecate old BravenChart | ❌ TODO | 2h | LOW | - | Add deprecation notices |

**Sprint 4 Total**: 8 tasks, ~30 hours estimated

---

## ⚠️ CRITICAL: Theming Re-Verification Task

**MUST DO BEFORE RELEASE**: Re-test theming system after ALL features added

| Task | Status | Hours Est. | Priority | When | Notes |
|------|--------|-----------|----------|------|-------|
| Test theme change updates ALL series colors | ❌ TODO | 0.5h | CRITICAL | After Sprint 3 | All chart types |
| Test theme change updates axis labels | ❌ TODO | 0.5h | CRITICAL | After Sprint 3 | Font, color, size |
| Test theme change updates tooltips | ❌ TODO | 0.5h | CRITICAL | After Sprint 3 | Background, text color |
| Test theme change updates annotations | ❌ TODO | 0.5h | CRITICAL | After Sprint 3 | All 5 annotation types |
| Test theme change updates legends | ❌ TODO | 0.5h | CRITICAL | After Sprint 3 | Colors, text |
| Test theme change updates markers | ❌ TODO | 0.5h | CRITICAL | After Sprint 3 | All marker shapes |
| Test runtime theme switching performance | ❌ TODO | 0.5h | HIGH | After Sprint 3 | No lag, smooth transition |
| Test theme changes with streaming data | ❌ TODO | 0.5h | HIGH | After Sprint 4 | Theme + streaming |

**Theming Re-Verification Total**: 8 tasks, ~4 hours

**WHY**: Performance divergence happened during theming implementation. Must verify theming works correctly with ALL features once they're all ported.

---

## 📈 Overall Progress Summary

### Time Tracking

| Phase | Planned Hours | Actual Hours | Variance | Status |
|-------|---------------|--------------|----------|--------|
| Phase 1: Foundation | 20-25h | ~25h | 0h | ✅ COMPLETE |
| Phase 2: Feature Porting (planned) | 25-30h | ~22h | -3h to -8h | 🔄 70% COMPLETE |
| **Performance Divergence** | **0h** | **~25h** | **+25h** | ✅ COMPLETE |
| Phase 2: Remaining Features | - | ~9.5h | - | 🔄 ~18.5h remaining |
| Phase 3: Feature Parity | 20-30h | 0h | - | ❌ ~30h remaining |
| Theming Re-Verification | 0h | 0h | - | ❌ ~4h remaining |
| **TOTAL** | **65-85h** | **81.5h** | **-** | **~52.5h remaining** |

**Revised Total Estimate**: ~134 hours (vs original 85 hours)  
**Reason for Increase**: Performance optimization divergence (+25h), theming re-verification (+4h), annotation implementation (+7h)
**Current Progress**: 61% complete (81.5h / 134h)

### Feature Completion Status

| Feature | Status | Progress | Remaining Tasks |
|---------|--------|----------|-----------------|
| ✅ ChartSeries (sealed classes) | COMPLETE | 100% | 0 |
| ✅ Theming (runtime switching) | COMPLETE | 100% | 0 (needs re-verification) |
| ✅ Annotations | COMPLETE | 100% | 0 (3 types: Point, Range, Text) |
| ❌ Streaming | NOT STARTED | 0% | 8 tasks (~9.5h) |
| ❌ Scrollbars | NOT STARTED | 0% | 6 tasks (~7h) |
| ✅ Chart Types | COMPLETE | 100% | 0 |
| 🔄 Markers/Legends/Tooltips | IN PROGRESS | 80% | 1 task remaining (~2h) - Legend DONE |

---

## 🚀 How to Use This Document

### Starting a Work Session

1. **Check current sprint section** (Sprint 3.2)
2. **Pick highest priority ❌ TODO task** (start with HIGH priority)
3. **Update task status** to `🔄 IN PROGRESS` in this document
4. **Implement the feature** following incremental merge pattern:
   - Port code from BravenChart (`lib/src/`)
   - Adapt to BravenChartPlus architecture (`lib/src_plus/`)
   - Test in example app
5. **Update task status** to `✅ DONE` when complete
6. **Commit changes** with descriptive message
7. **Update hours** in summary tables

### Tracking Progress

- **Daily**: Update task statuses (TODO → IN PROGRESS → DONE)
- **Weekly**: Update "Hours Spent" in sprint overview table
- **Sprint End**: Move to next sprint, update totals

### Picking Up After Break

1. **Read "Current Sprint" section** (top of document)
2. **Check last commit** in git history
3. **Find first ❌ TODO task** in current sprint
4. **Continue from there**

### When Divergence Happens Again

1. **Document it** in a new "Divergence Context" section
2. **Add divergence tasks** to current sprint
3. **Update time estimates** in summary tables
4. **Add re-verification tasks** if needed (like theming)

---

## 🎯 Next Session: What to Work On

**IMMEDIATE PRIORITIES** (Sprint 3.2):

1. **Complete Advanced Markers** (~2 hours)
   - Port advanced marker shapes (circle, square, triangle, diamond)
   - Test with different chart types (line, bar, scatter, area)

2. **Add Streaming Support** (~9.5 hours)
   - Port StreamingConfig, BufferManager, StreamingController
   - Integrate with ChartTransform viewport
   - Test streaming + pan/zoom interaction
   - Add streaming example

3. **Add Scrollbars** (~7 hours)
   - Port ChartScrollbar widget
   - Sync with ChartTransform (two-way binding)
   - Test no conflicts with pan gestures

**RECOMMENDED START**: Begin with **Advanced Markers** (Feature 7) - quickest win (~2h), completes Feature 7. Then tackle **Streaming** (Feature 4) based on priority.

✅ **COMPLETED**: 
- Annotations (Feature 3) - 100% complete with 3 types
- Legend Widget (Feature 7) - ChartLegend complete with show/hide functionality

**Progress**: Sprint 3.2 is 46% complete (13/28 tasks), ~18.5h remaining

---

## 📝 Update Log

| Date | Sprint | Changes | Updated By |
|------|--------|---------|------------|
| 2025-11-12 | Sprint 3 | Initial sprint task list created | Agent |
| 2025-11-12 | Sprint 3 | Documented performance divergence context | Agent |
| 2025-11-12 | Sprint 3 | Added theming re-verification tasks | Agent |
| 2025-11-14 | Sprint 3.2 | Feature 3 (Annotations) completed - 9 tasks, 7h actual | Agent |
| 2025-11-14 | Sprint 3.2 | Updated progress: 46% complete (13/28 tasks) | Agent |

---

## 🔗 Related Documents

- **Implementation Status**: [current_status.md](./current_status.md) - What's currently implemented
- **Merge Strategy**: [07-incremental_merge_strategy.md](./core-interaction/07-incremental_merge_strategy.md) - Overall plan and progress
- **Project README**: [readme.md](./readme.md) - Refactor documentation overview

---

**Last Updated**: 2025-11-14  
**Next Review**: After Sprint 3.2 completion (Feature 4 or Feature 5)
