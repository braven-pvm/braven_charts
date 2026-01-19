# Implementation Plan: Dual-Purpose Scrollbars for Chart Navigation

**Branch**: `010-dual-purpose-scrollbars` | **Date**: 2025-01-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-dual-purpose-scrollbars/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add dual-purpose scrollbars to Braven Charts that enable both panning (drag center) and zooming (resize edges) for intuitive chart navigation while maintaining coordinate system independence and constitutional compliance with the ValueNotifier pattern for high-frequency updates. Implement ChartScrollbar widget using CustomPainter for rendering, GestureDetector for dual-zone hit testing (center vs edges), and ScrollbarController for translating pixel-to-data transformations. Integrate with existing ViewportState via withRanges() method, wrap in RepaintBoundary for isolation, and use ValueNotifier pattern (constitutional requirement) for drag state management to prevent setState-induced crashes during pointer events. Extend ChartTheme with ScrollbarTheme component for consistent styling across 28 functional requirements supporting datasets from 100 to 1,000,000+ data points with WCAG 2.1 AA accessibility compliance.

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216  
**Primary Dependencies**: 
- ViewportState (Layer 003 - Coordinate System) for viewport updates via withRanges()
- InteractionConfig (Layer 007 - Interaction System) for enablePan/enableZoom callbacks
- ChartTheme (Layer 004 - Theming System) for ScrollbarTheme integration
- Flutter GestureDetector, CustomPainter, Semantics (dart:ui)
- **CONSTITUTIONAL**: ValueNotifier + ValueListenableBuilder (required for pointer event state >10Hz)

**Storage**: N/A (stateless widget with external data sources)  
**Testing**: Flutter test framework, ChromeDriver for integration tests, golden tests for visual regression  
**Target Platform**: Flutter Web (primary - Chrome), iOS/Android (secondary)  
**Project Type**: Single Flutter library (adding scrollbar components to lib/src/widgets/)  
**Performance Goals**: 
- 60 FPS (≤16.67ms frame time) during drag operations
- <0.1ms handle position calculations (O(1) complexity)
- <16ms viewport updates (full frame budget for chart re-render)
- <100KB memory overhead for both X and Y scrollbars combined

**Constraints**: 
- **CONSTITUTIONAL (Critical)**: ValueNotifier pattern REQUIRED for drag state (>10Hz pointer events) - setState WILL cause box.dart:3345 and mouse_tracker.dart:199 crashes per Constitution v1.1.0 Performance First principle
- **FR-015**: MUST NOT modify chartAreaBounds in TransformContext (coordinate system independence)
- Pure Flutter (no HTML/web-specific APIs per Constitution III - Architectural Integrity)
- Zero Dart analyzer warnings (constitutional requirement)
- No external packages (standard Dart libraries only: dart:core, dart:math, dart:ui, dart:async)
- RepaintBoundary isolation mandatory (prevent cascade rebuilds)

**Scale/Scope**: 
- Handle datasets from 100 to 1,000,000+ data points
- Support both X-axis (horizontal) and Y-axis (vertical) scrollbars
- 28 functional requirements across 7 component interactions
- WCAG 2.1 AA accessibility compliance (keyboard navigation, screen readers, 4.5:1 contrast)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development ✅ **PASS**
- **Requirement**: Contract tests first, implementation follows TDD cycle
- **Status**: Specification includes comprehensive acceptance criteria for all 5 user stories
- **Evidence**: spec.md contains 14 success criteria with measurable validation methods, 28 functional requirements with explicit test conditions
- **Validation**: Phase 0 will establish contract tests before any implementation

### II. Performance First ✅ **PASS** (Constitutional Mandate - Critical)
- **Requirement**: 60fps target, setState MUST NOT be used for >10Hz updates, MUST use ValueNotifier pattern
- **Status**: Feature ENFORCES Constitution v1.1.0 Performance First expansion
- **Evidence**: 
  - FR-025 explicitly requires ValueNotifier for scrollbar drag state (pointer events at 100+ Hz)
  - FR-026 mandates RepaintBoundary isolation to prevent cascade rebuilds
  - SC-008 validates 60 FPS performance during drag operations
  - Performance goals: <0.1ms calculations, <16ms viewport updates
