/// Reads `@chartSurface`-annotated classes from a resolved library into a
/// [SurfaceModel].
///
/// ## Annotation matching — by name + shape, library-agnostic
///
/// `surface_gen` cannot depend on the Flutter package, so the reader never
/// compares annotation types by library identity. An annotation counts as a
/// `ChartSurface` marker when its computed constant value's type is NAMED
/// `ChartSurface` AND the value exposes all five metadata fields
/// (`presetFactories`, `sealedVariants`, `combinedSetters`, `excluded`,
/// `clearFlags`). Test fixtures mirror the annotation classes verbatim inside
/// their own sources and match exactly like the real
/// `lib/src/meta/chart_surface.dart` annotations do in the builder.
/// A same-named class of a different shape is ignored, not an error.
///
/// The framework-shaped special types are matched by name for the same
/// reason: `ChartStyleValue` (tri-state) and `Listenable` (controller rule).
///
/// ## Constructor selection
///
/// Parameters are read from ONE constructor per class, selected by
/// convention:
///
/// 1. the unnamed generative constructor, when it is `const`;
/// 2. otherwise a private `const` generative constructor named `_internal`
///    (the repo convention for classes whose public unnamed constructor
///    cannot be const — e.g. `YAxisConfig`; internal-only parameters such as
///    `id` must be force-excluded via `ChartSurface(excluded: [...])`);
/// 3. otherwise the unnamed generative constructor even though non-const
///    ([SurfaceClass.isConstConstructible] reports `false`);
/// 4. otherwise the class is unreadable and a [StateError] is thrown.
///
/// [SurfaceClass.isConstConstructible] always describes the SELECTED
/// constructor.
///
/// Selection governs PARAMETERS only. Two things are read from EVERY
/// generative constructor the class declares, because reading them from the
/// selected one alone made real coupling invisible:
///
/// - assert initializers ([SurfaceClass.assertGroups]) — deleting
///   `YAxisConfig`'s hand-written `CombinedSetter`s used to leave the reader
///   silent, because its asserts live on the public non-const constructor
///   while its parameters are read from `const YAxisConfig._internal`;
/// - non-empty constructor BODIES
///   ([SurfaceClass.bodyValidationGroups]), the unmodelled-validation signal
///   described below.
///
/// [SurfaceClass.unnamedConstructorParams] additionally records the PUBLIC
/// unnamed constructor's parameters — the construction contract, as opposed
/// to `params`' surface contract — so generated tests can build a real
/// instance of a class whose selected constructor is private.
///
/// ## Classification precedence
///
/// Each parameter gets exactly one [SurfaceParamKind], decided in this
/// order (first match wins):
///
/// 1. named in `ChartSurface(excluded: [...])` → [SurfaceParamKind.excludedByAnnotation]
/// 2. carries a parameter-level `@Deprecated` → [SurfaceParamKind.excludedDeprecated]
/// 3. no same-named parameter on the class's `copyWith` →
///    [SurfaceParamKind.excludedNoCopyWithParam] (the ChartTheme case: four
///    deprecated constructor parameters back PRIVATE fields and never reach
///    `copyWith`; emitting `withGridColor` produced an
///    `undefined_named_parameter` and the generated library did not compile)
/// 4. function-typed (including typedef aliases) → [SurfaceParamKind.excludedFunction]
/// 5. `*Controller`-named type, `Listenable`, or any type whose supertype
///    walk contains a type named `Listenable` → [SurfaceParamKind.excludedController]
/// 6. `ChartStyleValue<X>` → [SurfaceParamKind.triState] (payload `X`)
/// 7. enum type → [SurfaceParamKind.enumType] with member names
/// 8. type annotated `@chartSurface` (anywhere) → [SurfaceParamKind.nestedConfig]
/// 9. `List<...>` / `Map<...>` → [SurfaceParamKind.listValue] / [SurfaceParamKind.mapValue]
/// 10. otherwise → [SurfaceParamKind.value]
///
/// Notably: an annotated config class whose name ends in `Controller` is
/// still excluded (rule 5 precedes rule 8) — explicit exclusion semantics
/// beat nesting.
///
/// Default expressions are captured as SOURCE STRINGS from
/// `defaultValueCode`, never evaluated.
///
/// ## Derived metadata
///
/// - **Clear flags** (`SurfaceParam.clearFlag`): for every NULLABLE parameter
///   `foo`, a `bool clearFoo` parameter on `copyWith` is discovered
///   automatically. `ChartSurface(clearFlags: {...})` is now an OVERRIDE, not
///   a transcription obligation.
/// - **Type origins** (`SurfaceParam.typeOrigins`): the defining library URI
///   of every type named in the parameter's type, so the emitter derives its
///   imports instead of consulting a curated allowlist.
/// - **Assert groups** (`SurfaceClass.assertGroups`): constructor-initializer
///   `assert`s naming two or more parameters. Coupled parameters MUST be
///   covered by a `CombinedSetter`; see the diagnostics below.
///
/// ## Named diagnostics (hard failures)
///
/// - **slicing copyWith** — an annotated class whose `copyWith` returns AND
///   constructs the class itself, while a REACHABLE subclass inherits that
///   `copyWith` instead of overriding it covariantly. Generated `withX` verbs
///   would hand back a bare base and discard the subclass's state. The scan
///   is over the whole reachable class set (`enforcement.dart`'s
///   `reachableClasses`), because a subclass almost never shares a file with
///   its base. Fix by giving the subclass a covariant `copyWith`, annotating
///   `@ChartSurfaceExempt(reason)`, or making `copyWith` abstract.
///
///   **Scope of this guard — read before trusting it.** It proves DATA
///   RETENTION THROUGH VIRTUAL DISPATCH, and nothing else. It answers one
///   question: does the `copyWith` a subclass effectively runs return the
///   subclass's own type? It does NOT prove field completeness. A covariant
///   override that returns the right type while silently dropping inherited
///   fields — `TintedPieStyle copyWith(...) => TintedPieStyle(tint: tint)`,
///   discarding `sliceGap`, `opacity` and `gradient` — passes this guard
///   untouched, and the reviewer confirmed it by injecting exactly that
///   class. A static sweep of all 647 reachable classes found no real case
///   today, so the hole is theoretical, but it IS a hole. A cheap
///   field-coverage check is not available at this layer: `copyWith` bodies
///   are ordinary Dart, the constructor arguments they build are arbitrary
///   expressions, and legitimate overrides routinely omit fields that are
///   DERIVED (`CandlestickDataPoint` never passes `y`; it passes `close` and
///   the constructor computes `y`). Distinguishing "derived" from "dropped"
///   needs dataflow the analyzer element model does not offer here, so a
///   naive "every field appears as an argument" rule would be a false-alarm
///   generator on the existing fleet. It is deliberately not added.
///
///   Note also that passing this guard does not make an INHERITED verb a
///   no-op-safe operation on a subclass: a base verb may be REMAPPED by the
///   subclass's `copyWith`. `ChartDataPointFluent.withY(42)` applied to a
///   base-typed `CandlestickDataPoint` lowers to `copyWith(y: 42)`, which
///   `CandlestickDataPoint.copyWith` re-reads as `close`, and throws when the
///   result violates the OHLC ordering. That is a REMAP, not slicing, and it
///   is out of this guard's scope by construction.
/// - **assert-coupled parameters** — a multi-parameter constructor assert not
///   covered by a `CombinedSetter`. Individual setters would let a chain step
///   construct a value the assert rejects (`BarChartSeries(...).withMinWidth(200)`
///   throws today). Scanned over every generative constructor, not just the
///   selected one.
/// - **unmodelled constructor validation** — an annotated class with a
///   non-empty generative constructor BODY. Statements in a body are opaque
///   to the reader: it can see that the class validates something and cannot
///   see what, so it cannot prove a generated `withX(...)` produces a value
///   the constructor accepts. Five classes shipped throwing verbs exactly
///   this way. Every emitted parameter the body could reach must be
///   discharged — owned by a `CombinedSetter`, force-excluded, or
///   acknowledged with `ChartSurface(bodyValidated: [BodyValidated(reason)])`.
library;

// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'
    show ConstructorElementImpl;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'surface_model.dart';

/// Reads a resolved library into a [SurfaceModel].
abstract interface class SurfaceReader {
  /// Reads every `@chartSurface`-annotated class of [library].
  ///
  /// [reachable] is the public-entrypoint class set (see
  /// `enforcement.dart`'s `reachableClasses`). The slicing diagnostic is
  /// defined over the whole reachable surface, not over [library] alone: a
  /// subclass usually lives in a DIFFERENT file from the base it slices.
  /// Callers that leave it empty get the single-library scan, which is
  /// strictly weaker.
  Future<SurfaceModel> read(
    LibraryElement library, {
    Iterable<ClassElement> reachable,
  });
}

/// The names a `ChartSurface`-shaped constant must expose to match.
const List<String> _annotationFields = [
  'presetFactories',
  'sealedVariants',
  'combinedSetters',
  'excluded',
  'clearFlags',
];

/// [SurfaceReader] over the analyzer element model (analyzer 12.x).
class AnalyzerSurfaceReader implements SurfaceReader {
  const AnalyzerSurfaceReader();

  @override
  Future<SurfaceModel> read(
    LibraryElement library, {
    Iterable<ClassElement> reachable = const [],
  }) async {
    final scope = _scope(library, reachable);
    final classes = <SurfaceClass>[];
    for (final cls in library.classes) {
      final annotation = _chartSurfaceAnnotation(cls);
      if (annotation == null) continue;
      classes.add(_readClass(cls, annotation, library, scope));
    }
    return SurfaceModel(classes);
  }

  /// The classes the slicing diagnostic looks at: this library's own plus the
  /// reachable set, de-duplicated by identity.
  List<ClassElement> _scope(
    LibraryElement library,
    Iterable<ClassElement> reachable,
  ) {
    final scope = <ClassElement>[...library.classes];
    for (final cls in reachable) {
      if (scope.any((existing) => identical(existing, cls))) continue;
      scope.add(cls);
    }
    return scope;
  }

