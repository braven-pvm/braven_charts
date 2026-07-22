import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// DRIFT GATE for the hand-written Source config emitter.
///
/// ## What the real contract is
///
/// `ChartConfigDartEmitter` (`lib/src/source/chart_config_dart_emitter.dart`)
/// is a hand-maintained MIRROR of the config surface: ~100 `_emit*` methods
/// that write `paramName: value` for each config class the source generator
/// reconstructs. Nothing type-checks that relationship. Adding a property to a
/// `@chartSurface` config class and forgetting the matching `_emit` line drifts
/// silently — the generated Source just omits the property, the value is lost
/// on round-trip, and no existing test fails.
///
/// This gate closes that hole the way `ai_mirror_drift_test.dart` gated the AI
/// tool schema: it measures which modelled config properties the emitter does
/// not name, pins today's reviewed gaps, and fails on any NEW one.
///
/// ## Source of truth
///
/// The surface side is the GENERATED manifest `ChartToolSchema.surfaceDefinitions`
/// (produced by `tool/surface_gen`, checked in at
/// `lib/src/ai/generated/surface_definitions.dart`): every `@chartSurface`
/// class keyed to its structural `properties`. Reading the generated manifest —
/// rather than re-deriving the surface with the analyzer — is deliberate: it is
/// always current with the modelled surface and cannot silently disagree with
/// the schema the AI lane already ships.
///
/// The emitter side is a SOURCE SCAN of `chart_config_dart_emitter.dart`: the
/// generous union of every member access (`value.foo`, the field READ), every
/// camelCase single-quoted literal (`'foo'`, the emitted argument-name WRITE)
/// and every object-pattern binding (`case Foo(:final foo)`, used by the value
/// summary presentation). A property counted here is one the emitter NAMES AT
/// ALL. This mirrors the FORWARD gate of the AI test: the question is "does the
/// emitter know this word", so the extraction is generous on purpose and must
/// not cry wolf. The stated cost, identical to the AI test's flattened schema
/// walk, is name COLLISION: a property covered for class A counts as covered
/// for a same-named property on class B. A brand-new property with a brand-new
/// name — the common drift — is still caught; a new property that happens to
/// reuse an existing emitted name is the documented blind spot.
///
/// ## Coverage boundary — READ THIS BEFORE WIDENING THE GATE
///
/// This gate covers the MODELLED surface: the ~100 `@chartSurface` classes in
/// the manifest. It CANNOT cover the ~29 copy-with-less config classes the
/// emitter also writes — `BarChartStyle`, `CandlestickChartStyle`, the
/// `Bar*Style` / `Scatter*Config` families (the same set
/// `ai_mirror_drift_test.dart` pins as `_builderTargetsOutsideSurfaceModel`).
/// Those classes are immutable with no `copyWith`, so the enforcement rule in
/// `surface_enforcement_test.dart` does not treat them as config, they carry no
/// `@chartSurface`, and they are absent from the manifest this gate reads.
/// Gating them needs a `copyWith` first — a separate slice. This gate does not
/// pretend to see them.
///
/// ## Gate style
///
/// Two reviewed allowlists, in the idiom of `surface_enforcement_test.dart` and
/// the AI mirror test: whole classes the source emitter is not responsible for,
/// and individual property gaps inside classes it IS responsible for. Each
/// carries a one-line reason. The gate fails on a NEW gap, and on a pinned gap
/// that was fixed without being unpinned.

/// The emitter source under audit.
String get _emitterSource => File(
      '${Directory.current.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}src${Platform.pathSeparator}source'
      '${Platform.pathSeparator}chart_config_dart_emitter.dart',
    ).readAsStringSync();

