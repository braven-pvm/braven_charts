# Phase 1: Detailed Implementation Plan - NO AMBIGUITY

**Branch**: `core-interaction-refactor`  
**Goal**: Replace CustomPainter with RenderBox while preserving 100% functionality  
**Duration**: 2 weeks (conservative)  
**Status**: READY TO EXECUTE  

---

## Critical Success Criteria

Before declaring Phase 1 complete, ALL of these MUST pass:

- [ ] Chart renders **pixel-perfect identical** to before refactor
- [ ] All 33 fields from `_BravenChartPainter` preserved in `BravenChartRenderBox`
- [ ] All rendering methods (`_drawLineSeries`, `_drawAreaSeries`, etc.) work unchanged
- [ ] Coordinator integrated and logging events
- [ ] QuadTree initialized (even if not fully utilized yet)
- [ ] Existing unit tests pass (zero failures)
- [ ] Example app runs without errors
- [ ] No performance regressions (benchmark paint times)

---

## Part 1: Field Inventory & Preservation

### Step 1.1: Complete Field Analysis

**Current `_BravenChartPainter` fields** (from lines 4256-4286):

```dart
class _BravenChartPainter extends CustomPainter {
  _BravenChartPainter({
    required this.chartType,           // 1
    required this.lineStyle,           // 2
    required this.series,              // 3
    required this.theme,               // 4
    required this.xAxis,               // 5
    required this.yAxis,               // 6
    required this.annotations,         // 7
    this.zoomPanState,                 // 8
    this.originalDataBounds,           // 9
    this.onChartRectCalculated,        // 10
  });

  static bool enablePaintProfiling = false;  // 11 (static)

  final ChartType chartType;                 // 1
  final LineStyle lineStyle;                 // 2
  final List<ChartSeries> series;            // 3
  final ChartTheme theme;                    // 4
  final AxisConfig xAxis;                    // 5
  final AxisConfig yAxis;                    // 6
  final List<ChartAnnotation> annotations;   // 7
  final ZoomPanState? zoomPanState;          // 8
  final _DataBounds? originalDataBounds;     // 9
  final void Function(Rect chartRect, Size size)? onChartRectCalculated; // 10
}
```

**CRITICAL**: All 10 fields MUST be preserved in `BravenChartRenderBox`.

**Action**: Create complete field mapping table.

---

### Step 1.2: Identify ALL Helper Methods

**Methods in `_BravenChartPainter` to preserve**:

Scan lines 4287-7306 and list every method:

```dart
// PRIMARY METHODS
void paint(Canvas canvas, Size size) { ... }
bool shouldRepaint(covariant _BravenChartPainter oldDelegate) { ... }

// DATA CALCULATION
_DataBounds? _calculateDataBounds({Rect? chartRect}) { ... }
_DataBounds _calculateRawDataBounds(List<ChartSeries> allSeries) { ... }
double _calculateAxisReservedSize(AxisConfig axis, _DataBounds bounds, bool isHorizontal) { ... }

// RENDERING METHODS
void _drawGrid(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawLineSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawAreaSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawBarSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawScatterSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawAxes(Canvas canvas, Size size, Rect chartRect, _DataBounds bounds) { ... }
void _drawAnnotations(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }

// COORDINATE CONVERSION
Offset _dataToPixel(double x, double y, Rect chartRect, _DataBounds bounds) { ... }
ChartDataPoint _pixelToData(Offset pixel, Rect chartRect, _DataBounds bounds) { ... }

// AXIS RENDERING
void _drawAxis(Canvas canvas, AxisConfig axis, Rect chartRect, _DataBounds bounds, bool isHorizontal) { ... }
String _formatAxisLabel(double value, AxisConfig axis) { ... }
List<double> _generateAxisTicks(AxisConfig axis, double min, double max, bool isHorizontal) { ... }

// MARKER RENDERING
void _drawMarker(Canvas canvas, Offset position, ChartSeries series) { ... }
void _drawMarkerShape(Canvas canvas, Offset position, MarkerShape shape, double size, Paint paint) { ... }

// ANNOTATION RENDERING
void _drawPointAnnotation(Canvas canvas, PointAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawRangeAnnotation(Canvas canvas, RangeAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawTextAnnotation(Canvas canvas, TextAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawThresholdAnnotation(Canvas canvas, ThresholdAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawTrendAnnotation(Canvas canvas, TrendAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }

// SELECTION/HOVER RENDERING
void _drawSelection(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawHoverEffects(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
```

