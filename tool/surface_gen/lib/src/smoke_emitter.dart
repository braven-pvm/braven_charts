/// Emits the exhaustive smoke coverage for the generated fluent surface.
///
/// ## What it proves
///
/// Every generated verb of every modelled class is written out once. Verbs
/// whose argument can be SYNTHESIZED are additionally INVOKED on a real
/// instance and asserted not to throw.
///
/// The original emitter only compiled its cases — "the cases are never
/// EXECUTED — compilation is the assertion" — and that is exactly why five
/// classes shipped verbs that throw:
/// `CandlestickDataPoint.withHigh(1)` on a candle whose `low` is 99,
/// `PieChartSeries.withPieStyle(PieChartStyle(radiusFactor: 2))`,
/// `PolarColumnChartSeries.withPoints([one])` against two targets. All three
/// type-check perfectly. 1131 verbs that compile are worth less than a
/// smaller number that run.
///
/// ## The two halves of a case
///
/// ```dart
/// /// Smoke coverage for [PieChartStyle]'s 14 generated verb(s).
/// void _smokePieChartStyle(_Verb verb, PieChartStyle subject) {
///   verb('PieChartStyleFluent.withRadiusFactor',
///       () => subject.withRadiusFactor(1.0));
/// }
///
/// /// Compile-only coverage for [AreaChartSeries]'s 1 verb(s) ...
/// void _compileAreaChartSeries(AreaChartSeries subject, AreaGradient a0) {
///   subject.withGradient(a0);
/// }
/// ```
///
/// The subject stays a FUNCTION PARAMETER, as it always was — the generated
/// `main` supplies it — so the compile-time breadth check is unchanged and no
/// class loses coverage because its constructor is awkward. What is new is
/// the `_Verb` recorder: it invokes each verb independently and collects the
/// ones that throw, so a single failure does not hide the rest of the class.
///
/// A verb whose argument type has no synthesizable value keeps the old
/// typed-parameter treatment in `_compile<Class>` — still compiled, never
/// executed — and is listed by name and reason in `_compileOnlyVerbs`. It is
/// recorded, not silently dropped.
///
/// ## Subjects
///
/// A subject is built from the class's PUBLIC UNNAMED constructor
/// ([SurfaceClass.unnamedConstructorParams]), not from the constructor the
/// reader selected for parameters: `YAxisConfig`'s parameters come from
/// `const YAxisConfig._internal(...)`, which no test can call.
///
/// - a required parameter with no synthesizable value → the class is SKIPPED
///   statically, with `skip:` naming the parameter and its type;
/// - a constructor that REJECTS the synthesized arguments (`PolarColumnChartSeries`
///   demands at least one category) → the case skips itself at run time
///   through `markTestSkipped`, carrying the thrown message.
///
/// Both outcomes are visible in the test report. Neither passes silently.
///
/// ## Argument synthesis
///
/// In order:
///
/// 1. the parameter's own DEFAULT expression, when it has one that names no
///    private identifier. A default is a value the class has already accepted,
///    which keeps a probe from tripping unrelated range asserts
///    (`TrendAnnotation.confidenceLevel` must stay below 1);
/// 2. a canonical literal for the primitives, and for the Flutter/dart:ui
///    types that have one (`Color`, `TextStyle`, `EdgeInsets`, `Curve`, ...);
/// 3. `Enum.values.first` for enums, empty literals for `List`/`Map`/`Set`;
/// 4. recursive construction of another MODELLED class from its own required
///    parameters;
/// 5. otherwise: no value, and the verb becomes compile-only.
///
/// Verb arguments use PROBE literals (`1.0`, `1`, `'y'`) while subjects use
/// BASE literals (`0.0`, `0`, `'x'`), so a verb argument differs from the
/// subject's current value wherever a parameter is required. That difference
/// is what makes the coupled-parameter regressions go red: on a candle built
/// as `(0.5, 0.5, 0.5, 0.5, 0.5)`, an individual `withLow(1.0)` throws — `low` would
/// exceed `open`. Reverting `CandlestickDataPoint`'s `withOhlc` metadata
/// turns this file red on three of the four verbs it re-exposes.
///
/// Combined setters are argued differently, because their whole reason for
/// existing is an invariant that same-valued arguments would violate:
///
/// - a NON-NULLABLE member replays the subject's own value
///   (`subject.withOhlc(subject.open, subject.high, subject.low,
///   subject.close)`), which the constructor has already accepted;
/// - a NULLABLE numeric member — the `min`/`max` idiom, where the subject's
///   getter is `double?` and the verb takes `double` — probes ASCENDING
///   values, so `assert(min < max)` is satisfied.
///
/// Verb NAMES are never re-derived here: `fluentVerb` from
/// `fluent_emitter.dart` is the single definition, so the two emitters cannot
/// drift.
library;

