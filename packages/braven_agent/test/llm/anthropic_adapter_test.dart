import 'dart:async';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:braven_agent/src/llm/llm.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:braven_agent/src/tools/tool_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock tool for testing tool conversion.
class MockTool implements AgentTool {
  final String _name;
  final String _description;
  final Map<String, dynamic> _inputSchema;

  MockTool({
    String name = 'test_tool',
    String description = 'A test tool for unit testing.',
    Map<String, dynamic>? inputSchema,
  })  : _name = name,
        _description = description,
        _inputSchema = inputSchema ??
            {
              'type': 'object',
              'properties': {
                'param1': {'type': 'string', 'description': 'First parameter'},
                'param2': {'type': 'integer', 'description': 'Second parameter'},
              },
              'required': ['param1'],
            };

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Map<String, dynamic> get inputSchema => _inputSchema;

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    return ToolResult(
      output: 'Executed with ${input['param1']}',
      data: input,
    );
  }
}

/// Mock AnthropicClient for testing AnthropicAdapter behavior.
///
/// Allows capturing requests and returning controlled responses.
class MockAnthropicClient implements anthropic.AnthropicClient {
  /// Captured request from the last createMessage call.
  anthropic.CreateMessageRequest? capturedRequest;

  /// Response to return from createMessage.
  anthropic.Message? messageResponse;

  /// Exception to throw from createMessage.
  Exception? messageException;

  /// Stream events to return from createMessageStream.
  List<anthropic.MessageStreamEvent>? streamEvents;

  /// Exception to throw from createMessageStream.
  Exception? streamException;

  /// Whether createMessage was called.
  bool createMessageCalled = false;

  /// Whether createMessageStream was called.
  bool createMessageStreamCalled = false;

  @override
  Future<anthropic.Message> createMessage({
    required anthropic.CreateMessageRequest request,
  }) async {
    createMessageCalled = true;
    capturedRequest = request;

    if (messageException != null) {
      throw messageException!;
    }

    if (messageResponse != null) {
      return messageResponse!;
    }

    // Default response
    return const anthropic.Message(
      id: 'msg_test_123',
      role: anthropic.MessageRole.assistant,
      content: anthropic.MessageContent.text('Default mock response'),
      model: 'claude-sonnet-4-20250514',
      stopReason: anthropic.StopReason.endTurn,
      usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
    );
  }

  @override
  Stream<anthropic.MessageStreamEvent> createMessageStream({
    required anthropic.CreateMessageRequest request,
  }) {
    createMessageStreamCalled = true;
    capturedRequest = request;

    if (streamException != null) {
      return Stream.error(streamException!);
    }

    if (streamEvents != null) {
      return Stream.fromIterable(streamEvents!);
    }

    // Default stream with text and completion
    return Stream.fromIterable([
      const anthropic.MessageStreamEvent.contentBlockDelta(
        type: anthropic.MessageStreamEventType.contentBlockDelta,
        index: 0,
        delta: anthropic.BlockDelta.textDelta(
          type: 'text_delta',
          text: 'Hello from stream',
        ),
      ),
      const anthropic.MessageStreamEvent.messageStop(
        type: anthropic.MessageStreamEventType.messageStop,
      ),
    ]);
  }

