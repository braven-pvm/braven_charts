import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LineRaceController createController() => LineRaceController(
    config: const LineRaceConfig(
      series: [LineRaceSeries(id: 'a', name: 'Alpha', color: Colors.blue)],
      frames: [
        LineRaceFrame(id: 'one', label: 'One', x: 1, values: {'a': 1}),
        LineRaceFrame(id: 'two', label: 'Two', x: 2, values: {'a': 2}),
        LineRaceFrame(id: 'three', label: 'Three', x: 3, values: {'a': 3}),
      ],
      durationPerFrame: Duration(milliseconds: 100),
    ),
  );

  testWidgets('advances with the frame clock and respects pause', (
    tester,
  ) async {
    final controller = createController();
    await tester.pumpWidget(
      MaterialApp(
        home: LineRaceTicker(
          controller: controller,
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(controller.currentFrame.id, 'two');
    controller.pause();
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.currentFrame.id, 'two');
  });

  testWidgets('updates the interpolated frontier on the same clock', (
    tester,
  ) async {
    final controller = createController();
    await tester.pumpWidget(
      MaterialApp(
        home: LineRaceTicker(
          controller: controller,
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.currentFrame.id, 'two');
    expect(controller.snapshot.pointsFor('a').last.x, closeTo(1.5, 0.05));
    expect(controller.snapshot.pointsFor('a').last.y, closeTo(1.5, 0.05));
  });

  testWidgets('reduced motion preserves cadence but settles each frontier', (
    tester,
  ) async {
    final controller = createController();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: LineRaceTicker(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    controller.play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));

    expect(controller.currentFrame.id, 'two');
    expect(controller.frameTransitionProgress, 1);
    expect(controller.snapshot.pointsFor('a').last.x, 2);
  });

  testWidgets('pauses when the app leaves the foreground', (tester) async {
    final controller = createController();
    await tester.pumpWidget(
      MaterialApp(
        home: LineRaceTicker(
          controller: controller,
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.play();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(controller.isPlaying, isFalse);
  });
}