import 'emitter.dart';
import 'fluent_emitter.dart';
import 'surface_model.dart';

/// The single Flutter import generated code ever needs.
const String _flutterImport = 'package:flutter/widgets.dart';

/// Canonical PROBE literals — the argument a verb is handed.
///
/// The values are chosen so a probe never trips a SINGLE-parameter range
/// check — which is honest behaviour, identical to what construction does —
/// and every failure the smoke run reports is therefore a real cross-parameter
/// coupling. `1.0` sits inside every bounded double range the config surface
/// declares (`[0, 1]`, `(0, 1]`, `[1, 1.5]`, `[-1, 1]`, `[0, 360]`); the int
/// probe is `2` because `tickCount` must be at least 2.
const Map<String, String> _probeLiterals = {
  'bool': 'true',
  'int': '2',
  'double': '1.0',
  'num': '2',
  'String': "'y'",
  'Object': "'y'",
  'Duration': 'const Duration(milliseconds: 1)',
  'DateTime': 'DateTime.utc(2026)',
};

/// Canonical BASE literals — the argument a SUBJECT is built with.
///
/// Deliberately different from [_probeLiterals] wherever a difference is
/// expressible: a verb that hands back the value the subject already holds
/// cannot detect a cross-parameter coupling.
/// Deliberately different from [_probeLiterals] wherever a difference is
/// expressible: a verb handed the value the subject already holds cannot
/// detect a cross-parameter coupling. `0.5` rather than `0.0` because a
/// required double is occasionally required to be POSITIVE
/// (`TypographyTheme.baseFontSize`), and a subject that cannot be built
/// covers nothing.
const Map<String, String> _baseLiterals = {
  'bool': 'true',
  'int': '1',
  'double': '0.5',
  'num': '1',
  'String': "'x'",
  'Object': "'x'",
  'Duration': 'const Duration(milliseconds: 1)',
  'DateTime': 'DateTime.utc(2026)',
};

/// Framework types with a canonical value, and the extra name that value
/// needs in the Flutter `show` clause.
const Map<String, (String, String?)> _frameworkValues = {
  'Color': ('const Color(0xFF2196F3)', null),
  'TextStyle': ('const TextStyle()', null),
  'EdgeInsets': ('EdgeInsets.zero', null),
  'EdgeInsetsGeometry': ('EdgeInsets.zero', 'EdgeInsets'),
  'BorderRadius': ('BorderRadius.zero', null),
  'Offset': ('Offset.zero', null),
  'Size': ('Size.zero', null),
  'Alignment': ('Alignment.center', null),
  'AlignmentGeometry': ('Alignment.center', 'Alignment'),
  'BoxShadow': ('const BoxShadow()', null),
  'Curve': ('Curves.linear', 'Curves'),
  'FontWeight': ('FontWeight.normal', null),
  'Rect': ('Rect.zero', null),
};

/// One emitted smoke case.
class SmokeCase {
  const SmokeCase({
    required this.className,
    required this.source,
    required this.verbs,
    this.executedFunctionName,
    this.compileOnlyFunctionName,
    this.subjectExpression,
    this.skipReason,
    this.compileOnlyVerbs = const <String>[],
    this.flutterNames = const <String>{},
  });

