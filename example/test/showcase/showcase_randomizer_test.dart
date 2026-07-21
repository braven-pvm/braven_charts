import 'package:braven_charts_example/showcase/widgets/showcase_randomizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the same seed reproduces the same complete value', () {
    final applied = <_GeneratedValue>[];
    final controller = ShowcaseRandomizerController<_GeneratedValue>(
      initialSeed: 17,
      generate: (seed) => _GeneratedValue(seed, seed * 2),
      apply: applied.add,
    );
    addTearDown(controller.dispose);

    controller.generateCurrent();
    controller.generateCurrent();

    expect(applied, const <_GeneratedValue>[
      _GeneratedValue(17, 34),
      _GeneratedValue(17, 34),
    ]);
    expect(controller.appliedSeed, 17);
    expect(controller.currentValue, const _GeneratedValue(17, 34));
  });

  testWidgets('playback advances, pauses, and retains the current value', (
    tester,
  ) async {
    final applied = <int>[];
    final controller = ShowcaseRandomizerController<int>(
      initialSeed: 10,
      initialIntervalSeconds: 2,
      generate: (seed) => seed,
      apply: applied.add,
    );
    addTearDown(controller.dispose);

    controller.togglePlayback();
    expect(controller.isPlaying, isTrue);
    expect(applied, <int>[11]);

    await tester.pump(const Duration(seconds: 2));
    expect(applied, <int>[11, 12]);

    controller.pause();
    final pausedValue = controller.currentValue;
    await tester.pump(const Duration(seconds: 8));

    expect(controller.isPlaying, isFalse);
    expect(controller.currentValue, pausedValue);
    expect(applied, <int>[11, 12]);
  });

  testWidgets('shared editor reflects generated and playback state', (
    tester,
  ) async {
    final controller = ShowcaseRandomizerController<int>(
      initialSeed: 4,
      generate: (seed) => seed,
      apply: (_) {},
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 700,
            child: PropertyRandomizerSection(controller: controller),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('showcase-randomizer-generate')),
    );
    await tester.pump();
    expect(find.text('Inspecting seed 4'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('showcase-randomizer-playback-toggle')),
    );
    await tester.pump();
    expect(find.text('Pause random sequence'), findsOneWidget);
    expect(find.text('Playing seed 5'), findsOneWidget);
    controller.pause();
  });

  testWidgets('header actions keep playback visible and pausable', (
    tester,
  ) async {
    final applied = <int>[];
    final controller = ShowcaseRandomizerController<int>(
      initialSeed: 8,
      generate: (seed) => seed,
      apply: applied.add,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ShowcaseRandomizerActions(controller: controller)),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('showcase-randomizer-playback-header')),
    );
    await tester.pump();

    expect(applied, <int>[9]);
    expect(find.text('Pause sequence'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('showcase-randomizer-playback-header')),
    );
    await tester.pump();

    expect(controller.isPlaying, isFalse);
    expect(find.text('Play sequence'), findsOneWidget);
  });
}

class _GeneratedValue {
  const _GeneratedValue(this.seed, this.value);

  final int seed;
  final int value;

  @override
  bool operator ==(Object other) =>
      other is _GeneratedValue && other.seed == seed && other.value == value;

  @override
  int get hashCode => Object.hash(seed, value);
}
