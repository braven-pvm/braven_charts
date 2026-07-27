# Crosshair Axis-Label Layout Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Measure and, only if justified, add safe per-chart reuse of crosshair axis-label text layout without stale content, styling, placement, accessibility, or device behavior.

**Architecture:** `ChartRenderBox` owns one bounded `CrosshairAxisLabelLayoutCache` and its lifecycle; the stateless `CrosshairRenderer` supplies fully resolved label text and layout inputs. Only `TextPainter` paragraph layout is reused. Formatter execution, axis geometry, cursor placement, backgrounds, borders, colors, semantics, zoom, pan, and synchronized positioning remain live per frame.

**Tech Stack:** Dart, Flutter rendering and painting APIs, `TextPainter`, `LinkedHashMap`, `flutter_test`, existing Braven Charts render-object and benchmark infrastructure.

---

## File map

- Create `lib/src/rendering/modules/crosshair_axis_label_layout_cache.dart`
  - Internal 16-entry LRU cache, compatibility key, environment value, debug
    counters, eviction, clearing, and disposal.
- Create
  `test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart`
  - Compatibility, LRU, invalidation, and lifecycle unit tests.
- Create
  `test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart`
  - Counterbalanced five-pair single-axis gate plus multi-axis and
    environment-key diagnostic workloads, recording median and p95.
- Modify `lib/src/rendering/modules/crosshair_renderer.dart`
  - Route the seven axis-label layout sites through the injected cache while
    keeping all placement and paint calculations live.
- Modify `lib/src/rendering/chart_render_box.dart`
  - Own, clear, pass, and dispose the cache; carry locale, text scaling,
    direction, and device-pixel-ratio inputs.
- Modify `lib/src/braven_chart_plus.dart`
  - Read the effective inherited rendering environment and propagate it
    through `_ChartRenderWidget`.
- Modify `test/unit/rendering/modules/crosshair_renderer_test.dart`
  - Supply the cache/environment and verify reuse cannot freeze paint or
    placement.
- Modify `test/unit/rendering/crosshair_renderer_x_axis_test.dart`
  - Supply the cache/environment and preserve top, bottom, mirrored, and
    tracking X-label behavior.
- Modify `test/widgets/braven_chart_plus_interaction_test.dart`
  - Verify inherited scale, direction, locale, and DPR reach the render object
    and invalidate retained layouts.
- Modify
  `docs/superpowers/specs/2026-07-26-crosshair-axis-label-layout-cache-design.md`
  - Record measured evidence and the ship/no-ship decision.
- Update external register item
  `F:\Repositories\_braven_charts_register\items\BC-0019-crosshair-label-cache.md`
  - Record evidence, deferrals, residual risk, and next state.

## Decision rule

Tasks 1–3 are mandatory. After Task 3:

- execute Tasks 4–6 only if unchanged-label p95 improves by both at least
  20 percent and at least 0.10 ms, while changing-label p95 regresses by no
  more than the greater of 10 percent or 0.05 ms;
- otherwise execute Task 7 instead and do not add production cache state.

The approved gate uses the single-axis workload: exactly one formatted X label
and one formatted Y label per frame. Its unchanged case drives the benefit
threshold, and its changing case drives the regression guard. The multi-axis
and environment-key workloads are non-gating diagnostics: they must report
median and p95, prove independently formatted Y labels remain distinct, prove
every environment-key change misses, and prove the cache stays within capacity.
They do not weaken or replace either approved single-axis threshold.

### Task 0: Reconcile the claim and current master

**Files:**
- Read:
  `F:\Repositories\_braven_charts_register\items\BC-0019-crosshair-label-cache.md`
- Read: `docs/agent_onboarding.md`
- Read: `docs/issue_workflow.md`

- [ ] **Step 1: Reconfirm exclusive ownership**

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' list
Get-Content 'F:\Repositories\_braven_charts_register\items\BC-0019-crosshair-label-cache.md'
```

Expected: `BC-0019` remains `In Progress`, owned by `Codex-BC0019`, on
`perf/crosshair-label-cache`, with no competing branch, worktree, or PR.
Stop and reconcile ownership before any code edit if that is no longer true.

- [ ] **Step 2: Rebase the committed design and plan onto current master**

```powershell
git fetch origin master
git status --short --branch
git rebase origin/master
```

Expected: the branch contains the design/plan commits on top of current
`origin/master`. Resolve only conflicts in this lane's two documentation files;
stop for owner direction if production files conflict.

- [ ] **Step 3: Re-read the affected paths after rebase**

```powershell
rg -n "crosshair label caching|CrosshairRenderer|textScaleFactor|textDirection" lib/src/rendering/chart_render_box.dart lib/src/rendering/modules/crosshair_renderer.dart lib/src/braven_chart_plus.dart
```

Expected: the four stale cache comments and the renderer ownership boundary
still exist. Amend the plan before execution if master changed either contract.

- [ ] **Step 4: Re-run the clean baseline**

```powershell
flutter pub get
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
flutter analyze --no-pub lib
```

Expected: 33 focused tests pass and analysis reports no issues. If test counts
change on master, record the actual count rather than retaining 33 as evidence.

### Task 1: Add the uncached benchmark baseline

**Files:**
- Create:
  `test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart`

- [ ] **Step 1: Define concrete single- and multi-axis workloads**

Create the benchmark with the real paragraph inputs used by crosshair labels.
The single-axis workload emits exactly one X and one Y label. The multi-axis
workload emits one X and six independently formatted Y labels:

```dart
import 'dart:ui';

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
  bool get changing =>
      this == _Scenario.singleAxisChanging ||
      this == _Scenario.multiAxisChanging;

  bool get multiAxis =>
      this == _Scenario.multiAxisUnchanged ||
      this == _Scenario.multiAxisChanging;
}

typedef _TrialResult = ({int medianMicros, int p95Micros});

