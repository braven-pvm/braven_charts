# Y-Axis Slot System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the unbounded multi-position Y-axis system with a slot-based system that caps visible axes per side, demotes overflow axes gracefully, and lets users swap a hidden axis in by tapping its series.

**Architecture:** All slot resolution lives in `MultiAxisManager` — it gains a `getVisibleAxes()` method (declaration-order, capped at `maxAxesPerSide`) alongside the existing `getEffectiveYAxes()` (all axes, unchanged). Painters and layout delegates are switched to `getVisibleAxes()` so overflow axes take no space and paint nothing. Selection swap mutates the internal slot-override lists in `MultiAxisManager` and triggers a repaint via `markNeedsLayout()`. The widget layer wires three trigger paths (legend tap, series tap, programmatic controller) to a single `_handleSeriesSelected()` method.

**Tech Stack:** Flutter/Dart, immutable model pattern (copyWith/==/hashCode/toString), `ChangeNotifier` for `BravenChartController`.

---

## File Map

| File | Status | Responsibility |
|------|--------|----------------|
| `lib/src/models/y_axis_position.dart` | modify | Deprecate `leftOuter`/`rightOuter` |
| `lib/src/models/y_axis_config.dart` | modify | Normalise deprecated positions in constructor |
| `lib/src/models/axis_swap_mode.dart` | **new** | `enum AxisSwapMode { sticky, revert }` |
| `lib/src/models/braven_chart_controller.dart` | **new** | Public API for programmatic series selection |
| `lib/braven_charts.dart` | modify | Barrel-export new models |
| `lib/src/layout/axis_layout_manager.dart` | modify | Stack multiple axes at same position |
| `lib/src/rendering/modules/multi_axis_manager.dart` | modify | Slot state, `getVisibleAxes()`, swap method |
| `lib/src/widgets/chart_legend.dart` | modify | Add `onSeriesTap` callback |
| `lib/src/braven_chart_plus.dart` | modify | New params, `_handleSeriesSelected/Deselected`, controller wiring |
| `lib/src/rendering/chart_render_box.dart` | modify | Pass `maxAxesPerSide`/`axisSwapMode` to `MultiAxisManager` |
| `test/unit/models/axis_swap_mode_test.dart` | **new** | Enum tests |
| `test/unit/multi_axis/slot_resolution_test.dart` | **new** | Slot logic tests |
| `example/lib/showcase/pages/axis_slot_demo_page.dart` | **new** | Visual demo |

---

## Task 1: Model Layer

**Files:**
- Modify: `lib/src/models/y_axis_position.dart`
- Modify: `lib/src/models/y_axis_config.dart`
- Create: `lib/src/models/axis_swap_mode.dart`
- Create: `lib/src/models/braven_chart_controller.dart`
- Modify: `lib/braven_charts.dart`
- Create: `test/unit/models/axis_swap_mode_test.dart`

---

- [ ] **Step 1: Write failing tests for AxisSwapMode**

Create `test/unit/models/axis_swap_mode_test.dart`:

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:test/test.dart';

