import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('radial_bar_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('Radial Bar labels and callouts remain visually stable', (
    tester,
  ) async {
    final chartTheme = _goldenTheme(ChartTheme.light);
    await _pumpGolden(
      tester,
      key: const ValueKey('radial-bar-label-golden'),
      chartTheme: chartTheme,
      size: const Size(640, 500),
      chart: BravenChartPlus(
        showLegend: false,
        theme: chartTheme,
        series: [
          RadialBarChartSeries.fromMap(
            id: 'delivery',
            name: 'Delivery readiness',
            unit: '%',
            values: const {
              'Activation': 92,
              'Retention': 78,
              'Adoption': 66,
              'Satisfaction': 84,
              'Expansion': 57,
            },
            radialBarStyle: const RadialBarStyle(
              gradient: RadialBarGradientStyle(
                type: RadialBarGradientType.sweep,
              ),
              dataLabels: RadialBarDataLabelConfig(
                position: RadialBarDataLabelPosition.outsideCallout,
                content: RadialBarDataLabelContent.categoryAndValue,
                showPanel: true,
              ),
            ),
          ),
        ],
        radialBarChartConfig: const RadialBarChartConfig(
          showCategoryLabels: false,
          thresholds: [RadialBarThreshold(value: 75, label: 'Target')],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('radial-bar-label-golden')),
      matchesGoldenFile('goldens/radial_bar_labels.png'),
    );
  });

  testWidgets(
    'Radial Bar survives constrained high-contrast large-text layout',
    (tester) async {
      final chartTheme = _goldenTheme(ChartTheme.highContrast);
      await _pumpGolden(
        tester,
        key: const ValueKey('radial-bar-constrained-golden'),
        chartTheme: chartTheme,
        size: const Size(420, 360),
        textScaler: const TextScaler.linear(1.35),
        highContrast: true,
        chart: BravenChartPlus(
          showLegend: false,
          theme: chartTheme,
          series: [
            RadialBarChartSeries.fromMap(
              id: 'regions',
              unit: '%',
              values: const {
                'North': 91,
                'North-east': 83,
                'East': 72,
                'South-east': 64,
                'South': 58,
                'South-west': 47,
                'West': 39,
                'North-west': 31,
              },
              radialBarStyle: const RadialBarStyle(
                showDataLabels: false,
                borderWidth: 1,
              ),
            ),
          ],
          radialBarChartConfig: const RadialBarChartConfig(
            pane: PolarPaneConfig(
              startAngleDegrees: -35,
              sweepAngleDegrees: 285,
              innerRadiusFactor: 0.18,
              outerRadiusFactor: 0.78,
            ),
            categoryLabels: RadialBarCategoryLabelConfig(
              position: RadialBarCategoryLabelPosition.startGap,
              orientation: RadialBarCategoryLabelOrientation.followStartAngle,
              showPanel: true,
            ),
            tickCount: 4,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('radial-bar-constrained-golden')),
        matchesGoldenFile('goldens/radial_bar_constrained_high_contrast.png'),
      );
    },
  );
}

ChartTheme _goldenTheme(ChartTheme source) => source.copyWith(
  typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
  animationTheme: source.animationTheme.copyWith(
    dataUpdateDuration: Duration.zero,
    themeChangeDuration: Duration.zero,
    interactionDuration: Duration.zero,
  ),
);

Future<void> _pumpGolden(
  WidgetTester tester, {
  required ValueKey<String> key,
  required ChartTheme chartTheme,
  required Size size,
  required Widget chart,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  final materialTheme = highContrast
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: materialTheme.copyWith(
        textTheme: materialTheme.textTheme.apply(fontFamily: 'Ahem'),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          highContrast: highContrast,
          textScaler: textScaler,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: chartTheme.backgroundColor,
              child: SizedBox.fromSize(size: size, child: chart),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required this.precisionTolerance,
  });

  final double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await getGoldenBytes(golden);
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );
    return result.passed || result.diffPercent <= precisionTolerance;
  }
}
