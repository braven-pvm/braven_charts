import 'dart:io';
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;

void main() {
  late GoldenFileComparator previousComparator;

  setUpAll(_loadRoboto);

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('gauge_chart_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('public Gauge family pair', (tester) async {
    const size = Size(1944, 540);
    await _pumpSurface(
      tester,
      key: const ValueKey('gauge-family-pair'),
      size: size,
      child: Row(
        children: [
          Expanded(
            child: _GaugeTile(
              title: 'Operational load',
              subtitle: 'Needle · zones · target',
              series: _needleSeries(),
              config: _standardConfig,
              chartTheme: ChartTheme.light,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: _GaugeTile(
              title: 'Service availability',
              subtitle: 'Solid · precise domain · SLO',
              series: _solidSeries(),
              config: _standardConfig,
              chartTheme: ChartTheme.light,
            ),
          ),
        ],
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('gauge-family-pair')),
      matchesGoldenFile('../../../doc/screenshots/family_gauge_pair.png'),
    );
  });

  testWidgets('public Gauge chart type image', (tester) async {
    const size = Size(960, 540);
    await _pumpSurface(
      tester,
      key: const ValueKey('gauge-chart-type'),
      size: size,
      child: _GaugeTile(
        title: 'Operational load',
        subtitle: 'One measurement, explicit range, visible status',
        series: _needleSeries(),
        config: _standardConfig,
        chartTheme: ChartTheme.light,
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('gauge-chart-type')),
      matchesGoldenFile('../../../doc/screenshots/chart_type_gauge.png'),
    );
  });

  testWidgets('high contrast and large text remain bounded', (tester) async {
    const size = Size(520, 420);
    await _pumpSurface(
      tester,
      key: const ValueKey('gauge-high-contrast'),
      size: size,
      theme: ChartTheme.highContrast,
      highContrast: true,
      textScaler: const TextScaler.linear(1.35),
      child: _GaugeTile(
        title: 'Response latency',
        subtitle: 'High contrast · 135% text',
        series: _needleSeries(),
        config: _standardConfig,
        chartTheme: ChartTheme.highContrast,
        showLegend: false,
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('gauge-high-contrast')),
      matchesGoldenFile('goldens/gauge_high_contrast_large_text.png'),
    );
  });

  testWidgets('zero offset labels, ticks, and references remain aligned', (
    tester,
  ) async {
    const size = Size(720, 520);
    await _pumpSurface(
      tester,
      key: const ValueKey('gauge-zero-offset-labels'),
      size: size,
      child: _GaugeTile(
        title: 'Service availability',
        subtitle: '20 px scale labels · zero edge gap · adjacent references',
        series: _zeroOffsetSolidSeries(),
        config: const GaugeChartConfig(
          tickCount: 6,
          pane: PolarPaneConfig(
            startAngleDegrees: -150,
            sweepAngleDegrees: 300,
            innerRadiusFactor: 0.56,
            outerRadiusFactor: 0.86,
          ),
          scale: GaugeScaleStyle(
            tickWidth: 4,
            tickLength: 16,
            labelStyle: PolarLabelStyle(fontSize: 20),
            labelOffset: 0,
          ),
          references: GaugeReferenceStyle(
            outerLineOffset: 12,
            labelOffset: 0,
            showLabelPanel: true,
          ),
          center: GaugeCenterConfig(showTarget: true),
        ),
        chartTheme: ChartTheme.light,
        showLegend: false,
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('gauge-zero-offset-labels')),
      matchesGoldenFile('goldens/gauge_zero_offset_labels.png'),
    );
  });
}

const _standardConfig = GaugeChartConfig(
  tickCount: 6,
  center: GaugeCenterConfig(showTarget: true),
);