  SurfaceClass _readClass(
    ClassElement cls,
    DartObject annotation,
    LibraryElement library,
    List<ClassElement> scope,
  ) {
    final excluded = _stringList(annotation.getField('excluded')).toSet();
    final clearFlagOverrides = _stringMap(annotation.getField('clearFlags'));
    final constructor = _selectConstructor(cls);
    final copyWith = _findCopyWith(cls);
    final isConstConstructible = constructor?.isConst ??
        cls.constructors.any((c) => c.isGenerative && c.isConst);

    _checkSlicingCopyWith(cls, copyWith, scope);

    final copyWithParams = <String, DartType>{
      if (copyWith != null)
        for (final parameter in copyWith.formalParameters)
          if (parameter.name != null) parameter.name!: parameter.type,
    };

    final params = [
      for (final parameter in constructor?.formalParameters ?? const [])
        _readParam(
          parameter,
          excluded: excluded,
          clearFlagOverrides: clearFlagOverrides,
          copyWithParams: copyWithParams,
          hasCopyWith: copyWith != null,
        ),
    ];

    final combinedSetters =
        _combinedSetters(annotation.getField('combinedSetters'));
    final asserts = _asserts(cls, params, library);
    final assertGroups = [for (final entry in asserts) entry.params];
    _checkAssertCoverage(cls, assertGroups, combinedSetters, params);

    final bodyValidations =
        _bodyValidations(annotation.getField('bodyValidated'));
    final bodyGroups = _bodyValidationGroups(cls, params, library);
    _checkBodyValidationCoverage(
      cls,
      bodyGroups,
      bodyValidations,
      combinedSetters,
      params,
    );

    final paramNotes = _stringMap(annotation.getField('paramNotes'));
    _checkParamNotes(cls, paramNotes, params);

    final sealedVariants = _stringList(annotation.getField('sealedVariants'));

    return SurfaceClass(
      name: cls.name!,
      libraryUri: cls.library.uri.toString(),
      isConstConstructible: isConstConstructible,
      hasCopyWith: copyWith != null,
      copyWithReturnType: copyWith?.returnType.getDisplayString(),
      typeParameters: _typeParameters(cls),
      factories: sealedVariants.isEmpty ? const [] : _factories(cls),
      assertGroups: assertGroups,
      asserts: asserts,
      bodyValidationGroups: bodyGroups,
      bodyValidations: bodyValidations,
      paramNotes: paramNotes,
      unnamedConstructorParams: _unnamedConstructorParams(
        cls,
        excluded: excluded,
        clearFlagOverrides: clearFlagOverrides,
        copyWithParams: copyWithParams,
        hasCopyWith: copyWith != null,
      ),
      params: params,
      sealedVariants: sealedVariants,
      presetFactories: _stringList(annotation.getField('presetFactories')),
      combinedSetters: combinedSetters,
      isSealed: cls.isSealed,
    );
  }

  /// The PUBLIC unnamed generative constructor's parameters, or `null`.
  ///
  /// This is the CONSTRUCTION contract (see
  /// [SurfaceClass.unnamedConstructorParams]); it coincides with `params` for
  /// every class except the `const _internal` shape and sealed bases.
  List<SurfaceParam>? _unnamedConstructorParams(
    ClassElement cls, {
    required Set<String> excluded,
    required Map<String, String> clearFlagOverrides,
    required Map<String, DartType> copyWithParams,
    required bool hasCopyWith,
  }) {
    for (final constructor in cls.constructors) {
      if (!constructor.isGenerative) continue;
      final name = constructor.name;
      if (name != null && name.isNotEmpty && name != 'new') continue;
      return [
        for (final parameter in constructor.formalParameters)
          _readParam(
            parameter,
            excluded: excluded,
            clearFlagOverrides: clearFlagOverrides,
            copyWithParams: copyWithParams,
            hasCopyWith: hasCopyWith,
          ),
      ];
    }
    return null;
  }

  /// Selects the constructor to read, per the library-level dartdoc.
  ///
  /// Returns `null` for a SEALED owner whose only generative constructor is
  /// private (`const Presentation._()`, the repo's sealed-hierarchy shape):
  /// a sealed base is never constructed directly and contributes no
  /// parameters — its surface is the variant factories.
  ConstructorElement? _selectConstructor(ClassElement cls) {
    ConstructorElement? unnamed;
    ConstructorElement? internalConst;
    for (final constructor in cls.constructors) {
      if (!constructor.isGenerative) continue;
      final name = constructor.name;
      if (name == null || name.isEmpty || name == 'new') {
        unnamed = constructor;
      } else if (name == '_internal' && constructor.isConst) {
        internalConst = constructor;
      }
    }
    if (unnamed != null && unnamed.isConst) return unnamed;
    if (internalConst != null) return internalConst;
    if (unnamed != null) return unnamed;
    if (cls.isSealed) return null;
    throw StateError(
      'surface_gen: class ${cls.name} is annotated @chartSurface but exposes '
      'no readable constructor. Expected a const unnamed constructor, a '
      'private const constructor named `_internal`, or a non-const unnamed '
      'constructor.',
    );
  }

