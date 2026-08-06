import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/bar_race.dart';

/// Deterministic state machine for a frame-clock-driven bar race.
final class BarRaceController extends ChangeNotifier {
  BarRaceController({required BarRaceConfig config}) : _config = config {
    _validate(config);
    _rebuildCaches();
    _settleAxisTransition();
  }

  static const int _maximumCachedFrames = 32;

  BarRaceConfig _config;
  int _frameIndex = 0;
  bool _playing = false;
  double _speed = 1;
  final LinkedHashMap<int, List<BarRaceRankedValue>> _rankedFrameCache =
      LinkedHashMap<int, List<BarRaceRankedValue>>();
  double _fixedAxisMaximum = 1;
  List<double> _dynamicAxisMaximums = const [1];
  List<double> _continuousAxisMaximums = const [1];
  int _transitionFromFrameIndex = 0;
  double _axisTransitionFrom = 1;
  double _axisTransitionTo = 1;
  double _axisTransitionProgress = 1;
  double _frameTransitionProgress = 1;

  BarRaceConfig get config => _config;
  int get frameIndex => _frameIndex;
  bool get isPlaying => _playing;
  double get speed => _speed;
  BarRaceFrame get currentFrame => _config.frames[_frameIndex];
  double get frameTransitionProgress => _frameTransitionProgress;
  double get progress => _config.frames.length <= 1
      ? 1
      : _frameIndex / (_config.frames.length - 1);

  Duration get effectiveDuration => Duration(
    microseconds: math.max(
      1,
      (_config.durationPerFrame.inMicroseconds / _speed).round(),
    ),
  );

  List<BarRaceRankedValue> get rankedValues =>
      _rankedValuesForFrame(_frameIndex);

  /// Values and rank positions interpolated on the active race clock.
  ///
  /// This is the presentation source for renderers that need values, rank
  /// swaps, axes, and period labels to remain on one clock. Categories leaving
  /// the visible top-N move just beyond the final rank while fading towards
  /// zero; entering categories start from that same boundary.
  List<BarRaceRankedValue> get effectiveRankedValues {
    if (_frameTransitionProgress >= 1 ||
        _transitionFromFrameIndex == _frameIndex) {
      return rankedValues;
    }

    final progress = _frameTransitionProgress;
    final from = _rankedValuesForFrame(_transitionFromFrameIndex);
    final to = rankedValues;
    final fromById = {for (final value in from) value.category.id: value};
    final toById = {for (final value in to) value.category.id: value};
    final boundaryRank = _config.topCount.toDouble();
    final effective = <BarRaceRankedValue>[];

    for (final target in to) {
      final source = fromById[target.category.id];
      effective.add(
        BarRaceRankedValue(
          category: target.category,
          value: _lerp(source?.value ?? 0, target.value, progress),
          rank: _lerp(source?.rank ?? boundaryRank, target.rank, progress),
        ),
      );
    }
    for (final source in from) {
      if (toById.containsKey(source.category.id)) continue;
      effective.add(
        BarRaceRankedValue(
          category: source.category,
          value: _lerp(source.value, 0, progress),
          rank: _lerp(source.rank, boundaryRank, progress),
        ),
      );
    }
    effective.sort((a, b) {
      final rank = a.rank.compareTo(b.rank);
      return rank == 0 ? a.category.id.compareTo(b.category.id) : rank;
    });
    return List<BarRaceRankedValue>.unmodifiable(effective);
  }

  List<BarRaceRankedValue> _rankedValuesForFrame(int frameIndex) {
    final cached = _rankedFrameCache.remove(frameIndex);
    if (cached != null) {
      _rankedFrameCache[frameIndex] = cached;
      return cached;
    }
    final frame = _config.frames[frameIndex];
    final values = [
      for (final category in _config.categories)
        BarRaceRankedValue(
          category: category,
          value: frame.values[category.id] ?? 0,
        ),
    ];
    values.sort((a, b) {
      final comparison = a.value.compareTo(b.value);
      if (comparison == 0) return a.category.id.compareTo(b.category.id);
      return _config.sort == BarRaceSort.descending ? -comparison : comparison;
    });
    final ranked = List<BarRaceRankedValue>.unmodifiable([
      for (final entry in values.take(_config.topCount).indexed)
        BarRaceRankedValue(
          category: entry.$2.category,
          value: entry.$2.value,
          rank: entry.$1.toDouble(),
        ),
    ]);
    _rankedFrameCache[frameIndex] = ranked;
    if (_rankedFrameCache.length > _maximumCachedFrames) {
      _rankedFrameCache.remove(_rankedFrameCache.keys.first);
    }
    return ranked;
  }

