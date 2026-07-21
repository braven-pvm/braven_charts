// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import 'options_panel.dart';

typedef ShowcaseValueGenerator<T> = T Function(int seed);
typedef ShowcaseValueApplier<T> = void Function(T value);

/// Non-generic UI contract for deterministic showcase randomizers.
abstract interface class ShowcaseRandomizerHandle implements Listenable {
  int get minimumSeed;
  int get maximumSeed;
  int get seed;
  set seed(int value);

  int? get appliedSeed;
  int get minimumIntervalSeconds;
  int get maximumIntervalSeconds;
  int get intervalSeconds;
  bool get isPlaying;
  bool get hasGeneratedValue;

  void setIntervalSeconds(int value);
  void generateCurrent();
  void generateNext();
  void togglePlayback();
  void pause();
  void clear();
}

/// Owns deterministic generation and safe timed playback for a showcase page.
///
/// Chart-family code supplies only a pure seeded generator and an adapter that
/// applies the generated value to its real editable state.
class ShowcaseRandomizerController<T> extends ChangeNotifier
    implements ShowcaseRandomizerHandle {
  ShowcaseRandomizerController({
    required ShowcaseValueGenerator<T> generate,
    required ShowcaseValueApplier<T> apply,
    int initialSeed = 47,
    int initialIntervalSeconds = 3,
    this.minimumSeed = 0,
    this.maximumSeed = 999,
    this.minimumIntervalSeconds = 2,
    this.maximumIntervalSeconds = 8,
  }) : _generate = generate,
       _apply = apply,
       _seed = initialSeed,
       _intervalSeconds = initialIntervalSeconds {
    assert(minimumSeed <= maximumSeed);
    assert(initialSeed >= minimumSeed && initialSeed <= maximumSeed);
    assert(minimumIntervalSeconds <= maximumIntervalSeconds);
    assert(
      initialIntervalSeconds >= minimumIntervalSeconds &&
          initialIntervalSeconds <= maximumIntervalSeconds,
    );
  }

  final ShowcaseValueGenerator<T> _generate;
  final ShowcaseValueApplier<T> _apply;
  @override
  final int minimumSeed;
  @override
  final int maximumSeed;
  @override
  final int minimumIntervalSeconds;
  @override
  final int maximumIntervalSeconds;

  Timer? _timer;
  int _seed;
  int _intervalSeconds;
  int? _appliedSeed;
  T? _currentValue;
  bool _isPlaying = false;

  @override
  int get seed => _seed;

  @override
  set seed(int value) {
    final next = value.clamp(minimumSeed, maximumSeed);
    if (next == _seed) return;
    _seed = next;
    notifyListeners();
  }

  @override
  int? get appliedSeed => _appliedSeed;

  @override
  int get intervalSeconds => _intervalSeconds;

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get hasGeneratedValue => _currentValue != null;

  T? get currentValue => _currentValue;

  @override
  void setIntervalSeconds(int value) {
    final next = value.clamp(minimumIntervalSeconds, maximumIntervalSeconds);
    if (next == _intervalSeconds) return;
    _intervalSeconds = next;
    if (_isPlaying) _scheduleTimer();
    notifyListeners();
  }

  @override
  void generateCurrent() => _generateAndApply(_seed);

  @override
  void generateNext() {
    _seed = _seed >= maximumSeed ? minimumSeed : _seed + 1;
    _generateAndApply(_seed);
  }

  @override
  void togglePlayback() => _isPlaying ? pause() : _play();

  void _play() {
    if (_isPlaying) return;
    _isPlaying = true;
    generateNext();
    _scheduleTimer();
    notifyListeners();
  }

  @override
  void pause() {
    _timer?.cancel();
    _timer = null;
    if (!_isPlaying) return;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void clear() {
    _timer?.cancel();
    _timer = null;
    final changed = _isPlaying || _currentValue != null || _appliedSeed != null;
    _isPlaying = false;
    _currentValue = null;
    _appliedSeed = null;
    if (changed) notifyListeners();
  }

  void _scheduleTimer() {
    _timer?.cancel();
    if (!_isPlaying) return;
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
      generateNext();
    });
  }

  void _generateAndApply(int generatedSeed) {
    final value = _generate(generatedSeed);
    _currentValue = value;
    _appliedSeed = generatedSeed;
    _apply(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// Standard inspector controls for a [ShowcaseRandomizerHandle].
class PropertyRandomizerSection extends StatelessWidget
    implements ShowcaseInspectorEntry {
  const PropertyRandomizerSection({
    super.key,
    required this.controller,
    this.keyPrefix = 'showcase-randomizer',
    this.initiallyExpanded = true,
  });

  final ShowcaseRandomizerHandle controller;
  final String keyPrefix;
  final bool initiallyExpanded;

  @override
  ShowcasePropertyMetadata
  get inspectorMetadata => const ShowcasePropertyMetadata(
    label: 'Property randomizer',
    description:
        'Generates reproducible chart data and supported property combinations, then optionally advances them on a timer.',
    aliases: <String>[
      'seed',
      'generate data',
      'random config',
      'play sequence',
      'pause',
      'stress test',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => OptionSection(
        title: inspectorMetadata.label,
        description: inspectorMetadata.description,
        aliases: inspectorMetadata.aliases,
        icon: Icons.auto_awesome,
        initiallyExpanded: initiallyExpanded,
        children: [
          IntSliderOption(
            key: ValueKey('$keyPrefix-seed'),
            label: 'Seed',
            value: controller.seed,
            min: controller.minimumSeed,
            max: controller.maximumSeed,
            aliases: const <String>['reproduce', 'deterministic'],
            onChanged: (value) => controller.seed = value,
          ),
          IntSliderOption(
            key: ValueKey('$keyPrefix-playback-interval'),
            label: 'Playback interval',
            value: controller.intervalSeconds,
            min: controller.minimumIntervalSeconds,
            max: controller.maximumIntervalSeconds,
            suffix: 's',
            aliases: const <String>['timer', 'speed', 'delay'],
            onChanged: controller.setIntervalSeconds,
          ),
          const InfoBox(
            message:
                'The same seed reproduces the same chart. Playback advances one seed at a time and can be paused for inspection.',
          ),
          const SizedBox(height: 8),
          ActionButton(
            key: ValueKey('$keyPrefix-generate'),
            label: 'Generate from seed',
            description:
                'Applies the current seed to the chart data and every property supported by this page.',
            icon: Icons.casino_outlined,
            isPrimary: true,
            onPressed: controller.generateCurrent,
          ),
          const SizedBox(height: 8),
          ActionButton(
            key: ValueKey('$keyPrefix-playback-toggle'),
            label: controller.isPlaying
                ? 'Pause random sequence'
                : 'Play random sequence',
            description:
                'Starts or pauses timed seed progression without discarding the chart currently on screen.',
            icon: controller.isPlaying
                ? Icons.pause_outlined
                : Icons.play_arrow_outlined,
            onPressed: controller.togglePlayback,
          ),
          if (controller.appliedSeed != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.isPlaying
                  ? 'Playing seed ${controller.appliedSeed}'
                  : 'Inspecting seed ${controller.appliedSeed}',
              key: ValueKey('$keyPrefix-status'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact page-header actions backed by the same randomizer controller.
class ShowcaseRandomizerActions extends StatelessWidget {
  const ShowcaseRandomizerActions({
    super.key,
    required this.controller,
    this.keyPrefix = 'showcase-randomizer',
  });

  final ShowcaseRandomizerHandle controller;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: ValueKey('$keyPrefix-next'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: controller.generateNext,
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: const Text('Randomize all'),
          ),
          OutlinedButton.icon(
            key: ValueKey('$keyPrefix-playback-header'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: controller.togglePlayback,
            icon: Icon(
              controller.isPlaying
                  ? Icons.pause_outlined
                  : Icons.play_arrow_outlined,
              size: 18,
            ),
            label: Text(
              controller.isPlaying ? 'Pause sequence' : 'Play sequence',
            ),
          ),
        ],
      ),
    );
  }
}
