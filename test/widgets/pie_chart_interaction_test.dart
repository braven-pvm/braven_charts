import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'hover and tap resolve the exact pie slice and durable selection',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      ChartDataPoint? hovered;
      ChartDataPoint? tapped;
      String? tappedSeries;
      List<ChartDataPoint>? selected;

      await tester.pumpWidget(
        _host(
          controller: controller,
          onPointHover: (point, _) => hovered = point,
          onPointTap: (point, seriesId) {
            tapped = point;
            tappedSeries = seriesId;
          },
          interactionConfig: InteractionConfig(
            onSelectionChanged: (points) => selected = points,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chart = find.byKey(const ValueKey('interactive-pie'));
      final firstSlice = tester.getCenter(chart) + const Offset(70, 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getTopLeft(chart));
      await mouse.moveTo(firstSlice);
      await tester.pump(const Duration(milliseconds: 250));

      expect(hovered?.label, 'Subscriptions');

      await tester.tapAt(firstSlice);
      await tester.pumpAndSettle();

      expect(tapped?.label, 'Subscriptions');
      expect(tappedSeries, 'revenue');
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'revenue', pointIndex: 0),
      });
      expect(selected?.single.label, 'Subscriptions');

      await tester.tapAt(tester.getTopLeft(chart) + const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, isEmpty);
      expect(selected, isEmpty);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'arrow keys traverse slices and Enter selects the focused slice',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final keyboardActions = <String>[];

      await tester.pumpWidget(
        _host(
          controller: controller,
          interactionConfig: InteractionConfig(
            onKeyboardAction: (action, _) => keyboardActions.add(action),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chart = find.byKey(const ValueKey('interactive-pie'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getTopLeft(chart));
      await mouse.moveTo(tester.getCenter(chart) + const Offset(70, 0));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'revenue', pointIndex: 0),
      });

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'revenue', pointIndex: 1),
      });

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.selectedPointRefs, isEmpty);
      expect(
        keyboardActions,
        containsAll(<String>[
          'focus_next_slice',
          'select_slice',
          'clear_slice_selection',
        ]),
      );
      await mouse.removePointer();
    },
  );

  testWidgets('InteractionConfig.none keeps pie input disabled', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    ChartDataPoint? tapped;
    await tester.pumpWidget(
      _host(
        controller: controller,
        interactionConfig: InteractionConfig.none(),
        onPointTap: (point, _) => tapped = point,
      ),
    );
    await tester.pumpAndSettle();

    final chart = find.byKey(const ValueKey('interactive-pie'));
    await tester.tapAt(tester.getCenter(chart) + const Offset(70, 0));
    await tester.pumpAndSettle();

    expect(tapped, isNull);
    expect(controller.selectedPointRefs, isEmpty);
  });

  testWidgets(
    'canvas exposes slice semantics with value, share, order, and state',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(_host(controller: controller));
      await tester.pumpAndSettle();

      const unselectedLabel =
          'Subscriptions, 42.00 USD, 42.0 percent, slice 1 of 3, not selected';
      final subscription = find.semantics.byLabel(unselectedLabel);
      expect(subscription, findsOne);
      final node = subscription.evaluate().single;
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.didGainAccessibilityFocus(subscription);
      await tester.pumpAndSettle();
      expect(
        subscription
            .evaluate()
            .single
            .getSemanticsData()
            .flagsCollection
            .isFocused,
        Tristate.isTrue,
      );

      tester.semantics.tap(subscription);
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'revenue', pointIndex: 0),
      });
      expect(
        find.semantics.byLabel(
          'Subscriptions, 42.00 USD, 42.0 percent, slice 1 of 3, selected',
        ),
        findsOne,
      );
      semantics.dispose();
    },
  );

  testWidgets('slice legend selects without hiding and honors reduced motion', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        controller: controller,
        showLegend: true,
        disableAnimations: true,
        textScaler: const TextScaler.linear(1.4),
      ),
    );
    await tester.pumpAndSettle();

    final firstItem = find.byKey(const ValueKey('pie-legend-item-0'));
    expect(firstItem, findsOneWidget);
    expect(tester.getSize(firstItem).height, greaterThanOrEqualTo(48));
    final animatedContainer = find.descendant(
      of: firstItem,
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester.widget<AnimatedContainer>(animatedContainer).duration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'revenue', pointIndex: 0),
    });
    expect(controller.hiddenSeriesIds, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  required BravenChartController controller,
  InteractionConfig? interactionConfig,
  void Function(ChartDataPoint point, String seriesId)? onPointTap,
  void Function(ChartDataPoint? point, String? seriesId)? onPointHover,
  bool showLegend = false,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(500, 520),
        disableAnimations: disableAnimations,
        textScaler: textScaler,
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            height: showLegend ? 500 : 320,
            child: BravenChartPlus(
              key: const ValueKey('interactive-pie'),
              bravenChartController: controller,
              showLegend: showLegend,
              interactionConfig: interactionConfig,
              onPointTap: onPointTap,
              onPointHover: onPointHover,
              series: [
                PieChartSeries.fromMap(
                  id: 'revenue',
                  unit: 'USD',
                  values: const {
                    'Subscriptions': 42,
                    'Services': 31,
                    'Hardware': 27,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
