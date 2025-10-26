// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Integration test: Drag beyond data boundaries → verify clamping (T075).
///
/// This test validates that the scrollbar prevents overscroll beyond the data range
/// and properly clamps viewport to valid boundaries.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';

void main() {
  group('ChartScrollbar Boundary Clamping Integration (T075)', () {
    testWidgets('Drag beyond right boundary → viewport clamped to max', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 60, max: 80); // Start near end
      
      braven.DataRange? capturedViewport;

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
                  capturedViewport = newViewport;
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Try to drag beyond right boundary
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      // Drag far to the right (way beyond boundary)
      await tester.drag(scrollbarFinder, const Offset(500, 0));
      await tester.pumpAndSettle();

      // Verify viewport clamped at maximum (80-100)
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.max, 100); // Clamped to dataRange.max
      expect(capturedViewport!.min, 80); // min = max - viewportSize
      expect(capturedViewport!.span, 20); // Viewport size unchanged
    });

    testWidgets('Drag beyond left boundary → viewport clamped to min', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 20, max: 40); // Start near beginning
      
      braven.DataRange? capturedViewport;

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
                  capturedViewport = newViewport;
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Try to drag beyond left boundary
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      // Drag far to the left (way beyond boundary)
      await tester.drag(scrollbarFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify viewport clamped at minimum (0-20)
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.min, 0); // Clamped to dataRange.min
      expect(capturedViewport!.max, 20); // max = min + viewportSize
      expect(capturedViewport!.span, 20); // Viewport size unchanged
    });

    testWidgets('Drag within boundaries → viewport not clamped', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 40, max: 60); // Middle of range
      
      braven.DataRange? capturedViewport;

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
                  capturedViewport = newViewport;
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Drag moderate distance (within boundaries)
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      await tester.drag(scrollbarFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Verify viewport moved but not clamped
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.min, greaterThan(40)); // Moved forward
      expect(capturedViewport!.max, lessThan(100)); // Not clamped to max
      expect(capturedViewport!.span, 20); // Viewport size unchanged
    });

    testWidgets('Vertical scrollbar clamps at boundaries', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20); // Start at top
      
      braven.DataRange? capturedViewport;

      // Build scrollbar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 44,
              height: 400,
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

      // Try to drag beyond top boundary (negative direction)
      final scrollbarFinder = find.byType(ChartScrollbar);
      
      await tester.drag(scrollbarFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify viewport clamped at minimum
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.min, 0);
      expect(capturedViewport!.max, 20);
      expect(capturedViewport!.span, 20);
    });
  });
}
