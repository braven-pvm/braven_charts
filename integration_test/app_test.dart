import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/integration/integration_test_utils.dart';

/// Example integration tests for Braven Charts
/// 
/// Run with: flutter test integration_test/
void main() {
  IntegrationTestUtils.initialize();

  group('Braven Charts Integration Tests', () {
    testWidgets('Should render chart in full app context', (tester) async {
      // Create a simple test chart (placeholder)
      final testChart = Container(
        key: const Key('test_chart'),
        height: 300,
        color: Colors.blue.withOpacity(0.1),
        child: const Center(
          child: Text('Test Chart Placeholder'),
        ),
      );

      final app = IntegrationTestUtils.createTestApp(
        chart: testChart,
        title: 'Integration Test Chart',
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Verify chart is rendered
      expect(find.byKey(const Key('test_chart')), findsOneWidget);
      expect(find.text('Integration Test Chart'), findsOneWidget);
      expect(find.text('Test Chart Placeholder'), findsOneWidget);
    });

    testWidgets('Should handle basic interactions', (tester) async {
      final testChart = Container(
        key: const Key('interactive_chart'),
        height: 300,
        color: Colors.green.withOpacity(0.1),
        child: const Center(
          child: Text('Interactive Chart'),
        ),
      );

      await tester.pumpWidget(
        IntegrationTestUtils.createTestApp(chart: testChart),
      );
      await tester.pumpAndSettle();

      final chartFinder = find.byKey(const Key('interactive_chart'));
      
      // Test basic interactions
      await IntegrationTestUtils.testChartInteractions(
        tester: tester,
        chartFinder: chartFinder,
      );

      // Verify chart is still visible after interactions
      expect(chartFinder, findsOneWidget);
    });

    testWidgets('Should work with test controls', (tester) async {
      final testChart = Container(
        key: const Key('controlled_chart'),
        height: 300,
        color: Colors.orange.withOpacity(0.1),
        child: const Center(
          child: Text('Controlled Chart'),
        ),
      );

      await tester.pumpWidget(
        IntegrationTestUtils.createTestApp(chart: testChart),
      );
      await tester.pumpAndSettle();

      // Test control buttons
      await tester.tap(find.byKey(const Key('refresh_data_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_theme_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_annotation_button')));
      await tester.pumpAndSettle();

      // Verify chart is still functional
      expect(find.byKey(const Key('controlled_chart')), findsOneWidget);
    });

    testWidgets('Should handle error conditions gracefully', (tester) async {
      await IntegrationTestUtils.testErrorHandling(
        tester: tester,
        chartBuilder: (data) {
          // Create a chart that handles various data conditions
          return Container(
            key: const Key('error_handling_chart'),
            height: 300,
            color: data == null 
                ? Colors.red.withOpacity(0.1)
                : data.isEmpty 
                    ? Colors.yellow.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
            child: Center(
              child: Text(
                data == null 
                    ? 'No Data' 
                    : data.isEmpty 
                        ? 'Empty Data' 
                        : 'Data: ${data.length} items',
              ),
            ),
          );
        },
      );
    });

    testWidgets('Should be responsive across screen sizes', (tester) async {
      final responsiveChart = Container(
        key: const Key('responsive_chart'),
        height: 300,
        color: Colors.purple.withOpacity(0.1),
        child: const Center(
          child: Text('Responsive Chart'),
        ),
      );

      await IntegrationTestUtils.testResponsiveness(
        tester: tester,
        chart: responsiveChart,
      );
    });

    testWidgets('Should maintain performance with large datasets', (tester) async {
      await IntegrationTestUtils.testPerformanceStress(
        tester: tester,
        chartBuilder: (data) {
          return Container(
            key: Key('performance_chart_${data.length}'),
            height: 300,
            color: Colors.teal.withOpacity(0.1),
            child: Center(
              child: Text('Chart with ${data.length} data points'),
            ),
          );
        },
      );
    });

    testWidgets('Should support accessibility features', (tester) async {
      final accessibleChart = Container(
        key: const Key('accessible_chart'),
        height: 300,
        color: Colors.indigo.withOpacity(0.1),
        child: const Center(
          child: Text(
            'Accessible Chart',
            semanticsLabel: 'Chart showing test data',
          ),
        ),
      );

      await IntegrationTestUtils.testAccessibility(
        tester: tester,
        chart: accessibleChart,
      );
    });
  });
}