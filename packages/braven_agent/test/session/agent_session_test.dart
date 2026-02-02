import 'package:braven_agent/src/llm/llm_config.dart';
import 'package:braven_agent/src/llm/llm_provider.dart';
import 'package:braven_agent/src/llm/llm_response.dart';
import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/session/agent_events.dart';
import 'package:braven_agent/src/session/agent_session_impl.dart';
import 'package:braven_agent/src/session/session_state.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:braven_agent/src/tools/tool_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// Mock LLM Provider for Test Isolation
// ============================================================

/// Mock LLM provider that returns controlled responses for testing.
///
/// Allows tests to specify exact responses, simulate errors, and
/// track method calls.
///
/// Supports a queue of responses via [responseQueue] for multi-turn
/// conversations. If [responseQueue] is not empty, responses are
/// dequeued in order. Otherwise, [nextResponse] or [defaultResponse]
/// is returned.
class MockLLMProvider implements LLMProvider {
  /// The next response to return from [generateResponse].
  LLMResponse? nextResponse;

  /// Queue of responses for multi-turn conversations.
  /// Responses are dequeued in order (first in, first out).
  final List<LLMResponse> responseQueue = [];

  /// Whether [generateResponse] should throw an error.
  bool shouldThrow = false;

  /// The error to throw when [shouldThrow] is true.
  Exception? nextError;

  /// Tracks calls to [generateResponse].
  final List<MockLLMCall> calls = [];

  /// The default response when [nextResponse] is null.
  LLMResponse get defaultResponse => LLMResponse(
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

  @override
  String get id => 'mock-provider';

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    calls.add(MockLLMCall(
      systemPrompt: systemPrompt,
      history: history,
      tools: tools,
      config: config,
    ));

    if (shouldThrow) {
      throw nextError ?? Exception('Mock LLM error');
    }

    // Use queue if available, otherwise fall back to nextResponse/default
    if (responseQueue.isNotEmpty) {
      return responseQueue.removeAt(0);
    }

    return nextResponse ?? defaultResponse;
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

  /// Resets the mock to its initial state.
  void reset() {
    nextResponse = null;
    responseQueue.clear();
    shouldThrow = false;
    nextError = null;
    calls.clear();
  }
}

/// Record of a call to [MockLLMProvider.generateResponse].
class MockLLMCall {
  final String systemPrompt;
  final List<AgentMessage> history;
  final List<AgentTool>? tools;
  final LLMConfig? config;

  MockLLMCall({
    required this.systemPrompt,
    required this.history,
    this.tools,
    this.config,
  });
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

  /// Tracks calls to [execute].
  final List<Map<String, dynamic>> executeCalls = [];

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
    executeCalls.add(input);

    if (shouldThrow) {
      throw Exception('Mock tool error');
    }

    return nextResult ??
        const ToolResult(
          output: '{"success": true}',
          isError: false,
        );
  }

  /// Resets the mock to its initial state.
  void reset() {
    nextResult = null;
    shouldThrow = false;
    executeCalls.clear();
  }
}

// ============================================================
// Test Helper Functions
// ============================================================

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

/// Creates an LLM response with tool use content.
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

/// Creates a simple text response from the LLM.
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

// ============================================================
// Tests
// ============================================================

