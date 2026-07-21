@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surface_gen/src/enforcement.dart';

/// Task 8 hard gate (a): every `@chartSurface` class is present in
/// [ChartToolSchema.surfaceDefinitions], with its non-excluded parameters.
///
/// ## Why this is gateable at all
///
/// The original plan wanted "every surface property is representable in the AI
/// schema" asserted against `chart_tool_schema.dart`. It is not assertable
/// there and never was: that file's properties are a FLAT snake_case
/// vocabulary (`bar_waterfall_connector_color`) keyed for the agent protocol,
/// with no mechanical relationship to any class or Dart parameter name. There
/// is no function from `BarWaterfallStyle.connectorColor` to that key that a
/// test could compute.
///
/// `surfaceDefinitions` is class-keyed and parameter-keyed, so the gate is a
/// real one. It is checked against TWO independent sources, neither of which
/// is the emitter that produced it:
///
/// 1. the ENFORCEMENT scan (`package:analyzer` over `lib/`, the same one
///    `surface_enforcement_test.dart` drives) supplies the class list;
/// 2. the generated FLUENT extensions supply the per-parameter check — a
///    property with no `withX` verb and no `x-mutation` caveat means the two
///    generated surfaces disagree about what the class has.
///
/// A single emitter bug that dropped a class or a parameter would have to be
/// mirrored in the analyzer scan AND in the fluent emitter to pass.
///
/// ## What this file does NOT assert
///
/// It says nothing about `createChartTool` / `modifyChartTool`, which are
/// untouched. The relationship between those literals and the parser that
/// consumes them is the subject of `ai_mirror_drift_test.dart`.

String get _separator => Platform.pathSeparator;

String get _libPath => '${Directory.current.path}${_separator}lib';

/// See `surface_enforcement_test.dart` for why `FLUTTER_ROOT` is the SDK
/// source under `flutter test`.
String get _sdkPath {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final sdk =
        '$flutterRoot${_separator}bin'
        '${_separator}cache'
        '${_separator}dart-sdk';
    if (Directory(sdk).existsSync()) return sdk;
    fail('FLUTTER_ROOT is set to "$flutterRoot" but "$sdk" does not exist.');
  }
  final candidate = File(Platform.resolvedExecutable).parent.parent.path;
  if (File('$candidate${_separator}version').existsSync()) return candidate;
  fail('FLUTTER_ROOT is unset and the host executable does not belong to a '
      'Dart SDK. Run through `flutter test`, or set FLUTTER_ROOT.');
}

/// Every checked-in generated fluent source, concatenated.
String _fluentSources() {
  final directory = Directory(
    '${Directory.current.path}$_separator'
    'lib${_separator}src${_separator}fluent${_separator}generated',
  );
  final buffer = StringBuffer();
  if (!directory.existsSync()) return '';
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      buffer.writeln(entity.readAsStringSync());
    }
  }
  return buffer.toString();
}

String? _fluentExtensionBody(String sources, String className) {
  final header = RegExp(
    'extension ${RegExp.escape(className)}Fluent\\s+'
    'on ${RegExp.escape(className)}\\s*\\{',
  );
  final match = header.firstMatch(sources);
  if (match == null) return null;
  final rest = sources.substring(match.end);
  final next = rest.indexOf('\nextension ');
  return next < 0 ? rest : rest.substring(0, next);
}

/// `fluentVerb`'s name derivation, mirrored: `isXOrdered` -> `XOrdered`.
String _deIs(String name) {
  if (name.length > 2 &&
      name.startsWith('is') &&
      name[2] == name[2].toUpperCase() &&
      name[2] != name[2].toLowerCase()) {
    return name.substring(2);
  }
  return name;
}

String _verbSuffix(String param) {
  final stripped = _deIs(param);
  return stripped.isEmpty
      ? stripped
      : stripped[0].toUpperCase() + stripped.substring(1);
}

Map<String, Object?> _definition(String className) =>
    ChartToolSchema.surfaceDefinitions[className]! as Map<String, Object?>;

Map<String, Object?> _properties(String className) =>
    _definition(className)['properties']! as Map<String, Object?>;

