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

    expect(find.text('Tracking & Value Display'), findsOneWidget);
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

    // Multi-series: crosshair lines default OFF (CrosshairMode.none) while
    // the crosshair subsystem stays enabled and the summary keeps tracking —
    // the layer-independence demonstration.
    await tester.tap(
      find.byKey(const ValueKey('value-summary-preset-multiSeries')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Three riders, crosshair lines off'), findsOneWidget);
    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.interactionConfig?.crosshair.enabled, isTrue);
    expect(chart.interactionConfig?.crosshair.mode, CrosshairMode.none);
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

    // The toggle now lives in the Tracking Display section as one of the
    // independent layers (relocated from Standard Chart Options).
    final markerToggle = find.byKey(
      const ValueKey('value-summary-layer-data-markers'),
    );
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
    'tracking display layer toggles each drive exactly one config flag, '
    'compose in any combination, and reach the synchronized pair',
    (tester) async {
      await pumpPage(tester);

      InteractionConfig config() => tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
          .interactionConfig!;

      Future<void> toggle(String key, {double delta = 120}) async {
        final finder = find.byKey(ValueKey(key));
        await revealOption(tester, finder, delta: delta);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      // Defaults: lines and intersection markers on; tracking panel, point
      // tooltip, and axis value labels off; summary on. The crosshair
      // subsystem itself stays enabled so each layer is one flag.
      expect(config().crosshair.enabled, isTrue);
      expect(config().crosshair.mode, CrosshairMode.both);
      expect(config().crosshair.showTrackingTooltip, isFalse);
      expect(config().crosshair.showCoordinateLabels, isFalse);
      expect(config().crosshair.showIntersectionMarkers, isTrue);
      expect(config().tooltip.enabled, isFalse);
      expect(config().valueSummary.enabled, isTrue);

      // Crosshair lines off: only the mode changes — the subsystem and the
      // sibling layer flags are untouched.
      await toggle('value-summary-layer-crosshair-lines');
      expect(config().crosshair.enabled, isTrue);
      expect(config().crosshair.mode, CrosshairMode.none);
      expect(config().crosshair.showIntersectionMarkers, isTrue);
      expect(config().valueSummary.enabled, isTrue);

      // Classic tracking panel on while the lines stay off — and while the
      // value summary stays on: both feedback panels are active at once.
      await toggle('value-summary-layer-tracking-panel');
      expect(config().crosshair.showTrackingTooltip, isTrue);
      expect(config().crosshair.mode, CrosshairMode.none);
      expect(config().valueSummary.enabled, isTrue);

      // Point tooltip and axis value labels: one flag each.
      await toggle('value-summary-layer-point-tooltip');
      expect(config().tooltip.enabled, isTrue);
      await toggle('value-summary-layer-axis-labels');
      expect(config().crosshair.showCoordinateLabels, isTrue);

      // Intersection markers off: the only flag that changes.
      await toggle('value-summary-layer-intersection-markers');
      expect(config().crosshair.showIntersectionMarkers, isFalse);
      expect(config().crosshair.showTrackingTooltip, isTrue);

      // Value summary off while the classic panel stays on: toggling the
      // summary never implies any of the other four layers.
      await toggle('value-summary-enabled', delta: -120);
      expect(config().valueSummary.enabled, isFalse);
      expect(config().crosshair.showTrackingTooltip, isTrue);
      expect(config().tooltip.enabled, isTrue);

      // The composed combination reaches BOTH charts of the synchronized
      // pair. Crosshair lines return with the preset default; every other
      // layer choice persists across the switch.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-synchronized')),
      );
      await tester.pumpAndSettle();
      final charts = tester
          .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
          .toList();
      expect(charts, hasLength(2));
      for (final chart in charts) {
        final crosshair = chart.interactionConfig!.crosshair;
        expect(crosshair.enabled, isTrue);
        expect(crosshair.mode, CrosshairMode.both);
        expect(crosshair.showTrackingTooltip, isTrue);
        expect(crosshair.showCoordinateLabels, isTrue);
        expect(crosshair.showIntersectionMarkers, isFalse);
        expect(chart.interactionConfig!.tooltip.enabled, isTrue);
        expect(chart.interactionConfig!.valueSummary.enabled, isFalse);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'audit fix: the axis-lines toggle reaches the multi-axis per-series '
    'axes',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-multiAxis')),
      );
      await tester.pumpAndSettle();

      BravenChartPlus chart() =>
          tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      for (final series in chart().series) {
        expect(series.yAxisConfig?.showAxisLine, isTrue);
      }

      // Previously the per-series Y-axis configs bypassed the shared yAxis
      // parameter, so this standard toggle was dead on this preset.
      final axisToggle = find.text('Show Axis Lines');
      await revealOption(tester, axisToggle);
      await tester.tap(axisToggle);
      await tester.pumpAndSettle();
      for (final series in chart().series) {
        expect(series.yAxisConfig?.showAxisLine, isFalse);
      }
      expect(chart().xAxisConfig?.showAxisLine, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'audit fix: inapplicable controls hide per preset — legend on the '
    'synchronized pair, datapoint markers on candlestick',
    (tester) async {
      await pumpPage(tester);

      // Line preset: both controls exist.
      final legendToggle = find.text('Show Legend');
      await revealOption(tester, legendToggle);
      expect(legendToggle, findsOneWidget);

      // Synchronized pair: both compact charts render with legends
      // structurally off, so the dead control hides instead of silently
      // doing nothing.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-synchronized')),
      );
      await tester.pumpAndSettle();
      await revealOption(tester, find.text('Enable Zoom'));
      expect(find.text('Show Legend'), findsNothing);

      // Candlestick: the candles are the marks — there is no datapoint
      // marker layer to toggle, while the intersection-marker layer stays.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-candlestick')),
      );
      await tester.pumpAndSettle();
      final intersectionToggle = find.byKey(
        const ValueKey('value-summary-layer-intersection-markers'),
      );
      await revealOption(tester, intersectionToggle, delta: -120);
      expect(intersectionToggle, findsOneWidget);
      expect(
        find.byKey(const ValueKey('value-summary-layer-data-markers')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'audit fix: scrollbar toggles are exposed and flow into every preset '
    'chart',
    (tester) async {
      await pumpPage(tester);

      bool xScrollbar() => tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
          .showXScrollbar;
      bool yScrollbar() => tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
          .showYScrollbar;
      expect(xScrollbar(), isFalse);
      expect(yScrollbar(), isFalse);

      final xToggle = find.text('Show X Scrollbar');
      await revealOption(tester, xToggle);
      await tester.tap(xToggle);
      await tester.pumpAndSettle();
      expect(xScrollbar(), isTrue);

      final yToggle = find.text('Show Y Scrollbar');
      await revealOption(tester, yToggle);
      await tester.tap(yToggle);
      await tester.pumpAndSettle();
      expect(yScrollbar(), isTrue);

      // Both charts of the synchronized pair follow.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-synchronized')),
      );
      await tester.pumpAndSettle();
      final charts = tester
          .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
          .toList();
      expect(charts, hasLength(2));
      for (final chart in charts) {
        expect(chart.showXScrollbar, isTrue);
        expect(chart.showYScrollbar, isTrue);
      }
      expect(tester.takeException(), isNull);
    },
  );

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

      // Multi-series preset: the crosshair lines default off
      // (CrosshairMode.none), yet the intersection-marker layer and the
      // panel still snap to real samples on the shared resolve — the layers
      // are independent of the lines.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-multiSeries')),
      );
      await tester.pumpAndSettle();
      renderBox = _renderBox(tester);
      transform = renderBox.transform!;
      plotArea = renderBox.debugPlotArea;

      await pointer.moveTo(cursorFor(4.6, 250));
      await tester.pump();

      // No crosshair lines, but the marker layer still paints one snapped
      // marker per series.
      expect(renderBox.debugPaintedIntersectionMarkers, hasLength(3));
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
    // to a stale explicit color. (The subtitle length changes with the
    // tri-state, so the swatch may have shifted since the last reveal.)
    await revealOption(tester, blueSwatch);
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

    // A text-color pick promotes both fields the same way: the theme base
    // plus the chosen color, with the untouched size and weight dimensions
    // still coming from the theme.
    final tealSwatch = find.byKey(
      ValueKey('value-summary-text-color-${Colors.teal.toARGB32()}'),
    );
    await revealOption(tester, tealSwatch);
    await tester.tap(tealSwatch);
    await tester.pumpAndSettle();
    expect(
      style().textStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.valueStyle.copyWith(color: Colors.teal),
      ),
    );
    expect(
      style().labelStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.labelStyle.copyWith(color: Colors.teal),
      ),
    );

    // Color and size compose into ONE override per field.
    await revealOption(tester, sizeSlider);
    tester.widget<SliderOption>(sizeSlider).onChanged(13);
    await tester.pumpAndSettle();
    expect(
      style().textStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.valueStyle.copyWith(color: Colors.teal, fontSize: 13),
      ),
    );
    expect(
      style().labelStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.labelStyle.copyWith(color: Colors.teal, fontSize: 13),
      ),
    );

    // Clearing the palette removes only the color dimension — the size
    // override survives on the theme base color. For text, clear means
    // BACK TO THEME (the annotation dialogs' automatic), never a
    // color-less style.
    final textColorClear = find.byKey(
      const ValueKey('value-summary-text-color-clear'),
    );
    await revealOption(tester, textColorClear);
    await tester.tap(textColorClear);
    await tester.pumpAndSettle();
    expect(
      style().textStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.valueStyle.copyWith(fontSize: 13),
      ),
    );
    expect(
      style().labelStyle,
      isA<ChartStyleExplicit<TextStyle>>().having(
        (v) => v.value,
        'value',
        themeBase.labelStyle.copyWith(fontSize: 13),
      ),
    );

    // Reset clears the color dimension along with everything else.
    await revealOption(tester, tealSwatch);
    await tester.tap(tealSwatch);
    await tester.pumpAndSettle();
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

  testWidgets(
    'style controls skin both the summary and the shared tracking-panel '
    'TooltipStyle across presets, and cleared returns the panel to its '
    'default',
    (tester) async {
      await pumpPage(tester);

      CartesianValueSummaryStyle summaryStyle() => tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
          .interactionConfig!
          .valueSummary
          .style;
      TooltipStyle panelStyle() => tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus).first)
          .interactionConfig!
          .tooltip
          .style;

      // Untouched: the page emits a style equal to the library default, so
      // the tracking panel keeps its default look and the point tooltip's
      // resolver still treats it as "no override" (theme resolution).
      expect(panelStyle(), const TooltipStyle());

      // Background color skins both surfaces: the summary gets the explicit
      // tri-state override, the panel gets the plain color.
      final blueSwatch = find.byKey(
        ValueKey('value-summary-background-color-${Colors.blue.toARGB32()}'),
      );
      await revealOption(tester, blueSwatch);
      await tester.tap(blueSwatch);
      await tester.pumpAndSettle();
      expect(summaryStyle().backgroundColor, isA<ChartStyleExplicit<Color>>());
      expect(panelStyle().backgroundColor.toARGB32(), Colors.blue.toARGB32());

      // Background opacity composes into the color's alpha on the panel side
      // — TooltipStyle takes a single color, not a separate opacity.
      final opacitySlider = find.byKey(
        const ValueKey('value-summary-background-opacity'),
      );
      await revealOption(tester, opacitySlider);
      tester.widget<SliderOption>(opacitySlider).onChanged(0.5);
      await tester.pumpAndSettle();
      expect(
        summaryStyle().backgroundOpacity,
        const ChartStyleValue<double>.value(0.5),
      );
      expect(panelStyle().backgroundColor.a, closeTo(0.5, 0.01));
      expect(
        panelStyle().backgroundColor.toARGB32() & 0x00FFFFFF,
        Colors.blue.toARGB32() & 0x00FFFFFF,
      );

      // Border color, corner radius, padding, text color, and text size map
      // onto their exact TooltipStyle equivalents.
      final borderTeal = find.byKey(
        ValueKey('value-summary-border-color-${Colors.teal.toARGB32()}'),
      );
      await revealOption(tester, borderTeal);
      await tester.tap(borderTeal);
      await tester.pumpAndSettle();
      expect(panelStyle().borderColor.toARGB32(), Colors.teal.toARGB32());

      final radiusSlider = find.byKey(
        const ValueKey('value-summary-corner-radius'),
      );
      await revealOption(tester, radiusSlider);
      tester.widget<SliderOption>(radiusSlider).onChanged(16);
      await tester.pumpAndSettle();
      expect(
        summaryStyle().borderRadius,
        ChartStyleValue<BorderRadius>.value(BorderRadius.circular(16)),
      );
      expect(panelStyle().borderRadius, 16);

      final paddingSlider = find.byKey(
        const ValueKey('value-summary-panel-padding'),
      );
      await revealOption(tester, paddingSlider);
      tester.widget<SliderOption>(paddingSlider).onChanged(12);
      await tester.pumpAndSettle();
      expect(
        summaryStyle().padding,
        const ChartStyleValue<EdgeInsets>.value(EdgeInsets.all(12)),
      );
      expect(panelStyle().padding, 12);

      final textTeal = find.byKey(
        ValueKey('value-summary-text-color-${Colors.teal.toARGB32()}'),
      );
      await revealOption(tester, textTeal);
      await tester.tap(textTeal);
      await tester.pumpAndSettle();
      expect(panelStyle().textColor.toARGB32(), Colors.teal.toARGB32());

      final sizeSlider = find.byKey(const ValueKey('value-summary-text-size'));
      await revealOption(tester, sizeSlider);
      tester.widget<SliderOption>(sizeSlider).onChanged(14);
      await tester.pumpAndSettle();
      expect(panelStyle().fontSize, 14);

      // Text weight is summary-only — TooltipStyle has no weight field, so
      // a weight choice leaves the panel style untouched.
      final beforeWeight = panelStyle();
      final bold = find.byKey(const ValueKey('value-summary-text-weight-700'));
      await revealOption(tester, bold);
      await tester.tap(bold);
      await tester.pumpAndSettle();
      expect(panelStyle(), beforeWeight);

      // The composed panel style persists onto a second preset...
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-candlestick')),
      );
      await tester.pumpAndSettle();
      expect(panelStyle().borderRadius, 16);
      expect(panelStyle().padding, 12);
      expect(panelStyle().fontSize, 14);
      expect(panelStyle().textColor.toARGB32(), Colors.teal.toARGB32());
      expect(panelStyle().backgroundColor.a, closeTo(0.5, 0.01));

      // ...and reaches BOTH charts of the synchronized pair.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-synchronized')),
      );
      await tester.pumpAndSettle();
      final charts = tester.widgetList<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      expect(charts, hasLength(2));
      for (final chart in charts) {
        expect(chart.interactionConfig!.tooltip.style.borderRadius, 16);
        expect(chart.interactionConfig!.tooltip.style.padding, 12);
      }

      // Clearing the background color drops only that override — the panel
      // returns to its default background while the still-active opacity
      // override keeps composing onto it.
      await tester.tap(find.byKey(const ValueKey('value-summary-preset-line')));
      await tester.pumpAndSettle();
      final backgroundClear = find.byKey(
        const ValueKey('value-summary-background-color-clear'),
      );
      await revealOption(tester, backgroundClear);
      await tester.tap(backgroundClear);
      await tester.pumpAndSettle();
      expect(summaryStyle().backgroundColor.isNone, isTrue);
      expect(
        panelStyle().backgroundColor.toARGB32() & 0x00FFFFFF,
        const TooltipStyle().backgroundColor.toARGB32() & 0x00FFFFFF,
      );
      expect(panelStyle().backgroundColor.a, closeTo(0.5, 0.01));

      // Reset Style to Theme: the summary returns to full inheritance and
      // the tracking panel to its exact default style.
      final reset = find.byKey(const ValueKey('value-summary-reset-style'));
      await revealOption(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(panelStyle(), const TooltipStyle());
      expect(summaryStyle().backgroundColor.isInherit, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'workbench chrome wraps every single-chart preset; the synchronized '
    'pair skips it, following the cartesian precedent',
    (tester) async {
      await pumpPage(tester);

      const workbenchPresets = [
        'line',
        'multiSeries',
        'multiAxis',
        'candlestick',
        'pinned',
        'draggable',
      ];
      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      for (final preset in workbenchPresets) {
        await tester.tap(find.byKey(ValueKey('value-summary-preset-$preset')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('value-summary-workbench')),
          findsOneWidget,
          reason: '$preset preset should render inside the workbench',
        );
        expect(switcher, findsOneWidget);
        for (final mode in ['Chart', 'Data', 'Split', 'Source']) {
          expect(
            find.descendant(of: switcher, matching: find.text(mode)),
            findsOneWidget,
            reason: '$preset preset should offer the $mode chip',
          );
        }
        // Chart mode keeps exactly one mounted chart inside the chrome.
        expect(find.byType(BravenChartPlus), findsOneWidget);
      }

      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-synchronized')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BravenChartWorkbench), findsNothing);
      expect(switcher, findsNothing);
      expect(find.byType(BravenChartPlus), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'workbench modes: Data shows the table, Source emits the summary '
    'config, and the summary survives a mode round-trip',
    (tester) async {
      await pumpPage(tester);

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );

      // Data: the table replaces the chart pane with one row per sample.
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChartDataTable), findsOneWidget);
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      expect(workbench.workbenchController!.tableModel?.rowCount, 11);

      // Split: chart and table side by side — the summary stays painted on
      // the single mounted chart.
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Split')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(find.byType(ChartDataTable), findsOneWidget);
      expect(_renderBox(tester).debugValueSummaryBounds, isNot(Rect.zero));

      // Back to Chart: the summary pipeline is intact after the round-trip,
      // still resolving the latest-datum fallback.
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Chart')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(find.byType(ChartDataTable), findsNothing);
      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryModel, isNotNull);
      expect(renderBox.debugValueSummaryBounds, isNot(Rect.zero));
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.fallback,
      );

      // The candlestick preset's document works in Data mode too — the
      // table models OHLC rows without any extra options.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-candlestick')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChartDataTable), findsOneWidget);
      expect(workbench.workbenchController!.tableModel?.rowCount, 28);

      // Source last, back on the line preset: the generated Dart names the
      // page variable and carries the enabled value summary configuration.
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Chart')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('value-summary-preset-line')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChartSourceView), findsOneWidget);
      expect(
        workbench.workbenchController!.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains('final valueSummaryChart = BravenChartPlus('));
      expect(source, contains('valueSummary: CartesianValueSummaryConfig('));

      // Switching preset with a captured Source snapshot in hand invalidates
      // it and remounts the chart underneath the open pane. The pane re-emits
      // for the new preset and the hidden panes stop animating, so this
      // settles.
      await tester.tap(
        find.byKey(const ValueKey('value-summary-preset-candlestick')),
      );
      await tester.pumpAndSettle();
      expect(
        workbench.workbenchController!.generatedSource!.source,
        contains('CandlestickChartSeries('),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('value-summary-preset-line')));
      await tester.pumpAndSettle();

      // Chart once more: the summary is alive after the full mode tour.
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Chart')),
      );
      await tester.pumpAndSettle();
      expect(_renderBox(tester).debugValueSummaryModel, isNotNull);
      expect(_renderBox(tester).debugValueSummaryBounds, isNot(Rect.zero));
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
