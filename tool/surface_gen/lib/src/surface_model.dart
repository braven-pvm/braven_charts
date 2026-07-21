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
    this.asserts = const <SurfaceAssert>[],
    this.sealedVariants = const <String>[],
    this.presetFactories = const <String>[],
    this.combinedSetters = const <CombinedSetterModel>[],
    this.bodyValidations = const <BodyValidationModel>[],
    this.bodyValidationGroups = const <BodyValidationGroup>[],
    this.paramNotes = const <String, String>{},
    this.unnamedConstructorParams,
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
  /// Unioned over EVERY generative constructor the class declares, not just
  /// the one the reader selected for parameters: the `const _internal` idiom
  /// puts the asserts on the public constructor and the parameters on the
  /// private one, and reading only the selected constructor made a whole
  /// class's coupling invisible.
  ///
  /// Every group must be covered by a [combinedSetters] entry — otherwise the
  /// reader refuses to model the class, because individual setters could
  /// construct an intermediate value the assert rejects at runtime.
  final List<List<String>> assertGroups;

  /// The same asserts as [assertGroups], carrying the two things a schema
  /// needs and a bare name list cannot supply: the assert's own MESSAGE, and
  /// whether the condition is a provable null-alternation.
  ///
  /// Kept alongside [assertGroups] rather than replacing it: the fluent
  /// emitter's coverage rule only ever needed the names, and every existing
  /// caller (and test fixture) constructs the class with them.
  final List<SurfaceAssert> asserts;

  /// Constructor-BODY validation the reader detected, one entry per
  /// generative constructor with a non-empty body.
  ///
  /// Every parameter named by a group must be discharged — excluded, owned by
  /// a [combinedSetters] entry, or acknowledged in [bodyValidations] —
  /// or the reader refuses to model the class.
  final List<BodyValidationGroup> bodyValidationGroups;

  /// `ChartSurface(bodyValidated: [...])` acknowledgements.
  final List<BodyValidationModel> bodyValidations;

  /// `ChartSurface(paramNotes: {...})` — parameter name -> a caveat appended
  /// to that parameter's generated verb dartdoc.
  ///
  /// For truths about a verb that the surface model cannot derive and the
  /// generator cannot fix: `TextAnnotation.withText` type-checks on every
  /// instance but is a no-op on a RICH one, because the class's rich half is
  /// reachable only through `TextAnnotation.rich`. The verb stays (it is the
  /// primary verb on a plain annotation) and says what it does not do.
  ///
  /// The reader rejects a note for an unknown or EXCLUDED parameter: a note
  /// with no verb to carry it is documentation nobody will ever read.
  final Map<String, String> paramNotes;

  /// Parameters of the class's PUBLIC UNNAMED generative constructor, or
  /// `null` when it declares none (a sealed base, or the `const _internal`
  /// shape where the reader selected a private constructor that no test can
  /// call).
  ///
  /// [params] is the surface contract — what verbs exist. This is the
  /// CONSTRUCTION contract — how a test builds an instance to run them on.
  /// The two differ for `YAxisConfig`, whose parameters are read from
  /// `const YAxisConfig._internal(...)` but which can only be built through
  /// the public `YAxisConfig(position: ...)`.
  final List<SurfaceParam>? unnamedConstructorParams;

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

/// One generative constructor whose BODY validates the class.
///
/// [params] lists the class's modelled parameters the body NAMES. When the
/// body names none of them — the `validateConfiguration();` shape, where the
/// statements read fields rather than parameters — the reader cannot tell
/// which parameters the validation reaches, so [isOpaque] is `true` and
/// [params] carries every emitted parameter of the class.
class BodyValidationGroup {
  const BodyValidationGroup(
    this.constructorName,
    this.params, {
    this.isOpaque = false,
  });

  /// Declared constructor name; the empty string for the unnamed constructor.
  final String constructorName;

  /// The modelled parameters this body could reach, sorted.
  final List<String> params;

  /// Whether [params] is the conservative "every parameter" fallback.
  final bool isOpaque;

  /// How the constructor is written in a diagnostic.
  String get displayName =>
      constructorName.isEmpty ? 'the unnamed constructor' : constructorName;
}

/// Model counterpart of the `BodyValidated` annotation.
class BodyValidationModel {
  const BodyValidationModel(this.reason, this.params);

  /// Why the validation cannot be modelled, and what a caller can still trip.
  final String reason;

  /// The parameters this acknowledgement covers; empty means every parameter.
  final List<String> params;

  /// Whether this acknowledgement covers the whole class.
  bool get isClassWide => params.isEmpty;
}

/// One constructor-initializer `assert` that names two or more modelled
/// parameters.
///
/// A name list alone cannot be translated into a schema constraint, and
/// guessing costs correctness: of the three multi-parameter asserts on the
/// real surface that no combined setter covers, `BarChartSeries`'s is
/// `barWidthPercent != null || barWidthPixels != null` ("at least one"),
/// `RangeAnnotation`'s `startX == null || endX == null || startX < endX` is an
/// ORDERING check that permits both being null, and `LegendAnnotation`'s
/// `[...].whereType<Object>().length <= 1` is "at MOST one" — the exact
/// opposite. Emitting `anyOf: [{required: [a]}, {required: [b]}]` for all
/// three would have documented two of them backwards.
///
/// So [isNullAlternation] is set only when the condition is provably a
/// top-level `||` chain of `x != null` tests over exactly [params]. Everything
/// else contributes [message] to the class description and no machine
/// constraint at all.
class SurfaceAssert {
  const SurfaceAssert(
    this.params, {
    this.message,
    this.isNullAlternation = false,
  });

  /// The modelled parameters the condition names, sorted and deduplicated.
  final List<String> params;

  /// The assert's message argument when it is a plain string literal.
  final String? message;

  /// Whether the condition is a provable `a != null || b != null [|| ...]`
  /// over exactly [params].
  final bool isNullAlternation;
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
