import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// DRIFT GATE for the artifact codec — the config's save/restore MIRROR.
///
/// ## What the real contract is
///
/// The `lib/src/artifacts/*_document_codec.dart` family is the hand-maintained
/// mirror that persists a chart configuration to a portable document and reads
/// it back: every `@chartSurface` config class is `_encodeX(x)` → JSON and
/// `_decodeX(map)` → `X(...)`. Nothing type-checks that relationship. Adding a
/// property to a config class and forgetting the matching encode OR decode line
/// drifts silently — the value is simply LOST on save/restore and no existing
/// test fails. An encode-present / decode-absent field is the worst case: it is
/// written to the artifact and then dropped when the artifact is restored (the
/// `categoryValue`-class bug this gate is built to catch).
///
/// This gate is the sibling of `source_emitter_drift_test.dart`. It measures,
/// per class, which modelled properties the codec ENCODES and which it DECODES,
/// pins today's reviewed gaps, and fails on any NEW gap or any encode/decode
/// ASYMMETRY.
///
/// ## Source of truth
///
/// The surface side is the GENERATED manifest `ChartToolSchema.surfaceDefinitions`
/// (`lib/src/ai/generated/surface_definitions.dart`): every `@chartSurface`
/// class keyed to its structural `properties` (123 classes, 1,152 props). It is
/// always current with the modelled surface.
///
/// The codec side is a SOURCE SCAN of the codec files. Attribution is keyed on
/// DART PROPERTY NAMES, not the JSON keys (which diverge — e.g. `fontWeight` is
/// persisted as `'fontWeightIndex'` — but agree between the two codec sides).
///   * ENCODE side — a value flows OUT of the config object, so it appears as a
///     member read `x.<prop>` (or an object-pattern binding `:final <prop>`).
///     encoded[C] is the generous union of those names over the encode method(s)
///     attributed to C, filtered to C's modelled props.
///   * DECODE side — a value flows INTO the config constructor, so it appears as
///     a top-level NAMED ARGUMENT `<prop>:` of a `C(...)` construction (or a
///     `.copyWith(...)` override). decoded[C] is the union of those argument
///     names over every construction site of C, filtered to C's modelled props.
///
/// Like the emitter gate, the extraction is GENEROUS on purpose: the question is
/// "does the codec name this word for this class". A brand-new property with a
/// brand-new name — the common drift — is caught on both sides; a new property
/// that reuses an existing name on the same class is the documented blind spot.
/// The precise side is DECODE (per-construction named args), which is where the
/// dangerous data-loss drops hide.
///
/// ## This gate is grown in tiers
///
/// Tier-1 (this file's first landing) gates the LEAF classes served by a
/// dedicated both-sided method pair — `_encodeX(X x)` ⇄ a `X(...)` construction
/// — which is the bulk of the surface. The polymorphic dispatch (series /
/// annotations / points), the inline value classes, and the class-level
/// scope pins arrive in the Tier-2 / Tier-3 steps; classes not yet reachable
/// are named in [_deferredToLaterTiers] with a reason, so nothing is silently
/// skipped.

// ===========================================================================
// Codec source files under audit (the artifact-codec mirror).
// The extractor/hydrator layer is DELIBERATELY excluded — it is a different
// mirror (a separate future slice).
// ===========================================================================
const List<String> _codecFiles = <String>[
  'chart_style_document_codec.dart',
  'chart_axis_document_codec.dart',
  'chart_configuration_document_codec.dart',
  'chart_interaction_document_codec.dart',
  'chart_series_document_codec.dart',
  'chart_theme_document_codec.dart',
  'chart_annotation_document_codec.dart',
  'donut_center_content_document_codec.dart',
];

String _artifactPath(String file) =>
    '${Directory.current.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}src${Platform.pathSeparator}artifacts'
    '${Platform.pathSeparator}$file';

// ===========================================================================
// ALLOWLISTS (reviewed, one reason each).
// ===========================================================================

