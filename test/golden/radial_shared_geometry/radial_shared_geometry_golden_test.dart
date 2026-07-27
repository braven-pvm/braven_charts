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
      local.basedir.resolve('radial_shared_geometry_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('shared annular geometry remains stable across radial families', (
    tester,
  ) async {
    final chartTheme = _goldenTheme(ChartTheme.light);

    await _pumpMatrix(
      tester,
      key: const ValueKey('radial-shared-geometry-golden-surface'),
      chartTheme: chartTheme,
      charts: [
        (label: 'Pie · outer corners', chart: _pieChart(chartTheme)),
        (label: 'Donut · parallel gaps', chart: _donutChart(chartTheme)),
        (
          label: 'Concentric · shared rings',
          chart: _concentricChart(chartTheme),
        ),
        (label: 'Polar · stack exterior', chart: _polarChart(chartTheme)),
      ],
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('radial-shared-geometry-golden-surface')),
      matchesGoldenFile('goldens/radial_shared_geometry_matrix.png'),
    );
  });

  testWidgets('selected radial marks keep depth and paint order', (
    tester,
  ) async {
    final controllers = List.generate(4, (_) => BravenChartController());
    for (final controller in controllers) {
      addTearDown(controller.dispose);
    }
    final chartTheme = _goldenTheme(ChartTheme.dark);

    await _pumpMatrix(
      tester,
      key: const ValueKey('radial-selected-depth-golden-surface'),
      chartTheme: chartTheme,
      materialTheme: ThemeData.dark(useMaterial3: true),
      charts: [
        (
          label: 'Pie · lifted slice',
          chart: _selectedPieChart(chartTheme, controllers[0]),
        ),
        (
          label: 'Donut · lifted arc',
          chart: _selectedDonutChart(chartTheme, controllers[1]),
        ),
        (
          label: 'Concentric · inner ring lifted',
          chart: _selectedConcentricChart(chartTheme, controllers[2]),
        ),
        (
          label: 'Polar · inner stack above cap',
          chart: _selectedPolarChart(chartTheme, controllers[3]),
        ),
      ],
    );

    for (final selection in [
      (controller: controllers[0], seriesId: 'pie', pointIndex: 0),
      (controller: controllers[1], seriesId: 'donut', pointIndex: 1),
      (controller: controllers[2], seriesId: 'inner', pointIndex: 0),
      (controller: controllers[3], seriesId: 'base', pointIndex: 0),
    ]) {
      final result = selection.controller.selectPoint(
        ChartPointRef(
          seriesId: selection.seriesId,
          pointIndex: selection.pointIndex,
        ),
        revision: selection.controller.effectiveDocumentRevision.value!,
      );
      expect(result, isA<ChartArtifactSuccess<void>>());
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('radial-selected-depth-golden-surface')),
      matchesGoldenFile('goldens/radial_shared_geometry_selected.png'),
    );
  });

  testWidgets('partial sweeps survive constrained high-contrast layout', (
    tester,
  ) async {
    final chartTheme = _goldenTheme(ChartTheme.highContrast);

    await _pumpMatrix(
      tester,
      key: const ValueKey('radial-constrained-golden-surface'),
      chartTheme: chartTheme,
      size: const Size(600, 520),
      textScaler: const TextScaler.linear(1.35),
      highContrast: true,
      charts: [
        (label: 'Pie · large text', chart: _constrainedPieChart(chartTheme)),
        (
          label: 'Donut · 220° counter-clockwise',
          chart: _constrainedDonutChart(chartTheme),
        ),
        (
          label: 'Concentric · compact three rings',
          chart: _constrainedConcentricChart(chartTheme),
        ),
        (
          label: 'Polar · 110° grid at 40°',
          chart: _constrainedPolarChart(chartTheme),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('radial-constrained-golden-surface')),
      matchesGoldenFile(
        'goldens/radial_shared_geometry_constrained_high_contrast.png',
      ),
    );
  });
}

ChartTheme _goldenTheme(ChartTheme source) => source.copyWith(
  typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
  animationTheme: source.animationTheme.copyWith(
    dataUpdateDuration: Duration.zero,
    themeChangeDuration: Duration.zero,
    interactionDuration: Duration.zero,
  ),
  pieChartTheme: source.pieChartTheme.copyWith(
    animationMode: PieAnimationMode.none,
  ),
);