  static double _lerp(double from, double to, double progress) =>
      from + (to - from) * progress;

  double get effectiveAxisMaximum {
    if (_config.axisRange == BarRaceAxisRange.fixed) {
      return _fixedAxisMaximum;
    }
    return _axisTransitionFrom +
        (_axisTransitionTo - _axisTransitionFrom) * _axisTransitionProgress;
  }

  /// The optional total interpolated on the same clock as the bar values.
  ///
  /// This prevents a prominent aggregate from snapping to the next frame
  /// while the bars are still travelling towards it.
  double? get effectiveTotal {
    final to = currentFrame.total;
    if (to == null) return null;
    final from = _config.frames[_transitionFromFrameIndex].total;
    if (from == null || _frameTransitionProgress >= 1) return to;
    return from + (to - from) * _frameTransitionProgress;
  }

  void replaceConfig(BarRaceConfig config, {bool preserveFrame = false}) {
    _validate(config);
    final previousId = preserveFrame && _config.frames.isNotEmpty
        ? currentFrame.id
        : null;
    _config = config;
    _rebuildCaches();
    _frameIndex = previousId == null
        ? 0
        : math.max(
            0,
            config.frames.indexWhere((frame) => frame.id == previousId),
          );
    _settleAxisTransition();
    notifyListeners();
  }

  void _rebuildCaches() {
    _rankedFrameCache.clear();
    var runningMaximum = 0.0;
    _dynamicAxisMaximums = List<double>.unmodifiable([
      for (final frame in _config.frames)
        _niceAxisMaximum(
          runningMaximum = frame.values.values.fold<double>(
            runningMaximum,
            math.max,
          ),
        ),
    ]);
    var continuousMaximum = _dynamicAxisMaximums.first;
    _continuousAxisMaximums = List<double>.unmodifiable([
      for (final frame in _config.frames)
        continuousMaximum = math.max(
          continuousMaximum,
          frame.values.values.fold<double>(0, math.max) / 0.9,
        ),
    ]);
    _fixedAxisMaximum = _dynamicAxisMaximums.last;
  }

  /// Returns a stable human-readable ceiling instead of rescaling to every
  /// small change in the current leader.
  ///
  /// The 1/1.2/1.5/2/2.5/3/4/5/6/8/10 progression provides useful headroom
  /// for common race magnitudes while keeping forward playback monotonic.
  static double _niceAxisMaximum(double value) {
    if (!value.isFinite || value <= 0) return 1;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
    final normalized = value / magnitude;
    const ceilings = <double>[1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];
    final factor = ceilings.firstWhere(
      (candidate) => normalized <= candidate,
      orElse: () => 10,
    );
    return factor * magnitude;
  }

  void play() {
    if (_playing || _config.frames.length < 2) return;
    if (_frameIndex == _config.frames.length - 1 && !_config.loop) {
      _frameIndex = 0;
      _settleAxisTransition();
    }
    _playing = true;
    notifyListeners();
  }

  void pause() {
    if (!_playing) return;
    _playing = false;
    notifyListeners();
  }

  void toggle() => _playing ? pause() : play();

  bool next() {
    final previousAxisMaximum = effectiveAxisMaximum;
    final previousFrameIndex = _frameIndex;
    if (_frameIndex < _config.frames.length - 1) {
      _frameIndex++;
    } else if (_config.loop) {
      _frameIndex = 0;
    } else {
      pause();
      return false;
    }
    if (_playing) {
      _beginAxisTransition(previousAxisMaximum, previousFrameIndex);
    } else {
      _settleAxisTransition();
    }
    notifyListeners();
    return true;
  }

  bool previous() {
    if (_frameIndex == 0) return false;
    _frameIndex--;
    _settleAxisTransition();
    notifyListeners();
    return true;
  }

  void seekToFrame(int index) {
    final next = index.clamp(0, _config.frames.length - 1);
    if (next == _frameIndex) return;
    _frameIndex = next;
    _settleAxisTransition();
    notifyListeners();
  }

  void seek(double normalizedProgress) {
    final normalized = normalizedProgress.clamp(0.0, 1.0);
    seekToFrame((normalized * (_config.frames.length - 1)).round());
  }

