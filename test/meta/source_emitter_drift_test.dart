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

// ===========================================================================
// PER-SERIES gate (see the per-series group's docstring below).
//
// The concrete series subclasses are constructed through the SHARED
// `writer.writeLine('$constructor(')` opener in `_emitSeries` (a `$constructor`
// dispatch), so the class-aware block attributor skips them entirely — they
// never get a literal-ClassName construction block. That auto-residual bucket
// is exactly where adversarial verification of slice 3c found the
// line/area-series-emitter drops hiding (a same-named field on
// RangeAreaChartSeries covered them in the flat union). This gate attributes
// each series' emitted names EXPLICITLY, by method, closing that hole.
// ===========================================================================

/// Every manifest series subclass keyed to the emit method(s) whose bodies —
/// unioned with the shared `_emitSeries` base slice ([_sharedSeriesBaseSlice])
/// — NAME that series' modelled fields. Read off the `switch (series)` type
/// dispatch in `_emitSeries` (chart_config_dart_emitter.dart).
///
/// A field whose VALUE is passed at the call site (`_emitX(writer,
/// series.foo)`) is named in the entry method directly. A field emitted inside
/// a helper that receives the WHOLE `series` object (so it reads `series.foo`
/// internally) needs that helper listed too — that is why area lists
/// `_emitLineLikeAreaOptions` and pie/donut list `_emitAdvancedRadial`.
///
/// `ScatterChartSeries` is the one series emitted INLINE in the `_emitSeries`
/// switch (no dedicated `_emit…Options` method); it maps to the empty list and
/// is covered by the scatter-case slice ([_scatterCaseSlice]).
const Map<String, List<String>> _seriesEmitMethods = <String, List<String>>{
  'LineChartSeries': <String>['_emitLineOptions'],
  'AreaChartSeries': <String>['_emitAreaOptions', '_emitLineLikeAreaOptions'],
  'RangeAreaChartSeries': <String>['_emitRangeAreaOptions'],
  'HeatmapChartSeries': <String>['emitHeatmapOptions'],
  'CandlestickChartSeries': <String>['_emitCandlestickOptions'],
  'BarChartSeries': <String>['_emitBarOptions'],
  'PieChartSeries': <String>['_emitPieOptions', '_emitAdvancedRadial'],
  'DonutChartSeries': <String>['_emitDonutOptions', '_emitAdvancedRadial'],
  'PolarColumnChartSeries': <String>['_emitPolarColumnOptions'],
  'RadialBarChartSeries': <String>['_emitRadialBarOptions'],
  'GaugeChartSeries': <String>['_emitGaugeSeries'],
  'ScatterChartSeries': <String>[],
};

/// `Series.property` pairs the per-series slice reports as a gap and that are
/// deliberately NOT emitted, one reviewed reason each. Kept empty unless a
/// series genuinely cannot round-trip a field through direct construction; a
/// slice that reports MANY gaps means [_seriesEmitMethods] is missing a
/// delegated helper, not that the gaps should be pinned.
const Map<String, String> _seriesExpectedGaps = <String, String>{};

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
  for (final match in RegExp(
    r"""(?:!|\?)?\.([a-z][A-Za-z0-9_]*)\b""",
  ).allMatches(source))
    match.group(1)!,
  for (final match in RegExp(r"""'([a-z][A-Za-z0-9_]*)'""").allMatches(source))
    match.group(1)!,
  for (final match in RegExp(
    r""":\s*final\s+([a-z][A-Za-z0-9_]*)""",
  ).allMatches(source))
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
    r"""writer\.writeLine\('(?:[A-Za-z_$][\w$]*: )?([A-Z][A-Za-z0-9_]*)\('\)""",
  );
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

/// Slices a single emitter method body by brace depth: from its
/// `void <name>(` opener to the matching method-close (`^  }` at brace depth 0,
/// the same 2-space method boundary [_attributeConstructionBlocks] uses).
/// Returns '' if the method is not found.
String _methodSlice(String source, String methodName) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final startRe = RegExp('void ${RegExp.escape(methodName)}\\(');
  final methodEndRe = RegExp(r'^  \}$');
  for (var i = 0; i < lines.length; i++) {
    if (!startRe.hasMatch(lines[i])) continue;
    for (var j = i + 1; j < lines.length; j++) {
      if (methodEndRe.hasMatch(lines[j])) {
        return lines.sublist(i, j + 1).join('\n');
      }
    }
  }
  return '';
}

