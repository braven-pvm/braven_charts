import 'dart:ui' show PointerDeviceKind;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/gauge_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Gauge page exposes authored, Workbench, and inspector UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    expect(find.text('Gauge Charts'), findsOneWidget);
    for (final label in [
      'Needle',
      'Instrument',
      'Solid',
      'Gradient',
      'Zones',
      'Target',
      'Legend',
      'Popup',
      'Partial sweep',
      'Accessible',
      'Density',
      'Playground',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    for (final mode in ['Chart', 'Data', 'Split', 'Source']) {
      expect(find.text(mode), findsOneWidget);
    }
    expect(find.byType(PaletteColorOption), findsWidgets);

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-0')),
    );
    final series = chart.series.single as GaugeChartSeries;
    expect(series.indicatorStyle, isA<NeedleGaugeStyle>());
    expect(series.status, 'Elevated');
    expect(chart.gaugeChartConfig.pane.sweepAngleDegrees, 270);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gauge page deep-links directly to an authored preset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GaugeChartsPage(initialPreset: 'instrument')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Instrument revenue gauge'), findsOneWidget);
    expect(find.textContaining('Dense inside ticks'), findsOneWidget);
  });

  testWidgets('instrument preset exposes dense scale and segmented zones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();
    await tester.tap(find.text('Instrument').first);
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    final series = chart.series.single as GaugeChartSeries;
    final needle = series.indicatorStyle as NeedleGaugeStyle;
    expect(chart.gaugeChartConfig.minorTicksPerInterval, 4);
    expect(chart.gaugeChartConfig.scale.tickPosition, GaugeTickPosition.inside);
    expect(
      chart.gaugeChartConfig.scale.labelPosition,
      GaugeScaleLabelPosition.outside,
    );
    expect(chart.gaugeChartConfig.zones.gap, 5);
    expect(needle.needleWidth, 28);
    expect(needle.needleTipWidth, 2);
    expect(needle.pivotBorderWidth, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored examples exercise scale and callout styling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    await tester.tap(find.text('Target').first);
    await tester.pump();
    final targetChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    expect(targetChart.gaugeChartConfig.references.showLabelPanel, isTrue);
    expect(targetChart.gaugeChartConfig.references.labelOffset, 12);

    await tester.tap(find.text('Accessible').first);
    await tester.pump();
    final accessibleChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-2')),
    );
    expect(accessibleChart.gaugeChartConfig.scale.tickWidth, 3);
    expect(accessibleChart.gaugeChartConfig.scale.tickLength, 16);
    expect(accessibleChart.gaugeChartConfig.scale.labelStyle.fontSize, 13);
    expect(accessibleChart.gaugeChartConfig.references.showLabelPanel, isTrue);

    await tester.tap(find.text('Density').first);
    await tester.pump();
    final densityChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-3')),
    );
    expect(densityChart.gaugeChartConfig.scale.tickWidth, 0.75);
    expect(densityChart.gaugeChartConfig.scale.labelOffset, 5);
    expect(densityChart.gaugeChartConfig.center.verticalOffset, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gradient, legend, popup, and motion controls are live', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    await tester.tap(find.text('Gradient').first);
    await tester.pump();
    final gradientChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    final gradientStyle =
        (gradientChart.series.single as GaugeChartSeries).indicatorStyle
            as SolidGaugeStyle;
    expect(gradientStyle.gradient?.type, GaugeGradientType.sweep);

    await tester.tap(find.text('Legend').first);
    await tester.pump();
    final legendChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-2')),
    );
    expect(legendChart.showLegend, isTrue);
    expect(legendChart.theme?.legendStyle.position, LegendPosition.centerRight);
    expect(find.byKey(const ValueKey('gauge-legend')), findsOneWidget);

    await tester.tap(find.text('Popup').first);
    await tester.pump();
    final popupChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-3')),
    );
    expect(popupChart.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(
      popupChart.interactionConfig?.tooltip.preferredPosition,
      TooltipPosition.right,
    );
    expect(popupChart.interactionConfig?.tooltip.followCursor, isTrue);
    expect(
      popupChart.theme?.animationTheme.dataUpdateDuration,
      isNot(Duration.zero),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored examples expose distinct pane geometries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    const expected = <String, (double, double)>{
      'Needle': (-135, 270),
      'Instrument': (180, 180),
      'Solid': (-150, 300),
      'Gradient': (-120, 240),
      'Zones': (-180, 360),
      'Target': (-90, 180),
      'Legend': (-160, 320),
      'Popup': (-105, 210),
      'Partial sweep': (15, 150),
      'Accessible': (-140, 280),
      'Density': (-165, 330),
    };
    final observedPanes = <(double, double)>{};

    for (final (index, entry) in expected.entries.indexed) {
      if (index > 0) {
        await tester.tap(find.text(entry.key).first);
        await tester.pump();
      }
      final chart = tester.widget<BravenChartPlus>(
        find.byKey(ValueKey('gauge-chart-$index')),
      );
      expect(
        chart.gaugeChartConfig.pane.startAngleDegrees,
        entry.value.$1,
        reason: '${entry.key} start angle',
      );
      expect(
        chart.gaugeChartConfig.pane.sweepAngleDegrees,
        entry.value.$2,
        reason: '${entry.key} sweep angle',
      );
      observedPanes.add((
        chart.gaugeChartConfig.pane.startAngleDegrees,
        chart.gaugeChartConfig.pane.sweepAngleDegrees,
      ));
    }

    expect(observedPanes, hasLength(expected.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored examples start fresh and Playground randomizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    await tester.tap(find.text('Solid').first);
    await tester.pump();
    final solid = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    expect(
      (solid.series.single as GaugeChartSeries).indicatorStyle,
      isA<SolidGaugeStyle>(),
    );
    expect((solid.series.single as GaugeChartSeries).minimum, 99);

    await tester.tap(find.text('Playground').first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gauge-randomizer-editor')));
    await tester.pump();
    expect(find.text('Property randomizer'), findsNWidgets(2));
    await tester.tap(find.text('Close'));
    await tester.pump();
    final generated = tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key != null &&
            widget.key.toString().contains('gauge-chart-'),
      ),
    );
    final generatedSeries = generated.series.single as GaugeChartSeries;
    expect(generatedSeries.value, inInclusiveRange(0, generatedSeries.maximum));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gauge page remains usable at tablet width with touch input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GaugeChartsPage()));
    await tester.pump();

    final solidChoice = find.text('Solid').first;
    await tester.ensureVisible(solidChoice);
    final touch = await tester.startGesture(
      tester.getCenter(solidChoice),
      kind: PointerDeviceKind.touch,
    );
    await touch.up();
    await tester.pump();

    final solid = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('gauge-chart-1')),
    );
    expect(
      (solid.series.single as GaugeChartSeries).indicatorStyle,
      isA<SolidGaugeStyle>(),
    );
    expect(find.byKey(const ValueKey('gauge-showcase-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