List<String> _labelsForFrame(_Scenario scenario, int frame) {
  final sample = scenario.changing ? frame + 42 : 42;
  final labels = <String>[
    '2026-07-${sample.toString().padLeft(2, '0')}',
  ];
  if (!scenario.multiAxis) {
    return [...labels, '${(sample * 1.25).toStringAsFixed(2)} W'];
  }
  return [
    ...labels,
    '${(sample * 1.25).toStringAsFixed(0)} W',
    '${(60 + sample * 0.25).toStringAsFixed(1)} bpm',
    '${(18 + sample * 0.01).toStringAsFixed(2)} °C',
    '${(sample / 3).toStringAsFixed(3)} m/s',
    '${(sample * 2).toStringAsFixed(0)} rpm',
    '${(sample / 10).toStringAsFixed(1)} mmol/L',
  ];
}
```

- [ ] **Step 2: Measure layout without charging baseline-only disposal**

Add the uncached warm-up and trial helpers. Retain every painter for the
complete trial and dispose it only after the last timed frame. The stopwatch
therefore measures paragraph construction/layout, not `TextPainter.dispose()`:

```dart
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
  for (var frame = 0; frame < _warmupFrameCount; frame++) {
    _layoutUncachedFrame(
      scenario: scenario,
      frame: frame,
      retainedPainters: retainedPainters,
    );
  }
  for (final painter in retainedPainters) {
    painter.dispose();
  }
}

_TrialResult _measureUncachedTrial(_Scenario scenario) {
  final samples = <int>[];
  final retainedPainters = <TextPainter>[];
  for (var frame = 0; frame < _frameCount; frame++) {
    final watch = Stopwatch()..start();
    _layoutUncachedFrame(
      scenario: scenario,
      frame: frame,
      retainedPainters: retainedPainters,
    );
    watch.stop();
    samples.add(watch.elapsedMicroseconds);
  }
  for (final painter in retainedPainters) {
    painter.dispose();
  }
  samples.sort();
  return (
    medianMicros: samples[samples.length ~/ 2],
    p95Micros: samples[(samples.length * 0.95).ceil() - 1],
  );
}

int _medianTrialP95(List<_TrialResult> trials) {
  final p95s = [for (final trial in trials) trial.p95Micros]..sort();
  return p95s[p95s.length ~/ 2];
}

String _formatTrials(List<_TrialResult> trials) => trials
    .map(
      (trial) =>
          'median=${trial.medianMicros / 1000}ms '
          'p95=${trial.p95Micros / 1000}ms',
    )
    .join(', ');
```

- [ ] **Step 3: Record five baseline trials for every workload**

Add the baseline test. It records both median and p95 for every trial, plus the
median of five p95 values used later by the decision:

```dart
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
      expect(trials.every((trial) => trial.p95Micros >= trial.medianMicros), isTrue);
    }
  });
}
```

- [ ] **Step 4: Run the baseline twice**

Run:

```powershell
dart format test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
```

Expected: both runs pass and print median and p95 for five trials of all four
workloads. Record both complete outputs; do not select a favorable run.

- [ ] **Step 5: Commit the baseline**

```powershell
git add test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
git commit -m "test: benchmark crosshair axis label layout"
```

### Task 2: Build the bounded cache with lifecycle tests

**Files:**
- Create:
  `lib/src/rendering/modules/crosshair_axis_label_layout_cache.dart`
- Create:
  `test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart`

- [ ] **Step 1: Write failing compatibility tests**

Write tests for hits, every key input, capacity, clear, and disposal:

```dart
import 'dart:ui';

import 'package:braven_charts/src/rendering/modules/crosshair_axis_label_layout_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosshairAxisLabelLayoutCache', () {
    late CrosshairAxisLabelLayoutCache cache;

    setUp(() {
      cache = CrosshairAxisLabelLayoutCache(capacity: 2);
    });

    tearDown(() {
      cache.dispose();
    });

    test('reuses only a fully compatible layout', () {
      final first = cache.layout(_request());
      final second = cache.layout(_request());

      expect(identical(first, second), isTrue);
      expect(cache.debugHitCount, 1);
      expect(cache.debugMissCount, 1);
    });

    test('misses for every paragraph compatibility input', () {
      final baseline = cache.layout(_request());
      final variants = <CrosshairAxisLabelLayoutRequest>[
        _request(text: '43.00'),
        _request(style: const TextStyle(fontSize: 12)),
        _request(direction: TextDirection.rtl),
        _request(locale: const Locale('ar')),
        _request(textScaler: const TextScaler.linear(1.5)),
        _request(devicePixelRatio: 2),
        _request(minWidth: 20),
        _request(maxWidth: 80),
      ];

      for (final variant in variants) {
        expect(identical(cache.layout(variant), baseline), isFalse);
      }
    });

    test('evicts least recently used entries and disposes every removal', () {
      cache.layout(_request(text: 'one'));
      cache.layout(_request(text: 'two'));
      cache.layout(_request(text: 'one'));
      cache.layout(_request(text: 'three'));

      expect(cache.debugEntryCount, 2);
      expect(cache.debugDisposedPainterCount, 1);

      cache.clear();
      expect(cache.debugEntryCount, 0);
      expect(cache.debugDisposedPainterCount, 3);
    });

    test('dispose is idempotent and rejects later layout', () {
      cache.layout(_request());
      cache.dispose();
      cache.dispose();

      expect(cache.debugDisposedPainterCount, 1);
      expect(() => cache.layout(_request()), throwsStateError);
    });
  });
}

CrosshairAxisLabelLayoutRequest _request({
  String text = '42.00',
  TextStyle style = const TextStyle(fontSize: 11),
  TextDirection direction = TextDirection.ltr,
  Locale? locale = const Locale('en', 'ZA'),
  TextScaler textScaler = TextScaler.noScaling,
  double devicePixelRatio = 1,
  double minWidth = 0,
  double maxWidth = double.infinity,
}) {
  return CrosshairAxisLabelLayoutRequest(
    text: text,
    style: style,
    textDirection: direction,
    locale: locale,
    textScaler: textScaler,
    devicePixelRatio: devicePixelRatio,
    minWidth: minWidth,
    maxWidth: maxWidth,
  );
}
```

- [ ] **Step 2: Run the tests to verify failure**

Run:

```powershell
flutter test test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart
```

Expected: compilation fails because the cache types do not exist.

- [ ] **Step 3: Implement the cache**

Create the internal cache:

```dart
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class CrosshairAxisLabelLayoutEnvironment {
  const CrosshairAxisLabelLayoutEnvironment({
    this.textDirection = TextDirection.ltr,
    this.locale,
    this.textScaler = TextScaler.noScaling,
    this.devicePixelRatio = 1,
  }) : assert(devicePixelRatio > 0);

  final TextDirection textDirection;
  final Locale? locale;
  final TextScaler textScaler;
  final double devicePixelRatio;
}

