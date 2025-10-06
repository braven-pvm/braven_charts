/// Tests for theme versioning.
library;

import 'package:braven_charts/src/theming/utilities/theme_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeVersion Construction', () {
    test('creates version with major, minor, patch', () {
      const version = ThemeVersion(1, 2, 3);
      expect(version.major, equals(1));
      expect(version.minor, equals(2));
      expect(version.patch, equals(3));
    });

    test('allows zero values', () {
      const version = ThemeVersion(0, 0, 0);
      expect(version.major, equals(0));
      expect(version.minor, equals(0));
      expect(version.patch, equals(0));
    });

    test('allows large values', () {
      const version = ThemeVersion(100, 200, 300);
      expect(version.major, equals(100));
      expect(version.minor, equals(200));
      expect(version.patch, equals(300));
    });
  });

  group('ThemeVersion.fromString', () {
    test('parses valid version string', () {
      final version = ThemeVersion.fromString('1.0.0');
      expect(version, isNotNull);
      expect(version!.major, equals(1));
      expect(version.minor, equals(0));
      expect(version.patch, equals(0));
    });

    test('parses version with non-zero components', () {
      final version = ThemeVersion.fromString('1.2.3');
      expect(version, isNotNull);
      expect(version!.major, equals(1));
      expect(version.minor, equals(2));
      expect(version.patch, equals(3));
    });

    test('parses version with large numbers', () {
      final version = ThemeVersion.fromString('100.200.300');
      expect(version, isNotNull);
      expect(version!.major, equals(100));
      expect(version.minor, equals(200));
      expect(version.patch, equals(300));
    });

    test('returns null for null input', () {
      expect(ThemeVersion.fromString(null), isNull);
    });

    test('returns null for empty string', () {
      expect(ThemeVersion.fromString(''), isNull);
    });

    test('returns null for missing patch', () {
      expect(ThemeVersion.fromString('1.0'), isNull);
    });

    test('returns null for missing minor and patch', () {
      expect(ThemeVersion.fromString('1'), isNull);
    });

    test('returns null for too many components', () {
      expect(ThemeVersion.fromString('1.0.0.0'), isNull);
    });

    test('returns null for non-numeric major', () {
      expect(ThemeVersion.fromString('a.0.0'), isNull);
    });

    test('returns null for non-numeric minor', () {
      expect(ThemeVersion.fromString('1.b.0'), isNull);
    });

    test('returns null for non-numeric patch', () {
      expect(ThemeVersion.fromString('1.0.c'), isNull);
    });

    test('returns null for negative major', () {
      expect(ThemeVersion.fromString('-1.0.0'), isNull);
    });

    test('returns null for negative minor', () {
      expect(ThemeVersion.fromString('1.-2.0'), isNull);
    });

    test('returns null for negative patch', () {
      expect(ThemeVersion.fromString('1.0.-3'), isNull);
    });

    test('parses integer-like decimals (1.5 becomes 1)', () {
      // int.tryParse('5') succeeds, so '1.5.0' parses as ThemeVersion(1, 5, 0)
      final version = ThemeVersion.fromString('1.5.0');
      expect(version, isNotNull);
      expect(version!.major, equals(1));
      expect(version.minor, equals(5));
      expect(version.patch, equals(0));
    });

    test('handles leading/trailing spaces via int.tryParse behavior', () {
      // int.tryParse trims spaces, so ' 1.0.0' parses successfully
      final version = ThemeVersion.fromString(' 1.0.0');
      expect(version, isNotNull);
      expect(version!.major, equals(1));
      expect(version.minor, equals(0));
      expect(version.patch, equals(0));
    });

    test('returns null for true decimal values', () {
      // int.tryParse('5.5') fails, so this will return null
      expect(ThemeVersion.fromString('1.5.5.0'), isNull);
    });
  });

  group('ThemeVersion.toString', () {
    test('formats as major.minor.patch', () {
      expect(const ThemeVersion(1, 0, 0).toString(), equals('1.0.0'));
      expect(const ThemeVersion(1, 2, 3).toString(), equals('1.2.3'));
    });

    test('handles zero values', () {
      expect(const ThemeVersion(0, 0, 0).toString(), equals('0.0.0'));
    });

    test('handles large values', () {
      expect(const ThemeVersion(100, 200, 300).toString(), equals('100.200.300'));
    });

    test('round-trips with fromString', () {
      const testVersions = [
        ThemeVersion(1, 0, 0),
        ThemeVersion(1, 2, 3),
        ThemeVersion(0, 0, 0),
        ThemeVersion(100, 200, 300),
      ];

      for (final version in testVersions) {
        final string = version.toString();
        final parsed = ThemeVersion.fromString(string);
        expect(parsed, equals(version), reason: 'Failed for $string');
      }
    });
  });

  group('ThemeVersion.isCompatible', () {
    test('same version is compatible', () {
      const v1 = ThemeVersion(1, 0, 0);
      const v2 = ThemeVersion(1, 0, 0);
      expect(v1.isCompatible(v2), isTrue);
      expect(v2.isCompatible(v1), isTrue);
    });

    test('same major with different minor is compatible', () {
      const v1_0 = ThemeVersion(1, 0, 0);
      const v1_1 = ThemeVersion(1, 1, 0);
      expect(v1_0.isCompatible(v1_1), isTrue);
      expect(v1_1.isCompatible(v1_0), isTrue);
    });

    test('same major with different patch is compatible', () {
      const v1_0_0 = ThemeVersion(1, 0, 0);
      const v1_0_1 = ThemeVersion(1, 0, 1);
      expect(v1_0_0.isCompatible(v1_0_1), isTrue);
      expect(v1_0_1.isCompatible(v1_0_0), isTrue);
    });

    test('same major with different minor and patch is compatible', () {
      const v1_0_0 = ThemeVersion(1, 0, 0);
      const v1_2_3 = ThemeVersion(1, 2, 3);
      expect(v1_0_0.isCompatible(v1_2_3), isTrue);
      expect(v1_2_3.isCompatible(v1_0_0), isTrue);
    });

    test('different major version is incompatible', () {
      const v1 = ThemeVersion(1, 0, 0);
      const v2 = ThemeVersion(2, 0, 0);
      expect(v1.isCompatible(v2), isFalse);
      expect(v2.isCompatible(v1), isFalse);
    });

    test('different major with same minor is incompatible', () {
      const v1_1 = ThemeVersion(1, 1, 0);
      const v2_1 = ThemeVersion(2, 1, 0);
      expect(v1_1.isCompatible(v2_1), isFalse);
      expect(v2_1.isCompatible(v1_1), isFalse);
    });

    test('different major with same minor and patch is incompatible', () {
      const v1_1_1 = ThemeVersion(1, 1, 1);
      const v2_1_1 = ThemeVersion(2, 1, 1);
      expect(v1_1_1.isCompatible(v2_1_1), isFalse);
      expect(v2_1_1.isCompatible(v1_1_1), isFalse);
    });

    test('v1 is compatible with all v1.x.x', () {
      const v1 = ThemeVersion(1, 0, 0);
      const testVersions = [
        ThemeVersion(1, 0, 0),
        ThemeVersion(1, 1, 0),
        ThemeVersion(1, 0, 1),
        ThemeVersion(1, 5, 10),
        ThemeVersion(1, 100, 200),
      ];

      for (final version in testVersions) {
        expect(v1.isCompatible(version), isTrue, reason: 'v1.0.0 should be compatible with $version');
        expect(version.isCompatible(v1), isTrue, reason: '$version should be compatible with v1.0.0');
      }
    });

    test('v2 is incompatible with all v1.x.x', () {
      const v2 = ThemeVersion(2, 0, 0);
      const testVersions = [
        ThemeVersion(1, 0, 0),
        ThemeVersion(1, 1, 0),
        ThemeVersion(1, 0, 1),
        ThemeVersion(1, 5, 10),
        ThemeVersion(1, 100, 200),
      ];

      for (final version in testVersions) {
        expect(v2.isCompatible(version), isFalse, reason: 'v2.0.0 should be incompatible with $version');
        expect(version.isCompatible(v2), isFalse, reason: '$version should be incompatible with v2.0.0');
      }
    });
  });

  group('ThemeVersion Equality', () {
    test('same version is equal', () {
      const v1 = ThemeVersion(1, 2, 3);
      const v2 = ThemeVersion(1, 2, 3);
      expect(v1, equals(v2));
      expect(v1 == v2, isTrue);
    });

    test('different major is not equal', () {
      const v1 = ThemeVersion(1, 0, 0);
      const v2 = ThemeVersion(2, 0, 0);
      expect(v1, isNot(equals(v2)));
      expect(v1 == v2, isFalse);
    });

    test('different minor is not equal', () {
      const v1 = ThemeVersion(1, 0, 0);
      const v2 = ThemeVersion(1, 1, 0);
      expect(v1, isNot(equals(v2)));
      expect(v1 == v2, isFalse);
    });

    test('different patch is not equal', () {
      const v1 = ThemeVersion(1, 0, 0);
      const v2 = ThemeVersion(1, 0, 1);
      expect(v1, isNot(equals(v2)));
      expect(v1 == v2, isFalse);
    });

    test('hashCode is consistent with equality', () {
      const v1 = ThemeVersion(1, 2, 3);
      const v2 = ThemeVersion(1, 2, 3);
      const v3 = ThemeVersion(1, 2, 4);

      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1.hashCode, isNot(equals(v3.hashCode)));
    });
  });

  group('currentVersion Constant', () {
    test('currentVersion is v1.0.0', () {
      expect(currentVersion.major, equals(1));
      expect(currentVersion.minor, equals(0));
      expect(currentVersion.patch, equals(0));
    });

    test('currentVersion toString is 1.0.0', () {
      expect(currentVersion.toString(), equals('1.0.0'));
    });

    test('currentVersion is compatible with v1.x.x', () {
      expect(currentVersion.isCompatible(const ThemeVersion(1, 0, 0)), isTrue);
      expect(currentVersion.isCompatible(const ThemeVersion(1, 1, 0)), isTrue);
      expect(currentVersion.isCompatible(const ThemeVersion(1, 0, 1)), isTrue);
      expect(currentVersion.isCompatible(const ThemeVersion(1, 5, 10)), isTrue);
    });

    test('currentVersion is incompatible with v2.x.x', () {
      expect(currentVersion.isCompatible(const ThemeVersion(2, 0, 0)), isFalse);
      expect(currentVersion.isCompatible(const ThemeVersion(2, 1, 0)), isFalse);
    });
  });
}
