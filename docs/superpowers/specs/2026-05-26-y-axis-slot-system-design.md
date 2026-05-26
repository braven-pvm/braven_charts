# Y-Axis Slot System Design

## Goal

Replace the unbounded multi-position Y-axis system (leftOuter / left / right / rightOuter) with a clean slot-based system that caps visible axes per side, demotes overflow axes gracefully, and lets users swap a hidden axis in by selecting its series.

## Context

The current system allows unlimited axes at any of four positions. When many series each declare a dedicated `YAxisConfig` with the same `YAxisPosition.right`, all of them render — producing visual chaos (overlapping labels, no readable scale). There is no cap, no priority, and no recovery UX.

---

## API Design

### `YAxisPosition` enum — deprecate outer variants

```dart
enum YAxisPosition {
  left,
  right,
  hidden,

  @Deprecated('Use YAxisPosition.left instead')
  leftOuter,   // normalised to left at runtime in YAxisConfig constructor

  @Deprecated('Use YAxisPosition.right instead')
  rightOuter,  // normalised to right at runtime in YAxisConfig constructor
}
```

Existing code still compiles with warnings. At runtime `leftOuter` and `rightOuter` behave identically to `left` and `right` respectively. No behavioural regression.

### New `AxisSwapMode` enum

```dart
/// Controls what happens to the swap state when a series is deselected.
enum AxisSwapMode {
  /// The swapped-in axis stays visible after deselection (default).
  sticky,

  /// The slot order reverts to the original declaration order on deselection.
  revert,
}
```

File: `lib/src/models/axis_swap_mode.dart`

### New `BravenChartController`

```dart
/// Programmatic control over series selection and axis slot state.
///
/// Attach to [BravenChartPlus.controller]. All methods are no-ops if the
/// controller is not yet attached to a mounted chart.
///
/// Example:
/// ```dart
/// final controller = BravenChartController();
///
/// BravenChartPlus(
///   controller: controller,
///   ...
/// )
///
/// // Trigger axis swap from outside the chart:
/// controller.selectSeries('heat_strain');
/// ```
class BravenChartController extends ChangeNotifier {
  /// Selects [seriesId]. If its axis is in overflow, promotes it to a visible
  /// slot by demoting the last-declared visible axis on the same side.
  /// Fires [BravenChartPlus.onSeriesSelected] and, if a swap occurred,
  /// [BravenChartPlus.onAxisSwapped].
  void selectSeries(String seriesId);

  /// Deselects [seriesId]. If [BravenChartPlus.axisSwapMode] is [AxisSwapMode.revert],
  /// restores the original slot order for that side.
  void deselectSeries(String seriesId);

  /// Deselects all series. Reverts slot order on both sides if mode is [AxisSwapMode.revert].
  void clearSelection();

  /// Currently selected series ID, or null if nothing is selected.
  String? get selectedSeriesId;

  /// Axis IDs currently occupying visible slots, in slot order.
  /// Updated after every swap.
  List<String> get visibleAxisIds;

