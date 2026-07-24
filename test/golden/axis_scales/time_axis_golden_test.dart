// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Render golden for a time (DateTime) X axis: a smooth monthly series over
/// ~3 years (Jan 2024 -> Jan 2027) whose x values are epoch-milliseconds.
/// Positions use the LINEAR arm of `ChartTransform` (epoch-millis map
/// linearly); only the tick spacing (real calendar year boundaries) and the
/// auto date labels (`2024/2025/2026/2027`) are the Phase-3 time render path.
/// The linear/log arms stay byte-identical — proven by the rest of
/// `test/golden/` passing untouched.
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

/// Jan 1 2024 / Jan 1 2027 (UTC) epoch-millis — the axis domain spans ~3 years,
/// so the calendar-nice generator resolves to the year interval and ticks land
/// on the 2024/2025/2026/2027 boundaries.
final double _jan2024 = DateTime.utc(2024).millisecondsSinceEpoch.toDouble();
final double _jan2027 = DateTime.utc(2027).millisecondsSinceEpoch.toDouble();

/// A smooth monthly series across the three-year span: each point's x is the
/// real UTC month boundary (epoch-millis), y a gentle sine wave so the line has
/// visible shape against the year gridlines.
final List<ChartDataPoint> _points = <ChartDataPoint>[
  for (var i = 0; i <= 36; i++)
    ChartDataPoint(
      x: DateTime.utc(2024, 1 + i).millisecondsSinceEpoch.toDouble(),
      y: 100 + 50 * math.sin(i * math.pi / 6),
    ),
];

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('time_axis_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('monthly series over ~3 years ticks on year boundaries', (
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
            key: const ValueKey('time-x-axis-golden'),
            child: BravenChartPlus(
              width: 600,
              height: 400,
              xAxisConfig: XAxisConfig(
                label: 'date',
                scaleType: AxisScaleType.time,
                min: _jan2024,
                max: _jan2027,
              ),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                label: 'value',
                min: 0,
                max: 200,
              ),
              series: [
                LineChartSeries(id: 'monthly', points: _points),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('time-x-axis-golden')),
      matchesGoldenFile('goldens/time_x_axis.png'),
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