  /// Type parameter declarations with bounds, e.g. `['T extends num']`.
  List<String> _typeParameters(ClassElement cls) => [
        for (final parameter in cls.typeParameters)
          parameter.bound == null
              ? parameter.name!
              : '${parameter.name} extends '
                  '${parameter.bound!.getDisplayString()}',
      ];

  /// Factory constructors of a sealed owner, with defaults resolved through
  /// the redirect target (Dart forbids defaults on redirecting factories).
  List<SurfaceFactoryModel> _factories(ClassElement cls) {
    final factories = <SurfaceFactoryModel>[];
    for (final constructor in cls.constructors) {
      if (!constructor.isFactory) continue;
      final name = constructor.name;
      if (name == null || name.isEmpty || name == 'new') continue;
      if (name.startsWith('_')) continue;
      final target = constructor.redirectedConstructor;
      final targetDefaults = <String, String>{
        if (target != null)
          for (final parameter in target.formalParameters)
            if (parameter.name != null && parameter.defaultValueCode != null)
              parameter.name!: parameter.defaultValueCode!,
      };
      factories.add(
        SurfaceFactoryModel(name, [
          for (final parameter in constructor.formalParameters)
            SurfaceParam(
              name: parameter.name!,
              dartType: parameter.type.getDisplayString(),
              kind: _classifyType(parameter.type),
              isRequired: parameter.isRequired,
              isNullable:
                  parameter.type.nullabilitySuffix == NullabilitySuffix.question,
              isNamed: parameter.isNamed,
              defaultCode: parameter.defaultValueCode ??
                  targetDefaults[parameter.name],
              typeOrigins: _typeOrigins(parameter.type),
            ),
        ]),
      );
    }
    return factories;
  }

  SurfaceParam _readParam(
    FormalParameterElement parameter, {
    required Set<String> excluded,
    required Map<String, String> clearFlagOverrides,
    required Map<String, DartType> copyWithParams,
    required bool hasCopyWith,
  }) {
    final name = parameter.name!;
    final type = parameter.type;
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

    var kind = SurfaceParamKind.value;
    String? triStatePayloadType;
    var enumValues = const <String>[];

    if (excluded.contains(name)) {
      kind = SurfaceParamKind.excludedByAnnotation;
    } else if (_isDeprecated(parameter)) {
      kind = SurfaceParamKind.excludedDeprecated;
    } else if (hasCopyWith && !copyWithParams.containsKey(name)) {
      kind = SurfaceParamKind.excludedNoCopyWithParam;
    } else if (type is FunctionType) {
      kind = SurfaceParamKind.excludedFunction;
    } else if (_isControllerType(type)) {
      kind = SurfaceParamKind.excludedController;
    } else if (type is InterfaceType && type.element.name == 'ChartStyleValue') {
      kind = SurfaceParamKind.triState;
      triStatePayloadType = type.typeArguments.isEmpty
          ? 'dynamic'
          : type.typeArguments.first.getDisplayString();
    } else if (type is InterfaceType && type.element is EnumElement) {
      kind = SurfaceParamKind.enumType;
      enumValues = [
        for (final constant in (type.element as EnumElement).constants)
          constant.name!,
      ];
    } else if (type is InterfaceType &&
        _chartSurfaceAnnotation(type.element) != null) {
      kind = SurfaceParamKind.nestedConfig;
    } else if (type.isDartCoreList) {
      kind = SurfaceParamKind.listValue;
    } else if (type.isDartCoreMap) {
      kind = SurfaceParamKind.mapValue;
    }

    return SurfaceParam(
      name: name,
      dartType: type.getDisplayString(),
      kind: kind,
      isRequired: parameter.isRequired,
      isNullable: isNullable,
      isNamed: parameter.isNamed,
      defaultCode: parameter.defaultValueCode,
      triStatePayloadType: triStatePayloadType,
      clearFlag: clearFlagOverrides[name] ??
          _derivedClearFlag(name, isNullable, copyWithParams),
      enumValues: enumValues,
      typeOrigins: _typeOrigins(type),
    );
  }

  /// The coarse classification used for factory parameters, where the
  /// nesting/tri-state distinctions the emitter needs do not apply.
  SurfaceParamKind _classifyType(DartType type) {
    if (type is FunctionType) return SurfaceParamKind.excludedFunction;
    if (type is InterfaceType && type.element is EnumElement) {
      return SurfaceParamKind.enumType;
    }
    if (type.isDartCoreList) return SurfaceParamKind.listValue;
    if (type.isDartCoreMap) return SurfaceParamKind.mapValue;
    return SurfaceParamKind.value;
  }

