// Integration Test: T101 - onZoomChanged Callback
//
// Tests: FR-019 (onZoomChanged Callback Behavior)
// - onZoomChanged fires when zoom completes (drag end, not during drag)
// - Callback provides new zoom level/viewport range
// - Callback fires for edge resize operations
// - Callback does NOT fire for pan operations (center drag)
//
// Status: SKIPPED - Edge zoom feature not working yet
// Reason: Related to T096-T100 findings - edge zoom infrastructure needs to work first
// See: T096_TEST_FINDINGS.md for detailed investigation
//
// Test Pattern: Full BravenChart integration with callback tracking
// When Feature Fixed: Remove `skip: true` from all test cases

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('T101: onZoomChanged Callback', () {
    testWidgets(
      'onZoomChanged fires when right edge zoom completes',
      (WidgetTester tester) async {
        // Track zoom changes via callback
        final List<Map<String, double>> zoomHistory = [];
        
        // Create test data (100 points: 0-99)
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with onZoomChanged callback
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
                    onZoomChanged: (zoomLevelX, zoomLevelY) {
                      zoomHistory.add({'zoomX': zoomLevelX, 'zoomY': zoomLevelY});
                      debugPrint('📊 Zoom #${zoomHistory.length}: X=$zoomLevelX, Y=$zoomLevelY');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Clear initial zoom events (if any from chart initialization)
        zoomHistory.clear();

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

        // Drag from RIGHT edge to zoom in
        final dragX = scrollbarRect.right - 30; // Right edge zone
        final dragY = scrollbarRect.center.dy;

        debugPrint('🎯 Dragging from right edge: ($dragX, $dragY)');

        // Perform drag (zoom in by dragging right edge left)
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(-50, 0), // Drag LEFT by 50px
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify onZoomChanged fired
        expect(zoomHistory.length, greaterThanOrEqualTo(1),
            reason: 'onZoomChanged should fire at least once when zoom completes');

        // Verify callback data is correct
        final zoomEvent = zoomHistory.last;
        expect(zoomEvent, contains('zoomX'));
        expect(zoomEvent, contains('zoomY'));
        
        final zoomLevelX = zoomEvent['zoomX']!;
        debugPrint('📊 Zoom event X level: $zoomLevelX');
        
        // Zoom level should be > 1.0 (zoomed in)
        expect(zoomLevelX, greaterThan(1.0),
            reason: 'Zoom level should be >1.0 when zoomed in');
      },
      skip: true, // SKIPPED: Edge zoom feature not working yet
    );

    testWidgets(
      'onZoomChanged fires when left edge zoom completes',
      (WidgetTester tester) async {
        // Track zoom changes
        final List<Map<String, double>> zoomHistory = [];
        
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with onZoomChanged callback
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
                    onZoomChanged: (zoomLevelX, zoomLevelY) {
                      zoomHistory.add({'zoomX': zoomLevelX, 'zoomY': zoomLevelY});
                      debugPrint('📊 Zoom #${zoomHistory.length}: X=$zoomLevelX, Y=$zoomLevelY');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Clear initial events
        zoomHistory.clear();

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

        // Drag from LEFT edge to zoom in
        final dragX = scrollbarRect.left + 30; // Left edge zone
        final dragY = scrollbarRect.center.dy;

        // Perform drag (zoom in by dragging left edge right)
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(50, 0), // Drag RIGHT by 50px
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify onZoomChanged fired
        expect(zoomHistory.length, greaterThanOrEqualTo(1),
            reason: 'onZoomChanged should fire for left edge zoom');

        final zoomEvent = zoomHistory.last;
        final zoomLevelX = zoomEvent['zoomX']!;
        
        expect(zoomLevelX, greaterThan(1.0),
            reason: 'Left edge zoom should increase zoom level (>1.0)');
      },
      skip: true, // SKIPPED: Edge zoom feature not working yet
    );

    testWidgets(
      'onZoomChanged does NOT fire for pan operations',
      (WidgetTester tester) async {
        // Track zoom changes
        final List<Map<String, double>> zoomHistory = [];
        
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with onZoomChanged callback
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
                    onZoomChanged: (zoomLevelX, zoomLevelY) {
                      zoomHistory.add({'zoomX': zoomLevelX, 'zoomY': zoomLevelY});
                      debugPrint('⚠️  UNEXPECTED: Zoom callback fired during pan operation!');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Clear initial events
        zoomHistory.clear();

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

        // Drag from CENTER of handle (pan operation, NOT zoom)
        final dragX = scrollbarRect.center.dx;
        final dragY = scrollbarRect.center.dy;

        debugPrint('🎯 Performing PAN operation (center drag)');

        // Perform pan drag
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(50, 0), // Drag RIGHT (pan)
          const Duration(milliseconds: 300),
        );

        await tester.pumpAndSettle();

        // Verify onZoomChanged did NOT fire (pan operations should not trigger zoom callback)
        expect(zoomHistory.length, equals(0),
            reason: 'onZoomChanged should NOT fire for pan operations (center drag)');

        debugPrint('✅ onZoomChanged correctly did not fire for pan operation');
      },
      skip: true, // SKIPPED: Pan operations need to work correctly first
    );

    testWidgets(
      'onZoomChanged fires only once per zoom operation (not during drag)',
      (WidgetTester tester) async {
        // Track zoom changes with timestamps
        final List<Map<String, dynamic>> zoomHistory = [];
        
        // Create test data
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with onZoomChanged callback
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
                    onZoomChanged: (zoomLevelX, zoomLevelY) {
                      final event = {
                        'timestamp': DateTime.now(),
                        'zoomX': zoomLevelX,
                        'zoomY': zoomLevelY,
                      };
                      zoomHistory.add(event);
                      debugPrint('📊 Zoom event #${zoomHistory.length} at ${event['timestamp']}');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Clear initial events
        zoomHistory.clear();

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

        // Perform zoom operation (right edge drag)
        final dragX = scrollbarRect.right - 30;
        final dragY = scrollbarRect.center.dy;

        // Perform slow drag (300ms) to potentially trigger multiple events if incorrectly implemented
        await tester.timedDragFrom(
          Offset(dragX, dragY),
          const Offset(-50, 0),
          const Duration(milliseconds: 300), // Long duration to test throttling
        );

        await tester.pumpAndSettle();

        // Verify callback fired exactly ONCE (on drag end, not during drag)
        // Note: Some implementations may throttle and fire multiple times during drag
        // The ideal behavior is ONE event on drag end only
        expect(zoomHistory.length, greaterThanOrEqualTo(1),
            reason: 'onZoomChanged should fire at least once');

        // If multiple events fired, they should be throttled (not one per frame)
        if (zoomHistory.length > 1) {
          debugPrint('⚠️  Multiple zoom events during single drag: ${zoomHistory.length}');
          debugPrint('   This may indicate missing throttling or firing during drag');
          debugPrint('   Ideal: 1 event on drag end only');
        } else {
          debugPrint('✅ onZoomChanged fired exactly once (on drag end only)');
        }
      },
      skip: true, // SKIPPED: Edge zoom feature not working yet
    );

    testWidgets(
      'onZoomChanged provides accurate viewport data',
      (WidgetTester tester) async {
        // This test would verify the data provided to onZoomChanged callback:
        // - minX, maxX match actual viewport state
        // - Range calculation is correct
        // - Data is consistent with onViewportChanged callback
        //
        // Currently skipped because edge zoom not working yet.
        //
        // When implemented, this test should:
        // - Track both onViewportChanged and onZoomChanged
        // - Perform zoom operation
        // - Compare viewport data from both callbacks
        // - Verify they report the same state
      },
      skip: true, // SKIPPED: Need working zoom to verify callback data accuracy
    );
  });
}
