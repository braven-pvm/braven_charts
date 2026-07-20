import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.035;
const _surfaceKey = ValueKey('candlestick-golden-surface');
const _noCandleAnimation = CandlestickAnimationStyle(
  mode: CandlestickAnimationMode.none,
  dataUpdateMode: CandlestickDataUpdateAnimationMode.none,
);

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('candlestick_chart_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('light financial candle surface', (tester) async {
    await _pumpChart(
      tester,
      size: const Size(640, 420),
      theme: _goldenTheme(ChartTheme.light),
      candles: _standardCandles(),
    );

    await _expectGolden(tester, 'goldens/candlestick_light.png');
  });

  testWidgets('dark financial candle surface', (tester) async {
    await _pumpChart(
      tester,
      size: const Size(640, 420),
      theme: _goldenTheme(ChartTheme.dark),
      candles: _standardCandles(),
      style: const CandlestickChartStyle(
        bodyFillMode: CandlestickBodyFillMode.filled,
        bodyCornerRadius: 2,
      ),
    );

    await _expectGolden(tester, 'goldens/candlestick_dark.png');
  });

  testWidgets('doji bodies remain visible and directional', (tester) async {
    await _pumpChart(
      tester,
      size: const Size(640, 360),
      theme: _goldenTheme(ChartTheme.light),
      candles: _dojiCandles(),
      style: const CandlestickChartStyle(
        bodyFillMode: CandlestickBodyFillMode.filled,
        minimumBodyHeight: 2,
        bodyBorderWidth: 1.5,
        wickWidth: 1.5,
      ),
    );

    await _expectGolden(tester, 'goldens/candlestick_doji.png');
  });

  testWidgets('irregular elapsed-time gaps remain proportional', (
    tester,
  ) async {
    await _pumpChart(
      tester,
      size: const Size(640, 380),
      theme: _goldenTheme(ChartTheme.light),
      candles: _irregularCandles(ordinal: false),
      xAxisLabel: 'Elapsed day',
      xFormatter: (value) => 'D${value.round()}',
    );

    await _expectGolden(tester, 'goldens/candlestick_irregular_gaps.png');
  });

  testWidgets('ordinal sessions collapse non-trading gaps', (tester) async {
    await _pumpChart(
      tester,
      size: const Size(640, 380),
      theme: _goldenTheme(ChartTheme.light),
      candles: _irregularCandles(ordinal: true),
      xAxisLabel: 'Trading session',
      xFormatter: (value) => 'S${value.round() + 1}',
    );

    await _expectGolden(tester, 'goldens/candlestick_ordinal_sessions.png');
  });

  testWidgets('compact stock composition keeps three readable panes', (
    tester,
  ) async {
    await _pumpComposition(tester);

    await _expectGolden(tester, 'goldens/candlestick_compact_stock.png');
  });

  testWidgets('grouped density preserves OHLC envelope', (tester) async {
    await _pumpChart(
      tester,
      size: const Size(640, 380),
      theme: _goldenTheme(ChartTheme.dark),
      candles: _denseCandles(),
      densityGrouping: const CandlestickDensityGrouping(
        enabled: true,
        targetGroupWidth: 8,
        minimumPointsPerGroup: 2,
      ),
      style: const CandlestickChartStyle(
        bodyFillMode: CandlestickBodyFillMode.filled,
        bodyWidthFactor: .8,
        maxBodyWidth: 10,
      ),
      xAxisLabel: 'Sample',
      xFormatter: (value) => value.round().toString(),
    );

    await _expectGolden(tester, 'goldens/candlestick_grouped_density.png');
  });
}

Future<void> _pumpChart(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required List<CandlestickDataPoint> candles,
  CandlestickChartStyle style = const CandlestickChartStyle(),
  CandlestickDensityGrouping densityGrouping =
      const CandlestickDensityGrouping(),
  String xAxisLabel = 'Session',
  String Function(double)? xFormatter,
}) async {
  await _pumpSurface(
    tester,
    size: size,
    theme: theme,
    child: BravenChartPlus(
      series: [
        CandlestickChartSeries(
          id: 'price',
          name: 'Price',
          unit: 'USD',
          points: candles,
          candlestickStyle: style,
          densityGrouping: densityGrouping,
          animation: _noCandleAnimation,
        ),
      ],
      theme: theme,
      showLegend: false,
      grid: const GridConfig(horizontal: true, vertical: true),
      xAxisConfig: XAxisConfig(
        label: xAxisLabel,
        tickCount: 7,
        labelFormatter: xFormatter,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.right,
        label: 'Price',
        unit: 'USD',
      ),
    ),
  );
}

