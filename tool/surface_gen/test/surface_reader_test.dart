import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:surface_gen/src/surface_reader.dart';
import 'package:test/test.dart';

/// Exhaustive expectation for one constructor parameter.
class ParamExpectation {
  const ParamExpectation(
    this.name, {
    required this.dartType,
    required this.kind,
    this.isRequired = false,
    this.isNullable = false,
    this.defaultCode,
    this.triStatePayloadType,
    this.clearFlag,
    this.enumValues = const <String>[],
  });

  final String name;
  final String dartType;
  final SurfaceParamKind kind;
  final bool isRequired;
  final bool isNullable;
  final String? defaultCode;
  final String? triStatePayloadType;
  final String? clearFlag;
  final List<String> enumValues;
}

const fixtureAsset = 'surface_gen|test/fixtures/fixture_configs.dart';
const fixtureUri = 'asset:surface_gen/test/fixtures/fixture_configs.dart';

const fixtureModeValues = ['off', 'auto', 'on'];

/// Every parameter of every fixture class, asserted exhaustively.
const crosshairParams = <ParamExpectation>[
  ParamExpectation(
    'id',
    dartType: 'String',
    kind: SurfaceParamKind.value,
    isRequired: true,
  ),
  ParamExpectation(
    'enabled',
    dartType: 'bool',
    kind: SurfaceParamKind.value,
    defaultCode: 'true',
  ),
  ParamExpectation(
    'mode',
    dartType: 'FixtureMode',
    kind: SurfaceParamKind.enumType,
    defaultCode: 'FixtureMode.auto',
    enumValues: fixtureModeValues,
  ),
  ParamExpectation(
    'snapRadius',
    dartType: 'double',
    kind: SurfaceParamKind.value,
    defaultCode: '20.0',
  ),
  ParamExpectation(
    'min',
    dartType: 'double?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'max',
    dartType: 'double?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'label',
    dartType: 'String?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'nested',
    dartType: 'FixtureNestedStyle',
    kind: SurfaceParamKind.nestedConfig,
    defaultCode: 'const FixtureNestedStyle()',
  ),
  ParamExpectation(
    'presentation',
    dartType: 'FixturePresentation',
    kind: SurfaceParamKind.nestedConfig,
    defaultCode: 'const FixtureOverlayPresentation()',
  ),
  ParamExpectation(
    'accentColor',
    dartType: 'ChartStyleValue<double>',
    kind: SurfaceParamKind.triState,
    defaultCode: 'const ChartStyleValue<double>.inherit()',
    triStatePayloadType: 'double',
  ),
  ParamExpectation(
    'panelText',
    dartType: 'ChartStyleValue<String>',
    kind: SurfaceParamKind.triState,
    defaultCode: 'const ChartStyleValue<String>.inherit()',
    triStatePayloadType: 'String',
  ),
  ParamExpectation(
    'onTap',
    dartType: 'void Function()?',
    kind: SurfaceParamKind.excludedFunction,
    isNullable: true,
  ),
  ParamExpectation(
    'formatter',
    // Typedef aliases display structurally in analyzer 12
    // (getDisplayString() does not expose preferTypeAlias).
    dartType: 'String Function(double)?',
    kind: SurfaceParamKind.excludedFunction,
    isNullable: true,
  ),
  ParamExpectation(
    'syncNotifier',
    dartType: 'FixtureSyncNotifier?',
    kind: SurfaceParamKind.excludedController,
    isNullable: true,
  ),
  ParamExpectation(
    'panController',
    dartType: 'FixturePanController?',
    kind: SurfaceParamKind.excludedController,
    isNullable: true,
  ),
  ParamExpectation(
    'overlayStyle',
    dartType: 'FixtureNestedStyle?',
    kind: SurfaceParamKind.nestedConfig,
    isNullable: true,
    clearFlag: 'clearOverlayStyle',
  ),
  ParamExpectation(
    'highlightText',
    dartType: 'String?',
    kind: SurfaceParamKind.value,
    isNullable: true,
    clearFlag: 'clearHighlightText',
  ),
  ParamExpectation(
    'dashPattern',
    dartType: 'List<double>',
    kind: SurfaceParamKind.listValue,
    defaultCode: 'const <double>[2, 6]',
  ),
  ParamExpectation(
    'metadata',
    dartType: 'Map<String, int>',
    kind: SurfaceParamKind.mapValue,
    defaultCode: 'const <String, int>{}',
  ),
  ParamExpectation(
    'debugTag',
    dartType: 'String?',
    kind: SurfaceParamKind.excludedByAnnotation,
    isNullable: true,
  ),
];