**CRITICAL**: Count every method. Current guide says "copy paint logic" but doesn't enumerate ALL methods.

**Action**: Create exhaustive method checklist with line numbers.

---

## Part 2: File Structure & Setup

### Step 2.1: Create Directory Structure

**New directories**:
```
lib/src/rendering/           # NEW - RenderBox implementation
lib/src/rendering/painters/  # NEW - Extracted painting logic
lib/src/interaction/core/    # NEW - Coordinator and state
```

**Commands**:
```powershell
# From repository root
New-Item -ItemType Directory -Force -Path "lib\src\rendering"
New-Item -ItemType Directory -Force -Path "lib\src\rendering\painters"
New-Item -ItemType Directory -Force -Path "lib\src\interaction\core"
```

---

### Step 2.2: Copy Prototype Files WITH IMPORT FIXES

**Critical Files to Copy**:

1. **Coordinator** (PRIMARY):
   ```powershell
   Copy-Item "refactor\interaction\lib\core\coordinator.dart" "lib\src\interaction\core\coordinator.dart"
   Copy-Item "refactor\interaction\lib\core\interaction_mode.dart" "lib\src\interaction\core\interaction_mode.dart"
   ```

   **Import fixes required**:
   ```dart
   // IN coordinator.dart
   // OLD: import '../transforms/chart_transform.dart';
   // NEW: import 'package:braven_charts/src/coordinates/chart_transform.dart';
   
   // OLD: import 'interaction_mode.dart';
   // NEW: import 'package:braven_charts/src/interaction/core/interaction_mode.dart';
   ```

2. **Spatial Index**:
   ```powershell
   Copy-Item "refactor\interaction\lib\rendering\spatial_index.dart" "lib\src\rendering\spatial_index.dart"
   ```

   **Import fixes required**:
   ```dart
   // IN spatial_index.dart
   // OLD: import '../core/chart_element.dart';
   // NEW: import 'package:braven_charts/src/interaction/chart_element.dart';
   ```

3. **Chart Transform** (for Phase 3, but copy now):
   ```powershell
   Copy-Item "refactor\interaction\lib\transforms\chart_transform.dart" "lib\src\coordinates\chart_transform.dart"
   ```

4. **Element Interface** (for Phase 2, but copy now):
   ```powershell
   Copy-Item "refactor\interaction\lib\core\chart_element.dart" "lib\src\interaction\chart_element.dart"
   Copy-Item "refactor\interaction\lib\core\element_types.dart" "lib\src\interaction\element_types.dart"
   ```

**Verification**:
```powershell
flutter analyze lib/src/interaction/core/
flutter analyze lib/src/rendering/spatial_index.dart
flutter analyze lib/src/coordinates/chart_transform.dart
flutter analyze lib/src/interaction/chart_element.dart
```

**Expected**: Zero errors (some warnings about unused imports OK for now).

**Commit Point 1**:
```powershell
git add lib/src/interaction/core/ lib/src/rendering/spatial_index.dart lib/src/coordinates/ lib/src/interaction/chart_element.dart lib/src/interaction/element_types.dart
git commit -m "feat: Copy core files from prototype with import fixes

- ChartInteractionCoordinator + InteractionMode
- QuadTree spatial indexing
- ChartTransform (3-space coordinates)
- ChartElement interface
- All imports updated for main package structure"
```

---

## Part 3: BravenChartRenderBox - Skeleton

### Step 3.1: Create RenderBox with ALL Fields

**File**: `lib/src/rendering/braven_chart_render_box.dart`

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' show cos, sin, sqrt, log, pow, ln10, max, min;

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

// Import ALL dependencies from _BravenChartPainter
import 'package:braven_charts/src/charts/line/line_chart_config.dart' show LineStyle;
import 'package:braven_charts/src/charts/line/line_interpolator.dart';
import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/src/interaction/core/coordinator.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/widgets/annotations/chart_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/point_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/range_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/text_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/threshold_annotation.dart';
import 'package:braven_charts/src/widgets/annotations/trend_annotation.dart';
import 'package:braven_charts/src/widgets/axis/axis_config.dart';
import 'package:braven_charts/src/widgets/enums/annotation_anchor.dart';
import 'package:braven_charts/src/widgets/enums/annotation_axis.dart';
import 'package:braven_charts/src/widgets/enums/axis_position.dart';
import 'package:braven_charts/src/widgets/enums/chart_type.dart';
import 'package:braven_charts/src/widgets/enums/marker_shape.dart';
import 'package:braven_charts/src/widgets/enums/trend_type.dart';