@immutable
class CrosshairAxisLabelLayoutRequest {
  const CrosshairAxisLabelLayoutRequest({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.textScaler,
    required this.devicePixelRatio,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
  }) : assert(devicePixelRatio > 0),
       assert(minWidth >= 0),
       assert(maxWidth >= minWidth);

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final TextScaler textScaler;
  final double devicePixelRatio;
  final double minWidth;
  final double maxWidth;

  @override
  bool operator ==(Object other) =>
      other is CrosshairAxisLabelLayoutRequest &&
      text == other.text &&
      style == other.style &&
      textDirection == other.textDirection &&
      locale == other.locale &&
      textScaler == other.textScaler &&
      devicePixelRatio == other.devicePixelRatio &&
      minWidth == other.minWidth &&
      maxWidth == other.maxWidth;

  @override
  int get hashCode => Object.hash(
    text,
    style,
    textDirection,
    locale,
    textScaler,
    devicePixelRatio,
    minWidth,
    maxWidth,
  );
}

class CrosshairAxisLabelLayoutCache {
  CrosshairAxisLabelLayoutCache({this.capacity = 16})
    : assert(capacity > 0);

  final int capacity;
  final LinkedHashMap<CrosshairAxisLabelLayoutRequest, TextPainter> _entries =
      LinkedHashMap<CrosshairAxisLabelLayoutRequest, TextPainter>();
  bool _disposed = false;
  int _hitCount = 0;
  int _missCount = 0;
  int _disposedPainterCount = 0;

  @visibleForTesting
  int get debugEntryCount => _entries.length;
  @visibleForTesting
  int get debugHitCount => _hitCount;
  @visibleForTesting
  int get debugMissCount => _missCount;
  @visibleForTesting
  int get debugDisposedPainterCount => _disposedPainterCount;

  TextPainter layout(CrosshairAxisLabelLayoutRequest request) {
    if (_disposed) {
      throw StateError('CrosshairAxisLabelLayoutCache is disposed.');
    }
    final retained = _entries.remove(request);
    if (retained != null) {
      _entries[request] = retained;
      _hitCount++;
      return retained;
    }

    _missCount++;
    final painter = TextPainter(
      text: TextSpan(text: request.text, style: request.style),
      textDirection: request.textDirection,
      textScaler: request.textScaler,
      locale: request.locale,
    )..layout(minWidth: request.minWidth, maxWidth: request.maxWidth);
    _entries[request] = painter;
    if (_entries.length > capacity) {
      final oldestKey = _entries.keys.first;
      _disposePainter(_entries.remove(oldestKey)!);
    }
    return painter;
  }

  void clear() {
    for (final painter in _entries.values) {
      _disposePainter(painter);
    }
    _entries.clear();
  }

  void dispose() {
    if (_disposed) return;
    clear();
    _disposed = true;
  }

  void _disposePainter(TextPainter painter) {
    painter.dispose();
    _disposedPainterCount++;
  }
}
```

- [ ] **Step 4: Run and format**

Run:

```powershell
dart format lib/src/rendering/modules/crosshair_axis_label_layout_cache.dart test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart
flutter test test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart
```

Expected: all cache tests pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/src/rendering/modules/crosshair_axis_label_layout_cache.dart test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart
git commit -m "perf: add bounded crosshair label layout cache"
```

### Task 3: Apply the performance gate

**Files:**
- Modify:
  `test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart`

- [ ] **Step 1: Add the cached hot path with symmetric cleanup**

Import the candidate cache and add the cached warm-up/trial helpers:

```dart
import 'dart:math' as math;

import 'package:braven_charts/src/rendering/modules/crosshair_axis_label_layout_cache.dart';

const _labelStyle = TextStyle(fontSize: 11, color: Color(0xFF202124));

CrosshairAxisLabelLayoutRequest _requestFor(
  String text, {
  TextDirection direction = TextDirection.ltr,
  Locale? locale = const Locale('en', 'ZA'),
  TextScaler textScaler = TextScaler.noScaling,
  double devicePixelRatio = 1,
}) {
  return CrosshairAxisLabelLayoutRequest(
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
  required CrosshairAxisLabelLayoutCache cache,
}) {
  for (final text in _labelsForFrame(scenario, frame)) {
    cache.layout(_requestFor(text));
  }
}

void _warmCached(_Scenario scenario) {
  final cache = CrosshairAxisLabelLayoutCache();
  for (var frame = 0; frame < _warmupFrameCount; frame++) {
    _layoutCachedFrame(scenario: scenario, frame: frame, cache: cache);
  }
  cache.dispose();
}

_TrialResult _measureCachedTrial(_Scenario scenario) {
  final cache = CrosshairAxisLabelLayoutCache();
  final samples = <int>[];
  for (var frame = 0; frame < _frameCount; frame++) {
    final watch = Stopwatch()..start();
    _layoutCachedFrame(scenario: scenario, frame: frame, cache: cache);
    watch.stop();
    samples.add(watch.elapsedMicroseconds);
  }
  // Final cleanup is outside timing, matching uncached trial cleanup. LRU
  // eviction/disposal caused by changing labels remains inside each sample.
  cache.dispose();
  samples.sort();
  return (
    medianMicros: samples[samples.length ~/ 2],
    p95Micros: samples[(samples.length * 0.95).ceil() - 1],
  );
}
```

- [ ] **Step 2: Counterbalance every paired trial**

Warm both paths with the same frame count and inputs before every pair. Alternate
both warm-up and measurement order so cached runs are first on even trials and
uncached runs are first on odd trials:

