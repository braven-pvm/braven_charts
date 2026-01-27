import 'dart:convert';

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
import 'data_store.dart';

enum AgentState {
  idle,
  processing,
}

class AgentService {
  AgentService({
    required LLMProvider provider,
    required ToolRegistry toolRegistry,
    DataStore<ChartConfiguration>? chartStore,
  })  : _provider = provider,
        _toolRegistry = toolRegistry,
        chartStore = chartStore ?? DataStore<ChartConfiguration>(),
        conversation = ValueNotifier<Conversation>(
          Conversation(id: const Uuid().v4()),
        ),
        state = ValueNotifier<AgentState>(AgentState.idle),
        currentChart = ValueNotifier<ChartConfiguration?>(null),
        history = ChartHistory();

  final LLMProvider _provider;
  final ToolRegistry _toolRegistry;

  /// Shared chart store for tools to access charts by ID.
  /// This is synced with conversation.charts when charts are created/modified.
  final DataStore<ChartConfiguration> chartStore;

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
            streamingMessage = streamingMessage.copyWith(textContent: streamingBuffer);
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
          debugPrint('=== AGENT TOOL EXECUTION START ===');
          debugPrint('[AgentService] Executing tool: ${call.toolName}');
          // DEBUG: Print the input arguments the agent provided
          _debugPrintJson('[AgentService] Tool input arguments', call.arguments);

          final result = await _toolRegistry.execute(call.toolName, call.arguments);
          debugPrint('[AgentService] Tool result type: ${result.runtimeType}');

          String? createdChartId;

          // If the tool returns a ChartConfiguration, add it to the conversation
          if (result is ChartConfiguration) {
            debugPrint('[AgentService] Adding ChartConfiguration to conversation');
            createdChartId = result.id ?? _uuid.v4();
            debugPrint('[AgentService] Chart ID: $createdChartId');

            // CRITICAL: Ensure the chart object has the ID set
            // This is essential for in-place modifications to work correctly
            final chartWithId = result.id == null ? result.copyWith(id: createdChartId) : result;

            // Store in chartStore so ModifyChartTool can access it
            chartStore.store(chartWithId, id: createdChartId);
            debugPrint('[AgentService] Chart stored in chartStore with ID: $createdChartId');

            // DEBUG: Print the chart configuration as JSON
            _debugPrintJson('[AgentService] ChartConfiguration created', chartWithId.toJson());
            final current = conversation.value;
            final updatedCharts = Map<String, dynamic>.from(current.charts);
            updatedCharts[createdChartId] = chartWithId.toJson();

            // DEBUG: Verify the updated charts map has the correct data
            final updatedChartJson = updatedCharts[createdChartId] as Map<String, dynamic>;
            final updatedSeries = updatedChartJson['series'] as List?;
            debugPrint('[AgentService] BEFORE setting conversation.value:');
            debugPrint('[AgentService]   updatedCharts has ${updatedSeries?.length ?? 0} series');
            for (final s in updatedSeries ?? []) {
              final seriesMap = s as Map<String, dynamic>;
              debugPrint('[AgentService]   - ${seriesMap['id']}');
            }

            final newConversation = current.copyWith(charts: updatedCharts);

            // DEBUG: Verify newConversation has correct data
            final newChartJson = newConversation.charts[createdChartId] as Map<String, dynamic>;
            final newSeries = newChartJson['series'] as List?;
            debugPrint('[AgentService] newConversation.charts has ${newSeries?.length ?? 0} series');
            debugPrint('[AgentService] newConversation identity: ${identityHashCode(newConversation)}');
            debugPrint('[AgentService] current identity: ${identityHashCode(current)}');
            debugPrint('[AgentService] conversation.value identity BEFORE: ${identityHashCode(conversation.value)}');

            conversation.value = newConversation;

            // DEBUG: Verify after assignment
            debugPrint('[AgentService] conversation.value identity AFTER: ${identityHashCode(conversation.value)}');
            final afterConv = conversation.value;
            debugPrint('[AgentService] afterConv same as newConversation: ${identical(afterConv, newConversation)}');
            final afterChart = afterConv.charts[createdChartId] as Map<String, dynamic>;
            final afterSeries = afterChart['series'] as List?;
            debugPrint('[AgentService] AFTER setting conversation.value: ${afterSeries?.length ?? 0} series');
          }
          debugPrint('=== AGENT TOOL EXECUTION END ===');

          if (result is ToolResult) {
            toolResults.add(result);
          } else {
            // CRITICAL: If result is ChartConfiguration, use chartWithId (with ID set), not original result
            final resultToStore = (result is ChartConfiguration && createdChartId != null)
                ? chartStore.get(createdChartId) ?? result // Get the version with ID from chartStore
                : result;
            toolResults.add(
              ToolResult(
                toolCallId: call.id,
                result: resultToStore,
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

    // DEBUG: Check chart state when appending messages
    for (final entry in current.charts.entries) {
      final chartMap = entry.value as Map<String, dynamic>;
      final seriesList = chartMap['series'] as List?;
      debugPrint('[AgentService._appendMessage] current chart ${entry.key} has ${seriesList?.length ?? 0} series');
    }

    final updatedMessages = List<Message>.from(current.messages)..add(message);
    final isUser = message.role == MessageRole.user;
    final newConv = current.copyWith(
      messages: updatedMessages,
      totalInputTokens: isUser ? current.totalInputTokens + 1 : current.totalInputTokens,
      totalOutputTokens: isUser ? current.totalOutputTokens : current.totalOutputTokens + 1,
    );

    // DEBUG: Check chart state in new conversation
    for (final entry in newConv.charts.entries) {
      final chartMap = entry.value as Map<String, dynamic>;
      final seriesList = chartMap['series'] as List?;
      debugPrint('[AgentService._appendMessage] newConv chart ${entry.key} has ${seriesList?.length ?? 0} series');
    }

    conversation.value = newConv;
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

  /// Debug helper: print any JSON object with formatting
  void _debugPrintJson(String label, Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(json);
      debugPrint('$label:');
      // Print line by line to avoid truncation
      for (final line in prettyJson.split('\n')) {
        debugPrint(line);
      }
    } catch (e) {
      debugPrint('$label: [Failed to serialize: $e]');
      debugPrint('Raw: $json');
    }
  }
}
