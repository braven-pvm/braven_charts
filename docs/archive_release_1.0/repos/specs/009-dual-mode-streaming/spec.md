# Feature Specification: Dual-Mode Streaming Chart

**Feature Branch**: `009-dual-mode-streaming`  
**Created**: 2025-01-22  
**Status**: Draft  
**Input**: User description: "New feature - detail in `docs\specs\streaming_interaction_architecture.md`"

## Clarifications

### Session 2025-10-22

- Q: When streaming data arrives (potentially from external/untrusted sources), should the chart validate or sanitize incoming data points? → A: No validation (assume developer provides clean data; fail fast on errors)
- Q: When the data stream disconnects or errors while in interactive mode (with buffered data), how should the chart behave when attempting to resume streaming? → A: Fail immediately and notify developer via error callback (no automatic retry)
- Q: When multiple chart instances exist on the same page/screen, should each chart manage its own mode independently, or should there be coordination (e.g., pausing one chart affects others)? → A: Independent mode management (each chart tracks its own mode; no coordination)
- Q: Should the chart provide built-in logging, metrics, or debugging hooks to help developers troubleshoot streaming/buffering issues? → A: No built-in observability (developers use external debugging tools)
- Q: When buffer reaches maximum capacity and continues receiving data, what should happen (given constraint: no data loss allowed)? → A: Force immediate return to streaming mode when buffer fills (auto-resume to apply buffered data and free space)

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Real-Time Data Monitoring (Priority: P1)

A developer integrates a real-time chart to monitor server metrics (CPU, memory, network traffic) that updates every 100ms. End users watch the live dashboard to track system health without interacting with the chart.

**Why this priority**: This is the core streaming use case. Without stable real-time visualization, the feature has no value. This must work flawlessly before any interaction capabilities are added.

**Independent Test**: Can be fully tested by streaming high-frequency data (60+ points per second) for extended periods (5+ minutes) and verifying zero rendering errors, smooth 60fps visualization, and accurate auto-scrolling to latest data.

**Acceptance Scenarios**:

1. **Given** a chart configured with real-time data stream, **When** data arrives at 60 points per second, **Then** chart displays all points smoothly at 60fps without frame drops
2. **Given** chart is in streaming mode, **When** new data arrives, **Then** viewport auto-scrolls to show the latest data points
3. **Given** streaming data for 10 minutes, **When** user observes the chart, **Then** no rendering errors occur and memory usage remains stable
4. **Given** chart is in streaming mode, **When** user moves mouse near chart, **Then** no interaction handlers activate and streaming continues uninterrupted

---

### User Story 2 - Pause for Historical Analysis (Priority: P2)

A user monitoring real-time data notices an anomaly and wants to inspect it closely. They hover over the chart to see detailed values, zoom into the suspicious time range, and pan to compare with earlier data. Meanwhile, new data continues to accumulate in the background.

**Why this priority**: This enables the critical use case of switching from monitoring to analysis. Users need this to investigate issues without losing incoming data.

**Independent Test**: Can be tested by hovering over a streaming chart, verifying immediate pause, performing zoom/pan interactions, confirming buffered data count increases, and verifying no rendering errors during interaction.

**Acceptance Scenarios**:

1. **Given** chart is streaming live data, **When** user hovers mouse over chart area, **Then** streaming pauses immediately and interaction mode activates
2. **Given** chart is in interactive mode, **When** new data arrives from stream, **Then** data is buffered silently without updating the visible chart
3. **Given** chart is in interactive mode, **When** user hovers over data points, **Then** crosshair and tooltip display without causing rendering errors
4. **Given** chart is in interactive mode with 100 buffered points, **When** user zooms and pans, **Then** chart responds smoothly without frame drops or errors
5. **Given** chart is in interactive mode, **When** user performs any interaction (hover, click, zoom, pan, scroll), **Then** auto-resume timer resets to configured duration

---

### User Story 3 - Auto-Resume to Live Stream (Priority: P2)

A user pauses streaming to investigate an anomaly. After examining the data for several seconds without further interaction, they want the chart to automatically return to live monitoring mode without manual intervention.

**Why this priority**: Auto-resume provides seamless return to monitoring mode, reducing cognitive load. Users shouldn't need to manually resume every time they pause to inspect data.