Future<void> _pumpComposition(WidgetTester tester) async {
  final theme = _goldenTheme(ChartTheme.light);
  final candles = _standardCandles(count: 22);
  final closePoints = [
    for (final candle in candles) ChartDataPoint(x: candle.x, y: candle.close),
  ];
  await _pumpSurface(
    tester,
    size: const Size(440, 560),
    theme: theme,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CompositionHeader(),
        Expanded(
          flex: 5,
          child: BravenChartPlus(
            series: [
              CandlestickChartSeries(
                id: 'price',
                points: candles,
                animation: _noCandleAnimation,
              ),
              LineChartSeries(
                id: 'average',
                points: _movingAverage(candles, 5),
                color: const Color(0xFF4F46E5),
                strokeWidth: 1.5,
                interpolation: LineInterpolation.monotone,
              ),
            ],
            theme: theme,
            showLegend: false,
            grid: const GridConfig(horizontal: true, vertical: false),
            xAxisConfig: const XAxisConfig(showTickLabels: false, tickCount: 5),
            yAxis: YAxisConfig(position: YAxisPosition.right, tickCount: 4),
          ),
        ),
        SizedBox(
          height: 120,
          child: BravenChartPlus(
            series: [
              BarChartSeries(
                id: 'volume',
                isXOrdered: true,
                barWidthPercent: .72,
                points: [
                  for (var index = 0; index < candles.length; index++)
                    ChartDataPoint(
                      x: candles[index].x,
                      y: 25 + (index * 17) % 70,
                      pointStyle: PointStyle(
                        color:
                            candles[index].direction ==
                                CandlestickDirection.falling
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                ],
              ),
            ],
            theme: theme,
            showLegend: false,
            grid: const GridConfig(horizontal: true, vertical: false),
            xAxisConfig: const XAxisConfig(showTickLabels: false, tickCount: 5),
            yAxis: YAxisConfig(
              position: YAxisPosition.right,
              tickCount: 2,
              label: 'Volume',
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: BravenChartPlus(
            series: [
              AreaChartSeries(
                id: 'navigator',
                points: closePoints,
                color: const Color(0xFF0EA5E9),
                strokeWidth: 1.25,
                fillOpacity: .14,
                interpolation: LineInterpolation.monotone,
              ),
            ],
            annotations: [
              RangeAnnotation(
                id: 'window',
                startX: 7,
                endX: 18,
                fillColor: const Color(0x243B82F6),
                borderColor: const Color(0x883B82F6),
              ),
            ],
            theme: theme,
            showLegend: false,
            grid: const GridConfig(horizontal: false, vertical: false),
            xAxisConfig: const XAxisConfig(tickCount: 4),
            yAxis: YAxisConfig(
              position: YAxisPosition.right,
              visible: false,
              showAxisLine: false,
              showTicks: false,
              showTickLabels: false,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Size size,
  required ChartTheme theme,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _materialTheme(theme.backgroundColor.computeLuminance() < .5),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _surfaceKey,
            child: ColoredBox(
              color: theme.backgroundColor,
              child: SizedBox.fromSize(size: size, child: child),
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

List<CandlestickDataPoint> _standardCandles({int count = 18}) => [
  for (var index = 0; index < count; index++) _candle(index),
];

CandlestickDataPoint _candle(int index, {double? x}) {
  final center = 102 + index * .42 + math.sin(index / 2.2) * 4.6;
  final open = center + math.sin(index * 1.7) * 2.1;
  final close = center + math.cos(index * 1.3) * 2.2;
  return CandlestickDataPoint(
    x: x ?? index.toDouble(),
    open: open,
    high: math.max(open, close) + 1.4 + (index % 3) * .45,
    low: math.min(open, close) - 1.2 - (index % 2) * .55,
    close: close,
  );
}

List<CandlestickDataPoint> _dojiCandles() => [
  for (var index = 0; index < 15; index++)
    CandlestickDataPoint(
      x: index.toDouble(),
      open: 100 + math.sin(index / 2) * 4,
      high: 104 + math.sin(index / 2) * 4 + (index % 3),
      low: 96 + math.sin(index / 2) * 4 - (index % 2),
      close: index % 3 == 0
          ? 100 + math.sin(index / 2) * 4
          : 100 + math.sin(index / 2) * 4 + (index.isEven ? 2 : -2),
    ),
];

List<CandlestickDataPoint> _irregularCandles({required bool ordinal}) {
  const elapsedDays = [0, 1, 2, 5, 6, 9, 13, 14, 15, 21, 22, 27, 28];
  return [
    for (var index = 0; index < elapsedDays.length; index++)
      _candle(index, x: ordinal ? index.toDouble() : elapsedDays[index] * 1.0),
  ];
}

List<CandlestickDataPoint> _denseCandles() => [
  for (var index = 0; index < 240; index++)
    CandlestickDataPoint(
      x: index.toDouble(),
      open: 100 + math.sin(index / 11) * 8,
      high: 105 + math.sin(index / 11) * 8 + (index % 7),
      low: 95 + math.sin(index / 11) * 8 - (index % 5),
      close: 100 + math.sin(index / 11) * 8 + math.cos(index / 4) * 3,
    ),
];

List<ChartDataPoint> _movingAverage(
  List<CandlestickDataPoint> candles,
  int window,
) => [
  for (var index = 0; index < candles.length; index++)
    ChartDataPoint(
      x: candles[index].x,
      y:
          candles
              .sublist(math.max(0, index - window + 1), index + 1)
              .fold<double>(0, (sum, candle) => sum + candle.close) /
          math.min(window, index + 1),
    ),
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

class _CompositionHeader extends StatelessWidget {
  const _CompositionHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'ACME',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Text('\$108.42', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
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
