// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/models/chart_mode.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for ChartMode enum (T012).
///
/// Validates:
/// - Enum has exactly 2 values (streaming, interactive)
/// - No null values allowed
/// - Values are distinct and non-nullable
///
/// Related: FR-001 (mutually exclusive modes), T005 (ChartMode implementation)
void main() {
  group('ChartMode enum tests', () {
    test('should have exactly 2 values', () {
      // Given: ChartMode enum
      // When: Getting all enum values
      final values = ChartMode.values;

      // Then: Should have exactly 2 values (streaming and interactive)
      expect(values, hasLength(2));
    });

    test('should have streaming value', () {
      // Given: ChartMode enum
      // When: Accessing streaming value
      final mode = ChartMode.streaming;

      // Then: Should not be null and should equal streaming
      expect(mode, isNotNull);
      expect(mode, equals(ChartMode.streaming));
      expect(mode.name, equals('streaming'));
    });

    test('should have interactive value', () {
      // Given: ChartMode enum
      // When: Accessing interactive value
      final mode = ChartMode.interactive;

      // Then: Should not be null and should equal interactive
      expect(mode, isNotNull);
      expect(mode, equals(ChartMode.interactive));
      expect(mode.name, equals('interactive'));
    });

    test('values should be distinct', () {
      // Given: ChartMode enum values
      // When: Comparing streaming and interactive
      final streaming = ChartMode.streaming;
      final interactive = ChartMode.interactive;

      // Then: Should be different values
      expect(streaming, isNot(equals(interactive)));
      expect(streaming.index, isNot(equals(interactive.index)));
    });

    test('should be non-nullable', () {
      // Given: ChartMode values
      // When: Assigning to non-nullable variables
      ChartMode mode1 = ChartMode.streaming;
      ChartMode mode2 = ChartMode.interactive;

      // Then: Should compile and be non-null (compile-time check)
      expect(mode1, isNotNull);
      expect(mode2, isNotNull);
    });

    test('should support equality comparison', () {
      // Given: Multiple references to same mode
      // When: Comparing references
      final mode1 = ChartMode.streaming;
      final mode2 = ChartMode.streaming;

      // Then: Should be equal
      expect(mode1, equals(mode2));
      expect(mode1 == mode2, isTrue);
    });

    test('should support switch statements', () {
      // Given: ChartMode value
      // When: Using in switch statement
      String result = '';
      final mode = ChartMode.streaming;

      switch (mode) {
        case ChartMode.streaming:
          result = 'streaming';
          break;
        case ChartMode.interactive:
          result = 'interactive';
          break;
      }

      // Then: Should execute correct case
      expect(result, equals('streaming'));
    });

    test('should have correct enum indices', () {
      // Given: ChartMode values
      // When: Getting indices
      final streamingIndex = ChartMode.streaming.index;
      final interactiveIndex = ChartMode.interactive.index;

      // Then: Should have sequential indices starting at 0
      expect(streamingIndex, equals(0));
      expect(interactiveIndex, equals(1));
    });
  });
}