- **Rationale**: Scrollbar drag operations generate continuous pointer events (>100 events/second). Using setState would trigger catastrophic crashes (box.dart:3345, mouse_tracker.dart:199) as documented in Constitution v1.1.0. ValueNotifier provides granular reactivity without rebuild overhead, achieving smooth 60fps interactions.

### III. Architectural Integrity ✅ **PASS**
- **Requirement**: Pure Flutter, SOLID principles, architectural consistency
- **Status**: Feature maintains existing architectural patterns
- **Evidence**:
  - Pure Flutter: Uses only dart:core, dart:math, dart:ui, dart:async (no external packages)
  - SOLID: ChartScrollbar widget with single responsibility, ScrollbarController for transformations, ScrollbarConfig for configuration (SRP, DIP)
  - Coordinate System Independence: FR-015 ensures no modification to TransformContext.chartAreaBounds
  - Integration via existing ViewportState.withRanges() method (Layer 003)
- **Validation**: Architecture follows existing widget patterns (CustomPainter for rendering, GestureDetector for input)

### IV. Requirements Compliance ✅ **PASS**
- **Requirement**: All work tracked in tasks.md, acceptance criteria met
- **Status**: Specification defines comprehensive requirements
- **Evidence**: 28 functional requirements, 14 success criteria, 8 edge cases, 5 user stories with acceptance conditions
- **Validation**: tasks.md will be generated in Phase 2 (/speckit.tasks) tracking all requirements

### V. API Consistency & Stability ✅ **PASS**
- **Requirement**: Follow Flutter conventions, maintain backward compatibility
- **Status**: Feature extends existing API patterns without breaking changes
- **Evidence**:
  - Follows Flutter widget naming (ChartScrollbar extends StatefulWidget)
  - Uses existing callback patterns (ValueChanged<DataRange> onViewportChanged)
  - Integrates with existing InteractionConfig (enablePan, enableZoom properties)
  - No modifications to public API of coordinate system or interaction system
- **Validation**: Zero breaking changes to existing chart functionality

### VI. Documentation Discipline ✅ **PASS**
- **Requirement**: All public APIs documented with examples
- **Status**: Specification includes detailed documentation requirements
- **Evidence**: FR-027 mandates dartdoc comments for all public APIs, FR-028 requires usage examples
- **Validation**: Phase 1 quickstart.md will provide comprehensive developer guide

### VII. Simplicity & Pragmatism ✅ **PASS**
- **Requirement**: KISS principle, SOLID design, avoid over-engineering
- **Status**: Feature uses simplest effective solution
- **Evidence**:
  - Single-purpose components: ChartScrollbar (widget), ScrollbarController (transformations), ScrollbarConfig (configuration)
  - Reuses existing systems: ViewportState, InteractionConfig, ChartTheme
  - Dual-purpose handle (pan + zoom) simpler than separate controls
  - O(1) calculations (simple ratio math) vs complex algorithms
- **Alternative Rejected**: Separate pan/zoom controls would increase UI complexity and cognitive load without benefit

**OVERALL STATUS**: ✅ **CONSTITUTIONAL COMPLIANCE CONFIRMED**  
**GATE RESULT**: **PROCEED TO PHASE 0** - All 7 constitutional principles satisfied

## Project Structure

### Documentation (this feature)

