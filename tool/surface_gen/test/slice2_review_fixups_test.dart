/// Regression suite for the Slice 2 independent-review engine findings
/// (S1–S4). Every group here reproduces a defect the reviewer proved
/// empirically against the real fleet, then pins the fix.
///
/// S1 — body-validated constructors were invisible: five annotated classes
///      enforce cross-parameter invariants in the constructor BODY, so
///      `assertGroups` was empty and the individual verbs shipped and threw.
/// S2 — asserts were read from only the SELECTED constructor, so the
///      `const _internal` idiom hid a whole constructor's asserts.
/// S3 — the generated smoke test never executed (see `smoke_emitter_test`).
/// S4 — the slicing guard is a RETURN-TYPE check; its scope is now documented.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:surface_gen/src/surface_reader.dart';
import 'package:test/test.dart';

/// The `ChartSurface` annotation contract, mirrored verbatim (including the
/// `bodyValidated` acknowledgement) so the reader's name+shape matching
/// applies exactly as it does against the real `lib/src/meta/chart_surface.dart`.
const String _preamble = '''
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],
    this.sealedVariants = const <String>[],
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[],
    this.clearFlags = const <String, String>{},
    this.bodyValidated = const <BodyValidated>[],
  });
  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
  final List<BodyValidated> bodyValidated;
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
  const asset = 'surface_gen|test/fixtures/inline_fixture.dart';
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
  // =========================================================================
  // S1 — body-validated constructors are an unmodelled-validation signal
  // =========================================================================

  group('S1 body-validated constructors', () {
    /// The `CandlestickDataPoint` shape: the body names the coupled
    /// parameters, so the reader can report them precisely.
    const namedBody = '''
@chartSurface
class FixturePoint {
  FixturePoint({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
  }) {
    validate(x: x, open: open, high: high, low: low);
  }

  final double x;
  final double open;
  final double high;
  final double low;

  static void validate({
    required double x,
    required double open,
    required double high,
    required double low,
  }) {
    if (high < low) throw ArgumentError('high < low');
  }

  FixturePoint copyWith({
    double? x,
    double? open,
    double? high,
    double? low,
  }) => FixturePoint(
        x: x ?? this.x,
        open: open ?? this.open,
        high: high ?? this.high,
        low: low ?? this.low,
      );
}
''';

    test('a non-empty constructor body fails the build, naming the class, '
        'the constructor and the parameters', () async {
      await _expectReadThrows(
        namedBody,
        _stateErrorContaining([
          'unmodelled constructor validation',
          'FixturePoint',
          'the unnamed constructor',
          'high, low, open, x',
        ]),
      );
    });

    test('the diagnostic offers the same three remedies the assert '
        'diagnostic does', () async {
      await _expectReadThrows(
        namedBody,
        _stateErrorContaining([
          'CombinedSetter',
          'excluded',
          'BodyValidated',
        ]),
      );
    });

    test('a CombinedSetter over the coupled parameters discharges them, '
        'leaving only the residue named', () async {
      await _expectReadThrows(
        namedBody.replaceFirst(
          '@chartSurface',
          '@ChartSurface(combinedSetters: ['
              "CombinedSetter('withOhl', ['open', 'high', 'low'])])",
        ),
        _stateErrorContaining([
          'unmodelled constructor validation',
          'x',
        ]),
      );
    });

    test('CombinedSetter plus a targeted acknowledgement resolves the class',
        () async {
      final model = await _read(
        namedBody.replaceFirst(
          '@chartSurface',
          '@ChartSurface(combinedSetters: ['
              "CombinedSetter('withOhl', ['open', 'high', 'low'])], "
              "bodyValidated: [BodyValidated('x is checked for finiteness "
              "only, exactly as construction does', params: ['x'])])",
        ),
      );
      final cls = model.byName('FixturePoint');
      expect(cls.bodyValidationGroups, hasLength(1));
      expect(cls.bodyValidationGroups.single.params,
          ['high', 'low', 'open', 'x']);
      expect(cls.bodyValidationGroups.single.isOpaque, isFalse);
      expect(cls.bodyValidations.single.params, ['x']);
    });

    test('excluding the coupled parameters resolves the class', () async {
      final model = await _read(
        namedBody.replaceFirst(
          '@chartSurface',
          "@ChartSurface(excluded: ['x', 'open', 'high', 'low'])",
        ),
      );
      expect(model.byName('FixturePoint').bodyValidationGroups, hasLength(1));
    });

    test('a class-wide acknowledgement resolves the class', () async {
      final model = await _read(
        namedBody.replaceFirst(
          '@chartSurface',
          '@ChartSurface(bodyValidated: [BodyValidated('
              "'validate() enforces the OHLC ordering invariant')])",
        ),
      );
      expect(model.byName('FixturePoint').bodyValidations.single.isClassWide,
          isTrue);
    });

    /// The `CandlestickChartSeries` shape: the body names no parameter at
    /// all, so every emitted parameter is conservatively in scope.
    const opaqueBody = '''