GaugeChartSeries _needleSeries() => GaugeChartSeries.needle(
  id: 'load',
  metric: 'CPU utilization',
  unit: '%',
  value: 72,
  minimum: 0,
  maximum: 100,
  target: const GaugeTarget(value: 70, label: 'Target'),
  zones: const [
    GaugeZone(from: 0, to: 60, status: 'Healthy', color: Color(0xFF16A34A)),
    GaugeZone(from: 60, to: 85, status: 'Elevated', color: Color(0xFFF59E0B)),
    GaugeZone(from: 85, to: 100, status: 'Critical', color: Color(0xFFDC2626)),
  ],
  style: const NeedleGaugeStyle(
    needleColor: Color(0xFF1D4ED8),
    pivotColor: Color(0xFF1D4ED8),
  ),
);

GaugeChartSeries _solidSeries() => GaugeChartSeries.solid(
  id: 'availability',
  metric: 'Availability',
  unit: '%',
  value: 99.94,
  minimum: 99,
  maximum: 100,
  target: const GaugeTarget(value: 99.9, label: 'SLO'),
  zones: const [
    GaugeZone(from: 99, to: 99.9, status: 'At risk', color: Color(0xFFF97316)),
    GaugeZone(from: 99.9, to: 100, status: 'Healthy', color: Color(0xFF0F9D7A)),
  ],
  style: const SolidGaugeStyle(
    cornerRadius: 10,
    borderColor: Color(0xFF334155),
    borderWidth: 1,
  ),
);

GaugeChartSeries _zeroOffsetSolidSeries() => GaugeChartSeries.solid(
  id: 'availability-zero-offset',
  metric: 'Service availability',
  unit: '%',
  value: 99.94,
  minimum: 99,
  maximum: 100,
  target: const GaugeTarget(value: 99.9, label: 'SLO'),
  thresholds: const [
    GaugeThreshold(value: 99.8, label: 'Alert', color: Color(0xFFDC2626)),
  ],
  zones: const [
    GaugeZone(from: 99, to: 99.8, status: 'Critical', color: Color(0xFFDC2626)),
    GaugeZone(from: 99.8, to: 99.9, status: 'Alert', color: Color(0xFFF59E0B)),
    GaugeZone(from: 99.9, to: 100, status: 'Healthy', color: Color(0xFF16A34A)),
  ],
  style: const SolidGaugeStyle(
    cornerRadius: 12,
    borderColor: Color(0xFF334155),
    borderWidth: 1,
  ),
);

class _GaugeTile extends StatelessWidget {
  const _GaugeTile({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.config,
    required this.chartTheme,
    this.showLegend = true,
  });

  final String title;
  final String subtitle;
  final GaugeChartSeries series;
  final GaugeChartConfig config;
  final ChartTheme chartTheme;
  final bool showLegend;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Expanded(
            child: BravenChartPlus(
              theme: chartTheme,
              series: [series],
              gaugeChartConfig: config,
              showLegend: showLegend,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required ValueKey<String> key,
  required Size size,
  required Widget child,
  ChartTheme? theme,
  bool highContrast = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: highContrast
            ? const ColorScheme.highContrastLight()
            : ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
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
        backgroundColor: (theme ?? ChartTheme.light).backgroundColor,
        body: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: (theme ?? ChartTheme.light).backgroundColor,
            child: SizedBox.fromSize(
              size: size,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _loadRoboto() async {
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot = configuredRoot == null
      ? File(Platform.resolvedExecutable).parent.parent.parent.parent.path
      : configuredRoot;
  final font = File(
    '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
    'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'material_fonts${Platform.pathSeparator}Roboto-Regular.ttf',
  );
  final bytes = await font.readAsBytes();
  await (FontLoader(
    'Roboto',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    Uri testFile, {
    required this.precisionTolerance,
  }) : super(testFile);

  final double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await getGoldenBytes(golden);
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );
    if (result.passed || result.diffPercent <= precisionTolerance) return true;
    throw FlutterError(
      'Gauge golden ${golden.path} differed by '
      '${(result.diffPercent * 100).toStringAsFixed(2)}%.',
    );
  }
}
