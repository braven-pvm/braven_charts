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

      // The line preset defaults to the fixed overlay.
      expect(presentation(), isA<CartesianValueSummaryOverlay>());

      final annotationSegment = find.text('Annotation');
      await revealOption(tester, annotationSegment);
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
      expect(readout, findsNothing);

      await tester.tap(find.text('Preset'));
      await tester.pumpAndSettle();
      expect(presentation(), isA<CartesianValueSummaryOverlay>());
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
