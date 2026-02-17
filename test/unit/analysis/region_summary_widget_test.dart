// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===========================================================================
  // Widget-level test for BravenChartPlusState.computeRegionSummaries()
  // ===========================================================================
  group('BravenChartPlusState.computeRegionSummaries', () {
    /// Creates known test series data for verification.
    ///
    /// Series 'power':     x=[1,2,3,4,5], y=[100,200,300,400,500]
    /// Series 'heartrate': x=[1,2,3,4,5], y=[60,80,100,120,140]
    List<ChartSeries> buildTestSeries() {
      return [
        const LineChartSeries(
          id: 'power',
          points: [
            ChartDataPoint(x: 1.0, y: 100.0),
            ChartDataPoint(x: 2.0, y: 200.0),
            ChartDataPoint(x: 3.0, y: 300.0),
            ChartDataPoint(x: 4.0, y: 400.0),
            ChartDataPoint(x: 5.0, y: 500.0),
          ],
          color: Colors.blue,
        ),
        const LineChartSeries(
          id: 'heartrate',
          points: [
            ChartDataPoint(x: 1.0, y: 60.0),
            ChartDataPoint(x: 2.0, y: 80.0),
            ChartDataPoint(x: 3.0, y: 100.0),
            ChartDataPoint(x: 4.0, y: 120.0),
            ChartDataPoint(x: 5.0, y: 140.0),
          ],
          color: Colors.red,
        ),
      ];
    }

    testWidgets(
      'computeRegionSummaries() returns summaries for a selected region '
      'with correct per-series metrics via GlobalKey access',
      (WidgetTester tester) async {
        // Arrange — build chart with known data and a range annotation
        final series = buildTestSeries();

        // GlobalKey to access BravenChartPlusState programmatically
        final globalKey = GlobalKey<BravenChartPlusState>();

        final annotation = RangeAnnotation(
          id: 'test-region',
          startX: 1.5,
          endX: 4.5,
          fillColor: Colors.blue.withValues(alpha: 0.2),
          label: 'Test Region',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  key: globalKey,
                  series: series,
                  annotations: [annotation],
                  onRegionSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — programmatically tap to select the region, then call
        // computeRegionSummaries() via GlobalKey
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pumpAndSettle();

        // Access computeRegionSummaries() on the state
        final state = globalKey.currentState!;
        final summaries = state.computeRegionSummaries();

        // Assert — should return list of RegionSummary objects
        expect(summaries, isNotEmpty);

        final summary = summaries.first;
        expect(summary, isA<RegionSummary>());

        // Verify power series metrics in the region [1.5, 4.5]
        // Points in range: x=2(y=200), x=3(y=300), x=4(y=400) → 3 points
        expect(summary.seriesSummaries.containsKey('power'), isTrue);
        final powerSummary = summary.seriesSummaries['power']!;
        expect(powerSummary.count, equals(3));
        expect(powerSummary.min, closeTo(200.0, 1e-10));
        expect(powerSummary.max, closeTo(400.0, 1e-10));
        expect(powerSummary.sum, closeTo(900.0, 1e-10));
        expect(powerSummary.average, closeTo(300.0, 1e-10));

        // Verify heartrate series metrics in the region [1.5, 4.5]
        // Points in range: x=2(y=80), x=3(y=100), x=4(y=120) → 3 points
        expect(summary.seriesSummaries.containsKey('heartrate'), isTrue);
        final hrSummary = summary.seriesSummaries['heartrate']!;
        expect(hrSummary.count, equals(3));
        expect(hrSummary.min, closeTo(80.0, 1e-10));
        expect(hrSummary.max, closeTo(120.0, 1e-10));
        expect(hrSummary.sum, closeTo(300.0, 1e-10));
        expect(hrSummary.average, closeTo(100.0, 1e-10));
      },
    );

    testWidgets(
      'computeRegionSummaries() returns empty list when no region is selected',
      (WidgetTester tester) async {
        // Arrange — chart with no annotations selected
        final series = buildTestSeries();
        final globalKey = GlobalKey<BravenChartPlusState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(key: globalKey, series: series),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — call computeRegionSummaries() without selecting a region
        final state = globalKey.currentState!;
        final summaries = state.computeRegionSummaries();

        // Assert — no region selected, should return empty list
        expect(summaries, isEmpty);
      },
    );
  });
}
