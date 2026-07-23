// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// One representative bar chart whose WIDTH is driven by a size channel:
/// bars of increasing width (a linear multiplier map), left to right.
library;

import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-platform antialiasing tolerance — the repo's golden convention (the
/// same `_TolerantGoldenFileComparator` every other golden suite uses). Windows
/// and the ubuntu CI runner render sub-pixel edges slightly differently.
const _pixelTolerance = 0.035;

class Bar {
  const Bar(this.cat, this.value, this.weight);
  final double cat;
  final double value;
  final double weight;
}

double bcat(Bar r) => r.cat;
double bval(Bar r) => r.value;
double bweight(Bar r) => r.weight;

const rows = <Bar>[Bar(0, 10, 0), Bar(1, 20, 5), Bar(2, 15, 10)];
// Width multiplier range 0.5 .. 1.5 (linear over the weight domain).
const widths = ScatterSizeEncoding(minimumRadius: 0.5, maximumRadius: 1.5);

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('grammar_channels_bar_size_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('bar width driven by a size channel: increasing widths', (
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
            key: const ValueKey('grammar-channels-bar-size-golden'),
            child: BravenChart.of(rows)
                .x(bcat)
                .y(bval)
                .geomBar(
                  sizeBy: Channel(bweight, label: 'Weight'),
                  sizeEncoding: widths,
                )
                .build(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('grammar-channels-bar-size-golden')),
      matchesGoldenFile('goldens/bar_size.png'),
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
