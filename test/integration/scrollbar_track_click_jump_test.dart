// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Integration test: Click track at 70% → verify handle animates to 70% over 300ms (T076).
///
/// This test validates that clicking the scrollbar track triggers a smooth animated jump
/// to the click position with the correct duration and curve.
library;

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartScrollbar Track Click Jump Animation Integration (T076)', () {
    testWidgets('Click track at 70% → handle animates to 70% position', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20); // Start at 0%

      final capturedViewports = <braven.DataRange>[];

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
                  capturedViewports.add(newViewport);
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

      // Click track at 70% position (280px from left)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarRect = tester.getRect(scrollbarFinder);
      final clickPosition = Offset(scrollbarRect.left + 280, scrollbarRect.center.dy);

      await tester.tapAt(clickPosition);

      // Pump frames to allow animation to progress
      // Animation is 300ms, pump every 50ms to see intermediate states
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50)); // 300ms total
      await tester.pumpAndSettle(); // Finish any remaining animation

      // Verify animation occurred (multiple viewport updates)
      expect(capturedViewports.length, greaterThan(1), reason: 'Animation should produce multiple viewport updates');

      // Verify final viewport centered at 70% of data range
      // 70% of 100 = 70, with viewport size 20, centered viewport = 60-80
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, closeTo(60, 2), reason: 'Viewport should center at 70% (60-80)');
      expect(finalViewport.max, closeTo(80, 2));
      expect(finalViewport.span, 20, reason: 'Viewport size should remain unchanged');
    });

    testWidgets('Track click animation uses ease-out curve', (WidgetTester tester) async {
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

      // Click track at 50%
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarRect = tester.getRect(scrollbarFinder);
      final clickPosition = Offset(scrollbarRect.left + 200, scrollbarRect.center.dy);

      await tester.tapAt(clickPosition);

      // Sample animation at different time points
      await tester.pump(); // Start
      await tester.pump(const Duration(milliseconds: 100));
      final viewportAt100ms = capturedViewports.last.min;

      await tester.pump(const Duration(milliseconds: 100)); // 200ms total
      final viewportAt200ms = capturedViewports.last.min;

      await tester.pump(const Duration(milliseconds: 100)); // 300ms total
      await tester.pumpAndSettle();
      final finalViewportMin = capturedViewports.last.min;

      // With ease-out curve, most movement happens early
      // Check that progress in first 100ms > progress in last 100ms
      final progressEarly = viewportAt100ms - 0; // Change from 0 to 100ms
      final progressLate = finalViewportMin - viewportAt200ms; // Change from 200ms to 300ms

      expect(progressEarly, greaterThan(progressLate), reason: 'Ease-out curve should move faster initially, slower at end');
    });

    testWidgets('Click track near boundary clamps viewport', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);

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

      // Click track at 95% (near right edge)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarRect = tester.getRect(scrollbarFinder);
      final clickPosition = Offset(scrollbarRect.left + 380, scrollbarRect.center.dy); // 95% of 400px

      await tester.tapAt(clickPosition);
      await tester.pumpAndSettle();

      // Verify viewport clamped at maximum
      expect(capturedViewport, isNotNull);
      expect(capturedViewport!.max, 100, reason: 'Viewport should clamp to dataRange.max');
      expect(capturedViewport!.min, 80, reason: 'Viewport min = max - size');
    });

    testWidgets('Vertical scrollbar track click animates correctly', (WidgetTester tester) async {
      // Setup
      const dataRange = braven.DataRange(min: 0, max: 100);
      braven.DataRange viewportRange = const braven.DataRange(min: 0, max: 20);

      final capturedViewports = <braven.DataRange>[];

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
                  capturedViewports.add(newViewport);
                  viewportRange = newViewport;
                },
                theme: ScrollbarConfig.defaultLight,
              ),
            ),
          ),
        ),
      );

      // Click track at 50% vertically
      final scrollbarFinder = find.byType(ChartScrollbar);
      final scrollbarRect = tester.getRect(scrollbarFinder);
      final clickPosition = Offset(scrollbarRect.center.dx, scrollbarRect.top + 200);

      await tester.tapAt(clickPosition);
      await tester.pumpAndSettle();

      // Verify viewport animated to center
      expect(capturedViewports.length, greaterThan(1));
      final finalViewport = capturedViewports.last;
      expect(finalViewport.min, closeTo(40, 2)); // Centered at 50%
      expect(finalViewport.max, closeTo(60, 2));
    });
  });
}
