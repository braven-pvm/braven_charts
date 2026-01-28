import 'package:braven_agent/src/llm/llm_config.dart';
import 'package:braven_agent/src/llm/llm_response.dart';
import 'package:braven_agent/src/llm/models/agent_message.dart';
import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageContent Sealed Hierarchy', () {
    group('TextContent', () {
      test('constructs with required text parameter', () {
        const content = TextContent(text: 'Hello, world!');

        expect(content.text, equals('Hello, world!'));
      });

      test('toJson returns correct map', () {
        const content = TextContent(text: 'Test message');

        final json = content.toJson();

        expect(json, equals({'type': 'text', 'text': 'Test message'}));
      });

      test('fromJson creates instance from map', () {
        final json = {'type': 'text', 'text': 'Parsed text'};

        final content = TextContent.fromJson(json);

        expect(content.text, equals('Parsed text'));
      });

      test('round-trip serialization preserves data', () {
        const original = TextContent(text: 'Round trip test');

        final restored = TextContent.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('equality works for identical instances', () {
        const content1 = TextContent(text: 'Same');
        const content2 = TextContent(text: 'Same');

        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('equality fails for different instances', () {
        const content1 = TextContent(text: 'First');
        const content2 = TextContent(text: 'Second');

        expect(content1, isNot(equals(content2)));
      });

      test('toString returns readable representation', () {
        const content = TextContent(text: 'Hello');

        expect(content.toString(), contains('TextContent'));
        expect(content.toString(), contains('Hello'));
      });

      test('handles empty text', () {
        const content = TextContent(text: '');

        expect(content.text, isEmpty);

        final restored = TextContent.fromJson(content.toJson());
        expect(restored, equals(content));
      });

      test('handles special characters in text', () {
        const content = TextContent(text: 'Line1\nLine2\t"quoted"');

        final restored = TextContent.fromJson(content.toJson());
        expect(restored.text, equals('Line1\nLine2\t"quoted"'));
      });
    });

    group('ImageContent', () {
      test('constructs with required parameters', () {
        const content = ImageContent(
          data: 'iVBORw0KGgo=',
          mediaType: 'image/png',
        );

        expect(content.data, equals('iVBORw0KGgo='));
        expect(content.mediaType, equals('image/png'));
      });

      test('toJson returns correct map', () {
        const content = ImageContent(
          data: 'base64data',
          mediaType: 'image/jpeg',
        );

        final json = content.toJson();

        expect(
            json,
            equals({
              'type': 'image',
              'data': 'base64data',
              'mediaType': 'image/jpeg',
            }));
      });

      test('fromJson creates instance from map', () {
        final json = {
          'type': 'image',
          'data': 'encodedimage',
          'mediaType': 'image/gif',
        };

        final content = ImageContent.fromJson(json);

        expect(content.data, equals('encodedimage'));
        expect(content.mediaType, equals('image/gif'));
      });

      test('round-trip serialization preserves data', () {
        const original = ImageContent(
          data: 'iVBORw0KGgoAAAANSUhEUg==',
          mediaType: 'image/png',
        );

        final restored = ImageContent.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('equality works for identical instances', () {
        const content1 = ImageContent(data: 'abc', mediaType: 'image/png');
        const content2 = ImageContent(data: 'abc', mediaType: 'image/png');

        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('equality fails for different data', () {
        const content1 = ImageContent(data: 'abc', mediaType: 'image/png');
        const content2 = ImageContent(data: 'xyz', mediaType: 'image/png');

        expect(content1, isNot(equals(content2)));
      });

      test('equality fails for different mediaType', () {
        const content1 = ImageContent(data: 'abc', mediaType: 'image/png');
        const content2 = ImageContent(data: 'abc', mediaType: 'image/jpeg');

        expect(content1, isNot(equals(content2)));
      });

      test('toString shows mediaType and data length', () {
        const content = ImageContent(
          data: 'iVBORw0KGgoAAAANSUhEUg==',
          mediaType: 'image/png',
        );

        expect(content.toString(), contains('ImageContent'));
        expect(content.toString(), contains('image/png'));
        expect(content.toString(), contains('chars'));
      });
    });

    group('BinaryContent', () {
      test('constructs with required parameters', () {
        const content = BinaryContent(
          data: 'SGVsbG8gV29ybGQ=',
          mimeType: 'application/octet-stream',
        );

        expect(content.data, equals('SGVsbG8gV29ybGQ='));
        expect(content.mimeType, equals('application/octet-stream'));
        expect(content.filename, isNull);
      });

      test('constructs with optional filename', () {
        const content = BinaryContent(
          data: 'data',
          mimeType: 'application/pdf',
          filename: 'document.pdf',
        );

        expect(content.filename, equals('document.pdf'));
      });

      test('toJson returns correct map without filename', () {
        const content = BinaryContent(
          data: 'data',
          mimeType: 'application/json',
        );

        final json = content.toJson();

        expect(
            json,
            equals({
              'type': 'binary',
              'data': 'data',
              'mimeType': 'application/json',
            }));
        expect(json.containsKey('filename'), isFalse);
      });

      test('toJson includes filename when present', () {
        const content = BinaryContent(
          data: 'data',
          mimeType: 'text/plain',
          filename: 'readme.txt',
        );

        final json = content.toJson();

        expect(json['filename'], equals('readme.txt'));
      });

      test('fromJson creates instance without filename', () {
        final json = {
          'type': 'binary',
          'data': 'binarydata',
          'mimeType': 'application/zip',
        };

        final content = BinaryContent.fromJson(json);

        expect(content.data, equals('binarydata'));
        expect(content.mimeType, equals('application/zip'));
        expect(content.filename, isNull);
      });

      test('fromJson creates instance with filename', () {
        final json = {
          'type': 'binary',
          'data': 'binarydata',
          'mimeType': 'application/zip',
          'filename': 'archive.zip',
        };

        final content = BinaryContent.fromJson(json);

        expect(content.filename, equals('archive.zip'));
      });

      test('round-trip serialization preserves data with filename', () {
        const original = BinaryContent(
          data: 'encoded',
          mimeType: 'application/octet-stream',
          filename: 'data.bin',
        );

        final restored = BinaryContent.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('round-trip serialization preserves data without filename', () {
        const original = BinaryContent(
          data: 'encoded',
          mimeType: 'application/octet-stream',
        );

        final restored = BinaryContent.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('equality includes filename in comparison', () {
        const content1 = BinaryContent(
          data: 'data',
          mimeType: 'text/plain',
          filename: 'file1.txt',
        );
        const content2 = BinaryContent(
          data: 'data',
          mimeType: 'text/plain',
          filename: 'file2.txt',
        );

        expect(content1, isNot(equals(content2)));
      });

      test('equality treats null and missing filename as equal', () {
        const content1 = BinaryContent(data: 'data', mimeType: 'text/plain');
        const content2 = BinaryContent(
          data: 'data',
          mimeType: 'text/plain',
          filename: null,
        );

        expect(content1, equals(content2));
      });

      test('toString shows mimeType, filename, and data length', () {
        const content = BinaryContent(
          data: 'SGVsbG8=',
          mimeType: 'application/pdf',
          filename: 'doc.pdf',
        );

        expect(content.toString(), contains('BinaryContent'));
        expect(content.toString(), contains('application/pdf'));
        expect(content.toString(), contains('doc.pdf'));
      });
    });

    group('ToolUseContent', () {
      test('constructs with required parameters', () {
        const content = ToolUseContent(
          id: 'toolu_123',
          toolName: 'create_chart',
          input: {'type': 'line'},
        );

        expect(content.id, equals('toolu_123'));
        expect(content.toolName, equals('create_chart'));
        expect(content.input, equals({'type': 'line'}));
      });

      test('toJson returns correct map', () {
        const content = ToolUseContent(
          id: 'toolu_abc',
          toolName: 'search',
          input: {'query': 'test', 'limit': 10},
        );

        final json = content.toJson();

        expect(
            json,
            equals({
              'type': 'tool_use',
              'id': 'toolu_abc',
              'toolName': 'search',
              'input': {'query': 'test', 'limit': 10},
            }));
      });

      test('fromJson creates instance from map', () {
        final json = {
          'type': 'tool_use',
          'id': 'toolu_xyz',
          'toolName': 'get_weather',
          'input': {'city': 'London'},
        };

        final content = ToolUseContent.fromJson(json);

        expect(content.id, equals('toolu_xyz'));
        expect(content.toolName, equals('get_weather'));
        expect(content.input, equals({'city': 'London'}));
      });

      test('round-trip serialization preserves data', () {
        const original = ToolUseContent(
          id: 'toolu_001',
          toolName: 'complex_tool',
          input: {
            'nested': {'key': 'value'},
            'array': [1, 2, 3],
            'boolean': true,
          },
        );

        final restored = ToolUseContent.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('handles empty input map', () {
        const content = ToolUseContent(
          id: 'toolu_empty',
          toolName: 'no_params_tool',
          input: {},
        );

        final restored = ToolUseContent.fromJson(content.toJson());

        expect(restored.input, isEmpty);
        expect(restored, equals(content));
      });

      test('equality works for identical instances', () {
        const content1 = ToolUseContent(
          id: 'id1',
          toolName: 'tool',
          input: {'a': 1},
        );
        const content2 = ToolUseContent(
          id: 'id1',
          toolName: 'tool',
          input: {'a': 1},
        );

        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('equality fails for different id', () {
        const content1 = ToolUseContent(
          id: 'id1',
          toolName: 'tool',
          input: {},
        );
        const content2 = ToolUseContent(
          id: 'id2',
          toolName: 'tool',
          input: {},
        );

        expect(content1, isNot(equals(content2)));
      });

      test('toString shows id and toolName', () {
        const content = ToolUseContent(
          id: 'toolu_display',
          toolName: 'my_tool',
          input: {},
        );

        expect(content.toString(), contains('ToolUseContent'));
        expect(content.toString(), contains('toolu_display'));
        expect(content.toString(), contains('my_tool'));
      });
    });

    group('ToolResultContent', () {
      test('constructs with required parameters', () {
        const content = ToolResultContent(
          toolUseId: 'toolu_123',
          output: '{"result": "success"}',
        );

        expect(content.toolUseId, equals('toolu_123'));
        expect(content.output, equals('{"result": "success"}'));
        expect(content.isError, isFalse);
      });

      test('constructs with isError true', () {
        const content = ToolResultContent(
          toolUseId: 'toolu_err',
          output: 'Error: Something went wrong',
          isError: true,
        );

        expect(content.isError, isTrue);
      });

      test('toJson returns correct map with default isError', () {
        const content = ToolResultContent(
          toolUseId: 'toolu_001',
          output: 'output data',
        );

        final json = content.toJson();

        expect(
            json,
            equals({
              'type': 'tool_result',
              'toolUseId': 'toolu_001',
              'output': 'output data',
              'isError': false,
            }));
      });

      test('toJson returns correct map with isError true', () {
        const content = ToolResultContent(
          toolUseId: 'toolu_002',
          output: 'error message',
          isError: true,
        );

        final json = content.toJson();

        expect(json['isError'], isTrue);
      });

      test('fromJson creates instance with default isError', () {
        final json = {
          'type': 'tool_result',
          'toolUseId': 'toolu_parse',
          'output': 'parsed output',
        };

        final content = ToolResultContent.fromJson(json);

        expect(content.toolUseId, equals('toolu_parse'));
        expect(content.output, equals('parsed output'));
        expect(content.isError, isFalse);
      });

      test('fromJson creates instance with explicit isError', () {
        final json = {
          'type': 'tool_result',
          'toolUseId': 'toolu_err',
          'output': 'error',
          'isError': true,
        };

        final content = ToolResultContent.fromJson(json);

        expect(content.isError, isTrue);
      });

      test('round-trip serialization preserves data', () {
        const original = ToolResultContent(
          toolUseId: 'toolu_round',
          output: '{"data": [1, 2, 3]}',
          isError: false,
        );

        final restored = ToolResultContent.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('round-trip serialization preserves isError true', () {
        const original = ToolResultContent(
          toolUseId: 'toolu_round_err',
          output: 'Error occurred',
          isError: true,
        );

        final restored = ToolResultContent.fromJson(original.toJson());

        expect(restored, equals(original));
        expect(restored.isError, isTrue);
      });

      test('equality includes isError in comparison', () {
        const content1 = ToolResultContent(
          toolUseId: 'id',
          output: 'output',
          isError: false,
        );
        const content2 = ToolResultContent(
          toolUseId: 'id',
          output: 'output',
          isError: true,
        );

        expect(content1, isNot(equals(content2)));
      });

      test('toString shows toolUseId and isError', () {
        const content = ToolResultContent(
          toolUseId: 'toolu_display',
          output: 'output',
          isError: true,
        );

        expect(content.toString(), contains('ToolResultContent'));
        expect(content.toString(), contains('toolu_display'));
        expect(content.toString(), contains('true'));
      });
    });

    group('MessageContent.fromJson', () {
      test('creates TextContent for type text', () {
        final json = {'type': 'text', 'text': 'content'};

        final content = MessageContent.fromJson(json);

        expect(content, isA<TextContent>());
        expect((content as TextContent).text, equals('content'));
      });

      test('creates ImageContent for type image', () {
        final json = {
          'type': 'image',
          'data': 'imgdata',
          'mediaType': 'image/png',
        };

        final content = MessageContent.fromJson(json);

        expect(content, isA<ImageContent>());
      });

      test('creates BinaryContent for type binary', () {
        final json = {
          'type': 'binary',
          'data': 'bindata',
          'mimeType': 'application/pdf',
        };

        final content = MessageContent.fromJson(json);

        expect(content, isA<BinaryContent>());
      });

      test('creates ToolUseContent for type tool_use', () {
        final json = {
          'type': 'tool_use',
          'id': 'id1',
          'toolName': 'tool',
          'input': {},
        };

        final content = MessageContent.fromJson(json);

        expect(content, isA<ToolUseContent>());
      });

      test('creates ToolResultContent for type tool_result', () {
        final json = {
          'type': 'tool_result',
          'toolUseId': 'id1',
          'output': 'output',
        };

        final content = MessageContent.fromJson(json);

        expect(content, isA<ToolResultContent>());
      });

      test('throws ArgumentError for unknown type', () {
        final json = {'type': 'unknown_type', 'data': 'something'};

        expect(
          () => MessageContent.fromJson(json),
          throwsA(
            allOf(
              isA<ArgumentError>(),
              predicate<ArgumentError>(
                (e) => e.message.contains('Unknown MessageContent type'),
              ),
            ),
          ),
        );
      });
    });

    group('Pattern matching (sealed class)', () {
      test('exhaustive switch works on MessageContent', () {
        String describe(MessageContent content) {
          return switch (content) {
            TextContent(:final text) => 'Text: $text',
            ImageContent(:final mediaType) => 'Image: $mediaType',
            BinaryContent(:final mimeType) => 'Binary: $mimeType',
            ToolUseContent(:final toolName) => 'Tool: $toolName',
            ToolResultContent(:final isError) => 'Result: error=$isError',
          };
        }

        expect(
          describe(const TextContent(text: 'hello')),
          equals('Text: hello'),
        );
        expect(
          describe(
            const ImageContent(data: 'd', mediaType: 'image/png'),
          ),
          equals('Image: image/png'),
        );
        expect(
          describe(
            const BinaryContent(data: 'd', mimeType: 'application/json'),
          ),
          equals('Binary: application/json'),
        );
        expect(
          describe(
            const ToolUseContent(id: 'i', toolName: 'search', input: {}),
          ),
          equals('Tool: search'),
        );
        expect(
          describe(
            const ToolResultContent(toolUseId: 'i', output: 'o', isError: true),
          ),
          equals('Result: error=true'),
        );
      });

      test('type checks work correctly', () {
        const MessageContent text = TextContent(text: 'test');
        const MessageContent image = ImageContent(
          data: 'd',
          mediaType: 'image/png',
        );

        expect(text is TextContent, isTrue);
        expect(text is ImageContent, isFalse);
        expect(image is ImageContent, isTrue);
        expect(image is TextContent, isFalse);
      });
    });
  });

  group('AgentMessage', () {
    final testTimestamp = DateTime.utc(2025, 1, 15, 10, 30, 0);

    group('Construction', () {
      test('constructs with required parameters', () {
        final message = AgentMessage(
          id: 'msg_001',
          role: MessageRole.user,
          content: const [TextContent(text: 'Hello')],
          timestamp: testTimestamp,
        );

        expect(message.id, equals('msg_001'));
        expect(message.role, equals(MessageRole.user));
        expect(message.content, hasLength(1));
        expect(message.timestamp, equals(testTimestamp));
        expect(message.metadata, isNull);
      });

      test('constructs with optional metadata', () {
        final message = AgentMessage(
          id: 'msg_002',
          role: MessageRole.assistant,
          content: const [],
          timestamp: testTimestamp,
          metadata: {'key': 'value', 'count': 42},
        );

        expect(message.metadata, equals({'key': 'value', 'count': 42}));
      });

      test('constructs with empty content list', () {
        final message = AgentMessage(
          id: 'msg_empty',
          role: MessageRole.system,
          content: const [],
          timestamp: testTimestamp,
        );

        expect(message.content, isEmpty);
      });

      test('constructs with multiple content types', () {
        final message = AgentMessage(
          id: 'msg_multi',
          role: MessageRole.assistant,
          content: const [
            TextContent(text: 'Here is the image:'),
            ImageContent(data: 'imgdata', mediaType: 'image/png'),
            ToolUseContent(id: 'tool1', toolName: 'analyze', input: {}),
          ],
          timestamp: testTimestamp,
        );

        expect(message.content, hasLength(3));
        expect(message.content[0], isA<TextContent>());
        expect(message.content[1], isA<ImageContent>());
        expect(message.content[2], isA<ToolUseContent>());
      });
    });

    group('MessageRole enum', () {
      test('has all expected values', () {
        expect(MessageRole.values, hasLength(4));
        expect(MessageRole.values, contains(MessageRole.user));
        expect(MessageRole.values, contains(MessageRole.assistant));
        expect(MessageRole.values, contains(MessageRole.system));
        expect(MessageRole.values, contains(MessageRole.tool));
      });

      test('byName works for all roles', () {
        expect(MessageRole.values.byName('user'), equals(MessageRole.user));
        expect(
          MessageRole.values.byName('assistant'),
          equals(MessageRole.assistant),
        );
        expect(MessageRole.values.byName('system'), equals(MessageRole.system));
        expect(MessageRole.values.byName('tool'), equals(MessageRole.tool));
      });
    });

    group('JSON Serialization', () {
      test('toJson returns correct map without metadata', () {
        final message = AgentMessage(
          id: 'msg_json',
          role: MessageRole.user,
          content: const [TextContent(text: 'Test')],
          timestamp: testTimestamp,
        );

        final json = message.toJson();

        expect(json['id'], equals('msg_json'));
        expect(json['role'], equals('user'));
        expect(json['content'], hasLength(1));
        expect(json['timestamp'], equals('2025-01-15T10:30:00.000Z'));
        expect(json.containsKey('metadata'), isFalse);
      });

      test('toJson includes metadata when present', () {
        final message = AgentMessage(
          id: 'msg_meta',
          role: MessageRole.assistant,
          content: const [],
          timestamp: testTimestamp,
          metadata: {'provider': 'anthropic'},
        );

        final json = message.toJson();

        expect(json['metadata'], equals({'provider': 'anthropic'}));
      });

      test('fromJson creates instance without metadata', () {
        final json = {
          'id': 'msg_parse',
          'role': 'system',
          'content': [
            {'type': 'text', 'text': 'You are helpful.'},
          ],
          'timestamp': '2025-01-15T10:30:00.000Z',
        };

        final message = AgentMessage.fromJson(json);

        expect(message.id, equals('msg_parse'));
        expect(message.role, equals(MessageRole.system));
        expect(message.content, hasLength(1));
        expect(message.content[0], isA<TextContent>());
        expect(message.metadata, isNull);
      });

      test('fromJson creates instance with metadata', () {
        final json = {
          'id': 'msg_parse_meta',
          'role': 'tool',
          'content': [
            {
              'type': 'tool_result',
              'toolUseId': 'tool1',
              'output': 'result',
            },
          ],
          'timestamp': '2025-01-15T10:30:00.000Z',
          'metadata': {'version': '1.0'},
        };

        final message = AgentMessage.fromJson(json);

        expect(message.metadata, equals({'version': '1.0'}));
      });

      test('round-trip serialization preserves all data', () {
        final original = AgentMessage(
          id: 'msg_roundtrip',
          role: MessageRole.assistant,
          content: const [
            TextContent(text: 'Here is the result'),
            ToolUseContent(
              id: 'tool_1',
              toolName: 'chart',
              input: {'type': 'bar'},
            ),
          ],
          timestamp: testTimestamp,
          metadata: {'model': 'claude', 'tokens': 100},
        );

        final restored = AgentMessage.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('serializes multiple content blocks correctly', () {
        final message = AgentMessage(
          id: 'msg_blocks',
          role: MessageRole.assistant,
          content: const [
            TextContent(text: 'First'),
            TextContent(text: 'Second'),
            BinaryContent(data: 'data', mimeType: 'text/plain'),
          ],
          timestamp: testTimestamp,
        );

        final json = message.toJson();
        final restored = AgentMessage.fromJson(json);

        expect(restored.content, hasLength(3));
        expect(restored.content[0], isA<TextContent>());
        expect(restored.content[1], isA<TextContent>());
        expect(restored.content[2], isA<BinaryContent>());
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        final original = AgentMessage(
          id: 'original_id',
          role: MessageRole.user,
          content: const [TextContent(text: 'msg')],
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(id: 'new_id');

        expect(copy.id, equals('new_id'));
        expect(copy.role, equals(original.role));
        expect(copy.content, equals(original.content));
        expect(copy.timestamp, equals(original.timestamp));
      });

      test('creates copy with updated role', () {
        final original = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(role: MessageRole.assistant);

        expect(copy.role, equals(MessageRole.assistant));
      });

      test('creates copy with updated content', () {
        final original = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [TextContent(text: 'old')],
          timestamp: testTimestamp,
        );

        final copy = original.copyWith(
          content: const [TextContent(text: 'new')],
        );

        expect((copy.content[0] as TextContent).text, equals('new'));
      });

      test('creates copy with updated timestamp', () {
        final original = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
        );
        final newTimestamp = DateTime.utc(2025, 6, 1);

        final copy = original.copyWith(timestamp: newTimestamp);

        expect(copy.timestamp, equals(newTimestamp));
      });

      test('creates copy with updated metadata', () {
        final original = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
          metadata: {'old': 'data'},
        );

        final copy = original.copyWith(metadata: {'new': 'data'});

        expect(copy.metadata, equals({'new': 'data'}));
      });

      test('preserves original when no changes', () {
        final original = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [TextContent(text: 'text')],
          timestamp: testTimestamp,
          metadata: {'key': 'value'},
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('Equality', () {
      test('equal messages are equal', () {
        final message1 = AgentMessage(
          id: 'msg_eq',
          role: MessageRole.user,
          content: const [TextContent(text: 'Hello')],
          timestamp: testTimestamp,
        );
        final message2 = AgentMessage(
          id: 'msg_eq',
          role: MessageRole.user,
          content: const [TextContent(text: 'Hello')],
          timestamp: testTimestamp,
        );

        expect(message1, equals(message2));
        expect(message1.hashCode, equals(message2.hashCode));
      });

      test('different id makes messages not equal', () {
        final message1 = AgentMessage(
          id: 'msg_1',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
        );
        final message2 = AgentMessage(
          id: 'msg_2',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
        );

        expect(message1, isNot(equals(message2)));
      });

      test('different content makes messages not equal', () {
        final message1 = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [TextContent(text: 'A')],
          timestamp: testTimestamp,
        );
        final message2 = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [TextContent(text: 'B')],
          timestamp: testTimestamp,
        );

        expect(message1, isNot(equals(message2)));
      });

      test('different metadata makes messages not equal', () {
        final message1 = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
          metadata: {'a': 1},
        );
        final message2 = AgentMessage(
          id: 'msg',
          role: MessageRole.user,
          content: const [],
          timestamp: testTimestamp,
          metadata: {'b': 2},
        );

        expect(message1, isNot(equals(message2)));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final message = AgentMessage(
          id: 'msg_str',
          role: MessageRole.assistant,
          content: const [TextContent(text: 'Hi'), TextContent(text: 'There')],
          timestamp: testTimestamp,
        );

        expect(message.toString(), contains('AgentMessage'));
        expect(message.toString(), contains('msg_str'));
        expect(message.toString(), contains('assistant'));
        expect(message.toString(), contains('2 blocks'));
      });
    });
  });

  group('LLMConfig', () {
    group('Construction', () {
      test('constructs with required apiKey only', () {
        const config = LLMConfig(apiKey: 'sk-test-key');

        expect(config.apiKey, equals('sk-test-key'));
        expect(config.baseUrl, isNull);
        expect(config.model, equals(LLMConfig.defaultModel));
        expect(config.temperature, equals(LLMConfig.defaultTemperature));
        expect(config.maxTokens, equals(LLMConfig.defaultMaxTokens));
        expect(config.providerOptions, isNull);
      });

      test('constructs with all parameters', () {
        const config = LLMConfig(
          apiKey: 'sk-full-key',
          baseUrl: 'https://custom.api.com',
          model: 'gpt-4',
          temperature: 0.5,
          maxTokens: 2048,
          providerOptions: {'streaming': true},
        );

        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('gpt-4'));
        expect(config.temperature, equals(0.5));
        expect(config.maxTokens, equals(2048));
        expect(config.providerOptions, equals({'streaming': true}));
      });

      test('default values are correct', () {
        expect(LLMConfig.defaultModel, equals('claude-sonnet-4-20250514'));
        expect(LLMConfig.defaultTemperature, equals(0.7));
        expect(LLMConfig.defaultMaxTokens, equals(4096));
      });
    });

    group('JSON Serialization', () {
      test('toJson returns correct map with required fields', () {
        const config = LLMConfig(apiKey: 'sk-test');

        final json = config.toJson();

        expect(json['apiKey'], equals('sk-test'));
        expect(json['model'], equals(LLMConfig.defaultModel));
        expect(json['temperature'], equals(LLMConfig.defaultTemperature));
        expect(json['maxTokens'], equals(LLMConfig.defaultMaxTokens));
        expect(json.containsKey('baseUrl'), isFalse);
        expect(json.containsKey('providerOptions'), isFalse);
      });

      test('toJson includes optional fields when present', () {
        const config = LLMConfig(
          apiKey: 'sk-test',
          baseUrl: 'https://api.example.com',
          providerOptions: {'key': 'value'},
        );

        final json = config.toJson();

        expect(json['baseUrl'], equals('https://api.example.com'));
        expect(json['providerOptions'], equals({'key': 'value'}));
      });

      test('fromJson creates instance with required fields', () {
        final json = {'apiKey': 'sk-parsed'};

        final config = LLMConfig.fromJson(json);

        expect(config.apiKey, equals('sk-parsed'));
        expect(config.model, equals(LLMConfig.defaultModel));
        expect(config.temperature, equals(LLMConfig.defaultTemperature));
        expect(config.maxTokens, equals(LLMConfig.defaultMaxTokens));
      });

      test('fromJson creates instance with all fields', () {
        final json = {
          'apiKey': 'sk-full',
          'baseUrl': 'https://custom.com',
          'model': 'custom-model',
          'temperature': 0.3,
          'maxTokens': 8192,
          'providerOptions': {'option': true},
        };

        final config = LLMConfig.fromJson(json);

        expect(config.apiKey, equals('sk-full'));
        expect(config.baseUrl, equals('https://custom.com'));
        expect(config.model, equals('custom-model'));
        expect(config.temperature, equals(0.3));
        expect(config.maxTokens, equals(8192));
        expect(config.providerOptions, equals({'option': true}));
      });

      test('fromJson handles int temperature as double', () {
        final json = {
          'apiKey': 'sk-test',
          'temperature': 1, // int instead of double
        };

        final config = LLMConfig.fromJson(json);

        expect(config.temperature, equals(1.0));
        expect(config.temperature, isA<double>());
      });

      test('round-trip serialization preserves all data', () {
        const original = LLMConfig(
          apiKey: 'sk-roundtrip',
          baseUrl: 'https://api.com',
          model: 'model-v2',
          temperature: 0.8,
          maxTokens: 1024,
          providerOptions: {
            'nested': {'key': 'value'}
          },
        );

        final restored = LLMConfig.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('round-trip preserves null optional fields', () {
        const original = LLMConfig(apiKey: 'sk-minimal');

        final restored = LLMConfig.fromJson(original.toJson());

        expect(restored.baseUrl, isNull);
        expect(restored.providerOptions, isNull);
        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('creates copy with updated apiKey', () {
        const original = LLMConfig(apiKey: 'old-key');

        final copy = original.copyWith(apiKey: 'new-key');

        expect(copy.apiKey, equals('new-key'));
        expect(copy.model, equals(original.model));
      });

      test('creates copy with updated model', () {
        const original = LLMConfig(apiKey: 'key');

        final copy = original.copyWith(model: 'new-model');

        expect(copy.model, equals('new-model'));
      });

      test('creates copy with updated temperature', () {
        const original = LLMConfig(apiKey: 'key', temperature: 0.5);

        final copy = original.copyWith(temperature: 0.9);

        expect(copy.temperature, equals(0.9));
      });

      test('creates copy with updated maxTokens', () {
        const original = LLMConfig(apiKey: 'key');

        final copy = original.copyWith(maxTokens: 512);

        expect(copy.maxTokens, equals(512));
      });

      test('creates copy with updated baseUrl', () {
        const original = LLMConfig(apiKey: 'key');

        final copy = original.copyWith(baseUrl: 'https://new.api.com');

        expect(copy.baseUrl, equals('https://new.api.com'));
      });

      test('creates copy with updated providerOptions', () {
        const original = LLMConfig(apiKey: 'key');

        final copy = original.copyWith(providerOptions: {'new': 'option'});

        expect(copy.providerOptions, equals({'new': 'option'}));
      });

      test('preserves original when no changes', () {
        const original = LLMConfig(
          apiKey: 'key',
          baseUrl: 'https://api.com',
          model: 'model',
          temperature: 0.5,
          maxTokens: 1000,
          providerOptions: {'opt': true},
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('Equality', () {
      test('equal configs are equal', () {
        const config1 = LLMConfig(
          apiKey: 'same-key',
          model: 'same-model',
          temperature: 0.5,
        );
        const config2 = LLMConfig(
          apiKey: 'same-key',
          model: 'same-model',
          temperature: 0.5,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different apiKey makes configs not equal', () {
        const config1 = LLMConfig(apiKey: 'key1');
        const config2 = LLMConfig(apiKey: 'key2');

        expect(config1, isNot(equals(config2)));
      });

      test('different temperature makes configs not equal', () {
        const config1 = LLMConfig(apiKey: 'key', temperature: 0.5);
        const config2 = LLMConfig(apiKey: 'key', temperature: 0.6);

        expect(config1, isNot(equals(config2)));
      });

      test('different providerOptions makes configs not equal', () {
        const config1 = LLMConfig(
          apiKey: 'key',
          providerOptions: {'a': 1},
        );
        const config2 = LLMConfig(
          apiKey: 'key',
          providerOptions: {'b': 2},
        );

        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('returns readable representation without apiKey', () {
        const config = LLMConfig(
          apiKey: 'sk-secret-key',
          model: 'claude-3',
          temperature: 0.7,
          maxTokens: 4096,
        );

        final str = config.toString();

        expect(str, contains('LLMConfig'));
        expect(str, contains('claude-3'));
        expect(str, contains('0.7'));
        expect(str, contains('4096'));
        // apiKey should not be in toString for security
        expect(str, isNot(contains('sk-secret-key')));
      });
    });
  });

  group('LLMResponse', () {
    final testMessage = AgentMessage(
      id: 'msg_resp',
      role: MessageRole.assistant,
      content: const [TextContent(text: 'Response text')],
      timestamp: DateTime.utc(2025, 1, 15),
    );

    group('Construction', () {
      test('constructs with required parameters', () {
        final response = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
        );

        expect(response.message, equals(testMessage));
        expect(response.inputTokens, equals(100));
        expect(response.outputTokens, equals(50));
        expect(response.stopReason, isNull);
      });

      test('constructs with optional stopReason', () {
        final response = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'end_turn',
        );

        expect(response.stopReason, equals('end_turn'));
      });
    });

    group('JSON Serialization', () {
      test('toJson returns correct map without stopReason', () {
        final response = LLMResponse(
          message: testMessage,
          inputTokens: 150,
          outputTokens: 75,
        );

        final json = response.toJson();

        expect(json['message'], isA<Map<String, dynamic>>());
        expect(json['inputTokens'], equals(150));
        expect(json['outputTokens'], equals(75));
        expect(json.containsKey('stopReason'), isFalse);
      });

      test('toJson includes stopReason when present', () {
        final response = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'tool_use',
        );

        final json = response.toJson();

        expect(json['stopReason'], equals('tool_use'));
      });

      test('fromJson creates instance without stopReason', () {
        final json = {
          'message': testMessage.toJson(),
          'inputTokens': 200,
          'outputTokens': 100,
        };

        final response = LLMResponse.fromJson(json);

        expect(response.inputTokens, equals(200));
        expect(response.outputTokens, equals(100));
        expect(response.stopReason, isNull);
      });

      test('fromJson creates instance with stopReason', () {
        final json = {
          'message': testMessage.toJson(),
          'inputTokens': 200,
          'outputTokens': 100,
          'stopReason': 'max_tokens',
        };

        final response = LLMResponse.fromJson(json);

        expect(response.stopReason, equals('max_tokens'));
      });

      test('round-trip serialization preserves all data', () {
        final original = LLMResponse(
          message: testMessage,
          inputTokens: 500,
          outputTokens: 250,
          stopReason: 'stop_sequence',
        );

        final restored = LLMResponse.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('nested message is properly serialized', () {
        final messageWithToolUse = AgentMessage(
          id: 'msg_tool',
          role: MessageRole.assistant,
          content: const [
            TextContent(text: 'Using tool'),
            ToolUseContent(
              id: 'tool_1',
              toolName: 'chart',
              input: {'type': 'line'},
            ),
          ],
          timestamp: DateTime.utc(2025, 1, 15),
        );
        final response = LLMResponse(
          message: messageWithToolUse,
          inputTokens: 100,
          outputTokens: 50,
        );

        final restored = LLMResponse.fromJson(response.toJson());

        expect(restored.message.content, hasLength(2));
        expect(restored.message.content[0], isA<TextContent>());
        expect(restored.message.content[1], isA<ToolUseContent>());
      });
    });

    group('copyWith', () {
      test('creates copy with updated message', () {
        final original = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
        );
        final newMessage = AgentMessage(
          id: 'new_msg',
          role: MessageRole.assistant,
          content: const [TextContent(text: 'New')],
          timestamp: DateTime.utc(2025, 2, 1),
        );

        final copy = original.copyWith(message: newMessage);

        expect(copy.message.id, equals('new_msg'));
        expect(copy.inputTokens, equals(original.inputTokens));
      });

      test('creates copy with updated inputTokens', () {
        final original = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
        );

        final copy = original.copyWith(inputTokens: 200);

        expect(copy.inputTokens, equals(200));
      });

      test('creates copy with updated outputTokens', () {
        final original = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
        );

        final copy = original.copyWith(outputTokens: 75);

        expect(copy.outputTokens, equals(75));
      });

      test('creates copy with updated stopReason', () {
        final original = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
        );

        final copy = original.copyWith(stopReason: 'end_turn');

        expect(copy.stopReason, equals('end_turn'));
      });

      test('preserves original when no changes', () {
        final original = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'end_turn',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('Equality', () {
      test('equal responses are equal', () {
        final response1 = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'end_turn',
        );
        final response2 = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'end_turn',
        );

        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('different message makes responses not equal', () {
        final msg1 = AgentMessage(
          id: 'msg1',
          role: MessageRole.assistant,
          content: const [],
          timestamp: DateTime.utc(2025, 1, 1),
        );
        final msg2 = AgentMessage(
          id: 'msg2',
          role: MessageRole.assistant,
          content: const [],
          timestamp: DateTime.utc(2025, 1, 1),
        );
        final response1 = LLMResponse(
          message: msg1,
          inputTokens: 100,
          outputTokens: 50,
        );
        final response2 = LLMResponse(
          message: msg2,
          inputTokens: 100,
          outputTokens: 50,
        );

        expect(response1, isNot(equals(response2)));
      });

      test('different token counts make responses not equal', () {
        final response1 = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
        );
        final response2 = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 60,
        );

        expect(response1, isNot(equals(response2)));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final response = LLMResponse(
          message: testMessage,
          inputTokens: 100,
          outputTokens: 50,
          stopReason: 'end_turn',
        );

        final str = response.toString();

        expect(str, contains('LLMResponse'));
        expect(str, contains('100'));
        expect(str, contains('50'));
        expect(str, contains('end_turn'));
      });
    });
  });

  group('LLMChunk', () {
    group('Construction', () {
      test('constructs with defaults', () {
        const chunk = LLMChunk();

        expect(chunk.textDelta, isNull);
        expect(chunk.toolUse, isNull);
        expect(chunk.isComplete, isFalse);
        expect(chunk.stopReason, isNull);
      });

      test('constructs with textDelta', () {
        const chunk = LLMChunk(textDelta: 'Hello');

        expect(chunk.textDelta, equals('Hello'));
      });

      test('constructs with toolUse', () {
        const toolUse = ToolUseContent(
          id: 'tool_1',
          toolName: 'search',
          input: {'query': 'test'},
        );
        const chunk = LLMChunk(toolUse: toolUse);

        expect(chunk.toolUse, equals(toolUse));
      });

      test('constructs with isComplete true', () {
        const chunk = LLMChunk(isComplete: true);

        expect(chunk.isComplete, isTrue);
      });

      test('constructs with stopReason', () {
        const chunk = LLMChunk(
          isComplete: true,
          stopReason: 'end_turn',
        );

        expect(chunk.stopReason, equals('end_turn'));
      });

      test('constructs with all parameters', () {
        const toolUse = ToolUseContent(
          id: 't1',
          toolName: 'tool',
          input: {},
        );
        const chunk = LLMChunk(
          textDelta: 'delta',
          toolUse: toolUse,
          isComplete: true,
          stopReason: 'tool_use',
        );

        expect(chunk.textDelta, equals('delta'));
        expect(chunk.toolUse, equals(toolUse));
        expect(chunk.isComplete, isTrue);
        expect(chunk.stopReason, equals('tool_use'));
      });
    });

    group('JSON Serialization', () {
      test('toJson returns minimal map for default chunk', () {
        const chunk = LLMChunk();

        final json = chunk.toJson();

        expect(json, equals({'isComplete': false}));
        expect(json.containsKey('textDelta'), isFalse);
        expect(json.containsKey('toolUse'), isFalse);
        expect(json.containsKey('stopReason'), isFalse);
      });

      test('toJson includes textDelta when present', () {
        const chunk = LLMChunk(textDelta: 'streaming text');

        final json = chunk.toJson();

        expect(json['textDelta'], equals('streaming text'));
      });

      test('toJson includes toolUse when present', () {
        const chunk = LLMChunk(
          toolUse: ToolUseContent(
            id: 'tool_json',
            toolName: 'test_tool',
            input: {'param': 'value'},
          ),
        );

        final json = chunk.toJson();

        expect(json['toolUse'], isA<Map<String, dynamic>>());
        expect(json['toolUse']['toolName'], equals('test_tool'));
      });

      test('toJson includes stopReason when present', () {
        const chunk = LLMChunk(
          isComplete: true,
          stopReason: 'max_tokens',
        );

        final json = chunk.toJson();

        expect(json['stopReason'], equals('max_tokens'));
      });

      test('fromJson creates instance with defaults', () {
        final json = <String, dynamic>{};

        final chunk = LLMChunk.fromJson(json);

        expect(chunk.textDelta, isNull);
        expect(chunk.toolUse, isNull);
        expect(chunk.isComplete, isFalse);
        expect(chunk.stopReason, isNull);
      });

      test('fromJson creates instance with all fields', () {
        final json = {
          'textDelta': 'parsed delta',
          'toolUse': {
            'type': 'tool_use',
            'id': 'tool_parsed',
            'toolName': 'parsed_tool',
            'input': {'key': 'value'},
          },
          'isComplete': true,
          'stopReason': 'tool_use',
        };

        final chunk = LLMChunk.fromJson(json);

        expect(chunk.textDelta, equals('parsed delta'));
        expect(chunk.toolUse, isNotNull);
        expect(chunk.toolUse!.toolName, equals('parsed_tool'));
        expect(chunk.isComplete, isTrue);
        expect(chunk.stopReason, equals('tool_use'));
      });

      test('round-trip serialization preserves all data', () {
        const original = LLMChunk(
          textDelta: 'round trip',
          isComplete: false,
        );

        final restored = LLMChunk.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('round-trip serialization preserves toolUse', () {
        const original = LLMChunk(
          toolUse: ToolUseContent(
            id: 'tool_round',
            toolName: 'round_tool',
            input: {
              'nested': {'deep': 'value'}
            },
          ),
          isComplete: true,
          stopReason: 'tool_use',
        );

        final restored = LLMChunk.fromJson(original.toJson());

        expect(restored, equals(original));
        expect(
            restored.toolUse!.input,
            equals({
              'nested': {'deep': 'value'}
            }));
      });
    });

    group('copyWith', () {
      test('creates copy with updated textDelta', () {
        const original = LLMChunk(textDelta: 'old');

        final copy = original.copyWith(textDelta: 'new');

        expect(copy.textDelta, equals('new'));
      });

      test('creates copy with updated toolUse', () {
        const original = LLMChunk();
        const newToolUse = ToolUseContent(
          id: 't1',
          toolName: 'new_tool',
          input: {},
        );

        final copy = original.copyWith(toolUse: newToolUse);

        expect(copy.toolUse, equals(newToolUse));
      });

      test('creates copy with updated isComplete', () {
        const original = LLMChunk(isComplete: false);

        final copy = original.copyWith(isComplete: true);

        expect(copy.isComplete, isTrue);
      });

      test('creates copy with updated stopReason', () {
        const original = LLMChunk(isComplete: true);

        final copy = original.copyWith(stopReason: 'end_turn');

        expect(copy.stopReason, equals('end_turn'));
      });

      test('preserves original when no changes', () {
        const original = LLMChunk(
          textDelta: 'text',
          isComplete: true,
          stopReason: 'end_turn',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('Equality', () {
      test('equal chunks are equal', () {
        const chunk1 = LLMChunk(
          textDelta: 'same',
          isComplete: false,
        );
        const chunk2 = LLMChunk(
          textDelta: 'same',
          isComplete: false,
        );

        expect(chunk1, equals(chunk2));
        expect(chunk1.hashCode, equals(chunk2.hashCode));
      });

      test('different textDelta makes chunks not equal', () {
        const chunk1 = LLMChunk(textDelta: 'a');
        const chunk2 = LLMChunk(textDelta: 'b');

        expect(chunk1, isNot(equals(chunk2)));
      });

      test('different isComplete makes chunks not equal', () {
        const chunk1 = LLMChunk(isComplete: false);
        const chunk2 = LLMChunk(isComplete: true);

        expect(chunk1, isNot(equals(chunk2)));
      });

      test('different toolUse makes chunks not equal', () {
        const chunk1 = LLMChunk(
          toolUse: ToolUseContent(id: 't1', toolName: 'a', input: {}),
        );
        const chunk2 = LLMChunk(
          toolUse: ToolUseContent(id: 't2', toolName: 'b', input: {}),
        );

        expect(chunk1, isNot(equals(chunk2)));
      });

      test('null vs present toolUse makes chunks not equal', () {
        const chunk1 = LLMChunk();
        const chunk2 = LLMChunk(
          toolUse: ToolUseContent(id: 't1', toolName: 'a', input: {}),
        );

        expect(chunk1, isNot(equals(chunk2)));
      });
    });

    group('toString', () {
      test('returns readable representation for text chunk', () {
        const chunk = LLMChunk(
          textDelta: 'Hello World',
          isComplete: false,
        );

        final str = chunk.toString();

        expect(str, contains('LLMChunk'));
        expect(str, contains('11 chars'));
        expect(str, contains('false'));
      });

      test('returns readable representation for tool chunk', () {
        const chunk = LLMChunk(
          toolUse: ToolUseContent(id: 't', toolName: 'tool', input: {}),
          isComplete: true,
        );

        final str = chunk.toString();

        expect(str, contains('toolUse: true'));
        expect(str, contains('isComplete: true'));
      });

      test('returns readable representation for empty chunk', () {
        const chunk = LLMChunk();

        final str = chunk.toString();

        expect(str, contains('0 chars'));
        expect(str, contains('toolUse: false'));
      });
    });
  });

  group('Edge Cases', () {
    test('handles deeply nested JSON in tool input', () {
      const content = ToolUseContent(
        id: 'deep',
        toolName: 'complex',
        input: {
          'level1': {
            'level2': {
              'level3': {
                'array': [
                  1,
                  2,
                  {'nested': 'value'}
                ],
              },
            },
          },
        },
      );

      final restored = ToolUseContent.fromJson(content.toJson());

      expect(restored, equals(content));
      expect(
        (((restored.input['level1'] as Map)['level2'] as Map)['level3']
            as Map)['array'],
        equals([
          1,
          2,
          {'nested': 'value'},
        ]),
      );
    });

    test('handles unicode in text content', () {
      const content = TextContent(
        text: '你好世界 🌍 مرحبا العالم',
      );

      final restored = TextContent.fromJson(content.toJson());

      expect(restored.text, equals('你好世界 🌍 مرحبا العالم'));
    });

    test('handles large base64 data', () {
      final largeData = 'A' * 10000; // 10KB of data
      final content = ImageContent(
        data: largeData,
        mediaType: 'image/png',
      );

      final restored = ImageContent.fromJson(content.toJson());

      expect(restored.data.length, equals(10000));
      expect(restored, equals(content));
    });

    test('handles empty lists and maps', () {
      final message = AgentMessage(
        id: 'empty',
        role: MessageRole.user,
        content: const [],
        timestamp: DateTime.utc(2025, 1, 1),
        metadata: {},
      );

      final restored = AgentMessage.fromJson(message.toJson());

      expect(restored.content, isEmpty);
      // Note: empty map becomes {} not null after serialization
      expect(restored.metadata, isNotNull);
    });

    test('LLMConfig with zero temperature', () {
      const config = LLMConfig(
        apiKey: 'key',
        temperature: 0.0,
      );

      final restored = LLMConfig.fromJson(config.toJson());

      expect(restored.temperature, equals(0.0));
    });

    test('LLMChunk with empty textDelta', () {
      const chunk = LLMChunk(textDelta: '');

      final restored = LLMChunk.fromJson(chunk.toJson());

      expect(restored.textDelta, equals(''));
    });

    test('MessageContent types are mutually exclusive in pattern matching', () {
      final contents = <MessageContent>[
        const TextContent(text: 'text'),
        const ImageContent(data: 'd', mediaType: 'm'),
        const BinaryContent(data: 'd', mimeType: 'm'),
        const ToolUseContent(id: 'i', toolName: 't', input: {}),
        const ToolResultContent(toolUseId: 'i', output: 'o'),
      ];

      for (final content in contents) {
        var matchCount = 0;
        if (content is TextContent) matchCount++;
        if (content is ImageContent) matchCount++;
        if (content is BinaryContent) matchCount++;
        if (content is ToolUseContent) matchCount++;
        if (content is ToolResultContent) matchCount++;

        expect(matchCount, equals(1),
            reason: '$content should match exactly one type');
      }
    });
  });
}