void main() {
  group('AxisSwapMode', () {
    test('has two values', () {
      expect(AxisSwapMode.values, hasLength(2));
      expect(AxisSwapMode.values, containsAll([
        AxisSwapMode.sticky,
        AxisSwapMode.revert,
      ]));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
cd f:/Repositories/braven_charts
flutter test test/unit/models/axis_swap_mode_test.dart
```

Expected: FAIL — `AxisSwapMode` not defined.

- [ ] **Step 3: Create `lib/src/models/axis_swap_mode.dart`**

```dart
/// Controls swap persistence when a series is deselected.
///
/// Used with [BravenChartPlus.axisSwapMode] to configure whether a
/// swap triggered by series selection persists after deselection.
///
/// Example:
/// ```dart
/// BravenChartPlus(
///   axisSwapMode: AxisSwapMode.sticky, // default
///   ...
/// )
/// ```
enum AxisSwapMode {
  /// The swapped-in axis stays visible after deselection (default).
  ///
  /// Subsequent selections of other overflow series trigger additional
  /// swaps, each bumping the current last-declared visible axis on that side.
  sticky,

  /// The slot order reverts to original declaration order on deselection.
  ///
  /// Both [BravenChartPlus.onSeriesDeselected] and
  /// [BravenChartPlus.onAxisSwapped] fire with promoted/demoted reversed.
  revert,
}
```

- [ ] **Step 4: Create `lib/src/models/braven_chart_controller.dart`**

```dart
import 'package:flutter/foundation.dart';

/// Programmatic control over series selection and Y-axis slot state.
///
/// Attach to [BravenChartPlus.controller] to drive series selection
/// and axis swaps from outside the chart widget.
///
/// The controller is optional — charts without one still respond to
/// legend taps and data-point taps internally. Add a controller only
/// when you need to read slot state or trigger selection externally.
///
/// Example:
/// ```dart
/// final _controller = BravenChartController();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// // Somewhere outside the chart:
/// _controller.selectSeries('heat_strain');
/// print(_controller.visibleAxisIds);
/// ```
class BravenChartController extends ChangeNotifier {
  // Internal hook set by _BravenChartPlusState in initState/didUpdateWidget.
  void Function(String seriesId)? _selectHandler;
  void Function(String seriesId)? _deselectHandler;
  void Function()? _clearHandler;

  // Slot state mirrored from MultiAxisManager (updated after every swap).
  String? _selectedSeriesId;
  List<String> _visibleAxisIds = const [];
  List<String> _overflowAxisIds = const [];

  // ---- Public read API ----

  /// Currently selected series ID, or null if nothing is selected.
  String? get selectedSeriesId => _selectedSeriesId;

  /// Axis IDs currently occupying visible slots, in slot order.
  List<String> get visibleAxisIds => List.unmodifiable(_visibleAxisIds);

  /// Axis IDs currently in overflow (voted out of visible slots).
  List<String> get overflowAxisIds => List.unmodifiable(_overflowAxisIds);

  // ---- Public command API ----

  /// Selects [seriesId]. If its axis is in overflow, promotes it to a visible
  /// slot by demoting the last-declared visible axis on the same side.
  ///
  /// Fires [BravenChartPlus.onSeriesSelected] and, if a swap occurred,
  /// [BravenChartPlus.onAxisSwapped]. No-op if the controller is not
  /// attached to a mounted chart.
  void selectSeries(String seriesId) => _selectHandler?.call(seriesId);

  /// Deselects [seriesId]. If [BravenChartPlus.axisSwapMode] is
  /// [AxisSwapMode.revert], restores the original slot order for that side.
  ///
  /// No-op if the controller is not attached to a mounted chart.
  void deselectSeries(String seriesId) => _deselectHandler?.call(seriesId);

  /// Deselects all series. Reverts slot order on both sides if mode is
  /// [AxisSwapMode.revert].
  ///
  /// No-op if the controller is not attached to a mounted chart.
  void clearSelection() => _clearHandler?.call();

  // ---- Internal state sync (called by _BravenChartPlusState) ----

  /// Attaches this controller to a chart state. Called by the state.
  void attach({
    required void Function(String) onSelect,
    required void Function(String) onDeselect,
    required void Function() onClear,
  }) {
    _selectHandler = onSelect;
    _deselectHandler = onDeselect;
    _clearHandler = onClear;
  }

  /// Detaches from the chart state. Called in dispose.
  void detach() {
    _selectHandler = null;
    _deselectHandler = null;
    _clearHandler = null;
  }

  /// Updates mirrored slot state (called after every swap or selection change).
  void updateSlotState({
    required String? selectedSeriesId,
    required List<String> visibleAxisIds,
    required List<String> overflowAxisIds,
  }) {
    _selectedSeriesId = selectedSeriesId;
    _visibleAxisIds = visibleAxisIds;
    _overflowAxisIds = overflowAxisIds;
    notifyListeners();
  }
}
```

- [ ] **Step 5: Deprecate `leftOuter`/`rightOuter` in `lib/src/models/y_axis_position.dart`**

Replace the file content:

```dart
/// Defines the positions where Y-axes can appear in a multi-axis chart.
///
/// Multi-axis charts support up to [BravenChartPlus.maxAxesPerSide] Y-axes
/// visible per side simultaneously. Axes on each side are stacked from the
/// plot area outward in declaration order.
///
/// ```
/// [left...] | Chart Area | [...right]
/// ```
///
/// The [left] position is the standard position for the primary Y-axis.
/// Add more axes with [right] (or additional [left] configs on separate series).
enum YAxisPosition {
  /// Left side — adjacent to plot area, stacked outward in declaration order.
  ///
  /// This is the standard position for the main Y-axis in most charts.
  left,

  /// Right side — adjacent to plot area, stacked outward in declaration order.
  ///
  /// Use for secondary or tertiary axes with different scales or units.
  right,

  /// Hidden axis — participates in data normalization but takes no visual space.
  ///
  /// Equivalent to setting [YAxisConfig.visible] to `false`. Use when a series
  /// needs its own Y-axis for normalization purposes but the axis itself
  /// should not be rendered (no ticks, labels, or line).
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'reference',
  ///   yAxisConfig: YAxisConfig(position: YAxisPosition.hidden, min: 0, max: 100),
  /// )
  /// ```
  hidden,

  /// Deprecated. Use [left] instead.
  ///
  /// Previously: leftmost axis (far left of plot area).
  /// Now: treated identically to [left] at runtime.
  @Deprecated('Use YAxisPosition.left instead. leftOuter is treated as left.')
  leftOuter,

  /// Deprecated. Use [right] instead.
  ///
  /// Previously: rightmost axis (far right of plot area).
  /// Now: treated identically to [right] at runtime.
  @Deprecated('Use YAxisPosition.right instead. rightOuter is treated as right.')
  rightOuter,
}
```

- [ ] **Step 6: Add `_normalizePosition()` to `YAxisConfig` constructor**

In `lib/src/models/y_axis_config.dart`, locate the public constructor (line ~160) and add position normalisation. Replace the constructor initialiser list:

```dart
  YAxisConfig({
    required YAxisPosition position,
    // ... all other params unchanged ...
  })  : id = '',
        // ignore: deprecated_member_use_from_same_package
        position = (position == YAxisPosition.leftOuter)
            ? YAxisPosition.left
            // ignore: deprecated_member_use_from_same_package
            : (position == YAxisPosition.rightOuter)
                ? YAxisPosition.right
                : position,
        visible = position == YAxisPosition.hidden ? false : visible,
        assert(minWidth >= 0, 'minWidth must be non-negative'),
        assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth'),
        assert(
          min == null || max == null || min < max,
          'min must be less than max',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be >= 2',
        );
```

Also update `copyWith` to expose `position` properly — it already does since it passes through to `_internal`. The `_internal` constructor does NOT need normalisation (it accepts raw values for internal use).

- [ ] **Step 7: Add barrel exports in `lib/braven_charts.dart`**

After the `chart_controller.dart` export line, add:

```dart
export 'src/models/axis_swap_mode.dart';
export 'src/models/braven_chart_controller.dart';
```

- [ ] **Step 8: Run tests and analyzer**

```
flutter test test/unit/models/axis_swap_mode_test.dart
flutter analyze lib/src/models/
```

Expected: All tests pass, no analysis errors. Existing tests that use `leftOuter`/`rightOuter` will show deprecation warnings — that is correct.

- [ ] **Step 9: Commit**

```
git add lib/src/models/y_axis_position.dart lib/src/models/y_axis_config.dart lib/src/models/axis_swap_mode.dart lib/src/models/braven_chart_controller.dart lib/braven_charts.dart test/unit/models/axis_swap_mode_test.dart
git commit -m "feat: add AxisSwapMode enum and BravenChartController; deprecate leftOuter/rightOuter"
```

---

## Task 2: Slot Resolution

**Files:**
- Modify: `lib/src/layout/axis_layout_manager.dart`
- Modify: `lib/src/rendering/modules/multi_axis_manager.dart`
- Create: `test/unit/multi_axis/slot_resolution_test.dart`

**Context:** `MultiAxisManager.getEffectiveYAxes()` returns ALL axes in declaration order (unchanged). The new `getVisibleAxes()` applies the slot cap and swap overrides. Painters and width computations switch to `getVisibleAxes()`. `computeAxisBounds()` keeps using `getEffectiveYAxes()` so overflow series still normalise correctly.

---

- [ ] **Step 1: Write failing slot-resolution tests**

Create `test/unit/multi_axis/slot_resolution_test.dart`:

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:test/test.dart';

// Helper to build a LineChartSeries with a named right-side yAxisConfig
LineChartSeries _rightSeries(String id) => LineChartSeries(
      id: id,
      points: const [],
      yAxisConfig: YAxisConfig(position: YAxisPosition.right, label: id),
    );

LineChartSeries _leftSeries(String id) => LineChartSeries(
      id: id,
      points: const [],
      yAxisConfig: YAxisConfig(position: YAxisPosition.left, label: id),
    );

void main() {
  group('MultiAxisManager slot resolution', () {
    late MultiAxisManager manager;

    setUp(() {
      manager = MultiAxisManager();
    });

    test('all axes visible when count <= maxAxesPerSide', () {
      manager.setSeries([_rightSeries('a'), _rightSeries('b'), _rightSeries('c')]);
      manager.setMaxAxesPerSide(3);
      final visible = manager.getVisibleAxes();
      expect(visible.where((a) => a.position == YAxisPosition.right), hasLength(3));
    });

    test('overflow axes are excluded from getVisibleAxes', () {
      manager.setSeries([
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'),
        _rightSeries('d'), _rightSeries('e'),
      ]);
      manager.setMaxAxesPerSide(3);
      final visible = manager.getVisibleAxes();
      expect(visible.where((a) => a.position == YAxisPosition.right), hasLength(3));
      final visibleIds = visible.map((a) => a.id).toSet();
      expect(visibleIds, contains('a_axis'));
      expect(visibleIds, contains('b_axis'));
      expect(visibleIds, contains('c_axis'));
      expect(visibleIds, isNot(contains('d_axis')));
      expect(visibleIds, isNot(contains('e_axis')));
    });

    test('overflowAxisIds returns ids outside the slot cap', () {
      manager.setSeries([
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ]);
      manager.setMaxAxesPerSide(3);
      final overflow = manager.overflowAxisIds;
      expect(overflow, contains('d_axis'));
      expect(overflow, isNot(contains('a_axis')));
    });

    test('left and right caps are independent', () {
      manager.setSeries([
        _leftSeries('l1'), _leftSeries('l2'), _leftSeries('l3'), _leftSeries('l4'),
        _rightSeries('r1'), _rightSeries('r2'),
      ]);
      manager.setMaxAxesPerSide(3);
      final visible = manager.getVisibleAxes();
      expect(visible.where((a) => a.position == YAxisPosition.left), hasLength(3));
      expect(visible.where((a) => a.position == YAxisPosition.right), hasLength(2));
    });

    test('applySeriesSelection promotes overflow axis to last visible slot', () {
      manager.setSeries([
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ]);
      manager.setMaxAxesPerSide(3);

      final series = [
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ];

      manager.applySeriesSelection('d', series);

      final visible = manager.getVisibleAxes();
      final visibleRightIds = visible
          .where((a) => a.position == YAxisPosition.right)
          .map((a) => a.id)
          .toList();

      // d_axis should be visible; c_axis (previously last) should be demoted
      expect(visibleRightIds, contains('d_axis'));
      expect(visibleRightIds, isNot(contains('c_axis')));
      expect(manager.overflowAxisIds, contains('c_axis'));
    });

    test('clearSelection restores declaration order in revert mode', () {
      manager.setSeries([
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ]);
      manager.setMaxAxesPerSide(3);
      manager.setAxisSwapMode(AxisSwapMode.revert);

      final series = [
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ];
      manager.applySeriesSelection('d', series);
      manager.clearSelectionFor('d', series);

      final visible = manager.getVisibleAxes();
      final visibleRightIds = visible
          .where((a) => a.position == YAxisPosition.right)
          .map((a) => a.id)
          .toList();

      expect(visibleRightIds, contains('c_axis'));
      expect(visibleRightIds, isNot(contains('d_axis')));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm failure**

```
flutter test test/unit/multi_axis/slot_resolution_test.dart
```

Expected: FAIL — `setMaxAxesPerSide`, `getVisibleAxes`, etc. not found.

- [ ] **Step 3: Add slot state fields to `MultiAxisManager`**

At the top of the State section (after `_cachedEffectiveBindings`, around line 64), add:

```dart
  /// Maximum number of Y-axes visible on each side simultaneously.
  int _maxAxesPerSide = 3;

  /// Swap behaviour on deselection.
  AxisSwapMode _axisSwapMode = AxisSwapMode.sticky;

  /// Swap-override for left side. null = use declaration order.
  /// Non-null = this ordered list of axis IDs is the current left visible set.
  List<String>? _overriddenLeftIds;

  /// Swap-override for right side.
  List<String>? _overriddenRightIds;

  /// Currently selected series ID (for deselect/revert logic).
  String? _selectedSeriesId;
```

Add import at the top of the file:

```dart
import '../../models/axis_swap_mode.dart';
```

- [ ] **Step 4: Add configuration setters to `MultiAxisManager`**

After `setPrimaryYAxisConfig()`, add:

```dart
  /// Sets the maximum number of visible Y-axes per side.
  ///
  /// Returns true if the value changed.
  bool setMaxAxesPerSide(int max) {
    assert(max >= 1, 'maxAxesPerSide must be >= 1');
    if (_maxAxesPerSide == max) return false;
    _maxAxesPerSide = max;
    _overriddenLeftIds = null;
    _overriddenRightIds = null;
    return true;
  }

  /// Sets the swap mode for deselection behaviour.
  ///
  /// Returns true if the value changed.
  bool setAxisSwapMode(AxisSwapMode mode) {
    if (_axisSwapMode == mode) return false;
    _axisSwapMode = mode;
    return true;
  }
```

Also update `invalidateCache()` to clear override state:

```dart
  void invalidateCache() {
    _cachedEffectiveBindings = null;
    _overriddenLeftIds = null;
    _overriddenRightIds = null;
    _selectedSeriesId = null;
  }
```

- [ ] **Step 5: Add `getVisibleAxes()` and `overflowAxisIds` to `MultiAxisManager`**

Add after `getEffectiveYAxes()`:

```dart
  /// Gets the Y-axes that are currently in visible slots.
  ///
  /// Returns at most [_maxAxesPerSide] axes per side. Overflow axes
  /// (those beyond the cap) are excluded — they take no space and
  /// are not painted, but their series lines still render.
  ///
  /// When a swap override is active (after [applySeriesSelection]),
  /// the overridden order is used instead of declaration order.
  ///
  /// [YAxisPosition.hidden] axes are always included — they are
  /// intentionally hidden and not subject to slot capping.
  List<YAxisConfig> getVisibleAxes() {
    final all = getEffectiveYAxes();
    final leftAxes = all.where((a) => a.position == YAxisPosition.left).toList();
    final rightAxes = all.where((a) => a.position == YAxisPosition.right).toList();
    final hiddenAxes = all.where((a) => a.position == YAxisPosition.hidden).toList();

    return [
      ..._applySlotCap(leftAxes, _overriddenLeftIds),
      ..._applySlotCap(rightAxes, _overriddenRightIds),
      ...hiddenAxes,
    ];
  }

  /// Axis IDs currently outside the slot cap (not rendered).
  List<String> get overflowAxisIds {
    final all = getEffectiveYAxes();
    final visible = getVisibleAxes();
    final visibleIds = visible.map((a) => a.id).toSet();
    return all
        .where((a) => a.position != YAxisPosition.hidden)
        .where((a) => !visibleIds.contains(a.id))
        .map((a) => a.id)
        .toList();
  }

  List<YAxisConfig> _applySlotCap(List<YAxisConfig> axes, List<String>? overrideIds) {
    if (overrideIds != null) {
      // Preserve the swap-ordered list
      final byId = {for (final a in axes) a.id: a};
      return overrideIds
          .where(byId.containsKey)
          .map((id) => byId[id]!)
          .toList();
    }
    return axes.take(_maxAxesPerSide).toList();
  }
```

- [ ] **Step 6: Add `applySeriesSelection()` and `clearSelectionFor()` to `MultiAxisManager`**

Add after `getVisibleAxes()`:

```dart
  /// Applies series selection, promoting the axis if it is in overflow.
  ///
  /// [seriesId] is the selected series.
  /// [allSeries] is the full series list (used to find the axis binding).
  ///
  /// Returns a record of `{promotedAxisId, demotedAxisId}` if a swap
  /// occurred, or null if no swap was needed.
  ({String promotedAxisId, String demotedAxisId})? applySeriesSelection(
    String seriesId,
    List<dynamic> allSeries,
  ) {
    _selectedSeriesId = seriesId;

    // Find the axis ID for this series
    final axisId = _resolveAxisIdForSeries(seriesId);
    if (axisId == null) return null;

    final overflow = overflowAxisIds;
    if (!overflow.contains(axisId)) return null; // Already visible — no swap

    // Determine which side this axis is on
    final all = getEffectiveYAxes();
    final axis = all.firstWhere((a) => a.id == axisId, orElse: () => throw StateError('Axis $axisId not found'));

    if (axis.position == YAxisPosition.left) {
      final leftAxes = all.where((a) => a.position == YAxisPosition.left).toList();
      final currentVisible = _applySlotCap(leftAxes, _overriddenLeftIds);
      final demoted = currentVisible.last;
      final newVisible = [...currentVisible.take(currentVisible.length - 1), axis];
      _overriddenLeftIds = newVisible.map((a) => a.id).toList();
      return (promotedAxisId: axisId, demotedAxisId: demoted.id);
    } else {
      final rightAxes = all.where((a) => a.position == YAxisPosition.right).toList();
      final currentVisible = _applySlotCap(rightAxes, _overriddenRightIds);
      final demoted = currentVisible.last;
      final newVisible = [...currentVisible.take(currentVisible.length - 1), axis];
      _overriddenRightIds = newVisible.map((a) => a.id).toList();
      return (promotedAxisId: axisId, demotedAxisId: demoted.id);
    }
  }

  /// Deselects, optionally reverting slot order (used by revert mode).
  ///
  /// Returns true if a revert swap occurred (i.e. mode is revert and
  /// the deselected series had triggered a swap).
  bool clearSelectionFor(String seriesId, List<dynamic> allSeries) {
    if (_selectedSeriesId != seriesId) return false;
    _selectedSeriesId = null;

    if (_axisSwapMode == AxisSwapMode.sticky) return false;

    // Revert: reset override lists to declaration order
    _overriddenLeftIds = null;
    _overriddenRightIds = null;
    return true;
  }

  /// Clears all selection state (deselect all, reset if revert mode).
  void clearAllSelection() {
    _selectedSeriesId = null;
    if (_axisSwapMode == AxisSwapMode.revert) {
      _overriddenLeftIds = null;
      _overriddenRightIds = null;
    }
  }

  /// Resolves the axis ID for a given series ID using effective bindings.
  String? _resolveAxisIdForSeries(String seriesId) {
    final bindings = getEffectiveBindings();
    for (final binding in bindings) {
      if (binding.seriesId == seriesId) return binding.axisId;
    }
    return null;
  }
```

- [ ] **Step 7: Switch painters and width methods to `getVisibleAxes()`**

In `multi_axis_manager.dart`, update these four methods to call `getVisibleAxes()` instead of `getEffectiveYAxes()`:

**`computeAxisWidths()`** (line ~614):
```dart
  Map<String, double> computeAxisWidths({
    required Map<String, DataRange> axisBounds,
    TextStyle labelStyle = const TextStyle(
      fontSize: 11,
      color: Color(0xFF666666),
    ),
  }) {
    final visibleAxes = getVisibleAxes();          // <-- changed
    if (visibleAxes.isEmpty) return {};
    const layoutDelegate = MultiAxisLayoutDelegate();
    return layoutDelegate.computeAxisWidths(
      axes: visibleAxes,                           // <-- changed
      axisBounds: axisBounds,
      labelStyle: labelStyle,
    );
  }
```

**`paintMultipleYAxes()`** (line ~648):
```dart
  void paintMultipleYAxes({ ... }) {
    final visibleAxes = getVisibleAxes();          // <-- changed
    if (visibleAxes.isEmpty) return;
    final axisBounds = computeAxisBounds(
      transform: transform,
      originalTransform: originalTransform,
      forPainting: true,
    );
    final effectiveBindings = getEffectiveBindings();
    final painter = MultiAxisPainter(
      axes: visibleAxes,                           // <-- changed
      axisBounds: axisBounds,
      bindings: effectiveBindings,
      series: _series,
    );
    painter.paint(canvas, Offset.zero & size, plotArea);
  }
```

**`getTotalLeftAxisWidth()`** (line ~798):
```dart
  double getTotalLeftAxisWidth(Map<String, double> axisWidths) {
    return layoutDelegate.getTotalLeftWidth(getVisibleAxes(), axisWidths); // <-- changed
  }
```

**`getTotalRightAxisWidth()`** (line ~809):
```dart
  double getTotalRightAxisWidth(Map<String, double> axisWidths) {
    return layoutDelegate.getTotalRightWidth(getVisibleAxes(), axisWidths); // <-- changed
  }
```

**`buildMultiAxisInfo()`** (line ~686):
```dart
  MultiAxisInfo buildMultiAxisInfo({ ... }) {
    final visibleAxes = getVisibleAxes();          // <-- changed
    final axisBounds = computeAxisBounds(...);
    final axisWidths = computeAxisWidths(axisBounds: axisBounds);
    final effectiveBindings = getEffectiveBindings();
    return MultiAxisInfo(
      effectiveAxes: visibleAxes,                  // <-- changed
      ...
    );
  }
```

Note: `computeAxisBounds()` keeps calling `getEffectiveYAxes()` — overflow axes still normalise.

- [ ] **Step 8: Fix `AxisLayoutManager.getAxisRect()` to stack multiple axes**

In `lib/src/layout/axis_layout_manager.dart`, replace the switch body:

```dart
  Rect getAxisRect({
    required Rect chartArea,
    required YAxisConfig axis,
    required Map<String, double> axisWidths,
    required List<YAxisConfig> allAxes,
  }) {
    final axisWidth = axisWidths[axis.id] ?? axis.minWidth;

    switch (axis.position) {
      case YAxisPosition.left:
      // ignore: deprecated_member_use_from_same_package
      case YAxisPosition.leftOuter:
        // Stack left axes from the plot area outward.
        // Preceding width = sum of all left axes before this one in allAxes order.
        var precedingWidth = 0.0;
        for (final a in allAxes) {
          if (a.id == axis.id) break;
          if ((a.position == YAxisPosition.left ||
               // ignore: deprecated_member_use_from_same_package
               a.position == YAxisPosition.leftOuter) &&
              a.visible) {
            precedingWidth += axisWidths[a.id] ?? 0.0;
          }
        }
        return Rect.fromLTWH(
          chartArea.left + precedingWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.right:
      // ignore: deprecated_member_use_from_same_package
      case YAxisPosition.rightOuter:
        // Stack right axes from the plot area outward.
        var precedingWidth = 0.0;
        for (final a in allAxes) {
          if (a.id == axis.id) break;
          if ((a.position == YAxisPosition.right ||
               // ignore: deprecated_member_use_from_same_package
               a.position == YAxisPosition.rightOuter) &&
              a.visible) {
            precedingWidth += axisWidths[a.id] ?? 0.0;
          }
        }
        return Rect.fromLTWH(
          chartArea.right - precedingWidth - axisWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.hidden:
        return Rect.zero;
    }
  }
```

- [ ] **Step 9: Run all tests**

```
flutter test test/unit/multi_axis/slot_resolution_test.dart
flutter test
```

Expected: slot_resolution tests all pass. Full suite: no new failures.

- [ ] **Step 10: Commit**

```
git add lib/src/layout/axis_layout_manager.dart lib/src/rendering/modules/multi_axis_manager.dart test/unit/multi_axis/slot_resolution_test.dart
git commit -m "feat: add Y-axis slot resolution with cap and swap logic to MultiAxisManager"
```

---

## Task 3: Selection Triggers & Widget Wiring

**Files:**
- Modify: `lib/src/widgets/chart_legend.dart`
- Modify: `lib/src/braven_chart_plus.dart`
- Modify: `lib/src/rendering/chart_render_box.dart`

**Context:** Three paths — legend tap, series tap, programmatic controller — all funnel into `_BravenChartPlusState._handleSeriesSelected()`. The widget already has `onSeriesSelected` (fires from data-point and series-line taps at line 2425). We intercept it internally before passing to the user callback.

---

- [ ] **Step 1: Add `onSeriesTap` to `ChartLegend`**

In `lib/src/widgets/chart_legend.dart`, add the optional callback field after `onSeriesToggle`:

```dart
  /// Optional callback when a legend item is tapped (for selection/axis swap).
  ///
  /// Unlike [onSeriesToggle] which controls visibility, this callback
  /// signals series *selection* and is used to drive Y-axis slot swaps.
  /// Both callbacks fire on the same tap.
  final ValueChanged<String>? onSeriesTap;
```

Update the constructor to accept it (add after `required this.onSeriesToggle`):

```dart
    this.onSeriesTap,
```

Update `_buildLegendItem` to fire it alongside the existing toggle:

```dart
  Widget _buildLegendItem(ChartSeries series) {
    final isHidden = hiddenSeriesIds.contains(series.id);
    final seriesColor = _getSeriesColor(series);

    return InkWell(
      onTap: () {
        onSeriesToggle(series.id);
        onSeriesTap?.call(series.id);    // <-- add this line
      },
      borderRadius: BorderRadius.circular(4.0),
      // ... rest unchanged
```

- [ ] **Step 2: Add new parameters to `BravenChartPlus`**

In `lib/src/braven_chart_plus.dart`, find the existing widget field declarations (around line 654 where `onSeriesSelected` is declared). Add the following fields to the `BravenChartPlus` class:

```dart
  /// Maximum number of Y-axes visible simultaneously on each side.
  ///
  /// When more than [maxAxesPerSide] series configure a Y-axis at the same
  /// position (e.g. all on [YAxisPosition.right]), the first [maxAxesPerSide]
  /// declared win visible slots. The rest are placed in overflow — not rendered
  /// but still used for normalization. Defaults to 3. Must be >= 1.
  ///
  /// Overflow axes can be swapped in by selecting their series (via legend tap,
  /// data-point tap, or [BravenChartController.selectSeries]).
  final int maxAxesPerSide;

  /// Controls whether a swap triggered by series selection persists after
  /// deselection. Defaults to [AxisSwapMode.sticky].
  ///
  /// - [AxisSwapMode.sticky]: The swapped-in axis stays visible.
  /// - [AxisSwapMode.revert]: Original declaration-order slot assignment
  ///   is restored when the selected series is deselected.
  final AxisSwapMode axisSwapMode;

  /// Optional controller for programmatic series selection and slot inspection.
  ///
  /// Attach to read [BravenChartController.visibleAxisIds] or call
  /// [BravenChartController.selectSeries] from outside the chart.
  /// The controller is optional — charts without one respond to taps internally.
  final BravenChartController? bravenChartController;

  /// Called when a series is deselected (tap again or tap empty space).
  final void Function(String seriesId)? onSeriesDeselected;

  /// Called immediately after an axis swap completes.
  ///
  /// [promotedAxisId] entered a visible slot; [demotedAxisId] moved to overflow.
  final void Function({
    required String promotedAxisId,
    required String demotedAxisId,
  })? onAxisSwapped;
```

Add corresponding constructor parameters. The existing public constructors (`BravenChartPlus(...)`, `BravenChartPlus.multiAxis(...)`, etc.) each need these five parameters added:

```dart
    this.maxAxesPerSide = 3,
    this.axisSwapMode = AxisSwapMode.sticky,
    this.bravenChartController,
    this.onSeriesDeselected,
    this.onAxisSwapped,
```

- [ ] **Step 3: Add `_handleSeriesSelected` and `_handleSeriesDeselected` to state**

In `_BravenChartPlusState`, add a field for tracking selected series:

```dart
  String? _selectedSeriesId;
```

Add the handler methods (after `_handleElementHover` around line 2469):

```dart
  void _handleSeriesSelected(String seriesId) {
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;

    if (_selectedSeriesId == seriesId) {
      // Second tap on same series = deselect
      _handleSeriesDeselected(seriesId);
      return;
    }

    _selectedSeriesId = seriesId;

    // Apply swap in MultiAxisManager via ChartRenderBox
    final swapResult = renderBox?.applySeriesSelection(seriesId, widget.series ?? []);

    if (swapResult != null) {
      widget.onAxisSwapped?.call(
        promotedAxisId: swapResult.promotedAxisId,
        demotedAxisId: swapResult.demotedAxisId,
      );
    }

    // Sync controller state
    _syncControllerState(renderBox);

    // Fire public callback
    widget.onSeriesSelected?.call(seriesId);
  }

  void _handleSeriesDeselected(String seriesId) {
    _selectedSeriesId = null;
    final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
    renderBox?.clearSeriesSelection(seriesId, widget.series ?? []);
    _syncControllerState(renderBox);
    widget.onSeriesDeselected?.call(seriesId);
  }

  void _syncControllerState(ChartRenderBox? renderBox) {
    widget.bravenChartController?.updateSlotState(
      selectedSeriesId: _selectedSeriesId,
      visibleAxisIds: renderBox?.visibleAxisIds ?? const [],
      overflowAxisIds: renderBox?.overflowAxisIds ?? const [],
    );
  }
```

- [ ] **Step 4: Wire controller attach/detach in state lifecycle**

In `_BravenChartPlusState.initState()`, add after existing initialisation:

```dart
    widget.bravenChartController?.attach(
      onSelect: _handleSeriesSelected,
      onDeselect: _handleSeriesDeselected,
      onClear: () {
        _selectedSeriesId = null;
        final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
        renderBox?.clearAllSeriesSelection();
        _syncControllerState(renderBox);
      },
    );
```

In `didUpdateWidget()`, handle controller change:

```dart
    if (oldWidget.bravenChartController != widget.bravenChartController) {
      oldWidget.bravenChartController?.detach();
      widget.bravenChartController?.attach(
        onSelect: _handleSeriesSelected,
        onDeselect: _handleSeriesDeselected,
        onClear: () {
          _selectedSeriesId = null;
          final renderBox = _renderBoxKey.currentContext?.findRenderObject() as ChartRenderBox?;
          renderBox?.clearAllSeriesSelection();
          _syncControllerState(renderBox);
        },
      );
    }
```

In `dispose()`, add:

```dart
    widget.bravenChartController?.detach();
```

- [ ] **Step 5: Intercept existing `onSeriesSelected` tap path**

The existing tap handler at line ~2418 fires `widget.onSeriesSelected?.call(tappedElement.series.id)`. Replace that line:

```dart
      } else if (tappedElement is SeriesElement) {
        final marker = _coordinator.hoveredMarker;
        if (marker != null && marker.seriesId == tappedElement.series.id) {
          final point = tappedElement.series.points[marker.markerIndex];
          widget.onPointTap?.call(point, tappedElement.series.id);
        } else {
          _handleSeriesSelected(tappedElement.series.id);  // <-- was: widget.onSeriesSelected?.call(...)
        }
```

- [ ] **Step 6: Wire legend `onSeriesTap` where `ChartLegend` is used**

Search for `ChartLegend(` in the codebase:

```
grep -rn "ChartLegend(" example/
```

For any usage that doesn't pass `onSeriesTap`, add it (typically in showcase pages). Example pattern:

```dart
ChartLegend(
  series: _allSeries,
  hiddenSeriesIds: _hiddenSeriesIds,
  onSeriesToggle: (id) { setState(() { ... }); },
  onSeriesTap: (id) => _chartController?.selectSeries(id),  // <-- add
)
```

- [ ] **Step 7: Add delegation methods to `ChartRenderBox`**

In `lib/src/rendering/chart_render_box.dart`, add these public delegation methods (alongside the existing `clearCursorPosition()`):

```dart
  /// Applies series selection to the slot system.
  ({String promotedAxisId, String demotedAxisId})? applySeriesSelection(
    String seriesId,
    List<ChartSeries> allSeries,
  ) {
    final result = _multiAxisManager.applySeriesSelection(seriesId, allSeries);
    if (result != null) {
      markNeedsLayout(); // Trigger repaint with new slot assignment
    }
    return result;
  }

  /// Deselects a series, reverting slot if mode is revert.
  void clearSeriesSelection(String seriesId, List<ChartSeries> allSeries) {
    final reverted = _multiAxisManager.clearSelectionFor(seriesId, allSeries);
    if (reverted) markNeedsLayout();
  }

  /// Clears all selection state.
  void clearAllSeriesSelection() {
    _multiAxisManager.clearAllSelection();
    markNeedsLayout();
  }

  /// Currently visible axis IDs (for controller state sync).
  List<String> get visibleAxisIds =>
      _multiAxisManager.getVisibleAxes().map((a) => a.id).toList();

  /// Currently overflow axis IDs.
  List<String> get overflowAxisIds => _multiAxisManager.overflowAxisIds;
```

- [ ] **Step 8: Pass `maxAxesPerSide` and `axisSwapMode` from widget to `ChartRenderBox`**

In `_ChartRenderWidget`, add the two fields and pass them through:

```dart
  // In _ChartRenderWidget field declarations:
  final int maxAxesPerSide;
  final AxisSwapMode axisSwapMode;
```

In `createRenderObject()`:
```dart
    return ChartRenderBox(...)
      ..setMaxAxesPerSide(maxAxesPerSide)
      ..setAxisSwapMode(axisSwapMode)
      ..setXAxis(xAxis)
      // ... rest unchanged
```

In `updateRenderObject()`:
```dart
    renderObject
      ..setMaxAxesPerSide(maxAxesPerSide)
      ..setAxisSwapMode(axisSwapMode)
      // ... rest unchanged
```

In `ChartRenderBox`, add delegation setters:

```dart
  void setMaxAxesPerSide(int max) {
    if (_multiAxisManager.setMaxAxesPerSide(max)) markNeedsLayout();
  }

  void setAxisSwapMode(AxisSwapMode mode) {
    _multiAxisManager.setAxisSwapMode(mode);
  }
```

Wire these in the `_ChartRenderWidget(...)` call in `build()`:
```dart
  _ChartRenderWidget(
    key: _renderBoxKey,
    maxAxesPerSide: widget.maxAxesPerSide,
    axisSwapMode: widget.axisSwapMode,
    // ... all existing params unchanged
  )
```

- [ ] **Step 9: Run full test suite and analyzer**

```
flutter test
flutter analyze lib/
```

Expected: All tests pass, no errors. Deprecation warnings on any existing use of `leftOuter`/`rightOuter` in tests — replace them with `left`/`right` in test series configs.

- [ ] **Step 10: Commit**

```
git add lib/src/widgets/chart_legend.dart lib/src/braven_chart_plus.dart lib/src/rendering/chart_render_box.dart
git commit -m "feat: wire Y-axis slot swap to legend tap, series tap, and BravenChartController"
```

---

## Task 4: Showcase Demo

**Files:**
- Create: `example/lib/showcase/pages/axis_slot_demo_page.dart`
- Modify: `example/lib/showcase/showcase_app.dart` (or equivalent nav file)

**Context:** Build a page with 5 series all on `YAxisPosition.right`, `maxAxesPerSide: 3`. The legend shows all 5; tapping an overflow series swaps its axis in. Show the `visibleAxisIds`/`overflowAxisIds` status in a text overlay.

---

- [ ] **Step 1: Find where showcase pages are registered**

```
grep -rn "LactatePage\|TrackingLabPage\|showcase" example/lib/showcase/ | head -20
```

Identify the navigation file (typically `showcase_app.dart` or a routes file).

- [ ] **Step 2: Create `axis_slot_demo_page.dart`**

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

class AxisSlotDemoPage extends StatefulWidget {
  const AxisSlotDemoPage({super.key});

  @override
  State<AxisSlotDemoPage> createState() => _AxisSlotDemoPageState();
}

class _AxisSlotDemoPageState extends State<AxisSlotDemoPage> {
  final _controller = BravenChartController();
  final Set<String> _hiddenSeriesIds = {};
  String? _statusMessage;

  // 5 series competing for the right axis — only 3 slots available
  late final List<LineChartSeries> _series;

  @override
  void initState() {
    super.initState();
    _series = [
      LineChartSeries(
        id: 'lactate',
        name: 'Lactate',
        color: const Color(0xFFE53935),
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: 0.5 + i * 0.08)),
        yAxisConfig: const YAxisConfig(position: YAxisPosition.right, label: 'Lactate', unit: 'mmol/L'),
      ),
      LineChartSeries(
        id: 'vo2',
        name: 'VO₂ Avg',
        color: const Color(0xFF1E88E5),
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: 20 + i * 0.8)),
        yAxisConfig: const YAxisConfig(position: YAxisPosition.right, label: 'VO₂', unit: 'mL/min/kg'),
      ),
      LineChartSeries(
        id: 'rf',
        name: 'Avg RF',
        color: const Color(0xFF43A047),
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: 12 + i * 0.3)),
        yAxisConfig: const YAxisConfig(position: YAxisPosition.right, label: 'RF', unit: 'br/min'),
      ),
      LineChartSeries(
        id: 'heat',
        name: 'Heat Strain',
        color: const Color(0xFFFF9800),
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: 0.8 + i * 0.04)),
        yAxisConfig: const YAxisConfig(position: YAxisPosition.right, label: 'Heat Strain', unit: 'HSI'),
      ),
      LineChartSeries(
        id: 'tidal',
        name: 'Tidal Volume',
        color: const Color(0xFF8E24AA),
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: 0.3 + i * 0.02)),
        yAxisConfig: const YAxisConfig(position: YAxisPosition.right, label: 'Tidal Vol', unit: 'L'),
      ),
    ];

    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      final visible = _controller.visibleAxisIds.join(', ');
      final overflow = _controller.overflowAxisIds.join(', ');
      _statusMessage = 'Visible: $visible\nOverflow: $overflow';
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleSeries = _series.where((s) => !_hiddenSeriesIds.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Y-Axis Slot System')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'maxAxesPerSide: 3 — 5 series compete for right axis.\nTap a legend item to swap its axis in.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: BravenChartPlus(
              series: visibleSeries,
              maxAxesPerSide: 3,
              axisSwapMode: AxisSwapMode.sticky,
              bravenChartController: _controller,
              xAxisConfig: const XAxisConfig(label: 'Time', showAxisLine: true),
              onAxisSwapped: ({required promotedAxisId, required demotedAxisId}) {
                setState(() {
                  _statusMessage = 'Swapped in: $promotedAxisId\nDemoted: $demotedAxisId';
                });
              },
            ),
          ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _statusMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ChartLegend(
              series: _series,
              hiddenSeriesIds: _hiddenSeriesIds,
              onSeriesToggle: (id) {
                setState(() {
                  if (_hiddenSeriesIds.contains(id)) {
                    _hiddenSeriesIds.remove(id);
                  } else {
                    _hiddenSeriesIds.add(id);
                  }
                });
              },
              onSeriesTap: (id) => _controller.selectSeries(id),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Register the page in the showcase nav file**

Find the route/page list (look for other page registrations like `LactatePage`). Add:

```dart
// In the routes/pages list:
ListTile(
  title: const Text('Y-Axis Slot System'),
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const AxisSlotDemoPage())),
),
```

And add the import:

```dart
import 'pages/axis_slot_demo_page.dart';
```

- [ ] **Step 4: Run the example app and manually verify**

```
cd example
flutter run -d windows
```

Navigate to "Y-Axis Slot System". Verify:
1. Only 3 right-side axes are visible (Lactate, VO₂, RF)
2. Heat Strain and Tidal Volume series lines draw but have no axis labels
3. Tapping "Heat Strain" in the legend swaps its axis in (RF is demoted)
4. Status text updates showing new visible/overflow IDs
5. `onAxisSwapped` fires and shows the swap message
6. Tapping "Lactate" (already visible) does not trigger a swap
7. Hot-reload preserves all existing charts on other showcase pages

- [ ] **Step 5: Commit**

```
git add example/lib/showcase/pages/axis_slot_demo_page.dart example/lib/showcase/
git commit -m "feat: add Y-axis slot system showcase demo page"
```

---

## Self-Review Checklist

### Spec Coverage

| Spec requirement | Task |
|-----------------|------|
| `leftOuter`/`rightOuter` deprecated, map to `left`/`right` | Task 1, Steps 5–6 |
| `AxisSwapMode` enum (sticky/revert) | Task 1, Step 3 |
| `BravenChartController` (select/deselect/clear/getters) | Task 1, Step 4 |
| `maxAxesPerSide` param on widget | Task 3, Step 2 |
| `axisSwapMode` param on widget | Task 3, Step 2 |
| `onSeriesDeselected` callback | Task 3, Step 2 |
| `onAxisSwapped` callback | Task 3, Step 2 |
| Slot resolution: first N per side visible, rest overflow | Task 2, Steps 5–7 |
| Overflow axes included in bounds but not painted | Task 2, Step 7 (computeAxisBounds unchanged) |
| Swap demotes last visible on same side | Task 2, Step 6 |
| Sticky: swap persists after deselect | Task 2, Step 6 |
| Revert: restore declaration order on deselect | Task 2, Step 6 |
| Legend tap triggers selection | Task 3, Steps 1, 6 |
| Data-point/series tap triggers selection | Task 3, Step 5 |
| Programmatic `controller.selectSeries()` | Task 3, Steps 3–4, 7 |
| Multiple axes at same position stack correctly | Task 2, Step 8 |
| Barrel exports for new models | Task 1, Step 7 |
| Showcase demo | Task 4 |

All requirements covered. No gaps.
