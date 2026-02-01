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

/// OpenAI adapter implementing [LLMProvider].
///
/// Bridges between braven_agent's internal models and the OpenAI API
/// using HTTP requests.
///
/// ## Usage
///
/// ```dart
/// final config = LLMConfig(
///   apiKey: 'sk-...',
///   model: 'gpt-4o',
/// );
/// final adapter = OpenAIAdapter(config);
///
/// final response = await adapter.generateResponse(
///   systemPrompt: 'You are a helpful chart assistant.',
///   history: conversationHistory,
///   tools: [createChartTool],
/// );
/// ```
///
/// ## Registration
///
/// Register with [LLMRegistry] at app startup:
///
/// ```dart
/// LLMRegistry.register('openai', (config) => OpenAIAdapter(config));
/// ```
///
/// ## Supported Models (as of Feb 2026)
///
/// GPT-4o series:
/// - `gpt-4o` - Latest GPT-4o (128K context)
/// - `gpt-4o-mini` - Smaller, faster GPT-4o (128K context)
///
/// GPT-4 Turbo:
/// - `gpt-4-turbo` - GPT-4 Turbo (128K context)
/// - `gpt-4-turbo-preview` - Preview version
///
/// GPT-4:
/// - `gpt-4` - Original GPT-4 (8K context)
/// - `gpt-4-32k` - Extended context (32K)
///
/// GPT-3.5:
/// - `gpt-3.5-turbo` - Fast and cheap (16K context)
class OpenAIAdapter implements LLMProvider {
  /// The LLM configuration.
  final LLMConfig _config;

  /// The HTTP client for API requests.
  final http.Client _client;

  /// UUID generator for message IDs.
  static const _uuid = Uuid();

  /// Default OpenAI API base URL.
  static const String defaultBaseUrl = 'https://api.openai.com/v1';

  /// Default OpenAI model.
  static const String defaultModel = 'gpt-4o';

  /// Creates an [OpenAIAdapter] with the given configuration.
  ///
  /// The [config] must contain a valid API key.
  /// An optional [client] can be provided for testing purposes.
  OpenAIAdapter(this._config, {http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'openai';

  /// Returns the effective base URL for API requests.
  String get _baseUrl => _config.baseUrl ?? defaultBaseUrl;

  /// Enable debug logging to console.
  bool debugLogging = false;

  void _debugLog(String message) {
    if (debugLogging) {
      print('[OpenAIAdapter] $message');
    }
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

    // Debug: Log the messages being sent
    if (debugLogging) {
      final messages = requestBody['messages'] as List<dynamic>;
      _debugLog('=== SENDING ${messages.length} MESSAGES TO OPENAI ===');
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i] as Map<String, dynamic>;
        final role = msg['role'];
        final content = msg['content'];
        final toolCallId = msg['tool_call_id'];
        if (role == 'tool') {
          _debugLog('  [$i] TOOL RESULT (id: $toolCallId):');
          _debugLog('      ${content.toString().substring(0, content.toString().length.clamp(0, 300))}...');
        } else if (role == 'assistant' && msg['tool_calls'] != null) {
          _debugLog('  [$i] ASSISTANT with tool_calls: ${msg['tool_calls']}');
        } else {
          _debugLog('  [$i] $role: ${content?.toString().substring(0, (content?.toString().length ?? 0).clamp(0, 100)) ?? "(no content)"}...');
        }
      }
      _debugLog('=== END MESSAGES ===');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _buildHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        _throwApiError(response);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Debug: Log raw response
      if (debugLogging) {
        _debugLog('=== OPENAI RESPONSE ===');
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
        Uri.parse('$_baseUrl/chat/completions'),
      );
      request.headers.addAll(_buildHeaders());
      request.body = jsonEncode(requestBody);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        _throwApiErrorFromStream(streamedResponse.statusCode, body);
      }

      // Buffer for incomplete SSE lines
      String buffer = '';
      // Track current tool call state for streaming
      final toolCallBuffers = <int, _ToolCallBuffer>{};

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Process complete SSE lines
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.isEmpty) continue;
          if (line == 'data: [DONE]') {
            // Yield any complete tool calls
            for (final toolBuffer in toolCallBuffers.values) {
              if (toolBuffer.isComplete) {
                yield LLMChunk(
                  toolUse: ToolUseContent(
                    id: toolBuffer.id,
                    toolName: toolBuffer.name,
                    input: _parseToolInput(toolBuffer.arguments),
                  ),
                );
              }
            }
            yield const LLMChunk(isComplete: true);
            return;
          }

