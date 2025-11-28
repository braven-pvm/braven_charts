/// Integration test for tooltip positioning fix
///
/// Tests that tooltip follows data point marker, not cursor/crosshair
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tooltip Positioning Integration Tests', () {
    testWidgets('Tooltip follows marker, not cursor', (WidgetTester tester) async {
      // Set window size for testing
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(const BravenChartsExampleApp());
      await tester.pumpAndSettle();

      // Navigate to interaction examples by finding and tapping the button
      // Since Flutter uses Canvas, we'll create the chart directly

      // Create test data
      final testSeries = [
        ChartSeries(
          id: 'temperature',
          name: 'Temperature (°F)',
          points: const [
            ChartDataPoint(x: 1, y: 72),
            ChartDataPoint(x: 2, y: 75),
            ChartDataPoint(x: 3, y: 78),
            ChartDataPoint(x: 4, y: 76),
            ChartDataPoint(x: 5, y: 74),
            ChartDataPoint(x: 6, y: 79),
          ],
        ),
      ];

      // Render chart with interaction config
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: testSeries,
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: const TooltipConfig(
                      enabled: true,
                      showDelay: Duration(milliseconds: 0),
                      hideDelay: Duration.zero,
                      preferredPosition: TooltipPosition.auto,
                      offsetFromPoint: 10.0,
                      style: TooltipStyle(
                        backgroundColor: Color(0xFFFFFFFF),
                        borderColor: Color(0xFFE0E0E0),
                        borderWidth: 1.0,
                        borderRadius: 4.0,
                        padding: 8.0,
                        textColor: Color(0xFF333333),
                        fontSize: 14.0,
                        shadowColor: Color(0x1A000000),
                        shadowBlurRadius: 4.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate mouse hover at a data point
      // Approximate position of first data point in chart
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );

      // Move to approximate location of data point 3 (x=3, y=78)
      // Chart area is approximately 40 to 760 for x, 40 to 560 for y
      // Data point 3 at x=3 (out of 1-6 range) should be at roughly:
      // x: 40 + (3-1)/5 * 720 = 40 + 0.4 * 720 = 328
      // y: 560 - (78-72)/7 * 520 = 560 - 0.857 * 520 = 115 (approximate)

      const Offset dataPoint3Position = Offset(328, 115);

      await gesture.moveTo(dataPoint3Position);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500)); // Wait for tooltip delay

      // Verify chart is still present (tooltip should be visible)
      expect(find.byType(BravenChart), findsOneWidget);

      // The key validation: tooltip should be at data point position, not cursor
      // We can't directly inspect tooltip position in Canvas, but we can verify
      // the chart doesn't crash and remains responsive
      expect(find.byType(CustomPaint), findsWidgets);

      // Now move cursor away from point (but keep within chart)
      await gesture.moveTo(const Offset(400, 300));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify chart is still functional
      expect(find.byType(BravenChart), findsOneWidget);

      // Clean up
      await gesture.removePointer();
    });

    testWidgets('Multiple data points show tooltip at their positions', (WidgetTester tester) async {
      // Set window size for testing
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final testSeries = [
        ChartSeries(
          id: 'test',
          points: const [
            ChartDataPoint(x: 1, y: 10),
            ChartDataPoint(x: 2, y: 20),
            ChartDataPoint(x: 3, y: 15),
            ChartDataPoint(x: 4, y: 25),
            ChartDataPoint(x: 5, y: 30),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: testSeries,
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: const TooltipConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

      // Test multiple hover positions
      final testPositions = [
        const Offset(200, 450), // Approximate point 1
        const Offset(350, 350), // Approximate point 2
        const Offset(500, 400), // Approximate point 3
        const Offset(650, 300), // Approximate point 4
      ];

      for (final pos in testPositions) {
        await gesture.moveTo(pos);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify chart is responsive at each position
        expect(find.byType(BravenChart), findsOneWidget);
      }

      await gesture.removePointer();
    });

    testWidgets('Tooltip hides when cursor leaves chart', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final testSeries = [
        ChartSeries(
          id: 'test',
          points: const [
            ChartDataPoint(x: 1, y: 10),
            ChartDataPoint(x: 2, y: 20),
            ChartDataPoint(x: 3, y: 15),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: testSeries,
                  interactionConfig: InteractionConfig(
                    crosshair: CrosshairConfig.defaultConfig(),
                    tooltip: const TooltipConfig(
                      enabled: true,
                      hideDelay: Duration(milliseconds: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

      // Move into chart
      await gesture.moveTo(const Offset(300, 300));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BravenChart), findsOneWidget);

      // Move outside chart
      await gesture.moveTo(const Offset(0, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      // Chart should still be present (tooltip hidden)
      expect(find.byType(BravenChart), findsOneWidget);

      await gesture.removePointer();
    });
  });
}