/// Individual `Class.property` pairs the codec deliberately does not round-trip,
/// one reviewed reason each. Removing the gap (adding the encode/decode line)
/// means deleting its entry here.
const Map<String, String> _codecPropertyGaps = <String, String>{
  'ChartTheme.cartesianValueSummaryTheme':
      'The cartesian value-summary theme component: the theme codec does not '
          'persist it, so ChartTheme neither encodes nor decodes this field.',
  'BarLabelStyle.formatter':
      'Runtime `Function` label formatter — unserializable; it fails closed '
          'through a runtime binding descriptor rather than being persisted.',
};

/// Classes that DO round-trip but through a mechanism no tier here attributes.
/// Each is picked up by a later tier or pinned; naming it keeps the gate honest
/// instead of silently green. (Emptied once Tier-2 lands the polymorphic /
/// inline / delegation attribution; retained as the seam for future deferrals.)
const Map<String, String> _deferredToLaterTiers = <String, String>{};

// ===========================================================================
// TIER-2: curated ENCODE sources for classes whose encode is NOT a dedicated
// `_encodeC(C c)` method (so the Tier-1 first-param attributor cannot see it):
// classes serialized INLINE inside a parent encoder, the pie/donut style
// delegation, and the polymorphic series / annotation / point dispatch.
//
// Each entry maps a class to the [file, method] encode bodies that name its
// fields. The generous member-read + object-pattern scan runs over those bodies
// and is filtered to the class's own modelled props — so a helper that happens
// to name a sibling's field does not credit it. A method named here that no
// longer exists makes the gate fail loudly (the "methods exist" test), never
// silently vacuous.
// ===========================================================================
const String _seriesFile = 'chart_series_document_codec.dart';
const String _axisFile = 'chart_axis_document_codec.dart';
const String _configFile = 'chart_configuration_document_codec.dart';
const String _interactionFile = 'chart_interaction_document_codec.dart';
const String _annotationFile = 'chart_annotation_document_codec.dart';

const Map<String, List<List<String>>> _inlineEncodeSources =
    <String, List<List<String>>>{
  // Inline value classes serialized inside a parent encoder.
  'SegmentStyle': [
    [_seriesFile, '_encodePoint'],
  ],
  'PointStyle': [
    [_seriesFile, '_encodePoint'],
  ],
  'CategoryAxisConfig': [
    [_axisFile, 'encodeXAxis'],
  ],
  'BarPatternStyle': [
    [_seriesFile, '_encodeBarStyle'],
  ],
  'BarMotionStyle': [
    [_seriesFile, '_encodeBarStyle'],
  ],
  'BarGradient': [
    [_seriesFile, '_encodeBarStyle'],
  ],
  'BarLabelCalloutStyle': [
    [_seriesFile, '_encodeBarLabels'],
  ],
  'BarBulletRange': [
    [_seriesFile, '_encodeBarBullet'],
  ],
  'BarWaterfallConnectorStyle': [
    [_seriesFile, '_encodeBarWaterfallStyle'],
  ],
  'SeriesLabelBackground': [
    [_seriesFile, '_encodeInlineLabel'],
  ],
  'PolarThreshold': [
    [_configFile, 'encodePolarChart'],
  ],
  'PolarPaneConfig': [
    [_configFile, 'encodePolarChart'],
  ],
  'PolarCategoryAxisConfig': [
    [_configFile, 'encodePolarChart'],
  ],
  'PolarNumericAxisConfig': [
    [_configFile, 'encodePolarChart'],
  ],
  'PolarColumnCompositionConfig': [
    [_configFile, 'encodePolarChart'],
  ],
  'CartesianValueSummaryOverlay': [
    [_interactionFile, '_encodeValueSummaryPresentation'],
  ],
  'CartesianValueSummaryAnnotation': [
    [_interactionFile, '_encodeValueSummaryPresentation'],
  ],
  'CartesianValueSummaryAutomaticContent': [
    [_interactionFile, '_encodeValueSummaryContent'],
  ],
  // Pie/Donut radial-style delegation: the pie encoder takes the RadialChartStyle
  // base (not a manifest type), and the donut encoder spreads it.
  'PieChartStyle': [
    [_seriesFile, '_encodePieStyle'],
  ],
  'DonutChartStyle': [
    [_seriesFile, '_encodeDonutStyle'],
    [_seriesFile, '_encodePieStyle'],
  ],
};

