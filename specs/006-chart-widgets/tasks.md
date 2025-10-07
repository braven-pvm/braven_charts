# Tasks: Chart Widgets with Annotations

**Feature**: 006-chart-widgets  
**Branch**: `006-chart-widgets`  
**Input**: Design documents from `/specs/006-chart-widgets/`  
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

---

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Extract: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216
   → Tech stack: StatefulWidget, ChangeNotifier, Stream integration
2. Load optional design documents ✅
   → data-model.md: 5 entities (BravenChart, ChartController, AxisConfig, ChartAnnotation + 5 subtypes)
   → contracts/: 4 contract files (braven_chart, chart_controller, axis_config, annotations)
   → research.md: 7 architectural decisions documented
   → quickstart.md: 6 integration scenarios
3. Generate tasks by category:
   → Setup: Directory structure, exports, barrel files
   → Tests: 4 contract test files (move from specs/ to test/)
   → Core: 5 entities + 8 supporting types
   → Widget: BravenChart StatefulWidget implementation
   → Integration: Widget tests, golden tests, quickstart validation
   → Polish: Documentation, examples, performance validation
4. Apply task rules:
   → Different files = mark [P] for parallel execution
   → Same file = sequential (no [P])
   → Tests before implementation (TDD red → green → refactor)
5. Number tasks sequentially (T001-T038)
6. Dependencies: Enums → Annotations → AxisConfig → Controller → Widget
7. Parallel execution: Enums [P], Annotation subtypes [P], Test files [P]
8. Validation: All contracts → tests, all entities → implementation
```

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **File paths**: All paths relative to repository root
- **TDD cycle**: Write test → Run (fail) → Implement → Run (pass) → Refactor

---

## Path Conventions
```
lib/src/widgets/              # Layer 5 - Widget implementations
├── annotations/              # Annotation classes
├── axis/                     # AxisConfig and related
├── controller/               # ChartController
├── enums/                    # Supporting enums
└── braven_chart.dart         # Main widget

test/widgets/                 # Widget tests (mirror lib structure)
├── contracts/                # Contract tests (moved from specs/)
├── golden/                   # Golden file tests
└── integration/              # Integration tests
```

---

## Phase 3.1: Setup & Structure

### T001: Create directory structure for Layer 5 ✅
**Description**: Create all necessary directories for the widgets layer  
**File Operations**:
- Create `lib/src/widgets/` ✅
- Create `lib/src/widgets/annotations/` ✅
- Create `lib/src/widgets/axis/` ✅
- Create `lib/src/widgets/controller/` ✅
- Create `lib/src/widgets/enums/` ✅
- Create `test/widgets/` ✅
- Create `test/widgets/contracts/` ✅
- Create `test/widgets/golden/` ✅
- Create `test/widgets/integration/` ✅

**Success Criteria**: All directories exist and follow Layer 5 structure ✅

---

### T002: [P] Move contract tests from specs/ to test/ ✅
**Description**: Move all 4 contract test files from specs/006-chart-widgets/contracts/ to test/widgets/contracts/  
**Source Files**:
- `specs/006-chart-widgets/contracts/braven_chart_contract.dart` ✅
- `specs/006-chart-widgets/contracts/chart_controller_contract.dart` ✅
- `specs/006-chart-widgets/contracts/axis_config_contract.dart` ✅
- `specs/006-chart-widgets/contracts/annotation_contracts.dart` ✅

**Destination**: `test/widgets/contracts/` ✅

**File Operations**:
- Move (not copy) all 4 files ✅
- Update import paths to reference `package:braven_charts/braven_charts.dart` (deferred to implementation)
- Verify all tests still compile (they will fail - that's expected TDD red phase) (T004)

**Success Criteria**: 4 contract files in test/widgets/contracts/, imports correct, tests compile with errors (undefined types) ✅

---

### T003: [P] Create barrel file for widgets layer ✅
**Description**: Create main export file for Layer 5 public API  
**File**: `lib/src/widgets/widgets.dart` ✅

**Content**:
```dart
/// Layer 5: Chart Widgets
/// 
/// User-facing widget API for Braven Charts.
/// Single entry point: BravenChart widget.
library braven_charts.widgets;