```dart
typedef _PairedTrials = ({
  List<_TrialResult> uncached,
  List<_TrialResult> cached,
});

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

String _formatPaired(String name, _PairedTrials paired) =>
    '$name uncached=[${_formatTrials(paired.uncached)}] '
    'cached=[${_formatTrials(paired.cached)}] '
    'decisionP95='
    '${_medianTrialP95(paired.uncached) / 1000}ms/'
    '${_medianTrialP95(paired.cached) / 1000}ms';
```

- [ ] **Step 3: Add the environment-key diagnostic workload**

Use identical text/style while changing exactly one environment key from the
baseline at a time:

```dart
typedef _EnvironmentCase = ({
  TextDirection direction,
  Locale? locale,
  TextScaler textScaler,
  double devicePixelRatio,
});

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

TextPainter _uncachedEnvironmentPainter(_EnvironmentCase environment) =>
    TextPainter(
      text: const TextSpan(text: '42.00 unit', style: _labelStyle),
      textDirection: environment.direction,
      locale: environment.locale,
      textScaler: environment.textScaler,
    )..layout();

CrosshairAxisLabelLayoutRequest _environmentRequest(
  _EnvironmentCase environment,
) => _requestFor(
  '42.00 unit',
  direction: environment.direction,
  locale: environment.locale,
  textScaler: environment.textScaler,
  devicePixelRatio: environment.devicePixelRatio,
);

_TrialResult _measureUncachedEnvironmentTrial() {
  final samples = <int>[];
  final retainedPainters = <TextPainter>[];
  for (var frame = 0; frame < _frameCount; frame++) {
    final environment = _environmentCases[frame % _environmentCases.length];
    final watch = Stopwatch()..start();
    retainedPainters.add(_uncachedEnvironmentPainter(environment));
    watch.stop();
    samples.add(watch.elapsedMicroseconds);
  }
  for (final painter in retainedPainters) {
    painter.dispose();
  }
  samples.sort();
  return (
    medianMicros: samples[samples.length ~/ 2],
    p95Micros: samples[(samples.length * 0.95).ceil() - 1],
  );
}

_TrialResult _measureCachedEnvironmentTrial() {
  final cache = CrosshairAxisLabelLayoutCache();
  final samples = <int>[];
  for (var frame = 0; frame < _frameCount; frame++) {
    final environment = _environmentCases[frame % _environmentCases.length];
    final watch = Stopwatch()..start();
    cache.layout(_environmentRequest(environment));
    watch.stop();
    samples.add(watch.elapsedMicroseconds);
  }
  cache.dispose();
  samples.sort();
  return (
    medianMicros: samples[samples.length ~/ 2],
    p95Micros: samples[(samples.length * 0.95).ceil() - 1],
  );
}
```

Warm and pair the environment workload explicitly:

```dart
void _warmUncachedEnvironment() {
  final retainedPainters = <TextPainter>[];
  for (var frame = 0; frame < _warmupFrameCount; frame++) {
    final environment = _environmentCases[frame % _environmentCases.length];
    retainedPainters.add(_uncachedEnvironmentPainter(environment));
  }
  for (final painter in retainedPainters) {
    painter.dispose();
  }
}

void _warmCachedEnvironment() {
  final cache = CrosshairAxisLabelLayoutCache();
  for (var frame = 0; frame < _warmupFrameCount; frame++) {
    final environment = _environmentCases[frame % _environmentCases.length];
    cache.layout(_environmentRequest(environment));
  }
  cache.dispose();
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
```

- [ ] **Step 4: Assert non-gating scenario behavior**

Add deterministic diagnostics alongside timing:

```dart
void _verifyMultiAxisBehavior() {
  final cache = CrosshairAxisLabelLayoutCache();
  final unchanged = _labelsForFrame(_Scenario.multiAxisUnchanged, 0);
  expect(unchanged, hasLength(7));
  expect(unchanged.toSet(), hasLength(7));

  for (final text in unchanged) {
    cache.layout(_requestFor(text));
  }
  for (final text in unchanged) {
    cache.layout(_requestFor(text));
  }
  expect(cache.debugMissCount, 7);
  expect(cache.debugHitCount, 7);

  for (var frame = 0; frame < 5; frame++) {
    for (final text in _labelsForFrame(_Scenario.multiAxisChanging, frame)) {
      cache.layout(_requestFor(text));
    }
    expect(cache.debugEntryCount, lessThanOrEqualTo(16));
  }
  expect(cache.debugDisposedPainterCount, greaterThan(0));
  cache.dispose();
}

void _verifyEnvironmentMisses() {
  final cache = CrosshairAxisLabelLayoutCache();
  for (final environment in _environmentCases) {
    cache.layout(_environmentRequest(environment));
  }
  expect(cache.debugMissCount, _environmentCases.length);
  expect(cache.debugHitCount, 0);
  expect(cache.debugEntryCount, _environmentCases.length);

  cache.layout(_environmentRequest(_environmentCases.first));
  expect(cache.debugHitCount, 1);
  cache.dispose();
}
```

This proves the multi-axis workload is one X plus six distinct Y labels,
changing labels trigger bounded LRU eviction, and scale, direction, locale,
and DPR each produce a miss despite identical text/style.

- [ ] **Step 5: Calculate and print the exact decision**

Replace Task 1's baseline-only `main()` with this named decision test. It
measures all workloads, prints every trial's median and p95, and applies
thresholds only to the single-axis pair:

```dart
void main() {
  test('applies the paired crosshair axis-label layout gate', () {
    final unchanged = _measurePairedScenario(
      _Scenario.singleAxisUnchanged,
    );
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
    final savedPercent = savedMicros / unchangedBaseline * 100;
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
      'gate: saved=$savedMicros us ($savedPercent%); '
      'changingRegression=$changingRegression us; '
      'changingLimit=$changingLimit us',
    );

    _verifyMultiAxisBehavior();
    _verifyEnvironmentMisses();
    expect(savedPercent, greaterThanOrEqualTo(20));
    expect(savedMicros, greaterThanOrEqualTo(100));
    expect(changingRegression, lessThanOrEqualTo(changingLimit));
  });
}
```

`_measurePairedEnvironment` must return `_PairedTrials`, so the same
`_formatPaired` output records median and p95 for all five uncached and cached
trials. The decision remains the median of five p95 values; no median value is
substituted into a gate.

