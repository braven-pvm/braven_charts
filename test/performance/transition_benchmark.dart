// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T038 & T039: Performance benchmarks for mode transitions and buffer application.
///
/// Tests performance requirements:
/// - SC-002: Mode transitions must complete within 50ms (T038)
/// - SC-007: Applying 10K buffered points must complete within 500ms (T039)
///
/// **Test Scenarios**:
/// 1. Mode transition from streaming to interactive < 50ms (SC-002)
/// 2. Mode transition from interactive to streaming < 50ms (SC-002)
/// 3. Buffer application of 10K points < 500ms (SC-007)
/// 4. Combined transition + buffer application stays within limits
///
/// NOTE: These tests are written BEFORE implementation (TDD approach)
/// and MUST FAIL until auto-resume functionality is implemented.
void main() {
  group('T038: Mode Transition Benchmark', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    late Stopwatch stopwatch;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      stopwatch = Stopwatch();
    });

    tearDown(() {
      streamController.close();
      chartController.dispose();
    });

    testWidgets(
        'T038: Streaming → Interactive transition completes within 50ms (SC-002)',
        (WidgetTester tester) async {
      // Arrange: Create chart with streaming data
      ChartMode? lastMode;
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
                  lastMode = mode;
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
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Trigger transition to interactive mode and measure time
      final chartFinder = find.byType(BravenChart);
      stopwatch.start();
      await tester.tap(chartFinder);
      await tester.pump(); // Single pump to process the transition
      stopwatch.stop();

      // Assert: Transition should complete within 50ms
      print(
          '⏱️ Streaming→Interactive transition time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Mode transition must complete within 50ms (SC-002)');
      expect(lastMode, equals(ChartMode.interactive),
          reason: 'Mode should change to interactive');
    });

    testWidgets(
        'T038: Interactive → Streaming transition completes within 50ms (SC-002)',
        (WidgetTester tester) async {
      // Arrange: Create chart and pause it
      ChartMode? lastMode;
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
                  lastMode = mode;
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
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Pause the chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();
      expect(lastMode, equals(ChartMode.interactive));

      // Add buffered data while paused
      for (int i = 100; i < 120; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Act: Trigger auto-resume and measure transition time
      stopwatch.start();
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      stopwatch.stop();

      // Assert: Transition should complete within 50ms
      print(
          '⏱️ Interactive→Streaming transition time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Mode transition must complete within 50ms (SC-002)');
      expect(lastMode, equals(ChartMode.streaming),
          reason: 'Mode should change to streaming after auto-resume');
    });

    testWidgets(
        'T038: Repeated transitions maintain <50ms performance (SC-002)',
        (WidgetTester tester) async {
      // Arrange: Create chart
      ChartMode? lastMode;
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
                  lastMode = mode;
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
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      final chartFinder = find.byType(BravenChart);
      final List<int> transitionTimes = [];

      // Act: Perform 5 pause/resume cycles and measure each transition
      for (int cycle = 0; cycle < 5; cycle++) {
        // Pause
        stopwatch.reset();
        stopwatch.start();
        await tester.tap(chartFinder);
        await tester.pump();
        stopwatch.stop();
        transitionTimes.add(stopwatch.elapsedMilliseconds);
        expect(lastMode, equals(ChartMode.interactive));

        // Resume (auto)
        stopwatch.reset();
        stopwatch.start();
        await tester.pump(const Duration(milliseconds: 600));
        stopwatch.stop();
        transitionTimes.add(stopwatch.elapsedMilliseconds);
        expect(lastMode, equals(ChartMode.streaming));
      }

      // Assert: All transitions should be <50ms
      print('⏱️ Transition times across 10 transitions: $transitionTimes');
      for (int i = 0; i < transitionTimes.length; i++) {
        expect(transitionTimes[i], lessThan(50),
            reason: 'Transition $i must complete within 50ms (SC-002)');
      }

      final avgTime =
          transitionTimes.reduce((a, b) => a + b) / transitionTimes.length;
      print('⏱️ Average transition time: ${avgTime.toStringAsFixed(2)}ms');
      expect(avgTime, lessThan(50),
          reason: 'Average transition time must be <50ms');
    });
  });

  group('T039: Buffer Application Benchmark', () {
    late StreamController<ChartDataPoint> streamController;
    late ChartController chartController;
    late Stopwatch stopwatch;

    setUp(() {
      streamController = StreamController<ChartDataPoint>.broadcast();
      chartController = ChartController();
      stopwatch = Stopwatch();
    });

    tearDown() {
      streamController.close();
      chartController.dispose();
    }

    testWidgets(
        'T039: Applying 10K buffered points completes within 500ms (SC-007)',
        (WidgetTester tester) async {
      // Arrange: Create chart
      ChartMode? lastMode;
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
                maxBufferSize: 15000, // Allow 10K+ buffered points
                onModeChanged: (mode) {
                  lastMode = mode;
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

      // Add initial 100 points
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();
      expect(lastMode, equals(ChartMode.interactive));

      final pointCountBefore =
          chartController.getAllSeries()['line']?.length ?? 0;

      // Act: Buffer 10,000 points while paused
      print('📊 Buffering 10,000 points...');
      for (int i = 100; i < 10100; i++) {
        streamController
            .add(ChartDataPoint(x: i.toDouble(), y: (i % 100) * 10.0));
        if (i % 1000 == 0) {
          await tester.pump(Duration.zero); // Allow buffer to process
        }
      }
      await tester.pump();

      // Verify points buffered, not applied
      final pointCountWhileBuffering =
          chartController.getAllSeries()['line']?.length ?? 0;
      expect(pointCountWhileBuffering, equals(pointCountBefore),
          reason: 'Points should buffer without visual update');

      // Trigger auto-resume and measure buffer application time
      print('⏱️ Measuring buffer application time for 10K points...');
      stopwatch.start();
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      stopwatch.stop();

      // Assert: Buffer application should complete within 500ms
      print(
          '⏱️ Buffer application time (10K points): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason:
              'Applying 10K buffered points must complete within 500ms (SC-007)');
      expect(lastMode, equals(ChartMode.streaming),
          reason: 'Should transition to streaming after auto-resume');

      // Verify all buffered points were applied
      final pointCountAfter =
          chartController.getAllSeries()['line']?.length ?? 0;
      expect(pointCountAfter, greaterThan(pointCountBefore),
          reason: 'Buffered points should be applied after resume');
    });

    testWidgets(
        'T039: Applying 5K buffered points completes well under limit (SC-007)',
        (WidgetTester tester) async {
      // Arrange: Create chart
      ChartMode? lastMode;
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
                maxBufferSize: 10000,
                onModeChanged: (mode) {
                  lastMode = mode;
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
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Pause chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pump();
      expect(lastMode, equals(ChartMode.interactive));

      // Buffer 5,000 points
      print('📊 Buffering 5,000 points...');
      for (int i = 100; i < 5100; i++) {
        streamController
            .add(ChartDataPoint(x: i.toDouble(), y: (i % 100) * 10.0));
        if (i % 1000 == 0) {
          await tester.pump(Duration.zero);
        }
      }
      await tester.pump();

      // Act: Trigger auto-resume and measure
      print('⏱️ Measuring buffer application time for 5K points...');
      stopwatch.start();
      await tester.pump(const Duration(seconds: 1, milliseconds: 100));
      stopwatch.stop();

      // Assert: Should be significantly faster than 500ms limit
      print(
          '⏱️ Buffer application time (5K points): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(250),
          reason: 'Applying 5K points should be well under 500ms limit');
      expect(lastMode, equals(ChartMode.streaming));
    });

    testWidgets('T039: Buffer application scales linearly with point count',
        (WidgetTester tester) async {
      // Arrange: Create chart
      ChartMode? lastMode;
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
                maxBufferSize: 15000,
                onModeChanged: (mode) {
                  lastMode = mode;
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
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      final chartFinder = find.byType(BravenChart);
      final Map<int, int> pointCountToTime = {};

      // Test different buffer sizes: 1K, 2.5K, 5K, 7.5K, 10K
      final testSizes = [1000, 2500, 5000, 7500, 10000];

      for (final size in testSizes) {
        // Pause
        await tester.tap(chartFinder);
        await tester.pump();
        expect(lastMode, equals(ChartMode.interactive));

        // Buffer points
        for (int i = 100; i < 100 + size; i++) {
          streamController
              .add(ChartDataPoint(x: i.toDouble(), y: (i % 100) * 10.0));
          if (i % 1000 == 0) {
            await tester.pump(Duration.zero);
          }
        }
        await tester.pump();

        // Measure buffer application
        stopwatch.reset();
        stopwatch.start();
        await tester.pump(const Duration(milliseconds: 600));
        stopwatch.stop();

        pointCountToTime[size] = stopwatch.elapsedMilliseconds;
        print(
            '⏱️ Buffer application time ($size points): ${stopwatch.elapsedMilliseconds}ms');

        expect(lastMode, equals(ChartMode.streaming));

        // Small delay before next test
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert: All buffer applications should meet their proportional limits
      expect(pointCountToTime[1000]!, lessThan(50),
          reason: '1K points should be <50ms (~10% of 500ms limit)');
      expect(pointCountToTime[2500]!, lessThan(125),
          reason: '2.5K points should be <125ms (~25% of 500ms limit)');
      expect(pointCountToTime[5000]!, lessThan(250),
          reason: '5K points should be <250ms (~50% of 500ms limit)');
      expect(pointCountToTime[7500]!, lessThan(375),
          reason: '7.5K points should be <375ms (~75% of 500ms limit)');
      expect(pointCountToTime[10000]!, lessThan(500),
          reason: '10K points should be <500ms (100% limit, SC-007)');

      print('📊 Buffer application scaling results: $pointCountToTime');
    });
  });
}
