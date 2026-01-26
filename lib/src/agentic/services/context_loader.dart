// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

class ContextConfig {
  ContextConfig({
    required this.athleteName,
    this.ftp,
    this.lthr,
    this.preferredColors,
  });

  final String athleteName;
  final int? ftp;
  final int? lthr;
  final Map<String, Color>? preferredColors;

  factory ContextConfig.fromMap(Map<String, dynamic> data) {
    final rawColors = data['preferredColors'] ?? data['preferred_colors'];
    return ContextConfig(
      athleteName:
          (data['athleteName'] ?? data['athlete_name'] ?? '').toString(),
      ftp: _toIntOrNull(data['ftp']),
      lthr: _toIntOrNull(data['lthr']),
      preferredColors: _parseColorMap(rawColors),
    );
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  static Map<String, Color>? _parseColorMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final result = <String, Color>{};
    value.forEach((key, raw) {
      final color = _parseColor(raw);
      if (color != null) {
        result[key.toString()] = color;
      }
    });

    return result.isEmpty ? null : result;
  }

  static Color? _parseColor(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Color) {
      return value;
    }
    if (value is int) {
      return Color(value);
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    String hex = text.toLowerCase();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }

    if (hex.length == 6) {
      hex = 'ff$hex';
    }

    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) {
      return null;
    }

    return Color(intValue);
  }
}

class ContextLoader {
  Future<ContextConfig?> loadContext(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    final data = _parseContent(filePath, content);
    if (data == null) {
      return null;
    }

    return ContextConfig.fromMap(data);
  }

  Map<String, dynamic>? _parseContent(String path, String content) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.json')) {
      return _parseJson(content);
    }
    if (lowerPath.endsWith('.yaml') || lowerPath.endsWith('.yml')) {
      return _parseYaml(content);
    }

    try {
      return _parseJson(content);
    } catch (_) {
      return _parseYaml(content);
    }
  }

  Map<String, dynamic> _parseJson(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Context config must be a JSON object');
    }
    return decoded;
  }

  Map<String, dynamic> _parseYaml(String content) {
    final lines = content.split('\n');
    final root = <String, dynamic>{};
    String? currentMapKey;

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty || line.trim().startsWith('#')) {
        continue;
      }

      final indent = rawLine.length - rawLine.trimLeft().length;
      final parts = line.split(':');
      if (parts.length < 2) {
        continue;
      }

      final key = parts.first.trim();
      final valueText = parts.sublist(1).join(':').trim();
      final value = _parseYamlValue(valueText);

      if (indent == 0) {
        if (valueText.isEmpty) {
          root[key] = <String, dynamic>{};
          currentMapKey = key;
        } else {
          root[key] = value;
          currentMapKey = null;
        }
      } else if (currentMapKey != null) {
        final nested = root[currentMapKey];
        if (nested is Map<String, dynamic>) {
          nested[key] = value;
        }
      }
    }

    return root;
  }

  dynamic _parseYamlValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.toLowerCase() == 'null') {
      return null;
    }

    final intValue = int.tryParse(trimmed);
    if (intValue != null) {
      return intValue;
    }

    final doubleValue = double.tryParse(trimmed);
    if (doubleValue != null) {
      return doubleValue;
    }

    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith('\'') && trimmed.endsWith('\''))) {
      return trimmed.substring(1, trimmed.length - 1);
    }

    return trimmed;
  }
}