- [ ] **Step 6: Run the decision benchmark twice**

Run:

```powershell
dart format test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
```

Expected: the same ship/no-ship decision on both runs, with median/p95 output
for single-axis unchanged/changing, multi-axis unchanged/changing, and
environment-changing trials. Record both complete outputs. If decisions
differ, increase trial/sample counts equally for both paths and repeat; do not
weaken any threshold.

- [ ] **Step 7: Choose exactly one route**

If both runs pass every assertion, continue with Task 4.

If either stable run fails an assertion, stop Tasks 4–6 and execute Task 7.

- [ ] **Step 8: Commit the decision harness**

```powershell
git add test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
git commit -m "test: gate crosshair label layout caching"
```

### Task 4: Integrate cache reuse into all axis-label paths

**Files:**
- Modify: `lib/src/rendering/modules/crosshair_renderer.dart`
- Modify: `lib/src/rendering/chart_render_box.dart`
- Modify:
  `test/unit/rendering/modules/crosshair_renderer_test.dart`
- Modify:
  `test/unit/rendering/crosshair_renderer_x_axis_test.dart`

- [ ] **Step 1: Add observable repeated-paint test support**

In both test suites, create and dispose a cache in `setUp`/`tearDown`, define:

```dart
const labelEnvironment = CrosshairAxisLabelLayoutEnvironment(
  textDirection: TextDirection.ltr,
  locale: Locale('en', 'ZA'),
  textScaler: TextScaler.noScaling,
  devicePixelRatio: 1,
);
```

Pass `axisLabelLayoutCache: labelCache` and
`axisLabelLayoutEnvironment: labelEnvironment` to every `renderer.paint(...)`
call.

Add an internal paint probe beside `PaintedIntersectionMarker`:

```dart
typedef PaintedCrosshairAxisLabel = ({
  String role,
  String? axisId,
  String text,
  Offset textOffset,
  RRect backgroundRect,
  Color backgroundColor,
  Color? borderColor,
  Color? textColor,
  Color? axisColor,
});
```

Add optional `List<PaintedCrosshairAxisLabel>? paintedAxisLabelSink` to
`CrosshairRenderer.paint`. Clear it at the start of each paint and record the
resolved text, final live offset/rectangle, and actual paint colors at every
cached axis-label site. This is a test probe only, like
`paintedMarkerSink`; it does not own layout or affect painting.

In the tests, copy the sink after each paint:

```dart
List<PaintedCrosshairAxisLabel> snapshot(
  List<PaintedCrosshairAxisLabel> sink,
) => List<PaintedCrosshairAxisLabel>.of(sink);

PaintedCrosshairAxisLabel labelFor(
  List<PaintedCrosshairAxisLabel> labels,
  String role, {
  String? axisId,
}) => labels.singleWhere(
  (label) => label.role == role && label.axisId == axisId,
);
```

- [ ] **Step 2: Add the complete cache-hit renderer matrix**

Add these named repeated-paint tests. Every case must capture the first
hit/miss counts and output, repaint with the stated change, assert the exact
counter delta, and compare the new sink snapshot:

1. `formatter and unit changes miss and paint new X text`
   - Paint twice without a formatter and with unit `s`; the second paint adds
     one X hit and preserves `text == '5 s'`.
   - Replace only the unit with `ms`; assert one miss,
     `text == '5 ms'`, and a changed `backgroundRect.width`.
   - Add a formatter returning `Session 5`; assert another miss and that exact
     text (the current formatter contract replaces numeric-plus-unit output).
   - Replace only the formatter with one returning `T=5.0`; assert another miss
     and `text == 'T=5.0'`.
2. `cache hit keeps background border and axis colors live`
   - Paint a constant X label with a blue axis, snapshot its blue-derived
     background/border, then repaint the same label/layout with a red axis.
   - Assert one hit, no miss, unchanged text metrics, red-derived
     `backgroundColor`/`borderColor`, and `axisColor == red` in the sink.
   - Repeat in tracking single-axis Y mode while changing only
     `crosshairLabelStyle.backgroundColor` and `borderColor`; assert a hit and
     both new colors in the sink.
3. `text color change misses and paints the new paragraph color`
   - Repaint identical text after changing only
     `crosshairLabelStyle.textStyle.color` from black to green.
   - Assert one miss rather than a hit and `textColor == green`; this proves
     text color remains live through the `TextStyle` key instead of reusing a
     stale colored paragraph.
4. `zoom pan and resize reuse layout but recompute placement`
   - Use a formatter that always returns `same`, paint twice at the initial
     transform/plot rect, and assert the second paint hits.
   - Repaint with zoomed data bounds and the cursor moved to the screen
     position for the same formatted value; assert another hit and changed
     `textOffset`.
   - Repaint with panned bounds, then with a narrower `plotArea`; assert one hit
     per paint and new/clamped `textOffset`/`backgroundRect` values each time.
5. `synchronized tracking hit follows the live synchronized position`
   - Supply a `CartesianTrackingSnapshot` with
     `origin: CartesianTrackingOrigin.synchronized`, constant formatted X/Y,
     and tracking mode with the tooltip disabled.
   - Paint twice at the first synchronized cursor and assert X/Y hits.
   - Paint the same snapshot text at a second synchronized cursor/plot X;
     assert X/Y hits again and changed X and Y `textOffset` values rather than
     retained pointer placement.
6. `multi-axis hits remain in current axis strips`
   - Use one X axis plus left `power` and right `heart-rate` axes whose
     formatters return `100 W` and `80 bpm`.
   - Paint twice; assert three hits on the second paint and three distinct sink
     records (`x`, `y/power`, `y/heart-rate`).
   - Change only plot bounds and axis-strip widths, repaint, assert three more
     hits, unchanged texts, and updated/distinct Y offsets matching
     `calculateYAxisCrosshairLabelX` for the new `MultiAxisInfo`.
7. `tick-label rotation does not rotate cached crosshair text`
   - Paint otherwise identical `XAxisConfig` values with
     `tickLabelRotationDegrees` `0` then `45`.
   - Assert the second paint hits and the crosshair label text offset/rectangle
     is identical because tick rotation is not a crosshair paragraph input.

