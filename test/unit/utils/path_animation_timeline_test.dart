import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/path_animation_timeline.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PathAnimationTimeline', () {
    test('resolves simultaneous inherited timing to the theme duration', () {
      final windows = PathAnimationTimeline.resolve(
        timings: const {
          'observed': PathAnimationTiming(),
          'plan': PathAnimationTiming(),
        },
        themeDuration: const Duration(milliseconds: 400),
      );

      expect(
        windows.values,
        everyElement(
          const PathAnimationWindow(
            start: Duration.zero,
            duration: Duration(milliseconds: 400),
          ),
        ),
      );
      expect(
        PathAnimationTimeline.totalDuration(windows.values),
        const Duration(milliseconds: 400),
      );
    });

    test('resolves explicit delays and mixed durations on one timeline', () {
      final windows = PathAnimationTimeline.resolve(
        timings: const {
          'observed': PathAnimationTiming(
            duration: Duration(milliseconds: 300),
          ),
          'plan': PathAnimationTiming(
            delay: Duration(milliseconds: 100),
            duration: Duration(milliseconds: 500),
          ),
        },
        themeDuration: const Duration(milliseconds: 400),
      );

      expect(
        windows['observed'],
        const PathAnimationWindow(
          start: Duration.zero,
          duration: Duration(milliseconds: 300),
        ),
      );
      expect(
        windows['plan'],
        const PathAnimationWindow(
          start: Duration(milliseconds: 100),
          duration: Duration(milliseconds: 500),
        ),
      );
      expect(
        PathAnimationTimeline.totalDuration(windows.values),
        const Duration(milliseconds: 600),
      );
    });

    test(
      'returns curved local progress before, within, and after a window',
      () {
        const window = PathAnimationWindow(
          start: Duration(milliseconds: 100),
          duration: Duration(milliseconds: 400),
        );
        const timeline = Duration(milliseconds: 600);

        expect(
          PathAnimationTimeline.progress(
            controllerValue: 0.1,
            timelineDuration: timeline,
            window: window,
            curve: Curves.linear,
          ),
          0,
        );
        expect(
          PathAnimationTimeline.progress(
            controllerValue: 0.5,
            timelineDuration: timeline,
            window: window,
            curve: Curves.easeIn,
          ),
          closeTo(Curves.easeIn.transform(0.5), 0.0001),
        );
        expect(
          PathAnimationTimeline.progress(
            controllerValue: 1,
            timelineDuration: timeline,
            window: window,
            curve: Curves.linear,
          ),
          1,
        );
      },
    );

    test('zero theme or series duration is immediate and ignores delay', () {
      final zeroTheme = PathAnimationTimeline.resolve(
        timings: const {
          'line': PathAnimationTiming(
            delay: Duration(seconds: 1),
            duration: Duration(milliseconds: 400),
          ),
        },
        themeDuration: Duration.zero,
      );
      final zeroSeries = PathAnimationTimeline.resolve(
        timings: const {
          'area': PathAnimationTiming(
            delay: Duration(seconds: 1),
            duration: Duration.zero,
          ),
        },
        themeDuration: const Duration(milliseconds: 400),
      );

      expect(zeroTheme['line']!.isImmediate, isTrue);
      expect(zeroTheme['line']!.start, Duration.zero);
      expect(zeroSeries['area']!.isImmediate, isTrue);
      expect(
        PathAnimationTimeline.totalDuration([
          ...zeroTheme.values,
          ...zeroSeries.values,
        ]),
        Duration.zero,
      );
    });

    test('rejects negative delay and duration before orchestration', () {
      expect(
        () => PathAnimationTimeline.resolve(
          timings: const {
            'line': PathAnimationTiming(delay: Duration(microseconds: -1)),
          },
          themeDuration: const Duration(milliseconds: 400),
        ),
        throwsArgumentError,
      );
      expect(
        () => PathAnimationTimeline.resolve(
          timings: const {
            'area': PathAnimationTiming(duration: Duration(microseconds: -1)),
          },
          themeDuration: const Duration(milliseconds: 400),
        ),
        throwsArgumentError,
      );
    });
  });
}