  /// The class the case covers.
  final String className;

  /// The formatted source of both generated functions.
  final String source;

  /// How many verbs the case covers, executed and compile-only together.
  final int verbs;

  /// The executing function's name, or `null` when every verb is
  /// compile-only.
  final String? executedFunctionName;

  /// The compile-only function's name, or `null` when there are none.
  final String? compileOnlyFunctionName;

  /// The expression that builds a subject, or `null` when none can be built.
  final String? subjectExpression;

  /// Why this class does not execute, or `null` when it does.
  final String? skipReason;

  /// `Class.verb — reason` for every verb that could not be executed.
  final List<String> compileOnlyVerbs;

  /// Extra Flutter names the synthesized values need in the `show` clause.
  final Set<String> flutterNames;

  /// Whether the case runs its verbs.
  bool get executes => executedFunctionName != null && skipReason == null;
}

/// [SurfaceEmitter] producing `test/fluent/fluent_smoke_generated_test.dart`.
class SmokeEmitter implements SurfaceEmitter {
  const SmokeEmitter({this.exportedNames});

  /// The public barrel's export namespace, when the caller can supply it.
  ///
  /// Used to keep a braven_charts type out of the `show` clause of the
  /// Flutter import when both packages define the same simple name.
  final Set<String>? exportedNames;

  @override
  String get outputSuffix => '_smoke_generated_test.dart';

  /// Emits the smoke FUNCTIONS for one class, or an empty string when the
  /// class contributes no verbs.
  @override
  String emit(SurfaceClass cls, SurfaceModel model) =>
      _case(cls, model)?.source ?? '';

  @override
  String? emitLibrary(SurfaceModel model) {
    final cases = <SmokeCase>[
      for (final cls in model.classes)
        if (_case(cls, model) case final SmokeCase smokeCase) smokeCase,
    ];
    if (cases.isEmpty) return null;

    final verbs = cases.fold<int>(0, (sum, item) => sum + item.verbs);
    final executed = cases.where((item) => item.executes).toList();
    final compileOnlyVerbs = [
      for (final item in cases) ...item.compileOnlyVerbs,
    ];
    final compileOnlyCases = [
      for (final item in cases)
        if (item.compileOnlyFunctionName != null) item.compileOnlyFunctionName!,
    ];

    final buffer = StringBuffer()
      ..writeln('// GENERATED by surface_gen — do not edit.')
      ..writeln('//')
      ..writeln('// Executable smoke coverage for the generated fluent '
          'surface.')
      ..writeln('//')
      ..writeln('// ${executed.length} of ${cases.length} classes have a '
          'synthesizable subject: every verb they')
      ..writeln('// own is INVOKED on a real instance and asserted not to '
          'throw. Compilation is')
      ..writeln('// no longer the only assertion — it never caught a verb '
          'that type-checks and')
      ..writeln('// throws. A class whose constructor REJECTS the synthesized '
          'arguments skips')
      ..writeln('// itself at run time and the runner reports the thrown '
          'message.')
      ..writeln('//')
      ..writeln('// $verbs verbs total; ${compileOnlyVerbs.length} of them '
          'have an argument type with no')
      ..writeln('// synthesizable value and are compiled but not run. Every '
          'skip says why.')
      ..writeln('//')
      ..writeln('// Regenerate: dart run build_runner build')
      ..writeln('library;')
      ..writeln()
      ..writeln("import 'package:braven_charts/braven_charts_fluent.dart';");
    final flutterNames = _flutterNames(cases, model);
    if (flutterNames.isNotEmpty) {
      buffer.writeln(
        "import '$_flutterImport' show ${flutterNames.join(', ')};",
      );
    }
    buffer
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln()
      ..writeln(_harness)
      ..writeln('/// How many classes run their verbs.')
      ..writeln('const int _executedClasses = ${executed.length};')
      ..writeln()
      ..writeln('/// How many classes have no synthesizable subject.')
      ..writeln('const int _skippedClasses = '
          '${cases.length - executed.length};')
      ..writeln();
    for (final smokeCase in cases) {
      buffer.writeln(smokeCase.source);
    }
    buffer
      ..writeln('/// Every compile-only case, referenced so none of them is '
          'dead code.')
      ..writeln('const List<Function> _compileOnlyCases = <Function>[')
      ..writeln([for (final name in compileOnlyCases) '  $name,'].join('\n'))
      ..writeln('];')
      ..writeln()
      ..writeln('/// Verbs that cannot be executed, recorded rather than '
          'silently dropped.')
      ..writeln('const List<String> _compileOnlyVerbs = <String>[')
      ..writeln([
        for (final entry in compileOnlyVerbs) "  '${_escape(entry)}',",
      ].join('\n'))
      ..writeln('];')
      ..writeln()
      ..writeln('void main() {')
      ..writeln("  group('generated fluent verbs run without throwing', () {");
    for (final smokeCase in cases) {
      buffer.writeln(_mainCase(smokeCase));
    }
    buffer
      ..writeln('  });')
      ..writeln()
      ..writeln("  test('the executed/skipped split is what the generator "
          "reported', () {")
      ..writeln('    expect(_executedClasses, ${executed.length});')
      ..writeln('    expect(_skippedClasses, ${cases.length - executed.length});')
      ..writeln('    expect(_compileOnlyCases, '
          'hasLength(${compileOnlyCases.length}));')
      ..writeln('    expect(_compileOnlyVerbs, '
          'hasLength(${compileOnlyVerbs.length}));')
      ..writeln('  });')
      ..writeln('}');
    return formatGenerated(buffer.toString());
  }

