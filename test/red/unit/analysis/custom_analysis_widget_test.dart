// @orchestra-task: 13
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT
//
// TDD red-phase widget tests for US6: Custom Analysis Extensions.
//
// These tests MUST FAIL until the green-phase implementation adds
// `customRegionAnalysis` to BravenChartPlus constructor and updates
// the overlay rendering pipeline to merge custom metrics.
//
// Why tests fail:
//   1. `customRegionAnalysis` named parameter does not exist on
//      BravenChartPlus — causes a compilation error.
//   2. Even if compilation passed, the overlay renderer does not yet
//      render custom metric entries — assertions would fail.
//
// Spec tasks: T049, T050

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // =========================================================================
  // Helper: Build a minimal single-series chart suitable for region tests.
  // =========================================================================

  /// Creates a simple cycling-themed power series spanning x=[0..10].
  ///
  /// Series 'power': x=[0,1,2,3,4,5,6,7,8,9,10], y=[200..300] (linear ramp).
  List<ChartSeries> buildPowerSeries() {
    return [
      LineChartSeries(
        id: 'power',
        points: List.generate(
          11,
          (i) => ChartDataPoint(x: i.toDouble(), y: 200.0 + i * 10.0),
        ),
        color: Colors.orange,
      ),
    ];
  }

  /// Creates a [RangeAnnotation] spanning x=[3, 7] for use as the selected
  /// region trigger in widget tests.
  RangeAnnotation buildRegionAnnotation() {
    return RangeAnnotation(
      id: 'power-zone',
      startX: 3.0,
      endX: 7.0,
      fillColor: Colors.orange.withValues(alpha: 0.2),
      label: 'Power Zone',
    );
  }

  // =========================================================================
  // US6 Test Scenario 1: customRegionAnalysis callback returns custom metrics
  // that appear in the summary overlay alongside built-in metrics.
  // =========================================================================
  group('US6 customRegionAnalysis callback', () {
    testWidgets('custom callback returning NP metric appears in summary overlay '
        'alongside built-in min/max/avg metrics', (WidgetTester tester) async {
      // Arrange
      final globalKey = GlobalKey<BravenChartPlusState>();
      final series = buildPowerSeries();
      final annotation = buildRegionAnnotation();

      // Custom analysis callback simulating a cycling app computing
      // Normalized Power from the region data.
      Map<String, String> computeNormalizedPower(
        DataRegion region,
        RegionSummary summary,
      ) {
        // In a real app this would compute NP from raw power data.
        // For test purposes, return a fixed value to verify wiring.
        return {'NP': '250 W'};
      }

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
                // THIS PARAMETER DOES NOT EXIST YET — causes compilation
                // error in red phase. The green-phase adds this parameter.
                // ignore: undefined_named_parameter
                customRegionAnalysis: computeNormalizedPower,
                showRegionSummary: true,
                regionSummaryConfig: RegionSummaryConfig(
                  metrics: {
                    RegionMetric.min,
                    RegionMetric.max,
                    RegionMetric.average,
                  },
                  position: RegionSummaryPosition.aboveRegion,
                ),
                onRegionSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act — tap the chart to select the range annotation region
      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — verify the region was selected via the state
      final state = globalKey.currentState!;
      final selectedRegions = state.selectedDataRegions;
      expect(
        selectedRegions,
        isNotEmpty,
        reason: 'A region must be selected after tapping the annotation',
      );

      // Assert — compute summaries and verify built-in metrics are present
      final summaries = state.computeRegionSummaries();
      expect(
        summaries,
        isNotEmpty,
        reason: 'RegionSummary should be computed for the selected region',
      );

      final summary = summaries.first;
      expect(
        summary.seriesSummaries.containsKey('power'),
        isTrue,
        reason: 'Built-in summary must include the power series',
      );

      // Assert — verify the custom metric 'NP' with value '250 W' is
      // present in the summary overlay rendered by ChartRenderBox.
      // The green implementation must merge customMetrics into the
      // rendered overlay. We verify the overlay contains the 'NP' label
      // by finding a Text widget with key 'custom_metric_NP' or by
      // finding a Text widget that displays 'NP' within the overlay.
      //
      // Check that 'NP' appears as a rendered text in the widget tree
      // (the green-phase RegionSummaryRenderer must render custom metrics).
      expect(
        find.text('NP'),
        findsOneWidget,
        reason: 'Custom metric label "NP" must appear in the summary overlay',
      );
      expect(
        find.text('250 W'),
        findsOneWidget,
        reason:
            'Custom metric value "250 W" must appear in the summary overlay',
      );

      // Assert — built-in metrics must also be present in the overlay
      // alongside the custom NP metric. look for the Min metric label.
      expect(
        find.text('Min'),
        findsOneWidget,
        reason:
            'Built-in "Min" metric must still appear alongside custom metrics',
      );
    });

    testWidgets(
      'custom callback is invoked with the selected DataRegion and its '
      'RegionSummary — callback receives correct arguments',
      (WidgetTester tester) async {
        // Arrange
        final globalKey = GlobalKey<BravenChartPlusState>();
        final series = buildPowerSeries();
        final annotation = buildRegionAnnotation();

        DataRegion? capturedRegion;
        RegionSummary? capturedSummary;

        Map<String, String> captureArgs(
          DataRegion region,
          RegionSummary summary,
        ) {
          capturedRegion = region;
          capturedSummary = summary;
          return {'Custom': 'Value'};
        }

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
                  // THIS PARAMETER DOES NOT EXIST YET — compilation error.
                  // ignore: undefined_named_parameter
                  customRegionAnalysis: captureArgs,
                  showRegionSummary: true,
                  onRegionSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pumpAndSettle();

        // Assert — callback must have been invoked with a valid DataRegion
        expect(
          capturedRegion,
          isNotNull,
          reason: 'customRegionAnalysis callback must be called with region',
        );
        expect(
          capturedSummary,
          isNotNull,
          reason: 'customRegionAnalysis callback must receive RegionSummary',
        );
        expect(
          capturedRegion!.startX,
          equals(3.0),
          reason: 'Callback region.startX must match annotation startX',
        );
        expect(
          capturedRegion!.endX,
          equals(7.0),
          reason: 'Callback region.endX must match annotation endX',
        );
      },
    );
  });

  // =========================================================================
  // US6 Test Scenario 2: No custom callback — only built-in metrics shown
  // and no errors occur.
  // =========================================================================
  group('US6 no customRegionAnalysis — built-in metrics only', () {
    testWidgets('chart without customRegionAnalysis renders only built-in metrics '
        'in summary overlay and does not crash', (WidgetTester tester) async {
      // Arrange — BravenChartPlus WITHOUT customRegionAnalysis callback
      final globalKey = GlobalKey<BravenChartPlusState>();
      final series = buildPowerSeries();
      final annotation = buildRegionAnnotation();

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
                // No customRegionAnalysis — this is the no-callback scenario
                showRegionSummary: true,
                regionSummaryConfig: RegionSummaryConfig(
                  metrics: {
                    RegionMetric.min,
                    RegionMetric.max,
                    RegionMetric.average,
                  },
                  position: RegionSummaryPosition.aboveRegion,
                ),
                onRegionSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act — select a region by tapping the chart
      expect(
        tester.takeException(),
        isNull,
        reason: 'Chart must render without exceptions even without callback',
      );

      await tester.tap(find.byType(BravenChartPlus));
      await tester.pumpAndSettle();

      // Assert — no exception after region selection
      expect(
        tester.takeException(),
        isNull,
        reason: 'No exception must be thrown on region selection',
      );

      // Assert — region was selected
      final state = globalKey.currentState!;
      final selectedRegions = state.selectedDataRegions;
      expect(
        selectedRegions,
        isNotEmpty,
        reason: 'A region must be selected after tap',
      );

      // Assert — built-in metrics are present in the overlay
      expect(
        find.text('Min'),
        findsOneWidget,
        reason:
            'Built-in "Min" metric must be rendered in overlay without callback',
      );
      expect(
        find.text('Max'),
        findsOneWidget,
        reason:
            'Built-in "Max" metric must be rendered in overlay without callback',
      );
      expect(
        find.text('Avg'),
        findsOneWidget,
        reason:
            'Built-in "Avg" metric must be rendered in overlay without callback',
      );

      // Assert — no custom metrics should be rendered (NP never defined)
      expect(
        find.text('NP'),
        findsNothing,
        reason:
            'Custom metric "NP" must NOT appear when no callback is registered',
      );
    });

    testWidgets(
      'chart without customRegionAnalysis — computeRegionSummaries() returns '
      'valid RegionSummary with correct power series statistics',
      (WidgetTester tester) async {
        // Arrange
        final globalKey = GlobalKey<BravenChartPlusState>();
        final series = buildPowerSeries();
        final annotation = buildRegionAnnotation();

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
                  showRegionSummary: true,
                  onRegionSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — select region
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pumpAndSettle();

        // Assert — computeRegionSummaries() returns correct data
        final state = globalKey.currentState!;
        final summaries = state.computeRegionSummaries();
        expect(
          summaries,
          isNotEmpty,
          reason: 'RegionSummary must be computed for the selected region',
        );

        final summary = summaries.first;
        expect(
          summary,
          isA<RegionSummary>(),
          reason: 'Summary must be a RegionSummary instance',
        );
        expect(
          summary.seriesSummaries.containsKey('power'),
          isTrue,
          reason: 'Summary must contain power series statistics',
        );

        // Power series in region x=[3,7]: points at x=3,4,5,6,7
        // y values: 230, 240, 250, 260, 270
        final powerStats = summary.seriesSummaries['power']!;
        expect(
          powerStats.count,
          equals(5),
          reason: 'Should find 5 power data points in region x=[3,7]',
        );
        expect(
          powerStats.min,
          closeTo(230.0, 1e-9),
          reason: 'Min power in region x=[3,7] should be 230.0',
        );
        expect(
          powerStats.max,
          closeTo(270.0, 1e-9),
          reason: 'Max power in region x=[3,7] should be 270.0',
        );
        expect(
          powerStats.average,
          closeTo(250.0, 1e-9),
          reason: 'Average power in region x=[3,7] should be 250.0',
        );
      },
    );
  });
}