```
specs/010-dual-purpose-scrollbars/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification (already created)
├── checklists/
│   ├── requirements.md  # Quality validation checklist (already created)
│   └── scrollbar-samples.png  # UI reference images (user-provided)
├── research.md          # Phase 0 output (to be generated)
├── data-model.md        # Phase 1 output (to be generated)
├── quickstart.md        # Phase 1 output (to be generated)
├── contracts/           # Phase 1 output (to be generated)
│   ├── chart_scrollbar.dart
│   ├── scrollbar_controller.dart
│   ├── scrollbar_config.dart
│   └── scrollbar_theme.dart
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/src/
├── widgets/
│   ├── braven_chart.dart            # Existing (modified to add scrollbar layout)
│   ├── chart_scrollbar.dart         # NEW - Main scrollbar widget
│   └── scrollbar_handle.dart        # NEW - Handle component (internal)
├── interaction/
│   ├── interaction_config.dart      # Existing (modified for scrollbar callbacks)
│   └── scrollbar_controller.dart    # NEW - Gesture-to-viewport transformations
├── theming/
│   ├── chart_theme.dart             # Existing (modified to add scrollbarTheme field)
│   ├── components/
│   │   └── scrollbar_theme.dart     # NEW - Scrollbar styling component
│   └── themes/
│       └── predefined_themes.dart   # Existing (modified for ScrollbarTheme defaults)
├── coordinates/
│   └── viewport_state.dart          # Existing (no changes - uses existing withRanges())
└── models/
    └── scrollbar_config.dart        # NEW - Configuration data class

test/
├── contract/
│   └── widgets/
│       ├── chart_scrollbar_contract_test.dart     # NEW - TDD contract test
│       └── scrollbar_controller_contract_test.dart # NEW - TDD contract test
├── unit/
│   ├── widgets/
│   │   └── chart_scrollbar_test.dart              # NEW - Unit tests
│   ├── interaction/
│   │   └── scrollbar_controller_test.dart         # NEW - Unit tests
│   └── theming/
│       └── scrollbar_theme_test.dart              # NEW - Unit tests
├── integration/
│   └── scrollbar_interaction_test.dart            # NEW - Integration tests
└── golden/
    └── scrollbar_visual_test.dart                 # NEW - Golden image tests

docs/
└── guides/
    └── scrollbar-usage.md           # NEW - User guide (from quickstart.md)
```

**Structure Decision**: Single Flutter library structure (default for Braven Charts). New scrollbar components integrate into existing layer structure:
- **Layer 007 (Widgets)**: ChartScrollbar widget, ScrollbarHandle component
- **Layer 007 (Interaction)**: ScrollbarController for transformations
- **Layer 004 (Theming)**: ScrollbarTheme, ScrollbarConfig for styling
- **Layer 003 (Coordinates)**: Integration via existing ViewportState.withRanges() - no new code in this layer

This structure maintains architectural layering (theming → coordinates → interaction → widgets) and follows existing patterns for component organization.

## Complexity Tracking

*No constitutional violations - this section is not applicable.*

---

## Phase 0: Outline & Research

**Status**: ✅ COMPLETE (2025-01-20)  
**Outputs** (generated):
- ✅ [`research.md`](./research.md) - 7 technical decisions documented with alternatives considered
- ✅ Updated plan.md with comprehensive research findings

### Research Questions to Resolve

Based on RESEARCH.md analysis (1490 lines), the following technical decisions have been documented and require consolidation into research.md:

#### 1. ValueNotifier Pattern for Drag State Management ✅ RESOLVED (Constitutional)

**Decision**: Use ValueNotifier<ScrollbarState> + ValueListenableBuilder for scrollbar drag state

**Rationale**:
- Constitution II mandates ValueNotifier for >10Hz updates
- Scrollbar drag generates 100+ pointer events per second
- Prevents setState-induced crashes (box.dart:3345, mouse_tracker.dart:199)
- Granular rebuild control: only handle visual updates, not entire chart
- Proven pattern from Layer 008 (ValueNotifier Architecture Refactor)

**Alternatives Considered**:
1. **setState** - REJECTED: Violates Constitution II, causes catastrophic crashes during pointer events
2. **StatefulWidget without ValueNotifier** - REJECTED: Same setState issues
3. **InheritedWidget** - REJECTED: Over-engineered for single widget scope

**Implementation Pattern**:
```dart
// Scrollbar widget state
late ValueNotifier<ScrollbarState> _scrollbarStateNotifier;

@override
void initState() {
  super.initState();
  _scrollbarStateNotifier = ValueNotifier(ScrollbarState.initial());
}

void _onDragUpdate(DragUpdateDetails details) {
  // Direct value update, no setState
  _scrollbarStateNotifier.value = _scrollbarStateNotifier.value.copyWith(
    handlePosition: newPosition,
    isDragging: true,
  );
}

@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<ScrollbarState>(
    valueListenable: _scrollbarStateNotifier,
    builder: (context, state, child) {
      return CustomPaint(painter: ScrollbarPainter(state));
    },
  );
}
```

