import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/enforcement.dart';
import 'package:test/test.dart';

const _barrelAsset = 'surface_gen|test/fixtures/enforcement_barrel.dart';
const _configsAsset = 'surface_gen|test/fixtures/enforcement_configs.dart';
const _hiddenAsset = 'surface_gen|test/fixtures/enforcement_hidden.dart';
const _secondBarrelAsset =
    'surface_gen|test/fixtures/enforcement_barrel_two.dart';
const _extraAsset = 'surface_gen|test/fixtures/enforcement_extra.dart';

/// The barrel under enforcement: re-exports the config library, and exports a
/// second library with a `hide` combinator so unexported classes prove the
/// scan follows the EXPORT NAMESPACE, not the file system.
const _barrelSource = '''
library;

export 'enforcement_configs.dart';
export 'enforcement_hidden.dart' show ExportedBareConfig;
''';

/// A SECOND public entrypoint, exactly like `braven_charts_fluent.dart`: it
/// re-exports the first barrel (so every class is reachable twice) and adds
/// one entrypoint-only config class.
const _secondBarrelSource = '''
library;

export 'enforcement_barrel.dart';
export 'enforcement_extra.dart';
''';

/// Reachable ONLY from the second entrypoint.
const _extraSource = '''
library;

class SecondEntrypointConfig {
  const SecondEntrypointConfig({this.value = 0});
  final int value;
  SecondEntrypointConfig copyWith({int? value}) =>
      SecondEntrypointConfig(value: value ?? this.value);
}
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

// --- const-ness is NOT part of the rule: reported missing ------------------

/// No const constructor at all. The emitter never needs const, so this is a
/// config class like any other.
class NonConstConfig {
  NonConstConfig({this.value = 0});
  int value;
  NonConstConfig copyWith({int? value}) =>
      NonConstConfig(value: value ?? this.value);
}

/// Only a private const constructor — the `const _internal` idiom the reader
/// already supports.
class PrivateCtorConfig {
  const PrivateCtorConfig._({this.value = 0});
  final int value;
  PrivateCtorConfig copyWith({int? value}) =>
      PrivateCtorConfig._(value: value ?? this.value);
}

/// `copyWith` lives in an EXTENSION. Consumers can still chain it, so it is
/// an escape hatch and counts as config-shaped.
class ExtensionCopyWithConfig {
  const ExtensionCopyWithConfig({this.value = 0});
  final int value;
}

extension ExtensionCopyWithConfigX on ExtensionCopyWithConfig {
  ExtensionCopyWithConfig copyWith({int? value}) =>
      ExtensionCopyWithConfig(value: value ?? this.value);
}

// --- ignored: not config-shaped -------------------------------------------

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

/// Abstract: never instantiated, so nothing to model.
abstract class AbstractCopyWithConfig {
  const AbstractCopyWithConfig();
  AbstractCopyWithConfig copyWith();
}

/// Sealed owners are modelled through their variants, not themselves.
sealed class SealedCopyWithConfig {
  const SealedCopyWithConfig({this.value = 0});
  final int value;
  SealedCopyWithConfig copyWith({int? value});
}

/// ...and the concrete variant IS config-shaped.
class SealedVariantConfig extends SealedCopyWithConfig {
  const SealedVariantConfig({super.value});
  @override
  SealedVariantConfig copyWith({int? value}) =>
      SealedVariantConfig(value: value ?? this.value);
}

/// Annotated but NOT config-shaped: still reported as annotated so the
/// package-level pilot assertions see every annotated class.
@chartSurface
class AnnotatedNonConfig {
  AnnotatedNonConfig({this.value = 0});
  int value;
}
''';

const _sources = {
  _barrelAsset: _barrelSource,
  _configsAsset: _configsSource,
  _hiddenAsset: _hiddenSource,
  _secondBarrelAsset: _secondBarrelSource,
  _extraAsset: _extraSource,
};

Future<EnforcementResult> _check() =>
    resolveSources(_sources, (resolver) async {
      final barrel = await resolver.libraryFor(AssetId.parse(_barrelAsset));
      return const SurfaceEnforcement().check(barrel: barrel);
    });

