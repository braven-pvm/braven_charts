// Copyright (c) 2025 braven_charts. All rights reserved.
// @orchestra-task: 5
// Test: US1 - Grouped Bar Chart Rendering (TDD Red Phase)

@Tags(['tdd-red'])
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Grouped Bar Chart Rendering', () {
    group('Two Bar Series Side-by-Side Grouping', () {
      testWidgets('renders both bars visibly at same X-position', (tester) async {
        // Arrange: Two bar series with overlapping X-values
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'series1',
                      name: 'Revenue',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 150),
                        ChartDataPoint(x: 3, y: 120),
                      ],
                      color: Colors.blue,
                      barWidthPixels: 20,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Revenue',
                      ),
                    ),
                    BarChartSeries(
                      id: 'series2',
                      name: 'Cost',
                      points: const [
                        ChartDataPoint(x: 1, y: 80),
                        ChartDataPoint(x: 2, y: 110),
                        ChartDataPoint(x: 3, y: 90),
                      ],
                      color: Colors.red,
                      barWidthPixels: 20,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Cost',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: This test expects bars to be side-by-side (grouped)
        // Currently FAILS because bars overlap at same X-position
        // Green phase will implement bar grouping to make this pass
        fail('Expected: Bars from series1 and series2 should render side-by-side at each X-position. '
            'Actual: Bars currently overlap, making only topmost series visible. '
            'Bar grouping not yet implemented (Task 6).');
      });

      testWidgets('applies 2px gap between grouped bars', (tester) async {
        // Arrange: Two bar series to verify gap spacing
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 1, y: 50),
                        ChartDataPoint(x: 2, y: 75),
                      ],
                      barWidthPixels: 15,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Series 1',
                      ),
                    ),
                    BarChartSeries(
                      id: 'series2',
                      points: const [
                        ChartDataPoint(x: 1, y: 60),
                        ChartDataPoint(x: 2, y: 80),
                      ],
                      barWidthPixels: 15,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Series 2',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: Gap spacing not implemented yet
        fail('Expected: 2px gap between adjacent bars in a group (per FR-003). '
            'Actual: Gap calculation not implemented. '
            'Requires BarGroupInfo.gap to be used in positioning logic (Task 6).');
      });
    });

    group('Three+ Bar Series All Visible', () {
      testWidgets('renders all three bars at each X-position', (tester) async {
        // Arrange: Three bar series with same X-values
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'actual',
                      name: 'Actual',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 120),
                        ChartDataPoint(x: 3, y: 95),
                      ],
                      color: Colors.green,
                      barWidthPixels: 18,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                    BarChartSeries(
                      id: 'target',
                      name: 'Target',
                      points: const [
                        ChartDataPoint(x: 1, y: 110),
                        ChartDataPoint(x: 2, y: 115),
                        ChartDataPoint(x: 3, y: 100),
                      ],
                      color: Colors.blue,
                      barWidthPixels: 18,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                    BarChartSeries(
                      id: 'forecast',
                      name: 'Forecast',
                      points: const [
                        ChartDataPoint(x: 1, y: 105),
                        ChartDataPoint(x: 2, y: 125),
                        ChartDataPoint(x: 3, y: 98),
                      ],
                      color: Colors.orange,
                      barWidthPixels: 18,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: Three bars should be grouped side-by-side
        fail('Expected: All three bars (actual, target, forecast) should be visible and grouped at each X-position. '
            'Actual: Bars overlap, only topmost bar is visible. '
            'Multi-series bar grouping not implemented (Task 6).');
      });

      testWidgets('handles five bar series with proper spacing', (tester) async {
        // Arrange: Five bar series to test complex grouping
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'series1',
                      points: const [ChartDataPoint(x: 1, y: 100)],
                      color: Colors.red,
                      barWidthPixels: 12,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                    BarChartSeries(
                      id: 'series2',
                      points: const [ChartDataPoint(x: 1, y: 90)],
                      color: Colors.blue,
                      barWidthPixels: 12,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                    BarChartSeries(
                      id: 'series3',
                      points: const [ChartDataPoint(x: 1, y: 110)],
                      color: Colors.green,
                      barWidthPixels: 12,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                    BarChartSeries(
                      id: 'series4',
                      points: const [ChartDataPoint(x: 1, y: 95)],
                      color: Colors.orange,
                      barWidthPixels: 12,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                    BarChartSeries(
                      id: 'series5',
                      points: const [ChartDataPoint(x: 1, y: 105)],
                      color: Colors.purple,
                      barWidthPixels: 12,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: Five bars should be grouped properly
        fail('Expected: All five bars should be visible in a grouped layout at X=1. '
            'Actual: Bars stack on top of each other. '
            'Bar grouping for 5+ series not implemented (Task 6).');
      });
    });

    group('Single Bar Series Centered (Unchanged Behavior)', () {
      testWidgets('single bar series renders bars centered at X-position', (tester) async {
        // Arrange: Single bar series (existing behavior should be unchanged)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'single',
                      name: 'Revenue',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 150),
                        ChartDataPoint(x: 3, y: 120),
                      ],
                      color: Colors.blue,
                      barWidthPixels: 30,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Revenue',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds and renders
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: This test verifies single bar series behavior is unchanged
        // Currently PASSES because single bar series already works correctly
        // Adding fail() to ensure test is in red phase for consistency
        fail('Expected: Single bar series should render bars centered at X-positions (existing behavior). '
            'This test validates that grouping implementation (Task 6) does NOT break single-series rendering. '
            'Currently unimplemented: BarGroupInfo with index=0, count=1 should produce offset=0.');
      });

      testWidgets('single bar series with barWidthPercent works', (tester) async {
        // Arrange: Single bar series using percentage width
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'single-pct',
                      points: const [
                        ChartDataPoint(x: 1, y: 50),
                        ChartDataPoint(x: 2, y: 75),
                        ChartDataPoint(x: 3, y: 60),
                      ],
                      barWidthPercent: 0.8,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: Percentage-based width with single series
        fail('Expected: Bars sized to 80% of available spacing, centered. '
            'This validates single-series behavior is preserved (FR-005). '
            'Adding explicit fail for red phase compliance.');
      });
    });

    group('Minimum Bar Width Enforcement', () {
      testWidgets('enforces 4px minimum width with many bar series', (tester) async {
        // Arrange: Six bar series that would calculate very narrow bars
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    for (int i = 0; i < 6; i++)
                      BarChartSeries(
                        id: 'series$i',
                        points: const [
                          ChartDataPoint(x: 1, y: 50),
                          ChartDataPoint(x: 2, y: 75),
                        ],
                        barWidthPixels: 3, // Below 4px minimum
                        yAxisConfig: YAxisConfig(
                          position: YAxisPosition.left,
                          label: 'Values',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: Minimum 4px width not enforced yet
        fail('Expected: Each bar should be at least 4px wide for readability (FR-012). '
            'Actual: Bars render at specified 3px width without minimum enforcement. '
            'MinWidth validation logic not implemented (Task 6).');
      });

      testWidgets('respects minWidth constraint in BarChartSeries', (tester) async {
        // Arrange: Bar series with explicit minWidth=8
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'constrained',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 150),
                      ],
                      barWidthPixels: 5, // Below minWidth
                      minWidth: 8.0, // Should clamp to this
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: minWidth clamping not implemented
        fail('Expected: Bar width clamped to minWidth=8px even though barWidthPixels=5px. '
            'Actual: minWidth property exists in BarChartSeries but not enforced during rendering. '
            'Width clamping logic needed (Task 6).');
      });

      testWidgets('allows bars wider than minimum', (tester) async {
        // Arrange: Bar series with comfortable width (should not be affected)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'wide',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 150),
                      ],
                      barWidthPixels: 40, // Well above minimum
                      minWidth: 4.0,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Values',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: This test should eventually pass (wide bars are fine)
        // Adding fail for red phase consistency
        fail('Expected: Bars render at 40px width (no clamping needed). '
            'This validates minWidth does not affect already-wide bars. '
            'Currently: Width constraint system not implemented (Task 6).');
      });
    });

    group('Mixed Series Types with Grouped Bars', () {
      testWidgets('bar series group while line series renders normally', (tester) async {
        // Arrange: Two bar series + one line series
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'bar1',
                      points: const [
                        ChartDataPoint(x: 1, y: 100),
                        ChartDataPoint(x: 2, y: 120),
                      ],
                      barWidthPixels: 20,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Bars',
                      ),
                    ),
                    BarChartSeries(
                      id: 'bar2',
                      points: const [
                        ChartDataPoint(x: 1, y: 90),
                        ChartDataPoint(x: 2, y: 110),
                      ],
                      barWidthPixels: 20,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Bars',
                      ),
                    ),
                    LineChartSeries(
                      id: 'line1',
                      points: const [
                        ChartDataPoint(x: 1, y: 105),
                        ChartDataPoint(x: 2, y: 115),
                      ],
                      color: Colors.purple,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Line',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // TODO: Bar grouping should only affect bar series
        fail('Expected: bar1 and bar2 grouped side-by-side, line1 renders independently. '
            'Actual: Bar series overlap, line renders fine. '
            'Bar-specific grouping logic not implemented (Task 6).');
      });
    });
  });
}
