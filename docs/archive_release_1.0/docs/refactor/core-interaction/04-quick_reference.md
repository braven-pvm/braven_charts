# Phase 1 Implementation Guide - Quick Start

**Branch**: `core-interaction-refactor`  
**Phase**: 1 - Foundation (Week 1-2)  
**Goal**: Replace CustomPainter with RenderBox, integrate coordinator

---

## ⚠️ **IMPORTANT: USE DETAILED PLAN**

**This is a QUICK REFERENCE guide only.**

**For COMPLETE, UNAMBIGUOUS instructions, read:**
📄 **`03-phase_1_implementation_plan.md`** (25 pages, zero ambiguity)

The detailed plan includes:

- ✅ Complete field inventory (all 10 fields enumerated)
- ✅ Exhaustive method checklist (26+ methods listed)
- ✅ Line-by-line migration instructions
- ✅ Exact PowerShell commands for file operations
- ✅ Import fix instructions
- ✅ Verification steps at each stage
- ✅ Troubleshooting guide
- ✅ Performance benchmarks
- ✅ Success criteria

**Use this guide for quick reference during implementation.**  
**Use 03-phase_1_implementation_plan.md for step-by-step execution.**

---

## Pre-Implementation Checklist

Before starting Phase 1, ensure:

- [ ] Read `03-phase_1_implementation_plan.md` completely (45 minutes)
- [ ] Analysis documents reviewed (`core_interaction_refactor_analysis.md`, `refactor_summary.md`)
- [ ] Branch confirmed: `core-interaction-refactor` ✅
- [ ] Baseline test suite established (capture current functionality)
- [ ] Development environment ready (Flutter SDK, dependencies installed)
- [ ] Backup of current `lib/src/widgets/braven_chart.dart` (git handles this, but good to note)

---

## Phase 1 Tasks - Step by Step

### Task 1: Create BravenChartRenderBox Skeleton

**File**: `lib/src/rendering/braven_chart_render_box.dart` (NEW)

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

import '../theming/chart_theme.dart';
import '../interaction/coordinator.dart';
import 'spatial_index.dart';

/// Custom RenderBox for high-performance chart rendering and interaction.
///
/// Replaces _BravenChartPainter (CustomPainter) with a RenderBox that provides:
/// - Direct pointer event handling via handleEvent()
/// - QuadTree spatial indexing for O(log n) hit testing
/// - Centralized interaction state via ChartInteractionCoordinator
/// - 3-space coordinate system (Widget → Plot → Data)
class BravenChartRenderBox extends RenderBox {
  BravenChartRenderBox({
    required this.theme,
    required this.coordinator,
  });

  final ChartTheme theme;
  final ChartInteractionCoordinator coordinator;

  QuadTree? _spatialIndex;
  Rect _plotArea = Rect.zero;

  // TODO: Add more fields from _BravenChartPainter
  // - List<ChartSeries> series
  // - AxisConfig xAxis, yAxis
  // - List<ChartAnnotation> annotations
  // - etc.

