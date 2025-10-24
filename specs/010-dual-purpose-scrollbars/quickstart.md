# Quickstart: Dual-Purpose Scrollbars

**Feature**: 010-dual-purpose-scrollbars  
**Difficulty**: Beginner  
**Time to Read**: 5 minutes

Get started with dual-purpose scrollbars for chart navigation in minutes.

---

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Configuration](#configuration)
3. [Theming](#theming)
4. [Keyboard Navigation](#keyboard-navigation)
5. [Accessibility](#accessibility)
6. [Performance Tips](#performance-tips)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Basic Usage

### Enable Scrollbars

Add scrollbars to your chart by setting flags in `InteractionConfig`:

```dart
import 'package:braven_charts/braven_charts.dart';

final chart = BravenChart(
  series: [
    LineSeries(
      data: myDataPoints,
      xAccessor: (d) => d.timestamp,
      yAccessor: (d) => d.value,
    ),
  ],
  interactionConfig: InteractionConfig(
    enablePanning: true,     // Allow direct chart pan
    enableZooming: true,     // Allow direct chart zoom
    showXScrollbar: true,    // ← Enable horizontal scrollbar
    showYScrollbar: true,    // ← Enable vertical scrollbar
  ),
  theme: ChartTheme.defaultLight,  // Includes scrollbar theme
);
```

**That's it!** Scrollbars appear automatically and integrate with viewport state.

---

### How It Works

```
User drags scrollbar handle
    ↓
Viewport updates (ViewportState.withRanges())
    ↓
Chart re-renders with new visible range
    ↓
Scrollbar handle position updates to match
```

**No manual wiring needed** - scrollbars automatically sync with chart viewport.

---

## Configuration

### Customize Visual Appearance

Override scrollbar config in your theme:

```dart
final customTheme = ChartTheme.defaultLight.copyWith(
  scrollbarTheme: ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      thickness: 16.0,                    // Thicker scrollbar (default: 12.0)
      minHandleSize: 30.0,                // Larger minimum handle (default: 20.0)
      handleColor: Colors.blue[300]!,     // Custom handle color
      autoHide: false,                    // Always visible (default: true)
    ),
    yAxisScrollbar: ScrollbarConfig.defaultLight,  // Y axis uses default
  ),
);

final chart = BravenChart(
  series: [...],
  interactionConfig: InteractionConfig(
    showXScrollbar: true,
    showYScrollbar: true,
  ),
  theme: customTheme,  // ← Use custom theme
);
```

---

### Configure Interaction Behavior

```dart
final scrollbarConfig = ScrollbarConfig(
  enableResizeHandles: true,    // Allow edge drag to zoom (default: true)
  edgeGripWidth: 8.0,           // Width of resize edge zones (default: 8.0)
  minZoomRatio: 0.01,           // Min zoom: 1% of data (default: 0.01)
  maxZoomRatio: 1.0,            // Max zoom: 100% of data (default: 1.0)
  autoHide: true,               // Auto-hide after 2s inactivity (default: true)
  autoHideDelay: Duration(seconds: 2),
);
```

---

### Disable Zoom (Pan-Only Mode)

```dart
final panOnlyConfig = ScrollbarConfig(
  enableResizeHandles: false,  // Disable edge resize (no zoom)
  // Entire handle now acts as center zone (pan only)
);
```

---

## Theming

### Use Predefined Themes

```dart
// Light theme (light background)
final lightTheme = ChartTheme.defaultLight;
// Scrollbar: light grey track, medium grey handle

// Dark theme (dark background)
final darkTheme = ChartTheme.defaultDark;
// Scrollbar: dark track, light grey handle

// High contrast theme (accessibility)
final highContrastTheme = ChartTheme.highContrast;
// Scrollbar: white track, black handle, colored states
```

---

### Customize Colors

```dart
final customTheme = ChartTheme.defaultLight.copyWith(
  scrollbarTheme: ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFFF5F5F5),      // Light grey track
      handleColor: Color(0xFF2196F3),     // Blue handle
      handleHoverColor: Color(0xFF1976D2), // Darker blue on hover
      handleActiveColor: Color(0xFF0D47A1), // Dark blue when dragging
    ),
    yAxisScrollbar: ScrollbarConfig.defaultLight,
  ),
);
```

---

### Ensure WCAG Compliance

All predefined themes meet WCAG 2.1 AA standards:

| Color Pair | Required Ratio | defaultLight | defaultDark | highContrast |
|------------|----------------|--------------|-------------|--------------|
| Handle vs Track | 4.5:1 | ✓ 5:1 | ✓ 5:1 | ✓ 21:1 |
| Track vs Background | 3:1 | ✓ 4:1 | ✓ 4:1 | ✓ 21:1 |
| Hover vs Handle | 3:1 | ✓ 3.5:1 | ✓ 3.5:1 | ✓ 7:1 |

**Custom themes**: Use a contrast checker (e.g., WebAIM Contrast Checker) to validate ratios.

---

## Keyboard Navigation

Scrollbars support full keyboard control when focused (Tab to focus):

| Key Combination | Action | Increment |
|----------------|--------|-----------|
| **Arrow keys** | Pan (small) | 5% of visible range |
| **Shift + Arrow** | Pan (fast) | 25% of visible range |
| **Ctrl/Cmd + Arrow** | Zoom in/out | ±10% zoom level |
| **Home** | Jump to start | viewportMin = dataMin |
| **End** | Jump to end | viewportMax = dataMax |
| **Page Up/Down** | Jump (large) | 1 viewport width |

---

### Enable Keyboard Access

Scrollbars are keyboard-accessible by default. No configuration needed.

**Focus Flow**:
1. User presses **Tab** → Scrollbar gains focus (visible focus ring)
2. User presses **Arrow keys** → Viewport pans
3. User presses **Tab** again → Focus moves to next widget

---

## Accessibility

### Screen Reader Support

Scrollbars automatically announce state to screen readers:

```
"Chart X-axis scrollbar. 
 Drag to pan, drag edges to zoom, use arrow keys to navigate.
 Showing data from 25.0 to 75.0, 50% of total data."
```

**No configuration needed** - semantic labels generated automatically.

---

### Accessible Keyboard Navigation

All mouse interactions have keyboard equivalents:

| Mouse Action | Keyboard Equivalent |
|-------------|---------------------|
| Drag center | Arrow keys (pan) |
| Drag edges | Ctrl + Arrow (zoom) |
| Click track | Page Up/Down (jump) |
| Hover state | Focus state (Tab) |

---

### Touch-Friendly Sizing

For touch screens, increase handle minimum size:

```dart
final touchFriendlyConfig = ScrollbarConfig(
  thickness: 16.0,         // Thicker for finger taps
  minHandleSize: 44.0,     // WCAG 2.1 touch target minimum
  edgeGripWidth: 12.0,     // Wider edge zones
);
```

---

## Performance Tips

### Scrollbars Are Already Optimized

- **RepaintBoundary Isolation**: Scrollbar renders independently (chart doesn't repaint during drag)
- **60 FPS Throttling**: Viewport updates capped at 60 FPS (no excessive chart re-renders)
- **O(1) Calculations**: Handle position/size computed in <0.1ms

**You don't need to do anything** - performance is built-in.

---

### Verify Performance

Use Flutter DevTools performance overlay:

```dart
import 'package:flutter/rendering.dart';

void main() {
  debugPaintLayerBordersEnabled = true;  // See RepaintBoundary layers
  runApp(MyApp());
}
```

**Expected**: During scrollbar drag, only scrollbar layer repaints (green flash), not chart layer.

---

### Disable Auto-Hide for Performance Monitoring

Auto-hide animations can interfere with performance profiling:

```dart
final monitoringConfig = ScrollbarConfig(
  autoHide: false,  // Always visible (no fade animations)
);
```

---

## Common Patterns

### Pattern 1: Large Dataset Navigation

```dart
// Scenario: 1M data points, user needs to explore specific ranges

final chart = BravenChart(
  series: [LineSeries(data: millionPoints, ...)],
  interactionConfig: InteractionConfig(
    showXScrollbar: true,     // Enable scrollbar for easy navigation
    enablePanning: true,      // Also allow direct chart pan
    enableZooming: true,      // Also allow direct chart zoom
  ),
  theme: ChartTheme.defaultLight.copyWith(
    scrollbarTheme: ScrollbarTheme(
      xAxisScrollbar: ScrollbarConfig(
        minZoomRatio: 0.001,  // Allow zooming to 0.1% (1K points visible)
        autoHide: false,      // Always visible for data exploration
      ),
      yAxisScrollbar: ScrollbarConfig.defaultLight,
    ),
  ),
);
```

---

### Pattern 2: Time Series with Fixed Viewport

```dart
// Scenario: Show last 24 hours, allow scrolling to view history

class TimeSeriesChart extends StatefulWidget {
  @override
  State<TimeSeriesChart> createState() => _TimeSeriesChartState();
}

class _TimeSeriesChartState extends State<TimeSeriesChart> {
  late ViewportState _viewport;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final oneDayAgo = now.subtract(Duration(days: 1));
    _viewport = ViewportState(
      xRange: DataRange(
        min: oneDayAgo.millisecondsSinceEpoch.toDouble(),
        max: now.millisecondsSinceEpoch.toDouble(),
      ),
      yRange: DataRange(min: 0, max: 100),  // Auto-calculated in real app
    );
  }

  @override
  Widget build(BuildContext context) {
    return BravenChart(
      series: [LineSeries(data: historicalData, ...)],
      viewportState: _viewport,
      onViewportChanged: (newViewport) => setState(() => _viewport = newViewport),
      interactionConfig: InteractionConfig(
        showXScrollbar: true,  // Scrollbar shows current 24h window position
      ),
      theme: ChartTheme.defaultLight,
    );
  }
}
```

---

### Pattern 3: Dashboard with Multiple Charts (Synchronized Scrolling)

```dart
// Scenario: Multiple charts share same X axis (time), sync viewport

class SynchronizedChartsExample extends StatefulWidget {
  @override
  State<SynchronizedChartsExample> createState() => _SynchronizedChartsExampleState();
}

class _SynchronizedChartsExampleState extends State<SynchronizedChartsExample> {
  late ViewportState _sharedViewport;

  @override
  void initState() {
    super.initState();
    _sharedViewport = ViewportState(
      xRange: DataRange(min: 0, max: 100),
      yRange: DataRange(min: 0, max: 100),
    );
  }

  void _onViewportChanged(ViewportState newViewport) {
    setState(() => _sharedViewport = newViewport);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart 1: CPU usage
        Expanded(
          child: BravenChart(
            series: [LineSeries(data: cpuData, ...)],
            viewportState: _sharedViewport,
            onViewportChanged: _onViewportChanged,
            interactionConfig: InteractionConfig(showXScrollbar: true),
            theme: ChartTheme.defaultLight,
          ),
        ),
        // Chart 2: Memory usage (shares viewport with Chart 1)
        Expanded(
          child: BravenChart(
            series: [LineSeries(data: memoryData, ...)],
            viewportState: _sharedViewport,  // ← Same viewport
            onViewportChanged: _onViewportChanged,
            interactionConfig: InteractionConfig(
              showXScrollbar: true,  // Both scrollbars sync automatically
            ),
            theme: ChartTheme.defaultLight,
          ),
        ),
      ],
    );
  }
}
```

**Result**: Dragging scrollbar in Chart 1 updates Chart 2 viewport (both scrollbars move in sync).

---

### Pattern 4: Simplified Scrollbar (Pan-Only, No Zoom)

```dart
// Scenario: Basic scrollbar for simple navigation (no zoom complexity)

final simplifiedTheme = ChartTheme.defaultLight.copyWith(
  scrollbarTheme: ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      enableResizeHandles: false,  // Disable edge resize
      // Entire handle is now center zone (pan only)
    ),
    yAxisScrollbar: ScrollbarConfig(
      enableResizeHandles: false,
    ),
  ),
);

final chart = BravenChart(
  series: [...],
  interactionConfig: InteractionConfig(
    showXScrollbar: true,
    showYScrollbar: true,
    enableZooming: false,  // Also disable direct chart zoom
  ),
  theme: simplifiedTheme,
);
```

---

## Troubleshooting

### Issue: Scrollbar Not Appearing

**Symptoms**: Chart renders, but no scrollbar visible.

**Causes & Solutions**:

1. **InteractionConfig flags not set**:
   ```dart
   // ❌ Missing flags
   interactionConfig: InteractionConfig()
   
   // ✅ Enable scrollbars
   interactionConfig: InteractionConfig(
     showXScrollbar: true,
     showYScrollbar: true,
   )
   ```

2. **Auto-hide enabled and no recent interaction**:
   ```dart
   // ✅ Disable auto-hide for debugging
   scrollbarTheme: ScrollbarTheme(
     xAxisScrollbar: ScrollbarConfig(autoHide: false),
     yAxisScrollbar: ScrollbarConfig(autoHide: false),
   )
   ```

3. **Viewport equals data range (nothing to scroll)**:
   - If viewportRange == dataRange, handle fills entire track (nothing to scroll)
   - Zoom in to create smaller viewport (handle shrinks, scrolling enabled)

---

### Issue: Handle Too Small to Grab

**Symptoms**: Viewing <5% of data, handle renders as tiny sliver.

**Solution**: Increase `minHandleSize`:

```dart
ScrollbarConfig(
  minHandleSize: 40.0,  // Larger minimum (default: 20.0)
)
```

**Trade-off**: Handle size no longer accurately represents viewport ratio when clamped.

---

### Issue: Scrollbar Drag Lags Behind Mouse

**Symptoms**: Mouse moves, but handle position updates slowly (feels sluggish).

**Cause**: Chart re-render too slow (>16ms), throttling delays visible updates.

**Solution**:

1. **Optimize chart rendering**:
   - Reduce data points (downsample before rendering)
   - Simplify series styling (fewer gradients/shadows)
   - Use RepaintBoundary around chart (already default)

2. **Profile with DevTools**:
   ```dart
   import 'package:flutter/rendering.dart';
   debugPaintLayerBordersEnabled = true;
   ```
   - Verify only scrollbar layer repaints during drag (not chart)

3. **Check viewport update callback**:
   ```dart
   // ❌ Expensive work in callback
   onViewportChanged: (newRange) {
     setState(() {
       _viewport = calculateComplexTransformation(newRange);  // Slow!
     });
   }
   
   // ✅ Lightweight callback
   onViewportChanged: (newRange) {
     setState(() {
       _viewport = _viewport.withRanges(newRange, _viewport.yRange);  // Fast
     });
   }
   ```

---

### Issue: Keyboard Navigation Not Working

**Symptoms**: Pressing arrow keys does nothing.

**Cause**: Scrollbar doesn't have focus.

**Solution**: Press **Tab** to focus scrollbar first, then use arrow keys.

**Debug**:
```dart
// Verify focus indicator visible
ScrollbarConfig(
  // Focus ring should appear when scrollbar focused
)
```

---

### Issue: Scrollbar Colors Don't Match Chart Theme

**Symptoms**: Chart is dark theme, but scrollbar is light grey.

**Cause**: Forgot to customize scrollbarTheme in ChartTheme.

**Solution**:
```dart
// ✅ Use matching theme
final darkTheme = ChartTheme.defaultDark;  // Includes dark scrollbar

// ✅ Or customize
final customTheme = ChartTheme.defaultLight.copyWith(
  backgroundColor: Color(0xFF121212),  // Dark background
  scrollbarTheme: ScrollbarTheme.defaultDark,  // Dark scrollbar
);
```

---

### Issue: Scrollbar Overlaps Chart Data

**Symptoms**: Scrollbar renders on top of chart, obscuring data points.

**Cause**: Layout issue (scrollbar should be outside chart canvas).

**Expected Layout**:
```
┌───────────────────────────────┬───┐
│                               │ Y │  ← Y scrollbar on right
│       Chart Canvas            │   │
│                               │   │
└───────────────────────────────┴───┘
└───────────────────────────────┘
        X scrollbar below            ← X scrollbar below
```

**Solution**: BravenChart handles layout automatically. If issue persists, check for custom layout wrappers.

---

## Next Steps

- **Read Full Spec**: [spec.md](./spec.md) - Detailed requirements and edge cases
- **Explore Examples**: `example/lib/charts/scrollbar_examples.dart` - Working demos
- **API Reference**: [contracts/](./contracts/) - Complete API documentation
- **Theming Guide**: [docs/guides/theming-usage.md](../../../docs/guides/theming-usage.md) - Advanced theming patterns

---

## Common Questions

**Q: Can I have X scrollbar without Y scrollbar?**  
A: Yes! Set `showXScrollbar: true, showYScrollbar: false` in InteractionConfig.

**Q: Can I programmatically control scrollbar position?**  
A: Yes, update ViewportState and scrollbar syncs automatically:
```dart
setState(() {
  _viewport = _viewport.withRanges(
    DataRange(min: 50, max: 100),  // Scrollbar moves to 50% position
    _viewport.yRange,
  );
});
```

**Q: Does scrollbar work with touch screens?**  
A: Yes! Increase `minHandleSize` to 44px for WCAG touch target compliance.

**Q: Can I change scrollbar position (e.g., Y scrollbar on left)?**  
A: Not in v1.0. Scrollbars always render below (X) and right (Y). Request as feature if needed.

**Q: Do scrollbars work with zoomed charts?**  
A: Yes! Handle size = (viewport / data range) ratio. Zoom in → smaller handle, more scroll range.

**Q: Can I disable pan but keep zoom?**  
A: Yes:
```dart
ScrollbarConfig(
  enableResizeHandles: true,  // Edge drag = zoom (enabled)
  // But disable center drag by overriding interaction zone logic (advanced)
)
```
Simpler: Use chart-level zoom controls, disable scrollbar pan via custom implementation.

---

**Happy scrolling!** 🚀
