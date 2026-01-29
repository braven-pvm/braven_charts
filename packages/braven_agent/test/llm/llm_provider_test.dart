import 'package:braven_agent/src/llm/llm_config.dart';
import 'package:braven_agent/src/llm/llm_provider.dart';
import 'package:braven_agent/src/llm/llm_registry.dart';
import 'package:braven_agent/src/llm/llm_response.dart';
import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:braven_agent/src/tools/tool_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock implementation of [AgentTool] for testing.
class MockAgentTool implements AgentTool {
  @override
  final String name;

  @override
  final String description;

  @override
  final Map<String, dynamic> inputSchema;

  /// Result to return from [execute].
  ToolResult? mockResult;

  /// Number of times [execute] was called.
  int executeCallCount = 0;

  /// Last input passed to [execute].
  Map<String, dynamic>? lastInput;

  MockAgentTool({
    this.name = 'mock_tool',
    this.description = 'A mock tool for testing',
    this.inputSchema = const {
      'type': 'object',
      'properties': {
        'param': {'type': 'string'},
      },
    },
  });

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    executeCallCount++;
    lastInput = input;
    return mockResult ?? const ToolResult(output: 'mock result');
  }
}

/// Mock implementation of [LLMProvider] for testing.
///
/// Returns predefined responses and tracks method calls.
class MockLLMProvider implements LLMProvider {
  final String _id;
  final LLMConfig config;

  /// Number of times [generateResponse] was called.
  int generateResponseCallCount = 0;

  /// Number of times [streamResponse] was called.
  int streamResponseCallCount = 0;

  /// The response to return from [generateResponse].
  LLMResponse? mockResponse;

  /// The chunks to yield from [streamResponse].
  List<LLMChunk> mockChunks = [];

  /// Last system prompt passed to [generateResponse].
  String? lastGenerateSystemPrompt;

  /// Last history passed to [generateResponse].
  List<AgentMessage>? lastGenerateHistory;

  /// Last tools passed to [generateResponse].
  List<AgentTool>? lastGenerateTools;

  /// Last config passed to [generateResponse].
  LLMConfig? lastGenerateConfig;

  /// Last system prompt passed to [streamResponse].
  String? lastStreamSystemPrompt;

  /// Last history passed to [streamResponse].
  List<AgentMessage>? lastStreamHistory;

  /// Last tools passed to [streamResponse].
  List<AgentTool>? lastStreamTools;

  /// Last config passed to [streamResponse].
  LLMConfig? lastStreamConfig;

  MockLLMProvider({
    String id = 'mock',
    required this.config,
  }) : _id = id;

  @override
  String get id => _id;

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    generateResponseCallCount++;
    lastGenerateSystemPrompt = systemPrompt;
    lastGenerateHistory = history;
    lastGenerateTools = tools;
    lastGenerateConfig = config;
    if (mockResponse != null) {
      return mockResponse!;
    }
    // Return a minimal valid response
    return LLMResponse(
      message: AgentMessage(
        id: 'msg_mock',
        role: MessageRole.assistant,
        content: [],
        timestamp: DateTime.now(),
      ),
      inputTokens: 10,
      outputTokens: 5,
      stopReason: 'end_turn',
    );
  }

  @override
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async* {
    streamResponseCallCount++;
    lastStreamSystemPrompt = systemPrompt;
    lastStreamHistory = history;
    lastStreamTools = tools;
    lastStreamConfig = config;
    for (final chunk in mockChunks) {
      yield chunk;
    }
    // Always yield a final complete chunk if no chunks provided
    if (mockChunks.isEmpty) {
      yield const LLMChunk(isComplete: true, stopReason: 'end_turn');
    }
  }
}

/// Mock LLM provider that throws exceptions for error testing.
class ThrowingLLMProvider implements LLMProvider {
  @override
  final String id = 'throwing';

  /// Object to throw from [generateResponse].
  /// Can be Exception, Error, or any Object.
  Object? generateException;

  /// Object to throw from [streamResponse].
  /// Can be Exception, Error, or any Object.
  Object? streamException;

