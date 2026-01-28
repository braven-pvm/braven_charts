import 'package:braven_agent/src/llm/llm_config.dart';
import 'package:braven_agent/src/llm/llm_provider.dart';
import 'package:braven_agent/src/llm/llm_registry.dart';
import 'package:braven_agent/src/llm/llm_response.dart';
import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

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
    for (final chunk in mockChunks) {
      yield chunk;
    }
    // Always yield a final complete chunk if no chunks provided
    if (mockChunks.isEmpty) {
      yield const LLMChunk(isComplete: true, stopReason: 'end_turn');
    }
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
}
