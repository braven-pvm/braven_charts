import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = BarRaceConfig(
    categories: [
      BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
      BarRaceCategory(id: 'b', label: 'Beta', color: Colors.red),
      BarRaceCategory(id: 'c', label: 'Gamma', color: Colors.green),
    ],
    frames: [
      BarRaceFrame(id: '2020', label: '2020', values: {'a': 10, 'b': 8}),
      BarRaceFrame(
        id: '2021',
        label: '2021',
        values: {'a': 9, 'b': 14, 'c': 7},
      ),
      BarRaceFrame(
        id: '2022',
        label: '2022',
        values: {'a': 15, 'b': 13, 'c': 18},
      ),
    ],
    topCount: 2,
    durationPerFrame: Duration(milliseconds: 100),
  );

  test('ranks stable category identities and seeks deterministically', () {
    final controller = BarRaceController(config: config);
    expect(controller.rankedValues.map((value) => value.category.id), [
      'a',
      'b',
    ]);
    controller.seek(0.5);
    expect(controller.currentFrame.id, '2021');
    expect(controller.rankedValues.map((value) => value.category.id), [
      'b',
      'a',
    ]);
    expect(controller.effectiveAxisMaximum, 15);
  });

  test('playback stops at the last frame when looping is disabled', () {
    final controller = BarRaceController(config: config)..play();
    expect(controller.next(), isTrue);
    expect(controller.next(), isTrue);
    expect(controller.next(), isFalse);
    expect(controller.currentFrame.id, '2022');
    expect(controller.isPlaying, isFalse);
  });

  test('replay resets the continuous domain with the first frame', () {
    final controller = BarRaceController(
      config: config.copyWith(axisRange: BarRaceAxisRange.continuous),
    )..seekToFrame(2);

    final finalMaximum = controller.effectiveAxisMaximum;
    controller.play();

    expect(controller.frameIndex, 0);
    expect(controller.effectiveAxisMaximum, lessThan(finalMaximum));
  });

  test('fixed axis range uses every frame', () {
    final controller = BarRaceController(
      config: BarRaceConfig(
        categories: config.categories,
        frames: config.frames,
        topCount: 2,
        axisRange: BarRaceAxisRange.fixed,
      ),
    );
    expect(controller.effectiveAxisMaximum, 20);
  });

  test('dynamic axis advances through monotonic human-readable ceilings', () {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: '0', label: '0', values: {'a': 667}),
          BarRaceFrame(id: '1', label: '1', values: {'a': 710}),
          BarRaceFrame(id: '2', label: '2', values: {'a': 805}),
          BarRaceFrame(id: '3', label: '3', values: {'a': 790}),
          BarRaceFrame(id: '4', label: '4', values: {'a': 1010}),
        ],
      ),
    );

    expect(controller.effectiveAxisMaximum, 800);
    controller.seekToFrame(1);
    expect(controller.effectiveAxisMaximum, 800);
    controller.seekToFrame(2);
    expect(controller.effectiveAxisMaximum, 1000);
    controller.seekToFrame(3);
    expect(controller.effectiveAxisMaximum, 1000);
    controller.seekToFrame(4);
    expect(controller.effectiveAxisMaximum, 1200);
  });

  test('playing interpolates a stepped axis instead of snapping it', () {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: '0', label: '0', values: {'a': 667}),
          BarRaceFrame(id: '1', label: '1', values: {'a': 805}),
        ],
      ),
    )..play();

    expect(controller.effectiveAxisMaximum, 800);
    controller.next();
    expect(controller.effectiveAxisMaximum, 800);
    controller.updateAxisTransitionProgress(0.5);
    expect(controller.effectiveAxisMaximum, 900);
    controller.completeAxisTransition();
    expect(controller.effectiveAxisMaximum, 1000);
  });

  test('interpolates values and fractional ranks on the race clock', () {
    final controller = BarRaceController(config: config)..play();

    controller.next();
    controller.updateAxisTransitionProgress(0.5);

    final effective = {
      for (final value in controller.effectiveRankedValues)
        value.category.id: value,
    };
    expect(effective['a']!.value, 9.5);
    expect(effective['b']!.value, 11);
    expect(effective['a']!.rank, 0.5);
    expect(effective['b']!.rank, 0.5);

    controller.completeAxisTransition();
    expect(controller.effectiveRankedValues.map((value) => value.category.id), [
      'b',
      'a',
    ]);
    expect(controller.effectiveRankedValues.map((value) => value.rank), [0, 1]);
  });

  test('continuous axis follows the leader after its headroom is consumed', () {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: '0', label: '0', values: {'a': 667}),
          BarRaceFrame(id: '1', label: '1', values: {'a': 710}),
          BarRaceFrame(id: '2', label: '2', values: {'a': 805}),
          BarRaceFrame(id: '3', label: '3', values: {'a': 790}),
          BarRaceFrame(id: '4', label: '4', values: {'a': 1010}),
        ],
        axisRange: BarRaceAxisRange.continuous,
      ),
    );

    expect(controller.effectiveAxisMaximum, 800);
    controller.seekToFrame(1);
    expect(controller.effectiveAxisMaximum, 800);
    controller.seekToFrame(2);
    expect(controller.effectiveAxisMaximum, closeTo(805 / 0.9, 1e-9));
    controller.seekToFrame(3);
    expect(controller.effectiveAxisMaximum, closeTo(805 / 0.9, 1e-9));
    controller.seekToFrame(4);
    expect(controller.effectiveAxisMaximum, closeTo(1010 / 0.9, 1e-9));
  });

  test('prominent totals count on the same continuous frame clock', () {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(
            id: 'jan',
            label: 'January',
            values: {'a': 10},
            total: 100,
          ),
          BarRaceFrame(
            id: 'feb',
            label: 'February',
            values: {'a': 20},
            total: 200,
          ),
        ],
        axisRange: BarRaceAxisRange.fixed,
      ),
    )..play();

    controller.next();
    expect(controller.effectiveTotal, 100);
    controller.updateAxisTransitionProgress(0.35);
    expect(controller.effectiveTotal, 135);
    controller.completeAxisTransition();
    expect(controller.effectiveTotal, 200);
  });

  test('reuses ranked frame projections until configuration changes', () {
    final controller = BarRaceController(config: config);
    final first = controller.rankedValues;
    expect(identical(controller.rankedValues, first), isTrue);

    controller.seekToFrame(1);
    final second = controller.rankedValues;
    expect(identical(second, first), isFalse);
    controller.seekToFrame(0);
    expect(identical(controller.rankedValues, first), isTrue);

    controller.replaceConfig(config.copyWith(topCount: 1));
    expect(identical(controller.rankedValues, first), isFalse);
    expect(controller.rankedValues, hasLength(1));
  });

  test('rejects unknown category identities', () {
    expect(
      () => BarRaceController(
        config: BarRaceConfig(
          categories: config.categories,
          frames: const [
            BarRaceFrame(id: 'bad', label: 'Bad', values: {'missing': 1}),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects non-portable value patterns at the runtime boundary', () {
    expect(
      () => BarRaceController(
        config: config.copyWith(
          valueFormat: const BarRaceValueFormat(pattern: 'missing token'),
        ),
      ),
      throwsArgumentError,
    );
  });
}