/// Polymorphic dispatch groups: series, annotations, and data points have no
/// per-class encode method — they are encoded through a shared method with a
/// `switch`/`is` dispatch. Each subclass's encoded set is the generous scan of
/// these shared bodies, filtered to that subclass's own modelled props. (The
/// DECODE side stays precise per subclass: each is constructed in its own switch
/// arm / decode method, so the construction-site scan attributes it exactly —
/// this is what catches a per-subclass drop like the categoryValue seam.)
const List<List<String>> _seriesEncodeSources = <List<String>>[
  [_seriesFile, 'encodeWithContext'],
  [_seriesFile, '_encodeSeriesStyle'],
];
const List<String> _seriesClasses = <String>[
  'LineChartSeries',
  'AreaChartSeries',
  'RangeAreaChartSeries',
  'ScatterChartSeries',
  'BarChartSeries',
  'CandlestickChartSeries',
  'PieChartSeries',
  'DonutChartSeries',
  'PolarColumnChartSeries',
];

const List<List<String>> _annotationEncodeSources = <List<String>>[
  [_annotationFile, 'encodeWithContext'],
  [_annotationFile, '_encodePayload'],
];
const List<String> _annotationClasses = <String>[
  'PointAnnotation',
  'RangeAnnotation',
  'TextAnnotation',
  'ThresholdAnnotation',
  'PinAnnotation',
  'TrendAnnotation',
  'ErrorBarAnnotation',
  'ChordAnnotation',
  'LegendAnnotation',
];

const List<List<String>> _pointEncodeSources = <List<String>>[
  [_seriesFile, '_encodePoint'],
];
const List<String> _pointClasses = <String>[
  'ChartDataPoint',
  'CandlestickDataPoint',
  'RangeAreaDataPoint',
];

/// DECODE delegation: a class whose decoded set includes another's because its
/// decoder threads the delegate's construction. `_decodeDonutStyle` builds a
/// `DonutChartStyle.fromRadialStyle(_decodePieStyle(value), …)`, so the shared
/// pie fields are decoded through the pie decoder.
const Map<String, List<String>> _decodeDelegates = <String, List<String>>{
  'DonutChartStyle': ['PieChartStyle'],
};

// ===========================================================================
// Source extraction primitives.
// ===========================================================================

