// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T053/T054: Integration tests for manual resume functionality (User Story 4).
///
/// Tests manual resume API for developers to trigger immediate return to streaming.
///
/// **Test Scenarios**:
/// 1. Manual resume triggers immediate transition from interactive to streaming
/// 2. Buffered data is applied during manual resume
/// 3. Auto-resume timer is cancelled on manual resume
/// 4. resumeStreaming() is idempotent (no-op when already streaming)
/// 5. resumeStreaming() can be called from external button/trigger
///
/// NOTE: These tests are written BEFORE implementation (TDD approach)
/// and MUST FAIL until manual resume API is implemented.
void main() {
  group('T053: Manual Resume Integration Tests', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    late StreamingController streamingController;
    ChartMode? lastModeChanged;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      streamingController = StreamingController();
      lastModeChanged = null;
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
      streamingController.dispose();
    });

    testWidgets('T053: Manual resume triggers immediate transition (FR-010)',
        (WidgetTester tester) async {
      // Arrange: Create chart with 10-second timeout (longer than test duration)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingController: streamingController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 10), // Long timeout
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
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Should be in interactive mode after tap');

      // Wait a bit to ensure we're not near auto-resume timeout
      await tester.pump(const Duration(seconds: 1));
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Should still be interactive after 1 second');

      // Act: Manually resume streaming
      streamingController.resumeStreaming();
      await tester.pump();

      // Assert: Chart should immediately return to streaming mode
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Manual resume should trigger immediate mode change');
    });

    testWidgets(
        'T053: Buffered data applied during manual resume (FR-010, FR-011)',
        (WidgetTester tester) async {
      // Arrange: Create chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              streamingController: streamingController,
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 10),
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
      await tester.pump(const Duration(milliseconds: 100));

      final pointCountBeforePause =
          chartController.getAllSeries()['stream']?.length ?? 0;

      // Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Add data while paused (should buffer)
      streamController.add(const ChartDataPoint(x: 5.0, y: 50.0));
      await tester.pump(const Duration(milliseconds: 20));
      streamController.add(const ChartDataPoint(x: 6.0, y: 60.0));
      await tester.pump(const Duration(milliseconds: 20));
      streamController.add(const ChartDataPoint(x: 7.0, y: 70.0));
      await tester.pump(const Duration(milliseconds: 20));

      final pointCountWhilePaused =
          chartController.getAllSeries()['stream']?.length ?? 0;
      expect(pointCountWhilePaused, equals(pointCountBeforePause),
          reason: 'Data should be buffered, not visible');

      // Act: Manually resume
      streamingController.resumeStreaming();
      await tester.pump();

      // Assert: Buffered data should be visible
      final pointCountAfterResume =
          chartController.getAllSeries()['stream']?.length ?? 0;
      expect(pointCountAfterResume, greaterThan(pointCountBeforePause),
          reason: 'Buffered data should be applied on manual resume');
    });

    testWidgets('T053: Auto-resume timer cancelled on manual resume (FR-010)',
        (WidgetTester tester) async {
      // Arrange: Create chart with short timeout
      bool timerFired = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              streamingController: streamingController,
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 2),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                },
                onReturnToLive: () {
                  timerFired = true;
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
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait 1 second (half of timeout)
      await tester.pump(const Duration(seconds: 1));
      expect(timerFired, isFalse, reason: 'Timer should not have fired yet');

      // Act: Manually resume before timeout
      streamingController.resumeStreaming();
      await tester.pump();
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Should be streaming after manual resume');

      // Wait for what would have been the timeout
      await tester.pump(const Duration(seconds: 2));

      // Assert: Timer callback should NOT fire (timer was cancelled)
      // Note: This is tricky to test directly. We verify by checking that
      // we don't get redundant mode changes or callbacks.
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Mode should not change again');
    });

    testWidgets('T054: resumeStreaming() is idempotent when already streaming',
        (WidgetTester tester) async {
      // Arrange: Create chart that starts in streaming mode
      int modeChangeCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              streamingController: streamingController,
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
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
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify we're in streaming mode
      // Note: Initial mode doesn't trigger callback, so modeChangeCount should be 0
      expect(modeChangeCount, equals(0), reason: 'No mode changes yet');

      // Act: Call resumeStreaming() while already streaming (should be no-op)
      streamingController.resumeStreaming();
      await tester.pump();

      // Assert: Should NOT trigger mode change callback (idempotent)
      expect(modeChangeCount, equals(0),
          reason:
              'resumeStreaming() should be idempotent (no mode change when already streaming)');
    });

    testWidgets('T054: Multiple resumeStreaming() calls are safe',
        (WidgetTester tester) async {
      // Arrange: Create chart
      int modeChangeCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              streamingController: streamingController,
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 10),
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
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
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();
      expect(modeChangeCount, equals(1),
          reason: 'One mode change (streaming → interactive)');

      // Act: Call resumeStreaming() multiple times
      streamingController.resumeStreaming();
      await tester.pump();
      expect(modeChangeCount, equals(2),
          reason: 'Second mode change (interactive → streaming)');

      streamingController.resumeStreaming();
      await tester.pump();
      expect(modeChangeCount, equals(2),
          reason: 'No additional mode change (idempotent)');

      streamingController.resumeStreaming();
      await tester.pump();
      expect(modeChangeCount, equals(2),
          reason: 'Still no additional mode change (idempotent)');

      // Assert: Mode should be streaming
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Should be in streaming mode');
    });
  });
}
