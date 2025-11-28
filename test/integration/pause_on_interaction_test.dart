// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for T025: Pause on Interaction (User Story 2).
///
/// Tests automatic pause on hover/click/zoom/pan (FR-004).
///
/// **Test Scenarios**:
/// 1. Chart starts in streaming mode
/// 2. Hover triggers pause to interactive mode
/// 3. Click triggers pause to interactive mode
/// 4. Zoom triggers pause to interactive mode
/// 5. Pan triggers pause to interactive mode
/// 6. Mode callbacks invoked correctly
void main() {
  group('T025: Pause on Interaction Tests', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    ChartMode? lastModeChanged;
    int modeChangeCount = 0;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      lastModeChanged = null;
      modeChangeCount = 0;
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
    });

    testWidgets('Chart starts in streaming mode with streamingConfig',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
              ),
              controller: chartController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial mode should be streaming
      expect(lastModeChanged, isNull); // No change yet, starts in streaming
      expect(modeChangeCount, 0);
    });

    testWidgets('Hover does NOT trigger pause (intentional UX decision)',
        (WidgetTester tester) async {
      // NOTE: Original spec FR-004 included hover, but during implementation this was
      // found to be too aggressive (accidental pauses from casual mouse movement).
      // Design decision: Only intentional interactions (click, zoom, pan) pause streaming.
      // See commit 2351a91: "Removed overly aggressive hover pause trigger"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
              ),
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

      // Add some data points first
      for (int i = 0; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Find the chart and hover over it
      final chartFinder = find.byType(BravenChart);
      expect(chartFinder, findsOneWidget);

      // Simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      final chartRect = tester.getRect(chartFinder);
      await gesture.moveTo(chartRect.center);
      await tester.pumpAndSettle();

      // Mode should NOT change (hover doesn't pause)
      expect(lastModeChanged, isNull);
      expect(modeChangeCount, 0);
    });

    testWidgets('Click triggers pause to interactive mode (FR-004)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
              ),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add some data
      for (int i = 0; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap the chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();

      // Mode should change to interactive
      expect(lastModeChanged, ChartMode.interactive);
      expect(modeChangeCount, 1);
    });

    testWidgets('Zoom triggers pause to interactive mode (FR-004)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
              ),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
                enableZoom: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add some data
      for (int i = 0; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Simulate zoom gesture
      final chartFinder = find.byType(BravenChart);

      await tester.startGesture(tester.getCenter(chartFinder));
      await tester.pumpAndSettle();

      // Mode should change to interactive when zoom starts
      expect(lastModeChanged, ChartMode.interactive);
      expect(modeChangeCount, 1);
    });

    testWidgets('Pan triggers pause to interactive mode (FR-004)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
              ),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
                enablePan: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add some data
      for (int i = 0; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Simulate pan gesture
      final chartFinder = find.byType(BravenChart);

      await tester.drag(chartFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Mode should change to interactive
      expect(lastModeChanged, ChartMode.interactive);
      expect(modeChangeCount, 1);
    });

    testWidgets('Multiple interactions do not trigger multiple mode changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
              ),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
                enableZoom: true,
                enablePan: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add data
      for (int i = 0; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      final chartFinder = find.byType(BravenChart);

      // First interaction - tap
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();
      expect(modeChangeCount, 1);
      expect(lastModeChanged, ChartMode.interactive);

      // Second interaction - pan (should not trigger another mode change)
      await tester.drag(chartFinder, const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(modeChangeCount, 1); // Still 1, no additional change

      // Third interaction - another tap
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();
      expect(modeChangeCount, 1); // Still 1, already in interactive mode
    });

    testWidgets(
        'T035: Data buffers silently without visual updates in interactive mode',
        (WidgetTester tester) async {
      int bufferUpdateCount = 0;
      int lastBufferCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  lastModeChanged = mode;
                  modeChangeCount++;
                },
                onBufferUpdated: (count) {
                  bufferUpdateCount++;
                  lastBufferCount = count;
                },
              ),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add initial data in streaming mode
      for (int i = 0; i < 5; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify initial state: streaming mode, no buffer updates
      expect(bufferUpdateCount, 0);
      expect(lastBufferCount, 0);

      // Pause by tapping
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();

      // Verify mode changed to interactive
      expect(lastModeChanged, ChartMode.interactive);
      expect(modeChangeCount, 1);

      // Get initial series data count (from controller)
      final allSeries = chartController.getAllSeries();
      final initialPointCount =
          allSeries.values.isEmpty ? 0 : allSeries.values.first.length;

      // Add data while in interactive mode (should buffer, not display)
      for (int i = 5; i < 15; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester
            .pump(const Duration(milliseconds: 10)); // Small delay to process
      }
      await tester.pumpAndSettle();

      // Verify buffer callback was invoked for each point
      expect(bufferUpdateCount, greaterThan(0),
          reason: 'Buffer should have been updated at least once');
      expect(lastBufferCount, greaterThan(0),
          reason: 'Buffer should contain at least 1 point');

      // Verify NO visual updates (point count unchanged in controller)
      final currentSeries = chartController.getAllSeries();
      final currentPointCount =
          currentSeries.values.isEmpty ? 0 : currentSeries.values.first.length;
      expect(currentPointCount, equals(initialPointCount),
          reason:
              'Buffered points should NOT appear in controller during interactive mode');

      // Verify buffer count is reasonable (may be less than 10 due to timing/throttling)
      expect(lastBufferCount, greaterThanOrEqualTo(1));
      expect(lastBufferCount, lessThanOrEqualTo(10));
    });

    testWidgets('T035: Buffering continues during zoom/pan interactions',
        (WidgetTester tester) async {
      int bufferUpdateCount = 0;
      int lastBufferCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onBufferUpdated: (count) {
                  bufferUpdateCount++;
                  lastBufferCount = count;
                },
              ),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
                enablePan: true,
                enableZoom: true,
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
      await tester.pumpAndSettle();

      final chartFinder = find.byType(BravenChart);

      // Trigger interactive mode with pan
      await tester.drag(chartFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Stream more data during interaction
      for (int i = 5; i < 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      // Verify buffer accumulated data
      expect(bufferUpdateCount, greaterThan(0),
          reason: 'Buffer should have been updated');
      expect(lastBufferCount, greaterThanOrEqualTo(1),
          reason: 'Buffer should contain at least 1 point');
      expect(lastBufferCount, lessThanOrEqualTo(5),
          reason: 'Buffer should not exceed streamed point count');

      // Continue interaction with another pan
      await tester.drag(chartFinder, const Offset(-30, 0));
      await tester.pumpAndSettle();

      final bufferCountAfterFirstPan = lastBufferCount;

      // Stream even more data
      for (int i = 10; i < 13; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      // Verify buffer continues to accumulate (should be more than after first pan)
      expect(lastBufferCount, greaterThan(bufferCountAfterFirstPan),
          reason:
              'Buffer should continue accumulating during continued interactions');
    });
  });
}