/// Blanks string literals (including raw + triple-quoted) and comments so that
/// path/error-message text (e.g. `r'$.style.barStyle.cornerRadiusPolicy'`)
/// cannot pollute the member-read scan and so paren/brace matching is not
/// derailed by braces inside strings. Newlines are preserved.
String _strip(String source) {
  final s = source;
  final out = StringBuffer();
  var i = 0;
  final n = s.length;
  while (i < n) {
    final c = s[i];
    if (c == '/' && i + 1 < n && s[i + 1] == '/') {
      while (i < n && s[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < n && s[i + 1] == '*') {
      i += 2;
      while (i < n && !(s[i] == '*' && i + 1 < n && s[i + 1] == '/')) {
        if (s[i] == '\n') out.write('\n');
        i++;
      }
      i += 2;
      continue;
    }
    if (c == 'r' && i + 1 < n && (s[i + 1] == '\'' || s[i + 1] == '"')) {
      final q = s[i + 1];
      i += 2;
      final triple = i + 1 < n && s[i] == q && s[i + 1] == q;
      if (triple) i += 2;
      i = _skipStringBody(s, i, q, triple, raw: true, out: out);
      continue;
    }
    if (c == '\'' || c == '"') {
      final q = c;
      i += 1;
      final triple = i + 1 < n && s[i] == q && s[i + 1] == q;
      if (triple) i += 2;
      i = _skipStringBody(s, i, q, triple, raw: false, out: out);
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Advances past a string body (interior blanked), returning the index after
/// the closing quote(s). Interpolations `${…}` are blanked wholesale; the
/// codebase uses only simple interpolations without nested quotes.
int _skipStringBody(
  String s,
  int start,
  String q,
  bool triple, {
  required bool raw,
  required StringBuffer out,
}) {
  var i = start;
  final n = s.length;
  while (i < n) {
    final c = s[i];
    if (!raw && c == r'\') {
      if (i + 1 < n && s[i + 1] == '\n') out.write('\n');
      i += 2;
      continue;
    }
    if (!raw && c == r'$' && i + 1 < n && s[i + 1] == '{') {
      var depth = 0;
      i += 1;
      while (i < n) {
        if (s[i] == '{') depth++;
        if (s[i] == '}') {
          depth--;
          if (depth == 0) {
            i++;
            break;
          }
        }
        if (s[i] == '\n') out.write('\n');
        i++;
      }
      continue;
    }
    if (c == q) {
      if (!triple) return i + 1;
      if (i + 2 < n && s[i + 1] == q && s[i + 2] == q) return i + 3;
    }
    if (c == '\n') out.write('\n');
    i++;
  }
  return i;
}

const String _identifier = r'[A-Za-z_][A-Za-z0-9_]*';

/// Finds the declaration of [method] and returns the source span from its
/// signature's opening paren through the end of its body (block `{…}` or arrow
/// `=> …;`). Returns '' if not found. Body boundaries are computed by
/// paren/brace matching on the (string-stripped) source, so a nested `_decodeX(`
/// CALL inside an arrow body is never mistaken for a new method start — the
/// method-splitter caveat.
String _methodBody(String stripped, String method) {
  final declRe = RegExp(
    r'(?:^|\n)[ ]{0,2}(?:static +)?[A-Za-z_][\w<>,?. ]*?\s' +
        RegExp.escape(method) +
        r'\s*\(',
  );
  final m = declRe.firstMatch(stripped);
  if (m == null) return '';
  final open = stripped.indexOf('(', m.start);
  return _spanFrom(stripped, open);
}

/// Given the index of a signature's opening `(`, returns the method text from
/// there to the end of its body.
String _spanFrom(String stripped, int open) {
  final n = stripped.length;
  var i = open;
  var depth = 0;
  for (; i < n; i++) {
    final c = stripped[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) {
        i++;
        break;
      }
    }
  }
  while (i < n && _isWs(stripped[i])) {
    i++;
  }
  if (i >= n) return stripped.substring(open);
  if (stripped[i] == '{') {
    var brace = 0;
    for (var j = i; j < n; j++) {
      final c = stripped[j];
      if (c == '{') {
        brace++;
      } else if (c == '}') {
        brace--;
        if (brace == 0) return stripped.substring(open, j + 1);
      }
    }
    return stripped.substring(open);
  }
  var d = 0;
  for (var j = i; j < n; j++) {
    final c = stripped[j];
    if (c == '(' || c == '[' || c == '{') {
      d++;
    } else if (c == ')' || c == ']' || c == '}') {
      d--;
    } else if (c == ';' && d == 0) {
      return stripped.substring(open, j + 1);
    }
  }
  return stripped.substring(open);
}

bool _isWs(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';

/// The generous set of DART property names a codec body NAMES on the encode
/// side: member reads `.<prop>` (through `.`, `?.` or `!.`) and object-pattern
/// bindings `:final <prop>`.
Set<String> _encodeNames(String body) => <String>{
      for (final m in RegExp(r'\.(' + _identifier + r')').allMatches(body))
        m.group(1)!,
      for (final m
          in RegExp(r':\s*final\s+(' + _identifier + r')').allMatches(body))
        m.group(1)!,
    };

/// The top-level (depth-1) named-argument labels of every `Class(` /
/// `Class.named(` construction of [className] across [stripped] sources.
Set<String> _decodeNames(List<String> strippedSources, String className) {
  final result = <String>{};
  final ctorRe = RegExp(
    r'\b' + RegExp.escape(className) + r'(?:\.' + _identifier + r')?\s*\(',
  );
  for (final src in strippedSources) {
    for (final m in ctorRe.allMatches(src)) {
      final open = src.indexOf('(', m.start);
      result.addAll(_topLevelNamedArgs(src, open));
    }
  }
  return result;
}

/// Collects the named-argument labels at paren-depth 1 of the call whose opening
/// `(` is at [open]. Nested groups are skipped, so only THIS constructor's own
/// arguments are returned.
Set<String> _topLevelNamedArgs(String stripped, int open) {
  final n = stripped.length;
  final buf = StringBuffer();
  var depth = 0;
  for (var i = open; i < n; i++) {
    final c = stripped[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
      if (depth == 1) continue;
    } else if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) break;
    }
    if (depth == 1) {
      buf.write(c);
    } else if (c == '\n') {
      buf.write('\n');
    }
  }
  final result = <String>{};
  for (final piece in buf.toString().split(',')) {
    final m = RegExp(r'^\s*(' + _identifier + r')\s*:').firstMatch(piece);
    if (m != null) result.add(m.group(1)!);
  }
  return result;
}

/// Unwraps a return-type token to its underlying class name: peels one generic
/// wrapper (`ChartArtifactResult<XAxisConfig>` → `XAxisConfig`), a trailing `?`,
/// and any library prefix.
String _unwrapType(String raw) {
  var t = raw.trim();
  final lt = t.indexOf('<');
  if (lt != -1 && t.endsWith('>')) t = t.substring(lt + 1, t.length - 1).trim();
  if (t.endsWith('?')) t = t.substring(0, t.length - 1);
  final dot = t.lastIndexOf('.');
  if (dot != -1) t = t.substring(dot + 1);
  final lt2 = t.indexOf('<');
  if (lt2 != -1) t = t.substring(0, lt2);
  return t.trim();
}

/// The unwrapped class name of the first positional parameter of a method whose
/// signature opens at [open], or null if the first parameter is named-only
/// (`{…}`) or not a plain type.
String? _firstParamClass(String stripped, int open) {
  final rest = stripped.substring(open + 1);
  final m = RegExp(r'^\s*([A-Za-z_][\w<>,?.]*)\s+' + _identifier).firstMatch(rest);
  if (m == null) return null;
  var type = m.group(1)!;
  final lt = type.indexOf('<');
  if (lt != -1) type = type.substring(0, lt);
  if (type.endsWith('?')) type = type.substring(0, type.length - 1);
  final dot = type.lastIndexOf('.');
  if (dot != -1) type = type.substring(dot + 1);
  return type;
}

/// Every `@chartSurface` class keyed to its modelled property names.
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

// ===========================================================================
// Codec model: encoded[C] and decoded[C] over the whole surface.
// ===========================================================================
class _CodecModel {
  _CodecModel(this.encoded, this.decoded);

  final Map<String, Set<String>> encoded;
  final Map<String, Set<String>> decoded;

  Set<String> encodedFor(String c) => encoded[c] ?? const <String>{};
  Set<String> decodedFor(String c) => decoded[c] ?? const <String>{};
}

Map<String, String> _strippedSources() => <String, String>{
      for (final file in _codecFiles)
        file: _strip(
          File(_artifactPath(file)).readAsStringSync().replaceAll('\r\n', '\n'),
        ),
    };

_CodecModel _buildModel(Set<String> manifestClasses) {
  final stripped = _strippedSources();
  final allStripped = stripped.values.toList(growable: false);

  final encoded = <String, Set<String>>{};
  void addEncoded(String cls, Iterable<String> names) =>
      encoded.putIfAbsent(cls, () => <String>{}).addAll(names);

  // Tier-1 auto: dedicated `_?encode…` methods whose first positional parameter
  // is a manifest class (the leaf both-sided pairs).
  final declRe = RegExp(
    r'(?:^|\n)([ ]{0,2})(?:static +)?[A-Za-z_][\w<>,?. ]*?\s(_?encode'
    r'[A-Za-z0-9_]*)\s*\(',
  );
  for (final src in allStripped) {
    for (final m in declRe.allMatches(src)) {
      final open = src.indexOf('(', m.start);
      final cls = _firstParamClass(src, open);
      if (cls == null || !manifestClasses.contains(cls)) continue;
      addEncoded(cls, _encodeNames(_spanFrom(src, open)));
    }
  }

  // Tier-2 curated inline / delegated encode sources.
  for (final entry in _inlineEncodeSources.entries) {
    for (final where in entry.value) {
      addEncoded(entry.key, _encodeNames(_methodBody(stripped[where[0]]!, where[1])));
    }
  }

  // Tier-2 polymorphic dispatch: series / annotations / points share encode
  // bodies; each subclass is filtered to its own modelled props downstream.
  final seriesBody = <String>[
    for (final where in _seriesEncodeSources)
      _methodBody(stripped[where[0]]!, where[1]),
  ].join('\n');
  for (final cls in _seriesClasses) {
    addEncoded(cls, _encodeNames(seriesBody));
  }
  final annotationBody = <String>[
    for (final where in _annotationEncodeSources)
      _methodBody(stripped[where[0]]!, where[1]),
  ].join('\n');
  for (final cls in _annotationClasses) {
    addEncoded(cls, _encodeNames(annotationBody));
  }
  final pointBody = <String>[
    for (final where in _pointEncodeSources)
      _methodBody(stripped[where[0]]!, where[1]),
  ].join('\n');
  for (final cls in _pointClasses) {
    addEncoded(cls, _encodeNames(pointBody));
  }

  // DECODE: construction-site scan for every manifest class.
  final decoded = <String, Set<String>>{
    for (final cls in manifestClasses)
      if (_decodeNames(allStripped, cls).isNotEmpty)
        cls: _decodeNames(allStripped, cls),
  };
  // Decode via `.copyWith(...)` override (the axis `id` idiom: build with a
  // placeholder id, then `axis.copyWith(id: document.id)`): attribute a decode
  // method's copyWith named args to its return-type class.
  final decodeDeclRe = RegExp(
    r'(?:^|\n)[ ]{0,2}(?:static +)?([A-Za-z_][\w<>,?. ]*?)\s(_?decode'
    r'[A-Za-z0-9_]*)\s*\(',
  );
  for (final src in allStripped) {
    for (final m in decodeDeclRe.allMatches(src)) {
      final ret = _unwrapType(m.group(1)!);
      if (!manifestClasses.contains(ret)) continue;
      final open = src.indexOf('(', m.start);
      final body = _spanFrom(src, open);
      for (final cw in RegExp(r'\.copyWith\s*\(').allMatches(body)) {
        final cwOpen = body.indexOf('(', cw.start);
        decoded
            .putIfAbsent(ret, () => <String>{})
            .addAll(_topLevelNamedArgs(body, cwOpen));
      }
    }
  }

  // Tier-2 decode delegation (donut → pie radial fields).
  for (final entry in _decodeDelegates.entries) {
    final target = decoded.putIfAbsent(entry.key, () => <String>{});
    for (final delegate in entry.value) {
      target.addAll(decoded[delegate] ?? const <String>{});
    }
  }

  return _CodecModel(encoded, decoded);
}

// ===========================================================================
void main() {
  late Map<String, Set<String>> surface;
  late _CodecModel model;
  // Gated scope: every props-bearing class the codec round-trips both-sided (a
  // member-read encode AND a construction-site decode) — Tier-1 leaf pairs plus
  // the Tier-2 polymorphic / inline / delegated classes — minus anything still
  // deferred to a later tier.
  late Set<String> gated;

  setUpAll(() {
    surface = _surfaceProperties();
    model = _buildModel(surface.keys.toSet());
    gated = <String>{
      for (final c in surface.keys)
        if (surface[c]!.isNotEmpty &&
            model.encoded.containsKey(c) &&
            model.decoded.containsKey(c) &&
            !_deferredToLaterTiers.containsKey(c))
          c,
    };
  });

  bool pinnedProp(String c, String p) =>
      _codecPropertyGaps.containsKey('$c.$p');

  test('the extraction produced plausible sets', () {
    expect(surface, hasLength(greaterThan(80)),
        reason: 'the surface manifest resolved almost no classes');
    expect(
      surface.values.fold<int>(0, (sum, props) => sum + props.length),
      greaterThan(700),
      reason: 'the surface manifest resolved almost no properties',
    );
    expect(gated, hasLength(greaterThan(100)),
        reason: 'almost no classes resolved both-sided — the encode/decode scan '
            'was probably broken');
    expect(model.encodedFor('LegendStyle'), contains('markerShape'));
    expect(model.decodedFor('LegendStyle'), contains('markerShape'));
    // Tier-2 spot-checks: the polymorphic + inline + delegated classes resolve.
    expect(model.decodedFor('CandlestickDataPoint'), contains('categoryValue'));
    expect(model.encodedFor('CandlestickDataPoint'), contains('categoryValue'));
    expect(model.decodedFor('DonutChartStyle'), contains('radiusFactor'),
        reason: 'the donut→pie decode delegation did not thread the pie fields');
    for (final c in <String>[
      'LegendStyle',
      'XAxisConfig',
      'YAxisConfig',
      'LineChartSeries',
      'PieChartStyle',
      'DonutChartStyle',
      'PointAnnotation',
      'SegmentStyle',
    ]) {
      expect(gated, contains(c), reason: '$c is not gated both-sided');
    }
  });

  test('every reviewed hole names a real class/property with a real reason', () {
    for (final key in _codecPropertyGaps.keys) {
      final parts = key.split('.');
      expect(surface.containsKey(parts[0]), isTrue,
          reason: '$key pins a property on ${parts[0]}, not a @chartSurface '
              'class.');
      expect(surface[parts[0]]!.contains(parts[1]), isTrue,
          reason: '$key pins property "${parts[1]}", which ${parts[0]} does not '
              'model — delete it.');
    }
    for (final className in _deferredToLaterTiers.keys) {
      expect(surface.containsKey(className), isTrue,
          reason: '$className is deferred but is not a @chartSurface class.');
    }
    for (final reason in <String>[
      ..._codecPropertyGaps.values,
      ..._deferredToLaterTiers.values,
    ]) {
      expect(reason.length, greaterThanOrEqualTo(20),
          reason: 'a pinned hole has a placeholder reason');
    }
  });

  test('every gated modelled property is ENCODED (or pinned)', () {
    final gaps = <String>[];
    for (final className in gated) {
      final encoded = model.encodedFor(className);
      for (final property in surface[className]!) {
        if (encoded.contains(property)) continue;
        if (pinnedProp(className, property)) continue;
        gaps.add('$className.$property');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason: 'NEW codec ENCODE drift: these modelled properties are not named '
          'on the encode side, so their value is never persisted. Add the encode '
          'line, or pin the property in _codecPropertyGaps:\n${gaps.join('\n')}',
    );
  });

  test('every gated modelled property is DECODED (or pinned)', () {
    final gaps = <String>[];
    for (final className in gated) {
      final decoded = model.decodedFor(className);
      for (final property in surface[className]!) {
        if (decoded.contains(property)) continue;
        if (pinnedProp(className, property)) continue;
        gaps.add('$className.$property');
      }
    }
    gaps.sort();
    expect(
      gaps,
      isEmpty,
      reason: 'NEW codec DECODE drift: these modelled properties are not a named '
          'constructor argument of their class, so their value is LOST on '
          'restore. Add the decode argument, or pin it in _codecPropertyGaps:\n'
          '${gaps.join('\n')}',
    );
  });

  test('no encode/decode ASYMMETRY across gated classes '
      '(the categoryValue-class bug)', () {
    final encodedNotDecoded = <String>[];
    final decodedNotEncoded = <String>[];
    for (final className in gated) {
      final encoded = model.encodedFor(className);
      final decoded = model.decodedFor(className);
      for (final property in surface[className]!) {
        if (pinnedProp(className, property)) continue;
        final e = encoded.contains(property);
        final d = decoded.contains(property);
        if (e && !d) encodedNotDecoded.add('$className.$property');
        if (d && !e) decodedNotEncoded.add('$className.$property');
      }
    }
    encodedNotDecoded.sort();
    decodedNotEncoded.sort();
    expect(
      encodedNotDecoded,
      isEmpty,
      reason: 'ENCODE/DECODE ASYMMETRY — these properties are ENCODED but not '
          'DECODED: written to the artifact then silently dropped on restore (a '
          'persisted data-loss bug). Fix the decoder:\n'
          '${encodedNotDecoded.join('\n')}',
    );
    expect(
      decodedNotEncoded,
      isEmpty,
      reason: 'ENCODE/DECODE ASYMMETRY — these properties are DECODED but not '
          'ENCODED: the decoder reads a value the encoder never writes. Fix the '
          'encoder or pin it:\n${decodedNotEncoded.join('\n')}',
    );
  });

  test('the pinned property gaps are all still real', () {
    final stale = <String>[];
    for (final key in _codecPropertyGaps.keys) {
      final parts = key.split('.');
      final encoded = model.encodedFor(parts[0]).contains(parts[1]);
      final decoded = model.decodedFor(parts[0]).contains(parts[1]);
      if (encoded && decoded) stale.add(key);
    }
    stale.sort();
    expect(
      stale,
      isEmpty,
      reason: 'these property gaps are now both encoded AND decoded but still '
          'pinned. Delete them from _codecPropertyGaps:\n${stale.join('\n')}',
    );
  });

  test('the curated Tier-2 encode sources all name real methods', () {
    final stripped = _strippedSources();
    final missing = <String>[];
    void check(String file, String method) {
      if (_methodBody(stripped[file]!, method).isEmpty) {
        missing.add('$file:$method');
      }
    }

    for (final sources in _inlineEncodeSources.values) {
      for (final where in sources) {
        check(where[0], where[1]);
      }
    }
    for (final where in <List<String>>[
      ..._seriesEncodeSources,
      ..._annotationEncodeSources,
      ..._pointEncodeSources,
    ]) {
      check(where[0], where[1]);
    }
    expect(
      (missing.toSet().toList()..sort()),
      isEmpty,
      reason: 'these curated encode-source methods no longer exist (renamed?) — '
          'the gate would be silently vacuous for the classes they feed. Update '
          'the Tier-2 source maps:\n${missing.join('\n')}',
    );
  });

  test('every polymorphic subclass is wired into a Tier-2 group', () {
    // A new series/annotation subclass must be added to its group or it escapes
    // the per-subclass gate (the emitter gate's maintenance guard, mirrored).
    final manifestSeries =
        surface.keys.where((c) => c.endsWith('ChartSeries')).toSet();
    expect(manifestSeries.difference(_seriesClasses.toSet()), isEmpty,
        reason: 'unmapped manifest series — add to _seriesClasses');
    expect(_seriesClasses.toSet().difference(manifestSeries), isEmpty,
        reason: 'stale _seriesClasses entry — not a manifest series');
    final manifestAnnotations =
        surface.keys.where((c) => c.endsWith('Annotation')).toSet()
          ..removeWhere((c) => c.startsWith('CartesianValueSummary'));
    expect(manifestAnnotations.difference(_annotationClasses.toSet()), isEmpty,
        reason: 'unmapped manifest annotation — add to _annotationClasses');
  });

  test('the gate is NON-VACUOUS: a synthetic decode drop is detected', () {
    // Prove the construction-site decode scan actually names each argument and
    // would flag a missing one — the same mechanism the live gate relies on, in
    // miniature, so a future refactor that silently emptied it fails here.
    const present = 'CandlestickDataPoint(x: base.x, categoryValue: '
        'base.categoryValue, close: close)';
    const dropped = 'CandlestickDataPoint(x: base.x, close: close)';
    expect(_decodeNames([_strip(present)], 'CandlestickDataPoint'),
        contains('categoryValue'));
    expect(_decodeNames([_strip(dropped)], 'CandlestickDataPoint'),
        isNot(contains('categoryValue')),
        reason: 'the decode scan failed to notice a dropped ctor arg — the gate '
            'would be vacuous for exactly the categoryValue-class bug');
  });

  test('COVERAGE REPORT (not a gate): artifact-codec round-trip coverage', () {
    var modelled = 0;
    var encoded = 0;
    var decoded = 0;
    for (final className in gated) {
      for (final property in surface[className]!) {
        modelled++;
        if (model.encodedFor(className).contains(property)) encoded++;
        if (model.decodedFor(className).contains(property)) decoded++;
      }
    }
    // ignore: avoid_print
    print(
      '\n[artifact codec drift — gated (Tier-1 + Tier-2)]\n'
      '  @chartSurface classes:      ${surface.length}\n'
      '  gated classes:              ${gated.length}\n'
      '  deferred to later tiers:    ${_deferredToLaterTiers.length}\n'
      '  gated modelled properties:  $modelled\n'
      '  property gaps pinned:       ${_codecPropertyGaps.length}\n'
      '  properties ENCODED:         $encoded of $modelled\n'
      '  properties DECODED:         $decoded of $modelled',
    );
    expect(encoded, greaterThan(0));
    expect(decoded, greaterThan(0));
  });
}
