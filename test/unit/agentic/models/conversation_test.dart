// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 2

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/conversation.dart';

@Tags(['tdd-red'])
void main() {
  group('Conversation', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        final conversation = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 0,
          totalOutputTokens: 0,
        );

        expect(conversation.id, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(conversation.messages, isEmpty);
        expect(conversation.dataStore, isEmpty);
        expect(conversation.charts, isEmpty);
        expect(conversation.totalInputTokens, equals(0));
        expect(conversation.totalOutputTokens, equals(0));
        expect(conversation.estimatedCostUsd, isNull);
      });

      test('creates instance with messages and data', () {
        final message = Message(
          id: '123',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25),
        );

        final conversation = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [message],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {
            'data-1': LoadedData(
                id: 'data-1',
                type: DataSourceType.file,
                rowCount: 10,
                columns: [],
                data: [],
                loadedAt: DateTime(2026, 1, 25))
          },
          charts: {},
          totalInputTokens: 100,
          totalOutputTokens: 200,
          estimatedCostUsd: 0.005,
        );

        expect(conversation.messages.length, equals(1));
        expect(conversation.dataStore.length, equals(1));
        expect(conversation.totalInputTokens, equals(100));
        expect(conversation.totalOutputTokens, equals(200));
        expect(conversation.estimatedCostUsd, equals(0.005));
      });

      test('throws assertion error when id is not UUID v4 format', () {
        expect(
          () => Conversation(
            id: 'invalid-uuid',
            messages: [],
            createdAt: DateTime(2026, 1, 25),
            dataStore: {},
            charts: {},
            totalInputTokens: 0,
            totalOutputTokens: 0,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when token counts are negative', () {
        expect(
          () => Conversation(
            id: '550e8400-e29b-41d4-a716-446655440000',
            messages: [],
            createdAt: DateTime(2026, 1, 25),
            dataStore: {},
            charts: {},
            totalInputTokens: -1,
            totalOutputTokens: 0,
          ),
          throwsAssertionError,
        );

        expect(
          () => Conversation(
            id: '550e8400-e29b-41d4-a716-446655440000',
            messages: [],
            createdAt: DateTime(2026, 1, 25),
            dataStore: {},
            charts: {},
            totalInputTokens: 0,
            totalOutputTokens: -1,
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final conversation = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 100,
          totalOutputTokens: 200,
          estimatedCostUsd: 0.005,
        );

        final json = conversation.toJson();

        expect(json['id'], equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(json['messages'], isA<List>());
        expect(json['dataStore'], isA<Map>());
        expect(json['charts'], isA<Map>());
        expect(json['totalInputTokens'], equals(100));
        expect(json['totalOutputTokens'], equals(200));
        expect(json['estimatedCostUsd'], equals(0.005));
      });

      test('fromJson creates instance from map', () {
        final json = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'messages': [],
          'createdAt': '2026-01-25T00:00:00.000',
          'dataStore': {},
          'charts': {},
          'totalInputTokens': 100,
          'totalOutputTokens': 200,
          'estimatedCostUsd': 0.005,
        };

        final conversation = Conversation.fromJson(json);

        expect(conversation.id, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(conversation.messages, isEmpty);
        expect(conversation.totalInputTokens, equals(100));
        expect(conversation.totalOutputTokens, equals(200));
        expect(conversation.estimatedCostUsd, equals(0.005));
      });

      test('JSON round-trip preserves data', () {
        final original = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 150,
          totalOutputTokens: 300,
          estimatedCostUsd: 0.0075,
        );

        final json = original.toJson();
        final restored = Conversation.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.totalInputTokens, equals(original.totalInputTokens));
        expect(restored.totalOutputTokens, equals(original.totalOutputTokens));
        expect(restored.estimatedCostUsd, equals(original.estimatedCostUsd));
      });
    });

    group('validation', () {
      test('validates UUID v4 format correctly', () {
        // Valid UUID v4
        expect(
          () => Conversation(
            id: '550e8400-e29b-41d4-a716-446655440000',
            messages: [],
            createdAt: DateTime(2026, 1, 25),
            dataStore: {},
            charts: {},
            totalInputTokens: 0,
            totalOutputTokens: 0,
          ),
          returnsNormally,
        );

        // Invalid formats
        expect(
          () => Conversation(
            id: 'not-a-uuid',
            messages: [],
            createdAt: DateTime(2026, 1, 25),
            dataStore: {},
            charts: {},
            totalInputTokens: 0,
            totalOutputTokens: 0,
          ),
          throwsAssertionError,
        );

        expect(
          () => Conversation(
            id: '550e8400e29b41d4a716446655440000', // Missing hyphens
            messages: [],
            createdAt: DateTime(2026, 1, 25),
            dataStore: {},
            charts: {},
            totalInputTokens: 0,
            totalOutputTokens: 0,
          ),
          throwsAssertionError,
        );
      });

      test('ensures messages are ordered by timestamp', () {
        final msg1 = Message(
          id: '1',
          role: MessageRole.user,
          textContent: 'First',
          timestamp: DateTime(2026, 1, 25, 10, 0),
        );
        final msg2 = Message(
          id: '2',
          role: MessageRole.assistant,
          textContent: 'Second',
          timestamp: DateTime(2026, 1, 25, 10, 1),
        );

        final conversation = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [msg1, msg2],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 0,
          totalOutputTokens: 0,
        );

        expect(
            conversation.messages[0].timestamp
                .isBefore(conversation.messages[1].timestamp),
            isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated token counts', () {
        final original = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 100,
          totalOutputTokens: 200,
        );

        final copy = original.copyWith(
          totalInputTokens: 150,
          totalOutputTokens: 250,
        );

        expect(copy.id, equals(original.id));
        expect(copy.totalInputTokens, equals(150));
        expect(copy.totalOutputTokens, equals(250));
      });

      test('creates copy with updated messages', () {
        final original = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 0,
          totalOutputTokens: 0,
        );

        final newMessage = Message(
          id: '1',
          role: MessageRole.user,
          textContent: 'Hello',
          timestamp: DateTime(2026, 1, 25),
        );

        final copy = original.copyWith(
          messages: [newMessage],
        );

        expect(copy.messages.length, equals(1));
        expect(original.messages.length, equals(0));
      });
    });

    group('equality', () {
      test('equal instances have same hash code', () {
        final conv1 = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 100,
          totalOutputTokens: 200,
        );

        final conv2 = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 100,
          totalOutputTokens: 200,
        );

        expect(conv1, equals(conv2));
        expect(conv1.hashCode, equals(conv2.hashCode));
      });

      test('different ids produce different instances', () {
        final conv1 = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440000',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 0,
          totalOutputTokens: 0,
        );

        final conv2 = Conversation(
          id: '550e8400-e29b-41d4-a716-446655440001',
          messages: [],
          createdAt: DateTime(2026, 1, 25),
          dataStore: {},
          charts: {},
          totalInputTokens: 0,
          totalOutputTokens: 0,
        );

        expect(conv1, isNot(equals(conv2)));
      });
    });
  });
}
