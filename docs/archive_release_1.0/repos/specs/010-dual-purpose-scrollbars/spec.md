# Feature Specification: Dual-Purpose Chart Scrollbars

**Feature Branch**: `010-dual-purpose-scrollbars`  
**Created**: 2025-10-24  
**Status**: Draft  
**Input**: User description: "010-scrollbars - Detail of new feature is here: `docs\specs\010-scrollbars\research.md`"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Navigate Large Dataset with Visual Feedback (Priority: P1)

A data analyst is exploring a time-series dataset with 50,000 data points spanning multiple years. They need to understand where they are in the dataset while viewing a zoomed-in portion showing only 500 points (1% of data). They want immediate visual feedback showing their position within the full dataset without losing context of what they're examining.

**Why this priority**: This is the core value proposition - providing spatial awareness during navigation. Without this, users are "lost" when zoomed in on large datasets. This foundational capability enables all other scrollbar interactions.

**Independent Test**: Can be fully tested by zooming into any chart until viewport shows less than 100% of data, then verifying that scrollbars appear showing proportionally-sized handles that represent the visible percentage. Delivers immediate value by answering "where am I in this data?"

**Acceptance Scenarios**:

1. **Given** a chart displaying 10,000 data points with current viewport showing all data, **When** user zooms in to show only 1,000 points (10% visible), **Then** horizontal scrollbar appears with handle occupying 10% of scrollbar track length
2. **Given** a chart with viewport showing 25% of X-axis data and 50% of Y-axis data, **When** chart renders, **Then** X-scrollbar shows 25%-width handle and Y-scrollbar shows 50%-height handle
3. **Given** a chart with viewport showing 100% of data (no zoom or pan), **When** chart renders, **Then** scrollbars are hidden (not displayed)
4. **Given** scrollbar is displaying with handle at 30% position along track, **When** user visually inspects chart data, **Then** data shown corresponds to middle section of full dataset (viewport positioned at 30% offset)

---

### User Story 2 - Pan Through Data via Scrollbar (Priority: P1)

A financial analyst reviewing stock price data needs to move quickly through different time periods. Rather than dragging the chart data itself (which can trigger unwanted interactions with data points), they want to drag the scrollbar handle to smoothly pan through the timeline while maintaining their current zoom level.

**Why this priority**: Pan capability is equally critical as visual feedback - users need both to see where they are AND navigate efficiently. This is standard scrollbar behavior users expect, making it essential for MVP.

**Independent Test**: Can be fully tested by dragging the scrollbar handle and verifying the chart viewport pans accordingly while zoom level remains constant. Delivers standalone value for efficient navigation without touching chart data.

**Acceptance Scenarios**:

1. **Given** horizontal scrollbar showing handle at left edge (0% position), **When** user drags handle to center of track (50% position), **Then** chart viewport pans to show middle section of data (viewport.xRange.min at 50% of data range)
2. **Given** user is dragging scrollbar handle, **When** drag motion continues beyond data boundaries, **Then** handle stops at track edge (no overscroll) and viewport clamps to data limits
3. **Given** scrollbar handle positioned at 40% along track, **When** user clicks scrollbar track at 70% position, **Then** handle jumps to 70% position and viewport immediately updates to show that data section
4. **Given** user drags vertical scrollbar handle from top to bottom, **When** drag completes, **Then** chart viewport pans vertically showing progression from lowest Y-values to highest Y-values
5. **Given** chart has both X and Y scrollbars visible, **When** user drags X-scrollbar, **Then** only horizontal viewport changes (Y-axis viewport remains unchanged)

---

### User Story 3 - Zoom via Scrollbar Handle Resize (Priority: P2)

A researcher analyzing scientific measurements wants to zoom into specific data ranges without using mouse wheel or pinch gestures. They want to grab the edges of the scrollbar handle and resize it - making it smaller to zoom in (show less data in more detail) or larger to zoom out (show more data with less detail). This provides precise, visual control over the zoom level.

**Why this priority**: While critical for the "dual-purpose" innovation, this can be delivered after basic scrollbar pan functionality. Users can initially use existing zoom methods (mouse wheel) while scrollbar provides pan + visual feedback. Resize capability is the differentiator but not blocking for basic navigation.

