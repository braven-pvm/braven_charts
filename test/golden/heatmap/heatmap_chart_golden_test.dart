// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;
const _surfaceKey = ValueKey('heatmap-golden-surface');

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('heatmap_chart_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('light labelled sequential matrix', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(680, 430),
      theme: _goldenTheme(ChartTheme.light),
      xCategories: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      yCategories: const ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'],
      series: HeatmapChartSeries(
        id: 'temperature',
        name: 'Daily maximum',
        unit: '°C',
        points: [
          for (var row = 0; row < 5; row++)
            for (var column = 0; column < 7; column++)
              if (!((row == 0 && column < 2) || (row == 4 && column > 2)))
                HeatmapDataPoint(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  value: 18 + math.sin((row * 7 + column) * .72) * 5 + row * .8,
                  pointKey: '$row-$column',
                )
              else
                HeatmapDataPoint.missing(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  pointKey: '$row-$column',
                ),
        ],
        colorScale: HeatmapColorScale.sequential(
          colors: const [
            Color(0xFFE0F2FE),
            Color(0xFF67E8F9),
            Color(0xFF0891B2),
            Color(0xFF164E63),
          ],
          minimumValue: 12,
          maximumValue: 29,
          missingColor: const Color(0xFFE2E8F0),
          label: 'Daily maximum',
          unit: '°C',
        ),
        showCellLabels: true,
        gapFraction: .08,
        cornerRadius: 3,
        borderColor: const Color(0x33475569),
        borderWidth: .6,
        animation: _noMotion,
      ),
    );

    await _expectGolden(tester, 'goldens/heatmap_calendar_light.png');
  });

  testWidgets('dark diverging correlation matrix', (tester) async {
    const categories = ['Price', 'Volume', 'Growth', 'Risk', 'Margin', 'NPS'];
    await _pumpSurface(
      tester,
      size: const Size(680, 430),
      theme: _goldenTheme(ChartTheme.dark),
      xCategories: categories,
      yCategories: categories.reversed.toList(),
      series: HeatmapChartSeries(
        id: 'correlation',
        name: 'Correlation',
        points: [
          for (var row = 0; row < categories.length; row++)
            for (var column = 0; column < categories.length; column++)
              HeatmapDataPoint(
                x: column.toDouble(),
                y: row.toDouble(),
                value: row == column
                    ? 1
                    : math.sin((row + 1) * (column + 2) * .73),
                pointKey: '$row-$column',
              ),
        ],
        colorScale: HeatmapColorScale.diverging(
          lowColor: const Color(0xFF2563EB),
          midpointColor: const Color(0xFF1E293B),
          highColor: const Color(0xFFF43F5E),
          midpoint: 0,
          minimumValue: -1,
          maximumValue: 1,
          label: 'Correlation',
        ),
        showCellLabels: true,
        gapFraction: .04,
        cornerRadius: 2,
        borderColor: const Color(0x667C3AED),
        borderWidth: .75,
        animation: _noMotion,
      ),
    );

    await _expectGolden(tester, 'goldens/heatmap_correlation_dark.png');
  });

  testWidgets('compact high-contrast threshold matrix', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(380, 390),
      theme: _goldenTheme(ChartTheme.highContrast),
      textScaler: const TextScaler.linear(1.15),
      highContrast: true,
      xCategories: const ['API', 'Auth', 'Queue', 'DB'],
      yCategories: const ['Now', '-5m', '-10m', '-15m'],
      series: HeatmapChartSeries(
        id: 'health',
        name: 'Service health',
        points: [
          for (var row = 0; row < 4; row++)
            for (var column = 0; column < 4; column++)
              if (row == 3 && column == 1)
                HeatmapDataPoint.missing(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  pointKey: '$row-$column',
                )
              else
                HeatmapDataPoint(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  value: 72 + ((row * 17 + column * 11) % 29),
                  pointKey: '$row-$column',
                ),
        ],
        colorScale: HeatmapColorScale.threshold(
          thresholds: const [80, 94],
          colors: const [
            Color(0xFFDC2626),
            Color(0xFFF59E0B),
            Color(0xFF16A34A),
          ],
          bandLabels: const ['Degraded', 'Watch', 'Healthy'],
          missingColor: const Color(0xFF64748B),
          label: 'Availability',
          unit: '%',
        ),
        showCellLabels: true,
        cellLabelFontSize: 10,
        gapFraction: .1,
        cornerRadius: 5,
        borderColor: Colors.black,
        borderWidth: 1,
        animation: _noMotion,
      ),
    );

    await _expectGolden(tester, 'goldens/heatmap_threshold_compact.png');
  });
}

const _noMotion = HeatmapAnimationStyle(
  entranceMode: HeatmapEntranceMode.none,
  animateDataUpdates: false,
);

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required List<String> xCategories,
  required List<String> yCategories,
  required HeatmapChartSeries series,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
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
                  title: series.name,
                  series: [series],
                  theme: theme,
                  showLegend: false,
                  grid: const GridConfig(horizontal: true, vertical: true),
                  xAxisConfig: XAxisConfig(
                    label: 'Column',
                    categoryAxis: CategoryAxisConfig(categories: xCategories),
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Row',
                    categoryAxis: CategoryAxisConfig(categories: yCategories),
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
