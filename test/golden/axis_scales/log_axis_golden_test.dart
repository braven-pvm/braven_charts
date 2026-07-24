// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Render golden for a logarithmic Y axis: an exponential series over three
/// decades (1..1000) straightens into a line under log-Y, and the horizontal
/// grid lands on the decade ticks (equally spaced in pixels). This golden is
/// the visual proof of the Phase-2 log render path; the linear-unchanged
/// regression is proven by the rest of `test/golden/` passing untouched.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-platform antialiasing tolerance — the repo's golden convention (the
/// same `_TolerantGoldenFileComparator` every other golden suite uses). Windows
/// and the ubuntu CI runner render sub-pixel edges slightly differently.
const _pixelTolerance = 0.035;

/// A smooth exponential curve y = 10^(x/4) sampled over x in [0, 12], so y
/// sweeps 1 -> 1000 (three decades) and renders as a straight line on log-Y.
final List<ChartDataPoint> _points = <ChartDataPoint>[
  for (var i = 0; i <= 12; i++)
    ChartDataPoint(x: i.toDouble(), y: math.pow(10, i / 4).toDouble()),
];

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('log_axis_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('exponential series straightens under a log-Y axis', (
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
            key: const ValueKey('log-y-axis-golden'),
            child: BravenChartPlus(
              width: 600,
              height: 400,
              xAxisConfig: const XAxisConfig(label: 'x', min: 0, max: 12),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                label: 'y (log)',
                scaleType: AxisScaleType.log,
                min: 1,
                max: 1000,
              ),
              series: [
                LineChartSeries(id: 'exp', points: _points),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('log-y-axis-golden')),
      matchesGoldenFile('goldens/log_y_axis.png'),
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
