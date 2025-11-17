# AutoScroll Analysis - Current Implementation & Issues

**Date**: 2025-11-17  
**Branch**: core-interaction-refactor  
**Context**: Analyzing autoscroll behavior for streaming charts to address two issues:
1. Window/viewport size when using autoscroll must be configurable
2. When autoscrolling (paused), user should be able to pan/zoom entire dataset

---

## Current Implementation Overview

### BravenChart (Original - `lib/src/widgets/braven_chart.dart`)

**Implementation Strategy**: Sliding Window with Zoom + Pan

```dart
// Lines 1516-1666: _calculateAutoScrollUpdate()

/// Implements auto-scroll as a **sliding window** that shows only the last N points
/// (configured via AutoScrollConfig.maxVisiblePoints). As new data arrives, older data
/// scrolls out of view on the left edge.
///
/// **Behavior:**
/// - Adjusts BOTH zoom and pan to create sliding window effect
/// - Zoom level calculated to make maxVisiblePoints fill the viewport
/// - Pan offset calculated to show the most recent maxVisiblePoints at right edge
/// - Older data scrolls off the left edge of viewport
/// - Creates a moving window where new data always fills the viewport
```

**Key Algorithm**:
1. Calculate X-spacing per data point (by sampling first 10 points)
2. Determine target visible range: `targetVisibleRangeX = xRangePerPoint * maxVisiblePoints`
3. Calculate zoom: `zoom = dataRangeX / targetVisibleRangeX`
   - Example: 450 units total, show 150 units → zoom = 3.0x
4. Calculate pan offset to center rightmost N points in viewport
5. All historical data is **preserved** - user can manually pan back

**Configuration** (`lib/src/widgets/auto_scroll_config.dart`):
```dart
class AutoScrollConfig {
  final bool enabled;
  final int maxVisiblePoints;        // ✅ CONFIGURABLE (default: 100)
  final bool resumeOnNewData;        // Auto-resume after manual pan
  final bool animateScroll;          // Smooth vs instant transition
  final Duration scrollAnimationDuration;
  
  // Presets:
  static const highFrequency = AutoScrollConfig(maxVisiblePoints: 50);
  static const lowFrequency = AutoScrollConfig(maxVisiblePoints: 100);
}
```

**Interaction Behavior**:
- ✅ Historical data preserved (all points in buffer)
- ✅ User can manually pan to view historical data
- ✅ Zoom is calculated automatically based on window size
- ⚠️ **ISSUE**: No explicit pause mechanism - relies on `resumeOnNewData` flag
- ⚠️ **ISSUE**: Window size controls both what's visible AND zoom level (coupled)

---

### BravenChartPlus (New - `lib/src_plus/widgets/braven_chart_plus.dart`)

**Implementation Strategy**: Incremental Pan with Streaming Control

```dart
// Lines 740-755: _autoScrollToLatest()

void _autoScrollToLatest() {
  final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
  if (renderBox == null) return;

  // NOTE: We don't call updateDataBounds() here anymore because:
  // 1. The sliding window in _rebuildElements() already calculated correct bounds
  // 2. Calling updateDataBounds() with all historical data causes bounds explosion
  // 3. The pan operation below is sufficient to follow latest data

  debugPrint('↩️  Auto-scrolling viewport to follow latest data');

  // Pan right every time to follow the data
  final panAmount = renderBox.size.width * 0.02; // 2% per update
  renderBox.panChart(panAmount, 0.0);
}
```

**Key Algorithm**:
1. No automatic zoom calculation
2. Simply pans right by 2% of viewport width per update
3. Relies on `_rebuildElements()` to calculate sliding window bounds
4. Uses `StreamingController` for explicit pause/resume control

**Configuration** (`lib/src_plus/models/streaming_config.dart`):
```dart
class StreamingConfig {
  final int maxBufferSize;           // Buffer limit (default: 10000)
  final bool autoScroll;             // ❌ NOT CONFIGURABLE - just on/off
  final ValueChanged<int>? onBufferUpdated;
}
```

**Streaming Control** (`lib/src_plus/streaming/streaming_controller.dart`):
```dart
class StreamingController extends ChangeNotifier {
  bool _isStreaming = true;
  
  bool get isStreaming => _isStreaming;
  bool get isPaused => !_isStreaming;
  
  void pauseStreaming() { /* ... */ }
  void resumeStreaming() { /* ... */ }
  void clearStreamingData() { /* ... */ }
}
```

**Pause/Resume Behavior** (Lines 647-674):
```dart
void _pauseStreaming() {
  setState(() { _isStreaming = false; });
  widget.streamingController?.updateState(false);
  // Incoming data goes to buffer instead of rendering
}

void _resumeStreaming() {
  _applyBufferedData();  // Apply all buffered points
  setState(() { _isStreaming = true; });
  widget.streamingController?.updateState(true);
  
  // Auto-scroll after resume
  if (config.autoScroll) {
    _autoScrollToLatest();
  }
}
```

