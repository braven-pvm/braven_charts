// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Integration test: Pan drag completes → verify onPanChanged callback (T078).
///
/// This test validates that the onPanChanged callback fires correctly when
/// pan gesture completes, with the correct delta offset.
library;

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartScrollbar onPanChanged Callback Integration (T078)', () {
    testWidgets('Pan drag horizontal → onPanChanged fires with dx delta', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);

      Offset? capturedPanOffset;

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
                  viewportRange = newViewport;
                },
                onPanChanged: (offset) {
                  capturedPanOffset = offset;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform horizontal drag on handle
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarCenter = tester.getCenter(scrollbarFinder);
      // Start drag from handle center (handle starts at 0%, is 20% wide, so center at 10% = 40px from left)
      final startPoint = Offset(scrollbarCenter.dx - 200 + 40, scrollbarCenter.dy);

      // Drag handle 100px to the right
      await tester.dragFrom(startPoint, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Verify onPanChanged fired with dx delta
      expect(capturedPanOffset, isNotNull, reason: 'onPanChanged should fire on drag completion');
      expect(capturedPanOffset!.dx, greaterThan(0), reason: 'dx should reflect positive horizontal pan');
      expect(capturedPanOffset!.dy, 0, reason: 'dy should be 0 for horizontal scrollbar');
    });

    testWidgets('Pan drag vertical → onPanChanged fires with dy delta', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);

      Offset? capturedPanOffset;

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
                  viewportRange = newViewport;
                },
                onPanChanged: (offset) {
                  capturedPanOffset = offset;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform vertical drag on handle
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarCenter = tester.getCenter(scrollbarFinder);
      // Start drag from handle center (handle starts at 0%, is 20% tall, so center at 10% = 40px from top)
      final startPoint = Offset(scrollbarCenter.dx, scrollbarCenter.dy - 200 + 40);

      // Drag handle 100px down
      await tester.dragFrom(startPoint, const Offset(0, 100));
      await tester.pumpAndSettle();

      // Verify onPanChanged fired with dy delta
      expect(capturedPanOffset, isNotNull, reason: 'onPanChanged should fire on drag completion');
      expect(capturedPanOffset!.dx, 0, reason: 'dx should be 0 for vertical scrollbar');
      expect(capturedPanOffset!.dy, greaterThan(0), reason: 'dy should reflect positive vertical pan');
    });

    testWidgets('Pan delta reflects total viewport change', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 10, max: 30); // Start at 10

      Offset? capturedPanOffset;
      final double initialViewportMin = viewportRange.min;

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
                  viewportRange = newViewport;
                },
                onPanChanged: (offset) {
                  capturedPanOffset = offset;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform drag on handle
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarCenter = tester.getCenter(scrollbarFinder);
      // Handle starts at 10% position (10/100 * 400 = 40px from left)
      // Handle is 20% wide ((20/100) * 400 = 80px)
      // Handle center = 40px + 40px = 80px from left edge
      final startPoint = Offset(scrollbarCenter.dx - 200 + 80, scrollbarCenter.dy);

      // Drag handle 80px to the right
      await tester.dragFrom(startPoint, const Offset(80, 0));
      await tester.pumpAndSettle();

      // Calculate expected delta
      final actualDelta = viewportRange.min - initialViewportMin;

      // Verify pan delta matches viewport change
      expect(capturedPanOffset, isNotNull);
      expect(capturedPanOffset!.dx, closeTo(actualDelta, 1), reason: 'Pan delta should match total viewport change from start to end');
    });

    testWidgets('onPanChanged not called if callback is null', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);

      // Build scrollbar widget WITHOUT onPanChanged callback
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
                  viewportRange = newViewport;
                },
                // onPanChanged: null (omitted)
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform drag
      final scrollbarFinder = find.byType(ChartScrollbar);

      // This should NOT throw even with null onPanChanged
      await tester.drag(scrollbarFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Test passes if no exception thrown
      expect(true, true, reason: 'Drag should complete without error when onPanChanged is null');
    });

    testWidgets('onPanChanged fires once per gesture', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);

      int callbackCount = 0;

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
                  viewportRange = newViewport;
                },
                onPanChanged: (offset) {
                  callbackCount++;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform drag with multiple move events
      final scrollbarFinder = find.byType(ChartScrollbar);
      final startPoint = tester.getCenter(scrollbarFinder);

      final TestGesture gesture = await tester.startGesture(startPoint);

      // Multiple move events during drag
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      // End gesture
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify onPanChanged fired exactly once (on gesture end)
      expect(callbackCount, 1, reason: 'onPanChanged should fire exactly once per gesture, not during intermediate moves');
    });

    testWidgets('Pan backward → negative delta', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 50, max: 70); // Start in middle

      Offset? capturedPanOffset;

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
                  viewportRange = newViewport;
                },
                onPanChanged: (offset) {
                  capturedPanOffset = offset;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Perform backward drag (negative direction) on handle
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarCenter = tester.getCenter(scrollbarFinder);
      // Handle starts at 50% position (50/100 * 400 = 200px from left)
      // Handle is 20% wide ((20/100) * 400 = 80px)
      // Handle center = 200px + 40px = 240px from left edge
      final startPoint = Offset(scrollbarCenter.dx - 200 + 240, scrollbarCenter.dy);

      // Drag handle 100px to the LEFT (negative direction)
      await tester.dragFrom(startPoint, const Offset(-100, 0));
      await tester.pumpAndSettle();

      // Verify negative delta
      expect(capturedPanOffset, isNotNull);
      expect(capturedPanOffset!.dx, lessThan(0), reason: 'Pan delta should be negative for backward drag');
    });
  });
}
