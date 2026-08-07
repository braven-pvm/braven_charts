@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/dependency_floor_support.dart';

void main() {
  group('parseDependencyFloorVersion', () {
    test('reads plain, prerelease and build-metadata versions', () {
      expect(parseDependencyFloorVersion('3.8.0')?.text, '3.8.0');
      expect(parseDependencyFloorVersion(' 1.27.0 ')?.text, '1.27.0');
      expect(parseDependencyFloorVersion('2.0.0+3')?.text, '2.0.0');
      expect(parseDependencyFloorVersion('2.0.0-beta.1')?.isPrerelease, isTrue);
      expect(parseDependencyFloorVersion('3.8.0')?.isPrerelease, isFalse);
    });

    test('rejects values that are not three-part versions', () {
      expect(parseDependencyFloorVersion('3.8'), isNull);
      expect(parseDependencyFloorVersion('stable'), isNull);
      expect(parseDependencyFloorVersion(''), isNull);
    });
  });

  group('lowestAllowedVersion', () {
    test('reads caret, range and bare constraints', () {
      expect(lowestAllowedVersion('^3.7.2')?.text, '3.7.2');
      expect(lowestAllowedVersion('>=3.38.0')?.text, '3.38.0');
      expect(lowestAllowedVersion('">=3.6.0 <4.0.0"')?.text, '3.6.0');
      expect(lowestAllowedVersion('3.35.0')?.text, '3.35.0');
    });

    test('treats absent or unbounded constraints as imposing no floor', () {
      expect(lowestAllowedVersion(null), isNull);
      expect(lowestAllowedVersion('any'), isNull);
      expect(lowestAllowedVersion(''), isNull);
    });
  });

  group('constraintAdmits', () {
    test('caret ranges stop at the next breaking version', () {
      expect(constraintAdmits('^3.7.2', '3.7.2'), isTrue);
      expect(constraintAdmits('^3.7.2', '3.8.0'), isTrue);
      expect(constraintAdmits('^3.7.2', '3.7.1'), isFalse);
      expect(constraintAdmits('^3.7.2', '4.0.0'), isFalse);
    });

    test('caret ranges below 1.0.0 stop at the next minor', () {
      expect(constraintAdmits('^0.4.1', '0.4.9'), isTrue);
      expect(constraintAdmits('^0.4.1', '0.5.0'), isFalse);
    });

    test('explicit ranges honour every bound', () {
      expect(constraintAdmits('>=3.0.0 <4.0.0', '3.9.0'), isTrue);
      expect(constraintAdmits('>=3.0.0 <4.0.0', '4.0.0'), isFalse);
      expect(constraintAdmits('>3.0.0', '3.0.0'), isFalse);
    });

    test('prereleases are never counted as reachable', () {
      // pub will not select a prerelease for an ordinary constraint, so
      // counting one would let the gate pass on a candidate no real consumer
      // receives.
      expect(constraintAdmits('^3.7.2', '3.9.0-beta.1'), isFalse);
    });
  });

  group('reachableFromFloor', () {
    test('a dependency requiring no more than the floor is reachable', () {
      final floor = parseDependencyFloorVersion('3.35.0')!;
      expect(reachableFromFloor('>=3.35.0', floor), isTrue);
      expect(reachableFromFloor('>=3.27.0', floor), isTrue);
      expect(reachableFromFloor(null, floor), isTrue);
    });

    test('a dependency requiring more than the floor is not reachable', () {
      final floor = parseDependencyFloorVersion('3.35.0')!;
      expect(reachableFromFloor('>=3.38.0', floor), isFalse);
    });
  });

  group('directDependencies', () {
    test('maps constraints and leaves nested blocks null', () {
      const pubspec = '''
name: braven_charts
environment:
  sdk: ">=3.9.0 <4.0.0"
  flutter: ">=3.35.0"

dependencies:
  flutter:
    sdk: flutter
  # commented_out:
  #   git:
  fleather: ^1.27.0
  flex_color_picker: ^3.7.2
  crypto: ^3.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
''';
      final dependencies = directDependencies(pubspec);

      expect(dependencies['fleather'], '^1.27.0');
      expect(dependencies['flex_color_picker'], '^3.7.2');
      expect(dependencies['crypto'], '^3.0.7');
      expect(dependencies['flutter'], isNull, reason: 'nested sdk block');
      expect(
        dependencies.containsKey('flutter_lints'),
        isFalse,
        reason: 'dev_dependencies must not be scanned',
      );
      expect(dependencies.containsKey('commented_out'), isFalse);
    });
  });

  group('THE GATE IS NON-VACUOUS', () {
    // The exact defect from BC-0060, which shipped in 0.14.0 through 0.17.0.
    //
    // pubspec.yaml declared flutter ">=3.35.0" while constraining
    // flex_color_picker to "^3.8.0". The only release satisfying ^3.8.0 is
    // 3.8.0, which itself requires flutter ">=3.38.0", so pub had no candidate
    // and version solving failed for every consumer on Flutter 3.35 to 3.37.
    //
    // If this test ever passes for the broken constraint, the gate has stopped
    // detecting the thing it exists for.
    const floorText = '3.35.0';
    const published = <String, String>{
      '3.7.0': '>=3.27.0',
      '3.7.1': '>=3.27.0',
      '3.7.2': '>=3.35.0',
      '3.8.0': '>=3.38.0',
    };

    List<String> reachableFor(String constraint) {
      final floor = parseDependencyFloorVersion(floorText)!;
      return published.entries
          .where((entry) => constraintAdmits(constraint, entry.key))
          .where((entry) => reachableFromFloor(entry.value, floor))
          .map((entry) => entry.key)
          .toList();
    }

    test('the shipped constraint ^3.8.0 has NO reachable candidate', () {
      expect(
        reachableFor('^3.8.0'),
        isEmpty,
        reason: 'this is the defect; an empty result is what fails the gate',
      );
    });

    test('the corrected constraint ^3.7.2 does have one', () {
      expect(reachableFor('^3.7.2'), contains('3.7.2'));
    });

    test('the correction does not downgrade a modern consumer', () {
      // 3.8.0 stays admissible, so a consumer whose toolchain allows it still
      // resolves the newest release.
      expect(constraintAdmits('^3.7.2', '3.8.0'), isTrue);
    });
  });
}
