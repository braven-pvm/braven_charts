// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 7

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===========================================================================
  // Helper: Build series with styled segment points
  // ===========================================================================

  /// Creates a series with points 0-9 styled blue and points 10-19 styled red.
  ///
  /// 20 total points: x = 0..19, y = x * 10.0
  /// Points 0-9: segmentStyle = blue
  /// Points 10-19: segmentStyle = red
  List<ChartSeries> buildBlueRedStyledSeries() {
    return [
      LineChartSeries(
        id: 'styled-series',
        points: [
          ...List.generate(
            10,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: const SegmentStyle(color: Color(0xFF0000FF)),
            ),
          ),
          ...List.generate(
            10,
            (i) => ChartDataPoint(
              x: (i + 10).toDouble(),
              y: (i + 10) * 10.0,
              segmentStyle: const SegmentStyle(color: Color(0xFFFF0000)),
            ),
          ),
        ],
        color: Colors.blue,
      ),
    ];
  }

  /// Creates a series with all unstyled points (no segmentStyle).
  ///
  /// 20 total points: x = 0..19, y = x * 10.0
  /// All points have null segmentStyle.
  List<ChartSeries> buildUnstyledSeries() {
    return [
      LineChartSeries(
        id: 'unstyled-series',
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0),
        ),
        color: Colors.grey,
      ),
    ];
  }

  /// Creates a series with non-adjacent same-style groups for contiguity testing.
  ///
  /// Points 0-4: blue, Points 5-9: red, Points 10-14: blue
  /// Blue groups are non-adjacent (FR-017 contiguity).
  List<ChartSeries> buildNonAdjacentSameStyleSeries() {
    return [
      LineChartSeries(
        id: 'contiguity-series',
        points: [
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: const SegmentStyle(color: Color(0xFF0000FF)),
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: const SegmentStyle(color: Color(0xFFFF0000)),
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 10).toDouble(),
              y: (i + 10) * 10.0,
              segmentStyle: const SegmentStyle(color: Color(0xFF0000FF)),
            ),
          ),
        ],
        color: Colors.blue,
      ),
    ];
  }

  // ===========================================================================
  // Segment tap → onRegionSelected flow
  // ===========================================================================
  group('Segment tap fires onRegionSelected', () {
    testWidgets(
      'tap point 5 in blue-styled series (0-9) delivers region with points 0-9',
      (WidgetTester tester) async {
        // Arrange
        final series = buildBlueRedStyledSeries();
        DataRegion? receivedRegion;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  onRegionSelected: (DataRegion? region) {
                    receivedRegion = region;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — simulate tap on point 5 which is in the blue segment (0-9)
        // Tap in the left portion of the chart where point 5 should be
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pumpAndSettle();

        // Assert — callback fires with region spanning points 0-9
        expect(
          receivedRegion,
          isNotNull,
          reason: 'onRegionSelected must fire when a styled segment is tapped',
        );
        expect(
          receivedRegion!.source,
          equals(DataRegionSource.segment),
          reason: 'Region source must be DataRegionSource.segment',
        );
        expect(receivedRegion!.startX, equals(0.0));
        expect(receivedRegion!.endX, equals(9.0));

        // Verify seriesData contains data for points 0-9
        expect(receivedRegion!.seriesData.containsKey('styled-series'), isTrue);
        expect(receivedRegion!.seriesData['styled-series'], hasLength(10));
        expect(
          receivedRegion!.seriesData['styled-series']!.map((p) => p.x).toList(),
          equals(List.generate(10, (i) => i.toDouble())),
        );
      },
    );
  });

  // ===========================================================================
  // Unstyled point tap does NOT trigger segment onRegionSelected
  // ===========================================================================
  group('Unstyled point tap does not fire segment onRegionSelected', () {
    testWidgets(
      'tapping an unstyled point does not fire onRegionSelected for segments',
      (WidgetTester tester) async {
        // Arrange
        final series = buildUnstyledSeries();
        DataRegion? receivedRegion;
        bool callbackFired = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  onRegionSelected: (DataRegion? region) {
                    callbackFired = true;
                    receivedRegion = region;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — tap on the chart (all points are unstyled)
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pumpAndSettle();

        // Assert — no segment-based onRegionSelected should fire
        // Either callback doesn't fire at all, or it fires with null,
        // or if it fires, it should NOT have source == segment.
        if (callbackFired && receivedRegion != null) {
          expect(
            receivedRegion!.source,
            isNot(equals(DataRegionSource.segment)),
            reason:
                'Tapping unstyled point must not trigger segment-based region',
          );
        } else {
          // No segment callback fired — correct behavior
          expect(
            callbackFired,
            isFalse,
            reason: 'onRegionSelected must not fire for unstyled segment taps',
          );
        }
      },
    );
  });

  // ===========================================================================
  // Non-adjacent same-style contiguity test
  // ===========================================================================
  group('Non-adjacent same-style contiguity verification', () {
    testWidgets(
      'blue 0-4, red 5-9, blue 10-14: tap point 12 returns only points 10-14',
      (WidgetTester tester) async {
        // Arrange
        final series = buildNonAdjacentSameStyleSeries();
        DataRegion? receivedRegion;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  series: series,
                  onRegionSelected: (DataRegion? region) {
                    receivedRegion = region;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — simulate tap corresponding to point 12 in the second blue
        // group (10-14). Tapping in the right portion of the chart.
        await tester.tapAt(const Offset(600, 200));
        await tester.pumpAndSettle();

        // Assert — must return region for the SECOND blue group only (10-14),
        // NOT merged with the first blue group (0-4).
        expect(
          receivedRegion,
          isNotNull,
          reason:
              'onRegionSelected must fire when styled segment point is tapped',
        );
        expect(
          receivedRegion!.source,
          equals(DataRegionSource.segment),
          reason: 'Region source must be DataRegionSource.segment',
        );
        // Contiguity check: startX must be 10, not 0
        expect(
          receivedRegion!.startX,
          equals(10.0),
          reason: 'Non-adjacent same-style groups must be separate (FR-017)',
        );
        expect(
          receivedRegion!.endX,
          equals(14.0),
          reason: 'endX must be the last point of the contiguous group',
        );

        // Verify seriesData contains only points 10-14
        expect(
          receivedRegion!.seriesData.containsKey('contiguity-series'),
          isTrue,
        );
        expect(receivedRegion!.seriesData['contiguity-series'], hasLength(5));
        expect(
          receivedRegion!.seriesData['contiguity-series']!
              .map((p) => p.x)
              .toList(),
          equals([10.0, 11.0, 12.0, 13.0, 14.0]),
        );
      },
    );
  });
}
