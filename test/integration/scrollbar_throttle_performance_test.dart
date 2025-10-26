// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Integration test: Rapid drag → verify 60 FPS throttling (T077).
///
/// This test validates that viewport updates are throttled to max 1 per 16ms (60 FPS)
/// during rapid drag operations to maintain performance.
library;

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartScrollbar 60 FPS Throttling Integration (T077)', () {
    testWidgets('Rapid drag throttles viewport updates to ~60 FPS', (WidgetTester tester) async {
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

      // Perform rapid drag (simulate fast pointer movement)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final startPoint = tester.getCenter(scrollbarFinder);

      // Simulate rapid drag with many small movements
      final TestGesture gesture = await tester.startGesture(startPoint);

      // Move quickly in small increments
      // Each moveBy triggers _onPanUpdate, which should be throttled to 60 FPS
      for (int i = 0; i < 50; i++) {
        await gesture.moveBy(const Offset(2, 0));
        // Pump with 1ms to create rapid updates (simulating fast pointer movement)
        await tester.pump(const Duration(milliseconds: 1));
      }

      await gesture.up();
      await tester.pumpAndSettle();

      // Verify throttling occurred
      // With 50 move events, WITHOUT throttling we'd get 50+ viewport updates
      // WITH throttling (Timer 16ms), callbacks should be significantly reduced
      // Expected: In test with rapid pumps, throttle mechanism should batch updates
      
      // The implementation fires first update immediately, then throttles to 16ms windows
      // With 50 rapid moves, we expect far fewer than 50 callbacks
      expect(capturedViewports.length, lessThan(50),
        reason: 'Throttling must reduce callback count below move event count');
      
      // Verify throttling is effective (< 80% of move events became callbacks)
      final throttleRatio = capturedViewports.length / 50;
      expect(throttleRatio, lessThan(0.8),
        reason: 'Throttling should reduce callbacks to < 80% of move events');
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
      expect(capturedViewports.length, greaterThan(0), reason: 'Viewport updates should occur during drag');

      // Verify final viewport reflects complete drag distance
      // (This tests T070 - final sync in _onPanEnd)
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, greaterThan(0), reason: 'Final viewport should reflect full drag distance');
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
      expect(capturedViewports.isNotEmpty, true, reason: 'Final viewport update should fire even if throttle is active');

      // Verify final viewport reflects all movements
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, greaterThan(0), reason: 'Throttling should not lose the final viewport state');
    });
  });
}
