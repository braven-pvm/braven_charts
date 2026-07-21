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
}

/// One constructor parameter of a surface class.
class SurfaceParam {
  const SurfaceParam({
    required this.name,
    required this.dartType,
    required this.kind,
    required this.isRequired,
    required this.isNullable,
    this.defaultCode,
    this.triStatePayloadType,
    this.clearFlag,
    this.enumValues = const <String>[],
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

  /// The default value expression as SOURCE CODE, exactly as written in the
  /// constructor (never evaluated). `null` when the parameter has no default.
  final String? defaultCode;

  /// For [SurfaceParamKind.triState]: the payload type `X` of
  /// `ChartStyleValue<X>` as a display string.
  final String? triStatePayloadType;

  /// The copyWith clear-flag name from `ChartSurface(clearFlags: {...})`
  /// metadata, when this parameter has one (e.g. `clearMarkerStyle`).
  final String? clearFlag;

  /// For [SurfaceParamKind.enumType]: the enum member names in order.
  final List<String> enumValues;
}

/// One `@chartSurface`-annotated class.
class SurfaceClass {
  const SurfaceClass({
    required this.name,
    required this.libraryUri,
    required this.isConstConstructible,
    required this.hasCopyWith,
    required this.params,
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

  /// Parameters of the selected constructor, in declaration order.
  final List<SurfaceParam> params;

  /// Subclass names from `ChartSurface(sealedVariants: [...])` metadata.
  final List<String> sealedVariants;

  /// Factory names from `ChartSurface(presetFactories: [...])` metadata.
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
}