// Enums
export 'enums/chart_type.dart';
export 'enums/annotation_axis.dart';
export 'enums/annotation_anchor.dart';
export 'enums/marker_shape.dart';
export 'enums/trend_type.dart';
export 'enums/axis_position.dart';
export 'enums/axis_range.dart';

// Annotations
export 'annotations/chart_annotation.dart';
export 'annotations/text_annotation.dart';
export 'annotations/point_annotation.dart';
export 'annotations/range_annotation.dart';
export 'annotations/threshold_annotation.dart';
export 'annotations/trend_annotation.dart';
export 'annotations/annotation_style.dart';

// Axis
export 'axis/axis_config.dart';

// Controller
export 'controller/chart_controller.dart';

// Main widget
export 'braven_chart.dart';
```

**Success Criteria**: Barrel file exports all public APIs (files don't exist yet - that's okay)

---

## Phase 3.2: Tests First (TDD Red Phase) ⚠️ CRITICAL

**IMPORTANT**: Contract tests are already written (moved in T002). This phase verifies they fail correctly.

### T004: Verify contract tests fail with correct errors ✅
**Description**: Run all contract tests and confirm they fail with "undefined type" errors  
**Command**: `flutter analyze test/widgets/contracts/`

**Expected Failures**:
- `braven_chart_contract.dart`: ~166 errors (BravenChart, ChartType undefined) ✅
- `chart_controller_contract.dart`: ~147 errors (ChartController, ChangeNotifier undefined) ✅
- `axis_config_contract.dart`: ~8 errors (AxisConfig undefined) ✅
- `annotation_contracts.dart`: ~14 errors (TextAnnotation, PointAnnotation, etc. undefined) ✅

**Success Criteria**: Tests compile, all fail with "undefined name" errors (TDD red phase confirmed) ✅

---

## Phase 3.3: Supporting Types (Enums & Value Objects)

**NOTE**: These can all run in parallel - different files, no dependencies

### T005: [P] Implement ChartType enum ✅
**Description**: Create chart type enumeration  
**File**: `lib/src/widgets/enums/chart_type.dart` ✅

**Tests**: Covered by braven_chart_contract.dart (enum reference)

**Success Criteria**: Enum defined, exports in widgets.dart, contract tests compile further ✅

---

### T006: [P] Implement AnnotationAxis enum ✅
**Description**: Create annotation axis enumeration  
**File**: `lib/src/widgets/enums/annotation_axis.dart` ✅

**Tests**: Covered by annotation_contracts.dart (ThresholdAnnotation)

**Success Criteria**: Enum defined, used in ThresholdAnnotation ✅

---

### T007: [P] Implement AnnotationAnchor enum ✅
**Description**: Create annotation anchor position enumeration  
**File**: `lib/src/widgets/enums/annotation_anchor.dart` ✅

**Tests**: Covered by annotation_contracts.dart (TextAnnotation)

**Success Criteria**: Enum defined with 9 positions ✅

---

### T008: [P] Implement MarkerShape enum ✅
**Description**: Create marker shape enumeration for point annotations  
**File**: `lib/src/widgets/enums/marker_shape.dart` ✅

**Tests**: Covered by annotation_contracts.dart (PointAnnotation)

**Success Criteria**: Enum defined with 7 shapes ✅

---

### T009: [P] Implement TrendType enum ✅
**Description**: Create trend type enumeration for trend annotations  
**File**: `lib/src/widgets/enums/trend_type.dart` ✅

**Tests**: Covered by annotation_contracts.dart (TrendAnnotation)

**Success Criteria**: Enum defined with 4 trend types ✅

---

### T010: [P] Implement AxisPosition enum ✅
**Description**: Create axis position enumeration  
**File**: `lib/src/widgets/enums/axis_position.dart` ✅

**Content**:
```dart
/// Axis positioning
enum AxisPosition {
  bottom,
  top,
  left,
  right,
}
```

**Tests**: Covered by axis_config_contract.dart

**Success Criteria**: Enum defined

---

### T011: [P] Implement AxisRange enum ✅
**Description**: Create axis range mode enumeration  
**File**: `lib/src/widgets/enums/axis_range.dart` ✅

**Tests**: Covered by axis_config_contract.dart

**Success Criteria**: Enum defined with 3 modes ✅

---

### T012: [P] Implement AnnotationStyle value object ✅
**Description**: Create immutable annotation style configuration  
**File**: `lib/src/widgets/annotations/annotation_style.dart` ✅

**Content**: Per data-model.md specification
- Properties: fontSize, fontWeight, textColor, backgroundColor, borderColor, borderWidth ✅
- Immutable class with const constructor ✅
- copyWith() method ✅

**Tests**: Implicitly tested through annotation contracts

**Success Criteria**: Immutable value object, all properties final ✅

---

## Phase 3.4: Annotation System

**Dependencies**: T005-T012 (enums) must complete first ✅

### T013: [P] Implement ChartAnnotation base class ✅
**Description**: Create abstract base class for all annotations  
**File**: `lib/src/widgets/annotations/chart_annotation.dart` ✅

**Requirements** (from data-model.md):
- Abstract base class ✅
- Properties: id, label, style, allowDragging, allowEditing, zIndex ✅
- Auto-generated ID if not provided ✅
- Immutable ✅

**Tests**: Covered by annotation_contracts.dart (all 5 subtype tests)

**Success Criteria**: Abstract class defined, all properties, contracts compile ✅

---

### T014: [P] Implement TextAnnotation ✅
**Description**: Free-floating text annotation at screen position  
**File**: `lib/src/widgets/annotations/text_annotation.dart` ✅

**Requirements** (from data-model.md):
- Extends ChartAnnotation ✅
- Properties: position (Offset), anchor (AnnotationAnchor), backgroundColor, borderColor ✅
- Validation: position cannot be negative ✅

**Tests**: `annotation_contracts.dart` - TextAnnotation group

**Success Criteria**: Class defined, extends ChartAnnotation, tests pass ✅

---

### T015: [P] Implement PointAnnotation ✅
**Description**: Data point marker annotation  
**File**: `lib/src/widgets/annotations/point_annotation.dart` ✅

**Requirements** (from data-model.md):
- Extends ChartAnnotation ✅
- Properties: seriesId, dataPointIndex, offset, markerShape, markerSize, markerColor ✅
- Validation: dataPointIndex >= 0 ✅

**Tests**: `annotation_contracts.dart` - PointAnnotation group

**Success Criteria**: Class defined, validation works, tests pass ✅

---

### T016: [P] Implement RangeAnnotation ✅
**Description**: Time/value range highlighting  
**File**: `lib/src/widgets/annotations/range_annotation.dart` ✅

**Requirements** (from data-model.md):
- Extends ChartAnnotation ✅
- Properties: startX, endX, startY, endY, fillColor, borderColor, labelPosition ✅
- Validation: startX < endX, startY < endY (if provided) ✅

**Tests**: `annotation_contracts.dart` - RangeAnnotation group (includes validation test)

**Success Criteria**: Class defined, validation enforces startX < endX, tests pass ✅

---

### T017: [P] Implement ThresholdAnnotation ✅
**Description**: Reference line at fixed axis value  
**File**: `lib/src/widgets/annotations/threshold_annotation.dart` ✅

**Requirements** (from data-model.md):
- Extends ChartAnnotation ✅
- Properties: axis (AnnotationAxis), value, lineColor, lineWidth, dashPattern, labelPosition ✅
- Validation: value cannot be NaN or infinite ✅

**Tests**: `annotation_contracts.dart` - ThresholdAnnotation group

**Success Criteria**: Class defined, axis property typed, tests pass ✅

---

### T018: [P] Implement TrendAnnotation ✅
**Description**: Statistical trend overlay  
**File**: `lib/src/widgets/annotations/trend_annotation.dart` ✅

**Requirements** (from data-model.md):
- Extends ChartAnnotation ✅
- Properties: seriesId, trendType, windowSize, degree, lineColor, lineWidth, dashPattern ✅
- Validation: windowSize > 0 if trendType == movingAverage ✅

**Tests**: `annotation_contracts.dart` - TrendAnnotation group (includes windowSize validation)

**Success Criteria**: Class defined, validation works, tests pass ✅

---

## Phase 3.5: Axis Configuration

**Dependencies**: T010-T011 (AxisPosition, AxisRange enums) ✅

### T019: Implement AxisConfig value object ✅
**Description**: Comprehensive axis configuration with factory presets  
**File**: `lib/src/widgets/axis/axis_config.dart` ✅

**Requirements** (from data-model.md):
- 45+ properties organized in groups (Visibility, Range, Axis Line, Grid Lines, Ticks, Labels, Advanced) ✅
- 4 factory constructors: defaults(), hidden(), minimal(), gridOnly() ✅
- copyWith() method for customization ✅
- Validation: positive widths, rotation -180° to 180°, range min < max ✅

**Tests**: `axis_config_contract.dart` (all factory tests, copyWith, validation)

**Success Criteria**: All 4 factory presets work, copyWith preserves unchanged values, validation enforces rules, all tests pass ✅

---

## Phase 3.6: Chart Controller

**Dependencies**: T013-T018 (all annotations), Layer 0 (ChartDataPoint) ✅

### T020: Implement ChartController ✅
**Description**: ChangeNotifier-based controller for programmatic chart updates  
**File**: `lib/src/widgets/controller/chart_controller.dart` ✅

**Requirements** (from data-model.md & research.md Decision 2):
- Extends ChangeNotifier ✅
- Internal state: `Map<String, List<ChartDataPoint>>`, `Map<String, ChartAnnotation>` ✅
- Data methods (4): addPoint, removeOldestPoint, clearSeries, getAllSeries ✅
- Annotation methods (8): addAnnotation, removeAnnotation, updateAnnotation, getAnnotation, getAllAnnotations, clearAnnotations, findAnnotationsAt ✅
- Validation: Reject NaN coordinates, validate annotation IDs ✅
- Lifecycle: dispose() clears all state ✅

**Tests**: `chart_controller_contract.dart` (all 40+ tests)

**Success Criteria**: 
- Construction tests pass (extends ChangeNotifier, empty init) ✅
- Data management tests pass (addPoint with notification, removeOldestPoint, clearSeries, getAllSeries) ✅
- Annotation management tests pass (addAnnotation with auto-ID, CRUD operations, findAnnotationsAt) ✅
- Validation tests pass (NaN rejection) ✅
- Disposal tests pass ✅
- All 40+ contract tests pass ✅

---

## Phase 3.7: Main Widget Implementation

**Dependencies**: T005 (ChartType), T019 (AxisConfig), T020 (ChartController), T013-T018 (annotations), Layers 0-4

### ✅ T021: Implement BravenChart widget (Part 1: Constructor & Properties)
**Description**: Create BravenChart StatefulWidget with all properties  
**File**: `lib/src/widgets/braven_chart.dart`

**Requirements** (from data-model.md):
- StatefulWidget class
- 25+ properties (chartType, series, width, height, theme, xAxis, yAxis, annotations, controller, dataStream, title, subtitle, showLegend, showToolbar, interactiveAnnotations, loading/error widgets, callbacks)
- 3 factory constructors: fromValues, fromMap, fromJson
- Validation: non-empty series, positive dimensions, no simultaneous dataStream + series updates

**Partial Tests**: `braven_chart_contract.dart` - Constructor group, Factory constructor group

**Success Criteria**: 
- Widget class defined with all properties ✅
- 3 factory constructors implemented ✅
- Constructor validation tests pass (25+ tests) ✅
- Factory constructor tests pass ✅

**Implementation Notes**:
- Created BravenChart StatefulWidget with 27 properties
- Implemented all 3 factory constructors (fromValues, fromMap, fromJson)
- Added validation assertions for series/dataStream, width, height
- Placeholder State class created (to be completed in T022)
- File compiles with no errors

---

### T022: Implement BravenChart widget (Part 2: State Class & Lifecycle)
**Description**: Implement _BravenChartState with lifecycle management  
**File**: `lib/src/widgets/braven_chart.dart` (same file, continues from T021)

**Requirements** (from research.md Decision 1):
- State class with lifecycle methods
- initState(): Attach controller listener, subscribe to dataStream
- dispose(): Detach controller, cancel stream subscription, dispose internal resources
- didUpdateWidget(): Handle configuration changes without memory leaks
- Resource management: RenderPipeline, ObjectPools, StreamSubscription

**Tests**: `braven_chart_contract.dart` - Controller integration group, Stream integration group, Hot reload group

**Success Criteria**:
- Controller integration tests pass (subscribe, unsubscribe, updates trigger rebuild)
- Stream integration tests pass (subscribe, cancel, throttling at 16ms)
- Hot reload tests pass (didUpdateWidget handles changes)
- No memory leaks on dispose

---

### T023: Implement BravenChart widget (Part 3: Build Method & Rendering)
**Description**: Implement build() method with chart rendering logic  
**File**: `lib/src/widgets/braven_chart.dart` (same file, continues from T022)

**Requirements** (from data-model.md & research.md Decision 7):
- build() returns Widget tree
- Integrate Layer 4 chart implementations (LineChartLayer, AreaChartLayer, BarChartLayer, ScatterChartLayer)
- Apply AxisConfig to coordinate transformer
- Render annotations as overlay (Stack widget)
- Apply theme from ThemeData or widget property
- RepaintBoundary for performance
- Handle loading/error states

**Tests**: `braven_chart_contract.dart` - Rendering group (widget rendering, dimensions, chart types)

**Success Criteria**:
- Rendering tests pass (widget renders correctly)
- Dimensions tests pass (respects width/height)
- Chart type tests pass (all 4 types render correctly)
- All BravenChart contract tests pass (80+ tests)

---

### T024: Implement BravenChart widget (Part 4: Annotation Rendering)
**Description**: Implement annotation overlay rendering  
**File**: `lib/src/widgets/braven_chart.dart` (same file, continues from T023)

**Requirements** (from research.md Decision 4):
- Simple overlay approach using Stack
- Render all 5 annotation types
- Layer 7 migration path (stub for future enhancement)
- Z-index ordering
- Hit testing for interactive annotations
- Respect interactiveAnnotations flag

**Tests**: `braven_chart_contract.dart` - Annotation rendering group

**Success Criteria**:
- Annotation rendering tests pass
- All 5 annotation types render correctly
- Z-index ordering works
- Interactive annotations respond to gestures (if enabled)

---

## Phase 3.8: Widget Tests

**Dependencies**: T021-T024 (BravenChart complete)

### T025: [P] Widget test - Basic rendering scenarios
**Description**: Test widget renders correctly in various scenarios  
**File**: `test/widgets/braven_chart_basic_test.dart`

**Test Cases**:
- Renders with minimal required params
- Renders with all chart types (line, area, bar, scatter)
- Renders with custom dimensions
- Renders with custom theme
- Handles empty series gracefully (error state)

**Success Criteria**: All basic rendering scenarios pass

---

### T026: [P] Widget test - Controller integration
**Description**: Test ChartController interaction with widget  
**File**: `test/widgets/braven_chart_controller_test.dart`

**Test Cases**:
- Controller created internally vs passed externally
- addPoint() triggers rebuild
- removeOldestPoint() updates chart
- clearSeries() updates chart
- addAnnotation() updates overlay
- removeAnnotation() updates overlay
- Multiple controllers don't interfere

**Success Criteria**: All controller integration scenarios pass

---

### T027: [P] Widget test - Stream integration
**Description**: Test real-time data streaming  
**File**: `test/widgets/braven_chart_stream_test.dart`

**Test Cases**:
- dataStream subscription works
- Throttling at 16ms (60 FPS)
- Backpressure handling (data faster than render)
- Stream cancellation on dispose
- Stream updates trigger rebuild
- Stream error shows error widget

**Success Criteria**: All stream scenarios pass, no memory leaks

---

### T028: [P] Widget test - Axis configuration
**Description**: Test AxisConfig application  
**File**: `test/widgets/braven_chart_axis_test.dart`

**Test Cases**:
- defaults() preset renders correctly
- hidden() preset hides axis
- minimal() preset shows grid only
- gridOnly() preset configuration
- copyWith() customization works
- Custom ranges applied correctly

**Success Criteria**: All axis configuration scenarios pass

---

### T029: [P] Widget test - Annotation rendering
**Description**: Test all 5 annotation types render correctly  
**File**: `test/widgets/braven_chart_annotations_test.dart`

**Test Cases**:
- TextAnnotation at position
- PointAnnotation on data point
- RangeAnnotation spanning range
- ThresholdAnnotation as horizontal/vertical line
- TrendAnnotation as overlay
- Z-index ordering
- Interactive annotations (drag, tap)

**Success Criteria**: All 5 annotation types render, interactions work

---

### T030: [P] Widget test - Hot reload support
**Description**: Test widget survives hot reload without memory leaks  
**File**: `test/widgets/braven_chart_hot_reload_test.dart`

**Test Cases**:
- didUpdateWidget() handles series changes
- didUpdateWidget() handles theme changes
- didUpdateWidget() handles controller swap
- didUpdateWidget() handles stream swap
- No duplicate subscriptions
- Old resources disposed

**Success Criteria**: All hot reload scenarios pass, no leaks

---

## Phase 3.9: Golden Tests (Visual Regression)

**Dependencies**: T021-T024 (BravenChart complete)

### T031: [P] Golden test - Chart types
**Description**: Visual regression for all 4 chart types  
**File**: `test/widgets/golden/chart_types_golden_test.dart`

**Golden Files** (generated):
- `line_chart.png`
- `area_chart.png`
- `bar_chart.png`
- `scatter_chart.png`

**Success Criteria**: Golden files match on regeneration

---

### T032: [P] Golden test - Axis configurations
**Description**: Visual regression for axis presets  
**File**: `test/widgets/golden/axis_config_golden_test.dart`

**Golden Files**:
- `axis_defaults.png`
- `axis_hidden.png` (sparkline)
- `axis_minimal.png`
- `axis_grid_only.png`

**Success Criteria**: Golden files match axis configurations

---

### T033: [P] Golden test - Annotations
**Description**: Visual regression for all 5 annotation types  
**File**: `test/widgets/golden/annotations_golden_test.dart`

**Golden Files**:
- `text_annotation.png`
- `point_annotation.png`
- `range_annotation.png`
- `threshold_annotation.png`
- `trend_annotation.png`

**Success Criteria**: Golden files match annotation rendering

---

### T034: [P] Golden test - Themes
**Description**: Visual regression for light/dark themes  
**File**: `test/widgets/golden/themes_golden_test.dart`

**Golden Files**:
- `light_theme.png`
- `dark_theme.png`
- `custom_theme.png`

**Success Criteria**: Golden files match theme application

---

## Phase 3.10: Integration Tests (Quickstart Scenarios)

**Dependencies**: All previous tasks complete

### T035: Integration test - Quickstart Step 1 (Basic Line Chart)
**Description**: Validate 2-minute basic chart scenario from quickstart.md  
**File**: `test/widgets/integration/quickstart_step1_test.dart`

**Test**: Create line chart with sales data per quickstart.md Step 1

**Success Criteria**: Chart renders, axes auto-calculated, legend shown

---

### T036: Integration test - Quickstart Step 2 (Annotations)
**Description**: Validate annotation scenario from quickstart.md  
**File**: `test/widgets/integration/quickstart_step2_test.dart`

**Test**: Add PointAnnotation + ThresholdAnnotation per quickstart.md Step 2

**Success Criteria**: Annotations render on chart

---

### T037: Integration test - Quickstart Step 3-6 (All Features)
**Description**: Validate remaining quickstart scenarios  
**File**: `test/widgets/integration/quickstart_full_test.dart`

**Tests**:
- Step 3: fromValues factory
- Step 4: Axis customization (hidden, gridOnly)
- Step 5: Real-time streaming
- Step 6: Programmatic control via ChartController

**Success Criteria**: All 6 quickstart scenarios work end-to-end

---

## Phase 3.11: Documentation & Polish

### T038: Create API documentation and examples
**Description**: Document all public APIs with dartdoc comments  
**Files**:
- `lib/src/widgets/braven_chart.dart` (add comprehensive dartdoc)
- `lib/src/widgets/controller/chart_controller.dart` (add method docs)
- `lib/src/widgets/axis/axis_config.dart` (add factory preset docs)
- `example/lib/main.dart` (create example app with all 6 quickstart scenarios)

**Success Criteria**: 
- All public APIs have dartdoc comments
- Example app demonstrates all features
- `flutter pub publish --dry-run` passes

---

## Dependencies Graph

```
T001 (Structure)
  ↓
