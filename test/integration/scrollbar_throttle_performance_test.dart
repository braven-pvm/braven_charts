// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Integration test: Rapid drag → verify 60 FPS throttling (T077).
///
/// This test validates that viewport updates are throttled to max 1 per 16ms (60 FPS)
/// during rapid drag operations to maintain performance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';

void main() {
  group('ChartScrollbar 60 FPS Throttling Integration (T077)', () {
    testWidgets('Rapid drag throttles viewport updates to ~60 FPS', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);
      
      final capturedViewports = <braven.DataRange>[];
      final timestamps = <int>[];

      // Build scrollbar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 44,
              child: ChartScrollbar(
                axis: Axis.horizontal,
                dataRange: dataRange,
                viewportRange: viewportRange,
                onViewportChanged: (newViewport) {
                  capturedViewports.add(newViewport);
                  timestamps.add(DateTime.now().millisecondsSinceEpoch);
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform rapid drag (simulate fast pointer movement)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final startPoint = tester.getCenter(scrollbarFinder);

      // Simulate rapid drag with many small movements
      final TestGesture gesture = await tester.startGesture(startPoint);
      
      // Move quickly in small increments
      for (int i = 0; i < 50; i++) {
        await gesture.moveBy(const Offset(2, 0));
        await tester.pump(const Duration(milliseconds: 1)); // Simulate 1000 FPS pointer events
      }
      
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify throttling occurred
      // With 50 move events at 1ms each = 50ms total drag
      // At 60 FPS (16ms per frame), max updates = 50ms / 16ms ≈ 3-4 updates
      // Plus initial update, we should have around 4-5 updates during drag
      // Plus final flush in _onPanEnd
      
      expect(capturedViewports.length, lessThanOrEqualTo(10), 
        reason: 'Throttling should limit viewport updates even with rapid pointer events');
      
      // Check time deltas between updates (excluding final flush)
      if (timestamps.length >= 3) {
        final deltas = <int>[];
        for (int i = 1; i < timestamps.length - 1; i++) {
          deltas.add(timestamps[i] - timestamps[i - 1]);
        }
        
        // Most deltas should be >= 15ms (allowing 1ms tolerance for 16ms throttle)
        final throttledDeltas = deltas.where((d) => d >= 15).length;
        final ratio = throttledDeltas / deltas.length;
        
        expect(ratio, greaterThan(0.5), 
          reason: 'Most viewport updates should be throttled to ~16ms intervals');
      }
    });

    testWidgets('Final viewport update fires immediately on pan end', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);
      
      final capturedViewports = <braven.DataRange>[];

      // Build scrollbar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 44,
              child: ChartScrollbar(
                axis: Axis.horizontal,
                dataRange: dataRange,
                viewportRange: viewportRange,
                onViewportChanged: (newViewport) {
                  capturedViewports.add(newViewport);
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform drag
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      await tester.drag(scrollbarFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Verify at least one viewport update occurred
      expect(capturedViewports.length, greaterThan(0), 
        reason: 'Viewport updates should occur during drag');
      
      // Verify final viewport reflects complete drag distance
      // (This tests T070 - final sync in _onPanEnd)
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, greaterThan(0), 
        reason: 'Final viewport should reflect full drag distance');
    });

    testWidgets('Throttling does not drop final viewport state', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);
      
      final capturedViewports = <braven.DataRange>[];

      // Build scrollbar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 44,
              child: ChartScrollbar(
                axis: Axis.horizontal,
                dataRange: dataRange,
                viewportRange: viewportRange,
                onViewportChanged: (newViewport) {
                  capturedViewports.add(newViewport);
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform very short rapid drag
      final scrollbarFinder = find.byType(ChartScrollbar);
      final startPoint = tester.getCenter(scrollbarFinder);

      final TestGesture gesture = await tester.startGesture(startPoint);
      
      // Quick burst of movements
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 5));
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 5));
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 5));
      
      // End drag immediately (within throttle window)
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify final viewport update occurred (T070 - flush pending update)
      expect(capturedViewports.isNotEmpty, true, 
        reason: 'Final viewport update should fire even if throttle is active');
      
      // Verify final viewport reflects all movements
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, greaterThan(0), 
        reason: 'Throttling should not lose the final viewport state');
    });
  });
}
