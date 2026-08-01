// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

/// Regression surface for a Bezier curve whose X values contain a tight cluster
/// immediately before a distant sample. The cyan curve must preserve forward X
/// motion while the dashed linear reference exposes the point-to-point spine.
library;

import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;

const _points = <ChartDataPoint>[
  ChartDataPoint(x: 14, y: 48),
  ChartDataPoint(x: 19, y: 55),
  ChartDataPoint(x: 24, y: 62),
  ChartDataPoint(x: 28.5, y: 82),
  ChartDataPoint(x: 32.8, y: 94),
  ChartDataPoint(x: 35.9, y: 116),
  ChartDataPoint(x: 36, y: 138),
  ChartDataPoint(x: 36.08, y: 136),
  ChartDataPoint(x: 36.14, y: 151),
  ChartDataPoint(x: 36.22, y: 121),
  ChartDataPoint(x: 36.31, y: 145),
  ChartDataPoint(x: 42.5, y: 130),
  ChartDataPoint(x: 44.9, y: 128),
  ChartDataPoint(x: 45, y: 109),
  ChartDataPoint(x: 45.03, y: 134),
  ChartDataPoint(x: 45.09, y: 112),
  ChartDataPoint(x: 45.18, y: 141),
  ChartDataPoint(x: 57.5, y: 113),
];

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('line_close_points_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('close X cluster preserves forward Bezier motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('line-close-points-golden'),
            child: BravenChartPlus(
              width: 900,
              height: 520,
              title: 'Close-point Bezier characterization',
              subtitle: 'Cyan: Bezier · Grey: linear reference',
              xAxisConfig: XAxisConfig(label: 'Elapsed time (min)'),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                label: 'Response (L/min)',
              ),
              series: [
                LineChartSeries(
                  id: 'linear-reference',
                  name: 'Linear reference',
                  unit: 'L/min',
                  points: _points,
                  color: Color(0xFF94A3B8),
                  interpolation: LineInterpolation.linear,
                  strokeWidth: 1.5,
                  dashPattern: [5, 4],
                ),
                LineChartSeries(
                  id: 'bezier-response',
                  name: 'Bezier response',
                  unit: 'L/min',
                  points: _points,
                  color: Color(0xFF0891B2),
                  interpolation: LineInterpolation.bezier,
                  tension: 0.25,
                  strokeWidth: 3,
                  showDataPointMarkers: true,
                  dataPointMarkerRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('line-close-points-golden')),
      matchesGoldenFile('goldens/bezier_close_points_characterization.png'),
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
