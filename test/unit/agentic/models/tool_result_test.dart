// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 2

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/tool_call.dart';
import 'package:braven_charts/src/agentic/models/tool_result.dart';

@Tags(['tdd-red'])
void main() {
  group('ToolCall', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        final toolCall = ToolCall(
          id: 'call-123',
          toolName: 'create_chart',
          arguments: {'type': 'line', 'title': 'Sales Data'},
        );

        expect(toolCall.id, equals('call-123'));
        expect(toolCall.toolName, equals('create_chart'));
        expect(toolCall.arguments['type'], equals('line'));
        expect(toolCall.arguments['title'], equals('Sales Data'));
        expect(toolCall.result, isNull);
      });

      test('creates instance with nested arguments', () {
        final toolCall = ToolCall(
          id: 'call-456',
          toolName: 'load_data',
          arguments: {
            'source': 'file',
            'config': {
              'format': 'csv',
              'delimiter': ',',
            },
          },
        );

        expect(toolCall.arguments['source'], equals('file'));
        expect((toolCall.arguments['config'] as Map)['format'], equals('csv'));
      });

      test('creates instance with empty arguments', () {
        final toolCall = ToolCall(
          id: 'call-789',
          toolName: 'get_status',
          arguments: {},
        );

        expect(toolCall.arguments, isEmpty);
      });

      test('creates instance with associated result', () {
        final result = ToolResult(
          id: 'result-1',
          toolCallId: 'call-123',
          success: true,
          result: {'chartId': 'chart-abc'},
        );

        final toolCall = ToolCall(
          id: 'call-123',
          toolName: 'create_chart',
          arguments: {'type': 'line'},
          result: result,
        );

        expect(toolCall.result, isNotNull);
        expect(toolCall.result?.id, equals('result-1'));
        expect(toolCall.result?.toolCallId, equals('call-123'));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final toolCall = ToolCall(
          id: 'call-123',
          toolName: 'create_chart',
          arguments: {'type': 'bar'},
        );

        final json = toolCall.toJson();

        expect(json['id'], equals('call-123'));
        expect(json['toolName'], equals('create_chart'));
        expect(json['arguments'], isA<Map>());
        expect(json['arguments']['type'], equals('bar'));
      });

      test('fromJson creates instance from map', () {
        final json = {
          'id': 'call-456',
          'toolName': 'load_data',
          'arguments': {
            'source': 'url',
            'url': 'https://example.com/data.csv',
          },
        };

        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.id, equals('call-456'));
        expect(toolCall.toolName, equals('load_data'));
        expect(toolCall.arguments['source'], equals('url'));
      });

      test('JSON round-trip preserves data', () {
        final original = ToolCall(
          id: 'call-round-trip',
          toolName: 'analyze',
          arguments: {
            'metric': 'power',
            'threshold': 250,
            'includeZones': true,
          },
        );

        final json = original.toJson();
        final restored = ToolCall.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.toolName, equals(original.toolName));
        expect(
            restored.arguments['metric'], equals(original.arguments['metric']));
        expect(restored.arguments['threshold'],
            equals(original.arguments['threshold']));
        expect(restored.arguments['includeZones'],
            equals(original.arguments['includeZones']));
      });

      test('JSON serialization includes result if present', () {
        final result = ToolResult(
          id: 'result-1',
          toolCallId: 'call-123',
          success: true,
          result: {'data': 'value'},
        );

        final toolCall = ToolCall(
          id: 'call-123',
          toolName: 'tool',
          arguments: {},
          result: result,
        );

        final json = toolCall.toJson();

        expect(json['result'], isNotNull);
        expect(json['result']['id'], equals('result-1'));
      });
    });

    group('validation', () {
      test('tool name cannot be empty', () {
        expect(
          () => ToolCall(
            id: 'call-1',
            toolName: '',
            arguments: {},
          ),
          throwsAssertionError,
        );
      });

      test('id cannot be empty', () {
        expect(
          () => ToolCall(
            id: '',
            toolName: 'tool',
            arguments: {},
          ),
          throwsAssertionError,
        );
      });
    });

    group('equality', () {
      test('equal tool calls have same hash code', () {
        final call1 = ToolCall(
          id: 'call-123',
          toolName: 'create_chart',
          arguments: {'type': 'line'},
        );

        final call2 = ToolCall(
          id: 'call-123',
          toolName: 'create_chart',
          arguments: {'type': 'line'},
        );

        expect(call1, equals(call2));
        expect(call1.hashCode, equals(call2.hashCode));
      });

      test('different ids produce different instances', () {
        final call1 = ToolCall(
          id: 'call-123',
          toolName: 'tool',
          arguments: {},
        );

        final call2 = ToolCall(
          id: 'call-456',
          toolName: 'tool',
          arguments: {},
        );

        expect(call1, isNot(equals(call2)));
      });
    });
  });

  group('ToolResult', () {
    group('constructor', () {
      test('creates successful result with data', () {
        final result = ToolResult(
          id: 'result-123',
          toolCallId: 'call-456',
          success: true,
          result: {
            'chartId': 'chart-abc',
            'status': 'created',
          },
        );

        expect(result.id, equals('result-123'));
        expect(result.toolCallId, equals('call-456'));
        expect(result.success, isTrue);
        expect(result.result, isNotNull);
        expect(result.result?['chartId'], equals('chart-abc'));
        expect(result.error, isNull);
      });

      test('creates failed result with error', () {
        final result = ToolResult(
          id: 'result-789',
          toolCallId: 'call-999',
          success: false,
          error: 'Invalid data format',
        );

        expect(result.id, equals('result-789'));
        expect(result.toolCallId, equals('call-999'));
        expect(result.success, isFalse);
        expect(result.error, equals('Invalid data format'));
        expect(result.result, isNull);
      });

      test('creates result with both result and error (for warnings)', () {
        final result = ToolResult(
          id: 'result-warn',
          toolCallId: 'call-warn',
          success: true,
          result: {'data': 'processed'},
          error: 'Warning: some rows skipped',
        );

        expect(result.success, isTrue);
        expect(result.result, isNotNull);
        expect(result.error, isNotNull);
      });
    });

    group('JSON serialization', () {
      test('toJson converts successful result correctly', () {
        final result = ToolResult(
          id: 'result-123',
          toolCallId: 'call-456',
          success: true,
          result: {'chartId': 'chart-xyz'},
        );

        final json = result.toJson();

        expect(json['id'], equals('result-123'));
        expect(json['toolCallId'], equals('call-456'));
        expect(json['success'], isTrue);
        expect(json['result'], isA<Map>());
        expect(json['result']['chartId'], equals('chart-xyz'));
      });

      test('toJson converts failed result correctly', () {
        final result = ToolResult(
          id: 'result-fail',
          toolCallId: 'call-fail',
          success: false,
          error: 'File not found',
        );

        final json = result.toJson();

        expect(json['id'], equals('result-fail'));
        expect(json['success'], isFalse);
        expect(json['error'], equals('File not found'));
      });

      test('fromJson creates result from map', () {
        final json = {
          'id': 'result-456',
          'toolCallId': 'call-789',
          'success': true,
          'result': {'data': 'loaded'},
        };

        final result = ToolResult.fromJson(json);

        expect(result.id, equals('result-456'));
        expect(result.toolCallId, equals('call-789'));
        expect(result.success, isTrue);
        expect(result.result?['data'], equals('loaded'));
      });

      test('JSON round-trip preserves data', () {
        final original = ToolResult(
          id: 'result-round-trip',
          toolCallId: 'call-round-trip',
          success: true,
          result: {
            'metrics': {
              'np': 256,
              'if': 0.85,
            },
          },
        );

        final json = original.toJson();
        final restored = ToolResult.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.toolCallId, equals(original.toolCallId));
        expect(restored.success, equals(original.success));
        expect((restored.result?['metrics'] as Map)['np'], equals(256));
      });
    });

    group('validation', () {
      test('successful result should have result data or error', () {
        // Success with result is valid
        expect(
          () => ToolResult(
            id: 'result-1',
            toolCallId: 'call-1',
            success: true,
            result: {'data': 'value'},
          ),
          returnsNormally,
        );

        // Success with neither result nor error should fail
        expect(
          () => ToolResult(
            id: 'result-2',
            toolCallId: 'call-2',
            success: true,
          ),
          throwsAssertionError,
        );
      });

      test('failed result should have error message', () {
        // Failure with error is valid
        expect(
          () => ToolResult(
            id: 'result-1',
            toolCallId: 'call-1',
            success: false,
            error: 'Something went wrong',
          ),
          returnsNormally,
        );

        // Failure without error should fail
        expect(
          () => ToolResult(
            id: 'result-2',
            toolCallId: 'call-2',
            success: false,
          ),
          throwsAssertionError,
        );
      });

      test('id cannot be empty', () {
        expect(
          () => ToolResult(
            id: '',
            toolCallId: 'call-1',
            success: true,
            result: {},
          ),
          throwsAssertionError,
        );
      });

      test('toolCallId cannot be empty', () {
        expect(
          () => ToolResult(
            id: 'result-1',
            toolCallId: '',
            success: true,
            result: {},
          ),
          throwsAssertionError,
        );
      });
    });

    group('equality', () {
      test('equal results have same hash code', () {
        final result1 = ToolResult(
          id: 'result-123',
          toolCallId: 'call-456',
          success: true,
          result: {'data': 'value'},
        );

        final result2 = ToolResult(
          id: 'result-123',
          toolCallId: 'call-456',
          success: true,
          result: {'data': 'value'},
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('different ids produce different instances', () {
        final result1 = ToolResult(
          id: 'result-123',
          toolCallId: 'call-1',
          success: true,
          result: {},
        );

        final result2 = ToolResult(
          id: 'result-456',
          toolCallId: 'call-1',
          success: true,
          result: {},
        );

        expect(result1, isNot(equals(result2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated success status', () {
        final original = ToolResult(
          id: 'result-1',
          toolCallId: 'call-1',
          success: false,
          error: 'Initial error',
        );

        final copy = original.copyWith(
          success: true,
          result: {'fixed': true},
        );

        expect(copy.success, isTrue);
        expect(copy.result?['fixed'], isTrue);
        expect(original.success, isFalse);
      });
    });
  });
}
