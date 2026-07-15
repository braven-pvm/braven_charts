import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/theming_page.dart';
import 'package:braven_charts_example/showcase/widgets/chart_options.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theming compares every public preset around one main chart', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThemingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose a visual system'), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-preset-ribbon')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-system-guide')), findsOneWidget);
    expect(find.byKey(const ValueKey('theming-main-chart')), findsOneWidget);

    for (final preset in ThemePreset.values) {
      expect(
        find.byKey(ValueKey('theme-preset-${preset.name}')),
        findsOneWidget,
      );
    }

    expect(find.text('Interaction'), findsOneWidget);
    expect(find.text('Motion'), findsOneWidget);
    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('Scrollbar'), findsOneWidget);
    expect(find.text('Legend'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('ChartTheme.light'), findsOneWidget);

    final chart = _mainChart(tester);
    expect(chart.theme, same(ChartTheme.light));
    expect(chart.showXScrollbar, isTrue);
    expect(chart.series, hasLength(3));
    expect(chart.annotations, hasLength(5));
    expect(chart.annotations.whereType<PointAnnotation>(), hasLength(1));
    expect(chart.annotations.whereType<RangeAnnotation>(), hasLength(1));
    expect(chart.annotations.whereType<TextAnnotation>(), hasLength(1));
    expect(chart.annotations.whereType<ThresholdAnnotation>(), hasLength(1));
    expect(chart.annotations.whereType<TrendAnnotation>(), hasLength(1));

    expect(find.text('Theme System'), findsOneWidget);
    expect(find.text('Chart Options'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
  });

  testWidgets('preset selection and nested customization update the stage', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThemingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('theme-preset-dark')));
    await tester.pump(const Duration(milliseconds: 200));

    var chart = _mainChart(tester);
    expect(chart.theme!.backgroundColor, ChartTheme.dark.backgroundColor);
    expect(
      chart.annotations.whereType<PointAnnotation>().single.markerColor,
      ChartTheme.dark.annotationTheme.pointDefaults.normalColor,
    );
    expect(
      chart.annotations.whereType<RangeAnnotation>().single.fillColor,
      ChartTheme.dark.annotationTheme.rangeDefaults.normalFillColor,
    );
    expect(
      chart.annotations.whereType<ThresholdAnnotation>().single.lineColor,
      ChartTheme.dark.annotationTheme.thresholdDefaults.lineColor,
    );
    expect(
      chart.annotations.whereType<TrendAnnotation>().single.lineColor,
      ChartTheme.dark.annotationTheme.trendDefaults.lineColor,
    );
    expect(
      chart.annotations.whereType<TextAnnotation>().single.backgroundColor,
      ChartTheme.dark.annotationTheme.textDefaults.backgroundColor,
    );
    expect(find.text('ChartTheme.dark'), findsOneWidget);
    expect(find.text('Dark operations overview'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('customize-theme')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Series Palette'), findsOneWidget);
    expect(find.text('Grid & Axes'), findsOneWidget);
    expect(find.text('Interaction & Chrome'), findsOneWidget);
    expect(find.text('Typography & Motion'), findsOneWidget);
    expect(find.textContaining('ChartTheme.dark.copyWith'), findsOneWidget);

    chart = _mainChart(tester);
    expect(chart.theme!.seriesTheme.colors.first, const Color(0xFF4F46E5));
    expect(chart.theme!.typographyTheme.baseFontSize, 12);
    expect(chart.theme!.scrollbarConfig.thickness, 12);
    expect(chart.theme!.animationTheme.dataUpdateDuration.inMilliseconds, 400);

    await tester.tap(find.text('Braven'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ocean').last);
    await tester.pump(const Duration(milliseconds: 200));

    chart = _mainChart(tester);
    expect(chart.theme!.seriesTheme.colors.first, const Color(0xFF0369A1));

    final options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.textContaining('ChartTheme combines background'),
      400,
      scrollable: options,
    );
    expect(
      find.textContaining('Every component can be replaced'),
      findsOneWidget,
    );
  });
}

BravenChartPlus _mainChart(WidgetTester tester) {
  return tester.widget<BravenChartPlus>(
    find.byKey(const ValueKey('theming-main-chart')),
  );
}
