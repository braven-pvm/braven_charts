// Copyright 2026 Braven Charts - Value Summary Page tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/value_summary_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() =>
      const MaterialApp(home: Scaffold(body: ValueSummaryPage()));

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
  }

  Future<void> revealOption(WidgetTester tester, Finder target) async {
    final optionsScrollable = find
        .descendant(of: find.byType(OptionsPanel), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(target, 120, scrollable: optionsScrollable);
    await tester.pumpAndSettle();
  }

  testWidgets('builds with a fallback summary before any pointer input', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Value Summary'), findsOneWidget);
    for (final preset in [
      'line',
      'multiSeries',
      'multiAxis',
      'candlestick',
      'synchronized',
      'pinned',
    ]) {
      expect(
        find.byKey(ValueKey('value-summary-preset-$preset')),
        findsOneWidget,
      );
    }
    expect(find.text('Single series with latest fallback'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);

    // The summary is enabled and already resolved to the latest-visible
    // fallback datum with no pointer anywhere near the chart.
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.interactionConfig?.valueSummary.enabled, isTrue);
    expect(
      chart.interactionConfig?.valueSummary.valuePolicy,
      CartesianValueSummaryValuePolicy.trackingThenLatest,
    );

    final renderBox = _renderBox(tester);
    final snapshot = renderBox.debugValueSummarySnapshot;
    expect(snapshot, isNotNull);
    expect(snapshot!.origin, CartesianTrackingOrigin.fallback);
    expect(snapshot.dataX, closeTo(20, 1e-6));
    expect(renderBox.debugValueSummaryModel, isNotNull);
    expect(renderBox.debugValueSummaryBounds, isNot(Rect.zero));
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches presets, keeping each stage summary-enabled', (
    tester,
  ) async {
    await pumpPage(tester);

    // Multi-series: crosshair defaults OFF while the summary stays enabled —
    // the independence demonstration.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-multiSeries')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Three riders, crosshair off'), findsOneWidget);
    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.interactionConfig?.crosshair.enabled, isFalse);
    expect(chart.interactionConfig?.valueSummary.enabled, isTrue);
    expect(chart.series, hasLength(3));

    // Multi-axis: two unit-bearing axes.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-multiAxis')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dual axes with units'), findsOneWidget);
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.series.map((series) => series.yAxisConfig?.unit),
      containsAll(['mL/kg/min', 'bpm']),
    );

    // Candlestick: OHLC series drives rich automatic rows.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-candlestick')),
    );
    await tester.pumpAndSettle();
    expect(find.text('OHLC session summary'), findsOneWidget);
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series.single, isA<CandlestickChartSeries>());
    expect(chart.interactionConfig?.valueSummary.enabled, isTrue);

    // Synchronized: two charts, each with its own enabled summary.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-synchronized')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Synchronized pair'), findsOneWidget);
    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList();
    expect(charts, hasLength(2));
    for (final synced in charts) {
      expect(synced.interactionGroupController, isNotNull);
      expect(synced.interactionConfig?.valueSummary.enabled, isTrue);
    }

    // Pinned: policy flips to pinnedThenTrackingThenLatest by default.
    await tester.tap(find.byKey(const ValueKey('value-summary-preset-pinned')));
    await tester.pumpAndSettle();
    expect(find.text('Pinned datum workflow'), findsOneWidget);
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.interactionConfig?.valueSummary.valuePolicy,
      CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('clear-background toggle drives the tri-state style', (
    tester,
  ) async {
    await pumpPage(tester);

    CartesianValueSummaryStyle style() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .interactionConfig!
        .valueSummary
        .style;

    // Untouched: every style field inherits from the summary theme.
    expect(style().backgroundColor.isInherit, isTrue);
    expect(style().borderColor.isInherit, isTrue);
    expect(style().backgroundOpacity.isInherit, isTrue);

    final clearBackground = find.byKey(
      const ValueKey('value-summary-clear-background'),
    );
    await revealOption(tester, clearBackground);
    await tester.tap(clearBackground);
    await tester.pumpAndSettle();

    // Cleared: ChartStyleValue.none() — a truly transparent surface, and the
    // panel still lays out and paints its rows.
    expect(style().backgroundColor.isNone, isTrue);
    expect(style().borderColor.isInherit, isTrue);
    expect(_renderBox(tester).debugValueSummaryBounds, isNot(Rect.zero));
    expect(_renderBox(tester).debugValueSummaryModel, isNotNull);

    // Toggling back returns to inherit, not to a stale explicit color.
    await tester.tap(clearBackground);
    await tester.pumpAndSettle();
    expect(style().backgroundColor.isInherit, isTrue);

    // Reset restores full theme inheritance after explicit overrides.
    await revealOption(
      tester,
      find.byKey(const ValueKey('value-summary-clear-border')),
    );
    await tester.tap(find.byKey(const ValueKey('value-summary-clear-border')));
    await tester.pumpAndSettle();
    expect(style().borderColor.isNone, isTrue);

    final reset = find.byKey(const ValueKey('value-summary-reset-style'));
    await revealOption(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(style().backgroundColor.isInherit, isTrue);
    expect(style().borderColor.isInherit, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pin and clear buttons drive the summary controller', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('value-summary-preset-pinned')));
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    expect(
      renderBox.debugValueSummarySnapshot?.origin,
      CartesianTrackingOrigin.fallback,
    );

    final pinLatest = find.byKey(const ValueKey('value-summary-pin-latest'));
    await revealOption(tester, pinLatest);
    await tester.tap(pinLatest);
    await tester.pumpAndSettle();

    final pinnedSnapshot = renderBox.debugValueSummarySnapshot;
    expect(pinnedSnapshot, isNotNull);
    expect(pinnedSnapshot!.origin, CartesianTrackingOrigin.pinned);
    expect(
      pinnedSnapshot.primaryPoint,
      const ChartPointRef(seriesId: 'summary-lactate', pointIndex: 7),
    );
    expect(pinnedSnapshot.dataX, closeTo(325, 1e-6));

    final clearPin = find.byKey(const ValueKey('value-summary-clear-pin'));
    await revealOption(tester, clearPin);
    await tester.tap(clearPin);
    await tester.pumpAndSettle();

    expect(
      renderBox.debugValueSummarySnapshot?.origin,
      CartesianTrackingOrigin.fallback,
    );
    expect(tester.takeException(), isNull);
  });
}

ChartRenderBox _renderBox(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
  );
  return finder.evaluate().single.renderObject! as ChartRenderBox;
}