**Independent Test**: Can be fully tested by dragging scrollbar handle edges and verifying chart zoom changes while opposite edge remains anchored. Delivers unique value by providing visual, direct-manipulation zoom control that's more intuitive than mouse wheel for precise range selection.

**Acceptance Scenarios**:

1. **Given** horizontal scrollbar with 50%-width handle (showing 50% of data), **When** user drags right edge of handle leftward reducing handle to 25% width, **Then** chart zooms in to show only 25% of data range with left boundary fixed at original position
2. **Given** scrollbar handle showing data range from 30% to 60% (30% width), **When** user drags left edge rightward to 40% position, **Then** viewport zooms to show data from 40% to 60% (right edge anchored, zoom-in on left side)
3. **Given** scrollbar handle at minimum allowed size (e.g., 20px representing 1% of data), **When** user attempts to drag edge to shrink further, **Then** handle size remains at minimum and cursor changes to indicate zoom limit reached
4. **Given** user hovers over left or right edge of scrollbar handle, **When** cursor enters 8px edge zone, **Then** cursor changes to horizontal resize arrows (↔) indicating resize capability
5. **Given** chart interaction configuration has enableZoom set to false, **When** scrollbar renders, **Then** handle edges are not interactive (no resize cursors, no resize on drag)

---

### User Story 4 - Keyboard Navigation for Accessibility (Priority: P3)

A user with motor disabilities or a power user preferring keyboard shortcuts needs to navigate the chart without using a mouse. They want to tab to focus the scrollbar, then use arrow keys to pan incrementally, Page Up/Down to jump by viewport width, and Home/End to jump to data boundaries.

**Why this priority**: Essential for accessibility compliance and power users, but can be delivered after core mouse-based interactions are stable. Basic chart functionality works without keyboard scrollbar control as long as other keyboard navigation methods exist.

**Independent Test**: Can be fully tested using only keyboard inputs - Tab to focus, arrow keys to verify pan, Page Up/Down to verify jumps. Delivers accessibility value independently of mouse interactions.

**Acceptance Scenarios**:

1. **Given** chart is displayed with scrollbar, **When** user presses Tab key, **Then** scrollbar receives keyboard focus with visible focus indicator (2px outline)
2. **Given** horizontal scrollbar has keyboard focus, **When** user presses Right Arrow key, **Then** viewport pans right by 5% of visible range (incremental pan)
3. **Given** scrollbar has focus, **When** user presses Page Down key, **Then** viewport pans by 100% of current viewport width (one full screen of data)
4. **Given** vertical scrollbar has focus at top position, **When** user presses End key, **Then** viewport jumps to show bottom section of data (handle at bottom of scrollbar)
5. **Given** scrollbar has keyboard focus, **When** screen reader is active, **Then** screen reader announces "Chart X-axis scrollbar, showing 25% of data from position 30% to 55%, use arrow keys to pan"

---

### User Story 5 - Themed Scrollbar Appearance (Priority: P3)

A UI designer creating a dashboard wants scrollbars to match the visual theme of their application (corporate blue, dark mode, high contrast for accessibility). They need scrollbars to automatically adapt to the chart theme without manual color configuration, using the existing theming system.

**Why this priority**: Important for polish and brand consistency, but doesn't affect functionality. Can be delivered last after core interactions are proven. Default appearance is acceptable for MVP.

**Independent Test**: Can be fully tested by applying different ChartTheme instances and verifying scrollbar colors update accordingly. Delivers aesthetic value independently of interaction features.

**Acceptance Scenarios**:

1. **Given** chart uses ChartTheme.defaultDark theme, **When** scrollbar renders, **Then** scrollbar track uses dark background color and handle uses light contrasting color (minimum 4.5:1 contrast ratio)
2. **Given** chart uses ChartTheme.highContrast theme, **When** user hovers over scrollbar handle, **Then** handle color changes to high-contrast hover state (minimum 3:1 contrast vs normal state)
3. **Given** developer specifies custom ScrollbarTheme with thickness: 12.0, **When** scrollbar renders, **Then** scrollbar width (for vertical) or height (for horizontal) is exactly 12.0 pixels

- **Given** chart uses ChartTheme.minimal theme, **When** scrollbar renders, **Then** scrollbar track has 0.1 opacity (nearly transparent) showing only on hover, handle uses theme primary color

