// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

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
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0)),
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
    testWidgets('tap on chart with styled series delivers segment region', (WidgetTester tester) async {
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

      // Act — tap near the line at the chart centre.
      // Chart: 800×400, 10px margins → plot area ~780×380. Data x=0..19, y=0..190.
      // With 5% padding: effective yRange=-9.5..199.5.
      // At widget X=400 (plotX≈390): dataX≈9.5, interpY≈95.
      // Actual line Y measured at ~189-190px from debug output.
      await tester.tapAt(const Offset(400, 189));
      await tester.pumpAndSettle();

      // Assert — callback fires with a segment region
      expect(receivedRegion, isNotNull, reason: 'onRegionSelected must fire when a styled segment is tapped');
      expect(receivedRegion!.source, equals(DataRegionSource.segment), reason: 'Region source must be DataRegionSource.segment');
      // The center of the chart maps to approximately x=9.5, which is
      // the boundary between the blue (0-9) and red (10-19) segments.
      // Either region is acceptable depending on rounding.
      expect(receivedRegion!.seriesData.containsKey('styled-series'), isTrue);
    });
  });

  // ===========================================================================
  // Unstyled point tap does NOT trigger segment onRegionSelected
  // ===========================================================================
  group('Unstyled point tap does not fire segment onRegionSelected', () {
    testWidgets('tapping an unstyled point does not fire onRegionSelected for segments', (WidgetTester tester) async {
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
      if (callbackFired && receivedRegion != null) {
        expect(
          receivedRegion!.source,
          isNot(equals(DataRegionSource.segment)),
          reason: 'Tapping unstyled point must not trigger segment-based region',
        );
      } else {
        expect(callbackFired, isFalse, reason: 'onRegionSelected must not fire for unstyled segment taps');
      }
    });
  });

  // ===========================================================================
  // Non-adjacent same-style contiguity test
  // ===========================================================================
  group('Non-adjacent same-style contiguity verification', () {
    testWidgets('blue 0-4, red 5-9, blue 10-14: tap in right portion returns second blue group', (WidgetTester tester) async {
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

      // Act — tap near the line in the right portion of the chart where the
      // second blue group (10-14) should be rendered.
      // Chart: 800×400, 10px margins → plot 780×380. Data x=0..14, y=0..140.
      // At x≈10.5: pixel_x ≈ 10 + (10.5/14)*780 ≈ 594, data_y≈105,
      // pixel_y ≈ 10 + 380*(1 − 105/140) ≈ 105. Tap slightly above line.
      await tester.tapAt(const Offset(594, 100));
      await tester.pumpAndSettle();

      // Assert — must return region for the SECOND blue group (10-14),
      // NOT merged with the first blue group (0-4).
      expect(receivedRegion, isNotNull, reason: 'onRegionSelected must fire when styled segment point is tapped');
      expect(receivedRegion!.source, equals(DataRegionSource.segment), reason: 'Region source must be DataRegionSource.segment');
      // Contiguity check: startX must be 10, not 0
      expect(receivedRegion!.startX, equals(10.0), reason: 'Non-adjacent same-style groups must be separate (FR-017)');
      expect(receivedRegion!.endX, equals(14.0), reason: 'endX must be the last point of the contiguous group');

      // Verify seriesData contains only points 10-14
      expect(receivedRegion!.seriesData.containsKey('contiguity-series'), isTrue);
      expect(receivedRegion!.seriesData['contiguity-series'], hasLength(5));
      expect(receivedRegion!.seriesData['contiguity-series']!.map((p) => p.x).toList(), equals([10.0, 11.0, 12.0, 13.0, 14.0]));
    });
  });
}