  /// Axis IDs currently in overflow (voted out of visible slots).
  List<String> get overflowAxisIds;
}
```

File: `lib/src/models/braven_chart_controller.dart`

### New `BravenChartPlus` parameters

```dart
BravenChartPlus(
  // --- existing (unchanged) ---
  series: [...],
  xAxisConfig: ...,

  // --- new ---

  /// Maximum number of Y-axes visible on each side simultaneously.
  /// Declaration order determines which axes fill the first [maxAxesPerSide]
  /// slots. Excess axes are placed in overflow (hidden but still normalised).
  /// Defaults to 3. Must be >= 1.
  maxAxesPerSide: 3,

  /// Controls swap persistence on deselection. Defaults to [AxisSwapMode.sticky].
  axisSwapMode: AxisSwapMode.sticky,

  /// Optional controller for programmatic selection and slot inspection.
  controller: BravenChartController(),

  /// Called when any series becomes selected (legend tap, data-point tap,
  /// or [BravenChartController.selectSeries]).
  onSeriesSelected: (String seriesId) { },

  /// Called when a series is deselected.
  onSeriesDeselected: (String seriesId) { },

  /// Called immediately after an axis swap completes.
  /// [promotedAxisId] entered a visible slot; [demotedAxisId] moved to overflow.
  onAxisSwapped: ({
    required String promotedAxisId,
    required String demotedAxisId,
  }) { },
)
```

---

## Slot Resolution Logic

### Initial resolution (at every layout)

1. Collect all effective Y-axes from `MultiAxisManager.getEffectiveYAxes()`.
2. Normalise deprecated positions (`leftOuter` → `left`, `rightOuter` → `right`) via `YAxisConfig._normalizePosition()`.
3. For each side (`left`, `right`), group axes in declaration order.
4. The first `maxAxesPerSide` axes per side are **visible**; the rest are **overflow**.
5. Overflow axes are treated as `YAxisPosition.hidden` for painting — they take no space, render no ticks or labels — but remain in bounds computation so their series lines scale correctly.
6. If a swap is currently active (sticky state), the swapped slot order overrides declaration order for that side.

### Swap on selection

When `_handleSeriesSelected(seriesId)` is called:

1. Resolve which axis the series is bound to (`axisId`).
2. If `axisId` is not in overflow → no axis swap. Series is still marked selected; `onSeriesSelected` fires.
3. If `axisId` is in overflow:
   a. Find the last-declared visible axis on the same side — this is the demote candidate.
   b. Move demote candidate to overflow.
   c. Move `axisId` to slot `maxAxesPerSide` (last visible slot).
   d. Call `setState()` → repaint.
   e. Fire `onAxisSwapped(promotedAxisId: axisId, demotedAxisId: demotedAxisId)`.
   f. Fire `onSeriesSelected(seriesId)`.

### Deselect behaviour

- **`AxisSwapMode.sticky`** (default): swap persists. Selecting a second overflow series triggers another swap from the new last-declared visible axis. The user gradually builds their preferred visible set.
- **`AxisSwapMode.revert`**: the original declaration-order slot assignment is restored for the affected side. Both `onSeriesDeselected` and `onAxisSwapped` fire (with promoted/demoted reversed).

### Tap-to-deselect

Tapping an already-selected series calls `_handleSeriesDeselected(seriesId)`. Tapping empty chart space (no series hit) calls `clearSelection()`.

---

## Selection Trigger Paths

All three paths converge on `_BravenChartPlusState._handleSeriesSelected(String seriesId)`:

### 1. Legend tap

`ChartLegend` already has `onSeriesToggle`. A new parallel callback `onSeriesTap` is added:

```dart
ChartLegend(
  onSeriesToggle: ...,   // existing — shows/hides series line
  onSeriesTap: (id) => _handleSeriesSelected(id),   // new — drives axis swap
)
```

`onSeriesTap` fires on every tap. `onSeriesToggle` remains unchanged — it controls line visibility independently of axis slot selection.

### 2. Data-point / series-line tap

`EventHandlerManager` already resolves a series from pointer hits. On a tap event (not drag), if a series is resolved, it calls `onSeriesSelected(seriesId)` — a new callback wired from `ChartRenderBox` up to `_BravenChartPlusState`.

### 3. Programmatic

`BravenChartController.selectSeries(id)` → calls into `_BravenChartPlusState` via an internal `_attach()` reference set in `initState`.

---

## Files Changed

| File | Status | Change |
|------|--------|--------|
| `lib/src/models/y_axis_position.dart` | modify | Add `@Deprecated` to `leftOuter` / `rightOuter` |
| `lib/src/models/y_axis_config.dart` | modify | Add `_normalizePosition()` called in constructor; normalises deprecated enum values |
| `lib/src/models/axis_swap_mode.dart` | **new** | `enum AxisSwapMode { sticky, revert }` |
| `lib/src/models/braven_chart_controller.dart` | **new** | `BravenChartController` with select/deselect/clear/getters |
| `lib/src/rendering/modules/multi_axis_manager.dart` | modify | Add slot resolution: `_visibleAxisIds`, `_overflowAxisIds`, swap method `applySeriesSelection()`, sticky/revert state |
| `lib/src/braven_chart_plus.dart` | modify | Add `maxAxesPerSide`, `axisSwapMode`, `controller`, callbacks; wire `_handleSeriesSelected` / `_handleSeriesDeselected`; pass slot config to `MultiAxisManager` |
| `lib/src/rendering/modules/event_handler_manager.dart` | modify | On tap: resolve series → call `onSeriesSelected` callback (new field on manager, set from `ChartRenderBox`) |
| `lib/src/rendering/chart_render_box.dart` | modify | Accept `onSeriesSelected` callback; pass through from widget to `EventHandlerManager` |
| `lib/src/widgets/chart_legend.dart` | modify | Add `onSeriesTap: ValueChanged<String>?` callback; fire on legend row tap alongside `onSeriesToggle` |
| `lib/braven_charts.dart` | modify | Barrel-export `AxisSwapMode`, `BravenChartController` |

---

## Invariants

- Overflow axes are **always** included in bounds computation. Their series lines always render. Only the axis label column is suppressed.
- `maxAxesPerSide` applies independently to left and right. Left can have 3 visible while right has 2.
- A series bound to `YAxisPosition.hidden` (intentionally hidden) is **never** promoted by the swap — overflow is a separate state from intentionally hidden.
- If fewer axes claim a side than `maxAxesPerSide`, all are visible. No artificial padding.
- Swapping is animated: axes slide in/out using the existing `markNeedsLayout()` → `performLayout()` path; no separate animation controller needed (layout already triggers repaint).
- `MultiAxisManager` persists `_visibleAxisIds` and `_overflowAxisIds` as mutable lists across `performLayout` calls. On each layout, if swap state exists it is used as-is; otherwise declaration order is used. This prevents a resize from resetting an active swap.
- "Last-declared visible axis" in swap logic always means the last element of the *current* `_visibleAxisIds` list for that side — not the original declaration order. After a first swap this may differ from the originally-last-declared axis.
- `BravenChartController` is optional. Charts without one work identically — selection state is managed internally in `_BravenChartPlusState`.

---

## Out of Scope

- Minor grid lines for overflow axes (no grid lines added).
- Per-series `axisPriority` field (declaration order is the priority).
- More than two sides (top/bottom Y-axes).
- Animated swap transition beyond the default layout repaint.
