import 'dart:async';
import 'dart:convert';

import 'package:braven_agent/src/llm/llm.dart';
import 'package:braven_agent/src/tools/agent_tool.dart';
import 'package:braven_agent/src/tools/tool_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Mock HTTP client that supports streaming responses.
class StreamingMockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;

  StreamingMockClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _handler(request);
}

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
                'param2': {
                  'type': 'integer',
                  'description': 'Second parameter',
                },
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

void main() {
  group('GrokAdapter', () {
    late LLMConfig config;

    setUp(() {
      config = const LLMConfig(
        apiKey: 'test-api-key',
        model: 'grok-3',
        temperature: 0.7,
        maxTokens: 4096,
      );
    });

    group('constructor', () {
      test('creates adapter with config', () {
        final adapter = GrokAdapter(config);
        expect(adapter.id, equals('grok'));
      });

      test('accepts custom HTTP client for testing', () {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Test response',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        expect(adapter.id, equals('grok'));
      });
    });

    group('id', () {
      test('returns grok', () {
        final adapter = GrokAdapter(config);
        expect(adapter.id, equals('grok'));
      });
    });

    group('generateResponse', () {
      test('sends correct request format', () async {
        Map<String, dynamic>? capturedBody;
        Map<String, String>? capturedHeaders;

        final mockClient = MockClient((request) async {
          capturedHeaders = request.headers;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Hello!',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'You are a helpful assistant.',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        // Verify headers
        expect(capturedHeaders?['Content-Type'], equals('application/json'));
        expect(capturedHeaders?['Authorization'], equals('Bearer test-api-key'));

        // Verify body structure
        expect(capturedBody?['model'], equals('grok-3'));
        expect(capturedBody?['temperature'], equals(0.7));
        expect(capturedBody?['max_tokens'], equals(4096));
        expect(capturedBody?['stream'], equals(false));

        // Verify messages
        final messages = capturedBody?['messages'] as List<dynamic>;
        expect(messages.length, equals(2)); // system + user
        expect(messages[0]['role'], equals('system'));
        expect(messages[0]['content'], equals('You are a helpful assistant.'));
        expect(messages[1]['role'], equals('user'));
        expect(messages[1]['content'], equals('Hello'));
      });

      test('parses text response correctly', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Here is your response.',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 15,
                'completion_tokens': 8,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final response = await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'User message')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        expect(response.message.role, equals(MessageRole.assistant));
        expect(response.message.content.length, equals(1));
        expect(response.message.content.first, isA<TextContent>());
        expect((response.message.content.first as TextContent).text, equals('Here is your response.'));
        expect(response.inputTokens, equals(15));
        expect(response.outputTokens, equals(8));
        expect(response.stopReason, equals('end_turn'));
      });

      test('parses tool call response correctly', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': null,
                    'tool_calls': [
                      {
                        'id': 'call_123',
                        'type': 'function',
                        'function': {
                          'name': 'create_chart',
                          'arguments': '{"type":"line","data":[1,2,3]}',
                        },
                      }
                    ],
                  },
                  'finish_reason': 'tool_calls',
                }
              ],
              'usage': {
                'prompt_tokens': 20,
                'completion_tokens': 15,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final response = await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Create a chart')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
          tools: [MockTool(name: 'create_chart')],
        );

        expect(response.message.content.length, equals(1));
        expect(response.message.content.first, isA<ToolUseContent>());

        final toolUse = response.message.content.first as ToolUseContent;
        expect(toolUse.id, equals('call_123'));
        expect(toolUse.toolName, equals('create_chart'));
        expect(
            toolUse.input,
            equals({
              'type': 'line',
              'data': [1, 2, 3]
            }));
        expect(response.stopReason, equals('tool_use'));
      });

      test('converts tools to correct format', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OK',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
          tools: [MockTool()],
        );

        final tools = capturedBody?['tools'] as List<dynamic>;
        expect(tools.length, equals(1));

        final tool = tools.first as Map<String, dynamic>;
        expect(tool['type'], equals('function'));
        expect(tool['function']['name'], equals('test_tool'));
        expect(tool['function']['description'], equals('A test tool for unit testing.'));
        expect(capturedBody?['tool_choice'], equals('auto'));
      });

      test('handles assistant message with tool calls in history', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Done',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Create chart')],
              timestamp: DateTime.now().toUtc(),
            ),
            AgentMessage(
              id: 'msg-2',
              role: MessageRole.assistant,
              content: [
                const ToolUseContent(
                  id: 'call_abc',
                  toolName: 'create_chart',
                  input: {'type': 'bar'},
                ),
              ],
              timestamp: DateTime.now().toUtc(),
            ),
            AgentMessage(
              id: 'msg-3',
              role: MessageRole.tool,
              content: [
                const ToolResultContent(
                  toolUseId: 'call_abc',
                  output: '{"success": true}',
                ),
              ],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        final messages = capturedBody?['messages'] as List<dynamic>;
        // system + user + assistant + tool = 4
        expect(messages.length, equals(4));

        // Verify assistant message with tool calls
        final assistantMsg = messages[2] as Map<String, dynamic>;
        expect(assistantMsg['role'], equals('assistant'));
        expect(assistantMsg['tool_calls'], isNotNull);

        final toolCalls = assistantMsg['tool_calls'] as List<dynamic>;
        expect(toolCalls.length, equals(1));
        expect(toolCalls[0]['id'], equals('call_abc'));
        expect(toolCalls[0]['function']['name'], equals('create_chart'));

        // Verify tool result message
        final toolMsg = messages[3] as Map<String, dynamic>;
        expect(toolMsg['role'], equals('tool'));
        expect(toolMsg['tool_call_id'], equals('call_abc'));
        expect(toolMsg['content'], equals('{"success": true}'));
      });

      test('handles image content in user messages', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'I see the image',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 100,
                'completion_tokens': 10,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [
                const TextContent(text: 'What is in this image?'),
                const ImageContent(data: 'base64data', mediaType: 'image/png'),
              ],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        final messages = capturedBody?['messages'] as List<dynamic>;
        final userMsg = messages[1] as Map<String, dynamic>;
        final content = userMsg['content'] as List<dynamic>;

        expect(content.length, equals(2));
        expect(content[0]['type'], equals('text'));
        expect(content[0]['text'], equals('What is in this image?'));
        expect(content[1]['type'], equals('image_url'));
        expect(content[1]['image_url']['url'], equals('data:image/png;base64,base64data'));
      });

      test('handles provider options', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OK',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        const configWithOptions = LLMConfig(
          apiKey: 'test-key',
          model: 'grok-3',
          providerOptions: {
            'top_p': 0.9,
            'frequency_penalty': 0.5,
            'presence_penalty': 0.3,
          },
        );

        final adapter = GrokAdapter(configWithOptions, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        expect(capturedBody?['top_p'], equals(0.9));
        expect(capturedBody?['frequency_penalty'], equals(0.5));
        expect(capturedBody?['presence_penalty'], equals(0.3));
      });

      test('throws on 401 unauthorized error', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'message': 'Invalid API key',
                'type': 'invalid_request_error',
              },
            }),
            401,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);

        expect(
          () => adapter.generateResponse(
            systemPrompt: 'System prompt',
            history: [
              AgentMessage(
                id: 'msg-1',
                role: MessageRole.user,
                content: [const TextContent(text: 'Hello')],
                timestamp: DateTime.now().toUtc(),
              ),
            ],
          ),
          throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid API key'))),
        );
      });

      test('throws on API error with message', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'message': 'Rate limit exceeded',
                'type': 'rate_limit_error',
              },
            }),
            429,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);

        expect(
          () => adapter.generateResponse(
            systemPrompt: 'System prompt',
            history: [
              AgentMessage(
                id: 'msg-1',
                role: MessageRole.user,
                content: [const TextContent(text: 'Hello')],
                timestamp: DateTime.now().toUtc(),
              ),
            ],
          ),
          throwsA(predicate((e) => e is Exception && e.toString().contains('Rate limit exceeded'))),
        );
      });

      test('uses custom base URL when provided', () async {
        String? capturedUrl;

        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OK',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        const customConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://custom.api.com/v1',
          model: 'grok-3',
        );

        final adapter = GrokAdapter(customConfig, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        expect(capturedUrl, equals('https://custom.api.com/v1/chat/completions'));
      });

      test('uses default model when config has Anthropic default', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OK',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        // Use default model (which is Anthropic's default)
        const defaultConfig = LLMConfig(apiKey: 'test-key');

        final adapter = GrokAdapter(defaultConfig, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        // Should use Grok's default model instead of Anthropic's
        expect(capturedBody?['model'], equals('grok-3'));
      });
    });

    group('streamResponse', () {
      test('yields text chunks correctly', () async {
        final streamController = StreamController<List<int>>();
        final mockClient = StreamingMockClient((request) async {
          // Schedule adding data after returning
          Future.microtask(() async {
            streamController.add(utf8.encode('data: {"choices":[{"delta":{"content":"Hello"},"finish_reason":null}]}\n\n'));
            streamController.add(utf8.encode('data: {"choices":[{"delta":{"content":" world"},"finish_reason":null}]}\n\n'));
            streamController.add(utf8.encode('data: {"choices":[{"delta":{},"finish_reason":"stop"}]}\n\n'));
            streamController.add(utf8.encode('data: [DONE]\n\n'));
            await streamController.close();
          });
          return http.StreamedResponse(streamController.stream, 200);
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final chunks = await adapter.streamResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        ).toList();

        // Should have text chunks and completion chunk
        expect(chunks.length, greaterThanOrEqualTo(2));

        final textChunks = chunks.where((c) => c.textDelta != null).toList();
        expect(textChunks.length, equals(2));
        expect(textChunks[0].textDelta, equals('Hello'));
        expect(textChunks[1].textDelta, equals(' world'));

        final completeChunk = chunks.last;
        expect(completeChunk.isComplete, isTrue);
      });

      test('yields tool use chunks correctly', () async {
        final streamController = StreamController<List<int>>();
        final mockClient = StreamingMockClient((request) async {
          // Schedule adding data after returning
          Future.microtask(() async {
            // Tool call start
            streamController.add(utf8.encode(
              'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_123","type":"function","function":{"name":"create_chart","arguments":""}}]},"finish_reason":null}]}\n\n',
            ));
            // Tool call arguments
            streamController.add(utf8.encode(
              'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\\"type\\":"}}]},"finish_reason":null}]}\n\n',
            ));
            streamController.add(utf8.encode(
              'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"\\"line\\"}"}}]},"finish_reason":null}]}\n\n',
            ));
            // Finish
            streamController.add(utf8.encode(
              'data: {"choices":[{"delta":{},"finish_reason":"tool_calls"}]}\n\n',
            ));
            streamController.add(utf8.encode('data: [DONE]\n\n'));
            await streamController.close();
          });
          return http.StreamedResponse(streamController.stream, 200);
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final chunks = await adapter.streamResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Create a chart')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
          tools: [MockTool(name: 'create_chart')],
        ).toList();

        // Find tool use chunk
        final toolChunks = chunks.where((c) => c.toolUse != null).toList();
        expect(toolChunks.length, equals(1));

        final toolUse = toolChunks.first.toolUse!;
        expect(toolUse.id, equals('call_123'));
        expect(toolUse.toolName, equals('create_chart'));
        expect(toolUse.input, equals({'type': 'line'}));
      });

      test('handles stream error response', () async {
        final streamController = StreamController<List<int>>();
        final mockClient = StreamingMockClient((request) async {
          Future.microtask(() async {
            streamController.add(utf8.encode(jsonEncode({
              'error': {'message': 'Stream error'},
            })));
            await streamController.close();
          });
          return http.StreamedResponse(streamController.stream, 500);
        });

        final adapter = GrokAdapter(config, client: mockClient);

        expect(
          () => adapter.streamResponse(
            systemPrompt: 'System prompt',
            history: [
              AgentMessage(
                id: 'msg-1',
                role: MessageRole.user,
                content: [const TextContent(text: 'Hello')],
                timestamp: DateTime.now().toUtc(),
              ),
            ],
          ).toList(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('message conversion', () {
      test('skips system messages in history', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OK',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'Main system prompt',
          history: [
            AgentMessage(
              id: 'sys-1',
              role: MessageRole.system,
              content: [const TextContent(text: 'This should be skipped')],
              timestamp: DateTime.now().toUtc(),
            ),
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hello')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        final messages = capturedBody?['messages'] as List<dynamic>;
        // Should only have system (from systemPrompt param) + user
        expect(messages.length, equals(2));
        expect(messages[0]['role'], equals('system'));
        expect(messages[0]['content'], equals('Main system prompt'));
        expect(messages[1]['role'], equals('user'));
      });

      test('handles empty content messages', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'OK',
                  },
                  'finish_reason': 'stop',
                }
              ],
              'usage': {
                'prompt_tokens': 10,
                'completion_tokens': 5,
              },
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        await adapter.generateResponse(
          systemPrompt: 'System prompt',
          history: [
            AgentMessage(
              id: 'msg-1',
              role: MessageRole.user,
              content: [], // Empty content
              timestamp: DateTime.now().toUtc(),
            ),
            AgentMessage(
              id: 'msg-2',
              role: MessageRole.user,
              content: [const TextContent(text: 'Real message')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        final messages = capturedBody?['messages'] as List<dynamic>;
        // Empty content message should be skipped
        expect(messages.length, equals(2)); // system + user
      });
    });

    group('finish reason mapping', () {
      test('maps stop to end_turn', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'Done'},
                  'finish_reason': 'stop',
                }
              ],
              'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [
            AgentMessage(
              id: '1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Hi')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        expect(response.stopReason, equals('end_turn'));
      });

      test('maps length to max_tokens', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'Truncated...'},
                  'finish_reason': 'length',
                }
              ],
              'usage': {'prompt_tokens': 10, 'completion_tokens': 4096},
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [
            AgentMessage(
              id: '1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Write a long story')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        expect(response.stopReason, equals('max_tokens'));
      });

      test('maps tool_calls to tool_use', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': null,
                    'tool_calls': [
                      {
                        'id': 'call_1',
                        'type': 'function',
                        'function': {
                          'name': 'test',
                          'arguments': '{}',
                        },
                      }
                    ],
                  },
                  'finish_reason': 'tool_calls',
                }
              ],
              'usage': {'prompt_tokens': 10, 'completion_tokens': 20},
            }),
            200,
          );
        });

        final adapter = GrokAdapter(config, client: mockClient);
        final response = await adapter.generateResponse(
          systemPrompt: 'Test',
          history: [
            AgentMessage(
              id: '1',
              role: MessageRole.user,
              content: [const TextContent(text: 'Use tool')],
              timestamp: DateTime.now().toUtc(),
            ),
          ],
          tools: [MockTool()],
        );

        expect(response.stopReason, equals('tool_use'));
      });
    });

    group('LLMRegistry integration', () {
      setUp(() {
        LLMRegistry.clearRegistrations();
      });

      test('can be registered and created via registry', () {
        LLMRegistry.register('grok', (config) => GrokAdapter(config));

        expect(LLMRegistry.isRegistered('grok'), isTrue);
        expect(LLMRegistry.registeredProviders, contains('grok'));

        final provider = LLMRegistry.create('grok', config);
        expect(provider, isA<GrokAdapter>());
        expect(provider.id, equals('grok'));
      });
    });
  });
}
