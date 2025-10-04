import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Integration test utilities for end-to-end testing
class IntegrationTestUtils {
  static late IntegrationTestWidgetsFlutterBinding binding;

  /// Initialize integration testing
  static void initialize() {
    binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Creates a test app with charts for integration testing
  static Widget createTestApp({
    required Widget chart,
    String title = 'Braven Charts Test',
  }) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 400,
                child: chart,
              ),
              const SizedBox(height: 20),
              // Add test controls
              _buildTestControls(),
            ],
          ),
        ),
      ),
    );
  }

  /// Test chart interactions (tap, pan, zoom)
  static Future<void> testChartInteractions({
    required WidgetTester tester,
    required Finder chartFinder,
  }) async {
    // Test tap interaction
    await tester.tap(chartFinder);
    await tester.pumpAndSettle();

    // Test pan gesture
    await tester.drag(chartFinder, const Offset(100, 0));
    await tester.pumpAndSettle();

    // Test zoom gesture (pinch)
    final center = tester.getCenter(chartFinder);
    final gesture1 = await tester.startGesture(center);
    final gesture2 = await tester.startGesture(center);

    await gesture1.moveBy(const Offset(-50, 0));
    await gesture2.moveBy(const Offset(50, 0));
    await tester.pumpAndSettle();

    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();
  }

  /// Test chart data updates
  static Future<void> testDataUpdates({
    required WidgetTester tester,
    required List<Future<void> Function()> dataUpdateActions,
  }) async {
    for (final action in dataUpdateActions) {
      await action();
      await tester.pumpAndSettle();

      // Verify chart updated
      expect(find.byType(CustomPaint), findsWidgets);
    }
  }

  /// Test chart responsiveness across different screen sizes
  static Future<void> testResponsiveness({
    required WidgetTester tester,
    required Widget chart,
  }) async {
    final sizes = [
      const Size(320, 568), // iPhone SE
      const Size(375, 667), // iPhone 8
      const Size(414, 896), // iPhone 11 Pro Max
      const Size(768, 1024), // iPad
      const Size(1366, 768), // Desktop
    ];

    for (final size in sizes) {
      binding.window.physicalSizeTestValue = size;
      binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(createTestApp(chart: chart));
      await tester.pumpAndSettle();

      // Verify chart renders correctly at this size
      expect(find.byWidget(chart), findsOneWidget);

      // Take screenshot for manual verification
      await binding.takeScreenshot('chart_${size.width.toInt()}x${size.height.toInt()}');
    }

    // Reset to default
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  }

  /// Test accessibility features
  static Future<void> testAccessibility({
    required WidgetTester tester,
    required Widget chart,
  }) async {
    await tester.pumpWidget(createTestApp(chart: chart));
    await tester.pumpAndSettle();

    // Test semantic labels
    expect(find.bySemanticsLabel(RegExp(r'Chart|Graph')), findsWidgets);

    // Test keyboard navigation
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // Test screen reader announcements
    final semantics = tester.binding.pipelineOwner.semanticsOwner;
    expect(semantics, isNotNull);
  }

  /// Test performance under stress
  static Future<void> testPerformanceStress({
    required WidgetTester tester,
    required Widget Function(List<Map<String, dynamic>>) chartBuilder,
  }) async {
    final largeSizes = [1000, 5000, 10000];

    for (final size in largeSizes) {
      final data = List.generate(
          size,
          (i) => {
                'x': i.toDouble(),
                'y': (i * 0.1) % 100,
                'label': 'Point $i',
              });

      final chart = chartBuilder(data);
      await tester.pumpWidget(createTestApp(chart: chart));

      // Measure frame build time
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify reasonable performance (less than 500ms for initial render)
      expect(stopwatch.elapsedMilliseconds, lessThan(500), reason: 'Chart with $size points took too long to render');

      // Test interaction performance
      final chartFinder = find.byWidget(chart);
      await tester.drag(chartFinder, const Offset(100, 0));
      await tester.pumpAndSettle();
    }
  }

  /// Test error handling and edge cases
  static Future<void> testErrorHandling({
    required WidgetTester tester,
    required Widget Function(List<Map<String, dynamic>>?) chartBuilder,
  }) async {
    // Test with null data
    await tester.pumpWidget(createTestApp(chart: chartBuilder(null)));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);

    // Test with empty data
    await tester.pumpWidget(createTestApp(chart: chartBuilder([])));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);

    // Test with invalid data
    final invalidData = [
      {'x': 'invalid', 'y': double.nan},
      {'x': double.infinity, 'y': null},
    ];
    await tester.pumpWidget(createTestApp(chart: chartBuilder(invalidData)));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  }

  static Widget _buildTestControls() {
    return Column(
      children: [
        ElevatedButton(
          key: const Key('refresh_data_button'),
          onPressed: () {
            // Refresh data action
          },
          child: const Text('Refresh Data'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          key: const Key('toggle_theme_button'),
          onPressed: () {
            // Toggle theme action
          },
          child: const Text('Toggle Theme'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          key: const Key('add_annotation_button'),
          onPressed: () {
            // Add annotation action
          },
          child: const Text('Add Annotation'),
        ),
      ],
    );
  }
}