---

### Edge Cases

- **What happens when dataset is empty or has only one data point?**  
  Scrollbars should be hidden entirely (no data range to navigate). System gracefully handles DataRange with min == max by treating viewport as 100% visible.

- **What happens when handle size would be less than minimum size (e.g., <20px)?**  
  Handle is clamped to minHandleSize (default 20px). Position calculations compensate for this constraint - user can still pan through entire dataset, but handle won't shrink below minimum for usability.

- **What happens when user rapidly drags scrollbar during active chart animation?**  
  Viewport updates are throttled to 60 FPS maximum. Chart animation pauses during scrollbar interaction, resumes when drag ends. No competing animations to prevent visual conflict. If user initiates new scrollbar interaction while previous animation is running, the active animation cancels immediately (0ms) and new interaction takes precedence - no animation queueing or overlap.

- **What happens when viewport is programmatically updated (not by scrollbar)?**  
  Scrollbar reactively updates handle position/size to reflect new ViewportState. System prevents infinite update loops by comparing old vs new viewport before triggering changes.

- **What happens when chart is resized (e.g., window resize, container resize)?**  
  Scrollbar track size recalculates, handle position/size adjust proportionally to maintain same data range visibility. No change to viewport data range, only visual proportions update.

- **What happens when user drags both X and Y scrollbars simultaneously (multi-touch)?**  
  Each scrollbar independently updates its axis dimension. ViewportState merges both updates atomically to prevent partial state updates.

- **How does system handle floating-point precision errors in position calculations?**  
  All calculations use double precision. Position-to-range conversions clamp results to valid data boundaries. Cumulative errors reset on drag end by snapping to calculated range values.

- **What happens when InteractionConfig.enablePan is false but scrollbar is configured?**  
  Scrollbar renders in read-only mode - handle shows current position/zoom but is not draggable. Only resize interactions (zoom) are enabled if enableZoom is true.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST display horizontal scrollbar when viewport X-range is smaller than full data X-range (zoom factor > 1.0 or panning active on X-axis)

- **FR-002**: System MUST display vertical scrollbar when viewport Y-range is smaller than full data Y-range (zoom factor > 1.0 or panning active on Y-axis)

- **FR-003**: System MUST hide scrollbars when viewport shows 100% of data in both dimensions (no zoom, no pan, viewport == data range)

- **FR-004**: Scrollbar handle size MUST represent visible percentage of data using formula: `handleSize = (viewportRange / dataRange) * trackLength` where all measurements are in consistent units

- **FR-005**: Scrollbar handle position MUST represent viewport offset within data using formula: `handlePosition = (viewportMin - dataMin) / (dataMax - dataMin) * (trackLength - handleSize)` with clamping to [0, trackLength - handleSize]

- **FR-006**: Users MUST be able to drag scrollbar handle center to pan viewport (scroll through data) while maintaining current zoom level. Handle position updates immediately during drag (no animation) with sub-frame latency (<16ms) to maintain direct manipulation feel.

- **FR-007**: Users MUST be able to click scrollbar track (outside handle) to jump viewport to that position, with handle animating to clicked position over 300ms using ease-out curve (Curves.easeOut in Flutter). All scrollbar animations (hover transitions, focus transitions, active state transitions) MUST use ease-in-out curve (Curves.easeInOut) for smooth, natural motion.

- **FR-008**: Users MUST be able to drag left/top edge of scrollbar handle to zoom by adjusting viewport minimum while keeping maximum fixed (anchor right/bottom). Edge interaction zone is defined as 8.0 logical pixels from handle boundary (per US3-AS4), with resize cursor (↔ or ↕) appearing when cursor enters this zone.

- **FR-009**: Users MUST be able to drag right/bottom edge of scrollbar handle to zoom by adjusting viewport maximum while keeping minimum fixed (anchor left/top). Edge interaction zone is defined as 8.0 logical pixels from handle boundary (per US3-AS4), with resize cursor (↔ or ↕) appearing when cursor enters this zone.

- **FR-010**: System MUST enforce minimum handle size (default 20px, configurable) to maintain usability, adjusting position calculations to compensate when theoretical handle size would be smaller. Visual clipping/overflow behavior: handle is always rendered fully within scrollbar track bounds - no partial rendering or overflow outside track area.