#### 2. Handle Position/Size Calculations ✅ RESOLVED

**Decision**: O(1) ratio-based formulas for handle geometry

**Formulas** (from RESEARCH.md lines 334-370):
```dart
// Handle size = visible percentage
double handleSize = (viewportRange / dataRange) * trackSize;

// Handle position = offset percentage (accounting for handle size)
double handlePosition = ((viewportMin - dataMin) / (dataMax - dataMin)) 
                        * (trackSize - handleSize);

// Reverse: Handle position → viewport range
double offsetRatio = handlePosition / (trackSize - handleSize);
double visibleRatio = handleSize / trackSize;
double dataSpan = dataMax - dataMin;
double viewportSpan = dataSpan * visibleRatio;
double viewportMin = dataMin + (dataSpan * offsetRatio);
double viewportMax = viewportMin + viewportSpan;
```

**Performance**: <0.1ms per calculation (verified in similar coordinate transforms in Layer 003)

#### 3. Coordinate System Independence ✅ RESOLVED (Critical Constraint)

**Decision**: Scrollbar layout MUST NOT affect TransformContext.chartAreaBounds

**Strategy** (from RESEARCH.md lines 384-445):
- Separate layout regions (Column/Row structure)
- Scrollbar uses Flutter RenderBox coordinates, no access to TransformContext
- Updates flow through ViewportState.withRanges(), not coordinate system modification
- Validation: chartAreaBounds always calculated from canvas size, never from scrollbar

**Layout Integration**:
```dart
Column(
  children: [
    Expanded(
      child: Row(
        children: [
          Expanded(child: ChartCanvas(...)),  // TransformContext here
          if (showYScrollbar) ChartScrollbar(axis: Axis.vertical),
        ],
      ),
    ),
    if (showXScrollbar) ChartScrollbar(axis: Axis.horizontal),
  ],
)
```

#### 4. Interaction Zone Hit Testing ✅ RESOLVED

**Decision**: Three hit zones with cursor changes (edges, center, track)

**Zones** (from RESEARCH.md lines 301-330):
1. **Left/Top Edge** (8px wide): Resize by adjusting minimum, cursor: ↔/↕
2. **Right/Bottom Edge** (8px wide): Resize by adjusting maximum, cursor: ↔/↕
3. **Center Area**: Drag to pan (no resize), cursor: ✋ (grab)
4. **Track (outside handle)**: Click to jump viewport, cursor: 👆 (pointer)

**Implementation**:
```dart
HitTestZone _getHitZone(Offset localPosition) {
  if (isInLeftEdge(localPosition, edgeGripWidth: 8.0)) {
    return HitTestZone.leftEdge;
  } else if (isInRightEdge(localPosition, edgeGripWidth: 8.0)) {
    return HitTestZone.rightEdge;
  } else if (isInHandleCenter(localPosition)) {
    return HitTestZone.center;
  } else {
    return HitTestZone.track;
  }
}
```

#### 5. Theming Integration ✅ RESOLVED

**Decision**: Extend ChartTheme with ScrollbarTheme component (follows existing Layer 004 patterns)

**Structure** (from RESEARCH.md lines 606-685):
```dart
class ChartTheme {
  // ... existing 6 component themes
  final ScrollbarTheme scrollbarTheme;  // NEW - 7th component theme
}

class ScrollbarTheme {
  final ScrollbarConfig xAxisScrollbar;
  final ScrollbarConfig yAxisScrollbar;
  
  static const ScrollbarTheme defaultLight = ScrollbarTheme(...);
  static const ScrollbarTheme defaultDark = ScrollbarTheme(...);
}

class ScrollbarConfig {
  final double thickness;            // 12.0 default
  final double minHandleSize;        // 20.0 minimum
  final Color trackColor;
  final Color handleColor;
  final Color handleHoverColor;
  final Color handleActiveColor;
  final double borderRadius;         // 4.0 default
  final double edgeGripWidth;        // 8.0 default
  final bool showGripIndicator;
  final bool autoHide;
  final Duration autoHideDelay;      // 2 seconds default
  final bool enableResizeHandles;
  final double minZoomRatio;         // 0.01 (1% minimum visible)
  final double maxZoomRatio;         // 1.0 (100% maximum)
}
```

