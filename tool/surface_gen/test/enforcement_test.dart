import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/enforcement.dart';
import 'package:test/test.dart';

const _barrelAsset = 'surface_gen|test/fixtures/enforcement_barrel.dart';
const _configsAsset = 'surface_gen|test/fixtures/enforcement_configs.dart';
const _hiddenAsset = 'surface_gen|test/fixtures/enforcement_hidden.dart';

/// The barrel under enforcement: re-exports the config library, and exports a
/// second library with a `hide` combinator so unexported classes prove the
/// scan follows the EXPORT NAMESPACE, not the file system.
const _barrelSource = '''
library;

export 'enforcement_configs.dart';
export 'enforcement_hidden.dart' show ExportedBareConfig;
''';

/// A library whose config-shaped classes are only partly exported.
const _hiddenSource = '''
// ignore_for_file: unused_element
library;

class ExportedBareConfig {
  const ExportedBareConfig({this.value = 0});
  final int value;
  ExportedBareConfig copyWith({int? value}) =>
      ExportedBareConfig(value: value ?? this.value);
}

class UnexportedBareConfig {
  const UnexportedBareConfig({this.value = 0});
  final int value;
  UnexportedBareConfig copyWith({int? value}) =>
      UnexportedBareConfig(value: value ?? this.value);
}
''';

/// The fixture family. Mirrors the annotation contract verbatim (surface_gen
/// matches annotations by name + shape, library-agnostically) and covers each
/// enforcement outcome.
const _configsSource = r'''
library;

// --- mirrored annotation contract -----------------------------------------

class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],
    this.sealedVariants = const <String>[],
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[],
    this.clearFlags = const <String, String>{},
  });

  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
}

class CombinedSetter {
  const CombinedSetter(this.name, this.params);
  final String name;
  final List<String> params;
}

class ChartSurfaceExempt {
  const ChartSurfaceExempt(this.reason);
  final String reason;
}

const chartSurface = ChartSurface();

/// A same-named annotation of a DIFFERENT shape: must not satisfy the rule.
class ForeignSurface {
  const ForeignSurface();
}

// --- annotated: passes -----------------------------------------------------

@chartSurface
class AnnotatedConfig {
  const AnnotatedConfig({this.value = 0});
  final int value;
  AnnotatedConfig copyWith({int? value}) =>
      AnnotatedConfig(value: value ?? this.value);
}

/// Annotated with metadata (the non-const `chartSurface` spelling).
@ChartSurface(excluded: <String>['value'])
class AnnotatedWithMetadataConfig {
  const AnnotatedWithMetadataConfig({this.value = 0});
  final int value;
  AnnotatedWithMetadataConfig copyWith({int? value}) =>
      AnnotatedWithMetadataConfig(value: value ?? this.value);
}

// --- exempt: passes --------------------------------------------------------

@ChartSurfaceExempt('runtime handle, not a declarative config')
class ExemptConfig {
  const ExemptConfig({this.value = 0});
  final int value;
  ExemptConfig copyWith({int? value}) =>
      ExemptConfig(value: value ?? this.value);
}

// --- bare config shape: reported missing -----------------------------------

class BareConfig {
  const BareConfig({this.value = 0});
  final int value;
  BareConfig copyWith({int? value}) => BareConfig(value: value ?? this.value);
}

/// Inherits `copyWith` from a supertype — still config-shaped.
class BaseWithCopyWith {
  const BaseWithCopyWith();
  BaseWithCopyWith copyWith() => const BaseWithCopyWith();
}

class InheritedCopyWithConfig extends BaseWithCopyWith {
  const InheritedCopyWithConfig({this.value = 0});
  final int value;
}

/// Carries a same-named annotation of the wrong shape: not a valid marker.
@ForeignSurface()
class ForeignAnnotatedConfig {
  const ForeignAnnotatedConfig({this.value = 0});
  final int value;
  ForeignAnnotatedConfig copyWith({int? value}) =>
      ForeignAnnotatedConfig(value: value ?? this.value);
}

// --- ignored: not config-shaped -------------------------------------------

/// No const unnamed constructor.
class NonConstConfig {
  NonConstConfig({this.value = 0});
  int value;
  NonConstConfig copyWith({int? value}) =>
      NonConstConfig(value: value ?? this.value);
}

/// Const unnamed constructor but no `copyWith`.
class ConstWithoutCopyWith {
  const ConstWithoutCopyWith({this.value = 0});
  final int value;
}

/// `copyWith` is STATIC — not an instance method, so not config-shaped.
class StaticCopyWithConfig {
  const StaticCopyWithConfig({this.value = 0});
  final int value;
  static StaticCopyWithConfig copyWith({int value = 0}) =>
      StaticCopyWithConfig(value: value);
}

/// `copyWith` lives in an EXTENSION — not a member of the class.
class ExtensionCopyWithConfig {
  const ExtensionCopyWithConfig({this.value = 0});
  final int value;
}

extension ExtensionCopyWithConfigX on ExtensionCopyWithConfig {
  ExtensionCopyWithConfig copyWith({int? value}) =>
      ExtensionCopyWithConfig(value: value ?? this.value);
}

/// Only a private const constructor: no const UNNAMED constructor.
class PrivateCtorConfig {
  const PrivateCtorConfig._({this.value = 0});
  final int value;
  PrivateCtorConfig copyWith({int? value}) =>
      PrivateCtorConfig._(value: value ?? this.value);
}

/// Annotated but NOT config-shaped: still reported as annotated so the
/// package-level pilot assertions see every annotated class.
@chartSurface
class AnnotatedNonConfig {
  AnnotatedNonConfig({this.value = 0});
  int value;
}
''';

