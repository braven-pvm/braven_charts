import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// BIDIRECTIONAL drift between the AI tool schema and the parser that
/// consumes it.
///
/// ## What the real contract is
///
/// `ChartToolSchema.createChartTool` is not a mirror of any class. It is a
/// flat LLM VOCABULARY: snake_case property names invented for the agent
/// protocol, which `ChartConfigBuilder` reads back as literal map keys
/// (`json['bar_corner_radius']`). Nothing type-checks that relationship — a
/// key can be documented and never parsed, or parsed and never documented,
/// and both compile, ship, and pass every existing test.
///
/// Both failures are live in this repository today. This file measures them
/// in both directions and pins the current set, so CI stays green while the
/// gaps are recorded, visible, and unable to grow.
///
/// ## Extraction method, and its error profile
///
/// The two sides are extracted differently ON PURPOSE, because the two
/// directions punish opposite errors.
///
/// **Schema side — structural, exact.** The tool maps are real Dart values,
/// so the documented set is every key of every `properties` map, collected
/// recursively. No parsing, no false positives. It is deliberately FLATTENED
/// across nesting levels: comparing full JSON paths would produce noise from
/// keys that are documented at the right level for a nested object but read
/// by a builder helper that receives that object directly. The cost is stated
/// plainly — a key documented at the WRONG nesting level still passes this
/// gate. That is a weaker check than path equality and a much stronger one
/// than nothing.
///
/// **Builder side — two sets, one per direction.**
///
/// - `_parsedKeys` (used by the REVERSE gate) is CONSERVATIVE: only string
///   literals in an actual subscript position — `json['k']`, `style?['k']`,
///   `containsKey('k')`. Every one of these is unambiguously a map read of
///   the AI JSON; all nine identifiers that appear in that position in
///   `chart_config_builder.dart` are AI-JSON maps (`json`, `style`,
///   `pointJson`, `seriesJson`, `chartStyle`, `styleJson`, `point`, `range`,
///   `value`). False-positive rate: zero observed. Under-reads are possible
///   (a key read through a helper parameter is missed) and are harmless here
///   — they can only make the REVERSE gate report FEWER undocumented keys,
///   never invent one.
/// - `_mentionedKeys` (used by the FORWARD gate) is GENEROUS: every
///   snake_case string literal in the file, plus prefix expansion for the
///   `prefix: 'pie_shadow'` helper idiom, which builds `pie_shadow_color`,
///   `pie_shadow_blur`, ... at runtime from a stem no literal scan can see.
///   This direction must not cry wolf: the question it asks is "does the
///   builder know this word AT ALL", and a documented key the builder never
///   names is a real hole regardless of how it would have been read. False
///   NEGATIVES are the tradeoff — a key mentioned only in an error message
///   counts as known. The generosity is what makes the 5 survivors
///   trustworthy.
///
/// ## Gate style
///
/// Both gates follow the reviewed-hole idiom of
/// `surface_enforcement_test.dart`'s exemption allowlist: today's known gaps
/// are PINNED below with a one-line reason each, and the test fails on any
/// drift in either direction — a new gap, or a pinned one that was fixed
/// without being unpinned.

/// Documented in the tool schema, never parsed by `ChartConfigBuilder`.
///
/// Reviewed, one reason per entry. Removing a hole from the schema (or
/// teaching the builder to read it) means deleting its line here.
const Map<String, String> _documentedButNotParsed = <String, String>{
  'action':
      'modify_chart protocol key. ChartConfigBuilder only parses create_chart; '
          'modify_chart is dispatched by the agent host, not by this parser.',
  'parameters':
      'modify_chart protocol key — the action-specific payload, opaque to the '
          'builder for the same reason as `action`.',
  'analysis_type':
      'explain_data protocol key. explain_data returns analysis, never a '
          'chart, so no config is built from it.',
  'series_ids':
      'explain_data protocol key, scoping the analysis; same reason.',
  'line_interpolation':
      'REAL GAP: documented as an enum on create_chart.style, but '
          '_parseLineSeries hardcodes LineInterpolation.linear and never reads '
          'the key. An agent that sets it gets a straight-line chart and no '
          'error. Tracked with the candlestick gap below.',
};

