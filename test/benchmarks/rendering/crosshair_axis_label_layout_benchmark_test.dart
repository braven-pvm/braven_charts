import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _trialCount = 5;
const _frameCount = 1000;
const _warmupFrameCount = 200;
const _labelStyle = TextStyle(fontSize: 11, color: Color(0xFF202124));

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
typedef _PairedTrials = ({
  List<_TrialResult> uncached,
  List<_TrialResult> cached,
});
typedef _EnvironmentCase = ({
  TextDirection direction,
  Locale? locale,
  TextScaler textScaler,
  double devicePixelRatio,
});

final class _LayoutRequest {
  const _LayoutRequest({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.textScaler,
    required this.devicePixelRatio,
  });

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final TextScaler textScaler;
  final double devicePixelRatio;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _LayoutRequest &&
            text == other.text &&
            style == other.style &&
            textDirection == other.textDirection &&
            locale == other.locale &&
            textScaler == other.textScaler &&
            devicePixelRatio == other.devicePixelRatio;
  }

  @override
  int get hashCode => Object.hash(
    text,
    style,
    textDirection,
    locale,
    textScaler,
    devicePixelRatio,
  );
}

/// Test-only bounded candidate retained for future benchmark comparisons.
///
/// BC-0019 rejected production integration because the candidate missed the
/// approved absolute p95 benefit floor. Keeping the smallest representative
/// implementation here lets future Flutter engine changes be re-measured
/// without adding cache state to the rendering pipeline.
final class _BoundedCandidateCache {
  _BoundedCandidateCache({this.capacity = 16});

  final int capacity;
  final LinkedHashMap<_LayoutRequest, TextPainter> _entries =
      LinkedHashMap<_LayoutRequest, TextPainter>();

  var hitCount = 0;
  var missCount = 0;
  var disposedPainterCount = 0;

  int get entryCount => _entries.length;

  TextPainter layout(_LayoutRequest request) {
    final cached = _entries.remove(request);
    if (cached != null) {
      _entries[request] = cached;
      hitCount++;
      return cached;
    }

    missCount++;
    final painter = TextPainter(
      text: TextSpan(text: request.text, style: request.style),
      textDirection: request.textDirection,
      locale: request.locale,
      textScaler: request.textScaler,
    )..layout();
    _entries[request] = painter;

    if (_entries.length > capacity) {
      final oldestRequest = _entries.keys.first;
      _entries.remove(oldestRequest)!.dispose();
      disposedPainterCount++;
    }
    return painter;
  }

  void dispose() {
    for (final painter in _entries.values) {
      painter.dispose();
      disposedPainterCount++;
    }
    _entries.clear();
  }
}

const _environmentCases = <_EnvironmentCase>[
  (
    direction: TextDirection.ltr,
    locale: Locale('en', 'ZA'),
    textScaler: TextScaler.noScaling,
    devicePixelRatio: 1,
  ),
  (
    direction: TextDirection.ltr,
    locale: Locale('en', 'ZA'),
    textScaler: TextScaler.linear(1.5),
    devicePixelRatio: 1,
  ),
  (
    direction: TextDirection.rtl,
    locale: Locale('en', 'ZA'),
    textScaler: TextScaler.noScaling,
    devicePixelRatio: 1,
  ),
  (
    direction: TextDirection.ltr,
    locale: Locale('ar'),
    textScaler: TextScaler.noScaling,
    devicePixelRatio: 1,
  ),
  (
    direction: TextDirection.ltr,
    locale: Locale('en', 'ZA'),
    textScaler: TextScaler.noScaling,
    devicePixelRatio: 2,
  ),
];

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
        text: TextSpan(text: text, style: _labelStyle),
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

_LayoutRequest _requestFor(
  String text, {
  TextDirection direction = TextDirection.ltr,
  Locale? locale = const Locale('en', 'ZA'),
  TextScaler textScaler = TextScaler.noScaling,
  double devicePixelRatio = 1,
}) {
  return _LayoutRequest(
    text: text,
    style: _labelStyle,
    textDirection: direction,
    locale: locale,
    textScaler: textScaler,
    devicePixelRatio: devicePixelRatio,
  );
}

void _layoutCachedFrame({
  required _Scenario scenario,
  required int frame,
  required _BoundedCandidateCache cache,
}) {
  for (final text in _labelsForFrame(scenario, frame)) {
    cache.layout(_requestFor(text));
  }
}

void _warmCached(_Scenario scenario) {
  final cache = _BoundedCandidateCache();
  try {
    for (var frame = 0; frame < _warmupFrameCount; frame++) {
      _layoutCachedFrame(scenario: scenario, frame: frame, cache: cache);
    }
  } finally {
    cache.dispose();
  }
}

