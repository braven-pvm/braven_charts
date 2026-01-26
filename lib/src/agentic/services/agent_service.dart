import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chart_configuration.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/tool_call.dart';
import '../models/tool_result.dart';
import '../providers/llm_provider.dart';
import '../tools/tool_registry.dart';
import 'chart_history.dart';

enum AgentState {
  idle,
  processing,
}

class AgentService {
  AgentService(
      {required LLMProvider provider, required ToolRegistry toolRegistry})
      : _provider = provider,
        _toolRegistry = toolRegistry,
        conversation = ValueNotifier<Conversation>(
          Conversation(id: const Uuid().v4()),
        ),
        state = ValueNotifier<AgentState>(AgentState.idle),
        currentChart = ValueNotifier<ChartConfiguration?>(null),
        history = ChartHistory();

  final LLMProvider _provider;
  final ToolRegistry _toolRegistry;
  final ValueNotifier<Conversation> conversation;
  final ValueNotifier<AgentState> state;
  final ValueNotifier<ChartConfiguration?> currentChart;
  final ChartHistory history;
  final Uuid _uuid = const Uuid();

  Future<void> processUserMessage(String content) async {
    state.value = AgentState.processing;
    try {
      final userMessage = Message(
        id: _uuid.v4(),
        role: MessageRole.user,
        textContent: content,
      );
      _appendMessage(userMessage);

      Message? streamingMessage;
      String streamingBuffer = '';
      bool streamed = false;

      try {
        await for (final chunk in _provider.streamMessage(conversation.value)) {
          if (chunk.isEmpty) {
            continue;
          }
          streamed = true;
          streamingBuffer += chunk;

          if (streamingMessage == null) {
            streamingMessage = Message(
              id: _uuid.v4(),
              role: MessageRole.assistant,
              textContent: streamingBuffer,
            );
            _appendMessage(streamingMessage);
          } else {
            streamingMessage =
                streamingMessage.copyWith(textContent: streamingBuffer);
            _replaceMessage(streamingMessage);
          }
        }
      } catch (_) {
        // Streaming is optional; fall back to non-streaming response.
      }

      Message response = await _provider.sendMessage(conversation.value);
      if (streamed || streamingMessage != null) {
        final updatedResponse = response.copyWith(
          id: streamingMessage?.id ?? response.id,
          textContent: response.textContent ?? streamingMessage?.textContent,
        );
        if (streamingMessage != null) {
          _replaceMessage(updatedResponse);
        } else {
          _appendMessage(updatedResponse);
        }
        response = updatedResponse;
      } else {
        _appendMessage(response);
      }
      while (true) {
        final toolCalls = response.toolCalls;
        if (toolCalls == null || toolCalls.isEmpty) {
          break;
        }

        final toolResults = <ToolResult>[];
        for (final ToolCall call in toolCalls) {
          debugPrint('[AgentService] Executing tool: ${call.toolName}');
          final result =
              await _toolRegistry.execute(call.toolName, call.arguments);
          debugPrint('[AgentService] Tool result type: ${result.runtimeType}');

          String? createdChartId;

          // If the tool returns a ChartConfiguration, add it to the conversation
          if (result is ChartConfiguration) {
            debugPrint(
                '[AgentService] Adding ChartConfiguration to conversation');
            createdChartId = result.id ?? _uuid.v4();
            debugPrint('[AgentService] Chart ID: $createdChartId');
            final current = conversation.value;
            final updatedCharts = Map<String, dynamic>.from(current.charts);
            updatedCharts[createdChartId] = result.toJson();
            final newConversation = current.copyWith(charts: updatedCharts);
            conversation.value = newConversation;
          }

          if (result is ToolResult) {
            toolResults.add(result);
          } else {
            toolResults.add(
              ToolResult(
                toolCallId: call.id,
                result: result,
                chartId: createdChartId,
              ),
            );
          }
        }

        final toolResultMessage = Message(
          id: _uuid.v4(),
          role: MessageRole.assistant,
          toolResults: toolResults,
        );
        _appendMessage(toolResultMessage);

        response = await _provider.sendMessage(conversation.value);
        _appendMessage(response);
      }
    } finally {
      state.value = AgentState.idle;
    }
  }

  void _replaceMessage(Message message) {
    final current = conversation.value;
    final index = current.messages.indexWhere((m) => m.id == message.id);
    if (index == -1) {
      _appendMessage(message);
      return;
    }

    final updatedMessages = List<Message>.from(current.messages);
    updatedMessages[index] = message;
    conversation.value = current.copyWith(messages: updatedMessages);
  }

  void _appendMessage(Message message) {
    final current = conversation.value;
    final updatedMessages = List<Message>.from(current.messages)..add(message);
    final isUser = message.role == MessageRole.user;
    conversation.value = current.copyWith(
      messages: updatedMessages,
      totalInputTokens:
          isUser ? current.totalInputTokens + 1 : current.totalInputTokens,
      totalOutputTokens:
          isUser ? current.totalOutputTokens : current.totalOutputTokens + 1,
    );
  }

  /// Records the current chart state in history
  void recordChartState(ChartConfiguration chart) {
    history.record(chart);
    currentChart.value = chart;
  }

  /// Undoes the last chart modification
  void undoChart() {
    final previousChart = history.undo();
    if (previousChart != null) {
      currentChart.value = previousChart;
    }
  }

  /// Redoes the last undone chart modification
  void redoChart() {
    final nextChart = history.redo();
    if (nextChart != null) {
      currentChart.value = nextChart;
    }
  }

  /// Whether undo is possible
  bool get canUndoChart => history.canUndo;

  /// Whether redo is possible
  bool get canRedoChart => history.canRedo;
}
