# Decision: LLM Architecture & Provider Extensibility

**Status:** Draft
**Context:** Spec 004.1 (BravenAgent Package)
**Date:** 2026-01-28

## 1. Objective

To define a robust, extensible LLM interaction layer for the `braven_agent` package that:

1.  **Decouples** the provider implementation (Anthropic, OpenAI, etc.) from the agent logic.
2.  **Standardizes** the message and tool-calling format across different underlying APIs.
3.  **Removes** business logic (system prompts, BCP specifics) from the low-level provider classes.

## 2. Core Abstractions

### 2.1 The Provider Interface

The `LLMProvider` is a dumb pipe. It takes a conversation history and tools, and returns a response. It does _not_ know about charts, athletes, or creating files.

```dart
abstract class LLMProvider {
  String get id; // e.g., 'anthropic-sonnet-3.5'

  /// Sends a complete conversation state to the LLM.
  ///
  /// [systemPrompt]: The global instruction (injected by AgentController).
  /// [history]: List of previous messages.
  /// [tools]: Available function definitions.
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  });

  /// Streams the response for real-time UI.
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  });
}
```

### 2.2 Data Models

We define our own neutral models to avoid leaking SDK-specific objects (like `anthropic.Message`) into the app.

**AgentMessage:**

```dart
enum MessageRole { user, assistant, system, tool }

class AgentMessage {
  final String id;
  final MessageRole role;
  final List<MessageContent> content; // Supports mixed text/image/tool_use
  final Map<String, dynamic> metadata;
}
```

**MessageContent:**

```dart
abstract class MessageContent {}

class TextContent extends MessageContent {
  final String text;
}

class ImageContent extends MessageContent {
  final String base64Data;
  final String mediaType;
}

class BinaryContent extends MessageContent {
  final List<int> data;
  final String mimeType;
  final String? filename;
  // Rationale: Preserves metadata (filename is crucial for LLM context).
  // Providers decide handling:
  // - text/* -> Decode to TextContent
  // - image/* -> Convert to ImageContent or generic image
  // - application/pdf -> Extract text (if supported) or upload
  // - Other -> Reject or summarize via Tool interaction
}

class ToolUseContent extends MessageContent {
  final String id;
  final String toolName;
  final Map<String, dynamic> input;
}

class ToolResultContent extends MessageContent {
  final String toolUseId;
  final String output; // JSON string or plain text
  final bool isError;
}
```

## 3. Configuration & Registry

To support "extensibility from the start," we use a Registry pattern.

```dart
class LLMRegistry {
  static final Map<String, LLMProviderFactory> _factories = {};

  static void register(String id, LLMProviderFactory factory) { ... }

  static LLMProvider create(String id, LLMConfig config) { ... }
}
```

**Configuration Object:**

```dart
class LLMConfig {
  final String apiKey;
  final String? baseUrl;
  final double temperature;
  final int maxTokens;
  final Map<String, dynamic> providerOptions; // e.g., top_k, top_p
}
```

## 4. Migration from `lib/src/agentic`

### 4.1 Refactoring `AnthropicProvider`

**Current State:**

- Hardcoded `_chartSystemPrompt`.
- Imports `chart_configuration.dart`.
- Manages strict specific tools.

**New State:**

- **Remove** `_chartSystemPrompt`. The prompt comes from `AgentSession`.
- **Remove** BCP imports. The provider only deals with JSON/Text.
- **Generic Tool Mapping:** Convert `AgentTool` (our definition) -> `anthropic.Tool` (SDK definition) dynamically.

### 4.2 Handling Tools

Current `LLMTool` class is good but needs to ensure `inputSchema` is strictly typed to generic Maps, not bound to specific validation logic inside the definition if possible (validation happens at execution).

## 5. Extensibility Strategy (The "OpenAI Ready" check)

The schema above supports OpenAI's Chat Completion API structure:

1.  `AgentMessage` maps to OpenAI `messages` array.
2.  `ToolUseContent` maps to `function_call` / `tool_calls`.
3.  `ImageContent` maps to `gpt-4-vision` input format.

By strictly enforcing this middle layer, adding `OpenAIProvider` is just implementing one class that maps `AgentMessage` <-> `OpenAI Request/Response`.

## 6. Context Window Management

Since we deal with CSV/FIT data, we must handle token limits. This logic lives in the **Agent Layer**, not the **Provider Layer**.

1.  **Summarization:** `AgentSession` calculates token count.
2.  **Pruning:** If `history` > context limit, `AgentSession` summarizes or drops old messages _before_ calling `provider.generateResponse()`.
3.  **The Provider just sends what it is given.**
