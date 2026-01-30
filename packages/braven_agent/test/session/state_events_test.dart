import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/session/agent_events.dart';
import 'package:braven_agent/src/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================
  // Helper Functions
  // ============================================================

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

  // ============================================================
  // ActivityStatus Tests
  // ============================================================
  group('ActivityStatus', () {
    test('has exactly 4 values', () {
      expect(ActivityStatus.values.length, equals(4));
    });

    test('idle is first value', () {
      expect(ActivityStatus.values[0], equals(ActivityStatus.idle));
    });

    test('thinking is second value', () {
      expect(ActivityStatus.values[1], equals(ActivityStatus.thinking));
    });

    test('calling_tool is third value', () {
      expect(ActivityStatus.values[2], equals(ActivityStatus.calling_tool));
    });

    test('error is fourth value', () {
      expect(ActivityStatus.values[3], equals(ActivityStatus.error));
    });

    test('all values have correct names', () {
      expect(ActivityStatus.idle.name, equals('idle'));
      expect(ActivityStatus.thinking.name, equals('thinking'));
      expect(ActivityStatus.calling_tool.name, equals('calling_tool'));
      expect(ActivityStatus.error.name, equals('error'));
    });

    test('values are accessible by name', () {
      expect(
        ActivityStatus.values.byName('idle'),
        equals(ActivityStatus.idle),
      );
      expect(
        ActivityStatus.values.byName('thinking'),
        equals(ActivityStatus.thinking),
      );
      expect(
        ActivityStatus.values.byName('calling_tool'),
        equals(ActivityStatus.calling_tool),
      );
      expect(
        ActivityStatus.values.byName('error'),
        equals(ActivityStatus.error),
      );
    });
  });

  // ============================================================
  // ToolCall Tests
  // ============================================================
  group('ToolCall', () {
    group('construction', () {
      test('creates instance with required fields', () {
        const toolCall = ToolCall(
          id: 'toolu_abc',
          name: 'create_chart',
          input: {'type': 'line', 'title': 'Sales'},
        );

        expect(toolCall.id, equals('toolu_abc'));
        expect(toolCall.name, equals('create_chart'));
        expect(toolCall.input, equals({'type': 'line', 'title': 'Sales'}));
      });

      test('input map can be empty', () {
        const toolCall =
            ToolCall(id: 'toolu_1', name: 'simple_tool', input: {});

        expect(toolCall.input, isEmpty);
      });

      test('input map can contain nested objects', () {
        const toolCall = ToolCall(
          id: 'toolu_2',
          name: 'complex_tool',
          input: {
            'nested': {'key': 'value'},
            'list': [1, 2, 3],
          },
        );

        expect(toolCall.input['nested'], equals({'key': 'value'}));
        expect(toolCall.input['list'], equals([1, 2, 3]));
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const toolCall1 = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'line'},
        );
        const toolCall2 = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'line'},
        );

        expect(toolCall1, equals(toolCall2));
        expect(toolCall1.hashCode, equals(toolCall2.hashCode));
      });

      test('different id makes instances not equal', () {
        const toolCall1 = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'line'},
        );
        const toolCall2 = ToolCall(
          id: 'toolu_456',
          name: 'create_chart',
          input: {'type': 'line'},
        );

        expect(toolCall1, isNot(equals(toolCall2)));
      });

      test('different name makes instances not equal', () {
        const toolCall1 = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'line'},
        );
        const toolCall2 = ToolCall(
          id: 'toolu_123',
          name: 'modify_chart',
          input: {'type': 'line'},
        );

        expect(toolCall1, isNot(equals(toolCall2)));
      });

      test('different input makes instances not equal', () {
        const toolCall1 = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'line'},
        );
        const toolCall2 = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'bar'},
        );

        expect(toolCall1, isNot(equals(toolCall2)));
      });
    });

    group('props', () {
      test('props contains id, name, and input', () {
        const toolCall = ToolCall(
          id: 'toolu_123',
          name: 'create_chart',
          input: {'type': 'line'},
        );

        expect(toolCall.props, hasLength(3));
        expect(toolCall.props[0], equals('toolu_123'));
        expect(toolCall.props[1], equals('create_chart'));
        expect(toolCall.props[2], equals({'type': 'line'}));
      });
    });

    group('toString', () {
      test('returns expected format with id and name', () {
        const toolCall = ToolCall(
          id: 'toolu_abc123',
          name: 'create_chart',
          input: {'type': 'line'},
        );

        expect(
          toolCall.toString(),
          equals('ToolCall(id: toolu_abc123, name: create_chart)'),
        );
      });

      test('toString does not include input details', () {
        const toolCall = ToolCall(
          id: 'toolu_1',
          name: 'test_tool',
          input: {'sensitive': 'data', 'password': 'secret'},
        );

        final result = toolCall.toString();
        expect(result, isNot(contains('sensitive')));
        expect(result, isNot(contains('secret')));
      });
    });
  });

  // ============================================================
  // SessionState Tests
  // ============================================================
  group('SessionState', () {
    group('construction', () {
      test('default constructor creates idle state with empty history', () {
        const state = SessionState();

        expect(state.history, isEmpty);
        expect(state.pendingResponse, isNull);
        expect(state.activeTool, isNull);
        expect(state.status, equals(ActivityStatus.idle));
        expect(state.activeChart, isNull);
        expect(state.errorMessage, isNull);
      });

      test('constructor accepts all fields', () {
        final message = createTestMessage();
        final pendingMsg = createTestMessage(id: 'pending');
        final toolCall = createTestToolCall();
        final chart = createTestChart();

        final state = SessionState(
          history: [message],
          pendingResponse: pendingMsg,
          activeTool: toolCall,
          status: ActivityStatus.thinking,
          activeChart: chart,
          errorMessage: 'An error occurred',
        );

        expect(state.history, hasLength(1));
        expect(state.history.first, equals(message));
        expect(state.pendingResponse, equals(pendingMsg));
        expect(state.activeTool, equals(toolCall));
        expect(state.status, equals(ActivityStatus.thinking));
        expect(state.activeChart, equals(chart));
        expect(state.errorMessage, equals('An error occurred'));
      });

      test('history defaults to const empty list', () {
        const state = SessionState();

        // Verify the list is the default const empty list
        expect(state.history, equals(const <AgentMessage>[]));
      });
    });

    group('all 6 fields', () {
      test('history field stores conversation messages', () {
        final messages = [
          createTestMessage(id: 'msg_1', text: 'Hello'),
          createTestMessage(
              id: 'msg_2', role: MessageRole.assistant, text: 'Hi!'),
        ];
        final state = SessionState(history: messages);

        expect(state.history, hasLength(2));
        expect(state.history[0].id, equals('msg_1'));
        expect(state.history[1].id, equals('msg_2'));
      });

      test('pendingResponse field stores message being streamed', () {
        final pending = createTestMessage(id: 'streaming');
        final state = SessionState(pendingResponse: pending);

        expect(state.pendingResponse, isNotNull);
        expect(state.pendingResponse!.id, equals('streaming'));
      });

      test('activeTool field stores currently executing tool', () {
        final tool = createTestToolCall(name: 'modify_chart');
        final state = SessionState(activeTool: tool);

        expect(state.activeTool, isNotNull);
        expect(state.activeTool!.name, equals('modify_chart'));
      });

      test('status field stores current activity status', () {
        const state = SessionState(status: ActivityStatus.calling_tool);

        expect(state.status, equals(ActivityStatus.calling_tool));
      });

      test('activeChart field stores chart configuration', () {
        final chart = createTestChart(title: 'Revenue Chart');
        final state = SessionState(activeChart: chart);

        expect(state.activeChart, isNotNull);
        expect(state.activeChart!.title, equals('Revenue Chart'));
      });

      test('errorMessage field stores error details', () {
        const state = SessionState(
          status: ActivityStatus.error,
          errorMessage: 'Connection timeout',
        );

        expect(state.errorMessage, equals('Connection timeout'));
      });
    });

    group('copyWith', () {
      test('with no args returns equal instance', () {
        final original = SessionState(
          history: [createTestMessage()],
          status: ActivityStatus.thinking,
          activeChart: createTestChart(),
        );
        final copy = original.copyWith();

        expect(copy, equals(original));
      });

      test('updates only history when specified', () {
        final original = SessionState(
          history: [createTestMessage(id: 'old')],
          status: ActivityStatus.thinking,
        );
        final newHistory = [createTestMessage(id: 'new')];
        final updated = original.copyWith(history: newHistory);

        expect(updated.history.first.id, equals('new'));
        expect(updated.status, equals(ActivityStatus.thinking));
      });

      test('updates only pendingResponse when specified', () {
        const original = SessionState(status: ActivityStatus.idle);
        final pending = createTestMessage(id: 'pending');
        final updated = original.copyWith(pendingResponse: pending);

        expect(updated.pendingResponse, equals(pending));
        expect(updated.status, equals(ActivityStatus.idle));
      });

      test('updates only activeTool when specified', () {
        const original = SessionState(status: ActivityStatus.idle);
        final tool = createTestToolCall();
        final updated = original.copyWith(activeTool: tool);

        expect(updated.activeTool, equals(tool));
        expect(updated.status, equals(ActivityStatus.idle));
      });

      test('updates only status when specified', () {
        final original = SessionState(activeChart: createTestChart());
        final updated = original.copyWith(status: ActivityStatus.error);

        expect(updated.status, equals(ActivityStatus.error));
        expect(updated.activeChart, equals(original.activeChart));
      });

      test('updates only activeChart when specified', () {
        const original = SessionState(status: ActivityStatus.thinking);
        final chart = createTestChart();
        final updated = original.copyWith(activeChart: chart);

        expect(updated.activeChart, equals(chart));
        expect(updated.status, equals(ActivityStatus.thinking));
      });

      test('updates only errorMessage when specified', () {
        const original = SessionState(status: ActivityStatus.error);
        final updated = original.copyWith(errorMessage: 'New error');

        expect(updated.errorMessage, equals('New error'));
        expect(updated.status, equals(ActivityStatus.error));
      });

      test('updates multiple fields simultaneously', () {
        const original = SessionState();
        final updated = original.copyWith(
          status: ActivityStatus.thinking,
          history: [createTestMessage()],
          activeChart: createTestChart(),
        );

        expect(updated.status, equals(ActivityStatus.thinking));
        expect(updated.history, hasLength(1));
        expect(updated.activeChart, isNotNull);
        expect(updated.pendingResponse, isNull);
        expect(updated.activeTool, isNull);
        expect(updated.errorMessage, isNull);
      });
    });

    group('copyWithCleared', () {
      test('clearPendingResponse sets pendingResponse to null', () {
        final original = SessionState(
          pendingResponse: createTestMessage(),
          status: ActivityStatus.thinking,
        );
        final cleared = original.copyWithCleared(clearPendingResponse: true);

        expect(cleared.pendingResponse, isNull);
        expect(cleared.status, equals(ActivityStatus.thinking));
      });

      test('clearActiveTool sets activeTool to null', () {
        final original = SessionState(
          activeTool: createTestToolCall(),
          status: ActivityStatus.calling_tool,
        );
        final cleared = original.copyWithCleared(clearActiveTool: true);

        expect(cleared.activeTool, isNull);
        expect(cleared.status, equals(ActivityStatus.calling_tool));
      });

      test('clearActiveChart sets activeChart to null', () {
        final original = SessionState(
          activeChart: createTestChart(),
          status: ActivityStatus.idle,
        );
        final cleared = original.copyWithCleared(clearActiveChart: true);

        expect(cleared.activeChart, isNull);
        expect(cleared.status, equals(ActivityStatus.idle));
      });

      test('clearErrorMessage sets errorMessage to null', () {
        const original = SessionState(
          status: ActivityStatus.error,
          errorMessage: 'Something went wrong',
        );
        final cleared = original.copyWithCleared(clearErrorMessage: true);

        expect(cleared.errorMessage, isNull);
        expect(cleared.status, equals(ActivityStatus.error));
      });

      test('can clear multiple fields at once', () {
        final original = SessionState(
          pendingResponse: createTestMessage(),
          activeTool: createTestToolCall(),
          activeChart: createTestChart(),
          errorMessage: 'Error',
        );
        final cleared = original.copyWithCleared(
          clearPendingResponse: true,
          clearActiveTool: true,
          clearActiveChart: true,
          clearErrorMessage: true,
        );

        expect(cleared.pendingResponse, isNull);
        expect(cleared.activeTool, isNull);
        expect(cleared.activeChart, isNull);
        expect(cleared.errorMessage, isNull);
      });

      test('can set new value while clearing others', () {
        final original = SessionState(
          pendingResponse: createTestMessage(),
          activeTool: createTestToolCall(),
        );
        final cleared = original.copyWithCleared(
          status: ActivityStatus.idle,
          clearPendingResponse: true,
          clearActiveTool: true,
        );

        expect(cleared.status, equals(ActivityStatus.idle));
        expect(cleared.pendingResponse, isNull);
        expect(cleared.activeTool, isNull);
      });

      test('without clear flags preserves existing values', () {
        final original = SessionState(
          pendingResponse: createTestMessage(),
          activeTool: createTestToolCall(),
          activeChart: createTestChart(),
          errorMessage: 'Error',
        );
        final copied = original.copyWithCleared();

        expect(copied.pendingResponse, equals(original.pendingResponse));
        expect(copied.activeTool, equals(original.activeTool));
        expect(copied.activeChart, equals(original.activeChart));
        expect(copied.errorMessage, equals(original.errorMessage));
      });

      test('new value takes precedence when not clearing', () {
        const original = SessionState(errorMessage: 'Old error');
        final updated = original.copyWithCleared(errorMessage: 'New error');

        expect(updated.errorMessage, equals('New error'));
      });
    });

    group('equality', () {
      test('same values are equal', () {
        final message = createTestMessage();
        final chart = createTestChart();

        final state1 = SessionState(
          history: [message],
          status: ActivityStatus.thinking,
          activeChart: chart,
        );
        final state2 = SessionState(
          history: [message],
          status: ActivityStatus.thinking,
          activeChart: chart,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('different history makes instances not equal', () {
        final state1 = SessionState(history: [createTestMessage(id: 'msg_1')]);
        final state2 = SessionState(history: [createTestMessage(id: 'msg_2')]);

        expect(state1, isNot(equals(state2)));
      });

      test('different pendingResponse makes instances not equal', () {
        final state1 = SessionState(
          pendingResponse: createTestMessage(id: 'pending_1'),
        );
        final state2 = SessionState(
          pendingResponse: createTestMessage(id: 'pending_2'),
        );

        expect(state1, isNot(equals(state2)));
      });

      test('different activeTool makes instances not equal', () {
        final state1 = SessionState(
          activeTool: createTestToolCall(id: 'tool_1'),
        );
        final state2 = SessionState(
          activeTool: createTestToolCall(id: 'tool_2'),
        );

        expect(state1, isNot(equals(state2)));
      });

      test('different status makes instances not equal', () {
        const state1 = SessionState(status: ActivityStatus.idle);
        const state2 = SessionState(status: ActivityStatus.thinking);

        expect(state1, isNot(equals(state2)));
      });

      test('different activeChart makes instances not equal', () {
        final state1 = SessionState(
          activeChart: createTestChart(id: 'chart_1'),
        );
        final state2 = SessionState(
          activeChart: createTestChart(id: 'chart_2'),
        );

        expect(state1, isNot(equals(state2)));
      });

      test('different errorMessage makes instances not equal', () {
        const state1 = SessionState(errorMessage: 'Error 1');
        const state2 = SessionState(errorMessage: 'Error 2');

        expect(state1, isNot(equals(state2)));
      });

      test('null vs non-null fields makes instances not equal', () {
        final state1 = SessionState(activeChart: createTestChart());
        const state2 = SessionState();

        expect(state1, isNot(equals(state2)));
      });

      test('default instances are equal', () {
        const state1 = SessionState();
        const state2 = SessionState();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });
    });

    group('toString', () {
      test('includes status and history length', () {
        final state = SessionState(
          history: [createTestMessage(), createTestMessage(id: 'msg_2')],
          status: ActivityStatus.thinking,
        );

        final result = state.toString();
        expect(result, contains('status: ActivityStatus.thinking'));
        expect(result, contains('history: 2 messages'));
      });

      test('indicates activeChart presence when present', () {
        final state = SessionState(activeChart: createTestChart());

        expect(state.toString(), contains('activeChart: true'));
      });

      test('indicates activeChart absence when null', () {
        const state = SessionState();

        expect(state.toString(), contains('activeChart: false'));
      });

      test('format is consistent', () {
        const state = SessionState();
        final result = state.toString();

        expect(
          result,
          equals(
            'SessionState(status: ActivityStatus.idle, '
            'history: 0 messages, activeChart: false)',
          ),
        );
      });
    });
  });

  // ============================================================
  // AgentEvent Tests
  // ============================================================
  group('AgentEvent', () {
    group('sealed class structure', () {
      test('has exactly 7 concrete event types', () {
        // This test verifies the sealed hierarchy by checking
        // that all expected event types can be instantiated
        final events = <AgentEvent>[
          ChartCreatedEvent(config: createTestChart()),
          ChartUpdatedEvent(config: createTestChart()),
          const ErrorEvent(message: 'error'),
          const ThinkingEvent(description: 'thinking'),
          const ToolStartEvent(toolName: 'tool'),
          const ToolEndEvent(toolName: 'tool', success: true),
          const CancelledEvent(),
        ];

        expect(events, hasLength(7));
      });
    });

    group('ChartCreatedEvent', () {
      test('creates instance with config', () {
        final chart = createTestChart(id: 'new_chart', title: 'New Chart');
        final event = ChartCreatedEvent(config: chart);

        expect(event.config, equals(chart));
        expect(event.config.id, equals('new_chart'));
        expect(event.config.title, equals('New Chart'));
      });

      test('is instance of AgentEvent', () {
        final event = ChartCreatedEvent(config: createTestChart());

        expect(event, isA<AgentEvent>());
      });

      test('toString includes chart id', () {
        final chart = createTestChart(id: 'chart_abc123');
        final event = ChartCreatedEvent(config: chart);

        expect(
          event.toString(),
          equals('ChartCreatedEvent(chartId: chart_abc123)'),
        );
      });

      test('toString handles null chart id', () {
        final chart = createTestChart(id: null);
        final event = ChartCreatedEvent(config: chart);

        expect(event.toString(), equals('ChartCreatedEvent(chartId: null)'));
      });
    });

    group('ChartUpdatedEvent', () {
      test('creates instance with config', () {
        final chart = createTestChart(id: 'updated_chart', title: 'Updated');
        final event = ChartUpdatedEvent(config: chart);

        expect(event.config, equals(chart));
        expect(event.config.id, equals('updated_chart'));
      });

      test('is instance of AgentEvent', () {
        final event = ChartUpdatedEvent(config: createTestChart());

        expect(event, isA<AgentEvent>());
      });

      test('toString includes chart id', () {
        final chart = createTestChart(id: 'chart_xyz789');
        final event = ChartUpdatedEvent(config: chart);

        expect(
          event.toString(),
          equals('ChartUpdatedEvent(chartId: chart_xyz789)'),
        );
      });

      test('toString handles null chart id', () {
        final chart = createTestChart(id: null);
        final event = ChartUpdatedEvent(config: chart);

        expect(event.toString(), equals('ChartUpdatedEvent(chartId: null)'));
      });
    });

    group('ErrorEvent', () {
      test('creates instance with message only', () {
        const event = ErrorEvent(message: 'Something went wrong');

        expect(event.message, equals('Something went wrong'));
        expect(event.originalError, isNull);
      });

      test('creates instance with message and originalError', () {
        final error = Exception('Original exception');
        final event = ErrorEvent(
          message: 'Wrapped error',
          originalError: error,
        );

        expect(event.message, equals('Wrapped error'));
        expect(event.originalError, equals(error));
      });

      test('originalError can be any Object', () {
        const event = ErrorEvent(
          message: 'String error',
          originalError: 'Not an Exception',
        );

        expect(event.originalError, equals('Not an Exception'));
      });

      test('is instance of AgentEvent', () {
        const event = ErrorEvent(message: 'error');

        expect(event, isA<AgentEvent>());
      });

      test('toString includes message and hasOriginal when null', () {
        const event = ErrorEvent(message: 'Connection failed');

        expect(
          event.toString(),
          equals('ErrorEvent(message: Connection failed, hasOriginal: false)'),
        );
      });

      test('toString includes message and hasOriginal when present', () {
        final event = ErrorEvent(
          message: 'Database error',
          originalError: Exception('SQL error'),
        );

        expect(
          event.toString(),
          equals('ErrorEvent(message: Database error, hasOriginal: true)'),
        );
      });
    });

    group('ThinkingEvent', () {
      test('creates instance with description', () {
        const event = ThinkingEvent(description: 'Analyzing data...');

        expect(event.description, equals('Analyzing data...'));
      });

      test('is instance of AgentEvent', () {
        const event = ThinkingEvent(description: 'thinking');

        expect(event, isA<AgentEvent>());
      });

      test('toString includes description', () {
        const event = ThinkingEvent(description: 'Processing your request');

        expect(
          event.toString(),
          equals('ThinkingEvent(description: Processing your request)'),
        );
      });

      test('description can be empty string', () {
        const event = ThinkingEvent(description: '');

        expect(event.description, isEmpty);
        expect(event.toString(), equals('ThinkingEvent(description: )'));
      });
    });

    group('ToolStartEvent', () {
      test('creates instance with toolName', () {
        const event = ToolStartEvent(toolName: 'create_chart');

        expect(event.toolName, equals('create_chart'));
      });

      test('is instance of AgentEvent', () {
        const event = ToolStartEvent(toolName: 'tool');

        expect(event, isA<AgentEvent>());
      });

      test('toString includes toolName', () {
        const event = ToolStartEvent(toolName: 'modify_chart');

        expect(
          event.toString(),
          equals('ToolStartEvent(toolName: modify_chart)'),
        );
      });
    });

    group('ToolEndEvent', () {
      test('creates instance with toolName and success true', () {
        const event = ToolEndEvent(toolName: 'create_chart', success: true);

        expect(event.toolName, equals('create_chart'));
        expect(event.success, isTrue);
      });

      test('creates instance with toolName and success false', () {
        const event = ToolEndEvent(toolName: 'create_chart', success: false);

        expect(event.toolName, equals('create_chart'));
        expect(event.success, isFalse);
      });

      test('is instance of AgentEvent', () {
        const event = ToolEndEvent(toolName: 'tool', success: true);

        expect(event, isA<AgentEvent>());
      });

      test('toString includes toolName and success true', () {
        const event = ToolEndEvent(toolName: 'create_chart', success: true);

        expect(
          event.toString(),
          equals('ToolEndEvent(toolName: create_chart, success: true)'),
        );
      });

      test('toString includes toolName and success false', () {
        const event = ToolEndEvent(toolName: 'modify_chart', success: false);

        expect(
          event.toString(),
          equals('ToolEndEvent(toolName: modify_chart, success: false)'),
        );
      });
    });

    group('CancelledEvent', () {
      test('creates instance with no parameters', () {
        const event = CancelledEvent();

        expect(event, isNotNull);
      });

      test('is instance of AgentEvent', () {
        const event = CancelledEvent();

        expect(event, isA<AgentEvent>());
      });

      test('toString returns expected format', () {
        const event = CancelledEvent();

        expect(event.toString(), equals('CancelledEvent()'));
      });

      test('multiple instances are created independently', () {
        const event1 = CancelledEvent();
        const event2 = CancelledEvent();

        // Both should exist independently
        expect(event1, isNotNull);
        expect(event2, isNotNull);
      });
    });

    group('pattern matching', () {
      test('switch expression works with all event types', () {
        final events = <AgentEvent>[
          ChartCreatedEvent(config: createTestChart()),
          ChartUpdatedEvent(config: createTestChart()),
          const ErrorEvent(message: 'error'),
          const ThinkingEvent(description: 'thinking'),
          const ToolStartEvent(toolName: 'tool'),
          const ToolEndEvent(toolName: 'tool', success: true),
          const CancelledEvent(),
        ];

        final results = <String>[];
        for (final event in events) {
          final result = switch (event) {
            ChartCreatedEvent(:final config) => 'created:${config.id}',
            ChartUpdatedEvent(:final config) => 'updated:${config.id}',
            ErrorEvent(:final message) => 'error:$message',
            ThinkingEvent(:final description) => 'thinking:$description',
            ToolStartEvent(:final toolName) => 'start:$toolName',
            ToolEndEvent(:final toolName, :final success) =>
              'end:$toolName:$success',
            CancelledEvent() => 'cancelled',
          };
          results.add(result);
        }

        expect(results[0], equals('created:chart_1'));
        expect(results[1], equals('updated:chart_1'));
        expect(results[2], equals('error:error'));
        expect(results[3], equals('thinking:thinking'));
        expect(results[4], equals('start:tool'));
        expect(results[5], equals('end:tool:true'));
        expect(results[6], equals('cancelled'));
      });
    });
  });

  // ============================================================
  // Edge Cases
  // ============================================================
  group('Edge cases', () {
    group('null/empty states', () {
      test('SessionState with all nulls handles correctly', () {
        const state = SessionState();

        expect(state.pendingResponse, isNull);
        expect(state.activeTool, isNull);
        expect(state.activeChart, isNull);
        expect(state.errorMessage, isNull);
        expect(state.history, isEmpty);
      });

      test('ToolCall with empty input works', () {
        const toolCall = ToolCall(id: 'toolu_1', name: 'simple', input: {});

        expect(toolCall.input, isEmpty);
        expect(toolCall.toString(), contains('simple'));
      });

      test('SessionState with empty history list', () {
        const state = SessionState(history: []);

        expect(state.history, isEmpty);
        expect(state.toString(), contains('0 messages'));
      });

      test('ErrorEvent with empty message', () {
        const event = ErrorEvent(message: '');

        expect(event.message, isEmpty);
        expect(event.toString(), contains('message: ,'));
      });

      test('ChartConfiguration with null id in events', () {
        final chart = createTestChart(id: null);
        final created = ChartCreatedEvent(config: chart);
        final updated = ChartUpdatedEvent(config: chart);

        expect(created.config.id, isNull);
        expect(updated.config.id, isNull);
        expect(created.toString(), contains('null'));
        expect(updated.toString(), contains('null'));
      });
    });

    group('large collections', () {
      test('SessionState with many messages in history', () {
        final messages = List.generate(
          100,
          (i) => createTestMessage(id: 'msg_$i'),
        );
        final state = SessionState(history: messages);

        expect(state.history, hasLength(100));
        expect(state.toString(), contains('100 messages'));
      });

      test('ToolCall with complex nested input', () {
        const toolCall = ToolCall(
          id: 'toolu_complex',
          name: 'complex_tool',
          input: {
            'level1': {
              'level2': {
                'level3': {'deep': 'value'},
              },
            },
            'array': [
              1,
              2,
              3,
              {'nested': true}
            ],
          },
        );

        expect(toolCall.input['level1'], isA<Map>());
        expect(toolCall.input['array'], isA<List>());
      });
    });
  });
}
