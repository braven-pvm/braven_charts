import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_types_page.dart';
import 'package:braven_charts_example/showcase/widgets/chart_type_catalog.dart';
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
      find.byKey(const ValueKey('chart-type-cartesian-grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-radial-grid')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsNWidgets(7));
    for (final family in [
      'Line',
      'Area',
      'Bar',
      'Scatter',
      'Pie',
      'Donut',
      'Concentric Donut',
    ]) {
      expect(find.text(family), findsOneWidget);
    }
    expect(find.text('Motion'), findsNWidgets(3));
    expect(find.text('Grouping'), findsOneWidget);
    expect(find.text('Variable radius'), findsOneWidget);
    expect(find.text('Chart Options'), findsNothing);
    expect(find.text('Regenerate Dataset'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('chart-type-card-pie'))).width,
      greaterThan(
        tester
            .getSize(find.byKey(const ValueKey('chart-type-card-line')))
            .width,
      ),
    );
  });

  testWidgets('family cards open the matching deep guides', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('chart-type-card-donut')));
    await tester.pump();
    expect(selectedSlug, 'donut-charts');

    await tester.tap(
      find.byKey(const ValueKey('chart-type-card-concentric-donut')),
    );
    await tester.pump();
    expect(selectedSlug, 'concentric-donut');
  });

  testWidgets('radial catalog previews fill their cards with concise actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: ChartTypeCatalogStrip(onOpenChartType: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final pie = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-pie')),
    );
    final pieSeries = pie.series.single as PieChartSeries;
    expect(pieSeries.pieStyle.radiusFactor, 1.0);

    final donut = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-donut')),
    );
    final donutSeries = donut.series.single as DonutChartSeries;
    expect(donutSeries.donutStyle.radiusFactor, 0.94);

    final concentric = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-concentric-donut')),
    );
    expect(concentric.concentricDonutConfig.outerRadiusFactor, 0.92);
    expect(concentric.series, hasLength(3));
    expect(concentric.concentricDonutConfig.centerContent.customValue, '3');
    final concentricScale = tester.widget<Transform>(
      find.byKey(const ValueKey('chart-type-preview-scale-concentric-donut')),
    );
    expect(concentricScale.transform.getMaxScaleOnAxis(), closeTo(1.12, 0.001));
    expect(
      tester.getSize(find.byKey(const ValueKey('chart-type-card-pie'))).width,
      greaterThan(
        tester
            .getSize(find.byKey(const ValueKey('chart-type-card-line')))
            .width,
      ),
    );
    expect(find.text('View Concentric'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
