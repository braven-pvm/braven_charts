import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonValue', () {
    test('round-trips nested JSON-safe values', () {
      final value = JsonValue.fromJson({
        'label': 'Power',
        'visible': true,
        'values': [1, 2.5, null],
      });

      expect(value.toJson(), {
        'label': 'Power',
        'visible': true,
        'values': [1, 2.5, null],
      });
    });

    test('rejects unsupported and non-finite metadata with paths', () {
      expect(
        () => JsonValue.fromJson({'nested': Object()}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.nested'),
          ),
        ),
      );
      expect(
        () => JsonValue.fromJson({'value': double.nan}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.value'),
          ),
        ),
      );
    });
  });

  group('canonicalJsonEncode', () {
    test('sorts keys recursively and normalizes negative zero', () {
      final encoded = canonicalJsonEncode({
        'z': -0.0,
        'whole': 1.0,
        'a': {'z': 2, 'a': 1},
      });

      expect(encoded, '{"a":{"a":1,"z":2},"whole":1,"z":0}');
      expect(jsonDecode(encoded), {
        'a': {'a': 1, 'z': 2},
        'whole': 1,
        'z': 0,
      });
    });
  });
}
