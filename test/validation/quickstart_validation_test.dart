/// Validation test for quickstart.md code examples.
///
/// This file compiles and tests all code snippets from the quickstart.md
/// to ensure they are syntactically correct and API-compatible.
///
/// @nodoc
library;

// Import src_plus components for multi-axis normalization feature
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sample data for all examples
  final powerData = [
    const ChartDataPoint(x: 0, y: 100),
    const ChartDataPoint(x: 1, y: 150),
    const ChartDataPoint(x: 2, y: 200),
    const ChartDataPoint(x: 3, y: 180),
    const ChartDataPoint(x: 4, y: 220),
  ];

  final heartRateData = [
    const ChartDataPoint(x: 0, y: 120),
    const ChartDataPoint(x: 1, y: 130),
    const ChartDataPoint(x: 2, y: 145),
    const ChartDataPoint(x: 3, y: 140),
    const ChartDataPoint(x: 4, y: 155),
  ];

  final volumeData = [
    const ChartDataPoint(x: 0, y: 0.5),
    const ChartDataPoint(x: 1, y: 1.2),
    const ChartDataPoint(x: 2, y: 2.5),
    const ChartDataPoint(x: 3, y: 3.0),
    const ChartDataPoint(x: 4, y: 3.8),
  ];

  final veData = [
    const ChartDataPoint(x: 0, y: 40),
    const ChartDataPoint(x: 1, y: 50),
    const ChartDataPoint(x: 2, y: 65),
  ];

  final tvData = [
    const ChartDataPoint(x: 0, y: 0.5),
    const ChartDataPoint(x: 1, y: 1.0),
    const ChartDataPoint(x: 2, y: 1.5),
  ];

  final rfData = [
    const ChartDataPoint(x: 0, y: 15),
    const ChartDataPoint(x: 1, y: 18),
    const ChartDataPoint(x: 2, y: 22),
  ];

  group('Quickstart.md Code Examples Validation', () {
    testWidgets('Basic Multi-Axis Chart example compiles and renders', (tester) async {
      // From quickstart.md: "Basic Multi-Axis Chart" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              yAxes: const [
                YAxisConfig(
                  id: 'power',
                  position: YAxisPosition.left,
                  color: Colors.blue,
                  label: 'Power',
                  unit: 'W',
                ),
                YAxisConfig(
                  id: 'heartRate',
                  position: YAxisPosition.right,
                  color: Colors.red,
                  label: 'Heart Rate',
                  unit: 'bpm',
                ),
              ],
              series: [
                LineChartSeries(
                  id: 'power',
                  yAxisId: 'power', // Bind to power axis
                  points: powerData,
                  color: Colors.blue,
                ),
                LineChartSeries(
                  id: 'hr',
                  yAxisId: 'heartRate', // Bind to heart rate axis
                  points: heartRateData,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Auto-Detection Mode example compiles and renders', (tester) async {
      // From quickstart.md: "Auto-Detection Mode" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              normalizationMode: NormalizationMode.auto, // Detects when ranges differ >10x
              series: [
                LineChartSeries(id: 'power', points: powerData), // 0-300W
                LineChartSeries(id: 'volume', points: volumeData), // 0.5-4L
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Four-Axis Chart example compiles and renders', (tester) async {
      // From quickstart.md: "Four-Axis Chart" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              yAxes: const [
                YAxisConfig(id: 'ventilation', position: YAxisPosition.leftOuter, unit: 'L/min'),
                YAxisConfig(id: 'tidalVolume', position: YAxisPosition.left, unit: 'L'),
                YAxisConfig(id: 'power', position: YAxisPosition.right, unit: 'W'),
                YAxisConfig(id: 'respRate', position: YAxisPosition.rightOuter, unit: 'bpm'),
              ],
              series: [
                LineChartSeries(id: 've', yAxisId: 'ventilation', points: veData),
                LineChartSeries(id: 'tv', yAxisId: 'tidalVolume', points: tvData),
                LineChartSeries(id: 'power', yAxisId: 'power', points: powerData),
                LineChartSeries(id: 'rf', yAxisId: 'respRate', points: rfData),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Sharing an Axis example compiles and renders', (tester) async {
      // From quickstart.md: "Sharing an Axis" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              yAxes: const [
                YAxisConfig(id: 'percentage', position: YAxisPosition.left, unit: '%'),
              ],
              series: [
                LineChartSeries(id: 'cpu', yAxisId: 'percentage', points: powerData),
                LineChartSeries(id: 'memory', yAxisId: 'percentage', points: heartRateData), // Same axis
                LineChartSeries(id: 'disk', yAxisId: 'percentage', points: volumeData), // Same axis
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Explicit Bounds example compiles', (tester) async {
      // From quickstart.md: "Explicit Bounds" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              yAxes: const [
                YAxisConfig(
                  id: 'heartRate',
                  position: YAxisPosition.right,
                  min: 50, // Always start at 50 bpm
                  max: 200, // Always end at 200 bpm
                ),
              ],
              series: [
                LineChartSeries(id: 'hr', yAxisId: 'heartRate', points: heartRateData),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Custom Formatting example compiles', (tester) async {
      // From quickstart.md: "Custom Formatting" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              yAxes: [
                YAxisConfig(
                  id: 'temperature',
                  position: YAxisPosition.left,
                  labelFormatter: (value) => '${value.toStringAsFixed(1)}°C',
                ),
              ],
              series: [
                LineChartSeries(id: 'temp', yAxisId: 'temperature', points: powerData),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Migration Guide - no changes required for single-axis', (tester) async {
      // From quickstart.md: "Migration Guide" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                LineChartSeries(id: 'series1', points: powerData),
                LineChartSeries(id: 'series2', points: heartRateData),
              ], // All use primary axis
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('Migration Guide - adding a second axis', (tester) async {
      // From quickstart.md: "Adding a Second Axis" section
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              yAxes: const [
                YAxisConfig(id: 'primary', position: YAxisPosition.left),
                YAxisConfig(id: 'secondary', position: YAxisPosition.right),
              ],
              series: [
                LineChartSeries(id: 's1', yAxisId: 'primary', points: powerData),
                LineChartSeries(id: 's2', yAxisId: 'secondary', points: heartRateData),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    test('YAxisConfig has all documented properties', () {
      // Validate all documented properties exist
      final config = const YAxisConfig(
        id: 'test',
        position: YAxisPosition.left,
        color: Colors.blue,
        label: 'Test Label',
        unit: 'units',
        min: 0,
        max: 100,
        minWidth: 40.0,
        maxWidth: 80.0,
      );

      expect(config.id, 'test');
      expect(config.position, YAxisPosition.left);
      expect(config.color, Colors.blue);
      expect(config.label, 'Test Label');
      expect(config.unit, 'units');
      expect(config.min, 0);
      expect(config.max, 100);
      expect(config.minWidth, 40.0);
      expect(config.maxWidth, 80.0);
    });

    test('YAxisPosition has all documented values', () {
      // Validate all documented enum values exist
      expect(YAxisPosition.values, contains(YAxisPosition.leftOuter));
      expect(YAxisPosition.values, contains(YAxisPosition.left));
      expect(YAxisPosition.values, contains(YAxisPosition.right));
      expect(YAxisPosition.values, contains(YAxisPosition.rightOuter));
    });

    test('NormalizationMode has all documented values', () {
      // Validate all documented enum values exist
      expect(NormalizationMode.values, contains(NormalizationMode.none));
      expect(NormalizationMode.values, contains(NormalizationMode.auto));
      expect(NormalizationMode.values, contains(NormalizationMode.perSeries));
    });

    test('ChartSeries has yAxisId and unit properties', () {
      // Validate ChartSeries extensions exist
      final series = LineChartSeries(
        id: 'test',
        yAxisId: 'testAxis',
        unit: 'W',
        points: powerData,
      );

      expect(series.yAxisId, 'testAxis');
      expect(series.unit, 'W');
    });
  });
}
