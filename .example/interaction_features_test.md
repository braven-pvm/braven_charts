# Interaction System Features - Manual Testing Guide

**Date Created:** October 8, 2025  
**Branch:** 007-interaction-system  
**Purpose:** Comprehensive manual testing of all implemented interaction features

---

## 🎯 Testing Overview

This guide verifies that ALL implemented interaction features are working correctly and showcased in the example app.

### Quick Navigation
- [Feature Checklist](#feature-checklist)
- [Testing Procedure](#testing-procedure)
- [Screen-by-Screen Tests](#screen-by-screen-tests)
- [Expected Behaviors](#expected-behaviors)

---

## ✅ Feature Checklist

### Core Interaction Features (Layer 7)
- [ ] **Crosshair Display**
  - [ ] Vertical mode
  - [ ] Horizontal mode
  - [ ] Both (crosshair) mode
  - [ ] Snap-to-data-point with configurable radius
  - [ ] Custom styling (color, width, dash pattern)
  - [ ] Coordinate label display

- [ ] **Tooltip System**
  - [ ] Default tooltip builder
  - [ ] Custom tooltip builder
  - [ ] Trigger modes: hover, tap, both
  - [ ] Smart positioning (auto-flip when clipping)
  - [ ] Custom styling (background, border, text)
  - [ ] Show delay configuration

- [ ] **Zoom Controls**
  - [ ] CTRL + Mouse Wheel zoom (desktop)
  - [ ] Pinch-to-zoom (touch devices)
  - [ ] Independent X/Y zoom levels
  - [ ] Zoom limits (min/max)
  - [ ] Double-click to reset zoom

- [ ] **Pan Controls**
  - [ ] Middle-mouse button drag (PRIMARY method)
  - [ ] SHIFT + Mouse Wheel pan (desktop)
  - [ ] Touch drag (mobile/tablet)
  - [ ] Pan offset tracking
  - [ ] Pan within bounds

- [ ] **Keyboard Navigation**
  - [ ] Arrow keys (Up/Down/Left/Right) - Pan viewport
  - [ ] Plus/Minus keys (+/-) - Zoom in/out
  - [ ] Home/End keys - Jump to start/end of data
  - [ ] Configurable step sizes (panStep, zoomStep)
  - [ ] Enable/disable individual key groups

- [ ] **Gesture Recognition**
  - [ ] Tap detection
  - [ ] Long-press detection
  - [ ] Hover detection (desktop)
  - [ ] Multi-touch support

- [ ] **Viewport Transformation**
  - [ ] Zoom transformation applied to rendering
  - [ ] Pan offset applied to rendering
  - [ ] Viewport culling for performance
  - [ ] Data bounds calculation with zoom/pan

### Callback System (10 Callbacks)
- [ ] **onDataPointTap** - Fired when tapping a data point
- [ ] **onDataPointHover** - Fired when hovering over a data point
- [ ] **onDataPointLongPress** - Fired when long-pressing a data point
- [ ] **onSelectionChanged** - Fired when data point selection changes
- [ ] **onZoomChanged** - Fired when zoom level changes
- [ ] **onPanChanged** - Fired when pan offset changes
- [ ] **onViewportChanged** - Fired when visible data bounds change
- [ ] **onCrosshairChanged** - Fired when crosshair position/snap changes
- [ ] **onTooltipChanged** - Fired when tooltip visibility changes
- [ ] **onKeyboardAction** - Fired when keyboard navigation occurs

### Configuration Options
- [ ] **InteractionConfig.all()** - Factory for all features enabled
- [ ] **InteractionConfig.none()** - Factory for all features disabled
- [ ] **InteractionConfig.defaultConfig()** - Factory for default settings
- [ ] **Custom InteractionConfig** - Granular feature control

---

## 🧪 Testing Procedure

### Setup
1. ✅ App running: `cd example; flutter run -d chrome`
2. Navigate to **"Interaction System"** section on home screen
3. Two test screens available:
   - **Full Interaction Showcase** - All features in one screen
   - **Interaction Examples** - 9 individual examples

---

## 📱 Screen-by-Screen Tests

### Test 1: Full Interaction Showcase Screen

**Navigation:** Home → "🚀 Full Interaction Showcase"

#### Test 1.1: Basic Interaction (Default State)
1. [ ] **Visual Check**: Chart displays with 2 line series (Revenue, Profit)
2. [ ] **Status Bar**: Shows "ENABLED", "Zoom: 100%", "Events: 0"
3. [ ] **Control Panel**: Shows on the right with all configuration options

#### Test 1.2: Crosshair Testing
1. [ ] **Move mouse over chart** → Crosshair appears (blue, dashed lines)
2. [ ] **Move near data point** → Crosshair snaps to nearest point (within 30px)
3. [ ] **Verify snap radius** → Point highlights with larger circle
4. [ ] **Check coordinate labels** → X/Y values displayed at crosshair intersection
5. [ ] **Event log** → "CROSSHAIR: Snapped to N points" messages appear
6. [ ] **Toggle OFF** → Uncheck "Crosshair" in control panel, crosshair disappears
7. [ ] **Toggle ON** → Re-check "Crosshair", crosshair reappears

#### Test 1.3: Tooltip Testing
1. [ ] **Hover over data point** → Custom tooltip appears with:
   - "📊 Data Point" header
   - X and Y values with icons
   - "✓ Above Average" or "! Below Average" badge
   - Blue border, light blue background
2. [ ] **Move mouse away** → Tooltip disappears
3. [ ] **Tap data point** → Tooltip appears (same as hover)
4. [ ] **Check smart positioning**:
   - Hover near top edge → Tooltip flips below cursor
   - Hover near right edge → Tooltip flips to left of cursor
5. [ ] **Event log** → "TOOLTIP: Shown at (X, Y)" / "TOOLTIP: Hidden" messages
6. [ ] **Toggle OFF** → Uncheck "Tooltip", tooltips stop appearing
7. [ ] **Toggle ON** → Re-check "Tooltip", tooltips work again

#### Test 1.4: Zoom Testing (CRITICAL - R-T008 Feature)
1. [ ] **CTRL + Scroll UP** → Chart zooms IN
   - Zoom percentage increases (e.g., 100% → 120% → 150%)
   - Data points get larger/spread out
   - Event log: "ZOOM: 120% x 120%"
2. [ ] **CTRL + Scroll DOWN** → Chart zooms OUT
   - Zoom percentage decreases
   - Data points get smaller/closer together
   - Event log: "ZOOM: 100% x 100%"
3. [ ] **Verify viewport transformation**:
   - Zoomed-in chart shows fewer data points (viewport culling active)
   - Chart re-renders with new data bounds
4. [ ] **Pinch gesture** (if touch-enabled):
   - Pinch out → Zoom in
   - Pinch in → Zoom out
5. [ ] **Event log** → "ZOOM: X% x Y%" messages for each zoom change
6. [ ] **Toggle OFF** → Uncheck "Zoom", scroll does nothing
7. [ ] **Toggle ON** → Re-check "Zoom", zoom works again

#### Test 1.5: Pan Testing (CRITICAL - R-T008 Feature)
1. [ ] **Middle-mouse button + Drag** → Chart pans (PRIMARY method)
   - Cursor changes to grabbing hand
   - Chart content shifts left/right/up/down
   - Event log: "PAN: dx=X, dy=Y"
2. [ ] **SHIFT + Scroll UP/DOWN** → Chart pans vertically
   - Chart shifts up/down
   - Event log: "PAN: dx=0, dy=Y"
3. [ ] **SHIFT + Scroll LEFT/RIGHT** (if supported) → Chart pans horizontally
4. [ ] **Touch drag** (if touch-enabled):
   - Drag finger → Chart pans in drag direction
5. [ ] **Verify viewport transformation**:
   - Panned chart shows different data range
   - onViewportChanged callback fires with new bounds
   - Event log: "VIEWPORT: X=min to max"
6. [ ] **Toggle OFF** → Uncheck "Pan", dragging does nothing
7. [ ] **Toggle ON** → Re-check "Pan", panning works again

#### Test 1.6: Keyboard Navigation Testing (CRITICAL - R-T010 Feature)
1. [ ] **Click inside chart** → Chart gains focus (visible focus indicator)
2. [ ] **Arrow UP** → Chart pans up (15 pixels)
   - Event log: "KEYBOARD: pan_up"
3. [ ] **Arrow DOWN** → Chart pans down
   - Event log: "KEYBOARD: pan_down"
4. [ ] **Arrow LEFT** → Chart pans left
   - Event log: "KEYBOARD: pan_left"
5. [ ] **Arrow RIGHT** → Chart pans right
   - Event log: "KEYBOARD: pan_right"
6. [ ] **Plus (+) key** → Chart zooms in (15% step)
   - Zoom level increases
   - Event log: "KEYBOARD: zoom_in"
7. [ ] **Minus (-) key** → Chart zooms out (15% step)
   - Zoom level decreases
   - Event log: "KEYBOARD: zoom_out"
8. [ ] **Home key** → Jump to start of data
   - Chart pans to show first data points
   - Event log: "KEYBOARD: jump_to_start"
9. [ ] **End key** → Jump to end of data
   - Chart pans to show last data points
   - Event log: "KEYBOARD: jump_to_end"
10. [ ] **Toggle OFF** → Uncheck "Keyboard", keys do nothing
11. [ ] **Toggle ON** → Re-check "Keyboard", keys work again

#### Test 1.7: Tap Gesture Testing
1. [ ] **Tap data point** → 
   - Event log: "TAP: X=value, Y=value"
   - Status bar: "Selected: X=value, Y=value"
2. [ ] **Tap another point** → Selection updates
3. [ ] **Tap background** → No TAP event (only background tap)

#### Test 1.8: Long-Press Testing
1. [ ] **Long-press data point** (hold >500ms) →
   - Event log: "LONG-PRESS: X=value, Y=value"
   - Dialog appears: "📌 Data Point Details" with X, Y, and position
2. [ ] **Close dialog** → Dialog dismisses
3. [ ] **Long-press another point** → New dialog with different data

#### Test 1.9: Hover Testing (Desktop Only)
1. [ ] **Hover over data point** →
   - Event log: "HOVER: X=value, Y=value"
   - Status bar: "Hovered: X=value, Y=value"
2. [ ] **Move to different point** → Hovered point updates
3. [ ] **Move mouse out of chart** →
   - Event log: "HOVER: null" or similar
   - Status bar: Hovered line disappears

#### Test 1.10: Factory Constructor Testing
1. [ ] **Select "InteractionConfig.all()"** →
   - All features become enabled (controls grayed out)
   - All interactions work (crosshair, tooltip, zoom, pan, keyboard)
2. [ ] **Select "InteractionConfig.none()"** →
   - All features become disabled
   - No interactions work (chart is static)
3. [ ] **Select "Custom Config"** →
   - Individual feature toggles become active
   - Can enable/disable features individually

#### Test 1.11: Event Log Verification
1. [ ] **Perform various interactions** → Event log updates in real-time
2. [ ] **Check event count** → Increments with each event
3. [ ] **Verify event format** → "[count] EVENT: details" format
4. [ ] **Scroll log** → Shows last 20 events
5. [ ] **Click "Clear"** → Log clears, count resets to 0

---

### Test 2: Interaction Examples Screen

**Navigation:** Home → "Interaction Examples"

#### Test 2.1: Example 1 - Basic Crosshair
1. [ ] Navigate to "Example 1: Basic Crosshair"
2. [ ] Move mouse over chart → Crosshair appears
3. [ ] Verify 5-line setup (minimal code)

#### Test 2.2: Example 2 - Custom Crosshair Style
1. [ ] Navigate to "Example 2: Custom Crosshair Style"
2. [ ] Move mouse over chart → Crosshair with custom style
3. [ ] Verify custom color, width, dash pattern
4. [ ] Verify custom snap radius

#### Test 2.3: Example 3 - Default Tooltip
1. [ ] Navigate to "Example 3: Default Tooltip"
2. [ ] Hover/tap data point → Default tooltip appears
3. [ ] Verify default formatting (simple X/Y display)

#### Test 2.4: Example 4 - Custom Tooltip Builder
1. [ ] Navigate to "Example 4: Custom Tooltip Builder"
2. [ ] Hover/tap data point → Custom tooltip with rich content
3. [ ] Verify custom styling and layout

#### Test 2.5: Example 5 - Zoom & Pan Config
1. [ ] Navigate to "Example 5: Zoom & Pan Config"
2. [ ] Test all zoom methods (CTRL+Scroll, pinch)
3. [ ] Test all pan methods (middle-mouse, SHIFT+Scroll, drag)
4. [ ] Verify zoom limits and bounds

#### Test 2.6: Example 6 - Gesture Callbacks
1. [ ] Navigate to "Example 6: Gesture Callbacks"
2. [ ] Test tap → Callback fires
3. [ ] Test long-press → Callback fires
4. [ ] Test hover → Callback fires
5. [ ] Verify callback parameters (point, position)

#### Test 2.7: Example 7 - Keyboard Navigation
1. [ ] Navigate to "Example 7: Keyboard Navigation"
2. [ ] Test all arrow keys
3. [ ] Test +/- keys
4. [ ] Test Home/End keys
5. [ ] Verify configurable step sizes

#### Test 2.8: Example 8 - Multi-Series Crosshair
1. [ ] Navigate to "Example 8: Multi-Series Crosshair"
2. [ ] Move crosshair over chart with multiple series
3. [ ] Verify crosshair snaps to nearest point across all series
4. [ ] Verify tooltip shows correct series info

#### Test 2.9: Example 9 - Complete Interaction
1. [ ] Navigate to "Example 9: Complete Interaction"
2. [ ] Verify all features work together:
   - [ ] Crosshair + Tooltip simultaneously
   - [ ] Zoom + Pan simultaneously
   - [ ] Keyboard + Mouse interactions
   - [ ] All callbacks fire correctly

---

## 🎯 Expected Behaviors

### Crosshair
- **Visual**: Two perpendicular lines following mouse cursor
- **Snap**: Lines jump to nearest data point when within snapRadius
- **Styling**: Configurable color, width, dash pattern
- **Labels**: Optional X/Y coordinate display at intersection

### Tooltip
- **Trigger**: Appears on hover and/or tap based on config
- **Position**: Smart positioning to avoid clipping at edges
- **Content**: Default or custom builder
- **Delay**: Optional show delay (default: 200ms)

### Zoom
- **Methods**: CTRL+Scroll (desktop), Pinch (touch)
- **Behavior**: Increases/decreases data point spacing
- **Viewport**: Applies transformation to rendering (fewer points visible when zoomed in)
- **Limits**: Configurable min/max zoom levels
- **Reset**: Double-click to reset to 100%

### Pan
- **Methods**: Middle-mouse drag (PRIMARY), SHIFT+Scroll, Touch drag
- **Behavior**: Shifts visible data range
- **Viewport**: Changes which portion of data is visible
- **Bounds**: Optional boundary constraints
- **Callback**: onViewportChanged fires with new data bounds

### Keyboard
- **Focus**: Chart must have focus (click or tab to it)
- **Arrow Keys**: Pan viewport by configurable step (default: 15px)
- **+/- Keys**: Zoom by configurable step (default: 15%)
- **Home/End**: Jump to data start/end
- **Modifier Keys**: Can combine with CTRL, SHIFT for variations

### Gestures
- **Tap**: Quick press and release (<200ms)
- **Long Press**: Hold for >500ms before release
- **Hover**: Mouse movement over chart (desktop only)
- **Pan**: Drag gesture (threshold: 10px movement)
- **Pinch**: Two-finger scale gesture (threshold: 0.1 scale change)

---

## 🐛 Known Issues / Limitations

### Pre-existing Issues (NOT from Layer 7)
- 96 failing contract tests for Layer 1 (ChartLayer, RenderContext not implemented)
- These are architectural placeholders, not interaction bugs

### Platform-Specific Behaviors
- **Keyboard navigation**: Requires focus (may need click-to-focus on web)
- **Middle-mouse pan**: May not work on some trackpads (use SHIFT+Scroll instead)
- **Touch gestures**: Only available on touch-enabled devices

### Performance Notes
- **Viewport culling**: Large datasets (>10k points) benefit from zoom (fewer points rendered)
- **Event throttling**: Hover events throttled to 60 FPS to prevent performance issues

---

## ✅ Acceptance Criteria

For this remediation sprint to be considered COMPLETE, ALL of the following must be TRUE:

### Code Completion
- [x] R-T008: Viewport transformation integrated (zoom/pan applied to rendering)
- [x] R-T009: GestureDetector provides all needed gesture recognition
- [x] R-T010: KeyboardHandler integrated for keyboard navigation
- [x] R-T011: InteractionState type documentation complete
- [x] R-T012: State synchronization verified (all handlers use copyWith)
- [x] R-T013: Static analysis passing (0 errors)
- [x] R-T014: Tests verified (1884 passing, 12/12 interaction widget tests passing)
- [x] R-T015: Documentation complete

### Feature Verification (Manual Testing)
- [ ] All 15 core interaction features working (see Feature Checklist)
- [ ] All 10 callbacks firing correctly
- [ ] All 3 factory constructors (.all(), .none(), .defaultConfig()) working
- [ ] InteractionShowcaseScreen demonstrates all features
- [ ] All 9 InteractionExamplesScreen examples working

### Integration Verification
- [ ] Zoom + Pan work simultaneously without conflicts
- [ ] Crosshair + Tooltip display together correctly
- [ ] Keyboard + Mouse interactions don't interfere
- [ ] GestureDetector handles all gestures correctly (no assertion errors)
- [ ] ZoomPanController applies transformations correctly
- [ ] KeyboardHandler processes all key events correctly

### Performance Verification
- [ ] Viewport culling reduces rendering load when zoomed in
- [ ] No frame drops during rapid zoom/pan
- [ ] Event log updates smoothly (60 FPS throttling working)
- [ ] Large datasets (50+ points) render smoothly

### Documentation Verification
- [ ] remediation_sprint.md fully updated with all test results
- [ ] This test plan covers all implemented features
- [ ] README or integration docs updated with interaction examples
- [ ] Code comments explain all non-obvious behavior

---

## 📝 Test Results Log

**Tester:** _________________________  
**Date:** _________________________  
**Browser/Platform:** _________________________  

### Quick Summary
- Total Features Tested: _____ / 15
- Features Passing: _____
- Features Failing: _____
- Critical Issues Found: _____

### Notes
_Use this space to document any issues, observations, or suggestions:_

```
[Your notes here]
```

---

## 🎉 Completion Sign-Off

**Developer:** _________________________  
**Date:** _________________________  
**Signature:** _________________________

**QA/Reviewer:** _________________________  
**Date:** _________________________  
**Signature:** _________________________

---

**End of Test Plan**
