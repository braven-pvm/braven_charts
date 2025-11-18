# Scrollbar Manual Testing Checklist

**Date**: 2025-11-18  
**Feature**: Dual-Purpose Scrollbars (Pan + Zoom)  
**Implementation Phase**: Task 4.1 - Manual Testing  
**Status**: ⏳ In Progress  

---

## Test Environment

- **Flutter Version**: 3.37.0-1.0.pre-216
- **Dart Version**: 3.10.0-227.0.dev
- **Target Platform**: Desktop (Windows/macOS/Linux)
- **Example App**: `example/lib/braven_chart_plus_example.dart`

---

## Test Setup Instructions

1. **Enable Scrollbars**:
   ```dart
   BravenChartPlus(
     series: series,
     showXScrollbar: true,  // Enable horizontal scrollbar
     showYScrollbar: true,  // Enable vertical scrollbar
     scrollbarTheme: ScrollbarConfig.defaultLight(),
   )
   ```

2. **Run Example App**:
   ```powershell
   cd example
   flutter run -d windows  # Or macos, linux
   ```

3. **Test Data Requirements**:
   - Chart should have enough data to require scrolling
   - Viewport should be zoomed in to show scrollbars
   - Minimum 50-100 data points recommended

---

## Phase 1: Visual Rendering Tests

### 1.1 Scrollbar Appearance
- [ ] Horizontal scrollbar renders at bottom of chart
- [ ] Vertical scrollbar renders on right side of chart
- [ ] Both scrollbars visible when dual-axis enabled
- [ ] Scrollbar thickness matches theme configuration
- [ ] Border radius applied correctly
- [ ] Track color distinct from handle color
- [ ] Handle color distinct from background
- [ ] No visual overlap at corner (when both scrollbars shown)

### 1.2 Layout Integration
- [ ] Chart canvas excludes scrollbar space
- [ ] Scrollbars positioned outside chart area
- [ ] Proper padding between chart and scrollbars
- [ ] No clipping or overflow issues
- [ ] Responsive to window resize

### 1.3 Handle Geometry
- [ ] Handle size proportional to viewport ratio
- [ ] Handle position accurate to viewport bounds
- [ ] Minimum handle size enforced (32px)
- [ ] Maximum handle size respected (full track width - 4px)
- [ ] Handle updates when viewport changes

---

## Phase 2: Interaction Tests - Horizontal Scrollbar

### 2.1 Pan Mode (Drag Handle Center)
- [ ] Click on handle center starts pan
- [ ] Drag left shifts viewport left (shows later data)
- [ ] Drag right shifts viewport right (shows earlier data)
- [ ] Pan constrained to data boundaries
- [ ] Handle follows mouse smoothly (60fps)
- [ ] Release ends interaction cleanly
- [ ] Viewport persists after release

### 2.2 Zoom Mode (Drag Handle Left Edge)
- [ ] Click on handle left edge starts zoom
- [ ] Drag left expands viewport minimum (zoom out left)
- [ ] Drag right contracts viewport minimum (zoom in left)
- [ ] Right edge stays fixed during left edge drag
- [ ] Zoom constrained to min/max limits (20px - track width)
- [ ] Handle updates smoothly during drag
- [ ] Viewport persists after release

### 2.3 Zoom Mode (Drag Handle Right Edge)
- [ ] Click on handle right edge starts zoom
- [ ] Drag right expands viewport maximum (zoom out right)
- [ ] Drag left contracts viewport maximum (zoom in right)
- [ ] Left edge stays fixed during right edge drag
- [ ] Zoom constrained to min/max limits (20px - track width)
- [ ] Handle updates smoothly during drag
- [ ] Viewport persists after release

### 2.4 Track Click (Jump to Position)
- [ ] Click on track left of handle jumps viewport left
- [ ] Click on track right of handle jumps viewport right
- [ ] Viewport centers at clicked position
- [ ] Jump respects data boundaries
- [ ] Handle updates immediately (no animation)

---

## Phase 3: Interaction Tests - Vertical Scrollbar

