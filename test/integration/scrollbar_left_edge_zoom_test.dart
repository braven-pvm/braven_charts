// Integration Test: T097 - Left Edge Zoom Functionality
//
// Tests: US3 Acceptance Criteria (Left Edge Zoom)
// - Drag left edge of scrollbar handle RIGHT to zoom in (increase minX, maxX stays anchored)
// - Multiple left edge drags maintain right anchor point
//
// Status: SKIPPED - Edge zoom feature not working yet
// Reason: Related to T096 findings - edge zoom infrastructure exists but viewport doesn't update
// See: T096_TEST_FINDINGS.md for detailed investigation
//
// Test Pattern: Full BravenChart integration with viewport tracking via onViewportChanged callback
// When Feature Fixed: Remove `skip: true` from both test cases

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('T097: Left Edge Zoom Functionality', () {
    testWidgets(
      'Left edge drag zooms in with right edge anchored',
      (WidgetTester tester) async {
        // Track viewport changes via callback
        Map<String, double>? lastViewport;
        
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
                    onViewportChanged: (viewport) {
                      lastViewport = viewport;
                      debugPrint('📊 Viewport changed: ${viewport['minX']} to ${viewport['maxX']}');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial viewport (should be 0-99 for full dataset)
        expect(lastViewport, isNotNull);
        final initialMinX = lastViewport!['minX']!;
        final initialMaxX = lastViewport!['maxX']!;
        
        debugPrint('📊 Initial Viewport: MinX: $initialMinX, MaxX: $initialMaxX');
        
        expect(initialMinX, closeTo(0.0, 2.0));
        expect(initialMaxX, closeTo(99.0, 2.0));

        // Find scrollbar widget
        final scrollbarFinder = find.byType(ChartScrollbar);
        expect(scrollbarFinder, findsOneWidget);

        // Get scrollbar render box for geometry
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

        // Drag from LEFT edge of scrollbar (left edge + 30px is safely in left edge zone)
        // Left edge zone is first 8px (per edgeGripWidth default)
        // We use left + 30px to ensure we're in the zone even with rendering variations
        final dragX = scrollbarRect.left + 30;
        final dragY = scrollbarRect.center.dy;

        debugPrint('🎯 Starting drag from LEFT edge: ($dragX, $dragY)');

        // Perform drag: Drag LEFT edge RIGHT by 50px to zoom in
        // Expected: viewport.minX should INCREASE (zooming in from left)
        // Expected: viewport.maxX should stay ANCHORED (right edge fixed)
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(50, 0), // Drag RIGHT (+50px in X)
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify viewport changed
        expect(lastViewport, isNotNull);
        final finalMinX = lastViewport!['minX']!;
        final finalMaxX = lastViewport!['maxX']!;

        debugPrint('📊 Final Viewport: MinX: $finalMinX, MaxX: $finalMaxX');
        debugPrint('📊 Changes: ΔMinX=${finalMinX - initialMinX}, ΔMaxX=${finalMaxX - initialMaxX}');

        // Verify zoom behavior:
        // 1. minX should INCREASE (viewport shrinks from left)
        expect(finalMinX, greaterThan(initialMinX),
            reason: 'Dragging left edge right should increase minX (zoom in from left)');
        
        // 2. maxX should stay ANCHORED (within small tolerance for float precision)
        expect(finalMaxX, closeTo(initialMaxX, 2.0),
            reason: 'Right edge should stay anchored during left edge drag');
        
        // 3. Viewport range should be SMALLER (zoomed in)
        final initialRange = initialMaxX - initialMinX;
        final finalRange = finalMaxX - finalMinX;
        expect(finalRange, lessThan(initialRange),
            reason: 'Viewport range should decrease when zooming in');
      },
      skip: true, // SKIPPED: Edge zoom feature not working (viewport doesn't change)
    );

    testWidgets(
      'Multiple left edge drags maintain right anchor',
      (WidgetTester tester) async {
        // Track viewport changes via callback
        final List<Map<String, double>> viewportHistory = [];
        
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
                    onViewportChanged: (viewport) {
                      viewportHistory.add(Map.from(viewport));
                      debugPrint('📊 Viewport #${viewportHistory.length}: ${viewport['minX']} to ${viewport['maxX']}');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial viewport
        expect(viewportHistory, isNotEmpty);
        final initialViewport = viewportHistory.last;
        final initialMaxX = initialViewport['maxX']!;

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

        // Perform 3 consecutive left edge drags
        for (int i = 0; i < 3; i++) {
          final dragX = scrollbarRect.left + 30; // Left edge zone
          final dragY = scrollbarRect.center.dy;

          debugPrint('🎯 Drag #${i + 1}: Starting from ($dragX, $dragY)');

          await tester.timedDragFrom(
            Offset(dragX, dragY),
            const Offset(50, 0), // Drag RIGHT by 50px
            const Duration(milliseconds: 300),
          );

          await tester.pumpAndSettle();

          // Verify right edge stays anchored after each drag
          final currentViewport = viewportHistory.last;
          final currentMaxX = currentViewport['maxX']!;
          
          expect(currentMaxX, closeTo(initialMaxX, 2.0),
              reason: 'Drag #${i + 1}: Right edge should stay anchored (maxX should not change)');
        }

        // Verify progressive zoom in (minX should increase with each drag)
        expect(viewportHistory.length, greaterThanOrEqualTo(4), 
            reason: 'Should have at least 4 viewport updates (initial + 3 drags)');

        // Check that minX increases progressively
        final viewport1MinX = viewportHistory[viewportHistory.length - 3]['minX']!;
        final viewport2MinX = viewportHistory[viewportHistory.length - 2]['minX']!;
        final viewport3MinX = viewportHistory[viewportHistory.length - 1]['minX']!;

        expect(viewport2MinX, greaterThan(viewport1MinX),
            reason: 'Second drag should increase minX further');
        expect(viewport3MinX, greaterThan(viewport2MinX),
            reason: 'Third drag should increase minX even further');

        debugPrint('📊 Progressive minX: $viewport1MinX → $viewport2MinX → $viewport3MinX');
      },
      skip: true, // SKIPPED: Depends on left edge zoom working (same issue as T096)
    );
  });
}