/// Parsed by `ChartConfigBuilder`, absent from the tool schema.
///
/// All ten are the same product gap: candlestick styling the builder has
/// supported for some time and that an LLM cannot discover, because the tool
/// schema never offers the vocabulary. Seven of them DO appear in
/// `chart_tool_schema.dart` — but as siblings of `properties` and `required`
/// inside an `if` subschema, a position where JSON Schema ignores unknown
/// keywords outright. Source-present and consumer-invisible is the same thing
/// as absent, and this gate treats it as absent.
///
/// Fixing the schema literals is deliberately NOT part of this change (see
/// the convergence section of
/// `docs/superpowers/specs/2026-07-21-chart-grammar-design.md`); recording the
/// gap so it cannot widen is.
const Map<String, String> _parsedButNotDocumented = <String, String>{
  'candlestick_body_fill':
      'CandlestickChartStyle.bodyFillMode (hollow_rising | filled) — misplaced '
          'as a sibling of `properties` inside the create_chart `if` subschema.',
  'candlestick_body_width_factor':
      'CandlestickChartStyle.bodyWidthFactor — same misplacement.',
  'candlestick_border_width':
      'CandlestickChartStyle.borderWidth — same misplacement.',
  'candlestick_wick_width':
      'CandlestickChartStyle.wickWidth — same misplacement.',
  'candlestick_corner_radius':
      'CandlestickChartStyle.cornerRadius — same misplacement.',
  'candlestick_animation_mode':
      'CandlestickAnimation.mode (none | reveal) — same misplacement.',
  'candlestick_animation_stagger':
      'CandlestickAnimation.stagger — same misplacement.',
  'candlestick_density_grouping':
      'CandlestickDensityGrouping.enabled — absent from the schema entirely.',
  'candlestick_target_group_width':
      'CandlestickDensityGrouping.targetGroupWidth — absent entirely.',
  'candlestick_minimum_points_per_group':
      'CandlestickDensityGrouping.minimumPointsPerGroup — absent entirely.',
};

/// Config classes `ChartConfigBuilder` constructs that the surface model
/// cannot see.
///
/// Every one of them is immutable-with-no-`copyWith`, so the enforcement rule
/// in `surface_enforcement_test.dart` — "config-shaped" means "instantiable,
/// public and has a `copyWith`" — does not consider them config at all, and
/// annotating them would generate an empty extension. They are nonetheless
/// where a large share of the AI vocabulary LANDS: `bar_waterfall_*`,
/// `bar_label_*`, `scatter_*` and `candlestick_*` keys all lower onto this
/// list.
///
/// This is the quantified reason the hand-written literals cannot simply be
/// regenerated from `@chartSurface`: the generator has no view of the classes
/// that receive half the vocabulary.
///
/// The list may SHRINK (a class gains a `copyWith` and gets annotated); it may
/// not grow unnoticed.
const Set<String> _builderTargetsOutsideSurfaceModel = <String>{
  'BarBorderStyle',
  'BarBulletRange',
  'BarBulletStyle',
  'BarChartStyle',
  'BarDivergingStyle',
  'BarErrorBarStyle',
  'BarGradient',
  'BarInteractionStyle',
  'BarLabelCalloutStyle',
  'BarLabelStyle',
  'BarLollipopStyle',
  'BarMotionStyle',
  'BarPatternStyle',
  'BarTargetMarkerStyle',
  'BarTrackStyle',
  'BarWaterfallConnectorStyle',
  'BarWaterfallStyle',
  'CandlestickAnimationStyle',
  'CandlestickChartStyle',
  'ScatterBinConfig',
  'ScatterClusterConfig',
  'ScatterDensityConfig',
};

/// Types the builder names that are not config at all — the widget it builds,
/// its own result type, and Flutter/dart:core values.
const Set<String> _nonConfigConstructions = <String>{
  'BravenChartPlus',
  'ChartBuildResult',
  'Color',
  'Offset',
  'FormatException',
};

/// The AI config builder's source.
String get _builderSource => File(
      '${Directory.current.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}src${Platform.pathSeparator}ai'
      '${Platform.pathSeparator}chart_config_builder.dart',
    ).readAsStringSync();

/// Every key of every `properties` map in the tool schemas, flattened.
Set<String> _documentedKeys() {
  final keys = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (entry.key == 'properties' && entry.value is Map) {
          for (final key in (entry.value! as Map).keys) {
            if (key is String) keys.add(key);
          }
        }
        walk(entry.value);
      }
    } else if (node is List) {
      for (final item in node) {
        walk(item);
      }
    }
  }

  walk(ChartToolSchema.tools);
  return keys;
}