### 3.1 Pan Mode (Drag Handle Center)
- [ ] Click on handle center starts pan
- [ ] Drag up shifts viewport up (shows higher values)
- [ ] Drag down shifts viewport down (shows lower values)
- [ ] Pan constrained to data boundaries
- [ ] Handle follows mouse smoothly (60fps)
- [ ] Release ends interaction cleanly
- [ ] Viewport persists after release

### 3.2 Zoom Mode (Drag Handle Top Edge)
- [ ] Click on handle top edge starts zoom
- [ ] Drag up expands viewport maximum (zoom out top)
- [ ] Drag down contracts viewport maximum (zoom in top)
- [ ] Bottom edge stays fixed during top edge drag
- [ ] Zoom constrained to min/max limits (20px - track height)
- [ ] Handle updates smoothly during drag
- [ ] Viewport persists after release

### 3.3 Zoom Mode (Drag Handle Bottom Edge)
- [ ] Click on handle bottom edge starts zoom
- [ ] Drag down expands viewport minimum (zoom out bottom)
- [ ] Drag up contracts viewport minimum (zoom in bottom)
- [ ] Top edge stays fixed during bottom edge drag
- [ ] Zoom constrained to min/max limits (20px - track height)
- [ ] Handle updates smoothly during drag
- [ ] Viewport persists after release

### 3.4 Track Click (Jump to Position)
- [ ] Click on track above handle jumps viewport up
- [ ] Click on track below handle jumps viewport down
- [ ] Viewport centers at clicked position
- [ ] Jump respects data boundaries
- [ ] Handle updates immediately (no animation)

---

## Phase 4: Viewport Synchronization Tests

### 4.1 Scrollbar Drag → Chart Updates
- [ ] Horizontal scrollbar drag updates X axis labels
- [ ] Horizontal scrollbar drag updates data points visible
- [ ] Vertical scrollbar drag updates Y axis labels
- [ ] Vertical scrollbar drag updates data points visible
- [ ] Both scrollbars update simultaneously during drag

### 4.2 Chart Pan → Scrollbar Updates
- [ ] Middle mouse pan updates horizontal scrollbar handle
- [ ] Middle mouse pan updates vertical scrollbar handle
- [ ] Arrow key pan updates scrollbars
- [ ] Pan via keyboard updates scrollbars
- [ ] Scrollbar handles track viewport accurately

### 4.3 Chart Zoom → Scrollbar Updates
- [ ] Shift+wheel zoom updates horizontal scrollbar handle size
- [ ] Shift+wheel zoom updates vertical scrollbar handle size
- [ ] +/- key zoom updates scrollbar handles
- [ ] Zoom in reduces handle size
- [ ] Zoom out increases handle size
- [ ] Handle position updates correctly during zoom

### 4.4 Streaming Data → Scrollbar Updates
- [ ] New data arrival updates scrollbar handle position
- [ ] Handle size updates if viewport ratio changes
- [ ] Scrollbar stays synchronized during continuous streaming
- [ ] No flicker or visual glitches

### 4.5 Reset View → Scrollbar Updates
- [ ] R key reset updates scrollbars to full viewport
- [ ] Home key reset updates scrollbars to full viewport
- [ ] Handle size becomes maximum (full track)
- [ ] Handle position resets to start

---

## Phase 5: Coordinator Integration Tests

### 5.1 Scrollbar Mode Claiming
- [ ] Scrollbar drag claims `scrollbarDragging` mode
- [ ] Mode priority 4 enforced (higher than pan, lower than selection)
- [ ] Coordinator reports correct mode during scrollbar drag
- [ ] Mode released when drag ends

### 5.2 Modal State Blocking
- [ ] Context menu blocks scrollbar interaction
- [ ] Edit mode blocks scrollbar interaction
- [ ] Scrollbar ignores clicks when modal active
- [ ] Scrollbar re-enables when modal closes

### 5.3 Gesture Priority Management
- [ ] Scrollbar drag prevents chart pan (middle mouse)
- [ ] Scrollbar drag prevents chart zoom (shift+wheel)
- [ ] Chart pan doesn't trigger during active scrollbar drag
- [ ] Chart zoom blocked during active scrollbar drag
- [ ] Element selection takes precedence over scrollbar

