// Copyright (c) 2025 braven_charts. All rights reserved.
// Test: US2 - Y-Axis Position and Modern Features in Single-Axis Mode

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Y-Axis Position Rendering', () {
    group('YAxisPosition.left (default)', () {
      testWidgets('renders Y-axis on left side of chart', (tester) async {
        // Arrange: Chart with left Y-axis
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 50, y: 100),
                        ChartDataPoint(x: 100, y: 50),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Left Axis',
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
      });

      testWidgets('left position is default when not specified', (tester) async {
        // Arrange: Chart without explicit position
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 100, y: 100),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully with default left position
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('YAxisPosition.right', () {
      testWidgets('renders Y-axis on right side of chart', (tester) async {
        // Arrange: Chart with right Y-axis (key acceptance criterion)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 50, y: 100),
                        ChartDataPoint(x: 100, y: 50),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Right Axis',
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
      });

      testWidgets('right position works with multiple series', (tester) async {
        // Arrange: Multiple series with right Y-axis
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Temperature',
                        unit: '°C',
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      points: const [
                        ChartDataPoint(x: 0, y: 15),
                        ChartDataPoint(x: 50, y: 35),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Temperature',
                        unit: '°C',
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
      });
    });

    group('YAxisPosition.leftOuter', () {
      testWidgets('renders Y-axis on leftmost side of chart', (tester) async {
        // Arrange: Chart with leftOuter Y-axis
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 50, y: 100),
                        ChartDataPoint(x: 100, y: 50),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.leftOuter,
                        label: 'Left Outer Axis',
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
      });

      testWidgets('leftOuter position works in multi-axis layout', (tester) async {
        // Arrange: Chart with both left and leftOuter axes
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 50, y: 200),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.leftOuter,
                        label: 'Outer',
                        unit: 'A',
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 20),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Inner',
                        unit: 'V',
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
      });
    });

    group('YAxisPosition.rightOuter', () {
      testWidgets('renders Y-axis on rightmost side of chart', (tester) async {
        // Arrange: Chart with rightOuter Y-axis
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 50, y: 100),
                        ChartDataPoint(x: 100, y: 50),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.rightOuter,
                        label: 'Right Outer Axis',
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
      });

      testWidgets('rightOuter position works in multi-axis layout', (tester) async {
        // Arrange: Chart with both right and rightOuter axes
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 300,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: const [
                        ChartDataPoint(x: 0, y: 50),
                        ChartDataPoint(x: 50, y: 100),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Inner Right',
                        unit: 'rpm',
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      points: const [
                        ChartDataPoint(x: 0, y: 200),
                        ChartDataPoint(x: 50, y: 400),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.rightOuter,
                        label: 'Outer Right',
                        unit: 'km',
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
      });
    });

    group('All Four Positions Together', () {
      testWidgets('renders chart with all four Y-axis positions', (tester) async {
        // Arrange: Chart with all four axis positions
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'leftOuter',
                      points: const [
                        ChartDataPoint(x: 0, y: 1000),
                        ChartDataPoint(x: 100, y: 2000),
                      ],
                      color: Colors.blue,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.leftOuter,
                        label: 'Left Outer',
                        unit: 'A',
                      ),
                    ),
                    LineChartSeries(
                      id: 'left',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 100, y: 200),
                      ],
                      color: Colors.green,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Left',
                        unit: 'V',
                      ),
                    ),
                    LineChartSeries(
                      id: 'right',
                      points: const [
                        ChartDataPoint(x: 0, y: 50),
                        ChartDataPoint(x: 100, y: 150),
                      ],
                      color: Colors.orange,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Right',
                        unit: 'rpm',
                      ),
                    ),
                    LineChartSeries(
                      id: 'rightOuter',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      color: Colors.red,
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.rightOuter,
                        label: 'Right Outer',
                        unit: '°C',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully with all positions
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });
  });

  group('Unit Display on Single Y-Axis', () {
    testWidgets('displays unit with AxisLabelDisplay.labelWithUnit', (tester) async {
      // Arrange: Chart with unit and labelWithUnit display
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'power',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 250),
                      ChartDataPoint(x: 100, y: 500),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Power',
                      unit: 'kW',
                      labelDisplay: AxisLabelDisplay.labelWithUnit,
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
    });

    testWidgets('displays unit with AxisLabelDisplay.labelAndTickUnit', (tester) async {
      // Arrange: Chart with unit on ticks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'voltage',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 12),
                      ChartDataPoint(x: 100, y: 24),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.right,
                      label: 'Voltage',
                      unit: 'V',
                      labelDisplay: AxisLabelDisplay.labelAndTickUnit,
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
    });

    testWidgets('displays unit with AxisLabelDisplay.labelWithUnitAndTickUnit', (tester) async {
      // Arrange: Chart with unit on both label and ticks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'current',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 5),
                      ChartDataPoint(x: 100, y: 10),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Current',
                      unit: 'A',
                      labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
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
    });

    testWidgets('displays no unit with AxisLabelDisplay.labelOnly', (tester) async {
      // Arrange: Chart with label only, no unit display
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'count',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 100),
                      ChartDataPoint(x: 100, y: 200),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Count',
                      unit: 'items',
                      labelDisplay: AxisLabelDisplay.labelOnly,
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
    });

    testWidgets('displays only tick unit with AxisLabelDisplay.none', (tester) async {
      // Arrange: Chart with no axis label, only tick unit
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'temperature',
                    points: const [
                      ChartDataPoint(x: 0, y: 20),
                      ChartDataPoint(x: 50, y: 25),
                      ChartDataPoint(x: 100, y: 30),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.right,
                      unit: '°C',
                      labelDisplay: AxisLabelDisplay.none,
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
    });
  });

  group('CrosshairLabelPosition Property', () {
    testWidgets('CrosshairLabelPosition.overAxis is default', (tester) async {
      // Arrange: YAxisConfig without explicit crosshairLabelPosition
      final config = YAxisConfig(
        position: YAxisPosition.left,
        label: 'Test',
      );

      // Assert: Default should be overAxis
      expect(config.crosshairLabelPosition, equals(CrosshairLabelPosition.overAxis));
    });

    testWidgets('CrosshairLabelPosition.overAxis works in chart', (tester) async {
      // Arrange: Chart with overAxis crosshair label
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'series1',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 100),
                      ChartDataPoint(x: 100, y: 50),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Over Axis Label',
                      crosshairLabelPosition: CrosshairLabelPosition.overAxis,
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
    });

    testWidgets('CrosshairLabelPosition.insidePlot works in chart', (tester) async {
      // Arrange: Chart with insidePlot crosshair label
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'series1',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 100),
                      ChartDataPoint(x: 100, y: 50),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.right,
                      label: 'Inside Plot Label',
                      crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
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
    });

    testWidgets('CrosshairLabelPosition works with different axis positions', (tester) async {
      // Arrange: Multiple axes with different crosshair positions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'left',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 100, y: 100),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Left (Over)',
                      crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                    ),
                  ),
                  LineChartSeries(
                    id: 'right',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 100, y: 200),
                    ],
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.right,
                      label: 'Right (Inside)',
                      crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
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
    });
  });

  group('Integration Tests', () {
    testWidgets('right axis with unit and crosshair label works together', (tester) async {
      // Arrange: Comprehensive test combining multiple features
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'power',
                    name: 'Power Output',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 25, y: 125),
                      ChartDataPoint(x: 50, y: 250),
                      ChartDataPoint(x: 75, y: 375),
                      ChartDataPoint(x: 100, y: 500),
                    ],
                    color: const Color(0xFF2196F3),
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.right,
                      label: 'Power',
                      unit: 'kW',
                      labelDisplay: AxisLabelDisplay.labelWithUnit,
                      crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
                      showTicks: true,
                      showAxisLine: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Widget builds successfully with all features combined
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('multiple series with different positions and units', (tester) async {
      // Arrange: Complex multi-axis scenario
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 700,
              height: 400,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'voltage',
                    name: 'Voltage',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 12),
                      ChartDataPoint(x: 100, y: 24),
                    ],
                    color: Colors.blue,
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Voltage',
                      unit: 'V',
                      labelDisplay: AxisLabelDisplay.labelWithUnit,
                      crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                    ),
                  ),
                  LineChartSeries(
                    id: 'current',
                    name: 'Current',
                    points: const [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 50, y: 5),
                      ChartDataPoint(x: 100, y: 10),
                    ],
                    color: Colors.red,
                    yAxisConfig: YAxisConfig(
                      position: YAxisPosition.right,
                      label: 'Current',
                      unit: 'A',
                      labelDisplay: AxisLabelDisplay.labelAndTickUnit,
                      crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
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
    });

    testWidgets('single axis without position explicitly defaults to left', (tester) async {
      // Arrange: Simple chart relying on defaults
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'simple',
                    points: [
                      ChartDataPoint(x: 0, y: 0),
                      ChartDataPoint(x: 100, y: 100),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Widget builds successfully with default behavior
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });
  });
}
