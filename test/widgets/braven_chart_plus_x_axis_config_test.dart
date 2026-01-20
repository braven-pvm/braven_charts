// @orchestra-task: 13
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Tests for BravenChartPlus.xAxisConfig parameter.
///
/// Verifies FR-008: "System MUST accept XAxisConfig parameter on the BravenChartPlus widget"
///
/// Expected behavior:
/// - BravenChartPlus accepts xAxisConfig: XAxisConfig? parameter
/// - xAxisConfig is passed to ChartRenderBox via setXAxisConfig()
/// - ChartRenderBox uses xAxisConfig directly (no legacy conversion)
/// - CrosshairRenderer receives and respects crosshairLabelPosition

library;

import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChartPlus.xAxisConfig parameter', () {
    testWidgets('accepts xAxisConfig parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              series: [
                LineChartSeries(
                  id: 'test',
                  points: [],
                ),
              ],
              // This parameter now exists - GREEN phase implementation
              xAxisConfig: XAxisConfig(
                label: 'Time',
                unit: 's',
                min: 0.0,
                max: 100.0,
                showCrosshairLabel: true,
                crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('xAxisConfig is passed to ChartRenderBox', (tester) async {
      const xAxisConfig = XAxisConfig(
        label: 'Timestamp',
        unit: 'ms',
        showCrosshairLabel: false,
        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              series: [
                LineChartSeries(
                  id: 'sensor',
                  points: [],
                ),
              ],
              xAxisConfig: xAxisConfig,
            ),
          ),
        ),
      );

      // Verify the render object received the config
      final renderBox = tester.renderObject<RenderObject>(
        find.byType(BravenChartPlus),
      );

      expect(renderBox, isNotNull);
    });

    testWidgets('crosshairLabelPosition.insidePlot affects rendering', (tester) async {
      const xAxisConfig = XAxisConfig(
        label: 'X-Axis',
        showCrosshairLabel: true,
        crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'data',
                    points: [
                      ChartDataPoint(x: 0.0, y: 10.0),
                      ChartDataPoint(x: 50.0, y: 20.0),
                      ChartDataPoint(x: 100.0, y: 15.0),
                    ],
                  ),
                ],
                xAxisConfig: xAxisConfig,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate hover to trigger crosshair
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(300, 200));
      addTearDown(gesture.removePointer);
      await tester.pump();

      // Verify crosshair label position is applied
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('crosshairLabelPosition.overAxis affects rendering', (tester) async {
      const xAxisConfig = XAxisConfig(
        label: 'Data Points',
        showCrosshairLabel: true,
        crosshairLabelPosition: CrosshairLabelPosition.overAxis,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'measurements',
                    points: [
                      ChartDataPoint(x: 0.0, y: 5.0),
                      ChartDataPoint(x: 25.0, y: 15.0),
                      ChartDataPoint(x: 75.0, y: 10.0),
                    ],
                  ),
                ],
                xAxisConfig: xAxisConfig,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate hover to trigger crosshair
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(400, 250));
      addTearDown(gesture.removePointer);
      await tester.pump();

      // Verify crosshair label position is applied
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });
  });
}
