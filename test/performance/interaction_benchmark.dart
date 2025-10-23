// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance benchmark for T027: Interaction Response Time (User Story 2).
///
/// Tests that mode transitions and interaction responses meet <16ms target (SC-004, FR-019).
///
/// **Performance Criteria** (from spec.md):
/// - **SC-004**: Chart responds to interactions within <16ms (60fps)
/// - **FR-019**: Smooth zoom/pan without dropped frames
///
/// **Test Scenarios**:
/// 1. Pause on hover response time (<16ms)
/// 2. Pause on zoom response time (<16ms)
/// 3. Pause on pan response time (<16ms)
/// 4. Mode transition overhead (<50ms per SC-006)
void main() {
  group('T027: Interaction Response Benchmark', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
    });

    testWidgets('Pause on hover completes within 16ms (SC-004)', (WidgetTester tester) async {
      ChartMode? modeAfterHover;
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  stopwatch.stop();
                  modeAfterHover = mode;
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

      // Add data to make chart interactive
      for (int i = 0; i < 20; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Start timing just before hover
      final chartFinder = find.byType(BravenChart);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      stopwatch.start();
      await gesture.moveTo(tester.getCenter(chartFinder));
      await tester.pump(); // Process hover event

      // Verify mode changed and timing
      expect(modeAfterHover, ChartMode.interactive);
      expect(stopwatch.elapsedMilliseconds, lessThan(16), reason: 'Pause on hover should complete within 16ms (SC-004)');

      print('⏱️ Hover response time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Pause on zoom completes within 16ms (SC-004)', (WidgetTester tester) async {
      ChartMode? modeAfterZoom;
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  stopwatch.stop();
                  modeAfterZoom = mode;
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

      // Add data
      for (int i = 0; i < 20; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      final chartFinder = find.byType(BravenChart);

      // Start timing just before zoom
      stopwatch.start();
      await tester.startGesture(tester.getCenter(chartFinder));
      await tester.pump(); // Process zoom start

      // Verify mode changed and timing
      expect(modeAfterZoom, ChartMode.interactive);
      expect(stopwatch.elapsedMilliseconds, lessThan(16), reason: 'Pause on zoom should complete within 16ms (SC-004)');

      print('⏱️ Zoom response time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Pause on pan completes within 16ms (SC-004)', (WidgetTester tester) async {
      ChartMode? modeAfterPan;
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  stopwatch.stop();
                  modeAfterPan = mode;
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

      // Add data
      for (int i = 0; i < 20; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();
      await tester.pumpAndSettle();

      final chartFinder = find.byType(BravenChart);

      // Start timing just before pan
      stopwatch.start();
      await tester.drag(chartFinder, const Offset(50, 0));
      await tester.pump(); // Process pan event

      // Verify mode changed and timing
      expect(modeAfterPan, ChartMode.interactive);
      expect(stopwatch.elapsedMilliseconds, lessThan(16), reason: 'Pause on pan should complete within 16ms (SC-004)');

      print('⏱️ Pan response time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Mode transition overhead is minimal (<50ms per SC-006)', (WidgetTester tester) async {
      int? transitionTime;
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(
                onModeChanged: (mode) {
                  // Only capture streaming → interactive transition
                  if (mode == ChartMode.interactive && transitionTime == null) {
                    stopwatch.stop();
                    transitionTime = stopwatch.elapsedMilliseconds;
                  }
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

      await tester.pump();

      // Add data
      for (int i = 0; i < 20; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      final chartFinder = find.byType(BravenChart);

      // Measure mode transition time
      stopwatch.start();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(chartFinder));
      await tester.pump();

      // Verify transition was captured and fast
      expect(transitionTime, isNotNull, reason: 'Mode transition should have occurred');
      expect(transitionTime!, lessThan(50), reason: 'Mode transition should complete within 50ms (SC-006)');

      print('⏱️ Mode transition time: ${transitionTime}ms');
    });

    testWidgets('Interaction response maintains 60fps with streaming data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: const [],
              dataStream: streamController.stream,
              streamingConfig: StreamingConfig(),
              controller: chartController,
              interactionConfig: const InteractionConfig(
                enabled: true,
                crosshair: CrosshairConfig(enabled: true),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Add initial data to simulate streaming
      for (int i = 0; i < 50; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Measure hover response with data already present (simulates streaming scenario)
      final stopwatch = Stopwatch();
      final chartFinder = find.byType(BravenChart);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      stopwatch.start();
      await gesture.moveTo(tester.getCenter(chartFinder));
      await tester.pump();
      stopwatch.stop();

      // Response should still be fast even with streaming data
      expect(stopwatch.elapsedMilliseconds, lessThan(16), reason: 'Interaction response should be <16ms even during streaming');

      print('⏱️ Hover response during streaming: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
