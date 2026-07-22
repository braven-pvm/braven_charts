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
  'ChartDocumentExtractOptions':
      'Artifact extraction policy supplied to ChartDocumentExtractor at '
          'capture time. It controls how an existing chart is projected into '
          'a document; it is not part of the hydrated chart configuration that '
          'ChartConfigDartEmitter reconstructs.',
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

// ===========================================================================
// CLASS-AWARE gate allowlists (see the class-aware group's docstring below).
// ===========================================================================

/// Modelled classes that DO produce an attributed construction block but whose
/// block body is NOT the class's field emission — so the class-aware slice
/// cannot see its coverage and it stays on the flat-union gate. Each is a
/// `*Fields` helper whose `<Class>(` opener lives in a THIN caller
/// (`_emitYAxis` / `_emitXAxis` / `_emitTheme` / `_emitInteraction`) that only
/// calls `writer.indented(() => _emit…Fields(writer, value))`; the fields are
/// written one method away, outside the opener→`),` slice. The flat-union gate
/// (which scans the whole file) already proves these are emitted, so excluding
/// them here is honest, not a hole. Removing a helper's indirection (inlining
/// its fields into the caller's block) is what lets its entry be deleted.
const Map<String, String> _classAwareResidualClasses = <String, String>{
  'XAxisConfig':
      'Emitted via _emitAxisFields; the XAxisConfig( opener in _emitXAxis only '
          'calls the helper, so the construction-block slice carries none of the '
          'axis field names. Covered by the flat-union gate.',
  'YAxisConfig':
      'Emitted via _emitYAxisFields; the YAxisConfig( opener in _emitYAxis only '
          'calls the helper, so the construction-block slice carries none of the '
          'axis field names. Covered by the flat-union gate.',
  'ChartTheme':
      'Emitted via _emitResolvedThemeFields; the ChartTheme( opener in _emitTheme '
          'only calls the helper, so the construction-block slice carries none of '
          'the theme component names. Covered by the flat-union gate.',
  'InteractionConfig':
      'Emitted via _emitInteractionFields; the InteractionConfig( opener only '
          'calls the helper, so the construction-block slice carries none of the '
          'interaction field names. Covered by the flat-union gate.',
};

/// Individual `Class.property` pairs the class-aware slice reports as a gap and
/// that are deliberately NOT emitted, one reviewed reason each. Unlike a parser
/// miss (a whole excluded class) these are per-property structural non-emits
/// inside a block that IS correctly attributed.
const Map<String, String> _classAwareExpectedGaps = <String, String>{};

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