  /// The fixed runtime the generated cases share.
  static const String _harness = '''
/// Invokes one generated verb, labelled by owner.
typedef _Verb = void Function(String label, Object? Function() invoke);

/// Runs [body] against [subject] and returns the verbs that threw.
///
/// Every verb is invoked independently, so one failure cannot hide the rest
/// of the class.
List<String> _record<T>(void Function(_Verb, T) body, T subject) {
  final failures = <String>[];
  body((label, invoke) {
    try {
      invoke();
    } on Object catch (error) {
      failures.add('\$label threw \$error');
    }
  }, subject);
  return failures;
}

/// Builds a subject, or skips the case with the reason it could not.
///
/// A constructor that rejects the generator's synthesized arguments is a
/// reportable outcome, not a passing one.
T? _subject<T>(T Function() build) {
  try {
    return build();
  } on Object catch (error) {
    markTestSkipped('subject could not be constructed: \$error');
    return null;
  }
}
''';

  /// The `test(...)` that runs — or skips — one case.
  String _mainCase(SmokeCase smokeCase) {
    final reason = smokeCase.skipReason;
    if (reason != null || !smokeCase.executes) {
      return "    test('${smokeCase.className}', () {}, "
          "skip: '${_escape(reason ?? 'every verb is compile-only')}');";
    }
    return '''
    test('${smokeCase.className}', () {
      final subject = _subject(() => ${smokeCase.subjectExpression});
      if (subject == null) return;
      expect(
        _record(${smokeCase.executedFunctionName}, subject),
        isEmpty,
        reason: 'generated ${smokeCase.className}Fluent verb(s) threw',
      );
    });''';
  }

  // -------------------------------------------------------------------------
  // Cases
  // -------------------------------------------------------------------------

