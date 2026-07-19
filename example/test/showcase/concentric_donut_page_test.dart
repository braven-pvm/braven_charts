import 'dart:ui' show Tristate;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/concentric_donut_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('generates the exact Concentric Donut composition in Source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    final extracted = workbench.chartController!.extractSourceDocument(
      workbench.documentOptions,
    );
    expect(extracted, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
    final directSource = ChartDartSourceGenerator.generate(
      (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value,
      options: workbench.sourceOptions,
    );
    expect(
      directSource,
      isA<ChartArtifactSuccess<ChartGeneratedSource>>(),
      reason: directSource is ChartArtifactFailure<ChartGeneratedSource>
          ? '${directSource.error.code}: ${directSource.error.message} '
                '${directSource.error.path ?? ''}'
          : null,
    );

    final switcher = find.byKey(
      const ValueKey('concentric-donut-display-mode'),
    );
    final sourceMode = find.descendant(
      of: switcher,
      matching: find.text('Source'),
    );
    await tester.ensureVisible(sourceMode);
    await tester.pump();
    await tester.tap(sourceMode);
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
      workbench.workbenchController!.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      allOf(
        contains('final concentricDonutChart = BravenChartPlus('),
        contains('concentricDonutConfig: ConcentricDonutConfig('),
        contains("ringWeights: {"),
        contains("'current': 1"),
        contains('DonutChartSeries('),
        contains('selectionStyle: RadialSelectionStyle('),
      ),
    );
    expect(find.byType(ChartSourceView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains and renders independent Concentric Donut rings', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Concentric Donut'), findsOneWidget);
    expect(find.text('Choose a presentation'), findsOneWidget);
    expect(find.text('Period comparison'), findsOneWidget);
    expect(find.text('Compact dashboard'), findsOneWidget);
    expect(find.text('Partial rings'), findsOneWidget);
    expect(find.text('Elevated gradients'), findsOneWidget);
    expect(find.text('High contrast'), findsWidgets);
    expect(find.text('Independent totals'), findsOneWidget);
    expect(find.text('Stable ring identity'), findsOneWidget);
    expect(
      find.text(
        'Tooltips, tables, selection, and grouped Other slices keep the ring name, series ID, and original source rows.',
      ),
      findsOneWidget,
    );
    expect(find.text('One shared pane'), findsOneWidget);
    expect(find.text('Outer · Current · 100 USD'), findsOneWidget);
    expect(find.text('Inner · Previous · 200 USD'), findsOneWidget);
    expect(find.text('Composition geometry'), findsOneWidget);
    expect(find.text('Shared angular frame'), findsOneWidget);
    expect(find.text('Slice appearance'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Demo data'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Demo data'), findsOneWidget);
    expect(find.text('Data points per ring'), findsOneWidget);
    expect(find.text('Center content'), findsOneWidget);
    expect(find.text('Group small categories'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Legend'), findsOneWidget);
    expect(find.text('Capture, transport, and restore'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('capture-concentric-artifact')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restore-concentric-artifact')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-workbench-data-table')),
      findsOneWidget,
    );
    expect(find.text('Ring'), findsOneWidget);
    expect(find.text('Previous period'), findsWidgets);

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    expect(chart.series, hasLength(2));
    expect(chart.series, everyElement(isA<DonutChartSeries>()));
    expect(
      chart.series.cast<DonutChartSeries>().every(
        (series) => series.sliceGroupingConfig != null,
      ),
      isTrue,
    );
    expect(
      chart.series.cast<DonutChartSeries>().every(
        (series) => series.visibleSlices.last.point.label == 'Other',
      ),
      isTrue,
    );
    expect(chart.showLegend, isFalse);
    expect(
      chart.series.cast<DonutChartSeries>().every(
        (series) => series.selectionStyle.effect == RadialSelectionEffect.lift,
      ),
      isTrue,
    );
    expect(chart.concentricDonutConfig.innerRadiusFactor, 0.36);
    expect(chart.concentricDonutConfig.outerRadiusFactor, 0.88);
    expect(chart.concentricDonutConfig.ringGap, 12);
    expect(chart.concentricDonutConfig.ringWeights['current'], 1);
    expect(chart.concentricDonutConfig.centerContent.isVisible, isTrue);
    expect(chart.donutCenterBuilder, isNotNull);
    expect(
      chart.concentricDonutConfig.legendMode,
      ConcentricDonutLegendMode.groupedByRing,
    );
    final radialSeries = chart.series.cast<DonutChartSeries>().toList();
    for (final series in radialSeries) {
      expect(series.donutStyle.sliceGap, 8);
      expect(series.donutStyle.cornerRadius, 6);
      expect(series.donutStyle.shadow?.isVisible, isTrue);
      expect(series.donutStyle.gradient?.type, PieGradientType.radial);
      expect(series.donutStyle.gradient?.startLightnessShift, 0.4);
      expect(series.donutStyle.gradient?.endLightnessShift, 0);
      expect(series.selectionStyle.effect, RadialSelectionEffect.lift);
      expect(series.selectionStyle.liftScale, 1.06);
      expect(series.selectionStyle.liftOffset, 3);
      expect(series.selectionStyle.backdropBlur, 3);
      expect(series.dataLabels.minimumShare, 0.02);
      expect(series.dataLabels.minimumSweepDegrees, 0);
      expect(series.dataLabels.secondaryContent, isNull);
    }
    expect(radialSeries[0].dataLabels.position, PieDataLabelPosition.outside);
    expect(
      radialSeries[0].dataLabels.content,
      PieDataLabelContent.categoryAndPercentage,
    );
    expect(radialSeries[0].dataLabels.calloutStyle, isNull);
    expect(radialSeries[1].dataLabels.position, PieDataLabelPosition.inside);
    expect(radialSeries[1].dataLabels.content, PieDataLabelContent.category);
    expect(
      radialSeries[1].dataLabels.calloutStyle?.backgroundColor,
      Colors.transparent,
    );

    final groupedRow = find.byKey(const ValueKey('current:3'));
    await tester.ensureVisible(groupedRow);
    await tester.pumpAndSettle();
    await tester.tap(groupedRow);
    await tester.pumpAndSettle();
    expect(
      find.text('Current period · Other · 10 USD · 2 source rows'),
      findsOneWidget,
    );
    for (final index in <int>[3, 4]) {
      expect(
        tester
            .getSemantics(find.byKey(ValueKey<String>('current:$index')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(find.byKey(ValueKey<String>('previous:$index')))
            .flagsCollection
            .isSelected,
        isNot(Tristate.isTrue),
      );
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('keeps the public split story usable at a compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('concentric-donut-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-workbench-data-table')),
      findsOneWidget,
    );
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Outer · Current · 100 USD'), findsOneWidget);
    expect(find.text('Inner · Previous · 200 USD'), findsOneWidget);

    tester.view.physicalSize = const Size(820, 760);
    await tester.pumpAndSettle();

    final groupedRow = find.byKey(const ValueKey('current:3'));
    await tester.ensureVisible(groupedRow);
    await tester.pumpAndSettle();
    await tester.tap(groupedRow);
    await tester.pumpAndSettle();
    expect(
      find.text('Current period · Other · 10 USD · 2 source rows'),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    expect(
      find.text('Current period · Other · 10 USD · 2 source rows'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes shared ring geometry, motion, and label controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-outer-radius')),
        )
        .onChanged(82);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-sweep-angle')),
        )
        .onChanged(270);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-start-angle')),
        )
        .onChanged(45);
    tester
        .widget<BoolOption>(find.byKey(const ValueKey('concentric-clockwise')))
        .onChanged(false);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-slice-gap')),
        )
        .onChanged(6);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-corner-radius')),
        )
        .onChanged(12);
    tester
        .widget<EnumOption<PieCornerTreatment>>(
          find.byKey(const ValueKey('concentric-corner-treatment')),
        )
        .onChanged(PieCornerTreatment.outerOnly);
    tester
        .widget<EnumOption<RadialSelectionEffect>>(
          find.byKey(const ValueKey('concentric-selection-effect')),
        )
        .onChanged(RadialSelectionEffect.explode);
    await tester.pump();
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-selection-offset')),
        )
        .onChanged(14);
    tester
        .widget<EnumOption<PieAnimationMode>>(
          find.byKey(const ValueKey('concentric-animation-mode')),
        )
        .onChanged(PieAnimationMode.fade);
    tester
        .widget<EnumOption<RadialDataTransitionMode>>(
          find.byKey(const ValueKey('concentric-data-transition-mode')),
        )
        .onChanged(RadialDataTransitionMode.none);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-label-inside-offset')),
        )
        .onChanged(-14);
    final dynamic labelLayoutOption = tester.widget(
      find.byKey(const ValueKey('concentric-label-layout')),
    );
    labelLayoutOption.onChanged(labelLayoutOption.values.first);
    await tester.pump();
    tester
        .widget<EnumOption<PieDataLabelPosition>>(
          find.byKey(const ValueKey('concentric-label-position')),
        )
        .onChanged(PieDataLabelPosition.outside);
    tester
        .widget<EnumOption<PieDataLabelContent>>(
          find.byKey(const ValueKey('concentric-label-content')),
        )
        .onChanged(PieDataLabelContent.categoryAndPercentage);
    await tester.pumpAndSettle();

    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-label-outside-offset')),
        )
        .onChanged(18);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    expect(chart.concentricDonutConfig.outerRadiusFactor, 0.82);
    for (final series in chart.series.cast<DonutChartSeries>()) {
      expect(series.donutStyle.sweepAngleDegrees, 270);
      expect(series.donutStyle.startAngleDegrees, 45);
      expect(series.donutStyle.clockwise, isFalse);
      expect(series.donutStyle.sliceGap, 6);
      expect(series.donutStyle.cornerRadius, 12);
      expect(series.donutStyle.cornerTreatment, PieCornerTreatment.outerOnly);
      expect(series.donutStyle.selectionExplodeOffset, 14);
      expect(series.selectionStyle.effect, RadialSelectionEffect.explode);
      expect(series.donutStyle.animationMode, PieAnimationMode.fade);
      expect(
        series.donutStyle.dataTransitionMode,
        RadialDataTransitionMode.none,
      );
      expect(series.dataLabels.position, PieDataLabelPosition.outside);
      expect(
        series.dataLabels.content,
        PieDataLabelContent.categoryAndPercentage,
      );
      expect(series.dataLabels.insideOffset, -14);
      expect(series.dataLabels.outsideOffset, 18);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('regenerates both rings without changing their totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    final before = tester
        .widget<BravenChartPlus>(
          find.byKey(const ValueKey('concentric-donut-chart')),
        )
        .series
        .cast<DonutChartSeries>()
        .map((series) => series.points.map((point) => point.y).toList())
        .toList();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('regenerate-concentric-values')),
      500,
      scrollable: find.byType(Scrollable).last,
    );

    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('regenerate-concentric-values')),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    final after = tester
        .widget<BravenChartPlus>(
          find.byKey(const ValueKey('concentric-donut-chart')),
        )
        .series
        .cast<DonutChartSeries>()
        .toList();
    expect(after[0].total, closeTo(100, 0.000001));
    expect(after[1].total, closeTo(200, 0.000001));
    expect(after[0].points.map((point) => point.y).toList(), isNot(before[0]));
    expect(after[1].points.map((point) => point.y).toList(), isNot(before[1]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('randomizes the requested data point count across both rings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    final categoryCount = find.byKey(
      const ValueKey('concentric-data-point-count'),
    );
    await tester.scrollUntilVisible(
      categoryCount,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    var slider = tester.widget<IntSliderOption>(categoryCount);
    expect(slider.value, 5);
    expect(slider.min, 3);
    expect(slider.max, 20);

    slider.onChanged(20);
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    var series = chart.series.cast<DonutChartSeries>().toList();
    expect(series, hasLength(2));
    expect(series[0].points, hasLength(20));
    expect(series[1].points, hasLength(20));
    expect(
      series[0].points.map((point) => point.label),
      orderedEquals(series[1].points.map((point) => point.label)),
    );
    expect(series[0].points.last.label, 'Other services');
    expect(series[0].total, closeTo(100, 0.000001));
    expect(series[1].total, closeTo(200, 0.000001));
    final firstCurrentDistribution = series[0].points
        .map((point) => point.y)
        .toList(growable: false);
    final firstPreviousDistribution = series[1].points
        .map((point) => point.y)
        .toList(growable: false);
    expect(
      find.textContaining('40 source points across 2 independent rings'),
      findsOneWidget,
    );

    slider = tester.widget<IntSliderOption>(categoryCount);
    slider.onChanged(3);
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    series = chart.series.cast<DonutChartSeries>().toList();
    expect(series[0].points, hasLength(3));
    expect(series[1].points, hasLength(3));
    expect(series[0].total, closeTo(100, 0.000001));
    expect(series[1].total, closeTo(200, 0.000001));

    slider = tester.widget<IntSliderOption>(categoryCount);
    slider.onChanged(20);
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    series = chart.series.cast<DonutChartSeries>().toList();
    expect(
      series[0].points.map((point) => point.y),
      isNot(orderedEquals(firstCurrentDistribution)),
    );
    expect(
      series[1].points.map((point) => point.y),
      isNot(orderedEquals(firstPreviousDistribution)),
    );
    expect(series[0].total, closeTo(100, 0.000001));
    expect(series[1].total, closeTo(200, 0.000001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('presentation cards apply complete deterministic presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('concentric-preset-partial')));
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    var series = chart.series.cast<DonutChartSeries>().toList();
    expect(chart.concentricDonutConfig.innerRadiusFactor, 0.38);
    expect(
      chart.concentricDonutConfig.legendMode,
      ConcentricDonutLegendMode.flat,
    );
    expect(chart.theme?.legendStyle.position, LegendPosition.centerRight);
    expect(chart.theme?.legendStyle.orientation, LegendOrientation.vertical);
    expect(series.first.donutStyle.sweepAngleDegrees, 260);
    expect(series.first.donutStyle.startAngleDegrees, -140);
    expect(series.first.dataLabels.position, PieDataLabelPosition.outside);
    expect(series.first.sliceGroupingConfig, isNull);
    expect(
      series.first.points.first.pointStyle?.color,
      const Color(0xFF386641),
    );

    await tester.tap(find.byKey(const ValueKey('concentric-preset-elevated')));
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    series = chart.series.cast<DonutChartSeries>().toList();
    expect(chart.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(chart.concentricDonutConfig.innerRadiusFactor, 0.38);
    expect(chart.concentricDonutConfig.outerRadiusFactor, 0.94);
    expect(chart.concentricDonutConfig.ringGap, 8);
    expect(chart.concentricDonutConfig.ringWeights['current'], 1.25);
    expect(chart.radialLegendItemBuilder, isNull);
    expect(chart.theme?.legendStyle.markerSize, 9);
    expect(chart.theme?.legendStyle.textStyle.fontSize, 10);
    expect(series.first.donutStyle.opacity, 1);
    expect(series.first.donutStyle.cornerRadius, 11);
    expect(series.first.donutStyle.sliceGap, 4);
    expect(series.first.donutStyle.shadow?.isVisible, isTrue);
    expect(series.first.donutStyle.shadow?.blurRadius, 12);
    expect(series.first.donutStyle.gradient?.type, PieGradientType.radial);
    expect(series.first.donutStyle.gradient?.startLightnessShift, 0.24);
    expect(series.first.donutStyle.gradient?.endLightnessShift, -0.14);
    expect(series.first.donutStyle.selectedElevation?.blurRadius, 20);
    expect(series.first.donutStyle.animationMode, PieAnimationMode.grow);
    expect(series.first.selectionStyle.effect, RadialSelectionEffect.lift);
    expect(series.first.selectionStyle.liftScale, 1.14);
    expect(series.first.selectionStyle.liftOffset, 8);
    expect(series.first.selectionStyle.backdropBlur, 2);
    expect(
      series.first.points.first.pointStyle?.color,
      const Color(0xFFE63946),
    );
    expect(series.first.dataLabels.position, PieDataLabelPosition.outside);
    expect(
      series.first.dataLabels.content,
      PieDataLabelContent.categoryAndPercentage,
    );
    expect(series.last.dataLabels.position, PieDataLabelPosition.inside);
    expect(series.last.dataLabels.content, PieDataLabelContent.category);
    expect(
      chart.concentricDonutConfig.centerContent.valueMode,
      DonutCenterValueMode.selectedOrTotal,
    );
    final title = tester.widget<Text>(find.text('Revenue mix by period'));
    final subtitle = tester.widget<Text>(
      find.text('Each ring calculates share against its own total'),
    );
    expect(title.style?.color, ChartTheme.dark.axisStyle.titleStyle.color);
    expect(subtitle.style?.color, ChartTheme.dark.axisStyle.labelStyle.color);
    final centerLabel = tester.widget<Text>(
      find.byKey(const ValueKey('concentric-runtime-center-label')),
    );
    final centerValue = tester.widget<Text>(
      find.byKey(const ValueKey('concentric-runtime-center-value')),
    );
    expect(
      centerLabel.style?.color,
      ChartTheme.dark.axisStyle.labelStyle.color,
    );
    expect(
      centerValue.style?.color,
      ChartTheme.dark.axisStyle.labelStyle.color,
    );

    await tester.tap(
      find.byKey(const ValueKey('concentric-preset-highContrast')),
    );
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    series = chart.series.cast<DonutChartSeries>().toList();
    expect(
      chart.theme?.backgroundColor,
      ChartTheme.highContrast.backgroundColor,
    );
    expect(chart.concentricDonutConfig.order, ConcentricRingOrder.innerToOuter);
    expect(series.first.donutStyle.gradient, isNull);
    expect(series.first.donutStyle.borderWidth, 2);
    expect(series.first.donutStyle.borderColor, Colors.black);
    expect(series.first.dataLabels.minimumShare, 0);
    expect(series.first.dataLabels.calloutStyle?.backgroundColor, Colors.black);
    expect(series.first.sliceGroupingConfig, isNull);

    await tester.tap(
      find.byKey(const ValueKey('concentric-preset-comparison')),
    );
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    series = chart.series.cast<DonutChartSeries>().toList();
    expect(chart.concentricDonutConfig.innerRadiusFactor, 0.36);
    expect(chart.concentricDonutConfig.order, ConcentricRingOrder.outerToInner);
    expect(series.first.donutStyle.sweepAngleDegrees, 360);
    expect(series.first.donutStyle.opacity, 1);
    expect(series.first.donutStyle.shadow?.isVisible, isTrue);
    expect(series.first.sliceGroupingConfig, isNotNull);
    expect(series.first.selectionStyle.effect, RadialSelectionEffect.lift);
    expect(series.first.selectionStyle.liftScale, 1.06);
    expect(chart.showLegend, isFalse);
    expect(chart.radialLegendItemBuilder, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes portable and runtime center presentation controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 7000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    tester
        .widget<EnumOption<DonutCenterValueMode>>(
          find.byKey(const ValueKey('concentric-center-value-mode')),
        )
        .onChanged(DonutCenterValueMode.custom);
    await tester.pump();
    tester
        .widget<TextOption>(
          find.byKey(const ValueKey('concentric-center-label')),
        )
        .onChanged('Portfolio');
    tester
        .widget<TextOption>(
          find.byKey(const ValueKey('concentric-center-custom-value')),
        )
        .onChanged('2 cycles');
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-center-label-size')),
        )
        .onChanged(14);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-center-value-size')),
        )
        .onChanged(28);
    tester
        .widget<EnumOption<FontWeight>>(
          find.byKey(const ValueKey('concentric-center-label-weight')),
        )
        .onChanged(FontWeight.w600);
    tester
        .widget<EnumOption<FontWeight>>(
          find.byKey(const ValueKey('concentric-center-value-weight')),
        )
        .onChanged(FontWeight.w800);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('concentric-center-theme-colors')),
        )
        .onChanged(false);
    await tester.pump();

    const labelColor = Color(0xFF0D9488);
    const valueColor = Color(0xFFF8FAFC);
    tester
        .widget<ColorOption>(
          find.byKey(const ValueKey('concentric-center-label-color')),
        )
        .onChanged(labelColor);
    tester
        .widget<ColorOption>(
          find.byKey(const ValueKey('concentric-center-value-color')),
        )
        .onChanged(valueColor);
    final dynamic surfaceOption = tester.widget(
      find.byKey(const ValueKey('concentric-center-surface')),
    );
    surfaceOption.onChanged(surfaceOption.values.last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    final center = chart.concentricDonutConfig.centerContent;
    expect(center.label, 'Portfolio');
    expect(center.valueMode, DonutCenterValueMode.custom);
    expect(center.customValue, '2 cycles');
    expect(center.labelStyle?.textStyle.fontSize, 14);
    expect(center.labelStyle?.textStyle.fontWeight, FontWeight.w600);
    expect(center.labelStyle?.textStyle.color, labelColor);
    expect(center.valueStyle?.textStyle.fontSize, 28);
    expect(center.valueStyle?.textStyle.fontWeight, FontWeight.w800);
    expect(center.valueStyle?.textStyle.color, valueColor);
    expect(chart.donutCenterBuilder, isNotNull);

    final runtimeLabel = tester.widget<Text>(
      find.byKey(const ValueKey('concentric-runtime-center-label')),
    );
    final runtimeValue = tester.widget<Text>(
      find.byKey(const ValueKey('concentric-runtime-center-value')),
    );
    expect(runtimeLabel.data, 'Portfolio');
    expect(runtimeLabel.style?.color, labelColor);
    expect(runtimeLabel.style?.fontSize, 14);
    expect(runtimeValue.data, '2 cycles');
    expect(runtimeValue.style?.color, valueColor);
    expect(runtimeValue.style?.fontSize, 28);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes complete radial appearance and interaction controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 10000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
    );
    await tester.pumpAndSettle();

    final dynamic themeOption = tester.widget(
      find.byKey(const ValueKey('concentric-theme')),
    );
    themeOption.onChanged(themeOption.values[1]);
    final dynamic paletteOption = tester.widget(
      find.byKey(const ValueKey('concentric-palette')),
    );
    paletteOption.onChanged(paletteOption.values[2]);
    final dynamic gradientOption = tester.widget(
      find.byKey(const ValueKey('concentric-gradient')),
    );
    gradientOption.onChanged(gradientOption.values[1]);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('concentric-fixed-gradient-colors')),
        )
        .onChanged(true);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-selection-lift-scale')),
        )
        .onChanged(118);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-selection-lift-offset')),
        )
        .onChanged(10);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-selection-backdrop-blur')),
        )
        .onChanged(3);
    tester
        .widget<SliderOption>(find.byKey(const ValueKey('concentric-opacity')))
        .onChanged(62);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-border-width')),
        )
        .onChanged(2.5);
    final dynamic borderOption = tester.widget(
      find.byKey(const ValueKey('concentric-border-color')),
    );
    borderOption.onChanged(borderOption.values[3]);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('concentric-slice-shadow')),
        )
        .onChanged(true);
    final dynamic glowColorOption = tester.widget(
      find.byKey(const ValueKey('concentric-glow-color')),
    );
    glowColorOption.onChanged(glowColorOption.values[1]);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-glow-blur')),
        )
        .onChanged(20);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-glow-spread')),
        )
        .onChanged(4);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-glow-opacity')),
        )
        .onChanged(70);
    final dynamic labelLayoutOption = tester.widget(
      find.byKey(const ValueKey('concentric-label-layout')),
    );
    labelLayoutOption.onChanged(labelLayoutOption.values.first);
    await tester.pump();
    tester
        .widget<EnumOption<PieDataLabelPosition>>(
          find.byKey(const ValueKey('concentric-label-position')),
        )
        .onChanged(PieDataLabelPosition.outside);
    await tester.pump();
    final dynamic calloutOption = tester.widget(
      find.byKey(const ValueKey('concentric-callout-style')),
    );
    calloutOption.onChanged(calloutOption.values[3]);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-label-minimum-sweep')),
        )
        .onChanged(12);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-label-padding')),
        )
        .onChanged(10);
    tester
        .widget<EnumOption<PieDataLabelCollisionStrategy>>(
          find.byKey(const ValueKey('concentric-label-collision')),
        )
        .onChanged(PieDataLabelCollisionStrategy.shift);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-connector-length')),
        )
        .onChanged(24);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-connector-width')),
        )
        .onChanged(2.5);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('concentric-custom-connector-color')),
        )
        .onChanged(true);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('concentric-show-legend')),
        )
        .onChanged(true);
    await tester.pump();
    tester
        .widget<EnumOption<LegendPosition>>(
          find.byKey(const ValueKey('concentric-legend-position')),
        )
        .onChanged(LegendPosition.centerRight);
    tester
        .widget<EnumOption<LegendOrientation>>(
          find.byKey(const ValueKey('concentric-legend-orientation')),
        )
        .onChanged(LegendOrientation.vertical);
    tester
        .widget<EnumOption<LegendMarkerShape>>(
          find.byKey(const ValueKey('concentric-legend-marker-shape')),
        )
        .onChanged(LegendMarkerShape.diamond);
    final dynamic legendContentOption = tester.widget(
      find.byKey(const ValueKey('concentric-legend-content')),
    );
    legendContentOption.onChanged(legendContentOption.values[1]);
    final dynamic tooltipStyleOption = tester.widget(
      find.byKey(const ValueKey('concentric-tooltip-style')),
    );
    tooltipStyleOption.onChanged(tooltipStyleOption.values[2]);
    tester
        .widget<EnumOption<TooltipPosition>>(
          find.byKey(const ValueKey('concentric-tooltip-position')),
        )
        .onChanged(TooltipPosition.left);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('concentric-tooltip-follow-cursor')),
        )
        .onChanged(true);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('concentric-tooltip-offset')),
        )
        .onChanged(16);
    await tester.pumpAndSettle();

    const gradientStart = Color(0xFF67E8F9);
    const gradientEnd = Color(0xFF1D4ED8);
    const fixedBorder = Color(0xFFEF4444);
    const connector = Color(0xFF0D9488);
    tester
        .widget<ColorOption>(
          find.byKey(const ValueKey('concentric-gradient-start-color')),
        )
        .onChanged(gradientStart);
    tester
        .widget<ColorOption>(
          find.byKey(const ValueKey('concentric-gradient-end-color')),
        )
        .onChanged(gradientEnd);
    tester
        .widget<ColorOption>(
          find.byKey(const ValueKey('concentric-fixed-border-color')),
        )
        .onChanged(fixedBorder);
    tester
        .widget<ColorOption>(
          find.byKey(const ValueKey('concentric-connector-color')),
        )
        .onChanged(connector);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );
    expect(chart.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(chart.radialLegendItemBuilder, isNotNull);
    expect(chart.theme?.legendStyle.position, LegendPosition.centerRight);
    expect(chart.theme?.legendStyle.orientation, LegendOrientation.vertical);
    expect(chart.theme?.legendStyle.markerShape, LegendMarkerShape.diamond);
    expect(
      chart.interactionConfig?.tooltip.preferredPosition,
      TooltipPosition.left,
    );
    expect(chart.interactionConfig?.tooltip.followCursor, isTrue);
    expect(chart.interactionConfig?.tooltip.offsetFromPoint, 16);

    for (final series in chart.series.cast<DonutChartSeries>()) {
      final style = series.donutStyle;
      expect(series.points.first.pointStyle?.color, const Color(0xFFE63946));
      expect(style.opacity, 0.62);
      expect(style.borderWidth, 2.5);
      expect(style.borderColor, fixedBorder);
      expect(style.gradient?.type, PieGradientType.linear);
      expect(style.gradient?.startColor, gradientStart);
      expect(style.gradient?.endColor, gradientEnd);
      expect(style.shadow?.isVisible, isTrue);
      expect(style.selectedElevation?.blurRadius, 20);
      expect(style.selectedElevation?.spreadRadius, 4);
      expect(style.selectedElevation?.opacity, 0.7);
      expect(series.selectionStyle.effect, RadialSelectionEffect.lift);
      expect(series.selectionStyle.liftScale, 1.18);
      expect(series.selectionStyle.liftOffset, 10);
      expect(series.selectionStyle.backdropBlur, 3);
      expect(series.dataLabels.minimumSweepDegrees, 12);
      expect(series.dataLabels.padding, 10);
      expect(
        series.dataLabels.collisionStrategy,
        PieDataLabelCollisionStrategy.shift,
      );
      expect(series.dataLabels.connectorLength, 24);
      expect(series.dataLabels.connectorWidth, 2.5);
      expect(series.dataLabels.connectorColor, connector);
      expect(series.dataLabels.calloutStyle?.backgroundColor, Colors.black);
    }
    expect(tester.takeException(), isNull);
  });
}
