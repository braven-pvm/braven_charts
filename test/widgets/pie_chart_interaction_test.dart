import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
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

  testWidgets(
    'controller selection updates pie rendering and interaction callbacks',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();
      List<ChartDataPoint>? selected;

      await tester.pumpWidget(
        _host(
          controller: controller,
          interactionConfig: InteractionConfig(
            onSelectionChanged: (points) => selected = points,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final revision = controller.effectiveDocumentRevision.value!;
      final result = controller.selectPoint(
        const ChartPointRef(seriesId: 'revenue', pointIndex: 1),
        revision: revision,
      );
      expect(result, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'revenue', pointIndex: 1),
      });
      expect(selected?.single.label, 'Services');
      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      expect(renderBox.debugSelectedTooltipMarker?.markerIndex, 1);
      expect(
        find.semantics.byLabel(
          'Services, 31.00 USD, 31.0 percent, slice 2 of 3, selected',
        ),
        findsOne,
      );

      controller.clearPointSelection();
      await tester.pumpAndSettle();
      expect(controller.selectedPointRefs, isEmpty);
      expect(renderBox.debugSelectedTooltipMarker, isNull);
      expect(selected, isEmpty);
      semantics.dispose();
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
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    expect(renderBox.debugSelectedTooltipMarker?.markerIndex, 0);
    expect(controller.hiddenSeriesIds, isEmpty);

    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    expect(controller.selectedPointRefs, isEmpty);
    expect(renderBox.debugSelectedTooltipMarker, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom radial legend items receive resolved data and select', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    final builtItems = <RadialLegendItemData>[];

    await tester.pumpWidget(
      _host(
        controller: controller,
        showLegend: true,
        radialLegendItemBuilder: (context, item) {
          builtItems.add(item);
          return SizedBox(
            key: ValueKey('custom-legend-content-${item.visibleIndex}'),
            width: 180,
            child: Text(
              '${item.visibleIndex + 1} · ${item.category} · '
              '${item.shareLabel} · ${item.selected ? 'selected' : 'ready'}',
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final subscriptions = builtItems.lastWhere(
      (item) => item.category == 'Subscriptions',
    );
    expect(subscriptions.seriesId, 'revenue');
    expect(subscriptions.value, 42);
    expect(subscriptions.valueLabel, '42.00 USD');
    expect(subscriptions.shareLabel, '42.0%');
    expect(subscriptions.sourcePointIndices, [0]);
    expect(subscriptions.sourcePoints.single.label, 'Subscriptions');
    expect(
      controller.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );
    expect(find.text('1 · Subscriptions · 42.0% · ready'), findsOneWidget);
    expect(find.text('42.00 USD · 42.0%'), findsNothing);
    expect(
      find.semantics.byLabel(
        'Subscriptions, 42.00 USD, 42.0 percent, not selected',
      ),
      findsOne,
    );

    await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
    await tester.pumpAndSettle();

    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'revenue', pointIndex: 0),
    });
    expect(find.text('1 · Subscriptions · 42.0% · selected'), findsOneWidget);
    expect(
      find.semantics.byLabel(
        'Subscriptions, 42.00 USD, 42.0 percent, selected',
      ),
      findsOne,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('selected tooltip anchor follows current pie geometry', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    late StateSetter updateHost;
    var width = 300.0;
    var startAngle = -90.0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Center(
              child: SizedBox(
                width: width,
                height: 300,
                child: BravenChartPlus(
                  key: const ValueKey('moving-tooltip-pie'),
                  bravenChartController: controller,
                  theme: ChartTheme.light.copyWith(
                    pieChartTheme: const PieChartTheme(
                      animationMode: PieAnimationMode.none,
                    ),
                  ),
                  interactionConfig: const InteractionConfig(
                    tooltip: TooltipConfig(
                      triggerMode: TooltipTriggerMode.both,
                      showDelay: Duration.zero,
                      hideDelay: Duration.zero,
                    ),
                  ),
                  series: [
                    PieChartSeries.fromMap(
                      id: 'moving',
                      values: const {'A': 3, 'B': 2, 'C': 1},
                      pieStyle: PieChartStyle(
                        startAngleDegrees: startAngle,
                        animationMode: PieAnimationMode.none,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final revision = controller.effectiveDocumentRevision.value!;
    controller.selectPoint(
      const ChartPointRef(seriesId: 'moving', pointIndex: 0),
      revision: revision,
    );
    await tester.pumpAndSettle();
    var renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    final before = renderBox.debugSelectedTooltipMarker!.plotPosition;

    updateHost(() {
      width = 420;
      startAngle = 15;
    });
    await tester.pumpAndSettle();

    renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    final after = renderBox.debugSelectedTooltipMarker!.plotPosition;
    expect(after, isNot(before));
    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'moving', pointIndex: 0),
    });
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  required BravenChartController controller,
  InteractionConfig? interactionConfig,
  void Function(ChartDataPoint point, String seriesId)? onPointTap,
  void Function(ChartDataPoint? point, String? seriesId)? onPointHover,
  bool showLegend = false,
  RadialLegendItemBuilder? radialLegendItemBuilder,
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
              radialLegendItemBuilder: radialLegendItemBuilder,
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
