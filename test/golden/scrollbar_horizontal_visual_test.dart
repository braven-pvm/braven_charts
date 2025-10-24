import 'package:braven_charts/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden test for horizontal ChartScrollbar visual appearance (T042)
///
/// Validates:
/// - Scrollbar renders with correct visual appearance
/// - Theme colors and styling applied correctly
/// - Handle size and position visually accurate
/// - Light/dark theme variants match design
/// - High contrast theme accessible
/// - Different viewport states (start, middle, end, zoomed)
///
/// Following Constitution I (Test-First Development).
///
/// Usage:
/// - Run: flutter test test/golden/scrollbar_horizontal_visual_test.dart
/// - Update: flutter test test/golden/scrollbar_horizontal_visual_test.dart --update-goldens
///
/// Related: T039-T041 (contract tests), T044-T049 (implementation)
void main() {
  group('Horizontal ChartScrollbar golden tests', () {
    testWidgets('MUST render light theme horizontal scrollbar at start position',
        (WidgetTester tester) async {
      // ARRANGE: Light theme scrollbar at start (0% offset)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50% visible, at start
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget with fixed dimensions
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_light_start.png'),
      );
    });

    testWidgets('MUST render dark theme horizontal scrollbar at start position',
        (WidgetTester tester) async {
      // ARRANGE: Dark theme scrollbar at start
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultDark,
      );

      // ACT: Build widget with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: Colors.grey[900],
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_dark_start.png'),
      );
    });

    testWidgets('MUST render horizontal scrollbar at middle position',
        (WidgetTester tester) async {
      // ARRANGE: Scrollbar at middle (50% offset)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0), // 50% visible, centered
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_middle.png'),
      );
    });

    testWidgets('MUST render horizontal scrollbar at end position',
        (WidgetTester tester) async {
      // ARRANGE: Scrollbar at end (100% offset)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 50.0, max: 100.0), // 50% visible, at end
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_end.png'),
      );
    });

    testWidgets('MUST render horizontal scrollbar with 10% viewport (highly zoomed)',
        (WidgetTester tester) async {
      // ARRANGE: Small viewport (10% visible, 10x zoom)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 1000.0),
        viewportRange: const DataRange(min: 0.0, max: 100.0), // 10% visible
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot with small handle
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_zoomed.png'),
      );
    });

    testWidgets('MUST render horizontal scrollbar at minimum handle size',
        (WidgetTester tester) async {
      // ARRANGE: Extreme zoom (0.5% visible) -> minimum handle size (20px)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 10000.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 0.5% visible
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight.copyWith(minHandleSize: 20.0),
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot with minimum size handle
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_min_handle.png'),
      );
    });

    testWidgets('MUST render high contrast theme horizontal scrollbar',
        (WidgetTester tester) async {
      // ARRANGE: High contrast theme for accessibility (uses preset)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.highContrast,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot with high contrast
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_high_contrast.png'),
      );
    });

    testWidgets('MUST render horizontal scrollbar with full viewport (100% visible)',
        (WidgetTester tester) async {
      // ARRANGE: Full viewport (no zoom) -> full-width handle
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 100.0), // 100% visible
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot with full-width handle
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_full_viewport.png'),
      );
    });

    testWidgets('MUST render horizontal scrollbar with custom theme colors',
        (WidgetTester tester) async {
      // ARRANGE: Custom theme with distinct colors
      final customTheme = ScrollbarConfig.defaultLight.copyWith(
        trackColor: Colors.blue[100]!,
        handleColor: Colors.blue[700]!,
        handleHoverColor: Colors.blue[800]!,
        handleActiveColor: Colors.blue[900]!,
        borderRadius: 8.0,
      );

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 20.0, max: 60.0),
        onViewportChanged: (_) {},
        theme: customTheme,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot with custom colors
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('horizontal_scrollbar_custom_theme.png'),
      );
    });
  });
}
