// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// Proves [DartSourceWriter.materialAmbiguousNames] is EXACTLY the set of names
/// that clash between the two libraries generated source imports.
///
/// Generated source opens with `package:braven_charts/braven_charts.dart` and
/// `package:flutter/material.dart`, both unprefixed. Any name both libraries
/// export under a different declaration is then `ambiguous_import` wherever the
/// emitter writes it: the file parses, reads perfectly, and does not compile.
/// That is not hypothetical — it is how every radial showcase chain shipped
/// unpasteable until this test's sibling gates went in, because `TooltipConfig`
/// writes a bare `TooltipTriggerMode` and Flutter grew an enum of that name in
/// `raw_tooltip.dart`.
///
/// The emitter cannot discover the clash on its own, so the list is hand-held —
/// and a hand-held list is worth only the test that re-derives it. Both halves
/// are asserted, because each catches a different way the list rots:
///
/// - COMPLETE: exporting both libraries while hiding exactly these names is
///   clean. A NEW clash — this package exporting a name Flutter later adds, or
///   Flutter adding one this package already exports — fails here instead of
///   reaching a user as source they cannot paste.
/// - MINIMAL: hiding nothing reports a clash. If Flutter ever drops
///   `raw_tooltip.dart`, or the package renames its enum, this fails rather
///   than leaving generated source carrying a `hide` for a name that no longer
///   needs hiding.
///
/// The probe is analysed as a real file by a real `dart analyze`, for the same
/// reason `expectGeneratedSourceCompiles` shells out: nothing inside the test
/// process can answer "does the analyzer consider these ambiguous".
library;

import 'dart:io';

import 'package:braven_charts/src/source/dart_source_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the emitter hides exactly the names that clash with package:flutter/material.dart',
    () async {
      final hidden = DartSourceWriter.materialAmbiguousNames;
      expect(
        hidden,
        isNotEmpty,
        reason:
            'an empty list would make both assertions below vacuous; delete '
            'this test with the list if the clash ever disappears entirely',
      );

      // COMPLETE: nothing else clashes.
      expect(
        await _ambiguousNames(hide: hidden),
        isEmpty,
        reason:
            'a name outside DartSourceWriter.materialAmbiguousNames now clashes '
            'between package:braven_charts and package:flutter/material.dart. '
            'Generated source imports both unprefixed, so every chart that '
            'emits that name emits source that does not compile. Add it to the '
            'list.',
      );

      // MINIMAL: every listed name really does clash. Checked one at a time so
      // the failure names the stale entry rather than the whole list.
      for (final name in hidden) {
        expect(
          await _ambiguousNames(hide: hidden.where((it) => it != name)),
          contains(name),
          reason:
              "'$name' is in DartSourceWriter.materialAmbiguousNames but no "
              'longer clashes, so generated source carries a hide clause it '
              'does not need. Remove it from the list.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

/// The names the analyzer reports as ambiguous between the two libraries
/// generated source imports, with [hide] hidden from the Flutter side.
///
/// `dart analyze` reports at most one `ambiguous_export` per export directive,
/// so this hides each name it finds and re-analyses until the probe is clean.
/// The loop is bounded: every pass either grows the hidden set or stops.
Future<List<String>> _ambiguousNames({required Iterable<String> hide}) async {
  final found = <String>[];
  final hidden = <String>[...hide];
  final probe = File(
    '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
    '${Platform.pathSeparator}generated_import_ambiguity_probe.dart',
  );
  try {
    // A generous bound rather than `while (true)`: a probe that somehow stopped
    // converging must fail the test, never hang the suite.
    for (var pass = 0; pass < 32; pass++) {
      final combinator = hidden.isEmpty ? '' : ' hide ${hidden.join(', ')}';
      await probe.writeAsString(
        "export 'package:braven_charts/braven_charts.dart';\n"
        "export 'package:flutter/material.dart'$combinator;\n",
      );
      final analyze = await Process.run(
        'dart',
        ['analyze', '--no-fatal-warnings', probe.path],
        workingDirectory: Directory.current.path,
        runInShell: Platform.isWindows,
      );
      if (analyze.exitCode == 0) return found;

      final output = '${analyze.stdout}';
      final match = RegExp(
        r"The name '([A-Za-z0-9_$]+)' is defined in the libraries",
      ).firstMatch(output);
      expect(
        match,
        isNotNull,
        reason:
            'the ambiguity probe failed to analyze for a reason other than an '
            'ambiguous export:\n$output\n${analyze.stderr}',
      );
      final name = match!.group(1)!;
      found.add(name);
      hidden.add(name);
    }
    fail('the ambiguity probe never converged; hid: $hidden');
  } finally {
    if (await probe.exists()) await probe.delete();
  }
}