import 'spatial_index.dart';

/// Data bounds helper class (copied from _BravenChartPainter)
class _DataBounds {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  _DataBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}

/// Custom RenderBox replacing _BravenChartPainter.
///
/// This RenderBox preserves ALL rendering logic from CustomPainter
/// while adding:
/// - Direct pointer event handling (handleEvent)
/// - QuadTree spatial indexing
/// - Coordinator-based interaction state
class BravenChartRenderBox extends RenderBox {
  BravenChartRenderBox({
    required ChartType chartType,
    required LineStyle lineStyle,
    required List<ChartSeries> series,
    required ChartTheme theme,
    required AxisConfig xAxis,
    required AxisConfig yAxis,
    required List<ChartAnnotation> annotations,
    required ChartInteractionCoordinator coordinator,
    ZoomPanState? zoomPanState,
    _DataBounds? originalDataBounds,
    void Function(Rect chartRect, Size size)? onChartRectCalculated,
  })  : _chartType = chartType,
        _lineStyle = lineStyle,
        _series = series,
        _theme = theme,
        _xAxis = xAxis,
        _yAxis = yAxis,
        _annotations = annotations,
        _coordinator = coordinator,
        _zoomPanState = zoomPanState,
        _originalDataBounds = originalDataBounds,
        _onChartRectCalculated = onChartRectCalculated;

  // ==================== FIELDS (ALL FROM _BravenChartPainter) ====================

  ChartType _chartType;
  LineStyle _lineStyle;
  List<ChartSeries> _series;
  ChartTheme _theme;
  AxisConfig _xAxis;
  AxisConfig _yAxis;
  List<ChartAnnotation> _annotations;
  final ChartInteractionCoordinator _coordinator;
  ZoomPanState? _zoomPanState;
  _DataBounds? _originalDataBounds;
  void Function(Rect chartRect, Size size)? _onChartRectCalculated;

  // NEW: Spatial index for hit testing
  QuadTree? _spatialIndex;
  Rect _plotArea = Rect.zero;

  // Static profiling flag (from _BravenChartPainter)
  static bool enablePaintProfiling = false;

  // ==================== GETTERS/SETTERS ====================

  ChartType get chartType => _chartType;
  set chartType(ChartType value) {
    if (_chartType == value) return;
    _chartType = value;
    markNeedsPaint();
  }

  LineStyle get lineStyle => _lineStyle;
  set lineStyle(LineStyle value) {
    if (_lineStyle == value) return;
    _lineStyle = value;
    markNeedsPaint();
  }

  List<ChartSeries> get series => _series;
  set series(List<ChartSeries> value) {
    if (_series == value) return;
    _series = value;
    markNeedsPaint();
    markNeedsLayout(); // Series change may affect bounds
  }

  ChartTheme get theme => _theme;
  set theme(ChartTheme value) {
    if (_theme == value) return;
    _theme = value;
    markNeedsPaint();
  }

  AxisConfig get xAxis => _xAxis;
  set xAxis(AxisConfig value) {
    if (_xAxis == value) return;
    _xAxis = value;
    markNeedsPaint();
    markNeedsLayout(); // Axis config may affect layout
  }

  AxisConfig get yAxis => _yAxis;
  set yAxis(AxisConfig value) {
    if (_yAxis == value) return;
    _yAxis = value;
    markNeedsPaint();
    markNeedsLayout();
  }

  List<ChartAnnotation> get annotations => _annotations;
  set annotations(List<ChartAnnotation> value) {
    if (_annotations == value) return;
    _annotations = value;
    markNeedsPaint();
  }

  ZoomPanState? get zoomPanState => _zoomPanState;
  set zoomPanState(ZoomPanState? value) {
    if (_zoomPanState == value) return;
    _zoomPanState = value;
    markNeedsPaint();
  }

  _DataBounds? get originalDataBounds => _originalDataBounds;
  set originalDataBounds(_DataBounds? value) {
    if (_originalDataBounds == value) return;
    _originalDataBounds = value;
    markNeedsPaint();
  }

  void Function(Rect chartRect, Size size)? get onChartRectCalculated => _onChartRectCalculated;
  set onChartRectCalculated(void Function(Rect chartRect, Size size)? value) {
    _onChartRectCalculated = value;
  }

  // ==================== LIFECYCLE ====================

