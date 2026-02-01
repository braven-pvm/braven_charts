import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../tools/agent_tool.dart';
import '../llm_config.dart';
import '../llm_provider.dart';
import '../llm_response.dart';
import '../models/agent_message.dart';
import '../models/message_content.dart';

/// Grok Responses API adapter implementing [LLMProvider].
///
/// This adapter uses xAI's `/v1/responses` endpoint instead of the
/// OpenAI-compatible `/v1/chat/completions`. The Responses API supports
/// a **hybrid client-server mode** that works much better for agentic
/// tool calling workflows.
///
/// ## Hybrid Mode Benefits
///
/// - Server-side handles agentic reasoning and loops
/// - Custom tools get returned to client for local execution
/// - Results are sent back with `previous_response_id` for context
/// - More reliable tool error handling than `/v1/chat/completions`
///
/// ## Key Differences from GrokAdapter
///
/// | Feature | GrokAdapter (chat/completions) | GrokResponsesAdapter (responses) |
/// |---------|-------------------------------|----------------------------------|
/// | Endpoint | `/v1/chat/completions` | `/v1/responses` |
/// | Messages key | `messages` | `input` |
/// | Continuations | Full history resent | `previous_response_id` |
/// | Agentic mode | Client-side loop | Server-side with custom tool returns |
///
/// ## Usage
///
/// ```dart
/// final config = LLMConfig(
///   apiKey: 'xai-...',
///   model: 'grok-4-1-fast',
/// );
/// final adapter = GrokResponsesAdapter(config);
///
/// final response = await adapter.generateResponse(
///   systemPrompt: 'You are a helpful chart assistant.',
///   history: conversationHistory,
///   tools: [createChartTool],
/// );
/// ```
///
/// ## Supported Models
///
/// - `grok-4-1-fast` - Recommended for agentic mode (default)
/// - `grok-4-1-fast-reasoning` - With extended reasoning
/// - `grok-4-1-fast-non-reasoning` - Faster, less reasoning depth
///
/// ## References
///
/// - https://docs.x.ai/docs/guides/chat (Responses API overview)
/// - https://docs.x.ai/docs/guides/tools/overview (Tools guide)
class GrokResponsesAdapter implements LLMProvider {
  /// The LLM configuration.
  final LLMConfig _config;

  /// The HTTP client for API requests.
  final http.Client _client;

  /// UUID generator for message IDs.
  static const _uuid = Uuid();

  /// Default Grok API base URL.
  static const String defaultBaseUrl = 'https://api.x.ai/v1';

  /// Default Grok model for Responses API.
  static const String defaultModel = 'grok-4-1-fast';

  /// Previous response ID for stateful conversations.
  String? _previousResponseId;

