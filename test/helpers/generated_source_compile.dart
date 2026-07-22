// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Shared harness for "the generated Dart really compiles" proofs.
///
/// Lifted verbatim from `test/unit/source/chart_generated_source_compile_test.dart`
/// so that a second caller does not fork the format-then-analyze recipe.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Writes [source] to a scratch file and asserts `dart format` and
/// `dart analyze` both accept it.
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
