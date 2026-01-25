// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 2

library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/message.dart';

@Tags(['tdd-red'])
void main() {
  group('MessageRole', () {
    test('has all required enum values', () {
      expect(MessageRole.values.contains(MessageRole.user), isTrue);
      expect(MessageRole.values.contains(MessageRole.assistant), isTrue);
      expect(MessageRole.values.contains(MessageRole.system), isTrue);
    });

    test('enum values serialize to string', () {
      expect(MessageRole.user.toString(), contains('user'));
      expect(MessageRole.assistant.toString(), contains('assistant'));
      expect(MessageRole.system.toString(), contains('system'));
    });
  });

  group('Message', () {
    group('constructor', () {
      test('creates user message with text content', () {
        final message = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Hello, AI!',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        expect(message.id, equals('msg-123'));
        expect(message.role, equals(MessageRole.user));
        expect(message.textContent, equals('Hello, AI!'));
        expect(message.timestamp, equals(DateTime(2026, 1, 25, 10, 0)));
        expect(message.toolCalls, isNull);
        expect(message.toolResults, isNull);
        expect(message.attachments, isNull);
      });

      test('creates assistant message with tool calls', () {
        final toolCall = ToolCall(
          id: 'call-1',
          toolName: 'create_chart',
          arguments: {'type': 'line'},
        );

        final message = Message(
          id: 'msg-456',
          role: MessageRole.assistant,
          toolCalls: [toolCall],
          timestamp: DateTime(2026, 1, 25, 10, 1),
        );

        expect(message.id, equals('msg-456'));
        expect(message.role, equals(MessageRole.assistant));
        expect(message.textContent, isNull);
        expect(message.toolCalls?.length, equals(1));
        expect(message.toolCalls?[0].toolName, equals('create_chart'));
      });

      test('creates user message with file attachments', () {
        final attachment = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List.fromList([1, 2, 3]),
          status: FileStatus.ready,
        );

        final message = Message(
          id: 'msg-789',
          role: MessageRole.user,
          textContent: 'Analyze this file',
          attachments: [attachment],
          timestamp: DateTime(2026, 1, 25, 10, 2),
        );

        expect(message.attachments?.length, equals(1));
        expect(message.attachments?[0].fileName, equals('data.csv'));
        expect(message.role, equals(MessageRole.user));
      });

      test('creates message with tool results', () {
        final toolResult = ToolResult(
          id: 'result-1',
          toolCallId: 'call-1',
          success: true,
          result: {'chartId': 'chart-123'},
        );

        final message = Message(
          id: 'msg-999',
          role: MessageRole.assistant,
          toolResults: [toolResult],
          timestamp: DateTime(2026, 1, 25, 10, 3),
        );

        expect(message.toolResults?.length, equals(1));
        expect(message.toolResults?[0].success, isTrue);
      });

      test(
          'throws assertion error when neither textContent nor toolCalls provided for assistant',
          () {
        expect(
          () => Message(
            id: 'msg-bad',
            role: MessageRole.assistant,
            timestamp: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when attachments provided for non-user role',
          () {
        final attachment = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List.fromList([1, 2, 3]),
          status: FileStatus.ready,
        );

        expect(
          () => Message(
            id: 'msg-bad',
            role: MessageRole.assistant,
            textContent: 'Text',
            attachments: [attachment],
            timestamp: DateTime(2026, 1, 25),
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts user message correctly', () {
        final message = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final json = message.toJson();

        expect(json['id'], equals('msg-123'));
        expect(json['role'], equals('user'));
        expect(json['textContent'], equals('Hello'));
        expect(json['timestamp'], isA<String>());
      });

      test('toJson converts assistant message with tool calls correctly', () {
        final toolCall = ToolCall(
          id: 'call-1',
          toolName: 'create_chart',
          arguments: {'type': 'line'},
        );

        final message = Message(
          id: 'msg-456',
          role: MessageRole.assistant,
          toolCalls: [toolCall],
          timestamp: DateTime(2026, 1, 25, 10, 1),
        );

        final json = message.toJson();

        expect(json['id'], equals('msg-456'));
        expect(json['role'], equals('assistant'));
        expect(json['toolCalls'], isA<List>());
        expect((json['toolCalls'] as List).length, equals(1));
      });

      test('fromJson creates message from map', () {
        final json = {
          'id': 'msg-123',
          'role': 'user',
          'textContent': 'Hello',
          'timestamp': '2026-01-25T10:00:00.000',
        };

        final message = Message.fromJson(json);

        expect(message.id, equals('msg-123'));
        expect(message.role, equals(MessageRole.user));
        expect(message.textContent, equals('Hello'));
      });

      test('JSON round-trip preserves data', () {
        final original = Message(
          id: 'msg-round-trip',
          role: MessageRole.user,
          textContent: 'Test message',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final json = original.toJson();
        final restored = Message.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.role, equals(original.role));
        expect(restored.textContent, equals(original.textContent));
      });

      test('JSON round-trip with attachments preserves data', () {
        final attachment = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List.fromList([1, 2, 3]),
          status: FileStatus.ready,
        );

        final original = Message(
          id: 'msg-with-attachment',
          role: MessageRole.user,
          textContent: 'Analyze this',
          attachments: [attachment],
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final json = original.toJson();
        final restored = Message.fromJson(json);

        expect(restored.attachments?.length, equals(1));
        expect(restored.attachments?[0].fileName, equals('data.csv'));
      });
    });

    group('copyWith', () {
      test('creates copy with updated text content', () {
        final original = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Original text',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final copy = original.copyWith(
          textContent: 'Updated text',
        );

        expect(copy.id, equals(original.id));
        expect(copy.textContent, equals('Updated text'));
        expect(original.textContent, equals('Original text'));
      });

      test('creates copy with added tool results', () {
        final original = Message(
          id: 'msg-456',
          role: MessageRole.assistant,
          textContent: 'Processing',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final toolResult = ToolResult(
          id: 'result-1',
          toolCallId: 'call-1',
          success: true,
          result: {'data': 'value'},
        );

        final copy = original.copyWith(
          toolResults: [toolResult],
        );

        expect(copy.toolResults?.length, equals(1));
        expect(original.toolResults, isNull);
      });
    });

    group('equality', () {
      test('equal messages have same hash code', () {
        final msg1 = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final msg2 = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        expect(msg1, equals(msg2));
        expect(msg1.hashCode, equals(msg2.hashCode));
      });

      test('different ids produce different messages', () {
        final msg1 = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final msg2 = Message(
          id: 'msg-456',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        expect(msg1, isNot(equals(msg2)));
      });

      test('different roles produce different messages', () {
        final msg1 = Message(
          id: 'msg-123',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        final msg2 = Message(
          id: 'msg-123',
          role: MessageRole.assistant,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );

        expect(msg1, isNot(equals(msg2)));
      });
    });

    group('validation', () {
      test('allows system messages with text only', () {
        final message = Message(
          id: 'msg-system',
          role: MessageRole.system,
          textContent: 'System prompt',
          timestamp: DateTime(2026, 1, 25),
        );

        expect(message.role, equals(MessageRole.system));
        expect(message.textContent, equals('System prompt'));
      });

      test('allows assistant messages with both textContent and toolCalls', () {
        final toolCall = ToolCall(
          id: 'call-1',
          toolName: 'tool',
          arguments: {},
        );

        final message = Message(
          id: 'msg-hybrid',
          role: MessageRole.assistant,
          textContent: 'I will use this tool',
          toolCalls: [toolCall],
          timestamp: DateTime(2026, 1, 25),
        );

        expect(message.textContent, isNotNull);
        expect(message.toolCalls, isNotNull);
      });
    });
  });
}
