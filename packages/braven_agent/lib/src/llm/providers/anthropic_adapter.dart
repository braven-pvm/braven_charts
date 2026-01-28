import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:uuid/uuid.dart';

import '../../tools/agent_tool.dart';
import '../llm_config.dart';
import '../llm_provider.dart';
import '../llm_response.dart';
import '../models/agent_message.dart';
import '../models/message_content.dart';

/// Anthropic Claude adapter implementing [LLMProvider].
///
/// Bridges between braven_agent's internal models and the Anthropic API
/// using the anthropic_sdk_dart package.
///
/// ## Usage
///
/// ```dart
/// final config = LLMConfig(apiKey: 'sk-...');
/// final adapter = AnthropicAdapter(config);
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
/// LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));
/// ```
class AnthropicAdapter implements LLMProvider {
  /// The LLM configuration.
  final LLMConfig _config;

  /// The Anthropic client instance.
  final anthropic.AnthropicClient _client;

  /// UUID generator for message IDs.
  static const _uuid = Uuid();

  /// Creates an [AnthropicAdapter] with the given configuration.
  ///
  /// The [config] must contain a valid API key.
  /// An optional [client] can be provided for testing purposes.
  AnthropicAdapter(this._config, {anthropic.AnthropicClient? client})
      : _client = client ??
            anthropic.AnthropicClient(
              apiKey: _config.apiKey,
              baseUrl: _config.baseUrl,
            );

  @override
  String get id => 'anthropic';

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    final effectiveConfig = config ?? _config;

    final request = anthropic.CreateMessageRequest(
      model: anthropic.Model.modelId(effectiveConfig.model),
      maxTokens: effectiveConfig.maxTokens,
      system: anthropic.CreateMessageRequestSystem.text(systemPrompt),
      messages: _convertMessages(history),
      tools: tools != null && tools.isNotEmpty ? _convertTools(tools) : null,
      toolChoice: tools != null && tools.isNotEmpty ? const anthropic.ToolChoice(type: anthropic.ToolChoiceType.auto) : null,
    );

    final response = await _client.createMessage(request: request);

