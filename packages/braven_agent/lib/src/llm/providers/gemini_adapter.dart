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

/// Gemini (Google AI) adapter implementing [LLMProvider].
///
/// Bridges between braven_agent's internal models and the Google Gemini API.
///
/// ## Usage
///
/// ```dart
/// final config = LLMConfig(
///   apiKey: 'AIza...',
///   model: 'gemini-2.0-flash',
/// );
/// final adapter = GeminiAdapter(config);
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
/// LLMRegistry.register('gemini', (config) => GeminiAdapter(config));
/// ```
///
/// ## Supported Models (as of Feb 2026)
///
/// Gemini 3 (preview - Jan 2026):
/// - `gemini-3-pro-preview` - Most powerful agentic model
/// - `gemini-3-flash-preview` - Best for speed and scale
///
/// Gemini 2.5 (stable):
/// - `gemini-2.5-flash` - Best price-performance, agentic (default)
/// - `gemini-2.5-flash-lite` - Fastest, cost-efficient
/// - `gemini-2.5-pro` - Advanced thinking model
class GeminiAdapter implements LLMProvider {
  /// The LLM configuration.
  final LLMConfig _config;

  /// The HTTP client for API requests.
  final http.Client _client;

  /// UUID generator for message IDs.
  static const _uuid = Uuid();

  /// Default Gemini API base URL.
  static const String defaultBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Default Gemini model.
  static const String defaultModel = 'gemini-2.5-flash';

