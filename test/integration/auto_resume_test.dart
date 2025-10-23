// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T037: Integration tests for auto-resume functionality (User Story 3).
///
/// Tests automatic resume to streaming mode after timeout (FR-007, FR-008, FR-009).
///
/// **Test Scenarios**:
/// 1. Default 10-second timeout triggers auto-resume
/// 2. Custom timeout durations work correctly
/// 3. Timer resets on hover interaction
/// 4. Timer resets on click interaction
/// 5. Timer resets on pan interaction
/// 6. Timer resets on zoom interaction
/// 7. Buffered data applied on auto-resume
/// 8. Mode change callback invoked on auto-resume
///
/// NOTE: These tests are written BEFORE implementation (TDD approach)
/// and MUST FAIL until auto-resume functionality is implemented.
void main() {
  group('T037: Auto-Resume Integration Tests', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    ChartMode? lastModeChanged;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      lastModeChanged = null;
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
    });

    testWidgets('T037: Default 10-second timeout triggers auto-resume (FR-007, FR-009)',
        (WidgetTester tester) async {
      // Arrange: Create chart with default auto-resume timeout (10 seconds)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                // NOTE: autoResumeTimeout not specified, should default to 10 seconds
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Pause by clicking
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Verify we're in interactive mode
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Click should pause streaming');

      // Add data while paused (should buffer)
      streamController.add(ChartDataPoint(x: 5.0, y: 50.0));
      await tester.pump();

      // Wait for default 10-second timeout (plus small buffer for safety)
      await tester.pump(const Duration(seconds: 10, milliseconds: 100));

      // Assert: Chart should auto-resume to streaming mode
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Chart should auto-resume after 10s timeout (FR-009)');
    });

    testWidgets('T037: Custom auto-resume timeout works correctly (FR-007)',
        (WidgetTester tester) async {
      // Arrange: Create chart with custom 3-second timeout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 3),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Pause by clicking
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      expect(lastModeChanged, equals(ChartMode.interactive));

      // Wait LESS than timeout (should NOT resume)
      await tester.pump(const Duration(seconds: 2));
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Should still be interactive before timeout');

      // Wait for remaining timeout duration (plus buffer)
      await tester.pump(const Duration(seconds: 1, milliseconds: 100));

      // Assert: Should auto-resume after custom 3s timeout
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Chart should auto-resume after custom 3s timeout (FR-007)');
    });

    testWidgets('T037: Timer resets on hover interaction (FR-008)',
        (WidgetTester tester) async {
      // Arrange: Create chart with 3-second timeout for faster testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 3),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Pause with click
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait 2 seconds (less than 3s timeout)
      await tester.pump(const Duration(seconds: 2));
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Should be interactive before timeout');

      // NOTE: Hover does NOT pause per commit 2351a91, but it SHOULD reset timer (FR-008)
      // Perform hover interaction to reset timer
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(chartFinder));
      await tester.pump();

      // Wait another 2 seconds (total 4s elapsed, but timer should have reset at 2s mark)
      await tester.pump(const Duration(seconds: 2));

      // Assert: Should STILL be interactive (timer was reset by hover)
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Timer should reset on hover interaction (FR-008)');

      // Wait for full timeout from last interaction
      await tester.pump(const Duration(seconds: 1, milliseconds: 100));

      // Now should auto-resume
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Should auto-resume after reset timer expires');
    });

    testWidgets('T037: Timer resets on click interaction (FR-008)',
        (WidgetTester tester) async {
      // Arrange: Create chart with 3-second timeout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 3),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Initial pause with click
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Perform another click to reset timer
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait another 2 seconds (total 4s, but timer reset at 2s mark)
      await tester.pump(const Duration(seconds: 2));

      // Assert: Should STILL be interactive (timer reset)
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Timer should reset on click interaction (FR-008)');
    });

    testWidgets('T037: Timer resets on pan interaction (FR-008)',
        (WidgetTester tester) async {
      // Arrange: Create chart with 3-second timeout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 3),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Pause with click
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Perform pan gesture to reset timer
      await tester.drag(chartFinder, const Offset(-100, 0));
      await tester.pumpAndSettle();

      // Wait another 2 seconds (timer should have reset)
      await tester.pump(const Duration(seconds: 2));

      // Assert: Should STILL be interactive (timer reset by pan)
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Timer should reset on pan interaction (FR-008)');
    });

    testWidgets('T037: Timer resets on zoom interaction (FR-008)',
        (WidgetTester tester) async {
      // Arrange: Create chart with 3-second timeout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 3),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Pause with click
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Perform zoom gesture (pinch)
      final center = tester.getCenter(chartFinder);
      final gesture1 = await tester.startGesture(center - const Offset(50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));
      await gesture1.moveTo(center - const Offset(100, 0));
      await gesture2.moveTo(center + const Offset(100, 0));
      await tester.pump();
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Wait another 2 seconds (timer should have reset)
      await tester.pump(const Duration(seconds: 2));

      // Assert: Should STILL be interactive (timer reset by zoom)
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Timer should reset on zoom interaction (FR-008)');
    });

    testWidgets('T037: Buffered data applied on auto-resume (User Story 3, scenario 2)',
        (WidgetTester tester) async {
      // Arrange: Create chart with 2-second timeout for faster testing
      int bufferCallbackCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 2),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                },
                onBufferUpdated: (count) {
                  bufferCallbackCount = count;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Get initial point count from controller
      final pointCountBeforePause = chartController.getAllSeries()['line']?.length ?? 0;

      // Act: Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Add multiple data points while paused (these should buffer)
      streamController.add(ChartDataPoint(x: 5.0, y: 50.0));
      await tester.pump();
      streamController.add(ChartDataPoint(x: 6.0, y: 60.0));
      await tester.pump();
      streamController.add(ChartDataPoint(x: 7.0, y: 70.0));
      await tester.pump();

      // Verify data is buffered, not visible
      final pointCountWhilePaused = chartController.getAllSeries()['line']?.length ?? 0;
      expect(pointCountWhilePaused, equals(pointCountBeforePause),
          reason: 'Points should buffer without visual update');
      expect(bufferCallbackCount, greaterThanOrEqualTo(1),
          reason: 'Buffer callback should track buffered points');

      // Wait for auto-resume timeout
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));

      // Assert: Buffered data should now be visible
      final pointCountAfterResume = chartController.getAllSeries()['line']?.length ?? 0;
      expect(pointCountAfterResume, greaterThan(pointCountBeforePause),
          reason: 'Buffered points should be applied on auto-resume');
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Should be in streaming mode after auto-resume');
    });

    testWidgets('T037: Mode change callback invoked on auto-resume (User Story 3, scenario 5)',
        (WidgetTester tester) async {
      // Arrange: Create chart with mode change callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 2),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
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

      // Add initial data
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Pause (callback should fire with interactive mode)
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Callback should fire when entering interactive mode');

      // Wait for auto-resume
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));

      // Assert: Callback should fire with streaming mode
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Callback should fire when auto-resuming to streaming mode (FR-009)');
    });
  });
}
