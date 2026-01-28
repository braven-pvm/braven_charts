# Feature Specification: Braven Agent Package

**Feature Branch**: `004-braven-agent-package`  
**Created**: 2026-01-28  
**Status**: Draft  
**Input**: User description: "braven_agent - Creating Braven_Agent package with headless AI orchestration engine for chart generation, plus demo application for testing agent interfaces, sessions, and basic chat flow"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Developer Creates Charts via Natural Language (Priority: P1)

A developer integrates the braven_agent package into their application to enable users to create charts through natural language conversations. The developer initializes an agent session, binds it to their UI, and when users type prompts like "Create a line chart showing sales trends", the session processes the request through an LLM, executes the chart creation tool, and returns a chart configuration that can be rendered.

**Why this priority**: This is the core value proposition - enabling conversational chart generation. Without this capability functioning end-to-end, the package delivers no value.

**Independent Test**: Can be fully tested by creating a demo application that starts a session, sends a chart creation prompt, and verifies the session returns a valid chart configuration with the requested properties. Delivers complete chart creation capability.

**Acceptance Scenarios**:

1. **Given** a developer has added braven_agent as a dependency and configured an LLM provider, **When** they create an `AgentSession`, **Then** the session initializes successfully in idle state with no errors
2. **Given** an active session, **When** the developer sends a prompt via `transform("Create a line chart with sales data")`, **Then** the session state transitions to "thinking" and listeners are notified
3. **Given** the LLM decides to create a chart, **When** the `create_chart` tool execution completes, **Then** the session's `activeChart` property contains a `ChartConfiguration` with at least one series
4. **Given** a chart was created successfully, **When** the session returns to idle, **Then** a `ChartCreatedEvent` is emitted on the events stream

---

### User Story 2 - Developer Modifies Existing Charts via Conversation (Priority: P1)

After creating a chart, a developer wants users to be able to refine it through follow-up conversation. Users can say things like "Make the line red" or "Add a legend at the top", and the agent modifies the existing chart rather than creating a new one.

**Why this priority**: Chart iteration is essential for real-world use. Users rarely get exactly what they want on the first try. This completes the core conversational loop.

**Independent Test**: Can be tested by creating a chart, then sending a modification prompt, and verifying the chart configuration updates while preserving the original chart ID.

**Acceptance Scenarios**:

1. **Given** an active chart exists in the session, **When** the developer sends a modification prompt like "Change the chart type to bar", **Then** the agent uses the `modify_chart` tool
2. **Given** a modification is applied, **When** the tool completes, **Then** the `activeChart` is updated with the new properties while preserving unchanged properties
3. **Given** a modification succeeds, **When** processing completes, **Then** a `ChartUpdatedEvent` is emitted (not `ChartCreatedEvent`)
4. **Given** no chart exists in the session, **When** a modification prompt is sent, **Then** the tool returns an error indicating no chart to modify

---

### User Story 3 - Demo App Demonstrates Complete Chat Flow (Priority: P1)

A developer runs the demo application to verify the braven_agent package works correctly and to understand integration patterns. They see a simple chat interface, type prompts requesting charts, observe processing states (thinking, tool execution), and see rendered charts appear alongside conversation messages.

**Why this priority**: The demo app validates the package works end-to-end and serves as living documentation for developers learning to integrate the package.

**Independent Test**: Can be tested by running the demo app, entering "Create a line chart with 3 data series", and visually confirming the chart renders with 3 distinct series.

**Acceptance Scenarios**:

1. **Given** the demo app is launched, **When** it loads completely, **Then** a text input for messages and a message display area are visible
2. **Given** the user types a message and submits it, **When** the message is sent, **Then** the user's message appears in the conversation history
3. **Given** the agent is processing, **When** the session state is "thinking", **Then** a visual indicator (spinner, text) shows processing is in progress
4. **Given** the agent is executing a tool, **When** the session state is "calling_tool", **Then** a visual indicator shows which tool is running
5. **Given** the agent creates a chart, **When** processing completes, **Then** the chart is rendered in the UI and the assistant's response appears
6. **Given** an error occurs, **When** the error is caught, **Then** a user-friendly error message is displayed in the conversation

---

### User Story 4 - Developer Observes Real-Time Session State (Priority: P2)

A developer needs to reflect the agent's processing state in their UI to provide good user experience. They listen to session state changes via `ValueListenable` to show loading indicators, display "thinking" animations, and indicate when specific tools are being executed.

**Why this priority**: Responsive feedback is critical for UX. Without state observability, developers cannot build engaging interfaces.

**Independent Test**: Can be tested by listening to session state transitions and logging each change through idle → thinking → calling_tool → idle during a chart generation request.

**Acceptance Scenarios**:

