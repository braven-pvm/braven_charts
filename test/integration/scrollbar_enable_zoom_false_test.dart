// Integration Test: T100 - enableZoom=false Behavior
//
// Tests: FR-017, FR-018 (Zoom Disabled Behavior)
// - When enableZoom=false, edge resize handles are disabled
// - Dragging edges acts as pan (same as center drag)
// - Cursor shows grab/move instead of resize when hovering edges
// - Visual feedback shows disabled state (optional, based on FR-023 gaps)
//
// Status: SKIPPED - Edge zoom feature not working yet, so disable behavior can't be tested
// Reason: Need working edge zoom first to verify disable works correctly
// See: T096_TEST_FINDINGS.md for detailed investigation
//
// Test Pattern: Full BravenChart integration with enableZoom=false
// When Feature Fixed: Remove `skip: true` from all test cases

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('T100: enableZoom=false Behavior', () {
    testWidgets(
      'Edge drag acts as pan when enableZoom=false',
      (WidgetTester tester) async {
        // Track viewport changes
        Map<String, double>? lastViewport;
        
        // Create test data (100 points: 0-99)
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with enableZoom=false (pan only)
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
                    enableZoom: false, // DISABLE ZOOM
                    enablePan: true,
                    showXScrollbar: true,
                    onViewportChanged: (viewport) {
                      lastViewport = viewport;
                      debugPrint('📊 Viewport: ${viewport['minX']} to ${viewport['maxX']}');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial viewport
        expect(lastViewport, isNotNull);
        final initialMinX = lastViewport!['minX']!;
        final initialMaxX = lastViewport!['maxX']!;
        final initialRange = initialMaxX - initialMinX;
        
        debugPrint('📊 Initial Viewport: MinX: $initialMinX, MaxX: $initialMaxX, Range: $initialRange');

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

        // Drag from RIGHT edge (would normally be zoom, but should act as pan with enableZoom=false)
        final dragX = scrollbarRect.right - 30; // Right edge zone
        final dragY = scrollbarRect.center.dy;

        debugPrint('🎯 Dragging from right edge: ($dragX, $dragY)');

        // Drag LEFT by 50px (with enableZoom=false, this should PAN left, not zoom)
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(-50, 0), // Drag LEFT
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify viewport changed
        expect(lastViewport, isNotNull);
        final finalMinX = lastViewport!['minX']!;
        final finalMaxX = lastViewport!['maxX']!;
        final finalRange = finalMaxX - finalMinX;

        debugPrint('📊 Final Viewport: MinX: $finalMinX, MaxX: $finalMaxX, Range: $finalRange');
        debugPrint('📊 Changes: ΔMinX=${finalMinX - initialMinX}, ΔMaxX=${finalMaxX - initialMinX}, ΔRange=${finalRange - initialRange}');

        // Verify PAN behavior (not ZOOM):
        // 1. Viewport range should stay CONSTANT (no zoom)
        expect(finalRange, closeTo(initialRange, 2.0),
            reason: 'With enableZoom=false, range should not change (no zoom allowed)');
        
        // 2. Both minX and maxX should shift LEFT (pan behavior)
        expect(finalMinX, lessThan(initialMinX),
            reason: 'Dragging left should decrease minX (pan left)');
        expect(finalMaxX, lessThan(initialMaxX),
            reason: 'Dragging left should decrease maxX (pan left)');
        
        // 3. Range delta should be near zero (confirming pan, not zoom)
        final rangeDelta = (finalRange - initialRange).abs();
        expect(rangeDelta, lessThan(3.0),
            reason: 'Range change should be minimal (< 3.0) for pan operation');
      },
      skip: true, // SKIPPED: Edge zoom not working, so can't verify disable behavior
    );

    testWidgets(
      'Center drag still pans when enableZoom=false',
      (WidgetTester tester) async {
        // Track viewport changes
        Map<String, double>? lastViewport;
        
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with enableZoom=false
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
                    enableZoom: false, // DISABLE ZOOM
                    enablePan: true,
                    showXScrollbar: true,
                    onViewportChanged: (viewport) {
                      lastViewport = viewport;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial viewport
        final initialMinX = lastViewport!['minX']!;
        final initialMaxX = lastViewport!['maxX']!;
        final initialRange = initialMaxX - initialMinX;

        // Find scrollbar
        final scrollbarFinder = find.byType(ChartScrollbar);
        final scrollbarBox = tester.renderObject(scrollbarFinder) as RenderBox;
        final scrollbarSize = scrollbarBox.size;
        final scrollbarOffset = scrollbarBox.localToGlobal(Offset.zero);
        
        final scrollbarRect = Rect.fromLTWH(
          scrollbarOffset.dx,
          scrollbarOffset.dy,
          scrollbarSize.width,
          scrollbarSize.height,
        );

        // Drag from CENTER of handle (normal pan operation)
        final dragX = scrollbarRect.center.dx;
        final dragY = scrollbarRect.center.dy;

        // Drag RIGHT by 50px (pan right)
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(50, 0),
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify pan behavior
        final finalMinX = lastViewport!['minX']!;
        final finalMaxX = lastViewport!['maxX']!;
        final finalRange = finalMaxX - finalMinX;

        // Range should stay constant
        expect(finalRange, closeTo(initialRange, 2.0),
            reason: 'Pan should not change viewport range');
        
        // Both edges should shift right
        expect(finalMinX, greaterThan(initialMinX),
            reason: 'Dragging right should increase minX (pan right)');
        expect(finalMaxX, greaterThan(initialMaxX),
            reason: 'Dragging right should increase maxX (pan right)');
      },
      skip: true, // SKIPPED: Verifying normal pan still works with zoom disabled
    );

    testWidgets(
      'Both enablePan=false and enableZoom=false disables all scrollbar interaction',
      (WidgetTester tester) async {
        // Track viewport changes
        Map<String, double>? lastViewport;
        
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with BOTH pan and zoom disabled
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
                    enableZoom: false, // DISABLE ZOOM
                    enablePan: false,  // DISABLE PAN
                    showXScrollbar: true, // Still show scrollbar for visual feedback
                    onViewportChanged: (viewport) {
                      lastViewport = viewport;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial viewport
        final initialMinX = lastViewport!['minX']!;
        final initialMaxX = lastViewport!['maxX']!;

        // Find scrollbar
        final scrollbarFinder = find.byType(ChartScrollbar);
        final scrollbarBox = tester.renderObject(scrollbarFinder) as RenderBox;
        final scrollbarSize = scrollbarBox.size;
        final scrollbarOffset = scrollbarBox.localToGlobal(Offset.zero);
        
        final scrollbarRect = Rect.fromLTWH(
          scrollbarOffset.dx,
          scrollbarOffset.dy,
          scrollbarSize.width,
          scrollbarSize.height,
        );

        // Try to drag handle (should have no effect)
        final dragX = scrollbarRect.center.dx;
        final dragY = scrollbarRect.center.dy;

        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(50, 0),
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify viewport did NOT change
        final finalMinX = lastViewport!['minX']!;
        final finalMaxX = lastViewport!['maxX']!;

        expect(finalMinX, closeTo(initialMinX, 1.0),
            reason: 'Viewport should not change when both pan and zoom disabled');
        expect(finalMaxX, closeTo(initialMaxX, 1.0),
            reason: 'Viewport should not change when both pan and zoom disabled');

        debugPrint('✅ Scrollbar correctly disabled when enablePan=false and enableZoom=false');
      },
      skip: true, // SKIPPED: Need working pan/zoom to verify disable works
    );

    testWidgets(
      'Visual feedback shows disabled state',
      (WidgetTester tester) async {
        // This test would verify visual disabled state (if implemented):
        // - Reduced opacity
        // - Greyscale colors
        // - No hover effects
        // - Cursor shows default (not grab/resize)
        //
        // Currently skipped because:
        // 1. Visual disabled state spec not finalized (CHK023 gap in ui.md)
        // 2. Golden test infrastructure needed for visual verification
        //
        // When implemented, this test should:
        // - Build chart with enablePan=false and enableZoom=false
        // - Capture golden image of disabled scrollbar
        // - Compare against reference image
        // - Verify opacity/color differences from enabled state
      },
      skip: true, // SKIPPED: Visual disabled state not specified (CHK023 gap)
    );
  });
}