**Interaction Behavior**:
- ✅ Explicit pause/resume via `StreamingController`
- ✅ Data buffered during pause (up to `maxBufferSize`)
- ✅ All data preserved for manual inspection
- ⚠️ **ISSUE**: No window size configuration (relies on bounds calculation)
- ⚠️ **ISSUE**: Auto-scroll only pans, doesn't control zoom
- ❌ **CRITICAL**: When paused, user CANNOT pan/zoom historical data!

---

## Issue #1: Window/Viewport Size Not Configurable

### Current State

**BravenChart**:
- ✅ Has `AutoScrollConfig.maxVisiblePoints` (configurable)
- ✅ Window size = number of points to show
- ✅ Zoom automatically calculated to fit those points
- **Limitation**: Window size tied to zoom level

**BravenChartPlus**:
- ❌ No window size configuration
- ❌ Only boolean `autoScroll` flag (on/off)
- **Limitation**: Cannot control how much data is visible during streaming

### User Requirement

> "Window/viewport size when using Autoscroll must be configurable"

**What this means**:
- User wants to control: "Show me the last **N** seconds/points of data"
- Different use cases need different window sizes:
  - High-frequency monitoring: Last 30 seconds (e.g., 300 points @ 10Hz)
  - Medium-frequency monitoring: Last 5 minutes (e.g., 300 points @ 1Hz)
  - Low-frequency monitoring: Last hour (e.g., 360 points @ 0.1Hz)

### Proposed Solution

Add window size configuration to `StreamingConfig`:

```dart
class StreamingConfig {
  final int maxBufferSize;
  final bool autoScroll;
  final int? autoScrollWindowSize;  // NEW: Number of points to show (null = auto)
  final Duration? autoScrollWindowDuration;  // NEW: Time window (alternative)
  // ...
}
```

**Options**:
1. **Point-based**: `autoScrollWindowSize: 150` → Show last 150 points
2. **Time-based**: `autoScrollWindowDuration: Duration(seconds: 30)` → Show last 30 seconds
3. **Auto** (null): Calculate based on viewport width and data density

---

## Issue #2: Cannot Pan/Zoom When Paused

### Current State

**BravenChartPlus** - When paused:
- ✅ Streaming stops (data goes to buffer)
- ✅ `_isStreaming = false`
- ❌ **Auto-scroll STILL DISABLED** - Cannot pan/zoom historical data!

**Why it doesn't work**:
1. `_pauseStreaming()` only sets `_isStreaming = false`
2. Doesn't unlock viewport or enable manual interaction
3. Bounds still calculated with sliding window logic
4. User cannot explore historical data during pause

### User Requirement

> "When autoscrolling, I should be able to pan/zoom the entire dataset as usual (when paused)"

**What this means**:
- When user clicks "Pause" → Should be able to:
  - Pan left to view historical data (all accumulated points)
  - Zoom in/out to inspect details
  - Use full dataset bounds (not sliding window)
- When user clicks "Resume" → Should return to:
  - Auto-scroll mode (following latest data)
  - Sliding window bounds (last N points visible)

### Current Problems in BravenChartPlus

**Line 342-373**: Bounds calculation
```dart
if (widget.streamingConfig?.autoScroll == true && effectiveSeries.isNotEmpty) {
  // Use SLIDING WINDOW bounds (last maxVisiblePoints)
  final maxVisiblePoints = 150;  // HARDCODED!
  // ... calculate rightmost N points ...
} else {
  // Use FULL DATA bounds
  // ... calculate all points ...
}
```

