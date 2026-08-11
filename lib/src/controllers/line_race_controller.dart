import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/chart_data_point.dart';
import '../models/line_race.dart';

/// Deterministic state machine for a frame-clock-driven line race.
///
/// The controller is the only playback clock. Its snapshot is composed into
/// ordinary line series, so paths, frontier markers, and last-visible callouts
/// always describe the same instant.
final class LineRaceController extends ChangeNotifier {
  LineRaceController({required LineRaceConfig config}) : _config = config {
    _validate(config);
    _settleTransition();
  }

  LineRaceConfig _config;
  int _frameIndex = 0;
  int _transitionFromFrameIndex = 0;
  double _frameTransitionProgress = 1;
  bool _playing = false;
  double _speed = 1;

  LineRaceConfig get config => _config;
  int get frameIndex => _frameIndex;
  bool get isPlaying => _playing;
  double get speed => _speed;
  double get frameTransitionProgress => _frameTransitionProgress;
  LineRaceFrame get currentFrame => _config.frames[_frameIndex];
  double get progress {
    if (_config.frames.length <= 1) return 1;
    final transitioning =
        _frameTransitionProgress < 1 &&
        _transitionFromFrameIndex != _frameIndex;
    final frameProgress = transitioning
        ? _transitionFromFrameIndex + _frameTransitionProgress
        : _frameIndex.toDouble();
    return frameProgress / (_config.frames.length - 1);
  }

  double get xMinimum => _config.frames.first.x;
  double get xMaximum => _config.frames.last.x;

  Duration get effectiveDuration => Duration(
    microseconds: math.max(
      1,
      (_config.durationPerFrame.inMicroseconds / _speed).round(),
    ),
  );

  LineRaceSnapshot get snapshot {
    final transitioning =
        _frameTransitionProgress < 1 &&
        _transitionFromFrameIndex != _frameIndex;
    final settledThrough = transitioning
        ? _transitionFromFrameIndex
        : _frameIndex;
    final points = <String, List<ChartDataPoint>>{};

    for (final series in _config.series) {
      final projected = <ChartDataPoint>[];
      var observed = false;
      for (var index = 0; index <= settledThrough; index++) {
        final frame = _config.frames[index];
        final value = frame.values[series.id];
        if (value != null) {
          projected.add(ChartDataPoint(x: frame.x, y: value));
          observed = true;
        } else if (observed) {
          projected.add(ChartDataPoint(x: frame.x, y: double.nan));
        }
      }

      if (transitioning) {
        final from = _config.frames[_transitionFromFrameIndex];
        final to = currentFrame;
        final fromValue = from.values[series.id];
        final toValue = to.values[series.id];
        if (fromValue != null && toValue != null) {
          projected.add(
            ChartDataPoint(
              x: _lerp(from.x, to.x, _frameTransitionProgress),
              y: _lerp(fromValue, toValue, _frameTransitionProgress),
            ),
          );
        }
      }
      points[series.id] = List<ChartDataPoint>.unmodifiable(projected);
    }

    final fromFrame = _config.frames[_transitionFromFrameIndex];
    return LineRaceSnapshot(
      frame: currentFrame,
      progress: progress,
      frontierX: transitioning
          ? _lerp(fromFrame.x, currentFrame.x, _frameTransitionProgress)
          : currentFrame.x,
      pointsBySeries: Map<String, List<ChartDataPoint>>.unmodifiable(points),
    );
  }

  static double _lerp(double from, double to, double progress) =>
      from + (to - from) * progress;

  void replaceConfig(LineRaceConfig config, {bool preserveFrame = false}) {
    _validate(config);
    final previousId = preserveFrame && _config.frames.isNotEmpty
        ? currentFrame.id
        : null;
    _config = config;
    _frameIndex = previousId == null
        ? 0
        : math.max(
            0,
            config.frames.indexWhere((frame) => frame.id == previousId),
          );
    _playing = false;
    _settleTransition();
    notifyListeners();
  }

  void play() {
    if (_playing || _config.frames.length < 2) return;
    if (_frameIndex == _config.frames.length - 1) {
      _frameIndex = 0;
      _settleTransition();
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
    final previousFrameIndex = _frameIndex;
    if (_frameIndex < _config.frames.length - 1) {
      _frameIndex++;
      if (_playing) {
        _transitionFromFrameIndex = previousFrameIndex;
        _frameTransitionProgress = 0;
      } else {
        _settleTransition();
      }
    } else if (_config.loop) {
      _frameIndex = 0;
      _settleTransition();
    } else {
      pause();
      return false;
    }
    notifyListeners();
    return true;
  }

  bool previous() {
    if (_frameIndex == 0) return false;
    _frameIndex--;
    _playing = false;
    _settleTransition();
    notifyListeners();
    return true;
  }

  void seekToFrame(int index) {
    final next = index.clamp(0, _config.frames.length - 1);
    final changed = next != _frameIndex || _playing;
    if (!changed) return;
    _frameIndex = next;
    _playing = false;
    _settleTransition();
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

  /// Updates the interpolated frontier on the active frame clock.
  void updateTransitionProgress(double progress) {
    final next = progress.clamp(0.0, 1.0);
    if (next == _frameTransitionProgress) return;
    _frameTransitionProgress = next;
    notifyListeners();
  }

  void completeTransition() {
    if (_frameTransitionProgress == 1) return;
    _frameTransitionProgress = 1;
    notifyListeners();
  }

  void _settleTransition() {
    _transitionFromFrameIndex = _frameIndex;
    _frameTransitionProgress = 1;
  }

  static void _validate(LineRaceConfig config) {
    if (config.series.isEmpty) {
      throw ArgumentError.value(config.series, 'series', 'must not be empty');
    }
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
    final seriesIds = <String>{};
    for (final series in config.series) {
      if (series.id.isEmpty || !seriesIds.add(series.id)) {
        throw ArgumentError.value(
          series.id,
          'series.id',
          'must be non-empty and unique',
        );
      }
      if (series.name.isEmpty) {
        throw ArgumentError.value(
          series.name,
          'series.name',
          'must be non-empty',
        );
      }
    }
    final frameIds = <String>{};
    double? previousX;
    for (final frame in config.frames) {
      if (frame.id.isEmpty || !frameIds.add(frame.id)) {
        throw ArgumentError.value(
          frame.id,
          'frame.id',
          'must be non-empty and unique',
        );
      }
      if (frame.label.isEmpty) {
        throw ArgumentError.value(
          frame.label,
          'frame.label',
          'must be non-empty',
        );
      }
      if (!frame.x.isFinite || (previousX != null && frame.x <= previousX)) {
        throw ArgumentError.value(
          frame.x,
          'frame.x',
          'must be finite and strictly increasing',
        );
      }
      previousX = frame.x;
      for (final entry in frame.values.entries) {
        if (!seriesIds.contains(entry.key)) {
          throw ArgumentError.value(
            entry.key,
            'frame.values',
            'unknown series',
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
