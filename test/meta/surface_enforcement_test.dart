@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:surface_gen/src/enforcement.dart';

/// Enforcement of the `@chartSurface` surface model against the REAL public
/// barrel, `lib/braven_charts.dart`.
///
/// ## How this runs
///
/// The check needs resolved analyzer elements for the whole exported surface,
/// so it drives `package:analyzer` directly (`AnalysisContextCollection` over
/// `lib/`) rather than build_runner. That works inside `flutter test` with one
/// caveat: the host executable is `flutter_tester`, not `dart`, so the
/// analyzer cannot derive an SDK root from `Platform.resolvedExecutable`. The
/// SDK path is therefore passed explicitly from `FLUTTER_ROOT`.
///
/// Resolving the barrel takes ~12s, hence the 5-minute file timeout.
///
/// ## Slice 1 = REPORT MODE
///
/// The hard assertion below ("every barrel-reachable config-shaped class is
/// annotated") is currently `skip`ped: the fleet is annotated incrementally in
/// Tasks 5 and 6. What IS hard today: the three Slice 1 pilots must stay
/// annotated. The report test prints the full un-annotated list with its count
/// so the remaining work is visible in every CI log.
///
/// >>> TASK 6 PROMOTION POINT: delete the `skip:` argument on
/// >>> 'every barrel-reachable config-shaped class carries @chartSurface or
/// >>> @ChartSurfaceExempt' — nothing else changes. <<<

/// The Slice 1 pilots. These must never regress to unannotated.
const _pilots = <String>[
  'CartesianValueSummaryStyle',
  'CrosshairConfig',
  'LineChartSeries',
];

/// The Flutter-bundled Dart SDK, which `flutter_tester` cannot infer.
String get _sdkPath {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    fail(
      'FLUTTER_ROOT is unset. This test resolves the package with '
      'package:analyzer and needs the Flutter-bundled Dart SDK path.',
    );
  }
  return '$flutterRoot${Platform.pathSeparator}bin'
      '${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}dart-sdk';
}

String get _barrelPath =>
    '${Directory.current.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}braven_charts.dart';

void main() {
  late EnforcementResult result;

  setUpAll(() async {
    result = await checkPackageBarrel(
      barrelPath: _barrelPath,
      sdkPath: _sdkPath,
    );
  });

  test('the barrel resolves and yields a non-trivial surface', () {
    expect(
      result.annotated.length + result.exempt.length + result.missing.length,
      greaterThan(20),
      reason: 'the export namespace scan produced implausibly few classes — '
          'the barrel probably failed to resolve',
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

  test('REPORT MODE: un-annotated config surface (Task 5/6 backlog)', () {
    // ignore: avoid_print
    print(
      '\n[surface enforcement] annotated=${result.annotated.length} '
      'exempt=${result.exempt.length} missing=${result.missing.length}\n'
      '${result.describeMissing()}',
    );
    expect(result.missing, isNotEmpty, reason: 'report mode is now obsolete');
  });

  test(
    'every barrel-reachable config-shaped class carries @chartSurface or '
    '@ChartSurfaceExempt',
    () {
      expect(
        result.isClean,
        isTrue,
        reason: 'un-annotated config-shaped classes:\n'
            '${result.describeMissing()}',
      );
    },
    skip: 'REPORT MODE (Slice 1). Task 6 annotates the fleet and deletes '
        'this skip, turning the surface model into a hard gate.',
  );
}