Future<void> _pumpMatrix(
  WidgetTester tester, {
  required ValueKey<String> key,
  required ChartTheme chartTheme,
  required List<({String label, Widget chart})> charts,
  ThemeData? materialTheme,
  Size size = const Size(720, 640),
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
}) async {
  assert(charts.length == 4);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  final baseMaterialTheme =
      materialTheme ?? ThemeData.light(useMaterial3: true);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: baseMaterialTheme.copyWith(
        textTheme: baseMaterialTheme.textTheme.apply(fontFamily: 'Ahem'),
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
              child: SizedBox.fromSize(
                size: size,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _FamilyTile(
                                label: charts[0].label,
                                chart: charts[0].chart,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FamilyTile(
                                label: charts[1].label,
                                chart: charts[1].chart,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _FamilyTile(
                                label: charts[2].label,
                                chart: charts[2].chart,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FamilyTile(
                                label: charts[3].label,
                                chart: charts[3].chart,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
}

class _FamilyTile extends StatelessWidget {
  const _FamilyTile({required this.label, required this.chart});

  final String label;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }
}

Widget _pieChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  series: [
    PieChartSeries.fromMap(
      id: 'pie',
      values: const {'North': 42, 'East': 28, 'South': 18, 'West': 12},
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.inside,
        content: PieDataLabelContent.percentage,
        minimumShare: 0.1,
      ),
      pieStyle: const PieChartStyle(
        startAngleDegrees: 40,
        radiusFactor: 0.78,
        sliceGap: 6,
        cornerRadius: 12,
        cornerTreatment: PieCornerTreatment.outerOnly,
        animationMode: PieAnimationMode.none,
      ),
    ),
  ],
);

Widget _donutChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  series: [
    DonutChartSeries.fromMap(
      id: 'donut',
      values: const {'North': 42, 'East': 28, 'South': 18, 'West': 12},
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.48,
        sweepAngleDegrees: 300,
        startAngleDegrees: 40,
        radiusFactor: 0.8,
        sliceGap: 8,
        cornerRadius: 10,
        cornerTreatment: PieCornerTreatment.roundAll,
        animationMode: PieAnimationMode.none,
      ),
    ),
  ],
);

Widget _concentricChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.24,
    ringGap: 6,
  ),
  series: [
    for (final ring in const [
      ('current', {'North': 45.0, 'East': 35.0, 'South': 20.0}),
      ('previous', {'North': 38.0, 'East': 32.0, 'South': 30.0}),
      ('baseline', {'North': 30.0, 'East': 28.0, 'South': 42.0}),
    ])
      DonutChartSeries.fromMap(
        id: ring.$1,
        values: ring.$2,
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          startAngleDegrees: 40,
          sliceGap: 6,
          cornerRadius: 8,
          cornerTreatment: PieCornerTreatment.roundAll,
          animationMode: PieAnimationMode.none,
        ),
      ),
  ],
);

Widget _polarChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: 40,
      innerRadiusFactor: 0.2,
      outerRadiusFactor: 0.8,
    ),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.stacked,
    ),
    angularAxis: PolarCategoryAxisConfig(showLabels: false),
    radialAxis: PolarNumericAxisConfig(showLabels: false),
  ),
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'base',
      values: const {'North': 24, 'East': 31, 'South': 28, 'West': 36},
      polarStyle: const PolarColumnStyle(
        cornerRadius: 10,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
        showDataLabels: false,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'cap',
      values: const {'North': 12, 'East': 18, 'South': 10, 'West': 15},
      polarStyle: const PolarColumnStyle(
        cornerRadius: 10,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
        showDataLabels: false,
      ),
    ),
  ],
);

const _liftSelection = RadialSelectionStyle(
  effect: RadialSelectionEffect.lift,
  liftScale: 1.12,
  liftOffset: 7,
  backdropBlur: 1.5,
);

const _selectionGoldenInteraction = InteractionConfig(
  tooltip: TooltipConfig(enabled: false),
);

Widget _selectedPieChart(ChartTheme theme, BravenChartController controller) =>
    BravenChartPlus(
      bravenChartController: controller,
      theme: theme,
      showLegend: false,
      interactionConfig: _selectionGoldenInteraction,
      series: [
        PieChartSeries.fromMap(
          id: 'pie',
          values: const {'North': 42, 'East': 28, 'South': 18, 'West': 12},
          selectionStyle: _liftSelection,
          dataLabels: const PieDataLabelConfig(isVisible: false),
          pieStyle: const PieChartStyle(
            startAngleDegrees: 40,
            radiusFactor: 0.7,
            sliceGap: 5,
            cornerRadius: 10,
            cornerTreatment: PieCornerTreatment.outerOnly,
            animationMode: PieAnimationMode.none,
          ),
        ),
      ],
    );

Widget _selectedDonutChart(
  ChartTheme theme,
  BravenChartController controller,
) => BravenChartPlus(
  bravenChartController: controller,
  theme: theme,
  showLegend: false,
  interactionConfig: _selectionGoldenInteraction,
  series: [
    DonutChartSeries.fromMap(
      id: 'donut',
      values: const {'North': 42, 'East': 28, 'South': 18, 'West': 12},
      selectionStyle: _liftSelection,
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.5,
        sweepAngleDegrees: 300,
        startAngleDegrees: 40,
        radiusFactor: 0.72,
        sliceGap: 7,
        cornerRadius: 9,
        animationMode: PieAnimationMode.none,
      ),
    ),
  ],
);