- **FR-011**: System MUST enforce maximum zoom ratio (default 100x, configurable) by preventing handle resize beyond minimum percentage of track length. When user attempts to resize handle beyond maximum zoom limit, handle size clamps at minimum and cursor changes to 'not-allowed', with handle flashing once (opacity 0.8 → 0.4 → 0.8 over 200ms) to indicate zoom limit reached.

- **FR-012**: System MUST enforce minimum zoom ratio (default 0.1x, configurable) by preventing handle resize beyond maximum percentage of track length

- **FR-013**: Scrollbar MUST respect data boundaries - panning cannot move viewport outside [dataMin, dataMax] range (no overscroll)

- **FR-014**: Scrollbar interactions MUST update ViewportState via onViewportChanged callback, using ViewportState.withRanges() method to create new immutable state

- **FR-015**: Scrollbar rendering MUST NOT modify TransformContext.chartAreaBounds - scrollbar must render in separate layout region outside chart canvas. Scrollbar stacking order (z-index) MUST place scrollbar above chart canvas elements (data points, lines, axes) but below interactive overlays (tooltips, context menus) to prevent obscuring critical UI.

- **FR-015A**: When both X-axis and Y-axis scrollbars are visible simultaneously, the bottom-right corner MUST handle overlap with the following specification:
  - Corner area (12.0px × 12.0px square where scrollbars meet) renders as neutral background matching chart container
  - X-axis scrollbar track extends to right edge of chart canvas (not shortened for Y-scrollbar)
  - Y-axis scrollbar track extends to bottom edge of chart canvas (not shortened for X-scrollbar)
  - Both scrollbar tracks render with 0.5 opacity in overlap area to show both tracks visually
  - No gap between scrollbars - seamless corner appearance

- **FR-016**: Scrollbar MUST work independently on X and Y axes - dragging one scrollbar only updates that axis dimension in ViewportState

- **FR-017**: Scrollbar MUST respect InteractionConfig.enablePan - when false, handle center is not draggable (read-only position indicator)

- **FR-018**: Scrollbar MUST respect InteractionConfig.enableZoom - when false, handle edges are not draggable (no resize capability)

- **FR-019**: Scrollbar MUST fire InteractionConfig.onPanChanged callback when handle drag completes (onDragEnd) with delta offset

- **FR-020**: Scrollbar MUST fire InteractionConfig.onZoomChanged callback when handle resize completes (onDragEnd) with zoom ratio change

- **FR-021**: Scrollbar MUST display cursor changes: resize arrows (↔ or ↕) for edges, grab hand for center, pointer for track, with cursor updates occurring immediately (<16ms) on hover zone changes

- **FR-021A**: Scrollbar handle MUST define visual states with the following specifications:
  - **Default/Idle state**: Handle uses base color from FR-025 (opacity 0.6 for light theme), no border, corner radius 4.0px
  - **Hover state**: Handle opacity increases to 0.7 (light theme) or 0.8 (dark theme), maintaining 4.5:1 contrast ratio vs track; transition occurs over 150ms with ease-in-out curve
  - **Active/Dragging state**: Handle opacity increases to 0.8 (light theme) or 0.9 (dark theme), handle scales to 1.05x size with box-shadow (2px blur, opacity 0.3) for depth; transition occurs immediately (<16ms)
  - **Disabled state** (when enablePan = false and enableZoom = false): Handle opacity reduces to 0.3, converted to greyscale filter, cursor changes to 'not-allowed'; no hover or active transitions occur

- **FR-021B**: Scrollbar track MUST define hover state: Track opacity increases from 0.2 to 0.3 when cursor hovers over track area (not handle), transitioning over 150ms with ease-in-out curve, to indicate click-to-jump interactivity

- **FR-021C**: Scrollbar interaction state transitions MUST be consistent across both horizontal (X-axis) and vertical (Y-axis) scrollbars - same opacity values, timing, easing curves, and visual effects apply to both orientations

- **FR-021D**: Scrollbar touch interface requirements:
  - Touch targets MUST meet 44x44 logical pixel minimum (see FR-024A for implementation)
  - Cursor changes are not applicable on touch devices - visual states (hover, active) still apply on touch
  - Touch hover is interpreted as press-and-hold for 300ms, then activates hover state visual feedback
  - All drag interactions (pan, resize) work identically on touch as mouse - no separate touch gesture recognition required

