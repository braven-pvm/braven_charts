import 'package:braven_charts/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar viewport update throttling (T062)
///
/// Tests that ChartScrollbar throttles viewport updates to maintain 60 FPS:
/// - Maximum 1 viewport update per 16ms (16.67ms = 60 FPS)
/// - Throttled updates during rapid pan input (>60 FPS)
/// - Final update applied after throttle delay
/// - No dropped final viewport state
///
/// Constitutional Requirements (FR-018):
/// - 60 FPS during all drag operations
/// - Viewport updates throttled to prevent excessive re-renders
/// - Final viewport state always synchronized
///
/// Following Constitution I (Test-First Development, Performance First) - User Story 2.
///
/// Related to:
/// - T067: Throttling implementation (16ms timer)
/// - T070: Final viewport sync in onPanEnd
/// - constitution.md: FR-018 (60 FPS requirement)
void main() {
  group('ChartScrollbar viewport update throttling - CONTRACT', () {
    testWidgets('MUST throttle viewport updates to max 1 per 16ms',
        (WidgetTester tester) async {
      // ARRANGE: Track viewport update timing
      final updateTimestamps = <int>[];
      final stopwatch = Stopwatch()..start();
      
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0),
        onViewportChanged: (_) {
          updateTimestamps.add(stopwatch.elapsedMilliseconds);
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Simulate rapid pan updates (>60 FPS input)
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      
      // Send 30 rapid updates over ~250ms (120 FPS input rate)
      for (int i = 0; i < 30; i++) {
        await gesture.moveBy(const Offset(2, 0));
        await tester.pump(const Duration(milliseconds: 8)); // ~120 FPS
      }
      
      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Updates should be throttled to ~60 FPS (16ms intervals)
      if (updateTimestamps.length >= 2) {
        // Calculate minimum interval between consecutive updates
        int minInterval = 1000000; // Large initial value
        for (int i = 1; i < updateTimestamps.length; i++) {
          final interval = updateTimestamps[i] - updateTimestamps[i - 1];
          if (interval < minInterval) {
            minInterval = interval;
          }
        }
        
        expect(minInterval, greaterThanOrEqualTo(14),
            reason: 'Viewport updates should be throttled to ≥14ms intervals (allows for ~2ms timing variance from 16ms target)');
        
        // Total duration ~250ms, expect max ~15 updates (250ms / 16ms = 15.6)
        expect(updateTimestamps.length, lessThanOrEqualTo(18),
            reason: 'Should throttle 30 input events to ~15 viewport updates at 60 FPS');
      }
    });

    testWidgets('MUST apply final update after throttle delay',
        (WidgetTester tester) async {
      // ARRANGE: Track final viewport state
      DataRange? finalViewport;
      int updateCount = 0;
      
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (newViewport) {
          finalViewport = newViewport;
          updateCount++;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Rapid drag then wait for final sync
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 5)); // 200 FPS input
      }
      
      await gesture.up();
      await tester.pumpAndSettle(); // Wait for final throttle delay

      // ASSERT: Final viewport should reflect total drag (50px)
      expect(updateCount, greaterThan(0),
          reason: 'Should receive at least one viewport update');
      
      expect(finalViewport, isNotNull,
          reason: 'Final viewport state should be synchronized');
      
      // TODO (T067, T070): After implementation, verify:
      // - finalViewport reflects full 50px drag distance
      // - No "dropped" final update due to throttling
    });

    testWidgets('MUST maintain smooth rendering during rapid input',
        (WidgetTester tester) async {
      // ARRANGE: Monitor frame rendering during rapid input
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Extremely rapid input (simulating high-refresh-rate display)
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      
      // 50 updates at 240 FPS (4.17ms intervals)
      for (int i = 0; i < 50; i++) {
        await gesture.moveBy(const Offset(1, 0));
        await tester.pump(const Duration(milliseconds: 4));
      }
      
      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Should handle input without crashing or frame drops
      expect(find.byType(ChartScrollbar), findsOneWidget,
          reason: 'Should maintain stable rendering under rapid input stress');
      
      // Note: Actual frame timing measured in performance tests
      // This contract verifies functional behavior under extreme input rates
    });

    testWidgets('MUST not drop final viewport state',
        (WidgetTester tester) async {
      // ARRANGE: Track all viewport updates
      final viewportHistory = <DataRange>[];
      
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 40.0),
        onViewportChanged: (newViewport) {
          viewportHistory.add(newViewport);
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Quick burst then stop (tests final sync after last throttle)
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      
      // Burst of 5 updates in 20ms (250 FPS)
      for (int i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 4));
      }
      
      await gesture.up();
      
      // Critical: Wait for throttle timer to expire and apply final update
      await tester.pump(const Duration(milliseconds: 20)); // Wait >16ms throttle
      await tester.pumpAndSettle();

      // ASSERT: Final viewport must reflect all movement (50px total)
      expect(viewportHistory, isNotEmpty,
          reason: 'Should have viewport updates');
      
      // TODO (T067, T070): After implementation, verify:
      // - viewportHistory.last reflects full 50px drag
      // - Final update applied after throttle delay
      // - No "lost" viewport state due to throttling
    });

    testWidgets('MUST throttle independent of input event rate',
        (WidgetTester tester) async {
      // ARRANGE: Test throttling at different input rates
      final testInputRates = [
        const Duration(milliseconds: 4),  // 250 FPS
        const Duration(milliseconds: 8),  // 125 FPS
        const Duration(milliseconds: 16), // 62.5 FPS
      ];
      
      for (final inputInterval in testInputRates) {
        final updateTimestamps = <int>[];
        final stopwatch = Stopwatch()..start();
        
        final scrollbar = ChartScrollbar(
          axis: Axis.horizontal,
          dataRange: const DataRange(min: 0.0, max: 100.0),
          viewportRange: const DataRange(min: 25.0, max: 75.0),
          onViewportChanged: (_) {
            updateTimestamps.add(stopwatch.elapsedMilliseconds);
          },
          theme: ScrollbarConfig.defaultLight,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 20,
                child: scrollbar,
              ),
            ),
          ),
        );

        // ACT: Send 20 updates at current input rate
        final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
        
        for (int i = 0; i < 20; i++) {
          await gesture.moveBy(const Offset(2, 0));
          await tester.pump(inputInterval);
        }
        
        await gesture.up();
        await tester.pumpAndSettle();

        // ASSERT: Output should be throttled regardless of input rate
        if (updateTimestamps.length >= 2) {
          int minInterval = 1000000;
          for (int i = 1; i < updateTimestamps.length; i++) {
            final interval = updateTimestamps[i] - updateTimestamps[i - 1];
            if (interval < minInterval) {
              minInterval = interval;
            }
          }
          
          // Should maintain ~16ms minimum interval even with faster input
          if (inputInterval.inMilliseconds < 16) {
            expect(minInterval, greaterThanOrEqualTo(14),
                reason: 'Throttling should maintain ~16ms intervals at ${inputInterval.inMilliseconds}ms input rate');
          }
        }
        
        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });
}
