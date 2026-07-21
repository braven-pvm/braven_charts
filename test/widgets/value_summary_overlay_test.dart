// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Task 8 pipeline wiring: config -> resolver -> reducer -> adapter -> overlay
// element inside the live chart. These tests drive a real BravenChartPlus and
// probe the render box's value summary debug hooks.

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fallback policies without a pointer', () {
    testWidgets(
      'trackingThenLatest shows latest visible datum rows with no pointer',
      (tester) async {
        await tester.pumpWidget(_host(interaction: _summaryInteraction()));
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        final snapshot = renderBox.debugValueSummarySnapshot;
        expect(snapshot, isNotNull);
        expect(snapshot!.origin, CartesianTrackingOrigin.fallback);
        expect(snapshot.dataX, closeTo(10, 1e-6));
        expect(snapshot.values, hasLength(2));

        final model = renderBox.debugValueSummaryModel;
        expect(model, isNotNull);
        expect(model!.rows, hasLength(2));
        expect(model.rows[0].label, snapshot.values[0].seriesName);
        expect(model.rows[0].value, snapshot.values[0].formattedY);
        expect(model.rows[1].value, snapshot.values[1].formattedY);

        // The panel actually painted at the configured top-left inset.
        final bounds = renderBox.debugValueSummaryBounds;
        expect(bounds, isNot(Rect.zero));
        expect(bounds.topLeft, const Offset(12, 12));

        // The overlay element never joins the interactive element list.
        expect(
          renderBox.debugElements.map((e) => e.id),
          isNot(contains('cartesian-value-summary-overlay')),
        );
      },
    );

    testWidgets('trackingThenFirst falls back to the first visible datum', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          interaction: _summaryInteraction(
            valuePolicy: CartesianValueSummaryValuePolicy.trackingThenFirst,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final snapshot = renderBox.debugValueSummarySnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.origin, CartesianTrackingOrigin.fallback);
      expect(snapshot.dataX, closeTo(0, 1e-6));
    });
  });

  testWidgets(
    'hover re-reduces once per datum change, never per pixel or repaint',
    (tester) async {
      await tester.pumpWidget(_host(interaction: _summaryInteraction()));
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      final reduceAfterFallback = renderBox.debugValueSummaryReduceCount;

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();

      final hoverSnapshot = renderBox.debugValueSummarySnapshot;
      expect(hoverSnapshot, isNotNull);
      expect(hoverSnapshot!.origin, CartesianTrackingOrigin.pointer);
      expect(hoverSnapshot.values.first.x, closeTo(4, 1e-6));
      final reduceAfterHover = renderBox.debugValueSummaryReduceCount;
      expect(reduceAfterHover, reduceAfterFallback + 1);
      final publishAfterHover = renderBox.debugTrackingPublishCount;
      final modelAfterHover = renderBox.debugValueSummaryModel;

      // Sub-datum cursor movement: the resolver recomputes for the new
      // cursor but suppresses re-publication for the identical snapped
      // datum, so the summary must not re-reduce.
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.5, 6));
      await tester.pump();
      expect(renderBox.debugTrackingPublishCount, publishAfterHover);
      expect(renderBox.debugValueSummaryReduceCount, reduceAfterHover);
      expect(renderBox.debugValueSummarySnapshot, same(hoverSnapshot));
      expect(renderBox.debugValueSummaryModel, same(modelAfterHover));

      // Stationary repaints must not re-reduce either.
      final computeBeforeRepaints = renderBox.debugTrackingComputeCount;
      for (var frame = 0; frame < 3; frame++) {
        renderBox.markNeedsPaint();
        await tester.pump();
      }
      expect(renderBox.debugTrackingComputeCount, computeBeforeRepaints);
      expect(renderBox.debugValueSummaryReduceCount, reduceAfterHover);

      // Crossing to the next snapped datum re-reduces exactly once.
      await pointer.moveTo(_plotTarget(tester, renderBox, 5.8, 6));
      await tester.pump();
      final nextSnapshot = renderBox.debugValueSummarySnapshot;
      expect(nextSnapshot, isNotNull);
      expect(nextSnapshot!.values.first.x, closeTo(6, 1e-6));
      expect(renderBox.debugValueSummaryReduceCount, reduceAfterHover + 1);
      expect(renderBox.debugValueSummaryModel, isNot(same(modelAfterHover)));
    },
  );

  testWidgets(
    'pointer exit returns to the latest-visible fallback, not an empty panel',
    (tester) async {
      await tester.pumpWidget(_host(interaction: _summaryInteraction()));
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.pointer,
      );

      await pointer.moveTo(const Offset(2, 2));
      await tester.pump();

      final snapshot = renderBox.debugValueSummarySnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.origin, CartesianTrackingOrigin.fallback);
      expect(snapshot.dataX, closeTo(10, 1e-6));
      expect(renderBox.debugValueSummaryModel, isNotNull);
      expect(renderBox.debugValueSummaryBounds, isNot(Rect.zero));
    },
  );

  group('gating', () {
    Future<void> expectNothingPainted(
      WidgetTester tester,
      InteractionConfig interaction,
    ) async {
      await tester.pumpWidget(_host(interaction: interaction));
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();

      expect(renderBox.debugValueSummaryModel, isNull);
      expect(renderBox.debugValueSummarySnapshot, isNull);
      expect(renderBox.debugValueSummaryBounds, Rect.zero);
      await pointer.removePointer();
      await tester.pump();
    }

    testWidgets('nested valueSummary disabled paints nothing', (tester) async {
      await expectNothingPainted(
        tester,
        const InteractionConfig(
          crosshair: CrosshairConfig(
            displayMode: CrosshairDisplayMode.tracking,
          ),
          // valueSummary defaults to disabled.
        ),
      );
    });

    testWidgets('outer InteractionConfig.enabled=false wins over nested '
        'enabled', (tester) async {
      await expectNothingPainted(
        tester,
        const InteractionConfig(
          enabled: false,
          valueSummary: CartesianValueSummaryConfig(enabled: true),
        ),
      );
    });

    testWidgets('InteractionConfig.none() disables an enabled nested config', (
      tester,
    ) async {
      await expectNothingPainted(
        tester,
        InteractionConfig.none().copyWith(
          valueSummary: const CartesianValueSummaryConfig(enabled: true),
        ),
      );
    });
  });

  group('feedback-layer independence', () {
    testWidgets(
      'summary and tracking crosshair share one resolution per frame',
      (tester) async {
        await tester.pumpWidget(_host(interaction: _summaryInteraction()));
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        expect(renderBox.debugTrackingComputeCount, 0);

        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
        await tester.pump();

        // One computation feeds both consumers: the summary resolves first,
        // the crosshair paint path is an input-memo hit on the same
        // resolver. The crosshair still received its snapshot.
        expect(renderBox.debugTrackingComputeCount, 1);
        expect(renderBox.debugTrackingPublishCount, 1);
        expect(renderBox.debugTrackingSnapshot, isNotNull);
        expect(
          renderBox.debugValueSummarySnapshot,
          same(renderBox.debugTrackingSnapshot),
        );
      },
    );

    testWidgets('summary tracks while the crosshair is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          interaction: _summaryInteraction(
            crosshair: const CrosshairConfig(
              enabled: false,
              interpolateValues: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();

      final snapshot = renderBox.debugValueSummarySnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.origin, CartesianTrackingOrigin.pointer);
      expect(snapshot.values.first.x, closeTo(4, 1e-6));
      expect(renderBox.debugValueSummaryModel, isNotNull);

      // Repaints while hovering keep the resolution alive (the crosshair's
      // gate-off clear must not wipe the summary's tracking state).
      renderBox.markNeedsPaint();
      await tester.pump();
      expect(renderBox.debugValueSummarySnapshot, same(snapshot));

      // Exit still falls back.
      await pointer.moveTo(const Offset(2, 2));
      await tester.pump();
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.fallback,
      );
    });
  });

  testWidgets(
    'pan and wheel zoom suspend the summary and re-reduce once on settle',
    (tester) async {
      await tester.pumpWidget(_host(interaction: _summaryInteraction()));
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryModel, isNotNull);

      final panStart = _plotTarget(tester, renderBox, 5, 7);

      // Middle-button pan: the displayed content is frozen for the whole
      // gesture — same model instance, no re-reduction.
      final middle = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      addTearDown(middle.removePointer);
      await middle.addPointer(location: Offset.zero);
      await middle.moveTo(panStart);
      await tester.pump();
      final frozenModel = renderBox.debugValueSummaryModel;
      final reduceBefore = renderBox.debugValueSummaryReduceCount;

      await middle.down(panStart);
      await middle.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(renderBox.coordinator.isPanningOrZooming, isTrue);
      expect(renderBox.debugValueSummaryModel, same(frozenModel));
      expect(renderBox.debugValueSummaryReduceCount, reduceBefore);
      await middle.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(renderBox.debugValueSummaryModel, same(frozenModel));
      expect(renderBox.debugValueSummaryReduceCount, reduceBefore);

      // Release: exactly one re-reduction on the first settled frame, and
      // repaints stay flat afterwards.
      await middle.up();
      await tester.pump();
      expect(renderBox.coordinator.isPanningOrZooming, isFalse);
      expect(renderBox.debugValueSummaryReduceCount, reduceBefore + 1);
      renderBox.markNeedsPaint();
      await tester.pump();
      expect(renderBox.debugValueSummaryReduceCount, reduceBefore + 1);

      // Shift-wheel zoom: the zooming mode freezes the content the same
      // way until the wheel settles (the mode self-releases on a timer).
      final modelAfterPan = renderBox.debugValueSummaryModel;
      final reduceAfterPan = renderBox.debugValueSummaryReduceCount;
      renderBox.coordinator.addModifierKey(LogicalKeyboardKey.shift);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: panStart,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await tester.pump();
      renderBox.coordinator.removeModifierKey(LogicalKeyboardKey.shift);
      expect(renderBox.coordinator.isPanningOrZooming, isTrue);
      expect(renderBox.debugValueSummaryModel, same(modelAfterPan));
      expect(renderBox.debugValueSummaryReduceCount, reduceAfterPan);

      await tester.pump(const Duration(milliseconds: 250));
      expect(renderBox.coordinator.isPanningOrZooming, isFalse);
      renderBox.markNeedsPaint();
      await tester.pump();
      expect(renderBox.debugValueSummaryReduceCount, reduceAfterPan + 1);
      renderBox.markNeedsPaint();
      await tester.pump();
      expect(renderBox.debugValueSummaryReduceCount, reduceAfterPan + 1);
    },
  );

  testWidgets(
    'hover through the fixed overlay still resolves markers beneath',
    (tester) async {
      // First pump measures the overlay, then a second pump parks it
      // exactly over the speed datum at (4, 7). Markers are enabled so the
      // line series actually hover-resolves data hits.
      await tester.pumpWidget(
        _host(
          interaction: _summaryInteraction(),
          showDataPointMarkers: true,
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      final panelSize = renderBox.debugValueSummaryBounds.size;
      final datumPlot = renderBox.transform!.dataToPlot(4, 7);

      await tester.pumpWidget(
        _host(
          interaction: _summaryInteraction(
            presentation: CartesianValueSummaryPresentation.overlay(
              placement: ChartOverlayPlacement(
                anchor: Alignment.topLeft,
                offset:
                    datumPlot -
                    Offset(panelSize.width / 2, panelSize.height / 2),
              ),
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
      await tester.pump(const Duration(milliseconds: 80));

      // The fixed overlay is spec'd hover-transparent: the datum beneath it
      // still hover-resolves (unlike the draggable annotation panel).
      final marker = renderBox.coordinator.hoveredMarker;
      expect(marker, isNotNull);
      expect(marker!.seriesId, 'speed');
      expect(marker.markerIndex, 2);
    },
  );

  testWidgets('hover tracking never invalidates the series picture cache', (
    tester,
  ) async {
    await tester.pumpWidget(_host(interaction: _summaryInteraction()));
    await tester.pumpAndSettle();
    final renderBox = _renderBox(tester);
    final picture = renderBox.debugSeriesCachePicture;
    expect(picture, isNotNull);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
    await tester.pump();
    await pointer.moveTo(_plotTarget(tester, renderBox, 5.8, 6));
    await tester.pump();
    await pointer.moveTo(_plotTarget(tester, renderBox, 7.6, 6));
    await tester.pump();

    expect(renderBox.debugSeriesCachePicture, same(picture));
  });

  group('controller pinning', () {
    testWidgets(
      'pinnedThenTrackingThenLatest shows the pin while hovering elsewhere',
      (tester) async {
        final controller = _TestSummaryController();
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
        expect(
          renderBox.debugValueSummarySnapshot?.origin,
          CartesianTrackingOrigin.fallback,
        );

        const pin = ChartPointRef(seriesId: 'speed', pointIndex: 1);
        controller.pin(pin);
        await tester.pump();

        final pinnedSnapshot = renderBox.debugValueSummarySnapshot;
        expect(pinnedSnapshot, isNotNull);
        expect(pinnedSnapshot!.origin, CartesianTrackingOrigin.pinned);
        expect(pinnedSnapshot.primaryPoint, pin);
        expect(pinnedSnapshot.dataX, closeTo(2, 1e-6));
        final speedValue = pinnedSnapshot.values.firstWhere(
          (value) => value.seriesId == 'speed',
        );
        expect(speedValue.dataPointIndex, 1);
        expect(speedValue.y, 8);

        // Hovering elsewhere must not displace the pin.
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(_plotTarget(tester, renderBox, 7.6, 6));
        await tester.pump();

        final whileHovering = renderBox.debugValueSummarySnapshot;
        expect(whileHovering!.origin, CartesianTrackingOrigin.pinned);
        expect(whileHovering.dataX, closeTo(2, 1e-6));
        expect(controller.pinnedPoint, pin);

        // Clearing the pin falls back to live tracking under the policy.
        controller.clearPin();
        await tester.pump();
        expect(
          renderBox.debugValueSummarySnapshot?.origin,
          CartesianTrackingOrigin.pointer,
        );
      },
    );

    testWidgets(
      'data replacement removing the pinned point clears the pin and falls '
      'through to the fallback',
      (tester) async {
        final controller = _TestSummaryController();
        final interaction = _summaryInteraction(
          valuePolicy:
              CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
          controller: controller,
        );
        await tester.pumpWidget(_host(interaction: interaction));
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);

        controller.pin(const ChartPointRef(seriesId: 'speed', pointIndex: 5));
        await tester.pump();
        expect(
          renderBox.debugValueSummarySnapshot?.origin,
          CartesianTrackingOrigin.pinned,
        );

        // Replace the data with a shorter series: index 5 no longer exists.
        await tester.pumpWidget(
          _host(interaction: interaction, shortSpeedSeries: true),
        );
        await tester.pump();

        final snapshot = renderBox.debugValueSummarySnapshot;
        expect(snapshot, isNotNull);
        expect(snapshot!.origin, CartesianTrackingOrigin.fallback);
        expect(snapshot.dataX, closeTo(4, 1e-6));

        // The invalid pin is cleared on the controller post-frame.
        await tester.pump();
        expect(controller.pinnedPoint, isNull);
        expect(
          renderBox.debugValueSummarySnapshot?.origin,
          CartesianTrackingOrigin.fallback,
        );
      },
    );

    testWidgets('explicitOnly hides the summary without a pin', (tester) async {
      final controller = _TestSummaryController();
      await tester.pumpWidget(
        _host(
          interaction: _summaryInteraction(
            valuePolicy: CartesianValueSummaryValuePolicy.explicitOnly,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      expect(renderBox.debugValueSummaryModel, isNull);
      expect(renderBox.debugValueSummaryBounds, Rect.zero);

      // Hovering changes nothing: explicitOnly has no tracking source.
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 4.2, 6));
      await tester.pump();
      expect(renderBox.debugValueSummaryModel, isNull);

      // A pin shows the panel; clearing it hides the panel again.
      controller.pin(const ChartPointRef(seriesId: 'power', pointIndex: 2));
      await tester.pump();
      final pinned = renderBox.debugValueSummarySnapshot;
      expect(pinned, isNotNull);
      expect(pinned!.origin, CartesianTrackingOrigin.pinned);
      expect(renderBox.debugValueSummaryBounds, isNot(Rect.zero));

      controller.clearPin();
      await tester.pump();
      expect(renderBox.debugValueSummaryModel, isNull);
      expect(renderBox.debugValueSummaryBounds, Rect.zero);
    });
  });
}

/// A listenable controller mirroring how applications implement the pin
/// surface (the package ships only the abstract interface).
class _TestSummaryController extends ChangeNotifier
    implements CartesianValueSummaryController {
  ChartPointRef? _pinnedPoint;
  int resetPlacementCalls = 0;

  @override
  ChartPointRef? get pinnedPoint => _pinnedPoint;

  @override
  void pin(ChartPointRef point) {
    if (_pinnedPoint == point) return;
    _pinnedPoint = point;
    notifyListeners();
  }

  @override
  void clearPin() {
    if (_pinnedPoint == null) return;
    _pinnedPoint = null;
    notifyListeners();
  }

  @override
  void resetPlacement() {
    resetPlacementCalls++;
    notifyListeners();
  }
}

InteractionConfig _summaryInteraction({
  CartesianValueSummaryValuePolicy valuePolicy =
      CartesianValueSummaryValuePolicy.trackingThenLatest,
  CartesianValueSummaryController? controller,
  CrosshairConfig? crosshair,
  CartesianValueSummaryPresentation presentation =
      const CartesianValueSummaryPresentation.overlay(),
}) {
  return InteractionConfig(
    crosshair:
        crosshair ??
        const CrosshairConfig(
          displayMode: CrosshairDisplayMode.tracking,
          // Snap to actual data points so a hover inside one datum's snap
          // range produces one stable snapshot identity.
          interpolateValues: false,
        ),
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      valuePolicy: valuePolicy,
      controller: controller,
      presentation: presentation,
    ),
  );
}

Widget _host({
  required InteractionConfig interaction,
  bool shortSpeedSeries = false,
  bool showDataPointMarkers = false,
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
                showDataPointMarkers: showDataPointMarkers,
                points: shortSpeedSeries
                    ? const [
                        ChartDataPoint(x: 0, y: 4),
                        ChartDataPoint(x: 2, y: 8),
                        ChartDataPoint(x: 4, y: 7),
                      ]
                    : const [
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
                points: shortSpeedSeries
                    ? const [
                        ChartDataPoint(x: 0, y: 2),
                        ChartDataPoint(x: 2, y: 5),
                        ChartDataPoint(x: 4, y: 3),
                      ]
                    : const [
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