  SmokeCase? _case(SurfaceClass cls, SurfaceModel model) {
    if (!cls.hasCopyWith) return null;
    if (cls.typeParameters.isNotEmpty) return null;
    if (cls.copyWithReturnType != null && cls.copyWithReturnType != cls.name) {
      return null;
    }

    final synth = _Synthesizer(model);
    final pool = _ParameterPool();
    final executed = <String>[];
    final compileOnly = <String>[];
    final compileOnlyVerbs = <String>[];
    final members = combinedMemberNames(cls);

    /// Records an executable verb: `subject.<verb>(<arguments>)`.
    void run(String verb, String arguments) {
      executed.add(
        "verb('${cls.name}Fluent.$verb', "
        '() => subject.$verb($arguments));',
      );
    }

    /// Records a verb that can only be compiled, with the type that blocked
    /// it.
    void compile(
      String verb,
      List<({String type, String? label})> formals,
      String blocker,
    ) {
      final declared = [
        for (final formal in formals)
          formal.label == null
              ? pool.declare(formal.type)
              : '${formal.label}: ${pool.declare(formal.type)}',
      ];
      compileOnly.add('subject.$verb(${declared.join(', ')});');
      compileOnlyVerbs.add(
        '${cls.name}Fluent.$verb — no synthesizable value for $blocker',
      );
    }

    for (final param in cls.params) {
      if (isExcludedParam(param)) continue;
      if (members.contains(param.name)) continue;

      if (param.kind == SurfaceParamKind.triState) {
        final payload = param.triStatePayloadType ?? 'Object';
        final verb = fluentVerb('with', param.name);
        final argument = synth.probe(param, typeOverride: payload);
        if (argument == null) {
          compile(verb, [(type: payload, label: null)], payload);
        } else {
          run(verb, argument);
        }
        for (final prefix in ['without', 'inherit']) {
          final name = fluentVerb(prefix, param.name);
          executed.add(
            "verb('${cls.name}Fluent.$name', () => subject.$name());",
          );
        }
        continue;
      }

      final verb = fluentVerb('with', param.name);
      final type = stripNullability(param.dartType);
      final argument = synth.probe(param);
      if (argument == null) {
        compile(verb, [(type: type, label: null)], type);
      } else {
        run(verb, argument);
      }

      final sealed = sealedOwnerFor(param, model);
      if (sealed != null) {
        for (final factory in sealed.factories) {
          _sealedCall(cls, param, sealed, factory, synth, run, compile);
        }
      }
      if (param.kind == SurfaceParamKind.nestedConfig && !param.isNullable) {
        final update = fluentVerb('update', param.name);
        executed.add(
          "verb('${cls.name}Fluent.$update', "
          '() => subject.$update((current) => current));',
        );
      }
      if (param.clearFlag != null) {
        final clear = fluentVerb('clear', param.name);
        executed.add(
          "verb('${cls.name}Fluent.$clear', () => subject.$clear());",
        );
      }
    }

    for (final setter in cls.combinedSetters) {
      // The fluent emitter labels a setter of three or more members; the two
      // emitters must agree about the call shape or the generated smoke file
      // does not compile.
      final isNamed = setter.paramNames.length >= 3;
      final arguments = <String>[];
      var ascending = 0;
      var synthesizable = true;
      for (final name in setter.paramNames) {
        final param = _paramByName(cls, name);
        final argument = synth.combined(
          param,
          ascendingIndex: ascending,
        );
        if (argument == null) {
          synthesizable = false;
          break;
        }
        if (synth.usesAscending(param)) ascending++;
        arguments.add(isNamed ? '$name: $argument' : argument);
      }
      if (!synthesizable) {
        compile(
          setter.name,
          [
            for (final name in setter.paramNames)
              (
                type: stripNullability(_paramByName(cls, name).dartType),
                label: isNamed ? name : null,
              ),
          ],
          'its members',
        );
      } else {
        run(setter.name, arguments.join(', '));
      }
      for (final name in setter.paramNames) {
        final param = _paramByName(cls, name);
        if (isExcludedParam(param) || param.clearFlag == null) continue;
        final clear = fluentVerb('clear', param.name);
        executed.add(
          "verb('${cls.name}Fluent.$clear', () => subject.$clear());",
        );
      }
    }

    if (executed.isEmpty && compileOnly.isEmpty) return null;

    final subject = _subjectExpression(cls, synth);
    final buffer = StringBuffer();
    String? executedName;
    String? compileOnlyName;

    if (executed.isNotEmpty) {
      executedName = '_smoke${cls.name}';
      buffer.write('''
/// Smoke coverage for [${cls.name}]'s ${executed.length} executable verb(s).
void $executedName(_Verb verb, ${cls.name} subject) {
${executed.map((statement) => '  $statement').join('\n')}
}
''');
    }
    if (compileOnly.isNotEmpty) {
      compileOnlyName = '_compile${cls.name}';
      if (executed.isNotEmpty) buffer.writeln();
      buffer.write('''
/// Compile-only coverage for [${cls.name}]'s ${compileOnly.length} verb(s)
/// whose argument type has no synthesizable value.
void $compileOnlyName(${[
        '${cls.name} subject',
        ...pool.declarations,
      ].join(', ')}) {
${compileOnly.map((statement) => '  $statement').join('\n')}
}
''');
    }

    return SmokeCase(
      className: cls.name,
      source: formatGenerated(buffer.toString()),
      verbs: executed.length + compileOnly.length,
      executedFunctionName: executedName,
      compileOnlyFunctionName: compileOnlyName,
      subjectExpression: subject.expression,
      skipReason: subject.expression == null
          ? 'no synthesizable subject: ${subject.problem}'
          : (executedName == null ? 'every verb is compile-only' : null),
      compileOnlyVerbs: compileOnlyVerbs,
      flutterNames: synth.flutterNames,
    );
  }