/// The union scan over BOTH public entrypoints, as `checkPackageSurface` does.
Future<EnforcementResult> _checkUnion() =>
    resolveSources(_sources, (resolver) async {
      final barrels = [
        await resolver.libraryFor(AssetId.parse(_barrelAsset)),
        await resolver.libraryFor(AssetId.parse(_secondBarrelAsset)),
      ];
      return const SurfaceEnforcement().checkAll(barrels: barrels);
    });

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
      expect(_names(result.annotated), contains('AnnotatedWithMetadataConfig'));
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
          'NonConstConfig',
          'PrivateCtorConfig',
          'ExtensionCopyWithConfig',
          'SealedVariantConfig',
        ]),
      );
    });

    test('isClean is false while classes are missing', () {
      expect(result.isClean, isFalse);
    });
  });

  group('const-ness is not part of the rule (C3)', () {
    test('a class with no const constructor is still config-shaped', () {
      expect(_names(result.missing), contains('NonConstConfig'));
    });

    test('a class with only a private const constructor is config-shaped', () {
      expect(_names(result.missing), contains('PrivateCtorConfig'));
    });

    test('const-ness is still reported as an attribute', () {
      EnforcementEntry entryFor(String name) =>
          result.missing.firstWhere((entry) => entry.className == name);
      expect(entryFor('BareConfig').hasConstUnnamedConstructor, isTrue);
      expect(entryFor('NonConstConfig').hasConstUnnamedConstructor, isFalse);
      expect(entryFor('PrivateCtorConfig').hasConstUnnamedConstructor, isFalse);
    });
  });

  group('extension copyWith (C5b)', () {
    test('an extension copyWith makes a class config-shaped', () {
      expect(_names(result.missing), contains('ExtensionCopyWithConfig'));
    });

    test('it is reported through hasInstanceCopyWith', () {
      final entry = result.missing.firstWhere(
        (e) => e.className == 'ExtensionCopyWithConfig',
      );
      expect(entry.hasInstanceCopyWith, isTrue);
    });
  });

  group('ignored', () {
    test('a class without copyWith is ignored', () {
      expect(_names(result.missing), isNot(contains('ConstWithoutCopyWith')));
    });

    test('a static copyWith does not make a class config-shaped', () {
      expect(_names(result.missing), isNot(contains('StaticCopyWithConfig')));
    });

    test('an abstract class is never config-shaped', () {
      expect(_names(result.missing), isNot(contains('AbstractCopyWithConfig')));
    });

    test('a sealed owner is never config-shaped, but its variant is', () {
      expect(_names(result.missing), isNot(contains('SealedCopyWithConfig')));
      expect(_names(result.missing), contains('SealedVariantConfig'));
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
      final entry = result.missing.firstWhere(
        (e) => e.className == 'BareConfig',
      );
      expect(entry.libraryUri, endsWith('enforcement_configs.dart'));
    });

    test('describeMissing lists every missing class grouped by library', () {
      final description = result.describeMissing();
      expect(description, contains('BareConfig'));
      expect(description, contains('ExportedBareConfig'));
      expect(description, contains('enforcement_configs.dart'));
      expect(description, contains('enforcement_hidden.dart'));
    });

    test('describeExempt lists every exemption with its reason', () {
      expect(
        result.describeExempt(),
        contains('ExemptConfig — runtime handle, not a declarative config'),
      );
    });

    test('describeExempt is empty when nothing is exempt', () {
      const none = EnforcementResult(
        annotated: <EnforcementEntry>[],
        exempt: <EnforcementEntry>[],
        missing: <EnforcementEntry>[],
      );
      expect(none.describeExempt(), isEmpty);
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

  group('multiple entrypoints (C5d)', () {
    late EnforcementResult union;

    setUpAll(() async {
      union = await _checkUnion();
    });

    test('a class reachable only from the second entrypoint is scanned', () {
      expect(_names(union.missing), contains('SecondEntrypointConfig'));
      expect(_names(result.missing), isNot(contains('SecondEntrypointConfig')));
    });

    test('a class reachable from both entrypoints is reported once', () {
      expect(
        _names(union.missing).where((name) => name == 'BareConfig').length,
        1,
      );
    });

    test('the union is a superset of the single-barrel scan', () {
      expect(_names(union.missing), containsAll(_names(result.missing)));
      expect(_names(union.annotated), containsAll(_names(result.annotated)));
      expect(_names(union.exempt), containsAll(_names(result.exempt)));
    });

    test('union entries stay sorted', () {
      final ordered = union.missing
          .map((e) => '${e.libraryUri}#${e.className}')
          .toList();
      expect(ordered, orderedEquals([...ordered]..sort()));
    });
  });
}
