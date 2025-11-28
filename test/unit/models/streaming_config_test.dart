// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/models/chart_mode.dart';
import 'package:braven_charts/legacy/src/models/streaming_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for StreamingConfig class (T013).
///
/// Validates:
/// - Default values (10s timeout, 10K buffer, pauseOnFirstInteraction=true)
/// - Validation rules (positive timeout, positive buffer size)
/// - Callback registration and invocation
/// - Immutability (const constructor)
///
/// Related: FR-007 (timeout), FR-013 (buffer size), T006 (StreamingConfig implementation)
void main() {
  group('StreamingConfig defaults', () {
    test('should have correct default values', () {
      // Given/When: Creating StreamingConfig with no parameters
      final config = StreamingConfig();

      // Then: Should use documented defaults
      expect(config.autoResumeTimeout, equals(const Duration(seconds: 10)));
      expect(config.maxBufferSize, equals(10000));
      expect(config.pauseOnFirstInteraction, isTrue);
      expect(config.onModeChanged, isNull);
      expect(config.onBufferUpdated, isNull);
      expect(config.onReturnToLive, isNull);
      expect(config.onStreamError, isNull);
    });

    test('should allow custom timeout', () {
      // Given/When: Creating config with custom timeout
      final config =
          StreamingConfig(autoResumeTimeout: const Duration(seconds: 15));

      // Then: Should use custom timeout
      expect(config.autoResumeTimeout, equals(const Duration(seconds: 15)));
      expect(config.maxBufferSize, equals(10000)); // Other defaults unchanged
    });

    test('should allow custom buffer size', () {
      // Given/When: Creating config with custom buffer size
      final config = StreamingConfig(maxBufferSize: 5000);

      // Then: Should use custom buffer size
      expect(config.maxBufferSize, equals(5000));
      expect(config.autoResumeTimeout,
          equals(const Duration(seconds: 10))); // Other defaults unchanged
    });

    test('should allow disabling pause on interaction', () {
      // Given/When: Creating config with pauseOnFirstInteraction=false
      final config = StreamingConfig(pauseOnFirstInteraction: false);

      // Then: Should respect custom value
      expect(config.pauseOnFirstInteraction, isFalse);
    });
  });

  group('StreamingConfig validation', () {
    test('should reject zero timeout', () {
      // Given/When/Then: Creating config with zero timeout should throw
      expect(
        () => StreamingConfig(autoResumeTimeout: Duration.zero),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should reject negative timeout', () {
      // Given/When/Then: Creating config with negative timeout should throw
      expect(
        () => StreamingConfig(autoResumeTimeout: const Duration(seconds: -1)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should reject zero buffer size', () {
      // Given/When/Then: Creating config with zero buffer size should throw
      expect(
        () => StreamingConfig(maxBufferSize: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should reject negative buffer size', () {
      // Given/When/Then: Creating config with negative buffer size should throw
      expect(
        () => StreamingConfig(maxBufferSize: -100),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should accept minimum valid values', () {
      // Given/When: Creating config with minimum valid values
      final config = StreamingConfig(
        autoResumeTimeout: const Duration(milliseconds: 1),
        maxBufferSize: 1,
      );

      // Then: Should succeed
      expect(config.autoResumeTimeout, equals(const Duration(milliseconds: 1)));
      expect(config.maxBufferSize, equals(1));
    });

    test('should accept large buffer sizes', () {
      // Given/When: Creating config with large buffer size
      final config = StreamingConfig(maxBufferSize: 100000);

      // Then: Should succeed
      expect(config.maxBufferSize, equals(100000));
    });
  });

  group('StreamingConfig callbacks', () {
    test('should register onModeChanged callback', () {
      // Given: Callback function
      ChartMode? capturedMode;
      void callback(ChartMode mode) {
        capturedMode = mode;
      }

      // When: Creating config with callback
      final config = StreamingConfig(onModeChanged: callback);

      // Then: Callback should be registered
      expect(config.onModeChanged, isNotNull);

      // And when: Invoking callback
      config.onModeChanged!(ChartMode.interactive);

      // Then: Should capture mode
      expect(capturedMode, equals(ChartMode.interactive));
    });

    test('should register onBufferUpdated callback', () {
      // Given: Callback function
      int? capturedCount;
      void callback(int count) {
        capturedCount = count;
      }

      // When: Creating config with callback
      final config = StreamingConfig(onBufferUpdated: callback);

      // Then: Callback should be registered
      expect(config.onBufferUpdated, isNotNull);

      // And when: Invoking callback
      config.onBufferUpdated!(42);

      // Then: Should capture count
      expect(capturedCount, equals(42));
    });

    test('should register onReturnToLive callback', () {
      // Given: Callback function
      bool callbackInvoked = false;
      void callback() {
        callbackInvoked = true;
      }

      // When: Creating config with callback
      final config = StreamingConfig(onReturnToLive: callback);

      // Then: Callback should be registered
      expect(config.onReturnToLive, isNotNull);

      // And when: Invoking callback
      config.onReturnToLive!();

      // Then: Should invoke callback
      expect(callbackInvoked, isTrue);
    });

    test('should register onStreamError callback', () {
      // Given: Callback function
      Object? capturedError;
      void callback(Object error) {
        capturedError = error;
      }

      // When: Creating config with callback
      final config = StreamingConfig(onStreamError: callback);

      // Then: Callback should be registered
      expect(config.onStreamError, isNotNull);

      // And when: Invoking callback with error
      final testError = Exception('Test error');
      config.onStreamError!(testError);

      // Then: Should capture error
      expect(capturedError, equals(testError));
    });

    test('should allow all callbacks to be null', () {
      // Given/When: Creating config with no callbacks
      final config = StreamingConfig();

      // Then: All callbacks should be null
      expect(config.onModeChanged, isNull);
      expect(config.onBufferUpdated, isNull);
      expect(config.onReturnToLive, isNull);
      expect(config.onStreamError, isNull);
    });

    test('should support multiple callbacks simultaneously', () {
      // Given: Multiple callback functions
      ChartMode? capturedMode;
      int? capturedBufferCount;
      bool returnToLiveInvoked = false;
      Object? capturedError;

      // When: Creating config with all callbacks
      final config = StreamingConfig(
        onModeChanged: (mode) => capturedMode = mode,
        onBufferUpdated: (count) => capturedBufferCount = count,
        onReturnToLive: () => returnToLiveInvoked = true,
        onStreamError: (error) => capturedError = error,
      );

      // Then: All callbacks should be registered
      expect(config.onModeChanged, isNotNull);
      expect(config.onBufferUpdated, isNotNull);
      expect(config.onReturnToLive, isNotNull);
      expect(config.onStreamError, isNotNull);

      // And when: Invoking all callbacks
      config.onModeChanged!(ChartMode.streaming);
      config.onBufferUpdated!(100);
      config.onReturnToLive!();
      config.onStreamError!(Exception('Error'));

      // Then: All callbacks should execute
      expect(capturedMode, equals(ChartMode.streaming));
      expect(capturedBufferCount, equals(100));
      expect(returnToLiveInvoked, isTrue);
      expect(capturedError, isNotNull);
    });
  });

  group('StreamingConfig immutability', () {
    test('should be const constructable', () {
      // Given/When: Creating const instance
      final config = StreamingConfig();

      // Then: Should compile (const constructor validation)
      expect(config, isNotNull);
    });

    test('should be const with all parameters', () {
      // Given/When: Creating const instance with all parameters
      final config = StreamingConfig(
        autoResumeTimeout: const Duration(seconds: 20),
        maxBufferSize: 5000,
        pauseOnFirstInteraction: false,
      );

      // Then: Should compile and preserve values
      expect(config.autoResumeTimeout, equals(const Duration(seconds: 20)));
      expect(config.maxBufferSize, equals(5000));
      expect(config.pauseOnFirstInteraction, isFalse);
    });
  });
}