**Problem**: 
- `autoScroll` flag is STATIC (doesn't change when paused)
- Pause state (`_isStreaming`) NOT checked in bounds calculation
- Therefore: Paused chart still uses sliding window bounds

### Proposed Solution

**Option A: Check pause state in bounds calculation**
```dart
if (widget.streamingConfig?.autoScroll == true && 
    _isStreaming &&  // NEW: Only use sliding window when actively streaming
    effectiveSeries.isNotEmpty) {
  // Sliding window (last N points)
} else {
  // Full data bounds (entire dataset)
}
```

**Option B: Separate control for viewport mode**
```dart
enum ViewportMode {
  followLatest,   // Auto-scroll (sliding window)
  explore,        // Manual exploration (full bounds)
}

class StreamingController {
  ViewportMode _viewportMode = ViewportMode.followLatest;
  
  void pauseStreaming() {
    _isStreaming = false;
    _viewportMode = ViewportMode.explore;  // Enable manual interaction
  }
  
  void resumeStreaming() {
    _isStreaming = true;
    _viewportMode = ViewportMode.followLatest;  // Return to auto-scroll
  }
}
```

---

## Comparison: BravenChart vs BravenChartPlus

| Feature | BravenChart (src) | BravenChartPlus (src_plus) |
|---------|-------------------|----------------------------|
| **Window Size Config** | ✅ `maxVisiblePoints` | ❌ Not configurable |
| **Zoom Calculation** | ✅ Automatic (based on window) | ❌ Manual/separate |
| **Pause/Resume** | ⚠️ Via `resumeOnNewData` flag | ✅ Explicit `StreamingController` |
| **Pause → Explore** | ✅ Can pan historical data | ❌ Still uses sliding window |
| **Data Buffering** | ❌ No explicit buffer | ✅ Buffered during pause |
| **Auto-Scroll Method** | Zoom + Pan calculation | Incremental pan (2% steps) |
| **Historical Data** | ✅ Preserved (all points) | ✅ Preserved (all points) |

---

## Recommendations

### For Issue #1 (Window Size Configuration)

**Add to StreamingConfig**:
```dart
class StreamingConfig {
  final int maxBufferSize;
  final bool autoScroll;
  
  // NEW: Window size options
  final int autoScrollWindowSize;  // Number of points (default: 150)
  final Duration? autoScrollWindowDuration;  // Alternative: time window
  
  // If duration provided, calculate points based on data frequency
  // If neither provided, use default 150 points
}
```

**Update bounds calculation** (line 342):
```dart
final windowSize = widget.streamingConfig?.autoScrollWindowSize ?? 150;
if (widget.streamingConfig?.autoScroll == true && effectiveSeries.isNotEmpty) {
  // Use configurable window size instead of hardcoded 150
  final maxVisiblePoints = windowSize;
  // ... rest of sliding window logic ...
}
```

### For Issue #2 (Pause → Explore Mode)

**Option A (Simple)**: Check pause state
```dart
// In _rebuildElements() line 342:
if (widget.streamingConfig?.autoScroll == true && 
    _isStreaming &&  // NEW: Only sliding window when streaming
    effectiveSeries.isNotEmpty) {
  // Sliding window bounds
} else {
  // Full data bounds (allows exploration when paused)
}
```

**Option B (Better UX)**: Add viewport mode to StreamingController
```dart
class StreamingController {
  ViewportMode _viewportMode = ViewportMode.followLatest;
  
  ViewportMode get viewportMode => _viewportMode;
  
  void pauseStreaming() {
    _isStreaming = false;
    _viewportMode = ViewportMode.explore;  // Unlock viewport
    notifyListeners();
  }
  
  void resumeStreaming() {
    _applyBufferedData();
    _isStreaming = true;
    _viewportMode = ViewportMode.followLatest;  // Lock to latest
    notifyListeners();
  }
  
  // NEW: Allow manual viewport mode toggle
  void setViewportMode(ViewportMode mode) {
    _viewportMode = mode;
    notifyListeners();
  }
}
```

Then in bounds calculation:
```dart
final controller = widget.streamingController;
final shouldUseWindowBounds = 
    widget.streamingConfig?.autoScroll == true &&
    controller?.viewportMode == ViewportMode.followLatest;

if (shouldUseWindowBounds && effectiveSeries.isNotEmpty) {
  // Sliding window
} else {
  // Full bounds
}
```

---

## Implementation Priority

1. **High Priority**: Issue #2 (Pause → Explore)
   - Critical UX issue - users expect to explore data when paused
   - Simple fix (add `_isStreaming` check to bounds calculation)
   - Can be done immediately

2. **Medium Priority**: Issue #1 (Window Size Config)
   - Quality of life improvement
   - Requires API changes to `StreamingConfig`
   - Should coordinate with existing `AutoScrollConfig` design

---

## Testing Scenarios

### Issue #1 Tests
- [ ] Set window size to 50 points → Should show last 50 points only
- [ ] Set window size to 200 points → Should show last 200 points
- [ ] Set window duration to 30 seconds @ 10Hz → Should show ~300 points
- [ ] Window size changes while streaming → Should smoothly adjust viewport

### Issue #2 Tests
- [ ] Start streaming → Should auto-scroll (follow latest)
- [ ] Click "Pause" → Should unlock viewport for manual exploration
- [ ] Pan left during pause → Should view historical data (all points)
- [ ] Zoom in during pause → Should zoom into historical data
- [ ] Click "Resume" → Should return to auto-scroll mode
- [ ] Resume should apply buffered data → All data preserved

---

## Next Steps

1. **Discuss with user**: Which option preferred for Issue #2?
   - Option A (simple): Just check `_isStreaming` in bounds calculation
   - Option B (better UX): Add explicit `ViewportMode` to `StreamingController`

2. **Agree on API changes**: How to add window size configuration?
   - Add to existing `StreamingConfig`?
   - Use separate `AutoScrollConfig` (like BravenChart)?
   - Merge concepts into unified config?

3. **Implement fixes**: Based on agreed approach

4. **Test thoroughly**: Both issues with various data rates and patterns
