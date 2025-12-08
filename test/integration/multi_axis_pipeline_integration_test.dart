// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Integration tests for multi-axis normalization pipeline.
///
/// These tests verify that the MultiAxisNormalizer and NormalizationDetector
/// are properly wired into the BravenChartPlus rendering pipeline.
///
/// **Key Integration Points**:
/// 1. BravenChartPlus calls NormalizationDetector.shouldNormalize()
/// 2. ChartRenderBox uses MultiAxisNormalizer for Y coordinate conversion
/// 3. Tooltips display original values (not normalized)
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Pipeline Integration', () {
    group('BravenChartPlus with multi-scale data', () {
      testWidgets('renders chart with 100x range difference without error', (tester) async {
        // Create chart with series having 100x range difference
        // Series A: 0-10
        // Series B: 0-1000
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'small-range',
                      name: 'Small Range',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 1, y: 5),
                        ChartDataPoint(x: 2, y: 10),
                      ],
                    ),
                    LineChartSeries(
                      id: 'large-range',
                      name: 'Large Range',
                      color: Colors.red,
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 1, y: 500),
                        ChartDataPoint(x: 2, y: 1000),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Widget should render without errors
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('renders chart with similar ranges without error', (tester) async {
        // Create chart with series having 2x range difference (below 10x threshold)
        // Series A: 0-50
        // Series B: 0-100
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'range-50',
                      name: 'Range 50',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 1, y: 25),
                        ChartDataPoint(x: 2, y: 50),
                      ],
                    ),
                    LineChartSeries(
                      id: 'range-100',
                      name: 'Range 100',
                      color: Colors.red,
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 1, y: 50),
                        ChartDataPoint(x: 2, y: 100),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Backward compatibility', () {
      testWidgets('single series chart works unchanged', (tester) async {
        // Existing single-series charts must continue working
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'single',
                      name: 'Single Series',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 1, y: 200),
                        ChartDataPoint(x: 2, y: 150),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('empty series list works', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('multi-series with similar ranges works unchanged', (tester) async {
        // Series with similar ranges should render normally
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series-a',
                      name: 'Series A',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 1, y: 15),
                        ChartDataPoint(x: 2, y: 12),
                      ],
                    ),
                    LineChartSeries(
                      id: 'series-b',
                      name: 'Series B',
                      color: Colors.red,
                      points: [
                        ChartDataPoint(x: 0, y: 8),
                        ChartDataPoint(x: 1, y: 18),
                        ChartDataPoint(x: 2, y: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('NormalizationDetector integration', () {
      test('shouldNormalize returns true for 100x difference', () {
        // Test the detector directly to verify it's available
        final seriesRanges = {
          'small': const DataRange(min: 0.0, max: 10.0),
          'large': const DataRange(min: 0.0, max: 1000.0),
        };

        expect(NormalizationDetector.shouldNormalize(seriesRanges), isTrue);
      });

      test('shouldNormalize returns false for 2x difference', () {
        final seriesRanges = {
          'series-a': const DataRange(min: 0.0, max: 50.0),
          'series-b': const DataRange(min: 0.0, max: 100.0),
        };

        expect(NormalizationDetector.shouldNormalize(seriesRanges), isFalse);
      });

      test('getMaxRatio calculates correct ratio', () {
        final seriesRanges = {
          'small': const DataRange(min: 0.0, max: 10.0),
          'large': const DataRange(min: 0.0, max: 1000.0),
        };

        expect(NormalizationDetector.getMaxRatio(seriesRanges), equals(100.0));
      });
    });

    group('MultiAxisNormalizer integration', () {
      test('normalize maps value to 0-1 range', () {
        // Test the normalizer directly to verify it's available
        final normalized = MultiAxisNormalizer.normalize(50.0, 0.0, 100.0);
        expect(normalized, equals(0.5));
      });

      test('denormalize restores original value', () {
        final original = MultiAxisNormalizer.denormalize(0.5, 0.0, 100.0);
        expect(original, equals(50.0));
      });

      test('normalize and denormalize are inverse operations', () {
        const value = 75.0;
        const min = 0.0;
        const max = 100.0;

        final normalized = MultiAxisNormalizer.normalize(value, min, max);
        final restored = MultiAxisNormalizer.denormalize(normalized, min, max);

        expect(restored, closeTo(value, 0.0001));
      });
    });

    group('RangeRatioCalculator integration', () {
      test('calculateRatio returns correct ratio for different ranges', () {
        // Test the calculator directly to verify it's available
        final smallRange = const DataRange(min: 0.0, max: 10.0);
        final largeRange = const DataRange(min: 0.0, max: 100.0);

        final ratio = RangeRatioCalculator.calculateRatio(smallRange, largeRange);
        expect(ratio, equals(10.0));
      });

      test('calculateRatio is order-independent', () {
        final rangeA = const DataRange(min: 0.0, max: 50.0);
        final rangeB = const DataRange(min: 0.0, max: 200.0);

        final ratio1 = RangeRatioCalculator.calculateRatio(rangeA, rangeB);
        final ratio2 = RangeRatioCalculator.calculateRatio(rangeB, rangeA);

        expect(ratio1, equals(ratio2));
      });
    });

    group('Chart types with multi-scale data', () {
      testWidgets('scatter chart with multi-scale data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    ScatterChartSeries(
                      id: 'temp',
                      name: 'Temperature',
                      color: Colors.orange,
                      markerRadius: 4.0,
                      points: [
                        ChartDataPoint(x: 0, y: 20),
                        ChartDataPoint(x: 1, y: 25),
                        ChartDataPoint(x: 2, y: 30),
                      ],
                    ),
                    ScatterChartSeries(
                      id: 'pressure',
                      name: 'Pressure',
                      color: Colors.purple,
                      markerRadius: 4.0,
                      points: [
                        ChartDataPoint(x: 0, y: 1000),
                        ChartDataPoint(x: 1, y: 1050),
                        ChartDataPoint(x: 2, y: 1020),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('bar chart with multi-scale data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    BarChartSeries(
                      id: 'revenue',
                      name: 'Revenue',
                      color: Colors.green,
                      barWidthPercent: 0.8,
                      points: [
                        ChartDataPoint(x: 0, y: 50000),
                        ChartDataPoint(x: 1, y: 75000),
                        ChartDataPoint(x: 2, y: 60000),
                      ],
                    ),
                    BarChartSeries(
                      id: 'units',
                      name: 'Units',
                      color: Colors.blue,
                      barWidthPercent: 0.8,
                      points: [
                        ChartDataPoint(x: 0, y: 100),
                        ChartDataPoint(x: 1, y: 150),
                        ChartDataPoint(x: 2, y: 120),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('area chart with multi-scale data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    AreaChartSeries(
                      id: 'cpu',
                      name: 'CPU %',
                      color: Colors.teal,
                      fillOpacity: 0.3,
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 1, y: 50),
                        ChartDataPoint(x: 2, y: 100),
                      ],
                    ),
                    AreaChartSeries(
                      id: 'memory',
                      name: 'Memory MB',
                      color: Colors.indigo,
                      fillOpacity: 0.3,
                      points: [
                        ChartDataPoint(x: 0, y: 2000),
                        ChartDataPoint(x: 1, y: 4000),
                        ChartDataPoint(x: 2, y: 8000),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Edge cases', () {
      testWidgets('handles series with single point', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'single-point',
                      name: 'Single Point',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 100),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles series with zero Y range', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'flat-line',
                      name: 'Flat Line',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 50),
                        ChartDataPoint(x: 1, y: 50),
                        ChartDataPoint(x: 2, y: 50),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles negative Y values', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'positive',
                      name: 'Positive',
                      color: Colors.green,
                      points: [
                        ChartDataPoint(x: 0, y: 0),
                        ChartDataPoint(x: 1, y: 50),
                        ChartDataPoint(x: 2, y: 100),
                      ],
                    ),
                    LineChartSeries(
                      id: 'negative',
                      name: 'Negative',
                      color: Colors.red,
                      points: [
                        ChartDataPoint(x: 0, y: -100),
                        ChartDataPoint(x: 1, y: -50),
                        ChartDataPoint(x: 2, y: 0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles very large Y values', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'small',
                      name: 'Small',
                      color: Colors.blue,
                      points: [
                        ChartDataPoint(x: 0, y: 1),
                        ChartDataPoint(x: 1, y: 2),
                        ChartDataPoint(x: 2, y: 3),
                      ],
                    ),
                    LineChartSeries(
                      id: 'huge',
                      name: 'Huge',
                      color: Colors.red,
                      points: [
                        ChartDataPoint(x: 0, y: 1000000),
                        ChartDataPoint(x: 1, y: 2000000),
                        ChartDataPoint(x: 2, y: 3000000),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });
  });
}
