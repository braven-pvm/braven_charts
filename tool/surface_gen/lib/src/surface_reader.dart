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
/// - **slicing copyWith** — an annotated class whose `copyWith` returns the
///   class itself while a SUBCLASS overrides `copyWith`. Generated `withX`
///   verbs would be typed to the base and silently discard subclass state
///   (`ChartSeries` is exactly this shape). Fix by annotating
///   `@ChartSurfaceExempt(reason)` or making `copyWith` abstract.
/// - **assert-coupled parameters** — a multi-parameter constructor assert not
///   covered by a `CombinedSetter`. Individual setters would let a chain step
///   construct a value the assert rejects (`BarChartSeries(...).withMinWidth(200)`
///   throws today).
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

import 'surface_model.dart';

/// Reads a resolved library into a [SurfaceModel].
abstract interface class SurfaceReader {
  /// Reads every `@chartSurface`-annotated class of [library].
  Future<SurfaceModel> read(LibraryElement library);
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
  Future<SurfaceModel> read(LibraryElement library) async {
    final classes = <SurfaceClass>[];
    for (final cls in library.classes) {
      final annotation = _chartSurfaceAnnotation(cls);
      if (annotation == null) continue;
      classes.add(_readClass(cls, annotation, library));
    }
    return SurfaceModel(classes);
  }

  SurfaceClass _readClass(
    ClassElement cls,
    DartObject annotation,
    LibraryElement library,
  ) {
    final excluded = _stringList(annotation.getField('excluded')).toSet();
    final clearFlagOverrides = _stringMap(annotation.getField('clearFlags'));
    final constructor = _selectConstructor(cls);
    final copyWith = _findCopyWith(cls);
    final isConstConstructible = constructor?.isConst ??
        cls.constructors.any((c) => c.isGenerative && c.isConst);

    _checkSlicingCopyWith(cls, copyWith, library);

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
    final assertGroups = _assertGroups(constructor, params, library);
    _checkAssertCoverage(cls, assertGroups, combinedSetters, params);

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
      params: params,
      sealedVariants: sealedVariants,
      presetFactories: _stringList(annotation.getField('presetFactories')),
      combinedSetters: combinedSetters,
      isSealed: cls.isSealed,
    );
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
  void _checkSlicingCopyWith(
    ClassElement cls,
    MethodElement? copyWith,
    LibraryElement library,
  ) {
    if (copyWith == null || copyWith.isAbstract) return;
    if (copyWith.enclosingElement != cls) return;
    if (copyWith.returnType.getDisplayString() != cls.name) return;

    final overriding = <String>[];
    for (final candidate in library.classes) {
      if (identical(candidate, cls)) continue;
      final inherits =
          candidate.allSupertypes.any((supertype) => supertype.element == cls);
      if (!inherits) continue;
      final own = candidate.methods
          .any((method) => method.name == 'copyWith' && !method.isStatic);
      if (own) overriding.add(candidate.name ?? '<unnamed>');
    }
    if (overriding.isEmpty) return;

    throw StateError(
      'surface_gen: slicing copyWith — ${cls.name}.copyWith returns '
      '${cls.name} while ${overriding.join(', ')} override copyWith. '
      'Generated ${cls.name}Fluent verbs would be typed to ${cls.name} and '
      'silently discard subclass state whenever the static type is '
      '${cls.name}. Annotate @ChartSurfaceExempt(reason) on ${cls.name} and '
      'model the concrete subtypes instead, or make ${cls.name}.copyWith '
      'abstract.',
    );
  }

  /// Constructor-initializer asserts naming two or more parameters.
  ///
  /// Only CONST constructors carry their initializers into the element model
  /// (`constantInitializers` exists for constant evaluation). Const-ness is
  /// not part of the enforcement rule, though, and the whole annotation
  /// family has a NON-const unnamed constructor because it defaults `id`
  /// through `super(id: id ?? ChartAnnotation.generateId())`. Their asserts
  /// couple parameters exactly as hard, so when the element model is empty the
  /// declaration is parsed and its initializers read from the AST.
  List<List<String>> _assertGroups(
    ConstructorElement? constructor,
    List<SurfaceParam> params,
    LibraryElement library,
  ) {
    if (constructor == null) return const [];
    final initializers = _initializers(constructor, library);
    if (initializers.isEmpty) return const [];
    final names = {for (final param in params) param.name};
    final groups = <String, List<String>>{};
    for (final initializer in initializers) {
      if (initializer is! AssertInitializer) continue;
      final visitor = _IdentifierCollector();
      initializer.condition.accept(visitor);
      final referenced = (visitor.names.intersection(names).toList())..sort();
      if (referenced.length < 2) continue;
      groups[referenced.join(',')] = referenced;
    }
    final result = groups.values.toList()
      ..sort((a, b) => a.join(',').compareTo(b.join(',')));
    return result;
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
    final parsed = library.session.getParsedLibraryByElement(library);
    if (parsed is! ParsedLibraryResult) return const [];
    final node = parsed.getFragmentDeclaration(constructor.firstFragment)?.node;
    if (node is! ConstructorDeclaration) return const [];
    return node.initializers;
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
