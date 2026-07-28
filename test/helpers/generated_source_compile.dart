// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Shared harness for "the generated Dart really parses and resolves" proofs.
///
/// Lifted verbatim from `test/unit/source/chart_generated_source_compile_test.dart`
/// so that a second caller does not fork the format-then-analyze recipe.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Writes [source] to a scratch file and asserts `dart format` and
/// `dart analyze` both accept it.
///
/// What each step actually proves, because the function's name promises more
/// than either delivers on its own:
///
/// - `dart format --output=none` PARSES the file and throws the formatted text
///   away, so exit 0 means "syntactically valid Dart" and nothing more. It does
///   NOT mean "already formatted": that assertion needs
///   `--set-exit-if-changed`, which this harness does not pass, and the emitted
///   chains would not survive it — they are laid out for a human reading the
///   Source pane (verified: adding the flag fails ~48 of the emitter's
///   round-trip cases). What this step does buy is a syntax gate — a dropped
///   paren or a mangled literal fails here, instead of reaching `dart analyze`
///   as a cascade of unrelated errors.
/// - `dart analyze --no-fatal-warnings` RESOLVES it against the real package
///   (the scratch file sits under the package root, so `package:braven_charts`
///   imports resolve): an unknown builder method, a misnamed parameter, a wrong
///   argument type all fail here. That is the substantive gate.
///
/// Neither step EXECUTES the chain, so "compiles" means "would compile", never
/// "renders the same chart". Callers carry that separately, with the round-trip
/// proof and their own assertions on the emitted text.
Future<void> expectGeneratedSourceCompiles(
  String source, {
  required String fixtureName,
}) async {
  final fixture = File(
    '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
    '${Platform.pathSeparator}$fixtureName.dart',
  );
  await fixture.writeAsString(
    '// ignore_for_file: prefer_const_constructors\n$source',
  );
  try {
    final format = await Process.run(
      'dart',
      ['format', '--output=none', fixture.path],
      workingDirectory: Directory.current.path,
      runInShell: Platform.isWindows,
    );
    expect(format.exitCode, 0, reason: '${format.stdout}\n${format.stderr}');

    final analyze = await Process.run(
      'dart',
      ['analyze', '--no-fatal-warnings', fixture.path],
      workingDirectory: Directory.current.path,
      runInShell: Platform.isWindows,
    );
    expect(analyze.exitCode, 0, reason: '${analyze.stdout}\n${analyze.stderr}');
  } finally {
    if (await fixture.exists()) await fixture.delete();
  }
}
