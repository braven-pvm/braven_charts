// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T069: Integration tests for stream error handling.
///
/// Tests onStreamError callback invocation when stream errors occur (FR-017a).
///
/// **Test Scenarios**:
/// 1. onStreamError callback invoked immediately on stream error
/// 2. Chart continues functioning after stream error (no crash)
/// 3. Multiple stream errors handled correctly
/// 4. Stream error during streaming mode
/// 5. Stream error during interactive mode
///
/// **Clarification Q2**: No automatic retry on stream errors - just invoke callback
///
/// NOTE: These tests are written BEFORE implementation (TDD approach)
/// and MUST FAIL until stream error handling is implemented.
void main() {
  group('T069: Stream Error Integration Tests', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    final List<Object> capturedErrors = [];

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      capturedErrors.clear();
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
    });

    testWidgets('T069: onStreamError callback invoked immediately on stream error (FR-017a)', (WidgetTester tester) async {
      // Arrange: Create chart with error callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onStreamError: (error) {
                  capturedErrors.add(error);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add some valid data first
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Add error to stream
      final testError = Exception('Test stream error');
      streamController.addError(testError);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Verify error callback invoked
      expect(capturedErrors.length, equals(1), reason: 'Error callback should be invoked once');
      expect(capturedErrors.first, equals(testError), reason: 'Captured error should match thrown error');

      // Verify chart still renders (no crash)
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Chart should not crash on stream error');
    });

    testWidgets('T069: Chart continues functioning after stream error', (WidgetTester tester) async {
      // Arrange: Create chart with error callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onStreamError: (error) {
                  capturedErrors.add(error);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Add valid data, then error, then more valid data
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      streamController.addError(Exception('Test error 1'));
      await tester.pump(const Duration(milliseconds: 100));

      streamController.add(const ChartDataPoint(x: 1.0, y: 10.0));
      await tester.pump(const Duration(milliseconds: 100));

      streamController.add(const ChartDataPoint(x: 2.0, y: 20.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Error captured but chart still functioning
      expect(capturedErrors.length, equals(1), reason: 'Error should be captured');
      expect(find.byType(BravenChart), findsOneWidget, reason: 'Chart should still render');
      expect(tester.takeException(), isNull, reason: 'No exceptions should propagate');
    });

    testWidgets('T069: Multiple stream errors handled correctly', (WidgetTester tester) async {
      // Arrange: Create chart with error callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onStreamError: (error) {
                  capturedErrors.add(error);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Add multiple errors
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      final error1 = Exception('Error 1');
      streamController.addError(error1);
      await tester.pump(const Duration(milliseconds: 100));

      streamController.add(const ChartDataPoint(x: 1.0, y: 10.0));
      await tester.pump(const Duration(milliseconds: 100));

      final error2 = Exception('Error 2');
      streamController.addError(error2);
      await tester.pump(const Duration(milliseconds: 100));

      final error3 = Exception('Error 3');
      streamController.addError(error3);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: All errors captured
      expect(capturedErrors.length, equals(3), reason: 'All 3 errors should be captured');
      expect(capturedErrors[0], equals(error1));
      expect(capturedErrors[1], equals(error2));
      expect(capturedErrors[2], equals(error3));
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T069: Stream error during streaming mode', (WidgetTester tester) async {
      // Arrange: Create chart in streaming mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onStreamError: (error) {
                  capturedErrors.add(error);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're in streaming mode
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Add error while in streaming mode
      final testError = Exception('Streaming mode error');
      streamController.addError(testError);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Error handled without mode change
      expect(capturedErrors.length, equals(1));
      expect(capturedErrors.first, equals(testError));
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T069: Stream error during interactive mode', (WidgetTester tester) async {
      // Arrange: Create chart and switch to interactive mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onStreamError: (error) {
                  capturedErrors.add(error);
                },
              ),
              interactionConfig: const InteractionConfig(
                enabled: true,
                crosshair: CrosshairConfig(enabled: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to interactive mode
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Act: Add error while in interactive mode
      final testError = Exception('Interactive mode error');
      streamController.addError(testError);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Error handled, data should be buffered
      expect(capturedErrors.length, equals(1));
      expect(capturedErrors.first, equals(testError));
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T069: No callback when onStreamError not provided', (WidgetTester tester) async {
      // Arrange: Create chart WITHOUT error callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                  // No onStreamError callback
                  ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Add error to stream
      streamController.addError(Exception('Test error'));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Chart should handle error gracefully (no crash)
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Chart should handle missing callback gracefully');
    });
  });
}
