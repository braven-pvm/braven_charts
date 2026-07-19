import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/controllers/chart_interaction_group_controller.dart'
    show ChartInteractionGroupParticipant;
import 'package:flutter_test/flutter_test.dart';

const _frameBudget = Duration(microseconds: 16667);

void main() {
  test('12-chart synchronized cursor fanout stays within one frame', () {
    final group = ChartInteractionGroupController();
    addTearDown(group.dispose);
    var callbackCount = 0;
    final participants = <ChartInteractionGroupParticipant>[
      for (var index = 0; index < 12; index++)
        group.attachChart(
          attachment: Object(),
          onCursorChanged: (_) => callbackCount++,
          onViewportChanged: (_) {},
        ),
    ];
    addTearDown(() {
      for (final participant in participants) {
        participant.dispose();
      }
    });

    // Warm the JIT and controller snapshot path before measuring.
    for (var index = 0; index < 200; index++) {
      participants.first.publishCursor(index.toDouble());
    }
    callbackCount = 0;

    final batches = <Duration>[];
    for (var batch = 0; batch < 20; batch++) {
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < 1000; index++) {
        participants.first.publishCursor((batch * 1000 + index).toDouble());
      }
      stopwatch.stop();
      batches.add(stopwatch.elapsed);
    }
    batches.sort();
    final p95 = batches[((batches.length - 1) * 0.95).ceil()];

    // One batch represents far more cursor publications than one UI frame.
    // Keeping its p95 within one 60 Hz budget provides a generous permanent
    // shield for normal 2-12 chart compositions.
    expect(p95, lessThan(_frameBudget));
    expect(callbackCount, 20 * 1000 * participants.length);
    // ignore: avoid_print
    print(
      'Synchronized cursor fanout (12 charts, 1000 moves): '
      'p95 ${(p95.inMicroseconds / 1000).toStringAsFixed(2)}ms',
    );
  });
}
