// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Dumps the CURRENT `ChartToolSchema.tools` to JSON.
///
/// This is the provenance of `test/unit/ai/fixtures/pre_convergence_schema.json`
/// — the behavioural baseline captured BEFORE the AI tool schema converges onto
/// generated output. Any future convergence work diffs its generated schema
/// against that fixture; regenerate the baseline only when deliberately
/// re-baselining, never to make a superset test pass.
///
/// ```
/// dart run tool/dump_pre_convergence_schema.dart \
///     test/unit/ai/fixtures/pre_convergence_schema.json
/// ```
library;

import 'dart:convert';
import 'dart:io';

// The public barrel transitively imports dart:ui, which a plain `dart run`
// cannot compile. `chart_tool_schema.dart` is a leaf library with no imports at
// all, so importing it directly keeps this a Flutter-free script.
// ignore: implementation_imports
import 'package:braven_charts/src/ai/chart_tool_schema.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/dump_pre_convergence_schema.dart <output.json>',
    );
    exitCode = 64;
    return;
  }
  final out = File(args.single)..parent.createSync(recursive: true);
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(ChartToolSchema.tools)}\n',
  );
}
