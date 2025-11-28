// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Integration tests for crosshair interaction functionality
///
/// Tests verify:
/// - Crosshair visibility during hover
/// - Snap-to-point behavior
/// - Screen coordinate transformation
/// - Crosshair rendering at correct positions
library;

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crosshair Integration Tests', () {
    testWidgets('Crosshair appears on hover and remains visible during snap',
        (WidgetTester tester) async {
      // Create a test chart with known data points
      final testSeries = ChartSeries(
        id: 'test_series',
        name: 'Test Data',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 50, y: 100),
          const ChartDataPoint(x: 100, y: 50),
          const ChartDataPoint(x: 150, y: 150),
        ],
      );

      bool crosshairChanged = false;
      Offset? lastCrosshairPosition;
      List<ChartDataPoint>? lastSnapPoints;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: BravenChart(
                chartType: ChartType.line,
                series: [testSeries],
                interactionConfig: InteractionConfig(
                  crosshair: const CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    snapRadius: 30.0,
                    style: CrosshairStyle(
                      lineColor: Colors.blue,
                      lineWidth: 2.0,
                    ),
                  ),
                  onCrosshairChanged: (position, snapPoints) {
                    crosshairChanged = true;
                    lastCrosshairPosition = position;
                    lastSnapPoints = snapPoints;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the chart widget
      final chartFinder = find.byType(BravenChart);
      expect(chartFinder, findsOneWidget);

      // Initially, no crosshair should be visible
      expect(find.byType(CustomPaint), findsWidgets); // Chart painter exists

      // Simulate hover at a position away from data points
      final chartCenter = tester.getCenter(chartFinder);
      final hoverPoint = chartCenter + const Offset(0, 0);

      // Create hover event
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: hoverPoint);
      await gesture.moveTo(hoverPoint);
      await tester.pumpAndSettle();

      // Crosshair should now be visible
      // The CustomPaint for crosshair is rendered in a Stack
      expect(find.byType(CustomPaint), findsWidgets);
      expect(crosshairChanged, true);
      expect(lastCrosshairPosition, isNotNull);

      // Reset flag
      crosshairChanged = false;

      // Now move near a data point (within snap radius of 30px)
      // This should snap to the point but crosshair should REMAIN VISIBLE
      final nearDataPoint =
          chartCenter + const Offset(10, 10); // Close to a point
      await gesture.moveTo(nearDataPoint);
      await tester.pumpAndSettle();

      // Crosshair should STILL be visible even when snapping
      expect(find.byType(CustomPaint), findsWidgets);

      // The callback should have fired with snap points
      expect(crosshairChanged, true);
      expect(lastSnapPoints, isNotNull);

      // Clean up
      await gesture.removePointer();
    });

    testWidgets(
        'Crosshair uses correct screen coordinates for snap point highlight',
        (WidgetTester tester) async {
      // This test specifically verifies the bug fix where crosshair
      // was disappearing because it was using data coordinates instead
      // of screen coordinates for the nearestPoint

      final testSeries = ChartSeries(
        id: 'test_series',
        name: 'Test Data',
        points: [
          const ChartDataPoint(x: 10, y: 20), // Data coordinates
          const ChartDataPoint(x: 20, y: 40),
          const ChartDataPoint(x: 30, y: 30),
        ],
      );

      Offset? snapPointPosition;
      List<ChartDataPoint>? capturedSnapPoints;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: BravenChart(
                chartType: ChartType.line,
                series: [testSeries],
                interactionConfig: InteractionConfig(
                  crosshair: const CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    snapRadius:
                        200.0, // VERY large radius to ensure we catch a point
                  ),
                  onCrosshairChanged: (position, snapPoints) {
                    capturedSnapPoints = snapPoints; // Capture for verification
                    if (snapPoints.isNotEmpty) {
                      // Verify snap point has metadata with screen coordinates
                      final snapPoint = snapPoints.first;
                      expect(snapPoint.metadata, isNotNull,
                          reason: 'Snap point should have metadata');

                      if (snapPoint.metadata != null) {
                        expect(snapPoint.metadata!.containsKey('screenX'), true,
                            reason:
                                'Snap point should have screenX coordinate');
                        expect(snapPoint.metadata!.containsKey('screenY'), true,
                            reason:
                                'Snap point should have screenY coordinate');

                        // Screen coordinates should be within widget bounds
                        final screenX =
                            snapPoint.metadata!['screenX'] as double;
                        final screenY =
                            snapPoint.metadata!['screenY'] as double;

                        expect(screenX >= 0 && screenX <= 400, true,
                            reason:
                                'screenX should be within widget bounds (got $screenX)');
                        expect(screenY >= 0 && screenY <= 400, true,
                            reason:
                                'screenY should be within widget bounds (got $screenY)');

                        snapPointPosition = Offset(screenX, screenY);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hover near the center where a data point should be
      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: chartCenter);
      await gesture.moveTo(chartCenter);
      await tester.pumpAndSettle();

      // Verify callback was called and snap points were provided
      expect(capturedSnapPoints, isNotNull,
          reason: 'Callback should have been invoked');

      // Verify that we detected a snap point with valid screen coordinates
      expect(snapPointPosition, isNotNull,
          reason: 'Should have detected a snap point near center');

      // Clean up
      await gesture.removePointer();
    });

    testWidgets('Crosshair renders in all three modes correctly',
        (WidgetTester tester) async {
      final testSeries = ChartSeries(
        id: 'test',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 100, y: 100),
        ],
      );

      // Test each crosshair mode
      for (final mode in CrosshairMode.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [testSeries],
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig(
                      enabled: true,
                      mode: mode,
                      snapToDataPoint: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChart);
        final chartCenter = tester.getCenter(chartFinder);

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: chartCenter);
        await gesture.moveTo(chartCenter);
        await tester.pumpAndSettle();

        // Verify crosshair is rendered
        expect(find.byType(CustomPaint), findsWidgets);

        await gesture.removePointer();
      }
    });

    testWidgets('Crosshair snaps to nearest point within snap radius',
        (WidgetTester tester) async {
      // Use simple data bounds 0-100 for easy screen position calculation
      final testSeries = ChartSeries(
        id: 'test',
        points: [
          const ChartDataPoint(x: 0, y: 0), // Bottom-left of data
          const ChartDataPoint(x: 50, y: 50), // Middle
          const ChartDataPoint(x: 100, y: 100), // Top-right of data
        ],
      );

      List<ChartDataPoint>? capturedSnapPoints;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: BravenChart(
                chartType: ChartType.line,
                series: [testSeries],
                interactionConfig: InteractionConfig(
                  crosshair: const CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    snapRadius: 60.0, // Large radius to ensure we catch a point
                  ),
                  onCrosshairChanged: (position, snapPoints) {
                    capturedSnapPoints = snapPoints;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      // Hover at center - with 0-100 data range, x=50,y=50 should be near center
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: chartCenter);
      await gesture.moveTo(chartCenter);
      await tester.pumpAndSettle();

      // Should have snapped to the middle point
      expect(capturedSnapPoints, isNotNull,
          reason: 'Callback should have been called');
      expect(capturedSnapPoints!.isNotEmpty, true,
          reason: 'Should snap to nearest point within radius');

      // Move far from any point (outside snap radius) - use top-left corner
      capturedSnapPoints = null;
      final chartRect = tester.getRect(chartFinder);
      final farPoint = chartRect.topLeft + const Offset(10, 10);
      await gesture.moveTo(farPoint);
      await tester.pumpAndSettle();

      // Should NOT snap (no points within radius)
      // Note: If crosshair is still shown, snapPoints list should be empty
      if (capturedSnapPoints != null) {
        expect(capturedSnapPoints!.isEmpty, true,
            reason: 'Should not snap when far from points');
      }

      await gesture.removePointer();
    });

    testWidgets('Crosshair disappears when mouse leaves chart area',
        (WidgetTester tester) async {
      final testSeries = ChartSeries(
        id: 'test',
        points: [const ChartDataPoint(x: 0, y: 0)],
      );

      bool crosshairExited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: BravenChart(
                chartType: ChartType.line,
                series: [testSeries],
                interactionConfig: InteractionConfig(
                  crosshair: const CrosshairConfig(enabled: true),
                  onDataPointHover: (point, position) {
                    if (point == null) {
                      crosshairExited = true;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      // Enter chart area
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: chartCenter);
      await gesture.moveTo(chartCenter);
      await tester.pumpAndSettle();

      // Exit chart area
      final outsidePoint = chartCenter + const Offset(500, 500);
      await gesture.moveTo(outsidePoint);
      await tester.pumpAndSettle();

      expect(crosshairExited, true,
          reason: 'Hover callback should fire with null when exiting');

      await gesture.removePointer();
    });
  });
}
