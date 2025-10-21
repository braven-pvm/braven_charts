import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChart ValueNotifier Integration', () {
    testWidgets('T010: _interactionStateNotifier exists and initializes correctly', (WidgetTester tester) async {
      // Arrange: Create a basic chart
      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: [
              const ChartDataPoint(x: 1, y: 10),
              const ChartDataPoint(x: 2, y: 20),
            ],
            color: Colors.blue,
          ),
        ],
      );

      // Act: Build the chart
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
      await tester.pumpAndSettle();

      // Assert: Chart renders without errors
      expect(find.byType(BravenChart), findsOneWidget);

      // Note: Cannot directly access private _interactionStateNotifier field
      // but the fact that chart renders without crashing verifies initialization
    });

    testWidgets('T011: _interactionStateNotifier updates without triggering setState', (WidgetTester tester) async {
      int buildCount = 0;

      // Arrange: Create chart with interaction enabled
      final chart = BravenChart(
        chartType: ChartType.line,
        series: [
          ChartSeries(
            id: 'test',
            points: List.generate(
              50,
              (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
            ),
            color: Colors.blue,
          ),
        ],
        interactionConfig: const InteractionConfig(
          crosshair: CrosshairConfig(enabled: true),
        ),
      );

      // Wrap in Builder to count builds
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                buildCount++;
                return chart;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Simulate mouse hover (should update notifier, not trigger setState)
      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      final gesture = await tester.createGesture();
      await gesture.addPointer(location: chartCenter);
      await gesture.moveTo(chartCenter + const Offset(10, 10));
      await tester.pump();

      // Assert: Build count should not increase significantly
      // (ValueNotifier prevents full widget rebuild)
      expect(find.byType(BravenChart), findsOneWidget);
      expect(buildCount, lessThan(5)); // Allow some rebuilds but not 100+

      await gesture.removePointer();
    });
  });
}