@chartSurface
class FixtureSeries {
  FixtureSeries({required this.id, this.gap = 1.0}) {
    validateConfiguration();
  }

  final String id;
  final double gap;

  void validateConfiguration() {
    if (gap < 0) throw ArgumentError('gap');
  }

  FixtureSeries copyWith({String? id, double? gap}) =>
      FixtureSeries(id: id ?? this.id, gap: gap ?? this.gap);
}
''';

    test('an opaque body puts EVERY emitted parameter in scope', () async {
      await _expectReadThrows(
        opaqueBody,
        _stateErrorContaining([
          'unmodelled constructor validation',
          'FixtureSeries',
          'names no parameter',
          'gap, id',
        ]),
      );
    });

    test('an opaque body records isOpaque once acknowledged', () async {
      final model = await _read(
        opaqueBody.replaceFirst(
          '@chartSurface',
          '@ChartSurface(bodyValidated: [BodyValidated('
              "'validateConfiguration() re-runs every nested validate()')])",
        ),
      );
      final group = model.byName('FixtureSeries').bodyValidationGroups.single;
      expect(group.isOpaque, isTrue);
      expect(group.params, ['gap', 'id']);
    });

    test('a body that MIXES an opaque call with named checks is opaque — '
        'the DonutChartSeries shape', () async {
      await _expectReadThrows('''
@chartSurface
class FixtureMixed {
  FixtureMixed({required this.id, this.gap = 1.0, this.tint = 0}) {
    validateConfiguration();
    if (gap < 0) throw ArgumentError.value(gap);
  }

  final String id;
  final double gap;
  final int tint;

  void validateConfiguration() {}

  FixtureMixed copyWith({String? id, double? gap, int? tint}) => FixtureMixed(
        id: id ?? this.id,
        gap: gap ?? this.gap,
        tint: tint ?? this.tint,
      );
}
''', _stateErrorContaining([
        'names no parameter',
        'gap, id, tint',
      ]));
    });

    test('an empty constructor body is not a signal', () async {
      final model = await _read('''
@chartSurface
class FixturePlain {
  FixturePlain({this.gap = 1.0});
  final double gap;
  FixturePlain copyWith({double? gap}) =>
      FixturePlain(gap: gap ?? this.gap);
}
''');
      expect(model.byName('FixturePlain').bodyValidationGroups, isEmpty);
    });

    test('a body on a NON-selected constructor is still a signal', () async {
      await _expectReadThrows('''
@chartSurface
class FixtureTwoCtors {
  FixtureTwoCtors({required this.gap}) {
    if (gap < 0) throw ArgumentError.value(gap);
  }

  const FixtureTwoCtors._internal({required this.gap});

  final double gap;

  FixtureTwoCtors copyWith({double? gap}) =>
      FixtureTwoCtors._internal(gap: gap ?? this.gap);
}
''', _stateErrorContaining(['unmodelled constructor validation', 'gap']));
    });

    test('a stale acknowledgement — no body to acknowledge — fails',
        () async {
      await _expectReadThrows('''