Future<EnforcementResult> _check() => resolveSources(
      {
        _barrelAsset: _barrelSource,
        _configsAsset: _configsSource,
        _hiddenAsset: _hiddenSource,
      },
      (resolver) async {
        final barrel = await resolver.libraryFor(AssetId.parse(_barrelAsset));
        return const SurfaceEnforcement().check(barrel: barrel);
      },
    );

Iterable<String> _names(List<EnforcementEntry> entries) =>
    entries.map((entry) => entry.className);

void main() {
  late EnforcementResult result;

  setUpAll(() async {
    result = await _check();
  });

  group('annotated', () {
    test('an @chartSurface class passes enforcement', () {
      expect(_names(result.annotated), contains('AnnotatedConfig'));
      expect(_names(result.missing), isNot(contains('AnnotatedConfig')));
    });

    test('an @ChartSurface(...) class with metadata passes enforcement', () {
      expect(
        _names(result.annotated),
        contains('AnnotatedWithMetadataConfig'),
      );
    });

    test('an annotated class that is not config-shaped is still reported', () {
      expect(_names(result.annotated), contains('AnnotatedNonConfig'));
      expect(_names(result.missing), isNot(contains('AnnotatedNonConfig')));
    });

    test('reports exactly the annotated classes', () {
      expect(
        _names(result.annotated),
        unorderedEquals([
          'AnnotatedConfig',
          'AnnotatedWithMetadataConfig',
          'AnnotatedNonConfig',
        ]),
      );
    });
  });

  group('exempt', () {
    test('an @ChartSurfaceExempt class passes enforcement', () {
      expect(_names(result.exempt), unorderedEquals(['ExemptConfig']));
      expect(_names(result.missing), isNot(contains('ExemptConfig')));
    });

    test('captures the exemption reason', () {
      expect(
        result.exempt.single.exemptReason,
        'runtime handle, not a declarative config',
      );
    });
  });

  group('missing', () {
    test('a bare config-shaped class is reported missing', () {
      expect(_names(result.missing), contains('BareConfig'));
    });

    test('an inherited copyWith still counts as config-shaped', () {
      expect(_names(result.missing), contains('InheritedCopyWithConfig'));
    });

    test('a same-named annotation of the wrong shape does not satisfy', () {
      expect(_names(result.missing), contains('ForeignAnnotatedConfig'));
    });

    test('only exported classes are scanned', () {
      expect(_names(result.missing), contains('ExportedBareConfig'));
      expect(_names(result.missing), isNot(contains('UnexportedBareConfig')));
    });

    test('reports exactly the un-annotated config-shaped classes', () {
      expect(
        _names(result.missing),
        unorderedEquals([
          'BareConfig',
          'BaseWithCopyWith',
          'InheritedCopyWithConfig',
          'ForeignAnnotatedConfig',
          'ExportedBareConfig',
        ]),
      );
    });

    test('isClean is false while classes are missing', () {
      expect(result.isClean, isFalse);
    });
  });

  group('ignored', () {
    test('a class without a const unnamed constructor is ignored', () {
      for (final name in ['NonConstConfig', 'PrivateCtorConfig']) {
        expect(_names(result.missing), isNot(contains(name)), reason: name);
        expect(_names(result.annotated), isNot(contains(name)), reason: name);
        expect(_names(result.exempt), isNot(contains(name)), reason: name);
      }
    });

    test('a class without copyWith is ignored', () {
      expect(_names(result.missing), isNot(contains('ConstWithoutCopyWith')));
    });

    test('a static copyWith does not make a class config-shaped', () {
      expect(_names(result.missing), isNot(contains('StaticCopyWithConfig')));
    });

    test('an extension copyWith does not make a class config-shaped', () {
      expect(
        _names(result.missing),
        isNot(contains('ExtensionCopyWithConfig')),
      );
    });

    test('the annotation classes themselves are ignored', () {
      final all = [
        ..._names(result.annotated),
        ..._names(result.exempt),
        ..._names(result.missing),
      ];
      expect(all, isNot(contains('ChartSurface')));
      expect(all, isNot(contains('ChartSurfaceExempt')));
      expect(all, isNot(contains('CombinedSetter')));
    });
  });

  group('reporting', () {
    test('entries record the defining library uri, not the barrel', () {
      final entry =
          result.missing.firstWhere((e) => e.className == 'BareConfig');
      expect(entry.libraryUri, endsWith('enforcement_configs.dart'));
    });

    test('describeMissing lists every missing class grouped by library', () {
      final description = result.describeMissing();
      expect(description, contains('BareConfig'));
      expect(description, contains('ExportedBareConfig'));
      expect(description, contains('enforcement_configs.dart'));
      expect(description, contains('enforcement_hidden.dart'));
    });

    test('describeMissing is empty when nothing is missing', () {
      const clean = EnforcementResult(
        annotated: <EnforcementEntry>[],
        exempt: <EnforcementEntry>[],
        missing: <EnforcementEntry>[],
      );
      expect(clean.isClean, isTrue);
      expect(clean.describeMissing(), isEmpty);
    });

    test('entries are sorted by library then class name', () {
      final ordered = result.missing
          .map((e) => '${e.libraryUri}#${e.className}')
          .toList();
      expect(ordered, orderedEquals([...ordered]..sort()));
    });
  });
}
