import 'json_value.dart';

Map<String, Object?> jsonValueMap(Map<String, JsonValue> values) => {
  for (final entry in values.entries) entry.key: entry.value.toJson(),
};

Map<String, JsonValue> readOptionalJsonValueMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) return const {};
  final object = JsonValue.fromJson(value, path: r'$.' + key);
  if (object is! JsonObjectValue) {
    throw FormatException('$key must be a JSON object');
  }
  return object.values;
}

JsonObjectValue? readOptionalJsonObject(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final object = JsonValue.fromJson(value, path: r'$.' + key);
  if (object is! JsonObjectValue) {
    throw FormatException('$key must be a JSON object');
  }
  return object;
}

Map<String, Object?> readRequiredMap(Map<String, Object?> json, String key) =>
    readStringMap(json[key], key);

Map<String, Object?> readStringMap(Object? value, String label) {
  if (value is! Map) throw FormatException('$label must be an object');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$label contains a non-string key');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> readRequiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be an array');
  return List<Object?>.from(value);
}

List<Object?> readOptionalList(Map<String, Object?> json, String key) {
  if (json[key] == null) return const [];
  return readRequiredList(json, key);
}

String readRequiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}

String? readOptionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}

int readRequiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer');
  return value;
}

int? readOptionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) throw FormatException('$key must be an integer');
  return value;
}

bool readRequiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean');
  return value;
}

bool? readOptionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! bool) throw FormatException('$key must be a boolean');
  return value;
}

double readRequiredDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number');
  }
  return value.toDouble();
}

double? readOptionalDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number');
  }
  return value.toDouble();
}

DateTime readRequiredDateTime(Map<String, Object?> json, String key) {
  final value = readRequiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key must be an ISO-8601 date');
  return parsed.toUtc();
}

DateTime? readOptionalDateTime(Map<String, Object?> json, String key) =>
    json[key] == null ? null : readRequiredDateTime(json, key);

Set<String> readOptionalStringSet(Map<String, Object?> json, String key) =>
    Set.unmodifiable(readOptionalStringList(json, key));

List<String> readOptionalStringList(Map<String, Object?> json, String key) {
  if (json[key] == null) return const [];
  return readRequiredList(json, key).map((value) {
    if (value is! String) throw FormatException('$key must contain strings');
    return value;
  }).toList();
}