  /// Creates a [GrokResponsesAdapter] with the given configuration.
  ///
  /// The [config] must contain a valid API key.
  /// An optional [client] can be provided for testing purposes.
  GrokResponsesAdapter(this._config, {http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'grok-responses';

  /// Returns the effective base URL for API requests.
  String get _baseUrl => _config.baseUrl ?? defaultBaseUrl;

  /// Enable debug logging to console.
  bool debugLogging = false;

  /// Maximum agentic turns (limits server-side loops).
  int maxTurns = 5;

  void _debugLog(String message) {
    if (debugLogging) {
      // ignore: avoid_print
      print('[GrokResponses] $message');
    }
  }

  /// Clears the conversation state.
  ///
  /// Call this to start a fresh conversation without prior context.
  void clearConversation() {
    _previousResponseId = null;
  }

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    final effectiveConfig = config ?? _config;
    final requestBody = _buildRequestBody(
      systemPrompt: systemPrompt,
      history: history,
      tools: tools,
      effectiveConfig: effectiveConfig,
      stream: false,
    );

    if (debugLogging) {
      final input = requestBody['input'] as List<dynamic>;
      _debugLog('=== SENDING TO /v1/responses ===');
      _debugLog('  Model: ${requestBody['model']}');
      _debugLog('  Previous Response ID: ${requestBody['previous_response_id'] ?? 'none'}');
      _debugLog('  Max Turns: ${requestBody['max_turns']}');
      _debugLog('  Input messages: ${input.length}');
      for (var i = 0; i < input.length; i++) {
        final msg = input[i] as Map<String, dynamic>;
        final role = msg['role'];
        final content = msg['content'];
        final toolCallId = msg['tool_call_id'];
        if (role == 'tool') {
          _debugLog('    [$i] TOOL RESULT (id: $toolCallId):');
          _debugLog('        ${content.toString().substring(0, content.toString().length.clamp(0, 200))}...');
        } else {
          _debugLog('    [$i] $role: ${content?.toString().substring(0, (content?.toString().length ?? 0).clamp(0, 100)) ?? "(no content)"}...');
        }
      }
      _debugLog('=== END REQUEST ===');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/responses'),
        headers: _buildHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        _throwApiError(response);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Store response ID for continuations
      final responseId = json['id'] as String?;
      if (responseId != null) {
        _previousResponseId = responseId;
        _debugLog('  Stored response ID: $responseId');
      }

      if (debugLogging) {
        _debugLog('=== GROK RESPONSE ===');
        _debugLog('  Response ID: ${json['id']}');
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
          if (message != null) {
            _debugLog('  Role: ${message['role']}');
            _debugLog(
                '  Content: ${message['content']?.toString().substring(0, (message['content']?.toString().length ?? 0).clamp(0, 200)) ?? "null"}');
            _debugLog('  Tool calls: ${message['tool_calls']}');
          }
        }
        _debugLog('=== END RESPONSE ===');
      }

      return _parseResponse(json);
    } catch (error, stackTrace) {
      _throwMappedError(error, stackTrace);
    }
  }

