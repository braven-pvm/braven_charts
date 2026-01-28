# Feature Specification: Braven Agent Package

**Feature Branch**: `004-braven-agent-package`  
**Created**: 2026-01-28  
**Status**: Draft  
**Input**: User description: "braven_agent - Creating a new package called Braven_Agents with demo application for testing agent interfaces and sessions"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Developer Uses Agent Session for Chat-Based Chart Generation (Priority: P1)

A developer integrates the braven_agent package into their application to enable users to create charts through natural language conversations. The developer initializes an agent session, binds it to their UI, and when users type prompts, the session processes them through an LLM, executes chart tools, and returns chart configurations that can be rendered.

**Why this priority**: This is the core value proposition - providing a clean, UI-bindable API for conversational chart generation. Without a working session abstraction, nothing else functions.

**Independent Test**: Can be fully tested by creating a demo application that starts a session, sends a prompt like "Create a line chart with sales data", and verifies the session returns a chart configuration. Delivers the foundation for all conversational chart features.

**Acceptance Scenarios**:

1. **Given** a developer has added braven_agent as a dependency, **When** they create an `AgentSession` with an LLM provider, **Then** the session initializes successfully in idle state
2. **Given** an active session, **When** the developer sends a user prompt via `transform()`, **Then** the session updates its state to "thinking" and notifies listeners
3. **Given** the LLM decides to create a chart, **When** the tool execution completes, **Then** the session's `activeChart` property contains the generated `ChartConfiguration`
4. **Given** a chart was created, **When** the session returns to idle, **Then** an event is emitted on the events stream that the developer can listen to

---

### User Story 2 - Developer Configures Different LLM Providers (Priority: P2)

A developer wants flexibility in choosing their LLM backend. They can configure the agent session with different LLM providers (starting with Anthropic/Claude) by simply swapping out the provider configuration, without changing their application code.

**Why this priority**: Extensibility and vendor independence are crucial for adoption. Developers need assurance they aren't locked into a single AI provider.

**Independent Test**: Can be tested by initializing sessions with an Anthropic provider using different API keys and model configurations, verifying successful LLM communication.

**Acceptance Scenarios**:

1. **Given** a developer creates an Anthropic LLM provider with API key and model configuration, **When** they pass it to an AgentSession, **Then** the session uses that provider for all communications
2. **Given** an LLM provider is configured with a specific model (e.g., claude-sonnet-4), **When** responses are generated, **Then** the specified model is used
3. **Given** the developer provides an invalid API key, **When** the session attempts to communicate, **Then** meaningful error information is available through the session state

---

### User Story 3 - Demo App Tests Basic Chat Flow (Priority: P1)

A developer runs the demo application to verify the braven_agent package works correctly. They see a simple chat interface, type a prompt requesting a chart, see the processing states (thinking, tool execution), and see the rendered chart appear.

**Why this priority**: The demo app is essential for validating the package works end-to-end and serves as reference documentation for integration patterns.

**Independent Test**: Can be tested by running the demo app, entering a prompt like "Create a chart with 4 data series", and visually confirming the chart renders with 4 series.

**Acceptance Scenarios**:

1. **Given** the demo app is launched, **When** it loads completely, **Then** a chat input area and message display area are visible
2. **Given** the user types a message and submits it, **When** the message is sent, **Then** the user message appears in the chat history
3. **Given** the agent is processing, **When** the session state is "thinking" or "calling_tool", **Then** a visual indicator shows processing is in progress
4. **Given** the agent creates a chart, **When** processing completes, **Then** the chart is rendered in the UI alongside the conversation
5. **Given** an error occurs (e.g., network failure), **When** the error is caught, **Then** a user-friendly error message is displayed

---

### User Story 4 - Developer Observes Session State Changes (Priority: P2)

A developer needs to reflect the agent's processing state in their UI. They listen to session state changes to show loading indicators, display thinking animations, and indicate when tools are being executed.

**Why this priority**: Good UX requires responsive feedback. Developers need granular state information to build engaging interfaces.

**Independent Test**: Can be tested by listening to session state changes and logging each transition through idle → thinking → calling_tool → idle during a chart generation request.

**Acceptance Scenarios**:

1. **Given** a session is idle, **When** a prompt is submitted, **Then** the state transitions to "thinking"
2. **Given** the LLM decides to call a tool, **When** the tool execution starts, **Then** the state transitions to "calling_tool" and `activeTool` is populated
3. **Given** a tool finishes execution, **When** the result is returned, **Then** the state transitions appropriately (back to thinking for more tools, or idle when complete)
4. **Given** an error occurs during processing, **When** the error is caught, **Then** the state includes error information

---

### User Story 5 - Developer Listens to Agent Events (Priority: P3)

A developer wants to react to specific agent activities, like chart creation events, to trigger additional UI updates (e.g., auto-scrolling to show a new chart, playing a sound, or updating a sidebar).

**Why this priority**: Events provide a clean reactive pattern for UI updates without polling or complex state diffing.

**Independent Test**: Can be tested by subscribing to the events stream and verifying `ChartCreatedEvent` is emitted when a chart tool completes successfully.

**Acceptance Scenarios**:

1. **Given** a developer subscribes to `session.events`, **When** a chart is successfully created, **Then** a `ChartCreatedEvent` is emitted with the configuration
2. **Given** a developer subscribes to events, **When** a tool starts executing, **Then** a `ToolStartEvent` is emitted with the tool name
3. **Given** a developer subscribes to events, **When** a tool finishes, **Then** a `ToolEndEvent` is emitted with success/failure indication
4. **Given** multiple listeners are subscribed, **When** an event is emitted, **Then** all listeners receive the event

---

### User Story 6 - Demo App Displays Conversation History (Priority: P3)

The demo app maintains and displays the full conversation history, showing user messages, assistant responses, and any tool usage, allowing developers to understand the flow and debug issues.

**Why this priority**: Conversation visibility is essential for development and debugging but not core to the package's value.

**Independent Test**: Can be tested by having a multi-turn conversation and verifying all messages (user, assistant, tool results) appear in chronological order.

**Acceptance Scenarios**:

1. **Given** a user sends multiple messages, **When** viewing the chat history, **Then** all messages appear in chronological order
2. **Given** the assistant provides a response, **When** viewing the history, **Then** the assistant's text is displayed
3. **Given** a tool was executed, **When** viewing the history, **Then** some indication of tool usage is visible (e.g., "Creating chart..." or tool result)

---

### Edge Cases

- What happens when the LLM service is unavailable? The session should report an error state with meaningful error information, and the demo app should display a user-friendly message.
- What happens when the LLM returns malformed tool input? The tool should catch parsing errors and return an error result that the LLM can see and self-correct.
- What happens when the user submits an empty prompt? The session should handle gracefully without crashing, potentially ignoring or returning immediately.
- What happens during network interruption mid-response? The session should timeout appropriately and transition to error state.
- What happens when a tool takes too long to execute? Cancellation should be possible via `session.cancel()`.
- What happens if the user disposes the session while processing? Resources should be cleaned up without leaking memory or leaving orphaned operations.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST provide an `AgentSession` abstraction that manages conversation state and LLM communication
- **FR-002**: System MUST support configuration of LLM providers with API credentials, model selection, and temperature settings
- **FR-003**: System MUST implement an Anthropic/Claude adapter as the initial LLM provider
- **FR-004**: System MUST expose session state (history, status, active tool, active chart, errors) through observable mechanisms
- **FR-005**: System MUST emit typed events for chart creation, tool execution, and errors
- **FR-006**: System MUST include a `create_chart` tool that produces chart configurations from natural language prompts
- **FR-007**: System MUST handle tool results and continue the LLM conversation loop until no more tools are called
- **FR-008**: System MUST capture `ChartConfiguration` objects from tool results and make them accessible via session state
- **FR-009**: Demo app MUST provide a simple chat interface for sending messages and viewing responses
- **FR-010**: Demo app MUST display visual feedback during processing states (thinking, tool execution)
- **FR-011**: Demo app MUST render charts created by the agent using the chart rendering capabilities
- **FR-012**: Demo app MUST display error messages when failures occur
- **FR-013**: System MUST support cancellation of in-progress operations via `session.cancel()`
- **FR-014**: System MUST clean up resources when the session is disposed

### Key Entities

- **AgentSession**: The core orchestration interface that manages conversation state, communicates with LLMs, and executes tools. Exposes observable state and an event stream.
- **LLMProvider**: An abstraction for LLM backends, allowing different AI services to be plugged in. Defines how to send prompts and receive responses.
- **LLMConfig**: Configuration model containing API credentials, model selection, and inference parameters.
- **AgentMessage**: A message in the conversation, containing role (user/assistant/tool), content (text, images, tool calls, tool results), and metadata.
- **AgentTool**: An interface for executable tools that the LLM can invoke. Defines name, description, input schema, and execution logic.
- **SessionState**: Immutable state model containing conversation history, current status, active tool, active chart, and any errors.
- **AgentEvent**: Base type for events emitted by the session (chart created, tool started, tool ended, errors).

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: A developer can integrate braven_agent into an application and have a working chat-to-chart flow in under 30 minutes
- **SC-002**: The demo application successfully demonstrates a complete conversation flow from user prompt to rendered chart
- **SC-003**: Session state transitions are observable and accurate, reflecting true processing status at all times
- **SC-004**: The create_chart tool successfully generates valid chart configurations for at least 90% of reasonable chart-related prompts
- **SC-005**: Errors are caught and surfaced through session state/events, not swallowed or causing crashes
- **SC-006**: Demo app runs without errors and renders charts for standard chart generation prompts
- **SC-007**: The package has no dependencies on application-specific concepts (athletes, projects, FIT files) - it remains domain-agnostic
- **SC-008**: Chart configurations produced by the agent can be rendered by the chart rendering library without additional transformation

## Assumptions

- The existing agentic implementation in `lib/src/agentic` serves as a working reference and source of tested patterns
- Anthropic/Claude is the initial LLM provider; the abstraction allows future providers to be added
- The demo app is simple/minimal - focused on testing package functionality, not production UX
- Session state is session-local only (no persistence to disk/database in this version)
- The chart rendering capability exists in the parent library (braven_chart_plus) and is imported as a dependency
- API keys are provided by the developer at runtime, not embedded in the package
- Network connectivity is available for LLM communication (offline mode is out of scope)

## Technical Reference

For implementation details, see: [specs/\_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md)

This specification focuses on user/developer needs and behaviors. The technical reference contains implementation patterns, API schemas, and code structure.