- **FR-022**: Scrollbar MUST support keyboard navigation with the following specifications:
  - **Tab to focus**: First Tab focuses X-axis scrollbar (if visible), second Tab focuses Y-axis scrollbar (if visible)
  - **Arrow keys to pan**: Left/Right (X-axis) or Up/Down (Y-axis) pan by 5% of current viewport range per key press
  - **Page Up/Down to jump**: Pan by 100% of current viewport (one full screen) per key press
  - **Home/End to boundaries**: Jump to start (0% position) or end (100% position) of data range
  - **Visual feedback**: Handle position animates smoothly (300ms, ease-out curve) during keyboard pan/jump operations
  - **Focus consistency**: Focus indicator appearance (2px outline, color, timing) is identical for both X and Y scrollbars

- **FR-023**: Scrollbar MUST provide semantic labels for accessibility: "Chart [X/Y]-axis scrollbar" with dynamic state announcements (position, visible percentage)

- **FR-024**: Scrollbar MUST display visible focus indicator (minimum 2px outline, high-contrast color with 4.5:1 contrast ratio vs background) when focused via keyboard navigation, with focus outline transitioning in over 150ms using ease-in-out curve

- **FR-024A**: Scrollbar handle MUST provide minimum 44x44 logical pixel touch target size for mobile/tablet devices (WCAG 2.5.5 compliance). When handle visual size is smaller than 44x44, invisible hit-test padding expands the interactive area to meet minimum size while maintaining visual appearance.

- **FR-024B**: Scrollbar MUST support Windows High Contrast Mode by:
  - Detecting forced colors via MediaQuery.platformBrightness and system accessibility settings
  - Using system colors: SystemColors.buttonFace for track, SystemColors.buttonText for handle
  - Adding 2px solid border (SystemColors.windowText) around handle for definition when background contrast is insufficient
  - Disabling opacity/transparency effects - all colors rendered at 100% opacity

- **FR-024C**: Scrollbar animations MUST respect reduced motion preferences (WCAG 2.3.3 compliance) by:
  - Detecting prefers-reduced-motion via MediaQuery.disableAnimations
  - Disabling all animation transitions (FR-007 click-to-jump, FR-021A hover/active states, FR-024 focus transitions) when preference is active
  - Using immediate state changes (0ms duration) instead of animated transitions
  - Maintaining all functionality - only animation timing changes, not behavior

- **FR-025**: Scrollbar appearance MUST adapt to ChartTheme via ScrollbarTheme configuration with the following specifications:
  - **Thickness**: Default 12.0 logical pixels (vertical scrollbar width, horizontal scrollbar height)
  - **Track dimensions**: Horizontal scrollbar height = thickness, width = chart canvas width; Vertical scrollbar width = thickness, height = chart canvas height
  - **Corner radius**: Default 4.0 logical pixels for both track and handle (Material Design standard)
  - **Padding**: Default 4.0 logical pixels between scrollbar and chart canvas boundaries
  - **Track visual**: Semi-transparent background (default opacity 0.2) with subtle border (1px, opacity 0.3) for definition
  - **Handle visual**: Solid color (theme-dependent) with 4.5:1 minimum contrast ratio vs track background, 2px corner radius smaller than track for visual nesting
  - **Color specifications**:
    - Light theme: Track `Color(0x33000000)` (black at 20% opacity), Handle `Color(0x99000000)` (black at 60% opacity)
    - Dark theme: Track `Color(0x33FFFFFF)` (white at 20% opacity), Handle `Color(0x99FFFFFF)` (white at 60% opacity)
    - High-contrast theme: Track `Color(0xFF000000)` (solid black) or `Color(0xFFFFFFFF)` (solid white), Handle `Color(0xFFFFFF00)` (yellow) or `Color(0xFF00FFFF)` (cyan) with 7:1 contrast ratio

- **FR-026**: Scrollbar MUST maintain 60 FPS performance during drag interactions (maximum 16.67ms frame time)

- **FR-027**: Scrollbar handle position calculations MUST complete in <0.1ms (O(1) complexity, no data iteration)

- **FR-028**: Scrollbar MUST render using RepaintBoundary to isolate repaints from chart canvas (scrollbar drag does not trigger chart re-render unless viewport changes)