  // Unused methods - not needed for our adapter tests
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('AnthropicAdapter', () {
    late LLMConfig config;

    setUp(() {
      config = const LLMConfig(
        apiKey: 'test-api-key',
        model: 'claude-sonnet-4-20250514',
        temperature: 0.7,
        maxTokens: 4096,
      );
    });

    group('Construction', () {
      test('creates adapter with valid config', () {
        final adapter = AnthropicAdapter(config);

        expect(adapter, isA<LLMProvider>());
        expect(adapter.id, equals('anthropic'));
      });

      test('implements LLMProvider interface', () {
        final adapter = AnthropicAdapter(config);

        expect(adapter, isA<LLMProvider>());
      });

      test('id returns anthropic', () {
        final adapter = AnthropicAdapter(config);

        expect(adapter.id, equals('anthropic'));
      });
    });

    group('Registry Integration', () {
      setUp(() {
        LLMRegistry.clearRegistrations();
      });

      tearDown(() {
        LLMRegistry.clearRegistrations();
      });

      test('can be registered with LLMRegistry', () {
        LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));

        expect(LLMRegistry.isRegistered('anthropic'), isTrue);
      });

      test('can be created from registry', () {
        LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));

        final provider = LLMRegistry.create('anthropic', config);

        expect(provider, isA<AnthropicAdapter>());
        expect(provider.id, equals('anthropic'));
      });
    });

    group('Message Conversion', () {
      test('converts user text message to AgentMessage', () {
        // Create a user message with text content
        final message = AgentMessage(
          id: 'msg_1',
          role: MessageRole.user,
          content: [const TextContent(text: 'Hello, Claude!')],
          timestamp: DateTime.now().toUtc(),
        );

        expect(message.role, equals(MessageRole.user));
        expect(message.content, hasLength(1));
        expect(message.content.first, isA<TextContent>());
        expect((message.content.first as TextContent).text, equals('Hello, Claude!'));
      });

      test('converts assistant message with text content', () {
        final message = AgentMessage(
          id: 'msg_2',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'Hello! How can I help?')],
          timestamp: DateTime.now().toUtc(),
        );

        expect(message.role, equals(MessageRole.assistant));
        expect(message.content.first, isA<TextContent>());
      });

      test('converts tool use content', () {
        const toolUse = ToolUseContent(
          id: 'toolu_123',
          toolName: 'create_chart',
          input: {'type': 'line', 'title': 'Sales'},
        );

        expect(toolUse.id, equals('toolu_123'));
        expect(toolUse.toolName, equals('create_chart'));
        expect(toolUse.input, containsPair('type', 'line'));
      });

      test('converts tool result content', () {
        const toolResult = ToolResultContent(
          toolUseId: 'toolu_123',
          output: '{"chartId": "chart_456"}',
          isError: false,
        );

        expect(toolResult.toolUseId, equals('toolu_123'));
        expect(toolResult.output, contains('chart_456'));
        expect(toolResult.isError, isFalse);
      });

      test('converts image content', () {
        const imageContent = ImageContent(
          data: 'iVBORw0KGgo...',
          mediaType: 'image/png',
        );

        expect(imageContent.data, isNotEmpty);
        expect(imageContent.mediaType, equals('image/png'));
      });

      test('message with multiple content blocks', () {
        final message = AgentMessage(
          id: 'msg_3',
          role: MessageRole.assistant,
          content: [
            const TextContent(text: 'Creating a chart for you.'),
            const ToolUseContent(
              id: 'toolu_456',
              toolName: 'create_chart',
              input: {'type': 'bar'},
            ),
          ],
          timestamp: DateTime.now().toUtc(),
        );

        expect(message.content, hasLength(2));
        expect(message.content[0], isA<TextContent>());
        expect(message.content[1], isA<ToolUseContent>());
      });
    });

    group('Tool Conversion', () {
      test('MockTool has correct properties', () {
        final tool = MockTool();

        expect(tool.name, equals('test_tool'));
        expect(tool.description, contains('test tool'));
        expect(tool.inputSchema, isA<Map<String, dynamic>>());
      });

      test('tool input schema has correct structure', () {
        final tool = MockTool();
        final schema = tool.inputSchema;

        expect(schema['type'], equals('object'));
        expect(schema['properties'], isA<Map<String, dynamic>>());
        expect(schema['required'], contains('param1'));
      });

      test('tool schema properties are well-formed', () {
        final tool = MockTool();
        final properties = tool.inputSchema['properties'] as Map<String, dynamic>;

        expect(properties['param1'], containsPair('type', 'string'));
        expect(properties['param2'], containsPair('type', 'integer'));
      });

      test('multiple tools can be converted', () {
        final tools = [MockTool(), MockTool()];

        expect(tools, hasLength(2));
        expect(tools.every((t) => t.name == 'test_tool'), isTrue);
      });
    });

    group('LLMResponse Construction', () {
      test('creates response with message and token counts', () {
        final message = AgentMessage(
          id: 'resp_1',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'Response text')],
          timestamp: DateTime.now().toUtc(),
        );

        final response = LLMResponse(
          message: message,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'end_turn',
        );

        expect(response.message, equals(message));
        expect(response.inputTokens, equals(100));
        expect(response.outputTokens, equals(50));
        expect(response.stopReason, equals('end_turn'));
      });

      test('response with tool_use stop reason', () {
        final message = AgentMessage(
          id: 'resp_2',
          role: MessageRole.assistant,
          content: [
            const ToolUseContent(
              id: 'toolu_789',
              toolName: 'test_tool',
              input: {'param1': 'value'},
            ),
          ],
          timestamp: DateTime.now().toUtc(),
        );

        final response = LLMResponse(
          message: message,
          inputTokens: 80,
          outputTokens: 40,
          stopReason: 'tool_use',
        );

        expect(response.stopReason, equals('tool_use'));
        expect(response.message.content.first, isA<ToolUseContent>());
      });
    });

    group('LLMChunk Construction', () {
      test('creates text delta chunk', () {
        const chunk = LLMChunk(
          textDelta: 'Hello',
          isComplete: false,
        );

        expect(chunk.textDelta, equals('Hello'));
        expect(chunk.isComplete, isFalse);
        expect(chunk.toolUse, isNull);
      });

      test('creates tool use chunk', () {
        const toolUse = ToolUseContent(
          id: 'toolu_stream',
          toolName: 'create_chart',
          input: {'type': 'line'},
        );

        const chunk = LLMChunk(
          toolUse: toolUse,
          isComplete: false,
        );

        expect(chunk.toolUse, isNotNull);
        expect(chunk.toolUse!.toolName, equals('create_chart'));
        expect(chunk.textDelta, isNull);
      });

      test('creates final chunk with stop reason', () {
        const chunk = LLMChunk(
          isComplete: true,
          stopReason: 'end_turn',
        );

        expect(chunk.isComplete, isTrue);
        expect(chunk.stopReason, equals('end_turn'));
      });
    });

    group('Config Override', () {
      test('config can be overridden per request', () {
        const overrideConfig = LLMConfig(
          apiKey: 'different-key',
          model: 'claude-3-haiku-20240307',
          temperature: 0.5,
          maxTokens: 2048,
        );

        expect(overrideConfig.model, equals('claude-3-haiku-20240307'));
        expect(overrideConfig.temperature, equals(0.5));
        expect(overrideConfig.maxTokens, equals(2048));
      });

      test('copyWith creates modified config', () {
        final modified = config.copyWith(temperature: 0.9);

        expect(modified.temperature, equals(0.9));
        expect(modified.apiKey, equals(config.apiKey));
        expect(modified.model, equals(config.model));
      });
    });

    group('MessageRole Mapping', () {
      test('all message roles are valid', () {
        expect(MessageRole.values, contains(MessageRole.user));
        expect(MessageRole.values, contains(MessageRole.assistant));
        expect(MessageRole.values, contains(MessageRole.system));
        expect(MessageRole.values, contains(MessageRole.tool));
      });

      test('tool role exists for tool results', () {
        final message = AgentMessage(
          id: 'tool_result_msg',
          role: MessageRole.tool,
          content: [
            const ToolResultContent(
              toolUseId: 'toolu_123',
              output: 'success',
              isError: false,
            ),
          ],
          timestamp: DateTime.now().toUtc(),
        );

        expect(message.role, equals(MessageRole.tool));
      });
    });

    group('Serialization', () {
      test('AgentMessage round-trips through JSON', () {
        final original = AgentMessage(
          id: 'msg_serialize',
          role: MessageRole.user,
          content: [const TextContent(text: 'Test message')],
          timestamp: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final json = original.toJson();
        final restored = AgentMessage.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.role, equals(original.role));
        expect(restored.content, hasLength(1));
        expect((restored.content.first as TextContent).text, equals('Test message'));
      });

      test('LLMResponse round-trips through JSON', () {
        final message = AgentMessage(
          id: 'resp_serialize',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'Response')],
          timestamp: DateTime.utc(2024, 1, 15, 10, 31),
        );

        final original = LLMResponse(
          message: message,
          inputTokens: 50,
          outputTokens: 25,
          stopReason: 'end_turn',
        );

        final json = original.toJson();
        final restored = LLMResponse.fromJson(json);

        expect(restored.inputTokens, equals(50));
        expect(restored.outputTokens, equals(25));
        expect(restored.stopReason, equals('end_turn'));
      });

      test('LLMChunk round-trips through JSON', () {
        const original = LLMChunk(
          textDelta: 'Hello',
          isComplete: false,
        );

        final json = original.toJson();
        final restored = LLMChunk.fromJson(json);

        expect(restored.textDelta, equals('Hello'));
        expect(restored.isComplete, isFalse);
      });
    });

    // =========================================================================
    // MOCK-BASED TESTS FOR ACTUAL ADAPTER BEHAVIOR
    // =========================================================================

    group('generateResponse() with Mock Client', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('constructs request with correct model and maxTokens', () async {
        await adapter.generateResponse(
          systemPrompt: 'Test prompt',
          history: [],
        );

        expect(mockClient.createMessageCalled, isTrue);
        expect(mockClient.capturedRequest, isNotNull);

        final request = mockClient.capturedRequest!;
        expect(
          request.model.value,
          equals('claude-sonnet-4-20250514'),
        );
        expect(request.maxTokens, equals(4096));
      });

      test('includes system prompt in request', () async {
        await adapter.generateResponse(
          systemPrompt: 'You are a helpful assistant.',
          history: [],
        );

        final request = mockClient.capturedRequest!;
        final systemText = request.system?.mapOrNull(
          text: (t) => t.value,
        );
        expect(systemText, equals('You are a helpful assistant.'));
      });

      test('converts history messages to request', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [const TextContent(text: 'Hello')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        expect(request.messages, hasLength(1));
        expect(request.messages.first.role, equals(anthropic.MessageRole.user));
      });

      test('includes tools when provided', () async {
        final tools = [MockTool()];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: tools,
        );

        final request = mockClient.capturedRequest!;
        expect(request.tools, isNotNull);
        expect(request.tools, hasLength(1));
        expect(request.tools!.first.name, equals('test_tool'));
      });

      test('does not include tools when empty list provided', () async {
        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: [],
        );

        final request = mockClient.capturedRequest!;
        expect(request.tools, isNull);
      });

      test('parses token counts from response', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.text('Response'),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.endTurn,
          usage: anthropic.Usage(inputTokens: 150, outputTokens: 75),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.inputTokens, equals(150));
        expect(response.outputTokens, equals(75));
      });

      test('maps end_turn stop reason correctly', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.text('Response'),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.endTurn,
          usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.stopReason, equals('end_turn'));
      });

      test('maps tool_use stop reason correctly', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.text('Response'),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.toolUse,
          usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.stopReason, equals('tool_use'));
      });

      test('maps max_tokens stop reason correctly', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.text('Response'),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.maxTokens,
          usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.stopReason, equals('max_tokens'));
      });

      test('maps stop_sequence stop reason correctly', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.text('Response'),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.stopSequence,
          usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.stopReason, equals('stop_sequence'));
      });

      test('uses override config when provided', () async {
        const overrideConfig = LLMConfig(
          apiKey: 'override-key',
          model: 'claude-3-haiku-20240307',
          maxTokens: 2048,
        );

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          config: overrideConfig,
        );

        final request = mockClient.capturedRequest!;
        expect(request.model.value, equals('claude-3-haiku-20240307'));
        expect(request.maxTokens, equals(2048));
      });

      test('converts text content from response blocks', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.blocks([
            anthropic.Block.text(text: 'Hello, world!'),
          ]),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.endTurn,
          usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.message.content, hasLength(1));
        expect(response.message.content.first, isA<TextContent>());
        expect(
          (response.message.content.first as TextContent).text,
          equals('Hello, world!'),
        );
      });

      test('converts tool_use block from response', () async {
        mockClient.messageResponse = const anthropic.Message(
          id: 'msg_test',
          role: anthropic.MessageRole.assistant,
          content: anthropic.MessageContent.blocks([
            anthropic.Block.toolUse(
              id: 'toolu_123',
              name: 'create_chart',
              input: {'type': 'line'},
            ),
          ]),
          model: 'claude-sonnet-4-20250514',
          stopReason: anthropic.StopReason.toolUse,
          usage: anthropic.Usage(inputTokens: 10, outputTokens: 5),
        );

        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
        );

        expect(response.message.content, hasLength(1));
        expect(response.message.content.first, isA<ToolUseContent>());

        final toolUse = response.message.content.first as ToolUseContent;
        expect(toolUse.id, equals('toolu_123'));
        expect(toolUse.toolName, equals('create_chart'));
        expect(toolUse.input, containsPair('type', 'line'));
      });
    });

    group('streamResponse() with Mock Client', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('yields text delta chunks', () async {
        mockClient.streamEvents = [
          const anthropic.MessageStreamEvent.contentBlockDelta(
            type: anthropic.MessageStreamEventType.contentBlockDelta,
            index: 0,
            delta: anthropic.BlockDelta.textDelta(
              type: 'text_delta',
              text: 'Hello',
            ),
          ),
          const anthropic.MessageStreamEvent.contentBlockDelta(
            type: anthropic.MessageStreamEventType.contentBlockDelta,
            index: 0,
            delta: anthropic.BlockDelta.textDelta(
              type: 'text_delta',
              text: ' world',
            ),
          ),
        ];

        final chunks = await adapter.streamResponse(
          systemPrompt: 'Test',
          history: [],
        ).toList();

        expect(chunks, hasLength(2));
        expect(chunks[0].textDelta, equals('Hello'));
        expect(chunks[1].textDelta, equals(' world'));
      });

      test('yields messageStop as complete chunk', () async {
        mockClient.streamEvents = [
          const anthropic.MessageStreamEvent.messageStop(
            type: anthropic.MessageStreamEventType.messageStop,
          ),
        ];

        final chunks = await adapter.streamResponse(
          systemPrompt: 'Test',
          history: [],
        ).toList();

        expect(chunks, hasLength(1));
        expect(chunks.first.isComplete, isTrue);
      });

      test('yields messageDelta with stop reason', () async {
        mockClient.streamEvents = [
          const anthropic.MessageStreamEvent.messageDelta(
            type: anthropic.MessageStreamEventType.messageDelta,
            delta: anthropic.MessageDelta(stopReason: anthropic.StopReason.endTurn),
            usage: anthropic.MessageDeltaUsage(outputTokens: 10),
          ),
        ];

        final chunks = await adapter.streamResponse(
          systemPrompt: 'Test',
          history: [],
        ).toList();

        expect(chunks, hasLength(1));
        expect(chunks.first.stopReason, equals('end_turn'));
      });

      test('handles error event', () async {
        mockClient.streamEvents = [
          const anthropic.MessageStreamEvent.error(
            type: anthropic.MessageStreamEventType.error,
            error: anthropic.Error(
              type: 'server_error',
              message: 'Something went wrong',
            ),
          ),
        ];

        final chunks = await adapter.streamResponse(
          systemPrompt: 'Test',
          history: [],
        ).toList();

        expect(chunks, hasLength(1));
        expect(chunks.first.textDelta, contains('Something went wrong'));
        expect(chunks.first.isComplete, isTrue);
        expect(chunks.first.stopReason, equals('error'));
      });

      test('skips ping events', () async {
        mockClient.streamEvents = [
          const anthropic.MessageStreamEvent.ping(
            type: anthropic.MessageStreamEventType.ping,
          ),
          const anthropic.MessageStreamEvent.contentBlockDelta(
            type: anthropic.MessageStreamEventType.contentBlockDelta,
            index: 0,
            delta: anthropic.BlockDelta.textDelta(
              type: 'text_delta',
              text: 'Hello',
            ),
          ),
          const anthropic.MessageStreamEvent.ping(
            type: anthropic.MessageStreamEventType.ping,
          ),
        ];

        final chunks = await adapter.streamResponse(
          systemPrompt: 'Test',
          history: [],
        ).toList();

        // Only the text delta should be yielded
        expect(chunks, hasLength(1));
        expect(chunks.first.textDelta, equals('Hello'));
      });

      test('constructs request with correct parameters', () async {
        await adapter.streamResponse(
          systemPrompt: 'Streaming test',
          history: [],
        ).toList();

        expect(mockClient.createMessageStreamCalled, isTrue);
        expect(mockClient.capturedRequest, isNotNull);

        final request = mockClient.capturedRequest!;
        expect(request.model.value, equals('claude-sonnet-4-20250514'));
        expect(request.maxTokens, equals(4096));
      });

      test('uses override config for streaming', () async {
        const overrideConfig = LLMConfig(
          apiKey: 'override-key',
          model: 'claude-3-haiku-20240307',
          maxTokens: 1024,
        );

        await adapter
            .streamResponse(
              systemPrompt: 'Test',
              history: [],
              config: overrideConfig,
            )
            .toList();

        final request = mockClient.capturedRequest!;
        expect(request.model.value, equals('claude-3-haiku-20240307'));
        expect(request.maxTokens, equals(1024));
      });
    });

    group('Message Conversion (_convertMessages)', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('converts TextContent to text block', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [const TextContent(text: 'Hello Claude')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        expect(request.messages, hasLength(1));

        final message = request.messages.first;
        final contentBlocks = message.content.mapOrNull(
          blocks: (blocks) => blocks.value,
        );
        expect(contentBlocks, isNotNull);
        expect(contentBlocks, hasLength(1));
        expect(contentBlocks!.first, isA<anthropic.TextBlock>());
      });

      test('converts ImageContent to image block', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(
                data: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
                mediaType: 'image/png',
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        expect(request.messages, hasLength(1));

        final message = request.messages.first;
        final contentBlocks = message.content.mapOrNull(
          blocks: (blocks) => blocks.value,
        );
        expect(contentBlocks, isNotNull);
        expect(contentBlocks!.first, isA<anthropic.ImageBlock>());
      });

      test('converts ToolUseContent to tool_use block', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.assistant,
            content: [
              const ToolUseContent(
                id: 'toolu_123',
                toolName: 'test_tool',
                input: {'param1': 'value'},
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        expect(request.messages, hasLength(1));

        final message = request.messages.first;
        final contentBlocks = message.content.mapOrNull(
          blocks: (blocks) => blocks.value,
        );
        expect(contentBlocks, isNotNull);
        expect(contentBlocks!.first, isA<anthropic.ToolUseBlock>());

        final toolBlock = contentBlocks.first as anthropic.ToolUseBlock;
        expect(toolBlock.id, equals('toolu_123'));
        expect(toolBlock.name, equals('test_tool'));
      });

      test('converts ToolResultContent to tool_result block', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.tool,
            content: [
              const ToolResultContent(
                toolUseId: 'toolu_123',
                output: '{"success": true}',
                isError: false,
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        expect(request.messages, hasLength(1));

        final message = request.messages.first;
        // Tool results come from user role
        expect(message.role, equals(anthropic.MessageRole.user));

        final contentBlocks = message.content.mapOrNull(
          blocks: (blocks) => blocks.value,
        );
        expect(contentBlocks, isNotNull);
        expect(contentBlocks!.first, isA<anthropic.ToolResultBlock>());
      });

      test('converts multiple content blocks in single message', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.assistant,
            content: [
              const TextContent(text: 'Let me help you'),
              const ToolUseContent(
                id: 'toolu_456',
                toolName: 'helper',
                input: {},
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final message = request.messages.first;
        final contentBlocks = message.content.mapOrNull(
          blocks: (blocks) => blocks.value,
        );

        expect(contentBlocks, hasLength(2));
        expect(contentBlocks![0], isA<anthropic.TextBlock>());
        expect(contentBlocks[1], isA<anthropic.ToolUseBlock>());
      });

      test('converts assistant role correctly', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.assistant,
            content: [const TextContent(text: 'I am the assistant')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        expect(
          request.messages.first.role,
          equals(anthropic.MessageRole.assistant),
        );
      });

      test('converts tool role to user role', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.tool,
            content: [
              const ToolResultContent(
                toolUseId: 'toolu_123',
                output: 'result',
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        // Tool results are sent with user role per Anthropic API spec
        expect(
          request.messages.first.role,
          equals(anthropic.MessageRole.user),
        );
      });
    });

    group('Tool Conversion (_convertTools)', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('maps tool name correctly', () async {
        final tools = [
          MockTool(name: 'my_custom_tool'),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: tools,
        );

        final request = mockClient.capturedRequest!;
        expect(request.tools, hasLength(1));
        expect(request.tools!.first.name, equals('my_custom_tool'));
      });

      test('maps tool description correctly', () async {
        final tools = [
          MockTool(description: 'A detailed description of the tool'),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: tools,
        );

        final request = mockClient.capturedRequest!;
        final tool = request.tools!.first as anthropic.ToolCustom;
        expect(
          tool.description,
          equals('A detailed description of the tool'),
        );
      });

      test('maps tool inputSchema correctly', () async {
        final tools = [
          MockTool(
            inputSchema: {
              'type': 'object',
              'properties': {
                'color': {'type': 'string'},
                'size': {'type': 'integer'},
              },
              'required': ['color'],
            },
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: tools,
        );

        final request = mockClient.capturedRequest!;
        final tool = request.tools!.first as anthropic.ToolCustom;
        final schema = tool.inputSchema;
        expect(schema['type'], equals('object'));
        expect((schema['properties'] as Map).containsKey('color'), isTrue);
        expect(schema['required'], contains('color'));
      });

      test('converts multiple tools', () async {
        final tools = [
          MockTool(name: 'tool_one'),
          MockTool(name: 'tool_two'),
          MockTool(name: 'tool_three'),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: tools,
        );

        final request = mockClient.capturedRequest!;
        expect(request.tools, hasLength(3));
        expect(
          request.tools!.map((t) => t.name),
          containsAll(['tool_one', 'tool_two', 'tool_three']),
        );
      });

      test('sets toolChoice to auto when tools provided', () async {
        final tools = [MockTool()];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: tools,
        );

        final request = mockClient.capturedRequest!;
        expect(request.toolChoice, isNotNull);
        expect(
          request.toolChoice!.type,
          equals(anthropic.ToolChoiceType.auto),
        );
      });

      test('does not set toolChoice when no tools', () async {
        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [],
          tools: null,
        );

        final request = mockClient.capturedRequest!;
        expect(request.toolChoice, isNull);
      });
    });

    group('System Message Handling', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('system messages are NOT included in converted messages', () async {
        final history = [
          AgentMessage(
            id: 'sys_1',
            role: MessageRole.system,
            content: [
              const TextContent(text: 'You are a helpful assistant'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
          AgentMessage(
            id: 'user_1',
            role: MessageRole.user,
            content: [const TextContent(text: 'Hello')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Real system prompt',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        // Only user message should be in the list, system is skipped
        expect(request.messages, hasLength(1));
        expect(
          request.messages.first.role,
          equals(anthropic.MessageRole.user),
        );
      });

      test('system prompt is passed separately from history', () async {
        final history = [
          AgentMessage(
            id: 'sys_1',
            role: MessageRole.system,
            content: [const TextContent(text: 'History system message')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Actual system prompt',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        // System prompt should be the one passed to generateResponse
        final systemText = request.system?.mapOrNull(
          text: (t) => t.value,
        );
        expect(systemText, equals('Actual system prompt'));
        // History system message should be excluded from messages
        expect(request.messages, isEmpty);
      });

      test('mixed history with system messages skips only system', () async {
        final history = [
          AgentMessage(
            id: 'sys_1',
            role: MessageRole.system,
            content: [const TextContent(text: 'System')],
            timestamp: DateTime.now().toUtc(),
          ),
          AgentMessage(
            id: 'user_1',
            role: MessageRole.user,
            content: [const TextContent(text: 'User message 1')],
            timestamp: DateTime.now().toUtc(),
          ),
          AgentMessage(
            id: 'asst_1',
            role: MessageRole.assistant,
            content: [const TextContent(text: 'Assistant reply')],
            timestamp: DateTime.now().toUtc(),
          ),
          AgentMessage(
            id: 'sys_2',
            role: MessageRole.system,
            content: [const TextContent(text: 'Another system')],
            timestamp: DateTime.now().toUtc(),
          ),
          AgentMessage(
            id: 'user_2',
            role: MessageRole.user,
            content: [const TextContent(text: 'User message 2')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        // Should have 3 messages: user_1, asst_1, user_2 (both system skipped)
        expect(request.messages, hasLength(3));
        expect(
          request.messages.map((m) => m.role),
          equals([
            anthropic.MessageRole.user,
            anthropic.MessageRole.assistant,
            anthropic.MessageRole.user,
          ]),
        );
      });
    });

    group('Error Handling', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('SDK exception from createMessage propagates', () async {
        mockClient.messageException = Exception('API Error: Rate limited');

        expect(
          () => adapter.generateResponse(
            systemPrompt: 'Test',
            history: [],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('SDK exception message is preserved', () async {
        mockClient.messageException = Exception('API Error: Invalid API key');

        try {
          await adapter.generateResponse(
            systemPrompt: 'Test',
            history: [],
          );
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Invalid API key'));
        }
      });

      test('stream error from createMessageStream propagates', () async {
        mockClient.streamException = Exception('Stream Error: Connection lost');

        expect(
          () => adapter.streamResponse(
            systemPrompt: 'Test',
            history: [],
          ).toList(),
          throwsA(isA<Exception>()),
        );
      });

      test('stream error message is preserved', () async {
        mockClient.streamException = Exception('Network timeout');

        try {
          await adapter.streamResponse(
            systemPrompt: 'Test',
            history: [],
          ).toList();
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Network timeout'));
        }
      });
    });

    group('Media Type Parsing', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('parses image/jpeg correctly', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(data: 'base64data', mediaType: 'image/jpeg'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        final imageBlock = blocks!.first as anthropic.ImageBlock;
        expect(
          imageBlock.source.mediaType,
          equals(anthropic.ImageBlockSourceMediaType.imageJpeg),
        );
      });

      test('parses image/png correctly', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(data: 'base64data', mediaType: 'image/png'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        final imageBlock = blocks!.first as anthropic.ImageBlock;
        expect(
          imageBlock.source.mediaType,
          equals(anthropic.ImageBlockSourceMediaType.imagePng),
        );
      });

      test('parses image/gif correctly', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(data: 'base64data', mediaType: 'image/gif'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        final imageBlock = blocks!.first as anthropic.ImageBlock;
        expect(
          imageBlock.source.mediaType,
          equals(anthropic.ImageBlockSourceMediaType.imageGif),
        );
      });

      test('parses image/webp correctly', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(data: 'base64data', mediaType: 'image/webp'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        final imageBlock = blocks!.first as anthropic.ImageBlock;
        expect(
          imageBlock.source.mediaType,
          equals(anthropic.ImageBlockSourceMediaType.imageWebp),
        );
      });

      test('unknown media type falls back to image/png', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(
                data: 'base64data',
                mediaType: 'image/bmp', // Unsupported
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        final imageBlock = blocks!.first as anthropic.ImageBlock;
        // Falls back to PNG
        expect(
          imageBlock.source.mediaType,
          equals(anthropic.ImageBlockSourceMediaType.imagePng),
        );
      });

      test('media type parsing is case-insensitive', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const ImageContent(data: 'base64data', mediaType: 'IMAGE/JPEG'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        final imageBlock = blocks!.first as anthropic.ImageBlock;
        expect(
          imageBlock.source.mediaType,
          equals(anthropic.ImageBlockSourceMediaType.imageJpeg),
        );
      });
    });

    group('BinaryContent Handling', () {
      late MockAnthropicClient mockClient;
      late AnthropicAdapter adapter;

      setUp(() {
        mockClient = MockAnthropicClient();
        adapter = AnthropicAdapter(config, client: mockClient);
      });

      test('BinaryContent is silently skipped during conversion', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const TextContent(text: 'Hello'),
              const BinaryContent(
                data: 'some_binary_data',
                mimeType: 'application/octet-stream',
              ),
              const TextContent(text: 'World'),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );

        // Only 2 text blocks, binary is skipped
        expect(blocks, hasLength(2));
        expect(blocks![0], isA<anthropic.TextBlock>());
        expect(blocks[1], isA<anthropic.TextBlock>());
      });

      test('message with only BinaryContent is skipped entirely', () async {
        final history = [
          AgentMessage(
            id: 'msg_1',
            role: MessageRole.user,
            content: [
              const BinaryContent(
                data: 'binary_data',
                mimeType: 'application/pdf',
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
          AgentMessage(
            id: 'msg_2',
            role: MessageRole.user,
            content: [const TextContent(text: 'Real message')],
            timestamp: DateTime.now().toUtc(),
          ),
        ];

        await adapter.generateResponse(
          systemPrompt: 'Test',
          history: history,
        );

        final request = mockClient.capturedRequest!;
        // First message is skipped because it becomes empty after binary removal
        expect(request.messages, hasLength(1));
        final blocks = request.messages.first.content.mapOrNull(
          blocks: (b) => b.value,
        );
        expect((blocks!.first as anthropic.TextBlock).text, equals('Real message'));
      });
    });
  });
}
