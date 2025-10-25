import 'package:braven_charts/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden test for vertical ChartScrollbar visual appearance (T043)
///
/// Validates:
/// - Vertical scrollbar renders with correct visual appearance
/// - Theme colors and styling applied correctly to vertical orientation
/// - Handle size and position visually accurate in vertical dimension
/// - Light/dark theme variants match design for vertical scrollbar
/// - High contrast theme accessible in vertical layout
/// - Different viewport states (top, middle, bottom, zoomed)
///
/// Following Constitution I (Test-First Development).
///
/// Usage:
/// - Run: flutter test test/golden/scrollbar_vertical_visual_test.dart
/// - Update: flutter test test/golden/scrollbar_vertical_visual_test.dart --update-goldens
///
/// Related: T039-T042 (contract tests), T044-T049 (implementation)
void main() {
  group('Vertical ChartScrollbar golden tests', () {
    testWidgets('MUST render light theme vertical scrollbar at top position', (WidgetTester tester) async {
      // ARRANGE: Light theme scrollbar at top (0% offset)
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50% visible, at top
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget with fixed vertical dimensions
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_light_top.png'),
      );
    });

    testWidgets('MUST render dark theme vertical scrollbar at top position', (WidgetTester tester) async {
      // ARRANGE: Dark theme scrollbar at top
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
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
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_dark_top.png'),
      );
    });

    testWidgets('MUST render vertical scrollbar at middle position', (WidgetTester tester) async {
      // ARRANGE: Scrollbar at middle (50% offset)
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
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
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_middle.png'),
      );
    });

    testWidgets('MUST render vertical scrollbar at bottom position', (WidgetTester tester) async {
      // ARRANGE: Scrollbar at bottom (100% offset)
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 50.0, max: 100.0), // 50% visible, at bottom
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_bottom.png'),
      );
    });

    testWidgets('MUST render vertical scrollbar with 10% viewport (highly zoomed)', (WidgetTester tester) async {
      // ARRANGE: Small viewport (10% visible, 10x zoom)
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
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
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_zoomed.png'),
      );
    });

    testWidgets('MUST render vertical scrollbar at minimum handle size', (WidgetTester tester) async {
      // ARRANGE: Extreme zoom (0.5% visible) -> minimum handle size (20px)
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
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
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_min_handle.png'),
      );
    });

    testWidgets('MUST render high contrast theme vertical scrollbar', (WidgetTester tester) async {
      // ARRANGE: High contrast theme for accessibility (uses preset)
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
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
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_high_contrast.png'),
      );
    });

    testWidgets('MUST render vertical scrollbar with full viewport (100% visible)', (WidgetTester tester) async {
      // ARRANGE: Full viewport (no zoom) -> full-height handle
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
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
                width: 20,
                height: 400,
                child: scrollbar,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Should match golden snapshot with full-height handle
      await expectLater(
        find.byType(ChartScrollbar),
        matchesGoldenFile('vertical_scrollbar_full_viewport.png'),
      );
    });

    testWidgets('MUST render vertical scrollbar with custom theme colors', (WidgetTester tester) async {
      // ARRANGE: Custom theme with distinct colors
      final customTheme = ScrollbarConfig.defaultLight.copyWith(
        trackColor: Colors.purple[100]!,
        handleColor: Colors.purple[700]!,
        handleHoverColor: Colors.purple[800]!,
        handleActiveColor: Colors.purple[900]!,
        borderRadius: 6.0,
      );

      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 200.0),
        viewportRange: const DataRange(min: 60.0, max: 140.0),
        onViewportChanged: (_) {},
        theme: customTheme,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 20,
                height: 400,
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
        matchesGoldenFile('vertical_scrollbar_custom_theme.png'),
      );
    });
  });
}
