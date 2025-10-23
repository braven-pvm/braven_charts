// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
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

    testWidgets('Hover triggers pause to interactive mode (FR-004)',
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
              interactionConfig: InteractionConfig(
                enabled: true,
                crosshair: const CrosshairConfig(enabled: true),
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

      // Simulate hover (this should trigger pause)
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      final chartRect = tester.getRect(chartFinder);
      await gesture.moveTo(chartRect.center);
      await tester.pumpAndSettle();

      // Mode should change to interactive
      expect(lastModeChanged, ChartMode.interactive);
      expect(modeChangeCount, 1);
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
              interactionConfig: InteractionConfig(
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
              interactionConfig: InteractionConfig(
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
              interactionConfig: InteractionConfig(
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
              interactionConfig: InteractionConfig(
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
  });
}
