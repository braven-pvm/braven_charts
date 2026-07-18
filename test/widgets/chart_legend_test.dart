import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('legend renders bar and path-aware series swatches', (
    tester,
  ) async {
    String? toggledId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartLegend(
            series: const [
              BarChartSeries(
                id: 'forecast',
                name: 'Forecast',
                points: [ChartDataPoint(x: 0, y: 42)],
                color: Color(0xFF386A78),
                barWidthPercent: 0.7,
                barStyle: BarChartStyle(
                  pattern: BarPatternStyle(pattern: BarFillPattern.crosshatch),
                ),
              ),
              LineChartSeries(
                id: 'trend',
                name: 'Trend',
                points: [ChartDataPoint(x: 0, y: 42)],
                color: Color(0xFF386A78),
                dashPattern: [2, 6],
              ),
              AreaChartSeries(
                id: 'range',
                name: 'Range',
                points: [ChartDataPoint(x: 0, y: 38)],
                color: Color(0xFF805AD5),
              ),
            ],
            hiddenSeriesIds: const {},
            onSeriesToggle: (id) => toggledId = id,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size == const Size(18, 12),
      ),
      findsNWidgets(3),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
      findsNothing,
    );

    await tester.tap(find.text('Forecast'));
    expect(toggledId, 'forecast');
  });
}