**Independent Test**: Can be tested by hovering to pause, waiting for the configured timeout period without interaction, and verifying chart automatically resumes streaming, applies buffered data, and jumps to latest viewport.

**Acceptance Scenarios**:

1. **Given** chart is in interactive mode with no user activity, **When** configured timeout period (default 10 seconds) expires, **Then** chart automatically resumes streaming mode
2. **Given** chart auto-resumes from interactive mode, **When** resuming, **Then** all buffered data points are applied to the chart
3. **Given** chart auto-resumes from interactive mode, **When** resuming, **Then** viewport jumps to show the latest data points
4. **Given** chart is in interactive mode, **When** user performs any interaction before timeout, **Then** timeout resets and countdown restarts
5. **Given** chart auto-resumes, **When** mode changes, **Then** configured callback is invoked with new mode

---

### User Story 4 - Manual Resume Control (Priority: P3)

A developer wants to provide users with explicit control over when to return to live streaming. They implement a "Return to Live" button in their UI that calls the resume method when clicked.

**Why this priority**: While auto-resume handles most cases, some users prefer explicit control. This is lower priority because auto-resume provides acceptable UX for most scenarios.

**Independent Test**: Can be tested by pausing chart, invoking the manual resume method via API call or button click, and verifying immediate return to streaming mode with buffered data applied.

**Acceptance Scenarios**:

1. **Given** chart is in interactive mode, **When** developer calls manual resume method, **Then** chart immediately returns to streaming mode regardless of timeout
2. **Given** chart is in interactive mode, **When** manual resume is triggered, **Then** all buffered data is applied and viewport jumps to latest data
3. **Given** chart provides manual resume callback, **When** callback is invoked, **Then** developer UI can display "Return to Live" button or custom control
4. **Given** manual resume is called, **When** mode changes, **Then** auto-resume timer is cancelled

---

### User Story 5 - Buffer Status Visibility (Priority: P3)

A developer wants to show users how much data has accumulated while they're in interactive mode. They configure the chart to provide buffer count updates and display "142 new points" or "5 seconds behind live" in their UI.

**Why this priority**: Nice-to-have feature for user awareness. Helpful but not essential for core functionality.

**Independent Test**: Can be tested by pausing chart, letting data accumulate, and verifying buffer count callback is invoked with accurate counts as new data arrives.

**Acceptance Scenarios**:

1. **Given** chart is in interactive mode with buffer callback configured, **When** new data point is buffered, **Then** callback is invoked with current buffer count
2. **Given** chart is in interactive mode, **When** buffer reaches configured maximum size, **Then** chart immediately forces return to streaming mode to prevent data loss
3. **Given** chart resumes streaming, **When** buffered data is applied, **Then** buffer count resets to zero

---

### Edge Cases

- What happens when chart starts with no data stream configured?
  - Chart defaults to interactive mode immediately (no streaming mode available)
- What happens when buffer size exceeds maximum limit during extended interaction?
  - Chart immediately forces return to streaming mode, applies all buffered data, and resumes normal streaming (prevents data loss; user interaction is interrupted)
- What happens when user switches modes rapidly (pause/resume/pause)?
  - Each transition completes fully before next can occur; timer resets appropriately
- What happens when stream ends or errors while in interactive mode?
  - Chart fails immediately and invokes error callback; buffered data is preserved; developer is responsible for reconnection/retry logic
- What happens when auto-scroll configuration changes during streaming?
  - New configuration takes effect on next data point arrival
- What happens when user interacts during the split-second of auto-resume?
  - Interaction takes precedence; chart stays in interactive mode and auto-resume is cancelled
