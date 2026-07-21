// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Task 15 accessibility contract for the Cartesian value summary: one grouped
// semantic region per visible summary (both presentations), title + context in
// the region label, unit-carrying rows in meaningful source order as the
// region value, no duplicate traversal against the crosshair panel, identity-
// debounced announcements, and move/reset/pin semantic actions.

import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _moveLeft = CustomSemanticsAction(label: 'Move left');
const _moveRight = CustomSemanticsAction(label: 'Move right');
const _moveUp = CustomSemanticsAction(label: 'Move up');
const _moveDown = CustomSemanticsAction(label: 'Move down');
const _resetPosition = CustomSemanticsAction(label: 'Reset position');
const _pinValue = CustomSemanticsAction(label: 'Pin value');
const _clearPin = CustomSemanticsAction(label: 'Clear pin');

void main() {
  group('grouped semantic region', () {
    testWidgets(
      'fixed overlay exposes one labelled region with unit-carrying rows in '
      'source order',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_host(interaction: _summaryInteraction()));
        await tester.pumpAndSettle();

        final finder = find.semantics.byLabel(RegExp('^Value summary'));
        expect(finder, findsOne);
        final data = finder.evaluate().single.getSemanticsData();

        // Multi-series region: label carries the resolved X context, the
        // value carries every row in source order with its unit.
        expect(data.label, 'Value summary, 10');
        expect(data.value, 'Speed: 12 km/h, Power: 8 W');

        // The fixed overlay is a passive region: never focusable, no
        // actions. (Tristate.none means the focus flag is not exposed at
        // all, i.e. the node is not focusable.)
        expect(data.flagsCollection.isFocused, ui.Tristate.none);
        expect(data.customSemanticsActionIds ?? const <int>[], isEmpty);
        semantics.dispose();
      },
    );

    testWidgets('single-series region labels title and context', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(interaction: _summaryInteraction(), singleSeries: true),
      );
      await tester.pumpAndSettle();

      final finder = find.semantics.byLabel(RegExp('^Value summary'));
      expect(finder, findsOne);
      final data = finder.evaluate().single.getSemanticsData();
      expect(data.label, 'Value summary, Speed, 10');
      expect(data.value, 'Value: 12');
      semantics.dispose();
    });

    testWidgets(
      'crosshair tracking panel never duplicates the summary value list',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_host(interaction: _summaryInteraction()));
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
        await tester.pump();

        // The crosshair tracking panel paints the same values on canvas but
        // must not add a second, identically-labelled traversal stop.
        final summaryFinder = find.semantics.byLabel(RegExp('^Value summary'));
        expect(summaryFinder, findsOne);
        final summaryData = summaryFinder.evaluate().single.getSemanticsData();
        expect(summaryData.value, contains('Speed: 7 km/h'));

        final duplicates = _allSemanticsData(tester).where(
          (data) =>
              !data.label.startsWith('Value summary') &&
              (data.label.contains('Speed: 7 km/h') ||
                  data.value.contains('Speed: 7 km/h')),
        );
        expect(duplicates, isEmpty);
        semantics.dispose();
      },
    );

    testWidgets('no region while the policy resolves nothing', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          interaction: _summaryInteraction(
            valuePolicy: CartesianValueSummaryValuePolicy.explicitOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel(RegExp('^Value summary')), findsNothing);
      semantics.dispose();
    });
  });

  group('annotation presentation', () {
    testWidgets(
      'draggable annotation region is focusable and exposes move and reset '
      'actions',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(interaction: _annotationInteraction(draggable: true)),
        );
        await tester.pumpAndSettle();

        final finder = find.semantics.byLabel(RegExp('^Value summary'));
        expect(finder, findsOne);
        final data = finder.evaluate().single.getSemanticsData();
        // Focusable (the flag is exposed) though not currently focused.
        expect(data.flagsCollection.isFocused, isNot(ui.Tristate.none));

        final actionIds = data.customSemanticsActionIds ?? const <int>[];
        for (final action in const [
          _moveLeft,
          _moveRight,
          _moveUp,
          _moveDown,
          _resetPosition,
        ]) {
          expect(
            actionIds,
            contains(CustomSemanticsAction.getIdentifier(action)),
            reason: 'expected ${action.label}',
          );
        }
        // No controller attached: pin actions must not appear.
        expect(
          actionIds,
          isNot(contains(CustomSemanticsAction.getIdentifier(_pinValue))),
        );
        expect(
          actionIds,
          isNot(contains(CustomSemanticsAction.getIdentifier(_clearPin))),
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'non-draggable annotation region exists without focus or actions',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(interaction: _annotationInteraction(draggable: false)),
        );
        await tester.pumpAndSettle();

        final finder = find.semantics.byLabel(RegExp('^Value summary'));
        expect(finder, findsOne);
        final data = finder.evaluate().single.getSemanticsData();
        expect(data.flagsCollection.isFocused, ui.Tristate.none);
        expect(data.customSemanticsActionIds ?? const <int>[], isEmpty);
        semantics.dispose();
      },
    );

    testWidgets('move and reset actions move and restore the panel', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final placements = <ChartOverlayPlacement>[];
      await tester.pumpWidget(
        _host(
          interaction: _annotationInteraction(
            draggable: true,
            onPlacementChanged: placements.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));

      _performCustomAction(tester, _moveRight);
      await tester.pump();
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(22, 12));
      expect(placements, hasLength(1));
      expect(placements.single.offset, const Offset(22, 12));

      _performCustomAction(tester, _moveDown);
      await tester.pump();
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(22, 22));
      expect(placements, hasLength(2));

      _performCustomAction(tester, _resetPosition);
      await tester.pump();
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));
      expect(placements, hasLength(3));
      expect(placements.last, ChartOverlayPlacement.topLeft);
      semantics.dispose();
    });
  });

  group('pin actions', () {
    testWidgets(
      'pin and clear-pin appear only while a pin policy has a controller, '
      'and drive it',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = DefaultCartesianValueSummaryController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            interaction: _summaryInteraction(
              valuePolicy:
                  CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        var actionIds = _summaryActionIds(tester);
        expect(
          actionIds,
          contains(CustomSemanticsAction.getIdentifier(_pinValue)),
        );
        expect(
          actionIds,
          isNot(contains(CustomSemanticsAction.getIdentifier(_clearPin))),
        );

        _performCustomAction(tester, _pinValue);
        await tester.pump();
        expect(
          controller.pinnedPoint,
          const ChartPointRef(seriesId: 'speed', pointIndex: 5),
        );
        expect(
          renderBox.debugValueSummarySnapshot?.origin,
          CartesianTrackingOrigin.pinned,
        );

        actionIds = _summaryActionIds(tester);
        expect(
          actionIds,
          contains(CustomSemanticsAction.getIdentifier(_clearPin)),
        );
        expect(
          actionIds,
          isNot(contains(CustomSemanticsAction.getIdentifier(_pinValue))),
        );

        _performCustomAction(tester, _clearPin);
        await tester.pump();
        expect(controller.pinnedPoint, isNull);
        expect(
          renderBox.debugValueSummarySnapshot?.origin,
          CartesianTrackingOrigin.fallback,
        );
        semantics.dispose();
      },
    );

    testWidgets('no pin actions without a pin policy', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = DefaultCartesianValueSummaryController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(interaction: _summaryInteraction(controller: controller)),
      );
      await tester.pumpAndSettle();

      final actionIds = _summaryActionIds(tester);
      expect(
        actionIds,
        isNot(contains(CustomSemanticsAction.getIdentifier(_pinValue))),
      );
      expect(
        actionIds,
        isNot(contains(CustomSemanticsAction.getIdentifier(_clearPin))),
      );
      semantics.dispose();
    });
  });

  group('announcements', () {
    testWidgets(
      'announceChanges announces once per datum identity change, never per '
      'pointer move or repaint',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(interaction: _summaryInteraction(announceChanges: true)),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        // The initial fallback appearance is not a change: silence.
        expect(tester.takeAnnouncements(), isEmpty);
        final reduceBaseline = renderBox.debugValueSummaryReduceCount;

        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);

        // Sweep: fallback(10) -> 0 -> 2 -> 2 (sub-datum) -> 4.
        await pointer.moveTo(_plotTarget(tester, renderBox, 0.3, 6));
        await tester.pump();
        await pointer.moveTo(_plotTarget(tester, renderBox, 2.1, 6));
        await tester.pump();
        await pointer.moveTo(_plotTarget(tester, renderBox, 2.6, 6));
        await tester.pump();

        // A stationary repaint announces nothing either.
        renderBox.markNeedsPaint();
        await tester.pump();

        await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
        await tester.pump();
        await tester.pump();

        final announcements = tester.takeAnnouncements();
        final reduceDelta =
            renderBox.debugValueSummaryReduceCount - reduceBaseline;
        // One announcement per resolved datum identity change (10->0, 0->2,
        // 2->4); the sub-datum move and the repaint stay silent. The
        // announcement cadence can never exceed the reduce cadence.
        expect(announcements, hasLength(3));
        expect(announcements.length, lessThanOrEqualTo(reduceDelta));
        for (final announcement in announcements) {
          expect(announcement.message, startsWith('Value summary'));
        }
        expect(announcements.last.message, contains('Speed: 7 km/h'));
        semantics.dispose();
      },
    );

    testWidgets('announceChanges false stays silent through a sweep', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(interaction: _summaryInteraction()));
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 0.3, 6));
      await tester.pump();
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();
      await tester.pump();

      expect(tester.takeAnnouncements(), isEmpty);
      semantics.dispose();
    });
  });
}

