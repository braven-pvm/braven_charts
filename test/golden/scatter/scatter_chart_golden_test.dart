// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The intentional Scatter baseline is a compact market-position composition.
///
/// Two cohorts exercise circle and diamond marker geometry while active
/// accounts drive marker area through [ScatterSizeEncoding]. Fixed bounds,
/// Ahem typography, a pinned surface, disabled interaction, and zero-duration
/// chart animations keep the baseline deterministic.
const _pixelTolerance = 0.035;
const _surfaceKey = ValueKey('scatter-golden-surface');

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('scatter_chart_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('marker geometry and magnitude encoding remain stable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final chartTheme = _goldenTheme(ChartTheme.light);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _materialTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true, textScaler: TextScaler.noScaling),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: _surfaceKey,
              child: ColoredBox(
                color: chartTheme.backgroundColor,
                child: SizedBox(
                  width: 640,
                  height: 420,
                  child: BravenChartPlus(
                    title: 'Market opportunity',
                    subtitle: 'Growth, retention, and active accounts',
                    series: _marketSeries,
                    theme: chartTheme,
                    interactionConfig: InteractionConfig.none(),
                    showLegend: true,
                    legendStyle: const LegendStyle(
                      position: LegendPosition.topRight,
                      orientation: LegendOrientation.horizontal,
                      allowDragging: false,
                      textStyle: TextStyle(
                        color: Color(0xFF334155),
                        fontFamily: 'Ahem',
                        fontSize: 9,
                      ),
                    ),
                    grid: const GridConfig(horizontal: true, vertical: true),
                    xAxisConfig: const XAxisConfig(
                      label: 'Revenue growth',
                      unit: '%',
                      min: 0,
                      max: 40,
                      tickCount: 5,
                    ),
                    yAxis: YAxisConfig(
                      position: YAxisPosition.left,
                      label: 'Retention',
                      unit: '%',
                      min: 68,
                      max: 100,
                      tickCount: 5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(_surfaceKey),
      matchesGoldenFile('goldens/scatter_market_opportunity.png'),
    );
  });
}

const _marketSeries = <ScatterChartSeries>[
  ScatterChartSeries(
    id: 'established',
    name: 'Established',
    color: Color(0xFF2563EB),
    markerShape: SeriesMarkerShape.circle,
    markerStyle: ScatterMarkerStyle(
      strokeColor: Color(0xFF1E3A8A),
      strokeWidth: 1.5,
      opacity: 0.82,
    ),
    sizeEncoding: ScatterSizeEncoding(
      minimumRadius: 6,
      maximumRadius: 22,
      maximumValue: 18000,
      label: 'Active accounts',
    ),
    points: [
      ChartDataPoint(x: 7, y: 94, magnitude: 16400),
      ChartDataPoint(x: 11, y: 90, magnitude: 9800),
      ChartDataPoint(x: 15, y: 86, magnitude: 7200),
      ChartDataPoint(x: 19, y: 92, magnitude: 12100),
    ],
  ),
  ScatterChartSeries(
    id: 'growth',
    name: 'Growth',
    color: Color(0xFFF97316),
    markerShape: SeriesMarkerShape.diamond,
    markerStyle: ScatterMarkerStyle(
      strokeColor: Color(0xFF9A3412),
      strokeWidth: 1.5,
      opacity: 0.84,
      rotationDegrees: 4,
    ),
    sizeEncoding: ScatterSizeEncoding(
      minimumRadius: 6,
      maximumRadius: 22,
      maximumValue: 18000,
      label: 'Active accounts',
    ),
    points: [
      ChartDataPoint(x: 18, y: 78, magnitude: 4100),
      ChartDataPoint(x: 24, y: 84, magnitude: 6900),
      ChartDataPoint(x: 30, y: 89, magnitude: 11300),
      ChartDataPoint(x: 36, y: 96, magnitude: 15300),
    ],
  ),
];

ChartTheme _goldenTheme(ChartTheme source) => source.copyWith(
  typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
  animationTheme: source.animationTheme.copyWith(
    dataUpdateDuration: Duration.zero,
    themeChangeDuration: Duration.zero,
    interactionDuration: Duration.zero,
  ),
);

ThemeData _materialTheme() {
  final source = ThemeData.light(useMaterial3: true);
  return source.copyWith(textTheme: source.textTheme.apply(fontFamily: 'Ahem'));
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required this.precisionTolerance,
  });

  final double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
