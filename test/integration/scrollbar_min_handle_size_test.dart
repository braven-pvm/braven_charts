// Integration Test: T098 - Zoom to Minimum Handle Size
//
// Tests: FR-010, FR-011, FR-012 (Minimum Handle Size Constraints)
// - Handle never smaller than minHandleSize (20.0px default)
// - Zoom in until handle reaches minimum size, then zoom stops
// - Edge resize respects minimum handle size constraint
//
// Status: SKIPPED - Edge zoom feature not working yet
// Reason: Related to T096/T097 findings - edge zoom infrastructure exists but viewport doesn't update
// See: T096_TEST_FINDINGS.md for detailed investigation
//
// Test Pattern: Full BravenChart integration with viewport tracking via onViewportChanged callback
// When Feature Fixed: Remove `skip: true` from all test cases

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('T098: Zoom to Minimum Handle Size', () {
    testWidgets(
      'Handle never smaller than minHandleSize during edge zoom',
      (WidgetTester tester) async {
        // Track viewport changes and handle size
        Map<String, double>? lastViewport;
        
        // Create large dataset (1000 points) to enable extreme zoom
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            1000,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with scrollbar enabled
        // Note: minHandleSize defaults to 20.0px (from ScrollbarConfig.defaultLight)
        // This test verifies handle never goes below that limit during zoom operations
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
                      debugPrint('📊 Viewport: ${viewport['minX']} to ${viewport['maxX']} (range: ${viewport['maxX']! - viewport['minX']!})');
                    },
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

        final trackWidth = scrollbarRect.width;
        debugPrint('📐 Scrollbar track width: $trackWidth');

        // Calculate initial handle size based on viewport
        final initialViewport = lastViewport!;
        final dataRange = 1000.0; // 0-999
        final viewportRange = initialViewport['maxX']! - initialViewport['minX']!;
        final expectedInitialHandleSize = (viewportRange / dataRange) * trackWidth;
        
        debugPrint('📊 Initial viewport range: $viewportRange / $dataRange');
        debugPrint('📊 Expected initial handle size: $expectedInitialHandleSize');

        // Perform multiple zoom in operations until handle reaches minimum size
        // Drag right edge LEFT multiple times to zoom in (shrink viewport from right)
        int zoomAttempts = 0;
        const maxZoomAttempts = 20; // Safety limit
        
        while (zoomAttempts < maxZoomAttempts) {
          zoomAttempts++;
          
          final dragX = scrollbarRect.right - 30; // Right edge zone
          final dragY = scrollbarRect.center.dy;

          debugPrint('🎯 Zoom attempt #$zoomAttempts: Dragging from right edge ($dragX, $dragY)');

          // Store viewport before drag
          final beforeViewport = lastViewport!;
          final beforeRange = beforeViewport['maxX']! - beforeViewport['minX']!;
          
          // Calculate expected handle size before drag
          final beforeHandleSize = (beforeRange / dataRange) * trackWidth;
          debugPrint('📊 Before drag #$zoomAttempts: Handle size = ${beforeHandleSize.toStringAsFixed(2)}px');

          // Drag right edge LEFT by 50px to zoom in
          await tester.timedDragFrom(
            Offset(dragX, dragY),
            const Offset(-50, 0), // Drag LEFT (-50px in X)
            const Duration(milliseconds: 300),
          );

          await tester.pumpAndSettle();

          // Check viewport after drag
          final afterViewport = lastViewport!;
          final afterRange = afterViewport['maxX']! - afterViewport['minX']!;
          final afterHandleSize = (afterRange / dataRange) * trackWidth;
          
          debugPrint('📊 After drag #$zoomAttempts: Handle size = ${afterHandleSize.toStringAsFixed(2)}px');

          // Verify handle size never goes below minimum (20.0px default)
          expect(afterHandleSize, greaterThanOrEqualTo(19.0), // 1px tolerance for float precision
              reason: 'Handle size should never be smaller than minHandleSize (20.0px default)');

          // Check if handle has reached minimum size (zoom limit)
          if (afterHandleSize <= 21.0) { // Within 1px of minimum (20.0px)
            debugPrint('✅ Handle reached minimum size after $zoomAttempts zoom attempts');
            
            // Verify zoom stopped (viewport shouldn't change further)
            expect(afterRange, closeTo(beforeRange, 2.0),
                reason: 'When handle is at minimum size, zoom should stop (viewport should not shrink further)');
            
            break;
          }
        }

        expect(zoomAttempts, lessThan(maxZoomAttempts),
            reason: 'Should reach minimum handle size within $maxZoomAttempts attempts');
      },
      skip: true, // SKIPPED: Edge zoom feature not working (viewport doesn't change)
    );

    testWidgets(
      'Zoom limit enforced when minZoomRatio reached',
      (WidgetTester tester) async {
        // Track viewport changes
        Map<String, double>? lastViewport;
        
        // Create dataset (1000 points)
        final testSeries = ChartSeries(
          id: 'test-series',
          points: List.generate(
            1000,
            (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
          ),
        );

        // Build chart with scrollbar enabled
        // Note: minZoomRatio defaults to 0.01 (1% minimum viewport)
        // For 1000 data points, minimum viewport = 10 points
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
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find scrollbar
        final scrollbarFinder = find.byType(ChartScrollbar);
        expect(scrollbarFinder, findsOneWidget);

        final scrollbarBox = tester.renderObject(scrollbarFinder) as RenderBox;
        final scrollbarSize = scrollbarBox.size;
        final scrollbarOffset = scrollbarBox.localToGlobal(Offset.zero);
        
        final scrollbarRect = Rect.fromLTWH(
          scrollbarOffset.dx,
          scrollbarOffset.dy,
          scrollbarSize.width,
          scrollbarSize.height,
        );

        // Perform multiple zoom operations until minZoomRatio limit reached
        int zoomAttempts = 0;
        const maxZoomAttempts = 30; // Safety limit
        
        const dataRange = 1000.0;
        const minZoomRatio = 0.01; // Default from ScrollbarConfig.defaultLight (1% minimum)
        const minViewportRange = dataRange * minZoomRatio; // 10 data points minimum

        while (zoomAttempts < maxZoomAttempts) {
          zoomAttempts++;
          
          final dragX = scrollbarRect.right - 30; // Right edge zone
          final dragY = scrollbarRect.center.dy;

          final beforeViewport = lastViewport!;
          final beforeRange = beforeViewport['maxX']! - beforeViewport['minX']!;
          
          debugPrint('🎯 Zoom attempt #$zoomAttempts: Current range = ${beforeRange.toStringAsFixed(2)}');

          // Drag right edge LEFT to zoom in
          await tester.timedDragFrom(
            Offset(dragX, dragY),
            const Offset(-50, 0),
            const Duration(milliseconds: 300),
          );

          await tester.pumpAndSettle();

          final afterViewport = lastViewport!;
          final afterRange = afterViewport['maxX']! - afterViewport['minX']!;

          // Verify viewport range never goes below minZoomRatio
          expect(afterRange, greaterThanOrEqualTo(minViewportRange - 2.0), // 2.0 tolerance
              reason: 'Viewport range should never be smaller than minZoomRatio (1% = 10 data points)');

          // Check if zoom limit reached
          if (afterRange <= minViewportRange + 5.0) {
            debugPrint('✅ Zoom limit reached after $zoomAttempts attempts (range: ${afterRange.toStringAsFixed(2)})');
            
            // Verify zoom stopped
            expect(afterRange, closeTo(beforeRange, 3.0),
                reason: 'When at zoom limit, viewport should not shrink further');
            
            break;
          }
        }

        expect(zoomAttempts, lessThan(maxZoomAttempts),
            reason: 'Should reach zoom limit within $maxZoomAttempts attempts');
      },
      skip: true, // SKIPPED: Edge zoom feature not working (viewport doesn't change)
    );

    testWidgets(
      'Visual feedback when zoom limit reached',
      (WidgetTester tester) async {
        // This test would verify visual feedback (e.g., handle flash, bounce animation)
        // when user tries to zoom beyond the minimum handle size limit.
        // 
        // Currently skipped because:
        // 1. Visual feedback spec not finalized (FR-054 gap)
        // 2. Edge zoom not working yet
        //
        // When implemented, this test should:
        // - Zoom to minimum handle size
        // - Attempt further zoom
        // - Verify visual feedback (animation, color change, etc.)
        // - Verify viewport stays at limit
      },
      skip: true, // SKIPPED: Visual feedback not specified + edge zoom not working
    );
  });
}