/// FixtureAxisConfig params come from the private const `_internal`
/// constructor (the public unnamed constructor is non-const).
const axisParams = <ParamExpectation>[
  ParamExpectation(
    'id',
    dartType: 'String',
    kind: SurfaceParamKind.excludedByAnnotation,
    isRequired: true,
  ),
  ParamExpectation(
    'mode',
    dartType: 'FixtureMode',
    kind: SurfaceParamKind.enumType,
    isRequired: true,
    enumValues: fixtureModeValues,
  ),
  ParamExpectation(
    'label',
    dartType: 'String?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'min',
    dartType: 'double?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'max',
    dartType: 'double?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'visible',
    dartType: 'bool',
    kind: SurfaceParamKind.value,
    defaultCode: 'true',
  ),
  ParamExpectation(
    'minWidth',
    dartType: 'double',
    kind: SurfaceParamKind.value,
    defaultCode: '0.0',
  ),
];

const nestedStyleParams = <ParamExpectation>[
  ParamExpectation(
    'opacity',
    dartType: 'double',
    kind: SurfaceParamKind.value,
    defaultCode: '1.0',
  ),
];

const mutableConfigParams = <ParamExpectation>[
  ParamExpectation(
    'scale',
    dartType: 'double',
    kind: SurfaceParamKind.value,
    defaultCode: '1.0',
  ),
];

/// `tint` has no counterpart on the INHERITED `copyWith`, so it is dropped
/// and recorded rather than emitted as an `undefined_named_parameter`.
const inheritedStyleParams = <ParamExpectation>[
  ParamExpectation(
    'opacity',
    dartType: 'double',
    kind: SurfaceParamKind.value,
    defaultCode: '1.0', // inherited through the super parameter
  ),
  ParamExpectation(
    'tint',
    dartType: 'int',
    kind: SurfaceParamKind.excludedNoCopyWithParam,
    defaultCode: '0',
  ),
];

/// Super parameters must resolve through the super constructor's types.
const lineSeriesParams = <ParamExpectation>[
  ParamExpectation(
    'id',
    dartType: 'String',
    kind: SurfaceParamKind.value,
    isRequired: true,
  ),
  ParamExpectation(
    'name',
    dartType: 'String?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'unit',
    dartType: 'String?',
    kind: SurfaceParamKind.value,
    isNullable: true,
  ),
  ParamExpectation(
    'ordered',
    dartType: 'bool',
    kind: SurfaceParamKind.value,
    defaultCode: 'false',
  ),
  ParamExpectation(
    'strokeWidth',
    dartType: 'double',
    kind: SurfaceParamKind.value,
    defaultCode: '2.0',
  ),
  ParamExpectation(
    'interpolation',
    dartType: 'FixtureMode',
    kind: SurfaceParamKind.enumType,
    defaultCode: 'FixtureMode.auto',
    enumValues: fixtureModeValues,
  ),
  ParamExpectation(
    'dashPattern',
    dartType: 'List<double>',
    kind: SurfaceParamKind.listValue,
    defaultCode: 'const <double>[]',
  ),
];