Keep the existing top, bottom, mirrored, range-boundary, transposed, and
multi-axis assertions. These new cases supplement them with repeated-paint
hit/miss and live-output evidence; a one-shot `returnsNormally` assertion does
not satisfy this matrix.

- [ ] **Step 3: Run tests to verify the new required arguments fail**

Run:

```powershell
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
```

Expected: compilation fails because `CrosshairRenderer.paint` does not accept
the cache/environment/probe arguments.

- [ ] **Step 4: Add the renderer helper and required inputs**

Import the cache module and add required `paint` arguments:

```dart
required CrosshairAxisLabelLayoutCache axisLabelLayoutCache,
required CrosshairAxisLabelLayoutEnvironment axisLabelLayoutEnvironment,
List<PaintedCrosshairAxisLabel>? paintedAxisLabelSink,
```

Add this renderer helper:

```dart
TextPainter _layoutAxisLabel({
  required String text,
  required TextStyle style,
  required CrosshairAxisLabelLayoutCache cache,
  required CrosshairAxisLabelLayoutEnvironment environment,
  double minWidth = 0,
  double maxWidth = double.infinity,
}) {
  return cache.layout(
    CrosshairAxisLabelLayoutRequest(
      text: text,
      style: style,
      textDirection: resolveChartTextDirection(
        text,
        fallback: environment.textDirection,
      ),
      locale: environment.locale,
      textScaler: environment.textScaler,
      devicePixelRatio: environment.devicePixelRatio,
      minWidth: minWidth,
      maxWidth: maxWidth,
    ),
  );
}
```

Thread both values only through label-painting methods and replace the seven
axis-label `TextPainter(...)..layout()` sites:

1. Range Area upper/lower boundary labels.
2. Transposed tracking category label.
3. Standard X coordinate label.
4. Transposed value labels.
5. Per-axis Y coordinate labels.
6. Tracking X coordinate label.
7. Tracking single-axis Y coordinate label.

Do not route tracking tooltip rows, trend headers, value-summary content,
annotations, or ordinary axis ticks through this cache.

At each site, append the `PaintedCrosshairAxisLabel` record only after final
placement and live colors are resolved. Use stable roles `x`, `range-upper`,
`range-lower`, `transposed-x`, and `y`; put the series ID for range labels or
Y-axis ID for Y labels in `axisId`.

- [ ] **Step 5: Wire the minimum compilable per-chart caller**

Import the cache module in `chart_render_box.dart`, replace the four stale
cache-comment blocks with this owned field, and add an initial environment
derived entirely from values already present on `ChartRenderBox`:

```dart
/// Per-chart crosshair axis-label paragraph cache.
///
/// The render box owns lifecycle/invalidation; the stateless renderer owns
/// formatting, lookup, live placement, and painting.
final CrosshairAxisLabelLayoutCache _crosshairAxisLabelLayoutCache =
    CrosshairAxisLabelLayoutCache();

CrosshairAxisLabelLayoutEnvironment
get _crosshairAxisLabelLayoutEnvironment =>
    CrosshairAxisLabelLayoutEnvironment(
      textDirection: _textDirection,
      textScaler: TextScaler.linear(_textScaleFactor),
      locale: null,
      devicePixelRatio: 1,
    );
```

Pass the required arguments at the existing `_crosshairRenderer.paint` call:

```dart
axisLabelLayoutCache: _crosshairAxisLabelLayoutCache,
axisLabelLayoutEnvironment: _crosshairAxisLabelLayoutEnvironment,
```

Clear the owned cache when existing setters change paragraph inputs or
effective axes. Preserve each setter's existing equality/change predicate and
call `_crosshairAxisLabelLayoutCache.clear()` only inside the branch where the
value actually changed:

- `setTheme`;
- `setTextScaleFactor` and `setTextDirection`;
- `setXAxis` and `setXAxisConfig`;
- `setYAxis` and `setPrimaryYAxisConfig`;
- `setNormalizationMode`, `setSeries`, `setMaxAxesPerSide`, and
  `setAxisSwapMode`.

Keep formatter output as the primary key boundary; these structural clears
remove predictably obsolete entries. Add
`_crosshairAxisLabelLayoutCache.dispose()` exactly once in
`ChartRenderBox.dispose()`.

For manager-backed setters, use this shape rather than clearing unconditionally:

```dart
void setNormalizationMode(NormalizationMode? mode) {
  if (_multiAxisManager.setNormalizationMode(mode)) {
    _crosshairAxisLabelLayoutCache.clear();
    _seriesCacheManager.invalidate();
    _invalidateTrackingResolution();
    markNeedsLayout();
    markNeedsPaint();
  }
}
```

Apply the same changed-branch placement to `setSeries`, `setMaxAxesPerSide`,
and `setAxisSwapMode`. Preserve every pre-existing side effect in those
setters—including series-cache invalidation, tracking-resolution invalidation,
layout, and paint scheduling where currently present—and add only
`_crosshairAxisLabelLayoutCache.clear()` to their existing changed-value
branches.

This Task 4 bridge intentionally uses `locale: null` and DPR `1`; Task 5
upgrades those defaults to inherited values. Task 4 must compile and pass on
its own.

- [ ] **Step 6: Run focused renderer tests and the product analyzer**

Run:

```powershell
dart format lib/src/rendering/modules/crosshair_renderer.dart lib/src/rendering/chart_render_box.dart test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
flutter analyze --no-pub lib
```

Expected: all renderer tests pass. Every matrix test observes the specified
hit/miss delta and changed live text, color, or placement. Analysis reports no
issues, proving the production caller supplies every newly required argument.

- [ ] **Step 7: Commit the compilable renderer integration**

```powershell
git add lib/src/rendering/modules/crosshair_renderer.dart lib/src/rendering/chart_render_box.dart test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
git commit -m "perf: reuse crosshair axis label layouts"
```

### Task 5: Upgrade the cache to the inherited rendering environment

**Files:**
- Modify: `lib/src/braven_chart_plus.dart`
- Modify: `lib/src/rendering/chart_render_box.dart`
- Modify: `test/widgets/braven_chart_plus_interaction_test.dart`