InteractionConfig _summaryInteraction({
  CartesianValueSummaryValuePolicy valuePolicy =
      CartesianValueSummaryValuePolicy.trackingThenLatest,
  CartesianValueSummaryController? controller,
  bool announceChanges = false,
}) {
  return InteractionConfig(
    crosshair: const CrosshairConfig(
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: false,
    ),
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      valuePolicy: valuePolicy,
      controller: controller,
      announceChanges: announceChanges,
    ),
  );
}

InteractionConfig _annotationInteraction({
  required bool draggable,
  ValueChanged<ChartOverlayPlacement>? onPlacementChanged,
}) {
  return InteractionConfig(
    crosshair: const CrosshairConfig(
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: false,
    ),
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      presentation: CartesianValueSummaryPresentation.annotation(
        draggable: draggable,
      ),
      onPlacementChanged: onPlacementChanged,
    ),
  );
}

Widget _host({
  required InteractionConfig interaction,
  bool singleSeries = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 640,
          height: 300,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: interaction,
            series: [
              LineChartSeries(
                id: 'speed',
                name: 'Speed',
                yAxisConfig: YAxisConfig(
                  position: YAxisPosition.left,
                  unit: 'km/h',
                ),
                points: const [
                  ChartDataPoint(x: 0, y: 4),
                  ChartDataPoint(x: 2, y: 8),
                  ChartDataPoint(x: 4, y: 7),
                  ChartDataPoint(x: 6, y: 11),
                  ChartDataPoint(x: 8, y: 9),
                  ChartDataPoint(x: 10, y: 12),
                ],
              ),
              if (!singleSeries)
                LineChartSeries(
                  id: 'power',
                  name: 'Power',
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.right,
                    unit: 'W',
                  ),
                  points: const [
                    ChartDataPoint(x: 0, y: 2),
                    ChartDataPoint(x: 2, y: 5),
                    ChartDataPoint(x: 4, y: 3),
                    ChartDataPoint(x: 6, y: 6),
                    ChartDataPoint(x: 8, y: 4),
                    ChartDataPoint(x: 10, y: 8),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

ChartRenderBox _renderBox(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
  );
  return finder.evaluate().single.renderObject! as ChartRenderBox;
}

Offset _plotTarget(
  WidgetTester tester,
  ChartRenderBox renderBox,
  double dataX,
  double dataY,
) {
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(renderBox.transform!.dataToPlot(dataX, dataY));
}

/// Every [SemanticsData] in the current semantics tree.
List<SemanticsData> _allSemanticsData(WidgetTester tester) {
  final result = <SemanticsData>[];
  void visit(SemanticsNode node) {
    result.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return result;
}

/// Custom semantic action ids exposed by the summary region.
List<int> _summaryActionIds(WidgetTester tester) {
  final finder = find.semantics.byLabel(RegExp('^Value summary'));
  expect(finder, findsOne);
  return finder.evaluate().single.getSemanticsData().customSemanticsActionIds ??
      const <int>[];
}

/// Invokes [action] on the summary region node.
void _performCustomAction(WidgetTester tester, CustomSemanticsAction action) {
  final finder = find.semantics.byLabel(RegExp('^Value summary'));
  expect(finder, findsOne);
  final node = finder.evaluate().single;
  tester.binding.pipelineOwner.semanticsOwner!.performAction(
    node.id,
    ui.SemanticsAction.customAction,
    CustomSemanticsAction.getIdentifier(action),
  );
}
