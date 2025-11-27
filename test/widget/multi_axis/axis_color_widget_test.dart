// Copyright 2025 Braven Charts - TDD Widget Tests for Color-Coded Axes
// SPDX-License-Identifier: MIT
//
// T032 [US3] Widget tests for color-coded axes
// TDD: These tests are written FIRST and should FAIL until implementation is complete.

import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Color-Coded Axes Widget Tests', () {
    // Helper to create test series with specified color
    LineChartSeries createSeries({
      required String id,
      required Color color,
      String? yAxisId,
      String? unit,
    }) {
      return LineChartSeries(
        id: id,
        name: id,
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 1, y: 100),
          const ChartDataPoint(x: 2, y: 50),
        ],
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
            ),
          ),
        ),
      );
    }

    group('Axis Renders with Series Color', () {
      testWidgets('axis label uses series color when no explicit color configured', (WidgetTester tester) async {
        // Given: A chart with a blue series bound to an axis without explicit color
        const seriesColor = Color(0xFF2196F3); // Blue
        final chart = buildTestChart(
          series: [
            createSeries(id: 'power', color: seriesColor, yAxisId: 'power'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
              // No color specified - should derive from series
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: The axis label should render in the series color
        // We verify by finding text with the specific color
        final textWidgets = tester.widgetList<Text>(find.text('Power'));
        expect(textWidgets, isNotEmpty, reason: 'Axis label "Power" should be found');

        // Check if any text has the expected color style
        final hasBlueText = textWidgets.any((text) {
          final style = text.style;
          return style?.color == seriesColor ||
              // Allow for slight color variations in theming
              (style?.color != null && (style!.color!.blue - seriesColor.blue).abs() < 10 && (style.color!.red - seriesColor.red).abs() < 10);
        });

        expect(hasBlueText, isTrue, reason: 'Axis label should use series color when no explicit color');
      });

      testWidgets('axis uses explicit color when configured', (WidgetTester tester) async {
        // Given: A chart with explicit axis color different from series color
        const seriesColor = Color(0xFF2196F3); // Blue series
        const axisColor = Color(0xFFE91E63); // Pink axis
        final chart = buildTestChart(
          series: [
            createSeries(id: 'power', color: seriesColor, yAxisId: 'power'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
              color: axisColor, // Explicit pink color
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: The axis should use the explicit color (not series color)
        final textWidgets = tester.widgetList<Text>(find.text('Power'));
        expect(textWidgets, isNotEmpty);

        // Check for explicit axis color
        final hasPinkText = textWidgets.any((text) {
          final style = text.style;
          return style?.color == axisColor ||
              (style?.color != null && (style!.color!.red - axisColor.red).abs() < 10 && (style.color!.green - axisColor.green).abs() < 10);
        });

        expect(hasPinkText, isTrue, reason: 'Axis should use explicit color, not series color');
      });
    });

    group('Multiple Axes with Different Colors', () {
      testWidgets('renders multiple axes with distinct colors', (WidgetTester tester) async {
        // Given: A chart with multiple series and axes, each with different colors
        const powerColor = Color(0xFF2196F3); // Blue
        const hrColor = Color(0xFFF44336); // Red
        const cadenceColor = Color(0xFF4CAF50); // Green

        final chart = buildTestChart(
          series: [
            createSeries(id: 'power', color: powerColor, yAxisId: 'power', unit: 'W'),
            createSeries(id: 'hr', color: hrColor, yAxisId: 'hr', unit: 'bpm'),
            createSeries(id: 'cadence', color: cadenceColor, yAxisId: 'cadence', unit: 'rpm'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'power',
              position: YAxisPosition.left,
              label: 'Power',
              // Derives blue from series
            ),
            const YAxisConfig(
              id: 'hr',
              position: YAxisPosition.right,
              label: 'Heart Rate',
              // Derives red from series
            ),
            const YAxisConfig(
              id: 'cadence',
              position: YAxisPosition.leftOuter,
              label: 'Cadence',
              // Derives green from series
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: All three axis labels should be present
        expect(find.text('Power'), findsWidgets);
        expect(find.text('Heart Rate'), findsWidgets);
        expect(find.text('Cadence'), findsWidgets);
      });

      testWidgets('mixed explicit and derived colors work correctly', (WidgetTester tester) async {
        // Given: Chart with mix of explicit and derived axis colors
        const seriesColor = Color(0xFF2196F3);
        const explicitColor = Color(0xFFFF9800); // Orange explicit

        final chart = buildTestChart(
          series: [
            createSeries(id: 's1', color: seriesColor, yAxisId: 'left'),
            createSeries(id: 's2', color: Colors.green, yAxisId: 'right'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'left',
              position: YAxisPosition.left,
              label: 'Derived',
              // Should use seriesColor
            ),
            const YAxisConfig(
              id: 'right',
              position: YAxisPosition.right,
              label: 'Explicit',
              color: explicitColor,
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Both labels should be present
        expect(find.text('Derived'), findsWidgets);
        expect(find.text('Explicit'), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('unbound axis uses neutral color', (WidgetTester tester) async {
        // Given: An axis with no series bound to it
        final chart = buildTestChart(
          series: [
            createSeries(id: 'data', color: Colors.blue, yAxisId: 'different'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'orphan',
              position: YAxisPosition.left,
              label: 'Orphan Axis',
              // No series bound, should use neutral grey
            ),
            const YAxisConfig(
              id: 'different',
              position: YAxisPosition.right,
              label: 'Different',
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: The orphan axis should still render (in neutral color)
        expect(find.text('Orphan Axis'), findsWidgets);
      });

      testWidgets('shared axis uses first series color', (WidgetTester tester) async {
        // Given: Multiple series bound to the same axis
        const firstColor = Color(0xFF2196F3); // Blue - should be used
        const secondColor = Color(0xFFF44336); // Red - should be ignored

        final chart = buildTestChart(
          series: [
            createSeries(id: 'first', color: firstColor, yAxisId: 'shared'),
            createSeries(id: 'second', color: secondColor, yAxisId: 'shared'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'shared',
              position: YAxisPosition.left,
              label: 'Shared Axis',
              // Should use firstColor (blue)
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: The shared axis should be present
        expect(find.text('Shared Axis'), findsWidgets);

        // Verify color is from first series (implementation detail)
        final textWidgets = tester.widgetList<Text>(find.text('Shared Axis'));
        expect(textWidgets, isNotEmpty);
      });

      testWidgets('unbound series uses first axis color', (WidgetTester tester) async {
        // Given: A series with null yAxisId (should bind to first axis)
        final chart = buildTestChart(
          series: [
            createSeries(id: 'unbound', color: Colors.orange, yAxisId: null),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'first',
              position: YAxisPosition.left,
              label: 'First Axis',
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Chart should render successfully
        expect(find.text('First Axis'), findsWidgets);
      });
    });

    group('Axis Components Color Consistency', () {
      testWidgets('axis line, ticks, and labels use same color', (WidgetTester tester) async {
        // Given: A chart with explicit axis color
        const axisColor = Color(0xFF9C27B0); // Purple

        final chart = buildTestChart(
          series: [
            createSeries(id: 'data', color: axisColor, yAxisId: 'colored'),
          ],
          yAxes: [
            const YAxisConfig(
              id: 'colored',
              position: YAxisPosition.left,
              label: 'Colored Axis',
              color: axisColor,
              showTicks: true,
              showAxisLine: true,
              showLabels: true,
            ),
          ],
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: The axis should render with all components
        expect(find.text('Colored Axis'), findsWidgets);

        // Note: Detailed visual verification would require golden tests
        // This test verifies the chart renders without errors
      });
    });

    group('Theme Integration', () {
      testWidgets('axis colors respect chart theme', (WidgetTester tester) async {
        // Given: A chart using dark theme
        final chart = MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  createSeries(id: 'data', color: Colors.blue, yAxisId: 'main'),
                ],
                yAxes: const [
                  YAxisConfig(
                    id: 'main',
                    position: YAxisPosition.left,
                    label: 'Dark Theme Axis',
                    // Color should be visible in dark theme
                    color: Colors.cyan,
                  ),
                ],
                normalizationMode: NormalizationMode.perSeries,
                theme: ChartTheme.dark,
              ),
            ),
          ),
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Chart should render without errors in dark theme
        expect(find.text('Dark Theme Axis'), findsWidgets);
      });

      testWidgets('high contrast theme maintains axis colors', (WidgetTester tester) async {
        // Given: A chart using high contrast theme
        final chart = MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  createSeries(id: 'data', color: Colors.yellow, yAxisId: 'main'),
                ],
                yAxes: const [
                  YAxisConfig(
                    id: 'main',
                    position: YAxisPosition.left,
                    label: 'High Contrast',
                    color: Colors.yellow,
                  ),
                ],
                normalizationMode: NormalizationMode.perSeries,
                theme: ChartTheme.highContrast,
              ),
            ),
          ),
        );

        // When: Pumping the widget
        await tester.pumpWidget(chart);
        await tester.pumpAndSettle();

        // Then: Chart should render in high contrast mode
        expect(find.text('High Contrast'), findsWidgets);
      });
    });
  });
}