/// String literals in a MAP-SUBSCRIPT position — definitely parsed.
Set<String> _parsedKeys(String source) => <String>{
      for (final match
          in RegExp(r"""[A-Za-z_][A-Za-z0-9_]*\??\[\s*'([a-z0-9_]+)'\s*\]""")
              .allMatches(source))
        match.group(1)!,
      for (final match
          in RegExp(r"""containsKey\(\s*'([a-z0-9_]+)'\s*\)""")
              .allMatches(source))
        match.group(1)!,
    };

/// Every snake_case literal the builder names — plausibly known.
Set<String> _mentionedKeys(String source) => <String>{
      for (final match
          in RegExp(r"""'([a-z][a-z0-9_]*)'""").allMatches(source))
        match.group(1)!,
    };

/// Stems of the `prefix:`-style helpers, which build keys at runtime.
Set<String> _keyPrefixes(String source) => <String>{
      for (final match
          in RegExp(r"""prefix:\s*'([a-z][a-z0-9_]*)'""").allMatches(source))
        match.group(1)!,
    };

void main() {
  late Set<String> documented;
  late Set<String> parsed;
  late Set<String> mentioned;
  late Set<String> prefixes;

  setUpAll(() {
    final source = _builderSource;
    documented = _documentedKeys();
    parsed = _parsedKeys(source);
    mentioned = _mentionedKeys(source);
    prefixes = _keyPrefixes(source);
  });

  bool isKnownToBuilder(String key) =>
      mentioned.contains(key) ||
      prefixes.any((prefix) => key.startsWith('${prefix}_'));

  test('the extraction produced plausible sets', () {
    // A regex that silently stopped matching would make both gates vacuous.
    expect(documented, hasLength(greaterThan(200)),
        reason: 'the schema walk found almost no properties');
    expect(parsed, hasLength(greaterThan(150)),
        reason: 'the subscript scan found almost no keys — the builder was '
            'probably restructured away from literal map reads, and this '
            'file needs a new extraction method');
    expect(parsed.difference(mentioned), isEmpty,
        reason: 'every subscripted key must also be a mentioned literal — '
            'the generous set is not a superset of the conservative one, so '
            'one of the two regexes is wrong');
    expect(documented, contains('chart_type'));
    expect(parsed, contains('chart_type'));
  });

  test('FORWARD: every documented key is known to ChartConfigBuilder', () {
    final gaps = documented.where((key) => !isKnownToBuilder(key)).toSet();
    final unexpected = gaps.difference(_documentedButNotParsed.keys.toSet())
        .toList()
      ..sort();
    expect(
      unexpected,
      isEmpty,
      reason: 'NEW forward drift: these keys are documented to LLM callers '
          'but ChartConfigBuilder never names them, so setting them does '
          'nothing and reports no error. Either parse them, remove them from '
          'the schema, or pin them in _documentedButNotParsed with a '
          'reason:\n${unexpected.join('\n')}',
    );
  });

  test('FORWARD: the pinned forward gaps are all still real', () {
    final stale = _documentedButNotParsed.keys
        .where((key) => !documented.contains(key) || isKnownToBuilder(key))
        .toList()
      ..sort();
    expect(
      stale,
      isEmpty,
      reason: 'these forward gaps were fixed but are still pinned. Delete '
          'them from _documentedButNotParsed:\n${stale.join('\n')}',
    );
  });

  test('REVERSE: every key the builder parses is documented in the schema',
      () {
    final gaps = parsed.difference(documented);
    final unexpected = gaps.difference(_parsedButNotDocumented.keys.toSet())
        .toList()
      ..sort();
    expect(
      unexpected,
      isEmpty,
      reason: 'NEW reverse drift: ChartConfigBuilder reads these keys but the '
          'tool schema never offers them, so an LLM cannot discover chart '
          'styling this package already supports. Document them in '
          'chart_tool_schema.dart, or pin them in _parsedButNotDocumented '
          'with a reason:\n${unexpected.join('\n')}',
    );
  });

  test('REVERSE: the pinned reverse gaps are all still real', () {
    final stale = _parsedButNotDocumented.keys
        .where((key) => !parsed.contains(key) || documented.contains(key))
        .toList()
      ..sort();
    expect(
      stale,
      isEmpty,
      reason: 'these reverse gaps were fixed but are still pinned. Delete '
          'them from _parsedButNotDocumented:\n${stale.join('\n')}',
    );
  });

  test('the pinned candlestick gap is exactly the ten keys reviewed', () {
    final candlestick = parsed
        .difference(documented)
        .where((key) => key.startsWith('candlestick_'))
        .toList()
      ..sort();
    expect(candlestick, hasLength(10));
    expect(
      candlestick,
      unorderedEquals(
        _parsedButNotDocumented.keys
            .where((key) => key.startsWith('candlestick_')),
      ),
    );
  });

  test('every pinned hole carries a real reason', () {
    for (final entry in <MapEntry<String, String>>[
      ..._documentedButNotParsed.entries,
      ..._parsedButNotDocumented.entries,
    ]) {
      expect(
        entry.value.length,
        greaterThanOrEqualTo(20),
        reason: '${entry.key} has a placeholder reason',
      );
    }
  });

  test('COVERAGE REPORT (not a gate): how much of the builder\'s vocabulary '
      'the surface model can see', () {
    // Reported, never asserted. The AI vocabulary is flat and the surface
    // model is class-keyed, so there is no function from one to the other —
    // this is the count that would have to move before a class-derived
    // schema could replace the hand-written literals.
    final definitions = ChartToolSchema.surfaceDefinitions;
    final modelled = <String>{
      for (final value in definitions.values)
        ...((value! as Map<String, Object?>)['properties']!
                as Map<String, Object?>)
            .keys,
    };
    // The builder's keys are snake_case; the model's are camelCase. Compare
    // on a normalized form, which is the most favourable possible mapping.
    String normalize(String name) => name.toLowerCase().replaceAll('_', '');
    final modelledNormalized = modelled.map(normalize).toSet();
    final covered =
        parsed.where((key) => modelledNormalized.contains(normalize(key)))
            .length;
    // ignore: avoid_print
    print(
      '\n[ai mirror drift]\n'
      '  documented keys:            ${documented.length}\n'
      '  builder keys (subscripted): ${parsed.length}\n'
      '  builder keys (mentioned):   ${mentioned.length}\n'
      '  forward gaps (pinned):      ${_documentedButNotParsed.length}\n'
      '  reverse gaps (pinned):      ${_parsedButNotDocumented.length}\n'
      '  surface classes modelled:   ${definitions.length}\n'
      '  builder keys whose NAME matches a modelled parameter: '
      '$covered/${parsed.length}\n'
      '  => ${parsed.length - covered} of the builder\'s keys have no '
      'same-named parameter\n'
      '     anywhere in the surface model. They lower onto classes the model '
      'cannot\n'
      '     see (no copyWith, so no @chartSurface) or onto names the '
      'vocabulary\n'
      '     invented. This is why the 1,698 hand-written literals cannot '
      'simply be\n'
      '     regenerated.',
    );
    expect(covered, lessThanOrEqualTo(parsed.length));
  });

  test('the builder\'s unmodelled construction targets have not grown', () {
    final constructed = <String>{
      for (final match
          in RegExp(r'\b([A-Z][A-Za-z0-9_]*)\s*\(').allMatches(_builderSource))
        match.group(1)!,
    };
    final outside = constructed
        .where((name) =>
            !ChartToolSchema.surfaceDefinitions.containsKey(name) &&
            !_nonConfigConstructions.contains(name))
        .toList()
      ..sort();

    // ignore: avoid_print
    print(
      '\n[ai mirror drift] ChartConfigBuilder constructs '
      '${constructed.length} types; '
      '${constructed.where(ChartToolSchema.surfaceDefinitions.containsKey).length}'
      ' are in the surface model, ${outside.length} are not:\n'
      '  ${outside.join('\n  ')}',
    );

    final grown = outside
        .where((name) => !_builderTargetsOutsideSurfaceModel.contains(name))
        .toList();
    expect(
      grown,
      isEmpty,
      reason: 'the builder now constructs config classes the surface model '
          'cannot see, beyond the reviewed set. Give them a copyWith and '
          '@chartSurface, or pin them in '
          '_builderTargetsOutsideSurfaceModel:\n${grown.join('\n')}',
    );
  });
}
