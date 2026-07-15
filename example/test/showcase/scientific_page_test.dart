import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/scientific_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scientific hub presents five real example previews', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScientificPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Scientific examples'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scientific-example-ribbon')),
      findsOneWidget,
    );
    for (final name in [
      'waveSynthesis',
      'distributions',
      'regression',
      'powerLactate',
      'lactateThreshold',
    ]) {
      expect(find.byKey(ValueKey('scientific-example-$name')), findsOneWidget);
      expect(find.byKey(ValueKey('scientific-preview-$name')), findsOneWidget);
    }

    expect(find.text('Signal synthesis'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scientific-analysis-guide')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('scientific-main-stage')), findsOneWidget);

    final chart = _mainChart(tester, 'waveSynthesis');
    expect(chart.series, hasLength(2));
    expect(chart.series.whereType<LineChartSeries>(), hasLength(2));
    expect(chart.annotations.whereType<ThresholdAnnotation>(), hasLength(1));
    expect(chart.xAxisConfig!.label, 'Sample');
    expect(chart.xAxisConfig!.unit, 's');

    expect(find.text('Scientific Model'), findsOneWidget);
    expect(find.text('Wave Parameters'), findsOneWidget);
    expect(find.text('Analysis Overlay'), findsOneWidget);
    expect(find.text('Chart Options'), findsOneWidget);
  });

  testWidgets('analytical examples expose distributions and regression', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScientificPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(
      find.byKey(const ValueKey('scientific-example-distributions')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    var chart = _mainChart(tester, 'distributions');
    expect(chart.series.whereType<AreaChartSeries>(), hasLength(2));
    expect(chart.annotations.whereType<ThresholdAnnotation>(), hasLength(2));
    expect(find.text('Probability distributions'), findsOneWidget);
    expect(find.text('Distribution Parameters'), findsOneWidget);
    expect(find.text('Mean A'), findsOneWidget);
    expect(find.text('Spread B'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('scientific-example-regression')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    chart = _mainChart(tester, 'regression');
    expect(chart.series.whereType<ScatterChartSeries>(), hasLength(1));
    expect(chart.series.whereType<LineChartSeries>(), hasLength(1));
    expect(chart.annotations.whereType<RangeAnnotation>(), hasLength(1));
    expect(find.text('Regression analysis'), findsOneWidget);
    expect(find.text('Regression Parameters'), findsOneWidget);
    expect(find.text('Slope'), findsOneWidget);
    expect(find.text('Noise'), findsOneWidget);
  });

  testWidgets('scientific hub preserves both physiology workbenches', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScientificPage())),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(
      find.byKey(const ValueKey('scientific-example-powerLactate')),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Cyclist Power vs Lactate'), findsOneWidget);
    var options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Scenario Guide'),
      300,
      scrollable: options,
    );
    expect(find.text('Scenario Guide'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('scientific-example-lactateThreshold')),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Lactate Threshold Detection'), findsOneWidget);
    options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Section Chord'),
      300,
      scrollable: options,
    );
    expect(find.text('Section Chord'), findsOneWidget);
    expect(find.text('Ramp Chord'), findsOneWidget);
  });
}

BravenChartPlus _mainChart(WidgetTester tester, String example) {
  return tester.widget<BravenChartPlus>(
    find.byKey(ValueKey('scientific-main-chart-$example')),
  );
}
