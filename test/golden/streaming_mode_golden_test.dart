// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/src/models/streaming_config.dart';
import 'package:braven_charts/src/widgets/braven_chart.dart';
import 'package:braven_charts/src/widgets/enums/chart_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests for streaming mode visual regression (T016).
///
/// Validates:
/// - Streaming mode renders correctly without visual artifacts
/// - Chart layout matches expected appearance
/// - No rendering errors visible in snapshots
///
/// Usage:
/// - Run: flutter test test/golden/streaming_mode_golden_test.dart
/// - Update: flutter test test/golden/streaming_mode_golden_test.dart --update-goldens
///
/// Related: T017-T024 (streaming implementation), FR-020 (zero errors)
void main() {
  group('Streaming mode golden tests', () {
    testWidgets('should render streaming mode chart correctly', (WidgetTester tester) async {
      // Given: Chart configured for streaming mode
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'golden-test',
            points: List.generate(
              50,
              (i) => ChartDataPoint(x: i.toDouble(), y: 50 + 20 * (i % 10 / 10)),
            ),
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart in streaming mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: chart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Should match golden snapshot
      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('streaming_mode_chart.png'),
      );

      // Cleanup
      await streamController.close();
    });

    testWidgets('should render streaming mode with data stream correctly', (WidgetTester tester) async {
      // Given: Chart with active data stream
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'stream-test',
            points: [const ChartDataPoint(x: 0, y: 50)],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart and adding stream data
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: chart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add some streamed data
      for (int i = 1; i <= 20; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: 50 + 10 * (i % 5 / 5)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();

      // Then: Should match golden snapshot with streamed data
      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('streaming_mode_with_data.png'),
      );

      // Cleanup
      await streamController.close();
    });

    testWidgets('should render streaming mode with multiple series correctly', (WidgetTester tester) async {
      // Given: Chart with multiple series in streaming mode
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'series-1',
            points: List.generate(
              30,
              (i) => ChartDataPoint(x: i.toDouble(), y: 40 + 15 * (i % 8 / 8)),
            ),
          ),
          ChartSeries(
            id: 'series-2',
            points: List.generate(
              30,
              (i) => ChartDataPoint(x: i.toDouble(), y: 60 + 10 * (i % 6 / 6)),
            ),
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building chart with multiple series
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: chart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Should match golden snapshot
      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('streaming_mode_multi_series.png'),
      );

      // Cleanup
      await streamController.close();
    });

    testWidgets('should render empty streaming chart correctly', (WidgetTester tester) async {
      // Given: Empty chart in streaming mode
      final streamController = StreamController<ChartDataPoint>();

      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'empty',
            points: [],
          ),
        ],
        dataStream: streamController.stream,
        streamingConfig: StreamingConfig(),
      );

      // When: Building empty chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: chart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Should match golden snapshot for empty state
      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('streaming_mode_empty.png'),
      );

      // Cleanup
      await streamController.close();
    });
  });
}