void main() {
  late SurfaceModel model;

  setUpAll(() async {
    final content = _fixtureContent();
    model = await resolveSources(
      {fixtureAsset: content},
      (resolver) async {
        final library = await resolver.libraryFor(AssetId.parse(fixtureAsset));
        return const AnalyzerSurfaceReader().read(library);
      },
    );
  });

  test('reads exactly the annotated classes', () {
    expect(
      model.classes.map((c) => c.name),
      unorderedEquals([
        'FixtureNestedStyle',
        'FixtureInheritedStyle',
        'FixturePresentation',
        'FixtureCrosshairConfig',
        'FixtureAxisConfig',
        'FixtureMutableConfig',
        'FixtureLineSeries',
      ]),
    );
  });

  group('SurfaceModel.byName', () {
    test('returns the class with the given name', () {
      expect(model.byName('FixtureNestedStyle').name, 'FixtureNestedStyle');
    });

    test('throws ArgumentError for unknown names', () {
      expect(() => model.byName('NoSuchConfig'), throwsArgumentError);
    });
  });

  _classGroup(
    () => model,
    name: 'FixtureCrosshairConfig',
    isConstConstructible: true,
    hasCopyWith: true,
    isSealed: false,
    presetFactories: ['tracking', 'defaultConfig'],
    sealedVariants: [],
    combinedSetters: {
      'withVisibleRange': ['min', 'max'],
    },
    params: crosshairParams,
  );

  _classGroup(
    () => model,
    name: 'FixtureAxisConfig',
    isConstConstructible: true, // read from the private const `_internal`
    hasCopyWith: true,
    isSealed: false,
    presetFactories: ['withId'],
    sealedVariants: [],
    combinedSetters: {
      'withVisibleRange': ['min', 'max'],
    },
    params: axisParams,
  );

  _classGroup(
    () => model,
    name: 'FixtureNestedStyle',
    isConstConstructible: true,
    hasCopyWith: true,
    isSealed: false,
    presetFactories: [],
    sealedVariants: [],
    combinedSetters: {},
    params: nestedStyleParams,
  );

  _classGroup(
    () => model,
    name: 'FixturePresentation',
    isConstConstructible: true,
    hasCopyWith: false,
    isSealed: true,
    presetFactories: [],
    sealedVariants: [
      'FixtureOverlayPresentation',
      'FixtureAnnotationPresentation',
    ],
    combinedSetters: {},
    params: [],
  );

  _classGroup(
    () => model,
    name: 'FixtureMutableConfig',
    isConstConstructible: false, // unnamed ctor is non-const, no _internal
    hasCopyWith: true,
    isSealed: false,
    presetFactories: [],
    sealedVariants: [],
    combinedSetters: {},
    params: mutableConfigParams,
  );

  _classGroup(
    () => model,
    name: 'FixtureInheritedStyle',
    isConstConstructible: true,
    hasCopyWith: true, // inherited from FixtureNestedStyle
    copyWithReturnType: 'FixtureNestedStyle',
    isSealed: false,
    presetFactories: [],
    sealedVariants: [],
    combinedSetters: {},
    params: inheritedStyleParams,
  );

  _classGroup(
    () => model,
    name: 'FixtureLineSeries',
    isConstConstructible: true,
    hasCopyWith: true,
    isSealed: false,
    presetFactories: [],
    sealedVariants: [],
    combinedSetters: {},
    params: lineSeriesParams,
  );

  group('constructor selection failures', () {
    test('annotated class with only factory/private-named ctors throws', () async {
      const asset = 'surface_gen|test/fixtures/factory_only.dart';
      await resolveSources(
        {asset: _factoryOnlySource},
        (resolver) async {
          final library = await resolver.libraryFor(AssetId.parse(asset));
          await expectLater(
            const AnalyzerSurfaceReader().read(library),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('FixtureFactoryOnly'),
              ),
            ),
          );
        },
      );
    });
  });

  group('annotation matching (name + shape, library-agnostic)', () {
    test('a ChartSurface class of the wrong shape is ignored', () async {
      const asset = 'surface_gen|test/fixtures/foreign_annotation.dart';
      final foreign = await resolveSources(
        {asset: _foreignAnnotationSource},
        (resolver) async {
          final library = await resolver.libraryFor(AssetId.parse(asset));
          return const AnalyzerSurfaceReader().read(library);
        },
      );
      expect(foreign.classes, isEmpty);
    });
  });

  test('libraryUri records the defining library', () {
    for (final cls in model.classes) {
      expect(cls.libraryUri, fixtureUri, reason: cls.name);
    }
  });
}