- What happens on hot reload during interactive mode?
  - Chart resets to streaming mode (no mode persistence across hot reload)

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: Chart MUST operate in exactly one mode at any time (streaming OR interactive, never both)
- **FR-001a**: Each chart instance MUST manage its mode independently (no coordination between multiple chart instances)
- **FR-002**: Chart MUST start in streaming mode when data stream is configured
- **FR-003**: Chart MUST start in interactive mode when no data stream is configured
- **FR-004**: Chart MUST automatically transition from streaming to interactive mode on first user interaction (hover, click, zoom, pan, scroll, keyboard)
- **FR-005**: Chart MUST disable ALL interaction handlers (mouse, touch, keyboard) while in streaming mode
- **FR-006**: Chart MUST buffer incoming data points silently while in interactive mode
- **FR-006a**: Chart MUST assume incoming data is valid and well-formed (no validation performed; invalid data causes fail-fast errors)
- **FR-007**: Chart MUST provide configurable auto-resume timeout (default 10 seconds)
- **FR-008**: Chart MUST reset auto-resume timer on any user interaction while in interactive mode
- **FR-009**: Chart MUST automatically resume streaming mode when auto-resume timeout expires with no user activity
- **FR-010**: Chart MUST provide manual resume method that can be called programmatically
- **FR-011**: Chart MUST apply all buffered data points when transitioning from interactive to streaming mode
- **FR-012**: Chart MUST update viewport to show latest data points when resuming streaming mode
- **FR-013**: Chart MUST limit buffer size to prevent memory overflow (configurable maximum, default 10,000 points)
- **FR-014**: Chart MUST immediately force return to streaming mode when buffer reaches maximum size (prevents data loss by applying buffered data and resuming streaming)
- **FR-015**: Chart MUST invoke mode change callback when transitioning between modes
- **FR-016**: Chart MUST invoke buffer update callback when data is buffered in interactive mode
- **FR-017**: Chart MUST invoke return-to-live callback to enable developer UI for manual resume
- **FR-017a**: Chart MUST invoke error callback immediately when stream disconnects or errors (no automatic retry)
- **FR-017b**: Chart MUST NOT provide built-in logging or metrics (developers use external debugging tools and callbacks for observability)
- **FR-018**: Chart MUST maintain smooth 60fps rendering during streaming mode
- **FR-019**: Chart MUST respond to user interactions within 16ms in interactive mode
- **FR-020**: Chart MUST NOT trigger rendering errors (box.dart, mouse_tracker.dart) during mode transitions or data updates

### Key Entities

- **Chart Mode**: Enumeration representing current operating mode (streaming or interactive)
- **Streaming Configuration**: Settings controlling timeout duration, buffer limits, pause behavior, and callback functions
- **Buffer**: Temporary storage for data points that arrive during interactive mode
- **Mode Transition**: Event representing change from one mode to another, with associated state cleanup and initialization
- **Auto-Resume Timer**: Countdown mechanism that triggers automatic return to streaming mode after inactivity period

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Chart displays real-time streaming data at 60 frames per second without frame drops for continuous 10-minute sessions
- **SC-002**: Chart transitions from streaming to interactive mode within 50 milliseconds of first user interaction
- **SC-003**: Zero rendering pipeline errors (box.dart:3345:18, mouse_tracker.dart:199:12) occur during streaming, interaction, or mode transitions
- **SC-004**: Chart responds to user interactions (hover, zoom, pan) within 16 milliseconds in interactive mode
- **SC-005**: Chart buffers up to 10,000 data points during extended interactive sessions without memory leaks or performance degradation; forces return to streaming mode when buffer capacity reached to prevent data loss
- **SC-006**: Chart automatically resumes streaming mode within 100 milliseconds after configured timeout expires
- **SC-007**: All buffered data points (up to 10,000) are applied and viewport updated within 500 milliseconds when resuming streaming
- **SC-008**: Users can perform unlimited interaction cycles (pause → interact → resume) without encountering errors or degraded performance
- **SC-009**: Memory usage remains stable (no unbounded growth) during 1-hour sessions with repeated mode transitions
- **SC-010**: Chart handles high-frequency data streams (100+ points per second) in streaming mode without data loss or visual artifacts

## Assumptions

- Users primarily monitor real-time data without interaction, and occasionally pause for analysis
- Interaction sessions are typically short (under 30 seconds) before returning to monitoring
- Data streams provide consistent data point formats throughout session
- Developers can implement custom UI for mode indicators and resume controls
- 10-second auto-resume timeout suits most use cases (configurable for exceptions)
- 10,000 point buffer limit is sufficient for typical interaction durations
- Users accept viewport "jump" to latest data when resuming (alternative: smooth animation to latest data)
- Charts display on devices capable of 60fps rendering (modern desktops, tablets, phones)
