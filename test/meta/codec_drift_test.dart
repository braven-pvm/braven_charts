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

/// Classes that DO round-trip but through a mechanism this Tier-1 landing does
/// not yet attribute (polymorphic dispatch, inline construction, or the radial
/// decode delegation). Each is picked up by a later tier; naming it here keeps
/// the Tier-1 scope honest instead of silently green.
const Map<String, String> _deferredToLaterTiers = <String, String>{
  'DonutChartStyle':
      'Its decoder delegates the 19 shared radial fields to _decodePieStyle via '
          'DonutChartStyle.fromRadialStyle — modelled by the Tier-2 decode '
          'delegation, not the leaf construction scan.',
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

  // Auto: dedicated `_?encode…` methods whose first positional parameter is a
  // manifest class (the leaf both-sided pairs).
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

  return _CodecModel(encoded, decoded);
}

// ===========================================================================
void main() {
  late Map<String, Set<String>> surface;
  late _CodecModel model;
  // Tier-1 scope: classes served by a dedicated both-sided pair (a member-read
  // encode AND a construction-site decode), minus the classes deferred to a
  // later tier.
  late Set<String> tier1;

  setUpAll(() {
    surface = _surfaceProperties();
    model = _buildModel(surface.keys.toSet());
    tier1 = <String>{
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
    expect(tier1, hasLength(greaterThan(50)),
        reason: 'almost no leaf pairs resolved — the encode/decode scan was '
            'probably broken');
    expect(model.encodedFor('LegendStyle'), contains('markerShape'));
    expect(model.decodedFor('LegendStyle'), contains('markerShape'));
    expect(tier1, contains('LegendStyle'));
    expect(tier1, contains('XAxisConfig'));
    expect(tier1, contains('YAxisConfig'));
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

  test('every Tier-1 modelled property is ENCODED (or pinned)', () {
    final gaps = <String>[];
    for (final className in tier1) {
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

  test('every Tier-1 modelled property is DECODED (or pinned)', () {
    final gaps = <String>[];
    for (final className in tier1) {
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

  test('no encode/decode ASYMMETRY across Tier-1 (the categoryValue-class bug)',
      () {
    final encodedNotDecoded = <String>[];
    final decodedNotEncoded = <String>[];
    for (final className in tier1) {
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

  test('COVERAGE REPORT (not a gate): Tier-1 leaf-pair coverage', () {
    var modelled = 0;
    var encoded = 0;
    var decoded = 0;
    for (final className in tier1) {
      for (final property in surface[className]!) {
        modelled++;
        if (model.encodedFor(className).contains(property)) encoded++;
        if (model.decodedFor(className).contains(property)) decoded++;
      }
    }
    // ignore: avoid_print
    print(
      '\n[artifact codec drift — Tier-1 leaf pairs]\n'
      '  @chartSurface classes:      ${surface.length}\n'
      '  Tier-1 gated classes:       ${tier1.length}\n'
      '  deferred to later tiers:    ${_deferredToLaterTiers.length}\n'
      '  Tier-1 modelled properties: $modelled\n'
      '  property gaps pinned:       ${_codecPropertyGaps.length}\n'
      '  properties ENCODED:         $encoded of $modelled\n'
      '  properties DECODED:         $decoded of $modelled',
    );
    expect(encoded, greaterThan(0));
    expect(decoded, greaterThan(0));
  });
}
