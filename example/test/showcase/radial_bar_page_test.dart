import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/radial_bar_page.dart';
import 'package:braven_charts_example/showcase/widgets/chart_options.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Radial Bar page exposes authored, Workbench, and inspector UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();

    expect(find.text('Radial Bar Charts'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Signed baseline'), findsOneWidget);
    expect(find.text('Partial target'), findsOneWidget);
    expect(find.text('Callout labels'), findsOneWidget);
    expect(find.text('Inside styling'), findsOneWidget);
    expect(find.text('Label cards'), findsOneWidget);
    expect(find.text('Popup studio'), findsOneWidget);
    expect(find.text('Motion'), findsAtLeastNWidgets(1));
    expect(find.text('Rotated categories'), findsOneWidget);
    expect(find.text('Callout lanes'), findsOneWidget);
    expect(find.text('Dense tracks'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.byType(PaletteColorOption), findsAtLeastNWidgets(3));

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radial-bar-chart-0')),
    );
    expect(chart.showLegend, isFalse);
    expect(chart.theme?.legendStyle.position, LegendPosition.bottomCenter);
    expect(chart.theme?.legendStyle.orientation, LegendOrientation.horizontal);
    expect(chart.theme?.legendStyle.markerShape, LegendMarkerShape.circle);
    expect(chart.series.single, isA<RadialBarChartSeries>());
    expect(chart.radialBarChartConfig.thresholds.single.value, 75);
    expect(chart.radialBarChartConfig.pane.sweepAngleDegrees, 360);
    final radialSeries = chart.series.single as RadialBarChartSeries;
    expect(
      radialSeries.radialBarStyle.gradient?.type,
      RadialBarGradientType.sweep,
    );
    expect(
      radialSeries.radialBarStyle.dataLabels.position,
      RadialBarDataLabelPosition.insideEnd,
    );
    expect(
      radialSeries.radialBarStyle.dataLabels.colorMode,
      RadialBarDataLabelColorMode.autoContrast,
    );
    expect(
      chart.radialBarChartConfig.categoryLabels.position,
      RadialBarCategoryLabelPosition.startGap,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('legend position selects the matching band orientation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Legend',
    );
    await tester.pump();

    final legendToggle = tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text('Show legend'),
        matching: find.byType(SwitchListTile),
      ),
    );
    legendToggle.onChanged?.call(true);
    await tester.pump();

    final positionOption = tester.widget<EnumOption<LegendPosition>>(
      find.byKey(const ValueKey('radial-bar-legend-position')),
    );
    positionOption.onChanged(LegendPosition.centerRight);
    await tester.pump();

    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.theme?.legendStyle.position, LegendPosition.centerRight);
    expect(chart.theme?.legendStyle.orientation, LegendOrientation.vertical);

    tester
        .widget<EnumOption<LegendPosition>>(
          find.byKey(const ValueKey('radial-bar-legend-position')),
        )
        .onChanged(LegendPosition.topCenter);
    await tester.pump();

    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.theme?.legendStyle.position, LegendPosition.topCenter);
    expect(chart.theme?.legendStyle.orientation, LegendOrientation.horizontal);
  });

  testWidgets('dense tracks keep category labels at their track starts', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.tap(find.text('Dense tracks'));
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final config = chart.radialBarChartConfig;

    expect(
      config.categoryLabels.position,
      RadialBarCategoryLabelPosition.startGap,
    );
    expect(config.categoryLabels.connectorWidth, 0);
    expect(chart.showLegend, isFalse);
  });

  testWidgets(
    'authored presets intentionally mix legend and legend-free layouts',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
      await tester.pump();

      BravenChartPlus currentChart() =>
          tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));

      expect(currentChart().showLegend, isFalse);

      await tester.tap(find.text('Signed baseline'));
      await tester.pump();
      expect(currentChart().showLegend, isTrue);

      await tester.tap(find.text('Callout labels'));
      await tester.pump();
      expect(currentChart().showLegend, isFalse);

      await tester.tap(find.text('Inside styling'));
      await tester.pump();
      expect(currentChart().showLegend, isTrue);

      await tester.tap(find.text('Rotated categories'));
      await tester.pump();
      expect(currentChart().showLegend, isFalse);

      await tester.tap(find.text('Callout lanes'));
      await tester.pump();
      expect(currentChart().showLegend, isTrue);

      await tester.tap(find.text('Dense tracks'));
      await tester.pump();
      expect(currentChart().showLegend, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('choosing category callouts enables visible leaders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Category position',
    );
    await tester.pump();

    await tester.tap(find.text('At track start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outside labels').last);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.radialBarChartConfig.categoryLabels.position,
      RadialBarCategoryLabelPosition.outsideCallout,
    );
    expect(chart.radialBarChartConfig.categoryLabels.connectorWidth, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored examples start fresh and Playground randomizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();

    await tester.tap(find.text('Partial target'));
    await tester.pump();
    final partial = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radial-bar-chart-1')),
    );
    expect(partial.radialBarChartConfig.pane.sweepAngleDegrees, 270);
    expect(partial.radialBarChartConfig.thresholds.single.value, 80);
    expect(
      (partial.series.single as RadialBarChartSeries)
          .radialBarStyle
          .gradient
          ?.type,
      RadialBarGradientType.sweep,
    );
    expect(partial.theme?.legendStyle.position, LegendPosition.centerRight);
    expect(partial.theme?.legendStyle.orientation, LegendOrientation.vertical);
    expect(
      partial.theme?.backgroundColor,
      ThemePreset.corporateBlue.theme.backgroundColor,
    );

    await tester.tap(find.text('Callout labels'));
    await tester.pump();
    final callouts = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('radial-bar-chart-2')),
    );
    final calloutSeries = callouts.series.single as RadialBarChartSeries;
    expect(
      calloutSeries.radialBarStyle.dataLabels.position,
      RadialBarDataLabelPosition.outsideCallout,
    );
    expect(
      calloutSeries.radialBarStyle.dataLabels.content,
      RadialBarDataLabelContent.categoryAndValue,
    );
    expect(calloutSeries.radialBarStyle.dataLabels.showPanel, isTrue);
    expect(calloutSeries.radialBarStyle.dataLabels.panelStyle, isNotNull);
    expect(callouts.radialBarChartConfig.showCategoryLabels, isFalse);

    await tester.tap(find.text('Playground'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('radial-bar-randomizer-editor')),
    );
    await tester.pump();
    expect(find.text('Property randomizer'), findsNWidgets(2));
    await tester.tap(find.text('Close'));
    await tester.pump();
    final generated = tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key != null &&
            widget.key.toString().contains('radial-bar-chart-'),
      ),
    );
    final generatedSeries = generated.series.single as RadialBarChartSeries;
    expect(generatedSeries.points.length, inInclusiveRange(4, 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored label examples cover distinct presentation contracts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();

    BravenChartPlus currentChart() =>
        tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));

    await tester.tap(find.text('Inside styling'));
    await tester.pump();
    var chart = currentChart();
    var series = chart.series.single as RadialBarChartSeries;
    expect(
      series.radialBarStyle.dataLabels.colorMode,
      RadialBarDataLabelColorMode.fixed,
    );
    expect(series.radialBarStyle.dataLabels.textStyle.color, Colors.white);
    expect(series.radialBarStyle.dataLabels.textStyle.fontSize, 12);
    expect(
      chart.radialBarChartConfig.categoryLabels.orientation,
      RadialBarCategoryLabelOrientation.horizontal,
    );
    expect(chart.radialBarChartConfig.categoryLabels.showPanel, isTrue);
    expect(series.radialBarStyle.gradient?.type, RadialBarGradientType.radial);
    expect(chart.radialLegendItemBuilder, isNotNull);
    expect(
      chart.theme?.backgroundColor,
      ThemePreset.dark.theme.backgroundColor,
    );
    expect(
      chart.radialBarChartConfig.categoryLabels.panelStyle?.backgroundColor,
      const Color(0xFF1E293B),
    );

    await tester.tap(find.text('Rotated categories'));
    await tester.pump();
    chart = currentChart();
    expect(chart.radialBarChartConfig.pane.startAngleDegrees, 25);
    expect(chart.radialBarChartConfig.pane.sweepAngleDegrees, 285);
    expect(
      chart.radialBarChartConfig.categoryLabels.orientation,
      RadialBarCategoryLabelOrientation.followStartAngle,
    );
    expect(
      chart.radialBarChartConfig.categoryLabels.textStyle.color,
      const Color(0xFF312E81),
    );
    expect(chart.radialBarChartConfig.categoryLabels.showPanel, isTrue);

    await tester.tap(find.text('Callout lanes'));
    await tester.pump();
    chart = currentChart();
    series = chart.series.single as RadialBarChartSeries;
    expect(series.points, hasLength(8));
    expect(
      series.radialBarStyle.dataLabels.position,
      RadialBarDataLabelPosition.outsideCallout,
    );
    expect(
      series.radialBarStyle.dataLabels.colorMode,
      RadialBarDataLabelColorMode.fixed,
    );
    expect(series.radialBarStyle.dataLabels.showPanel, isFalse);
    expect(series.radialBarStyle.dataLabels.connectorLength, 22);
    expect(series.radialBarStyle.dataLabels.connectorWidth, 2);
    expect(series.radialBarStyle.gradient?.startColor, const Color(0xFF22D3EE));
    expect(series.radialBarStyle.gradient?.endColor, const Color(0xFF4F46E5));
    expect(chart.theme?.legendStyle.position, LegendPosition.centerLeft);
    expect(
      series.radialBarStyle.dataLabels.connectorColor,
      const Color(0xFF7C3AED),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'label cards, popup studio, and motion expose distinct complete contracts',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
      await tester.pump();

      BravenChartPlus currentChart() =>
          tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));

      await tester.tap(find.text('Label cards'));
      await tester.pump();
      var chart = currentChart();
      var labels = (chart.series.single as RadialBarChartSeries)
          .radialBarStyle
          .dataLabels;
      expect(labels.position, RadialBarDataLabelPosition.outsideCallout);
      expect(labels.content, RadialBarDataLabelContent.categoryAndValue);
      expect(
        labels.panelStyle?.padding,
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );
      expect(labels.panelStyle?.shadowBlurRadius, 10);
      expect(chart.showLegend, isFalse);

      await tester.tap(find.text('Popup studio'));
      await tester.pump();
      chart = currentChart();
      final tooltip = chart.interactionConfig!.tooltip;
      expect(tooltip.triggerMode, TooltipTriggerMode.both);
      expect(tooltip.preferredPosition, TooltipPosition.right);
      expect(tooltip.followCursor, isTrue);
      expect(tooltip.offsetFromPoint, 14);
      expect(tooltip.showDelay, const Duration(milliseconds: 100));
      expect(tooltip.hideDelay, const Duration(milliseconds: 450));
      expect(tooltip.style.backgroundColor, const Color(0xFF172554));
      expect(tooltip.style.textColor, const Color(0xFFEFF6FF));
      expect(tooltip.style.borderColor, const Color(0xFF38BDF8));
      expect(tooltip.style.borderWidth, 1.5);
      expect(tooltip.style.borderRadius, 12);
      expect(tooltip.style.padding, 12);
      expect(tooltip.style.shadowBlurRadius, 16);
      expect(tooltip.style.fontSize, 13);

      await tester.tap(find.text('Motion').first);
      await tester.pump();
      chart = currentChart();
      expect(
        chart.theme?.animationTheme.dataUpdateDuration,
        const Duration(milliseconds: 1200),
      );
      expect(chart.theme?.animationTheme.dataUpdateCurve, Curves.easeOutCubic);
      expect(
        chart.theme?.animationTheme.interactionDuration,
        const Duration(milliseconds: 280),
      );
      expect(
        chart.theme?.animationTheme.interactionCurve,
        Curves.easeInOutCubic,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('popup inspector exposes every portable tooltip property', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pump();
    final search = find.byKey(const ValueKey('options-panel-search'));

    for (final label in const [
      'Data point popup',
      'Popup style',
      'Popup trigger',
      'Preferred position',
      'Follow pointer',
      'Point offset',
      'Show delay',
      'Hide delay',
      'Popup background',
      'Popup text color',
      'Popup text size',
      'Popup border',
      'Popup border width',
      'Popup corner radius',
      'Popup padding',
      'Popup shadow',
      'Popup shadow blur',
    ]) {
      await tester.enterText(search, label);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == label,
        ),
        findsOneWidget,
        reason: label,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('label placement is searchable and updates the live series', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Label position',
    );
    await tester.pump();

    expect(find.text('Value labels'), findsOneWidget);
    expect(find.text('Label position'), findsNWidgets(2));
    await tester.tap(find.text('Inside end'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outside callout').last);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key.toString().contains('radial-bar-chart-'),
      ),
    );
    final series = chart.series.single as RadialBarChartSeries;
    expect(
      series.radialBarStyle.dataLabels.position,
      RadialBarDataLabelPosition.outsideCallout,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('label palette switches directly between fixed and auto color', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Label color',
    );
    await tester.pump();

    final blackSwatch = find.byKey(
      ValueKey('radial-bar-label-color-${Colors.black.toARGB32()}'),
    );
    await tester.ensureVisible(blackSwatch);
    await tester.tap(blackSwatch);
    await tester.pump();

    RadialBarChartSeries currentSeries() {
      final chart = tester.widget<BravenChartPlus>(
        find.byWidgetPredicate(
          (widget) =>
              widget is BravenChartPlus &&
              widget.key.toString().contains('radial-bar-chart-'),
        ),
      );
      return chart.series.single as RadialBarChartSeries;
    }

    expect(
      currentSeries().radialBarStyle.dataLabels.colorMode,
      RadialBarDataLabelColorMode.fixed,
    );
    expect(
      currentSeries().radialBarStyle.dataLabels.textStyle.color,
      Colors.black,
    );

    final clearSwatch = find.byKey(
      const ValueKey('radial-bar-label-color-clear'),
    );
    await tester.tap(clearSwatch);
    await tester.pump();

    expect(
      currentSeries().radialBarStyle.dataLabels.colorMode,
      RadialBarDataLabelColorMode.autoContrast,
    );
    expect(currentSeries().radialBarStyle.dataLabels.textStyle.color, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('callout panel controls update the live series', (tester) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
    await tester.pump();
    await tester.tap(find.text('Callout labels'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Label panel',
    );
    await tester.pump();

    final panelToggle = find.ancestor(
      of: find.text('Label panel'),
      matching: find.byType(SwitchListTile),
    );
    expect(panelToggle, findsOneWidget);
    await tester.tap(panelToggle);
    await tester.pump();
    await tester.tap(panelToggle);
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'Panel fill',
    );
    await tester.pump();

    final blackSwatch = find.byKey(
      ValueKey('radial-bar-callout-panel-fill-${Colors.black.toARGB32()}'),
    );
    await tester.ensureVisible(blackSwatch);
    await tester.tap(blackSwatch);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key.toString().contains('radial-bar-chart-'),
      ),
    );
    final series = chart.series.single as RadialBarChartSeries;
    expect(series.radialBarStyle.dataLabels.showPanel, isTrue);
    expect(
      series.radialBarStyle.dataLabels.panelStyle?.backgroundColor,
      Colors.black,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category label inspector controls position, direct color, and panel',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RadialBarPage()));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('options-panel-search-toggle')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('options-panel-search')),
        'Category labels',
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(OptionSection),
          matching: find.text('Category labels'),
        ),
        findsOneWidget,
      );
      expect(find.text('Category position'), findsOneWidget);
      expect(find.text('Category orientation'), findsOneWidget);
      await tester.tap(find.text('Adaptive orientation').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Horizontal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Horizontal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adaptive orientation').last);
      await tester.pump();
      await tester.tap(find.text('At track start').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outside labels').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outside labels').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('At track start').last);
      await tester.pump();

      final blackSwatch = find.byKey(
        ValueKey('radial-bar-category-label-color-${Colors.black.toARGB32()}'),
      );
      await tester.ensureVisible(blackSwatch);
      await tester.tap(blackSwatch);
      await tester.pump();

      final panelToggle = find.ancestor(
        of: find.text('Label background panel'),
        matching: find.byType(SwitchListTile),
      );
      await tester.ensureVisible(panelToggle);
      await tester.tap(panelToggle);
      await tester.pump();

      final chart = tester.widget<BravenChartPlus>(
        find.byWidgetPredicate(
          (widget) =>
              widget is BravenChartPlus &&
              widget.key.toString().contains('radial-bar-chart-'),
        ),
      );
      expect(
        chart.radialBarChartConfig.categoryLabels.position,
        RadialBarCategoryLabelPosition.startGap,
      );
      expect(
        chart.radialBarChartConfig.categoryLabels.orientation,
        RadialBarCategoryLabelOrientation.followStartAngle,
      );
      expect(
        chart.radialBarChartConfig.categoryLabels.textStyle.color,
        Colors.black,
      );
      expect(chart.radialBarChartConfig.categoryLabels.showPanel, isTrue);
      expect(chart.radialBarChartConfig.categoryLabels.panelStyle, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
