# Decisions: Chat Stream Architecture

## 1. Core Abstraction: `AgentSession`

We will not just expose a "Stream of Messages". We will expose an `AgentSession` object that encapsulates the entire lifecycle of a chat interaction.

### Why not just Streams?

Chat is not just data flow; it has **State** (Idle, Thinking, Tool Execution) and **Control** (Cancel, Retry). A simple `Stream<Message>` is insufficient for "Stop generating" or "Retry this tool".

### The `AgentSession` API (Draft)

```dart
class AgentSession {
  // 1. The Single Truth
  // Provides the full history + current partial response + current tool execution status
  // Optimized for UI binding (Provider/Riverpod/Bloc friendly)
  ValueListenable<SessionState> get state;

  // 2. Transients
  // Events that don't need to be persisted but shown (toasts, debug logs)
  Stream<AgentEvent> get events;

  // 3. Controls
  Future<void> transform(String prompt); // Send user message
  Future<void> cancel(); // Stop current generation
  void dispose();
}
```

## 2. State Modeling (`SessionState`)

The state object must be **complete**. The UI should never have to guess or keep its own side-state.

```dart
class SessionState {
  final List<Message> history;      // Past turn
  final Message? pendingResponse;   // The message currently being streamed (typing...)
  final ToolCall? activeTool;       // If a tool is running, which one?
  final ActivityStatus status;      // idle, thinking, calling_tool, error

  /// The chart currently relevant to the conversation.
  /// 1. If Agent just created one, it's here.
  /// 2. If User selects one from history, it's here.
  /// 3. If User edits it, the updated version is here.
  final ChartConfig? activeChart;
}
```

## 3. Technology Choice: `ValueNotifier` vs `Stream`

**Decision:** We will use **`ValueNotifier` (or `ValueListenable`)** for the main State.

- **Why?** Flutter UIs are synchronous reflections of state. `ValueListenableBuilder` is built-in and highly efficient. Streams require `StreamBuilder` which handles async snapshots and connection states, adding unnecessary friction for synchronous state updates.
- **Streams** are reserved for _Transient Events_ (Logs, Toasts) that happen _at a point in time_ rather than _state over time_.

## 4. The "Thinking" UX Pattern

We will implement the **"Thought Stream"** pattern separate from the **"Content Stream"**.

- LLMs often emit "Thinking" separately from "Speaking".
- The `AgentEvent` stream will carry `ThinkingEvent("Analyzing columns...")`.
- The `SessionState.pendingResponse` will carry the actual text "I have analyzed the file...".
- This allows the UI to show a "Spinner with text" (Thinking) distinct from the "Typing Bubble" (Response).

## 5. Cancellation

Cancellation is non-negotiable.

- The `transform()` method returns a Future.
- Calling `cancel()` must immediately abort the underlying HTTP request (Anthropic) AND abort any running Tool logic.
- We will use `CancelToken` (from built-in or Dio) or `CancellationSignal` pattern within the `AgentSession` logic.