          if (!line.startsWith('data: ')) continue;

          final data = line.substring(6);
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final chunks = _parseStreamChunk(json, toolCallBuffers);
            for (final llmChunk in chunks) {
              yield llmChunk;
            }
          } catch (_) {
            // Skip malformed JSON in stream
          }
        }
      }
    } catch (error, stackTrace) {
      _throwMappedError(error, stackTrace);
    }
  }

  /// Builds HTTP headers for API requests.
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_config.apiKey}',
    };
  }

  /// Builds the request body for the OpenAI API.
  Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    required LLMConfig effectiveConfig,
    required bool stream,
  }) {
    final model = effectiveConfig.model == LLMConfig.defaultModel ? defaultModel : effectiveConfig.model;

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ..._convertMessages(history),
    ];

    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'max_tokens': effectiveConfig.maxTokens,
      'temperature': effectiveConfig.temperature,
      'stream': stream,
    };

    // Add tools if provided
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = _convertTools(tools);
      body['tool_choice'] = 'auto';
    }

    // Add provider-specific options
    final providerOptions = effectiveConfig.providerOptions ?? const {};
    if (providerOptions['top_p'] != null) {
      body['top_p'] = providerOptions['top_p'];
    }
    if (providerOptions['frequency_penalty'] != null) {
      body['frequency_penalty'] = providerOptions['frequency_penalty'];
    }
    if (providerOptions['presence_penalty'] != null) {
      body['presence_penalty'] = providerOptions['presence_penalty'];
    }

    return body;
  }

  /// Converts a list of [AgentTool] to OpenAI-compatible tool format.
  List<Map<String, dynamic>> _convertTools(List<AgentTool> tools) {
    return tools.map((tool) {
      return {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.inputSchema,
        },
      };
    }).toList();
  }

  /// Converts a list of [AgentMessage] to OpenAI-compatible message format.
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

  /// Converts a single [AgentMessage] to OpenAI-compatible message format.
  Map<String, dynamic>? _convertMessage(AgentMessage message) {
    // Skip system messages - they are handled separately
    if (message.role == MessageRole.system) {
      return null;
    }

    // Handle tool role (tool results)
    if (message.role == MessageRole.tool) {
      for (final content in message.content) {
        if (content is ToolResultContent) {
          // For OpenAI, prefix errors with clear instruction
          String outputContent = content.output;
          if (content.isError) {
            outputContent = 'ERROR: $outputContent\n\nPlease fix the issue and try again with corrected parameters.';
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
    if (message.role == MessageRole.assistant) {
      final contentParts = <Map<String, dynamic>>[];
      final toolCalls = <Map<String, dynamic>>[];

      for (final content in message.content) {
        switch (content) {
          case TextContent(:final text):
            contentParts.add({
              'type': 'text',
              'text': text,
            });
          case ToolUseContent(:final id, :final toolName, :final input):
            toolCalls.add({
              'id': id,
              'type': 'function',
              'function': {
                'name': toolName,
                'arguments': jsonEncode(input),
              },
            });
          default:
            // Skip unsupported content types
            continue;
        }
      }

      final result = <String, dynamic>{
        'role': 'assistant',
      };

      // Add content if present
      if (contentParts.isNotEmpty) {
        if (contentParts.length == 1 && contentParts.first['type'] == 'text') {
          result['content'] = contentParts.first['text'];
        } else {
          result['content'] = contentParts;
        }
      } else {
        // Tool-only messages need empty content
        result['content'] = null;
      }

      // Add tool calls if present
      if (toolCalls.isNotEmpty) {
        result['tool_calls'] = toolCalls;
      }

      return result;
    }

    // Handle user messages
    if (message.role == MessageRole.user) {
      final contentParts = <Map<String, dynamic>>[];

      for (final content in message.content) {
        switch (content) {
          case TextContent(:final text):
            contentParts.add({
              'type': 'text',
              'text': text,
            });
          case ImageContent(:final data, :final mediaType):
            contentParts.add({
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mediaType;base64,$data',
              },
            });
          case ToolResultContent(:final toolUseId, :final output):
            // Tool results from user role (shouldn't happen but handle gracefully)
            return {
              'role': 'tool',
              'tool_call_id': toolUseId,
              'content': output,
            };
          default:
            // Skip unsupported content types
            continue;
        }
      }

      if (contentParts.isEmpty) {
        return null;
      }

      // Simplify if only single text content
      if (contentParts.length == 1 && contentParts.first['type'] == 'text') {
        return {
          'role': 'user',
          'content': contentParts.first['text'],
        };
      }

      return {
        'role': 'user',
        'content': contentParts,
      };
    }

    return null;
  }

  /// Parses an API response into [LLMResponse].
  LLMResponse _parseResponse(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw Exception('No choices returned from OpenAI API');
    }

    final choice = choices.first as Map<String, dynamic>;
    final messageJson = choice['message'] as Map<String, dynamic>;
    final finishReason = choice['finish_reason'] as String?;

    final contentList = <MessageContent>[];

    // Parse text content
    final content = messageJson['content'];
    if (content != null && content is String && content.isNotEmpty) {
      contentList.add(TextContent(text: content));
    }

    // Parse tool calls
    final toolCalls = messageJson['tool_calls'] as List<dynamic>?;
    if (toolCalls != null) {
      for (final toolCall in toolCalls) {
        final tc = toolCall as Map<String, dynamic>;
        final function = tc['function'] as Map<String, dynamic>;
        contentList.add(ToolUseContent(
          id: tc['id'] as String,
          toolName: function['name'] as String,
          input: _parseToolInput(function['arguments'] as String),
        ));
      }
    }

    // Parse usage
    final usage = json['usage'] as Map<String, dynamic>?;
    final inputTokens = usage?['prompt_tokens'] as int? ?? 0;
    final outputTokens = usage?['completion_tokens'] as int? ?? 0;

    final message = AgentMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: contentList,
      timestamp: DateTime.now().toUtc(),
    );

    return LLMResponse(
      message: message,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      stopReason: _mapFinishReason(finishReason),
    );
  }

  /// Parses streaming chunks from the OpenAI API.
  List<LLMChunk> _parseStreamChunk(
    Map<String, dynamic> json,
    Map<int, _ToolCallBuffer> toolCallBuffers,
  ) {
    final chunks = <LLMChunk>[];
    final choices = json['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      return chunks;
    }

    final choice = choices.first as Map<String, dynamic>;
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

          // Initialize or update tool call buffer
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

  /// Maps OpenAI finish reason to standard stop reason.
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

    // Check for auth errors
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Invalid API key. Please check your OpenAI API key and try again.');
    }

    throw Exception('OpenAI API error: $message');
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

    // Check for auth errors
    if (statusCode == 401 || statusCode == 403) {
      throw Exception('Invalid API key. Please check your OpenAI API key and try again.');
    }

    throw Exception('OpenAI API error: $message');
  }

  /// Detects authentication error messages.
  String? _detectAuthErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    final isAuthError = message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('authentication') ||
        message.contains('invalid api key') ||
        message.contains('api key');

    if (!isAuthError) {
      return null;
    }

    return 'Invalid API key. Please check your OpenAI API key and try again.';
  }

  /// Throws a mapped error with proper stack trace.
  Never _throwMappedError(Object error, StackTrace stackTrace) {
    final authMessage = _detectAuthErrorMessage(error);
    if (authMessage != null) {
      Error.throwWithStackTrace(Exception(authMessage), stackTrace);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  /// Disposes the HTTP client.
  ///
  /// Call this when the adapter is no longer needed to release resources.
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