  @override
  void performLayout() {
    // Chart respects parent constraints
    size = constraints.biggest;

    // Calculate plot area (PLACEHOLDER - will be replaced with exact logic from _BravenChartPainter)
    // TODO: Copy _calculateAxisReservedSize logic
    const leftMargin = 60.0;
    const rightMargin = 10.0;
    const topMargin = 10.0;
    const bottomMargin = 50.0;

    _plotArea = Rect.fromLTRB(
      leftMargin,
      topMargin,
      size.width - rightMargin,
      size.height - bottomMargin,
    );

    // Build spatial index (PLACEHOLDER - will be populated in Phase 2)
    _spatialIndex = QuadTree(
      bounds: Offset.zero & _plotArea.size,
      maxElementsPerNode: 4,
      maxDepth: 8,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // TODO: PASTE ENTIRE PAINT METHOD FROM _BravenChartPainter HERE
    // For now, placeholder
    final backgroundPaint = Paint()..color = _theme.backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    canvas.restore();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    // PLACEHOLDER: Basic event logging
    if (event is PointerDownEvent) {
      debugPrint('[BravenChartRenderBox] PointerDown at ${event.localPosition}');
      _coordinator.startInteraction(event.localPosition);
    } else if (event is PointerMoveEvent) {
      debugPrint('[BravenChartRenderBox] PointerMove at ${event.localPosition}');
    } else if (event is PointerUpEvent) {
      debugPrint('[BravenChartRenderBox] PointerUp at ${event.localPosition}');
      _coordinator.endInteraction();
      _coordinator.releaseMode();
    }

    // TODO: Full coordinator integration in Phase 1 Task 5
  }

  // ==================== HELPER METHODS (TO BE COPIED FROM _BravenChartPainter) ====================

  // TODO: Copy ALL methods from _BravenChartPainter here:
  // - _calculateDataBounds
  // - _calculateRawDataBounds
  // - _calculateAxisReservedSize
  // - _drawGrid
  // - _drawLineSeries
  // - _drawAreaSeries
  // - _drawBarSeries
  // - _drawScatterSeries
  // - _drawAxes
  // - _drawAnnotations
  // - _dataToPixel
  // - _pixelToData
  // - _drawAxis
  // - _formatAxisLabel
  // - _generateAxisTicks
  // - _drawMarker
  // - _drawMarkerShape
  // - _drawPointAnnotation
  // - _drawRangeAnnotation
  // - _drawTextAnnotation
  // - _drawThresholdAnnotation
  // - _drawTrendAnnotation
  // - _drawSelection
  // - _drawHoverEffects
  // (26+ methods total)
}
```

**Verification**:
```powershell
flutter analyze lib/src/rendering/braven_chart_render_box.dart
```

**Expected**: Zero errors. Warnings about unused variables OK.

**Commit Point 2**:
```powershell
git add lib/src/rendering/braven_chart_render_box.dart
git commit -m "feat: Add BravenChartRenderBox skeleton with all fields

- All 10 fields from _BravenChartPainter preserved
- Getters/setters with markNeedsPaint/markNeedsLayout
- Basic performLayout/paint/hitTest/handleEvent
- Placeholder spatial index initialization
- Coordinator integration placeholder
- Ready for paint logic migration"
```

---

## Part 4: Paint Logic Migration (CRITICAL)

### Step 4.1: Extract EXACT Paint Method

**Source**: `lib/src/widgets/braven_chart.dart`, line 4287

**Task**: Copy lines 4287-~5500 (entire paint method) into `BravenChartRenderBox.paint()`

**Critical Details**:
1. **Line-by-line copy** - NO MODIFICATIONS initially
2. **Canvas API adaptation**:
   ```dart
   // OLD (CustomPainter):
   void paint(Canvas canvas, Size size) {
     canvas.drawRect(...);
   }

   // NEW (RenderBox):
   void paint(PaintingContext context, Offset offset) {
     final canvas = context.canvas;
     canvas.save();
     canvas.translate(offset.dx, offset.dy);
     
     // PASTE EXACT CODE HERE (use canvas as before)
     canvas.drawRect(...);
     
     canvas.restore();
   }
   ```

3. **Field access changes**:
   ```dart
   // OLD: chartType
   // NEW: _chartType

   // OLD: series
   // NEW: _series

   // OLD: theme
   // NEW: _theme