/// `@chartSurface` classes the source emitter does not emit AT ALL, because
/// they are not reachable from the captured `HydratedChartConfiguration` /
/// `ChartDocument` the generator consumes. A class here is skipped entirely.
///
/// This set is a permanent structural hole, not a per-property gap: pinning
/// individual properties would be dishonest, since the flat scan only surfaces
/// the uniquely-named ones and lets the collision-named siblings pass. The list
/// may SHRINK (the generator learns to capture one of them); it may not grow
/// unnoticed.
const Map<String, String> _classesNotEmittedBySource = <String, String>{
  'ChartDataTableTheme':
      'Data-table view theme (lib/src/table). It themes the tabular data view, '
          'not the chart, and is never part of the config graph the source '
          'generator captures.',
  'StreamingConfig':
      'Runtime streaming config. A BravenChartPlus parameter that is NOT '
          'captured in ChartDocument / HydratedChartConfiguration, so the '
          'source generator has no value to emit.',
  'AutoScrollConfig':
      'Runtime auto-scroll config. Like StreamingConfig it is a live '
          'BravenChartPlus parameter absent from the captured document, so '
          'there is nothing for the emitter to reconstruct.',
  'CartesianValueSummaryTheme':
      'Theme-level value-summary defaults. The theme document codec does not '
          'persist this component, so the hydrated ChartTheme never carries a '
          'non-default value and the emitter has nothing to write. (The '
          'per-chart CartesianValueSummaryConfig IS emitted via _emitValueSummary.)',
};

/// Individual modelled properties the emitter does not name, inside classes it
/// otherwise emits. Reviewed, one reason each. Removing the gap (adding the
/// `_emit` coverage) means deleting its line here.
const Map<String, String> _propertyGaps = <String, String>{
  'ChartTheme.cartesianValueSummaryTheme':
      'The cartesian value-summary theme component (see '
          'CartesianValueSummaryTheme above): ChartTheme is emitted, but this '
          'field is not, because the theme codec does not persist it.',
  'MultiAxisConfig.bindings':
      'Series-to-axis bindings are emitted per series as yAxisId / yAxisConfig, '
          'not as a MultiAxisConfig.bindings map. There is no MultiAxisConfig '
          'object in the emitted graph.',
};

/// Every `@chartSurface` class keyed to its modelled property names, from the
/// generated manifest.
Map<String, Set<String>> _surfaceProperties() {
  final definitions = ChartToolSchema.surfaceDefinitions;
  final result = <String, Set<String>>{};
  for (final entry in definitions.entries) {
    final value = entry.value! as Map<String, Object?>;
    final properties = value['properties'] as Map<String, Object?>?;
    result[entry.key] = (properties?.keys ?? const <String>[]).toSet();
  }
  return result;
}

/// The generous set of property names the emitter NAMES: field reads, emitted
/// argument-name literals, and object-pattern bindings.
Set<String> _emitterMentions(String source) => <String>{
      for (final match
          in RegExp(r"""(?:!|\?)?\.([a-z][A-Za-z0-9_]*)\b""").allMatches(source))
        match.group(1)!,
      for (final match
          in RegExp(r"""'([a-z][A-Za-z0-9_]*)'""").allMatches(source))
        match.group(1)!,
      for (final match
          in RegExp(r""":\s*final\s+([a-z][A-Za-z0-9_]*)""").allMatches(source))
        match.group(1)!,
    };