### 5.4 Multi-Axis Scrollbar Conflicts
- [ ] Horizontal scrollbar drag doesn't affect vertical scrollbar
- [ ] Vertical scrollbar drag doesn't affect horizontal scrollbar
- [ ] Can drag horizontal, release, then drag vertical immediately
- [ ] No mode conflicts between X and Y scrollbars

---

## Phase 6: Edge Case Tests

### 6.1 Empty Dataset
- [ ] Scrollbars hidden when no data
- [ ] No errors or crashes
- [ ] Chart renders cleanly without scrollbars

### 6.2 Extreme Zoom Levels
- [ ] Scrollbar handle reaches minimum size (20px)
- [ ] Scrollbar handle reaches maximum size (track - 4px)
- [ ] Zoom in to 10x shows tiny handle
- [ ] Zoom out to 0.1x shows full-width handle
- [ ] No visual glitches at extreme zoom

### 6.3 Window Resize During Drag
- [ ] Resize window while dragging scrollbar
- [ ] Scrollbar updates to new track size
- [ ] Handle remains clickable
- [ ] No crash or visual corruption

### 6.4 Rapid Interactions
- [ ] Rapidly click track multiple times
- [ ] Rapidly switch between scrollbar and chart pan
- [ ] Rapidly drag handle back and forth
- [ ] No lag or stutter (maintain 60fps)
- [ ] No state corruption

### 6.5 Data Boundaries
- [ ] Can't pan scrollbar past left boundary
- [ ] Can't pan scrollbar past right boundary
- [ ] Can't zoom scrollbar beyond min size
- [ ] Can't zoom scrollbar beyond max size
- [ ] Visual feedback at boundaries (no snap-back)

---

## Phase 7: Performance Tests

### 7.1 Rendering Performance
- [ ] Scrollbar renders at 60fps during drag
- [ ] No dropped frames during pan
- [ ] No dropped frames during zoom
- [ ] No dropped frames during track click
- [ ] Smooth animation throughout

### 7.2 Hit Testing Performance
- [ ] Scrollbar hit testing < 1ms
- [ ] No lag when clicking scrollbar
- [ ] No lag when hovering over scrollbar
- [ ] Fast response to pointer events

### 7.3 Large Datasets
- [ ] Scrollbar performs well with 1000+ data points
- [ ] Scrollbar performs well with 10,000+ data points
- [ ] No lag during viewport updates
- [ ] Memory usage stable

---

## Phase 8: Accessibility Tests

### 8.1 Visual Contrast
- [ ] Handle color has 4.5:1 contrast with track
- [ ] Track color has 4.5:1 contrast with background
- [ ] Edge zones visible during hover
- [ ] Clear visual feedback for all interactions

### 8.2 Touch Targets
- [ ] Handle meets 44x44 minimum touch target (WCAG 2.1 AA)
- [ ] Edge zones meet 44x44 minimum
- [ ] Track click area meets 44x44 minimum
- [ ] No missed clicks due to small targets

### 8.3 Keyboard Navigation
- [ ] Tab key focuses scrollbar (if implemented)
- [ ] Arrow keys move scrollbar (if implemented)
- [ ] Page up/down keys scroll viewport (if implemented)
- [ ] Home/end keys jump to boundaries (if implemented)

---

## Test Results Summary

**Test Date**: [To be filled]  
**Tester**: [To be filled]  
**Total Tests**: 150+  
**Passed**: [To be filled]  
**Failed**: [To be filled]  
**Blocked**: [To be filled]  

### Critical Issues Found
[List any critical bugs or issues that block functionality]

### Non-Critical Issues Found
[List minor bugs, visual glitches, or polish items]

### Performance Notes
[Note any performance concerns or optimizations needed]

### Recommendations
[List any recommendations for improvements or follow-up work]

---

## Sign-Off

- [ ] All critical tests passed
- [ ] All non-critical tests reviewed
- [ ] Performance meets 60fps target
- [ ] No crashes or errors during testing
- [ ] Ready for production use

**Tested By**: [Name]  
**Date**: [Date]  
**Approved By**: [Name]  
**Date**: [Date]  

---

**Document Status**: ✅ Ready for Testing  
**Created**: 2025-11-18  
**Last Updated**: 2025-11-18  
**Author**: AI Assistant (with user guidance)
