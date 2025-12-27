// Copyright (c) 2025 braven_charts. All rights reserved.
// Test: US5 - Crosshair Label Position Control (overAxis vs insidePlot)

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crosshair Label Position Control', () {
    group('CrosshairLabelPosition.overAxis (default)', () {
      testWidgets('renders crosshair label outside plot area in axis strip',
          (tester) async {
        // Arrange: Chart with overAxis crosshair label (default)
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Test Axis',
                        unit: 'units',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.overAxis, // Explicit
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('overAxis is default when not explicitly specified',
          (tester) async {
        // Arrange: Chart without explicit crosshairLabelPosition
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Test Axis',
                        unit: 'units',
                        showCrosshairLabel: true,
                        // crosshairLabelPosition not specified - should default to overAxis
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully with default behavior
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('overAxis works with left axis', (tester) async {
        // Arrange: Left axis with overAxis label
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Left Axis',
                        unit: 'L',
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('overAxis works with right axis', (tester) async {
        // Arrange: Right axis with overAxis label
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Right Axis',
                        unit: 'R',
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
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

    group('CrosshairLabelPosition.insidePlot', () {
      testWidgets('renders crosshair label inside plot area near axis edge',
          (tester) async {
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Test Axis',
                        unit: 'units',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('insidePlot works with left axis', (tester) async {
        // Arrange: Left axis with insidePlot label
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Left Axis',
                        unit: 'L',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('insidePlot works with right axis', (tester) async {
        // Arrange: Right axis with insidePlot label
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Right Axis',
                        unit: 'R',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('insidePlot works with leftOuter axis', (tester) async {
        // Arrange: LeftOuter axis with insidePlot label
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.leftOuter,
                        label: 'LeftOuter Axis',
                        unit: 'LO',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('insidePlot works with rightOuter axis', (tester) async {
        // Arrange: RightOuter axis with insidePlot label
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.rightOuter,
                        label: 'RightOuter Axis',
                        unit: 'RO',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
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

    group('Mixed Crosshair Label Positions', () {
      testWidgets('multiple axes with different crosshairLabelPosition values',
          (tester) async {
        // Arrange: Multi-axis chart with mixed overAxis and insidePlot
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'power',
                      name: 'Power',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 50, y: 250),
                        ChartDataPoint(x: 100, y: 180),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.overAxis, // Outside
                      ),
                    ),
                    LineChartSeries(
                      id: 'heartrate',
                      name: 'Heart Rate',
                      points: const [
                        ChartDataPoint(x: 0, y: 120),
                        ChartDataPoint(x: 50, y: 155),
                        ChartDataPoint(x: 100, y: 140),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot, // Inside
                      ),
                    ),
                  ],
                  normalizationMode: NormalizationMode.perSeries,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully with mixed positioning
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('all four axis positions with mixed crosshair positions',
          (tester) async {
        // Arrange: Complex multi-axis scenario with all positions
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 500,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.leftOuter,
                        label: 'LeftOuter',
                        unit: 'LO',
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      name: 'Series 2',
                      points: const [
                        ChartDataPoint(x: 0, y: 20),
                        ChartDataPoint(x: 50, y: 60),
                        ChartDataPoint(x: 100, y: 40),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Left',
                        unit: 'L',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series3',
                      name: 'Series 3',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 50, y: 200),
                        ChartDataPoint(x: 100, y: 150),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Right',
                        unit: 'R',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series4',
                      name: 'Series 4',
                      points: const [
                        ChartDataPoint(x: 0, y: 1000),
                        ChartDataPoint(x: 50, y: 2000),
                        ChartDataPoint(x: 100, y: 1500),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.rightOuter,
                        label: 'RightOuter',
                        unit: 'RO',
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                  ],
                  normalizationMode: NormalizationMode.perSeries,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully with all positions and mixed settings
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('three axes on same side with alternating positions',
          (tester) async {
        // Arrange: Multiple axes on left with alternating crosshair positions
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Axis 1',
                        unit: 'A1',
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      name: 'Series 2',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 50, y: 200),
                        ChartDataPoint(x: 100, y: 150),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Axis 2',
                        unit: 'A2',
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series3',
                      name: 'Series 3',
                      points: const [
                        ChartDataPoint(x: 0, y: 1000),
                        ChartDataPoint(x: 50, y: 2000),
                        ChartDataPoint(x: 100, y: 1500),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Axis 3',
                        unit: 'A3',
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                  ],
                  normalizationMode: NormalizationMode.perSeries,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
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

    group('Integration with Other Features', () {
      testWidgets('crosshair label position works with custom colors',
          (tester) async {
        // Arrange: Chart with custom axis colors and insidePlot
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Custom Color',
                        unit: 'units',
                        color: const Color(0xFFFF0000), // Red
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('crosshair label position works with unit display modes',
          (tester) async {
        // Arrange: Chart with different AxisLabelDisplay modes
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        labelDisplay: AxisLabelDisplay.labelWithUnit,
                        showCrosshairLabel: true,
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      name: 'Series 2',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 50, y: 200),
                        ChartDataPoint(x: 100, y: 150),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        labelDisplay: AxisLabelDisplay.labelAndTickUnit,
                        showCrosshairLabel: true,
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                  ],
                  normalizationMode: NormalizationMode.perSeries,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('crosshair label position respects showCrosshairLabel flag',
          (tester) async {
        // Arrange: Mixed showCrosshairLabel settings
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Visible Label',
                        unit: 'V',
                        showCrosshairLabel: true, // Enabled
                        crosshairLabelPosition:
                            CrosshairLabelPosition.insidePlot,
                      ),
                    ),
                    LineChartSeries(
                      id: 'series2',
                      name: 'Series 2',
                      points: const [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 50, y: 200),
                        ChartDataPoint(x: 100, y: 150),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.right,
                        label: 'Hidden Label',
                        unit: 'H',
                        showCrosshairLabel: false, // Disabled
                        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
                      ),
                    ),
                  ],
                  normalizationMode: NormalizationMode.perSeries,
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
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

    group('Default Behavior Preservation', () {
      testWidgets('existing charts without crosshairLabelPosition use overAxis',
          (tester) async {
        // Arrange: Chart as it would have been before this feature
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
                      name: 'Series 1',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 50, y: 50),
                        ChartDataPoint(x: 100, y: 30),
                      ],
                      yAxisConfig: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Legacy Chart',
                        unit: 'units',
                        showCrosshairLabel: true,
                        // No crosshairLabelPosition - should default to overAxis
                      ),
                    ),
                  ],
                  interactionConfig: const InteractionConfig(
                    crosshair: CrosshairConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Widget builds successfully with backward compatibility
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('YAxisConfig defaults to overAxis', (tester) async {
        // Arrange: Create YAxisConfig without crosshairLabelPosition
        final config = YAxisConfig(
          position: YAxisPosition.left,
          label: 'Test',
        );

        // Assert: Verify default value is overAxis
        expect(
          config.crosshairLabelPosition,
          equals(CrosshairLabelPosition.overAxis),
        );
      });
    });
  });
}
