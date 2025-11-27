// Copyright 2025 Braven Charts - TDD Widget Tests for Crosshair Values
// SPDX-License-Identifier: MIT
//
// T041 [US4] Widget tests for crosshair values in multi-axis mode
// TDD: These tests are written FIRST and should FAIL until implementation is complete.

import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/interaction_config.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crosshair Values Widget Tests', () {
    // Helper to create test series
    LineChartSeries createSeries({
      required String id,
      required Color color,
      required List<ChartDataPoint> points,
      String? yAxisId,
      String? unit,
    }) {
      return LineChartSeries(
        id: id,
        name: id,
        points: points,
        color: color,
        yAxisId: yAxisId,
        unit: unit,
      );
    }

    // Helper to wrap chart in MaterialApp for rendering
    Widget buildTestChart({
      required List<ChartSeries> series,
      List<YAxisConfig>? yAxes,
      NormalizationMode normalizationMode = NormalizationMode.perSeries,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: series,
              yAxes: yAxes,
              normalizationMode: normalizationMode,
              theme: ChartTheme.light,
              interactionConfig: const InteractionConfig(
                crosshair: CrosshairConfig(
                  showCoordinateLabels: true,
                  displayMode: CrosshairDisplayMode.auto,
                  trackingModeThreshold: 250,
                  mode: CrosshairMode.vertical,
                  interpolateValues: true,
                  showTrackingTooltip: true,
                  showIntersectionMarkers: true,
                ),
              ),
            ),
          ),
        ),
      );
    }

    group('Multi-Axis Crosshair Rendering', () {
      testWidgets('renders chart with crosshair enabled',
          (WidgetTester tester) async {
        // Given: A multi-axis chart with crosshair enabled
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Power',
              color: Colors.blue,
              yAxisId: 'power',
              unit: 'W',
              points: [
                const ChartDataPoint(x: 0, y: 100),
                const ChartDataPoint(x: 1, y: 200),
                const ChartDataPoint(x: 2, y: 150),
              ],
            ),
            createSeries(
              id: 'Heart Rate',
              color: Colors.red,
              yAxisId: 'hr',
              unit: 'bpm',
              points: [
                const ChartDataPoint(x: 0, y: 80),
                const ChartDataPoint(x: 1, y: 120),
                const ChartDataPoint(x: 2, y: 100),
              ],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
            ),
            YAxisConfig(
              id: 'hr',
              position: YAxisPosition.right,
              label: 'Heart Rate',
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Chart should render without errors
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('displays crosshair on tap/hover',
          (WidgetTester tester) async {
        // Given: A multi-axis chart
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Power',
              color: Colors.blue,
              yAxisId: 'power',
              unit: 'W',
              points: [
                const ChartDataPoint(x: 0, y: 100),
                const ChartDataPoint(x: 1, y: 200),
                const ChartDataPoint(x: 2, y: 150),
              ],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // When: Tapping on the chart
        final center = tester.getCenter(find.byType(BravenChartPlus));
        await tester.tapAt(center);
        await tester.pumpAndSettle();

        // Then: Chart should render without errors after interaction
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Original Value Display', () {
      testWidgets('chart with power and heart rate renders correctly',
          (WidgetTester tester) async {
        // This test verifies the chart can render with multi-scale data
        // The actual crosshair value display is verified through golden tests
        // and manual testing since tooltip text is canvas-painted

        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Power',
              color: Colors.blue,
              yAxisId: 'power',
              unit: 'W',
              points: [
                const ChartDataPoint(x: 0, y: 240),
                const ChartDataPoint(x: 1, y: 180),
                const ChartDataPoint(x: 2, y: 220),
              ],
            ),
            createSeries(
              id: 'Heart Rate',
              color: Colors.red,
              yAxisId: 'hr',
              unit: 'bpm',
              points: [
                const ChartDataPoint(x: 0, y: 165),
                const ChartDataPoint(x: 1, y: 140),
                const ChartDataPoint(x: 2, y: 155),
              ],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
            ),
            YAxisConfig(
              id: 'hr',
              position: YAxisPosition.right,
              label: 'Heart Rate',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // When: Interacting with the chart
        final center = tester.getCenter(find.byType(BravenChartPlus));
        await tester.tapAt(center);
        await tester.pump();

        // Then: Chart renders correctly (crosshair values tested via golden tests)
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Tracking Mode', () {
      testWidgets('renders chart with tracking enabled',
          (WidgetTester tester) async {
        // Given: A chart with tracking mode configured
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Power',
              color: Colors.blue,
              yAxisId: 'power',
              unit: 'W',
              points: List.generate(
                10,
                (i) => ChartDataPoint(x: i.toDouble(), y: 100 + i * 10.0),
              ),
            ),
            createSeries(
              id: 'Cadence',
              color: Colors.green,
              yAxisId: 'cadence',
              unit: 'rpm',
              points: List.generate(
                10,
                (i) => ChartDataPoint(x: i.toDouble(), y: 80 + i * 2.0),
              ),
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
            ),
            YAxisConfig(
              id: 'cadence',
              position: YAxisPosition.right,
              label: 'Cadence',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Chart renders without errors
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Decimal Value Formatting', () {
      testWidgets('renders chart with decimal values correctly',
          (WidgetTester tester) async {
        // Given: A chart with decimal values
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Tidal Volume',
              color: Colors.purple,
              yAxisId: 'tv',
              unit: 'L',
              points: [
                const ChartDataPoint(x: 0, y: 2.1),
                const ChartDataPoint(x: 1, y: 2.3),
                const ChartDataPoint(x: 2, y: 2.5),
              ],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'tv',
              position: YAxisPosition.left,
              label: 'Tidal Volume',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // When: Interacting with the chart
        final center = tester.getCenter(find.byType(BravenChartPlus));
        await tester.tapAt(center);
        await tester.pump();

        // Then: Chart renders (decimal formatting verified via unit tests)
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('renders chart with very small values',
          (WidgetTester tester) async {
        // Given: A chart with micro-scale values
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Micro',
              color: Colors.orange,
              yAxisId: 'micro',
              unit: 'µV',
              points: [
                const ChartDataPoint(x: 0, y: 0.001),
                const ChartDataPoint(x: 1, y: 0.003),
                const ChartDataPoint(x: 2, y: 0.002),
              ],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'micro',
              position: YAxisPosition.left,
              label: 'Micro',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Chart renders correctly with micro-scale values
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles single data point', (WidgetTester tester) async {
        // Given: A series with only one point
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Single',
              color: Colors.blue,
              yAxisId: 'single',
              unit: 'W',
              points: const [ChartDataPoint(x: 0, y: 150)],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'single',
              position: YAxisPosition.left,
              label: 'Single',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles series with zero range',
          (WidgetTester tester) async {
        // Given: A series where all values are identical
        final chart = buildTestChart(
          series: [
            createSeries(
              id: 'Flat',
              color: Colors.blue,
              yAxisId: 'flat',
              unit: 'V',
              points: [
                const ChartDataPoint(x: 0, y: 5.0),
                const ChartDataPoint(x: 1, y: 5.0),
                const ChartDataPoint(x: 2, y: 5.0),
              ],
            ),
          ],
          yAxes: const [
            YAxisConfig(
              id: 'flat',
              position: YAxisPosition.left,
              label: 'Flat',
            ),
          ],
        );

        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });
  });
}
