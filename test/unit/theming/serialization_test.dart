/// Tests for serialization helpers.
library;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/utilities/serialization_helpers.dart';

void main() {
  group('parseColor', () {
    test('parses valid #AARRGGBB format', () {
      expect(parseColor('#FFFFFFFF'), equals(const Color(0xFFFFFFFF)));
      expect(parseColor('#FF000000'), equals(const Color(0xFF000000)));
      expect(parseColor('#80FF0000'), equals(const Color(0x80FF0000)));
      expect(parseColor('#FF123456'), equals(const Color(0xFF123456)));
    });

    test('handles lowercase hex digits', () {
      expect(parseColor('#ffffffff'), equals(const Color(0xFFFFFFFF)));
      expect(parseColor('#ff123abc'), equals(const Color(0xFF123ABC)));
    });

    test('handles mixed case hex digits', () {
      expect(parseColor('#FfFfFfFf'), equals(const Color(0xFFFFFFFF)));
      expect(parseColor('#fF123AbC'), equals(const Color(0xFF123ABC)));
    });

    test('returns null for null input', () {
      expect(parseColor(null), isNull);
    });

    test('returns null for missing # prefix', () {
      expect(parseColor('FFFFFFFF'), isNull);
      expect(parseColor('FF123456'), isNull);
    });

    test('returns null for wrong length', () {
      expect(parseColor('#FFF'), isNull);      // too short
      expect(parseColor('#FFFFFF'), isNull);   // 6 digits (missing alpha)
      expect(parseColor('#FFFFFFFFF'), isNull); // too long
    });

    test('returns null for invalid hex characters', () {
      expect(parseColor('#GGGGGGGG'), isNull);
      expect(parseColor('#FF12345Z'), isNull);
      expect(parseColor('#FF 12345'), isNull); // space
    });

    test('returns null for empty string', () {
      expect(parseColor(''), isNull);
    });

    test('returns null for just #', () {
      expect(parseColor('#'), isNull);
    });
  });

  group('colorToHex', () {
    test('converts Color to #AARRGGBB format', () {
      expect(colorToHex(const Color(0xFFFFFFFF)), equals('#FFFFFFFF'));
      expect(colorToHex(const Color(0xFF000000)), equals('#FF000000'));
      expect(colorToHex(const Color(0x80FF0000)), equals('#80FF0000'));
      expect(colorToHex(const Color(0xFF123456)), equals('#FF123456'));
    });

    test('produces uppercase hex digits', () {
      expect(colorToHex(const Color(0xFFABCDEF)), equals('#FFABCDEF'));
      expect(colorToHex(const Color(0x12345678)), equals('#12345678'));
    });

    test('pads with leading zeros', () {
      expect(colorToHex(const Color(0x00000000)), equals('#00000000'));
      expect(colorToHex(const Color(0x00000001)), equals('#00000001'));
      expect(colorToHex(const Color(0x01000000)), equals('#01000000'));
    });

    test('round-trips with parseColor', () {
      const testColors = [
        Color(0xFFFFFFFF),
        Color(0xFF000000),
        Color(0x80808080),
        Color(0xFF123456),
        Color(0x00000000),
        Color(0x12345678),
      ];

      for (final color in testColors) {
        final hex = colorToHex(color);
        final parsed = parseColor(hex);
        expect(parsed, equals(color), reason: 'Failed for $hex');
      }
    });
  });

  group('parseEdgeInsets', () {
    test('parses valid EdgeInsets map', () {
      final result = parseEdgeInsets({
        'top': 16,
        'right': 16,
        'bottom': 16,
        'left': 16,
      });
      expect(result, equals(const EdgeInsets.all(16)));
    });

    test('handles double values', () {
      final result = parseEdgeInsets({
        'top': 10.5,
        'right': 20.5,
        'bottom': 10.5,
        'left': 20.5,
      });
      expect(result, equals(const EdgeInsets.symmetric(
        vertical: 10.5,
        horizontal: 20.5,
      )));
    });

    test('handles mixed int and double values', () {
      final result = parseEdgeInsets({
        'top': 10,
        'right': 20.5,
        'bottom': 10,
        'left': 20.5,
      });
      expect(result, equals(const EdgeInsets.fromLTRB(20.5, 10, 20.5, 10)));
    });

    test('handles zero values', () {
      final result = parseEdgeInsets({
        'top': 0,
        'right': 0,
        'bottom': 0,
        'left': 0,
      });
      expect(result, equals(EdgeInsets.zero));
    });

    test('handles asymmetric values', () {
      final result = parseEdgeInsets({
        'top': 1,
        'right': 2,
        'bottom': 3,
        'left': 4,
      });
      expect(result, equals(const EdgeInsets.fromLTRB(4, 1, 2, 3)));
    });

    test('returns null for null input', () {
      expect(parseEdgeInsets(null), isNull);
    });

    test('returns null for missing top', () {
      expect(parseEdgeInsets({
        'right': 16,
        'bottom': 16,
        'left': 16,
      }), isNull);
    });

    test('returns null for missing right', () {
      expect(parseEdgeInsets({
        'top': 16,
        'bottom': 16,
        'left': 16,
      }), isNull);
    });

    test('returns null for missing bottom', () {
      expect(parseEdgeInsets({
        'top': 16,
        'right': 16,
        'left': 16,
      }), isNull);
    });

    test('returns null for missing left', () {
      expect(parseEdgeInsets({
        'top': 16,
        'right': 16,
        'bottom': 16,
      }), isNull);
    });

    test('returns null for non-numeric values', () {
      expect(parseEdgeInsets({
        'top': '16',
        'right': 16,
        'bottom': 16,
        'left': 16,
      }), isNull);
    });

    test('returns null for null values', () {
      expect(parseEdgeInsets({
        'top': null,
        'right': 16,
        'bottom': 16,
        'left': 16,
      }), isNull);
    });

    test('returns null for empty map', () {
      expect(parseEdgeInsets({}), isNull);
    });

    test('ignores extra keys', () {
      final result = parseEdgeInsets({
        'top': 16,
        'right': 16,
        'bottom': 16,
        'left': 16,
        'extra': 'ignored',
      });
      expect(result, equals(const EdgeInsets.all(16)));
    });
  });

  group('edgeInsetsToJson', () {
    test('converts EdgeInsets.all to JSON', () {
      final result = edgeInsetsToJson(const EdgeInsets.all(16));
      expect(result, equals({
        'top': 16.0,
        'right': 16.0,
        'bottom': 16.0,
        'left': 16.0,
      }));
    });

    test('converts EdgeInsets.symmetric to JSON', () {
      final result = edgeInsetsToJson(const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ));
      expect(result, equals({
        'top': 10.0,
        'right': 20.0,
        'bottom': 10.0,
        'left': 20.0,
      }));
    });

    test('converts EdgeInsets.only to JSON', () {
      final result = edgeInsetsToJson(const EdgeInsets.only(
        top: 1,
        right: 2,
        bottom: 3,
        left: 4,
      ));
      expect(result, equals({
        'top': 1.0,
        'right': 2.0,
        'bottom': 3.0,
        'left': 4.0,
      }));
    });

    test('converts EdgeInsets.zero to JSON', () {
      final result = edgeInsetsToJson(EdgeInsets.zero);
      expect(result, equals({
        'top': 0.0,
        'right': 0.0,
        'bottom': 0.0,
        'left': 0.0,
      }));
    });

    test('handles decimal values', () {
      final result = edgeInsetsToJson(const EdgeInsets.fromLTRB(
        10.5,
        20.5,
        30.5,
        40.5,
      ));
      expect(result, equals({
        'top': 20.5,
        'right': 30.5,
        'bottom': 40.5,
        'left': 10.5,
      }));
    });

    test('round-trips with parseEdgeInsets', () {
      const testInsets = [
        EdgeInsets.all(16),
        EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        EdgeInsets.only(top: 1, right: 2, bottom: 3, left: 4),
        EdgeInsets.zero,
        EdgeInsets.fromLTRB(10.5, 20.5, 30.5, 40.5),
      ];

      for (final insets in testInsets) {
        final json = edgeInsetsToJson(insets);
        final parsed = parseEdgeInsets(json);
        expect(parsed, equals(insets), reason: 'Failed for $insets');
      }
    });
  });

  group('Null Safety Integration', () {
    test('parseColor handles null gracefully', () {
      String? nullString;
      expect(parseColor(nullString), isNull);
    });

    test('parseEdgeInsets handles null gracefully', () {
      Map<String, dynamic>? nullMap;
      expect(parseEdgeInsets(nullMap), isNull);
    });

    test('all parsers return null for invalid input', () {
      expect(parseColor('invalid'), isNull);
      expect(parseEdgeInsets({'invalid': 'data'}), isNull);
    });
  });
}
