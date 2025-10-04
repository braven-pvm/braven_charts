import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'test_utils.dart';
import 'golden/golden_test_utils.dart';
import 'performance/performance_test_utils.dart';

/// Main test suite runner for Braven Charts
/// 
/// This file demonstrates how to structure comprehensive tests.
/// Run with: flutter test
void main() {
  setUpAll(() async {
    // Initialize golden file testing
    await loadAppFonts();
  });

  group('Braven Charts Test Suite', () {
    group('Unit Tests', () {
      testWidgets('TestUtils should provide test data', (tester) async {
        final data = TestUtils.getTestChartData();
        expect(data, isNotEmpty);
        expect(data.first, containsPair('x', 0));
        expect(data.first, containsPair('y', 10));
      });

      testWidgets('TestUtils should create large datasets', (tester) async {
        final data = TestUtils.getLargeTestDataset(1000);
        expect(data, hasLength(1000));
        expect(data.last, containsPair('x', 999));
      });

      testWidgets('Custom matcher should work for close values', (tester) async {
        expect(3.14159, TestUtils.closeTo(3.14, tolerance: 0.01));
        expect(3.20, isNot(TestUtils.closeTo(3.14, tolerance: 0.01)));
      });
    });

    group('Performance Tests', () {
      testWidgets('Should measure render time', (tester) async {
        var counter = 0;
        final duration = await PerformanceTestUtils.measureRenderTime(
          renderFunction: () {
            counter++;
            // Add a small delay to ensure measurable time
            for (int i = 0; i < 1000; i++) {
              math.sin(i.toDouble());
            }
          },
          iterations: 10, // Reduced iterations for test stability
        );
        
        expect(duration.inMicroseconds, greaterThanOrEqualTo(0));
        expect(counter, 10);
      });

      testWidgets('Should provide performance utilities', (tester) async {
        // Test that performance utilities are available
        expect(PerformanceTestUtils.measureRenderTime, isA<Function>());
        expect(PerformanceTestUtils.measureMemoryUsage, isA<Function>());
        expect(PerformanceTestUtils.benchmarkLargeDataset, isA<Function>());
      });

      testWidgets('Should handle benchmark operations', (tester) async {
        final result = await PerformanceTestUtils.benchmarkLargeDataset(
          operation: (data) {
            // Simple operation that won't cause issues
            return data.length;
          },
          dataSizes: [10, 100], // Smaller sizes for testing
        );
        
        expect(result.dataSizes, containsAll([10, 100]));
        expect(result.getDurationForSize(10), isNotNull);
      });
    });

    group('Golden Tests', () {
      testWidgets('Should configure golden test utilities', (tester) async {
        expect(GoldenTestUtils.chartSmall, const Size(300, 200));
        expect(GoldenTestUtils.chartSizes, hasLength(3));
        
        final wrapper = GoldenTestUtils.materialAppWrapper();
        final wrapped = wrapper(const Text('Test'));
        expect(wrapped, isA<MaterialApp>());
      });
    });

    group('Widget Tests', () {
      testWidgets('Should create test app wrapper', (tester) async {
        final child = const Text('Test Chart');
        final app = TestUtils.createTestApp(child: child);
        
        await tester.pumpWidget(app);
        expect(find.text('Test Chart'), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('Should create minimal test widget', (tester) async {
        final child = const Text('Minimal Test');
        final widget = TestUtils.createMinimalTestWidget(child);
        
        await tester.pumpWidget(widget);
        expect(find.text('Minimal Test'), findsOneWidget);
        expect(find.byType(Directionality), findsOneWidget);
      });
    });

    group('Integration Test Setup', () {
      testWidgets('Should provide test utilities', (tester) async {
        // This verifies that our integration test utilities are properly set up
        expect(TestUtils.getTestChartData, isA<Function>());
        expect(TestUtils.getLargeTestDataset, isA<Function>());
        expect(GoldenTestUtils.testChartForSizes, isA<Function>());
        expect(PerformanceTestUtils.measureRenderTime, isA<Function>());
      });
    });
  });
}
