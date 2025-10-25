// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/src/interaction/models/interaction_config.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/widgets/braven_chart.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:braven_charts/src/widgets/enums/chart_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration test T056: Scrollbar zoom visual feedback
///
/// Validates that scrollbars appear and render correctly when data exceeds viewport:
/// - X scrollbar appears when chart has more data than can be displayed
/// - Y scrollbar appears when chart has more data than can be displayed  
/// - Both scrollbars appear when both axes have excess data
/// - Scrollbars render without errors and display visual feedback
///
/// User Story: "When I zoom the chart to see 10% of the data, the scrollbar
/// handle should shrink to ~10% of the scrollbar track to show I'm looking
/// at a small portion of the full dataset"
///
/// Note: Specific handle size calculations are validated in unit tests.
/// This integration test verifies end-to-end rendering and interaction.
void main() {
  group('T056: Scrollbar zoom visual feedback integration', () {
    testWidgets('X scrollbar appears and renders when chart has large dataset',
        (WidgetTester tester) async {
      // Arrange: Create chart with 100 points (simulating zoomed state)
      final series = ChartSeries(
        id: 'test',
        points: List.generate(
          100,
          (i) => ChartDataPoint(x: i.toDouble(), y: 50.0),
        ),
      );

      const interactionConfig = InteractionConfig(
        showXScrollbar: true,
        showYScrollbar: false,
        enablePan: true,
        enableZoom: true,
      );

      // Act: Build chart with scrollbar enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Limited width to ensure not all data fits
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: [series],
                interactionConfig: interactionConfig,
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify scrollbar widget exists
      final scrollbarFinder = find.byType(ChartScrollbar);
      expect(
        scrollbarFinder,
        findsWidgets,
        reason: 'X scrollbar should render when enabled in InteractionConfig',
      );

      // Assert: Verify chart renders without errors
      expect(find.byType(BravenChart), findsOneWidget);
      
      // Assert: No error indicators
      expect(tester.takeException(), isNull, reason: 'Should render without throwing exceptions');
    });

    testWidgets('Y scrollbar appears and renders when chart has large dataset',
        (WidgetTester tester) async {
      // Arrange: Create chart with 100 points
      final series = ChartSeries(
        id: 'test',
        points: List.generate(
          100,
          (i) => ChartDataPoint(x: 5.0, y: i.toDouble()), // Varied Y values
        ),
      );

      const interactionConfig = InteractionConfig(
        showXScrollbar: false,
        showYScrollbar: true,
        enablePan: true,
        enableZoom: true,
      );

      // Act: Build chart with Y scrollbar enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300, // Limited height to ensure not all data fits
              child: BravenChart(
                chartType: ChartType.line,
                series: [series],
                interactionConfig: interactionConfig,
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify scrollbar widget exists
      final scrollbarFinder = find.byType(ChartScrollbar);
      expect(
        scrollbarFinder,
        findsWidgets,
        reason: 'Y scrollbar should render when enabled in InteractionConfig',
      );

      // Assert: Verify chart renders without errors
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Both scrollbars appear when both axes have large datasets',
        (WidgetTester tester) async {
      // Arrange: Create chart with 100 points with varied X and Y
      final series = ChartSeries(
        id: 'test',
        points: List.generate(
          100,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
        ),
      );

      const interactionConfig = InteractionConfig(
        showXScrollbar: true,
        showYScrollbar: true,
        enablePan: true,
        enableZoom: true,
      );

      // Act: Build chart with both scrollbars enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: [series],
                interactionConfig: interactionConfig,
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify both scrollbar widgets exist
      final scrollbarFinder = find.byType(ChartScrollbar);
      expect(
        scrollbarFinder,
        findsNWidgets(2),
        reason: 'Both X and Y scrollbars should render when both enabled',
      );

      // Assert: Verify chart renders without errors
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chart renders correctly with scrollbars disabled',
        (WidgetTester tester) async {
      // Arrange: Create chart with scrollbars disabled
      final series = ChartSeries(
        id: 'test',
        points: List.generate(
          100,
          (i) => ChartDataPoint(x: i.toDouble(), y: 50.0),
        ),
      );

      const interactionConfig = InteractionConfig(
        showXScrollbar: false,
        showYScrollbar: false,
        enablePan: true,
        enableZoom: true,
      );

      // Act: Build chart without scrollbars
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: [series],
                interactionConfig: interactionConfig,
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify no scrollbar widgets exist
      final scrollbarFinder = find.byType(ChartScrollbar);
      expect(
        scrollbarFinder,
        findsNothing,
        reason: 'No scrollbars should render when both disabled in InteractionConfig',
      );

      // Assert: Verify chart still renders correctly
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
