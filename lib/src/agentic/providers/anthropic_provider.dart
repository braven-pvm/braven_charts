import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/tool_call.dart';
import '../tools/llm_tool.dart';
import 'llm_provider.dart';

/// System prompt that instructs Claude to use the create_chart tool.
const String _chartSystemPrompt = '''
You are a helpful chart creation assistant. 
When users ask for charts or data visualizations, use the create_chart tool to generate them.

IMPORTANT: You MUST include the data in the series array when calling create_chart.
Do NOT write Python code or matplotlib code.
Do NOT just describe the chart - actually call the tool with data.

Be creative with sample data if the user doesn't provide specific values.
For line charts, generate smooth realistic-looking data with 10-20 points.
For bar charts, use 4-8 categories.
For scatter plots, use 10-20 points.

Example tool call for a bar chart:
{
  "prompt": "quarterly sales",
  "type": "bar",
  "series": [
    {
      "id": "sales",
      "name": "Sales",
      "data": [
        {"x": 0, "y": 120000},
        {"x": 1, "y": 150000},
        {"x": 2, "y": 180000},
        {"x": 3, "y": 210000}
      ]
    }
  ]
}

Always explain what chart you're creating before using the tool.
''';

/// Anthropic (Claude) LLM provider implementation.
class AnthropicProvider extends LLMProvider {
  AnthropicProvider({
    required this.apiKey,
    dynamic client,
    this.model = 'claude-sonnet-4-20250514',
    this.maxTokens = 1024,
    List<LLMTool>? tools,
  })  : _client = client ?? anthropic.AnthropicClient(apiKey: apiKey),
        _tools = tools ?? [];

  final String apiKey;
  final String model;
  final int maxTokens;
  final dynamic _client;
  final List<LLMTool> _tools;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    final messages = _buildMessages(conversation);
    final anthropicTools = _buildTools();

    // Debug logging
    print('[AnthropicProvider] Sending ${messages.length} messages with ${anthropicTools.length} tools');
    for (final tool in anthropicTools) {
      print('[AnthropicProvider]   - Tool: ${tool.name}');
    }

