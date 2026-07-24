// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// One representative line chart whose stroke is driven by a colour channel:
/// a green -> red gradient along the line (leading-point rule), plus a
/// colour-ramp legend.
library;

import 'dart:typed_data';
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-platform antialiasing tolerance — the repo's golden convention (the
/// same `_TolerantGoldenFileComparator` every other golden suite uses). Windows
/// and the ubuntu CI runner render sub-pixel edges slightly differently.
const _pixelTolerance = 0.035;

class P {
  const P(this.t, this.v, this.pace);
  final double t;
  final double v;
  final double pace;
}

double pt(P r) => r.t;
double pv(P r) => r.v;
double ppace(P r) => r.pace;

const rows = <P>[P(0, 5, 0), P(1, 7, 5), P(2, 6, 10)];

const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF00FF00), Color(0xFFFF0000)],
  label: 'Pace',
);

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('grammar_channels_line_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('line stroke driven by a colour channel: green -> red', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('grammar-channels-line-golden'),
            child: BravenChart.of(rows)
                .x(pt)
                .y(pv)
                .geomLine(
                  colorBy: Channel(ppace, label: 'Pace'),
                  colorEncoding: ramp,
                )
                .build(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('grammar-channels-line-golden')),
      matchesGoldenFile('goldens/line_color.png'),
    );
  });
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