/// The fields every series emits UNCONDITIONALLY: the `_emitSeries` body BEFORE
/// its `switch (series)` type dispatch (minus the `isXOrdered` gate, see below),
/// plus the shared `_emitPoints` helper.
///
/// `style` and `isXOrdered` are DELIBERATELY excluded from this shared slice.
/// Both are written through a per-series RUNTIME allowlist — `style` via the
/// `_emitSeriesStyle` `if (series is …)` allowlist, `isXOrdered` via the
/// `if (series is! …)` negative gate around its `_valueIf`. Unioning either into
/// every series' slice would credit ALL series with the field regardless of that
/// allowlist, so a regression that dropped a series from the emitter's allowlist
/// would NOT be caught (the latent unsoundness slice 3f closes). They are
/// attributed per-series in [_seriesEmittedNames] against the SAME allowlists,
/// parsed from source ([_styleAllowlist] / [_isXOrderedExcluded]).
String _sharedSeriesBaseSlice(String source) {
  final emitSeries = _methodSlice(source, '_emitSeries');
  // Two `switch (series)` occur: the `final constructor = switch (series)`
  // class-name expression at the top, then the type-dispatch `switch (series)`
  // that runs the per-series emit. The shared base is everything before the
  // dispatch (the LAST occurrence) — including the base-field emission between
  // the two switches.
  final switchIdx = emitSeries.lastIndexOf('switch (series)');
  final base = switchIdx == -1
      ? emitSeries
      : emitSeries.substring(0, switchIdx);
  // Strip the isXOrdered gate (the `if (series is! …) { _valueIf(… 'isXOrdered'
  // …); }` block) so the shared base does not credit `isXOrdered` to every
  // series — it is attributed per-series below.
  final baseWithoutIsXOrdered = base.replaceAll(
    RegExp(r"if \(series is![\s\S]*?'isXOrdered'[\s\S]*?\n\s*\}\n"),
    '\n',
  );
  return <String>[
    baseWithoutIsXOrdered,
    _methodSlice(source, '_emitPoints'),
    // _emitSeriesStyle is intentionally NOT unioned here — `style` is
    // attributed per-series in _seriesEmittedNames.
  ].join('\n');
}

/// Series the emitter's `_emitSeriesStyle` positive allowlist names with
/// `series is <ClassName>`, parsed from the method body. A series dropped from
/// this allowlist loses its `style` credit in [_seriesEmittedNames], so the
/// per-series gate fails for it — this is what makes the gate non-vacuous. The
/// base type, admitted via `runtimeType ==`, is deliberately not parsed (it is
/// not a manifest series, so it is never checked by the gate).
Set<String> _styleAllowlist(String source) {
  final method = _methodSlice(source, '_emitSeriesStyle');
  return <String>{
    for (final match in RegExp(r'series is (\w+)').allMatches(method))
      match.group(1)!,
  };
}

/// Series the emitter EXCLUDES from `isXOrdered` emission, parsed from the
/// `series is! <ClassName>` negative gate around the `'isXOrdered'` `_valueIf`
/// in `_emitSeries`. A series emits `isXOrdered` iff it is NOT in this set.
Set<String> _isXOrderedExcluded(String source) {
  final emitSeries = _methodSlice(source, '_emitSeries');
  final gate = RegExp(
    r"if \(series is![\s\S]*?'isXOrdered'",
  ).firstMatch(emitSeries);
  if (gate == null) return const <String>{};
  return <String>{
    for (final match in RegExp(r'series is! (\w+)').allMatches(gate.group(0)!))
      match.group(1)!,
  };
}