- [ ] **Step 1: Write the inherited-environment widget test**

Pump a Cartesian chart inside `MediaQuery`, `Directionality`, and
`Localizations`, move the pointer into the plot to populate axis labels, then
read the `ChartRenderBox` debug values:

```dart
Future<void> pumpChart({
  required TextScaler textScaler,
  required TextDirection textDirection,
  required Locale locale,
  required double devicePixelRatio,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            devicePixelRatio: devicePixelRatio,
          ),
          child: Localizations.override(
            context: context,
            locale: locale,
            child: Directionality(
              textDirection: textDirection,
              child: const SizedBox(
                width: 520,
                height: 360,
                child: BravenChartPlus(
                  showLegend: false,
                  series: [
                    LineChartSeries(
                      id: 'signal',
                      points: [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 10, y: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

await pumpChart(
  textScaler: const TextScaler.linear(1.5),
  textDirection: TextDirection.rtl,
  locale: const Locale('ar'),
  devicePixelRatio: 2,
);
var renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
var mouseActive = false;
addTearDown(() async {
  if (mouseActive) await mouse.removePointer();
});
await mouse.addPointer(location: Offset.zero);
mouseActive = true;
final chartCenter = tester.getCenter(_chartRenderFinder());
await mouse.moveTo(chartCenter);
await tester.pump();

expect(renderBox.debugCrosshairAxisLabelCacheEntryCount, greaterThan(0));
expect(renderBox.debugCrosshairTextScaler.scale(10), 15);
expect(renderBox.debugCrosshairTextDirection, TextDirection.rtl);
expect(renderBox.debugCrosshairLocale, const Locale('ar'));
expect(renderBox.debugCrosshairDevicePixelRatio, 2);
final missesBeforeEnvironmentChange =
    renderBox.debugCrosshairAxisLabelCacheMissCount;
```

Remove the pointer before changing inherited values so the repaint cannot
immediately rebuild entries:

```dart
await mouse.removePointer();
mouseActive = false;
await tester.pump();

await pumpChart(
  textScaler: TextScaler.noScaling,
  textDirection: TextDirection.ltr,
  locale: const Locale('en', 'ZA'),
  devicePixelRatio: 1,
);
renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());

expect(renderBox.debugCrosshairTextScaler, TextScaler.noScaling);
expect(renderBox.debugCrosshairTextDirection, TextDirection.ltr);
expect(renderBox.debugCrosshairLocale, const Locale('en', 'ZA'));
expect(renderBox.debugCrosshairDevicePixelRatio, 1);
expect(renderBox.debugCrosshairAxisLabelCacheEntryCount, 0);

final reenteredMouse = await tester.createGesture(
  kind: PointerDeviceKind.mouse,
);
var reenteredMouseActive = false;
addTearDown(() async {
  if (reenteredMouseActive) await reenteredMouse.removePointer();
});
await reenteredMouse.addPointer(location: Offset.zero);
reenteredMouseActive = true;
await reenteredMouse.moveTo(tester.getCenter(_chartRenderFinder()));
await tester.pump();
expect(renderBox.debugCrosshairAxisLabelCacheEntryCount, greaterThan(0));
expect(
  renderBox.debugCrosshairAxisLabelCacheMissCount,
  greaterThan(missesBeforeEnvironmentChange),
);
await reenteredMouse.removePointer();
reenteredMouseActive = false;
```

The stable clearing assertion is made only while no cursor is active. The
subsequent pointer re-entry separately proves layouts are rebuilt under the new
environment; do not expect zero entries after an active-cursor repump.

- [ ] **Step 2: Run the widget test to verify failure**

Run the exact named test:

```powershell
flutter test test/widgets/braven_chart_plus_interaction_test.dart --plain-name "crosshair label cache follows inherited rendering environment"
```

Expected: compilation fails because the debug environment/cache getters do not
exist.

- [ ] **Step 3: Capture inherited values in `BravenChartPlus`**

Add state fields:

```dart
TextScaler _textScaler = TextScaler.noScaling;
Locale? _locale;
double _devicePixelRatio = 1;
```

In `didChangeDependencies()` resolve:

```dart
final nextMediaQuery = MediaQuery.maybeOf(context);
final nextTextScaler = nextMediaQuery?.textScaler ?? TextScaler.noScaling;
final nextTextScale = nextTextScaler.scale(1);
final nextLocale = Localizations.maybeLocaleOf(context);
final nextDevicePixelRatio =
    nextMediaQuery?.devicePixelRatio ?? View.of(context).devicePixelRatio;
```

Include all four new/effective values in the dependency-change comparison and
assignment. Pass `textScaler`, `locale`, and `devicePixelRatio` into
`_ChartRenderWidget`; add matching fields, constructor arguments, creation
arguments, and update setters.

- [ ] **Step 4: Upgrade the already-wired render-box environment**

Keep the cache ownership, renderer call, structural invalidation, disposal, and
current ownership comment added in Task 4. Do not add a second cache or a second
dispose call. Add only the inherited environment state:

```dart
TextScaler _textScaler = TextScaler.noScaling;
Locale? _locale;
double _devicePixelRatio = 1;
```

Add setters that compare, clear, repaint, and update semantics:

```dart
void setTextScaler(TextScaler value) {
  if (_textScaler == value) return;
  _textScaler = value;
  _crosshairAxisLabelLayoutCache.clear();
  markNeedsPaint();
  markNeedsSemanticsUpdate();
}

void setLocale(Locale? value) {
  if (_locale == value) return;
  _locale = value;
  _crosshairAxisLabelLayoutCache.clear();
  markNeedsPaint();
  markNeedsSemanticsUpdate();
}

void setDevicePixelRatio(double value) {
  if (_devicePixelRatio == value) return;
  _devicePixelRatio = value;
  _crosshairAxisLabelLayoutCache.clear();
  markNeedsPaint();
}
```

Replace Task 4's temporary environment getter body with inherited values. The
existing `_crosshairRenderer.paint` call continues to consume this getter; do
not rewire the caller:

