import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Creates a sample AgentMessage for testing.
  AgentMessage createTestMessage({
    String id = 'msg_1',
    MessageRole role = MessageRole.user,
    String text = 'Test message',
  }) {
    return AgentMessage(
      id: id,
      role: role,
      content: [TextContent(text: text)],
      timestamp: DateTime(2024, 1, 15, 10, 30),
    );
  }

  /// Creates a sample ChartConfiguration for testing.
  ChartConfiguration createTestChart({
    String? id = 'chart_1',
    String title = 'Test Chart',
  }) {
    return ChartConfiguration(
      id: id,
      title: title,
      series: const [],
    );
  }

  /// Creates a sample ToolCall for testing.
  ToolCall createTestToolCall({
    String id = 'toolu_123',
    String name = 'create_chart',
    Map<String, dynamic> input = const {'type': 'line'},
  }) {
    return ToolCall(id: id, name: name, input: input);
  }

  group('SessionState state transitions', () {
    test('simulates full session lifecycle', () {
      // Initial idle state
      const state1 = SessionState();
      expect(state1.status, equals(ActivityStatus.idle));

      // User sends message - thinking
      final state2 = state1.copyWith(
        history: [createTestMessage()],
        status: ActivityStatus.thinking,
      );
      expect(state2.status, equals(ActivityStatus.thinking));
      expect(state2.history, hasLength(1));

      // Tool execution starts
      final state3 = state2.copyWith(
        status: ActivityStatus.calling_tool,
        activeTool: createTestToolCall(),
      );
      expect(state3.status, equals(ActivityStatus.calling_tool));
      expect(state3.activeTool, isNotNull);

      // Tool completes, chart created
      final state4 = state3.copyWithCleared(
        status: ActivityStatus.idle,
        activeChart: createTestChart(),
        clearActiveTool: true,
      );
      expect(state4.status, equals(ActivityStatus.idle));
      expect(state4.activeTool, isNull);
      expect(state4.activeChart, isNotNull);

      // Error occurs
      final state5 = state4.copyWith(
        status: ActivityStatus.error,
        errorMessage: 'Something went wrong',
      );
      expect(state5.status, equals(ActivityStatus.error));
      expect(state5.errorMessage, isNotNull);
      // Chart is still preserved
      expect(state5.activeChart, isNotNull);

      // Recovery to idle
      final state6 = state5.copyWithCleared(
        status: ActivityStatus.idle,
        clearErrorMessage: true,
      );
      expect(state6.status, equals(ActivityStatus.idle));
      expect(state6.errorMessage, isNull);
      expect(state6.activeChart, isNotNull);
    });
  });
}
