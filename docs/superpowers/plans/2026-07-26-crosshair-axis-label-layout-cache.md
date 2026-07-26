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
  - Five paired trials for unchanged and changing label frames and the
    approved p95 decision gate.
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

- [ ] **Step 1: Write the baseline benchmark**

Create the benchmark with the real paragraph inputs used by crosshair labels:

```dart
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _trialCount = 5;
const _frameCount = 1000;
const _labelsPerFrame = 7;

void main() {
  test('records uncached crosshair axis-label layout p95', () {
    for (var warmup = 0; warmup < 200; warmup++) {
      _layoutUncachedFrame(frame: warmup, changing: false);
    }

    final unchanged = <int>[];
    final changing = <int>[];
    for (var trial = 0; trial < _trialCount; trial++) {
      unchanged.add(_measureUncachedTrial(changing: false));
      changing.add(_measureUncachedTrial(changing: true));
    }

    // ignore: avoid_print
    print(
      'Crosshair axis labels uncached: '
      'unchanged p95 ${_decisionP95(unchanged) / 1000}ms; '
      'changing p95 ${_decisionP95(changing) / 1000}ms',
    );
    expect(unchanged, hasLength(_trialCount));
    expect(changing, hasLength(_trialCount));
  });
}

int _measureUncachedTrial({required bool changing}) {
  final samples = <int>[];
  for (var frame = 0; frame < _frameCount; frame++) {
    final watch = Stopwatch()..start();
    _layoutUncachedFrame(frame: frame, changing: changing);
    watch.stop();
    samples.add(watch.elapsedMicroseconds);
  }
  samples.sort();
  return samples[(samples.length * 0.95).ceil() - 1];
}

void _layoutUncachedFrame({
  required int frame,
  required bool changing,
}) {
  for (var label = 0; label < _labelsPerFrame; label++) {
    final suffix = changing ? frame : 42;
    final text = label == 0
        ? '2026-07-${suffix.toString().padLeft(2, '0')}'
        : '${(suffix * 1.25 + label).toStringAsFixed(2)} unit';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF202124)),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      locale: const Locale('en', 'ZA'),
    )..layout();
    painter.dispose();
  }
}

int _decisionP95(List<int> trialP95s) {
  final sorted = [...trialP95s]..sort();
  return sorted[sorted.length ~/ 2];
}
```

- [ ] **Step 2: Run the baseline twice**

Run:

```powershell
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
```

Expected: both runs pass and print uncached unchanged/changing p95 values.
Record both outputs in the task notes; do not select a favorable run.

- [ ] **Step 3: Commit the baseline**

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

- [ ] **Step 1: Extend the benchmark with paired cached trials**

Import the cache, add `_measureCachedTrial`, and calculate the exact decision:

```dart
import 'package:braven_charts/src/rendering/modules/crosshair_axis_label_layout_cache.dart';

final uncachedUnchanged = <int>[];
final cachedUnchanged = <int>[];
final uncachedChanging = <int>[];
final cachedChanging = <int>[];
for (var trial = 0; trial < _trialCount; trial++) {
  uncachedUnchanged.add(_measureUncachedTrial(changing: false));
  cachedUnchanged.add(_measureCachedTrial(changing: false));
  uncachedChanging.add(_measureUncachedTrial(changing: true));
  cachedChanging.add(_measureCachedTrial(changing: true));
}

final unchangedBaseline = _decisionP95(uncachedUnchanged);
final unchangedCandidate = _decisionP95(cachedUnchanged);
final changingBaseline = _decisionP95(uncachedChanging);
final changingCandidate = _decisionP95(cachedChanging);
final savedMicros = unchangedBaseline - unchangedCandidate;
final savedPercent = savedMicros / unchangedBaseline * 100;
final changingRegression = changingCandidate - changingBaseline;
final changingLimit = math.max(
  changingBaseline * 0.10,
  50,
);

expect(savedPercent, greaterThanOrEqualTo(20));
expect(savedMicros, greaterThanOrEqualTo(100));
expect(changingRegression, lessThanOrEqualTo(changingLimit));
```

Add `dart:math` and this cached measurement path:

```dart
int _measureCachedTrial({required bool changing}) {
  final cache = CrosshairAxisLabelLayoutCache();
  final samples = <int>[];
  for (var frame = 0; frame < _frameCount; frame++) {
    final watch = Stopwatch()..start();
    for (var label = 0; label < _labelsPerFrame; label++) {
      final suffix = changing ? frame : 42;
      final text = label == 0
          ? '2026-07-${suffix.toString().padLeft(2, '0')}'
          : '${(suffix * 1.25 + label).toStringAsFixed(2)} unit';
      cache.layout(
        CrosshairAxisLabelLayoutRequest(
          text: text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF202124)),
          textDirection: TextDirection.ltr,
          locale: const Locale('en', 'ZA'),
          textScaler: TextScaler.noScaling,
          devicePixelRatio: 1,
        ),
      );
    }
    watch.stop();
    samples.add(watch.elapsedMicroseconds);
  }
  cache.dispose();
  samples.sort();
  return samples[(samples.length * 0.95).ceil() - 1];
}
```

Print the four decision values, absolute/percentage saving, and changing
regression before assertions.

- [ ] **Step 2: Run the decision benchmark twice**

Run:

```powershell
dart format test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
flutter test test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart --reporter expanded
```