  @override
  void performLayout() {
    // Chart respects parent constraints
    size = constraints.biggest;

    // Calculate plot area (reserve space for axes)
    // TODO: Copy logic from _BravenChartPainter
    const leftMargin = 60.0;   // Y-axis space
    const rightMargin = 10.0;
    const topMargin = 10.0;
    const bottomMargin = 50.0; // X-axis space

    _plotArea = Rect.fromLTRB(
      leftMargin,
      topMargin,
      size.width - rightMargin,
      size.height - bottomMargin,
    );

    // TODO: Build spatial index
    // _spatialIndex = QuadTree(bounds: Offset.zero & _plotArea.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // TODO: Move all rendering code from _BravenChartPainter.paint() here
    // For now, just draw a placeholder
    final backgroundPaint = Paint()..color = theme.backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    canvas.restore();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Always claim hit test (chart consumes all pointer events)
    if (!size.contains(position)) return false;

    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    // TODO: Implement coordinator-based event routing
    // For now, just log events
    print('PointerEvent: ${event.runtimeType} at ${event.localPosition}');
  }
}
```

**Commit**: `git add lib/src/rendering/braven_chart_render_box.dart && git commit -m "feat: Add BravenChartRenderBox skeleton"`

---

### Task 2: Copy Core Files from Prototype

Copy these files from `refactor/interaction/lib/` to `lib/src/interaction/`:

1. **Coordinator** (CRITICAL):
   - `core/coordinator.dart` → `lib/src/interaction/coordinator.dart`
   - `core/interaction_mode.dart` → `lib/src/interaction/interaction_mode.dart`

2. **Spatial Index**:
   - `rendering/spatial_index.dart` → `lib/src/rendering/spatial_index.dart`

3. **Transform** (for later, but copy now):
   - `transforms/chart_transform.dart` → `lib/src/coordinates/chart_transform.dart`

4. **Element Interface** (for later, but copy now):
   - `core/chart_element.dart` → `lib/src/interaction/chart_element.dart`
   - `core/element_types.dart` → `lib/src/interaction/element_types.dart`

**Commands**:

```powershell
# From repository root
Copy-Item "refactor\interaction\lib\core\coordinator.dart" "lib\src\interaction\coordinator.dart"
Copy-Item "refactor\interaction\lib\core\interaction_mode.dart" "lib\src\interaction\interaction_mode.dart"
Copy-Item "refactor\interaction\lib\rendering\spatial_index.dart" "lib\src\rendering\spatial_index.dart"
Copy-Item "refactor\interaction\lib\transforms\chart_transform.dart" "lib\src\coordinates\chart_transform.dart"
Copy-Item "refactor\interaction\lib\core\chart_element.dart" "lib\src\interaction\chart_element.dart"
Copy-Item "refactor\interaction\lib\core\element_types.dart" "lib\src\interaction\element_types.dart"
```

**Fix Imports**: Update import paths in copied files to match new locations.

**Commit**: `git add lib/src/interaction/ lib/src/rendering/ lib/src/coordinates/ && git commit -m "feat: Copy core interaction files from prototype"`

---

### Task 3: Move Paint Logic to RenderBox

**Goal**: Move ALL rendering code from `_BravenChartPainter.paint()` to `BravenChartRenderBox.paint()`

**File to Edit**: `lib/src/rendering/braven_chart_render_box.dart`

**Steps**:

1. Open `lib/src/widgets/braven_chart.dart`
2. Find `_BravenChartPainter.paint()` method (line ~4287)
3. Copy the entire method body (~1000 lines)
4. Paste into `BravenChartRenderBox.paint()`
5. Fix any references to instance variables (add as fields to RenderBox)
6. Fix Canvas API differences:
   - `canvas.save()` / `canvas.restore()` work same way
   - `canvas.translate()` for offset
7. Test that chart renders identically

**Example**:

```dart
@override
void paint(PaintingContext context, Offset offset) {
  final canvas = context.canvas;
  canvas.save();
  canvas.translate(offset.dx, offset.dy);

  // PASTE ALL CODE from _BravenChartPainter.paint() here
  // Including:
  // - Background drawing
  // - Grid drawing
  // - Series drawing (line, area, bar, scatter)
  // - Annotation drawing
  // - Axis drawing
  // - Crosshair drawing

  canvas.restore();
}
```

**Required Fields** (add to BravenChartRenderBox):

```dart
class BravenChartRenderBox extends RenderBox {
  // ... existing fields ...

  // From _BravenChartPainter:
  final List<ChartSeries> series;
  final AxisConfig xAxis;
  final AxisConfig yAxis;
  final List<ChartAnnotation> annotations;
  final CrosshairConfig? crosshairConfig;
  final ChartType chartType;
  final LineStyle lineStyle;
  // ... etc. (copy ALL fields from _BravenChartPainter)

  BravenChartRenderBox({
    required this.theme,
    required this.coordinator,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    // ... all other fields
  });
}
```

**Commit**: `git commit -am "feat: Move paint logic from CustomPainter to RenderBox"`

---

### Task 4: Update BravenChart Widget to Use RenderBox

**Goal**: Replace CustomPaint with RenderBox-based widget

**File to Edit**: `lib/src/widgets/braven_chart.dart`

**Changes**:

1. **Create RenderObject Widget** (new class):

```dart
/// Widget that creates BravenChartRenderBox.
class _BravenChartRenderObjectWidget extends LeafRenderObjectWidget {
  const _BravenChartRenderObjectWidget({
    required this.theme,
    required this.coordinator,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    // ... all other fields
  });

  final ChartTheme theme;
  final ChartInteractionCoordinator coordinator;
  final List<ChartSeries> series;
  final AxisConfig xAxis;
  final AxisConfig yAxis;
  // ... all other fields