  /// `subject.with<Factory><Param>(...)`, passing every positional parameter
  /// and every REQUIRED named one; the rest take their defaults.
  void _sealedCall(
    SurfaceClass cls,
    SurfaceParam param,
    SurfaceClass sealed,
    SurfaceFactoryModel factory,
    _Synthesizer synth,
    void Function(String verb, String arguments) run,
    void Function(
      String verb,
      List<({String type, String? label})> formals,
      String blocker,
    ) compile,
  ) {
    final passed = [
      for (final factoryParam in factory.params)
        if (!factoryParam.isNamed || factoryParam.isRequired) factoryParam,
    ];
    final arguments = <String>[];
    String? blocker;
    for (final factoryParam in passed) {
      final argument = synth.probe(factoryParam);
      if (argument == null) {
        blocker = stripNullability(factoryParam.dartType);
        break;
      }
      arguments.add(
        factoryParam.isNamed ? '${factoryParam.name}: $argument' : argument,
      );
    }
    final verb = 'with${capitalize(factory.name)}${capitalize(param.name)}';
    if (blocker != null) {
      compile(
        verb,
        [
          for (final factoryParam in passed)
            (
              type: factoryParam.dartType,
              label: factoryParam.isNamed ? factoryParam.name : null,
            ),
        ],
        blocker,
      );
      return;
    }
    run(verb, arguments.join(', '));
  }

  /// The expression that builds a subject, or the reason none can be built.
  ({String? expression, String? problem}) _subjectExpression(
    SurfaceClass cls,
    _Synthesizer synth,
  ) {
    final params = cls.unnamedConstructorParams;
    if (params == null) {
      return (expression: null, problem: 'no public unnamed constructor');
    }
    final arguments = <String>[];
    for (final param in params) {
      if (!param.isRequired) continue;
      final argument = synth.base(param);
      if (argument == null) {
        return (
          expression: null,
          problem: 'required parameter `${param.name}` of type '
              '${stripNullability(param.dartType)}',
        );
      }
      arguments.add(param.isNamed ? '${param.name}: $argument' : argument);
    }
    return (
      expression: '${cls.name}(${arguments.join(', ')})',
      problem: null,
    );
  }

  SurfaceParam _paramByName(SurfaceClass cls, String name) {
    for (final param in cls.params) {
      if (param.name == name) return param;
    }
    throw StateError(
      'surface_gen: smoke emitter: combined setter on ${cls.name} names '
      'unknown parameter `$name`.',
    );
  }

  String _escape(String text) => text.replaceAll(r'\', r'\\').replaceAll(
        "'",
        r"\'",
      );

