# Research: Braven Agent Package

**Feature**: 004-braven-agent-package  
**Date**: 2026-01-28  
**Status**: Complete

## Overview

This document consolidates research findings and design decisions for the `braven_agent` package implementation. All decisions reference the authoritative base specifications.

---

## 1. Package Architecture

### Decision: Monorepo Sub-Package

**What was chosen**: Create `braven_agent` as a sub-package at `packages/braven_agent/` within the braven_chart_plus repository.

**Rationale**:

- Allows path-based dependency on `braven_chart_plus` during development
- Enables coordinated releases
- Keeps related code together for easier maintenance
- Standard Flutter monorepo pattern

**Alternatives considered**:

- Separate repository: Rejected - adds complexity for tightly coupled packages
- Same package: Rejected - violates separation of concerns (AI vs rendering)

**Reference**: [004.1 Section 3.1](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md#31-metadata)

---

## 2. State Management Pattern

### Decision: ValueNotifier + ValueListenableBuilder

**What was chosen**: Use `ValueNotifier<SessionState>` for reactive UI binding, NOT streams for primary state.

**Rationale**:

- Flutter UIs are synchronous reflections of state
- `ValueListenableBuilder` is built-in and efficient
- Avoids StreamBuilder's async snapshot complexity
- Constitution mandates ValueNotifier for >10Hz updates (Performance First)
- MouseTracker conflicts: setState during pointer events causes assertion failures

**Alternatives considered**:

- Stream<SessionState>: Rejected - adds unnecessary async complexity
- setState: Rejected - violates constitution Performance First principle

**Reference**: [chat-architecture.md Section 3](../_base/004-braven-lab-studio-integration/decisions/chat-architecture.md)

---

## 3. Event vs State Pattern

### Decision: Dual-Channel Notification

**What was chosen**:

- `ValueListenable<SessionState>` for **rendering** (draw the chart)
- `Stream<AgentEvent>` for **side effects** (save to DB, show toast, navigate)

**Rationale**:

- State is for "what to show" - synchronous, always-current
- Events are for "what happened" - transient, one-time notifications
- Prevents consumers from polling or diffing state for persistence triggers
- Clean separation of concerns

**Alternatives considered**:

- Single stream for everything: Rejected - conflates rendering with persistence
- State-only with callbacks: Rejected - harder to manage multiple listeners

**Reference**: [chart-propagation.md Sections 6-7](../_base/004-braven-lab-studio-integration/decisions/chart-propagation.md)

---

## 4. LLM Provider Abstraction

### Decision: Registry Pattern with Interface

**What was chosen**:

- Abstract `LLMProvider` interface (dumb pipe - no business logic)
- `LLMRegistry` factory for provider creation
- `AnthropicAdapter` as initial implementation

**Rationale**:

- Decouples provider implementation from agent logic
- Adding new providers (OpenAI, Gemini) requires only new adapter + registration
- No changes to AgentSession when switching providers
- Provider doesn't know about charts, athletes, or domain concepts

**Alternatives considered**:

- Hardcoded Anthropic: Rejected - not extensible
- Direct SDK usage: Rejected - leaks SDK types into app layer

**Reference**: [llm-architecture.md Sections 2-3](../_base/004-braven-lab-studio-integration/decisions/llm-architecture.md)

---

## 5. Tool System Design

### Decision: Interface-Based Tools with Structured Results

**What was chosen**:

- `AgentTool` interface with name, description, inputSchema, execute()
- `ToolResult` with output string, isError flag, and optional structured `data`
- AgentSession captures `ChartConfiguration` from `ToolResult.data`

**Rationale**:

- Consistent interface for all tools
- Schema-driven (JSON Schema for LLM)
- Structured data allows type-safe chart capture
- Error handling via isError flag enables LLM self-correction

**Alternatives considered**:

- String-only results: Rejected - loses type safety for chart objects
- Exception-based errors: Rejected - breaks LLM conversation loop

**Reference**: [004.1 Section 6](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md#6-tool-system)

---

## 6. Chart State Propagation

### Decision: Chart in SessionState with updateChart() Method

**What was chosen**:

- `activeChart` is part of `SessionState` (single source of truth)
- `session.updateChart(newConfig)` for user edits
- Next `transform()` automatically includes chart context

**Rationale**:

- Guarantees chart on screen matches chart agent sees
- No separate chart stream to synchronize
- User edits flow back to agent naturally
- Clean update loop: Agent creates → User edits → Agent sees update

**Alternatives considered**:

- Separate Stream<Chart>: Rejected - synchronization complexity
- Chart outside state: Rejected - divergence risk

**Reference**: [chart-propagation.md Section 6](../_base/004-braven-lab-studio-integration/decisions/chart-propagation.md#6-chart-state-propagation)

---

## 7. ChartRenderer Location

### Decision: Renderer Lives in braven_agent

**What was chosen**: `ChartRenderer` at `lib/src/renderer/chart_renderer.dart` within braven_agent.

**Rationale**:

- braven_agent owns the `ChartConfiguration` model
- Renderer depends on braven_chart_plus for output widget
- Consumers of braven_agent get both config AND renderer
- Single import for full functionality

**Alternatives considered**:

- Renderer in braven_chart_plus: Rejected - would require moving models there too, coupling AI concepts to rendering library
- Separate renderer package: Rejected - unnecessary complexity for tightly coupled components

**Reference**: [004.1 Section 8.1](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md#81-purpose)

---

## 8. Direct Translation Components

### Decision: Only ChartRenderer and Property Wiring Test

**What was chosen**: Translate these two components directly from `/agentic`:

1. `ChartRenderer` from `lib/src/agentic/services/chart_renderer.dart`
2. Property wiring test from `test/agentic/property_wiring_test.dart`

**Rationale**:

- ChartRenderer has complex property mapping logic already working
- Property wiring test validates all chart properties flow correctly
- All other components implement fresh from specification
- Prevents copying unnecessary complexity from legacy code

**Alternatives considered**:

- Translate all agentic code: Rejected - carries technical debt and complexity
- Rewrite ChartRenderer from scratch: Rejected - high-risk, complex mapping logic

**Reference**: [004.1 Section 2.4](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md#24-direct-translations-exceptions)

---

## 9. V1 Scope Boundaries

### Decision: MVP with Create/Modify Chart Only

**What was chosen**: V1 includes ONLY:

- `create_chart` tool (synthetic data)
- `modify_chart` tool (update active chart)
- Image attachments (PNG/JPEG)
- Basic text file attachments

**Excluded from V1**:

- `load_data_tool`, `describe_data_tool`, `calculate_metric_tool`
- FIT/CSV file processing (requires 004.3 DataContext)
- Chart history/versioning
- File picker services

**Rationale**:

- KISS principle - minimum viable product
- Data tools require athlete datastore (future spec 004.3)
- Synthetic chart generation validates core architecture
- Can ship and iterate

**Alternatives considered**:

- Include data tools: Rejected - depends on unimplemented DataContext
- Include file pickers: Rejected - out of scope for headless package

**Reference**: [004.1 Section 2.3](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md#23-out-of-scope-v1)

---

## 10. Error Handling Strategy

### Decision: Graceful Degradation with Events

**What was chosen**:

- Tool errors return `ToolResult(isError: true)` - LLM can self-correct
- Network errors caught by AgentSession, emit `ErrorEvent`, set state to error
- Unknown tools throw `ToolNotFoundException`, emit `ErrorEvent`
- Never crash - always surface through state or events

**Rationale**:

- LLM self-correction is powerful for tool errors
- UI can react to ErrorEvent (show dialog, retry button)
- State always reflects current situation
- No silent failures

**Reference**: [004.1 Section 5 (Error Handling)](../_base/004-braven-lab-studio-integration/technical-design.md#5-error-handling-strategy)

---

## 11. Cancellation Support

### Decision: CancelableOperation Pattern

**What was chosen**:

- Use `CancelableOperation` from `async` package
- `session.cancel()` aborts LLM request and resets state
- Emit `CancelledEvent` on cancellation

**Rationale**:

- Users expect to stop long-running requests
- Clean abort of HTTP requests saves resources
- State consistency after cancel

**Reference**: [chat-architecture.md Section 5](../_base/004-braven-lab-studio-integration/decisions/chat-architecture.md)

---

## 12. Default System Prompt

### Decision: Package-Provided Default, Consumer Override

**What was chosen**:

- `defaultSystemPrompt` constant exported from package
- Consumers can provide custom prompt to `AgentSessionImpl`
- Default covers chart creation/modification guidance

**Rationale**:

- Works out-of-box for most use cases
- Extensible for custom scenarios
- No hardcoded business logic in provider layer

**Reference**: [004.1 Section 9.1](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md#91-default-system-prompt)

---

## Summary

All technical decisions are resolved. No NEEDS CLARIFICATION items remain. The implementation can proceed using:

1. **Authoritative Spec**: [004.1-braven-agent-extraction.md](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md) v5.1
2. **Architecture Guide**: [technical-design.md](../_base/004-braven-lab-studio-integration/technical-design.md)
3. **Decision Records**: [decisions/](../_base/004-braven-lab-studio-integration/decisions/)

All components implement fresh from specification except ChartRenderer and property wiring test (direct translation).
