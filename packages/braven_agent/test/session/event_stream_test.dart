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
import 'package:braven_agent/src/tools/tool_result.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// Mock LLM Provider for Test Isolation
// ============================================================

/// Mock LLM provider that returns controlled responses for testing.
class MockLLMProvider implements LLMProvider {
  /// The next response to return from [generateResponse].
  LLMResponse? nextResponse;

  /// Queue of responses for multi-turn conversations.
  final List<LLMResponse> responseQueue = [];

  /// Whether [generateResponse] should throw an error.
  bool shouldThrow = false;

  /// The error to throw when [shouldThrow] is true.
  Exception? nextError;

  @override
  String get id => 'mock-provider';

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    if (shouldThrow) {
      throw nextError ?? Exception('Mock LLM error');
    }

    if (responseQueue.isNotEmpty) {
      return responseQueue.removeAt(0);
    }

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

// ============================================================
// Mock Agent Tool for Test Isolation
// ============================================================

/// Mock tool for testing tool execution flow.
class MockAgentTool implements AgentTool {
  final String _name;
  final String _description;
  final Map<String, dynamic> _inputSchema;

  /// The next result to return from [execute].
  ToolResult? nextResult;

  /// Whether [execute] should throw an error.
  bool shouldThrow = false;

  MockAgentTool({
    String name = 'mock_tool',
    String description = 'A mock tool for testing',
    Map<String, dynamic>? inputSchema,
  })  : _name = name,
        _description = description,
        _inputSchema = inputSchema ?? const {'type': 'object'};

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Map<String, dynamic> get inputSchema => _inputSchema;

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    if (shouldThrow) {
      throw Exception('Mock tool error');
    }

    return nextResult ??
        const ToolResult(
          output: '{"success": true}',
          isError: false,
        );
  }
}

// ============================================================
// Test Helper Functions
// ============================================================

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

LLMResponse createToolUseResponse({
  required String toolName,
  Map<String, dynamic>? input,
}) {
  return LLMResponse(
    message: AgentMessage(
      id: 'msg_tool',
      role: MessageRole.assistant,
      content: [
        ToolUseContent(
          id: 'toolu_123',
          toolName: toolName,
          input: input ?? const {},
        ),
      ],
      timestamp: DateTime(2024, 1, 15, 10, 30),
    ),
    inputTokens: 100,
    outputTokens: 50,
    stopReason: 'tool_use',
  );
}

LLMResponse createMultiToolUseResponse(List<ToolUseContent> toolUses) {
  return LLMResponse(
    message: AgentMessage(
      id: 'msg_tool_multi',
      role: MessageRole.assistant,
      content: toolUses,
      timestamp: DateTime(2024, 1, 15, 10, 30),
    ),
    inputTokens: 120,
    outputTokens: 60,
    stopReason: 'tool_use',
  );
}

LLMResponse createTextResponse(String text) {
  return LLMResponse(
    message: AgentMessage(
      id: 'msg_text',
      role: MessageRole.assistant,
      content: [TextContent(text: text)],
      timestamp: DateTime(2024, 1, 15, 10, 30),
    ),
    inputTokens: 100,
    outputTokens: 50,
    stopReason: 'end_turn',
  );
}

Future<void> flushEventQueue() => Future<void>.delayed(Duration.zero);

