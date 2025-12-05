// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for TooltipAnimator module

import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_animator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TooltipAnimator', () {
    late TooltipAnimator animator;
    late int repaintCount;

    setUp(() {
      repaintCount = 0;
      animator = TooltipAnimator(
        onRepaint: () => repaintCount++,
      );
    });

    tearDown(() {
      animator.dispose();
    });

    group('Initial State', () {
      test('opacity starts at 0', () {
        expect(animator.opacity, equals(0.0));
      });

      test('isVisible is false initially', () {
        expect(animator.isVisible, isFalse);
      });

      test('targetMarker is null initially', () {
        expect(animator.getTargetMarker<Object>(), isNull);
      });
    });

    group('Show Animation', () {
      test('show with zero delay triggers immediate animation', () async {
        const config = TooltipConfig(showDelay: Duration.zero);

        animator.show('marker1', config);

        // Should start animation immediately
        expect(animator.getTargetMarker<String>(), equals('marker1'));

        // Wait for animation to complete
        await Future.delayed(const Duration(milliseconds: 200));

        expect(animator.opacity, equals(1.0));
        expect(animator.isVisible, isTrue);
        expect(repaintCount, greaterThan(0));
      });

      test('show with delay waits before animating', () async {
        const config = TooltipConfig(showDelay: Duration(milliseconds: 50));

        animator.show('marker1', config);

        // Should not have started animation yet
        expect(animator.opacity, equals(0.0));

        // Wait for delay + animation
        await Future.delayed(const Duration(milliseconds: 250));

        expect(animator.opacity, equals(1.0));
        expect(animator.isVisible, isTrue);
      });

      test('show cancels previous show timer', () async {
        const config = TooltipConfig(showDelay: Duration(milliseconds: 100));

        animator.show('marker1', config);

        // Cancel first show by starting second
        await Future.delayed(const Duration(milliseconds: 20));
        animator.show('marker2', config);

        // Wait for first timer to expire (should be cancelled)
        await Future.delayed(const Duration(milliseconds: 100));

        // Should be targeting marker2, not marker1
        expect(animator.getTargetMarker<String>(), equals('marker2'));
      });

      test('show sets targetMarker', () {
        const config = TooltipConfig(showDelay: Duration.zero);

        animator.show('myMarker', config);

        expect(animator.getTargetMarker<String>(), equals('myMarker'));
      });
    });

    group('Hide Animation', () {
      test('hide with zero delay triggers immediate animation', () async {
        // First show the tooltip
        const showConfig = TooltipConfig(showDelay: Duration.zero);
        animator.show('marker1', showConfig);
        await Future.delayed(const Duration(milliseconds: 200));

        expect(animator.opacity, equals(1.0));

        // Now hide it
        const hideConfig = TooltipConfig(hideDelay: Duration.zero);
        animator.hide(hideConfig);

        // Wait for fade out animation
        await Future.delayed(const Duration(milliseconds: 150));

        expect(animator.opacity, equals(0.0));
        expect(animator.isVisible, isFalse);
        // Note: targetMarker preserved during fade-out for drawing
      });

      test('hide with delay waits before animating', () async {
        // First show the tooltip
        const showConfig = TooltipConfig(showDelay: Duration.zero);
        animator.show('marker1', showConfig);
        await Future.delayed(const Duration(milliseconds: 200));

        // Now hide with delay
        const hideConfig = TooltipConfig(hideDelay: Duration(milliseconds: 50));
        animator.hide(hideConfig);

        // Should still be visible
        expect(animator.opacity, equals(1.0));

        // Wait for delay + animation
        await Future.delayed(const Duration(milliseconds: 200));

        expect(animator.opacity, equals(0.0));
      });

      test('hide preserves targetMarker for fade-out drawing', () async {
        const config = TooltipConfig(showDelay: Duration.zero);
        animator.show('marker1', config);

        animator.hide(config);

        // Target should be preserved for drawing during fade-out
        expect(animator.getTargetMarker<String>(), equals('marker1'));
      });
    });

    group('Hide Immediately', () {
      test('hideImmediately sets opacity to 0 without animation', () async {
        // First show the tooltip
        const config = TooltipConfig(showDelay: Duration.zero);
        animator.show('marker1', config);
        await Future.delayed(const Duration(milliseconds: 200));

        expect(animator.opacity, equals(1.0));

        // Hide immediately
        animator.hideImmediately();

        expect(animator.opacity, equals(0.0));
        expect(animator.isVisible, isFalse);
        expect(animator.getTargetMarker<Object>(), isNull);
      });

      test('hideImmediately triggers repaint', () async {
        const config = TooltipConfig(showDelay: Duration.zero);
        animator.show('marker1', config);
        await Future.delayed(const Duration(milliseconds: 200));

        final countBefore = repaintCount;
        animator.hideImmediately();

        expect(repaintCount, greaterThan(countBefore));
      });
    });

    group('Cancel All', () {
      test('cancelAll stops all timers', () async {
        const config = TooltipConfig(showDelay: Duration(milliseconds: 100));
        animator.show('marker1', config);

        animator.cancelAll();

        // Wait for original timer to have fired (if not cancelled)
        await Future.delayed(const Duration(milliseconds: 150));

        // Opacity should still be 0 because timer was cancelled
        expect(animator.opacity, equals(0.0));
        expect(animator.getTargetMarker<Object>(), isNull);
      });
    });

    group('Disposal', () {
      test('dispose cancels all timers', () async {
        const config = TooltipConfig(showDelay: Duration(milliseconds: 100));
        animator.show('marker1', config);

        animator.dispose();

        // Wait for original timer to have fired (if not cancelled)
        await Future.delayed(const Duration(milliseconds: 150));

        // No crash means timers were properly cancelled
        expect(animator.opacity, equals(0.0));
      });
    });
  });
}