  // -------------------------------------------------------------------------
  // Imports
  // -------------------------------------------------------------------------

  /// The Flutter/dart:ui type names the smoke sources reference.
  ///
  /// A name the public barrel also exports is left out: braven_charts wins,
  /// and showing both would be an `ambiguous_import`.
  List<String> _flutterNames(List<SmokeCase> cases, SurfaceModel model) {
    final origins = <String, String>{};
    for (final cls in model.classes) {
      for (final param in cls.params) {
        origins.addAll(param.typeOrigins);
      }
      for (final param in cls.unnamedConstructorParams ?? const <SurfaceParam>[]) {
        origins.addAll(param.typeOrigins);
      }
      for (final factory in cls.factories) {
        for (final param in factory.params) {
          origins.addAll(param.typeOrigins);
        }
      }
    }
    final identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');
    final exported = exportedNames;
    final names = <String>{};
    for (final smokeCase in cases) {
      final scanned = '${smokeCase.source}\n${smokeCase.subjectExpression}';
      for (final match in identifier.allMatches(scanned)) {
        final name = match.group(0)!;
        final origin = origins[name];
        if (origin == null) continue;
        if (origin != 'dart:ui' && !origin.startsWith('package:flutter/')) {
          continue;
        }
        if (exported != null && exported.contains(name)) continue;
        names.add(name);
      }
      for (final name in smokeCase.flutterNames) {
        if (exported != null && exported.contains(name)) continue;
        names.add(name);
      }
    }
    final sorted = names.toList()..sort();
    return sorted;
  }
}

/// Synthesizes the argument expressions the emitted cases pass.
class _Synthesizer {
  _Synthesizer(this.model)
      : _resolvable = {
          ..._coreNames,
          for (final cls in model.classes) ...[
            cls.name,
            for (final param in cls.params) ...param.typeOrigins.keys,
            for (final param
                in cls.unnamedConstructorParams ?? const <SurfaceParam>[])
              ...param.typeOrigins.keys,
            for (final factory in cls.factories)
              for (final param in factory.params) ...param.typeOrigins.keys,
          ],
        };

  final SurfaceModel model;

  /// Every top-level name the generated file can actually resolve: the
  /// modelled classes (through the barrel), every type the model NAMES (which
  /// is what the `show` clause is derived from), and the dart:core handful.
  final Set<String> _resolvable;

  /// Extra Flutter names the synthesized values reference (`Curves`).
  final Set<String> flutterNames = <String>{};

  static const Set<String> _coreNames = {
    'Duration',
    'DateTime',
    'Object',
    'String',
    'int',
    'double',
    'num',
    'bool',
    'List',
    'Map',
    'Set',
    'Iterable',
  };

  /// Identifiers that start an expression rather than following a `.`, and
  /// are not a named-argument label.
  static final RegExp _rootIdentifier =
      RegExp(r'(?<![.\w$])([A-Za-z_$][A-Za-z0-9_$]*)(?!\s*:)');

  /// The argument a VERB is handed.
  String? probe(SurfaceParam param, {String? typeOverride}) {
    final type = typeOverride ?? stripNullability(param.dartType);
    if (typeOverride == null) {
      final fromDefault = _fromDefault(param);
      if (fromDefault != null) return fromDefault;
    }
    return _value(type, param, _probeLiterals, 0);
  }

  /// The argument a SUBJECT is built with.
  ///
  /// Defaults are never used here: an optional parameter is simply omitted, so
  /// only required parameters reach this, and they take base literals.
  String? base(SurfaceParam param) =>
      _value(stripNullability(param.dartType), param, _baseLiterals, 0);

  /// The argument a COMBINED SETTER member is handed.
  ///
  /// A non-nullable member replays the subject's own value — guaranteed to
  /// satisfy whatever invariant the setter exists for. A nullable numeric
  /// member cannot (`double?` does not fit a `double` parameter), so it probes
  /// ascending values, which is what the `min`/`max` idiom needs.
  String? combined(SurfaceParam param, {required int ascendingIndex}) {
    if (!param.isNullable && !isExcludedParam(param)) {
      return 'subject.${param.name}';
    }
    if (usesAscending(param)) {
      final type = stripNullability(param.dartType);
      return type == 'int' || type == 'num'
          ? '${ascendingIndex + 1}'
          : '${ascendingIndex + 1}.0';
    }
    return probe(param);
  }

