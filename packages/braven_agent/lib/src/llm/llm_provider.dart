import '../tools/agent_tool.dart';
import 'llm_config.dart';
import 'llm_response.dart';
import 'models/agent_message.dart';

/// Abstract interface for LLM providers.
///
/// Defines the contract for communicating with Large Language Models.
/// Implementations handle provider-specific details (authentication,
/// request formatting, response parsing) while exposing a uniform API.
///
/// The LLMProvider is intentionally a "dumb pipe" with no business logic:
/// - Abstract interface decouples provider implementation from agent logic
/// - Adding new providers (OpenAI, Gemini) requires only new adapter + registration
/// - AgentSession doesn't change when switching providers
/// - Provider doesn't know about charts, athletes, or domain concepts
///
/// ## Implementing a Provider
///
/// ```dart
/// class AnthropicAdapter implements LLMProvider {
///   final LLMConfig _config;
///
///   AnthropicAdapter(this._config);
///
///   @override
///   String get id => 'anthropic';
///
///   @override
///   Future<LLMResponse> generateResponse({
///     required String systemPrompt,
///     required List<AgentMessage> history,
///     List<AgentTool>? tools,
///     LLMConfig? config,
///   }) async {
///     final effectiveConfig = config ?? _config;
///     // Make API call to Anthropic...
///     return LLMResponse(...);
///   }
///
///   @override
///   Stream<LLMChunk> streamResponse({
///     required String systemPrompt,
///     required List<AgentMessage> history,
///     List<AgentTool>? tools,
///     LLMConfig? config,
///   }) async* {
///     // Stream chunks from Anthropic API...
///     yield LLMChunk(textDelta: 'Hello');
///   }
/// }
/// ```
///
/// ## Registration
///
/// Providers are registered with [LLMRegistry] at app startup:
///
/// ```dart
/// LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));
/// final provider = LLMRegistry.create('anthropic', llmConfig);
/// ```
abstract class LLMProvider {
  /// Unique identifier for this provider.
  ///
  /// Used for registration and lookup in [LLMRegistry].
  /// Common values: 'anthropic', 'openai', 'gemini'.
  String get id;

  /// Generates a complete response from the LLM.
  ///
  /// Sends the conversation history to the LLM and waits for the
  /// full response. Use this for non-streaming scenarios or when
  /// you need the complete response before processing.
  ///
  /// Parameters:
  /// - [systemPrompt]: Instructions for the LLM's behavior and context.
  /// - [history]: Conversation history as a list of [AgentMessage] objects.
  /// - [tools]: Optional list of [AgentTool] definitions for tool calling.
  /// - [config]: Optional [LLMConfig] to override provider defaults.
  ///
  /// Returns an [LLMResponse] containing the generated message,
  /// token usage statistics, and stop reason.
  ///
  /// Throws on network errors or API failures.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final response = await provider.generateResponse(
  ///   systemPrompt: 'You are a helpful chart assistant.',
  ///   history: conversationHistory,
  ///   tools: [createChartTool, modifyChartTool],
  /// );
  /// print('Response: ${response.message}');
  /// ```
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  });

  /// Streams response chunks from the LLM.
  ///
  /// Sends the conversation history to the LLM and yields response
  /// chunks as they arrive. Use this for real-time UI updates during
  /// response generation.
  ///
  /// Parameters:
  /// - [systemPrompt]: Instructions for the LLM's behavior and context.
  /// - [history]: Conversation history as a list of [AgentMessage] objects.
  /// - [tools]: Optional list of [AgentTool] definitions for tool calling.
  /// - [config]: Optional [LLMConfig] to override provider defaults.
  ///
  /// Yields [LLMChunk] objects containing incremental text deltas,
  /// tool use requests, or completion signals.
  ///
  /// The final chunk has [LLMChunk.isComplete] set to `true` and
  /// may include a [LLMChunk.stopReason].
  ///
  /// ## Example
  ///
  /// ```dart
  /// await for (final chunk in provider.streamResponse(
  ///   systemPrompt: 'You are a helpful chart assistant.',
  ///   history: conversationHistory,
  /// )) {
  ///   if (chunk.textDelta != null) {
  ///     stdout.write(chunk.textDelta);
  ///   }
  ///   if (chunk.isComplete) {
  ///     print('\n--- Done: ${chunk.stopReason}');
  ///   }
  /// }
  /// ```
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  });
}
