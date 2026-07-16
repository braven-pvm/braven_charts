import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders one pie series through BravenChartPlus', (tester) async {
    await tester.pumpWidget(
      _host(
        PieChartSeries.fromMap(
          id: 'revenue-share',
          values: const {'Subscriptions': 42, 'Services': 31, 'Hardware': 27},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.text('Revenue mix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all-zero pie data uses the configured empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PieChartSeries.fromMap(id: 'empty', values: const {'A': 0, 'B': 0}),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('braven_chart_empty_state')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects Cartesian annotations on a radial chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BravenChartPlus(
          series: [
            PieChartSeries.fromMap(id: 'annotated', values: const {'A': 1}),
          ],
          annotations: [
            ThresholdAnnotation(
              id: 'threshold',
              axis: AnnotationAxis.y,
              value: 1,
            ),
          ],
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        contains('do not support Cartesian annotations'),
      ),
    );
  });
}

Widget _host(PieChartSeries series) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          height: 320,
          child: BravenChartPlus(
            title: 'Revenue mix',
            series: [series],
            theme: ChartTheme.light,
          ),
        ),
      ),
    ),
  );
}
