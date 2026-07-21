/// Tests for the exhaustive smoke emitter (Task 6, Scope D; Slice 2 review
/// finding S3).
///
/// The emitted file has two jobs and the tests are split the same way:
///
/// - it must EXECUTE every generated verb it can, on a real instance, and
///   fail when one throws — the original emitter only compiled its cases,
///   which is precisely why five classes shipped verbs that threw;
/// - it must still fail COMPILATION when a generated verb does not type-check
///   against its owner, including for the verbs whose argument type has no
///   synthesizable value and which therefore cannot be executed.
library;

import 'package:surface_gen/src/emitter.dart';
import 'package:surface_gen/src/smoke_emitter.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:test/test.dart';

SurfaceParam _param(
  String name,
  String type, {
  SurfaceParamKind kind = SurfaceParamKind.value,
  bool isRequired = false,
  bool isNullable = false,
  bool isNamed = true,
  bool readsBackNullable = false,
  String? clearFlag,
  String? defaultCode,
  String? triStatePayloadType,
  List<String> enumValues = const [],
  Map<String, String> typeOrigins = const {},
}) =>
    SurfaceParam(
      name: name,
      dartType: type,
      kind: kind,
      isRequired: isRequired,
      isNullable: isNullable,
      isNamed: isNamed,
      readsBackNullable: readsBackNullable,
      defaultCode: defaultCode,
      clearFlag: clearFlag,
      triStatePayloadType: triStatePayloadType,
      enumValues: enumValues,
      typeOrigins: typeOrigins,
    );

SurfaceClass _cls(
  String name,
  List<SurfaceParam> params, {
  bool hasCopyWith = true,
  String? copyWithReturnType,
  List<CombinedSetterModel> combinedSetters = const [],
  List<String> typeParameters = const [],
  List<SurfaceParam>? unnamedConstructorParams,
}) =>
    SurfaceClass(
      name: name,
      libraryUri: 'package:braven_charts/src/models/fixture.dart',
      isConstConstructible: true,
      hasCopyWith: hasCopyWith,
      copyWithReturnType: copyWithReturnType ?? (hasCopyWith ? name : null),
      params: params,
      combinedSetters: combinedSetters,
      typeParameters: typeParameters,
      unnamedConstructorParams: unnamedConstructorParams ?? params,
    );