@ChartSurface(bodyValidated: [BodyValidated('nothing to acknowledge here')])
class FixtureStale {
  const FixtureStale({this.gap = 1.0});
  final double gap;
  FixtureStale copyWith({double? gap}) =>
      FixtureStale(gap: gap ?? this.gap);
}
''', _stateErrorContaining(['stale BodyValidated', 'FixtureStale']));
    });

    test('an acknowledgement naming an unknown parameter fails', () async {
      await _expectReadThrows(
        opaqueBody.replaceFirst(
          '@chartSurface',
          '@ChartSurface(bodyValidated: [BodyValidated('
              "'the reason is long enough', params: ['nope'])])",
        ),
        _stateErrorContaining(['BodyValidated', 'nope']),
      );
    });
  });

  // =========================================================================
  // S2 — asserts are unioned across ALL generative constructors
  // =========================================================================

  group('S2 asserts across every constructor', () {
    /// The `YAxisConfig` shape verbatim: a NON-const public constructor
    /// carrying the asserts, a `const _internal` carrying the parameters, and
    /// a `copyWith` that rebuilds through `_internal`.
    const yAxisShape = '''
@ChartSurface(
  excluded: ['id'],
  %COMBINED%
)
class FixtureYAxis {
  FixtureYAxis({required int position, this.min, this.max})
      : id = '',
        assert(min == null || max == null || min < max, 'min < max');

  const FixtureYAxis._internal({required this.id, this.min, this.max});

  final String id;
  final double? min;
  final double? max;

  FixtureYAxis copyWith({double? min, double? max}) =>
      FixtureYAxis._internal(id: id, min: min ?? this.min, max: max ?? this.max);
}
''';

    test('the asserts of a non-selected constructor are read', () async {
      final model = await _read(
        yAxisShape.replaceFirst(
          '%COMBINED%',
          "combinedSetters: [CombinedSetter('withRange', ['min', 'max'])],",
        ),
      );
      expect(model.byName('FixtureYAxis').assertGroups, [
        ['max', 'min'],
      ]);
    });

    test('removing the CombinedSetters now FIRES the diagnostic — the '
        'const _internal idiom no longer hides them', () async {
      await _expectReadThrows(
        yAxisShape.replaceFirst('%COMBINED%', ''),
        _stateErrorContaining([
          'assert-coupled parameters',
          'FixtureYAxis',
          'max, min',
        ]),
      );
    });

    test('the union is deduplicated across constructors', () async {
      final model = await _read('''
@ChartSurface(combinedSetters: [CombinedSetter('withRange', ['min', 'max'])])
class FixtureDuplicate {
  const FixtureDuplicate({this.min, this.max})
      : assert(min == null || max == null || min < max, 'min < max');

  const FixtureDuplicate.alt({this.min, this.max})
      : assert(min == null || max == null || min < max, 'min < max');

  final double? min;
  final double? max;

  FixtureDuplicate copyWith({double? min, double? max}) =>
      FixtureDuplicate(min: min ?? this.min, max: max ?? this.max);
}
''');
      expect(model.byName('FixtureDuplicate').assertGroups, [
        ['max', 'min'],
      ]);
    });
  });

  // =========================================================================
  // Construction contract — what a generated test can actually build
  // =========================================================================

  group('public construction contract', () {
    test('the PUBLIC unnamed constructor is recorded alongside the selected '
        'one', () async {
      final model = await _read('''
@ChartSurface(excluded: ['id'])
class FixtureInternal {
  FixtureInternal({required int position, this.gap = 1.0}) : id = '';

  const FixtureInternal._internal({required this.id, this.gap = 1.0});

  final String id;
  final double gap;

  FixtureInternal copyWith({double? gap}) =>
      FixtureInternal._internal(id: id, gap: gap ?? this.gap);
}
''');
      final cls = model.byName('FixtureInternal');
      expect(cls.params.map((p) => p.name), ['id', 'gap']);
      expect(
        cls.unnamedConstructorParams?.map((p) => p.name),
        ['position', 'gap'],
      );
      expect(
        cls.unnamedConstructorParams!
            .singleWhere((p) => p.name == 'position')
            .isRequired,
        isTrue,
      );
    });

    test('a sealed base with no public constructor records none', () async {
      final model = await _read('''
@ChartSurface(sealedVariants: ['FixtureLeaf'])
sealed class FixtureBase {
  const FixtureBase._();
  factory FixtureBase.leaf(double gap) = FixtureLeaf;
}

final class FixtureLeaf extends FixtureBase {
  const FixtureLeaf(this.gap) : super._();
  final double gap;
}
''');
      expect(model.byName('FixtureBase').unnamedConstructorParams, isNull);
    });
  });
}
