// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Task 10 draggable annotation-style value summary: drag acquisition from the
// panel bounds, one committed placement per drag, frozen tracking during the
// drag, plot clamping on drag and resize, keyboard movement, and the concrete
// controller's resetPlacement round trip. These tests drive a real
// BravenChartPlus and probe the render box's value summary debug hooks.

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/value_summary_annotation_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('static (non-draggable) annotation presentation', () {
    testWidgets('renders at the configured placement and never hit-tests', (
      tester,
    ) async {
      final placements = <ChartOverlayPlacement>[];
      await tester.pumpWidget(
        _host(
          interaction: _annotationInteraction(
            draggable: false,
            onPlacementChanged: placements.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final bounds = renderBox.debugValueSummaryBounds;
      expect(bounds, isNot(Rect.zero));
      expect(bounds.topLeft, const Offset(12, 12));

      // The static panel never intercepts pointers within its bounds.
      final panelCenter = _panelCenter(tester, renderBox);
      expect(
        renderBox.hitTestElements(panelCenter),
        isNot(isA<ValueSummaryAnnotationElement>()),
      );

      // A drag across the panel neither moves it nor commits a placement.
      final gesture = await tester.startGesture(
        panelCenter,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));
      expect(placements, isEmpty);
    });
  });

  group('pointer drag', () {
    testWidgets(
      'drag moves the panel continuously and commits exactly one placement',
      (tester) async {
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              onPlacementChanged: placements.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));

        final gesture = await tester.startGesture(
          _panelCenter(tester, renderBox),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(10, 5));
        await tester.pump();
        await gesture.moveBy(const Offset(10, 10));
        await tester.pump();

        // Continuous visual update, no commit yet.
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(12 + 20, 12 + 15),
        );
        expect(placements, isEmpty);

        await gesture.moveBy(const Offset(10, 5));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // Exactly one committed anchor-relative placement on release.
        expect(placements, hasLength(1));
        expect(placements.single.anchor, Alignment.topLeft);
        expect(placements.single.offset, const Offset(12 + 30, 12 + 20));

        // The committed placement stays applied on subsequent frames.
        renderBox.markNeedsPaint();
        await tester.pump();
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(42, 32),
        );
      },
    );

    testWidgets(
      'commit recomputes the offset relative to a far-edge anchor',
      (tester) async {
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              placement: const ChartOverlayPlacement(
                anchor: Alignment.bottomRight,
                offset: Offset(12, 12),
              ),
              onPlacementChanged: placements.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        final plot = renderBox.debugPlotArea;
        final bounds = renderBox.debugValueSummaryBounds;
        // Anchored bottom-right with a 12px interior inset.
        expect(bounds.right, closeTo(plot.width - 12, 0.01));
        expect(bounds.bottom, closeTo(plot.height - 12, 0.01));

        final gesture = await tester.startGesture(
          _panelCenter(tester, renderBox),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(-30, -20));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // Moving toward the plot interior grows the inset on both axes.
        expect(placements, hasLength(1));
        expect(placements.single.anchor, Alignment.bottomRight);
        expect(placements.single.offset.dx, closeTo(42, 0.01));
        expect(placements.single.offset.dy, closeTo(32, 0.01));
      },
    );

    testWidgets('tracking, crosshair, and selection freeze during the drag', (
      tester,
    ) async {
      await tester.pumpWidget(_host(interaction: _annotationInteraction()));
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      // Establish live tracking first.
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.pointer,
      );

      // Move onto the panel and let the deferred hover hit test flip the
      // cursor to `move` (50ms throttle). The cursor setState triggers the
      // first widget rebuild, which syncs the element generator version and
      // regenerates the series picture once — capture identities after that
      // settles so the drag itself is proven invalidation-free.
      await pointer.moveTo(_panelCenter(tester, renderBox));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      final frozenSnapshot = renderBox.debugValueSummarySnapshot;
      final frozenModel = renderBox.debugValueSummaryModel;
      final reduceCount = renderBox.debugValueSummaryReduceCount;
      final computeCount = renderBox.debugTrackingComputeCount;
      final hoveredMarker = renderBox.coordinator.hoveredMarker;
      final seriesPicture = renderBox.debugSeriesCachePicture;
      expect(seriesPicture, isNotNull);

      await pointer.down(_panelCenter(tester, renderBox));
      await pointer.moveBy(const Offset(40, 30));
      await tester.pump();
      await pointer.moveBy(const Offset(40, 30));
      await tester.pump();

      // Displayed content and counters are frozen while dragging.
      expect(renderBox.debugValueSummarySnapshot, same(frozenSnapshot));
      expect(renderBox.debugValueSummaryModel, same(frozenModel));
      expect(renderBox.debugValueSummaryReduceCount, reduceCount);
      expect(renderBox.debugTrackingComputeCount, computeCount);

      // The drag repaints only the feedback layer: the cached series picture
      // instance must survive the whole gesture.
      expect(renderBox.debugSeriesCachePicture, same(seriesPicture));

      // The drag never hovers or selects the data beneath the panel.
      expect(renderBox.coordinator.hoveredMarker, hoveredMarker);
      expect(renderBox.coordinator.selectedElements, isEmpty);

      await pointer.up();
      await tester.pump();
      expect(renderBox.coordinator.selectedElements, isEmpty);
      expect(renderBox.debugSeriesCachePicture, same(seriesPicture));
    });

    testWidgets('drag over data points never selects or tooltips them', (
      tester,
    ) async {
      // Place the panel over the middle of the plot, on top of data.
      await tester.pumpWidget(
        _host(
          interaction: _annotationInteraction(
            placement: const ChartOverlayPlacement(
              anchor: Alignment.center,
              offset: Offset.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final gesture = await tester.startGesture(
        _panelCenter(tester, renderBox),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(25, 10));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(renderBox.coordinator.selectedElements, isEmpty);
      expect(renderBox.coordinator.hoveredMarker, isNull);
    });

    testWidgets('clampToPlot keeps the drag preview and commit inside', (
      tester,
    ) async {
      final placements = <ChartOverlayPlacement>[];
      await tester.pumpWidget(
        _host(
          interaction: _annotationInteraction(
            onPlacementChanged: placements.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      final plot = renderBox.debugPlotArea;

      final gesture = await tester.startGesture(
        _panelCenter(tester, renderBox),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(Offset(plot.width * 2, plot.height * 2));
      await tester.pump();

      // The live preview is already clamped inside the plot.
      final preview = renderBox.debugValueSummaryBounds;
      expect(preview.right, lessThanOrEqualTo(plot.width + 0.01));
      expect(preview.bottom, lessThanOrEqualTo(plot.height + 0.01));

      await gesture.up();
      await tester.pump();

      expect(placements, hasLength(1));
      final committed = renderBox.debugValueSummaryBounds;
      expect(committed.right, lessThanOrEqualTo(plot.width + 0.01));
      expect(committed.bottom, lessThanOrEqualTo(plot.height + 0.01));
      expect(committed.left, greaterThanOrEqualTo(-0.01));
      expect(committed.top, greaterThanOrEqualTo(-0.01));
    });

    testWidgets('clampToPlot false allows the panel to overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(interaction: _annotationInteraction(clampToPlot: false)),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      final plot = renderBox.debugPlotArea;

      final gesture = await tester.startGesture(
        _panelCenter(tester, renderBox),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(Offset(plot.width, 0));
      await tester.pump();
      expect(
        renderBox.debugValueSummaryBounds.right,
        greaterThan(plot.width),
      );
      await gesture.up();
      await tester.pump();
    });
  });

  group('non-primary buttons over the panel', () {
    testWidgets(
      'right-click over the panel opens the context menu instead of '
      'engaging a drag',
      (tester) async {
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              onPlacementChanged: placements.add,
            ),
            contextActionsBuilder: (context, invocation) => [
              ChartContextAction(
                id: 'probe.action',
                label: 'Panel probe action',
                onSelected: () {},
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        final panelBefore = renderBox.debugValueSummaryBounds.topLeft;

        final gesture = await tester.startGesture(
          _panelCenter(tester, renderBox),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await gesture.up();
        await tester.pumpAndSettle();

        // The secondary press fell through to the chart's context-menu path.
        expect(find.text('Panel probe action'), findsOneWidget);

        // Selecting the action closes the menu; the panel neither moved nor
        // committed a placement.
        await tester.tap(find.text('Panel probe action'));
        await tester.pumpAndSettle();
        expect(renderBox.debugValueSummaryBounds.topLeft, panelBefore);
        expect(placements, isEmpty);
      },
    );

    testWidgets(
      'middle-drag over the panel pans the chart instead of moving the panel',
      (tester) async {
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              onPlacementChanged: placements.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        final panelBefore = renderBox.debugValueSummaryBounds.topLeft;
        final dataXMinBefore = renderBox.transform!.dataXMin;

        final middle = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kMiddleMouseButton,
        );
        addTearDown(middle.removePointer);
        await middle.addPointer(location: Offset.zero);
        await middle.moveTo(_panelCenter(tester, renderBox));
        await middle.down(_panelCenter(tester, renderBox));
        await middle.moveBy(const Offset(56, 0));
        await tester.pump();
        await middle.up();
        await tester.pump();

        // The middle press fell through to the exclusive pan handler.
        expect(
          renderBox.transform!.dataXMin,
          isNot(closeTo(dataXMinBefore, 0.0001)),
        );
        // The plot-anchored panel stayed put and committed nothing.
        expect(renderBox.debugValueSummaryBounds.topLeft, panelBefore);
        expect(placements, isEmpty);
      },
    );
  });

  testWidgets('hovering the draggable panel suppresses marker hover beneath', (
    tester,
  ) async {
    // First pump measures the panel, then a second pump centers it exactly
    // on the speed datum at (4, 7). Markers are enabled so the line series
    // actually hover-resolves data hits.
    await tester.pumpWidget(
      _host(
        interaction: _annotationInteraction(),
        showDataPointMarkers: true,
      ),
    );
    await tester.pumpAndSettle();
    final renderBox = _renderBox(tester);
    final panelSize = renderBox.debugValueSummaryBounds.size;
    final datumPlot = renderBox.transform!.dataToPlot(4, 7);

    await tester.pumpWidget(
      _host(
        interaction: _annotationInteraction(
          placement: ChartOverlayPlacement(
            anchor: Alignment.topLeft,
            offset:
                datumPlot -
                Offset(panelSize.width / 2, panelSize.height / 2),
          ),
        ),
        showDataPointMarkers: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(renderBox.debugValueSummaryBounds.contains(datumPlot), isTrue);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(_plotTarget(tester, renderBox, 4, 7));
    // Let the deferred hover hit test run too (50ms throttle).
    await tester.pump(const Duration(milliseconds: 80));

    // The datum directly under the draggable panel must not hover-resolve:
    // no marker highlight and no tooltip beneath the move cursor, matching
    // the press path.
    expect(renderBox.coordinator.hoveredMarker, isNull);

    // Outside the panel, marker hover resolves normally again.
    final outsideDatum = renderBox.transform!.dataToPlot(8, 9);
    expect(
      renderBox.debugValueSummaryBounds.contains(outsideDatum),
      isFalse,
    );
    await pointer.moveTo(_plotTarget(tester, renderBox, 8, 9));
    await tester.pump(const Duration(milliseconds: 80));
    expect(renderBox.coordinator.hoveredMarker, isNotNull);
    expect(renderBox.coordinator.hoveredMarker!.seriesId, 'speed');
  });

  testWidgets('plot resize clamps the effective placement', (tester) async {
    await tester.pumpWidget(_host(interaction: _annotationInteraction()));
    await tester.pumpAndSettle();
    final renderBox = _renderBox(tester);
    final plot = renderBox.debugPlotArea;

    // Park the panel near the bottom-right corner.
    final gesture = await tester.startGesture(
      _panelCenter(tester, renderBox),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(Offset(plot.width * 2, plot.height * 2));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    final parked = renderBox.debugValueSummaryBounds;
    expect(parked.right, closeTo(plot.width, 0.01));
    expect(parked.bottom, closeTo(plot.height, 0.01));

    // Shrink the chart: the panel must stay inside the smaller plot.
    await tester.pumpWidget(
      _host(
        interaction: _annotationInteraction(),
        width: 420,
        height: 220,
      ),
    );
    await tester.pumpAndSettle();
    final smallPlot = renderBox.debugPlotArea;
    expect(smallPlot.width, lessThan(plot.width));
    final clamped = renderBox.debugValueSummaryBounds;
    expect(clamped, isNot(Rect.zero));
    expect(clamped.right, lessThanOrEqualTo(smallPlot.width + 0.01));
    expect(clamped.bottom, lessThanOrEqualTo(smallPlot.height + 0.01));
    expect(clamped.left, greaterThanOrEqualTo(-0.01));
    expect(clamped.top, greaterThanOrEqualTo(-0.01));

    // The oversized committed placement parks the panel exactly at the
    // clamped bottom-right corner of the smaller plot — not merely
    // somewhere inside it.
    expect(clamped.right, closeTo(smallPlot.width, 0.01));
    expect(clamped.bottom, closeTo(smallPlot.height, 0.01));
  });

  group('keyboard', () {
    testWidgets(
      'arrows move by 1px, Shift by 10px, committing on key release',
      (tester) async {
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              onPlacementChanged: placements.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        await _focusPanel(tester, renderBox);
        expect(placements, isEmpty);

        // Arrow right: +1px, committed once on release.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(13, 12),
        );
        expect(placements, isEmpty);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(placements, hasLength(1));
        expect(placements.last.offset, const Offset(13, 12));

        // Shift+arrow down: +10px.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(13, 22),
        );
        expect(placements, hasLength(2));
        expect(placements.last.offset, const Offset(13, 22));

        // Escape resets to the configured placement and emits it.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(12, 12),
        );
        expect(placements, hasLength(3));
        expect(placements.last, ChartOverlayPlacement.topLeft);
      },
    );

    testWidgets(
      'Escape emits only when an override or pending nudge exists',
      (tester) async {
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              onPlacementChanged: placements.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        // One mouse pointer for the whole test (multiple gestures on the
        // same device trip the MouseTracker's add/remove pairing).
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);

        Future<void> clickPanel() async {
          await pointer.moveTo(_panelCenter(tester, renderBox));
          await tester.pump();
          await pointer.down(_panelCenter(tester, renderBox));
          await tester.pump();
          await pointer.up();
          await tester.pump();
        }

        Future<void> pressEscape() async {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
          await tester.pump();
        }

        // Focused but untouched: Escape must not fabricate a commit.
        await clickPanel();
        await pressEscape();
        expect(placements, isEmpty);
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(12, 12),
        );

        // After a committed drag, Escape re-syncs the host exactly once.
        await pointer.moveTo(_panelCenter(tester, renderBox));
        await tester.pump();
        await pointer.down(_panelCenter(tester, renderBox));
        await pointer.moveBy(const Offset(30, 20));
        await tester.pump();
        await pointer.up();
        await tester.pump();
        expect(placements, hasLength(1));

        await clickPanel();
        await pressEscape();
        expect(placements, hasLength(2));
        expect(placements.last, ChartOverlayPlacement.topLeft);

        // The override is gone now: a further Escape emits nothing.
        await clickPanel();
        await pressEscape();
        expect(placements, hasLength(2));
      },
    );

    testWidgets('a non-draggable panel is never keyboard-movable', (
      tester,
    ) async {
      final placements = <ChartOverlayPlacement>[];
      await tester.pumpWidget(
        _host(
          interaction: _annotationInteraction(
            draggable: false,
            onPlacementChanged: placements.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      await _focusPanel(tester, renderBox);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      // The unconsumed arrow falls through to keyboard panning, which
      // releases its interaction mode on a 200ms timer.
      await tester.pump(const Duration(milliseconds: 250));

      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));
      expect(placements, isEmpty);
    });
  });

  group('controller', () {
    testWidgets(
      'DefaultCartesianValueSummaryController.resetPlacement restores the '
      'configured placement without emitting',
      (tester) async {
        final controller = DefaultCartesianValueSummaryController();
        addTearDown(controller.dispose);
        final placements = <ChartOverlayPlacement>[];
        await tester.pumpWidget(
          _host(
            interaction: _annotationInteraction(
              controller: controller,
              onPlacementChanged: placements.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        final gesture = await tester.startGesture(
          _panelCenter(tester, renderBox),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(60, 40));
        await tester.pump();
        await gesture.up();
        await tester.pump();
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(72, 52),
        );
        expect(placements, hasLength(1));

        controller.resetPlacement();
        await tester.pump();
        expect(
          renderBox.debugValueSummaryBounds.topLeft,
          const Offset(12, 12),
        );
        // Host-initiated reset: no additional committed-placement callback.
        expect(placements, hasLength(1));
      },
    );

    testWidgets('the default controller also drives the pin surface', (
      tester,
    ) async {
      final controller = DefaultCartesianValueSummaryController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          interaction: _annotationInteraction(
            valuePolicy:
                CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.fallback,
      );

      const pin = ChartPointRef(seriesId: 'speed', pointIndex: 1);
      controller.pin(pin);
      await tester.pump();
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.pinned,
      );
      expect(controller.pinnedPoint, pin);

      controller.clearPin();
      await tester.pump();
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.fallback,
      );
    });
  });

  testWidgets('setValueSummaryFocus reports focus transitions only', (
    tester,
  ) async {
    await tester.pumpWidget(_host(interaction: _annotationInteraction()));
    await tester.pumpAndSettle();
    final renderBox = _renderBox(tester);

    // Only actual transitions report true (and re-flush semantics);
    // steady-state repeats — one per pointer-down — are free.
    expect(renderBox.setValueSummaryFocus(true), isTrue);
    expect(renderBox.setValueSummaryFocus(true), isFalse);
    expect(renderBox.setValueSummaryFocus(false), isTrue);
    expect(renderBox.setValueSummaryFocus(false), isFalse);
    await tester.pump();
  });

  testWidgets('hovering the draggable panel shows the move cursor', (
    tester,
  ) async {
    await tester.pumpWidget(_host(interaction: _annotationInteraction()));
    await tester.pumpAndSettle();
    final renderBox = _renderBox(tester);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(_panelCenter(tester, renderBox));
    // Let the deferred hover hit test run (50ms throttle).
    await tester.pump(const Duration(milliseconds: 80));

    final region = tester.widget<MouseRegion>(
      find
          .descendant(
            of: find.byType(BravenChartPlus),
            matching: find.byType(MouseRegion),
          )
          .at(1),
    );
    expect(region.cursor, SystemMouseCursors.move);
  });
}

InteractionConfig _annotationInteraction({
  ChartOverlayPlacement placement = ChartOverlayPlacement.topLeft,
  bool draggable = true,
  bool clampToPlot = true,
  ValueChanged<ChartOverlayPlacement>? onPlacementChanged,
  CartesianValueSummaryController? controller,
  CartesianValueSummaryValuePolicy valuePolicy =
      CartesianValueSummaryValuePolicy.trackingThenLatest,
}) {
  return InteractionConfig(
    crosshair: const CrosshairConfig(
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: false,
    ),
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      valuePolicy: valuePolicy,
      presentation: CartesianValueSummaryPresentation.annotation(
        placement: placement,
        draggable: draggable,
        clampToPlot: clampToPlot,
      ),
      onPlacementChanged: onPlacementChanged,
      controller: controller,
    ),
  );
}

Widget _host({
  required InteractionConfig interaction,
  double width = 640,
  double height = 300,
  ChartContextActionsBuilder? contextActionsBuilder,
  bool showDataPointMarkers = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: interaction,
            contextActionsBuilder: contextActionsBuilder,
            series: [
              LineChartSeries(
                id: 'speed',
                showDataPointMarkers: showDataPointMarkers,
                points: const [
                  ChartDataPoint(x: 0, y: 4),
                  ChartDataPoint(x: 2, y: 8),
                  ChartDataPoint(x: 4, y: 7),
                  ChartDataPoint(x: 6, y: 11),
                  ChartDataPoint(x: 8, y: 9),
                  ChartDataPoint(x: 10, y: 12),
                ],
              ),
              LineChartSeries(
                id: 'power',
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

/// Widget-space center of the currently painted summary panel.
Offset _panelCenter(WidgetTester tester, ChartRenderBox renderBox) {
  final bounds = renderBox.debugValueSummaryBounds;
  assert(bounds != Rect.zero, 'value summary panel is not painted');
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(bounds.center);
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

/// Hovers the chart (granting the chart focus) and clicks the panel so the
/// summary acquires keyboard focus.
Future<void> _focusPanel(WidgetTester tester, ChartRenderBox renderBox) async {
  final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(pointer.removePointer);
  await pointer.addPointer(location: Offset.zero);
  await pointer.moveTo(_panelCenter(tester, renderBox));
  await tester.pump();
  await pointer.down(_panelCenter(tester, renderBox));
  await tester.pump();
  await pointer.up();
  await tester.pump();
}
