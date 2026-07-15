import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A recursively JSON-safe value used at the artifact boundary.
sealed class JsonValue {
  const JsonValue();

  /// Converts a decoded JSON value into a constrained [JsonValue].
  ///
  /// Unsupported runtime values and non-string map keys are rejected with a
  /// path-bearing [FormatException]. Non-finite doubles are intentionally not
  /// accepted here; chart numeric fields use their own reversible encoding.
  factory JsonValue.fromJson(Object? value, {String path = r'$'}) {
    if (value == null) return const JsonNullValue();
    if (value is bool) return JsonBoolValue(value);
    if (value is String) return JsonStringValue(value);
    if (value is num) return JsonNumberValue(value, path: path);
    if (value is List<Object?>) {
      return JsonArrayValue([
        for (var index = 0; index < value.length; index++)
          JsonValue.fromJson(value[index], path: '$path[$index]'),
      ]);
    }
    if (value is Map) {
      final result = <String, JsonValue>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw FormatException('Non-string JSON object key at $path');
        }
        result[key] = JsonValue.fromJson(
          entry.value,
          path: _childPath(path, key),
        );
      }
      return JsonObjectValue(result);
    }
    throw FormatException(
      'Unsupported JSON value ${value.runtimeType} at $path',
    );
  }

  Object? toJson();

  static String _childPath(String parent, String key) {
    final simpleKey = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    return simpleKey.hasMatch(key)
        ? '$parent.$key'
        : '$parent[${jsonEncode(key)}]';
  }
}

@immutable
final class JsonNullValue extends JsonValue {
  const JsonNullValue();

  @override
  Object? toJson() => null;
}

@immutable
final class JsonBoolValue extends JsonValue {
  const JsonBoolValue(this.value);

  final bool value;

  @override
  Object toJson() => value;
}

@immutable
final class JsonStringValue extends JsonValue {
  const JsonStringValue(this.value);

  final String value;

  @override
  Object toJson() => value;
}

@immutable
final class JsonNumberValue extends JsonValue {
  JsonNumberValue(this.value, {String path = r'$'}) {
    if (value is double && !(value as double).isFinite) {
      throw FormatException('Non-finite JSON number at $path');
    }
  }

  final num value;

  @override
  Object toJson() => value;
}

@immutable
final class JsonArrayValue extends JsonValue {
  JsonArrayValue(Iterable<JsonValue> values)
    : values = List.unmodifiable(values);

  final List<JsonValue> values;

  @override
  Object toJson() => values.map((value) => value.toJson()).toList();
}

@immutable
final class JsonObjectValue extends JsonValue {
  JsonObjectValue(Map<String, JsonValue> values)
    : values = Map.unmodifiable(values);

  final Map<String, JsonValue> values;

  @override
  Object toJson() => {
    for (final entry in values.entries) entry.key: entry.value.toJson(),
  };
}

/// Encodes JSON with recursively sorted object keys and stable finite numbers.
String canonicalJsonEncode(Object? value) {
  final buffer = StringBuffer();
  _writeCanonicalJson(buffer, value is JsonValue ? value.toJson() : value);
  return buffer.toString();
}

void _writeCanonicalJson(StringBuffer buffer, Object? value) {
  switch (value) {
    case null:
      buffer.write('null');
    case bool():
      buffer.write(value ? 'true' : 'false');
    case String():
      buffer.write(jsonEncode(value));
    case int():
      buffer.write(value);
    case double():
      if (!value.isFinite) {
        throw const FormatException(
          'Canonical JSON cannot encode non-finite numbers',
        );
      }
      if (value == 0) {
        buffer.write('0');
      } else {
        final encoded = value.toString();
        buffer.write(
          encoded.endsWith('.0')
              ? encoded.substring(0, encoded.length - 2)
              : encoded,
        );
      }
    case List():
      buffer.write('[');
      for (var index = 0; index < value.length; index++) {
        if (index > 0) buffer.write(',');
        _writeCanonicalJson(buffer, value[index]);
      }
      buffer.write(']');
    case Map():
      final entries = value.entries.toList()
        ..sort((left, right) {
          final leftKey = left.key;
          final rightKey = right.key;
          if (leftKey is! String || rightKey is! String) {
            throw const FormatException(
              'Canonical JSON object keys must be strings',
            );
          }
          return leftKey.compareTo(rightKey);
        });
      buffer.write('{');
      for (var index = 0; index < entries.length; index++) {
        if (index > 0) buffer.write(',');
        final key = entries[index].key;
        if (key is! String) {
          throw const FormatException(
            'Canonical JSON object keys must be strings',
          );
        }
        buffer
          ..write(jsonEncode(key))
          ..write(':');
        _writeCanonicalJson(buffer, entries[index].value);
      }
      buffer.write('}');
    default:
      throw FormatException(
        'Canonical JSON cannot encode ${value.runtimeType}',
      );
  }
}
