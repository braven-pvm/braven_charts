/// The intermediate model between the `@chartSurface` annotations and the
/// emitters (fluent extensions, AI schema, manifest).
///
/// Built by `AnalyzerSurfaceReader` in `surface_reader.dart`; consumed by
/// every emitter. The contract mirrors the implementation plan verbatim —
/// later tasks depend on these exact names.
library;

/// How a constructor parameter participates in the generated surface.
enum SurfaceParamKind {
  /// Plain settable value (`withX(value)`).
  value,

  /// Enum-typed value; [SurfaceParam.enumValues] lists the member names.
  enumType,

  /// Another `@chartSurface`-annotated config class.
  nestedConfig,

  /// `ChartStyleValue<X>` tri-state field;
  /// [SurfaceParam.triStatePayloadType] carries `X`.
  triState,

  /// `List<...>`-typed value.
  listValue,

  /// `Map<...>`-typed value.
  mapValue,

  /// Function-typed parameter — excluded from generation.
  excludedFunction,

  /// Listenable-implementing or `*Controller`-typed parameter — excluded.
  excludedController,

  /// Force-excluded via `ChartSurface(excluded: [...])` metadata.
  excludedByAnnotation,

  /// Carries a parameter-level `@Deprecated(...)` — excluded by default.
  excludedDeprecated,

  /// The class's `copyWith` has no same-named parameter, so no fluent verb
  /// could lower onto it (ChartTheme's private-field-backed deprecated
  /// parameters are the canonical case). Excluded, and recorded here so the
  /// gap is visible rather than emitting code that does not compile.
  excludedNoCopyWithParam,
}

/// One constructor parameter of a surface class.
class SurfaceParam {
  const SurfaceParam({
    required this.name,
    required this.dartType,
    required this.kind,
    required this.isRequired,
    required this.isNullable,
    this.isNamed = true,
    this.defaultCode,
    this.triStatePayloadType,
    this.clearFlag,
    this.enumValues = const <String>[],
    this.typeOrigins = const <String, String>{},
  });

  /// Parameter name as declared on the read constructor.
  final String name;

  /// Display string of the static type (nullability suffix included).
  /// Typedef-aliased function types display structurally
  /// (e.g. `String Function(double)?`).
  final String dartType;

  /// Classification per the reader's rules.
  final SurfaceParamKind kind;

  /// Whether the parameter is required (positional or `required` named).
  final bool isRequired;

  /// Whether the static type is nullable (`?` suffix).
  final bool isNullable;

  /// Whether the parameter is named (as opposed to positional).
  final bool isNamed;

  /// The default value expression as SOURCE CODE, exactly as written in the
  /// constructor (never evaluated). `null` when the parameter has no default.
  final String? defaultCode;

  /// For [SurfaceParamKind.triState]: the payload type `X` of
  /// `ChartStyleValue<X>` as a display string.
  final String? triStatePayloadType;

  /// The `copyWith` clear-flag name for this parameter.
  ///
  /// Derived by the reader from the class's `copyWith` signature (a
  /// `bool clearFoo = false` parameter next to a nullable `foo`);
  /// `ChartSurface(clearFlags: {...})` metadata overrides the derivation.
  final String? clearFlag;

  /// For [SurfaceParamKind.enumType]: the enum member names in order.
  final List<String> enumValues;

  /// Simple type name -> URI of the library that DEFINES it, for the
  /// parameter's own type and every type argument it carries.
  ///
  /// This is what lets the emitter derive its imports from the analyzer
  /// instead of a hand-curated name allowlist: `dart:ui` and
  /// `package:flutter/**` origins become a `show`-limited
  /// `package:flutter/widgets.dart` import; `dart:core` needs no import; the
  /// package's own types come through the barrel.
  final Map<String, String> typeOrigins;
}

/// A factory constructor of a sealed surface class.
///
/// Sealed variant helpers mirror these signatures verbatim, defaults
/// included, so `withOverlayPresentation(...)` reads exactly like
/// `Presentation.overlay(...)`.
class SurfaceFactoryModel {
  const SurfaceFactoryModel(this.name, this.params);

  /// Factory name as declared (e.g. `overlay`).
  final String name;