**Integration**: Follows same pattern as existing GridStyle, AxisStyle, SeriesTheme components

#### 6. Accessibility Requirements ✅ RESOLVED

**Decision**: WCAG 2.1 AA compliance with keyboard navigation and screen readers

**Requirements** (from RESEARCH.md lines 686-760):

1. **Contrast Ratios**:
   - Track vs Handle: Minimum 3:1
   - Handle vs Background: Minimum 4.5:1
   - Active state: Minimum 3:1 vs normal

2. **Keyboard Navigation**:
   - Tab: Focus scrollbar
   - Arrow keys: Pan (5% of visible range increments)
   - Shift + Arrow keys: Pan faster (25% of visible range)
   - Ctrl/Cmd + Arrow keys: Zoom (±10% zoom level)
   - Home/End: Jump to start/end of data
   - Page Up/Down: Jump by full viewport width

3. **Semantics**:
```dart
Semantics(
  label: 'Chart X-axis scrollbar',
  hint: 'Drag to pan, drag edges to zoom, use arrow keys to navigate',
  value: 'Showing data from ${viewport.min} to ${viewport.max}, ${percent}% of total',
  onIncrease: () => _panRight(),
  onDecrease: () => _panLeft(),
  child: scrollbarWidget,
)
```

#### 7. Performance Optimization Strategy ✅ RESOLVED

**Decision**: Independent rendering + throttling + RepaintBoundary isolation

**Strategies** (from RESEARCH.md lines 761-810):

1. **Independent Rendering**:
   - Scrollbar renders in separate CustomPainter (RepaintBoundary wrapped)
   - Chart canvas only re-renders when viewport changes (not during drag preview)
   - Use onEnd callback to finalize viewport (not onUpdate for every frame)

2. **Gesture Throttling**:
   - Throttle viewport updates during rapid drag (max 60 updates/sec)
   - Batch multiple small drags into single viewport update
   - Visual feedback immediate (handle position updates), data updates throttled

3. **Layout Optimization**:
   - Scrollbar size fixed during chart lifetime
   - Handle position calculated in O(1) time
   - No data queries during drag (use cached DataRange)

**Performance Targets**:
- Handle position calculation: <0.1ms (O(1) ratio math)
- Scrollbar render (CustomPainter): <1ms
- Viewport update + chart re-render: <16ms (full 60 FPS budget)
- Memory overhead: <100KB for both scrollbars

### Unknowns Remaining

**None** - All critical technical decisions documented in RESEARCH.md and consolidated above. Research phase complete, ready to generate formal research.md artifact.

### Next Steps for Phase 0 Completion

1. **Generate research.md** - Consolidate above decisions into formal research document with Decision/Rationale/Alternatives format
2. **Update plan.md** - Mark Phase 0 as COMPLETE
3. **Proceed to Phase 1** - Generate data-model.md, contracts/, and quickstart.md

---

## Phase 1: Design & Contracts

**Status**: ✅ COMPLETE (2025-01-20)  
**Outputs** (generated):
- ✅ [`data-model.md`](./data-model.md) - 7 entities documented with relationships, state transitions, validation rules
- ✅ [`contracts/`](./contracts/) - 4 API contract files with comprehensive documentation
  - ✅ `chart_scrollbar.dart` - ChartScrollbar widget API
  - ✅ `scrollbar_controller.dart` - ScrollbarController pure functions + HitTestZone enum
  - ✅ `scrollbar_config.dart` - ScrollbarConfig configuration class
  - ✅ `scrollbar_theme.dart` - ScrollbarTheme component theme
- ✅ [`quickstart.md`](./quickstart.md) - Developer onboarding guide with 8 sections, 4 common patterns, troubleshooting

### Entities to Document (data-model.md)

Based on spec.md Key Entities section and RESEARCH.md technical design:

1. **ChartScrollbar** (StatefulWidget)
   - Purpose: Main scrollbar widget with dual-purpose handle
   - Fields: axis, dataRange, viewportRange, onViewportChanged, scrollbarConfig
   - State: ValueNotifier<ScrollbarState> for drag management
   - Lifecycle: initState() creates notifier, dispose() cleans up

2. **ScrollbarState** (Immutable Value Object) - NEW
   - Purpose: Represents current scrollbar interaction state
   - Fields: isDragging, isResizing, resizeEdge, handlePosition, handleSize, isHovered
   - Pattern: copyWith() for immutable updates
   - Used by: ValueNotifier<ScrollbarState> for reactive UI

3. **ScrollbarController** (Pure Functions Class)
   - Purpose: Translate gestures to viewport transformations
   - Methods: handlePositionToDataRange(), dataRangeToHandlePosition(), handleDrag(), handleResize()
   - Pattern: Static utility class, no state
   - Used by: ChartScrollbar for coordinate calculations

4. **ScrollbarConfig** (Immutable Data Class)
   - Purpose: Configuration for scrollbar appearance and behavior
   - Fields: thickness, minHandleSize, colors, borderRadius, edgeGripWidth, autoHide settings, zoom constraints
   - Pattern: Immutable with const constructor
   - Used by: ScrollbarTheme, ChartScrollbar

5. **ScrollbarTheme** (Immutable Data Class)
   - Purpose: Theme component for scrollbar styling
   - Fields: xAxisScrollbar (ScrollbarConfig), yAxisScrollbar (ScrollbarConfig)
   - Integration: Added to ChartTheme as 7th component theme
   - Predefined: defaultLight, defaultDark

6. **ViewportState** (Existing - Integration Point)
   - Purpose: Immutable viewport state tracking visible data range
   - Integration: withRanges(DataRange x, DataRange y) method used for scrollbar updates
   - No Changes: Existing implementation sufficient

7. **InteractionConfig** (Existing - Integration Point)
   - Purpose: Configuration for chart interaction behaviors
   - Integration: enablePan, enableZoom properties control scrollbar behavior
   - Callbacks: onPanChanged, onZoomChanged fired when scrollbar interactions complete

### Contracts to Define (contracts/)

1. **chart_scrollbar.dart** - ChartScrollbar widget public API
2. **scrollbar_controller.dart** - ScrollbarController transformation methods
3. **scrollbar_config.dart** - ScrollbarConfig configuration data class
4. **scrollbar_theme.dart** - ScrollbarTheme theme component integration

### Quickstart Content (quickstart.md)

Developer guide covering:
- Basic scrollbar addition to chart
- Configuration customization (colors, sizes, behavior)
- Theming integration with ChartTheme
- Accessibility setup (keyboard navigation, screen readers)
- Performance optimization tips
- Common patterns and gotchas

---

## Notes

**Constitutional Compliance Critical**: The ValueNotifier pattern is MANDATORY for this feature (Constitution v1.1.0 Performance First principle). Scrollbar drag operations generate 100+ pointer events per second, making this a textbook case for the constitutional requirement. Any attempt to use setState will result in catastrophic crashes (box.dart:3345, mouse_tracker.dart:199) as documented in the constitution's expanded Performance First section.

**Architecture Integration**: This feature seamlessly integrates with existing Braven Charts architecture:
- Layer 003 (Coordinate System): ViewportState.withRanges() - no modifications needed
- Layer 004 (Theming System): ScrollbarTheme extends ChartTheme - follows existing component theme pattern
- Layer 007 (Interaction System): InteractionConfig callbacks - uses existing interaction patterns
- Layer 007 (Widgets): ChartScrollbar widget - follows existing widget patterns (CustomPainter, GestureDetector)

**Testing Strategy**: TDD contract tests will be established in Phase 0 before any implementation:
- Contract tests for ChartScrollbar widget API
- Contract tests for ScrollbarController transformations
- Unit tests for calculations (handle position, viewport ranges)
- Integration tests for gesture handling (drag, resize, click-to-jump)
- Golden tests for visual regression (scrollbar rendering, themes)
- Performance tests for 60 FPS validation during drag operations

