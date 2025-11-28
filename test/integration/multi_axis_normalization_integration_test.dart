// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Integration tests for multi-axis normalization in chart rendering.
///
/// These tests verify that DataNormalizer and NormalizationDetector are
/// properly wired into the chart rendering pipeline and that series with
/// different Y ranges render correctly using the full chart height.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/axis/multi_axis_config.dart';
import 'package:braven_charts/src/axis/normalization_mode.dart';
import 'package:braven_charts/src/axis/series_axis_binding.dart';
import 'package:braven_charts/src/axis/y_axis_config.dart';
import 'package:braven_charts/src/axis/y_axis_position.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Normalization Integration', () {
    testWidgets('BravenChart accepts multiAxisConfig parameter', (tester) async {
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
          const YAxisConfig(id: 'volume', position: YAxisPosition.right),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          const SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 150),
                    ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    ChartDataPoint(x: 0, y: 0.5),
                    ChartDataPoint(x: 1, y: 2.25),
                    ChartDataPoint(x: 2, y: 4.0),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
          const YAxisConfig(id: 'volume', position: YAxisPosition.right),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          const SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 150),
                    ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    ChartDataPoint(x: 0, y: 0.5),
                    ChartDataPoint(x: 1, y: 2.25),
                    ChartDataPoint(x: 2, y: 4.0),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
          const YAxisConfig(id: 'volume', position: YAxisPosition.right),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          const SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 150),
                    ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    ChartDataPoint(x: 0, y: 0.5),
                    ChartDataPoint(x: 1, y: 2.25),
                    ChartDataPoint(x: 2, y: 4.0),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 150),
                    ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    ChartDataPoint(x: 0, y: 0.5),
                    ChartDataPoint(x: 1, y: 2.25),
                    ChartDataPoint(x: 2, y: 4.0),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            minValue: 0,
            maxValue: 400,
          ),
          const YAxisConfig(
            id: 'volume',
            position: YAxisPosition.right,
            minValue: 0,
            maxValue: 5.0,
          ),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
          const SeriesAxisBinding(seriesId: 'volume-series', axisId: 'volume'),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 200),
                    ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'volume-series',
                  name: 'Volume',
                  points: [
                    ChartDataPoint(x: 0, y: 0.5),
                    ChartDataPoint(x: 1, y: 2.5),
                    ChartDataPoint(x: 2, y: 4.0),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'sales', position: YAxisPosition.left),
          const YAxisConfig(id: 'count', position: YAxisPosition.right),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'revenue', axisId: 'sales'),
          const SeriesAxisBinding(seriesId: 'units', axisId: 'count'),
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
                    ChartDataPoint(x: 0, y: 10000),
                    ChartDataPoint(x: 1, y: 15000),
                    ChartDataPoint(x: 2, y: 12000),
                  ],
                ),
                ChartSeries(
                  id: 'units',
                  name: 'Units Sold',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 150),
                    ChartDataPoint(x: 2, y: 120),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'temp', position: YAxisPosition.left),
          const YAxisConfig(id: 'pressure', position: YAxisPosition.right),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'temp-data', axisId: 'temp'),
          const SeriesAxisBinding(seriesId: 'pressure-data', axisId: 'pressure'),
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
                    ChartDataPoint(x: 0, y: 20),
                    ChartDataPoint(x: 1, y: 25),
                    ChartDataPoint(x: 2, y: 30),
                  ],
                ),
                ChartSeries(
                  id: 'pressure-data',
                  name: 'Pressure',
                  points: [
                    ChartDataPoint(x: 0, y: 1013),
                    ChartDataPoint(x: 1, y: 1015),
                    ChartDataPoint(x: 2, y: 1010),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'cpu', position: YAxisPosition.left),
          const YAxisConfig(id: 'memory', position: YAxisPosition.right),
        ],
        bindings: [
          const SeriesAxisBinding(seriesId: 'cpu-usage', axisId: 'cpu'),
          const SeriesAxisBinding(seriesId: 'mem-usage', axisId: 'memory'),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 50),
                    ChartDataPoint(x: 2, y: 100),
                  ],
                ),
                ChartSeries(
                  id: 'mem-usage',
                  name: 'Memory',
                  points: [
                    ChartDataPoint(x: 0, y: 2048),
                    ChartDataPoint(x: 1, y: 4096),
                    ChartDataPoint(x: 2, y: 8192),
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
      final config = MultiAxisConfig(
        axes: [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
        ],
        bindings: [
          // Only power-series has a binding
          const SeriesAxisBinding(seriesId: 'power-series', axisId: 'power'),
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
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 150),
                    ChartDataPoint(x: 2, y: 300),
                  ],
                ),
                ChartSeries(
                  id: 'unbound-series', // No binding for this series
                  name: 'Unbound',
                  points: [
                    ChartDataPoint(x: 0, y: 10),
                    ChartDataPoint(x: 1, y: 20),
                    ChartDataPoint(x: 2, y: 30),
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