  /// The factory's formal parameters, in declaration order. For a redirecting
  /// factory the default expressions come from the redirect target, which is
  /// where Dart requires them to live.
  final List<SurfaceParam> params;
}

/// One `@chartSurface`-annotated class.
class SurfaceClass {
  const SurfaceClass({
    required this.name,
    required this.libraryUri,
    required this.isConstConstructible,
    required this.hasCopyWith,
    required this.params,
    this.copyWithReturnType,
    this.typeParameters = const <String>[],
    this.factories = const <SurfaceFactoryModel>[],
    this.assertGroups = const <List<String>>[],
    this.sealedVariants = const <String>[],
    this.presetFactories = const <String>[],
    this.combinedSetters = const <CombinedSetterModel>[],
    this.isSealed = false,
  });

  /// Class name.
  final String name;

  /// URI of the defining library.
  final String libraryUri;

  /// Whether the constructor the reader selected is `const`.
  ///
  /// For YAxisConfig-shaped classes this reports the private const
  /// `_internal` pathway, not the non-const public constructor.
  final bool isConstConstructible;

  /// Whether the class declares or inherits an instance `copyWith`.
  final bool hasCopyWith;

  /// The declared return type of that `copyWith`, or `null` when there is
  /// none. When this is not [name] the class only has an INHERITED
  /// base-typed `copyWith` and no fluent surface can be emitted for it.
  final String? copyWithReturnType;

  /// Parameters of the selected constructor, in declaration order.
  final List<SurfaceParam> params;

  /// Type parameter DECLARATIONS with bounds (e.g. `T`, `T extends num`).
  ///
  /// Empty for non-generic classes. The emitter re-declares them on the
  /// generated extension so a generic config class does not silently
  /// type-erase.
  final List<String> typeParameters;

  /// Factory constructors, read only for sealed classes carrying
  /// `sealedVariants` metadata (they drive the variant helpers).
  final List<SurfaceFactoryModel> factories;

  /// Groups of constructor parameters that appear together in one
  /// constructor-initializer `assert`, sorted, deduplicated.
  ///
  /// Every group must be covered by a [combinedSetters] entry — otherwise the
  /// reader refuses to model the class, because individual setters could
  /// construct an intermediate value the assert rejects at runtime.
  final List<List<String>> assertGroups;

  /// Subclass names from `ChartSurface(sealedVariants: [...])` metadata.
  final List<String> sealedVariants;

  /// Factory names from `ChartSurface(presetFactories: [...])` metadata.
  ///
  /// Model metadata only: preset factories get NO generated fluent surface —
  /// Dart factories already chain (`CrosshairConfig.tracking().withSnapRadius(12)`).
  /// Slice 3's AI schema consumes this.
  final List<String> presetFactories;

  /// Assert-coupled setter groups from `ChartSurface(combinedSetters: [...])`.
  final List<CombinedSetterModel> combinedSetters;

  /// Whether the class itself is declared `sealed`.
  final bool isSealed;
}

/// Model counterpart of the `CombinedSetter` annotation.
class CombinedSetterModel {
  const CombinedSetterModel(this.name, this.paramNames);

  /// Generated setter name (e.g. `withVisibleRange`).
  final String name;

  /// The coupled parameter names it replaces (e.g. `['min', 'max']`).
  final List<String> paramNames;
}

/// The whole read surface: every annotated class of the read library.
class SurfaceModel {
  const SurfaceModel(this.classes);

  final List<SurfaceClass> classes;

  /// Returns the surface class named [name].
  ///
  /// Throws an [ArgumentError] listing the known classes when absent, so
  /// emitter failures point at the actual annotation gap.
  SurfaceClass byName(String name) {
    for (final cls in classes) {
      if (cls.name == name) return cls;
    }
    throw ArgumentError.value(
      name,
      'name',
      'No surface class with this name. '
          'Known: ${classes.map((c) => c.name).join(', ')}',
    );
  }

  /// Returns the surface class named [name], or `null`.
  SurfaceClass? tryByName(String name) {
    for (final cls in classes) {
      if (cls.name == name) return cls;
    }
    return null;
  }
}
