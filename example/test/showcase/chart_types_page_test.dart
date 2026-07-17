import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_types_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart types is a concise native-rendered family overview', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chart Types'), findsOneWidget);
    expect(find.text('Start with the data question'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-type-catalog-grid')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsNWidgets(5));
    for (final family in ['Line', 'Area', 'Bar', 'Scatter', 'Pie']) {
      expect(find.text(family), findsOneWidget);
    }
    expect(find.text('Chart Options'), findsNothing);
    expect(find.text('Regenerate Dataset'), findsNothing);
  });

  testWidgets('family card opens the matching deep guide', (tester) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    String? selectedSlug;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartTypesPage(onOpenChartType: (slug) => selectedSlug = slug),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('chart-type-card-bar')));
    await tester.pump();

    expect(selectedSlug, 'bar-charts');
  });
}