  /// `clearFoo` when `copyWith` declares `bool clearFoo` next to nullable
  /// `foo`. This is what removes 119 hand transcriptions from Task 5/6.
  String? _derivedClearFlag(
    String name,
    bool isNullable,
    Map<String, DartType> copyWithParams,
  ) {
    if (!isNullable || name.isEmpty) return null;
    final flag = 'clear${name[0].toUpperCase()}${name.substring(1)}';
    final type = copyWithParams[flag];
    if (type == null) return null;
    return type.isDartCoreBool ? flag : null;
  }

  bool _isDeprecated(Element element) => element.metadata.annotations
      .any((annotation) => annotation.isDeprecated);

  /// Simple type name -> defining library URI, for [type] and its arguments.
  Map<String, String> _typeOrigins(DartType type) {
    final origins = <String, String>{};
    void collect(DartType current) {
      if (current is InterfaceType) {
        final name = current.element.name;
        if (name != null && name.isNotEmpty) {
          origins[name] = current.element.library.uri.toString();
        }
        for (final argument in current.typeArguments) {
          collect(argument);
        }
      } else if (current is FunctionType) {
        collect(current.returnType);
        for (final parameter in current.formalParameters) {
          collect(parameter.type);
        }
      }
    }

    collect(type);
    return origins;
  }

  /// Whether [type] is controller-shaped: named `*Controller`, named
  /// `Listenable`, or implementing/extending a type named `Listenable`.
  bool _isControllerType(DartType type) {
    if (type is! InterfaceType) return false;
    final element = type.element;
    final name = element.name;
    if (name != null && (name.endsWith('Controller') || name == 'Listenable')) {
      return true;
    }
    return element.allSupertypes
        .any((supertype) => supertype.element.name == 'Listenable');
  }

  /// The instance `copyWith` [cls] declares or inherits, or `null`.
  MethodElement? _findCopyWith(ClassElement cls) {
    MethodElement? declared(InterfaceElement element) {
      for (final method in element.methods) {
        if (method.name == 'copyWith' && !method.isStatic) return method;
      }
      return null;
    }

    final own = declared(cls);
    if (own != null) return own;
    for (final supertype in cls.allSupertypes) {
      final inherited = declared(supertype.element);
      if (inherited != null) return inherited;
    }
    return null;
  }

  /// Named diagnostic: slicing copyWith.
  ///
  /// [scope] is the reachable class set, not one library: a subclass almost
  /// never shares a file with the base it slices.
  ///
  /// A base whose `copyWith` returns the base and CONSTRUCTS a base is only
  /// dangerous for subclasses that inherit it. When a subclass overrides
  /// `copyWith` with its own return type, the generated `withX` still
  /// dispatches virtually, so no field is lost — the `chart_annotation.dart`
  /// / `candlestick_data_point.dart` shape is safe and is pinned by
  /// `test/fluent/fluent_behavior_matrix_test.dart` ('a base-typed verb keeps
  /// the subclass'). What IS lost is state on a subclass whose effective
  /// `copyWith` hands back something other than itself — it inherits the
  /// base's constructor call verbatim. That is the condition checked here.
  ///
  /// Subclasses that are themselves `@chartSurface` are skipped: the emitter
  /// already fails them loudly, and with a better message, through
  /// `FluentEmitter._checkCopyWithReturnType`.
  void _checkSlicingCopyWith(
    ClassElement cls,
    MethodElement? copyWith,
    List<ClassElement> scope,
  ) {
    if (copyWith == null || copyWith.isAbstract) return;
    if (copyWith.enclosingElement != cls) return;
    if (copyWith.returnType.getDisplayString() != cls.name) return;

    final sliced = <String>[];
    for (final candidate in scope) {
      if (identical(candidate, cls)) continue;
      if (candidate.isAbstract || candidate.isSealed) continue;
      final inherits =
          candidate.allSupertypes.any((supertype) => supertype.element == cls);
      if (!inherits) continue;
      if (_chartSurfaceAnnotation(candidate) != null) continue;
      final effective = _findCopyWith(candidate);
      if (effective == null) continue;
      if (effective.returnType.getDisplayString() == candidate.name) continue;
      sliced.add(candidate.name ?? '<unnamed>');
    }
    if (sliced.isEmpty) return;

    throw StateError(
      'surface_gen: slicing copyWith — ${cls.name}.copyWith returns and '
      'constructs a ${cls.name}, and ${sliced.join(', ')} inherit it without '
      'overriding it. Every generated ${cls.name}Fluent verb would hand back '
      'a bare ${cls.name} and silently discard their state whenever the '
      'static type is ${cls.name}. Give ${sliced.join(', ')} a covariant '
      'copyWith, annotate @ChartSurfaceExempt(reason) on ${cls.name} and '
      'model the concrete subtypes instead, or make ${cls.name}.copyWith '
      'abstract.',
    );
  }

