import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.025;

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('concentric_donut_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('normal grouped concentric Donut', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(620, 520),
      showLegend: true,
      series: _standardRings(),
    );

    await _expectGolden(tester, 'goldens/concentric_donut_normal.png');
  });

  testWidgets('compact concentric Donut retains readable ring bands', (
    tester,
  ) async {
    await _pumpSurface(
      tester,
      size: const Size(300, 300),
      series: _standardRings(showLabels: true),
    );

    await _expectGolden(tester, 'goldens/concentric_donut_compact.png');
  });

  testWidgets('constrained selected chart fits gaps and paint overflow', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await _pumpSurface(
      tester,
      size: const Size(220, 220),
      controller: controller,
      config: const ConcentricDonutConfig(innerRadiusFactor: 0.25, ringGap: 24),
      series: [
        for (var index = 0; index < 4; index++)
          DonutChartSeries.fromMap(
            id: 'ring-$index',
            values: const {'Primary': 70, 'Context': 30},
            dataLabels: const PieDataLabelConfig(isVisible: false),
            donutStyle: const DonutChartStyle(
              selectionExplodeOffset: 14,
              selectedElevation: PieElevationStyle(
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(3, 4),
                opacity: 0.5,
              ),
              animationMode: PieAnimationMode.none,
            ),
          ),
      ],
    );
    final result = controller.selectPoint(
      const ChartPointRef(seriesId: 'ring-0', pointIndex: 0),
      revision: controller.effectiveDocumentRevision.value!,
    );
    expect(result, isA<ChartArtifactSuccess<void>>());
    await tester.pumpAndSettle();

    await _expectGolden(tester, 'goldens/concentric_donut_constrained.png');
  });

  testWidgets('lifted inner ring rises above the full composition', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    const selectionStyle = RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
      liftScale: 1.14,
      liftOffset: 7,
      backdropBlur: 1.5,
    );
    await _pumpSurface(
      tester,
      size: const Size(440, 400),
      controller: controller,
      series: [
        DonutChartSeries.fromMap(
          id: 'current',
          name: 'Current period',
          values: const {'Subscriptions': 50, 'Services': 30, 'Other': 20},
          selectionStyle: selectionStyle,
          dataLabels: const PieDataLabelConfig(
            isVisible: true,
            position: PieDataLabelPosition.inside,
            content: PieDataLabelContent.percentage,
          ),
        ),
        DonutChartSeries.fromMap(
          id: 'previous',
          name: 'Previous period',
          values: const {'Subscriptions': 45, 'Services': 35, 'Other': 20},
          selectionStyle: selectionStyle,
          dataLabels: const PieDataLabelConfig(
            isVisible: true,
            position: PieDataLabelPosition.inside,
            content: PieDataLabelContent.percentage,
          ),
        ),
      ],
    );
    final result = controller.selectPoint(
      const ChartPointRef(seriesId: 'previous', pointIndex: 0),
      revision: controller.effectiveDocumentRevision.value!,
    );
    expect(result, isA<ChartArtifactSuccess<void>>());
    await tester.pumpAndSettle();

    await _expectGolden(tester, 'goldens/concentric_donut_lifted_inner.png');
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required List<DonutChartSeries> series,
  BravenChartController? controller,
  bool showLegend = false,
  ConcentricDonutConfig config = const ConcentricDonutConfig(
    innerRadiusFactor: 0.28,
    ringGap: 6,
  ),
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  final base = ChartTheme.light;
  final chartTheme = base.copyWith(
    typographyTheme: base.typographyTheme.copyWith(fontFamily: 'Ahem'),
    animationTheme: base.animationTheme.copyWith(
      dataUpdateDuration: Duration.zero,
      themeChangeDuration: Duration.zero,
      interactionDuration: Duration.zero,
    ),
    pieChartTheme: const PieChartTheme(animationMode: PieAnimationMode.none),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Ahem'),
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('concentric-donut-golden-surface'),
            child: ColoredBox(
              color: chartTheme.backgroundColor,
              child: SizedBox.fromSize(
                size: size,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  title: showLegend ? 'Revenue mix by period' : null,
                  showLegend: showLegend,
                  concentricDonutConfig: config,
                  theme: chartTheme,
                  series: series,
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

Future<void> _expectGolden(WidgetTester tester, String path) => expectLater(
  find.byKey(const ValueKey('concentric-donut-golden-surface')),
  matchesGoldenFile(path),
);

List<DonutChartSeries> _standardRings({bool showLabels = false}) => [
  DonutChartSeries.fromMap(
    id: 'current',
    name: 'Current period',
    unit: 'USD',
    values: const {'Subscriptions': 50, 'Services': 30, 'Other': 20},
    dataLabels: PieDataLabelConfig(
      isVisible: showLabels,
      position: PieDataLabelPosition.inside,
      content: PieDataLabelContent.percentage,
      minimumShare: 0.18,
    ),
    donutStyle: const DonutChartStyle(animationMode: PieAnimationMode.none),
  ),
  DonutChartSeries.fromMap(
    id: 'previous',
    name: 'Previous period',
    unit: 'USD',
    values: const {'Subscriptions': 70, 'Services': 80, 'Other': 50},
    dataLabels: PieDataLabelConfig(
      isVisible: showLabels,
      position: PieDataLabelPosition.inside,
      content: PieDataLabelContent.percentage,
      minimumShare: 0.18,
    ),
    donutStyle: const DonutChartStyle(animationMode: PieAnimationMode.none),
  ),
];

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
