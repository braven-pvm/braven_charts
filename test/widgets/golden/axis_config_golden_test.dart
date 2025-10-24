import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T032: Golden test - Axis configurations
///
/// Visual regression tests for all 4 axis configuration presets.
/// Ensures axis rendering consistency across code changes.
///
/// Run: flutter test test/widgets/golden/axis_config_golden_test.dart
/// Update: flutter test --update-goldens test/widgets/golden/axis_config_golden_test.dart
void main() {
  group('Axis Configuration Golden Tests', () {
    // Common test data
    final testSeries = [
      ChartSeries(
        id: 'data',
        name: 'Data',
        points: const [
          ChartDataPoint(x: 0, y: 10),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 2, y: 15),
          ChartDataPoint(x: 3, y: 25),
          ChartDataPoint(x: 4, y: 18),
        ],
      ),
    ];

    testWidgets('defaults() preset golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Axis Defaults',
                xAxis: AxisConfig.defaults(),
                yAxis: AxisConfig.defaults(),
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/axis_defaults.png'),
      );
    });

    testWidgets('hidden() preset golden (sparkline)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Axis Hidden (Sparkline)',
                xAxis: AxisConfig.hidden(),
                yAxis: AxisConfig.hidden(),
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/axis_hidden.png'),
      );
    });

    testWidgets('minimal() preset golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Axis Minimal',
                xAxis: AxisConfig.minimal(),
                yAxis: AxisConfig.minimal(),
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/axis_minimal.png'),
      );
    });

    testWidgets('gridOnly() preset golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Grid Only',
                xAxis: AxisConfig.gridOnly(),
                yAxis: AxisConfig.gridOnly(),
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/axis_grid_only.png'),
      );
    });

    testWidgets('Custom axis config golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Custom Axis',
                xAxis: const AxisConfig(
                  label: 'Time (s)',
                  showAxis: true,
                  showLabels: true,
                  showGrid: true,
                ),
                yAxis: const AxisConfig(
                  label: 'Value',
                  showAxis: true,
                  showLabels: true,
                  showGrid: false,
                ),
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/axis_custom.png'),
      );
    });
  });
}