/// Attributes emitted property names to the CLASS whose construction block
/// names them — the class-aware complement to the flat [_emitterMentions]
/// union.
///
/// In scope: construction blocks opened by a LITERAL-ClassName
/// `writer.writeLine('<field>: <ClassName>(')` — where `<field>: ` may be absent
/// (a bare list element like `ChartDataPoint(`) or a `$var` — whose matching
/// `writer.writeLine('),')` close is found in the SAME method (paren-balanced,
/// stopping at the method's own `^  }` line). For each block, the existing
/// [_emitterMentions] regexes run over the block slice and the names are
/// attributed to `<ClassName>` (unioned across every block of that class).
///
/// Out of scope (never matched, so they stay on the flat-union gate): openers
/// whose ClassName is a `$constructor` / `$argument: $constructor` dispatch
/// (`_emitSeries` / `_emitAnnotation` / `_emitRadialStyle`), sealed-union
/// named constructors ending in `.lowercase(` (`RangeAreaDataPoint.gap(`,
/// `CartesianValueSummaryContent.automatic(`, …) and controller calls
/// (`$controllerName.restoreViewState(`). A block whose close is not in the
/// method — the `*Fields` helpers whose opener lives in the caller
/// (`_emitYAxisFields`, `_emitAxisFields`, `_emitResolvedThemeFields`,
/// `_emitInteractionFields`) — is attributed with an empty body; those classes
/// are declared as [_classAwareResidualClasses] parser misses, not pinned.
({Map<String, Set<String>> mentions, Map<String, int> blocks})
    _attributeConstructionBlocks(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final openerRe = RegExp(
      r"""writer\.writeLine\('(?:[A-Za-z_$][\w$]*: )?([A-Z][A-Za-z0-9_]*)\('\)""");
  final anyOpenerRe = RegExp(r"""writer\.writeLine\('[^']*\('\)""");
  final closerRe = RegExp(r"""writer\.writeLine\('\),'\)""");
  final methodEndRe = RegExp(r'^  \}$');

  final mentions = <String, Set<String>>{};
  final blocks = <String, int>{};

  for (var i = 0; i < lines.length; i++) {
    final match = openerRe.firstMatch(lines[i]);
    if (match == null) continue;
    final className = match.group(1)!;
    var depth = 1;
    var closeLine = -1;
    for (var j = i + 1; j < lines.length; j++) {
      if (methodEndRe.hasMatch(lines[j])) break; // method ended: out of scope.
      if (closerRe.hasMatch(lines[j])) {
        depth--;
        if (depth == 0) {
          closeLine = j;
          break;
        }
      } else if (anyOpenerRe.hasMatch(lines[j])) {
        depth++;
      }
    }
    if (closeLine == -1) continue; // no in-method close: out of scope.
    final slice = lines.sublist(i, closeLine + 1).join('\n');
    mentions
        .putIfAbsent(className, () => <String>{})
        .addAll(_emitterMentions(slice));
    blocks[className] = (blocks[className] ?? 0) + 1;
  }
  return (mentions: mentions, blocks: blocks);
}

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

  // =========================================================================
  // CLASS-AWARE gate (ADDITIVE — the flat-union tests above stay authoritative)
  //
  // The flat-union gate decides `isEmitted(property)` against ONE global name
  // set, so a property dropped by class B still counts as covered if class A
  // emits the same name (the documented collision blind spot). This group
  // closes that hole for the ROBUST SUBSET: classes emitted by an in-method
  // construction block with a LITERAL ClassName opener
  // (`writer.writeLine('<field>: <ClassName>(')`, `<field>: ` optional) whose
  // matching `writer.writeLine('),')` close is in the SAME method. For those,
  // it attributes the emitted names per class ([_attributeConstructionBlocks])
  // and checks each modelled property against ITS OWN class's block.
  //
  // Explicitly OUT of scope — these stay on the flat-union gate only:
  //   * `$constructor` / `$argument: $constructor` dispatch openers
  //     (`_emitSeries`, `_emitAnnotation`, `_emitRadialStyle`) → every series,
  //     annotation, and Pie/Donut style is auto-residual (no literal block).
  //   * sealed-union named constructors ending `.lowercase(`
  //     (`RangeAreaDataPoint.gap(`, `CartesianValueSummaryContent.automatic(`,
  //     the value-summary presentation/content ternaries) → auto-residual.
  //   * `*Fields` helpers whose `<Class>(` opener is in a thin caller
  //     (`XAxisConfig`, `YAxisConfig`, `ChartTheme`, `InteractionConfig`) →
  //     a block IS attributed but its body is empty, so they are declared
  //     [_classAwareResidualClasses] (a parser miss, NOT pinned per-property).
  //   * classes not emitted at all (StreamingConfig, AutoScrollConfig, …) →
  //     auto-residual, already pinned by the flat-union `_classesNotEmitted…`.
  // =========================================================================

  test('class-aware allowlists name real classes/properties with reasons', () {
    for (final className in _classAwareResidualClasses.keys) {
      expect(surface.containsKey(className), isTrue,
          reason: '$className is a class-aware residual but not a @chartSurface '
              'class — delete it from _classAwareResidualClasses.');
    }
    for (final key in _classAwareExpectedGaps.keys) {
      final parts = key.split('.');
      expect(surface.containsKey(parts[0]), isTrue,
          reason: '$key pins a property on ${parts[0]}, not a @chartSurface '
              'class.');
      expect(surface[parts[0]]!.contains(parts[1]), isTrue,
          reason: '$key pins property "${parts[1]}", which ${parts[0]} does not '
              'model — delete it from _classAwareExpectedGaps.');
      expect(_classAwareResidualClasses.containsKey(parts[0]), isFalse,
          reason: '$key pins a property on ${parts[0]}, which is already an '
              'excluded residual class — the per-property pin is redundant.');
    }
    for (final reason in [
      ..._classAwareResidualClasses.values,
      ..._classAwareExpectedGaps.values,
    ]) {
      expect(reason.length, greaterThanOrEqualTo(20),
          reason: 'a class-aware allowlist entry has a placeholder reason');
    }
  });

  test('every property is covered by its OWN class construction block', () {
    final attributed = _attributeConstructionBlocks(_emitterSource);
    final gaps = <String>[];
    for (final entry in surface.entries) {
      final className = entry.key;
      if (_classAwareResidualClasses.containsKey(className)) continue;
      final names = attributed.mentions[className];
      if (names == null) continue; // no in-scope block: the flat-union gate owns it.
      for (final property in entry.value) {
        if (names.contains(property)) continue;
        if (_classAwareExpectedGaps.containsKey('$className.$property')) continue;
        gaps.add('$className.$property');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason: 'NEW class-aware source-emitter drift: these properties are NOT '
          "named inside their own class's construction block in "
          'chart_config_dart_emitter.dart, even though a same-named property on '
          'another class may hide this from the flat-union gate. Add the _emit '
          'line to that block (with a source-generator test), or — if the '
          'property genuinely cannot be emitted there — pin it in '
          '_classAwareExpectedGaps (per-property) or exclude the whole class in '
          '_classAwareResidualClasses (only if the block is a parser miss):\n'
          '${gaps.join('\n')}',
    );
  });

  test('class-aware allowlists have no stale entries', () {
    final attributed = _attributeConstructionBlocks(_emitterSource);
    final staleGaps = _classAwareExpectedGaps.keys.where((key) {
      final parts = key.split('.');
      final names = attributed.mentions[parts[0]];
      return names != null && names.contains(parts[1]);
    }).toList()
      ..sort();
    expect(
      staleGaps,
      isEmpty,
      reason: 'these class-aware gaps are now covered by their block but still '
          'pinned. Delete them from _classAwareExpectedGaps:\n'
          '${staleGaps.join('\n')}',
    );
    // A residual-excluded class with no attributed block would be auto-residual
    // anyway, so its explicit exclusion is stale (or the block moved).
    final staleResidual = _classAwareResidualClasses.keys
        .where((className) => attributed.blocks[className] == null)
        .toList()
      ..sort();
    expect(
      staleResidual,
      isEmpty,
      reason: 'these classes have no attributed construction block, so they are '
          'already residual and do not need an explicit exclusion. Delete them '
          'from _classAwareResidualClasses:\n${staleResidual.join('\n')}',
    );
  });

  test('COVERAGE REPORT (not a gate): class-aware block attribution', () {
    final attributed = _attributeConstructionBlocks(_emitterSource);
    final gatedClasses = attributed.mentions.keys
        .where((c) =>
            surface.containsKey(c) &&
            !_classAwareResidualClasses.containsKey(c))
        .length;
    // ignore: avoid_print
    print(
      '\n[class-aware source emitter coverage]\n'
      '  attributed construction blocks: '
      '${attributed.blocks.values.fold<int>(0, (s, v) => s + v)}\n'
      '  classes with an attributed block: ${attributed.mentions.length}\n'
      '  in-scope gated classes:           $gatedClasses\n'
      '  residual (parser-miss) classes:   ${_classAwareResidualClasses.length}\n'
      '  per-property pinned gaps:         ${_classAwareExpectedGaps.length}\n'
      '  RESIDUAL SCOPE: series/annotations (\$constructor dispatch), Pie/Donut '
      'styles (_emitRadialStyle),\n'
      '  sealed-union named constructors, the *Fields-helper classes above, and '
      'the not-emitted\n'
      '  classes all stay on the flat-union gate — this check does not pretend '
      'to attribute them.',
    );
    expect(attributed.mentions, isNotEmpty);
  });
}
