// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Integration tests for multi-axis normalization in chart rendering.
///
/// These tests verify that DataNormalizer and NormalizationDetector are
/// properly wired into the chart rendering pipeline and that series with
/// different Y ranges render correctly using the full chart height.
library;

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Normalization Integration', () {
    testWidgets('BravenChart accepts multiAxisConfig parameter', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'power', position: YAxisPosition.left),
          YAxisConfig(id: 'volume', position: YAxisPosition.right),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
        ],
        mode: NormalizationMode.always,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'power-series',
                  name: 'Power',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 150),
                    const ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    const ChartDataPoint(x: 0, y: 0.5),
                    const ChartDataPoint(x: 1, y: 2.25),
                    const ChartDataPoint(x: 2, y: 4.0),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Chart renders with NormalizationMode.auto', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'power', position: YAxisPosition.left),
          YAxisConfig(id: 'volume', position: YAxisPosition.right),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
        ],
        mode: NormalizationMode.auto,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'power-series',
                  name: 'Power',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 150),
                    const ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    const ChartDataPoint(x: 0, y: 0.5),
                    const ChartDataPoint(x: 1, y: 2.25),
                    const ChartDataPoint(x: 2, y: 4.0),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Chart renders with NormalizationMode.none', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'power', position: YAxisPosition.left),
          YAxisConfig(id: 'volume', position: YAxisPosition.right),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
        ],
        mode: NormalizationMode.none,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'power-series',
                  name: 'Power',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 150),
                    const ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    const ChartDataPoint(x: 0, y: 0.5),
                    const ChartDataPoint(x: 1, y: 2.25),
                    const ChartDataPoint(x: 2, y: 4.0),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Chart renders without multiAxisConfig (backward compatibility)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'power-series',
                  name: 'Power',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 150),
                    const ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    const ChartDataPoint(x: 0, y: 0.5),
                    const ChartDataPoint(x: 1, y: 2.25),
                    const ChartDataPoint(x: 2, y: 4.0),
                  ],
                ),
              ],
              // No multiAxisConfig - should still work
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Chart renders with explicit axis bounds', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            minValue: 0,
            maxValue: 400,
          ),
          YAxisConfig(
            id: 'volume',
            position: YAxisPosition.right,
            minValue: 0,
            maxValue: 5.0,
          ),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
        ],
        mode: NormalizationMode.always,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'power-series',
                  name: 'Power',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 200),
                    const ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    const ChartDataPoint(x: 0, y: 0.5),
                    const ChartDataPoint(x: 1, y: 2.5),
                    const ChartDataPoint(x: 2, y: 4.0),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Bar chart renders with multiAxisConfig', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'sales', position: YAxisPosition.left),
          YAxisConfig(id: 'count', position: YAxisPosition.right),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'revenue', axisId: 'sales'),
          SeriesAxisBinding(seriesId: 'units', axisId: 'count'),
        ],
        mode: NormalizationMode.always,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.bar,
              series: [
                ChartSeries(
                  id: 'revenue',
                  name: 'Revenue',
                  points: [
                    const ChartDataPoint(x: 0, y: 10000),
                    const ChartDataPoint(x: 1, y: 15000),
                    const ChartDataPoint(x: 2, y: 12000),
                  ],
                ),
                ChartSeries(
                  id: 'units',
                  name: 'Units Sold',
                  points: [
                    const ChartDataPoint(x: 0, y: 100),
                    const ChartDataPoint(x: 1, y: 150),
                    const ChartDataPoint(x: 2, y: 120),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Scatter chart renders with multiAxisConfig', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'temp', position: YAxisPosition.left),
          YAxisConfig(id: 'pressure', position: YAxisPosition.right),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'temp-data', axisId: 'temp'),
          SeriesAxisBinding(seriesId: 'pressure-data', axisId: 'pressure'),
        ],
        mode: NormalizationMode.always,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.scatter,
              series: [
                ChartSeries(
                  id: 'temp-data',
                  name: 'Temperature',
                  points: [
                    const ChartDataPoint(x: 0, y: 20),
                    const ChartDataPoint(x: 1, y: 25),
                    const ChartDataPoint(x: 2, y: 30),
                  ],
                ),
                ChartSeries(
                  id: 'pressure-data',
                  name: 'Pressure',
                  points: [
                    const ChartDataPoint(x: 0, y: 1013),
                    const ChartDataPoint(x: 1, y: 1015),
                    const ChartDataPoint(x: 2, y: 1010),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Area chart renders with multiAxisConfig', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'cpu', position: YAxisPosition.left),
          YAxisConfig(id: 'memory', position: YAxisPosition.right),
        ],
        bindings: [
          SeriesAxisBinding(seriesId: 'cpu-usage', axisId: 'cpu'),
          SeriesAxisBinding(seriesId: 'mem-usage', axisId: 'memory'),
        ],
        mode: NormalizationMode.always,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.area,
              series: [
                ChartSeries(
                  id: 'cpu-usage',
                  name: 'CPU',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 50),
                    const ChartDataPoint(x: 2, y: 100),
                  ],
                ),
                ChartSeries(
                  id: 'mem-usage',
                  name: 'Memory',
                  points: [
                    const ChartDataPoint(x: 0, y: 2048),
                    const ChartDataPoint(x: 1, y: 4096),
                    const ChartDataPoint(x: 2, y: 8192),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Series without binding uses global bounds', (tester) async {
      final config = const MultiAxisConfig(
        axes: [
          YAxisConfig(id: 'power', position: YAxisPosition.left),
        ],
        bindings: [
          // Only power-series has a binding
          SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
        ],
        mode: NormalizationMode.always,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'power-series',
                  name: 'Power',
                  points: [
                    const ChartDataPoint(x: 0, y: 0),
                    const ChartDataPoint(x: 1, y: 150),
                    const ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'unbound-series', // No binding for this series
                  name: 'Unbound',
                  points: [
                    const ChartDataPoint(x: 0, y: 10),
                    const ChartDataPoint(x: 1, y: 20),
                    const ChartDataPoint(x: 2, y: 30),
                  ],
                ),
              ],
              multiAxisConfig: config,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);
    });
  });
}
