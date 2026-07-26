import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _trialCount = 5;
const _frameCount = 1000;
const _warmupFrameCount = 200;

enum _Scenario {
  singleAxisUnchanged,
  singleAxisChanging,
  multiAxisUnchanged,
  multiAxisChanging,
}

extension on _Scenario {
  bool get changing => switch (this) {
    _Scenario.singleAxisChanging || _Scenario.multiAxisChanging => true,
    _Scenario.singleAxisUnchanged || _Scenario.multiAxisUnchanged => false,
  };

  bool get multiAxis => switch (this) {
    _Scenario.multiAxisUnchanged || _Scenario.multiAxisChanging => true,
    _Scenario.singleAxisUnchanged || _Scenario.singleAxisChanging => false,
  };
}

typedef _TrialResult = ({int medianMicros, int p95Micros});

List<String> _labelsForFrame(_Scenario scenario, int frame) {
  final sample = scenario.changing ? frame + 42 : 42;
  final date = DateTime.utc(2026, 1, 1).add(Duration(days: sample));
  final dateLabel =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  if (!scenario.multiAxis) {
    return [dateLabel, '${sample.toStringAsFixed(0)} W'];
  }

  return [
    dateLabel,
    '${sample.toStringAsFixed(0)} W',
    '${(60 + sample).toStringAsFixed(0)} bpm',
    '${(sample / 10).toStringAsFixed(1)} °C',
    '${(sample / 100).toStringAsFixed(2)} m/s',
    '${(sample * 3).toStringAsFixed(0)} rpm',
    '${(sample / 1000).toStringAsFixed(3)} mmol/L',
  ];
}

void _layoutUncachedFrame({
  required _Scenario scenario,
  required int frame,
  required List<TextPainter> retainedPainters,
}) {
  for (final text in _labelsForFrame(scenario, frame)) {
    retainedPainters.add(
      TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF202124)),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        locale: const Locale('en', 'ZA'),
      )..layout(),
    );
  }
}

void _warmUncached(_Scenario scenario) {
  final retainedPainters = <TextPainter>[];
  try {
    for (var frame = 0; frame < _warmupFrameCount; frame++) {
      _layoutUncachedFrame(
        scenario: scenario,
        frame: frame,
        retainedPainters: retainedPainters,
      );
    }
  } finally {
    for (final painter in retainedPainters) {
      painter.dispose();
    }
  }
}

_TrialResult _measureUncachedTrial(_Scenario scenario) {
  final retainedPainters = <TextPainter>[];
  final frameMicros = <int>[];

  try {
    for (var frame = 0; frame < _frameCount; frame++) {
      final stopwatch = Stopwatch()..start();
      _layoutUncachedFrame(
        scenario: scenario,
        frame: frame,
        retainedPainters: retainedPainters,
      );
      stopwatch.stop();
      frameMicros.add(stopwatch.elapsedMicroseconds);
    }
  } finally {
    for (final painter in retainedPainters) {
      painter.dispose();
    }
  }

  frameMicros.sort();
  return (
    medianMicros: frameMicros[frameMicros.length ~/ 2],
    p95Micros: frameMicros[(frameMicros.length * 0.95).ceil() - 1],
  );
}

int _medianTrialP95(List<_TrialResult> trials) {
  final p95Micros = [for (final trial in trials) trial.p95Micros]..sort();
  return p95Micros[p95Micros.length ~/ 2];
}

String _formatTrials(List<_TrialResult> trials) {
  return [
    for (final (index, trial) in trials.indexed)
      'trial ${index + 1}: median=${trial.medianMicros}us, '
          'p95=${trial.p95Micros}us',
  ].join(' | ');
}

void main() {
  test('records uncached crosshair axis-label layout trials', () {
    for (final scenario in _Scenario.values) {
      _warmUncached(scenario);
      final trials = [
        for (var trial = 0; trial < _trialCount; trial++)
          _measureUncachedTrial(scenario),
      ];
      // ignore: avoid_print
      print(
        '${scenario.name} uncached trials: ${_formatTrials(trials)}; '
        'decision p95=${_medianTrialP95(trials) / 1000}ms',
      );
      expect(trials, hasLength(_trialCount));
      expect(
        trials.every((trial) => trial.p95Micros >= trial.medianMicros),
        isTrue,
      );
    }
  });
}