  @override
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async* {
    final effectiveConfig = config ?? _config;
    final requestBody = _buildRequestBody(
      systemPrompt: systemPrompt,
      history: history,
      tools: tools,
      effectiveConfig: effectiveConfig,
      stream: true,
    );

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/responses'),
      );
      request.headers.addAll(_buildHeaders());
      request.body = jsonEncode(requestBody);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        _throwApiErrorFromStream(streamedResponse.statusCode, body);
      }

      // Buffer for incomplete SSE lines and tool call accumulation
      String buffer = '';
      final toolCallBuffers = <int, _ToolCallBuffer>{};

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Process complete lines
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.isEmpty || !line.startsWith('data: ')) {
            continue;
          }

          final data = line.substring(6);
          if (data == '[DONE]') {
            yield const LLMChunk(isComplete: true, stopReason: 'end_turn');
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final chunks = _parseStreamChunk(json, toolCallBuffers);
            for (final chunk in chunks) {
              yield chunk;
            }

            // Store response ID if present
            final responseId = json['id'] as String?;
            if (responseId != null) {
              _previousResponseId = responseId;
            }
          } catch (_) {
            // Skip malformed chunks
            continue;
          }
        }
      }
    } catch (error, stackTrace) {
      _throwMappedError(error, stackTrace);
    }
  }

  /// Builds the request headers.
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_config.apiKey}',
    };
  }

  /// Builds the request body for the Responses API.
  Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    required LLMConfig effectiveConfig,
    required bool stream,
  }) {
    final model = effectiveConfig.model == LLMConfig.defaultModel ? defaultModel : effectiveConfig.model;

    // Build input messages
    final input = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ..._convertMessages(history),
    ];

    final body = <String, dynamic>{
      'model': model,
      'input': input, // Responses API uses 'input' not 'messages'
      'stream': stream,
      'max_turns': maxTurns, // Limit agentic loops
    };

    // Use previous_response_id for continuations if available
    // But only if we're not sending full history (for tool results)
    // The API handles stateful context via response_id
    if (_previousResponseId != null && _hasToolResult(history)) {
      body['previous_response_id'] = _previousResponseId;
    }

    // Add tools if provided
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = _convertTools(tools);
      body['tool_choice'] = 'auto';
    }

    // Add provider-specific options
    final providerOptions = effectiveConfig.providerOptions ?? const {};
    if (providerOptions['temperature'] != null) {
      body['temperature'] = providerOptions['temperature'];
    }

    return body;
  }

  /// Checks if history contains a tool result (for continuations).
  bool _hasToolResult(List<AgentMessage> history) {
    return history.any((msg) => msg.role == MessageRole.tool || msg.content.any((c) => c is ToolResultContent));
  }

  /// Converts a list of [AgentTool] to Responses API tool format.
  ///
  /// The Responses API uses a FLAT structure with `name`, `description`, and
  /// `parameters` at the tool level (OpenResponses format), NOT nested inside
  /// a `function` object like Chat Completions API.
  ///
  /// Reference: https://docs.x.ai/docs/api-reference (Responses API)
  List<Map<String, dynamic>> _convertTools(List<AgentTool> tools) {
    return tools.map((tool) {
      return {
        'type': 'function',
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.inputSchema,
      };
    }).toList();
  }

  /// Converts a list of [AgentMessage] to Responses API message format.
  List<Map<String, dynamic>> _convertMessages(List<AgentMessage> messages) {
    final result = <Map<String, dynamic>>[];

    for (final message in messages) {
      final converted = _convertMessage(message);
      if (converted != null) {
        result.add(converted);
      }
    }

    return result;
  }

  /// Converts a single [AgentMessage] to Responses API message format.
  Map<String, dynamic>? _convertMessage(AgentMessage message) {
    // Skip system messages - they are handled separately
    if (message.role == MessageRole.system) {
      return null;
    }

    // Handle tool role (tool results)
    // xAI Responses API uses Chat Completions message format for input array
    // Reference: https://grok.com/share/bGVnYWN5_bdb69e54-e4a4-445a-a6b9-ad6202ca0b49
    if (message.role == MessageRole.tool) {
      for (final content in message.content) {
        if (content is ToolResultContent) {
          String outputContent = content.output;
          if (content.isError) {
            outputContent = 'ERROR: $outputContent';
          }
          return {
            'role': 'tool',
            'tool_call_id': content.toolUseId,
            'content': outputContent,
          };
        }
      }
      return null;
    }

    // Handle assistant messages
    // xAI Responses API uses Chat Completions format for tool_calls
    if (message.role == MessageRole.assistant) {
      final toolCalls = <Map<String, dynamic>>[];
      String? textContent;

      for (final content in message.content) {
        switch (content) {
          case TextContent(:final text):
            textContent = text;
          case ToolUseContent(:final id, :final toolName, :final input):
            // Chat Completions format: nested 'function' object
            toolCalls.add({
              'id': id,
              'type': 'function',
              'function': {
                'name': toolName,
                'arguments': jsonEncode(input),
              },
            });
          default:
            continue;
        }
      }

      final result = <String, dynamic>{
        'role': 'assistant',
        'content': textContent,
      };

      if (toolCalls.isNotEmpty) {
        result['tool_calls'] = toolCalls;
      }

      return result;
    }

    // Handle user messages
    if (message.role == MessageRole.user) {
      final contentParts = <String>[];

      for (final content in message.content) {
        if (content is TextContent) {
          contentParts.add(content.text);
        }
        // Note: Responses API may have different image handling
        // For now, just use text content
      }

      if (contentParts.isEmpty) {
        return null;
      }

      return {
        'role': 'user',
        'content': contentParts.join('\n'),
      };
    }

    return null;
  }

  /// Parses the API response into an [LLMResponse].
  ///
  /// The Responses API in hybrid mode returns `choices[0].message` format
  /// (same as Chat Completions), as documented in the xAI Responses API guide.
  /// We also handle `output[]` format for compatibility with pure agentic mode.
  ///
  /// Reference: https://grok.com/share/bGVnYWN5_bdb69e54-e4a4-445a-a6b9-ad6202ca0b49
  LLMResponse _parseResponse(Map<String, dynamic> json) {
    // Try choices format first (hybrid mode uses this)
    final choices = json['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      return _parseChoicesFormat(json, choices);
    }

    // Fallback to output format (pure agentic mode)
    final output = json['output'] as List<dynamic>?;
    if (output != null && output.isNotEmpty) {
      return _parseOutputFormat(json, output);
    }

    // Empty response
    return LLMResponse(
      message: AgentMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: const [],
        timestamp: DateTime.now().toUtc(),
      ),
      inputTokens: 0,
      outputTokens: 0,
      stopReason: 'end_turn',
    );
  }

  /// Parses the `choices[]` format response (used by hybrid mode).
  LLMResponse _parseChoicesFormat(Map<String, dynamic> json, List<dynamic> choices) {
    final choice = choices[0] as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>?;
    final finishReason = choice['finish_reason'] as String?;

    final content = <MessageContent>[];

    if (message != null) {
      // Parse text content
      final textContent = message['content'] as String?;
      if (textContent != null && textContent.isNotEmpty) {
        content.add(TextContent(text: textContent));
      }

      // Parse tool calls
      final toolCalls = message['tool_calls'] as List<dynamic>?;
      if (toolCalls != null) {
        for (final tc in toolCalls) {
          final toolCall = tc as Map<String, dynamic>;
          final id = toolCall['id'] as String?;
          final function = toolCall['function'] as Map<String, dynamic>?;

          if (id != null && function != null) {
            final name = function['name'] as String?;
            final argumentsStr = function['arguments'] as String?;

            if (name != null) {
              Map<String, dynamic> arguments;
              try {
                arguments = argumentsStr != null ? jsonDecode(argumentsStr) as Map<String, dynamic> : {};
              } catch (_) {
                arguments = {};
              }

              content.add(ToolUseContent(
                id: id,
                toolName: name,
                input: arguments,
              ));
            }
          }
        }
      }
    }

    // Parse usage
    final usage = json['usage'] as Map<String, dynamic>?;
    final inputTokens = usage?['prompt_tokens'] as int? ?? usage?['input_tokens'] as int? ?? 0;
    final outputTokens = usage?['completion_tokens'] as int? ?? usage?['output_tokens'] as int? ?? 0;

    final agentMessage = AgentMessage(
      id: json['id'] as String? ?? _uuid.v4(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now().toUtc(),
    );

    // Determine stop reason based on content
    final String stopReason;
    if (content.any((c) => c is ToolUseContent)) {
      stopReason = 'tool_use';
    } else {
      stopReason = _mapFinishReason(finishReason) ?? 'end_turn';
    }

    return LLMResponse(
      message: agentMessage,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      stopReason: stopReason,
      responseId: json['id'] as String?,
    );
  }

  /// Parses the `output[]` format response (used by pure agentic mode).
  LLMResponse _parseOutputFormat(Map<String, dynamic> json, List<dynamic> output) {
    final content = <MessageContent>[];
    String? finishReason;

    // Process all output items
    for (final outputItem in output) {
      final item = outputItem as Map<String, dynamic>;
      final itemType = item['type'] as String?;
      final status = item['status'] as String?;

      if (status == 'completed') {
        finishReason = 'stop';
      }

      if (itemType == 'message') {
        // Message contains content array
        final contentList = item['content'] as List<dynamic>?;
        if (contentList != null) {
          for (final contentItem in contentList) {
            final ci = contentItem as Map<String, dynamic>;
            final contentType = ci['type'] as String?;

            if (contentType == 'output_text') {
              // Text content
              final text = ci['text'] as String?;
              if (text != null && text.isNotEmpty) {
                content.add(TextContent(text: text));
              }
            }
          }
        }
      } else if (itemType == 'function_call') {
        // Tool call item
        final callId = item['call_id'] as String? ?? item['id'] as String?;
        final name = item['name'] as String?;
        final argumentsStr = item['arguments'] as String?;

        if (callId != null && name != null) {
          Map<String, dynamic> arguments;
          try {
            arguments = argumentsStr != null ? jsonDecode(argumentsStr) as Map<String, dynamic> : {};
          } catch (_) {
            arguments = {};
          }

          content.add(ToolUseContent(
            id: callId,
            toolName: name,
            input: arguments,
          ));
          finishReason = 'tool_use';
        }
      }
    }

    // Parse usage - Responses API format
    final usage = json['usage'] as Map<String, dynamic>?;
    final inputTokens = usage?['input_tokens'] as int? ?? 0;
    final outputTokens = usage?['output_tokens'] as int? ?? 0;

    final agentMessage = AgentMessage(
      id: json['id'] as String? ?? _uuid.v4(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now().toUtc(),
    );

    return LLMResponse(
      message: agentMessage,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      stopReason: _mapFinishReason(finishReason),
      responseId: json['id'] as String?,
    );
  }

  /// Parses a streaming chunk into [LLMChunk] objects.
  List<LLMChunk> _parseStreamChunk(
    Map<String, dynamic> json,
    Map<int, _ToolCallBuffer> toolCallBuffers,
  ) {
    final chunks = <LLMChunk>[];
    final choices = json['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      return chunks;
    }

    final choice = choices[0] as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    final finishReason = choice['finish_reason'] as String?;

    if (delta != null) {
      // Handle text content delta
      final content = delta['content'] as String?;
      if (content != null && content.isNotEmpty) {
        chunks.add(LLMChunk(textDelta: content));
      }

      // Handle tool call deltas
      final toolCalls = delta['tool_calls'] as List<dynamic>?;
      if (toolCalls != null) {
        for (final toolCall in toolCalls) {
          final tc = toolCall as Map<String, dynamic>;
          final index = tc['index'] as int? ?? 0;
          final id = tc['id'] as String?;
          final function = tc['function'] as Map<String, dynamic>?;

          if (!toolCallBuffers.containsKey(index)) {
            toolCallBuffers[index] = _ToolCallBuffer();
          }
          final buffer = toolCallBuffers[index]!;

          if (id != null) {
            buffer.id = id;
          }
          if (function != null) {
            final name = function['name'] as String?;
            final arguments = function['arguments'] as String?;
            if (name != null) {
              buffer.name = name;
            }
            if (arguments != null) {
              buffer.arguments += arguments;
            }
          }
        }
      }
    }

    // Handle finish reason
    if (finishReason != null) {
      // Yield complete tool calls when finishing
      if (finishReason == 'tool_calls') {
        for (final buffer in toolCallBuffers.values) {
          if (buffer.isComplete) {
            chunks.add(LLMChunk(
              toolUse: ToolUseContent(
                id: buffer.id,
                toolName: buffer.name,
                input: _parseToolInput(buffer.arguments),
              ),
            ));
          }
        }
        toolCallBuffers.clear();
      }

      chunks.add(LLMChunk(
        isComplete: finishReason == 'stop' || finishReason == 'tool_calls',
        stopReason: _mapFinishReason(finishReason),
      ));
    }

    return chunks;
  }

  /// Parses tool input from JSON string.
  Map<String, dynamic> _parseToolInput(String arguments) {
    if (arguments.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(arguments) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Maps Grok finish reason to standard stop reason.
  String? _mapFinishReason(String? reason) {
    if (reason == null) return null;
    return switch (reason) {
      'stop' => 'end_turn',
      'length' => 'max_tokens',
      'tool_calls' => 'tool_use',
      'content_filter' => 'content_filter',
      _ => reason,
    };
  }

  /// Throws an API error from a non-streaming response.
  Never _throwApiError(http.Response response) {
    final body = response.body;
    String message;

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      message = error?['message'] as String? ?? 'Unknown API error';
    } catch (_) {
      message = 'API error: ${response.statusCode}';
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Invalid API key. Please check your Grok API key and try again.');
    }

    throw Exception('Grok Responses API error: $message');
  }

  /// Throws an API error from a streaming response.
  Never _throwApiErrorFromStream(int statusCode, String body) {
    String message;

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      message = error?['message'] as String? ?? 'Unknown API error';
    } catch (_) {
      message = 'API error: $statusCode';
    }

    if (statusCode == 401 || statusCode == 403) {
      throw Exception('Invalid API key. Please check your Grok API key and try again.');
    }

    throw Exception('Grok Responses API error: $message');
  }

  /// Throws a mapped error with proper stack trace.
  Never _throwMappedError(Object error, StackTrace stackTrace) {
    final message = error.toString().toLowerCase();
    final isAuthError = message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('authentication') ||
        message.contains('invalid api key');

    if (isAuthError) {
      Error.throwWithStackTrace(
        Exception('Invalid API key. Please check your Grok API key and try again.'),
        stackTrace,
      );
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}

/// Buffer for accumulating streaming tool call data.
class _ToolCallBuffer {
  String id = '';
  String name = '';
  String arguments = '';

  bool get isComplete => id.isNotEmpty && name.isNotEmpty;
}
