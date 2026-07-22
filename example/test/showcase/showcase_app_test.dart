import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:braven_charts_example/showcase/pages/mobile_showcase_page.dart';
import 'package:braven_charts_example/showcase/widgets/braven_brand.dart';
import 'package:braven_charts_example/showcase/widgets/chart_type_catalog.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('direct Candlestick route attaches one Workbench', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1600 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'candlestick-charts'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Candlestick Charts'), findsWidgets);
    expect(find.byType(BravenChartWorkbench), findsOneWidget);
    expect(
      find.byKey(const ValueKey('candlestick-reference-chart')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct Technical Indicators route mounts the financial stack', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1600 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'technical-indicators'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Technical Indicators'), findsWidgets);
    expect(
      find.byKey(const ValueKey('financial-technical-stack')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('financial-price-chart')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct Range Area route attaches the native review surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'range-area-charts'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Range Area Charts'), findsWidgets);
    expect(find.byType(BravenChartWorkbench), findsOneWidget);
    expect(
      find.byKey(const ValueKey('range-area-chart-temperature')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct Selection route mounts the cross-family test lab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: ShowcaseHome(requestedPageOverride: 'selection')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selection lab'), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-family-grid')), findsOneWidget);
    expect(find.byType(BravenChartWorkbench), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow showcase uses the focused phone chart browser', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.byType(MobileShowcasePage), findsOneWidget);
    expect(find.byType(BravenBrand), findsOneWidget);
    expect(find.text('Charts for Flutter'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-chart-type-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-chart-card-line-charts-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-chart-list-line-charts')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsAtLeast(1));
    expect(find.text('Loading States'), findsNothing);
  });

  testWidgets('phone chart selector swaps one mounted chart at a time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 250));

    final strip = find.byKey(const ValueKey('mobile-chart-type-strip'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mobile-chart-type-pie-charts')),
      320,
      scrollable: find.descendant(of: strip, matching: find.byType(Scrollable)),
    );
    await tester.tap(
      find.byKey(const ValueKey('mobile-chart-type-pie-charts')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-chart-card-pie-charts-0')),
      findsOneWidget,
    );
    expect(find.text('Monthly spending'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-chart-list-pie-charts')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsAtLeast(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone direct chart route opens the matching focused example', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'polar-column'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MobileShowcasePage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-chart-card-polar-column-0')),
      findsOneWidget,
    );
    expect(
      find
          .byKey(const ValueKey('mobile-chart-type-polar-column'))
          .hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Activity rhythm'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsAtLeast(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone style selector applies a dark chart treatment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byKey(const ValueKey('mobile-style-midnight')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('mobile-style-selector')), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus).first,
    );
    expect(chart.theme?.backgroundColor, const Color(0xFF0F172A));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone line examples preserve comparison and forecast grammar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'line-charts'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final comparison = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-line-charts-1')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(comparison.series, hasLength(3));
    expect(comparison.showLegend, isTrue);

    final forecast = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-line-charts-2')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(forecast.annotations.single, isA<ThresholdAnnotation>());
    final forecastSeries = forecast.series.single as LineChartSeries;
    expect(
      forecastSeries.points.where((point) => point.segmentStyle != null),
      isNotEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone analytical examples retain native family composition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final slug in const [
      'range-area-charts',
      'bar-charts',
      'scatter-charts',
      'candlestick-charts',
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: MobileShowcasePage(initialChartSlug: slug)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(ValueKey('mobile-chart-card-$slug-2')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      switch (slug) {
        case 'range-area-charts':
          expect(chart.series.whereType<RangeAreaChartSeries>(), hasLength(2));
          expect(chart.series.whereType<LineChartSeries>(), hasLength(1));
        case 'bar-charts':
          expect(chart.series, hasLength(3));
          expect(
            chart.series.cast<BarChartSeries>().every(
              (series) => series.layoutMode == BarLayoutMode.divergingStacked,
            ),
            isTrue,
          );
        case 'scatter-charts':
          expect(chart.series.whereType<ScatterChartSeries>(), hasLength(3));
        case 'candlestick-charts':
          expect(
            chart.series.whereType<CandlestickChartSeries>(),
            hasLength(1),
          );
          expect(chart.series.whereType<RangeAreaChartSeries>(), hasLength(1));
          expect(chart.series.whereType<LineChartSeries>(), hasLength(1));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('phone radial examples expose radius and composition variants', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'donut-charts'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final donut = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-donut-charts-2')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(
      (donut.series.single as DonutChartSeries).sliceRadiusConfig,
      isNotNull,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'polar-column'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final polar = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-polar-column-2')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(polar.series.whereType<PolarColumnChartSeries>(), hasLength(3));
    expect(
      polar.polarChartConfig.composition.mode,
      PolarColumnCompositionMode.grouped,
    );
    expect(tester.takeException(), isNull);
  });

  for (final chartType in showcaseChartTypes) {
    testWidgets('phone renders the ${chartType.label} family example', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(home: MobileShowcasePage(initialChartSlug: chartType.slug)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(ValueKey('mobile-chart-card-${chartType.slug}-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('mobile-chart-list-${chartType.slug}')),
        findsOneWidget,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -620));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(ValueKey('mobile-chart-card-${chartType.slug}-2')),
        findsOneWidget,
      );
      expect(find.byType(BravenChartPlus), findsAtLeast(1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wide showcase uses the persistent feature rail', (tester) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 900 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BravenBrand), findsOneWidget);
    expect(find.text('Tracking Lab'), findsNothing);
    expect(find.text('Interaction'), findsOneWidget);
    expect(find.text('Selection'), findsOneWidget);
    expect(find.text('Line Charts'), findsOneWidget);
    expect(find.text('Area Charts'), findsOneWidget);
    expect(find.text('Bar Charts'), findsOneWidget);
    expect(find.text('Scatter Charts'), findsOneWidget);
    expect(find.text('Candlestick Charts'), findsOneWidget);
    expect(find.text('FINANCIAL'), findsOneWidget);
    expect(find.text('Technical Indicators'), findsOneWidget);
    expect(find.text('Pie Charts'), findsOneWidget);
    expect(find.text('Donut Charts'), findsOneWidget);
    expect(find.text('Concentric Donut Charts'), findsOneWidget);
    expect(find.text('Power + Lactate'), findsNothing);
    expect(find.text('Lactate Threshold'), findsNothing);
    expect(find.text('Multi-Axis'), findsOneWidget);
    expect(find.text('Axes'), findsOneWidget);
    expect(find.text('Minor Ticks'), findsNothing);
    expect(find.text('Render Range'), findsNothing);
    expect(find.text('Axis Slots'), findsNothing);
    expect(find.text('Segment Styling'), findsNothing);
    expect(find.text('Point Labels'), findsNothing);
    expect(find.text('Series Styling'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('chart-type-card-donut'))).right,
      lessThanOrEqualTo(1440),
    );

    await tester.tap(find.text('Line Charts'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Choose a line chart example'), findsOneWidget);
    expect(find.text('Workhorse'), findsWidgets);
    final selectedRailItem = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Line Charts'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final selectedDecoration = selectedRailItem.decoration! as BoxDecoration;
    expect(selectedDecoration.borderRadius, isNull);
    expect(selectedDecoration.boxShadow, isNull);
    expect(selectedDecoration.color, Colors.transparent);

    await tester.tap(find.text('Candlestick Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('candlestick-reference-chart')),
      findsOneWidget,
    );

    await tester.tap(find.text('Technical Indicators'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('financial-price-chart')), findsOneWidget);

    await tester.tap(find.text('Pie Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);

    await tester.tap(find.text('Donut Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Contribution ring'), findsOneWidget);

    await tester.ensureVisible(find.text('Performance'));
    await tester.tap(find.text('Performance'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Performance Lab'), findsOneWidget);
    expect(find.text('Needs review'), findsNothing);
  });

  testWidgets('streaming is consolidated into the live stream destination', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 900 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Streaming'), findsNothing);
    expect(find.text('Live Stream'), findsOneWidget);

    await tester.ensureVisible(find.text('Live Stream'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Live Stream'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Follow latest'), findsWidgets);
    expect(find.text('Paused buffer'), findsOneWidget);
    expect(find.text('Expand then slide'), findsOneWidget);
    expect(find.text('High frequency'), findsOneWidget);
    expect(find.text('Live navigator'), findsOneWidget);
  });

  testWidgets('Workbench presentation follows chart-family navigation', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 900 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Line Charts'));
    await tester.pump(const Duration(milliseconds: 300));

    final lineSwitcher = tester.widget<SegmentedButton<ChartDisplayMode>>(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
    );
    lineSwitcher.onSelectionChanged?.call({ChartDisplayMode.split});
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<ChartDisplayMode>>(
            find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          )
          .selected,
      {ChartDisplayMode.split},
    );

    await tester.tap(find.text('Area Charts'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<ChartDisplayMode>>(
            find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          )
          .selected,
      {ChartDisplayMode.split},
    );

    await tester.tap(find.text('Pie Charts'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<ChartDisplayMode>>(
            find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          )
          .selected,
      {ChartDisplayMode.split},
    );

    await tester.ensureVisible(find.text('Chart Workbench'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chart Workbench'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Show view selector'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNothing,
    );

    await tester.ensureVisible(find.text('Line Charts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Line Charts'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a line chart example'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
