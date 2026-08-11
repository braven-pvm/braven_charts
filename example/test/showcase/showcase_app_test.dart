import 'dart:ui' show PointerDeviceKind;

import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:braven_charts_example/showcase/pages/mobile_showcase_page.dart';
import 'package:braven_charts_example/showcase/pages/mobile_interaction_page.dart';
import 'package:braven_charts_example/showcase/widgets/braven_brand.dart';
import 'package:braven_charts_example/showcase/widgets/chart_type_catalog.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _verticalMobileScroll() => find
    .descendant(
      of: find.byKey(const ValueKey('mobile-showcase')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    )
    .first;

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

  testWidgets('direct Heatmap route mounts the native matrix renderer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'heatmap-charts'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heatmap Charts'), findsWidgets);
    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('heatmap-chart-activity')),
    );
    expect(chart.series.single, isA<HeatmapChartSeries>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct Gauge route attaches the native Workbench', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'gauge-charts'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gauge Charts'), findsWidgets);
    expect(find.byType(BravenChartWorkbench), findsOneWidget);
    expect(find.byKey(const ValueKey('gauge-chart-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct Radar route opens the authored Spider comparison', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'radar-charts'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Radar and Spider Charts'), findsWidgets);
    expect(
      find.byKey(const ValueKey('radar-chart-budget-polygon')),
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

  testWidgets('direct Mobile Interaction route stays available on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'mobile-interaction'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MobileInteractionPage), findsOneWidget);
    expect(find.text('Mobile interaction'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Short tap selects'), findsOneWidget);
    expect(find.text('Long-press tracking'), findsOneWidget);
    expect(find.text('Haptic steps'), findsOneWidget);
    expect(find.text('Pan inertia'), findsOneWidget);
    final pageScroll = find.descendant(
      of: find.byKey(const ValueKey('mobile-interaction-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mobile-interaction-chart')),
      300,
      scrollable: pageScroll,
    );
    await tester.pumpAndSettle();
    TouchInteractionConfig touchConfig() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .interactionConfig!
        .touch;
    expect(touchConfig().profile, TouchInteractionProfile.browse);
    expect(touchConfig().tapBehavior, TouchTapBehavior.disabled);

    await tester.drag(pageScroll, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-short-tap-activation-switch')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('mobile-short-tap-activation-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('mobile-short-tap-activation-switch')),
    );
    await tester.pump();

    await tester.drag(pageScroll, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-interaction-chart')),
      findsOneWidget,
    );
    expect(touchConfig().tapBehavior, TouchTapBehavior.inspectAndSelect);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Fit data'),
              matching: find.byType(FilledButton),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mobile-action-select-all')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final selectAllButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-action-select-all')),
        matching: find.byType(OutlinedButton),
      ),
    );
    selectAllButton.onPressed!();
    await tester.pump();
    expect(find.text('Selected all bounded chart data.'), findsOneWidget);

    final clearSelectionButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-action-clear-selection')),
        matching: find.byType(OutlinedButton),
      ),
    );
    clearSelectionButton.onPressed!();
    await tester.pump();
    expect(find.text('Cleared chart selection.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile Interaction actions reflow at 200% text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: MobileInteractionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mobile-action-select-all')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Accessible chart actions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-action-fit-data')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('mobile-action-select-all')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct Selection route remains reachable on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: ShowcaseHome(requestedPageOverride: 'selection')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MobileShowcasePage), findsNothing);
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
    final chartTypeList = find.descendant(
      of: strip,
      matching: find.byType(ListView),
    );
    for (var drag = 0; drag < 2; drag++) {
      await tester.drag(chartTypeList, const Offset(-620, 0));
      await tester.pumpAndSettle();
    }
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

    for (final style in const [
      'vivid',
      'midnight',
      'calm',
      'ocean',
      'ember',
      'graphite',
    ]) {
      expect(find.byKey(ValueKey('mobile-style-$style')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('mobile-style-midnight')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('mobile-style-selector')), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus).first,
    );
    expect(chart.theme?.backgroundColor, const Color(0xFF0F172A));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone chart chrome defaults clean and can restore axes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'line-charts'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    BravenChartPlus chart() => tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-line-charts-0')),
        matching: find.byType(BravenChartPlus),
      ),
    );

    expect(chart().xAxisConfig?.visible, isFalse);
    expect(chart().yAxis!.visible, isFalse);
    expect(chart().grid!.horizontal, isFalse);
    expect(chart().grid!.vertical, isFalse);

    await tester.tap(find.byKey(const ValueKey('mobile-view-touch-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-chart-chrome-axes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-touch-options-done')));
    await tester.pumpAndSettle();

    expect(chart().xAxisConfig?.visible, isTrue);
    expect(chart().yAxis!.visible, isTrue);
    expect(chart().grid!.horizontal, isTrue);
    expect(chart().grid!.vertical, isFalse);
    expect(chart().theme!.axisStyle.lineColor, isNot(equals(Colors.black)));
    expect(
      chart().theme!.axisStyle.labelStyle.color,
      isNot(equals(chart().theme!.axisStyle.lineColor)),
    );
    expect(
      chart().theme!.axisStyle.titleStyle.color,
      isNot(equals(chart().theme!.axisStyle.labelStyle.color)),
    );
    expect(chart().grid!.horizontalColor, isNotNull);
    expect(chart().xAxisConfig!.tickLabelPadding, 3);
    expect(chart().yAxis!.axisLabelPadding, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone gesture and tap profiles are explicit and chart-wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'line-charts'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    InteractionConfig config() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
        .interactionConfig!;

    expect(config().enabled, isTrue);
    expect(config().tooltip.enabled, isTrue);
    expect(config().enableSelection, isTrue);
    expect(config().crosshair.enabled, isTrue);
    expect(config().enableZoom, isTrue);
    expect(config().enablePan, isTrue);
    expect(config().touch.profile, TouchInteractionProfile.browse);
    expect(config().touch.enableLongPressTracking, isTrue);
    expect(config().touch.enableHapticFeedback, isTrue);
    expect(config().touch.enablePanInertia, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('mobile-touch-settings-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('mobile-touch-profile-explore')),
    );
    await tester.pump();
    expect(config().touch.profile, TouchInteractionProfile.explore);

    await tester.tap(find.byKey(const ValueKey('mobile-touch-mode-details')));
    await tester.pump();
    expect(config().tooltip.enabled, isTrue);
    expect(config().enableSelection, isFalse);
    expect(config().enableZoom, isTrue);
    expect(config().enablePan, isTrue);

    await tester.tap(find.byKey(const ValueKey('mobile-touch-mode-select')));
    await tester.pump();
    expect(config().tooltip.enabled, isFalse);
    expect(config().enableSelection, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('mobile-touch-tracking-switch')),
    );
    await tester.pump();
    expect(config().touch.enableLongPressTracking, isFalse);
    expect(config().crosshair.enabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('mobile-touch-mode-static')));
    await tester.pump();
    expect(config().enabled, isFalse);
    expect(config().tooltip.enabled, isFalse);
    expect(config().enableSelection, isFalse);
    expect(config().enableZoom, isFalse);
    expect(config().enablePan, isFalse);
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
          expect(chart.series, hasLength(5));
          expect(chart.legendStyle?.position, LegendPosition.topLeft);
          expect(chart.legendStyle?.orientation, LegendOrientation.vertical);
          expect(chart.legendStyle?.textStyle.fontSize, 8);
          expect(
            chart.series.cast<BarChartSeries>().every(
              (series) =>
                  series.layoutMode == BarLayoutMode.divergingStacked &&
                  series.labelStyle.fontSize == 8,
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

  testWidgets('phone advanced examples preserve their defining chart grammar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final slug in const [
      'line-charts',
      'area-charts',
      'range-area-charts',
      'bar-charts',
      'scatter-charts',
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: MobileShowcasePage(initialChartSlug: slug)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final card = find.byKey(ValueKey('mobile-chart-card-$slug-3'));
      await tester.scrollUntilVisible(
        card,
        420,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 100));

      final chart = tester.widget<BravenChartPlus>(
        find.descendant(of: card, matching: find.byType(BravenChartPlus)),
      );
      switch (slug) {
        case 'line-charts':
          expect(chart.series.whereType<LineChartSeries>(), hasLength(2));
          expect(chart.annotations.whereType<RangeAnnotation>(), hasLength(1));
          expect(
            chart.annotations.whereType<ThresholdAnnotation>(),
            hasLength(1),
          );
          final stage = chart.series.whereType<LineChartSeries>().last;
          expect(stage.interpolation, LineInterpolation.stepped);
          expect(stage.lineGlow, greaterThan(0));
        case 'area-charts':
          expect(chart.series.whereType<AreaChartSeries>(), hasLength(3));
          expect(chart.series.whereType<LineChartSeries>(), hasLength(2));
        case 'range-area-charts':
          final range = chart.series.single as RangeAreaChartSeries;
          expect(range.interpolation, LineInterpolation.stepped);
          expect(range.connectGaps, isFalse);
          expect(range.intervals.where((point) => point.isGap), hasLength(3));
        case 'bar-charts':
          expect(chart.series.whereType<BarChartSeries>(), hasLength(2));
          expect(
            chart.series.cast<BarChartSeries>().every(
              (series) => series.lollipopStyle != null,
            ),
            isTrue,
          );
        case 'scatter-charts':
          final density = chart.series.single as ScatterChartSeries;
          expect(density.renderMode, ScatterRenderMode.hexbin);
          expect(density.points, hasLength(900));
          expect(density.binConfig.aggregate, ScatterBinAggregate.count);
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
    final donutCard = find.byKey(
      const ValueKey('mobile-chart-card-donut-charts-2'),
    );
    await tester.scrollUntilVisible(
      donutCard,
      420,
      scrollable: _verticalMobileScroll(),
    );
    final donut = tester.widget<BravenChartPlus>(
      find.descendant(of: donutCard, matching: find.byType(BravenChartPlus)),
    );
    final donutSeries = donut.series.single as DonutChartSeries;
    expect(donutSeries.sliceRadiusConfig, isNotNull);
    expect(donutSeries.donutStyle.radiusFactor, 0.98);
    expect(donutSeries.donutStyle.gradient, isNotNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'concentric-donut'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final comparison = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-concentric-donut-0')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(comparison.series.whereType<DonutChartSeries>(), hasLength(2));
    expect(comparison.concentricDonutConfig.ringWeights, hasLength(2));
    expect(comparison.concentricDonutConfig.outerRadiusFactor, 0.98);
    expect(
      comparison.concentricDonutConfig.legendMode,
      ConcentricDonutLegendMode.flat,
    );
    expect(comparison.showLegend, isTrue);
    expect(comparison.legendStyle?.position, LegendPosition.bottomCenter);
    expect(comparison.legendStyle?.orientation, LegendOrientation.horizontal);
    expect(comparison.radialLegendItemBuilder, isNotNull);
    expect(
      comparison.series.whereType<DonutChartSeries>().every(
        (series) => series.donutStyle.gradient != null,
      ),
      isTrue,
    );

    final calloutCard = find.byKey(
      const ValueKey('mobile-chart-card-concentric-donut-1'),
    );
    await tester.scrollUntilVisible(
      calloutCard,
      420,
      scrollable: _verticalMobileScroll(),
    );
    final callout = tester.widget<BravenChartPlus>(
      find.descendant(of: calloutCard, matching: find.byType(BravenChartPlus)),
    );
    final calloutRing = callout.series.first as DonutChartSeries;
    expect(calloutRing.dataLabels.position, PieDataLabelPosition.outside);
    expect(
      calloutRing.dataLabels.secondaryContent,
      PieDataLabelContent.percentage,
    );
    expect(
      calloutRing.dataLabels.secondaryPosition,
      PieDataLabelPosition.inside,
    );
    expect(calloutRing.dataLabels.calloutStyle, isNotNull);
    expect(calloutRing.dataLabels.secondaryCalloutStyle, isNotNull);

    final partialCard = find.byKey(
      const ValueKey('mobile-chart-card-concentric-donut-2'),
    );
    await tester.scrollUntilVisible(
      partialCard,
      420,
      scrollable: _verticalMobileScroll(),
    );
    final partial = tester.widget<BravenChartPlus>(
      find.descendant(of: partialCard, matching: find.byType(BravenChartPlus)),
    );
    expect(partial.series.whereType<DonutChartSeries>(), hasLength(3));
    expect(
      partial.series.whereType<DonutChartSeries>().every(
        (series) => series.donutStyle.sweepAngleDegrees == 280,
      ),
      isTrue,
    );
    expect(
      partial.concentricDonutConfig.order,
      ConcentricRingOrder.innerToOuter,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'polar-column'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('mobile-view-touch-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-chart-chrome-axes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-touch-options-done')));
    await tester.pumpAndSettle();

    final rose = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('mobile-chart-card-polar-column-0')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(rose.polarChartConfig.pane.outerRadiusFactor, 0.98);
    expect(rose.polarChartConfig.angularAxis.labelOffset, 7);
    expect(rose.polarChartConfig.angularAxis.labelStyle.color, isNotNull);
    expect(rose.polarChartConfig.radialAxis.showLabels, isTrue);
    expect(
      (rose.series.single as PolarColumnChartSeries).polarStyle.gradient,
      isNotNull,
    );

    final polarCard = find.byKey(
      const ValueKey('mobile-chart-card-polar-column-2'),
    );
    await tester.scrollUntilVisible(
      polarCard,
      420,
      scrollable: _verticalMobileScroll(),
    );
    final polar = tester.widget<BravenChartPlus>(
      find.descendant(of: polarCard, matching: find.byType(BravenChartPlus)),
    );
    expect(polar.series.whereType<PolarColumnChartSeries>(), hasLength(3));
    expect(
      polar.polarChartConfig.composition.mode,
      PolarColumnCompositionMode.grouped,
    );

    final stackedCard = find.byKey(
      const ValueKey('mobile-chart-card-polar-column-3'),
    );
    await tester.scrollUntilVisible(
      stackedCard,
      420,
      scrollable: _verticalMobileScroll(),
    );
    final stacked = tester.widget<BravenChartPlus>(
      find.descendant(of: stackedCard, matching: find.byType(BravenChartPlus)),
    );
    expect(stacked.series.whereType<PolarColumnChartSeries>(), hasLength(3));
    expect(
      stacked.polarChartConfig.composition.mode,
      PolarColumnCompositionMode.stacked,
    );
    expect(
      stacked.series.whereType<PolarColumnChartSeries>().last.points.every(
        (point) => point.y < 0,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone fourth examples add distinct radial and OHLC grammar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final slug in const [
      'candlestick-charts',
      'pie-charts',
      'donut-charts',
      'concentric-donut',
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: MobileShowcasePage(initialChartSlug: slug)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final card = find.byKey(ValueKey('mobile-chart-card-$slug-3'));
      await tester.scrollUntilVisible(
        card,
        420,
        scrollable: _verticalMobileScroll(),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final chart = tester.widget<BravenChartPlus>(
        find.descendant(of: card, matching: find.byType(BravenChartPlus)),
      );
      switch (slug) {
        case 'candlestick-charts':
          final candles =
              chart.series.singleWhere(
                    (series) => series is CandlestickChartSeries,
                  )
                  as CandlestickChartSeries;
          expect(candles.points, hasLength(20));
          expect(chart.series.whereType<LineChartSeries>(), hasLength(1));
        case 'pie-charts':
          final pie = chart.series.single as PieChartSeries;
          expect(pie.points, hasLength(7));
          expect(pie.sliceGroupingConfig, isNotNull);
        case 'donut-charts':
          final donut = chart.series.single as DonutChartSeries;
          expect(donut.donutStyle.innerRadiusFactor, 0.58);
          expect(donut.centerContent.customValue, '82%');
          expect(donut.dataLabels.position, PieDataLabelPosition.outside);
          expect(
            donut.dataLabels.secondaryContent,
            PieDataLabelContent.percentage,
          );
          expect(
            donut.dataLabels.secondaryPosition,
            PieDataLabelPosition.inside,
          );
          expect(donut.dataLabels.secondaryCalloutStyle, isNotNull);
        case 'concentric-donut':
          expect(chart.series.whereType<DonutChartSeries>(), hasLength(4));
          expect(chart.concentricDonutConfig.ringWeights, hasLength(4));
          expect(chart.concentricDonutConfig.centerContent.customValue, '4');
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('phone Heatmaps preserve four distinct colour-scale stories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MobileShowcasePage(initialChartSlug: 'heatmap-charts'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final scaleTypes = <HeatmapColorScaleType>[];
    for (var index = 0; index < 4; index++) {
      final card = find.byKey(
        ValueKey('mobile-chart-card-heatmap-charts-$index'),
      );
      await tester.scrollUntilVisible(
        card,
        420,
        scrollable: _verticalMobileScroll(),
      );
      await tester.pump(const Duration(milliseconds: 80));
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(of: card, matching: find.byType(BravenChartPlus)),
      );
      final series = chart.series.single as HeatmapChartSeries;
      scaleTypes.add(series.colorScale.type);
      expect(series.cells, isNotEmpty);
    }

    expect(scaleTypes, [
      HeatmapColorScaleType.sequential,
      HeatmapColorScaleType.diverging,
      HeatmapColorScaleType.threshold,
      HeatmapColorScaleType.diverging,
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final chartType in showcaseChartTypes) {
    testWidgets('phone renders the ${chartType.label} family example', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1800);
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
      expect(find.text('4 examples'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Candlestick Charts'));
    await tester.tap(find.text('Candlestick Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('candlestick-reference-chart')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Technical Indicators'));
    await tester.tap(find.text('Technical Indicators'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('financial-price-chart')), findsOneWidget);

    await tester.ensureVisible(find.text('Pie Charts'));
    await tester.tap(find.text('Pie Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);

    await tester.ensureVisible(find.text('Donut Charts'));
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

  testWidgets('wide rail opens the public package and repository links', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final openedUrls = <String>[];

    await tester.pumpWidget(
      MaterialApp(home: ShowcaseHome(onOpenPublicUrl: openedUrls.add)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('showcase-public-links')), findsOneWidget);
    expect(find.text('pub.dev'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('pub.dev')).style?.decoration,
      TextDecoration.none,
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('showcase-pubdev-link'))),
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('pub.dev')).style?.decoration,
      TextDecoration.underline,
    );

    await tester.tap(find.byKey(const ValueKey('showcase-pubdev-link')));
    await tester.tap(find.byKey(const ValueKey('showcase-github-link')));
    await mouse.removePointer();

    expect(openedUrls, [showcasePubDevUrl, showcaseRepositoryUrl]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact rail keeps both public links accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final openedUrls = <String>[];

    await tester.pumpWidget(
      MaterialApp(home: ShowcaseHome(onOpenPublicUrl: openedUrls.add)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('pub.dev'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.byKey(const ValueKey('showcase-pubdev-link')), findsOneWidget);
    expect(find.byKey(const ValueKey('showcase-github-link')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('showcase-pubdev-link')));
    await tester.tap(find.byKey(const ValueKey('showcase-github-link')));

    expect(openedUrls, [showcasePubDevUrl, showcaseRepositoryUrl]);
    expect(tester.takeException(), isNull);
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
