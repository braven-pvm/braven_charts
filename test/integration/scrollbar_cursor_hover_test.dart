// Integration Test: T099 - Cursor Changes on Hover
//
// Tests: FR-021 (Cursor Changes for Different Interaction Zones)
// - Hover over center → cursor changes to move/grab (SystemMouseCursors.grab)
// - Hover over left edge → cursor changes to resize horizontal (SystemMouseCursors.resizeLeftRight)
// - Hover over right edge → cursor changes to resize horizontal (SystemMouseCursors.resizeLeftRight)
// - Hover over track (outside handle) → cursor changes to pointer (SystemMouseCursors.click)
//
// Status: SKIPPED - Edge zoom feature not working yet, cursor detection may also need verification
// Reason: Related to T096-T098 findings - edge detection infrastructure needs verification
// See: T096_TEST_FINDINGS.md for detailed investigation
//
// Test Pattern: Full BravenChart integration with MouseRegion cursor tracking
// When Feature Fixed: Remove `skip: true` from all test cases
//
// Note: Mouse cursor testing in Flutter requires special handling
// - Use MouseRegion to track cursor changes
// - Verify cursor updates when hovering over different scrollbar zones
// - May require golden tests or render tree inspection

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('T099: Cursor Changes on Hover', () {
    testWidgets(
      'Cursor changes to grab when hovering over handle center',
      (WidgetTester tester) async {
        // Create test data (100 points: 0-99)
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with scrollbar enabled
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [testSeries],
                  interactionConfig: InteractionConfig(
                    enableZoom: true,
                    enablePan: true,
                    showXScrollbar: true,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find scrollbar widget
        final scrollbarFinder = find.byType(ChartScrollbar);
        expect(scrollbarFinder, findsOneWidget);

        // Get scrollbar geometry
        final scrollbarBox = tester.renderObject(scrollbarFinder) as RenderBox;
        final scrollbarSize = scrollbarBox.size;
        final scrollbarOffset = scrollbarBox.localToGlobal(Offset.zero);
        
        final scrollbarRect = Rect.fromLTWH(
          scrollbarOffset.dx,
          scrollbarOffset.dy,
          scrollbarSize.width,
          scrollbarSize.height,
        );

        debugPrint('📐 Scrollbar geometry: $scrollbarRect');

        // Hover over center of handle (should trigger grab cursor)
        final hoverX = scrollbarRect.center.dx;
        final hoverY = scrollbarRect.center.dy;

        debugPrint('🎯 Hovering over handle center: ($hoverX, $hoverY)');

        // Create hover event at handle center
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset(hoverX, hoverY));
        await tester.pumpAndSettle();

        // TODO: Verify cursor changed to SystemMouseCursors.grab
        // This requires inspecting the MouseRegion cursor in the widget tree
        // or using a custom cursor tracking mechanism
        //
        // Possible approaches:
        // 1. Find MouseRegion widget and check its cursor property
        // 2. Use golden test to verify visual cursor appearance
        // 3. Add cursor callback to ChartScrollbar for testing
        
        debugPrint('⚠️  Cursor verification not implemented - requires MouseRegion inspection');

        await gesture.removePointer();
      },
      skip: true, // SKIPPED: Cursor testing requires special MouseRegion inspection
    );

    testWidgets(
      'Cursor changes to resize when hovering over edges',
      (WidgetTester tester) async {
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with scrollbar enabled
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [testSeries],
                  interactionConfig: InteractionConfig(
                    enableZoom: true,
                    enablePan: true,
                    showXScrollbar: true,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find scrollbar widget
        final scrollbarFinder = find.byType(ChartScrollbar);
        expect(scrollbarFinder, findsOneWidget);

        // Get scrollbar geometry
        final scrollbarBox = tester.renderObject(scrollbarFinder) as RenderBox;
        final scrollbarSize = scrollbarBox.size;
        final scrollbarOffset = scrollbarBox.localToGlobal(Offset.zero);
        
        final scrollbarRect = Rect.fromLTWH(
          scrollbarOffset.dx,
          scrollbarOffset.dy,
          scrollbarSize.width,
          scrollbarSize.height,
        );

        debugPrint('📐 Scrollbar geometry: $scrollbarRect');

        // Test left edge hover (should trigger resizeLeftRight cursor)
        final leftEdgeX = scrollbarRect.left + 4; // Within 8px edge zone
        final leftEdgeY = scrollbarRect.center.dy;

        debugPrint('🎯 Hovering over LEFT edge: ($leftEdgeX, $leftEdgeY)');

        final gesture1 = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture1.addPointer(location: Offset(leftEdgeX, leftEdgeY));
        await tester.pumpAndSettle();

        // TODO: Verify cursor changed to SystemMouseCursors.resizeLeftRight
        debugPrint('⚠️  Cursor verification not implemented - requires MouseRegion inspection');

        await gesture1.removePointer();
        await tester.pumpAndSettle();

        // Test right edge hover (should trigger resizeLeftRight cursor)
        final rightEdgeX = scrollbarRect.right - 4; // Within 8px edge zone
        final rightEdgeY = scrollbarRect.center.dy;

        debugPrint('🎯 Hovering over RIGHT edge: ($rightEdgeX, $rightEdgeY)');

        final gesture2 = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture2.addPointer(location: Offset(rightEdgeX, rightEdgeY));
        await tester.pumpAndSettle();

        // TODO: Verify cursor changed to SystemMouseCursors.resizeLeftRight
        debugPrint('⚠️  Cursor verification not implemented - requires MouseRegion inspection');

        await gesture2.removePointer();
      },
      skip: true, // SKIPPED: Cursor testing requires special MouseRegion inspection
    );

    testWidgets(
      'Cursor changes to click when hovering over track',
      (WidgetTester tester) async {
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with scrollbar enabled
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [testSeries],
                  interactionConfig: InteractionConfig(
                    enableZoom: true,
                    enablePan: true,
                    showXScrollbar: true,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find scrollbar widget
        final scrollbarFinder = find.byType(ChartScrollbar);
        expect(scrollbarFinder, findsOneWidget);

        // Get scrollbar geometry
        final scrollbarBox = tester.renderObject(scrollbarFinder) as RenderBox;
        final scrollbarSize = scrollbarBox.size;
        final scrollbarOffset = scrollbarBox.localToGlobal(Offset.zero);
        
        final scrollbarRect = Rect.fromLTWH(
          scrollbarOffset.dx,
          scrollbarOffset.dy,
          scrollbarSize.width,
          scrollbarSize.height,
        );

        debugPrint('📐 Scrollbar geometry: $scrollbarRect');

        // Hover over track (outside handle, to the left)
        // Assuming handle is in middle, hover at far left of track
        final trackX = scrollbarRect.left + 10; // Well outside handle zone
        final trackY = scrollbarRect.center.dy;

        debugPrint('🎯 Hovering over track (outside handle): ($trackX, $trackY)');

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset(trackX, trackY));
        await tester.pumpAndSettle();

        // TODO: Verify cursor changed to SystemMouseCursors.click
        debugPrint('⚠️  Cursor verification not implemented - requires MouseRegion inspection');

        await gesture.removePointer();
      },
      skip: true, // SKIPPED: Cursor testing requires special MouseRegion inspection
    );

    testWidgets(
      'Cursor changes during drag operations',
      (WidgetTester tester) async {
        // This test would verify cursor changes during active drag:
        // - Starts as hover cursor (grab/resize)
        // - Changes to active drag cursor (grabbing/resizing)
        // - Returns to hover cursor when drag ends but mouse still over scrollbar
        // - Returns to default when mouse leaves scrollbar
        //
        // Currently skipped because:
        // 1. Cursor testing infrastructure not implemented
        // 2. Edge zoom not working yet (related to T096)
        //
        // When implemented, this test should:
        // - Start hover to get hover cursor
        // - Begin drag to get active cursor
        // - End drag to get hover cursor again
        // - Move mouse away to get default cursor
      },
      skip: true, // SKIPPED: Cursor testing not implemented + edge zoom not working
    );
  });
}
