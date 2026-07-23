import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/data/polar_showcase_randomizer.dart';
import 'package:braven_charts_example/showcase/pages/polar_column_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:braven_charts_example/showcase/widgets/showcase_randomizer.dart';
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

    expect(find.text('Polar Column Charts'), findsOneWidget);
    expect(find.text('Standard columns'), findsOneWidget);
    expect(find.text('Nightingale rose'), findsOneWidget);
    expect(find.text('Partial sweep'), findsOneWidget);
    expect(find.text('Layered comparison'), findsOneWidget);
    expect(find.text('Grouped comparison'), findsOneWidget);
    expect(find.text('Stacked comparison'), findsOneWidget);
    expect(find.text('Targets & thresholds'), findsOneWidget);
    expect(find.text('Ranges & uncertainty'), findsOneWidget);
    expect(find.byKey(const ValueKey('polar-playground')), findsOneWidget);
    expect(find.byKey(const ValueKey('polar-randomizer-next')), findsNothing);
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

    final categoryLabels = section('Category labels');
    expect(
      categoryLabels.children.whereType<BoolOption>().map((item) => item.label),
      contains('Show category labels'),
    );
    expect(
      categoryLabels.children.whereType<SliderOption>().map(
        (item) => item.label,
      ),
      containsAll(['Text size', 'Outer offset']),
    );
    final valueLabels = section('Inside value labels');
    expect(
      valueLabels.children.whereType<BoolOption>().map((item) => item.label),
      contains('Show values'),
    );
    expect(
      valueLabels.children.whereType<SliderOption>().map((item) => item.label),
      containsAll(['Text size', 'Radial position']),
    );
    final radialLabels = section('Radial axis labels');
    expect(
      radialLabels.children.whereType<BoolOption>().map((item) => item.label),
      contains('Show radial labels'),
    );
    expect(
      radialLabels.children.whereType<SliderOption>().map((item) => item.label),
      containsAll(['Text size', 'Angular adjustment', 'Ray offset']),
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

    final fillAndElevation = section('Column fill & elevation');
    expect(
      fillAndElevation.children.whereType<BoolOption>().map(
        (item) => item.label,
      ),
      containsAll(['Gradient fill', 'Column shadow']),
    );
    final motion = section('Motion');
    expect(
      motion.children.whereType<EnumOption>().map((item) => item.label),
      contains('Entrance'),
    );

    expect(panel.headerEditor, isNull);
    await _enterPlayground(tester);
    final playgroundPanel = tester.widget<OptionsPanel>(
      find.byType(OptionsPanel),
    );
    expect(playgroundPanel.headerEditor, isA<PropertyRandomizerSection>());
    await _openRandomizerEditor(tester);
    expect(find.byKey(const ValueKey('polar-randomizer-seed')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('polar-randomizer-playback-interval')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'seeded randomizer applies a complete reproducible configuration',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PolarColumnPage())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await _enterPlayground(tester);
      expect(find.text('Randomize all'), findsOneWidget);
      await _openRandomizerEditor(tester);
      final seedOption = tester.widget<IntSliderOption>(
        find.byKey(const ValueKey('polar-randomizer-seed')),
      );
      seedOption.onChanged(317);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('polar-randomizer-generate')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();

      final generated = PolarShowcaseRandomizer.generate(317);
      expect(find.text('Generated seed 317'), findsOneWidget);
      _expectGeneratedChart(tester, generated);

      await tester.tap(find.byKey(const ValueKey('polar-randomizer-next')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Generated seed 318'), findsOneWidget);
      _expectGeneratedChart(tester, PolarShowcaseRandomizer.generate(318));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'randomized example plays on schedule, pauses, and yields to authored presets',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PolarColumnPage())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await _enterPlayground(tester);
      await _openRandomizerEditor(tester);
      tester
          .widget<IntSliderOption>(
            find.byKey(const ValueKey('polar-randomizer-playback-interval')),
          )
          .onChanged(2);
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('polar-randomizer-playback-header')),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Generated seed 48'), findsOneWidget);
      expect(find.text('Pause sequence'), findsWidgets);
      expect(find.text('Playing seed 48'), findsNothing);
      _expectGeneratedChart(tester, PolarShowcaseRandomizer.generate(48));

      await tester.pump(const Duration(milliseconds: 1800));
      expect(find.text('Generated seed 48'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Generated seed 49'), findsOneWidget);
      _expectGeneratedChart(tester, PolarShowcaseRandomizer.generate(49));

      await tester.tap(
        find.byKey(const ValueKey('polar-randomizer-playback-header')),
      );
      await tester.pump();
      expect(find.text('Play sequence'), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Generated seed 49'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('polar-randomizer-playback-header')),
      );
      await tester.pump();
      expect(find.text('Generated seed 50'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('polar-presentation-standard')),
      );
      await tester.pump();
      expect(find.text('Generated seed 50'), findsNothing);
      expect(
        find.byKey(const ValueKey('polar-randomizer-playback-header')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Generated seed 51'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('seed matrix renders every Polar presentation without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _enterPlayground(tester);
    final randomizer =
        (tester.widget<OptionsPanel>(find.byType(OptionsPanel)).headerEditor!
                as PropertyRandomizerSection)
            .controller;

    final seeds = _firstSeedForEveryPresentation();
    expect(seeds.keys, PolarShowcasePresentationKind.values.toSet());
    for (final presentation in PolarShowcasePresentationKind.values) {
      final seed = seeds[presentation]!;
      randomizer.seed = seed;
      randomizer.generateCurrent();
      await tester.pump(const Duration(milliseconds: 350));

      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('polar-column-live-chart')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      expect(
        chart.series,
        hasLength(switch (presentation) {
          PolarShowcasePresentationKind.layered => 2,
          PolarShowcasePresentationKind.grouped ||
          PolarShowcasePresentationKind.stacked => 3,
          _ => 1,
        }),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'seed $seed: $presentation',
      );
    }
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
    expect(chart.theme?.backgroundColor, const Color(0xFFF8FAFC));
    expect(chart.theme?.gridStyle.majorColor, const Color(0xFFCBD5E1));
    expect(
      (chart.series.single as PolarColumnChartSeries)
          .points
          .first
          .pointStyle
          ?.color,
      const Color(0xFF2563EB),
    );

    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Category colors',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    expect(find.text('Ocean'), findsNWidgets(2));
    expect(find.text('Sunset'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
    expect(find.text('Monochrome'), findsOneWidget);
    await tester.tap(find.text('Sunset').last);
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
      const Color(0xFFE63946),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grid line pattern reaches the public chart theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pumpAndSettle();

    final optionsList = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(ListView),
    );
    final control = find.byKey(const ValueKey('polar-grid-line-pattern'));
    for (
      var attempt = 0;
      attempt < 16 && control.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(optionsList, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(control, findsOneWidget);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: control,
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString().startsWith(
            'DropdownButtonFormField<',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dotted').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('polar-column-live-chart')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    expect(chart.theme?.gridStyle.majorDashPattern, const <double>[2, 3]);
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

  testWidgets('uses the compact chart-family selector and chart-first layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final selector = find.byKey(const ValueKey('polar-presentation-selector'));
    expect(
      find.descendant(of: selector, matching: find.byType(ChoiceChip)),
      findsNWidgets(9),
    );
    expect(tester.getSize(selector).height, lessThan(130));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('polar-column-live-chart')))
          .height,
      greaterThan(500),
    );
    expect(
      find.byKey(const ValueKey('polar-column-reset-example')),
      findsOneWidget,
    );
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

  testWidgets('authored examples exercise distinct visual systems', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PolarColumnPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final backgrounds = <Color>{};
    final gridColors = <Color>{};
    final categoryLabelColors = <Color?>{};
    final animations = <PolarColumnAnimationMode>{};
    final opacities = <double>{};
    final dashPatterns = <List<double>>[];
    var gradientCount = 0;
    var shadowCount = 0;

    for (final preset in const [
      'standard',
      'rose',
      'partial',
      'layered',
      'grouped',
      'stacked',
      'references',
      'intervals',
    ]) {
      if (preset != 'standard') {
        await tester.tap(find.byKey(ValueKey('polar-presentation-$preset')));
        await tester.pump(const Duration(milliseconds: 50));
      }
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('polar-column-live-chart')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      final style = chart.series
          .whereType<PolarColumnChartSeries>()
          .last
          .polarStyle;
      backgrounds.add(chart.theme!.backgroundColor);
      gridColors.add(chart.theme!.gridStyle.majorColor);
      categoryLabelColors.add(
        chart.polarChartConfig.angularAxis.labelStyle.color,
      );
      animations.add(style.animationMode);
      opacities.add(style.opacity);
      dashPatterns.add(chart.theme!.gridStyle.majorDashPattern);
      if (style.gradient != null) gradientCount++;
      if (style.shadow.isVisible) shadowCount++;
    }

    expect(backgrounds.length, greaterThanOrEqualTo(6));
    expect(gridColors.length, greaterThanOrEqualTo(7));
    expect(categoryLabelColors.length, greaterThanOrEqualTo(6));
    expect(animations, {
      PolarColumnAnimationMode.grow,
      PolarColumnAnimationMode.fade,
      PolarColumnAnimationMode.sweep,
    });
    expect(opacities.length, greaterThanOrEqualTo(6));
    expect(gradientCount, greaterThanOrEqualTo(5));
    expect(shadowCount, greaterThanOrEqualTo(4));
    expect(dashPatterns, contains(const <double>[]));
    expect(dashPatterns, contains(const <double>[2, 3]));
    expect(dashPatterns, contains(const <double>[7, 4]));
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

Future<void> _enterPlayground(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('polar-playground')));
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(const ValueKey('polar-randomizer-next')), findsOneWidget);
}

Future<void> _openRandomizerEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('polar-randomizer-editor')));
  await tester.pumpAndSettle();
  expect(find.text('Property randomizer'), findsWidgets);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _expectGeneratedChart(
  WidgetTester tester,
  PolarShowcaseRandomization generated,
) {
  final chart = tester.widget<BravenChartPlus>(
    find.descendant(
      of: find.byKey(const ValueKey('polar-column-live-chart')),
      matching: find.byType(BravenChartPlus),
    ),
  );
  final config = chart.polarChartConfig;
  expect(config.pane.startAngleDegrees, generated.startAngle);
  expect(config.pane.sweepAngleDegrees, generated.sweepAngle);
  expect(config.pane.clockwise, generated.clockwise);
  expect(config.pane.innerRadiusFactor, generated.innerRadius);
  expect(config.pane.outerRadiusFactor, generated.outerRadius);
  expect(config.angularAxis.innerPadding, generated.innerPadding);
  expect(config.angularAxis.outerPadding, generated.outerPadding);
  expect(config.angularAxis.showLabels, generated.showAngularLabels);
  expect(config.angularAxis.showGridLines, generated.showAngularGrid);
  expect(config.angularAxis.labelOffset, generated.categoryLabelOffset);
  expect(config.angularAxis.labelStyle.color, generated.categoryLabelColor);
  expect(config.angularAxis.labelStyle.fontSize, generated.categoryLabelSize);
  expect(
    config.angularAxis.labelStyle.fontWeight,
    generated.categoryLabelWeight,
  );
  expect(config.radialAxis.scaleMode, generated.scaleMode);
  expect(config.radialAxis.tickCount, generated.tickCount);
  expect(config.radialAxis.labelPosition, generated.radialLabelPosition);
  expect(
    config.radialAxis.labelAngleOffsetDegrees,
    generated.radialLabelAngleOffset,
  );
  expect(config.radialAxis.labelOffset, generated.radialLabelOffset);
  expect(config.radialAxis.labelStyle.color, generated.radialLabelColor);
  expect(config.radialAxis.labelStyle.fontSize, generated.radialLabelSize);
  expect(config.radialAxis.labelStyle.fontWeight, generated.radialLabelWeight);
  expect(config.composition.mode, generated.compositionMode);

  final primaryId = switch (generated.presentation) {
    PolarShowcasePresentationKind.layered => 'showcase-polar-observed',
    PolarShowcasePresentationKind.grouped => 'showcase-polar-north',
    PolarShowcasePresentationKind.stacked => 'showcase-polar-new',
    PolarShowcasePresentationKind.references => 'showcase-polar-actual-targets',
    PolarShowcasePresentationKind.intervals =>
      'showcase-polar-forecast-intervals',
    _ => 'showcase-polar-column',
  };
  final primary = chart.series.whereType<PolarColumnChartSeries>().singleWhere(
    (series) => series.id == primaryId,
  );
  expect(
    primary.points.map((point) => point.label),
    generated.primaryValues.keys,
  );
  expect(
    primary.points.map((point) => point.y),
    generated.primaryValues.values,
  );
  expect(primary.polarStyle.cornerRadius, generated.cornerRadius);
  expect(primary.polarStyle.cornerRadiusMode, generated.cornerRadiusMode);
  expect(primary.polarStyle.opacity, generated.opacity);
  expect(
    primary.polarStyle.dataLabelRadialPosition,
    generated.dataLabelRadialPosition,
  );
  expect(primary.polarStyle.dataLabelStyle.color, generated.dataLabelColor);
  expect(primary.polarStyle.dataLabelStyle.fontSize, generated.dataLabelSize);
  expect(
    primary.polarStyle.dataLabelStyle.fontWeight,
    generated.dataLabelWeight,
  );
  expect(primary.polarStyle.gradient != null, generated.showGradient);
  if (generated.showGradient) {
    expect(
      primary.polarStyle.gradient?.startColor,
      generated.gradientStartColor,
    );
    expect(primary.polarStyle.gradient?.endColor, generated.gradientEndColor);
  }
  expect(primary.polarStyle.shadow.isVisible, generated.showColumnShadow);
  expect(primary.polarStyle.animationMode, generated.animationMode);
  expect(primary.selectionStyle.effect, generated.selectionEffect);
  expect(primary.selectionStyle.liftScale, generated.selectionScale);
  expect(primary.selectionStyle.liftOffset, generated.selectionOffset);

  final baseTheme = switch (generated.theme) {
    PolarShowcaseThemeKind.light => ChartTheme.light,
    PolarShowcaseThemeKind.dark => ChartTheme.dark,
    PolarShowcaseThemeKind.corporate => ChartTheme.corporateBlue,
    PolarShowcaseThemeKind.vibrant => ChartTheme.vibrant,
    PolarShowcaseThemeKind.minimal => ChartTheme.minimal,
    PolarShowcaseThemeKind.highContrast => ChartTheme.highContrast,
    PolarShowcaseThemeKind.colorblind => ChartTheme.colorblindFriendly,
  };
  expect(
    chart.theme?.backgroundColor,
    generated.canvasColor ?? baseTheme.backgroundColor,
  );
  expect(
    chart.theme?.axisStyle.lineColor,
    generated.axisLineColor ?? baseTheme.axisStyle.lineColor,
  );
  expect(chart.theme?.axisStyle.lineWidth, generated.axisLineWidth);
  expect(
    chart.theme?.axisStyle.labelStyle.color,
    generated.axisLabelColor ?? baseTheme.axisStyle.labelStyle.color,
  );
  expect(
    chart.theme?.gridStyle.majorColor,
    generated.gridLineColor ?? baseTheme.gridStyle.majorColor,
  );
  expect(chart.theme?.gridStyle.majorWidth, generated.gridLineWidth);
  expect(
    chart.theme?.gridStyle.majorDashPattern,
    _dashPatternFor(generated.gridLinePattern),
  );
  expect(chart.interactionConfig!.tooltip.enabled, generated.showTooltip);
  expect(
    chart.interactionConfig!.tooltip.triggerMode,
    generated.tooltipTrigger,
  );
}

List<double> _dashPatternFor(PolarShowcaseLinePatternKind pattern) =>
    switch (pattern) {
      PolarShowcaseLinePatternKind.solid => const <double>[],
      PolarShowcaseLinePatternKind.dashed => const <double>[7, 4],
      PolarShowcaseLinePatternKind.dotted => const <double>[2, 3],
    };

Map<PolarShowcasePresentationKind, int> _firstSeedForEveryPresentation() {
  final seeds = <PolarShowcasePresentationKind, int>{};
  for (var seed = 0; seed < 1000; seed++) {
    final presentation = PolarShowcaseRandomizer.generate(seed).presentation;
    seeds.putIfAbsent(presentation, () => seed);
    if (seeds.length == PolarShowcasePresentationKind.values.length) break;
  }
  return seeds;
}