Expected: the same ship/no-ship decision on both runs. Record both complete
outputs. If decisions differ, increase trial/sample counts equally for both
paths and repeat; do not weaken any threshold.

- [ ] **Step 3: Choose exactly one route**

If both runs pass every assertion, continue with Task 4.

If either stable run fails an assertion, stop Tasks 4–6 and execute Task 7.

- [ ] **Step 4: Commit the decision harness**

```powershell
git add test/benchmarks/rendering/crosshair_axis_label_layout_benchmark_test.dart
git commit -m "test: gate crosshair label layout caching"
```

### Task 4: Integrate cache reuse into all axis-label paths

**Files:**
- Modify: `lib/src/rendering/modules/crosshair_renderer.dart`
- Modify:
  `test/unit/rendering/modules/crosshair_renderer_test.dart`
- Modify:
  `test/unit/rendering/crosshair_renderer_x_axis_test.dart`

- [ ] **Step 1: Update renderer tests to require cache inputs**

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

Add a repeated-paint test that expects the second paint to increase
`debugHitCount`, then change the effective label `TextStyle` and expect a miss.
Keep the existing top, bottom, mirrored, multi-axis, range-boundary, and
transposed assertions unchanged.

Add a rotated-axis regression using otherwise identical `XAxisConfig` values
with `tickLabelRotationDegrees` of `0` and `45`. Assert that crosshair label
paragraph placement remains identical and the second paint can hit the layout
cache, because tick-label rotation does not rotate the crosshair coordinate
label.

- [ ] **Step 2: Run tests to verify the new required arguments fail**

Run:

```powershell
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
```

Expected: compilation fails because `CrosshairRenderer.paint` does not accept
the two cache arguments.

- [ ] **Step 3: Add the renderer helper and required inputs**

Import the cache module and add required `paint` arguments:

```dart
required CrosshairAxisLabelLayoutCache axisLabelLayoutCache,
required CrosshairAxisLabelLayoutEnvironment axisLabelLayoutEnvironment,
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

- [ ] **Step 4: Run focused renderer tests**

Run:

```powershell
dart format lib/src/rendering/modules/crosshair_renderer.dart test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
```

Expected: all renderer tests pass; repeated equivalent paints record hits.

- [ ] **Step 5: Commit**

```powershell
git add lib/src/rendering/modules/crosshair_renderer.dart test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
git commit -m "perf: reuse crosshair axis label layouts"
```

### Task 5: Wire per-chart environment, invalidation, and disposal

**Files:**
- Modify: `lib/src/braven_chart_plus.dart`
- Modify: `lib/src/rendering/chart_render_box.dart`
- Modify: `test/widgets/braven_chart_plus_interaction_test.dart`

- [ ] **Step 1: Write the inherited-environment widget test**

Pump a Cartesian chart inside `MediaQuery`, `Directionality`, and
`Localizations`, move the pointer into the plot to populate axis labels, then
read the `ChartRenderBox` debug values:

```dart
expect(renderBox.debugCrosshairAxisLabelCacheEntryCount, greaterThan(0));
expect(renderBox.debugCrosshairTextScaler.scale(10), 15);
expect(renderBox.debugCrosshairTextDirection, TextDirection.rtl);
expect(renderBox.debugCrosshairLocale, const Locale('ar'));
expect(renderBox.debugCrosshairDevicePixelRatio, 2);
```

Re-pump with scale `1.0`, LTR, `Locale('en', 'ZA')`, and DPR `1.0`. Expect the
environment getters to update and the retained-entry count to be zero before
the next pointer paint repopulates it.

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

- [ ] **Step 4: Own and invalidate the cache in `ChartRenderBox`**

Add:

```dart
final CrosshairAxisLabelLayoutCache _crosshairAxisLabelLayoutCache =
    CrosshairAxisLabelLayoutCache();
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

Clear the cache in existing setters for theme, text direction, X-axis config,
legacy X axis, primary Y-axis config, legacy Y axis, normalization mode,
effective series, maximum axes per side, and axis swap mode.

Pass the owned cache and this live environment into `_crosshairRenderer.paint`:

```dart
axisLabelLayoutCache: _crosshairAxisLabelLayoutCache,
axisLabelLayoutEnvironment: CrosshairAxisLabelLayoutEnvironment(
  textDirection: _textDirection,
  locale: _locale,
  textScaler: _textScaler,
  devicePixelRatio: _devicePixelRatio,
),
```

Expose `@visibleForTesting` read-only debug getters for cache entry/hit/miss
counts and the four environment values. Dispose the cache once in
`ChartRenderBox.dispose()`.

Replace the four stale cache-comment blocks near the render-box tracking state
with one current ownership comment on `_crosshairAxisLabelLayoutCache`.

- [ ] **Step 5: Run widget and focused renderer tests**

Run:

```powershell
dart format lib/src/braven_chart_plus.dart lib/src/rendering/chart_render_box.dart test/widgets/braven_chart_plus_interaction_test.dart
flutter test test/widgets/braven_chart_plus_interaction_test.dart --plain-name "crosshair label cache follows inherited rendering environment"
flutter test test/unit/rendering/modules/crosshair_renderer_test.dart test/unit/rendering/crosshair_renderer_x_axis_test.dart
```

Expected: all commands pass; the cache clears on inherited-environment change
and repopulates on the next crosshair paint.

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
- final uncached/cached unchanged p95;
- absolute and percentage saving;
- uncached/cached changing p95 and regression;
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
