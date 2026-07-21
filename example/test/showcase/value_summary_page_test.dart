// Copyright 2026 Braven Charts - Value Summary Page tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/value_summary_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/gestures.dart';
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

  Future<void> revealOption(
    WidgetTester tester,
    Finder target, {
    double delta = 120,
  }) async {
    final optionsScrollable = find
        .descendant(
          of: find.byType(OptionsPanel),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      target,
      delta,
      scrollable: optionsScrollable,
    );
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
      'draggable',
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

    // Draggable: annotation presentation with drag + clamp defaults.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-draggable')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Draggable summary panel'), findsOneWidget);
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series, hasLength(3));
    expect(
      chart.interactionConfig?.valueSummary.valuePolicy,
      CartesianValueSummaryValuePolicy.trackingThenLatest,
    );
    expect(
      chart.interactionConfig?.valueSummary.presentation,
      isA<CartesianValueSummaryAnnotation>()
          .having((p) => p.draggable, 'draggable', isTrue)
          .having((p) => p.clampToPlot, 'clampToPlot', isTrue),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('value mode toggle flows into the config, drives the crosshair '
      'interpolation with it, and survives preset switches', (tester) async {
    await pumpPage(tester);

    CartesianValueSummaryValueMode valueMode() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
        .interactionConfig!
        .valueSummary
        .valueMode;

    bool crosshairInterpolates() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
        .interactionConfig!
        .crosshair
        .interpolateValues;

    // Default: interpolated — the pre-existing curve-tracking behavior, with
    // the crosshair interpolation paired so marker, crosshair, and panel all
    // ride the curve together.
    expect(valueMode(), CartesianValueSummaryValueMode.interpolated);
    expect(crosshairInterpolates(), isTrue);

    final segmented = find.byKey(const ValueKey('value-summary-value-mode'));
    await revealOption(tester, segmented);
    final dataPointsSegment = find.descendant(
      of: segmented,
      matching: find.text('Data points'),
    );
    await tester.tap(dataPointsSegment);
    await tester.pumpAndSettle();
    expect(valueMode(), CartesianValueSummaryValueMode.dataPoints);
    // The showcase couples the visual tracking to the mode: Data points
    // turns crosshair interpolation off so the marker snaps with the rows.
    expect(crosshairInterpolates(), isFalse);

    // The choice is preset-independent: it survives switching presets and
    // applies to every chart of the synchronized pair.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-multiSeries')),
    );
    await tester.pumpAndSettle();
    expect(valueMode(), CartesianValueSummaryValueMode.dataPoints);
    expect(crosshairInterpolates(), isFalse);

    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-synchronized')),
    );
    await tester.pumpAndSettle();
    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList();
    expect(charts, hasLength(2));
    for (final chart in charts) {
      expect(
        chart.interactionConfig?.valueSummary.valueMode,
        CartesianValueSummaryValueMode.dataPoints,
      );
      expect(chart.interactionConfig?.crosshair.interpolateValues, isFalse);
    }

    // Back to the default segment: both settings return together.
    await revealOption(tester, segmented);
    final interpolatedSegment = find.descendant(
      of: segmented,
      matching: find.text('Interpolated'),
    );
    await tester.tap(interpolatedSegment);
    await tester.pumpAndSettle();
    expect(valueMode(), CartesianValueSummaryValueMode.interpolated);
    expect(crosshairInterpolates(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data markers toggle flows into every preset series', (
    tester,
  ) async {
    await pumpPage(tester);

    List<List<ChartSeries>> allSeries() => [
      for (final chart in tester.widgetList<BravenChartPlus>(
        find.byType(BravenChartPlus),
      ))
        chart.series,
    ];

    bool markerFlag(ChartSeries series) => switch (series) {
      LineChartSeries(:final showDataPointMarkers) => showDataPointMarkers,
      AreaChartSeries(:final showDataPointMarkers) => showDataPointMarkers,
      _ => throw StateError('unexpected series type: ${series.runtimeType}'),
    };

    // Markers default on so the tracked datum is visible on the curve.
    expect(markerFlag(allSeries().single.single), isTrue);

    final markerToggle = find.text('Show Data Markers');
    await revealOption(tester, markerToggle);
    await tester.tap(markerToggle);
    await tester.pumpAndSettle();
    expect(markerFlag(allSeries().single.single), isFalse);

    // The pinned preset no longer hardcodes markers on — it follows the
    // toggle like every other preset.
    await tester.tap(find.byKey(const ValueKey('value-summary-preset-pinned')));
    await tester.pumpAndSettle();
    expect(markerFlag(allSeries().single.single), isFalse);

    await revealOption(tester, markerToggle);
    await tester.tap(markerToggle);
    await tester.pumpAndSettle();
    expect(markerFlag(allSeries().single.single), isTrue);

    // Multi-series: the toggle reaches every series, area included.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-multiSeries')),
    );
    await tester.pumpAndSettle();
    expect(allSeries().single, hasLength(3));
    for (final series in allSeries().single) {
      expect(markerFlag(series), isTrue);
    }

    // Synchronized: both charts of the pair follow the toggle.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-synchronized')),
    );
    await tester.pumpAndSettle();
    expect(allSeries(), hasLength(2));
    for (final series in allSeries()) {
      expect(markerFlag(series.single), isTrue);
    }
    await revealOption(tester, markerToggle);
    await tester.tap(markerToggle);
    await tester.pumpAndSettle();
    for (final series in allSeries()) {
      expect(markerFlag(series.single), isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Data points mode paints the tracking marker at the real datum and every '
    'combination stays on the shared resolution',
    (tester) async {
      await pumpPage(tester);

      var renderBox = _renderBox(tester);
      var transform = renderBox.transform!;
      var plotArea = renderBox.debugPlotArea;

      Offset cursorFor(double dataX, double dataY) =>
          tester.getTopLeft(find.byType(BravenChartPlus)) +
          renderBox.plotToWidget(transform.dataToPlot(dataX, dataY));

      final pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(cursorFor(4.6, 30));
      await tester.pump();

      // Interpolated default: the marker rides the curve at the cursor X.
      expect(renderBox.debugPaintedIntersectionMarkers, hasLength(1));
      expect(
        renderBox.debugPaintedIntersectionMarkers.single.center.dx,
        closeTo(plotArea.left + transform.dataToPlot(4.6, 30).dx, 0.5),
      );

      // Switch to Data points: marker, crosshair, and panel snap together.
      final segmented = find.byKey(const ValueKey('value-summary-value-mode'));
      await revealOption(tester, segmented);
      await tester.tap(
        find.descendant(of: segmented, matching: find.text('Data points')),
      );
      await tester.pumpAndSettle();

      await pointer.moveTo(cursorFor(4.7, 30));
      await tester.pump();

      // The nearest real sample to x=4.7 is (4, 31): the marker pins to it
      // instead of following the cursor.
      final marker = renderBox.debugPaintedIntersectionMarkers.single;
      final datum = plotArea.topLeft + transform.dataToPlot(4, 31);
      expect(marker.center.dx, closeTo(datum.dx, 0.5));
      expect(marker.center.dy, closeTo(datum.dy, 0.5));

      // Coupling the crosshair interpolation to the mode keeps every
      // combination on the chart's single shared tracking resolution: the
      // summary's divergent-mode resolver is never consulted.
      expect(renderBox.debugSummaryTrackingResolveCount, 0);

      // Multi-series preset: the crosshair is disabled, yet the panel still
      // snaps to real samples through the summary-owned shared resolve.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-multiSeries')),
      );
      await tester.pumpAndSettle();
      renderBox = _renderBox(tester);
      transform = renderBox.transform!;
      plotArea = renderBox.debugPlotArea;

      await pointer.moveTo(cursorFor(4.6, 250));
      await tester.pump();

      // No crosshair — no painted markers.
      expect(renderBox.debugPaintedIntersectionMarkers, isEmpty);
      final snapshot = renderBox.debugValueSummarySnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.origin, CartesianTrackingOrigin.pointer);
      expect(snapshot.values, hasLength(3));
      for (final value in snapshot.values) {
        expect(value.isInterpolated, isFalse);
        expect(value.x, closeTo(4, 1e-6));
      }
      expect(renderBox.debugSummaryTrackingResolveCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('color palette clear affordance drives the tri-state style', (
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
    expect(style().accentColor.isInherit, isTrue);
    expect(style().backgroundOpacity.isInherit, isTrue);

    // The palette's leading clear swatch produces ChartStyleValue.none() — a
    // truly transparent surface, and the panel still lays out and paints.
    final backgroundClear = find.byKey(
      const ValueKey('value-summary-background-color-clear'),
    );
    await revealOption(tester, backgroundClear);
    await tester.tap(backgroundClear);
    await tester.pumpAndSettle();
    expect(style().backgroundColor.isNone, isTrue);
    expect(style().borderColor.isInherit, isTrue);
    expect(_renderBox(tester).debugValueSummaryBounds, isNot(Rect.zero));
    expect(_renderBox(tester).debugValueSummaryModel, isNotNull);

    // Picking a preset swatch promotes the field to an explicit override.
    final blueSwatch = find.byKey(
      ValueKey('value-summary-background-color-${Colors.blue.toARGB32()}'),
    );
    await revealOption(tester, blueSwatch);
    await tester.tap(blueSwatch);
    await tester.pumpAndSettle();
    expect(
      style().backgroundColor,
      isA<ChartStyleExplicit<Color>>().having(
        (v) => v.value.toARGB32(),
        'value',
        Colors.blue.toARGB32(),
      ),
    );

    // Tapping the selected swatch again toggles it off — back to none, never
    // to a stale explicit color.
    await tester.tap(blueSwatch);
    await tester.pumpAndSettle();
    expect(style().backgroundColor.isNone, isTrue);

    // Border and accent expose the same clear affordance.
    final borderClear = find.byKey(
      const ValueKey('value-summary-border-color-clear'),
    );
    await revealOption(tester, borderClear);
    await tester.tap(borderClear);
    await tester.pumpAndSettle();
    expect(style().borderColor.isNone, isTrue);

    final accentClear = find.byKey(
      const ValueKey('value-summary-accent-color-clear'),
    );
    await revealOption(tester, accentClear);
    await tester.tap(accentClear);
    await tester.pumpAndSettle();
    expect(style().accentColor.isNone, isTrue);

    // Reset restores full theme inheritance after explicit overrides.
    final reset = find.byKey(const ValueKey('value-summary-reset-style'));
    await revealOption(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(style().backgroundColor.isInherit, isTrue);
    expect(style().borderColor.isInherit, isTrue);
    expect(style().accentColor.isInherit, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('label-value gap and width sliders drive the tri-state style', (
    tester,
  ) async {
    await pumpPage(tester);

    CartesianValueSummaryStyle style() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .interactionConfig!
        .valueSummary
        .style;

    // Untouched sliders leave every field inheriting the theme default —
    // the spread layout with the theme's min/max widths.
    expect(style().labelValueGap.isInherit, isTrue);
    expect(style().minWidth.isInherit, isTrue);
    expect(style().maxWidth.isInherit, isTrue);

    // First touch of the gap slider promotes the field to an explicit
    // override: the packed layout.
    final gapSlider = find.byKey(
      const ValueKey('value-summary-label-value-gap'),
    );
    await revealOption(tester, gapSlider);
    tester.widget<SliderOption>(gapSlider).onChanged(24);
    await tester.pumpAndSettle();
    expect(
      style().labelValueGap,
      const ChartStyleValue<double>.value(24.0),
    );

    // Min and max width sliders follow the same first-touch promotion.
    final minWidthSlider = find.byKey(
      const ValueKey('value-summary-min-width'),
    );
    await revealOption(tester, minWidthSlider);
    tester.widget<SliderOption>(minWidthSlider).onChanged(120);
    await tester.pumpAndSettle();
    expect(style().minWidth, const ChartStyleValue<double>.value(120.0));

    final maxWidthSlider = find.byKey(
      const ValueKey('value-summary-max-width'),
    );
    await revealOption(tester, maxWidthSlider);
    tester.widget<SliderOption>(maxWidthSlider).onChanged(320);
    await tester.pumpAndSettle();
    expect(style().maxWidth, const ChartStyleValue<double>.value(320.0));

    // The Spread affordance returns only the gap to theme inheritance —
    // the width overrides stay put.
    final spread = find.byKey(const ValueKey('value-summary-gap-spread'));
    await revealOption(tester, spread);
    await tester.tap(spread);
    await tester.pumpAndSettle();
    expect(style().labelValueGap.isInherit, isTrue);
    expect(style().minWidth, const ChartStyleValue<double>.value(120.0));
    expect(style().maxWidth, const ChartStyleValue<double>.value(320.0));

    // Reset Style to Theme restores full inheritance.
    final reset = find.byKey(const ValueKey('value-summary-reset-style'));
    await revealOption(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(style().labelValueGap.isInherit, isTrue);
    expect(style().minWidth.isInherit, isTrue);
    expect(style().maxWidth.isInherit, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text size and weight controls compose one row-text override', (
    tester,
  ) async {
    await pumpPage(tester);

    CartesianValueSummaryStyle style() => tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .interactionConfig!
        .valueSummary
        .style;

    // The page runs without a theme override, so the charts resolve the
    // summary against the light component theme — the base the page must
    // build its overrides from.
    const themeBase = CartesianValueSummaryTheme.light;

    // Untouched: both text fields inherit the theme's row styles.
    expect(style().textStyle.isInherit, isTrue);
    expect(style().labelStyle.isInherit, isTrue);

    // First touch of the size slider promotes BOTH fields to explicit
    // overrides built from the theme preset's corresponding base styles:
    // fontSize is the chosen value while everything else — color, the value
    // style's w500 weight — still comes from the theme.
    final sizeSlider = find.byKey(const ValueKey('value-summary-text-size'));
    await revealOption(tester, sizeSlider);
    tester.widget<SliderOption>(sizeSlider).onChanged(14);
    await tester.pumpAndSettle();
    expect(
      style().textStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.valueStyle.copyWith(fontSize: 14),
      ),
    );
    expect(
      style().labelStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.labelStyle.copyWith(fontSize: 14),
      ),
    );

    // Weight selection composes onto the same override: the chosen fontSize
    // is preserved and both fields carry size and weight together.
    final semiBold = find.byKey(
      const ValueKey('value-summary-text-weight-600'),
    );
    await revealOption(tester, semiBold);
    await tester.tap(semiBold);
    await tester.pumpAndSettle();
    expect(
      style().textStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.valueStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    expect(
      style().labelStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.labelStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Reset Style to Theme returns both fields to inheritance.
    final reset = find.byKey(const ValueKey('value-summary-reset-style'));
    await revealOption(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(style().textStyle.isInherit, isTrue);
    expect(style().labelStyle.isInherit, isTrue);

    // Weight-only touch after the reset: the size dimension stays on the
    // theme base — the override carries only what was touched, so the label
    // style keeps its theme size and the value style keeps 11/w500 -> w700.
    final bold = find.byKey(const ValueKey('value-summary-text-weight-700'));
    await revealOption(tester, bold);
    await tester.tap(bold);
    await tester.pumpAndSettle();
    expect(
      style().textStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.valueStyle.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    expect(
      style().labelStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.labelStyle.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    // And a final reset restores full inheritance again.
    await revealOption(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(style().textStyle.isInherit, isTrue);
    expect(style().labelStyle.isInherit, isTrue);
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

  testWidgets(
    'draggable preset wires an annotation presentation to the concrete '
    'default controller',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-draggable')),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      final summary = chart.interactionConfig!.valueSummary;
      expect(summary.enabled, isTrue);
      expect(
        summary.presentation,
        isA<CartesianValueSummaryAnnotation>()
            .having((p) => p.draggable, 'draggable', isTrue)
            .having((p) => p.clampToPlot, 'clampToPlot', isTrue),
      );
      // The page's single controller is the package's concrete class: only
      // its resetPlacement handshake can reach the chart.
      expect(
        summary.controller,
        isA<DefaultCartesianValueSummaryController>(),
      );
      expect(summary.onPlacementChanged, isNotNull);

      // The panel is painted and acquirable as a drag target.
      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryBounds, isNot(Rect.zero));
      expect(renderBox.valueSummaryDragTarget, isNotNull);

      // The Draggable Panel controls auto-show with an empty readout, and
      // the reset button is present.
      final readout = find.byKey(
        const ValueKey('value-summary-placement-readout'),
      );
      await revealOption(tester, readout);
      expect(readout, findsOneWidget);
      expect(find.textContaining('No committed placement'), findsOneWidget);
      final reset = find.byKey(
        const ValueKey('value-summary-reset-placement'),
      );
      await revealOption(tester, reset);
      expect(reset, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draggable and clamp toggles flow into the annotation config', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-draggable')),
    );
    await tester.pumpAndSettle();

    CartesianValueSummaryAnnotation annotation() =>
        tester
                .widget<BravenChartPlus>(find.byType(BravenChartPlus))
                .interactionConfig!
                .valueSummary
                .presentation
            as CartesianValueSummaryAnnotation;

    final draggableToggle = find.byKey(
      const ValueKey('value-summary-draggable'),
    );
    await revealOption(tester, draggableToggle);
    await tester.tap(draggableToggle);
    await tester.pumpAndSettle();
    expect(annotation().draggable, isFalse);
    expect(annotation().clampToPlot, isTrue);
    // A non-draggable annotation panel is no longer a drag target.
    expect(_renderBox(tester).valueSummaryDragTarget, isNull);

    await tester.tap(draggableToggle);
    await tester.pumpAndSettle();
    expect(annotation().draggable, isTrue);

    final clampToggle = find.byKey(const ValueKey('value-summary-clamp'));
    await revealOption(tester, clampToggle);
    await tester.tap(clampToggle);
    await tester.pumpAndSettle();
    expect(annotation().clampToPlot, isFalse);
    expect(annotation().draggable, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'presentation override switches any preset between overlay and '
    'annotation',
    (tester) async {
      await pumpPage(tester);

      CartesianValueSummaryPresentation presentation() => tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .interactionConfig!
          .valueSummary
          .presentation;

      // The line preset defaults to the fixed overlay, and the helper line
      // spells out the resolved kind (Value policy dropdown convention).
      expect(presentation(), isA<CartesianValueSummaryOverlay>());

      final annotationSegment = find.text('Annotation');
      await revealOption(tester, annotationSegment);
      expect(find.text('Preset default'), findsOneWidget);
      expect(find.text('currently: overlay'), findsOneWidget);
      await tester.tap(annotationSegment);
      await tester.pumpAndSettle();
      expect(
        presentation(),
        isA<CartesianValueSummaryAnnotation>().having(
          (p) => p.draggable,
          'draggable',
          isTrue,
        ),
      );
      expect(find.text('currently: annotation'), findsOneWidget);
      // The Draggable Panel section auto-shows with the override.
      final readout = find.byKey(
        const ValueKey('value-summary-placement-readout'),
      );
      await revealOption(tester, readout);
      expect(readout, findsOneWidget);

      // Scroll back up to the Summary section's presentation control.
      final overlaySegment = find.text('Overlay');
      await revealOption(tester, overlaySegment, delta: -120);
      await tester.tap(overlaySegment);
      await tester.pumpAndSettle();
      expect(presentation(), isA<CartesianValueSummaryOverlay>());
      expect(find.text('currently: overlay'), findsOneWidget);
      expect(readout, findsNothing);

      await tester.tap(find.text('Preset default'));
      await tester.pumpAndSettle();
      expect(presentation(), isA<CartesianValueSummaryOverlay>());
      expect(find.text('currently: overlay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'synchronized preset with the Annotation override exposes no placement '
    'or pin controls',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-synchronized')),
      );
      await tester.pumpAndSettle();

      final annotationSegment = find.text('Annotation');
      await revealOption(tester, annotationSegment);
      await tester.tap(annotationSegment);
      await tester.pumpAndSettle();

      // The override took effect on both synchronized charts.
      final charts = tester
          .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
          .toList();
      expect(charts, hasLength(2));
      for (final chart in charts) {
        expect(
          chart.interactionConfig?.valueSummary.presentation,
          isA<CartesianValueSummaryAnnotation>(),
        );
      }

      // The synchronized charts run without the page's shared controller,
      // so the Draggable Panel and Pinning sections must stay hidden.
      expect(
        find.byKey(const ValueKey('value-summary-placement-readout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('value-summary-reset-placement')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('value-summary-pin-latest')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('value-summary-clear-pin')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a committed drag fills the placement readout and Reset Placement '
    'restores the configured position through the controller',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-draggable')),
      );
      await tester.pumpAndSettle();

      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));

      final gesture = await tester.startGesture(
        _panelCenter(tester, renderBox),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(40, 25));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // The committed placement is applied to the panel and surfaced through
      // onPlacementChanged into the page readout: configured (12, 12) plus
      // the drag delta, relative to the topLeft anchor.
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(52, 37));
      final readout = find.byKey(
        const ValueKey('value-summary-placement-readout'),
      );
      await revealOption(tester, readout);
      expect(
        find.textContaining('topLeft anchor, offset (52.0, 37.0)'),
        findsOneWidget,
      );

      // Reset Placement goes through DefaultCartesianValueSummaryController:
      // the chart-side handshake restores the configured placement, and the
      // readout empties.
      final reset = find.byKey(
        const ValueKey('value-summary-reset-placement'),
      );
      await revealOption(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));
      expect(find.textContaining('No committed placement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

ChartRenderBox _renderBox(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
  );
  return finder.evaluate().single.renderObject! as ChartRenderBox;
}

/// Screen-space center of the currently painted summary panel.
Offset _panelCenter(WidgetTester tester, ChartRenderBox renderBox) {
  final bounds = renderBox.debugValueSummaryBounds;
  assert(bounds != Rect.zero, 'value summary panel is not painted');
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(bounds.center);
}