  @override
  RenderObject createRenderObject(BuildContext context) {
    return BravenChartRenderBox(
      theme: theme,
      coordinator: coordinator,
      series: series,
      xAxis: xAxis,
      yAxis: yAxis,
      // ... all other fields
    );
  }

  @override
  void updateRenderObject(BuildContext context, BravenChartRenderBox renderObject) {
    // Update fields when widget rebuilds
    renderObject
      ..theme = theme
      ..series = series
      // ... update all mutable fields
      ..markNeedsPaint();
  }
}
```

2. **Replace CustomPaint in build()** (around line 2400):

```dart
// OLD:
interactiveWidget = CustomPaint(
  painter: _BravenChartPainter(...),
  child: Container(),
);

// NEW:
interactiveWidget = _BravenChartRenderObjectWidget(
  theme: theme,
  coordinator: _coordinator,
  series: series,
  xAxis: xAxis,
  yAxis: yAxis,
  // ... all other fields
);
```

3. **Initialize Coordinator in State** (add to `_BravenChartState`):

```dart
class _BravenChartState extends State<BravenChart> {
  late ChartInteractionCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = ChartInteractionCoordinator();
  }

  @override
  void dispose() {
    _coordinator.dispose();
    super.dispose();
  }

  // ... rest of state
}
```

**Commit**: `git commit -am "feat: Replace CustomPaint with RenderBox widget"`

---

### Task 5: Basic Coordinator Integration

**Goal**: Route pointer events through coordinator

**File to Edit**: `lib/src/rendering/braven_chart_render_box.dart`

**Implementation**:

```dart
@override
void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
  assert(debugHandleEvent(event, entry));

  // Modal states block all events except themselves
  if (coordinator.isModal) return;

  final localPosition = event.localPosition;

  if (event is PointerDownEvent) {
    _handlePointerDown(event, localPosition);
  } else if (event is PointerMoveEvent) {
    _handlePointerMove(event, localPosition);
  } else if (event is PointerUpEvent) {
    _handlePointerUp(event, localPosition);
  } else if (event is PointerHoverEvent) {
    _handlePointerHover(event, localPosition);
  }
}

void _handlePointerDown(PointerDownEvent event, Offset position) {
  // TODO: Hit test elements using spatial index
  // For now, just track interaction start
  coordinator.startInteraction(position);
  print('PointerDown at $position, mode=${coordinator.currentMode}');
}

void _handlePointerMove(PointerMoveEvent event, Offset position) {
  if (!coordinator.isInteracting) return;
  print('PointerMove at $position, mode=${coordinator.currentMode}');
}

void _handlePointerUp(PointerUpEvent event, Offset position) {
  coordinator.endInteraction();
  coordinator.releaseMode();
  print('PointerUp at $position');
}

void _handlePointerHover(PointerHoverEvent event, Offset position) {
  // TODO: Update hover state
  print('PointerHover at $position');
}
```

**Commit**: `git commit -am "feat: Add basic coordinator integration to event handling"`

---

### Task 6: Add QuadTree for Hit Testing

**Goal**: Implement spatial indexing for fast hit tests

**File to Edit**: `lib/src/rendering/braven_chart_render_box.dart`

**Implementation**:

```dart
@override
void performLayout() {
  size = constraints.biggest;

  // Calculate plot area
  _plotArea = Rect.fromLTRB(/* ... */);

  // Build spatial index
  _spatialIndex = QuadTree(
    bounds: Offset.zero & _plotArea.size,
    maxElementsPerNode: 4,
    maxDepth: 8,
  );

  // TODO: Insert elements (for now, just initialize empty)
  // In future phases, we'll insert DataPointElement, AnnotationElement, etc.
}

