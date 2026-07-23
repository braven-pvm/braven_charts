// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// One representative bar chart whose fill is driven by a colour channel:
/// a blue -> red gradient across three bars, plus a colour-ramp legend.
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

class Bar {
  const Bar(this.cat, this.value, this.heat);
  final double cat;
  final double value;
  final double heat;
}

double barCat(Bar r) => r.cat;
double barValue(Bar r) => r.value;
double barHeat(Bar r) => r.heat;

const rows = <Bar>[
  Bar(0, 10, 0), // heat min
  Bar(1, 20, 5),
  Bar(2, 15, 10), // heat max
];

const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
  label: 'Heat',
);

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('grammar_channels_bar_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('bar fill driven by a colour channel: blue -> red', (
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
            key: const ValueKey('grammar-channels-bar-golden'),
            child: BravenChart.of(rows)
                .x(barCat)
                .y(barValue)
                .geomBar(
                  colorBy: Channel(barHeat, label: 'Heat'),
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
      find.byKey(const ValueKey('grammar-channels-bar-golden')),
      matchesGoldenFile('goldens/bar_color.png'),
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