```dart
CrosshairAxisLabelLayoutEnvironment
get _crosshairAxisLabelLayoutEnvironment =>
    CrosshairAxisLabelLayoutEnvironment(
      textDirection: _textDirection,
      locale: _locale,
      textScaler: _textScaler,
      devicePixelRatio: _devicePixelRatio,
    );
```

Expose these exact `@visibleForTesting` read-only debug getters:

```dart
int get debugCrosshairAxisLabelCacheEntryCount =>
    _crosshairAxisLabelLayoutCache.debugEntryCount;
int get debugCrosshairAxisLabelCacheHitCount =>
    _crosshairAxisLabelLayoutCache.debugHitCount;
int get debugCrosshairAxisLabelCacheMissCount =>
    _crosshairAxisLabelLayoutCache.debugMissCount;
int get debugCrosshairAxisLabelCacheDisposedPainterCount =>
    _crosshairAxisLabelLayoutCache.debugDisposedPainterCount;
TextScaler get debugCrosshairTextScaler => _textScaler;
TextDirection get debugCrosshairTextDirection => _textDirection;
Locale? get debugCrosshairLocale => _locale;
double get debugCrosshairDevicePixelRatio => _devicePixelRatio;
```

In `_ChartRenderWidget.createRenderObject` and `updateRenderObject`, supply
both the existing scalar (`textScaleFactor: textScaler.scale(1)`) and the new
`textScaler`, `locale`, and `devicePixelRatio` values. The scalar remains for
existing tooltip behavior; the full scaler drives the already-wired crosshair
environment.

- [ ] **Step 5: Run widget and focused renderer tests**

Run:

```powershell
dart format lib/src/braven_chart_plus.dart lib/src/rendering/chart_render_box.dart test/widgets/braven_chart_plus_interaction_test.dart
flutter test test/widgets/braven_chart_plus_interaction_test.dart --plain-name "crosshair label cache follows inherited rendering environment"
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
flutter analyze --no-pub lib
```

Expected: all commands pass; the cache clears on inherited-environment change
and repopulates on the next crosshair paint, and analysis reports no issues.

- [ ] **Step 6: Commit**

```powershell
git add lib/src/braven_chart_plus.dart lib/src/rendering/chart_render_box.dart test/widgets/braven_chart_plus_interaction_test.dart
git commit -m "perf: scope crosshair label cache to each chart"
```

### Task 6: Complete successful-route verification and evidence

**Files:**
- Modify:
  `docs/superpowers/specs/2026-07-26-crosshair-axis-label-layout-cache-design.md`
- Update:
  `F:\Repositories\_braven_charts_register\items\BC-0019-crosshair-label-cache.md`

- [ ] **Step 1: Run the complete focused suite**

```powershell
flutter test test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart test/widgets/braven_chart_plus_x_axis_config_test.dart
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
flutter analyze --no-pub lib
```

Expected: all tests pass, the benchmark passes all three gates, and analysis
reports no issues.

- [ ] **Step 2: Run proportional package verification**

```powershell
flutter test test/unit/rendering test/widgets/braven_chart_plus_x_axis_config_test.dart
```

Expected: all selected rendering and widget tests pass.

- [ ] **Step 3: Record exact evidence**

Append a “Measured outcome” section to the design spec containing:

- both baseline runs from Task 1;
- both paired decision runs from Task 3;
- every trial's median and p95 plus final uncached/cached unchanged decision
  p95;
- absolute and percentage saving;
- uncached/cached changing p95 and regression;
- non-gating multi-axis and environment-key median/p95 values and their
  distinct-label/miss/capacity assertions;
- focused and proportional test counts; and
- analyzer result.

Update `BC-0019` checkboxes, evidence, residual risks, and next action with the
same values. Do not describe the item as complete until every acceptance
criterion has matching evidence.

- [ ] **Step 4: Validate and refresh the register**

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' validate
& 'F:\Repositories\_braven_charts_register\register.ps1' refresh
```

Expected: validation passes and generated `CURRENT.md` refreshes.

- [ ] **Step 5: Commit repository evidence**

```powershell
git add docs/superpowers/specs/2026-07-26-crosshair-axis-label-layout-cache-design.md
git commit -m "docs: record crosshair label cache evidence"
```

### Task 7: Gate-failure route

Execute this task instead of Tasks 4–6 when Task 3 fails any approved gate.

**Files:**
- Delete:
  `lib/src/rendering/modules/crosshair_axis_label_layout_cache.dart`
- Delete:
  `test/unit/rendering/modules/crosshair_axis_label_layout_cache_test.dart`
- Modify:
  `test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart`
- Modify: `lib/src/rendering/chart_render_box.dart`
- Modify:
  `docs/superpowers/specs/2026-07-26-crosshair-axis-label-layout-cache-design.md`
- Update:
  `F:\Repositories\_braven_charts_register\items\BC-0019-crosshair-label-cache.md`

- [ ] **Step 1: Remove the production prototype**

Delete the cache implementation and its unit tests. Keep the benchmark as a
test-only comparison by moving the minimal bounded candidate implementation
into the benchmark file under private names.

- [ ] **Step 2: Replace stale render-box comments**

Remove the four obsolete X/Y painter and last-text comment blocks from
`ChartRenderBox`. Add:

```dart
// Crosshair axis-label layout remains intentionally uncached. BC-0019's
// focused benchmark did not meet the approved p95 benefit and regression
// gates; see the committed design evidence.
```

- [ ] **Step 3: Verify the no-cache route**

```powershell
dart format lib/src/rendering/chart_render_box.dart test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
flutter analyze --no-pub lib
```

Expected: renderer tests pass and analysis reports no issues.

- [ ] **Step 4: Record the rejected optimization evidence**

Add exact benchmark values and the failed gate to the design spec. Mark the
register acceptance item for measurement complete, record caching as rejected,
and close BC-0019 with no production cache. Retain the changing-label benchmark
so future engine/framework changes can be re-evaluated from evidence.

- [ ] **Step 5: Validate the register**

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' validate
& 'F:\Repositories\_braven_charts_register\register.ps1' refresh
```

Expected: validation passes.

- [ ] **Step 6: Commit the no-cache result**

```powershell
git add -A
git commit -m "perf: retire unjustified crosshair label cache debt"
```
