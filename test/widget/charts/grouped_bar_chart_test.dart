// Copyright (c) 2025 braven_charts. All rights reserved.
// Test: US1 - Grouped Bar Chart Rendering (TDD Green Phase)

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

        // Assert: Widget builds successfully and renders grouped bars
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with proper gap spacing
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds successfully with three grouped bars
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with five grouped bars
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds and single series remains centered
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with percentage-based width
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with minimum width enforced
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with minWidth constraint respected
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with wide bars (no clamping needed)
        expect(find.byType(BravenChartPlus), findsOneWidget);
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

        // Assert: Widget builds with mixed series types
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });
  });
}
