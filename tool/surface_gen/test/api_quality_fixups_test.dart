/// Regression suite for the Slice 2 API-QUALITY review findings (Q3, Q4, Q6).
///
/// These are defects in the GENERATED PUBLIC SURFACE rather than in the
/// reader's model, so every group here asserts on emitted source.
///
/// Q3 — a class whose `copyWith` rebuilds through a constructor the reader did
///      not select can ship a verb that is a semantic no-op on half its
///      instances (`TextAnnotation.withText` on a RICH annotation). The
///      surface cannot fix that without changing the class, so it must SAY it:
///      `ChartSurface(paramNotes: {...})` appends the caveat to the verb's
///      own dartdoc, where a chart author reads it.
/// Q4 — the sealed-variant helper path bypassed the `excludedFunction` rule,
///      so `withBuilderContent` was the fleet's only function-typed verb and
///      it minted a config the artifact codec refuses to serialize.
/// Q6 — combined setters took UNLABELLED positional parameters, so a 4-member
///      setter read `withOhlc(1, 6, 0.5, 3)`; and their dartdoc claimed a
///      "pair" no matter how many members they had.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/fluent_emitter.dart';
import 'package:surface_gen/src/smoke_emitter.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:surface_gen/src/surface_reader.dart';
import 'package:test/test.dart';

// ===========================================================================
// Model fixtures
// ===========================================================================

SurfaceParam _param(
  String name,
  String type, {
  SurfaceParamKind kind = SurfaceParamKind.value,
  bool isRequired = false,
  bool isNullable = false,
  bool isNamed = true,
  String? defaultCode,
}) =>
    SurfaceParam(
      name: name,
      dartType: type,
      kind: kind,
      isRequired: isRequired,
      isNullable: isNullable,
      isNamed: isNamed,
      defaultCode: defaultCode,
    );

SurfaceClass _cls(
  String name,
  List<SurfaceParam> params, {
  List<CombinedSetterModel> combinedSetters = const [],
  Map<String, String> paramNotes = const {},
  bool isSealed = false,
  List<String> sealedVariants = const [],
  List<SurfaceFactoryModel> factories = const [],
  bool hasCopyWith = true,
}) =>
    SurfaceClass(
      name: name,
      libraryUri: 'package:braven_charts/src/models/fixture.dart',
      isConstConstructible: true,
      hasCopyWith: hasCopyWith,
      copyWithReturnType: hasCopyWith ? name : null,
      params: params,
      combinedSetters: combinedSetters,
      paramNotes: paramNotes,
      isSealed: isSealed,
      sealedVariants: sealedVariants,
      factories: factories,
      unnamedConstructorParams: params,
    );

/// Collapses whitespace so an assertion is not hostage to line wrapping.
String _collapse(String source) => source.replaceAll(RegExp(r'\s+'), ' ');

// ===========================================================================
// Source fixtures (reader-level)
// ===========================================================================

/// The `ChartSurface` annotation contract, mirrored verbatim so the reader's
/// name+shape matching applies exactly as it does against the real
/// `lib/src/meta/chart_surface.dart`.
const String _preamble = '''
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],
    this.sealedVariants = const <String>[],
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[],
    this.clearFlags = const <String, String>{},
    this.bodyValidated = const <BodyValidated>[],
    this.paramNotes = const <String, String>{},
  });
  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
  final List<BodyValidated> bodyValidated;
  final Map<String, String> paramNotes;
}

class CombinedSetter {
  const CombinedSetter(this.name, this.params);
  final String name;
  final List<String> params;
}

class BodyValidated {
  const BodyValidated(this.reason, {this.params = const <String>[]});
  final String reason;
  final List<String> params;
}

const chartSurface = ChartSurface();
''';

Future<T> _withSource<T>(
  String body,
  Future<T> Function(LibraryElement) action,
) async {
  const asset = 'surface_gen|test/fixtures/api_quality_fixture.dart';
  return resolveSources({asset: '$_preamble\n$body'}, (resolver) async {
    final library = await resolver.libraryFor(AssetId.parse(asset));
    return action(library);
  });
}

Future<SurfaceModel> _read(String body) => _withSource(
      body,
      (library) => const AnalyzerSurfaceReader().read(library),
    );

Future<void> _expectReadThrows(String body, Matcher matcher) async {
  await _withSource(body, (library) async {
    await expectLater(const AnalyzerSurfaceReader().read(library), matcher);
  });
}