/// `ScatterChartSeries` is emitted INLINE in the `_emitSeries` switch (no
/// dedicated `_emit…Options` method). Slices its `case ScatterChartSeries():`
/// arm up to the next `case` label.
String _scatterCaseSlice(String source) {
  final emitSeries = _methodSlice(source, '_emitSeries');
  const marker = 'case ScatterChartSeries():';
  final start = emitSeries.indexOf(marker);
  if (start == -1) return '';
  final rest = emitSeries.substring(start + marker.length);
  final nextCase = RegExp(r'\n\s*case ').firstMatch(rest);
  return nextCase == null ? rest : rest.substring(0, nextCase.start);
}

/// The union of emitted names for a series: shared base + its mapped method
/// bodies (+ the scatter-case slice for the inline scatter series), plus the
/// per-series `style` / `isXOrdered` attribution.
///
/// `style` and `isXOrdered` are NOT in the shared base slice (they are written
/// through per-series runtime allowlists — see [_sharedSeriesBaseSlice]). They
/// are attributed here against the SAME allowlists parsed from the emitter
/// source, so a series is credited a field iff the emitter actually emits it
/// for that series. Dropping a series from the emitter's allowlist therefore
/// makes this gate fail for that series (non-vacuous).
Set<String> _seriesEmittedNames(String source, String className) {
  final parts = <String>[_sharedSeriesBaseSlice(source)];
  if (className == 'ScatterChartSeries') parts.add(_scatterCaseSlice(source));
  for (final method in _seriesEmitMethods[className] ?? const <String>[]) {
    parts.add(_methodSlice(source, method));
  }
  final names = _emitterMentions(parts.join('\n'));
  if (_styleAllowlist(source).contains(className)) names.add('style');
  if (!_isXOrderedExcluded(source).contains(className)) {
    names.add('isXOrdered');
  }
  return names;
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
    expect(
      surface,
      hasLength(greaterThan(80)),
      reason: 'the surface manifest resolved almost no classes',
    );
    expect(
      surface.values.fold<int>(0, (sum, props) => sum + props.length),
      greaterThan(700),
      reason: 'the surface manifest resolved almost no properties',
    );
    expect(
      mentioned,
      hasLength(greaterThan(500)),
      reason:
          'the emitter scan found almost no names — the emitter was '
          'probably restructured and this extraction needs revisiting',
    );
    // Spot-check a property known to be emitted and one class known to exist.
    expect(surface.containsKey('LegendStyle'), isTrue);
    expect(isEmitted('strokeWidth'), isTrue);
  });

  test('every reviewed hole names a real class/property and a real reason', () {
    for (final className in _classesNotEmittedBySource.keys) {
      expect(
        surface.containsKey(className),
        isTrue,
        reason:
            '$className is pinned as not-emitted but is not a '
            '@chartSurface class in the manifest — delete it from '
            '_classesNotEmittedBySource.',
      );
    }
    for (final key in _propertyGaps.keys) {
      final parts = key.split('.');
      final className = parts[0];
      final property = parts[1];
      expect(
        surface.containsKey(className),
        isTrue,
        reason:
            '$key pins a property on $className, which is not a '
            '@chartSurface class.',
      );
      expect(
        _classesNotEmittedBySource.containsKey(className),
        isFalse,
        reason:
            '$key pins a property on $className, but $className is already '
            'pinned as a whole not-emitted class — a property gap there is '
            'redundant.',
      );
      expect(
        surface[className]!.contains(property),
        isTrue,
        reason:
            '$key pins property "$property", which $className does not '
            'model — delete it from _propertyGaps.',
      );
    }
    for (final reason in [
      ..._classesNotEmittedBySource.values,
      ..._propertyGaps.values,
    ]) {
      expect(
        reason.length,
        greaterThanOrEqualTo(20),
        reason: 'a pinned hole has a placeholder reason',
      );
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
      reason:
          'NEW source-emitter drift: these modelled config properties are '
          'not named anywhere in chart_config_dart_emitter.dart, so the '
          'generated Source silently drops them on round-trip. Add an '
          '_emit path (with a source-generator test proving the property '
          'appears for a non-default value), or — if the property genuinely '
          'cannot be emitted — pin it in _propertyGaps with a reason:\n'
          '${gaps.join('\n')}',
    );
  });

  test('the pinned property gaps are all still real', () {
    final stale =
        _propertyGaps.keys.where((key) => isEmitted(key.split('.')[1])).toList()
          ..sort();
    expect(
      stale,
      isEmpty,
      reason:
          'these property gaps are now emitted but still pinned. Delete '
          'them from _propertyGaps:\n${stale.join('\n')}',
    );
  });

  test(
    'COVERAGE REPORT (not a gate): source-emitter coverage of the surface',
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
    },
  );

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
      expect(
        surface.containsKey(className),
        isTrue,
        reason:
            '$className is a class-aware residual but not a @chartSurface '
            'class — delete it from _classAwareResidualClasses.',
      );
    }
    for (final key in _classAwareExpectedGaps.keys) {
      final parts = key.split('.');
      expect(
        surface.containsKey(parts[0]),
        isTrue,
        reason:
            '$key pins a property on ${parts[0]}, not a @chartSurface '
            'class.',
      );
      expect(
        surface[parts[0]]!.contains(parts[1]),
        isTrue,
        reason:
            '$key pins property "${parts[1]}", which ${parts[0]} does not '
            'model — delete it from _classAwareExpectedGaps.',
      );
      expect(
        _classAwareResidualClasses.containsKey(parts[0]),
        isFalse,
        reason:
            '$key pins a property on ${parts[0]}, which is already an '
            'excluded residual class — the per-property pin is redundant.',
      );
    }
    for (final reason in [
      ..._classAwareResidualClasses.values,
      ..._classAwareExpectedGaps.values,
    ]) {
      expect(
        reason.length,
        greaterThanOrEqualTo(20),
        reason: 'a class-aware allowlist entry has a placeholder reason',
      );
    }
  });

  test('every property is covered by its OWN class construction block', () {
    final attributed = _attributeConstructionBlocks(_emitterSource);
    final gaps = <String>[];
    for (final entry in surface.entries) {
      final className = entry.key;
      if (_classAwareResidualClasses.containsKey(className)) continue;
      final names = attributed.mentions[className];
      if (names == null) {
        continue; // no in-scope block: the flat-union gate owns it.
      }
      for (final property in entry.value) {
        if (names.contains(property)) continue;
        if (_classAwareExpectedGaps.containsKey('$className.$property')) {
          continue;
        }
        gaps.add('$className.$property');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason:
          'NEW class-aware source-emitter drift: these properties are NOT '
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
    }).toList()..sort();
    expect(
      staleGaps,
      isEmpty,
      reason:
          'these class-aware gaps are now covered by their block but still '
          'pinned. Delete them from _classAwareExpectedGaps:\n'
          '${staleGaps.join('\n')}',
    );
    // A residual-excluded class with no attributed block would be auto-residual
    // anyway, so its explicit exclusion is stale (or the block moved).
    final staleResidual =
        _classAwareResidualClasses.keys
            .where((className) => attributed.blocks[className] == null)
            .toList()
          ..sort();
    expect(
      staleResidual,
      isEmpty,
      reason:
          'these classes have no attributed construction block, so they are '
          'already residual and do not need an explicit exclusion. Delete them '
          'from _classAwareResidualClasses:\n${staleResidual.join('\n')}',
    );
  });

  test('COVERAGE REPORT (not a gate): class-aware block attribution', () {
    final attributed = _attributeConstructionBlocks(_emitterSource);
    final gatedClasses = attributed.mentions.keys
        .where(
          (c) =>
              surface.containsKey(c) &&
              !_classAwareResidualClasses.containsKey(c),
        )
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
      '  RESIDUAL SCOPE: annotations (\$constructor dispatch), Pie/Donut '
      'styles (_emitRadialStyle),\n'
      '  sealed-union named constructors, the *Fields-helper classes above, and '
      'the not-emitted\n'
      '  classes stay on the flat-union gate — this check does not pretend '
      'to attribute them.\n'
      '  The series subclasses (also \$constructor dispatch) are now covered by '
      'the per-series gate below.',
    );
    expect(attributed.mentions, isNotEmpty);
  });

  // =========================================================================
  // PER-SERIES gate (ADDITIVE — closes the $constructor-dispatch blind spot)
  //
  // Every concrete series is emitted through the shared
  // `writer.writeLine('$constructor(')` opener in `_emitSeries`, so the
  // class-aware attributor above skips them (no literal-ClassName block) and
  // they were left to the flat-union gate — where a same-named field on a
  // sibling series hid the line/area-emitter drops slice 3c missed. This gate
  // attributes each series' emitted names by an EXPLICIT method map
  // ([_seriesEmitMethods], read off the `switch (series)` dispatch) unioned
  // with the shared `_emitSeries` base, and checks each series' modelled
  // properties against ITS OWN slice. Annotations remain residual (the same
  // pattern could extend to them — a follow-up slice).
  // =========================================================================

  test('the per-series map covers every manifest series subclass', () {
    final manifestSeries = surface.keys
        .where((c) => c.endsWith('Series'))
        .toSet();
    final unmapped =
        manifestSeries.difference(_seriesEmitMethods.keys.toSet()).toList()
          ..sort();
    expect(
      unmapped,
      isEmpty,
      reason:
          'these manifest series subclasses are NOT mapped in '
          '_seriesEmitMethods — add each with the emit method(s) that name its '
          'fields. This is the maintenance guard: a new series must be wired '
          'into the per-series gate or it silently escapes coverage:\n'
          '${unmapped.join('\n')}',
    );
    final stale =
        _seriesEmitMethods.keys.toSet().difference(manifestSeries).toList()
          ..sort();
    expect(
      stale,
      isEmpty,
      reason:
          'these _seriesEmitMethods keys are not @chartSurface series '
          'classes in the manifest — delete them:\n${stale.join('\n')}',
    );
    // Every method the slicer names must resolve to a real, non-empty body, or
    // a rename would make the gate silently vacuous.
    final source = _emitterSource;
    final missing = <String>[];
    for (final method in <String>{
      '_emitSeries',
      '_emitPoints',
      '_emitSeriesStyle',
      for (final methods in _seriesEmitMethods.values) ...methods,
    }) {
      if (_methodSlice(source, method).isEmpty) missing.add(method);
    }
    missing.sort();
    expect(
      missing,
      isEmpty,
      reason:
          'these methods named by the per-series slicer no longer exist in '
          'chart_config_dart_emitter.dart (renamed?) — update '
          '_seriesEmitMethods / the slicers:\n${missing.join('\n')}',
    );
    expect(
      _scatterCaseSlice(source),
      isNotEmpty,
      reason:
          'the inline ScatterChartSeries case in _emitSeries was not found '
          '— the scatter-case slicer needs revisiting.',
    );
  });

  test('every series subclass emits all its modelled fields', () {
    final source = _emitterSource;
    final gaps = <String>[];
    for (final entry in _seriesEmitMethods.entries) {
      final className = entry.key;
      final props = surface[className];
      if (props == null) continue; // completeness asserted separately.
      final names = _seriesEmittedNames(source, className);
      for (final property in props) {
        if (names.contains(property)) continue;
        if (_seriesExpectedGaps.containsKey('$className.$property')) continue;
        gaps.add('$className.$property');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason:
          'NEW per-series source-emitter drift: these modelled series '
          "properties are NOT named inside their own series' emit method(s) "
          'plus the shared _emitSeries base, even though a same-named property '
          'on another series can hide this from the flat-union gate (the '
          "slice-3c blind spot). Add the _emit line to that series' method "
          '(with a source-generator round-trip test); or, if a delegated '
          'helper that reads series.<field> internally is missing from the '
          'slice, add it to _seriesEmitMethods (do NOT pin a batch of gaps — '
          'that means the slice is wrong). A genuine structural non-emit goes '
          'in _seriesExpectedGaps with a reason:\n${gaps.join('\n')}',
    );
  });

  test('style and isXOrdered are attributed per-series against the emitter '
      'allowlists, not credited via the shared base slice', () {
    final source = _emitterSource;

    // (1) STRUCTURAL: the shared series base slice must credit NEITHER field.
    // If it did, every series would count as covered regardless of the
    // emitter's runtime allowlist — the latent unsoundness this closes: a
    // series dropped from the _emitSeriesStyle allowlist (or added to the
    // isXOrdered negative gate) would still pass the per-series gate because
    // the shared base carried the field name for all series.
    final baseNames = _emitterMentions(_sharedSeriesBaseSlice(source));
    expect(
      baseNames.contains('style'),
      isFalse,
      reason:
          'the shared series base slice still names `style`; exclude '
          "_emitSeriesStyle's body from _sharedSeriesBaseSlice so `style` is "
          'attributed per-series.',
    );
    expect(
      baseNames.contains('isXOrdered'),
      isFalse,
      reason:
          'the shared series base slice still names `isXOrdered`; strip '
          'its _valueIf gate from _sharedSeriesBaseSlice so it is attributed '
          'per-series.',
    );

    // (2) The mirrored allowlists parse a plausible set — a rename/refactor that
    // emptied them would make the per-series enforcement below vacuous.
    final styleAllowlist = _styleAllowlist(source);
    final isXOrderedExcluded = _isXOrderedExcluded(source);
    expect(
      styleAllowlist,
      contains('LineChartSeries'),
      reason: 'could not parse the _emitSeriesStyle `series is` allowlist',
    );
    expect(
      isXOrderedExcluded,
      contains('CandlestickChartSeries'),
      reason: 'could not parse the isXOrdered `series is!` negative gate',
    );

    // (3) Each manifest series that MODELS the field is credited iff the
    // emitter's own allowlist emits it for that series — required-covered for
    // the emitting series, and (via step 1) NOT credited for the others.
    final gaps = <String>[];
    for (final className in _seriesEmitMethods.keys) {
      final props = surface[className];
      if (props == null) continue;
      final names = _seriesEmittedNames(source, className);
      if (props.contains('style') && !names.contains('style')) {
        gaps.add('$className.style');
      }
      if (props.contains('isXOrdered') && !names.contains('isXOrdered')) {
        gaps.add('$className.isXOrdered');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason:
          'these series model style/isXOrdered but the emitter allowlist '
          'parsed from source does NOT emit them for that series, so they are '
          'dropped on round-trip:\n${gaps.join('\n')}',
    );
  });

  test('per-series expected gaps name real series/properties with reasons', () {
    for (final key in _seriesExpectedGaps.keys) {
      final parts = key.split('.');
      expect(
        _seriesEmitMethods.containsKey(parts[0]),
        isTrue,
        reason:
            '$key pins a property on ${parts[0]}, which is not a mapped '
            'series in _seriesEmitMethods.',
      );
      expect(
        surface[parts[0]]?.contains(parts[1]) ?? false,
        isTrue,
        reason:
            '$key pins property "${parts[1]}", which ${parts[0]} does not '
            'model — delete it from _seriesExpectedGaps.',
      );
    }
    for (final reason in _seriesExpectedGaps.values) {
      expect(
        reason.length,
        greaterThanOrEqualTo(20),
        reason: 'a per-series expected gap has a placeholder reason',
      );
    }
  });

  test('per-series expected gaps have no stale entries', () {
    final source = _emitterSource;
    final stale = _seriesExpectedGaps.keys.where((key) {
      final parts = key.split('.');
      return _seriesEmittedNames(source, parts[0]).contains(parts[1]);
    }).toList()..sort();
    expect(
      stale,
      isEmpty,
      reason:
          'these per-series gaps are now named by their series slice but '
          'still pinned. Delete them from _seriesExpectedGaps:\n'
          '${stale.join('\n')}',
    );
  });

  test('COVERAGE REPORT (not a gate): per-series slice attribution', () {
    final source = _emitterSource;
    var modelled = 0;
    var named = 0;
    for (final className in _seriesEmitMethods.keys) {
      final props = surface[className];
      if (props == null) continue;
      final names = _seriesEmittedNames(source, className);
      for (final property in props) {
        modelled++;
        if (names.contains(property)) named++;
      }
    }
    // ignore: avoid_print
    print(
      '\n[per-series source emitter coverage]\n'
      '  series subclasses gated:     ${_seriesEmitMethods.length}\n'
      '  modelled series properties:  $modelled\n'
      '  named by own series slice:   $named of $modelled\n'
      '  per-series pinned gaps:      ${_seriesExpectedGaps.length}',
    );
    expect(_seriesEmitMethods, isNotEmpty);
  });
}
