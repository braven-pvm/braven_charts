/// Tests for [AiSchemaEmitter] — the structural JSON-Schema `$defs` the AI
/// lane exposes ALONGSIDE its hand-written tool literals.
///
/// The emitter's whole value is that it cannot lie about the config surface,
/// so the tests are organized around the ways a schema generator normally
/// does: dropping a parameter that is merely un-SETTABLE, inventing a
/// constraint from an assert it did not read, and evaluating a default it can
/// only see as source text.
library;

import 'package:surface_gen/src/ai_schema_emitter.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:test/test.dart';

SurfaceParam _param(
  String name,
  String type, {
  SurfaceParamKind kind = SurfaceParamKind.value,
  bool isRequired = false,
  bool isNullable = false,
  String? defaultCode,
  String? triStatePayloadType,
  List<String> enumValues = const [],
}) =>
    SurfaceParam(
      name: name,
      dartType: type,
      kind: kind,
      isRequired: isRequired,
      isNullable: isNullable,
      defaultCode: defaultCode,
      triStatePayloadType: triStatePayloadType,
      enumValues: enumValues,
    );

SurfaceClass _cls(
  String name,
  List<SurfaceParam> params, {
  List<CombinedSetterModel> combinedSetters = const [],
  List<SurfaceAssert> asserts = const [],
  List<BodyValidationGroup> bodyValidationGroups = const [],
  List<BodyValidationModel> bodyValidations = const [],
  Map<String, String> paramNotes = const {},
  bool isSealed = false,
  List<String> sealedVariants = const [],
}) =>
    SurfaceClass(
      name: name,
      libraryUri: 'package:braven_charts/src/models/fixture.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: name,
      params: params,
      combinedSetters: combinedSetters,
      assertGroups: [for (final entry in asserts) entry.params],
      asserts: asserts,
      bodyValidationGroups: bodyValidationGroups,
      bodyValidations: bodyValidations,
      paramNotes: paramNotes,
      isSealed: isSealed,
      sealedVariants: sealedVariants,
    );

Map<String, Object?> _definition(SurfaceClass cls, [SurfaceModel? model]) =>
    const AiSchemaEmitter().definition(cls, model ?? SurfaceModel([cls]));

Map<String, Object?> _properties(Map<String, Object?> definition) =>
    definition['properties']! as Map<String, Object?>;

Map<String, Object?> _property(Map<String, Object?> definition, String name) =>
    _properties(definition)[name]! as Map<String, Object?>;