Widget _selectedConcentricChart(
  ChartTheme theme,
  BravenChartController controller,
) => BravenChartPlus(
  bravenChartController: controller,
  theme: theme,
  showLegend: false,
  interactionConfig: _selectionGoldenInteraction,
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.24,
    ringGap: 7,
  ),
  series: [
    for (final ring in const [
      ('outer', {'North': 45.0, 'East': 35.0, 'South': 20.0}),
      ('middle', {'North': 38.0, 'East': 32.0, 'South': 30.0}),
      ('inner', {'North': 30.0, 'East': 28.0, 'South': 42.0}),
    ])
      DonutChartSeries.fromMap(
        id: ring.$1,
        values: ring.$2,
        selectionStyle: _liftSelection,
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          startAngleDegrees: 40,
          radiusFactor: 0.76,
          sliceGap: 5,
          cornerRadius: 7,
          animationMode: PieAnimationMode.none,
        ),
      ),
  ],
);

Widget _selectedPolarChart(
  ChartTheme theme,
  BravenChartController controller,
) => BravenChartPlus(
  bravenChartController: controller,
  theme: theme,
  showLegend: false,
  interactionConfig: _selectionGoldenInteraction,
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: 40,
      innerRadiusFactor: 0.2,
      outerRadiusFactor: 0.74,
    ),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.stacked,
    ),
    angularAxis: PolarCategoryAxisConfig(showLabels: false),
    radialAxis: PolarNumericAxisConfig(showLabels: false),
  ),
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'base',
      values: const {'North': 24, 'East': 31, 'South': 28, 'West': 36},
      selectionStyle: _liftSelection,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 10,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
        showDataLabels: false,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'cap',
      values: const {'North': 12, 'East': 18, 'South': 10, 'West': 15},
      selectionStyle: _liftSelection,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 10,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
        showDataLabels: false,
      ),
    ),
  ],
);

Widget _constrainedPieChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  series: [
    PieChartSeries.fromMap(
      id: 'pie-constrained',
      values: const {'North': 58, 'East': 24, 'South': 18},
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.outside,
        content: PieDataLabelContent.category,
        outsideOffset: 0,
        connectorLength: 8,
      ),
      pieStyle: const PieChartStyle(
        startAngleDegrees: 40,
        radiusFactor: 0.64,
        sliceGap: 4,
        cornerRadius: 8,
        cornerTreatment: PieCornerTreatment.outerOnly,
        animationMode: PieAnimationMode.none,
      ),
    ),
  ],
);

Widget _constrainedDonutChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  series: [
    DonutChartSeries.fromMap(
      id: 'donut-constrained',
      values: const {'North': 52, 'East': 31, 'South': 17},
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.5,
        sweepAngleDegrees: 220,
        startAngleDegrees: 40,
        clockwise: false,
        radiusFactor: 0.74,
        sliceGap: 7,
        cornerRadius: 8,
        animationMode: PieAnimationMode.none,
      ),
    ),
  ],
);

Widget _constrainedConcentricChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.2,
    ringGap: 4,
  ),
  series: [
    for (final ring in const [
      ('outer', {'North': 52.0, 'East': 31.0, 'South': 17.0}),
      ('middle', {'North': 44.0, 'East': 34.0, 'South': 22.0}),
      ('inner', {'North': 36.0, 'East': 29.0, 'South': 35.0}),
    ])
      DonutChartSeries.fromMap(
        id: ring.$1,
        values: ring.$2,
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          startAngleDegrees: 40,
          radiusFactor: 0.74,
          sliceGap: 4,
          cornerRadius: 6,
          animationMode: PieAnimationMode.none,
        ),
      ),
  ],
);

Widget _constrainedPolarChart(ChartTheme theme) => BravenChartPlus(
  theme: theme,
  showLegend: false,
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: 40,
      sweepAngleDegrees: 110,
      clockwise: false,
      innerRadiusFactor: 0.18,
      outerRadiusFactor: 0.74,
    ),
    angularAxis: PolarCategoryAxisConfig(showLabels: false),
    radialAxis: PolarNumericAxisConfig(showLabels: false, tickCount: 5),
  ),
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'polar-constrained',
      values: const {
        'North': 24,
        'North East': 31,
        'East': 28,
        'South East': 36,
        'South': 22,
      },
      polarStyle: const PolarColumnStyle(
        cornerRadius: 6,
        cornerRadiusMode: PolarColumnCornerRadiusMode.bothEnds,
        showDataLabels: false,
      ),
    ),
  ],
);

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