  /// Constructor-initializer asserts naming two or more parameters, unioned
  /// over EVERY generative constructor the class declares.
  ///
  /// Reading only the selected constructor was a hole: `YAxisConfig` puts its
  /// asserts on the public non-const constructor and its parameters on
  /// `const YAxisConfig._internal`, so deleting its hand-written
  /// `CombinedSetter`s left the reader silent while the identical deletion on
  /// `XAxisConfig` — which has one constructor — fired. Coupling is a
  /// property of the CLASS, not of whichever constructor happened to be
  /// selected for parameter reading.
  ///
  /// Only CONST constructors carry their initializers into the element model
  /// (`constantInitializers` exists for constant evaluation). Const-ness is
  /// not part of the enforcement rule, though, and the whole annotation
  /// family has a NON-const unnamed constructor because it defaults `id`
  /// through `super(id: id ?? ChartAnnotation.generateId())`. Their asserts
  /// couple parameters exactly as hard, so when the element model is empty the
  /// declaration is parsed and its initializers read from the AST.
  /// Each assert additionally carries its MESSAGE and whether its condition is
  /// a provable null-alternation (see [SurfaceAssert]), because a name list
  /// alone cannot be turned into a schema constraint without guessing.
  List<SurfaceAssert> _asserts(
    ClassElement cls,
    List<SurfaceParam> params,
    LibraryElement library,
  ) {
    final names = {for (final param in params) param.name};
    if (names.isEmpty) return const [];
    final groups = <String, SurfaceAssert>{};
    for (final constructor in cls.constructors) {
      if (!constructor.isGenerative) continue;
      for (final initializer in _initializers(constructor, library)) {
        if (initializer is! AssertInitializer) continue;
        final visitor = _IdentifierCollector();
        initializer.condition.accept(visitor);
        final referenced = (visitor.names.intersection(names).toList())..sort();
        if (referenced.length < 2) continue;
        groups[referenced.join(',')] = SurfaceAssert(
          referenced,
          message: _assertMessage(initializer),
          isNullAlternation: _isNullAlternation(
            initializer.condition,
            referenced.toSet(),
          ),
        );
      }
    }
    final result = groups.values.toList()
      ..sort((a, b) => a.params.join(',').compareTo(b.params.join(',')));
    return result;
  }

  /// The assert's message argument, when it is a plain (non-interpolated)
  /// string literal.
  String? _assertMessage(AssertInitializer initializer) {
    final message = initializer.message;
    if (message is! SimpleStringLiteral) return null;
    final value = message.value.trim();
    return value.isEmpty ? null : value;
  }

  /// Whether [condition] is `a != null || b != null [|| ...]` over exactly
  /// [expected].
  ///
  /// Deliberately narrow: this is the ONLY assert shape that translates into a
  /// sound `anyOf: [{required: [a]}, ...]`. Anything richer — an ordering
  /// check, a `length <= 1` cardinality check — reads as a constraint the
  /// schema would state backwards, so it is not recognized.
  bool _isNullAlternation(Expression condition, Set<String> expected) {
    final seen = <String>{};
    bool walk(Expression node) {
      final expression = node.unParenthesized;
      if (expression is BinaryExpression) {
        if (expression.operator.type == TokenType.BAR_BAR) {
          return walk(expression.leftOperand) && walk(expression.rightOperand);
        }
        if (expression.operator.type == TokenType.BANG_EQ) {
          final left = expression.leftOperand.unParenthesized;
          final right = expression.rightOperand.unParenthesized;
          if (right is NullLiteral && left is SimpleIdentifier) {
            seen.add(left.name);
            return true;
          }
          if (left is NullLiteral && right is SimpleIdentifier) {
            seen.add(right.name);
            return true;
          }
        }
      }
      return false;
    }

    if (!walk(condition)) return false;
    return seen.length == expected.length && seen.containsAll(expected);
  }

  /// Non-empty generative constructor bodies, one group per constructor.
  ///
  /// A body is the unmodelled-validation signal: the reader can see that the
  /// class validates something in imperative code and cannot see what.
  ///
  /// Scope is resolved per STATEMENT, not per body, because the two shapes
  /// mix — `DonutChartSeries` opens with an opaque
  /// `validateRadialConfiguration(chartName: 'Donut')` and then range-checks
  /// `donutStyle` and `centerContent` by name in the statements that follow:
  ///
  /// - a statement that NAMES modelled parameters (`validateValues(x: x,
  ///   open: open, ...)`) contributes exactly those parameters;
  /// - a statement that names NONE of them (`validateConfiguration();`, which
  ///   reads FIELDS) makes the whole group opaque — every emitted parameter is
  ///   in scope and [BodyValidationGroup.isOpaque] is set. Recursing into the
  ///   callee is not sound: `PieChartSeries` forwards `pieStyle` to
  ///   `super(radialStyle: pieStyle)` and `validateRadialConfiguration` then
  ///   range-checks `radialStyle`, so a callee scan would miss the very
  ///   parameter whose verb throws.
  ///
  /// Const constructors cannot have bodies, so this never fires on the
  /// `_internal` half of a two-constructor class.
  List<BodyValidationGroup> _bodyValidationGroups(
    ClassElement cls,
    List<SurfaceParam> params,
    LibraryElement library,
  ) {
    final names = {for (final param in params) param.name};
    final emitted = [
      for (final param in params)
        if (!_isExcludedKind(param.kind)) param.name,
    ]..sort();
    final groups = <BodyValidationGroup>[];
    for (final constructor in cls.constructors) {
      if (!constructor.isGenerative) continue;
      final declaration = _declaration(constructor, library);
      final body = declaration?.body;
      if (body is! BlockFunctionBody) continue;
      final statements = body.block.statements;
      if (statements.isEmpty) continue;
      final referenced = <String>{};
      var isOpaque = false;
      for (final statement in statements) {
        final visitor = _IdentifierCollector();
        statement.accept(visitor);
        final named = visitor.names.intersection(names);
        if (named.isEmpty) {
          isOpaque = true;
        } else {
          referenced.addAll(named);
        }
      }
      groups.add(
        isOpaque
            ? BodyValidationGroup(
                _constructorName(constructor),
                emitted,
                isOpaque: true,
              )
            : BodyValidationGroup(
                _constructorName(constructor),
                referenced.toList()..sort(),
              ),
      );
    }
    return groups;
  }

