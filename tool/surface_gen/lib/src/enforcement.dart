/// Enforces that the whole public config surface is modelled.
///
/// ## The rule (spec: Layer 0 — Enforcement)
///
/// Every class reachable from a public entrypoint (`lib/*.dart` — today
/// `braven_charts.dart` and the generated `braven_charts_fluent.dart`) that is
/// CONFIG-SHAPED must carry `@chartSurface` or `@ChartSurfaceExempt(reason)`.
/// Config-shaped means:
///
/// 1. the class is neither `abstract` nor `sealed` (it can be instantiated,
///    so it is a config a consumer actually holds), and
/// 2. an instance `copyWith` is callable on it — declared on the class,
///    inherited from a supertype, or supplied by a public extension.
///
/// Const-ness is deliberately NOT part of the rule. The emitter never needs a
/// const constructor, and the reader already handles non-const constructors
/// and the `const _internal` idiom; requiring const would permanently exempt
/// large parts of the real fleet (candlestick, polar and pie series, the
/// annotation family, the theme components). Const-ness is still recorded on
/// every entry as [EnforcementEntry.hasConstUnnamedConstructor].
///
/// A `static` `copyWith` does NOT count: it cannot participate in a fluent
/// `withX` chain. An EXTENSION `copyWith` does count — consumers can chain it
/// exactly like a member, so leaving it out would be a silent escape hatch
/// (move `copyWith` to an extension, vanish from enforcement).
///
/// ## Reachability
///
/// "Reachable" means present in the EXPORT NAMESPACE of any public entrypoint
/// — the names a consumer can actually write after `import
/// 'package:braven_charts/braven_charts.dart';` (or `..._fluent.dart`).
/// Combinators (`show`/`hide`) are therefore honoured for free, and a config
/// class that lives under `lib/src/` but is never exported is out of scope,
/// exactly like the public API contract says. Classes reachable from more
/// than one entrypoint are reported once.
///
/// ## Annotation matching
///
/// Identical in spirit to `surface_reader.dart`: matching is by NAME + SHAPE
/// and library-agnostic, because `surface_gen` cannot depend on the Flutter
/// package. `ChartSurface` must expose all five metadata fields;
/// `ChartSurfaceExempt` must expose a `reason` string. A same-named class of
/// a different shape is ignored, not an error.
///
/// ## Classification
///
/// Each scanned class lands in exactly one bucket:
///
/// - [EnforcementResult.annotated] — carries `@chartSurface`. Reported even
///   when the class is not config-shaped, so callers can assert that specific
///   classes are annotated (the Slice 1 pilot assertions) and so classes read
///   through a private `const _internal` constructor still show up.
/// - [EnforcementResult.exempt] — carries `@ChartSurfaceExempt(reason)`.
/// - [EnforcementResult.missing] — config-shaped, unannotated: the violation
///   set. [EnforcementResult.isClean] is the gate.
///
/// Anything else (not config-shaped, not annotated) is silently ignored.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Where a scanned class landed.
enum EnforcementStatus {
  /// Carries `@chartSurface`.
  annotated,

  /// Carries `@ChartSurfaceExempt(reason)`.
  exempt,

  /// Config-shaped but unannotated — an enforcement violation.
  missing,
}

/// One scanned class.
class EnforcementEntry implements Comparable<EnforcementEntry> {
  const EnforcementEntry({
    required this.className,
    required this.libraryUri,
    required this.status,
    required this.isConfigShaped,
    required this.hasInstanceCopyWith,
    required this.hasConstUnnamedConstructor,
    this.exemptReason,
  });

  /// The class name as written in source.
  final String className;

  /// URI of the library that DEFINES the class (never the barrel).
  final String libraryUri;

  /// The bucket this class landed in.
  final EnforcementStatus status;

  /// Whether the class is instantiable and carries an instance `copyWith`
  /// (always `true` for [EnforcementStatus.missing]).
  final bool isConfigShaped;

  /// Whether an instance `copyWith` is callable on the class — declared,
  /// inherited, or supplied by a public extension.
  final bool hasInstanceCopyWith;

  /// Whether the class has a `const` unnamed generative constructor. Reported
  /// only; it is NOT part of the enforcement rule.
  final bool hasConstUnnamedConstructor;

  /// The reason string of `@ChartSurfaceExempt`, when [status] is
  /// [EnforcementStatus.exempt].
  final String? exemptReason;

  @override
  int compareTo(EnforcementEntry other) {
    final byLibrary = libraryUri.compareTo(other.libraryUri);
    if (byLibrary != 0) return byLibrary;
    return className.compareTo(other.className);
  }

