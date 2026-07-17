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
      local.basedir.resolve('pie_chart_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('light pie with outside labels', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(560, 380),
      theme: _goldenTheme(ChartTheme.light),
      series: _standardSeries(),
    );

    await _expectGolden(tester, 'goldens/pie_light_outside.png');
  });

  testWidgets('dark pie with inside labels', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(460, 340),
      theme: _goldenTheme(ChartTheme.dark),
      series: _standardSeries(
        labels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.08,
        ),
      ),
    );

    await _expectGolden(tester, 'goldens/pie_dark_inside.png');
  });

  testWidgets('high contrast pie with large text', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(600, 420),
      theme: _goldenTheme(ChartTheme.highContrast),
      textScaler: const TextScaler.linear(1.5),
      highContrast: true,
      series: _standardSeries(
        labels: const PieDataLabelConfig(
          content: PieDataLabelContent.categoryValueAndPercentage,
          minimumShare: 0.08,
        ),
      ),
    );

    await _expectGolden(tester, 'goldens/pie_high_contrast_large_text.png');
  });

  testWidgets('compact dense pie resolves outside label collisions', (
    tester,
  ) async {
    await _pumpSurface(
      tester,
      size: const Size(300, 260),
      theme: _goldenTheme(ChartTheme.light),
      series: PieChartSeries.fromMap(
        id: 'dense',
        values: const {
          'Subscriptions': 24,
          'Services': 19,
          'Hardware': 15,
          'Licensing': 12,
          'Support': 10,
          'Training': 8,
          'Consulting': 7,
          'Other': 5,
        },
        dataLabels: const PieDataLabelConfig(
          minimumShare: 0,
          minimumSweepDegrees: 0,
        ),
      ),
    );

    await _expectGolden(
      tester,
      'goldens/pie_compact_dense.png',
      precisionTolerance: 0.04,
    );
  });

  testWidgets('selected pie and native slice legend', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(600, 520),
      theme: _goldenTheme(ChartTheme.light),
      series: _standardSeries(),
      showLegend: true,
    );

    await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
    await tester.pumpAndSettle();
    await _expectGolden(tester, 'goldens/pie_selected_legend.png');
  });

  testWidgets('advanced Pie styling and right-side legend', (tester) async {
    final base = ChartTheme.light;
    final theme = _goldenTheme(
      base.copyWith(
        seriesTheme: base.seriesTheme.copyWith(
          colors: const [
            Color(0xFF006D77),
            Color(0xFF0A9396),
            Color(0xFF48CAE4),
            Color(0xFF023E8A),
          ],
        ),
        legendStyle: base.legendStyle.copyWith(
          position: LegendPosition.centerRight,
          orientation: LegendOrientation.vertical,
          markerShape: LegendMarkerShape.circle,
        ),
        pieChartTheme: const PieChartTheme(
          opacity: 0.88,
          cornerRadius: 12,
          shadow: PieElevationStyle(
            color: Color(0x401A1A1A),
            blurRadius: 8,
            offset: Offset(0, 4),
            opacity: 0.7,
          ),
          selectedElevation: PieElevationStyle(
            blurRadius: 12,
            spreadRadius: 2,
            opacity: 0.5,
          ),
          calloutStyle: LabelStyle(
            textStyle: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Color(0xF2FFFFFF),
            borderColor: Color(0xFF94A3B8),
            borderWidth: 1,
            borderRadius: 8,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shadowColor: Color(0x331A1A1A),
            shadowBlurRadius: 5,
          ),
          animationMode: PieAnimationMode.none,
        ),
      ),
    );
    await _pumpSurface(
      tester,
      size: const Size(680, 430),
      theme: theme,
      showLegend: true,
      series: _standardSeries().copyWith(
        pieStyle: const PieChartStyle(
          sliceGap: 8,
          selectionExplodeOffset: 12,
          gradient: PieGradientStyle(
            type: PieGradientType.radial,
            startLightnessShift: 0.2,
            endLightnessShift: -0.12,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
    await tester.pumpAndSettle();
    await _expectGolden(tester, 'goldens/pie_advanced_styling.png');
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required PieChartSeries series,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
  bool showLegend = false,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _materialTheme(theme.backgroundColor.computeLuminance() < 0.5),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: textScaler, highContrast: highContrast),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('pie-golden-surface'),
            child: ColoredBox(
              color: theme.backgroundColor,
              child: SizedBox.fromSize(
                size: size,
                child: BravenChartPlus(
                  title: 'Revenue contribution',
                  subtitle: 'Share by product category',
                  showLegend: showLegend,
                  theme: theme,
                  series: [series],
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

Future<void> _expectGolden(
  WidgetTester tester,
  String path, {
  double? precisionTolerance,
}) async {
  final comparator = goldenFileComparator;
  if (precisionTolerance == null ||
      comparator is! _TolerantGoldenFileComparator) {
    await expectLater(
      find.byKey(const ValueKey('pie-golden-surface')),
      matchesGoldenFile(path),
    );
    return;
  }

  final previousTolerance = comparator.precisionTolerance;
  comparator.precisionTolerance = precisionTolerance;
  try {
    await expectLater(
      find.byKey(const ValueKey('pie-golden-surface')),
      matchesGoldenFile(path),
    );
  } finally {
    comparator.precisionTolerance = previousTolerance;
  }
}

PieChartSeries _standardSeries({
  PieDataLabelConfig labels = const PieDataLabelConfig(),
}) {
  return PieChartSeries.fromMap(
    id: 'revenue',
    unit: 'USD',
    values: const {
      'Subscriptions': 42,
      'Services': 31,
      'Hardware': 17,
      'Training': 10,
    },
    sliceColors: const {'Training': Color(0xFFEC4899)},
    dataLabels: labels,
  );
}

ChartTheme _goldenTheme(ChartTheme source) {
  return source.copyWith(
    typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
    animationTheme: source.animationTheme.copyWith(
      dataUpdateDuration: Duration.zero,
      themeChangeDuration: Duration.zero,
      interactionDuration: Duration.zero,
    ),
  );
}

ThemeData _materialTheme(bool dark) {
  final source = dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return source.copyWith(textTheme: source.textTheme.apply(fontFamily: 'Ahem'));
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : precisionTolerance = precisionTolerance;

  double precisionTolerance;

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
