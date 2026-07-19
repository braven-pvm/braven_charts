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
      local.basedir.resolve('polar_column_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('normal linear Polar Column', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(560, 420),
      theme: _goldenTheme(ChartTheme.light),
      series: _standardSeries(),
    );

    await _expectGolden(tester, 'goldens/polar_normal_linear.png');
  });

  testWidgets('compact dense Rose thins angular labels', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(300, 280),
      theme: _goldenTheme(ChartTheme.dark),
      series: PolarColumnChartSeries.rose(
        id: 'dense-rose',
        unit: 'events',
        values: {
          for (var index = 0; index < 16; index++)
            'Sector ${index + 1}': 18 + ((index * 13) % 37),
        },
        polarStyle: const PolarColumnStyle(
          cornerRadius: 5,
          borderWidth: 0.75,
          showDataLabels: true,
        ),
      ),
      title: null,
      subtitle: null,
    );

    await _expectGolden(tester, 'goldens/polar_compact_dense_rose.png');
  });

  testWidgets('constrained partial sweep remains bounded', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(240, 220),
      theme: _goldenTheme(ChartTheme.light),
      series: _standardSeries(
        style: const PolarColumnStyle(
          cornerRadius: 7,
          borderWidth: 1,
          showDataLabels: true,
        ),
      ),
      config: const PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -210,
          sweepAngleDegrees: 240,
          innerRadiusFactor: 0.28,
          outerRadiusFactor: 0.88,
        ),
        radialAxis: PolarNumericAxisConfig(tickCount: 4),
      ),
      title: null,
      subtitle: null,
    );

    await _expectGolden(tester, 'goldens/polar_constrained_partial.png');
  });

  testWidgets('high contrast Polar Column supports large text', (tester) async {
    await _pumpSurface(
      tester,
      size: const Size(600, 440),
      theme: _goldenTheme(ChartTheme.highContrast),
      textScaler: const TextScaler.linear(1.5),
      highContrast: true,
      series: _standardSeries(
        style: const PolarColumnStyle(
          cornerRadius: 4,
          borderWidth: 2,
          showDataLabels: true,
        ),
      ),
      title: 'Accessible channel demand',
      subtitle: 'Large text and strong boundaries',
    );

    await _expectGolden(tester, 'goldens/polar_high_contrast_large_text.png');
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required PolarColumnChartSeries series,
  PolarChartConfig config = const PolarChartConfig(),
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
  String? title = 'Channel demand',
  String? subtitle = 'Magnitude by acquisition source',
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _materialTheme(theme.backgroundColor.computeLuminance() < 0.5),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScaler,
          highContrast: highContrast,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('polar-column-golden-surface'),
            child: ColoredBox(
              color: theme.backgroundColor,
              child: SizedBox.fromSize(
                size: size,
                child: BravenChartPlus(
                  title: title,
                  subtitle: subtitle,
                  theme: theme,
                  polarChartConfig: config,
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

Future<void> _expectGolden(WidgetTester tester, String path) async {
  await expectLater(
    find.byKey(const ValueKey('polar-column-golden-surface')),
    matchesGoldenFile(path),
  );
}

PolarColumnChartSeries _standardSeries({
  PolarColumnStyle style = const PolarColumnStyle(),
}) => PolarColumnChartSeries.fromMap(
  id: 'demand',
  unit: 'requests',
  values: const {
    'Search': 72,
    'Social': 41,
    'Partners': 58,
    'Email': 29,
    'Events': 47,
    'Referrals': 63,
  },
  polarStyle: style,
);

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