   // etc. for all fields
   ```

**Action**: Use find/replace to update field references:
- Find: `chartType` → Replace: `_chartType`
- Find: `lineStyle` → Replace: `_lineStyle`
- Find: `series` → Replace: `_series`
- Find: `theme` → Replace: `_theme`
- Find: `xAxis` → Replace: `_xAxis`
- Find: `yAxis` → Replace: `_yAxis`
- Find: `annotations` → Replace: `_annotations`
- Find: `zoomPanState` → Replace: `_zoomPanState`
- Find: `originalDataBounds` → Replace: `_originalDataBounds`
- Find: `onChartRectCalculated` → Replace: `_onChartRectCalculated`

**Verification Steps**:
1. Count lines in original paint method: ~1213 lines
2. Count lines in new paint method: Should match
3. Compile: `flutter analyze lib/src/rendering/braven_chart_render_box.dart`
4. Expected: Zero errors

**Commit Point 3**:
```powershell
git add lib/src/rendering/braven_chart_render_box.dart
git commit -m "feat: Migrate paint() method from CustomPainter to RenderBox

- Copied entire paint() method (1213 lines)
- Updated canvas API (context.canvas + save/translate/restore)
- Updated all field references (_chartType, _series, etc.)
- Zero logic changes - pixel-perfect preservation"
```

---

### Step 4.2: Extract ALL Helper Methods

**Source**: Lines 5500-7306 in `braven_chart.dart`

**Methods to copy** (COMPLETE LIST - verify by reading file):

```dart
// Data calculation
_DataBounds? _calculateDataBounds({Rect? chartRect}) { ... }
_DataBounds _calculateRawDataBounds(List<ChartSeries> allSeries) { ... }
double _calculateAxisReservedSize(AxisConfig axis, _DataBounds bounds, bool isHorizontal) { ... }

// Grid rendering
void _drawGrid(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }

// Series rendering
void _drawLineSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawAreaSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawBarSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawScatterSeries(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }

// Axis rendering
void _drawAxes(Canvas canvas, Size size, Rect chartRect, _DataBounds bounds) { ... }
void _drawAxis(Canvas canvas, AxisConfig axis, Rect chartRect, _DataBounds bounds, bool isHorizontal) { ... }
String _formatAxisLabel(double value, AxisConfig axis) { ... }
List<double> _generateAxisTicks(AxisConfig axis, double min, double max, bool isHorizontal) { ... }

// Coordinate conversion
Offset _dataToPixel(double x, double y, Rect chartRect, _DataBounds bounds) { ... }
ChartDataPoint _pixelToData(Offset pixel, Rect chartRect, _DataBounds bounds) { ... }

// Marker rendering
void _drawMarker(Canvas canvas, Offset position, ChartSeries series) { ... }
void _drawMarkerShape(Canvas canvas, Offset position, MarkerShape shape, double size, Paint paint) { ... }

// Annotation rendering (ALL 5 types)
void _drawPointAnnotation(Canvas canvas, PointAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawRangeAnnotation(Canvas canvas, RangeAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawTextAnnotation(Canvas canvas, TextAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawThresholdAnnotation(Canvas canvas, ThresholdAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }
void _drawTrendAnnotation(Canvas canvas, TrendAnnotation annotation, Rect chartRect, _DataBounds bounds) { ... }

// Selection/hover (if exists)
void _drawSelection(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
void _drawHoverEffects(Canvas canvas, Rect chartRect, _DataBounds bounds) { ... }
```

**Action**:
1. **READ** lines 5500-7306 in `braven_chart.dart`
2. **IDENTIFY** every method that starts with `_` (private methods)
3. **COPY** each method verbatim into `BravenChartRenderBox`
4. **UPDATE** field references (same find/replace as Step 4.1)

**Verification Checklist**:
```markdown
### Helper Methods Migration Checklist

- [ ] _calculateDataBounds (2 overloads?)
- [ ] _calculateRawDataBounds
- [ ] _calculateAxisReservedSize
- [ ] _drawGrid
- [ ] _drawLineSeries
- [ ] _drawAreaSeries
- [ ] _drawBarSeries
- [ ] _drawScatterSeries
- [ ] _drawAxes
- [ ] _drawAxis
- [ ] _formatAxisLabel
- [ ] _generateAxisTicks
- [ ] _dataToPixel
- [ ] _pixelToData
- [ ] _drawMarker
- [ ] _drawMarkerShape
- [ ] _drawPointAnnotation
- [ ] _drawRangeAnnotation
- [ ] _drawTextAnnotation
- [ ] _drawThresholdAnnotation
- [ ] _drawTrendAnnotation
- [ ] _drawSelection (if exists)
- [ ] _drawHoverEffects (if exists)
- [ ] Any other _private methods
```

**Commit Point 4**:
```powershell
git add lib/src/rendering/braven_chart_render_box.dart
git commit -m "feat: Migrate all helper methods from CustomPainter

- Copied 26+ private methods
- Updated field references
- Zero logic changes
- All rendering logic now in RenderBox"
```

---

## Part 5: Widget Integration

### Step 5.1: Create RenderObjectWidget

**File**: `lib/src/widgets/braven_chart_render_widget.dart` (NEW)

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:braven_charts/src/charts/line/line_chart_config.dart' show LineStyle;
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/src/interaction/core/coordinator.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/src/rendering/braven_chart_render_box.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/widgets/annotations/chart_annotation.dart';
import 'package:braven_charts/src/widgets/axis/axis_config.dart';
import 'package:braven_charts/src/widgets/enums/chart_type.dart';

/// Widget that creates BravenChartRenderBox.
///
/// This widget replaces the CustomPaint widget that was used before.
class BravenChartRenderWidget extends LeafRenderObjectWidget {
  const BravenChartRenderWidget({
    super.key,
    required this.chartType,
    required this.lineStyle,
    required this.series,
    required this.theme,
    required this.xAxis,
    required this.yAxis,
    required this.annotations,
    required this.coordinator,
    this.zoomPanState,
    this.originalDataBounds,
    this.onChartRectCalculated,
  });

  final ChartType chartType;
  final LineStyle lineStyle;
  final List<ChartSeries> series;
  final ChartTheme theme;
  final AxisConfig xAxis;
  final AxisConfig yAxis;
  final List<ChartAnnotation> annotations;
  final ChartInteractionCoordinator coordinator;
  final ZoomPanState? zoomPanState;
  final dynamic originalDataBounds; // _DataBounds from RenderBox
  final void Function(Rect chartRect, Size size)? onChartRectCalculated;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return BravenChartRenderBox(
      chartType: chartType,
      lineStyle: lineStyle,
      series: series,
      theme: theme,
      xAxis: xAxis,
      yAxis: yAxis,
      annotations: annotations,
      coordinator: coordinator,
      zoomPanState: zoomPanState,
      originalDataBounds: originalDataBounds,
      onChartRectCalculated: onChartRectCalculated,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant BravenChartRenderBox renderObject) {
    renderObject
      ..chartType = chartType
      ..lineStyle = lineStyle
      ..series = series
      ..theme = theme
      ..xAxis = xAxis
      ..yAxis = yAxis
      ..annotations = annotations
      ..zoomPanState = zoomPanState
      ..originalDataBounds = originalDataBounds
      ..onChartRectCalculated = onChartRectCalculated;
  }
}
```

**Commit Point 5**:
```powershell
git add lib/src/widgets/braven_chart_render_widget.dart
git commit -m "feat: Add RenderObjectWidget for BravenChartRenderBox

- Widget wraps RenderBox creation
- All fields passed through
- updateRenderObject updates mutable fields
- Ready to replace CustomPaint"
```

---

### Step 5.2: Replace CustomPaint in BravenChart Widget

**File**: `lib/src/widgets/braven_chart.dart`

**Location**: Find where `CustomPaint` is created (around line 2000-2500)

**Current code** (approximate):
```dart
final interactiveWidget = CustomPaint(
  painter: _BravenChartPainter(
    chartType: widget.chartType,
    lineStyle: widget.lineStyle,
    series: allSeries,
    theme: effectiveTheme,
    xAxis: effectiveXAxis,
    yAxis: effectiveYAxis,
    annotations: allAnnotations,
    zoomPanState: _interactionStateNotifier.value.zoomPanState,
    originalDataBounds: preliminaryBounds,
    onChartRectCalculated: (chartRect, size) {
      _cachedChartRect = chartRect;
    },
  ),
  child: Container(),
);
```

**New code**:
```dart
// Import at top of file
import 'package:braven_charts/src/widgets/braven_chart_render_widget.dart';

// In build method
final interactiveWidget = BravenChartRenderWidget(
  chartType: widget.chartType,
  lineStyle: widget.lineStyle,
  series: allSeries,
  theme: effectiveTheme,
  xAxis: effectiveXAxis,
  yAxis: effectiveYAxis,
  annotations: allAnnotations,
  coordinator: _coordinator, // NEW: Must initialize in State
  zoomPanState: _interactionStateNotifier.value.zoomPanState,
  originalDataBounds: preliminaryBounds,
  onChartRectCalculated: (chartRect, size) {
    _cachedChartRect = chartRect;
  },
);
```

**CRITICAL**: Must initialize `_coordinator` in `_BravenChartState`:

```dart
class _BravenChartState extends State<BravenChart> with TickerProviderStateMixin {
  // ... existing fields ...
  
  // NEW: Coordinator for interaction system
  late final ChartInteractionCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    
    // Initialize coordinator FIRST
    _coordinator = ChartInteractionCoordinator();
    
    // ... rest of initState ...
  }

  @override
  void dispose() {
    // Dispose coordinator LAST
    _coordinator.dispose();
    
    // ... rest of dispose ...
    super.dispose();
  }
}
```

**Commit Point 6**:
```powershell
git add lib/src/widgets/braven_chart.dart
git commit -m "feat: Replace CustomPaint with RenderObjectWidget

- Import BravenChartRenderWidget
- Replace CustomPaint creation
- Initialize ChartInteractionCoordinator in State
- Dispose coordinator properly
- Zero functional changes - rendering identical"
```

---

## Part 6: Testing & Verification

### Step 6.1: Compile & Analyze

```powershell
# Full project analysis
flutter analyze

# Expected: Zero errors
# Acceptable: Warnings about unused imports/variables
```

**If errors**:
1. Missing imports → Add them
2. Type mismatches → Check field types match exactly
3. Undefined methods → Verify all helper methods copied

---

### Step 6.2: Run Example App

```powershell
cd example
flutter run -d chrome
```

**Visual Verification Checklist**:
- [ ] Chart renders (not blank white screen)
- [ ] Background color matches theme
- [ ] Grid lines visible
- [ ] Axes render with labels
- [ ] Series data displays (line/area/bar/scatter)
- [ ] Annotations visible
- [ ] Markers visible
- [ ] No visual glitches/artifacts

**If blank or errors**:
1. Check browser console for errors
2. Add `debugPrint` statements in `paint()` to verify it's called
3. Check `performLayout()` is calculating correct `_plotArea`

---

### Step 6.3: Test Interactions

**Basic interaction tests**:
- [ ] Click on chart → See "PointerDown" log in console
- [ ] Drag on chart → See "PointerMove" logs
- [ ] Release → See "PointerUp" log
- [ ] Hover → See "PointerHover" logs (desktop/web only)

**If no logs**:
1. Check `handleEvent()` is implemented
2. Check `hitTest()` returns true
3. Verify coordinator initialized

---

### Step 6.4: Run Unit Tests

```powershell
cd ..
flutter test
```

**Expected**: All existing tests pass

**If failures**:
1. Tests expecting `CustomPainter` → Update to `RenderBox`
2. Tests checking `shouldRepaint` → Update to `markNeedsPaint`
3. Mock dependencies → Update imports

---

### Step 6.5: Performance Benchmark

**Create benchmark script** (`test/benchmarks/render_benchmark.dart`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  testWidgets('Paint performance benchmark', (tester) async {
    final stopwatch = Stopwatch()..start();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BravenChart(
            chartType: ChartType.line,
            series: [
              ChartSeries(
                id: 'test',
                points: List.generate(1000, (i) => ChartDataPoint(x: i.toDouble(), y: i * 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
    
    stopwatch.stop();
    print('Initial render: ${stopwatch.elapsedMilliseconds}ms');
    
    expect(stopwatch.elapsedMilliseconds, lessThan(100), reason: 'Initial render should be <100ms');
  });
}
```

**Run benchmark**:
```powershell
flutter test test/benchmarks/render_benchmark.dart
```

**Expected**: <100ms for 1000 points

---

## Part 7: Final Checklist & Commit

### Phase 1 Complete Checklist

**Core Migration**:
- [ ] All 10 fields from `_BravenChartPainter` in `BravenChartRenderBox`
- [ ] All 26+ helper methods copied verbatim
- [ ] `paint()` method migrated (1213 lines)
- [ ] Canvas API updated (context.canvas + save/restore)
- [ ] Field references updated (_chartType, etc.)

**Integration**:
- [ ] `BravenChartRenderWidget` created
- [ ] `CustomPaint` replaced in `BravenChart` widget
- [ ] `ChartInteractionCoordinator` initialized
- [ ] Import paths correct

**Testing**:
- [ ] `flutter analyze` passes (zero errors)
- [ ] Example app renders identically
- [ ] Basic pointer events logged
- [ ] All unit tests pass
- [ ] Performance benchmark <100ms

**Documentation**:
- [ ] Comments added explaining migration
- [ ] TODO markers for Phase 2 tasks
- [ ] Commit messages descriptive

---

### Final Commit

```powershell
git add .
git commit -m "feat: PHASE 1 COMPLETE - CustomPainter → RenderBox migration

SUMMARY:
- Migrated 7,306 lines from _BravenChartPainter to BravenChartRenderBox
- All 10 fields preserved
- All 26+ helper methods copied verbatim
- Zero logic changes - pixel-perfect rendering preservation
- Coordinator integrated with basic event logging
- QuadTree spatial index initialized (not utilized yet)
- All tests passing
- Example app renders identically
- Performance: <100ms for 1000 points

NEXT: Phase 2 - Element System Integration

FILES CHANGED:
- lib/src/rendering/braven_chart_render_box.dart (NEW, 2500+ lines)
- lib/src/widgets/braven_chart_render_widget.dart (NEW, 60 lines)
- lib/src/widgets/braven_chart.dart (MODIFIED, CustomPaint → RenderWidget)
- lib/src/interaction/core/coordinator.dart (COPIED from prototype)
- lib/src/interaction/core/interaction_mode.dart (COPIED from prototype)
- lib/src/rendering/spatial_index.dart (COPIED from prototype)
- lib/src/coordinates/chart_transform.dart (COPIED from prototype)
- lib/src/interaction/chart_element.dart (COPIED from prototype)
- lib/src/interaction/element_types.dart (COPIED from prototype)

TESTING:
✅ flutter analyze: PASS
✅ Visual verification: IDENTICAL
✅ Unit tests: PASS (all existing)
✅ Performance benchmark: PASS (<100ms)
✅ Basic interactions: LOGGING CONFIRMED"
```

---

## Troubleshooting Guide

### Issue 1: Blank Chart
**Symptom**: Chart renders but shows only background, no data  
**Cause**: `paint()` method not painting series  
**Fix**: Verify `_drawLineSeries` (and other series methods) are called in `paint()`

---

### Issue 2: Compilation Errors
**Symptom**: "Undefined name '_chartType'"  
**Cause**: Field references not updated from `chartType` to `_chartType`  
**Fix**: Run find/replace again:
```dart
// In BravenChartRenderBox only:
Find: (?<!_)(chartType|lineStyle|series|theme|xAxis|yAxis|annotations|zoomPanState|originalDataBounds|onChartRectCalculated)
Replace: _$1
Regex: ON
```

---

### Issue 3: No Pointer Events
**Symptom**: Clicks don't log anything  
**Cause**: `hitTest()` not working or `handleEvent()` not implemented  
**Fix**:
1. Verify `hitTestSelf()` returns `true`
2. Verify `hitTest()` adds `BoxHitTestEntry`
3. Add debug print at start of `handleEvent()`

---

### Issue 4: Layout Issues
**Symptom**: Chart is wrong size or axes overlap data  
**Cause**: `performLayout()` not calculating `_plotArea` correctly  
**Fix**: Copy exact axis padding logic from `_BravenChartPainter.paint()` lines ~4330-4350

---

## Time Estimates

**Conservative (2 weeks)**:
- Day 1-2: File copying + import fixes (4-6 hours)
- Day 3-5: RenderBox skeleton + paint migration (12-16 hours)
- Day 6-7: Helper methods migration (8-12 hours)
- Day 8-9: Widget integration (6-8 hours)
- Day 10: Testing + bug fixes (8 hours)

**Aggressive (1 week)**:
- Day 1: File copying + RenderBox skeleton (8 hours)
- Day 2-3: Paint + helper methods migration (16 hours)
- Day 4: Widget integration (6 hours)
- Day 5: Testing + polish (6 hours)

---

## Success Criteria Summary

Phase 1 is **COMPLETE** when:
1. ✅ Chart renders **pixel-perfect identical** to before
2. ✅ All 10 fields preserved
3. ✅ All 26+ methods copied
4. ✅ Coordinator logging events
5. ✅ QuadTree initialized
6. ✅ Zero test failures
7. ✅ Zero visual regressions
8. ✅ Performance maintained (<100ms)

**DO NOT PROCEED to Phase 2** until ALL criteria met.

---

*Phase 1 Detailed Plan v1.0*  
*Last Updated: 2025-11-10*  
*Total Pages: 25*  
*Estimated Reading Time: 45 minutes*  
*Estimated Implementation Time: 1-2 weeks*