  void setSpeed(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, 'value', 'must be positive and finite');
    }
    if (value == _speed) return;
    _speed = value;
    notifyListeners();
  }

  /// Synchronizes a dynamic axis change with the ticker driving the frame.
  ///
  /// Applications normally do not call this directly; [BarRaceTicker] feeds
  /// it the same normalized frame-clock progress used for race playback.
  void updateAxisTransitionProgress(double progress) {
    final next = progress.clamp(0.0, 1.0);
    if (next == _axisTransitionProgress && next == _frameTransitionProgress) {
      return;
    }
    _frameTransitionProgress = next;
    _axisTransitionProgress = next;
    notifyListeners();
  }

  /// Resolves any in-flight axis change immediately.
  void completeAxisTransition() {
    if (_axisTransitionProgress == 1 && _frameTransitionProgress == 1) return;
    _axisTransitionProgress = 1;
    _frameTransitionProgress = 1;
    notifyListeners();
  }

  void _beginAxisTransition(double from, int fromFrameIndex) {
    _transitionFromFrameIndex = fromFrameIndex;
    _frameTransitionProgress = 0;
    _axisTransitionFrom = from;
    _axisTransitionTo = _axisMaximumForFrame(_frameIndex);
    _axisTransitionProgress = _axisTransitionFrom == _axisTransitionTo ? 1 : 0;
  }

  void _settleAxisTransition() {
    _transitionFromFrameIndex = _frameIndex;
    final target = _axisMaximumForFrame(_frameIndex);
    _axisTransitionFrom = target;
    _axisTransitionTo = target;
    _axisTransitionProgress = 1;
    _frameTransitionProgress = 1;
  }

  double _axisMaximumForFrame(int frameIndex) => switch (_config.axisRange) {
    BarRaceAxisRange.dynamic => _dynamicAxisMaximums[frameIndex],
    BarRaceAxisRange.continuous => _continuousAxisMaximums[frameIndex],
    BarRaceAxisRange.fixed => _fixedAxisMaximum,
  };

  static void _validate(BarRaceConfig config) {
    if (config.frames.isEmpty) {
      throw ArgumentError.value(config.frames, 'frames', 'must not be empty');
    }
    if (config.durationPerFrame.inMicroseconds <= 0) {
      throw ArgumentError.value(
        config.durationPerFrame,
        'durationPerFrame',
        'must be positive',
      );
    }
    final periodStyle = config.periodStyle;
    if (!periodStyle.fontSize.isFinite || periodStyle.fontSize <= 0) {
      throw ArgumentError.value(
        periodStyle.fontSize,
        'periodStyle.fontSize',
        'must be positive and finite',
      );
    }
    if (!periodStyle.opacity.isFinite ||
        periodStyle.opacity < 0 ||
        periodStyle.opacity > 1) {
      throw ArgumentError.value(
        periodStyle.opacity,
        'periodStyle.opacity',
        'must be between 0 and 1',
      );
    }
    if (!periodStyle.inset.isFinite || periodStyle.inset < 0) {
      throw ArgumentError.value(
        periodStyle.inset,
        'periodStyle.inset',
        'must be non-negative and finite',
      );
    }
    if (!periodStyle.supportingTextSize.isFinite ||
        periodStyle.supportingTextSize <= 0) {
      throw ArgumentError.value(
        periodStyle.supportingTextSize,
        'periodStyle.supportingTextSize',
        'must be positive and finite',
      );
    }
    if (config.periodFormat.pattern.isEmpty) {
      throw ArgumentError.value(
        config.periodFormat.pattern,
        'periodFormat.pattern',
        'must not be empty',
      );
    }
    for (final entry in <String, BarRaceValueFormat>{
      'valueFormat': config.valueFormat,
      'totalFormat': config.totalFormat,
    }.entries) {
      final format = entry.value;
      if (!format.pattern.contains('{value}')) {
        throw ArgumentError.value(
          format.pattern,
          '${entry.key}.pattern',
          'must contain {value}',
        );
      }
      if (format.decimalPlaces < 0 || format.decimalPlaces > 12) {
        throw ArgumentError.value(
          format.decimalPlaces,
          '${entry.key}.decimalPlaces',
          'must be between 0 and 12',
        );
      }
      if (!format.scale.isFinite || format.scale <= 0) {
        throw ArgumentError.value(
          format.scale,
          '${entry.key}.scale',
          'must be positive and finite',
        );
      }
    }
    final categoryIds = <String>{};
    for (final category in config.categories) {
      if (!categoryIds.add(category.id)) {
        throw ArgumentError.value(category.id, 'category.id', 'must be unique');
      }
    }
    final frameIds = <String>{};
    for (final frame in config.frames) {
      if (!frameIds.add(frame.id)) {
        throw ArgumentError.value(frame.id, 'frame.id', 'must be unique');
      }
      for (final entry in frame.values.entries) {
        if (!categoryIds.contains(entry.key)) {
          throw ArgumentError.value(
            entry.key,
            'frame.values',
            'unknown category',
          );
        }
        if (!entry.value.isFinite) {
          throw ArgumentError.value(
            entry.value,
            'frame.values',
            'must be finite',
          );
        }
      }
    }
  }
}
