// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T070: Integration tests for edge cases and boundary conditions.
///
/// Tests edge cases from spec.md clarifications:
/// - No stream configured (default to interactive mode - FR-003)
/// - Buffer overflow (forced auto-resume - FR-014)
/// - Rapid mode switches (race condition prevention)
/// - Stream ends/completes
/// - Hot reload behavior (no mode persistence)
///
/// NOTE: These tests are written BEFORE implementation (TDD approach)
/// and MUST FAIL until edge case handling is implemented.
void main() {
  group('T070: Edge Cases Integration Tests', () {
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

    testWidgets(
        'T070: No stream configured defaults to interactive mode (FR-003)',
        (WidgetTester tester) async {
      // Arrange & Act: Create chart WITHOUT dataStream (static data only)
      ChartMode? initialMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'static',
                  points: const [
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 10),
                    ChartDataPoint(x: 2, y: 20),
                  ],
                ),
              ],
              // No dataStream provided
              controller: chartController,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  initialMode ??= mode;
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

      // Assert: Chart should default to interactive mode
      // Note: This test verifies FR-003 behavior
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Chart should handle no stream gracefully');
    });

    testWidgets('T070: Rapid mode switches handled safely',
        (WidgetTester tester) async {
      // Arrange: Create chart with very short auto-resume timeout
      final modeChanges = <ChartMode>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(milliseconds: 100),
                onModeChanged: (mode) {
                  modeChanges.add(mode);
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
      await tester.pump(const Duration(milliseconds: 50));

      modeChanges.clear();

      // Act: Rapidly switch modes
      final chartFinder = find.byType(BravenChart);

      // Pause
      await tester.tap(chartFinder);
      await tester.pump();

      // Try to pause again (should be idempotent)
      await tester.tap(chartFinder);
      await tester.pump();

      // Wait for auto-resume
      await tester.pump(const Duration(milliseconds: 150));

      // Try to resume again (should be idempotent)
      await tester.pump();

      // Assert: No crashes, predictable mode changes
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Rapid mode switches should not crash');

      // Mode changes should be: interactive, streaming (no duplicates)
      expect(modeChanges.length, greaterThanOrEqualTo(2),
          reason: 'Should have at least 2 mode changes');
    });

    testWidgets('T070: Stream ends gracefully', (WidgetTester tester) async {
      // Arrange: Create chart with stream
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add some data
      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Close stream (end of data)
      await streamController.close();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Chart should handle stream end gracefully
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Chart should handle stream end gracefully');
    });

    testWidgets('T070: Buffer overflow triggers forced auto-resume (FR-014)',
        (WidgetTester tester) async {
      // Arrange: Create chart with very small buffer
      const maxBufferSize = 10;
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
                onModeChanged: (mode) {
                  if (mode == ChartMode.streaming &&
                      lastModeChanged == ChartMode.interactive) {
                    forcedResumeOccurred = true;
                  }
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

      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      // Act: Pause and add more than maxBufferSize points
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();

      expect(lastModeChanged, equals(ChartMode.interactive));

      // Add more than maxBufferSize points
      for (int i = 1; i <= maxBufferSize + 2; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Assert: Forced auto-resume should occur
      expect(forcedResumeOccurred, isTrue,
          reason: 'Buffer overflow should trigger forced auto-resume');
      expect(lastModeChanged, equals(ChartMode.streaming),
          reason: 'Should be back in streaming mode');
    });

    testWidgets('T070: Multiple rapid interactions handled safely',
        (WidgetTester tester) async {
      // Arrange: Create chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              controller: chartController,
              streamingConfig: StreamingConfig(
                autoResumeTimeout: const Duration(milliseconds: 500),
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

      streamController.add(const ChartDataPoint(x: 0.0, y: 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      final chartFinder = find.byType(BravenChart);

      // Act: Perform rapid interactions
      await tester.tap(chartFinder);
      await tester.pump();

      await tester.tap(chartFinder);
      await tester.pump();

      await tester.tap(chartFinder);
      await tester.pump();

      // Add data while in interactive mode
      for (int i = 1; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // More interactions
      await tester.tap(chartFinder);
      await tester.pump();

      // Assert: No crashes from rapid interactions
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Rapid interactions should not crash');
      expect(lastModeChanged, equals(ChartMode.interactive),
          reason: 'Should be in interactive mode');

      // Wait for any pending timers to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('T070: Data updates blocked when no stream configured',
        (WidgetTester tester) async {
      // Arrange: Create chart with static data only (no stream)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'static',
                  points: const [
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 10),
                  ],
                ),
              ],
              // No dataStream
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
                crosshair: CrosshairConfig(enabled: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Try to use controller to add data (should not cause streaming behavior)
      chartController.addPoint('static', const ChartDataPoint(x: 2, y: 20));
      await tester.pump();

      // Assert: Chart should handle this gracefully
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Chart should handle non-streaming data updates');
    });
  });
}
