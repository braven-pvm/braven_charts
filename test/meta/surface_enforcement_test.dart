@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:surface_gen/src/enforcement.dart';

/// Enforcement of the `@chartSurface` surface model against the REAL public
/// entrypoints, `lib/*.dart` (today `braven_charts.dart` and the generated
/// `braven_charts_fluent.dart`).
///
/// ## How this runs
///
/// The check needs resolved analyzer elements for the whole exported surface,
/// so it drives `package:analyzer` directly (`AnalysisContextCollection` over
/// `lib/`) rather than build_runner. That works inside `flutter test` with one
/// caveat: the host executable is `flutter_tester`, not `dart`, so the
/// analyzer cannot derive an SDK root from `Platform.resolvedExecutable`. The
/// SDK path is therefore taken from `FLUTTER_ROOT` (see [_sdkPath]).
///
/// Resolving the entrypoints takes ~15s, hence the 5-minute file timeout.
///
/// ## HARD MODE (promoted in Task 6)
///
/// 'every barrel-reachable config-shaped class carries @chartSurface or
/// @ChartSurfaceExempt' is a hard assertion: a new instantiable public class
/// with a `copyWith` fails this test until it is modelled or deliberately
/// exempted. That is the whole promise of the surface model — a future
/// feature cannot bypass it — and it is only real now that the assertion is
/// no longer skipped.
///
/// The backlog report is still printed from `setUpAll` on every run, so a
/// regression names the offending classes in the CI log instead of only in a
/// matcher failure.

/// The Slice 1 pilots. These must never regress to unannotated.
const _pilots = <String>[
  'CartesianValueSummaryStyle',
  'CrosshairConfig',
  'LineChartSeries',
];

/// The exemptions that have been reviewed and accepted.
///
/// An exemption is a permanent hole in the surface model. Pinning the set here
/// means a new `@ChartSurfaceExempt` fails this test until it is added
/// deliberately — with the reason read by a human — instead of quietly
/// shrinking the modelled surface.
const _allowedExemptions = <String>[
  // Slicing base copyWith; only the concrete series types are modelled.
  'ChartSeries',
  // Runtime coordinate mapping derived by the render pipeline (Task 5).
  'ChartTransform',
  // Render-time bar-slot layout result produced per frame (Task 5).
  'BarGroupInfo',
];

/// Directories holding checked-in generator output.
const _generatedDirectories = <String>[
  'lib/src/fluent/generated',
  'lib/src/ai/generated',
];

String get _separator => Platform.pathSeparator;

/// The Dart SDK the analyzer should use.
///
/// Under `flutter test` the host executable is `flutter_tester`, so the
/// analyzer cannot infer an SDK: `FLUTTER_ROOT` (always set by the `flutter`
/// tool, including on CI) supplies the bundled SDK. The derived directory is
/// verified so a wrong `FLUTTER_ROOT` fails with that message rather than
/// silently degrading into an unresolved scan. When the variable is unset —
/// an IDE or bare `dart test` run — fall back to the SDK that owns the host
/// executable.
String get _sdkPath {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final sdk =
        '$flutterRoot${_separator}bin'
        '${_separator}cache'
        '${_separator}dart-sdk';
    if (!Directory(sdk).existsSync()) {
      fail(
        'FLUTTER_ROOT is set to "$flutterRoot" but "$sdk" does not exist. '
        'This test resolves the package with package:analyzer and needs the '
        'Flutter-bundled Dart SDK.',
      );
    }
    return sdk;
  }

  final candidate = File(Platform.resolvedExecutable).parent.parent.path;
  final isDartSdk =
      File('$candidate${_separator}version').existsSync() &&
      Directory('$candidate${_separator}lib').existsSync();
  if (isDartSdk) return candidate;
  fail(
    'FLUTTER_ROOT is unset and the host executable '
    '(${Platform.resolvedExecutable}) does not belong to a Dart SDK. Run this '
    'test through `flutter test`, or set FLUTTER_ROOT.',
  );
}

String get _libPath => '${Directory.current.path}${_separator}lib';

/// Every checked-in generated source, concatenated.
String _generatedSources() {
  final buffer = StringBuffer();
  for (final relative in _generatedDirectories) {
    final directory = Directory(
      '${Directory.current.path}$_separator'
      '${relative.replaceAll('/', _separator)}',
    );
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        buffer.writeln(entity.readAsStringSync());
      }
    }
  }
  return buffer.toString();
}

/// The body of `extension <name>Fluent on <name>` in [sources], or `null`
/// when no such extension was generated.
///
/// `dart_style` wraps the declaration onto a second line once the class name
/// is long enough (`extension CartesianValueSummaryAnnotationFluent\n    on
/// CartesianValueSummaryAnnotation {`), so the header is matched with a
/// whitespace-tolerant pattern rather than a literal.
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

void main() {
  late EnforcementResult result;
  late String report;

  setUpAll(() async {
    result = await checkPackageSurface(libPath: _libPath, sdkPath: _sdkPath);
    report =
        '\n[surface enforcement] annotated=${result.annotated.length} '
        'exempt=${result.exempt.length} missing=${result.missing.length}\n'
        'exempt:\n${result.describeExempt()}'
        'un-annotated config-shaped classes:\n${result.describeMissing()}';
    // The backlog must be visible in every CI log, including while the hard
    // gate below is skipped.
    // ignore: avoid_print
    print(report);
  });

  test('the entrypoints resolve and yield a non-trivial surface', () {
    expect(
      result.annotated.length + result.exempt.length + result.missing.length,
      greaterThan(20),
      reason:
          'the export namespace scan produced implausibly few classes — '
          'the entrypoints probably failed to resolve',
    );
  });

  test('the Slice 1 pilot classes are annotated', () {
    for (final pilot in _pilots) {
      expect(
        result.isAnnotated(pilot),
        isTrue,
        reason: '$pilot lost its @chartSurface annotation',
      );
    }
  });

  test('exemptions match the reviewed allowlist', () {
    expect(
      result.exempt.map((entry) => entry.className),
      unorderedEquals(_allowedExemptions),
      reason:
          'the exempt set changed. An exemption is a permanent hole in '
          'the surface model: justify it, then add the class to '
          '_allowedExemptions.\n${result.describeExempt()}',
    );
    for (final entry in result.exempt) {
      expect(
        entry.exemptReason?.length ?? 0,
        greaterThanOrEqualTo(12),
        reason: '${entry.className} has a placeholder exemption reason',
      );
    }
  });

  test('every annotated config class has a non-empty generated extension', () {
    final sources = _generatedSources();
    final generable = result.annotated
        .where((entry) => entry.hasInstanceCopyWith)
        .toList();
    expect(
      generable,
      isNotEmpty,
      reason: 'no annotated class has a copyWith — the scan is broken',
    );
    for (final entry in generable) {
      final body = _fluentExtensionBody(sources, entry.className);
      expect(
        body,
        isNotNull,
        reason:
            '${entry.className} is annotated and has a copyWith, but no '
            'extension ${entry.className}Fluent was generated. Run '
            "'dart run build_runner build'.",
      );
      expect(
        body,
        contains('copyWith('),
        reason:
            'extension ${entry.className}Fluent was generated EMPTY — '
            'the emitter produced no modifiers for an annotated class.',
      );
    }
  });

  test('every barrel-reachable config-shaped class carries @chartSurface or '
      '@ChartSurfaceExempt', () {
    expect(result.isClean, isTrue, reason: report);
  });
}