void main() {
  group('AgentSessionImpl event stream', () {
    test('emits ThinkingEvent with description when transform starts',
        () async {
      final mockProvider = MockLLMProvider();
      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: const [],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final thinkingEvents = events.whereType<ThinkingEvent>().toList();
      expect(thinkingEvents, isNotEmpty);
      expect(
        thinkingEvents.first.description,
        equals('Processing your request...'),
      );
    });

    test('emits ToolStartEvent with correct toolName', () async {
      final mockProvider = MockLLMProvider();
      final mockTool = MockAgentTool(name: 'create_chart');
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final startEvents = events.whereType<ToolStartEvent>().toList();
      expect(startEvents, isNotEmpty);
      expect(startEvents.first.toolName, equals('create_chart'));
    });

    test('emits ToolEndEvent with success=true for successful tool', () async {
      final mockProvider = MockLLMProvider();
      final mockTool = MockAgentTool(name: 'create_chart');
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final endEvents = events.whereType<ToolEndEvent>().toList();
      expect(endEvents, isNotEmpty);
      expect(endEvents.first.toolName, equals('create_chart'));
      expect(endEvents.first.success, isTrue);
    });

    test('emits ToolEndEvent with success=false when tool returns error',
        () async {
      final mockProvider = MockLLMProvider();
      final mockTool = MockAgentTool(name: 'create_chart');
      mockTool.nextResult = const ToolResult(
        output: 'Error: invalid chart',
        isError: true,
      );
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Handled'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create an invalid chart');
      await flushEventQueue();

      final endEvents = events.whereType<ToolEndEvent>().toList();
      expect(endEvents, isNotEmpty);
      expect(endEvents.first.success, isFalse);
    });

    test('emits ToolEndEvent with success=false when tool throws', () async {
      final mockProvider = MockLLMProvider();
      final mockTool = MockAgentTool(name: 'create_chart')..shouldThrow = true;
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Handled'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final endEvents = events.whereType<ToolEndEvent>().toList();
      expect(endEvents, isNotEmpty);
      expect(endEvents.first.success, isFalse);
    });

    test('emits ChartCreatedEvent when first chart is created', () async {
      final mockProvider = MockLLMProvider();
      final chart = createTestChart(id: 'new_chart');
      final mockTool = MockAgentTool(name: 'create_chart');
      mockTool.nextResult = ToolResult(
        output: '{"chartId": "new_chart"}',
        isError: false,
        data: chart,
      );
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Created'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final createEvents = events.whereType<ChartCreatedEvent>().toList();
      expect(createEvents, isNotEmpty);
      expect(createEvents.first.config.id, equals('new_chart'));
    });

    test('emits ChartUpdatedEvent when existing chart is modified', () async {
      final mockProvider = MockLLMProvider();
      final existingChart = createTestChart(id: 'existing_chart');
      final updatedChart = createTestChart(
        id: 'existing_chart',
        title: 'Updated Title',
      );

      final mockTool = MockAgentTool(name: 'modify_chart');
      mockTool.nextResult = ToolResult(
        output: '{"chartId": "existing_chart"}',
        isError: false,
        data: updatedChart,
      );
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'modify_chart'),
        createTextResponse('Updated'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      session.updateChart(existingChart);

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Update the chart');
      await flushEventQueue();

      final updateEvents = events.whereType<ChartUpdatedEvent>().toList();
      expect(updateEvents, isNotEmpty);
      expect(updateEvents.first.config.title, equals('Updated Title'));

      final createEvents = events.whereType<ChartCreatedEvent>().toList();
      expect(createEvents, isEmpty);
    });

    test('emits ErrorEvent with message and originalError on LLM error',
        () async {
      final mockProvider = MockLLMProvider()
        ..shouldThrow = true
        ..nextError = Exception('Boom');

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: const [],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Trigger error');
      await flushEventQueue();

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(errorEvents, isNotEmpty);
      expect(errorEvents.first.message, equals('Boom'));
      expect(errorEvents.first.originalError, isNotNull);
    });

    test('emits CancelledEvent when cancel is called', () async {
      final mockProvider = MockLLMProvider();
      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: const [],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.cancel();
      await flushEventQueue();

      final cancelEvents = events.whereType<CancelledEvent>().toList();
      expect(cancelEvents, isNotEmpty);
    });

    test('emits ToolStartEvent before ToolEndEvent for a tool', () async {
      final mockProvider = MockLLMProvider();
      final mockTool = MockAgentTool(name: 'create_chart');
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final startIndex = events.indexWhere((e) => e is ToolStartEvent);
      final endIndex = events.indexWhere((e) => e is ToolEndEvent);
      expect(startIndex, isNonNegative);
      expect(endIndex, isNonNegative);
      expect(startIndex, lessThan(endIndex));
    });

    test('emits events in order for multiple tool uses', () async {
      final mockProvider = MockLLMProvider();
      final createTool = MockAgentTool(name: 'create_chart');
      final modifyTool = MockAgentTool(name: 'modify_chart');
      mockProvider.responseQueue.addAll([
        createMultiToolUseResponse([
          const ToolUseContent(
            id: 'toolu_1',
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          const ToolUseContent(
            id: 'toolu_2',
            toolName: 'modify_chart',
            input: {'title': 'Updated'},
          ),
        ]),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [createTool, modifyTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create and update');
      await flushEventQueue();

      final orderedTypes = events
          .where((event) =>
              event is ThinkingEvent ||
              event is ToolStartEvent ||
              event is ToolEndEvent)
          .map((event) => event.runtimeType)
          .toList();

      expect(
        orderedTypes,
        equals([
          ThinkingEvent,
          ToolStartEvent,
          ToolEndEvent,
          ToolStartEvent,
          ToolEndEvent,
        ]),
      );
    });

    test('ToolStartEvent and ToolEndEvent carry correct toolName per tool',
        () async {
      final mockProvider = MockLLMProvider();
      final createTool = MockAgentTool(name: 'create_chart');
      final modifyTool = MockAgentTool(name: 'modify_chart');
      mockProvider.responseQueue.addAll([
        createMultiToolUseResponse([
          const ToolUseContent(
            id: 'toolu_1',
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          const ToolUseContent(
            id: 'toolu_2',
            toolName: 'modify_chart',
            input: {'title': 'Updated'},
          ),
        ]),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [createTool, modifyTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create and update');
      await flushEventQueue();

      final startEvents = events.whereType<ToolStartEvent>().toList();
      final endEvents = events.whereType<ToolEndEvent>().toList();

      expect(startEvents.length, equals(2));
      expect(endEvents.length, equals(2));
      expect(startEvents.first.toolName, equals('create_chart'));
      expect(startEvents.last.toolName, equals('modify_chart'));
      expect(endEvents.first.toolName, equals('create_chart'));
      expect(endEvents.last.toolName, equals('modify_chart'));
    });

    test('ToolEndEvent success reflects tool result per tool', () async {
      final mockProvider = MockLLMProvider();
      final createTool = MockAgentTool(name: 'create_chart')
        ..nextResult = const ToolResult(
          output: '{"ok": true}',
          isError: false,
        );
      final modifyTool = MockAgentTool(name: 'modify_chart')
        ..nextResult = const ToolResult(
          output: 'Error: failed',
          isError: true,
        );
      mockProvider.responseQueue.addAll([
        createMultiToolUseResponse([
          const ToolUseContent(
            id: 'toolu_1',
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          const ToolUseContent(
            id: 'toolu_2',
            toolName: 'modify_chart',
            input: {'title': 'Updated'},
          ),
        ]),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [createTool, modifyTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create and update');
      await flushEventQueue();

      final endEvents = events.whereType<ToolEndEvent>().toList();
      expect(endEvents.length, equals(2));
      expect(endEvents.first.success, isTrue);
      expect(endEvents.last.success, isFalse);
    });

    test('does not emit ErrorEvent on successful flow', () async {
      final mockProvider = MockLLMProvider();
      final mockTool = MockAgentTool(name: 'create_chart');
      mockProvider.responseQueue.addAll([
        createToolUseResponse(toolName: 'create_chart'),
        createTextResponse('Done'),
      ]);

      final session = AgentSessionImpl(
        llmProvider: mockProvider,
        tools: [mockTool],
        systemPrompt: 'System prompt',
      );

      final events = <AgentEvent>[];
      session.events.listen(events.add);

      await session.transform('Create a chart');
      await flushEventQueue();

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(errorEvents, isEmpty);
    });
  });
}
