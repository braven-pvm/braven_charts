import 'package:braven_agent/src/llm/llm.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:braven_agent/src/tools/tool_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock tool for testing tool conversion.
class MockTool implements AgentTool {
  @override
  String get name => 'test_tool';

  @override
  String get description => 'A test tool for unit testing.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'param1': {'type': 'string', 'description': 'First parameter'},
          'param2': {'type': 'integer', 'description': 'Second parameter'},
        },
        'required': ['param1'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    return ToolResult(
      output: 'Executed with ${input['param1']}',
      data: input,
    );
  }
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
        expect((message.content.first as TextContent).text,
            equals('Hello, Claude!'));
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
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;

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
        expect((restored.content.first as TextContent).text,
            equals('Test message'));
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
  });
}
