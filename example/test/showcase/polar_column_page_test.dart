import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/polar_column_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Polar Column guide renders the real public chart model', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Polar Column'), findsOneWidget);
    expect(find.text('Standard columns'), findsOneWidget);
    expect(find.text('Nightingale rose'), findsOneWidget);
    expect(find.text('Partial sweep'), findsOneWidget);
    expect(find.text('Layered comparison'), findsOneWidget);
    expect(find.text('Grouped comparison'), findsOneWidget);
    expect(find.text('Stacked comparison'), findsOneWidget);
    expect(find.text('Targets & thresholds'), findsOneWidget);
    expect(find.text('Ranges & uncertainty'), findsOneWidget);
    final chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.series.single, isA<PolarColumnChartSeries>());
    expect(chart.polarChartConfig.pane.sweepAngleDegrees, 360);
    expect(chart.polarChartConfig.angularAxis.maximumVisibleLabels, 24);
    expect(chart.polarChartConfig.angularAxis.maximumVisibleGridLines, 72);
    expect(
      (chart.series.single as PolarColumnChartSeries)
          .polarStyle
          .maximumVisibleDataLabels,
      24,
    );
    expect(find.text('Chart appearance'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Category colors'), findsOneWidget);
    expect(find.byType(ChartColorPalette), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Maximum category labels'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Maximum category labels'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Maximum value labels'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Maximum value labels'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Maximum grid spokes'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Maximum grid spokes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('options are grouped by the property users are editing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump();

    final panel = tester.widget<OptionsPanel>(find.byType(OptionsPanel));
    OptionSection section(String title) => panel.children
        .whereType<OptionSection>()
        .singleWhere((candidate) => candidate.title == title);

    final categories = section('Categories');
    expect(
      categories.children.whereType<IntSliderOption>().map(
        (item) => item.label,
      ),
      contains('Category count'),
    );
    expect(
      categories.children.whereType<EnumOption>().map((item) => item.label),
      contains('Category colors'),
    );
    expect(
      categories.children.whereType<SliderOption>().map((item) => item.label),
      containsAll(['Column gap', 'Outer padding']),
    );

    final labels = section('Labels');
    expect(
      labels.children.whereType<BoolOption>().map((item) => item.label),
      containsAll([
        'Show category labels',
        'Show radial labels',
        'Show values inside columns',
      ]),
    );
    final gridAndAxes = section('Grid & axes');
    expect(
      gridAndAxes.children.whereType<BoolOption>().map((item) => item.label),
      containsAll(['Show angular grid', 'Show radial grid']),
    );
    expect(
      gridAndAxes.children.whereType<SliderOption>().map((item) => item.label),
      containsAll(['Axis line width', 'Grid line width']),
    );

    final geometry = section('Polar geometry & scale');
    expect(
      geometry.children.whereType<SliderOption>().map((item) => item.label),
      containsAll([
        'Start angle',
        'Sweep angle',
        'Inner radius',
        'Outer radius',
      ]),
    );
    expect(
      geometry.children.whereType<EnumOption>().map((item) => item.label),
      contains('Scale mode'),
    );
    final columns = section('Columns');
    expect(
      columns.children.whereType<EnumOption>().map((item) => item.label),
      contains('Corner placement'),
    );
    final cornerPlacement = columns.children
        .whereType<EnumOption<PolarColumnCornerRadiusMode>>()
        .singleWhere((item) => item.label == 'Corner placement');
    expect(cornerPlacement.values, PolarColumnCornerRadiusMode.values);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appearance controls drive public chart styling', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.theme?.backgroundColor, ChartTheme.light.backgroundColor);
    expect(
      chart.theme?.gridStyle.majorColor,
      ChartTheme.light.gridStyle.majorColor,
    );
    expect(
      (chart.series.single as PolarColumnChartSeries)
          .points
          .first
          .pointStyle
          ?.color,
      const Color(0xFF2196F3),
    );

    await tester.tap(find.text('Theme colors'));
    await tester.pumpAndSettle();
    expect(find.text('Ocean'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
    expect(find.text('Monochrome'), findsOneWidget);
    await tester.tap(find.text('Ocean').last);
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(
      (chart.series.single as PolarColumnChartSeries)
          .points
          .first
          .pointStyle
          ?.color,
      const Color(0xFF2563EB),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Polar colors use the shared custom color selector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('polar-canvas-color-custom')));
    await tester.pumpAndSettle();

    expect(find.text('Select Color'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Select Color'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Polar color overrides can clear or toggle back to theme defaults',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PolarColumnPage())),
      );
      await tester.pumpAndSettle();

      final clear = find.byKey(const ValueKey('polar-canvas-color-clear'));
      final red = find.byKey(
        ValueKey('polar-canvas-color-${Colors.red.toARGB32()}'),
      );
      expect(clear, findsOneWidget);

      await tester.tap(red);
      await tester.pump();
      var chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('polar-column-live-chart')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      expect(chart.theme?.backgroundColor, Colors.red);

      await tester.tap(red);
      await tester.pump();
      chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('polar-column-live-chart')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      expect(chart.theme?.backgroundColor, ChartTheme.light.backgroundColor);

      await tester.tap(red);
      await tester.pump();
      await tester.tap(clear);
      await tester.pump();
      chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('polar-column-live-chart')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      expect(chart.theme?.backgroundColor, ChartTheme.light.backgroundColor);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('feature guide cards use compact content-driven height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();

    final pageScroll = find.descendant(
      of: find.byKey(const ValueKey('polar-column-showcase-scroll')),
      matching: find.byType(Scrollable),
    );
    final firstCard = find.byKey(const ValueKey('polar-feature-card-0'));
    await tester.scrollUntilVisible(
      firstCard,
      500,
      scrollable: pageScroll.first,
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(firstCard).height, lessThan(150));
    expect(tester.takeException(), isNull);
  });

  testWidgets('presentation cards change the real series and pane contract', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('polar-presentation-rose')));
    await tester.pump();
    var chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(
      (chart.series.single as PolarColumnChartSeries).preset,
      PolarColumnPreset.rose,
    );
    expect(
      chart.polarChartConfig.radialAxis.scaleMode,
      PolarRadialScaleMode.areaCorrect,
    );

    await tester.tap(find.byKey(const ValueKey('polar-presentation-partial')));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.polarChartConfig.pane.sweepAngleDegrees, 240);
    expect(chart.polarChartConfig.pane.innerRadiusFactor, 0.28);

    await tester.tap(find.byKey(const ValueKey('polar-presentation-layered')));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.series, hasLength(2));
    expect(chart.series.map((series) => series.id), [
      'showcase-polar-capacity',
      'showcase-polar-observed',
    ]);
    expect(
      chart.series.every((series) => series is PolarColumnChartSeries),
      isTrue,
    );
    expect(chart.series.map((series) => series.unit).toSet(), {'orders'});

    await tester.tap(find.byKey(const ValueKey('polar-presentation-grouped')));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.series, hasLength(3));
    expect(chart.series.map((series) => series.name), [
      'North',
      'South',
      'West',
    ]);
    expect(
      chart.polarChartConfig.composition.mode,
      PolarColumnCompositionMode.grouped,
    );
    expect(chart.polarChartConfig.composition.groupInnerPadding, 0.12);

    await tester.tap(find.byKey(const ValueKey('polar-presentation-stacked')));
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.series, hasLength(3));
    expect(chart.series.map((series) => series.name), [
      'New accounts',
      'Expansion',
      'Churn',
    ]);
    expect(
      chart.polarChartConfig.composition.mode,
      PolarColumnCompositionMode.stacked,
    );
    expect(
      chart.series
          .whereType<PolarColumnChartSeries>()
          .expand((series) => series.points)
          .any((point) => point.y < 0),
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('polar-presentation-references')),
    );
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    final referenceSeries = chart.series.single as PolarColumnChartSeries;
    expect(referenceSeries.targetValues, [78, 62, 80, 55, 72, 88]);
    expect(referenceSeries.targetMarkerStyle.width, 3);
    expect(chart.polarChartConfig.thresholds.single.value, 80);
    expect(chart.polarChartConfig.thresholds.single.label, 'Capacity');

    await tester.tap(
      find.byKey(const ValueKey('polar-presentation-intervals')),
    );
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    final intervalSeries = chart.series.single as PolarColumnChartSeries;
    expect(intervalSeries.intervalLowerValues, [63, 49, 70, 38, 57, 76]);
    expect(intervalSeries.intervalUpperValues, [84, 69, 94, 56, 79, 103]);
    expect(
      intervalSeries.intervalStyle.display,
      PolarColumnIntervalDisplay.whisker,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('interval preset exposes bounds in table and generated source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('polar-presentation-intervals')),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
              .workbenchController
              ?.tableModel !=
          null,
    );
    final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
    expect(table.model?.hasPolarIntervals, isTrue);
    expect(table.model?.polarRows.first.intervalLowerDisplay, '63.00');
    expect(table.model?.polarRows.first.intervalUpperDisplay, '84.00');
    expect(
      find.byKey(const ValueKey('chart-table-header-interval-lower')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-table-header-interval-upper')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
              .workbenchController
              ?.generatedSource !=
          null,
    );
    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    final source = workbench.workbenchController?.generatedSource?.source;
    expect(source, contains('intervalLowerValues:'));
    expect(source, contains('intervalUpperValues:'));
    expect(source, contains('PolarColumnIntervalStyle('));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reference preset exposes targets in table and generated source',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PolarColumnPage())),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('polar-presentation-references')),
      );
      await tester.pumpAndSettle();

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await _pumpUntil(
        tester,
        () =>
            tester
                .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
                .workbenchController
                ?.tableModel !=
            null,
      );
      final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
      expect(table.model?.hasPolarTargets, isTrue);
      expect(table.model?.polarRows.first.targetDisplay, '78.00');

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await _pumpUntil(
        tester,
        () =>
            tester
                .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
                .workbenchController
                ?.generatedSource !=
            null,
      );
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      final source = workbench.workbenchController?.generatedSource?.source;
      expect(source, contains('targetValues:'));
      expect(source, contains('PolarColumnTargetMarkerStyle('));
      expect(source, contains('PolarThreshold('));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Workbench exposes Polar chart, value table, split, and source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('polar-presentation-stacked')));
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
              .workbenchController
              ?.tableModel !=
          null,
    );
    final dataWorkbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(
      dataWorkbench.workbenchController?.tableModel,
      isNotNull,
      reason:
          '${dataWorkbench.workbenchController?.tableState.phase}: ${dataWorkbench.workbenchController?.tableState.error?.message}',
    );
    final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
    expect(table.model?.projectionKind, ChartTableProjectionKind.polar);
    expect(table.model?.polarRows, hasLength(18));
    expect(table.model?.polarRows.map((row) => row.seriesName).toSet(), {
      'New accounts',
      'Expansion',
      'Churn',
    });
    expect(table.model?.polarRows.any((row) => row.valueRaw < 0), isTrue);
    expect(table.model?.pieRows, isEmpty);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-workbench-split-handle')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<BravenChartWorkbench>(find.byType(BravenChartWorkbench))
              .workbenchController
              ?.generatedSource !=
          null,
    );
    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(
      workbench.workbenchController?.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    final source = workbench.workbenchController?.generatedSource?.source;
    expect(
      RegExp('PolarColumnChartSeries\\(').allMatches(source!),
      hasLength(3),
    );
    expect(source, contains('polarChartConfig: PolarChartConfig('));
    expect(source, contains('PolarColumnCompositionMode.stacked'));
    expect(source, contains('-21.0'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
