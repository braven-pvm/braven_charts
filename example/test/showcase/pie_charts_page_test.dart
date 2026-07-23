import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('generates current Pie configuration in the shared Source view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    final sourceMode = find.descendant(
      of: switcher,
      matching: find.text('Source'),
    );
    await tester.ensureVisible(sourceMode);
    await tester.pump();
    await tester.tap(sourceMode);
    await tester.pumpAndSettle();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(
      workbench.workbenchController!.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      allOf(
        contains('final pieChart = BravenChartPlus('),
        contains('PieChartSeries('),
      ),
    );
    expect(find.byType(ChartSourceView), findsOneWidget);

    final firstSource = workbench.workbenchController!.generatedSource;
    final compactPreset = find.byKey(const ValueKey('pie-preset-compact'));
    await tester.ensureVisible(compactPreset);
    await tester.pump();
    await tester.tap(compactPreset);
    await tester.pumpAndSettle();

    expect(workbench.workbenchController!.sourceIsStale, isFalse);
    expect(
      workbench.workbenchController!.generatedSource,
      isNot(same(firstSource)),
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('position: PieDataLabelPosition.inside'),
    );
    expect(find.text('Chart changed'), findsNothing);
    expect(find.text('Refresh source'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
    expect(find.text('Choose a Pie chart example'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-simple')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-editorial')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-compact')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-preset-elevated')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pie-preset-highContrast')),
      findsOneWidget,
    );
    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-revenue')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-effort')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-support')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-countries')), findsOneWidget);
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-legend-item-0')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('pie-example-picker'))).height,
      lessThan(390),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('pie-showcase-card'))).dy,
      lessThan(520),
    );
    final initialChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final initialSeries = initialChart.series.single as PieChartSeries;
    expect(
      initialSeries.pieStyle.dataTransitionMode,
      RadialDataTransitionMode.automatic,
    );
    expect(initialSeries.dataLabels.valueFormatter, isNotNull);
    expect(initialSeries.dataLabels.percentageFormatter, isNotNull);
    expect(initialSeries.dataLabels.position, PieDataLabelPosition.outside);
    expect(initialSeries.dataLabels.content, PieDataLabelContent.category);
    expect(
      initialSeries.dataLabels.secondaryContent,
      PieDataLabelContent.percentage,
    );
    expect(
      initialSeries.dataLabels.secondaryPosition,
      PieDataLabelPosition.inside,
    );
    expect(
      initialSeries.dataLabels.secondaryCalloutStyle?.backgroundColor,
      const Color(0xD91F2937),
    );
    expect(initialSeries.pieStyle.gradient?.type, PieGradientType.radial);
    expect(initialSeries.pieStyle.cornerTreatment, PieCornerTreatment.roundAll);
    expect(initialSeries.selectionStyle.effect, RadialSelectionEffect.explode);
    expect(initialChart.interactionConfig?.showFocusBorder, isFalse);
    expect(tester.takeException(), isNull);

    final dynamic primaryLabelStyle = tester.widget(
      find.byKey(const ValueKey('pie-primary-label-style')),
    );
    primaryLabelStyle.onChanged(primaryLabelStyle.values.last);
    await tester.pump();
    final simpleOutsideStyle = tester
        .widget<BravenChartPlus>(
          find.byKey(const ValueKey('pie-showcase-chart')),
        )
        .theme
        ?.pieChartTheme
        .calloutStyle;
    expect(
      simpleOutsideStyle?.textStyle.color,
      ChartTheme.light.axisStyle.labelStyle.color,
    );
    expect(simpleOutsideStyle?.backgroundColor, const Color(0x00000000));

    final dynamic insideShareStyle = tester.widget(
      find.byKey(const ValueKey('pie-inside-share-style')),
    );
    insideShareStyle.onChanged(insideShareStyle.values.last);
    await tester.pump();
    final lightInsideStyle =
        (tester
                    .widget<BravenChartPlus>(
                      find.byKey(const ValueKey('pie-showcase-chart')),
                    )
                    .series
                    .single
                as PieChartSeries)
            .dataLabels
            .secondaryCalloutStyle;
    expect(lightInsideStyle?.textStyle.color, const Color(0xFF1A1A1A));
    expect(lightInsideStyle?.backgroundColor, const Color(0xF2FFFFFF));

    await tester.tap(find.byKey(const ValueKey('pie-preset-compact')));
    await tester.pump(const Duration(milliseconds: 300));

    final compactChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    expect(compactChart.radialLegendItemBuilder, isNotNull);
    expect(
      find.byKey(const ValueKey('pie-custom-legend-item-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('pie-preset-simple')));
    await tester.pump(const Duration(milliseconds: 300));

    final simpleChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final simpleSeries = simpleChart.series.single as PieChartSeries;
    expect(simpleChart.showLegend, isFalse);
    expect(simpleChart.theme?.backgroundColor, const Color(0xFFFFFFFF));
    expect(simpleSeries.points, hasLength(9));
    expect(simpleSeries.points.first.label, 'Subscriptions');
    expect(simpleSeries.points.first.y, closeTo(0.8404721477638243, 1e-12));
    expect(simpleSeries.points.last.label, 'Category 9');
    expect(simpleSeries.points.last.y, closeTo(9.78854068295935, 1e-12));
    expect(simpleSeries.visibleSlices, hasLength(9));
    expect(simpleSeries.dataLabels.position, PieDataLabelPosition.outside);
    expect(simpleSeries.dataLabels.content, PieDataLabelContent.category);
    expect(
      simpleSeries.dataLabels.secondaryContent,
      PieDataLabelContent.percentage,
    );
    expect(
      simpleSeries.dataLabels.secondaryPosition,
      PieDataLabelPosition.inside,
    );
    expect(simpleSeries.dataLabels.minimumShare, 0.06);
    expect(simpleSeries.dataLabels.minimumSweepDegrees, 2);
    expect(simpleSeries.dataLabels.padding, 3);
    expect(simpleSeries.dataLabels.connectorLength, 20);
    expect(simpleSeries.dataLabels.connectorWidth, 1.5);
    expect(simpleSeries.pieStyle.startAngleDegrees, -45);
    expect(simpleSeries.pieStyle.radiusFactor, 0.92);
    expect(simpleSeries.pieStyle.borderWidth, 1);
    expect(simpleSeries.pieStyle.gradient?.type, PieGradientType.radial);
    expect(simpleSeries.pieStyle.gradient?.startLightnessShift, 0.25);
    expect(simpleSeries.pieStyle.gradient?.endLightnessShift, -0.15);
    expect(simpleSeries.pieStyle.cornerTreatment, PieCornerTreatment.outerOnly);
    expect(simpleSeries.selectionStyle.effect, RadialSelectionEffect.lift);
    expect(simpleSeries.selectionStyle.liftScale, 1.18);
    expect(simpleSeries.selectionStyle.liftOffset, 8);
    expect(simpleSeries.selectionStyle.backdropBlur, 0);
    expect(simpleChart.theme?.pieChartTheme.opacity, 0.8);
    expect(simpleChart.theme?.pieChartTheme.cornerRadius, 4);
    expect(simpleChart.theme?.pieChartTheme.shadow.isVisible, isTrue);
    expect(simpleChart.theme?.pieChartTheme.selectedElevation.blurRadius, 10);
    expect(simpleChart.theme?.pieChartTheme.selectedElevation.spreadRadius, 2);
    expect(
      simpleChart.theme?.pieChartTheme.animationMode,
      PieAnimationMode.sweep,
    );
    expect(
      simpleChart.theme?.pieChartTheme.calloutStyle?.textStyle.color,
      const Color(0xFF000000),
    );
    expect(
      simpleChart.theme?.pieChartTheme.calloutStyle?.backgroundColor,
      const Color(0x00000000),
    );

    await tester.tap(find.byKey(const ValueKey('pie-preset-highContrast')));
    await tester.pump(const Duration(milliseconds: 300));

    final highContrastChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final highContrastSeries =
        highContrastChart.series.single as PieChartSeries;
    final highContrastCallout =
        highContrastChart.theme?.pieChartTheme.calloutStyle;
    expect(
      highContrastSeries.dataLabels.position,
      PieDataLabelPosition.outside,
    );
    expect(
      highContrastSeries.dataLabels.collisionStrategy,
      PieDataLabelCollisionStrategy.shiftAndHide,
    );
    expect(highContrastSeries.dataLabels.outsideOffset, 0);
    expect(highContrastSeries.pieStyle.gradient, isNull);
    expect(
      highContrastSeries.pieStyle.cornerTreatment,
      PieCornerTreatment.circularCenter,
    );
    expect(
      highContrastCallout?.backgroundColor.toARGB32(),
      const Color(0xFFFFFFFF).toARGB32(),
    );
    expect(
      highContrastCallout?.textStyle.color?.toARGB32(),
      const Color(0xFF1A1A1A).toARGB32(),
    );
    expect(highContrastCallout?.borderWidth, 2);

    await tester.tap(find.byKey(const ValueKey('pie-preset-elevated')));
    await tester.pump(const Duration(milliseconds: 300));

    final elevatedChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final elevatedSeries = elevatedChart.series.single as PieChartSeries;
    expect(elevatedSeries.pieStyle.sliceGap, 7);
    expect(elevatedSeries.pieStyle.cornerRadius, isNull);
    expect(elevatedSeries.dataLabels.position, PieDataLabelPosition.outside);
    expect(elevatedSeries.dataLabels.outsideOffset, 12);
    expect(elevatedSeries.pieStyle.gradient?.type, PieGradientType.radial);
    expect(elevatedSeries.selectionStyle.effect, RadialSelectionEffect.lift);
    expect(elevatedSeries.selectionStyle.liftScale, 1.12);
    expect(elevatedSeries.selectionStyle.liftOffset, 8);
    expect(elevatedSeries.selectionStyle.backdropBlur, 1.5);
    expect(elevatedChart.theme?.pieChartTheme.cornerRadius, 14);
    expect(
      elevatedChart.theme?.pieChartTheme.cornerTreatment,
      PieCornerTreatment.circularCenter,
    );
    expect(elevatedChart.theme?.pieChartTheme.shadow.isVisible, isTrue);
    expect(
      elevatedChart.theme?.pieChartTheme.selectedElevation.offset,
      const Offset(0, 7),
    );
    expect(elevatedChart.theme?.pieChartTheme.opacity, 0.94);

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

    await tester.tap(find.byKey(const ValueKey('pie-dataset-countries')));
    await _settleCapture(tester);

    final variableChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final variableSeries = variableChart.series.single as PieChartSeries;
    expect(variableSeries.hasVariableSliceRadius, isTrue);
    expect(variableSeries.sliceRadiusConfig?.label, 'Total area');
    expect(variableSeries.sliceRadiusConfig?.unit, 'km²');
    expect(variableSeries.points.first.pointStyle?.size, isNotNull);
    final geometrySection = tester
        .widget<ChartPageLayout>(find.byType(ChartPageLayout))
        .optionsChildren
        .whereType<OptionSection>()
        .singleWhere((section) => section.title == 'Pie geometry');
    expect(
      geometrySection.children.whereType<SliderOption>().any(
        (option) => option.label == 'Smallest slice radius',
      ),
      isTrue,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chart-workbench-mode-switcher')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);
    final variableTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(variableTable.model?.pieRadiusColumnLabel, 'Total area (km²)');
    expect(find.text('Total area (km²)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wires the complete Pie appearance and interaction editors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pumpAndSettle();

    _pieOption<SliderOption>(tester, 'pie-label-minimum-sweep').onChanged(12);
    _pieOption<SliderOption>(tester, 'pie-label-padding').onChanged(10);
    _pieOption<SliderOption>(tester, 'pie-label-inside-offset').onChanged(-14);
    _pieOption<SliderOption>(tester, 'pie-label-outside-offset').onChanged(18);
    _pieOption<SliderOption>(tester, 'pie-connector-length').onChanged(24);
    _pieOption<SliderOption>(tester, 'pie-connector-width').onChanged(2.5);
    _pieOption<BoolOption>(
      tester,
      'pie-custom-connector-color',
    ).onChanged(true);

    final dynamic gradient = _pieOption(tester, 'pie-gradient');
    gradient.onChanged(gradient.values[1]);
    await tester.pump();
    _pieOption<BoolOption>(tester, 'pie-fixed-gradient-colors').onChanged(true);
    final dynamic border = _pieOption(tester, 'pie-border-color');
    border.onChanged(border.values.last);
    await tester.pump();

    const gradientStart = Color(0xFF67E8F9);
    const gradientEnd = Color(0xFF1D4ED8);
    const fixedBorder = Color(0xFFEF4444);
    const connector = Color(0xFF0D9488);
    _pieOption<ColorOption>(
      tester,
      'pie-gradient-start-color',
    ).onChanged(gradientStart);
    _pieOption<ColorOption>(
      tester,
      'pie-gradient-end-color',
    ).onChanged(gradientEnd);
    _pieOption<ColorOption>(
      tester,
      'pie-fixed-border-color',
    ).onChanged(fixedBorder);
    _pieOption<ColorOption>(tester, 'pie-connector-color').onChanged(connector);
    _pieOption<EnumOption<LegendMarkerShape>>(
      tester,
      'pie-legend-marker-shape',
    ).onChanged(LegendMarkerShape.diamond);
    _pieOption<SliderOption>(tester, 'pie-legend-marker-size').onChanged(14);
    _pieOption<SliderOption>(tester, 'pie-legend-font-size').onChanged(12);
    _pieOption<SliderOption>(tester, 'pie-legend-opacity').onChanged(70);
    _pieOption<EnumOption<TooltipPosition>>(
      tester,
      'pie-tooltip-position',
    ).onChanged(TooltipPosition.left);
    _pieOption<BoolOption>(tester, 'pie-tooltip-follow-cursor').onChanged(true);
    _pieOption<SliderOption>(tester, 'pie-tooltip-offset').onChanged(16);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    final series = chart.series.single as PieChartSeries;
    expect(series.dataLabels.minimumSweepDegrees, 12);
    expect(series.dataLabels.padding, 10);
    expect(series.dataLabels.insideOffset, -14);
    expect(series.dataLabels.outsideOffset, 18);
    expect(series.dataLabels.connectorLength, 24);
    expect(series.dataLabels.connectorWidth, 2.5);
    expect(series.dataLabels.connectorColor, connector);
    expect(series.pieStyle.borderColor, fixedBorder);
    expect(series.pieStyle.gradient?.type, PieGradientType.linear);
    expect(series.pieStyle.gradient?.startColor, gradientStart);
    expect(series.pieStyle.gradient?.endColor, gradientEnd);
    expect(chart.theme?.legendStyle.markerShape, LegendMarkerShape.diamond);
    expect(chart.theme?.legendStyle.markerSize, 14);
    expect(chart.theme?.legendStyle.textStyle.fontSize, 12);
    expect(chart.theme?.legendStyle.opacity, 0.7);
    expect(
      chart.interactionConfig?.tooltip.preferredPosition,
      TooltipPosition.left,
    );
    expect(chart.interactionConfig?.tooltip.followCursor, isTrue);
    expect(chart.interactionConfig?.tooltip.offsetFromPoint, 16);
    expect(tester.takeException(), isNull);
  });

  testWidgets('randomizes the requested Pie data point count', (tester) async {
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pumpAndSettle();

    final dataPointCount = find.byKey(const ValueKey('pie-data-point-count'));
    var slider = tester.widget<IntSliderOption>(dataPointCount);
    expect(slider.value, 5);
    expect(slider.min, 3);
    expect(slider.max, 20);

    slider.onChanged(20);
    await tester.pumpAndSettle();

    PieChartSeries series() =>
        tester
                .widget<BravenChartPlus>(
                  find.byKey(const ValueKey('pie-showcase-chart')),
                )
                .series
                .single
            as PieChartSeries;

    expect(series().points, hasLength(20));
    expect(series().total, closeTo(100, 0.000001));
    expect(
      series().points,
      everyElement(
        predicate<ChartDataPoint>((point) {
          return point.y > 0;
        }),
      ),
    );
    final firstDistribution = series().points
        .map((point) => point.y)
        .toList(growable: false);

    tester
        .widget<ElevatedButton>(
          find.byKey(const ValueKey('regenerate-pie-values')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(series().points, hasLength(20));
    expect(series().total, closeTo(100, 0.000001));
    expect(
      series().points.map((point) => point.y),
      isNot(orderedEquals(firstDistribution)),
    );

    await tester.tap(find.byKey(const ValueKey('pie-dataset-countries')));
    await tester.pumpAndSettle();
    slider = tester.widget<IntSliderOption>(dataPointCount);
    expect(slider.value, 7);
    slider.onChanged(20);
    await tester.pumpAndSettle();

    expect(series().points, hasLength(20));
    expect(series().hasVariableSliceRadius, isTrue);
    expect(
      series().points,
      everyElement(
        predicate<ChartDataPoint>((point) {
          return point.pointStyle?.size != null && point.pointStyle!.size! > 0;
        }),
      ),
    );
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
    expect(
      find.byKey(const ValueKey('pie-presentation-selector')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('chart-page-options-button')))
          .right,
      lessThanOrEqualTo(390),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('pie-showcase-card'))).right,
      lessThanOrEqualTo(390),
    );

    await tester.tap(find.byKey(const ValueKey('chart-page-options-button')));
    await tester.pumpAndSettle();
    expect(find.text('Chart options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-fits and resizes the native Pie Split surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await _settleCapture(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chart-workbench-mode-switcher')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);

    final chartFinder = find.byKey(const ValueKey('pie-showcase-chart'));
    final tableFinder = find.byKey(
      const ValueKey('chart-workbench-data-table'),
    );
    final handleFinder = find.byKey(
      const ValueKey('chart-workbench-split-handle'),
    );
    final initialChartWidth = tester.getSize(chartFinder).width;
    final initialTableWidth = tester.getSize(tableFinder).width;

    expect(initialChartWidth, greaterThan(initialTableWidth));
    await tester.drag(handleFinder, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(chartFinder).width, greaterThan(initialChartWidth));
    expect(tester.getSize(tableFinder).width, lessThan(initialTableWidth));

    await tester.tap(handleFinder);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getSize(chartFinder).width, closeTo(initialChartWidth, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('replays each public Pie entrance mode without remounting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pumpAndSettle();

    final animationOption = find.byKey(const ValueKey('pie-animation-mode'));
    await tester.scrollUntilVisible(
      animationOption,
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final dropdown = find.descendant(
      of: animationOption,
      matching: find.byType(DropdownButtonFormField<PieAnimationMode>),
    );
    tester
        .widget<DropdownButtonFormField<PieAnimationMode>>(dropdown)
        .onChanged!(PieAnimationMode.sweep);
    await tester.pumpAndSettle();

    final chartBeforeReplay = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('pie-showcase-chart')),
    );
    expect(
      chartBeforeReplay.theme?.pieChartTheme.animationMode,
      PieAnimationMode.sweep,
    );

    await tester.tap(find.byKey(const ValueKey('replay-pie-entrance')));
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(
      tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('pie-showcase-chart')),
      ),
      same(chartBeforeReplay),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'groups small Pie slices while retaining and linking source table rows',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PieChartsPage())),
      );
      await tester.pumpAndSettle();

      final groupingOption = find.byKey(
        const ValueKey('pie-group-small-slices'),
      );
      await tester.scrollUntilVisible(
        groupingOption,
        400,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      tester
          .widget<Switch>(
            find.descendant(of: groupingOption, matching: find.byType(Switch)),
          )
          .onChanged!(true);
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('pie-showcase-chart')),
      );
      final series = chart.series.single as PieChartSeries;
      expect(series.points, hasLength(5));
      expect(series.visibleSlices, hasLength(4));
      expect(series.visibleSlices.last.point.label, 'Other');
      expect(series.visibleSlices.last.sourcePointIndices, [3, 4]);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          matching: find.text('Split'),
        ),
      );
      await _settleCapture(tester);

      var table = tester.widget<ChartDataTable>(
        find.byKey(const ValueKey('chart-workbench-data-table')),
      );
      expect(table.model?.pieRows, hasLength(5));
      expect(
        table.model?.pieRows.map((row) => row.category),
        containsAll(<String>['Training', 'Other']),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('chart-workbench-data-table')),
          matching: find.text('Training'),
        ),
      );
      await tester.pumpAndSettle();

      table = tester.widget<ChartDataTable>(
        find.byKey(const ValueKey('chart-workbench-data-table')),
      );
      expect(table.selectedPointRefs, {
        const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 3),
        const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 4),
      });
      expect(find.text('Selected: Other'), findsOneWidget);
      expect(find.textContaining('all 2 original source rows'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows native pie data and restores a captured artifact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await _settleCapture(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chart-workbench-mode-switcher')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);
    final initialTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(initialTable.model?.projectionKind, ChartTableProjectionKind.pie);
    expect(initialTable.model?.pieRows.first.category, 'Subscriptions');
    expect(initialTable.model?.pieRows.first.shareDisplay, '42.00%');
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Value (USD)'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    final hardwareCell = find.descendant(
      of: find.byKey(const ValueKey('chart-workbench-data-table')),
      matching: find.text('Hardware'),
    );
    await tester.tap(hardwareCell);
    await tester.pumpAndSettle();
    expect(find.text('Selected: Hardware'), findsOneWidget);
    final selectedTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('chart-workbench-data-table')),
    );
    expect(selectedTable.selectedPointRefs, {
      const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 2),
    });
    expect(
      find.semantics.byLabel(
        'Hardware, 16.0 USD, 16 percent, slice 3 of 5, selected',
      ),
      findsOne,
    );

    await tester.tap(hardwareCell);
    await tester.pumpAndSettle();
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(
      tester
          .widget<ChartDataTable>(
            find.byKey(const ValueKey('chart-workbench-data-table')),
          )
          .selectedPointRefs,
      isEmpty,
    );
    semantics.dispose();

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('pie-showcase-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('capture-pie-artifact')),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const ValueKey('capture-pie-artifact')));
    await _settleCapture(tester);

    expect(find.text('series.pie'), findsOneWidget);
    expect(find.text('series.pie.style.v2'), findsOneWidget);
    expect(find.text('series.pie.corner-treatment.v1'), findsOneWidget);
    expect(find.text('Schema 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Captured pie chart preview'), findsOneWidget);
    expect(find.text('Restore captured chart'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restore-pie-artifact')));
    await tester.pump();
    expect(find.byKey(const ValueKey('restored-pie-artifact')), findsOneWidget);
    expect(
      find.text('Restored from canonical JSON into a fresh chart runtime'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

T _pieOption<T extends Widget>(WidgetTester tester, String key) {
  final layout = tester.widget<ChartPageLayout>(find.byType(ChartPageLayout));
  final widgets = <Widget>[
    for (final child in layout.optionsChildren)
      if (child is OptionSection)
        ...child.children
      else if (child is StandardChartOptions)
        ...?child.additionalOptions,
  ];
  return widgets.whereType<T>().singleWhere(
    (widget) => widget.key == ValueKey(key),
  );
}

Future<void> _settleCapture(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump();
  }
  // Advance zero-delay extraction and the bounded revision refresh timer
  // without waiting for the showcase's intentionally replayable animation.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
