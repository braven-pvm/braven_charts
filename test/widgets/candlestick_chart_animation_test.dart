import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entrance reveal advances candles in X order', (tester) async {
    await tester.pumpWidget(_host(_series(close: 12)));

    expect(_element(tester).visibleCandlestickGeometryCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    final partial = _element(tester).visibleCandlestickPointIndices;
    expect(partial, isNotEmpty);
    expect(partial.length, lessThan(4));
    expect(partial, orderedEquals(List.generate(partial.length, (i) => i)));

    await tester.pumpAndSettle();
    expect(_element(tester).visibleCandlestickGeometryCount, 4);
  });

  testWidgets('reduced motion renders the complete candle series immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(_series(close: 12)),
      ),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(_element(tester).revealProgress, 1);
    expect(_element(tester).visibleCandlestickGeometryCount, 4);
  });

  testWidgets(
    'compatible OHLC revisions interpolate without changing identity',
    (tester) async {
      final key = GlobalKey<_RevisionHarnessState>();
      await tester.pumpWidget(_RevisionHarness(key: key));
      await tester.pumpAndSettle();

      key.currentState!.revise();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      final point = (_element(tester).series as CandlestickChartSeries)
          .candleAt(0);
      expect(point.x, 0);
      expect(point.timestamp, DateTime.utc(2026, 7, 19));
      expect(point.close, greaterThan(12));
      expect(point.close, lessThan(20));

      await tester.pumpAndSettle();
      expect(
        (_element(tester).series as CandlestickChartSeries).candleAt(0).close,
        20,
      );
    },
  );
}

Widget _host(CandlestickChartSeries series) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 500,
      height: 320,
      child: BravenChartPlus(showLegend: false, series: [series]),
    ),
  ),
);

CandlestickChartSeries _series({required double close}) =>
    CandlestickChartSeries(
      id: 'price',
      points: [
        CandlestickDataPoint(
          x: 0,
          open: 10,
          high: close > 10 ? close + 2 : 12,
          low: 8,
          close: close,
          timestamp: DateTime.utc(2026, 7, 19),
        ),
        CandlestickDataPoint(x: 1, open: 12, high: 15, low: 11, close: 14),
        CandlestickDataPoint(x: 2, open: 14, high: 16, low: 12, close: 13),
        CandlestickDataPoint(x: 3, open: 13, high: 17, low: 12, close: 16),
      ],
      animation: const CandlestickAnimationStyle(
        mode: CandlestickAnimationMode.reveal,
        staggerFraction: .85,
      ),
    );

SeriesElement _element(WidgetTester tester) {
  final renderBox = tester.renderObject<ChartRenderBox>(
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
    ),
  );
  return renderBox.debugElements
      .whereType<SeriesElement>()
      .where((element) => element.series is CandlestickChartSeries)
      .single;
}

class _RevisionHarness extends StatefulWidget {
  const _RevisionHarness({super.key});

  @override
  State<_RevisionHarness> createState() => _RevisionHarnessState();
}

class _RevisionHarnessState extends State<_RevisionHarness> {
  double _close = 12;

  void revise() => setState(() => _close = 20);

  @override
  Widget build(BuildContext context) => _host(_series(close: _close));
}
