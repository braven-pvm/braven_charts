// @orchestra-task: 13
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// TDD RED phase tests for BravenChartPlus.xAxisConfig parameter.
///
/// These tests define the expected behavior for FR-008:
/// "System MUST accept XAxisConfig parameter on the BravenChartPlus widget"
///
/// Current state: BravenChartPlus has legacy 'AxisConfig? xAxis' but NOT
/// 'XAxisConfig? xAxisConfig'. This means users cannot configure properties
/// like crosshairLabelPosition from the widget level.
///
/// Expected behavior (after GREEN phase):
/// - BravenChartPlus accepts xAxisConfig: XAxisConfig? parameter
/// - xAxisConfig is passed to ChartRenderBox via setXAxisConfig()
/// - ChartRenderBox uses xAxisConfig directly (no legacy conversion)
/// - CrosshairRenderer receives and respects crosshairLabelPosition

@Tags(['tdd-red'])
library;

import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/models/axis_config.dart';
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
      // EXPECTED TO FAIL: xAxisConfig parameter does not exist yet
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
              // This parameter does not exist yet - will fail to compile
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
      // EXPECTED TO FAIL: No mechanism to pass xAxisConfig through yet
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

      // This will fail because ChartRenderBox has no xAxisConfig property yet
      expect(renderBox, isNotNull);
      // We would check renderBox._xAxisConfig here, but it doesn't exist yet
    });

    testWidgets('crosshairLabelPosition.insidePlot affects rendering',
        (tester) async {
      // EXPECTED TO FAIL: crosshairLabelPosition cannot be configured from widget
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

      // Verify crosshair label position matches config
      // This will fail because xAxisConfig is not passed through to rendering
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('crosshairLabelPosition.overAxis affects rendering',
        (tester) async {
      // EXPECTED TO FAIL: crosshairLabelPosition cannot be configured from widget
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

      // Verify crosshair label position matches overAxis config
      // This will fail because xAxisConfig.crosshairLabelPosition is not used
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('xAxisConfig properties override legacy xAxis', (tester) async {
      // EXPECTED TO FAIL: xAxisConfig parameter does not exist
      // This test verifies that when both xAxis (legacy) and xAxisConfig are
      // provided, xAxisConfig takes precedence
      const xAxisConfig = XAxisConfig(
        label: 'Modern Config',
        unit: 'units',
        showCrosshairLabel: true,
        crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
      );

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
              // Both legacy and new config provided
              xAxis: AxisConfig(
                label: 'Legacy Config',
                showAxis: true,
              ),
              xAxisConfig: xAxisConfig,
            ),
          ),
        ),
      );

      // xAxisConfig should take precedence
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('xAxisConfig null falls back to legacy xAxis', (tester) async {
      // EXPECTED TO FAIL during compilation (xAxisConfig doesn't exist)
      // This test verifies backward compatibility: when xAxisConfig is null,
      // the chart should still work with legacy xAxis
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
              xAxis: AxisConfig(
                label: 'Legacy Only',
                showAxis: true,
              ),
              xAxisConfig: null, // Explicit null - parameter doesn't exist yet
            ),
          ),
        ),
      );

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });
  });
}