void main() {
  late EnforcementResult enforcement;
  late String fluent;

  setUpAll(() async {
    enforcement = await checkPackageSurface(
      libPath: _libPath,
      sdkPath: _sdkPath,
    );
    fluent = _fluentSources();
  });

  test('the definitions are non-trivial', () {
    expect(
      ChartToolSchema.surfaceDefinitions,
      hasLength(greaterThan(80)),
      reason: 'surfaceDefinitions is implausibly small — the generated file '
          'is probably stale. Run `dart run build_runner build`.',
    );
  });

  test('HARD GATE (a): every @chartSurface class has a definition', () {
    final missing = [
      for (final entry in enforcement.annotated)
        if (!ChartToolSchema.surfaceDefinitions.containsKey(entry.className))
          '${entry.className} (${entry.libraryUri})',
    ]..sort();
    expect(
      missing,
      isEmpty,
      reason: 'these classes carry @chartSurface but have no entry in '
          'ChartToolSchema.surfaceDefinitions. Run '
          '`dart run build_runner build`.\n${missing.join('\n')}',
    );
  });

  test('every definition names a class the enforcement scan knows', () {
    final known = {
      for (final entry in enforcement.annotated) entry.className,
      for (final entry in enforcement.exempt) entry.className,
    };
    final unknown = ChartToolSchema.surfaceDefinitions.keys
        .where((name) => !known.contains(name))
        .toList()
      ..sort();
    expect(
      unknown,
      isEmpty,
      reason: 'surfaceDefinitions describes classes the public surface scan '
          'does not see: ${unknown.join(', ')}',
    );
  });

  test('every definition is a closed object with properties and a library', () {
    ChartToolSchema.surfaceDefinitions.forEach((name, value) {
      final definition = value! as Map<String, Object?>;
      expect(definition['type'], 'object', reason: name);
      expect(definition['title'], name, reason: name);
      expect(definition['additionalProperties'], isFalse, reason: name);
      expect(definition['properties'], isA<Map<String, Object?>>(),
          reason: name);
      expect(definition['x-dartLibrary'],
          startsWith('package:braven_charts/src/'),
          reason: name);
    });
  });

  test('every \$ref resolves inside the definitions', () {
    final dangling = <String>[];
    void walk(String owner, Object? node) {
      if (node is Map) {
        for (final entry in node.entries) {
          if (entry.key == r'$ref' && entry.value is String) {
            final target =
                (entry.value! as String).replaceFirst(r'#/$defs/', '');
            if (!ChartToolSchema.surfaceDefinitions.containsKey(target)) {
              dangling.add('$owner -> ${entry.value}');
            }
          }
          walk(owner, entry.value);
        }
      } else if (node is List) {
        for (final item in node) {
          walk(owner, item);
        }
      }
    }

    ChartToolSchema.surfaceDefinitions.forEach(walk);
    expect(dangling, isEmpty,
        reason: 'a \$ref points outside the \$defs block:\n'
            '${dangling.join('\n')}');
  });

  test('HARD GATE (a): every property is either settable through the '
      'generated fluent verb or marked construction-only', () {
    final gaps = <String>[];
    for (final entry in ChartToolSchema.surfaceDefinitions.entries) {
      final body = _fluentExtensionBody(fluent, entry.key);
      // Sealed bases and classes without a `copyWith` yield no extension;
      // they still belong in a STRUCTURAL schema.
      if (body == null) continue;
      for (final property in _properties(entry.key).entries) {
        final schema = property.value! as Map<String, Object?>;
        // Present for construction, deliberately unsettable.
        if (schema.containsKey('x-mutation')) continue;
        // A combined setter replaces its members' individual verbs.
        if (schema['x-combinedSetter'] case final String setter) {
          if (body.contains('$setter(')) continue;
          gaps.add('${entry.key}.${property.key} (claims $setter, which the '
              'fluent extension does not declare)');
          continue;
        }
        if (body.contains('with${_verbSuffix(property.key)}(')) continue;
        gaps.add('${entry.key}.${property.key}');
      }
    }
    expect(
      gaps,
      isEmpty,
      reason: 'these properties exist in surfaceDefinitions but have no '
          'generated fluent verb and no x-mutation caveat — the two generated '
          'surfaces disagree about the class:\n${gaps.join('\n')}',
    );
  });

  test('the tri-state fields of CartesianValueSummaryStyle are '
      '{value | none | inherit} unions', () {
    final properties = _properties('CartesianValueSummaryStyle');
    expect(properties, hasLength(14));
    for (final entry in properties.entries) {
      final schema = entry.value! as Map<String, Object?>;
      final union = schema['oneOf']! as List;
      expect(union, hasLength(3), reason: entry.key);
      expect((union[0]! as Map)['title'], 'value', reason: entry.key);
      expect((union[1]! as Map)['const'], 'none', reason: entry.key);
      expect((union[2]! as Map)['const'], 'inherit', reason: entry.key);
      expect(schema['default'], 'inherit', reason: entry.key);
    }
  });

  test('CandlestickDataPoint keeps its OHLC group whole in `required`', () {
    final definition = _definition('CandlestickDataPoint');
    expect(definition['required'], ['close', 'high', 'low', 'open', 'x']);
    expect(definition['description'],
        contains('validated together and are all required as a unit'));
  });

  test('BarChartSeries states its OR-shaped width alternative as anyOf', () {
    final definition = _definition('BarChartSeries');
    expect(definition['anyOf'], [
      {
        'required': ['barWidthPercent'],
      },
      {
        'required': ['barWidthPixels'],
      },
    ]);
    // Force-excluded from the MUTATION surface, present in the STRUCTURAL one.
    expect(_properties('BarChartSeries'), contains('barWidthPercent'));
    expect(
      (_properties('BarChartSeries')['id']! as Map)['x-mutation'],
      contains('construction-only'),
    );
  });

  test('an assert whose shape the reader cannot prove states its message '
      'instead of inventing a constraint', () {
    final range = _definition('RangeAnnotation');
    expect(range['description'],
        contains('"startX must be less than endX"'));
    final legend = _definition('LegendAnnotation');
    expect(legend.containsKey('anyOf'), isFalse);
    expect(legend['description'],
        contains('Legend scales use separate LegendAnnotation instances.'));
  });

  test('callbacks are omitted and the omission is recorded on the class', () {
    final legend = _definition('LegendAnnotation');
    expect(_properties('LegendAnnotation'), isNot(contains('onSeriesToggle')));
    expect(legend['description'], contains('onSeriesToggle (callback'));
  });
}