  /// Creates a [GeminiAdapter] with the given configuration.
  ///
  /// The [config] must contain a valid API key.
  /// An optional [client] can be provided for testing purposes.
  GeminiAdapter(this._config, {http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'gemini';

  /// Returns the effective base URL for API requests.
  String get _baseUrl => _config.baseUrl ?? defaultBaseUrl;

  /// Enable debug logging to console.
  bool debugLogging = false;

  void _debugLog(String message) {
    if (debugLogging) {
      print('[GeminiAdapter] $message');
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
    final model = effectiveConfig.model == LLMConfig.defaultModel ? defaultModel : effectiveConfig.model;
    final requestBody = _buildRequestBody(
      systemPrompt: systemPrompt,
      history: history,
      tools: tools,
      effectiveConfig: effectiveConfig,
    );

    // Debug: Log the messages being sent
    if (debugLogging) {
      final contents = requestBody['contents'] as List<dynamic>;
      _debugLog('=== SENDING ${contents.length} MESSAGES TO GEMINI ===');
      for (var i = 0; i < contents.length; i++) {
        final msg = contents[i] as Map<String, dynamic>;
        final role = msg['role'];
        final parts = msg['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final firstPart = parts.first as Map<String, dynamic>;
          if (firstPart.containsKey('functionResponse')) {
            final funcResp = firstPart['functionResponse'] as Map<String, dynamic>;
            _debugLog('  [$i] FUNCTION RESPONSE (${funcResp['name']}):');
            _debugLog('      ${jsonEncode(funcResp['response']).substring(0, 300.clamp(0, jsonEncode(funcResp['response']).length))}...');
          } else if (firstPart.containsKey('functionCall')) {
            final funcCall = firstPart['functionCall'] as Map<String, dynamic>;
            _debugLog('  [$i] FUNCTION CALL: ${funcCall['name']}');
          } else if (firstPart.containsKey('text')) {
            final text = firstPart['text'] as String;
            _debugLog('  [$i] $role: ${text.substring(0, text.length.clamp(0, 100))}...');
          }
        }
      }
      _debugLog('=== END MESSAGES ===');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/models/$model:generateContent?key=${_config.apiKey}'),
        headers: _buildHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        _throwApiError(response);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Debug: Log raw response
      if (debugLogging) {
        _debugLog('=== GEMINI RESPONSE ===');
        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = (candidates[0] as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
          if (content != null) {
            _debugLog('  Role: ${content['role']}');
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              _debugLog('  Parts: ${parts.length}');
              for (final part in parts) {
                final p = part as Map<String, dynamic>;
                if (p.containsKey('text')) {
                  _debugLog('    Text: ${(p['text'] as String).substring(0, (p['text'] as String).length.clamp(0, 100))}...');
                } else if (p.containsKey('functionCall')) {
                  _debugLog('    Function call: ${p['functionCall']}');
                }
              }
            }
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
    final model = effectiveConfig.model == LLMConfig.defaultModel ? defaultModel : effectiveConfig.model;
    final requestBody = _buildRequestBody(
      systemPrompt: systemPrompt,
      history: history,
      tools: tools,
      effectiveConfig: effectiveConfig,
    );

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/models/$model:streamGenerateContent?key=${_config.apiKey}&alt=sse'),
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

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Process complete SSE lines
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.isEmpty) continue;
          if (!line.startsWith('data: ')) continue;

          final data = line.substring(6);
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final chunks = _parseStreamChunk(json);
            for (final llmChunk in chunks) {
              yield llmChunk;
            }
          } catch (_) {
            // Skip malformed JSON in stream
          }
        }
      }

      yield const LLMChunk(isComplete: true);
    } catch (error, stackTrace) {
      _throwMappedError(error, stackTrace);
    }
  }

  /// Builds HTTP headers for API requests.
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  /// Builds the request body for the Gemini API.
  Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    required LLMConfig effectiveConfig,
  }) {
    final body = <String, dynamic>{
      'contents': _convertMessages(history),
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'generationConfig': {
        'maxOutputTokens': effectiveConfig.maxTokens,
        'temperature': effectiveConfig.temperature,
      },
    };

    // Add tools if provided
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations': _convertTools(tools),
        }
      ];
      body['toolConfig'] = {
        'functionCallingConfig': {
          'mode': 'AUTO',
        }
      };
    }

    // Add provider-specific options
    final providerOptions = effectiveConfig.providerOptions ?? const {};
    if (providerOptions['topP'] != null) {
      (body['generationConfig'] as Map<String, dynamic>)['topP'] = providerOptions['topP'];
    }
    if (providerOptions['topK'] != null) {
      (body['generationConfig'] as Map<String, dynamic>)['topK'] = providerOptions['topK'];
    }

    return body;
  }

  /// Converts a list of [AgentTool] to Gemini function declaration format.
  List<Map<String, dynamic>> _convertTools(List<AgentTool> tools) {
    return tools.map((tool) {
      return {
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.inputSchema,
      };
    }).toList();
  }

  /// Converts a list of [AgentMessage] to Gemini content format.
  List<Map<String, dynamic>> _convertMessages(List<AgentMessage> messages) {
    final result = <Map<String, dynamic>>[];

    for (final message in messages) {
      final converted = _convertMessage(message);
      if (converted != null) {
        result.addAll(converted);
      }
    }

    return result;
  }

  /// Converts a single [AgentMessage] to Gemini content format.
  /// Returns a list because tool results need separate messages.
  List<Map<String, dynamic>>? _convertMessage(AgentMessage message) {
    // Skip system messages - they are handled separately via systemInstruction
    if (message.role == MessageRole.system) {
      return null;
    }

    // Handle tool role (function responses)
    if (message.role == MessageRole.tool) {
      final results = <Map<String, dynamic>>[];
      for (final content in message.content) {
        if (content is ToolResultContent) {
          // Parse the output to get structured response
          dynamic responseData;
          try {
            responseData = jsonDecode(content.output);
          } catch (_) {
            // If not JSON, wrap as text
            responseData = {
              'result': content.output,
              'error': content.isError ? true : null,
            };
          }

          // For errors, wrap with error indicator
          if (content.isError) {
            responseData = {
              'error': true,
              'message': content.output,
              'instruction': 'Please fix the issue and try again with corrected parameters.',
            };
          }

          results.add({
            'role': 'user',
            'parts': [
              {
                'functionResponse': {
                  'name': content.toolName ?? 'unknown',
                  'response': responseData,
                }
              }
            ]
          });
        }
      }
      return results.isNotEmpty ? results : null;
    }

    // Handle assistant messages (model role in Gemini)
    if (message.role == MessageRole.assistant) {
      final parts = <Map<String, dynamic>>[];

      for (final content in message.content) {
        switch (content) {
          case TextContent(:final text):
            parts.add({'text': text});
          case ToolUseContent(:final toolName, :final input, :final providerMetadata):
            final functionCallPart = <String, dynamic>{
              'functionCall': {
                'name': toolName,
                'args': input,
              }
            };
            // Include thoughtSignature for Gemini 3 models (required for function calling)
            final thoughtSignature = providerMetadata?['thoughtSignature'] as String?;
            if (thoughtSignature != null) {
              functionCallPart['thoughtSignature'] = thoughtSignature;
            }
            parts.add(functionCallPart);
          default:
            // Skip unsupported content types
            continue;
        }
      }

      if (parts.isEmpty) {
        return null;
      }

      return [
        {
          'role': 'model',
          'parts': parts,
        }
      ];
    }

    // Handle user messages
    if (message.role == MessageRole.user) {
      final parts = <Map<String, dynamic>>[];

      for (final content in message.content) {
        switch (content) {
          case TextContent(:final text):
            parts.add({'text': text});
          case ImageContent(:final data, :final mediaType):
            parts.add({
              'inlineData': {
                'mimeType': mediaType,
                'data': data,
              }
            });
          default:
            // Skip unsupported content types
            continue;
        }
      }

      if (parts.isEmpty) {
        return null;
      }

      return [
        {
          'role': 'user',
          'parts': parts,
        }
      ];
    }

    return null;
  }

  /// Parses an API response into [LLMResponse].
  LLMResponse _parseResponse(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      // Check for prompt feedback (safety block)
      final promptFeedback = json['promptFeedback'] as Map<String, dynamic>?;
      if (promptFeedback != null) {
        final blockReason = promptFeedback['blockReason'] as String?;
        throw Exception('Gemini blocked the request: $blockReason');
      }
      throw Exception('No candidates returned from Gemini API');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final finishReason = candidate['finishReason'] as String?;

    final contentList = <MessageContent>[];

    if (content != null) {
      final parts = content['parts'] as List<dynamic>?;
      if (parts != null) {
        for (final part in parts) {
          final p = part as Map<String, dynamic>;

          // Parse text content
          if (p.containsKey('text')) {
            final text = p['text'] as String;
            if (text.isNotEmpty) {
              contentList.add(TextContent(text: text));
            }
          }

          // Parse function calls
          if (p.containsKey('functionCall')) {
            final funcCall = p['functionCall'] as Map<String, dynamic>;
            // Capture thoughtSignature for Gemini 3 models (required for function calling)
            final thoughtSignature = p['thoughtSignature'] as String?;
            contentList.add(ToolUseContent(
              id: _uuid.v4(), // Gemini doesn't provide IDs, generate one
              toolName: funcCall['name'] as String,
              input: (funcCall['args'] as Map<String, dynamic>?) ?? {},
              providerMetadata: thoughtSignature != null ? {'thoughtSignature': thoughtSignature} : null,
            ));
          }
        }
      }
    }

    // Parse usage
    final usageMetadata = json['usageMetadata'] as Map<String, dynamic>?;
    final inputTokens = usageMetadata?['promptTokenCount'] as int? ?? 0;
    final outputTokens = usageMetadata?['candidatesTokenCount'] as int? ?? 0;

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

  /// Parses streaming chunks from the Gemini API.
  List<LLMChunk> _parseStreamChunk(Map<String, dynamic> json) {
    final chunks = <LLMChunk>[];
    final candidates = json['candidates'] as List<dynamic>?;

    if (candidates == null || candidates.isEmpty) {
      return chunks;
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final finishReason = candidate['finishReason'] as String?;

    if (content != null) {
      final parts = content['parts'] as List<dynamic>?;
      if (parts != null) {
        for (final part in parts) {
          final p = part as Map<String, dynamic>;

          // Handle text content
          if (p.containsKey('text')) {
            final text = p['text'] as String;
            if (text.isNotEmpty) {
              chunks.add(LLMChunk(textDelta: text));
            }
          }

          // Handle function calls
          if (p.containsKey('functionCall')) {
            final funcCall = p['functionCall'] as Map<String, dynamic>;
            // Capture thoughtSignature for Gemini 3 models (required for function calling)
            final thoughtSignature = p['thoughtSignature'] as String?;
            chunks.add(LLMChunk(
              toolUse: ToolUseContent(
                id: _uuid.v4(),
                toolName: funcCall['name'] as String,
                input: (funcCall['args'] as Map<String, dynamic>?) ?? {},
                providerMetadata: thoughtSignature != null ? {'thoughtSignature': thoughtSignature} : null,
              ),
            ));
          }
        }
      }
    }

    // Handle finish reason
    if (finishReason != null && finishReason != 'STOP') {
      chunks.add(LLMChunk(
        isComplete: true,
        stopReason: _mapFinishReason(finishReason),
      ));
    }

    return chunks;
  }

  /// Maps Gemini finish reason to standard stop reason.
  String? _mapFinishReason(String? reason) {
    if (reason == null) return null;
    return switch (reason) {
      'STOP' => 'end_turn',
      'MAX_TOKENS' => 'max_tokens',
      'SAFETY' => 'content_filter',
      'RECITATION' => 'content_filter',
      'OTHER' => 'other',
      _ => reason.toLowerCase(),
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
    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 400) {
      if (message.toLowerCase().contains('api key') || message.toLowerCase().contains('api_key')) {
        throw Exception('Invalid API key. Please check your Gemini API key and try again.');
      }
    }

    throw Exception('Gemini API error: $message');
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
    if (statusCode == 401 || statusCode == 403 || statusCode == 400) {
      if (message.toLowerCase().contains('api key') || message.toLowerCase().contains('api_key')) {
        throw Exception('Invalid API key. Please check your Gemini API key and try again.');
      }
    }

    throw Exception('Gemini API error: $message');
  }

  /// Detects authentication error messages.
  String? _detectAuthErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    final isAuthError = message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('authentication') ||
        message.contains('invalid api key') ||
        message.contains('api key') ||
        message.contains('api_key');

    if (!isAuthError) {
      return null;
    }

    return 'Invalid API key. Please check your Gemini API key and try again.';
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