1. **Given** a session is idle, **When** a prompt is submitted, **Then** the state transitions to "thinking" immediately
2. **Given** the LLM returns a tool call, **When** tool execution starts, **Then** the state transitions to "calling_tool" and `activeTool` contains the tool name and input
3. **Given** a tool finishes, **When** the result is processed, **Then** `activeTool` is cleared
4. **Given** all processing completes, **When** the final response is received, **Then** the state returns to "idle"

---

### User Story 5 - Developer Reacts to Agent Events (Priority: P2)

A developer wants to trigger side effects when specific agent activities occur - like saving charts to a database when created, showing toast notifications, or navigating to a chart view. They subscribe to the events stream for clean, reactive event handling.

**Why this priority**: Events enable persistence, analytics, and UI orchestration without polling or complex state diffing.

**Independent Test**: Can be tested by subscribing to the events stream and verifying `ChartCreatedEvent`, `ToolStartEvent`, and `ToolEndEvent` are emitted with correct data during a chart creation flow.

**Acceptance Scenarios**:

1. **Given** a developer subscribes to `session.events`, **When** a chart is created, **Then** a `ChartCreatedEvent` is emitted containing the full `ChartConfiguration`
2. **Given** a developer subscribes to events, **When** a chart is modified, **Then** a `ChartUpdatedEvent` is emitted with the updated configuration
3. **Given** a tool starts executing, **When** the event is emitted, **Then** `ToolStartEvent` contains the tool name
4. **Given** a tool completes, **When** the event is emitted, **Then** `ToolEndEvent` contains success/failure status
5. **Given** an error occurs, **When** the event is emitted, **Then** `ErrorEvent` contains a descriptive message

---

### User Story 6 - Developer Configures LLM Provider (Priority: P2)

A developer configures the agent session to use their preferred LLM backend (Anthropic/Claude initially). They provide API credentials and can select different models for different use cases (faster model for simple tasks, more capable model for complex charts).

**Why this priority**: Without LLM configuration, the package cannot communicate with AI services. This is a prerequisite for all agent functionality.

**Independent Test**: Can be tested by creating an Anthropic provider with valid API key and model selection, then verifying the session successfully generates responses.

**Acceptance Scenarios**:

1. **Given** a developer creates an LLM config with API key and model name, **When** they create a provider from the config, **Then** the provider initializes without errors
2. **Given** a valid provider is passed to AgentSession, **When** transform() is called, **Then** the LLM is invoked with the configured model
3. **Given** an invalid API key is configured, **When** transform() is called, **Then** an error is surfaced through the events stream or state

---

### User Story 7 - Developer Syncs User Edits to Agent Context (Priority: P3)

After the agent creates a chart, the user might edit it directly in the UI (e.g., change a color via color picker). The developer calls `session.updateChart()` to sync this edit back to the session, so subsequent agent interactions are aware of the current chart state.

**Why this priority**: Bi-directional sync completes the interaction model but is not required for basic functionality.

**Independent Test**: Can be tested by modifying a chart configuration externally, calling `updateChart()`, then sending a follow-up prompt and verifying the agent is aware of the modification.

**Acceptance Scenarios**:

1. **Given** a chart exists in the session, **When** the developer calls `updateChart(modifiedConfig)`, **Then** `state.activeChart` reflects the modified configuration
2. **Given** updateChart was called, **When** the next prompt is sent, **Then** the agent's context includes the updated chart state
3. **Given** updateChart is called, **When** the update completes, **Then** a `ChartUpdatedEvent` is emitted

---

### User Story 8 - Demo App Displays Conversation History (Priority: P3)

The demo app maintains and displays the full conversation history, showing user messages and assistant responses in chronological order, allowing developers to review the interaction flow and debug issues.

**Why this priority**: Conversation visibility aids development and debugging but is not core to package value.

**Independent Test**: Can be tested by having a multi-turn conversation and verifying all messages appear in correct chronological order.

**Acceptance Scenarios**:

1. **Given** a user sends multiple messages, **When** viewing the chat history, **Then** all messages appear in chronological order
2. **Given** the assistant responds with text, **When** viewing the history, **Then** the assistant's message is displayed with appropriate styling
3. **Given** a chart was created, **When** viewing the history, **Then** some indication of the chart creation appears in the conversation

---

### Edge Cases