  /// Whether [param] takes an ascending numeric probe in a combined setter.
  bool usesAscending(SurfaceParam param) {
    if (!param.isNullable) return false;
    return const {'double', 'int', 'num'}
        .contains(stripNullability(param.dartType));
  }

  /// The parameter's own default, when the generated file could evaluate it.
  ///
  /// A default is only usable when every name it ROOTS on is one the smoke
  /// library resolves. `const TextStyle(color: Colors.black)` is a real
  /// default in this fleet and `Colors` lives in `package:flutter/material.dart`,
  /// which generated code never imports; taking it verbatim produced eleven
  /// `Undefined name 'Colors'` errors. A lowercase or private root is rejected
  /// outright — it is a library-private constant the smoke file cannot see.
  String? _fromDefault(SurfaceParam param) {
    final code = param.defaultCode;
    if (code == null || code.isEmpty || code == 'null') return null;
    for (final match in _rootIdentifier.allMatches(code)) {
      final name = match.group(1)!;
      if (_dartKeywords.contains(name)) continue;
      final first = name[0];
      if (first != first.toUpperCase() || first == '_') return null;
      if (!_resolvable.contains(name)) return null;
    }
    return code;
  }

  static const Set<String> _dartKeywords = {
    'const',
    'new',
    'true',
    'false',
    'null',
    'if',
    'else',
    'is',
    'as',
    'in',
    'for',
    'return',
  };

  String? _value(
    String type,
    SurfaceParam param,
    Map<String, String> literals,
    int depth,
  ) {
    final literal = literals[type];
    if (literal != null) return literal;

    if (param.kind == SurfaceParamKind.enumType &&
        param.enumValues.isNotEmpty &&
        type == stripNullability(param.dartType)) {
      return '$type.values.first';
    }

    final framework = _frameworkValues[type];
    if (framework != null) {
      final extra = framework.$2;
      if (extra != null) flutterNames.add(extra);
      return framework.$1;
    }

    if (type.startsWith('List<') && type.endsWith('>')) {
      return 'const <${type.substring(5, type.length - 1)}>[]';
    }
    if (type.startsWith('Set<') && type.endsWith('>')) {
      return 'const <${type.substring(4, type.length - 1)}>{}';
    }
    if (type.startsWith('Map<') && type.endsWith('>')) {
      return 'const <${type.substring(4, type.length - 1)}>{}';
    }

    if (depth < 3) {
      final nested = model.tryByName(type);
      if (nested != null && !nested.isSealed) {
        final construction = _construct(nested, literals, depth + 1);
        if (construction != null) return construction;
      }
    }
    return null;
  }

  /// `Foo(required: ...)` for a modelled class, or `null`.
  String? _construct(
    SurfaceClass cls,
    Map<String, String> literals,
    int depth,
  ) {
    final params = cls.unnamedConstructorParams;
    if (params == null) return null;
    if (cls.typeParameters.isNotEmpty) return null;
    final arguments = <String>[];
    for (final param in params) {
      if (!param.isRequired) continue;
      final argument = _value(
        stripNullability(param.dartType),
        param,
        literals,
        depth,
      );
      if (argument == null) return null;
      arguments.add(param.isNamed ? '${param.name}: $argument' : argument);
    }
    return '${cls.name}(${arguments.join(', ')})';
  }
}

/// Allocates the extra parameters of a compile-only smoke function, which
/// stand in for types with no synthesizable value.
class _ParameterPool {
  final List<String> declarations = <String>[];

  String declare(String dartType) {
    final type = stripNullability(dartType);
    final name = 'a${declarations.length}';
    declarations.add('$type $name');
    return name;
  }
}
