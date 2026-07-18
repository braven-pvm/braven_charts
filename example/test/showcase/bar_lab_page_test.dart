import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/bar_lab_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: Scaffold(body: BarLabPage()));

  testWidgets('shows a live bar review surface and style controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Bar Charts'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.text('Progress against capacity'), findsOneWidget);
    expect(find.text('Series count'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Capacity tracks'), findsOneWidget);
    expect(find.text('Value labels'), findsOneWidget);
    expect(find.text('Edge offset'), findsOneWidget);
    expect(
      tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .series
          .whereType<BarChartSeries>()
          .every((series) => series.labelStyle.padding == 8),
      isTrue,
    );
  });

  testWidgets('showcases native dense categories in chart and data views', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-categories')));
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.showXScrollbar, isTrue);
    expect(chart.xAxisConfig?.categoryAxis?.categories, hasLength(24));
    expect(chart.xAxisConfig?.labelFormatter, isNull);
    expect(find.text('Category axis'), findsOneWidget);
    expect(find.text('Label density'), findsOneWidget);
    expect(find.text('Long labels'), findsOneWidget);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('North America Enterprise'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inherits RTL direction across horizontal and vertical bars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-rtl')));
    await tester.pumpAndSettle();

    final chartFinder = find.byType(BravenChartPlus);
    var chart = tester.widget<BravenChartPlus>(chartFinder);
    expect(Directionality.of(tester.element(chartFinder)), TextDirection.rtl);
    expect(chart.xAxisConfig?.categoryAxis?.categories, contains('المؤسسات'));
    expect(chart.series.first.name, 'الإيراد الحالي');
    expect(chart.showLegend, isFalse);
    expect(
      chart.series.whereType<BarChartSeries>().every(
        (series) => series.orientation == BarOrientation.horizontal,
      ),
      isTrue,
    );

    tester
        .widget<EnumOption<BarOrientation>>(
          find.byKey(const ValueKey('bar-lab-orientation')),
        )
        .onChanged(BarOrientation.vertical);
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(chartFinder);
    expect(
      chart.series.whereType<BarChartSeries>().every(
        (series) => series.orientation == BarOrientation.vertical,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcases a first-class bullet chart preset', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-bullet')));
    await tester.pumpAndSettle();

    expect(find.text('Delivery against target'), findsOneWidget);
    expect(find.text('Bullet ranges'), findsOneWidget);
    expect(find.text('Qualitative bands'), findsOneWidget);
    expect(find.text('Measure thickness'), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final series = chart.series.single as BarChartSeries;
    expect(series.orientation, BarOrientation.horizontal);
    expect(series.bulletStyle?.ranges, hasLength(3));
    expect(series.bulletStyle?.measureThicknessFactor, 0.42);
    expect(series.targetValues, isNotEmpty);
    expect(series.trackStyle, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcases a centered diverging Likert preset', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-likert')));
    await tester.pumpAndSettle();

    expect(find.text('Product experience survey'), findsOneWidget);
    expect(find.text('Diverging scale'), findsOneWidget);
    expect(find.text('Center line'), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final series = chart.series.cast<BarChartSeries>();
    expect(series, hasLength(5));
    expect(
      series.every(
        (current) => current.layoutMode == BarLayoutMode.divergingStacked,
      ),
      isTrue,
    );
    expect(series.map((current) => current.divergingRole), [
      BarDivergingRole.negative,
      BarDivergingRole.negative,
      BarDivergingRole.neutral,
      BarDivergingRole.positive,
      BarDivergingRole.positive,
    ]);
    expect(series.first.orientation, BarOrientation.horizontal);
    expect(series.first.divergingStyle.showCenterLine, isTrue);
    expect(series.first.labelStyle.valueMode, BarLabelValueMode.percentage);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcases first-class lollipop marks and controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-lollipop')));
    await tester.pumpAndSettle();

    expect(find.text('Weekly activation score'), findsOneWidget);
    expect(find.text('Stem width'), findsOneWidget);
    expect(find.text('Marker radius'), findsOneWidget);
    expect(find.text('Corner radius'), findsNothing);
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final series = chart.series.cast<BarChartSeries>();
    expect(series, hasLength(2));
    expect(series.every((current) => current.lollipopStyle != null), isTrue);
    expect(series.first.lollipopStyle?.stemWidth, 3);
    expect(series.first.lollipopStyle?.headRadius, 8);
    expect(series.first.labelStyle.position, BarLabelPosition.outsideEnd);
    expect(chart.interactionConfig?.crosshair.mode, CrosshairMode.both);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcases a ranked Pareto bar and cumulative line composition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-pareto')));
    await tester.pumpAndSettle();

    expect(find.text('Support issues by cause'), findsOneWidget);
    expect(find.text('Cumulative line'), findsOneWidget);
    expect(find.text('Markers'), findsOneWidget);
    expect(find.text('Cumulative labels'), findsOneWidget);
    expect(find.text('Series count'), findsNothing);
    expect(find.text('Orientation'), findsNothing);
    expect(find.text('Capacity tracks'), findsNothing);

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series, hasLength(2));
    var bars = chart.series.first as BarChartSeries;
    var cumulative = chart.series.last as LineChartSeries;
    expect(
      bars.points.map((point) => point.y),
      orderedEquals([126, 84, 53, 41, 29, 18, 12]),
    );
    expect(
      bars.points.map((point) => point.label),
      orderedEquals(chart.xAxisConfig!.categoryAxis!.categories),
    );
    expect(bars.yAxisConfig?.position, YAxisPosition.left);
    expect(bars.yAxisConfig?.min, 0);
    expect(
      cumulative.points.map((point) => point.y),
      orderedEquals(cumulative.points.map((point) => point.y).toList()..sort()),
    );
    expect(cumulative.points.last.y, 100);
    expect(cumulative.yAxisConfig?.position, YAxisPosition.right);
    expect(cumulative.yAxisConfig?.min, 0);
    expect(cumulative.yAxisConfig?.max, 100);
    expect(cumulative.showDataPointMarkers, isTrue);
    expect(chart.interactionConfig?.crosshair.mode, CrosshairMode.both);

    final labelPosition = tester.widget<EnumOption<BarLabelPosition>>(
      find.byType(EnumOption<BarLabelPosition>),
    );
    expect(labelPosition.values, isNot(contains(BarLabelPosition.rangeEnds)));

    SliderOption slider(String label) => tester
        .widgetList<SliderOption>(find.byType(SliderOption))
        .singleWhere((option) => option.label == label);

    slider('Category fill').onChanged(0.8);
    slider('Bar gap').onChanged(12);
    slider('Corner radius').onChanged(14);
    slider('Edge offset').onChanged(10);
    tester
        .widget<EnumOption<BarCornerRadiusPolicy>>(
          find.byType(EnumOption<BarCornerRadiusPolicy>),
        )
        .onChanged(BarCornerRadiusPolicy.all);
    tester
        .widget<BoolOption>(find.byKey(const ValueKey('bar-lab-border')))
        .onChanged(true);
    tester
        .widget<BoolOption>(find.byKey(const ValueKey('bar-lab-gradient')))
        .onChanged(true);
    tester
        .widget<BoolOption>(
          find.byKey(const ValueKey('bar-lab-pareto-markers')),
        )
        .onChanged(false);
    tester
        .widget<BoolOption>(find.byKey(const ValueKey('bar-lab-pareto-labels')))
        .onChanged(true);
    tester
        .widget<SliderOption>(
          find.byKey(const ValueKey('bar-lab-pareto-line-width')),
        )
        .onChanged(5);
    await tester.pumpAndSettle();

    final updatedChart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    bars = updatedChart.series.first as BarChartSeries;
    cumulative = updatedChart.series.last as LineChartSeries;
    expect(bars.barWidthPercent, 0.8);
    expect(bars.barGap, 12);
    expect(bars.barStyle.cornerRadius, 14);
    expect(bars.barStyle.cornerRadiusPolicy, BarCornerRadiusPolicy.all);
    expect(bars.barStyle.border, isNotNull);
    expect(bars.barStyle.gradient, isNotNull);
    expect(bars.labelStyle.padding, 10);
    expect(cumulative.showDataPointMarkers, isFalse);
    expect(cumulative.dataPointLabels?.show, isTrue);
    expect(cumulative.strokeWidth, 5);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
    expect(
      table.model?.wideRows.map((row) => row.xDisplay),
      contains('Missing profile data'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bins continuous samples into a configurable histogram', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-histogram')));
    await tester.pumpAndSettle();

    expect(find.text('Support response-time distribution'), findsOneWidget);
    expect(find.text('Binning'), findsOneWidget);
    expect(find.text('Method'), findsOneWidget);
    expect(find.text('Bar height'), findsOneWidget);
    expect(find.text('Bin count'), findsNothing);
    expect(find.text('Series count'), findsNothing);
    expect(find.text('Orientation'), findsNothing);
    expect(find.text('Capacity tracks'), findsNothing);

    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    var series = chart.series.single as BarChartSeries;
    expect(series.points.fold<double>(0, (sum, point) => sum + point.y), 52);
    expect(series.points, hasLength(greaterThan(1)));
    expect(series.barWidthPercent, 1);
    expect(series.barGap, 0);
    expect(series.barStyle.cornerRadius, 0);
    expect(series.barStyle.border, isNotNull);
    expect(chart.showLegend, isFalse);
    expect(
      chart.xAxisConfig?.categoryAxis?.categories,
      orderedEquals(series.points.map((point) => point.label)),
    );

    tester
        .widget<EnumOption<HistogramBinningMethod>>(
          find.byKey(const ValueKey('bar-lab-histogram-method')),
        )
        .onChanged(HistogramBinningMethod.fixedCount);
    await tester.pumpAndSettle();
    expect(find.text('Bin count'), findsOneWidget);
    tester
        .widget<IntSliderOption>(
          find.byKey(const ValueKey('bar-lab-histogram-bin-count')),
        )
        .onChanged(6);
    tester
        .widget<EnumOption<HistogramValueMode>>(
          find.byKey(const ValueKey('bar-lab-histogram-value-mode')),
        )
        .onChanged(HistogramValueMode.percentage);
    tester
        .widget<BoolOption>(find.byKey(const ValueKey('bar-lab-gradient')))
        .onChanged(true);
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    series = chart.series.single as BarChartSeries;
    expect(series.points, hasLength(6));
    expect(
      series.points.fold<double>(0, (sum, point) => sum + point.y),
      closeTo(100, 0.000001),
    );
    expect(series.unit, '%');
    expect(series.barStyle.gradient, isNotNull);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between chart, data, and split presentations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);
    expect(
      find.descendant(of: switcher, matching: find.text('Chart')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: switcher, matching: find.text('Data')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: switcher, matching: find.text('Split')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    final table = find.byType(ChartDataTable);
    expect(table, findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the workbench attached when entering Waterfall in Split', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-horizontal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-waterfall')));
    await tester.pumpAndSettle();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(workbench.workbenchController!.tableState.error, isNull);
    expect(
      find.textContaining('not attached to a mounted chart'),
      findsNothing,
    );
    expect(find.text('Cash-flow bridge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows rendered shares for normalized stacks in Data view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-normalized')));
    await tester.pumpAndSettle();
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.textContaining('share (%)'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows cumulative bounds for regular stacks in Data view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-stacked')));
    await tester.pumpAndSettle();
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.textContaining('stack start'), findsWidgets);
    expect(find.textContaining('stack end'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes the number of grouped bar series', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      tester.widget<BravenChartPlus>(find.byType(BravenChartPlus)).series,
      hasLength(2),
    );

    await tester.drag(find.byType(Slider).first, const Offset(1000, 0));
    await tester.pumpAndSettle();

    expect(
      tester.widget<BravenChartPlus>(find.byType(BravenChartPlus)).series,
      hasLength(12),
    );
    expect(find.textContaining('12 series · vertical'), findsOneWidget);
  });

  testWidgets('changes the end-label edge offset', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final edgeOffsetOption = find.byWidgetPredicate(
      (widget) => widget is SliderOption && widget.label == 'Edge offset',
    );
    await tester.ensureVisible(edgeOffsetOption);
    await tester.pumpAndSettle();
    final edgeOffsetSlider = find.descendant(
      of: edgeOffsetOption,
      matching: find.byType(Slider),
    );
    await tester.drag(edgeOffsetSlider, const Offset(1000, 0));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .series
          .whereType<BarChartSeries>()
          .every((series) => series.labelStyle.padding == 20),
      isTrue,
    );
  });

  testWidgets('switches to normalized named stacks', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('100% stacked').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.series.whereType<BarChartSeries>().every(
        (series) =>
            series.layoutMode == BarLayoutMode.normalizedStacked &&
            series.groupId != null &&
            series.labelStyle.valueMode == BarLabelValueMode.percentage,
      ),
      isTrue,
    );
    expect(find.text('Named stacks'), findsOneWidget);
    expect(find.textContaining('100% stacked · 1 stack'), findsOneWidget);
  });

  testWidgets('overlays series with deterministic layer widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overlaid').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final bars = chart.series.whereType<BarChartSeries>().toList();
    expect(bars, hasLength(2));
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.overlaid),
      isTrue,
    );
    expect(bars.first.groupId, bars.last.groupId);
    expect(bars.first.overlayWidthFactor, 1);
    expect(bars.last.overlayWidthFactor, closeTo(0.78, 0.001));
    expect(bars.every((series) => series.overlayOffsetFactor == 0), isTrue);
    expect(bars.first.labelStyle.show, isFalse);
    expect(bars.last.labelStyle.show, isTrue);
    expect(find.text('Overlay groups'), findsOneWidget);
    expect(find.text('Layer inset'), findsOneWidget);
    expect(find.text('Layer offset'), findsOneWidget);
    expect(find.textContaining('overlaid · 1 group'), findsOneWidget);
  });

  testWidgets('switches between reference-driven presets', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gradient').first);
    await tester.pumpAndSettle();

    expect(find.text('Value-axis gradients'), findsOneWidget);
    expect(
      find.text(
        'Gradients follow each bar from its baseline to its value end.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('transposes the live chart when orientation changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BarOrientation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horizontal').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.series.whereType<BarChartSeries>().every(
        (series) => series.orientation == BarOrientation.horizontal,
      ),
      isTrue,
    );
    expect(chart.interactionConfig?.crosshair.mode, CrosshairMode.both);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal bars remain rendered after repeated pan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final axesPreset = find.byKey(const ValueKey('bar-lab-preset-axes'));
    await tester.ensureVisible(axesPreset);
    await tester.tap(axesPreset);
    await tester.pumpAndSettle();

    final renderBox = tester.firstRenderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final fullTransform = renderBox.transform!;
    final categoryCenter =
        (fullTransform.dataXMin + fullTransform.dataXMax) / 2;
    final categoryHalfRange = fullTransform.dataXRange / 4;
    expect(
      renderBox.restoreVisibleDataBounds(
        xMin: categoryCenter - categoryHalfRange,
        xMax: categoryCenter + categoryHalfRange,
        yMin: fullTransform.dataYMin,
        yMax: fullTransform.dataYMax,
      ),
      isTrue,
    );

    for (var index = 0; index < 6; index++) {
      renderBox.panChart(-200, 0);
      await tester.pump();
    }

    final pannedTransform = renderBox.transform!;
    final maximumWhitespace = fullTransform.dataYRange * 0.1;

    expect(tester.takeException(), isNull);
    expect(pannedTransform.transposed, isTrue);
    expect(
      pannedTransform.dataYMin,
      greaterThanOrEqualTo(fullTransform.dataYMin - maximumWhitespace - 0.001),
    );
    expect(
      _hasVisibleSeriesHit(renderBox),
      isTrue,
      reason: 'Panning must not move every horizontal bar off-screen',
    );
  });

  testWidgets('range bounds update when more series are added', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final rangePreset = find.byKey(const ValueKey('bar-lab-preset-range'));
    await tester.ensureVisible(rangePreset);
    await tester.pumpAndSettle();
    await tester.tap(rangePreset);
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.yAxis?.min, isNull);
    expect(chart.yAxis?.max, isNull);

    await tester.drag(find.byType(Slider).first, const Offset(1000, 0));
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final bars = chart.series.whereType<BarChartSeries>().toList();
    expect(bars, hasLength(12));
    expect(chart.yAxis?.min, isNull);
    expect(chart.yAxis?.max, isNull);
    expect(
      bars
          .expand((series) => series.points)
          .every((point) => point.y >= 22 && point.y <= 32),
      isTrue,
    );
    expect(
      bars
          .expand((series) => series.rangeStartValues)
          .whereType<double>()
          .every((value) => value >= 11 && value <= 24),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick-jumps to every shipped composition setup', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final presetSelector = find.byKey(const ValueKey('bar-lab-preset-wrap'));
    Future<void> tapPreset(String label) async {
      final target = find.descendant(
        of: presetSelector,
        matching: find.text(label),
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    for (final label in [
      'Capacity',
      'Targets',
      'Uncertainty',
      'Lollipop',
      'Pareto',
      'Histogram',
      'Rods',
      'Gradient',
      'Signed',
      'Overlay',
      'Offset',
      'Range',
      'Waterfall',
      'Horizontal',
      'Axes',
      'Patterns',
      'Motion',
      'States',
      'Stacked',
      '100%',
    ]) {
      expect(
        find.descendant(of: presetSelector, matching: find.text(label)),
        findsOneWidget,
      );
    }

    final firstPreset = find.byKey(const ValueKey('bar-lab-preset-capacity'));
    final lastPreset = find.byKey(const ValueKey('bar-lab-preset-normalized'));
    expect(
      tester.getTopLeft(lastPreset).dy,
      greaterThan(tester.getTopLeft(firstPreset).dy),
      reason: 'The full preset set should wrap instead of clipping offscreen.',
    );

    await tapPreset('Overlay');
    var bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Layered comparisons'), findsOneWidget);
    expect(bars, hasLength(4));
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.overlaid),
      isTrue,
    );
    expect(bars.map((series) => series.groupId).toSet(), hasLength(2));

    await tapPreset('Offset');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Offset comparisons'), findsOneWidget);
    expect(bars, hasLength(2));
    expect(bars.first.name, 'Summer 2020');
    expect(bars.last.name, 'Current result');
    expect(bars.first.overlayWidthFactor, 1);
    expect(bars.last.overlayWidthFactor, 1);
    expect(bars.first.overlayOffsetFactor, closeTo(-0.15, 0.001));
    expect(bars.last.overlayOffsetFactor, closeTo(0.15, 0.001));
    expect(bars.first.points, hasLength(5));
    expect(
      bars.last.points.every((point) => point.pointStyle?.color != null),
      isTrue,
    );

    await tapPreset('Range');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Floating temperature ranges'), findsOneWidget);
    expect(bars, hasLength(2));
    expect(bars.first.name, 'Observed');
    expect(bars.last.name, 'Forecast');
    expect(bars.first.rangeStartValues, const [14, 17, 15, 19, 16, 13, 14]);
    expect(bars.last.rangeStartValues, const [12, 16, 18, 17, 15, 14, 17]);
    expect(
      bars.every(
        (series) =>
            series.hasRangeValues &&
            series.labelStyle.valueMode == BarLabelValueMode.range &&
            series.labelStyle.position == BarLabelPosition.rangeEnds &&
            series.barStyle.cornerRadiusPolicy == BarCornerRadiusPolicy.all,
      ),
      isTrue,
    );
    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    expect(find.text('Overlaid'), findsOneWidget);
    expect(
      tester
          .widgetList<DropdownMenuItem<BarLayoutMode>>(
            find.byType(DropdownMenuItem<BarLayoutMode>),
          )
          .map((item) => item.value)
          .toSet(),
      {BarLayoutMode.grouped, BarLayoutMode.overlaid},
    );
    await tester.tap(find.text('Overlaid'));
    await tester.pumpAndSettle();
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.overlaid),
      isTrue,
    );

    await tapPreset('Waterfall');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Cash-flow bridge'), findsOneWidget);
    expect(find.text('Increase'), findsOneWidget);
    expect(find.text('Decrease'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Connectors'), findsOneWidget);
    expect(bars, hasLength(1));
    expect(bars.single.layoutMode, BarLayoutMode.waterfall);
    expect(bars.single.waterfallTotalIndices, const {6});
    expect(bars.single.waterfallDisplayValueFor(6), 91);
    expect(bars.single.labelStyle.valueMode, BarLabelValueMode.waterfall);
    expect(bars.single.waterfallStyle.connector.show, isTrue);
    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DropdownMenuItem<BarLayoutMode>>(
            find.byType(DropdownMenuItem<BarLayoutMode>),
          )
          .map((item) => item.value)
          .toSet(),
      {BarLayoutMode.waterfall},
    );
    await tester.tap(find.text('Waterfall').last);
    await tester.pumpAndSettle();

    await tapPreset('Horizontal');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    final horizontalChart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    expect(find.text('Revenue by channel'), findsOneWidget);
    expect(bars, hasLength(2));
    expect(
      bars.every(
        (series) =>
            series.orientation == BarOrientation.horizontal &&
            series.layoutMode == BarLayoutMode.grouped,
      ),
      isTrue,
    );
    expect(
      bars.first.points.map((point) => point.y),
      orderedEquals([96, 84, 73, 61, 49, 36]),
    );
    expect(horizontalChart.xAxisConfig?.label, 'Channel');
    expect(horizontalChart.yAxis?.label, 'Revenue (thousands)');
    expect(
      horizontalChart.interactionConfig?.crosshair.mode,
      CrosshairMode.both,
    );

    await tapPreset('Axes');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    final axesChart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    expect(find.text('Independent channel metrics'), findsOneWidget);
    expect(bars, hasLength(4));
    expect(
      bars.every(
        (series) =>
            series.orientation == BarOrientation.horizontal &&
            series.yAxisConfig != null &&
            series.yAxisConfig!.showCrosshairLabel,
      ),
      isTrue,
    );
    expect(
      bars.map((series) => series.yAxisConfig!.position),
      orderedEquals([
        YAxisPosition.left,
        YAxisPosition.right,
        YAxisPosition.right,
        YAxisPosition.left,
      ]),
    );
    expect(axesChart.normalizationMode, NormalizationMode.perSeries);
    expect(axesChart.maxAxesPerSide, 3);
    expect(tester.takeException(), isNull);

    await tapPreset('States');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Interactive bar states'), findsOneWidget);
    expect(find.text('Inactive opacity', skipOffstage: false), findsOneWidget);
    expect(bars, hasLength(3));
    expect(
      bars.every((series) => series.barStyle.interaction.dimmedOpacity == 0.32),
      isTrue,
    );
    expect(
      bars.expand((series) => series.points).every((point) => point.hasLabel),
      isTrue,
    );

    await tapPreset('Stacked');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Named stacked totals'), findsOneWidget);
    expect(bars, hasLength(6));
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.stacked),
      isTrue,
    );
    expect(bars.every((series) => series.labelStyle.showStackTotal), isTrue);
    expect(bars.map((series) => series.groupId).toSet(), hasLength(2));

    await tapPreset('100%');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('100% stacked composition'), findsOneWidget);
    expect(
      bars.every(
        (series) =>
            series.layoutMode == BarLayoutMode.normalizedStacked &&
            series.labelStyle.valueMode == BarLabelValueMode.percentage &&
            series.labelStyle.showStackTotal,
      ),
      isTrue,
    );
  });

  testWidgets('shows benchmark markers and transposes them with the chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-targets')));
    await tester.pumpAndSettle();

    expect(find.text('Actual against target'), findsOneWidget);
    expect(find.text('Target markers', skipOffstage: false), findsOneWidget);
    expect(find.text('Marker width', skipOffstage: false), findsOneWidget);
    expect(find.text('Marker span', skipOffstage: false), findsOneWidget);

    var bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars, hasLength(1));
    expect(bars.single.name, 'Actual');
    expect(bars.single.targetValues, const [72, 78, 85, 68, 84, 95, 76]);
    expect(bars.single.targetMarkerStyle.width, 2);

    var renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    var element = renderBox.debugElements.whereType<SeriesElement>().single;
    var geometry = element.barGeometryForPoint(0)!;
    expect(geometry.targetStart, isNotNull);
    expect(geometry.targetEnd, isNotNull);
    expect(geometry.targetStart!.dy, closeTo(geometry.targetEnd!.dy, 0.001));

    await tester.tap(find.byType(DropdownButtonFormField<BarOrientation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horizontal').last);
    await tester.pumpAndSettle();

    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars.single.orientation, BarOrientation.horizontal);
    renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    element = renderBox.debugElements.whereType<SeriesElement>().single;
    geometry = element.barGeometryForPoint(0)!;
    expect(geometry.targetStart!.dx, closeTo(geometry.targetEnd!.dx, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('coordinates dense value labels across bar series', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-labels')));
    await tester.pumpAndSettle();

    expect(find.text('Collision-aware value labels'), findsOneWidget);
    expect(find.text('Collisions', skipOffstage: false), findsOneWidget);
    expect(find.text('Plot-edge aware', skipOffstage: false), findsOneWidget);

    final bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars, hasLength(6));
    expect(
      bars.every(
        (series) =>
            series.labelStyle.collisionPolicy ==
                BarLabelCollisionPolicy.reposition &&
            series.labelStyle.plotEdgeAware &&
            series.labelStyle.backgroundColor != null &&
            series.labelStyle.callout.show,
      ),
      isTrue,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuilds advanced bars through the public tool contract', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-config')));
    await tester.pumpAndSettle();

    expect(find.text('Tool-configured analytical bars'), findsOneWidget);
    expect(find.textContaining('public tool JSON'), findsWidgets);
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final bars = chart.series.whereType<BarChartSeries>().toList();
    expect(bars, hasLength(3));
    expect(chart.xAxisConfig?.categoryAxis?.categories, const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ]);
    expect(
      bars.every(
        (series) =>
            series.targetValues.isNotEmpty &&
            series.errorLowerValues.isNotEmpty &&
            series.errorUpperValues.isNotEmpty &&
            series.barStyle.gradient != null &&
            series.barStyle.gradient!.colors.last == series.color &&
            series.trackStyle != null &&
            series.labelStyle.collisionPolicy ==
                BarLabelCollisionPolicy.reposition &&
            series.labelStyle.backgroundColor != null &&
            series.labelStyle.callout.show,
      ),
      isTrue,
    );

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
    expect(
      table.model!.series.every(
        (column) => column.auxiliaryFields.containsAll(const {
          ChartTableAuxiliaryField.target,
          ChartTableAuxiliaryField.errorLower,
          ChartTableAuxiliaryField.errorUpper,
        }),
      ),
      isTrue,
    );
    expect(find.textContaining('target'), findsWidgets);
    expect(find.textContaining('lower'), findsWidgets);
    expect(find.textContaining('upper'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows uncertainty whiskers and transposes them with the chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-uncertainty')));
    await tester.pumpAndSettle();

    expect(find.text('Estimate with uncertainty'), findsOneWidget);
    expect(find.text('Error bars', skipOffstage: false), findsOneWidget);
    expect(find.text('Line width', skipOffstage: false), findsOneWidget);
    expect(find.text('Cap span', skipOffstage: false), findsOneWidget);

    var bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars, hasLength(1));
    expect(bars.single.name, 'Estimate');
    expect(bars.single.errorLowerValues, isNotEmpty);
    expect(bars.single.errorUpperValues, isNotEmpty);
    expect(bars.single.errorBarStyle.width, 1.5);

    var renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    var element = renderBox.debugElements.whereType<SeriesElement>().single;
    var geometry = element.barGeometryForPoint(0)!;
    expect(geometry.errorStemStart, isNotNull);
    expect(geometry.errorStemEnd, isNotNull);
    expect(
      geometry.errorStemStart!.dx,
      closeTo(geometry.errorStemEnd!.dx, 0.001),
    );

    await tester.tap(find.byType(DropdownButtonFormField<BarOrientation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horizontal').last);
    await tester.pumpAndSettle();

    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars.single.orientation, BarOrientation.horizontal);
    renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    element = renderBox.debugElements.whereType<SeriesElement>().single;
    geometry = element.barGeometryForPoint(0)!;
    expect(
      geometry.errorStemStart!.dy,
      closeTo(geometry.errorStemEnd!.dy, 0.001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pairs a shared bar hue with distinct pattern encodings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-patterns')));
    await tester.pumpAndSettle();

    expect(find.text('Pattern-coded comparisons'), findsOneWidget);
    expect(find.text('Pattern encoding', skipOffstage: false), findsOneWidget);
    expect(find.text('Pattern spacing', skipOffstage: false), findsOneWidget);
    expect(find.text('Line width', skipOffstage: false), findsOneWidget);
    expect(find.text('Pattern opacity', skipOffstage: false), findsOneWidget);

    var bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars, hasLength(4));
    expect(bars.map((series) => series.color).toSet(), hasLength(1));
    expect(
      bars.map((series) => series.barStyle.pattern?.pattern).toSet(),
      hasLength(4),
    );
    expect(bars.every((series) => series.barStyle.pattern != null), isTrue);

    final patternToggle = find.byKey(
      const ValueKey('bar-lab-pattern-fills'),
      skipOffstage: false,
    );
    await tester.ensureVisible(patternToggle);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: patternToggle, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars.every((series) => series.barStyle.pattern == null), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replays bar values from the Motion preset', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-motion')));
    await tester.pumpAndSettle();

    expect(find.text('Keyed lifecycle motion'), findsOneWidget);
    expect(find.text('Sequence', skipOffstage: false), findsOneWidget);
    expect(find.text('Stagger', skipOffstage: false), findsOneWidget);
    expect(find.text('Duration', skipOffstage: false), findsOneWidget);
    expect(find.text('Animate bars', skipOffstage: false), findsOneWidget);
    expect(find.text('Sunday point', skipOffstage: false), findsOneWidget);
    expect(find.text('Forecast series', skipOffstage: false), findsOneWidget);

    final initialChart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    final initialMotion =
        (initialChart.series.first as BarChartSeries).barStyle.motion;
    expect(initialMotion.order, BarAnimationOrder.forward);
    expect(initialMotion.staggerFraction, 0.45);

    final replay = find.byKey(
      const ValueKey('bar-lab-replay-motion'),
      skipOffstage: false,
    );
    await tester.ensureVisible(replay);
    await tester.pumpAndSettle();
    await tester.tap(replay);
    await tester.pump();
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 325));

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final animatedPoints =
        (renderBox.debugElements.whereType<SeriesElement>().first.series
                as BarChartSeries)
            .points;
    final firstProgress = (animatedPoints.first.y - 54) / (82 - 54);
    final lastProgress = (animatedPoints.last.y - 76) / (96 - 76);
    expect(firstProgress, greaterThan(lastProgress));
    expect(firstProgress, greaterThan(0));
    expect(firstProgress, lessThan(1));
    expect(lastProgress, greaterThan(0));
    expect(lastProgress, lessThan(1));

    await tester.pumpAndSettle();
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect((chart.series.first as BarChartSeries).points.first.y, 82);
    expect(tester.takeException(), isNull);
  });

  testWidgets('previews keyed point and series exits from the Motion preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-motion')));
    await tester.pumpAndSettle();

    final sunday = find.byKey(
      const ValueKey('bar-lab-motion-sunday'),
      skipOffstage: false,
    );
    await tester.ensureVisible(sunday);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: sunday, matching: find.byType(Switch)),
    );
    await tester.pump();
    await tester.pump();

    var renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    var rendered = renderBox.debugElements
        .whereType<SeriesElement>()
        .map((element) => element.series)
        .whereType<BarChartSeries>()
        .toList();
    expect(rendered.first.points, hasLength(7));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .series
          .first
          .points,
      hasLength(6),
    );

    final forecast = find.byKey(
      const ValueKey('bar-lab-motion-forecast'),
      skipOffstage: false,
    );
    await tester.tap(
      find.descendant(of: forecast, matching: find.byType(Switch)),
    );
    await tester.pump();
    await tester.pump();

    renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    rendered = renderBox.debugElements
        .whereType<SeriesElement>()
        .map((element) => element.series)
        .whereType<BarChartSeries>()
        .toList();
    expect(rendered, hasLength(2));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .series
          .whereType<BarChartSeries>(),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps chart options reachable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

bool _hasVisibleSeriesHit(ChartRenderBox renderBox) {
  for (var x = 4.0; x < renderBox.plotWidth; x += 6) {
    for (var y = 4.0; y < renderBox.plotHeight; y += 6) {
      final hit = renderBox.hitTestElements(
        renderBox.plotToWidget(Offset(x, y)),
      );
      if (hit is SeriesElement) return true;
    }
  }
  return false;
}
