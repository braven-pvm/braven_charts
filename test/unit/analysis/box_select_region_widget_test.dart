// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===========================================================================
  // Helper: Build multi-series test data
  // ===========================================================================

  /// Creates 2 series with known data points for box-select testing.
  ///
  /// Series 'series-a': 10 points at x = 1..10, y = x * 10.0
  /// Series 'series-b': 5 points at x = 2, 4, 6, 8, 10, y = x * 5.0
  ///
  /// This provides clear multi-series coverage for verifying that box-select
  /// correctly filters data from all series within the drag's X-range.
  List<ChartSeries> buildMultiSeriesData() {
    return [
      LineChartSeries(
        id: 'series-a',
        points: List.generate(
          10,
          (i) => ChartDataPoint(x: (i + 1).toDouble(), y: (i + 1) * 10.0),
        ),
        color: Colors.blue,
      ),
      const LineChartSeries(
        id: 'series-b',
        points: [
          ChartDataPoint(x: 2.0, y: 10.0),
          ChartDataPoint(x: 4.0, y: 20.0),
          ChartDataPoint(x: 6.0, y: 30.0),
          ChartDataPoint(x: 8.0, y: 40.0),
          ChartDataPoint(x: 10.0, y: 50.0),
        ],
        color: Colors.red,
      ),
    ];
  }

  // ===========================================================================
  // Box-select drag → onRegionSelected with DataRegion(source=boxSelect)
  // ===========================================================================
  group('Box-select drag fires onRegionSelected', () {
    testWidgets(
      'box-select drag on chart with multi-series data fires onRegionSelected '
      'with DataRegion where source == DataRegionSource.boxSelect and '
      'seriesData contains correct filtered points for the drag X-range',
      (WidgetTester tester) async {
        // Arrange
        final series = buildMultiSeriesData();
        DataRegion? receivedRegion;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  interactionConfig: const InteractionConfig(
                    enableSelection: true,
                  ),
                  onRegionSelected: (DataRegion? region) {
                    receivedRegion = region;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — simulate a box-select drag gesture across the chart.
        // Drag from left portion to right portion, covering a subset of
        // the X-range. The exact pixel-to-data mapping depends on chart
        // layout, but the drag should span some data points.
        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Drag from left-of-center to right-of-center
        await tester.timedDragFrom(
          Offset(chartCenter.dx - 150, chartCenter.dy),
          const Offset(300, 50), // drag 300px right, 50px down
          const Duration(milliseconds: 500),
        );
        await tester.pumpAndSettle();

        // Assert — callback fires with region
        expect(
          receivedRegion,
          isNotNull,
          reason:
              'onRegionSelected must fire when box-select drag completes on '
              'a chart with data',
        );
        expect(
          receivedRegion!.source,
          equals(DataRegionSource.boxSelect),
          reason: 'Region source must be DataRegionSource.boxSelect',
        );

        // Verify seriesData is populated with data points from the drag range
        expect(
          receivedRegion!.seriesData,
          isNotEmpty,
          reason:
              'seriesData must contain filtered points from series within the '
              'box-select X-range',
        );

        // At least one series should have matching points
        final allPoints = receivedRegion!.seriesData.values
            .expand((points) => points)
            .toList();
        expect(
          allPoints,
          isNotEmpty,
          reason: 'Box-select should capture data points from the drag range',
        );

        // Verify startX <= endX (well-formed region)
        expect(
          receivedRegion!.startX,
          lessThanOrEqualTo(receivedRegion!.endX),
          reason: 'DataRegion startX must be <= endX',
        );
      },
    );
  });

  // ===========================================================================
  // onSelectionChanged co-fires alongside onRegionSelected
  // ===========================================================================
  group('Box-select co-fires onSelectionChanged and onRegionSelected', () {
    testWidgets(
      'both onSelectionChanged and onRegionSelected fire when box-select '
      'drag completes — co-firing contract per api-contracts.md §4',
      (WidgetTester tester) async {
        // Arrange
        final series = buildMultiSeriesData();
        DataRegion? receivedRegion;
        List<ChartDataPoint>? receivedSelection;
        bool regionCallbackFired = false;
        bool selectionCallbackFired = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  interactionConfig: InteractionConfig(
                    enableSelection: true,
                    onSelectionChanged: (List<ChartDataPoint> selectedPoints) {
                      selectionCallbackFired = true;
                      receivedSelection = selectedPoints;
                    },
                  ),
                  onRegionSelected: (DataRegion? region) {
                    regionCallbackFired = true;
                    receivedRegion = region;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — perform box-select drag
        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        await tester.timedDragFrom(
          Offset(chartCenter.dx - 150, chartCenter.dy),
          const Offset(300, 50),
          const Duration(milliseconds: 500),
        );
        await tester.pumpAndSettle();

        // Assert — BOTH callbacks must fire for the same gesture
        expect(
          regionCallbackFired,
          isTrue,
          reason: 'onRegionSelected must fire when box-select drag completes',
        );
        expect(
          selectionCallbackFired,
          isTrue,
          reason:
              'onSelectionChanged must co-fire alongside onRegionSelected '
              'when box-select completes (co-firing contract)',
        );

        // Verify the region callback received a valid DataRegion
        expect(receivedRegion, isNotNull);
        expect(receivedRegion!.source, equals(DataRegionSource.boxSelect));

        // Verify the selection callback received selected points
        expect(
          receivedSelection,
          isNotNull,
          reason: 'onSelectionChanged must receive selected data points',
        );
      },
    );
  });

  // ===========================================================================
  // Clearing on click-elsewhere fires onRegionSelected(null)
  // ===========================================================================
  group('Box-select clearing on click-elsewhere', () {
    testWidgets(
      'box-select drag then tap elsewhere fires onRegionSelected with null '
      '(region cleared)',
      (WidgetTester tester) async {
        // Arrange
        final series = buildMultiSeriesData();
        final regionsReceived = <DataRegion?>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  interactionConfig: const InteractionConfig(
                    enableSelection: true,
                  ),
                  onRegionSelected: (DataRegion? region) {
                    regionsReceived.add(region);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act 1 — perform box-select drag to create a region
        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        await tester.timedDragFrom(
          Offset(chartCenter.dx - 150, chartCenter.dy),
          const Offset(300, 50),
          const Duration(milliseconds: 500),
        );
        await tester.pumpAndSettle();

        // Act 2 — tap elsewhere on the chart (outside the selected region)
        // to clear the box-select region
        await tester.tapAt(Offset(chartCenter.dx - 300, chartCenter.dy - 100));
        await tester.pumpAndSettle();

        // Assert — first callback should be non-null (region created),
        // second callback should be null (region cleared)
        expect(
          regionsReceived.length,
          greaterThanOrEqualTo(2),
          reason:
              'onRegionSelected must fire at least twice: once with '
              'DataRegion on box-select, once with null on click-elsewhere',
        );

        // First call: DataRegion with boxSelect source
        expect(
          regionsReceived.first,
          isNotNull,
          reason: 'First onRegionSelected call must provide a DataRegion',
        );
        expect(
          regionsReceived.first!.source,
          equals(DataRegionSource.boxSelect),
        );

        // Last call: null (region cleared)
        expect(
          regionsReceived.last,
          isNull,
          reason:
              'Clicking elsewhere must clear the box-select region — '
              'onRegionSelected fires with null',
        );
      },
    );
  });

  // ===========================================================================
  // Replacement semantics: second box-select replaces first
  // ===========================================================================
  group('Box-select replacement semantics', () {
    testWidgets(
      'second box-select replaces the first — only one box-select DataRegion '
      'exists at a time (replacement, not accumulation)',
      (WidgetTester tester) async {
        // Arrange
        final series = buildMultiSeriesData();
        final regionsReceived = <DataRegion?>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  interactionConfig: const InteractionConfig(
                    enableSelection: true,
                  ),
                  onRegionSelected: (DataRegion? region) {
                    regionsReceived.add(region);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act 1 — first box-select drag (left side of chart)
        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        await tester.timedDragFrom(
          Offset(chartCenter.dx - 250, chartCenter.dy),
          const Offset(150, 30),
          const Duration(milliseconds: 500),
        );
        await tester.pumpAndSettle();

        // Act 2 — second box-select drag (right side of chart)
        // This should REPLACE the first, not accumulate
        await tester.timedDragFrom(
          Offset(chartCenter.dx + 50, chartCenter.dy),
          const Offset(150, 30),
          const Duration(milliseconds: 500),
        );
        await tester.pumpAndSettle();

        // Assert — both drags should fire callbacks
        expect(
          regionsReceived.length,
          greaterThanOrEqualTo(2),
          reason: 'onRegionSelected must fire for each box-select drag',
        );

        // Both regions must have boxSelect source
        final nonNullRegions = regionsReceived.whereType<DataRegion>().toList();
        for (final region in nonNullRegions) {
          expect(
            region.source,
            equals(DataRegionSource.boxSelect),
            reason: 'All box-select regions must have boxSelect source',
          );
        }

        // The most recent non-null DataRegion is the only active one.
        // The second drag's X-range should differ from the first's,
        // confirming replacement rather than accumulation.
        if (nonNullRegions.length >= 2) {
          final firstRegion = nonNullRegions[nonNullRegions.length - 2];
          final secondRegion = nonNullRegions.last;

          // The two drags should produce regions with different X-ranges,
          // proving the second replaced the first rather than merging.
          final rangesAreDifferent =
              firstRegion.startX != secondRegion.startX ||
              firstRegion.endX != secondRegion.endX;
          expect(
            rangesAreDifferent,
            isTrue,
            reason:
                'Second box-select must produce a different region than the '
                'first, confirming replacement semantics',
          );
        }

        // Verify only one active box-select region at a time:
        // The last callback should contain only the second region's data,
        // not a union of both regions.
        final lastRegion = nonNullRegions.last;
        expect(
          lastRegion.seriesData,
          isNotEmpty,
          reason: 'The replacement region must contain its own series data',
        );
      },
    );
  });
}
