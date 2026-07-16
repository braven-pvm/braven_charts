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

    await _expectGolden(tester, 'goldens/pie_compact_dense.png');
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required PieChartSeries series,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
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
            child: SizedBox.fromSize(
              size: size,
              child: BravenChartPlus(
                title: 'Revenue contribution',
                subtitle: 'Share by product category',
                showLegend: false,
                theme: theme,
                series: [series],
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
  find.byKey(const ValueKey('pie-golden-surface')),
  matchesGoldenFile(path),
);

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
