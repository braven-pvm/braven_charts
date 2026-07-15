import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'json_value.dart';

/// Portable schema representation of one chart annotation.
@immutable
class ChartAnnotationDocument {
  ChartAnnotationDocument({
    required this.type,
    required this.id,
    JsonObjectValue? payload,
    Set<String> requiredCapabilities = const {},
    Map<String, JsonValue> extensions = const {},
  }) : payload = payload ?? JsonObjectValue(const {}),
       requiredCapabilities = Set.unmodifiable(requiredCapabilities),
       extensions = Map.unmodifiable(extensions);

  final String type;
  final String id;
  final JsonObjectValue payload;
  final Set<String> requiredCapabilities;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'payload': payload.toJson(),
    if (requiredCapabilities.isNotEmpty)
      'requiredCapabilities': requiredCapabilities.toList()..sort(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartAnnotationDocument.fromJson(Map<String, Object?> json) =>
      ChartAnnotationDocument(
        type: readRequiredString(json, 'type'),
        id: readRequiredString(json, 'id'),
        payload: readOptionalJsonObject(json, 'payload'),
        requiredCapabilities: readOptionalStringSet(
          json,
          'requiredCapabilities',
        ),
        extensions: readOptionalJsonValueMap(json, 'extensions'),
      );
}
