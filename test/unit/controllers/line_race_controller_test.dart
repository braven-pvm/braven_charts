import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = LineRaceConfig(
    series: [
      LineRaceSeries(id: 'a', name: 'Alpha', color: Colors.blue),
      LineRaceSeries(id: 'b', name: 'Beta', color: Colors.red),
    ],
    frames: [
      LineRaceFrame(id: 'r1', label: 'Round 1', x: 1, values: {'a': 10}),
      LineRaceFrame(
        id: 'r2',
        label: 'Round 2',
        x: 2,
        values: {'a': 20, 'b': 5},
      ),
      LineRaceFrame(id: 'r3', label: 'Round 3', x: 3, values: {'a': 30}),
      LineRaceFrame(
        id: 'r4',
        label: 'Round 4',
        x: 4,
        values: {'a': 40, 'b': 10},
      ),
    ],
    durationPerFrame: Duration(milliseconds: 100),
  );

  test('interpolates one frontier on the deterministic race clock', () {
    final controller = LineRaceController(config: config)..play();

    controller.next();
    controller.updateTransitionProgress(0.5);

    final alpha = controller.snapshot.pointsFor('a');
    expect(alpha, hasLength(2));
    expect(alpha.last.x, 1.5);
    expect(alpha.last.y, 15);
    expect(controller.snapshot.frontierX, 1.5);
  });

  test('does not fabricate a frontier for a late entrant', () {
    final controller = LineRaceController(config: config)..play();

    controller.next();
    controller.updateTransitionProgress(0.75);

    expect(controller.snapshot.pointsFor('b'), isEmpty);
    controller.completeTransition();
    expect(controller.snapshot.pointsFor('b').single.y, 5);
  });

  test('preserves authored gaps instead of connecting across them', () {
    final controller = LineRaceController(config: config)..seekToFrame(3);

    final beta = controller.snapshot.pointsFor('b');
    expect(beta, hasLength(3));
    expect(beta[0].x, 2);
    expect(beta[1].x, 3);
    expect(beta[1].y.isNaN, isTrue);
    expect(beta[2].x, 4);
  });

  test('seek settles and pauses while retaining the full X domain', () {
    final controller = LineRaceController(config: config)..play();

    controller.seek(2 / 3);

    expect(controller.currentFrame.id, 'r3');
    expect(controller.isPlaying, isFalse);
    expect(controller.frameTransitionProgress, 1);
    expect(controller.xMinimum, 1);
    expect(controller.xMaximum, 4);
  });

  test('speed rescales cadence and playback stops at the final frame', () {
    final controller = LineRaceController(config: config)
      ..setSpeed(2)
      ..play();

    expect(controller.effectiveDuration, const Duration(milliseconds: 50));
    expect(controller.next(), isTrue);
    expect(controller.next(), isTrue);
    expect(controller.next(), isTrue);
    expect(controller.next(), isFalse);
    expect(controller.currentFrame.id, 'r4');
    expect(controller.isPlaying, isFalse);
  });

  test('loop returns to the first settled frame without a false bridge', () {
    final controller = LineRaceController(config: config.copyWith(loop: true))
      ..seekToFrame(2);

    controller.play();
    controller.next();
    controller.completeTransition();
    controller.next();

    expect(controller.frameIndex, 0);
    expect(controller.frameTransitionProgress, 1);
    expect(controller.snapshot.pointsFor('a').single.x, 1);
  });

  test('rejects unknown identities, non-finite values, and unordered X', () {
    expect(
      () => LineRaceController(
        config: config.copyWith(
          frames: const [
            LineRaceFrame(
              id: 'bad',
              label: 'Bad',
              x: 1,
              values: {'missing': 1},
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => LineRaceController(
        config: config.copyWith(
          frames: const [
            LineRaceFrame(
              id: 'bad',
              label: 'Bad',
              x: 1,
              values: {'a': double.infinity},
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => LineRaceController(
        config: config.copyWith(
          frames: const [
            LineRaceFrame(id: 'a', label: 'A', x: 2, values: {'a': 1}),
            LineRaceFrame(id: 'b', label: 'B', x: 1, values: {'a': 2}),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });
}