/// Finds the top-priority element at the given position.
ChartElement? _hitTestElements(Offset widgetPosition) {
  if (_spatialIndex == null) return null;

  // Convert widget coordinates to plot coordinates
  final plotPosition = Offset(
    widgetPosition.dx - _plotArea.left,
    widgetPosition.dy - _plotArea.top,
  );

  // Query spatial index
  final candidates = _spatialIndex!.query(plotPosition, radius: 18);

  if (candidates.isEmpty) return null;

  // Filter to elements that pass precise hit test
  final hits = candidates.where((e) => e.hitTest(plotPosition)).toList();

  if (hits.isEmpty) return null;

  // Return highest priority element
  hits.sort((a, b) => b.priority.compareTo(a.priority));
  return hits.first;
}
```

**Commit**: `git commit -am "feat: Add QuadTree spatial index to RenderBox"`

---

### Task 7: Verify Rendering & Test

**Goal**: Ensure chart renders identically to before refactor

**Testing Steps**:

1. **Run Example App**:

   ```powershell
   cd example
   flutter run -d chrome
   ```

2. **Visual Verification**:
   - [ ] Chart renders (background, grid, axes)
   - [ ] Series data displays correctly (line, area, bar, scatter)
   - [ ] Annotations render
   - [ ] Themes apply correctly
   - [ ] No visual regressions

3. **Basic Interaction Test**:
   - [ ] Click on chart (should see "PointerDown" in console)
   - [ ] Drag on chart (should see "PointerMove" in console)
   - [ ] Release (should see "PointerUp" in console)
   - [ ] Hover over chart (should see "PointerHover" in console)

4. **Run Existing Tests**:
   ```powershell
   flutter test
   ```

   - [ ] All existing tests still pass
   - [ ] No new failures introduced

**If Issues**: Debug using Flutter DevTools, check:

- Paint calls (should see BravenChartRenderBox.paint)
- Layout issues (check \_plotArea calculation)
- Missing fields (compare with \_BravenChartPainter)

**Commit**: `git commit -am "test: Verify Phase 1 rendering and basic interaction"`

---

## Phase 1 Success Criteria

Before proceeding to Phase 2, verify:

- ✅ Chart renders identically to before refactor
- ✅ Background, grid, axes, series, annotations all visible
- ✅ Themes apply correctly
- ✅ Basic pointer events detected (down, move, up, hover)
- ✅ Coordinator tracks interaction state
- ✅ QuadTree initialized (even if empty for now)
- ✅ All existing tests pass
- ✅ No visual regressions
- ✅ Code compiles without errors

---

## Common Issues & Solutions

### Issue 1: Import Errors

**Problem**: Copied files have incorrect import paths  
**Solution**: Update imports to match new locations:

```dart
// OLD (prototype):
import '../core/coordinator.dart';

// NEW (main package):
import 'package:braven_charts/src/interaction/coordinator.dart';
```

### Issue 2: Canvas API Differences

**Problem**: CustomPainter uses `canvas` directly, RenderBox uses `context.canvas`  
**Solution**: Extract canvas in paint():

```dart
@override
void paint(PaintingContext context, Offset offset) {
  final canvas = context.canvas;  // Extract once
  // ... use canvas as before
}
```

### Issue 3: Missing Fields

**Problem**: RenderBox missing fields that \_BravenChartPainter had  
**Solution**: Copy ALL fields from painter to RenderBox, add to constructor

### Issue 4: Performance Issues

**Problem**: Chart lags during interaction  
**Solution**: Check if markNeedsPaint() called too frequently, optimize later

---

## Next Phase Preview

### Phase 2: Element System (Week 3)

Once Phase 1 is complete, Phase 2 will:

- Create element wrappers (DataPointElement, SeriesElement, AnnotationElement)
- Implement precise hit testing using elements
- Wire coordinator to all gesture types
- Add selection and hover effects

**Phase 2 will make interactions functional**, while Phase 1 just **establishes the foundation**.

---

## Resources

### Key Files to Reference

- `core_interaction_refactor_analysis.md` (detailed technical analysis)
- `refactor_summary.md` (executive summary)
- `refactor/interaction/lib/rendering/chart_render_box.dart` (prototype reference)
- `lib/src/widgets/braven_chart.dart` (current implementation)

### Prototype Files to Study

- `refactor/interaction/lib/rendering/chart_render_box.dart` (1,308 lines - full example)
- `refactor/interaction/lib/core/coordinator.dart` (450 lines - state management)
- `refactor/interaction/lib/rendering/spatial_index.dart` (700+ lines - QuadTree)

### Flutter Documentation

- [RenderBox Documentation](https://api.flutter.dev/flutter/rendering/RenderBox-class.html)
- [Custom RenderObject Tutorial](https://flutter.dev/docs/development/ui/advanced/custom-render-objects)

---

## Getting Help

If stuck:

1. Check prototype implementation (working reference)
2. Review analysis document (explains decisions)
3. Add debug prints to trace execution
4. Use Flutter DevTools (widget inspector, timeline)
5. Ask questions in comments (will update guide)

---

**Ready to begin?** Start with Task 1: Create BravenChartRenderBox skeleton.

---

_Phase 1 Guide v1.0_  
_Branch: core-interaction-refactor_  
_Goal: Foundation complete by end of Week 2_
