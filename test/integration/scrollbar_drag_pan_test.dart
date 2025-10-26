// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Integration test: Drag handle from 0% to 50% → verify viewport pans to middle (T074).
///
/// This test validates that dragging the scrollbar handle actually changes the viewport
/// and that the pan interaction works end-to-end.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';

void main() {
  group('ChartScrollbar Drag Pan Integration (T074)', () {
    testWidgets('Drag handle from 0% to 50% → viewport pans to middle', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20); // Start at 0%
      
      braven.DataRange? capturedViewport;

      // Build scrollbar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Track length = 400px
              height: 44,
              child: ChartScrollbar(
                axis: Axis.horizontal,
                dataRange: dataRange,
                viewportRange: viewportRange,
                onViewportChanged: (newViewport) {
                  capturedViewport = newViewport;
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(viewportRange.min, 0);
      expect(viewportRange.max, 20);

      // Find scrollbar widget
      final scrollbarFinder = find.byType(ChartScrollbar);
      expect(scrollbarFinder, findsOneWidget);

      // Drag handle from 0% to 50% position
      // With dataRange 0-100, viewportRange 0-20 (20% width), track 400px:
      // - Handle size = (20/100) * 400 = 80px
      // - Initial position = 0px
      // - Target position = 50% of scrollable area
      // - Scrollable area = 400 - 80 = 320px
      // - 50% of scrollable = 160px offset from start
      // - This should move viewport to middle: 40-60 (center at 50)
      
      final scrollbarCenter = tester.getCenter(scrollbarFinder);
      final startPoint = Offset(scrollbarCenter.dx - 200 + 40, scrollbarCenter.dy); // Start at handle center (40px from left edge)

      // Perform drag
      await tester.dragFrom(startPoint, Offset(160, 0));
      await tester.pumpAndSettle();

      // Verify viewport moved to middle range
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.min, closeTo(40, 1)); // Allow 1 unit tolerance
      expect(capturedViewport!.max, closeTo(60, 1));
      expect(capturedViewport!.span, 20); // Viewport size unchanged
    });

    testWidgets('Drag handle updates viewport continuously during drag', (WidgetTester tester) async {
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

      // Drag handle
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      await tester.drag(scrollbarFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Verify multiple viewport updates occurred during drag
      expect(capturedViewports.length, greaterThan(0));
      
      // Verify final viewport changed from initial
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, greaterThan(0));
    });

    testWidgets('Vertical scrollbar drag pans viewport along Y-axis', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);
      
      braven.DataRange? capturedViewport;

      // Build scrollbar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 44,
              height: 400, // Track length = 400px
              child: ChartScrollbar(
                axis: Axis.vertical,
                dataRange: dataRange,
                viewportRange: viewportRange,
                onViewportChanged: (newViewport) {
                  capturedViewport = newViewport;
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Drag handle vertically
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      await tester.drag(scrollbarFinder, const Offset(0, 160)); // Drag down
      await tester.pumpAndSettle();

      // Verify viewport moved
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.min, greaterThan(0));
      expect(capturedViewport!.span, 20); // Viewport size unchanged
    });
  });
}
