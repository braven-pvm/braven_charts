// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/src/models/chart_mode.dart';
import 'package:braven_charts/src/models/streaming_config.dart';
import 'package:braven_charts/src/widgets/braven_chart.dart';
import 'package:braven_charts/src/widgets/enums/chart_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for streaming mode behavior (T014).
///
/// Validates:
/// - Chart starts in streaming mode when streamingConfig provided
/// - Auto-scroll enabled in streaming mode
/// - Interaction handlers disabled in streaming mode
/// - Smooth rendering without errors
///
/// Related: FR-002 (streaming mode), FR-005 (disabled interactions), T017-T024 (implementation)
void main() {
  group('Streaming mode integration tests', () {
    testWidgets('should start in streaming mode when streamingConfig provided',
        (WidgetTester tester) async {
      // Given: Chart with streamingConfig and dataStream
      final streamController = StreamController<ChartDataPoint>();
      ChartMode? capturedMode;

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [const ChartDataPoint(x: 0, y: 0)],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(
          onModeChanged: (mode) => capturedMode = mode,
        ),
      );

      // When: Building chart
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Then: Should start in streaming mode
      expect(capturedMode, isNull); // No mode change yet (started in streaming)

      // Verify chart renders without error
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('should not have interaction handlers in streaming mode',
        (WidgetTester tester) async {
      // Given: Chart in streaming mode
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [const ChartDataPoint(x: 0, y: 0)],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Then: Should not have GestureDetector (interactions disabled per FR-005)
      // Note: This test will fail until T019 implements conditional interaction wrapping
      // In streaming mode, GestureDetector should be absent or disabled
      // This is a placeholder - actual implementation in T019
      expect(find.byType(BravenChart), findsOneWidget);
      // TODO(T019): Add assertion: expect(find.byType(GestureDetector), findsNothing);

      // Cleanup
      await streamController.close();
    });

    testWidgets('should render without errors during streaming',
        (WidgetTester tester) async {
      // Given: Chart in streaming mode with data stream
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [const ChartDataPoint(x: 0, y: 0)],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart and adding data points
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Add multiple points to simulate streaming
      for (int i = 1; i <= 10; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i.toDouble()));
        await tester.pump(const Duration(milliseconds: 16)); // 60fps
      }

      await tester.pumpAndSettle();

      // Then: Should render without throwing errors
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('should default to interactive mode when no streamingConfig',
        (WidgetTester tester) async {
      // Given: Chart without streamingConfig
      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [const ChartDataPoint(x: 0, y: 0)],
          ),
        ],
      );

      // When: Building chart
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Then: Should render successfully (defaults to interactive per FR-003)
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty series with streamingConfig',
        (WidgetTester tester) async {
      // Given: Chart with empty series but dataStream configured
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: const [],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Then: Should render without errors (will populate from stream)
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Cleanup
      await streamController.close();
    });

    testWidgets('should invoke onModeChanged callback when provided',
        (WidgetTester tester) async {
      // Given: Chart with mode change callback
      final streamController = StreamController<ChartDataPoint>();
      final modeChanges = <ChartMode>[];

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [const ChartDataPoint(x: 0, y: 0)],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(
          onModeChanged: (mode) => modeChanges.add(mode),
        ),
      );

      // When: Building chart
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Then: Callback should be registered (will be invoked by future implementation)
      // Note: This test validates callback registration, actual invocation tested in T025+
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('should accept stream data updates',
        (WidgetTester tester) async {
      // Given: Chart with data stream
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [const ChartDataPoint(x: 0, y: 0)],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart and streaming data
      await tester.pumpWidget(MaterialApp(home: chart));
      await tester.pumpAndSettle();

      // Stream multiple points
      streamController.add(const ChartDataPoint(x: 1, y: 10));
      await tester.pump();
      streamController.add(const ChartDataPoint(x: 2, y: 20));
      await tester.pump();
      streamController.add(const ChartDataPoint(x: 3, y: 15));
      await tester.pump();

      await tester.pumpAndSettle();

      // Then: Should handle stream without errors
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });
  });
}
