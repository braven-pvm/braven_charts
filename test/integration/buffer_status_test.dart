// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T059: Integration tests for buffer status visibility (User Story 5).
///
/// Tests buffer status callbacks and overflow behavior (FR-013, FR-014, FR-016).
///
/// **Test Scenarios**:
/// 1. onBufferUpdated callback accuracy (count matches actual buffer size)
/// 2. Buffer full callback (forced auto-resume when FIFO overflow occurs)
/// 3. Buffer cleared callback (on resume)
/// 4. Multiple buffer updates with accurate counts
/// 5. Buffer update callback timing (synchronous with buffer add)
///
/// NOTE: These tests are written BEFORE implementation (TDD approach)
/// and MUST FAIL until buffer status functionality is implemented.
void main() {
  group('T059: Buffer Status Integration Tests', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    final List<int> bufferCounts = [];
    ChartMode? lastModeChanged;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      bufferCounts.clear();
      lastModeChanged = null;
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
    });

    testWidgets(
        'T059: onBufferUpdated callback provides accurate count (FR-016)',
        (WidgetTester tester) async {
      // Arrange: Create chart with buffer update callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onBufferUpdated: (count) {
                  bufferCounts.add(count);
                },
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

      // Add initial data to establish streaming mode
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Pause by clicking
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Verify we're in interactive mode
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Chart should be in interactive mode after click');

      // Clear buffer counts from any initial data
      bufferCounts.clear();

      // Add 10 data points while in interactive mode
      for (int i = 5; i < 15; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(
            milliseconds: 20)); // Allow stream throttle processing
      }

      // Assert: Verify callback invoked with accurate counts
      expect(bufferCounts.length, greaterThanOrEqualTo(10),
          reason: 'Callback should be invoked for each buffered point');

      // Verify counts are sequential (1, 2, 3, ..., 10)
      for (int i = 0; i < 10; i++) {
        expect(bufferCounts[i], equals(i + 1),
            reason: 'Buffer count should increment sequentially');
      }
    });

    testWidgets(
        'T060: Buffer full triggers forced auto-resume (FR-014, SC-005)',
        (WidgetTester tester) async {
      // Arrange: Create chart with small maxBufferSize for testing
      const maxBufferSize = 20;
      bool forcedResumeOccurred = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                maxBufferSize: maxBufferSize,
                onBufferUpdated: (count) {
                  bufferCounts.add(count);
                },
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  if (mode == ChartMode.streaming &&
                      bufferCounts.isNotEmpty &&
                      bufferCounts.last >= maxBufferSize) {
                    forcedResumeOccurred = true;
                  }
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

      // Act: Pause by clicking
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      // Verify we're in interactive mode
      expect(lastModeChanged, equals(ChartMode.interactive));

      bufferCounts.clear();
      lastModeChanged = null;

      // Add more than maxBufferSize points to trigger forced resume
      for (int i = 5; i < 5 + maxBufferSize + 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Assert: Verify forced auto-resume occurred
      expect(forcedResumeOccurred, isTrue,
          reason:
              'Chart should force auto-resume when buffer reaches maxBufferSize');
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Chart should be back in streaming mode after forced resume');
    });

    testWidgets('T059: Buffer cleared after resume',
        (WidgetTester tester) async {
      // Arrange: Create chart with buffer update callback
      int? lastBufferCount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(seconds: 1),
                onBufferUpdated: (count) {
                  lastBufferCount = count;
                },
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

      // Act: Pause by clicking
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      expect(lastModeChanged, equals(ChartMode.interactive));

      // Add data points to buffer
      for (int i = 5; i < 15; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Verify buffer has data
      expect(lastBufferCount, greaterThan(0),
          reason: 'Buffer should contain data after adding points');

      // Wait for auto-resume
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Assert: Verify mode changed back to streaming
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Chart should auto-resume to streaming mode');

      // Add more data after resume - buffer count should restart from 0 if we pause again
      lastBufferCount = null;
      await tester.tap(chartFinder);
      await tester.pump();

      expect(lastModeChanged, equals(ChartMode.interactive));

      streamController.add(const ChartDataPoint(x: 15.0, y: 150.0));
      await tester.pump(const Duration(milliseconds: 20));

      // Verify buffer restarted from 1 (not continuing from previous count)
      expect(lastBufferCount, equals(1),
          reason:
              'Buffer should be cleared after resume, count should restart from 1');
    });

    testWidgets('T059: Multiple buffer updates with accurate sequential counts',
        (WidgetTester tester) async {
      // Arrange: Create chart to test precise counting
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onBufferUpdated: (count) {
                  bufferCounts.add(count);
                },
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
      for (int i = 0; i < 3; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Pause and add data in bursts
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      bufferCounts.clear();

      // Burst 1: Add 5 points
      for (int i = 3; i < 8; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Burst 2: Add 3 more points
      for (int i = 8; i < 11; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Assert: Verify all counts are present and sequential
      expect(bufferCounts.length, equals(8),
          reason: 'Should have 8 buffer update callbacks (5 + 3)');

      for (int i = 0; i < bufferCounts.length; i++) {
        expect(bufferCounts[i], equals(i + 1),
            reason: 'Buffer count at index $i should be ${i + 1}');
      }
    });

    testWidgets('T059: Buffer update callback timing is synchronous',
        (WidgetTester tester) async {
      // Arrange: Create chart to verify callback timing
      final List<String> eventLog = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onBufferUpdated: (count) {
                  eventLog.add('buffer:$count');
                },
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  eventLog.add('mode:${mode.name}');
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

      eventLog.clear();

      // Act: Pause and add single point
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      streamController.add(const ChartDataPoint(x: 1.0, y: 10.0));
      await tester.pump(const Duration(milliseconds: 20));

      // Assert: Verify callback was invoked synchronously
      expect(eventLog, contains('buffer:1'),
          reason: 'Buffer callback should be invoked after adding point');
      expect(eventLog.indexOf('buffer:1'),
          greaterThan(eventLog.indexOf('mode:interactive')),
          reason:
              'Buffer callback should occur after mode change to interactive');
    });
  });
}
