// @orchestra-task: 3
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===========================================================================
  // Helper: Build standard 3-series test data
  // ===========================================================================

  /// Creates 3 series with known data points for testing.
  ///
  /// Series 'alpha': x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  /// Series 'beta':  x = [1.5, 3.5, 5.5, 7.5, 9.5]
  /// Series 'gamma': x = [2.0, 4.0, 6.0, 8.0, 10.0]
  List<ChartSeries> buildThreeSeriesData() {
    return [
      LineChartSeries(
        id: 'alpha',
        points: List.generate(10, (i) => ChartDataPoint(x: (i + 1).toDouble(), y: (i + 1) * 10.0)),
        color: Colors.blue,
      ),
      const LineChartSeries(
        id: 'beta',
        points: [
          ChartDataPoint(x: 1.5, y: 15.0),
          ChartDataPoint(x: 3.5, y: 35.0),
          ChartDataPoint(x: 5.5, y: 55.0),
          ChartDataPoint(x: 7.5, y: 75.0),
          ChartDataPoint(x: 9.5, y: 95.0),
        ],
        color: Colors.red,
      ),
      const LineChartSeries(
        id: 'gamma',
        points: [
          ChartDataPoint(x: 2.0, y: 22.0),
          ChartDataPoint(x: 4.0, y: 44.0),
          ChartDataPoint(x: 6.0, y: 66.0),
          ChartDataPoint(x: 8.0, y: 88.0),
          ChartDataPoint(x: 10.0, y: 110.0),
        ],
        color: Colors.green,
      ),
    ];
  }

  // ===========================================================================
  // Core annotation-tap → onRegionSelected flow
  // ===========================================================================
  group('Annotation tap fires onRegionSelected', () {
    testWidgets('tapping range annotation fires onRegionSelected with correct DataRegion '
        'for 3 series in range X=3.2..7.8', (WidgetTester tester) async {
      // Arrange
      final series = buildThreeSeriesData();
      DataRegion? receivedRegion;

      final annotation = RangeAnnotation(
        id: 'test-annotation',
        startX: 3.2,
        endX: 7.8,
        fillColor: Colors.blue.withValues(alpha: 0.2),
        label: 'Test Range',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(
                series: series,
                annotations: [annotation],
                onRegionSelected: (DataRegion? region) {
                  receivedRegion = region;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act — simulate tap on the annotation region
      // Tap center of the chart area where the annotation should be
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert
      expect(receivedRegion, isNotNull);
      expect(receivedRegion!.source, equals(DataRegionSource.rangeAnnotation));
      expect(receivedRegion!.startX, equals(3.2));
      expect(receivedRegion!.endX, equals(7.8));

      // Alpha series: x=4,5,6,7 are in [3.2, 7.8]
      expect(receivedRegion!.seriesData.containsKey('alpha'), isTrue);
      expect(receivedRegion!.seriesData['alpha'], hasLength(4));
      expect(receivedRegion!.seriesData['alpha']!.map((p) => p.x).toList(), equals([4.0, 5.0, 6.0, 7.0]));

      // Beta series: x=3.5, 5.5, 7.5 are in [3.2, 7.8]
      expect(receivedRegion!.seriesData.containsKey('beta'), isTrue);
      expect(receivedRegion!.seriesData['beta'], hasLength(3));
      expect(receivedRegion!.seriesData['beta']!.map((p) => p.x).toList(), equals([3.5, 5.5, 7.5]));

      // Gamma series: x=4.0, 6.0 are in [3.2, 7.8]
      expect(receivedRegion!.seriesData.containsKey('gamma'), isTrue);
      expect(receivedRegion!.seriesData['gamma'], hasLength(2));
      expect(receivedRegion!.seriesData['gamma']!.map((p) => p.x).toList(), equals([4.0, 6.0]));
    });

    testWidgets('onAnnotationTap co-fires alongside onRegionSelected when annotation is tapped', (WidgetTester tester) async {
      // Arrange
      final series = buildThreeSeriesData();
      DataRegion? receivedRegion;
      ChartAnnotation? receivedAnnotation;

      final annotation = RangeAnnotation(id: 'co-fire-test', startX: 3.2, endX: 7.8, fillColor: Colors.blue.withValues(alpha: 0.2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(
                series: series,
                annotations: [annotation],
                onRegionSelected: (DataRegion? region) {
                  receivedRegion = region;
                },
                onAnnotationTap: (ChartAnnotation ann) {
                  receivedAnnotation = ann;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act — tap annotation
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — both callbacks must fire
      expect(receivedRegion, isNotNull, reason: 'onRegionSelected must fire when annotation is tapped');
      expect(receivedAnnotation, isNotNull, reason: 'onAnnotationTap must co-fire when annotation is tapped');
      expect(receivedAnnotation!.id, equals('co-fire-test'));
    });

    testWidgets('selectedDataRegions getter on state returns matching region after tap', (WidgetTester tester) async {
      // Arrange
      final series = buildThreeSeriesData();
      final globalKey = GlobalKey<State>();

      final annotation = RangeAnnotation(id: 'state-test', startX: 3.2, endX: 7.8, fillColor: Colors.blue.withValues(alpha: 0.2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(key: globalKey, series: series, annotations: [annotation], onRegionSelected: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act — tap annotation
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — access selectedDataRegions from the state
      // This will fail because selectedDataRegions doesn't exist yet
      final state = globalKey.currentState!;
      // ignore: avoid_dynamic_calls
      final regions = (state as dynamic).selectedDataRegions as List<DataRegion>;
      expect(regions, isNotEmpty);
      expect(regions.first.source, equals(DataRegionSource.rangeAnnotation));
      expect(regions.first.startX, equals(3.2));
      expect(regions.first.endX, equals(7.8));
    });
  });

  // ===========================================================================
  // Edge cases
  // ===========================================================================
  group('Annotation region selection edge cases', () {
    testWidgets('zero data scenario: annotation covers no points results in empty seriesData', (WidgetTester tester) async {
      // Arrange — series data all outside the annotation range
      final series = [
        const LineChartSeries(id: 'outside', points: [ChartDataPoint(x: 1.0, y: 10.0), ChartDataPoint(x: 2.0, y: 20.0)], color: Colors.blue),
      ];

      DataRegion? receivedRegion;

      final annotation = RangeAnnotation(id: 'no-data-annotation', startX: 50.0, endX: 60.0, fillColor: Colors.grey.withValues(alpha: 0.2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(
                series: series,
                annotations: [annotation],
                onRegionSelected: (DataRegion? region) {
                  receivedRegion = region;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — callback fires but seriesData should be empty
      expect(receivedRegion, isNotNull);
      expect(receivedRegion!.seriesData, isEmpty);
    });

    testWidgets('partial match: multiple series but only some have data in range', (WidgetTester tester) async {
      // Arrange
      final series = [
        const LineChartSeries(id: 'in-range', points: [ChartDataPoint(x: 5.0, y: 50.0), ChartDataPoint(x: 6.0, y: 60.0)], color: Colors.blue),
        const LineChartSeries(id: 'out-of-range', points: [ChartDataPoint(x: 1.0, y: 10.0), ChartDataPoint(x: 2.0, y: 20.0)], color: Colors.red),
      ];

      DataRegion? receivedRegion;

      final annotation = RangeAnnotation(id: 'partial-match', startX: 4.0, endX: 8.0, fillColor: Colors.orange.withValues(alpha: 0.2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(
                series: series,
                annotations: [annotation],
                onRegionSelected: (DataRegion? region) {
                  receivedRegion = region;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — only 'in-range' series should be in seriesData
      expect(receivedRegion, isNotNull);
      expect(receivedRegion!.seriesData.containsKey('in-range'), isTrue);
      expect(receivedRegion!.seriesData.containsKey('out-of-range'), isFalse);
      expect(receivedRegion!.seriesData['in-range'], hasLength(2));
    });

    testWidgets('horizontal-only annotation with null startX/endX is ignored — '
        'no onRegionSelected fires', (WidgetTester tester) async {
      // Arrange — horizontal annotation with only Y-range, no X-range
      final series = buildThreeSeriesData();
      DataRegion? receivedRegion;
      bool callbackFired = false;

      // Horizontal annotation: startY/endY defined, startX/endX are null
      final horizontalAnnotation = RangeAnnotation(id: 'horizontal-only', startY: 20.0, endY: 80.0, fillColor: Colors.yellow.withValues(alpha: 0.2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(
                series: series,
                annotations: [horizontalAnnotation],
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

      // Act — tap on the horizontal annotation
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — onRegionSelected should NOT fire for horizontal-only annotations
      expect(callbackFired, isFalse, reason: 'Horizontal-only annotations (null startX/endX) must be ignored');
      expect(receivedRegion, isNull);
    });

    testWidgets('FR-005 single-region: tap annotation A then tap annotation B '
        'results in only B being active and A deselected', (WidgetTester tester) async {
      // Arrange
      final series = buildThreeSeriesData();
      final regionsReceived = <DataRegion?>[];

      final annotationA = RangeAnnotation(id: 'annotation-a', startX: 1.0, endX: 4.0, fillColor: Colors.blue.withValues(alpha: 0.2), label: 'A');

      final annotationB = RangeAnnotation(id: 'annotation-b', startX: 6.0, endX: 9.0, fillColor: Colors.red.withValues(alpha: 0.2), label: 'B');

      final globalKey = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: BravenChartPlus(
                key: globalKey,
                series: series,
                annotations: [annotationA, annotationB],
                onRegionSelected: (DataRegion? region) {
                  regionsReceived.add(region);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act — tap annotation A first, then tap annotation B
      // Tap in the left half of the chart (annotation A region)
      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();

      // Tap in the right half of the chart (annotation B region)
      await tester.tapAt(const Offset(600, 200));
      await tester.pumpAndSettle();

      // Assert — after second tap, only B should be active
      // FR-005: Only one region can be selected at a time
      final state = globalKey.currentState!;
      // ignore: avoid_dynamic_calls
      final activeRegions = (state as dynamic).selectedDataRegions as List<DataRegion>;
      expect(activeRegions, hasLength(1));
      expect(activeRegions.first.startX, equals(6.0));
      expect(activeRegions.first.endX, equals(9.0));
    });
  });
}