_TrialResult _measureCachedTrial(_Scenario scenario) {
  final cache = _BoundedCandidateCache();
  final frameMicros = <int>[];

  try {
    for (var frame = 0; frame < _frameCount; frame++) {
      final stopwatch = Stopwatch()..start();
      _layoutCachedFrame(scenario: scenario, frame: frame, cache: cache);
      stopwatch.stop();
      frameMicros.add(stopwatch.elapsedMicroseconds);
    }
  } finally {
    // Final cleanup is outside timing, matching uncached trial cleanup. LRU
    // eviction/disposal caused by changing labels remains inside each sample.
    cache.dispose();
  }

  frameMicros.sort();
  return (
    medianMicros: frameMicros[frameMicros.length ~/ 2],
    p95Micros: frameMicros[(frameMicros.length * 0.95).ceil() - 1],
  );
}

_PairedTrials _measurePairedScenario(_Scenario scenario) {
  final uncached = <_TrialResult>[];
  final cached = <_TrialResult>[];
  for (var trial = 0; trial < _trialCount; trial++) {
    final cachedFirst = trial.isEven;
    if (cachedFirst) {
      _warmCached(scenario);
      _warmUncached(scenario);
      cached.add(_measureCachedTrial(scenario));
      uncached.add(_measureUncachedTrial(scenario));
    } else {
      _warmUncached(scenario);
      _warmCached(scenario);
      uncached.add(_measureUncachedTrial(scenario));
      cached.add(_measureCachedTrial(scenario));
    }
  }
  return (uncached: uncached, cached: cached);
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

String _formatPaired(String name, _PairedTrials paired) {
  return '$name\n'
      '  uncached: ${_formatTrials(paired.uncached)}\n'
      '  cached: ${_formatTrials(paired.cached)}\n'
      '  decision p95: '
      '${_medianTrialP95(paired.uncached)}us uncached / '
      '${_medianTrialP95(paired.cached)}us cached';
}

TextPainter _uncachedEnvironmentPainter(_EnvironmentCase environment) {
  return TextPainter(
    text: const TextSpan(text: '42.00 unit', style: _labelStyle),
    textDirection: environment.direction,
    locale: environment.locale,
    textScaler: environment.textScaler,
  )..layout();
}

_LayoutRequest _environmentRequest(_EnvironmentCase environment) {
  return _requestFor(
    '42.00 unit',
    direction: environment.direction,
    locale: environment.locale,
    textScaler: environment.textScaler,
    devicePixelRatio: environment.devicePixelRatio,
  );
}

void _warmUncachedEnvironment() {
  final retainedPainters = <TextPainter>[];
  try {
    for (var frame = 0; frame < _warmupFrameCount; frame++) {
      final environment = _environmentCases[frame % _environmentCases.length];
      retainedPainters.add(_uncachedEnvironmentPainter(environment));
    }
  } finally {
    for (final painter in retainedPainters) {
      painter.dispose();
    }
  }
}

void _warmCachedEnvironment() {
  final cache = _BoundedCandidateCache();
  try {
    for (var frame = 0; frame < _warmupFrameCount; frame++) {
      final environment = _environmentCases[frame % _environmentCases.length];
      cache.layout(_environmentRequest(environment));
    }
  } finally {
    cache.dispose();
  }
}

_TrialResult _measureUncachedEnvironmentTrial() {
  final frameMicros = <int>[];
  final retainedPainters = <TextPainter>[];
  try {
    for (var frame = 0; frame < _frameCount; frame++) {
      final environment = _environmentCases[frame % _environmentCases.length];
      final stopwatch = Stopwatch()..start();
      retainedPainters.add(_uncachedEnvironmentPainter(environment));
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

_TrialResult _measureCachedEnvironmentTrial() {
  final cache = _BoundedCandidateCache();
  final frameMicros = <int>[];
  try {
    for (var frame = 0; frame < _frameCount; frame++) {
      final environment = _environmentCases[frame % _environmentCases.length];
      final stopwatch = Stopwatch()..start();
      cache.layout(_environmentRequest(environment));
      stopwatch.stop();
      frameMicros.add(stopwatch.elapsedMicroseconds);
    }
  } finally {
    cache.dispose();
  }

  frameMicros.sort();
  return (
    medianMicros: frameMicros[frameMicros.length ~/ 2],
    p95Micros: frameMicros[(frameMicros.length * 0.95).ceil() - 1],
  );
}

_PairedTrials _measurePairedEnvironment() {
  final uncached = <_TrialResult>[];
  final cached = <_TrialResult>[];
  for (var trial = 0; trial < _trialCount; trial++) {
    final cachedFirst = trial.isEven;
    if (cachedFirst) {
      _warmCachedEnvironment();
      _warmUncachedEnvironment();
      cached.add(_measureCachedEnvironmentTrial());
      uncached.add(_measureUncachedEnvironmentTrial());
    } else {
      _warmUncachedEnvironment();
      _warmCachedEnvironment();
      uncached.add(_measureUncachedEnvironmentTrial());
      cached.add(_measureCachedEnvironmentTrial());
    }
  }
  return (uncached: uncached, cached: cached);
}

void _verifyMultiAxisBehavior() {
  final cache = _BoundedCandidateCache();
  try {
    final unchanged = _labelsForFrame(_Scenario.multiAxisUnchanged, 0);
    expect(unchanged, hasLength(7));
    expect(unchanged.toSet(), hasLength(7));

    for (final text in unchanged) {
      cache.layout(_requestFor(text));
    }
    for (final text in unchanged) {
      cache.layout(_requestFor(text));
    }
    expect(cache.entryCount, 7);
    expect(cache.missCount, 7);
    expect(cache.hitCount, 7);

    // Changing frame zero deliberately repeats the unchanged sample. The next
    // four frames introduce 28 distinct labels and deterministically exercise
    // eviction from the 16-entry LRU.
    for (var frame = 0; frame < 5; frame++) {
      for (final text in _labelsForFrame(_Scenario.multiAxisChanging, frame)) {
        cache.layout(_requestFor(text));
      }
      expect(cache.entryCount, lessThanOrEqualTo(16));
    }
    expect(cache.hitCount, 14);
    expect(cache.missCount, 35);
    expect(cache.entryCount, 16);
    expect(cache.disposedPainterCount, 19);
  } finally {
    cache.dispose();
  }
}

void _verifyEnvironmentMisses() {
  final cache = _BoundedCandidateCache();
  try {
    for (final environment in _environmentCases) {
      cache.layout(_environmentRequest(environment));
    }
    expect(cache.missCount, _environmentCases.length);
    expect(cache.hitCount, 0);
    expect(cache.entryCount, _environmentCases.length);

    cache.layout(_environmentRequest(_environmentCases.first));
    expect(cache.missCount, _environmentCases.length);
    expect(cache.hitCount, 1);
    expect(cache.entryCount, _environmentCases.length);
  } finally {
    cache.dispose();
  }
}

void main() {
  test('reports paired crosshair axis-label layout diagnostics', () {
    final unchanged = _measurePairedScenario(_Scenario.singleAxisUnchanged);
    final changing = _measurePairedScenario(_Scenario.singleAxisChanging);
    final multiAxisUnchanged = _measurePairedScenario(
      _Scenario.multiAxisUnchanged,
    );
    final multiAxisChanging = _measurePairedScenario(
      _Scenario.multiAxisChanging,
    );
    final environment = _measurePairedEnvironment();

    final unchangedBaseline = _medianTrialP95(unchanged.uncached);
    final unchangedCandidate = _medianTrialP95(unchanged.cached);
    final changingBaseline = _medianTrialP95(changing.uncached);
    final changingCandidate = _medianTrialP95(changing.cached);
    final savedMicros = unchangedBaseline - unchangedCandidate;
    final savedPercent = unchangedBaseline == 0
        ? 0.0
        : savedMicros / unchangedBaseline * 100;
    final changingRegression = changingCandidate - changingBaseline;
    final changingLimit = math.max(changingBaseline * 0.10, 50);

    // ignore: avoid_print
    print(_formatPaired('singleAxisUnchanged', unchanged));
    // ignore: avoid_print
    print(_formatPaired('singleAxisChanging', changing));
    // ignore: avoid_print
    print(_formatPaired('multiAxisUnchanged', multiAxisUnchanged));
    // ignore: avoid_print
    print(_formatPaired('multiAxisChanging', multiAxisChanging));
    // ignore: avoid_print
    print(_formatPaired('environmentChanging', environment));
    // ignore: avoid_print
    print(
      'gate: saved=$savedMicros us '
      '(${savedPercent.toStringAsFixed(2)}%); '
      'changingRegression=$changingRegression us; '
      'changingLimit=${changingLimit.toStringAsFixed(2)} us',
    );

    // Timing is diagnostic only. BC-0019's production decision is recorded
    // from stable paired runs in the design document; CI asserts deterministic
    // bounded-cache behavior rather than machine-sensitive thresholds.
    _verifyMultiAxisBehavior();
    _verifyEnvironmentMisses();
  });
}