### Key Entities

- **ChartScrollbar**: Widget component representing the entire scrollbar (track + handle + interaction zones). Contains axis orientation (horizontal/vertical), data range, viewport range, callbacks for viewport changes, and configuration. Renders outside chart canvas in dedicated layout region.

- **ScrollbarHandle**: Visual and interactive component representing the visible viewport within full data range. Has position (offset from track start), size (length along track), and interaction zones (left/right or top/bottom edges for resize, center for drag). Position and size are calculated from viewport-to-data ratios.

- **ScrollbarController**: State management component that translates gesture events (drag delta, resize delta) into viewport transformations (new DataRange for viewport). Maintains drag state (isDragging, isResizing, resizeEdge), performs position-to-range and range-to-position calculations, enforces constraints (min/max handle size, data boundaries).

- **ScrollbarConfig**: Immutable configuration object defining scrollbar behavior and appearance. Contains thickness, colors (track, handle, hover, active), padding, radius, interaction settings (enableClickToJump, animatePan, panAnimationDuration), size constraints (minHandleSize, minHandlePercent), zoom limits (minZoomRatio, maxZoomRatio).

- **ScrollbarTheme**: Theme configuration for scrollbars integrated into ChartTheme. Contains separate configurations for X-axis and Y-axis scrollbars (ScrollbarConfig instances), default colors that adapt to chart theme (light/dark mode), accessibility settings (contrast ratios, focus indicator styles).

- **ViewportState**: (Existing entity) Immutable state tracking visible data range (xRange, yRange as DataRange), zoom factor, pan offset. Updated by scrollbar via withRanges() method. Consumed by TransformContext for coordinate transformations. Scrollbar reactively displays this state and updates it via callbacks.

- **DataRange**: (Existing entity) Represents a numeric range with min and max values. Used for both full data range (unchanging) and viewport range (changes with zoom/pan). Scrollbar calculates handle position/size from ratio of viewport DataRange to data DataRange.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Users can navigate to any position in a dataset of 100,000+ points in under 3 seconds using scrollbar pan (drag or click-to-jump)

- **SC-002**: Users can visually identify their position within a dataset at a glance - given a scrollbar with handle at 75% position, users correctly identify they are viewing "approximately the last quarter" of data (validated via user testing, 90% accuracy)

- **SC-003**: Scrollbar handle drag maintains 60 FPS (frame time ≤16.67ms) with datasets up to 1,000,000 points on reference hardware (mid-range desktop, 2020 specs)

- **SC-004**: Scrollbar handle resize (zoom) operation provides smoother, more predictable zoom control than mouse wheel - user testing shows 80%+ preference for scrollbar resize over mouse wheel when asked to "zoom to show exactly this specific data range"

- **SC-005**: Scrollbar position/size calculations complete in under 0.1ms (100 microseconds) for any dataset size (validated via benchmark tests, 99th percentile)

- **SC-006**: Chart viewport updates triggered by scrollbar interactions complete in under 16ms (including culling recalculation and re-render) for datasets up to 50,000 visible points

- **SC-007**: Users with motor disabilities can successfully navigate charts using only keyboard within 5 seconds of instruction (Tab to focus, arrows to pan) - validated via accessibility testing with assistive technology users

- **SC-008**: Scrollbar contrast ratios meet WCAG 2.1 AA standards: minimum 4.5:1 for track vs handle, 3:1 for handle normal vs hover/active states (validated via automated contrast checker)

- **SC-009**: Scrollbar appearance automatically adapts to all 7 predefined chart themes without developer intervention - visual consistency verified across defaultLight, defaultDark, corporateBlue, vibrant, minimal, highContrast, colorblindFriendly

- **SC-010**: Scrollbar memory overhead is under 100KB for both X and Y scrollbars combined (measured via Flutter DevTools memory profiler)

- **SC-011**: Developers can integrate scrollbars into existing charts with zero breaking changes to coordinate system - all existing chart rendering tests pass unchanged after scrollbar feature is added

- **SC-012**: Scrollbar handle size remains usable (≥20px) even when viewport shows 0.1% of data (1:1000 zoom ratio), with position calculations compensating for clamped size