/// Collapses runs of whitespace so an assertion is not hostage to where
/// dart_style chose to wrap a line.
String _collapse(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ');

void main() {
  const emitter = SmokeEmitter();

  group('argument synthesis', () {
    test('canonical literals cover the primitive types', () {
      final cls = _cls('FixtureConfig', [
        _param('enabled', 'bool'),
        _param('count', 'int'),
        _param('ratio', 'double'),
        _param('label', 'String'),
        _param('delay', 'Duration'),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(
        source,
        contains('void _smokeFixtureConfig(_Verb verb, FixtureConfig subject)'),
      );
      expect(source, contains('subject.withEnabled(true)'));
      expect(source, contains('subject.withCount(2)'));
      expect(source, contains('subject.withRatio(1.0)'));
      expect(source, contains("subject.withLabel('y')"));
      expect(
        source,
        contains('subject.withDelay(const Duration(milliseconds: 1))'),
      );
    });

    test('every verb is invoked through the recorder, labelled by owner',
        () {
      final cls = _cls('FixtureConfig', [_param('enabled', 'bool')]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains(
          "verb('FixtureConfigFluent.withEnabled', "
          '() => subject.withEnabled(true));',
        ),
      );
    });

    test('a parameter with a DEFAULT is probed with that default, which the '
        'class has already accepted', () {
      final style = _cls('FixtureStyle', [_param('gap', 'double')]);
      final cls = _cls('FixtureConfig', [
        _param('ratio', 'double', defaultCode: '0.95'),
        _param('style', 'FixtureStyle', defaultCode: 'const FixtureStyle()'),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls, style]));
      expect(source, contains('subject.withRatio(0.95)'));
      expect(source, contains('subject.withStyle(const FixtureStyle())'));
    });

    test('a default rooted on a name the smoke library cannot resolve is not '
        'used — `Colors` lives in material.dart', () {
      final cls = _cls('FixtureStyle', [
        _param(
          'textStyle',
          'TextStyle',
          defaultCode: 'const TextStyle(color: Colors.black)',
          typeOrigins: {'TextStyle': 'package:flutter/src/painting/x.dart'},
        ),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains('subject.withTextStyle(const TextStyle())'),
      );
    });

    test('a default referring to a PRIVATE name is not used', () {
      final cls = _cls('FixtureConfig', [
        _param('ratio', 'double', defaultCode: '_kDefaultRatio'),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains('subject.withRatio(1.0)'),
      );
    });

    test('an enum uses its own first value', () {
      final cls = _cls('FixtureConfig', [
        _param(
          'mode',
          'FixtureMode',
          kind: SurfaceParamKind.enumType,
          enumValues: ['a', 'b'],
        ),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains('subject.withMode(FixtureMode.values.first)'),
      );
    });

    test('collections become empty literals of the declared type', () {
      final cls = _cls('FixtureConfig', [
        _param('values', 'List<double>', kind: SurfaceParamKind.listValue),
        _param('lookup', 'Map<String, double>', kind: SurfaceParamKind.mapValue),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withValues(const <double>[])'));
      expect(source, contains('subject.withLookup(const <String, double>{})'));
    });

    test('the Flutter types with a canonical value are synthesized, not '
        'parameterised', () {
      final cls = _cls('FixtureStyle', [
        _param('color', 'Color'),
        _param('textStyle', 'TextStyle'),
        _param('padding', 'EdgeInsets'),
        _param('curve', 'Curve'),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withColor(const Color(0xFF2196F3))'));
      expect(source, contains('subject.withTextStyle(const TextStyle())'));
      expect(source, contains('subject.withPadding(EdgeInsets.zero)'));
      expect(source, contains('subject.withCurve(Curves.linear)'));
    });

    test('a nested modelled config is constructed from its own required '
        'parameters', () {
      final nested = _cls('FixtureNested', [
        _param('id', 'String', isRequired: true),
        _param('gap', 'double', defaultCode: '1.0'),
      ]);
      final owner = _cls('FixtureOwner', [
        _param('nested', 'FixtureNested', kind: SurfaceParamKind.nestedConfig),
      ]);
      expect(
        emitter.emit(owner, SurfaceModel([owner, nested])),
        contains("subject.withNested(FixtureNested(id: 'y'))"),
      );
    });

    test('a type with no synthesizable value falls back to a COMPILE-ONLY '
        'case rather than being dropped', () {
      final cls = _cls('FixtureSeries', [
        _param('enabled', 'bool'),
        _param('gradient', 'AreaGradient'),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withEnabled(true)'));
      expect(
        source,
        contains('void _compileFixtureSeries(FixtureSeries subject, '
            'AreaGradient a0)'),
      );
      expect(source, contains('subject.withGradient(a0);'));
    });
  });

  group('verb families', () {
    test('a tri-state parameter yields with/without/inherit', () {
      final cls = _cls('FixtureStyle', [
        _param(
          'backgroundColor',
          'ChartStyleValue<Color>',
          kind: SurfaceParamKind.triState,
          triStatePayloadType: 'Color',
        ),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(
        source,
        contains('subject.withBackgroundColor(const Color(0xFF2196F3))'),
      );
      expect(source, contains('subject.withoutBackgroundColor()'));
      expect(source, contains('subject.inheritBackgroundColor()'));
    });

    test('a tri-state parameter ignores its ChartStyleValue default', () {
      final cls = _cls('FixtureStyle', [
        _param(
          'width',
          'ChartStyleValue<double>',
          kind: SurfaceParamKind.triState,
          triStatePayloadType: 'double',
          defaultCode: 'const ChartStyleValue<double>.inherit()',
        ),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains('subject.withWidth(1.0)'),
      );
    });

    test('a derived clear flag yields clearX', () {
      final cls = _cls('FixtureConfig', [
        _param('label', 'String?', isNullable: true, clearFlag: 'clearLabel'),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains('subject.clearLabel()'),
      );
    });

    test('a non-nullable nested config yields updateX', () {
      final nested = _cls('FixtureNested', [_param('gap', 'double')]);
      final owner = _cls('FixtureOwner', [
        _param('nested', 'FixtureNested', kind: SurfaceParamKind.nestedConfig),
      ]);
      expect(
        emitter.emit(owner, SurfaceModel([owner, nested])),
        contains('subject.updateNested((current) => current)'),
      );
    });

    test('a combined setter over NON-NULLABLE members replays the subject\'s '
        'own values, which the constructor has already accepted', () {
      final cls = _cls(
        'FixturePoint',
        [
          _param('open', 'double', isRequired: true),
          _param('high', 'double', isRequired: true),
        ],
        combinedSetters: [
          const CombinedSetterModel('withOhlc', ['open', 'high']),
        ],
      );
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(
        source,
        contains('subject.withOhlc(subject.open, subject.high)'),
      );
      expect(source, isNot(contains('subject.withOpen(')));
    });

    test('a combined setter over NULLABLE numeric members probes ASCENDING '
        'values, so a `min < max` assert is satisfied', () {
      final cls = _cls(
        'FixtureAxis',
        [
          _param('min', 'double?', isNullable: true),
          _param('max', 'double?', isNullable: true),
        ],
        combinedSetters: [
          const CombinedSetterModel('withRange', ['min', 'max']),
        ],
      );
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withRange(1.0, 2.0)'));
      expect(source, isNot(contains('subject.withMin(')));
    });

    test('a combined setter whose NON-NULLABLE members read back NULLABLE '
        'probes instead of replaying — the RangeAreaDataPoint shape', () {
      // RangeAreaDataPoint(low: double, high: double) stores `double? low` /
      // `double? high` because `.gap()` leaves both null. Replaying
      // `subject.low` emitted `withInterval(subject.low, subject.high)`,
      // which does not compile: "The argument type 'double?' can't be
      // assigned to the parameter type 'double'".
      final cls = _cls(
        'FixtureInterval',
        [
          _param('low', 'double', isRequired: true, readsBackNullable: true),
          _param('high', 'double', isRequired: true, readsBackNullable: true),
        ],
        combinedSetters: [
          const CombinedSetterModel('withInterval', ['low', 'high']),
        ],
      );
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withInterval(1.0, 2.0)'));
      expect(source, isNot(contains('subject.low')));
      expect(source, isNot(contains('subject.high')));
    });

    test('the `is` prefix is dropped exactly as the fluent emitter does', () {
      final cls = _cls('FixtureSeries', [_param('isXOrdered', 'bool')]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withXOrdered(true)'));
      expect(source, isNot(contains('withIsXOrdered')));
    });
  });

  group('subjects', () {
    test('a subject is built from the PUBLIC unnamed constructor, not the '
        'selected one — the YAxisConfig shape', () {
      final cls = _cls(
        'FixtureAxis',
        [
          _param('id', 'String',
              isRequired: true, kind: SurfaceParamKind.excludedByAnnotation),
          _param('gap', 'double'),
        ],
        unnamedConstructorParams: [
          _param(
            'position',
            'FixturePosition',
            isRequired: true,
            kind: SurfaceParamKind.enumType,
            enumValues: ['left', 'right'],
          ),
          _param('gap', 'double'),
        ],
      );
      final source = emitter.emitLibrary(SurfaceModel([cls]))!;
      expect(
        source,
        contains('FixtureAxis(position: FixturePosition.values.first)'),
      );
    });

    test('a subject uses BASE literals so a verb probe differs from it', () {
      final cls = _cls('FixturePoint', [
        _param('x', 'double', isRequired: true),
      ]);
      final source = emitter.emitLibrary(SurfaceModel([cls]))!;
      expect(source, contains('FixturePoint(x: 0.5)'));
      expect(source, contains('subject.withX(1.0)'));
    });

    test('positional required parameters are passed positionally', () {
      final cls = _cls('FixtureSpan', [
        _param('start', 'double', isRequired: true, isNamed: false),
        _param('end', 'double', isRequired: true, isNamed: false),
      ]);
      expect(
        emitter.emitLibrary(SurfaceModel([cls]))!,
        contains('FixtureSpan(0.5, 0.5)'),
      );
    });

    test('a class whose required parameter has no synthesizable value is '
        'SKIPPED with a reason naming it', () {
      final cls = _cls('FixtureSeries', [
        _param('gradient', 'AreaGradient', isRequired: true),
        _param('enabled', 'bool'),
      ]);
      final source = emitter.emitLibrary(SurfaceModel([cls]))!;
      expect(
        _collapse(source),
        contains("skip: 'no synthesizable subject: required parameter "
            "`gradient` of type AreaGradient'"),
      );
    });

    test('a class with no public unnamed constructor is SKIPPED with a '
        'reason', () {
      final cls = SurfaceClass(
        name: 'FixtureInternal',
        libraryUri: 'package:braven_charts/src/models/fixture.dart',
        isConstConstructible: true,
        hasCopyWith: true,
        copyWithReturnType: 'FixtureInternal',
        params: [_param('gap', 'double')],
      );
      expect(
        emitter.emitLibrary(SurfaceModel([cls]))!,
        contains('no synthesizable subject: no public unnamed constructor'),
      );
    });

    test('a subject that THROWS on construction is skipped at run time with '
        'the thrown message, not silently passed', () {
      final cls = _cls('FixtureConfig', [_param('enabled', 'bool')]);
      final source = emitter.emitLibrary(SurfaceModel([cls]))!;
      expect(source, contains('T? _subject<T>(T Function() build)'));
      expect(source, contains('markTestSkipped'));
    });
  });

  group('skips', () {
    test('a class without copyWith contributes nothing', () {
      final cls = _cls(
        'FixtureSealedBase',
        [_param('value', 'int')],
        hasCopyWith: false,
      );
      expect(emitter.emit(cls, SurfaceModel([cls])), isEmpty);
      expect(emitter.emitLibrary(SurfaceModel([cls])), isNull);
    });

    test('a class with only excluded parameters contributes nothing', () {
      final cls = _cls('FixtureCallbacks', [
        _param(
          'onTap',
          'void Function()',
          kind: SurfaceParamKind.excludedFunction,
        ),
      ]);
      expect(emitter.emit(cls, SurfaceModel([cls])), isEmpty);
    });

    test('a generic class is skipped rather than emitted unsound', () {
      // A `T` argument has no literal and no nameable parameter type at the
      // smoke-function level; the fleet has none today.
      final cls = _cls(
        'FixtureSpec',
        [_param('value', 'T')],
        typeParameters: ['T extends num'],
      );
      expect(emitter.emit(cls, SurfaceModel([cls])), isEmpty);
    });

    test('a base-typed inherited copyWith is skipped', () {
      final cls = _cls(
        'FixtureDerived',
        [_param('value', 'int')],
        copyWithReturnType: 'FixtureBase',
      );
      expect(emitter.emit(cls, SurfaceModel([cls])), isEmpty);
    });
  });

  group('library assembly', () {
    test('the file carries the header, the executed cases and the ledgers',
        () {
      final a = _cls('FixtureA', [_param('value', 'int')]);
      final b = _cls('FixtureB', [_param('flag', 'bool')]);
      final source = emitter.emitLibrary(SurfaceModel([a, b]))!;
      expect(source, startsWith('// GENERATED by surface_gen'));
      expect(
        source,
        contains("import 'package:braven_charts/braven_charts_fluent.dart';"),
      );
      expect(
        source,
        contains("import 'package:flutter_test/flutter_test.dart';"),
      );
      expect(source, contains('_smokeFixtureA'));
      expect(source, contains('_smokeFixtureB'));
      expect(source, contains('typedef _Verb'));
      expect(source, contains("test('FixtureA', () {"));
      expect(
        _collapse(source),
        contains('_record(_smokeFixtureA, subject), isEmpty'),
      );
      expect(source, contains('const List<String> _compileOnlyVerbs'));
    });

    test('the executed/skipped split is stated in the header and pinned by a '
        'test', () {
      final executed = _cls('FixtureA', [_param('value', 'int')]);
      final skipped = _cls('FixtureB', [
        _param('gradient', 'AreaGradient', isRequired: true),
        _param('flag', 'bool'),
      ]);
      final source = emitter.emitLibrary(SurfaceModel([executed, skipped]))!;
      expect(source, contains('// 1 of 2 classes have a synthesizable subject'));
      expect(source, contains('const int _executedClasses = 1;'));
      expect(source, contains('const int _skippedClasses = 1;'));
    });

    test('compile-only verbs are recorded with their reason', () {
      final cls = _cls('FixtureSeries', [
        _param('flag', 'bool'),
        _param('gradient', 'AreaGradient'),
      ]);
      final source = emitter.emitLibrary(SurfaceModel([cls]))!;
      expect(
        _collapse(source),
        contains("'FixtureSeriesFluent.withGradient — no synthesizable value "
            "for AreaGradient',"),
      );
      expect(source, contains('const List<Function> _compileOnlyCases'));
    });

    test('the Flutter show clause is derived from the type origins', () {
      final cls = _cls('FixtureStyle', [
        _param(
          'color',
          'Color',
          typeOrigins: {'Color': 'dart:ui'},
        ),
        _param(
          'padding',
          'EdgeInsets',
          typeOrigins: {'EdgeInsets': 'package:flutter/src/painting/x.dart'},
        ),
      ]);
      final source = emitter.emitLibrary(SurfaceModel([cls]))!;
      expect(
        source,
        contains(
          "import 'package:flutter/widgets.dart' show Color, EdgeInsets;",
        ),
      );
    });

    test('a synthesized value pulls its own Flutter name into the show '
        'clause', () {
      final cls = _cls('FixtureStyle', [
        _param(
          'curve',
          'Curve',
          typeOrigins: {'Curve': 'package:flutter/src/animation/x.dart'},
        ),
      ]);
      // `Curves.linear` is the value; `Curves` is not a parameter type, so it
      // would be an undefined name without this. `Curve` itself never appears
      // as an identifier in an executed case, so it is not shown.
      expect(
        emitter.emitLibrary(SurfaceModel([cls]))!,
        contains('show Curves;'),
      );
    });

    test('a name the barrel also exports is left out of the show clause', () {
      // Both packages define `TooltipTriggerMode`; showing it from Flutter
      // would be an ambiguous_import against the braven_charts export.
      final cls = _cls('FixtureStyle', [
        _param(
          'trigger',
          'TooltipTriggerMode',
          typeOrigins: {
            'TooltipTriggerMode': 'package:flutter/src/widgets/x.dart',
          },
        ),
      ]);
      const guarded = SmokeEmitter(exportedNames: {'TooltipTriggerMode'});
      final source = guarded.emitLibrary(SurfaceModel([cls]))!;
      expect(source, isNot(contains('show TooltipTriggerMode')));
    });

    test('emitLibrary is reachable through the SurfaceEmitter interface', () {
      const SurfaceEmitter seam = SmokeEmitter();
      expect(seam.outputSuffix, '_smoke_generated_test.dart');
      expect(seam.emitLibrary(const SurfaceModel([])), isNull);
    });
  });
}
