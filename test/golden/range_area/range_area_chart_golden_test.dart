// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;
const _surfaceKey = ValueKey('range-area-golden-surface');

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('range_area_chart_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('light nested forecast fan', (tester) async {
    final outer = _forecastIntervals(width: 11);
    final inner = _forecastIntervals(width: 5);
    await _pumpSurface(
      tester,
      size: const Size(640, 420),
      theme: _goldenTheme(ChartTheme.light),
      series: [
        RangeAreaChartSeries(
          id: 'outer',
          name: '95% interval',
          points: outer,
          color: const Color(0xFF4F46E5),
          fillOpacity: .2,
          fillGradient: const AreaGradient(
            colors: [Color(0x334F46E5), Color(0x994F46E5)],
          ),
          interpolation: LineInterpolation.monotone,
        ),
        RangeAreaChartSeries(
          id: 'inner',
          name: '50% interval',
          points: inner,
          color: const Color(0xFF7C3AED),
          fillOpacity: .32,
          interpolation: LineInterpolation.monotone,
          showBoundaryMarkers: true,
          markerRadius: 2.5,
        ),
        LineChartSeries(
          id: 'forecast',
          name: 'Forecast',
          color: const Color(0xFFDB2777),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.2,
          points: [
            for (final point in inner)
              ChartDataPoint(x: point.x, y: point.midpoint!),
          ],
        ),
      ],
    );

    await _expectGolden(tester, 'goldens/range_area_forecast_fan_light.png');
  });

  testWidgets('dark stepped intervals preserve gaps', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(640, 380),
      theme: _goldenTheme(ChartTheme.dark),
      series: [
        RangeAreaChartSeries(
          id: 'availability',
          name: 'Availability range',
          color: const Color(0xFF22D3EE),
          interpolation: LineInterpolation.stepped,
          fillOpacity: .3,
          lowerBoundaryStyle: const RangeAreaBoundaryStyle(dashPattern: [6, 4]),
          showBoundaryMarkers: true,
          points: _steppedIntervals(),
        ),
      ],
    );

    await _expectGolden(tester, 'goldens/range_area_stepped_gaps_dark.png');
  });

  testWidgets('compact high-contrast interval remains legible', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(360, 340),
      theme: _goldenTheme(ChartTheme.highContrast),
      textScaler: const TextScaler.linear(1.25),
      highContrast: true,
      showLegend: false,
      series: [
        RangeAreaChartSeries(
          id: 'temperature',
          points: _forecastIntervals(width: 8).take(12).toList(),
          color: const Color(0xFF0EA5E9),
          interpolation: LineInterpolation.monotone,
          fillOpacity: .36,
          showBoundaryMarkers: true,
          markerRadius: 3,
        ),
      ],
    );

    await _expectGolden(tester, 'goldens/range_area_compact_high_contrast.png');
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required List<ChartSeries> series,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
  bool showLegend = true,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _materialTheme(theme.backgroundColor.computeLuminance() < .5),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: textScaler,
          highContrast: highContrast,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _surfaceKey,
            child: ColoredBox(
              color: theme.backgroundColor,
              child: SizedBox.fromSize(
                size: size,
                child: BravenChartPlus(
                  series: series,
                  theme: theme,
                  showLegend: showLegend,
                  grid: const GridConfig(horizontal: true, vertical: true),
                  xAxisConfig: const XAxisConfig(
                    label: 'Forecast horizon',
                    tickCount: 6,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Expected range',
                    unit: '%',
                    tickCount: 6,
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
}

Future<void> _expectGolden(WidgetTester tester, String path) async {
  await expectLater(find.byKey(_surfaceKey), matchesGoldenFile(path));
}

List<RangeAreaDataPoint> _forecastIntervals({required double width}) => [
  for (var index = 0; index < 20; index++)
    RangeAreaDataPoint(
      x: index.toDouble(),
      low:
          52 +
          index * .7 +
          math.sin(index * .45) * 3 -
          (width + index * .16) / 2,
      high:
          52 +
          index * .7 +
          math.sin(index * .45) * 3 +
          (width + index * .16) / 2,
    ),
];

List<RangeAreaDataPoint> _steppedIntervals() => [
  RangeAreaDataPoint(x: 0, low: 88, high: 94),
  RangeAreaDataPoint(x: 1, low: 90, high: 96),
  RangeAreaDataPoint(x: 2, low: 90, high: 96),
  RangeAreaDataPoint.gap(x: 3),
  RangeAreaDataPoint.gap(x: 4),
  RangeAreaDataPoint(x: 5, low: 92, high: 98),
  RangeAreaDataPoint(x: 6, low: 92, high: 98),
  RangeAreaDataPoint(x: 7, low: 94, high: 100),
  RangeAreaDataPoint.gap(x: 8),
  RangeAreaDataPoint(x: 9, low: 91, high: 97),
  RangeAreaDataPoint(x: 10, low: 91, high: 97),
  RangeAreaDataPoint(x: 11, low: 95, high: 101),
];

ChartTheme _goldenTheme(ChartTheme source) => source.copyWith(
  typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
  animationTheme: source.animationTheme.copyWith(
    dataUpdateDuration: Duration.zero,
    themeChangeDuration: Duration.zero,
    interactionDuration: Duration.zero,
  ),
);

ThemeData _materialTheme(bool dark) {
  final source = dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
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