void main() {
  group('type mapping', () {
    test('primitives map to their JSON types', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('enabled', 'bool'),
        _param('count', 'int'),
        _param('ratio', 'double'),
        _param('label', 'String'),
      ]));
      expect(_property(definition, 'enabled')['type'], 'boolean');
      expect(_property(definition, 'count')['type'], 'integer');
      expect(_property(definition, 'ratio')['type'], 'number');
      expect(_property(definition, 'label')['type'], 'string');
    });

    test('Color uses the encoding ChartConfigBuilder already parses', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('color', 'Color?', isNullable: true),
      ]));
      final color = _property(definition, 'color');
      expect(color['type'], 'string');
      expect(color['description'], contains('#AARRGGBB'));
    });

    test('an enum becomes a string enum list', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('mode', 'FixtureMode',
            kind: SurfaceParamKind.enumType,
            enumValues: const ['linear', 'stepped']),
      ]));
      expect(_property(definition, 'mode'),
          containsPair('enum', ['linear', 'stepped']));
      expect(_property(definition, 'mode')['type'], 'string');
    });

    test('a nested modelled config becomes a \$ref', () {
      final style = _cls('FixtureStyle', [_param('gap', 'double')]);
      final cls = _cls('FixtureConfig', [
        _param('style', 'FixtureStyle', kind: SurfaceParamKind.nestedConfig),
      ]);
      final definition = _definition(cls, SurfaceModel([cls, style]));
      expect(_property(definition, 'style'),
          containsPair(r'$ref', r'#/$defs/FixtureStyle'));
    });

    test('an UNMODELLED type is named as opaque rather than hidden', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('textStyle', 'TextStyle?', isNullable: true),
      ]));
      final style = _property(definition, 'textStyle');
      expect(style['type'], isNull);
      expect(style['description'], contains('Opaque `TextStyle`'));
      expect(style['x-dartType'], 'TextStyle?');
    });

    test('collections carry an item schema', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('values', 'List<double>', kind: SurfaceParamKind.listValue),
        _param('lookup', 'Map<String, int>', kind: SurfaceParamKind.mapValue),
      ]));
      expect(_property(definition, 'values')['type'], 'array');
      expect(
        (_property(definition, 'values')['items']! as Map)['type'],
        'number',
      );
      expect(_property(definition, 'lookup')['type'], 'object');
      expect(
        (_property(definition, 'lookup')['additionalProperties']!
            as Map)['type'],
        'integer',
      );
    });
  });

  group('tri-state', () {
    test('becomes a {value | none | inherit} union over the payload type', () {
      final definition = _definition(_cls('FixtureStyle', [
        _param('backgroundColor', 'ChartStyleValue<Color>',
            kind: SurfaceParamKind.triState,
            triStatePayloadType: 'Color',
            defaultCode: 'const ChartStyleValue<Color>.inherit()'),
      ]));
      final property = _property(definition, 'backgroundColor');
      final union = property['oneOf']! as List;
      expect(union, hasLength(3));
      expect((union[0] as Map)['title'], 'value');
      expect((union[0] as Map)['type'], 'string');
      expect(union[1], containsPair('const', 'none'));
      expect(union[2], containsPair('const', 'inherit'));
    });

    test('an inherit default lowers to the union member, not to source text',
        () {
      final definition = _definition(_cls('FixtureStyle', [
        _param('gap', 'ChartStyleValue<double>',
            kind: SurfaceParamKind.triState,
            triStatePayloadType: 'double',
            defaultCode: 'const ChartStyleValue<double>.inherit()'),
      ]));
      expect(_property(definition, 'gap'), containsPair('default', 'inherit'));
      expect(_property(definition, 'gap').containsKey('x-defaultSource'),
          isFalse);
    });
  });

  group('exclusion-kind translation', () {
    test('callbacks, controllers and deprecated parameters are omitted and '
        'the omission is stated on the class', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('enabled', 'bool'),
        _param('onTap', 'void Function()?',
            kind: SurfaceParamKind.excludedFunction, isNullable: true),
        _param('controller', 'FixtureController?',
            kind: SurfaceParamKind.excludedController, isNullable: true),
        _param('legacy', 'double?',
            kind: SurfaceParamKind.excludedDeprecated, isNullable: true),
      ]));
      expect(_properties(definition).keys, ['enabled']);
      final description = definition['description']! as String;
      expect(description, contains('onTap (callback'));
      expect(description, contains('controller (controller'));
      expect(description, contains('legacy (deprecated)'));
    });

    test('force-excluded and no-copyWith parameters are INCLUDED and marked '
        'construction-only', () {
      final definition = _definition(_cls('FixtureSeries', [
        _param('id', 'String',
            kind: SurfaceParamKind.excludedByAnnotation, isRequired: true),
        _param('legacyWidth', 'double?',
            kind: SurfaceParamKind.excludedNoCopyWithParam, isNullable: true),
      ]));
      expect(_properties(definition).keys, ['id', 'legacyWidth']);
      expect(
        _property(definition, 'id')['x-mutation'],
        contains('construction-only'),
      );
      expect(
        _property(definition, 'legacyWidth')['x-mutation'],
        contains('copyWith has no matching parameter'),
      );
      // Still a real construction parameter, so it still counts as required.
      expect(definition['required'], ['id']);
    });
  });

  group('coupling translation', () {
    test('a combined setter over a REQUIRED member promotes the whole group '
        'into required', () {
      final definition = _definition(_cls(
        'FixturePoint',
        [
          _param('open', 'double', isRequired: true),
          _param('close', 'double', isRequired: true),
        ],
        combinedSetters: const [
          CombinedSetterModel('withOhlc', ['open', 'close']),
        ],
      ));
      expect(definition['required'], ['close', 'open']);
      expect(definition['description'],
          contains('close and open are validated together'));
    });

    test('each member names the combined setter that moves it, so "no '
        'withMinorColor verb" is machine-readable', () {
      final definition = _definition(_cls(
        'FixtureGrid',
        [
          _param('showMinor', 'bool', defaultCode: 'false'),
          _param('minorColor', 'Color?', isNullable: true),
          _param('other', 'double?', isNullable: true),
        ],
        combinedSetters: const [
          CombinedSetterModel('withMinorGrid', ['showMinor', 'minorColor']),
        ],
      ));
      expect(_property(definition, 'minorColor')['x-combinedSetter'],
          'withMinorGrid');
      expect(_property(definition, 'showMinor')['x-combinedSetter'],
          'withMinorGrid');
      expect(_property(definition, 'other').containsKey('x-combinedSetter'),
          isFalse);
    });

    test('a construction-only parameter carries x-mutation, not '
        'x-combinedSetter', () {
      final definition = _definition(_cls(
        'FixtureSeries',
        [
          _param('widthPercent', 'double?',
              kind: SurfaceParamKind.excludedByAnnotation, isNullable: true),
          _param('widthPixels', 'double?',
              kind: SurfaceParamKind.excludedByAnnotation, isNullable: true),
        ],
        combinedSetters: const [
          CombinedSetterModel('withWidth', ['widthPercent', 'widthPixels']),
        ],
      ));
      final property = _property(definition, 'widthPercent');
      expect(property.containsKey('x-mutation'), isTrue);
      expect(property.containsKey('x-combinedSetter'), isFalse);
    });

    test('an all-optional combined setter becomes dependentRequired', () {
      final definition = _definition(_cls(
        'FixtureAxis',
        [
          _param('min', 'double?', isNullable: true),
          _param('max', 'double?', isNullable: true),
        ],
        combinedSetters: const [
          CombinedSetterModel('withVisibleRange', ['min', 'max']),
        ],
      ));
      expect(definition['dependentRequired'], {
        'max': ['min'],
        'min': ['max'],
      });
      expect(definition.containsKey('anyOf'), isFalse);
    });

    test('a PROVEN null-alternation becomes anyOf', () {
      final definition = _definition(_cls(
        'FixtureSeries',
        [
          _param('widthPercent', 'double?', isNullable: true),
          _param('widthPixels', 'double?', isNullable: true),
        ],
        asserts: const [
          SurfaceAssert(['widthPercent', 'widthPixels'],
              message: 'Must specify either widthPercent or widthPixels',
              isNullAlternation: true),
        ],
      ));
      expect(definition['anyOf'], [
        {
          'required': ['widthPercent'],
        },
        {
          'required': ['widthPixels'],
        },
      ]);
      expect(definition['description'],
          contains('At least one of widthPercent and widthPixels'));
    });

    test('an assert of UNKNOWN shape states its own message and adds no '
        'constraint', () {
      // RangeAnnotation's `startX == null || endX == null || startX < endX`
      // permits both being absent, and LegendAnnotation's is "at MOST one".
      // A blanket anyOf would document both backwards.
      final definition = _definition(_cls(
        'FixtureRange',
        [
          _param('startX', 'double?', isNullable: true),
          _param('endX', 'double?', isNullable: true),
        ],
        asserts: const [
          SurfaceAssert(['endX', 'startX'],
              message: 'startX must be less than endX'),
        ],
      ));
      expect(definition.containsKey('anyOf'), isFalse);
      expect(
        definition['description'],
        contains('does not express: "startX must be less than endX"'),
      );
    });

    test('an assert already covered by a combined setter adds no anyOf', () {
      final definition = _definition(_cls(
        'FixtureAxis',
        [
          _param('min', 'double?', isNullable: true),
          _param('max', 'double?', isNullable: true),
        ],
        combinedSetters: const [
          CombinedSetterModel('withVisibleRange', ['min', 'max']),
        ],
        asserts: const [
          SurfaceAssert(['max', 'min'], isNullAlternation: true),
        ],
      ));
      expect(definition.containsKey('anyOf'), isFalse);
    });

    test('body validation contributes description only', () {
      final definition = _definition(_cls(
        'FixturePoint',
        [_param('x', 'double', isRequired: true)],
        bodyValidationGroups: const [
          BodyValidationGroup('', ['x']),
        ],
        bodyValidations: const [
          BodyValidationModel('validateValues() rejects a non-finite x.', ['x']),
        ],
      ));
      expect(definition.containsKey('anyOf'), isFalse);
      final description = definition['description']! as String;
      expect(description, contains('validates x in its body'));
      expect(description, contains('not expressed as schema constraints'));
      expect(description, contains('validateValues() rejects a non-finite x.'));
    });
  });

  group('defaults', () {
    test('JSON-shaped defaults are surfaced as `default`', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('enabled', 'bool', defaultCode: 'true'),
        _param('gap', 'double', defaultCode: '0.5'),
        _param('label', 'String', defaultCode: "'x'"),
        _param('values', 'List<double>',
            kind: SurfaceParamKind.listValue, defaultCode: 'const []'),
        _param('mode', 'FixtureMode',
            kind: SurfaceParamKind.enumType,
            enumValues: const ['linear', 'stepped'],
            defaultCode: 'FixtureMode.stepped'),
      ]));
      expect(_property(definition, 'enabled'), containsPair('default', true));
      expect(_property(definition, 'gap'), containsPair('default', 0.5));
      expect(_property(definition, 'label'), containsPair('default', 'x'));
      expect(
          _property(definition, 'values'), containsPair('default', <Object?>[]));
      expect(
          _property(definition, 'mode'), containsPair('default', 'stepped'));
    });

    test('a default only Dart can evaluate is recorded as SOURCE, never '
        'guessed at', () {
      final style = _cls('FixtureStyle', [_param('gap', 'double')]);
      final cls = _cls('FixtureConfig', [
        _param('style', 'FixtureStyle',
            kind: SurfaceParamKind.nestedConfig,
            defaultCode: 'const FixtureStyle()'),
      ]);
      final property =
          _property(_definition(cls, SurfaceModel([cls, style])), 'style');
      expect(property.containsKey('default'), isFalse);
      expect(property['x-defaultSource'], 'const FixtureStyle()');
    });
  });

  group('library emission', () {
    test('emits a const map keyed by class name, sorted', () {
      final a = _cls('ZebraConfig', [_param('enabled', 'bool')]);
      final b = _cls('AlphaConfig', [_param('enabled', 'bool')]);
      final source =
          const AiSchemaEmitter().emitLibrary(SurfaceModel([a, b]))!;
      expect(source, contains('GENERATED by surface_gen'));
      expect(
        source,
        contains('const Map<String, Object?> surfaceDefinitions'),
      );
      expect(
        source.indexOf("'AlphaConfig'"),
        lessThan(source.indexOf("'ZebraConfig'")),
      );
      expect(source, contains('// 2 classes, 2 properties.'));
    });

    test('an empty model emits nothing', () {
      expect(
        const AiSchemaEmitter().emitLibrary(const SurfaceModel([])),
        isNull,
      );
    });

    test('a `\$` in generated text is escaped so the map stays a literal', () {
      final style = _cls('FixtureStyle', [_param('gap', 'double')]);
      final cls = _cls('FixtureConfig', [
        _param('style', 'FixtureStyle', kind: SurfaceParamKind.nestedConfig),
      ]);
      final source =
          const AiSchemaEmitter().emitLibrary(SurfaceModel([cls, style]))!;
      expect(source, contains(r"'\$ref': '#/\$defs/FixtureStyle'"));
    });
  });

  group('class-level shape', () {
    test('every definition is a closed object naming its Dart library', () {
      final definition = _definition(_cls('FixtureConfig', [
        _param('enabled', 'bool'),
      ]));
      expect(definition['type'], 'object');
      expect(definition['title'], 'FixtureConfig');
      expect(definition['additionalProperties'], isFalse);
      expect(definition['x-dartLibrary'],
          'package:braven_charts/src/models/fixture.dart');
    });

    test('a paramNote reaches the property description', () {
      final definition = _definition(_cls(
        'FixtureAnnotation',
        [_param('text', 'String')],
        paramNotes: const {'text': 'No-op on a rich annotation.'},
      ));
      expect(_property(definition, 'text')['description'],
          contains('No-op on a rich annotation.'));
    });

    test('a sealed base lists its variants', () {
      final definition = _definition(_cls(
        'FixturePresentation',
        [_param('enabled', 'bool')],
        isSealed: true,
        sealedVariants: const ['FixtureOverlay', 'FixtureInline'],
      ));
      expect(definition['description'],
          contains('variants: FixtureOverlay, FixtureInline'));
    });
  });
}
