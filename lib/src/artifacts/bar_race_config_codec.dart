import 'package:flutter/material.dart';

import '../models/bar_race.dart';
import 'chart_artifact_diagnostics.dart';

/// Versioned, JSON-safe codec for a portable [BarRaceConfig].
abstract final class BarRaceConfigCodec {
  static const int schemaVersion = 2;

  static ChartArtifactResult<Map<String, Object?>> encode(
    BarRaceConfig config,
  ) {
    try {
      _validate(config);
      return ChartArtifactSuccess(
        value: <String, Object?>{
          'type': 'barRace',
          'schemaVersion': schemaVersion,
          'categories': [
            for (final category in config.categories) _encodeCategory(category),
          ],
          'frames': [for (final frame in config.frames) _encodeFrame(frame)],
          'topCount': config.topCount,
          'durationPerFrameMs': config.durationPerFrame.inMilliseconds,
          'axisRange': config.axisRange.name,
          'sort': config.sort.name,
          'loop': config.loop,
          'showPeriod': config.showPeriod,
          'showTotal': config.showTotal,
          'periodStyle': _encodePeriodStyle(config.periodStyle),
          'periodFormat': _encodePeriodFormat(config.periodFormat),
          'valueFormat': _encodeValueFormat(config.valueFormat),
          'totalFormat': _encodeValueFormat(config.totalFormat),
        },
      );
    } on FormatException catch (error) {
      return _failure(error.message);
    }
  }

  static ChartArtifactResult<BarRaceConfig> decode(Map<String, Object?> json) {
    try {
      if (json['type'] != 'barRace') {
        throw const FormatException('Expected a barRace document.');
      }
      final version = _integer(json, 'schemaVersion');
      if (version != 1 && version != schemaVersion) {
        throw const FormatException('Unsupported bar-race schema version.');
      }
      final categories = <BarRaceCategory>[
        for (final value in _list(json, 'categories'))
          () {
            final item = _map(value, 'category');
            return BarRaceCategory(
              id: _string(item, 'id'),
              label: _string(item, 'label'),
              color: Color(_integer(item, 'color')),
            );
          }(),
      ];
      final frames = <BarRaceFrame>[
        for (final value in _list(json, 'frames'))
          () {
            final item = _map(value, 'frame');
            final rawValues = _requiredMap(item, 'values');
            return BarRaceFrame(
              id: _string(item, 'id'),
              label: _string(item, 'label'),
              values: <String, double>{
                for (final entry in rawValues.entries)
                  entry.key: _finiteNumber(entry.value, entry.key),
              },
              timestamp: item['timestamp'] == null
                  ? null
                  : _dateTime(item, 'timestamp'),
              total: item['total'] == null
                  ? null
                  : _finiteNumber(item['total'], 'total'),
            );
          }(),
      ];
      final axisRange = BarRaceAxisRange.values.byName(
        _string(json, 'axisRange'),
      );
      final sort = BarRaceSort.values.byName(_string(json, 'sort'));
      final config = BarRaceConfig(
        categories: List.unmodifiable(categories),
        frames: List.unmodifiable(frames),
        topCount: _integer(json, 'topCount'),
        durationPerFrame: Duration(
          milliseconds: _integer(json, 'durationPerFrameMs'),
        ),
        axisRange: axisRange,
        sort: sort,
        loop: _boolean(json, 'loop'),
        showPeriod: _boolean(json, 'showPeriod'),
        showTotal: _boolean(json, 'showTotal'),
        periodStyle: json['periodStyle'] == null
            ? const BarRacePeriodStyle()
            : _decodePeriodStyle(_requiredMap(json, 'periodStyle')),
        periodFormat: json['periodFormat'] == null
            ? const BarRacePeriodFormat()
            : _decodePeriodFormat(_requiredMap(json, 'periodFormat')),
        valueFormat: json['valueFormat'] == null
            ? const BarRaceValueFormat()
            : _decodeValueFormat(_requiredMap(json, 'valueFormat')),
        totalFormat: json['totalFormat'] == null
            ? const BarRaceValueFormat(
                notation: BarRaceValueNotation.compact,
                decimalPlaces: 1,
                pattern: '{value} total',
              )
            : _decodeValueFormat(_requiredMap(json, 'totalFormat')),
      );
      _validate(config);
      return ChartArtifactSuccess(value: config);
    } on Object catch (error) {
      return _failure(error is FormatException ? error.message : '$error');
    }
  }

  static Map<String, Object?> _encodeCategory(BarRaceCategory category) =>
      <String, Object?>{
        'id': category.id,
        'label': category.label,
        'color': category.color.toARGB32(),
      };

  static Map<String, Object?> _encodeFrame(BarRaceFrame frame) =>
      <String, Object?>{
        'id': frame.id,
        'label': frame.label,
        'values': <String, Object?>{
          for (final entry in frame.values.entries) entry.key: entry.value,
        },
        if (frame.timestamp != null)
          'timestamp': frame.timestamp!.toIso8601String(),
        if (frame.total != null) 'total': frame.total,
      };

  static Map<String, Object?> _encodePeriodFormat(BarRacePeriodFormat format) =>
      <String, Object?>{'pattern': format.pattern};

  static BarRacePeriodFormat _decodePeriodFormat(Map<String, Object?> json) =>
      BarRacePeriodFormat(pattern: _string(json, 'pattern'));