  @override
  String toString() => '$libraryUri#$className (${status.name})';
}

/// The outcome of one enforcement run. All three lists are sorted by library
/// URI then class name.
class EnforcementResult {
  const EnforcementResult({
    required this.annotated,
    required this.exempt,
    required this.missing,
  });

  /// Classes carrying `@chartSurface`.
  final List<EnforcementEntry> annotated;

  /// Classes carrying `@ChartSurfaceExempt(reason)`.
  final List<EnforcementEntry> exempt;

  /// Config-shaped classes carrying neither annotation.
  final List<EnforcementEntry> missing;

  /// Whether the surface is fully modelled.
  bool get isClean => missing.isEmpty;

  /// Whether [className] is annotated with `@chartSurface`.
  bool isAnnotated(String className) =>
      annotated.any((entry) => entry.className == className);

  /// A human-readable listing of [missing], grouped by defining library.
  ///
  /// Returns the empty string when nothing is missing.
  String describeMissing() {
    if (missing.isEmpty) return '';
    final buffer = StringBuffer();
    String? currentLibrary;
    for (final entry in missing) {
      if (entry.libraryUri != currentLibrary) {
        currentLibrary = entry.libraryUri;
        buffer.writeln(currentLibrary);
      }
      buffer.writeln('  ${entry.className}');
    }
    return buffer.toString();
  }

  /// A human-readable listing of [exempt] as `ClassName — reason`, one per
  /// line, so every exemption is visible in the CI log and can be reviewed.
  ///
  /// Returns the empty string when nothing is exempt.
  String describeExempt() {
    if (exempt.isEmpty) return '';
    final buffer = StringBuffer();
    for (final entry in exempt) {
      buffer.writeln('  ${entry.className} — ${entry.exemptReason}');
    }
    return buffer.toString();
  }
}

/// The names a `ChartSurface`-shaped constant must expose to match.
const List<String> _chartSurfaceFields = [
  'presetFactories',
  'sealedVariants',
  'combinedSetters',
  'excluded',
  'clearFlags',
];

/// Checks the enforcement rule over a barrel library.
class SurfaceEnforcement {
  const SurfaceEnforcement();

  /// Scans every class in [barrel]'s export namespace and classifies it.
  EnforcementResult check({required LibraryElement barrel}) =>
      checkAll(barrels: [barrel]);

  /// Scans the UNION of every entrypoint in [barrels].
  ///
  /// A class reachable from more than one entrypoint (the fluent barrel
  /// re-exports the core barrel) is classified once, keyed by defining
  /// library plus class name.
  EnforcementResult checkAll({required Iterable<LibraryElement> barrels}) {
    final annotated = <EnforcementEntry>[];
    final exempt = <EnforcementEntry>[];
    final missing = <EnforcementEntry>[];
    final seen = <String>{};

    final elements = <Element>[];
    for (final barrel in barrels) {
      elements.addAll(barrel.exportNamespace.definedNames2.values);
    }
    final extensionCopyWithTargets = _extensionCopyWithTargets(elements);

    for (final element in elements) {
      if (element is! ClassElement) continue;
      final name = element.name;
      if (name == null || name.isEmpty) continue;
      final libraryUri = element.library.uri.toString();
      if (!seen.add('$libraryUri#$name')) continue;

      final hasCopyWith =
          _hasInstanceCopyWith(element) ||
          extensionCopyWithTargets.contains(element);
      final configShaped = _isConfigShaped(element, hasCopyWith: hasCopyWith);
      final isConst = _hasConstUnnamedConstructor(element);

      EnforcementEntry entry(EnforcementStatus status, {String? reason}) =>
          EnforcementEntry(
            className: name,
            libraryUri: libraryUri,
            status: status,
            isConfigShaped: configShaped,
            hasInstanceCopyWith: hasCopyWith,
            hasConstUnnamedConstructor: isConst,
            exemptReason: reason,
          );

      final surface = _annotationValue(element, 'ChartSurface');
      if (surface != null && _hasFields(surface, _chartSurfaceFields)) {
        annotated.add(entry(EnforcementStatus.annotated));
        continue;
      }

      final exemption = _annotationValue(element, 'ChartSurfaceExempt');
      final exemptReason = exemption?.getField('reason')?.toStringValue();
      if (exemptReason != null) {
        exempt.add(entry(EnforcementStatus.exempt, reason: exemptReason));
        continue;
      }

      if (!configShaped) continue;
      missing.add(entry(EnforcementStatus.missing));
    }

    return EnforcementResult(
      annotated: annotated..sort(),
      exempt: exempt..sort(),
      missing: missing..sort(),
    );
  }

