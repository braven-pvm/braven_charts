/// Enforces that the whole public config surface is modelled.
///
/// ## The rule (spec: Layer 0 — Enforcement)
///
/// Every class reachable from the public barrel (`lib/braven_charts.dart`)
/// that is CONFIG-SHAPED must carry `@chartSurface` or
/// `@ChartSurfaceExempt(reason)`. Config-shaped means both:
///
/// 1. a `const` UNNAMED generative constructor, and
/// 2. an instance `copyWith` method (declared or inherited).
///
/// A `copyWith` that is `static`, or that lives in an extension rather than
/// the class itself, does not count: neither can participate in a fluent
/// `withX` chain.
///
/// ## Reachability
///
/// "Reachable" means present in the barrel's EXPORT NAMESPACE — the names a
/// consumer can actually write after `import 'package:braven_charts/
/// braven_charts.dart';`. Combinators (`show`/`hide`) are therefore honoured
/// for free, and a config class that lives under `lib/src/` but is never
/// exported is out of scope, exactly like the public API contract says.
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
    this.exemptReason,
  });

  /// The class name as written in source.
  final String className;

  /// URI of the library that DEFINES the class (never the barrel).
  final String libraryUri;

  /// The bucket this class landed in.
  final EnforcementStatus status;

  /// Whether the class has a const unnamed constructor and an instance
  /// `copyWith` (always `true` for [EnforcementStatus.missing]).
  final bool isConfigShaped;

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
  EnforcementResult check({required LibraryElement barrel}) {
    final annotated = <EnforcementEntry>[];
    final exempt = <EnforcementEntry>[];
    final missing = <EnforcementEntry>[];

    for (final element in barrel.exportNamespace.definedNames2.values) {
      if (element is! ClassElement) continue;
      final name = element.name;
      if (name == null || name.isEmpty) continue;

      final configShaped = _isConfigShaped(element);
      final surface = _annotationValue(element, 'ChartSurface');
      if (surface != null && _hasFields(surface, _chartSurfaceFields)) {
        annotated.add(
          EnforcementEntry(
            className: name,
            libraryUri: element.library.uri.toString(),
            status: EnforcementStatus.annotated,
            isConfigShaped: configShaped,
          ),
        );
        continue;
      }

      final exemption = _annotationValue(element, 'ChartSurfaceExempt');
      final reason = exemption?.getField('reason')?.toStringValue();
      if (reason != null) {
        exempt.add(
          EnforcementEntry(
            className: name,
            libraryUri: element.library.uri.toString(),
            status: EnforcementStatus.exempt,
            isConfigShaped: configShaped,
            exemptReason: reason,
          ),
        );
        continue;
      }

      if (!configShaped) continue;
      missing.add(
        EnforcementEntry(
          className: name,
          libraryUri: element.library.uri.toString(),
          status: EnforcementStatus.missing,
          isConfigShaped: true,
        ),
      );
    }

    return EnforcementResult(
      annotated: annotated..sort(),
      exempt: exempt..sort(),
      missing: missing..sort(),
    );
  }

  /// A const unnamed generative constructor plus an instance `copyWith`.
  bool _isConfigShaped(ClassElement cls) =>
      _hasConstUnnamedConstructor(cls) && _hasInstanceCopyWith(cls);

  bool _hasConstUnnamedConstructor(ClassElement cls) => cls.constructors.any(
        (constructor) =>
            constructor.isGenerative &&
            constructor.isConst &&
            _isUnnamed(constructor.name),
      );

  bool _isUnnamed(String? name) => name == null || name.isEmpty || name == 'new';

  /// Whether [cls] declares or inherits an instance `copyWith` method.
  ///
  /// Extension members are not class members and never reach [InterfaceElement.methods],
  /// so extension `copyWith` is excluded structurally.
  bool _hasInstanceCopyWith(ClassElement cls) {
    bool declares(InterfaceElement element) => element.methods
        .any((method) => method.name == 'copyWith' && !method.isStatic);
    if (declares(cls)) return true;
    return cls.allSupertypes.any((supertype) => declares(supertype.element));
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

/// Runs [SurfaceEnforcement] against a REAL package barrel on disk.
///
/// [barrelPath] is the absolute path of the barrel library (for braven_charts:
/// `<packageRoot>/lib/braven_charts.dart`). The analysis context is anchored on
/// the barrel's directory, so the package's `.dart_tool/package_config.json`
/// resolves every dependency exactly as `dart analyze` would.
///
/// [sdkPath] must be supplied when the host VM is not a Dart SDK executable —
/// notably under `flutter test`, whose `flutter_tester` runtime would otherwise
/// derive a bogus SDK root from `Platform.resolvedExecutable`. Pass
/// `<flutterRoot>/bin/cache/dart-sdk` there; see
/// `test/meta/surface_enforcement_test.dart`.
///
/// Throws [StateError] when the barrel does not resolve.
Future<EnforcementResult> checkPackageBarrel({
  required String barrelPath,
  String? sdkPath,
}) async {
  final barrel = File(barrelPath);
  if (!barrel.existsSync()) {
    throw StateError('surface_gen: barrel not found at $barrelPath');
  }
  final absolutePath = barrel.absolute.path;
  final collection = AnalysisContextCollection(
    includedPaths: [barrel.parent.absolute.path],
    sdkPath: sdkPath,
  );
  final session = collection.contextFor(absolutePath).currentSession;
  final resolved = await session.getResolvedLibrary(absolutePath);
  if (resolved is! ResolvedLibraryResult) {
    throw StateError(
      'surface_gen: could not resolve $absolutePath (got $resolved)',
    );
  }
  return const SurfaceEnforcement().check(barrel: resolved.element);
}
