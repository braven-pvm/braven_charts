/// The reader's assert-SHAPE detection, added for the structural AI schema.
///
/// `assertGroups` only ever said WHICH parameters an assert couples, which is
/// all the fluent emitter's coverage rule needs. A schema has to say HOW they
/// are coupled, and the three uncovered multi-parameter asserts on the real
/// surface disagree about that in every possible direction:
///
/// - `BarChartSeries`: `barWidthPercent != null || barWidthPixels != null` —
///   at least one;
/// - `RangeAnnotation`: `startX == null || endX == null || startX < endX` —
///   an ordering check that permits BOTH being absent;
/// - `LegendAnnotation`: `[...].whereType<Object>().length <= 1` — at MOST
///   one, the exact opposite of the first.
///
/// So `isNullAlternation` is deliberately narrow, and these tests pin the
/// boundary: it must be true for the first shape and false for the other two,
/// because a generated `anyOf` derived from either of them would document the
/// class backwards.
library;

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:surface_gen/src/surface_reader.dart';
import 'package:test/test.dart';

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

Future<SurfaceModel> _read(String body) async {
  const asset = 'surface_gen|test/fixtures/assert_shape_fixture.dart';
  return resolveSources({asset: '$_preamble\n$body'}, (resolver) async {
    final library = await resolver.libraryFor(AssetId.parse(asset));
    return const AnalyzerSurfaceReader().read(library);
  });
}

/// A class whose only multi-parameter assert is [condition], carrying
/// [message]. `min`/`max` are covered by a combined setter so the reader's
/// coverage diagnostic stays quiet regardless of the shape under test.
String _fixture(String condition, String message) => '''
@ChartSurface(
  combinedSetters: [CombinedSetter('withRange', ['min', 'max'])],
)
class FixtureConfig {
  const FixtureConfig({this.min, this.max}) : assert($condition, '$message');

  final double? min;
  final double? max;

  FixtureConfig copyWith({double? min, double? max}) =>
      FixtureConfig(min: min ?? this.min, max: max ?? this.max);
}
''';

SurfaceAssert _single(SurfaceModel model) =>
    model.byName('FixtureConfig').asserts.single;

void main() {
  test('assertGroups is unchanged — same names, same order', () async {
    final model = await _read(_fixture('min != null || max != null', 'either'));
    expect(model.byName('FixtureConfig').assertGroups, [
      ['max', 'min'],
    ]);
  });

  test('the assert MESSAGE is captured', () async {
    final entry = _single(
      await _read(_fixture('min != null || max != null', 'need one of them')),
    );
    expect(entry.message, 'need one of them');
    expect(entry.params, ['max', 'min']);
  });

  test('`a != null || b != null` is a null-alternation', () async {
    expect(
      _single(await _read(_fixture('min != null || max != null', 'either')))
          .isNullAlternation,
      isTrue,
    );
  });

  test('the operands may be parenthesized or reversed', () async {
    expect(
      _single(await _read(
        _fixture('(null != min) || ((max != null))', 'either'),
      )).isNullAlternation,
      isTrue,
    );
  });

  test('an ORDERING assert is not a null-alternation — RangeAnnotation\'s '
      'shape permits both being absent', () async {
    expect(
      _single(await _read(
        _fixture('min == null || max == null || min < max', 'min < max'),
      )).isNullAlternation,
      isFalse,
    );
  });

  test('a CARDINALITY assert is not a null-alternation — LegendAnnotation\'s '
      'shape means at MOST one', () async {
    expect(
      _single(await _read(_fixture(
        '[min, max].whereType<Object>().length <= 1',
        'use separate instances',
      ))).isNullAlternation,
      isFalse,
    );
  });

  test('an AND of null checks is not an alternation', () async {
    expect(
      _single(await _read(_fixture('min != null && max != null', 'both')))
          .isNullAlternation,
      isFalse,
    );
  });

  test('an interpolated message is dropped rather than emitted raw', () async {
    const body = '''
@ChartSurface(
  combinedSetters: [CombinedSetter('withRange', ['min', 'max'])],
)
class FixtureConfig {
  const FixtureConfig({this.min, this.max})
      : assert(min != null || max != null, 'need \$min or \$max');

  final double? min;
  final double? max;

  FixtureConfig copyWith({double? min, double? max}) =>
      FixtureConfig(min: min ?? this.min, max: max ?? this.max);
}
''';
    expect(_single(await _read(body)).message, isNull);
  });
}
