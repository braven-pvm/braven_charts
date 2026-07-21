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
/// 2. function-typed (including typedef aliases) → [SurfaceParamKind.excludedFunction]
/// 3. `*Controller`-named type, `Listenable`, or any type whose supertype
///    walk contains a type named `Listenable` → [SurfaceParamKind.excludedController]
/// 4. `ChartStyleValue<X>` → [SurfaceParamKind.triState] (payload `X`)
/// 5. enum type → [SurfaceParamKind.enumType] with member names
/// 6. type annotated `@chartSurface` (anywhere) → [SurfaceParamKind.nestedConfig]
/// 7. `List<...>` / `Map<...>` → [SurfaceParamKind.listValue] / [SurfaceParamKind.mapValue]
/// 8. otherwise → [SurfaceParamKind.value]
///
/// Notably: an annotated config class whose name ends in `Controller` is
/// still excluded (rule 3 precedes rule 6) — explicit exclusion semantics
/// beat nesting.
///
/// Default expressions are captured as SOURCE STRINGS from
/// `defaultValueCode`, never evaluated.
library;

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
      classes.add(_readClass(cls, annotation));
    }
    return SurfaceModel(classes);
  }

  SurfaceClass _readClass(ClassElement cls, DartObject annotation) {
    final excluded = _stringList(annotation.getField('excluded')).toSet();
    final clearFlags = _stringMap(annotation.getField('clearFlags'));
    final constructor = _selectConstructor(cls);
    return SurfaceClass(
      name: cls.name!,
      libraryUri: cls.library.uri.toString(),
      isConstConstructible: constructor.isConst,
      hasCopyWith: _hasInstanceCopyWith(cls),
      params: [
        for (final parameter in constructor.formalParameters)
          _readParam(parameter, excluded: excluded, clearFlags: clearFlags),
      ],
      sealedVariants: _stringList(annotation.getField('sealedVariants')),
      presetFactories: _stringList(annotation.getField('presetFactories')),
      combinedSetters: _combinedSetters(annotation.getField('combinedSetters')),
      isSealed: cls.isSealed,
    );
  }

  /// Selects the constructor to read, per the library-level dartdoc.
  ConstructorElement _selectConstructor(ClassElement cls) {
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
    throw StateError(
      'surface_gen: class ${cls.name} is annotated @chartSurface but exposes '
      'no readable constructor. Expected a const unnamed constructor, a '
      'private const constructor named `_internal`, or a non-const unnamed '
      'constructor.',
    );
  }

  SurfaceParam _readParam(
    FormalParameterElement parameter, {
    required Set<String> excluded,
    required Map<String, String> clearFlags,
  }) {
    final name = parameter.name!;
    final type = parameter.type;

    var kind = SurfaceParamKind.value;
    String? triStatePayloadType;
    var enumValues = const <String>[];

    if (excluded.contains(name)) {
      kind = SurfaceParamKind.excludedByAnnotation;
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
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      defaultCode: parameter.defaultValueCode,
      triStatePayloadType: triStatePayloadType,
      clearFlag: clearFlags[name],
      enumValues: enumValues,
    );
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

  /// Whether [cls] declares or inherits an instance `copyWith` method.
  bool _hasInstanceCopyWith(ClassElement cls) {
    bool declares(InterfaceElement element) => element.methods
        .any((method) => method.name == 'copyWith' && !method.isStatic);
    if (declares(cls)) return true;
    return cls.allSupertypes.any((supertype) => declares(supertype.element));
  }

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