  /// Instantiable (neither abstract nor sealed) plus a callable instance
  /// `copyWith`. Const-ness is NOT part of the rule; see the library doc.
  bool _isConfigShaped(ClassElement cls, {required bool hasCopyWith}) =>
      !cls.isAbstract && !cls.isSealed && hasCopyWith;

  bool _hasConstUnnamedConstructor(ClassElement cls) => cls.constructors.any(
    (constructor) =>
        constructor.isGenerative &&
        constructor.isConst &&
        _isUnnamed(constructor.name),
  );

  bool _isUnnamed(String? name) =>
      name == null || name.isEmpty || name == 'new';

  /// Whether [cls] declares or inherits an instance `copyWith` method.
  ///
  /// Extension members are not class members and never reach
  /// [InterfaceElement.methods]; they are picked up separately by
  /// [_extensionCopyWithTargets].
  bool _hasInstanceCopyWith(ClassElement cls) {
    bool declares(InterfaceElement element) => element.methods.any(
      (method) => method.name == 'copyWith' && !method.isStatic,
    );
    if (declares(cls)) return true;
    return cls.allSupertypes.any((supertype) => declares(supertype.element));
  }

  /// The classes that a reachable public extension gives an instance
  /// `copyWith`. Such a `copyWith` chains exactly like a member, so hiding
  /// one in an extension must not dodge enforcement.
  Set<InterfaceElement> _extensionCopyWithTargets(Iterable<Element> elements) {
    final targets = <InterfaceElement>{};
    for (final element in elements) {
      if (element is! ExtensionElement) continue;
      final declaresCopyWith = element.methods.any(
        (method) => method.name == 'copyWith' && !method.isStatic,
      );
      if (!declaresCopyWith) continue;
      final extended = element.extendedType;
      if (extended is InterfaceType) targets.add(extended.element);
    }
    return targets;
  }

  /// The computed constant value of the annotation on [element] whose type is
  /// named [typeName], or `null`.
  DartObject? _annotationValue(Element element, String typeName) {
    for (final annotation in element.metadata.annotations) {
      final value = annotation.computeConstantValue();
      if (value == null) continue;
      final type = value.type;
      if (type is InterfaceType && type.element.name == typeName) return value;
    }
    return null;
  }

  bool _hasFields(DartObject value, List<String> fields) =>
      fields.every((field) => value.getField(field) != null);
}

/// Runs [SurfaceEnforcement] against a REAL package on disk, over EVERY
/// public entrypoint.
///
/// [libPath] is the absolute path of the package's `lib/` directory. Every
/// `lib/*.dart` is treated as a public entrypoint and its export namespace is
/// unioned, so adding a third barrel never silently narrows the scan (there
/// are two today: `braven_charts.dart` and the generated
/// `braven_charts_fluent.dart`). The analysis context is anchored on `lib/`,
/// so the package's `.dart_tool/package_config.json` resolves every dependency
/// exactly as `dart analyze` would.
///
/// [sdkPath] must be supplied when the host VM is not a Dart SDK executable —
/// notably under `flutter test`, whose `flutter_tester` runtime would otherwise
/// derive a bogus SDK root from `Platform.resolvedExecutable`. Pass
/// `<flutterRoot>/bin/cache/dart-sdk` there; see
/// `test/meta/surface_enforcement_test.dart`.
///
/// Throws [StateError] when `lib/` holds no entrypoint or one does not resolve.
Future<EnforcementResult> checkPackageSurface({
  required String libPath,
  String? sdkPath,
}) async {
  final lib = Directory(libPath);
  if (!lib.existsSync()) {
    throw StateError('surface_gen: lib directory not found at $libPath');
  }
  final entrypoints =
      lib
          .listSync()
          .whereType<File>()
          .map((file) => file.absolute.path)
          .where((path) => path.endsWith('.dart'))
          .toList()
        ..sort();
  if (entrypoints.isEmpty) {
    throw StateError(
      'surface_gen: no public entrypoint (lib/*.dart) in $libPath',
    );
  }
  final collection = AnalysisContextCollection(
    includedPaths: [lib.absolute.path],
    sdkPath: sdkPath,
  );
  final barrels = <LibraryElement>[];
  for (final path in entrypoints) {
    final session = collection.contextFor(path).currentSession;
    final resolved = await session.getResolvedLibrary(path);
    if (resolved is! ResolvedLibraryResult) {
      throw StateError('surface_gen: could not resolve $path (got $resolved)');
    }
    barrels.add(resolved.element);
  }
  return const SurfaceEnforcement().checkAll(barrels: barrels);
}
