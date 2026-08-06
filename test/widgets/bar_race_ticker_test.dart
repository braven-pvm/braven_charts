import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('advances playback with the frame clock and respects pause', (
    tester,
  ) async {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: 'one', label: 'One', values: {'a': 1}),
          BarRaceFrame(id: 'two', label: 'Two', values: {'a': 2}),
          BarRaceFrame(id: 'three', label: 'Three', values: {'a': 3}),
        ],
        durationPerFrame: Duration(milliseconds: 100),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BarRaceTicker(
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

  testWidgets('pauses playback when the app leaves the foreground', (
    tester,
  ) async {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: 'one', label: 'One', values: {'a': 1}),
          BarRaceFrame(id: 'two', label: 'Two', values: {'a': 2}),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BarRaceTicker(
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

  testWidgets(
    'honors ambient reduced motion while preserving the frame cadence',
    (tester) async {
      final controller = BarRaceController(
        config: const BarRaceConfig(
          categories: [
            BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
          ],
          frames: [
            BarRaceFrame(id: 'one', label: 'One', values: {'a': 100}),
            BarRaceFrame(id: 'two', label: 'Two', values: {'a': 200}),
          ],
          durationPerFrame: Duration(milliseconds: 100),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: BarRaceTicker(
              controller: controller,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      controller.play();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.currentFrame.id, 'one');
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.currentFrame.id, 'two');
      expect(controller.effectiveAxisMaximum, 200);
    },
  );

  testWidgets('uses linear full-frame progress for dynamic axis motion', (
    tester,
  ) async {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: 'one', label: 'One', values: {'a': 750}),
          BarRaceFrame(id: 'two', label: 'Two', values: {'a': 850}),
          BarRaceFrame(id: 'three', label: 'Three', values: {'a': 900}),
        ],
        durationPerFrame: Duration(milliseconds: 100),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BarRaceTicker(
          controller: controller,
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(controller.currentFrame.id, 'two');
    await tester.pump(const Duration(milliseconds: 25));

    expect(controller.effectiveAxisMaximum, closeTo(850, 0.001));
  });
}