/// Registers a group asserting every class-level field and every parameter of
/// [name] exhaustively (field-by-field, in declared order).
void _classGroup(
  SurfaceModel Function() model, {
  required String name,
  required bool isConstConstructible,
  required bool hasCopyWith,
  required bool isSealed,
  required List<String> presetFactories,
  required List<String> sealedVariants,
  required Map<String, List<String>> combinedSetters,
  required List<ParamExpectation> params,
  String? copyWithReturnType,
}) {
  group(name, () {
    late SurfaceClass cls;

    setUp(() => cls = model().byName(name));

    test('class-level shape', () {
      expect(cls.name, name);
      expect(cls.isConstConstructible, isConstConstructible,
          reason: 'isConstConstructible');
      expect(cls.hasCopyWith, hasCopyWith, reason: 'hasCopyWith');
      expect(
        cls.copyWithReturnType,
        hasCopyWith ? (copyWithReturnType ?? name) : isNull,
        reason: 'copyWithReturnType',
      );
      expect(cls.isSealed, isSealed, reason: 'isSealed');
      expect(cls.presetFactories, presetFactories, reason: 'presetFactories');
      expect(cls.sealedVariants, sealedVariants, reason: 'sealedVariants');
      expect(
        {for (final s in cls.combinedSetters) s.name: s.paramNames},
        combinedSetters,
        reason: 'combinedSetters',
      );
    });

    test('declares parameters in constructor order', () {
      expect(
        cls.params.map((p) => p.name).toList(),
        params.map((p) => p.name).toList(),
      );
    });

    for (final expected in params) {
      test('param ${expected.name}', () {
        final param = cls.params.singleWhere((p) => p.name == expected.name);
        expect(param.dartType, expected.dartType, reason: 'dartType');
        expect(param.kind, expected.kind, reason: 'kind');
        expect(param.isRequired, expected.isRequired, reason: 'isRequired');
        expect(param.isNullable, expected.isNullable, reason: 'isNullable');
        expect(param.defaultCode, expected.defaultCode, reason: 'defaultCode');
        expect(
          param.triStatePayloadType,
          expected.triStatePayloadType,
          reason: 'triStatePayloadType',
        );
        expect(param.clearFlag, expected.clearFlag, reason: 'clearFlag');
        expect(param.enumValues, expected.enumValues, reason: 'enumValues');
      });
    }
  });
}

/// Loads the fixture library source. The file is a real, analyzable Dart
/// library; its content is fed to the in-memory resolver so the annotations
/// it mirrors are defined INSIDE the resolved sources (surface_gen has no
/// dependency on the Flutter package).
String _fixtureContent() {
  const relative = 'test/fixtures/fixture_configs.dart';
  final candidates = [relative, 'tool/surface_gen/$relative'];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
  }
  throw StateError('fixture_configs.dart not found from ${Directory.current}');
}

/// An annotated class with no const unnamed ctor, no `_internal`, and no
/// non-const unnamed ctor: the reader must fail loudly.
const _factoryOnlySource = '''
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],
    this.sealedVariants = const <String>[],
    this.combinedSetters = const <Object>[],
    this.excluded = const <String>[],
    this.clearFlags = const <String, String>{},
  });
  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<Object> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
}

const chartSurface = ChartSurface();

@chartSurface
class FixtureFactoryOnly {
  factory FixtureFactoryOnly.make() => FixtureFactoryOnly._(1);
  FixtureFactoryOnly._(this.v);
  final int v;
}
''';

/// A `ChartSurface` annotation matching by name but NOT by shape (missing the
/// five metadata fields): must be ignored, not treated as a surface marker.
const _foreignAnnotationSource = '''
class ChartSurface {
  const ChartSurface();
}

@ChartSurface()
class NotOurConfig {
  const NotOurConfig({this.a = 1});
  final int a;
  NotOurConfig copyWith({int? a}) => NotOurConfig(a: a ?? this.a);
}
''';
