# BravenChartPlus Sprint Task List

**Purpose**: Trackable, updateable task list for incremental merge into `lib/src_plus/`  
**Last Updated**: 2025-11-12  
**Current Sprint**: Sprint 3 (Performance + Remaining Features)  
**Branch**: `core-interaction-refactor`

---

## 📊 Sprint Overview

| Sprint | Focus Area | Status | Hours Spent | Hours Remaining |
|--------|-----------|--------|-------------|-----------------|
| Sprint 1 | Phase 1 Foundation | ✅ COMPLETE | ~25h | 0h |
| Sprint 2 | Phase 2 Features (Partial) | ✅ COMPLETE | ~22h | 0h |
| **Sprint 3** | **Performance + Features** | **🔄 IN PROGRESS** | **~25h** | **~35-45h** |
| Sprint 4 | Phase 3 Feature Parity | ❌ NOT STARTED | 0h | ~20-30h |

**Total Progress**: 72 hours spent, ~55-75 hours remaining

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

#### Feature 3: Annotations (50% complete)

| Task | Status | Hours Est. | Priority | Assignee | Notes |
|------|--------|-----------|----------|----------|-------|
| Port PointAnnotation from BravenChart | ❌ TODO | 1.5h | HIGH | - | Markers at specific data points |
| Port RangeAnnotation from BravenChart | ❌ TODO | 1.5h | HIGH | - | Vertical/horizontal ranges |
| Port TextAnnotation from BravenChart | ❌ TODO | 1h | HIGH | - | Floating text labels |
| Port ThresholdAnnotation from BravenChart | ❌ TODO | 1h | MEDIUM | - | Horizontal threshold lines |
| Port TrendAnnotation from BravenChart | ❌ TODO | 1h | MEDIUM | - | Trend lines with equations |
| Test annotations with pan/zoom | ❌ TODO | 0.5h | HIGH | - | Ensure annotations transform correctly |
| Test annotations with theming | ❌ TODO | 0.5h | MEDIUM | - | Verify colors update on theme change |

**Feature 3 Subtotal**: 7 tasks, ~7 hours remaining

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

#### Feature 7: Markers, Legends, Tooltips (40% complete)

| Task | Status | Hours Est. | Priority | Assignee | Notes |
|------|--------|-----------|----------|----------|-------|
| Port Legend widget from BravenChart | ❌ TODO | 2h | HIGH | - | Show/hide series functionality |
| Connect Legend to BravenChartPlus | ❌ TODO | 1h | HIGH | - | Toggle series visibility |
| Update chart when series hidden/shown | ❌ TODO | 1h | MEDIUM | - | Rebuild with subset of series |
| Port advanced Marker shapes | ❌ TODO | 1.5h | MEDIUM | - | Circle, square, triangle, diamond |
| Test markers with different chart types | ❌ TODO | 0.5h | LOW | - | Line, bar, scatter, area |
| Tooltips already implemented | ✅ DONE | - | - | - | Completed in Sprint 2 |

**Feature 7 Subtotal**: 5 tasks, ~6 hours remaining

---

### Sprint 3.2 Summary

| Feature | Tasks | Tasks Done | Tasks Remaining | Hours Remaining |
|---------|-------|------------|-----------------|-----------------|
| Feature 3: Annotations | 7 | 0 | 7 | ~7h |
| Feature 4: Streaming | 8 | 0 | 8 | ~9.5h |
| Feature 5: Scrollbars | 6 | 0 | 6 | ~7h |
| Feature 7: Markers/Legends | 5 | 1 | 4 | ~6h |
| **TOTAL** | **26** | **1** | **25** | **~29.5h** |

**Sprint 3 Total Remaining**: ~29.5 hours (Phase 2 features only)

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
| Phase 2: Feature Porting (planned) | 25-30h | ~22h | -3h to -8h | 🔄 60% COMPLETE |
| **Performance Divergence** | **0h** | **~25h** | **+25h** | ✅ COMPLETE |
| Phase 2: Remaining Features | - | 0h | - | ❌ ~29.5h remaining |
| Phase 3: Feature Parity | 20-30h | 0h | - | ❌ ~30h remaining |
| Theming Re-Verification | 0h | 0h | - | ❌ ~4h remaining |
| **TOTAL** | **65-85h** | **72h** | **-** | **~63.5h remaining** |

**Revised Total Estimate**: ~135.5 hours (vs original 85 hours)  
**Reason for Increase**: Performance optimization divergence (+25h), theming re-verification (+4h)

### Feature Completion Status

| Feature | Status | Progress | Remaining Tasks |
|---------|--------|----------|-----------------|
| ✅ ChartSeries (sealed classes) | COMPLETE | 100% | 0 |
| ✅ Theming (runtime switching) | COMPLETE | 100% | 0 (needs re-verification) |
| 🔄 Annotations | IN PROGRESS | 50% | 7 tasks (~7h) |
| ❌ Streaming | NOT STARTED | 0% | 8 tasks (~9.5h) |
| ❌ Scrollbars | NOT STARTED | 0% | 6 tasks (~7h) |
| ✅ Chart Types | COMPLETE | 100% | 0 |
| 🔄 Markers/Legends/Tooltips | IN PROGRESS | 40% | 5 tasks (~6h) |

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

1. **Complete Annotations** (~7 hours)
   - Start with: Port PointAnnotation
   - Then: RangeAnnotation, TextAnnotation
   - Finally: ThresholdAnnotation, TrendAnnotation
   - Test with pan/zoom and theming

2. **Add Legend Widget** (~3 hours)
   - Port Legend from BravenChart
   - Connect to BravenChartPlus
   - Test show/hide series functionality

3. **Add Streaming Support** (~9.5 hours)
   - Port StreamingConfig, BufferManager, StreamingController
   - Integrate with ChartTransform viewport
   - Test streaming + pan/zoom interaction
   - Add streaming example

4. **Add Scrollbars** (~7 hours)
   - Port ChartScrollbar widget
   - Sync with ChartTransform (two-way binding)
   - Test no conflicts with pan gestures

**RECOMMENDED START**: Begin with **Annotations** (Feature 3) - completes partial work, enables richer data visualization

---

## 📝 Update Log

| Date | Sprint | Changes | Updated By |
|------|--------|---------|------------|
| 2025-11-12 | Sprint 3 | Initial sprint task list created | Agent |
| 2025-11-12 | Sprint 3 | Documented performance divergence context | Agent |
| 2025-11-12 | Sprint 3 | Added theming re-verification tasks | Agent |

---

## 🔗 Related Documents

- **Implementation Status**: [CURRENT_STATUS.md](./CURRENT_STATUS.md) - What's currently implemented
- **Merge Strategy**: [07-INCREMENTAL_MERGE_STRATEGY.md](./core-interaction/07-INCREMENTAL_MERGE_STRATEGY.md) - Overall plan and progress
- **Project README**: [README.md](./README.md) - Refactor documentation overview

---

**Last Updated**: 2025-11-12  
**Next Review**: After Sprint 3.2 completion
