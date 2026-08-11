import 'package:flutter/material.dart';

import '../models/line_race.dart';
import 'chart_artifact_diagnostics.dart';

/// Versioned, JSON-safe codec for a portable [LineRaceConfig].
abstract final class LineRaceConfigCodec {
  static const int schemaVersion = 1;

  static ChartArtifactResult<Map<String, Object?>> encode(
    LineRaceConfig config,
  ) {
    try {
      _validate(config);
      return ChartArtifactSuccess(
        value: <String, Object?>{
          'type': 'lineRace',
          'schemaVersion': schemaVersion,
          'series': [
            for (final series in config.series)
              <String, Object?>{
                'id': series.id,
                'name': series.name,
                'color': series.color.toARGB32(),
              },
          ],
          'frames': [
            for (final frame in config.frames)
              <String, Object?>{
                'id': frame.id,
                'label': frame.label,
                'x': frame.x,
                'values': <String, Object?>{
                  for (final entry in frame.values.entries)
                    entry.key: entry.value,
                },
              },
          ],
          'durationPerFrameMs': config.durationPerFrame.inMilliseconds,
          'loop': config.loop,
        },
      );
    } on FormatException catch (error) {
      return _failure(error.message);
    }
  }

  static ChartArtifactResult<LineRaceConfig> decode(Map<String, Object?> json) {
    try {
      if (json['type'] != 'lineRace') {
        throw const FormatException('Expected a lineRace document.');
      }
      if (_integer(json, 'schemaVersion') != schemaVersion) {
        throw const FormatException('Unsupported line-race schema version.');
      }
      final series = <LineRaceSeries>[
        for (final raw in _list(json, 'series'))
          () {
            final item = _map(raw, 'series');
            return LineRaceSeries(
              id: _string(item, 'id'),
              name: _string(item, 'name'),
              color: Color(_integer(item, 'color')),
            );
          }(),
      ];
      final frames = <LineRaceFrame>[
        for (final raw in _list(json, 'frames'))
          () {
            final item = _map(raw, 'frame');
            final values = _map(item['values'], 'values');
            return LineRaceFrame(
              id: _string(item, 'id'),
              label: _string(item, 'label'),
              x: _finiteNumber(item['x'], 'x'),
              values: <String, double>{
                for (final entry in values.entries)
                  entry.key: _finiteNumber(entry.value, entry.key),
              },
            );
          }(),
      ];
      final config = LineRaceConfig(
        series: List<LineRaceSeries>.unmodifiable(series),
        frames: List<LineRaceFrame>.unmodifiable(frames),
        durationPerFrame: Duration(
          milliseconds: _integer(json, 'durationPerFrameMs'),
        ),
        loop: _boolean(json, 'loop'),
      );
      _validate(config);
      return ChartArtifactSuccess(value: config);
    } on Object catch (error) {
      return _failure(error is FormatException ? error.message : '$error');
    }
  }

  static void _validate(LineRaceConfig config) {
    if (config.series.isEmpty) {
      throw const FormatException('Line-race series must not be empty.');
    }
    if (config.frames.isEmpty) {
      throw const FormatException('Line-race frames must not be empty.');
    }
    if (config.durationPerFrame.inMicroseconds <= 0) {
      throw const FormatException('Line-race duration must be positive.');
    }
    final seriesIds = <String>{};
    for (final series in config.series) {
      if (series.id.isEmpty || !seriesIds.add(series.id)) {
        throw FormatException(
          'Line-race series ID "${series.id}" must be non-empty and unique.',
        );
      }
      if (series.name.isEmpty) {
        throw const FormatException(
          'Line-race series names must be non-empty.',
        );
      }
    }
    final frameIds = <String>{};
    double? previousX;
    for (final frame in config.frames) {
      if (frame.id.isEmpty || !frameIds.add(frame.id)) {
        throw FormatException(
          'Line-race frame ID "${frame.id}" must be non-empty and unique.',
        );
      }
      if (frame.label.isEmpty) {
        throw const FormatException(
          'Line-race frame labels must be non-empty.',
        );
      }
      if (!frame.x.isFinite || (previousX != null && frame.x <= previousX)) {
        throw const FormatException(
          'Line-race frame X values must be finite and strictly increasing.',
        );
      }
      previousX = frame.x;
      for (final entry in frame.values.entries) {
        if (!seriesIds.contains(entry.key)) {
          throw FormatException('Unknown line-race series ID "${entry.key}".');
        }
        if (!entry.value.isFinite) {
          throw FormatException(
            'Line-race value for "${entry.key}" must be finite.',
          );
        }
      }
    }
  }

  static ChartArtifactFailure<T> _failure<T>(String message) =>
      ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: message,
        ),
      );
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is! Map) throw FormatException('$name must be an object.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Object?> _list(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! List) throw FormatException('$key must be an array.');
  return value.cast<Object?>();
}

String _string(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! num || value.toInt() != value) {
    throw FormatException('$key must be an integer.');
  }
  return value.toInt();
}

bool _boolean(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

double _finiteNumber(Object? value, String name) {
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('$name must be a finite number.');
  }
  return value.toDouble();
}