  static Map<String, Object?> _encodeValueFormat(BarRaceValueFormat format) =>
      <String, Object?>{
        'pattern': format.pattern,
        'notation': format.notation.name,
        'decimalPlaces': format.decimalPlaces,
        'useGrouping': format.useGrouping,
        'trimTrailingZeros': format.trimTrailingZeros,
        'scale': format.scale,
      };

  static BarRaceValueFormat _decodeValueFormat(Map<String, Object?> json) =>
      BarRaceValueFormat(
        pattern: _string(json, 'pattern'),
        notation: BarRaceValueNotation.values.byName(_string(json, 'notation')),
        decimalPlaces: _integer(json, 'decimalPlaces'),
        useGrouping: _boolean(json, 'useGrouping'),
        trimTrailingZeros: _boolean(json, 'trimTrailingZeros'),
        scale: _finiteNumber(json['scale'], 'scale'),
      );

  static Map<String, Object?> _encodePeriodStyle(BarRacePeriodStyle style) =>
      <String, Object?>{
        'position': style.position.name,
        'fontSize': style.fontSize,
        if (style.color != null) 'color': style.color!.toARGB32(),
        'fontWeightIndex': FontWeight.values.indexOf(style.fontWeight),
        'opacity': style.opacity,
        'inset': style.inset,
        'supportingTextSize': style.supportingTextSize,
      };

  static BarRacePeriodStyle _decodePeriodStyle(Map<String, Object?> json) {
    final weightIndex = _integer(json, 'fontWeightIndex');
    if (weightIndex < 0 || weightIndex >= FontWeight.values.length) {
      throw const FormatException(
        'fontWeightIndex is outside the valid range.',
      );
    }
    return BarRacePeriodStyle(
      position: BarRacePeriodPosition.values.byName(_string(json, 'position')),
      fontSize: _finiteNumber(json['fontSize'], 'fontSize'),
      color: json['color'] == null ? null : Color(_integer(json, 'color')),
      fontWeight: FontWeight.values[weightIndex],
      opacity: _finiteNumber(json['opacity'], 'opacity'),
      inset: _finiteNumber(json['inset'], 'inset'),
      supportingTextSize: _finiteNumber(
        json['supportingTextSize'],
        'supportingTextSize',
      ),
    );
  }

  static void _validate(BarRaceConfig config) {
    if (config.categories.isEmpty) {
      throw const FormatException('Bar-race categories must not be empty.');
    }
    if (config.frames.isEmpty) {
      throw const FormatException('Bar-race frames must not be empty.');
    }
    if (config.topCount <= 0 || config.topCount > config.categories.length) {
      throw const FormatException(
        'Bar-race topCount must fit the category collection.',
      );
    }
    if (config.durationPerFrame.inMicroseconds <= 0) {
      throw const FormatException('Bar-race duration must be positive.');
    }
    final periodStyle = config.periodStyle;
    if (!periodStyle.fontSize.isFinite || periodStyle.fontSize <= 0) {
      throw const FormatException('Period font size must be positive.');
    }
    if (!periodStyle.opacity.isFinite ||
        periodStyle.opacity < 0 ||
        periodStyle.opacity > 1) {
      throw const FormatException('Period opacity must be between 0 and 1.');
    }
    if (!periodStyle.inset.isFinite || periodStyle.inset < 0) {
      throw const FormatException('Period inset must not be negative.');
    }
    if (!periodStyle.supportingTextSize.isFinite ||
        periodStyle.supportingTextSize <= 0) {
      throw const FormatException(
        'Period supporting text size must be positive.',
      );
    }
    if (config.periodFormat.pattern.isEmpty) {
      throw const FormatException('Period format pattern must not be empty.');
    }
    for (final entry in <String, BarRaceValueFormat>{
      'Value': config.valueFormat,
      'Total': config.totalFormat,
    }.entries) {
      final format = entry.value;
      if (format.pattern.isEmpty || !format.pattern.contains('{value}')) {
        throw FormatException(
          '${entry.key} format pattern must contain {value}.',
        );
      }
      if (format.decimalPlaces < 0 || format.decimalPlaces > 12) {
        throw FormatException(
          '${entry.key} format decimalPlaces must be between 0 and 12.',
        );
      }
      if (!format.scale.isFinite || format.scale <= 0) {
        throw FormatException('${entry.key} format scale must be positive.');
      }
    }
    final categoryIds = <String>{};
    for (final category in config.categories) {
      if (!categoryIds.add(category.id)) {
        throw FormatException('Duplicate category ID "${category.id}".');
      }
    }
    final frameIds = <String>{};
    for (final frame in config.frames) {
      if (!frameIds.add(frame.id)) {
        throw FormatException('Duplicate frame ID "${frame.id}".');
      }
      for (final entry in frame.values.entries) {
        if (!categoryIds.contains(entry.key)) {
          throw FormatException('Unknown category ID "${entry.key}".');
        }
        if (!entry.value.isFinite) {
          throw FormatException('Value for "${entry.key}" must be finite.');
        }
      }
      if (frame.total case final total? when !total.isFinite) {
        throw const FormatException('Frame total must be finite.');
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

Map<String, Object?> _requiredMap(Map<String, Object?> source, String key) =>
    _map(source[key], key);

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

DateTime _dateTime(Map<String, Object?> source, String key) {
  final raw = _string(source, key);
  final value = DateTime.tryParse(raw);
  if (value == null) throw FormatException('$key must be an ISO-8601 date.');
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