void main() {
  late Map<String, Set<String>> surface;
  late Set<String> mentioned;

  setUpAll(() {
    surface = _surfaceProperties();
    mentioned = _emitterMentions(_emitterSource);
  });

  bool isEmitted(String property) => mentioned.contains(property);

  test('the extraction produced plausible sets', () {
    // A manifest that failed to load or a regex that stopped matching would
    // make the gate vacuous.
    expect(surface, hasLength(greaterThan(80)),
        reason: 'the surface manifest resolved almost no classes');
    expect(
      surface.values.fold<int>(0, (sum, props) => sum + props.length),
      greaterThan(700),
      reason: 'the surface manifest resolved almost no properties',
    );
    expect(mentioned, hasLength(greaterThan(500)),
        reason: 'the emitter scan found almost no names — the emitter was '
            'probably restructured and this extraction needs revisiting');
    // Spot-check a property known to be emitted and one class known to exist.
    expect(surface.containsKey('LegendStyle'), isTrue);
    expect(isEmitted('strokeWidth'), isTrue);
  });

  test('every reviewed hole names a real class/property and a real reason', () {
    for (final className in _classesNotEmittedBySource.keys) {
      expect(surface.containsKey(className), isTrue,
          reason: '$className is pinned as not-emitted but is not a '
              '@chartSurface class in the manifest — delete it from '
              '_classesNotEmittedBySource.');
    }
    for (final key in _propertyGaps.keys) {
      final parts = key.split('.');
      final className = parts[0];
      final property = parts[1];
      expect(surface.containsKey(className), isTrue,
          reason: '$key pins a property on $className, which is not a '
              '@chartSurface class.');
      expect(
        _classesNotEmittedBySource.containsKey(className),
        isFalse,
        reason: '$key pins a property on $className, but $className is already '
            'pinned as a whole not-emitted class — a property gap there is '
            'redundant.',
      );
      expect(surface[className]!.contains(property), isTrue,
          reason: '$key pins property "$property", which $className does not '
              'model — delete it from _propertyGaps.');
    }
    for (final reason in [
      ..._classesNotEmittedBySource.values,
      ..._propertyGaps.values,
    ]) {
      expect(reason.length, greaterThanOrEqualTo(20),
          reason: 'a pinned hole has a placeholder reason');
    }
  });

  test('every modelled property is emitted, pinned, or in an exempt class', () {
    final gaps = <String>[];
    for (final entry in surface.entries) {
      final className = entry.key;
      if (_classesNotEmittedBySource.containsKey(className)) continue;
      for (final property in entry.value) {
        if (isEmitted(property)) continue;
        if (_propertyGaps.containsKey('$className.$property')) continue;
        gaps.add('$className.$property');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason: 'NEW source-emitter drift: these modelled config properties are '
          'not named anywhere in chart_config_dart_emitter.dart, so the '
          'generated Source silently drops them on round-trip. Add an '
          '_emit path (with a source-generator test proving the property '
          'appears for a non-default value), or — if the property genuinely '
          'cannot be emitted — pin it in _propertyGaps with a reason:\n'
          '${gaps.join('\n')}',
    );
  });

  test('the pinned property gaps are all still real', () {
    final stale = _propertyGaps.keys
        .where((key) => isEmitted(key.split('.')[1]))
        .toList()
      ..sort();
    expect(
      stale,
      isEmpty,
      reason: 'these property gaps are now emitted but still pinned. Delete '
          'them from _propertyGaps:\n${stale.join('\n')}',
    );
  });

  test('COVERAGE REPORT (not a gate): source-emitter coverage of the surface',
      () {
    var modelledProps = 0;
    var emittedProps = 0;
    var exemptProps = 0;
    for (final entry in surface.entries) {
      final exempt = _classesNotEmittedBySource.containsKey(entry.key);
      for (final property in entry.value) {
        modelledProps++;
        if (exempt) {
          exemptProps++;
        } else if (isEmitted(property)) {
          emittedProps++;
        }
      }
    }
    // ignore: avoid_print
    print(
      '\n[source emitter drift]\n'
      '  @chartSurface classes:        ${surface.length}\n'
      '  modelled properties:          $modelledProps\n'
      '  classes not emitted (pinned): ${_classesNotEmittedBySource.length}\n'
      '  property gaps (pinned):       ${_propertyGaps.length}\n'
      '  emitter names (union):        ${mentioned.length}\n'
      '  properties in exempt classes: $exemptProps\n'
      '  properties the emitter names: $emittedProps of '
      '${modelledProps - exemptProps} in gated classes\n'
      '  NOTE: this gates the MODELLED surface only. The ~29 copyWith-less '
      'config\n'
      '  classes the emitter also writes (BarChartStyle, the Bar*Style / '
      'Scatter*\n'
      '  families) carry no @chartSurface and are invisible here — a separate '
      'slice.',
    );
    expect(emittedProps, greaterThan(0));
  });
}