T002 (Move contracts) → T004 (Verify tests fail)
  ↓
T003 (Barrel file)
  ↓
T005-T012 (Enums & Value Objects) [ALL PARALLEL]
  ↓
T013 (ChartAnnotation base) → T014-T018 (Annotation subtypes) [ALL PARALLEL]
  ↓                              ↓
T019 (AxisConfig)               ↓
  ↓                              ↓
T020 (ChartController) ←────────┘
  ↓
T021 (BravenChart Part 1: Constructor)
  ↓
T022 (BravenChart Part 2: State & Lifecycle)
  ↓
T023 (BravenChart Part 3: Rendering)
  ↓
T024 (BravenChart Part 4: Annotations)
  ↓
T025-T030 (Widget Tests) [ALL PARALLEL]
  ↓
T031-T034 (Golden Tests) [ALL PARALLEL]
  ↓
T035-T037 (Integration Tests) [3 PARALLEL]
  ↓
T038 (Documentation)
```

---

## Parallel Execution Examples

### Phase 3.3: Supporting Types (7 parallel tasks)
```bash
# All enums can be implemented simultaneously
Task T005: "Implement ChartType enum in lib/src/widgets/enums/chart_type.dart"
Task T006: "Implement AnnotationAxis enum in lib/src/widgets/enums/annotation_axis.dart"
Task T007: "Implement AnnotationAnchor enum in lib/src/widgets/enums/annotation_anchor.dart"
Task T008: "Implement MarkerShape enum in lib/src/widgets/enums/marker_shape.dart"
Task T009: "Implement TrendType enum in lib/src/widgets/enums/trend_type.dart"
Task T010: "Implement AxisPosition enum in lib/src/widgets/enums/axis_position.dart"
Task T011: "Implement AxisRange enum in lib/src/widgets/enums/axis_range.dart"
```

### Phase 3.4: Annotation Subtypes (5 parallel tasks)
```bash
# After T013 (ChartAnnotation base), all subtypes parallel
Task T014: "Implement TextAnnotation in lib/src/widgets/annotations/text_annotation.dart"
Task T015: "Implement PointAnnotation in lib/src/widgets/annotations/point_annotation.dart"
Task T016: "Implement RangeAnnotation in lib/src/widgets/annotations/range_annotation.dart"
Task T017: "Implement ThresholdAnnotation in lib/src/widgets/annotations/threshold_annotation.dart"
Task T018: "Implement TrendAnnotation in lib/src/widgets/annotations/trend_annotation.dart"
```

### Phase 3.8: Widget Tests (6 parallel tasks)
```bash
# After T024 (BravenChart complete), all widget tests parallel
Task T025: "Widget test basic rendering in test/widgets/braven_chart_basic_test.dart"
Task T026: "Widget test controller integration in test/widgets/braven_chart_controller_test.dart"
Task T027: "Widget test stream integration in test/widgets/braven_chart_stream_test.dart"
Task T028: "Widget test axis configuration in test/widgets/braven_chart_axis_test.dart"
Task T029: "Widget test annotation rendering in test/widgets/braven_chart_annotations_test.dart"
Task T030: "Widget test hot reload in test/widgets/braven_chart_hot_reload_test.dart"
```

### Phase 3.9: Golden Tests (4 parallel tasks)
```bash
Task T031: "Golden test chart types in test/widgets/golden/chart_types_golden_test.dart"
Task T032: "Golden test axis configs in test/widgets/golden/axis_config_golden_test.dart"
Task T033: "Golden test annotations in test/widgets/golden/annotations_golden_test.dart"
Task T034: "Golden test themes in test/widgets/golden/themes_golden_test.dart"
```

---

## Validation Checklist
*GATE: Verify before marking tasks.md complete*

- [x] All 4 contract files have corresponding implementation tasks (T013-T024)
- [x] All 5 entities have model tasks (AxisConfig, ChartController, ChartAnnotation + 5 subtypes)
- [x] All contract tests come before implementation (T002-T004 before T005+)
- [x] Parallel tasks truly independent (different files, verified in dependency graph)
- [x] Each task specifies exact file path (all tasks have File: or Files: section)
- [x] No task modifies same file as another [P] task (verified: enums separate, annotations separate, tests separate)
- [x] All quickstart scenarios have integration tests (T035-T037)
- [x] Golden tests cover visual regression (T031-T034)
- [x] TDD cycle enforced (tests → fail → implement → pass → refactor)

---

## Notes

- **TDD Approach**: Contract tests already written (T002), verify they fail (T004), then implement to make them pass
- **Parallel Execution**: 24 tasks marked [P] can run simultaneously (enums, annotations, widget tests, golden tests)
- **Sequential Dependencies**: BravenChart must be built in 4 parts (T021-T024) as they modify the same file
- **Hot Reload**: T030 validates proper resource cleanup per research.md Decision 1
- **Performance**: Stream throttling validated in T027 per research.md Decision 3
- **Constitutional Compliance**: 
  - Test-First: T002-T004 before any implementation ✅
  - Performance: T027 validates 60 FPS throttling ✅
  - Architectural Integrity: Single BravenChart widget ✅
  - Requirements: T035-T037 validate all user stories ✅
  - API Consistency: ChartController follows TextEditingController pattern ✅
  - Documentation: T038 ensures comprehensive docs ✅
  - Simplicity: Factory presets (T019) for discoverability ✅

---

## Estimated Timeline

- **Phase 3.1 (Setup)**: 30 minutes (T001-T003)
- **Phase 3.2 (Verify Tests)**: 15 minutes (T004)
- **Phase 3.3 (Supporting Types)**: 2 hours (T005-T012, parallel)
- **Phase 3.4 (Annotations)**: 3 hours (T013-T018, mostly parallel)
- **Phase 3.5 (AxisConfig)**: 2 hours (T019)
- **Phase 3.6 (Controller)**: 3 hours (T020)
- **Phase 3.7 (BravenChart)**: 6 hours (T021-T024, sequential)
- **Phase 3.8 (Widget Tests)**: 4 hours (T025-T030, parallel)
- **Phase 3.9 (Golden Tests)**: 2 hours (T031-T034, parallel)
- **Phase 3.10 (Integration)**: 2 hours (T035-T037)
- **Phase 3.11 (Docs)**: 2 hours (T038)

**Total Estimated Time**: ~27 hours of implementation

**With Parallel Execution**: ~18-20 hours (7 enums, 5 annotations, 6 widget tests, 4 golden tests can overlap)

---

**Status**: ✅ TASKS READY FOR EXECUTION  
**Next Step**: Begin with T001 (Create directory structure)
