/// Tests for the exhaustive smoke emitter (Task 6, Scope D).
///
/// The emitted file's job is to fail COMPILATION when a generated verb does
/// not type-check against its owner, so what is asserted here is the shape of
/// what it writes: one function per class, the subject as a parameter, a
/// canonical literal where one exists and a typed parameter otherwise, and the
/// same verb names `fluent_emitter.dart` produces.
library;

import 'package:surface_gen/src/emitter.dart';
import 'package:surface_gen/src/smoke_emitter.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:test/test.dart';

SurfaceParam _param(
  String name,
  String type, {
  SurfaceParamKind kind = SurfaceParamKind.value,
  bool isNullable = false,
  String? clearFlag,
  String? triStatePayloadType,
  List<String> enumValues = const [],
  Map<String, String> typeOrigins = const {},
}) =>
    SurfaceParam(
      name: name,
      dartType: type,
      kind: kind,
      isRequired: false,
      isNullable: isNullable,
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
    );

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
      expect(source, contains('void _smokeFixtureConfig(FixtureConfig subject)'));
      expect(source, contains('subject.withEnabled(true);'));
      expect(source, contains('subject.withCount(1);'));
      expect(source, contains('subject.withRatio(1.0);'));
      expect(source, contains("subject.withLabel('x');"));
      expect(
        source,
        contains('subject.withDelay(const Duration(milliseconds: 1));'),
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
        contains('subject.withMode(FixtureMode.values.first);'),
      );
    });

    test('a type with no literal becomes a typed parameter', () {
      final cls = _cls('FixtureConfig', [
        _param('color', 'Color'),
        _param('padding', 'EdgeInsets'),
      ]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('Color a0'));
      expect(source, contains('EdgeInsets a1'));
      expect(source, contains('subject.withColor(a0);'));
      expect(source, contains('subject.withPadding(a1);'));
    });

    test('a nullable type is passed non-null, matching the stripped verb', () {
      final cls = _cls('FixtureConfig', [
        _param('label', 'String?', isNullable: true),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains("subject.withLabel('x');"),
      );
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
      expect(source, contains('subject.withBackgroundColor(a0);'));
      expect(source, contains('subject.withoutBackgroundColor();'));
      expect(source, contains('subject.inheritBackgroundColor();'));
    });

    test('a derived clear flag yields clearX', () {
      final cls = _cls('FixtureConfig', [
        _param('label', 'String?', isNullable: true, clearFlag: 'clearLabel'),
      ]);
      expect(
        emitter.emit(cls, SurfaceModel([cls])),
        contains('subject.clearLabel();'),
      );
    });

    test('a non-nullable nested config yields updateX', () {
      final nested = _cls('FixtureNested', [_param('gap', 'double')]);
      final owner = _cls('FixtureOwner', [
        _param('nested', 'FixtureNested', kind: SurfaceParamKind.nestedConfig),
      ]);
      final source = emitter.emit(owner, SurfaceModel([owner, nested]));
      expect(source, contains('subject.updateNested((current) => current);'));
    });

    test('a combined setter replaces its members with one call', () {
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
      expect(source, contains('subject.withRange(1.0, 1.0);'));
      expect(source, isNot(contains('subject.withMin(')));
      expect(source, isNot(contains('subject.withMax(')));
    });

    test('the `is` prefix is dropped exactly as the fluent emitter does', () {
      final cls = _cls('FixtureSeries', [_param('isXOrdered', 'bool')]);
      final source = emitter.emit(cls, SurfaceModel([cls]));
      expect(source, contains('subject.withXOrdered(true);'));
      expect(source, isNot(contains('withIsXOrdered')));
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
    test('the file carries the header, the case list and one test', () {
      final a = _cls('FixtureA', [_param('value', 'int')]);
      final b = _cls('FixtureB', [_param('flag', 'bool')]);
      final source = emitter.emitLibrary(SurfaceModel([a, b]))!;
      expect(source, startsWith('// GENERATED by surface_gen'));
      expect(source, contains('2\n// classes'));
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
      expect(source, contains('const List<Function> _cases'));
      expect(source, contains('expect(_cases, hasLength(2));'));
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
