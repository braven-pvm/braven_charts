// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 11

import 'dart:ui' as ui;

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/region_summary.dart';
import 'package:braven_charts/src/models/region_summary_config.dart';
import 'package:braven_charts/src/rendering/modules/region_summary_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Test Data Helpers
// =============================================================================

/// Creates a [DataRegion] for golden test use.
DataRegion _makeGoldenRegion({
  String id = 'golden-region',
  double startX = 10.0,
  double endX = 90.0,
  Map<String, List<ChartDataPoint>>? seriesData,
}) {
  return DataRegion(
    id: id,
    startX: startX,
    endX: endX,
    source: DataRegionSource.rangeAnnotation,
    seriesData:
        seriesData ??
        {
          'series-a': [
            const ChartDataPoint(x: 20.0, y: 10.0),
            const ChartDataPoint(x: 50.0, y: 25.0),
            const ChartDataPoint(x: 80.0, y: 20.0),
          ],
        },
  );
}

/// Creates a [SeriesRegionSummary] for golden tests.
SeriesRegionSummary _makeGoldenSeries({
  required String seriesId,
  required String seriesName,
  double min = 10.0,
  double max = 25.0,
  double average = 18.33,
  double sum = 55.0,
  double range = 15.0,
  int count = 3,
  double duration = 80.0,
}) {
  return SeriesRegionSummary(
    seriesId: seriesId,
    seriesName: seriesName,
    count: count,
    min: min,
    max: max,
    sum: sum,
    average: average,
    range: range,
    firstY: min,
    lastY: max - 5.0,
    delta: (max - 5.0) - min,
    duration: duration,
  );
}

/// A [CustomPainter] that delegates to [RegionSummaryRenderer.paint].
///
/// Used to create a renderable widget for golden file comparison.
class _RegionSummaryPainter extends CustomPainter {
  /// Creates a painter that renders a [RegionSummary] overlay.
  const _RegionSummaryPainter({
    required this.summary,
    required this.config,
    required this.regionBounds,
  });

  /// The statistical summary to visualise.
  final RegionSummary summary;

  /// Rendering configuration (metrics, formatter, position).
  final RegionSummaryConfig config;

  /// The region bounds rectangle used for card positioning.
  final Rect regionBounds;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    const renderer = RegionSummaryRenderer();
    renderer.paint(canvas, size, summary, config, regionBounds);
  }

  @override
  bool shouldRepaint(_RegionSummaryPainter oldDelegate) => false;
}

