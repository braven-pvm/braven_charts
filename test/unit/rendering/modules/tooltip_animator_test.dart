import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_animator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a cold first show schedules a frame for timer-driven repaint', (
    tester,
  ) async {
    var repaintCount = 0;
    final scheduledCallbacks = <void Function()>[];
    final animator = TooltipAnimator(
      onRepaint: () => repaintCount++,
      scheduleRepaintFrame: scheduledCallbacks.add,
    );

    animator.show(Object(), const TooltipConfig(showDelay: Duration.zero));

    await tester.pump(const Duration(milliseconds: 16));

    expect(animator.opacity, greaterThan(0));
    expect(
      scheduledCallbacks,
      hasLength(1),
      reason:
          'The first timer tick must drive its own Flutter frame. Merely adding '
          'a post-frame callback leaves a cold chart partially painted until '
          'another pointer event or rebuild happens.',
    );
    scheduledCallbacks.single();
    expect(repaintCount, greaterThan(0));
    animator.dispose();
  });

  testWidgets(
    'the first tooltip reaches full opacity without a second show call',
    (tester) async {
      final scheduledCallbacks = <void Function()>[];
      final marker = Object();
      final animator = TooltipAnimator(
        onRepaint: () {},
        scheduleRepaintFrame: scheduledCallbacks.add,
      );

      animator.show(marker, const TooltipConfig(showDelay: Duration.zero));

      for (var step = 0; step < 10 && animator.opacity < 1; step++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          scheduledCallbacks,
          isNotEmpty,
          reason: 'Every opacity step must request its own rendered frame.',
        );
        scheduledCallbacks.removeAt(0)();
      }

      expect(animator.opacity, 1);
      expect(animator.scale, 1);
      expect(animator.getTargetMarker<Object>(), same(marker));
      animator.dispose();
    },
  );

  testWidgets('replacing a partially visible target completes the new popup', (
    tester,
  ) async {
    final scheduledCallbacks = <void Function()>[];
    final firstMarker = Object();
    final secondMarker = Object();
    final animator = TooltipAnimator(
      onRepaint: () {},
      scheduleRepaintFrame: scheduledCallbacks.add,
    );

    animator.show(firstMarker, const TooltipConfig(showDelay: Duration.zero));
    await tester.pump(const Duration(milliseconds: 48));
    expect(animator.opacity, inExclusiveRange(0.5, 1));
    scheduledCallbacks.removeAt(0)();

    animator.show(secondMarker, const TooltipConfig(showDelay: Duration.zero));
    for (var step = 0; step < 10; step++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (scheduledCallbacks.isNotEmpty) {
        scheduledCallbacks.removeAt(0)();
      }
    }

    expect(animator.opacity, 1);
    expect(animator.getTargetMarker<Object>(), same(secondMarker));
    animator.dispose();
  });

  testWidgets('default motion flicks in with a restrained overshoot', (
    tester,
  ) async {
    final scheduledCallbacks = <void Function()>[];
    final animator = TooltipAnimator(
      onRepaint: () {},
      scheduleRepaintFrame: scheduledCallbacks.add,
    );

    animator.show(Object(), const TooltipConfig(showDelay: Duration.zero));
    expect(animator.scale, closeTo(0.88, 0.001));

    await tester.pump(const Duration(milliseconds: 64));
    expect(animator.opacity, greaterThan(0.8));
    expect(
      animator.scale,
      greaterThan(1),
      reason: 'The quick entrance should overshoot before settling.',
    );

    await tester.pump(const Duration(milliseconds: 64));
    expect(animator.opacity, 1);
    expect(animator.scale, 1);
    animator.dispose();
  });

  testWidgets('default motion snaps out faster than it enters', (tester) async {
    final animator = TooltipAnimator(
      onRepaint: () {},
      scheduleRepaintFrame: (_) {},
    );

    animator.show(
      Object(),
      const TooltipConfig(showDelay: Duration.zero),
      animate: false,
    );
    animator.hide(const TooltipConfig(hideDelay: Duration.zero));

    await tester.pump(const Duration(milliseconds: 32));
    expect(animator.opacity, lessThan(1));
    expect(animator.scale, lessThan(1));

    await tester.pump(const Duration(milliseconds: 64));
    expect(animator.opacity, 0);
    expect(animator.scale, closeTo(0.94, 0.001));
    expect(animator.getTargetMarker<Object>(), isNull);
    animator.dispose();
  });

  testWidgets('repeated paint-driven hides do not restart the exit clock', (
    tester,
  ) async {
    final animator = TooltipAnimator(
      onRepaint: () {},
      scheduleRepaintFrame: (_) {},
    );

    animator.show(
      Object(),
      const TooltipConfig(showDelay: Duration.zero),
      animate: false,
    );
    animator.hide(const TooltipConfig(hideDelay: Duration.zero));
    await tester.pump(const Duration(milliseconds: 32));
    animator.hide(const TooltipConfig(hideDelay: Duration.zero));
    await tester.pump(const Duration(milliseconds: 64));

    expect(animator.opacity, 0);
    expect(animator.getTargetMarker<Object>(), isNull);
    animator.dispose();
  });

  testWidgets('reduced motion resolves show and hide without transitions', (
    tester,
  ) async {
    final marker = Object();
    final animator = TooltipAnimator(
      onRepaint: () {},
      scheduleRepaintFrame: (_) {},
    );

    animator.show(
      marker,
      const TooltipConfig(showDelay: Duration.zero),
      animate: false,
    );
    expect(animator.opacity, 1);
    expect(animator.scale, 1);
    expect(animator.getTargetMarker<Object>(), same(marker));

    animator.hide(
      const TooltipConfig(hideDelay: Duration.zero),
      animate: false,
    );
    expect(animator.opacity, 0);
    expect(animator.scale, 1);
    expect(animator.getTargetMarker<Object>(), isNull);
    animator.dispose();
  });
}