  /// The declared name of [constructor]; the empty string when unnamed.
  String _constructorName(ConstructorElement constructor) {
    final name = constructor.name;
    if (name == null || name.isEmpty || name == 'new') return '';
    return name;
  }

  /// The initializers of [constructor] — from the element model for a const
  /// constructor, from the parsed declaration otherwise.
  ///
  /// Returns an empty list when there is no declaration to parse (a
  /// constructor synthesised by the analyzer has none), which degrades to
  /// "no coupling detected" rather than failing the build.
  List<ConstructorInitializer> _initializers(
    ConstructorElement constructor,
    LibraryElement library,
  ) {
    if (constructor is ConstructorElementImpl) {
      final constant = constructor.constantInitializers;
      if (constant.isNotEmpty) return constant;
    }
    return _declaration(constructor, library)?.initializers ?? const [];
  }

  /// The parsed declaration of [constructor], or `null` when the analyzer
  /// synthesised it (a synthesised constructor has no source and no body).
  ConstructorDeclaration? _declaration(
    ConstructorElement constructor,
    LibraryElement library,
  ) {
    final parsed = library.session.getParsedLibraryByElement(library);
    if (parsed is! ParsedLibraryResult) return null;
    final node = parsed.getFragmentDeclaration(constructor.firstFragment)?.node;
    return node is ConstructorDeclaration ? node : null;
  }

  /// Named diagnostic: assert-coupled parameters.
  void _checkAssertCoverage(
    ClassElement cls,
    List<List<String>> groups,
    List<CombinedSetterModel> combinedSetters,
    List<SurfaceParam> params,
  ) {
    if (groups.isEmpty) return;
    final emitted = {
      for (final param in params)
        if (!_isExcludedKind(param.kind)) param.name,
    };
    for (final group in groups) {
      final live = group.where(emitted.contains).toList();
      if (live.length < 2) continue;
      final covered = combinedSetters.any(
        (setter) => live.every(setter.paramNames.contains),
      );
      if (covered) continue;
      final suggestion = "CombinedSetter('with${_cap(live.first)}"
          "${live.skip(1).map(_cap).join()}', "
          "[${live.map((n) => "'$n'").join(', ')}])";
      throw StateError(
        'surface_gen: assert-coupled parameters — ${cls.name} asserts a '
        'relationship between ${live.join(', ')} in its constructor, so an '
        'individual with${_cap(live.first)}(...) can build a value the assert '
        'rejects at runtime. Add '
        '@ChartSurface(combinedSetters: [$suggestion]) to ${cls.name}, or '
        'force-exclude the parameters.',
      );
    }
  }

  /// Named diagnostic: a `paramNotes` entry with no verb to carry it.
  ///
  /// A note documents a generated verb, so it is only meaningful for a
  /// parameter that HAS one. Naming an unknown parameter is a typo; naming an
  /// excluded one is documentation that will never be emitted, and both used
  /// to fail silently.
  void _checkParamNotes(
    ClassElement cls,
    Map<String, String> notes,
    List<SurfaceParam> params,
  ) {
    if (notes.isEmpty) return;
    final byName = {for (final param in params) param.name: param};
    for (final name in notes.keys) {
      final param = byName[name];
      if (param == null) {
        throw StateError(
          'surface_gen: ${cls.name} carries a paramNotes entry for `$name`, '
          'which is not a parameter of its constructor. Known: '
          '${byName.keys.join(', ')}.',
        );
      }
      if (_isExcludedKind(param.kind)) {
        throw StateError(
          'surface_gen: ${cls.name} carries a paramNotes entry for `$name`, '
          'which is excluded (${param.kind.name}) and therefore has no '
          'generated verb to carry the note. Document the exclusion in the '
          "class's own dartdoc instead.",
        );
      }
    }
  }

