import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showcases live pie datasets and public usage guidance', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pie Charts'), findsOneWidget);
    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-revenue')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-effort')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-support')), findsOneWidget);
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-legend-item-0')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pie-legend-item-0')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('pie-showcase-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
    await tester.pumpAndSettle();

    expect(find.text('Selected: Subscriptions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pie-dataset-support')),
      -500,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('pie-showcase-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('pie-dataset-support')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Requests by topic'), findsOneWidget);
    expect(find.textContaining('8 categories'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
    tester
        .widget<ElevatedButton>(
          find.byKey(const ValueKey('regenerate-pie-values')),
        )
        .onPressed!();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('tickets total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the pie showcase usable at a narrow viewport', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Options'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
