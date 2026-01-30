import 'dart:async';

import 'package:braven_agent/src/llm/llm_config.dart';
import 'package:braven_agent/src/llm/llm_provider.dart';
import 'package:braven_agent/src/llm/llm_response.dart';
import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/session/agent_events.dart';
import 'package:braven_agent/src/session/agent_session_impl.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLLMProvider implements LLMProvider {
  LLMResponse? nextResponse;

  @override
  String get id => 'mock-provider';

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    return nextResponse ?? _defaultResponse;
  }

  @override
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) {
    throw UnimplementedError('streamResponse not used in tests');
  }

  LLMResponse get _defaultResponse => LLMResponse(
        message: AgentMessage(
          id: 'msg_mock',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'Mock response')],
          timestamp: DateTime(2024, 1, 15, 10, 30),
        ),
        inputTokens: 100,
        outputTokens: 50,
        stopReason: 'end_turn',
      );
}

ChartConfiguration createTestChart({
  String? id = 'chart_1',
  String title = 'Test Chart',
  ChartType type = ChartType.line,
}) {
  return ChartConfiguration(
    id: id,
    type: type,
    title: title,
    series: const [],
  );
}

Future<void> flushEventQueue() => Future<void>.delayed(Duration.zero);

void main() {
  group('updateChart()', () {
    test('updates activeChart in session state', () {
      final session = AgentSessionImpl(
        llmProvider: MockLLMProvider(),
        tools: const [],
        systemPrompt: 'System prompt',
      );

      final updatedChart = createTestChart(id: 'updated_chart');
      session.updateChart(updatedChart);

      expect(session.state.value.activeChart, equals(updatedChart));
      session.dispose();
    });

    test('emits ChartUpdatedEvent with provided config', () async {
      final session = AgentSessionImpl(
        llmProvider: MockLLMProvider(),
        tools: const [],
        systemPrompt: 'System prompt',
      );

      final updatedChart = createTestChart(id: 'updated_chart');

      final eventFuture = expectLater(
        session.events,
        emits(
          isA<ChartUpdatedEvent>().having(
            (event) => event.config,
            'config',
            equals(updatedChart),
          ),
        ),
      );

      session.updateChart(updatedChart);

      await eventFuture;
      session.dispose();
    });

    test('notifies ValueListenable listeners on update', () {
      final session = AgentSessionImpl(
        llmProvider: MockLLMProvider(),
        tools: const [],
        systemPrompt: 'System prompt',
      );

      var notified = false;
      void listener() {
        notified = true;
      }

      session.state.addListener(listener);

      final updatedChart = createTestChart(id: 'updated_chart');
      session.updateChart(updatedChart);

      expect(notified, isTrue);

      session.state.removeListener(listener);
      session.dispose();
    });

    test('preserves history and status when updating chart', () async {
      final mockProvider = MockLLMProvider();
      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: const [],
        systemPrompt: 'System prompt',
      );

      await session.transform('Create a chart');
      await flushEventQueue();

      final previousHistory = session.state.value.history;
      final previousStatus = session.state.value.status;
      final previousPending = session.state.value.pendingResponse;
      final previousActiveTool = session.state.value.activeTool;

      final updatedChart = createTestChart(id: 'updated_chart');
      session.updateChart(updatedChart);

      expect(session.state.value.history, equals(previousHistory));
      expect(session.state.value.status, equals(previousStatus));
      expect(session.state.value.pendingResponse, equals(previousPending));
      expect(session.state.value.activeTool, equals(previousActiveTool));
      expect(session.state.value.activeChart, equals(updatedChart));

      session.dispose();
    });

    test('does not emit event after session is disposed', () async {
      final session = AgentSessionImpl(
        llmProvider: MockLLMProvider(),
        tools: const [],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      final subscription = session.events.listen(events.add);

      session.dispose();
      session.updateChart(createTestChart(id: 'updated_chart'));
      await flushEventQueue();

      expect(events, isEmpty);
      await subscription.cancel();
    });
  });
}