- What happens when the LLM service is unavailable? The session should transition to error state, emit an `ErrorEvent` with descriptive message, and the demo app should display a user-friendly error.
- What happens when the LLM returns malformed tool input? The tool should catch parsing errors, return a `ToolResult` with `isError: true`, and the LLM can self-correct on the next turn.
- What happens when the user submits an empty prompt? The session should handle gracefully - either ignore, return immediately, or provide a helpful response.
- What happens during network interruption mid-request? The session should timeout appropriately, transition to error state, and allow retry.
- What happens when a user calls `dispose()` while processing? Resources should be cleaned up, pending operations cancelled, without memory leaks or orphaned async operations.
- What happens when `cancel()` is called during tool execution? The operation should be cancelled if possible, state reset to idle, and `CancelledEvent` emitted.
- What happens when the LLM calls an unknown tool? The session should handle gracefully with an error rather than crashing.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: Package MUST provide an `AgentSession` interface that manages conversation state and orchestrates LLM communication
- **FR-002**: Package MUST support an LLM provider abstraction allowing different AI backends to be plugged in
- **FR-003**: Package MUST include an Anthropic/Claude adapter as the initial LLM provider implementation
- **FR-004**: Package MUST expose session state (history, status, active tool, active chart, errors) through an observable mechanism (`ValueListenable`)
- **FR-005**: Package MUST emit typed events for chart creation, chart modification, tool execution, errors, and cancellation
- **FR-006**: Package MUST include a `create_chart` tool that produces `ChartConfiguration` objects from natural language prompts
- **FR-007**: Package MUST include a `modify_chart` tool that updates existing charts based on natural language prompts
- **FR-008**: Package MUST handle the LLM tool-calling loop, continuing until no more tools are called
- **FR-009**: Package MUST capture `ChartConfiguration` objects from tool results and make them accessible via session state
- **FR-010**: Package MUST provide a `ChartRenderer` that converts `ChartConfiguration` into renderable chart widgets
- **FR-011**: Package MUST support cancellation of in-progress operations via `cancel()` method
- **FR-012**: Package MUST clean up resources (close streams, cancel operations) when `dispose()` is called
- **FR-013**: Package MUST provide an `updateChart()` method to sync external chart modifications back to session state
- **FR-014**: Demo app MUST provide a text input for sending messages and a display area for conversation history
- **FR-015**: Demo app MUST show visual feedback during processing states (thinking, tool execution)
- **FR-016**: Demo app MUST render charts created by the agent
- **FR-017**: Demo app MUST display error messages when failures occur

### Key Entities

- **AgentSession**: The core orchestration interface managing conversation state, LLM communication, and tool execution. Exposes observable state and an event stream.
- **SessionState**: Immutable state model containing conversation history, activity status, active tool info, active chart, and error messages.
- **AgentEvent**: Sealed type hierarchy for events (ChartCreatedEvent, ChartUpdatedEvent, ToolStartEvent, ToolEndEvent, ErrorEvent, CancelledEvent, ProcessingStartedEvent, ProcessingCompletedEvent).
- **LLMProvider**: Abstraction for LLM backends, defining how to send conversation history and receive responses.
- **LLMConfig**: Configuration model with API credentials, model selection, and inference parameters.
- **AgentTool**: Interface for executable tools with name, description, JSON schema, and execute method.
- **ToolResult**: Result of tool execution containing output string, error flag, and optional structured data.
- **ChartConfiguration**: Complete specification of a chart including type, series, axes, annotations, and styling.
- **ChartRenderer**: Translator that converts ChartConfiguration into renderable chart widgets.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: A developer can integrate braven_agent by following quickstart.md in 5 steps or fewer: (1) add dependency, (2) register provider, (3) create session, (4) call transform(), (5) render chart. Demo app serves as working reference implementation
- **SC-002**: The demo application successfully demonstrates creating a chart, modifying it, and displaying the conversation - all within a single session
- **SC-003**: Session state transitions are accurate and observable, with correct status at all processing stages
- **SC-004**: The `create_chart` tool successfully generates valid chart configurations containing at least one series with data points for prompts that include chart type and data description (e.g., "Create a line chart with sales data")
- **SC-005**: The `modify_chart` tool successfully updates existing charts while preserving unchanged properties
- **SC-006**: All errors are caught and surfaced through state or events, with no silent failures or crashes
- **SC-007**: The demo app runs without errors and renders charts for standard chart generation prompts
- **SC-008**: The package remains domain-agnostic - no dependencies on "Athletes", "FIT files", "Projects" or other app-specific concepts
- **SC-009**: Chart configurations produced by the agent render correctly through `ChartRenderer` without additional transformation

## Assumptions

- The technical implementation specification at `specs/_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md` provides authoritative implementation details
- Anthropic/Claude is the initial LLM provider; the abstraction allows future providers to be added
- The demo app is minimal - focused on validating package functionality, not production-grade UX
- Session state is session-local only (no persistence to disk/database in V1)
- The chart rendering library (`braven_chart_plus`) is available as a dependency for chart output
- API keys are provided by the developer at runtime via configuration
- Network connectivity is available for LLM communication (offline mode is out of scope)
- V1 attachment support is limited to images and basic text files; FIT/CSV parsing requires future integration with DataContext (004.3)

## Technical Reference

For implementation details, architecture decisions, and code samples, see:

- [specs/\_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md) - Complete implementation specification
- [specs/\_base/004-braven-lab-studio-integration/decisions/](../_base/004-braven-lab-studio-integration/decisions/) - Architecture decision records

This specification focuses on user/developer needs and behaviors. The technical reference contains API schemas, code structure, and implementation patterns.
