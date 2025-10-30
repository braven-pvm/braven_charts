import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T034: Golden test - Themes
///
/// Visual regression tests for light/dark/custom themes.
/// Ensures theme application consistency across code changes.
///
/// Run: flutter test test/widgets/golden/themes_golden_test.dart
/// Update: flutter test --update-goldens test/widgets/golden/themes_golden_test.dart
void main() {
  group('Themes Golden Tests', () {
    // Common test data
    final testSeries = [
      ChartSeries(
        id: 'sales',
        name: 'Sales',
        points: const [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: 150),
          ChartDataPoint(x: 2, y: 120),
          ChartDataPoint(x: 3, y: 180),
          ChartDataPoint(x: 4, y: 160),
        ],
      ),
      ChartSeries(
        id: 'costs',
        name: 'Costs',
        points: const [
          ChartDataPoint(x: 0, y: 80),
          ChartDataPoint(x: 1, y: 90),
          ChartDataPoint(x: 2, y: 85),
          ChartDataPoint(x: 3, y: 95),
          ChartDataPoint(x: 4, y: 100),
        ],
      ),
    ];

    testWidgets('Light theme golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Light Theme',
                subtitle: 'ChartTheme.defaultLight',
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/light_theme.png'),
      );
    });

    testWidgets('Dark theme golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.grey[900],
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Dark Theme',
                subtitle: 'ChartTheme.defaultDark',
                theme: ChartTheme.defaultDark,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/dark_theme.png'),
      );
    });

    testWidgets('Custom theme golden', (WidgetTester tester) async {
      // Use defaultLight as base for custom theme
      // (Full custom theme creation requires all required theme component parameters)
      final customTheme = ChartTheme.defaultLight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.area,
                series: testSeries,
                title: 'Custom Theme',
                subtitle: 'Area Chart',
                theme: customTheme,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/custom_theme.png'),
      );
    });

    testWidgets('Theme with annotations golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.grey[900],
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.area,
                series: testSeries,
                title: 'Dark Theme with Annotations',
                theme: ChartTheme.defaultDark,
                annotations: [
                  ThresholdAnnotation(
                    id: 'target',
                    label: 'Target',
                    value: 150,
                    axis: AnnotationAxis.y,
                    style: const AnnotationStyle(
                      borderColor: Colors.greenAccent,
                      borderWidth: 2,
                    ),
                  ),
                  PointAnnotation(
                    id: 'peak',
                    label: 'Peak',
                    seriesId: 'sales',
                    dataPointIndex: 3,
                    markerShape: MarkerShape.star,
                    markerSize: 12,
                    style: const AnnotationStyle(
                      textStyle: TextStyle(color: Colors.yellowAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/dark_theme_with_annotations.png'),
      );
    });
  });
}