- **SC-013**: Scrollbar interactions work correctly on touch devices - handle drag, edge resize, and track tap all function with finger input (tested on tablet with minimum 44px touch targets)

- **SC-014**: 95% of users can successfully zoom to a specific data range using scrollbar handle resize on first attempt without instruction (validated via user testing with think-aloud protocol)

## Assumptions

- Charts using scrollbars have sufficient data density to make scrolling meaningful (minimum 100 data points recommended, though technically works with any count >1)
- Chart container has minimum dimensions to accommodate scrollbar (minimum 200px width/height to allow reasonable scrollbar track length)
- Data ranges are numeric and finite (no NaN, Infinity values in DataRange min/max)
- ViewportState and TransformContext implementations from existing coordinate system (Layer 003) are stable and will not change incompatibly
- InteractionConfig callback signatures (onZoomChanged, onPanChanged, onViewportChanged) will remain stable
- ChartTheme structure supports adding new ScrollbarTheme component without breaking existing theme configurations
- Flutter framework's GestureDetector and CustomPainter APIs remain stable (standard Flutter widgets)
- Scrollbar will initially target desktop and tablet form factors - mobile phone optimization (smaller touch targets) is a future enhancement
- Default scrollbar configuration values (thickness: 12.0 logical pixels, minHandleSize: 20px, etc.) are reasonable for majority of use cases - developers can override via ScrollbarConfig
- Scrollbar rendering occurs after chart data layout is complete (scrollbar depends on knowing full data range and current viewport)

## Dependencies

- **Layer 003 - Coordinate System**: Scrollbar consumes ViewportState and updates it via withRanges(). Requires ViewportState.xRange, yRange, withRanges() method. No modifications to coordinate transformation logic needed.
- **Layer 004 - Theming System**: Scrollbar extends ChartTheme with new ScrollbarTheme component. Requires ability to add optional scrollbarTheme field to ChartTheme without breaking existing themes.
- **Layer 007 - Interaction System**: Scrollbar respects InteractionConfig.enableZoom, enablePan flags and fires onZoomChanged, onPanChanged callbacks. Requires these configuration points remain stable.
- **Flutter Framework**: Depends on GestureDetector for drag detection, CustomPainter for rendering, Semantics for accessibility, LayoutBuilder for responsive sizing.

## Out of Scope

The following are explicitly excluded from this feature specification:

- **Mini-chart navigator** (like Highcharts Navigator showing data preview in scrollbar track) - future enhancement after basic scrollbar proven
- **Scrollbar annotations** (markers on scrollbar track indicating events/outliers) - future enhancement for data storytelling
- **Dual-thumb range selection** (two independent handles to select non-viewport ranges) - future enhancement for range filtering
- **Touch optimization for phones** (larger touch targets, different interaction patterns) - initial release targets desktop/tablet, phone optimization is follow-up
- **Scrollbar-triggered data loading** (infinite scroll, pagination) - assumes all data is loaded, streaming integration is separate feature
- **Custom handle shapes** (beyond rectangle with rounded corners) - future enhancement for advanced customization
- **Scrollbar position customization** (left side, top side, floating overlay) - initial release uses standard positions (bottom for X, right for Y)
- **Scrollbar animation during auto-scroll** (for streaming charts with AutoScrollConfig) - initial implementation updates immediately, smooth animation is enhancement
- **Cross-axis zoom/pan locking** (proportional zoom on both axes, diagonal pan) - scrollbars operate independently, locked interactions are future feature

## Notes

- **Design Decision**: Scrollbar uses direct manipulation (drag handle) rather than scroll buttons (+/- arrows at ends) for simplicity and space efficiency. Keyboard navigation provides equivalent functionality for accessibility.
- **Performance Strategy**: Scrollbar updates throttle viewport changes to 60 FPS during drag. Final viewport update on drag end ensures accurate snapping to calculated data range.
- **Accessibility Priority**: All interactions must have keyboard equivalents. Screen reader support is mandatory, not optional, from initial release.
- **Integration Pattern**: Scrollbar is a widget that wraps or is placed alongside chart canvas, not painted into chart coordinate system. This preserves coordinate system independence.
- **Testing Approach**: Unit tests for position calculations, widget tests for rendering/gestures, integration tests for scrollbar+chart updates, performance benchmarks for drag smoothness.
