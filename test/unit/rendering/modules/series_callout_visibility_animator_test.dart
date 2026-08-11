import 'package:braven_charts/src/rendering/modules/series_callout_visibility_animator.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesCalloutVisibilityAnimator', () {
    test('snaps the initial layout without an entrance flash', () {
      final animator = SeriesCalloutVisibilityAnimator(onRepaint: () {});
      addTearDown(animator.dispose);

      animator.update(
        allIds: {'leader', 'challenger'},
        visibleIds: {'leader'},
        duration: const Duration(milliseconds: 180),
        animate: true,
      );

      expect(animator.opacityFor('leader'), 1);
      expect(animator.opacityFor('challenger'), 0);
      expect(animator.isAnimating, isFalse);
    });

    test('fades collision changes in both directions', () {
      fakeAsync((async) {
        var repaintCount = 0;
        final animator = SeriesCalloutVisibilityAnimator(
          onRepaint: () => repaintCount++,
        );

        animator.update(
          allIds: {'leader', 'challenger'},
          visibleIds: {'leader'},
          duration: const Duration(milliseconds: 160),
          animate: true,
        );
        animator.update(
          allIds: {'leader', 'challenger'},
          visibleIds: {'challenger'},
          duration: const Duration(milliseconds: 160),
          animate: true,
        );

        expect(animator.opacityFor('leader'), 1);
        expect(animator.opacityFor('challenger'), 0);
        expect(animator.isAnimating, isTrue);

        async.elapse(const Duration(milliseconds: 80));
        expect(animator.opacityFor('leader'), inExclusiveRange(0, 1));
        expect(animator.opacityFor('challenger'), inExclusiveRange(0, 1));
        expect(repaintCount, greaterThan(0));

        async.elapse(const Duration(milliseconds: 96));
        expect(animator.opacityFor('leader'), 0);
        expect(animator.opacityFor('challenger'), 1);
        expect(animator.isAnimating, isFalse);
        animator.dispose();
      });
    });

    test('reduced motion snaps an active transition to its target', () {
      fakeAsync((async) {
        final animator = SeriesCalloutVisibilityAnimator(onRepaint: () {});
        animator.update(
          allIds: {'series'},
          visibleIds: {'series'},
          duration: const Duration(milliseconds: 180),
          animate: true,
        );
        animator.update(
          allIds: {'series'},
          visibleIds: const {},
          duration: const Duration(milliseconds: 180),
          animate: true,
        );
        async.elapse(const Duration(milliseconds: 32));
        expect(animator.opacityFor('series'), greaterThan(0));

        animator.update(
          allIds: {'series'},
          visibleIds: const {},
          duration: const Duration(milliseconds: 180),
          animate: false,
        );

        expect(animator.opacityFor('series'), 0);
        expect(animator.isAnimating, isFalse);
        animator.dispose();
      });
    });
  });
}