void main() {
  // ============================================================
  // Construction Tests
  // ============================================================
  group('AgentSessionImpl', () {
    group('construction', () {
      test('accepts required dependencies: LLMProvider, tools, systemPrompt',
          () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool();
        const systemPrompt = 'You are a chart creation assistant.';

        // Act - should not throw
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: systemPrompt,
        );

        // Assert - session was created successfully
        expect(session, isNotNull);
        expect(session, isA<AgentSessionImpl>());
      });

      test('accepts empty tools list', () {
        // Arrange
        final mockProvider = MockLLMProvider();

        // Act - should not throw with empty tools
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Assert
        expect(session, isNotNull);
      });

      test('accepts multiple tools', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final tools = [
          MockAgentTool(name: 'create_chart'),
          MockAgentTool(name: 'modify_chart'),
          MockAgentTool(name: 'delete_chart'),
        ];

        // Act
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: tools,
          systemPrompt: 'System prompt',
        );

        // Assert
        expect(session, isNotNull);
      });

      test('initializes with idle status', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.status, equals(ActivityStatus.idle));
      });

      test('initializes with empty history', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.history, isEmpty);
      });

      test('initializes with null activeChart', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.activeChart, isNull);
      });

      test('initializes with null activeTool', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.activeTool, isNull);
      });
    });

    // ============================================================
    // State Getter Tests
    // ============================================================
    group('state', () {
      test('returns ValueListenable<SessionState>', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state, isA<ValueListenable<SessionState>>());
      });

      test('initial state has status=idle', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.status, equals(ActivityStatus.idle));
      });

      test('initial state has empty history', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.history, equals(const <AgentMessage>[]));
      });

      test('initial state has null activeChart', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.activeChart, isNull);
      });

      test('initial state has null activeTool', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.activeTool, isNull);
      });

      test('initial state has null pendingResponse', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.pendingResponse, isNull);
      });

      test('initial state has null errorMessage', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.state.value.errorMessage, isNull);
      });

      test('state.value returns immutable SessionState', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        final state1 = session.state.value;
        final state2 = session.state.value;

        // Assert - same instance for initial state
        expect(identical(state1, state2), isTrue);
      });
    });

    // ============================================================
    // Events Getter Tests
    // ============================================================
    group('events', () {
      test('returns Stream<AgentEvent>', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert
        expect(session.events, isA<Stream<AgentEvent>>());
      });

      test('events stream is broadcast - can have multiple listeners', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act - should not throw when adding multiple listeners
        final events = <AgentEvent>[];
        final sub1 = session.events.listen(events.add);
        final sub2 = session.events.listen(events.add);

        // Assert - both subscriptions are valid
        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        // Cleanup
        sub1.cancel();
        sub2.cancel();
      });

      test('events stream allows listener after previous listener cancelled',
          () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        final sub1 = session.events.listen((_) {});
        await sub1.cancel();

        // Should not throw - can add new listener after cancel
        final sub2 = session.events.listen((_) {});
        expect(sub2, isNotNull);
        await sub2.cancel();
      });
    });

    // ============================================================
    // Transform Method Tests
    // ============================================================
    group('transform', () {
      test('sets status to ActivityStatus.thinking when called', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        final statuses = <ActivityStatus>[];
        session.state.addListener(() {
          statuses.add(session.state.value.status);
        });

        // Act
        await session.transform('Create a chart');

        // Assert - should have transitioned through thinking
        expect(statuses, contains(ActivityStatus.thinking));
      });

      test('emits ThinkingEvent when processing prompt', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act
        await session.transform('Create a chart');

        // Assert
        expect(
          events.whereType<ThinkingEvent>().isNotEmpty,
          isTrue,
          reason: 'Should emit ThinkingEvent when processing',
        );
      });

      test('adds user message to history', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a line chart');

        // Assert
        final history = session.state.value.history;
        expect(history.length, greaterThanOrEqualTo(1));

        // Find the user message
        final userMessages =
            history.where((m) => m.role == MessageRole.user).toList();
        expect(userMessages, isNotEmpty);

        // Check the prompt is in the content
        final userMessage = userMessages.first;
        final textContent = userMessage.content
            .whereType<TextContent>()
            .map((c) => c.text)
            .join();
        expect(textContent, contains('Create a line chart'));
      });

      test('calls LLMProvider.generateResponse with system prompt', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        const systemPrompt = 'You are a helpful chart assistant.';
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: systemPrompt,
        );

        // Act
        await session.transform('Hello');

        // Assert
        expect(mockProvider.calls, isNotEmpty);
        expect(mockProvider.calls.first.systemPrompt, equals(systemPrompt));
      });

      test('calls LLMProvider.generateResponse with history', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a chart');

        // Assert
        expect(mockProvider.calls, isNotEmpty);
        expect(mockProvider.calls.first.history, isNotEmpty);
      });

      test('appends assistant response to history after completion', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        mockProvider.nextResponse = createTextResponse('Here is your chart!');
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a chart');

        // Assert
        final history = session.state.value.history;
        final assistantMessages =
            history.where((m) => m.role == MessageRole.assistant).toList();
        expect(assistantMessages, isNotEmpty);
      });

      test('sets status to idle after successful completion', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a chart');

        // Assert
        expect(session.state.value.status, equals(ActivityStatus.idle));
      });

      test('handles attachments parameter', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform(
          'Analyze this image',
          attachments: [
            const BinaryContent(
              data: 'base64data',
              mimeType: 'image/png',
              filename: 'chart.png',
            ),
          ],
        );

        // Assert - should complete without error
        expect(session.state.value.status, equals(ActivityStatus.idle));
      });

      group('error handling', () {
        test('sets status to error when LLM throws', () async {
          // Arrange
          final mockProvider = MockLLMProvider();
          mockProvider.shouldThrow = true;
          mockProvider.nextError = Exception('Network error');
          final session = AgentSessionImpl(
            llmProvider: mockProvider,
            tools: const [],
            systemPrompt: 'System prompt',
          );

          // Act
          await session.transform('Create a chart');

          // Assert
          expect(session.state.value.status, equals(ActivityStatus.error));
        });

        test('emits ErrorEvent when LLM throws', () async {
          // Arrange
          final mockProvider = MockLLMProvider();
          mockProvider.shouldThrow = true;
          mockProvider.nextError = Exception('Network error');
          final session = AgentSessionImpl(
            llmProvider: mockProvider,
            tools: const [],
            systemPrompt: 'System prompt',
          );

          final events = <AgentEvent>[];
          final subscription = session.events.listen(events.add);

          // Act
          await session.transform('Create a chart');

          // Give time for events to propagate
          await Future<void>.delayed(Duration.zero);

          // Clean up
          await subscription.cancel();

          // Assert
          final errorEvents = events.whereType<ErrorEvent>().toList();
          expect(errorEvents, isNotEmpty);
        });

        test('sets errorMessage in state when LLM throws', () async {
          // Arrange
          final mockProvider = MockLLMProvider();
          mockProvider.shouldThrow = true;
          mockProvider.nextError = Exception('Network error');
          final session = AgentSessionImpl(
            llmProvider: mockProvider,
            tools: const [],
            systemPrompt: 'System prompt',
          );

          // Act
          await session.transform('Create a chart');

          // Assert
          expect(session.state.value.errorMessage, isNotNull);
        });

        test('does not throw when LLM throws - handles gracefully', () async {
          // Arrange
          final mockProvider = MockLLMProvider();
          mockProvider.shouldThrow = true;
          mockProvider.nextError = Exception('Network error');
          final session = AgentSessionImpl(
            llmProvider: mockProvider,
            tools: const [],
            systemPrompt: 'System prompt',
          );

          // Act & Assert - should complete without throwing
          await expectLater(
            session.transform('Create a chart'),
            completes,
          );
        });
      });
    });

    // ============================================================
    // Tool Execution Tests
    // ============================================================
    group('tool execution', () {
      test('sets status to calling_tool when LLM returns tool_use', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created successfully'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        final statuses = <ActivityStatus>[];
        session.state.addListener(() {
          statuses.add(session.state.value.status);
        });

        // Act
        await session.transform('Create a line chart');

        // Assert
        expect(statuses, contains(ActivityStatus.calling_tool));
      });

      test('sets activeTool with ToolCall info when executing tool', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created successfully'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        ToolCall? capturedToolCall;
        session.state.addListener(() {
          if (session.state.value.activeTool != null) {
            capturedToolCall = session.state.value.activeTool;
          }
        });

        // Act
        await session.transform('Create a chart');

        // Assert
        expect(capturedToolCall, isNotNull);
        expect(capturedToolCall!.name, equals('create_chart'));
      });

      test('emits ToolStartEvent when tool execution begins', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created successfully'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act
        await session.transform('Create a chart');

        // Assert
        final startEvents = events.whereType<ToolStartEvent>().toList();
        expect(startEvents, isNotEmpty);
        expect(startEvents.first.toolName, equals('create_chart'));
      });

      test('emits ToolEndEvent when tool execution completes', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created successfully'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act
        await session.transform('Create a chart');

        // Assert
        final endEvents = events.whereType<ToolEndEvent>().toList();
        expect(endEvents, isNotEmpty);
        expect(endEvents.first.toolName, equals('create_chart'));
        expect(endEvents.first.success, isTrue);
      });

      test('ToolEndEvent.success is false when tool throws', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockTool.shouldThrow = true;
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Error handled'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act
        await session.transform('Create a chart');

        // Assert
        final endEvents = events.whereType<ToolEndEvent>().toList();
        expect(endEvents, isNotEmpty);
        expect(endEvents.first.success, isFalse);
      });

      test('executes the correct tool based on toolName', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final createTool = MockAgentTool(name: 'create_chart');
        final modifyTool = MockAgentTool(name: 'modify_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'modify_chart',
            input: {'chartId': 'chart_1'},
          ),
          createTextResponse('Chart modified successfully'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [createTool, modifyTool],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Modify the chart');

        // Assert - only modifyTool should be called
        expect(createTool.executeCalls, isEmpty);
        expect(modifyTool.executeCalls, isNotEmpty);
      });

      test('passes input to tool.execute', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'bar', 'title': 'Sales'},
          ),
          createTextResponse('Bar chart created'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a bar chart');

        // Assert
        expect(mockTool.executeCalls, isNotEmpty);
        expect(mockTool.executeCalls.first['type'], equals('bar'));
        expect(mockTool.executeCalls.first['title'], equals('Sales'));
      });

      test('clears activeTool after tool execution completes', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a chart');

        // Assert - activeTool should be null after completion
        expect(session.state.value.activeTool, isNull);
      });
    });

    // ============================================================
    // Chart Creation Tests
    // ============================================================
    group('chart creation', () {
      test('updates activeChart when tool result contains ChartConfiguration',
          () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final chart = createTestChart(id: 'new_chart', title: 'New Chart');
        final mockTool = MockAgentTool(name: 'create_chart');
        mockTool.nextResult = ToolResult(
          output: '{"chartId": "new_chart"}',
          isError: false,
          data: chart,
        );
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create a chart');

        // Assert
        expect(session.state.value.activeChart, isNotNull);
        expect(session.state.value.activeChart!.id, equals('new_chart'));
      });

      test('emits ChartCreatedEvent when new chart is created', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final chart = createTestChart(id: 'new_chart', title: 'New Chart');
        final mockTool = MockAgentTool(name: 'create_chart');
        mockTool.nextResult = ToolResult(
          output: '{"chartId": "new_chart"}',
          isError: false,
          data: chart,
        );
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act
        await session.transform('Create a chart');

        // Assert
        final createEvents = events.whereType<ChartCreatedEvent>().toList();
        expect(createEvents, isNotEmpty);
        expect(createEvents.first.config.id, equals('new_chart'));
      });

      test('emits ChartUpdatedEvent when existing chart is modified', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final existingChart = createTestChart(id: 'existing_chart');
        final updatedChart = createTestChart(
          id: 'existing_chart',
          title: 'Updated Title',
        );

        final createTool = MockAgentTool(name: 'create_chart');
        createTool.nextResult = ToolResult(
          output: '{"chartId": "existing_chart"}',
          data: existingChart,
        );

        final modifyTool = MockAgentTool(name: 'modify_chart');
        modifyTool.nextResult = ToolResult(
          output: '{"chartId": "existing_chart"}',
          data: updatedChart,
        );

        // First call returns create, then text response, then modify, then text response
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'line'},
          ),
          createTextResponse('Chart created'),
          createToolUseResponse(
            toolName: 'modify_chart',
            input: {'chartId': 'existing_chart', 'title': 'Updated Title'},
          ),
          createTextResponse('Chart modified'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [createTool, modifyTool],
          systemPrompt: 'System prompt',
        );

        // Create initial chart
        await session.transform('Create a chart');

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act - modify the chart
        await session.transform('Change the title');

        // Assert
        final updateEvents = events.whereType<ChartUpdatedEvent>().toList();
        expect(updateEvents, isNotEmpty);
      });

      test('does not update activeChart when tool returns error', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final mockTool = MockAgentTool(name: 'create_chart');
        mockTool.nextResult = const ToolResult(
          output: 'Error: Invalid chart type',
          isError: true,
        );
        mockProvider.responseQueue.addAll([
          createToolUseResponse(
            toolName: 'create_chart',
            input: {'type': 'invalid'},
          ),
          createTextResponse('Error handled'),
        ]);

        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: [mockTool],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.transform('Create an invalid chart');

        // Assert - activeChart should remain null
        expect(session.state.value.activeChart, isNull);
      });
    });

    // ============================================================
    // updateChart Tests
    // ============================================================
    group('updateChart', () {
      test('updates state.activeChart to newConfig', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        final newChart = createTestChart(id: 'updated_chart', title: 'Updated');

        // Act
        session.updateChart(newChart);

        // Assert
        expect(session.state.value.activeChart, isNotNull);
        expect(session.state.value.activeChart!.id, equals('updated_chart'));
        expect(session.state.value.activeChart!.title, equals('Updated'));
      });

      test('emits ChartUpdatedEvent with newConfig', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        final newChart = createTestChart(id: 'updated_chart');

        final events = <AgentEvent>[];
        final subscription = session.events.listen(events.add);

        // Act
        session.updateChart(newChart);

        // Give time for events to propagate
        await Future<void>.delayed(Duration.zero);

        // Clean up
        await subscription.cancel();

        // Assert
        final updateEvents = events.whereType<ChartUpdatedEvent>().toList();
        expect(updateEvents.length, equals(1));
        expect(updateEvents.first.config.id, equals('updated_chart'));
      });

      test('replaces existing activeChart', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        final firstChart = createTestChart(id: 'chart_1', title: 'First');
        final secondChart = createTestChart(id: 'chart_1', title: 'Second');

        // Act
        session.updateChart(firstChart);
        session.updateChart(secondChart);

        // Assert
        expect(session.state.value.activeChart!.title, equals('Second'));
      });

      test('notifies state listeners', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        var notificationCount = 0;
        session.state.addListener(() {
          notificationCount++;
        });

        // Act
        session.updateChart(createTestChart());

        // Assert
        expect(notificationCount, greaterThan(0));
      });
    });

    // ============================================================
    // Cancel Tests
    // ============================================================
    group('cancel', () {
      test('sets status to idle when cancelled', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Start a transform that we'll cancel
        // (This is tricky to test without async control, but we can
        // at least verify cancel() works when called)

        // Act
        await session.cancel();

        // Assert
        expect(session.state.value.status, equals(ActivityStatus.idle));
      });

      test('emits CancelledEvent when cancelled', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        final events = <AgentEvent>[];
        session.events.listen(events.add);

        // Act
        await session.cancel();

        // Assert
        final cancelEvents = events.whereType<CancelledEvent>().toList();
        expect(cancelEvents, isNotEmpty);
      });

      test('clears activeTool when cancelled', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.cancel();

        // Assert
        expect(session.state.value.activeTool, isNull);
      });

      test('is idempotent - calling cancel twice does not throw', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert - should not throw
        await session.cancel();
        await session.cancel();
      });

      test('has no effect when no operation in progress', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act
        await session.cancel();

        // Assert - should remain idle
        expect(session.state.value.status, equals(ActivityStatus.idle));
      });
    });

    // ============================================================
    // Dispose Tests
    // ============================================================
    group('dispose', () {
      test('closes the events StreamController', () async {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        var streamClosed = false;
        session.events.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        // Act
        session.dispose();

        // Wait for stream to close
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamClosed, isTrue);
      });

      test('is idempotent - calling dispose twice does not throw', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Act & Assert - should not throw
        session.dispose();
        // Second dispose should be safe
        expect(() => session.dispose(), returnsNormally);
      });

      test('state ValueNotifier is disposed', () {
        // Arrange
        final mockProvider = MockLLMProvider();
        final session = AgentSessionImpl(
          llmProvider: mockProvider,
          tools: const [],
          systemPrompt: 'System prompt',
        );

        // Get the state before dispose
        final stateNotifier = session.state;

        // Act
        session.dispose();

        // Assert - adding listener after dispose should throw or be no-op
        // Note: ValueNotifier throws when used after dispose
        expect(
          () => stateNotifier.addListener(() {}),
          throwsA(anything),
        );
      });
    });
  });
}