/// Wraps a [_RegionSummaryPainter] in a testable widget scaffold.
Widget _buildGoldenWidget({
  required RegionSummary summary,
  required RegionSummaryConfig config,
  required Rect regionBounds,
  Size canvasSize = const Size(600.0, 400.0),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: CustomPaint(
          size: canvasSize,
          painter: _RegionSummaryPainter(
            summary: summary,
            config: config,
            regionBounds: regionBounds,
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// Golden Tests
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Default config: min, max, average — aboveRegion position
  final defaultConfig = RegionSummaryConfig(
    metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
    position: RegionSummaryPosition.aboveRegion,
  );

  // Region bounds centred in a 600×400 canvas
  const defaultBounds = Rect.fromLTWH(150.0, 120.0, 300.0, 200.0);

  // ===========================================================================
  // 1-Series Variants
  // ===========================================================================
  group('RegionSummaryOverlay — 1 series', () {
    testWidgets('1_series_above_region', (WidgetTester tester) async {
      // Arrange
      final region = _makeGoldenRegion();
      final summary = RegionSummary(
        region: region,
        seriesSummaries: {
          'series-a': _makeGoldenSeries(
            seriesId: 'series-a',
            seriesName: 'Temperature',
          ),
        },
      );

      await tester.pumpWidget(
        _buildGoldenWidget(
          summary: summary,
          config: defaultConfig,
          regionBounds: defaultBounds,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/region_summary_overlay_1series_above.png'),
      );
    });
  });

  // ===========================================================================
  // 2-Series Variants
  // ===========================================================================
  group('RegionSummaryOverlay — 2 series', () {
    testWidgets('2_series_above_region', (WidgetTester tester) async {
      // Arrange
      final region = _makeGoldenRegion(
        seriesData: {
          'series-a': [
            const ChartDataPoint(x: 20.0, y: 10.0),
            const ChartDataPoint(x: 50.0, y: 25.0),
            const ChartDataPoint(x: 80.0, y: 20.0),
          ],
          'series-b': [
            const ChartDataPoint(x: 25.0, y: 50.0),
            const ChartDataPoint(x: 55.0, y: 80.0),
            const ChartDataPoint(x: 75.0, y: 60.0),
          ],
        },
      );
      final summary = RegionSummary(
        region: region,
        seriesSummaries: {
          'series-a': _makeGoldenSeries(
            seriesId: 'series-a',
            seriesName: 'Temperature',
          ),
          'series-b': _makeGoldenSeries(
            seriesId: 'series-b',
            seriesName: 'Humidity',
            min: 50.0,
            max: 80.0,
            average: 63.33,
            sum: 190.0,
            range: 30.0,
          ),
        },
      );

      await tester.pumpWidget(
        _buildGoldenWidget(
          summary: summary,
          config: defaultConfig,
          regionBounds: defaultBounds,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/region_summary_overlay_2series_above.png'),
      );
    });
  });

  // ===========================================================================
  // 3-Series Variants
  // ===========================================================================
  group('RegionSummaryOverlay — 3 series', () {
    testWidgets('3_series_above_region', (WidgetTester tester) async {
      // Arrange
      final region = _makeGoldenRegion(
        seriesData: {
          'series-a': [const ChartDataPoint(x: 20.0, y: 10.0)],
          'series-b': [const ChartDataPoint(x: 30.0, y: 50.0)],
          'series-c': [const ChartDataPoint(x: 40.0, y: 100.0)],
        },
      );
      final summary = RegionSummary(
        region: region,
        seriesSummaries: {
          'series-a': _makeGoldenSeries(
            seriesId: 'series-a',
            seriesName: 'Power',
            count: 1,
          ),
          'series-b': _makeGoldenSeries(
            seriesId: 'series-b',
            seriesName: 'Cadence',
            min: 50.0,
            max: 50.0,
            average: 50.0,
            sum: 50.0,
            range: 0.0,
            count: 1,
          ),
          'series-c': _makeGoldenSeries(
            seriesId: 'series-c',
            seriesName: 'Heart Rate',
            min: 100.0,
            max: 100.0,
            average: 100.0,
            sum: 100.0,
            range: 0.0,
            count: 1,
          ),
        },
      );

      await tester.pumpWidget(
        _buildGoldenWidget(
          summary: summary,
          config: defaultConfig,
          regionBounds: defaultBounds,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/region_summary_overlay_3series_above.png'),
      );
    });
  });

  // ===========================================================================
  // Position Variants — aboveRegion (default) and insideTop fallback
  // ===========================================================================
  group('RegionSummaryOverlay — position variants', () {
    testWidgets('position_aboveRegion_default', (WidgetTester tester) async {
      // Arrange — region in middle of canvas, config uses aboveRegion
      final region = _makeGoldenRegion();
      final summary = RegionSummary(
        region: region,
        seriesSummaries: {
          'series-a': _makeGoldenSeries(
            seriesId: 'series-a',
            seriesName: 'Power',
          ),
        },
      );
      final config = RegionSummaryConfig(
        metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        position: RegionSummaryPosition.aboveRegion,
      );
      // Bounds with ample room above
      const bounds = Rect.fromLTWH(150.0, 200.0, 300.0, 150.0);

      await tester.pumpWidget(
        _buildGoldenWidget(
          summary: summary,
          config: config,
          regionBounds: bounds,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/region_summary_overlay_position_above.png'),
      );
    });

    testWidgets('position_insideTop_fallback', (WidgetTester tester) async {
      // Arrange — region near top of canvas (y=5), forces insideTop fallback
      final region = _makeGoldenRegion(startX: 10.0, endX: 90.0);
      final summary = RegionSummary(
        region: region,
        seriesSummaries: {
          'series-a': _makeGoldenSeries(
            seriesId: 'series-a',
            seriesName: 'Power',
          ),
        },
      );
      // aboveRegion config — but region top at y=5 triggers fallback
      final config = RegionSummaryConfig(
        metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        position: RegionSummaryPosition.aboveRegion,
      );
      // Region starts at y=5 — card height will exceed top boundary
      const bounds = Rect.fromLTWH(150.0, 5.0, 300.0, 300.0);

      await tester.pumpWidget(
        _buildGoldenWidget(
          summary: summary,
          config: config,
          regionBounds: bounds,
        ),
      );
      await tester.pumpAndSettle();

      // Assert — card must be rendered inside the region (insideTop)
      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile(
          'goldens/region_summary_overlay_position_inside_top.png',
        ),
      );
    });
  });
}