    try {
      final request = anthropic.CreateMessageRequest(
        model: anthropic.Model.modelId(model),
        maxTokens: maxTokens,
        // ignore: prefer_const_constructors
        system: anthropic.CreateMessageRequestSystem.text(_chartSystemPrompt),
        messages: messages,
        tools: anthropicTools.isNotEmpty ? anthropicTools : null,
        // Force Claude to use tools when available
        toolChoice: anthropicTools.isNotEmpty
            ? const anthropic.ToolChoice(
                type: anthropic.ToolChoiceType.auto,
              )
            : null,
      );
      final response = await _client.createMessage(request: request);
      return _extractResponse(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  /// Build Anthropic tool definitions from registered LLMTools.
  List<anthropic.Tool> _buildTools() {
    return _tools.map((tool) {
      return anthropic.Tool.custom(
        name: tool.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
      );
    }).toList();
  }

  /// Extract response including text and tool calls.
  Message _extractResponse(dynamic response) {
    final text = _extractText(response);
    final toolCalls = _extractToolCalls(response);

    // Debug logging
    print('[AnthropicProvider] Response text: "${text.length > 100 ? text.substring(0, 100) : text}..."');
    print('[AnthropicProvider] Tool calls found: ${toolCalls.length}');
    for (final tc in toolCalls) {
      print('[AnthropicProvider]   - Tool: ${tc.toolName}, args: ${tc.arguments}');
    }

    return Message(
      id: _generateMessageId(),
      role: MessageRole.assistant,
      textContent: text.isEmpty && toolCalls.isEmpty ? '...' : text,
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Extract tool calls from the response.
  List<ToolCall> _extractToolCalls(dynamic response) {
    final toolCalls = <ToolCall>[];
    if (response == null) return toolCalls;

    try {
      final dynamic content = (response as dynamic).content;
      if (content is anthropic.MessageContent) {
        content.mapOrNull(
          blocks: (blocksContent) {
            for (final block in blocksContent.value) {
              if (block is anthropic.ToolUseBlock) {
                toolCalls.add(ToolCall(
                  id: block.id,
                  toolName: block.name,
                  arguments: block.input,
                ));
              }
            }
            return null;
          },
        );
      }
    } catch (_) {
      // Ignore extraction errors
    }
    return toolCalls;
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {
    // Streaming not yet supported by anthropic_sdk_dart
    // Return empty stream to trigger fallback to non-streaming in agent_service
    return;
  }

  List<anthropic.Message> _buildMessages(Conversation conversation) {
    if (conversation.messages.isEmpty) {
      return [];
    }

    final result = <anthropic.Message>[];

    for (final message in conversation.messages) {
      // Handle user messages with text
      if (message.role == MessageRole.user && message.textContent != null && message.textContent!.trim().isNotEmpty) {
        result.add(
          anthropic.Message(
            role: anthropic.MessageRole.user,
            content: anthropic.MessageContent.text(message.textContent!),
          ),
        );
        continue;
      }

      // Handle assistant messages with tool calls
      if (message.role == MessageRole.assistant && message.toolCalls != null && message.toolCalls!.isNotEmpty) {
        final blocks = <anthropic.Block>[];

        // Add text block if there's text content
        if (message.textContent != null && message.textContent!.trim().isNotEmpty) {
          blocks.add(anthropic.Block.text(text: message.textContent!));
        }

        // Add tool use blocks
        for (final toolCall in message.toolCalls!) {
          blocks.add(anthropic.Block.toolUse(
            id: toolCall.id,
            name: toolCall.toolName,
            input: toolCall.arguments,
          ));
        }

        result.add(
          anthropic.Message(
            role: anthropic.MessageRole.assistant,
            content: anthropic.MessageContent.blocks(blocks),
          ),
        );
        continue;
      }

      // Handle assistant messages with tool results (send as user message with tool_result blocks)
      if (message.role == MessageRole.assistant && message.toolResults != null && message.toolResults!.isNotEmpty) {
        final blocks = <anthropic.Block>[];

        for (final toolResult in message.toolResults!) {
          // Convert result to string for the API
          String resultContent;
          if (toolResult.result != null) {
            resultContent = toolResult.result.toString();
          } else if (toolResult.content != null) {
            resultContent = toolResult.content.toString();
          } else if (toolResult.error != null) {
            resultContent = 'Error: ${toolResult.error}';
          } else {
            resultContent = 'Success';
          }

          blocks.add(anthropic.Block.toolResult(
            toolUseId: toolResult.toolCallId,
            content: anthropic.ToolResultBlockContent.text(resultContent),
            isError: toolResult.isError,
          ));
        }

        // Tool results must be sent as user messages per Anthropic API
        result.add(
          anthropic.Message(
            role: anthropic.MessageRole.user,
            content: anthropic.MessageContent.blocks(blocks),
          ),
        );
        continue;
      }

      // Handle regular assistant text messages
      if (message.role == MessageRole.assistant && message.textContent != null && message.textContent!.trim().isNotEmpty) {
        result.add(
          anthropic.Message(
            role: anthropic.MessageRole.assistant,
            content: anthropic.MessageContent.text(message.textContent!),
          ),
        );
      }
    }

    return result;
  }

  String _extractText(dynamic response) {
    if (response == null) {
      return '';
    }

    // Handle anthropic SDK response with content.blocks
    try {
      final dynamic content = (response as dynamic).content;
      if (content != null) {
        // Check if content is MessageContentBlocks
        if (content is anthropic.MessageContent) {
          return content.map(
            text: (textContent) => textContent.text,
            blocks: (blocksContent) {
              for (final block in blocksContent.value) {
                if (block is anthropic.TextBlock) {
                  return block.text;
                }
                // Try to get text from block dynamically
                try {
                  final text = (block as dynamic).text;
                  if (text is String && text.isNotEmpty) {
                    return text;
                  }
                } catch (_) {}
              }
              return '';
            },
          );
        }

        // Fallback: try to access blocks directly
        try {
          final blocks = (content as dynamic).value;
          if (blocks is List) {
            for (final block in blocks) {
              if (block is anthropic.TextBlock) {
                return block.text;
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback for other response formats
    if (response is String) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final content = response['content'];
      return _extractFromContent(content);
    }

    return '';
  }

  String _extractFromContent(dynamic content) {
    if (content == null) {
      return '';
    }

    if (content is String) {
      return content;
    }

    if (content is List) {
      for (final block in content) {
        final text = _extractText(block);
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    if (content is Map<String, dynamic>) {
      final text = content['text'];
      if (text is String) {
        return text;
      }
    }

    try {
      final dynamic text = (content as dynamic).text;
      if (text is String) {
        return text;
      }
    } catch (_) {}

    return '';
  }

  LLMProviderException _mapError(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('401') || raw.contains('unauthorized') || raw.contains('invalid api key') || raw.contains('authentication')) {
      return LLMProviderException(
        'Authentication failed. Please check your API key.',
        type: LLMProviderErrorType.authentication,
      );
    }

    if (raw.contains('429') || raw.contains('rate limit')) {
      return LLMProviderException(
        'Rate limit reached. Please wait and try again.',
        type: LLMProviderErrorType.rateLimited,
      );
    }

    if (raw.contains('socket') || raw.contains('network') || raw.contains('timeout') || raw.contains('connection')) {
      return LLMProviderException(
        'Network error. Please check your connection and retry.',
        type: LLMProviderErrorType.network,
      );
    }

    return LLMProviderException(
      'Unexpected error from LLM provider. Please try again.',
      type: LLMProviderErrorType.unknown,
    );
  }

  String _generateMessageId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