    return _convertResponse(response);
  }

  @override
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async* {
    final effectiveConfig = config ?? _config;

    final request = anthropic.CreateMessageRequest(
      model: anthropic.Model.modelId(effectiveConfig.model),
      maxTokens: effectiveConfig.maxTokens,
      system: anthropic.CreateMessageRequestSystem.text(systemPrompt),
      messages: _convertMessages(history),
      tools: tools != null && tools.isNotEmpty ? _convertTools(tools) : null,
      toolChoice: tools != null && tools.isNotEmpty ? const anthropic.ToolChoice(type: anthropic.ToolChoiceType.auto) : null,
    );

    final stream = _client.createMessageStream(request: request);

    await for (final event in stream) {
      final chunk = _convertStreamEvent(event);
      if (chunk != null) {
        yield chunk;
      }
    }
  }

  /// Converts a list of [AgentTool] to Anthropic tool format.
  ///
  /// Each tool's [inputSchema] is mapped to the Anthropic tool schema format.
  List<anthropic.Tool> _convertTools(List<AgentTool> tools) {
    return tools.map((tool) {
      return anthropic.Tool.custom(
        name: tool.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
      );
    }).toList();
  }

  /// Converts a list of [AgentMessage] to Anthropic message format.
  ///
  /// Handles different message roles and content types:
  /// - User messages with text or tool results
  /// - Assistant messages with text or tool use requests
  List<anthropic.Message> _convertMessages(List<AgentMessage> messages) {
    final result = <anthropic.Message>[];

    for (final message in messages) {
      final anthropicMessage = _convertMessage(message);
      if (anthropicMessage != null) {
        result.add(anthropicMessage);
      }
    }

    return result;
  }

  /// Converts a single [AgentMessage] to Anthropic message format.
  ///
  /// Returns null for system messages (handled separately in the API call).
  anthropic.Message? _convertMessage(AgentMessage message) {
    // Skip system messages - they are handled via the system parameter
    if (message.role == MessageRole.system) {
      return null;
    }

    final blocks = <anthropic.Block>[];

    for (final content in message.content) {
      switch (content) {
        case TextContent(:final text):
          blocks.add(anthropic.Block.text(text: text));
        case ImageContent(:final data, :final mediaType):
          blocks.add(anthropic.Block.image(
            source: anthropic.ImageBlockSource(
              type: anthropic.ImageBlockSourceType.base64,
              mediaType: _parseMediaType(mediaType),
              data: data,
            ),
          ));
        case ToolUseContent(:final id, :final toolName, :final input):
          blocks.add(anthropic.Block.toolUse(
            id: id,
            name: toolName,
            input: input,
          ));
        case ToolResultContent(:final toolUseId, :final output, :final isError):
          blocks.add(anthropic.Block.toolResult(
            toolUseId: toolUseId,
            content: anthropic.ToolResultBlockContent.text(output),
            isError: isError,
          ));
        case BinaryContent():
          // Binary content not supported by Anthropic API - skip
          continue;
      }
    }

    if (blocks.isEmpty) {
      return null;
    }

    return anthropic.Message(
      role: _convertRole(message.role),
      content: anthropic.MessageContent.blocks(blocks),
    );
  }

  /// Converts [MessageRole] to Anthropic role.
  anthropic.MessageRole _convertRole(MessageRole role) {
    return switch (role) {
      MessageRole.user => anthropic.MessageRole.user,
      MessageRole.assistant => anthropic.MessageRole.assistant,
      MessageRole.tool => anthropic.MessageRole.user, // Tool results come from user role
      MessageRole.system => anthropic.MessageRole.user, // Should not happen
    };
  }

  /// Parses media type string to Anthropic enum.
  anthropic.ImageBlockSourceMediaType _parseMediaType(String mediaType) {
    return switch (mediaType.toLowerCase()) {
      'image/jpeg' => anthropic.ImageBlockSourceMediaType.imageJpeg,
      'image/png' => anthropic.ImageBlockSourceMediaType.imagePng,
      'image/gif' => anthropic.ImageBlockSourceMediaType.imageGif,
      'image/webp' => anthropic.ImageBlockSourceMediaType.imageWebp,
      _ => anthropic.ImageBlockSourceMediaType.imagePng, // Default fallback
    };
  }

  /// Converts Anthropic response to [LLMResponse].
  LLMResponse _convertResponse(anthropic.Message response) {
    final contentList = <MessageContent>[];

    response.content.mapOrNull(
      blocks: (blocksContent) {
        for (final block in blocksContent.value) {
          final content = _convertBlock(block);
          if (content != null) {
            contentList.add(content);
          }
        }
        return null;
      },
      text: (textContent) {
        contentList.add(TextContent(text: textContent.value));
        return null;
      },
    );

    final message = AgentMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: contentList,
      timestamp: DateTime.now().toUtc(),
    );

    return LLMResponse(
      message: message,
      inputTokens: response.usage?.inputTokens ?? 0,
      outputTokens: response.usage?.outputTokens ?? 0,
      stopReason: _mapStopReason(response.stopReason),
    );
  }

  /// Converts an Anthropic block to [MessageContent].
  MessageContent? _convertBlock(anthropic.Block block) {
    if (block is anthropic.TextBlock) {
      return TextContent(text: block.text);
    }
    if (block is anthropic.ToolUseBlock) {
      return ToolUseContent(
        id: block.id,
        toolName: block.name,
        input: block.input,
      );
    }
    return null;
  }

  /// Maps Anthropic stop reason to string.
  String? _mapStopReason(anthropic.StopReason? reason) {
    if (reason == null) return null;
    return switch (reason) {
      anthropic.StopReason.endTurn => 'end_turn',
      anthropic.StopReason.maxTokens => 'max_tokens',
      anthropic.StopReason.stopSequence => 'stop_sequence',
      anthropic.StopReason.toolUse => 'tool_use',
    };
  }

  /// Converts a stream event to [LLMChunk].
  LLMChunk? _convertStreamEvent(anthropic.MessageStreamEvent event) {
    return event.map(
      messageStart: (_) => null,
      contentBlockStart: (e) {
        // Check if this is a tool use block start
        final block = e.contentBlock;
        if (block is anthropic.ToolUseBlock) {
          return LLMChunk(
            toolUse: ToolUseContent(
              id: block.id,
              toolName: block.name,
              input: block.input,
            ),
          );
        }
        return null;
      },
      contentBlockDelta: (e) {
        final delta = e.delta;
        if (delta is anthropic.TextBlockDelta) {
          return LLMChunk(textDelta: delta.text);
        }
        if (delta is anthropic.InputJsonBlockDelta) {
          // JSON delta for tool input - can be accumulated if needed
          return null;
        }
        return null;
      },
      contentBlockStop: (_) => null,
      messageDelta: (e) {
        // Message delta contains stop reason
        return LLMChunk(
          isComplete: false,
          stopReason: _mapStopReason(e.delta.stopReason),
        );
      },
      messageStop: (_) => const LLMChunk(isComplete: true),
      ping: (_) => null,
      error: (e) {
        // Convert error to a chunk with error info
        return LLMChunk(
          textDelta: 'Error: ${e.error.message}',
          isComplete: true,
          stopReason: 'error',
        );
      },
    );
  }
}
