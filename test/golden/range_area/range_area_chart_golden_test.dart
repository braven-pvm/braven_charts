// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;
const _surfaceKey = ValueKey('range-area-golden-surface');
const _interactionSurfaceKey = ValueKey(
  'range-area-interaction-golden-surface',
);

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

  testWidgets('interaction hierarchy stays distinct across themes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _materialTheme(false),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: _interactionSurfaceKey,
              child: SizedBox(
                width: 960,
                height: 690,
                child: Column(
                  children: [
                    _RangeAreaInteractionMatrixRow(
                      label: 'Light',
                      chartTheme: ChartTheme.light,
                    ),
                    _RangeAreaInteractionMatrixRow(
                      label: 'Dark',
                      chartTheme: ChartTheme.dark,
                    ),
                    _RangeAreaInteractionMatrixRow(
                      label: 'High contrast',
                      chartTheme: ChartTheme.highContrast,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_interactionSurfaceKey),
      matchesGoldenFile('goldens/range_area_interaction_hierarchy.png'),
    );
  });
}

enum _RangeAreaInteractionState {
  intervalHover,
  bandHover,
  keyboardFocus,
  durableSelection,
}

class _RangeAreaInteractionMatrixRow extends StatelessWidget {
  const _RangeAreaInteractionMatrixRow({
    required this.label,
    required this.chartTheme,
  });

  final String label;
  final ChartTheme chartTheme;

  @override
  Widget build(BuildContext context) {
    final textColor = chartTheme.textColor;
    return ColoredBox(
      color: chartTheme.backgroundColor,
      child: SizedBox(
        height: 230,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Ahem',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (final state in _RangeAreaInteractionState.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                switch (state) {
                                  _RangeAreaInteractionState.intervalHover =>
                                    'Interval hover',
                                  _RangeAreaInteractionState.bandHover =>
                                    'Band hover',
                                  _RangeAreaInteractionState.keyboardFocus =>
                                    'Keyboard focus',
                                  _RangeAreaInteractionState.durableSelection =>
                                    'Durable selection',
                                },
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'Ahem',
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: CustomPaint(
                                  painter: _RangeAreaInteractionMatrixPainter(
                                    state: state,
                                    chartTheme: chartTheme,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeAreaInteractionMatrixPainter extends CustomPainter {
  const _RangeAreaInteractionMatrixPainter({
    required this.state,
    required this.chartTheme,
  });

  final _RangeAreaInteractionState state;
  final ChartTheme chartTheme;

  @override
  void paint(Canvas canvas, Size size) {
    final plotSize = Size(size.width - 16, size.height - 10);
    final transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 10,
      dataYMin: 0,
      dataYMax: 100,
      plotWidth: plotSize.width,
      plotHeight: plotSize.height,
    );
    final outer = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'outer',
        color: const Color(0xFF38BDF8),
        fillOpacity: .16,
        borderMode: RangeAreaBorderMode.boundaries,
        interpolation: LineInterpolation.monotone,
        points: _interactionIntervals(spread: 26),
      ),
      transform: transform,
      rangeAreaTheme: chartTheme.rangeAreaTheme,
    );
    final middle = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'middle',
        color: const Color(0xFF14B8A6),
        fillOpacity: .2,
        borderMode: RangeAreaBorderMode.boundaries,
        interpolation: LineInterpolation.monotone,
        points: _interactionIntervals(spread: 18),
      ),
      transform: transform,
      rangeAreaTheme: chartTheme.rangeAreaTheme,
    );
    final inner = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'inner',
        color: const Color(0xFF8B5CF6),
        fillOpacity: .3,
        borderMode: RangeAreaBorderMode.boundaries,
        interpolation: LineInterpolation.monotone,
        points: _interactionIntervals(spread: 10),
      ),
      transform: transform,
      rangeAreaTheme: chartTheme.rangeAreaTheme,
      isHovered: state == _RangeAreaInteractionState.bandHover,
      focusedPointIndices: state == _RangeAreaInteractionState.keyboardFocus
          ? const {2}
          : const {},
      selectedPointIndices: state == _RangeAreaInteractionState.durableSelection
          ? const {2}
          : const {},
    );

    canvas.save();
    canvas.translate(8, 5);
    outer.paint(canvas, plotSize);
    middle.paint(canvas, plotSize);
    inner.paint(canvas, plotSize);
    if (state == _RangeAreaInteractionState.intervalHover) {
      inner.paintRangeAreaInteractionOverlay(canvas, hoveredPointIndex: 2);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RangeAreaInteractionMatrixPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.chartTheme != chartTheme;
}

List<RangeAreaDataPoint> _interactionIntervals({required double spread}) {
  return [
    for (var index = 0; index < 5; index++)
      RangeAreaDataPoint(
        x: index * 2.5,
        low: 50 + math.sin(index * .9) * 10 - spread,
        high: 50 + math.sin(index * .9) * 10 + spread,
      ),
  ];
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