  ThrowingLLMProvider({
    this.generateException,
    this.streamException,
  });

  @override
  Future<LLMResponse> generateResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async {
    if (generateException != null) {
      throw generateException!;
    }
    return LLMResponse(
      message: AgentMessage(
        id: 'msg_throwing',
        role: MessageRole.assistant,
        content: [],
        timestamp: DateTime.now(),
      ),
      inputTokens: 0,
      outputTokens: 0,
    );
  }

  @override
  Stream<LLMChunk> streamResponse({
    required String systemPrompt,
    required List<AgentMessage> history,
    List<AgentTool>? tools,
    LLMConfig? config,
  }) async* {
    if (streamException != null) {
      throw streamException!;
    }
    yield const LLMChunk(isComplete: true);
  }
}

void main() {
  group('LLMProvider', () {
    late LLMConfig config;

    setUp(() {
      config = const LLMConfig(apiKey: 'test-api-key');
    });

    test('MockLLMProvider implements LLMProvider interface', () {
      final provider = MockLLMProvider(config: config);

      expect(provider, isA<LLMProvider>());
      expect(provider.id, equals('mock'));
    });

    test('MockLLMProvider can have custom id', () {
      final provider = MockLLMProvider(id: 'custom', config: config);

      expect(provider.id, equals('custom'));
    });

    test('generateResponse returns LLMResponse', () async {
      final provider = MockLLMProvider(config: config);

      final response = await provider.generateResponse(
        systemPrompt: 'You are a helpful assistant.',
        history: [],
      );

      expect(response, isA<LLMResponse>());
      expect(response.message.role, equals(MessageRole.assistant));
      expect(provider.generateResponseCallCount, equals(1));
    });

    test('generateResponse accepts optional tools parameter', () async {
      final provider = MockLLMProvider(config: config);

      final response = await provider.generateResponse(
        systemPrompt: 'You are a helpful assistant.',
        history: [],
        tools: [], // Empty tools list
      );

      expect(response, isA<LLMResponse>());
      expect(provider.generateResponseCallCount, equals(1));
    });

    test('generateResponse accepts optional config parameter', () async {
      final provider = MockLLMProvider(config: config);
      const overrideConfig = LLMConfig(
        apiKey: 'override-key',
        temperature: 0.5,
      );

      final response = await provider.generateResponse(
        systemPrompt: 'You are a helpful assistant.',
        history: [],
        config: overrideConfig,
      );

      expect(response, isA<LLMResponse>());
    });

    test('streamResponse yields LLMChunk objects', () async {
      final provider = MockLLMProvider(config: config);
      provider.mockChunks = [
        const LLMChunk(textDelta: 'Hello'),
        const LLMChunk(textDelta: ' World'),
        const LLMChunk(isComplete: true, stopReason: 'end_turn'),
      ];

      final chunks = await provider.streamResponse(
        systemPrompt: 'You are a helpful assistant.',
        history: [],
      ).toList();

      expect(chunks, hasLength(3));
      expect(chunks[0].textDelta, equals('Hello'));
      expect(chunks[1].textDelta, equals(' World'));
      expect(chunks[2].isComplete, isTrue);
      expect(provider.streamResponseCallCount, equals(1));
    });

    test('streamResponse yields default complete chunk when no mocks',
        () async {
      final provider = MockLLMProvider(config: config);

      final chunks = await provider.streamResponse(
        systemPrompt: 'Test',
        history: [],
      ).toList();

      expect(chunks, hasLength(1));
      expect(chunks[0].isComplete, isTrue);
    });
  });

  group('LLMRegistry', () {
    late LLMConfig config;

    setUp(() {
      LLMRegistry.clearRegistrations();
      config = const LLMConfig(apiKey: 'test-api-key');
    });

    tearDown(() {
      LLMRegistry.clearRegistrations();
    });

    test('register adds factory to registry', () {
      expect(LLMRegistry.isRegistered('test'), isFalse);

      LLMRegistry.register('test', (c) => MockLLMProvider(config: c));

      expect(LLMRegistry.isRegistered('test'), isTrue);
    });

    test('create returns provider from registered factory', () {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));

      final provider = LLMRegistry.create('mock', config);

      expect(provider, isA<MockLLMProvider>());
      expect(provider.id, equals('mock'));
    });

    test('create passes config to factory', () {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));
      const customConfig = LLMConfig(
        apiKey: 'custom-key',
        model: 'custom-model',
        temperature: 0.9,
      );

      final provider =
          LLMRegistry.create('mock', customConfig) as MockLLMProvider;

      expect(provider.config.apiKey, equals('custom-key'));
      expect(provider.config.model, equals('custom-model'));
      expect(provider.config.temperature, equals(0.9));
    });

    test('create throws StateError for unregistered provider', () {
      expect(
        () => LLMRegistry.create('unknown', config),
        throwsA(
          allOf(
            isA<StateError>(),
            predicate<StateError>(
              (e) =>
                  e.message
                      .contains("No LLM provider registered for 'unknown'") &&
                  e.message.contains(
                      'Did you forget to call LLMRegistry.register()?'),
            ),
          ),
        ),
      );
    });

    test('clearRegistrations removes all factories', () {
      LLMRegistry.register(
          'provider1', (c) => MockLLMProvider(id: 'p1', config: c));
      LLMRegistry.register(
          'provider2', (c) => MockLLMProvider(id: 'p2', config: c));
      expect(LLMRegistry.registeredProviders, hasLength(2));

      LLMRegistry.clearRegistrations();

      expect(LLMRegistry.registeredProviders, isEmpty);
      expect(LLMRegistry.isRegistered('provider1'), isFalse);
      expect(LLMRegistry.isRegistered('provider2'), isFalse);
    });

    test('register overwrites existing factory', () {
      LLMRegistry.register(
          'mock', (c) => MockLLMProvider(id: 'first', config: c));
      LLMRegistry.register(
          'mock', (c) => MockLLMProvider(id: 'second', config: c));

      final provider = LLMRegistry.create('mock', config);

      expect(provider.id, equals('second'));
    });

    test('registeredProviders returns all registered IDs', () {
      LLMRegistry.register(
          'anthropic', (c) => MockLLMProvider(id: 'anthropic', config: c));
      LLMRegistry.register(
          'openai', (c) => MockLLMProvider(id: 'openai', config: c));
      LLMRegistry.register(
          'gemini', (c) => MockLLMProvider(id: 'gemini', config: c));

      final providers = LLMRegistry.registeredProviders;

      expect(providers, containsAll(['anthropic', 'openai', 'gemini']));
      expect(providers, hasLength(3));
    });

    test('isRegistered returns false for unregistered provider', () {
      expect(LLMRegistry.isRegistered('nonexistent'), isFalse);
    });

    test('isRegistered returns true after registration', () {
      LLMRegistry.register('test', (c) => MockLLMProvider(config: c));

      expect(LLMRegistry.isRegistered('test'), isTrue);
    });

    test('multiple providers can be registered and used', () {
      LLMRegistry.register(
          'provider_a', (c) => MockLLMProvider(id: 'a', config: c));
      LLMRegistry.register(
          'provider_b', (c) => MockLLMProvider(id: 'b', config: c));

      final providerA = LLMRegistry.create('provider_a', config);
      final providerB = LLMRegistry.create('provider_b', config);

      expect(providerA.id, equals('a'));
      expect(providerB.id, equals('b'));
    });
  });

  group('LLMProvider - Realistic Data', () {
    late LLMConfig config;

    setUp(() {
      config = const LLMConfig(apiKey: 'test-api-key');
    });

    test('generateResponse with non-empty conversation history', () async {
      final provider = MockLLMProvider(config: config);
      final history = [
        AgentMessage(
          id: 'msg_1',
          role: MessageRole.user,
          content: [const TextContent(text: 'Create a line chart')],
          timestamp: DateTime.now(),
        ),
        AgentMessage(
          id: 'msg_2',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'I will create a line chart.')],
          timestamp: DateTime.now(),
        ),
        AgentMessage(
          id: 'msg_3',
          role: MessageRole.user,
          content: [const TextContent(text: 'Add a title')],
          timestamp: DateTime.now(),
        ),
      ];

      await provider.generateResponse(
        systemPrompt: 'You are a chart assistant.',
        history: history,
      );

      expect(provider.generateResponseCallCount, equals(1));
      expect(provider.lastGenerateHistory, hasLength(3));
      expect(provider.lastGenerateHistory![0].role, equals(MessageRole.user));
      expect(
          provider.lastGenerateHistory![1].role, equals(MessageRole.assistant));
      expect(provider.lastGenerateHistory![2].role, equals(MessageRole.user));
    });

    test('generateResponse with actual AgentTool objects', () async {
      final provider = MockLLMProvider(config: config);
      final tools = [
        MockAgentTool(
          name: 'create_chart',
          description: 'Creates a new chart',
          inputSchema: {
            'type': 'object',
            'properties': {
              'chartType': {
                'type': 'string',
                'enum': ['line', 'bar']
              },
            },
            'required': ['chartType'],
          },
        ),
        MockAgentTool(
          name: 'modify_chart',
          description: 'Modifies an existing chart',
          inputSchema: {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
            },
          },
        ),
      ];

      await provider.generateResponse(
        systemPrompt: 'You are a chart assistant.',
        history: [],
        tools: tools,
      );

      expect(provider.generateResponseCallCount, equals(1));
      expect(provider.lastGenerateTools, isNotNull);
      expect(provider.lastGenerateTools, hasLength(2));
      expect(provider.lastGenerateTools![0].name, equals('create_chart'));
      expect(provider.lastGenerateTools![1].name, equals('modify_chart'));
    });

    test('generateResponse tracks all parameters including history and tools',
        () async {
      final provider = MockLLMProvider(config: config);
      final history = [
        AgentMessage(
          id: 'msg_user',
          role: MessageRole.user,
          content: [const TextContent(text: 'Hello')],
          timestamp: DateTime.now(),
        ),
      ];
      final tools = [
        MockAgentTool(name: 'test_tool', description: 'Test tool'),
      ];
      const overrideConfig = LLMConfig(apiKey: 'override', temperature: 0.7);

      await provider.generateResponse(
        systemPrompt: 'Test system prompt',
        history: history,
        tools: tools,
        config: overrideConfig,
      );

      expect(provider.lastGenerateSystemPrompt, equals('Test system prompt'));
      expect(provider.lastGenerateHistory, equals(history));
      expect(provider.lastGenerateTools, equals(tools));
      expect(provider.lastGenerateConfig, equals(overrideConfig));
    });
  });

  group('LLMProvider - streamResponse Parameter Coverage', () {
    late LLMConfig config;

    setUp(() {
      config = const LLMConfig(apiKey: 'test-api-key');
    });

    test('streamResponse with tools parameter', () async {
      final provider = MockLLMProvider(config: config);
      provider.mockChunks = [
        const LLMChunk(textDelta: 'Using tool...'),
        const LLMChunk(isComplete: true, stopReason: 'tool_use'),
      ];
      final tools = [
        MockAgentTool(name: 'stream_tool', description: 'A streaming tool'),
      ];

      final chunks = await provider
          .streamResponse(
            systemPrompt: 'You are a helpful assistant.',
            history: [],
            tools: tools,
          )
          .toList();

      expect(provider.streamResponseCallCount, equals(1));
      expect(provider.lastStreamTools, isNotNull);
      expect(provider.lastStreamTools, hasLength(1));
      expect(provider.lastStreamTools![0].name, equals('stream_tool'));
      expect(chunks, hasLength(2));
    });

    test('streamResponse with config override', () async {
      final provider = MockLLMProvider(config: config);
      const overrideConfig = LLMConfig(
        apiKey: 'stream-override-key',
        model: 'stream-model',
        temperature: 0.3,
      );

      await provider
          .streamResponse(
            systemPrompt: 'Test prompt',
            history: [],
            config: overrideConfig,
          )
          .toList();

      expect(provider.streamResponseCallCount, equals(1));
      expect(provider.lastStreamConfig, isNotNull);
      expect(provider.lastStreamConfig!.apiKey, equals('stream-override-key'));
      expect(provider.lastStreamConfig!.model, equals('stream-model'));
      expect(provider.lastStreamConfig!.temperature, equals(0.3));
    });

    test('streamResponse with conversation history', () async {
      final provider = MockLLMProvider(config: config);
      final history = [
        AgentMessage(
          id: 'stream_msg_1',
          role: MessageRole.user,
          content: [const TextContent(text: 'Stream request')],
          timestamp: DateTime.now(),
        ),
        AgentMessage(
          id: 'stream_msg_2',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'Streaming response')],
          timestamp: DateTime.now(),
        ),
      ];

      await provider
          .streamResponse(
            systemPrompt: 'Stream test',
            history: history,
          )
          .toList();

      expect(provider.streamResponseCallCount, equals(1));
      expect(provider.lastStreamHistory, hasLength(2));
      expect(provider.lastStreamHistory![0].id, equals('stream_msg_1'));
      expect(provider.lastStreamHistory![1].id, equals('stream_msg_2'));
    });

    test('streamResponse with all parameters', () async {
      final provider = MockLLMProvider(config: config);
      final history = [
        AgentMessage(
          id: 'full_msg',
          role: MessageRole.user,
          content: [const TextContent(text: 'Full test')],
          timestamp: DateTime.now(),
        ),
      ];
      final tools = [MockAgentTool(name: 'full_tool')];
      const overrideConfig = LLMConfig(apiKey: 'full-key', temperature: 0.9);

      await provider
          .streamResponse(
            systemPrompt: 'Full prompt',
            history: history,
            tools: tools,
            config: overrideConfig,
          )
          .toList();

      expect(provider.lastStreamSystemPrompt, equals('Full prompt'));
      expect(provider.lastStreamHistory, equals(history));
      expect(provider.lastStreamTools, equals(tools));
      expect(provider.lastStreamConfig, equals(overrideConfig));
    });
  });

  group('LLMChunk - Tool Use Content', () {
    late LLMConfig config;

    setUp(() {
      config = const LLMConfig(apiKey: 'test-api-key');
    });

    test('streamResponse yields chunks with tool use content', () async {
      final provider = MockLLMProvider(config: config);
      const toolUseContent = ToolUseContent(
        id: 'toolu_123',
        toolName: 'create_chart',
        input: {'chartType': 'line', 'title': 'Sales'},
      );
      provider.mockChunks = [
        const LLMChunk(textDelta: 'I will create a chart.'),
        const LLMChunk(toolUse: toolUseContent, isComplete: false),
        const LLMChunk(isComplete: true, stopReason: 'tool_use'),
      ];

      final chunks = await provider
          .streamResponse(systemPrompt: 'Test', history: []).toList();

      expect(chunks, hasLength(3));
      expect(chunks[0].textDelta, equals('I will create a chart.'));
      expect(chunks[0].toolUse, isNull);

      expect(chunks[1].toolUse, isNotNull);
      expect(chunks[1].toolUse!.id, equals('toolu_123'));
      expect(chunks[1].toolUse!.toolName, equals('create_chart'));
      expect(chunks[1].toolUse!.input['chartType'], equals('line'));
      expect(chunks[1].toolUse!.input['title'], equals('Sales'));

      expect(chunks[2].isComplete, isTrue);
      expect(chunks[2].stopReason, equals('tool_use'));
    });

    test('LLMChunk with tool use has correct properties', () {
      const toolUseContent = ToolUseContent(
        id: 'toolu_456',
        toolName: 'modify_chart',
        input: {'color': 'blue'},
      );
      const chunk = LLMChunk(toolUse: toolUseContent);

      expect(chunk.toolUse, isNotNull);
      expect(chunk.toolUse!.id, equals('toolu_456'));
      expect(chunk.toolUse!.toolName, equals('modify_chart'));
      expect(chunk.toolUse!.input, {'color': 'blue'});
      expect(chunk.textDelta, isNull);
      expect(chunk.isComplete, isFalse);
    });

    test('LLMChunk with multiple tool uses in sequence', () async {
      final provider = MockLLMProvider(config: config);
      provider.mockChunks = [
        const LLMChunk(
          toolUse: ToolUseContent(
            id: 'toolu_first',
            toolName: 'tool_a',
            input: {'param': 'a'},
          ),
        ),
        const LLMChunk(
          toolUse: ToolUseContent(
            id: 'toolu_second',
            toolName: 'tool_b',
            input: {'param': 'b'},
          ),
        ),
        const LLMChunk(isComplete: true, stopReason: 'tool_use'),
      ];

      final chunks = await provider
          .streamResponse(systemPrompt: 'Test', history: []).toList();

      expect(chunks, hasLength(3));
      expect(chunks[0].toolUse!.id, equals('toolu_first'));
      expect(chunks[0].toolUse!.toolName, equals('tool_a'));
      expect(chunks[1].toolUse!.id, equals('toolu_second'));
      expect(chunks[1].toolUse!.toolName, equals('tool_b'));
    });

    test('LLMChunk copyWith preserves tool use', () {
      const originalToolUse = ToolUseContent(
        id: 'toolu_copy',
        toolName: 'copy_tool',
        input: {'key': 'value'},
      );
      const originalChunk = LLMChunk(toolUse: originalToolUse);
      final copiedChunk = originalChunk.copyWith(isComplete: true);

      expect(copiedChunk.toolUse, equals(originalToolUse));
      expect(copiedChunk.isComplete, isTrue);
    });

    test('LLMChunk JSON serialization with tool use', () {
      const toolUse = ToolUseContent(
        id: 'toolu_json',
        toolName: 'json_tool',
        input: {
          'nested': {'key': 'value'}
        },
      );
      const chunk = LLMChunk(toolUse: toolUse, isComplete: false);
      final json = chunk.toJson();
      final restored = LLMChunk.fromJson(json);

      expect(restored.toolUse, isNotNull);
      expect(restored.toolUse!.id, equals('toolu_json'));
      expect(restored.toolUse!.toolName, equals('json_tool'));
      expect(restored.toolUse!.input['nested'], {'key': 'value'});
    });
  });

  group('LLMProvider - Error Propagation', () {
    test('generateResponse propagates exceptions', () async {
      final provider = ThrowingLLMProvider(
        generateException: Exception('Network error'),
      );

      expect(
        () => provider.generateResponse(
          systemPrompt: 'Test',
          history: [],
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          ),
        ),
      );
    });

    test('streamResponse propagates exceptions', () async {
      final provider = ThrowingLLMProvider(
        streamException: Exception('Stream error'),
      );

      expect(
        () => provider.streamResponse(
          systemPrompt: 'Test',
          history: [],
        ).toList(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Stream error'),
          ),
        ),
      );
    });

    test('error propagation does not affect other provider instances',
        () async {
      final throwingProvider = ThrowingLLMProvider(
        generateException: Exception('Provider 1 error'),
      );
      final normalProvider = ThrowingLLMProvider();

      // First provider throws
      expect(
        () => throwingProvider.generateResponse(
          systemPrompt: 'Test',
          history: [],
        ),
        throwsA(isA<Exception>()),
      );

      // Second provider works normally
      final response = await normalProvider.generateResponse(
        systemPrompt: 'Test',
        history: [],
      );
      expect(response, isA<LLMResponse>());
    });

    test('provider can be configured to throw different exception types',
        () async {
      final formatProvider = ThrowingLLMProvider(
        generateException: const FormatException('Invalid format'),
      );
      final stateProvider = ThrowingLLMProvider(
        generateException: StateError('Invalid state'),
      );

      expect(
        () => formatProvider.generateResponse(
          systemPrompt: 'Test',
          history: [],
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => stateProvider.generateResponse(
          systemPrompt: 'Test',
          history: [],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('LLMProvider - Instance Independence', () {
    late LLMConfig config;

    setUp(() {
      LLMRegistry.clearRegistrations();
      config = const LLMConfig(apiKey: 'test-api-key');
    });

    tearDown(() {
      LLMRegistry.clearRegistrations();
    });

    test('multiple instances from same factory are independent', () async {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));

      final provider1 = LLMRegistry.create('mock', config) as MockLLMProvider;
      final provider2 = LLMRegistry.create('mock', config) as MockLLMProvider;

      // Modify state on provider1
      provider1.mockResponse = LLMResponse(
        message: AgentMessage(
          id: 'custom_response',
          role: MessageRole.assistant,
          content: [const TextContent(text: 'Custom')],
          timestamp: DateTime.now(),
        ),
        inputTokens: 100,
        outputTokens: 50,
      );

      // Call generateResponse on provider1
      await provider1.generateResponse(
        systemPrompt: 'Test',
        history: [],
      );

      // Verify provider2 is not affected
      expect(provider2.mockResponse, isNull);
      expect(provider2.generateResponseCallCount, equals(0));
    });

    test('call count is tracked independently per instance', () async {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));

      final provider1 = LLMRegistry.create('mock', config) as MockLLMProvider;
      final provider2 = LLMRegistry.create('mock', config) as MockLLMProvider;

      // Call provider1 three times
      await provider1.generateResponse(systemPrompt: 'Test', history: []);
      await provider1.generateResponse(systemPrompt: 'Test', history: []);
      await provider1.generateResponse(systemPrompt: 'Test', history: []);

      // Call provider2 once
      await provider2.generateResponse(systemPrompt: 'Test', history: []);

      expect(provider1.generateResponseCallCount, equals(3));
      expect(provider2.generateResponseCallCount, equals(1));
    });

    test('mock chunks are independent per instance', () async {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));

      final provider1 = LLMRegistry.create('mock', config) as MockLLMProvider;
      final provider2 = LLMRegistry.create('mock', config) as MockLLMProvider;

      provider1.mockChunks = [
        const LLMChunk(textDelta: 'Provider 1 response'),
        const LLMChunk(isComplete: true),
      ];

      provider2.mockChunks = [
        const LLMChunk(textDelta: 'Provider 2 response'),
        const LLMChunk(isComplete: true),
      ];

      final chunks1 = await provider1
          .streamResponse(systemPrompt: 'Test', history: []).toList();
      final chunks2 = await provider2
          .streamResponse(systemPrompt: 'Test', history: []).toList();

      expect(chunks1[0].textDelta, equals('Provider 1 response'));
      expect(chunks2[0].textDelta, equals('Provider 2 response'));
    });

    test('different configs create truly independent providers', () async {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));

      const config1 = LLMConfig(apiKey: 'key-1', temperature: 0.5);
      const config2 = LLMConfig(apiKey: 'key-2', temperature: 0.9);

      final provider1 = LLMRegistry.create('mock', config1) as MockLLMProvider;
      final provider2 = LLMRegistry.create('mock', config2) as MockLLMProvider;

      expect(provider1.config.apiKey, equals('key-1'));
      expect(provider1.config.temperature, equals(0.5));
      expect(provider2.config.apiKey, equals('key-2'));
      expect(provider2.config.temperature, equals(0.9));
    });

    test('last parameters tracked independently per instance', () async {
      LLMRegistry.register('mock', (c) => MockLLMProvider(config: c));

      final provider1 = LLMRegistry.create('mock', config) as MockLLMProvider;
      final provider2 = LLMRegistry.create('mock', config) as MockLLMProvider;

      await provider1.generateResponse(
        systemPrompt: 'System 1',
        history: [
          AgentMessage(
            id: 'msg1',
            role: MessageRole.user,
            content: [const TextContent(text: 'Message 1')],
            timestamp: DateTime.now(),
          ),
        ],
      );

      await provider2.generateResponse(
        systemPrompt: 'System 2',
        history: [
          AgentMessage(
            id: 'msg2',
            role: MessageRole.user,
            content: [const TextContent(text: 'Message 2')],
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(provider1.lastGenerateSystemPrompt, equals('System 1'));
      expect(provider1.lastGenerateHistory![0].id, equals('msg1'));
      expect(provider2.lastGenerateSystemPrompt, equals('System 2'));
      expect(provider2.lastGenerateHistory![0].id, equals('msg2'));
    });
  });
}