Matcher _stateErrorContaining(List<String> fragments) => throwsA(
      isA<StateError>().having(
        (error) => error.message,
        'message',
        allOf([for (final fragment in fragments) contains(fragment)]),
      ),
    );

void main() {
  const fluent = FluentEmitter();
  const smoke = SmokeEmitter();

  // =========================================================================
  // Q3 — a verb the class cannot make honest must SAY so
  // =========================================================================

  group('Q3 paramNotes', () {
    test('a note is appended to the generated verb dartdoc', () {
      final cls = _cls(
        'FixtureText',
        [_param('text', 'String', isRequired: true)],
        paramNotes: {
          'text': 'Plain-text only: a rich annotation ignores it.',
        },
      );
      final source = fluent.emit(cls, SurfaceModel([cls]));
      expect(
        _collapse(source),
        contains(
          '/// Replaces [FixtureText.text] with [value]. /// '
          '/// Plain-text only: a rich annotation ignores it. '
          'FixtureText withText(String value)',
        ),
      );
    });

    test('a note is appended to a tri-state verb dartdoc too', () {
      final cls = _cls(
        'FixtureStyle',
        [
          _param(
            'color',
            'ChartStyleValue<Color>',
            kind: SurfaceParamKind.triState,
          ),
        ],
        paramNotes: {'color': 'Theme components narrow the legal range.'},
      );
      final source = fluent.emit(cls, SurfaceModel([cls]));
      expect(
        _collapse(source),
        contains('Theme components narrow the legal range.'),
      );
    });

    test('the reader reads paramNotes off the annotation', () async {
      final model = await _read('''
@ChartSurface(paramNotes: {'text': 'Plain text only, see the rich half.'})
class FixtureText {
  const FixtureText({required this.text});
  final String text;
  FixtureText copyWith({String? text}) =>
      FixtureText(text: text ?? this.text);
}
''');
      expect(
        model.byName('FixtureText').paramNotes,
        {'text': 'Plain text only, see the rich half.'},
      );
    });

    test('a note naming an unknown parameter fails the build', () async {
      await _expectReadThrows(
        '''
@ChartSurface(paramNotes: {'nope': 'Plain text only, see the rich half.'})
class FixtureText {
  const FixtureText({required this.text});
  final String text;
  FixtureText copyWith({String? text}) =>
      FixtureText(text: text ?? this.text);
}
''',
        _stateErrorContaining([
          'FixtureText carries a paramNotes entry for `nope`',
        ]),
      );
    });

    test('a note on an EXCLUDED parameter fails the build — there is no verb '
        'to carry it', () async {
      await _expectReadThrows(
        '''
@ChartSurface(
  excluded: ['text'],
  paramNotes: {'text': 'Plain text only, see the rich half.'},
)
class FixtureText {
  const FixtureText({required this.text, this.label});
  final String text;
  final String? label;
  FixtureText copyWith({String? text, String? label}) =>
      FixtureText(text: text ?? this.text, label: label ?? this.label);
}
''',
        _stateErrorContaining([
          'paramNotes entry for `text`',
          'excluded',
        ]),
      );
    });
  });

  // =========================================================================
  // Q4 — the excludedFunction rule applies to sealed FACTORY parameters
  // =========================================================================

  group('Q4 function-typed sealed factories', () {
    SurfaceModel modelWithBuilderFactory() {
      final sealed = _cls(
        'FixtureContent',
        const [],
        hasCopyWith: false,
        isSealed: true,
        sealedVariants: ['FixtureAutomaticContent', 'FixtureBuilderContent'],
        factories: const [
          SurfaceFactoryModel('automatic', [
            SurfaceParam(
              name: 'includeTrends',
              dartType: 'bool',
              kind: SurfaceParamKind.value,
              isRequired: false,
              isNullable: false,
              defaultCode: 'false',
            ),
          ]),
          SurfaceFactoryModel('builder', [
            SurfaceParam(
              name: 'builder',
              dartType: 'String Function(double)',
              kind: SurfaceParamKind.excludedFunction,
              isRequired: true,
              isNullable: false,
              isNamed: false,
            ),
            SurfaceParam(
              name: 'descriptorId',
              dartType: 'String?',
              kind: SurfaceParamKind.value,
              isRequired: false,
              isNullable: true,
            ),
          ]),
        ],
      );
      final owner = _cls('FixtureConfig', [
        _param(
          'content',
          'FixtureContent',
          kind: SurfaceParamKind.nestedConfig,
          defaultCode: 'const FixtureContent.automatic()',
        ),
      ]);
      return SurfaceModel([owner, sealed]);
    }

    test('no helper is emitted for a factory carrying a function-typed '
        'parameter', () {
      final model = modelWithBuilderFactory();
      final source = fluent.emit(model.byName('FixtureConfig'), model);
      expect(source, contains('withAutomaticContent('));
      expect(source, isNot(contains('withBuilderContent')));
      // `updateContent` legitimately takes a rebuild callback; what must not
      // appear is a verb whose argument IS the config's own function payload.
      expect(source, isNot(contains('String Function(double)')));
    });

    test('the plain withX verb for the sealed parameter still exists — a '
        'caller can construct the variant and pass it', () {
      final model = modelWithBuilderFactory();
      final source = fluent.emit(model.byName('FixtureConfig'), model);
      expect(source, contains('withContent(FixtureContent value)'));
    });

    test('the smoke emitter drops it too, so the executed set matches the '
        'emitted set', () {
      final model = modelWithBuilderFactory();
      final source = smoke.emit(model.byName('FixtureConfig'), model);
      expect(source, contains('withAutomaticContent('));
      expect(source, isNot(contains('withBuilderContent')));
    });

    test('a controller-typed factory parameter is dropped on the same rule',
        () {
      final sealed = _cls(
        'FixtureSource',
        const [],
        hasCopyWith: false,
        isSealed: true,
        sealedVariants: ['FixtureLiveSource'],
        factories: const [
          SurfaceFactoryModel('live', [
            SurfaceParam(
              name: 'controller',
              dartType: 'FixtureController',
              kind: SurfaceParamKind.excludedController,
              isRequired: true,
              isNullable: false,
              isNamed: false,
            ),
          ]),
        ],
      );
      final owner = _cls('FixtureConfig', [
        _param('source', 'FixtureSource', kind: SurfaceParamKind.nestedConfig),
      ]);
      final model = SurfaceModel([owner, sealed]);
      expect(
        fluent.emit(owner, model),
        isNot(contains('withLiveSource')),
      );
    });
  });

  // =========================================================================
  // Q6 — combined setters read as prose, not as a tuple
  // =========================================================================

  group('Q6 combined setter ergonomics', () {
    SurfaceClass twoMember() => _cls(
          'FixtureAxis',
          [
            _param('min', 'double?', isNullable: true),
            _param('max', 'double?', isNullable: true),
          ],
          combinedSetters: const [
            CombinedSetterModel('withRange', ['min', 'max']),
          ],
        );

    SurfaceClass fourMember() => _cls(
          'FixturePoint',
          [
            _param('open', 'double', isRequired: true),
            _param('high', 'double', isRequired: true),
            _param('low', 'double', isRequired: true),
            _param('close', 'double', isRequired: true),
          ],
          combinedSetters: const [
            CombinedSetterModel('withOhlc', ['open', 'high', 'low', 'close']),
          ],
        );

    test('a TWO-member setter keeps positional parameters', () {
      final cls = twoMember();
      expect(
        _collapse(fluent.emit(cls, SurfaceModel([cls]))),
        contains('FixtureAxis withRange(double min, double max)'),
      );
    });

    test('a THREE-OR-MORE-member setter takes REQUIRED NAMED parameters', () {
      final cls = fourMember();
      expect(
        _collapse(fluent.emit(cls, SurfaceModel([cls]))),
        contains(
          'FixturePoint withOhlc({ required double open, '
          'required double high, required double low, '
          'required double close, })',
        ),
      );
    });

    test('the dartdoc pluralises off the member count', () {
      final two = twoMember();
      expect(
        _collapse(fluent.emit(two, SurfaceModel([two]))),
        contains('assert-coupled, so they only move as a pair.'),
      );
      final four = fourMember();
      expect(
        _collapse(fluent.emit(four, SurfaceModel([four]))),
        contains('assert-coupled, so all four only move together.'),
      );
      expect(
        _collapse(fluent.emit(four, SurfaceModel([four]))),
        isNot(contains('as a pair')),
      );
    });

    test('the smoke emitter labels the arguments of a named combined setter',
        () {
      final cls = fourMember();
      expect(
        _collapse(smoke.emit(cls, SurfaceModel([cls]))),
        contains(
          'subject.withOhlc( open: subject.open, high: subject.high, '
          'low: subject.low, close: subject.close, )',
        ),
      );
    });

    test('the smoke emitter leaves a TWO-member setter positional', () {
      final cls = twoMember();
      expect(
        _collapse(smoke.emit(cls, SurfaceModel([cls]))),
        contains('subject.withRange(1.0, 2.0)'),
      );
    });
  });
}