  /// Named diagnostic: unmodelled constructor validation.
  ///
  /// A parameter is DISCHARGED when it is force-excluded, when it is a member
  /// of some `CombinedSetter` (the author has explicitly modelled how it
  /// moves), or when a `BodyValidated` acknowledgement names it — or names
  /// nothing, which covers the whole class.
  void _checkBodyValidationCoverage(
    ClassElement cls,
    List<BodyValidationGroup> groups,
    List<BodyValidationModel> acknowledgements,
    List<CombinedSetterModel> combinedSetters,
    List<SurfaceParam> params,
  ) {
    final known = {for (final param in params) param.name};
    for (final acknowledgement in acknowledgements) {
      for (final name in acknowledgement.params) {
        if (known.contains(name)) continue;
        throw StateError(
          'surface_gen: ${cls.name} carries a BodyValidated acknowledgement '
          'for `$name`, which is not a parameter of its constructor. Known: '
          '${known.join(', ')}.',
        );
      }
    }
    if (groups.isEmpty) {
      if (acknowledgements.isEmpty) return;
      throw StateError(
        'surface_gen: stale BodyValidated on ${cls.name} — no generative '
        'constructor of ${cls.name} has a non-empty body, so there is no '
        'unmodelled validation to acknowledge. Drop the '
        'ChartSurface(bodyValidated: [...]) entry.',
      );
    }

    final acknowledged = <String>{
      for (final acknowledgement in acknowledgements)
        if (acknowledgement.isClassWide) ...known else ...acknowledgement.params,
    };
    final combined = <String>{
      for (final setter in combinedSetters) ...setter.paramNames,
    };
    final emitted = {
      for (final param in params)
        if (!_isExcludedKind(param.kind)) param.name,
    };

    for (final group in groups) {
      final live = [
        for (final name in group.params)
          if (emitted.contains(name) &&
              !combined.contains(name) &&
              !acknowledged.contains(name))
            name,
      ];
      if (live.isEmpty) continue;
      final scope = group.isOpaque
          ? 'names no parameter of ${cls.name}, so every emitted parameter is '
              'in scope'
          : 'names ${group.params.join(', ')}';
      throw StateError(
        'surface_gen: unmodelled constructor validation — ${cls.name} '
        'validates in the BODY of ${group.displayName}, not in assert '
        'initializers, so surface_gen cannot prove a generated verb produces '
        'a value the constructor accepts. The body $scope; undischarged: '
        '${live.join(', ')}. Resolve each one by covering it with a '
        'CombinedSetter when the parameters are genuinely a unit, by naming '
        'it in ChartSurface(excluded: [...]) when no single verb could keep '
        'the invariant, or by acknowledging it with '
        "ChartSurface(bodyValidated: [BodyValidated('why...', "
        "params: ['${live.first}'])]) — omit `params` to cover the class.",
      );
    }
  }

  bool _isExcludedKind(SurfaceParamKind kind) => switch (kind) {
        SurfaceParamKind.excludedFunction ||
        SurfaceParamKind.excludedController ||
        SurfaceParamKind.excludedByAnnotation ||
        SurfaceParamKind.excludedDeprecated ||
        SurfaceParamKind.excludedNoCopyWithParam =>
          true,
        _ => false,
      };

  String _cap(String name) =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

  /// Returns the `ChartSurface` constant on [element], matched by name +
  /// shape (see library dartdoc), or `null`.
  DartObject? _chartSurfaceAnnotation(Element element) {
    for (final annotation in element.metadata.annotations) {
      final value = annotation.computeConstantValue();
      if (value == null) continue;
      final type = value.type;
      if (type is! InterfaceType || type.element.name != 'ChartSurface') {
        continue;
      }
      final matchesShape =
          _annotationFields.every((field) => value.getField(field) != null);
      if (matchesShape) return value;
    }
    return null;
  }

  List<String> _stringList(DartObject? value) => [
        for (final item in value?.toListValue() ?? const <DartObject>[])
          item.toStringValue()!,
      ];

  Map<String, String> _stringMap(DartObject? value) => {
        for (final entry
            in (value?.toMapValue() ?? const <DartObject?, DartObject?>{})
                .entries)
          entry.key!.toStringValue()!: entry.value!.toStringValue()!,
      };

  /// `ChartSurface(bodyValidated: [...])`.
  ///
  /// Read OPTIONALLY: `bodyValidated` is deliberately not part of the
  /// annotation shape the reader matches on (see the library dartdoc), so a
  /// fixture mirroring only the five original fields still matches and simply
  /// carries no acknowledgements.
  List<BodyValidationModel> _bodyValidations(DartObject? value) => [
        for (final entry in value?.toListValue() ?? const <DartObject>[])
          BodyValidationModel(
            entry.getField('reason')?.toStringValue() ?? '',
            _stringList(entry.getField('params')),
          ),
      ];

  List<CombinedSetterModel> _combinedSetters(DartObject? value) => [
        for (final setter in value?.toListValue() ?? const <DartObject>[])
          CombinedSetterModel(
            setter.getField('name')!.toStringValue()!,
            _stringList(setter.getField('params')),
          ),
      ];
}

/// Collects every simple identifier name inside an expression.
class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
