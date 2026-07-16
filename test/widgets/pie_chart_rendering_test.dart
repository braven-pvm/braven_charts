import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/widgets/pie_chart_legend.dart';
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

  testWidgets('honors a vertical center-right legend layout', (tester) async {
    final theme = ChartTheme.light.copyWith(
      legendStyle: ChartTheme.light.legendStyle.copyWith(
        position: LegendPosition.centerRight,
        orientation: LegendOrientation.vertical,
        markerShape: LegendMarkerShape.diamond,
      ),
      pieChartTheme: const PieChartTheme(animationMode: PieAnimationMode.none),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                showLegend: true,
                theme: theme,
                series: [
                  PieChartSeries.fromMap(
                    id: 'legend',
                    values: const {'A': 4, 'B': 3, 'C': 2},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chartRect = tester.getRect(find.byType(BravenChartPlus));
    final legendRect = tester.getRect(find.byType(PieChartLegend));
    expect(legendRect.center.dx, greaterThan(chartRect.center.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pie grow animation runs and respects reduced motion', (
    tester,
  ) async {
    Widget build({required bool disableAnimations}) {
      return MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: SizedBox(
          width: 320,
          height: 240,
          child: BravenChartPlus(
            theme: ChartTheme.light,
            series: [
              PieChartSeries.fromMap(
                id: 'animated',
                values: const {'A': 2, 'B': 1},
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(disableAnimations: false));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(build(disableAnimations: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all Pie legend anchors remain bounded', (tester) async {
    for (final position in LegendPosition.values) {
      final vertical =
          position == LegendPosition.centerLeft ||
          position == LegendPosition.centerRight;
      final theme = ChartTheme.light.copyWith(
        legendStyle: ChartTheme.light.legendStyle.copyWith(
          position: position,
          orientation: vertical
              ? LegendOrientation.vertical
              : LegendOrientation.horizontal,
        ),
        pieChartTheme: const PieChartTheme(
          animationMode: PieAnimationMode.none,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 420,
            height: 320,
            child: BravenChartPlus(
              showLegend: true,
              theme: theme,
              series: [
                PieChartSeries.fromMap(
                  id: 'positions',
                  values: const {
                    'One': 8,
                    'Two': 7,
                    'Three': 6,
                    'Four': 5,
                    'Five': 4,
                    'Six': 3,
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(PieChartLegend),
        findsOneWidget,
        reason: position.name,
      );
      expect(tester.takeException(), isNull, reason: position.name);
    }
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
